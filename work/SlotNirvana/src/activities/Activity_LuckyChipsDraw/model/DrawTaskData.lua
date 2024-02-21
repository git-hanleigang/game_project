--赠送抽奖次数任务 ios fix
local DrawTaskData = class("DrawTaskData")
DrawTaskData.p_expire = nil             --剩余秒数
DrawTaskData.p_expireAt = nil           --过期时间
DrawTaskData.m_max = nil                --任务目标
DrawTaskData.m_collectCoins = nil       --任务进度
DrawTaskData.m_collected = nil          --是否领取
function DrawTaskData:parseData(data)
    self.p_expire = tonumber(data.expire)
    self.p_expireAt = tonumber(data.expireAt)
    self.m_max = tonumber(data.max)
    self.m_collectCoins = tonumber(data.collectCoins)
    self.m_collected = data.collected
    self.m_tickNum = data.num or 0
end
function DrawTaskData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end
function DrawTaskData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end
--是否可以领取任务
function DrawTaskData:canCollectTask()
    if not self.m_collected and self.m_collectCoins >= self.m_max and self.p_expire>0 then
        return true
    end
    return false
end
return DrawTaskData