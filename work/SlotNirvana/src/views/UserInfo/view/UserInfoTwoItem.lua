local UserInfoTwoItem = class("UserInfoTwoItem", BaseLayer)

-- list配置
-- zOrder排序：从小到大、从上往下
local CELL_INFO = {
    FB = {key = "FB", zOrder = 1},
    Email = {key = "Email", zOrder = 2},
    Inviter = {key = "Inviter", zOrder = 3},
    Invitee = {key = "Invitee", zOrder = 4},
    BindPhone = {key = "BindPhone", zOrder = 5},
}
-- 第一个cell的Y
local FIRSTY = -89
-- cell的间距
local INTERVAL = 113

function UserInfoTwoItem:ctor()
    UserInfoTwoItem.super.ctor(self)
    self:setExtendData("UserInfoTwoItem")
    self:setLandscapeCsbName("Activity/csd/Information/Iformation_Zong/Iformation_zong2.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:setShowActionEnabled(false)
    self:setMaskEnabled(false)
end

function UserInfoTwoItem:initView()
    self.btn_fb = self:findChild("btn_fb")
    self.btn_fb:setSwallowTouches(false)
    self.btn_email = self:findChild("btn_email")
    self.btn_email:setSwallowTouches(false)
    local btn_inviter = self:findChild("btn_inviter")
    btn_inviter:setSwallowTouches(false)
    local btn_invitee = self:findChild("btn_invitee")
    btn_invitee:setSwallowTouches(false)
    self.txt_fb = self:findChild("txt_fb")
    self.txt_email = self:findChild("txt_email")
    self.txt_bindPhone = self:findChild("txt_bindPhone")
    self.node_record_show = self:findChild("img_bg")
    self.Node_jiedian = self:findChild("Node_jiedian")
    self.node_fb = self:findChild("node_facebook")
    self.node_email = self:findChild("node_email")
    self.node_inviter = self:findChild("node_inviter")
    self.node_invitee = self:findChild("node_invitee")
    self.node_bindPhone = self:findChild("node_bindPhone")
    self.inviter_red = self:findChild("inviter_red")
    self.invitee_red = self:findChild("invitee_red")
    self.bindPhone_red = self:findChild("bindPhone_red")

    self:updataFB()
    self:updataEmail()
    self:updataInvite()
    self:updataBindPhone()
    
    -- 排序放在所有update之后
    self:sortCells()
end

function UserInfoTwoItem:addCell(_key, _cell)
    if _key == nil then
        return
    end
    if not self.m_showCells then
        self.m_showCells = {}
    end
    -- 去重
    for i = 1, #self.m_showCells do
        local cell = self.m_showCells[i]
        if cell and cell.key and cell.key == _key then
            return
        end
    end
    table.insert(self.m_showCells, {key = _key, node = _cell, zOrder = CELL_INFO[_key].zOrder})
end

function UserInfoTwoItem:delCell(_key)
    if _key == nil then
        return
    end    
    if self.m_showCells and #self.m_showCells > 0 then
        for i = #self.m_showCells, 1, -1 do
            local cell = self.m_showCells[i]
            if cell.key == key then
                table.remove(self.m_showCells, i)
                break
            end
        end
    end
end

-- 每次update后都要调用一下排序
function UserInfoTwoItem:sortCells()
    if not (self.m_showCells and #self.m_showCells > 0) then
        return
    end
    if self.m_showCells and #self.m_showCells > 1 then
        table.sort(self.m_showCells, function(a, b)
            return a.zOrder < b.zOrder
        end)
    end
    for i = 1, #self.m_showCells do
        local cell = self.m_showCells[i]
        if cell and not tolua.isnull(cell.node) then
            cell.node:setPositionY(FIRSTY - INTERVAL*(i-1))
        end
    end
end

function UserInfoTwoItem:updataFB()
    if gLobalSendDataManager:getIsFbLogin() == true then
        --绑定状态
        self.btn_fb:setTouchEnabled(false)
        self.txt_fb:setString("")
        self.node_fb:setVisible(false)
        -- self.node_email:setPositionY(-89)
        -- self.node_inviter:setPositionY(-205)
        -- self.node_invitee:setPositionY(-322)
        self:delCell(CELL_INFO.FB.key)
    else
        self:addCell(CELL_INFO.FB.key, self.node_fb)
    end
end

function UserInfoTwoItem:updataBindPhone()
    local isBound = G_GetMgr(G_REF.BindPhone):isBound()
    if isBound == true then
        self.node_bindPhone:setVisible(false)
        self.bindPhone_red:setVisible(false)
        -- self.txt_bindPhone:setString("Modify Bind Phone")
        self:delCell(CELL_INFO.BindPhone.key)
    else
        self.node_bindPhone:setVisible(true)
        self.bindPhone_red:setVisible(true)
        -- self.txt_bindPhone:setString("Bind Phone for more rewards!")
        self:addCell(CELL_INFO.BindPhone.key, self.node_bindPhone)
    end
end

function UserInfoTwoItem:bindSuccessFunc()
    -- 绑定成功对话框
    G_GetMgr(G_REF.BindPhone):showBindSuccDialog(function()
        if not tolua.isnull(self) then
            self:collectReward()
        end
    end)
end

function UserInfoTwoItem:collectReward()
    G_GetMgr(G_REF.BindPhone):gainBindReward(function()
        -- 显示领奖弹窗
        G_GetMgr(G_REF.BindPhone):showBindRewardLayer(true)
    end)
end

function UserInfoTwoItem:updataInvite()
    self.node_inviter:setVisible(false)
    self.node_invitee:setVisible(false)
    self.inviter_red:setVisible(false)
    self.invitee_red:setVisible(false)
    self:delCell(CELL_INFO.Inviter.key)
    self:delCell(CELL_INFO.Invitee.key)
    if G_GetMgr(G_REF.Invite) and G_GetMgr(G_REF.Invite):getData() then
        local data = G_GetMgr(G_REF.Invite):getData()
        local t = G_GetMgr(G_REF.Invite):getInviteeVs()
        if data:getInviteeReward() ~= nil and t then
            local all_rew = G_GetMgr(G_REF.Invite):getAllCollect()
            if all_rew.coin_num ~= 0 or #all_rew.prop ~= 0 then
                self.invitee_red:setVisible(true)
            end
            self.node_invitee:setVisible(true)
            self:addCell(CELL_INFO.Invitee.key, self.node_invitee)
        end
        if globalData.userRunData.levelNum >= globalData.constantData.INVITE_LEVEL and data:getInviterReward() ~= nil and data:getInviterReward().inviteNum ~= nil then
            local p_data = data:getPersonReceive()
            local pay_data = data:getPayReceive()
            if p_data and #p_data > 0 then
                self.inviter_red:setVisible(true)
            end
            if pay_data and #pay_data > 0 then
                self.inviter_red:setVisible(true)
            end
            self.node_inviter:setVisible(true)
            self:addCell(CELL_INFO.Inviter.key, self.node_inviter)
        --     self.node_invitee:setPositionY(-429)
        -- else
        --     self.node_invitee:setPositionY(self.node_inviter:getPositionY())
        end
    end
end

function UserInfoTwoItem:updataEmail()
    local sMail = globalData.userRunData.mail
    if sMail ~= nil and string.len(sMail) ~= 0 then
        self.ManGer:setIsFristBindEmail(false)
        self.txt_email:setString("Link and update")
    else
        self.ManGer:setIsFristBindEmail(true)
    end
    self:addCell(CELL_INFO.Email.key, self.node_email)
end
function UserInfoTwoItem:checkFBLoginState(loginInfo)
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
            self:sortCells()
        elseif loginState == 0 then
            --失败
        else
        end
    else
        if loginInfo then
            self:updataFB()
            self:sortCells()
        end
    end
end
function UserInfoTwoItem:registerListener()
    --绑定邮箱
    gLobalNoticManager:addObserver(
        self,
        function()
            self:updataEmail()
            self:sortCells()
        end,
        self.config.ViewEventType.NOTIFY_USERINFO_MODIFY_SUCC
    )

     -- fb登陆成功回调
    gLobalNoticManager:addObserver(
        self,
        function(Target, loginInfo)
            self:checkFBLoginState(loginInfo)
        end,
        GlobalEvent.FB_LoginStatus,
        true
    )

    --展开缩放
    gLobalNoticManager:addObserver(
        self,
        function(Target, _type)
            self:runNode(_type)
        end,
        self.config.ViewEventType.MAIN_HASTIORY
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, _type)
            self:updataInvite()
            self:sortCells()
        end,
        ViewEventType.NOTIFY_ACTIVITY_INVITEE_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            self:updataInvite()
            self:sortCells()
        end,
        ViewEventType.NOTIFY_ACTIVITY_INVITE_MAIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:updataBindPhone()
            self:sortCells()
        end,
        "notify_succ_bindPhone"
    )
end

function UserInfoTwoItem:runNode(_type)
    if _type == 1 then
        local move = cc.MoveTo:create(0.2, cc.p(504,240))
        self.Node_jiedian:runAction(move)
    else
        local move = cc.MoveTo:create(0.2, cc.p(504,531))
        self.Node_jiedian:runAction(move)
    end
    
end

function UserInfoTwoItem:clickStartFunc(sender)
end

function UserInfoTwoItem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_fb" then
        --fb登录
        gLobalViewManager:addLoadingAnima(false, nil, 5)
        performWithDelay(
            self,
            function()
                self.ManGer:fbBtnTouchEvent()
            end,
            0.2
        )
    elseif name == "btn_email" then
        --绑定邮箱
        self.ManGer:showEmailLayer()
    elseif name == "btn_inviter" then
        local view = G_GetMgr(G_REF.Invite):showInviterLayer()
        if not view then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
    elseif name == "btn_invitee" then
        local view = G_GetMgr(G_REF.Invite):showInviteeLayer()
        if not view then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
    elseif name == "btn_bindPhone" then
        local view = G_GetMgr(G_REF.BindPhone):showMainLayer(function()
            if not tolua.isnull(self) then
                self:bindSuccessFunc()
            end
        end)
        if not view then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
    end
end

return UserInfoTwoItem