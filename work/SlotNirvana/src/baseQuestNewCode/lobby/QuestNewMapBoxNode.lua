--金币滚动节点
local QuestNewMapBoxNode = class("QuestNewMapBoxNode", util_require("base.BaseView"))

QuestNewMapBoxNode.NoneRank = 360

local res_suffix = {"minor.csd","major.csd","grand.csd"}

function QuestNewMapBoxNode:initDatas(data)
    self.m_data = data.data_box
end

function QuestNewMapBoxNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewMapBoxNode 
end

function QuestNewMapBoxNode:initUI()
    self:createCsbNode(self:getCsbName())
    --self:runCsbAction("idle", true)
    self:initView()
end

function QuestNewMapBoxNode:refreshByData(data)
    self.m_data = data
    self:initView()
end

function QuestNewMapBoxNode:initCsbNodes()
    self.m_node_Reward_kelingqu = self:findChild("node_Reward_kelingqu") 
    self.m_sp_rewards_yilingqu = self:findChild("sp_rewards_yilingqu") 
    self.m_sp_rewards_bukeling = self:findChild("sp_rewards_bukeling") 

    self.m_panel_touch = self:findChild("Panel_touch") 
    self:addClick(self.m_panel_touch)
    self.m_panel_touch:setSwallowTouches(false)
    
    self.m_Node_qipao = self:findChild("Node_qipao") 
end

function QuestNewMapBoxNode:initView()
    if self.m_data:isBoxUnlock() and not self.m_data:isWillDoBoxOpen() then
        if self.m_data:isBoxCollected() then
            self:runCsbAction("idle2", true)
            self.m_node_Reward_kelingqu:setVisible(false)
            self.m_sp_rewards_yilingqu:setVisible(true)
            self.m_sp_rewards_bukeling:setVisible(false)
            self.m_panel_touch:setVisible(false)
            self.m_panel_touch:setTouchEnabled(false)
        else
            self:runCsbAction("idle", true)
            self.m_node_Reward_kelingqu:setVisible(true)
            self.m_sp_rewards_yilingqu:setVisible(false)
            self.m_sp_rewards_bukeling:setVisible(false)
        end
    else
        self:runCsbAction("idle_an", true)
        self.m_node_Reward_kelingqu:setVisible(true)
        self.m_sp_rewards_yilingqu:setVisible(false)
        self.m_sp_rewards_bukeling:setVisible(true)
    end
    self:initStepNode()
end

function QuestNewMapBoxNode:initStepNode()
    local unlock = self.m_data:isBoxUnlock() and not self.m_data:isWillDoBoxOpen()
    self.m_stepNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapStepNode, {type = "box",index = self.m_data.p_id ,unlock = unlock})
    self.m_stepNode:setScale(5/3)
    self:addChild(self.m_stepNode)
end

function QuestNewMapBoxNode:doBoxOpen(callFun)
    if self.m_data:isBoxUnlock() and self.m_data:isWillDoBoxOpen() then
        self.m_data:clearWillDoBoxOpen()
        self.m_sp_rewards_bukeling:setVisible(false)
        self.m_stepNode:doStepAct(function ()
            self:runCsbAction("jiesuo", false,function ()
                self.m_node_Reward_kelingqu:setVisible(true)
                self.m_sp_rewards_yilingqu:setVisible(false)
                self.m_sp_rewards_bukeling:setVisible(false)
                self:runCsbAction("idle", true)
                if callFun then
                    callFun()
                end
            end)
        end)
    end
end

function QuestNewMapBoxNode:clickFunc(sender)
    local name = sender:getName()
    if G_GetMgr(ACTIVITY_REF.QuestNew):isDoingMapCheckLogic() then
        return
    end
    if name == "Panel_touch"  then
        if self.m_data:isBoxUnlock() and not self.m_data:isBoxCollected() and not self.m_data:isWillDoBoxOpen() then
            if self.m_requestingReward then
                return
            end
            self.m_requestingReward = true
            G_GetMgr(ACTIVITY_REF.QuestNew):requestCollectGift(self.m_data.p_chapterId,self.m_data.p_id)
        else
            self:addBubble()
            self.m_bubbleNode:doShowOrHide()
        end
    end
end

function QuestNewMapBoxNode:addBubble()
    if not self.m_bubbleNode then
        self.m_bubbleNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapBoxBubbleNode, {rewardData = self.m_data})
        self.m_bubbleNode:setScale(1.5)
        self.m_Node_qipao:addChild(self.m_bubbleNode,2000)
    end
end

return QuestNewMapBoxNode
