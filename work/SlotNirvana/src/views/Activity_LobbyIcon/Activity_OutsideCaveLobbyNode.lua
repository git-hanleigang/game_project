--[[--
    大富翁活动大厅图标
]]
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_OutsideCaveLobbyNode = class("Activity_OutsideCaveLobbyNode", BaseActLobbyNodeUI)

function Activity_OutsideCaveLobbyNode:initDatas()
    Activity_OutsideCaveLobbyNode.super.initDatas(self)
end

function Activity_OutsideCaveLobbyNode:initUI(data)
    Activity_OutsideCaveLobbyNode.super.initUI(self, data)
    self:initUnlockUI()
end

function Activity_OutsideCaveLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_OutsideCaveLobbyNode.csb"
end

function Activity_OutsideCaveLobbyNode:initCsbNodes()
    self.lb_loading = self:findChild("lb_downloading") -- 下载中描述文本
    self.lb_unlock = self:findChild("lb_unlock") -- 未解锁描述文本
    self.m_djsLabel = self:findChild("timeValue")
end

function Activity_OutsideCaveLobbyNode:initView()
    Activity_OutsideCaveLobbyNode.super.initView(self)

    self.btnFunc:loadTextureNormal("Activity_LobbyIconRes/ui/OutsideCave_logo1.png", UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTexturePressed("Activity_LobbyIconRes/ui/OutsideCave_logo2.png", UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTextureDisabled("Activity_LobbyIconRes/ui/OutsideCave_logo2.png", UI_TEX_TYPE_LOCAL)

    self.m_lockIocn:setTexture("Activity_LobbyIconRes/ui/OutsideCave_logo1.png")

    self.lb_loading:setString("OUTSIDE CAVE IS DOWNLOADING")
    self.lb_unlock:setString("UNLOCK OUTSIDE CAVE AT LEVEL " .. self:getSysOpenLv())

    -- 根据图片大小 重置按钮尺寸
    if self.btnFunc then
        local size = self.btnFunc:getNormalTextureSize()
        self.btnFunc:setContentSize(size)
    end
end
------- 倒计时相关
--显示倒计时
function Activity_OutsideCaveLobbyNode:showDownTimer()
    local data = G_GetMgr(ACTIVITY_REF.OutsideCave):getRunningData()
    if not data or data:getLeftTime() <= 0 then
        self:showCommingSoon()
        return
    end

    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function Activity_OutsideCaveLobbyNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function Activity_OutsideCaveLobbyNode:updateLeftTime()
    Activity_OutsideCaveLobbyNode.super.updateLeftTime(self)
    -- local gameData = self:getGameData()
    -- if gameData ~= nil and gameData:isRunning() then
    --     local strLeftTime = util_daysdemaining(gameData:getExpireAt(), true)
    --     self.m_djsLabel:setString(strLeftTime)
    -- else
    --     self:closeLobbyNode()
    --     self:stopTimerAction()
    -- end
    self:updateLabelSize({label = self.m_djsLabel}, 85)
    --显示红点
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
-------
function Activity_OutsideCaveLobbyNode:openMainUI()
    self:registPopupLog()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_OPEN_VIEW)
    G_GetMgr(ACTIVITY_REF.OutsideCave):showMainLayer()
end

function Activity_OutsideCaveLobbyNode:updateView()
    Activity_OutsideCaveLobbyNode.super.updateView(self)

    self.m_lockIocn:setVisible(false) -- 锁定icon
    self.btnFunc:setOpacity(255)
end

--点击了活动node
function Activity_OutsideCaveLobbyNode:clickLobbyNode()
    
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local _Data = G_GetMgr(ACTIVITY_REF.OutsideCave):getData()
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

    -- 新手引导 lobby 结束
    -- if self.m_isBottomExtra == false then
    --     if G_GetMgr(ACTIVITY_REF.OutsideCave):getGuideMgr():checkStopGuide("lobby") then
    --         G_GetMgr(ACTIVITY_REF.OutsideCave):getGuideMgr():stopGuide("lobby")
    --     end
    -- end
    -- 如果大厅弹框没有弹完，这里强行完成
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    self:openMainUI()
end

function Activity_OutsideCaveLobbyNode:getDownLoadKey()
    return self:getThemeName()
end

function Activity_OutsideCaveLobbyNode:getThemeName()
    return "Activity_OutsideCave"
end

-- 下载进度条节点资源
function Activity_OutsideCaveLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/OutsideCave_logo1.png"
end

function Activity_OutsideCaveLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_OutsideCaveLobbyNode:getBottomName()
    return "OUTSIDE"
end

function Activity_OutsideCaveLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.OutsideCave):getRunningData()
end

