--[[
]]
local BaseGameModel = require("GameBase.BaseGameModel")
local DuckShotGameData = import(".DuckShotGameData")
local DuckShotData = class("DuckShotData", BaseGameModel)

function DuckShotData:ctor()
    DuckShotData.super.ctor(self)

    self.m_dataList = {}
    self:setRefName(ACTIVITY_REF.DuckShot)
end

function DuckShotData:parseData(data, _isLogon)
    local temp = {}
    if data and #data > 0 then
        for i = 1, #data do
            local gameData = DuckShotGameData:create()
            gameData:parseData(data[i])
            local nIndexGame = gameData:getIndex()
            local tempList = 
            {
                gameData = gameData,
                gameIndex = nIndexGame
            }
            if self.m_dataList[nIndexGame] or _isLogon then 
                tempList.notNewGame = true
            end
            temp[nIndexGame] = tempList
        end
    end
    self.m_dataList = temp
end

function DuckShotData:getList()
    return self.m_dataList
end

return DuckShotData
