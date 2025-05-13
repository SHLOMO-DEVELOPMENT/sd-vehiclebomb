local QBCore = exports['qb-core']:GetCoreObject()
local BombedVehicles = {}
local IsNearBombedVehicle = false
local ClosestBombedVehicle = nil
local IsPlacingBomb = false
local BlinkState = true
local BlinkTime = 0

if not Config then
    print("^1[SD-VehicleBomb] ERROR: Config table is nil. Creating default config...^7")
    Config = {
        Debug = true,
        ShowNotifications = true,
        DetonateRange = 25.0,
        DetonateKey = 47,
        InstallTime = 8000,
        DetectionRange = 5.0,
        BombItem = 'vehiclebomb',
        ExplosionType = 4,
        ExplosionDamage = 60.0,
        ExplosionShake = 1.0,
        FireEffect = true,
        Animation = {
            dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
            name = "machinic_loop_mechandplayer",
            flag = 1
        },
        UI = {
            width = 0.14,
            height = 0.075,
            borderThickness = 0.003,
            font = 4,
            scale = 0.45,
            position = "right",
            backgroundColor = {0, 0, 0, 180},
            textColor = {255, 255, 255, 255},
            borderColor = {255, 0, 0, 255},
            showKey = true,
            keyText = "G",
            blinking = false,
            blinkSpeed = 500,
            useGlowEffect = false,
            glowColor = {255, 0, 0, 50},
            glowSize = 0.003,
            useBlur = false,
            style = "classic",
            rtlText = true
        },
        Text = {
            alreadyBombed = "רכב זה כבר מכיל פצצה",
            tooFar = "אתה צריך להיות קרוב יותר לרכב",
            startInstall = "מתחיל להתקין פצצה...",
            installing = "מתקין פצצה...",
            installCancelled = "התקנת הפצצה בוטלה",
            installed = "הפצצה הותקנה בהצלחה",
            detonated = "הפצצה פוצצה בהצלחה",
            noVehicle = "אין רכב בקרבת מקום",
            pressToDetonate = "לחץ על G כדי לפוצץ"
        }
    }
end

local function DebugPrint(msg)
    if Config and Config.Debug then
        print("^2[SD-VehicleBomb] ^7" .. msg)
    end
end

local function ValidateConfig()
    if not Config.Text then
        Config.Text = {
            alreadyBombed = "רכב זה כבר מכיל פצצה",
            tooFar = "אתה צריך להיות קרוב יותר לרכב",
            startInstall = "מתחיל להתקין פצצה...",
            installing = "מתקין פצצה...",
            installCancelled = "התקנת הפצצה בוטלה",
            installed = "הפצצה הותקנה בהצלחה",
            detonated = "הפצצה פוצצה בהצלחה",
            noVehicle = "אין רכב בקרבת מקום",
            pressToDetonate = "לחץ על G כדי לפוצץ"
        }
    end
    
    if not Config.UI then
        Config.UI = {
            width = 0.14,
            height = 0.075,
            borderThickness = 0.003,
            font = 4,
            scale = 0.45,
            position = "right",
            backgroundColor = {0, 0, 0, 180},
            textColor = {255, 255, 255, 255},
            borderColor = {255, 0, 0, 255},
            showKey = true,
            keyText = "G",
            blinking = false,
            blinkSpeed = 500,
            useGlowEffect = false,
            glowColor = {255, 0, 0, 50},
            glowSize = 0.003,
            useBlur = false,
            style = "classic",
            rtlText = true
        }
    end
    
    if not Config.Animation then
        Config.Animation = {
            dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
            name = "machinic_loop_mechandplayer",
            flag = 1
        }
    end
    
    DebugPrint("Config validation complete")
end

local function FormatRTLText(text)
    if Config and Config.UI and Config.UI.rtlText then
        return "\u{202B}" .. text .. "\u{202C}"
    else
        return text
    end
end

local function ShowNotification(msg, type)
    if Config and Config.ShowNotifications then
        QBCore.Functions.Notify(FormatRTLText(msg), type, 5000)
    end
end

local function HasVehicleBomb(vehicle)
    for _, v in pairs(BombedVehicles) do
        if v.vehicle == vehicle then
            return true
        end
    end
    return false
end

local function ShowProgressBar(text, duration)
    QBCore.Functions.Progressbar("vehiclebomb", FormatRTLText(text), duration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() end, function()
        IsPlacingBomb = false
        ClearPedTasks(PlayerPedId())
    end)
