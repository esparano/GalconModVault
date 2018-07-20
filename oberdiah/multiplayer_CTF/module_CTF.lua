function galcon_CTF_init()
    local G = GAME.galcon
    math.randomseed(os.time())
    
    g2.game_reset();
    
    local o = g2.new_user("neutral",0x555555)
    o.user_neutral = 1
    o.ships_production_enabled = 0
    G.neutral = o
    
    local t1 = g2.new_team("Team 1", 0xff0000)
    local t2 = g2.new_team("Team 2", 0x0000ff)
    
    local users = {}
    G.users = users

    local team = true
    for uid,client in pairs(GAME.clients) do
        if client.status == "play" then
            local p
            if team then
                p = g2.new_user(client.name,client.color, t1)
            else
                p = g2.new_user(client.name,client.color, t2)
            end
            team = not team
            p.fleet_crash = 100
            users[#users+1] = p
            p.user_uid = client.uid
            client.live = 0
        end
    end

    local sw = 600
    local sh = 599
    
    local i = 0
    while i < 23 do
        local x = math.random(0,sw)
        local y = math.random(0,sh)
        local prod = math.random(15, 20)
        local ships = 0
        if (y/sh > math.abs(x - sw/2)/(sw/2)) then
            local p = g2.new_planet(G.neutral, x, y, prod, ships)
            p = g2.new_planet(G.neutral, sw - x, y, prod, ships)
            i = i + 2
        end
    end
    FLAG.flag = g2.new_planet(G.neutral, sw/2, 0, 200, 0)
    FLAG.flag.ships_production_enabled = false
    FLAG.flag.ships_production = 0
	FLAG.planet = true
    
    local a = math.random(0,360)
    local first_user
    local last_user
    for i,user in pairs(users) do
        local first_user = first_user or user
        local last_user = user
        local x,y
        x = 1*math.cos(a*math.pi/180.0)
        if user:team() == t2 then
            x = x + sw
        end
        y = sh + 1*math.sin(a*math.pi/180.0)
        g2.new_planet(user, x,y, 100, 100);
        a = a + 360/#users
    end
    
    g2.planets_settle(0,0,sw,sh)
    g2.net_send("","sound","sfx-start");

    local r = g2.search("planet")
end

function galcon_CTF_loop()
    local G = GAME.galcon
    local r = count_production()
    local total = 0
    for k,v in pairs(r) do total = total + 1 end
    if #G.users <= 1 and total == 0 then
        galcon_stop(false)
    end
    if #G.users > 1 and total <= 1 then
        galcon_stop(true)
    end
end

function is_new_fleet(test_fleet)
    if not FLAG.old_fleets then return true end
    for _i,fleet in ipairs(FLAG.old_fleets) do
        if test_fleet.n == fleet.n then
            return false
        end
    end
    return true
end

function prod_to_radius(prod)
    local radius = (prod - 15)*3/17 + 15
    if radius < 15 then radius = 15 end
	return radius
end