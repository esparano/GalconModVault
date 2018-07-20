-- mod_api.lua is called after the sandbox is setup, but before setmetatable is removed
-- mod_api.lua (c) 2013 Phil Hassey, all rights reserved

function _g2_init()

-------------------------------------------------------------------------------
local setmetatable = setmetatable -- local to avoid sandbox

_g2_object_meta = {
    __concat = function(a,b)
        return tostring(a) .. tostring(b)
    end,

    __tostring = function(self)
        return tostring(self.n)
    end,

    __index = function(self,k)
        local v = _g2_object_meta[k]
        if v ~= nil then return v end
        return g2_item_get(self.n,k)
    end,
    
    __newindex = function(self,k,v)
        g2_item_set(self.n,k,v)
    end,
    
    __eq = function(a,b)
        return a.n == b.n
    end,
    
    owner = function(self)
        return _g2_object(self.owner_n)
    end,
        
    team = function(self)
        return _g2_object(self.user_team_n)
    end,
    
    distance = function(self,b)
        return _g2_distance(self,b)
    end,
    
    fleet_redirect = function(self,b)
        g2_fleet_redirect(self.n,b.n)
    end,
    
    fleet_send = function(self,perc,b)
        local n = g2_fleet_send(perc,self.n,b.n)
        return _g2_object(n)
    end,
    
    planet_chown = function(self,user)
        g2_planet_chown(self.n,user.n)
    end,
    
    destroy = function(self)
        g2_item_destroy(self.n)
    end,

    sync = function(self)
        g2_item_sync(self.n)
    end,

    selected = function(self)
        return g2_item_selected(self.n)
    end,

}

_g2_object_cache = {}

function _g2_object(n)
    local o = _g2_object_cache[n]
    if o == nil then
        o = {n=n}
        setmetatable(o,_g2_object_meta)
        _g2_object_cache[n] = o
    end
    return o
end
    
function _g2_new_team(name,color)
    local n = g2_team_init(name,color)
    return _g2_object(n)
end

    
function _g2_new_user(name,color,team)
    if team ~= nil then team = team.n end
    local n = g2_user_init(name,color,team)
    return _g2_object(n)
end

    
    
function _g2_new_planet(user,x,y,production,ships)
    local n = g2_planet_init(user.n,x,y,production,ships)
    return _g2_object(n)
end
    
    
function _g2_new_fleet(user,ships,from,to)
    local n = g2_fleet_init(user.n,ships,from.n,to.n)
    return _g2_object(n)
end
function _g2_new_label(text,x,y,color)
    local o = _g2_object(g2_item_init())
    o.has_label = true
    o.label_text = text
    o.label_font = "font"
    o.label_size = 20
    o.has_position = true
    o.position_x = x
    o.position_y = y
    if color == nil then color = 0xffffff end
    o.render_color = color
    o.render_alpha = 255
    o.render_blend = 0
    return o
end
function _g2_new_image(src,x,y,w,h)
    local o = _g2_object(g2_item_init())
    o.has_position = true
    o.position_x = x
    o.position_y = y
    o.has_image = true
    o.image_src = src
    o.image_w = w
    o.image_h = h
    o.image_cx = 0
    o.image_cy = 0
    o.image_scale = 1
    o.render_color = 0xffffff
    o.render_alpha = 255
    o.render_blend = 0
    return o
end
function _g2_new_part(src,d,x,y,r,q,a,vx,vy,vr,vq,va)
    return g2_part_init(src,d,x,y,r,q,a,vx,vy,vr,vq,va)
end
    
function _g2_new_circle(color,x,y,r)
    local o = _g2_object(g2_item_init())
    o.has_position = true
    o.position_x = x
    o.position_y = y
    o.has_draw = true
    o.draw_type = "C"
    o.draw_r = r
    o.render_color = color
    o.render_alpha = 255
    o.render_blend = 1
    return o
end
function _g2_new_line(color,x,y,x2,y2)
    local o = _g2_object(g2_item_init())
    o.has_position = true
    o.position_x = x
    o.position_y = y
    o.has_draw = true
    o.draw_type = "L"
    o.draw_x2 = x2
    o.draw_y2 = y2
    o.render_color = color
    o.render_alpha = 255
    o.render_blend = 1
    return o
end

function _g2_new_triangle(color,x,y,x2,y2,x3,y3)
    local o = _g2_object(g2_item_init())
    o.has_position = true
    o.position_x = x
    o.position_y = y
    o.has_draw = true
    o.draw_type = "T"
    o.draw_x2 = x2
    o.draw_y2 = y2
    o.draw_x3 = x3
    o.draw_y3 = y3
    o.render_color = color
    o.render_alpha = 255
    o.render_blend = 1
    return o
end

function _g2_items_find(value)
    local r = g2_items_find(value)
    for n,v in ipairs(r) do
        r[n] = _g2_object(v)
    end
    return r
end

function _g2_distance(a,b)
    local dx = b.position_x - a.position_x
    local dy = b.position_y - a.position_y
    return math.sqrt(dx*dx+dy*dy)
end

_g2_module_meta = {
    __index = function(self,k)
        return g2_param_get(k)
    end,
    
    __newindex = function(self,k,v)
        if type(v) == "table" then
            v = v.n
        end
        g2_param_set(k,v)
    end,
}

_g2_form_meta = {
    __index = function(self,k)
        return g2_gui_get(k)
    end,
    
    __newindex = function(self,k,v)
        g2_gui_set(k,v)
    end,
}
_g2_form = {}
setmetatable(_g2_form,_g2_form_meta)

    
-- _g2_client_meta = {
--     __index = function(self,k)
--         return g2_lobby_get(self.uid,k)
--     end,
--     
--     __newindex = function(self,k,v)
--         g2_lobby_set(self.uid,k,v)
--     end,
-- }
-- 
-- function _g2_client(uid)
--     local o = {uid=uid}
--     setmetatable(o,_g2_client_meta)
--     return o
-- end
    
function _g2_net_send(uid, _type, value)
    if type(uid) == "table" then
        uid = uid.uid
    end
    g2_net_send(uid,_type,value)
end

g2 = {
    game_reset = g2_game_reset,
    planets_settle = g2_planets_settle,
    play_sound = g2_play_sound,
    play_music = g2_play_music,
--     db_query = g2_db_query,
    view_set = g2_view_set,
    clip_set = g2_clip_set,
    bounds_set = g2_bounds_set,
    new_user = _g2_new_user,
    new_planet = _g2_new_planet,
    new_fleet = _g2_new_fleet,
    new_label = _g2_new_label,
    new_circle = _g2_new_circle,
    new_line = _g2_new_line,
    new_triangle = _g2_new_triangle,
    new_team = _g2_new_team,
    new_image = _g2_new_image,
    new_part = _g2_new_part,
    item = _g2_object,
    search = _g2_items_find,
    distance = _g2_distance,
    form = _g2_form,
    net_host = g2_net_host,
    net_join = g2_net_join,
    net_send = _g2_net_send,
    chat_append = g2_chat_append,
    chat_keywords = g2_chat_keywords,
--     client = _g2_client,
--     server = _g2_client("$"),
}    
setmetatable(g2,_g2_module_meta)

return g2
-------------------------------------------------------------------------------

end

g2 = _g2_init()
_g2_init = nil

function _init()
    init()
end

function _loop(t)
    loop(t)
end

function _event(e)
--     if e.uid ~= nil then
--         e.client = g2.client(e.uid)
--     end
    event(e)
end
