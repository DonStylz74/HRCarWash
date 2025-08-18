local config <const> = HRLib.require('@HRCarWash/config.lua') --[[@as HRCarWashConfig]]

-- Callbacks

do
    local modules <const> = { 'playingAnim', 'goingToCoord' }
    for i=1, #modules do
        RegisterNetEvent(('HRCarWash:%s'):format(modules[i]), function(params)
            local players <const>, networkId <const> = GetPlayers(), NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
            for l=1, #players do
                local curr <const> = tonumber(players[l]) --[[@as integer]]
                if curr ~= source then
                    TriggerClientEvent(('HRCarWash:%s'):format(modules[i]), curr, networkId, params)
                end
            end
        end)
    end
end

-- State Bags

AddStateBagChangeHandler('HRCarWash:removePlayerMoney', '', function(bagName, _, state)
    if state then
        local separatedBagName <const> = HRLib.string.split(bagName, ':', nil, true) --[[@as string[] ]]
        if separatedBagName[1] == 'player' then
            local playerId <const> = tonumber(separatedBagName[2]) --[[@as integer]]
            if config.getMoneyFunction(playerId) then
                Player(playerId).state['HRCarWash:successfullyRemovedPlayerMoney'] = true
            end
        end
    end
end)

-- Events

RegisterNetEvent('HRCarWash:syncronizeAnimation', function(netId, stationCoords)
    local players <const> = GetPlayers()
    if players and #players > 0 then
        for i=1, #players do
            if players[i] ~= tostring(source) then
                TriggerClientEvent('HRCarWash:syncronizeAnimation', tonumber(players[i]) --[[@as integer]], netId, stationCoords)
            end
        end
    end
end)