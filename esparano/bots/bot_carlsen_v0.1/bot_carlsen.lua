-- Notes: Minimax with uncertainty:
-- http://en.wikipedia.org/wiki/Minimax#Minimax_in_the_face_of_uncertainty

require("bot_util.lua")
require("bot_carlsen_eval.lua")
require("bot_carlsen_util.lua")
global("BOT_CARLSEN")

function bot_carlsen_init()
    BOT_CARLSEN = {}
    local BOT = BOT_CARLSEN
    -- ship-sending "resolution"
    BOT.send_incr = 20
    -- minimum time in between moves
    BOT.min_cooldown = 1
    -- time to advance simulation by 
    BOT.simulation_dt = BOT.min_cooldown
    
    BOT.max_search_depth = 100

end

-- continue with calculation for a time dt
function bot_carlsen_loop(user, dt)
    -- get bot data or initialize
    if not BOT_CARLSEN then bot_carlsen_init() end
    local BOT = BOT_CARLSEN
    BOT.user = user
    BOT.enemy_user = bot_carlsen_get_enemy_user(user)
    
    -- update t or initialize
    BOT.t = BOT.t or 0
    BOT.t = BOT.t + dt
    
    --[[
    BOT.cooldown = BOT.cooldown or 0
    BOT.cooldown = BOT.cooldown - dt
    --]]
    
    -- get shorter function references
    local RTMM = bot_carlsen_RTMM_ID
    local execute = bot_carlsen_execute_action
    local d2t = dist_to_time
    local t2d = time_to_dist
    local p2s = prod_to_ships
    local s2p = ships_to_prod
    
    -- find a plan assuming that the opponent does not move
    local start_t = os.clock()
    local end_t = start_t + dt - 0.01
    
    local s = bot_carlsen_get_start_state()
    
    local depth = s.time
    local best_action
    while os.clock() < end_t do
        local action = RTMM(s, depth)
        if action then 
            best_action = action 
        end
        depth = depth + BOT.min_cooldown
        local search_depth = math.floor((depth - s.time)/BOT.min_cooldown + 0.5)
        
        if search_depth >= BOT.max_search_depth then break end
    end    
    --print(math.floor((depth - s.time)/BOT.min_cooldown + 0.5))
    -- THIS SHOULD BE BEST_PLAN, NOT BEST_ACTION
    if best_action then  
        if best_action.type ~= "pass" then
            --print("best action: ".."target: "..best_action.target.n.." ships: "..best_action.fleet.fleet_ships)
        end
        execute(s, best_action) 
    end
    --]]
end

function bot_carlsen_RTMM_ID(s, t_max)
    local BOT = BOT_CARLSEN
    local issue_action = bot_carlsen_issue_action
    local get_actions = bot_carlsen_get_actions
    local RTMM = bot_carlsen_RTMM
    
    local best_action = nil
    
    -- go through all of the bot's actions
    local bot_actions = get_actions(s, BOT.user)
    if #bot_actions > 0 then
        local best = -math.huge
        for _i, action in ipairs(bot_actions) do
            local result_s = issue_action(s, action)
            local result = RTMM(result_s, t_max)
            --[[
            if action.type ~= "pass" then
                print("target: "..action.fleet.fleet_target.." result: "..result.." ships: "..action.fleet.fleet_ships)
            else
                --print("PASS: ".."result: "..result)
            end 
            --]]  
            if result > best then
                best = result
                best_action = action
            elseif result == best then
                -- on ties, prefer pass actions and actions with fewer ships
                if action.type ~= "pass" then
                    if best_action.type ~= "pass" then
                        if action.ships < best_action.ships then
                            best_action = action
                        end
                    end
                else
                    best_action = action
                end
            end
        end
    end
    
    if best_action then
        -- figure out cooldown
        
        return best_action
    else 
        
    end
end

-- real-time minimax given a current state s and 
-- a maximum simulation cutoff of t_max
function bot_carlsen_RTMM(s, t_max) 
    local BOT = BOT_CARLSEN
    
    local eval = bot_carlsen_eval1
    local get_actions = bot_carlsen_get_actions
    local simulate = bot_carlsen_simulate
    local RTMM = bot_carlsen_RTMM
    local issue_action = bot_carlsen_issue_action
    
    -- return an evaluation if a terminal state has been
    -- reached or if time has expired
    --if s.time >= t_max or not s.ongoing then
    if s.time >= t_max then
        return eval(s)
    end
    
    --
    -- go through all of the bot's actions
    local bot_actions = get_actions(s, BOT.user)
    if #bot_actions > 0 then
        local best = -math.huge
        for _i, action in ipairs(bot_actions) do
            local result_s = issue_action(s, action)
            local result = RTMM(result_s, t_max) 
            best = math.max(best, result) 
        end
        return best
    end
    --]]
    
    --
    -- go through all of the enemy's actions
    local enemy_actions = get_actions(s, BOT.enemy_user)
    if #enemy_actions > 0 then
        local best = math.huge
        for _i, action in ipairs(enemy_actions) do
            local result_s = issue_action(s, action)
            local result = RTMM(result_s, t_max) 
            best = math.min(best, result) 
        end
        return best
    end
    --
    
    -- no actions remaining, so simulate until 
    -- someone can perform an action
    return RTMM(simulate(s, t_max), t_max)
end

