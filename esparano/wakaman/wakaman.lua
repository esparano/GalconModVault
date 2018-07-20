function init()
    init_game()
end

function init_game()
    -- 0=blocked,1=food,2=superfood,3=empty,4=door
    MAP = {
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0},
        {0,1,0,0,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,1,0},
        {0,2,0,0,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,2,0},
        {0,1,0,0,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,1,0},
        {0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0},
        {0,1,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,1,0},
        {0,1,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,1,0},
        {0,1,1,1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,1,1,1,0},
        {0,0,0,0,0,0,1,0,0,0,0,0,3,0,0,3,0,0,0,0,0,1,0,0,0,0,0,0},
        {0,0,0,0,0,0,1,0,0,0,0,0,3,0,0,3,0,0,0,0,0,1,0,0,0,0,0,0},  
        {0,0,0,0,0,0,1,0,0,3,3,3,3,3,3,3,3,3,3,0,0,1,0,0,0,0,0,0},
        {0,0,0,0,0,0,1,0,0,3,0,0,0,0,0,0,0,0,3,0,0,1,0,0,0,0,0,0},
        {0,0,0,0,0,0,1,0,0,3,0,3,3,3,3,3,3,0,3,0,0,1,0,0,0,0,0,0},
        {3,3,3,3,3,3,1,3,3,3,0,3,3,3,3,3,3,0,3,3,3,1,3,3,3,3,3,3},
        {0,0,0,0,0,0,1,0,0,3,0,3,3,3,3,3,3,0,3,0,0,1,0,0,0,0,0,0},
        {0,0,0,0,0,0,1,0,0,3,0,0,0,0,0,0,0,0,3,0,0,1,0,0,0,0,0,0},
        {0,0,0,0,0,0,1,0,0,3,3,3,3,3,3,3,3,3,3,0,0,1,0,0,0,0,0,0},
        {0,0,0,0,0,0,1,0,0,3,0,0,0,0,0,0,0,0,3,0,0,1,0,0,0,0,0,0},  
        {0,0,0,0,0,0,1,0,0,3,0,0,0,0,0,0,0,0,3,0,0,1,0,0,0,0,0,0},  
        {0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0},
        {0,1,0,0,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,1,0},
        {0,1,0,0,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,1,0},
        {0,2,1,1,0,0,1,1,1,1,1,1,1,3,3,1,1,1,1,1,1,1,0,0,1,1,2,0},
        {0,0,0,1,0,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0},
        {0,0,0,1,0,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0},
        {0,1,1,1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,1,1,1,0},
        {0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0},
        {0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0},
        {0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    }    
    
    GLOBAL = {
        sw=387,
        sh=481,
        t=0,
        score=0,
        waka_timeout=0,
        blue_timeout=0,
        ghost_anim_timeout=4,
        last_anim_t = 0
    }
    
    g2.game_reset()
    g2.state = "scene"
    g2.view_set(0,0,GLOBAL.sw,GLOBAL.sh)
    g2.status = "Score: "..GLOBAL.score
    g2.bkgr_src = "black"

    g2.new_image("map_blue",0,0,GLOBAL.sw,GLOBAL.sh)
    DOTS = {}
    for i,row in ipairs(MAP) do
        DOTS[i] = {}
        for j,value in ipairs(row) do
            local image
            if value == 1 then
                image = g2.new_image("dot",get_x(j),get_y(i),4,4)
                image.image_cx = 2
                image.image_cy = 2
            elseif value == 2 then     
                image = g2.new_image("big_dot",get_x(j),get_y(i),10,10)
                image.image_cx = 5
                image.image_cy = 5
            end  
            if image ~= nil then DOTS[i][j] = image else DOTS[i][j] = 0 end
        end
    end
    
    GLOBAL.score_label = g2.new_label("Score: "..GLOBAL.score,GLOBAL.sw/2,20,0xffffff)
    
    wakaman = {}
    wakaman.x = 14.5
    wakaman.y = 24
    wakaman.anim = 1
    wakaman.image = g2.new_image("wakaman_"..wakaman.anim,get_x(wakaman.x),get_y(wakaman.y),20,20)
    wakaman.image.image_cx = 10
    wakaman.image.image_cy = 10
    wakaman.dir = "left" 
    wakaman.image.image_a = math.pi
    wakaman.speed = 2
    
    BOTS = {
        {name="Blinky",color=0xff0000,loop="loop_blinky",x=14,y=12,dir="left",default_x=3,default_y=-2,released=true,release_time=0},
        {name="Pinky",color=0xFFA0FF,loop="loop_pinky",x=14,y=15,dir="down",default_x=25,default_y=-2,released=false,release_time=5},
        {name="Inky",color=0x00A0FF,loop="loop_inky",x=12,y=15,dir="up",default_x=28,default_y=33,released=false,release_time=15},
        {name="Clyde",color=0xFFA000,loop="loop_clyde",x=16,y=15,dir="up",default_x=1,default_y=33,released=false,release_time=30}
    }
    for i,bot in ipairs(BOTS) do
        bot.anim = 1
        bot.image = g2.new_image("ghost_"..bot.dir.."_"..bot.anim,get_x(bot.x + 0.5),get_y(bot.y),20,20)
        bot.image.render_color = bot.color
        bot.image.image_cx = 10
        bot.image.image_cy = 10
        bot.speed = 1.5
        bot.last_x = bot.x
        bot.last_y = bot.y
        bot.last_t = 0
        bot.blue = false
    end
    
    g2.play_sound("start")    
