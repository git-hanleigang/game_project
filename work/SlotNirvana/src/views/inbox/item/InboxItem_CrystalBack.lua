-- 新版新关挑战 邮件
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_CrystalBack = class("InboxItem_CrystalBack", InboxItem_base)

function InboxItem_CrystalBack:getCsbName()
    return "InBox/InboxItem_CrystalBack.csb"
end

-- 描述说明
function InboxItem_CrystalBack:getDescStr()
    return "CRYSTAL BACK"
end

function InboxItem_CrystalBack:initView()
    self:initData()
    self:initDesc()
    self:initReward()
end

function InboxItem_CrystalBack:initReward()
    local lb_num = self:findChild("lb_num")
    local num = 0 
    if self.m_items and #self.m_items > 0 then
        local item = self.m_items[1]
        num = item.num
    end
    lb_num:setString(num)

    self.m_sp_coin:setVisible(false)
    self.m_lb_coin:setVisible(false)
    self.m_lb_add:setVisible(false)
end

function InboxItem_CrystalBack:collectMailSuccess()
    local view = util_createView("views.inbox.item.InboxItem_CrystalBackReward", self.m_items)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:removeSelfItem()
end

return InboxItem_CrystalBack
