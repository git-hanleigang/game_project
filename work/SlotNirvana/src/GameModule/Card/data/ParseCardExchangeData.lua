-- 解析wild卡请求兑换数据
-- 数据结构 CARDEXCHANGERESPONSE
--[[-- 
("cardInfo"   ,..., 1 , false , nil , "struct" ,  CARDDROPINFO  )     --获得新卡数据
("wheelConfig",..., 1 , false , nil , "struct" ,  CARDWHEELCONFIG  )  --返回兑换卡片年度的回收机信息
]]
local ParseCardDropData = require("GameModule.Card.data.ParseCardDropData")
local ParseRecoverData = require("GameModule.Card.data.ParseRecoverData")
local ParseCardExchangeData = class("ParseCardExchangeData")

function ParseCardExchangeData:ctor()
end

function ParseCardExchangeData:parseData(data)
    if data.cardInfo and data.cardInfo.source ~= nil and data.cardInfo.source ~= "" then
        self.cardInfo = ParseCardDropData:create()
        self.cardInfo:parseData(data.cardInfo)
    end

    if data.wheelConfig and data.wheelConfig.coolDown ~= nil then
        self.wheelConfig = ParseRecoverData:create()
        self.wheelConfig:parseData(data.wheelConfig)
    end

    -- 同步金币
    if data and data:HasField("simpleUser") then
        -- globalData.userRunData:setCoins(data.simpleUser.coins)
        globalData.userRunData:setCoins(data.simpleUser.coinsV2)
    end

    -- 检测是否需要更新 CommonConfig 信息
    if data and data:HasField("config") then
        globalData.syncUserConfig(data.config)
    end
end

return ParseCardExchangeData
