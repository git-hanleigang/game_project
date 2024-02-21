local InviteeItem = class("InviteeItem", BaseView)

function InviteeItem:initUI()
    self:createCsbNode("Activity/InviteeItem.csb")
    self.m_data = G_GetMgr(G_REF.Invite):getData()
end

function InviteeItem:initCsbNodes()
    self.leave_text = self:findChild("Text_level")
    self.Loadingbar = self:findChild("Loadingbar")
end

function InviteeItem:updataView(_data,_cltype)
    local intee_data = self.m_data:getInviteeReward()
    local free_data = _data.free
    local pay_data = _data.pay
    local di_level = self.m_data:getLevel() + free_data.value
    self.Loadingbar:setPercent(_data.parent*100)
    if globalData.userRunData.levelNum >= di_level and free_data.value == intee_data.freeRewards[#intee_data.freeRewards].value then
        self.Loadingbar:setPercent(100)
    end
    self.leave_text:setString(di_level)
    local node_ex = self:findChild("Node_exp")
    local node_gl = self:findChild("Node_genl")
    if node_ex:getChildByName("view_pay") and not tolua.isnull(node_ex:getChildByName("view_pay")) then
        node_ex:removeChildByName("view_pay")
    end
    local view_ex = util_createView("views.Invite.Activity.InviteeExpressItem")
    view_ex:updataView(pay_data,_cltype)
    node_ex:addChild(view_ex)
    view_ex:setName("view_pay")
    if node_gl:getChildByName("view_free") and not tolua.isnull(node_gl:getChildByName("view_free")) then
        node_gl:removeChildByName("view_free")
    end
    local view_gl = util_createView("views.Invite.Activity.InviteeGeneralItem")
    view_gl:updataView(free_data)
    node_gl:addChild(view_gl)
    view_gl:setName("view_free")
end
function InviteeItem:getItemSize()
    return cc.size(200,435)
end
function InviteeItem:clickStartFunc(sender)
end

function InviteeItem:clickFunc(sender)
end
return InviteeItem