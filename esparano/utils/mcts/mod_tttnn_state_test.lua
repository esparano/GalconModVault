require("mod_assert")
require("mod_tttnn_state")

local EMPTY_BOARD = {
    {"-", "-", "-"},
    {"-", "-", "-"},
    {"-", "-", "-"}
}

local NON_TERMINAL_BOARD = {
    {"X", "-", "O"},
    {"-", "O", "-"},
    {"X", "X", "-"}
}

local DRAW_BOARD = {
    {"X", "O", "X"},
    {"X", "O", "X"},
    {"O", "X", "O"}
}

local NOUGHT_WON_FULL_BOARD = {
    {"X", "O", "O"},
    {"X", "O", "X"},
    {"O", "X", "O"}
}

local CROSS_WON_COLUMN_BOARD1 = {
    {"X", "O", "-"},
    {"X", "O", "-"},
    {"X", "-", "O"}
}

local state
local noughtPlayer
local crossPlayer

function before()
    state = TicTacToeState.new()
    crossPlayer = state:getCurrentAgent()
    noughtPlayer = state:getPreviousAgent()
end

function test_predict()
    state:setBoard(NON_TERMINAL_BOARD)
    local player = state:getCurrentAgent()
    local reward = player:getRewardFromTerminalState(state)
    assert.not_equals(0, reward)
    assert.not_equals(0.5, reward)
    assert.not_equals(1, reward)
end

function test_reward_draw()
    state:setBoard(DRAW_BOARD)
    local player = state:getCurrentAgent()
    local reward = player:getRewardFromTerminalState(state)
    assert.equals(0.5, reward)
end

function test_reward_win()
    state:setBoard(CROSS_WON_COLUMN_BOARD1)
    local player = state:getCurrentAgent()
    local reward = player:getRewardFromTerminalState(state)
    assert.equals(1, reward)
end

function test_reward_lose()
    state:setBoard(NOUGHT_WON_FULL_BOARD)
    local player = state:getCurrentAgent()
    local reward = player:getRewardFromTerminalState(state)
    assert.equals(0, reward)
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")
