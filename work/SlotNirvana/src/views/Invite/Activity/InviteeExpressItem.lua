local InviteeExpressItem = class("InviteeExpressItem", BaseView)

function InviteeExpressItem:initUI()
    self:createCsbNode("Activity/Node_inviteerewards_express.csb")
    self.m_data = G_GetMgr(G_REF.Invite):getData()
end

function InviteeExpressItem:initCsbNodes()
    self.exsp_yform = self:findChild("sp_yform")
    self.exsp_locky = self:findChild("sp_yform1")
    self.exsp_tick = self:findChild("sp_tick")
    self.exsp_collect = self:findChild("sp_collect")
    self.exsp_lock = self:findChild("sp_lock")
    self.exsp_rewnode = self:findChild("Node_rewards") 
    self.btn_e = self:findChild("btn_e")
    self.btn_e:setSwallowTouches(false)
end

function InviteeExpressItem:updataView(_data,_cltype)
    local intee_data = self.m_data:getInviteeReward()
    self._data = _data
    self.btn_e:setTag(_data.value)
    local shopItemUI = gLobalItemManager:createRewardNode(_data, ITEM_SIZE_TYPE.BATTLE_PASS)
    shopItemUI:setPositionY(25)
    self.exsp_rewnode:addChild(shopItemUI)
    local level = globalData.userRunData.levelNum - self.m_data:getLevel()
    if level >= _data.value then
        --付费奖励
        if _data.collect then
            self.exsp_locky:setVisible(true)
            self.exsp_collect:setVisible(false)
            self.exsp_tick:setVisible(true)
            self.exsp_lock:setVisible(false)
            self.btn_e:setTouchEnabled(false)
        else
            self.exsp_locky:setVisible(false)
            self.exsp_tick:setVisible(false)
            if intee_data.pay then
                self.exsp_collect:setVisible(true)
                self.exsp_lock:setVisible(true)
                if _cltype ~= nil then
                    self:runCsbAction("unlock",false,function()
                        self.exsp_lock:setVisible(false)
                        self:runCsbAction("idle",true)
                    end)
                else
                    self:runCsbAction("idle",true)
                end
            else
                self.btn_e:setTouchEnabled(false)
                self.exsp_collect:setVisible(false)
                self.exsp_lock:setVisible(true)
                self:runCsbAction("idle_lock",true)
            end
        end
    else
        self.exsp_locky:setVisible(false)
        self.exsp_lock:setVisible(true)
        self.exsp_collect:setVisible(false)
        self.exsp_tick:setVisible(false)
        self.btn_e:setTouchEnabled(false)
        self:runCsbAction("idle_lock",true)
    end
end

function InviteeExpressItem:clickStartFunc(sender)
end

function InviteeExpressItem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_e" then
        --付费领奖
        G_GetMgr(G_REF.Invite):sendInviteeRew("1",sender:getTag(),self._data)
    end
end
return InviteeExpressItem