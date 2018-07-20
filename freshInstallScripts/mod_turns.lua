LICENSE = [[
mod_turns.lua

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
        turns = 20,
        homes = 1,
        players = 4,
        names = {},
        seed = 0,
        t = 0.0,
        tmax = 0.0,
        rank = 1,
        sw = 640,
        sh = 480,
        neutrals = 23,
        homes = 1,
        size = 125,
        bots = 0,
        ships = 100,
        turn = 1,
        
    }
    
    OPTS.seed = os.time();
    init_options();
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
   
    local players = {}
    for i=1,OPTS.players do
        local o1 = g2.new_user(OPTS.names[i], COLORS[1+i])
        players[i] = o1
    end
    
    OPTS.users = players

    local pad = 50;
    local sw = OPTS.sw*OPTS.size / 100;
    local sh = OPTS.sh*OPTS.size / 100;
    

    local a = math.random(0,360)
    
    local users = OPTS.players + OPTS.bots 
    
    for i=1,OPTS.homes do
        local x,y
        for j=1,OPTS.players do
            o2 = players[j]
            a = a+360/(users)
            x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
            y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
            g2.new_planet(o2, x,y, 100, OPTS.ships);
        end
            
        a = a+360/(users)
        a = a + 360/(OPTS.homes*users)
        
    end
    
    for i=1,OPTS.neutrals do
        g2.new_planet( o, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end
    
    g2.planets_settle()
    OPTS.turn = 0
    OPTS.state = "play"

end


function count_production()
    local r = {}
    local items = g2.search("planet -neutral")
    for _i,o in ipairs(items) do
        local user = o:owner()
        r[user] = mknumber(r[user]) + o.ships_production
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
    
            

function next_turn()
    OPTS.turn = OPTS.turn + 1
    OPTS.tmax = OPTS.turn * 5.0

    if (OPTS.turn > (OPTS.turns*OPTS.players)) then
        g2.player = nil
        OPTS.state = "wait"
        g2.html = [[
        <table>
        <tr><td><p>Watch the finish</p>
        <tr><td><p>&nbsp;</p>
        <tr><td><input type='button' value='Continue' onclick='resume' />
        </table>
        ]]
        g2.state = "pause"
        return
    end
    
    p = OPTS.users[1+((OPTS.turn-1)%OPTS.players)]
    g2.player = p

    local r = g2.search("planet OR fleet owner:"..p)
    if #r == 0 then
        OPTS.t = OPTS.t + 5.0
        next_turn()
        return
    end

    init_next(p.title_value)
    g2.state = "pause"
   
end

function loop(t)
    if OPTS.t < OPTS.tmax then
        OPTS.t = OPTS.t + t
    end
    local diff = OPTS.tmax - OPTS.t
    
    if diff < 0.1 then
        g2.speed = 0.0001
    else
        g2.speed = 10.0 * diff / 1.0
    end
    
    if OPTS.state == "wait" then
        g2.speed = 1.0
        local fleets = g2.search("fleet")
        if #fleets == 0 then
            win = most_production()
            init_end(win.title_value)
            g2.state = "pause"
        end
    end

    local win = nil;
    local planets = g2.search("planet -neutral")
    for _i,p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then win = user end
        if (win ~= user) then return end
    end
    
    if (win ~= nil) then
        init_end(win.title_value)
        g2.state = "pause"
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
    if (e.type == "onclick" and e.value == "options") then
        OPTS.players = fix(g2.form.players,1,2,8)
        OPTS.neutrals = fix(g2.form.neutrals,23,0,100)
        OPTS.turns = fix(g2.form.turns,1,1,100)
        init_names()
        g2.state = "menu"
    end
    
    if (e.type == "onclick" and e.value == "names") then
        for i = 1,OPTS.players do
            OPTS.names[i] = g2.form["name"..tostring(i)]
        end
        init_game();
        init_getready();
        g2.state = "pause"
    end
    
    if (e["type"] == "onclick" and e["value"] == "newmap") then
        OPTS.seed = OPTS.seed + 1;
        init_game();
        init_getready();
        g2.state = "pause"
    end
    if (e["type"] == "onclick" and e["value"] == "restart") then
        init_game();
        init_getready();
        g2.state = "pause"
    end
    
    if (e["type"] == "onclick" and e["value"] == "next") then
        next_turn()
        g2.state = "pause"
    end
    
    if (e["type"] == "onclick" and e["value"] == "resume") then
        g2.state = "play"
    end
    
    if (e["type"] == "onclick" and e["value"] == "quit") then
        g2.state = "quit"
    end
    if (e["type"] == "pause") and OPTS.state == "play" then
        next_turn()
        g2.state = "pause"
        return
    end
    if (e["type"] == "pause") and OPTS.state == "wait" then
        win = most_production()
        init_end(win.title_value)
        g2.state = "pause"
        return
    end
end

function init_options()
    local html = [[
    <table><tr><td colspan=2><h1>Turn-based Galcon</h1>
    <tr><td colspan=2><p>Mod by Phil Hassey</p>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>Players:</p><td><input type='text' name='players' />
    <tr><td><p>Neutrals:</p><td><input type='text' name='neutrals'  />
    <tr><td><p>Rounds:</p><td><input type='text' name='turns' />
    <tr><td><p>&nbsp;</p>
    <tr><td colspan=2><input type='button' value='Continue' onclick='options' />
    </table>
]];
    
    html = string.gsub(html,"$Z",34)
    
    g2.html = html
    g2.form.neutrals = OPTS.neutrals
    g2.form.players = OPTS.players
    g2.form.turns = OPTS.turns
end

function init_names()
    local html = [[
    <table><tr><td colspan=2><h1>Player Names</h1>
    <tr><td><p>&nbsp;</p>
]];
    
    for i = 1,OPTS.players do
    
--         html = html .. "<tr><td><p>#"..tostring(i)..": </p><td><input type='text' name='name"..tostring(i).."' />"
        if (i%2)==1 then html = html .. "<tr>" end
        html = html .. "<td><input type='text' name='name"..tostring(i).."' value='player"..tostring(i).."' />"
    end

    html = html .. [[
    <tr><td><p>&nbsp;</p>
    <tr><td colspan=2><input type='button' value='Play!' onclick='names' />
    </table>
]];
    
    g2.html = html
end

function init_getready()
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>Is this map okay?</h1>"..
    "<tr><td><p>&nbsp;</p>"..
    "<tr><td><input type='button' value=\"No! Try another.\" onclick='newmap' />"..
    "<tr><td><input type='button' value=\"Yes! Let's play!\" onclick='next' />"..
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

function init_end(name) 
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>"..name.." Wins!</h1>"..
    "<tr><td><p>&nbsp;</p>"..
    "<tr><td><input type='button' value='Replay' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end


function init_next(name)
    local t = 1+math.floor((OPTS.turn-1)/OPTS.players)
    g2.html = ""..
    "<table>"..
    "<tr><td><p>Round "..tostring(t).." / "..tostring(OPTS.turns).."</p></td>"..
    "<tr><td><p>&nbsp;</p>"..
    "<tr><td><h1>"..name.."'s turn</h1>"..
    "<tr><td><p>&nbsp;</p>"..
    "<tr><td><input type='button' value='Continue' onclick='resume' />"..
    "</table>"..
    "";
end
