--[[
    
]]
local QuestPassRewardBox = class("QuestPassRewardBox", BaseView)

function QuestPassRewardBox:initDatas(_data, _passLayer)
    self.m_data = _data
    self.m_passLayer = _passLayer
    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

function QuestPassRewardBox:getCsbName()
    return QUEST_RES_PATH.QuestPassBox
end

function QuestPassRewardBox:initCsbNodes()
    self.m_node_unComplted_1 = self:findChild("node_unComplted_1")
    self.m_node_unUnlock = self:findChild("node_unUnlock")
    self.m_node_unComplted_2 = self:findChild("node_unComplted_2")
    self.m_node_normal = self:findChild("node_normal")
    self.m_bar_progress = self:findChild("bar_progress")
    self.m_lb_num = self:findChild("lb_num")
    self.m_lb_desc = self:findChild("lb_desc")
end

function QuestPassRewardBox:initUI()
    QuestPassRewardBox.super.initUI(self)

    self:initBubble()
    self:setPrice()
    self:initProgress()
    self:setStatus()
    self:updateBtnBuck()
end

function QuestPassRewardBox:updateBtnBuck()
    local buyType = BUY_TYPE.QUEST_PASS
    self:setBtnBuckVisible(self:findChild("btn_buy"), buyType, nil, {
        {node = self:findChild("btn_buy"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 25},
        {node = self:findChild("Sp_ticket"), addX = 25}
    })
end

function QuestPassRewardBox:initBubble()
    self.m_bubble = util_createView(QUEST_CODE_PATH.QuestPassRewardBubble, self.m_data.box)
    self:addChild(self.m_bubble)
end

function QuestPassRewardBox:setPrice()
    if self.m_gameData then
        local passData = self.m_gameData:getPassData()
        local price = passData:getPrice()
        self:setButtonLabelContent("btn_buy", "          $" .. price, nil, true)
    end
end

function QuestPassRewardBox:initProgress()
    local boxData = self.m_data.box
    local curExp = boxData.p_curExp
    local tatolExp = boxData.p_totalExp
    local percent = math.floor(math.min(curExp, tatolExp) / tatolExp * 100)
    self.m_bar_progress:setPercent(percent)
    self.m_lb_num:setString(curExp .. "/" .. tatolExp)
    self.m_lb_desc:setString(tatolExp)
end

function QuestPassRewardBox:setStatus()
    self.m_status = "unlocked_unC"
    if not self.m_data.payUnlocked then
        if self.m_data.curExp >= self.m_data.totalExp then
            self.m_status = "unlocked"
        end
    elseif self.m_data.curExp < self.m_data.totalExp then
        self.m_status = "uncompleted"
    else
        self.m_status = "normal"
    end

    self.m_node_normal:setVisible(self.m_status == "normal")
    self.m_node_unComplted_1:setVisible(self.m_status == "unlocked_unC")
    self.m_node_unComplted_2:setVisible(self.m_status == "uncompleted")
    self.m_node_unUnlock:setVisible(self.m_status == "unlocked")
end

function QuestPassRewardBox:clickFunc(_sender)
    if self.m_passLayer:getTouch() then
        return 
    end
    
    local name = _sender:getName()
    if name == "btn_touch" then
        self.m_bubble:playAction()
    elseif name == "btn_buy" then
        if self.m_gameData then
            self.m_passLayer:setTouch(true)
            local passData = self.m_gameData:getPassData()
            G_GetMgr(ACTIVITY_REF.Quest):buyPassUnlock(passData)
        end
    end
end

function QuestPassRewardBox:updateView(_params)
    if _params and _params.success then
        if self.m_gameData then
            local passData = self.m_gameData:getPassData()
            self.m_data = {
                box = passData:getBoxReward(),
                curExp = passData:getCurExp(),
                totalExp = passData:getTotalExp(),
                payUnlocked = passData:getPayUnlocked()
            }
            self:initProgress()
            self:setStatus()
        end
    end
end

function QuestPassRewardBox:onEnter()
    QuestPassRewardBox.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self, self.updateView, ViewEventType.NOTIFY_QUEST_PASS_COLLECT)
    gLobalNoticManager:addObserver(self, self.updateView, ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK)
end

return QuestPassRewardBox