local CoinPusherBaseActionData = class("CoinPusherBaseActionData")
local Config = G_GetMgr(ACTIVITY_REF.CoinPusher):getConfig()

function CoinPusherBaseActionData:ctor()
    self._Config = Config
    --运行时数据
    self._RunningData = {}

    --初始化通用数据
    self._RunningData.UserData = nil --用户数据
    self._RunningData.ActionData = {} --事件数据
    self._RunningData.ActionState = self._Config.PlayState.IDLE --事件状态 可能为多个
    self._RunningData.ExtraActionStates = {} --事件下级状态
    self._RunningData.ActionType = nil --事件类型
    self._RunningData.Stage = nil
    self._RunningData.Round = nil
end

--设置用户数据 即coinpusherData
function CoinPusherBaseActionData:setUserData(data)
    self._RunningData.UserData = data
end

--更新用户数据
function CoinPusherBaseActionData:updateUserData()
    local coinPusherData = G_GetMgr(ACTIVITY_REF.CoinPusher):getRunningData()
    if coinPusherData then
        local runningData = coinPusherData:getRuningData()
        if self._RunningData.UserData then
            self._RunningData.UserData:setRunningData(runningData)
        else
            local data = self:createUserData(runningData)
            self:setUserData(data)
        end
    end
end

function CoinPusherBaseActionData:createUserData(data)
    local _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherRunningData")
    local runingUserDate = _dataModule:create()
    runingUserDate:setRunningData(data)
    return runingUserDate
end

function CoinPusherBaseActionData:getUserData()
    return self._RunningData.UserData
end

function CoinPusherBaseActionData:getUserDataPushes()
    return self._RunningData.UserData:getPushes()
end

function CoinPusherBaseActionData:addUserDataPushesCount(_countAddStage)
    -- self._RunningData.UserData._
    local pushes = self:getUserDataPushes()
    self._RunningData.UserData:setPushes(pushes + _countAddStage)
end

--设置用户数据 即coinpusherData
function CoinPusherBaseActionData:setActionType(nType)
    self._RunningData.ActionType = nType
end

function CoinPusherBaseActionData:getActionType()
    return self._RunningData.ActionType
end

--设置用户数据 即coinpusherData组装后的数据
function CoinPusherBaseActionData:setActionData(data)
    self._RunningData.ActionData = data
end

function CoinPusherBaseActionData:getActionData()
    return self._RunningData.ActionData
end

--设置用户数据 即coinpusherData
function CoinPusherBaseActionData:setActionState(data)
    self._RunningData.ActionState = data
end

function CoinPusherBaseActionData:getActionState()
    return self._RunningData.ActionState
end

--次级ActionState
function CoinPusherBaseActionData:setExtraActionStates(extraActionStates)
    self._RunningData.ExtraActionStates = extraActionStates
end

function CoinPusherBaseActionData:getExtraActionState()
    return self._RunningData.ExtraActionStates or {}
end

function CoinPusherBaseActionData:checkStagePass()
    local stage = self:getStageData()
    if stage then
        return true
    end
    return false
end

function CoinPusherBaseActionData:checkRoundPass()
    local round = self:getRoundData()
    if round then
        return true
    end
    return false
end

function CoinPusherBaseActionData:getStageData()
    return self._RunningData.PassStageData
end

function CoinPusherBaseActionData:getRoundData()
    return self._RunningData.PassRoundData
end

function CoinPusherBaseActionData:setStageData(data)
    self._RunningData.PassStageData = data
end

function CoinPusherBaseActionData:setRoundData(data)
    self._RunningData.PassRoundData = data
end

function CoinPusherBaseActionData:getCardDropData()
    return self:getStageData().cardDrops
end

function CoinPusherBaseActionData:getItemData()
    return self:getStageData().items
end

function CoinPusherBaseActionData:getRewarCoins()
    return self:getStageData().rewardCoinsEnd
end

function CoinPusherBaseActionData:getRoundCardDropData()
    return self:getRoundData().cardDrops
end

function CoinPusherBaseActionData:getRoundItemData()
    return self:getRoundData().items
end

function CoinPusherBaseActionData:getRoundRewarCoins()
    return self:getRoundData().rewardCoinsEnd
end

function CoinPusherBaseActionData:checkActionDone()
    local actionState = self:getActionState()
    return actionState == self._Config.PlayState.DONE
end

function CoinPusherBaseActionData:checkActionStateDone(actionStates)
    for k, v in pairs(actionStates) do
        if type(v) == "table" then
            local bDone = self:checkActionStateDone(v)
            if not bDone then
                return false
            end
        else
            if v ~= self._Config.PlayState.DONE then
                return false
            end
        end
    end
    return true
end

--递归检测是否全部完成
function CoinPusherBaseActionData:checkExtraActionStateDone()
    local extraAcitonStates = self:getExtraActionState()

    --如果是个空表 返回false
    if table.nums(extraAcitonStates) == 0 then
        return false
    end

    for k, v in pairs(extraAcitonStates) do
        if type(v) == "table" then
            local bDone = self:checkActionStateDone(v)
            return bDone
        else
            if v ~= self._Config.PlayState.DONE then
                return false
            end
        end
    end
    return true
end

--检测所有的状态是否结束 检查ActionState和 ExtraActionState
function CoinPusherBaseActionData:checkAllStateDone()
    if not self:checkActionDone() then
        if not self:checkExtraActionStateDone() then
            return false
        end
        return true
    else
        return true
    end
end

function CoinPusherBaseActionData:getRunningData()
    local data = clone(self._RunningData)
    data.UserData = data.UserData:getRunningData()
    return data
end

function CoinPusherBaseActionData:setRunningData(data)
    self._RunningData = data
    local data = self:createUserData(self._RunningData.UserData)
    self:setUserData(data)
end

return CoinPusherBaseActionData
