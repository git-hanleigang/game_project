--[[
]]

local OutsideGaveWheelPoolData = util_require("activities.Activity_OutsideCave.model.OutsideGaveWheelPoolData")
local OutsideGaveWheelGameData = class("OutsideGaveWheelGameData")

-- message OutsideGaveWheelGame {
--     optional int32 wheelLefts = 1; //转盘剩余次数
--     repeated OutsideGaveWheelPool rewardPool = 2; //转盘玩法奖池
--     repeated int32 positions = 3; //本次转盘全部奖励的位置
--     optional int32 betGear = 4; //触发转盘的bet及倍数
-- }
function OutsideGaveWheelGameData:parseData(data)
    self.wheelLefts = data.wheelLefts

    -- 扇面基础数据，没有乘以倍数
    self.rewardPool = {}
    if data.rewardPool and #data.rewardPool > 0 then
        for i=1,#data.rewardPool do
            local pool = OutsideGaveWheelPoolData:create()
            pool:parseData(data.rewardPool[i])
            table.insert(self.rewardPool, pool)
        end
    end

    -- 初始化时长度是0，每次spin请求后插入结果数据
    self.hitPositions = {}
    if data.positions and #data.positions > 0 then
        for i=1,#data.positions do
            table.insert(self.hitPositions, data.positions[i])
        end
    end

    self.betGear = data.betGear

    -- 总次数
    self.m_totalNum = self.wheelLefts + #self.hitPositions
end

function OutsideGaveWheelGameData:getWheelLefts()
    return self.wheelLefts
end

function OutsideGaveWheelGameData:getRewardPool()
    return self.rewardPool
end

function OutsideGaveWheelGameData:getRewardPoolByIndex(_index)
    if _index and _index > 0 and self.rewardPool and #self.rewardPool > 0 then
        return self.rewardPool[_index]
    end
    return
end

function OutsideGaveWheelGameData:getHitPositions()
    return self.hitPositions
end

-- 转盘奖励倍数
function OutsideGaveWheelGameData:getMultiple()
    return self.betGear
end

function OutsideGaveWheelGameData:getTotalNum()
    return self.m_totalNum
end

-- 断线重连用
function OutsideGaveWheelGameData:hasWheel()
    if self.wheelLefts > 0 then
        return true
    end
    return false
end

return OutsideGaveWheelGameData