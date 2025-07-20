local config <const> = HRLib.require('@HRCarWash/config.lua') --[[@as HRCarWashConfig]]
local invType <const> = GetResourceState('ox_inventory') == 'started' and 'ox'
local lastTime = 0

LocalPlayer.state:set('HRCarWash:canUseCarWashKit', true, true)

-- Events

if invType == 'ox' then
    AddEventHandler('ox_inventory:usedItem', function(name)
        if name == 'carwashkit' and config.selfWash.itemUseDelay.enable and LocalPlayer.state['HRCarWash:canUseCarWashKit'] or not config.selfWash.itemUseDelay.enable and true then
            local vehicle <const> = HRLib.ClosestVehicle()

            if vehicle and vehicle.distance <= config.selfWash.useDistance then
                CreateSelfWashAnimation(vehicle.vehicle)

                if config.selfWash.itemUseDelay.enable then
                    LocalPlayer.state:set('HRCarWash:canUseCarWashKit', false, true)

                    lastTime = GetGameTimer()

                    SetTimeout(config.selfWash.itemUseDelay.delay, function()
                        LocalPlayer.state:set('HRCarWash:canUseCarWashKit', true, true)
                    end)
                end
            elseif vehicle then
                if vehicle.distance > config.selfWash.useDistance + 3.0 then
                    HRLib.Notify(Translation.selfCarWashFail2, 'error')
                else
                    HRLib.Notify(Translation.selfCarWashFail1, 'error')
                end
            else
                HRLib.Notify(Translation.selfCarWashFail2, 'error')
            end
        elseif name == 'carwashkit' and config.selfWash.itemUseDelay.enable then
            HRLib.Notify(config.selfWash.itemUseDelay.tryDuringDelayMsg:format((config.selfWash.itemUseDelay.delay - (GetGameTimer() - lastTime)) / 1000), 'error')
        end
    end)
elseif invType == 'qb' then
    AddStateBagChangeHandler('HRCarWash:usedItem', '', function(_, _, state)
        if state then
            local vehicle <const> = HRLib.ClosestVehicle()
            if vehicle and vehicle.distance <= config.selfWash.useDistance then
                CreateSelfWashAnimation(vehicle.vehicle)

                if config.selfWash.itemUseDelay.enable then
                    LocalPlayer.state:set('HRCarWash:canUseCarWashKit', false, true)

                    lastTime = GetGameTimer()

                    SetTimeout(config.selfWash.itemUseDelay.delay, function()
                        LocalPlayer.state:set('HRCarWash:canUseCarWashKit', true, true)
                    end)
                end
            elseif vehicle then
                if vehicle.distance > config.selfWash.useDistance + 3.0 then
                    HRLib.Notify(Translation.selfCarWashFail2, 'error')
                else
                    HRLib.Notify(Translation.selfCarWashFail1, 'error')
                end
            else
                HRLib.Notify(Translation.selfCarWashFail2, 'error')
            end
        end
    end)
end

RegisterCommand('testCommand', function()
    local veh <const> = HRLib.ClosestVehicle().vehicle
    local currCoords <const> = GetEntityCoords(veh)
    SetVehicleDirtLevel(veh, 15.0)
    StartWashStationAnimation(veh, vector4(currCoords.x, currCoords.y, currCoords.z, GetEntityHeading(veh)))
end, false)