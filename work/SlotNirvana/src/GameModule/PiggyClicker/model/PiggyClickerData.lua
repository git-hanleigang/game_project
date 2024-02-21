--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-13 10:21:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-13 10:21:42
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/model/PiggyClickerData.lua
Description: 快速点击小游戏 游戏数据
--]]
local BaseGameModel = require("GameBase.BaseGameModel")
local PiggyClickerGameData = import(".PiggyClickerGameData")
local PiggyClickerData = class("PiggyClickerData", BaseGameModel)

function PiggyClickerData:ctor()
    PiggyClickerData.super.ctor(self)

    self.m_gameDataList = {}
    self:setRefName(ACTIVITY_REF.PiggyClicker)
end

function PiggyClickerData:parseData(data)
    local newGameDataList = {}
    if data and #data > 0 then
        for i = 1, #data do
            local gameData = PiggyClickerGameData:create()
            gameData:parseData(data[i])
            table.insert(newGameDataList, gameData)
        end
    end
    if self.m_bInit then
        self.m_bGainNewGame = #newGameDataList > #self.m_gameDataList
    end
    self.m_bInit = true
    self.m_gameDataList = newGameDataList
end

-- 获取所有
function PiggyClickerData:getAllGameDataList()
    return self.m_gameDataList
end

-- 获取新获得的 小游戏数据
function PiggyClickerData:getNewGameData()
    return self.m_gameDataList[#self.m_gameDataList]
end
function PiggyClickerData:getGameDataByIdx(_idx)
    for _, _gameData in ipairs(self.m_gameDataList) do
        local gameIdx = _gameData:getGameIdx() 
        if _idx == gameIdx then
            return _gameData
        end
    end
end

-- 游戏结束删除数据
function PiggyClickerData:removeGameDataByIdx(_idx)
    local delIdx
    for i=1, #self.m_gameDataList do
        local gameData = self.m_gameDataList[i]
        local gameIdx = gameData:getGameIdx() 
        if _idx == gameIdx then
            delIdx = i
            break
        end
    end
    if delIdx then
        table.remove(self.m_gameDataList, delIdx)
    end
end

-- 是否 获得 新的小游戏数据
function PiggyClickerData:checkIsGainNewGame()
    return self.m_bGainNewGame
end
function PiggyClickerData:resetGainNewGame()
    self.m_bGainNewGame = false
end

return PiggyClickerData
