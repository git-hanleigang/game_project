--[[
    剩余食材邮件
]]
local InboxItem_diningRoomFood = class("InboxItem_diningRoomFood", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_diningRoomFood:getCsbName( )
    return "InBox/InboxItem_diningRoomFood.csb"
end

function InboxItem_diningRoomFood:initView()
    self:initNode()
    local awards = self.m_mailData.awards
    self.m_coins = tonumber(awards.coins)
    self:updateCoinNum(self.m_coins)
end

--初始化节点
function InboxItem_diningRoomFood:initNode()
    self.m_lb_coins = self:findChild("label_coin")
end
--更新金币数
function InboxItem_diningRoomFood:updateCoinNum(_num)
    local num = tonumber(_num)
    if num > 0 then 
        local strCoins = util_formatCoins(num,9)
        self.m_lb_coins:setString(strCoins)
        self:updateLabelSize({label = self.m_lb_coins},265)
    else
        self.m_lb_coins:setString(0)
    end
end

return  InboxItem_diningRoomFood