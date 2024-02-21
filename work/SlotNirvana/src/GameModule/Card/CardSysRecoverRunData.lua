--[[
    回收机 运行时数据
]]
local ParseCardWheelAllCardsData = require("GameModule.Card.data.ParseCardWheelAllCardsData")
local CardSysRecoverRunData = class("CardSysRecoverRunData")
function CardSysRecoverRunData:ctor()
end

-- 设置回收机可回收年度的所有卡片数据 --
function CardSysRecoverRunData:setCardWheelAllCardsInfo(tInfo)
    self.m_CardWheelAllCardsInfo = ParseCardWheelAllCardsData:create()
    self.m_CardWheelAllCardsInfo:parseData(tInfo)
end

-- 获取回收机可回收年度的所有卡片数据 --
function CardSysRecoverRunData:getCardWheelAllCardsInfo(tInfo)
    return self.m_CardWheelAllCardsInfo.cards
end

return CardSysRecoverRunData
