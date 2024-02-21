--[[
    pass 入口
]]

local QuestPassEntry = class("QuestPassEntry", BaseView)

function QuestPassEntry:getCsbName()
    return QUEST_RES_PATH.QuestPassEntry
end

function QuestPassEntry:initCsbNodes()
    self.m_sp_redpoint = self:findChild("sp_redpoint")
    self.m_lb_redpoint = self:findChild("lb_redpoint")
end

function QuestPassEntry:initUI()
    QuestPassEntry.super.initUI(self)

    self:updateView()
end

function QuestPassEntry:updateView()
    local data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if data and data:getPassData() then
        local passData = data:getPassData()
        local rewardCount = passData:getRewardCount()
        self.m_lb_redpoint:setString(rewardCount)
        self.m_sp_redpoint:setVisible(rewardCount > 0)
    else
        self.m_sp_redpoint:setVisible(false)
    end
end

function QuestPassEntry:clickFunc(_sender)
    G_GetMgr(ACTIVITY_REF.Quest):showPassLayer()
end

function QuestPassEntry:onEnter()
    QuestPassEntry.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.NOTIFY_QUEST_PASS_COLLECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.NOTIFY_QUEST_PASS_DATA_UPDATE
    )
end

return QuestPassEntry