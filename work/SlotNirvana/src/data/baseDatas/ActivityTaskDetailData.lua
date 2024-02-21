--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-09 14:46:48
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-26 14:41:50
FilePath: /SlotNirvana/src/data/baseDatas/ActivityTaskDetailData.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
--[[
    活动任务详细数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ActivityTaskDetailData = class("ActivityTaskDetailData",BaseActivityData)

function ActivityTaskDetailData:ctor()
    ActivityTaskDetailData.super.ctor(self)
    self.m_oldData = nil 
end

function ActivityTaskDetailData:parseData(_data,_isSaveData)
    ActivityTaskDetailData.super.parseData(self,_data)
    self.p_activityId = _data.activityId          --活动任务id
    self.p_activityName = _data.activityName        --活动任务名称
    self.p_activityCommonType = _data.activityCommonType  --活动类型
    self.p_start = tonumber(_data.start)         --开始时间
    self.p_expireAt = tonumber(_data.expireAt) + 3000           --截止时间
    self.p_expire = tonumber(_data.expire)               --剩余时间
    self.p_completed = _data.completed           --完成标识
    self.p_reward = _data.reward              --奖励发放标识
    self.p_phase = tonumber(_data.phase)              --当前阶段
    self.p_content = _data.content             --任务描述
    self.p_params = (_data.paramsV2 and #_data.paramsV2 > 0) and _data.paramsV2 or _data.params     --目标数
    self.p_process = (_data.processV2 and #_data.paramsV2 > 0) and _data.processV2 or _data.process  --已完成进度
    
    self.p_itemData = _data.itemData           --物品奖励
    self.p_coins = tonumber(_data.coins)              --金币奖励
    if _data.coinsV2 and _data.coinsV2 ~= "" and _data.coinsV2 ~= "0" then
        self.p_coins = toLongNumber(_data.coinsV2)
    end
    self.p_userType = tonumber(_data.userType)           --玩家类型
    self.p_phaseResult = _data.phaseResult        --阶段数据
    self.p_missionType = _data.missionType      --任务类型
    self.p_displayItemData = _data.displayItemData   --展示物品
    self.p_status = tonumber(_data.status)   --任务状态

    --当前数据备份
    if _isSaveData then     
        self:closeOldData()
        self.m_oldData = _data
    end
end

--------------------------数据访问接口-----------------
function ActivityTaskDetailData:getActivityTaskID( )
    return self.p_activityId
end
function ActivityTaskDetailData:getActivityTaskName( )
    return self.p_activityName
end
function ActivityTaskDetailData:getActivityCommonType( )
    return self.p_activityCommonType
end
function ActivityTaskDetailData:getCompleted( )
    return self.p_completed
end
function ActivityTaskDetailData:getReward( )
    return self.p_reward
end
function ActivityTaskDetailData:getContent( )
    return self.p_content
end
function ActivityTaskDetailData:getParams( )
    return self.p_params
end
function ActivityTaskDetailData:getProcess( )
    return self.p_process
end
function ActivityTaskDetailData:getCoins( )
    return self.p_coins
end
function ActivityTaskDetailData:getUserType( )
    return self.p_userType
end
function ActivityTaskDetailData:getPhaseResult( )
    return self.p_phaseResult
end
function ActivityTaskDetailData:getItemData( )
    return self.p_itemData
end
function ActivityTaskDetailData:getMissionType( )
    return self.p_missionType
end
function ActivityTaskDetailData:getDisplayItemData( )
    return self.p_displayItemData
end
function ActivityTaskDetailData:getStatus( )
    return self.p_status
end
function ActivityTaskDetailData:getPhase( )
    return self.p_phase
end
function ActivityTaskDetailData:getStart( )
    return self.p_start
end
-----------------旧数据访问----------------------
function ActivityTaskDetailData:getOldDataProcess()
    if self.m_oldData then 
        return self.m_oldData.process
    else 
        return nil 
    end
end

function ActivityTaskDetailData:setOldData(_data)
    self.m_oldData = _data
end

function ActivityTaskDetailData:closeOldData( )
    self.m_oldData = nil 
end


return ActivityTaskDetailData