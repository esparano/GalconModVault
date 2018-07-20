function bot_esparanbot_get_actions(start_s, target, user)
    local actions = {}
    -- for each planet, send 100% at the target
    for _i, source in pairs(start_s.planets) do
        if source.owner_n == user.n then 
            local action = bot_esparanbot_new_send_action(source, target, source.ships_value)
            table.insert(actions, action)
        end
    end      
    -- for each fleet, redirect to the target
    for _i, fleet in pairs(start_s.fleets) do
        if fleet.owner_n == user.n then 
            local action = bot_esparanbot_new_redirect_action(fleet, start_s.planets[fleet.fleet_target], target)
            table.insert(actions, action)
        end
    end   
    return actions
end

-- create a new send action representing source sending
-- ships ships to target
function bot_esparanbot_new_send_action(source, target, ships)
    local fleet = {}
    fleet.owner_n = source.owner_n
    fleet.fleet_ships = ships
    fleet.fleet_target = target.n
    
    -- start fleet at edge of planet to simulate tunneling
    local a = math.atan2(target.position_y - source.position_y, target.position_x - source.position_x)
    fleet.position_x = source.position_x + source.planet_r*math.cos(a)
    fleet.position_y = source.position_y + source.planet_r*math.sin(a)
    
    ----- HAAAAAAAAAAAAAAACK FIX THIS
    fleet.n = 5000
    
    local action = {}
    action.type = "send"
    action.fleet = fleet
    action.source = source
    action.target = target
    action.ships = fleet.fleet_ships
    return action
end

-- redirect a fleet to a new target
function bot_esparanbot_new_redirect_action(fleet, old_target, new_target)
    local action = {}
    action.type = "redirect"
    action.fleet = fleet
    action.old_target = old_target
    action.new_target = new_target
    return action
end

-- issue the action a in state s
-- return the resulting state
function bot_esparanbot_execute_action(a)
    if a.type == "redirect" then
        local fleet = g2.item(a.fleet.n)
        fleet:fleet_redirect(g2.item(a.new_target.n))
    elseif a.type == "send" then
        local from_user = g2.item(a.source.n):owner()
        local source = g2.item(a.source.n)
        local target = g2.item(a.target.n)
        local ships = a.fleet.fleet_ships
        send_exact(from_user, source, target, ships)
    end
end

-- issue the action a in state s
-- return the resulting state
function bot_esparanbot_apply_action(s, a)
    if a.type == "redirect" then
        --[[
        local fleet = s.fleets[a.fleet.n]
        fleet.fleet_target = a.fleet_target
        --]]
    elseif a.type == "send" then
        s.fleets[a.fleet.n] = a.fleet
        local source = s.planets[a.source.n]
        source.ships_value = source.ships_value - a.fleet.fleet_ships
        table.insert(s.incoming_fleets[a.target.n], a.fleet)
        table.sort(s.incoming_fleets[a.target.n], function(f1,f2) if f1 ~= nil and f2 ~= nil then if g2.distance(a.target, f1) < g2.distance(a.target, f2) then return true end end end)
    end
end

-- instead of resimulating entire game, find the incremental difference by only examining the affected planets
function bot_esparanbot_return_on_action(s, action, horizon, user)
    if action.type == "redirect" then
        return bot_esparanbot_return_on_redirect(s, action, horizon, user)
    elseif action.type == "send" then
        return bot_esparanbot_return_on_send(s, action, horizon, user)
    end
end

