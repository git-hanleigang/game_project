-- 大富翁 排行榜数据

local BaseActivityRankCfg = require("baseActivity.BaseActivityRankCfg")
local CardShowTopData = class("CardShowTopData", BaseActivityRankCfg)
local CardShowTopBriefData = require("GameModule.Card.CardRank.model.CardShowTopBriefData")

function CardShowTopData:ctor()
    self.p_rankUsers = {}
    self.p_rewards = {}
    self.p_myRank = nil
    self.p_prizePool = 0
end

-- message CardRank {
--     optional CardRankInfo info = 1; //简要信息
--     optional CardRankUser myRank = 2; //排名列表
--     repeated CardRankUser users = 3; //排名列表
--     repeated CardRankReward rewards = 4; //排名对应的奖励
-- }
function CardShowTopData:parseData(data)
    local rankUsers = data.users
    
    local p_rankUsers = {}
    if rankUsers ~= nil and #rankUsers > 0 then
        for k, v in ipairs(rankUsers) do
            local d = self:createRankUser(k, v)
            table.insert(p_rankUsers, d)
        end
        if #p_rankUsers > 1 then
            --从小到大排序
            table.sort(
                p_rankUsers,
                function(a, b)
                    if tonumber(a.p_rank) == tonumber(b.p_rank) then
                        return a.p_index < b.p_index
                    else
                        return tonumber(a.p_rank) < tonumber(b.p_rank)
                    end
                end
            )
        end
    end
    self.p_rankUsers = p_rankUsers


    if data:HasField("myRank") then
        release_print("_result.myRank 3 is " .. tostring(data.myRank.rank))
        self.p_myRank = self:createRankUser(nil, data.myRank)
    end

    local dataRewards = data.rewards
    if dataRewards ~= nil and #dataRewards > 0 then
        local p_rewards = {}
        self.p_rewards = p_rewards
        for k, v in ipairs(dataRewards) do
            local d = self:createReward(v)
            table.insert(p_rewards, d)
        end
        if #p_rewards > 1 then
            --从小到大排序
            table.sort(
                p_rewards,
                function(a, b)
                    return tonumber(a.p_rank) < tonumber(b.p_rank)
                end
            )
        end
    end

    self:parseBriefData(data.info)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = G_REF.CardRank})
end

-- message CardRankInfo {
--     optional int32 rank = 1; //排行榜排名
--     optional int32 rankUp = 2; //排行榜排名上升的幅度
--     optional int64 points = 3; //排行榜点数
--     optional int64 coins = 4; //奖励金币
-- }
function CardShowTopData:parseBriefData(data)
    if not self.brifeData then
        self.brifeData = CardShowTopBriefData.new()
    end
    self.brifeData:parseData(data)
    self.p_prizePool = data.coins
end

function CardShowTopData:getRankUp()
    if self.brifeData then
        return self.brifeData:getRankUp()
    end
end

function CardShowTopData:setRankUp(rankUp)
    if self.brifeData then
        return self.brifeData:setRankUp(rankUp)
    end
end

function CardShowTopData:getRankCfg()
    return self
end

function CardShowTopData:getRank()
    if self.brifeData then
        return self.brifeData:getRank()
    end
end

function CardShowTopData:getThemeName()
    return G_REF.CardRank
end

function CardShowTopData:getExpireAt()
    return CardSysManager:getSeasonExpireAt()
end

-- function CardShowTopData:getLeftTime()
--     local time = self:getExpireAt()
--     local curTime = os.time()
--     if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
--         curTime = globalData.userRunData.p_serverTime / 1000
--     end
--     local leftTime = time / 1000 - curTime
--     return leftTime
-- end

function CardShowTopData:hasData()
    return (self.brifeData ~= nil)
end

function CardShowTopData:getLeftTime()
    return self.brifeData:getLeftTime()
end

function CardShowTopData:isRunning()
    -- return CardSysManager:hasSeasonOpening()
    return true --(self.brifeData ~= nil)
end

function CardShowTopData:getMyRank()
    return self.brifeData:getRank()
end

return CardShowTopData
