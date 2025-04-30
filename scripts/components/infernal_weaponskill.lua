local Infernal_weaponskill = Class(function(self, inst)
	self.inst = inst
	
	self.LClickFn = nil
	self.RClickFn = nil

	self.Lcooldown = 1
	self.Rcooldown = 10
end)

function Infernal_weaponskill:Set_LClickFn(fn)
	self.LClickFn = fn
end

function Infernal_weaponskill:Set_RClickFn(fn)
	self.RClickFn = fn
end

function Infernal_weaponskill:Set_LClickcooldown(cooldown)
	self.Lcooldown = cooldown
end

function Infernal_weaponskill:Set_RClickcooldown(cooldown)
	self.Rcooldown = cooldown
end

function Infernal_weaponskill:Cast_LClick(inst, caster, target)
	if self.LClickFn then
		self.LClickFn(inst, caster, target)
	else
		print("need to set LClickFN!")
	end
end

function Infernal_weaponskill:Cast_RClick(inst, caster, target)
	if self.RClickFn then
		self.RClickFn(inst, caster, target)
	else
		print("need to set RClickFN!")
	end
end

return Infernal_weaponskill
