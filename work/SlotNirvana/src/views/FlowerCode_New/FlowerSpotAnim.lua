local FlowerSpotAnim = class("FlowerSpotAnim", BaseView)
local ITEM_TYPE = {
    SLVER_ITEM = 1,
    GOLD_ITEM = 2
}

function FlowerSpotAnim:initUI(param)
    self._type = param.type
    self.index = param.index
    local path = "Flower/Activity/csd/EasterSeason_Operation/node_pot.csb"
    self:createCsbNode(path)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    self:initView()
end

function FlowerSpotAnim:initCsbNodes()
end

function FlowerSpotAnim:initView()
    local sp1 = self:findChild("sp_pot_1")
    local sp2 = self:findChild("sp_pot_2")
    sp1:setVisible(self._type == ITEM_TYPE.SLVER_ITEM)
    sp2:setVisible(self._type == ITEM_TYPE.GOLD_ITEM)
end

function FlowerSpotAnim:playAnima()
    gLobalSoundManager:playSound("Flower/" ..self.config.SOUND.WATER)
    self:runCsbAction(
        "click",
        false,
        function()
            gLobalNoticManager:postNotification(self.config.EVENT_NAME.ITEM_CLICK_SPOT,self.index)
            self:runCsbAction("end",false,function()
                local type_str = "silver"
                if self._type == ITEM_TYPE.GOLD_ITEM then
                    type_str = "gold"
                end
                self.ManGer:sendWater(type_str,self.index)
                self:setVisible(false)
            end)
        end
    )
end

return FlowerSpotAnim