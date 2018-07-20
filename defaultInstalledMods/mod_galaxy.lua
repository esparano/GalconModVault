-- mod_galaxy.lua (c) 2013 Phil Hassey - All Rights Reserved.

DB = "galaxy"

function g2Xdb_query(db,mode,ver,q)

    if q == "select * from stars" then
        return {
        {id=1,x=100.0,y=200.0,name="Cuzco",gtype="FFA",label_y=1,consts_id=1},
{id=2,x=0.0,y=0.0,name="Nibbles",gtype="SP",label_y=-1,consts_id=1},
{id=3,x=200.0,y=0.0,name="Lilly",gtype="COOP",label_y=-1,consts_id=1},
}
    end
    
    if q == "select * from lines" then
        return {
        {id=1,p1=1,p2=2},
{id=2,p1=2,p2=3},
{id=3,p1=3,p2=1},
        }
    end
    
    if q == "select * from consts" then
        return {
        {id=1,name="Goatorama",x=100.0,y=75.0},
    }
    end
end


function init()
    g2.game_reset();
    g2.bkgr_src = "background05"

    --g2.db_query(DB,"rw",1,"create table stars (id integer primary key, x float, y float, name text, gtype text)")
    --g2.db_query(DB,"rw",2,"create table lines (id integer primary key,p1 int, p2 int)")
    --g2.db_query(DB,"rw",3,"alter table stars add label_y int default 1")
    --g2.db_query(DB,"rw",6,"create table consts (id integer primary key, name text)")
    --g2.db_query(DB,"rw",7,"alter table consts add x float")
    --g2.db_query(DB,"rw",8,"alter table consts add y float")
    --g2.db_query(DB,"rw",9,"alter table stars add consts_id int")

    OBJS = {}

    _STARS = g2Xdb_query(DB,"r",0,"select * from stars")
    for n,e in pairs(_STARS) do
        local z = 10
        e.image = g2.new_image("star",e.x-z/2,e.y-z/2,z,z)
        e.image.render_blend = 1
        e.label = g2.new_label(e.name ,e.x,e.y+z * e.label_y,0xaaaaaa)
        e.label.label_size = 10

        z = 80
        local b = g2.new_image("blank",e.x-z/2,e.y-z/2,z,z)
        b.has_button = true
        b.button_name = "s" .. e.id
        b.render_color = 0
        b.has_image = false
        e.b = b
        
        e.parent = "c" .. e.consts_id
        
        OBJS["s" .. e.id] = e
    end
    
    _LINES = g2Xdb_query(DB,"r",0,"select * from lines")
    for n,e in pairs(_LINES) do
        local p1 = OBJS["s"..e.p1]
        local p2 = OBJS["s"..e.p2]
        local line = g2.new_line(0x555555,p1.x,p1.y,p2.x,p2.y)
    end
    
    _CONSTS = g2Xdb_query(DB,"r",0,"select * from consts")
    for n,e in pairs(_CONSTS) do
        e.label = g2.new_label(e.name,e.x,e.y)
        e.label.has_button = true
        e.label.button_name = "c" .. e.id
        e.label.image_w = 300
        e.label.image_h = 300
        e.label.image_cx = 150
        e.label.image_cy = 150
        e.label.image_scale = 1.0
        e.label.image_src = "gui-button1"
        e.label.render_color = 0xffffff
        e.label.label_size = 20
        e.b = e.label
        e.parent = nil
        OBJS["c" .. e.id] = e
    end
    
    
    g2.state = "tabs"
    g2.tab = "play"
    g2.view_set(-1000,-1000,2000,2000)
    
--     g2.new_image("gui-button2",-200,-100,600,400)
--     img = g2.new_image("logo",100,100,400,200)
--     img.image_cx = 100
--     img.image_cy = 100
--     img.image_scale = 0.01


--    local l = g2.new_label("this is a demo",0,750)
--    l.label_size = 150
end

FOCUS = nil
VIEW = {-1000,-1000,2000,2000}
_VIEW = {-1000,-1000,2000,2000}

WIDGETS = {}
_WIDGETS = {}

