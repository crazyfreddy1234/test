local TIMEOUT = 5

local function OnRemoveCleanupTargetFX(inst)
    if inst.sg.statemem.targetfx.KillFX ~= nil then
        inst.sg.statemem.targetfx:RemoveEventCallback("onremove", OnRemoveCleanupTargetFX, inst)
        inst.sg.statemem.targetfx:KillFX()
    else
        inst.sg.statemem.targetfx:Remove()
    end
end

local CheckPreviewChannelCastAction --forward declare

local function StopPreviewChannelCast(inst)
	if inst.sg.mem.preview_channelcast_task then
		inst.sg.mem.preview_channelcast_task:Cancel()
		inst.sg.mem.preview_channelcast_task = nil
		inst.sg.mem.preview_channelcast_action = nil
		inst:RemoveEventCallback("performaction", CheckPreviewChannelCastAction)
		inst.components.locomotor:RemovePredictExternalSpeedMultiplier(inst, "preview_channelcast")
	end
end

CheckPreviewChannelCastAction = function(inst)
	if inst:IsChannelCasting() == (inst.sg.mem.preview_channelcast_action.action == _G.ACTIONS.START_CHANNEL_HEALING) then
		StopPreviewChannelCast(inst)
	end
end

local function StartPreviewChannelCast(inst, buffaction)
	if buffaction.action == _G.ACTIONS.START_CHANNEL_HEALING then
        if inst:IsChannelCasting() then
			StopPreviewChannelCast(inst)
			return
		end
		inst.components.locomotor:SetPredictExternalSpeedMultiplier(inst, "preview_channelcast", TUNING.CHANNELCAST_SPEED_MOD)
	elseif buffaction.action == _G.ACTIONS.STOP_CHANNEL_HEALING then
		if not inst:IsChannelCasting() then
			StopPreviewChannelCast(inst)
			return
		end
		inst.components.locomotor:SetPredictExternalSpeedMultiplier(inst, "preview_channelcast", 1 / TUNING.CHANNELCAST_SPEED_MOD)
	else
		StopPreviewChannelCast(inst)
		return
	end

	if inst.sg.mem.preview_channelcast_task then
		inst.sg.mem.preview_channelcast_task:Cancel()
	else
		inst:ListenForEvent("performaction", CheckPreviewChannelCastAction)
	end
	inst.sg.mem.preview_channelcast_task = inst:DoTaskInTime(TIMEOUT, StopPreviewChannelCast)
	inst.sg.mem.preview_channelcast_action = buffaction
end


local function IsChannelCastingItem(inst)
	--essentially prediction, since the actions aren't busy w/ lag states
	local buffaction = inst.sg.mem.preview_channelcast_action
	if buffaction then
		return buffaction.invobject ~= nil
		--Don't use "or inst:IsChannelCastingItem()"
		--We want to be able to return false here when predicting!
	end
	--otherwise return server state
	return inst:IsChannelCastingItem()
end



