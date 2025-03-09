local function TurnOnPowerAllPlayer()
    for _,player in pairs(AllPlayers) do
        player.PowerOnOff:set(true)
    end
end

local function TurnOffPowerAllPlayer()  
    for _,player in pairs(AllPlayers) do
        player.PowerOnOff:set(false)
    end
end

local function TurnOnPowerJoinPlayer(src,player)
    player:DoTaskInTime(1,function()
        player.PowerOnOff:set(true)
    end)
end

local function TurnOnPowerWhoJoinServer()
    _G.REFORGED_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].power_on = true
end

local function StopTurnOnPowerWhoJoinServer()
    _G.REFORGED_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].power_on = nil
end

local function IsDungeon()
    local map_name = _G.REFORGED_SETTINGS.gameplay.map or "lavaarena"

    return _G.REFORGED_DATA.maps[map_name].is_dungeon
end

return {
    TurnOnPowerAllPlayer = TurnOnPowerAllPlayer,
    TurnOffPowerAllPlayer = TurnOffPowerAllPlayer,
    TurnOnPowerWhoJoinServer = TurnOnPowerWhoJoinServer,
    StopTurnOnPowerWhoJoinServer = StopTurnOnPowerWhoJoinServer,
    IsDungeon = IsDungeon,
}
