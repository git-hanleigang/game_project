--宝箱气泡节点
local QuestNewMapBoxBubbleNode = class("QuestNewMapBoxBubbleNode", util_require("base.BaseView"))

function QuestNewMapBoxBubbleNode:initDatas(data)
    self.m_rewardData = data.rewardData
end

function QuestNewMapBoxBubbleNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewMapBoxBubbleNode 
end

function QuestNewMapBoxBubbleNode:initUI()
    self:createCsbNode(self:getCsbName())
    self:initView()
end

function QuestNewMapBoxBubbleNode:initCsbNodes()
    self.m_node_reward = self:findChild("node_reward") 
    self.m_sp_qipao = self:findChild("sp_qipao") 
    self.m_sp_qipao_jiao = self:findChild("sp_qipao_jiao") 
    self.m_wheel_coin = self:findChild("wheel_coin_4") 
    self.m_Text_1 = self:findChild("Text_1") 
    self.m_wheel_coin:setVisible(false)
    self.m_Text_1:setVisible(false)
end

function QuestNewMapBoxBubbleNode:initView()
    local index = 0
    self.m_node_reward:removeAllChildren()
    local propList = {}
    -- 通用道具
    if self.m_rewardData.p_items and #self.m_rewardData.p_items > 0 then
        for i, v in ipairs(self.m_rewardData.p_items) do
            propList[#propList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
        end
    end
    if self.m_rewardData.p_coins and self.m_rewardData.p_coins > 0 then
        propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(self.m_rewardData.p_coins), {p_limit = 3})
    end

    for k,item in pairs(propList) do
        local newItemNode = gLobalItemManager:createRewardNode(item, ITEM_SIZE_TYPE.REWARD_BIG)
        if newItemNode then 
            index = index + 1
            gLobalDailyTaskManager:setItemNodeByExtraData(item, newItemNode)
            self.m_node_reward:addChild(newItemNode)
            newItemNode:setPositionX((index -1)*80)
            newItemNode:setScale(0.4)
        end
    end
    if index >= 1 then
        local width =  110 + (index- 1)* 80
        self.m_sp_qipao:setContentSize(cc.size(width,100))
        self.m_sp_qipao_jiao:setPositionX(width/2)
        self.m_node_reward:setPositionX(55)
    end
end

function QuestNewMapBoxBubbleNode:doShowOrHide()
    if not self.m_isShowingRewards then
        self.m_isShowingRewards = true
        self:showRewardBubble()
    else
        self:forceHideBubble()
    end
end

function QuestNewMapBoxBubbleNode:showRewardBubble()
    if self.m_doAct then
        return 
    end
    self.m_doAct = true
    self.m_node_reward:setVisible(true)
    self:runCsbAction("start",false, function ()
        self.m_doAct = false
        util_performWithDelay(self.m_node_reward, function ()
            if self.m_isShowingRewards then
                if self.m_doAct then
                    return 
                end
                self.m_doAct = true
                self.m_isShowingRewards = false
                self:runCsbAction("over",false, function ()
                    self.m_node_reward:setVisible(false)
                    self.m_doAct = false
                end)
            end
        end, 1)
    end)
end

function QuestNewMapBoxBubbleNode:forceHideBubble()
    if self.m_isShowingRewards then
        if self.m_doAct then
            return 
        end
        self.m_doAct = true
        self.m_isShowingRewards = false
        self.m_node_reward:stopAllActions()
        self:runCsbAction("over",false, function ()
            self.m_node_reward:setVisible(false)
            self.m_doAct = false
        end)
    end
end

return QuestNewMapBoxBubbleNode
