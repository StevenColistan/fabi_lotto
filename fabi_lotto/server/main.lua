ESX = exports["es_extended"]:getSharedObject()

local webhookWinnerURL = 'https://discord.com/api/webhooks/1286896529046638655/rhIHoVXXqkuxVdgUflEuoZt6lU342of1_muqXlLxGqqY3XSiRXImoUeeoVLoeJpTybvv'
local webhookTicketURL = 'https://discordapp.com/api/webhooks/1290717494541025383/ia0ha1guEcGih9M9xORt7TIY4r6P4mpzl_-PgzoQtcqol3EZIO3-rCuF5kXGYuTULMnH'
local drawWinnerLocal = false
local winnerDrawenAlready = false

local function sendWebhook(webhookURL, title, description, color)
    local embed = {
        {
            ["color"] = color,
            ["title"] = title,
            ["description"] = description,
            ["footer"] = { ["text"] = os.date("%Y-%m-%d %H:%M:%S") }
        }
    }

    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
end

local function loadLottoJackpot()
    MySQL.scalar('SELECT jackpot FROM lotto WHERE id = ?', {1}, function(result)
        if result then
            lottoJackpotOC = result
        else
            MySQL.update('INSERT INTO lotto (id, jackpot) VALUES (?, ?)', {1, 1500000})
        end
    end)
end

local function loadLottoParticipants(cb)
    MySQL.query('SELECT * FROM lotto_participants', {}, function(participants)
        cb(participants)
    end)
end

local function saveLottoParticipant(identifier, numbers)
    MySQL.update('INSERT INTO lotto_participants (identifier, numbers) VALUES (?, ?) ON DUPLICATE KEY UPDATE numbers = VALUES(numbers)', {identifier, json.encode(numbers)})
end

local function resetLottoParticipants()
    MySQL.update('DELETE FROM lotto_participants')
end

local function updateLottoJackpot(amount)
    lottoJackpotOC = amount
    MySQL.update('UPDATE lotto SET jackpot = ? WHERE id = ?', {lottoJackpotOC, 1})
end

ESX.RegisterCommand('lotto_drawWiner', 'superadmin', function(xPlayer, args, showError)
    TriggerEvent('lotto:drawWinner')
    if not winnerDrawenAlready then
        winnerDrawenAlready = true
    end
end, true, {help = "Ziehe einen Lotto Gewinner"}) 

ESX.RegisterCommand('lotto_setchance', 'superadmin', function(xPlayer, args, showError)
    if drawWinnerLocal then
        local xPlayerr = ESX.GetPlayerFromId(source)
        drawWinnerLocal = false
        print("Gewinner false")
        TriggerClientEvent('brutal_notify:SendAlert', xPlayer.source, 'Lotto', 'Du hast die Gewinnchance erfolgreich auf Zufall gesetzt.', 5000, 'success')
    else
        local xPlayerr = ESX.GetPlayerFromId(source)
        drawWinnerLocal = true
        print("Gewinner true")
        TriggerClientEvent('brutal_notify:SendAlert', xPlayer.source, 'Lotto', 'Du hast die Gewinnchance erfolgreich auf 100% gesetzt.', 5000, 'success')
    end
end, true, {help = "Setze die Gewinnchance auf 100%"}) 


RegisterServerEvent('lotto:chooseNumbers')
AddEventHandler('lotto:chooseNumbers', function(numbers)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    if xPlayer.hasItem('lottoschein', 1) then
        xPlayer.removeInventoryItem('lottoschein', 1)
        saveLottoParticipant(identifier, numbers)
        updateLottoJackpot(lottoJackpotOC + 28000)
        TriggerClientEvent('lotto:ticketPurchased', source)

        local numbersFormatted = table.concat(numbers, ', ')
        sendWebhook(webhookTicketURL, "Lotto-Ticket gekauft", ("Spieler: %s\nZahlen: %s"):format(xPlayer.getName(), numbersFormatted), 3447003)
    else
        TriggerClientEvent('brutal_notify:SendAlert', xPlayer.source, 'Lotto', 'Du hast keinen Lottoschein.', 5000, 'error')
    end
end)

