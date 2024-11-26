ESX = exports["es_extended"]:getSharedObject()

RegisterNUICallback('chooseLottoNumbers', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ 
        action = 'openLottoUI', 
        show = false 
    })
    if not data then
        cb('error')
        return
    end
    local numbers = {}
    for i = 1, 3 do
        local num = tonumber(data.numbers[i])
        if num and num >= 1 and num <= 35 then
            table.insert(numbers, num)
            table.sort(numbers)
        else
            return
        end
    end
    TriggerServerEvent('lotto:chooseNumbers', numbers)
    cb('ok')
end)

RegisterNetEvent('lotto:jackpotUpdate')
AddEventHandler('lotto:jackpotUpdate', function(setHtmlJackPot)
    SendNUIMessage({
        action = 'updateJackpot',
        jackpot = setHtmlJackPot
    })
end)

RegisterNetEvent('lotto:ticketPurchased')
AddEventHandler('lotto:ticketPurchased', function()
    ESX.ShowNotification('Du hast dir ein Lotto Ticket gekauft')
    TriggerEvent('lotto:logToDiscord', 'Ein Lotto Ticket wurde gekauft.')
end)

RegisterNetEvent('lotto:lottoOpen')
AddEventHandler('lotto:lottoOpen', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openLottoUI',
        show = true, 
        url = 'https://fabi_lotto/screen/'
    })
end, false)

RegisterNUICallback('closeLottoUI', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ 
        action = 'openLottoUI', 
        show = false 
    })
end)