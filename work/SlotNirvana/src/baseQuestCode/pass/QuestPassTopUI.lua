--[[
    pass
]]

local QuestPassTopUI = class("QuestPassTopUI", BaseView)

function QuestPassTopUI:getCsbName()
    return QUEST_RES_PATH.QuestPassTopUI
end

function QuestPassTopUI:initCsbNodes()
    self.m_node_ticket = self:findChild("node_ticket")
    self.m_node_claimall = self:findChild("node_claimall")
    self.m_claimallPos = cc.p(self.m_node_claimall:getPosition())
end

function QuestPassTopUI:initUI(_parent)
    QuestPassTopUI.super.initUI(self)

    self.m_parent = _parent
    self:updateView()
end

function QuestPassTopUI:updateView()
    local data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if data and data:getPassData() then
        local passData = data:getPassData()
        local rewardCount = passData:getRewardCount()
        local payUnlocked = passData:getPayUnlocked()
        self.m_node_ticket:setVisible(not payUnlocked)
        self.m_node_claimall:setPosition(payUnlocked and cc.p(0,0) or self.m_claimallPos)
        self:setButtonLabelDisEnabled("btn_claimAll", rewardCount > 0)
    else
        self.m_node_ticket:setVisible(false)
        self.m_node_claimall:setPosition(0, 0)
        self:setButtonLabelDisEnabled("btn_claimAll", false)
    end
end

function QuestPassTopUI:clickFunc(_sender)
    if self.m_parent:getTouch() then
        return
    end

    local name = _sender:getName()
    if name == "btn_buy" then
        G_GetMgr(ACTIVITY_REF.Quest):showPassBuyTicketLayer()
    elseif name == "btn_claimAll" then
        self.m_parent:setTouch(true)

        local data = {p_level = -1}
        G_GetMgr(ACTIVITY_REF.Quest):sendPassCollect(data, "all")
    end
end

function QuestPassTopUI:onEnter()
    QuestPassTopUI.super.onEnter(self)

    gLobalNoticManager:addObserver(self, self.updateView, ViewEventType.NOTIFY_QUEST_PASS_COLLECT)
    gLobalNoticManager:addObserver(self, self.updateView, ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK)
end

return QuestPassTopUI