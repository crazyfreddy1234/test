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
require "behaviours/rhinocebrobuff_forge"
require "behaviours/doaction"
require "behaviours/maintaindistance"

local CHEER_MIN_DISTANCE = 6
local CHEER_MAX_DISTANCE = 8
local VICTORY_POSE_MIN_DISTANCE = 0
local VICTORY_POSE_MAX_DISTANCE = 2

local RhinocebroBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function ReviveAction(inst)
    --inst.components.locomotor:Stop() -- TODO this is here because any gotopoint that was called prior to a bro dying will first go to their prior point (if they did not already reach that point) before doing the bufferedaction, remove if not necessary
    if inst.bro and inst.bro.sg and inst.bro:HasTag("corpse") then
        return BufferedAction(inst, inst.bro, ACTIONS.REVIVE_CORPSE)
    end
end

local function IsBroDead(inst)
	return inst.bro and inst.bro.components.health and inst.bro.components.health:IsDead()
end

local function IsBusy(inst)
	--return not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("sleeping"))
    return inst.sg:HasStateTag("busy") -- TODO should it just be "busy" in general???
end

local function GetBro(inst)
    return inst.bro
end

local function StartCheer(inst)
    if inst.components.combat:IsAttackReady("cheer") and not IsBroDead(inst) and not IsBusy(inst) then
        inst:PushEvent("startcheer")
        return true
    end
    return false
end

local function ShouldChaseAndAttack(inst)
    return (not inst.bro or not IsBroDead(inst)) and TheWorld.components.lavaarenaevent.victory ~= false
end

local function ShouldWander(inst)
    return not IsBroDead(inst)
end

local function DoVictoryPose(inst)
    inst:PushEvent("victorypose")
    return true
end

local behavior_values = {
    chaseandattack_condition_fn = ShouldChaseAndAttack,
    wander_condition_fn = ShouldWander,
}

function RhinocebroBrain:OnStart()
    local nodes = {
		--Reviving takes top priority, no matter what.
		WhileNode(function() return self.inst.bro and self.inst.bro.sg and self.inst.bro:HasTag("corpse") and not self.inst.sg:HasStateTag("reviving") and not self.inst.sg:HasStateTag("knockback") end, "Reviving Bro", DoAction(self.inst, ReviveAction)),
		-- Victory Pose
        WhileNode(function() return not IsBroDead(self.inst) and TheWorld.components.lavaarenaevent.victory == false and not IsBusy(self.inst) and not self.inst.sg:HasStateTag("posing") end, "Bro Posing", MaintainDistance(self.inst, GetBro, VICTORY_POSE_MIN_DISTANCE, VICTORY_POSE_MAX_DISTANCE, DoVictoryPose)),
		-- Buff
        WhileNode(function() return not IsBroDead(self.inst) and self.inst.components.combat:IsAttackReady("cheer") and TheWorld.components.lavaarenaevent.victory == nil and not IsBusy(self.inst) end, "Bro Cheering", MaintainDistance(self.inst, GetBro, CHEER_MIN_DISTANCE, CHEER_MAX_DISTANCE, StartCheer)),
    }
    self.bt = BT(self.inst, common_brain.CreateMobBehaviorRoot(self.inst, nil, behavior_values, nodes))
end

return RhinocebroBrain
