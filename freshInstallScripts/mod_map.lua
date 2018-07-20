

function _map_shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



function _map_randomf(a,b)
	return a + math.random() * (b-a)
end

function _map_my_new_pixart(data, x, y, w, h)
	local o = _g2_object(g2_item_init())
    o.has_position = true
    o.position_x = x
    o.position_y = y
    o.has_draw = true
    o.draw_type = "P"
    o.image_w = w
    o.image_h = h
    o.image_scale = 1
    o.render_color = 0xffffff
    o.render_alpha = 255
    o.render_blend = 0
    o.draw_pixart = data
    return o
end


function _map_sign(n) return n>0 and 1 or n<0 and -1 or 0 end

function _map_checkDir(pt1, pt2, pt3) 
	return _map_sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end

function _map_checkIntersect(l1p1, l1p2, l2p1, l2p2)
    return (_map_checkDir(l1p1,l1p2,l2p1) ~= _map_checkDir(l1p1,l1p2,l2p2)) and (_map_checkDir(l2p1,l2p2,l1p1) ~= _map_checkDir(l2p1,l2p2,l1p2))
end

function _map_distanceToSegment(p1,p2,p3) -- p3 is the point
	local x1 = p1.x ; local y1 = p1.y ; local x2 = p2.x ; local y2 = p2.y ;local x3 = p3.x ; local y3 = p3.y

	local px = x2-x1
	local py = y2-y1
	local dp = px*px + py*py
    local u = ((x3 - x1) * px + (y3 - y1) * py) / dp
    if u < 0 then u = 0 elseif u > 1 then u = 1 end
    local x = x1 + u * px
    local y = y1 + u * py
    local dx = x - x3
    local dy = y - y3
    local dist = math.sqrt(dx*dx+dy*dy)

    return dist
end

function _map_inTriangle(pt, p1,p2,p3) 
    local AB = (pt.y-p1.y)*(p2.x-p1.x) - (pt.x-p1.x)*(p2.y-p1.y)
    local CA = (pt.y-p3.y)*(p1.x-p3.x) - (pt.x-p3.x)*(p1.y-p3.y)
    local BC = (pt.y-p2.y)*(p3.x-p2.x) - (pt.x-p2.x)*(p3.y-p2.y)
    return (AB*BC>0 and BC*CA>0)
end

