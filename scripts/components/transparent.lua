--NOTE: This is a client side component. No server
--      logic should be driven off this component!

local function PushAlpha(inst,alpha,shadow)
	inst.AnimState:OverrideMultColour(1, 1, 1, alpha)
	inst.DynamicShadow:Enable(shadow)
end

local function UpdateEnts(inst,stop)
	inst:DoTaskInTime(0.1,function()
		local pos = Vector3(0,0,0)
		local player_ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"player"})
		local LA_mob_ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"LA_mob"})
		for _,ent in pairs(player_ents) do
			if ent.components.transparent and (not ent.components.transparent:GetUpdate()) and (not stop) then
				if ThePlayer ~= ent then
					ent.components.transparent:Start(ent)
				end
			elseif ent.components.transparent and ent.components.transparent:GetUpdate() and stop then
				if ThePlayer ~= ent then
					ent.components.transparent:Stop(ent)
				end
			end
		end
		for _,ent in pairs(LA_mob_ents) do
			if ent.components.transparent and (not ent.components.transparent:GetUpdate()) and (not stop) then
				ent.components.transparent:Start(ent)
			elseif ent.components.transparent and ent.components.transparent:GetUpdate() and stop then
				ent.components.transparent:Stop(ent)
			end
		end
	end)
end

local function NonUpdateMobSpawn(world,data)
	local mob = data.mob
	if mob.components.transparent and (not mob.components.transparent:GetUpdate()) then
		mob.components.transparent:Start(mob)
	end
end

local Transparent = Class(function(self, inst)
	self.inst = inst
	self.alpha = 1
	self.shadow = true
	self.isupdate = false
end)

function Transparent:GetInst()
	return self.inst
end

function Transparent:SetAlpha(alpha)
	self.alpha = alpha
end

function Transparent:GetAlpha()
	return self.alpha or 1
end

function Transparent:SetShadow(shadow)
	self.shadow = shadow
end

function Transparent:GetShadow()
	return self.shadow
end

function Transparent:GetUpdate()
	return self.isupdate
end

function Transparent:OnUpdate(dt)
	if ThePlayer then
		if ThePlayer == self.inst then 
			ThePlayer.components.transparent:SetAlpha(self.inst.MobsPlayersAlpha:value())
			ThePlayer.components.transparent:SetShadow(self.inst.MobsPlayersShadowEnable:value())
			return 
		end 
		if (ThePlayer.components.transparent:GetAlpha() ~= self.alpha 
				or ThePlayer.components.transparent:GetShadow() ~= self.shadow) then
			self.alpha  = ThePlayer.components.transparent:GetAlpha()
			self.shadow = ThePlayer.components.transparent:GetShadow()
			PushAlpha(self.inst, self.alpha, self.shadow)
		end
	end
end

function Transparent:ChangeSound(MIXON)
	if MIXON then
		_G.TheMixer:PushMix("infernal_silence")
	else	
		_G.TheMixer:PopMix("infernal_silence")
	end
end

function Transparent:Start()
	self.inst:StartUpdatingComponent(self)
	self.isupdate = true
	--[[
	if ThePlayer == self.inst then
		UpdateEnts(self.inst,false)
		_G.TheWorld:ListenForEvent("on_spawned_mob", NonUpdateMobSpawn)
	end ]]--
end

function Transparent:Stop()
	self.inst:DoTaskInTime(0.1,function()
		self.inst:StopUpdatingComponent(self)
		self.isupdate = false
		--[[
		if ThePlayer == self.inst then
			UpdateEnts(self.inst,true)
			_G.TheWorld:RemoveEventCallback("on_spawned_mob", NonUpdateMobSpawn)
		end ]]--
	end)
end

Transparent.OnRemoveEntity = Transparent.Stop
Transparent.OnRemoveFromEntity = Transparent.Stop

return Transparent
