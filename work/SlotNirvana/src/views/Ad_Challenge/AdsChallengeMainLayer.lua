--[[
    广告激励相关
]]

local BaseLayer = util_require("base.BaseLayer")
local AdsChallengeMainLayer = class("AdsChallengeMainLayer", BaseLayer)

function AdsChallengeMainLayer:ctor()
    AdsChallengeMainLayer.super.ctor(self)

    self.m_isPauseSlotsEnabled = true
    
    self:setLandscapeCsbName("Ad_Challenge/csb/Ad_Challenge_MainUi.csb")
    self:setPortraitCsbName("Ad_Challenge/csb/Ad_Challenge_MainUi_Shu.csb")

    self:setExtendData("AdsChallengeMainLayer")
    self:logADPush()
end

function AdsChallengeMainLayer:initDatas(_overCallback)
    self.m_overCallback = _overCallback
end

function AdsChallengeMainLayer:initCsbNodes()
    self.m_root = self:findChild("root")
    self.m_node_video = self:findChild("node_video")
    self.m_node_tips = self:findChild("node_tips")
    
    self.m_AllCellNode = {}
    self.m_AllProgressCellNode = {}
    for i=1,3 do
        self.m_AllCellNode[i] = self:findChild("node_cell"..i)
        self.m_AllProgressCellNode[i] = self:findChild("node_progressCell"..i)
    end
    
    self.m_txt_time= self:findChild("txt_time")

    self.m_btnClose = self:findChild("btn_close")
end

function AdsChallengeMainLayer:initView()
    local data  = globalData.AdChallengeData
    data:setAddCount(1)
    self.m_taskCellNodeVec = {}
    for i=1,3 do
        local rewardTaskData = data.m_stageReward[i]

        local taskCellNode = util_createView("views.Ad_Challenge.AdsChallengeTaskCellNode",self.m_isShownAsPortrait)
        taskCellNode:updateData(rewardTaskData)
        self.m_AllCellNode[i]:addChild(taskCellNode)
        self.m_taskCellNodeVec[i] = taskCellNode
    end

    self:updateLeftTimeUI()

    self:startButtonAnimation("btn_ok", "sweep")

    self:initVideoShow()
    self:initTips()
end

function AdsChallengeMainLayer:updetaView()
    local data  = globalData.AdChallengeData
    for i = 1, 3 do
        local rewardTaskData = data.m_stageReward[i]
        local taskCellNode = self.m_taskCellNodeVec[i]
        taskCellNode:doTaskComplete(rewardTaskData)
    end
    -- 看完广告后 会自动打这个点 无需重复打
    if gLobalAdChallengeManager:isDoAction() then
        -- globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.AdMission}, nil, "playfinish")
        self:doProgressAction()
    end
end

function AdsChallengeMainLayer:initTips()
    local tipsNode = util_createAnimation("Ad_Challenge/csb/Ad_Challenge_Tips.csb")
    if self.m_node_tips and tipsNode then
        self.m_node_tips:addChild(tipsNode)
        tipsNode:setVisible(false)
        self.m_tipsNode = tipsNode
    end
end

function AdsChallengeMainLayer:initVideoShow()
    local videoShowNode = util_createAnimation("Ad_Challenge/csb/Ad_video_show.csb")
    if videoShowNode then
        self.m_node_video:addChild(videoShowNode)
        videoShowNode:setVisible(false)
        self.m_videoShowNode = videoShowNode
    end
end

