local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_BattlePassNode = class("LobbyBottom_BattlePassNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_BattlePassNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomBattlePassNode.csb")

    self:initView()

    -- 特殊组件
    self.m_label_battlepass_num = self:findChild("label_battlepass_num")
    self.m_sprite_battlepass_tip = self:findChild("sprite_battlepass_tip")

    self:initBattlePass()
    self:refreshTips()
end

-- function LobbyBottom_BattlePassNode:initView( )

-- end

function LobbyBottom_BattlePassNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
end

function LobbyBottom_BattlePassNode:getBottomName()
    return "PASS"
end

function LobbyBottom_BattlePassNode:initBattlePass()
    local openLevel = globalData.constantData.BATTLEPASS_OPEN_LEVEL or 25 --解锁等级
    self.m_unlockValue:setString(openLevel)

    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData or not bpData:isRunning() then
        self:showCommingSoon()
        if globalData.userRunData.levelNum < openLevel then
            self.m_LockState = true -- 特殊处理 如果当前等级未满足开启,优先展示等级tips
        end
        return
    end

    self.m_openLevel = openLevel
    local curLevel = globalData.userRunData.levelNum
    -- 第一层判断
    if globalData.userRunData.levelNum < openLevel then
        self.m_lock:setVisible(true)
        self:updateDownLoad(false)
        self.m_LockState = true
    else
        self.m_lock:setVisible(false)
        self:updateDownLoad(true)
        self.m_LockState = false

        if not globalDynamicDLControl:checkDownloading(ACTIVITY_REF.BattlePass) then
            self.m_timeBg:setVisible(true)
            self:showDownTimer()
        end
    end
end

-- 接受消息刷新红点数字奖励
function LobbyBottom_BattlePassNode:refreshTips()
    -- self.m_label_battlepass_num
    -- self.m_sprite_battlepass_tip
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData or not bpData:isRunning() then
        return
    end

    local canClaimNum = bpData:getCanClaimNum()
    if canClaimNum > 0 then
        self.m_sprite_battlepass_tip:setVisible(true)
        self.m_label_battlepass_num:setString(canClaimNum)
    else
        self.m_sprite_battlepass_tip:setVisible(false)
    end
end

-- 节点特殊处理逻辑 --
function LobbyBottom_BattlePassNode:clickLobbyNode()
    -- self:removeDownloadGuide(true)
    --
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips()
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end
    if globalDynamicDLControl:checkDownloading(ACTIVITY_REF.BattlePass) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    local battlePassMainUi = util_createView("Activity.BattlePassCode.BattlePassMainLayer")
    gLobalViewManager:showUI(battlePassMainUi)
    self:openLayerSuccess()
end

function LobbyBottom_BattlePassNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

function LobbyBottom_BattlePassNode:updateLeftTime()
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData or not bpData:isRunning() then
        self:stopTimerAction()
        self:showCommingSoon()
        return
    end
    local expireAt = bpData:getExpireAt()
    local leftTime = math.max(expireAt, 0)
    local dayStr = util_daysdemaining(leftTime)
    self.m_djsLabel:setString(dayStr)

    -- 监听当前奖励数量变化
    self:refreshTips()
end

function LobbyBottom_BattlePassNode:showCommingSoon()
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
    self.m_sprite_battlepass_tip:setVisible(false)
    self:updateDownLoad(false)
end
-- onEnter
function LobbyBottom_BattlePassNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)

    -- 领取宝箱
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:refreshTips()
        end,
        ViewEventType.EVENT_BATTLE_PASS_COLLECT_BOX_SUCCESS
    )

    -- self.popViewCount = 0
    -- gLobalNoticManager:addObserver(
    -- self,
    -- function(sender, params)
    --     self.popViewCount = self.popViewCount + 1
    --     if not tolua.isnull(self) then
    --         self:removeDownloadGuide(false)
    --         addExitListenerNode(
    --             params.node,
    --             function()
    --                 if not tolua.isnull(self) then
    --                     self.popViewCount = self.popViewCount - 1
    --                     util_afterDrawCallBack(
    --                     function()
    --                         if not tolua.isnull(self) then
    --                             self:createDownloadGuide()
    --                         end
    --                     end)
    --                 end
    --             end
    --         )
    --     end
    -- end,
    -- ViewEventType.NOTIFY_SHOW_UI)

    -- gLobalNoticManager:addObserver(
    -- self,
    -- function(sender, params)
    --     if not tolua.isnull(self) then
    --         self:createDownloadGuide()
    --     end
    -- end,
    -- ViewEventType.NOTIFY_LOBBYNODE_BATTLEPASS)
end

function LobbyBottom_BattlePassNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

-- 下载 相关回调 ---
function LobbyBottom_BattlePassNode:getProgressPath()
    return "Activity_LobbyIconRes/lobbyNode/map_btn_battlepass_down.png"
end

function LobbyBottom_BattlePassNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_BattlePassNode:getDownLoadKey()
    return "Activity_BattlePass"
end

function LobbyBottom_BattlePassNode:endProcessFunc()
    self:initBattlePass()
    -- self:createDownloadGuide()
end

return LobbyBottom_BattlePassNode
