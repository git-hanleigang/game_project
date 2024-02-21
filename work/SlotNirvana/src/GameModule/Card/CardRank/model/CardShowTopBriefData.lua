-- 大富翁 排行榜数据

local CardShowTopBriefData = class("CardShowTopBriefData")

-- message CardRankInfo {
--     optional int32 rank = 1; //排行榜排名
--     optional int32 rankUp = 2; //排行榜排名上升的幅度
--     optional int64 points = 3; //排行榜点数
--     optional int64 coins = 4; //奖励金币
--     optional int64 expireAt = 5; //过期时间
-- }
function CardShowTopBriefData:parseData(data)
    self.rank = data.rank
    self.rankUp = data.rankUp
    self.points = tonumber(data.points) or 0
    self.coins = tonumber(data.coins) or 0
    self.p_expireAt = data.expireAt
end

function CardShowTopBriefData:getRankUp()
    return self.rankUp
end

function CardShowTopBriefData:setRankUp(rankUp)
    self.rankUp = rankUp
end

function CardShowTopBriefData:getRank()
    return self.rank
end

function CardShowTopBriefData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function CardShowTopBriefData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

return CardShowTopBriefData
