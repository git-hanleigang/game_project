--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-10 10:23:17
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_BFDraw = class("InboxItem_BFDraw", InboxItem_base)

function InboxItem_BFDraw:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_BFDraw:getCardSource()
    return {"Black Friday"}
end
-- 描述说明
function InboxItem_BFDraw:getDescStr()
    return "BLACK FRIDAY DRAW"
end

function InboxItem_BFDraw:initReward()
    if not self.m_sp_coin or not self.m_lb_coin or not self.m_lb_add or not self.m_node_reward then 
        return
    end
    
    local coinLen, itemLen = self:getRewardLen()
    -- 金币
    if toLongNumber(self.m_coins) > toLongNumber(0) then 
        local strCoins = util_formatCoins(self.m_coins, coinLen)
        self.m_lb_coin:setString(strCoins)
        local size = self.m_sp_coin:getContentSize()
        local scale = self.m_sp_coin:getScale()
        table.insert(self.m_uiList, {node = self.m_sp_coin, alignX = -size.width/2*scale})
        table.insert(self.m_uiList, {node = self.m_lb_coin, alignX = 5.5})
        table.insert(self.m_uiList, {node = self.m_lb_add, alignX = 3.5})
    else
        self.m_sp_coin:setVisible(false)
        self.m_lb_coin:setVisible(false)
        self.m_lb_add:setVisible(false)
    end

    -- 高倍场点数 非道具就是数值
    if #self.m_items > 0 or self.m_deluxePoint > 0 then 
        self.m_shopItemList = self:mergeItems(self.m_items)
        for i,v in ipairs(self.m_shopItemList) do
            if i > itemLen then 
                return
            end
            if string.find(v.p_icon, "Coupon") then --促销优惠券
                v:setTempData({p_mark = {{ITEM_MARK_TYPE.NONE}}})
            end
            if string.find(v.p_icon, "club_pass_") then -- 高倍场体验卡
                v:setTempData({p_num = 1})
            end
            local itemNode = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.TOP)
            if itemNode then
                itemNode:setScale(0.8)
                self.m_node_reward:addChild(itemNode)
                local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP) * 1
                local sizeNode = cc.size(width, width)
                table.insert(self.m_uiList, {node = itemNode, alignX = 3, alignY = 2, size = sizeNode, anchor = {x = 0.5, y = 0.5}})
            end
        end
    else
        self.m_lb_add:setVisible(false)
    end
end

return InboxItem_BFDraw