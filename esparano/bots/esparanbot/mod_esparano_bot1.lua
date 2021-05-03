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
        sw = 640,
        sh = 480,
        -- default game settings
        neutrals = 10,
        homes = 1,
        size = 100,
        bots = 1,
        -- default bot settings
        wait = 0.3, -- time in between bot loop calls
    }
    
    OPTS.seed = os.time()
    init_menu()
    g2.state = "menu"
end

--- {{{ Bot code ----------------------------

-- call at the very end of init_game()
function init_bot_bot1()    
    BOT1 = {}
    BOT1.moves = {}
    
    -- how far in the future the bot will predict moves for
    BOT1.horizon = 20
    
    if BOT1.user_neutral == nil then
        local users = g2.search("user")
        for _i,u in ipairs(users) do
            if u.user_neutral == 1 then BOT1.user_neutral = u end
        end
    end
    
    -- calculate an array of all planets and their distances from each other planet
    -- an array holding "planet" objects
    -- each planet object has a reference to the corresponding planet and a list of other planets sorted by distance from it
    BOT1.planets = {}
    local planets = g2.search("planet")
    for i,planet in ipairs(planets) do
        local cp = {}
        for j,planet2 in ipairs(planets) do
            if j ~= i then
                table.insert(cp, {planet=planet2,dist = planet:distance(planet2)})
            end
        end
        BOT1.planets[planet.n] = {planet = planet,closest_planets = cp}
        -- sort planets in the other_planets array
        table.sort(BOT1.planets[planet.n].closest_planets, function(p1,p2) if p1 ~= nil and p2 ~= nil then if p1.dist < p2.dist then return true end end end)
    end
end

function bot1(user)
    BOT1.moves = {}
    -- all fleets currently in the air
    BOT1.fleets = g2.search("fleet")
    -- update game state
    for i,planet_data in pairs(BOT1.planets) do
        -- update unallocated ships
        local planet = planet_data.planet
        if planet:owner() == user then
            planet_data.unallocated_ships = planet.ships_value
        end
        -- update planet timeline
        update_planet_timeline(planet)
    end
    
    -- pick moves
    while total_unallocated_ships(user) > 0 do
        if find_best_move(user) == false then break end
    end    
            
    -- do moves for this turn
    for i,move in ipairs(BOT1.moves) do
        for j,partial_move in ipairs(move) do
            send_exact(user, partial_move.from, partial_move.to, partial_move.amount)
        end
    end
end

function find_best_move(user)
    -- pick the best possible move
    local best_move
    local best_return_ratio = 0
    local investment
    local return_on_investment
    local return_ratio
    for _i,planet_data in pairs(BOT1.planets) do
        local planet = planet_data.planet
        if planet:owner() == user then
            -- calculate the return on defending this planet from any attacks within horizon seconds (if the planet will be captured)
            -- TODO: FIX CASE WHERE CAPTURING PLANET TEMPORARILY BEFORE A LARGE ATTACK COMES IN YIELDS A GOOD RETURN
            -- find the minimum number of ships necessary to defend the planet from any attacks within horizon seconds
            local min_investment = 0
            for i=1,BOT1.horizon/OPTS.wait do
                if planet_data.timeline[i] < 0 then
                    if -planet_data.timeline[i] > min_investment then min_investment = -planet_data.timeline[i] end
                end
            end
            -- only consider attacking planet if it will be captured without aid
            if min_investment > 0 then
                investment = min_investment
                return_on_investment = (BOT1.horizon - time_distance(planet, closest_owned_planet(planet, user)))* planet.ships_production / 50.0 * 2 - investment -- multiply by 2 because you also deny your enemy production
                return_ratio = return_on_investment/investment
                if return_ratio > best_return_ratio then
                    -- this is a good move.  Attempt to construct an attack from the available ships
                    local move = {}
                    local ships_to_be_sent = 0
                    for j,close_planet in ipairs(planet_data.closest_planets) do
                        if close_planet.planet:owner() == user then
                            local planet_data2 = get_planet_data(close_planet.planet)
                            if ships_to_be_sent + planet_data2.unallocated_ships > investment then
                                -- the attack plan has been successfully constructed
                                move[#move + 1] = {to=planet, from=close_planet.planet, amount=investment - ships_to_be_sent}
                                best_return_ratio = return_ratio
                                best_move = move
                                break
                            else
                                ships_to_be_sent = ships_to_be_sent + planet_data2.unallocated_ships
                                move[#move + 1] = {to=planet, from=close_planet.planet, amount=planet_data2.unallocated_ships}
                            end
                        end
                    end                
                end
            end
        elseif planet:owner() == BOT1.user_neutral then
            -- calculate the return on capturing this neutral
            -- find the minimum number of ships necessary to defend the planet from any attacks within horizon seconds
            -- TODO: FIX CASE WHERE ENEMY ATTACKS SAME NEUTRAL
            investment = planet_data.timeline[#planet_data.timeline] + 1 -- avoid divide by zero errors.... HACK
            return_on_investment = (BOT1.horizon - time_distance(planet, closest_owned_planet(planet, user))) * planet.ships_production / 50.0 - investment
            return_ratio = return_on_investment/investment
            if return_ratio > best_return_ratio then
                -- this is a good move.  Attempt to construct an attack from the available ships
                local move = {}
                local ships_to_be_sent = 0
                for j,close_planet in ipairs(planet_data.closest_planets) do
                    if close_planet.planet:owner() == user then
                        local planet_data2 = get_planet_data(close_planet.planet)
                        if ships_to_be_sent + planet_data2.unallocated_ships > investment then
                            -- the attack plan has been successfully constructed
                            move[#move + 1] = {to=planet, from=close_planet.planet, amount=investment - ships_to_be_sent}
                            best_return_ratio = return_ratio
                            best_move = move
                            break
                        else
                            ships_to_be_sent = ships_to_be_sent + planet_data2.unallocated_ships
                            move[#move + 1] = {to=planet, from=close_planet.planet, amount=planet_data2.unallocated_ships}
                        end
                    end
                 end                
             end
        else
            -- calculate the return on taking this planet from the enemy
            -- find the minimum number of ships necessary to take this planet despite enemy support within horizon seconds
            local min_investment = 0
            for i=1,BOT1.horizon/OPTS.wait do
                if planet_data.timeline[i] > 0 then
                    if planet_data.timeline[i] > min_investment then min_investment = planet_data.timeline[i] end
                end
            end
            if min_investment > 0 then
                investment = min_investment + 1
                return_on_investment = (BOT1.horizon - time_distance(planet, closest_owned_planet(planet, user))) * planet.ships_production / 50.0 * 2 - investment -- multiply by 2 because you also deny your enemy production
                return_ratio = return_on_investment/investment
                if return_ratio > best_return_ratio then
                    -- this is a good move.  Attempt to construct an attack from the available ships
                    local move = {}
                    local ships_to_be_sent = 0
                    for j,close_planet in ipairs(planet_data.closest_planets) do
                        if close_planet.planet:owner() == user then
                            local planet_data2 = get_planet_data(close_planet.planet)
                            if ships_to_be_sent + planet_data2.unallocated_ships > investment then
                                -- the attack plan has been successfully constructed
                                move[#move + 1] = {to=planet, from=close_planet.planet, amount=investment - ships_to_be_sent}
                                best_return_ratio = return_ratio
                                best_move = move
                                break
                            else
                                ships_to_be_sent = ships_to_be_sent + planet_data2.unallocated_ships
                                move[#move + 1] = {to=planet, from=close_planet.planet, amount=planet_data2.unallocated_ships}
                            end
                        end
                    end                
                end
            end
        end
    end
    -- if a best move has been found, add it to the list of moves
    if best_move ~= nil then
        table.insert(BOT1.moves, best_move)
        local planet_data4 = get_planet_data(best_move[1].to)
        if planet_data4.planet:owner() == user then
            -- since this planet needs to be defended, don't let it send any ships anywhere 
            -- SHOULD DEFENSE HAVE PRECEDENCE OVER OFFENSE?
            planet_data4.unallocated_ships = 0
            for k=1,BOT1.horizon/OPTS.wait do
                planet_data4.timeline[k] = 0 -- HACK TO MAKE THE PLANET NOT BE DEFENDED ANYMORE THIS TURN
            end
        elseif planet_data4.planet:owner() == BOT1.user_neutral then
            for k=1,BOT1.horizon/OPTS.wait do
                planet_data4.timeline[k] = 10000000000 -- HACK TO MAKE THE PLANET NOT BE ATTACKED ANYMORE THIS TURN
            end
        else
            for k=1,BOT1.horizon/OPTS.wait do
                planet_data4.timeline[k] = -10000000000 -- HACK TO MAKE THE PLANET NOT BE ATTACKED ANYMORE THIS TURN
            end
        end
        
        -- update planet timelines
        for m,partial_move in ipairs(best_move) do
            local planet_data_from = get_planet_data(partial_move.from)
            planet_data_from.unallocated_ships = planet_data_from.unallocated_ships - partial_move.amount
        end
    else 
        return false
    end
end

function closest_owned_planet(planet, user)
    local planet_data = get_planet_data(planet)
    for i,planet2 in pairs(planet_data.closest_planets) do
        if planet2.planet:owner() == user then return planet2.planet end
    end
    print("couldn't find any planet")
end

-- update this planet's timeline
function update_planet_timeline(planet)
    local planet_data = get_planet_data(planet)
    planet_data.timeline = {}
    -- the correct timeline if the planet isn't taken over at any point
    for i=1,BOT1.horizon/OPTS.wait do
        planet_data.timeline[i] = future_ships(planet, i*OPTS.wait)
    end
    
    -- account for incoming fleets
    for i,fleet in ipairs(BOT1.fleets) do
        if fleet.fleet_target == planet.n then
            local arrival_time = time_distance(fleet, planet) - 0.5
            if fleet:owner() == planet:owner() then
                 -- the fleet is friendly
                 for j=math.ceil(arrival_time/OPTS.wait),BOT1.horizon/OPTS.wait do
                    if j >= 1 then 
                        planet_data.timeline[j] = planet_data.timeline[j] + mknumber(fleet.fleet_ships)
                    end
                 end
            else
                 -- TODO: ACCOUNT FOR PLANETS THAT WILL EVENTUALLY CHANGE HANDS
                 -- CURRENTLY PLANETS THAT WILL BE TAKEN OVER HAVE NEGATIVE VALUES AT T AFTER CAPTURE
                 -- the fleet is not friendly
                 for j=math.ceil(arrival_time/OPTS.wait),BOT1.horizon/OPTS.wait do
                    if j >= 1 then
                        planet_data.timeline[j] = planet_data.timeline[j] - mknumber(fleet.fleet_ships)
                    end
                 end
            end
        end
    end
end

-- get the data associated with this planet
function get_planet_data(planet)
    return BOT1.planets[planet.n]
end

-- return the number of ships not used for any purpose
function total_unallocated_ships(user)
    local total = 0
    for _i,planet_data in pairs(BOT1.planets) do
        local planet = planet_data.planet
        if planet:owner() == user then
            total = total + math.floor(planet_data.unallocated_ships)
        end
    end
    return total
end

-- Send a specific number of ships
-- Returns the number of ships actually sent
function send_exact(user, from, to, ships)
	if from.ships_value < ships then
		from:fleet_send(100, to)
		print("could not send enough ships")
	end
	local perc = ships / from.ships_value * 100
	if perc > 100 then perc = 100 end
	from:fleet_send(perc, to)
end

-- returns the angle formed by three planets (picture two vectors from middle->first and middle->last)
function angle_between(first, middle, last)
	local angle1 = math.atan2(first.position_y - middle.position_y, first.position_x - middle.position_x)
	local angle2 = math.atan2(last.position_y - middle.position_y, last.position_x - middle.position_x)
	local angle = math.abs(angle2 - angle1)
	if angle > math.pi then angle = 2*math.pi - angle end
	return angle
end

-- if the user were to attack this planet, how long would it take
-- for the user to break even on ship investment?
function time_to_break_even(p, time_overhead)
	return p.ships_value / (p.ships_production / 50.0) + time_overhead
end

-- "Time-distance" between a source and a planet
function time_distance(source, planet)
	return source:distance(planet)/40
end

-- "Time-distance" for a length distance
function distance_to_time(distance)
	return distance/40
end

-- The number of ships a planet will have after a time interval
function future_ships(planet, time)
	return planet.ships_value + time * planet.ships_production * planet.ships_production_enabled / 50.0
end

-- pythagorean theorem
function dist(x1, y1, x2, y2)
	return math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
end

--- }}} End bot code -------------------------

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
            g2.new_planet(o2, x,y, 100, 100);
        end
        a = a + 360/(users)
        a = a + 360/(OPTS.homes*users)
        
    end
    
    for i=1,OPTS.neutrals do
        g2.new_planet(user_neutral, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end

    g2.planets_settle()
    init_bot_bot1()
end

function loop(t)   
    OPTS.t = OPTS.t + t
    if (OPTS.t >= OPTS.wait) then
        OPTS.t = OPTS.t - OPTS.wait
        local users = g2.search("user")
        for _i,user in ipairs(users) do
            if (user.title_value == "enemy") then
                bot1(user)
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