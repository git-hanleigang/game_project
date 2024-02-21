--大地图上的logo节点
local QuestNewLobbyLogoNode = class("QuestNewLobbyLogoNode", BaseView)

function QuestNewLobbyLogoNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewLobbyLogoNode
end

function QuestNewLobbyLogoNode:initUI(data)
    QuestNewLobbyLogoNode.super.initUI(self)
    self.m_activityData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
end

function QuestNewLobbyLogoNode:initCsbNodes()
    self.m_lb_time = self:findChild("m_lb_num")
end

function QuestNewLobbyLogoNode:onEnter()
    QuestNewLobbyLogoNode.super.onEnter(self)
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
function QuestNewLobbyLogoNode:updateTime()
    if not self.m_activityData then
        return
    end
    local expireTime = self.m_activityData:getLeftTime()
    if expireTime >= 0 then
        local time_str = util_daysdemaining1(expireTime)
        self.m_lb_time:setString(time_str)
    end
end

function QuestNewLobbyLogoNode:onExit()
    QuestNewLobbyLogoNode.super.onExit(self)
    if self.schedule_timer then
        self:stopAction(self.schedule_timer)
        self.schedule_timer = nil
    end
end

function QuestNewLobbyLogoNode:getLanguageTableKeyPrefix()
    local theme = self.m_activityData:getThemeName()
    return theme .. "Logo"
end

return QuestNewLobbyLogoNode
