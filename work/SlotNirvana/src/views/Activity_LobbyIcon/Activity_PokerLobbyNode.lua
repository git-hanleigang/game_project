--[[--
    扑克活动大厅图标
]]
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_PokerLobbyNode = class("Activity_PokerLobbyNode", BaseActLobbyNodeUI)

function Activity_PokerLobbyNode:initDatas()
    Activity_PokerLobbyNode.super.initDatas(self)
    self.m_cfg = G_GetMgr(ACTIVITY_REF.Poker):getConfig()
end

function Activity_PokerLobbyNode:initUI(data)
    Activity_PokerLobbyNode.super.initUI(self, data)
    self:initUnlockUI()
end

function Activity_PokerLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_PokerLobbyNode.csb"
end

function Activity_PokerLobbyNode:initCsbNodes()
    self.lb_loading = self:findChild("lb_downloading") -- 下载中描述文本
    self.lb_unlock = self:findChild("lb_unlock") -- 未解锁描述文本
end

function Activity_PokerLobbyNode:initView()
    Activity_PokerLobbyNode.super.initView(self)

    self.btnFunc:loadTextureNormal(self.m_cfg.lobbyPath .. "poker_logo.png", UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTexturePressed(self.m_cfg.lobbyPath .. "poker_logo_lock.png", UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTextureDisabled(self.m_cfg.lobbyPath .. "poker_logo_lock.png", UI_TEX_TYPE_LOCAL)

    self.m_lockIocn:setTexture(self.m_cfg.lobbyPath .. "poker_logo.png")

    self.lb_loading:setString("CASH POKER IS DOWNLOADING")
    self.lb_unlock:setString("UNLOCK CASH POKER AT LEVEL " .. self:getSysOpenLv())

    -- 根据图片大小 重置按钮尺寸
    if self.btnFunc then
        local size = self.btnFunc:getNormalTextureSize()
        self.btnFunc:setContentSize(size)
    end
end

function Activity_PokerLobbyNode:openPokerMainUI()
    self:registPokerPopupLog()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_OPEN_VIEW)
    G_GetMgr(ACTIVITY_REF.Poker):showChapterLayer()
end

--点击了活动node
function Activity_PokerLobbyNode:clickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local _Data = G_GetMgr(ACTIVITY_REF.Poker):getData()
    if not _Data then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    local curLevel = globalData.userRunData.levelNum
    local unLockLevel = self:getSysOpenLv() -- globalData.constantData.ACTIVITY_OPEN_LEVEL
    if curLevel < unLockLevel then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local dl_key = self:getDownLoadKey()
    if globalDynamicDLControl:checkDownloading(dl_key) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    -- poker新手引导 lobby 结束
    if self.m_isBottomExtra == false then
        if G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():checkStopGuide("lobby") then
            G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():stopGuide("lobby")
        end
    end
    -- 如果大厅弹框没有弹完，这里强行完成
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    self:openPokerMainUI()
end

function Activity_PokerLobbyNode:getDownLoadKey()
    return self:getThemeName()
end

function Activity_PokerLobbyNode:getThemeName()
    return "Activity_Poker"
end

-- 下载进度条节点资源
function Activity_PokerLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/poker_logo.png"
end

function Activity_PokerLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_PokerLobbyNode:getBottomName()
    return "CASH POKER"
end

function Activity_PokerLobbyNode:updateLeftTime()
    local gameData = self:getGameData()
    if gameData ~= nil and gameData:isRunning() then
        local strLeftTime = util_daysdemaining(gameData:getExpireAt(), true)
        self.m_djsLabel:setString(strLeftTime)
    else
        self:closeLobbyNode()
        self:stopTimerAction()
    end
    self:updateLabelSize({label = self.m_djsLabel}, 85)
    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local redNum = gameData:getLobbyRedNum()
            if redNum > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(redNum)
                -- 动态更改label尺寸
                local rp_size = self.m_spRedPoint:getContentSize()
                -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
                self:updateLabelSize({label = self.m_labelActivityNums}, rp_size.width - 15)
            else
                self.m_spRedPoint:setVisible(false)
            end
        else
            -- 隐藏
            self.m_spRedPoint:setVisible(false)
        end
    end
end

function Activity_PokerLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.Poker):getRunningData()
end

-- 记录打点信息
function Activity_PokerLobbyNode:registPokerPopupLog()
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "PokerLobbyIcon")
end

-- 获取活动引用名
function Activity_PokerLobbyNode:getActRefName()
    return ACTIVITY_REF.Poker
end

-- 获取默认的解锁文本
function Activity_PokerLobbyNode:getDefaultUnlockDesc()
    return "UNLOCK CASH POKER AT LEVEL " .. self:getSysOpenLv()
end

function Activity_PokerLobbyNode:checkPlayIsOn(result)
    local data = self:getActivityData()
    if data then
        return data:isTicketEnough()
    end
    return false
end

--下载结束回调
function Activity_PokerLobbyNode:endProcessFunc()
    -- local runData = G_GetMgr(ACTIVITY_REF.Poker):getRunningData()
    -- if runData then
    --     if G_GetMgr(ACTIVITY_REF.Poker):isCanShowLayer() then
    --         local stepId = G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():getUserDefaultStepId()
    --         if stepId == 0 and runData:isLoginTriggerGuide() and self.m_isBottomExtra == false then
    --             -- poker新手引导 lobby 开始
    --             if G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():checkStartGuide("lobby") then
    --                 G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():startGuide("lobby")
    --             end
    --         end
    --     end
    -- end
end

function Activity_PokerLobbyNode:registerListener()
    Activity_PokerLobbyNode.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.refName == ACTIVITY_REF.Poker and self.m_isBottomExtra == false then
                -- poker新手引导 lobby
                if params.stepKey == "lobby" then
                    local ui = gLobalViewManager:getViewByName("PokerGuideUI_Main")
                    if ui then
                        ui:addHighNode(self.m_csbNode, nil, true)
                        G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():closeGuideStartUI(params.stepKey)
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_GUIDE_START
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.refName == ACTIVITY_REF.Poker and self.m_isBottomExtra == false then
                -- poker新手引导 lobby
                if params.stepKey == "lobby" then
                    local ui = gLobalViewManager:getViewByName("PokerGuideUI_Main")
                    if ui then
                        ui:delHighNode(self.m_csbNode, self)
                        G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():closeGuideStopUI("lobby")
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_GUIDE_OVER
    )
end

return Activity_PokerLobbyNode
