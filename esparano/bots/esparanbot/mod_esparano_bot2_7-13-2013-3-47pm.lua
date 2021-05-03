LICENSE = [[
Copyright (c) 2013 Phil Hassey
Modifed by: [YOUR NAME HERE]
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]

function init()
    
    -- set up global data here
    
    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
        
    OPTS = {
        seed = 0,
        t = 0.0,
        rank = 1,
        sw = 640,
        sh = 480,
        -- default game settings
        neutrals = 23,
        homes = 1,
        size = 100,
        bots = 1,
        ships = 100,
        -- default bot settings
        wait = 0.3, -- time in between bot loop calls
    }
    
    OPTS.seed = os.time()
    init_menu()
    g2.state = "menu"
end

-- BOT CODE {{{ //////////////////////////////////

-- stats: 60-1 against Classic bot

-- initialize anything needed for the bot to run
function init_bot_sample()
    BOT = {}
    BOT.moves = {}
    
    -- how far in the future the bot will predict moves for
    BOT.horizon = 10
    
    if BOT.user_neutral == nil then
        local users = g2.search("user")
        for _i,u in ipairs(users) do
            if u.user_neutral == 1 then BOT.user_neutral = u end
        end
    end   
    
    -- calculate an array of all planets and their distances from each other planet
    -- an array holding "planet" objects
    -- each planet object has a reference to the corresponding planet and a list of other planets sorted by distance from it
    BOT.planets = {}
    local planets = g2.search("planet")
    for i,planet in ipairs(planets) do
        local cp = {}
        for j,planet2 in ipairs(planets) do
            if j ~= i then
                table.insert(cp, {planet=planet2,dist = planet:distance(planet2)})
            end
        end
        BOT.planets[planet.n] = {planet = planet,closest_planets = cp}
        -- sort planets in the other_planets array
        table.sort(BOT.planets[planet.n].closest_planets, function(p1,p2) if p1 ~= nil and p2 ~= nil then if p1.dist < p2.dist then return true end end end)
    end
    
    BOT.target_planets = {}
end

-- bot loop called every turn
function bot_sample(user)
    if BOT.first_turn == nil then
        BOT.first_turn = false
        find_enemy(user)
        -- on the first turn, expand to any neutrals that are worth it.  Then start attacking.
        -- identify homes
        local user_planets = g2.search("planet owner:"..user)
        if #user_planets == 1 then
            BOT.home = user_planets[1] 
        else
            BOT.home = user_planets[1] 
            print("More than one bot home detected.")
        end
        local enemy_planets = g2.search("planet owner:"..BOT.enemy)
        if #enemy_planets == 1 then
            BOT.enemy_home = enemy_planets[1] 
        else
            BOT.enemy_home = enemy_planets[1] 
            print("More than one enemy home detected.")
        end
        BOT.horizon = distance_to_time(BOT.home:distance(BOT.enemy_home))
        
        -- initial expansion    
        for i,planet_data in pairs(BOT.planets) do
            local planet = planet_data.planet
            if planet:owner() == BOT.user_neutral then
                if distance_to_time(planet:distance(BOT.home))*1.5 < distance_to_time(planet:distance(BOT.enemy_home)) then
                    -- take ALL decent planets that are very close to the bot
                    if is_worth_capturing_initially(planet, BOT.horizon*1.5, BOT.home) then
                        send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                        table.insert(BOT.target_planets, planet_data)
                    end
                elseif distance_to_time(planet:distance(BOT.home)) < distance_to_time(planet:distance(BOT.enemy_home)) then
                    -- take ALL very good planets that are closer to the bot than the enemy
                    if is_worth_capturing_initially(planet, BOT.horizon*1.1, BOT.home) then
                        send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                        table.insert(BOT.target_planets, planet_data)
                    end
                elseif distance_to_time(planet:distance(BOT.home)) < distance_to_time(planet:distance(BOT.enemy_home))*1.5 then
                    -- take ALL very good planets that are closer to the enemy than the bot
                    if is_worth_capturing_initially(planet, BOT.horizon, BOT.home) then
                        send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                        table.insert(BOT.target_planets, planet_data)
                    end
                elseif is_worth_capturing_ever(planet, BOT.horizon, BOT.home) then
                    send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                    table.insert(BOT.target_planets, planet_data)
                end
            end
        end
    end
    
    -- calculate which planets should be fought over
    for i,planet_data in pairs(BOT.planets) do
        local planet = planet_data.planet
        if planet:owner() == user then
            -- reset unallocated_ships
            planet_data.unallocated_ships = planet.ships_value
            -- if the planet is not already in BOT.target_planets, add it
            local is_already_in_array = false
            for _i,source in pairs(BOT.target_planets) do
                if source.planet == planet then is_already_in_array = true break end
            end
            if is_already_in_array == false then
                table.insert(BOT.target_planets, planet_data)
            end
        else
            planet_data.unallocated_ships = 0
        end
    end
    
    -- calculate the "front" planets
    for _i,source in pairs(BOT.target_planets) do
        -- find closest enemy planet to "source"
        local closest_enemy
        for _j,planet_data in pairs(source.closest_planets) do
            if planet_data.planet:owner() == BOT.enemy then closest_enemy = get_planet_data(planet_data.planet) break end
        end
        if closest_enemy ~= nil then
            -- find closest target planet to "closest_enemy"
            local target
            for _j,planet_data2 in pairs(closest_enemy.closest_planets) do
                for _m,planet in pairs(BOT.target_planets) do
                    if planet.planet == planet_data2.planet then    
                        -- needed to correctly calculate "front" planets
                        if source.planet:distance(planet_data2.planet) < source.planet:distance(closest_enemy.planet) then
                            target = get_planet_data(planet_data2.planet) 
                            break 
                        end
                    end
                end
                if target ~= nil then break end
            end
            -- the source planet is a front planet
            if source.planet == target.planet then
                source.front = true
            elseif source.planet:owner() == user then
                source.front = false
                -- try to find a closer planet to tunnel through
                for _j,planet_data2 in pairs(source.closest_planets) do
                    if planet_data2.planet:owner() == user then
                        local d1 = source.planet:distance(planet_data2.planet)
                        local d2 = planet_data2.planet:distance(target.planet)
                        local d3 = source.planet:distance(target.planet)
                        if d2 < d3 and d1 < d3 and (d1 + d2)/1.25 < d3 then 
                            target = get_planet_data(planet_data2.planet) 
                            break  
                        end
                    end
                end
                source.target = target
            else
                source.front = nil
                source.target = nil
            end
        end    
    end   
    
    local b_s = count_ships(user)
    local b_p = count_production(user)
    local e_s = count_ships(BOT.enemy)
    local e_p = count_production(BOT.enemy)
    
    -- if the enemy has more ships, 
    if e_s > b_s then
        -- if the enemy has more production, go into "attack" mode
        if e_p > b_p then
            BOT.state = "attack"
        -- if the enemy has less production, go into "defend" mode
        else
            BOT.state = "defend"
        end
    -- if the bot has more ships
    else
        -- if the enemy has more production, go into "expand" mode
        if e_p > b_p then
            BOT.state = "expand"
        -- if the enemy has less production, go into "finish" mode
        else
            BOT.state = "finish"
        end
    end
    
    -- stop attacking/supporting on planets that are being attacked
    local fleets = g2.search("fleet")
    for i,fleet in ipairs(fleets) do
        if fleet:owner() == BOT.enemy then
            local target = BOT.planets[fleet.fleet_target]
            if target.planet:owner() == user then
                target.unallocated_ships = target.unallocated_ships - fleet.fleet_ships
            end
        elseif fleet:owner() == user then
            local target = BOT.planets[fleet.fleet_target]
            if target.planet:owner() == user then
                target.unallocated_ships = target.unallocated_ships + fleet.fleet_ships/4 -- take advantage of capture delay bug
            end
        end
    end
    
    for i,source in pairs(BOT.target_planets) do
        -- shuttle remaining ships to front planets
        if source.front == false then
            send_exact(user, source.planet, source.target.planet, source.unallocated_ships)
            source.unallocated_ships = 0
        else
            local closest_enemy
            for _j,planet_data in pairs(source.closest_planets) do
                if planet_data.planet:owner() == BOT.enemy then closest_enemy = get_planet_data(planet_data.planet) break end
            end
            if closest_enemy ~= nil then
                send_exact(user, source.planet, closest_enemy.planet, source.unallocated_ships)
                source.unallocated_ships = 0
            end
        end
    end
end

-- The number of ships a planet will have after a time interval
function future_ships(planet, time)
	return planet.ships_value + time * planet.ships_production * planet.ships_production_enabled / 50.0
end

-- get the data associated with this planet
function get_planet_data(planet)
    return BOT.planets[planet.n]
end

-- returns the angle formed by three planets (picture two vectors from middle->first and middle->last)
function angle_between(first, middle, last)
	local angle1 = math.atan2(first.position_y - middle.position_y, first.position_x - middle.position_x)
	local angle2 = math.atan2(last.position_y - middle.position_y, last.position_x - middle.position_x)
	local angle = math.abs(angle2 - angle1)
	if angle > math.pi then angle = 2*math.pi - angle end
	return angle
end

function amount_to_send(to, from)
    -- account for rounding errors and intervening neutrals
    return future_ships(to, distance_to_time(to:distance(from))) + 1.5 + 4*to.ships_production/50*to.ships_production_enabled*to:distance(from)/OPTS.sw 
end

-- get the enemy user (only works in 1v1 scenario)
function find_enemy(user)
    if BOT.enemy == nil then
        local users = g2.search("user")
        for _i,u in ipairs(users) do
            if u.user_neutral == 0 and u ~= user then BOT.enemy = u end
        end
    end
end

-- The number of ships a neutral will have after a time interval (and after it's captured)
function is_worth_capturing_initially(neutral, time, home)
	return (((-neutral.ships_value + (time - distance_to_time(neutral:distance(home)))* neutral.ships_production / 50.0))/(neutral.ships_value+0.1) > 0.3
        and neutral.ships_production/(neutral.ships_value+0.1) > 3) or (neutral.ships_production/(neutral.ships_value+0.1) > 6 and neutral.ships_value < 20)
end

function is_worth_capturing_ever(neutral)
    return (neutral.ships_production/neutral.ships_value > 6 and neutral.ships_value < 6)
end

-- "Time-distance" for a length distance
function distance_to_time(distance)
	return distance/40
end

function send_exact(user, from, to, ships)
	if from.ships_value < ships then
		from:fleet_send(100, to)
	end
	local perc = ships / from.ships_value * 100
	if perc > 100 then perc = 100 end
	from:fleet_send(perc, to)
end

function count_production(user)
    local total = 0
    for i,planet_data in pairs(BOT.planets) do
        local planet = planet_data.planet
        if planet:owner() == user then
            total = total + planet.ships_production
        end
    end
    return total        
end

function count_ships(user)
    local total = 0
    local item = g2.search("planet or fleet")
    for i,item in ipairs(item) do
        if item:owner() == user then
            if item.has_planet == 1 then
                total = total + item.ships_value
            else
                total = total + item.fleet_ships
            end
        end
    end
    return total      
end

-- }}} END BOT CODE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


-- GAME CODE {{{ ----------------------------

function init_game()
    g2.game_reset()
    OPTS.t = 0
    math.randomseed(OPTS.seed)
   
    local user_neutral = g2.new_user("neutral",COLORS[1])
    user_neutral.user_neutral = 1
    user_neutral.ships_production_enabled = 0
   
    local player = g2.new_user("player", COLORS[2])
    player.ui_ships_show_mask = 0xf
    g2.player = player
    
    local bots = {}
    for i=1,OPTS.bots do
        local enemy = g2.new_user("enemy", COLORS[2+i])
        bots[i] = enemy
    end
    
    local pad = 50;
    local sw = OPTS.sw*OPTS.size / 100;
    local sh = OPTS.sh*OPTS.size / 100;

    local a = math.random(0,360)
    
    local users = 1.0 + OPTS.bots
    
    for i=1,OPTS.homes do
        local x,y
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(player, x,y, 100, 100);
        for j=1,OPTS.bots do
            o2 = bots[j]
            a = a+360/(users)
            x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
            y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
            g2.new_planet(o2, x,y, 100, OPTS.ships);
        end
        a = a + 360/(users)
        a = a + 360/(OPTS.homes*users)
        
    end
    
    for i=1,OPTS.neutrals/2 do
        local x = sw/2 + math.random(-(sw + pad)/2,(sw + pad)/2)
        local y = sh/2 + math.random(-(sh + pad)/2,(sh + pad)/2)
        local prod = math.random(15,100)
        local cost = math.random(0,50)
        g2.new_planet(user_neutral, x, y, prod, cost);
        g2.new_planet(user_neutral, sw - x, sh - y, prod, cost);
    end

    g2.planets_settle()
    init_bot_sample()
end

function loop(t)
    OPTS.t = OPTS.t + t
    if (OPTS.t >= OPTS.wait) then
        OPTS.t = OPTS.t - OPTS.wait
        local users = g2.search("user")
        for _i,user in ipairs(users) do
            if (user.title_value == "enemy") then
                bot_sample(user)
            end
        end
    end
    
    local win = nil;
    local planets = g2.search("planet -neutral")
    for _i,p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then win = user end
        if (win ~= user) then return end
    end
    
    if (win ~= nil) then
        if (win.has_player == 1) then
            init_win()
            g2.state = "pause"
            return
        else
            init_lose()
            g2.state = "pause"
            return
        end
    end
end

function event(e)
    if (e["type"] == "onclick" and string.find(e["value"],"init") ~= nil) then
        OPTS.homes = fix(g2.form.homes,1,1,100)
        OPTS.neutrals = fix(g2.form.neutrals,23,0,100)
        OPTS.size = fix(g2.form.size,100,100,1000)
        OPTS.bots = fix(g2.form.bots,1,1,11)
        e["value"] = "newmap"
    end
    if (e["type"] == "onclick" and e["value"] == "newmap") then
        OPTS.seed = os.time();
        init_game();
        init_getready();
        g2.state = "pause"
    end
    if (e["type"] == "onclick" and e["value"] == "restart") then
        init_game();
        init_getready();
        g2.state = "pause"
    end
    if (e["type"] == "onclick" and e["value"] == "resume") then
        g2.state = "play"
    end
    if (e["type"] == "onclick" and e["value"] == "quit") then
        g2.state = "quit"
    end
    if (e["type"] == "pause") then
        init_pause();
        g2.state = "pause"
    end
end

-- }}} END GAME CODE

-- UTILITY FUNCTIONS {{{

-- make sure a number is actually a number
function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

-- value, default, min, max
function fix(v,d,a,b)
    if (type(v) == "string") then v = tonumber(v) end
    if (type(v) ~= "number") then v = d end
    if v < a then v = a end
    if v > b then v = b end
    return v
end

-- find a game object described by "query" using a evaluation function "eval"
function find(query,eval)
    local res = g2.search(query)
    local best = nil; local value = nil
    for _i,item in pairs(res) do
        _value = eval(item)
        if _value ~= nil and (value == nil or _value > value) then
            best = item
            value = _value
        end
    end
    return best
end

-- }}} END UTILITY FUNCTIONS 

-- HTML STUFF {{{

function init_menu()
    local html = [[
    <table><tr><td colspan=2><h1>Sample Bot Mod</h1>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>Homes:</p><td><input type='text' name='homes' />
    <tr><td><p>Neutrals:</p><td><input type='text' name='neutrals'  />
    <tr><td><p>Size:</p><td><input type='text' name='size' />
    <tr><td><p>Bots:</p><td><input type='text' name='bots' />
    <tr><td><p>&nbsp;</p>
    <tr><td colspan=2>
    <table><tr>
    <td><input type='button' value='Start' onclick='init' />
    </table></table>
    ]]
    html = string.gsub(html,"$Z",34)
    g2.html = html
    g2.form.neutrals = OPTS.neutrals
    g2.form.bots = OPTS.bots
    g2.form.homes = OPTS.homes
    g2.form.size = OPTS.size
end

function init_getready()
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>Get Ready!</h1>"..
    "<tr><td><input type='button' value='Tap to Begin' onclick='resume' />"..
    "";
end

function init_pause() 
    g2.html = ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume' onclick='resume' />"..
    "<tr><td><input type='button' value='Restart' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

function init_win() 
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><input type='button' value='Replay' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

function init_lose() 
    g2.html = "" ..
    "<table>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

-- }}} END HTML STUFF