RegisterServerEvent('lotto:drawWinner')
AddEventHandler('lotto:drawWinner', function()
    local winners = {}
    local winningNumbers = generateUniqueRandomNumbers(3, 1, 35)
    local numbersFormatted = table.concat(winningNumbers, ', ')

    loadLottoParticipants(function(participants)
        for _, participant in ipairs(participants) do
            local numbers = json.decode(participant.numbers)
            if table.concat(numbers) == table.concat(winningNumbers) then
                table.insert(winners, participant.identifier)
                print("winner 1")
            end
        end

        if #winners > 0 or drawWinnerLocal then
            if #winners == 0 and drawWinnerLocal then
                        print("winner 2")
                local randomIndex = math.random(1, #participants)
                table.insert(winners, participants[randomIndex].identifier)
            end

            local share = lottoJackpotOC / #winners
            local winnerNames = {}

            for _, winner in ipairs(winners) do
                local xPlayer = ESX.GetPlayerFromIdentifier(winner)
                if xPlayer then
                    xPlayer.addMoney(share)
                    table.insert(winnerNames, xPlayer.getName())
                    TriggerClientEvent('esx:showNotification', xPlayer.source, ('Herzlichen Glückwunsch! Du hast $%d gewonnen.'):format(share))
                end
            end

            local winnersMessage = table.concat(winnerNames, ", ")
            sendWebhook(webhookWinnerURL, "Lotto Gewinner", ("Gewinner: %s\nGewinnzahlen: %s\nGewinn: $%d pro Gewinner"):format(winnersMessage, numbersFormatted, share), 3066993)

            for _, player in pairs(ESX.GetExtendedPlayers()) do
                if not table.contains(winnerNames, ESX.GetPlayerFromId(player.source).getName()) then
                    TriggerClientEvent('esx:showNotification', player.source, ('Die Lotto Gewinner sind: %s und haben jeweils $%d gewonnen!'):format(winnersMessage, share))
                end
            end

            updateLottoJackpot(1500000)
        else
            for _, player in pairs(ESX.GetExtendedPlayers()) do
                TriggerClientEvent('esx:showNotification', player.source, ('Keiner hat das Lotto gewonnen. Der neue Jackpot beträgt nun:'.. lottoJackpotOC + 250000))
            end
            sendWebhook(webhookWinnerURL, "Lotto - Kein Gewinner", ("Gewinnzahlen: %s\nJackpot erhöht auf: $%d"):format(numbersFormatted, lottoJackpotOC + 250000), 15158332)
            updateLottoJackpot(lottoJackpotOC + 250000)
        end

        resetLottoParticipants()
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        TriggerClientEvent('lotto:jackpotUpdate', -1, lottoJackpotOC)
    end
end)

Citizen.CreateThread(function()
    local lastDrawHour = -1  

    while true do
        Citizen.Wait(1000)  
        local currentTime = os.date("*t")

        if currentTime.hour == 21 and currentTime.min == 00 and lastDrawHour ~= 21 then
            if winnerDrawenAlready then
                winnerDrawenAlready = false
                break
            else
                TriggerEvent('lotto:drawWinner')
                lastDrawHour = 21 
            end
        elseif currentTime.hour == 0 then
            lastDrawHour = -1  
        end

        if (currentTime.hour == 20) and currentTime.min == 00 then
            for _, player in pairs(ESX.GetExtendedPlayers()) do
                if winnerDrawenAlready then
                    break
                else
                    local xPlayer = ESX.GetPlayerFromId(player.source)
                    TriggerClientEvent('esx:showNotification', xPlayer.source, 'Es ist 20:00 Uhr, die Lottoziehung findet um 21:00 Uhr statt! Aktueller Jackpot liegt bei '..lottoJackpotOC)
                end
            end
        end
    end
end)

ESX.RegisterUsableItem('lottoschein', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    loadLottoParticipants(function(participants)
        local alreadyParticipated = false

        if #participants == 0 then
            TriggerClientEvent('lotto:lottoOpen', source)
            TriggerClientEvent('brutal_notify:SendAlert', xPlayer.source, 'Lotto', 'Du hast ein Lottoschein benutzt! Wähle deine Zahlen aus.', 5000, 'info')
        else
            for _, participant in ipairs(participants) do
                if participant.identifier == identifier then
                    alreadyParticipated = true
                    break
                end
            end

            if alreadyParticipated then
                TriggerClientEvent('brutal_notify:SendAlert', xPlayer.source, 'Lotto', 'Du hast bereits ein Ticket gekauft!', 5000, 'error')
            else
                TriggerClientEvent('lotto:lottoOpen', source)
                TriggerClientEvent('brutal_notify:SendAlert', xPlayer.source, 'Lotto', 'Du hast ein Lottoschein benutzt! Wähle deine Zahlen aus.', 5000, 'info')
            end
        end
    end)
end)

function generateUniqueRandomNumbers(count, min, max)
    local numbers = {}
    while #numbers < count do
        local num = math.random(min, max)
        if not table.contains(numbers, num) then
            table.insert(numbers, num)
        end
    end
    table.sort(numbers)
    return numbers
end

function table.contains(t, element)
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

loadLottoJackpot()
