--[[
    author:JohnnyFred
    time:2019-12-25 15:07:56
]]
local BaseDownLoadNodeUI = util_require("baseActivity.BaseDownLoadNodeUI")
local BaseLobbyNodeUI = class("BaseLobbyNodeUI", BaseDownLoadNodeUI)
BaseLobbyNodeUI.m_commingSoon = false

function BaseLobbyNodeUI:initUI(data)
    BaseDownLoadNodeUI.initUI(self, data)

    -- 点击log数据
    self.m_logFuncClickInfo = {}

    self.m_curActivityId = ""
    if data and data.activityId then
        self.m_curActivityId = data.activityId
    end

    self.m_isBottomExtra = false
    if data and data.isBottomExtra then
        self.m_isBottomExtra = true
    end

    self:initView()
end

function BaseLobbyNodeUI:setLogFuncClickInfo(info)
    self.m_logFuncClickInfo = info or {}
end

function BaseLobbyNodeUI:initView()
    self.m_timeBg = self:findChild("timebg")
    self.m_djsLabel = self:findChild("timeValue")
    self.m_lock = self:findChild("lock")
    self.m_tips_msg = self:findChild("tipsNode")
    self.m_tips_msg:setVisible(false)
    self.m_unlockValue = self:findChild("unlockValue")

    self.m_lockIocn = self:findChild("lockIcon") -- 锁定icon
    if self.m_lockIocn then
        self.m_lockIocn:setVisible(false)
    end
    self.m_spRedPoint = self:findChild("spRedPoint") -- 红点的底
    if self.m_spRedPoint then
        self.m_spRedPoint:setVisible(false)
    end
    self.m_labelActivityNums = self:findChild("labelActivityNums") -- 红点的次数

    self.btnFunc = self:findChild("Button_1")
    if self.btnFunc then
        self.btnFunc:setSwallowTouches(false)
    end
    self.m_btnSpecial = self:findChild("Button_2")
    if self.m_btnSpecial then -- 如果存在两个按钮 第二个需要隐藏
        self.m_btnSpecial:setVisible(false)
        self.m_btnSpecial:setSwallowTouches(false)
    end

    self.m_sp_new = self:findChild("sp_new")
    if self.m_sp_new then
        self.m_sp_new:setVisible(false)
    end

    self.m_nodeSizePanel = self:findChild("node_sizePanel")
    self.m_tips_commingsoon_msg = self:findChild("tipsNode_comingsoon")
    self.m_tipsNode_downloading = self:findChild("tipsNode_downloading")
    if self.m_tips_commingsoon_msg then
        self.m_tips_commingsoon_msg:setVisible(false)
    end
    if self.m_tipsNode_downloading then
        self.m_tipsNode_downloading:setVisible(false)
    end

    self:updateView()
end

function BaseLobbyNodeUI:updateUiByDeluxe(bOpenDeluxe)
    local nodeName = self:findChild("name")
    local fntPath = "Activity_LobbyIconRes/lobbyNode/font_name.fnt"
    if bOpenDeluxe then
        fntPath = "Activity_LobbyIconRes/lobbyNode/font_name2.fnt"
    end

    if nodeName then
        nodeName:setFntFile(fntPath)
    end
end

--刷新界面
function BaseLobbyNodeUI:updateView()
    --解锁等级
    local unLockLevel = self:getSysOpenLv()
    if not tolua.isnull(self.m_unlockValue) then
        self.m_unlockValue:setString(unLockLevel)
    end

    local lobbyNodeNewIconKey = self:getLobbyNodeNewIconKey()
    local newCount = 0
    if lobbyNodeNewIconKey ~= nil and lobbyNodeNewIconKey ~= "" then
        newCount = gLobalDataManager:getNumberByField(lobbyNodeNewIconKey, 0)
    end
    local curLevel = globalData.userRunData.levelNum
    print("curLevel-----",curLevel)
    print("unLockLevel-----",unLockLevel)
    if curLevel < unLockLevel then
        self.m_timeBg:setVisible(false)
        self.m_lock:setVisible(true)

        self.m_LockState = true
        -- self.m_lockIocn:setVisible(true) -- 锁定icon
        -- self.btnFunc:setOpacity(0)
        self.m_sp_new:setVisible(false)
        self:updateDownLoad(false)
    else
        if lobbyNodeNewIconKey ~= nil and lobbyNodeNewIconKey ~= "" then
            self.m_timeBg:setVisible(newCount >= 3)
        else
            self.m_timeBg:setVisible(true)
        end
        self.m_lock:setVisible(false)

        self.m_LockState = false
        -- self.m_lockIocn:setVisible(false) -- 锁定icon
        self.btnFunc:setOpacity(255)
        if lobbyNodeNewIconKey ~= nil and lobbyNodeNewIconKey ~= "" then
            self.m_sp_new:setVisible(newCount < 3)
        end
        self:updateDownLoad(true)
        self:showDownTimer()
    end
