----------------------------------------------------------------------------

-- Hi, and welcome to the BOTWAR!
--
-- To create a bot first go down to the "BOTS GO BELOW" section
-- and look at the code!  Try and changing some simple things,
-- and then adding your own ideas.  If you are unfamiliar with
-- Lua there are plenty of tutorials on the internet.
-- Also you can ask questions in the Modding forums:
-- https://www.galcon.com/forums/55/65/
--
-- Bots are memory limited to 64K of temporary memory and time limited
-- to 64k instructions 4x a second.  Bots are also given 64K of storage.
-- Bots that exceed those limits will automatically crash.
-- Bot code should be limited to under 16K bytes.
-- Lua code is restricted to a small selection of safe functions.
--
-- type,pairs,print, -- general functions
-- strsub, -- string functions
-- HUGE,PI -- math constants
-- abs,ceil,floor,max,min,random,cos,sin,atan2,log,pow,sqrt,exp -- math functions
--
-- You may add multiple bots to this file.  And you can even
-- try different options out on your bots to see which works
-- the best.  You can adjust these options in the "REGISTER BOTS"
-- section of the file.
--
-- You can also play against your bots by pressing the pause button
-- and then pressing the play button.  Try and make your bots
-- feel like playing against real players.  Bots may do multiple actions
-- per turn, but they can only use a single target per turn and
-- percentages are rounded to the nearest 5%.
--
-- Once you have a bot you are proud of, go to:
-- http://www.galcon.com/g2/mods.php
-- There you can submit your bot to be tried out in the game!
-- Once it is reviewed, it will play against
-- other human players and other bots!
--
-- Fine print: bots may be removed or disabled for any reason.
--
-- Have fun!
-- -Phil

----------------------------------------------------------------------------
function _sandbox_init(_ENV) -- ignore -------------------------------------
----------------------------------------------------------------------------
-- BOTS GO BELOW -----------------------------------------------------------
----------------------------------------------------------------------------

-- "bots_simple" - You can name your bot loop function whatever you want.
-- Your script may contain other functions.  However, globals will be
-- reset each time the bot is called, so do not depend on them.
-- Your script will be called approximately 4x per second.

-- .items: The current state of the game.  Is a key=>item array of users,planets,fleets
    -- { n = o.n, type = user/planet/fleet,
    -- x = o.position_x, y = o.position_y, r = o.planet_r or o.fleet_r,
    -- ships = o.ships_value or o.fleet_ships, production = o.ships_production,
    -- owner = o.owner_n, team = o:owner().user_team_n, neutral = o:owner().user_neutral,
    -- target = o.fleet_target }

-- .user: The user number of this bot

-- .options: Optional parameters.  This way you can battle the same bot against itself with different options.  Always set params to your best default when it is not provided.

-- .storage: A table you can store data in.  Limit 64K.

--/////////////////////////////////////////////////////////////////////////////
--////////////////////// BOT_WATSON by esparano ///////////////////////////////
--/////////////////////////////////////////////////////////////////////////////

function bots_watson(params)
    ---------------------------------------------------------
    -------------------------------------------- loop startup
    -- set globals so helper functions will work
    G = params.items ; USER = params.user
    initWatsonLoop()
    -- get storage
    S = params.storage
    if S.init == nil then initWatsonStorage() end

    ---------------------------------------------------------
    ----------------------------------------------- loop body

    ACTION = _ENV[S.state .. "Loop"]();

    --//////////// TESTING ////////////
    --[[
    for _i,home in pairs(_myPlanets) do
        print(incoming(home))
    end
    --]]
    --[[
    for i,f in pairs(_enemyFleets) do
        if G[f.target].owner == USER then
            print(fleetWillCaptureAndHoldTarget(f));
        end
    end
    --]]
    ---------------------------------------------------------
    -------------------------------------------- loop cleanup
    local mem,ins = sb_stats()
    print("Memory used: " .. mem .. " Instructions: " .. ins)
    return ACTION
end

