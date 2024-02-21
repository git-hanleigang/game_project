--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-07 16:07:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-07 16:07:41
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandMainUI.lua
Description: 扩圈系统大厅 主UI
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local NewUserExpandMainUI = class("NewUserExpandMainUI", BaseView)

function NewUserExpandMainUI:initDatas()
    NewUserExpandMainUI.super.initDatas(self)

    self.m_chooseType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    self.m_expandData = G_GetMgr(G_REF.NewUserExpand):getData()
    self.m_gameData = self.m_expandData:getGameData()
end

function NewUserExpandMainUI:getCsbName()
    return "NewUser_Expend/Activity/csd/NewUser_MainUI.csb"
end

-- 初始化节点
function NewUserExpandMainUI:initCsbNodes()
    local root = self:findChild("root")
    root:setContentSize(display.size)
    ccui.Helper:doLayout(root)

    -- 滑动层
    self.m_scrollView = self:findChild("ScrollView")
    self.m_scrollView:setScrollBarEnabled(false)
    self.m_scrollView:addEventListener(handler(self, self.udpateScrollEvt))
end

function NewUserExpandMainUI:initUI()
    NewUserExpandMainUI.super.initUI(self)

    -- 初始化地图
    self:initMapUI()
end

function NewUserExpandMainUI:onEnter()
    performWithDelay(self, function()
        self.m_maskLayer = util_newMaskLayer()
        self.m_maskLayer:setOpacity(0)
        gLobalViewManager:showUI(self.m_maskLayer, ViewZorder.ZORDER_LOADING)
    end, 0)

    NewUserExpandMainUI.super.onEnter(self)
    
    self:registerListener()
    -- 滑动地图到 最新章节位置
    self:scrollToCurChapterPos()
    performWithDelay(self, util_node_handler(self, self.onEnterLast), 0.2)
end

function NewUserExpandMainUI:onEnterLast()
    if not tolua.isnull(self.m_maskLayer) then
        self.m_maskLayer:removeSelf()
        self.m_maskLayer = nil
    end

    self:udpateScrollEvt()

    -- 记录地图上 任务View
    self.m_mapUI:recordTaskView()
    self:onCheckUpdateTaskDataEvt()

    -- 引导
    self:dealGuideLogic()

    if G_GetMgr(G_REF.NewUserExpand):checkIsClientActiveType() then
        self.m_mapUI:dealGuideLogic()
    end
end

function NewUserExpandMainUI:initMapUI()
    local view = util_createView("GameModule.NewUserExpand.views.NewUserExpandMapUI", self.m_gameData, self)
    local parent = self:findChild("node_map")
    parent:addChild(view)
    self.m_mapUI = view
    local viewSize = view:getContentSize()
    self.m_scrollView:setInnerContainerSize(cc.size(viewSize.width, viewSize.height))
end

-- 滑动地图到 最新章节位置
function NewUserExpandMainUI:scrollToCurChapterPos(_bScroll, _bMissionCenter)
    local missionTaskData = self.m_gameData:getHadDoneMissionTaskData()
    if not missionTaskData then
        return
    end

    local curIdx = missionTaskData:getCurTypeIdx()
    if not curIdx then
        return
    end

    local scrollViewSize = self.m_scrollView:getContentSize()
    local innerNodeSize = self.m_scrollView:getInnerContainerSize()
    local subWidth = innerNodeSize.width - scrollViewSize.width
    local correctNodePosX = self.m_mapUI:getLockNodePosXByIdx(curIdx)
    if not correctNodePosX then
        return
    end 
    local percent = (correctNodePosX - 200) / subWidth
    if _bMissionCenter then
        percent = (correctNodePosX - display.width*0.5) / subWidth
    end
    percent = math.min(percent, 1) 
    if _bScroll then
        self.m_scrollView:scrollToPercentHorizontal(percent * 100, 0.5, false)
    else
        self.m_scrollView:jumpToPercentHorizontal(percent * 100)
    end
end

