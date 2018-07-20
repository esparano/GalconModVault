
function init()
	g2.state = 'none'
	global("G") 
	G = {}
	G.t = 0
    G.ct = 0
	global("OPTS")
	OPTS = {rand=0,redir=true}


    g2.game_reset();
	g2.bkgr_src = 'background05'
	g2.bkgr_stars = 2 -- 2 zoom
    local o = g2.new_user("neutral",0x555555)
    o.user_neutral = 0
    o.ships_production_enabled = 0

    local f = 1
	G.width = 480*f
	G.height = 320*f
    for i=1,15 do
		local p = g2.new_planet(o,math.random(-G.width/2,G.width/2),math.random(-G.height/2,G.height/2),math.random(15,100),math.random(0,50))
	end

    local u1 = g2.new_user("u1",0x0000ff) 
    u1.fleet_crash = 100
    u1.fleet_image = 'ship-5'
    u1.planet_style = json.encode({ texture="tex3",ambient=true, lighting=true,addition=true,drawback=true,alpha=0.65 })
    local u2 = g2.new_user("u2",0xff0000) 
    u2.fleet_crash = 100
    local imgs = {11,12,14,15,16,17,18,19,20}
    u2.fleet_image = 'ship-'..imgs[math.random(1,#imgs)]
    u2.planet_style = json.encode({
                texture="tex0",lighting=true,normal=true, 
                overdraw = {texture="tex5", ambient=true,addition=true}
                })
    G.bots = {}
    G.bots[#G.bots+1] = u1
    G.bots[#G.bots+1] = u2

    local production = 200
    local ships = 500
    local p1 = g2.new_planet(u1,-G.width/2,-G.height/2,production,ships)
    local p2 = g2.new_planet(u2,G.width/2,G.height/2,production,ships)
    G.homes = {}
    G.homes[#G.homes+1] = p1
    G.homes[#G.homes+1] = p2

    g2.planets_settle(-G.width/2,-G.height/2,G.width,G.height)

    G.target = {-G.width/2,-G.height/2,G.width/2,G.height/2}
    -- G.view = {G.width/2,G.height/2,G.width/2+1,G.height/2+1}
    local f = 100--8
    G.view = {-G.width*f,-G.height*f,G.width*f,G.height*f}
    
    build_galaxy()

    zoom()
end

function _map_randomnorm(a,b)
        local v = 0
        for i=1,12 do
                v = v + math.random() * 2 - 1
        end
        v = v/12
        return (a + b) / 2 + v * (b - a) / 2
end

function _map_randomf(a,b)
        return a + math.random() * (b-a)
end

function build_galaxy()
    local arms = {}
    local afuzz = 80
    local pfuzz = 1
    for i=1,5 do 
            arms[i] = 360 * i / 5
    end
    local plist = {}
    local team = g2.new_team("team",0xffaa55)
    local user = g2.new_user("star",0xffffee,team)
    local GSIZE = 2000
    local psize = GSIZE * 5

    local delay = {}

    for i=1,512 do
        local r = _map_randomf(0,psize/2)
        local a = (r * 250/psize +arms[math.random(1,#arms)] + _map_randomnorm(-afuzz,afuzz)) * math.pi / 180
        local x = math.cos(a) * r + _map_randomf(-pfuzz,pfuzz) 
        local y = math.sin(a) * r + _map_randomf(-pfuzz,pfuzz) 
        -- local planet = g2.new_planet(user,x,y,200,200)
        local z = math.random(50,250) * 0.5
        local o = g2.new_image('map-star1',x-z/2,y-z/2,z,z)
        o.render_blend = 1
        o.has_xflag = 1
        o._position_x = o.position_x
        o._position_y = o.position_y
        plist[#plist+1] = o

		-- local dd = math.sqrt(x*x+y*y)/(GSIZE*2)
		nearby = 1
		local r = math.sqrt(x*x+y*y)
		local cz = 3 * (math.random(16,72) * 2 / math.sqrt(2)) / math.pow(nearby,1/4)
		local img = 'map-nebula1'
		if math.random(0,r) < GSIZE/5 then img = 'map-nebula2' end
        delay[#delay+1] = {x=x,y=y,cz=cz,img=img}

    end
    for _,e in ipairs(delay) do
        local x= e.x ; local y =e.y ; local cz = e.cz ; local img = e.img
        local o = g2.new_image(img,x,y,cz*2,cz*2)
        local item = o
        item.render_blend = 1
        item.image_cx = cz
        item.image_cy = cz
        item.image_a = _map_randomf(0,math.pi*2)
        item._position_x = x
        item._position_y = y
        item.has_xflag = true

        plist[#plist+1] = o        
    end


    G.plist = plist
    G.zscale = 0.5
end

function zoom()
	local f = 0.975
	for i=1,4 do
		G.view[i] = G.view[i] * f + G.target[i] * (1-f)
	end
	g2.view_set(G.view[1],G.view[2],G.view[3]-G.view[1],G.view[4]-G.view[2])

	local alpha = math.max(0,math.min(1,((G.view[3]-G.view[1]) / G.width - 1.0) * (1/12)))
	local a = math.floor(255 * alpha)
    if a <= 4 then
        for _,p in ipairs(G.plist) do
            p:destroy()
        end
        G.plist = {}
    else
        -- local nlist = {}
        for _,p in ipairs(G.plist) do
            p.render_alpha = a
            -- local z = p.image_w
            -- if p.position_x < (G.view[1]-z) or
            --     p.position_x > (G.view[3]+z) or
            --     p.position_y < (G.view[2]-z) or
            --     p.position_y > (G.view[4]+z) then
            --     p:destroy() 
            -- else
            --     nlist[#nlist+1] = p
            -- end
        end
        -- G.plist = nlist
    end


end


function loop(t)
	local pt = G.t
	G.t = G.t + t
    local first = true
    while first or G.ct < G.t do
        first = false
        G.ct = G.ct + 1/60.0
        zoom()
    end
    local f = 0.999
    -- G.zscale = G.zscale * f + 1.0 * (1-f)
    local aa = -G.t*0.5
    g2_ext_call("galcon2:map_rotate",json.encode({t=0,aa=aa,zscale=G.zscale,zstar=0}))


	if pt == 0 or math.floor(G.t*2) ~= math.floor(pt*2) then
		for _,u in ipairs(G.bots) do
			bot_classic(u)
		end
		-- for _,p in ipairs(G.homes) do
		-- 	p.ships_value = p.ships_value + 10
		-- end
	end
end

function event(e)
end



-----------------------------------------------------------------------------
function mknumber(v)
    return tonumber(v) or 0
end
function pass() end
-----------------------------------------------------------------------------

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
        if p.ships_production > 100 then v = 0 end -- don't attack homes
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