end

local function PlayInstallAnimation()
    local ped = PlayerPedId()
    local dict = Config.Animation.dict
    local anim = Config.Animation.name
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, Config.InstallTime, Config.Animation.flag, 0, false, false, false)
end

local function InstallBomb(vehicle)
    if IsPlacingBomb then 
        return 
    end
    
    if HasVehicleBomb(vehicle) then
        ShowNotification(Config.Text.alreadyBombed, "error")
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)
    
    if distance > 3.0 then
        ShowNotification(Config.Text.tooFar, "error")
        return
    end
    
    IsPlacingBomb = true
    ShowNotification(Config.Text.startInstall, "primary")
    
    PlayInstallAnimation()
    
    ShowProgressBar(Config.Text.installing, Config.InstallTime)
    
    Wait(Config.InstallTime)
    
    if not IsPlacingBomb then
        ShowNotification(Config.Text.installCancelled, "error")
        return
    end
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    
    table.insert(BombedVehicles, {
        vehicle = vehicle,
        netId = netId
    })
    
    TriggerServerEvent('sd-vehiclebomb:server:PlaceBomb', netId)
    
    TriggerServerEvent('sd-vehiclebomb:server:RemoveItem', Config.BombItem)
    
    IsPlacingBomb = false
    ClearPedTasks(playerPed)
    ShowNotification(Config.Text.installed, "success")
end

