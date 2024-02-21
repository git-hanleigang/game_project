local ChristmasMagicTourManager = class("ChristmasMagicTourManager")
local ShopItem = util_require("data.baseDatas.ShopItem")
ChristmasMagicTourManager._instance = nil
-- FIX IOS 139

function ChristmasMagicTourManager:getInstance()
    if ChristmasMagicTourManager.m_instance == nil then
        ChristmasMagicTourManager.m_instance = ChristmasMagicTourManager.new()
    end
    return ChristmasMagicTourManager.m_instance
end

function ChristmasMagicTourManager:ctor()
    self.m_configData = nil
    self.m_lightInfo = {}

    --
    self:registerObservers()
end

function ChristmasMagicTourManager:registerObservers()
    -- 监听零点刷新
    gLobalNoticManager:addObserver(
        self,
        function(sender)
            self:updateActivityData()
        end,
        ViewEventType.NOTIFY_CHRISTMASMT_ZERO_REFRESH
    )

    -- gLobalNoticManager:addObserver(self,
    -- function(sender)
    --     --

    -- end,ViewEventType.NOTIFY_CARD_SYS_OVER)
end

function ChristmasMagicTourManager:getActivityData()
    return clone(G_GetActivityDataByRef(ACTIVITY_REF.ChristmasMagicTour))
end

function ChristmasMagicTourManager:updateActivityData()
    local taskType = "Mission"
    self:sendRefreshReq(taskType, 0, true)
end

function ChristmasMagicTourManager:getIsOpen()
    local cmtData = self:getActivityData()

    if cmtData and cmtData:isRunning() and not globalDynamicDLControl:checkDownloading(ACTIVITY_REF.ChristmasMagicTour) then
        return true
    end

    return false
end

function ChristmasMagicTourManager:getIsMaxPoints()
    local cmtData = self:getActivityData()
    local currPoints = cmtData:getCurrentPoints()
    local maxPoints = cmtData:getMaxPoints()
    if currPoints >= maxPoints then
        return true
    end
    return false
end

function ChristmasMagicTourManager:getConfig()
    if not self.m_configData then
        self.m_configData = util_require("Activity/ChristmasMagicTourConfig")
    end
    return self.m_configData
end

function ChristmasMagicTourManager:getTaskDataByIndex(_index)
    local taskData = nil
    for k, v in pairs(self:getActivityData().m_taskData) do
        if v:getTaskSeqID() == _index then
            taskData = v
            break
        end
    end
    return taskData
end

function ChristmasMagicTourManager:getRewardDataByIndex(_index)
    return self:getActivityData():getRewardData()[_index]
end

-- 获取所有的灯信息
function ChristmasMagicTourManager:getLightInfo(_scenePos)
    if not self.m_lightInfo[_scenePos] then
        self.m_lightInfo[_scenePos] = {}
        local config = self:getConfig()
        local lightConfig = config.LIGHTPOS_CONFIG
        if self:getActivityData():getPhase() == 2 then
            lightConfig = config.LIGHTPOS_CONFIG_STEP2
        end
        local resConfig = config.RESPATH
        for i = 1, #lightConfig do
            local info = lightConfig[i]
            local data = {
                pos = info[_scenePos],
                resPath = info.big and resConfig.BIG_LIGHT_PATH or resConfig.SAMLL_LIGHT_PATH,
                big = info.big,
                actName = info.actName
            }
            table.insert(self.m_lightInfo[_scenePos], data)
        end
    end
    return self.m_lightInfo[_scenePos]
end

function ChristmasMagicTourManager:refreshLightInfo()
    self.m_lightInfo = {}
end

function ChristmasMagicTourManager:getIsRewardPhase()
    if self:getActivityData():getPhase() == 2 then
        local rewardData = self:getRewardDataByIndex(1) -- 第二阶段只有一个奖励
        if rewardData then
            if rewardData:getCollected() == false then -- 如果当前没有领取 返回可以领取
                return true
            end
        end
    end
    return false