return {
    CLIENT_STATES = {
        State{
            name = "start_channelcast_inforge",
            tags = { "idle", "canrotate"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
                if inst.actionfailedevent == nil then
                    inst.actionfailedevent = inst:ListenForEvent("actionfailed", function(inst, data) print(reason) end)
                end
                if inst.bufferedaction then
                    inst:PerformPreviewBufferedAction()
                    StartPreviewChannelCast(inst, inst.bufferedaction)
                end
                if IsChannelCastingItem(inst) then
                    inst.sg.statemem.channelcastitem = true
                    inst.AnimState:PlayAnimation("channelcast_idle_pre")
                    inst.AnimState:PushAnimation("channelcast_idle")
                else
                    inst.AnimState:PlayAnimation("channelcast_oh_idle_pre")
                    inst.AnimState:PushAnimation("channelcast_oh_idle")
                end
                inst.sg:SetTimeout(TIMEOUT)
            end,

            onupdate = function(inst)
                if inst:IsChannelCasting() then
                    if inst.entity:FlattenMovementPrediction() then
                        StopPreviewChannelCast(inst)
                        inst.sg:GoToState("idle", "noanim")
                    else
                    end
                elseif inst.bufferedaction == nil then
                    inst.AnimState:PlayAnimation(inst.sg.statemem.channelcastitem and "channelcast_idle_pst" or "channelcast_oh_idle_pst")
                    inst.sg:GoToState("idle", true)
                end
            end,

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.AnimState:PlayAnimation("channelcast_idle_pst")
                inst.sg:GoToState("idle", true)
            end,
        },

        State{
            name = "stop_channelcast_inforge",
            tags = { "idle", "canrotate" },
            server_states = { "stop_channelcast_inforge" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                if inst.bufferedaction then
                    inst:PerformPreviewBufferedAction()
                    StartPreviewChannelCast(inst, inst.bufferedaction)
                end
                if IsChannelCastingItem(inst) then
                    inst.sg.statemem.channelcastitem = true
                    inst.AnimState:PlayAnimation("channelcast_idle_pst")
                else
                    inst.AnimState:PlayAnimation("channelcast_oh_idle_pst")
                end
                inst.AnimState:PushAnimation("idle_loop")
                inst.sg:SetTimeout(TIMEOUT)
            end,

            onupdate = function(inst)
                if not inst:IsChannelCasting() then
                    if inst.entity:FlattenMovementPrediction() then
                        StopPreviewChannelCast(inst)
                        inst.sg:GoToState("idle", "noanim")
                    end
                elseif inst.bufferedaction == nil then
                    inst.AnimState:PlayAnimation(inst.sg.statemem.channelcastitem and "channelcast_idle_pre" or "channelcast_oh_idle_pre")
                    inst.sg:GoToState("idle", true)
                end
            end,

            ontimeout = function(inst)
                print("time out")
                inst:ClearBufferedAction()
                inst.AnimState:PlayAnimation(inst.sg.statemem.channelcastitem and "channelcast_idle_pre" or "channelcast_oh_idle_pre")
                inst.sg:GoToState("idle", true)
            end,
        },

        State{
            name = "castspellmind_inforge",
            tags = { "doing", "busy", "canrotate" },
            server_states = { "castspellmind_inforge" },

            onenter = function(inst)
                inst.components.locomotor:Stop()

                if inst:HasTag("canrepeatcast") and inst.entity:FlattenMovementPrediction() then
                    inst:PerformPreviewBufferedAction()
                    inst.sg:GoToState("idle", "noanim")
                    return
                end

                inst.AnimState:PlayAnimation("pyrocast_pre")
                inst.AnimState:PushAnimation("pyrocast_lag", false)

                inst:PerformPreviewBufferedAction()
                inst.sg:SetTimeout(TIMEOUT)
            end,

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end,
        },
    },
    SERVER_STATES = {
        State{
            name = "start_channelcast_inforge",

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst:PerformBufferedAction()
                inst.AnimState:PlayAnimation("channelcast_idle_pre")
                inst.sg:GoToState("idle", true)
            end,
        },
        State{
            name = "stop_channelcast_inforge",

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("channelcast_idle_pst")
                inst:PerformBufferedAction()
                inst.sg:GoToState("idle", true)
            end,
        },
        State{
            name = "castspellmind_inforge",
            tags = { "doing", "busy", "canrotate" },

            onenter = function(inst, repeatcast)
                inst.SoundEmitter:PlaySound("meta3/willow/pyrokinetic_activate")

                if repeatcast then
                    inst.AnimState:PlayAnimation("pyrocast")
                    inst.sg.statemem.repeatcast = true
                else
                    inst.AnimState:PlayAnimation("pyrocast_pre") --4 frames
                    inst.AnimState:PushAnimation("pyrocast", false)
                end
                inst:PerformBufferedAction()
                inst.components.locomotor:Stop()
            end,

            events =
            {
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                inst:RemoveTag("canrepeatcast")
                if inst.sg.statemem.targetfx and inst.sg.statemem.targetfx:IsValid() then
                    OnRemoveCleanupTargetFX(inst)
                end
            end,
        },
    },
}
