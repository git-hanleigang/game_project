--[[
    LevelRoadGame 小游戏数据层 对数据的操作控制判断
]]

local BaseGameModel = require("GameBase.BaseGameModel")
local LevelRoadGameData = class("LevelRoadGameData",BaseGameModel)
local LevelRoadGameBaseData = util_require("activities.Activity_LevelRoadGame.model.LevelRoadGameBaseData")

function LevelRoadGameData:ctor()
    LevelRoadGameData.super.ctor(self)

    self._allGameDataArray = {}
end

function LevelRoadGameData:parseData(_dataResult)
    --local lenBeforeSync = self:getGameListLen()
    LevelRoadGameData.super.parseData(self,_dataResult)

    if _dataResult and #_dataResult.levelRoadGame > 0  then
        for i = 1, #_dataResult.levelRoadGame do
            local gameData
            local lRGame = _dataResult.levelRoadGame[i]
            local gameIndex = lRGame.index
            if not self._allGameDataArray[gameIndex] then
                gameData = LevelRoadGameBaseData:create()
                self._allGameDataArray[gameIndex] = gameData
            else
                gameData = self._allGameDataArray[gameIndex]
            end
            gameData:parseData(_dataResult.levelRoadGame[i])
        end
    end
    -- if self._isInit then
    --     self._isHaveNewGame = self:getGameListLen() > lenBeforeSync
    -- end
    -- if not self._isInit then
    --     self._isInit = true
    -- end

end

function LevelRoadGameData:getGameList()
    return self._allGameDataArray
end

function LevelRoadGameData:getOneGame(index)
    -- 取游戏列表中第一个
    local gameList = self:getGameList()
    for k,v in pairs(gameList) do
        if v.p_status ~= "END" then
            return v
        end
    end

    -- --再找根据传入下标的
    -- if index and self:getGameDataBuyIndex(index) and self:getGameDataBuyIndex(index):isCanPlay() then
    --     return self:getGameDataBuyIndex(index)
    -- end

    -- --再随便找一个
    -- for k,v in pairs(gameList) do
    --     if v:isCanPlay() then
    --         return v
    --     end
    -- end
end

function LevelRoadGameData:getGameDataBuyIndex(index)
    return self._allGameDataArray and self._allGameDataArray[index]
end

function LevelRoadGameData:removeGameDataByIndex(index)
    if self._allGameDataArray[index] then
        self._allGameDataArray[index] = nil
    end
end

function LevelRoadGameData:getGameListLen()
    local i = 0
    for k,v in pairs(self._allGameDataArray) do
        i = i + 1
    end
    return i
end

function LevelRoadGameData:checkIsGainNewGame()
    return self._isHaveNewGame or false
end


function LevelRoadGameData:getNewGameData()
    local maxIndex = -1
    for k,v in pairs(self._allGameDataArray) do
        if v:getIndex() > maxIndex then
            maxIndex = v:getIndex()
        end
    end
    return self._allGameDataArray[maxIndex]
end

function LevelRoadGameData:resetGainNewGame()
    self._isHaveNewGame = false
end

return LevelRoadGameData

