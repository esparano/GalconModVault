-- reset bot before EVERY game
function reset_sparky()
    BOT = {}
end

-- bot loop called every turn
function bot_sparky(user)   
    -- local variables for optimization
    local bot = BOT[user.n]
    
    -- First-turn setup code
    if bot == nil then 
        -- BOT SETUP
        bot = {}
        BOT[user.n] = bot
        bot.first_turn = true
        
        -- Utility functions ------------

        -- recursively generate initial expansion tunnel
        bot.generate_tunnel_request = function(from, to, amount, user)
            local bot = BOT[user.n]
            for i=1, #from.closest_planets do local p = from.closest_planets[i];
                if p.n ~= to.planet.n then
                    local planet_data = bot.planets[p.n]
                    if planet_data.is_target then
                        local d1 = from.planet:distance(p)
                        local d2 = p:distance(to.planet)
                        local d3 = from.planet:distance(to.planet)
                        if d2 < d3 and d1 < d3 and d1 + d2 < d3 * bot.tunneling_const then 
                            bot.generate_tunnel_request(from, planet_data, amount, user)
                            bot.generate_tunnel_request(planet_data, to, amount, user)
                            return
                        end
                    end
                else
                    bot.tunneling_requests[#bot.tunneling_requests + 1] = {from=from,to=to,amount=amount}
                    return
                end
            end
        end

        -- recursively generate forward-movement tunnel
        bot.generate_target_tunnel = function(from, to, user)
            local bot = BOT[user.n]
            for i=1, #from.closest_planets do local p = from.closest_planets[i];
                if p.n ~= to.planet.n then
                    local planet_data = bot.planets[p.n]
                    if planet_data.is_target then
                        local d1 = from.planet:distance(p)
                        local d2 = p:distance(to.planet)
                        local d3 = from.planet:distance(to.planet)
                        if d2 < d3 and d1 < d3 and d1 + d2 < d3 * bot.tunneling_const then 
                            bot.generate_target_tunnel(from, planet_data, user)
                            bot.generate_target_tunnel(planet_data, to, user)
                            return
                        end
                    end
                else
                    from.target = to
                    return
                end
            end
        end

        -- The number of ships a planet will have after a time interval
        bot.future_ships = function(planet, time)
            return planet.ships_value + time * planet.ships_production * planet.ships_production_enabled * 0.02
        end

        -- amount to send from "from" to "to" when attacking.
        bot.amount_to_send = function(to, from)
            -- account for rounding errors and intervening neutrals
            local dist = to:distance(from)
            return bot.future_ships(to, dist*0.025) + 1.5 + 0.00012*to.ships_production*to.ships_production_enabled*dist
        end

        -- return true if the planet is decent
        bot.is_worth_capturing_initially = function(neutral, time, home)
            return (-neutral.ships_value + (time - neutral:distance(home)*0.025)*neutral.ships_production*0.02)/(neutral.ships_value+0.1) > 0.3
                and neutral.ships_production/(neutral.ships_value+0.1) > 3
        end

        -- return true if the planet is awesome
        bot.is_worth_capturing_ever = function(neutral)
            return neutral.ships_production/(neutral.ships_value+0.1) > 6 and neutral.ships_value < 7
        end

        -- simplified function for redirects only
        bot.planet_worth = function(to, from)
            return -to:distance(from)*0.09091 - 2.2*to.ships_value + to.ships_production*0.2
        end

        -- the number of ships that could be gained by attacking from this planet to another planet in the viscinity within horizon seconds
        bot.strategic_value = function(to, from, user)
            return -to.ships_value + to.ships_production*(BOT[user.n].horizon - to:distance(from)*0.025)
        end

        -- try to send an amount of ships, return the amount sent
        bot.send_exact = function(user, from, to, ships)
            if from.ships_value < ships then
                from:fleet_send(100, to)
                return from.ships_value
            end
            local perc = ships / from.ships_value * 100
            if perc > 100 then perc = 100 end
            from:fleet_send(perc, to)
            return ships
        end
    end
        
    -- FUNCTION SETUP
    local generate_tunnel_request = bot.generate_tunnel_request
    local generate_target_tunnel = bot.generate_target_tunnel
    local future_ships = bot.future_ships
    local amount_to_send = bot.amount_to_send
    local is_worth_capturing_initially = bot.is_worth_capturing_initially
    local is_worth_capturing_ever = bot.is_worth_capturing_ever
    local planet_worth = bot.planet_worth
    local strategic_value = bot.strategic_value
    local send_exact = bot.send_exact
    
    -- ACTUAL BOT SETUP
    if bot.first_turn then
        bot.tunneling_requests = {}
        bot.tunneling_const = 1.25
        
        -- get a reference to the neutral user (g2.search("user neutral") wasn't working...)
        if bot.user_neutral == nil then
            local users = g2.search("user")
            for i=1, #users do local u = users[i];
                if u.user_neutral == 1 then bot.user_neutral = u end
            end
        end
        
        -- each planet object has a reference to the corresponding planet, a list of other planets' distances, and a list of closest planets
        bot.planets = {}
        local planets = g2.search("planet")
        for i=1, #planets do local planet = planets[i];
            local planet_data = {dist = {}}
            for j=1, #planets do local planet2 = planets[j];
                planet_data.dist[planet2.n] = planet:distance(planet2)
            end
            bot.planets[planet.n] = planet_data
        end
        for i=1, #planets do local planet = planets[i];
            local planet_data = bot.planets[planet.n]
            local cp = {}
            for j=1, #planets do local planet2 = planets[j];
                if j ~= i then 
                    cp[#cp+1] = planet2
                end
            end
            planet_data.planet = planet
            planet_data.closest_planets = cp
            -- sort planets in the other_planets array
            table.sort(planet_data.closest_planets, function(p1,p2) if p1 ~= nil and p2 ~= nil then if planet_data.dist[p1.n] < planet_data.dist[p2.n] then return true end end end)
        end
        
        bot.target_planets = {}
        -- find enemy user
        if bot.enemy == nil then
            local users = g2.search("user")
            for i=1, #users do local u = users[i];
                if u.user_neutral == 0 and u ~= user then bot.enemy = u end
            end
        end
        -- identify homes
        local user_planets = g2.search("planet owner:"..user)
        bot.home = user_planets[1]
        local enemy_planets = g2.search("planet owner:"..bot.enemy)
        bot.enemy_home = enemy_planets[1] 
        -- calculate horizon
        bot.horizon = bot.home:distance(bot.enemy_home)*0.025
        -- calculate planet worth for initial ship distribution
        for i,planet_data in pairs(bot.planets) do
            local planet_worth = 1
            for j,planet_2 in pairs(planet_data.closest_planets) do
                local value = strategic_value(planet_2, planet_data.planet, user)
                if value > 0 then planet_worth = planet_worth + value end
            end
            planet_data.planet_worth = planet_worth
        end
        -- initial expansion  
        local home_n = bot.home.n
        local home_data = bot.planets[home_n]
        local h_to_e = home_data.dist[bot.enemy_home.n]
        for i,planet in pairs(home_data.closest_planets) do
            if planet.owner_n == bot.user_neutral.n then
                local h_to_n = home_data.dist[planet.n]
                -- take ALL awesome planets that aren't behind the enemy
                if h_to_n < h_to_e and is_worth_capturing_ever(planet) then
                    local planet_data = bot.planets[planet.n]
                    generate_tunnel_request(home_data, planet_data, amount_to_send(planet, bot.home), user)
                    bot.target_planets[planet.n] = planet_data
                    planet_data.is_target = true
                elseif is_worth_capturing_initially(planet, bot.horizon*1.15, bot.home) then
                    local planet_data = bot.planets[planet.n]
                    generate_tunnel_request(home_data, planet_data, amount_to_send(planet, bot.home), user)
                    bot.target_planets[planet.n] = planet_data
                    planet_data.is_target = true
                end
            end
        end    
    end

    -- main loop ///////////////
    
    -- TESTING STUFF
    test=[[
    for i,planet_data in pairs(bot.planets) do
        local test_property = tostring(planet_data.front)
        local p = planet_data.planet
        if planet_data.label ~= nil then
            planet_data.label.label_text = test_property
        else
            planet_data.label = g2.new_label(test_property, p.position_x, p.position_y + 30)
        end
    end ]]
    
    -- update net_ships and target_planets
    for i,planet_data in pairs(bot.planets) do
        local planet = planet_data.planet
        if planet.owner_n == user.n or planet.owner_n == bot.enemy.n then
            -- add the planet to the list of target planets (if it's already in the array, just overwrite it)
            planet_data.is_target = true
            bot.target_planets[planet.n] = planet_data
        end
        -- reset net ships
        planet_data.net_ships = planet.ships_value
        planet_data.is_under_attack = false
    end
    
    -- calculate the "front" planets
    for i,source in pairs(bot.target_planets) do
        if source.planet.owner_n ~= bot.enemy.n then
            -- find closest enemy planet to "source"
            local closest_enemy
            for j,planet in pairs(source.closest_planets) do
                if planet.owner_n == bot.enemy.n then closest_enemy = bot.planets[planet.n] break end
            end
            if closest_enemy ~= nil then
                -- find closest target planet to "closest_enemy"
                local target
                for k,planet2 in ipairs(closest_enemy.closest_planets) do
                    local planet_data_2 = bot.planets[planet2.n]
                    if planet_data_2.is_target then
                        -- needed to correctly calculate "front" planets
                        local s_to_t = source.dist[planet2.n]
                        local s_to_c = source.dist[closest_enemy.planet.n]
                        local t_to_c = closest_enemy.dist[planet2.n]
                        if  s_to_t < s_to_c and s_to_t + t_to_c < s_to_c*bot.tunneling_const then
                            target = planet_data_2
                            break 
                        end
                    end
                    if target ~= nil then break end
                end
                -- the source planet is a front planet
                if source.planet == target.planet then
                    source.front = true
                -- the source planet is not a front planet
                else
                    source.front = false
                    generate_target_tunnel(source, target, user)
                end
            end    
        else
            source.front = nil
            source.target = nil
        end
    end  
    
    -- attempt to complete any oustanding tunneling requests
    for i,request in pairs(bot.tunneling_requests) do
        if request.from.planet.owner_n == user.n and request.from.net_ships > 0 then
            local amount_to_send = request.amount 
            if amount_to_send > request.from.net_ships then 
                amount_to_send = request.from.net_ships
                request.from.unallocated_ships = 0
            end
            local amount_sent = send_exact(user, request.from.planet, request.to.planet, amount_to_send)
            request.amount = request.amount - amount_sent
            request.from.net_ships = request.from.net_ships - amount_sent
            if request.amount <= 0 then
                bot.tunneling_requests[i] = nil
            end
        end
    end
    
    -- allocate remaining ships to good front planets on first turn
    if bot.first_turn then
        bot.first_turn = false
        local front_planets = {}
        local total_front_planet_worth = 0
        for i,planet_data in pairs(bot.target_planets) do
            if planet_data.target then 
                front_planets[#front_planets + 1] = planet_data 
                total_front_planet_worth = total_front_planet_worth + planet_data.planet_worth
            end
        end   
        for i,planet_data in pairs(front_planets) do
            send_exact(user, bot.home, planet_data.planet, bot.home.ships_value*planet_data.planet_worth/total_front_planet_worth)
        end
    end
    
    -- update incoming_fleets and adjust net_ships
    for i,target_data in pairs(bot.planets) do
        local fleets = g2.search("fleet target:"..target_data.planet)
        target_data.incoming_fleets = {}
        for i=1, #fleets do local fleet = fleets[i];
            target_data.incoming_fleets[#target_data.incoming_fleets + 1] = {fleet=fleet, dist=fleet:distance(target_data.planet)}
            local sign = -1
            if target_data.planet.owner_n == fleet.owner_n then sign = 1 end
            -- when an enemy fleet is incoming, save a few ships on the closest friendly planet as well as ships on the target planet
            if target_data.planet.owner_n == user.n and sign == -1 then
                local closest_friendly
                local closest_distance = math.huge
                for j,planet_data in pairs(bot.target_planets) do
                    if planet_data.planet.owner_n == user.n then
                        local dist = fleet:distance(planet_data.planet)
                        if dist < closest_distance then
                            closest_distance = dist
                            closest_friendly = planet_data
                        end
                    end
                end
                if closest_friendly ~= nil then
                    local ships_to_reserve = fleet.fleet_ships - (closest_distance*0.025 - 3)*closest_friendly.planet.ships_production*0.02 + 1
                    if ships_to_reserve < 0 then ships_to_reserve = 0 end
                    closest_friendly.net_ships = closest_friendly.net_ships - ships_to_reserve*0.3
                end
                local ships_to_reserve = fleet.fleet_ships - (fleet:distance(target_data.planet)*0.025 - 3)*target_data.planet.ships_production*0.02 + 1
                if ships_to_reserve < 0 then ships_to_reserve = 0 end
                target_data.net_ships = target_data.net_ships - ships_to_reserve*0.7
                target_data.is_under_attack = true
            else 
                target_data.net_ships = target_data.net_ships + sign*fleet.fleet_ships
            end
        end
    end
    -- sort incoming_fleets by distance to target
    for i,planet_data in pairs(bot.planets) do
        table.sort(planet_data.incoming_fleets, function(f1,f2) if f1 ~= nil and f2 ~= nil then if f1.dist < f2.dist then return true end end end)
    end 
    -- redirect fleets if the enemy is also going to an expensive neutal
    for i,planet_data in pairs(bot.target_planets) do
        if planet_data.planet.owner_n == bot.user_neutral.n then
            if planet_data.planet.ships_value > 6 then
                local fleets = planet_data.incoming_fleets
                if fleets[1] ~= nil and fleets[2] ~= nil then
                    if fleets[1].fleet.owner_n == user.n and fleets[2].fleet.owner_n == bot.enemy.n then
                        local arrival_time_1 = fleets[1].dist*0.025
                        local arrival_time_2 = fleets[2].dist*0.025
                        -- if capturing the planet leads to a net gain of ships for the enemy, then don't take it
                        if (-planet_data.planet.ships_value + fleets[1].fleet.fleet_ships) + (arrival_time_2 - arrival_time_1) * planet_data.planet.ships_production*0.02 < fleets[2].fleet.fleet_ships 
                            or (arrival_time_2 - arrival_time_1 - 2) * planet_data.planet.ships_production*0.02 < planet_data.planet.ships_value then
                            -- redirect to the closest enemy planet
                            local closest_enemy
                            for j,new_target in pairs(planet_data.closest_planets) do
                                if new_target.owner_n == bot.enemy.n then closest_enemy = bot.planets[new_target.n] break end
                            end
                            if closest_enemy ~= nil then
                                fleets[1].fleet:fleet_redirect(closest_enemy.planet)
                                planet_data.net_ships = planet_data.net_ships + fleets[1].fleet.fleet_ships
                                closest_enemy.net_ships = closest_enemy.net_ships - fleets[1].fleet.fleet_ships
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- attempt to support planets that need help (planet-planet support)
    for i,source in pairs(bot.target_planets) do
        if source.planet.owner_n == user.n and (source.net_ships < 0 or (source.is_under_attack and source.net_ships < 2))then
            for k=1,4 do
                for j,helper in pairs(source.closest_planets) do
                    local helper_data = bot.planets[helper.n]
                    -- if the helper planet has ships available
                    if source.dist[helper.n] < 250 and source.net_ships < 0 and helper_data.net_ships > 0 then
                        if helper.owner_n == user.n then
                            local amount_needed = -source.net_ships
                            if amount_needed > helper_data.net_ships*0.3333 + 1 then amount_needed = helper_data.net_ships*0.3333 + 1 end
                            -- planet under attack must prioritize its own defence over helping other planets
                            if not (helper_data.is_under_attack and helper_data.net_ships - amount_needed < 2) then
                                local amount_sent = send_exact(user, helper, source.planet, amount_needed)
                                helper_data.net_ships = helper_data.net_ships - amount_sent
                                source.net_ships = source.net_ships + amount_sent
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
    for i=1, #fleets do local fleet = fleets[i];
        -- don't bother redirecting a million tiny fleets -> fewer calculations for minor bot performance impact
        --if fleet.fleet_ships > 0 then -- nvm
            if fleet.owner_n == user.n then
                local target_planet_data = bot.planets[fleet.fleet_target]
                local target = target_planet_data.planet
                if target.owner_n == bot.enemy.n then
                    -- if the planet cannot be captured or will definitely be captured without this fleet's help,
                    if target_planet_data.net_ships > 0 or target_planet_data.net_ships + fleet.fleet_ships < 0 then
                        local target_worth = planet_worth(target, fleet) - 1
                        local planet_to_attack = target_planet_data.planet
                        -- find best planet to redirect to
                        for j,p in pairs(target_planet_data.closest_planets) do
                            if p:distance(fleet) < 300 then 
                                -- either find a better enemy planet
                                if p.owner_n == bot.enemy.n then
                                    local worth = planet_worth(p, fleet)
                                    if worth > target_worth and bot.planets[p.n].net_ships < target_planet_data.net_ships then
                                        target_worth = worth
                                        planet_to_attack = p
                                    end
                                end  
                            end
                        end
                        -- if a better target was found
                        if planet_to_attack ~= target_planet_data.planet then
                            -- redirect and update net_ships
                            fleet:fleet_redirect(planet_to_attack)
                            local planet_data = bot.planets[planet_to_attack.n]
                            target_planet_data.net_ships = target_planet_data.net_ships + fleet.fleet_ships
                            local sign = -1
                            if planet_to_attack.owner_n == fleet.fleet_target then sign = 1 end
                            planet_data.net_ships = planet_data.net_ships + sign*fleet.fleet_ships
                        end
                    end
                elseif target.owner_n == user.n then
                    -- if the target doesn't really need this fleet, redirect it
                    if target_planet_data.net_ships - fleet.fleet_ships > 0 then
                        -- go right to the target's target if it exists and it saves time
                        if target_planet_data.target ~= nil then
                            local d1 = fleet:distance(target_planet_data.planet)
                            local d2 = target_planet_data.dist[target_planet_data.target.planet.n]
                            local d3 = fleet:distance(target_planet_data.target.planet)
                            if not (d2 < d3 and d1 < d3 and d1 + d2 < d3 * bot.tunneling_const) then 
                                fleet:fleet_redirect(target_planet_data.target.planet)
                                local data = bot.planets[target_planet_data.target.planet.n]
                                data.net_ships = data.net_ships - fleet.fleet_ships
                                target_planet_data.net_ships = target_planet_data.net_ships - fleet.fleet_ships
                            end
                        end
                    end
                end
            end
        --end
    end

    for i,source in pairs(bot.target_planets) do
        if source.planet.owner_n == user.n then
            -- give remaining ships to target planet
            if source.front == false then
                if source.net_ships > 0 then
                    send_exact(user, source.planet, source.target.planet, source.net_ships)
                    source.net_ships = 0
                end
            else
                -- front planets attack with remaining ships
                for _j,planet in pairs(source.closest_planets) do
                    if planet.owner_n == bot.enemy.n then 
                        local closest_enemy = bot.planets[planet.n] 
                        source.target = closest_enemy
                        local amount_to_send = amount_to_send(closest_enemy.planet, source.planet)
                        if amount_to_send > source.net_ships then
                            if source.net_ships > 0 then
                                send_exact(user, source.planet, closest_enemy.planet, source.net_ships)
                                source.net_ships = 0
                            end
                            break
                        else
                            local to = closest_enemy.planet
                            local from = source.planet
                            local dist = closest_enemy.dist[from.n]
                            local time = dist/40 + 1.5 + 0.00012*to.ships_production*dist
                            local amount_to_send = closest_enemy.net_ships + time * to.ships_production / 50.0
                            if amount_to_send < 0 then amount_to_send = 0 end
                            local amount_sent = send_exact(user, source.planet, closest_enemy.planet, amount_to_send)
                            source.net_ships = source.net_ships - amount_sent
                            closest_enemy.net_ships = closest_enemy.net_ships - amount_sent
                        end
                    end
                end
            end
        end
    end
end