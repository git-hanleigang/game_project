--[[
    --新版每日任务pass主界面
    csc 2021-06-21
]]
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionMainLayer = class("DailyMissionMainLayer", BaseLayer)

local PAGE_TYPE = {
    MISSION_PAGE = 1,
    REWARD_PAGE = 2,
    FLOWER_PAGE = 3
}

function DailyMissionMainLayer:ctor()
    DailyMissionMainLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_MainLayer.csb")
    self:setPortraitCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_MainLayer_Vertical.csb")

    self:setPauseSlotsEnabled(true)
    self:setHideLobbyEnabled(true)
    self:setKeyBackEnabled(true)
    self:setBgm(DAILYPASS_RES_PATH.PASS_MISSION_BGM_MP3)
    -- 定义变量
    self.m_currPageType = nil
    self.m_inAction = false
    self.m_completeCreatePassTableView = true
end

function DailyMissionMainLayer:initUI(_autoOpen, _isNewUser)
    self.m_isNewUser = _isNewUser
    self.m_bAutoCollect = _autoOpen
    self.m_bAutoCollectGuideFlag = _autoOpen
    self.m_bIsPushingView = gLobalPushViewControl:isPushingView()
    DailyMissionMainLayer.super.initUI(self)
end

function DailyMissionMainLayer:initCsbNodes()
    -- 按钮部分
    self.m_btnClose = self:findChild("btn_close")

    -- 显示page ui
    self.m_spMissionPageUp = self:findChild("sp_missionPageUp")
    self.m_spRewardPageUp = self:findChild("sp_rewardPageUp")
    self.m_spMissionPageDown = self:findChild("sp_missionPageDown")
    self.m_spRewardPageDown = self:findChild("sp_rewardPageDown")
    self.m_spMissionBg = self:findChild("sp_missionBottomBg")

    -- ui节点绑定
    self.m_nodeTopTitle = self:findChild("node_title") -- 顶部标题
    self.m_nodePassTime = self:findChild("node_passTime") -- pass任务倒计时
    self.m_nodeMission = self:findChild("node_dailyMission") --任务节点
    self.m_nodeSeason = self:findChild("node_seasonMission") --season 节点
    self.m_nodeSeasonProgress = self:findChild("node_progress") -- season 进度节点
    self.m_nodeRewardTopUI = self:findChild("node_rewardTopUI") -- reward界面 topui节点
    
    self.m_nodePassReward = self:findChild("passPanelLayout") -- table View 节点
    self.m_nodePromotion = self:findChild("node_promotion") -- 促销节点
    
    self.node_flowerPage = self:findChild("node_flowerPage") --浇花节点
    self.node_missionPage = self:findChild("node_missionPage") --每日任务
    self.node_passPage = self:findChild("node_passPage") --pass节点

    self.m_nodePreview = self:findChild("node_fixedReward") -- 固定奖励

    -- 引导使用
    self.m_guideNode = self:findChild("node_guide")
    -- self.m_guideMissionBg       = self:findChild("guide_bg")
    self.m_nodeSpineNpc = self:findChild("node_spine_npc")

    self.m_labSeasonTime = self:findChild("lb_passTime") -- pass任务倒计时
    self.m_sprRewardNum = self:findChild("sp_rewardnum") -- 可领奖励节点
    self.m_labRewardNum = self:findChild("lb_rewardnum") -- 可领奖励数

    self.m_node_leftTitle = self:findChild("node_title")
    self.m_node_topTitle = self:findChild("node_top")

    self.m_nodeUnlock = self:findChild("node_unlock")
    self.m_nodeComingSoon = self:findChild("node_comingSoon")

    self.m_spPassBG = self:findChild("sp_reward_bg")


    self.m_panel_guide = self:findChild("panel_guide")
    
end

function DailyMissionMainLayer:initView()
    local currPageType = gLobalDailyTaskManager:getEnterPageType()
    if not currPageType then
        currPageType = PAGE_TYPE.MISSION_PAGE
    end
    gLobalDailyTaskManager:setEnterPageType(nil)
    if  self:hasPassGuide(true) then
        currPageType = PAGE_TYPE.MISSION_PAGE
    end

    self:initLeftNodeView(currPageType)
    self:initTopNodeView(currPageType)
    self:checkUnlock()

    -- 开始加载任务页
    self:initMissionTaskPage()

    self:updatePageSpStatus(currPageType)
   

    -- self:initPassRewardView()

    -- self:initFlowerViewNode()

end

-- 主界面左侧 节点界面
function DailyMissionMainLayer:initLeftNodeView(currPageType)
    local leftNodeView = util_createView("views.baseDailyMissionCode.DailyMissionMainLeftNodeView",  {isPortrait = self:isPortraitWindow(),currPageType = currPageType, chanegFun = function (currPageType,isCheckSafeBoxGuide)
        self:changeViewToPage(currPageType,false,isCheckSafeBoxGuide)
    end})
    self.m_node_leftTitle:addChild(leftNodeView)
    self.m_leftNodeView = leftNodeView
end

function DailyMissionMainLayer:initTopNodeView(currPageType)
    local topNodeView = util_createView("views.baseDailyMissionCode.DailyMissionMainTopNodeView", {isPortrait = self:isPortraitWindow(),currPageType = currPageType})
    self.m_node_topTitle:addChild(topNodeView)
    self.m_topNodeView = topNodeView
end

function  DailyMissionMainLayer:checkUnlock()
    self.m_nodeUnlock:setVisible(false)
    self.m_nodeComingSoon:setVisible(false)
    -- 需要展示其他
    if not G_GetMgr(ACTIVITY_REF.NewPass):getSeasonActivityOpen() then
        self.node_passPage:setVisible(false)
        self.m_nodeComingSoon:setVisible(self.m_currPageType == PAGE_TYPE.REWARD_PAGE)
    end
    
    if globalData.userRunData.levelNum < globalData.constantData.NEWPASS_OPEN_LEVEL then
        -- 未达到开启等级
        self.m_nodeUnlock:setVisible(self.m_currPageType == PAGE_TYPE.REWARD_PAGE)
        self.m_nodeComingSoon:setVisible(false)
    end

    -- 新手期pass
    if gLobalDailyTaskManager:isWillUseNovicePass() and G_GetMgr(ACTIVITY_REF.NewPass):getSeasonActivityOpen() then
        self.m_nodeUnlock:setVisible(false)
        self.m_nodeComingSoon:setVisible(false)
    end
end

function DailyMissionMainLayer:initMissionTaskPage()
    -- 加载任务节点和season 任务节点
    self.m_missionTaskView = util_createView("views.baseDailyMissionCode.DailyMissionMissionPageNode",  self:isPortraitWindow())
    self.m_nodeMission:addChild(self.m_missionTaskView)
    self:updateMission()

    self.m_seasonTaskView = util_createView("views.baseDailyMissionCode.DailyMissionSeasonPageNode",  self:isPortraitWindow())
    self.m_nodeSeason:addChild(self.m_seasonTaskView)
    self:updateSeasonMission()
end


