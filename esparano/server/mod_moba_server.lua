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

-- MOBA-STYLE SERVER MOD

function init()

    GAME = {
        seed = 0,
        t = 0.0,
        rank = 1,
        sw = 640,
        sh = 640,
        neutrals = 100,
        homes = 1,
        size = 100,
        bots = 1,
        port = 23099,
        admin = nil,
        qid = 0,
        state = "lobby",
        level = 100,
    }
    
    GAME.seed = os.time();
--    init_menu();
--    g2.state = "menu"
    
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
    --g2.server.state = v
    g2.state = v
end

function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

function init_game()
    GAME.t = 0
    GAME.end_t = 0
    math.randomseed(GAME.seed);
    
    g2.game_reset();
   
    local o = g2.new_user("neutral",0x555555)
    o.user_neutral = 1
    o.ships_production_enabled = 0
    GAME.u_neutral = o
    
    -- generate players/teams
    local n = 1
    local users = {}
    local team_1 = g2.new_team("team_1","0x0000ff")
    local team_2 = g2.new_team("team_2","0xff0000")
    local team1 = {}
    local team2 = {}
    local team = team_1
    for uid,client in pairs(CLIENTS) do
        if client.status == "play" then
            local p = g2.new_user(client.name,client.color,team)
            users[n] = p
            p.user_uid = client.uid
            client.live = 0
            n = n + 1
            if team == team_1 then 
                team1[#team1 + 1] = p
                team = team_2
            elseif team == team_2 then 
                team2[#team2 + 1] = p
                team = team_1
            end
        end
    end

    local pad = 50;
    local lane_width = 400;
    local sw = GAME.sw*GAME.size / 100 * 2;
    local sh = GAME.sh*GAME.size / 100 * 2;
    
    local a = 90
    local dA = 90/(#team1 - 1)
    --local dA = 30
    -- spawn teams
    for i=1,#team1 do
        local x,y
        x = -sw + pad*math.cos(a*math.pi/180.0)
        y = sh - pad*math.sin(a*math.pi/180.0)
        g2.new_planet(team1[i], x,y, 15, 100);
        a = a - dA
    end
    
    local a = -90
    local dA = 90/(#team2 - 1)
    -- spawn teams
    for i=1,#team2 do
        local x,y
        x = sw - pad*math.cos(a*math.pi/180.0)
        y = -sh + pad*math.sin(a*math.pi/180.0)
        g2.new_planet(team2[i], x,y, 15, 100);
        a = a - dA
    end
    
    for i=1,GAME.neutrals/6 do
        local x,y
        x = math.random(-sw,-sw+lane_width)
        y = math.random(-sh,sh)
        prod = math.random(15,100)
        cost = math.random(0,50)
        g2.new_planet(o, x, y, prod, cost);
        g2.new_planet(o, -x, -y, prod, cost);
        
        x = math.random(-sw,sw)
        y = math.random(sh-lane_width,sh)
        prod = math.random(15,100)
        cost = math.random(0,50)
        g2.new_planet(o, x, y, prod, cost);
        g2.new_planet(o, -x, -y, prod, cost);
        
        x = math.random(-sw+lane_width,0)
        y = x+math.random(-lane_width/2,lane_width/2)
        prod = math.random(15,100)
        cost = math.random(0,50)
        g2.new_planet(o, x, y, prod, cost);
        g2.new_planet(o, -x, -y, prod, cost);
    end
    
    -- generate neutrals
    
    g2.planets_settle()
    chstate("play")
    g2.net_send("","sfx","start");
    GAME.mode = "ffa"
end

function round(num, idp)
    return tonumber(string.format("%." .. (idp or 0) .. "f", num))
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
    
    g2.game_reset();
    chstate("lobby")
    g2.net_send("","sfx","stop");
end

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

function loop(t)
    GAME.t = GAME.t + t

    if GAME.state == "pause" then
        if GAME.t > GAME.pause_t then
            chstate("play")
        end
    end
    
    if GAME.state == "lobby" then return end
    
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
            init_end(false)
        end
        return
    end
    
    -- if one team has conquered all other teams end the game
    if win == nil then GAME.end_t = 0 end -- reset timer if someone recovers
    if GAME.tusers > 1 then -- ignore single team games
        if (win ~= nil) then
            if GAME.end_t == 0 then GAME.end_t = GAME.t + 3.0 end
            if GAME.t > GAME.end_t then
                init_end(true)
            end
            return
        end
    end
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

function net_join(e)
    g2.net_send("","sfx","join");
    g2.net_send("","message",e.name .." has joined")
    g2.net_send(e.uid,"message","Welcome to esparano's MOBA server!")
    g2.net_send(e.uid,"message","Hosted on port "..GAME.port)
    g2.net_send(e.uid,"message","Commands: /start, /who, /play, /away, /surrender, /stop")
    g2.net_send(e.uid,"message","Type /start to start the game!")
    GAME.qid = GAME.qid + 1
    --e.client.qid = GAME.qid
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

    if ivalue:find("cuzco") ~= nil then
        g2.net_send("","message","Cuzco is the best goat in the world!")
    end
    
    if ivalue:find("/play") == 1 then
        GAME.qid = GAME.qid + 1
        e.client.qid = GAME.qid
        e.client.status = "queue"
        update_queue()
    end
    if ivalue:find("/away") == 1 then
        e.client.status = "away"
        update_queue()
    end
    
    if ivalue:find("/start") == 1 then
        if g2.state ~= "play" then
            GAME.seed = GAME.seed + 1
            if ivalue:find("coop") ~= nil then
                GAME.level = 1 -- fix(ivalue:match("%d+"),1,1,100)
                init_game_coop()
            else
                init_game()
            end
        end
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
    
    -- admin stuff
    if ivalue:find("/stop") == 1 and GAME.admin == e.uid then
        if g2.state == "play" then
            init_end(false)
        end
    end
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
    <tr><td colspan=2><h1>Galcon 2 MOBA Server</h1>
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

