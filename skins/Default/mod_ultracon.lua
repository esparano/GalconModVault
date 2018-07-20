LICENSE = [[
mod_classic.lua

Copyright (c) 2013 Phil Hassey
Modifed by: Medeman

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]


RANKS = {
    {ships=50,wait=5.0,rand=100,ships_show=1,redir=0},
    {ships=65,wait=3.33,rand=70,ships_show=1,redir=0},
    {ships=75,wait=2.25,rand=50,ships_show=1,redir=0},
    {ships=75,wait=2.25,rand=50,ships_show=0,redir=0},
    {ships=85,wait=1.5,rand=25,ships_show=0,redir=0},
    {ships=100,wait=1.0,rand=0,ships_show=0,redir=0},
    {ships=100,wait=1.0,rand=0,ships_show=0,redir=1},
    {ships=120,wait=1.0,rand=0,ships_show=0,redir=1},
    {ships=135,wait=1.0,rand=0,ships_show=0,redir=1},
    {ships=150,wait=1.0,rand=0,ships_show=0,redir=1},
	{ships=250,wait=0.5,rand=0,ships_show=0,redir=1}
}



function pass()
end

function init()
    
    -- set up global data here
    
    COLORS = {0x555555,
		0x0000ff,0x99aaff,
		0xbb99ff,0xee99ff,
		0xff99aa,0xffbb99,
		0xffee99,0xaaff99,
		0x99ffee,0x99ddff,
		0xaaaaaa,0x0000ff,
		0x8000ff,0xff00ff,
		0xff0000,0xff8000,
		0xffff00,0x00ff00,
		0x00ffff,0x0080ff,
		0x545454,0x000080,
		0x550080,0x80006a,
		0x801500,0x805500,
		0x6a8000,0x008015,
		0x006a80,0x002a80,
		0xea4378,0x0815ae,
		0xff3216,0x00aefb,
		0x55176f,0xff0815,
    }
        
    OPTS = {
        seed = 0,
        t = 0.0,
        rank = 1,
        sw = 640,
        sh = 480,
        neutrals = 35,
        homes = 1,
        size = 100,
        bots = 5,
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
   
    local o1 = g2.new_user("player", COLORS[2])
--    o1.has_player = 1
    if OPTS["ships_show"] == 1 then
        o1.ui_mask = "YsfrtTstNstEst"
    end

    g2.player = o1
    
    local bots = {}
    for i=1,OPTS.bots do
        local o2 = g2.new_user("enemy", COLORS[2+i]);
--        o2.has_bot = 1
--        o2.bot_name = "classic"
--        o2.ships_show = OPTS["ships_show"]

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
        r[uid] = mknumber(r[uid]) + o.ships_value
    end
    
    return r
end

function is_winning(user)
    local r = count_ships()
    local totals = {0,0,0} --neutral,team,other
    local team = user:team()
    for n,t in ipairs(r) do
        local u = g2.item(n)
        if (u.user_neutral == 1) then
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


function loop(t)
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
    
    if (win ~= nil) then
        if (win.has_player == 1) then
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

function event(e)
    if (e["type"] == "onclick" and string.find(e["value"],"init:") ~= nil) then
        OPTS.rank = tonumber(string.sub(e["value"],6))
        for k,v in pairs(RANKS[OPTS.rank]) do
            OPTS[k] = v
        end
        OPTS.homes = fix(g2.form.homes,1,1,500)
        OPTS.neutrals = fix(g2.form.neutrals,35,0,1000)
        OPTS.size = fix(g2.form.size,100,100,1000)
        OPTS.bots = fix(g2.form.bots,5,1,35)
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
    <table>
		<tr>
			<td colspan=100><p>Ultracon 0.4, by Medeman</td>
		</tr>
		<tr>
			<td colspan=25><p>Bots:</p></td>
			<td colspan=25><input type="text" name="bots" width="40" /></td>
			<td colspan=25><p>Homes:</p></td>
			<td colspan=25><input type="text" name="homes" width="40" /></td>
		</tr>
		<tr>
			<td colspan=25></td>
			<td colspan=25><p>1-35</p></td>
			<td colspan=25></td>
			<td colspan=25><p>1-500</p></td>
		</tr>
		<tr>
			<td colspan=25><p>Neutrals:</p></td>
			<td colspan=25><input type="text" name="neutrals" width="40" /></td>
			<td colspan=25><p>Size:</p></td>
			<td colspan=25><input type="text" name="size" width="40" /></td>
		</tr>
		<tr>
			<td colspan=25></td>
			<td colspan=25><p>0-1000</p></td>
			<td colspan=25></td>
			<td colspan=25><p>100-1000</p></td>
		</tr>
		<tr>
			<td colspan=10><input type='image' src='rank1.png' width=20 height=20 onclick='init:1' /></td>
			<td colspan=10><input type='image' src='rank2.png' width=20 height=20 onclick='init:2' /></td>
			<td colspan=10><input type='image' src='rank3.png' width=20 height=20 onclick='init:3' /></td>
			<td colspan=10><input type='image' src='rank4.png' width=20 height=20 onclick='init:4' /></td>
			<td colspan=10><input type='image' src='rank5.png' width=20 height=20 onclick='init:5' /></td>

			<td colspan=10><input type='image' src='rank6.png' width=20 height=20 onclick='init:6' /></td>
			<td colspan=10><input type='image' src='rank7.png' width=20 height=20 onclick='init:7' /></td>
			<td colspan=10><input type='image' src='rank8.png' width=20 height=20 onclick='init:8' /></td>
			<td colspan=10><input type='image' src='rank9.png' width=20 height=20 onclick='init:9' /></td>
			<td colspan=10><input type='image' src='rank10.png' width=20 height=20 onclick='init:10' /></td>
		</tr>
		<tr>
			<td colspan=20></td>
			<td colspan=10><input type='image' src='spark.png' width=20 height=20 onclick='init:11' /></td>
			<td colspan=50><p>Hardcore mode</p></td>
			<td colspan=40></td>
		</tr>
		<tr>
			<td colspan=100>
				<img src="logo.png" height=50 />
			</td>
		</tr>
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

function init_win() 
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><input type='button' value='Replay' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

function init_lose() 
    g2.html = "" ..
    "<table>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' />"..
    "<tr><td><input type='button' value='New Map' onclick='newmap' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end
