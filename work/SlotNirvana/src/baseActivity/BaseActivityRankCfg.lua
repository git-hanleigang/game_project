--[[
    author:JohnnyFred
    time:2019-12-27 10:33:28
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityRankCfg = class("BaseActivityRankCfg")

function BaseActivityRankCfg:parseData(data)
    local rankUsers = data.rankUsers
    if rankUsers ~= nil and #rankUsers > 0 then
        local p_rankUsers = {}
        self.p_rankUsers = p_rankUsers
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
    release_print("_result.myRank 2 is " .. tostring(data.myRank))
    if data.myRank ~= nil then
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

    local dataSeason = data.seasons
    if dataSeason ~= nil and #dataSeason > 0 then
        local p_seasons = {}
        self.p_seasons = p_seasons
        for k, v in ipairs(dataSeason) do
            local d = self:createSeason(v)
            table.insert(p_seasons, d)
        end
        if #p_seasons > 1 then
            --从小到大排序
            table.sort(
                p_seasons,
                function(a, b)
                    return tonumber(a.p_rank) < tonumber(b.p_rank)
                end
            )
        end
    end

    self.p_prizePool = data.prizePool or 0
    if data.prizePoolV2 and data.prizePoolV2 ~= "" and data.prizePoolV2 ~= "0" then
        self.p_prizePool = toLongNumber(data.prizePoolV2)
    end
end

--RankUser
function BaseActivityRankCfg:createRankUser(index, data)
    local rankUser = {
        p_rank = data.rank,
        p_name = data.name,
        p_points = data.points,
        p_udid = data.udid,
        p_fbid = data.facebookId,
        p_head = data.head or 0,
        p_frameId = data.frame,
        p_coins = data.coins and tonumber(data.coins) or 0,
        p_robotHead = data.robotHead,
        p_items = {}
    }
    if data.coinsV2 and data.coinsV2 ~= "" and data.coinsV2 ~= "0" then
        rankUser.p_coins = toLongNumber(data.coinsV2)
    end
    if index ~= nil then
        rankUser.p_index = index
    end

    if data.udid == globalData.userRunData.userUdid then
        if not gLobalSendDataManager:getIsFbLogin() then
            -- 如果是我自己 并且 我没有登录facebook那么置空的facebookid (服务器不知道你退出了facebook)
            rankUser.p_fbid = ""
        end
        rankUser.p_head = globalData.userRunData.HeadName or 1
        rankUser.p_frameId = globalData.userRunData.avatarFrameId
    end
    if data.items then
        for k, v in ipairs(data.items) do
            local itemConfig = ShopItem:create()
            itemConfig:parseData(v, true)
            table.insert(rankUser.p_items, itemConfig)
        end
    end

    return rankUser
end

--Reward
function BaseActivityRankCfg:createReward(data)
    local reward = {
        p_rank = data.minRank,
        p_minRank = data.minRank,
        p_maxRank = data.maxRank,
        p_coins = tonumber(data.coins),
        p_items = nil
    }
    if data.coinsV2 and data.coinsV2 ~= "" and data.coinsV2 ~= "0" then
        reward.p_coins = toLongNumber(data.coinsV2)
    end

    local dataItems = data.items
    if dataItems ~= nil and #dataItems > 0 then
        local p_items = {}
        reward.p_items = p_items
        for k, v in ipairs(dataItems) do
            local itemConfig = ShopItem:create()
            itemConfig:parseData(v, true)
            table.insert(p_items, itemConfig)
        end
    end
    return reward
end

--Season
function BaseActivityRankCfg:createSeason(data)
    local season = {
        p_rank = data.rank,
        p_season = data.season
    }
    return season
end

--获取自己在所有排名中的序号
function BaseActivityRankCfg:getSelfRankIndex()
    if self.p_myRank ~= nil then
        return self:getRankIndex(self.p_myRank.p_udid)
    end
    return -1
end

--获取排名
function BaseActivityRankCfg:getRankIndex(udid)
    local p_rankUsers = self.p_rankUsers
    if p_rankUsers ~= nil then
        for k, v in ipairs(p_rankUsers) do
            if v.p_udid == udid then
                return k
            end
        end
    end
    return -1
end

--获取排行信息
function BaseActivityRankCfg:getRankConfig(index)
    if index == 2 then
        return self.p_rewards
    elseif index == 3 then
        return self.p_seasons
    end

    return self.p_rankUsers
end

--获取自己排行信息
function BaseActivityRankCfg:getMyRankConfig()
    return self.p_myRank
end

--获取奖池
function BaseActivityRankCfg:getPrizePool()
    return self.p_prizePool
end
return BaseActivityRankCfg