function initWatsonLoop()
    STATES = {
        initialExpansion = "initialExpansion", -- quickly take all good planets, don't get into a fight
        secondaryExpansion = "secondaryExpansion", -- second wave of gradual expansion,
        default = "default", -- middle-game, after all decent nearby neutrals have been taken
        defensive = "defensive", -- save territory snapshot and maintain at all cost
        comboBreaker = "comboBreaker", -- lightly attack largest player
        superComboBreaker = "superComboBreaker", -- full-out attack largest player
        turtle = "turtle", -- land on 1 small planet and stay there for a while
        breakTurtle = "breakTurtle", -- attempt to expand from a turtle
        deescalate = "deescalate", -- bring all ships back home, but defend planets
        retreat = "retreat", -- bring all ships back home, don't defend planets
        float = "float", -- float around without landing
        pounce = "pounce", -- punish overexpansion
        tryWin = "tryWin", -- full-out attack everyone
        swap = "swap", -- detect swap and go for it. save territory snapshot.
        avoidRevolt = "avoidRevolt", -- stop revolt from hitting you
    };
    _realDistance = {}; -- cached each loop             -- TODO:  Only recalculate when memory is getting low
    _allPlanets = all_planets()
    _myPlanets = my_planets()
    _friendlyPlanets = friendly_planets()
    _neutralPlanets = neutral_planets()
    _enemyPlanets = enemy_planets()
    --_otherPlanets = other_planets()
    _allFleets = all_fleets()
    _myFleets = my_fleets()
    _friendlyFleets = my_fleets()
    _enemyFleets = enemy_fleets()
    _myProduction = myProduction()
    _playerCenters = playerCenters() -- maps user.n to user average planet location
    _incoming = _calculateIncoming() -- map of planet.n to net friendly/enemy fleets incoming
    _myTerritory = myTerritory()
    _myTerritoryOrdered = myTerritoryOrdered() -- suitable to use with pairs
    -- estimate time of first capture of planet
end

function initWatsonStorage()
    S.init = true;
    S.state = STATES.initialExpansion; -- unit tested
    S.horizon = calculateHorizon();
    --S.distance = getMapDistances();  -- unit tested
    --S.closestPlanets = getMapClosestPlanets(s);
end

-- ///////////////////////////// Watson state loops /////////////////////////////////////

function initialExpansionLoop()
    S.horizon = calculateHorizon(); -- base horizon off of closest enemy planet

    -- best neutral to attack and from which home
    local bestPlan = nil
    for _j,neutral in pairs(_neutralPlanets) do
        local roi = returnOnNeutral(neutral) -- ships gained before horizon
        if not bestPlan or roi > bestPlan.roi then
            if not territoryContains(neutral) then -- don't send more fleets than necessary
                bestPlan = {neutral=neutral,roi=roi}
            end
        end -- this is a better plan
    end

    -- execute plan
    if bestPlan then
        -- amount of ships bot can afford to over-spend
        local budget = prodToShips(_myProduction) * S.horizon
        --print("best: " .. round(bestPlan.neutral.ships) .. ", " .. bestPlan.roi .. ", " .. budget)
        if bestPlan.roi + budget >= 0 then
            return attackNeutral(bestPlan.neutral)
        else
            print("no more decent neutrals")
            --S.state = STATES.default -- when there are no more decent to take, switch to default FFA state
        end
    end

    return -- no good plan found, return no action
end

function secondaryExpansionLoop()
    print("secondaryExpansionLoop")
    return -- no good plan found, return no action
end

function defaultLoop()
    print("default")
    return
end


