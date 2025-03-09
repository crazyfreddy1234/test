 local RPX,RPXT,_G,TUNING=RPX,RPXT,GLOBAL,TUNING
 local SpawnPrefab=_G.SpawnPrefab
 local STRINGS = _G.STRINGS
 local MapTuning,AddReforgedWorld,SetHealthModifier,GetArenaCenterPoint,SetMusic=RPX.MapTuning,RPX.AddReforgedWorld,RPX.SetHealthModifier,RPX.GetArenaCenterPoint,RPX.SetMusic

 AddReforgedWorld(function(TheWorld,gameplay)
	if gameplay.gametype=="golemdefense" then 
		local golem=SpawnPrefab("golem")
		local rlgl_talker=SpawnPrefab("reforged_rlgl_talker")
		golem.Transform:SetPosition(TheWorld.center.Transform:GetWorldPosition())
		golem.components.health:SetMaxHealth(1000)
		
		
		golem:DoTaskInTime(2*GLOBAL.FRAMES, function()
			GLOBAL.RemoveTask(golem, "death_timer")
		end)

		for i,player in pairs(GLOBAL.AllPlayers) do
			player.components.pethealthbars:AddPet(golem)
		end

		golem.components.health:StartRegen(2, 1, false, golem_regen)
		golem.acidimmune = true

		golem.components.combat:SetRange(999)
		local function UpdateProjectileRange(weapon, caster, target, projectile)
			projectile.components.projectile:SetRange(999)
		end
		golem.weapon.components.weapon:SetOnProjectileLaunched(UpdateProjectileRange)

		golem:SetCharged(true)
		golem.components.buffable:AddBuff("golem_size", {{name = "scaler", type = "mult", val = 1.5}})
		golem.components.scaler:ApplyScale()
		local distance = 100

		--golem:DoPeriodicTask(1, function()
		--	if GLOBAL.distsq(golem:GetPosition(), TheWorld.center:GetPosition()) > distance then
		--		for _,player in pairs(GLOBAL.AllPlayers) do
		--			player.components.health:Kill()
		--		end
			--end
		--end)

		local function UpdateLightPhase(golem)
			local x,y,z = golem.Transform:GetWorldPosition() 
			local ents = TheSim:FindEntities(x,y,z, 9001) 
			for k,v in pairs(ents) do 
				if v.components and v.components.health and not v:HasTag("player") and not v:HasTag("companion") then 
					v.components.combat:SetTarget(golem)
				end
			end

			rlgl_talker.components.talker:Chatter("REFORGED.golemdefense.Aggro_To_Golem", 0, 4)

			golem:DoTaskInTime(45, function()
				UpdateLightPhase(golem)
			end)
		end

		UpdateLightPhase(golem)

		golem:ListenForEvent("death", function(golem)
			for _,player in pairs(GLOBAL.AllPlayers) do
				player.components.health:Kill()
			end
			TheWorld.components.lavaarenaevent:End(false)
		end)
	end
 end)