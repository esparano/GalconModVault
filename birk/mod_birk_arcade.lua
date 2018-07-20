-- VERSION 0.03


function init()
  OPTIONS = {
    screen_width = 640,
    screen_height = 480,
    bot_ships = 1.1
  }
  
  MEMORY = json.decode(g2.data)
  if not MEMORY then
    MEMORY = {
      highscore = 0
    }
  end
  
  GAME = {
    
  }
  
  COLORS = {
    -- black, white
    0x222222, 0xffffff,
    -- blue, red, gree, purple, orange, cyan, pink, yellow, azure, silver
    0x0000ff, 0xff0000, 0x00ff00, 0x8000ff, 0xff8000, 0x00ffff, 0xff00ff, 0xffff00, 0x0080ff, 0xaaaaaa,
    -- midnight, maroon, forest, indigo, brown, teal, violet, olive, navy, gray
    0x000080, 0x801500, 0x008015, 0x550080, 0x805500, 0x006a80, 0x80006a, 0x6a8000, 0x002a80, 0x545454,
    -- periwinkle, rose, lime, orchid, salmon, aquamarine, plum, wheat, powder
    0x99aaff, 0xff99aa, 0xaaff99, 0xbb99ff, 0xffbb99, 0x99ffee, 0xee99ff, 0xffee99, 0x99ddff
  }

  
  -- g2.speed = 1
  
  g2.state = "play"
  init_game()
end


function init_game()
  g2.game_reset()

  GAME.timer = 0
  GAME.tempo = 10 -- pixel per second
  GAME.score = 0
  GAME.level = 0
  GAME.direction = 1
  
  GAME.dead = false
  GAME.planetcount = 0
  
  GAME.last_x = OPTIONS.screen_width/2
  
  GAME.redir = 0
  
  g2.view_set(0, 0, OPTIONS.screen_width, OPTIONS.screen_height)
  
  init_users()
  
  init_map()
  
  init_level_0()
  
end


function init_users()
  GAME.neutral = g2.new_user("neutral", COLORS[1])
  GAME.neutral.user_neutral = true
  GAME.neutral.ships_production_enabled = false
  
  GAME.player = g2.new_user("player", COLORS[2])
  g2.player = GAME.player
  
  GAME.bot1 = g2.new_user("blue bot", COLORS[3])
  GAME.bot2 = g2.new_user("red bot", COLORS[4])
  GAME.bot3 = g2.new_user("green bot", COLORS[5])
  GAME.bot4 = g2.new_user("purple bot", COLORS[6])
  GAME.bot5 = g2.new_user("orange bot", COLORS[7])
  GAME.bot6 = g2.new_user("cyan bot", COLORS[8])
  GAME.bot7 = g2.new_user("pink bot", COLORS[9])
  GAME.bot8 = g2.new_user("yellow bot", COLORS[10])
  GAME.bot9 = g2.new_user("azure bot", COLORS[11])
  GAME.bot10 = g2.new_user("silver bot", COLORS[12])
  
  GAME.bot11 = g2.new_user("midnight bot", COLORS[13])
  GAME.bot12 = g2.new_user("maroon bot", COLORS[14])
end

function init_map()
  g2.new_planet(GAME.player, OPTIONS.screen_width / 2, OPTIONS.screen_height /2, 100, 50)
  g2.new_planet(GAME.neutral, OPTIONS.screen_width / 2, 25, 100, 0)
  
  g2.new_line(COLORS[1], 0, - 25, OPTIONS.screen_width, 0 - 25)
  g2.new_line(COLORS[1], 0, OPTIONS.screen_height + 25, OPTIONS.screen_width, OPTIONS.screen_height + 25)
end



-----------------------------------------------------------------------------------------------------------------------------------------

function loop(t)
  GAME.timer = GAME.timer + t
  if GAME.timer >= 0.05 then
    if GAME.level == 0 then
      level_0_map()
      level_0_bot()
    elseif GAME.level == 1 then
      level_1_map()
      level_1_bot()
    elseif GAME.level == 2 then
      level_2_map()
      level_2_bot()
    elseif GAME.level == 3 then
      level_3_map()
      level_3_bot()
    elseif GAME.level == 4 then
      level_4_map()
      level_4_bot()
    elseif GAME.level == 5 then
      level_5_map()
      level_5_bot()
     elseif GAME.level == 6 then
      level_6_map()
      level_6_bot()
     elseif GAME.level == 7 then
      level_7_map()
      level_7_bot()
     elseif GAME.level == 8 then
      level_8_map()
      level_8_bot()
     elseif GAME.level == 9 then
      level_9_map()
      level_9_bot()
     elseif GAME.level == 10 then
      level_10_map()
      level_10_bot()
     elseif GAME.level == 11 then
      level_11_map()
      level_11_bot()
     elseif GAME.level == 12 then
      level_12_map()
      level_12_bot()
    end

    GAME.timer = GAME.timer - 0.05
  end
  
