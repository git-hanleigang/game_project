local Activity_LevelDashPlusManager = class(" Activity_LevelDashPlusManager", BaseActivityControl)

function Activity_LevelDashPlusManager:ctor()
    Activity_LevelDashPlusManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LevelDashPlus)
end

--创建奖励UI
function Activity_LevelDashPlusManager:createRewardListByIndex(index)
    local array = {}
    local data = self:getData()
    if data then
        local rewardData = data:getDataByIndex(index)
        if not rewardData then
            return {}
        end
        for i, v in ipairs(rewardData:getItemList()) do
            local shopItemUI = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.REWARD)
            array[i] = shopItemUI
        end
    end
    return array
end

function Activity_LevelDashPlusManager:setLevelDashPlusIndex(index)
    local data = self:getRunningData()
    if data then
        self:getData():setLevelDashPlusIndex(index)
    end
end

function Activity_LevelDashPlusManager:getLevelDashPlusIndex()
    return self:getData():getLevelDashPlusIndex()
end

--判断本次spin是否可以显示tip
function Activity_LevelDashPlusManager:canShowMissionRushTip()
    if not self:isDownloadRes() then
        return false
    end
    if not self:isRunning() then
        return false
    end

    if self._isFirstCheck then
        self._isFirstCheck = false
        return false
    end

    if self._nextSpinOpen then
        return true
    end
    self:checkData()
    return false
end

function Activity_LevelDashPlusManager:lobbyOnEnter()
    if self:isRunning() then
        self._isFirstCheck = true
        self:getData():setStatus()
        if not self:isRunning() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COMPLETED, {id = self:getData():getID(), name = self:getData():getRefName()})
        end
    end
end

function Activity_LevelDashPlusManager:checkData()
    if self:getLevelDashPlusIndex() then
        self._nextSpinOpen = true
    else
        self._nextSpinOpen = false
    end
end

-- function Activity_LevelDashPlusManager:showPopLayer()
--     local view = util_createView("Activity/Activity_LevelDashPlusTip.lua")
--     gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
--     self:setLevelDashPlusIndex(nil)
--     self._nextSpinOpen = false
--     return view
-- end

function Activity_LevelDashPlusManager:showMissionRushTip(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    local view = util_createFindView(self:getThemeName() .. "/Activity_LevelDashPlusTip", _params)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:setLevelDashPlusIndex(nil)
    self._nextSpinOpen = false
    return view
end

function Activity_LevelDashPlusManager:getHallPath(hallName)
    return "" .. hallName .. "/" .. hallName .. "HallNode"
end

function Activity_LevelDashPlusManager:getSlidePath(slideName)
    return "" .. slideName .. "/" .. slideName .. "SlideNode"
end

function Activity_LevelDashPlusManager:getPopPath(popName)
    return "" .. popName .. "/" .. popName
end

return Activity_LevelDashPlusManager
