local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_LeagueNode = class("LobbyBottom_LeagueNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_LeagueNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/Activity_LeagueLobbyNode.csb")

    self:initView()

    -- 特殊组件
    self.m_label_battlepass_num = self:findChild("label_battlepass_num")
    -- self.m_sprite_battlepass_tip = self:findChild("sprite_battlepass_tip")

    self:initLeague()
    self:refreshTips()
end

function LobbyBottom_LeagueNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
end

function LobbyBottom_LeagueNode:getBottomName()
    return "LEAGUES"
end

function LobbyBottom_LeagueNode:initLeague()
    local openLevel = globalData.constantData.LEAGUE_OPEN_LEVEL or 35 --解锁等级
    local leagueData = G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():getData()
    if leagueData then
        self.m_openLevel = leagueData:getOpenLevel()
    else
        self.m_openLevel = openLevel
    end
    self.m_unlockValue:setString(self.m_openLevel)

    if not leagueData or not leagueData:isRunning() then
        self:showCommingSoon()
        if globalData.userRunData.levelNum < openLevel then
            self.m_LockState = true -- 特殊处理 如果当前等级未满足开启,优先展示等级tips
        end
        return
    end

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

        if G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():isDownloadRes() then
            self.m_timeBg:setVisible(true)
            self:showDownTimer()
        end
    end
end

-- 接受消息刷新红点数字奖励
function LobbyBottom_LeagueNode:refreshTips()
    local leagueData = G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():getRunningData()
    if not leagueData or not leagueData:isRunning() then
        return
    end

    -- local canClaimNum = bpData:getCanClaimNum()
    -- if canClaimNum > 0 then
    --     self.m_sprite_battlepass_tip:setVisible(true)
    --     self.m_label_battlepass_num:setString(canClaimNum)
    -- else
    --     self.m_sprite_battlepass_tip:setVisible(false)
    -- end
end

-- 节点特殊处理逻辑 --
function LobbyBottom_LeagueNode:clickLobbyNode()
    self:removeDownloadGuide(true)
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

    if not G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():isDownloadRes() then
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():showMainLayer()
    self:openLayerSuccess()

    -- 发送点击事件 关闭merge node 节点
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_MERGE_NODE_CLICK)
    -- 发送点击事件 关闭扩展栏
end

function LobbyBottom_LeagueNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

function LobbyBottom_LeagueNode:updateLeftTime()
    local leagueData = G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():getRunningData()
    if not leagueData or not leagueData:isRunning() then
        self:stopTimerAction()
        self:showCommingSoon()
        return
    end
    local expireAt = leagueData:getExpireAt()
    local leftTime = math.max(expireAt, 0)
    local dayStr = util_daysdemaining(leftTime, true)
    self.m_djsLabel:setString(dayStr)

    -- 监听当前奖励数量变化
    self:refreshTips()
end

function LobbyBottom_LeagueNode:removeDownloadGuide(removeCallBackFlag)
    local nodeParentInfo = self.nodeParentInfo
    if nodeParentInfo ~= nil then
        util_changeNodeParent(nodeParentInfo.parentNode, self, nodeParentInfo.zOrder)
        self:setPosition(nodeParentInfo.pos)
        self.nodeParentInfo = nil
    end
    if self.downloadGuideNode ~= nil then
        self.downloadGuideNode:removeFromParent()
        self.downloadGuideNode = nil
    end
    if removeCallBackFlag then
        gLobalDataManager:setBoolByField("BattlePass_LobbyNode_Login_Guide", true)
    end
end

function LobbyBottom_LeagueNode:showCommingSoon()
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
    -- self.m_sprite_battlepass_tip:setVisible(false)
    self:updateDownLoad(false)
end
-- onEnter
function LobbyBottom_LeagueNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)
end

function LobbyBottom_LeagueNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

-- 下载 相关回调 ---
function LobbyBottom_LeagueNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/leagueA_node.png"
end

function LobbyBottom_LeagueNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_LeagueNode:getDownLoadKey()
    local dlKey = G_GetMgr(G_REF.LeagueCtrl):getLobbyBtCheckDLKey()
    return dlKey
end

function LobbyBottom_LeagueNode:endProcessFunc()
    self:initLeague()
    -- self:createDownloadGuide()
end

-- 获取活动引用名
function LobbyBottom_LeagueNode:getActRefName()
    -- return ACTIVITY_REF.League
    return self:getDownLoadKey()
end

return LobbyBottom_LeagueNode