end

-- 当前阶段一的奖励是否全都领取完毕
function ChristmasMagicTourManager:getRewradAllCollected()
    local cmtData = self:getActivityData()
    local bAllCollect = true
    if cmtData then
        for i = 1, #cmtData:getRewardData() do
            local rewardData = cmtData:getRewardData()[i]
            if rewardData:getCollected() == false then --  只有有奖励没有领取,都返回 false
                bAllCollect = false
                break
            end
        end
    end
    return bAllCollect
end

function ChristmasMagicTourManager:getFinishAll()
    local cmtData = self:getActivityData()
    if cmtData then
        return cmtData:getFinishAll()
    end
    return false
end

function ChristmasMagicTourManager:getHasTaskCompleted()
    --判断当前是否有任务完成
    local bHas = false
    if self:getIsOpen() == false then
        return false
    end
    if self:getActivityData():getPhase() == 2 then -- 当前如果是阶段2的情况下,不打开
        return false
    end
    if self:getRewradAllCollected() == false then -- 如果当前有奖励没有收集 还是可以打开的
        bHas = true
    end
    for k, taskData in pairs(self:getActivityData().m_taskData) do
        if taskData then
            if taskData:getStatus() == "completed" then
                -- 弹出主界面
                bHas = true
                break
            end
        end
    end
    return bHas
end

function ChristmasMagicTourManager:getCompletedGuide()
    return gLobalDataManager:getBoolByField("ChristmasMagicTour_showguide", false)
end

-- 专门为每日任务关闭收集之后做的接口
function ChristmasMagicTourManager:dailyTaskCollectOver()
    if self:getHasTaskCompleted() then
        local ctsView = util_createFindView("Activity/ChristmasMagicTourMainLayer")
        ctsView:setOverFunc(
            function()
                -- 后续行为
                gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_ANIMATION_TIPS)
            end
        )
        gLobalViewManager:showUI(ctsView, ViewZorder.ZORDER_UI)
    else
        -- 后续行为
        gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_ANIMATION_TIPS)
    end
end

--[[
    服务器接口
]]
function ChristmasMagicTourManager:sendRefreshReq(_taskType, _actionType, _bZeroRefresh)
    local successCallFun = function()
        if _bZeroRefresh then
            -- 判断当前是否进入阶段二
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMASMT_ZERO_REFRESH_SUCCESS)
        else
            -- 正常领取 刷新task
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMASMT_REFRESH_SUCCESS)
        end
    end

    local failedCallFunFail = function()
        -- 什么都用做
    end
    -- actionType 0 零点刷新 1 非零点刷新
    local params = {}
    params.taskType = _taskType
    params.actionType = _actionType
    gLobalSendDataManager:getNetWorkFeature():sendChristmasMagicTourReq(ActionType.HolidayChallengeRefresh, params, successCallFun, failedCallFunFail)
end

function ChristmasMagicTourManager:sendCollectReq(_phase, _points)
    local successCallFun = function(resultData)
        local rewardItems = nil
        if resultData:HasField("result") == true then
            rewardItems = util_cjsonDecode(resultData.result)
        end

        if rewardItems.items ~= nil then
            local itemData = {}
            for i = 1, #rewardItems.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(rewardItems.items[i], true)
                itemData[i] = shopItem
            end
            rewardItems.items = itemData
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMASMT_COLLECT_REWARD, {isSuccess = true, rewardItems = rewardItems})
    end

    local failedCallFunFail = function(errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMASMT_COLLECT_REWARD, {isSuccess = false})
    end

    local params = {}
    params.phase = _phase
    params.points = _points
    gLobalSendDataManager:getNetWorkFeature():sendChristmasMagicTourReq(ActionType.HolidayChallengeCollect, params, successCallFun, failedCallFunFail)
end

return ChristmasMagicTourManager
