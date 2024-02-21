--[[
]]
local PerlinkData = util_require("GameModule.LeveDashLinko.model.PerlinkData")

local BaseGameModel = require("GameBase.BaseGameModel")
local LeveDashLinkoData = class("LeveDashLinkoData", BaseGameModel)

function LeveDashLinkoData:ctor()
    self:setRefName(G_REF.LeveDashLinko)
end

-- 走客户端配置
function LeveDashLinkoData:getThemeName()
    return G_REF.LeveDashLinko
end

-- message PerlinkData {
--     optional int32 pearlsLinkTimes = 1; //中间气泡球的数量
--     repeated PearlsLinkGame pearlsLinkGame = 2;//小游戏
--   }

function LeveDashLinkoData:parseData(_netData)
    self.p_pearlsLinkTimes = _netData.pearlsLinkTimes
    self.p_games = {}
    if _netData.pearlsLinkGame ~= nil and #_netData.pearlsLinkGame > 0 then
        for i = 1, #_netData.pearlsLinkGame do
            local gameData = PerlinkData:create()
            gameData:parseData(_netData.pearlsLinkGame[i])
            table.insert(self.p_games, gameData)
        end
    end
end

function LeveDashLinkoData:getGames()
    return self.p_games
end

function LeveDashLinkoData:getGameDataById(_id)
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

function LeveDashLinkoData:getNewestGameData()
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

function LeveDashLinkoData:isHaveUnActiveGame()
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

function LeveDashLinkoData:checkReconnectGame()
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

function LeveDashLinkoData:getCenterBallCount()
    return self.pearlsLinkTimes
end

return LeveDashLinkoData
