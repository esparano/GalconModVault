LICENSE = [[
mod_client.lua

Copyright (c) 2013 Phil Hassey
Modifed by: YOUR_NAME_HERE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Galcon is a registered trademark of Phil Hassey
For more information see http://www.galcon.com/
]]
--------------------------------------------------------------------------------
strict(true)
--------------------------------------------------------------------------------
function menu_init()
    GAME.modules.menu = GAME.modules.menu or {}
    local obj = GAME.modules.menu
    function obj:init()
        g2.html = [[
            <table>
            <tr><td colspan=2><h1>Galcon 2 Client</h1>
            <tr><td><p>&nbsp;</p>
            <tr><td><input type='text' name='host' value='$HOST' />
            <tr><td><input type='text' name='port' value='$PORT' />
            <tr><td><p>&nbsp;</p>
            <tr><td><input type='button' value='Join Server' onclick='join' />"
            </table>
            ]]
        GAME.data = json.decode(g2.data)
        if type(GAME.data) ~= "table" then GAME.data = {} end
        g2.form.host = GAME.data.host or "127.0.0.1"
        g2.form.port = GAME.data.port or "23099"
        g2.state = "menu"
    end
    function obj:loop(t) end
    function obj:event(e)
        if e.type == 'onclick' and e.value == 'join' then
            GAME.data.host = g2.form.host
            GAME.data.port = g2.form.port
            g2.data = json.encode(GAME.data)
            g2.html = [[
                <table>
                <tr><td><p>Connecting ...</p>
                <tr><td><p>&nbsp;</p>
                <tr><td><input type='button' value='Cancel' onclick='cancel' />"
                </table>
                ]]
            g2.net_join(GAME.data.host,GAME.data.port)
        end
        if e.type == 'onclick' and e.value == 'cancel' then
            obj:init()
        end
        if e.type == 'net:disconnect' then
            obj:init()
        end
        if e.type == 'net:connect' then
            GAME.engine:next(GAME.modules.client)
        end
    end
end
--------------------------------------------------------------------------------
function client_init()
    GAME.modules.client = GAME.modules.client or {}
    local obj = GAME.modules.client
    function obj:init() end
    function obj:loop(t) end
    function obj:event(e)
--         print("client:"..e.type)
        if e.type == 'net:state' then
            g2.state = e.value
        end
        if e.type == 'net:html' then
            g2.html = e.value
        end
        if e.type == 'net:tabs' then
            g2.tabs = e.value
        end
        if e.type == 'net:chat' then
            local data = json.decode(e.value)
            if data.uid ~= g2.uid and data.value:find(g2.name) ~= nil then
                g2.play_sound("sfx-ping")
            end
            g2.chat_append(data.color,data.value)
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
        if e.type == 'net:message' then
            g2.chat_append(0x555555,e.value)
        end
        if e.type == 'onclick' and e.value == 'resume' then
            g2.state = "play"
        end
        if e.type == 'onclick' and e.value:sub(1,1) == '/' then 
            g2.net_send("","message",e.value) -- HACK: won't work from server
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
        self:next(GAME.modules.menu)
    end
    
    function obj:event(e)
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
    menu_init()
    client_init()
end
--------------------------------------------------------------------------------
function init() GAME.engine:init() end
function loop(t) GAME.engine:loop(t) end
function event(e) GAME.engine:event(e) end
--------------------------------------------------------------------------------
mod_init()