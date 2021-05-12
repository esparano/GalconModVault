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
require("mod_hivemind_pressure")
require("mod_hivemind_redirect_trick")
require("mod_hivemind_rush")
require("mod_hivemind_surrender")
require("mod_hivemind_swap")
require("mod_hivemind_timer_trick")

require("mod_hivemind_action")

function firstTurnSetup(params)
    print("first turn setup")
end

function getOptsForMind(mindName, opts)
    local mindOpts = {}
    for k,v in pairs(opts.optimized) do 
        local tokens = {}
        for token in string.gmatch(k, "[^_]+") do 
            table.insert(tokens, token)
        end
        if string.lower(tokens[1]) == string.lower(mindName) then 
            local optKey = string.sub(k,  #mindName + 2)
            mindOpts[optKey] = v
        end
    end
    mindOpts.settings = opts.settings
    return mindOpts
end

function initMinds(opts) 
    local minds = {}
     -- sets positive RoI planets as tunnelable. Should analyze earlier than most other minds.
    table.insert(minds, ExpandMind.new(getOptsForMind("expand", opts)))
    table.insert(minds, AttackMind.new(getOptsForMind("attack", opts)))
    table.insert(minds, CenterControlMind.new(getOptsForMind("centercontrol", opts)))
    table.insert(minds, CleanupMind.new(getOptsForMind("cleanup", opts)))
    table.insert(minds, ClusterControlMind.new(getOptsForMind("clustercontrol", opts)))
    table.insert(minds, DefendRushMind.new(getOptsForMind("defendrush", opts)))
    table.insert(minds, DefendMind.new(getOptsForMind("defend", opts)))
    table.insert(minds, EvenDistributionMind.new(getOptsForMind("evendistribution", opts)))
    table.insert(minds, ExploitEmptyMind.new(getOptsForMind("exploitempty", opts)))
    table.insert(minds, FeedFrontMind.new(getOptsForMind("feedfront", opts)))
    table.insert(minds, FleeTrickMind.new(getOptsForMind("fleetrick", opts)))
    table.insert(minds, FloatMind.new(getOptsForMind("float", opts)))
    table.insert(minds, MidRushMind.new(getOptsForMind("midrush", opts)))
    table.insert(minds, OvercaptureMind.new(getOptsForMind("overcapture", opts)))
    table.insert(minds, PassMind.new(getOptsForMind("pass", opts)))
    table.insert(minds, PressureMind.new(getOptsForMind("pressure", opts)))
    table.insert(minds, RedirectTrickMind.new(getOptsForMind("redirecttrick", opts)))
    table.insert(minds, RushMind.new(getOptsForMind("rush", opts)))
    table.insert(minds, SurrenderMind.new(getOptsForMind("surrender", opts)))
    table.insert(minds, SwapMind.new(getOptsForMind("swap", opts)))
    table.insert(minds, TimerTrickMind.new(getOptsForMind("timertrick", opts)))
    return minds
end

function getHome(map, mapTunnels, user)
    return common_utils.find(map:getPlanetList(user.n), function(p) return p.production end)
end

function getHomesDistance(map, mapTunnels)
    local users = map:getUserList(false)
    local h1 = getHome(map, mapTunnels, users[1])
    local h2 = getHome(map, mapTunnels, users[2])
    return mapTunnels:getSimplifiedTunnelDist(h1.n, h2.n)
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
            expand_fullAttackDiffWeight = 1,
            expand_fullAttackDiffIntercept = 1,
            expand_fullAttackDiffMin = 1,
            expand_fullAttackDiffMax = 1,
            expand_fullAttackCaptureEase = 1,
            expand_fullAttackProdWeight = 1,
            expand_fullAttackOverallWeight = 1,
            expand_planContinuityBonus = 1,
            expand_gainedShipsWeight = 1,
            expand_targetCostWeight = 1,
            expand_ownedPlanetMaxShipLoss = 1,
            expand_negativeRoiReductionFactor = 1
        },
        settings = {
            multiSelect = true,
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
    MEM.plans = MEM.plans or {}
    -- update mapTunnelsData, then clone it for use in this function to avoid neutrals marked tunnelable from being permanently (mistakenly) tunnelable even if the map changes a lot
    mapTunnels = MapTunnels.new(ITEMS, MEM.mapTunnelsData)
    mapTunnels = MapTunnels.new(ITEMS, common_utils.copy(MEM.mapTunnelsData))

    mapFuture = MapFuture.new(ITEMS, botUser)

    if not MEM.initialized then
        MEM.initialized = true
        firstTurnSetup(params)
    end

    local move = getMove(map, mapTunnels, mapFuture, botUser, OPTS, MEM)
    print("CHOOSING MOVE: " .. move:getSummary())

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
    -- print("ticks, alloc = " .. ticks .. " , " .. alloc)

    if not move or move.mind.name == "Pass" then 
        return 
    end

    local sources = common_utils.map(move.sources, function (p) return p.n end)
    
    return {percent = move.percent, from = sources, to = move.target.n}
end

function getMove(map, mapTunnels, mapFuture, botUser, opts, mem)
    -- TODO: params for genetic algorithm
    local minds = initMinds(opts);

    -- update minds' state with chosen plans and update saved plans.
    for _,mind in ipairs(minds) do 
        for _,plan in ipairs(mem.plans) do 
            if mind.name == plan.mindName then
                mind:processPlan(map, mapTunnels, mapFuture, botUser, plan)
            end
        end
    end
    mem.plans = common_utils.filter(mem.plans, function (p) return not p.satisfied end)

    local candidates = {}
    for _,mind in ipairs(minds) do 
        local actions = mind:suggestActions(map, mapTunnels, mapFuture, botUser)
        for _,action in ipairs(actions) do 
            table.insert(candidates, action)
        end
    end

    for _,action in ipairs(candidates) do 
        gradeAction(action, minds)
    end

    -- TODO: THIS sometimes results in situations where the bot over-sends to expand to a nearby planet, not realizing that it can't actually afford multiple neutrals.
    -- Instead, the highest-priority move should track and apply its reservations and only then determine if the secondary action is compatible.
    -- TODO: THe way that moves with different percentages get combined, it may break "reservations" slightly.
    -- candidates = getCombinedActions(candidates, minds, opts.multiSelect)

    -- 1 Priority is roughly equivalent to 1 ship value (high priority moves expect to gain or save many ships)
    table.sort(candidates, function (a, b) 
        return a:getOverallPriority() > b:getOverallPriority() end
    )

    -- for i,a in ipairs(candidates) do 
    --     print(a:getSummary())
    -- end

    local chosenAction = candidates[1]
    mem.plans = common_utils.combineLists(mem.plans, chosenAction.plans)

    return chosenAction, candidates
end

function gradeAction(action, minds)
    for _,mind in ipairs(minds) do 
        if mind ~= action.mind then
            -- TODO: bias and multiplier for each mind's priority and adjustments? 4 parameters? Idk.
            mind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
        end
    end
end

function getCombinedActions(actions, minds, multiselect)
    local allActions = common_utils.shallow_copy(actions)
    local newActions = common_utils.shallow_copy(actions) 

    -- keep track of the raw/base constituent actions.
    local comboActionSourceMap = {}
    for _,a in ipairs(allActions) do
        comboActionSourceMap[a] = Set.new({a})
    end

    local iterations = 1
    local MAX_ITERATIONS = 4
    while #newActions > 0 and iterations < MAX_ITERATIONS do
        local nextNewActions = {}

        for i,a1 in ipairs(allActions) do
            for j,a2 in ipairs(newActions) do 
                if i < j or iterations > 1 then 
                    -- Combined actions may not have any base actions in common.
                    if comboActionSourceMap[a1]:intersection(comboActionSourceMap[a2]):size() == 0 then 
                        local a = combineActions(a1, a2, multiselect)
                        if a then
                            comboActionSourceMap[a] = comboActionSourceMap[a1]:union(comboActionSourceMap[a2])
                            gradeAction(a, minds)
                            table.insert(nextNewActions, a) 
                        end
                    end
                end
            end
        end

        allActions = common_utils.combineLists(allActions, nextNewActions)
        newActions = nextNewActions

        iterations = iterations + 1
    end
    if iterations > MAX_ITERATIONS then
        print("WARNING: TOOK MORE THAN " .. MAX_ITERATIONS .. " to combine actions")
    end
    return allActions
end

-- TODO: provide bonus for moves that move a lot of ships? (large movements rather than a few small ones?? for efficiency?)
-- TODO: combine actions for expand mind and deal with "waiting" a bit
-- TODO: which mind should be responsible for not expanding if ANY "front" planet could be rushed by enemy? Try execute plan, reserving ships for expansion, AND try all out attack?
-- see if they are still able to defend? attack against all front planets?

function combineActions(a1, a2, multiSelect)
    -- incompatible actions
    if a1.actionType ~= a2.actionType then return end
    if a1.target.n ~= a2.target.n then return end
    -- TODO: how to combine actions from different minds??
    if a1.mind.name ~= a2.mind.name then return end
    local combinedAction = doCombineActions(a1, a2)
    return combinedAction
end

function doCombineActions(a1, a2, multiSelect)
    local priority = a1.initialPriority + a2.initialPriority
    local desc = "COMBO{".. a1.description .. "|" .. a2.description .. "}"

    local a1SourceIdSet = Set.new()
    a1SourceIdSet:addAll(common_utils.map(a1.sources, function (s) return s.n end))
    local a2SourceIdSet = Set.new()
    a2SourceIdSet:addAll(common_utils.map(a2.sources, function (s) return s.n end))
    local sourcesEquivalent = a1SourceIdSet:symmetricDifference(a2SourceIdSet):size() == 0
    local sourcesAreDisjoint = a1SourceIdSet:intersection(a2SourceIdSet):size() == 0

    local combinedPlans = {}
    combinedPlans = common_utils.combineLists(combinedPlans, a1.plans)
    combinedPlans = common_utils.combineLists(combinedPlans, a2.plans)

    -- TODO: should not combine two new plans to help solve expansion bug? can combine new plan and old plan though or 2 old plans
    if a1.actionType == ACTION_TYPE_REDIRECT then
        -- TODO: for now, only combine if sources are not intersecting at all.
        if sourcesEquivalent then
            local combinedSources = common_utils.combineLists(a1.sources, a2.sources)
            return Action.newRedirect(priority, a1.mind, desc, combinedPlans, combinedSources, a1.target)
        end
    elseif a1.actionType == ACTION_TYPE_SEND then
        -- combine from same sources, adding percentages
        if sourcesEquivalent then
            -- TODO: combining percents may not be perfectly efficient because ceil(a) + ceil(b) >= ceil(a + b)
            local percent = a1.percent + a2.percent
            if percent > 100 then return end

            return Action.newSend(priority, a1.mind, desc, combinedPlans, a1.sources, a1.target, percent)
        -- TODO: for now, only combine if sources are completely disjoint
        elseif sourcesAreDisjoint and multiSelect then
            -- if percents are too different, don't try to combine
            if math.abs(a1.percent - a2.percent) > 40 then return end

            local combinedSources = common_utils.combineLists(a1.sources, a2.sources)
            
            -- if percents are the same, this is easy.
            if a1.percent == a2.percent then
                return Action.newSend(priority, a1.mind, desc, combinedPlans, combinedSources, a1.target, a1.percent)
            end

            -- we want to send the same number of ships, if possible, so send a single percentage that sends the same number
            -- TODO: combining percents may not be perfectly efficient because ceil(a) + ceil(b) + ... >= ceil(a + b + ...)
            local shipsToSend = 0
            local totalAvailable = 0
            for i,source in ipairs(a1.sources) do 
                shipsToSend = shipsToSend + a1.percent / 100 * source.ships
                totalAvailable = totalAvailable + source.ships
            end
            for i,source in ipairs(a2.sources) do 
                shipsToSend = shipsToSend + a2.percent / 100 * source.ships
                totalAvailable = totalAvailable + source.ships
            end
            local combinedPercent = math.ceil(shipsToSend / totalAvailable * 100 / 5) * 5
            assert.is_true(combinedPercent >= 5 and combinedPercent <= 100)

            return Action.newSend(priority, a1.mind, desc, combinedPlans, combinedSources, a1.target, combinedPercent)
        end
    end
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

