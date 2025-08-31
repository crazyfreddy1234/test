local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")

local StackDisplay = Class(Widget, function(self, owner, weapon)
    Widget._ctor(self, "StackDisplay")
    self:MoveToFront()
    self:SetPosition(-60, -10)    ------(-12,-474)-----

    self.owner = owner
    self.temp_value = "?"
    self.equip_weapon = weapon

    self.stacktext = self:AddChild(Text(NUMBERFONT, 45))
    self.stacktext:SetColour(1, 1, 1, 1)

    if self.equip_weapon ~= nil then
        self.owner:DoTaskInTime(_G.FRAMES, function()
            self:UpdateText()
        end)
    end

    -- 등록
    self.owner._stackdirty = function(inst, data) self:UpdateText(inst, data) end

    self.owner:ListenForEvent("inf_stackdirty", self.owner._stackdirty)
end)

function StackDisplay:UpdateText()

    local stack_num = self.owner._stack_count and self.owner._stack_count:value() or nil

    if stack_num ~= nil then
        self:ShowText(stack_num)
    else
        self:HideText()
    end
end

function StackDisplay:ShowText(val)
    self:Show()

    if val ~= nil then
        self.stacktext:SetString(val)
    else
        self.stacktext:SetString(self.temp_value)
    end
end

function StackDisplay:HideText()
    self.stacktext:SetString("")
    self:Hide()
end

return StackDisplay
