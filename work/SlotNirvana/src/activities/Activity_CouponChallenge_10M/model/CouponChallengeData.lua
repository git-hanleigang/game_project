--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-04-14 14:46:27
    describe:10M每日任务送优惠券数据模块
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CouponChallengeData = class("CouponChallengeData", BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

--[[message SmashHammerConfig {
    optional string activityId = 1; //活动id
    optional int64 expireAt = 2; //活动截止时间
    optional int32 expire = 3; //活动剩余时间
    optional int32 resetHour = 4; //积分商城道具重置时间
    optional int32 popupsNum = 5; //弹窗次数
    optional int32 totalPoints = 6; //总积分点数
    repeated PointsShop pointsShop = 7; //积分商城信息
  }
  
  message PointsShop {
    optional int32 id = 1; //道具主键id
    optional ShopItem shopItem = 2; //物品信息
    optional int32 points = 3; //兑换需要点数
    optional int32 num = 4; //可兑换数量
    optional int32 remainingNum = 5; //剩余数量
    optional string rewardType = 6; //类型
    optional int64 coins = 7; //金币数量
  }
]]
function CouponChallengeData:parseData(_data)
    CouponChallengeData.super.parseData(self, _data)

    self.p_resetHour = tonumber(_data.resetHour)
    self.p_popupsNum = tonumber(_data.popupsNum)
    self.p_totalPoints = tonumber(_data.totalPoints)
    self.p_pointsShop = self:parsePointsShopData(_data.pointsShop)
end

-- 解析积分商城数据
function CouponChallengeData:parsePointsShopData(_data)
    local shopData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.id = v.id
            tempData.shopItem = self:parseItemsData(v.shopItem)
            tempData.points = tonumber(v.points)
            tempData.num = tonumber(v.num)
            tempData.remainingNum = tonumber(v.remainingNum)
            tempData.rewardType = v.rewardType
            tempData.coins = tonumber(v.coins)
            table.insert(shopData, tempData)
        end
    end
    return shopData
end

-- 解析道具数据
function CouponChallengeData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function CouponChallengeData:setLastPopupsNum()
    self.p_lastPopupsNum = self.p_popupsNum
end

function CouponChallengeData:getShopData()
    return self.p_pointsShop
end

function CouponChallengeData:getShopDataByIndex(index)
    return self.p_pointsShop[index] or nil
end

function CouponChallengeData:getTotalPoints()
    return self.p_totalPoints or 0
end

function CouponChallengeData:getResetHour()
    return self.p_resetHour or 0
end

function CouponChallengeData:getPopupsNum()
    return self.p_popupsNum or 0
end

function CouponChallengeData:getLastPopupsNum()
    return self.p_lastPopupsNum or self:getPopupsNum()
end

function CouponChallengeData:getItemIdByIndex(index)
    local shopData = self:getShopDataByIndex(index)
    if shopData then
        return shopData.id
    end
    return nil
end

function CouponChallengeData:isRemainingNum(index)
    local shopData = self:getShopDataByIndex(index)
    if shopData then
        return shopData.remainingNum > 0
    end
    return false
end

function CouponChallengeData:isPopupsNum()
    return self:getPopupsNum() > 0
end

return CouponChallengeData
