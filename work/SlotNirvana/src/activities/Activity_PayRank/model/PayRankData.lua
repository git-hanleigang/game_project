--[[
    付费排行榜
]]

local PayRankConfig = require("activities.Activity_PayRank.config.PayRankConfig")
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local PayRankData = class("PayRankData",BaseActivityData)

-- message PayRank {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated PayRankRewardResult rankRewardList = 4;//排行榜奖励
--     repeated PayRankUserRank rankList = 5;//排行榜
--     optional PayRankUserRank myRank = 6;//个人排名
--     optional bool unlock = 7;//是否解锁
--     optional int32 points = 8;//当前
--     optional int32 unlockPoints = 9;//解锁积分
--   }
function PayRankData:parseData(_data)
    PayRankData.super.parseData(self, _data)

    self.p_unlock = _data.unlock
    self.p_points = _data.points
    self.p_unlockPoints = _data.unlockPoints
    self.p_myRank = self:parseRankData(_data.myRank)
    self.p_rankList = self:parseRankList(_data.rankList)
    self.p_rankRewardList = self:parseRewardList(_data.rankRewardList)

    gLobalNoticManager:postNotification(PayRankConfig.notify_update_data)
end

-- message PayRankUserRank {
--     optional int32 rank = 1;
--     optional string name = 2;
--     optional int32 points = 3;
--     optional string facebookId = 4;
--     optional string udid = 5;
--     optional string head = 6;
--     optional string frame = 7;
--     optional string robotHead = 8;
--   }
function PayRankData:parseRankData(_data)
    local rankData = {}
    if _data then 
        rankData.p_rank = _data.rank
        rankData.p_name = _data.name
        rankData.p_points = _data.points
        rankData.p_facebookId = _data.facebookId
        rankData.p_udid = _data.udid
        rankData.p_head = _data.head
        rankData.p_frame = _data.frame
        rankData.p_robotHead = _data.robotHead
    end

    return rankData
end

function PayRankData:parseRankList(_data)
    local rankList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local rankData = self:parseRankData(v)
            table.insert(rankList, rankData)
        end
    end
    return rankList
end

-- message PayRankReward {
--     optional int32 index = 1;
--     optional int64 coins = 2;
--     repeated ShopItem items = 3;
--   }
function PayRankData:parseRewardList(_data)
    local rewardList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_coins = tonumber(v.coins)
            temp.p_items = self:parseItems(v.items)
            table.insert(rewardList, temp)
        end
    end
    return rewardList
end

function PayRankData:parseItems(_items)
    local itemList = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemList, tempData)
        end
    end
    return itemList
end

function PayRankData:getUnlock()
    return self.p_unlock
end

function PayRankData:getCurPoints()
    return self.p_points
end

function PayRankData:getUnlockPoints()
    return self.p_unlockPoints
end

function PayRankData:getMyRank()
    return self.p_myRank
end

function PayRankData:getRankList()
    return self.p_rankList    
end

function PayRankData:getRankRewardList()
    local tempList = {}
    for i,v in ipairs(self.p_rankRewardList) do
        local bAdd = true
        local data = self.p_rankRewardList[i]
        for k,m in ipairs(tempList) do
            local temp = m[1]
            if temp.p_coins == data.p_coins and not self:checkItemsDifferent(temp.p_items, data.p_items) then
                table.insert(m, data)
                bAdd = false
                break
            end
        end
        if bAdd then
            table.insert(tempList, {data})
        end
    end

    local dataList = {}
    for i,v in ipairs(tempList) do
        if #v == 1 then
            local data = v[1]
            local rank = data.p_index
            table.insert(dataList, {rank = rank, data = data})
        else
            local startData = v[1]
            local endData = v[#v]
            local startRank = startData.p_index
            local endRank = endData.p_index
            table.insert(dataList, {rank = startRank .. "-" .. endRank, data = startData})
        end
    end

    return dataList
end

function PayRankData:checkItemsDifferent(_items1, _items2)
    local count1 = #_items1
    local count2 = #_items2
    
    if count1 ~= count2 then
        return true
    end

    for i = 1, count1 do
        local item1 = _items1[i]
        local item2 = _items2[i]
        if item1.p_id ~= item2.p_id then
            return true
        end
    end

    return false
end

function PayRankData:getMyRankIndex()
    local index = -1
    for i,v in ipairs(self.p_rankList) do
        if v.p_udid == globalData.userRunData.userUdid then
            index = i
            break
        end
    end

    return index
end

return PayRankData
