local config <const> = HRLib.require('@HRCarWash/config.lua') --[[@as HRCarWashConfig]]

CreateSelfWashAnimation = function(vehicle)
    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        local min <const>, max <const> = GetModelDimensions(GetEntityModel(vehicle))
        local bones <const>, playerPed <const>, singleDirtLevel <const>, dirtLevel, cleaned = {
            GetOffsetFromEntityInWorldCoords(vehicle, min.x, 0.0, min.z),
            GetOffsetFromEntityInWorldCoords(vehicle, max.x, 0.0, min.z),
            GetOffsetFromEntityInWorldCoords(vehicle, 0.0, min.y, min.z),
            GetOffsetFromEntityInWorldCoords(vehicle, 0.0, max.y, min.z)
        }, PlayerPedId(), GetVehicleDirtLevel(vehicle) / 4, GetVehicleDirtLevel(vehicle), 0

        -- Loop that prevents foreign intervention, connected to the vehicle's dirt level and vehicle position
        CreateThread(function()
            local oldLockStatus <const> = GetVehicleDoorLockStatus(vehicle)

            SetVehicleDoorsShut(vehicle, true)

            while dirtLevel > 0 do
                Wait(100)

                SetVehicleDirtLevel(vehicle, dirtLevel)
                SetVehicleDoorsLocked(vehicle, 10)
            end

            SetVehicleDoorsLocked(vehicle, oldLockStatus)
        end)

        HRLib.RequestAnimDict(config.selfWash.animation.dict)

        for i=1, #bones do
            TriggerServerEvent('HRCarWash:goingToCoord', { bones[i], 1.0, 0, false, 2, 0 })
            TaskGoToCoordAnyMeans(playerPed, bones[i], 1.0, 0, false, 2, 0) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

            repeat Wait(10) until not GetIsTaskActive(playerPed, 224)

            SetEntityCoords(playerPed, bones[i]) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

            repeat Wait(150) until GetEntityCoords(playerPed) ~= bones[i]

            TaskTurnPedToFaceEntity(playerPed, vehicle, 0) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

            repeat Wait(10) until not GetIsTaskActive(playerPed, 225)

            TriggerServerEvent('HRCarWash:playingAnim', { anim = { config.selfWash.animation.dict, config.selfWash.animation.animName, 8.0, 8.0, config.selfWash.animation.duration, 1, 1.0, false, false, false }, prop = { GetEntityBoneIndexByName(playerPed, 'BONETAG_R_HAND'), config.selfWash.animation.propOffsetForPlayerPed, 0, 0, 0, true, true, false, true, 1, true }})

            local rag <const> = CreateObject(joaat(config.selfWash.animation.propName), GetEntityCoords(playerPed)) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

            AttachEntityToEntity(rag, playerPed, GetEntityBoneIndexByName(playerPed, 'BONETAG_R_HAND'), config.selfWash.animation.propOffsetForPlayerPed, 0, 0, 0, true, true, false, true, 1, true) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
            TaskPlayAnim(playerPed, config.selfWash.animation.dict, config.selfWash.animation.animName, 8.0, 8.0, config.selfWash.animation.duration, 1, 1.0, false, false, false)
            SetEntityInvincible(playerPed, true)

            Wait(config.selfWash.animation.duration + 2)

            DeleteObject(rag)

            dirtLevel -= singleDirtLevel
            cleaned += 1

            SetEntityInvincible(playerPed, false)
            SetVehicleDirtLevel(vehicle, dirtLevel)
            WashDecalsFromVehicle(vehicle, 1.0)
            HRLib.Notify(Translation.selfWashDirtPlacesNumberCleaned:format(cleaned, #bones), 'success')
        end
    end
end

if config.carWashStations.enable then
    ---@param vehicle integer
    ---@param heading number
    local setVehicleHeading = function(vehicle, heading)
        local currHeading <const> = GetEntityHeading(vehicle)
        if (currHeading < 0 and heading < 0) or (currHeading > 0 and heading > 0) then
            SetEntityHeading(vehicle, heading)
        elseif (currHeading > 0 and heading < 0) or (currHeading < 0 and heading > 0) then
            SetEntityHeading(vehicle, currHeading < 0 and -(math.abs(heading)) or math.abs(heading))
        end
    end

    ---@param polusType 'minus'|any?
    ---@param value number
    ---@param addition number
    ---@return number
    local degressAdditionPolusChanger = function(polusType, value, addition)
        if polusType == 'minus' then
            local additionResult <const> = value - addition
            return additionResult < 0 and additionResult + 360 or additionResult
        else
            local additionResult <const> = value + addition
            return additionResult > 360 and additionResult - 360 or additionResult
        end
    end

    ---@param polus 'minus'|any?
    ---@param curr integer
    ---@param vehicle integer
    ---@param currCoords vector3
    ---@param singleDistAddition number
    ---@param distType number|any?
    local vehDistanceAdditionPolusChanger = function(polus, curr, vehicle, currCoords, singleDistAddition, distType)
        local vectorAddition <const>, offsetForCurrCoords <const> = distType == 2 and vector3(singleDistAddition, 0.0, 0.0) or vector3(0.0, singleDistAddition, 0.0), GetOffsetFromEntityGivenWorldCoords(vehicle, currCoords.x, currCoords.y, currCoords.z)

        if polus == 'minus' then
            SetEntityCoords(curr, GetOffsetFromEntityInWorldCoords(vehicle, offsetForCurrCoords - vectorAddition)) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
        else
            SetEntityCoords(curr, GetOffsetFromEntityInWorldCoords(vehicle, offsetForCurrCoords + vectorAddition)) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
        end
    end

    StartWashStationAnimation = function(vehicle, stationCoords, isFromEvent)
        if not isFromEvent then
            TriggerServerEvent('HRCarWash:syncronizeAnimation', NetworkGetNetworkIdFromEntity(vehicle), stationCoords)
        end

        local vehicleHeading <const> = GetEntityHeading(vehicle)
        setVehicleHeading(vehicle, (stationCoords.w + vehicleHeading - 360 < 0 and math.abs(stationCoords.w + vehicleHeading - 360) or stationCoords.w + vehicleHeading - 360) <= 100.0 and stationCoords.w or (stationCoords.w + 180 - 360 < 0 and math.abs(stationCoords.w + 180 - 360) or stationCoords.w + 180 - 360))
        SetEntityCoords(vehicle, HRLib.ToVector3(stationCoords)) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

        if not isFromEvent then
            CurrentSession = promise.new()
        end

        local lockStatusMemory <const>, dirtLevel = GetVehicleDoorLockStatus(vehicle), GetVehicleDirtLevel(vehicle)
        local min <const>, max <const> = GetModelDimensions(GetEntityModel(vehicle))
        local roolerModel <const> = joaat(config.carWashStations.washRoolerPropName)
        local roolerMin <const>, roolerMax <const> = GetModelDimensions(roolerModel)
        local washRoolers <const>, washRoolersCyclesMemory <const> = {
            CreateObject(roolerModel, GetOffsetFromEntityInWorldCoords(vehicle, min.x - ((roolerMax - roolerMin).x / 2 - 0.2), max.y, min.z - 0.5)), ---@diagnostic disable-line: missing-parameter, param-type-mismatch
            CreateObject(roolerModel, GetOffsetFromEntityInWorldCoords(vehicle, max.x + ((roolerMax - roolerMin).x / 2 - 0.2), min.y, min.z - 0.5)) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
        }, { 0, 0 }

        if not isFromEvent then
            NetworkRequestControlOfEntity(vehicle)

            while not NetworkHasControlOfEntity(vehicle) do
                Wait(10)
            end

            FreezeEntityPosition(vehicle, true)
            SetVehicleDoorsLocked(vehicle, 9)
            SetEntityInvincible(vehicle, true)
            SetVehicleEngineOn(vehicle, false, true, true)
        end

        HRLib.RequestPTFX('cut_test')

        local dirtModifier <const>, ftpxAssetRadius <const> = dirtLevel / 8 / 100, (max - min).x / 4
        for i=1, 2 do
            local ptfxs1v <const>, ptfxs2v = i == 1 and min + vector3(ftpxAssetRadius / 2, 0.0, 0.0) or max - vector3(ftpxAssetRadius / 2, 0.0, 0.0), i == 1 and max or min
            local curr <const>, currPtfxs <const> = washRoolers[i], {}

            for l=1, 2 do
                UseParticleFxAsset('cut_test')

                if l == 1 then
                    currPtfxs[l] = StartNetworkedParticleFxLoopedOnEntity('exp_hydrant', vehicle, ptfxs1v.x, ptfxs2v.y, 4.0, 0.0, 180.0, 0.0, ftpxAssetRadius, false, false, false)
                else
                    currPtfxs[l] = StartNetworkedParticleFxLoopedOnEntity('exp_hydrant', vehicle, i == 1 and ptfxs1v.x + ftpxAssetRadius or ptfxs1v.x - ftpxAssetRadius, ptfxs2v.y, 4.0, 0.0, 180.0, 0.0, ftpxAssetRadius, false, false, false)
                end
            end

            FreezeEntityPosition(curr, true)
            SetEntityCollision(curr, false, false)
            SetEntityHeading(curr, 0)

            CreateThread(function()
                local cycleDurationFrameModifier, singleDistAddition, singleDegreeAddition <const> = 100 / (config.carWashStations.verticalRoolerTwoCyclesSpeed * 10), (max - min).y / 100, 360 * 4 / 100

                while true do
                    local currMemory <const> = washRoolersCyclesMemory[i]
                    if currMemory <= 200 then
                        SetEntityHeading(curr, degressAdditionPolusChanger(i == 1 and (currMemory <= 100 and 'minus' or 'plus') or i == 2 and (currMemory > 100 and 'minus' or 'plus'), GetEntityHeading(curr), singleDegreeAddition))
                        vehDistanceAdditionPolusChanger(i == 1 and (currMemory <= 100 and 'minus' or 'plus') or i == 2 and (currMemory > 100 and 'minus' or 'plus'), curr, vehicle, GetEntityCoords(curr), singleDistAddition)
                        SetVehicleDirtLevel(vehicle, dirtLevel - dirtModifier)
                        SetVehicleEngineOn(vehicle, false, true, true)

                        if i == 1 and currMemory <= 100 then
                            ptfxs2v -= vector3(0.0, singleDistAddition, 0.0)
                        elseif i == 1 and currMemory > 100 then
                            ptfxs2v += vector3(0.0, singleDistAddition, 0.0)
                        elseif i == 2 and currMemory <= 100 then
                            ptfxs2v += vector3(0.0, singleDistAddition, 0.0)
                        elseif i == 2 and currMemory > 100 then
                            ptfxs2v -= vector3(0.0, singleDistAddition, 0.0)
                        end

                        dirtLevel = dirtLevel - dirtModifier
                        washRoolersCyclesMemory[i] = washRoolersCyclesMemory[i] + 1

                        for l=1, 2 do
                            SetParticleFxLoopedOffsets(currPtfxs[l], (l == 1 and ptfxs1v.x or (i == 1 and ptfxs1v.x + ftpxAssetRadius or ptfxs1v.x - ftpxAssetRadius)), ptfxs2v.y, 4.0, 0.0, 180.0, 0.0)
                        end

                        Wait(cycleDurationFrameModifier)
                    else
                        break
                    end
                end

                if i == 1 then
                    repeat Wait(10) until washRoolersCyclesMemory[1] ~= 200 and washRoolersCyclesMemory[2] ~= 200
                end

                for l=1, #currPtfxs do
                    StopParticleFxLooped(currPtfxs[l], false)
                end

                washRoolersCyclesMemory[i] = 0
                singleDistAddition = (max - min).x / 100
                cycleDurationFrameModifier = 100 / (config.carWashStations.horizontalRoolerTwoCyclesSpeed * 10)

                local oldZ <const> = GetEntityCoords(curr).z

                SetEntityCoords(curr, (i == 1 and GetOffsetFromEntityInWorldCoords(vehicle, min.x, max.y, min.z - 0.5) or GetOffsetFromEntityInWorldCoords(vehicle, max.x, min.y, min.z - 0.5))) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

                local currCoordsNow <const> = GetEntityCoords(curr)
                SetEntityCoords(curr, currCoordsNow.x, currCoordsNow.y, oldZ) ---@diagnostic disable-line: missing-parameter

                SetEntityHeading(curr, 0.0)

                while true do
                    local currMemory <const> = washRoolersCyclesMemory[i]
                    if currMemory <= 200 then
                        SetEntityHeading(curr, degressAdditionPolusChanger(i == 1 and (currMemory <= 100 and 'minus' or 'plus') or i == 2 and (currMemory > 100 and 'minus' or 'plus'), GetEntityHeading(curr), singleDegreeAddition))
                        vehDistanceAdditionPolusChanger(i == 1 and (currMemory <= 100 and 'plus' or 'minus') or i == 2 and (currMemory > 100 and 'plus' or 'minus'), curr, vehicle, GetEntityCoords(curr), singleDistAddition, 2)

                        if not isFromEvent then
                            SetVehicleDirtLevel(vehicle, dirtLevel - dirtModifier)
                            SetVehicleEngineOn(vehicle, false, true, true)
                        end

                        dirtLevel = dirtLevel - dirtModifier
                        washRoolersCyclesMemory[i] = washRoolersCyclesMemory[i] + 1

                        Wait(cycleDurationFrameModifier)
                    else
                        break
                    end
                end

                DeleteObject(curr)

                if i == 2 and not isFromEvent then
                    SetVehicleDirtLevel(vehicle, 0.0)
                    WashDecalsFromVehicle(vehicle, 1.0)
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleDoorsLocked(vehicle, lockStatusMemory)
                    SetEntityInvincible(vehicle, false)
                    SetVehicleEngineOn(vehicle, true, true, false)
                    HRLib.Notify(Translation.carWashSuccess, 'success')

                    CurrentSession:resolve(true)
                end
            end)
        end
    end
end