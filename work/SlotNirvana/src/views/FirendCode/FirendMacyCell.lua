local FirendMacyCell = class("FirendMacyCell", BaseView)

function FirendMacyCell:initUI()
    self:createCsbNode("Friends/csd/Activity_FriendsMain_intimacy.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self:initView()
end

function FirendMacyCell:initView()
    self.lb_name = self:findChild("lb_name")
    self.lb_sname = self:findChild("lb_sname")
    self.lb_layer = self:findChild("layout_sw")
    self.lb_level = self:findChild("lb_level")
    self.node_frame = self:findChild("node_frame")
    self.sp_fb = self:findChild("sp_fb")
    self.sp_progress = self:findChild("sp_progress")
    self.lb_progress = self:findChild("lb_progress")
    self.sp_icon1 = self:findChild("sp_label1")
    self.sp_icon2 = self:findChild("sp_label2")
    self.lb_contentsize = self.lb_layer:getContentSize()
end

function FirendMacyCell:getItemSize()
    return cc.size(841,122)
end

function FirendMacyCell:updataCell(_data)
    self.data = _data
    --self.lb_name:setString(self.data.p_name)
    self:updataName(self.data.p_name)
    self.lb_level:setString("LEVEL:"..self.data.p_level)
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
    local per = self.data.p_curFriendliness/self.data.p_maxFriendliness
    self.sp_progress:setPercent(math.floor(per * 100))
    self.lb_progress:setString(self.data.p_curFriendliness.."/"..self.data.p_maxFriendliness)
    if self.data.p_friendlinessLevel >= 5 then
        util_changeTexture(self.sp_icon1,FriendConfig.macy_img[4])
        self.sp_progress:setPercent(100)
        self.lb_progress:setString("MAX")
        util_changeTexture(self.sp_icon2,FriendConfig.macy_img[5])
    else
        util_changeTexture(self.sp_icon1,FriendConfig.macy_img[self.data.p_friendlinessLevel])
        util_changeTexture(self.sp_icon2,FriendConfig.macy_img[self.data.p_friendlinessLevel+1])
    end
    
end

function FirendMacyCell:updataName(name)
    self.lb_name:setString(name)
    self.lb_sname:setString(name)

    local lbSize = self.lb_name:getContentSize()
    if lbSize.width > self.lb_contentsize.width then
        self.lb_name:setVisible(false)
        self.lb_layer:setVisible(true)
        util_wordSwing(self.lb_sname, 1, self.lb_layer, 2, 38, 2) 
    else
        self.lb_name:setVisible(true)
        self.lb_layer:setVisible(false)
        self.lb_sname:stopAllActions()
    end
end

return FirendMacyCell