function w_fade()
    for n,e in ipairs(WIDGETS) do
        _WIDGETS[#_WIDGETS + 1] = e
    end
    WIDGETS = {}
end

function w_add(e)
    WIDGETS[#WIDGETS+1] = e
    return e
end

function event(e)
    if e.type == 'ui:down' and e.value ~= "" then
--         print(e.type .. ":" .. e.value)
        
        if FOCUS ~= e.value then
            FOCUS = e.value
        else
            FOCUS = OBJS[FOCUS].parent
        end
--[[        print(FOCUS)]]

        w_fade()
        
        if FOCUS == nil then
            VIEW = { -1000,-1000,2000,2000}
            g2.html = "<p>&nbsp;</p>"
        else
            local o = OBJS[FOCUS].b
            local z = 1.0
            local zx = 1.0
            local zy = 1.0
            if FOCUS:sub(1,1) == "s" then 
                if g2.orient == 0 then
                    zx = 2.0
                else
                    zy = 2.0
                end
            end
            
            VIEW = { o.position_x - o.image_cx * o.image_scale , o.position_y - o.image_cy * o.image_scale, (o.image_w * o.image_scale) * zx, o.image_h * o.image_scale * zy}
            
--             if zy == 2.0 then
--                 VIEW[2] = o.position_y - o.image_cy * o.image_scale - o.image_h * o.image_scale
--             end
            
            g2.html = "<p>&nbsp;</p>"
            
            if FOCUS:sub(1,1) == "s" then
                local pad = 5
                local e = w_add(g2.new_image("galaxy_triangle",o.position_x - (o.image_cx* o.image_scale) + o.image_w* o.image_scale/2-30, o.position_y - (o.image_cy* o.image_scale) + o.image_h* o.image_scale/2-30, 60,60))
                e.render_alpha = 0
                e.render_blend = 1
                
                
                local fs = 5
                local l
                local z = 6
                local iz = 5
                local zz = 6

                local x = VIEW[1] + 40
                local y = VIEW[2] + VIEW[4]-10 
                l=w_add(g2.new_label("Co-op Classic",e.position_x+e.image_w/2,e.position_y+e.image_h - 10 ))
                l.label_size = fs; l.label_align = 0; l.label_valign = 0
                l.render_alpha = 0
                
                local LHTML = "<table class=box>"
                LHTML = LHTML .. "<tr><td><img src='blank' width=22 height=1><td><img src='blank' width=98 height=1><td><img src='blank' width=22 height=1><td><img src='blank' width=98 height=1>"
                LHTML = LHTML .. "<tr><td><img src='rank5' width=Z height=Z><td align=left><p>&nbsp;nanno</p><td><img src='rank5' width=Z height=Z><td align=left><p>&nbsp;PonyClan</p>"
                LHTML = LHTML .. "<tr><td><img src='rank3' width=Z height=Z><td align=left><p>&nbsp;philhassey</p><td><img src='rank4' width=Z height=Z><td align=left><p>&nbsp;DevClan</p>"
                LHTML = LHTML .. "</table>"
                
                local IHTML = "<table class=box>"
                IHTML = IHTML .. "<tr><td><img src='blank' width=22 height=1><td><img src='blank' width=98 height=1><td><img src='blank' width=22 height=1><td><img src='blank' width=98 height=1>"
                IHTML = IHTML .. "<tr><td><img src='rank8' width=Z height=Z><td align=left><p>&nbsp;Wiljafjord</p><td><img src='rank4' width=Z height=Z><td align=left><p>&nbsp;Cuzco</p>"
                IHTML = IHTML .. "<tr><td><img src='rank9' width=Z height=Z><td align=left><p>&nbsp;Grandma</p><td><img src='rank3' width=Z height=Z><td align=left><p>&nbsp;Bozo</p>"
                IHTML = IHTML .. "</table>"   
                
                LHTML = string.gsub(LHTML,"Z",22)
                IHTML = string.gsub(IHTML,"Z",22)
                
    g2.html = "<table align=right width=320 >"
    
    if g2.orient == 1 then
        g2.html = "<table align=right valign=bottom width=320 >"
    end
    
    g2.html = g2.html .. "<tr><td align=center><table>"..
    "<tr><td><p>Leaderboard:</p>"..
    "<tr><td>"..LHTML..
    "<tr><td><p>&nbsp;</p>"..
    "<tr><td><p>In-Game:</p>"..
    "<tr><td>"..IHTML..
    "<tr><td><p>&nbsp;</p>"..
    "<tr><td><input type='button' value='Join Game! (not yet)' onclick='join' />"..
    "</table></table>"..
    "";                

      
            end
            
        end
    end

end

function loop(t)
--     img.image_a = img.image_a + 1.0 * t
--     img.image_scale = img.image_scale + 0.01 * 60 * t

    local j = 5
    local k = 1
    
    _VIEW[1] = (_VIEW[1] * j + VIEW[1] * k) / (j+k)
    _VIEW[2] = (_VIEW[2] * j + VIEW[2] * k) / (j+k)
    _VIEW[3] = (_VIEW[3] * j + VIEW[3] * k) / (j+k)
    _VIEW[4] = (_VIEW[4] * j + VIEW[4] * k) / (j+k)
   
    g2.view_set(_VIEW[1],_VIEW[2],_VIEW[3],_VIEW[4])
    
    for n,e in ipairs(WIDGETS) do
        local a = e.render_alpha + 0x10
        if a > 255 then a = 255 end
        e.render_alpha = a
    end

    local w2 = {}
    
    for n,e in ipairs(_WIDGETS) do
        local a = e.render_alpha - 0x10
        if a < 0 then a = 0 end
        e.render_alpha = a
        if a == 0 then
            e:destroy()
        else
            w2[#w2+1] = e
        end
    end
    
    _WIDGETS = w2
    

end

