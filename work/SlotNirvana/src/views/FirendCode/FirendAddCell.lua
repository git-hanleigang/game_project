local FirendAddCell = class("FirendAddCell", BaseView)

function FirendAddCell:initUI()
    self:createCsbNode("Friends/csd/Activity_Friends_AddMain_recommended.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self:initView()
end

function FirendAddCell:initView()
    self.lb_name = self:findChild("lb_name")
    self.lb_level = self:findChild("lb_level")
    self.node_frame = self:findChild("node_frame")
    local btn_cell = self:findChild("btn_prol")
    self:addClick(btn_cell)
    btn_cell:setSwallowTouches(false)
    self.btn_request = self:findChild("btn_request")
    self.btn_request:setSwallowTouches(false)
    self:registerListener()
end

function FirendAddCell:getItemSize()
    return cc.size(975,122)
end

function FirendAddCell:updataCell(_data)
    self.data = _data
    self.lb_name:setString(self.data.name)
    self.lb_level:setString("LEVEL:"..self.data.level)
    local head_node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
        self.data.facebookId, 
        self.data.head, 
        self.data.headFrame, 
        nil,
        cc.size(100,100))
    if head_node then
        self.node_frame:addChild(head_node)
    end
end

function FirendAddCell:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _num)
            if _num then
                return
            end
            if self.ManGer:getAdduid() == self.data.udid then
                self.btn_request:setTouchEnabled(false)
                gLobalSoundManager:playSound(FriendConfig.Sounds.CUT_BTN)
                self:runCsbAction("start",false,function()
                    self:runCsbAction("over",true)
                end)
            end
        end,
        FriendConfig.EVENT_NAME.ADD_SERCH_SUCCESS
    )
end

function FirendAddCell:clickCell()
end

function FirendAddCell:clickStartFunc(sender)
end

function FirendAddCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_prol" then
        --查看个人信息
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.data.udid, "","",self.data.head)
    elseif name == "btn_request" then
        --添加他为好友
        if self.ManGer:getAddStuts() == 0 then
            self.ManGer:setAddStuts(1)
            self.ManGer:setAdduid(self.data.udid)
            self.ManGer:requestAddFriend("Apply",self.data.udid,nil,"3")
        end
        
    end
end

return FirendAddCell