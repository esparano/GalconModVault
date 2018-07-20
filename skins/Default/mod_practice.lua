LICENSE = [[
mod_classic.lua

Copyright (c) 2013 Phil Hassey
Modifed by: YOUR_NAME_HERE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]

---------------------------------------------------------------------------------
function pass()
end
---------------------------------------------------------------------------------
function classic_init()
    GAME.modules.classic = GAME.modules.classic or {}
    local obj = GAME.modules.classic


RANKS = {
    {ships=50,wait=5.0,rand=100,ships_show=1,redir=false,hint=true},
    {ships=65,wait=3.33,rand=70,ships_show=1,redir=false,hint=true},
    {ships=75,wait=2.25,rand=50,ships_show=1,redir=false,hint=false},
    {ships=75,wait=1.5,rand=50,ships_show=1,redir=false,hint=false},
    {ships=85,wait=1.5,rand=25,ships_show=0,redir=false,hint=false},
    {ships=100,wait=1.0,rand=0,ships_show=0,redir=false,hint=false},
    {ships=100,wait=1.0,rand=0,ships_show=0,redir=true,hint=false},
    {ships=120,wait=1.0,rand=0,ships_show=0,redir=true,hint=false},
    {ships=135,wait=1.0,rand=0,ships_show=0,redir=true,hint=false},
    {ships=150,wait=1.0,rand=0,ships_show=0,redir=true,hint=false},
}




function obj:init()
    
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
        sw = 600,
        sh = 400,
        neutrals = 23,
        homes = 1,
        size = 100,
        bots = 1,
    }

    do_load()
    
    OPTS.seed = os.time();

    if OPTS.rank == 1 then
        GAME.engine:next(GAME.modules.tutorial)
        return
    end

    init_menu();
    g2.state = "tabs"
    -- g2.tab = "lite"
end

function do_load()
    local data = json.decode(g2.data) or {}
    if data.rank then OPTS.rank = data.rank end
end
function do_save()
    local data = OPTS
    g2.data = json.encode(data)
end

function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

function init_game()

    OPTS.t = 0
    GAME.win_t = 0
    GAME.hint = nil

    for k,v in pairs(RANKS[OPTS.rank]) do
        OPTS[k] = v
    end

    OPTS.homes = 1
    OPTS.neutrals = 23
    OPTS.size = 100
    OPTS.bots = 1


    math.randomseed(OPTS.seed);
    
    g2.game_reset();
    
    local o = g2.new_user("neutral",COLORS[1])
    o.user_neutral = 1
    o.ships_production_enabled = 0
   
    local o1 = g2.new_user("player", COLORS[2])
    o1.user_rank = string.format("%x",OPTS.rank)
    if OPTS["ships_show"] == 1 then
        o1.ui_ships_show_mask = 0xf
    end
    
    GAME.player = o1
    g2.player = o1
    the_player = o1
    
    local bots = {}
    for i=1,OPTS.bots do
        local o2 = g2.new_user("enemy", COLORS[2+i]);
        the_bot=o2
        bots[i] = o2
    end
    
    
    --g2.speed = 16.0
    
    local pad = 50;
    local sw = OPTS.sw*OPTS.size / 100;
    local sh = OPTS.sh*OPTS.size / 100;
    

    local a = math.random(0,360)
    
    local users = 1.0 + OPTS.bots
    
    for i=1,OPTS.homes do
        local x,y
        x = sw/2 + (sw-pad*2)*math.cos(a*math.pi/180.0)/2.0
        y = sh/2 + (sh-pad*2)*math.sin(a*math.pi/180.0)/2.0
        g2.new_planet(o1, x,y, 100, 100);
        for j=1,OPTS.bots do
            o2 = bots[j]
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
end

function find_random(user,from)
    local planets = g2.search("planet");
    local to = nil; local to_v = 0
    for i,p in ipairs(planets) do
        local v = math.random(0,99999)
        if (to==nil or v > to_v) then
            to_v = v
            to = p
        end
    end
    return to
end
    
function find_finish(user,from)
    local planets = g2.search("planet -team:"..user:team().." -neutral")
    local to = nil; local to_v = 0;
    for _i,p in ipairs(planets) do
        local d = from:distance(p)
        local v = -p.ships_value + p.ships_production - d * 0.20;
        if (to==nil or v > to_v) then
            to_v = v;
            to = p;
        end
    end
    return to
end
    
function find_normal(user,from)
    local planets = g2.search("planet -team:"..user:team());
    local to = nil; local to_v = 0;
    for _i,p in ipairs(planets) do
        local d = from:distance(p)
        local v = -p.ships_value + p.ships_production - d * 0.20;
        if (to==nil or v > to_v) then
            to_v = v;
            to = p;
        end
    end
    return to
