local PUGNAX="workshop-2038128735"
RPXT=TUNING[PUGNAX]
RPX=TUNING.modfns and TUNING.modfns[PUGNAX]
if not (RPXT and RPX) then return end

local RPX,RPXT=RPX,RPXT
local AddGameplayTag,GetUtil,ImagePath,AddMode,AddWaveset,AddDifficulty,AddGametype,AddForgeLord=RPX.AddGameplayTag,RPX.GetUtil,RPX.ImagePath,RPX.AddMode,RPX.AddWaveset,RPX.AddDifficulty,RPX.AddGametype,RPX.AddForgeLord
local type,modimport,Asset,AddSimPostInit=type,modimport,Asset,AddSimPostInit
env._G = GLOBAL
env.require = _G.require
local RF_DATA = _G.REFORGED_DATA


--------------gametypes--------------------
local gametype = "rpx/gametypes/"
modimport(gametype.."golemdefense.lua")
modimport(gametype.."mathtest.lua")
modimport(gametype.."discolights.lua")
modimport(gametype.."discolightsrave.lua")
modimport(gametype.."blossoms.lua")

--------------functions--------------------
modimport("scripts/inforge_main.lua")
modimport("scripts/postinit/inforge_anyprefab.lua")
modimport("scripts/postinit/inforge_prefabpostinit.lua")

--------------assets--------------------
modimport("scripts/inforge_strings.lua")
_G.TUNING.INFORGE         = require("inforge_tuning")
_G.INFORGE_COMMON_FNS     = require( "inforge_common_functions")
PrefabFiles               = require("inforge_prefabs")
Assets                    = require("inforge_assets")


local Mixer = require("mixer")
local amb = "set_ambience/ambience"
local cloud = "set_ambience/cloud"
local music = "set_music/soundtrack"
local voice = "set_sfx/voice"
local movement ="set_sfx/movement"
local creature ="set_sfx/creature"
local player ="set_sfx/player"
local HUD ="set_sfx/HUD"
local sfx ="set_sfx/sfx"
local slurp ="set_sfx/everything_else_muted"

_G.TheMixer:AddNewMix("infernal_silence", 0, 8,
{
    [amb] = 0,
    [cloud] = 0,
    [music] = 1,
    [voice] = 0,
    [movement] = 0,
    [creature] = 0,
    [player] = 0,
    [HUD] = 0,
    [sfx] = 0,
    [slurp] = 0,
})

AddClassPostConstruct("components/combat_replica", function(self)
    local _oldCanTarget = self.CanTarget
    function self:CanTarget(target)
        if target and _G.COMMON_FNS.IsAlly(self.inst,target) and target:HasTag("upgrade_healer_ishere") and self.inst:HasTag("upgrade_healer") then
            return true
        end
        return _oldCanTarget(self, target)
    end

    local _oldIsValidTarget = self.IsValidTarget
    function self:IsValidTarget(target)
        if target and _G.COMMON_FNS.IsAlly(self.inst,target) and target:HasTag("upgrade_healer_ishere") and self.inst:HasTag("upgrade_healer") then           
            return true
        end
        return _oldIsValidTarget(self, target)
    end
end)


local force_start_display = {
    announcement = function(result, results, params)
        return result == 1 and _G.STRINGS.REFORGED.VOTE.FORCE_START_SUCCESS or _G.STRINGS.REFORGED.VOTE.FORCE_START_FAILED
    end,
    title = function(initiator, params)
        return _G.STRINGS.REFORGED.VOTE.FORCE_START_TITLE
    end
}

local function force_start_oncompletefn(result, results)
    if result == 1 then
        TheWorld:PushEvent("answer_yes")
    else
        TheWorld:PushEvent("answer_no")
    end
end
local force_start_opts = {
    oncompletefns = {
        server = force_start_oncompletefn,
    },
}
AddVoteCommand("the_choice", force_start_opts, force_start_display)

local function WagstaffOnChangedTo(inst)
    inst.Work = function(inst)
        inst:PushEvent("work")
    end
    inst.Idle = function(inst, dest)
        inst:PushEvent("idle")
    end
end
local function WagstaffOnChangedFrom(inst)
    inst.Work = nil
    inst.Idle = nil
end
local wagstaff_opts={
	nameoverride="boarlord_wagstaff",
	scale={1,1},
    avatar={
        bank   = "wagstaff_dialogue",
		build  = "wagstaff_dialogue",
        colour = {84/255, 93/255, 144/255, 1},
	},
	on_changed_to_fn   = WagstaffOnChangedTo,
    on_changed_from_fn = WagstaffOnChangedFrom,	
}
AddForgeLord("wagstaff","wilson","wagstaff","SGwagstaff",wagstaff_opts,10)

