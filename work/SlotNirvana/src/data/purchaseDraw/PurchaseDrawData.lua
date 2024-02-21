--[[
Author: cxc
Date: 2021-04-30 12:09:35
LastEditTime: 2021-05-27 11:38:18
LastEditors: Please set LastEditors
Description: HAT TRICK DELUXE 活动 购买充值触发的活动 数据
FilePath: /SlotNirvana/src/data/purchaseDraw/PurchaseDrawData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local PurchaseDrawData = class("PurchaseDrawData",BaseActivityData)
local PurchaseDrawRewardData = require("data.purchaseDraw.PurchaseDrawRewardData")

function PurchaseDrawData:ctor()
    PurchaseDrawData.super.ctor(self)

    self.m_bInit = false

    self.m_normalRewardList = {}
    self.m_gearRewardList = {}
    self.m_allNormalShopItemList = {}

    self.m_maxProg = 1
    self.m_curProcess = 0
    self.m_curActMaxLightning = 0

    self.m_leftDrawTimes = 0
    self.m_lastCollectedIdx = 0
end

function PurchaseDrawData:parseData(_data)
    PurchaseDrawData.super.parseData(self,_data)

    -- message HatTrickConfig {
    --     optional string name = 1;
    --     optional int64 expireAt = 2;
    --     optional int32 expire = 3;
    --     optional string activityId = 4;
    --     repeated HatTrickAwards awards = 5; // 12个道具
    --     repeated HatTrickAwards processAwards = 6; // 进度奖励
    --     optional int32 process = 7; // 当前进度  注意：抽一次，最多涨一点
    --     optional int32 leftDrawTimes = 8; // 剩余抽奖次数
    --     optional int32 collected = 9; // 最近一次领取奖励索引
    --     optional int32 maxLightning = 10; //最大闪电数量
    --   }
      
    if not self.m_bInit then
        self.m_name = _data.name
        self.m_expireAt = _data.expireAt
        self.m_expire = _data.expire
        self.m_activityId = _data.activityId
        self.m_normalRewardList = self:parseRewardData(_data.awards) --12个道具
        self.m_gearRewardList = self:parseRewardData( _data.processAwards, true) -- 进度奖励
        
        self.m_curActMaxLightning = _data.maxLightning or 0
    end
  
    self.m_lastCollectedIdx = _data.collected or 0 --最近一次的领取奖励索引
    self.m_curProcess = _data.process or 0 --当前进度
    self.m_leftDrawTimes = _data.leftDrawTimes or 0 --剩余抽奖次数 

    self.m_bInit = true
end

function PurchaseDrawData:parseRewardData(_rewardList, _bBig)
    local list = {}
    for i, data in ipairs(_rewardList) do
        if not _bBig then
            data.pos = i
        else
            self.m_maxProg = data.pos
        end
    
        local rewardData = PurchaseDrawRewardData:create()
        rewardData:parseData(data)

        table.insert(list, rewardData)
    end
    
    if _bBig and self.m_maxProg <= 0 then
        self.m_maxProg = 10
    end

    return list
end

-- 获取普通奖励
function PurchaseDrawData:getNormalRewardList()
    return self.m_normalRewardList
end
-- 获取进度条奖励
function PurchaseDrawData:getGearRewardList()
    return self.m_gearRewardList
end

-- 是否是 高倍模式
function PurchaseDrawData:checkIsDeluxeModule()
    -- return self.m_curActMaxLightning > 0
    return #self.m_gearRewardList > 0
end

-- 获取可领奖的次数
function PurchaseDrawData:getActDrawLeftCount()
    return self.m_leftDrawTimes
end
 
-- 是否 被激活
function PurchaseDrawData:checkIsActive()
    return self.m_leftDrawTimes > 0
end

-- 进度条进度
function PurchaseDrawData:getCurProgress()
    return self.m_curProcess / self.m_maxProg
end
function PurchaseDrawData:getCurProgGear()
    return self.m_curProcess
end
function PurchaseDrawData:getMaxProGear()
    return self.m_maxProg
end

-- 获取 高配模式 活动配置的闪电数量
function PurchaseDrawData:getActMaxLightning()
    return self.m_curActMaxLightning
end

-- 上次领取的 普通奖励idx 服务器从0开始的
function PurchaseDrawData:getLastCollectIdx()
    return (self.m_lastCollectedIdx + 1)
end

-- 获取所有普通的 道具奖励
function PurchaseDrawData:getAllNormalShopItemList()
    if next(self.m_allNormalShopItemList) then
        return self.m_allNormalShopItemList
    end

    for i, rewardData in ipairs(self.m_normalRewardList) do
        local itemList = rewardData:getItemList()
            for k, shopItemData in pairs(itemList) do
                table.insert(self.m_allNormalShopItemList, shopItemData)
            end
    end

    return self.m_allNormalShopItemList
end

function PurchaseDrawData:isCollectBigReward()
    return self.m_curProcess >= self.m_maxProg
end

return PurchaseDrawData