end

function do_redirect(user,find)
    local fleets = g2.search("fleet owner:"..user);
    for _i,from in ipairs(fleets) do
        to = find(user,from)
        if (to ~= nil and to ~= from) then
            from:fleet_redirect(to)
        end
    end
end

function count_ships()
    local r = {}
    
    local items = g2.search("planet OR fleet")
    for _i,o in ipairs(items) do
        local uid = o.owner_n
        r[uid] = mknumber(r[uid]) + o.ships_value + o.fleet_ships
    end
    
    return r
end

function is_winning(user)
    local r = count_ships()
    local totals = {0,0,0} --neutral,team,other
    local team = user:team()
    for n,t in ipairs(r) do
        local u = g2.item(n)
        if (u.user_neutral == true) then
            totals[1] = totals[1] + t
        elseif (u:team() ~= team) then
            totals[3] = totals[3] + t
        else
            totals[2] = totals[2] + t
        end
    end
    return (totals[2] > totals[3]*2)
end

function find_from(user)
    local from = nil; local from_v = 0;
    local planets = g2.search("planet owner:"..user);
    for _i,p in ipairs(planets) do
        local v = p.ships_value
        if (v < 17) then
            pass()
            elseif (v > from_v) then
            from_v = v;
            from = p;
        end
    end
    return from
end

function bot_classic(user)
    local perc = 65
    
    local find = find_normal
    if (is_winning(user)) then
        find = find_finish
    end
    if math.random(1,100) <= OPTS.rand then
        find = find_random
    end
        
    local from = find_from(user)
    if (from ~= nil) then
        local to = find(user,from)
        if (to ~= nil) then
            from:fleet_send(perc,to)
        end
    end
 
    if OPTS.redir then
        do_redirect(user,find)
    end
end

function find_hint(user,from)
    local planets = g2.search("planet -team:"..user:team());
    local to = nil; local to_v = 0;
    for _i,p in ipairs(planets) do
        local d = from:distance(p)
        local v = -p.ships_value + p.ships_production - d * 0.20;
        if (to==nil or v > to_v) then
            to_v = v;
            to = p;
        end
    end
    return to
end

function do_hint(force)
    if not force and not OPTS.hint then return end

    local user = GAME.player
    local best = nil
    local best_v = 0
    local total = 0
    for _,p in pairs(g2.search("planet owner:"..user)) do
        if p:selected() and p.ships_value > best_v then
            best = p
            best_v = p.ships_value
        end
    end

    local to = nil
    local find = find_hint
    if not force and (is_winning(user)) then
        find = find_finish
    end
    if best then to = find(user,best) end

    if GAME.hint then GAME.hint:destroy() ; GAME.hint = nil end
    if to == nil then return end

    local r = to.planet_r * 2
    local hint = g2.new_image('planet-hint',to.position_x-r,to.position_y-r,r*2,r*2)
    hint.render_color = 0x00ffff
    hint.render_blend = 1
    GAME.hint = hint

end


function obj:loop(t)
    if g2.state ~= "play" then return end

    do_hint()

    OPTS.t = OPTS.t + t
    if (OPTS.t >= OPTS.wait) then
        OPTS.t = OPTS.t - OPTS.wait
        local users = g2.search("user")
        for _i,user in ipairs(users) do
            if (user.title_value == "enemy") then
                bot_classic(user)
            end
        end
    end
    
    local win = nil;
    local planets = g2.search("planet -neutral")
    for _i,p in ipairs(planets) do
        local user = p:owner()
        if (win == nil) then win = user end
        if (win ~= user) then return end
    end
    
    if win == nil then 
        GAME.win_t = 0
    else
        GAME.win_t = GAME.win_t + t
    end

    if (win ~= nil) and GAME.win_t > 2.0 then
        if (win.has_player == true) then
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

function fix(v,d,a,b)
    if (type(v) == "string") then v = tonumber(v) end
    if (type(v) ~= "number") then v = d end
    if v < a then v = a end
    if v > b then v = b end
    return v
end

