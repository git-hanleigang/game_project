--[[
Author: ZKK
Description: 比赛聚合主活动数据
--]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local BaseActivityData = require "baseActivity.BaseActivityData"
local BattleMatchData = class("BattleMatchData", BaseActivityData)

function BattleMatchData:parseData(data)
    BattleMatchData.super.parseData(self, data)
    self.m_openRankFront = self.m_openRank
    self.m_openRank = not not data.openRank -- 是否进榜 进榜之后才显示排行榜
    if self.m_openRankFront == false and self.m_openRank then
        self.m_thisTimeOpenRank = true
    else
        self.m_thisTimeOpenRank = false
    end
    self.m_openRankMinPoints = tonumber(data.openRankMinPoints) 
    self.m_collect = not not data.collect -- 是否可以领取奖励

    local currentRank = data.rank or 0 -- 排名
    if not self.m_frontRank then
        self.m_frontRank = currentRank
    else
        self.m_frontRank = self.m_rank 
    end
    self.m_rank = currentRank

    local current =  data.points and tonumber(data.points) or 0 -- 活动分
    if not self.m_frontPoints then
        self.m_frontPoints = current
    else
        self.m_frontPoints = self.m_currentPoints 
    end
    self.m_currentPoints = current

    self.m_taskData = {}
    for index, value in ipairs(data.tasks) do
        local taskData = self:parseTaskData(value)
        table.insert(self.m_taskData, taskData)
    end
    if data.rewards then
        self:parseReward(data.rewards)
    else
        self.m_hasRewards = false
    end
end
function BattleMatchData:updateActivitySlotData(data)
    local currentRank = data.myRank or 0 -- 排名
    local current =  data.myPoints and tonumber(data.myPoints) or 0 -- 活动分

    if current == self.m_currentPoints and currentRank == self.m_rank then
        return
    end

    self.m_openRankFront = self.m_openRank
    self.m_openRank = not not data.openRank -- 是否进榜 进榜之后才显示排行榜
    if self.m_openRankFront == false and self.m_openRank then
        self.m_thisTimeOpenRank = true
    else
        self.m_thisTimeOpenRank = false
    end

    if not self.m_frontRank then
        self.m_frontRank = currentRank
    else
        self.m_frontRank = self.m_rank 
    end
    self.m_rank = currentRank

    if not self.m_frontPoints then
        self.m_frontPoints = current
    else
        self.m_frontPoints = self.m_currentPoints 
    end
    self.m_currentPoints = current
end

function BattleMatchData:clearCompareData()
    self.m_frontRank = self.m_rank
    self.m_frontPoints = self.m_currentPoints
end

function BattleMatchData:resetFrontPoints()
    self.m_frontPoints = self.m_currentPoints
end

function BattleMatchData:resetThisTimeOpenRank()
    self.m_thisTimeOpenRank = false
end

function BattleMatchData:parseTaskData(data)
    if not data then
        return
    end
    local taskData = {}
    taskData.taskType           =    data.type
    taskData.points             =    data.unitPoint
    taskData.icon               =    data.icon
    taskData.description        =    data.description
    return taskData
end

function BattleMatchData:parseReward(data)
    self.m_rewards = {}
    self.m_hasRewards = true
    self.m_rewards.coins = tonumber(data.coins)
    self.m_rewards.items = self:parseItems(data.items)
    if self.m_rewards.coins <= 0 and #self.m_rewards.items ==0 then
        self.m_hasRewards = false
    end
end

function BattleMatchData:parseItems(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function BattleMatchData:getTaskData( )
    return self.m_taskData 
end

-- 解析排行榜信息
function BattleMatchData:parseBattleMatchRankData(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self.m_frontRank = self.m_rank
        self.m_rank = myRankConfigInfo.p_rank
        self.m_myrankData = myRankConfigInfo
    end
end

-- 获取排行榜数据
function BattleMatchData:getRankData()
    local rankDataVec = {}
    local oneData123 = {}
    local rankCofing = self.p_rankCfg:getRankConfig()
    for i,v in ipairs(rankCofing) do
        if i > 3 then
            table.insert(rankDataVec, v) 
        else
            oneData123[i] = v
            if #oneData123 == 3 then
                table.insert(rankDataVec, oneData123) 
            end
        end
    end
    return rankDataVec
end

--获取排名
function BattleMatchData:getRankIndex(udid)
    local p_rankUsers = self.p_rankCfg.p_rankUsers
    if p_rankUsers ~= nil then
        for k, v in ipairs(p_rankUsers) do
            if v.p_udid == udid then
                return k
            end
        end
    end
    return -1
end

--获取入口位置 1：左边，0：右边
function BattleMatchData:getPositionBar()
    return 1
end

function BattleMatchData:isCanDelete()
    return false
end

function BattleMatchData:isIgnoreExpire()
    return true
end

function BattleMatchData:isRunning()
    if not self:checkOpenLevel() then
        return false
    end
    if self:getOpenFlag() or self:getBuffFlag() then
        return not self:isCompleted()
    else
        return false
    end
end

function BattleMatchData:checkCompleteCondition()
    local leftTime = self:getLeftTime()
    return not (leftTime > 0)
end

return BattleMatchData
