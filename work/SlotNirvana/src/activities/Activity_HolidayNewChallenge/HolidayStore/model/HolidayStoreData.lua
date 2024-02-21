--[[
    圣诞聚合 -- 商店
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local HolidayStoreData = class("HolidayStoreData", BaseActivityData)
local HolidayGoodsData = util_require("activities.Activity_HolidayNewChallenge.HolidayStore.model.HolidayGoodsData")
local HolidaySaleData = util_require("activities.Activity_HolidayNewChallenge.HolidayStore.model.HolidaySaleData")


-- message HolidayNewChallengeStore {
--     optional string activityId = 1; // 活动的id
--     optional string activityName = 2;// 活动的名称
--     optional string begin = 3;// 活动的开启时间
--     optional int64 expireAt = 4; // 活动倒计时
--     optional int64 curPoints = 5; // 当前点数 跟主活动当中一样的点数
--     repeated HolidayNewChallengeGoods goods = 6; // 商品的信息
--     repeated HolidayNewChallengePromotion promotions = 7;//促销数据
--   }
function HolidayStoreData:ctor()
    HolidayStoreData.super.ctor(self)
    self.isRefresh = true
end

function HolidayStoreData:parseData(_data)
    HolidayStoreData.super.parseData(self, _data)
    self.p_curPoints = _data.curPoints -- 当前道具数

    self.p_goodsList = self:parseGoodsList(_data.goods)

    if _data.promotions ~=  nil then
        self.p_promotionData = self:parsePromotionList(_data.promotions)
    end

    if self.isRefresh then
        self.p_goldenGoods = self:getGoldenGoods()
        self.isRefresh = false
    end
end

function HolidayStoreData:getCurPoints()
    return tonumber(self.p_curPoints)
end

function HolidayStoreData:getGoodsList()
    return self.p_goodsList
end

function HolidayStoreData:getGoodsByIndex(seq)
    for i = 1 ,#self.p_goodsList do
        if self.p_goodsList[i]:getSeq() == seq then
            return self.p_goodsList[i]
        end
    end
    return nil
end

function HolidayStoreData:parseGoodsList(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local rewardData = HolidayGoodsData:create()
            rewardData:parseData(v)
            table.insert(list, rewardData)
        end
    end
    return list
end

function HolidayStoreData:parsePromotionList(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local rewardData = HolidaySaleData:create()
            rewardData:parseData(v)
            table.insert(list, rewardData)
        end
    end
    return list
end

-- 检测是否显示红点（拥有点数 > 商店物品最小价格）
function HolidayStoreData:checkIsRedPoint()
    local data = G_GetMgr(ACTIVITY_REF.HolidayNewChallenge):getRunningData()
    local propNum = tonumber(data:getCurPoints())
    local min = self:getStoreMinPrice()
    if min >= 0 and propNum >= min then
        return true
    end
    return false
end

-- 商店物品最小价格 (可购买的)
function HolidayStoreData:getStoreMinPrice()
    local min = -1
    if self.p_goodsList and #self.p_goodsList > 0 then
        for i = 1, #(self.p_goodsList) do
            local color = self.p_goodsList[i]:getColor()
            if not (color == "GOLDEN" and not self:checkUnLockPass()) then
                local cash = self.p_goodsList[i]:getCash()
                local isSellOut = self.p_goodsList[i]:isSellOut()
                if not isSellOut then
                    if min == -1  or min > cash then
                        min = cash
                    end
                end
            end
        end
    end
    return min
end

function HolidayStoreData:checkUnLockPass()
    local mgr = G_GetMgr(ACTIVITY_REF.HolidayPass)
    if mgr then
        local data = mgr:getRunningData()
        if data then
            return true
        end
    end
    return false
end

--是否存在刚刚解锁的商品
function HolidayStoreData:isExist()
    local time = 0 -- 次数
    if self.p_goodsList and #self.p_goodsList > 0 then
        for i, v in ipairs(self.p_goodsList) do
            local color = v:getColor()
            if color == "GOLDEN" then
                local task = v:getGoldGoodsTask()
                local old = self:getOldGoldenGoodsBySeq(v:getSeq())
                if old then
                    local oldTask = old:getGoldGoodsTask()
                    if not oldTask:isUnlocked() and task:isUnlocked() then
                        task:setComplete(true)
                        time = time + 1
                    end
                end 
            end
        end
    end
    if time > 0 then
        return true
    else
        return false
    end
end



function HolidayStoreData:getGoldenGoods()
    local list = {}
    if self.p_goodsList and #self.p_goodsList > 0 then
        for i, v in ipairs(self.p_goodsList) do
            local color = v:getColor()
            if color == "GOLDEN" then
                table.insert(list, clone(v))
            end
        end
    end
    return list
end

function HolidayStoreData:getOldGoldenGoodsBySeq(_seq)
    for i, v in ipairs(self.p_goldenGoods) do
        local seq = v:getSeq()
        if seq == _seq then
            return v
        end
    end
    return nil
end

function HolidayStoreData:updateOldGoldenGoods()
    self.p_goldenGoods = self:getGoldenGoods()
end

function HolidayStoreData:getSale()
    return self.p_promotionData
end

return HolidayStoreData
