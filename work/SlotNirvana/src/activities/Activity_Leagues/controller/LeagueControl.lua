--[[
    联赛控制层
    author:徐袁
    time:2020-12-24 16:37:27
]]
local LeagueNetModel = util_require("activities.Activity_Leagues.net.LeagueNetModel")
local LeagueCommonCtrl = util_require("activities.Activity_Leagues.controller.LeagueCommonCtrl")
local LeagueControl = class("LeagueControl", LeagueCommonCtrl)

function LeagueControl:ctor()
    LeagueControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.League)
    self.m_typeStr = "Normal"
    self.m_netModel = LeagueNetModel:getInstance() 
end

-- 领取排行奖励完成
function LeagueControl:collectRankRewardCompleted()
    -- 领取完成关闭界面
    local uiView = gLobalViewManager:getViewByName("League_MainLayer")
    if uiView then
        local callFunc = function()
            G_GetMgr(G_REF.LeagueCtrl):clearOpenActInfo()
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
        uiView:closeUI(callFunc)
    end

    local activityData = self:getData()
    if activityData then
        activityData:setCanCollect(false)
    end

    self.m_oldData = nil
end

-- 显示赛季结束界面
function LeagueControl:onShowFinalLayer()
    if not self:isDownloadRes() then
        return false
    end

    local leagueData = self:getData()
    if not leagueData then
        return false
    end

    if not leagueData:isCanCollect() then
        return false
    end

    local finalLayer = util_createView("Activity.Normal.League_FinalLayer")
    finalLayer:setName("League_FinalLayer")
    self:showLayer(finalLayer, ViewZorder.ZORDER_POPUI)

    return true
end

-- 显示当前段位界面
function LeagueControl:onShowDivisionLayer()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_RANK_SHOW, {status = false})
    local diviView = util_createView("Activity.Common.DivisionLayer.League_ShowDivisionLayer")
    diviView:updateView(self.m_oldData)
    self:showLayer(diviView, ViewZorder.ZORDER_POPUI)
end

-- 检查第一次升级
function LeagueControl:checkToDayFirstLevelUp()
    local isShow = false
    local unLockLevel = globalData.constantData.LEAGUE_OPEN_LEVEL or 35
    local curLevel = globalData.userRunData.levelNum or 1

    if curLevel < unLockLevel or curLevel > (unLockLevel + 5) then
        -- 只有等于解锁等级才弹
        return isShow
    end

    local leagueFristIsLevelUp = gLobalDataManager:getBoolByField("LeagueFristIsLevelUp", false)
    if leagueFristIsLevelUp then
        isShow = false
    else
        isShow = true
    end
    return isShow
end

-- 显示开启活动界面
function LeagueControl:onShowOpenLayer()
    if not self:isCanShowLayer() then
        return false
    end

    if not self:checkToDayFirstLevelUp() then
        return false
    end

    local leagueData = self:getData()
    leagueData:setWinCupInfo(nil) -- 第一次开启不飞点数奖杯 重置了
    gLobalDataManager:setBoolByField("LeagueFristIsLevelUp", true)
    local openView = util_createView("Activity.Normal.League_OpenLayer")
    self:showLayer(openView, ViewZorder.ZORDER_UI)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_ENTRY_UPDATE)
    return true
end

-- 关卡内入口
function LeagueControl:getMachineEntryModule()
    local module = LeagueControl.super.getMachineEntryModule(self)
    if not module then
        return
    end 

    local data = self:getRunningData()
    local bOpen = data:isOpenRank()
    if not bOpen and self:checkToDayFirstLevelUp() then
        module = nil
    end

    return module
end

------------------------------- 引导 -------------------------------
-- 开启引导
function LeagueControl:openGuide()
    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    if activityData:isCanCollect() then
        -- 有奖励领取，直接跳过引导
        local _maxStep = activityData:getMaxGuideStep()
        activityData:setGuideStep(_maxStep)
    end

    if activityData:isGuideCompleted() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_GUIDE_OVER)
        return
    end

    self:nextGuide()
end

-- 下一个引导
function LeagueControl:nextGuide()
    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    local _delay = 0.01
    local _step = activityData:getGuideStep()
    if not activityData:isOpenRank() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_GUIDE_OVER)
        return
    end

    if _step <= 1 then
        -- 上榜
        _delay = 5
    elseif _step <= 2 then
        -- 滑动到榜顶
        _delay = 5
    elseif _step <= 3 then
        -- 展示奖励
        _delay = 5
    elseif _step <= 4 then
        -- 展示段位
        _delay = 5
    elseif _step <= 5 then
        -- 段位置顶
        _delay = 5
    end
    -- end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_GUIDE_STEP, {step = _step, delay = _delay})
end

local guideStep = {
    [1] = {nextStep = 2},
    [2] = {nextStep = 4},
    [3] = {nextStep = 4},
    [4] = {nextStep = 5},
    [5] = {nextStep = 6}
}

-- 获取引导下一步
function LeagueControl:getNextStep(step)
    local stepInfo = guideStep[step]
    if stepInfo then
        return stepInfo.nextStep
    else
        return 1
    end
end

-- 转到下一引导
function LeagueControl:turnNextStepGuide()
    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    -- local _step = activityData:getGuideStep() + 1
    local _step = self:getNextStep(activityData:getGuideStep())

    activityData:setGuideStep(_step)

    if activityData:isGuideCompleted() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_GUIDE_OVER)
    else
        self:nextGuide()
    end
end
------------------------------- 引导 -------------------------------

return LeagueControl
