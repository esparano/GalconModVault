local seed				= os.time()
local neutrals, homes	= 24,	1
local homeprod, ships	= 100,	100
local prodmin, prodmax	= 15,	100
local costmin, costmax	= 0,	50
local botrate, speed 	= .25,	1
local crash, solid 		= false, true
local botvsbot, show 	= false, false
local spawnside = "random"
local freezeplay = false

local running = false
local bot1time, bot2time = 0, 0
local botmemory, bot2memory = {}, {}
local neutral, player, enemy;
local freezetime, fleetrecord = 0, {}
function init_game()
	g2.game_reset()
	bot1time, bot2time = 0, 0
	botmemory, bot2memory = {}, {}
	freezetime, fleetrecord = 0, {}
	math.randomseed(seed)
	g2.ticks = speed
	running = true
	
	neutral	= g2.new_user("neutral",0x555555)
	player	= g2.new_user("player",	0x0000ff)
	enemy	= g2.new_user("enemy",	0xff0000)
	if crash then
		player.fleet_crash	= 100
		enemy.fleet_crash	= 100
	end
	
	neutral.user_neutral = 1
	neutral.ships_production_enabled = 0
	if show then player.ui_ships_show_mask = 0xf end
	g2.player = player

	local planets = neutrals+homes*2
	local w = math.sqrt(planets)*480/4
	local h = math.sqrt(planets)*230/4

	
	for i = 1, (neutrals+neutrals%2)/2 do
		local prod, ships = math.random(prodmin, prodmax), math.random(costmin, costmax)
		local x, y = math.random()*w, math.random()*h
		g2.new_planet(neutral,   x,   y, prod, ships)
		g2.new_planet(neutral, w-x, h-y, prod, ships)
	end
	
	local a = math.random()
	for i = 1, homes do
		local x = w*(1+math.cos(a*math.pi*2))*.5
		local y = h*(1+math.sin(a*math.pi*2))*.5
		if spawnside == "right" then
			if x*2 < w then x = w-x end
		elseif spawnside == "left" then
			if x*2 > w then x = w-x end
		end
		g2.new_planet(player,  x,   y, homeprod, ships)
		g2.new_planet(enemy, w-x, h-y, homeprod, ships)
		a = a + .5/homes
	end
	
	g2.planets_settle()
	
	for _, p in pairs(g2.search("planet")) do
		p.has_collide = solid
	end
end

function _bots_data()
	local r = g2.search("user OR planet OR fleet")
	local res = {}
	for _,o in ipairs(r) do
		local _type = nil
		if o.has_user then res[o.n] = {
			n = o.n, is_user = true,
			team = o.user_team_n,
			neutral = o.user_neutral,
			}
		elseif o.has_planet then local u = o:owner() ; res[o.n] = {
			n = o.n, is_planet = true,
			x = o.position_x, y = o.position_y, r = o.planet_r, 
			ships = o.ships_value, production = o.ships_production,
			owner = o.owner_n, team = u.user_team_n, neutral = u.user_neutral,
			}
		elseif o.has_fleet then local u = o:owner() ;
			local sync_id = tostring(o.sync_id) ; res[sync_id] = {
			_n = o.n, n = sync_id, is_fleet = true,
			x = o.position_x, y = o.position_y, r = o.fleet_r, 
			ships = o.fleet_ships,
			owner = o.owner_n, team = u.user_team_n,
			target = o.fleet_target,
			}
		end
	end
	return res
end

local behavior1 = { -- enemy bot behavior
	speed = 0.25; -- moves per second
	tunnels = "on"; -- "on", "off", "only"
	percent = false; -- force a certain percent
	redirects = true; -- bot is allowed to redirect
	multiselect = true; -- bot is allowed to select multiple things each move
	unlimited = false; -- bot is not limited to human controls
}
local behavior2 = { -- auto bot behavior
	speed = 0.25;
	tunnels = "on";
	percent = false;
	redirects = true;
	multiselect = true;
	unlimited = false;
}

