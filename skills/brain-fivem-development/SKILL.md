# brain-fivem-development

## Purpose

Development guidance for FiveM Lua scripting, NUI (HTML/JS interface), and QBox/QBCore/ESX framework work. Covers the most common mistakes and the patterns that avoid them.

**Note:** This is an optional skill. Enable it during setup (Question 14) or load it manually for FiveM work.

## When to Use

Writing or reviewing FiveM Lua scripts, NUI interfaces, resource manifests, or framework integrations (QBox, QBCore, ESX).

## When Not to Use

General web development, non-FiveM game scripting, or anything outside the FiveM/GTA V modding ecosystem.

## Workflow

**Server authority — mandatory rule**

The server is authoritative. Never trust client events. Every server event handler must validate:
- Input types: `type(amount) ~= 'number'`
- Input ranges: `amount < 1 or amount > maxAllowed`
- Player permissions: does the player own the thing they are trying to modify?
- Distance: is the player physically near the object they are interacting with?

```lua
RegisterNetEvent('myshop:server:purchase', function(itemId, quantity)
    local source = source  -- capture source first
    if type(itemId) ~= 'string' or type(quantity) ~= 'number' then return end
    if quantity < 1 or quantity > 100 then return end
    -- process...
end)
```

**Thread management — no Wait(0) in permanent loops**

`Wait(0)` on every frame burns CPU. Use adaptive wait based on distance, or event-driven patterns.

```lua
-- BAD
CreateThread(function()
    while true do
        checkNearbyThings()
        Wait(0)  -- Every frame!
    end
end)

-- GOOD: Adaptive wait
CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(cache.ped)
        for _, zone in ipairs(zones) do
            if #(coords - zone.coords) < 5.0 then sleep = 0 end
        end
        Wait(sleep)
    end
end)

-- BEST: Use ox_lib target zones (no loop needed)
exports.ox_target:addBoxZone({ coords = ..., options = { ... } })
```

**NUI transparency — mandatory**

NUI backgrounds must be transparent. A black NUI background blocks the game view and looks wrong.

```css
html, body {
    background: transparent !important;
    overflow: hidden;
}
```

Animate only compositor-friendly properties: `transform` and `opacity`. Never animate `width`, `height`, `top`, or `left`.

**Framework detection order**

Always check in this order: qbx_core → qb-core → es_extended.

```lua
local function DetectFramework()
    if GetResourceState('qbx_core') ~= 'missing' then return 'qbox' end
    if GetResourceState('qb-core') ~= 'missing' then return 'qbcore' end
    if GetResourceState('es_extended') ~= 'missing' then return 'esx' end
    return nil
end
```

**Natives: verify before using**

Never guess native function names or parameters. Verify at `docs.fivem.net/natives` before using any native you are not certain about. Invented natives cause silent errors that are hard to trace.

**Event naming convention**

`resourcename:side:action`

Examples: `myshop:server:purchase`, `myshop:client:openMenu`, `myshop:client:updateUI`

**Rate limiting**

```lua
local cooldowns = {}
RegisterNetEvent('myresource:action', function()
    local source = source
    local now = GetGameTimer()
    if cooldowns[source] and now - cooldowns[source] < 1000 then return end
    cooldowns[source] = now
    -- process...
end)
```

**Statebags for state sync**

Use statebags instead of event spam for state that multiple parties need to observe.

```lua
-- Server
Player(source).state:set('duty', true, true)

-- Client (reads own state)
local onDuty = LocalPlayer.state.duty
```

## Checklist

- [ ] Server validates all client event inputs (type, range, permission, distance)
- [ ] No `Wait(0)` in permanent loops
- [ ] NUI has transparent background
- [ ] Natives verified at docs.fivem.net
- [ ] Event names follow `resource:side:action` pattern
- [ ] Rate limiting on server events
- [ ] ox_lib target used instead of distance-check loops where possible
- [ ] Framework detected at runtime, not hardcoded

## Token Discipline

Load this skill at the start of a FiveM development session. It covers the most common mistakes and saves debugging time. Cost: roughly 90 tokens. Do not load it for non-FiveM work.

## Verification

After writing a FiveM script, check:
1. Does every server event validate input before processing?
2. Does any thread use `Wait(0)` without a clear frame-by-frame requirement?
3. Does the NUI CSS set `background: transparent`?
4. Are all native function names verified against the docs?

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository. Do not include server IPs, rcon passwords, or license keys in FiveM scripts committed to public repositories.
