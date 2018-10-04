require("mod_assert")
require("mod_mcts")
require("mod_tictactoestate")
require("mod_profiler")

local NUM_GAMES = 1
local NUM_ITERATIONS = 300
local EXPLORATION_PARAMETER = 0.4

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

function test_uctSearch()
    local mcts = Mcts.new(deepCopy)
    for i = 1, NUM_GAMES do
        local initialState = TicTacToeState.new()
        playOneTicTacToeGame(mcts, initialState)
        assert.is_true(initialState:isDraw())
    end
end

function play_game()
    local instructions, mem
    local ok, msg =
        g2_sandbox(
        function()
            playOneTicTacToeGame(Mcts.new(deepCopy), TicTacToeState.new())
            instructions, mem = g2_sandbox_stats()
        end,
        1000000,
        10000
    ) -- 1B instructions, 100MB memory
    if not ok then
        error(msg)
    end
    return instructions, mem
end

function test_performance()
    local totalInstructions = 0
    local totalMem = 0
    local numGames = 1
    for i = 1, numGames do
        local prof = profiler.new()
        prof:profile(Mcts)

        instructions, mem = play_game()
        totalInstructions = totalInstructions + instructions
        totalMem = totalMem + mem

        prof:printData(Mcts, "Mcts")
    end
    print("avg instructions: " .. totalInstructions / numGames .. " k")
    --print("avg mem: " .. totalMem/numGames .. " MB")
end

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function playOneTicTacToeGame(mcts, state)
    while not state:isTerminal() do
        mcts:startUtcSearch(state, EXPLORATION_PARAMETER)
        for i = 1, NUM_ITERATIONS do
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
