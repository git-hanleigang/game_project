--[[
    自选任务
]]

local PickTaskNet = require("activities.Activity_PickTask.net.PickTaskNet")
local PickTaskManager = class("PickTaskManager", BaseActivityControl)

function PickTaskManager:ctor()
    PickTaskManager.super.ctor(self)

    self:setRefName(ACTIVITY_REF.PickTask)
    self.m_netModel = PickTaskNet:getInstance()   -- 网络模块

    self.m_hasInit = false
    self.m_saveTaskStatus = {}
    self.m_curTaskStatus = {}
end

function PickTaskManager:collectReward()
    self.m_netModel:sendCollectReward()
end

function PickTaskManager:getConfig()
    self.m_netModel:sendGetConfig()
end

function PickTaskManager:showRewardLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Activity_PickTaskReward") == nil then
        local view = util_createView("Activity_PickTask.Activity.Activity_PickTaskReward", _data)
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    end
end

function PickTaskManager:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local data = _data
    if not data then
        local flag, typeList = self:checkTaskStatus()
        data = {isMianLayer = true, isComplete = flag, type = typeList}
    end

    local view = util_createView("Activity_PickTask.Activity.Activity_PickTask", data)
    gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    return view
end

function PickTaskManager:shwoCompleteTipLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Activity_PickTaskCompleteTip") == nil then
        local view = util_createView("Activity_PickTask.Activity.Activity_PickTaskCompleteTip", _data)
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
        return view
    end
end

function PickTaskManager:setTaskStatus(_taskStatus)
    if self.m_hasInit then
        self.m_curTaskStatus = _taskStatus
    else
        self.m_saveTaskStatus = _taskStatus
        self.m_curTaskStatus = _taskStatus
        self.m_hasInit = true
    end
end

function PickTaskManager:checkTaskStatus()
    local typeList = {count = 0}
    local flag = false
    for k,v in pairs(self.m_curTaskStatus) do
        if v == true and not self.m_saveTaskStatus[k] then
            typeList[k] = true
            typeList.count = typeList.count + 1
            flag = true
        end
    end
    
    self.m_saveTaskStatus = self.m_curTaskStatus
    return flag, typeList
end

function PickTaskManager:checkShowComplete(_isSendLayer)
    if not self:isCanShowLayer() then
        return nil
    end

    local data = self:getRunningData()
    local flag, typeList = self:checkTaskStatus()
    if flag and data then
        local finishMax = data:getFinishMax()
        local finishCount = data:getFinishCount()
        if finishCount >= finishMax then
            self:showMainLayer({isMianLayer = true, isComplete = true, type = typeList})
        else
            self:shwoCompleteTipLayer({isMianLayer = true, isComplete = true, type = typeList, isAutoClose = true})
        end
    end
    return flag
end

function PickTaskManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function PickTaskManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function PickTaskManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return PickTaskManager
