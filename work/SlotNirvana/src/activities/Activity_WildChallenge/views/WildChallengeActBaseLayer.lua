--[[
Author: cxc
Date: 2022-03-23 16:19:33
LastEditTime: 2022-03-23 16:19:34
LastEditors: cxc
Description: 3日行为付费聚合活动   base  弹板
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/WildChallengeActBaseLayer.lua
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local WildChallengeActBaseLayer = class("WildChallengeActBaseLayer", BaseActivityMainLayer)
local Config = require("activities.Activity_WildChallenge.config.WildChallengeConfig")

function WildChallengeActBaseLayer:ctor()
    WildChallengeActBaseLayer.super.ctor(self)

    self.m_codePathConfig = {}
    self.m_bGuide = G_GetMgr(ACTIVITY_REF.WildChallenge):checkGuide()
    self:setHideLobbyEnabled(true)
    self:setPauseSlotsEnabled(true)
    local csbName = self:getCsbName()
    self:setLandscapeCsbName(csbName)
    self:setExtendData("WildChallengeActMainLayer")
end

function WildChallengeActBaseLayer:getCsbName()
    return ""
end

function WildChallengeActBaseLayer:initCsbNodes()
    self.m_root = self:findChild("root")
    self.m_scrollView = self:findChild("ScrollView")
    self.m_nodeUI = self:findChild("node_ui")
    self.m_nodeNpc = self:findChild("node_npc")
end

function WildChallengeActBaseLayer:onShowedCallFunc()
    if self.m_bGuide then
        self:sclToCurTaskNode(true)
        G_GetMgr(ACTIVITY_REF.WildChallenge):saveGuideKey(G_GetMgr(ACTIVITY_REF.WildChallenge):getFormatTime())
    end

    -- 检查当前开启的任务是否自动领取 (1秒后再监测)
    performWithDelay(self, function()
        self.m_mainTaskUI:checkAutoCollect()
    end, 1)
end

function WildChallengeActBaseLayer:initView()
    WildChallengeActBaseLayer.super.initView(self)

    -- 初始化 滑动相关的内容
    self:initScrlUI()
    -- 初始化 非滑动相关的 UI
    self:initContentUI()

    -- 滑动档最新任务 位置
    if not self.m_bGuide then
        self:sclToCurTaskNode()
    end
end

function WildChallengeActBaseLayer:updateUI()
    -- 更新活动数据
    if self.m_mainTaskUI then
        self.m_mainTaskUI:updateUI()
    end
    -- 检查领奖
    performWithDelay(self, function()
        self.m_mainTaskUI:checkAutoCollect()
    end, 2)
end

-- 初始化 滑动相关的内容
function WildChallengeActBaseLayer:initScrlUI()
    self.m_scrollView:setContentSize(self.m_root:getContentSize())
    self.m_scrollView:setScrollBarEnabled(false)

    -- 添加背景
    self:createBgUI()
    -- 添加路面
    self:createTaskUI()
    -- 添加npc
    self:createNpc()

    -- 设置 滑动view  innerViewSize
    local innerSize = self.m_mainBgUI:getContentSize()
    self.m_scrollView:setInnerContainerSize(innerSize)
end

-- 添加背景
function WildChallengeActBaseLayer:createBgUI()
    local parent = self:findChild("node_Building")
    local codePath = self.m_codePathConfig.MAIN_UI_BG
    local view = util_createView(codePath)
    if not view then
        return
    end
    parent:addChild(view)
    self.m_mainBgUI = view
end

-- 添加路面 和 任务节点等
function WildChallengeActBaseLayer:createTaskUI()
    local parent = self:findChild("node_road")
    local codePath = self.m_codePathConfig.MAIN_UI_TASK
    local view = util_createView(codePath)
    if not view then
        return
    end
    parent:addChild(view)
    self.m_mainTaskUI = view
end

-- 在路面上移动的npc
function WildChallengeActBaseLayer:createNpc()
end

-- 初始化 非滑动相关的 UI
function WildChallengeActBaseLayer:initContentUI()
    -- mainUI
    local codePath = self.m_codePathConfig.MAIN_UI
    local view = util_createView(codePath)
    if not view then
        return
    end
    view:changeVisibleSize(self.m_root:getContentSize())
    self.m_nodeUI:addChild(view)
    self.m_mainUI = view
end

 -- 滑动档最新任务 位置
 function WildChallengeActBaseLayer:sclToCurTaskNode(_bMoveTo)
    local innerSize = self.m_mainBgUI:getContentSize()
    local posLX = self.m_mainTaskUI:getCurTaskPosLX() * self.m_root:getScale()
    
    local prog = math.max(posLX / innerSize.width, 0)
    self.m_newScrlProgV = math.min(prog * 100, 100)
    if _bMoveTo then
        self.m_scrollView:scrollToPercentHorizontal(self.m_newScrlProgV, 0.5, false)
    else
        self.m_scrollView:jumpToPercentHorizontal(self.m_newScrlProgV)
    end
 end

function WildChallengeActBaseLayer:closeUI(_cb)
    local bRunning = G_GetMgr(ACTIVITY_REF.WildChallenge):isRunning()
    if bRunning then
        local bCanAutoCollect = self.m_mainTaskUI:checkAutoCollect(true)
        if bCanAutoCollect then
            self.m_autoClose = true
            return
        end
    end

    local cb = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        if _cb then
            _cb()
        end
    end
    WildChallengeActBaseLayer.super.closeUI(self, cb)
end

-- 阶段任务领取成功
function WildChallengeActBaseLayer:collectSuccessEvt(_idx)
    if self.m_newScrlProgV then
        self.m_scrollView:jumpToPercentHorizontal(self.m_newScrlProgV)
    end
    self.m_bActing = true
    self:_addBlockMask()
    local actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getData()
    if not actData then
        self:closeUI()
        return
    end
    local phaseDataList = actData:getPhaseListData()
    if _idx == #phaseDataList then
        self:popRewardLayer(_idx, true)
        return
    end

    local cb = function()
        if tolua.isnull(self) then
            return
        end
        self:sclToCurTaskNode(true)
        performWithDelay(self, function()
            self:popRewardLayer(_idx)
        end, 1)
    end
    self.m_mainTaskUI:collectSuccessEvt(0, cb)
end

-- 弹 奖励弹板
function WildChallengeActBaseLayer:popRewardLayer(_idx, _bEnd)
    self:_removeBlockMask()
    if not _idx then
        local actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getData()
        local curOpenIdx = self.m_actData:getCurPhaseIdx()
        _idx = curOpenIdx - 1
    end

    local closeRewardCB = function()
        if tolua.isnull(self) then
            return
        end
        local actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getRunningData()
        if self.m_autoClose or not actData then
            self:closeUI()
            return
        end
        if _bEnd and actData then
            actData:updateCompleteSign() 
            return
        end
        self.m_mainTaskUI:updatePhaseNode(nil, true)
        self.m_mainTaskUI:checkAutoCollect()
    end
    local view = G_GetMgr(ACTIVITY_REF.WildChallenge):popRewardLayer(_idx, closeRewardCB)
    if view then
        self.m_bActing = false
        return
    end
    if self.m_autoClose then
        self:closeUI()
        return
    end
    self.m_mainTaskUI:updatePhaseNode(nil, true)
    self.m_mainTaskUI:checkAutoCollect()
    self.m_bActing = false
end

function WildChallengeActBaseLayer:actTimeEndEvt(_params)
    if _params and _params.name == ACTIVITY_REF.WildChallenge then
        local actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getRunningData()
        if actData then
            actData:setOpenFlag(false)
        end
        if not self.m_bActing then
            self:closeUI()
        end
    end
end

function WildChallengeActBaseLayer:registerListener()
    gLobalNoticManager:addObserver(self, "actTimeEndEvt", ViewEventType.NOTIFY_ACTIVITY_TIMEOUT) -- 活动到期
    gLobalNoticManager:addObserver(self, "actTimeEndEvt", ViewEventType.NOTIFY_ACTIVITY_COMPLETED) -- 活动完成
    gLobalNoticManager:addObserver(self, "collectSuccessEvt", Config.EVENT_NAME.WILD_CHALLENGE_COLLECT_SUCCESS) -- 任务领取成功
    gLobalNoticManager:addObserver(self, "closeUI", Config.EVENT_NAME.WILD_CHALLENGE_COLSE_MIAN_LAYER)
end

return WildChallengeActBaseLayer