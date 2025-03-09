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
require "behaviours/victorypose_forge"

local SwineclopsBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetNoBusyTags(inst) -- TODO can't busy just be used?
	return not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("busy"))
end

local function ShouldChaseAndAttack(inst)
    return TheWorld.components.lavaarenaevent.victory ~= false
end

-- TODO tuning global variable MAP_RANGE
-- Add inst.avoid_healing_circle check
-- Why was notarget a canttag, and healingcircle a mustoneoftags?
local function AvoidHealAuras(inst) -- TODO common fn, it's in boarrior as well
    --local x, y, z = inst.Transform:GetWorldPosition()
    return inst.avoid_heal_auras and COMMON_FNS.GetHealAuras(inst)--TheSim:FindEntities(x, y, z, 255, {"healingcircle"}) or {}
end

local behaviour_values = {
    chaseandattack_condition_fn = ShouldChaseAndAttack,
    wander_condition_fn = ShouldChaseAndAttack,
    findavoidanceobjectsfn = AvoidHealAuras,
    avoid_dist = 4, -- TODO tuning?
}

function SwineclopsBrain:OnStart()
    local nodes = {
		-- Victory Pose
		WhileNode(function() return TheWorld.components.lavaarenaevent.victory == false and GetNoBusyTags(self.inst) end, "Pose", VictoryPose_Forge(self.inst)),
    }
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst, nil, behaviour_values, nodes))
end

return SwineclopsBrain