function DailyMissionMainLayer:changeViewToPage(_currPageType, willDoProgress, _isCheckSafeBoxGuide)
    -- 点击的是相同的界面按钮不相应操作
    if self.m_currPageType == _currPageType then
        return
    end
    self.m_currPageType = _currPageType

    self.m_leftNodeView:updateBtnSp(self.m_currPageType)
    
    if _currPageType == PAGE_TYPE.MISSION_PAGE or _currPageType == PAGE_TYPE.FLOWER_PAGE then
        self:updatePageSpStatus(_currPageType)
    elseif _currPageType == PAGE_TYPE.REWARD_PAGE then
        self:updatePageSpStatus(_currPageType)
        if not willDoProgress then
            self:checkAutoShowBoxBubble(_isCheckSafeBoxGuide)
        end
    end

    -- 检测切换时间线
    self:checkTimeLine()
    self:checkUnlock()
end

function DailyMissionMainLayer:updateSeasonBuffTime()
    self.m_topNodeView:updateGemSaleNode()
end

function DailyMissionMainLayer:updatePageSpStatus(_currPageType)
    self.m_currPageType = _currPageType
    self.m_spPassBG:setVisible(_currPageType == PAGE_TYPE.REWARD_PAGE)
    
    self.node_missionPage:setVisible(_currPageType == PAGE_TYPE.MISSION_PAGE)
    self.node_passPage:setVisible(_currPageType == PAGE_TYPE.REWARD_PAGE)
    self.node_flowerPage:setVisible(_currPageType == PAGE_TYPE.FLOWER_PAGE)
    
    self.m_topNodeView:changePage(_currPageType)

end

-- 检测当前时间线
function DailyMissionMainLayer:checkTimeLine()
    if self.m_currPageType == PAGE_TYPE.MISSION_PAGE then
        -- 需要判断当前是否解锁 reward页签
        if self.m_bOpenRewardPage then
            -- 时间线
            self:runCsbAction("actionframe", true, nil, 60)
        end
    elseif self.m_currPageType == PAGE_TYPE.REWARD_PAGE then -- 如果切换到 reward 播放普通时间线
        self:runCsbAction("idle", true, nil, 60)
    end
end

function DailyMissionMainLayer:initPassRewardView()
    if self:isPassOpen() then
        self.m_bOpenRewardPage = true
        self.m_hasInitPassData = true
        self.m_passRewardView = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_MailLayer,  self:isPortraitWindow())
        local passPageSize = self.node_passPage:getContentSize()
        self.m_passRewardView:changeVisibleSize(passPageSize)
        -- local _scale = self:getUIScalePro()
        -- self.m_passRewardView:setScale(1/_scale)
        self.node_passPage:addChild(self.m_passRewardView)
    end
end

-- 检测 pass 活动状态
function DailyMissionMainLayer:afterPassOver()
    self.m_passRewardView:setVisible(false)
    self.node_passPage:removeAllChildren()
    self.m_passRewardView = nil
   
    self.m_topNodeView:afterPassOver()
    self.m_leftNodeView:afterPassOver()

    self:updateSeasonMission()
    self:checkUnlock()
end

-- 额外的展示情况
function DailyMissionMainLayer:checkRewardPageExtraStatus(willDoProgress, _isCheckSafeBoxGuide)
    if not willDoProgress then
        self:checkAutoShowBoxBubble(_isCheckSafeBoxGuide)
    end
end

---------------------------------- Mission 任务 Page相关 ----------------------------------


function DailyMissionMainLayer:updateMission(_refresh, _callback)
    if _refresh then
        self.m_missionTaskView:refreshAction(globalData.missionRunData, _callback)
    else
        self.m_missionTaskView:updateData(globalData.missionRunData)
    end
end

function DailyMissionMainLayer:updateSeasonMission(_refresh, _callback)
    local passTask = G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission()
    if _refresh then
        self.m_seasonTaskView:refreshAction(passTask, _callback)
    else
        self.m_seasonTaskView:updateData(passTask)
    end
end

--检测浇花系统
function DailyMissionMainLayer:initFlowerViewNode()
    if not G_GetMgr(G_REF.Flower) then
        return
    end
    local data = G_GetMgr(G_REF.Flower):getData()
    if data and data:getOpen() then
        self.isFlower = true
        if globalData.userRunData.levelNum >= data:getOpenLevel() and G_GetMgr(G_REF.Flower):isDownloadRes("Flower_2023") then
            local node = util_createView("views.FlowerCode_New.FlowerUnWaterLayer")
            local flowerPageSize = self.node_flowerPage:getContentSize()
            node:changeVisibleSize(flowerPageSize)
            -- local _scale = self:getUIScalePro()
            -- node:setScale(1/_scale)
            self.node_flowerPage:addChild(node)
        else
            -- self.bmtLabel:setString(data:getOpenLevel())
            -- self.Sp_flunlock:setVisible(true)
            -- self.bmtLabel:setVisible(true)
        end
    end
end

-- 通用刷新
function DailyMissionMainLayer:updateMissionByType(_params, _moveView, _callback)
    self:collectMissionUpdate(_params, _callback)
    -- 刷新左上角进度
    self:updateProgressNode(_params)
    -- 更新奖励页
    self:updateRewardPage(_moveView)
    -- 检测切换时间线
    self:checkTimeLine()
    -- 刷新任务提示数据
    self:updateRefreshData(_params)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
end

-- 收集了任务之后的回调
function DailyMissionMainLayer:collectMissionUpdate(_params, _callback)
    local missionType = _params.missionType
    local refresh = _params.refresh -- 是否有刷新动画
    if missionType == gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION then
        self:updateMission(refresh, _callback)
    elseif missionType == gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION then
        self:updateSeasonMission(refresh, _callback)
    elseif missionType == gLobalDailyTaskManager.MISSION_TYPE.PROMOTION_SALE then
        self:updateSeasonBuffTime()
    end
end

function DailyMissionMainLayer:updateRefreshData(_params)
    local refresh = _params.refresh -- 是否有刷新动画
    if refresh then
        self.m_refreshData = {}
        self.m_refreshData.task, self.m_refreshData.type = gLobalDailyTaskManager:getCurrRefreshInfo()
    end
end

---------------------------------- Reward Page 相关 ----------------------------------
-- 创建rewardPage 页相关ui
function DailyMissionMainLayer:initRewardPageUI()
    local mainlayer = util_createFindView(DAILYPASS_CODE_PATH.DailyMissionPass_MailLayer, self.m_bAutoCollectGuideFlag)
    self.node_passPage:addChild(mainlayer)
end


function DailyMissionMainLayer:updateRewardPage(_moveTableView)
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end

    --更新 pass TopUI 展示
    self.m_topNodeView:updatePassTopView()

    self.m_leftNodeView:updateRedPointNum(false)

    -- 更新促销按钮
    self:updateSeasonBuffTime()

    -- 通知 pass界面 滑动界面到哪一个index
    if self.m_passRewardView then
        self.m_passRewardView:updateRewardPage(_moveTableView)
    end
end

-- pass跳转
function DailyMissionMainLayer:updateTableViewToIndex(_nTime, _level, overCallBack)
    self.m_passRewardView:updateTableViewToIndex(_nTime, _level, overCallBack)
end

-- 保险箱独立出来
function DailyMissionMainLayer:updateSafeBox(_max)
    self.m_passRewardView:updateSafeBox(_max)
end
---------------------------------- 刷新界面 + 动画 + 基础功能 相关 ----------------------------------
function DailyMissionMainLayer:updateProgressNode(_params)
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end
    self.m_topNodeView:updateProgressNode(_params)
end

