local FirendRequestCell = class("FirendRequestCell", BaseView)

function FirendRequestCell:initUI()
    self:createCsbNode("Friends/csd/Activity_Friends_Requests_info.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self:initView()
end

function FirendRequestCell:initView()
    self.lb_name = self:findChild("lb_name")
    self.lb_level = self:findChild("lb_level")
    self.node_frame = self:findChild("node_frame")
    self.btn_accept = self:findChild("btn_decline")
    self.btn_accept:setSwallowTouches(false)
    self.btn_request = self:findChild("btn_accept")
    self.btn_request:setSwallowTouches(false)
    self.btn_black = self:findChild("btn_block")
    self.btn_black:setSwallowTouches(false)
    local btn_layer = self:findChild("btn_layer")
    btn_layer:setSwallowTouches(false)
    self:addClick(btn_layer)
    self:registerListener()
end

function FirendRequestCell:getItemSize()
    return cc.size(975,122)
end

function FirendRequestCell:updataCell(_data)
    self.data = _data
    self.lb_name:setString(self.data.name)
    self.lb_level:setString("LEVEL:"..self.data.level)
    self.md_id = 1
    if self.data.facebookId then
        self.md_id = self.data.facebookId
    else
        self.md_id = self.data.udid
    end
    local head_node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
        self.md_id, 
        self.data.head, 
        self.data.headFrame, 
        nil,
        cc.size(90,90))
    if head_node then
        self.node_frame:addChild(head_node)
    end
    self.btn_black:setVisible(false)
    --添加已经超过三次
    if self.data.screening then
        self.btn_black:setVisible(true)
    end
end

function FirendRequestCell:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            -- if params.type == FriendConfig.QuestType.Pass then
            --     --刷新好友列表
            -- elseif params.type == FriendConfig.QuestType.Refuse then
            -- elseif params.type == FriendConfig.QuestType.Screening then
            -- end
            self.isclick = false
            if params.uid == self.data.udid then
                self.btn_accept:setTouchEnabled(false)
                self.btn_request:setTouchEnabled(false)
                self.btn_black:setTouchEnabled(false) 
                self:findChild("btn_layer"):setTouchEnabled(false)   
            end
        end,
        FriendConfig.EVENT_NAME.REQUEST_FRIEND
    )
end

function FirendRequestCell:clickCell()
end

function FirendRequestCell:clickStartFunc(sender)
    local name = sender:getName()
end

function FirendRequestCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_block" then
        --屏蔽黑名单
        self.isclick = true
        self.ManGer:requestAddFriend(FriendConfig.QuestType.Screening,self.data.udid)
    elseif name == "btn_decline" then
        --拒接
        self.isclick = true
        self.ManGer:requestAddFriend(FriendConfig.QuestType.Refuse,self.data.udid)
    elseif name == "btn_accept" then
        --接受
        self.isclick = true
        local count = self.ManGer:getData():getCourentCount()
        if count and count >= self.ManGer:getMaxCount() then
            local _callback = function()
                self.ManGer:requestAddFriend(FriendConfig.QuestType.Refuse,self.data.udid)
            end
            self.ManGer:showErrorLayer(_callback)
            return
        end
        self.ManGer:requestAddFriend(FriendConfig.QuestType.Pass,self.data.udid)
    elseif name == "btn_layer" then
        if self.isclick then
            return
        end
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.data.udid, "","",self.data.head)
    end
end

return FirendRequestCell