LICENSE = [[
Copyright (c) 2013 Phil Hassey
Modifed by: esparano
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]
require("bot_carlsen.lua")

function init()
    -- set up global data here
    
    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }
    
    OPTS = {
        seed = math.random(1,99999999),
        t = 1.0,
        rank = 1,
        sw = 800,
        sh = 600,
        -- default game settings
        neutrals = 6,
        homes = 1,
        size = 50,
        bots = 1,
        ships = 100,
        -- default bot settings
        wait = 0.0, -- time in between bot loop calls
    }
    
    OPTS.seed = os.time()
    init_menu()
    g2.state = "menu"
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////
-- BOT CODE ////////////////////////////////////////////////////////////////////////////////////////////

-- GAME CODE {{{ ----------------------------

function init_game()
    g2.game_reset()
    OPTS.t = 0
    OPTS.win_t = 5
    math.randomseed(OPTS.seed)
   
    local user_neutral = g2.new_user("neutral",COLORS[1])
    user_neutral.user_neutral = true
    user_neutral.ships_production_enabled = false
   
    local player = g2.new_user("player", COLORS[2])
    player.ui_ships_show_mask = 0xf
    g2.player = player
    
    local bots = {}
    for i=1,OPTS.bots do
        local enemy = g2.new_user("enemy", COLORS[2+i])
        bots[i] = enemy
    end
    
    local pad = 50;
    local sw = OPTS.sw*OPTS.size / 100;
    local sh = OPTS.sh*OPTS.size / 100;

    local a = math.random(0,360)
    
    local users = 1.0 + OPTS.bots
        
    for i=1,OPTS.neutrals/2 do
        local x = sw/2 + math.random(-(sw + pad)/2,(sw + pad)/2)
        local y = sh/2 + math.random(-(sh + pad)/2,(sh + pad)/2)
        local prod = math.random(15,100)
        local cost = math.random(0,50)
        g2.new_planet(user_neutral, x, y, prod, cost);
        g2.new_planet(user_neutral, sw - x, sh - y, prod, cost);
    end
    
    for i=1,OPTS.homes do
        local x,y
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(player, x,y, 100, 100);
        for j=1,OPTS.bots do
            o2 = bots[j]
            a = a+360/(users)
            x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
            y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
            g2.new_planet(o2, x,y, 100, OPTS.ships);
        end
        a = a + 360/(users)
        a = a + 360/(OPTS.homes*users)
        
    end

    g2.planets_settle()
    
    local planets = g2.search("planet")
    for _i, planet in ipairs(planets) do
        local x = planet.position_x
        local y = planet.position_y
        g2.new_label(planet.n, x, y + 20)
    end
end

function loop(t)
    OPTS.t = OPTS.t + t
    if (OPTS.t >= OPTS.wait) then
        OPTS.t = OPTS.t - OPTS.wait
        local users = g2.search("user")
        for _i,user in ipairs(users) do
            if (user.title_value == "enemy") then
                --bot_carlsen_loop(user, t)
                bot_carlsen_loop(user, 1/30)
            end
        end
    end
    
    local win = nil;
    local planets = g2.search("planet -neutral")
    for _i,p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then win = user end
        if (win ~= user) then OPTS.win_t = 5 return end
    end
    
    if (win ~= nil) then
        OPTS.win_t = OPTS.win_t - t
        if OPTS.win_t < 0 then
            if (win.has_player) then
                init_win()
                g2.state = "pause"
                return
            else
                init_lose()
                g2.state = "pause"
                return
            end
        end
    end
end

function event(e)
    if (e["type"] == "onclick" and string.find(e["value"],"init") ~= nil) then
        OPTS.homes = fix(g2.form.homes,1,1,100)
        OPTS.neutrals = fix(g2.form.neutrals,23,0,100)
        OPTS.size = fix(g2.form.size,100,100,1000)
        OPTS.bots = fix(g2.form.bots,1,1,11)
        e["value"] = "newmap"
    end
    if (e["type"] == "onclick" and e["value"] == "newmap") then
        OPTS.seed = os.time();
        init_game();
        init_getready();
        g2.state = "pause"
    end
    if (e["type"] == "onclick" and e["value"] == "restart") then
        init_game();
        init_getready();
        g2.state = "pause"
    end
    if (e["type"] == "onclick" and e["value"] == "resume") then
        g2.state = "play"
    end
    if (e["type"] == "onclick" and e["value"] == "quit") then
        g2.state = "quit"
    end
    if (e["type"] == "pause") then
        init_pause();
        g2.state = "pause"
    end
end

-- }}} END GAME CODE

-- UTILITY FUNCTIONS {{{

-- make sure a number is actually a number
function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

-- value, default, min, max
function fix(v,d,a,b)
    if (type(v) == "string") then v = tonumber(v) end
    if (type(v) ~= "number") then v = d end
    if v < a then v = a end
    if v > b then v = b end
    return v
end

-- find a game object described by "query" using a evaluation function "eval"
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

-- }}} END UTILITY FUNCTIONS 

-- HTML STUFF {{{

function init_menu()
    g2.html = [[
    <table><tr><td colspan=2><h1>Bot: Sparky</h1>
    <tr><td colspan=2><h1>by esparano</h1>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>Neutrals:</p><td><input type='text' name='neutrals'  />
    <tr><td><p>Size:</p><td><input type='text' name='size' />
    <tr><td><p>&nbsp;</p>
    <tr><td colspan=2>
    <table><tr>
    <td><input type='button' value='Start' onclick='init' />
    </table></table>
    ]]
    g2.form.neutrals = OPTS.neutrals
    g2.form.size = OPTS.size
end

function init_getready()
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>Get Ready!</h1>"..
    "<tr><td><input type='button' value='Tap to Begin' onclick='resume' />"..
    "";
end

function init_pause() 
    g2.html = ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume' onclick='resume' />"..
    "<tr><td><input type='button' value='Restart' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

function init_win() 
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><input type='button' value='Replay' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "<tr><td><h1>Seed: "..OPTS.seed.."</h1>"..
    "";
end

function init_lose() 
    g2.html = "" ..
    "<table>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "<tr><td><h1>Seed: "..OPTS.seed.."</h1>"..
    "";
end

-- }}} END HTML STUFF