end

function get_bot_data(name)
    for _i,bot in ipairs(BOTS) do
        if bot.name == name then return bot end
    end
end


function get_x(array_pos)
    return 4 + GLOBAL.sw/28.5*(array_pos-0.5)
end

function get_y(array_pos)
    return 4 + GLOBAL.sh/31.4*(array_pos-0.5)
end

function get_array_x(x)
    return math.ceil((x-4)*28.5/GLOBAL.sw)
end

function get_array_y(y)
    return math.ceil((y-4)*31.4/GLOBAL.sh)
end

-- get map value corresponding to array indices
function get_map_value(x, y)
    if x < 1 or y < 1 or y > #MAP or x > #MAP[1] then return 0 end
    return MAP[y][x]
end

function has_won()
    for i,row in ipairs(MAP) do
        for j,value in ipairs(row) do
            if value == 1 or value == 2 then return false end
        end
    end
    return true 
end

function loop(t)
    GLOBAL.t = GLOBAL.t + t
    GLOBAL.score_label.label_text = "Score: "..GLOBAL.score
    
    if GLOBAL.t < 4 then return end

    -- animation
    if math.ceil(GLOBAL.t*4) ~= GLOBAL.last_anim_t then
        last_anim_t = math.ceil(GLOBAL.t*4)
        if GLOBAL.waka_timeout > 0 then
            wakaman.anim = wakaman.anim + 1
        else
            wakaman.anim = 3
        end
        if wakaman.anim > 4 then wakaman.anim = 1 end
        local image = g2.new_image("wakaman_"..wakaman.anim, wakaman.image.position_x, wakaman.image.position_y, 20, 20)
        if wakaman.dir == "up" then 
            image.image_a = -math.pi/2
        elseif wakaman.dir == "left" then
            image.image_a = math.pi
        elseif wakaman.dir == "down" then
            image.image_a = math.pi/2
        else
            image.image_a = 0
        end
        
        image.image_cx = 10
        image.image_cy = 10
        wakaman.image:destroy()
        wakaman.image = image
        GLOBAL.ghost_anim_timeout = GLOBAL.ghost_anim_timeout - 1
        if GLOBAL.ghost_anim_timeout < 0 then
            GLOBAL.ghost_anim_timeout = 4
            for i,ghost in ipairs(BOTS) do
                if GLOBAL.mode ~= "frightened" then ghost.blue = false end
                if ghost.anim == "2" then ghost.anim = "1" else ghost.anim = "2" end
                local image
                if GLOBAL.mode ~= "frightened" or (GLOBAL.mode == "frightened" and not ghost.blue) then
                    ghost.speed = 1.5
                    image = g2.new_image("ghost_"..ghost.dir.."_"..ghost.anim, ghost.image.position_x, ghost.image.position_y, 20, 20)
                    image.render_color = ghost.color
                else
                    local color
                    if GLOBAL.blue_timeout < 5 and math.ceil(GLOBAL.t*4)%2 == 0 then
                        color = "white"
                    else
                        color = "blue"
                    end
                    image = g2.new_image("ghost_"..color.."_"..ghost.anim, ghost.image.position_x, ghost.image.position_y, 20, 20)
                end
                image.image_cx = 10
                image.image_cy = 10
                ghost.image:destroy()
                ghost.image = image
            end
        end
    end
    
    GLOBAL.waka_timeout = GLOBAL.waka_timeout - t
    GLOBAL.blue_timeout = GLOBAL.blue_timeout - t
    -- attack "waves"
    if GLOBAL.blue_timeout > 0 then
        GLOBAL.mode = "frightened"
    else
        if GLOBAL.t <= 11 then GLOBAL.mode = "scatter"
        elseif GLOBAL.t <= 31 then GLOBAL.mode = "chase"
        elseif GLOBAL.t <= 38 then GLOBAL.mode = "scatter"
        elseif GLOBAL.t <= 58 then GLOBAL.mode = "chase"
        elseif GLOBAL.t <= 63 then GLOBAL.mode = "scatter"
        elseif GLOBAL.t <= 83 then GLOBAL.mode = "chase"
        elseif GLOBAL.t <= 88 then GLOBAL.mode = "scatter"
        else GLOBAL.mode = "chase" end
    end
    -- release ghosts
    for i,ghost in ipairs(BOTS) do
        if GLOBAL.t > ghost.release_time and not ghost.released then
            ghost.released = true
            ghost.x = 14
            ghost.y = 12
            ghost.image.position_x = get_x(ghost.x)
            ghost.image.position_y = get_y(ghost.y)
            if math.random() > 0.5 then
                ghost.dir = "left"
            else
                ghost.dir = "right"
            end
        end
    end
    -- try to apply queued direction changes
    if GLOBAL.queued_dir == "left" then
        if get_map_value(wakaman.x - 1, wakaman.y) ~= 0 then wakaman.dir = GLOBAL.queued_dir end
    elseif GLOBAL.queued_dir == "right" then
        if get_map_value(wakaman.x + 1, wakaman.y) ~= 0 then wakaman.dir = GLOBAL.queued_dir end
    elseif GLOBAL.queued_dir == "up" then
        if get_map_value(wakaman.x, wakaman.y - 1) ~= 0 then wakaman.dir = GLOBAL.queued_dir end
    elseif GLOBAL.queued_dir == "down" then 
        if get_map_value(wakaman.x, wakaman.y + 1) ~= 0 then wakaman.dir = GLOBAL.queued_dir end
    end
    
    -- update position
    local new_coord
    if wakaman.dir == "left" then
        new_coord = get_array_x(wakaman.image.position_x - wakaman.speed)
        if get_map_value(new_coord, wakaman.y) ~= 0 or new_coord == wakaman.x then
            wakaman.image.position_x = wakaman.image.position_x - wakaman.speed
        end
    elseif wakaman.dir == "right" then
        new_coord = get_array_x(wakaman.image.position_x + wakaman.speed)
        if get_map_value(new_coord, wakaman.y) ~= 0 or new_coord == wakaman.x then
            wakaman.image.position_x = wakaman.image.position_x + wakaman.speed
        end
    elseif wakaman.dir == "up" then
        new_coord = get_array_y(wakaman.image.position_y - wakaman.speed)
        if get_map_value(wakaman.x, new_coord) ~= 0 or new_coord == wakaman.y then
            wakaman.image.position_y = wakaman.image.position_y - wakaman.speed
        end
    elseif wakaman.dir == "down" then
        new_coord = get_array_y(wakaman.image.position_y + wakaman.speed)
        if get_map_value(wakaman.x, new_coord) ~= 0 or new_coord == wakaman.y then
            wakaman.image.position_y = wakaman.image.position_y + wakaman.speed
        end
    end
    -- update array position
    wakaman.x = get_array_x(wakaman.image.position_x)
    wakaman.y = get_array_y(wakaman.image.position_y)
    if wakaman.x == 1 and wakaman.dir == "left" then
        wakaman.x = #MAP[1]
        wakaman.image.position_x = get_x(wakaman.x)
    elseif wakaman.x == #MAP[1] and wakaman.dir == "right" then
        wakaman.x = 1
        wakaman.image.position_x = get_x(wakaman.x)
    end
    -- snap to grid
    if wakaman.dir == "left" or wakaman.dir == "right" then
        wakaman.image.position_y = get_y(wakaman.y)
    else 
        wakaman.image.position_x = get_x(wakaman.x)
    end
    -- gather coins
    if get_map_value(wakaman.x,wakaman.y) == 1 then
        wakaman.speed = 1.4
        MAP[wakaman.y][wakaman.x] = 3
        DOTS[wakaman.y][wakaman.x]:destroy()
        if GLOBAL.waka_timeout < 0 then
            g2.play_sound("waka_waka")
            GLOBAL.waka_timeout = 0.525
        end
        GLOBAL.score = GLOBAL.score + 10
    elseif get_map_value(wakaman.x,wakaman.y) == 2 then
        wakaman.speed = 1.4
        MAP[wakaman.y][wakaman.x] = 3
        DOTS[wakaman.y][wakaman.x]:destroy()
        GLOBAL.blue_timeout = 15
        for i,bot in ipairs(BOTS) do
            bot.blue = true
            bot.speed = 1
        end     
    GLOBAL.score = GLOBAL.score + 50   
    else
        if GLOBAL.waka_timeout < 0.2 then wakaman.speed = 2 end
    end
    
    for i,bot in ipairs(BOTS) do
        _ENV[bot.loop](bot)
    end
    
    if has_won() then init_win() end
