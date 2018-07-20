function init()
    GLOBAL = {
        sw=400,
        sh=300,
    }
    load()
    init_game()
    g2.play_music("athletic")
end


-- load game state
function load()
    local data = json.decode(g2.data)
    if data == nil or g2.data == "[]" then
        GLOBAL.highscore = 0
    else 
        GLOBAL.highscore = data.highscore
    end
end

-- save game state
function save()
    g2.data = json.encode({
        highscore = GLOBAL.highscore,
    })
end

function init_game()
    GLOBAL.t=0
    GLOBAL.score=0
    game_over = false
    
    CLOUD_HEIGHT = 30
    CLOUD_SEPARATION = GLOBAL.sw/4
    PIPE_SEPARATION = math.floor(GLOBAL.sw/2.5)
    PIPE_WIDTH = 60
    PIPE_HEIGHT = PIPE_WIDTH*596/128
    CHEEP_CHEEP_WIDTH = 25
    CHEEP_CHEEP_X = GLOBAL.sw/4
    
    x = 0
    y = GLOBAL.sh/2
    vx = 2
    vy = 0
    ay = 0.35
    jump_vy = -6.2
    pipes = {}
    images = {}
    num_pipes_behind = 0
    
    g2.game_reset()
    g2.state = "scene"
    g2.view_set(0,0,GLOBAL.sw,GLOBAL.sh)
    g2.status = "Score: "..GLOBAL.score
    g2.bkgr_src = "cheep_bkgr"
    
    initial_draw()
    
    cheep_cheep = g2.new_image("cheep_up", CHEEP_CHEEP_X, GLOBAL.sh/2, CHEEP_CHEEP_WIDTH, CHEEP_CHEEP_WIDTH)
    cheep_cheep.image_cx = cheep_cheep.image_w/2
    cheep_cheep.image_cy = cheep_cheep.image_h/2
    cheep_cheep.image_a = 0.1
    
    GLOBAL.score_label = g2.new_label("Score: "..GLOBAL.score,GLOBAL.sw/2,20,0xffffff)
end

