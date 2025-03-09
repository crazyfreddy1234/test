local common_brain = require("brains/common_dunguen_brain_functions")

local BoaronBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function BoaronBrain:OnStart()    
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst))
end

return BoaronBrain