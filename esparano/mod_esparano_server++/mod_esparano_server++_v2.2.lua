LICENSE = [[
mod_server.lua

Copyright (c) 2013 Phil Hassey
Modifed by: Evan Sparano

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]

function init()

    GAME = {
        seed = 0,
        t = 0.0,
        rank = 1,
        sw = 640,
        sh = 480,
        neutrals = 23,
        homes = 1,
        size = 100,
        bots = 1,
        port = 23099,
        admin = nil,
        qid = 0,
        state = "lobby",
        level = 100,
        data_wait = 0.5, -- Spacing in seconds between data collection points
        datat = 0.0,
        data_num = 1,
        graph_timer_length = 10,
        finished = false,
        strict = false,
        tusers = 0,
        bot_wait = 0.2
    }
    
    GAME.seed = os.time();
    
    CLIENTS = {}
    
    init_menu()
    
    if g2.port ~= nil then
        GAME.port = g2.port
    end

    if g2.headless ~= nil then
        print("Running headless!")
        init_host()
    end

end

function chstate(v)
    GAME.state = v
    g2.server.state = v
    g2.state = v
end

function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

function standard_init()
    SHIP_DATA = {}
	PROD_DATA = {}
	data_num = 0
	GAME.datat = 0
    GAME.t = 0
    GAME.end_t = 0
    math.randomseed(GAME.seed)
    GAME.graph_drawn = false
    GAME.finished = false
    GAME.bot_t = 0
end

function init_game()
	standard_init()
    
    g2.game_reset()
   
    local o = g2.new_user("neutral",0x555555)
    o.user_neutral = 1
    o.ships_production_enabled = 0
    GAME.u_neutral = o
    
    local n = 1
    local users = {}

    for uid,client in pairs(CLIENTS) do
        if client.status == "play" then
            local p = g2.new_user(client.name,client.color)
            users[n] = p
            p.user_uid = client.uid
            client.live = 0
            n = n + 1
        end
    end
  
    if #users == 0 then return end
    
    if #users == 1 then
   		local bteam = g2.new_team("bteam",0xff0000)
    	local bot = g2.new_user("bot",0x555555,bteam)
    	GAME.bot = bot
    	users[n] = bot
    else
    	GAME.bot = nil
    end
    
    local num_players = mknumber(#users) 
    GAME.neutrals = 10*num_players;
    
    local pad = 50;
    local sw = GAME.sw*GAME.size / 100
    local sh = GAME.sh*GAME.size / 100
    
    for i=1,GAME.neutrals do
        g2.new_planet(o, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end
    local a = math.random(0,360)
    
    local tusers = mknumber(#users)
    GAME.tusers = tusers
    for i=1,tusers do
        local x,y
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        if (users[i] == GAME.bot) then
  			g2.new_planet(users[i], x, y, 100, 165)
  		else
   			g2.new_planet(users[i], x, y, 100, 100)
   		end
            
        a = a + 360/(tusers)
    end
    
    g2.planets_settle()
    chstate("play")
    g2.net_send("","sfx","start");
    GAME.mode = "ffa"
end

function init_game_symmetric()
    standard_init()
    
    g2.game_reset()
   
    local neutral = g2.new_user("neutral",0x555555)
    neutral.user_neutral = 1
    neutral.ships_production_enabled = 0
    GAME.u_neutral = neutral
    
    local n = 1
    local users = {}

    for uid,client in pairs(CLIENTS) do
        if client.status == "play" then
            local p = g2.new_user(client.name,client.color)
            users[n] = p
            p.user_uid = client.uid
            client.live = 0
            n = n + 1
        end
    end
  
    if #users == 0 then return end
    
    if #users == 1 then
   		local bteam = g2.new_team("bteam",0xff0000)
    	local bot = g2.new_user("bot",0x555555,bteam)
    	GAME.bot = bot
    	users[n] = bot
    else
    	GAME.bot = nil
    end
    
    local num_players = mknumber(#users) 
    GAME.neutrals = 10*num_players;
    local neutral_prod_min = 15
    local neutral_prod_max = 100
    local neutral_ships_min = 0
    local neutral_ships_max = 50

	-- set users' home planet coords
	local x0 = math.random(-GAME.sw/2,GAME.sw/2)
	local y0 = math.random(-GAME.sh/2,GAME.sh/2)
	local angle = 0
	for _i,u in ipairs(users) do
		local x = x0 * math.cos(angle) - y0 * math.sin(angle);
  		local y = x0 * math.sin(angle) + y0 * math.cos(angle);
  		if (u == GAME.bot) then
  			g2.new_planet(u, x, y, 100, 165)
  		else
   			g2.new_planet(u, x, y, 100, 100)
   		end
   		angle = angle + math.pi*2/#users
	end

    -- @TODO: minimum distance between home planets

    -- generate neutrals
    for i=1, GAME.neutrals/num_players, 1 do
    	-- create neutrals
    	local x0 = math.random(-GAME.sw/2,GAME.sw/2)
		local y0 = math.random(-GAME.sh/2,GAME.sh/2)
        local rand_prod = math.random(neutral_prod_min, neutral_prod_max)
   		local rand_ships = math.random(neutral_ships_min, neutral_ships_max)
    	angle = 0
    	for i=1, num_players, 1 do
    		local x = x0 * math.cos(angle) - y0 * math.sin(angle)
  			local y = x0 * math.sin(angle) + y0 * math.cos(angle)
        	g2.new_planet(GAME.u_neutral, x, y, rand_prod, rand_ships)
			angle = angle + math.pi*2/num_players
			
		end
    end
    
    g2.planets_settle()
    chstate("play")
    g2.net_send("","sfx","start");
    GAME.mode = "ffa"
end

function round(num, idp)
    return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function init_game_coop()
	SHIP_DATA = {}
	PROD_DATA = {}
	data_num = 0
	GAME.datat = 0
    GAME.graph_drawn = false
    GAME.finished = false
    local ships = 100
    local bonus = 0
    local prev = GAME.t
    if GAME.level > 1 then
        bonus = 1000 / GAME.t
    end
    ships = ships + bonus
    
    GAME.t = 0
    GAME.end_t = 0
    GAME.bot_t = 5.0
    math.randomseed(GAME.seed);
    
    g2.game_reset();
    
    local o = g2.new_user("neutral",0x555555)
    o.user_neutral = 1
    o.ships_production_enabled = 0
    GAME.u_neutral = o
    
    local players = g2.new_team("players",0x0000ff)
    
    local n = 1
    local users = {}
    
    for uid,client in pairs(CLIENTS) do
        if client.status == "play" then
            local p = g2.new_user(client.name,client.color,players)
            users[n] = p
            p.user_uid = client.uid
            client.live = 0
            n = n + 1
        end
    end
    
    if #users == 0 then return end
    
    local bteam = g2.new_team("bteam",0xff0000)
    local bot = g2.new_user("bot",0x555555,bteam)
    GAME.bot = bot
    
    local pad = 50;
    local sw = GAME.sw*GAME.size / 100;
    local sh = GAME.sh*GAME.size / 100;
    
    for i=1,GAME.neutrals do
        g2.new_planet(o, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end
    local a = math.random(0,360)
    
    local tusers = #users
    GAME.tusers = tusers + 1 -- +1 for bot
    for i=1,tusers do
        local x,y
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(users[i], x,y, 100, ships);
        
        g2.new_planet(bot,math.random(pad,sw-pad),math.random(pad,sh-pad), 50, 75 + (GAME.level-1) * 5);
        
        a = a + 360/(tusers)
        
    end
    
    g2.net_send("","message","Co-op Round: "..GAME.level)
    g2.planets_settle()
    GAME.mode = "coop"
    local html = "<table><tr><td colspan=2><h2>Round "..GAME.level.."</h2>"
    if GAME.level > 1 then
        html = html .. "<tr><td><p>&nbsp;</p>"
        html = html .. "<tr><td><p>Previous Time:</p><td><p>"..round(prev).." seconds</p>"
        html = html .. "<tr><td><p>Speed Bonus:</p><td><p>"..round(bonus).." ships</p>"
    end
    html = html .. "</table>"
    g2.server.html = html
    g2.html = g2.server.html
    GAME.pause_t = 3.0
    chstate("pause")
end

function count_production()
    local r = {}
    local items = g2.search("planet -neutral")
    for _i,o in ipairs(items) do
        local team = o:owner():team()
        r[team] = mknumber(r[team]) + o.ships_production
    end
    return r
end

function most_production()
    local r = count_production()
    local best_o = nil
    local best_v = 0
    for o,v in pairs(r) do
        if v > best_v then
            best_v = v
            best_o = o
        end
    end
    return best_o
end

function init_end(live)
    local win = false
  
    local best = most_production()
    if best ~= nil then
        local items = g2.search("user")
        local txt = ""
        local pre = ""
        for _i,o in ipairs(items) do
            if o:team() == best then
                if o ~= GAME.bot then
                    win = true
                end
                txt = txt .. pre .. o.title_value
                pre = ", "
            end
        end

        if txt ~= "" then
            g2.net_send("","message",txt .. " conquered the galaxy!")
        end

    end
    
    if live == true then
        for uid,client in pairs(CLIENTS) do
            if client.live == 0 and client.status == "play" then
                client.status = "away"
                g2.net_send("","message",client.name .. " is AFK.")
            end
        end
    end
    
    if win == true then
        if GAME.mode == "coop" then
            GAME.seed = GAME.seed + 1
            GAME.level = GAME.level + 1
            init_game_coop()
            return
        end
    end
    
    g2.game_reset();
    chstate("lobby")
    g2.net_send("","sfx","stop");
end

function init_finish(live)
	GAME.live = live
	GAME.finished = true
	if GAME.mode == "ffa" then
		if (GAME.graph_timer_length > 0 and GAME.bot == nil) then
			g2.net_send("","message","Type /lobby to return to the lobby.")
			g2.net_send("","message","You will be returned to the lobby automatically after " .. GAME.graph_timer_length .. " seconds.")
			print_graph()
			return
		end
		init_end(live)
	elseif GAME.mode == "coop" or GAME.graph_timer_length == 0 then
		init_end(live)
	end
end

-- BOT UTILITY FUNCTIONS -------------------------------------------------------

function find(query,eval)
    local res = g2.search(query)
    local best = nil; local value = nil
    for _i,item in pairs(res) do
        _value = eval(item)
        if _value ~= nil and (value == nil or _value > value) then
            best = item
            value = _value
        end
    end
    return best
end

function bot_classic(user) return {
    loop = function(self)
    local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
    if from == nil then return end
    local to = find("planet -owner:"..user,function(o) return -o.ships_value + o.ships_production - o:distance(from) * 0.20 end)
    if to == nil then return end
    from:fleet_send(65,to)
    end
} end

-- Returns a table of (owner_n, ship_count)
function count_ships()
    local r = {}
    
    local items = g2.search("planet OR fleet")
    for _i,object in ipairs(items) do
        if r[object.owner_n] == nil then r[object.owner_n] = 0 end
        r[object.owner_n] = mknumber(r[object.owner_n]) + mknumber(object.ships_value) * mknumber(object.ships_production_enabled) + mknumber(object.fleet_ships)
    end
    
    return r
end

function count_prod()
    local r = {}
    
    local items = g2.search("planet")
    for _i,object in ipairs(items) do
        if r[object.owner_n] == nil then r[object.owner_n] = 0 end
        r[object.owner_n] = mknumber(r[object.owner_n]) + mknumber(object.ships_production) * mknumber(object.ships_production_enabled)
    end
    
    return r
end

function coop_loop()
    if GAME.t > GAME.bot_t then
        bot_classic(GAME.bot):loop()
    end
end

function loop(t)
    GAME.t = GAME.t + t
    
    if GAME.finished and GAME.mode == "ffa" then
    	if GAME.state == "pause" then
       		if GAME.t > GAME.graph_end_t then
        		 init_end(GAME.live)
       		end
   		end
    	return
    end

    if GAME.state == "pause" then
        if GAME.t > GAME.pause_t then
            chstate("play")
        end
    end
    
    if GAME.state == "lobby" then return end
    
    
    if GAME.mode == "coop" then
        coop_loop()
    end
    
    if GAME.bot ~= nil and GAME.mode ~= "coop" then
	    if GAME.t > GAME.bot_t then
        	bot_classic(GAME.bot):loop()
        	GAME.bot_t = GAME.t + GAME.bot_wait
   		end
    end
    
    -- Keep track of the number of ships of each player
	GAME.datat = GAME.datat + t
    if GAME.datat >= GAME.data_wait and GAME.mode == "ffa" then
        GAME.datat = GAME.datat - GAME.data_wait
        data_num = data_num + 1;
        SHIP_DATA[data_num] = count_ships()
        PROD_DATA[data_num] = count_prod()
    end
    
    local win = nil;
    local planets = g2.search("planet -neutral")
    local total = 0
    for _i,p in ipairs(planets) do
        total = total + 1 
        local team = p:owner():team()
        if (win == nil) then win = team end
        if (win ~= team) then return end
    end
    
    -- if no players own any planets anymore
    if total == 0 then
        if GAME.end_t == 0 then GAME.end_t = GAME.t + 1.0 end
        if GAME.t > GAME.end_t then
            init_finish(false)
        end
        return
    end
    
    --- if no players own any planets anymore
    if win == nil then GAME.end_t = 0 end -- reset timer if someone recovers
    if GAME.tusers > 1 then -- ignore single team games
        if (win ~= nil) then
            if GAME.end_t == 0 then GAME.end_t = GAME.t + 3.0 end
            if GAME.t > GAME.end_t then
                init_finish(true)
            end
            return
        end
    end
end

function print_graph()
	if GAME.graph_drawn or GAME.mode ~= "ffa" then return end
	
	GAME.graph_drawn = true
	
	GAME.graph_end_t = GAME.t + GAME.graph_timer_length
	
	local html = [[
		<table><tr><td><p>Total Shipcount Over Time </p></td><td><p>    Total Production Over Time</p></td></tr>
	]]	
	
	local graph_size = 200
	local resolution = 60 -- Number of "bars"
	
	html = html .. "<tr><td><vectors width=200 height=200 data='"
	local x_spacing = graph_size/resolution
	local x
	local y
	for i = 1,resolution do 
		x = i * x_spacing
		y = 0
		local data_array = SHIP_DATA[math.ceil(i/resolution * data_num)]
		
		local total = 0
		for j,count in ipairs(data_array) do
			total = total + mknumber(count)
		end
		local y_spacing = graph_size/total
      	for owner_n,count in ipairs(data_array) do
      		local client
      		local color
      		for i,c in pairs(CLIENTS) do
      			local user = find_user(c.uid)
      			if user ~= nil and user.n == owner_n and user.n ~= GAME.u_neutral.n then
      				client = c 
      			end
	        end
	        if (client ~= nil) then
	        	color = Dec2Hex(client.color)
	  		else
	  			color = ""
	  		end
	  		local length =  mknumber(y_spacing) * mknumber(count)
	  		if length ~= 0 then
	  			html = html .. "T P C" .. color .. " X" .. x .. " Y" .. y .. " P C" .. color .. " X" .. x .. " Y" .. y + length .. " P C" .. color .. " X" .. x + x_spacing .. " Y" .. y + length .. " "
				html = html .. "T P C" .. color .. " X" .. x .. " Y" .. y .. " P C" .. color .. " X" .. x + x_spacing .. " Y" .. y .. " P C" .. color .. " X" .. x + x_spacing .. " Y" .. y + length .. " "
	       		y = y + mknumber(length)
	        end
   		end    
   		x = x + x_spacing 
    end
    html = html .. "' /></td>"
    
    html = html .. "<td><vectors width=200 height=200 data='"
	local x_spacing = graph_size/resolution
	local x
	local y
	for i = 1,resolution do 
		x = i * x_spacing
		y = 0
		local data_array = PROD_DATA[math.ceil(i/resolution * data_num)]
		
		local total = 0
		for j,count in ipairs(data_array) do
			total = total + mknumber(count)
		end
		local y_spacing = graph_size/total
      	for owner_n,count in ipairs(data_array) do
      		local client
      		local color
      		for i,c in pairs(CLIENTS) do
      			local user = find_user(c.uid)
      			if user ~= nil and user.n == owner_n and user.n ~= GAME.u_neutral.n then
      				client = c 
      			end
	        end
	        if (client ~= nil) then
	        	color = Dec2Hex(client.color)
	  		else
	  			color = ""
	  		end
	  		local length =  mknumber(y_spacing) * mknumber(count)
	  		if length ~= 0 then
	  			html = html .. "T P C" .. color .. " X" .. x .. " Y" .. y .. " P C" .. color .. " X" .. x .. " Y" .. y + length .. " P C" .. color .. " X" .. x + x_spacing .. " Y" .. y + length .. " "
				html = html .. "T P C" .. color .. " X" .. x .. " Y" .. y .. " P C" .. color .. " X" .. x + x_spacing .. " Y" .. y .. " P C" .. color .. " X" .. x + x_spacing .. " Y" .. y + length .. " "
	       		y = y + mknumber(length)
	        end
   		end    
   		x = x + x_spacing 
    end
    html = html .. "' /></td></tr>"
    
    --html = html .. [[
    --	<tr><td><p>&nbsp;</p></td></tr>
    --]]
    
    --html = html .. "<tr><td><p>&nbsp;</p></td><td><input type='button' value='Continue' onclick='lobby' /></td></tr>"
    html = html .. "</table>"
    g2.server.html = html
    g2.html = g2.server.html
    chstate("pause")
end

function Dec2Hex(nValue)
	if type(nValue) == "string" then
		nValue = String.ToNumber(nValue);
	end
	nHexVal = string.format("%X", nValue);  -- %X returns uppercase hex, %x gives lowercase letters
	sHexVal = nHexVal.."";
	return sHexVal;
end

function fix(v,d,a,b)
    if (type(v) == "string") then v = tonumber(v) end
    if (type(v) ~= "number") then v = d end
    if v < a then v = a end
    if v > b then v = b end
    return v
end

-- if only one user in the room, they are admin
function find_admin()
    if CLIENTS[GAME.admin] ~= nil then return end
    for uid,client in pairs(CLIENTS) do
        GAME.admin = uid
        g2.net_send("","message",client.name .. " is admin")
        return
    end
end

function set(x)
    local r = {}
    for n,v in pairs(x) do
        r[v] = true
    end
    return r
end

function table_find(r,v)
    for _k,_v in pairs(r) do
        if v == _v then return _k end
    end
end

-- let more people play and set their color
function update_queue()
    local best = nil
    local colors = {
        0x0000ff,--0xff0000, -- saving red for bots
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
    for uid,client in pairs(CLIENTS) do
        if client.status == "queue" then
            if best == nil or client.qid < best.qid then
                best = client
            end
        end
        if client.status == "play" then
            local k = table_find(colors,client.color)
            if k ~= nil then colors[k] = nil end
        end
        if client.status == "away" then
            client.color = 0x555555
        end
    end
    if best == nil then return end
    for _i,color in pairs(colors) do
        best.color = color
        best.status = "play"
        return
    end
end

function find_user(uid)
    for n,e in pairs(g2.search("user")) do
        if e.user_uid == uid then return e end
    end
end

function surrender(uid)
    if g2.state ~= "play" then return end
    local user = find_user(uid)
    if user == nil then return end
    for n,e in pairs(g2.search("planet owner:"..user)) do
        e:planet_chown(GAME.u_neutral)
    end
end
function net_rejoin(e)
    -- do nothing!
end

function send_help(uid)
	g2.net_send(uid,"message","Commands: /who, /play, /away, /surrender, /lobby, /start, /help, /[num]")
    g2.net_send(uid,"message","Admin Commands: /stop, /abort, /strict, /set graphtimer [seconds]")
    g2.net_send(uid,"message","Type '/start' to start a game!")
    g2.net_send(uid,"message","OR '/start symmetric' to start a symmetric game!")
    g2.net_send(uid,"message","OR '/start coop' to start a co-op game!")
end

function net_join(e)
    g2.net_send("","sfx","join");
    g2.net_send("","message",e.name .." has joined")
    g2.net_send(e.uid,"message","Welcome to Esparano's Server++ Mod v2.2!")
    g2.net_send(e.uid,"message","Hosted on port "..GAME.port)
    send_help(e.uid)
    GAME.qid = GAME.qid + 1
    e.client.qid = GAME.qid
    CLIENTS[e.uid] = e.client
    find_admin()
    update_queue()
    net_rejoin(e)
end

function net_leave(e)
    CLIENTS[e.uid] = nil
    g2.net_send("","message",e.name .. " has left")
    g2.net_send("","sfx","leave");
    surrender(e.uid)
    find_admin()
    update_queue()
end

function net_message(e)
    local ivalue = e.value:lower()
    
    -- user commandsi
    if ivalue:find("/play") == 1 then
        GAME.qid = GAME.qid + 1
        e.client.qid = GAME.qid
        e.client.status = "queue"
        update_queue()
    end
    if ivalue:find("/help") == 1 then
        send_help(e.uid)
    end
    if ivalue:find("/away") == 1 then
        e.client.status = "away"
        update_queue()
    end
    if ivalue:find("/surrender") == 1 then
        surrender(e.uid)
    end
    
    if ivalue:find("/who") == 1 then
        local msg = "/who: "
        local pre = ""
        for uid,client in pairs(CLIENTS) do
            msg = msg .. pre .. client.name
            msg = msg .. " (" .. client.status .. ")"
            pre = ", "
        end
        g2.net_send("","message",msg)
    end
    
    -- strict-able commands
    if (GAME.strict == false and e.client.status ~= "away") or GAME.admin == e.uid then
	    if ivalue:find("/lobby") == 1 and GAME.finished and GAME.state == "pause" then
	        init_end(GAME.live)
	    end
	    if ivalue:find("/start") == 1 then
	        if g2.state ~= "play" then
	            GAME.seed = GAME.seed + 1
	            if ivalue:find("coop") ~= nil then
	                GAME.level = 1 -- fix(ivalue:match("%d+"),1,1,100)
	                init_game_coop()
	            elseif ivalue:find("symmetric") ~= nil then
	           		init_game_symmetric()
	            else
	                init_game()
	            end
	        end
	    end
	end
    
    -- admin commands
    if GAME.admin == e.uid then
	    if ivalue:find("/stop") == 1 then
	    	if GAME.mode == "coop" and (g2.state == "play" or g2.state == "pause") then
	    		g2.net_send("","message","bot conquered the galaxy!")
	    		g2.game_reset()
    			chstate("lobby")
    			g2.net_send("","sfx","stop")
	    	elseif g2.state == "play" then
	            init_end(false)
	        end
	    end
	    if ivalue:find("/strict") == 1 then
	    	-- turn strict on
	        if ivalue:find("on") ~= nil then
	        	GAME.strict = true
	        	g2.net_send("","message","strict - on")
	        -- turn strict off
	        elseif ivalue:find("off") ~= nil then
	       		GAME.strict = false
	       		g2.net_send("","message","strict - off")
	       	-- invert strict
	       	else 
	       		GAME.strict = not GAME.strict
	       		if GAME.strict then
	       			g2.net_send("","message","strict - on")
	       		else 
	       			g2.net_send("","message","strict - off")
	       		end
	       	end
	    end
	    if ivalue:find("/abort") == 1 then
	    	if g2.state == "play" or (GAME.mode == "coop" and g2.state == "pause") then
	            g2.game_reset();
    			chstate("lobby")
    			g2.net_send("","sfx","stop");
	        end
    	end
    	if ivalue:find("/set graphtimer") == 1 then
	    	GAME.graph_timer_length = round(mknumber(string.sub(ivalue, 17)), 0)
	    	if GAME.graph_timer_length < 0 then GAME.graph_timer_length = 0 end
	    	if GAME.graph_timer_length == 0 then
	    		g2.net_send("","message","Post-game graph is now turned off.")
	    	else 
	    		g2.net_send("","message","Post-game graph timer is now set to " .. GAME.graph_timer_length .. " seconds.")
	    	end
    	end
	end
    
     -- easter eggs
    if ivalue:find("cuzco") ~= nil then
        g2.net_send("","message","Cuzco is the best goat in the world!")
    end
    if ivalue:find("esparano") ~= nil then
        g2.net_send("","message","Please refer to esparano as His Highness. Thank you.")
    end
    if ivalue:find("esperano") ~= nil then
        g2.net_send("","message","It's spelled espArano. Thank you.")
    end
    for i,t in ipairs(TAUNTS) do
	    if ivalue == "/" .. i then
	        g2.net_send("","message",t)
	    end 
    end
end

TAUNTS = {
	"Yes.",
	"No.",
	"Food, please.",
	"Wood, please.",
	"Gold, please.",
	"Stone, please.",
	"Ahhhhhh!",
	"All hail King of the losers!",
	"Ooooohhhh.",
	"I'll beat you back to Age of Empires.",
	"HAHAHAHAHAHAHAHAHAHA.",
	"Ack! Bein' rushed!",
	"Sure blame it on your isp.",
	"Start the game already!",
	"Don't point that thing at me.",
	"Enemy sighted.",
	"It is good to be the king.",
	"Monk! I need a monk!",
	"Long time no seige.",
	"My granny can scrap better than that.",
	"Nice town. I'll take it.",
	"Quit touching me.",
	"Raiding party!",
	"Dadgum.",
	"Smite me!",
	"The wonder! The wonder! Nooooo!",
	"You played two hours to die like this?!",
	"You should see the other guy.",
	"Rogan?",
	"Wololo.",
	"Attack the enemy now.",
	"Cease creating extra villagers.",
	"Create extra villagers.",
	"Build a navy.",
	"Stop building a navy.",
	"Wait for my signal to attack.",
	"Build a wonder.",
	"Give me your extra resources.",
	"Ally.",
	"Enemy.",
	"Neutral.",
	"What age are you in?"
}

-- dispatch events!
function event(e)
    if e.type:find("net:") == 1 then
        if e.client ~= nil then
            e.client.live = 1
        end
        
        local f = e.type:gsub(":","_")
        if _ENV[f] ~= nil then
            _ENV[f](e)
        end
    end
    
    if e.type == "pause" then
        g2.html =  [[
        <table>
        <tr><td><input type='button' value='Resume' onclick='resume' />
        <tr><td><input type='button' value='Surrender' onclick='surrender' />
        <tr><td><input type='button' value='Quit' onclick='quit' />
        </table>
        ]]
        g2.state = "pause"
    end
    
    if e.type == "onclick" and e.value == "resume" then
        g2.state = GAME.state
    end
    
    if e.type == "onclick" and e.value == "surrender" then
        g2.net_send(g2.server,"message","/surrender")
        g2.state = GAME.state
    end
    
    if e.type == "onclick" and e.value == "quit" then
        g2.state = "quit"
    end
   	
   	--if e.type == "onclick" and e.value == "lobby" then
    --    init_end(GAME.live)
    --end
    
    if e.type == "onclick" and e.value == "host" then
        GAME.port = g2.form.port
        init_host()
    end
end

function init_host()
    g2.net_host(GAME.port)
    if g2.headless == nil then
        g2.net_join("",GAME.port) -- join this game, need this to make the modder a player in the game, alternately, they could join the game from a separate instance of Galcon 2, by joining "127.0.0.1"
    end
    chstate("lobby")
end

function init_menu()
    local html = [[
    <table>
    <tr><td colspan=2><h1>Galcon 2 Server++</h1>
    <tr><td colspan=2><p>Mod by esparano</p>
    <tr><td><p>&nbsp;</p>
    <tr><td><input type='text' name='port' value='$PORT' />
    <tr><td><p>&nbsp;</p>
    <tr><td><input type='button' value='Start Server' onclick='host' />"
    </table>
    ]]
    html = html:gsub("$PORT",GAME.port)
    g2.html = html
    g2.state = "menu"
end

