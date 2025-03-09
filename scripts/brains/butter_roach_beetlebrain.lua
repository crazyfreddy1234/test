local common_brain = require("brains/common_brain_functions")
local tuning_values = TUNING.FORGE.ROACH_BEETLE

local ButterRoachBeetleBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function ButterRoachBeetleBrain:OnStart()
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst))
end

return ButterRoachBeetleBrain