local Reminiscence_icon = {atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"}
local TotalWar_icon     = {atlas = "images/totalwar64.xml", tex = "totalwar64.tex"}
local wagstaff_icon     = {atlas = "images/64wagstafficon.xml", tex = "64wagstafficon.tex"}
local Reflection_icon   = {atlas = "images/mirror.xml", tex = "mirror.tex"}

local golemdefense_icon = {atlas = "images/golemdefenceicon64.xml", tex = "golemdefenceicon64.tex"}
local mathtest_icon     = {atlas = "images/MATH64.xml", tex = "MATH64.tex"}

local exp=nil

local Reminiscence_exp = {
    {desc = "ORDINARY_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1 * 1.5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "ORDINARY_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * 1.5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "ORDINARY_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3 * 1.5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "ORDINARY_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4 * 1.5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "ORDINARY_MILESTONE_5", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5 * 1.5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "ORDINARY_WIN",         val = TUNING.FORGE.EXP.WAVESETS.VICTORY * 1.5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
}
AddWaveset("Ordinary",3,Reminiscence_icon,Reminiscence_exp)

local Extraordinary_exp = {
    {desc = "EXTRAORDINARY_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1 * 5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "EXTRAORDINARY_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * 5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "EXTRAORDINARY_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3 * 5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "EXTRAORDINARY_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4 * 5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "EXTRAORDINARY_MILESTONE_5", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5 * 5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "EXTRAORDINARY_WIN",         val = TUNING.FORGE.EXP.WAVESETS.VICTORY * 5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
}
AddWaveset("Extraordinary",3,Reminiscence_icon,Extraordinary_exp)


local TotalWar_exp = {
    {desc = "TOTALWAR_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1,atlas = "images/totalwar64.xml", tex = "totalwar64.tex"},
    {desc = "TOTALWAR_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * 3,atlas = "images/totalwar64.xml", tex = "totalwar64.tex"},
    {desc = "TOTALWAR_WIN",         val = TUNING.FORGE.EXP.WAVESETS.VICTORY * 5,atlas = "images/totalwar64.xml", tex = "totalwar64.tex"},
}
AddWaveset("TotalWar",3,TotalWar_icon,TotalWar_exp)


local Scientific_Expedition_exp = {
    {desc = "SCIENTIFIC_EXPEDITION_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1,atlas = "images/64wagstafficon.xml", tex = "64wagstafficon.tex"},
    {desc = "SCIENTIFIC_EXPEDITION_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2,atlas = "images/64wagstafficon.xml", tex = "64wagstafficon.tex"},
    {desc = "SCIENTIFIC_EXPEDITION_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4 * 3,atlas = "images/64wagstafficon.xml", tex = "64wagstafficon.tex"},
    {desc = "SCIENTIFIC_EXPEDITION_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5 * 3,atlas = "images/64wagstafficon.xml", tex = "64wagstafficon.tex"},
    {desc = "SCIENTIFIC_EXPEDITION_WIN",         val = TUNING.FORGE.EXP.WAVESETS.VICTORY * 3,atlas = "images/64wagstafficon.xml", tex = "64wagstafficon.tex"},
}
AddWaveset("Scientific_Expedition",3,wagstaff_icon,Scientific_Expedition_exp,"wagstaff")

local TotalWar2_exp = {
    {desc = "TOTALWAR2_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1,atlas = "images/totalwar64.xml", tex = "totalwar64.tex"},
    {desc = "TOTALWAR2_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2 * 3,atlas = "images/totalwar64.xml", tex = "totalwar64.tex"},
    {desc = "TOTALWAR2_WIN",         val = TUNING.FORGE.EXP.WAVESETS.VICTORY * 5,atlas = "images/totalwar64.xml", tex = "totalwar64.tex"},
}
AddWaveset("TotalWar2",3,TotalWar_icon,TotalWar2_exp)
--_G.REFORGED_DATA.wavesets["TotalWar2"].power_on = false

local Winter_exp = {
    {desc = "WINTER_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "WINTER_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "WINTER_MILESTONE_3", val = TUNING.FORGE.EXP.WAVESETS.ROUND_3,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "WINTER_MILESTONE_4", val = TUNING.FORGE.EXP.WAVESETS.ROUND_4,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "WINTER_MILESTONE_5", val = TUNING.FORGE.EXP.WAVESETS.ROUND_5,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
    {desc = "WINTER_WIN",         val = TUNING.FORGE.EXP.WAVESETS.VICTORY,atlas = "images/reminiscenceicon64.xml", tex = "reminiscenceicon64.tex"},
}
--AddWaveset("Winter",3,Reminiscence_icon,Winter_exp)



local Golem_Defense_exp = {desc = "GOLEMDEFENSE_WIN", val = {mult = 3},atlas = "images/golemdefenceicon64.xml", tex = "golemdefenceicon64.tex"}
AddGametype("golemdefense",nil,golemdefense_icon,Golem_Defense_exp)


local MATH_TEST_exp = {desc = "MATHTEST_WIN", val = {mult = 3},atlas = "images/MATH64.xml", tex = "MATH64.tex"}
AddGametype("mathtest",nil,mathtest_icon,MATH_TEST_exp)





local Reflection_exp = {
    {desc = "REFLECTION_MILESTONE_1", val = TUNING.FORGE.EXP.WAVESETS.ROUND_1*5,atlas = "images/mirror.xml", tex = "mirror.tex"},
    {desc = "REFLECTION_MILESTONE_2", val = TUNING.FORGE.EXP.WAVESETS.ROUND_2*5,atlas = "images/mirror.xml", tex = "mirror.tex"},
    {desc = "REFLECTION_WIN",         val = TUNING.FORGE.EXP.WAVESETS.VICTORY*5,atlas = "images/mirror.xml", tex = "mirror.tex"},
}
AddSimPostInit(function()
    if TUNING.HALLOWED_FORGE then 
        AddWaveset("Reflection",3,Reflection_icon,Reflection_exp,nil,3.5,"hallowedforge")

        RF_DATA.wavesets.Reflection.must_map = "chapter1_cave"
    end
end)

