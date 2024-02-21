--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-17 12:09:52
--
local TopUpBonusCoinIncreaseData = class("TopUpBonusCoinIncreaseData")
local endTime = 5 * 60

function TopUpBonusCoinIncreaseData:ctor()
end

function TopUpBonusCoinIncreaseData:getCurTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return curTime
end

function TopUpBonusCoinIncreaseData:setMinCoins(currentCoin, minCoins, refreshTime)
    self.initValue = currentCoin
    self.curValue = self.initValue

    self.minCoins = LongNumber.min(minCoins, currentCoin)
    self.refreshTime = refreshTime

    self.initTime = self:getCurTime() --滚动数值的最大值
    if toLongNumber(currentCoin) <= toLongNumber(minCoins) then
        self.addPer = 0
    else
        self.addPer = (currentCoin - self.minCoins) / (self.refreshTime - self.initTime) --滚动数值每秒增长的量
    end
end

function TopUpBonusCoinIncreaseData:updateIncrese()
    if self:getCurTime() >= self.refreshTime then
        self.curValue = self.minCoins
        return true
    end

    local dis_t = self.refreshTime - self:getCurTime()
    local addValue = dis_t * self.addPer
    self.curValue = self.minCoins + addValue
end

function TopUpBonusCoinIncreaseData:getRuningGold()
    return self.curValue
end

return TopUpBonusCoinIncreaseData
