local Infernal_Power = Class(function(self, inst)
	self.inst = inst

	self.power = 0
	self.maxpower = 100
	self.downpersecTask = nil
	self.ratescale = 1
	self.cooldown = 10
	self.cooldownrate = 1 --per sec

	self:ActiveDownPerSec()
end)

function Infernal_Power:GetRateScale()
    return self.ratescale
end

function Infernal_Power:GetPower()
	return self.power
end

function Infernal_Power:GetMaxPower()
    return self.maxpower
end

function Infernal_Power:SetPower(power)
	local oldPower = self.power
	self.power = math.clamp(power,0,self.maxpower)
	self.inst.InfernalPower:set(self.power)
	self.inst:PushEvent("infernalpowerdelta", { old = oldPower, new = self.power })
end

function Infernal_Power:SetCoolDown(cooldown)
	self.cooldown = cooldown
end

function Infernal_Power:DoDelta(power)
	local oldPower = self.power
	self.power = math.clamp(self.power + power,0,self.maxpower)
	self.inst.InfernalPower:set(self.power)
	self.inst:PushEvent("infernalpowerdelta", { old = oldPower, new = self.power })
end

function Infernal_Power:ActiveDownPerSec()
	if self.downpersecTask == nil then
		self.downpersecTask = self.inst:DoPeriodicTask(1,function() self:DoDelta(-0.5) end)
	end
end

function Infernal_Power:DeactiveDownPerSec()
	if self.downpersecTask ~= nil then
		self.downpersecTask:Cancel()
		self.downpersecTask = nil
	end
end

return Infernal_Power