-- 记录打点信息
function Activity_OutsideCaveLobbyNode:registPopupLog()
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "OutsideCaveLobbyIcon")
end

-- 获取活动引用名
function Activity_OutsideCaveLobbyNode:getActRefName()
    return ACTIVITY_REF.OutsideCave
end

-- 获取默认的解锁文本
function Activity_OutsideCaveLobbyNode:getDefaultUnlockDesc()
    return "UNLOCK OUTSIDE CAVE AT LEVEL " .. self:getSysOpenLv()
end

function Activity_OutsideCaveLobbyNode:checkPlayIsOn(result)
    local data = self:getActivityData()
    if data then
        return data:isTicketEnough()
    end
    return false
end

--下载结束回调
-- function Activity_OutsideCaveLobbyNode:endProcessFunc()
--     local runData = G_GetMgr(ACTIVITY_REF.OutsideCave):getRunningData()
--     if runData then
--         if G_GetMgr(ACTIVITY_REF.OutsideCave):isCanShowLayer() then
--             -- local stepId = G_GetMgr(ACTIVITY_REF.OutsideCave):getGuideMgr():getUserDefaultStepId()
--             -- if stepId == 0 and runData:isLoginTriggerGuide() and self.m_isBottomExtra == false then
--             --     -- poker新手引导 lobby 开始
--             --     if G_GetMgr(ACTIVITY_REF.OutsideCave):getGuideMgr():checkStartGuide("lobby") then
--             --         G_GetMgr(ACTIVITY_REF.OutsideCave):getGuideMgr():startGuide("lobby")
--             --     end
--             -- end
--         end
--     end
-- end

function Activity_OutsideCaveLobbyNode:registerListener()
    Activity_OutsideCaveLobbyNode.super.registerListener(self)
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         if params and params.refName == ACTIVITY_REF.OutsideCave and self.m_isBottomExtra == false then
    --             -- poker新手引导 lobby
    --             if params.stepKey == "lobby" then
    --                 local ui = gLobalViewManager:getViewByName("PokerGuideUI_Main")
    --                 if ui then
    --                     ui:addHighNode(self.m_csbNode, nil, true)
    --                     G_GetMgr(ACTIVITY_REF.OutsideCave):getGuideMgr():closeGuideStartUI(params.stepKey)
    --                 end
    --             end
    --         end
    --     end,
    --     ViewEventType.NOTIFY_ACTIVITY_GUIDE_START
    -- )
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         if params and params.refName == ACTIVITY_REF.OutsideCave and self.m_isBottomExtra == false then
    --             -- poker新手引导 lobby
    --             if params.stepKey == "lobby" then
    --                 local ui = gLobalViewManager:getViewByName("PokerGuideUI_Main")
    --                 if ui then
    --                     ui:delHighNode(self.m_csbNode, self)
    --                     G_GetMgr(ACTIVITY_REF.OutsideCave):getGuideMgr():closeGuideStopUI("lobby")
    --                 end
    --             end
    --         end
    --     end,
    --     ViewEventType.NOTIFY_ACTIVITY_GUIDE_OVER
    -- )
end

return Activity_OutsideCaveLobbyNode
