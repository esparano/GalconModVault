-- GALCON 2 MODS STARTER KIT
-- by tinny

function init()
	OPTIONS = {
	}
	GLOBAL = {
		count = 0
	}
    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
	FLAG = {
	}
    main_menu()
end

function main_menu()
    g2.state = "menu"

    g2.html = [[
        <table>
            <tr><td><h1>CTF</h1>
            <tr><td><p>By Oberdiah</p>
            <tr><td><input type='button' value='Start' onclick='newmap' />
        </table>
    ]]
	
end

function init_getready()
    g2.html = [[
        <table>
        <tr><td><input type='button' value='Start' onclick='resume' />
    ]]
end

function init_paused()
    g2.html = [[
        <table>
        <tr><td><input type='button' value='Resume' onclick='resume' />
    ]] .. sk_menu()
end

function init_win() 
  	g2.html = [[
        <table>
        <tr><td><h1>Congratulations!</h1>
    ]] .. sk_menu()
end

function init_lose() 
    g2.html = [[
        <table>
        <tr><td><h1>Well, at least you tried.</h1>
    ]] .. sk_menu()
end

function sk_menu()
    return [[
        <table>
        <tr><td><input type='button' value='New Map' onclick='newmap' />
        <tr><td><input type='button' value='Quit' onclick='quit' />
    ]]
end

-- generate the map
function sk_mapGen(player, enemy, neutral)

    -- g2.new_planet(user, x_coords, y_coords, prod, ships)
	
    -- create individual planets
    g2.new_planet(player, -200, -200, 200, 100)
    g2.new_planet(enemy, 200, 200, 200, 100)
	
    for i=1,20 do
    	planet = g2.new_planet(neutral, math.random(-200,200), math.random(-200,200), math.random(10,150), math.random(0,50));
	end
	FLAG.flag = g2.new_planet(neutral, 0, 0, 100, 0);
	FLAG.planet = true
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

function prodtoradius(prod)
    local radius = (prod - 15)*3/17 + 15
    if radius < 15 then radius = 15 end
	return radius
end

function loop(t)
	local planets= g2.search("planet owner:"..GLOBAL.player)
	local fleets = g2.search("fleet owner:"..GLOBAL.player)
	local eplanets= g2.search("planet owner:"..GLOBAL.enemy)
	
	if #planets == 0 and #fleets == 0 then
		init_lose()
		g2.state = "pause"
	elseif #eplanets == 0 then
		init_win()
		g2.state = "pause"
	end


	local new_fleets = g2.search("fleet")
	local flagexists = false
	for _i,fleet in ipairs(new_fleets) do
		if fleet == FLAG.flag then
			flagexists = true
			if g2.item(fleet.fleet_target):owner() == fleet:owner() and fleet.fleet_ships < FLAG.oldflag then
				FLAG.flag = g2.item(fleet.fleet_target)
				FLAG.planet = true
			end
		end
		if is_new_fleet(fleet) then
			if g2.distance(fleet, FLAG.flag) < prodtoradius(FLAG.flag.ships_production) and FLAG.planet == true then
				FLAG.flag = fleet
				FLAG.planet = false
				FLAG.goingto = nil
			end
		end
	end
	
	if FLAG.planet == false and flagexists == false and FLAG.goingto then
		if g2.distance(g2.item(FLAG.goingto), GLOBAL.flaglabel) < prodtoradius(g2.item(FLAG.goingto).ships_production) + 10 then
			FLAG.flag = g2.item(FLAG.goingto)
			FLAG.planet = true
		else
			print("Ping!")
			local closest
			local distance = -math.huge
			for _i,fleet in ipairs(eplanets) do
				if g2.distance(fleet,GLOBAL.flaglabel) < distance then
					closest = fleet
				end
			end
			FLAG.flag = closest
		end
	end
	
	if FLAG.planet == false then
		if GLOBAL.flaglabel then
			GLOBAL.flaglabel:destroy()
		end
		GLOBAL.flaglabel = g2.new_label("", FLAG.flag.position_x, FLAG.flag.position_y)
		FLAG.goingto = FLAG.flag.fleet_target
		FLAG.oldflag = FLAG.flag.fleet_ships
	end
	FLAG.old_fleets = new_fleets

	if GLOBAL.back == false then GLOBAL.count = GLOBAL.count + 1 else GLOBAL.count = GLOBAL.count - 1 end
	if GLOBAL.circle then GLOBAL.circle:destroy() end
	GLOBAL.circle = g2.new_circle(FLAG.flag:owner().render_color,FLAG.flag.position_x,FLAG.flag.position_y,GLOBAL.count)
	if FLAG.planet == true then
		if GLOBAL.count > prodtoradius(FLAG.flag.ships_production)+ 10 then GLOBAL.back = true end
		if GLOBAL.count < prodtoradius(FLAG.flag.ships_production) then GLOBAL.back = false end
	else
		if GLOBAL.count > 20 then GLOBAL.back = true end
		if GLOBAL.count < 10 then GLOBAL.back = false end
	end
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local from_planets = g2.search("planet owner:"..GLOBAL.enemy)
	local from_fleets = g2.search("fleet owner:"..GLOBAL.enemy)
	local best_value = -math.huge
	local from
	local from_planet = true
	for _i,planet in ipairs(from_planets) do
		if planet.ships_value > best_value then 
			from = planet
			best_value = planet.ships_value
			from_planet = true
		end
	end
	for _i,fleet in ipairs(from_fleets) do
		if fleet.fleet_ships > best_value then 
			from = fleet
			best_value = fleet.fleet_ships
			from_planet = false
		end
	end
	if from ~= nil then -- make sure a planet to attack from was found
		local to_planets = g2.search("planet -team:"..GLOBAL.enemy:team())
		best_value = -math.huge
		local to
		for _i,planet in ipairs(to_planets) do
			local value = -planet.ships_value + planet.ships_production - planet:distance(from)/5
			if value > best_value then
				to = planet
				best_value = value
			end
		end
		if to ~= nil and from_planet == true then from:fleet_send(100, to) end
		if to ~= nil and from_planet == false then from:fleet_redirect(to) end
	end
end

function event(e)
	if e["type"] == "onclick" and e["value"] then
        if e["value"] == "newmap" then
            init_game();
            init_getready();
            g2.state = "pause"
		elseif (e["value"] == "restart") then
			main_menu()
        elseif (e["value"] == "resume") then
            g2.state = "play"
        elseif (e["value"] == "quit") then
            g2.state = "quit"
        end
    elseif e["type"] == "pause" then
        init_paused();
        g2.state = "pause"
    end
end

function init_game()

	GLOBAL.flaglabel = nil
	GLOBAL.circle = nil
	GLOBAL.count = 0
	
    g2.game_reset();
	
    -- set up users
	local neutral = g2.new_user("neutral", 0x999999)
	neutral.user_neutral = 1
	neutral.ships_production_enabled = 0
	GLOBAL.neutral = neutral
	
	local player = g2.new_user("player", 0x00FF00)
	g2.player = player
	GLOBAL.player = player
	player.fleet_crash = 100
		
	local enemy = g2.new_user("bot", 0xFF0000)
	GLOBAL.enemy = enemy
	enemy.fleet_crash = 100
	
    -- generate map
    sk_mapGen(player, enemy, neutral)
    g2.planets_settle()
end