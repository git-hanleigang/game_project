--[[
]]
local LuckFishGameData = util_require("GameModule.Plinko.model.LuckFishGameData")

local BaseGameModel = require("GameBase.BaseGameModel")
local PlinkoData = class("PlinkoData", BaseGameModel)

function PlinkoData:ctor()
    self:setRefName(G_REF.Plinko)
end

-- 走客户端配置
function PlinkoData:getThemeName()
    return PlinkoConfig.themeName
end

-- message LuckFishGameData {
--     optional int32 centreBallCount = 1; //中间气泡球的数量
--     repeated LuckFishGame games = 2;//小游戏
--   }

function PlinkoData:parseData(_netData)
    self.p_centreBallCount = _netData.centreBallCount
    self.p_games = {}
    if _netData.games ~= nil and #_netData.games > 0 then
        for i = 1, #_netData.games do
            local gameData = LuckFishGameData:create()
            gameData:parseData(_netData.games[i])
            table.insert(self.p_games, gameData)
        end
    end
end

function PlinkoData:getGames()
    return self.p_games
end

function PlinkoData:getGameDataById(_id)
    if self.p_games and #self.p_games > 0 then
        for i = 1, #self.p_games do
            local gameData = self.p_games[i]
            if gameData:getIndex() == _id then
                return gameData
            end
        end
    end
    return nil
end

function PlinkoData:getNewestGameData()
    local maxExpireAt = nil
    local newestGameId = nil
    for k, v in pairs(self.p_games) do
        if v:getGameStatus() ~= PlinkoConfig.GameStatus.Finish and v:getLeftTime() > 0 then
            local expireAt = v:getExpireAt()
            local gameId = v:getIndex()

            if not maxExpireAt then
                maxExpireAt = expireAt
                newestGameId = gameId
            end
            if expireAt > maxExpireAt then
                maxExpireAt = expireAt
                newestGameId = gameId
            end
        end
    end
    if newestGameId ~= nil then
        return self:getGameDataById(newestGameId)
    end
    return nil
end

function PlinkoData:isHaveUnActiveGame()
    if self.p_games and #self.p_games > 0 then
        for i = 1, #self.p_games do
            local gameData = self.p_games[i]
            if gameData:getGameStatus() == PlinkoConfig.GameStatus.Init and gameData:getLeftTime() > 0 then
                return true
            end
        end
    end
    return false
end

function PlinkoData:checkReconnectGame()
    if self.p_games and #self.p_games > 0 then
        for i = 1, #self.p_games do
            local gameData = self.p_games[i]
            if gameData:getGameStatus() == PlinkoConfig.GameStatus.Playing then
                return gameData:getIndex()
            end
        end
    end
    return -1
end

function PlinkoData:getCenterBallCount()
    return self.p_centreBallCount
end

return PlinkoData
