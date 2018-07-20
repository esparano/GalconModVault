LICENSE = [[
Copyright (c) 2013 Phil Hassey
Modifed by: esparano
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
        seed = math.random(1,99999999),
        t = 1.0,
        rank = 1,
        sw = 720,
        sh = 540,
        -- default game settings
        neutrals = 30,
        homes = 1,
        size = 100,
        bots = 1,
        ships = 100,
        -- default bot settings
        wait = 1, -- time in between bot loop calls
    }
    
    OPTS.seed = os.time()
    init_menu()
    g2.state = "menu"
end

-- BOT CODE {{{ //////////////////////////////////

-- initialize anything needed for the bot to run
function init_bot_plus_plus()
    BOT = {}
    BOT.moves = {}
    
    -- get a reference to the neutral user
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
    BOT.tunneling_requests = {}
    BOT.turn_number = 0
end

-- bot loop called every turn
function bot_plus_plus(user)
    BOT.turn_number = BOT.turn_number + 1
    
    -- First-turn code
    if BOT.turn_number == 1 then
        -- find enemy user
        if BOT.enemy == nil then
            local users = g2.search("user")
            for _i,u in ipairs(users) do
                if u.user_neutral == 0 and u ~= user then BOT.enemy = u end
            end
        end
        -- identify homes
        local user_planets = g2.search("planet owner:"..user)
        BOT.home = user_planets[1]
        local enemy_planets = g2.search("planet owner:"..BOT.enemy)
        BOT.enemy_home = enemy_planets[1] 
        -- calculate horizon
        BOT.horizon = distance_to_time(BOT.home:distance(BOT.enemy_home))
        
        -- initial expansion    
        for i,planet_data in pairs(get_planet_data(BOT.home).closest_planets) do
            local planet = planet_data.planet
            planet_data = get_planet_data(planet)
            if planet:owner() == BOT.user_neutral then
                local h_to_e = BOT.home:distance(BOT.enemy_home)
                local h_to_n = planet:distance(BOT.home)
                local n_to_e = planet:distance(BOT.enemy_home)
                -- take ALL awesome planets that aren't behind the enemy
                if h_to_n < h_to_e and is_worth_capturing_ever(planet, BOT.horizon, BOT.home) then
                    send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                    BOT.target_planets[planet] = planet_data
                elseif h_to_n*1.5 < n_to_e then
                    -- take ALL decent planets that are very close to the bot
                    if is_worth_capturing_initially(planet, BOT.horizon*1.4, BOT.home) then
                        send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                        BOT.target_planets[planet] = planet_data
                    end
                elseif h_to_n < n_to_e then
                    -- take ALL good planets that are closer to the bot than the enemy
                    if is_worth_capturing_initially(planet, BOT.horizon*1.1, BOT.home) then
                        send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                        BOT.target_planets[planet] = planet_data
                    end
                elseif h_to_n < n_to_e*1.5 then
                    -- take ALL very good planets that are slightly closer to the enemy than the bot
                    if is_worth_capturing_initially(planet, BOT.horizon*0.9, BOT.home) then
                        send_exact(user, BOT.home, planet, amount_to_send(planet, BOT.home))
                        BOT.target_planets[planet] = planet_data
                    end
                end
            end
        end
    end
    
    -- main loop //////////
    
    -- update net_ships and target_planets
    for i,planet_data in pairs(BOT.planets) do
        local planet = planet_data.planet
        if planet:owner() == user then
            -- add the planet to the list of target planets (if it's already in the array, just overwrite it)
            BOT.target_planets[planet] = planet_data
        end
        -- reset net ships
        planet_data.net_ships = planet.ships_value
        planet_data.is_under_attack = false
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
                if BOT.target_planets[planet_data2.planet] ~= nil then
                    -- needed to correctly calculate "front" planets
                    local s_to_t = source.planet:distance(planet_data2.planet)
                    local s_to_c = source.planet:distance(closest_enemy.planet) 
                    local t_to_c = planet_data2.planet:distance(closest_enemy.planet) 
                    if  s_to_t < s_to_c and s_to_t + t_to_c < s_to_c*1.2 then
                        target = get_planet_data(planet_data2.planet) 
                        break 
                    end
                end
                if target ~= nil then break end
            end
            -- the source planet is a front planet
            if source.planet == target.planet then
                source.front = true
            -- the source planet is not a front planet
            elseif source.planet.owner_n == user.n then
                source.front = false
                -- try to find a closer planet to tunnel through
                for _j,planet_data2 in pairs(source.closest_planets) do
                    if planet_data2.planet.owner_n == user.n then
                        local d1 = source.planet:distance(planet_data2.planet)
                        local d2 = planet_data2.planet:distance(target.planet)
                        local d3 = source.planet:distance(target.planet)
                        if d2 < d3 and d1 < d3 and (d1 + d2)/1.2 < d3 then 
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
    -- correct the target planets
    for i,planet_data in pairs(BOT.target_planets) do
        if planet_data.planet.owner_n == user.n then
             if planet_data.target ~= nil then
                local planet_data2 = get_planet_data(planet_data.target.planet)
                if planet_data2.target ~= nil then
                    local d1 = planet_data.planet:distance(planet_data2.planet)
                    local d2 = planet_data2.planet:distance(planet_data2.target.planet)
                    local d3 = planet_data.planet:distance(planet_data2.target.planet)
                    if not (d2 < d3 and d1 < d3 and (d1 + d2)/1.2 < d3) then
                        planet_data.target = planet_data2.target
                        break  
                    end
                end
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
        if e_p > b_p*1.5 then
            BOT.state = "attack"
        -- if the enemy has about the same or less production, go into "defend" mode
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
    
    -- update incoming_fleets and adjust net_ships
    for i,planet_data in pairs(BOT.planets) do
        planet_data.incoming_fleets = {}
    end
    local fleets = g2.search("fleet")
    for i,fleet in ipairs(fleets) do
        local target_data = BOT.planets[fleet.fleet_target]
        target_data.incoming_fleets[#target_data.incoming_fleets + 1] = fleet
        local sign = -1
        if target_data.planet.owner_n  == fleet.owner_n then sign = 1 end
        if target_data.planet.owner_n == user.n and sign == -1 then
            local ships_to_reserve = fleet.fleet_ships - (fleet:distance(target_data.planet)/40 - 3)*target_data.planet.ships_production/50 + 1
            if ships_to_reserve < 0 then ships_to_reserve = 0 end
            target_data.net_ships = target_data.net_ships - ships_to_reserve
            target_data.is_under_attack = true
        else 
            target_data.net_ships = target_data.net_ships + sign*fleet.fleet_ships
        end
    end        
    
    -- attempt to support planets that need help (planet-planet support)
    for i,source in pairs(BOT.target_planets) do
        if source.planet.owner_n == user.n and source.net_ships < 0 then
            local planet_data = get_planet_data(source.planet)
            for k=1,4 do
                for j,helper in pairs(planet_data.closest_planets) do
                    local helper_data = get_planet_data(helper.planet)
                    if helper.dist < 400 and source.net_ships < 0 and helper_data.net_ships > 0 then
                        -- if the helper planet has ships available
                        if helper_data.planet.owner_n == user.n then
                            local amount_needed = -source.net_ships
                            if amount_needed > helper_data.net_ships/3 + 1 then amount_needed = helper_data.net_ships/3 + 1 end
                            -- planet under attack must prioritize its own defence over helping other planets
                            if not (helper_data.is_under_attack and helper_data.net_ships - amount_needed < 2) then
                                local amount_sent = send_exact(user, helper_data.planet, source.planet, amount_needed)
                                helper_data.net_ships = helper_data.net_ships - amount_sent
                                planet_data.net_ships = planet_data.net_ships + amount_sent
                            end
                        end
                    else
                        break
                    end
                end
            end
        end
    end
    
    -- offensive and efficiency-based redirecting
    local fleets = g2.search("fleet")
    for i,fleet in ipairs(fleets) do
        -- don't bother redirecting a million tiny fleets -> fewer calculations for minor bot performance impact
        if fleet.fleet_ships > 1.5 then
            if fleet.owner_n == user.n then
                local target_planet_data = BOT.planets[fleet.fleet_target]
                local target = target_planet_data.planet
                if target.owner_n == BOT.enemy.n then
                    -- if the planet cannot be captured or if the planet will definitely be captured without this fleet's help, redirect the fleet
                    if target_planet_data.net_ships > 5 or target_planet_data.net_ships + fleet.fleet_ships < -5 then
                        local target_worth = planet_worth(target, fleet)
                        local planet_to_attack = target_planet_data.planet
                        -- find best planet to redirect to
                        for j,p in pairs(target_planet_data.closest_planets) do
                            if p.dist > 400 then break end
                            if p.planet.owner_n == BOT.enemy.n then
                                local worth = planet_worth(p.planet, fleet)
                                if worth > target_worth and get_planet_data(p.planet).net_ships < target_planet_data.net_ships then
                                    target_worth = worth
                                    planet_to_attack = p.planet
                                end
                            end        
                        end
                        -- if a better target was found
                        if planet_to_attack ~= target_planet_data.planet then
                            -- redirect and update net_ships
                            fleet:fleet_redirect(planet_to_attack)
                            local planet_data = get_planet_data(planet_to_attack)
                            target_planet_data.net_ships = target_planet_data.net_ships + fleet.fleet_ships
                            planet_data.net_ships = planet_data.net_ships - fleet.fleet_ships
                        end
                    end
                -- if the fleet can reach the target faster by not tunneling and the target planet can spare the incoming fleet, redirect
                elseif target.owner_n == user.n then
                    if target_planet_data.net_ships - fleet.fleet_ships > 0 and target_planet_data.target ~= nil then
                        local d1 = fleet:distance(target_planet_data.planet)
                        local d2 = target_planet_data.planet:distance(target_planet_data.target.planet)
                        local d3 = fleet:distance(target_planet_data.target.planet)
                        if not (d2 < d3 and d1 < d3 and (d1 + d2)/1.4 < d3) then
                            fleet:fleet_redirect(target_planet_data.target.planet)
                            break  
                        end
                    end
                end
            end
        end
    end

    for i,source in pairs(BOT.target_planets) do
        if source.planet:owner() == user then
            -- shuttle remaining ships to front planets
            if source.front == false then
                if source.net_ships > 0 then
                    send_exact(user, source.planet, source.target.planet, source.net_ships)
                    source.net_ships = 0
                end
            else
                -- front planets attack with remaining ships
                local closest_enemy
                for _j,planet_data in pairs(source.closest_planets) do
                    if planet_data.planet.owner_n == BOT.enemy.n then closest_enemy = get_planet_data(planet_data.planet) break end
                end
                if closest_enemy ~= nil then
                    if source.net_ships > 0 then
                        local amount_sent = send_exact(user, source.planet, closest_enemy.planet, source.net_ships)
                        source.net_ships = 0
                    end
                end
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

function amount_to_send(to, from)
    -- account for rounding errors and intervening neutrals
    return future_ships(to, distance_to_time(to:distance(from))) + 1.5 + 0.000112*to.ships_production*to.ships_production_enabled*to:distance(from)/OPTS.sw 
end

function is_worth_capturing_initially(neutral, time, home)
	return (((-neutral.ships_value + (time - distance_to_time(neutral:distance(home)))* neutral.ships_production / 50.0))/(neutral.ships_value+0.1) > 0.3
        and neutral.ships_production/(neutral.ships_value+0.1) > 3) or (neutral.ships_production/(neutral.ships_value+0.1) > 6 and neutral.ships_value < 20)
end

-- return true if the planet is awesome
function is_worth_capturing_ever(neutral)
    return (neutral.ships_production/neutral.ships_value > 6 and neutral.ships_value < 7)
end

-- from can be a fleet or other planet
function planet_worth(to, from)
    return -to:distance(from)/11 - 2.2*to.ships_value + to.ships_production/5
end

-- convert distance to time
function distance_to_time(distance)
	return distance/40
end

-- try to send an amount of ships, return the amount sent
function send_exact(user, from, to, ships)
	if from.ships_value < ships then
		from:fleet_send(100, to)
		return from.ships_value
	end
	local perc = ships / from.ships_value * 100
	if perc > 100 then perc = 100 end
	from:fleet_send(perc, to)
	return ships
end

-- count the total amount of production a user has
function count_production(user)
    local total = 0
    local items = g2.search("planet owner:"..user)
    for i,item in ipairs(items) do
        total = total + item.ships_production
    end
    return total     
end

-- count the total number of ships a user has
function count_ships(user)
    local total = 0
    local items = g2.search("planet or fleet owner:"..user)
    for i,item in ipairs(items) do
        if item.has_planet == 1 then
            total = total + item.ships_value
        else
            total = total + item.fleet_ships
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
    init_bot_plus_plus()
end

function loop(t)
    OPTS.t = OPTS.t + t
    if (OPTS.t >= OPTS.wait) then
        OPTS.t = OPTS.t - OPTS.wait
        local users = g2.search("user")
        for _i,user in ipairs(users) do
            if (user.title_value == "enemy") then
                bot_plus_plus(user)
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
    <table><tr><td colspan=2><h1>Bot++ Mod by esparano</h1>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>Neutrals:</p><td><input type='text' name='neutrals'  />
    <tr><td><p>Size:</p><td><input type='text' name='size' />
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