require("mod_hivemind_bot")

function _sandbox_init(_ENV) -- ignore -------------------------------------
    ----------------------------------------------------------------------------
    -- BOTS GO BELOW -----------------------------------------------------------
    ----------------------------------------------------------------------------

    -- .items: The current state of the game.  Is a o.n=>item array of users,planets,fleets
    -- { n = o.n, is_user = bool, is_planet = bool, is_fleet = bool,
    -- x = o.position_x, y = o.position_y, r = o.planet_r or o.fleet_r,
    -- ships = o.ships_value or o.fleet_ships, production = o.ships_production,
    -- owner = o.owner_n, team = o:owner().user_team_n, neutral = o:owner().user_neutral,
    -- target = o.fleet_target }

    -- .user: The user number of this bot

    -- .options: Optional parameters.  This way you can battle the same bot against itself with different options.  Always set params to your best default when it is not provided.

    -- .memory: A table you can store data in.  Limit 64K.

    -- RETURN: Your bot should return a single command {percent=50,from=N or {N1,N2,N3...},to=N} The from may include both planets and/or fleets.
    
    function bots_1(params)
        return bot_hivemind(params, sb_stats)
        -- return bots_simple(params, true)
    end

    function bots_2(params)
        -- return bots_simple(params, false)
    end

    function bots_simple(params, shouldTunnel)
        -- setup
        G = params.items
        USER = params.user
        OPTS = params.opts
        MEM = params.memory
        OPTS = OPTS or {percent = 65} -- setup defaults for the live server
        MEM.t = (MEM.t or 0) + 1
        if (MEM.t % 4) ~= 1 then
            -- return
        end -- do an action once per second

        -- filter all items to just planets
        local planets = {}
        for _, o in pairs(G) do
            if o.is_planet then
                planets[#planets + 1] = o
            end
        end

        -- search list for the best match by greatest result
        local function find(Q, f)
            local r, v
            for _, o in pairs(Q) do
                local _v = f(o)
                if _v and ((not r) or _v > v) then
                    r, v = o, _v
                end
            end
            return r
        end
        -- return distance between planets
        local function dist(a, b)
            return ((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2) ^ 0.5
        end

        -- find a source planet
        local from =
            find(
            planets,
            function(o)
                if o.owner == USER then
                    return o.ships
                end
            end
        )
        if not from then
            return
        end

        -- check if we've run out of resources
        local ticks, alloc = sb_stats()
        if ticks > 60 or alloc > 60 then
            return
        end

        -- find a target planet
        local to =
            find(
            planets,
            function(o)
                if o.owner ~= USER then
                    return o.production - o.ships - 0.2 * dist(from, o)
                end
            end
        )
        if not to then
            return
        end
        
        if shouldTunnel then 
            MEM.mapData = MEM.mapData or {}
            map = Map.new(G, MEM.mapData)
            to = map:getTunnelAlias(from.n, to.n)
        end

        -- by using a table for from, you can send from multiple planets and fleets
        return {percent = OPTS.percent, from = {from.n}, to = to.n}
    end

end
----------------------------------------------------------------------------
-- REGISTER BOTS -----------------------------------------------------------
----------------------------------------------------------------------------
global("BOTS") 
BOTS = {}

-- "bots_register" - Register your bot using this function

-- NAME: The display name of your bot
-- LOOP: the loop function name for your bot
-- OPTIONS: optional parameters for your bot, do not use for globals.
function bots_register(name, loop, options)
    BOTS[name] = {name = name, loop = loop, ok = true, options = options}
end

function register_bots()
    bots_register("Compare", "bots_2")
    bots_register("Dev", "bots_1",
    {
        debug = DEBUG
    })
    -- bots_register("simple", "bots_simple")
end

register_bots()

----------------------------------------------------------------------------
-- Below this is the code for running the bot war
-- You may want to tweak some of the GAME
-- settings below to ensure your bot works well on larger maps.
----------------------------------------------------------------------------
-- MOD ---------------------------------------------------------------------
----------------------------------------------------------------------------

function init()
    COLORS = {
        0x555555,
        0xff0000,
        0x0000ff,
        0xffff00,
        0x00ffff,
        0xbb00ff,
        0x00ff00,
        0xff8800,
        0x9999ff,
        0x99ff99,
        0xff88ff,
        0xff9999 -- 0xffffff reserved for live player
    }
    GAME = {
        t = 0.0,
        ships = 100,
        sw = 480,
        sh = 320,
        planets = 23,
        production = 100, -- small map
        -- sw = 840, sh = 560, planets = 48, production = 125, -- standard map
        -- sw = 977, sh = 652, planets = 65, production = 125, -- large map
        wins = {},
        total = 0,
        timeout = 300.0,
        players = 2, -- max number of players in a round
        speed = 1, -- more time per loop, 15 max (1/4 second)
        ticks = 1, -- more loops per frame
        -- speed = 12, -- more time per loop, 15 max (1/4 second)
        -- ticks = 40, -- more loops per frame
        live = false,
        delay = 0.25,
        -- mapSeed = 26,
        -- mapSeed = 559, -- streaming slowly
        mapSeed = 26,
        minNeutralProd = 15,
        maxNeutralShips = 50
    }
    DEBUG = {
        drawFriendlyFrontPlanets = true,
        drawEnemyFrontPlanets = true,
        drawFriendlyTunnels = true,
        drawEnemyTunnels = true,
        drawFriendlyExpansionPlan = true,
        drawEnemyExpansionPlan = true,
    }

    reset(false)
end

function reset(live)
    GAME.live = live
    GAME.total = 0
    GAME.wins = {}
    next_game()
end

function next_game()
    resetAllDebugDrawings()
    g2.game_reset()

    print('starting game with seed ' .. GAME.mapSeed)
    math.randomseed(GAME.mapSeed)
    
    GAME.t = 0

    local u0 = g2.new_user("neutral", COLORS[1])
    GAME.u_neutral = u0
    u0.user_neutral = true
    u0.ships_production_enabled = 0

    GAME.users = {}
    local _bots = {}
    for _, b in pairs(BOTS) do
        if b.ok then
            _bots[#_bots + 1] = copy(b)
        end
    end
    table.sort(
        _bots,
        function(a, b)
            return a.name < b.name
        end
    )
    shuffle(_bots)

    GAME.bots = {}

    local total = 0
    local maxBotPlayers = GAME.players
    if GAME.live then 
        maxBotPlayers = maxBotPlayers - 1 
        math.random() -- maintain same seed
    end
    for n = 1, maxBotPlayers do
        local bot = _bots[n]
        if bot then
            GAME.bots[bot.name] = bot
            bot.memory = {}
            bot.t = math.random()
            bot.delay = GAME.delay
            local user = g2.new_user(bot.name, COLORS[1 + n])
            user.ui_ships_show_mask = 0xf
            GAME.users[bot.name] = user
            total = total + 1
        end
    end

    local pad = 0
    local sw = GAME.sw
    local sh = GAME.sh

    local o1 = g2.new_user("player", 0xffffff)
    o1.ui_ships_show_mask = 0xf
    g2.player = o1
    if GAME.live then
        GAME.users["player"] = o1
        total = total + 1
    end

    local n = GAME.planets - total
    for i = 1, n / 2 do
        local x = math.random(pad,sw-pad)
        local y = math.random(pad,sh-pad)
        local p = math.random(GAME.minNeutralProd,100)
        local s = math.random(0,GAME.maxNeutralShips)
        g2.new_planet(u0, x, y, p, s);
        g2.new_planet(u0, sw - x, sh - y, p, s);
    end

    local a = math.random(0, 360)
    local x, y
    local users = {}
    for name, user in pairs(GAME.users) do
        users[#users + 1] = user
    end
    shuffle(users)

    for _, user in ipairs(users) do
        x = sw / 2 + (sw - pad * 2) * math.cos(a * math.pi / 180.0) / 2.0
        y = sh / 2 + (sh - pad * 2) * math.sin(a * math.pi / 180.0) / 2.0
        g2.new_planet(user, x, y, GAME.production, GAME.ships)
        a = a + 360 / total
    end

    g2.planets_settle()

    g2.state = "play"
    g2.speed = GAME.speed
    g2.ticks = GAME.ticks

    if GAME.live then
        g2.speed = 1
        g2.ticks = 1
    end

    GAME.total = GAME.total + 1
end

function loop(t)
    GAME.t = GAME.t + t
    if GAME.t > GAME.timeout then
        local name = "*TIMEOUT*"
        GAME.wins[name] = (GAME.wins[name] or 0) + 1
        update_stats()
        next_game()
    end

    if GAME.t < 0.5 then
        return
    end -- give human a chance

    local users = {}
    for name, user in pairs(GAME.users) do
        if name ~= "player" then
            local info = GAME.bots[name]
            users[#users + 1] = {name = name, user = user, info = info}
        end
    end
    shuffle(users)

    local data = nil
    for _, bot in pairs(users) do
        if bot.info.ok then -- about 4x per second
            local pt = bot.info.t
            bot.info.t = bot.info.t + t
            if math.floor(bot.info.t / bot.info.delay) ~= math.floor(pt / bot.info.delay) then
                local data = data or _bots_data()
                local ok, msg =
                    pcall(
                    function()
                        _bots_run(data, bot.info.loop, bot.user.n, bot.info.options, bot.info.memory)
                    end
                )

                if not ok then
                    print(msg)
                    BOTS[bot.name].ok = false
                    bot.info.ok = false
                    local user = bot.user
                    local neutral = GAME.u_neutral
                    for n, e in pairs(g2.search("planet owner:" .. user)) do
                        e:planet_chown(neutral)
                    end
                    for n, e in pairs(g2.search("fleet owner:" .. user)) do
                        e:destroy()
                    end
                end
            end
        end
    end

    local win = nil
    local planets = g2.search("planet -neutral")
    for _i, p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then
            win = user
        end
        if (win ~= user) then
            return nil
        end
    end

    if win ~= nil then
        local name = win.title_value
        GAME.wins[name] = (GAME.wins[name] or 0) + 1
        update_stats()
        next_game()
    end
end

function _bots_data()
    -- local r = g2.search("user OR team OR planet OR fleet")
    local r = g2.search("user OR planet OR fleet")
    local res = {}
    for _, o in ipairs(r) do
        local _type = nil
        -- IMPORTANT: the "viewer" g2.player should not be fed to the bot if it isn't playing!!
        if o.has_user and (GAME.live or o.title_value ~= "player") then
            res[o.n] = {
                n = o.n,
                is_user = true,
                team = o.user_team_n,
                neutral = o.user_neutral
            }
        elseif o.has_planet then
            local u = o:owner()
            res[o.n] = {
                n = o.n,
                is_planet = true,
                x = o.position_x,
                y = o.position_y,
                r = o.planet_r,
                ships = o.ships_value,
                production = o.ships_production,
                owner = o.owner_n,
                team = u.user_team_n,
                neutral = u.user_neutral
            }
        elseif o.has_fleet then
            local u = o:owner()
            local sync_id = tostring(o.sync_id)
            res[sync_id] = {
                _n = o.n,
                n = sync_id,
                is_fleet = true,
                x = o.position_x,
                y = o.position_y,
                r = o.fleet_r,
                ships = o.fleet_ships,
                owner = o.owner_n,
                team = u.user_team_n,
                target = o.fleet_target
            }
        end
    end
    return res
end

function memory_estimate(r) -- rough estimate of memory usage, inf on error
    local _stack = {}
    local function _calc(r)
        local _type = type(r)
        if _type == "number" then
            return 16
        end -- 9999
        if _type == "string" then
            return 16 + #r
        end -- "abc"
        if _type == "boolean" then
            return 16
        end -- true
        if _type == "table" then
            if _stack[r] then
                return math.huge
            end -- error on loops
            _stack[r] = true
            local t = 16 -- {}
            local n = 0
            for k, v in pairs(r) do
                t = t + _calc(k) + _calc(v) -- k:v,
                n = n + 1
            end
            if #r == n then
                t = t - n * 16
            end -- v,
            _stack[r] = nil
            return t
        end
        return math.huge -- error on other types
    end
    return _calc(r)
end

function _bots_sandbox(live)
    local sb = {
        type = type,
        pairs = pairs,
        print = print,
        strsub = string.sub,
        abs = math.abs,
        ceil = math.ceil,
        floor = math.floor,
        max = math.max,
        min = math.min,
        HUGE = math.huge,
        random = math.random,
        PI = math.pi,
        cos = math.cos,
        sin = math.sin,
        atan2 = math.atan2,
        log = math.log,
        pow = math.pow,
        sqrt = math.sqrt,
        exp = math.exp,
        sb_stats = g2_sandbox_stats,
        bot_hivemind = bot_hivemind,
        Map = Map
    }
    if live then
        sb.print = function()
        end
    end
    sb.sort = function(t, f)
        assert(type(f) == "function", "bad argument #2 to 'sort' (function expected)")
        for k, v in pairs(sb) do
            if v == f then
                error("unsafe order function for sorting")
            end
        end
        return table.sort(t, f)
    end
    return sb
end

function _bots_run(_data, loop, uid, _options, memory)
    -- reset environment
    local env = _bots_sandbox()
    local res = nil
    local data = copy(_data)
    local options = copy(_options)
    local debug = {
        debugDrawPaths = debugDrawPaths,
        debugHighlightPlanets = debugHighlightPlanets
    }
    resetDebugDrawings(uid)

    local ok, msg =
        g2_sandbox(
        function()
            _sandbox_init(env)
            res = env[loop]({items = data, user = uid, options = options, memory = memory, debug = debug})
        end,
        64000000,
        64000000
    )
    if not ok then
        error("[" .. loop .. "]: " .. msg)
        return
    end
    if memory_estimate(memory) > 64000000 then
        error("[" .. loop .. "]: memory limit exceeded")
        return
    end

    if not res then
        return
    end
    local data = _data

    -- res.action = res.action or 'send'
    -- if res.action == 'redirect' then res.action = 'send' end
    -- if res.action == 'send' then
    if true then
        local percent = res.percent or 50
        percent = math.max(5, math.min(100, round(percent / 5) * 5))
        local from = res.from
        if type(from) ~= "table" then
            from = {from}
        end
        local to = res.to
        if data[to].is_planet then
            for _, f in pairs(from) do
                if data[f].is_planet and data[f].owner == uid then
                    g2_fleet_send(percent, f, to)
                end
                if data[f].is_fleet and data[f].owner == uid and data[f].target ~= to then
                    g2_fleet_redirect(data[f]._n, to)
                end
            end
        end
    end
end

function update_stats()
    local stats = {}
    for name, total in pairs(GAME.wins) do
        stats[#stats + 1] = {name, total}
    end
    table.sort(
        stats,
        function(a, b)
            return a[2] > b[2]
        end
    )
    local info = ""
    for i, item in ipairs(stats) do
        info = info .. item[1] .. ":" .. tostring(item[2]) .. "  "
    end
    local function gprint(msg)
        print("[" .. tostring(GAME.total) .. "] " .. msg)
    end
    gprint(info)
end

function resetAllDebugDrawings()
    DEBUG_DRAWINGS = DEBUG_DRAWINGS or {}
    for userN, drawings in pairs(DEBUG_DRAWINGS) do 
        for _,o in pairs(drawings) do 
            o:destroy()
        end
    end
    DEBUG_DRAWINGS = {}
end

function resetDebugDrawings(userN)
    DEBUG_DRAWINGS = DEBUG_DRAWINGS or {}
    DEBUG_DRAWINGS[userN] = DEBUG_DRAWINGS[userN] or {}
    for i,o in pairs(DEBUG_DRAWINGS[userN]) do 
        o:destroy()
    end
    DEBUG_DRAWINGS[userN] = {}
end

function debugHighlightPlanets(botUser, planets, planetOwner, offset)
    offset = offset or 0

    local highlightColor = g2.item(planetOwner.n).render_color
    highlightColor = adjustSaturation(highlightColor, -0.5)

    local SHIP_RADIUS = 6
    for i, p in pairs(planets) do
        local o = g2.new_circle(highlightColor, p.x, p.y, p.r + SHIP_RADIUS + offset)
        table.insert(DEBUG_DRAWINGS[botUser.n], o)
    end
end

function debugDrawPaths(botUser, planetOrFleetPairs, planetOwner)
    local highlightColor = g2.item(planetOwner.n).render_color
    highlightColor = adjustSaturation(highlightColor, -0.5)
    for i, pair in pairs(planetOrFleetPairs) do
        local o = g2.new_line(highlightColor, pair.source.x, pair.source.y, pair.target.x, pair.target.y)
        table.insert(DEBUG_DRAWINGS[botUser.n], o)
    end
end

-- TODO: put in library
-- 0.5 returns a color 50% lighter, 0 returns color, 1 returns full-saturation color, -1 returns black
function adjustSaturation(hexColor, satAdjustment)
    local rgb = 0x000000
    for i = 0,2 do 
        local c = math.floor(hexColor / 256^i) % 256
        c = common_utils.round(common_utils.clamp(c + c * satAdjustment, 0, 255))
        rgb = rgb + c * 256^i
    end
    return rgb
end

-- TODO: draw these later
function visualizeBlockedPaths(map, tunnelProxies, blockedPathCorrections)
    for i, target in ipairs(tunnelProxies) do
        local source = map[i]
        local avgX = (source.position_x + target.position_x) / 2
        local avgY = (source.position_y + target.position_y) / 2
        local correction = round(blockedPathCorrections[source.n][target.n])
        g2.new_label(correction, avgX, avgY, 0xffaaff)
    end
end

function event(e)
    if (e["type"] == "pause") then
        g2.html =
            [[
        <table>
        <tr><td><input type='button' value='Play' onclick='play' />
        <tr><td><input type='button' value='Resume' onclick='resume' />
        <tr><td><input type='button' value='Reset' onclick='reset' />
        <tr><td><input type='button' value='New Seed' onclick='newSeed' />
        <tr><td><input type='button' value='Quit' onclick='quit' />
        ]]
        g2.state = "pause"
    end
    if (e["type"] == "onclick" and e["value"] == "play") then
        reset(true)
    end
    if (e["type"] == "onclick" and e["value"] == "reset") then
        reset(false)
    end
    if (e["type"] == "onclick" and e["value"] == "newSeed") then
        GAME.mapSeed = math.random(0, 1000)
        reset(GAME.live)
    end
    if (e["type"] == "onclick" and e["value"] == "resume") then
        g2.state = "play"
    end
    if (e["type"] == "onclick" and e["value"] == "quit") then
        g2.state = "quit"
    end
end

----------------------------------------------------------------------------
-- UTILITY FUNCTIONS -------------------------------------------------------
----------------------------------------------------------------------------

function pass()
end

function shuffle(t)
    for i, v in ipairs(t) do
        local n = math.random(i, #t)
        t[i] = t[n]
        t[n] = v
    end
end

function copy(o)
    if type(o) ~= "table" then
        return o
    end
    local r = {}
    for k, v in pairs(o) do
        r[k] = copy(v)
    end
    return r
end

function round(num)
    return math.floor(num + 0.5)
end

----------------------------------------------------------------------------
-- LICENSE -----------------------------------------------------------------
----------------------------------------------------------------------------

LICENSE =
    [[
mod_botwar.lua

Copyright (c) 2013 Phil Hassey
Modifed by: YOUR_NAME_HERE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]
