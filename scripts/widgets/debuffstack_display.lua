local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")

local DebuffStack_Display = Class(Widget, function(self)
    Widget._ctor(self, "DebuffStack_Display")
    self:MoveToFront()
    self:SetPosition(-60, -10)    ------(-12,-474)-----

    self.temp_value = "?"

    self.stacktext = self:AddChild(Text(NUMBERFONT, 45))
    self.stacktext:SetColour(1, 1, 1, 1)
end)

function DebuffStack_Display:ShowText(val)
    self:Show()

    if val ~= nil then
        self.stacktext:SetString(val)
    else
        self.stacktext:SetString(self.temp_value)
    end
end

function DebuffStack_Display:HideText()
    self.stacktext:SetString("")
    self:Hide()
end

return DebuffStack_Display