end

function init_level_0()
  GAME.level = 0
  GAME.tempo = 10
  add_planet(GAME.neutral, math.random(15,100), math.random(0,50))
  g2.bkgr_src = "background05"
end

function init_level_1()
  GAME.level = 1
  GAME.tempo = 15
  add_planet(GAME.bot1, math.random(20,40), math.random(0,25))
  g2.bkgr_src = "background03"
end

function init_level_2()
  GAME.level = 2
  GAME.tempo = 20
  add_planet(GAME.bot2, math.random(33,66), math.random(25,30))
  g2.bkgr_src = "background02"
end

function init_level_3()
  GAME.level = 3
  GAME.tempo = 9
  add_planet(GAME.bot3, math.random(200,200), math.random(200,200))
  g2.bkgr_src = "background01"
end

function init_level_4()
  GAME.level = 4
  GAME.tempo = 22.5
  add_planet(GAME.bot4, math.random(0,1), math.random(0,25))
  g2.bkgr_src = "background03"
end

function init_level_5()
  GAME.level = 5
  GAME.tempo = 50
  local x = add_planet(GAME.bot5, 100, 0)
  g2.new_planet(GAME.neutral, OPTIONS.screen_width - x, -25, 100, 10)
  g2.bkgr_src = "background02"
end

function init_level_6()
  GAME.level = 6
  GAME.tempo = 15
  GAME.bot6.fleet_crash = 100
  add_planet(GAME.bot6, math.random(20,40), math.random(0,25))
  g2.bkgr_src = "background01"
end

function init_level_7()
  GAME.level = 7
  GAME.tempo = 20
  GAME.bot7.fleet_crash = 100
  local x = add_planet(GAME.bot7, 15, 20)
  g2.new_planet(GAME.neutral, x + 50, -25, 15, 0)
  g2.new_planet(GAME.neutral, OPTIONS.screen_width - x, -25, 15, 0)
  g2.new_planet(GAME.bot7, OPTIONS.screen_width - x - 50, -25, 15, 20*OPTIONS.bot_ships)
  g2.bkgr_src = "background04"
end

function init_level_8()
  GAME.level = 8
  GAME.tempo = 21
  GAME.bot8.fleet_crash = 100
  add_planet(GAME.neutral, 200, 10)
  add_planet(GAME.bot8, math.random(25,50), math.random(25,50))
  g2.bkgr_src = "background05"
end

function init_level_9()
  GAME.level = 9
  GAME.tempo = 40
  GAME.bot9.fleet_crash = 100
  g2.new_planet(GAME.bot9, OPTIONS.screen_width/2, -25, 100, 10*OPTIONS.bot_ships)
  g2.bkgr_src = "background03"
end

function init_level_10()
  GAME.level = 10
  GAME.tempo = 15
  --GAME.bot10.fleet_crash = 100
  GAME.bot10.fleet_v_factor  = 2
  g2.new_planet(GAME.bot10, OPTIONS.screen_width/2, -25, 100, 10*OPTIONS.bot_ships)
  g2.bkgr_src = "background05"
end

function init_level_11()
  GAME.level = 11
  GAME.tempo = 15
  GAME.direction = -1
  add_planet(GAME.bot11, math.random(25,50), math.random(25,50))
  g2.bkgr_src = "background03"
end

function init_level_12()
  GAME.level = 12
  GAME.tempo = 25
  GAME.direction = -1
  GAME.bot9.fleet_crash = 50
  GAME.bot10.fleet_v_factor  = 1.5
  add_planet(GAME.bot12, math.random(500,500), 250)
  g2.bkgr_src = "background02"
end








function level_0_map()
  move_planets()
  local r = math.random(0,50)
  if r == 0 then
    add_planet(GAME.neutral, math.random(15,100), math.random(0,100))
  end
end

