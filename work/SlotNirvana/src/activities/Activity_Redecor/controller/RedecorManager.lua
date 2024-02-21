--[[
    装饰房子活动管理器
]]
-- key是主题名
local THEME_LOGIC = {
    ["Activity_Redecor"] = "activities.Activity_Redecor.config.RedecorThemeLogic"
}
local RedecorNet = require("activities.Activity_Redecor.net.RedecorNet")
local ActivityTaskManager = util_require("manager.ActivityTaskManager")
local RedecorManager = class(" RedecorManager", BaseActivityControl)

-- 构造函数
function RedecorManager:ctor()
    RedecorManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Redecor)
    self.m_redecorNet = RedecorNet:getInstance()
    self:initBase()
end

-- function RedecorManager:getInstance()
--     if RedecorManager.m_instance == nil then
--         RedecorManager.m_instance = RedecorManager.new()
--     end
--     return RedecorManager.m_instance
-- end

function RedecorManager:initBase()
    self.m_chapterRewardData = nil
    -- 登陆重置客户端缓存新手引导步骤
    self:resetStep()
end

function RedecorManager:setChapterRewardData(_rData)
    self.m_chapterRewardData = _rData
end

function RedecorManager:getChapterRewardData()
    return self.m_chapterRewardData
end

-- 每一期都会进行一次清理，
function RedecorManager:setCleanStatus(_isClean)
    self.m_cleanStatus = _isClean
end

function RedecorManager:getCleanStatus()
    return self.m_cleanStatus
end

-- function RedecorManager:getThemeName()
--     local name = nil
--     local data = self:getRunningData()
--     if data then
--         name = data:getThemeName()
--     end
--     if name == nil then
--         name = "Activity_Redecor"
--     end
--     return name
-- end

function RedecorManager:getThemeLogic()
    local themeName = self:getThemeName()
    local themeLogic = util_require(THEME_LOGIC[themeName])
    assert(themeLogic ~= nil, "!!! ERROR CONFIG, THEME_LOGIC not find themeName " .. themeName)
    return themeLogic:getInstance()
end

-- 资源是否已下载
-- function RedecorManager:isResDownLoadComplete()
--     local _key = self:getThemeName()
--     if globalDynamicDLControl:checkDownloading(_key) then
--         return false
--     else
--         return true
--     end
-- end

-- 轮盘转动请求
function RedecorManager:buildNode(_nodeId, _success, _failed)
    local function successCallFunc(resultData)
        self:getRunningData():parseWheelResultData(resultData)
        if _success then
            _success()
        end
    end

    local function failedCallFunc()
        if _failed then
            _failed()
        end
        gLobalViewManager:showReConnect()
    end
    self.m_redecorNet:requestBuildNode(_nodeId, successCallFunc, failedCallFunc)
end

-- 选择风格请求
function RedecorManager:selectStyle(_nodeId, _style, _success, _fail)
    local function successCallFun(resData)
        if _success then
            _success()
        end
    end

    local function failedCallFun()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end

    self.m_redecorNet:requestSelectStyle(_nodeId, _style, successCallFun, failedCallFun)
end

-- 请求:打开宝箱
function RedecorManager:requestOpenTreasure(_openType, _order, _success, _fail)
    local function successCallFun(resData)
        if _success then
            _success(resData)
        end
    end

    local function failedCallFun()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end

    self.m_redecorNet:requestOpenTreasure(_openType, _order, successCallFun, failedCallFun)
end

-- 请求:丢弃宝箱
function RedecorManager:passTreasure(_order, _success, _fail)
    local function successCallFun(resData)
        if _success then
            _success(resData)
        end
    end

    local function failedCallFun()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end

    self.m_redecorNet:requestPassTreasure(_order, successCallFun, failedCallFun)
end

-- 请求:打开fullview
function RedecorManager:openFullView(_success, _fail)
    local function successCallFun(resData)
        if resData ~= nil then
            -- 数据缓存
            local _views = resData.views
            if _views and next(_views) then
                local data = self:getRunningData()
                if data then
                    data:parseFullViewData(_views)
                    if _success then
                        _success()
                    end
                end
            else
                release_print("------------- REQUEST ERROR [MAQUN]: requestOpenFullView dont have result.views!!!")
            end
        else
            if _fail then
                _fail()
            end
            gLobalViewManager:showReConnect()
        end
    end

    local function failedCallFun()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end

    self.m_redecorNet:requestOpenFullView(successCallFun, failedCallFun)