function DailyMissionMainLayer:flyMedalAction(_params)
    -- 完成任务飞行节点
    local _missionType = _params.missionType
    local medalStartPos = cc.p(0, 0)
    local medalNum = 0
    if _missionType == gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION then
        medalStartPos = self.m_missionTaskView:getMedalNodePos()
        medalNum = self.m_missionTaskView:getMedalNums()
    elseif _missionType == gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION then
        medalStartPos = self.m_seasonTaskView:getMedalNodePos()
        medalNum = self.m_seasonTaskView:getMedalNums()
    end

    local flyCallBack = function()
        -- 进行左上角进度条刷新
        self:updateProgressNode(_params)
        self.m_flyData = {}
        self.m_flyData.params = _params
        self.m_flyData.moveView = true
    end
    -- 添加屏蔽层
    gLobalViewManager:addLoadingAnima(true)

    local endPos = self.m_topNodeView:getMedalEndPos()
    if endPos then
        -- 创建飞行节点
        local flyNode = util_createView("views.baseDailyMissionCode.DailyMissionMedalFlyNode", medalNum)
        self:addChild(flyNode)
        flyNode:setPosition(medalStartPos)
        flyNode:playFlyAction(medalStartPos, endPos, flyCallBack)
    else
        -- 当前没有左上角节点 直接刷新界面
        if not self.m_bOpenRewardPage then
            local callback = function()
                -- 添加屏蔽层
                gLobalViewManager:removeLoadingAnima()
                if self.m_bAutoCollect then
                    self:autoCollectMission()
                end
            end
            self:updateMissionByType(_params, false, callback)
        else
            -- 添加屏蔽层
            gLobalViewManager:removeLoadingAnima()
        end
    end
end

function DailyMissionMainLayer:playBuyTicketAction()
    -- 先添加遮罩层
    gLobalViewManager:addLoadingAnima(true)
    -- 需要刷新大厅任务页状态
    self:updateMissionByType({missionType = gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION}, false)
    if G_GetMgr(ACTIVITY_REF.NewPass):canDoUnlockGuide() then
        performWithDelay(
            self,
            function()
                self:buyPassTicketSuccessGuide()
            end,
            0.5
        )
    else
        self.m_passRewardView:doAfterBuyPassUpdate()
        gLobalViewManager:removeLoadingAnima()
    end
end

function DailyMissionMainLayer:buyPassTicketSuccessGuide()
    if self.m_buyGuideIndex == nil then
        self.m_buyGuideIndex = 1
    end
    local buyGuideTotalNum = 4
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData or self.m_buyGuideIndex > buyGuideTotalNum then
        gLobalViewManager:removeLoadingAnima()
        return
    end

    if self.m_buyGuideIndex == 1 then
        -- 让table view 移动到头
        self.m_passRewardView:scrollTableViewByRowIndex(1, 0.5, 1, true)
    elseif self.m_buyGuideIndex == 2 then
        -- 播放 pay cell 块解锁动画
        self.m_passRewardView:doAfterBuyPassUpdate()
        performWithDelay(
            self,
            function()
                local pointConfig = actData:getPassPointsInfo()
                self.m_passRewardView:scrollTableViewByRowIndex(#pointConfig, 1, 1, true)
            end,
            2.5
        )
    elseif self.m_buyGuideIndex == 3 then
        -- 播放保险箱解锁动画
        self.m_passRewardView:doAfterBuyPassUpdate(true)
        performWithDelay(
            self,
            function()
                -- 回到当前进度
                local currLevel = actData:getLevel()
                self.m_passRewardView:scrollTableViewByRowIndex(currLevel + 1, 0.5, 1, true)
            end,
            2
        )
    elseif self.m_buyGuideIndex == 4 then
        -- 判断当前保险箱是否可以领取
        if self:checkSafeBoxCompleted() then
            -- 移动界面到保险箱
            local pointConfig = actData:getPassPointsInfo()
            self.m_passRewardView:scrollTableViewByRowIndex(#pointConfig, 1, 1, true)
            performWithDelay(
                self,
                function()
                    self.m_bInBuyTicketGuide = true
                    self:collectSafeBox()
                end,
                1.1
            )
        else
            performWithDelay(
                self,
                function()
                    self:buyPassTicketSuccessGuide()
                end,
                0.1
            )
        end
    end
    self.m_buyGuideIndex = self.m_buyGuideIndex + 1
end

function DailyMissionMainLayer:checkAutoShowBoxBubble(_isCheckSafeBoxGuide)
    if not self.m_bAutoCollect and self.m_currPageType == PAGE_TYPE.REWARD_PAGE and (not self.m_guideStep or self.m_guideStep == -1) then
        if self:checkShowFreeQipao() then
            self:showBoxQipao("free", 1)
        elseif self.m_bOpenRewardPage and _isCheckSafeBoxGuide and self.m_passRewardView and self:hasSafeBoxGuide() then
            -- 保险箱引导
            self:showSafeBoxGuide()
        end
    end
end

function DailyMissionMainLayer:checkShowFreeQipao()
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passActData then
        local currLevel = passActData:getLevel()
        if G_GetMgr(ACTIVITY_REF.NewPass):getIsMaxPoints() then
            currLevel = passActData:getLevel()
        end
        local levelLimit = 4
        if globalData.slotRunData.isPortrait == true then
            levelLimit = 3
        end
        if currLevel <= levelLimit then
            local newPassCellData = passActData:getPassPointsInfo()
            local pointData = newPassCellData[2]
            local boxInfo = pointData.freeInfo
            if boxInfo and not boxInfo.m_collected and self:checkIsSpeaicalItme(boxInfo) and self.m_passView ~= nil then
                return true
            end
        end
    end
    return false
end

function DailyMissionMainLayer:showBoxQipao(_boxType, _level, _isPreview,isPortrait)
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end
    local newPassCellData = actData:getPassPointsInfo()
    local pointData = newPassCellData[_level + 1]

    local pos = {x = 0, y = 0}
    local boxInfo = nil
    if _boxType == "free" then
        if _isPreview == true then
            pos = self:getPreviewCellCellPos(_boxType)
        else
            pos = self:getCellPos(_boxType, _level)
        end
        if pos then
            boxInfo = pointData.freeInfo
        end
    elseif _boxType == "pay" or  _boxType == "season" then
        if _isPreview == true then
            pos = self:getPreviewCellCellPos(_boxType)
        else
            pos = self:getCellPos(_boxType, _level)
        end
        if pos then
            boxInfo = pointData.payInfo
        end
    elseif _boxType == "premium" then
        if _isPreview == true then
            pos = self:getPreviewCellCellPos(_boxType)
        else
            pos = self:getCellPos(_boxType, _level)
        end
        if pos then
            boxInfo = pointData.tripleInfo
        end
    elseif _boxType == "safeBox" then
        if gLobalDailyTaskManager:isWillUseNovicePass() then
            return
        end
        
        pos = self:getCellPos(_boxType, _level, cc.p(60, 0))
        if pos then
            if self:isPortraitWindow() then
                pos = cc.p(pos.x - 160, pos.y)
            end
        
            boxInfo = pointData.safeBoxInfo
        end
    end
    if boxInfo then
        self:removeBoxRewardInfo(true)
        if _level + 1 == #newPassCellData then
            self.uiQipao = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassSafeBoxCellQipao_ThreeLine,false,self:isPortraitWindow())
        else
            self.uiQipao = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassCellQipao_ThreeLine, self:checkIsSpeaicalItme(boxInfo))
        end
        self:addChild(self.uiQipao)
        self.uiQipao:setPosition(pos)
        self.uiQipao:showView(boxInfo)
    end
    return self.uiQipao
