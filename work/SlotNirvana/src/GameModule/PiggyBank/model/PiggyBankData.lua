--[[
    解析小猪银行数据
]]
local BaseGameModel = require("GameBase.BaseGameModel")
local PiggyBankData = class("PiggyBankData", BaseGameModel)

PiggyBankData.m_lastPrice = nil --存储的实际价值

function PiggyBankData:ctor()
    self:setRefName(G_REF.PiggyBank)
end

function PiggyBankData:parseData(data)
    self.p_price = data.price -- 购买的金币价格
    self.p_coins = tonumber(data.coins) -- 积攒的金币数量
    self.p_coinsMax = tonumber(data.coinsMax) -- 最大金币数量
    self.p_valuePrice = data.valuePrice -- 显示的金币价格
    self.p_productKey = data.productKey -- 小猪的商品ID
    self.p_vipPoint = tonumber(data.vipPoint) -- vip点数

    -- 小猪优惠券数据
    self.p_originalCoins = tonumber(data.originalCoins) -- 折扣后金币
    self.p_ticketDiscount = tonumber(data.ticketDiscount) -- 促销券折扣
    self.p_expireAt = tonumber(data.expireAt) -- 折扣过期时间

    -- 免费小猪的过期时间
    self.p_freeExpireAt = tonumber(data.freeExpireAt)

    -- 解析新手折扣数据
    self.p_noviceDiscountLevelMin = data.levelMin -- 最低等级
    self.p_noviceDiscountLevelMax = data.levelMax -- 最高等级
    self.p_noviceDiscount = data.discount -- 总折扣率
    self.p_noviceFirstDiscount = data.firstDiscount -- 小猪新手的折扣率
    self.p_hasNoviceDiscount = data.hasDiscount -- 是否在此折扣条件内

    self:checkShowPigTips()
    gLobalNoticManager:postNotification(ViewEventType.PIGGY_DATA_UPDATE)
end

function PiggyBankData:getFreeExpireAt()
    return self.p_freeExpireAt or 0
end

function PiggyBankData:getValuePrice()
    return self.p_valuePrice
end

-- 是否降档
function PiggyBankData:isLevelDown()
    if self.p_price < self.p_valuePrice then
        return true
    end
    return false
    -- return true
end

-- 是否是在新手折扣期间内
function PiggyBankData:checkInNoviceDiscount()
    return self.p_hasNoviceDiscount
end

-- 是否在新手折扣期间内弹出推送框
function PiggyBankData:checkShowNoviceDiscountPop()
    return self.p_hasNoviceDiscount and globalData.userRunData.levelNum == self.p_noviceDiscountLevelMin
end

-- 如果有其他促销折扣开启的话，这个是总折扣
function PiggyBankData:getNoviceDiscount()
    return self.p_noviceDiscount
end

-- 小猪新手的折扣
function PiggyBankData:getNoviceFirstDiscount()
    return self.p_noviceFirstDiscount
end

-- 小猪优惠券折扣
function PiggyBankData:getTicketDiscount()
    local curTime = tonumber(globalData.userRunData.p_serverTime)
    local endTime = self.p_expireAt
    if curTime >= endTime then
        return 0
    end
    return self.p_ticketDiscount or 0
end

function PiggyBankData:checkShowPigTips()
    --弹levelDash结算不弹提示板子
    local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
    if levelDashData and globalData.userRunData.levelNum == levelDashData.p_endLevel then
        return
    end

    if not self:isUnlockShowPig() then
        return
    end
    self:readPriceData()
    local diffPrice = globalData.constantData.PIG_SHOW_VALUE or 2
    local valuePrice = tonumber(self.p_valuePrice)
    local price = tonumber(self.p_price)
    --本次实际价格大于上次的实际价格 并且 实际价格和购买价格的差值大于配置发送通知
    if valuePrice > self.m_lastPrice and valuePrice - price >= diffPrice and valuePrice - self.m_lastPrice >= diffPrice then
        gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "pigPush")
        G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showTip("LevelUp")
    elseif self.m_pigLevelupSpinPush then
        gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "spinPush")
        G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showTip("LevelUp")
    end
    self.m_pigLevelupSpinPush = nil
