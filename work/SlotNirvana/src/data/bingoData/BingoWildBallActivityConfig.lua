--[[
    author:JohnnyFred
    time:2020-06-23 14:32:26
]]
local BingoWildBallActivityConfig = class("BingoWildBallActivityConfig")

function BingoWildBallActivityConfig:parseData(data)
    self.activityId = data.activityId
    self.expire = data.expire
    self.expireAt = data.expireAt
    self.extra = data.extra
end

function BingoWildBallActivityConfig:getActivityID()
    return self.activityId
end

function BingoWildBallActivityConfig:getExpire()
    return self.expire
end

function BingoWildBallActivityConfig:getExpireAt()
    return self.expireAt / 1000
end

function BingoWildBallActivityConfig:getExtra()
    return self.extra
end

function BingoWildBallActivityConfig:isRunning()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime > 0
end
return  BingoWildBallActivityConfig