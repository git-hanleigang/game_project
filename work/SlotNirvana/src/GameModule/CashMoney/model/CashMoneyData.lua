--[[
Author: dhs
Date: 2022-04-19 11:14:42
LastEditTime: 2022-04-19 11:14:43
LastEditors: your name
Description: CashMoney 道具通用化 数据解析
FilePath: /SlotNirvana/src/GameModule/CashMoney/model/CashMoneyData.lua
--]]
local BaseGameModel = require("GameBase.BaseGameModel")
local CashMoneyData = class("CashMoneyData", BaseGameModel)
local CashMoneyGameData = util_require("GameModule.CashMoney.model.CashMoneyGameData")
local CashMoneyConfig = util_require("GameModule.CashMoney.config.CashMoneyConfig")

function CashMoneyData:ctor()
    CashMoneyData.super.ctor(self)
    self:setRefName(G_REF.CashMoney)
end

function CashMoneyData:parseData(_data)
    -- 存有所有的CashMoney数据的table
    self.m_cashMoneyGameList = {}
    -- 存有正常途径获得的CashMoney
    self.m_normalGameList = {}
    -- 存有投放来源的CashMoney
    self.m_putGameList = {}
    local tempList = {}
    local tempNormalList = {}
    local tempPutList = {}
    if _data and #_data > 0 then
        for i = 1, #_data do
            local gameData = CashMoneyGameData:create()
            gameData:parseData(_data[i])
            local nowGameId = gameData:getGameId()
            local gameSource = gameData:getSource()
            local tempDataList = {
                gameData = gameData,
                gameId = nowGameId
            }
            tempList[nowGameId] = tempDataList
            if gameSource == "CashBonus" then
                tempNormalList[nowGameId] = tempDataList
            else
                tempPutList[nowGameId] = tempDataList
            end
        end
    end
    self.m_cashMoneyGameList = tempList
    self.m_normalGameList = tempNormalList
    self.m_putGameList = tempPutList
end

-- 将所有CaskMoney的小游戏数据都返回给外部
function CashMoneyData:getGameList()
    return self.m_cashMoneyGameList
end

function CashMoneyData:getGameListByType(_type)
    if _type == CashMoneyConfig.DATA_TYPE.CASHBONUS then
        return self.m_normalGameList
    else
        return self.m_putGameList
    end
end

return CashMoneyData
