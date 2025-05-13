local QBCore = exports['qb-core']:GetCoreObject()
local BombedVehicles = {}

if not Config then
    print("^1[SD-VehicleBomb] ERROR: Config table is nil in server.lua. Creating default config...^7")
    Config = {
        Debug = true,
        BombItem = 'vehiclebomb'
    }
end

local function DebugPrint(msg)
    if Config and Config.Debug then
        print("^2[SD-VehicleBomb] ^7" .. msg)
    end
end

RegisterNetEvent('QBCore:Server:UpdateObject', function()
    if source ~= '' then return end
    QBCore = exports['qb-core']:GetCoreObject()
    DebugPrint("Server object updated")
end)

if not Config.BombItem then
    Config.BombItem = 'vehiclebomb'
    DebugPrint("BombItem not found in config, using default: 'vehiclebomb'")
end

Citizen.CreateThread(function()
    Wait(1000)
    
    DebugPrint("Registering usable item: " .. Config.BombItem)
    
    QBCore.Functions.CreateUseableItem(Config.BombItem, function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if Player then
            DebugPrint("Player " .. src .. " used item " .. Config.BombItem)
            TriggerClientEvent('sd-vehiclebomb:client:UseItem', src)
        end
    end)
end)

RegisterNetEvent('sd-vehiclebomb:server:PlaceBomb', function(netId)
    local src = source
    
    if netId then
        table.insert(BombedVehicles, netId)
        DebugPrint("Vehicle with netId " .. netId .. " has been bombed by player " .. src)
    else
        DebugPrint("WARNING: Received nil netId from player " .. src)
    end
end)

RegisterNetEvent('sd-vehiclebomb:server:BombDetonated', function(netId)
    local src = source
    
    if not netId then
        DebugPrint("WARNING: Received nil netId for detonation from player " .. src)
        return
    end
    
    for k, v in pairs(BombedVehicles) do
        if v == netId then
            table.remove(BombedVehicles, k)
            DebugPrint("Vehicle with netId " .. netId .. " has been detonated by player " .. src)
            break
        end
    end
end)

RegisterNetEvent('sd-vehiclebomb:server:RemoveItem', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not itemName then
        itemName = Config.BombItem
        DebugPrint("WARNING: Received nil itemName from player " .. src .. ", using default: " .. itemName)
    end
    
    if Player then
        Player.Functions.RemoveItem(itemName, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
        DebugPrint("Removed 1 " .. itemName .. " from player " .. src)
    else
        DebugPrint("WARNING: Could not find player " .. src)
    end
end)

RegisterNetEvent('sd-vehiclebomb:server:RequestSync', function()
    local src = source
    DebugPrint("Player " .. src .. " requested bomb sync, sending " .. #BombedVehicles .. " bombs")
    TriggerClientEvent('sd-vehiclebomb:client:SyncBombs', src, BombedVehicles)
end)

QBCore.Commands.Add('givebomb', 'Give a vehicle bomb item (Admin Only)', { { name = 'id', help = 'Player ID' } }, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    
    if Player then
        Player.Functions.AddItem(Config.BombItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', tonumber(args[1]), QBCore.Shared.Items[Config.BombItem], "add")
        TriggerClientEvent('QBCore:Notify', src, 'You gave a bomb to ' .. Player.PlayerData.charinfo.firstname, 'success')
        TriggerClientEvent('QBCore:Notify', tonumber(args[1]), 'You received a vehicle bomb', 'success')
        DebugPrint("Admin " .. src .. " gave a bomb to player " .. args[1])
    else
        TriggerClientEvent('QBCore:Notify', src, 'Player not online', 'error')
    end
end, 'admin')

RegisterCommand('checkbombs', function(source)
    if source > 0 then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player.PlayerData.permission == "admin" then
            TriggerClientEvent('QBCore:Notify', source, 'Active bombs: ' .. #BombedVehicles, 'primary')
        end
    else
        print("^3[SD-VehicleBomb] Active bombs: " .. #BombedVehicles .. "^7")
    end
end, true)