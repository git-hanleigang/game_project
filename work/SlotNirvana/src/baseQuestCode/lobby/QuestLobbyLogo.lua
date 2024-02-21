--大地图上的logo节点
local QuestLobbyLogo = class("QuestLobbyLogo", BaseView)

-- function QuestLobbyLogo:ctor()
--     QuestLobbyLogo.super.ctor(self)
--     self:mergePlistInfos(QUEST_PLIST_PATH.QuestLobbyLogo)
-- end

function QuestLobbyLogo:getCsbName()
    return QUEST_RES_PATH.QuestLobbyLogo
end

function QuestLobbyLogo:initUI(data)
    QuestLobbyLogo.super.initUI(self)
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

function QuestLobbyLogo:initCsbNodes()
    self.m_lb_time = self:findChild("m_lb_num")
end

function QuestLobbyLogo:onEnter()
    QuestLobbyLogo.super.onEnter(self)
    self:runCsbAction("idle", true)

    --刷新倒计时
    if self.m_lb_time then
        self:updateTime()
        if not self.schedule_timer then
            self.schedule_timer =
                util_schedule(
                self,
                function()
                    self:updateTime()
                end,
                1
            )
        end
    end
end

--刷新倒计时
function QuestLobbyLogo:updateTime()
    if not self.m_config then
        return
    end
    local expireTime = self.m_config:getLeftTime()
    if expireTime >= 0 then
        local time_str = util_daysdemaining1(expireTime)
        self.m_lb_time:setString(time_str)
    end
end

function QuestLobbyLogo:onExit()
    QuestLobbyLogo.super.onExit(self)
    if self.schedule_timer then
        self:stopAction(self.schedule_timer)
        self.schedule_timer = nil
    end
end

function QuestLobbyLogo:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "Logo"
end

return QuestLobbyLogo
