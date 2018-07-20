-- GALCON 2 MODS STARTER KIT
-- by tinny

function init()
	OPTIONS = {
	}
	GLOBAL = {
		uion = false,
		count = 0,
		uix = 0,
		uiy = 0,
	}
	PLANETSGONE = {
	}
	LINES = {
	}
	BUTTONS = {
	}
	LABELS = {
	}
    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
	
    main_menu()
end

function main_menu()
    g2.state = "menu"

    g2.html = [[
        <table>
            <tr><td><h1>Click or Die</h1>
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

	g2.view_set(-250, -250, 500, 500)
	
    -- g2.new_planet(user, x_coords, y_coords, prod, ships)
	
    -- create individual planets
	local pp = g2.new_planet(player, -200, -100, 200, 1000)
    local ep = g2.new_planet(enemy, 200, 200, 200, 100)
	
	pp.ships_production_enabled = false
	ep.ships_production_enabled = false
	
    for i=1,20 do
    	planet = g2.new_planet(neutral, math.random(-300,300), math.random(-200,200), math.random(10,150), math.random(0,50));
	end
	
	GLOBAL.coinslbl = g2.new_label("100 Gold", 250, -200, 0xffffff)
	GLOBAL.coins = 100
end

-- (Start x, start y, end x, end y, delay)
Linestodraw = {
	{0, 0, 200, 0, 0},
	{0, 0, 0, 200, 0},
	{200, 0, 200, 200, 200},
	{0, 200, 200, 200, 200},
}

function loop(t)
	local nplanets= g2.search("planet owner:"..GLOBAL.neutral)
	
	if GLOBAL.uion == true then
		--[[
		for _i,planet in ipairs(nplanets) do
			local info = {}
			info.positionx = planet.position_x
			info.positiony = planet.position_y
			info.ships = planet.ships_value
			info.production = planet.ships_production
			table.insert(PLANETSGONE, info)
			planet:destroy()
		end
		]]--
	end
	
	GLOBAL.coinslbl.label_text = GLOBAL.coins .. " Coins"
	if GLOBAL.uion == true then
		LABELS[1].label_text = "Ships: ".. string.format("%.0f", GLOBAL.planetselected.ships_value)
	end
	
	if GLOBAL.counter == true then
		GLOBAL.count = GLOBAL.count + 10
	end
	
	local planets= g2.search("planet owner:"..GLOBAL.player)
	
	for _i,planet in ipairs(planets) do
		if planet:selected() then
			GLOBAL.selected = true
			if GLOBAL.uion ~= true then
				local pp = g2.new_planet(GLOBAL.player, planet.position_x, planet.position_y, planet.ships_production, planet.ships_value);
				pp.ships_production_enabled = false
				GLOBAL.planetselected = pp
				
				local x = planet.position_x + 20
				local y = planet.position_y + 20
				GLOBAL.uix = x
				GLOBAL.uiy = y
				for i,v in pairs(Linestodraw) do
					local line = {}
					line.x = v[1] + x
					line.y = v[2] + y
					line.line = g2.new_line(0xffffff, v[1] + x, v[2] + y, v[1] + x, v[2] + y)
					line.xmoveto = v[3] + x
					line.ymoveto = v[4] + y
					line.percentage = 0
					line.delay = v[5]
					table.insert(LINES, line)
				end
				
				planet:destroy()
				GLOBAL.counter = true
			else
				local pp = g2.new_planet(GLOBAL.player, planet.position_x, planet.position_y, planet.ships_production, planet.ships_value);
				pp.ships_production_enabled = false
				GLOBAL.planetselected = pp
				
				planet:destroy()
			end
		end
		
		-- Removing Stuff ------------------------------
		
		if GLOBAL.selected == false then
			if GLOBAL.uion == true then
				--[[
				for i,v in pairs(PLANETSGONE) do
					g2.new_planet(GLOBAL.neutral, v.positionx, v.positiony, v.production, v.ships)
					PLANETSGONE[i] = nil
				end
				]]--
				GLOBAL.uion = false
				GLOBAL.counter = false
				GLOBAL.uiimage:destroy()
				GLOBAL.uiimage = nil
				for i in pairs(LINES) do
					local line = LINES[i]
					line.line:destroy()
					LINES[i] = nil
				end
				for i,v in pairs(BUTTONS) do
					v:destroy()
					v = nil
				end
				for i,v in pairs(LABELS) do
					v:destroy()
					v = nil
				end
			end
		end
	end
	
	if GLOBAL.count > 400 then
		GLOBAL.uion = true
		GLOBAL.count = 0
		GLOBAL.counter = false
		GLOBAL.uiimage = g2.new_image("gui-box",GLOBAL.uix,GLOBAL.uiy,200,200)
		GLOBAL.uiimage.render_alpha = 15
		BUTTONS[1] = g2.new_image("gui-selection",GLOBAL.uix + 25,GLOBAL.uiy + 25,150,25)
		LABELS[1] = g2.new_label("Ships: ".. string.format("%.0f", GLOBAL.planetselected.ships_value),GLOBAL.uix + 65,GLOBAL.uiy + 37,0xffffff)
		
		BUTTONS[2] = g2.new_image("gui-icon4",GLOBAL.uix + 105,GLOBAL.uiy + 27,31,22)
		LABELS[2] = g2.new_label("+  3 Gold",GLOBAL.uix + 147,GLOBAL.uiy + 37,0xffffff)
	end
	
	if GLOBAL.uiimage ~= nil then
		if GLOBAL.uiimage.render_alpha < 255 then
			GLOBAL.uiimage.render_alpha = GLOBAL.uiimage.render_alpha + 20
		end
	end
	
	if LINES[1] ~= nil then
		for i=1,#LINES do
			local line = LINES[i]
			if line.percentage < 1 then
				if line.delay < 0 then
					line.percentage = line.percentage + 0.05
					line.line:destroy()
					line.line = g2.new_line(0xffffff, line.x, line.y, line.x + ((line.xmoveto - line.x)*line.percentage), line.y + ((line.ymoveto - line.y)*line.percentage))
				else
					line.delay = line.delay - 10
				end
			end
		end
	end
	
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
end

function event(e)
	if e["type"] == "ui:motion" then
		-- GLOBAL.uix + 105,GLOBAL.uiy + 27,31,22
		if e.y > GLOBAL.uiy + 27 and e.y < GLOBAL.uiy + 27 + 22 and e.x > GLOBAL.uix + 105 and e.x < GLOBAL.uix + 105 + 31 then
			if GLOBAL.uion == true then
				BUTTONS[2]:destroy()
				BUTTONS[2] = g2.new_image("gui-icon4o",GLOBAL.uix + 105,GLOBAL.uiy + 27,31,22)
			end
		else
			if GLOBAL.uion == true then
				BUTTONS[2]:destroy()
				BUTTONS[2] = g2.new_image("gui-icon4",GLOBAL.uix + 105,GLOBAL.uiy + 27,31,22)
			end
		end
	end
	if e["type"] == "ui:down" then
		if e.y > GLOBAL.uiy + 27 and e.y < GLOBAL.uiy + 27 + 22 and e.x > GLOBAL.uix + 105 and e.x < GLOBAL.uix + 105 + 31 then
			if GLOBAL.coins >= 3 then
				GLOBAL.coins = GLOBAL.coins - 3
				GLOBAL.planetselected.ships_value = GLOBAL.planetselected.ships_value + 10
			end
		else
			GLOBAL.selected = false
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

	GLOBAL.uiimage = nil
	for i in pairs(LINES) do
		LINES[i] = nil
	end


	GLOBAL.uion = false
	GLOBAL.uiimage = nil
	
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
	
    -- generate map
    sk_mapGen(player, enemy, neutral)
    g2.planets_settle()
end