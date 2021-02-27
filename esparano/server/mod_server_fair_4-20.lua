require("mod_elo")
require("mod_memoize")

--------------------------------------------------------------------------------
if g2.headless == nil then
    require("mod_client") -- HACK: not a clean import, but it works
end
--------------------------------------------------------------------------------
function menu_init()
    GAME.modules.menu = GAME.modules.menu or {}
    local obj = GAME.modules.menu
    function obj:init()
        g2.html =
            [[
            <table>
            <tr><td colspan=2><h1>Galcon 2 Fair</h1>
            <tr><td colspan=2><h1>Nonsymmetric 1v1</h1>
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
    _clients_queue()
    resetLobbyHtml()
end

function _clients_queue()
    --0x82cafa
    local colors = {
        0x0000ff,
        0xff0000
        -- 0xff0000,
        -- 0xffff00,
        -- 0x00ffff,
        -- 0xffffff,
        -- 0xff8800,
        -- 0x99ff99,
        -- 0xff9999,
        -- 0xbb00ff,
        -- 0xff88ff,
        -- 0x9999ff,
        -- 0x00ff00
    }
    colors = {
        0x82cafa,
        0xff69b4
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

-- TODO: set player away if they didn't move all game.

function clients_init()
    GAME.modules.clients = GAME.modules.clients or {}
    GAME.clients = GAME.clients or {}
    local obj = GAME.modules.clients
    function obj:event(e)
        if e.type == "net:join" then
            GAME.clients[e.uid] = {uid = e.uid, name = e.name, status = "queue"}
            clients_queue()
            net_send("", "message", e.name .. " joined")
            play_sound("sfx-join")
            resetChatKeywords()
        end
        if e.type == "net:leave" then
            GAME.clients[e.uid] = nil
            net_send("", "message", e.name .. " left")
            play_sound("sfx-leave")
            clients_queue()
            resetChatKeywords()
        end
        -- Do anything with chat_enabled messages?
        if isNetMessageOrButton(e) then
            if matchesCommand(e.value, "play") then
                local uid = getEventUid(e)
                if GAME.clients[uid].status ~= "play" then
                    GAME.clients[uid].status = "queue"
                    clients_queue()
                end
            end
            if matchesCommand(e.value, "away") then
                local uid = getEventUid(e)
                if GAME.clients[uid].status ~= "away" then
                    GAME.clients[uid].status = "away"
                    clients_queue()
                    net_send("", "message", GAME.clients[uid].name .. " is /away")
                end
            end
            if matchesCommand(e.value, "awayall") then
                for k, e in pairs(GAME.clients) do
                    e.status = "away"
                    clients_queue()
                end
            end
            if matchesCommand(e.value, "analyze") or matchesCommand(e.value, "analyse") or matchesCommand(e.value, "analysis") then
                GAME.params.analysis.enabled = not GAME.params.analysis.enabled
                net_send("", "message", "Live game analysis is " .. analysisText(GAME.params.analysis.enabled))
            end
            if matchesCommand(e.value, "who") then
                local uid = getEventUid(e)
                local m = ""
                for _, c in pairs(GAME.clients) do
                    m = m .. c.name .. ", "
                end
                net_send(uid, "message", "/who: " .. m)
            end
            if matchesCommand(e.value, "elo") then
                local uid = getEventUid(e)
                -- TODO: this doesn't work for ME
                net_send(uid, "message", "Your elo is " .. round(elo.get_elo(e.name)))
            end
            if matchesCommand(e.value, "matchup") then
                local uid = getEventUid(e)
                local player1Name, player2Name, winPercent = getMatchupPercentage()
                if winPercent ~= nil then
                    local prettyPercent = round(winPercent * 100)
                    net_send(uid, "message", "The predicted win rate for " .. player1Name .. " vs. " .. player2Name .. " is " .. prettyPercent .. "%")
                end
            end
            if matchesCommand(e.value, "sym") then
                GAME.params.gen.SYM = true
                net_send("", "message", "symmetry is ENABLED")
            end
            if matchesCommand(e.value, "asym") then
                GAME.params.gen.SYM = false
                net_send("", "message", "symmetry is DISABLED")
            end

            if matchesCommand(e.value, "settings") then
                local uid = getEventUid(e)
                net_send(uid, "message", "/planets " .. GAME.params.gen.NUM_PLANETS 
                                    .. ", /minProd " .. GAME.params.gen.MIN_NEUTRAL_PROD 
                                    .. ", /maxProd " .. GAME.params.gen.MAX_NEUTRAL_PROD 
                                    .. ", /minCost " .. GAME.params.gen.MIN_NEUTRAL_COST 
                                    .. ", /maxCost " .. GAME.params.gen.MAX_NEUTRAL_COST
                )
            end 
            if matchesCommand(searchString(e.value, "[%S]+")[1], "planets") then
                local commandParts = searchString(e.value, "%S+")
                local newVal = tonumber(commandParts[2])
                if newVal ~= nil and newVal <= GAME.params.gen.MAX_ALLOWED_NUM_PLANETS and newVal >= GAME.params.gen.MIN_ALLOWED_NUM_PLANETS then
                    GAME.params.gen.NUM_PLANETS = newVal
                    resetLobbyHtml()
                    net_send("", "message", "Number of planets set to " .. newVal)
                else
                    local uid = getEventUid(e)
                    net_send(uid, "message", "Please enter a valid number between " .. GAME.params.gen.MIN_ALLOWED_NUM_PLANETS .. " and " .. GAME.params.gen.MAX_ALLOWED_NUM_PLANETS)
                end
            end
            if matchesCommand(searchString(e.value, "[%S]+")[1], "minProd") then
                local commandParts = searchString(e.value, "%S+")
                local newVal = tonumber(commandParts[2])
                if newVal ~= nil and newVal <= GAME.params.gen.MAX_ALLOWED_MIN_NEUTRAL_PROD and newVal >= GAME.params.gen.MIN_ALLOWED_MIN_NEUTRAL_PROD then
                    GAME.params.gen.MIN_NEUTRAL_PROD = newVal
                    resetLobbyHtml()
                    net_send("", "message", "Min neutral production set to " .. newVal)
                else
                    local uid = getEventUid(e)
                    net_send(uid, "message", "Please enter a valid number between " .. GAME.params.gen.MIN_ALLOWED_MIN_NEUTRAL_PROD .. " and " .. GAME.params.gen.MAX_ALLOWED_MIN_NEUTRAL_PROD)
                end
            end 
            if matchesCommand(searchString(e.value, "[%S]+")[1], "maxProd") then
                local commandParts = searchString(e.value, "%S+")
                local newVal = tonumber(commandParts[2])
                if newVal ~= nil and newVal <= GAME.params.gen.MAX_ALLOWED_MAX_NEUTRAL_PROD and newVal >= GAME.params.gen.MIN_ALLOWED_MAX_NEUTRAL_PROD then
                    GAME.params.gen.MAX_NEUTRAL_PROD = newVal
                    resetLobbyHtml() 
                    net_send("", "message", "Max neutral production set to " .. newVal)
                else
                    local uid = getEventUid(e)
                    net_send(uid, "message", "Please enter a valid number between " .. GAME.params.gen.MIN_ALLOWED_MAX_NEUTRAL_PROD .. " and " .. GAME.params.gen.MAX_ALLOWED_MAX_NEUTRAL_PROD)
                end
            end
            if matchesCommand(searchString(e.value, "[%S]+")[1], "minCost") then
                local commandParts = searchString(e.value, "%S+")
                local newVal = tonumber(commandParts[2])
                if newVal ~= nil and newVal <= GAME.params.gen.MAX_ALLOWED_MIN_NEUTRAL_COST and newVal >= GAME.params.gen.MIN_ALLOWED_MIN_NEUTRAL_COST then
                    GAME.params.gen.MIN_NEUTRAL_COST = newVal
                    resetLobbyHtml()
                    net_send("", "message", "Min neutral cost set to " .. newVal)
                else
                    local uid = getEventUid(e)
                    net_send(uid, "message", "Please enter a valid number between " .. GAME.params.gen.MIN_ALLOWED_MIN_NEUTRAL_COST .. " and " .. GAME.params.gen.MAX_ALLOWED_MIN_NEUTRAL_COST)
                end
            end
            if matchesCommand(searchString(e.value, "[%S]+")[1], "maxCost") then
                local commandParts = searchString(e.value, "%S+")
                local newVal = tonumber(commandParts[2])
                if newVal ~= nil and newVal <= GAME.params.gen.MAX_ALLOWED_MAX_NEUTRAL_COST and newVal >= GAME.params.gen.MIN_ALLOWED_MAX_NEUTRAL_COST then
                    GAME.params.gen.MAX_NEUTRAL_COST = newVal
                    resetLobbyHtml()
                    net_send("", "message", "Max neutral cost set to " .. newVal)
                else
                    local uid = getEventUid(e)
                    net_send(uid, "message", "Please enter a valid number between " .. GAME.params.gen.MIN_ALLOWED_MAX_NEUTRAL_COST .. " and " .. GAME.params.gen.MAX_ALLOWED_MAX_NEUTRAL_COST)
                end
            end

            if matchesCommand(e.value, "m") or matchesCommand(searchString(e.value, "[%S]+")[1], "msg") then
                local commandParts = searchString(e.value, "%S+")

                local toPlayerName = commandParts[2]

                local message = ""
                for i = 3, #commandParts do
                    message = message .. " " .. commandParts[i]
                end

                processChatPm(e, toPlayerName, message)
            end
            if matchesCommand(e.value, "r") or matchesCommand(searchString(e.value, "[%S]+")[1], "reply") then
                local commandParts = searchString(e.value, "%S+")

                local toPlayerName = GAME.modules.chat.replyUsers[e.name]

                local message = ""
                for i = 2, #commandParts do
                    message = message .. " " .. commandParts[i]
                end
                processChatPm(e, toPlayerName, message)
            end
        end
    end
end

function processChatPm(e, toPlayerName, message)
    if message == nil or message == "" or toPlayerName == nil then
        return
    end

    local fromUid = getEventUid(e)

    local toPlayerUid
    for _, c in pairs(GAME.clients) do
        if toPlayerName:lower() == c.name:lower() then
            toPlayerUid = c.uid
            toPlayerName = c.name
            break
        end
    end

    if toPlayerUid ~= nil then
        local msg = "(" .. e.name .. " -> " .. toPlayerName .. ")" .. message
        GAME.modules.chat.replyUsers[toPlayerName] = e.name
        net_send(
            toPlayerUid,
            "chat",
            json.encode(
                {
                    uid = fromUid,
                    color = GAME.clients[fromUid].color,
                    value = msg
                }
            )
        )
        net_send(
            fromUid, -- who to send to
            "chat",
            json.encode(
                {
                    uid = fromUid, -- who sent the message (used for ping calculations etc)
                    color = GAME.clients[fromUid].color,
                    value = msg
                }
            )
        )
    else
        local undeliverableMsg = "Undelivered @" .. toPlayerName .. ": " .. message
        local msg = "(" .. e.name .. " -> " .. e.name .. ") " .. undeliverableMsg
        net_send(
            fromUid,
            "chat",
            json.encode(
                {
                    uid = fromUid,
                    color = GAME.clients[fromUid].color,
                    value = msg
                }
            )
        )
    end
end

function getEventUid(e)
    if e.type == "net:message" then
        return e.uid
    else
        -- any unintended consequences?
        return g2.uid
    end
end

function resetChatKeywords()
    local keywords = {}
    for _, e in pairs(GAME.clients) do
        table.insert(keywords, e.name)
    end
    for _, c in pairs(getAllPublicCommands()) do
        table.insert(keywords, "/" .. c)
    end
    for _, c in pairs(getAllPublicCommands()) do
        table.insert(keywords, "." .. c)
    end
    -- no need for tab completion on single character commands
    local encodedKeywords = json.encode(keywords)
    g2.chat_keywords(encodedKeywords)
    net_send("", "keywords", encodedKeywords)
end

function getAllPublicCommands()
    return {
        "help", -- TODO
        "play",
        "away",
        "who",
        "help",
        "ladder",
        "elo",
        "matchup",
        "analyze",
        "redo",
        "start",
        "swap",
        "surrender",
        "msg",
        "reply",
        "sym",
        "asym",
        "planets",
        "minProd",
        "maxProd",
        "minCost",
        "maxCost",
        "banishSelf"
    }
end

function getAllPrivateCommands()
    return {
        "awayall",
        "tab1",
        "tab2",
        "abort",
        "analyse", "analysis",
        "m",
        "r"
    }
end

function matchesCommand(string, searchCommand)
    if string == nil then
        return false
    end
    local justCommand = searchString(string, "%S+")[1]
    if justCommand == nil then
        return false
    end
    if justCommand == "." .. searchCommand or justCommand == "/" .. searchCommand then
        return true
    end
    -- single letter commands don't need the . or /
    if justCommand:len() == 1 and justCommand == searchCommand then
        return true
    end
    return false
end

function isCommand(e)
    for i, c in pairs(getAllPublicCommands()) do
        if matchesCommand(e.value, c) then
            return true
        end
    end
    for i, c in pairs(getAllPrivateCommands()) do
        if matchesCommand(e.value, c) then
            return true
        end
    end
    return false
end

function analysisText(enabled)
    if enabled then
        return "ON"
    else
        return "OFF"
    end
end

-- TODO: sets and lifetime stats

function getMatchupPercentage(uid)
    local player1 = nil
    local player2 = nil
    for k, e in pairs(GAME.clients) do
        if e.status == "play" then
            if player1 == nil then
                player1 = e.name
            elseif player2 == nil then
                player2 = e.name
            end
        end
    end
    if player1 ~= nil and player2 ~= nil then
        return player1, player2, elo.player_win_probability(player1, player2)
    end
end

function round(v)
    return math.floor(v + 0.5)
end
--------------------------------------------------------------------------------
function params_set(k, v)
    GAME.params[k] = v
    net_send("", k, v)
end
-- TODO: eliminate need for elo button by putting each user's rating at the top of THEIR lobby HTML
local SHIP_RADIUS = 6
function params_init()
    GAME.modules.params = GAME.modules.params or {}
    GAME.params = GAME.params or {}
    GAME.params.state = GAME.params.state or "lobby"
    GAME.params.registerServer = true
    GAME.params.html = GAME.params.html or ""
    GAME.params.gen = {
        HOME_DIST_TO_EDGE = 0.65,
        MIN_MAP_WIDTH = 300,
        MIN_MAP_HEIGHT = 200,
        MAP_WIDTH_20 = 600,
        MAP_HEIGHT_20 = 400,

        MAX_PLAYERS = 2,

        NUM_PLANETS = 24,
        MIN_ALLOWED_NUM_PLANETS = 1,
        MAX_ALLOWED_NUM_PLANETS = 60,

        MIN_NEUTRAL_PROD = 20,
        MIN_ALLOWED_MIN_NEUTRAL_PROD = 5,
        MAX_ALLOWED_MIN_NEUTRAL_PROD = 200,

        MAX_NEUTRAL_PROD = 100,
        MIN_ALLOWED_MAX_NEUTRAL_PROD = 5,
        MAX_ALLOWED_MAX_NEUTRAL_PROD = 200,

        MIN_NEUTRAL_COST = 0,
        MIN_ALLOWED_MIN_NEUTRAL_COST = 0,
        MAX_ALLOWED_MIN_NEUTRAL_COST = 200,

        MAX_NEUTRAL_COST = 30,
        MIN_ALLOWED_MAX_NEUTRAL_COST = 0,
        MAX_ALLOWED_MAX_NEUTRAL_COST = 200,

        FAIRNESS_TOLERANCE_INCREASE = 1.0005,
        MAX_GENERATION_ATTEMPTS = 100,
        MAX_SWEETENING_ITERATIONS = 200,
        SYM = true
    }
    GAME.params.analysis = {
        enabled = true
    }

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
    obj.replyUsers = {}
    function obj:event(e)
        if e.type == "net:message" and not isCommand(e) and not isEmpty(e.value) then
            net_send(
                "",
                "chat",
                json.encode({uid = e.uid, color = GAME.clients[e.uid].color, value = "<" .. GAME.clients[e.uid].name .. "> " .. e.value})
            )
        end
    end
end

function isEmpty(s)
    return s == nil or s:match("%S") == nil
end
--------------------------------------------------------------------------------
function lobby_init()
    GAME.modules.lobby = GAME.modules.lobby or {}
    local obj = GAME.modules.lobby
    function obj:init()
        self.startTimerLength = 3
        self.startTimer = 1000
        g2.state = "lobby"
        params_set("state", "lobby")
        resetLobbyHtml()
    end
    function obj:loop(t)
        self.startTimer = self.startTimer + t

        if self.startTimer >= 0 and self.startTimer < self.startTimerLength then
            if math.floor(self.startTimer) >= self.countDown then
                play_sound("sfx-getready")
                net_send("", "message", ">> T-minus " .. (3 - self.countDown) .. " <<")
                self.countDown = self.countDown + 1
            end
        end

        if self.startTimer >= self.startTimerLength and self.startTimer < 1000 then
            GAME.engine:next(GAME.modules.galcon)
        end
    end
    function obj:event(e)
        if isNetMessageOrButton(e) and isStartEvent(e) and self.startTimer >= 1000 then
            net_send("", "message", toStartEventDescription(e))
            GAME.modules.galcon.startMode = e.value
            self.startTimer = 0
            self.countDown = 0
        end
    end
end

function searchString(string, pattern)
    local words = {}
    for word in string:gmatch(pattern) do
        table.insert(words, word)
    end
    return words
end

function splitToTokens(command)
    if command == nil then
        return
    end
    return searchString(command, "[%S]+")
end

function toStartEventDescription(e)
    if matchesCommand(splitToTokens(e.value)[1], "start") then
        return "STARTING GAME!"
    elseif matchesCommand(e.value, "redo") then
        return "REDOING GAME!"
    elseif matchesCommand(e.value, "swap") then
        return "SWAPPING SIDES!"
    end
    return ""
end

function isStartEvent(e)
    return toStartEventDescription(e) ~= ""
end

function resetLobbyHtml()
    if g2.state ~= "lobby" then
        return
    end
    params_set(
        "tabs",
        [[
                <table class='box' width=160>
                <tr>
                    <td><input type='button' value='Players' onclick='/players' class="tab0" icon="icon-members" onclick="/tab1" />
                    <td><input type='button' value='Ladder' onclick='/ladder' class="tab" icon="icon-trophy" onclick="/tab2" />
                </table>
            ]]
    )
    params_set(
        "html",
        [[
                <table>
                <tr><td><h2>Fair Asym 1v1
                <tr><td><h4>by esparano
                <tr><td><p>&nbsp;</p>

                <tr><td width=150><input type='button' value='Start Game' onclick='/start' class="toggle1" width=160 />
                <td width=150><input type='button' value='Redo Game' onclick='/redo' class="toggle1" width="160" />
                <td width=150><input type='button' value='Swap Sides' onclick='/swap' class="toggle1" width="160" />
                <tr><td><p>Try /start InsertSeedHere</p>

                <tr><td><p>&nbsp;</p>
                <tr><td width=150><input type='button' value='Sym Mode' onclick='/sym' class="toggle1" width=160 />
                <td width=150><input type='button' value='Asym Mode' onclick='/asym' class="toggle1" width="160" />
                <tr><td><p>Try /planets etc.</p>

                ]]
                ..
                [[
                <tr><td><p>&nbsp;</p>
                <tr><td width=100><input type='button' value='Play' onclick='/play' class="toggle1" width="100" />
                <td width=100><input type='button' value='Away' onclick='/away' class="toggle1" width="100" />

                <tr><td><input type='button' value='My Rating' onclick='/elo' class="toggle1" width=160 />
                <td><input type='button' value='Calc Win Chance' onclick='/matchup' class="toggle1" width=160 />
                <td><input type='button' value='Analyze' onclick='/analyze' class="toggle1" width=160 />
            ]]
            .. 
            getSettings()
            ..
            [[
                <tr><td><p>&nbsp;</p>
                <tr><td><h2>Player List
                <tr><td><h4>PLAY: 
            ]] ..
            getPlayersInState("play") ..
                [[
                <tr><td><p>&nbsp;</p>
                <tr><td><h3>QUEUE: 
            ]] ..
                    getPlayersInState("queue") ..
                        [[
                <tr><td><p>&nbsp;</p>
                <tr><td><h3>AWAY: 
            ]] ..
                            getPlayersInState("away") ..
                                [[
                <tr><td><p>&nbsp;</p>
                <tr><td><h2>Leaderboard
            ]] ..
                                    getLadderTable() .. [[
                </table>
            ]]
    )

    -- <tr><td><p>&nbsp;</p>
    --<div font='font-outline:18' color='#ff8800'>LAdder high <br/>SCORES</div>
end

function getSettings()
    local settings = "<tr><td><h2>SETTINGS:"
        .. "<tr><td><h4>/planets " .. GAME.params.gen.NUM_PLANETS 
        .. "<tr><td><h4>/minProd " .. GAME.params.gen.MIN_NEUTRAL_PROD 
        .. "<tr><td><h4>/maxProd " .. GAME.params.gen.MAX_NEUTRAL_PROD 
        .. "<tr><td><h4>/minCost " .. GAME.params.gen.MIN_NEUTRAL_COST 
        .. "<tr><td><h4>/maxCost " .. GAME.params.gen.MAX_NEUTRAL_COST
    return settings
end

function getPlayersInState(state)
    local players = ""
    for uid, client in pairs(GAME.clients) do
        if client.status == state then
            players = players .. "<tr><td><h4>" .. client.name
        end
    end
    return players
end

function getLadderTable()
    local html = ""

    local ladder = getLadderSorted()

    for k, v in ipairs(ladder) do
        html = html .. "<tr><td><h3>" .. v.username .. "</h3><td>" .. round(v.value)
    end

    html = html .. "</tr></td>"
    return html
end

function getLadderSorted()
    local ladder = {}
    for k, v in pairs(elo.get_elos()) do
        table.insert(ladder, {username = k, value = v})
    end
    table.sort(
        ladder,
        function(a, b)
            return a.value > b.value
        end
    )
    return ladder
end
-------------------------------------------------------------------------------
function angleToVec(a)
    local x = math.cos(a * math.pi / 180.0)
    local y = math.sin(a * math.pi / 180.0)
    return x, y
end
angleToVec = memoize(angleToVec)

--------------------------------------------------------------------------------
function galcon_classic_init(startModeString)
    -- play_sound("sfx-ohyeah")

    local G = GAME.galcon
    local simpleSeedModulus = 100000
    local osTimeSeed = os.time() % simpleSeedModulus
    -- TODO:
    -- ("%X"):format(seed), tonumber(input, 16)

    local seed = GAME.modules.galcon.prevSeed or os.time() % simpleSeedModulus
    local startMode = splitToTokens(startModeString)
    if matchesCommand(startMode[1], "start") then
        if tonumber(startMode[2]) ~= nil then
            seed = tonumber(startMode[2])
        else
            seed = os.time() % simpleSeedModulus
        end
    end
    net_send("", "message", "Map seed: " .. seed)
    GAME.modules.galcon.prevSeed = seed
    math.randomseed(seed)

    g2.game_reset()

    local o = g2.new_user("neutral", 0x555555)
    o.user_neutral = 1
    o.ships_production_enabled = 0
    --[[
    o.planet_style = json.encode({overdraw = {ambient = true, addition = true, texture = "a"}, normal = true, lighting = true, texture = "tex0"})
    --]]
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

    local sw = getMapWidth()
    local sh = getMapHeight()

    local homes = {}
    local a = math.random(0, 360)

    GAME.modules.galcon.swapped = GAME.modules.galcon.swapped or false
    if startMode[1] == "/swap" then
        GAME.modules.galcon.swapped = not GAME.modules.galcon.swapped
    end
    if GAME.modules.galcon.swapped then
        a = a + 360 / #users
    end

    GAME.params.gen.HOME_DIST_TO_EDGE = 0.7
    for i, user in pairs(users) do
        -- TODO: investigate home placement. HOME_DIST_TO_EDGE does NOT seem to work. fuckin weird
        local dx, dy = angleToVec(a)
        local x = (sw / 2) * dx * GAME.params.gen.HOME_DIST_TO_EDGE
        local y = (sh / 2) * dy * GAME.params.gen.HOME_DIST_TO_EDGE
        local home = g2.new_planet(user, x, y, 100, 100)
        table.insert(homes, home)
        a = a + 360 / #users
    end

    -- [[
    local numNeutrals = GAME.params.gen.NUM_PLANETS - #homes
    local time =  os.clock()

    local map

    if GAME.params.gen.SYM then 
        map = generate_sym(homes, numNeutrals)
        print("SYM MAP GENERATION TOOK: " .. os.clock() - time)
    else
        map = generate_fair_asym(homes, numNeutrals, 1.2)
        print("GENERATION TOOK: " .. os.clock() - time)
    end


    for _i, p in ipairs(map) do
        g2.new_planet(o, p.position_x, p.position_y, p.ships_production, p.ships_value)
    end
    --]]

    g2.planets_settle(-sw / 2, -sh / 2, sw, sh)
    setBestView()
    play_sound("sfx-start")
end

function setBestView()
    local left = findLeftMapBound()
    local right = findRightMapBound()
    local top = findTopMapBound()
    local bottom = findBottomMapBound()
    local offsetForAnalysisBars = 40
    g2.view_set(left, top, right - left, bottom - top + offsetForAnalysisBars)
end


function resetBar(obj)
    local bogus = 10000 
    if obj == nil or obj.leftLine == nil then return end
    obj.leftLine.position_x = bogus
    obj.leftLine.position_y = bogus
    obj.leftLine.draw_x2 = bogus
    obj.leftLine.draw_y2 = bogus

    obj.rightLine.position_x = bogus
    obj.rightLine.position_y = bogus
    obj.rightLine.draw_x2 = bogus
    obj.rightLine.draw_y2 = bogus

    obj.midLine.position_x = bogus
    obj.midLine.position_y = bogus
    obj.midLine.draw_x2 = bogus
    obj.midLine.draw_y2 = bogus

    obj.leftLabel.position_x = bogus
    obj.leftLabel.position_y = bogus
    obj.leftLabel.label_text = bogus

    obj.rightLabel.position_x = bogus
    obj.rightLabel.position_y = bogus
    obj.rightLabel.label_text = bogus

    obj.icon.position_x = bogus
    obj.icon.position_y = bogus
end

function findLeftMapBound()
    local p =
        findMax(
        g2.search("planet"),
        function(p)
            return -p.position_x
        end
    )
    return p.position_x - p.planet_r
end
function findRightMapBound()
    local p =
        findMax(
        g2.search("planet"),
        function(p)
            return p.position_x
        end
    )
    return p.position_x + p.planet_r
end
function findTopMapBound()
    local p =
        findMax(
        g2.search("planet"),
        function(p)
            return -p.position_y
        end
    )
    return p.position_y - p.planet_r
end
function findBottomMapBound()
    local p =
        findMax(
        g2.search("planet"),
        function(p)
            return p.position_y
        end
    )
    return p.position_y + p.planet_r
end

function updateBar(obj, offset, frac, t1Color, t2Color, t1LabelText, t2LabelText)
    -- running into issues restartind mod...
    if obj == nil or obj.leftLine == nil or g2.item(obj.leftLine.n) == nil then return end 
    local sw = GAME.params.gen.MAP_WIDTH_20 * math.sqrt(GAME.params.gen.NUM_PLANETS / 20)
    local sh = GAME.params.gen.MAP_HEIGHT_20 * math.sqrt(GAME.params.gen.NUM_PLANETS / 20)

    local stretchFactor = 0.6

    local right = findRightMapBound() - 40
    local left = (findLeftMapBound() + right) / 2
    local indicator = left + (right - left) * frac
    local mid = (right + left) / 2
    local height = findBottomMapBound() + 20 + offset

    obj.leftLine.position_x = left
    obj.leftLine.position_y = height
    obj.leftLine.draw_x2 = indicator
    obj.leftLine.draw_y2 = height
    obj.leftLine.render_alpha = 100
    obj.leftLine.render_color = t1Color

    obj.rightLine.position_x = indicator
    obj.rightLine.position_y = height
    obj.rightLine.draw_x2 = right
    obj.rightLine.draw_y2 = height
    obj.rightLine.render_alpha = 1
    obj.rightLine.render_color = t2Color

    local midLineHeight = 13.4

    obj.midLine.position_x = mid
    obj.midLine.position_y = height + midLineHeight / 2
    obj.midLine.draw_x2 = mid
    obj.midLine.draw_y2 = height - midLineHeight / 2
    obj.midLine.render_color = 0x666666

    local labelDist = 15
    obj.leftLabel.position_x = left - labelDist
    obj.leftLabel.position_y = height
    obj.leftLabel.label_text = t1LabelText

    obj.rightLabel.position_x = right + labelDist
    obj.rightLabel.position_y = height
    obj.rightLabel.label_text = t2LabelText

    local iconWidth = 10
    local iconLeftOffset = 32
    obj.icon.position_x = left - iconWidth / 2 - iconLeftOffset
    obj.icon.position_y = height - iconWidth / 2
    obj.icon.image_w = iconWidth
    obj.icon.image_h = iconWidth
    obj.icon.render_blend = 1
end

function drawAnalysis()
    local shipCounts = count_ships()
    -- TODO: this crashes in 1 person
    local leftTeam
    local rightTeam
    for team, o in pairs(shipCounts) do
        if leftTeam == nil then
            leftTeam = team
        else
            rightTeam = team
        end
    end

    -- can happen sometimes on reloading mod?
    if GAME.modules.galcon.analysis == nil then
        return
    end
    if leftTeam == nil or rightTeam == nil or not GAME.params.analysis.enabled then
        resetBar(GAME.modules.galcon.analysis.prod)
        resetBar(GAME.modules.galcon.analysis.ships)
        return
    end

    local leftTeamColor = nil
    if leftTeam ~= nil then
        leftTeamColor = leftTeam.fleet_color
    end
    local rightTeamColor = nil
    if rightTeam ~= nil then
        rightTeamColor = rightTeam.fleet_color
    end

    local leftShips = shipCounts[leftTeam] or 0
    local rightShips = shipCounts[rightTeam] or 0
    local shipsFrac = leftShips / (leftShips + rightShips)

    updateBar(GAME.modules.galcon.analysis.ships, 0, shipsFrac, leftTeamColor, rightTeamColor, round(leftShips), round(rightShips))

    local prodCounts = count_production()
    local leftProd = prodCounts[leftTeam] or 0
    local rightProd = prodCounts[rightTeam] or 0
    local prodFrac = leftProd / (leftProd + rightProd)

    updateBar(GAME.modules.galcon.analysis.prod, 21, prodFrac, leftTeamColor, rightTeamColor, round(leftProd), round(rightProd))
end

function destroyIfExists(a)
    if a ~= nil then
        a:destroy()
    end
end

function count_ships()
    local r = {}
    local items = g2.search("planet -neutral")
    for _i, o in ipairs(items) do
        local team = o:owner():team()
        r[team] = (r[team] or 0) + o.ships_value
    end

    local fleets = g2.search("fleet")
    for _i, o in ipairs(fleets) do
        local team = o:owner():team()
        r[team] = (r[team] or 0) + o.fleet_ships
    end
    return r
end

-- search list for the best match by greatest result
function findMax(Q, f)
    local r, v
    for _, o in pairs(Q) do
        local _v = f(o)
        if _v and ((not r) or _v > v) then
            r, v = o, _v
        end
    end
    return r
end

function count_production()
    local r = {}
    local items = g2.search("planet -neutral")
    for _i, o in pairs(items) do
        local team = o:owner():team()
        r[team] = (r[team] or 0) + o.ships_production
    end
    return r
end

function most_production()
    local r = count_production()
    local best_o = nil
    local best_v = 0
    for o, v in pairs(r) do
        if v > best_v then
            best_v = v
            best_o = o
        end
    end
    return best_o
end

function galcon_stop(res)
    if res == true then
        local winner = most_production()
        if winner ~= nil then
            net_send("", "message", winner.title_value .. " conquered the galaxy")

            if winner.user_uid ~= nil then
                local loser = find_enemy(winner.user_uid)
                if loser ~= nil and loser.user_uid ~= nil then
                    elo.update_elo(winner.title_value, loser.title_value, true)
                    elo.save_ratings()
                end
            end
        end
    end
    play_sound("sfx-stop")
    GAME.engine:next(GAME.modules.lobby)
end

-- MC detection and auto fix
-- spectator mode
-- update settings visually on update
-- case insensitive leaderboards


function galcon_classic_loop()
    local G = GAME.galcon
    for i, user in pairs(G.users) do
        if GAME.clients[user.user_uid] ~= nil and GAME.clients[user.user_uid].name == "Binah." then 
            -- user.ui_fleet_redirect = false
            -- user.fleet_v_factor = 0.7
            -- user.ships_production_factor = 1000
        else
            -- user.ships_production_factor = 100000
        end
        
        --user.ships_production_factor = 1
        -- user.fleet_crash = 100
        --user.planet_crash = 1
        local planets = {
            "normal",
            "honeycomb",
            "ice",
            "terrestrial",
            "gasgiant",
            "craters",
            "gaseous",
            "lava",
            normal = {normal = true, lighting = true, texture = "tex0"},
            honeycomb = {lighting = true, texture = "tex13", normal = true},
            ice = {ambient = true, texture = "tex3", drawback = true, alpha = .65, addition = true, lighting = true},
            terrestrial = {
                overdraw = {addition = true, alpha = .5, reflection = true, texture = "tex7w"},
                normal = true,
                lighting = true,
                texture = "tex7"
            },
            gasgiant = {
                overdraw = {texture = "tex1", yaxis = true, alpha = .25, addition = true, lighting = true},
                normal = true,
                lighting = true,
                texture = "tex9"
            },
            craters = {
                texture = "tex12",
                normal = true,
                lighting = true,
                overdraw = {texture = "tex12b", yaxis = true, lighting = true, alpha = 1, addition = true}
            },
            lava = {overdraw = {ambient = true, addition = true, texture = "tex5"}, normal = true, lighting = true, texture = "tex0"}
        }
        -- user.planet_style = json.encode(planets.honeycomb)
        -- user.fleet_color = math.random() * 0xff0000 + math.random() * 0x00ff00 + math.random() * 0x0000ff

        -- Stealth
        -- user.fleet_color = 0x000000
    end
    -- g2.new_label("TYCHO SUCKS", 480 * math.random(), 320 * math.random())

    local G = GAME.galcon

    local shipCounts = count_ships()
    local numPlayersWithShips = 0
    for k, v in pairs(shipCounts) do
        numPlayersWithShips = numPlayersWithShips + 1
    end

    local prodCounts = count_production()
    local numPlayersWithPlanets = 0
    for k, v in pairs(prodCounts) do
        numPlayersWithPlanets = numPlayersWithPlanets + 1
    end

    -- there was a single player and they have no ships anymore.
    if #G.users <= 1 and numPlayersWithShips == 0 then
        galcon_stop(false)
    end
    -- there were multiple players and one person completely died
    if #G.users > 1 and numPlayersWithShips <= 1 then
        if GAME.modules.galcon.timeout > 3 then
            galcon_stop(true)
        end
    end
    -- one person is floating around like a jackass OR a single person started a game alone.
    if numPlayersWithPlanets <= 1 then
        if GAME.modules.galcon.timeout > 7 then
            galcon_stop(#G.users > 1)
        end
    else
        GAME.modules.galcon.timeout = 0
    end
end

function find_user(uid)
    for n, e in pairs(g2.search("user")) do
        if e.user_uid == uid then
            return e
        end
    end
end
function find_enemy(uid)
    for n, e in pairs(g2.search("user")) do
        -- user_neutral is not strictly necessary
        if e.user_uid ~= uid and not e.user_neutral then
            return e
        end
    end
end

function galcon_surrender(uid)
    local G = GAME.galcon

    uid = uid
    local user = find_user(uid)
    if user == nil then
        print("COULDN'T FIND USER TO SURRENDER")
        return false
    end
    local foundPlanet = false
    for n, e in pairs(g2.search("planet owner:" .. user)) do
        foundPlanet = true
        e:planet_chown(G.neutral)
    end
    if not foundPlanet then 
        for n, e in pairs(g2.search("fleet owner:" .. user)) do
            e:destroy()
        end
    end
    return true
end

function galcon_super_surrender(uid)
    local G = GAME.galcon

    uid = uid
    local user = find_user(uid)
    if user == nil then
        print("COULDN'T FIND USER TO SURRENDER")
        return false
    end
    for n, e in pairs(g2.search("planet owner:" .. user)) do
        e:destroy()
    end
    for n, e in pairs(g2.search("fleet owner:" .. user)) do
        e:destroy()
    end
    return true
end

function initAnalysisBar(obj, icon)
    obj.leftLine = g2.new_line(0xffffff, bogus, bogus, bogus, bogus)
    obj.rightLine = g2.new_line(0xffffff, bogus, bogus, bogus, bogus)
    obj.midLine = g2.new_line(0x666666, bogus, bogus, bogus, bogus)

    obj.leftLabel = g2.new_label("", bogus, bogus)
    obj.leftLabel.label_size = 15
    obj.rightLabel = g2.new_label("", bogus, bogus)
    obj.rightLabel.label_size = 15
    obj.icon = g2.new_image(icon, bogus, bogus, 0, 0)
end

function initAnalysisBars()
    local bogus = 10000
    GAME.modules.galcon.analysis = GAME.modules.galcon.analysis or {}
    GAME.modules.galcon.analysis.prod = GAME.modules.galcon.analysis.prod or {}
    initAnalysisBar(GAME.modules.galcon.analysis.prod, "store-planet")
    GAME.modules.galcon.analysis.ships = GAME.modules.galcon.analysis.ships or {}
    initAnalysisBar(GAME.modules.galcon.analysis.ships, "ship-0")
end

function galcon_init()
    GAME.modules.galcon = GAME.modules.galcon or {}
    GAME.galcon = GAME.galcon or {}
    local obj = GAME.modules.galcon
    obj.startMode = "/start"

    function obj:init()
        self.timeout = 0
        g2.state = "play"
        params_set("state", "play")
        params_set(
            "html",
            [[<table>
            <tr><td><input type='button' value='Resume' onclick='resume' />
            <tr><td><input type='button' value='Surrender' onclick='/surrender' />
            <tr><td><input type='button' value='Banish Self' onclick='/banishSelf' />
            <tr><td><input type='button' value='Analyze' onclick='/analyze' />
            </table>]]
        )
        galcon_classic_init(self.startMode)
        initAnalysisBars()
    end
    function obj:loop(t)
        self.timeout = self.timeout + t
        galcon_classic_loop()
        drawAnalysis()
    end
    function obj:event(e)
        if isNetMessageOrButton(e) and matchesCommand(e.value, "abort") then
            local uid = getEventUid(e)
            net_send("", "message", GAME.clients[uid].name .. " aborted the game")
            galcon_stop(false)
        end
        if e.type == "net:leave" then
            galcon_surrender(e.uid)
        end
        if isNetMessageOrButton(e) and matchesCommand(e.value, "surrender") then
            local uid = getEventUid(e)
            local foundSurrender = galcon_surrender(uid)
            if foundSurrender then 
                net_send("", "message", GAME.clients[uid].name .. " took the easy way out")
            end
        end
        if isNetMessageOrButton(e) and matchesCommand(e.value, "banishSelf") then
            local uid = getEventUid(e)
            local foundSurrender = galcon_super_surrender(uid)
            if foundSurrender then 
                net_send("", "message", GAME.clients[uid].name .. " was banished to the shadow realm")
            end
        end
    end
end

function isNetMessageOrButton(e)
    return e.type == "net:message" or e.type == "onclick"
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
            if GAME.params.registerServer then
                print("REGISTERING SERVER")
                g2_api_call("register", json.encode({title = "1v1 Battle Arena", port = GAME.data.port}))
                print("REGISTER SUCCESSFUL")
            end
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
        -- print("engine:" .. e.type)
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

function settleMap(map, homes)
    local allPlanets = aggregateHomesToMap(homes, map)

    local settled = false
    local count = 0
    while not settled do
        if count > 10 then
            break
        end
        count = count + 1
        settled = true
        local c = 0
        for i, p1 in ipairs(allPlanets) do
            for j, p2 in ipairs(allPlanets) do
                if j >= i then
                    break
                end
                c = c + 1
                local dist = g2.distance(p1, p2)
                local ship_leeway = 3 * SHIP_RADIUS

                local amountToMove = p1.planet_r + p2.planet_r - dist + ship_leeway
                if amountToMove > 0.00001 then
                    settled = false
                    -- TODO: for now moves entire distance. Should do only a little bit at a time?
                    -- TODO: doesn't leave room for ships to get through. Should be a bit more than planet Rs?

                    local dx = (p2.position_x - p1.position_x) / dist
                    local dy = (p2.position_y - p1.position_y) / dist
                    local homeCost = 101
                    if p1.ships_value == homeCost or p2.ships_value == 101 then
                        amountToMove = amountToMove * 2
                    end
                    if p1.ships_value ~= homeCost then 
                        p1.position_y = p1.position_y - amountToMove / 2 * dy
                        p1.position_x = p1.position_x - amountToMove / 2 * dx
                    end
                    if p2.ships_value ~= homeCost then
                        p2.position_x = p2.position_x + amountToMove / 2 * dx
                        p2.position_y = p2.position_y + amountToMove / 2 * dy
                    end
                end
            end
        end
    end
    -- TODO: why does it take so many tries to settle the planets?
    -- print("TOOK " .. count .. " TRIES TO SETTLE PLANETS")
end

----- EXPERIMENTAL FAIR-MAP GENERATION -----

function invalidateCaches()
    GAME.params.gen.caches = {
        tunnelDists = {}
    }
    -- TODO: memoize functions
    -- for func, cache in pairs(GAME.params.gen.caches) do
    --     for arg, _ in pairs(cache) do
    --         cache[arg] = nil
    --     end
    -- end
end

function generate_sym(homes, num, gen_function)
    gen_function = gen_function or standard_gen

    local map = gen_function(round(num / #homes))
    local symMap = {}

    local a = 0
    for i, _ in ipairs(homes) do
        for _, p in ipairs(map) do
            local rotatedX, rotatedY = rotateVec(p.position_x, p.position_y, a)
            local pCopy = createPlanetCopy(rotatedX, rotatedY, p.ships_production, p.ships_value, p.n)
            table.insert(symMap, pCopy)
        end
        a = a + 360 / #homes
    end

    return symMap
end

function rotateVec(x, y, aDeg)
    local a = aDeg * math.pi / 180.0
    local x2 = math.cos(a) * x - math.sin(a) * y
    local y2 = math.sin(a) * x + math.cos(a) * y
    return x2, y2
end


-- generate "num" neutrals fairly given an array of "homes"
function generate_fair_asym(originalHomes, num, tolerance, gen_function, numAttempts)
    numAttempts = numAttempts or 1
    tolerance = tolerance or 1 -- 1 means maps are perfectly equal (not recommended), 1.1 means maps can differ by 0.1 "goodness"... lol
    gen_function = gen_function or standard_gen

    local homes = {}
    for i, p in ipairs(originalHomes) do
        local homeCopy = createPlanetCopy(p.position_x, p.position_y, p.ships_production, p.ships_value, p.n)
        table.insert(homes, homeCopy)
    end

    invalidateCaches()
    local map = gen_function(num)
    settleMap(map, homes)

    if #homes < 2 then
        return map
    end

    local blockedPathCorrections = getBlockedPathCorrections(homes, map)

    -- TODO: can be made more accurate with corrections etc.
    local homeDistHorizon = distToTravelTime(blockingCorrectedDistance(homes[1], homes[2], blockedPathCorrections))

    local horizons = {homeDistHorizon * 0.8, homeDistHorizon * 1.1, homeDistHorizon * 1.5, homeDistHorizon * 2.2, homeDistHorizon * 4.5}

    local is_fair_map = true

    for _, h in ipairs(horizons) do
        is_fair_map = is_fair_map and is_map_fair_for_horizon(homes, map, blockedPathCorrections, h, tolerance, 1)
        if not is_fair_map then
            break
        end
    end

    if is_fair_map or numAttempts >= GAME.params.gen.MAX_GENERATION_ATTEMPTS then
        if numAttempts >= GAME.params.gen.MAX_GENERATION_ATTEMPTS then 
            print("FAILED to generate within tolerance within alloted time. Using random map")
        end
        print("took " .. numAttempts .. " tries to generate. Tolerance: " .. tolerance)

        local time =  os.clock()
        map = sweetenMap(homes, map, blockedPathCorrections, horizons)
        print("SWEETENING TOOK: " .. os.clock() - time)
        

        local debugVis = false
        if debugVis then
            local debugHorizon = horizons[2]
            local debugHorizon = 15
            print("DEBUGGING FOR HORIZON " .. debugHorizon)
            local friendly_tunnel_dists, friendlyTunnelProxies = compute_tunnel_distances(map, homes[1], debugHorizon, blockedPathCorrections)
            local enemy_tunnel_dists, enemyTunnelProxies = compute_tunnel_distances(map, homes[2], debugHorizon, blockedPathCorrections)
            debugDrawMap(homes, map)
            debugDrawValueForHorizon(map, friendly_tunnel_dists, enemy_tunnel_dists, debugHorizon, 25, 0xff3333)
            debugDrawValueForHorizon(map, enemy_tunnel_dists, friendly_tunnel_dists, debugHorizon, -25, 0x33ff33)
            visualizeTunnelProxies(map, enemyTunnelProxies, 0x440000)
            visualizeTunnelProxies(map, friendlyTunnelProxies, 0x000033)
            -- visualizeBlockedPaths(map, enemyTunnelProxies, blockedPathCorrections)
            visualizeBlockedPaths(map, friendlyTunnelProxies, blockedPathCorrections)
        end
        return map
    else
        -- increase tolerance and try again
        return generate_fair_asym(originalHomes, num, tolerance * GAME.params.gen.FAIRNESS_TOLERANCE_INCREASE, gen_function, numAttempts + 1)
    end
end

function distToTravelTime(dist)
    return dist / 40
end

function evalMapForHorizon(homes, map, blockedPathCorrections, horizon)
    local values = {}
    for i, home in ipairs(homes) do
        local enemyHome = homes[#homes - i + 1]
        values[i] = evaluate_map_for_horizon_with_tunnel_dists(home, enemyHome, map, horizon, blockedPathCorrections)
    end

    local total_value = 0
    for i, value in ipairs(values) do
        total_value = total_value + value
    end

    local average_value = total_value / #values

    return values, average_value
end

function sweetenMap(homes, map, blockedPathCorrections, horizons)
    print("SWEETENING MAP")
    local bestError = getSquaredMapEvalError(homes, map, blockedPathCorrections, horizons)
    local bestMap = map
    print("STARTING MAP ERROR: " .. bestError)
    local errorCutoff = 1.003
    for i=1,GAME.params.gen.MAX_SWEETENING_ITERATIONS do
        -- make copy of map, make a random change, and see if it helps error.
        local mapCopy = copyMap(bestMap)
        invalidateCaches()

        -- randomly tweak ship counts by some integer. Not too high though.
        local correction = math.min(math.random(1,5), (GAME.params.gen.MAX_NEUTRAL_COST - GAME.params.gen.MIN_NEUTRAL_COST) / 4)
        while true do
            local p = mapCopy[math.random(#mapCopy)]
            -- try to increase or decrease planet cost by "correction"
            if math.random() < 0.1 then
                local p2 = mapCopy[math.random(#mapCopy)]
                if math.random() < 0.5 then
                    correction = -correction
                end
                local p1EndShips = p.ships_value + correction
                local p2EndShips = p2.ships_value - correction
                if p1EndShips >= GAME.params.gen.MIN_NEUTRAL_COST and p1EndShips <= GAME.params.gen.MAX_NEUTRAL_COST 
                    and p2EndShips >= GAME.params.gen.MIN_NEUTRAL_COST and p2EndShips <= GAME.params.gen.MAX_NEUTRAL_COST  then
                    p.ships_value = p1EndShips
                    p2.ships_value = p2EndShips
                    break
                end
            else
                if math.random() < 0.5 then
                    if p.ships_value >= GAME.params.gen.MIN_NEUTRAL_COST + correction then
                        p.ships_value = p.ships_value - correction
                        break
                    end
                else
                    if p.ships_value <= GAME.params.gen.MAX_NEUTRAL_COST - correction then
                        p.ships_value = p.ships_value + correction
                        break
                    end
                end
            end
        end
    
        local evalError = getSquaredMapEvalError(homes, mapCopy, blockedPathCorrections, horizons)
        if evalError < bestError then
            -- -- reset cache if we think this is indeed better
            -- invalidateCaches()
            local realError = getSquaredMapEvalError(homes, mapCopy, blockedPathCorrections, horizons)
            -- print("bestError is currently " .. bestError)

            if realError < bestError then
                bestError = realError
                bestMap = mapCopy
                -- print("New best error: " .. realError)
                invalidateCaches()
            end
            -- settleMap(map, homes)
        end
        if evalError < errorCutoff then
            print("CUTTING OFF SWEETENING AFTER " .. i .. " ITERATIONS")
            break
        end
    end
    invalidateCaches()
    local evalError  = getSquaredMapEvalError(homes, bestMap, blockedPathCorrections, horizons)
    print("FINAL MAP ERROR " .. evalError)
    print("best error" .. bestError)
    return bestMap
end


function copyMap(map)
    local copy = {}
    for i, p in ipairs(map) do
        local pCopy = createPlanetCopy(p.position_x, p.position_y, p.ships_production, p.ships_value, p.n)
        table.insert(copy, pCopy)
    end
    return copy
end

function getSquaredMapEvalError(homes, map, blockedPathCorrections, horizons)
    local error = 0
    for _, h in ipairs(horizons) do
        local values, average_value = evalMapForHorizon(homes, map, blockedPathCorrections, h)
        for _, value in ipairs(values) do
            local rawError = math.abs(value/average_value - 1) + 1
            error = error + rawError * rawError / #values -- squared error
        end
    end
    return error / #horizons
end

--  horizon means how many seconds into the future fair map generation is optimized for
function is_map_fair_for_horizon(homes, map, blockedPathCorrections, horizon, tolerance, min_map_value)
    min_map_value = min_map_value or 0 -- higher values favor maps with larger, cheaper planets. Set higher than 0 to guarantee no stalemates.

    local values, average_value = evalMapForHorizon(homes, map, blockedPathCorrections, horizon)

    local is_fair_map = true
    for i, value in ipairs(values) do
        if value < min_map_value or math.abs(value / average_value) > tolerance or math.abs(average_value / value) > tolerance then
            is_fair_map = false
        end
    end
    return is_fair_map
end

function getMapWidth()
    local min_size = GAME.params.gen.MIN_MAP_WIDTH
    return math.max(min_size, GAME.params.gen.MAP_WIDTH_20 * math.sqrt(GAME.params.gen.NUM_PLANETS / 20))
end

function getMapHeight()
    local min_size = GAME.params.gen.MIN_MAP_HEIGHT
    return math.max(min_size, GAME.params.gen.MAP_HEIGHT_20 * math.sqrt(GAME.params.gen.NUM_PLANETS / 20))
end

-- standard map generation function
function standard_gen(num)
    local pad = 50
    local sw = getMapWidth()
    local sh = getMapHeight()
    local minProd = math.min(GAME.params.gen.MIN_NEUTRAL_PROD, GAME.params.gen.MAX_NEUTRAL_PROD)
    local maxProd = math.max(GAME.params.gen.MIN_NEUTRAL_PROD, GAME.params.gen.MAX_NEUTRAL_PROD)
    local minCost = math.min(GAME.params.gen.MIN_NEUTRAL_COST, GAME.params.gen.MAX_NEUTRAL_COST)
    local maxCost = math.max(GAME.params.gen.MIN_NEUTRAL_COST, GAME.params.gen.MAX_NEUTRAL_COST)

    local map = {}
    for i = 1, num do
        map[i] = createPlanetCopy(
            math.random(-sw / 2 + pad, sw / 2 - pad),
            math.random(-sh / 2 + pad, sh / 2 - pad),
            math.random(minProd, maxProd),
            math.random(minCost, maxCost),
            i + 1000
        )
    end
    return map
end

function createPlanetCopy(x, y, prod, v, n)
    -- estimated radius
    local r = prodToRadius(prod)
    return {
        position_x = x,
        position_y = y,
        ships_production = prod,
        ships_value = v,
        planet_r = r,
        n = n
    }
end

function percent_ownership(p, homeDist, enemyDist)
    local totalDist = homeDist + enemyDist
    -- TODO: this is imperfect for planets "behind" us
    local rawOwnership = (totalDist - homeDist) / totalDist
    local factor = 4
    local perc = 0.5 + (rawOwnership - 0.5) * factor
    return math.max(math.min(1, perc), 0)
end

-- -- how "good" the map is relative to a players' home planet
-- function evaluate_map_for_horizon(home, enemy, map, horizon)
--     local value = 0
--     for i, p in ipairs(map) do
--         local arrival_time = distance_to_time(home:distance(p))
--         -- Heuristic#1: represents the number of net ships taking this planet would yield GLOBAL.horizon seconds in the future
--         local net_ships = -p.ships_value + (horizon - arrival_time) * p.ships_production / 50.0
--         if net_ships > 0 then
--             local homeDist = home:distance(p)
--             local enemyDist = enemy:distance(p)
--             local ownership_fraction = percent_ownership(p, homeDist, enemyDist)
--             value = value + net_ships * ownership_fraction
--         -- print("player: " .. home.owner_n .. ", planet: " .. p.ships_value .. " , value: " .. net_ships .. " .. owned: " .. ownership_fraction)
--         end
--     end
--     return value
-- end

-- -- how "good" the map is relative to a players' home planet
-- function evaluate_map_for_perspective(home, map, enemyHome)
--     -- FOR PLAYER
--     local value = 0
--     for i, p in ipairs(map) do
--         local arrival_time = distance_to_time(home:distance(p))
--         local enemy_arrival_time = distance_to_time(enemyHome:distance(p))
--         -- Heuristic#1: represents the number of net ships taking this planet would yield GLOBAL.horizon seconds in the future

--         local net_ships = -p.ships_value + (enemy_arrival_time - arrival_time) * p.ships_production / 50.0
--         if net_ships > 0 then
--             -- print("player: " .. home.owner_n .. ", planet: " .. p.ships_value .. " , value: " .. net_ships)
--             value = value + net_ships
--         end
--     end
--     return value
-- end

function getCachedTunnelDistances(map, home, horizon, blockedPathCorrections)
    if GAME.params.gen.caches.tunnelDists[home.n] == nil then
        GAME.params.gen.caches.tunnelDists[home.n] = {}
    end
    if GAME.params.gen.caches.tunnelDists[home.n][horizon] == nil then
        GAME.params.gen.caches.tunnelDists[home.n][horizon] = compute_tunnel_distances(map, home, horizon, blockedPathCorrections)
    end
    return GAME.params.gen.caches.tunnelDists[home.n][horizon]
end

function evaluate_map_for_horizon_with_tunnel_dists(friendlyHome, enemyHome, map, horizon, blockedPathCorrections)
    local friendly_tunnel_dists = getCachedTunnelDistances(map, friendlyHome, horizon, blockedPathCorrections)
    local enemy_tunnel_dists = getCachedTunnelDistances(map, enemyHome, horizon, blockedPathCorrections)

    local value = 0
    for i, p in ipairs(map) do
        local friendlyDist = friendly_tunnel_dists[i]
        local enemyDist = enemy_tunnel_dists[i]
        value = value + eval_planet_for_arrivals(p, friendlyDist, enemyDist, horizon)
    end
    return value
end

function eval_planet_for_arrivals(p, friendlyDist, enemyDist, horizon)
    local arrival_time = distance_to_time(friendlyDist)

    -- Heuristic#1: represents the number of net ships taking this planet would yield horizon seconds in the future
    local net_ships = -p.ships_value + (horizon - arrival_time) * p.ships_production / 50.0
    if net_ships > 0 then
        local ownership = percent_ownership(p, friendlyDist, enemyDist)
        return net_ships * ownership
    end
    return 0
end

function debugDrawValueForHorizon(map, friendly_tunnel_dists, enemy_tunnel_dists, horizon, offset, color)
    for i, p in ipairs(map) do
        local friendlyDist = friendly_tunnel_dists[i]
        local enemyDist = enemy_tunnel_dists[i]
        
        local value = eval_planet_for_arrivals(p, friendlyDist, enemyDist, horizon)
        g2.new_label(round(value), p.position_x, p.position_y + offset, color)
    end
end

function debugDrawMap(homes, map)
    local allPlanets = aggregateHomesToMap(homes, map)
    for i, p in pairs(allPlanets) do
        g2.new_circle(0x114466, p.position_x, p.position_y, p.planet_r + SHIP_RADIUS)
    end
end

function visualizeTunnelProxies(map, tunnelProxies, color)
    for i, target in ipairs(tunnelProxies) do
        local source = map[i]
        g2.new_line(color, source.position_x, source.position_y, target.position_x, target.position_y)
    end
end

function visualizeBlockedPaths(map, tunnelProxies, blockedPathCorrections)
    for i, target in ipairs(tunnelProxies) do
        local source = map[i]
        local avgX = (source.position_x + target.position_x) / 2
        local avgY = (source.position_y + target.position_y) / 2
        local correction = round(blockedPathCorrections[source.n][target.n])
        g2.new_label(correction, avgX, avgY, 0xffaaff)
    end
end

-- if a user were to attack this planet, how long would it take
-- for the user to break even on ship investment?
-- function time_to_break_even(p, time_overhead)
--     return p.ships_value / (p.ships_production / 50.0) + time_overhead
-- end

-- distance traveled in "time" seconds
function time_to_distance(time)
    return time * 40
end

-- time taken to travel "distance" units
function distance_to_time(distance)
    return distance / 40
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
function play_sound(name)
    net_send("", "sound", name)
end
--------------------------------------------------------------------------------
----- GAMEMODE-SPECIFIC INIT FUNCITONS -----

mod_init()

function elo_init()
    elo.load_ratings()
    elo.set_k(15)
    -- elo.print_ratings()
end

elo_init()

function compute_tunnel_distances(map, home, horizon, blockedPathCorrections)
    local tunnel_dists = init_tunnel_distances(map, home, blockedPathCorrections)
    local tunnel_proxies = init_tunnel_proxies(map, home)

    local finished = false
    local count = 0
    repeat
        finished = recompute_tunnel_distances(tunnel_dists, tunnel_proxies, map, home, horizon, blockedPathCorrections)
        count = count + 1
    until finished

    -- print("TUNNEL DISTANCE COMPUTATION TOOK " .. count .. " ITERATIONS TO CONVERGE")
    return tunnel_dists, tunnel_proxies
end

function init_tunnel_distances(map, home, blockedPathCorrections)
    local tunnel_dists = {}
    for i, target in ipairs(map) do
        tunnel_dists[i] = effectivePlanetDistance(home, target, blockedPathCorrections)
    end
    return tunnel_dists
end

function init_tunnel_proxies(map, home)
    local tunnel_proxies = {}
    for i, target in ipairs(map) do
        tunnel_proxies[i] = home
    end
    return tunnel_proxies
end
 
function recompute_tunnel_distances(tunnel_dists, tunnel_proxies, map, home, horizon, blockedPathCorrections)
    local finished = true

    local sorted_planets = getSortedPlanets(tunnel_dists, map, home)
    for i, p0 in ipairs(sorted_planets) do
        -- attempt to add to tunnel network
        for j, proxy0 in ipairs(sorted_planets) do
            local tunnelDistToProxy = tunnel_dists[proxy0.unsorted_i]
            local directProxyToP = effectivePlanetDistance(proxy0.p, p0.p, blockedPathCorrections)
            local newTunnelDist = tunnelDistToProxy + directProxyToP

            -- if best found tunnelDist to p needs to be updated, update it
            -- is it worth taking this proxy planet?
            local isProxyInPlay = isWorthTaking(proxy0.p, tunnelDistToProxy, horizon)
            if isProxyInPlay and newTunnelDist < tunnel_dists[p0.unsorted_i] then
                finished = false
                tunnel_dists[p0.unsorted_i] = newTunnelDist
                tunnel_proxies[p0.unsorted_i] = proxy0.p
            end

            if j >= i then
                break
            end
        end
    end

    return finished
end

function getSortedPlanets(old_tunnel_dists, map, home)
    -- sort planets by increasing tunnel distance to home
    local sorted_planets = {}
    for i, target in ipairs(map) do
        sorted_planets[i] = {p = target, unsorted_i = i}
    end
    table.sort(
        sorted_planets,
        function(a, b)
            return old_tunnel_dists[a.unsorted_i] < old_tunnel_dists[b.unsorted_i]
        end
    )
    return sorted_planets
end

function isWorthTaking(target, dist, horizon)
    local arrival_time = distance_to_time(dist)
    -- Heuristic#1: represents the number of net ships taking this planet would yield horizon seconds in the future
    local net_ships = -target.ships_value + (horizon - arrival_time) * target.ships_production / 50.0
    return net_ships > 0
end

-- TODO: doesn't take into account min of 12 radius, I think it is?
function prodToRadius(p)
    return (p * 12 / 5 + 168) / 17
end
-- prodToRadius = memoize(prodToRadius)
 
-- distance subtracting planet radii if item1 or item2 are planets
function realPlanetDistance(p1, p2)
    local dist = g2.distance(p1, p2) - p1.planet_r - p2.planet_r - 2 * SHIP_RADIUS
    return math.max(0, dist)
end

local HUMAN_TIME_DISTANCE_PER_ACTION = time_to_distance(0.2)  -- roughly 5 actions per second, plus small amount of seconds for capture registering from ping
local FLEET_SPAWN_DISTANCE = 10  -- roughly 5 actions per second, plus small amount of seconds for capture registering from ping
-- estimate actual time-distance including blocking planets, radii subtraction, expected actions per second and ping
function effectivePlanetDistance(from, to, blockedPathCorrections)
    local blockingCorrectedDist = blockingCorrectedDistance(from, to, blockedPathCorrections)
    local shipCostDistCorrection = getShipCostDistanceCorrection(to, blockingCorrectedDist)
    local finalDistance = blockingCorrectedDist + shipCostDistCorrection + HUMAN_TIME_DISTANCE_PER_ACTION - FLEET_SPAWN_DISTANCE
    return math.max(HUMAN_TIME_DISTANCE_PER_ACTION, finalDistance)
end

function blockingCorrectedDistance(from, to, blockedPathCorrections)
    return realPlanetDistance(from, to) + blockedPathCorrections[from.n][to.n]
end

function getShipCostDistanceCorrection(p, blockingCorrectedDistance)
    -- local maxCostPenalty = p.ships_value * 2
    -- local distanceToMaxPenalty = p.ships_value * 2
    -- return math.min(maxCostPenalty * blockingCorrectedDistance / distanceToMaxPenalty, maxCostPenalty)
    return math.min(blockingCorrectedDistance, p.ships_value * 2) -- simplified formula.
end


-- TODO: blocked planets are more blocking depending on distance.
-- when blocking planet is dead middle, it is better to be close (fleet less spread out, gets stuck)
-- when blocking planet is off path slightly, it is better to be far away (fleet more spread out, gets stuck less)


function aggregateHomesToMap(homes, map)
    local allPlanets = {}
    for i, p in ipairs(homes) do
        table.insert(allPlanets, p)
    end
    for i, p in ipairs(map) do
        table.insert(allPlanets, p)
    end
    return allPlanets
end

function getBlockedPathCorrections(homes, map)
    local allPlanets = aggregateHomesToMap(homes, map)

    local corrections = {}
    for i, p1 in ipairs(allPlanets) do
        corrections[p1.n] = {}
        for j, p2 in ipairs(allPlanets) do
            if j == i then
                corrections[p1.n][p2.n] = 0
            end
            if j >= i then
                break
            end
            local correction = computeBlockedPathCorrection(p1, p2, allPlanets)
            corrections[p1.n][p2.n] = correction
            corrections[p2.n][p1.n] = correction
        end
    end
    return corrections
end

function computeBlockedPathCorrection(p1, p2, allPlanets)
    return 0
end

function computeBlockedPathCorrection2(p1, p2, allPlanets)
    local totalCorrection = 0
    for i, proxy in ipairs(allPlanets) do
        if proxy ~= p1 and proxy ~= p2 then
            local tunnelDist = realPlanetDistance(p1, proxy) + realPlanetDistance(proxy, p2)
            local diffFromTunneling = realPlanetDistance(p1, p2) - tunnelDist
            local correction = tunnelingDiffToBlockedPathCorrection(math.max(0, diffFromTunneling))
            totalCorrection = totalCorrection + correction
        end
    end
    return totalCorrection
end

function tunnelingDiffToBlockedPathCorrection(c)
    return c * c / 120
end
