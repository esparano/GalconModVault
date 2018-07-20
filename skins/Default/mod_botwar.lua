LICENSE = [[
mod_botwar.lua

Copyright (c) 2013 Phil Hassey
Modifed by: YOUR_NAME_HERE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]

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

-- BOTS ------------------------------------------------------------------------

function bot_cuzco(user) return {
    loop = function(self)
        local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
        if from == nil then return end
        local to = find("planet -owner:"..user,function(o) return o.ships_production end)
        if to == nil then return end
        from:fleet_send(65,to)
    end
} end

function bot_zanthor(user) return {
    loop = function(self)
        local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
        if from == nil then return end
        local to = find("planet -owner:"..user,function(o) return o.ships_value end)
        if to == nil then return end
        from:fleet_send(65,to)
    end
} end

function bot_tarbukas(user) return {
    loop = function(self)
        local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
        if from == nil then return end
        local to = find("planet -owner:"..user,function(o) return -o.ships_value end)
        if to == nil then return end
        from:fleet_send(65,to)
    end
} end

function bot_wiljafjord(user) return {
    loop = function(self)
        local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
        if from == nil then return end
        local to = find("planet -owner:"..user,function(o) return -o.ships_value+o.ships_production end)
        if to == nil then return end
        from:fleet_send(65,to)
    end
} end

function bot_beast(user) return {
    loop = function(self)
        local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
        if from == nil then return end
        local to = find("planet -owner:"..user,function(o) return math.random(0,999) end)
        if to == nil then return end
        from:fleet_send(65,to)
    end
} end

function bot_classic(user) return {
    loop = function(self)
        local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
        if from == nil then return end
        local to = find("planet -owner:"..user,function(o) return -o.ships_value + o.ships_production - o:distance(from) * 0.20 end)
        if to == nil then return end
        from:fleet_send(65,to)
    end
} end

-- this is the compact version of the classic bot
function xbot_classic(user) return {
    loop = function(self)
        local from = find("planet owner:"..user,function(o) if o.ships_value < 15 then return nil end return o.ships_value end)
        if from == nil then return end
        local to = find("planet -owner:"..user,function(o) return -o.ships_value + o.ships_production - o:distance(from) * 0.20 end)
        if to == nil then return end
        from:fleet_send(65,to)
    end
} end

-- this is a more readable and verbose version of the classic bot
function bot_classic(user) return {
    loop = function(self)
        function ships_value_if_15_or_more(o) 
            if o.ships_value < 15 then
                return nil
            end
            return o.ships_value
        end

        local from = find("planet owner:"..user,ships_value_if_15_or_more)
        if from == nil then return end
        
        function classic_eval(o)
            return -o.ships_value + o.ships_production - o:distance(from) * 0.20
        end
        
        local to = find("planet -owner:"..user,classic_eval)
        if to == nil then return end
        
        from:fleet_send(65,to)
    end
} end

-- LUA UTILITY FUNCTIONS ----------------------------------------------

function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

function shuffle(t)
    for i,v in ipairs(t) do
        local n = math.random(i,#t)
        t[i] = t[n]
        t[n] = v
    end
end

-- GAME UTILITY FUNCTIONS ------------------------------------------------------

function get_winner()
    local win = nil;
    local planets = g2.search("planet -neutral")
    for _i,p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then win = user end
        if (win ~= user) then return nil end
    end
    return win
end

-- MOD -------------------------------------------------------------------------

function init()
    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
    GAME = {
        t = 0.0,
        sw = 640,
        sh = 480,
        neutrals = 23,
        ships = 100,
        wins = {},
        total = 0,
        timeout = 300.0,
        players = 12, -- max number of players in a round
        speed = 10, -- more time per loop
        ticks = 30, -- more loops per frame
    }

    math.randomseed(os.time()) -- don't reset the seed each game, it makes the game unfair
    reset()
end

function init_game()
    g2.game_reset()

    GAME.t = 0
   
    local u0 = g2.new_user("neutral",COLORS[1])
    u0.user_neutral = 1
    u0.ships_production_enabled = 0
   
    GAME.users = {}
    local n = 0
    -- HACK/NOTE: _ENV is a Lua 5.2 feature, may not be available in the future
    for k,bot in pairs(_ENV) do
        if string.sub(k,1,4) == "bot_" then
            n = n + 1
            local name = string.sub(k,5)
            local user = g2.new_user(name,COLORS[1+n])
            GAME.users[user] = bot(user)
        end
    end
            
    local pad = 50
    local sw = GAME.sw
    local sh = GAME.sh
    
    for i=1,GAME.neutrals do
        g2.new_planet( u0, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end
    
    local a = math.random(0,360)
    local x,y
    local users = {}
    for user,bot in pairs(GAME.users) do
        users[#users+1] = {user,bot}
    end
    shuffle(users)
    
    local total = 0
    n = math.min(n,GAME.players)
    for _i,item in ipairs(users) do
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(item[1], x,y, 100, GAME.ships);
        a = a+360/n
        total = total + 1
        if total >= n then break end
    end
        
    g2.planets_settle()
    
    g2.state = "play"
    g2.speed = GAME.speed
    g2.ticks = GAME.ticks
    GAME.total = GAME.total + 1
end

function gprint(msg)
    print("["..tostring(GAME.total).."] "..msg)
end

function loop(t)
    GAME.t = GAME.t + t
    if GAME.t > GAME.timeout then
        local name = "*TIMEOUT*"
        GAME.wins[name] = mknumber(GAME.wins[name]) + 1
        update_stats()
        init_game()
    end

    local users = {}
    for user,bot in pairs(GAME.users) do
        users[#users+1] = {user,bot}
    end
    shuffle(users)
    for _i,item in pairs(users) do
        item[2]:loop()
    end

    local win = get_winner()
    if win ~= nil then
        local name = win.title_value
        GAME.wins[name] = mknumber(GAME.wins[name]) + 1
        update_stats()
        init_game()
    end
end

function update_stats()
    local stats = {}
    for name,total in pairs(GAME.wins) do
        stats[#stats+1] = {name,total}
    end
    table.sort(stats,function(a,b) return a[2] > b[2] end)
    local info = ""
    for i,item in ipairs(stats) do
        info = info .. item[1] .. ":" .. tostring(item[2]) .. "  "
    end
    gprint(info)
end

function pause() 
    init_pause()
    g2.state = "pause"
end
function reset()
    GAME.total = 0
    GAME.wins = {}
    init_game()
end
function resume()
    g2.state = "play"
end
function quit()
    g2.state = "quit"
end

function event(e)
    if (e["type"] == "pause") then pause() end
    if (e["type"] == "onclick" and e["value"] == "reset") then reset() end
    if (e["type"] == "onclick" and e["value"] == "resume") then resume() end
    if (e["type"] == "onclick" and e["value"] == "quit") then quit() end
end

function init_pause() 
    g2.html = [[
    <table>
    <tr><td><input type='button' value='Resume' onclick='resume' />
    <tr><td><input type='button' value='Reset' onclick='reset' />
    <tr><td><input type='button' value='Quit' onclick='quit' />
    ]]
end