require("bot_util")
require("bot_esparanbot_map")
require("bot_esparanbot_constants")
require("bot_esparanbot_eval")
require("bot_esparanbot_action")

-- initialize bot(s) - call once even if multiple bots
function init_esparanbot()
    global("BOT_ESPARANBOT")
    BOT_ESPARANBOT = BOT_ESPARANBOT or {}
    
    global("DEBUG")
    DEBUG = true
end

-- reset bot(s) before EVERY game - call once even if multiple bots
function reset_esparanbot()
    BOT_ESPARANBOT = {}
end

-- first-turn setup.  return a reference to the bot data
function first_turn_setup(user)
    BOT_ESPARANBOT[user.n] = {}
    local bot = BOT_ESPARANBOT[user.n]
    
    -- get neutral user
    bot.neutral_user = bot.neutral_user or bot_esparanbot_get_user_neutral()
    
    -- get the map.  It is assumed that the map never changes until the end of the game.
    bot.map = bot.map or bot_esparanbot_get_map()
    
    if (DEBUG) then 
        debug_view(user, "n")
    end
    
    return bot
end

-- print a label below each planet of the planet's property
function debug_view(user, property, offset)
    offset = offset or 0
    local bot = BOT_ESPARANBOT[user.n]
    for _i, planet in pairs(bot.map.planets) do
        local s = tostring(planet[property])
        g2.new_label(s, planet.position_x, planet.position_y + 30 + offset)
    end 
end

-- bot loop called every tick
function bot_esparanbot(user)
    -- first-turn setup?
    local bot = BOT_ESPARANBOT[user.n] or first_turn_setup(user) 
    
    -- update planet ownership
    --[[
    for i,planet in pairs(bot.map.planets) do
        planet.owner_n = g2.item(planet.n).owner_n
    end
    --]]
    
    -- compute optimal tunnels
    --bot_esparanbot_compute_tunnels(user)  ----------- EXPENSIVE
    
    -- TEST TUNNELS
    --[[  
    local path = ""
    local tunnel = bot.map.planets[4].tunnel[5]
    for k,v in pairs(tunnel) do
        path = path .. v.n .. " "
    end
    g2.status = path
    --]]
    
    -- TEST TUNNEL DISTANCE
    --g2.status = bot.map.planets[4].tunnel_dist[5]
    
    -- TEST EVAL FUNCTION
    --[[
    local g = bot_esparanbot_get_start_state()
    local eval = "" .. bot_esparanbot_eval1(g, user)
    g2.status = eval
    --]]
    
    -- TEST COPY PLANET
    --[[
    local planets = g2.search("planet")
    for i,p in pairs(planets) do
        local copy = copy_planet(p)
        for k,v in pairs(copy) do
            print(k)
            print(v)
        end
    end
    --]]
    
    local horizon = 30
    
    -- simulate the base case (no movement) in order to compare to future plans
    local start_s = bot_esparanbot_get_start_state()
    local e = copy_state(start_s)
    bot_esparanbot_simulate(e, horizon)
    local base_eval = bot_esparanbot_eval1(e, user)

    ---[[
    -- see if any other actions result in a better eval.  
    local best_eval = base_eval
    local best_action = nil
    -- for each planet, come up with an invasion plan for that planet
    for _i, target in pairs(start_s.planets) do
        local actions = bot_esparanbot_get_actions(start_s, target, user)
        for _i, action in pairs(actions) do
            -- apply the action, simulate forward and see the resulting eval
            local result_eval = bot_esparanbot_return_on_action(start_s, action, horizon, user) + base_eval
            
            -- Does incremental update (for optimization) produce same effect as slower, full simulation?
            --[[
            local e = copy_state(start_s)
            bot_esparanbot_apply_action(e, action)
            bot_esparanbot_simulate(e, horizon)
            local result_eval_using_full_sim = bot_esparanbot_eval1(e, user)
            
            --print("sim_eval: " .. math.floor(results_eval_using_full_sim) .. " result_eval: " .. math.floor(result_eval) .. " base_eval: " .. math.floor(base_eval))
            --]]
            --]]
            
            if math.floor(result_eval) > math.floor(best_eval) then
                best_eval = result_eval
                best_action = action
            end
        end
    end
    --]]
    -- execute the best action
    if best_action ~= nil then
        --g2.status = "Base eval: "..base_eval..", best eval: "..best_eval
        bot_esparanbot_execute_action(best_action)
    end
end


-- run the game from s until t_max (seconds into the future) has been reached OR until all fleets have landed
-- return the reached state
function bot_esparanbot_simulate(s, desired_t_max)
    -- figure out time it takes to land all fleets  THIS SHOULD NEVER EVER BE RUN.
    local t_max = desired_t_max
    
    --[[
    for _i, planet in pairs(s.planets) do
        local time = 0
        for _j, fleet in pairs(s.incoming_fleets[planet.n]) do
            local new_time = dist_to_time(g2.distance(planet, fleet))
            if new_time > t_max then t_max = new_time; print("EXCEEDED HORIZON IN SIMULATE") end
        end
    end
    --]]
    
    -- land all fleets
    for _i, target in pairs(s.planets) do
        local time = 0
        for _j, fleet in ipairs(s.incoming_fleets[target.n]) do
            -- fast-forward until the fleet lands
            local new_time = dist_to_time(g2.distance(target, fleet))
            -- update production
            target.ships_value = future_ships(target, new_time - time)
            time = new_time
            
            -- update ships as fleet lands on planet
            if fleet.owner_n == target.owner_n then
                target.ships_value = target.ships_value + fleet.fleet_ships
            else
                local diff = target.ships_value - fleet.fleet_ships
                --print(fleet.owner_n .. " " .. target.owner_n .. " " .. diff)
                -- change ownerships
                if diff < 0 then
                    target.owner_n = fleet.owner_n
                    target.ships_value = -diff
                    target.ships_production_enabled = true
                else
                    target.ships_value = diff
                end
            end
        end
        -- run until t_max
        if time < t_max then
            target.ships_value = future_ships(target, t_max - time)
        end
    end
    s.fleets = {}
end


function error(string)
    print("Esparanbot: Fatal Error: " .. string)
end

function warning(string)
    if DEBUG then
        print("Esparanbot: Warning: " .. string)
    end
end