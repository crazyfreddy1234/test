local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")

local StackDisplay = Class(Widget, function(self, owner)
    Widget._ctor(self, "StackDisplay")
    self.owner = owner

    self.stacktext = self:AddChild(Text(CHATFONT, 100))
    self.stacktext:SetHAlign(ANCHOR_MIDDLE)
    self.stacktext:SetVAlign(ANCHOR_MIDDLE)
    self.stacktext:SetPosition(0, 0)
    self.stacktext:SetColour(1, 1, 1, 1)
    self:Show()

    self.inst:DoPeriodicTask(0.2, function() self:UpdateText() end)
end)

function StackDisplay:UpdateText()
    local item = self.owner.components.inventory and self.owner.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
    print(item)
    if item and item.components and item.components.rechargeable and item.components.rechargeable.max_stacks then
        local r = item.components.rechargeable
        local txt = string.format("스택: %d / %d", r.current_stacks, r.max_stacks)
        self.stacktext:SetString(txt)
        self:Show()
    else
        self:Show()
    end
end

return StackDisplay
