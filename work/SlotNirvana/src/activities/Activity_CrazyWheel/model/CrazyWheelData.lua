--[[
]]
local CrazyWheelRewardData = import(".CrazyWheelRewardData")

local BaseActivityData = require("baseActivity.BaseActivityData")
local CrazyWheelData = class("CrazyWheelData", BaseActivityData)

function CrazyWheelData:ctor()
    CrazyWheelData.super.ctor(self)
end

-- message CrazyWheel {
--     optional string activityId = 1; // 活动的id
--     optional string activityName = 2;// 活动的名称
--     optional string begin = 3;// 活动的开启时间
--     optional string end = 4;// 活动的结束时间
--     optional int64 expireAt = 5; // 活动倒计时
--     repeated int32 multiples = 6; // 乘倍List
--     optional int32 curMultiple = 7; // 当前乘倍数
--     optional string lotteryDollarCoins = 8; // 抽奖劵对应的金币
--     optional int32 lotteryNum = 9; // 抽奖劵的个数
--     optional int32 curWheel = 10;// 当前是第几轮
--     optional int32 totalWheel = 11; //  总共是几轮
--     optional int32 curStage = 12; // 一轮当中是第几阶段
--     optional int32 totalStage = 13;// 总共多少个阶段
--     repeated CrazyWheelRewardResult wheelData = 14; //转盘奖励
--     repeated CrazyWheelRewardResult rewardData = 15;// 已经获得奖励
--     optional CrazyWheelRewardResult curRewardData = 16; // 当前阶段的获得奖励
--     repeated bool collectedList = 17;// 是否已经领过奖 根据当前是第几轮
--   }
function CrazyWheelData:parseData(_netData)
    CrazyWheelData.super.parseData(self, _netData)

    -- 乘倍List
    self.p_multiples = {}
    if _netData.multiples and #_netData.multiples > 0 then
        for i = 1, #_netData.multiples do
            table.insert(self.p_multiples, _netData.multiples[i])
        end
    end

    self.p_curMultiple = _netData.curMultiple

    self.p_lotteryDollarCoins = toLongNumber(_netData.lotteryDollarCoins)
    self.p_lotteryNum = _netData.lotteryNum
    self.p_curWheel = _netData.curWheel
    self.p_totalWheel = _netData.totalWheel
    self.p_curStage = _netData.curStage
    self.p_totalStage = _netData.totalStage

    self.m_wheelNum = 0
    self.p_wheelData = {}
    if _netData.wheelData and #_netData.wheelData > 0 then
        for i=1,#_netData.wheelData do
            local rData = CrazyWheelRewardData:create()
            rData:parseData(_netData.wheelData[i])
            table.insert(self.p_wheelData, rData)
            self.m_wheelNum = self.m_wheelNum + 1
        end
    end
    -- 完成一个阶段插一条奖励，完成轮次领奖后清空
    self.p_rewardData = {}
    if _netData.rewardData and #_netData.rewardData > 0 then
        for i=1,#_netData.rewardData do
            local rData = CrazyWheelRewardData:create()
            rData:parseData(_netData.rewardData[i])
            table.insert(self.p_rewardData, rData)
        end
    end
    self.p_curRewardData = {}
    if _netData.curRewardData and #_netData.curRewardData > 0 then
        for i=1,#_netData.curRewardData do
            local rData = CrazyWheelRewardData:create()
            rData:parseData(_netData.curRewardData[i])
            table.insert(self.p_curRewardData, rData)
        end
    end

    self.p_collectedList = {}
    if _netData.collectedList and #_netData.collectedList > 0 then
        for i = 1, #_netData.collectedList do
            table.insert(self.p_collectedList, _netData.collectedList[i])
        end
    end
end

function CrazyWheelData:getMultiples()
    return self.p_multiples
end

-- 断线重连用
function CrazyWheelData:getCurMultiple()
    return self.p_curMultiple
end

function CrazyWheelData:getLotteryDollarCoins()
    return self.p_lotteryDollarCoins
end

function CrazyWheelData:getLotteryNum()
    return self.p_lotteryNum
end

function CrazyWheelData:getCurWheel()
    return self.p_curWheel
end

function CrazyWheelData:getTotalWheel()
    return self.p_totalWheel
end

function CrazyWheelData:getCurStage()
    return self.p_curStage
end

function CrazyWheelData:getTotalStage()
    return self.p_totalStage
end

function CrazyWheelData:getWheelData()
    return self.p_wheelData
end

function CrazyWheelData:getWheelNum()
    return self.m_wheelNum
end

function CrazyWheelData:getRewardData()
    return self.p_rewardData
end

function CrazyWheelData:getCurRewardData()
    return self.p_curRewardData
end

function CrazyWheelData:getCollectedList()
    return self.p_collectedList
end

-- _index跟界面上的位置对应
function CrazyWheelData:getMultipleByIndex(_index)
    if self.p_multiples and #self.p_multiples > 0 then
        return self.p_multiples[_index] or 1
    end
    return 1
end

function CrazyWheelData:getWheelDataByIndex(_index)
    if self.p_wheelData and #self.p_wheelData > 0 then
        for i=1,#self.p_wheelData do
            local wData = self.p_wheelData[i]
            if wData:getIndex() == _index then
                return wData
            end
        end
    end
    return
end

-- 阶段奖励 转盘转出来的
function CrazyWheelData:getRewardDataByIndex(_stageIndex)
    if self.p_rewardData and #self.p_rewardData > 0 then
        return self.p_rewardData[_stageIndex]
    end
    return
end

-- 阶段展示奖励 = 之前阶段累计奖励 + 转盘转出来的奖励
function CrazyWheelData:getStageAllReward(_stageIndex)
    local allRewards = {}
    if self.p_rewardData and #self.p_rewardData > 0 then
        for i=1,#self.p_rewardData do
            if i <= _stageIndex then
                table.insert(allRewards, self.p_rewardData[i])
            end
        end
    end
    return allRewards
end

function CrazyWheelData:isRoundCollected(_round)
    _round = _round or self.p_curWheel
    if self.p_collectedList and #self.p_collectedList > 0 then
        if self.p_collectedList[_round] == true then
            return true
        end
    end
    return false
end

-- 当前轮次玩完
function CrazyWheelData:isRoundCompleted()
    -- 奖励长度与阶段大小作比较
    if self.p_rewardData and #self.p_rewardData >= self.p_totalStage then
        return true
    end
    return false
end

-- 最后一轮且已经领奖
function CrazyWheelData:isGameOver()
    if self.p_curWheel ~= nil and self.p_totalWheel ~= nil then
        if self.p_curWheel >= self.p_totalWheel and self:isRoundCollected(self.p_totalWheel) then
            return true
        end
    end
    return false
end

-- 完成最后一轮直接删除活动
function CrazyWheelData:checkCompleteCondition()
    if self:isGameOver() then
        return true
    end
    return false
end

function CrazyWheelData:isRunning()
    if not CrazyWheelData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

--获取入口位置 1：左边，0：右边
function CrazyWheelData:getPositionBar()
    return 1
end

return CrazyWheelData