require("mod_tictactoestate")
require("mod_mcts")

LICENSE = [[]]
strict(true)
if g2.headless == nil then
    require("mod_client") -- HACK: not a clean import, but it works
end

function menu_init()
    GAME.modules.menu = GAME.modules.menu or {}
    local obj = GAME.modules.menu
    function obj:init()
        g2.html =
            [[
            <table>
            <tr><td colspan=2><h1>Tic Tac Toe MCTS Bot Demo Server</h1>
            <tr><td><p>&nbsp;</p>
            <tr><td><input type='text' name='port' value='$PORT' />
            <tr><td><p>&nbsp;</p>
            <tr><td><input type='button' value='Start Server' onclick='host' />"
            </table>
            ]]
        GAME.data = json.decode(g2.data)
        if type(GAME.data) ~= "table" then
            GAME.data = {}
        end
        g2.form.port = GAME.data.port or "23099"
        g2.state = "menu"
    end
    function obj:loop(t)
    end
    function obj:event(e)
        if e.type == "onclick" and e.value == "host" then
            GAME.data.port = g2.form.port
            g2.data = json.encode(GAME.data)
            g2.net_host(GAME.data.port)
            GAME.engine:next(GAME.modules.lobby)
            if g2.headless == nil then
                g2.net_join("", GAME.data.port)
            end
        end
    end
end
--------------------------------------------------------------------------------
function clients_queue()
    local colors = {
        0x0000ff
    }
    local q = nil
    for k, e in pairs(GAME.clients) do
        if e.status == "away" or e.status == "queue" then
            e.color = 0x555555
        end
        if e.status == "queue" then
            q = e
        end
        for i, v in pairs(colors) do
            if v == e.color then
                colors[i] = nil
            end
        end
    end
    if q == nil then
        return
    end
    for i, v in pairs(colors) do
        if v ~= nil then
            q.color = v
            q.status = "play"
            net_send("", "message", q.name .. " is /play")
            return
        end
    end
end
function clients_init()
    GAME.modules.clients = GAME.modules.clients or {}
    GAME.clients = GAME.clients or {}
    local obj = GAME.modules.clients
    function obj:event(e)
        if e.type == "net:join" then
            GAME.clients[e.uid] = {uid = e.uid, name = e.name, status = "queue"}
            clients_queue()
            net_send("", "message", e.name .. " joined")
            g2.net_send("", "sound", "sfx-join")
        end
        if e.type == "net:leave" then
            GAME.clients[e.uid] = nil
            net_send("", "message", e.name .. " left")
            g2.net_send("", "sound", "sfx-leave")
            clients_queue()
        end
        if e.type == "net:message" and e.value == "/play" then
            if GAME.clients[e.uid].status == "away" then
                GAME.clients[e.uid].status = "queue"
                clients_queue()
            end
        end
        if e.type == "net:message" and e.value == "/away" then
            if GAME.clients[e.uid].status == "play" then
                GAME.clients[e.uid].status = "away"
                clients_queue()
                net_send("", "message", e.name .. " is /away")
            end
        end
        if e.type == "net:message" and e.value == "/who" then
            local msg = ""
            for _, c in pairs(GAME.clients) do
                msg = msg .. c.name .. ", "
            end
            net_send(e.uid, "message", "/who: " .. msg)
        end
    end
end
--------------------------------------------------------------------------------
function params_set(k, v)
    GAME.params[k] = v
    net_send("", k, v)
end
function params_init()
    GAME.modules.params = GAME.modules.params or {}
    GAME.params = GAME.params or {}
    GAME.params.state = GAME.params.state or "lobby"
    GAME.params.html = GAME.params.html or ""
    local obj = GAME.modules.params
    function obj:event(e)
        if e.type == "net:join" then
            net_send(e.uid, "state", GAME.params.state)
            net_send(e.uid, "html", GAME.params.html)
            net_send(e.uid, "tabs", GAME.params.tabs)
        end
    end
end
--------------------------------------------------------------------------------
function chat_init()
    GAME.modules.chat = GAME.modules.chat or {}
    GAME.clients = GAME.clients or {}
    local obj = GAME.modules.chat
    function obj:event(e)
        if e.type == "net:message" then
            net_send(
                "",
                "chat",
                json.encode(
                    {
                        uid = e.uid,
                        color = GAME.clients[e.uid].color,
                        value = "<" .. GAME.clients[e.uid].name .. "> " .. e.value
                    }
                )
            )
        end
    end
end
--------------------------------------------------------------------------------
local menu_html =
    [[
    <table><tr><td colspan=2><h1>TicTacToe MCTS Bot Demo</h1>
    <tr><td colspan=2><p>Mod by esparano</p>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>Lobby ... enter /start to play!</p>
    <tr><td><p>Change difficulty with /easy, /medium, /hard</p>
    <tr><td><p>View difficulty with /difficulty</p>
    <tr><td><p>You can change difficulty mid-game</p>
    <tr><td><p>&nbsp;</p>
    <tr><td><p>I'm probably not here.</p>
    </table>
]]

