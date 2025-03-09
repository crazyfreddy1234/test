 local RPX,RPXT,_G,TUNING=RPX,RPXT,GLOBAL,TUNING
 local SpawnPrefab=_G.SpawnPrefab
 local STRINGS = _G.STRINGS
 local MapTuning,AddReforgedWorld,SetHealthModifier,GetArenaCenterPoint,SetMusic=RPX.MapTuning,RPX.AddReforgedWorld,RPX.SetHealthModifier,RPX.GetArenaCenterPoint,RPX.SetMusic

 AddReforgedWorld(function(TheWorld,gameplay)
	if gameplay.gametype=="mathtest" then

		local function KillPlayer(inst)
			if not inst:HasTag("stoptalking") then
				inst:AddTag("stoptalking")
			end
			if not inst.components.health:IsDead() then
				inst.components.health:Kill()
			end
		end

		local function RGB(r, g, b)
			return { r / 255, g / 255, b / 255, 1 }
		end


		STRINGS.REFORGED.mathtest = {
			Math_Question = "%s + %s ?"
		}

		function mathend()

			local mathcooltime = math.random(20,35)

			for _,player in pairs(_G.AllPlayers) do
				if not player:HasTag("corret") then
					player.AnimState:SetMultColour(1, 0, 0, 1)
					KillPlayer(player)
				end
			end		

			TheWorld:DoTaskInTime(2, function()
				for i,player in pairs(_G.AllPlayers) do
					player.AnimState:SetMultColour(1, 1, 1, 1)
					player:RemoveTag("corret")
					answer = 0
				end
			end)

			TheWorld:DoTaskInTime(mathcooltime, function()
				mathstart()
			end)

		end

		function mathstart(inst)

			TheWorld:DoTaskInTime(6, function()
				mathend()
			end)

			local math_talker=SpawnPrefab("math_talker")
			local str1 = math.random(1,99)
			local str2 = math.random(1,99)
			local math_question = string.format(STRINGS.REFORGED.mathtest.Math_Question, str1, str2)
			answer = str1 + str2
			answer = string.format("%d",answer)

			math_talker.components.talker:Chatter(math_question, 0, 5)

			for i,player in pairs(_G.AllPlayers) do
				player.components.talker:Say(math_question, 5)
				player:RemoveTag("stoptalking")
				player.AnimState:SetMultColour(1, 1, 0, 1)
			end

			local Networking_Say = _G.Networking_Say
			for i,player in pairs(_G.AllPlayers) do
				_G.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote, ...)
					Networking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, ...)
					
					if message == answer then
						playerforgeid = guid.." - "..prefab 
						playerstring = tostring(player)
						playeridsizestart , playeridsizeend = string.find(playerstring,guid)
						
						if playerstring ~= nil and playeridsizestart ~= nil and playeridsizeend ~= nil then
							playerid = string.sub(playerstring, GLOBAL.tonumber(playeridsizestart), GLOBAL.tonumber(playeridsizeend))
						end
							
							--[[
							print(playerforgeid)
							print(player)
							print(playerguid)
							print(tostring(playerid))
							print(prefab)
							print(guid)
							--]]

							for _,player2 in pairs(_G.AllPlayers) do
								if tostring(playerforgeid) == tostring(player2) and not player2:HasTag("stoptalking") then
									player2.AnimState:SetMultColour(0, 1, 0.5, 1)
									player2:AddTag("corret")

									if player2.components.health:IsDead() and not player2:HasTag("1questionleft") and not player2:HasTag("stoptalking") then
										player2:AddTag("1questionleft")
										player2:AddTag("stoptalking")
										player2.components.talker:Say("1 question left!", 3)
										break
									elseif player2.components.health:IsDead() and player2:HasTag("1questionleft") and not player2:HasTag("stoptalking") then
										player2.components.revivablecorpse:Revive(player2)
										player2:AddTag("stoptalking")
										player2:RemoveTag("1questionleft")
										break
									end
									player2:AddTag("stoptalking")
									break
								end	
							end

					end

				end
			end

			
		end

		TheWorld:DoTaskInTime(1, function()
			mathstart()
		end)
	end
end)