function level_1_map()
  move_planets()
  local r = math.random(0,50)
  if r == 0 then
    add_planet(GAME.neutral, math.random(15,100), math.random(0,75))
  elseif r == 1 then
    add_planet(GAME.bot1, math.random(20,40), math.random(0,25))
  end
end

function level_2_map()
  move_planets()
  local r = math.random(0,50)
  if r == 0 then
    add_planet(GAME.neutral, math.random(15,100), math.random(0,100))
  elseif r == 1 then
    add_planet(GAME.bot2, math.random(33,66), math.random(25,30))
  end
end

function level_3_map()
  move_planets()
  local r = math.random(0,200)
  if r < 1 then
    add_planet(GAME.neutral, math.random(15,100), math.random(0,50))
  elseif r == 1 then
    add_planet(GAME.bot3, math.random(150,150), math.random(75,100))
  end
end


function level_4_map()
  move_planets()
  local r = math.random(0,50)
  if r == 0 then
    add_planet(GAME.neutral, math.random(0,1), math.random(0,25))
  elseif r == 1 or r == 2 then
    add_planet(GAME.bot4, math.random(0,1), math.random(0,25))
  end
end

function level_5_map()
  move_planets()
  local r = math.random(0,50)
  if r == 1 then
    local x = add_planet(GAME.bot5, 100, 10)
    g2.new_planet(GAME.neutral, OPTIONS.screen_width - x, -25, 100, 10)
  elseif r == 0 then
    local x = add_planet(GAME.neutral, 100, 10)
    g2.new_planet(GAME.neutral, OPTIONS.screen_width - x, -25, 100, 10)
  end
end

function level_6_map()
  move_planets()
  local r = math.random(0,100)
  if r <= 1 then
    add_planet(GAME.neutral, math.random(15,100), math.random(0,50))
  elseif r == 2 then
    add_planet(GAME.bot6, math.random(20,40), math.random(0,25))
  end
end

function level_7_map()
  move_planets()
  local r = math.random(0,80)
  if r == 1 then
    local x = add_planet(GAME.bot7, 15, 5)
    g2.new_planet(GAME.neutral, x + 50, -25, 15, 5)
    g2.new_planet(GAME.neutral, OPTIONS.screen_width - x, -25, 15, 5)
    g2.new_planet(GAME.bot7, OPTIONS.screen_width - x - 50, -25, 15, 5)
  end
end

function level_8_map()
  move_planets()
  local r = math.random(0,100)
  if r == 0 then
    add_planet(GAME.neutral, math.random(0,200), 1000)
  elseif r == 1 then
    add_planet(GAME.neutral, math.random(100,200), math.random(1,100))
  elseif r == 2 then
    add_planet(GAME.bot8, math.random(25,50), math.random(20,30))
  end
end

function level_9_map()
  move_planets()
  GAME.planetcount = GAME.planetcount + 1
  if GAME.planetcount == 40 then
     add_planet(GAME.neutral, 10, 0)
  elseif GAME.planetcount == 80 then
    g2.new_planet(GAME.bot9, OPTIONS.screen_width/2, -25, 10, 10)
    GAME.planetcount = 0
  end
end

function level_10_map()
  move_planets()
  local r = math.random(0,100)
  if r <= 1 then
    add_planet(GAME.neutral, math.random(15,100), math.random(0,50))
  elseif r == 2 then
    add_planet(GAME.bot10, math.random(25,50), math.random(0,70))
  end
end

function level_11_map()
  move_planets()
  local r = math.random(0,100)
  if r <= 1 then
    add_planet(GAME.neutral, math.random(25,50), math.random(25,50))
  elseif r == 2 then
    add_planet(GAME.bot11, math.random(25,50), math.random(25,50))
  end
end

function level_12_map()
  move_planets()
  local r = math.random(0,100)
  if r <= 1 then
    add_planet(GAME.neutral, math.random(0,5), math.random(0,5))
  elseif r == 2 then
    add_planet(GAME.bot12, math.random(0,5), math.random(10,40))
  end
end



function level_0_bot()
  -- no bot
end

function level_1_bot()
  bot_loop(GAME.bot1, false)
end

function level_2_bot()
  bot_loop(GAME.bot1, false)
  bot_loop(GAME.bot2, true)
end

function level_3_bot()
  bot_loop(GAME.bot2, true)
  bot_loop(GAME.bot3, true)
end

function level_4_bot()
  bot_loop(GAME.bot3, true)
  bot_loop(GAME.bot4, true)
end

