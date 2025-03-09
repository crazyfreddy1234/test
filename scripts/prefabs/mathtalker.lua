local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require "widgets/uianim"

local assets = {
    Asset("ANIM", "anim/boarlord.zip"),
    Asset("ANIM", "anim/lavaarena_boarlord_dialogue.zip"),
}

local function SpeechRootKillTask(speechroot_inst, inst)
    if inst.speechroot ~= nil then
        if inst.speechroot.inst:IsValid() then
            inst.speechroot:Kill()
        end
        inst.speechroot = nil
    end
end

local function OnTalk(inst, data)
	if data ~= nil and data.message ~= nil and ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer:IsValid() then
		if inst.speechroot == nil then
			--inst.speech_parent = ThePlayer.HUD.eventannouncer
			--inst.speech_parent:SetPosition(0, -70)
			inst.speechroot = Widget("speech root")
            local settings = {
                bank      = "",
                build     = "",
                anim      = "dialogue_loop",
                font      = UIFONT,
                font_size = 40,
                colour    = {247/255, 165/255, 68/255, 1},
                offset    = Vector3(0,-70,0),
            }
            MergeTable(settings, inst.avatar or {}, true)
			local speech_text = inst.speechroot:AddChild(Text(settings.font, settings.font_size, nil, settings.colour)) -- TALKINGFONT, UIFONT

			local speech_head = inst.speechroot:AddChild(UIAnim())
			speech_head:GetAnimState():SetBuild(settings.build)
			speech_head:GetAnimState():SetBank(settings.bank)
			speech_head:GetAnimState():PushAnimation(settings.anim, true)
			speech_head:SetClickable(false)
			speech_head:SetScale(0.4)

            ThePlayer.HUD:AddTalker(inst.speechroot, settings.offset)
            inst.speechroot:MoveToBack()

			inst.speechroot.SetTint = function(obj, r, g, b, a)
				local cr, cb, cg = unpack(speech_text:GetColour())
				speech_text:SetColour(cr, cb, cg, a)
			end

			inst.speechroot.SetSpeechString = function(s)
				inst.speechroot:SetTint(1, 1, 1, 0)
				inst.speechroot:TintTo({ r=1, g=1, b=1, a=0 }, { r=1, g=1, b=1, a=1 }, .3)

				speech_text:SetString(s)

				local x = speech_text:GetRegionSize()
				speech_head:SetPosition(-.5 * x - 35, 0)
			end

			inst:ListenForEvent("onremove", function()
				if inst.speech_parent ~= nil and inst.speech_parent.inst:IsValid() then
					inst.speech_parent:SetPosition(0, 0)
					inst.speech_parent = nil
				end
                if inst.speechroot ~= nil and ThePlayer ~= nil and ThePlayer.HUD ~= nil then
                    ThePlayer.HUD:RemoveTalker(inst.speechroot)
                end
				inst.speechroot = nil
			end, inst.speechroot.inst)
		end
		if inst.speechroot ~= nil then
			if inst.speechroot.inst.killtask ~= nil then
				inst.speechroot.inst.killtask:Cancel()
				inst.speechroot.inst.killtask = nil
			end

			inst.speechroot.SetSpeechString(data.message)
		end
	elseif inst.speechroot ~= nil and inst.speechroot.inst:IsValid() then
		inst.speechroot.inst.killtask = inst.speechroot.inst:DoTaskInTime(.5, SpeechRootKillTask, inst)
	end
end

--------------------------------------------------------------------------
-- Pet Functions
--------------------------------------------------------------------------
local function OnRemoveEntity(inst)
    if inst.speechroot ~= nil then
        inst.speechroot:Kill()
        inst.speechroot = nil
    end
end
--------------------------------------------------------------------------
local function common_fn()
    local inst = CreateEntity()
    ------------------------------------------
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    ------------------------------------------
    inst:AddTag("talker")
    ------------------------------------------
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -900, 0)
    inst.components.talker.disablefollowtext = true
    inst.components.talker.ontalkfn = OnTalk
    inst.components.talker.donetalkingfn = OnTalk
    inst.components.talker.resolvechatterfn = function(inst, str_id, str_tbl) return str_tbl:value() end
    inst.components.talker:MakeChatter()
    inst.components.talker.lineduration = 3.5
    ------------------------------------------
    inst.OnRemoveEntity = OnRemoveEntity
    ------------------------------------------
    inst.entity:SetCanSleep(false)
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return Prefab("math_talker", common_fn, assets)
