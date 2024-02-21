-- Created by jfwang on 2019-05-21.
-- QuestNewUserLoginView 基类
--
local QuestNewUserLoginView = class("QuestNewUserLoginView", BaseLayer)

function QuestNewUserLoginView:ctor()
    QuestNewUserLoginView.super.ctor(self)

    self:setLandscapeCsbName(QUEST_RES_PATH.QuestPopLayer)
    self:setPortraitCsbName(QUEST_RES_PATH.QuestPopLayer_por)
    self:setPauseSlotsEnabled(true)

    self:setExtendData("QuestNewUserLoginView")
end

function QuestNewUserLoginView:initCsbNodes()
    self.m_timeLb = self:findChild("lb_time")
    self.node_coin = self:findChild("node_coin")
    self.sp_coins = self:findChild("sp_coins")
    self.lb_coins = self:findChild("lb_reward")
    self.lb_phase = self:findChild("lb_phase")
    self:setButtonLabelContent("btn_play", "LET'S PLAY")
    self.icons = {}
    for i = 1, 6 do
        local node_icon = self:findChild("sp_icon" .. i)
        if node_icon then
            self.icons[i] = node_icon
        end
    end

end

function QuestNewUserLoginView:initDatas(_callback)
    self.quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()

    self.m_callback = _callback
end

function QuestNewUserLoginView:initUI(_callback)
    QuestNewUserLoginView.super.initUI(self)

    gLobalSendDataManager:getLogQuestNewUserActivity():sendQuestEntrySite("loginLobbyPush")
    gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("PushPage", "Open")
end

function QuestNewUserLoginView:onEnter()
    QuestNewUserLoginView.super.onEnter(self)
    self:updateView()
end

function QuestNewUserLoginView:playShowAction()
    -- 播放光圈动画
    if gLobalViewManager:isLevelView() then
        local efView = util_createView("QuestNewUserCode.QuestNewUserOpenEfUI")
        if efView then
            self:addChild(efView, 99)
            efView:move(display.center)
            efView:playShowAct()
        end
    end

    QuestNewUserLoginView.super.playShowAction(self, "start")
end

function QuestNewUserLoginView:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function QuestNewUserLoginView:updateView()
    if tolua.isnull(self.sp_coins) or tolua.isnull(self.lb_coins) then
        return
    end

    if self.quest_data == nil then
        return
    end
    if not tolua.isnull(self.lb_phase) then
        local phase_idx = self.quest_data:getPhaseIdx()
        self.lb_phase:setString(phase_idx)
    end

    local ui_list = {
        {node = self.sp_coins, alignX = 0},
        {node = self.lb_coins, alignX = 0}
    }
    local coins = 0
    local phase_data = self.quest_data:getCurPhaseData()
    if G_GetMgr(ACTIVITY_REF.Quest):getGroupName() == "GroupB" and phase_data then
        coins = tonumber(phase_data.p_phaseCoins) or 0
    else
        coins = tonumber(globalData.constantData.NOVICE_NEWUSERQUEST_LOGIN_REWARD) or 0
    end

    self.lb_coins:setString(util_formatCoins(coins, 9))
    if not tolua.isnull(self.node_coin) and phase_data and phase_data.p_phaseItems and #phase_data.p_phaseItems > 0 then
        local item = gLobalItemManager:createRewardNode(phase_data.p_phaseItems[1], ITEM_SIZE_TYPE.TOP)
        if item then
            self.lb_coins:setString(util_formatCoins(coins, 9) .. " + ")
            item:addTo(self.node_coin)
            local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
            table.insert(ui_list, {node = item, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)})
        end
    end

    util_alignCenter(ui_list)

    local group_res = G_GetMgr(ACTIVITY_REF.Quest):getPopLayerLevelIcons()
    if group_res then
        for i, node_icon in pairs(self.icons) do
            if node_icon and group_res[i] then
                local sp_icon = util_createSprite(group_res[i])
                if sp_icon then
                    node_icon:addChild(sp_icon)
                end
            end
        end
    end

    -- 倒计时
    self:updateTime()
    schedule(
        self,
        function()
            self:updateTime()
        end,
        1
    )
end

function QuestNewUserLoginView:updateTime()
    if not self.quest_data then
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )
    else
        --活动结束时间
        local expireTime = self.quest_data:getLeftTime()
        if expireTime <= 0 then
            self:closeUI(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
            )
        else
            if self.m_timeLb then
                if self.quest_data and expireTime then
                    local timer = util_daysdemaining(self.quest_data:getExpireAt(), true)
                    self.m_timeLb:setString(timer)
                end
            end
        end
    end
end

function QuestNewUserLoginView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_play" then
        self:closeUI(
            function()
                if gLobalViewManager:isLobbyView() then
                    G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
                    return
                end

                gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("PushPage", "Click")
                if self.quest_data then
                    self.quest_data.class.m_IsQuestLogin = true
                    self.quest_data.p_isLevelEnterQuest = true
                    gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("gameLevelUpPush")
                    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
                end
            end
        )
    elseif name == "btn_close" then
        self:closeUI(
            function()
                if self.m_callback then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                    self.m_callback()
                else
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end
        )
    end
end

return QuestNewUserLoginView
