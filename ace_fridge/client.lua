-- ace_fridge · client
-- Rail-menu fridge interaction. Same keys everywhere: up/down or wheel to
-- browse, E/Enter to select, Backspace/Esc to go back or close.

local openState = nil

-- ---------------------------------------------------------- tiny plumbing --

local cbSeq, pending = 0, {}
RegisterNetEvent('ace_fridge:cb', function(id, result)
    local p = pending[id]
    if p then
        pending[id] = nil
        p:resolve(result)
    end
end)

local function request(event, ...) -- always resolves with a single table
    cbSeq = cbSeq + 1
    local p = promise.new()
    pending[cbSeq] = p
    TriggerServerEvent(event, cbSeq, ...)
    return Citizen.Await(p)
end

local function notify(msg)
    if not msg then return end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function playOpenAnim()
    local dict = 'mp_common'
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    TaskPlayAnim(PlayerPedId(), dict, 'givetake1_a', 4.0, -4.0, 1200, 48, 0.0, false, false, false)
    Wait(900)
    ClearPedTasks(PlayerPedId())
end

local function drawHint(text)
    SetTextFont(4)
    SetTextScale(0.0, 0.42)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentSubstringPlayerName(text)
    DrawText(0.5, 0.92)
end

-- -------------------------------------------------------------- menu core --

local function pushState()
    local st = openState
    if not st then return end
    local rows = {}
    for i, row in ipairs(st.rows) do
        local r = {
            label = row.label,
            selected = i == st.sel,
            price = row.cancel and '' or ('x' .. tostring(row.count or 0)),
            inBag = 0,
        }
        if row.cancel then r.cancel = true end
        if row.addRow then r.price = '+' end
        rows[#rows + 1] = r
    end
    SendNUIMessage({
        action = 'shop:state',
        data = { items = rows, currency = '', scale = Config.MenuScale }
    })
end

local function closeMenu()
    if not openState then return end
    openState = nil
    SendNUIMessage({ action = 'shop:overlay', show = false })
end

local function refresh()
    local st = openState
    if not st then return end

    local rows
    if st.mode == 'main' then
        rows = request('ace_fridge:sv:list', st.stashId)
        if not rows then return closeMenu() end
        for _, r in ipairs(rows) do r.kind = 'take' end
        rows[#rows + 1] = { label = 'Add Item', addRow = true, kind = 'add', count = '' }
        rows[#rows + 1] = { label = 'Cancel', cancel = true, kind = 'cancel', count = '' }
    else
        rows = request('ace_fridge:sv:pockets')
        if not rows then return closeMenu() end
        for _, r in ipairs(rows) do r.kind = 'put' end
        rows[#rows + 1] = { label = 'Back', cancel = true, kind = 'back', count = '' }
    end
    st.rows = rows
    if st.sel > #st.rows then st.sel = #st.rows end
    pushState()
end

local function selectRow()
    local st = openState
    if not st then return end
    local row = st.rows[st.sel]
    if not row then return end

    if row.kind == 'cancel' then return closeMenu() end
    if row.kind == 'back' or row.kind == 'add' then
        st.mode = row.kind == 'back' and 'main' or 'add'
        st.sel = 1
        return refresh()
    end

    local res = request(row.kind == 'take' and 'ace_fridge:sv:take' or 'ace_fridge:sv:put', st.stashId, row.name)
    if res and res.ok == false then
        notify(res.msg)
    end
    refresh()
end

local function menuLoop()
    while openState do
        DisableControlAction(0, 1, true)   -- look left/right
        DisableControlAction(0, 2, true)   -- look up/down
        DisableControlAction(0, 24, true)  -- attack
        DisableControlAction(0, 25, true)  -- aim
        DisableControlAction(0, 142, true) -- melee attack alt

        if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 322) then -- Backspace / Esc
            if openState.mode == 'add' then
                openState.mode = 'main'
                openState.sel = 1
                refresh()
            else
                closeMenu()
            end
        elseif #openState.rows > 0 and (IsControlJustPressed(0, 172) or IsControlJustPressed(0, 15)) then
            openState.sel = (openState.sel - 2) % #openState.rows + 1
            pushState()
        elseif #openState.rows > 0 and (IsControlJustPressed(0, 173) or IsControlJustPressed(0, 14)) then
            openState.sel = openState.sel % #openState.rows + 1
            pushState()
        elseif #openState.rows > 0 and (IsControlJustPressed(0, 38) or IsControlJustPressed(0, 201)) then
            CreateThread(selectRow) -- request() awaits; keep the input loop live
        end

        if openState and #(GetEntityCoords(PlayerPedId()) - openState.coords) > 2.75 then
            closeMenu()
        end

        Wait(0)
    end
end

local function openFridge(data)
    if openState then return end

    local entity = data.entity
    local coords, model
    if entity and DoesEntityExist(entity) then
        coords = GetEntityCoords(entity)
        model = GetEntityModel(entity)
    else
        coords = data.coords
        model = 0
    end
    if not coords then return end

    playOpenAnim()

    local res = request('ace_fridge:sv:open', model, coords)
    if not res or not res.stashId then
        return notify('The fridge seems broken.')
    end

    openState = {
        stashId = res.stashId,
        coords = coords,
        mode = 'main',
        sel = 1,
        rows = {},
    }

    SendNUIMessage({ action = 'shop:overlay', show = true })
    refresh()
    CreateThread(menuLoop)
end

-- --------------------------------------------------------------- targeting --

local OPTION = { icon = Config.Icon, label = Config.Label }

local function registerTargets()
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addModel(Config.Models, {
            { name = 'ace_fridge_open', icon = OPTION.icon, label = OPTION.label, distance = Config.Distance, onSelect = openFridge },
        })
        for i, c in ipairs(Config.CustomSpots) do
            exports.ox_target:addSphereZone({
                coords = c, radius = 1.25,
                options = {
                    { name = 'ace_fridge_spot_' .. i, icon = OPTION.icon, label = OPTION.label, distance = Config.Distance,
                      onSelect = function() openFridge({ coords = c }) end },
                },
            })
        end
        return true
    end

    for _, target in ipairs({ 'qb-target', 'qtarget' }) do
        if GetResourceState(target) == 'started' then
            local t = exports[target]
            t:AddTargetModel(Config.Models, {
                options = {
                    { icon = OPTION.icon, label = OPTION.label,
                      action = function(entity) openFridge({ entity = entity }) end },
                },
                distance = Config.Distance,
            })
            for i, c in ipairs(Config.CustomSpots) do
                local name = 'ace_fridge_spot_' .. i
                t:AddCircleZone(name, c, 1.25, { name = name, useZ = true }, {
                    options = {
                        { icon = OPTION.icon, label = OPTION.label,
                          action = function() openFridge({ coords = c }) end },
                    },
                    distance = Config.Distance,
                })
            end
            return true
        end
    end

    return false
end

-- no target resource -> proximity prompt + E
CreateThread(function()
    if registerTargets() then return end

    local near = false
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local entity, spot

        for _, m in ipairs(Config.Models) do
            local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.0, joaat(m), false, false, false)
            if obj ~= 0 then entity = obj break end
        end
        if not entity then
            for _, c in ipairs(Config.CustomSpots) do
                if #(coords - c) <= 1.5 then spot = c break end
            end
        end

        near = (entity ~= nil) or (spot ~= nil)
        if near and not openState then
            drawHint('[E] ' .. Config.Label)
            if IsControlJustReleased(0, 38) then
                openFridge({ entity = entity, coords = spot })
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
