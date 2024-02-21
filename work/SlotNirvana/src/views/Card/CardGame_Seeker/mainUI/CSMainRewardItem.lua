--[[
    奖励
]]
local CSMainRewardItem = class("CSMainRewardItem", BaseView)

function CSMainRewardItem:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_MainLayer_Reward_item.csb"
end

function CSMainRewardItem:initDatas(_itemData)
    self.m_itemData = _itemData
end

function CSMainRewardItem:initCsbNodes()
    self.m_nodeItem = self:findChild("node_item")
end

function CSMainRewardItem:initUI()
    CSMainRewardItem.super.initUI(self)
    self:initItems()
    self:playIdle()
end

function CSMainRewardItem:initItems()
    self.m_itemNode = gLobalItemManager:createRewardNode(self.m_itemData, ITEM_SIZE_TYPE.REWARD)
    self.m_itemNode:setScale(0.7)
    assert(self.m_itemNode, "itemNode is nil, itemData.p_icon = " .. self.m_itemData.p_icon)
    self.m_nodeItem:addChild(self.m_itemNode)
end

function CSMainRewardItem:updateNum(_itemData)
    self.m_itemData = _itemData

    -- 刷新创建的奖励中的数字【FUCK!这是一段神奇的代码，有缘者得之】
    local itemNodeData = self.m_itemNode:getItemData()
    if itemNodeData:isBuff() then
        itemNodeData:getBuffInfo():setExpire(self.m_itemData:getBuffInfo():getExpire())
    else
        itemNodeData:setNum(self.m_itemData:getNum() + itemNodeData:getNum())
    end
    self.m_itemNode:updateNum()
end

function CSMainRewardItem:playStart(_over)
    self:runCsbAction(
        "start",
        false,
        function()
            if _over then
                _over()
            end
            self:playIdle()
        end,
        60
    )
end

function CSMainRewardItem:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function CSMainRewardItem:getItemSize()
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.BATTLE_PASS)
    return cc.size(width, width)
end

return CSMainRewardItem
