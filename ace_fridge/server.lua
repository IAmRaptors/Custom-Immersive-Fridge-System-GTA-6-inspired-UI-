-- ace_fridge · server
-- Fridge contents live in resource KVP (survives restarts), keyed per fridge.
-- Player items move through an adapter that autodetects the inventory:
--   ox_inventory / qb-inventory family (qb-core objects) / ESX.

local RES = GetCurrentResourceName()

-- ------------------------------------------------------------- inventory --

local Inv = {}

if GetResourceState('ox_inventory') == 'started' then
    local ox = exports.ox_inventory
    print('[ace_fridge] inventory backend: ox_inventory')

    function Inv.items(src)
        local out, acc, labels = {}, {}, {}
        for _, slot in pairs(ox:GetInventoryItems(src) or {}) do
            if slot.name and (slot.count or 0) > 0 then
                acc[slot.name] = (acc[slot.name] or 0) + slot.count
                labels[slot.name] = labels[slot.name] or (slot.metadata and slot.metadata.label) or Inv.label(slot.name)
            end
        end
        for name, count in pairs(acc) do out[#out + 1] = { name = name, count = count, label = labels[name] } end
        return out
    end

    function Inv.count(src, name) return ox:GetItemCount(src, name) or 0 end
    function Inv.add(src, name, n) ox:AddItem(src, name, n) end
    function Inv.remove(src, name, n) ox:RemoveItem(src, name, n) end
    function Inv.label(name)
        local it = ox:Items(name)
        return (it and it.label) or name
    end

    function Inv.hasFoodStatus(name)
        local it = ox:Items(name)
        local s = it and it.client and it.client.status
        return s ~= nil and (s.hunger ~= nil or s.thirst ~= nil or s.drunk ~= nil)
    end

elseif GetResourceState('qb-core') == 'started' then
    local QBCore = exports['qb-core']:GetCoreObject()
    print('[ace_fridge] inventory backend: qb-core')

    local function P(src) return QBCore.Functions.GetPlayer(src) end

    function Inv.items(src)
        local p = P(src)
        local out, acc, labels = {}, {}, {}
        for _, it in pairs(p and p.PlayerData.items or {}) do
            local name, count = it.name, it.amount or it.count or 0
            if name and count > 0 then
                acc[name] = (acc[name] or 0) + count
                labels[name] = labels[name] or it.label
            end
        end
        for name, count in pairs(acc) do out[#out + 1] = { name = name, count = count, label = labels[name] } end
        return out
    end

    function Inv.count(src, name)
        local p = P(src)
        local it = p and p.Functions.GetItemByName(name)
        return (it and (it.amount or it.count)) or 0
    end

    function Inv.add(src, name, n)
        local p = P(src)
        if p then p.Functions.AddItem(name, n) end
    end

    function Inv.remove(src, name, n)
        local p = P(src)
        if p then p.Functions.RemoveItem(name, n) end
    end

    function Inv.label(name)
        local it = QBCore.Shared.Items[name]
        return (it and it.label) or name
    end

    function Inv.hasFoodStatus() return false end

elseif GetResourceState('es_extended') == 'started' then
    local ESX = exports['es_extended']:getSharedObject()
    print('[ace_fridge] inventory backend: es_extended')

    local function P(src) return ESX.GetPlayerFromId(src) end

    function Inv.items(src)
        local p = P(src)
        local out, acc, labels = {}, {}, {}
        for _, it in pairs(p and p.getInventory() or {}) do
            if it.name and (it.count or 0) > 0 then
                acc[it.name] = (acc[it.name] or 0) + it.count
                labels[it.name] = labels[it.name] or it.label
            end
        end
        for name, count in pairs(acc) do out[#out + 1] = { name = name, count = count, label = labels[name] } end
        return out
    end

    function Inv.count(src, name)
        local p = P(src)
        local it = p and p.getInventoryItem(name)
        return (it and it.count) or 0
    end

    function Inv.add(src, name, n)
        local p = P(src)
        if p then p.addInventoryItem(name, n) end
    end

    function Inv.remove(src, name, n)
        local p = P(src)
        if p then p.removeInventoryItem(name, n) end
    end

    function Inv.label(name)
        local ok, label = pcall(ESX.GetItemLabel, name)
        return (ok and label) or name
    end

    function Inv.hasFoodStatus() return false end

else
    print('[ace_fridge] WARNING: no supported inventory found (ox_inventory / qb-core / es_extended) -- menus will open but transfers will fail')
    function Inv.items() return {} end
    function Inv.count() return 0 end
    function Inv.add() end
    function Inv.remove() end
    function Inv.label(name) return name end
    function Inv.hasFoodStatus() return false end
end

-- ------------------------------------------------------------- whitelist --

local consumables = {}
for _, name in ipairs(Config.Consumables) do consumables[name] = true end
for _, name in ipairs(Config.ExtraItems) do consumables[name] = true end

for _, name in ipairs(Config.Blocklist) do consumables[name] = false end
local function allowed(name) return consumables[name] == true or (consumables[name] == nil and Inv.hasFoodStatus(name)) end

-- --------------------------------------------------------------- storage --

local KEY = 'ace_fridge:stores'
local stores = json.decode(GetResourceKvpString(KEY) or '{}') or {}

local function save() SetResourceKvp(KEY, json.encode(stores)) end
AddEventHandler('onResourceStop', function(r) if r == RES then save() end end)

local function stashId(model, coords)
    return ('f_%x_%d_%d_%d'):format(model, math.floor(coords.x + 0.5), math.floor(coords.y + 0.5), math.floor(coords.z + 0.5))
end

local function storeFor(id)
    local s = stores[id]
    if not s then s = {} stores[id] = s end
    return s
end

local function storeRows(id)
    local s = stores[id] or {}
    local rows = {}
    for name, count in pairs(s) do
        if count > 0 then rows[#rows + 1] = { name = name, label = Inv.label(name), count = count } end
    end
    table.sort(rows, function(a, b) return a.label < b.label end)
    return rows
end

local function isNear(source, coords)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= 10.0
end

local function coordsFromId(id)
    local x, y, z = id:match('f_%x+_(%-?%d+)_(%-?%d+)_(%-?%d+)')
    if not x then return nil end
    return vector3(tonumber(x), tonumber(y), tonumber(z))
end

-- ------------------------------------------------------- request handlers --

-- client: request(event, ...) -> resolves with whatever table we send back
local function reply(src, reqId, result)
    TriggerClientEvent('ace_fridge:cb', src, reqId, result)
end

RegisterNetEvent('ace_fridge:sv:open', function(reqId, model, coords)
    local src = source
    if type(model) ~= 'number' or type(coords) ~= 'vector3' or not isNear(src, coords) then
        return reply(src, reqId, {})
    end
    reply(src, reqId, { stashId = stashId(model, coords) })
end)

RegisterNetEvent('ace_fridge:sv:list', function(reqId, id)
    local src = source
    if type(id) ~= 'string' then return reply(src, reqId, nil) end
    reply(src, reqId, storeRows(id))
end)

RegisterNetEvent('ace_fridge:sv:pockets', function(reqId)
    local src = source
    local rows = {}
    for _, it in ipairs(Inv.items(src)) do
        if allowed(it.name) then
            rows[#rows + 1] = { name = it.name, label = it.label or Inv.label(it.name), count = it.count }
        end
    end
    table.sort(rows, function(a, b) return a.label < b.label end)
    reply(src, reqId, rows)
end)

RegisterNetEvent('ace_fridge:sv:take', function(reqId, id, item)
    local src = source
    if type(id) ~= 'string' or type(item) ~= 'string' then return reply(src, reqId, { ok = false }) end
    local coords = coordsFromId(id)
    if not coords or not isNear(src, coords) then return reply(src, reqId, { ok = false, msg = 'Too far from the fridge.' }) end

    local s = stores[id]
    if not s or not s[item] or s[item] < 1 then return reply(src, reqId, { ok = false, msg = 'Not in the fridge.' }) end

    -- add-then-verify: if the inventory is full the count will not rise and
    -- the fridge keeps its item. no dupes, no losses.
    local before = Inv.count(src, item)
    Inv.add(src, item, 1)
    if Inv.count(src, item) <= before then
        return reply(src, reqId, { ok = false, msg = 'You cannot carry that.' })
    end

    s[item] = s[item] - 1
    if s[item] <= 0 then s[item] = nil end
    save()
    reply(src, reqId, { ok = true })
end)

RegisterNetEvent('ace_fridge:sv:put', function(reqId, id, item)
    local src = source
    if type(id) ~= 'string' or type(item) ~= 'string' then return reply(src, reqId, { ok = false }) end
    local coords = coordsFromId(id)
    if not coords or not isNear(src, coords) then return reply(src, reqId, { ok = false, msg = 'Too far from the fridge.' }) end
    if not allowed(item) then return reply(src, reqId, { ok = false, msg = 'That does not belong in a fridge.' }) end

    local s = storeFor(id)
    -- MaxItems distinct types; stacking an existing type is always fine
    if not s[item] then
        local kinds = 0
        for _ in pairs(s) do kinds = kinds + 1 end
        if kinds >= Config.MaxItems then
            return reply(src, reqId, { ok = false, msg = 'The fridge is full.' })
        end
    end

    local before = Inv.count(src, item)
    if before < 1 then return reply(src, reqId, { ok = false, msg = 'You do not have that.' }) end
    Inv.remove(src, item, 1)
    if Inv.count(src, item) >= before then
        return reply(src, reqId, { ok = false, msg = 'You do not have that.' })
    end

    s[item] = (s[item] or 0) + 1
    save()
    reply(src, reqId, { ok = true })
end)
