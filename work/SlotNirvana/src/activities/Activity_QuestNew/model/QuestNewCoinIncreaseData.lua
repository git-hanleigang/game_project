--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-17 12:09:52
--
local QuestNewCoinIncreaseData = class("QuestNewCoinIncreaseData")
local endTime = 5 * 60

function QuestNewCoinIncreaseData:ctor()
end

function QuestNewCoinIncreaseData:getCurTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return curTime
end

function QuestNewCoinIncreaseData:setMaxCoins(oldCoin,maxCoins,minCoins)
    
    self.initValue = oldCoin and oldCoin or maxCoins*0.8 --初始值
    if self.initValue < minCoins then
        self.initValue = minCoins
    end
    self.maxValue = maxCoins --最大值

    self.curValue = self.initValue
    self.initTime = self:getCurTime() --滚动数值的最大值

    self.addPer = (self.maxValue -  self.initValue) /endTime --滚动数值每秒增长的量
end

function QuestNewCoinIncreaseData:updateIncrese()
    local dis_t = self:getCurTime() - self.initTime
    local addValue = dis_t * self.addPer
    if self.m_showName then
        self.showNameTime = self.showNameTime - 0.1
        if self.showNameTime <= 0 then
            self.m_showName = false
        end
    end
    if dis_t >= endTime - 1 then
        return true
    end
    self.curValue = self.initValue + addValue
    
    if self.curValue >= self.maxValue then
        return true
    end
end

function QuestNewCoinIncreaseData:setGainName(name)
    self.gainName = name
    self.showNameTime = 3
    self.m_showName = true
end

-- 第二个返回值 是否是展示名字
function QuestNewCoinIncreaseData:getRuningGold()
    if self.m_showName then
        return self.gainName,true
    end
    return self.curValue, false
end

return QuestNewCoinIncreaseData
