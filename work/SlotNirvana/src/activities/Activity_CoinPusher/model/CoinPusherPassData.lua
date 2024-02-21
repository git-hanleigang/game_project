--[[
    推币机PASS
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CoinPusherPassData = class("CoinPusherPassData", BaseActivityData)

--[[
    message CoinPusherPass {
        repeated CoinPusherPoint pointResults = 1;//蛋相关数据
        optional int64 coins = 2; //奖池金币
        optional int32 passPoints = 3;//当前蛋数
    }
    
    message CoinPusherPoint {
        optional int64 coins = 1; //阶段对应的金币
        optional int32 pointData = 2;  //阶段对应蛋数
        optional bool rewardFlag = 3; //奖励是否已经领取
    }
]]
function CoinPusherPassData:ctor()
    CoinPusherPassData.super.ctor(self)
    self.m_open = false
end

function CoinPusherPassData:parseData(data)
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
function CoinPusherPassData:setLastPoints(value)
    self.m_lastPoints = value
end

function CoinPusherPassData:setIsGuide(value)
    gLobalDataManager:setBoolByField("CoinPusherPassDataIsGuide", value)
end

function CoinPusherPassData:setCanCollectAllIndex()
    self.collectArr = {}
    for k, v in pairs(self.m_pointData) do
        local state = self:getStateByIndex(k)
        if state == 1 then
            table.insert(self.collectArr, k)
        end
    end
end

---------------------------------- get方法 ----------------------------------
function CoinPusherPassData:checkPassOpen()
    return self.m_open
end

function CoinPusherPassData:getPoints()
    return math.min(self.m_passPoints, self:getTotalPoints())
end

function CoinPusherPassData:getCoin()
    return self.m_coins
end

function CoinPusherPassData:getTotalPoints()
    return self.m_pointData[#self.m_pointData].points
end

function CoinPusherPassData:getPointData()
    return self.m_pointData or {}
end

function CoinPusherPassData:getPointDataLength()
    return table.nums(self:getPointData())
end

function CoinPusherPassData:getPassDataByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index] or {}
end

function CoinPusherPassData:getPointsByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index].points
end

function CoinPusherPassData:getCoinsByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index].coins
end

function CoinPusherPassData:getIsRewardByIndex(index)
    index = math.min(index, self:getPointDataLength())
    return self.m_pointData[index].isReward
end

function CoinPusherPassData:getLastPoints()
    return self.m_lastPoints or 0
end

function CoinPusherPassData:getIsGuide()
    return gLobalDataManager:getBoolByField("CoinPusherPassDataIsGuide", false)
end

function CoinPusherPassData:getStateByIndex(index, isLast) -- 0-未解锁，1-可领取，2-已领取
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

function CoinPusherPassData:getCanGetAllReward()
    local reward = 0
    for k, v in pairs(self.m_pointData) do
        local state = self:getStateByIndex(k)
        if state == 1 then
            reward = reward + v.coins
        end
    end
    return reward
end

function CoinPusherPassData:getCanCollectAllIndex()
    return self.collectArr or {}
end

--[[ 
    @param egg 蛋数
    @param minP 当前点数对应的最小点数
    @param difP 差值点数
 ]]
function CoinPusherPassData:getEggByPoint(point)
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
function CoinPusherPassData:isCanCollectByIndex(index)
    return self:getStateByIndex(index) == 1
end

function CoinPusherPassData:isLockByIndex(index)
    return self:getStateByIndex(index) == 0
end

function CoinPusherPassData:isCanCollect()
    for k, v in pairs(self.m_pointData) do
        local state = self:getStateByIndex(k)
        if state == 1 then
            return true
        end
    end
    return false
end

function CoinPusherPassData:isAllUnlock()
    return self:getLastPoints() >= self:getTotalPoints()
end

function CoinPusherPassData:isPopView()
    if self.m_passPoints > self:getTotalPoints() then
        return false
    end
    return self:isCanCollect()
end

return CoinPusherPassData
