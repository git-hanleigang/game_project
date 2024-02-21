local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_MergeNode = class("LobbyBottom_MergeNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_MergeNode:initUI(data)
    self.m_showActTimeMacro = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):geShowActEndTimeMacro()

    -- 这里需要改成正式的
    self:createCsbNode("Activity_LobbyIconRes/Activity_DeluxeClubMerge.csb")

    self:initView()

    self:initIconUI()
    self:refreshTips()
    -- 有下载节点的时候，记得要去这里注册下载广播
    -- BaseDLControl.kPercentBroadMsgMap
end

function LobbyBottom_MergeNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
    self.m_djsLabel:setVisible(false)
end

function LobbyBottom_MergeNode:getBottomName()
    return "MERGE"
end

function LobbyBottom_MergeNode:initIconUI()
    local act_data = self:getData()
    if not act_data then
        self:showCommingSoon()
        return
    end

    local bLock = globalData.userRunData.levelNum < act_data.p_openLevel
    -- 第一层判断
    if not globalData.deluexeClubData:getDeluexeClubStatus() or bLock then
        self.m_lock:setVisible(true)
        self:updateDownLoad(false)
        self.m_LockState = true
    else
        self.m_lock:setVisible(false)
        self:updateDownLoad(true)
        self.m_LockState = false
        self.m_lockIocn:setVisible(false)
        self.m_timeBg:setVisible(true)
        self.m_djsLabel:setVisible(true)
        self.m_spRedPoint:setVisible(true)
        self:showDownTimer()
    end
end

-- 接受消息刷新红点数字奖励
function LobbyBottom_MergeNode:refreshTips()
    local act_data = self:getData()
    if not act_data then
        self.m_spRedPoint:setVisible(false)
        return
    end

    local count = act_data:getActRedDotCount()
    if count > 0 then
        self.m_labelActivityNums:setString(count)
        util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
        self.m_spRedPoint:setVisible(true)
    else
        self.m_spRedPoint:setVisible(false)
    end
end

-- 节点特殊处理逻辑 --
function LobbyBottom_MergeNode:clickLobbyNode()
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

    if globalDynamicDLControl:checkDownloading(ACTIVITY_REF.DeluxeClubMergeActivity) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):tryEnterMergeMainView()

    self:openLayerSuccess()
end

function LobbyBottom_MergeNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

--显示倒计时
function LobbyBottom_MergeNode:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function LobbyBottom_MergeNode:updateLeftTime()
    local act_data = self:getData()
    if not act_data then
        self:stopTimerAction()
        self:showCommingSoon()
        return
    end

    -- 监听当前奖励数量变化
    self:refreshTips()

    if not globalData.deluexeClubData:getDeluexeClubStatus() then
        self:stopTimerAction()
        self.m_lock:setVisible(true)
        self.m_timeBg:setVisible(false)
        self.m_djsLabel:setVisible(false)
        -- self.m_spRedPoint:setVisible(false)
        self.m_LockState = true
        return
    end

    local expireAt = act_data:getExpireAt()
    local leftTime = math.max(expireAt, 0)
    local dayStr = util_daysdemaining(leftTime)
    self.m_djsLabel:setString(dayStr)

    if self.m_timeBg:isVisible() then
        local leftTime = math.floor(act_data:getLeftTime())
        self.m_timeBg:setVisible(leftTime <= self.m_showActTimeMacro)
    end
end

function BaseLobbyNodeUI:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function LobbyBottom_MergeNode:showCommingSoon()
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
    self.m_spRedPoint:setVisible(false)
    self:updateDownLoad(false)
end
-- onEnter
function LobbyBottom_MergeNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)
end

function LobbyBottom_MergeNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

-- 下载 相关回调 ---
function LobbyBottom_MergeNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/merge_node.png"
end

function LobbyBottom_MergeNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_MergeNode:getDownLoadKey()
    return "Activity_DeluxeClub_Merge"
end

function LobbyBottom_MergeNode:endProcessFunc()
    self:initIconUI()
end

-- 获取活动引用名
function LobbyBottom_MergeNode:getActRefName()
    return ACTIVITY_REF.DeluxeClubMergeActivity
end

function LobbyBottom_MergeNode:getData()
    local act_data = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):getRunningData()
    if act_data and act_data:isRunning() then
        return act_data
    end
end

return LobbyBottom_MergeNode
