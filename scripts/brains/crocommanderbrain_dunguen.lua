local common_brain = require("brains/common_dunguen_brain_functions")
local tuning_values = TUNING.FORGE.CROCOMMANDER


local CrocommanderBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function CrocommanderBrain:OnStart()
	local nodes = {
        MeleeRangeSwap(self.inst, tuning_values.SWAP_ATTACK_MODE_RANGE, self.inst.weapon, tuning_values.SPIT_ATTACK_RANGE, tuning_values.SPIT_HIT_RANGE, tuning_values.ATTACK_RANGE, tuning_values.HIT_RANGE, tuning_values.ATTACK_PERIOD)
    }
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst, nil, nil, nodes))
end

return CrocommanderBrain
