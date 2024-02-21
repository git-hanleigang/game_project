--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-03 17:00:04
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local BFDrawData = class("BFDrawData", BaseActivityData)

--[[
    message BlackFridayCarnival {
        optional string activityId = 1;
        optional string name = 2;
        optional string begin = 3;
        optional int64 expireAt = 4;
        optional int32 expire = 5;
        optional int32 totalPoint = 6;//获得代币总数
        optional int32 point = 7;//现在代币数
        optional int32 needPoint = 8;//解锁宝箱需要代币数
        repeated BlackFridayLottery lotteryReward = 9;//抽奖展示奖励
        optional int32 consume = 10;//每次抽奖消耗代币数

        repeated BlackFridayPoint points = 11;//价格对应代币数

        -- optional string totalPayAmount = 12;//累计付费
        optional string totalPurchase = 12;//累计付费
        repeated BlackFridayPool pools = 13;//奖池
    }

    message BlackFridayLottery {
        optional int64 coins = 1;//金币
        repeated ShopItem item = 2;//物品
        optional int32 special = 3;//是否是特殊奖励
    }

    message BlackFridayPool {
        optional int32 pool = 1;//奖池ID
        optional string amountRequired = 2;//解锁累计付费
        optional string coins = 3;//金币
    }
]]

function BFDrawData:parseData(_data)
    BFDrawData.super.parseData(self, _data)
    self.m_totalPoint = _data.totalPoint
    self.m_point = _data.point
    self.m_needPoint = _data.needPoint
    self.m_consume = _data.consume --每次抽奖消耗代币数
    self.m_lotteryReward = self:parseReward(_data.lotteryReward)

    self.p_totalPayAmount = _data.totalPurchase

    self.p_pools = self:parsePools(_data.pools)
end

function BFDrawData:parsePools(_dataPools)
    local list = {}
    for i,v in ipairs(_dataPools) do
        local tempData = {}
        tempData.pool = tonumber(v.pool)
        tempData.amountRequired = tonumber(v.amountRequired)
        tempData.coins = v.coins
        table.insert(list, tempData)
    end
    return list
end

function BFDrawData:parseReward(_data)
    local list = {}
    for i,v in ipairs(_data) do
        local tempData = {}
        tempData.coins = tonumber(v.coins)
        tempData.item = self:parseItemsData(v.item)
        tempData.special = v.special
        table.insert(list, tempData)
    end
    return list
end

-- 解析道具数据
function BFDrawData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function BFDrawData:getTotalPoint()
    return self.m_totalPoint or 0
end

function BFDrawData:getPoint()
    return self.m_point or 0
end

--每次抽奖消耗代币数
function BFDrawData:getDrawPoint()
    return self.m_consume or 0
end

function BFDrawData:getRewardList()
    return self.m_lotteryReward or {}
end

-- 是否能够抽奖（拥有代币数 >= 抽一次所需代币数）
function BFDrawData:isCanDraw()
    return self:getPoint() >= self:getDrawPoint()
end

function BFDrawData:getTotalPayAmount()
    if self.p_totalPayAmount == "" then
        return "0"
    end
    return self.p_totalPayAmount or "0"
end

function BFDrawData:getPools()
    return self.p_pools or {}
end


return BFDrawData
