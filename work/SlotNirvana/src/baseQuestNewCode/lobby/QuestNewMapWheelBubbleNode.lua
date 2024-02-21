--宝箱气泡节点
local QuestNewMapWheelBubbleNode = class("QuestNewMapWheelBubbleNode", util_require("base.BaseView"))

function QuestNewMapWheelBubbleNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewMapWheelBubbleNode 
end

function QuestNewMapWheelBubbleNode:initUI()
    self:createCsbNode(self:getCsbName())
    self.m_lb_dec_unlock = self:findChild("lb_dec_unlock")
    self.m_lb_dec_wancheng = self:findChild("lb_dec_wancheng")
end

function QuestNewMapWheelBubbleNode:setType(type)
    if type ==1 then
        self.m_lb_dec_unlock:setVisible(true)
        self.m_lb_dec_wancheng:setVisible(false)
    else
        self.m_lb_dec_unlock:setVisible(false)
        self.m_lb_dec_wancheng:setVisible(true)
    end
end

function QuestNewMapWheelBubbleNode:doShowOrHide()
    if not self.m_isShowingRewards then
        self.m_isShowingRewards = true
        self:showRewardBubble()
    else
        self:forceHideBubble()
    end
end

function QuestNewMapWheelBubbleNode:showRewardBubble()
    if self.m_doAct then
        return 
    end
    self.m_doAct = true
    self:runCsbAction("show",false, function ()
        self.m_doAct = false
        util_performWithDelay(self, function ()
            if self.m_isShowingRewards then
                if self.m_doAct then
                    return 
                end
                self.m_doAct = true
                self.m_isShowingRewards = false
                self:runCsbAction("over",false, function ()
                    self.m_doAct = false
                end)
            end
        end, 1)
    end)
end

function QuestNewMapWheelBubbleNode:forceHideBubble()
    if self.m_isShowingRewards then
        if self.m_doAct then
            return 
        end
        self.m_doAct = true
        self.m_isShowingRewards = false
        self:stopAllActions()
        self:runCsbAction("over",false, function ()
            self.m_doAct = false
        end)
    end
end

return QuestNewMapWheelBubbleNode
