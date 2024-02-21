--被邀请者界面
local Activity_Invitee = class("Activity_Invitee",BaseLayer)

function Activity_Invitee:ctor()
    Activity_Invitee.super.ctor(self)
    self:setLandscapeCsbName("Activity/Inviteemain_MainLayer.csb")
    self:setExtendData("Activity_Invitee")
    self.m_data = G_GetMgr(G_REF.Invite):getData()
    self.MangeMr = G_GetMgr(G_REF.Invite)
    self.config = G_GetMgr(G_REF.Invite):getConfig()
end

function Activity_Invitee:initCsbNodes()
    self.listView = self:findChild("listView")
    self.lb_unlock = self:findChild("lb_unlock")
    self.lab_all = self:findChild("label_1")
    self.commonbtny = self:findChild("commonbtny")
    self.btn_all = self:findChild("btn_spin")
    self.MangeMr:getInviteeVs()
end

function Activity_Invitee:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
    self:startButtonAnimation("btn_spin", "sweep", true)
    local invite_Data = self.m_data:getInviteeReward()
    local item_data = self.MangeMr:getInviteeItems()
    self:reshfh()
    self.lb_unlock:setString("UNLOCK $"..invite_Data.price)
    self:setListView(item_data)
end

function Activity_Invitee:reshfh()
    local invite_Data = self.m_data:getInviteeReward()
    self.commonbtny:setPositionX(205)
    self.btn_all:setPositionX(0)
    local anniu = 0
    local all = 0
    if invite_Data ~= nil and invite_Data.pay == true then
        anniu = 1
        self.commonbtny:setVisible(false)
    end
    local all_rew = self.MangeMr:getAllCollect()
    if all_rew.coin_num == 0 and #all_rew.prop == 0 then
        all = 1
        self.btn_all:setVisible(false)
    else
        self.btn_all:setVisible(true)
    end
    if anniu == 0 and all == 1 then
        self.commonbtny:setPositionX(0)
    end
    if anniu == 1 and all == 0 then
        self.btn_all:setPositionX(210)
    end
end

function Activity_Invitee:onEnter()
    Activity_Invitee.super.onEnter(self)
    local guideStep = gLobalDataManager:getNumberByField(self.config.EVENT_NAME.INVITEE_GUIDER, 1)
    if guideStep ~= 2 then
        local node_gl = self:findChild("node_general")
        local node_ex = self:findChild("node_express")
        local node_list = {node_gl,node_ex}

        self.MangeMr:showGuideLayer(2,node_list)
        -- self.up_time = 0
        -- self.m_timeScheduler = schedule(self, handler(self, self.updateUI), 0.1)
    end
    performWithDelay(self, function()
            local item = self.MangeMr:getHistoryItem()
            local percent = self:getJumpPercent(item-1)
            self.listView:scrollToPercentHorizontal(percent, 0.3, false)
    end, 0.1)
 
end

function Activity_Invitee:updateUI()
    self.up_time = self.up_time + 0.1
    if self.up_time >= 1.5 then
        local item = self.MangeMr:getHistoryItem()
        local percent = self:getJumpPercent(item-1)
        self.listView:scrollToPercentHorizontal(percent, 0.1, false)
        if self.m_timeScheduler then
            self:stopAction(self.m_timeScheduler)
            self.m_timeScheduler = nil
        end
    elseif self.up_time == 0.1 then
        self.listView:scrollToPercentHorizontal(100, 0.8, false)
    end
end

function Activity_Invitee:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function()
            self:setListView(self.MangeMr:getInviteeItems())
            if self.MangeMr:getRewardAll() == 1 then
                self:showAllReward()
            end
            performWithDelay(self, function()
                self:reshfh()
            end, 0.5)
        end,
        self.config.EVENT_NAME.INVITEE_UPDATA_PAY
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            self.MangeMr:sendDataReq()
            self.collect = 1
        end,
        ViewEventType.NOTIFY_ACTIVITY_INVITE_BUY_SUCCESS
    )
end

function Activity_Invitee:setListView(_data)
    self.listView:removeAllChildren()
    for i,v in ipairs(_data) do
        local view = util_createView("views.Invite.Activity.InviteeItem")
        local size = view:getItemSize()
        view:updataView(v,self.collect)
        local layout = ccui.Layout:create()
        layout:setContentSize({width = size.width, height = size.height})
        view:setPosition(size.width/2,size.height/2-5)
        layout:addChild(view)
        self.listView:pushBackCustomItem(layout)
    end
    self.collect = nil
end
function Activity_Invitee:showAllReward()
    local view = util_createView("views.Invite.Activity.InvitaRewardAll")
    self:addChild(view)
end
function Activity_Invitee:getJumpPercent(_distance,moveNode)
    local percent = 1
    local innerSize = self.listView:getInnerContainerSize()
    local conSize = self.listView:getContentSize()
    local maxWidth = innerSize.width - conSize.width
    local moveDis = 200*_distance
    percent = moveDis*100 / maxWidth
    return percent
end
function Activity_Invitee:closeUI()
    local root = self:findChild("root")
    self:commonHide(
        root,
        function()
            self:removeFromParent(true)
        end
    )
end
function Activity_Invitee:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_i" then
        --规则
        local view = util_createView("views.Invite.Activity.InviteeRules")
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    elseif name == "btn_close" then
        if self.m_timeScheduler then
            self:stopAction(self.m_timeScheduler)
            self.m_timeScheduler = nil
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_INVITEE_CLOSE)
        self:closeUI()
    elseif name == "btn_spin" then
        --spin
        local data = self.MangeMr:getAllCollect()
        if #data.prop > 0 then
            G_GetMgr(G_REF.Invite):sendInviteeRew("2",nil,data)
        end
    elseif name == "btn" then
        --shop
        self.MangeMr:buyGoods()
    end
end



return Activity_Invitee