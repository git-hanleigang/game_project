local FrameDisyCell = class("FrameDisyCell", BaseView)

function FrameDisyCell:initUI()
    self:createCsbNode("Activity/csd/Information_FramePartII/FramePartII_display/FramePartII_ShowFrame.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:initView()
end

function FrameDisyCell:initView()
    self.sp_choicebox = self:findChild("sp_choicebox")
    self.lb_num = self:findChild("lb_desc")
    local btn_cell = self:findChild("btn_cell")
    self.line = self:findChild("line")
    self.txt_game = self:findChild("txt_game")
    self.head_node = self:findChild("node_reward")
    btn_cell:setSwallowTouches(false)
end

function FrameDisyCell:updataCell(_data,idx,index)
    self.data = _data
    self.lb_num:setVisible(false)
    self.sp_choicebox:setVisible(false)
    if index == 1 then
        if idx == 0 then
            self.txt_game:setVisible(true)
            if self.ManGer:getGameHoldFrameItem() ~= 0 then
                self.txt_game:setString("EVENT FRAME")
            else
                self.txt_game:setString("GAME FRAME")
            end
        elseif idx == self.ManGer:getGameHoldFrameItem() then
            self.txt_game:setVisible(true)
            self.txt_game:setString("GAME FRAME")
            if self.ManGer:getGameHoldFrameItem() ~= 0 then
                self.line:setVisible(true)
            end
        end
    end
    local shop1 = self.head_node:getChildByName("head_disyCell")
    if shop1 ~= nil and not tolua.isnull(shop1) then
        self.head_node:removeAllChildren()
    end
    local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(_data.id)
    if head_sprite then
        head_sprite:setScale(0.3)
        head_sprite:setPosition(0,0)
        self.head_node:addChild(head_sprite)
        head_sprite:setName("head_disyCell")
    end
    self.lb_num:setVisible(false)
    local frame_data = self.ManGer:getDisyItem()
    if frame_data and #frame_data > 0 then
        local _index = 0
        for i,v in ipairs(frame_data) do
            if self.data.id == tonumber(v) then
                _index = i
            end
        end
        if _index ~= 0 then
            self.lb_num:setString(_index)
            self.lb_num:setVisible(true)
            self.sp_choicebox:setVisible(true)
        end
    end
end

function FrameDisyCell:clickCell()
    local num,index = self.ManGer:setDisyItem(self.data.id)
    if index ~= 0 then
        self.lb_num:setVisible(false)
        self.sp_choicebox:setVisible(false)
    elseif num ~= 0 then
        self.sp_choicebox:setVisible(true)
        self.lb_num:setString(num)
        self.lb_num:setVisible(true)
    end
    gLobalNoticManager:postNotification(self.config.ViewEventType.FRAME_AVMENT_ANILEVEL)
end

function FrameDisyCell:clickStartFunc(sender)
end

function FrameDisyCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_cell" then
       self:clickCell()
    end
end

return FrameDisyCell