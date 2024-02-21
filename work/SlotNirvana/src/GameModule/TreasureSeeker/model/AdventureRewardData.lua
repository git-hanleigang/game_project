--[[
    message AdventureReward {
    optional int32 chapter = 1;//当前章节
    optional int32 special = 2; //是否是特殊章节
    optional int32 needGems = 3; //支付需要宝石数
    repeated int32 index = 4; //要翻开箱子位置
    repeated AdventureRewardBox rewards = 5;//箱子配置
    }
]]
local AdventureRewardBoxData = import(".AdventureRewardBoxData")
local AdventureRewardData = class("AdventureRewardData")

function AdventureRewardData:parseData(data)
    self.p_chapter = data.chapter
    -- 当前层还剩余开宝箱的次数
    self.p_retainOpenCount = data.leftCount
    -- 打开宝箱奖励位置，从0开始计数
    self.p_boxRewardIndexs = {}
    if data.index and #data.index > 0 then
        for i = 1, #data.index do
            table.insert(self.p_boxRewardIndexs, data.index[i])
        end
    end
    -- 已经打开的宝箱位置， 客户端传给服务器的，从1开始计数
    self.p_openedClientPos = {}
    if data.pos and #data.pos > 0 then
        for i = 1, #data.pos do
            table.insert(self.p_openedClientPos, data.pos[i])
        end
    end
    self.p_boxRewards = {}
    if data.rewards and #data.rewards > 0 then
        for i = 1, #data.rewards do
            local boxRewardData = AdventureRewardBoxData:create()
            boxRewardData:parseData(data.rewards[i])
            table.insert(self.p_boxRewards, boxRewardData)
        end
    end
end

-- 从0开始计数
function AdventureRewardData:getBoxRewardIndexs()
    return self.p_boxRewardIndexs
end

function AdventureRewardData:getLastBoxRewardIndex()
    if self.p_boxRewardIndexs and #self.p_boxRewardIndexs > 0 then
        return self.p_boxRewardIndexs[#self.p_boxRewardIndexs]
    end
    return nil
end

-- 从1开始计数, 客户端传给服务器的数值
function AdventureRewardData:getOpenedClientPos()
    return self.p_openedClientPos
end

function AdventureRewardData:getBoxRewards()
    return self.p_boxRewards
end

function AdventureRewardData:getOpenedBoxCount()
    return #self.p_openedClientPos
end

function AdventureRewardData:isFinish()
    return self.p_retainOpenCount == 0
end

function AdventureRewardData:getBoxReward(_index)
    assert(_index and _index > 0, "index 参数错误")
    if self.p_boxRewards and #self.p_boxRewards > 0 then
        return self.p_boxRewards[_index]
    end
    return nil
end

function AdventureRewardData:getWillOpenBoxRewardData()
    local index = self:getLastBoxRewardIndex()
    if index ~= nil then
        return self:getBoxReward(index + 1)
    end
    return nil
end

function AdventureRewardData:getUnOpenedBoxRewardData()
    local boxDatas = {}
    for i = 1, TreasureSeekerCfg.BoxTotalCount do
        local boxData = self.p_boxRewards[i]
        if not boxData:isOpened() then
            boxDatas[#boxDatas + 1] = boxData
        end
    end
    return boxDatas
end

-- 判断已经打开的箱子的类型。如果是鲨鱼，则断线重连
function AdventureRewardData:isWillOpenMonster()
    if self.p_boxRewards and #self.p_boxRewards > 0 then
        local index = self:getLastBoxRewardIndex()
        if index ~= nil then
            if self.p_boxRewards[index + 1]:isMonsterBox() then
                return true
            end
        end
    end
    return false
end

function AdventureRewardData:isBoxOpened(_boxIndex)
    if self.p_openedClientPos and #self.p_openedClientPos > 0 then
        for i = 1, #self.p_openedClientPos do
            local openedIndex = self.p_openedClientPos[i]
            if _boxIndex == openedIndex then
                return true
            end
        end
    end
    return false
end

return AdventureRewardData
