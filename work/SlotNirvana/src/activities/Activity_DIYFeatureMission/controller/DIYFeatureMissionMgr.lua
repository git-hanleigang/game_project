
local DIYFeatureMissionNet = require("activities.Activity_DIYFeatureMission.net.DIYFeatureMissionNet")
local DIYFeatureMissionMgr = class("DIYFeatureMissionMgr", BaseActivityControl)

local PAGE_TYPE = {
    Simple = 1,
    Hard = 2
}

function DIYFeatureMissionMgr:ctor()
    DIYFeatureMissionMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DIYFeatureMission)
    self.m_DIYFeatureMissionNet = DIYFeatureMissionNet:getInstance()
    self.m_config = util_require("activities.Activity_DIYFeatureMission.config.DIYFeatureMissionConfig")
    -- 前置活动设置
    self:addPreRef(ACTIVITY_REF.DiyFeature)

    self.m_pageType = PAGE_TYPE.Simple
    self.m_feature = false --付费任务领奖时用 返回老数据还是新数据
    self.m_reward = nil -- 创建奖励用 奖励是否领完
end

-- function DragonChallengeMgr:getDIYFeatureMissionData()
--     local actData = self:getRunningData()
--     if not actData then
--         return {}
--     end
--     return actData:getTaskData()
-- end
function DIYFeatureMissionMgr:getTaskData(_type)
    local actData = self:getRunningData()
    if not actData then
        return {}
    end
    return actData:getTaskData(_type)
end

function DIYFeatureMissionMgr:updateSlotData(data)
    local _data = self:getData()
    if _data then
        _data:parseData(data)
    end
end

function DIYFeatureMissionMgr:getPageType()
    return self.m_pageType
end

function DIYFeatureMissionMgr:setPageType(_type)
    self.m_pageType = _type
end

function DIYFeatureMissionMgr:getConfig(_type)
    return self.m_config
end

function DIYFeatureMissionMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function DIYFeatureMissionMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function DIYFeatureMissionMgr:getPopPath(popName)
    -- if not self:isCanShowPop() then
    --     return nil
    -- end
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function DIYFeatureMissionMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName .."/Activity/" .. themeName .. "EntryNode" 
end

function DIYFeatureMissionMgr:isCanShowHall()
    local isCanShow = DIYFeatureMissionMgr.super.isCanShowHall(self)
    if isCanShow then
        if self:taskIsOver() then --任务结束
            isCanShow = false
        end
    end
    return isCanShow
end

function DIYFeatureMissionMgr:isCanShowSlide()
    local isCanShow = DIYFeatureMissionMgr.super.isCanShowSlide(self)
    if isCanShow then
        if self:taskIsOver() then --任务结束
            isCanShow = false
        end
    end
    return isCanShow
end

function DIYFeatureMissionMgr:isCanShowEntry()
    local isCanShow = DIYFeatureMissionMgr.super.isCanShowEntry(self)
    if isCanShow then
        if self:taskIsOver() then --任务结束
            isCanShow = false
        end
    end
    return isCanShow
end

function DIYFeatureMissionMgr:isCanShowInEntrance()
    local isCanShow = DIYFeatureMissionMgr.super.isCanShowInEntrance(self)
    if isCanShow then
        if self:taskIsOver() then --任务结束
            isCanShow = false
        end
    end
    return isCanShow
end

function DIYFeatureMissionMgr:isCanShowPop(...)
    local isCanShow = DIYFeatureMissionMgr.super.isCanShowPop(self,...)
    if isCanShow then
        if gLobalViewManager:getViewByExtendData("Activity_DIYFeatureMission") ~= nil then 
            isCanShow = false
        end
        if self:taskIsOver() then --任务结束
            isCanShow = false
        end
    end
    return isCanShow
end

--
function DIYFeatureMissionMgr:taskIsOver()
    local isOver = true
    local act_data = self:getRunningData()
    if act_data then
       -- 任务是否全部完成
       isOver = act_data:getIsOver()
    end
    return isOver
end