end

-- 请求:fullview切换风格
function RedecorManager:fullViewSelectStyle(_activityName, _nodeId, _style, _success, _fail)
    local function successCallFun(resData)
        -- 解析数据客户端保存起来
        local data = self:getRunningData()
        if data then
            data:setFullViewNodeData(_activityName, _nodeId, _style)
            if _success then
                _success(resData)
            end
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end

    self.m_redecorNet:requestFullViewSelectStyle(_activityName, _nodeId, _style, successCallFun, failedCallFun)
end

--[[--
    entry_name:
        RedecorWheelSpinNode 点击轮盘spin，道具不足弹出
        ConfirmNode 装修操作时，道具不足弹出
        RedecorItemNode 道具入口
        RedecorPromotionNode 活动主界面入口
        RedecorEntryPromotionNode 关卡左边条入口
]]
-- function RedecorManager:showPromotionView(entry_name)
--     local data = G_GetActivityDataByRef(ACTIVITY_REF.Redecor)
--     if data == nil or data:isRunning() == false then
--         return
--     end

--     -- 促销数据尚未配置
--     local pData = G_GetActivityDataByRef(ACTIVITY_REF.RedecorSale)
--     if pData == nil or table.nums(pData) == 0 then
--         return
--     end

--     -- TODO:
--     if gLobalSendDataManager.getLogIap and gLobalSendDataManager:getLogIap().setEnterOpen then
--         gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", entry_name)
--     end

--     local extra_data = nil
--     if entry_name == "ConfirmNode" or entry_name == "RedecorItemNode" or entry_name == "InfoNode" then
--         extra_data = {isShowSpinNode = true}
--     end

--     local themeLogic = self:getThemeLogic()
--     local themeLuaCfg = themeLogic:getLuaCfg()
--     local uiView = util_createFindView(themeLuaCfg.promotionLayer, extra_data)
--     gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
-- end

function RedecorManager:showMainLayer(param, func)
    local ui = nil
    if not self:isCanShowLayer() then
        if func then
            func()
        end
        return
    end
    if gLobalViewManager:getViewByExtendData("RedecorMainUI") == nil then
        ui = util_createFindView("Activity/RedecorCode/RedecorMainUI", param)
        if ui ~= nil then
            self:showLayer(ui, ViewZorder.ZORDER_UI)
        end
    end
    if func then
        func()
    end

    return ui
end

function RedecorManager:showChooseStyleUI(_refName)
    if gLobalViewManager:getViewByExtendData("RedecorStyleMainUI") ~= nil then
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.selectStyleMainLayer, _refName)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_POPUI)
end

function RedecorManager:showRankFlyStarUI(_starNum)
    if gLobalViewManager:getViewByExtendData("RedecorRankStarFly") ~= nil then
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.mainRankStarFlyLayer, _starNum)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_POPUI)
end

function RedecorManager:showTreasureEffectFlyUI(_order, _isResumeCor)
    if gLobalViewManager:getViewByExtendData("RedecorTreasureFlyUI") ~= nil then
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.treasureEffectFlyLayer, _order, _isResumeCor)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_POPUI)
end

function RedecorManager:showTreasureInfoUI(_order, _isOpenNow, _isResumeCor, _isCheckTaskCompleted, _closeCallBack)
    if gLobalViewManager:getViewByExtendData("TreasureInfoUI") ~= nil then
        if _isResumeCor then
            gLobalNoticManager:postNotification(ViewEventType.REDECOR_RESUME_COR_CREATE_NODE)
        end
        if _closeCallBack then
            _closeCallBack()
        end
        release_print("--------------- [ERROR]MAQUN: TreasureInfoUI is not clear")
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.treasureInfoLayer, _order, _isOpenNow, _isResumeCor, _isCheckTaskCompleted, _closeCallBack)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_UI)
end

function RedecorManager:showTreasureRewardUI(_rewardData, _level, _isResumeCor, _isCheckTaskCompleted, _closeCallBack, _dropSource)
    if not (_rewardData and next(_rewardData) ~= nil and gLobalViewManager:getViewByExtendData("TreasureRewardUI") == nil) then
        if _isResumeCor then
            gLobalNoticManager:postNotification(ViewEventType.REDECOR_RESUME_COR_CREATE_NODE)
        end
        if _closeCallBack then
            _closeCallBack()
        end
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.treasureRewardLayer, _rewardData, _level, _isResumeCor, _isCheckTaskCompleted, _closeCallBack, _dropSource)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_UI)
end

