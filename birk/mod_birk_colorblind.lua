LICENSE = [[
mod_classic.lua

Copyright (c) 2013 Phil Hassey

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]


RANKS = {
    {ships=50,wait=5.0,rand=100,ships_show=1,redir=0},
    {ships=65,wait=3.33,rand=70,ships_show=1,redir=0},
    {ships=75,wait=2.25,rand=50,ships_show=1,redir=0},
    {ships=75,wait=2.25,rand=50,ships_show=0,redir=0},
    {ships=85,wait=1.5,rand=25,ships_show=0,redir=0},
    {ships=100,wait=1.0,rand=0,ships_show=0,redir=0},
    {ships=125,wait=0.75,rand=0,ships_show=0,redir=1},
    {ships=150,wait=0.5,rand=0,ships_show=0,redir=1},
    {ships=175,wait=0.5,rand=0,ships_show=0,redir=1},
    {ships=200,wait=0.5,rand=0,ships_show=0,redir=1},
}



function pass()
end

function u_team(uid)
    return g2_item_get(uid,"user_team_n")
end
function p_team(pid)
    return g2_item_get(g2_item_get(pid,"owner_n"),"user_team_n")
end

function init()
    
    -- set up global data here
    
    COLORS = {0x333333,
        0x000099,
        0xffffff,
        0xffffff,0xffffff,
        0xffffff,0xffffff,
        0xffffff,0xffffff,
        0xffffff,0xffffff,
        0xffffff,0xffffff,
    }
        
    OPTS = {
        seed = 0,
        t = 0.0,
        rank = 1,
        sw = 640,
        sh = 480,
        neutrals = 50,
        homes = 1,
        size = 200,
        bots = 3,
    }
    
    OPTS.seed = os.time();
    init_menu();
    g2_param_set("state","menu");
end

function init_game()
    OPTS.t = 0
    math.randomseed(OPTS.seed);
    g2_game_reset();
    
    local o = g2_user_init("neutral", COLORS[1]);
    g2_item_set(o,"user_neutral",1);
    g2_item_set(o,"ships_production_enabled",0);
    
    local o1 = g2_user_init("player", COLORS[2]);
    g2_item_set(o1,"has_player",1);

    local bots = {}
    for i=1,OPTS.bots do
        local o2 = g2_user_init("enemy", COLORS[2+i]);
        g2_item_set(o2,"has_bot",1);
        g2_item_set(o2,"bot_name","classic");
        g2_item_set(o2,"ships_show",OPTS.ships_show);
        bots[i] = o2
    end
    
    --g2_param_set("speed",16.0);

    local pad = 50;
    local sw = OPTS.sw*OPTS.size / 100;
    local sh = OPTS.sh*OPTS.size / 100;
    
    for i=1,OPTS.neutrals do
        g2_planet_init( o, math.random(pad,sw-pad),math.random(pad,sh-pad), math.random(15,100), math.random(0,50));
    end
    local a = math.random(0,360)
    
    local users = 1.0 + OPTS.bots
    
    for i=1,OPTS.homes do
        local x,y
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2_planet_init(o1, x,y, 100, 100);
        for j=1,OPTS.bots do
            o2 = bots[j]
            a = a+360/(users)
            x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
            y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
            g2_planet_init(o2, x,y, 100, OPTS.ships);
        end
            
        a = a+360/(users)
        a = a + 360/(OPTS.homes*users)
        
    end
    
    g2_planets_settle();
end

function find_random(uid,from)
    local planets = g2_items_find("planet");
    local to = 0; local to_v = 0;
    for _i,pid in ipairs(planets) do
        local v = math.random(0,99999)
        if (to==0 or v > to_v) then
            to_v = v;
            to = pid;
        end
    end
    return to
end
    
function find_finish(uid,from)
    local planets = g2_items_find("planet");
    local to = 0; local to_v = 0;
    local team = u_team(uid);
    for _i,pid in ipairs(planets) do
        if (p_team(pid) == team) then
            pass()
        elseif (g2_item_get(g2_item_get(pid,"owner_n"),"user_neutral") == 1) then
            pass()
        else
            local dx = g2_item_get(pid,"position_x")-g2_item_get(from,"position_x");
            local dy = g2_item_get(pid,"position_y")-g2_item_get(from,"position_y");
            local d = math.sqrt(dx*dx+dy*dy);
            local v = -g2_item_get(pid,"ships_value") + g2_item_get(pid,"ships_production") - d * 0.20;
            if (to==0 or v > to_v) then
                to_v = v;
                to = pid;
            end
        end
    end
    return to
end
    
function find_normal(uid,from)
    local planets = g2_items_find("planet");
    local to = 0; local to_v = 0;
    local team = u_team(uid);
    for _i,pid in ipairs(planets) do
        if (p_team(pid) == team) then
            pass()
        else
            local dx = g2_item_get(pid,"position_x")-g2_item_get(from,"position_x");
            local dy = g2_item_get(pid,"position_y")-g2_item_get(from,"position_y");
            local d = math.sqrt(dx*dx+dy*dy);
            local v = -g2_item_get(pid,"ships_value") + g2_item_get(pid,"ships_production") - d * 0.20;
            if (to==0 or v > to_v) then
                to_v = v;
                to = pid;
            end
        end
    end
    return to
end

function do_redirect(uid,find)
    local fleets = g2_items_find("fleet");
    for _i,from in ipairs(fleets) do
        if (g2_item_get(from,"owner_n") ~= uid) then
            pass()
        else
            to = find(uid,from)
            if (to ~= 0 and to ~= from) then
                g2_fleet_redirect(from,to)
            end
        end
    end
end

function count_ships()
    local r = {}
    
    local planets = g2_items_find("planet");
    for _i,n in ipairs(planets) do
        local uid = g2_item_get(n,"owner_n")
        local pv = r[uid]
        if pv == nil then pv = 0 end
        r[uid] = pv + g2_item_get(n,"ships_value")
    end
    
    local fleets = g2_items_find("fleet");
    for _i,n in ipairs(fleets) do
        local uid = g2_item_get(n,"owner_n")
        local pv = r[uid]
        if pv == nil then pv = 0 end
        r[uid] = pv + g2_item_get(n,"ships_value")
    end
    
    return r
end

function is_winning(uid)
    local r = count_ships()
    local totals = {0,0,0} --neutral,team,other
    local team = u_team(uid)
    for n,t in ipairs(r) do
        if (g2_item_get(n,"user_neutral") == 1) then
            totals[1] = totals[1] + t
        elseif (u_team(n) ~= team) then
            totals[3] = totals[3] + t
        else
            totals[2] = totals[2] + t
        end
    end
    return (totals[2] > totals[3]*2)
end

function find_from(uid)
    local from = 0; local from_v = 0;
    local planets = g2_items_find("planet");
    for _i,pid in ipairs(planets) do
        if (g2_item_get(pid,"owner_n") ~= uid) then
            pass()
        else
            local v = g2_item_get(pid,"ships_value");
            if (v < 17) then
                pass();
                elseif (v > from_v) then
                from_v = v;
                from = pid;
            end
        end
    end
    return from
end

function bot_classic(uid)
    local perc = 65
    
    local find = find_normal
    if (is_winning(uid)) then
        find = find_finish
    end
    if math.random(1,100) <= OPTS.rand then
        find = find_random
    end
        
    local from = find_from(uid)
    if (from ~= 0) then
        local to = find(uid,from)
        if (to ~= 0) then
            g2_fleet_send(perc,from,to)
        end
    end
 
    if OPTS.redir then
        do_redirect(uid,find)
    end
end


function loop(t)
    OPTS.t = OPTS.t + t
    if (OPTS.t >= OPTS.wait) then
        OPTS.t = OPTS.t - OPTS.wait
        local users = g2_items_find("user");
        for _i,uid in ipairs(users) do
            local bot_name = g2_item_get(uid,"bot_name");
            if (bot_name == "classic") then
                bot_classic(uid);
            end
        end
    end
    
    local win = 0;
    local planets = g2_items_find("planet");
    for _i,pid in ipairs(planets) do
        local uid = g2_item_get(pid,"owner_n");
        if (g2_item_get(uid,"user_neutral") == 1) then
            pass()
        else
            if (win == 0) then win = uid; end
            if (win ~= uid) then return end
        end
    end
    
    if (win ~= 0) then
        if (g2_item_get(win,"has_player")==1) then
            init_win();
            g2_param_set("state","pause");
            return;
        else
            init_lose();
            g2_param_set("state","pause");
            return;
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

function event(e)
    if (e["type"] == "onclick" and string.find(e["value"],"init:") ~= nil) then
        OPTS.rank = tonumber(string.sub(e["value"],6))
        for k,v in pairs(RANKS[OPTS.rank]) do
            OPTS[k] = v
        end
        OPTS.homes = fix(g2_gui_get("homes"),1,1,100)
        OPTS.neutrals = fix(g2_gui_get("neutrals"),23,0,100)
        OPTS.size = fix(g2_gui_get("size"),100,100,1000)
        OPTS.bots = fix(g2_gui_get("bots"),1,1,11)
        e["value"] = "newmap"
    end
    if (e["type"] == "onclick" and e["value"] == "newmap") then
        OPTS.seed = os.time();
        init_game();
        init_getready();
        g2_param_set("state","pause");
    end
    if (e["type"] == "onclick" and e["value"] == "restart") then
        init_game();
        init_getready();
        g2_param_set("state","pause");
    end
    if (e["type"] == "onclick" and e["value"] == "resume") then
        g2_param_set("state","play");
    end
    if (e["type"] == "onclick" and e["value"] == "quit") then
        g2_param_set("state","quit");
    end
    if (e["type"] == "pause") then
        init_pause();
        g2_param_set("state","pause");
    end
end

function init_menu()
--    
    local html = [[
    <table><tr><td colspan=2><h1>Galcon Colorblind</h1>
    <tr><td colspan=2><p>Mod by Birk</p>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>Bots:</p><td><input type='text' name='bots' />
    <tr><td><p>Neutrals:</p><td><input type='text' name='neutrals'  />
    <tr><td><p>Size:</p><td><input type='text' name='size' />
    <tr><td><p>&nbsp;</p>
    <tr><td colspan=2><p>Select a rank to play!</p>
    <tr><td colspan=2>
    <table><tr>
    <td><input type='image' src='rank1.png' width=$Z height=$Z onclick='init:1' />
    <td><input type='image' src='rank2.png' width=$Z height=$Z onclick='init:2' />
    <td><input type='image' src='rank3.png' width=$Z height=$Z onclick='init:3' />
    <td><input type='image' src='rank4.png' width=$Z height=$Z onclick='init:4' />
    <td><input type='image' src='rank5.png' width=$Z height=$Z onclick='init:5' />
    <tr>
    <td><input type='image' src='rank6.png' width=$Z height=$Z onclick='init:6' />
    <td><input type='image' src='rank7.png' width=$Z height=$Z onclick='init:7' />
    <td><input type='image' src='rank8.png' width=$Z height=$Z onclick='init:8' />
    <td><input type='image' src='rank9.png' width=$Z height=$Z onclick='init:9' />
    <td><input type='image' src='rank10.png' width=$Z height=$Z onclick='init:10' />
    </table>
    </table>
]];
    
    html = string.gsub(html,"$Z",34)
    
    g2_param_set("html",html);
    g2_gui_set("neutrals",OPTS.neutrals);
    g2_gui_set("bots",OPTS.bots);
    g2_gui_set("homes",OPTS.homes);
    g2_gui_set("size",OPTS.size);
end

function init_getready()
    local html = ""..
    "<table>"..
    "<tr><td><h1>Get Ready!</h1>"..
    "<tr><td><input type='button' value='Tap to Begin' onclick='resume' />"..
    "";
    g2_param_set("html",html);
end

function init_pause() 
    local html = ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume' onclick='resume' />"..
    "<tr><td><input type='button' value='Restart' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
    g2_param_set("html",html);
end

function init_win() 
    local html = ""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><input type='button' value='Replay' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
    g2_param_set("html",html);
end

function init_lose() 
    local html = "" ..
    "<table>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
    g2_param_set("html",html);
end
