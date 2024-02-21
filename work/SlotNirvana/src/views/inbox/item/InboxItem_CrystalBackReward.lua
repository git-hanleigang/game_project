--[[--
    宝石返还
]]

local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_CrystalBackReward = class("InboxItem_CrystalBackReward", BaseLayer)

function InboxItem_CrystalBackReward:ctor()
    InboxItem_CrystalBackReward.super.ctor(self)

    self:setLandscapeCsbName("InBox/CrystalBack_RewardLayer.csb")
    self:setExtendData("InboxItem_CrystalBackReward")
end

function InboxItem_CrystalBackReward:initDatas(_items)
    self.m_items = _items
end

function InboxItem_CrystalBackReward:initCsbNodes()
    self.m_node_reward = self:findChild("node_reward")
    self.m_lb_num = self:findChild("lb_num")
end

function InboxItem_CrystalBackReward:initView()
    local num = 0
    if self.m_items and #self.m_items > 0 then
        local item = self.m_items[1]
        num = item.num
    end
    self.m_lb_num:setString(num)
end

function InboxItem_CrystalBackReward:clickFunc(sender)
    if self.m_isTouch then
        return
    end
    self.m_isTouch = true

    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function InboxItem_CrystalBackReward:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

return InboxItem_CrystalBackReward