end

function event(e)
    if e.type == "ui:motion" or e.type == "ui:down" then
        if e.x - wakaman.image.position_x > e.y - wakaman.image.position_y then
            if wakaman.image.position_x - e.x < e.y - wakaman.image.position_y then
                GLOBAL.queued_dir = "right"
            else
                GLOBAL.queued_dir = "up"
            end
        else
            if wakaman.image.position_x - e.x < e.y - wakaman.image.position_y then
                GLOBAL.queued_dir = "down"
            else
                GLOBAL.queued_dir = "left"
            end
        end
    end
    if (e["type"] == "onclick" and e["value"] == "resume") then
        g2.state = "scene"
    end
    if (e["type"] == "onclick" and e["value"] == "restart") then
        init_game()
    end
    if (e["type"] == "onclick" and e["value"] == "continue") then
        local score = GLOBAL.score
        init_game()
        GLOBAL.score = score
    end
    if (e["type"] == "onclick" and e["value"] == "quit") then
        g2.state = "quit"
    end
    if (e["type"] == "pause") then
        init_pause()
    end
end

function loop_pinky(bot)
    if GLOBAL.mode == "chase" then
        if wakaman.dir == "left" then
            bot.target_x = wakaman.x - 4
            bot.target_y = wakaman.y
        elseif wakaman.dir == "right" then
            bot.target_x = wakaman.x + 4
            bot.target_y = wakaman.y 
        elseif wakaman.dir == "down" then
            bot.target_x = wakaman.x
            bot.target_y = wakaman.y - 4
        elseif wakaman.dir == "up" then
            bot.target_x = wakaman.x
            bot.target_y = wakaman.y + 4
        end
    elseif GLOBAL.mode == "scatter" then
        bot.target_x = bot.default_x
        bot.target_y = bot.default_y
    end
    loop_bot_standard(bot)
