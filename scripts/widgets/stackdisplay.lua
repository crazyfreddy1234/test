local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")

local StackDisplay = Class(Widget, function(self, owner)
    Widget._ctor(self, "StackDisplay")
    self.owner = owner

    self.stacktext = self:AddChild(Text(NUMBERFONT, 42))
    --self.stacktext:SetHAnchor(ANCHOR_MIDDLE)
    --self.stacktext:SetVAnchor(ANCHOR_BOTTOM)
    self.stacktext:SetPosition(0, 0)
    self.stacktext:SetColour(1, 1, 1, 1)
    self:Show()

    self.inst:DoPeriodicTask(0, function() self:UpdateText() end)
end)

function StackDisplay:UpdateText()
    local item = self.owner.replica.inventory and self.owner.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)

    if item and item._stack_count then
        local count = item._stack_count:value()

        -- 표시
        self.stacktext:SetString(tostring(count))
        self:Show()
    end
end

return StackDisplay
