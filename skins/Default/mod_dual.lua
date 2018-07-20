LICENSE = [[
mod_dual.lua

Copyright (c) 2013 Phil Hassey
Modifed by: YOUR_NAME_HERE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]



function pass()
end

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
        seed = 0,
        t = 0.0,
        rank = 1,
        sw = 640,
        sh = 480,
        neutrals = 23,
        homes = 1,
        size = 100,
        bots = 1,
        wins = {Red=0,Blue=0},
    }

    OPTS.seed = os.time();
    init_menu();
    g2.state = "menu"
end

function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

function init_game()
    OPTS.t = 0
    math.randomseed(OPTS.seed);
    
    g2.game_reset();
   
    local o = g2.new_user("neutral",COLORS[1])
    o.user_neutral = 1
    o.ships_production_enabled = 0
   
    local o1 = g2.new_user("Blue", COLORS[2])
    g2.player = o1
    
    local o2 = g2.new_user("Red", COLORS[3]);
    g2.player2 = o2
    
    local pad = 50;
    local sw = OPTS.sw*OPTS.size / 100;
    local sh = OPTS.sh*OPTS.size / 100;
    
    for i=1,OPTS.neutrals do
        g2.new_planet( o, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end
    local a = math.random(0,360)
    
    local x,y
    x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
    y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
    g2.new_planet(o1, x,y, 100, 100);
    a = a + 180
    x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
    y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
    g2.new_planet(o2, x,y, 100, 100);
    
    g2.planets_settle()
end

function loop(t)
    OPTS.t = OPTS.t + t

    
    local win = nil;
    local planets = g2.search("planet -neutral")
    for _i,p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then win = user end
        if (win ~= user) then return end
    end
    
    if (win ~= nil) then
        init_win(win)
        g2.state = "pause"
        return
    end
end

function fix(v,d,a,b)
    if (type(v) == "string") then v = tonumber(v) end
    if (type(v) ~= "number") then v = d end
    if v < a then v = a end
    if v > b then v = b end
    return v
end

function event(e)
    if e["type"] == "onclick" and e.value == "play" then
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

function init_menu()
    local html = [[
    <table><tr><td colspan=2><h1>Dual Galcon</h1>
    <tr><td colspan=2><p>Mod by Phil Hassey</p>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>Homes:</p><td><input type='text' name='homes' />
    <tr><td><p>Neutrals:</p><td><input type='text' name='neutrals'  />
    <tr><td><p>Size:</p><td><input type='text' name='size' />
    <tr><td><p>&nbsp;</p>
    <tr><td colspan=2><input type='button' value='Play!' onclick='play' />
    </table>
]];
    
    html = string.gsub(html,"$Z",34)
    
    g2.html = html
    g2.form.neutrals = OPTS.neutrals
    g2.form.bots = OPTS.bots
    g2.form.homes = OPTS.homes
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

function init_win(p)
    OPTS.wins[p.title_value] = mknumber(OPTS.wins[p.title_value])+1

    g2.html = ""..
    "<table>"..
    "<tr><td><h1>"..p.title_value.." Wins!</h1>"
    g2.html = g2.html .. "<tr><td><p>&nbsp;</p>"

    if OPTS.wins["Blue"] >= OPTS.wins["Red"] then
        g2.html = g2.html .. "<tr><td><p>Blue: "..OPTS.wins["Blue"].."</p>"
        g2.html = g2.html .. "<tr><td><p>Red: "..OPTS.wins["Red"].."</p>"
    else
        g2.html = g2.html .. "<tr><td><p>Red: "..OPTS.wins["Red"].."</p>"
        g2.html = g2.html .. "<tr><td><p>Blue: "..OPTS.wins["Blue"].."</p>"
    end
    
    g2.html = g2.html .. "<tr><td><p>&nbsp;</p>"

    g2.html = g2.html ..
    "<tr><td><input type='button' value='Replay' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

