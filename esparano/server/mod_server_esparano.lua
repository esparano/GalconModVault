LICENSE = [[
mod_server.lua

Copyright (c) 2013 Phil Hassey
Modifed by: YOUR_NAME_HERE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]
--------------------------------------------------------------------------------
strict(true)
require("mod_client") -- HACK: not a clean import, but it works
--------------------------------------------------------------------------------
function menu_init()
    GAME.modules.menu = GAME.modules.menu or {}
    local obj = GAME.modules.menu
    function obj:init()
        g2.html = [[
            <table>
            <tr><td colspan=2><h1>Galcon 2 Server</h1>
            <tr><td><p>&nbsp;</p>
            <tr><td><input type='text' name='port' value='$PORT' />
            <tr><td><p>&nbsp;</p>
            <tr><td><input type='button' value='Start Server' onclick='host' />"
            </table>
            ]]
        GAME.data = json.decode(g2.data)
        if type(GAME.data) ~= "table" then GAME.data = {} end
        g2.form.port = GAME.data.port or "23099"
        g2.state = "menu"
    end
    function obj:loop(t) end
    function obj:event(e)
        if e.type == 'onclick' and e.value == 'host' then
            GAME.data.port = g2.form.port
            g2.data = json.encode(GAME.data)
            g2.net_host(GAME.data.port)
            GAME.engine:next(GAME.modules.lobby)
            if g2.headless == nil then
                g2.net_join("",GAME.data.port)
            end
        end
    end
end
--------------------------------------------------------------------------------
function clients_queue()
    local colors = {
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xff8800,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
    local q = nil
    for k,e in pairs(GAME.clients) do
        if e.status == "away" or e.status == "queue" then
            e.color = 0x555555
        end
        if e.status == "queue" then q = e end
        for i,v in pairs(colors) do
            if v == e.color then colors[i] = nil end
        end
    end
    if q == nil then return end
    for i,v in pairs(colors) do
        if v ~= nil then
            q.color = v
            q.status = "play"
            net_send("","message",q.name .. " is /play")
            return
        end
    end
end
function clients_init()
    GAME.modules.clients = GAME.modules.clients or {}
    GAME.clients = GAME.clients or {}
    local obj = GAME.modules.clients
    function obj:event(e)
        if e.type == 'net:join' then
            GAME.clients[e.uid] = {uid=e.uid,name=e.name,status="queue"}
            clients_queue()
            net_send("","message",e.name .. " joined")
        end
        if e.type == 'net:leave' then
            GAME.clients[e.uid] = nil
            net_send("","message",e.name .. " left")
            clients_queue()
        end
        if e.type == 'net:message' and e.value == '/play' then
            if GAME.clients[e.uid].status == "away" then
                GAME.clients[e.uid].status = "queue"
                clients_queue()
            end
        end
        if e.type == 'net:message' and e.value == '/away' then
            if GAME.clients[e.uid].status == "play" then
                GAME.clients[e.uid].status = "away"
                clients_queue()
                net_send("","message",e.name .. " is /away")
            end
        end
    end
end
--------------------------------------------------------------------------------
function params_set(k,v)
    GAME.params[k] = v
    net_send("",k,v)
end
function params_init()
    GAME.modules.params = GAME.modules.params or {}
    GAME.params = GAME.params or {}
    GAME.params.state = GAME.params.state or "lobby"
    GAME.params.html = GAME.params.html or ""
    local obj = GAME.modules.params
    function obj:event(e)
        if e.type == 'net:join' then
            net_send(e.uid,"state",GAME.params.state)
            net_send(e.uid,"html",GAME.params.html)
        end
    end
end
--------------------------------------------------------------------------------
function chat_init()
    GAME.modules.chat = GAME.modules.chat or {}
    GAME.clients = GAME.clients or {}
    local obj = GAME.modules.chat
    function obj:event(e)
        if e.type == 'net:message' then
            net_send("","chat",json.encode({uid=e.uid,color=GAME.clients[e.uid].color,value="<"..GAME.clients[e.uid].name.."> "..e.value}))
        end
    end
end
--------------------------------------------------------------------------------
function lobby_init()
    GAME.modules.lobby = GAME.modules.lobby or {}
    local obj = GAME.modules.lobby
    function obj:init()
        params_set("state","lobby")
        params_set("tabs","<table class='box' width=160><tr><td><h2>My Server</h2></table>")
        params_set("html","<p>Lobby ... enter /start to play!</p>")
    end
    function obj:loop(t) end
    function obj:event(e)
        if e.type == 'net:message' and e.value == '/start' then
            GAME.engine:next(GAME.modules.galcon)
        end
    end
end
--------------------------------------------------------------------------------
function galcon_classic_init()
    local G = GAME.galcon
    math.randomseed(os.time())
    
    g2.game_reset();
   
    local o = g2.new_user("neutral",0x555555)
    o.user_neutral = 1
    o.ships_production_enabled = 0
    G.neutral = o
    
    local users = {}
    G.users = users

    for uid,client in pairs(GAME.clients) do
        if client.status == "play" then
            local p = g2.new_user(client.name,client.color)
            users[#users+1] = p
            p.user_uid = client.uid
            client.live = 0
        end
    end

    local sw = 480
    local sh = 320
    
    for i=1,23 do
        g2.new_planet( o, math.random(0,sw),math.random(0,sh), math.random(15,100), math.random(0,50))
    end
    local a = math.random(0,360)
    
    for i,user in pairs(users) do
        local x,y
        x = sw/2 + (sw/2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh/2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(user, x,y, 100, 100);
        a = a + 360/#users
    end
    
    g2.planets_settle(0,0,sw,sh)
    g2.net_send("","sfx","start");
end

function count_production()
    local r = {}
    local items = g2.search("planet -neutral")
    for _i,o in ipairs(items) do
        local team = o:owner():team()
        r[team] = (r[team] or 0) + o.ships_production
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

function galcon_stop(res)
    if res == true then
        local o = most_production()
        net_send("","message",o.title_value.." conquered the galaxy")
    end
    GAME.engine:next(GAME.modules.lobby)
end

function galcon_classic_loop()
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

function find_user(uid)
    for n,e in pairs(g2.search("user")) do
        if e.user_uid == uid then return e end
    end
end
function galcon_surrender(uid)
    local G = GAME.galcon

    local user = find_user(uid)
    if user == nil then return end
    for n,e in pairs(g2.search("planet owner:"..user)) do
        e:planet_chown(G.neutral)
    end
end

function galcon_init()
    GAME.modules.galcon = GAME.modules.galcon or {}
    GAME.galcon = GAME.galcon or {}
    local obj = GAME.modules.galcon
    function obj:init()
        params_set("state","play")
        params_set("html",[[<table>
            <tr><td><input type='button' value='Resume' onclick='resume' />
            <tr><td><input type='button' value='Surrender' onclick='/surrender' />
            </table>]])
        galcon_classic_init()
    end
    function obj:loop(t)
        galcon_classic_loop()
    end
    function obj:event(e)
        if e.type == 'net:message' and e.value == '/abort' then
            galcon_stop(false)
        end
        if e.type == 'net:leave' then
            galcon_surrender(e.uid)
        end
        if e.type == 'net:message' and e.value == '/surrender' then
            galcon_surrender(e.uid)
        end
    end
end
--------------------------------------------------------------------------------
function register_init()
    GAME.modules.register = GAME.modules.register or {}
    local obj = GAME.modules.register
    obj.t = 0
    function obj:loop(t)
        if GAME.module == GAME.modules.menu then return end
        self.t = self.t - t
        if self.t < 0 then
            self.t = 60
            g2_api_call("register",json.encode({title='Esparano\'s Custom Server',port=GAME.data.port}))
        end
    end
end
--------------------------------------------------------------------------------
function engine_init()
    GAME.engine = GAME.engine or {}
    GAME.modules = GAME.modules or {}
    local obj = GAME.engine

    function obj:next(module)
        GAME.module = module
        GAME.module:init()
    end
    
    function obj:init()
        self:next(GAME.modules.menu)
    end
    
    function obj:event(e)
--         print("engine:"..e.type)
        GAME.modules.clients:event(e)
        GAME.modules.params:event(e)
        GAME.modules.chat:event(e)
        GAME.module:event(e)
        if e.type == 'onclick' then 
            GAME.modules.client:event(e)
        end
    end
    
    function obj:loop(t)
        GAME.module:loop(t)
        GAME.modules.register:loop(t)
    end
end
--------------------------------------------------------------------------------
function mod_init()
    global("GAME")
    GAME = GAME or {}
    engine_init()
    menu_init()
    clients_init()
    params_init()
    chat_init()
    lobby_init()
    galcon_init()
    register_init()
    
    client_init()
end
--------------------------------------------------------------------------------
function init() GAME.engine:init() end
function loop(t) GAME.engine:loop(t) end
function event(e) GAME.engine:event(e) end
--------------------------------------------------------------------------------
function net_send(uid,mtype,mvalue) -- HACK - to make headed clients work
    if g2.headless == nil and (uid == "" or uid == g2.uid) then
        GAME.modules.client:event({type="net:"..mtype,value=mvalue})
    end
    g2.net_send(uid,mtype,mvalue)
end
--------------------------------------------------------------------------------
mod_init()