--道具
local BaseItemNode = util_require("PBCode2.BaseItemNode")
local ItemTipNode = class("ItemTipNode", BaseItemNode)
--初始化csb
function ItemTipNode:getCsbPath()
    return "PBRes/CommonItemRes/ItemTipNode_Shop2022.csb"
end
--更新道具
function ItemTipNode:updateLayoutValue(value)
    local itemInfo = self.m_data.p_itemInfo
    if not itemInfo then
        return
    end
    if self.m_lb_value then
        self.m_lb_value:setString(self.m_data:getSubtitle(value))
    end
    if self.m_lb_name then
        local lineNum,lineStrVec = util_AutoLine(self.m_lb_name,self.m_data:getItemName(),280,true)
        if self.m_lb_name_sub then
            self.m_lb_name_sub:setVisible(false)
            if lineNum > 1 and lineStrVec and #lineStrVec > 1 then
                for i=1,2 do
                    self.m_lb_name:setString(lineStrVec[1])
                    self.m_lb_name_sub:setString(lineStrVec[2])
                    self.m_lb_value:setPositionY(-91)
                    self.m_lb_name_sub:setVisible(true)
                    self.m_lb_name_sub:setPositionY(-70)
                    self.m_lb_name:setPositionY(-52)
                end
            end
        end
    end
    local lb_desc = self:findChild("lb_desc")
    -- csc 2022-02-15 隐藏掉字段
    lb_desc:setVisible(false)
    -- if lb_desc then
    --     local extraDesc = self.m_data:getBuyTipDesc()
    --     if extraDesc then
    --         lb_desc:setString(extraDesc)
    --     else
    --         lb_desc:setVisible(false)
    --     end
    -- end
end
return ItemTipNode