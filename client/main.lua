CurrentSession = nil
local config <const> = HRLib.require('@HRCarWash/config.lua') --[[@as HRCarWashConfig]]

-- Events

RegisterNetEvent('HRCarWash:playingAnim', function(networkId, params)
    local playerPed <const> = NetworkGetEntityFromNetworkId(networkId)
    if playerPed and #(GetEntityCoords(playerPed) - GetEntityCoords(PlayerPedId())) <= 100.0 then
        local rag <const> = CreateObject(joaat(config.selfWash.animation.propName), GetEntityCoords(playerPed)) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
        AttachEntityToEntity(rag, playerPed, table.unpack(params.prop)) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

        HRLib.RequestAnimDict(params.anim[1])
        TaskPlayAnim(playerPed, table.unpack(params.anim))
        SetTimeout(params.anim[5] + 2, function()
            RemoveAnimDict(params.anim[1])
            DeleteEntity(rag)
        end)
    end
end)

RegisterNetEvent('HRCarWash:goingToCoord', function(networkId, params)
    local playerPed <const> = NetworkGetEntityFromNetworkId(networkId)
    TaskGoToCoordAnyMeans(playerPed, table.unpack(params))

    repeat Wait(10) until not GetIsTaskActive(playerPed, 224)

    SetEntityCoords(playerPed, params[1]) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

    repeat Wait(150) until GetEntityCoords(playerPed) ~= params[1]

    TaskTurnPedToFaceCoord(playerPed, params[1], 0) ---@diagnostic disable-line: missing-parameter
end)

if config.carWashStations.enable then
    RegisterNetEvent('HRCarWash:syncronizeAnimation', function(netId, stationCoords)
        StartWashStationAnimation(NetworkGetEntityFromNetworkId(netId), stationCoords, true)
    end)

    -- Key Registering

    RegisterCommand('+HRCarWash_carWashStation', function()
        local playerPed <const> = PlayerPedId()
        local vehicle <const> = GetVehiclePedIsIn(playerPed, false)
        if vehicle then
            for i=1, #config.carWashStations.stations do
                local curr <const> = config.carWashStations.stations[i]
                if #(GetEntityCoords(vehicle) - HRLib.ToVector3(curr)) <= config.carWashStations.textUIDistance then
                    LocalPlayer.state:set('HRCarWash:removePlayerMoney', true, true)
                    Wait(100)

                    LocalPlayer.state:set('HRCarWash:removePlayerMoney', nil, true)

                    if LocalPlayer.state['HRCarWash:successfullyRemovedPlayerMoney'] then
                        if not NetworkGetEntityIsNetworked(vehicle) then
                            NetworkRegisterEntityAsNetworked(vehicle)
                            SetEntityAsMissionEntity(vehicle, false, true)
                        end

                        StartWashStationAnimation(vehicle, curr)
                        LocalPlayer.state:set('HRCarWash:successfullyRemovedPlayerMoney', nil, true)
                    end
                end
            end
        end
    end, false)

    RegisterKeyMapping('+HRCarWash_carWashStation', Translation.keyBindDescription, 'keyboard', config.carWashStations.defaultKey)

    -- Threads

    local isPlayerClose = function(ped)
        for i=1, #config.carWashStations.stations do
            if #(GetEntityCoords(ped) - HRLib.ToVector3(config.carWashStations.stations[i])) <= config.carWashStations.textUIDistance then
                return true
            end
        end

        return false
    end

    local textUIDescription <const> = Translation.textUIDescription:format(config.carWashStations.defaultKey, config.carWashStations.money.amount)
    CreateThread(function()
        while true do
            if CurrentSession then
                HRLib.hideTextUI()
                Citizen.Await(CurrentSession)

                CurrentSession = nil
            end

            local playerPed <const> = PlayerPedId()
            local isOpen <const>, desc <const> = HRLib.isTextUIOpen(true)
            if IsPedSittingInAnyVehicle(playerPed) then
                if isPlayerClose(playerPed) then
                    if not isOpen or isOpen and desc ~= textUIDescription then
                        HRLib.showTextUI(textUIDescription)
                    end
                elseif isOpen and desc == textUIDescription then
                    HRLib.hideTextUI()
                end
            elseif isOpen and desc == textUIDescription then
                HRLib.hideTextUI()
            end

            Wait(150)
        end
    end)

    CreateThread(function()
        for i=1, #config.carWashStations.stations do
            local blip <const> = HRLib.CreateBlip({
                type = 'forCoord',
                options = {
                    sprite = config.carWashStations.blip.sprite,
                    colour = config.carWashStations.blip.color,
                    scale = config.carWashStations.blip.scale
                },
                specificOptions = {
                    coords = HRLib.ToVector3(config.carWashStations.stations[i]) --[[@as vector3]]
                }
            })

            if blip then
                BeginTextCommandSetBlipName('HRCarWash:setBlipName')
                AddTextEntry('HRCarWash:setBlipName', config.carWashStations.blip.label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end)
end