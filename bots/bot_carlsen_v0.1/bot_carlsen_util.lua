require("bot_util")

-- create a new send action representing source sending
-- ships ships to target
function bot_carlsen_new_send_action(source, target, ships)
    local next_n = bot_carlsen_next_n
    
    local fleet = {}
    fleet.owner_n = source.owner_n
    fleet.fleet_ships = ships
    fleet.fleet_target = target.n
    
    -- TEMPORARY.  EVENTALLY START FARTHER TO SIMULATE 
    -- TUNNELING
    fleet.position_x = source.position_x
    fleet.position_y = source.position_y
    
    ----- HAAAAAAAAAAAAAAACK FIX THIS
    fleet.n = next_n()
    
    local action = {}
    action.type = "send"
    action.fleet = fleet
    action.source = source
    action.target = target
    action.ships = fleet.fleet_ships
    action.user_n = source.owner_n
    return action
end

-- redirect a fleet to a new target
function bot_carlsen_new_redirect_action(fleet, target)
    fleet.fleet_target = target.n

    local action = {}
    action.type = "redirect"
    action.fleet = fleet
    action.target = target
    action.user_n = fleet.owner_n
    return action
end

-- redirect a fleet to a new target
function bot_carlsen_new_pass_action(user)
    local action = {}
    action.type = "pass"
    action.user_n = user.n
    return action
end


function bot_carlsen_get_start_state()
    local BOT = BOT_CARLSEN
    local s = {}
    
    local planets = bot_carlsen_clean_map(g2.search("planet"))
    s.planets = {}
    for _i,p in pairs(planets) do
        print("planet: "..p.n)
        local planet = {}
        planet.ships_production = p.ships_production
        planet.ships_production_enabled = p.ships_production_enabled
        planet.ships_value = p.ships_value
        planet.owner_n = p.owner_n
        planet.n = p.n
        planet.position_x = p.position_x
        planet.position_y = p.position_y
        planet.planet_r = p.planet_r
        s.planets[p.n] = planet
    end
    
    local fleets = g2.search("fleet")
    s.fleets = {}
    for _i,f in pairs(fleets) do
        local fleet = {}
        fleet.fleet_target = f.fleet_target
        fleet.fleet_ships = f.fleet_ships
        fleet.owner_n = f.owner_n
        fleet.n = f.n
        fleet.position_x = f.position_x
        fleet.position_y = f.position_y
        s.fleets[f.n] = fleet
    end
    
    s.time = os.clock()
    
    return s
end

function bot_carlsen_next_n()
    return math.floor(9999999999*math.random() + 1)
end

-- return the number of ships 
function bot_carlsen_sum_ships(s, user)
    local planets = s.planets
    local fleets = s.fleets
    
    local sum = 0
    
    for _i, planet in pairs(planets) do
        if planet.owner_n == user.n then
            sum = sum + planet.ships_value
        end
    end
    
    for _i, fleet in pairs(fleets) do
        if fleet.owner_n == user.n then
            sum = sum + fleet.fleet_ships
        end
    end
    
    return sum
end

-- assuming there are only two users, return
-- the user that is not "bot"
function bot_carlsen_get_enemy_user(bot)
    local users = g2.search("user")
    for _i, user in pairs(users) do
        if not user.user_neutral then
            if user.n ~= bot.n then
                return user
            end
        end 
    end
    print("Could not find enemy user.")
end

-- get rid of any planets not even worth considering
function bot_carlsen_clean_map(planets)
    local BOT = BOT_CARLSEN
    local horizon = get_horizon(planets)
    local new_map = {}
    for _i, planet in pairs(planets) do
        if planet:owner().user_neutral then
            if bot_carlsen_is_worth_considering(planet, horizon) then
                table.insert(new_map, planet)
            end
        else 
            table.insert(new_map, planet)
        end
    end
    return new_map
end

-- would this planet EVER be worth capturing in any 1v1 situation ever?
function bot_carlsen_is_worth_considering(planet, horizon)
    local cutoff = 0.5
    if prod_to_ships(planet.ships_production)*horizon < cutoff * planet.ships_value then 
        return false
    else
        return true
    end
end
