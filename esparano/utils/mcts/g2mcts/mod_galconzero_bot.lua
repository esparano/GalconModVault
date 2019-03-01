require("mod_galconstate")
require("mod_galconplayer_classicbot")
require("mod_mcts")
require("mod_map_wrapper")

local function cloneState(state)
    return GalconState.new(Map.copy(state._map), state._currentAgent, state._previousAgent)
end

local function getOtherPlayerN(map, userN)
    for i, p in pairs(map:getPlanetList()) do
        if not p.neutral and p.owner ~= userN then
            return p.owner
        end
    end
end

local function setupMcts(items, userN)
    return mcts, agent, enemyAgent
end

function bot_galconzero(params, sb_stats)
    G = params.items
    USER = params.user
    OPTS = params.opts
    MEM = params.memory
    MEM.t = (MEM.t or 0) + 1
    if MEM.t % 4 ~= 0 then
        return
    end

    local map = Map.new(G)
    -- TODO: refactor this?
    local enemyN = getOtherPlayerN(map, USER)
    if enemyN == nil then
        print("no enemy detected")
        return
    end
    local agent = GalconPlayer.new(USER)
    local enemyAgent = GalconPlayer.new(enemyN)
    local startState = GalconState.new(map, agent, enemyAgent)
    local mcts = Mcts.new(cloneState)
    mcts:startUtcSearch(startState)

    local ticks, alloc = sb_stats()
    while ticks < 10000 and alloc < 10000 do
        -- for i=1,1 do
        --[[
        print("starting iteration!!! ticks: " ..
                ticks .. ", alloc: " .. alloc .. ", reward: " .. mcts._rootNode:getDomainTheoreticValue())
        --]]
        mcts:nextIteration(0.1, sb_stats)
        ticks, alloc = sb_stats()
    end

    local iterations = mcts._rootNode._visitCount
    local initEval = agent:getRewardFromState(mcts._rootNode._state)
    local mctsEval = -mcts._rootNode:getDomainTheoreticValue()
    print("iterations: " .. iterations .. ", initEval: " .. initEval .. ", mctsEval: " .. mctsEval)

    local moveStr = mcts:finish()
    local move = GalconState.parseMove(moveStr, map)
    if move.actionType == GalconState.NULL_MOVE then
        return
    elseif move.actionType == GalconState.SEND then
        return {percent = move.perc, from = move.from.n, to = move.to.n}
    elseif move.actionType == GalconState.REDIRECT then
        return {from = move.from.n, to = move.to.n}
    else
        error("UNRECOGNIZED ACTION TYPE")
    end
end