function DIYFeatureMissionMgr:isCanShowLayer()
    local activityData = G_GetMgr(ACTIVITY_REF.DiyFeature):getRunningData()
    if not activityData or activityData:getIsActivateGame() then
        return false
    end
    return DIYFeatureMissionMgr.super.isCanShowLayer(self)
end

function DIYFeatureMissionMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:taskIsOver() then --任务结束
        return
    end
    local view = util_createView("Activity_DIYFeatureMission.Activity.Activity_DIYFeatureMission")
    if view ~= nil then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

-- 入口节点点击
function DIYFeatureMissionMgr:onClickShowMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:taskIsOver() then --任务结束
        return
    end
    --获取数据
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        local view = util_createView("Activity_DIYFeatureMission.Activity.Activity_DIYFeatureMission")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end
    gLobalViewManager:addLoadingAnima(false, 1)
    self.m_DIYFeatureMissionNet:sendDiyTaskUpdate(successCallback, failedCallback)
end


function DIYFeatureMissionMgr:sendCollect(_data)
    
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        --领取成功
        -- local actData = self:getRunningData()
        -- if actData and _result and _result.DiyFeatureMission then 
        --     actData:parseData(_result.DiyFeatureMission)
        -- end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DIYFEATURE_FLYPOINT_OVER)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DIYFEATUREMISSION_TASK_COLLECT, {success = true,data = _data})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DIYFEATUREMISSION_TASK_COLLECT)
    end
    self.m_DIYFeatureMissionNet:sendCollect(_data,successCallback,failedCallback)
end

--刷新任务数据
function DIYFeatureMissionMgr:sendDiyTaskUpdate()
    local successCallback = function (_result)  
    end

    local failedCallback = function (errorCode, errorData)
    end
    self.m_DIYFeatureMissionNet:sendDiyTaskUpdate(successCallback,failedCallback)
end

-- 付费任务完成后 弹出主弹板 (然后弹领奖)
function DIYFeatureMissionMgr:showHardTaskMasterRewardLayer(callback)
    local isShow = true
    if not self:isCanShowLayer() then
        isShow = false
    end

    local actData = self:getRunningData()
    if not actData then
        isShow = false
    else
        local hardTaskComplete = actData:hardTaskHandle()
        if hardTaskComplete == nil then
            isShow = false
        else
            hardTaskComplete:unpdateHardTaskData() -- 更新旧数据
            self.m_reward =  hardTaskComplete
        end
    end
 
    if not isShow then
        if callback then
            callback()
        end
    else
        self.m_feature = true
        local view = util_createView("Activity_DIYFeatureMission.Activity.Activity_DIYFeatureMission",callback)
        if view ~= nil then
            self.m_pageType = PAGE_TYPE.Hard
            view:changePage(PAGE_TYPE.Hard)
            self:showLayer(view, ViewZorder.ZORDER_UI)
        else
            if callback then
                callback()
            end
        end
    end
end

-- 付费任务完成后 弹出主弹板 然后弹领奖
function DIYFeatureMissionMgr:showHardTaskRewardLayer()
    if not self:isCanShowLayer() then
        return 
    end
    --
    if nil == self.m_reward then
        return 
    end

    local viewReward = util_createView("Activity_DIYFeatureMission.Activity.Activity_DIYFeatureMissionRewardLayer")
    if viewReward ~= nil then
        self:showLayer(viewReward, ViewZorder.ZORDER_UI + 1)
    end

end


function DIYFeatureMissionMgr:getFeature()
    return  self.m_feature 
end

function DIYFeatureMissionMgr:setFeature(val)
    self.m_feature = val
end

function DIYFeatureMissionMgr:clearReward()
    self.m_reward = nil
end

function DIYFeatureMissionMgr:getReward()
    return self.m_reward
end

function DIYFeatureMissionMgr:clearFeature()
    self.m_feature = nil
    --更新旧数据
    local actData = self:getRunningData()
    if actData then
        actData:updataHardTaskListOld()
    end 
end

--活动结束处理 （先判断活动是否结束）
-- function DIYFeatureMissionMgr:actOverHandle()
--     local isOver = self:taskIsOver()
--     if isOver then --结束活动

--     end
-- end

return DIYFeatureMissionMgr
