--[[
    推币机PASS
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local NewCoinPusherPassData = class("NewCoinPusherPassData", BaseActivityData)

--[[
    message NewCoinPusherPass {
        repeated NewCoinPusherPoint pointResults = 1;//蛋相关数据
        optional int64 coins = 2; //奖池金币
        optional int32 passPoints = 3;//当前蛋数
    }
    
    message NewCoinPusherPoint {
        optional int64 coins = 1; //阶段对应的金币
        optional int32 pointData = 2;  //阶段对应蛋数
        optional bool rewardFlag = 3; //奖励是否已经领取
    }
]]
function NewCoinPusherPassData:ctor()
    NewCoinPusherPassData.super.ctor(self)
    self.m_open = false
end

function NewCoinPusherPassData:parseData(data)
    self.m_passPoints = tonumber(data.passPoints) -- 当前蛋数
    self.m_coins = tonumber(data.coins) -- 奖池金币
    self.m_pointData = {} -- 蛋相关数据
    if not self.m_lastPoints then
        self.m_lastPoints = self.m_passPoints
    end

    for k, v in ipairs(data.pointData) do
        local pointData = {}
        pointData.coins = tonumber(v.coins) -- 阶段对应的金币
        pointData.points = tonumber(v.points) -- 阶段对应蛋数
        pointData.isReward = v.rewardFlag -- 奖励是否已经领取

        table.insert(self.m_pointData, pointData)
    end

    self.m_open = #self.m_pointData > 0
end

---------------------------------- set方法 ----------------------------------
function NewCoinPusherPassData:setLastPoints(value)
    self.m_lastPoints = value
end

function NewCoinPusherPassData:setIsGuide(value)
    gLobalDataManager:setBoolByField("NewCoinPusherPassDataIsGuide", value)
end

function NewCoinPusherPassData:setCanCollectAllIndex()
    self.collectArr = {}
    for k, v in pairs(self.m_pointData) do
        local state = self:getStateByIndex(k)
        if state == 1 then
            table.insert(self.collectArr, k)
        end
    end
end

---------------------------------- get方法 ----------------------------------
function NewCoinPusherPassData:checkPassOpen()
    return self.m_open
end

function NewCoinPusherPassData:getPoints()
    return math.min(self.m_passPoints, self:getTotalPoints())
end

function NewCoinPusherPassData:getCoin()
    return self.m_coins
end

function NewCoinPusherPassData:getTotalPoints()
    return self.m_pointData[#self.m_pointData].points
end

function NewCoinPusherPassData:getPointData()
    return self.m_pointData or {}
end

function NewCoinPusherPassData:getPointDataLength()
    return table.nums(self:getPointData())
end

function NewCoinPusherPassData:getPassDataByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index] or {}
end

function NewCoinPusherPassData:getPointsByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index].points
end

function NewCoinPusherPassData:getCoinsByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index].coins
end

function NewCoinPusherPassData:getIsRewardByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index].isReward
end

function NewCoinPusherPassData:getLastPoints()
    return self.m_lastPoints or 0
end

function NewCoinPusherPassData:getIsGuide()
    return gLobalDataManager:getBoolByField("NewCoinPusherPassDataIsGuide", false)
end

function NewCoinPusherPassData:getStateByIndex(index, isLast) -- 0-未解锁，1-可领取，2-已领取
    local points = self.m_passPoints
    if isLast then
        points = self:getLastPoints()
    end
    for k, v in pairs(self.m_pointData) do
        if k == index then
            if v.points > points then
                return 0
            else
                local isReward = v.isReward == true and 2 or 1
                return isReward
            end
        end
    end
    return 0
end

function NewCoinPusherPassData:getCanGetAllReward()
    local reward = 0
    for k, v in pairs(self.m_pointData) do
        local state = self:getStateByIndex(k)
        if state == 1 then
            reward = reward + v.coins
        end
    end
    return reward
end

function NewCoinPusherPassData:getCanCollectAllIndex()
    return self.collectArr or {}
end

--[[ 
    @param egg 蛋数
    @param minP 当前点数对应的最小点数
    @param difP 差值点数
 ]]
function NewCoinPusherPassData:getEggByPoint(point)
    local point = point or self:getPoints()
    local egg, minP, maxP = 0, 0, 0
    local difP = 1
    for k, v in ipairs(self.m_pointData) do
        if point >= v.points then
            egg = k
            minP = v.points
        else
            maxP = v.points
            break
        end
    end
    if maxP == 0 then
        maxP = self:getTotalPoints()
    end
    difP = math.max(1, maxP - minP)
    return egg, minP, difP, maxP
end

---------------------------------- 判断 ----------------------------------
function NewCoinPusherPassData:isCanCollectByIndex(index)
    return self:getStateByIndex(index) == 1
end

function NewCoinPusherPassData:isLockByIndex(index)
    return self:getStateByIndex(index) == 0
end

function NewCoinPusherPassData:isCanCollect()
    for k, v in pairs(self.m_pointData) do
        local state = self:getStateByIndex(k)
        if state == 1 then
            return true
        end
    end
    return false
end

function NewCoinPusherPassData:isAllUnlock()
    return self:getLastPoints() >= self:getTotalPoints()
end

function NewCoinPusherPassData:isPopView()
    if self.m_passPoints > self:getTotalPoints() then
        return false
    end
    return self:isCanCollect()
end

return NewCoinPusherPassData
