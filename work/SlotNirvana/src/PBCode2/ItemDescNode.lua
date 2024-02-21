--道具
local BaseItemNode = util_require("PBCode2.BaseItemNode")
local ItemDescNode = class("ItemDescNode", BaseItemNode)
--初始化csb
function ItemDescNode:getCsbPath()
    return "PBRes/CommonItemRes/ItemDescNode.csb"
end
--更新道具
function ItemDescNode:updateLayoutValue(value)
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
                sp:setPosition(17*i-10,0)
            end
        end
    else
        self.m_lb_value:setString(subtitle)
    end
    --设置名字
    if self.m_lb_name then
        self.m_lb_name:setString(self.m_data:getItemName())
        --先放着不确定是否都要限制大小
        self:updateNameSize()
    end
end
--名字限制大小
function ItemDescNode:updateNameSize()
    --设置名字
    if self.m_lb_name then
        self:updateLabelSize({label = self.m_lb_name},130)
    end
end
return ItemDescNode