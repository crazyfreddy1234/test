local Infernal_Skill = Class(function(self, inst)
	self.inst = inst
	self.name = "skill"

	--ACTIVE--
	self.isactive = true
	self.cost = 50
	self.cooldown = 0
	self.maxcooldown = 10
	self.cooldownrate = 1
	self.cooldownamount = 1
	self.skill = nil
	self.cooldowntask = nil
	self.canskill = true
	self.color_r = 1
	self.color_g = 1
	self.color_b = 1
	self.color_d = 1

	--PASSIVE--
	self.ispassive = false

	--ONOFF--
	self.isonoff = false
end)

function Infernal_Skill:SetSkillToActive()
	self.isactive = true
	self.ispassive = false
	self.isonoff = false
end

function Infernal_Skill:SetSkillToPassive()
	self.isactive = false
	self.ispassive = true
	self.isonoff = false
end

function Infernal_Skill:SetSkillToOnOff()
	self.isactive = false
	self.ispassive = false
	self.isonoff = true
end

function Infernal_Skill:SetName(name)
	self.name = name
end

-------------------------------------------------------------------------------------
--------------------------------------ACTIVE-----------------------------------------
-------------------------------------------------------------------------------------

function Infernal_Skill:SetCost(cost)
	self.cost = cost
end

function Infernal_Skill:SetMaxCoolDown(maxcooldown)
	self.maxcooldown = maxcooldown
end

function Infernal_Skill:SetCoolDownRate(cooldownrate)
	self.cooldownrate = 1/cooldownrate
end

function Infernal_Skill:SetSkill(fn)
	self.skill = fn
end

function Infernal_Skill:SetBackgroundColor(r,g,b,d)
	self.color_r = r or 1
	self.color_g = g or 1
	self.color_b = b or 1
	self.color_d = d or 1
end

function Infernal_Skill:FinishCoolDown()
	self.canskill = true
	if self.cooldowntask ~= nil then
		self.cooldowntask:Cancel()
		self.cooldowntask = nil
	end
	self.inst:PushEvent("infernal_skill_cooldown_end")
end

function Infernal_Skill:CoolDownDelta(delta)
	local oldCoolDown = self.cooldown

	self.cooldown = math.clamp(self.cooldown-delta,0,self.maxcooldown)

	self.inst:PushEvent("infernal_skill_cooldown_delta", { old = oldCoolDown, new = self.cooldown })

	print(oldCoolDown,self.cooldown)

	if oldCoolDown <= 0 and self.cooldown > 0 then
		self:StartCoolDown(delta)
	end
	if self.cooldown <= 0 then
		self:FinishCoolDown()
	end
end

function Infernal_Skill:StartCoolDown(cooldown)
	self.cooldown = cooldown or 10
	self.canskill = false
	self.inst:PushEvent("infernal_skill_cooldown_start",{cooldown = cooldown})

	self.cooldowntask = self.inst:DoPeriodicTask(self.cooldownrate,function()
		self:CoolDownDelta(self.cooldownamount)
	end)
end

function Infernal_Skill:CoolDownRateDelta(cooldownrate)
	self.cooldownrate = cooldownrate
	if self.cooldowntask ~= nil then
		self.cooldowntask:Cancel()
		self.cooldowntask = nil

		self.cooldowntask = self.inst:DoPeriodicTask(self.cooldownrate,function()
			self:CoolDownDelta(self.cooldownamount)
		end)
	end
end

function Infernal_Skill:CoolDownAmountDelta(cooldownamount)
	self.cooldownamount = cooldownamount
	if self.cooldowntask ~= nil then
		self.cooldowntask:Cancel()
		self.cooldowntask = nil

		self.cooldowntask = self.inst:DoPeriodicTask(self.cooldownrate,function()
			self:CoolDownDelta(self.cooldownamount)
		end)
	end
end

function Infernal_Skill:Active()
	if self.canskill ~= true then return end
	if self.inst.components.infernal_power and self.inst.components.infernal_power:GetPower() < self.cost then
		print("no mana!")
		return
	end

	self:StartCoolDown(self.maxcooldown)
	self.inst:PushEvent("infernal_skill_active")

	if self.inst.components.infernal_power ~= nil then
		local cost = self.cost
		self.inst.components.infernal_power:DoDelta(-cost)
	end
	if self.skill ~= nil then
		self.skill(self.inst)
		print("skill active")
	else
		print("no skill")
	end
end

return Infernal_Skill
