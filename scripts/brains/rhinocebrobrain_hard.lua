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
local rhinocebro_brain = deepcopy(require("brains/rhinocebrobrain"))
require "behaviours/maintaindistance"

local function IsBusy(inst)
    return inst.sg:HasStateTag("busy")
end
local function GetBro(inst)
    --print("Getting bro " .. tostring(inst.bro))
    return inst.bro
end
local function IsBroDead(inst)
    return inst.bro and inst.bro.components.health and inst.bro.components.health:IsDead()
end
local MAX_HEAT = 300 -- 10 seconds
local function IsChestBumpReady(inst)
    return inst.heat and (inst.heat >= MAX_HEAT and inst.bro.heat >= MAX_HEAT)
end
-- Do Chest Bump if both Bros are at max heat and are ready
local function StartChestBump(inst)
    --print("Checking Chest Bump...")
    if not IsBroDead(inst) and not IsBusy(inst) then
        --print("- Triggering Chest Bump...")
        inst:PushEvent("chest_bump", {initiator = true})
        inst.bro:PushEvent("chest_bump")
        return true
    end
    return false
end
local CHEST_BUMP_MIN_DISTANCE = 0
local CHEST_BUMP_MAX_DISTANCE = 2
-- Edit the cheer node and make it a chest bump node
local _oldOnStart = rhinocebro_brain.OnStart
rhinocebro_brain.OnStart = function(self)
    _oldOnStart(self)
    self.bt.root.children[3] = WhileNode(function() return not IsBroDead(self.inst) and IsChestBumpReady(self.inst) and TheWorld.components.lavaarenaevent.victory == nil and not IsBusy(self.inst) end, "Brosplosion", MaintainDistance(self.inst, GetBro, CHEST_BUMP_MIN_DISTANCE, CHEST_BUMP_MAX_DISTANCE, StartChestBump))
end

return rhinocebro_brain