-- run the game from s until either player may issue a new
-- action, the game ends, or until t_max has been reached
-- return the reached state
function bot_carlsen_simulate(prev_s, t_max, stop_if_move_found)
    local BOT = BOT_CARLSEN
    local s = deep_copy(prev_s)
    
    local planets = s.planets
    local fleets = s.fleets
    local dt = BOT.simulation_dt -------------- CHANGE THIS MAYBE?
    
    local time
    for t = s.time, t_max, dt do
        time = t
        -- update planets with production
        for _i, planet in pairs(planets) do
            planet.ships_value = future_ships(planet, dt)
        end
        
        -- update fleet positions
        for _i, fleet in pairs(fleets) do
            local target = planets[fleet.fleet_target]
            local f_x = fleet.position_x
            local f_y = fleet.position_y
            local t_x = target.position_x
            local t_y = target.position_y
            local dx = t_x - f_x
            local dy = t_y - f_y
            local hyp = math.sqrt(dx*dx + dy*dy)
            
            local landed = false
            if hyp ~= 0 then
                local travel_dist = time_to_dist(dt)
                local delta_x = travel_dist*dx/hyp
                local delta_y = travel_dist*dy/hyp
                
                local distance = math.sqrt((f_x-t_x)*(f_x-t_x)+(f_y-t_y)*(f_y-t_y))
                if distance < travel_dist + target.planet_r then
                    landed = true
                end
                
                fleet.position_x = f_x + delta_x
                fleet.position_y = f_y + delta_y
            else
                landed = true
            end
            
            -- if fleets land, change the planet's ships
            -- and change ownership if necessary
            -- TEMPORARY.  FLEETS SHOULD LAND INCREMENTALLY
            if landed then
                -- friendly fleet
                if fleet.owner_n == target.owner_n then
                    target.ships_value = target.ships_value + fleet.fleet_ships
                -- unfriendly fleet
                else
                    local diff = target.ships_value - fleet.fleet_ships
                    -- change ownerships
                    if diff < 0 then
                        target.owner_n = fleet.owner_n
                        target.ships_value = -diff
                        target.ships_production_enabled = true
                    else
                        target.ships_value = diff
                    end
                end
                s.fleets[fleet.n] = nil 
            end
        end
        
        if stop_if_move_found == true then
            -- can either player make a move yet?
            s.bot_cooldown = s.bot_cooldown - dt
            s.enemy_cooldown = s.enemy_cooldown - dt
            if s.bot_cooldown <= 0 or s.enemy_cooldown <= 0 then 
                time = time + dt
                break
            end
        end
    end
    
    s.time = time
    return s
end

-- get a list of possible actions for the user
function bot_carlsen_get_actions(s, user)
    local BOT = BOT_CARLSEN
    local new_redirect_action = bot_carlsen_new_redirect_action
    local new_send_action = bot_carlsen_new_send_action
    local new_pass_action = bot_carlsen_new_pass_action
    
    local actions = {}
    
    if user == BOT.user then
        if s.bot_cooldown > 0 then
            return actions
        end
    elseif user == BOT.enemy_user then
        if s.enemy_cooldown > 0 then
            return actions
        end
    else 
        print("wtf at line 287.")
    end    
    
    local pass_action = new_pass_action(user)
    table.insert(actions, pass_action)
    
    local planets = s.planets
    -- for each user planet
    for _i, source in pairs(planets) do
        if source.owner_n == user.n then
            -- for each neutral planet, attack with 1 extra ship
            -- TEMPORARY SOLUTION - THIS WILL PREVENT TWO PLANETS
            -- FROM ATTACKING A NEUTRAL TOGETHER
            for _j, target in pairs(planets) do
                if target.n ~= source.n then
                    -- MIN SHIPS TO SEND
                    for ships = BOT.send_incr, source.ships_value, BOT.send_incr do
                        local new_action = new_send_action(source, target, ships)
                        actions[#actions + 1] = new_action
                    end
                end
            end 
        end
    end
    
    -- for each user fleet
    
    return actions
end

-- issue the action a in state s
-- return the resulting state
function bot_carlsen_execute_action(s, a)
    if a.type == "redirect" then
        local fleet = g2.item(a.fleet.n)
        fleet:fleet_redirect(a.target.n)
    elseif a.type == "send" then
        local from = g2.item(a.source.n):owner()
        local source = g2.item(a.source.n)
        local target = g2.item(a.target.n)
        local ships = a.fleet.fleet_ships
        send_exact(from, source, target, ships)
    elseif a.type == "pass" then
    end
end

-- issue the action a in state s
-- return the resulting state
function bot_carlsen_issue_action(prev_s, a)
    local BOT = BOT_CARLSEN
    local s = deep_copy(prev_s)
    if a.type == "redirect" then
        local fleet = s.fleets[a.fleet.n]
        fleet.fleet_target = a.fleet_target
    elseif a.type == "send" then
        local n = a.fleet.n
        s.fleets[n] = a.fleet
        local source = s.planets[a.source.n]
        source.ships_value = source.ships_value - a.fleet.fleet_ships
    elseif a.type == "pass" then
    else
        print("Unrecognized action")
    end
    
    if a.type == "redirect" or a.type == "send" or a.type == "pass" then
        if a.user_n == BOT.user.n then
            s.bot_cooldown = BOT.min_cooldown
        elseif a.user_n == BOT.enemy_user.n then
            s.enemy_cooldown = BOT.min_cooldown
        else 
            print("wtf: 1 in bot_carlsen_issue_action")
        end
    elseif a.type == "pass" then
    else
        print("Unrecognized action")
    end         
    
    return s
end