function obj:event(e)
    if (e["type"] == "onclick" and string.find(e["value"],"rank:") ~= nil) then
        OPTS.rank = tonumber(string.sub(e["value"],6))
        do_save()
        init_menu()
    end

    if (e["type"] == "onclick" and string.find(e["value"],"init:") ~= nil) then
        OPTS.rank = tonumber(string.sub(e["value"],6))
        do_save()
        if OPTS.rank == 1 then
            GAME.engine:next(GAME.modules.tutorial)
            return
        end
        g2.play_music("mus-play"..math.random(1,3))
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
    if (e["type"] == "onclick" and e["value"] == "skip") then
        OPTS.rank = math.max(OPTS.rank,2)
        do_save()
        g2.state = "login"
    end
    if (e["type"] == "pause") then
        init_pause();
        g2.state = "pause"
    end
    if (e["type"] == "onclick" and e["value"] == "menu") then
        init_menu()
        g2.state = "tabs"
    end
    if (e["type"] == "quit") then
        g2.state = "quit"
    end
    if (e["type"] == "onclick" and e["value"] == "tutorial") then
        GAME.engine:next(GAME.modules.tutorial)
    end
end

function init_menu()
--    <tr><td><p>Bots:</p><td><input type='text' name='bots' width=120 />
    g2.play_music("mus-menu")

    local html = [[
    <table>
    <tr><td align=left><h2 class='header'>Difficulty</h2>
    <tr><td><table class='box'>
    <tr><td>
    <table> ]]
    for n=1,10 do
        if (n%5)==1 then html = html .. "<tr>" end
        local kls="toggle0"
        if n == OPTS.rank then kls = "toggle1" end
        html = html .. "<td><input type='button' name='rank' class='"..kls.."'  onclick='rank:"..n.."' width=40><img src='rank"..n.."' width=40 height=40 /></input>"
    end
    html = html .. "</table>"
    local rnames = {"Cabin Boy","Ensign","Lieutenant","Commander","Captain","Admiral","1-Stripe Admiral", "2-Stripe Admiral", "3-Stripe Admiral", "Grand Admiral"}
    html = html .. "<tr><td><p>"..rnames[OPTS.rank].."</p>"

    html = html .. "</table>"

    html = html .. "<tr><td>&nbsp;"

    local kls = "ibutton1"; 


    local onclick = "init:"..OPTS.rank
    html = html .. "<tr><td align=center><input type='button' value='Play' onclick='"..onclick.."' class='"..kls.."'  icon='icon-play' /></td>"

    html = html .. "<tr><td align=center><input type='button' value='Tutorial' onclick='tutorial' class='"..kls.."'  icon='icon-practice' /></td>"

    html = html .. "<tr><td><input type='button' value='Menu' onclick='quit' icon='icon-menu' class='ibutton1'  />"

    html = html .. "</table>"

    g2.html = html
end

function init_getready()
    g2.html = ""..
    "<table>"..
    "<tr><td><h2>Get Ready</h2>"..
    "<tr><td>&nbsp;"..
    -- "<tr><td align=center><input type='button' value='Tap to Begin' onclick='resume' icon='icon-play' class='ibutton1' /></td>"..
    "<tr><td align=center><input type='button' value='START!' height=66 onclick='resume' icon='icon-play' class='xibutton1' ><h1>START!</h1></button></td>"..
    "";
end

function init_pause() 
    if g2.first then return init_pause_first() end
    g2.html = ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume' onclick='resume' icon='icon-play' class='ibutton1' />"..
    "<tr><td><input type='button' value='Restart' onclick='restart' icon='icon-restart' class='ibutton1' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' icon='icon-new_map' class='ibutton1' />"..
    "<tr><td><input type='button' value='Difficulty' onclick='menu' icon='icon-practice' class='ibutton1' />"..
    "<tr><td><input type='button' value='Menu' onclick='quit' icon='icon-menu' class='ibutton1'  />"..
    "";
end



function init_win() 
    if g2.first then return init_win_first() end
    g2.html = ""..
    "<table>"..
    "<tr><td><h2>Good Job!</h2>"..
    "<tr><td>&nbsp;"..
    "<tr><td><input type='button' value='Replay' onclick='restart' icon='icon-restart' class='ibutton1' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' icon='icon-new_map' class='ibutton1' />"..
    "<tr><td><input type='button' value='Difficulty' onclick='menu' icon='icon-practice' class='ibutton1'  />"..
    "<tr><td><input type='button' value='Menu' onclick='quit' icon='icon-menu' class='ibutton1'  />"..
    "";
end



function init_lose() 
    if g2.first then return init_lose_first() end
    g2.html = "" ..
    "<table>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' icon='icon-restart' class='ibutton1' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' icon='icon-new_map' class='ibutton1' />"..
    "<tr><td><input type='button' value='Difficulty' onclick='menu' icon='icon-practice' class='ibutton1'  />"..
    "<tr><td><input type='button' value='Menu' onclick='quit' icon='icon-menu' class='ibutton1'  />"..
    "";
end