function bot_esparanbot_return_on_redirect(s, action, horizon, user)
    local t_max = horizon
    
    -- FIGURE OUT BASELINE SHIPS ON THE AFFECTED PLANETS
    local baseline = 0
    
    for i=1,2 do
        -- target planet
        local time = 0
        local target
        if i == 1 then target = action.old_target else target = action.new_target end
        local target_ships_value = target.ships_value
        local target_owner_n = target.owner_n
        local target_ships_production_enabled = target.ships_production_enabled
        for _j, fleet in pairs(s.incoming_fleets[target.n]) do
            local new_time = dist_to_time(g2.distance(target, fleet))
            if target_ships_production_enabled then
                target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (new_time - time)
            end
            time = new_time
            if fleet.owner_n == target_owner_n then
                target_ships_value = target_ships_value + fleet.fleet_ships
            else
                local diff = target_ships_value - fleet.fleet_ships
                if diff < 0 then
                    target_owner_n = fleet.owner_n
                    target_ships_value = -diff
                    target_ships_production_enabled = true
                else
                    target_ships_value = diff
                end
            end
        end
        if time < t_max then
            if target_ships_production_enabled then
                target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (t_max - time)
            end
        end
        
        -- update baseline
        if target_owner_n == user.n then 
            baseline = baseline + target_ships_value
        else
            baseline = baseline - target_ships_value
        end
    end
    
    -- NOW FIGURE OUT EFFECT OF ACTION
    local result = 0
    
    -- old target planet
    local time = 0
    local target = action.old_target
    local target_ships_value = target.ships_value
    local target_owner_n = target.owner_n
    local target_ships_production_enabled = target.ships_production_enabled
    for _j, fleet in pairs(s.incoming_fleets[target.n]) do
        -- fleet will no longer arrive at old target
        if fleet.n ~= action.fleet.n then 
            local new_time = dist_to_time(g2.distance(target, fleet))
            if target_ships_production_enabled then
                target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (new_time - time)
            end
            time = new_time
            if fleet.owner_n == target_owner_n then
                target_ships_value = target_ships_value + fleet.fleet_ships
            else
                local diff = target_ships_value - fleet.fleet_ships
                if diff < 0 then
                    target_owner_n = fleet.owner_n
                    target_ships_value = -diff
                    target_ships_production_enabled = true
                else
                    target_ships_value = diff
                end
            end
        end
    end
    if time < t_max then
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (t_max - time)
        end
    end
    
    -- update result
    if target_owner_n == user.n then 
        result = result + target_ships_value
    else
        result = result - target_ships_value
    end
    
    -- target planet (account for new incoming fleet)
    time = 0
    target = action.new_target
    target_ships_value = target.ships_value
    target_owner_n = target.owner_n
    target_ships_production_enabled = target.ships_production_enabled
    -- the new fleet sent
    local time_to_land = dist_to_time(g2.distance(target, action.fleet))
    local landed = false
    
    for _j, fleet in pairs(s.incoming_fleets[target.n]) do
        local new_time = dist_to_time(g2.distance(target, fleet))
        if not landed then
            -- insert the new fleet into planet's event timeline
            if time_to_land < new_time then
                landed = true
                if target_ships_production_enabled then
                    target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (time_to_land - time)
                end
                time = time_to_land
                if action.fleet.owner_n == target_owner_n then
                    target_ships_value = target_ships_value + action.fleet.fleet_ships
                else
                    local diff = target_ships_value - action.fleet.fleet_ships
                    if diff < 0 then
                        target_owner_n = action.fleet.owner_n
                        target_ships_value = -diff
                        target_ships_production_enabled = true
                    else
                        target_ships_value = diff
                    end
                end
            end
        end
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (new_time - time)
        end
        time = new_time
        if fleet.owner_n == target_owner_n then
            target_ships_value = target_ships_value + fleet.fleet_ships
        else
            local diff = target_ships_value - fleet.fleet_ships
            if diff < 0 then
                target_owner_n = fleet.owner_n
                target_ships_value = -diff
                target_ships_production_enabled = true
            else
                target_ships_value = diff
            end
        end
    end
    if not landed then
        -- insert the new fleet into planet's event timeline
        landed = true
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (time_to_land - time)
        end
        time = time_to_land
        if action.fleet.owner_n == target_owner_n then
            target_ships_value = target_ships_value + action.fleet.fleet_ships
        else
            local diff = target_ships_value - action.fleet.fleet_ships
            if diff < 0 then
                target_owner_n = action.fleet.owner_n
                target_ships_value = -diff
                target_ships_production_enabled = true
            else
                target_ships_value = diff
            end
        end    
    end
    if time < t_max then
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (t_max - time)
        end
    end
    -- update result
    if target_owner_n == user.n then 
        result = result + target_ships_value
    else
        result = result - target_ships_value
    end
    
    -- EFFECT OF ACTION
    local effect = result - baseline
    return effect
end