end

function loop_blinky(bot)
    if GLOBAL.mode == "chase" then
        bot.target_x = wakaman.x
        bot.target_y = wakaman.y
    elseif GLOBAL.mode == "scatter" then
        bot.target_x = bot.default_x
        bot.target_y = bot.default_y
    end    
    loop_bot_standard(bot)
end

function loop_inky(bot)
    if GLOBAL.mode == "chase" then
        local blinky = get_bot_data("Blinky")
        local x
        local y
        if wakaman.dir == "left" then
            x = wakaman.x - 2
            y = wakaman.y
        elseif wakaman.dir == "right" then
            x = wakaman.x + 2
            y = wakaman.y
        elseif wakaman.dir == "down" then
            x = wakaman.x
            y = wakaman.y - 2
        elseif wakaman.dir == "up" then
            x = wakaman.x
            y = wakaman.y + 2
        end
        bot.target_x = (x - blinky.x)*2 + blinky.x
        bot.target_y = (y - blinky.y)*2 + blinky.y
    elseif GLOBAL.mode == "scatter" then
        bot.target_x = bot.default_x
        bot.target_y = bot.default_y
    end
    loop_bot_standard(bot)
end

function loop_clyde(bot)
    if GLOBAL.mode == "chase" then
        if dist(bot.x, bot.y, wakaman.x, wakaman.y) > 8 then
            bot.target_x = wakaman.x
            bot.target_y = wakaman.y
        else
           bot.target_x = bot.default_x
           bot.target_y = bot.default_y
        end  
    elseif GLOBAL.mode == "scatter" then
        bot.target_x = bot.default_x
        bot.target_y = bot.default_y
    end
    loop_bot_standard(bot)
end