function init_pause_first() 
    g2.html = ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume' onclick='resume' icon='icon-play' class='ibutton1' />"..
    "<tr><td><input type='button' value='Restart' onclick='restart' icon='icon-restart' class='ibutton1' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' icon='icon-new_map' class='ibutton1' />"..
    "<tr><td><input type='button' value='Skip' onclick='skip'  icon='icon-quit' class='ibutton1' />"..
    "</table>";
end

function init_win_first() 
    g2.html = ""..
    "<table>"..
    "<tr><td><h2>Good Job!</h2>"..
    "<tr><td>&nbsp;"..
    "<tr><td><input type='button' value='Continue' onclick='skip' icon='icon-menu' class='ibutton1'  />"..
    "</table>";
end

function init_lose_first()
    g2.html = "" ..
    "<table>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' icon='icon-restart' class='ibutton1' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' icon='icon-new_map' class='ibutton1' />"..
    "</table>";
end   

end

---------------------------------------------------------------------------------
function tutorial_init()
    GAME.modules.tutorial = GAME.modules.tutorial or {}
    local obj = GAME.modules.tutorial
    local G = {}
    function obj:init()
        g2.play_music("mus-lobby")
        G = tutorial_1()
        g2.html = ""..
        "<table>"..
        "<tr><td><input type='button' value='Resume' onclick='resume'  icon='icon-play' class='ibutton1' />"..
        "<tr><td><input type='button' value='Restart' onclick='restart'  icon='icon-restart' class='ibutton1' />"..
        "<tr><td><input type='button' value='Skip' onclick='skip'  icon='icon-quit' class='ibutton1' />"
        if not g2.first then
            g2.html = g2.html .. "<tr><td><input type='button' value='Difficulty' onclick='menu'  icon='icon-practice' class='ibutton1' />"..
            "<tr><td><input type='button' value='Menu' onclick='quit'  icon='icon-menu' class='ibutton1' />"
        end

        g2.html = g2.html .. "</table>"..
        "";
        -- "<tr><td><input type='button' value='Menu' onclick='menu' />"..
    end
    function obj:loop(t)
        do_hint(true)
        local win = nil
        local planets = g2.search("planet -neutral")
        for _i,p in pairs(planets) do
            local user = p:owner()
            if (win == nil) then win = user end
            if (win ~= user) then return end
        end
        if win == G.player then
            G.win_t = G.win_t + t
            if G.win_t >= 2 then
                G = G.post()
            end
        end
    end
    function obj:event(e) 
        if e.type == 'quit' then
            -- g2.quit = false
        end

        if e.type == 'onclick' and e.value == 'resume' then
            g2.state = "play"
        end
        if e.type == 'onclick' and e.value == 'restart' then
            G = tutorial_1()
        end
        if e.type == 'onclick' and e.value == 'skip' then
            GAME.module = GAME.modules.classic
            event({type='onclick',value='newmap'})
            -- tutorial_end()
        end
        if e.type == 'onclick' and e.value == 'menu' then
            GAME.module = GAME.modules.classic
            init_menu()
            g2.state = 'tabs'
            -- GAME.engine:next(GAME.modules.classic)
            -- ENGINE.engine:next(ENGINE.modules.title)
        end
        if (e["type"] == "onclick" and e["value"] == "quit") then
            g2.state = "quit"
        end
    end
end

function tutorial_setup(title,intro,post)
    local G = {}
    G.SW = 320
    G.SH = 320
    G.HY = G.SH-60
    G.post = post
    G.win_t = 0
    
    local COLORS = {0x555555,0x0000ff,0xff0000} 

    g2.state = "play"
    g2.game_reset()
    g2.bkgr_src = "background05"
    g2.view_set(0,0,G.SW,G.SH)

    local o = g2.new_user("neutral",COLORS[1])
    o.user_neutral = 1
    o.ships_production_enabled = 0
    G.neutral = o
    
    local o = g2.new_user("player",COLORS[2])
    o.ui_ships_show_mask = 0xf
    G.player = o
    GAME.player = o
    g2.player = o

    local o = g2.new_user("enemy",COLORS[3])
    G.bot = o
    
    local txt = g2.new_label(title,G.SW/2,20)
    txt.label_size = 32
    
    local y = 60
    for k,v in pairs(intro) do
        local txt = g2.new_label(v,G.SW/2,y)
        txt.label_size = 20
        y = y + 20
    end
    
    return G
end