-- 完成关卡 小游戏返回大厅
function NewUserExpandMainUI:onCompleteMiniGameEvt()
    if not self:onCheckUpdateTaskDataEvt() then
        return
    end

    self.m_mapUI:onCompleteMiniGameEvt()
end

-- 更新 扩圈任务
function NewUserExpandMainUI:onCheckUpdateTaskDataEvt()
    local curTaskData = self.m_gameData:getCurTaskData()
    if not curTaskData then
        return
    end

    local status = curTaskData:getStatus()
    if status ~= 2 then
        return
    end

    G_GetMgr(G_REF.NewUserExpand):sendActiveExpandNewTaskReq()
    return true
end

function NewUserExpandMainUI:udpateScrollEvt()
    self.m_mapUI:udpateScrollEvt()
end

function NewUserExpandMainUI:onUpdateTaskStateEvt()
    self.m_mapUI:onUpdateTaskStateEvt()

    if not self:onCheckUpdateTaskDataEvt() then
        return
    end

    --开完所有任务 移动到最新章节
    local curTaskData = self.m_gameData:getCurTaskData()
    if not curTaskData then
        return
    end

    local bMission = curTaskData:checkIsMission()
    if bMission then
        self:scrollToCurChapterPos(false, true)
        performWithDelay(self, function()
            self:scrollToCurChapterPos(true)
        end, 0.3)
    end
end

-- 旋转横竖屏 后在检测下map
function NewUserExpandMainUI:onResetScreenEvt()
    self.m_mapUI:udpateScrollEvt()
end

-- 引导完成后 设置任务view 不吞噬事件
function NewUserExpandMainUI:onResetMapGuieViewSwallowEvt()
    self.m_mapUI:setGuideTaskViewSwallow(false) 
end

function NewUserExpandMainUI:registerListener()
    gLobalNoticManager:addObserver(self, "onCheckUpdateTaskDataEvt", NewUserExpandConfig.EVENT_NAME.NOTIFY_CHECK_REFRESH_TASK_STATE)
    gLobalNoticManager:addObserver(self, "onCompleteMiniGameEvt", NewUserExpandConfig.EVENT_NAME.COMPLETE_MINI_GAME_BACK_EXPAND_UI)
    gLobalNoticManager:addObserver(self, "onUpdateTaskStateEvt", NewUserExpandConfig.EVENT_NAME.ACTIVE_EXPAND_NEW_TASK_SUCCESS)
    gLobalNoticManager:addObserver(self, "onResetMapGuieViewSwallowEvt", NewUserExpandConfig.EVENT_NAME.NOTIFY_RESET_GUIDE_TASK_VIEW_SWALLOW)
    gLobalNoticManager:addObserver(self, "onResetScreenEvt", ViewEventType.NOTIFY_RESET_SCREEN)
end

-- 引导
function NewUserExpandMainUI:dealGuideLogic()
    -- if not G_GetMgr(G_REF.NewUserExpand):checkIsServerActiveType() then
    --     return
    -- end
    local curType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    if curType ~= NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
        return
    end

    local curTaskData = self.m_gameData:getCurTaskData()
    if not curTaskData then
        return
    end

    if curTaskData:getSeq() == 1 and curTaskData:getState() == NewUserExpandConfig.TASK_STATE.UNLOCK then
        -- 引导 1 直接进入第一关玩游戏
        local hasGuide = G_GetMgr(G_REF.NewUserExpand):getGuide():triggerGuide(self, "EnterExpandMainFirst", G_REF.NewUserExpand)
        if not hasGuide then
            return
        end

        G_GetMgr(G_REF.NewUserExpand):getGuide():triggerGuide(self, "EnterExpandMainFirst", G_REF.NewUserExpand)
        G_GetMgr(G_REF.NewUserExpand):getGuide():doNextGuideStep("EnterExpandMainFirst")
        G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandGuideLog("EnterExpandMainFirst")
        G_GetMgr(G_REF.NewUserExpand):gotoPlayGame()
    end
end

function NewUserExpandMainUI:jumpToLeft()
    self.m_scrollView:jumpToLeft()
end

return NewUserExpandMainUI