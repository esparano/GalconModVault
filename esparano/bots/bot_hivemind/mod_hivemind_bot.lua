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
require("mod_hivemind_utils")
require("mod_logger")

function firstTurnSetup(params)
    logger:debug("first turn setup")
end

function getOptsForMind(mindName, params)
    local mindParams = {}
    for k,v in pairs(params.optimized) do 
        local tokens = {}
        for token in string.gmatch(k, "[^_]+") do 
            table.insert(tokens, token)
        end
        if string.lower(tokens[1]) == string.lower(mindName) then 
            local optKey = string.sub(k,  #mindName + 2)
            mindParams[optKey] = v
        end
    end
    for k,v in pairs(params.passThrough) do 
        mindParams[k] = v
    end
    mindParams.settings = params.settings
    return mindParams
end

function initMinds(params) 
    local minds = {}
    -- Reserves ships from planned neutral captures. Should analyze earlier than most other minds.
    table.insert(minds, ExpandMind.new(getOptsForMind("expand", params)))
    -- Reserves ships for defense. Should analyze earlier than most other minds.
    table.insert(minds, DefendMind.new(getOptsForMind("defend", params)))
    table.insert(minds, AttackMind.new(getOptsForMind("attack", params)))
    -- table.insert(minds, CenterControlMind.new(getOptsForMind("centercontrol", params)))
    -- table.insert(minds, CleanupMind.new(getOptsForMind("cleanup", params)))
    -- table.insert(minds, ClusterControlMind.new(getOptsForMind("clustercontrol", params)))
    -- table.insert(minds, DefendRushMind.new(getOptsForMind("defendrush", params)))
    -- table.insert(minds, EvenDistributionMind.new(getOptsForMind("evendistribution", params)))
    -- table.insert(minds, ExploitEmptyMind.new(getOptsForMind("exploitempty", params)))
    table.insert(minds, FeedFrontMind.new(getOptsForMind("feedfront", params)))
    -- table.insert(minds, FleeTrickMind.new(getOptsForMind("fleetrick", params)))
    table.insert(minds, FloatMind.new(getOptsForMind("float", params)))
    table.insert(minds, MidRushMind.new(getOptsForMind("midrush", params)))
    -- table.insert(minds, OvercaptureMind.new(getOptsForMind("overcapture", params)))
    table.insert(minds, PassMind.new(getOptsForMind("pass", params)))
    -- table.insert(minds, PressureMind.new(getOptsForMind("pressure", params)))
    -- table.insert(minds, RedirectTrickMind.new(getOptsForMind("redirecttrick", params)))
    -- table.insert(minds, RushMind.new(getOptsForMind("rush", params)))
    -- table.insert(minds, SurrenderMind.new(getOptsForMind("surrender", params)))
    -- table.insert(minds, SwapMind.new(getOptsForMind("swap", params)))
    -- table.insert(minds, TimerTrickMind.new(getOptsForMind("timertrick", params)))
    return minds
end

function bot_hivemind(params, sb_stats)
    local ITEMS = params.items
    local botUser = ITEMS[params.user]
    local defaultOptions = {
        -- TODO: fill these out
        -- percent = 100,
        name = "Hivemind",
        logLevel = Logger.WARN,
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
            expand_negativeRoiReductionFactor = 1,
            expand_overallWeight = 1,
            expand_overallBias = 1,
            feedFront_frontWeightFrontProd = 1,
            feedFront_frontWeightFrontShips = 1,
            feedFront_frontWeightNetShips = 1,
            feedFront_frontWeightStolenProd = 1,
            feedFront_frontWeightEnemyDistIntercept = 1,
            feedFront_frontWeightEnemyOverall = 1,
            feedFront_frontWeightEnemyShipsExponent = 1,
            feedFront_frontWeightEnemyProdExponent = 1,
            feedFront_frontWeightEnemyProdShipsBalance = 1,
            feedFront_frontWeightEnemyDistExponent = 1,
            feedFront_targetWeightExponent = 1,
            feedFront_targetDistExponent = 1,
            feedFront_targetDistDiscount = 1,
            feedFront_targetDistDiscountExponent = 1,
            feedFront_feedSendAmountWeight = 1,
            feedFront_feedDistWeight = 1,
            feedFront_overallWeight = 1,
            feedFront_overallBias = 1,
            attack_nearbyCapturableProdProdExponent = 1,
            attack_nearbyCapturableProdDistExponent = 1,
            attack_nearbyCapturableProdDistIntercept = 1,
            attack_nearbyUserProdProdExponent = 1,
            attack_nearbyUserProdDistExponent = 1,
            attack_nearbyUserProdDistIntercept = 1,
            attack_nearbyUserShipsShipsExponent = 1,
            attack_nearbyUserShipsDistExponent = 1,
            attack_nearbyUserShipsDistIntercept = 1,
            attack_naiveNetShipsWeight = 1,
            attack_naiveProdDiffWeight = 1,
            attack_nearbyProdDiffWeight = 1,
            attack_targetProdWeight = 1,
            attack_targetNearbyProdWeight = 1,
            attack_delayCaptureWeight = 1,
            attack_stolenProdWeight = 1,
            attack_overcaptureIncomingShipsWeight = 1,
            attack_overcapturedNearbyEnemyShipsWeight = 1,
            attack_overcapturePenalty = 1,
            attack_targetClusterWeight = 1,
            attack_emptyClusterIntercept = 1,
            attack_emptyClusterBonus = 1,
            attack_frontNetShipsWeight = 1,
            attack_targetNetShipsWeight = 1,
            attack_distIntercept = 1,
            attack_distWeight = 1,
            attack_distExponent = 1,
            attack_availableShipsExponent = 1,
            attack_overallBias = 1,
            attack_overallWeight = 1,
        },
        settings = {
            multiSelect = true,
        }
    }

    local OPTS = common_utils.mergeTableInto(defaultOptions, params.options or {})

    local MEM = params.memory
    local DEBUG = params.debug or {
        debugHighlightPlanets = common_utils.pass,
        debugDrawPaths = common_utils.pass
    }

    MEM.t = (MEM.t or 0) + 1
    if (MEM.t % 4) ~= 1 then
        -- return
    end -- do an action once per second

    logger = Logger.new(OPTS.name, OPTS.logLevel)

    local map = Map.new(ITEMS)
    local users = map:getUserList(false)
    if #users ~= 2 then 
        logger:fatal("Match is either FFA or there is no enemy. Skipping turn. #users = " .. #users)
        return
    end
    local enemyUser = map:getEnemyUser(botUser)

    MEM.mapTunnelsData = MEM.mapTunnelsData or {}
    MEM.plans = MEM.plans or {}
    -- update mapTunnelsData, then clone it for use in this function to avoid neutrals marked tunnelable from being permanently (mistakenly) tunnelable even if the map changes a lot
    local mapTunnels = MapTunnels.new(ITEMS, MEM.mapTunnelsData)
    local mapTunnels = MapTunnels.new(ITEMS, common_utils.copy(MEM.mapTunnelsData))

    local mapFuture = MapFuture.new(ITEMS, botUser)

    if not MEM.initialized then
        MEM.initialized = true
        firstTurnSetup(params)
    end

    -- set on each Mind
    OPTS.passThrough = {
        map = map,
        mapTunnels = mapTunnels,
        mapFuture = mapFuture,
        botUser = botUser,
    }

    local move = getMove(OPTS, MEM)
    logger:info("CHOOSE: " .. move:getSummary())
    logger:info("----------------------------------------")

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

function getMove(params, mem)
    -- TODO: params for genetic algorithm
    local minds = initMinds(params);

    -- update minds' state with chosen plans and update saved plans.
    local confirmedPlans = {}
    for _,mind in ipairs(minds) do
        for _,plan in ipairs(mem.plans) do
            if mind.name == plan.mindName then
                local viable = mind:processPlan(plan, confirmedPlans)
                if viable then 
                    table.insert(confirmedPlans, plan)
                end
            end
        end
    end
    mem.plans = confirmedPlans

    local candidates = {}
    for _,mind in ipairs(minds) do 
        local actions = mind:suggestActions(mem.plans)
        for _,action in ipairs(actions) do
            table.insert(candidates, action)
        end
    end

    for _,action in ipairs(candidates) do
        gradeAction(action, minds, mem.plans)
    end

    candidates = common_utils.filter(candidates, function (a) return a:getOverallPriority() >= 0 end)

    -- TODO: THIS sometimes results in situations where the bot over-sends to expand to a nearby planet, not realizing that it can't actually afford multiple neutrals.
    -- Instead, the highest-priority move should track and apply its reservations and only then determine if the secondary action is compatible.
    -- TODO: THe way that moves with different percentages get combined, it may break "reservations" slightly.
    -- candidates = getCombinedActions(candidates, minds, params.settings.multiSelect)

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

function gradeAction(action, minds, plans)
    for _,mind in ipairs(minds) do
        if mind ~= action.mind then
            -- TODO: bias and multiplier for each mind's priority and adjustments? 4 parameters? Idk.
            mind:gradeAction(action, plans)
        end
    end
end

-- TODO: make sure a combined action is not created two different ways, for example A + B + C -> AB + C or AC + B or BC + A, resulting in 3 duplicates.
-- TODO: split by mind/target/etc (split into combinable actions groups)
function getCombinedActions(actions, minds, multiSelect)
    local allActions = common_utils.shallow_copy(actions)
    local newActions = common_utils.shallow_copy(actions) 

    -- keep track of the raw/base constituent actions.
    local comboActionSourceMap = {}
    for _,a in ipairs(allActions) do
        comboActionSourceMap[a] = Set.new({a})
    end

    local iterations = 1
    local MAX_ITERATIONS = 2
    while #newActions > 0 and iterations <= MAX_ITERATIONS do
        local nextNewActions = {}

        for i,a1 in ipairs(allActions) do
            for j,a2 in ipairs(newActions) do 
                if i < j or iterations > 1 then 
                    -- Combined actions may not have any base actions in common.
                    if comboActionSourceMap[a1]:intersection(comboActionSourceMap[a2]):size() == 0 then 
                        local a = combineActions(a1, a2, multiSelect)
                        if a then
                            comboActionSourceMap[a] = comboActionSourceMap[a1]:union(comboActionSourceMap[a2])
                            gradeAction(a, minds)
                            if a:getOverallPriority() > 0 then 
                                table.insert(nextNewActions, a) 
                            end
                        end
                    end
                end
            end
        end

        allActions = common_utils.combineLists(allActions, nextNewActions)
        newActions = nextNewActions

        iterations = iterations + 1
    end
    -- assert.is_true(iterations <= MAX_ITERATIONS, "WARNING: TOOK MORE THAN " .. MAX_ITERATIONS .. " to combine actions")

    return allActions
end

-- TODO: provide bonus for moves that move a lot of ships? (large movements rather than a few small ones?? for efficiency?)
-- TODO: combine actions for expand mind and deal with "waiting" a bit
-- TODO: which mind should be responsible for not expanding if ANY "front" planet could be rushed by enemy? Try execute plan, reserving ships for expansion, AND try all out attack?
-- see if they are still able to defend? attack against all front planets?

function combineActions(a1, a2, multiSelect)
    -- incompatible actions
    if a1.actionType == ACTION_TYPE_PASS or a2.actionType == ACTION_TYPE_PASS then return end
    if a1.actionType ~= a2.actionType then return end
    if a1.target.n ~= a2.target.n then return end

    -- TODO: how to combine actions from different minds?? add priorities and regrade for all minds except originating minds?
    if a1.mind.name ~= a2.mind.name then return end

    -- TODO: for now, only combine new plans with old plans or 2 old plans, etc.
    if #a1.plans > 0 and #a2.plans > 0 then return end
    local combinedAction = doCombineActions(a1, a2, multiSelect)
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

    if a1.actionType == ACTION_TYPE_REDIRECT then
        -- only combine if sources are not intersecting at all. This is a minor simplifying assumption.
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
            assert.is_true(combinedPercent >= 5 and combinedPercent <= 100, "combined percents was not in range")

            return Action.newSend(priority, a1.mind, desc, combinedPlans, combinedSources, a1.target, combinedPercent)
        end
    end
end


