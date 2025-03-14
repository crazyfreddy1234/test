--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]
local common_brain = require("brains/common_dunguen_brain_functions")
require "behaviours/useshield_forge"

local SnortoiseBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local DAMAGE_UNTIL_SHIELD = 50 -- TODO 140 --rough estimate
local SHIELD_TIME = 4
local SHIELD_COOLDOWN = 12

function SnortoiseBrain:OnStart()
    local nodes = {
		UseShield_Forge(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, SHIELD_COOLDOWN, true),
    }
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst, nil, nil, nodes))
end

return SnortoiseBrain
