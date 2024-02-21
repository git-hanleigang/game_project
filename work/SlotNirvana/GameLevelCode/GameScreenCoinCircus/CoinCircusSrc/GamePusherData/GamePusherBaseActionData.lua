local GamePusherBaseActionData = class("GamePusherBaseActionData")
local Config    = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local GamePusherManager   = require "CoinCircusSrc.GamePusherManager"

function GamePusherBaseActionData:ctor(  )

    self.m_pConfig = Config
    --运行时数据
    self.m_tRunningData = {}
    self.m_pGamePusherMgr                 = GamePusherManager:getInstance()

    --初始化通用数据
    self.m_tRunningData.UserData          = nil   --用户数据
    self.m_tRunningData.ActionData        = {}    --事件数据
    self.m_tRunningData.ActionState       = self.m_pConfig.PlayState.IDLE   --事件状态 可能为多个
    self.m_tRunningData.ExtraActionStates = {}    --事件下级状态 
    self.m_tRunningData.ActionType        = nil   --事件类型  
    
    self.m_tRunningData.Stage       = nil     
    self.m_tRunningData.Round       = nil 
end

----------------------------------------------------------------------------------------
-- 玩法数据 数据和状态
----------------------------------------------------------------------------------------
function GamePusherBaseActionData:setActionType(nType)
    self.m_tRunningData.ActionType = nType
end

function GamePusherBaseActionData:getActionType()
    return self.m_tRunningData.ActionType
end

--设置用户数据 即coinpusherData组装后的数据
function GamePusherBaseActionData:setActionData(data)
    self.m_tRunningData.ActionData = data
end

function GamePusherBaseActionData:getActionData()
    return self.m_tRunningData.ActionData
end

--设置用户数据 即coinpusherData
function GamePusherBaseActionData:setActionState(data)
    self.m_tRunningData.ActionState = data
end

function GamePusherBaseActionData:getActionState()
    return self.m_tRunningData.ActionState
end

--次级ActionState
function GamePusherBaseActionData:setExtraActionStates(extraActionStates)
    self.m_tRunningData.ExtraActionStates = extraActionStates
end

function GamePusherBaseActionData:getExtraActionState()
    return self.m_tRunningData.ExtraActionStates or {}
end


---------------------------------------------------------------------------------------
-- 检测玩法是否走完
---------------------------------------------------------------------------------------

function GamePusherBaseActionData:checkActionDone()
    local actionState = self:getActionState()
    return actionState == self.m_pConfig.PlayState.DONE
end

function GamePusherBaseActionData:checkActionStateDone(actionStates)
    for k,v in pairs(actionStates) do
        if type(v) == "table" then
            local bDone = self:checkActionStateDone(v)
            if not bDone then
                return false
            end
        else
            if  v ~= self.m_pConfig.PlayState.DONE  then
                return false
            end
        end
    end
    return true
end

--递归检测是否全部完成
function GamePusherBaseActionData:checkExtraActionStateDone()
    local extraAcitonStates = self:getExtraActionState()

    --如果是个空表 返回false 
    if table.nums(extraAcitonStates) == 0 then
        return false
    end

    for k,v in pairs(extraAcitonStates) do
        if type(v) == "table" then
            local bDone = self:checkActionStateDone(v)
            return bDone
        else
            if v ~= self.m_pConfig.PlayState.DONE then
                return false
            end
        end
    end
    return true
end

--检测所有的状态是否结束 检查ActionState和 ExtraActionState
function GamePusherBaseActionData:checkAllStateDone()
    if not self:checkActionDone() then
        if not self:checkExtraActionStateDone() then
            return false
        end
        return true
    else
        return true
    end
end

return GamePusherBaseActionData