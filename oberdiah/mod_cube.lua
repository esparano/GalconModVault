-- GALCON 2 MODS STARTER KIT
-- by tinny

function init()
	OPTIONS = {
		screen_width = 1500,
		screen_height = 900,
	}
	GLOBAL = {
		planets = 10,
		count = 100,
		movingright = 0, -- What speed to move right with the camera; stores data between event and loop
		movingup = 0,
	}
    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
	PLANETS = {}
    main_menu()
end

function main_menu()
    g2.state = "menu"

    g2.html = [[
        <table>
            <tr><td><h1>The Cube</h1>
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

	g2.view_set(-1000, -1000, 2000, 2000)
    
	-- g2.new_planet(user, x_coords, y_coords, prod, ships)
	
    -- create individual planets
	
    for z=1,GLOBAL.planets do
		local plxy = {}
		for y=1,GLOBAL.planets do
			local plx = {}
			for x=1,GLOBAL.planets do
				if z == GLOBAL.planets/2 and y == GLOBAL.planets/2 and x == GLOBAL.planets/2 then
					plx[x] = g2.new_planet(player, (200*z-x*200/2*z)+z*100, (200*z-y*200/2*z)+z*100, z*30, 0);
				else
					plx[x] = g2.new_planet(neutral, (200*z-x*200/2*z)+z*100, (200*z-y*200/2*z)+z*100, z*30, 0);
				end
			end
			table.insert(plxy, plx)
		end
		table.insert(PLANETS, plxy)
	end
	--ZYX
end

function loop(t)
	if GLOBAL.movingright == 1 then
		for z=1,GLOBAL.planets do
			for y=1,GLOBAL.planets do
				for x=1,GLOBAL.planets do
					PLANETS[z][x][y].position_x = PLANETS[z][x][y].position_x - z
				end
			end
		end
	elseif GLOBAL.movingright == 2 then
		for z=1,GLOBAL.planets do
			for y=1,GLOBAL.planets do
				for x=1,GLOBAL.planets do
					PLANETS[z][x][y].position_x = PLANETS[z][x][y].position_x + z
				end
			end
		end
	elseif GLOBAL.movingup == 1 then
		for z=1,GLOBAL.planets do
			for y=1,GLOBAL.planets do
				for x=1,GLOBAL.planets do
					PLANETS[z][x][y].position_y = PLANETS[z][x][y].position_y - z
				end
			end
		end
	elseif GLOBAL.movingup == 2 then
		for z=1,GLOBAL.planets do
			for y=1,GLOBAL.planets do
				for x=1,GLOBAL.planets do
					PLANETS[z][x][y].position_y = PLANETS[z][x][y].position_y + z
				end
			end
		end
	end
end

function event(e)
	 if (e.type == "ui:motion" or e.type == "ui:down") then
		if e.x > 1490 then
			GLOBAL.movingright = 1
		elseif e.x < -1490 then
			GLOBAL.movingright = 2
		else
			GLOBAL.movingright = 0
		end

		if e.y > 990 then
			GLOBAL.movingup = 1
		elseif e.y < -990 then
			GLOBAL.movingup = 2
		else
			GLOBAL.movingup = 0
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
	GLOBAL.count = 100
    g2.game_reset();
	
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
	
    -- generate map code
    sk_mapGen(player, enemy, neutral)
end