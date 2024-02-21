--[[
    集卡赛季末聚合
]]

-- 加载配置文件
require("activities.Activity_ChaseForChips.config.ChaseForChipsCfg")

local ChaseForChipsMgr = class("ChaseForChipsMgr", BaseActivityControl)
function ChaseForChipsMgr:ctor()
    ChaseForChipsMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChaseForChips)

    -- SPIN后数据解析
    -- 关卡spin消息回调
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            if param[1] == true then
                local spinData = param[2]
                if spinData and spinData.action == "SPIN" and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                    if spinData.extend and spinData.extend.chaseForChips ~= nil and globalData.slotRunData.machineData ~= nil then
                        -- 原来是完成任务弹，现在改成完成一个收集再弹 2024-01-10-zzy
                        if spinData.extend.chaseForChips.finishTask == 1 then
                            self:setNewFinishTaskBySpin(true)
                            if spinData.extend.chaseForChips.finishCollect == 1 then
                                self:setNewFinishCollectCollectBySpin(true)
                            end
                        else -- 应该不会出现完成收集但没有完成任务的情况，以防万一
                            if spinData.extend.chaseForChips.finishCollect == 1 then
                                self:setNewFinishCollectCollectBySpin(true)
                            end
                        end
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    self.m_isNewFinishTaskBySpin = false
    self.m_isNewFinishCollectBySpin = false
end

-- 关卡内入口名
function ChaseForChipsMgr:getEntryName()
    return self:getThemeName()
end

function ChaseForChipsMgr:setNewFinishTaskBySpin(_isNew)
    self.m_isNewFinishTaskBySpin = _isNew
end

function ChaseForChipsMgr:isNewFinishTaskBySpin()
    return self.m_isNewFinishTaskBySpin == true
end

function ChaseForChipsMgr:setNewFinishCollectCollectBySpin(_isNew)
    self.m_isNewFinishCollectBySpin = _isNew
end

function ChaseForChipsMgr:isNewFinishCollectCollectBySpin()
    return self.m_isNewFinishCollectBySpin == true
