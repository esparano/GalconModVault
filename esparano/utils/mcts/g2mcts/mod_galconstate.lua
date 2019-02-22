require("mod_galconplayer")
require("mod_set")

function _m_init()
    local GalconState = {}

    local BOARD_SIZE = 3
    local ACTION_ROW_POSITION = 0
    local ACTION_COLUMN_POSITION = 1
    local FINAL_ROUND = 9

    GalconState.EMPTY = "-"
    GalconState.CROSS = "X"
    GalconState.NOUGHT = "O"

    local function initializePlayers()
        local players = {}
        players[GalconState.CROSS] = GalconPlayer.new(GalconState.CROSS)
        players[GalconState.NOUGHT] = GalconPlayer.new(GalconState.NOUGHT)
        return players
    end

    local function initializeEmptyBoard()
        local board = {}
        for i = 1, BOARD_SIZE do
            board[i] = {}
            for j = 1, BOARD_SIZE do
                board[i][j] = GalconState.EMPTY
            end
        end
        return board
    end

    local function boardContainsPlayersFullRow(board, player)
        for i = 1, BOARD_SIZE do
            if
                (board[i][1] == player:getMarker() and board[i][2] == player:getMarker() and
                    board[i][3] == player:getMarker())
             then
                return true
            end
        end
        return false
    end

    local function boardContainsPlayersFullColumn(board, player)
        for i = 1, BOARD_SIZE do
            local marker = player:getMarker()
            local equal = true
            for j = 1, BOARD_SIZE do
                equal = equal and board[j][i] == marker
            end
            if equal then
                return true
            end
        end
        return false
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
        board[row][column] = GalconState.EMPTY
    end

    function GalconState:undoAction(action)
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

    function GalconState:applyAction(action)
        validateAction(self, action)
        doApplyAction(self, action)
        self:selectNextPlayer()
        return self
    end

    function GalconState:setBoard(board)
        local b = {}
        for i = 1, #board do
            b[i] = {}
            for j = 1, #board[1] do
                b[i][j] = board[i][j]
            end
        end
        self._board = b
    end

    function GalconState:getBoard()
        return self._board
    end

    function GalconState:getCurrentAgent()
        return self._players[self._currentPlayerIndex]
    end

    function GalconState:getPreviousAgent()
        return self._players[self._previousPlayerIndex]
    end

    function GalconState:specificPlayerWon(player)
        return TODO.TODO
    end

    function GalconState:specificPlayerLost(player)
        return TODO.TODO
    end

    function GalconState:somePlayerWon()
        return self:specificPlayerWon(self:getCurrentAgent()) or self:specificPlayerWon(self:getPreviousAgent())
    end

    function GalconState:isTerminal()
        return self:somePlayerWon()
    end

    function GalconState:skipCurrentAgent()
        return self
    end

    function GalconState:selectNextPlayer()
        local tmp = self._currentPlayerIndex
        self._currentPlayerIndex = self._previousPlayerIndex
        self._previousPlayerIndex = tmp
    end

    function GalconState:getNumAvailableActions()
        return self:getAvailableActions():size()
    end

    local function generateActionFromBoardPosition(i, j)
        return "" .. i .. j
    end

    function GalconState:getAvailableActions()
        local availableActions = Set.new()
        for i = 1, BOARD_SIZE do
            for j = 1, BOARD_SIZE do
                if self._board[i][j] == GalconState.EMPTY then
                    local action = generateActionFromBoardPosition(i, j)
                    availableActions:add(action)
                end
            end
        end
        return availableActions
    end

    function GalconState.new(map, players)
        local instance = {}
        for k, v in pairs(GalconState) do
            instance[k] = v
        end
        instance._map = map
        instance._players = players
        instance._currentPlayerIndex = GalconState.CROSS
        instance._previousPlayerIndex = GalconState.NOUGHT
        return instance
    end

    return GalconState
end
GalconState = _m_init()
_m_init = nil
