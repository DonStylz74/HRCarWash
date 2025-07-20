local config <const> = HRLib.require('@HRCarWash/config.lua') --[[@as HRCarWashConfig]]
local invType <const> = GetResourceState('ox_inventory') == 'started' and 'ox' or GetResourceState('qb-inventory') == 'started' and 'qb'

local inventory <const> = invType == 'ox' and exports.ox_inventory or invType == 'qb' and exports['qb-inventory'] --[[@as any[] ]]
if invType == 'ox' then
    AddEventHandler('ox_inventory:usedItem', function(name)
        if name == 'carwashkit' and config.selfWash.itemUseDelay.enable and Player(source).state['HRCarWash:canUseCarWashKit'] or not config.selfWash.itemUseDelay.enable and true then
            inventory:RemoveItem(source, 'carwashkit', 1)
        end
    end)
elseif invType == 'qb' then
    HRLib.bridge.framework.Functions.CreateUseableItem('carwashkit', function(source)
        if config.selfWash.itemUseDelay.enable and Player(source).state['HRCarWash:canUseCarWashKit'] or not config.selfWash.itemUseDelay.enable and true then
            inventory:RemoveItem(tostring(source), 'carwashkit', 1)
            Player(source).state['HRCarWash:usedItem'] = true

            Wait(100)

            Player(source).state['HRCarWash:usedItem'] = nil
        end
    end)
end