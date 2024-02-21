--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-07 18:06:52
]]

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
    }

    message BlackFridayPoint {
        optional string price = 1;//价格
        optional int32 point = 2;//对应代币数
    }

    message BlackFridayLottery {
        optional int64 coins = 1;//金币
        repeated ShopItem item = 2;//物品
        optional int32 special = 3;//是否是特殊奖励
    }
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local GrandPrizeData = class("GrandPrizeData", BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

function GrandPrizeData:ctor()
    GrandPrizeData.super.ctor(self)
end

function GrandPrizeData:parseData(_data)
    GrandPrizeData.super.parseData(self, _data)
    self.m_totalPoint = _data.totalPoint
    self.m_point = _data.point
    self.m_needPoint = _data.needPoint
    self.m_pointList = self:parsePointList(_data.points)
end

-- 解析对应档位可获得的点数
function GrandPrizeData:parsePointList(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.price = v.price
            tempData.point = v.point
            table.insert(list, tempData)
        end
    end
    return list
end

-- 解析道具数据
function GrandPrizeData:parseItemsData(_data)
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

function GrandPrizeData:getTotalPoint()
    return self.m_totalPoint or 0
end

function GrandPrizeData:getPoint()
    return self.m_point or 0
end

function GrandPrizeData:getNeedPoint()
    return self.m_needPoint or 0
end

-- 是否达到条件参与活动（拥有代币 >= 所需代币）
function GrandPrizeData:isJoin()
    return self:getTotalPoint() >= self:getNeedPoint()
end

-- 获得付费档位所对应的点数
function GrandPrizeData:getPointByPrice(_price)
    local point = 0
    for i = 1, #self.m_pointList do
        if _price and _price == self.m_pointList[i].price then
            point = self.m_pointList[i].point
        end
    end
    return point
end

return GrandPrizeData