function _map_dist(a,b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return math.sqrt(dx*dx+dy*dy)
end

function table_find(r,v)
    for _k,_v in pairs(r) do
        if v == _v then return _k end
    end
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function str_join(delim,arr)
	local s = ""
	local pre = ""
	for i,v in ipairs(arr) do
		s = s .. pre .. v
		pre = delim
	end
	return s
end

function _map_find_nearby_stars(_origin)
	local G = GAME.map
	local origin = G.MINFO[_origin]
	local my_stars = {}
	local cid = G.player.clans_id
	local all_stars = G._stars

	for _,ce in pairs(G._stars) do
		local ok = true

		-- test for clan membership
		if ce.clans_id ~= cid then ok = false end

		-- test for constellation membership

		if ok then
			my_stars[#my_stars+1] = ce
		end
	end

	table.sort(my_stars,function(a,b) return _map_dist(origin,a) < _map_dist(origin,b) end)

	if table_find(my_stars,origin) == nil then return end

	local res = {}
	for _,ce in pairs(my_stars) do
		local ok = true

		-- test for crossing lines from any constellation

		-- test for non-clan points in triangle
		local p1 = ce
		for _,p2 in pairs(res) do
			for _,p3 in pairs(res) do
				if p1 ~= p2 and p2 ~= p3 and p3 ~= p1 then
					for _,te in pairs(all_stars) do
						if te ~= p1 and table_find(res,te) == nil then 
							if _map_inTriangle(te,p1,p2,p3) then
								ok = false
								goto xfail
							end
						end
					end
				end
			end
		end

		if ok then
			res[#res+1] = ce
		end

		if #res >= 12 then break end

		::xfail::
	end
	if #res < 5 then return end
	return res
end


function _map_cleanup()
	local G = GAME.map
	for _,item in pairs(G.INFO) do
		item:destroy()
	end
	G.INFO = {}
end

function _map_show_info1(sid,alpha)
	local G = GAME.map
	local star = g2.item(sid)
	local clan = G.CLANS[G.SINFO[sid].clans_id]

	local sz = 5
	local pad = 3
	local xx = star.position_x + star.planet_r + pad
	if star.position_x < G._VIEW[1] + G._VIEW[3]/2 then
		xx = star.position_x - (star.planet_r + pad + sz)
	end
	if clan ~= nil then 
		local item = _map_my_new_pixart(clan.icon,
			xx, star.position_y - sz/2, sz,sz
			)
		item.render_alpha = alpha
		G.INFO[#G.INFO+1] = item
	else
		if star.position_x < G._VIEW[1] + G._VIEW[3]/2 then
			xx = xx + sz
		end
		sz = 0
	end

	local label = g2.new_label(star.label_text,xx - 1,star.position_y +0.5,0x00ffff)
	label.label_size = 6
	label.label_font = "font-outline"
	label.label_valign = 0
	label.label_align = -1
	label.render_color = 0xffffff
	label.render_alpha = alpha

	if star.position_x >= G._VIEW[1] + G._VIEW[3]/2 then
		label.position_x = xx + sz + 1
		label.label_align = 1
	end

	G.INFO[#G.INFO+1] = label

end

function mknumber(v)
    v = tonumber(v)
    if v ~= nil then return v end
    return 0
end

function _map_number_format_long(v)
	v = tostring(math.floor(mknumber(v)))
	local n = 1
	while n > 0 do
		v,n = v:gsub("(%d+)(%d%d%d)","%1,%2")
	end
	return v
end

function _map_show_info2(sid,buttons)
	local G = GAME.map
	local star = g2.item(sid)
	local clan = G.CLANS[G.SINFO[sid].clans_id]

	-- local img = g2.new_circle(0x777777,star.position_x,star.position_y,star.planet_r + 8.5)

	-- local base_size = star.planet_r
	local base_size = 5.0

	local z = (base_size + 16.5) * 2
	local img = g2.new_image("planet-aura",star.position_x,star.position_y,z,z)
	img.image_cx = z/2 ; img.image_cy = z/2
	img.render_blend = 1
	-- img.render_color = 0x555555
	img.render_color = star.planet_color
	img.render_alpha = 0
	G.INFO[#G.INFO+1] = img

	-- local res = _map_find_nearby_stars(G.SINFO[sid].id)
	-- if res ~= nil then 
	-- 	for _,ne in pairs(res) do
	-- 		local sitem = G.SMAP[ne.id]
	-- 		local z = 5
	-- 		local img = g2.new_image("circle",sitem.position_x,sitem.position_y,z,z)
	-- 		img.image_cx = z/2 ; img.image_cy = z/2
	-- 		img.render_color = 0xff00ff
	-- 		G.INFO[#G.INFO+1] = img
	-- 	end
	-- end

	local sz = 5
	local pad = 3
	local xx = star.position_x - (base_size + pad + sz + 3)
	if clan ~= nil then 
		local item = _map_my_new_pixart(clan.icon,
			xx, star.position_y - sz/2, sz,sz
			)
		G.INFO[#G.INFO+1] = item
	end

	local label = g2.new_label(star.label_text,xx - 1,star.position_y +0.5,0x00ffff)
	label.label_size = 6
	label.label_font = "font-outline"
	label.label_valign = 0
	label.label_align = -1
	label.render_color = 0xffffff
	label.render_alpha = 0
	G.INFO[#G.INFO+1] = label

	local wy = star.position_y +1.5 + sz/2
	if clan ~= nil then 
		local label = g2.new_label("["..clan.name.."]",xx + sz,star.position_y +1.5 + sz/2,0x00ffff)
		label.label_size = 3
		label.label_font = "font-outline"
		label.label_valign = 0
		label.label_align = -1
		label.render_color = 0xffffff
		label.render_alpha = 0
		G.INFO[#G.INFO+1] = label

		wy = wy + 20
	end

	-- show value
	-- local px = star.position_x+3
	local px = star.position_x
	local py = star.position_y-15
	-- local txt = '+'.._map_number_format_long(math.floor(G.SINFO[sid].value))..' '
	local txt = G.SINFO[sid].label
	local label = g2.new_label(txt,px,py,0x00ffff)
	label.label_size = 3
	label.label_font = "font-outline"
	label.label_valign = 0
	label.label_align = 0
	label.render_color = 0xffffff
	label.render_alpha = 0
	G.INFO[#G.INFO+1] = label

	-- local img = g2.new_image('coin',px+0.5,py-1.25,3,3)
	-- img.render_color = 0xffffff
	-- G.INFO[#G.INFO+1] = img


	-- show war
	local war = G.WARS[G.SINFO[sid].id]
	if war ~= nil then
		local cwar = G.CLANS[war.attacker_id]

		local ap = 1 + war.attacker_points
		local dp = 1 + war.defender_points

		local p1 = dp / (ap+dp)
		local p2 = ap / (ap+dp)

		local pw = 35
		local ph = 5
		local px = star.position_x - pw/2
		local py = star.position_y + 15

		local img = g2.new_image('white',px-1,py-1,pw+2,ph+2)
		img.render_color = 0x000000
		G.INFO[#G.INFO+1] = img

		local img = g2.new_image('white',px,py,pw*p1,ph)
		img.render_color = tonumber(war.defender_color,16) or 0x444444
		G.INFO[#G.INFO+1] = img

		local img = g2.new_image('white',px+pw*p1,py,pw*p2,ph)
		img.render_color = tonumber(war.attacker_color,16) or 0x444444
		G.INFO[#G.INFO+1] = img
		-- local item = _map_my_new_pixart(cwar.icon,
		-- 	xx, wy, sz,sz
		-- 	)
		-- G.INFO[#G.INFO+1] = item

		local label = g2.new_label("vs. ["..cwar.name.."]",px+pw/2,py+ph+4,0x00ffff)
		label.label_size = 3
		label.label_font = "font-outline"
		label.label_valign = 0
		label.label_align = 0
		label.render_color = 0xffffff
		label.render_alpha = 0
		G.INFO[#G.INFO+1] = label


	end



	local yinc = 6
	local xinc = 6
	local yy = star.position_y - (#buttons - 1) * yinc / 2
	for _,b in pairs(buttons) do
		local xx = star.position_x + base_size + pad
		xx = xx + 3 - 2 * math.abs(_-(#buttons+1)/2)
		local icon = g2.new_image(b.icon,xx,yy,5,5)
		icon.image_cy = 2.5
		icon.render_alpha = 0
		icon.has_button = true
		icon.button_name = b.onclick..'/'..G.SINFO[sid].id
		G.INFO[#G.INFO+1] = icon
		local label = g2.new_label(b.label,xx+xinc,yy)
		label.label_align = 1
		label.label_size = 3
		label.label_font = "font-outline"
		label.render_color = 0xaaaaaa
		label.render_alpha = 0
		G.INFO[#G.INFO+1] = label
		yy = yy + yinc
	end


end

function _map_show_labels()
	local G = GAME.map
	_map_cleanup()	
	if not _map_ZOOM_DONE() then return end
	local cx = G._VIEW[1]+G._VIEW[3]/2
	local cy = G._VIEW[2]+G._VIEW[4]/2
	local mdd = 80*80

	-- for _,star in pairs(G.stars) do
	for _,star in pairs(g2.search("planet -clip")) do
		local x = star.position_x
		local y = star.position_y
		local dx = x-cx; local dy = y-cy
		local dd = dx*dx+dy*dy
		-- if x > _VIEW[1] and x < (_VIEW[1]+_VIEW[3]) and
			-- y > _VIEW[2] and y < (_VIEW[2]+_VIEW[4]) then
		if dd < mdd then
			local alpha = (mdd - dd) * 255 / mdd 
			_map_show_info1(star.n,alpha)
		end
	end

	for _,player in pairs(G.ships) do
		local star = player.item
		local x = star.position_x
		local y = star.position_y
		local dx = x-cx; local dy = y-cy
		local dd = dx*dx+dy*dy
		if dd < mdd then
			local alpha = (mdd - dd) * 255 / mdd 
			local label = g2.new_label(star.label_text,star.position_x,star.position_y)
			label.label_font = "font-outline"
			label.label_size = 6
			label.label_align = 0
			label.label_valign = 0
			label.render_alpha = alpha
			G.INFO[#G.INFO+1] = label
		end
	end

end

function _map_set_default_view()
	local G = GAME.map
	G.VIEW = {-G.ZSIZE/2 + G.ZSIZE/6,-G.ZSIZE/2 + G.ZSIZE/6,G.ZSIZE - G.ZSIZE/3,G.ZSIZE - G.ZSIZE/3}
end

function _map_ZOOM_DONE()
	local G = GAME.map
	local z = 10
	return math.abs(G.VIEW[3] - G._VIEW[3]) < z and math.abs(G.VIEW[4] - G._VIEW[4]) < z
end

function _map_do_add_flare(img,x,y,r,a,xs,ys,rot,color)
	local G = GAME.map
	xs = xs or 2
	ys = ys or 0.5
	local item = g2.new_image(img,x,y,r*2*xs,r*2*ys)
	item.render_blend = 1
	item.render_alpha = a 
	item.render_color = color

	item.image_cx = r*xs
	item.image_cy = r*ys
	item.image_a = rot
	-- item.image_a = _map_randomf(0,math.pi*2)
	G.FLARE[#G.FLARE+1] = item

end
function _map_add_flare(star,a,zx,zy,sz,rot)
	local G = GAME.map
	local x = star.position_x
	local y = star.position_y
	_map_do_add_flare("map-flare3",x,y,sz*0.75,a,1,1,rot,star.planet_color)

end

function _map_lens_flare()
	local G = GAME.map
	for _,item in pairs(G.FLARE) do
		item:destroy()
	end

	G.FLARE = {}

	if G.FOCUS == nil then return end

	local cx = G._VIEW[1]+G._VIEW[3]/2
	local cy = G._VIEW[2]+G._VIEW[4]/2

	-- for _,star in pairs(G.stars) do
	for _,star in pairs(g2.search("planet -clip")) do
		local x = star.position_x
		local y = star.position_y
		if x > G._VIEW[1] and x < (G._VIEW[1]+G._VIEW[3]) and
			y > G._VIEW[2] and y < (G._VIEW[2]+G._VIEW[4]) then
				local dx = x-cx
				local dy = y-cy
				local dd = math.sqrt(dx*dx+dy*dy)
				local a = math.sqrt(math.max(0,255-dd*3)/255)*255
				local zx = dx/6
				if a > 0 then
					_map_add_flare(star,a,zx,10,star.planet_r*5 + -dd/7 + math.sin(G.T * 3) * 1 ,zx/40 + G.T/20)
				end
		end
	end
end


function map_data_decode(data)
	local cols = {}
	local res = {}
	-- print('data:'..data)
	local n = 1
	for line in string.gmatch(data.."`","([^`]*)`") do
		-- print('line:'..line)
		local e = {}
		local k = 1
		for v in string.gmatch(line..",","([^,]*),") do
			if n == 1 then
				cols[k] = v
			else
				e[cols[k] or "?"] = v
			end
			k = k + 1
		end
		if n > 1 then
			res[#res+1] = e
		end
		n = n + 1
	end
	-- print(json.encode(res))
	return res
end


function map_data_init(data)
	-- print (#data)
	local data = json.decode(data)

	-- GAME.map = GAME.map or {}
	GAME.map = {}
	g2.game_reset()
	local G = GAME.map

	G.clans_id = data.clans_id

	G._stars = map_data_decode(data.stars)
	G._wars = map_data_decode(data.wars)
	G.WARS = {}
	for _,e in pairs(G._wars) do G.WARS[e.stars_id] = e end
	G._users = map_data_decode(data.users)
	G._clans = map_data_decode(data.clans)

	G.CLANS = {}
	for _,e in pairs(G._clans) do G.CLANS[e.id] = e end

	G.T = 0.0
	G.SIZE = 1920
	G.NEBULA = G.NEBULA or nil
	G.NEBS = G.NEBS or {}
	G.SINFO = G.SINFO or {} -- item.n -> stardata
	G.MINFO = {}
	for _,e in pairs(G._stars) do G.MINFO[e.id] = e end -- star.id -> stardata
	G.SMAP = {} -- star.id -> item

	G.FOCUS = nil
	G.ZSIZE = G.SIZE * 1.125
	G.VIEW = {-G.ZSIZE/2,-G.ZSIZE/2,G.ZSIZE,G.ZSIZE}
	G._VIEW = {-G.ZSIZE/2,-G.ZSIZE/2,G.ZSIZE,G.ZSIZE}


	G.stars = G.stars or {}
	G.lines = G.lines or {}
	G.lused = {}
	G.consts = G.consts or {}

	G.MOVED = false
	G.DX = 0
	G.DY = 0
	G.MX = 0
	G.MY = 0
	G.MA = 0
	G._MX = 0
	G._MY = 0
	G._MA = 0
	G.ZSCALE = 0.65
	G._ZSCALE = 0.65
	G.ZSTAR = 1.0
	G._ZSTAR = 1.0
	G.ZSTAR_MIN = 0.25

	G.INFO = G.INFO or {}


	G.OX = -9999; G.OY = -9999
	G.VIEW_A = 0
	G._VIEW_A = 0
	G.CALPHA = 0
	G._CALPHA = 0
	G.FLARE = G.FLARE or {}

	G.speed = 50
end
function _map_color_fade(c,f)
    local r = math.floor(bit32.rshift(bit32.band(c,0xff0000),16) * f)
    local g = math.floor(bit32.rshift(bit32.band(c,0x00ff00),8) * f)
    local b = math.floor(bit32.rshift(bit32.band(c,0x0000ff),0) * f)
    return bit32.lshift(r,16) + bit32.lshift(g,8) + bit32.lshift(b,0)
end

function map_module_init()

	local G = GAME.map
	local plist = G._stars

	g2.game_reset()
	math.randomseed(23099)

	g2.view_set(-G.ZSIZE/2,-G.ZSIZE/2,G.ZSIZE,G.ZSIZE)
	g2.state = 'scene'
	g2.bkgr_src = 'background05' -- 'black'
	g2.bkgr_stars = 3
	g2.bkgr_zoom = 1.0


	local USERS = {}

	local nebs = 0

	local grid = {}
	local space = 75
	for _,planet in pairs(plist) do
		local v = math.ceil((planet.y / space) + 0.5) * 256 + math.ceil((planet.x / space) + 0.5)
		grid[v] = (grid[v] or 0) + 1
	end



	-- for _,planet in pairs(plist) do
	-- 	local x = planet.x-- * SIZE / psize
	-- 	local y= planet.y-- * SIZE /psize
	-- 	local item = g2.new_image('blank',x,y,1,1)

	-- 	-- nebs

	-- end









	local total = 0
	for _,planet in pairs(plist) do
		local x = planet.x-- * SIZE / psize
		local y= planet.y-- * SIZE /psize
		-- local z = 2 * math.sqrt(planet.value / 500)
		local z = planet.size / 2

		local user = USERS[planet.color]
		if not user then
			local c = tonumber(planet.color,16) or 0xffffff
			local team = g2.new_team("team",c)
			user = g2.new_user("star",c,team)

			local js = { hidden=true }
			js.aura = "map-aura-sun"
			user.planet_style = json.encode(js)
			USERS[planet.color] = user
		end


		local item = g2.new_planet(user,x,y,0,0)
		item.planet_color = user.planet_color
		item.label_text = planet.name -- planet.id 
		item.has_xflag = true
		item.planet_r = z
		item.ships_production = z
		item._position_x = x
		item._position_y = y
		item.has_button = true
		item.button_name = item.n
		item.render_zindex = -1


		if true then --  math.random(1,odds) == 1 then
			local v = math.ceil((planet.y / space) + 0.5) * 256 + math.ceil((planet.x / space) + 0.5)
			local nearby = grid[v] or 1
			local dd = math.sqrt(x*x+y*y)/960.0

			nebs = nebs + 1
			-- local r = math.sqrt(x*x+y*y)
			-- local cz = (math.random(16,72) * 2 / math.sqrt(2)) / math.pow(nearby,1/4)
			-- local img = 'map-nebula1'
			-- if math.random(0,r) < G.SIZE/6 then img = 'map-nebula2' end

			local F = 0.225 
			local GSIZE = F * G.SIZE
			nearby = 1
			local r = math.sqrt(x*x+y*y)
			local cz = F * 3 * (math.random(16,72) * 2 / math.sqrt(2)) / math.pow(nearby,1/4)
			local img = 'map-nebula1'
			if math.random(0,r) < GSIZE/5 then img = 'map-nebula2' end

			local alpha = 0x44 + 0xbb * math.min(1, 4 * r / G.SIZE)

			item.has_image = true
			item.image_src = img
			item.image_w = cz*2
			item.image_h = cz*2
			item.render_color = 0xffffff
			item.image_scale = 1.0

			item.render_blend = 1
			item.render_alpha = alpha
			-- item.render_alpha = (0x50 + 0x70 * math.sin(dd * math.pi * 0.825)) * 0.65
			item.image_cx = cz
			item.image_cy = cz
			item.image_a = _map_randomf(0,math.pi*2)
			item._position_x = x
			item._position_y = y
			item.has_xflag = true

		end



		local star = item
		G.stars[#G.stars+1] = star
		G.SINFO[item.n] = planet
		G.SMAP[planet.id] = item


		total = total + 1
	end
	-- print(total)


	local total = 0
	for _,a in pairs(plist) do
		local routes = a.routes
		if routes ~= '' then
			local delim = ';' ; if routes:find(':') then delim = ':' end
			routes = _map_str_split(routes,delim)
			for _,v in pairs(routes) do
				local c = 0x333333 -- 0x222222
				local pre = v:sub(1,1)
				if pre == '+' then c = 0xffffff; v = v:sub(2) end
				if pre == '-' then c = tonumber(a.color,16); v = v:sub(2) end
				local b = G.MINFO[v]
                local o = g2.new_line(c, a.x,a.y,b.x,b.y)
                o._position_x = o.position_x
                o._position_y = o.position_y
                o._draw_x2 = o.draw_x2
                o._draw_y2 = o.draw_y2
                o.image_src = 'map-line'
                o.render_blend = 1
                o.has_xflag = true
                o.render_zindex = -1
                total = total + 1
			end
		end
	end
	-- print(total)


	local total = 0
	for _,a in pairs(plist) do
		local regions = a.regions
		if regions ~= '' then
			regions = _map_str_split(regions,';')
			for _,v in pairs(regions) do
				local pre = v:sub(1,1)
				if pre == '+' or pre == '-' then
					local color = 0xffffff
					if pre == '-' then color = tonumber(a.color,16) end
					color = _map_color_fade(color,1/3)
					local pts = _map_str_split(v:sub(2),':')
					local b = G.MINFO[pts[1]]
					local c = G.MINFO[pts[2]]

	                local o = g2.new_triangle(color, a.x,a.y,b.x,b.y,c.x,c.y)
	                o._position_x = o.position_x
	                o._position_y = o.position_y
	                o._draw_x2 = o.draw_x2
	                o._draw_y2 = o.draw_y2
	                o._draw_x3 = o.draw_x3
	                o._draw_y3 = o.draw_y3
	                o.has_xflag = true
	                total = total + 1
	        	end
			end
		end
	end
	-- print(total)	

	math.randomseed(os.time())


	_map_set_default_view()
	G._VIEW = _map_shallowcopy(G.VIEW)
	local Z = 3
	G._VIEW = {G._VIEW[1]*Z,G._VIEW[2]*Z,G._VIEW[3]*Z,G._VIEW[4]*Z}

	G.circles = {}
	G.markers = {}


	G.neutrals = {}
	for n=1,25 do
		local player = {x = math.random(-500,500),y = math.random(-500,500), target=G.stars[math.random(1,#G.stars)]}

		local zz = 20

		player.item = g2.new_image("ship",player.x,player.y,zz,zz)
		player.item.render_color = 0x888888
		player.item.has_xflag = true
		player.item.image_cx = zz/2
		player.item.image_cy = zz/2
		player.item._position_x = player.x
		player.item._position_y = player.y
		player.item.render_blend = 1
		player.bot = true

		G.neutrals[#G.neutrals+1] = player
	end

	G.ships = {}
	for _,e in pairs(G._users) do
		local star = G.MINFO[e.stars_id] or {x=0,y=0}

		local zz = 35
		if e.id == g2.uid then zz = 45 end

		local a = math.random(0,360)*math.pi / 180
		local ax = zz * math.cos(a)
		local ay = zz * math.sin(a)		

		local player = {clans_id = e.clans_id, x = tonumber(star.x) + ax,y=tonumber(star.y)+ay,target=G.SMAP[e.stars_id]}

		player.item = g2.new_image(e.image or 'ship',player.x,player.y,zz,zz)
		player.item.render_color = tonumber(e.color or 'ffffff',16)
		player.item.has_xflag = true
		player.item.image_cx = zz/2
		player.item.image_cy = zz/2
		player.item._position_x = player.x
		player.item._position_y = player.y
		player.item.render_blend = 1
		player.active = false

		player.item.has_user = true
		player.item.label_text = e.name


		if e.id == g2.uid then 
			player.marker = _map_new_marker(player.x,player.y,75)
			player.active = true
			G.player = player
			G.markers[#G.markers+1] = player.marker

			-- if player.target == nil then
			-- 	g2.net_send("","map:goto",G._stars[math.random(1,#G._stars)].id)
			-- end
		end

		G.ships[#G.ships+1] = player
	end

	-- if mknumber(G.clans_id) > 0 then
	-- 	local used = {}
	-- 	for _,e in pairs(G.WARS) do

	-- 		if e.defender_id == G.clans_id then
	-- 			_map_add_marker(e.stars_id,0x5555ff)
	-- 			used[e.stars_id] = true
	-- 		end
	-- 		if e.attacker_id == G.clans_id then
	-- 			_map_add_marker(e.stars_id,0xff5555)
	-- 			used[e.stars_id] = true
	-- 		end
	-- 	end
	-- 	for _,e in pairs(G.MINFO) do
	-- 		if used[e.id] == nil and e.clans_id == G.clans_id then
	-- 			_map_add_marker(e.id,0xffffff)
	-- 			used[e.id] = true
	-- 		end
	-- 	end
	-- end

	if mknumber(G.clans_id) > 0 then
		for _,planet in pairs(plist) do
			local c = tonumber(planet.marker or '',16)
			if c then _map_add_marker(planet.id,c) end
		end
	end


	map_module_loop(0)

end

function _map_add_marker(starid,color)
	local G = GAME.map
	local item = G.SMAP[starid]
	local marker = _map_new_circle(item.position_x,item.position_y,25)
	marker.render_color = color
	G.circles[#G.circles+1] = marker	
end

function _map_new_circle(x,y,zz)
	-- local o = g2.new_circle(0xffffff,x,y,zz)
	local o = g2.new_image("map-circle",x,y,zz*2,zz*2)
	o.image_cx = zz
	o.image_cy = zz
	o.has_xflag = true
	o._position_x = x
	o._position_y = y
	return o
end

function _map_new_marker(x,y,zz)
	local marker = g2.new_image("map-marker",x,y,zz,zz)
	marker.has_xflag = true
	marker.image_cx = zz/2
	marker.image_cy = zz+5
	marker._position_x = x
	marker._position_y = y
	return marker
end

function _map_str_split(value,delim)
    local r = {}
    for token in value:gmatch("[^"..delim.."]+") do
        r[#r+1] = token
    end
    return r
end

function _map_focus_star(val,force)
	local G = GAME.map
	if tonumber(val) == nil then return end

	-- fix view/etc
	if force then
		G.FOCUS = true
		G.VIEW_A = G._VIEW_A
		G._ZSCALE = 1.0
		G.ZSCALE = G._ZSCALE		
		map_module_loop(0)
	end

	-- focus on the star.
	G.FOCUS = tonumber(val)
	local z = 24
	local pad = 3
	local item = g2.item(G.FOCUS)
	local ix = item.position_x
	local iy = item.position_y
	local xz = z -- (z*2) * (ix + ZSIZE/2) / ZSIZE
	local yz = z -- (z*2) * (iy + ZSIZE/2) / ZSIZE
	G.VIEW = {ix - xz - pad, iy - yz-pad, z *2+pad*2, z*2+pad*2 }
	g2.net_send('','map:view',G.SINFO[G.FOCUS].id)
	_map_cleanup()
end

function map_module_event(e)
	local G = GAME.map

	-- handle basic events to over-ride the mod_client event handling
    if e.type == 'pause' then
        g2.state = 'dialog'
        return true
    end

    if e.type == 'quit' then
    	g2.net_send('','map:leave','')
        g2.quit = false
        return true
    end

    if e.type == 'back' then
        g2.state = 'scene'
        return true
    end

    if e.type == "onclick" and e.value == "resume" then
        g2.state = 'scene'
        return true
    end


    -- handle map specific events

	if e.type == 'onclick' and e.value == 'map:resume' then
		g2.state = 'scene'
		return true
	end

	if e.type == 'onclick' and e.value == 'map:leave' then
        g2.net_send('','map:leave','')
        return true
	end

	if e.type == 'net:map:cleanup' then -- return player to client module
        g2.state = GAME.state
        g2.status = ''
        g2.html = ''
        g2.game_reset()
        GAME.module = GAME.modules.client
        return true
    end


	if e.type == 'net:map:buttons' then
		local n = tonumber(G.FOCUS)
		if n ~= nil then
			_map_cleanup()
			_map_show_info2(G.FOCUS,json.decode(e.value))	
		end
		return true
	end

	if e.type == 'net:map:goto' then
		G.player.target = G.SMAP[e.value]
		G.player.flying = true
		_map_zoom_middle({x=G.player.target.position_x,y=G.player.target.position_y})
		return true
	end

	if e.type == 'net:map:focus' then
		local item = G.SMAP[e.value]
		if item.n then
			_map_focus_star(item.n,true)
		end
		return true
	end

	-- handle the map navigation events

	if e.type == 'ui:down' then
		G.MX = 0
		G.MY = 0
		G.MA = 0
	end
	if e.type == 'ui:motion' and e.b ~= 0 then
		local rf = 1.0
 		if math.max(-G.ZSIZE/2,math.min(G.ZSIZE/2-G.VIEW[3],G.VIEW[1])) ~= G.VIEW[1] or math.max(-G.ZSIZE/2,math.min(G.ZSIZE/2-G.VIEW[4],G.VIEW[2])) ~= G.VIEW[2] then rf = 0.5 end

		G.DX = G.DX + e.dx * rf
		G.DY = G.DY + e.dy * rf
		local dd = math.sqrt(G.DX*G.DX+G.DY*G.DY) * G.ZSIZE / G.VIEW[3]

 		if G.FOCUS == nil then
 			if G.MOVED == true or dd > 50 then
 				G.MOVED = true
				G.DX = 0
				G.DY = 0
				G.MA = 0
				G._MX = 0
				G._MY = 0
 				local aa = math.atan2(e.y,e.x)
 				local bb = math.atan2((e.y-e.dy),(e.x-e.dx))
 				local zz = math.pi/2
 				if aa < -zz and bb > zz then aa = aa + math.pi * 2 end
 				if aa > zz and bb < -zz then bb = bb + math.pi * 2 end
 				G._MA = aa - bb
				G.VIEW_A = G.VIEW_A + aa - bb
			end
 			return
 		end

		if G.MOVED == true or dd > 50 then
			g2.status = ''
			G.MOVED = true
			G._VIEW[1] = G._VIEW[1] - e.dx
			G._VIEW[2] = G._VIEW[2] - e.dy
			G.VIEW[1] = G.VIEW[1] - e.dx
			G.VIEW[2] = G.VIEW[2] - e.dy
			G._MX = e.dx
			G._MY = e.dy
			G._MA = 0
			G.DX = 0
			G.DY = 0
			G.MA = 0
		end
	end

	if e.type == 'ui:up' and G.MOVED == false then
		if e.value:find("/") ~= nil then
			-- handle map button actions
			g2.play_sound('sfx-click')
			local parts = _map_str_split(e.value,'/')
			local action = parts[1]
			local item = g2.item(parts[2])
			
			-- if action == 'map:goto' then
			-- 	G.player.target = item
			-- 	_map_zoom_middle(e)
			-- end
			g2.net_send('',action,parts[2])
			return
		end

		if e.value ~= nil and e.value ~= '' then
			local maybe_n = tonumber(e.value)
			local item = g2.item(maybe_n)
			local dx = item.position_x - e.x
			local dy = item.position_y - e.y
			local dd = math.sqrt(dx*dx+dy*dy)
			if dd > (item.planet_r + 10) then
				e.value = ''
			end
		end


		if G.FOCUS ~= nil and G.FOCUS == e.value then
			-- pass
		elseif G.FOCUS ~= nil and e.value ~= '' then
			g2.status = ''
			_map_focus_star(e.value)
		elseif G.FOCUS ~= true then
			g2.status = ''
			_map_zoom_middle(e)
		else
			g2.status = ''
			G.FOCUS = nil
			_map_set_default_view()
			_map_cleanup()		
		end
	end

	if e.type == 'ui:up' and G.MOVED == true then
		G.MOVED = false
		G.MX = G._MX
		G.MY = G._MY
		G.MA = G._MA
	end

end

function _map_zoom_middle(e)
	local G = GAME.map
	G.FOCUS = true
	local z = 64
	local pad = 8
	local xz = (z*2) * (e.x + G.ZSIZE/2) / G.ZSIZE
	local yz = (z*2) * (e.y + G.ZSIZE/2) / G.ZSIZE
	G.VIEW = {e.x - xz - pad, e.y / G.ZSCALE - yz-pad, z *2+pad*2, z*2+pad*2 }
	_map_cleanup()	
	G.OX = -9999; G.OY = -9999
end

function _map_item_fly(t,item,target,angle,dist)
	if not target then return end

	local dist = dist / 2

	local G = GAME.map
	local dx = target._position_x - item._position_x
	local dy = target._position_y - item._position_y
	local dd = math.sqrt(dx*dx+dy*dy)
	local ret = true

	if dd > dist then
		dx = dx / dd ; dy = dy / dd
		item._position_x = item._position_x + dx * G.speed * t
		item._position_y = item._position_y + dy * G.speed * t
		ret = false
	end

	if angle then
		local dx = target.position_x - item.position_x
		local dy = target.position_y - item.position_y
		item.image_a = math.atan2(dy,dx) + math.pi/2
	end

	return ret
end

function map_player_update(t)
	local G = GAME.map
	for _,player in pairs(G.ships) do
		-- local player = G.player
		if player.marker then 
			_map_item_fly(t,player.marker,player.target,false,player.item.image_w)
		end
		if _map_item_fly(t,player.item,player.target,true,player.item.image_w) then
		end
	end

	local player = G.player
	if player == nil then return end
	local target = player.target
	if target == nil then return end
	local item = player.item
	if item == nil then return end

	local dx = target._position_x - item._position_x
	local dy = target._position_y - item._position_y
	local dd = math.sqrt(dx*dx+dy*dy)
	local tt = (dd / G.speed)+0.5
	local tm = math.floor(tt)
	if player.flying then
		if tm < 1 then
			g2.status = '' -- ''..target.label_text
			player.flying = false
		else
			g2.status = ''..target.label_text..',  ETA: '..string.format('%d:%02d',math.floor(tm/60),tm%60)
		end
	end
end

function map_neutrals_update(t)
	local G = GAME.map
	for _,player in pairs(G.neutrals) do
		if player.marker then 
			_map_item_fly(t,player.marker,player.target,false,player.item.image_w)
		end
		if _map_item_fly(t,player.item,player.target,true,player.item.image_w) then
			player.target = G.stars[math.random(1,#G.stars)]
		end
	end
end

function map_module_loop(t)
	local G = GAME.map
	G.T = G.T + t

	map_neutrals_update(t)
	map_player_update(t)

    local j = 5
    local k = 1

	G._VIEW[1] = G._VIEW[1] - G.MX
	G._VIEW[2] = G._VIEW[2] - G.MY
	G.VIEW[1] = G.VIEW[1] - G.MX
	G.VIEW[2] = G.VIEW[2] - G.MY

    G._VIEW[1] = (G._VIEW[1] * j + G.VIEW[1] * k) / (j+k)
    G._VIEW[2] = (G._VIEW[2] * j + G.VIEW[2] * k) / (j+k)
    G._VIEW[3] = (G._VIEW[3] * j + G.VIEW[3] * k) / (j+k)
    G._VIEW[4] = (G._VIEW[4] * j + G.VIEW[4] * k) / (j+k)

    if math.abs(G._VIEW[3] - G.VIEW[3]) < 1.0 and math.abs(G._VIEW[4] - G.VIEW[4]) < 1.0 and math.abs(G.OX-G._VIEW[1]) > 1.0 and math.abs(G.OY-G._VIEW[2]) > 1.0 then
    	-- if FOCUS == true then
    	-- 	show_labels()
    	-- end
	    G.OX = G._VIEW[1]
    	G.OY = G._VIEW[2]
    end

	if G.FOCUS == true then
		_map_show_labels()
	end


    g2.view_set(G._VIEW[1],G._VIEW[2],G._VIEW[3],G._VIEW[4])
    g2.clip_set(G._VIEW[1]-G._VIEW[3]/2,G._VIEW[2]-G._VIEW[4]/2,G._VIEW[3]+G._VIEW[3],G._VIEW[4]+G._VIEW[4])
	g2.bkgr_zoom = 1.125 + (((G.ZSIZE / G._VIEW[3]) - 1.0) / 8.0)
	local zmax = (g2.bkgr_zoom - 1.0) * 1.0
	g2.bkgr_dx = zmax * (-(G._VIEW[1] + G._VIEW[3]/2) / G.ZSIZE) 
	g2.bkgr_dy = zmax * (-(G._VIEW[2] + G._VIEW[4]/2) / G.ZSIZE)

	-- NEBULA.position_x = -ZSIZE/3 * (-(_VIEW[1] + _VIEW[3]/2) / ZSIZE) 
	-- NEBULA.position_y = -ZSIZE/3 * (-(_VIEW[2] + _VIEW[4]/2) / ZSIZE) 
    local f = 0.95
    G.MX = G.MX * f
    G.MY = G.MY * f

 	-- also rubber band from edges.
 	if not G.MOVED then
 		G.VIEW[1] = math.max(-G.ZSIZE/2,math.min(G.ZSIZE/2-G.VIEW[3],G.VIEW[1]))
 		G.VIEW[2] = math.max(-G.ZSIZE/2,math.min(G.ZSIZE/2-G.VIEW[4],G.VIEW[2]))
 	end


	-- if FOCUS ~= nil then
	-- 	local x = VIEW[1]+VIEW[3]/2
	-- 	local y = VIEW[2]+VIEW[4]/2
	-- 	local xx = x * math.cos(at) - y * math.sin(at)
	-- 	local yy = x * math.sin(at) + y * math.cos(at)	
	-- 	VIEW[1] = xx - VIEW[3]/2
	-- 	VIEW[2] = yy - VIEW[4]/2
	-- end	



	local changes = false

	if G.FOCUS == nil then
	 	local at = -t * 0.025

	 	G.VIEW_A = G.VIEW_A + G.MA
	 	G._VIEW_A = G._VIEW_A + G.MA
	 	G.MA = G.MA * 0.95

	 	G.VIEW_A = G.VIEW_A + at
	    G._VIEW_A  = (G._VIEW_A  * j + G.VIEW_A  * k) / (j+k)
	    changes = true

	    G.ZSCALE = 0.65
	    G.ZSTAR = 1.0
	    G.CALPHA = 0
	else
		G.VIEW_A = G._VIEW_A
		G.MA = 0
		G.ZSCALE = 1.0
		G.ZSTAR = G.ZSTAR_MIN
		G.CALPHA = 0xaa
		if G.FOCUS ~= true then G.CALPHA = 0 end
	end



 	local aa = G._VIEW_A
    G._ZSCALE = (G._ZSCALE * j + G.ZSCALE * k) / (j+k)
	local zscale = G._ZSCALE

	-- aa = 0 ; zscale = 1.0 -- LINEGEN


    G._CALPHA = (G._CALPHA * j + G.CALPHA * k) / (j+k)
    local calpha = G._CALPHA

    G._ZSTAR = (G._ZSTAR * j + G.ZSTAR * k) / (j+k)
    local zstar = G._ZSTAR


    g2_ext_call("galcon2:map_rotate",json.encode({t=t,aa=aa,zscale=zscale,zstar=zstar}))


	if G.FOCUS ~= nil and G.FOCUS ~= true then
		for _,item in pairs(G.INFO) do
		    item.render_alpha = (item.render_alpha * j + 255 * k) / (j+k)
		end
	end


	for _,item in pairs(G.circles) do
		local zz = 25 * zstar
		item.image_w = zz*2
		item.image_h = zz*2
		item.image_cx = zz
		item.image_cy = zz
	end

	for _,item in pairs(G.markers) do
		local zz = 75 * zstar
		item.image_w = zz
		item.image_h = zz
		item.image_cx = zz/2
		item.image_cy = zz + 5
	end

 	_map_lens_flare()

 	-- add a random explosion once a second ... eventually
 	if math.random(0,30) == 0 and #G._wars > 0 then
 		-- local star = G.stars[math.random(1,#G.stars)]
 		local war = G._wars[math.random(1,#G._wars)]
 		local star = G.SMAP[war.stars_id]
 		for i=1,10 do
            local xx = star.position_x;
            local yy = star.position_y;
            local rr = star.planet_r
            local aa = i * 37
            g2.new_part("spark",1.0,
                    xx+rr*math.cos(aa),yy+rr*math.sin(aa),math.random(10,15),math.random(0,360),1.0,
                    15*math.random(-100,100)/100.0,
                    15*math.random(-100,100)/100.0,
                    math.random(100,200)/100.0,
                    math.random(-100,100)/100.0,
                    -1.0/1.0)
		end
	end




end


function map_init()
    GAME.modules.map = GAME.modules.map or {}
    local obj = GAME.modules.map

    function obj:init()
    	map_module_init()
    end
    
    function obj:loop(t) 
    	map_module_loop(t) 
    	GAME.modules.client:loop(t)
    end
    
    function obj:event(e)
    	if not map_module_event(e) then
    		GAME.modules.client:event(e)
    	end
    end 

end