function loop_bot_standard(bot)
    -- collisions
    if bot.x == wakaman.x and bot.y == wakaman.y then
        if GLOBAL.blue_timeout > 0 and bot.blue then
            g2.play_sound("nom")
            bot.x = 14
            bot.y = 12
            bot.image.position_x = get_x(bot.x)
            bot.image.position_y = get_y(bot.y)
            if math.random() > 0.5 then bot.dir = "left" else bot.dir = "right" end
            bot.blue = false
            GLOBAL.score = GLOBAL.score + 800
        else
            g2.play_sound("death")
            init_lose()
            return
        end
    end
    -- try to apply direction changes
    local best = 923849898
    local dir = bot.dir
    local opts = {
        {dist=dist(bot.x-1,bot.y,bot.target_x,bot.target_y),dir="left",x=-1,y=0,rand=math.random()},
        {dist=dist(bot.x+1,bot.y,bot.target_x,bot.target_y),dir="right",x=1,y=0,rand=math.random()},
        {dist=dist(bot.x,bot.y-1,bot.target_x,bot.target_y),dir="up",x=0,y=-1,rand=math.random()},
        {dist=dist(bot.x,bot.y+1,bot.target_x,bot.target_y),dir="down",x=0,y=1,rand=math.random()}
    }
    for i,opt in ipairs(opts) do
        if get_map_value(bot.x + opt.x, bot.y + opt.y) ~= 0 then
            if (opt.dir == "left" and bot.dir ~= "right") or
                (opt.dir == "right" and bot.dir ~= "left") or
                (opt.dir == "up" and bot.dir ~= "down") or
                (opt.dir == "down" and bot.dir ~= "up") then
                if GLOBAL.mode == "frightened" then
                    if opt.rand < best then
                        best = opt.rand
                        dir = opt.dir
                    end
                else
                    if opt.dist < best then
                        best = opt.dist
                        dir = opt.dir
                    end
                end
            end
        end
    end
    if dir ~= bot.dir then
        if bot.x ~= bot.last_x or bot.y ~= bot.last_y or GLOBAL.t > bot.last_t + 1 then 
            bot.dir = dir
            bot.last_x = bot.x
            bot.last_y = bot.y
            bot.last_t = GLOBAL.t
        end
    end
    
    -- update position
    local new_coord
    if bot.dir == "left" then
        new_coord = get_array_x(bot.image.position_x - bot.speed)
        if get_map_value(new_coord, bot.y) ~= 0 or new_coord == bot.x then
            bot.image.position_x = bot.image.position_x - bot.speed
        end
    elseif bot.dir == "right" then
        new_coord = get_array_x(bot.image.position_x + bot.speed)
        if get_map_value(new_coord, bot.y) ~= 0 or new_coord == bot.x then
            bot.image.position_x = bot.image.position_x + bot.speed
        end
    elseif bot.dir == "up" then
        new_coord = get_array_y(bot.image.position_y - bot.speed)
        if get_map_value(bot.x, new_coord) ~= 0 or new_coord == bot.y then
            bot.image.position_y = bot.image.position_y - bot.speed
        end
    elseif bot.dir == "down" then
        new_coord = get_array_y(bot.image.position_y + bot.speed)
        if get_map_value(bot.x, new_coord) ~= 0 or new_coord == bot.y then
            bot.image.position_y = bot.image.position_y + bot.speed
        end
    end
    -- update array position
    bot.x = get_array_x(bot.image.position_x)
    bot.y = get_array_y(bot.image.position_y)
    if bot.x == 1 and bot.dir == "left" then
        bot.x = #MAP[1]
        bot.image.position_x = get_x(bot.x)
    elseif bot.x == #MAP[1] and bot.dir == "right" then
        bot.x = 1
        bot.image.position_x = get_x(bot.x)
    end
    -- snap to grid
    if bot.dir == "left" or bot.dir == "right" then
        bot.image.position_y = get_y(bot.y)
    else 
        bot.image.position_x = get_x(bot.x)
    end
    -- collisions
    if bot.x == wakaman.x and bot.y == wakaman.y then
        if GLOBAL.blue_timeout > 0 and bot.blue then
            g2.play_sound("nom")
            bot.x = 14
            bot.y = 12
            bot.image.position_x = get_x(bot.x)
            bot.image.position_y = get_y(bot.y)
            if math.random() > 0.5 then bot.dir = "left" else bot.dir = "right" end
            bot.blue = false
            GLOBAL.score = GLOBAL.score + 800
        else
            g2.play_sound("death")
            init_lose()
            return
        end
    end
end

function dist(x1,y1,x2,y2)
    return math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
end

function init_pause() 
    g2.state = "pause"
    g2.html = ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume' onclick='resume' />"..
    "<tr><td><input type='button' value='Restart' onclick='restart' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

function init_win() 
    g2.state = "pause"
    g2.html = ""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><input type='button' value='Next Round' onclick='continue' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

function init_lose() 
    g2.state = "pause"
    g2.html = "" ..
    "<table>"..
    "<tr><td><h1>    Game Over\nYour Score: "..GLOBAL.score.."</h1>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end
