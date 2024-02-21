local FirendHeadCell = class("FirendHeadCell", BaseView)

function FirendHeadCell:initUI()
    self:createCsbNode("Friends/csd/Activity_FriendsMain_frame.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self:initView()
end

function FirendHeadCell:initView()
    self.lb_name = self:findChild("lb_name")
    self.lb_sname = self:findChild("lb_sname")
    self.lb_layer = self:findChild("layout_sw")
    self.sp_fb = self:findChild("sp_fb")
    self.lb_contentsize = self.lb_layer:getContentSize()
    self.node_frame = self:findChild("node_frame")
    local btn_cell = self:findChild("btn_cell")
    self.node_qipao = self:findChild("node_qipao")
    btn_cell:setSwallowTouches(false)
end

function FirendHeadCell:updataCell(_data,_idx,_index)
    self.m_zorder = self:getZOrder()
    self.m_index = _index
    self.data = _data
    self:updataName(self.data.p_name)
    local size = cc.size(100,100)
    local head_node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
        self.data.p_facebookId, 
        self.data.p_facebookHead, 
        self.data.p_facebookHeadFrame, 
        nil,
        size)
    if head_node then
        self.node_frame:addChild(head_node)
    end
    if self.data.p_isSysFriend then
        self.sp_fb:setVisible(false)
    else
        self.sp_fb:setVisible(true)
    end
end

function FirendHeadCell:updataName(name)
    self.lb_name:setString(name)
    self.lb_sname:setString(name)

    local lbSize = self.lb_name:getContentSize()
    if lbSize.width > self.lb_contentsize.width then
        self.lb_name:setVisible(false)
        self.lb_layer:setVisible(true)
        util_wordSwing(self.lb_sname, 1, self.lb_layer, 2, 30, 2) 
    else
        self.lb_name:setVisible(true)
        self.lb_layer:setVisible(false)
        self.lb_sname:stopAllActions()
    end
end

function FirendHeadCell:clickCell()
    self:setZOrder(100)
    local callback = function()
        self:setZOrder(self.m_zorder)
    end
    if self.qipao_layer and not tolua.isnull(self.qipao_layer) then
        self.qipao_layer:removeFromParent()
        self.qipao_layer = nil
    end
    gLobalSoundManager:playSound(FriendConfig.Sounds.QIPAO)
    self.qipao_layer = util_createView("views.FirendCode.FirendHeadQiPao")
    self.qipao_layer:updataUI(self.data,self.m_index,callback)
    self.qipao_layer:showAction()
    self.node_qipao:addChild(self.qipao_layer)
end

function FirendHeadCell:clickStartFunc(sender)
end

function FirendHeadCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_cell" then
        self:clickCell()
    end
end

return FirendHeadCell