function AdsChallengeMainLayer:doProgressAction()
    self.m_doProgressAction = true
    if not self.m_videoShowNode then
        self:initVideoShow()
    end
    self.m_videoShowNode:setVisible(true)
    self.m_videoShowNode:activityShow(self.m_videoShowNode, function()
        self.m_videoShowNode:playAction("idle", false, function()
            self.m_videoShowNode:maskHide(15 / 60)
            for i=1, #self.m_taskCellNodeVec do
                local taskCellNode = self.m_taskCellNodeVec[i]
                local pos = taskCellNode:getVideoIconPos()
                if pos then
                    pos = self.m_node_video:convertToNodeSpace(pos)
                    local actionList = {}
                    actionList[#actionList + 1] = cc.MoveTo:create(0.3, pos)
                    local seq = cc.Sequence:create(actionList)
                    local actionList2 = {}
                    actionList2[#actionList2 + 1] = cc.ScaleTo:create(0.3, 0.3)
                    actionList2[#actionList2 + 1] = cc.CallFunc:create(function()
                        if not tolua.isnull(self.m_videoShowNode) then
                            self.m_videoShowNode:removeFromParent()
                            self.m_videoShowNode = nil
                        end
                        self.m_doProgressAction = false
                        taskCellNode:refreshUI()
                        if gLobalAdChallengeManager:willDoComplete() then
                            self:afterDoProgress()
                        end
                        local curPoint = globalData.AdChallengeData:getCurrentWatchCount()
                        globalData.AdChallengeData:setLastWatchCount(curPoint)
                    end)
                    local seq2 = cc.Sequence:create(actionList2)
                    local spawn = cc.Spawn:create(seq, seq2)
                    self.m_videoShowNode:runAction(spawn)
                end
            end
        end, 60)
    end)
end

function AdsChallengeMainLayer:afterDoProgress()
    gLobalAdChallengeManager:sendCollectReward()
end

function AdsChallengeMainLayer:afterGetReward()
    local data  = globalData.AdChallengeData
    for i = 1, 3 do
        local rewardTaskData = data.m_stageReward[i]
        local taskCellNode = self.m_taskCellNodeVec[i]
        taskCellNode:doTaskComplete(rewardTaskData)
    end
end

function AdsChallengeMainLayer:updateLeftTimeUI()
    local leftTime = util_get_today_lefttime()
    if leftTime < 0 then
        -- if not self:isShowing() and not self:isHiding() then
        --     self:clearScheduler()
            self:closeUI()
        -- end
        return
    end
    if self.m_txt_time then
        self.m_txt_time:setString(util_count_down_str(leftTime))
    end
end

function AdsChallengeMainLayer:clickFunc(_sender)
    if self.m_doProgressAction then
        return
    end

    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_ok" then
        if self.m_isTips then
            if self.m_isShowTips then
                return
            end
            self.m_isShowTips = true
            self.m_tipsNode:setVisible(true)
            self.m_tipsNode:playAction("show", false, function()
                self.m_tipsNode:setVisible(false)
                self.m_isShowTips = false
            end, 60)
            return
        end
        self.m_isTips = true
        globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.AdMission}, nil, "click")
        gLobalAdsControl:playRewardVideo(PushViewPosType.LobbyPos, PushViewPosType.AdMission)
    end
end

function AdsChallengeMainLayer:onEnter()
    AdsChallengeMainLayer.super.onEnter(self)

    self.m_scheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
end

function AdsChallengeMainLayer:registerListener()
    AdsChallengeMainLayer.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if data.success then
                self:afterGetReward()
                self:showRewardView(data.result)
            end
        end,
        ViewEventType.NOTIFY_ADSTASK_COLLECT_REWARDS
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            self:setHideActionEnabled(false)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_ADSTASK_FORCE_CLOSE
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            self.m_isTips = false
        end,
        ViewEventType.NOTIFY_ADCHALLENGE_LOAD_STATE
    )
end

function AdsChallengeMainLayer:onShowedCallFunc()
    AdsChallengeMainLayer.super.onShowedCallFunc(self)
    self:runCsbAction("idle", true)
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.AdMission}, nil, "trigger")
    if gLobalAdChallengeManager:isDoAction() then
        self:doProgressAction()
    else
        if gLobalAdChallengeManager:willDoComplete() then
            self:afterDoProgress()
        end
    end
end


function AdsChallengeMainLayer:showRewardView(rewards)
    local uiView = util_createView("views.Ad_Challenge.AdsChallengeRewardLayer",rewards)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
end

function AdsChallengeMainLayer:onExit()
    AdsChallengeMainLayer.super.onExit(self)
    self:clearScheduler()
end

--停掉定时器
function AdsChallengeMainLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
    -- if self.timeSchedule then
    --     self:stopAction(self.timeSchedule)
    --     self.timeSchedule = nil
    -- end
    -- if self.m_scheduler_progress then
    --     self:stopAction(self.m_scheduler_progress)
    --     self.m_scheduler_progress = nil
    -- end
end

function AdsChallengeMainLayer:closeUI()
    if self:isShowing() or self:isHiding() then
        return
    end
    self:clearScheduler()
    AdsChallengeMainLayer.super.closeUI(
        self,
        function()
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            if self.m_overCallback then
                self.m_overCallback()
            end
        end
    )
end

function AdsChallengeMainLayer:logADPush()
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.AdMission)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
end

return AdsChallengeMainLayer
