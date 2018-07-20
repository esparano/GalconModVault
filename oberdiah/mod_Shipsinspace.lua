-- GALCON 2 MODS STARTER KIT
-- by tinny

function init()
	OPTIONS = {
	}
	GLOBAL = {
		count = 0
	}
	LABELS = {
	}
	FLEETS = {
	1
	}
    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
	ssave = {}
    main_menu()
end

function main_menu()
    g2.state = "menu"

    g2.html = [[
        <table>
            <tr><td><h1>Ships in space</h1>
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
        <tr><td><h1>:D</h1>
    ]] .. sk_menu()
end

function init_lose() 
    g2.html = [[
        <table>
        <tr><td><h1>D:</h1>
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
    g2.new_planet(player, -200, -200, 100, 100)
    g2.new_planet(enemy, 200, 200, 200, 100)
	
	
end

function loop(t)

	if GLOBAL.reset == true then
		superreset()
	end
	
	local planets= g2.search("planet owner:"..GLOBAL.player)
	local fleets = g2.search("fleet owner:"..GLOBAL.player)
	local eplanets= g2.search("planet owner:"..GLOBAL.enemy)
	
	if FLEETS then
		for i=1,#FLEETS do
			FLEETS[i] = nil
		end
		fleets = g2.search("fleet owner:"..GLOBAL.player)
		for _i,fleet in ipairs(fleets) do
			if fleet:selected() then
				table.insert(FLEETS, fleet)
			end
		end
	end
	
	GLOBAL.selected = false
	for _i,planet in ipairs(planets) do
		if planet:selected() then
			GLOBAL.selected = true
		end
	end
	
	GLOBAL.reset = false
	for i=1,#LABELS do
		fleets = g2.search("fleet owner:"..GLOBAL.player)
		local label = LABELS[i]
		for _i,fleet in ipairs(fleets) do
			if fleet.position_x > label.x - 10 and fleet.position_x < label.x + 10 and fleet.position_y > label.y - 10 and fleet.position_y < label.y + 10 and label.label.n == fleet.fleet_target then
				GLOBAL.player.fleet_v_factor = 0
				g2.new_fleet(GLOBAL.player, 1, fleet, planets[1])
				fleet:destroy()
				GLOBAL.player.fleet_v_factor = 1
			end
		end
	end
	
	if #planets == 0 and #fleets == 0 then
		init_lose()
		g2.state = "pause"
	elseif #eplanets == 0 then
		init_win()
		g2.state = "pause"
	end
end


function event(e)
	GLOBAL.ping = true
	if GLOBAL.selected == false and e["type"] == "ui:down" then
		if FLEETS then
			local planets= g2.search("planet")
			for i=1,#FLEETS do
				local sendto = nil
				for _i,p in ipairs(planets) do
					local n = p.ships_production/3
					if e.x > p.position_x - n and e.x < p.position_x + n and e.y > p.position_y - n and e.y < p.position_y + n then
						sendto = p
					end
				end
				if sendto ~= nil then
					g2.new_fleet(GLOBAL.player, 1, FLEETS[i], sendto)
					FLEETS[i]:destroy()
					FLEETS[i] = nil
				else
					local l = {}
					l.label = g2.new_label("", e.x, e.y, COLORS[5])
					l.x = e.x
					l.y = e.y
					table.insert(LABELS, l)
					g2.new_fleet(GLOBAL.player, 1, FLEETS[i], l.label)
					FLEETS[i]:destroy()
					FLEETS[i] = nil
				end
			end
		end
	end

	if GLOBAL.init == true then
		local planets= g2.search("planet owner:"..GLOBAL.player)
		for _i,planet in ipairs(planets) do
			if e["type"] == "ui:down" and planet:selected() then
				local l = {}
				l.label = g2.new_label("", e.x, e.y, COLORS[5])
				l.x = e.x
				l.y = e.y
				table.insert(LABELS, l)
				for i = 1,planet.ships_value/2 do
					g2.new_fleet(GLOBAL.player, 1, planet, l.label)
				end
				planet.ships_value = planet.ships_value/2
			end
		end
	end
	
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
	for i=1,#LABELS do
		LABELS[i] = nil
	end
	
	
	GLOBAL.circle = nil
	
	GLOBAL.init = true
	
    g2.game_reset();
	g2.bkgr_src = "background01"
    -- set up users
	local neutral = g2.new_user("neutral", 0x999999)
	neutral.user_neutral = 1
	neutral.ships_production_enabled = 0
	GLOBAL.neutral = neutral
	
	local player = g2.new_user("player", 0x00FF00)
	g2.player = player
	GLOBAL.player = player
		
	local enemy = g2.new_user("bot", 0xFF0000)
	GLOBAL.enemy = enemy
	
    -- generate map
    sk_mapGen(player, enemy, neutral)
    g2.planets_settle()
end



















































































function saving()
	local fleets = g2.search("fleet")
	local planets = g2.search("planet")
	local fleetsave = {}
	for _i,v in ipairs(fleets) do
		local s = {}
		if v.owner == GLOBAL.player then
			s.pl = "p"
		elseif v.owner == GLOBAL.enemy then
			s.pl = "e"
		elseif v.owner == GLOBAL.neutral then
			s.pl = "n"
		end
		s.to = v.fleet_target
		s.x = v.position_x
		s.y = v.position_y
		table.insert(fleetsave, s)
	end
	local planetsave = {}
	for _i,v in ipairs(planets) do
		local s = {}
		if v:owner().n == GLOBAL.player.n then
			s.pl = "p"
		elseif v:owner().n == GLOBAL.enemy.n then
			s.pl = "e"
		elseif v:owner().n == GLOBAL.neutral.n then
			s.pl = "n"
		end
		s.x = v.position_x
		s.y = v.position_y
		s.prod = v.ships_production
		s.val = v.ships_value
		table.insert(planetsave, s)
	end
	ssave.fleet = fleetsave
	ssave.planet = planetsave
end

function superreset()
	
	GLOBAL.circle = nil
	
	
	g2.game_reset();
	g2.bkgr_src = "background01"
	------------------------------------------------------------------------
	local neutral = g2.new_user("neutral", 0x999999)
	neutral.user_neutral = 1
	neutral.ships_production_enabled = 0
	GLOBAL.neutral = neutral
	
	local player = g2.new_user("player", 0x00FF00)
	g2.player = player
	GLOBAL.player = player
		
	local enemy = g2.new_user("bot", 0xFF0000)
	GLOBAL.enemy = enemy
	------------------------------------------------------------------------
	-- Loading
	
	for i = 1,#ssave.planet do
		local p = ssave.planet[i]
		local user
		if p.pl == "p" then
			user = GLOBAL.player
		elseif p.pl == "e" then
			user = GLOBAL.enemy
		elseif p.pl == "n" then
			user = GLOBAL.neutral
		end
		g2.new_planet(user, p.x, p.y, p.prod, p.val)
	end
	
	
	
	
end
