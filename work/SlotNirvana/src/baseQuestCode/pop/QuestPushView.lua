-- quest 活动主题弹窗 基类 做一些通用的逻辑
---- FIX IOS 139
local QuestPushView = class("QuestPushView", BaseLayer)

function QuestPushView:ctor()
    QuestPushView.super.ctor(self)
    local path = self:getCsbPath()
    assert(path, "quest弹窗资源指定路径不存在")
    self:setLandscapeCsbName(path)
    self:setKeyBackEnabled(true)
end

function QuestPushView:getCsbPath()
    assert(false, "getCsbPath 子类需要重载这个方法 指定资源路径")
end

function QuestPushView:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    assert(self.m_btnClose, "QuestPushView 缺少必要的节点1")

    --倒计时控件
    self.m_timerLabel = self:getTimerLabel()
end
function QuestPushView:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "Push"
end

function QuestPushView:initView()
    local view = ""
    if self.m_config and self.m_config:getThemeName() == "Activity_QuestIsland" then
        view = "IslandQuestPage"
    end
    gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("PushPage", "Open", view)
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

function QuestPushView:updateTime()
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

function QuestPushView:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestPushView:onEnter()
    QuestPushView.super.onEnter(self)

    local sp_time_bg = self:findChild("sp_time_bg")
    if sp_time_bg then
        if not self:isShowActionEnabled() then
            sp_time_bg:setVisible(false)
        end
    end
end

function QuestPushView:clickFunc(sender)
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
            gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("pushViewToQuestMain")

            self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if not self.m_config then
                return
            end

            local view = ""
            if self.m_config and self.m_config:getThemeName() == "Activity_QuestIsland" then
                view = "IslandQuestPage"
            end
            gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("PushPage", "Click", view)
            if gLobalViewManager:isLobbyView() then
                G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
            else
                if not self.m_config.m_IsQuestLogin then
                    self.m_config.class.m_IsQuestLogin = true
                    self.m_config.p_isLevelEnterQuest = true
                    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
                end
            end
        end
        self:closeUI(callfunc)
    end
end

function QuestPushView:closeUI(_callfunc)
    if self.isClose then
        return
    end
    self.isClose = true

    local call_func = function()
        if _callfunc then
            _callfunc()
        end
    end
    QuestPushView.super.closeUI(self, call_func)
end

--是否弹出buff界面
function QuestPushView:checkShowBuffView()
    if globalData.constantData.FREE_QUEST_BUFF_OPEN_TIME then
        local times = util_string_split(globalData.constantData.FREE_QUEST_BUFF_OPEN_TIME, ";")
        if times and #times == 2 then
            local function changeExprie(strTime)
                local year = tonumber(string.sub(strTime, 1, 4))
                local month = tonumber(string.sub(strTime, 5, 6))
                local day = tonumber(string.sub(strTime, 7, 8))
                local time = os.time({day = day, month = month, year = year, hour = 0, minute = 0, second = 0, isdst = false})
                time = util_LoaclChangeUtcTime(time)
                return time
            end
            local startTime = changeExprie(times[1])
            local endTime = changeExprie(times[2])
            local curTime = os.time()
            if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
                curTime = globalData.userRunData.p_serverTime / 1000
            end
            if curTime >= startTime and curTime < endTime then
                local buffEndTime = gLobalDataManager:getNumberByField("quest_temp_buff_end", -1)
                if buffEndTime ~= -1 and curTime >= buffEndTime then
                    --如果赠送时间到了不再弹窗
                    return false
                end
                return true
            end
        end
    end
    return false
end

-- 是否显示加成
function QuestPushView:isShowMoreLabel()
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
function QuestPushView:getData()
    return G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

return QuestPushView
