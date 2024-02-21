--[[-- 
    解析回收机回收卡片spin请求数据
]]
-- //回收机请求回收spin结果
-- message CardWheelResponse {
--   optional int32 index = 1; //轮盘中奖位置, 从0开始
--   optional int64 coins = 2; //获得金币数量
--   optional CardDropInfo cardInfo = 3; //获得新卡数据
--   repeated ShopItem rewards = 4; //其他奖励物品
-- }

local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardDropData = require("GameModule.Card.data.ParseCardDropData")
local ParseCardWheelSpinData = class("ParseCardWheelSpinData")

function ParseCardWheelSpinData:ctor()
end

function ParseCardWheelSpinData:parseData(data)
    self.index = data.index
    self.coins = tonumber(data.coins)

    if data.cardInfo and data.cardInfo.source ~= nil and data.cardInfo.source ~= "" then
        self.cardInfo = ParseCardDropData:create()
        self.cardInfo:parseData(data.cardInfo)
    end

    self.rewards = {}
    if data.rewards and #data.rewards > 0 then
        for i = 1, #data.rewards do
            local sItem = ShopItem:create()
            sItem:parseData(data.rewards[i])
            table.insert(self.rewards, sItem)
        end
    end
end

return ParseCardWheelSpinData