end

function DailyMissionMainLayer:checkIsSpeaicalItme(boxInfo)
    local result = false
    if DAILYPASS_EXTRA_CONFIG.DailyMissionPass_SpecialItemIcon and boxInfo.m_rewards and boxInfo.m_rewards.items then
        for i, v in ipairs(boxInfo.m_rewards.items) do
            if v.p_icon == DAILYPASS_EXTRA_CONFIG.DailyMissionPass_SpecialItemIcon then
                result = true
                break
            end
        end
    end
    return result
end

function DailyMissionMainLayer:getCellPos(_boxType, _level, _offset)
    -- 从tableView 中获取
    return self.m_passRewardView:getCellPos(_boxType, _level, _offset)
end

function DailyMissionMainLayer:getPreviewCellCellPos(_boxType)
    return self.m_passRewardView:getPreviewCellCellPos(_boxType)
end

function DailyMissionMainLayer:removeBoxRewardInfo(remove)
    if not tolua.isnull(self.uiQipao) then
        if remove == true then
            self.uiQipao:removeFromParent()
        end
        self.uiQipao = nil
    end
end


function DailyMissionMainLayer:closeMainLayerPopView()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        self:postCloseNotification()
        return
    end

    -- 新手期abtest 4.0 新增条件 用户等级需要大于限制等级才能弹出
    -- csc 2021-11-29 11:55:34 取消掉4.0判断，保留等级判断
    local canPop = true
    if globalData.userRunData.levelNum < globalData.constantData.NOVICE_DAILYPASS_PRUCHASES_LEVEL then
        canPop = false
    end
    -- 如果当前未解锁的情况
    if actData:isUnlocked() == false and canPop then
        self:closeMainLayerPopUnlock()
    else
        self:postCloseNotification()
    end
end

function DailyMissionMainLayer:closeMainLayerPopUnlock()
    local uiView = nil
    local key = DAILYPASS_EXTRA_CONFIG.DailyMissionPass_CloseMainLayerPopUnlock
    local value = DAILYPASS_EXTRA_CONFIG.DailyMissionPass_CloseMainLayerPopUnlockCD
    if gLobalDailyTaskManager:checkPopViewCD(key, value) then
        uiView = gLobalDailyTaskManager:createBuyPassTicketLayer()
    end
    self:postCloseNotification(uiView)
end

function DailyMissionMainLayer:checkSafeBoxCompleted()
    -- 检测当前保险箱是否需要收集

    -- -------- 发动态更新先这么写 2021-07-26 下一次版本热更修改到 DailyTaskManager:getSafeBoxIsCompleted 中
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return false
    end
    -- 如果当前未解锁的情况
    if actData:isUnlocked() == false then
        return false
    end

    if G_GetMgr(ACTIVITY_REF.NewPass):getSafeBoxIsCompleted() and not  self:hasPassGuide() then
        return true
    end
    return false
end

function DailyMissionMainLayer:collectSafeBox()
    self:changeViewToPage(PAGE_TYPE.REWARD_PAGE)
    -- 发送收集保险箱
    gLobalDailyTaskManager:sendActionPassRewardCollect(nil, 3, false, false,true)
end

-- 左上角进度条进度增长完毕之后的回调
function DailyMissionMainLayer:progressNodeIncreaseCallBack(_params)
    -- 创建刷新回调
    local callback = function()
        -- TODO:这个地方的老逻辑有bug，开宝箱的时候，无法触发不涨进度了
        if self.m_openSafeBox then
            self.m_openSafeBox = false
            if self.m_bOpenRewardPage then -- 允许切换的时候才能切
                self:changeViewToPage(PAGE_TYPE.REWARD_PAGE, true)
                self:updateSafeBox(true) -- 这里刷新的时候需要展示保险箱收集满的进度
                -- 发送收集保险箱
                if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
                    gLobalDailyTaskManager:sendActionPassRewardCollect(nil, 3, false, false,true)
                else
                    gLobalDailyTaskManager:sendActionPassRewardCollect(nil, 3, false, false,false)
                end
            end
        else
            -- 如果当前有新奖励可以领
            if self.m_bIsUpgrade then
                self.m_bIsUpgrade = false
                if self.m_bOpenRewardPage then -- 允许切换的时候才能切
                    self:changeViewToPage(PAGE_TYPE.REWARD_PAGE, true)
                end
            else
                self.m_passRewardView:setMoveSpeedTime(0.2)
            end
            -- 直接更新page 页滚动层
            self:updateRewardPage(true)
        end
    end
    -- 刷新任务页
    self:collectMissionUpdate(_params, callback)

    -- 刷新任务提示数据
    self:updateRefreshData(_params)

    self.m_flyData = nil
end

-- reward界面进度条增长完毕之后的回调
function DailyMissionMainLayer:tableViewProgressIncCallBack()
    self:updateProgressNode({addExp = 0})
    self:updateSafeBox()
    self.m_passRewardView:updatePreviewCellProgress()
    -- 正常进度增长完毕
    if self.m_bAutoCollect then
        self:autoCollectMission()
    end
end

-- 收集保险箱之后的回调
function DailyMissionMainLayer:collectSafeBoxCallBack()
    if self:checkSafeBoxCompleted() then
        -- 可能还要做一个保险箱上的进度条增加动画  先预留
        -- 如果当前还有保险箱需要收集,重新走一遍进度条 0->total 的动画，再打开下一个保险箱
        gLobalViewManager:addLoadingAnima(true) -- 添加遮罩
        self:updateProgressNode({nextSafeBox = true})
    else
        gLobalViewManager:removeLoadingAnima()
        self:updateProgressNode({addExp = 0})
        self:updateSafeBox()
        if self.m_bAutoCollect then
            self:autoCollectMission()
        end
        if self.m_bInBuyTicketGuide then
            self.m_bInBuyTicketGuide = false
            self:buyPassTicketSuccessGuide()
        end
    end
end

-- 处理 pass 相关界面全部关闭之后，提示高倍场刷新弹板
function DailyMissionMainLayer:postCloseNotification(_view)
    if _view then
        _view:setOverFunc(
            function()
                local rewardCount = gLobalDailyTaskManager:getCollectRewardCount() or 0
                gLobalDailyTaskManager:rememberCollectRewardCount(0)
                local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("PassCollect", "PassCollect_" .. rewardCount)
                if view then
                    view:setOverFunc(function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS) -- 提示开启
                        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                    end)
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS) -- 提示开启
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                end
            end
        )
    else
        local rewardCount = gLobalDailyTaskManager:getCollectRewardCount() or 0
        gLobalDailyTaskManager:rememberCollectRewardCount(0)
        local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("PassCollect", "PassCollect_" .. rewardCount)
        if view then
            view:setOverFunc(function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS) -- 提示开启
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS) -- 提示开启
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        end
    end
end

function DailyMissionMainLayer:setMissionPageAutoClickStatus(_flag)
    -- 设置mission 页不能点击
    if self.m_missionTaskView then
        self.m_missionTaskView:setAutoCollect(_flag)
    end
    if self.m_seasonTaskView then
        self.m_seasonTaskView:setAutoCollect(_flag)
    end
end

---------------------------------- 引导 相关 ----------------------------------

