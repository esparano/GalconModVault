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
-- START EVENT CODE {{{
listeners = {}
function create_listener(mod_name, Function) 
    return {mod_name=mod_name, Function=Function}
end
function add_listener(name, Function, mod_name)
    if listeners[name] == nil then
        return
    end
    for index, listener in ipairs(listeners[name]) do
        if listener.mod_name == mod_name then
            if listener.Function == Function then
                print(mod_name .. " tried to register a " .. name .. "handler twice.")
                return
            end
        end
    end
    table.insert(listeners[name], #listeners[name], create_listener(mod_name, Function))
end

function remove_listener(name, mod_name)
    for i=#listeners[name],1, -1 do
        local listener = listeners[name][i]
        if listener.mod_name == mod_name then
           table.remove(listeners[name], i)
        end
    end
end

function event_wrapper(function_name) 
    return function (...) 
        local args = {...}
        for index, listener in ipairs(listeners[function_name]) do
            if listener.mod_name == "standard" then
                listener.Function(...)
            end
        end
        for index, listener in ipairs(listeners[function_name]) do
            if listener.mod_name ~= "standard" then
                listener.Function(...)
            end
        end
    end
end

-- END EVENT CODE }}}

-- START STANDARD MOD CODE {{{

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

listeners["init"] = {create_listener("standard", init)}

init = event_wrapper("init")

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

function init_game()
    GAME.t = 0
    GAME.end_t = 0
    math.randomseed(GAME.seed);
    
    g2.game_reset();
   
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

    local pad = 50;
    local sw = GAME.sw*GAME.size / 100;
    local sh = GAME.sh*GAME.size / 100;
    
    for i=1,GAME.neutrals do
        g2.new_planet( o, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end
    local a = math.random(0,360)
    
    local tusers = #users
    GAME.tusers = tusers
    for i=1,tusers do
        local x,y
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(users[i], x,y, 100, 100);
            
        a = a + 360/(tusers)
        
    end
    
    g2.planets_settle()
    chstate("play")
    g2.net_send("","sfx","start");
    GAME.mode = "ffa"
end

listeners["init_game"] = {create_listener("standard", init_game)}
init_game = event_wrapper("init_game")

function round(num, idp)
    return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function init_game_coop()
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
    
    local bteam = g2.new_team("bteam",0xff0000)
    local bot = g2.new_user("bot",0x555555,bteam)
    GAME.bot = bot
    
    local pad = 50;
    local sw = GAME.sw*GAME.size / 100;
    local sh = GAME.sh*GAME.size / 100;
    
    for i=1,GAME.neutrals do
        g2.new_planet( o, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
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

listeners["init_game_coop"] = {create_listener("standard", init_game_coop)}
init_game_coop = event_wrapper("init_game_coop")

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

listeners["init_end"] =  {create_listener("standard", init_end)}

init_end = event_wrapper("init_end")

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

function coop_loop()
    if GAME.t > GAME.bot_t then
        bot_classic(GAME.bot):loop()
    end
end
listeners["coop_loop"] = {create_listener("standard", coop_loop)}
coop_loop = event_wrapper("coop_loop")

function loop(t)
    GAME.t = GAME.t + t

    if GAME.state == "pause" then
        if GAME.t > GAME.pause_t then
            chstate("play")
        end
    end
    
    if GAME.state == "lobby" then return end
    
    
    if GAME.mode == "coop" then
        coop_loop()
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

listeners["loop"] = {create_listener("standard", loop)}
loop = event_wrapper("loop")

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
listeners["find_admin"] = {create_listener("standard", find_admin)}
find_admin = event_wrapper("find_admin")

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
listeners["update_queue"] = {create_listener("standard", update_queue)}
update_queue = event_wrapper("update_queue")



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
listeners["surrender"] = {create_listener("standard", surrender)}
surrender = event_wrapper("surrender")

function net_rejoin(e)
    -- do nothing!
end
listeners["net_rejoin"] = {create_listener("standard", net_rejoin)}
net_rejoininit = event_wrapper("net_rejoin")

function net_join(e)
    g2.net_send("","sfx","join");
    g2.net_send("","message",e.name .." has joined")
    g2.net_send(e.uid,"message","Welcome to the SuperServer 2000!")
    g2.net_send(e.uid,"message","Hosted on port "..GAME.port)
    g2.net_send(e.uid,"message","Commands: /start, /who, /play, /away, /surrender, /stop")
    g2.net_send(e.uid,"message","Type /start to start the game!")
    g2.net_send(e.uid,"message","OR '/start coop' to start a co-op game!")
    GAME.qid = GAME.qid + 1
    e.client.qid = GAME.qid
    CLIENTS[e.uid] = e.client
    find_admin()
    update_queue()
    net_rejoin(e)
end
listeners["net_join"] = {create_listener("standard", net_join)}
net_join = event_wrapper("net_join")

function net_leave(e)
    CLIENTS[e.uid] = nil
    g2.net_send("","message",e.name .. " has left")
    g2.net_send("","sfx","leave");
    surrender(e.uid)
    find_admin()
    update_queue()
end

listeners["net_leave"] = {create_listener("standard", net_leave)}
net_leave = event_wrapper("net_leave")


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
listeners["net_message"] = {create_listener("standard", net_message)}
net_message = event_wrapper("net_message")

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

listeners["event"] = {create_listener("standard", event)}
event = event_wrapper("event")

function init_host()
    g2.net_host(GAME.port)
    if g2.headless == nil then
        g2.net_join("",GAME.port) -- join this game, need this to make the modder a player in the game, alternately, they could join the game from a separate instance of Galcon 2, by joining "127.0.0.1"
    end
    chstate("lobby")
end

listeners["init_host"] = {create_listener("standard", init_host)}
init_host = event_wrapper("init_host")

function init_menu()
    local html = [[
    <table>
    <tr><td colspan=2><h1>Galcon 2 Server</h1>
    <tr><td colspan=2><p>Mod by Phil Hassey</p>
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
listeners["init_menu"] = {create_listener("standard", init_menu)}
init_menu = event_wrapper("init_menu")

-- END STANDARD MOD CODE {{{

-- START AoE_Taunts PLUGIN {{{

function taunt(e)
    local ivalue = e.value:lower()

    for i,t in ipairs(TAUNTS) do
	    if ivalue == "/" .. i then
	        g2.net_send("","message",t)
	    end 
    end
end

add_listener("net_message", taunt, "AoE_Taunts")

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

-- END AoE_Taunts PLUGIN }}}

-- START not_esperano PLUGIN {{{

function taunt(e)
    local ivalue = e.value:lower()

    if ivalue:find("esperano") ~= nil then
        g2.net_send("","message","It's spelled espArano. Thank you.")
    end
end

add_listener("net_message", taunt, "AoE_Taunts")

-- END not_esperano PLUGIN }}}