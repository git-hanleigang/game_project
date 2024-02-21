local UserInfoFramCell = class("UserInfoFrame", BaseView)

function UserInfoFramCell:initUI()
    self:createCsbNode("Activity/csd/Information_Frame/Information_frame3.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:initView()
end

function UserInfoFramCell:initView()
    self.sp_frame_bottom = self:findChild("sp_frame_bottom")
    self.sp_choicebox = self:findChild("sp_choicebox")
    self.sp_true = self:findChild("sp_true")
    local node_headCsb = self:findChild("Node_head")
    local nodeHeadRef = display.newNode()
    nodeHeadRef:setPosition(96,72)
    node_headCsb:addChild(nodeHeadRef)
    self.head_node = nodeHeadRef

    local btn_cell = self:findChild("btn_cell")
    btn_cell:setSwallowTouches(false)
end

function UserInfoFramCell:updataCell(_data)
    self._data = _data
    local shop1 = self.head_node:getChildByName("head_frameCell")
    if shop1 ~= nil and not tolua.isnull(shop1) then
        self.head_node:removeAllChildren()
    end
    local userResHeadIdx = tonumber(globalData.userRunData.HeadName or 1)
    local head_sprite = nil
    if self._data == 0 and gLobalSendDataManager:getIsFbLogin() then
        head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(globalData.userRunData.facebookBindingID, _data, nil, false, cc.size(105,105), false)
    else
        head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(nil, _data, nil, false, cc.size(105,105))
    end
    if head_sprite then
        self.head_node:addChild(head_sprite)
        head_sprite:setName("head_frameCell")
    end
    if _data == self.ManGer:getHeadIndex() then
        self.sp_choicebox:setVisible(true)
    else
        self.sp_choicebox:setVisible(false)
    end
    if _data == userResHeadIdx then
        self.sp_true:setVisible(true)
    else
        self.sp_true:setVisible(false)
    end
    self:registerListener()
end

function UserInfoFramCell:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self.sp_choicebox:setVisible(self._data == self.ManGer:getHeadIndex())
    end,self.config.ViewEventType.FRAME_ITEM_CLICK)

    gLobalNoticManager:addObserver(self,function(self, itemData)
        local userResHeadIdx = tonumber(globalData.userRunData.HeadName or 1)
        self.sp_true:setVisible(self._data == userResHeadIdx)
    end,self.config.ViewEventType.NOTIFY_USERINFO_MODIFY_SUCC)

    gLobalNoticManager:addObserver(
        self,
        function(Target, loginInfo)
            self:checkFBLoginState(loginInfo)
        end,
        GlobalEvent.FB_LoginStatus,
        true
    )
end

function UserInfoFramCell:clickCell()
    if self._data == 0 and not gLobalSendDataManager:getIsFbLogin() then
        self:setFbHead()
        return
    end
    self.ManGer:setHeadIndex(self._data)
    gLobalNoticManager:postNotification(self.config.ViewEventType.FRAME_ITEM_CLICK,self._data)
end

function UserInfoFramCell:clickStartFunc(sender)
end

function UserInfoFramCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_cell" then
        if self._data == 0 and not gLobalSendDataManager:getIsFbLogin() then
            self:setFbHead()
            return
        end
        self.ManGer:setHeadIndex(self._data)
        gLobalNoticManager:postNotification(self.config.ViewEventType.FRAME_ITEM_CLICK,self._data)
    end
end

function UserInfoFramCell:setFbHead()
    if globalFaceBookManager:getFbLoginStatus() then
        release_print("xcyy : FbLoginStatus")
        globalData.skipForeGround = true
        gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_TopIcon)
    else
        gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos=LOG_ENUM_TYPE.BindFB_TopIcon
        globalFaceBookManager:fbLogin()
        release_print("xcyy : FbLoginStatus fail")
    end
end

function UserInfoFramCell:checkFBLoginState(loginInfo)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" then
        supportVersion = "1.6.6"
    elseif platform == "android" then
        supportVersion = "1.5.8"
    end

    if supportVersion ~= nil and util_isSupportVersion(supportVersion) then
        local loginState = loginInfo.state
        local msg = loginInfo.message
        --成功
        if loginState == 1 then
            --取消
            self:updataFB()
        elseif loginState == 0 then
            --失败
        else
        end
    else
        if loginInfo then
            self:updataFB()
        end
    end
end

function UserInfoFramCell:updataFB()
    if not gLobalSendDataManager:getIsFbLogin() then
        return
    end
    local shop1 = self.head_node:getChildByName("head_frameCell")
    if shop1 ~= nil and not tolua.isnull(shop1) then
        self.head_node:removeAllChildren()
    end
    local head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(globalData.userRunData.facebookBindingID, _data, nil, false, cc.size(105,105), false)
    head_sprite:setPosition(96,72)
    self.head_node:addChild(head_sprite)
    head_sprite:setName("head_frameCell")
end

return UserInfoFramCell