end
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
function ChaseForChipsMgr:enterChaseFroChips(_over, _openType)
    local themeName  = self:getThemeName()
    -- ChaseForChipsCfg.setPath(themeName)

    -- 回调
    self:setChaseForChipsOverCall(_over)

    -- 因为任务都是集卡相关的，需要手动拉取数据
    -- 打开界面需要拉最新的数据
    self:requestInfo(
        function()
            local news = self:getNewFinishTaskIds()
            if not (news and #news > 0) then
                self:syncCacheData()
            end
            local view = self:openChaseForChips(_openType)
            if not view then
                self:exitChaseFroChips()
            end
        end,
        function()
            self:exitChaseFroChips()
        end
    )
    
end

function ChaseForChipsMgr:openChaseForChips(_openType)
    local themeName  = self:getThemeName()
    -- ChaseForChipsCfg.setPath(themeName)
    -- 如果没有特定打开哪个界面
    -- 默认打开主界面， 如果有新完成的任务打开任务
    if _openType == nil then
        _openType = 1
        -- 检测 新完成的任务
        local news = self:getNewFinishTaskIds()
        if news and #news > 0 then
            _openType = 2
        end
    end

    -- 如果pass的进度，之前就满了，不打开任务界面
    local preData = self:getCacheData()
    if preData and preData:isMax() then
        _openType = 1
    end

    local view = nil
    if _openType == 1 then
        view = self:showMainLayer()
    elseif _openType == 2 then
        -- 不展示任务界面，直接弹主界面
        -- view = self:showMissionLayer()
        view = self:showMainLayer(true)
    elseif _openType == 3 then
        -- 点击关卡入口正常弹出任务界面
        view = self:showMissionLayer()
    end
    return view    
end

function ChaseForChipsMgr:exitChaseFroChips()
    -- self:clearAutoIncrease()
    self:removeLogicMask()
    self:doChaseForChipsOverCall()
end

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

function ChaseForChipsMgr:setChaseForChipsOverCall(_over)
    self.m_chaseForChipsOverCall = _over 
end
function ChaseForChipsMgr:doChaseForChipsOverCall()
    if self.m_chaseForChipsOverCall then
        self.m_chaseForChipsOverCall()
        self.m_chaseForChipsOverCall = nil
    end
end
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
function ChaseForChipsMgr:getCacheData()
    local data = self:getRunningData()
    if data then
        return data:getCacheData()
    end
    return
end

function ChaseForChipsMgr:syncCacheData()
    local data = self:getRunningData()
    if data then
        data:syncCacheData()
    end
end
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- 获取新完成的任务列表
function ChaseForChipsMgr:getNewFinishTaskIds()
    local themeName  = self:getThemeName()
    -- ChaseForChipsCfg.setPath(themeName)

    -- 上次缓存数据
    local cacheData = self:getCacheData() 
    -- 当前最新数据
    local newestData = self:getRunningData() 

    local newFinishTasks = {}

    if not (cacheData and newestData) then
        return newFinishTasks
    end
    -- -- 主界面已经满了，即使有新完成的任务，也不弹出了
    -- if cacheData:isMax() then
    --     return newFinishTasks
    -- end

    local cacheTaskData = cacheData:getTasks()
    local newestTaskData = newestData:getTasks()
    if (cacheTaskData and #cacheTaskData > 0) and (newestTaskData and #newestTaskData > 0) then
        local num = #newestTaskData
        for i = 1, num do
            local taskData1 = cacheTaskData[i]
            local taskData2 = newestTaskData[i]
            local finishTimes1 = taskData1:getFinishTimes()
            local finishTimes2 = taskData2:getFinishTimes()     
            if finishTimes2 - finishTimes1 > 0 then
                table.insert(newFinishTasks, i)
            end
        end
    end
    dump(newFinishTasks, "====newFinishTasks====", 2)
    return newFinishTasks
end

function ChaseForChipsMgr:getIncreaseTasks()
    -- 上次缓存数据
    local cacheData = self:getCacheData() 
    -- 当前最新数据
    local newestData = self:getRunningData() 

    local increaseTasks = {}

    if not (cacheData and newestData) then
        return increaseTasks
    end
    -- -- 主界面已经满了，即使有新完成的任务，也不弹出了
    -- if cacheData:isMax() then
    --     return increaseTasks
    -- end

    local cacheTaskData = cacheData:getTasks()
    local newestTaskData = newestData:getTasks()
    if (cacheTaskData and #cacheTaskData > 0) and (newestTaskData and #newestTaskData > 0) then
        local num = #newestTaskData
        for i = 1, num do
            local taskData1 = cacheTaskData[i]
            local taskData2 = newestTaskData[i]
            local rewardPoints = taskData1:getRewardPoints()
            local finishTimes1 = taskData1:getFinishTimes()
            local finishTimes2 = taskData2:getFinishTimes()
            local addTimes = finishTimes2 - finishTimes1            
            local increaseList = self:getTaskIncreaseList(taskData1, taskData2)
            if increaseList and #increaseList > 0 then
                table.insert(increaseTasks, 
                    {
                        index = i, 
                        times = addTimes, 
                        points = rewardPoints*addTimes, 
                        increase = increaseList
                    }
                )
            end
        end
    end
    dump(increaseTasks, "====increaseTasks====", 2)
    return increaseTasks    
end

function ChaseForChipsMgr:getTaskIncreaseList(_pre, _now)
    local preCur = _pre:getCurPro()
    local nowCur = _now:getCurPro()
    
    local preTimes = _pre:getFinishTimes()
    local nowTimes = _now:getFinishTimes()

    local nowMaxTimes = _now:getTotalTimes()

    -- 当前进度条涨到满算一条数据，多余的再另算一条数据
    local _increase = {}
    local add = nowTimes - preTimes
    if add > 0 then
        -- 从当前进度涨满
        local _max = _pre:getDiffGoalByIndex(preTimes + 1)
        table.insert(_increase, {cur = preCur, tar = _max, max = _max})
        -- 从0涨满
        if add > 1 then
            for j = 1, add-1 do
                local _max1 = _pre:getDiffGoalByIndex(preTimes + 1 + j)
                table.insert(_increase, {cur = 0, tar = _max1, max = _max1})
            end
        end
        -- 从0涨到最新进度
        if nowCur > 0 then
            if nowTimes < nowMaxTimes then
                local _max2 = _now:getDiffGoalByIndex(nowTimes + 1)
                table.insert(_increase, {cur = 0, tar = nowCur, max = _max2})
            elseif nowTimes == nowMaxTimes then
                -- 达到最大次数后，满了就不涨了
            end
        end
    elseif add == 0 then
        if nowCur > preCur then
            if nowTimes < nowMaxTimes then
                local _max = _pre:getDiffGoalByIndex(preTimes + 1)
                table.insert(_increase, {cur = preCur, tar = nowCur, max = _max})
            else
                -- 达到最大次数后，即使涨，也不表现
            end
        end
    end
    -- dump(_increase, "====_increase====", 3)
    return _increase
end
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- -- 子类重写
-- -- 关卡内入口
-- function ChaseForChipsMgr:getEntryModule()
--     local data = self:getRunningData()
--     if data and data:isMax() then
--         return ""
--     end
--     return ChaseForChipsMgr.super.getEntryModule(self)
-- end

function ChaseForChipsMgr:showPopLayer(_params, _over)
    if _params and _params.clickFlag == true then
        -- 主动点击大厅轮播广告
        self:enterChaseFroChips(_over)
    else
        local themeName  = self:getThemeName()
        -- ChaseForChipsCfg.setPath(themeName)
        -- 弹版自动弹出
        self:setChaseForChipsOverCall(function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end)
        local view = self:openChaseForChips(_openType)
        if not view then
            self:exitChaseFroChips()
            return
        end
        return view
    end
end

function ChaseForChipsMgr:showMainLayer(_isCheckAutoIncrease)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("Activity_ChaseForChips") ~= nil then
        return
    end
    
    local themeName = self:getThemeName() or "Activity_ChaseForChips"
    local view = util_createView("Activity." .. themeName, _isCheckAutoIncrease)
    view:setName("Activity_ChaseForChips")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function ChaseForChipsMgr:showMissionLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("CFCTaskMainLayer") ~= nil then
        return
    end
    local view = util_createView(ChaseForChipsCfg.luaPath .. "taskUI.CFCTaskMainLayer")
    view:setName("CFCTaskMainLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function ChaseForChipsMgr:showRewardLayer(_over)
    local function callFunc()
        if _over then
            _over()
        end
    end

    if self:getLayerByName("CFCRewardLayer") ~= nil then
        callFunc()
        return
    end
    --奖励界面
    local itemDataList = {}
    local rewardData = self:getRewardData()
    local coins = rewardData:getCoins()
    local items = rewardData:getItems()
    if coins and coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        table.insert(itemDataList, itemData)
    end
    if items and #items > 0 then
        local items = rewardData:getItems()
        for i,v in ipairs(items) do
            table.insert(itemDataList, items[i])
            -- 刷新高倍场
            if v.p_icon then
                if string.find(v.p_icon, "Pouch") then
                    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                    mergeManager:refreshBagsNum(v.p_icon, v.p_num)
                end
            end
        end
    end
    if not (itemDataList and #itemDataList > 0) then
        callFunc()
        return 
    end
    local function overCallFunc()
        if CardSysManager:needDropCards("Chase For Chips") == true then
            CardSysManager:doDropCards("Chase For Chips",
                function()
                    callFunc()
                end
            )
        else
            callFunc()
        end
    end
    local view = gLobalItemManager:createRewardLayer(itemDataList, overCallFunc, coins)
    if not view then
        overCallFunc()
        return
    end
    view:setName("CFCRewardLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- function ChaseForChipsMgr:showPointsLayer(_over, _points)
--     if self:getLayerByName("CFCPointsLayer") ~= nil then
--         if _over then
--             _over()
--         end
--         return
--     end
--     local view = util_createView(ChaseForChipsCfg.luaPath .. "mainUI.CFCPointsLayer", _over, _points)
--     view:setName("CFCPointsLayer")
--     self:showLayer(view, ViewZorder.ZORDER_UI)
--     return view    
-- end

function ChaseForChipsMgr:requestInfo(_success, _fail)
    local function successFunc(_result)
        local data = self:getRunningData()
        if data then
            if _success then
                _success()
            end
        end
    end
    local function failureFunc()
        if _fail then
            _fail()
        end
        -- gLobalViewManager:showReConnect()
    end
    G_GetNetModel(NetType.ChaseForChips):requestInfo(successFunc, failureFunc)
end

function ChaseForChipsMgr:requestCollectReward(_index, _isFree, _success, _fail)
    local function successFunc(_result)
        local data = self:getRunningData()
        if data then
            self:recordRewardData(_result)
            gLobalNoticManager:postNotification(ViewEventType.CHASE_FOR_CHIPS_COLLECT_PASS_SUCCESS, {index = _index})
            -- 同步数据
            self:syncCacheData()
            if _success then
                _success()
            end
        end
    end
    local function failureFunc()
        if _fail then
            _fail()
        end        
        gLobalViewManager:showReConnect()
    end
    G_GetNetModel(NetType.ChaseForChips):requestCollectReward(_index, _isFree, successFunc, failureFunc)
end

function ChaseForChipsMgr:recordRewardData(_rewardData)
    local ChasePassRewardData = util_require("activities.Activity_ChaseForChips.model.ChasePassRewardData")
    self.m_rewardData = ChasePassRewardData:create()
    self.m_rewardData:parseData(_rewardData)
end

function ChaseForChipsMgr:getRewardData()
    return self.m_rewardData
end

-- 逻辑遮罩层
function ChaseForChipsMgr:addLogicMask()
    local logicMask = util_newMaskLayer(false)
    logicMask:setOpacity(0)
    logicMask:setName("ObsidianLogicMask")
    self:showLayer(logicMask, ViewZorder.ZORDER_UI)
end

function ChaseForChipsMgr:removeLogicMask()
    local mask = self:getLayerByName("ObsidianLogicMask")
    if not tolua.isnull(mask) then
        mask:removeFromParent()
        mask = nil
    end
end


return ChaseForChipsMgr
