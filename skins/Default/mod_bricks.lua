function init(lev)
    g2.game_reset();
    level = lev
    if level == nil then
        level = 1
        score = 0
    end
    ticks = 0
    uticks = 0
    v = math.sqrt(1.5 + level/2.0)
    bricks = {}
    ball = nil
    paddle = nil
    data = {}
    colors = {0xffff00,0x00ffff,0xff00ff,0xffffff}
    for y=0,3 do
        for x=0,7 do
            b = g2.new_image("white",x*20,y*10,19,9)
            bricks[#bricks+1] = b
            b.render_color = colors[y+1]
        end
    end
    ball = g2.new_image("white",100,100,4,4)
    paddle = g2.new_image("white",100,96,20,4)
    g2.new_line(0x00ffff,0,0,0,120)
    g2.new_line(0x00ffff,160,0,160,120)
    g2.view_set(0,0,160,120)
    g2.state = "scene"
    a = -math.pi/4
    data.dx = v * math.cos(a)
    data.dy = v * math.sin(a)
    combo = 1
    score_txt = g2.new_label("",80,110,0xffffff)
    update_txt()
end

function update_txt()
    score_txt.label_text = score
end


function loop(t)
    ticks = ticks + t
    while uticks < ticks do
        inc = 1/60
        uticks = uticks + inc
        do_tick()
    end
end

function do_tick()
    ball.position_x = ball.position_x + data.dx 
    ball.position_y = ball.position_y + data.dy 
    
    if ball.position_x < 0 then
        g2.play_sound("bricks-tink")                      
        data.dx = -data.dx
        ball.position_x = 0
    end
    if ball.position_x > 160 then
        g2.play_sound("bricks-tink")                      
        data.dx = -data.dx
        ball.position_x = 160
    end
    if ball.position_y < 0 then
        g2.play_sound("bricks-tink")                      
        data.dy = -data.dy
        ball.position_y = 0
    end
    if ball.position_y > 120 then
        g2.play_sound("sfx-explode")
        init()
    end
    
    if ball.position_y > 94 and ball.position_x > paddle.position_x and ball.position_x < (paddle.position_x + paddle.image_w) then
        a = math.pi + math.pi / 8 + (math.pi*3/4) * ((ball.position_x - paddle.position_x) / 20.0) 
        g2.play_sound("bricks-snap")                      
        data.dx = v * math.cos(a)
        data.dy = v * math.sin(a)
        ball.position_y = 94
        combo = 1
    end
    
    t = 0
    for i,b in ipairs(bricks) do
        if b ~= 0 and ball.position_x >= b.position_x and ball.position_y >= b.position_y and ball.position_x <= (b.position_x + b.image_w) and ball.position_y <= (b.position_y + b.image_h) then
            g2.play_sound("bricks-tick")                      
            data.dy = -data.dy
            b:destroy()
            bricks[i]=0
            score = score + 1 * level * combo
            combo = combo + 1
            update_txt()
            return
        end
        if b ~= 0 then t = t + 1 end
    end
    
    if t == 0 then
        init(level + 1)
    end
end

function event(e) 
    if e.type == "ui:motion" or e.type == "ui:down" then
        paddle.position_x = e.x - 10
    end
end