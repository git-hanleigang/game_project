--道具
local BaseItemNode = util_require("PBCode2.BaseItemNode")
local ItemDescSingleNumNode = class("ItemDescSingleNumNode", BaseItemNode)
--初始化csb
function ItemDescSingleNumNode:getCsbPath()
    return "PBRes/CommonItemRes/ItemDescNode_SingleNum.csb"
end
--更新道具
function ItemDescSingleNumNode:updateLayoutValue(value)
    self.m_lb_name:setVisible(false)
    local itemInfo = self.m_data.p_itemInfo
    if not itemInfo then
        return
    end
    local subtitle = self.m_data:getSubtitle(value)
    if subtitle == ITEM_DESC_NODEVALUE.NODE_STAR then
        --集卡特殊道具需要显示星星
        self.m_lb_value:setVisible(false)
        local node_value = self:findChild("node_value")
        if node_value and self.m_data.p_mark[3] then
            for i=1,self.m_data.p_mark[3] do
                local sp = util_createSprite("PBRes/CommonItemRes/other/card_star.png")
                node_value:addChild(sp)
                sp:setPosition(17*i-10,-10) -- 修改1
            end
        end
        -- 卡牌的话 需要修改节点位置
        --设置名字
        if self.m_lb_name then
            self.m_lb_name:setVisible(true) -- 修改2
            self.m_lb_name:setString(self.m_data:getItemName())
            --先放着不确定是否都要限制大小
            self:updateNameSize()
        end
    elseif subtitle == ITEM_DESC_NODEVALUE.NODE_JACKPOT_RETURN then
        if self.m_lb_name then
            self.m_lb_name:setVisible(true) -- 修改2
            self.m_lb_name:setString(self.m_data:getItemName())
            --先放着不确定是否都要限制大小
            self:updateNameSize()
        end
        self.m_lb_value:setString(subtitle)
        self.m_lb_value:setPositionY(self.m_lb_value:getPositionY() - 10)
    elseif self.m_data:getItemName()  == "ECHO WINS" then
        local dataName = string.split(self.m_data:getItemName()," ")
        if self.m_lb_name then
            self.m_lb_name:setVisible(true) -- 修改2
            self.m_lb_name:setString(dataName[1])
        end
        self.m_lb_value:setString(dataName[2])
        self.m_lb_value:setPositionY(self.m_lb_value:getPositionY() - 10)
    else
        self.m_lb_value:setString(subtitle)
        if string.find(subtitle,"+") then
            self.m_lb_value:setFontSize(32)
        end
    end
end

--名字限制大小
function ItemDescSingleNumNode:updateNameSize()
    --设置名字
    if self.m_lb_name then
        self:updateLabelSize({label = self.m_lb_name},130)
    end
end

return ItemDescSingleNumNode