end

function BaseLobbyNodeUI:showCommingSoon()
    -- 主要用作于活动结束之后 切换成commingSoon 界面
    -- 如果当前等级小于活动等级 。但是活动已经关闭的情况下 显示comming soon
    if self.m_LockState then
        self.m_LockState = false
    end
    self.m_commingSoon = true
    self.btnFunc:setOpacity(255)
    self.m_tips_msg:setVisible(false)
    self.m_tips_commingsoon_msg:setVisible(false)
    self.m_lockIocn:setVisible(false) -- 锁定icon
    self.m_lock:setVisible(true)
    self.m_timeBg:setVisible(false)
    self:findChild("name"):setString("COMING SOON")
    self:updateDownLoad(false)
end

--显示倒计时
function BaseLobbyNodeUI:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function BaseLobbyNodeUI:updateLeftTime()
    local gameData = self:getGameData()
    if gameData ~= nil and gameData:isRunning() then
        self.m_lock:setVisible(false)
        self.m_timeBg:setVisible(true)
        local strLeftTime = util_daysdemaining(gameData:getExpireAt(), true)
        self.m_djsLabel:setString(strLeftTime)
    else
        self:closeLobbyNode()
        self:stopTimerAction()
    end
end

function BaseLobbyNodeUI:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

--活动结束，关闭入口
function BaseLobbyNodeUI:closeLobbyNode()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FIND_CLOSE, self:getDownLoadRelevancyKey())
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, self.m_curActivityId)
end

function BaseLobbyNodeUI:showTips(tips)
    if tips == nil then
        tips = self.m_tips_msg
    end
    if tips:isVisible() then
        tips:setVisible(false)
        return
    end
    tips:setVisible(true)
    gLobalViewManager:addAutoCloseTips(
        tips,
        function()
            --修改正点刷新自身节点被删除后导致的bug
            if not tolua.isnull(self) then
                performWithDelay(
                    self,
                    function()
                        if not tolua.isnull(tips) then
                            tips:setVisible(false)
                        end
                    end,
                    0.1
                )
            end
        end
    )
end

--点击了活动node
function BaseLobbyNodeUI:clickLobbyNode(sender)
    if self.m_LockState then
        self:showTips(self.m_tips_msg)
        return
    end
end

function BaseLobbyNodeUI:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" or name == "Button_2" then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickLobbyNode(sender)
    end
end

function BaseLobbyNodeUI:registerListener()
    BaseDownLoadNodeUI.registerListener(self)
    --升级消息
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:updateView()
        end,
        ViewEventType.SHOW_LEVEL_UP
    )
end

function BaseLobbyNodeUI:updateDownLoad(status)
    self:findChild("downLoadNode"):setVisible(status)
end

function BaseLobbyNodeUI:onEnter()
    BaseDownLoadNodeUI.onEnter(self)

    -- 放在这块处理
    if self.m_commingSoon == false then
        local lbName = self:findChild("name")
        local bottomName = self:getBottomName()
        if bottomName ~= nil then
            lbName:setString(bottomName)
        end
    end
end

-- function BaseLobbyNodeUI:onExit()
--     BaseDownLoadNodeUI.onExit(self)

--     gLobalNoticManager:removeAllObservers(self)
-- end

------------------------------------------子类重写---------------------------------------
--大厅底部的new逻辑，3次之前显示new标签
function BaseLobbyNodeUI:getLobbyNodeNewIconKey()
    return ""
end

function BaseLobbyNodeUI:getGameData()
    return nil
end

function BaseLobbyNodeUI:getBottomName()
    return nil
end

--用来动态计算节点之间的距离
function BaseLobbyNodeUI:getNodeSizePanel()
    if self.m_nodeSizePanel then
        local size = self.m_nodeSizePanel:getContentSize()
        return size
    end
    return {widht = 120, height = 120}
end

function BaseLobbyNodeUI:setNodeFontSacle(scale)
    local lbName = self:findChild("name")
    lbName:setScale(scale)
end

-- 获取活动引用名
function BaseLobbyNodeUI:getActRefName()
    return nil
end

-- 获取 开启等级
function BaseLobbyNodeUI:getSysOpenLv()
    return globalData.constantData.ACTIVITY_OPEN_LEVEL
end

-- 获取 未解锁 文本
function BaseLobbyNodeUI:getSysUnlockDesc(_defaultDesc)
    _defaultDesc = _defaultDesc or ""
    return _defaultDesc
end

-- 获取默认的宽高
function BaseLobbyNodeUI:getContentSize()
    return cc.size(120, 120)
end
------------------------------------------子类重写---------------------------------------
function BaseLobbyNodeUI:openLayerSuccess()
    -- 打点
    gLobalSendDataManager:getLogBottomNode():sendFunctionClickLog(self.m_logFuncClickInfo)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_OPEN_VIEW)
end

return BaseLobbyNodeUI
