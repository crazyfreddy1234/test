local Widget = require "widgets/widget"
local Image = require "widgets/image"

local Inf_BloodOver =  Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "Inf_BloodOver")
    self:UpdateWhilePaused(false)

    self:SetClickable(false)

    self.bg = self:AddChild(Image("images/fx.xml", "blood_over.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self:Hide()
    self.base_level = 0
    self.level = 0
    self.k = 1

    self.time_since_pulse = 0
    self.pulse_period = 1

    local function _TurnOn() self:TurnOn() end
    local function _TurnOff() self:TurnOff() end

    self.inst:ListenForEvent("startbloodeffect", _TurnOn, owner)
    self.inst:ListenForEvent("stopbloodeffect", _TurnOff, owner)
end)

function Inf_BloodOver:TurnOn()
    --TheInputProxy:AddVibration(VIBRATION_BLOOD_FLASH, .2, .7, true)
    self:StartUpdating()
    self.base_level = .5
    self.k = 5
    self.time_since_pulse = 0
end

function Inf_BloodOver:TurnOff()
    self.base_level = 0
    self.k = 5
    --self:OnUpdate(0)
end

function Inf_BloodOver:OnUpdate(dt)
    -- ignore 0 interval
    -- ignore abnormally large intervals as they will destabilize the math in here
    if dt <= 0 or dt > 0.1 then
        return
    end

    local delta = self.base_level - self.level

    if math.abs(delta) < .025 then
        self.level = self.base_level
    else
        self.level = self.level + delta * dt * self.k
    end

    --this runs on WallUpdate so the pause check is needed.
    if self.base_level > 0 and not TheNet:IsServerPaused() then
        self.time_since_pulse = self.time_since_pulse + dt
        if self.time_since_pulse > self.pulse_period then
            self.time_since_pulse = 0

            if not IsEntityDead(self.owner) then
                TheInputProxy:AddVibration(VIBRATION_BLOOD_OVER, .2, .3, false)
            end
        end
    end

    if self.level > 0 then
        self:Show()
        self.bg:SetTint(1, 1, 1, self.level)
    else
        self:StopUpdating()
        self:Hide()
    end
end

function Inf_BloodOver:Flash()
    TheInputProxy:AddVibration(VIBRATION_BLOOD_FLASH, .2, .7, false)
    self:StartUpdating()
    self.level = 1
    self.k = 1.33
end

return Inf_BloodOver