function lobby_init()
    GAME.modules.lobby = GAME.modules.lobby or {}
    local obj = GAME.modules.lobby
    function obj:init()
        g2.state = "lobby"
        params_set("state", "lobby")
        params_set("tabs", "<table class='box' width=160><tr><td><h2>WELCOME</h2></table>")
        params_set("html", menu_html)
    end
    function obj:loop(t)
    end
    function obj:event(e)
        run_difficulty_commands(e)
        if e.type == "net:message" and e.value == "/start" then
            GAME.engine:next(GAME.modules.galcon)
        end
    end
end
--------------------------------------------------------------------------------
local function deepCopy(o)
    if type(o) ~= "table" then
        return o
    end
    local r = {}
    for k, v in pairs(o) do
        r[k] = deepCopy(v)
    end
    return r
end

function update_stats()
    GAME.total = GAME.total + 1
    local stats = {}
    for name,total in pairs(GAME.wins) do
        stats[#stats+1] = {name,total}
    end
    table.sort(stats,function(a,b) return a[2] > b[2] end)
    local info = ""
    for i,item in ipairs(stats) do
        info = info .. item[1] .. ":" .. tostring(item[2]) .. "  "
    end
    local function gprint(msg)
        print("["..tostring(GAME.total).."] "..msg)
    end
    gprint(info)
end

function galcon_classic_init()
    local G = GAME.galcon
    math.randomseed(os.time())

    g2.game_reset()

    local o = g2.new_user("neutral", 0x555555)
    o.user_neutral = 1
    o.ships_production_enabled = 0
    G.neutral = o

    local users = {}
    G.users = users

    for uid, client in pairs(GAME.clients) do
        if client.status == "play" then
            local p = g2.new_user(client.name, client.color)
            users[#users + 1] = p
            p.user_uid = client.uid
            client.live = 0
        end
    end
    if #users < 1 then
        galcon_stop(nil, true)
        return
    end

    local sw = 480
    local sh = 320

    GAME.galcon.grid_planets = {}
    for i = 1, 3 do
        for j = 1, 3 do
            local p = g2.new_planet(o, i / 4 * sw, j / 4 * sh, 100, 0)
            GAME.galcon.grid_planets["" .. i .. j] = p
        end
    end
    for i = 1, 4 do
        local loc = (i / 4 - 1 / 8)
        local left = 1 / 8
        local right = 7 / 8
        g2.new_line(0xffffff, loc * sw, left * sh, loc * sw, right * sh)
        g2.new_line(0xffffff, left * sw, loc * sh, right * sw, loc * sh)
    end

    for i, user in pairs(users) do
        user.ships_production_enabled = 0
        user.ui_ships_show_mask = 0xf
        user.fleet_v_factor = 8
        user.ui_to_mask = 0x6
        user.ui_fleet_redirect = false
        G.player_user = user
        G.player_planet = g2.new_planet(user, 0, sh / 2, 100, 0)
    end

    local enemy = g2.new_user("MCTS BOT", 0xff0000)
    enemy.ships_production_enabled = 0
    enemy.fleet_v_factor = 5
    G.enemy_user = enemy
    G.enemy_planet = g2.new_planet(enemy, sw, sh / 2, 100, 0)

    local initialState = TicTacToeState.new()
    local mcts = Mcts.new(deepCopy)
    G.state = initialState
    G.mcts = mcts

    G.player_first = math.random() < 0.5

    g2.net_send("", "sound", "sfx-start")
end

function galcon_stop(winner_user, aborted)
    if winner_user then
        net_send("", "message", winner_user.title_value .. " won")
        local name = winner_user.title_value
        GAME.wins[name] = (GAME.wins[name] or 0) + 1
        update_stats()
    elseif aborted then
        net_send("", "message", "Game aborted")
    else
        net_send("", "message", "Game drawn")
        update_stats()
    end
   
    g2.net_send("", "sound", "sfx-stop")
    GAME.engine:next(GAME.modules.lobby)
end

function loop_delete_grid_ships()
    for n, p in pairs(g2.search("planet")) do
        if p ~= GAME.galcon.player_planet and p ~= GAME.galcon.enemy_planet then
            p.ships_value = 0
        end
    end
end

function is_player_turn()
    local total = 0
    for n, p in pairs(g2.search("planet neutral")) do
        total = total + 1
    end
    return (total % 2 == 0) ~= GAME.galcon.player_first
end

function loop_give_ships()
    for n, p in pairs(g2.search("fleet")) do
        -- if there are any fleets, don't give any more ships out
        return
    end
    if is_player_turn() then
        GAME.galcon.player_planet.ships_value = 1
    else
        GAME.galcon.enemy_planet.ships_value = 1
    end
end

function loop_update_state()
    local G = GAME.galcon
    local available_actions = G.state:getAvailableActions():getValues()
    for action, available in pairs(available_actions) do
        if not G.grid_planets[action]:owner().user_neutral then
            G.state:applyAction(action)
        end
    end
end

function loop_determine_winner()
    local G = GAME.galcon
    if G.state:somePlayerWon() then
        local first_player = G.state._players[TicTacToeState.CROSS]
        if G.state:specificPlayerWon(first_player) == G.player_first then
            return G.player_user
        else
            return G.enemy_user
        end
    end
    return nil
end

function get_num_iterations()
    if GAME.difficulty == "easy" then
        return 50
    elseif GAME.difficulty == "medium" then
        return 100
    else
        return 600
    end
end

function galcon_classic_loop(t)
    local G = GAME.galcon
    loop_update_state()
    if G.state:isTerminal() then
        local WIN_TIMEOUT = 3
        G.win_timeout = G.win_timeout or WIN_TIMEOUT
        G.win_timeout = G.win_timeout - t
        if G.win_timeout < 0 then
            G.win_timeout = WIN_TIMEOUT
            local winner = loop_determine_winner()
            galcon_stop(winner)
        end
        return
    end
    loop_delete_grid_ships()
    loop_give_ships()

    if G.enemy_planet.ships_value == 1 then
        local EXPLORATION_PARAMETER = 0.4
        local NUM_ITERATIONS = get_num_iterations()
        G.mcts:startUtcSearch(G.state, EXPLORATION_PARAMETER)
        for i = 1, NUM_ITERATIONS do
            G.mcts:nextIteration()
        end
        local chosenAction = G.mcts:finish()
        local chosenPlanet = G.grid_planets[chosenAction]
        g2_fleet_send(100, G.enemy_planet.n, chosenPlanet.n)
        G.state:applyAction(chosenAction)
    end
end

function find_user(uid)
    for n, e in pairs(g2.search("user")) do
        if e.user_uid == uid then
            return e
        end
    end
end

function galcon_surrender(uid)
    galcon_stop(nil, true)
end

function changeDifficulty(d)
    GAME.difficulty = d
    local message = "difficulty is set to " .. GAME.difficulty
    net_send("", "message", message)
end

function run_difficulty_commands(e)
    if e.type == "net:message" and e.value == "/easy" then
        changeDifficulty("easy")
    end
    if e.type == "net:message" and e.value == "/medium" then
        changeDifficulty("medium")
    end
    if e.type == "net:message" and e.value == "/hard" then
        changeDifficulty("hard")
    end
    if e.type == "net:message" and e.value == "/difficulty" then
        changeDifficulty(GAME.difficulty)
    end
end

function galcon_init()
    GAME.modules.galcon = GAME.modules.galcon or {}
    GAME.galcon = GAME.galcon or {}
    GAME.difficulty = "hard"
    GAME.wins = {}
    GAME.total = 0
    local obj = GAME.modules.galcon
    function obj:init()
        g2.state = "play"
        params_set("state", "play")
        params_set(
            "html",
            [[<table>
            <tr><td><input type='button' value='Resume' onclick='resume' />
            <tr><td><input type='button' value='Surrender' onclick='/surrender' />
            </table>]]
        )
        galcon_classic_init()
    end
    function obj:loop(t)
        galcon_classic_loop(t)
    end
    function obj:event(e)
        run_difficulty_commands(e)
        if e.type == "net:message" and e.value == "/abort" then
            galcon_stop(nil, true)
        end
        if e.type == "net:leave" then
            galcon_surrender(e.uid)
        end
        if e.type == "net:message" and e.value == "/surrender" then
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
        if GAME.module == GAME.modules.menu then
            return
        end
        self.t = self.t - t
        if self.t < 0 then
            self.t = 60
            g2_api_call("register", json.encode({title = "Tic Tac Toe Bot", port = GAME.data.port}))
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
        if g2.headless then
            GAME.data = {port = g2.port}
            g2.net_host(GAME.data.port)
            GAME.engine:next(GAME.modules.lobby)
        else
            self:next(GAME.modules.menu)
        end
    end

    function obj:event(e)
        --         print("engine:"..e.type)
        GAME.modules.clients:event(e)
        GAME.modules.params:event(e)
        GAME.modules.chat:event(e)
        GAME.module:event(e)
        if e.type == "onclick" then
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
    GAME = GAME or {}
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
end
--------------------------------------------------------------------------------
function init()
    GAME.engine:init()
end
function loop(t)
    GAME.engine:loop(t)
end
function event(e)
    GAME.engine:event(e)
end
--------------------------------------------------------------------------------
function net_send(uid, mtype, mvalue) -- HACK - to make headed clients work
    if g2.headless == nil and (uid == "" or uid == g2.uid) then
        GAME.modules.client:event({type = "net:" .. mtype, value = mvalue})
    end
    g2.net_send(uid, mtype, mvalue)
end
--------------------------------------------------------------------------------
mod_init()
print(g2.name)
print(g2.uid)
