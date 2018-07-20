LICENSE = [[
Copyright (c) 2013 Phil Hassey - All rights reserved

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]

RELEASE = 0

strict(true)


function pass() end
--------------------------------------------------------------------------------

function client_init()
    GAME.modules.client = GAME.modules.client or {}
    local obj = GAME.modules.client

    function obj:init()
        GAME.state = "menu"
        GAME.error = false
        GAME.ihtml = "<p>ihtml</p>"
    end

    function obj:loop(t)
        local chat_enabled = tostring(g2.chat_enabled)
        if chat_enabled ~= GAME.chat_enabled then
            GAME.chat_enabled = chat_enabled
            g2.net_send(g2.server,'chat:enabled',GAME.chat_enabled)
        end
    end

    -- str_split doesn't really work "a,,c" => {'a','c'} instead of {'a','','c'}
    function str_split(value,delim)
        local r = {}
        for token in value:gmatch("[^"..delim.."]+") do
            r[#r+1] = token
        end
        return r
    end

    function do_connect_prep()
        if GAME.error then return end
        GAME.chat_enabled = nil
        g2.status = ''
        -- g2.tabs = ""
        g2.html = "" -- HACK: makes transition look smoother
        -- g2.state = "menu"
        -- g2.html = "<p>Connecting ...</p>"
        GAME.color = nil
    end
    
    function do_leave()
        if GAME.error then return end
        do_connect_prep()
        if GAME.galaxy then
            g2.state = 'quit'
            return
        end
        GAME.galaxy = true
		g2.net_join(GAME.host,GAME.port,GAME.token)
        g2.net_send('','opts',g2.gsize)  
        g2.net_send('','cookie',g2.data)
        g2.net_send('','session',GAME.session)
		g2.quit = false
	end
	
	function do_sub(value)
		return value:gsub("({$(%w+)})",function(_,k) return tostring(g2.form[k]) end )
	end
    
    function obj:event(e)
        if e.type == 'net:disconnect' then
            -- print('disconnect')
            do_leave()
        end

    	if e.type == 'quit' and g2.quit == true and g2.state ~= 'tabs' and g2.state ~= 'menu' then
    		do_leave()
    	end

        if e.type == 'back' and g2.state ~= 'lobby' and g2.state ~= 'pause' then
            g2.net_send('','stack:back','')
        end
        if e.type == 'back' and g2.state == 'pause' then
            g2.state = GAME.state
        end

        if e.type == 'message' and GAME.color then
            local v = e.value
            v = v:gsub("^%s*(.-)%s*$", "%1")
            v = v:gsub("^[.]","/")
            if #v == 0 then return end
            if true then -- #v > 1 then
                local c1 = v:sub(1,1):lower()
                local c2 = v:sub(2,2)
                local ok = true
                if c1 == '/' then ok = false end
                if c1 == 'm' and c2 == ' ' then ok = false end
                if c1 == 't' and c2 == ' ' then ok = false end
                if c1 == 'c' and c2 == ' ' then ok = false end
                if c1 == 'b' and c2 == ' ' then ok = false end
                if ok then
                    local msg = '<'..g2.name..'> '..v
                    g2.chat_append(GAME.color,msg)
                end
            end
            if v:sub(1,4) == "/me " then
                local msg = g2.name .. v:sub(4)
                g2.chat_append(GAME.color,msg)
            end
        end

        if e.type == 'net:color' then
            GAME.color = tonumber(e.value)
        end
     

        if e.type == 'net:state' then
            -- print('state:'..e.value)
            g2.state = e.value
            GAME.state = e.value
        end
    
        if e.type == 'net:chat' then
            local data = json.decode(e.value)
            if data.uid ~= g2.uid and data.value:lower():find(g2.name:lower()) ~= nil and GAME.chat_enabled == '1' then
                g2.play_sound("sfx-ping")
            end
            g2.chat_append(data.color,data.value,data.bgcolor or 0)
        end
        
        if e.type == 'net:keywords' then
            g2.chat_keywords(e.value)
        end
        
        if e.type == 'net:sound' then
            g2.play_sound(e.value)
        end
        
        if e.type == 'net:music' then
            g2.play_music(e.value)
        end

        if e.type == 'net:view' then
            local p = json.decode(e.value)
            g2.view_set(p[1],p[2],p[3],p[4])
        end
        
        if e.type == 'net:message' then
            g2.chat_append(0x555555,e.value)
        end
    
        if e.type == 'net:connect' then
        end

        if e.type == 'net:ext:rank' then
            g2_ext_call('galcon2:rank',e.value)
        end

        if (e.type == "onclick" or e.type == "onchange") and e.value ~= nil and e.value:find('join:') == 1 then
            -- print('value:'..e.value)
			local value = e.value:sub(6)
            local p = str_split(value,":")
            local host = p[1]
            local port = p[2]
            local token = p[3]
            local request = p[4]
            do_connect_prep()
            GAME.galaxy = false
            g2.net_join(host,port,token)
            g2.net_send('','opts',g2.gsize)  
            g2.net_send('','cookie',g2.data)
            g2.net_send('','session',GAME.session)
            -- print(#p)
            -- print(request)
            g2.net_send(g2.server,'request',request)  
        end

        if e.type == 'net:join' then
            local cmd = json.decode(e.value)
            local host = cmd.host
            local port = cmd.port
            local token = cmd.token
            local request = cmd.request
            do_connect_prep()
            GAME.galaxy = false
            g2.net_join(host,port,token)
            g2.net_send('','opts',g2.gsize)  
            g2.net_send('','cookie',g2.data)
            g2.net_send('','session',GAME.session)
            g2.net_send(g2.server,'request',request)  
        end

        -- lobby / play
        -- if e.type == "net:lobby" then
        --     if GAME.state ~= g2.server.state then
        --         GAME.state = g2.server.state
        --         g2.state = g2.server.state
        --     end
        -- end
        if e.type == "net:error" then
            GAME.error = true
            g2.state = "menu"
            g2.html = "<p>"..e.value.."</p>"
        end
        if e.type == "pause" then
            -- print('pause:pause')
			g2.state = "pause"
        end
        
        if e.type == 'net:html' then
            g2.html = e.value
        end
        if e.type == 'net:ihtml' then
            GAME.ihtml = e.value
        end
    	if e.type == 'net:status' then
    	    g2.status = e.value
    	end
        
        if e.type == 'net:tabs' then
            g2.tabs = e.value
        end

        -- pause
        if e.type == "onclick" and e.value == "resume" then
            -- print('resume',GAME.state)
            g2.state = GAME.state
        end
        if e.type == "onclick" and e.value == "leave" then
        	do_leave()
        end
        if e.type == "onclick" and e.value == "iap" then
            g2_ext_call("galcon2:iap","")
        end
        if e.type == 'suspend' then
            g2.net_send(g2.server,"suspend","")
        end
        if e.type == 'resume' then
            g2.net_send(g2.server,"resume","")
        end

        if e.type == "onclick" and (e.value:find('http:') == 1 or e.value:find('https:') == 1 ) then
            g2_ext_call("galcon2:open_url",e.value)
        end

        if (e.type == "onclick" or e.type == "onchange") and e.value ~= nil and e.value:sub(1,1) == "/" then
            g2.net_send(g2.server,"message",do_sub(e.value))
            -- print('onclick',GAME.state)
            g2.state = GAME.state
        end
        if (e.type == "onclick" or e.type == "onchange") and e.value ~= nil and e.value:sub(1,1) == "*" then
			local cmd = e.value:sub(2)
            local ihtml = false
            if cmd:sub(1,1) == "!" then
                ihtml = true
                cmd = cmd:sub(2)
            end
			local value = ''
			local sep = cmd:find("\t")
			if sep ~= nil then
				value = cmd:sub(sep+1)
				cmd = cmd:sub(1,sep-1)
			end
            local values = do_sub(value)
            if ihtml then
                g2.html = GAME.ihtml
            end
            g2.net_send(g2.server,cmd,values)
        end


        
    end
end

--------------------------------------------------------------------------------
function cookie_init()
    GAME.modules.cookie = GAME.modules.cookie or {}
    local obj = GAME.modules.cookie
    GAME.session = GAME.session or ''
    
    function obj:event(e)
        if e.type == "net:cookie:get" then
            g2.net_send("","cookie",g2.data)
        end
        if e.type == "net:cookie:set" then
            g2.data = e.value
        end
        if e.type == "net:session:get" then
            g2.net_send("","session",GAME.session)
        end
        if e.type == "net:session:set" then
            GAME.session = e.value
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
    	g2.tab = 'play'
    	GAME.host = g2.host
    	GAME.port = g2.port
        GAME.token = g2.token

        do_connect_prep()
        GAME.galaxy = true
        g2.net_join(GAME.host,GAME.port,GAME.token)
        g2.net_send('','opts',g2.gsize)  
        g2.net_send('','cookie',g2.data)
        g2.net_send('','session',GAME.session)
        self:next(GAME.modules.client)
    end
    
    function obj:event(e)
        if e.type == "net:module" then
            if GAME.modules[e.value] ~= nil and GAME.modules[e.value] ~= GAME.module then
                self:next(GAME.modules[e.value])
            end
        end
        GAME.modules.cookie:event(e)
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
    cookie_init()
    client_init()
end
--------------------------------------------------------------------------------
function init() GAME.engine:init() end
function loop(t) GAME.engine:loop(t) end
function event(e) GAME.engine:event(e) end
--------------------------------------------------------------------------------
mod_init()