function bot(params, behavior)
	local abs, floor, ceil, max, min, HUGE, random, PI, sqrt, sort = math.abs, math.floor, math.ceil, math.max, math.min, math.huge, math.random, math.pi, math.sqrt, table.sort
	local function send(p,f,t)return{percent=p,from=f.ships and{f.n}or f,to=t.n}end
	local function redirect(f,t)return{from=f.ships and{f.n}or f,to=t.n}end
	local function distance(a,b)local dx,dy=b.x-a.x,b.y-a.y return sqrt(dx*dx+dy*dy)end
	local G,USER,memory=params.items,params.user,params.memory
	local FIRST=not memory.init
	if FIRST then memory.init=true end
	local uteam=G[USER].team
	local homes,eteam=memory.homes,memory.eteam
	if not homes then
		homes={}
		for _,v in pairs(G)do
			if v.is_planet and not v.neutral then
				local o=v.team
				local h=homes[o]
				if not h or h.production<v.production then
					homes[o]=v
				end
			end
		end
		for k,v in pairs(homes)do if k~=uteam then memory.eteam,eteam=k,k end end
		memory.homes=homes
	end
	local home,ehome=homes[uteam],homes[eteam]
	local ships,total,tprod,myprod=0,0,0,0
	local data={planets={},neutral={},myplanets={},myteam={},eplanets={},others={},fleets={},myfleets={},efleets={},mystuff={}}
	for _,p in pairs(G)do
		local o,s=p.team,p.ships
		if not p.is_user and not p.neutral then
			if o==uteam then
				ships=ships+s
			end
			total=total+s
		end
		if p.is_planet then
			data.planets[#data.planets+1]=p
			if p.neutral then
				data.neutral[#data.neutral+1]=p
				data.others[#data.others+1]=p
			else
				tprod=tprod+p.production
				if o==uteam then
					data.myteam[#data.myteam+1]=p
					if p.owner==USER then
						myprod=myprod+p.production
						data.myplanets[#data.myplanets+1]=p
						data.mystuff[#data.mystuff+1]=p
					end
				else
					data.others[#data.others+1]=p
					data.eplanets[#data.eplanets+1]=p
				end
			end
		elseif p.is_fleet then
			data.fleets[#data.fleets+1]=p
			if p.team==uteam then
				data.myfleets[#data.myfleets+1]=p
				data.mystuff[#data.mystuff+1]=p
			else
				data.efleets[#data.efleets+1]=p
			end
		end
	end
	local planets,control=data.myplanets,ships/total
	if FIRST and home and #data.neutral~=0 then
		local function path(f,t,set)
			local ft=distance(f,t)
			for i=1,#set do local p=set[i]
				if p~=f and p~=t then
					local pt=distance(p,t)
					if pt<ft then
						local fp=distance(f,p)
						if fp<ft and(pt+fp-p.r*2)<ft then
							t,ft=p,fp
						end
					end
				end
			end
			return t
		end
		local function recovertime(a,b)
			local r=b.ships-a.ships
			if r<0 then
				return distance(a,b)/20+b.ships*50/b.production
			elseif a.is_planet then
				return distance(a,b)/20+b.ships*50/b.production+r*50/a.production
			else
				return HUGE
			end
		end
		local function pathlength(f,t,set)
			local d=0
			for i=1,20 do
				if f==t then break end
				local F=path(f,t,set)
				d=d+distance(f,F)
				f=F
			end
			return d
		end
		local eeval,enemy=HUGE
		for _,v in pairs(data.eplanets)do
			local n=distance(v,home)
			if eeval>n then eeval,enemy=n,v end
		end
		if not enemy then
			local eeval=-HUGE
			for _,v in pairs(data.others)do
				local n=distance(v,home)
				if n>eeval then eeval,enemy=n,v end
			end
		end
		local p,expand=data.neutral,{}
		local rt={}for _,v in pairs(p)do rt[v]=recovertime(home,v)end
		sort(p,function(a,b)return rt[a]<rt[b]end)
		local c=home.ships
		local cinit,ships,n=c,c,0
		local benefit=home.production*distance(enemy,home)/2000
		local prod=home.production
		for i=1,#p do local v=p[i]
			if home and enemy and distance(enemy,v)>distance(home,v)then
				local s=max(1,v.ships+1)
				local ben = (distance(enemy,v)-pathlength(home,v,expand))*v.production/2000-s
				local liability = s-max(c, 0)
				if c < s then
					ben = ben - liability*v.production/prod
				end
				if benefit+ben+c>cinit then
					benefit=benefit+ben
					c=c-s
					if c>0 then prod=prod+v.production end
					expand[#expand+1]=v
				end
			end
		end
		memory.expand=expand
		return
	end
	local stuff=data.mystuff
	sort(stuff,function(a,b)return a.ships>b.ships end)
	local targets=data.eplanets
	local defend=myprod/tprod>.5 and control<.8
	if memory.expand then
		for _,v in pairs(memory.expand)do
			local v=G[v.n]
			if v and v.neutral then
				targets[#targets+1]=v
			end
		end
	end
	if control > .5 then
		local excess = total*(control-.5)
		for _, v in pairs(data.neutral) do
			if v.ships < excess then
				targets[#targets+1] = v
			end
		end
	end
	local function tunnel(f,t)
		if not t then return end
		if behavior.tunnels == "off" then return t end
		local planets = behavior.tunnels == "on" and data.myteam or data.planets
		local ft=distance(f,t)
		for _,p in pairs(planets)do
			local fp=distance(f,p)
			if fp<ft then
				local pt=distance(p,t)
				if p~=f and pt<ft and(pt+fp-p.r*2)<ft then
					t,ft=p,fp
				end
			end
		end
		return t
	end
	local finish=control>.7
	local GetTarget=function(f)
		local teval,t=HUGE
		for _,v in pairs(targets)do
			local s=v.ships
			if v.neutral then
				local dist=distance(f,v)
				for _,x in pairs(data.myfleets)do if x~=f and x.target==v.n then s=s-floor(x.ships)end end
			else
				local close=distance(f,v)
				s=s+ceil(v.production*close/2000)
			end
			if floor(s)>=0 then
				local n=distance(f,v)/10+s-v.production/4
				if v.neutral then n=distance(f,v)/10 end
				if teval>n then teval,t=n,v end
			end
		end
		return t
	end
	if finish then
		GetTarget=function(f)
			local teval,t=HUGE
			for _,v in pairs(targets)do
				local d=distance(f,v)
				if teval>d then teval,t=d,v end
			end
			return t
		end
	end
	local selected,maintarget,percent={}
	if behavior.percent then
		percent = behavior.percent
	end
	local danger,help={},{}
	for ind,f in pairs(data.myplanets)do
		local available,dist=floor(f.ships),HUGE
		for _,v in pairs(data.efleets)do
			local targ=G[v.target]
			if targ.neutral then
				if distance(targ,f)<100 then
					targ=f
				end
			end
			if targ==f then
				available=available-ceil(v.ships)
				dist=min(dist,distance(v,f)-f.r)
			end
		end
		local h=0
		for _,v in pairs(data.myfleets)do
			if v.target==f.n then
				h=h+v.ships
			end
		end
		help[f]=h
		danger[f]=floor(available+f.production*dist/2000)
	end
	for ind,f in pairs(stuff)do
		if f.is_planet then
			local available=danger[f]or f.ships
			if available>0 then
				local t0=GetTarget(f)
				local t=tunnel(f,t0)
				local low,t2=0
				for _,v in pairs(data.myplanets)do
					local d=(danger[v]or v.ships)+(help[v]or 0)
					if d<low then low,t2=d,v end
				end
				if t2 and defend and t2 ~= f then
					if not t or (not t.neutral and distance(t,f) > distance(t2,f)) then
						t = t2
						percent = percent or 15
					end
				end
				if t then
					if behavior.unlimited then
						local a = 100*available/f.ships
						if t.neutral and not behavior.percent then a = min(a, 200*(t.ships+1)/f.ships) end
						g2_fleet_send(math.min(100, percent or a), f.n, t.n)
						if not behavior.multiselect then break end
					else
						if not maintarget then maintarget=t end
						if maintarget~=t and t0 and behavior.tunnels ~= "only" then
							if distance(f,t0)+10>distance(f,maintarget)+distance(maintarget,t0)-maintarget.r*2 then
								t=maintarget
							end
						end
						if maintarget==t then
							local a=floor(available*20/f.ships)*5
							if t.neutral and not behavior.percent then a=min(a,ceil((t.ships+1)*20/f.ships)*10)end
							if not percent then percent=a end
							if percent<=a then
								t.ships=t.ships-floor(ceil(percent*20/f.ships)*f.ships/20+.5) 
								selected[#selected+1]=f.n
							end
						end
					end
				end
			end
		elseif behavior.redirects then
			local t=tunnel(f,GetTarget(f))
			local low,t2=0
			local targ=G[f.target]
			for _,v in pairs(data.myplanets)do
				local d=(danger[v]or v.ships)+(help[v]or 0)
				if v==targ then d=d-f.ships end
				if d<low then low,t2=d,v end
			end
			if t then
				if t2 and defend and not t.neutral and distance(t,f)>distance(t2,f) then t=t2 end
			elseif t2 and defend then
				t=t2
			end
			if t then
				if f.target~=t.n then
					if behavior.unlimited then
						g2_fleet_redirect(G[f.n]._n, t.n)
						if not behavior.multiselect then break end
					else
						if not maintarget then maintarget=t end
						if maintarget==t then
							f.target=t.n
							selected[#selected+1]=f.n
						end
					end
				end
			end
		end
		if selected[1] and not behavior.multiselect then
			break
		end
	end
	if maintarget and #selected>0 then
		--[[if finish then
			return send(50,{selected[1],selected[2]},maintarget)
		end]]
		return send(percent,selected,maintarget)
	end
end

function copy(o)
	if type(o) ~= 'table' then return o end
	local r = {}
	for k,v in pairs(o) do r[k] = copy(v) end
	return r
end

function _bots_run(_data, uid, memory, behavior)
	local data = copy(_data)
	local res = bot({items=data, user=uid, memory=memory}, behavior)
	if not res then return end
	local data = _data
	local percent = res.percent or 50
	percent = math.max(5,math.min(100,math.floor(percent/5 + .5) * 5))
	local from = res.from ; if type(from) ~= 'table' then from = {from} end
	local to = res.to
	return {data = data, to = to, from = from, uid = uid, percent = percent}
end

function loop(t)
	if g2.state ~= "play" then return end
	if freezeplay then
		local moved = false
		for _, f in pairs(g2.search("fleet owner:"..g2.player)) do
			local id = f.sync_id
			local r = fleetrecord[id]
			if not r or f.fleet_target ~= r then
				fleetrecord[id] = f.fleet_target
				moved = true
			end
		end
		if moved then
			freezetime = freezetime + .25
			g2.speed = 1
		end
		if freezetime <= 0 then
			g2.speed = 0
			for _, p in pairs(g2.search("planet owner:"..g2.player)) do
				if p.ships_value > 1 then
					return
				end
			end
			g2.speed = 1 -- resume for 1 frame until player has a planet it can send from
		else
			freezetime = freezetime - t
		end
	end
	bot1time = bot1time + t
	bot2time = bot2time + t
	local bot1rate = behavior1.speed
	local bot2rate = behavior2.speed
	local data;
	local moves = {}
	if bot1time >= bot1rate then
		bot1time = bot1time - bot1rate
		data = _bots_data()
		moves[#moves+1] = _bots_run(data, enemy.n, botmemory, behavior1)
	end
	if botvsbot and bot2time >= bot2rate then
		bot2time = bot2time - bot2rate
		data = data or _bots_data()
		moves[#moves+1] = _bots_run(data, player.n, bot2memory, behavior2)
	end
	if #moves == 2 and math.random() > .5 then
		moves[1], moves[2] = moves[2], moves[1]
	end
	for i = 1, #moves do
		local move = moves[i]
		local data, to, from, uid, percent = move.data, move.to, move.from, move.uid, move.percent
		if data[to].is_planet then
			for _, f in pairs(from) do
				if data[f].is_planet and data[f].owner == uid then
					g2_fleet_send(percent, f, to)
				end
				if data[f].is_fleet and data[f].owner == uid and data[f].target ~= to then
					g2_fleet_redirect(data[f]._n, to)
				end
			end
		end
	end
	
	local winner;
	for _, p in pairs(g2.search("planet OR fleet -neutral")) do
		local user = p:owner()
		if not winner then
			winner = user
		elseif winner ~= user then
			return
		end
	end
	
	if winner then
		if winner.has_player then
			init_pause("win")
		else
			init_pause("lose")
		end
	end
end

local menustate = "menu"
function readmenu()
	if g2.state ~= "menu" and menustate == "menu" then return end
	if menustate == "menu" then
		seed	 = tonumber(g2.form.seed	) or 0
		neutrals = tonumber(g2.form.neutrals) or 24
		homes	 = tonumber(g2.form.homes	) or 1
		homeprod = tonumber(g2.form.homeprod) or 100
		ships	 = tonumber(g2.form.ships	) or 100
		prodmin	 = tonumber(g2.form.prodmin	) or 15
		prodmax	 = tonumber(g2.form.prodmax	) or 100
		costmin	 = tonumber(g2.form.costmin	) or 0
		costmax	 = tonumber(g2.form.costmax	) or 50
		speed	 = tonumber(g2.form.speed	) or 1
		if speed < 1 then speed = 1 end
		neutrals = neutrals + neutrals%2
		if prodmin > prodmax then prodmin, prodmax = prodmax, prodmin end
		if costmin > costmax then costmin, costmax = costmax, costmin end
		g2.ticks = speed
	else
		behavior1.speed	 = tonumber(g2.form.moverate1) or 0
		behavior2.speed	 = tonumber(g2.form.moverate2) or 0
		bot1time, bot2time = 0, 0
		if behavior1.percent then
			behavior1.percent = math.max(5, math.min(100, tonumber(g2.form.percent1) or 100))
			behavior1.percent = math.floor(behavior1.percent/5+.5)*5
		end
		if behavior2.percent then
			behavior2.percent = math.max(5, math.min(100, tonumber(g2.form.percent2) or 100))
			behavior2.percent = math.floor(behavior2.percent/5+.5)*5
		end
	end
end

function refresh()
	if g2.state == "menu" then
		readmenu()
		init_menu()
	elseif menustate == "behavior" then
		readmenu()
		init_botmenu()
	else
		show_toggles()
	end
end

function event(e)
	if e.type == "onclick" then
		if e.value:sub(1,4) == "init" then
			readmenu()
			botvsbot = e.value == "initbot"
			refresh()
			init_game()
			init_getready()
		elseif e.value == "newmap" then
			readmenu()
			seed = seed + 1
			init_game()
			init_getready()
		elseif e.value == "restart" then
			readmenu()
			init_game()
			init_getready()
		elseif e.value == "resume" then
			readmenu()
			g2.state = "play"
		elseif e.value == "menu" then
			init_menu()
		elseif e.value == "toggle" then
			show_toggles()
		elseif e.value == "quit" then
			g2.state = "quit"
		elseif e.value == "switch" then
			if spawnside == "right" then
				spawnside = "left"
			elseif spawnside == "left" then
				spawnside = "right"
			end
			for _, p in pairs(g2.search("planet -neutral")) do
				p:planet_chown(p:owner() == player and enemy or player)
			end
			for _, f in pairs(g2.search("fleet")) do
				for _, p in pairs(g2.search("planet")) do
					if p.n == f.fleet_target then
						g2.new_fleet(f:owner() == player and enemy or player, f.fleet_ships, f, p)
						f:destroy()
						break
					end
				end
			end
		elseif e.value == "crash" then
			crash = not crash
			refresh()
			if running then
				local value = crash and 100 or 0
				player.fleet_crash	= value
				enemy.fleet_crash	= value
				for _, f in pairs(g2.search("fleet")) do
					for _, p in pairs(g2.search("planet")) do
						if p.n == f.fleet_target then
							g2.new_fleet(f:owner(), f.fleet_ships, f, p)
							f:destroy()
							break
						end
					end
				end
			end
		elseif e.value == "show" then
			show = not show
			refresh()
			if running then
				player.ui_ships_show_mask = show and 0xf or 0x17
			end
		elseif e.value == "solid" then
			solid = not solid
			refresh()
			if running then
				for _, p in pairs(g2.search("planet")) do
					p.has_collide = solid
				end
			end
		elseif e.value == "lockside" then
			spawnside = spawnside == "random" and "right" or "random"
			refresh()
		elseif e.value == "bebot" then
			botvsbot = not botvsbot
			g2.state = "play"
		elseif e.value == "pause" then
			readmenu()
			init_pause()
		elseif e.value == "toggleback" then
			botrate	 = tonumber(g2.form.botrate	) or 0
			speed	 = tonumber(g2.form.speed	) or 1
			g2.ticks = speed
			init_pause()
		elseif e.value == "behavior" then
			if g2.state == "menu" then
				readmenu()
				menustate = menustate == "menu" and "behavior" or "menu"
				init_menu()
			elseif menustate == "behavior" then
				readmenu()
				menustate = "menu"
				show_toggles()
			else
				menustate = "behavior"
				init_botmenu()
			end
		elseif e.value == "redirect1" then
			behavior1.redirects = not behavior1.redirects
			refresh()
		elseif e.value == "redirect2" then
			behavior2.redirects = not behavior2.redirects
			refresh()
		elseif e.value == "tunnel1" then
			behavior1.tunnels = behavior1.tunnels == "on" and "off" or behavior1.tunnels == "off" and "only" or "on"
			refresh()
		elseif e.value == "tunnel2" then
			behavior2.tunnels = behavior2.tunnels == "on" and "off" or behavior2.tunnels == "off" and "only" or "on"
			refresh()
		elseif e.value == "multisel1" then
			behavior1.multiselect = not behavior1.multiselect
			refresh()
		elseif e.value == "multisel2" then
			behavior2.multiselect = not behavior2.multiselect
			refresh()
		elseif e.value == "percent1" then
			behavior1.percent = (not behavior1.percent) and 100
			refresh()
		elseif e.value == "percent2" then
			behavior2.percent = (not behavior2.percent) and 100
			refresh()
		elseif e.value == "unlimited1" then
			behavior1.unlimited = not behavior1.unlimited
			refresh()
		elseif e.value == "unlimited2" then
			behavior2.unlimited = not behavior2.unlimited
			refresh()
		elseif e.value == "freeze" then
			freezeplay = not freezeplay
			if not freezeplay then
				g2.speed = 1
			end
			refresh()
		end
	elseif e.type == "pause" then
		init_pause()
	end
end

function init_menu()
	g2.state = "menu"
	if menustate == "behavior" then
		init_botmenu()
		return
	end
	g2.html  = [[<table>
	<tr><td colspan=6><h1>Waffle3z's Bot 1v1</h1>
	<tr><td><p>&nbsp;</p>
	<tr><td><p>Map seed:			</p><td colspan=2><input type='text' name='seed'	/>
	    <td><p>Homes:				</p><td colspan=2><input type='text' name='homes'	/>
	<tr><td><p>Neutrals:			</p><td colspan=2><input type='text' name='neutrals'/>
	    <td><p>Starting ships:		</p><td colspan=2><input type='text' name='ships'	/>
	<tr><td><p>Home production:		</p><td colspan=2><input type='text' name='homeprod'/>
	    <td colspan=3><input type='button'      name='crash' value='Ships crash'   onclick='crash'    class='ibutton]]..(crash and 2 or 1)..[[' icon='klass-fighter'/>
	<tr><td><p>Neutral prod range:	</p><td><input type='text' name='prodmin' /><td><input type='text' name='prodmax' />
	    <td colspan=3><input type='button'      name='show'  value='Enemy ships'   onclick='show'     class='ibutton]]..(show  and 2 or 1)..[[' icon='icon-search'  />
	<tr><td><p>Neutral cost range:	</p><td><input type='text' name='costmin' /><td><input type='text' name='costmax' />
	    <td colspan=3><input type='button'      name='solid' value='Solid planets' onclick='solid'    class='ibutton]]..(solid and 2 or 1)..[[' icon='icon-world'   />
	<tr><td><p>Game speed:			</p><td colspan=2><input type='text' name='speed'/>
	    <td colspan=3><input type='button'      name='side'  value='Lock side'     onclick='lockside' class='ibutton]]..(spawnside == "random" and 1 or 2)..[[' icon='icon-forever'/>
	<tr><td colspan=3><p>&nbsp;</p>
		<td colspan=3><input type='button' name='freeze'value='Freeze play'   onclick='freeze'   class='ibutton]]..(freezeplay and 2 or 1)..[[' icon='icon-review'/>
	<tr><td colspan=3><p>&nbsp;</p>
	    <td colspan=3><input type='button'      name='bots'  value='Bot behavior'  onclick='behavior' class='ibutton1' icon='icon-custom'/>]]
	if running then
		g2.html = g2.html..[[
		<tr><td colspan=6><table><tr><td><input type='button' value='Resume'  onclick='pause'  class='ibutton1' icon='icon-play'   /></table>
		<tr><td colspan=6><table><tr><td><input type='button' value='Restart' onclick='init'   class='ibutton1' icon='icon-restart'/></table>
		<tr><td colspan=6><table><tr><td><input type='button' value='New Map' onclick='newmap' class='ibutton1' icon='icon-new_map'/></table>]]
	else
		g2.html = g2.html..[[
		<tr><td colspan=6><table><tr><td><input type='button' value='Play'       onclick='init'    class='ibutton1' icon='icon-play'   /></table>
		<tr><td colspan=6><table><tr><td><input type='button' value='Bot VS Bot' onclick='initbot' class='ibutton1' icon='icon-rivalry'/></table>
		</table>]]
	end
	g2.form.seed	 = seed
	g2.form.neutrals = neutrals
	g2.form.homes	 = homes
	g2.form.homeprod = homeprod
	g2.form.ships	 = ships
	g2.form.prodmin	 = prodmin
	g2.form.prodmax	 = prodmax
	g2.form.costmin	 = costmin
	g2.form.costmax	 = costmax
	g2.form.botrate	 = botrate
	g2.form.speed	 = speed
end
init = init_menu

function init_botmenu()
	local tunnel1 = behavior1.tunnels
	local tunnel1n = tunnel1 == "off" and 1 or tunnel1 == "on" and 2 or 3
	local tunnel2 = behavior2.tunnels
	local tunnel2n = tunnel2 == "off" and 1 or tunnel2 == "on" and 2 or 3
	g2.html  = [[<table>
	<tr><td colspan=4><h1>Bot Behavior Menu</h1>
	<tr><td><p>&nbsp;</p>
	<tr><td colspan=2><h2>Enemy bot</h2>
		<td colspan=2><h2>Auto bot</h2>
	<tr><td><p>Move rate:</p><td><input type='text' name='moverate1'/>
		<td><p>Move rate:</p><td><input type='text' name='moverate2'/>
	<tr><td colspan=2><input type='button' name='redirect1' value='Redirects'   onclick='redirect1' class='ibutton]]..(behavior1.redirects and 2 or 1)..[[' icon='klass-rocket'/>
		<td colspan=2><input type='button' name='redirect2' value='Redirects'   onclick='redirect2' class='ibutton]]..(behavior2.redirects and 2 or 1)..[[' icon='klass-rocket'/>
	<tr><td colspan=2><input type='button' name='tunnel1'   value='Tunnel ]]..tunnel1..[['  onclick='tunnel1' class='ibutton]]..tunnel1n..[[' icon='icon-more'/>
		<td colspan=2><input type='button' name='tunnel2'   value='Tunnel ]]..tunnel2..[['  onclick='tunnel2' class='ibutton]]..tunnel2n..[[' icon='icon-more'/>
	<tr><td colspan=2><input type='button' name='multisel1' value='Multiselect' onclick='multisel1' class='ibutton]]..(behavior1.multiselect and 2 or 1)..[[' icon='icon-clans'/>
		<td colspan=2><input type='button' name='multisel2' value='Multiselect' onclick='multisel2' class='ibutton]]..(behavior2.multiselect and 2 or 1)..[[' icon='icon-clans'/>
	<tr><td colspan=2><input type='button' name='percentb1' value='Auto percent' onclick='percent1' class='ibutton]]..(behavior1.percent and 1 or 2)..[['  icon='icon-controls'/>
		<td colspan=2><input type='button' name='percentb2' value='Auto percent' onclick='percent2' class='ibutton]]..(behavior2.percent and 1 or 2)..[['  icon='icon-controls'/>
	<tr><td><p>Set percent:</p><td><input type='text' name='percent1' ]]..(behavior1.percent and '' or 'disabled=true')..[[/>
		<td><p>Set percent:</p><td><input type='text' name='percent2' ]]..(behavior2.percent and '' or 'disabled=true')..[[/>
	<tr><td colspan=2><input type='button' name='unlimited1' value='Unlimited' onclick='unlimited1' class='ibutton]]..(behavior1.unlimited and 3 or 1)..[[' icon='icon-forever'/>
		<td colspan=2><input type='button' name='unlimited2' value='Unlimited' onclick='unlimited2' class='ibutton]]..(behavior2.unlimited and 3 or 1)..[[' icon='icon-forever'/>
	<tr><td><p>&nbsp;</p>
	<tr><td colspan=4><input type='button' name='bots' value='Back' onclick='behavior' class='ibutton1' icon='icon-restart'/>]]
	g2.form.moverate1 = behavior1.speed
	g2.form.moverate2 = behavior2.speed
	g2.form.percent1 = behavior1.percent or "Bot decision"
	g2.form.percent2 = behavior2.percent or "Bot decision"
end

function show_toggles()
	g2.html = [[<table>
		<tr><td colspan=2><input type='button' name='crash' value='Ships crash'   onclick='crash'    class='ibutton]]..(crash and 2 or 1)..[[' icon='klass-fighter'/>
		<tr><td colspan=2><input type='button' name='show'  value='Enemy ships'   onclick='show'     class='ibutton]]..(show  and 2 or 1)..[[' icon='icon-search'  />
		<tr><td colspan=2><input type='button' name='solid' value='Solid planets' onclick='solid'    class='ibutton]]..(solid and 2 or 1)..[[' icon='icon-world'   />
		<tr><td colspan=3><input type='button' name='freeze'value='Freeze play'   onclick='freeze'   class='ibutton]]..(freezeplay and 2 or 1)..[[' icon='icon-review'/>
		<tr><td colspan=3><input type='button' name='bots'  value='Bot behavior'  onclick='behavior' class='ibutton1' icon='icon-custom'/>	
		<tr><td><p>Game speed:			</p><td><input type='text' name='speed'  />
		<tr><td colspan=2><input type='button' value='Back' onclick='toggleback' class='ibutton1' icon='icon-restart'/>
	]]
	g2.form.speed	 = speed
	g2.form.botrate	 = botrate
end

function init_getready()
	g2.state = "pause"
	g2.html  = [[<table>
	<tr><td><h1>Get Ready!</h1>
	<tr><td><input type='button' value='Begin'        onclick='resume' class='ibutton1'                             icon='icon-play'    />
	<tr><td><input type='button' value='Become bot'   onclick='bebot'  class='ibutton]]..(botvsbot and 2 or 1)..[[' icon='icon-rivalry' />
	<tr><td><input type='button' value='Switch sides' onclick='switch' class='ibutton1'                             icon='icon-forever' />
	<tr><td><input type='button' value='New Map'      onclick='newmap' class='ibutton1'                             icon='icon-new_map' />
	<tr><td><input type='button' value='Toggles'      onclick='toggle' class='ibutton1'                             icon='icon-custom'  />
	<tr><td><input type='button' value='Menu'         onclick='menu'   class='ibutton1'                             icon='icon-settings'/>]]
end

function init_pause(x) 
	g2.state = "pause"
	g2.html  = [[<table>
	<tr><td><input type='button' value='Resume'  onclick='resume'  class='ibutton1' icon='icon-resume' />
	<tr><td><input type='button' value='Restart' onclick='restart' class='ibutton1' icon='icon-restart'/>]]
	if x == "win" then
		running = false
		g2.html = [[<table>
		<tr><td><h1>Good Job!</h1>
		<tr><td><input type='button' value='Replay'  onclick='restart' class='ibutton1' icon='icon-restart' />
		<tr><td><input type='button' value='New Map' onclick='newmap'  class='ibutton1' icon='icon-new_map' />
		<tr><td><input type='button' value='Menu'    onclick='menu'    class='ibutton1' icon='icon-settings'/>]]
	elseif x == "lose" then
		running = false
		g2.html = [[<table>
		<tr><td><input type='button' value='Try Again' onclick='restart' class='ibutton1' icon='icon-restart' />
		<tr><td><input type='button' value='New Map'   onclick='newmap'  class='ibutton1' icon='icon-new_map' />
		<tr><td><input type='button' value='Menu'      onclick='menu'    class='ibutton1' icon='icon-settings'/>]]
	else
		g2.html = g2.html..[[
		<tr><td><input type='button' value='Become bot'   onclick='bebot'  class='ibutton]]..(botvsbot and 2 or 1)..[[' icon='icon-rivalry' />
		<tr><td><input type='button' value='Switch sides' onclick='switch' class='ibutton1'                             icon='icon-forever' />
		<tr><td><input type='button' value='New Map'      onclick='newmap' class='ibutton1'                             icon='icon-new_map' />
		<tr><td><input type='button' value='Toggles'      onclick='toggle' class='ibutton1'                             icon='icon-custom'  />
		<tr><td><input type='button' value='Menu'         onclick='menu'   class='ibutton1'                             icon='icon-settings'/>]]
	end
	g2.html = g2.html..[[]]
end