function level_5_bot()
  bot_loop(GAME.bot4, true)
  bot_loop(GAME.bot5, false)
end

function level_6_bot()
  bot_loop(GAME.bot5, false)
  bot_loop(GAME.bot6, true)
end

function level_7_bot()
  bot_loop(GAME.bot6, true)
  bot_loop(GAME.bot7, true)
end

function level_8_bot()
  bot_loop(GAME.bot7, true)
  bot_loop(GAME.bot8, false)
end

function level_9_bot()
  bot_loop(GAME.bot8, false)
  bot_loop(GAME.bot9, true)
end

function level_10_bot()
  bot_loop(GAME.bot9, true)
  bot_loop(GAME.bot10, true)
end

function level_11_bot()
  bot_loop(GAME.bot10, true)
  bot_loop(GAME.bot11, true)
end


function level_12_bot()
  bot_loop(GAME.bot11, true)
  bot_loop(GAME.bot12, true)
end





function add_planet(user, p, s)
  local x = math.random(0,OPTIONS.screen_width)
  local y = -25
  
  if GAME.direction == -1 then
    y = OPTIONS.screen_height + 25
  end
  
  if not  (user == GAME.player or user == GAME.neutral) then
    s = s*OPTIONS.bot_ships
  end
  
  local d = GAME.last_x - x
  if d < 50 and d > -50 then
    if d < 0 then
      x = x + 50
    else
      x = x - 50
    end
  end

  GAME.last_x = x
  
  g2.new_planet(user, x, y, p, s)

  return x
end


function move_planets(t)

  local planets = g2.search("planet")
  for i,p in ipairs(planets) do
    if GAME.direction == -1 then
      p.position_y = p.position_y - GAME.tempo/20
    else
      p.position_y = p.position_y + GAME.tempo/20
    end
  end
  

  
  destroy_planets(planets)
end

function destroy_planets(planets)
  for i,p in ipairs(planets) do
    if GAME.direction == -1 then
      if p.position_y <= - 25 then -- TEST
        p:destroy()
        add_score()
        check_lose(planets)
      end
    else
      if p.position_y >= OPTIONS.screen_height + 25 then
        p:destroy()
        add_score()
        check_lose(planets)
      end
    end
  end
  

  
end


function add_score()
  if GAME.dead == false then
    GAME.score = GAME.score + 1
  end
  
  if GAME.score == 15 then
    init_level_1()
  elseif GAME.score == 45 then
    init_level_2()
  elseif GAME.score == 75 then
    init_level_3()
  elseif GAME.score == 95 then
    init_level_4()
  elseif GAME.score == 125 then
    init_level_5()
  elseif GAME.score == 160 then
    init_level_6()
  elseif GAME.score == 190 then
    init_level_7()
  elseif GAME.score == 220 then
    init_level_8()
  elseif GAME.score == 250 then
    init_level_9()
  elseif GAME.score == 285 then
    init_level_10()
  elseif GAME.score == 315 then
    init_level_11()
  elseif GAME.score == 335 then
    init_level_12()
  end
  
end



function check_lose(planets)
  local empty = true
  local planets= g2.search("planet owner:"..GAME.player)
  --local fleets = g2.search("fleet owner:"..GAME.player)
  
  if #planets == 0 then --and #fleets == 0 then
    init_lose()
    g2.state = "pause"
  end
end


function init_lose()
  --g2.game_reset()
  local highscore = MEMORY.highscore
  
  
  GAME.dead = true
  
  if GAME.score > MEMORY.highscore then
    g2.html = "" ..
    "<table>"..
    "<tr><td><h1>NEW HIGH SCORE!</h1>"..
    "<tr><td><h1>score: ".. GAME.score.."</h1>"..
    "<tr><td><h1>old high score: ".. MEMORY.highscore .."</h1>"..
    "<tr><td><input type='button' value='Reset High Score' onclick='resetscore' />"..
    "<tr><td><input type='button' value='Get Better' onclick='restart' />"..
    "";
    MEMORY.highscore = GAME.score
    g2.data = json.encode(MEMORY)
  else
    g2.html = "" ..
    "<table>"..
    "<tr><td><h1>GAME OVER</h1>"..
    "<tr><td><h1>score: ".. GAME.score.."</h1>"..
    "<tr><td><h1>high score: ".. MEMORY.highscore .."</h1>"..
    "<tr><td><input type='button' value='Reset High Score' onclick='resetscore' />"..
    "<tr><td><input type='button' value='Try Again' onclick='restart' />"..
    "";
  end
  


  
  -- todo: add reset highscore option
