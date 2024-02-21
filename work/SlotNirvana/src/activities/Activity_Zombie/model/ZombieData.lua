--行尸走肉主数据部分
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopItem = require "data.baseDatas.ShopItem"
local ZombieData = class("ZombieData", BaseActivityData)

-- message ZombieOnslaught {
--   optional string activityId = 1;
--   optional string name = 2;
--   optional string begin = 3;
--   optional int64 expireAt = 4;
--   optional int32 expire = 5;
--   optional int32 arms = 6; //武器数量
--   optional int32 energy = 7; //当前能量
--   optional int32 maxEnergy = 8; //最大能量
--   optional string priceKey = 9; //回收价格key
--   optional string price = 10; //回收价格
--   optional string priceValue = 11; //回收价格支付value
--   optional int64 armsCoins = 12; //武器回收金币
--   optional int64 activeTime = 13; //激活时间戳
--   optional int64 coins = 14; //奖励总金币
--   repeated int64 coinLosts = 15; // 金币损失
--   repeated ZombieOnslaughtRewardData rewards = 16; //道具奖励
--   repeated int64 attackTimes = 17; //攻击时间戳
--   repeated int32 needArms = 18; //所需要的武器
--   repeated bool defendResults = 19; //防御结果
--   optional ZombieOnslaughtSale sale = 20; //促销数据
--  optional ZombieOnslaughtSupplyBox supplyBox = 21;//补给箱
--  optional ZombieOnslaughtRedeemSale redeemSale = 22;//挽回促销
--  optional ZombieOnslaughtTimePause timePause = 23;//时间暂停
--  optional ZombieOnslaughtDefendResult defendResultsV2 = 24;//防御结果
--  optional string recycleCoins = 25;//武器回收金币
-- }

function ZombieData:ctor()
    ZombieData.super.ctor(self)
end

function ZombieData:parseData(data)
    ZombieData.super.parseData(self, data)
    self.m_coins = data.coins
    if data.rewards and #data.rewards > 0 then
        self:parseReward(data.rewards)
    end
    if data.defendResults then
        self.m_result = data.defendResultsV2
        self:parseResults(self.m_result)
    end
    self.m_actime = data.activeTime
    self.m_coinLosts = data.coinLosts
    self.m_attackTimes = data.attackTimes
    self.m_energy = data.energy
    self.m_maxEnergy = data.maxEnergy
    self.m_arms = data.arms
    self.m_needArms = data.needArms
    if data.price and data.price ~= "0" and data.price ~= 0 then
        self.m_price = data.price
        if self.m_price == "" then
            self.m_price = nil
        end
        self.m_priceKey = data.priceKey
        self.m_priceValue = data.priceValue
    end
    self.m_armsCoins = data.armsCoins
    if data.sale then
        self:parseZombieSale(data.sale)
    end
    if data.supplyBox then
        self:parseZombieSupplyBox(data.supplyBox)
    end
    if data.timePause then
        self:parseZombiePause(data.timePause)
    end
    if data.redeemSale then
        self:parseZombieRedeem(data.redeemSale)
    end
    self.m_recycleCoins = data.recycleCoins
    if not self.m_actime or self.m_actime == "0" then
        G_GetMgr(ACTIVITY_REF.Zombie):saveOnlinStatus(0)
    end
    G_GetMgr(ACTIVITY_REF.Zombie):updateComing()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Zombie})
end

function ZombieData:getActiveTimes()
    return self.m_actime or "0"
end

function ZombieData:getAttackTimes()
    return self.m_attackTimes or {}
end

function ZombieData:getEnergy()
    return self.m_energy or 0
end

function ZombieData:getMaxEnergy()
    return self.m_maxEnergy or 10000
end

function ZombieData:getArms()
    return self.m_arms or 0
end

function ZombieData:getMaxArms()
    return 10000
end

function ZombieData:getNeedArms()
    return self.m_needArms or {}
end

function ZombieData:getPrice()
    return self.m_price
end

function ZombieData:getArmsCoins()
    return self.m_recycleCoins or 0
end

function ZombieData:parseZombieSupplyBox(_data)
    self.m_armBox = {} --武器促销
    self.m_coverBox = {} --保护罩促销
    if _data.armsSaleList and #_data.armsSaleList > 0 then
        for i,v in ipairs(_data.armsSaleList) do
            local a = {}
            a.p_index = v.index
            a.p_arms = v.arms
            a.p_discount = v.discount
            a.p_key = v.key
            a.p_keyId = v.keyId
            a.p_price = v.price
            a.p_coins = v.coins
            table.insert(self.m_armBox,a)
        end
    end
    if _data.protectiveCoverSale then
        self.m_coverBox.p_key = _data.protectiveCoverSale.key
        self.m_coverBox.p_keyId = _data.protectiveCoverSale.keyId
        self.m_coverBox.p_price = _data.protectiveCoverSale.price
        self.m_coverBox.p_coins = _data.protectiveCoverSale.coins
    end
    self.m_Curams = _data.defaultArmsSaleIndex
    self.m_CurCover = _data.hasProtectiveCoverNum
