local Activity_MissionRushNewManager = class(" Activity_MissionRushNewManager", BaseActivityControl)

function Activity_MissionRushNewManager:ctor()
    Activity_MissionRushNewManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ActivityMissionRushNew)

    self:registEvents()
end

function Activity_MissionRushNewManager:registEvents()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self:isRunning() then
                return false
            end
            self:checkData()
        end,
        ViewEventType.NOTIFY_DAILYPASS_OPENGIFT_ACTION
    )
end

--创建奖励UI
function Activity_MissionRushNewManager:createRewardListByIndex(index)
    local data = self:getData()

    local array = {}
    local reward = data:getDataByIndex(index)
    if reward then
        for i, v in ipairs(reward:getItems()) do
            local shopItemUI = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.REWARD)
            array[i] = shopItemUI
        end
    end
    return array
end

--判断本次spin是否可以显示tip
function Activity_MissionRushNewManager:canShowMissionRushTip()
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
        self:checkData()
        return true
    end
    self:checkData()
    return false
end

function Activity_MissionRushNewManager:lobbyOnEnter()
    if self:isRunning() then
        self._isFirstCheck = true
    end
end

function Activity_MissionRushNewManager:checkData()
    local curIndex = self:getData():getCurrMissionID()
    local localTipIndex = self:getData():getLocalTipIndex()

    curIndex = curIndex - 1

    if curIndex > localTipIndex then
        self._nextIndex = curIndex
        self._nextSpinOpen = true
    else
        self._nextSpinOpen = false
    end
end

function Activity_MissionRushNewManager:showMissionRushTip(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    local view = util_createView("Activity.Activity_MissionRushTip", _params)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self._nextSpinOpen = false
    self._isFirstCheck = false
    self:getData():setLocalTipIndex(self._nextIndex)
    return view
end

return Activity_MissionRushNewManager
