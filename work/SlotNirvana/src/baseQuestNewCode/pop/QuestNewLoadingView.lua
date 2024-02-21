-- quest 活动主题弹窗 基类 做一些通用的逻辑
---- FIX IOS 139
local QuestNewLoadingView = class("QuestNewLoadingView", BaseLayer)

function QuestNewLoadingView:ctor()
    QuestNewLoadingView.super.ctor(self)
    local path = self:getCsbPath()
    assert(path, "quest弹窗资源指定路径不存在")
    self:setLandscapeCsbName(path)
    self:setKeyBackEnabled(true)
end

function QuestNewLoadingView:getCsbPath()
    assert(false, "getCsbPath 子类需要重载这个方法 指定资源路径")
end

function QuestNewLoadingView:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    assert(self.m_btnClose, "QuestNewLoadingView 缺少必要的节点1")

    --倒计时控件
    self.m_timerLabel = self:getTimerLabel()
end
function QuestNewLoadingView:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "Push"
end

function QuestNewLoadingView:initView()
    local view = ""
    if self.m_config and self.m_config:getThemeName() == "Activity_QuestIsland" then
        view = "IslandQuestPage"
    end
    gLobalSendDataManager:getLogQuestNewActivity():sendQuestUILog("PushPage", "Open", view)
    if globalData.slotRunData.checkViewAutoClick then
        globalData.slotRunData:checkViewAutoClick(self)
    end

    if self.m_timerLabel then
        schedule(
            self,
            function()
                if self.isClose then
                    return
                end
                self:updateTime()
            end,
            1
        )
        self:updateTime()
    end
end

function QuestNewLoadingView:updateTime()
    local questData = self:getData()
    if not questData then
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
        return
    end

    --活动结束时间
    local expireTime = questData:getLeftTime()
    if expireTime <= 0 then
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
        return
    end

    --设置倒计时
    if self.m_timerLabel then
        self.m_timerLabel:setString(util_daysdemaining1(expireTime))
    end
end

function QuestNewLoadingView:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestNewLoadingView:onEnter()
    QuestNewLoadingView.super.onEnter(self)

    local sp_time_bg = self:findChild("sp_time_bg")
    if sp_time_bg then
        if not self:isShowActionEnabled() then
            sp_time_bg:setVisible(false)
        end
    end
end

function QuestNewLoadingView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        if not self.isCloseLog then
            self.isCloseLog = true
        end
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
    elseif name == "btn_letsgo" or name == "btn_get" then -- csc 2021-12-27 按钮统一化 ,不再使用同一个按钮名称，需要多一个按钮，但是功能相同
        local callfunc = function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
            gLobalSendDataManager:getLogQuestNewActivity():sendQuestEntrySite("pushViewToQuestMain")
            gLobalSendDataManager:getLogQuestNewActivity():sendQuestUILog("PushPage", "Click", "FantasyQuestPage")
            local data = self:getData()
            if not data then
                return
            end
            if gLobalViewManager:isLobbyView() then
                G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer()
            else
                G_GetMgr(ACTIVITY_REF.QuestNew):setEnterGameFromQuest(true)
                G_GetMgr(ACTIVITY_REF.QuestNew):setEnterQuestFromGame(true)
                gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
            end
        end
        self:closeUI(callfunc)
    end
end

function QuestNewLoadingView:closeUI(_callfunc)
    if self.isClose then
        return
    end
    self.isClose = true

    local call_func = function()
        if _callfunc then
            _callfunc()
        end
    end
    QuestNewLoadingView.super.closeUI(self, call_func)
end


-- 是否显示加成
function QuestNewLoadingView:isShowMoreLabel()
    local questData = self:getData()
    if not questData then
        return false
    end

    local expireTime = questData:getLeftTime()
    if expireTime <= questData.p_questExtraPrize then
        return true
    end

    return false
end

-- 获取数据
function QuestNewLoadingView:getData()
    return G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
end

return QuestNewLoadingView