function create_pipes(x)
    local height = GLOBAL.sh*(0.25 + 0.5*math.random())
    local separation = GLOBAL.sh/3
    local pipe_1_height = height - separation/2 - PIPE_HEIGHT/2
    local pipe_2_height = height + separation/2 + PIPE_HEIGHT/2
    local pipe = g2.new_image("pipe2", x, pipe_1_height, PIPE_WIDTH, PIPE_HEIGHT)
    pipe.image_cx = pipe.image_w/2
    pipe.image_cy = pipe.image_h/2
    pipes[#pipes + 1] = pipe
    pipe = g2.new_image("pipe", x, pipe_2_height, PIPE_WIDTH, PIPE_HEIGHT)
    pipe.image_cx = pipe.image_w/2
    pipe.image_cy = pipe.image_h/2
    pipes[#pipes + 1] = pipe
end

function create_cloud(x)
    local small = false
    if math.random() > 0.5 then 
        small = true
    end
    local cloud
    local height = GLOBAL.sh*(0.08 + 0.84*math.random())
    if small then
        cloud = g2.new_image("cloud_small", x + GLOBAL.sw/10*(math.random() - 0.5), height, CLOUD_HEIGHT*30/22, CLOUD_HEIGHT)
        cloud.image_cx = cloud.image_w/2
        cloud.image_cy = cloud.image_h/2
    else
        cloud = g2.new_image("cloud_large", x  + GLOBAL.sw/10*(math.random() - 0.5), height, CLOUD_HEIGHT*62/22, CLOUD_HEIGHT)
        cloud.image_cx = cloud.image_w/2
        cloud.image_cy = cloud.image_h/2
    end
    images[#images + 1] = cloud
end

function initial_draw() 
    for i=0,GLOBAL.sw*20 do
        if i%CLOUD_SEPARATION == 0 then
            create_cloud(i)
        end
    end
    for i=0,GLOBAL.sw*20 do
        if i > GLOBAL.sw/3 and i%PIPE_SEPARATION == 100 then
            create_pipes(i)
        end
    end
end

function num_behind()
    local num = 0
    for _i,pipe in ipairs(pipes) do
        if (pipe.position_x + PIPE_WIDTH/2 < CHEEP_CHEEP_X - CHEEP_CHEEP_WIDTH) then num = num + 1 end
    end
    return num
end

function loop(t)
    if game_over and g2.state == "pause" then return end
    if game_over and g2.state == "scene" then init_game() end
    if game_over and g2.state == "play" then init_game() end
    GLOBAL.t = GLOBAL.t + t 
    GLOBAL.score_label.label_text = "Score: "..GLOBAL.score
    
    x = x + vx
    y = y + vy
    vy = vy + ay
    
    cheep_cheep:destroy()
    if (vy > 0) then
        cheep_cheep = g2.new_image("cheep_up", CHEEP_CHEEP_X, y, CHEEP_CHEEP_WIDTH, CHEEP_CHEEP_WIDTH)
    else 
        cheep_cheep = g2.new_image("cheep_down", CHEEP_CHEEP_X, y, CHEEP_CHEEP_WIDTH, CHEEP_CHEEP_WIDTH)
    end
    cheep_cheep.image_cx = cheep_cheep.image_w/2
    cheep_cheep.image_cy = cheep_cheep.image_h/2
    cheep_cheep.image_a = vy/18 + 0.1
    
    local npb = num_behind()
    if npb > num_pipes_behind then
        GLOBAL.score = GLOBAL.score + 1
        g2.play_sound("smw_coin")
        g2.play_sound("smw_coin")
        g2.play_sound("smw_coin")
        g2.play_sound("smw_coin")
        g2.play_sound("smw_coin")
        g2.play_sound("smw_coin")
        g2.play_sound("smw_coin")
        g2.play_sound("smw_coin")
        -- Hack to make sound louder LOLOLOLOLOLOL
        num_pipes_behind = npb
    end
    
    for _i,image in ipairs(images) do 
        image.position_x = image.position_x - vx/4
        if image.position_x < -PIPE_WIDTH*4 then
            image.position_x = image.position_x + GLOBAL.sw*20
        end
    end
    for _i,pipe in ipairs(pipes) do
        pipe.position_x = pipe.position_x - vx
        if math.abs(pipe.position_x - CHEEP_CHEEP_X) - 0.6*CHEEP_CHEEP_WIDTH/2 < pipe.image_w/2 then
            if math.abs(pipe.position_y - y) - 0.93*CHEEP_CHEEP_WIDTH/2 < pipe.image_h/2 then
                -- collision
                init_lose()
                return
            end
        end
        if math.abs(pipe.position_x - CHEEP_CHEEP_X) - 0.95*CHEEP_CHEEP_WIDTH/2 < pipe.image_w/2 then
            if math.abs(pipe.position_y - y) - 0.6*CHEEP_CHEEP_WIDTH/2 < pipe.image_h/2 then
                -- collision
                init_lose()
                return
            end
        end
        if y > GLOBAL.sh + 1.5*CHEEP_CHEEP_WIDTH or y < -1.5*CHEEP_CHEEP_WIDTH then init_lose() return end
        if pipe.position_x < -PIPE_WIDTH*4 then
            pipe.position_x = pipe.position_x + GLOBAL.sw*20
            num_pipes_behind = num_pipes_behind - 1
        end
    end
end

function event(e)
    if e.type == "ui:down" then
        vy = jump_vy
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

function init_pause() 
    g2.state = "pause"
    g2.html = ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume' onclick='resume' />"..
    "<tr><td><input type='button' value='Restart' onclick='restart' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end

function init_lose() 
    game_over = true
    GLOBAL.score_label:destroy()
    if GLOBAL.score > GLOBAL.highscore then GLOBAL.highscore = GLOBAL.score end
    save()
    g2.state = "pause"
    g2.html = "" ..
    "<table>"..
    "<tr><td><h1>Game Over\n\nYour Score: "..GLOBAL.score.."\nBest: "..GLOBAL.highscore.."</h1>"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "";
end