function RedecorManager:showChapterRewardUI(_rewardData)
    if not (_rewardData and next(_rewardData) ~= nil) then
        return
    end
    if gLobalViewManager:getViewByExtendData("ChapterRewardUI") ~= nil then
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.chapterRewardLayer, _rewardData)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_UI)
end

function RedecorManager:showRoundRewardUI(_rewardData)
    if not (_rewardData and next(_rewardData) ~= nil) then
        return
    end
    if gLobalViewManager:getViewByExtendData("ChapterRewardUI") ~= nil then
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.roundRewardLayer, _rewardData)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_UI)
end

function RedecorManager:showRoundOverStreamerUI()
    if gLobalViewManager:getViewByExtendData("RoundOverStreamerUI") ~= nil then
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.roundOverStreamerLayer)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_UI)
end

function RedecorManager:showRoundOverCurtainUI(_round)
    if gLobalViewManager:getViewByExtendData("RoundOverCurtainUI") ~= nil then
        return
    end
    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local popUI = util_createView(themeLuaCfg.roundOverCurtainLayer, _round)
    gLobalViewManager:showUI(popUI, ViewZorder.ZORDER_UI)
end

-- 检查任务是否完成弹出任务面板
function RedecorManager:checkRedecorTaskCompleted()
    local bOpenTask = ActivityTaskManager:getInstance():checkTaskData(ACTIVITY_REF.RedecorTask)
    local bComplete = ActivityTaskManager:getInstance():checkTaskCompleted(ACTIVITY_REF.RedecorTask)
    if bOpenTask and bComplete then
        return true
    end
    return false
end

function RedecorManager:showRedecorTaskView(_isResumeCor)
    -- ActivityTaskManager:getInstance():openRedecorTaskView(_isResumeCor)
    self:getMgr(ACTIVITY_REF.RedecorTask):showMainLayer(_isResumeCor)
end

-- 主界面关闭按钮是否禁用
function RedecorManager:setRedecorMainExitDisabled(_Disabled)
    self.m_mainExitDisabled = _Disabled
end

function RedecorManager:getRedecorMainExitDisabled()
    return self.m_mainExitDisabled
end

-- spin按钮是否禁用
function RedecorManager:setWheelSpinDisabled(_Disabled)
    self.m_wheelSpinDisabled = _Disabled
end

function RedecorManager:getWheelSpinDisabled()
    return self.m_wheelSpinDisabled
end

function RedecorManager:getUserDefaultKey()
    return "RedecorManager" .. globalData.userRunData.uid
end

-- 每一期开始都要引导
function RedecorManager:getGuideKey()
    local data = self:getRunningData()
    if data then
        local id = data:getExpireAt()
        return "Redecor_Guide" .. id
    end
end

function RedecorManager:getWheelChangeGoldenKey()
    local data = self:getRunningData()
    if data then
        local id = data:getExpireAt()
        return "Redecor_wheel_change_golden_" .. id
    end
end

function RedecorManager:getCacheWheelChangeGolden()
    local key = self:getWheelChangeGoldenKey()
    if key ~= nil then
        return gLobalDataManager:getNumberByField(key, 0)
    end
end

function RedecorManager:setCacheWheelChangeGolden()
    local key = self:getWheelChangeGoldenKey()
    if key ~= nil then
        gLobalDataManager:setNumberByField(key, 1)
    end
end

function RedecorManager:getCacheStepId()
    local key = self:getGuideKey()
    if key ~= nil then
        return gLobalDataManager:getNumberByField(key, 0)
    end
end

function RedecorManager:setCacheStepId(_stepId)
    local key = self:getGuideKey()
    if key ~= nil then
        gLobalDataManager:setNumberByField(key, _stepId)
    end
end

function RedecorManager:resetStep()
    if not self:isRunning() then
        return
    end
    local newStepId = nil
    local curStepId = self:getCacheStepId()
    if curStepId == 2 then
        newStepId = 1
    elseif curStepId >= 3 and curStepId < 7 then
        newStepId = 7
    elseif curStepId == 8 then
        newStepId = 9
    end
    if newStepId then
        self:setCacheStepId(newStepId)
    end
end

function RedecorManager:setCacheWheelData(_wheels)
    self.m_cacheWheels = clone(_wheels)
end

function RedecorManager:getCacheWheelData()
    return self.m_cacheWheels
end

return RedecorManager
