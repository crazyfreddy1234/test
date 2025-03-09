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

require("stategraphs/commonforgestates")

local events = {
	CommonForgeHandlers.OnTalk(),
    EventHandler("work", function(inst, data)
        if inst.sg:HasStateTag("nointerrupt") then
            inst.sg:GoToState("work", data)
        else
            inst.sg.mem.wants_to_work = true
        end
    end),
    EventHandler("idle", function(inst, data)
        if inst.sg:HasStateTag("nointerrupt") then
            inst.sg:GoToState("idle", data)
        else
            inst.sg.mem.wants_to_idle = true
        end
    end),
    EventHandler("ontalk",function(inst, data) inst.sg:GoToState("talk") end)
}

local states = {
    State{
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:Hide("ARM_carry")

            if inst.sg.mem.wants_to_work then
                inst.sg:GoToState("work")
                inst.sg.mem.wants_to_work = nil
            else
                inst.AnimState:PlayAnimation("emote_impatient", true)               
            end
        end,

        events ={
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
	State{
        name = "work",
        tags = {"idle"},
        onenter = function(inst)
            if inst.sg.mem.wants_to_idle then
                inst.sg:GoToState("idle")
                inst.sg.mem.wants_to_idle = nil
            else
                inst.AnimState:PlayAnimation("build_loop", true)               
            end
            
        end,

        events ={
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("work")
                end
            end),
        },
    },
    State{
        name="talk",
        tags={"talking"},
        onenter=function(inst)
            if inst.components.locomotor~=nil then 
                inst.components.locomotor:Stop()
            end
            inst.SoundEmitter:PlaySound("moonstorm/characters/wagstaff/talk_single")
            inst.AnimState:PlayAnimation("dial_loop",true)
        end,
        events=
        {
            EventHandler("animover",function(inst) inst.sg:GoToState("idle") end)
        }
    },
}

return StateGraph("waggstaff", states, events, "idle")
