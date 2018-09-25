require("mod_tttnn_player")
require("mod_set")

function _m_init()
local TicTacToeState = {}

local BOARD_SIZE = 3
local ACTION_ROW_POSITION = 0
local ACTION_COLUMN_POSITION = 1
local FINAL_ROUND = 9

TicTacToeState.EMPTY = '-'
TicTacToeState.CROSS = 'X'
TicTacToeState.NOUGHT = 'O'

local function initializePlayers()
    local players = {}
    players[TicTacToeState.CROSS] = TicTacToePlayer.new(TicTacToeState.CROSS)
    players[TicTacToeState.NOUGHT] = TicTacToePlayer.new(TicTacToeState.NOUGHT)
    return players
end

local function initializeEmptyBoard()
    local board = {}
    for i=1,BOARD_SIZE do
        board[i] = {}
        for j=1,BOARD_SIZE do
            board[i][j] = TicTacToeState.EMPTY
        end
    end
    return board
end

local function boardContainsPlayersFullRow(board, player)
    for i=1,BOARD_SIZE do
        if (board[i][1] == player:getMarker()
            and board[i][2] == player:getMarker()
            and board[i][3] == player:getMarker()) then
            return true
        end
    end
    return false
end

local function boardContainsPlayersFullColumn(board, player)
    for i=1,BOARD_SIZE do
        local marker = player:getMarker()
        local equal = true
        for j=1,BOARD_SIZE do
            equal = equal and board[j][i] == marker
        end
        if equal then return true end
    end
    return false
end

local function boardContainsPlayersFullAscendingDiagonal(board, player)
    for i=1,BOARD_SIZE do
        if board[i][BOARD_SIZE + 1 - i] ~= player:getMarker() then
            return false
        end
    end
    return true
end

local function boardContainsPlayersFullDescendingDiagonal(board, player)
    for i=1,BOARD_SIZE do
        if board[i][i] ~= player:getMarker() then
            return false
        end
    end
    return true
end

local function boardContainsPlayersFullDiagonal(board, player)
    return boardContainsPlayersFullAscendingDiagonal(board, player) 
        or boardContainsPlayersFullDescendingDiagonal(board, player)
end

local function rowFromAction(action)
    return tonumber(string.sub(action, 1, 1))
end
local function columnFromAction(action)
    return tonumber(string.sub(action, 2, 2))
end 

local function validateUndoAction(action)
    local row = rowFromAction(action)
    local column = columnFromAction(action)
    assert.is_true(1 <= row and row <= 3)
    assert.is_true(1 <= column and column <= 3)
end

local function applyUndoAction(board, action)
    local row = rowFromAction(action)
    local column = columnFromAction(action)
    board[row][column] = TicTacToeState.EMPTY
end

function TicTacToeState:undoAction(action)
    validateUndoAction(action)
    applyUndoAction(self._board, action)
    self:selectNextPlayer() 
    return self
end

local function doApplyAction(self, action) 
    local row = rowFromAction(action)
    local column = columnFromAction(action)
    self._board[row][column] = self:getCurrentAgent():getMarker()
end

local function validateAction(self, action)
    assert.is_true(self:getAvailableActions():contains(action))
end

function TicTacToeState:applyAction(action)
    validateAction(self, action)
    doApplyAction(self, action)
    self:selectNextPlayer() 
    return self
end

function TicTacToeState:setBoard(board)
    local b = {}
    for i=1,#board do
        b[i] = {}
        for j=1,#board[1] do
            b[i][j] = board[i][j]
        end
    end
    self._board = b
end

function TicTacToeState:getBoard()
    return self._board
end

function TicTacToeState:getCurrentAgent()
    return self._players[self._currentPlayerIndex]
end

function TicTacToeState:getPreviousAgent()
    return self._players[self._previousPlayerIndex]
end

function TicTacToeState:specificPlayerWon(player)
    return boardContainsPlayersFullRow(self._board, player)
        or boardContainsPlayersFullColumn(self._board, player)
        or boardContainsPlayersFullDiagonal(self._board, player)
end

function TicTacToeState:somePlayerWon()
    return self:specificPlayerWon(self:getCurrentAgent())
        or self:specificPlayerWon(self:getPreviousAgent())
end

function TicTacToeState:isTerminal()
    return self:somePlayerWon() or self:isDraw()
end

function TicTacToeState:isDraw()
    for i=1,BOARD_SIZE do
        for j=1,BOARD_SIZE do
            if self._board[i][j] == TicTacToeState.EMPTY then return false end
        end
    end
    return not self:somePlayerWon()
end

function TicTacToeState:skipCurrentAgent() 
    return self
end

function TicTacToeState:selectNextPlayer()
    local tmp = self._currentPlayerIndex
    self._currentPlayerIndex = self._previousPlayerIndex
    self._previousPlayerIndex = tmp
end

function TicTacToeState:getNumAvailableActions()
    return self:getAvailableActions():size()
end

local function generateActionFromBoardPosition(i, j) 
    return "" .. i .. j
end

function TicTacToeState:getAvailableActions()
    local availableActions = Set.new()
    for i=1,BOARD_SIZE do
        for j=1,BOARD_SIZE do
            if self._board[i][j] == TicTacToeState.EMPTY then
                local action = generateActionFromBoardPosition(i, j)
                availableActions:add(action)
            end
        end
    end
    return availableActions
end

function TicTacToeState.new()
    local instance = {}
    for k, v in pairs(TicTacToeState) do
        instance[k] = v
    end
    instance._board = initializeEmptyBoard()
    instance._players = initializePlayers()
    instance._currentPlayerIndex = TicTacToeState.CROSS
    instance._previousPlayerIndex = TicTacToeState.NOUGHT
	return instance
end

return TicTacToeState
end; TicTacToeState = _m_init(); _m_init = nil