local function DetonateBomb(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    
    local coords = GetEntityCoords(vehicle)
    
    AddExplosion(
        coords.x, 
        coords.y, 
        coords.z, 
        Config.ExplosionType, 
        Config.ExplosionDamage, 
        true, 
        false, 
        Config.ExplosionShake
    )
    
    if Config.FireEffect then
        StartScriptFire(coords.x, coords.y, coords.z - 0.5, 25, false)
        StartScriptFire(coords.x + 1.0, coords.y, coords.z - 0.5, 25, false)
        StartScriptFire(coords.x, coords.y + 1.0, coords.z - 0.5, 25, false)
    end
    
    SetVehicleEngineHealth(vehicle, -4000.0)
    SetVehiclePetrolTankHealth(vehicle, -4000.0)
    
    for k, v in pairs(BombedVehicles) do
        if v.vehicle == vehicle then
            table.remove(BombedVehicles, k)
            break
        end
    end
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('sd-vehiclebomb:server:BombDetonated', netId)
    
    if ClosestBombedVehicle == vehicle then
        ClosestBombedVehicle = nil
        IsNearBombedVehicle = false
    end
    
    ShowNotification(Config.Text.detonated, "success")
end

local function DrawDetonationUI()
    if not IsNearBombedVehicle or not ClosestBombedVehicle then 
        return 
    end
    
    local width = Config.UI.width or 0.14
    local height = Config.UI.height or 0.075
    local borderThickness = Config.UI.borderThickness or 0.003
    local font = Config.UI.font or 4
    local scale = Config.UI.scale or 0.45
    local position = Config.UI.position or "right"
    local backgroundColor = Config.UI.backgroundColor or {0, 0, 0, 180}
    local textColor = Config.UI.textColor or {255, 255, 255, 255}
    local borderColor = Config.UI.borderColor or {255, 0, 0, 255}
    local showKey = Config.UI.showKey ~= false
    local keyText = Config.UI.keyText or "G"
    local blinking = Config.UI.blinking or false
    local blinkSpeed = Config.UI.blinkSpeed or 500
    local useGlowEffect = Config.UI.useGlowEffect or false
    local glowColor = Config.UI.glowColor or {255, 0, 0, 50}
    local glowSize = Config.UI.glowSize or 0.003
    local useBlur = Config.UI.useBlur or false
    local style = Config.UI.style or "classic"
    
    local x, y
    if position == "right" then
        x, y = 0.9 - width/2, 0.8 - height/2
    elseif position == "left" then
        x, y = 0.1 + width/2, 0.8 - height/2
    elseif position == "top" then
        x, y = 0.5, 0.1 + height/2
    elseif position == "bottom" then
        x, y = 0.5, 0.9 - height/2
    else 
        x, y = 0.5, 0.5
    end
    
    if blinking then
        local currentTime = GetGameTimer()
        if currentTime - BlinkTime > blinkSpeed then
            BlinkState = not BlinkState
            BlinkTime = currentTime
        end
        if not BlinkState then
            return
        end
    end
    
    if useBlur then
        DrawRect(x, y, width + 0.02, height + 0.02, 0, 0, 0, 100)
    end
    
    if useGlowEffect then
        DrawRect(x, y, width + glowSize, height + glowSize, 
            glowColor[1], glowColor[2], glowColor[3], glowColor[4])
    end
    
    DrawRect(x, y, width, height, 
        backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    
    DrawRect(x - width/2 - borderThickness/2, y, borderThickness, height + borderThickness*2, 
        borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    DrawRect(x + width/2 + borderThickness/2, y, borderThickness, height + borderThickness*2, 
        borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    DrawRect(x, y - height/2 - borderThickness/2, width + borderThickness*2, borderThickness, 
        borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    DrawRect(x, y + height/2 + borderThickness/2, width + borderThickness*2, borderThickness, 
        borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(textColor[1], textColor[2], textColor[3], textColor[4])
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    
    if showKey then
        AddTextComponentString("PRESS [" .. keyText .. "] TO DETONATE")
    else
        AddTextComponentString(FormatRTLText(Config.Text.pressToDetonate or "Press G to detonate"))
    end
    
    DrawText(x, y - 0.015)
    
    if style == "modern" then
        local keyWidth = 0.03
        local keyHeight = 0.03
        local keyX = x
        local keyY = y + 0.022
        DrawRect(keyX, keyY, keyWidth, keyHeight, 200, 0, 0, 200)
        SetTextFont(7)
        SetTextScale(0.5, 0.5)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString(keyText)
        DrawText(keyX, keyY - 0.014)
    end
end

CreateThread(function()
    Wait(1000)
    ValidateConfig()
    
    DebugPrint("Starting bomb detection thread")
    
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local closestVehicle = nil
        local closestDistance = Config.DetonateRange + 1.0
        
        for _, v in pairs(BombedVehicles) do
            if v.vehicle and DoesEntityExist(v.vehicle) then
                local vehCoords = GetEntityCoords(v.vehicle)
                local distance = #(playerCoords - vehCoords)
                
                if distance < closestDistance and distance <= Config.DetonateRange then
                    closestVehicle = v.vehicle
                    closestDistance = distance
                end
            end
        end
        
        if closestVehicle then
            IsNearBombedVehicle = true
            ClosestBombedVehicle = closestVehicle
        else
            IsNearBombedVehicle = false
            ClosestBombedVehicle = nil
        end
        
        Wait(500)
    end
end)

CreateThread(function()
    Wait(1500)
    
    DebugPrint("Starting detonation UI thread")
    
    while true do
        local sleep = 1000
        if IsNearBombedVehicle and ClosestBombedVehicle then
            sleep = 0
            DrawDetonationUI()
            if IsControlJustPressed(0, Config.DetonateKey) then
                DetonateBomb(ClosestBombedVehicle)
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('sd-vehiclebomb:client:UseItem')
AddEventHandler('sd-vehiclebomb:client:UseItem', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.DetectionRange, 0, 71)
    
    if vehicle ~= 0 then
        InstallBomb(vehicle)
    else
        ShowNotification(Config.Text.noVehicle, "error")
    end
end)

RegisterNetEvent('sd-vehiclebomb:client:SyncBombs')
AddEventHandler('sd-vehiclebomb:client:SyncBombs', function(netIds)
    BombedVehicles = {}
    for _, netId in pairs(netIds) do
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(vehicle) then
            table.insert(BombedVehicles, {
                vehicle = vehicle,
                netId = netId
            })
        end
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        ValidateConfig()
        TriggerServerEvent('sd-vehiclebomb:server:RequestSync')
        DebugPrint("Resource loaded successfully - Vehicle bomb ready for use")
    end
end)

RegisterCommand('bombconfig', function()
    print("^3===== VEHICLE BOMB CONFIG =====^7")
    print("Config exists: " .. tostring(Config ~= nil))
    if Config then
        print("ShowNotifications: " .. tostring(Config.ShowNotifications))
        print("DetonateRange: " .. tostring(Config.DetonateRange))
        print("DetonateKey: " .. tostring(Config.DetonateKey))
        print("UI exists: " .. tostring(Config.UI ~= nil))
        print("Text exists: " .. tostring(Config.Text ~= nil))
        if Config.Text then
            print("Text.noVehicle: " .. tostring(Config.Text.noVehicle))
        end
    end
    print("^3================================^7")
end, false)