function tutorial_1() 
    local G = tutorial_setup("Basic Gameplay",
        {
        "",
        "Tap to select your planet",
        "(indicated by spiral.)",
        "",
        "Then choose a target.",
        "(Tap on or drag to the",
        "enemy planet.)",
        },tutorial_2)

    g2.new_planet(G.player,80,G.HY,100,100)
    g2.new_planet(G.bot,G.SW-80,G.HY,50,45)
    
    return G
end

function tutorial_2()
    local G = tutorial_setup("Production",
        {
        "The number is ships on the planet.",
        "",
        "Large planets produce more ships.",
        "Grey planets are neutral.",
        "",
        "Take over the neutral planet so",
        "that you can produce enough",
        "ships to conquer the enemy.",
        },tutorial_3)

    g2.new_planet(G.player,80,G.HY+30,25,50)
    g2.new_planet(G.bot,G.SW-80,G.HY+30,30,50)
    g2.new_planet(G.neutral,G.SW/2,G.HY-10,100,3)
    
    return G
end

function tutorial_3()
    local G = tutorial_setup("Advanced Controls",
        {
        "Select multiple planets by tapping",
        "them individually, or select all by",
        "double-tapping one of them.",
        "",
        "Tap the % indicator to change",
        "your fleet size.",
        "",
        "Conquer the enemy to win!",
        },tutorial_end)
    
    g2.new_planet(G.player,60,G.HY+20,60,80)
    g2.new_planet(G.bot,G.SW-60,G.HY-20,20,12)
    g2.new_planet(G.bot,G.SW-90,G.HY+20,40,24)
    g2.new_planet(G.neutral,G.SW/2-35,G.HY-15,65,15)
    g2.new_planet(G.neutral,G.SW/2+15,G.HY+30,45,10)
    
    return G
end
    

function tutorial_end()
    -- ext_achievement_submit("tutorial")
    GAME.module = GAME.modules.classic
    event({type='onclick',value='newmap'})
end

---------------------------------------------------------------------------------
function help_init()
    GAME.modules.help = GAME.modules.help or {}
    local obj = GAME.modules.help
    local G = {}
    function obj:init()
        g2.html = "<table><tr><td><h1>Help</h1>"..
        "<tr><td>&nbsp;"..

        "<tr><td align=left><h2 class='header'>Basic Gameplay</h2>"..
        "<tr><td class='box'><p width=240>"..
        "Tap to select your planet "..
        "(indicated by spiral.) "..
        "<br/><br/>"..
        "Then choose a target. "..
        "(Tap on or drag to the "..
        "enemy planet.) "..
        "</p>"..
        "<tr><td>&nbsp;"..

        "<tr><td align=left><h2 class='header'>Production</h2>"..
        "<tr><td class='box'><p width=240>"..
        "The number is ships on the planet. "..
        "<br/><br/>"..
        "Large planets produce more ships. "..
        "Grey planets are neutral. "..
        "<br/><br/>"..
        "Take over the neutral planet so "..
        "that you can produce enough "..
        "ships to conquer the enemy. "..
        "</p>"..
        "<tr><td>&nbsp;"..

        "<tr><td align=left><h2 class='header'>Advanced Controls</h2>"..
        "<tr><td class='box'><p width=240>"..
        "Select multiple planets by tapping "..
        "them individually, or select all by "..
        "double-tapping one of them. "..
        "<br/><br/>"..
        "Tap the % indicator to change "..
        "your fleet size. "..
        "<br/><br/>"..
        "Conquer the enemy to win! "..
        "</p>"..
        "<tr><td>&nbsp;"..

        "<tr><td><input type='button' value='Back' onclick='menu' />"..
        "</table>"
        g2.state = 'tabs';
    end
    function obj:loop(t)
    end
    function obj:event(e) 
        if e.type == 'quit' then
            -- g2.quit = false
        end
        if e.type == 'onclick' and e.value == 'menu' then
            GAME.module = GAME.modules.classic
            init_menu()
            g2.state = 'tabs'
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
        self:next(GAME.modules.classic)
    end
    
    function obj:event(e)
        if e.type == 'help' then
            self:next(GAME.modules.help)
        end
        if g2.first and e.type == 'quit' then
            g2.quit = false
            e = {type='onclick',value='skip'}
        end
        GAME.module:event(e)
    end
    
    function obj:loop(t)
        GAME.module:loop(t)
    end
end
--------------------------------------------------------------------------------
function mod_init()
    global("GAME")
    GAME = GAME or {}
    engine_init()
    classic_init()
    tutorial_init()
    help_init()
end
--------------------------------------------------------------------------------
function init() GAME.engine:init() end
function loop(t) GAME.engine:loop(t) end
function event(e) GAME.engine:event(e) end
--------------------------------------------------------------------------------
mod_init()
