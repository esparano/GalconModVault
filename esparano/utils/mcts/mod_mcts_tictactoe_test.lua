require("mod_assert")
require("mod_mcts")
require("mod_tictactoestate")

local NUM_GAMES = 1
local NUM_ITERATIONS = 100
local EXPLORATION_PARAMETER = 0.4

local function deepCopy(o)
    if type(o) ~= 'table' then return o end
    local r = {}
    for k,v in pairs(o) do r[k] = deepCopy(v) end
    return r
end

function test_uctSearch()
    local mcts = Mcts.new(deepCopy)
    for i=1,NUM_GAMES do
        local initialState = TicTacToeState.new()
        playOneTicTacToeGame(mcts, initialState)
        assert.is_true(initialState:isDraw())
    end
end

function test_performance()
    local totalInstructions = 0
    local totalMem = 0
    local numGames = 10
    for i=1,numGames do
        local ok,msg = g2_sandbox(function()
            local a = {}
            playOneTicTacToeGame(Mcts.new(deepCopy), TicTacToeState.new())
            local instructions, mem = g2_sandbox_stats()
            totalInstructions = totalInstructions + instructions
            totalMem = totalMem + mem
        end, 1000000, 10000) -- 1B instructions, 100MB memory
        if not ok then
            error(msg)
        end
    end
    print("avg instructions: " .. totalInstructions/numGames .. " k")
    --print("avg mem: " .. totalMem/numGames .. " MB")
end

function playOneTicTacToeGame(mcts, state)
    while not state:isTerminal() do
        mcts:startUtcSearch(state, EXPLORATION_PARAMETER)
        for i=1,NUM_ITERATIONS do
            mcts:nextIteration()
        end 
        local chosenAction = mcts:finish()
        state:applyAction(chosenAction)
    end
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")