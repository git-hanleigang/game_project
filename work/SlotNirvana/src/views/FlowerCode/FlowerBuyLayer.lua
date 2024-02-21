--购买水壶
local FlowerBuyLayer = class("FlowerBuyLayer", BaseLayer)
local ITEM_TYPE = {
    SLVER_ITEM = 1,
    GOLD_ITEM = 2
}
function FlowerBuyLayer:ctor(_type)
    FlowerBuyLayer.super.ctor(self)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.m_data = G_GetMgr(G_REF.Flower):getData()
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    self:setExtendData("FlowerBuyLayer")
    local path = "Activity/csd/EasterSeason_Buy.csb"
    path_v = "Activity/csd/EasterSeason_Buy_vertical.csb"
    self.payInfo = {}
    self.index_list = {}
    if _type == ITEM_TYPE.SLVER_ITEM then
        self.payInfo = self.m_data:getSilverPayInfo()
        self.index_list = self.m_data:getSilverIndexList()
    elseif _type == ITEM_TYPE.GOLD_ITEM then
        self.payInfo = self.m_data:getGoldPayInfo()
        self.index_list = self.m_data:getGoldIndexList()
    end
    if #self.payInfo == 1 then
        path = "Activity/csd/EasterSeason_Buy_2.csb"
        path_v = "Activity/csd/EasterSeason_Buy_vertical_2.csb"
    end
    self:setLandscapeCsbName(path)
    self:setPortraitCsbName(path_v)
    self._type = _type
    self.ManGer:setGoodHide(true)
end

function FlowerBuyLayer:initCsbNodes()
    self.sp_pot1 = self:findChild("sp_pot1")
    self.sp_pot1g = self:findChild("sp_pot1g")
    self.rew_num1 = self:findChild("txt_shuzi1")
end

function FlowerBuyLayer:initView()
    self.sp_pot1:setVisible(self._type == ITEM_TYPE.SLVER_ITEM)
    self.sp_pot1g:setVisible(self._type == ITEM_TYPE.GOLD_ITEM)
    self.rew_num1:setString("X"..self.payInfo[1].num)
    self:setButtonLabelContent("btn_buy1", "$"..self.payInfo[1].price)
    self.type_str = "silver"
    if self._type == ITEM_TYPE.GOLD_ITEM then
        self.type_str = "gold"
    end
    if #self.payInfo == 2 then
        local sp_pot2 = self:findChild("sp_pot2")
        local sp_pot2g = self:findChild("sp_pot2g")
        sp_pot2:setVisible(self._type == ITEM_TYPE.SLVER_ITEM)
        sp_pot2g:setVisible(self._type == ITEM_TYPE.GOLD_ITEM)
        local rew_num2 = self:findChild("txt_shuzi2")
        rew_num2:setString("X"..self.payInfo[2].num)
        self:setButtonLabelContent("btn_buy2", "$"..self.payInfo[2].price)
    end

    self:updateBtnBuck()
end

function FlowerBuyLayer:updateBtnBuck()
    local buyType = BUY_TYPE.FLOWER
    self:setBtnBuckVisible(self:findChild("btn_buy1"), buyType)
    self:setBtnBuckVisible(self:findChild("btn_buy2"), buyType)
end

function FlowerBuyLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _num)
            self:closeUI()
        end,
        self.config.EVENT_NAME.NOTIFY_FLOWER_BUY_SUCCESS
    )
end


function FlowerBuyLayer:clickStartFunc(sender)
end

function FlowerBuyLayer:closeUI()
    FlowerBuyLayer.super.closeUI(self)
end

function FlowerBuyLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self.ManGer:setWaterHide(true)
        self:closeUI()
    elseif name == "btn_buy1" then
        if self.ManGer:getGoodHide() then
            self.ManGer:setGoodHide(false)
            self.ManGer:buyGoods(self.payInfo[1],self.type_str,"FlowerSale1",#self.index_list)
        end
    elseif name == "btn_buy2" then
        if self.ManGer:getGoodHide() then
            self.ManGer:setGoodHide(false)
            self.ManGer:buyGoods(self.payInfo[2],self.type_str,"FlowerSale2",#self.index_list)
        end
    elseif name == "btn_purce1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:getBetItem(self.payInfo[1])
    elseif name == "btn_purce2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:getBetItem(self.payInfo[2])
    end
end

function FlowerBuyLayer:getBetItem(_data)
    local sl_data = {nil,p_price = _data.price}
    local itemList = gLobalItemManager:checkAddLocalItemList(sl_data)
    if itemList and #itemList > 0 then
        local view = util_createView("views.baseDailyPassCode_New.DailyMissionPassDialog",itemList)
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    
end

return FlowerBuyLayer