-- 最终宝箱的引导
function DailyMissionMainLayer:hasSafeBoxGuide()
    if self.m_currPageType ~= PAGE_TYPE.REWARD_PAGE then
        return false
    end
    if self.m_bAutoCollect then
        return false
    end
    if self.m_bIsPushingView then
        return false
    end
    local refreshGuideId = gLobalDailyTaskManager:getSafeBoxGuideId()
    if refreshGuideId and refreshGuideId > 0 then
        return false
    end
    return true
end
function DailyMissionMainLayer:showSafeBoxGuide()
    if self.m_isScrollingToSafeBoxGuide then 
        return
    end 
    -- 移动tableview到最终宝箱位置
    self.m_isScrollingToSafeBoxGuide = true
    self:addMask()
    if self.m_passRewardView then
        self.m_passRewardView:scrollToBottom()
    end
    util_performWithDelay(
        self,
        function()
            if not tolua.isnull(self) then
                -- 添加引导遮罩和气泡
                self:openSafeBoxGuide()
                self.m_isScrollingToSafeBoxGuide = false
            end
        end,
        0.5
    )
end
function DailyMissionMainLayer:openSafeBoxGuide()
    local function createFailCall()
        if not tolua.isnull(self.m_mask) then
            self.m_mask:removeFromParent()
            self.m_mask = nil
        end
    end
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        createFailCall()
        return
    end
    local newPassCellData = actData:getPassPointsInfo()
    local index = table.nums(newPassCellData)

    local pointData = newPassCellData[index]
    if not pointData then
        createFailCall()
        return
    end
    local boxInfo = pointData.safeBoxInfo
    if not boxInfo then
        createFailCall()
        return
    end

    local maskPath = DAILYPASS_RES_PATH.DailyMissionPass_Mask
    local passPageSize = self.node_passPage:getContentSize()
    local scale = self:getUIScalePro() * passPageSize.height / 628 
    local size = cc.size(430*scale, 600*scale)
    local pos = self.m_passRewardView:getPreviewNodePos()

    if self:isPortraitWindow() then
        size = cc.size(680, 390)
        pos.x = pos.x + 10
        pos.y = pos.y + size.height / 2 + 5 *scale
    else
        pos.y = pos.y + size.height / 2 + 14 *scale
        pos.x = pos.x - size.width / 2 - 24 *scale
    end

    size.width = size.width 
    size.height = size.height 

    -- 创建引导区域
    self.maskNode = util_require("utils.MaskNode"):create()
    self.maskNode:init(maskPath, cc.p(pos.x, pos.y), 200, size)
    gLobalViewManager:getViewLayer():addChild(self.maskNode, ViewZorder.ZORDER_GUIDE)

    -- self:showBoxQipao("safeBox", index - 1 , gLobalViewManager:getViewLayer(), ViewZorder.ZORDER_GUIDE+2)
    self.m_safeBoxGuideQipao = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassSafeBoxCellQipao_ThreeLine, true,self:isPortraitWindow())
    gLobalViewManager:getViewLayer():addChild(self.m_safeBoxGuideQipao, ViewZorder.ZORDER_GUIDE + 2)
    if self:isPortraitWindow() then
        pos = cc.p(pos.x - 160, pos.y)
    end
    self.m_safeBoxGuideQipao:setPosition(pos)
    self.m_safeBoxGuideQipao:showView(boxInfo)
end

-- 提取Pass引导判断方法
function DailyMissionMainLayer:hasPassGuide(isIgnorePassView)
    if not G_GetMgr(ACTIVITY_REF.NewPass):getSeasonActivityOpen() then
        return false
    end
    if not self.m_hasInitPassData and not isIgnorePassView then
        return false
    end
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData:getGuideIndex() == -1 then
        return false
    end
    return true
end

function DailyMissionMainLayer:openPassGuide()
    -- 必须要判断当前等级是否满足 以及活动是否开启
    if not G_GetMgr(ACTIVITY_REF.NewPass):getSeasonActivityOpen() then
        if not tolua.isnull(self.m_mask) then
            self.m_mask:removeFromParent()
        end
        return
    end

    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()

    if self.m_guideStep == nil then
        self.m_guideStep = actData:getGuideIndex()
    end

    local guideStep = nil
    --补丁 以防用户发在因为跟服务器交互有问题,导致引导应该进入reward 页没进去重新上游戏 引导有问题的bug
    if self.m_guideStep > 2 and not guideStep then
        self:changeViewToPage(PAGE_TYPE.REWARD_PAGE)
    end

    guideStep = self.m_guideStep
    if guideStep == -1 then
        if not tolua.isnull(self.m_mask) then
            self.m_mask:removeFromParent()
        end
        return
    end

    self.data = {
        guideStep = guideStep,
        isForceGuide = false,
        node = nil,
        pos = nil,
        zorder = 1,
        parent = nil
    }

    local bEnd = false
    local maskPath = DAILYPASS_RES_PATH.DailyMissionPass_Mask

    local scale = self:getUIScalePro()
    if guideStep == 1 then
        local pos = self.m_guideNode:getParent():convertToWorldSpace(cc.p(self.m_guideNode:getPosition()))
        -- 创建引导区域
        self.maskNode = util_require("utils.MaskNode"):create()
        local size = self.m_panel_guide:getContentSize()-- cc.size(1050, 600)
        size.width = size.width * scale
        size.height = size.height * scale
        self.maskNode:init(maskPath, pos, 200, size)
        gLobalViewManager:getViewLayer():addChild(self.maskNode, ViewZorder.ZORDER_GUIDE)
    elseif guideStep == 2 then
        -- 这里不使用抬高, 采用挖洞
        local rewardBtnPos = self.m_node_leftTitle:convertToWorldSpace(cc.p(self.m_leftNodeView:getPassBtnPos()))
        
        self.data.isForceGuide = true
        -- 创建引导区域
        self.maskNode = util_require("utils.MaskNode"):create()
        local size = cc.size(300, 100)
        if globalData.slotRunData.isPortrait then
            size = cc.size(246, 100)
        else
            rewardBtnPos.y = rewardBtnPos.y + 1.5
        end
        size.width = size.width * scale
        size.height = size.height * scale

        self.maskNode:init(maskPath, rewardBtnPos, 200, size)
        gLobalViewManager:getViewLayer():addChild(self.maskNode, ViewZorder.ZORDER_GUIDE)
        -- 抬高透明按钮
        local passBtn = self.m_leftNodeView:getPassBtn()
        self.data.node = passBtn
        self.data.zorder = passBtn:getZOrder()
        self.data.parent = passBtn:getParent()
        self.data.pos = cc.p(passBtn:getPosition())
        local wordPos = self.m_node_leftTitle:convertToWorldSpace(cc.p(passBtn:getPosition()))
        passBtn:setPosition(wordPos)
        self:changeGuideNodeZorder(passBtn, ViewZorder.ZORDER_GUIDE + 3)
    elseif guideStep == 3 then
        local pos = self.m_guideNode:getParent():convertToWorldSpace(cc.p(self.m_guideNode:getPosition()))
        -- 创建引导区域
        local size = self.m_panel_guide:getContentSize()
        size.width = size.width * scale
        size.height = size.height * scale
        self.maskNode = util_require("utils.MaskNode"):create()
        self.maskNode:init(maskPath, pos, 200, size)
        gLobalViewManager:getViewLayer():addChild(self.maskNode, ViewZorder.ZORDER_GUIDE)
    elseif guideStep == 4 then
        if actData:isUnlocked() then
            -- 直接结束
            bEnd = true
        else
            local topUI = self.m_topNodeView:getPassTopView()
            if topUI then
                local nodePos = topUI:getTicketNodePos()
                -- 创建引导区域
                self.maskNode = util_require("utils.MaskNode"):create()
                local size = cc.size(320, 80)
                size.width = size.width * scale
                size.height = size.height * scale
                self.maskNode:init(maskPath, nodePos, 200, size)
                gLobalViewManager:getViewLayer():addChild(self.maskNode, ViewZorder.ZORDER_GUIDE)
            else
                -- 直接结束
                bEnd = true
            end
        end
    end
    if bEnd then
        util_nextFrameFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_NEXT_GUIDE, {nextStep = true})
            end
        )
    else
        self.m_guideLayer = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_GuideLayer, self.data)
        gLobalViewManager:getViewLayer():addChild(self.m_guideLayer, ViewZorder.ZORDER_GUIDE + 2)
        self.m_guideLayer:setPosition(display.cx, display.cy)
    end
