local FirendHelpCell = class("FirendHelpCell", BaseView)

function FirendHelpCell:initUI()
    self:createCsbNode("Friends/csd/Activity_FriendsMain_help.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self:initView()
end

function FirendHelpCell:initView()
    self.lb_name = self:findChild("lb_name")
    self.lb_desc = self:findChild("lb_desc")
    self.node_frame = self:findChild("node_frame")
    self.node_card = self:findChild("node_card")
    self.sp_normal_bg = self:findChild("sp_normal_bg")
    self.sp_special_bg = self:findChild("sp_special_bg")
    self.lb_time = self:findChild("lb_time")
    self.lb_card = self:findChild("lb_card")
    self.btn_cell = self:findChild("btn_send")
    self.node_qipao = self:findChild("node_qipao")
    self.btn_qipao = self:findChild("btn_qipao")
    self.sp_time_bg = self:findChild("sp_time_bg")
    self.node_btn = self:findChild("node_btn")
    self.btn_qipao:setSwallowTouches(false)
    self.btn_cell:setSwallowTouches(false)
    self:registerListener()
end

function FirendHelpCell:getItemSize()
    return cc.size(841,122)
end

function FirendHelpCell:updataCell(_data,_index)
    self.data = _data
    self.m_index = _index
    self.sp_special_bg:setVisible(false)
    self.sp_normal_bg:setVisible(false)
    local cardData = {}
    cardData.cardId = self.data.cardId
    cardData.count = 0
    local grey = true
    if self.data.tab == 1 then
        self:setButtonLabelAction(self.btn_cell, true)
        self.btn_cell:setTouchEnabled(false)
        self.sp_special_bg:setVisible(true)
        self.btn_qipao:setVisible(false)
    elseif self.data.exist then
        cardData.count = 1
        cardData.type = "NORMAL"
        self.btn_cell:setTouchEnabled(true)
        self:setButtonLabelAction(self.btn_cell, false)
        self.sp_normal_bg:setVisible(true)
        self.btn_qipao:setVisible(false)
        grey = nil
    else
        self:setButtonLabelAction(self.btn_cell, true)
        self.btn_cell:setTouchEnabled(false)
        self.sp_normal_bg:setVisible(true)
        self.btn_qipao:setVisible(true)
    end
    self.node_btn:setVisible(true)
    self.sp_time_bg:setVisible(true)
    self.node_card:setPositionX(119)
    self.lb_card:setPositionX(119)
    if globalData.userRunData.userUdid == self.data.udid then
        self.node_card:setPositionX(305)
        self.lb_card:setPositionX(305)
        self.node_btn:setVisible(false)
        self.sp_time_bg:setVisible(false)
    end
    self.lb_name:setString(self.data.name)
    local head_node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
        self.data.facebookId, 
        self.data.head, 
        self.data.headFrame, 
        nil,
        cc.size(100,100))
    if head_node then
        self.node_frame:addChild(head_node)
    end
    if self.data.stars then
        cardData.star = self.data.stars
    end
    if self.data.cardName then
        self.lb_card:setString("")
        cardData.name = self.data.cardName
    end

    local chipItem = util_createView("GameModule.Card.season201903.MiniChipUnit")
    chipItem:playIdle()
    chipItem:reloadUI(cardData, true,nil,nil,nil,grey)
    chipItem:addTo(self.node_card)
    chipItem:setScale(0.25)
    self.cut_time = math.floor(self.data.expireAt/1000) - util_getCurrnetTime()
    self:updatetTimes()
    

    if self.m_index == 1 then
        self.node_qipao:setPositionY(0)
    else
        self.node_qipao:setPositionY(18)
    end
end

function FirendHelpCell:addQiPao()
    if self.qipao_layer and not tolua.isnull(self.qipao_layer) then
        self.qipao_layer:removeFromParent()
        self.qipao_layer = nil
    end
    self.qipao_layer = util_createView("views.FirendCode.FirendHelpQiPao")
    self.qipao_layer:updataUI(self.data,nil,nil)
    self.qipao_layer:showAction()
    self.node_qipao:addChild(self.qipao_layer)
end

function FirendHelpCell:updatetTimes()
    if self.cut_time > 0 then
        self:setTimeStr(self.cut_time)
        self:clearSchedule()
        self.m_schedu =
            schedule(
            self,
            function()
                self.cut_time = self.cut_time - 1
                if self.cut_time == 0 then
                    local param = {}
                    param.type = 1
                    param.cardId = self.data.id
                    gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.CARD_SUCCESS, param)
                    self:clearSchedule()
                else
                    self:setTimeStr(self.cut_time)
                end
            end,
            1
        )
    end
end

function FirendHelpCell:setTimeStr(_time)
    if _time > 0 then
        if self.lb_time then
            local str = util_daysdemaining1(_time)
            self.lb_time:setString(str)
        end
    end
end

function FirendHelpCell:clearSchedule()
    if self.m_schedu then
        self:stopAction(self.m_schedu)
        self.m_schedu = nil
    end
end

function FirendHelpCell:registerListener()
   
end

function FirendHelpCell:playAction(_callback)
    self:runCsbAction("start",false,function()
        if _callback then
            _callback()
        end
    end)
end

function FirendHelpCell:clickCell()
end

function FirendHelpCell:clickStartFunc(sender)
end

function FirendHelpCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_send" then
        --查看个人信息
        if self.m_click then
            return
        end
        self.ManGer:requestSendCard("SendCard", self.data.id,"CARD",{self.data.udid},{[tostring(self.data.cardId)] = 1})
        self.m_click = true
    elseif name == "btn_qipao" then
        self:addQiPao()
    end
end

return FirendHelpCell