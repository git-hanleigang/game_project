--[[
    pass 气泡
]]

local QuestPassRewardBubble = class("QuestPassRewardBubble", BaseView)

function QuestPassRewardBubble:getCsbName()
    return QUEST_RES_PATH.QuestPassBoxBubble
end

function QuestPassRewardBubble:initCsbNodes()
    
end

function QuestPassRewardBubble:initUI(_data)
    QuestPassRewardBubble.super.initUI(self)

    self.m_status = "hide"
    self.m_action = false
    local hasCoins = false

    if _data.p_coins and _data.p_coins > 0 then 
        hasCoins = true
        self.m_itemData = gLobalItemManager:createLocalItemData("Coins", _data.p_coins)
        self.m_itemData:setTempData({p_limit = 3})
        self.m_itemNode = gLobalItemManager:createRewardNode(self.m_itemData, ITEM_SIZE_TYPE.TOP)
        local node_reward = self:findChild("node_reward1")
        node_reward:addChild(self.m_itemNode)
    end

    if _data.p_items and #_data.p_items > 0 then
        local nodeIdx = hasCoins and 1 or 0
        for i,v in ipairs(_data.p_items) do
            local node_reward = self:findChild("node_reward" .. nodeIdx + i)
            if node_reward then
                self.m_itemData = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
                self.m_itemNode = gLobalItemManager:createRewardNode(self.m_itemData, ITEM_SIZE_TYPE.TOP)
                node_reward:addChild(self.m_itemNode)
            end
        end
    end
end

function QuestPassRewardBubble:playAction()
    if not self.m_action then
        if self.m_status == "show" then
            self:playHide()
        else
            self:playShow()
        end
    end
end

function QuestPassRewardBubble:playShow()
    self:stopAllActions()
    self.m_action = true
    self:runCsbAction("start", false, function ()
        self.m_status = "show"
        self.m_action = false
        performWithDelay(self, function ()
            self:playAction()
        end, 3)
    end, 60)
end

function QuestPassRewardBubble:playHide()
    self:stopAllActions()
    self.m_action = true
    self:runCsbAction("over", false, function ()
        self.m_status = "hide"
        self.m_action = false
    end, 60)
end

return QuestPassRewardBubble