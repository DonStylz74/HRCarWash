local config <const> = {}

config.language = 'en'

config.carWashStations = {
    enable = true,
    blip = {
        label = 'LS Car Wash',
        sprite = 100,
        color = 26,
        scale = 1.0
    },
    washRoolerPropName = 'prop_carwash_roller_vert',
    verticalRoolerTwoCyclesSpeed = 1.0, -- Max is 1.42 (anything bigger is equal to it in the visual effect)
    horizontalRoolerTwoCyclesSpeed = 1.0, -- Max is 1.42 (anything bigger is equal to it in the visual effect)
    textUIDistance = 1.5, -- The distance, the player can start to see the textUI from each station's coordinates center
    defaultKey = 'E', -- This is only for the first time, a player loads this script, so if the setting was changed after some players load the script with the old settings, it won't change for them
    money = {
        account = 'bank',
        amount = 150 -- This is also used in the textUIDescription translation.
    },
    stations = { -- List of vector4 coords of the car wash stations
        vector4(-699.7520, -933.2900, 19.0139, 358.1540)
    }
}

config.selfWash = {
    useDistance = 2.0, -- The allowed distance off a car when using the car wash kit item
    animation = {
        dict = 'amb@world_human_maid_clean@base',
        animName = 'base',
        duration = 2000, -- In miliseconds
        propName = 'prop_rag_01',
        propOffsetForPlayerPed = vector3(0.10620473369158, -0.019339246593609, -0.059161619795683)
    },
    itemUseDelay = { -- A delay that prevents the item reuse just when it was used for example better realism with the idea it probably tired the player
        enable = true,
        delay = 10000, -- In miliseconds
        tryDuringDelayMsg = 'You can\'t use this item in the next %s seconds!'
    }
}

if IsDuplicityVersion() then
    ---By default, this function supports esx and qb frameworks
    ---@param playerId integer
    ---@return boolean status
    config.getMoneyFunction = function(playerId)
        if HRLib.bridge.getMoney(playerId, config.carWashStations.money.account) >= config.carWashStations.money.amount then
            HRLib.bridge.removeMoney(playerId, config.carWashStations.money.account, config.carWashStations.money.amount)
            HRLib.Notify(playerId, Translation.removedMoneyFromBalance:format(config.carWashStations.money.amount))

            return true
        end

        HRLib.Notify(playerId, Translation.failedToWashCar_notEnoughMoney, 'error')

        return false
    end
end

return config