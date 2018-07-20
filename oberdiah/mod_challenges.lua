	

    -- GALCON 2 MODS STARTER KIT
    -- by tinny
     
    function init()
		GLOBAL = {
			level = 1,
			simplebot = {},
			count = 0
		}
		
        main_menu()
    end
     
    function main_menu()
        g2.state = "menu"
     
        g2.html = [[
            <table>
                <tr><td><h1>The Challenges</h1>
				<tr><td>By Oberdiah
                <tr><td><input type='button' value='Start' onclick='start' />
                <tr><td><p></p>
            </table>
        ]]
    end
     
    function init_paused()
        g2.html = [[
            <table>
            <tr><td><input type='button' value='Resume' onclick='resume' />
			<tr><td><input type='button' value='Restart Level' onclick='restart' />
			<tr><td><input type='button' value='I give up' onclick='giveup' />
        ]]
    end
     
    function init_win()
            g2.html = 
            "<table>" ..
            "<tr><td><h1>Well done on completing level " .. string.format("%d", GLOBAL.level) .. "</h1>" ..
			"<tr><td><input type='button' value='Next level' onclick='nextlvl' />" ..
			"<tr><td><input type='button' value='Quit' onclick='quit' />"
    end
     
    function init_lose()
        g2.html = [[
            <table>
            <tr><td><h1>You suck.</h1>
			<tr><td><input type='button' value='Restart Level' onclick='restart' />
        ]]
    end
     
    -- generate the map
    function sk_mapGen(player, enemy, neutral, afk)
		
		GLOBAL.simplebot[4] = false
		GLOBAL.simplebot[3] = true
		GLOBAL.simplebot[2] = false
		GLOBAL.simplebot[1] = true
		
		if GLOBAL.level == 1 then
			for i=-50,50 do
				g2.new_planet(neutral, i*10, i*10, 10, 0)
			end
			g2.new_planet(enemy, 500, 500, 200, 0)
			g2.new_planet(player, -500, -500, 200, 0)
		elseif GLOBAL.level == 2 then
			for i=-20,20 do
				g2.new_planet(neutral, 100, i*40, 0, 0)
				g2.new_planet(neutral, -100, i*40, 0, 0)
			end
			g2.new_planet(neutral, 0, 1000, 100, 0)
			g2.new_planet(enemy, 100, -820, 0, 1)
			g2.new_planet(player, -100, -820, 0, 1)
		elseif GLOBAL.level == 3 then
			for i=-2,2 do
				for f =-2,2 do
					if i == 0 and f == 0 then
						g2.new_planet(player, -200, 0, 10, 1)
						g2.new_planet(enemy, 200, 0, 10, 2)
					else
						g2.new_planet(afk, i*50 - 200, f*50, 10, 0)
						g2.new_planet(afk, i*50 + 200, f*50, 10, 0)
					end
				end
			end
		elseif GLOBAL.level == 4 then
			for i = -1,1 do
				g2.new_planet(player, -200, i*200, 100, 10)
				g2.new_planet(enemy, 200, i*200, 100, 10)
			end
		end
    end
     
    -- no need to touch this
    function loop(t)
		GLOBAL.count = GLOBAL.count + 1
		
		-- Default bot
		if GLOBAL.simplebot[GLOBAL.level] == true then
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
		
		-- Bot for lvl 2
		if GLOBAL.level == 2 and GLOBAL.count > 30 then
			GLOBAL.count = 0
			local from_planets = g2.search("planet owner:"..GLOBAL.enemy)
			local to_planets = g2.search("planet -team:"..GLOBAL.enemy:team())
			local value = math.huge
			local attack
			for _i,planet in ipairs(from_planets) do
				if planet.ships_value == 1 then 
					for _i,toplanet in ipairs(to_planets) do
						if value > toplanet:distance(planet) then
							value = toplanet:distance(planet)
							attack = toplanet
						end
					end
					if attack:distance(planet) > 100 then
						for _i,bigplanet in ipairs(to_planets) do
							if bigplanet.ships_production == 100 then
								planet:fleet_send(100, bigplanet)
							end
						end
					end
					planet:fleet_send(100, attack)
				end
			end
		end
	
		-- Bot for level 4
		if GLOBAL.level == 4 then
			local all_fleets = g2.search("fleet owner:" .. GLOBAL.enemy)
			local all_planets = g2.search("planet")
			for tablenumber,fleet in ipairs(all_fleets) do
				if fleet ~= nil and fleet.fleet_ships > 1 then
					for i = 0,fleet.fleet_ships do
						for _i,planet in ipairs(all_planets) do
							if planet.n == fleet.fleet_target then
								g2.new_fleet(fleet:owner(), 1, fleet, planet)
							end
						end
					end
					fleet:destroy()
				end
			end
			
			local fleets = g2.search("fleet owner:"..GLOBAL.player)
			local myfleets = g2.search("fleet owner:"..GLOBAL.enemy)
			local my_planets = g2.search("planet owner:"..GLOBAL.enemy)
			local yo_planets = g2.search("planet owner:"..GLOBAL.player)
			local defend
			local attacked
			local numberofships = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			local mynumberofships = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			local closestplanet = nil
			local value
			
			for _i,fleet in ipairs(fleets) do
				numberofships[fleet.fleet_target] = fleet.fleet_ships + numberofships[fleet.fleet_target]
			end
			
			for _i,fleet in ipairs(myfleets) do
				mynumberofships[fleet.fleet_target] = fleet.fleet_ships + mynumberofships[fleet.fleet_target]
			end

			for _i,attacking in ipairs(my_planets) do
				value = math.huge
				local attacked
				if numberofships[attacking.n] == 0 then
					for _i,toattack in ipairs(yo_planets) do
						if toattack.ships_value * toattack:distance(attacking) < value and attacking ~= toattack then
							value = toattack.ships_value * toattack:distance(attacking)
							attacked = toattack
						end
					end
					if attacked ~= nil and mynumberofships[attacked.n] == 0 then
						attacking:fleet_send(25, attacked)
					end
				end
			end
			
			for _i,fleet in ipairs(fleets) do
				attacked = g2.item(fleet.fleet_target)
				defend = nil
				closestplanet = nil
				value = -math.huge
				if attacked ~= nil and attacked:owner() == GLOBAL.enemy then
					for _i,defendpl in ipairs(my_planets) do
						if attacked ~= defendpl then
							if defendpl.ships_value > value and defendpl:distance(attacked) < 300 then
								value = defendpl.ships_value
								closestplanet = defendpl
							end
						end
					end
					local fleetsfeeding = 0
					if closestplanet ~= nil then
						for _i,myfleet in ipairs(myfleets) do
							if attacked.n == myfleet.fleet_target then
								fleetsfeeding = fleetsfeeding + myfleet.fleet_ships
							end
						end
						numberofships[fleet.fleet_target] = numberofships[fleet.fleet_target] - fleetsfeeding - attacked.ships_value
						local percentage = numberofships[fleet.fleet_target] / closestplanet.ships_value
						if percentage > 1 then
							percentage = 1
						elseif percentage < 0 then
							percentage = 0
						end
						if numberofships[fleet.fleet_target] < closestplanet.ships_value - numberofships[closestplanet.n] then
							closestplanet:fleet_send(percentage * 100, attacked)
						end
						myfleets = g2.search("fleet owner:"..GLOBAL.enemy)
						for _i,myfleet in ipairs(myfleets) do
							if numberofships[attacked.n] > 0 and numberofships[myfleet.fleet_target] == 0 then
								myfleet:fleet_redirect(attacked)
							end
						end
						if closestplanet.ships_value < 10 and mynumberofships[closestplanet.n] then
							for _i,backup in ipairs(my_planets) do
								if numberofships[backup.n] == 0 then
									backup:fleet_send(5, closestplanet)
								end
							end
						end
					end
				end
			end
		end
		
		local planets = g2.search("planet owner:"..GLOBAL.player)
		local fleets = g2.search("fleet owner:"..GLOBAL.player)
		local eplanets = g2.search("planet owner:"..GLOBAL.enemy)
		if #planets == 0 and #fleets == 0 and #eplanets == 0 then
		elseif #planets == 0 and #fleets == 0 then
			init_lose()
			g2.state = "pause"
		elseif #eplanets == 0 then
			init_win()
			g2.state = "pause"
		end

    end
    
	function nextlevel()
		GLOBAL.level = GLOBAL.level + 1
		g2.game_reset();
		init_game();
		g2.state = "play"
	end
	
    function event(e)
		if e["type"] == "onclick" and e["value"] then
			if e["value"] == "nextlvl" then
				nextlevel()
			elseif e["value"] == "giveup" then
				nextlevel()
			elseif e["value"] == "restart" then
				init_game();
				g2.state = "play"
			elseif (e["value"] == "resume") then
				g2.state = "play"
			elseif (e["value"] == "start") then
				init_game();
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
		   
		local afk = g2.new_user("bot", 0xFFFF00)
		GLOBAL.afk = afk
        -- generate map
        sk_mapGen(player, enemy, neutral, afk)
        g2.planets_settle()
       
    end