end
--时间暂停数据
function ZombieData:parseZombiePause(_data)
    self.m_timePause = {}
    self.m_timePause.pauseMaxExpireAt = _data.pauseMaxExpireAt --最大暂停时间
    self.m_timePause.pauseExpireAt = tonumber(_data.pauseExpireAt) --暂停结束
    local times = {}
    if _data.timePauseSaleList and #_data.timePauseSaleList > 0 then
        for i,v in ipairs(_data.timePauseSaleList) do
            local a = {}
            a.p_index = v.index
            a.p_gems = v.gems
            a.p_timeMinute = v.timeMinute
            table.insert(times,a)
        end
        self.m_timePause.times = times
    end
end

--挽回促销
function ZombieData:parseZombieRedeem(_data)
    self.m_saleRedeem = {}
    self.m_saleRedeem.p_key = _data.key
    self.m_saleRedeem.p_keyId = _data.keyId
    self.m_saleRedeem.p_price = _data.price
end

function ZombieData:getRedeemSale()
    return self.m_saleRedeem or {}
end

function ZombieData:getPauseExTime()
    local bendi = globalData.userRunData.p_serverTime
    if tonumber(bendi) > tonumber(self.m_timePause.pauseExpireAt) then
        return 0
    end
    return self.m_timePause.pauseExpireAt or 0
end

function ZombieData:parseReward(_data)
    self.m_reward = {}
    for i,v in ipairs(_data) do
        local item = {}
        if v.items then
            for k=1,#v.items do
                local tempData = ShopItem:create()
                tempData:parseData(v.items[k])
                table.insert(item,tempData)
            end
        end
        table.insert(self.m_reward,item)
    end
end

function ZombieData:parseResults(_data)
    self.m_succNums = 0 
    for i,v in ipairs(_data) do
        if v.success == false then
            self.m_succNums = self.m_succNums + 1
        end
    end
end

function ZombieData:parseZombieSale(_data)
    self.m_saleResult = {}
    self.m_buffTime = 0
    if _data.gem then
        self.m_saleResult.gem = _data.gem
        local itemList = {}
        if _data.items and #_data.items > 0 then
            for i,v in ipairs(_data.items) do
                local tempData = ShopItem:create()
                tempData:parseData(v)
                if tempData.p_buffInfo and tempData.p_buffInfo.buffDuration then
                    self.m_buffTime = tempData.p_buffInfo.buffDuration
                end
                table.insert(itemList,tempData)
            end
        end
        dump(itemList)
        self.m_saleResult.items = itemList
        self.m_saleResult.freeTimes = _data.freeTimes
    end
end

function ZombieData:getBuffTime()
    return self.m_buffTime or 0
end

function ZombieData:getSileData()
    return self.m_saleResult or {}
end
--抵御成功的次数
function ZombieData:getFileNums()
    return self.m_succNums or 0
end

function ZombieData:getDefendResult()
    return self.m_result or {}
end

function ZombieData:getCurrentReward()
    local nums = self:getFileNums()
    local reward = self.m_reward[nums + 1]
    return reward
end

function ZombieData:getLoseReward()
    local nums = self:getFileNums()
    local reward = self.m_reward[nums]
    return reward
end

function ZombieData:getLoseCoins()
    local nums = self:getFileNums()
    return self.m_coinLosts[nums]
end

function ZombieData:getCurrentCoins()
    local nums = self:getFileNums()
    local lost = 0
    if self.m_coinLosts and #self.m_coinLosts > 0 and nums ~= 0 then
        for i=1,nums do
            lost = lost + self.m_coinLosts[i]
        end
    end
    local coins = self.m_coins - lost
    return coins
end

function ZombieData:getArmsSale()
    return self.m_armBox or {}
end

function ZombieData:getCoverSale()
    return self.m_coverBox or {}
end

function ZombieData:getCurrentArms()
    return self.m_Curams or 1
end

function ZombieData:getCurrentCover()
    return self.m_CurCover or 0
end

function ZombieData:setCurrentCover()
    self.m_CurCover = 0
end

function ZombieData:getPauseTime()
    return self.m_timePause or {}
end

function ZombieData:checkIsActve()
    if self:getActiveTimes() == "0" then
        return false
    else
        return true
    end
end

--获取入口位置 1：左边，0：右边
function ZombieData:getPositionBar()
    return self:checkIsActve() and 1
end

return ZombieData