end

-- 抬高层级之后需要设置回来
function DailyMissionMainLayer:resetGuideNodeZOrder()
    if self.maskNode then
        self.maskNode:removeFromParent()
        self.maskNode = nil
    end
    if self.data and self.data.node ~= nil then
        util_changeNodeParent(self.data.parent, self.data.node, self.data.zorder)
        self.data.node:setScale(1)
        self.data.node:setPosition(self.data.pos)
        self.data.parent = nil
        self.data.node = nil
        self.data.zorder = 1
        self.data.pos = nil
        if self.hitLightingEffect then
            self.hitLightingEffect:removeFromParent()
            self.hitLightingEffect = nil
        end
    end
end

function DailyMissionMainLayer:changeGuideNodeZorder(node, zorder)
    local newZorder = zorder and zorder or ViewZorder.ZORDER_GUIDE + 1
    util_changeNodeParent(gLobalViewManager:getViewLayer(), node, newZorder)

    -- 横竖版都需要适配
    local currLayerScale = self.m_csbNode:getChildByName("root"):getScale()
    node:setScale(currLayerScale)
end

---------------------------------- 点击 相关 ----------------------------------
function DailyMissionMainLayer:onKeyBack()
    if G_GetMgr(G_REF.Flower) then
        if G_GetMgr(G_REF.Flower):getWaterHide() == nil then
        elseif not G_GetMgr(G_REF.Flower):getWaterHide() then
            return
        end
    end
    if DEBUG == 2 and not  self:hasPassGuide() then
        DailyMissionMainLayer.super.onKeyBack(self)
    end
end

---------------------------------- 外部调用 相关 ----------------------------------
-- 自动收集  需要自检当前要完成什么任务 优先每日任务
function DailyMissionMainLayer:autoCollectMission()
    self.m_inAction = true
    self.m_bAutoCollect = true
    local taskInfo = gLobalDailyTaskManager:getCompletedMissionTask()
    if taskInfo ~= nil then
        if self.m_currPageType == PAGE_TYPE.REWARD_PAGE then
            self:changeViewToPage(PAGE_TYPE.MISSION_PAGE)
        end
        self:setMissionPageAutoClickStatus(true)
        gLobalDailyTaskManager:sendMissionCollectAction(taskInfo.taskType, taskInfo.taskId, taskInfo.taskExp)
    else
        self:setMissionPageAutoClickStatus(false)
        self.m_inAction = false
        self.m_bAutoCollect = false
    end
end

