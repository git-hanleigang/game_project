local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_ChallengeNode = class("LobbyBottom_ChallengeNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_ChallengeNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomChallengeNode.csb")

    self:initView()

    self:initChallenge()
end

-- function LobbyBottom_ChallengeNode:initView( )

-- end

function LobbyBottom_ChallengeNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
end

function LobbyBottom_ChallengeNode:initChallenge()
    self.m_openLevel = globalData.constantData.CHALLENGE_OPEN_LEVEL

    self.m_nodeChallengeLoad = self:findChild("downLoadNode")
    self.m_tipsNode_comingsoon = self:findChild("tipsNode_comingsoon")
    self.m_tipsNode_downloading = self:findChild("tipsNode_downloading")
    self.m_challenge_msg_0 = self:findChild("challenge_msg_0")
    self.m_tipsNode_comingsoon:setVisible(false)
    self.m_tipsNode_downloading:setVisible(false)

    self:showChallengeBtn()
end

function LobbyBottom_ChallengeNode:showChallengeBtn()
    self:findChild("sprite_challenge_tip"):setVisible(false)
    self.m_timeBg:setVisible(false)
    self.m_lockIocn:setVisible(false)

    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()

    if luckyChallengeData then
        self:showDownTimer()
    end

    --下载
    -- 等级
    -- 是否开放
    self.m_unlockValue:setString(self.m_openLevel)

    if globalData.userRunData.levelNum < self.m_openLevel then
        self.m_LockState = true
        self:updateDownLoad(false)
        self.m_lock:setVisible(true)
        -- self.m_lockIocn:setVisible(true)
    else
        self.m_LockState = false
        local isDown = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):isDownloadRes()
        if isDown then -- 已经下载好了
            if luckyChallengeData then
                self:showChallengeRedPoint()
                self.m_lock:setVisible(false)
                self.m_timeBg:setVisible(true)
                self.m_lockIocn:setVisible(false)
            else --赛季间 下载好了 无数据的话
                self:showCommingSoon()
            end
        else -- 还未下载完成
            if luckyChallengeData then
                self.m_timeBg:setVisible(false)
                --小锁
                self.m_lock:setVisible(false)
                --红点
                self:findChild("sprite_challenge_tip"):setVisible(false)

                self.m_lockIocn:setVisible(false) -- 未开放的背景 配合小锁使用
                self.m_nodeChallengeLoad:setVisible(true)
            else
                self:showCommingSoon()
            end
        end
    end

    self.m_challenge_msg_0:setVisible(false)
end

function LobbyBottom_ChallengeNode:getBottomName()
    return "CHALLENGE"
end

-- 节点特殊处理逻辑 --
function LobbyBottom_ChallengeNode:clickLobbyNode(sender)
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips()
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_comingsoon)
        return
    end

    if not G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):isDownloadRes() then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end
    -- self:findChild("Button_1"):setEnabled(false)
    -- performWithDelay(
    --     self,
    --     function()
    --         self:findChild("Button_1"):setEnabled(true)
    --     end,
    --     1
    -- )
    gLobalSendDataManager:getLogIap():setLCEnterOpen("tapOpen", "challengeIcon")
    G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):showMainLayer(nil, sender:getTouchEndPosition())

    self:openLayerSuccess()

    -- -- 发送点击事件 关闭merge node 节点
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_MERGE_NODE_CLICK)
end

function LobbyBottom_ChallengeNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

--显示倒计时
function LobbyBottom_ChallengeNode:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateChallengeSeasonTime), 1)
    self:updateChallengeSeasonTime()
end

function LobbyBottom_ChallengeNode:updateChallengeSeasonTime()
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData then
        local str_time, isOver = util_daysdemaining(luckyChallengeData:getExpireAt(), true)
        local leftLb = self.m_djsLabel
        if not isOver then
            leftLb:setString(str_time)
            self:updateLabelSize({label = leftLb}, 85)
        end
    else
        self:stopTimerAction()

        self.m_timeBg:setVisible(false)
        self:findChild("sprite_challenge_tip"):setVisible(false)
        performWithDelay(
            self,
            function()
                self:showChallengeBtn()
            end,
            2
        )
    end
