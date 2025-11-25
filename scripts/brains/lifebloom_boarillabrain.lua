
local common_brain = require("brains/common_brain_functions")
require "behaviours/lifebloom_boarilla_useshield"

local LifeBloom_BoarillaBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function LifeBloom_BoarillaBrain:OnStart()
	local nodes = {
		LifeBloom_Boarilla_UseShield(self.inst),
    }
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst, nil, nil, nodes))
end

return LifeBloom_BoarillaBrain
