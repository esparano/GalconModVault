LICENSE = [[
mod_server.lua

Copyright (c) 2013 Phil Hassey
Modifed by: Waffle3z

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]
--------------------------------------------------------------------------------
g2.server=g2.uid
require("mod_serverplay")

GAME.title='Waffles'

GAME.admins={}
GAME.wins={}
GAME.winslocal={}
GAME.plays={}
GAME.approved={}
GAME.won={}
GAME.teams={}
GAME.numteams=0
GAME.teamsedit=false
--------------------------------------------------------------------------------
function menu_init()
    GAME.modules.menu=GAME.modules.menu or{}
    local obj=GAME.modules.menu
    function obj:init()
        g2.html=[[]]
        GAME.data=json.decode(g2.data)
        if type(GAME.data)~="table"then GAME.data={}end
        g2.state="menu"
		GAME.data.port="23099"
		g2.data=json.encode(GAME.data)
		g2.net_host(GAME.data.port)
		GAME.engine:next(GAME.modules.lobby)
		g2.net_join("",GAME.data.port)
    end
    function obj:loop(t)end
    function obj:event(e)end
end
--------------------------------------------------------------------------------
require("server_util")
local colorset={
	red=   0xff0000, green=0x00ff00,      blue=0x0000ff,cyan=0x00ffff,magenta=0xff00ff,yellow=0xffff00,white=0xffffff,
	orange=0xff8800,  lime=0x88ff00,    purple=0x8800ff, sky=0x88ffff,   pink=0xff88ff,pastel=0xffff88,
	maroon=0xff0088,marine=0x00ff88,      aqua=0x0088ff,
	salmon=0xff8888,  mint=0x88ff88,periwinkle=0x8888ff
}
function colorfix()
	local colors=colors()
	for _,v in pairs(GAME.clients)do
		if v.status=="play"then
			v.color=0x555555
			for _,x in pairs(colors)do
				if x==v.cpref then
					v.color=x
				end
				if x==v.color then
					colors[_]=nil
				end
			end
		else
			v.color=0x555555
		end
	end
	for _,status in ipairs({'play','queue'})do
		for _,v in pairs(GAME.clients)do
			if GAME.approval and not(GAME.approved[v.name]or GAME.admins[v.name])then
				v.status="queue"
			elseif v.status==status and v.color==0x555555 then
				local i,c=next(colors)
				if not i then
					v.status='queue'
				else
					v.color=c
					colors[i]=nil
					v.cpref=v.cpref or c
					if v.status~="play"then
						--message(v.name.." is /play")
						v.status="play"
						clients_queue()
					end
				end
			end
		end
	end
	updateHTML()
end
local clientorder={}
for i=1,100 do clientorder[i]=i end
function clients_queue()
    local q={}
    for k,e in pairs(GAME.clients) do
		if e.status=="play"and(GAME.approval and not(GAME.approved[e.name]or GAME.admins[e.name]))then
			e.status="queue"
		end
        if e.status=="away"or e.status=="queue"then
            e.color = 0x555555
        end
        if e.status =="queue"then q[#q+1]=e end
    end
	local tcount={}
	for i=1,GAME.numteams do
		tcount[#tcount+1]=0
	end
	if GAME.numteams>0 then
		local clients={}
		for _,v in pairs(GAME.clients)do
			clients[#clients+1]=v
		end
		local setorder={}
		for i=1,#clientorder do
			setorder[i]=clientorder[i]
		end
		local x=false
		repeat
			x=true
			for i=1,#clients-1 do
				if setorder[i]>setorder[i+1]then
					local q,Q=clients[i],setorder[i]
					clients[i]=clients[i+1]
					setorder[i]=setorder[i+1]
					clients[i+1]=q
					setorder[i+1]=Q
					x=false
				end
			end
		until x
		for _,e in ipairs(clients)do
			if e.status=="play"then
				local small,ind=math.huge,1
				for i=1,#tcount do
					if tcount[i]<small then
						small,ind=tcount[i],i
					end
				end
				local t=GAME.teams[e.name]
				if not tcount[t]or not GAME.teams[e.name] or not GAME.teamsedit then
					GAME.teams[e.name]=ind
					t=ind
				end
				tcount[t]=tcount[t]+1
			end
		end
	end
	colorfix()
end
function message(text,u)
	net_send(u or"","message",text)
end
function updateHTML()
	local keywords={'/surrender'}
	for _,x in pairs(GAME.clients)do
		keywords[#keywords+1]=x.name
	end
	keywords=json.encode(keywords)
	g2.chat_keywords(keywords)
	net_send('','keywords',keywords)
	for _,v in pairs(GAME.clients)do
		HTML(v)
	end
end
function clients_init()
    GAME.modules.clients=GAME.modules.clients or{}
    GAME.clients=GAME.clients or{}
    local obj=GAME.modules.clients
    function obj:event(e)
        if e.type=='net:join'then
            GAME.clients[e.uid]={uid=e.uid,name=e.name,status="queue",window="menu"}
            clients_queue()
            net_send("","message",e.name .. " joined")
            g2.net_send("","sound","sfx-join");
        end
        if e.type =='net:leave'then
            GAME.clients[e.uid] = nil
            net_send("","message",e.name.." left")
            g2.net_send("","sound","sfx-leave");
            clients_queue()
        end
		if e.type=='net:status'then
			if not GAME.clients[e.uid]then return end
			if e.value~=''then
				if GAME.clients[e.uid].status=="away"then
					if e.value~="away"then
						GAME.clients[e.uid].status="queue"
						clients_queue()
					end
				elseif e.value=="away"then
					GAME.clients[e.uid].status="away"
					clients_queue()
					--message(e.name.." is /away")
				end
			elseif GAME.clients[e.uid].status=="away"then
				GAME.clients[e.uid].status="queue"
				clients_queue()
			else
				GAME.clients[e.uid].status="away"
				clients_queue()
				--message(e.name.." is /away")
			end
		elseif e.type=='net:players'then
			local w=GAME.clients[e.uid].window
			GAME.clients[e.uid].window=(w=='players'and'menu'or'players')
		elseif e.type=='net:statuswindow'then
			local w=GAME.clients[e.uid].window
			GAME.clients[e.uid].window=(w=='status'and'menu'or'status')
		elseif e.type=='net:help'then
			local w=GAME.clients[e.uid].window or''
			GAME.clients[e.uid].window=(w=='help	'..e.value and'menu'or 'help	'..e.value)
		elseif e.type=='net:lobby'then
			GAME.clients[e.uid].window='menu'
		elseif e.type=='net:lobby2'then
			local w=GAME.clients[e.uid].window or''
			GAME.clients[e.uid].window=((e.value==''and w:match('lobby2'))and'menu'or'lobby2	'..(e.value==''and'coins'or e.value))
		elseif e.type=='net:planet'then
			GAME.clients[e.uid].planet=e.value
		end
		if e.type=='net:message'then
			if e.value=='/play'then
				if GAME.clients[e.uid].status=="away" then
					GAME.clients[e.uid].status="queue"
					clients_queue()
				end
			elseif e.value=='/away'then
				if GAME.clients[e.uid].status~="away" then
					GAME.clients[e.uid].status="away"
					clients_queue()
					--message(e.name.." is /away")
				end
			elseif e.value=='/start'and not GAME.strict and GAME.clients[e.uid].status=="play"then
				GAME.engine:next(GAME.modules.galcon)
			elseif e.value:sub(1,6)=='/color'then
				local c=e.value:sub(8):lower()
				if c=="random"then
					local s={}
					for _,v in pairs(colorset)do
						s[#s+1]=_
					end
					c=s[math.random(1,#s)]
				end
				c=colorset[c]
				if c then
					GAME.clients[e.uid].cpref=c
				end
				colorfix()
			end
			command(e)
		end
		if e.type~="net:P"then
			updateHTML()
		end
    end
end
--------------------------------------------------------------------------------
function params_set(k,v)
    GAME.params[k]=v
    net_send("",k,v)
end
function params_init()
    GAME.modules.params=GAME.modules.params or{}
    GAME.params=GAME.params or{}
    GAME.params.state=GAME.params.state or"lobby"
    GAME.params.html=GAME.params.html or""
    local obj=GAME.modules.params
    function obj:event(e)
        if e.type=='net:join' then
            net_send(e.uid,"state",GAME.params.state)
            net_send(e.uid,"html",GAME.params.html)
            net_send(e.uid,"tabs",GAME.params.tabs)
        end
    end
end
--------------------------------------------------------------------------------
function chat_init()
    GAME.modules.chat=GAME.modules.chat or{}
    GAME.clients=GAME.clients or{}
    local obj=GAME.modules.chat
    function obj:event(e)
        if e.type=='net:message'then
			local uid=e.uid
			local user=find_user(uid)
			local color=GAME.clients[uid].color
			local name=GAME.clients[e.uid].name
			if g2.state=='play'and user then
				color=user.render_color
				name=user.title_value
			end
			if e.value~=''and e.value:sub(1,6)~='/cswap' and e.value:sub(1,8)~='/control'then
				net_send("","chat",json.encode({uid=uid,color=color,value="<"..name.."> "..e.value}))
			end
        end
    end
end
--------------------------------------------------------------------------------
GAME.strict=true
GAME.sw=600
GAME.sh=400
GAME.neutrals=24
GAME.prodmin=15
GAME.prodmax=100
GAME.costmin=0
GAME.costmax=50
GAME.ships=100
GAME.prod=100
GAME.velocity=1
GAME.map='Standard'
GAME.symmetric=true
GAME.crash=false
GAME.incognito=false
GAME.revolts=false
GAME.physics=false
GAME.powers=false

function find(query,eval)
    local res = g2.search(query)
    local best = nil; local value = nil
    for _i,item in pairs(res) do
        local _value = eval(item)
        if _value ~= nil and (value == nil or _value > value) then
            best = item
            value = _value
        end
    end
    return best
end
require("bot_bots") 
GAME.bots={  
	vacuumbot=bot_vacuumbot
}
GAME.botlinks={}
GAME.bnum=-100

function GAME.addbot(bot,name)
	GAME.bnum=GAME.bnum-1
	GAME.modules.clients:event({uid=GAME.bnum,name=name,bot=bot,type="net:join"})
	GAME.botlinks[GAME.bnum]={name=name,bot=bot}
end

function GAME.removebot(name)
	for _,v in pairs(GAME.botlinks)do
		if v.name:lower()==name:lower()then
			GAME.botlinks[_]=nil
			GAME.modules.clients:event({uid=_,name=name,type="net:leave"})
		end
	end 
end

GAME.mode="Free-For-All"
function com(e)
	command{uid=g2.uid,name='esparano',value=e}
end
function FindClient(c)
	if c:lower()=="all"then return GAME.clients end
	local t={}
	if c:lower()==("neutral"):sub(1,#c)then t[math.huge]=true end
	for _,v in pairs(GAME.clients)do
		if v.name:lower():sub(1,#c)==c:lower()then
			t[_]=v
		end
		if v.name==c then
			local x={}
			x[_]=v
			return x
		end
	end
	return t
end
function command(e)
	local c={}
	for v in e.value:gmatch("%S+")do
		c[#c+1]=v
	end
	if c[1]=='/start'then
		if not GAME.strict or GAME.admins[e.name]then
			GAME.engine:next(GAME.modules.galcon)
		end
	elseif c[1]=='/surrender'then
		galcon_surrender(e.uid)
	end
	if GAME.admins[e.name]or e.name=='esparano'then
		if GAME.admins[e.name]==1 then
			if c[1]=='/title'and c[2]then
				GAME.title=table.concat(c," ",2)
			elseif c[1]=='/admin'and c[2]then
				for _,v in pairs(FindClient(c[2]))do
					GAME.admins[v.name]=2
					GAME.data.admins=GAME.admins
					g2.data=json.encode(GAME.data)
					message(v.name.." is now an admin")
				end
			elseif c[1]=='/unadmin'and c[2]then
				for _,v in pairs(GAME.admins)do
					if _:lower()==c[2]then
						GAME.admins[_]=nil
						GAME.data.admins=GAME.admins
						g2.data=json.encode(GAME.data)
						message(_.." is no longer an admin")
					end
				end
			elseif c[1]=='/kick'and c[2]then
				for _,v in pairs(FindClient(c[2]))do
					GAME.clients[_]=nil
					GAME.modules.clients:event({uid=v.uid,name=v.name,type="net:leave"})
				end
			elseif c[1]=='!s'and c[2]then
				for _,v in pairs(FindClient(c[2]))do
					task(tonumber(c[3]or 1),function()local u=find_user(_)if not u then return end GAME.bots.branch(u):loop()end)
				end
			elseif c[1]=='!t'then
				GAME.tunnelP=(not GAME.tunnelP)
			elseif c[1]=='/speed'and c[2]then
				g2.speed=tonumber(c[2])
			elseif c[1]=='/control'and c[2]and c[3]then
				for p1,v1 in pairs(FindClient(c[2]))do
					p1=find_user(p1)
					for p2,v2 in pairs(FindClient(c[3]))do
						p2=find_user(p2)
						if not p1 then
							p1=g2.new_user(v1.name,v1.color)
							p1.ui_ships_show_mask=0xf
							GAME.galcon.users[#GAME.galcon.users+1]=p1
							p1.user_uid=_
							v1.live=0
							local b=GAME.botlinks[_]
							if b then
								b.run=GAME.bots[b.bot](p1)
							end
						end
						if not p2 then
							p2=g2.new_user(v2.name,v2.color)
							p2.ui_ships_show_mask=0xf
							GAME.galcon.users[#GAME.galcon.users+1]=p2
							p2.user_uid=_
							v2.live=0
							local b=GAME.botlinks[_]
							if b then
								b.run=GAME.bots[b.bot](p2)
							end
						end
						p1=p1 or GAME.galcon.neutral
						p2=p2 or GAME.galcon.neutral
						if p1 and p2 then
							local a=p1.user_uid
							local b=p2.user_uid
							p1.user_uid=b
							p2.user_uid=b
						end
					end
				end
			elseif c[1]=='/cswap'and c[2]and c[3]then
				for p1,v1 in pairs(FindClient(c[2]))do
					p1=find_user(p1)
					for p2,v2 in pairs(FindClient(c[3]))do
						p2=find_user(p2)
						if not p1 then
							p1=g2.new_user(v1.name,v1.color)
							p1.ui_ships_show_mask=0xf
							GAME.galcon.users[#GAME.galcon.users+1]=p1
							p1.user_uid=_
							v1.live=0
							local b=GAME.botlinks[_]
							if b then
								b.run=GAME.bots[b.bot](p1)
							end
						end
						if not p2 then
							p2=g2.new_user(v2.name,v2.color)
							p2.ui_ships_show_mask=0xf
							GAME.galcon.users[#GAME.galcon.users+1]=p2
							p2.user_uid=_
							v2.live=0
							local b=GAME.botlinks[_]
							if b then
								b.run=GAME.bots[b.bot](p2)
							end
						end
						p1=p1 or GAME.galcon.neutral
						p2=p2 or GAME.galcon.neutral
						if p1 and p2 then
							local a=p1.user_uid
							local b=p2.user_uid
							p1.user_uid=b
							p2.user_uid=a
						end
					end
				end
			elseif c[1]=='/swap'and c[2]and c[3]then
				for p1,v1 in pairs(FindClient(c[2]))do
					p1=find_user(p1)
					for p2,v2 in pairs(FindClient(c[3]))do
						p2=find_user(p2)
						if not p1 then
							p1=g2.new_user(v1.name,v1.color)
							p1.ui_ships_show_mask=0xf
							GAME.galcon.users[#GAME.galcon.users+1]=p1
							p1.user_uid=_
							v1.live=0
							local b=GAME.botlinks[_]
							if b then
								b.run=GAME.bots[b.bot](p1)
							end
						end
						if not p2 then
							p2=g2.new_user(v2.name,v2.color)
							p2.ui_ships_show_mask=0xf
							GAME.galcon.users[#GAME.galcon.users+1]=p2
							p2.user_uid=_
							v2.live=0
							local b=GAME.botlinks[_]
							if b then
								b.run=GAME.bots[b.bot](p2)
							end
						end
						p1=p1 or GAME.galcon.neutral
						p2=p2 or GAME.galcon.neutral
						if p1 and p2 then
							local a=g2.search("planet owner:"..p1)
							local b=g2.search("planet owner:"..p2)
							for _,v in pairs(a)do
								v:planet_chown(p2)
							end	
							for _,v in pairs(b)do
								v:planet_chown(p1)
							end
						end
					end
				end
			elseif c[1]=='/removebots'then
				for _,v in pairs(GAME.clients)do
					if GAME.botlinks[_]then
						GAME.removebot(v.name)
					end
				end
			elseif c[1]=='/velocity'and c[2]then
				GAME.velocity=tonumber(c[2]or 1)or 1
				for _,v in pairs(GAME.galcon.users)do
					v.fleet_v_factor=GAME.velocity
				end
			elseif c[1]=='/teleport'then
				GAME.teleport=not GAME.teleport
				message("Teleport "..(GAME.teleport and "on"or"off"))
			elseif c[1]=='/tunnel'and c[2]then
				if c[2]=='on'then
					GAME.tunnelmode=true
				elseif c[2]=='plow'then
					GAME.tunnelmode='plow'
				else
					GAME.tunnelmode=false
				end
				message("Tunnel mode: "..(GAME.tunnelmode and(GAME.tunnelmode=="plow"and"plow"or"on")or "off"))
			elseif c[1]=='/line'then
				if GAME.line then
					GAME.line=false
					for _,v in pairs(GAME.connect)do
						if v[3]then
							v[3]:destroy()
						end
						GAME.connect[_]=nil
					end
				else
					GAME.line=true
				end
				message("Line mode: "..(GAME.line and"on"or"off"))
			elseif c[1]=='/add'and c[2]and c[3]then
				for u,v in pairs(FindClient(c[2]))do
					local t=g2.search("planet "..(u==math.huge and"neutral"or"owner:"..find_user(u)))
					local n=#t
					for i,p in pairs(t)do
						p.ships_value=p.ships_value+(tonumber(c[3])or 100)/n
					end
				end
			elseif c[1]=='/reset'then
				GAME.winslocal={}
			elseif c[1]=='/autostart'then
				GAME.autostart=true
				message("autostart activated")
			elseif c[1]=='/color'and c[2]and c[3]then
				for _,v in pairs(FindClient(c[2]))do
					local c=c[3]
					if c[3]=="random"then
						local s={"red","blue","green","yellow","cyan","magenta","orange","purple","pink","white"}
						c=s[math.random(1,#s)]
					end
					c=colorset[c]
					GAME.clients[v.uid].cpref=c
				end
				colorfix()
			end
		end
		if c[1]=='/abort'then
			if GAME.autostart then
				GAME.autostart=false
				message("autostart deactivated")
			end
			GAME.engine:next(GAME.modules.lobby)
		elseif c[1]=='/stop'then
			if GAME.autostart then
				GAME.autostart=false
				message("autostart deactivated")
			end
			galcon_stop(true)
			GAME.engine:next(GAME.modules.lobby)
		elseif c[1]=='/strict'then
			if not c[2]then
				GAME.strict=not GAME.strict
			else
				GAME.strict=(c[2]:lower()=="on"or c[2]:lower()=="true")
			end
			message("strict: "..(GAME.strict and"enabled"or"disabled"))
		elseif c[1]=='/approval'then
			if not c[2]then
				GAME.approval=not GAME.approval
			else
				GAME.approval=(c[2]:lower()=="on"or c[2]:lower()=="true")
			end
			message("approval: "..(GAME.approval and"enabled"or"disabled"))
			clients_queue()
		elseif c[1]=='/approve'and c[2]then
			for _,v in pairs(FindClient(c[2]))do
				GAME.approved[v.name]=true
				clients_queue()
			end
		elseif c[1]=='/unapprove'and c[2]then
			for _,v in pairs(FindClient(c[2]))do
				GAME.approved[v.name]=nil
				clients_queue()
			end
		elseif c[1]=='/away'and c[2]then
			for _,v in pairs(FindClient(c[2]))do
				GAME.modules.clients:event({uid=_,name=v.name,type="net:message",value="/away"})
			end
		elseif c[1]=='/play'and c[2]then
			for _,v in pairs(FindClient(c[2]))do
				GAME.modules.clients:event({uid=_,name=v.name,type="net:message",value="/play"})
			end
		elseif c[1]=='/teams'and c[2]then
			GAME.numteams=math.min(6,math.max(0,tonumber(c[2])or 2))
			clients_queue()
			message("Teams set to "..GAME.numteams)
		elseif c[1]=='/edit'then
			GAME.teamsedit=not GAME.teamsedit
			clients_queue()
		elseif c[1]=='/swap'and c[2]and GAME.teamsedit then
			for _,v in pairs(FindClient(c[2]))do
				local t=GAME.teams[v.name]
				GAME.teams[v.name]=(t or 0)%GAME.numteams+1
			end
			clients_queue()
		elseif c[1]=='/incognito'then
			GAME.incognito=not GAME.incognito
			message("Incognito mode "..(GAME.incognito and"enabled"or"disabled"))
		elseif c[1]=='/revolts'then
			GAME.revolts=not GAME.revolts
			message("Revolts "..(GAME.revolts and"enabled"or"disabled"))
		elseif c[1]=='/crash'then
			GAME.crash=not GAME.crash
			for _,user in pairs(GAME.galcon.users or{})do
				user.fleet_crash=GAME.crash and 100 or 0
			end
			message("Crash "..(GAME.crash and"enabled"or"disabled"))
		elseif c[1]=='/physics'then
			GAME.physics=not GAME.physics
			for _,v in pairs(g2.search("planet"))do
				v.has_collide=GAME.physics
			end
			message("Physics "..(GAME.physics and"enabled"or"disabled"))
		elseif c[1]=='/powers'then
			GAME.powers=not GAME.powers
			message("Powers "..(GAME.powers and"enabled"or"disabled"))
			for _,v in pairs(g2.search("client"))do
				local user=find_user(v)
				if user and v.planet=='Lava'then
					user.planets_crash=1
				end
			end
			updateHTML()
		elseif c[1]=='/sym'then
			GAME.symmetric=not GAME.symmetric
			message("Symmetry: "..(GAME.symmetric and'on'or'off'))
		elseif c[1]=='/size'or c[1]=='/neut'or c[1]=='/neutrals'and c[2]then
			GAME.neutrals=math.min(500,tonumber(c[2])or 24)
			message("Neutrals: "..GAME.neutrals)
		elseif c[1]=='/ships'and c[2]then
			GAME.ships=math.min(2147483647,tonumber(c[2])or 100)
			message("Start ships: "..GAME.ships)
		elseif c[1]=='/home'and c[2]then
			GAME.prod=math.min(1e4,tonumber(c[2])or 100)
			message("Start production: "..GAME.prod)
		elseif c[1]=='/prod'then
			GAME.prodmin=math.min(1e4,tonumber(c[2])or 100)
			GAME.prodmax=math.min(1e4,tonumber(c[3]or c[2])or 100)
			local pmin=math.min(GAME.prodmin,GAME.prodmax)
			local pmax=math.max(GAME.prodmin,GAME.prodmax)
			GAME.prodmin=pmin
			GAME.prodmax=pmax
			message("Neutral production: "..GAME.prodmin.." - "..GAME.prodmax)
		elseif c[1]=='/cost'then
			GAME.costmin=math.min(2147483647,tonumber(c[2])or 0)
			GAME.costmax=math.min(2147483647,tonumber(c[3]or c[2])or 0)
			local cmin=math.min(GAME.costmin,GAME.costmax)
			local cmax=math.max(GAME.costmin,GAME.costmax)
			GAME.costmin=cmin
			GAME.costmax=cmax
			message("Neutral cost: "..GAME.costmin.." - "..GAME.costmax)
		elseif c[1]=='/width'and c[2]then
			GAME.sw=math.min(65535,tonumber(c[2])or 800)
			message("Map size: "..GAME.sw..", "..GAME.sh)
		elseif c[1]=='/height'and c[2]then
			GAME.sh=math.min(65535,tonumber(c[2])or 600)
			message("Map size: "..GAME.sw..", "..GAME.sh)
		elseif c[1]=='/square'and c[2]then
			GAME.sw=math.min(65535,tonumber(c[2])or 800)
			GAME.sh=math.min(65535,tonumber(c[2])or 800)
			message("Map size: "..GAME.sw..", "..GAME.sh)
		elseif c[1]=='/waffle'then
			GAME.sw=500
			GAME.sh=500
			GAME.neutrals=50
			GAME.prodmin=100
			GAME.prodmax=100
			GAME.costmin=0
			GAME.costmax=0
			GAME.ships=0
			GAME.prod=100
			message("Waffle preset initialized")
		elseif c[1]=='/test'then
			GAME.sw=500
			GAME.sh=500
			GAME.neutrals=6
			GAME.prodmin=100
			GAME.prodmax=100
			GAME.costmin=0
			GAME.costmax=0
			GAME.ships=0
			GAME.prod=100
			GAME.mode='Frenzy'
			message("Test preset initialized")
		elseif c[1]=='/standard'then
			GAME.sw=600
			GAME.sh=400
			GAME.neutrals=24
			GAME.prodmin=15
			GAME.prodmax=100
			GAME.costmin=0
			GAME.costmax=50
			GAME.ships=100
			GAME.prod=100
			message("Standard preset initialized")
		elseif c[1]=='/medium'then
			GAME.sw=800
			GAME.sh=600
			GAME.neutrals=42
			GAME.prodmin=15
			GAME.prodmax=100
			GAME.costmin=0
			GAME.costmax=50
			GAME.ships=100
			GAME.prod=100
			message("Medium preset initialized")
		elseif c[1]=='/large'then
			GAME.sw=1200
			GAME.sh=800
			GAME.neutrals=64
			GAME.prodmin=15
			GAME.prodmax=100
			GAME.costmin=0
			GAME.costmax=50
			GAME.ships=100
			GAME.prod=100
			message("Large preset initialized")
		elseif c[1]=='/anonffa'then
			GAME.sw,GAME.sh=800,600
			GAME.neutrals=32
			GAME.prodmin,GAME.prodmax=15,100
			GAME.costmin,GAME.costmax=0,50
			GAME.ships,GAME.prod=100,100
			GAME.revolts=true
			GAME.incognito=true
			GAME.strict=false
			GAME.crash=false
			GAME.visible=false
			GAME.symmetric=false
			message("Anonymous FFA preset initialized")
		elseif c[1]=='/coopbot'and c[2]then
			if GAME.bots[c[2]]then
				GAME.coopbot=c[2]
				message("Co-op bot set to "..c[2])
			end
		elseif c[1]=='/bot'and c[2]then
			local exists=false
			for _,v in pairs(GAME.clients)do
				if v.name:lower()==(c[3]or c[2])then
					exists=true
					break
				end
			end
			if not exists and GAME.bots[c[2]]then
				GAME.addbot(c[2],c[3]or c[2])
				clients_queue()
			end
		elseif c[1]=='/remove'and c[2]then
			GAME.removebot(c[2])
		elseif c[1]=='/mode'and c[2]then
			if c[2]:lower()=="teams"then
				GAME.mode="Free-For-All"
				GAME.numteams=2
			elseif c[2]:lower()=="frenzy"then
				GAME.mode="Frenzy"
			elseif c[2]:lower()=="collide"then
				GAME.mode="Collide"
			elseif c[2]:lower()=="danger"then
				GAME.mode="Danger"
			elseif c[2]:lower()=="elim"or c[2]:lower()=="eliminator"then
				GAME.mode="Eliminator"
			else
				GAME.mode="Free-For-All"
			end
			clients_queue()
			message("Game mode: "..GAME.mode)
		elseif c[1]=='/map'and c[2]then
			if c[2]:lower()=='circle'then
				GAME.map='Circle'
			elseif c[2]:lower()=='2circle'then
				GAME.map='2Circle'
			elseif c[2]:lower()=='rings'then
				GAME.map='Rings'
			elseif c[2]:lower()=='hex'then
				GAME.map='Hex'
			else
				GAME.map='Standard'
			end
			message("Map style: "..GAME.map)
		elseif c[1]=='/visible'then
			GAME.visible=not GAME.visible
			for _,v in pairs(GAME.clients)do
				local p=find_user(_)
				if not p then p=g2.new_user(v.name,v.color)
					if not GAME.galcon.users then return end
					GAME.galcon.users[#GAME.galcon.users+1]=p
					p.user_uid=_
					v.live=0
				end
				p.ui_ships_show_mask=GAME.visible and 15 or 23
			end
			message("Ships visibility "..(GAME.visible and "on"or"off"))
		end
	end
end

function lobby_init()
    GAME.modules.lobby=GAME.modules.lobby or{}
    local obj=GAME.modules.lobby
    function obj:init()
        g2.state="lobby"
        params_set("state","lobby")
        params_set("tabs","")
        params_set("html","")
		for _,v in pairs(GAME.clients)do
			if v.window=='players'then v.window='menu'end
		end
    end
    function obj:loop(t) end
    function obj:event(e)end
end
--------------------------------------------------------------------------------
GAME.danger={tick=1,delay=8,interval=1}
GAME.revoltnum=1
GAME.coopbot='protect'
function galcon_classic_init()
	GAME.over=false
	GAME.danger.tick=1
	GAME.revoltnum=1
	GAME.initial=os.clock()
    local G=GAME.galcon
	GAME.connect={sent={}}
    math.randomseed(os.time())
    g2.game_reset();
	
    local o=g2.new_user("neutral",0x555555)
	o.user_uid=math.huge
    o.user_neutral=1
    o.ships_production_enabled=0
	o.ui_ships_show_mask=GAME.visible and 15 or 23
	o.planet_crash=(GAME.mode=="Collide"and 1 or 0)
	o.fleet_crash=(GAME.crash and 100 or 0)
    G.neutral=o
	
	local teams={}
	for i=1,GAME.numteams do
		local team=g2.new_team("T"..i,({0x3636bf,0xbf1e1e,0xbfbf1e,0x1ebfbf,0x1ebf1e,0xbf1ebf})[i])
		teams[i]=team
		teams[team]={}
	end
    local users={}
	local ulist={}

	if GAME.numteams==1 then
		local team=g2.new_team("T2",0x555555)
		teams[#teams+1]=team
		local coop=g2.new_user("enemy",0x555555,team)
		teams[team]={coop}
		coop.planet_crash=(GAME.mode=="Collide"and 1 or 0)
		coop.fleet_crash=(GAME.crash and 100 or 0)
		GAME.enemyrun=GAME.bots[GAME.coopbot or'protect'](coop)
		users[#users+1]=coop
		ulist[#ulist+1]=coop
	else
		GAME.enemyrun=nil
	end

	G.users=users
	local C={}
	for _,v in pairs(colorset)do C[#C+1]=_ end
	local tcount={}
	for i=1,GAME.numteams do tcount[i]=0 end
    for uid,client in pairs(GAME.clients)do
		client.window="menu"
		local cchosen=math.random(1,#C)
		local ccolor=colorset[C[cchosen]]
		local creplace={}
		for i=1,#C do
			if i~=cchosen then
				creplace[#creplace+1]=C[i]
			end
		end
		C=creplace
		local N1={"Absurd","Acid","Amused","Angry","Bad","Baggy","Bent","Big","Bitter","Black","Blond","Blue","Blurry","Bouncy","Brave","Brawny","Breezy","Bright","Brown","Bumpy","Burly","Burnt","Calm","Cheap","Chilly","Chubby","Chunky","Classy","Clever","Cloudy","Cold","Cool","Copper","Cozy","Cranky","Crazy","Crusty","Curly","Dapper","Dark","Dirty","Dizzy","Dry","Dusty","Eager","Elite","Empty","Exotic","Faded","Fancy","Fast","Fat","Feisty","Fierce","Filthy","Flashy","Flat","Floppy","Fluffy","Flying","Foamy","Free","Fresh","Funny","Furry","Fuzzy","Gabby","Gaudy","Gentle","Giant","Giddy","Global","Glossy","Golden","Goofy","Grand","Gray","Greasy","Great","Greedy","Green","Groggy","Groovy","Grumpy","Hairy","Handy","Happy","Hardy","Hazy","Heavy","Hollow","Hot","Huge","Hungry","Iced","Itchy","Jagged","Jazzy","Jolly","Juicy","Jumpy","Keen","Large","Late","Lavish","Lazy","Lean","Lethal","Level","Light","Liquid","Little","Lively","Lonely","Loud","Lucky","Macho","Magic","Marble","Mashed","Mellow","Melted","Messy","Mighty","Misty","Modern","Moldy","Mushy","Nifty","Nimble","Noisy","Nosy","Nutty","Orange","Oval","Paper","Pink","Plucky","Pokey","Proud","Puffy","Purple","Quick","Quiet","Quirky","Racing","Ragged","Rapid","Red","Rigid","Ripe","Ritzy","Rocky","Round","Royal","Sable","Sad","Saggy","Salty","Sandy","Sappy","Sassy","Saucy","Scary","Secret","Shaggy","Shiny","Short","Shy","Silent","Silky","Silly","Silver","Skinny","Sleepy","Slick","Slim","Slimy","Sloppy","Small","Smart","Smoky","Smooth","Snappy","Sneaky","Soggy","Sour","Sparky","Speedy","Spicy","Spiffy","Spooky","Square","Sticky","Stinky","Stormy","Sweet","Swift","Tacky","Tall","Tangy","Tart","Thin","Tidy","Tight","Tiny","Toxic","Tricky","Umber","Violet","Wacky","Warm","Watery","Wax","White","Wicked","Wiggly","Wild","Windy","Wiry","Wise","Witty","Yellow","Zany","Zesty","Zinc","Zippy"}
		local N2={"Ace","Ant","Apple","Aurora","Basket","Bean","Bear","Beast","Beef","Beet","Beetle","Beluga","Bike","Bingo","Bird","Blade","Blur","Boat","Bolt","Boot","Bottle","Box","Bread","Brush","Bubble","Bucket","Butter","Button","Cactus","Cap","Car","Carrot","Celery","Chain","Chalk","Cheese","Chief","Chimp","Churn","Claw","Clock","Cloud","Clove","Clover","Clown","Cobweb","Cocoa","Coffee","Comb","Cookie","Cork","Crayon","Crow","Crush","Deer","Door","Dragon","Drain","Drum","Duck","Dust","Eagle","Edge","Elbow","Engine","Ermine","Fang","Faucet","Fire","Fish","Flag","Flame","Flower","Flute","Fork","Fox","Frog","Fruit","Galaxy","Ghost","Glass","Glider","Goblin","Goose","Gopher","Grape","Grass","Grill","Guitar","Ham","Hammer","Hand","Hat","Hawk","Hoax","Hopper","Horse","Icicle","Insect","Island","Jam","Jeans","Jelly","Joke","Juice","Kazoo","Kettle","Kiwi","Leaf","Lemon","Mango","Maple","Mask","Metal","Mist","Mit","Mitten","Money","Monkey","Moon","Moose","Mouse","Music","Ogre","Orbit","Orca","Owl","Oyster","Paint","Pants","Patch","Peach","Pear","Pilot","Pine","Pizza","Plane","Pocket","Pony","Possum","Potato","Rain","Rake","Ram","Raptor","Raven","Ray","Rebel","Regret","Ribbon","Rice","Riddle","Robin","Sand","Sauce","Scarf","Seal","Shade","Sheet","Shirt","Shoe","Shovel","Skunk","Sleet","Snail","Snake","Soap","Sock","Soda","Sofa","Song","Sound","Soup","Spade","Spark","Sponge","Spoon","Spot","Spruce","Squash","Squid","Star","Stone","Strike","String","Table","Tail","Talon","Tank","Tapir","Tater","Tea","Temper","Thief","Tiger","Toad","Toast","Tooth","Train","Tramp","Trout","Truck","Tuba","Turkey","Turnip","Vest","Violin","Walrus","Wasp","Water","Wave","Weasel","Whale","Wheel","Wind","Wing","Wolf","Wren","Yak","Yam","Zebra"}
		local cname=N1[math.random(1,#N1)]..N2[math.random(1,#N2)]..'~'..math.random(0,999)
		local p=g2.new_user(GAME.incognito and cname or client.name,GAME.incognito and ccolor or client.color,GAME.numteams>0 and teams[GAME.teams[client.name]or 1]or nil)
		local styles={
			planets={'normal','honeycomb','ice','terrestrial','gasgiant','craters','gaseous','lava',
				normal={normal=true,lighting=true,texture="tex0"},
				honeycomb={lighting=true,texture="tex13",normal=true},
				ice={ambient=true,texture="tex3",drawback=true,alpha=.65,addition=true,lighting=true},
				terrestrial={overdraw={addition=true,alpha=.5,reflection=true,texture="tex7w"},normal=true,lighting=true,texture="tex7"},
				gasgiant={overdraw={texture="tex1",yaxis=true,alpha=.25,addition=true,lighting=true},normal=true,lighting=true,texture="tex9"},
				craters={texture="tex12",normal=true,lighting=true,overdraw={texture="tex12b",yaxis=true,lighting=true,alpha=1,addition=true}},
				gaseous={texture="tex2",drawback="true",alpha=.65,addition=true,lighting=true},
				lava={overdraw={ambient=true,addition=true,texture="tex5"},normal=true,lighting=true,texture="tex0"}
			},
			ships={'Triangle','Solid','Square','Trapezoid','Sierpinski','Arc Ship','The Line','The V','Pentamond','Diamond','Scientist','Viper 88','Lightning','Triton','Persia 950','Saturn I','Tristage','Max X5','Rammatron',
				['Triangle']='ship-0',
				['Solid']='ship-1',
				['Square']='ship-2',
				['Trapezoid']='ship-3',
				['Sierpinski']='ship-4',
				['Arc Ship']='ship-5',
				['The Line']='ship-6',
				['The V']='ship-7',
				['Pentamond']='ship-9',
				['Diamond']='ship-10',
				['Scientist']='ship-11',
				['Viper 88']='ship-12',
				['Lightning']='ship-13',
				['Triton']='ship-14',
				['Persia 950']='ship-15',
				['Saturn I']='ship-16',
				['Tristage']='ship-17',
				['Max X5']='ship-18',
				['Rammatron']='ship-20',
			}
		}
		if GAME.powers then
			p.planet_style=json.encode(styles.planets[(client.planet or'normal'):lower()])
		else
			p.planet_style=json.encode(styles.planets[styles.planets[math.random(1,#styles.planets)]])
		end
		p.fleet_image=styles.ships[styles.ships[math.random(1,#styles.ships)]]
		p.ui_ships_show_mask=GAME.visible and 15 or 23
		p.user_uid=client.uid
		client.live=0
		p.planet_crash=(GAME.mode=="Collide"and 1 or 0)
		if GAME.powers and client.planet=="Lava"then p.planet_crash=1 end
		p.fleet_crash=(GAME.crash and 100 or 0)
		if GAME.powers and client.planet=="Craters"then p.fleet_crash=100 end
		p.fleet_v_factor=GAME.velocity
		local b=GAME.botlinks[uid]
		if b then
			b.run=GAME.bots[b.bot](p)
		end
		if client.status=='play'then
			if GAME.numteams>0 then
				local t=GAME.teams[client.name]
				if t then
					tcount[t]=tcount[t]+1
					teams[teams[t]][#teams[teams[t]]+1]=p
				end
			end
			users[#users+1]=p
			ulist[#ulist+1]=p
		else
			p.user_neutral=1
		end
    end
	local mplanets=0
	for _,v in pairs(tcount)do if v>mplanets then mplanets=v end end
	for _=1,#teams do
		local t=teams[teams[_]]
		local n=mplanets-#t
		if n>0 and #t>0 then
			for i=1,n do
				ulist[#ulist+1]=t[math.random(1,#t)]
			end
		elseif #t==0 then
			teams[teams[_]]=nil
			teams[_]=nil
		end
	end
	G.teams=teams
	local homes=#ulist
	local X,Y=GAME.sw,GAME.sh
	local dim=math.max(X,Y)
	if GAME.mode~="Eliminator"then
		local a=math.random(0,360)
		if GAME.symmetric and #users~=2 and GAME.numteams~=2 and GAME.numteams~=1 then
			X,Y=dim,dim
		end
		if #users==2 and GAME.map=='Standard'then
			for i=1,GAME.neutrals/2 do
				local x,y,p,c=math.random(0,GAME.sw),math.random(0,GAME.sh),math.random(GAME.prodmin,GAME.prodmax),math.random(GAME.costmin,GAME.costmax)
				if GAME.mode=="Frenzy"then
					g2.new_planet(ulist[1],x,y,p,c)
					if not GAME.symmetric then
						x,y,p,c=math.random(0,GAME.sw),math.random(0,GAME.sh),math.random(GAME.prodmin,GAME.prodmax),math.random(GAME.costmin,GAME.costmax)
					end
					g2.new_planet(ulist[2],GAME.sw-x,GAME.sh-y,p,c)
				else
					g2.new_planet(o,x,y,p,c)
					if not GAME.symmetric then
						x,y,p,c=math.random(0,GAME.sw),math.random(0,GAME.sh),math.random(GAME.prodmin,GAME.prodmax),math.random(GAME.costmin,GAME.costmax)
					end
					g2.new_planet(o,GAME.sw-x,GAME.sh-y,p,c)
				end
			end
		elseif #users>0 then
			local a=math.random(1,360)
			if GAME.map=='Hex'then
				g2.new_planet(o,X/2,Y/2,100,0)
				for i=1,10 do
					local r=24/math.sin(math.pi/(i*6))
					for n=1,i*6 do
						local a=n*60/i
						local x,y=X/2+r*math.cos(a*math.pi/180),Y/2+r*math.sin(a*math.pi/180)
						local p=g2.new_planet(o,x,y,100,0)
					end
				end
			end
			for i=1,math.ceil(GAME.neutrals/homes)do
				local x,y,p,c=math.random(0,X),math.random(0,Y),math.random(GAME.prodmin,GAME.prodmax),math.random(GAME.costmin,GAME.costmax)
				if GAME.map=='Circle'then
					x,y=X,Y
				elseif GAME.map=='2Circle'then
					if math.random(1,2)==1 then
						x,y=X,Y
					else
						x,y=X/2,Y/2
					end
				end
				if GAME.map=='Rings'then
					for _=1,#ulist do
						local cx,cy=X/2+(X/2*_/homes)*math.cos(a*math.pi/180),Y/2+(Y/2*_/homes)*math.sin(a*math.pi/180)
						if GAME.mode=="Frenzy"then
							g2.new_planet(ulist[_],cx,cy,p,c)
						else
							g2.new_planet(o,cx,cy,p,c)
						end
					end
					a=a+360/math.ceil(GAME.neutrals/homes)
				elseif GAME.map=='Hex'then
				else
					local a=math.random(1,360)
					for _=1,#ulist do
						local fx,fy=X/2+(x/2)*math.cos(a*math.pi/180),Y/2+(y/2)*math.sin(a*math.pi/180)
						if not GAME.symmetric then
							fx,fy=math.random(GAME.sw),math.random(GAME.sh)
						end
						if GAME.mode=="Frenzy"then
							g2.new_planet(ulist[_],fx,fy,p,c)
						else
							g2.new_planet(o,fx,fy,p,c)
						end
						if GAME.symmetric then
							a=a+360/homes
						else
							a=math.random(1,360)
						end
					end
				end
			end
		end
		for i,user in pairs(ulist)do
			local x,y=X/2+(X/2)*math.cos(a*math.pi/180),Y/2+(Y/2)*math.sin(a*math.pi/180)
			g2.new_planet(user,x,y,GAME.prod,GAME.ships)
			a=a+360/homes
		end
		if GAME.map=='Standard'then g2.planets_settle(0,0,X,Y)end
		g2.bounds_set(0,0,GAME.sw,GAME.sh)
		--[[local bspeed=50
		for _,v in pairs(g2.search("planet"))do
			v.has_physics=true
			v.has_motion=true
			v.motion_vx=(math.random()-.5)*bspeed*2
			math.randomseed(os.time()*math.random())
			v.motion_vy=(math.random()-.5)*bspeed*2
			math.randomseed(os.time()*math.random())
		end]]local bspeed=50
		for _,v in pairs(g2.search("planet"))do
			v.has_physics=true
			v.has_motion=true
			v.motion_vx=0
			v.motion_vy=0
		end
    elseif GAME.mode=="Eliminator"then
		local U={}
		for i,user in pairs(users)do
			U[#U+1]=user
		end
		for i=1,#U,2 do
			local p1,p2=U[i],U[i+1]
			for i=1,GAME.neutrals/2 do
				local x,y,p,c=math.random(GAME.sw*(i-1),GAME.sw*i),math.random(0,GAME.sh),math.random(GAME.prodmin,GAME.prodmax),math.random(GAME.costmin,GAME.costmax)
				g2.new_planet(o,x,y,p,c)
				if not GAME.symmetric then
					x,y,p,c=math.random(GAME.sw*(i-1),GAME.sw*i),math.random(0,GAME.sh),math.random(GAME.prodmin,GAME.prodmax),math.random(GAME.costmin,GAME.costmax)
				end
				g2.new_planet(o,GAME.sw*i-x,GAME.sh-y,p,c)
			end
			local x,y=math.random(GAME.sw*(i-1),GAME.sw*i),math.random(0,GAME.sh)
			g2.new_planet(U[i],x,y,GAME.prod,GAME.ships)
			g2.new_planet(U[i+1],GAME.sw*(i-1)-x,GAME.sh-y,GAME.prod,GAME.ships)
		end
	end
	if not GAME.physics then
		for _,v in pairs(g2.search("planet"))do
			v.has_collide=false
		end
	end
    g2.net_send("","sound","sfx-start");
end

function count_production()
    local r = {}
    local items = g2.search("planet -neutral")
    for _i,o in ipairs(items) do
        local team = o:owner():team()
        r[team] = (r[team] or 0) + o.ships_production
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

function count_ships()
	local r={}
	local items=g2.search("planet -neutral")
	for _i,o in ipairs(items)do
		local team=o:owner()
		r[team]=(r[team]or 0)+o.ships_value
	end
	local items=g2.search("fleet")
	for _i,o in ipairs(items)do
		local team=o:owner()
		r[team]=(r[team]or 0)+o.fleet_ships
	end
	return r
end

function most_ships()
	local r=count_ships()
	local best_o=nil
	local best_v=0
	for o,v in pairs(r)do
		if v>best_v then
			best_v=v
			best_o=o
		end
	end
	return best_o,best_v
end

function galcon_stop(res)
    if res then
        local o=most_production()
		local name=''
		GAME.won={}
		if GAME.numteams==0 then
			name=o and(GAME.clients[o.user_uid]or{name=o.title_value or'Nobody'}).name or'Nobody'
			GAME.wins[name]=(GAME.wins[name]or 0)+1
			GAME.winslocal[name]=(GAME.winslocal[name]or 0)+1
			GAME.won[name]=true
		else
			local t={}
			for _,v in pairs(GAME.galcon.users)do
				if v:team()==o then
					local name=v.title_value
					GAME.won[name]=true
					t[#t+1]=name
					GAME.wins[name]=(GAME.wins[name]or 0)+1
					GAME.winslocal[name]=(GAME.winslocal[name]or 0)+1
				end
			end
			if #t==1 then
				name=t[1]
			elseif #t==2 then
				name=table.concat(t," and ")
			elseif #t==3 then
				name=t[1]..", "..t[2].." and "..t[3]
			elseif #t>3 then
				for i=1,#t-2 do
					name=name..t[i]..", "
				end
				name=name..t[#t-1].." and "..t[#t]
			else
				name="Nobody"
			end
		end
		local troll={"DESTROYED","DELETED","OBLITERATED","OWNED","RUINED","SCHOOLED","TOASTED","WAFFLE3Z'D","WHIPPED"}
        net_send("","message",name.." "..troll[math.random(1,#troll)].." the galaxy!")
		for _,v in pairs(GAME.galcon.users)do
			local n=v.title_value
			GAME.plays[n]=(GAME.plays[n]or 0)+1
		end
		GAME.data.wins=GAME.wins
		GAME.data.winslocal=GAME.winslocal
		GAME.data.plays=GAME.plays
		g2.data=json.encode(GAME.data)
		
		-- Randomize client order for random teams
		for i,v in ipairs(clientorder)do
			local n=math.random(i,#clientorder)
			clientorder[i]=clientorder[n]
			clientorder[n]=v
		end
	end
    g2.net_send("","sound","sfx-stop");
end

GAME.frame=0
local dt={}
function task(t,f)
	dt[f]=GAME.frame+t
end

function itemget(n)
	if not tonumber(tostring(n))then return end
	return find("planet OR fleet",function(x)if tonumber(tostring(x.n))==tonumber(tostring(n))then return 1 end end)
end

local function revolt()
	local op,ships=most_ships()
	if not op then return end
	local total=0
	local living={}
	for _,v in pairs(g2.search("-neutral -owner:"..op))do
		total=total+v.ships_value+v.fleet_ships
		local o=v:owner()
		living[o]=(living[o]or 0)+1
	end
	local alive=0
	for _,v in pairs(living)do
		alive=alive+1
	end
	local avg=total/alive
	local alive2=0
	for _,v in pairs(living)do
		if v>avg/2 then
			alive2=alive2+1
		end
	end
	avg=total/math.max(alive2,2)
	local stuff=g2.search("owner:"..op)
	local best,closest={},math.huge
	local lships=0
	for i=1,1024 do
		local set={}
		local count=0
		for _,v in pairs(stuff)do
			local q=v.ships_value+v.fleet_ships
			if math.random(1,2)==1 and ships-(count+q)>=avg then
				set[#set+1]=v
				count=count+v.ships_value+v.fleet_ships
			end
		end
		local offset=math.abs(count-avg)
		if closest>offset then
			best,closest=set,math.abs(count-avg)
			lships=count
		end
	end
	if #best>0 then
		for _,v in pairs(best)do
			if v.has_fleet then
				v:destroy()
			else
				v:planet_chown(GAME.galcon.neutral)
			end
		end
		message(op.title_value.."'s ships revolted! -"..math.ceil(lships))
		return 1
	end
	return 0
end

GAME.connect={}
GAME.tunnel={}
GAME.autostart=false
local endstart=0
GAME.over=false
local peaceinit=0
local shipinit=0
local prodinit=0
local rcheck=0
function galcon_classic_loop()
	if GAME.powers then
		if GAME.physics then
			for _,v in pairs(g2.search("planet neutral"))do
				v.has_collide=true
			end
		end
		for _,user in pairs(g2.search("user"))do
			if not user.user_neutral then
				local client;
				for _,v in pairs(GAME.clients)do
					if tostring(v.uid)==tostring(user.user_uid)then
						client=v
					end
				end
				if client then
					if GAME.physics then
						if client.planet=='Gaseous'then
							for _,v in pairs(g2.search("planet owner:"..user))do v.has_collide=false end
						else
							for _,v in pairs(g2.search("planet owner:"..user))do v.has_collide=true end
						end
					end
					if client.planet=='Terrestrial'then
						for _,v in pairs(g2.search("planet owner:"..user))do
							v.ships_production=(v.planet_r)*17/3-36+(math.max(0,v.ships_value)*math.log(10)/math.log(math.max(math.exp(1),v.ships_value)))
						end
					end
				end
			end
		end
	end
	if GAME.revolts and os.clock()-rcheck>1 then
		rcheck=os.clock()
		--[[local scount=0
		for _,v in pairs(g2.search("-neutral"))do
			scount=scount+v.ships_value+v.fleet_ships
		end
		local pcount=0
		for _,v in pairs(g2.search("planet -neutral"))do
			pcount=pcount+v.ships_production
		end]]
		local revolttime=GAME.initial+(GAME.revoltnum)*60
		if GAME.revolts and os.clock()>revolttime then
			GAME.revoltnum=GAME.revoltnum+revolt()
		end
	end
	if GAME.mode=="Danger"then
		if os.clock()-GAME.initial>GAME.danger.delay+GAME.danger.tick*GAME.danger.interval then
			GAME.danger.tick=GAME.danger.tick+1
			local f=find("planet",function(f)return f.ships_value end)
			if f then
				f:destroy()
			end
		end
	end
	if GAME.line then
		for _,f in pairs(g2.search("fleet"))do
			if f.fleet_crash~=1 then
				f.fleet_crash=1
				local owner=f:owner()
				local n=find("planet owner:"..owner,function(x)return -f:distance(x)end)
				local d=f.fleet_target
				for _,v in pairs(g2.search("planet"))do
					if v.n==d then
						d=v
						break
					end
				end
				if n and d and n~=d then
					local c=GAME.connect[n]
					if not c or c[1]~=d or c[2]~=owner then
						if c then
							c[3]:destroy()
						end
						local color=owner.render_color
						local offx=d.planet_r/(d.position_x-n.position_x)
						local offy=d.planet_r/(d.position_y-n.position_y)
						local uy=d.position_y-n.position_y
						local ux=d.position_x-n.position_x
						local um=math.max(math.abs(ux),math.abs(uy))
						uy=uy/um
						ux=ux/um
						local l=g2.new_line(color,n.position_x+(n.planet_r-3)*ux,n.position_y+(n.planet_r-3)*uy,d.position_x-ux*(d.planet_r-3),d.position_y-uy*(d.planet_r-3))
						GAME.connect[n]={d,owner,l,math.max(1,n.ships_value)}
					end
				end
			end
		end
		for _,v in pairs(GAME.connect)do
			if _.owner and _:owner()==v[2]then
				if math.floor(_.ships_value)>v[4]then
					_:fleet_send(math.max(1,100*(_.ships_value-v[4])/_.ships_value),v[1])
				end
			else
				GAME.connect[_]=nil
				if v[3]then
					v[3]:destroy()
				end
			end
		end
	end
	if not GAME.teleport and(GAME.tunnelmode or GAME.tunnelP or GAME.powers)then
		if not GAME.closestplanets then
			local t={}
			local planets=g2.search("planet")
			for _,x in pairs(planets)do
				t[x]={}
				for _,y in pairs(planets)do t[x][#t[x]+1]=y end
				table.sort(t[x],function(a,b)return a:distance(x)<b:distance(x)end)
			end
			GAME.closestplanets=t
		end
		local S={}
		if GAME.tunnelP and not GAME.tunnelmode then
			for _,v in pairs(GAME.clients)do
				if v.name=="esparano"then
					local u=find_user(_)
					if u then S=g2.search("fleet owner:"..u)end
				end
			end
		elseif GAME.powers then
			for _,v in pairs(GAME.clients)do
				if v.planet=="Honeycomb"then
					local u=find_user(_)
					if u then
						for _,v in pairs(g2.search("fleet owner:"..u))do
							S[#S+1]=v
						end
					end
				end
			end
		else
			S=g2.search("fleet")
		end
		for _,f in pairs(S)do
			if f.fleet_crash~=1 then
				local t=f.fleet_target
				find("planet",function(q)if q.n==t then t=q end end)
				local user=find_user(f:owner().user_uid)
				local S="planet owner:"..user
				if GAME.tunnelmode=="plow"then
					S="planet"
				end
				local p=find(S,function(p)
					local ft,pt,fp=f:distance(t),p:distance(t),f:distance(p)
					if p~=f and pt<ft and(pt+fp-p.planet_r*2)<ft then return-fp end
				end)
				f.fleet_crash=1
				if p then
					f:fleet_redirect(p)
					--[[local new=g2.new_fleet(f:owner(),f.fleet_ships,f,p)
					f:destroy()
					f=new]]
					f.fleet_crash=1
					local chain={p}
					repeat
						local U=find_user(f:owner().user_uid)
						local f=chain[#chain]
						if f==t then break end
						local targ;
						if GAME.closestplanets and GAME.closestplanets[f]then
							for _,p in pairs(GAME.closestplanets[f])do
								pcall(function()
									if p:owner()==U then
										local ft,pt,fp=f:distance(t),p:distance(t),f:distance(p)
										if p~=f and pt<ft and(pt+fp-p.planet_r*2)<ft then
											targ=p
										end
									end
								end)
							end
						end
						chain[#chain+1]=targ or find("planet owner:"..U,function(p)
							local ft,pt,fp=f:distance(t),p:distance(t),f:distance(p)
							if p~=f and pt<ft and(pt+fp-p.planet_r*2)<ft then return-fp end
						end)or t
					until chain[#chain]==t
					for i=1,#chain-1 do
						if f and p then
							GAME.tunnel[#GAME.tunnel+1]={chain[i],chain[i+1],f.fleet_ships,f:owner(),p:owner()}
						end
					end
				end
			end
		end
		for _=1,#GAME.tunnel do
			local v=GAME.tunnel[_]
			if not v then break end
			if not itemget(v[1])or not itemget(v[2])or not v[4]or not v[5]then
				local t={}
				for i=1,#GAME.tunnel do
					if i~=_ then
						t[#t+1]=GAME.tunnel[i]
					end
				end
				if #GAME.tunnel>0 then
					GAME.tunnel=t
				else
					break
				end
			elseif v[4]==v[1]:owner()then
				local f,t,l=v[1],v[2],v[3]
				local a=math.min(f.ships_value,l)
				if f.ships_value>1 then
					v[3]=v[3]-a
					f:fleet_send(100*a/f.ships_value,t)
					if v[3]<=0 then
						local t={}
						for i=1,#GAME.tunnel do
							if i~=_ then
								t[#t+1]=GAME.tunnel[i]
							end
						end
						if #GAME.tunnel>0 then
							GAME.tunnel=t
						else
							break
						end
					end
				end
			elseif v[5]~=v[1]:owner()and v[5]~=v[2]:owner()then
				local t={}
				for i=1,#GAME.tunnel do
					if i~=_ then
						t[#t+1]=GAME.tunnel[i]
					end
				end
				if #GAME.tunnel>0 then
					GAME.tunnel=t
				else
					break
				end
			end
			local inbound={}
			local question={}
			for i=1,#GAME.tunnel do
				local x=GAME.tunnel[i]
				question[i]={x[1],x[2],x[3],i}
			end
			local k=true
			local C=0
			repeat
				C=C+1
				k=true
				local t={}
				for i=1,#question do
					local n=true
					for j=1,#question do
						if i~=j and question[j][2]==question[i][1]then
							n=false
							break
						end
					end
					if n then
						local x=0
						local p=question[i][1]
						for _,v in pairs(g2.search("fleet owner:"..p:owner().." target:"..p))do
							x=x+v.fleet_ships
						end
						for _,v in pairs(inbound)do
							if v[1]==p then
								x=x+v[2]
							end
						end
						inbound[#inbound+1]={question[i][2],x}
						local a=GAME.tunnel[question[i][4]]
						a[3]=math.min(a[3],x)
					else
						t[#t+1]=question[i]
						k=false
					end
				end
				question=t
			until k or C>10
		end
	end

	GAME.frame=GAME.frame+1
	for _,v in pairs(dt)do
		if GAME.frame<=v then
			_()
		else
			dt[_]=nil
		end
	end
	for _,v in pairs(GAME.botlinks)do
		if v.run then
			v.run:loop()
		end
	end
	if GAME.enemyrun then
		GAME.enemyrun:loop()
	end
	if GAME.teleport then
		for _,v in pairs(g2.search("fleet"))do
			local t=v.fleet_target
			for _,x in pairs(g2.search("planet"))do
				if x.n==t then
					t=x
					break
				end
			end
			if t:owner():team()~=v:owner():team()then
				if v.fleet_ships>t.ships_value then
					t.ships_value=v.fleet_ships-t.ships_value
					t:planet_chown(v:owner())
				else
					t.ships_value=t.ships_value-v.fleet_ships
				end
			else
				t.ships_value=t.ships_value+v.fleet_ships
			end
			v:destroy()
		end
	end
	-------------------------------------
    local G = GAME.galcon
    local r = count_production()
    local total = 0
    for k,v in pairs(r)do total=total+1 end
    if #G.users<=1 and total==0 then
		if endstart==0 then endstart=os.clock()end
		if os.clock()-endstart>3 then
			galcon_stop(false)
			GAME.over=true
		end
    elseif not GAME.over and((#G.users>1 and #G.teams~=1)or GAME.numteams==1)and total<=1 then
		if endstart==0 then endstart=os.clock()end
		if os.clock()-endstart>3 then
			galcon_stop(true)
			GAME.over=true
		end
	elseif not GAME.over and(#G.users==1 or(#G.teams==1 and GAME.numteams~=1))and #g2.search("planet neutral")==0 then
		if endstart==0 then endstart=os.clock()end
		if os.clock()-endstart>3 then
			galcon_stop(true)
			GAME.over=true
		end
	elseif not GAME.over and endstart~=0 and os.clock()-endstart<5 then
		endstart=0
    end
	if GAME.over and os.clock()-endstart>5 then
		endstart=0
		for _,v in pairs(GAME.botlinks)do
			v.run=nil
		end
		if GAME.autostart then
			GAME.engine:next(GAME.modules.galcon)
		else
			GAME.engine:next(GAME.modules.lobby)
			updateHTML()
		end
	end
end

function find_user(uid)
    for n,e in pairs(g2.search("user")) do
        if tostring(e.user_uid) == tostring(uid) then return e end
    end
end
function galcon_surrender(uid)
    local G = GAME.galcon
    local user = find_user(uid)
    if user == nil then return end
	local s=g2.search("planet -owner:"..user.." team:"..user:team())
	if #s>0 then
		for n,e in pairs(g2.search("planet owner:"..user)) do
			e:planet_chown(s[math.random(1,#s)]:owner())
		end
	else
		local count=0
		for n,e in pairs(g2.search("planet owner:"..user)) do
			e:planet_chown(G.neutral)
			count=count+1
		end
		if count==0 then
			for n,e in pairs(g2.search("fleet owner:"..user)) do
				e:destroy()
			end
		end
	end
end

function galcon_init()
	GAME.tunnel={}
	GAME.closestplanets=nil
    GAME.modules.galcon=GAME.modules.galcon or{}
    GAME.galcon=GAME.galcon or{}
    local obj=GAME.modules.galcon
	obj.t=obj.t or 0
    function obj:init()
        g2.state = "play"
        params_set("state","play")
        galcon_classic_init()
    end
    function obj:loop(t)
		galcon_classic_loop()
		obj.t=obj.t+1
		if obj.t==20 then
			obj.t=0
			for _,v in pairs(GAME.clients)do
				HTML(v)
			end
		end
    end
    function obj:event(e)
        if e.type == 'net:leave' then
            galcon_surrender(e.uid)
        end
    end
end
--------------------------------------------------------------------------------
function register_init()
    GAME.modules.register = GAME.modules.register or {}
    local obj = GAME.modules.register
    obj.t = 0
    function obj:loop(t)
        if GAME.module == GAME.modules.menu then return end
        self.t = self.t - t
        if self.t < 0 then
            self.t = 60
            g2_api_call("register",json.encode({title=GAME.title,port=GAME.data.port}))
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
        --[[if g2.headless then
            GAME.data = { port = g2.port }
            g2.net_host(GAME.data.port)
            GAME.engine:next(GAME.modules.lobby)
        else]]
            self:next(GAME.modules.menu)
        --end
    end
    
    function obj:event(e)
        GAME.modules.clients:event(e)
        GAME.modules.params:event(e)
        GAME.modules.chat:event(e)
        GAME.module:event(e)
        if e.type == 'onclick' then 
            GAME.modules.client:event(e)
        end
    end
    
    function obj:loop(t)
        GAME.module:loop(t)
        GAME.modules.register:loop(t)
    end
end
--------------------------------------------------------------------------------
function mod_init()
    global("GAME")
    GAME=GAME or{}
    engine_init()
    menu_init()
    clients_init()
    params_init()
    chat_init()
    lobby_init()
    galcon_init()
    register_init()
    if g2.headless == nil then
        client_init()
    end
	local b={}
	for _,v in pairs(GAME.clients)do
		if tonumber(v.uid)<0 then
			local B=v.name
			for x,y in pairs(GAME.bots)do
				if v.name:sub(1,#x)==x then
					B=x
				end
			end
			b[v.name]=B
			GAME.modules.clients:event({uid=_,name=v.name,type="net:leave"})
		end
	end
	for _,v in pairs(b)do
		GAME.addbot(v,_)
	end
end
--------------------------------------------------------------------------------
function init() GAME.engine:init() end
function loop(t) GAME.engine:loop(t) end
function event(e) GAME.engine:event(e) end
--------------------------------------------------------------------------------
function net_send(uid,mtype,mvalue) -- HACK - to make headed clients work
    if uid == "" or uid == g2.uid then
        GAME.modules.client:event({type="net:"..mtype,value=mvalue})
    end
	g2.net_send(uid,mtype,mvalue)
end
--------------------------------------------------------------------------------
mod_init()
GAME.data=json.decode(g2.data or{})
GAME.admins=GAME.data.admins or{esparano=1}
GAME.wins=GAME.data.wins or{}
GAME.winslocal=GAME.data.winslocal or{}
GAME.plays=GAME.data.plays or{}