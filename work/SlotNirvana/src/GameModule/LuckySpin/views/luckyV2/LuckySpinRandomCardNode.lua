--[[
]]
local LuckySpinRandomCardNode = class("LuckySpinRandomCardNode", BaseView)

function LuckySpinRandomCardNode:getCsbName()
    return "LuckySpinNew/FireLuckySpinRandomCardLayer_card.csb"
end

function LuckySpinRandomCardNode:initUI(_data)
    LuckySpinRandomCardNode.super.initUI(self)

    self.m_data = _data

    self:updateCardInfo()
end

function LuckySpinRandomCardNode:updateCardInfo()
    -- 节点添加卡片
    self.m_nodeCard = self:findChild("node_card")
    if not self.m_nodeCard then
        return
    end

    self:addChipUnitNode(self.m_data)

    self:runCsbAction("idle")
    
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function LuckySpinRandomCardNode:addChipUnitNode(data)
    if not data then
        return
    end
    
    local chipUnit = util_createView("GameModule.Card.season201903.MiniChipUnit")
    chipUnit:playIdle()
    chipUnit:reloadUI(data, true, true)
    chipUnit:updateTagNew(data.newCard == true) -- 特殊显示逻辑，当玩家没有这张卡的时候显示new，告诉玩家送给玩家的是新卡
    chipUnit:setScale(0.5)
    self.m_nodeCard:addChild(chipUnit)
end

function LuckySpinRandomCardNode:onEnter()
    LuckySpinRandomCardNode.super.onEnter(self)

    -- 集卡下载完 更新卡图片
    if self.m_data and self.m_data.cardId then
        gLobalNoticManager:addObserver(self,
            function(self, params)
                self:addChipUnitNode(self.m_data)
            end,
            CardSysManager:getCardIconDLKey(self.m_data.cardId)
        )
    end
end

return LuckySpinRandomCardNode