-- given a "send" action, how many ships are gained relative to baseline (no action at all)?
function bot_esparanbot_return_on_send(s, action, horizon, user)
    local t_max = horizon
    
    -- FIGURE OUT BASELINE SHIPS ON THE AFFECTED PLANETS
    local baseline = 0
    
    for i=1,2 do
        -- target planet
        local time = 0
        local target
        if i == 1 then target = action.source else target = action.target end
        local target_ships_value = target.ships_value
        local target_owner_n = target.owner_n
        local target_ships_production_enabled = target.ships_production_enabled
        for _j, fleet in pairs(s.incoming_fleets[target.n]) do
            local new_time = dist_to_time(g2.distance(target, fleet))
            if target_ships_production_enabled then
                target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (new_time - time)
            end
            time = new_time
            if fleet.owner_n == target_owner_n then
                target_ships_value = target_ships_value + fleet.fleet_ships
            else
                local diff = target_ships_value - fleet.fleet_ships
                if diff < 0 then
                    target_owner_n = fleet.owner_n
                    target_ships_value = -diff
                    target_ships_production_enabled = true
                else
                    target_ships_value = diff
                end
            end
        end
        if time < t_max then
            if target_ships_production_enabled then
                target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (t_max - time)
            end
        end
        
        -- update baseline
        if target_owner_n == user.n then 
            baseline = baseline + target_ships_value
        else
            baseline = baseline - target_ships_value
        end
    end
    
    -- NOW FIGURE OUT EFFECT OF ACTION
    local result = 0
    
    -- target planet (account for new incoming fleet)
    time = 0
    target = action.target
    target_ships_value = target.ships_value
    target_owner_n = target.owner_n
    target_ships_production_enabled = target.ships_production_enabled
    -- the new fleet sent
    local time_to_land = dist_to_time(g2.distance(target, action.fleet))
    local landed = false
    
    for _j, fleet in pairs(s.incoming_fleets[target.n]) do
        local new_time = dist_to_time(g2.distance(target, fleet))
        if not landed then
            -- insert the new fleet into planet's event timeline
            if time_to_land < new_time then
                landed = true
                if target_ships_production_enabled then
                    target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (time_to_land - time)
                end
                time = time_to_land
                if action.fleet.owner_n == target_owner_n then
                    target_ships_value = target_ships_value + action.fleet.fleet_ships
                else
                    local diff = target_ships_value - action.fleet.fleet_ships
                    if diff < 0 then
                        target_owner_n = action.fleet.owner_n
                        target_ships_value = -diff
                        target_ships_production_enabled = true
                    else
                        target_ships_value = diff
                    end
                end
            end
        end
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (new_time - time)
        end
        time = new_time
        if fleet.owner_n == target_owner_n then
            target_ships_value = target_ships_value + fleet.fleet_ships
        else
            local diff = target_ships_value - fleet.fleet_ships
            if diff < 0 then
                target_owner_n = fleet.owner_n
                target_ships_value = -diff
                target_ships_production_enabled = true
            else
                target_ships_value = diff
            end
        end
    end
    if not landed then
        -- insert the new fleet into planet's event timeline
        landed = true
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (time_to_land - time)
        end
        time = time_to_land
        if action.fleet.owner_n == target_owner_n then
            target_ships_value = target_ships_value + action.fleet.fleet_ships
        else
            local diff = target_ships_value - action.fleet.fleet_ships
            if diff < 0 then
                target_owner_n = action.fleet.owner_n
                target_ships_value = -diff
                target_ships_production_enabled = true
            else
                target_ships_value = diff
            end
        end    
    end
    if time < t_max then
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (t_max - time)
        end
    end
    -- update result
    if target_owner_n == user.n then 
        result = result + target_ships_value
    else
        result = result - target_ships_value
    end
    
    -- source planet
    time = 0
    target = action.source
    target_ships_value = target.ships_value - action.fleet.fleet_ships -- should be >= 0
    if target_ships_value < 0 then error("WTF NEGATIVE SHIPS") end
    target_owner_n = target.owner_n
    target_ships_production_enabled = target.ships_production_enabled
    for _j, fleet in pairs(s.incoming_fleets[target.n]) do
        local new_time = dist_to_time(g2.distance(target, fleet))
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (new_time - time)
        end
        time = new_time
        if fleet.owner_n == target_owner_n then
            target_ships_value = target_ships_value + fleet.fleet_ships
        else
            local diff = target_ships_value - fleet.fleet_ships
            if diff < 0 then
                target_owner_n = fleet.owner_n
                target_ships_value = -diff
                target_ships_production_enabled = true
            else
                target_ships_value = diff
            end
        end
    end
    if time < t_max then
        if target_ships_production_enabled then
            target_ships_value = target_ships_value + prod_to_ships(target.ships_production) * (t_max - time)
        end
    end
    
    -- update result
    if target_owner_n == user.n then 
        result = result + target_ships_value
    else
        result = result - target_ships_value
    end
    
    -- EFFECT OF ACTION
    local effect = result - baseline
    return effect
end