function DailyMissionMainLayer:flaySpot()
end
function DailyMissionMainLayer:onEnter()
    -- self.m_perBgMusicName = gLobalSoundManager:getCurrBgMusicName()
    -- gLobalSoundManager:playBgMusic(DAILYPASS_RES_PATH.PASS_MISSION_BGM_MP3)
    -- self:playBgMusic()

    --csc 2021-11-08 11:16:28 修复从关卡进入的时候背景音渐隐的问题
    if gLobalViewManager:isLevelView() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REMOVE_LEVEL_SOUND_HANDLER_AND_SET_MAX_VOLUME)
    end

    DailyMissionMainLayer.super.onEnter(self)

    self:initPassRewardView()
    self:initFlowerViewNode()

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 倒计时为0时关闭界面
            self:closeUI()
        end,
        ViewEventType.NOTIFY_DAILY_TASK_UI_CLOSE
    )

    -- season活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPass then

                if self.m_safeBoxGuideQipao then
                    self.m_safeBoxGuideQipao:removeFromParent()
                    self.m_safeBoxGuideQipao = nil
                end

                if self.m_refreshGuideLayer then
                    self.m_refreshGuideLayer:removeFromParent()
                    self.m_refreshGuideLayer = nil
                end

                if self.m_guideLayer then
                    self.m_guideLayer:removeFromParent()
                    self.m_guideLayer = nil
                end

                if not tolua.isnull(self.m_mask) then
                    self.m_mask:removeFromParent()
                end

                self:resetGuideNodeZOrder()

                self:afterPassOver()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 监听钻石消耗
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:updateMissionByType(params, false)
        end,
        ViewEventType.NOTIFY_DAILYPASS_GEMCONSUME_SUCCESS
    )

    -- 监听消耗钻石直接刷新任务
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:updateMissionByType({missionType = params.missionType, refresh = true}, false)
        end,
        ViewEventType.NOTIFY_DAILYPASS_REFRESH_SUCCESS
    )

    -- 监听 reward 界面 collect
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
            if not actData then
                return
            end
            if self.m_passRewardView then
                if params.rewardInfo.collectAll then
                    self.m_passRewardView:collectAllUpdate()
                elseif params.rewardInfo.safeBox then
                    self:collectSafeBoxCallBack()
                else
                    self.m_passRewardView:collectUpdate(params.rewardInfo)
                end
            end
            -- 刷新界面
            self:updateRewardPage()
        end,
        ViewEventType.NOTIFY_DAILYPASS_COLLECT_REWARD_OVER
    )

    -- 监听领取界面成功回调
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not G_GetMgr(G_REF.Flower) then
                self:flyMedalAction(params)
                return
            end
            local spot = 0
            if globalData.missionRunData.p_totalMissionNum == 3 then
                if globalData.missionRunData.p_allMissionCompleted then
                    spot = 1
                end
            else
                if globalData.missionRunData.p_currMissionID == 4 and not globalData.missionRunData.p_allMissionCompleted then
                    spot = 1
                end
            end
            local fl_data = G_GetMgr(G_REF.Flower):getData()
            if fl_data and fl_data:getGoldCkm() ~= 0 and spot == 1 then
                self:flyMedalAction(params)
                
                local pos = self.m_node_leftTitle:convertToWorldSpace(cc.p(self.m_leftNodeView:getFlowerBtnPos()))
                local view = G_GetMgr(G_REF.Flower):createFlayerLayer_New()
                if view then
                    view:setPosition(display.cx ,display.cy)
                    self:addChild(view)
                    local moveAction = cc.MoveTo:create(0.8, pos)
                    local action =
                        cc.CallFunc:create(
                        function()
                            fl_data:setGoldCkm()
                            --self:flyMedalAction(params)
                            view:removeFromParent()
                        end
                    )
                    view:runAction(cc.Sequence:create(moveAction, action))
                    gLobalSoundManager:playSound(G_GetMgr(G_REF.Flower):getConfig().SOUND.PRTICL)
                    gLobalNoticManager:postNotification(G_GetMgr(G_REF.Flower):getConfig().EVENT_NAME.NOTIFY_REWARD_BIG)
                end
            else
                self:flyMedalAction(params)
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_COLLECT_OVER
    )

    -- 监听左上角进度结束
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.isUpgrade then
                self.m_bIsUpgrade = params.isUpgrade
            end
            if params.canOpenSafeBox then
                self.m_openSafeBox = params.canOpenSafeBox
            end
            if self.m_flyData ~= nil then
                self:progressNodeIncreaseCallBack(self.m_flyData.params)
            else
                if self.m_openSafeBox then
                    self.m_openSafeBox = false
                    self:collectSafeBox()
                end
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_PROGRESS_INCEXP_OVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- if self.m_bOpenRewardPage then
            if self.m_currPageType ~= PAGE_TYPE.REWARD_PAGE then
                local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
                if passActData then
                    local levelIndex = passActData:getLevel() + 1
                    self:updateTableViewToIndex(0.1, levelIndex)
                    self:changeViewToPage(PAGE_TYPE.REWARD_PAGE)
                end
            end
            -- end
        end,
        ViewEventType.NOTIFY_DAILYPASS_CLICK_CHANGE_PAGE
    )

    ----------------- pass任务部分 --------------
    -- 刷新pass 任务
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.success == true then
                self:updateMissionByType({missionType = gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION, refresh = true}, false)
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_SEASONMISSON_REFRESH
    )
    -- 购买pass ticket
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.success == true then
                self:playBuyTicketAction()
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_BUY_PASSTICKET
    )

    -- 监听滑动回调
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:buyPassTicketSuccessGuide()
        end,
        ViewEventType.NOTIFY_DAILYPASS_TABLEVIEW_MOVEOVER
    )

    -- 监听购买等级商店回调
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.success == true then
                self:updateRewardPage(true)
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_BUY_LEVELSTORE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_inAction = false
        end,
        ViewEventType.NOTIFY_DAILYPASS_COLLECT_FAILED
    )

    -- 进度条增长完毕回调
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:tableViewProgressIncCallBack()
        end,
        ViewEventType.NOTIFY_DAILYPASS_INC_EXP_OVER
    )

    -- 显示宝箱奖励信息
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if self.m_currPageType == PAGE_TYPE.MISSION_PAGE then
                if params and params.giftType ~= nil then -- 补丁：发消息时可能极限点击切页
                    self:showTaskRewardQipao(params)
                end
            elseif self.m_currPageType == PAGE_TYPE.REWARD_PAGE then
                if params and params.level ~= nil and params.boxType ~= nil then -- 补丁：发消息时可能极限点击切页
                    local level = params.level
                    local boxType = params.boxType
                    local isPreview = params.isPreview
                    local isPortrait = params.isPortrait
                    self:showBoxQipao(boxType, level, isPreview,isPortrait)
                end
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_SHOW_REWARD_INFO
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:removeBoxRewardInfo(params)
        end,
        ViewEventType.NOTIFY_DAILYPASS_REMOVE_REWARD_INFO
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if self.m_guideStep == nil or self.m_guideStep == -1 then
                return
            end

            if self.m_guideLayer then
                self.m_guideLayer:removeFromParent()
                self.m_guideLayer = nil
            end
            self:resetGuideNodeZOrder()

            if params.nextStep == true then
                self.m_guideStep = self.m_guideStep + 1
                if self.m_guideStep > 4 then
                    self.m_guideStep = -1
                end

                local isNewUser = gLobalDailyTaskManager:isWillUseNovicePass()
                gLobalDailyTaskManager:sendActionPassGuideStep(self.m_guideStep, isNewUser)
            end
            performWithDelay(
                self,
                function()
                    self:openPassGuide()
                end,
                0.1
            )
        end,
        ViewEventType.EVENT_BATTLE_PASS_NEXT_GUIDE
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if self.m_refreshGuideLayer then
                self.m_refreshGuideLayer:removeFromParent()
                self.m_refreshGuideLayer = nil
            end
            if self.maskNode then
                self.maskNode:removeFromParent()
                self.maskNode = nil
            end
            if params and params.guideId >= 1 then
                if not tolua.isnull(self.m_mask) then
                    self.m_mask:removeFromParent()
                end
                gLobalDailyTaskManager:setRefreshGuideId(params.guideId)
                gLobalDailyTaskManager:sendExtraRequest(ExtraType.PassMissionRefreshGuide, params.guideId)
            end
        end,
        ViewEventType.EVENT_PASS_REFRESH_NEXT_GUIDE
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if self.m_safeBoxGuideQipao then
                self.m_safeBoxGuideQipao:removeFromParent()
                self.m_safeBoxGuideQipao = nil
            end
            if self.maskNode then
                self.maskNode:removeFromParent()
                self.maskNode = nil
            end
            if params and params.guideId >= 1 then
                if not tolua.isnull(self.m_mask) then
                    self.m_mask:removeFromParent()
                end
                gLobalDailyTaskManager:setSafeBoxGuideId(params.guideId)
                gLobalDailyTaskManager:sendExtraRequest(ExtraType.PassRewardSafeBoxGuide, params.guideId)
            end
        end,
        ViewEventType.EVENT_PASS_SAFTBOX_NEXT_GUIDE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_leftNodeView:updateRedPointNum(true)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_REFRESH)
        end,
        ViewEventType.NOTIFY_ACTIVITY_FLOWER
    )

    local mgr = G_GetMgr(G_REF.Flower)
    if mgr and mgr:getData() and mgr:getData():getWaterTime() then
        if globalData.userRunData.p_serverTime >= tonumber(mgr:getData():getWaterTime()) then
            mgr:sendWaterTime()
        end
    end
end

function DailyMissionMainLayer:addMask()
    self.m_mask = util_newMaskLayer()
    self.m_mask:setOpacity(0)
    gLobalViewManager:getViewLayer():addChild(self.m_mask, ViewZorder.ZORDER_GUIDE)
end

function DailyMissionMainLayer:onExit()
    DailyMissionMainLayer.super.onExit(self)
end

-- 重写父类方法
function DailyMissionMainLayer:onShowedCallFunc()
    -- 检测切换时间线
    self:checkTimeLine()
    -- 进入引导
    performWithDelay(
        self,
        function()
            -- 如果当前是自动收集  登录弹窗队列 进入的，不允许出现引导
            if not self.m_bAutoCollect and not self.m_bIsPushingView then
                if self:hasPassGuide() then
                    self:addMask()
                    self:openPassGuide()
                end
            end
        end,
        0
    )

    -- 检测当前是否有保险箱要收集
    if self:checkSafeBoxCompleted() then
        performWithDelay(
            self,
            function()
                self:collectSafeBox()
            end,
            0.6
        )
    else
        -- 如果当前没有保险箱需要收集,需要判断当前是否有自动收集
        if self.m_bAutoCollect then
            self:autoCollectMission()
        end
    end
end