end
--读取上次的实际价格
function PiggyBankData:readPriceData()
    if self.m_lastPrice == nil then
        self.m_lastPrice = gLobalDataManager:getNumberByField("pig_last_price", 0)
    end
end
--设置实际价格
function PiggyBankData:setPriceData(lastPrice)
    if lastPrice and lastPrice > self.m_lastPrice then
        self.m_lastPrice = lastPrice
        gLobalDataManager:setNumberByField("pig_last_price", self.m_lastPrice)
    end
end
--购买后重置价格
function PiggyBankData:clearData()
    self.m_lastPrice = 0
    self.m_spinCount = 0
    gLobalDataManager:setNumberByField("pig_last_price", self.m_lastPrice)
    gLobalDataManager:setNumberByField("pig_spin_count", self.m_spinCount)
end
--小猪曝光点解锁等级
function PiggyBankData:isUnlockShowPig()
    local unlockLevel = globalData.constantData.PIG_SHOW_LEVEL or 15
    local curLevel = globalData.userRunData.levelNum or 1
    if curLevel < unlockLevel then
        return false
    end
    return true
end

function PiggyBankData:updatePigLevelupPush()
    if not self:isUnlockShowPig() then
        return
    end
    self.m_pigLevelupSpinPush = nil
    if self.m_spinCount == nil then
        self.m_spinCount = gLobalDataManager:getNumberByField("pig_spin_count", 0)
    end
    self.m_spinCount = self.m_spinCount + 1
    local maxCount = globalData.constantData.PIG_SHOW_SPIN_TIMES or 1000
    if self.m_spinCount >= maxCount then
        self.m_spinCount = 0
        self.m_pigLevelupSpinPush = true
    end
    gLobalDataManager:setNumberByField("pig_spin_count", self.m_spinCount)
end

--spin次数
function PiggyBankData:updateSpinCount()
    self:updatePigLevelupPush()
    self:checkMaxCoinTip()
end

function PiggyBankData:setRewardCoin(_rewardCoin)
    self.m_rewardCoin = _rewardCoin
end

function PiggyBankData:getRewardCoin()
    return self.m_rewardCoin or 0
end

function PiggyBankData:isFree()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    -- 1655172961352
    -- 1655177572.9814
    local leftTime = self:getFreeExpireAt() / 1000 - curTime
    if leftTime > 0 then
        return true
    end
    return false
end

function PiggyBankData:isMax()
    if self.p_coinsMax and self.p_coinsMax <= self.p_coins then
        return true
    end
    return false
    -- return true
end

function PiggyBankData:isUnlock()
    if globalData.userRunData.levelNum < (globalData.constantData.OPENLEVEL_PIGBANK or 6) then
        return false
    end
    return true
    -- return false
end

------------------------------小猪储满提示框--------------------------------------------
function PiggyBankData:checkMaxCoinTip()
    if self:isMax() == true then
        local curTime = util_getCurrnetTime()
        local saveTime = self:getMaxCoinTipPopTime()
        if saveTime == 0 or curTime - saveTime >= ONE_DAY_TIME_STAMP then
            self:saveMaxCoinTipPopTime()
            G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showTip("Max")
        end
    end
end

function PiggyBankData:saveMaxCoinTipPopTime()
    local popTime = util_getCurrnetTime()
    local uid = globalData.userRunData.uid
    gLobalDataManager:setNumberByField("PIG_MAXTIP_POPTIME_" .. uid, tonumber(popTime))
end

function PiggyBankData:getMaxCoinTipPopTime()
    local uid = globalData.userRunData.uid
    return gLobalDataManager:getNumberByField("PIG_MAXTIP_POPTIME_" .. uid, 0)
end
------------------------------小猪储满提示框--------------------------------------------

return PiggyBankData
