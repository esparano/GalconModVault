function init()
    GLOBAL = {
        sw = 400,
        sh = 300,
    }
    init_game()
    g2.play_music("mus-play1")
end
 
function init_game()
    g2.game_reset()
    g2.state = "scene"
    g2.view_set(0, 0, GLOBAL.sw, GLOBAL.sh)
 
    ball = g2.new_circle(0xffffff, GLOBAL.sw/2, GLOBAL.sh/2, 5)
    l_paddle = g2.new_image("white", 10, GLOBAL.sh/2, 10, 50)
    l_paddle.image_cx = 5
    l_paddle.image_cy = 25
    r_paddle = g2.new_image("white", GLOBAL.sw - 10, GLOBAL.sh/2, 10, 50)
    r_paddle.image_cx = 5
    r_paddle.image_cy = 25
    ball_vx = 10
    ball_vy = 5
    
    score = 0
    score_label = g2.new_label("Score: "..score, GLOBAL.sw/2, 10)
end
 
function loop(t)
    ball.position_x = ball.position_x + ball_vx
    ball.position_y = ball.position_y + ball_vy
    
    if ball.position_y < 10 or ball.position_y > GLOBAL.sh - 10 then
        ball_vy = -ball_vy
    end
    
    if ball.position_x > r_paddle.position_x - 10 then
        ball_vx = -ball_vx
        ball_vy = 10*(math.random() - 0.5)
        g2.play_sound("sfx-hit")
    end
    
    if ball_vx < 0 and ball.position_x < 20 and math.abs(ball.position_y - l_paddle.position_y) < 25 then
        ball_vx = -ball_vx
        ball_vy = 10*(math.random() - 0.5)
        g2.play_sound("sfx-hit")
        score = score + 10
    end
    
    if ball.position_x < 0 then
        init_lose()
    end
    
    r_paddle.position_y = ball.position_y
    score_label.label_text = "Score: "..score
end
 
function event(e)
    if e.type == "ui:motion" or e.type == "ui:down" then
        l_paddle.position_y = e.y
    end
    if e.type == "pause" then
        g2.state = "pause"
        g2.html = "<table><tr><td><input type='button' value='Resume' onclick='resume' />"
    end
    if e.type == "onclick" and e.value == "resume" then
        g2.state = "scene"
    end
    if e.type == "onclick" and e.value == "new_game" then
        g2.state = "scene"
        init_game()
    end
end
 
function init_lose()
    g2.state = "pause"
    g2.html = "<table><tr><td><h1>Try again?"..
              "<tr><td><input type='button' value='New Game' onclick='new_game' />"
end