local FlowerWaterItem = class("FlowerWaterItem", BaseView)
local ITEM_TYPE = {
    SLVER_ITEM = 1,
    GOLD_ITEM = 2
}

function FlowerWaterItem:initUI(param)
    self._type = param.type
    local path =  ""
    if not param.isPortrait then
        path = "Flower/Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_vertical/MainUI_flower.csb"
        if self._type == ITEM_TYPE.SLVER_ITEM then
            path = "Flower/Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_vertical/MainUI_flower_2.csb"
        end
    else
        path = "Flower/Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_vertical/MainUI_vertical_flower.csb"
        if self._type == ITEM_TYPE.SLVER_ITEM then
            path = "Flower/Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_vertical/MainUI_vertical_flower_2.csb"
        end
    end
    self.index = param.index
    self:createCsbNode(path)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.m_data = G_GetMgr(G_REF.Flower):getData()
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    self:initView()
end

function FlowerWaterItem:initCsbNodes()
    local btn_now = self:findChild("btn_now")
    local sp_true = self:findChild("sp_duihao")
    local node_di = self:findChild("node_di")
    self.node_spot = self:findChild("node_spot")
    self.node_hua = self:findChild("node_hua")
    self.btn_flow = self:findChild("btn_flow")
    btn_now:setVisible(false)
    sp_true:setVisible(false)
    node_di:setVisible(false)
end

function FlowerWaterItem:initView()
    --self:runCsbAction("idle",true)
    local param = {}
    param.type = self._type
    param.index = self.index
    self.spot_anim = util_createView("views.FlowerCode_New.FlowerSpotAnim",param)
    self.node_spot:addChild(self.spot_anim)
    self.node_spot:setVisible(false)
    self:initSpine()
end

function FlowerWaterItem:initSpine()
    local path = self.config.SPINE_PATH.SILVER
    if self._type == 2 then
        path = self.config.SPINE_PATH.GOLD
    end
    self.m_spine = util_spineCreate("Flower/" ..path, true, true, 1)
    self.node_hua:addChild(self.m_spine)
    util_spinePlay(self.m_spine, "idle", true)
end

function FlowerWaterItem:setBtnTouch(_enble)
    self.btn_flow:setTouchEnabled(_enble)
end

function FlowerWaterItem:playEndAnima(isBig)
    local csb_name = "click"
    if isBig then
        csb_name = "click2"
        gLobalSoundManager:playSound("Flower/" ..self.config.SOUND.HAPPY1)
    else
        gLobalSoundManager:playSound("Flower/" ..self.config.SOUND.HAPPY)
    end
    util_spinePlay(self.m_spine, csb_name, false)
    util_spineEndCallFunc(
            self.m_spine,
            csb_name,
            function()
                util_spinePlay(self.m_spine, "end", false)
                print("util_spinePlay-----------------")
                util_spineEndCallFunc(
                    self.m_spine,
                    "end",
                    function()
                        print("util_spinePlay1111111-----------------")
                         gLobalNoticManager:postNotification(self.config.EVENT_NAME.ITEM_END)
                    end
                )
            end
    )
end

function FlowerWaterItem:registerListener()
end


function FlowerWaterItem:clickStartFunc(sender)
end

function FlowerWaterItem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_flow" then
        if not self.ManGer:getWaterHide() then
            return
        end
        self.ManGer:setWaterHide(false)
        gLobalSoundManager:playSound("Flower/" ..self.config.SOUND.CLICK)
        local item_data = {}
        local type_str = "silver"
        if self._type == ITEM_TYPE.SLVER_ITEM then
            item_data = self.m_data.silverResult
        else
            item_data = self.m_data.goldResult
            type_str = "gold"
        end
        if item_data and item_data.kettleNum and item_data.kettleNum == 0 then
            self.ManGer:sendPayInfo(type_str)
        else
            self.node_spot:setVisible(true)
            if self.spot_anim then
                self.spot_anim:setVisible(true)
                self.spot_anim:playAnima()
            else
                self.ManGer:setWaterHide(true)
            end
        end
       
    end
end

return FlowerWaterItem