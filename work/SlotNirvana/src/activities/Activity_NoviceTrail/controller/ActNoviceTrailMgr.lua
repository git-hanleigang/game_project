--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-26 11:32:06
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-26 11:37:46
FilePath: /SlotNirvana/src/activities/Activity_NoviceTrail/controller/ActNoviceTrailMgr.lua
Description: 新手期三日任务 mgr
--]]
local ActNoviceTrailMgr = class("ActNoviceTrailMgr", BaseActivityControl)
local ActNoviceTrailColReceiveData = util_require("activities.Activity_NoviceTrail.model.ActNoviceTrailColReceiveData")

function ActNoviceTrailMgr:ctor()
    ActNoviceTrailMgr.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.NoviceTrail)
end

-- 获取网络 obj
function ActNoviceTrailMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local ActNoviceTrailNet = util_require("activities.Activity_NoviceTrail.net.ActNoviceTrailNet")
    self.m_net = ActNoviceTrailNet:getInstance()
    return self.m_net
end

-- 显示奖励弹板
function ActNoviceTrailMgr:showRewardLayer(_itemList, _coins, _callback)
    if gLobalViewManager:getViewByName("NoviceTrailRewardLayer") then
        return
    end

    -- local view = util_createView("Activity.Activity_NoviceTrail.code.Activity_NoviceTrailRewardLayer")
    local view = gLobalItemManager:createRewardLayer(_itemList, _callback, _coins, true, "NoviceTrail")
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

-- 领取奖励
function ActNoviceTrailMgr:sendCollectTaskReq(_taskData)
    if not _taskData then
        return
    end
    local day = _taskData:getDay()
    local taskId = _taskData:getTaskId()
    self:getNetObj():sendCollectTaskReq(0, taskId, day)
end
-- 领取奖励 all
function ActNoviceTrailMgr:sendCollectTaskFastReq(_day)
    if not _day then
        return
    end
    self:getNetObj():sendCollectTaskReq(1, nil, _day)
end

-- 领取接口 数据
function ActNoviceTrailMgr:createColReceiveData(_receiveData)
    local data = ActNoviceTrailColReceiveData:create()
    data:parseData(_receiveData)
    return data
end

-- 关卡spin 更新任务
function ActNoviceTrailMgr:spinUpdateTaskList(_info)
    if type(_info) ~= "table" then
        return
    end

    local updateList = _info.updateTask
    local data = self:getRunningData()
    if data then
        data:updateTaskList(updateList)
    end
end


-- 获取最新 活动数据
function ActNoviceTrailMgr:sendGetNewActDataReq()
    self:getNetObj():sendGetNewActDataReq()
end

return ActNoviceTrailMgr