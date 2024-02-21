local InviteeGeneralItem = class("InviteeGeneralItem", BaseView)

function InviteeGeneralItem:initUI()
    self:createCsbNode("Activity/Node_inviteerewards_general.csb")
    self.m_data = G_GetMgr(G_REF.Invite):getData()
end

function InviteeGeneralItem:initCsbNodes()
    self.glsp_yform = self:findChild("sp_bform")
    self.glsp_locky = self:findChild("sp_bform1")
    self.glsp_tick = self:findChild("sp_tick")
    self.glsp_collect = self:findChild("sp_collect")
    self.glsp_lock = self:findChild("sp_lock")
    self.glsp_rewnode = self:findChild("Node_rewards")
    self.btn_g = self:findChild("btn_g")
    self.btn_g:setSwallowTouches(false)
end

function InviteeGeneralItem:updataView(_data)
    local intee_data = self.m_data:getInviteeReward()
    self._data = _data
    self.btn_g:setTag(_data.value)
    local shopItemUI = gLobalItemManager:createRewardNode(_data, ITEM_SIZE_TYPE.BATTLE_PASS)
    shopItemUI:setPositionY(25)
    self.glsp_rewnode:addChild(shopItemUI)
    local level = globalData.userRunData.levelNum - self.m_data:getLevel()
    if level >= _data.value then
        --设置普通奖励
        self.glsp_lock:setVisible(false)
        if _data.collect then
            --领取了已经
            self.glsp_locky:setVisible(true)
            self.glsp_collect:setVisible(false)
            self.glsp_tick:setVisible(true)
            self.btn_g:setTouchEnabled(false)
        else
            self.glsp_locky:setVisible(false)
            self.glsp_collect:setVisible(true)
            self.glsp_tick:setVisible(false)
            self:runCsbAction("idle",true)
        end
    else
        self.glsp_locky:setVisible(false)
        self.glsp_lock:setVisible(true)
        self.glsp_collect:setVisible(false)
        self.glsp_tick:setVisible(false)
        self.btn_g:setTouchEnabled(false)
        self:runCsbAction("idle_lock",true)
    end
end

function InviteeGeneralItem:clickStartFunc(sender)
end

function InviteeGeneralItem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_g" then
        --领奖
        G_GetMgr(G_REF.Invite):sendInviteeRew("0",sender:getTag(),self._data)
    end
end
return InviteeGeneralItem