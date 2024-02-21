local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_CatteryNode = class("LobbyBottom_CatteryNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_CatteryNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/Activity_DeluxeClubCat.csb")

    self:initView()

    self:initCattery()
    self:refreshTips()
end

function LobbyBottom_CatteryNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
    self.m_djsLabel:setVisible(false)
end

function LobbyBottom_CatteryNode:getBottomName()
    return "KITTENS"
end

function LobbyBottom_CatteryNode:initCattery()
    local bpData = G_GetMgr(ACTIVITY_REF.DeluxeClubCat):getRunningData()
    if not bpData then
        self:showCommingSoon()
        return
    end

    local bLock = globalData.userRunData.levelNum < bpData.p_openLevel
    -- 第一层判断
    if not globalData.deluexeClubData:getDeluexeClubStatus() or bLock then
        self.m_lock:setVisible(true)
        self:updateDownLoad(false)
        self.m_LockState = true
    else
        -- if not globalDynamicDLControl:checkDownloading(ACTIVITY_REF.BattlePass) then
        --     self.m_timeBg:setVisible(true)
        --     self:showDownTimer()
        -- end
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
function LobbyBottom_CatteryNode:refreshTips()
    local bpData = G_GetMgr(ACTIVITY_REF.DeluxeClubCat):getRunningData()
    if not bpData then
        return
    end

    local count = bpData:getTotalFoodCount()
    if count > 0 then
        self.m_labelActivityNums:setString(count)
        util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
    else
        self.m_spRedPoint:setVisible(false)
    end
end

-- 节点特殊处理逻辑 --
function LobbyBottom_CatteryNode:clickLobbyNode()
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

    if globalDynamicDLControl:checkDownloading(ACTIVITY_REF.DeluxeClubCat) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    G_GetMgr(ACTIVITY_REF.DeluxeClubCat):showMainLayer(true)
    self:openLayerSuccess()
end

function LobbyBottom_CatteryNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

--显示倒计时
function LobbyBottom_CatteryNode:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function LobbyBottom_CatteryNode:updateLeftTime()
    local bpData = G_GetMgr(ACTIVITY_REF.DeluxeClubCat):getRunningData()
    if not bpData then
        self:stopTimerAction()
        self:showCommingSoon()
        return
    end
    if not globalData.deluexeClubData:getDeluexeClubStatus() then
        self:stopTimerAction()
        self.m_lock:setVisible(true)
        self.m_timeBg:setVisible(false)
        self.m_djsLabel:setVisible(false)
        self.m_spRedPoint:setVisible(false)
        self.m_LockState = true
        return
    end
    local expireAt = bpData:getExpireAt()
    local leftTime = math.max(expireAt, 0)
    local dayStr = util_daysdemaining(leftTime)
    self.m_djsLabel:setString(dayStr)

    -- 监听当前奖励数量变化
    self:refreshTips()
end

function BaseLobbyNodeUI:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function LobbyBottom_CatteryNode:showCommingSoon()
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
function LobbyBottom_CatteryNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)
end

function LobbyBottom_CatteryNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

-- 下载 相关回调 ---
function LobbyBottom_CatteryNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/Kittens_logo1.png"
end

function LobbyBottom_CatteryNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_CatteryNode:getDownLoadKey()
    return "Activity_DeluxeClub_Cat"
end

function LobbyBottom_CatteryNode:endProcessFunc()
    self:initCattery()
end

-- 获取活动引用名
function LobbyBottom_CatteryNode:getActRefName()
    return ACTIVITY_REF.DeluxeClubCat
end

return LobbyBottom_CatteryNode
