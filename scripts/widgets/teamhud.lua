local Widget = require "widgets/widget"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local PlayerBadge = require "widgets/playerbadge"
local TeamHealthBar = require "widgets/teamhealthbar"

local TEMPLATES = require "widgets/redux/templates"

local MOVEICON_TIME = 0.3

local TeamHUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "TeamHUD")

    self.owner = owner

    self:SetPosition(0, 0, 0)

    self.root = self:AddChild(Widget("teamhud_root"))
    self.root:SetPosition(300, 300)

    -- + / - 버튼 만들기
    self.toggle_btn = self.root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "view_ban.tex"))
    self.toggle_btn:SetPosition(0, 0)
    self.toggle_btn:MoveToFront()

    -- 팀 체력바 패널 (초기에는 숨김)
    self.team_panel = self.root:AddChild(Widget("team_panel"))
    self.team_panel:SetPosition(-150, 100) -- + 버튼 오른쪽에 표시
    self.team_panel:Hide()

    self.is_open = false
    self.teammates = {}   -- 팀원 리스트
    self.healthbars = {}  -- 체력바 저장

    -- 클릭 시 + / - 상태 토글
    self.toggle_btn:SetOnClick(function()
        if not self.dragging then
            self:TryToggleHUD()
        end
    end) 

    self.toggle_btn.OnMouseButton = function(_, button, down)
        if button == MOUSEBUTTON_LEFT then
            if down then
                -- 마우스 눌렀을 때 시간 저장
                self.press_time = GetTime()
            else
                -- 마우스 뗐을 때
                if self.dragging then
                    self.dragging = false

                    self.root:StopFollowMouse()
                    self.root:SetPosition(TheInput:GetScreenPosition())
                end

                self.press_time = nil
            end
        end
        return true
    end

    self:SetTeammates(_G.AllPlayers)
    self:StartUpdating()
end)

function TeamHUD:TryToggleHUD()
    print("change hide show")
    if self.is_open then
        self.team_panel:Hide()
    else
        self.team_panel:Show()
    end

    self.is_open = not self.is_open
end

function TeamHUD:CreateHealthBars()
    self.team_panel:KillAllChildren()  -- 기존 체력바 삭제
    self.healthbars = {}

    local y_offset = 0
    for i, teammate in ipairs(self.teammates) do
        local healthbar = self.team_panel:AddChild(TeamHealthBar(teammate, self.owner))
        healthbar:SetPosition(0, y_offset, 0)
        table.insert(self.healthbars, {player = teammate, bar = healthbar})
        y_offset = y_offset - 120 -- 체력바 간 간격
    end
end

function TeamHUD:SetTeammates(teammate_list)
    -- 팀원 설정
    self.teammates = teammate_list
    self:CreateHealthBars()
end

function TeamHUD:RefreshTeammates()
    -- 현재 클라이언트에서 보이는 모든 플레이어
    local teammates = {}

    for i, v in ipairs(_G.AllPlayers) do
        table.insert(teammates, v)
    end

    self:SetTeammates(teammates)
end

function TeamHUD:OnUpdate(dt)
    if self.press_time then
        local held_time = GetTime() - self.press_time
        if held_time > MOVEICON_TIME and not self.dragging then
            self.root:FollowMouse()
            self.dragging = true
        end
    else
        self.root:StopFollowMouse()
    end
end

return TeamHUD