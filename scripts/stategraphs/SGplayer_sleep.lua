local wilson_sg = require "stategraphs/SGwilson"
wilson_sg.name = "wilson_sleep"

local SLEEP_TIME = 4

local _oldSleep = wilson_sg.states.knockout
local _oldWakeUp = wilson_sg.states.wakeup

local _oldOnEnterSleep = _oldSleep.onenter
local _oldTimeOutSleep = _oldSleep.ontimeout
local _oldOnEnterWakeUp = _oldWakeUp.onenter
local _oldOnExitWakeUp = _oldWakeUp.onexit

local function SetSleeperSleepState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:AddImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:IgnoreAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Disable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(false)
        inst.components.playercontroller:Enable(false)
    end
    inst:OnSleepIn()
    inst.components.inventory:Hide()
    inst:PushEvent("ms_closepopups")
    inst:ShowActions(false)
end

local function SetSleeperAwakeState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:RemoveImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:StopIgnoringAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Enable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(true)
        inst.components.playercontroller:Enable(true)
    end
    inst:OnWakeUp()
    if not (inst.components.health.currenthealth <= 0) and inst:IsValid() then
        inst.components.inventory:Show()
    end
    inst:ShowActions(true)
end

_oldSleep.onenter = function(inst)
    inst.components.locomotor:Stop()
    inst:ClearBufferedAction()

    inst.sg.statemem.isinsomniac = inst:HasTag("insomniac")

    if inst.components.rider:IsRiding() then
        inst.sg:AddStateTag("dismounting")
        inst.AnimState:PlayAnimation("fall_off")
        inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
    else
        inst.AnimState:PlayAnimation(inst.sg.statemem.isinsomniac and "insomniac_dozy" or "dozy")
    end

    SetSleeperSleepState(inst)

    inst.sg:SetTimeout(SLEEP_TIME)
end

_oldSleep.ontimeout= function(inst)
    inst.sg.statemem.iswaking = true
    inst.sg:GoToState("wakeup")
end

_oldWakeUp.onexit = function(inst)
    SetSleeperAwakeState(inst)
    if inst.sg.statemem.isresurrection then
        inst:ShowHUD(true)
        inst:SetCameraDistance()
        SerializeUserSession(inst)
    end
    if inst.sg.statemem.goodsleep then
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_COZY_SLEEP"))
    end
end

return wilson_sg

