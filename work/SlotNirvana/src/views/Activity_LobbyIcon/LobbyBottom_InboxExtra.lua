local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_InboxExtra = class("LobbyBottom_InboxExtra", BaseLobbyNodeUI)
LobbyBottom_InboxExtra.m_isChangeParent = nil -- 因为引导原因提高层级
LobbyBottom_InboxExtra.m_inboxGuideList = nil
-- 节点特殊ui 配置相关 --
function LobbyBottom_InboxExtra:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomInboxNode.csb")

    self:initView()
    self.m_inboxGuideList = {}
    -- 特殊组件
    self.m_lbInboxTipSp = self:findChild("sprite_inbox_tip")
    self.m_lbInboxNum = self:findChild("label_inbox_num")
    --特殊奖励提示气泡
    self.m_sp_qipao = self:findChild("sp_qipao")
    if self.m_sp_qipao then
        self.m_sp_qipao:setVisible(false)
    end
    if G_GetMgr(G_REF.Inbox) and G_GetMgr(G_REF.Inbox).getMailCount then
        self:refreshInboxTip(G_GetMgr(G_REF.Inbox):getMailCount())
    else
        self:refreshInboxTip(0)
    end
end

-- function LobbyBottom_InboxExtra:initView( )

-- end

function LobbyBottom_InboxExtra:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
end

function LobbyBottom_InboxExtra:getBottomName()
    return "INBOX"
end

function LobbyBottom_InboxExtra:refreshInboxTip(params)
    self.btnFunc:setVisible(true)
    self.m_btnSpecial:setVisible(false)

    if params <= 0 then
        self.m_lbInboxNum:setVisible(false)
        self.m_lbInboxTipSp:setVisible(false)
    else
        self.m_lbInboxNum:setVisible(true)
        self.m_lbInboxTipSp:setVisible(true)
        self.m_lbInboxNum:setString(tostring(params))
        util_scaleCoinLabGameLayerFromBgWidth(self.m_lbInboxNum, 26)
    end
end

--更新特殊气泡
function LobbyBottom_InboxExtra:checkShowRewardTips()
    local isShowPop = false
    --检测是否有RepartJackpot邮箱引导
    if not isShowPop and self:checkRepartReward(InboxConfig.TYPE_NET.JackpotReturn) then
        isShowPop = true
    end
    --检测是否有RepartFreeSpin邮箱引导
    if not isShowPop and self:checkRepartReward(InboxConfig.TYPE_NET.freeGamesFever) then
        isShowPop = true
    end
    --提高层级添加遮罩显示引导
    if isShowPop and self.m_sp_qipao then
        self.m_sp_qipao:setVisible(isShowPop)
        if not self.m_isChangeParent then
            --改变层级
            self.m_isChangeParent = true
            local wordPos = self:convertToWorldSpace(cc.p(0, 0))
            util_changeNodeParent(gLobalViewManager:getViewLayer(), self.m_csbNode, ViewZorder.ZORDER_GUIDE + 1)
            self.m_csbNode:setPosition(wordPos)
            --添加遮罩
            self.m_newbieMask = util_newMaskLayer()
            gLobalViewManager:getViewLayer():addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE - 1)
            self.m_newbieMask:onTouch(
                function(event)
                    --点击消失
                    self:hideRewardTips()
                end
            )
        end
        --5秒小时
        performWithDelay(
            self,
            function()
                self:hideRewardTips()
            end,
            5
        )
    else
        --弹窗逻辑执行下一个事件
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end
end

function LobbyBottom_InboxExtra:hideRewardTips()
    --还原层级
    if self.m_isChangeParent then
        self.m_isChangeParent = nil
        util_changeNodeParent(self, self.m_csbNode, 0)
        self.m_csbNode:setPosition(cc.p(0, 0))
    end
    --去掉气泡
    if self.m_sp_qipao then
        self.m_sp_qipao:setVisible(false)
    end
    --移除遮罩
    if self.m_newbieMask then
        self.m_newbieMask:removeFromParent()
        self.m_newbieMask = nil
    end
    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    --弹窗逻辑执行下一个事件
end

--检测是否有RepartReward
function LobbyBottom_InboxExtra:checkRepartReward(inboxType)
    if not inboxType then
        return false
    end
    if not self.m_inboxGuideList[inboxType] then
        self.m_inboxGuideList[inboxType] = gLobalDataManager:getStringByField("ToDayInboxReward_" .. inboxType, "")
    end
    local toDayTime = util_getymd_format()
    if self.m_inboxGuideList[inboxType] == toDayTime then
        --今日已经提示过了
        return false
    end
    local collectData = G_GetMgr(G_REF.Inbox):getSysRunData()    
    if not collectData then
        return false
    end
    local mailData = collectData:getMailData()
    for i = 1, #mailData do
        if mailData[i].type == inboxType then
            --记录今日提示状态
            self.m_inboxGuideList[inboxType] = toDayTime
            gLobalDataManager:setStringByField("ToDayInboxReward_" .. inboxType, toDayTime)
            return true
        end
    end
    return false
end
-- 节点特殊处理逻辑 --
function LobbyBottom_InboxExtra:clickLobbyNode()
    --
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if gLobalSendDataManager:checkShowNetworkDialog() then
        return
    end
    if globalPlatformManager.sendFireBaseLogDirect then
        globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.click_inbox)
    end
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "inboxIcon")
    if globalPlatformManager.sendFireBaseLogDirect then
        if G_GetMgr(G_REF.Inbox):getMailCount() > 0 then
            G_GetMgr(G_REF.Inbox):setSourceData(FireBaseLogType.InboxLobbyTipClick)
            globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.InboxLobbyTipOpen)
        else
            G_GetMgr(G_REF.Inbox):setSourceData(FireBaseLogType.InboxLobbyNotipClick)
            globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.InboxLobbyNotipOpen)
        end
    end

    local worldPos = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
    G_GetMgr(G_REF.Inbox):showInboxLayer(
        {
            rootStartPos = worldPos,
            senderName = name,
            dotUrlType = DotUrlType.UrlName,
            dotEntrySite = DotEntrySite.DownView,
            dotEntryType = DotEntryType.Lobby
        }
    )

    self:openLayerSuccess()

    if self.m_isChangeParent then
        self:hideRewardTips()
    end
end

function LobbyBottom_InboxExtra:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

-- onEnter
function LobbyBottom_InboxExtra:onEnter()
    BaseLobbyNodeUI.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            self:refreshInboxTip(mailCount)
        end,
        ViewEventType.NOTIFY_REFRESH_MAIL_COUNT
    )

    gLobalNoticManager:addObserver(self, handler(self, self.checkShowRewardTips), ViewEventType.NOTIFY_GUIDE_INBOX_REWARDTIPS)
end

function LobbyBottom_InboxExtra:onExit()
    BaseLobbyNodeUI.onExit(self)
end

return LobbyBottom_InboxExtra
