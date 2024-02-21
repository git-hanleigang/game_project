local UserInfoAvterCell = class("UserInfoFrame", BaseView)

function UserInfoAvterCell:initUI()
    self:createCsbNode("Activity/csd/Information_Frame/Information_frame2.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:initView()
end

function UserInfoAvterCell:initView()
    self.sp_frame_bottom = self:findChild("sp_bg")
    self.sp_choicebox = self:findChild("sp_choicebox")
    self.sp_true = self:findChild("sp_true")
    self.head_node = self:findChild("node_reward")
    self.sp_desc = self:findChild("sp_desc_new")
    self.line = self:findChild("line")
    self.txt_game = self:findChild("txt_game")
    local btn_cell = self:findChild("btn_cell")
    btn_cell:setSwallowTouches(false)
end

function UserInfoAvterCell:updataCell(_data,idx,index)
    self.line:setVisible(false)
    self.txt_game:setVisible(false)
    if self.ManGer:getGameFrameItem() ~= 0 then
        if index == 1 then
            if idx == 0 then
                self.txt_game:setString("EVENT FRAME")
                self.txt_game:setVisible(true)
            elseif idx == self.ManGer:getGameFrameItem() then
                self.txt_game:setString("GAME FRAME")
                self.txt_game:setVisible(true)
                self.line:setVisible(true)
            end
        end
    end
    self.data = _data
    local shop1 = self.head_node:getChildByName("head_avterCell")
    if shop1 ~= nil and not tolua.isnull(shop1) then
        self.head_node:removeAllChildren()
    end
    local userResHeadIdx = 0
    if globalData.userRunData.avatarFrameId ~= nil and globalData.userRunData.avatarFrameId ~= "" then
        userResHeadIdx = tonumber(globalData.userRunData.avatarFrameId)
    end
    local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(_data.id)
    if head_sprite then
        head_sprite:setScale(0.3)
        head_sprite:setPosition(0,0)
        self.head_node:addChild(head_sprite)
        head_sprite:setName("head_avterCell")
    end
    local status = self.ManGer:getStatus(_data.id)
    if status == 0 then
        --未获得
        self.sp_choicebox:setVisible(false)
        self.sp_true:setVisible(false)
        self.sp_desc:setVisible(false)
        self:runCsbAction("dark")
    else
        self:runCsbAction("idle")
        if _data.id == userResHeadIdx then
            self.sp_true:setVisible(true)
        else
            self.sp_true:setVisible(false)
        end
        local status = self.ManGer:getIsNew(_data.id)
        if status == 0 then
            self.sp_desc:setVisible(true)
        else
            self.sp_desc:setVisible(false)
        end
    end
    self.m_status = status
    if _data.id == self.ManGer:getChooseAvr() then
        self.sp_choicebox:setVisible(true)
    else
        self.sp_choicebox:setVisible(false)
    end
    util_setCascadeColorEnabledRescursion(self.head_node, true)
    self:registerListener()
end

function UserInfoAvterCell:clickCell()
    local status = self.ManGer:getIsNew(self.data.id)
    if status == 0 then
        self.ManGer:setIsNew(self.data.id)
    end
    self.sp_desc:setVisible(false)
    self.ManGer:setChooseAvr(self.data.id)
    gLobalNoticManager:postNotification(self.config.ViewEventType.AVR_ITEM_CLICK,self.data)
end

function UserInfoAvterCell:clickStartFunc(sender)
end

function UserInfoAvterCell:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self.sp_choicebox:setVisible(self.data.id == self.ManGer:getChooseAvr())
    end,self.config.ViewEventType.AVR_ITEM_CLICK)
    gLobalNoticManager:addObserver(self,function(self, itemData)
        local avrId = globalData.userRunData.avatarFrameId
        if avrId ~= nil and avrId == self.data.id then
            self.sp_true:setVisible(true)
        else
            self.sp_true:setVisible(false)
        end
    end,self.config.ViewEventType.NOTIFY_USERINFO_MODIFY_SUCC)
    --头像卡到期卸下自己的头像框
    gLobalNoticManager:addObserver(self, function()
        -- if self.sp_true:isVisible() then
        --     self.sp_true:setVisible(false)
        -- end
        if self.data.frameType == "item" and self.m_status == 1 then
            self.m_status = self.ManGer:getStatus(self.data.id)
            if self.m_status == 0 then
                --未获得
                self.sp_choicebox:setVisible(false)
                self.sp_true:setVisible(false)
                self.sp_desc:setVisible(false)
                self:runCsbAction("dark")
            end
        end
    end, ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI)
end

function UserInfoAvterCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_cell" then
       self:clickCell()
    end
end

return UserInfoAvterCell