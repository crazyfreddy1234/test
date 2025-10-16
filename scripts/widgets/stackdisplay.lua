local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")

local StackDisplay = Class(Widget, function(self, owner, weapon)
    Widget._ctor(self, "StackDisplay")
    self:MoveToFront()
    self:SetPosition(-60, -10)    ------(-12,-474)-----

    self.owner = owner
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

    if stack_num == nil or stack_num <= -1 then
        self:HideText()
    else
        self:SetText(stack_num)
        self:ShowText()
    end
end

function StackDisplay:SetText(text)
    if text == nil or not (type(text) == "number" or type(text) == "string")   then
        self.stacktext:SetString("ERROR")
    else
        self.stacktext:SetString(text)
    end
end

function StackDisplay:ShowText()
    self:Show()
end

function StackDisplay:HideText()
    self:Hide()
end

return StackDisplay