--[[
    local goodNeutrals = {}
    for _i,home in pairs(_myPlanets) do
        for _j,neutral in pairs(_neutralPlanets) do
            local returns = returnOnNeutral(home, neutral)
            local roi = returns/(neutral.ships + 1) -- ships gained before horizon divided by ships required
            goodNeutrals[#goodNeutrals+1] = {n=neutral.n,roi=roi}
        end
    end
    goodNeutrals = sort(goodNeutrals, function(data1, data2) return data1.roi > data2.roi end)
]]

-- ///////////////////////////// Watson utility functions ///////////////////////////////

-- come up with a combination of fleets to attack the neutral
function attackNeutral(neutral)
    --[[
        local myClosestPlanets = sort(_myPlanets, function (x1,x2)
            return realDistance(x1,neutral) < realDistance(x2, neutral)
        end)
        return send(10,myClosestPlanets[1],neutral)
    --]]
    --
    local totalLeft = netShips(neutral) -- fleets already on their way discount cost
    if totalLeft >= 0 then
        -- get closest owned planets to the neutral
        local myClosestPlanets = sort(_myPlanets, function (x1,x2)
            return realDistance(x1,neutral) < realDistance(x2, neutral)
        end)

        local from = nil
        local percent
        local timeElapsed = 0
        local attackingProd = 0
        -- radiating circle outwards starting from neutral planet
        for i,p in pairs(myClosestPlanets) do
            local pUnreserved = netShips(p)
            -- this planet will send in the future. remove it from the amount to send
            if pUnreserved > 0 then
                from = p
                local newTimeElapsed = distToTime(realDistance(p,neutral))
                local diff = newTimeElapsed - timeElapsed
                if newTimeElapsed < timeElapsed then print("NOT SORTED PROPERLY WTF") end
                -- the previous planets will be able to produce enough before this one's ships get there
                if totalLeft - diff*prodToShips(attackingProd) < 0 then
                    -- TODO: DO SOMETHING USEFUL INSTEAD OF NOTHING
                    print("IDK")
                    break
                end
                timeElapsed = newTimeElapsed
                totalLeft = totalLeft - diff*prodToShips(attackingProd) -- production from all CLOSER planets
                if p.ships > totalLeft then -- there are enough stored ships in this planet to capture
                    percent = percentToUse(p, totalLeft)
                    break
                elseif pUnreserved > totalLeft then -- there WILL BE enough stored ships in this planet to capture, so do something else
                    print("IDK2")
                    break
                else
                    totalLeft = totalLeft - pUnreserved
                end
                attackingProd = attackingProd + p.production
            end

        end
        -- now that an action has been found, perform it
        if from then
            if not percent then percent = 100 end
            local tunnelPlanet = tunnelAlias(from, neutral) -- send through tunnel
            return send(percent,from,tunnelPlanet)
        else
            print("NO PLANET FOUND TO ATTACK WITH")
            return
        end
    else
        print("NEUTRAL IS ALREADY GOING TO BE CAPTURED WTF")
        return
    end
    --]]
end

-- if you want to tunnel from "from" to "to", send from "from" to this planet instead
function tunnelAlias(from, to)
    local alias = to
    local fullDist = realDistance(from,to)
    local bestDist = fullDist
    for i,p in pairs(_myTerritory) do -- you can also tunnel through planets about to be captured
        if p.n ~= from.n then -- can't tunel through itself
            -- if it's closer than the current tunnel alias
            local dist = realDistance(from,p)
            if dist < bestDist then
                -- if it would be a good tunnel
                local otherDist = realDistance(p, to)
                if dist + otherDist < fullDist then
                    bestDist = dist
                    alias = p
                end
            end
        end
    end
    return alias
end

-- return array of planet.n to my planets (and planets that will be captured by fleets)
function myTerritory()
    local territory = {}
    -- add all currently owned planets
    for i,p in pairs(_myPlanets) do territory[p.n] = p end
    -- add all planets that my fleets will capture
    for i,f in pairs(_myFleets) do
        local target = G[f.target]
        if not sameTeam(f, target) and fleetWillCaptureAndHoldTarget(f) then
            territory[target.n] = target
        elseif netShips(target) < 0 then
            territory[target.n] = target -- planet will be captured... idk exactly how this metric differs
        end
    end
    return territory
end


