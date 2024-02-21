--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local ShopItem = require "data.baseDatas.ShopItem"
local QuestNewRankData = class("QuestNewRankData")
QuestNewRankData.p_rankUsers = nil
QuestNewRankData.p_myRank = nil
QuestNewRankData.p_rewards = nil
QuestNewRankData.p_seasons = nil
QuestNewRankData.p_prizePool = nil --金币池

function QuestNewRankData:ctor()
    self.p_rankUsers = {}
    self.p_rewards = {}
    self.p_seasons = {}
end

function QuestNewRankData:parseData(data)
    if not data then
        return
    end

    if data.rankUsers ~= nil and #data.rankUsers > 0 then
        self.p_rankUsers = {}
        for i = 1, #data.rankUsers do
            local d = self:createRankUser(data.rankUsers[i])
            if d and d.p_points and d.p_points > 0 then
                self.p_rankUsers[#self.p_rankUsers + 1] = d
                if #self.p_rankUsers >= 50 then
                    break
                end
            end
        end
    end

    if data.myRank ~= nil then
        self.p_myRank = self:createRankUser(data.myRank)
    end

    if data.rewards ~= nil and #data.rewards > 0 then
        self.p_rewards = {}
        for i = 1, #data.rewards do
            local d = self:createReward(data.rewards[i])
            self.p_rewards[#self.p_rewards + 1] = d
        end
    end

    if data.seasons ~= nil and #data.seasons > 0 then
        self.p_seasons = {}
        for i = 1, #data.seasons do
            local d = self:createSeason(data.seasons[i])
            self.p_seasons[#self.p_seasons + 1] = d
        end
    end

    self.p_prizePool = data.prizePool or 0
end

--QuestNewRankUser
function QuestNewRankData:createRankUser(data)
    local rankUser = {
        p_rank = data.rank,
        p_name = data.name,
        p_points = data.points,
        p_udid = data.udid,
        p_fbid = data.facebookId,
        p_head = data.head or 0,
        p_frameId = data.frame,
    }

    if data.udid == globalData.userRunData.userUdid then
        if not gLobalSendDataManager:getIsFbLogin() then
            -- 如果是我自己 并且 我没有登录facebook那么置空的facebookid (服务器不知道你退出了facebook)
            rankUser.p_fbid = ""
        end
        rankUser.p_head = globalData.userRunData.HeadName or 1
    end

    return rankUser
end

--QuestNewReward
function QuestNewRankData:createReward(data)
    local reward = {
        p_rank = data.minRank,
        p_minRank = data.minRank,
        p_maxRank = data.maxRank,
        p_coins = tonumber(data.coins),
        p_items = nil
    }

    if data.items ~= nil and #data.items > 0 then
        reward.p_items = {}
        for i = 1, #data.items do
            local itemConfig = ShopItem:create()
            itemConfig:parseData(data.items[i], true)
            reward.p_items[#reward.p_items + 1] = itemConfig
        end
    end

    return reward
end

--QuestNewSeason
function QuestNewRankData:createSeason(data)
    local season = {
        p_rank = data.rank,
        p_season = data.season
    }

    return season
end

--获取自己在所有排名中的序号
function QuestNewRankData:getSelfRankIndex()
    if self.p_myRank ~= nil then
        return self:getRankIndex(self.p_myRank.p_udid)
    end

    return -1
end

--获取排名
function QuestNewRankData:getRankIndex(udid)
    if self.p_rankUsers ~= nil then
        for i = 1, #self.p_rankUsers do
            local data = self.p_rankUsers[i]
            if data ~= nil and data.p_udid == udid then
                return i
            end
        end
    end

    return -1
end

--获取排行信息
function QuestNewRankData:getRankConfig(index)
    if index == 2 then
        return self.p_rewards
    elseif index == 3 then
        return self.p_seasons
    end

    return self.p_rankUsers
end

--获取自己排行信息
function QuestNewRankData:getMyRankConfig()
    return self.p_myRank
end

return QuestNewRankData