function DailyMissionMainLayer:closeUI()
    if self:isShowing() or self:isHiding() then
        return
    end

    if G_GetMgr(G_REF.Flower) then
        G_GetMgr(G_REF.Flower):setWaterHide(true)
    end

    if self.m_safeBoxGuideQipao then
        self.m_safeBoxGuideQipao:removeFromParent()
        self.m_safeBoxGuideQipao = nil
    end

    if self.m_refreshGuideLayer then
        self.m_refreshGuideLayer:removeFromParent()
        self.m_refreshGuideLayer = nil
    end

    if self.m_guideLayer then
        self.m_guideLayer:removeFromParent()
        self.m_guideLayer = nil
    end

    if not tolua.isnull(self.m_mask) then
        self.m_mask:removeFromParent()
    end

    self:resetGuideNodeZOrder()

    if self.m_passRewardView then
        self.m_passRewardView:beforeClose()
    end

    gLobalViewManager:removeLoadingAnima()

    -- 如有有气泡的情况下需要移除
    self:removeBoxRewardInfo(true)

    -- 恢复背景音
    -- gLobalSoundManager:playBgMusic(self.m_perBgMusicName)
    -- self:stopBgMusic()
    --csc 2021-11-08 11:16:28 修复从关卡进入的时候背景音渐隐的问题
    if gLobalViewManager:isLevelView() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_LEVEL_SOUND_HANDLER)
    end

    local callback = function()
        -- gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_REFRESH)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_CLOSE_LAYER)

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_REFRESH_TIPS, self.m_refreshData)
        self.m_refreshData = nil
        if gLobalViewManager:isLevelView() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR, true)
        end

        -- 关卡内每日任务掉落公会点数 更新公会宝箱任务进度
        if gLobalDailyTaskManager["getNotifyAddClanPointsEvt"] and gLobalDailyTaskManager:getNotifyAddClanPointsEvt() then
            local ClanManager = util_require("manager.System.ClanManager"):getInstance()
            ClanManager:updateEntryProgUI()
            if not self.m_bAutoCollect then
                -- 关卡内自己打开的 检查下要不要弹 宝箱升级弹板
                if ClanManager:checkRewardBoxPop() then
                    ClanManager:showRewardBoxPop()
                end
            end
            gLobalDailyTaskManager:setNotifyAddClanPointsEvt(false)
        end

        self:closeMainLayerPopView()

        -- 清空自动收集变量 以免出现非spin情况下在关卡内完成任务还会在出现自动收集特效
        gLobalDailyTaskManager:setAutoColectFlag(false)
    end
    DailyMissionMainLayer.super.closeUI(self, callback)
end

function DailyMissionMainLayer:playBgMusic()
    self.m_perBgMusicName = gLobalSoundManager:getCurrBgMusicName()
    gLobalSoundManager:playBgMusic(DAILYPASS_RES_PATH.PASS_MISSION_BGM_MP3)
end

-- 切换背景音乐
function DailyMissionMainLayer:stopBgMusic()
    if gLobalViewManager:isLobbyView() then
        if self:isQuestLobby() then
            gLobalSoundManager:playBgMusic("Activity/QuestSounds/Quest_bg.mp3")
        else
            --上线兼容使用方式
            local lobbyBgmPath = "Sounds/bkg_lobby_new.mp3"
            if gLobalActivityManager.getLobbyMusicPath then
                lobbyBgmPath = gLobalActivityManager:getLobbyMusicPath()
            end
            gLobalSoundManager:playBgMusic(lobbyBgmPath)
        end
    else
        --关卡中
        if self.m_perBgMusicName then
            gLobalSoundManager:playBgMusic(self.m_perBgMusicName)
            self.m_perBgMusicName = nil
        end
    end
end

function DailyMissionMainLayer:isQuestLobby()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    --串一行
    if questConfig and questConfig.m_isQuestLobby then
        return true
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterQuestLayer() then
        return true
    end
    return false
end


function DailyMissionMainLayer:isShowRefreshBtn()
    if not globalData.missionRunData then
        return false
    end
    if not (globalData.missionRunData.p_refreshGems and globalData.missionRunData.p_refreshGems > 0 and globalData.missionRunData.p_allMissionCompleted == false) then
        return false
    end
    if not (globalData.missionRunData.p_taskInfo and globalData.missionRunData.p_taskInfo.p_taskCompleted == false) then
        return false
    end
    return true
end

function DailyMissionMainLayer:isPassOpen()
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    return not not passActData
end

function DailyMissionMainLayer:clickFunc(_sender)
    if self.m_inAction then
        return
    end
    if self.m_isScrollingToSafeBoxGuide then
        return
    end
    local name = _sender:getName()

    if name == "btn_close" then
        -- 如有有气泡的情况下需要移除
        if G_GetMgr(G_REF.Flower) then
            if G_GetMgr(G_REF.Flower):getWaterHide() == nil then
            elseif not G_GetMgr(G_REF.Flower):getWaterHide() then
                return
            end
        end
        if not self.m_bAutoCollectGuideFlag and not self.m_bIsPushingView and  self:hasPassGuide() then
            return
        end
        if self.m_currPageType == PAGE_TYPE.REWARD_PAGE and not self.m_completeCreatePassTableView then
            return
        end
        self:removeBoxRewardInfo(true)
        self:closeUI()
    elseif name == "btn_info" then
        local infolayer = nil
        if self.m_currPageType == PAGE_TYPE.FLOWER_PAGE then
            infolayer = util_createView("views.FlowerCode_New.FlowerExplainLayer")
        else
            infolayer = util_createView("views.baseDailyMissionCode.DailyMissionInfoLayer")
        end
        gLobalViewManager:showUI(infolayer, ViewZorder.ZORDER_UI)
    end
end


function DailyMissionMainLayer:showTaskRewardQipao(params)
    local giftType = params.giftType
    local pos = cc.p(0, 0)
    local missionTaskData = nil
    local rewardData = nil
    if giftType == "Daily" then
        pos = self.m_missionTaskView:getGiftPos()
    elseif giftType == "Season" then
        pos = self.m_seasonTaskView:getGiftPos()
        rewardData = gLobalDailyTaskManager:getLastTaskData()
    end
    if not rewardData then
        rewardData = gLobalDailyTaskManager:getTaskRewardData(giftType)
    end
    if rewardData and table.nums(rewardData) > 0 then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:removeBoxRewardInfo(true)
        self.uiQipao = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassCellQipao_ThreeLine)
        self:addChild(self.uiQipao)
        self.uiQipao:setPosition(pos)
        if not G_GetMgr(G_REF.Flower) or giftType ~= "Daily" then
            self.uiQipao:showTaskRewardView(rewardData)
            return
        end
        local fl_data = G_GetMgr(G_REF.Flower):getData()
        if fl_data:getOpen() and globalData.userRunData.levelNum >= fl_data:getOpenLevel() and globalData.missionRunData.p_currMissionID == 3 then
            local item = self:buildingFlowerItem()
            if not rewardData.items then
                rewardData.items = {}
            end
            table.insert(rewardData.items, item)
        end
        self.uiQipao:showTaskRewardView(rewardData)
    end
end

function DailyMissionMainLayer:buildingFlowerItem()
    local item = {}
    item.p_activityId = "400001"
    item.p_buff = 0
    item.p_description = "水壶"
    item.p_expireAt = 1672559999000
    item.p_icon = "Reward_pot"
    item.p_id = 880302
    item.p_item = 0
    item.p_limit = 6
    item.p_num = 1
    item.p_mark = {2}
    item.p_type = "Item"
    return item
end

return DailyMissionMainLayer
