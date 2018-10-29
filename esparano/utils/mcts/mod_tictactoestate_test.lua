require("mod_assert")
require("mod_tictactoestate")

local EMPTY_BOARD = {
    {'-', '-', '-'},
    {'-', '-', '-'},
    {'-', '-', '-'}
};

local NON_TERMINAL_BOARD = {
    {'X', '-', 'O'},
    {'-', 'O', '-'},
    {'X', 'X', '-'}
};

local DRAW_BOARD = {
    {'X', 'O', 'X'},
    {'X', 'O', 'X'},
    {'O', 'X', 'O'}
};

local NOUGHT_WON_DIAGONAL_BOARD1 = {
    {'O', '-', '-'},
    {'X', 'O', 'X'},
    {'-', '-', 'O'}
};

local NOUGHT_WON_DIAGONAL_BOARD2 = {
    {'-', '-', 'O'},
    {'X', 'O', 'X'},
    {'O', '-', '-'}
};

local NOUGHT_WON_FULL_BOARD = {
    {'X', 'O', 'O'},
    {'X', 'O', 'X'},
    {'O', 'X', 'O'}
};

local CROSS_WON_COLUMN_BOARD1 = {
    {'X', 'O', '-'},
    {'X', 'O', '-'},
    {'X', '-', 'O'}
};

local CROSS_WON_COLUMN_BOARD2 = {
    {'O', 'X', '-'},
    {'-', 'X', 'O'},
    {'-', 'X', 'O'}
};

local CROSS_WON_COLUMN_BOARD3 = {
    {'O', 'O', 'X'},
    {'-', '-', 'X'},
    {'-', 'O', 'X'}
};

local CROSS_WON_ROW_BOARD1 = {
    {'X', 'X', 'X'},
    {'O', '-', '-'},
    {'O', '-', 'O'}
};

local CROSS_WON_ROW_BOARD2 = {
    {'-', 'O', '-'},
    {'X', 'X', 'X'},
    {'-', 'O', 'O'}
};

local CROSS_WON_ROW_BOARD3 = {
    {'-', 'O', '-'},
    {'O', '-', '-'},
    {'X', 'X', 'X'}
};

local state
local noughtPlayer
local crossPlayer

function before()
    state = TicTacToeState.new()
    crossPlayer = state:getCurrentAgent()
    noughtPlayer = state:getPreviousAgent()
end

function test_available_functions()
    assert.not_equals(nil, TicTacToeState)
    assert.not_equals(nil, TicTacToeState.new)
    local root = TicTacToeState.new()
    for k,v in pairs(root) do
        --print(k)
    end
end

function test_local_functions()
    assert.equals(nil, new)
    assert.equals(nil, _m_init)
    assert.equals(nil, initializeEmptyBoard)
end
 
function test_WinPlayersFullRow()
    state:setBoard(CROSS_WON_ROW_BOARD1);
    assert.is_true(state:specificPlayerWon(crossPlayer))
    assert.is_false(state:specificPlayerWon(noughtPlayer))
    state:setBoard(CROSS_WON_ROW_BOARD2);
    assert.is_true(state:specificPlayerWon(crossPlayer))
    assert.is_false(state:specificPlayerWon(noughtPlayer))
    state:setBoard(CROSS_WON_ROW_BOARD3);
    assert.is_true(state:specificPlayerWon(crossPlayer))
    assert.is_false(state:specificPlayerWon(noughtPlayer))
end

function test_WinPlayersFullColumn()
    state:setBoard(CROSS_WON_COLUMN_BOARD1);
    assert.is_true(state:specificPlayerWon(crossPlayer))
    assert.is_false(state:specificPlayerWon(noughtPlayer))
    state:setBoard(CROSS_WON_COLUMN_BOARD2);
    assert.is_true(state:specificPlayerWon(crossPlayer))
    assert.is_false(state:specificPlayerWon(noughtPlayer))
    state:setBoard(CROSS_WON_COLUMN_BOARD3);
    assert.is_true(state:specificPlayerWon(crossPlayer))
    assert.is_false(state:specificPlayerWon(noughtPlayer))
end

function test_WinPlayersFullDiagonal()
    state:setBoard(NOUGHT_WON_DIAGONAL_BOARD1);
    assert.is_false(state:specificPlayerWon(crossPlayer))
    assert.is_true(state:specificPlayerWon(noughtPlayer))
    state:setBoard(NOUGHT_WON_DIAGONAL_BOARD2);
    assert.is_false(state:specificPlayerWon(crossPlayer))
    assert.is_true(state:specificPlayerWon(noughtPlayer))
end

function test_NonTerminalState()
    state:setBoard(NON_TERMINAL_BOARD);
    assert.is_false(state:specificPlayerWon(crossPlayer))
    assert.is_false(state:specificPlayerWon(noughtPlayer))
end

function test_IsDraw()
    state:setBoard(NOUGHT_WON_DIAGONAL_BOARD2)
    assert.is_false(state:isDraw())
    state:setBoard(DRAW_BOARD)
    assert.is_true(state:isDraw())
    state:setBoard(NOUGHT_WON_FULL_BOARD)
    assert.is_false(state:isDraw())
end

function test_IsTerminal()
    state:setBoard(EMPTY_BOARD)
    assert.is_false(state:isTerminal())
    state:setBoard(NON_TERMINAL_BOARD)
    assert.is_false(state:isTerminal())
    state:setBoard(NOUGHT_WON_DIAGONAL_BOARD2)
    assert.is_true(state:isTerminal())
    state:setBoard(DRAW_BOARD)
    assert.is_true(state:isTerminal())
end

function test_applyValidAction()
    state:setBoard(NON_TERMINAL_BOARD)
    local expectedBoard = {
        {'X', 'O', 'O'},
        {'-', 'O', '-'},
        {'X', 'X', '-'}
    };
    
    state:applyAction("12")
    
    local actualBoard = state:getBoard()
    for i=1,#expectedBoard do
        for j=1,#expectedBoard[1] do
            assert.equals(expectedBoard[i][j], actualBoard[i][j])
        end
    end
end

function test_applyInvalidAction()
    state:setBoard(NON_TERMINAL_BOARD)
    state:applyAction("12")
    state:applyAction("21")
    state:applyAction("23")
    state:applyAction("33")
    print("should fail validation:")
    state:applyAction("13")
end

function test_getAvailableActions()
      state:setBoard(NON_TERMINAL_BOARD)
      local availableActions = state:getAvailableActions()
      assert.is_true(availableActions:contains("12"))
      assert.is_true(availableActions:contains("21"))
      assert.is_true(availableActions:contains("23"))
      assert.is_true(availableActions:contains("33"))
      assert.equals(4, state:getNumAvailableActions());
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")