--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-17 12:09:52
--
local CashBonusIncreaseData = class("CashBonusIncreaseData")

function CashBonusIncreaseData:ctor()
end

function CashBonusIncreaseData:parseWheelData(type, data)
    self.baseValue = data.p_coinsShowBase --名字
    self.maxValue = data.p_coinsShowMax --冷却时间

    self:calInitValue(globalData.constantData.ROULETTE_RANDOMS)

    self.addPer = data.p_coinsShowPerSecond --滚动数值每秒增长的量
    self.type = type
end

function CashBonusIncreaseData:calInitValue(rateNum)
    local randomMax = rateNum * self.baseValue
    local addNum = math.random(self.baseValue, randomMax)
    self.initValue = addNum --初始值
    self.curValue = self.initValue
    self.initTime = self:getCurTime() --滚动数值的最大值
end

function CashBonusIncreaseData:getCurTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return curTime
end

function CashBonusIncreaseData:parseBoxData(data)
    local rate
    self.type = data.type
    if self.type == CASHBONUS_TYPE.BONUS_GOLD then
        rate = globalData.constantData.CASHVAULT_GOLDBOX_RANDOMS
    elseif self.type == CASHBONUS_TYPE.BONUS_SILVER then
        rate = globalData.constantData.CASHVAULT_SILVERBOX_RANDOMS
    end
    self.baseValue = tonumber(data.maxCoins) --基础值
    self.maxValue = tonumber(data.coinsShowMax) --最大值

    self:calInitValue(rate)

    self.addPer = data.coinsShowPerSecond --滚动数值每秒增长的量
end
function CashBonusIncreaseData:updateIncrese()
    local curTime = self:getCurTime()
    local addValue = (curTime - self.initTime) * self.addPer
    self.curValue = self.initValue + addValue
    local rate
    if self.type == CASHBONUS_TYPE.BONUS_WHEEL then
        rate = globalData.constantData.ROULETTE_RANDOMS
    elseif self.type == CASHBONUS_TYPE.BONUS_GOLD then
        rate = globalData.constantData.CASHVAULT_GOLDBOX_RANDOMS
    elseif self.type == CASHBONUS_TYPE.BONUS_SILVER then
        rate = globalData.constantData.CASHVAULT_SILVERBOX_RANDOMS
    end

    local maxValueTemp = self.maxValue
    local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    if wheelData then
        self.curValue = wheelData.p_vipMultiple * self.curValue
        maxValueTemp = maxValueTemp * wheelData.p_vipMultiple
    end
    if self.curValue >= maxValueTemp then
        self:calInitValue(rate)
    end
end

return CashBonusIncreaseData