end

function event(e)
  local levelbutton = ""
  if MEMORY.highscore >= 125 then
    levelbutton = "<table><tr><td><input type='button' value='Level 5' onclick='level5' />"
  end
  if MEMORY.highscore >= 285 then
    levelbutton = levelbutton.."<table><tr><td><input type='button' value='Level 10' onclick='level10' />"
  end
  
  if e.type == "pause" then
      g2.state = "pause"
      g2.html = "<table><tr><td><input type='button' value='Resume' onclick='resume' />"..
      "<tr><td><input type='button' value='Restart' onclick='restart' />"..
      levelbutton
       
  end
    
  if e.type == "onclick" and e.value == "restart" then
    g2.state = "play"
    init_game()
  end
  
  if (e["type"] == "onclick" and e["value"] == "resume") then
      g2.state = "play"
  end
  
  
  if (e["type"] == "onclick" and e["value"] == "resetscore") then
      MEMORY.highscore = 0
      g2.data = json.encode(MEMORY)
      GAME.score = 0
      init_lose()
  end
  
  
  if (e["type"] == "onclick" and e["value"] == "level5") then
      GAME.score = 124
      g2.state = "play"
  end
  if (e["type"] == "onclick" and e["value"] == "level10") then
      GAME.score = 284
      g2.state = "play"
  end

end




-- TODO REWRITE LATER --

function bot_loop(user, can_redirect)
    local p = 90
    local r = math.random(0,10)

    local from_planets = g2.search("planet owner:"..user) -- search for all planets owned by the bot
    local best_value = -math.huge  -- haven't found a good planet yet, so set the best value so far to -infinity
    local from                                            
    for _i,planet in ipairs(from_planets) do
        if planet.ships_value > best_value and planet.ships_value >= r then -- find the planet with the most 
            from = planet
            best_value = planet.ships_value
        end
    end
    if from ~= nil then -- make sure a planet to attack from was found
        local to_planets = g2.search("planet -team:"..user:team()) -- 
        best_value = -math.huge
        local to
        for _i,planet in ipairs(to_planets) do
            local value = -planet.ships_value + planet.ships_production - planet:distance(from)/5
            
            if GAME.direction == -1 then -- TESTING
              value = value + planet.position_y * 10 / OPTIONS.screen_height
            else
              value = value - planet.position_y * 10 / OPTIONS.screen_height
            end

        if planet.ships_value / 3 >= from.ships_value then
          value = 0 -- TEST: don't attack planets with too many ships
        end
        
        if value > best_value then
            to = planet
            best_value = value
        end
            
        end
        if to ~= nil then from:fleet_send(p, to) end  -- if a good planet to attack was found, attack it
        
        --TEST:
        if can_redirect then
          if GAME.redir ~= GAME.score then
            do_redirect(user)
            GAME.redir = GAME.score
          end
        end
    end
end



-- from mod_classic

function do_redirect(user)
    local fleets = g2.search("fleet owner:"..user);
    for _i,from in ipairs(fleets) do
        to = find_normal(user,from)
        if (to ~= nil and to ~= from) then
            from:fleet_redirect(to)
        end
    end
end

-- TODO: use one global target planet find function
function find_normal(user,from)
    local r = math.random(0,10) -- hack for better performance
    local planets = {}
    if r == 1 then
      planets = g2.search("planet")
    else
      planets = g2.search("planet -team:"..user:team())
    end
    
    local to = nil; local to_v = 0;
    

    for _i,p in ipairs(planets) do
        local d = from:distance(p)
        local v = -p.ships_value + p.ships_production - d * 0.20

        
        if GAME.direction == -1 then -- TESTING
          v = v + p.position_y * 10 / OPTIONS.screen_height
        else
          v = v - p.position_y * 10 / OPTIONS.screen_height
        end
        

        if p:owner() == user then
          local is_attacked = false
          local fleets = g2.search("fleet -owner:"..user)
          for _i,f in ipairs(fleets) do
            if f.fleet_target == p.n then
              is_attacked = true
               
            end
          end
          if is_attacked == false then
            v = 0
          else
            v = v + 10
          end
        end
        
        
        if (to==nil or v > to_v) then
            to_v = v;
            to = p;
        end
    end
    return to
end



-- add redirection to defend