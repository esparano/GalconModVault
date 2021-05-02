require("mod_map_tunnels")
require("mod_map_info")
require("mod_map_future")
require("mod_common_utils")

require("mod_hivemind_attack")
require("mod_hivemind_center_control")
require("mod_hivemind_cleanup")
require("mod_hivemind_cluster_control")
require("mod_hivemind_defend_rush")
require("mod_hivemind_defend")
require("mod_hivemind_even_distribution")
require("mod_hivemind_expand")
require("mod_hivemind_exploit_empty")
require("mod_hivemind_feed_front")
require("mod_hivemind_flee_trick")
require("mod_hivemind_float")
require("mod_hivemind_mid_rush")
require("mod_hivemind_overcapture")
require("mod_hivemind_pass")
require("mod_hivemind_redirect_trick")
require("mod_hivemind_rush")
require("mod_hivemind_swap")
require("mod_hivemind_timer_trick")

require("mod_hivemind_action")

function firstTurnSetup(params)
    print("first turn setup")
end

function initMinds(opts) 
    local minds = {}
     -- sets positive RoI planets as tunnelable. Should analyze earlier than most other minds.
    table.insert(minds, ExpandMind.new({
        roiWeight = opts.optimized.expand_roiWeight,
        shipReturnsWeight = opts.optimized.expand_shipReturnsWeight
    }))
    table.insert(minds, AttackMind.new())
    table.insert(minds, CenterControlMind.new())
    table.insert(minds, CleanupMind.new())
    table.insert(minds, ClusterControlMind.new())
    table.insert(minds, DefendRushMind.new())
    table.insert(minds, DefendMind.new())
    table.insert(minds, EvenDistributionMind.new())
    table.insert(minds, ExploitEmptyMind.new())
    table.insert(minds, FeedFrontMind.new())
    table.insert(minds, FleeTrickMind.new())
    table.insert(minds, FloatMind.new())
    table.insert(minds, MidRushMind.new())
    table.insert(minds, OvercaptureMind.new())
    table.insert(minds, PassMind.new())
    table.insert(minds, RedirectTrickMind.new())
    table.insert(minds, RushMind.new())
    table.insert(minds, SwapMind.new())
    table.insert(minds, TimerTrickMind.new())
    return minds
end

function bot_hivemind(params, sb_stats)
    ITEMS = params.items
    local botUser = ITEMS[params.user]
    local defaultOptions = {
        -- TODO: fill these out
        -- percent = 100,
        debug = {
            drawFriendlyFrontPlanets = false,
            drawEnemyFrontPlanets = false,
            drawFriendlyTunnels = false,
            drawEnemyTunnels = false,
        },
        optimized = {
            expand_roiWeight = 1,
            expand_shipReturnsWeight = 1,
        }
        
    }
    OPTS = common_utils.mergeTableInto(defaultOptions, params.options or {})

    MEM = params.memory
    DEBUG = params.debug or {
        debugHighlightPlanets = common_utils.pass,
        debugDrawPaths = common_utils.pass
    }

    MEM.t = (MEM.t or 0) + 1
    if (MEM.t % 4) ~= 1 then
        -- return
    end -- do an action once per second

    local map = Map.new(ITEMS)
    local users = map:getUserList(false)
    if #users ~= 2 then 
        print("ERROR: Match is either FFA or there is no enemy. Skipping turn. #users = " .. #users)
        return
    end
    local enemyUser = map:getEnemyUser(botUser.n)

    MEM.mapTunnelsData = MEM.mapTunnelsData or {}
    mapTunnels = MapTunnels.new(ITEMS, MEM.mapTunnelsData)
    mapFuture = MapFuture.new(ITEMS, botUser)

    if not MEM.initialized then
        MEM.initialized = true
        firstTurnSetup(params)
    end

    local move = getMove(map, mapTunnels, mapFuture, botUser, OPTS)
    print(move:getSummary())

    -- DEBUG DRAWING
    -- if OPTS.debug.drawFriendlyFrontPlanets then 
    --     DEBUG.debugHighlightPlanets(botUser, botFrontPlanets, botUser, 7)
    -- end
    -- if OPTS.debug.drawEnemyFrontPlanets then 
    --     DEBUG.debugHighlightPlanets(botUser, enemyFrontPlanets, enemyUser, 7)
    -- end
    -- if OPTS.debug.drawFriendlyTunnels then 
    --     debugDrawTunnels(botUser, map, mapTunnels, botUser, botFrontPlanets)
    -- end
    -- if OPTS.debug.drawEnemyTunnels then 
    --     debugDrawTunnels(botUser, map, mapTunnels, enemyUser, enemyFrontPlanets)
    -- end

    local ticks, alloc = sb_stats()
    print("ticks, alloc = " .. ticks .. " , " .. alloc)

    if not move or move.mind.name == "Pass" then 
        return 
    end

    local sources = common_utils.map(move.sources, function (p) return p.n end)
    
    return {percent = move.percent, from = sources, to = move.target.n}
end

function getMove(map, mapTunnels, mapFuture, botUser, opts)
    -- TODO: params for genetic algorithm
    local minds = initMinds(opts);

    local candidates = {}
    for _,mind in ipairs(minds) do 
        local actions = mind:suggestActions(map, mapTunnels, mapFuture, botUser)
        for _,action in ipairs(actions) do 
            table.insert(candidates, action)
        end
    end

    for _,action in ipairs(candidates) do 
        for _,mind in ipairs(minds) do 
            if mind ~= action.mind then 
                mind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
            end
        end
    end

    -- 1 Priority is roughly equivalent to 1 ship value (high priority moves expect to gain or save many ships)
    table.sort(candidates, function (a, b) 
        return a:getOverallPriority() > b:getOverallPriority() end
    )

    return candidates[1], candidates
end

function debugDrawTunnels(botUser, map, mapTunnels, owner, targets)
    local tunnelPairs = {}
    for i,source in ipairs(map:getPlanetList(owner)) do 
        local closestTarget = getClosestTarget(mapTunnels, source, targets)
        if closestTarget ~= nil and source.n ~= closestTarget.n then
            local tunnelAlias = mapTunnels:getTunnelAlias(source.n, closestTarget.n)
            table.insert(tunnelPairs, {source = source, target = tunnelAlias})
        end
    end
    DEBUG.debugDrawPaths(botUser, tunnelPairs, owner)
end

