local BaseGameModel = require("GameBase.BaseGameModel")

local ShopItem = util_require("data.baseDatas.ShopItem")

local DartsGameData = class("DartsGameData", BaseGameModel)
local DartsGameSingleData = util_require("activities.Activity_DartsGameNew.model.DartsGameSingleData"):create()

function DartsGameData:ctor()
    DartsGameData.super.ctor(self)

    self._allGameDataArray = {}
end

function DartsGameData:parseData(data)
    local lenBeforeSync = self:getGameListLen()
    DartsGameData.super.parseData(self,data)
    if data and #data > 0 then
        for i = 1, #data do
            local gameData
            local d = data[i]
            local index = d.index
            if not self._allGameDataArray[index] then
                gameData = DartsGameSingleData:create()
                self._allGameDataArray[index] = gameData
            else
                gameData = self._allGameDataArray[index]
            end
            gameData:parseData(data[i])
            release_print(string.format("Darts Index:%s leftTime:%s",tostring(index),tostring(gameData and gameData._leftItems)))
        end
    end
    if self._isInit then
        self._isHaveNewGame = self:getGameListLen() > lenBeforeSync
    end
    if not self._isInit then
        self._isInit = true
    end
end

function DartsGameData:getGameList()
    return self._allGameDataArray
end

function DartsGameData:getCurGameOrCanPlayGame(index)
    --首先找正在玩并还能玩的
    local gameList = self:getGameList()
    for k,v in pairs(gameList) do
        if v:canPlay() and v:getStatus() == 1 then
            return v
        end
    end

    --再找根据传入下标的
    if index and self:getGameDataBuyIndex(index) and self:getGameDataBuyIndex(index):canPlay() then
        return self:getGameDataBuyIndex(index)
    end

    --再随便找一个
    for k,v in pairs(gameList) do
        if v:canPlay() then
            return v
        end
    end
end

function DartsGameData:getGameDataBuyIndex(index)
    return self._allGameDataArray and self._allGameDataArray[index]
end

function DartsGameData:removeGameDataByIndex(index)
    if self._allGameDataArray[index] then
        self._allGameDataArray[index] = nil
    end
end

function DartsGameData:getGameListLen()
    local i = 0
    for k,v in pairs(self._allGameDataArray) do
        i = i + 1
    end
    return i
end

function DartsGameData:checkIsGainNewGame()
    return self._isHaveNewGame or false
end

function DartsGameData:getNewGameData()
    local maxIndex = -1
    for k,v in pairs(self._allGameDataArray) do
        if v:getIndex() > maxIndex then
            maxIndex = v:getIndex()
        end
    end
    return self._allGameDataArray[maxIndex]
end

function DartsGameData:resetGainNewGame()
    self._isHaveNewGame = false
end

return DartsGameData