end

function LobbyBottom_ChallengeNode:showChallengeRedPoint()
    local tip_bg = self:findChild("sprite_challenge_tip")
    local lb_num = self:findChild("label_challenge_num")
    if tip_bg and lb_num then
        local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
        if luckyChallengeData then
            local redNum = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getAllRed()
            if redNum and redNum > 0 then
                lb_num:setString(redNum)
                tip_bg:setVisible(true)
                util_scaleCoinLabGameLayerFromBgWidth(lb_num, 26)
            else
                tip_bg:setVisible(false)
            end
        else
            tip_bg:setVisible(false)
        end
    end
end

--刷新luckyChallenge按钮状态
function LobbyBottom_ChallengeNode:updateChallengeResStatus()
    -- self.m_nodeChallengeLoad:setVisible(false)
    self:removeDownLoadProcess() -- 调用父类删除调度条
    self:showChallengeBtn()
end

-- function LobbyBottom_ChallengeNode:openLuckyChallengeTip()
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_TOPDOWN_ZORDER,true)
--     local viewTip = util_createView("Activity.Logic.LuckyChallengeOpenTip")
--     self:findChild("luckyChallenge_tip"):addChild(viewTip)
-- end

-- function LobbyBottom_ChallengeNode:openLuckyChallengeMissionTip()
--     local msg_challenge = self:findChild("challenge_msg_0")
--     msg_challenge:setVisible(true)
--     local randomIndex = math.random(1,3)
--     for i=1,3 do
--         self:findChild("lc_missionTip"..i):setVisible(randomIndex==i)
--     end
--     gLobalViewManager:addAutoCloseTips(msg_challenge,function()
--         msg_challenge:setVisible(false)
--     end)
-- end

function LobbyBottom_ChallengeNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function LobbyBottom_ChallengeNode:showCommingSoon()
    -- 主要用作于活动结束之后 切换成commingSoon 界面
    if self.m_LockState then
        self.m_LockState = false
    end
    self.m_commingSoon = true
    self.m_tips_msg:setVisible(false)
    self.m_tips_commingsoon_msg:setVisible(false)
    self.m_lock:setVisible(true)
    self.m_timeBg:setVisible(false)
    self.m_sp_new:setVisible(false)
    self:updateDownLoad(false)
end

-- 下载 相关回调 ---
function LobbyBottom_ChallengeNode:getProgressPath()
    return "Activity_LobbyIconRes/lobbyNode/map_btn_challenge_down.png"
end

function LobbyBottom_ChallengeNode:getDownLoadingNode()
    return self.m_nodeChallengeLoad
end

function LobbyBottom_ChallengeNode:getDownLoadKey()
    return ACTIVITY_REF.NewDiamondChallenge
end

function LobbyBottom_ChallengeNode:endProcessFunc()
    self:updateChallengeResStatus()
end

-- onEnter
function LobbyBottom_ChallengeNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)

    -- gLobalNoticManager:addObserver(self,function(self,params)

    --     if params.id == NOVICEGUIDE_ORDER.luckyChallengeTip.id then
    --             self:openLuckyChallengeTip()
    --     elseif params.id == NOVICEGUIDE_ORDER.luckyChallengeMissionTip.id then
    --         self:openLuckyChallengeMissionTip()
    --     end

    -- end,ViewEventType.NOTIFY_NOVICEGUIDE_SHOW)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showChallengeRedPoint()
        end,
        ViewEventType.NOTIFY_LC_UPDATE_VIEW
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showChallengeRedPoint()
        end,
        ViewEventType.NOTIFY_NDC_TASK_RED
    )
end

function LobbyBottom_ChallengeNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

-- 获取活动引用名
function LobbyBottom_ChallengeNode:getActRefName()
    return ACTIVITY_REF.NewDiamondChallenge
end

return LobbyBottom_ChallengeNode