-- return array of planet.n to my planets (and planets that will be captured by fleets)
function myTerritoryOrdered()
    local territory = {}
    -- add all currently owned planets
    for i,p in pairs(_myPlanets) do territory[#territory + 1] = p end
    -- add all planets that my fleets will capture
    for i,f in pairs(_myFleets) do
        local target = G[f.target]
        if not sameTeam(f, target) and fleetWillCaptureAndHoldTarget(f) then
            territory[#territory + 1] = target
        elseif netShips(target) < 0 then
            territory[#territory + 1] = target -- planet will be captured... idk exactly how this metric differs
        end
    end
    return territory
end

function territoryContains(planet)
    return _myTerritory[planet.n] ~= nil
end

function sameTeam(o1, o2)
    return o1.team == o2.team
end

-- will this fleet be able to capture the planet?
-- TODO: make it depend on enemy incoming fleet timing
-- note: doesn't make sense for fleet supporting own planet.
-- unit tested
function fleetWillCaptureAndHoldTarget(fleet)
    local target = G[fleet.target]
    return fleet.ships >= futureShips(target, distToTime(realDistance(fleet, target)))
end

-- map of planet.n to net friendly/enemy fleets incoming
-- unit tested
function _calculateIncoming()
    inc = {}
    for i,f in pairs(_allFleets) do
        local target = G[f.target]
        local change;
        if sameTeam(f, target) then change = f.ships else change = -f.ships end
        if not inc[target.n] then inc[target.n] = 0 end
        inc[target.n] = inc[target.n] + change
    end
    return inc
end

-- how many fleets incoming to this planet? positive means net friendly support, negative means net enemy attack
-- unit tested
function incoming(planet)
    if not _incoming[planet.n] then _incoming[planet.n] = 0 end
    return _incoming[planet.n]
end

-- how many ships after all fleets have landed
function netShips(planet)
    return planet.ships + incoming(planet)
end

-- what percent the planet should send at to send at least this number of ships
-- increments of 5%, max 100%.
function percentToUse(planet, ships)
    if planet.ships == 0 then return 100 end
    return max(5,min(100,ceil((ships + 1)/ planet.ships * 100 / 5) * 5))
end

-- number of ships that would be gained by sending a fleet from "from" to "to" before horizon seconds
-- including production after capture and subtracting
-- "from" may be a fleet so this can be used for redirecting
-- only used for neutral planets
function returnOnNeutral(to)
    local timeDist = distToTime(distance(to, _playerCenters[USER]))
    if S.horizon < timeDist then return -1000000 end -- won't produce enough ships by the time they are potentially needed
    return producedNonNeutral(to, S.horizon - timeDist) - to.ships; -- cost to capture plus ship production before S.horizon
end

-- subtracting planet radii if item1 and item2 are planets
function realDistance(item1, item2)
    local index = item1.n .. "-" .. item2.n
    if not _realDistance[index] then
        local dist = distance(item1, item2)
        if item1.is_planet then dist = dist - item1.r end
        if item2.is_planet then dist = dist - item2.r end
        _realDistance[index] = dist
    end
    return _realDistance[index]
end

-- the distance from my center of mass to the nearest enemy's center of mass
function calculateHorizon()
    local horizonDist = 1000000
    for user,center in pairs(_playerCenters) do
        if user ~= USER then
            local dist = realDistance(_playerCenters[USER],center)
            if dist < horizonDist then horizonDist = dist end
        end
    end
    return distToTime(horizonDist)
end

-- bot's total production
function myProduction()
    local total = 0
    for _i,p in pairs(_myPlanets) do
        total = total + p.production
    end
    return total
end

-- bot's total production
function playerCenters()
    local centers = {}
    local function count(p)
        local userN = p.owner
        if not centers[userN] then centers[userN] = {x=0,y=0,n=0} end
        centers[userN].x = centers[userN].x + p.x
        centers[userN].y = centers[userN].y + p.y
        centers[userN].n = centers[userN].n + 1
    end
    for i,p in pairs(_myPlanets) do
        count(p)
    end
    for i,p in pairs(_enemyPlanets) do
        count(p)
    end

    for i,c in pairs(centers) do
        c.x = c.x / c.n
        c.y = c.y / c.n
    end
    return centers
end

-- Return the number of ships "planet" will have "time" seconds from now
function futureShips(planet, time)
    return planet.ships + produced(planet, time)
end

-- return the number of ships produced by planet after a time
function produced(planet, time)
    if not planet.neutral then
        return prodToShips(planet.production) * time
    end
    return 0
end

-- doesn't care whether planet is neutral or not
function producedNonNeutral(planet, time)
    return prodToShips(planet.production) * time
end

-- convert distance to time (assumes constant ship movement speed)
function distToTime(dist)
	return dist/40
end

-- convert time to distance (assumes constant ship movement speed)
function timeToDist(time)
	return time*40
end

-- convert planet production to ships per second
function prodToShips(prod)
    return prod / 50
end

-- convert ships per second to planet production
function shipsToProd(ships)
    return ships * 50
end

--[[
-- return table containing precomputed g2.distances. distance[p1.n][p2.n] is equivalent to g2.distance(p1,p2)
function getMapDistances()
    local distances = {}
    local planets = all_planets()
    for _i, p in pairs(planets) do
        distances[p.n] = distances[p.n] or {}
        for _j, p2 in pairs(planets) do
            distances[p.n][p2.n] = distance(p, p2) - p.planet_r/2 - p2.planet_r/2
        end
    end
    return distances
end
]]
--[[
function getMapClosestPlanets(s)
    local cp = {}
    for _i, p in pairs(s.planetNs) do
        local planets2 = copy(s.planetNs)
        cp[p] = shellsort(planets2, function (x1,x2) return s.distance[p][x1] < s.distance[p][x2] end)
    end
    return cp
end
--]]

--/////////////////////////////////////////////////////////////////////////////
--////////////////////// end BOT_WATSON by esparano ///////////////////////////
--/////////////////////////////////////////////////////////////////////////////

function bots_simple(params)
    -- set globals so helper functions will work
    G = params.items ; USER = params.user
    -- if unset, set best default options
    local opts = params.options or {percent = 65}

    -- target all other planets
    local targets = other_planets()
    -- if we control over 65% of the ships only target enemy planets
    if my_strength() > 0.65 then targets = enemy_planets() end

    -- find our planet with the most ships on it
    local from = find(my_planets(),function (o) if o.ships >= 15 then return o.ships end end)
    if from then
        -- find the best target for these ships
        local to = find(targets,function (o) return 1.0*o.production + -1.0*o.ships + -0.2*distance(from,o) end)
        -- return the attack order
        if to then return send(opts.percent,from,to) end
    end

    -- redirect a fleet
    local fleets = my_fleets() ; shuffle(fleets)
    for _,from in pairs(fleets) do
        -- quit if we're running low on resources
        if sb_warn() then return end
        -- find the best target for this fleet
        local to = find(targets,function (o) return 1.0*o.production + -1.0*o.ships + -0.2*distance(from,o) end)
        -- return the redirect order
        if to and to.n ~= from.target then return redirect(from,to) end
    end

    -- if we made it this far, then we've got nothing to do
    return
end

----------------------------------------------------------------------------
-- UTILITY FUNCTIONS -------------------------------------------------------
-- functions that you use must be included as part of your bot -------------
----------------------------------------------------------------------------

-- check for resource overuse
function sb_warn()
    local mem,ins = sb_stats()
    -- print('mem:'..mem..' ins:'..ins)
    return mem > 60 or ins > 60
end

-- calculate your ship-based strength
function my_strength()
    local ships = 0 ; local total = 0
    for _,o in pairs(G) do
        if o.ships then
            if o.owner == USER then ships = ships + o.ships end
            if not o.neutral then total = total + o.ships end
        end
    end
    return ships / max(1,total)
end

-- search G for all matches
function search(eval) local r = {} for _,o in pairs(G) do if eval(o) then r[#r+1] = o end end return r end

-- return lists of matching planets
function all_planets() return search(function (o) return o.is_planet end) end
function my_planets() return search(function (o) return o.is_planet and o.owner == USER end) end
function friendly_planets() return search(function (o) return o.is_planet and o.team == G[USER].team end) end
function neutral_planets() return search(function (o) return o.is_planet and o.neutral == true end) end
function enemy_planets() return search(function (o) return o.is_planet and o.owner ~= USER and not o.neutral end) end
function other_planets() return search(function (o) return o.is_planet and o.owner ~= USER end) end

-- return list of matching fleets
function all_fleets() return search(function (o) return o.is_fleet end) end
function my_fleets() return search(function (o) return o.is_fleet and o.owner == USER end) end
function friendly_fleets() return search(function (o) return o.is_fleet and o.team == G[USER].team end) end
function enemy_fleets() return search(function (o) return o.is_fleet and o.owner ~= USER end) end

-- issue a single redirect order
function redirect(from,to)
    return { {action='redirect',from=from.n,to=to.n} }
end
-- issue a single send order
function send(percent,from,to)
    return { {action='send',percent=percent,from=from.n,to=to.n} }
end

-- search list for the best match
function find(Q,eval)
    local r, v
    for _,o in pairs(Q) do
        _v = eval(o)
        if _v ~= nil and (r == nil or _v > v) then
            r = o ; v = _v
        end
    end
    return r
end

-- calculate simple distance between two items
function distance(a,b)
    local dx = b.x-a.x ; local dy = b.y-a.y ;
    return sqrt(dx*dx+dy*dy)
end

-- INCLUDE THIS
function round(num)
  return floor(num + 0.5)
end


-- do nothing
function pass() end

-- shuffle a list
function shuffle(t)
    local l = #t
    for i=1,l do
        local n = random(i,l)
        t[i],t[n] = t[n],t[i]
    end
end

-- copy an item
function copy(o)
    if type(o) ~= 'table' then return o end
    local r = {}
    for k,v in pairs(o) do r[k] = copy(v) end
    return r
end

function merge(a,b,f)
    local t,i,j={},1,1
    for _=1,#a+#b do
        if not b[j] or a[i] and (f and f(a[i],b[j]) or ((not f) and a[i]<b[j])) then
            t[#t+1],i=a[i],i+1
        else
            t[#t+1],j=b[j],j+1
        end
    end
    return t
end
function sort(t,f)if #t<=1 then return t end
    local n,a,b=(#t-#t%2)/2,{},{}
    for i=1,n do a[i],b[i]=t[i],t[i+n]end
    b[n+1]=t[n*2+1]
    return merge(sort(a,f),sort(b,f),f)
end

----------------------------------------------------------------------------
-- YOU DON'T NEED TO COPY ANYTHING AFTER THIS AS PART OF YOUR BOT SCRIPT ---
----------------------------------------------------------------------------
-- EXAMPLE BOTS THAT CRASH -------------------------------------------------
----------------------------------------------------------------------------

function bots_crash() fail() end
function bots_ticks() while true do end end
function bots_memory() local t = 't' while true do t = t .. t end end

----------------------------------------------------------------------------
end
----------------------------------------------------------------------------
-- REGISTER BOTS -----------------------------------------------------------
----------------------------------------------------------------------------
global("BOTS") ; BOTS = {}

-- "bots_register" - Register your bot using this function

-- NAME: The display name of your bot
-- LOOP: the loop function name for your bot
-- OPTIONS: optional parameters for your bot, do not use for globals.
function bots_register(name,loop,options)
    BOTS[name] = {name=name,loop=loop,ok=true,options=options}
end

-- Put your own bots here. You can have multiple versions of your
-- same bot by changing the options for each version.

-- version uses defaults
--bots_register("simple","bots_simple")
bots_register("watson","bots_watson")

-- these bots crashes in code, and will get eliminated, feel free to remove
--bots_register("x_crash","bots_crash")
--bots_register("x_ticks","bots_ticks")
--bots_register("x_memory","bots_memory")

----------------------------------------------------------------------------
-- Below this is the code for running the bot war
-- You may want to tweak some of the GAME
-- settings below to ensure your bot works well on larger maps.
----------------------------------------------------------------------------
-- MOD ---------------------------------------------------------------------
----------------------------------------------------------------------------

function init()
    COLORS = { 0x555555,
        0xff0000,0x0000ff,0xffff00,0x00ffff,
        0xbb00ff,0x00ff00,0xff8800,0x9999ff,
        0x99ff99,0xff88ff,0xff9999, -- 0xffffff reserved for live player
    }
    GAME = {
        t = 0.0,
        ships = 100,
        sw = 480, sh = 320, planets = 24, production = 100, -- small map
        -- sw = 840, sh = 560, planets = 48, production = 125, -- standard map
        -- sw = 977, sh = 652, planets = 65, production = 125, -- large map
        wins = {},
        total = 0,
        timeout = 300.0,
        players = 4, -- max number of players in a round
        speed = 15, -- more time per loop, 15 max (1/4 second)
        ticks = 4, -- more loops per frame
        live = false,
    }

    math.randomseed(os.time()) -- don't reset the seed each game, it makes the game unfair
    reset(false)
end

function reset(live)
    GAME.live = live
    GAME.total = 0
    GAME.wins = {}
    next_game()
end

function next_game()
    g2.game_reset()

    GAME.t = 0

    local u0 = g2.new_user("neutral",COLORS[1])
    GAME.u_neutral = u0
    u0.user_neutral = true
    u0.ships_production_enabled = 0

    GAME.users = {}
    local _bots = {}
    for _,b in pairs(BOTS) do if b.ok then _bots[#_bots+1] = b end end
    table.sort(_bots,function(a,b) return a.name < b.name end)
    shuffle(_bots)

    local total = 0
    for n=1,GAME.players do
        local bot = _bots[n]
        if bot then
            bot.storage = {}
            bot.t = math.random()
            bot.delay = 0.25
            local user = g2.new_user(bot.name,COLORS[1+n])
            GAME.users[bot.name] = user
            total = total + 1
        end
    end

    local pad = 0
    local sw = GAME.sw
    local sh = GAME.sh

    local o1 = g2.new_user("player",0xffffff)
    o1.ui_ships_show_mask = 0xf
    g2.player = o1
    if GAME.live then
        GAME.users['player'] = o1
        total = total + 1
    end

    local n = GAME.planets - total
    for i=1,n do
        g2.new_planet( u0, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end

    local a = math.random(0,360)
    local x,y
    local users = {}
    for name,user in pairs(GAME.users) do
        users[#users+1] = user
    end
    shuffle(users)

    for _,user in ipairs(users) do
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(user, x,y, GAME.production, GAME.ships);
        a = a+360/total
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

    if GAME.t < 0.5 then return end -- give human a chance

    local users = {}
    for name,user in pairs(GAME.users) do
        if name ~= 'player' then
            local info = BOTS[name]
            users[#users+1] = {name = name, user = user, info = info}
        end
    end
    shuffle(users)

    local data = nil
    for _,bot in pairs(users) do
        if bot.info.ok then -- about 4x per second
            local pt = bot.info.t
            bot.info.t = bot.info.t + t
            if math.floor(bot.info.t/bot.info.delay) ~= math.floor(pt/bot.info.delay) then
                local data = data or _bots_data()
                local ok,msg = pcall(function () _bots_run(data,bot.info.loop, bot.user.n,bot.info.options,bot.info.storage) end)

                if not ok then
                    print(msg)
                    bot.info.ok = false
                    local user = bot.user
                    local neutral = GAME.u_neutral
                    for n,e in pairs(g2.search("planet owner:"..user)) do
                        e:planet_chown(neutral)
                    end
                    for n,e in pairs(g2.search("fleet owner:"..user)) do
                        e:destroy()
                    end
                end
            end
        end
    end

    local win = nil;
    local planets = g2.search("planet -neutral")
    for _i,p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then win = user end
        if (win ~= user) then return nil end
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
    for _,o in ipairs(r) do
        local _type = nil
        if o.has_user then res[o.n] = {
            n = o.n, is_user = true,
            team = o.user_team_n,
            neutral = o.user_neutral,
            }
        elseif o.has_planet then local u = o:owner() ; res[o.n] = {
            n = o.n, is_planet = true,
            x = o.position_x, y = o.position_y, r = o.planet_r,
            ships = o.ships_value, production = o.ships_production,
            owner = o.owner_n, team = u.user_team_n, neutral = u.user_neutral,
            }
        elseif o.has_fleet then local u = o:owner() ;
            local sync_id = tostring(o.sync_id) ; res[sync_id] = {
            _n = o.n, n = sync_id, is_fleet = true,
            x = o.position_x, y = o.position_y, r = o.fleet_r,
            ships = o.fleet_ships,
            owner = o.owner_n, team = u.user_team_n,
            target = o.fleet_target,
            }
        end
    end
    return res
end

-- function _bots_sandbox()
--     return {
--     type = type,
--     ipairs = ipairs,
--     pairs = pairs,
--     print = print, -- in game this will be function () end
--     string = { sub = string.sub, },
--     table = { sort = table.sort, insert = table.insert, remove = table.remove, },
--     math = { abs = math.abs, ceil = math.ceil, floor = math.floor, math.huge,
--         max = math.max, min = math.min, random = math.random,
--         pi = math.pi, cos = math.cos, sin = math.sin, atan2 = math.atan2,
--         log = math.log, pow = math.pow, sqrt = math.sqrt, exp = math.exp,
--         },
-- } end


function memory_estimate(r) -- rough estimate of memory usage, inf on error
    local _used = {}
    local function _calc(r)
        local _type = type(r)
        if _type == 'number' then return 16 end -- 9999
        if _type == 'string' then return 16 + #r end -- "abc"
        if _type == 'boolean' then return 16 end -- true
        if _type == 'table' then
            if _used[r] then return math.huge end -- error on loops
            _used[r] = true
            local t = 16 ; -- {}
            local n = 0
            for k,v in pairs(r) do
                t = t + _calc(k) + _calc(v) -- k:v,
                n = n + 1
            end
            if #r == n then t = t - n * 16 end -- v,
            return t
        end
        return math.huge -- error on other types
    end
    return _calc(r)
end


function _bots_sandbox()
    return {
    sb_stats = g2_sandbox_stats,
    type = type, pairs = pairs, print = print, strsub = string.sub,
    abs = math.abs, ceil = math.ceil, floor = math.floor,
    max = math.max, min = math.min, HUGE = math.huge, random = math.random,
    PI = math.pi, cos = math.cos, sin = math.sin, atan2 = math.atan2,
    log = math.log, pow = math.pow, sqrt = math.sqrt, exp = math.exp,
} end


function _bots_run(_data,loop,uid,_options,storage)
    -- reset environment
    local env = _bots_sandbox()
    local res = nil
    local data = copy(_data)
    local options = copy(_options)

    local ok,msg = g2_sandbox(function ()
        _sandbox_init(env)
        res = env[loop]({items=data,user=uid,options=options,storage=storage})
        end,64,64)
    if not ok then
        error('['..loop..']: '..msg)
        return
    end
    if memory_estimate(storage) > 65536 then
        error('['..loop..']: storage limit exceeded')
        return
    end
    if not res then return end
    local data = _data
    local to = nil ; local percent = nil
    for _,a in ipairs(res) do
        -- filter inhuman actions: you can only target one planet per move
        if a.action == 'send' or a.action == 'redirect' then
            if to == nil then to = a.to end
            if a.to ~= to then a.action = 'none' end
        end
        -- normalize percent: you can only use one percent at 5% increments
        if a.action == 'send' then
            if percent == nil then percent = math.max(5,math.min(100,round(a.percent / 5) * 5)) end
            a.percent = percent
        end

        if a.action == 'send' then
            if data[a.from].is_planet and data[a.from].owner == uid and data[a.to].is_planet then
                g2_fleet_send(a.percent,a.from,a.to)
            end
        end
        if a.action == 'redirect' then
            if data[a.from].is_fleet and data[a.from].owner == uid and data[a.to].is_planet and data[a.from].target ~= a.to then
                g2_fleet_redirect(data[a.from]._n,a.to)
            end
        end
    end
end

function update_stats()
    local stats = {}
    for name,total in pairs(GAME.wins) do
        stats[#stats+1] = {name,total}
    end
    table.sort(stats,function(a,b) return a[2] > b[2] end)
    local info = ""
    for i,item in ipairs(stats) do
        info = info .. item[1] .. ":" .. tostring(item[2]) .. "  "
    end
    local function gprint(msg)
        print("["..tostring(GAME.total).."] "..msg)
    end
    gprint(info)
end

function event(e)
    if (e["type"] == "pause") then
        g2.html = [[
        <table>
        <tr><td><input type='button' value='Play' onclick='play' />
        <tr><td><input type='button' value='Resume' onclick='resume' />
        <tr><td><input type='button' value='Reset' onclick='reset' />
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

function pass() end

function shuffle(t)
    for i,v in ipairs(t) do
        local n = math.random(i,#t)
        t[i] = t[n]
        t[n] = v
    end
end

function copy(o)
    if type(o) ~= 'table' then return o end
    local r = {}
    for k,v in pairs(o) do r[k] = copy(v) end
    return r
end

function round(num)
  return math.floor(num + 0.5)
end



----------------------------------------------------------------------------
-- LICENSE -----------------------------------------------------------------
----------------------------------------------------------------------------

LICENSE = [[
mod_botwar.lua

Copyright (c) 2013 Phil Hassey
Modifed by: esparano

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]


