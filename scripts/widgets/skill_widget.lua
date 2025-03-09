local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local function SetValue(inst,data)
    if data.new and inst.HUD.controls.status.skillwidget then
        inst.HUD.controls.status.skillwidget.num:SetString(tostring(math.ceil(data.new)))

        if data.new <= 0 then
            inst.HUD.controls.status.skillwidget.num:Hide()
        else
            inst.HUD.controls.status.skillwidget.num:Show()
        end
    elseif data.cooldown and inst.HUD.controls.status.skillwidget then
        inst.HUD.controls.status.skillwidget.num:SetString(tostring(math.ceil(data.cooldown)))
        
        if data.cooldown <= 0 then
            inst.HUD.controls.status.skillwidget.num:Hide()
        else
            inst.HUD.controls.status.skillwidget.num:Show()
        end
    end
end

local SkliiWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "SkliiWidget")
    self.owner = owner

    self:SetPosition(0, 0, 0)

    self.skill = 0

    --self.bg clashes with existing mods
    self.backing = self:AddChild(UIAnim())
    self.backing:GetAnimState():SetBank("status_meter")
    self.backing:GetAnimState():SetBuild("status_wet")
    self.backing:GetAnimState():Hide("frame")
    self.backing:GetAnimState():Hide("icon")
    self.backing:GetAnimState():AnimateWhilePaused(false)
    self.backing:SetClickable(true)

    self.anim = self:AddChild(UIAnim())
    self.anim:GetAnimState():SetBank("status_meter")
    self.anim:GetAnimState():SetBuild("status_meter")
    self.anim:Hide("icon")
    self.anim:GetAnimState():AnimateWhilePaused(false)
    self.anim:GetAnimState():SetMultColour(1, 1, 1, 1)
    self.anim:SetClickable(false)
    self.anim:GetAnimState():SetPercent("anim",0)

    --self.frame clashes with existing mods
    self.circleframe = self:AddChild(UIAnim())
    self.circleframe:GetAnimState():SetBank("status_meter")
    self.circleframe:GetAnimState():SetBuild("status_meter")
    self.circleframe:GetAnimState():Hide("bg")
    self.circleframe:GetAnimState():AnimateWhilePaused(false)
    self.circleframe:SetClickable(true)

    self.arrowdir = "neutral"
    self.arrow = self:AddChild(UIAnim())
    self.arrow:GetAnimState():SetBank("sanity_arrow")
    self.arrow:GetAnimState():SetBuild("sanity_arrow")
    self.arrow:GetAnimState():PlayAnimation(self.arrowdir)
    self.arrow:GetAnimState():AnimateWhilePaused(false)
    self.arrow:SetClickable(false)

    self.num = self:AddChild(Text(BODYTEXTFONT, 33))
    self.num:SetHAlign(ANCHOR_MIDDLE)
    self.num:SetPosition(3, 0, 0)
    self.num:SetClickable(false)
    self.num:Hide()
    self.num:SetString(tostring(math.ceil(0)))

    self.owner:ListenForEvent("infernal_skill_cooldown_delta",SetValue)
    self.owner:ListenForEvent("infernal_skill_cooldown_start",function(inst,data)
        SetValue(inst,data)
        self:IsCoolDown(true)
    end)
    self.owner:ListenForEvent("infernal_skill_cooldown_end",function()
        self:IsCoolDown(false)
    end)
end)

function SkliiWidget:IsCoolDown(iscooldown)
    if iscooldown == true then
        self.anim:GetAnimState():SetPercent("anim",0)
        self.anim:GetAnimState():SetMultColour(0, 0, 0, 1)
    else
        self.anim:GetAnimState():SetPercent("anim",0)
        if self.owner.components.infernal_skill then
            local skill = self.owner.components.infernal_skill
            self.anim:GetAnimState():SetMultColour(skill.color_r, skill.color_g, skill.color_b, skill.color_d)
        else
            self.anim:GetAnimState():SetMultColour(1, 1, 1, 1)
        end
    end
end

-----------------------------------------------------------------------------------------------

return SkliiWidget
