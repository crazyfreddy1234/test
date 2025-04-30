local common_brain = require("brains/common_dunguen_brain_functions")

local BoarillaBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function BoarillaBrain:OnStart()
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst))
end

return BoarillaBrain
