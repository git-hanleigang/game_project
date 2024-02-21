--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-17 12:09:52
--
local QuestJackpotCoinIncreaseData = class("QuestJackpotCoinIncreaseData")
local endTime = 5 * 60

function QuestJackpotCoinIncreaseData:ctor()
end

function QuestJackpotCoinIncreaseData:getCurTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return curTime
end

function QuestJackpotCoinIncreaseData:setMaxCoins(maxCoins)
    local oldCoin = self.initValue or 0
    self.initValue = maxCoins*0.8 --初始值
    if self.initValue < oldCoin then
        self.initValue = oldCoin
    end
    self.maxValue = maxCoins --最大值

    self.curValue = self.initValue
    self.initTime = self:getCurTime() --滚动数值的最大值

    self.addPer = (self.maxValue -  self.initValue) /endTime --滚动数值每秒增长的量
end

function QuestJackpotCoinIncreaseData:updateIncrese()
    local dis_t = self:getCurTime() - self.initTime
    local addValue = dis_t * self.addPer
    if dis_t >= endTime - 1 then
        return true
    end
    self.curValue = self.initValue + addValue
    
    if self.curValue >= self.maxValue then
        return true
    end
end

-- 第二个返回值 是否是展示名字
function QuestJackpotCoinIncreaseData:getRuningGold()
    return self.curValue
end

return QuestJackpotCoinIncreaseData
