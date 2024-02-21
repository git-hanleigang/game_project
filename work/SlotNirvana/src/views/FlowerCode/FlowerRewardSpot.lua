--购买水壶
local FlowerRewardSpot = class("FlowerRewardSpot", BaseLayer)
local ITEM_TYPE = {
    SLVER_ITEM = 1,
    GOLD_ITEM = 2
}
function FlowerRewardSpot:ctor(param)
    FlowerRewardSpot.super.ctor(self)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.m_data = G_GetMgr(G_REF.Flower):getData()
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    self:setExtendData("FlowerRewardSpot")
    local path = "Activity/csd/EasterSeason_Reward_1.csb"
    self:setLandscapeCsbName(path)
    self._type = param.type
    self.num = param.num
    self.cb = param.cb
end

function FlowerRewardSpot:initCsbNodes()
    self.sp_pot1 = self:findChild("sp_pot2")
    self.sp_pot1g = self:findChild("sp_pot")
    self.rew_num = self:findChild("txt_desc")
end

function FlowerRewardSpot:initView()
    self:runCsbAction("idle",true)
    self.sp_pot1:setVisible(self._type == ITEM_TYPE.SLVER_ITEM)
    self.sp_pot1g:setVisible(self._type == ITEM_TYPE.GOLD_ITEM)
    self.rew_num:setString("YOU GOT "..self.num.." WATERING CAN!")
end

function FlowerRewardSpot:registerListener()
end

function FlowerRewardSpot:onEnter()
    FlowerRewardSpot.super.onEnter(self)
end

function FlowerRewardSpot:clickStartFunc(sender)
end

function FlowerRewardSpot:onKeyBack()
    self:closeUI()
end

function FlowerRewardSpot:onClickMask()
    self:closeUI()
end

function FlowerRewardSpot:closeUI()
    if self.cb then
        self.cb()
    end
    FlowerRewardSpot.super.closeUI(self)
end

function FlowerRewardSpot:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self:closeUI()
    end
end

return FlowerRewardSpot