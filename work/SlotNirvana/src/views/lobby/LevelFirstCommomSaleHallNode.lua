--
-- 大厅展示图
--
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelFirstCommomSaleHallNode = class("LevelFirstCommomSaleHallNode", LevelFeature)

function LevelFirstCommomSaleHallNode:createCsb()
    self.m_saleData = G_GetMgr(G_REF.FirstCommonSale):getData()
    if self.m_saleData:getGroup() == 0 then
        self:initViewA()
    elseif self.m_saleData:getGroup() == 1 then 
        self:initViewB()
    end
end

-- A组
function LevelFirstCommomSaleHallNode:initViewA()
    local csbTheme = "Promotion/FirstCommonSale_normal"
    if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        csbTheme = "Promotion/FirstCommonSale_special"
    end
    self:createCsbNode(csbTheme .. "/Icons/FirstTimeSale_A_Hall.csb")
    self.m_discount = self:findChild("lb_desc")
    self:updateDisconut()
end

function LevelFirstCommomSaleHallNode:updateDisconut()
    local stringNumber = function(_str)
        _str = string.split(_str,".")
        local number = ""
        for i = 1 ,#_str do
            number = number.._str[i]
        end
        if number == nil then
            number = 0
        end
        return tonumber(number) 
    end
    local oldPrice = stringNumber(self.m_saleData.p_price)  + 1-- 本次首充价格
    local newPrice = stringNumber(self.m_saleData.p_dollars) + 1 -- 本次首充实际价值
    local disconut = tonumber(newPrice / oldPrice) * 100
    -- 转换成数字
    self.m_discount:setString(disconut .. "%")
    self:updateLabelSize({label = self.m_discount, sx = self.m_discount:getScaleX(), sy = self.m_discount:getScaleY()}, 210)
end

-- B组
function LevelFirstCommomSaleHallNode:initViewB()
    local csbTheme = "Promotion/FirstCommonSale_normal"
    if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        csbTheme = "Promotion/FirstCommonSale_special"
    end
    self:createCsbNode(csbTheme .. "/Icons/FirstTimeSale_B_Hall.csb")
    
    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin = self:findChild("lb_coin")
    self:updateCoin()

    if not globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        self.m_lbPriceOld = self:findChild("lb_origin_num")
        self.m_lbPriceNew = self:findChild("lb_desc")
        self:updateDisconut_price()
    end
end

function LevelFirstCommomSaleHallNode:updateCoin()
    self.m_lb_coin:setString(util_formatMoneyStr(self.m_saleData.p_coins))
    self:updateLabelSize({label = self.m_lb_coin, sx = self.m_lb_coin:getScaleX(), sy = self.m_lb_coin:getScaleY()}, 730)

    local uiList = {
        {node = self.m_sp_coin},
        {node = self.m_lb_coin, alignX = 3}
    }
    util_alignCenter(uiList)
    
    local bagType = self.m_saleData:getBagType()
    local title_1 = self:findChild("sp_logo2")
    local title_2 = self:findChild("sp_logo")
    title_1:setVisible(bagType == 1)
    title_2:setVisible(bagType == 2)

    if not globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        local nodeCoins = self:findChild("node_coin")
        local nodePrice = self:findChild("node_price")
        nodePrice:setVisible(bagType == 1)
        nodeCoins:setVisible(bagType == 2)
    end
end

function LevelFirstCommomSaleHallNode:updateDisconut_price()
    self.m_lbPriceOld:setString("$" .. self.m_saleData.p_dollars) -- 本次首充实际价值
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbPriceOld, 112, 1)
    self.m_lbPriceNew:setString("$" .. self.m_saleData.p_price) -- 本次首充价格
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbPriceNew, 210, 1)
end

--点击回调
function LevelFirstCommomSaleHallNode:clickFunc(sender)
    if self.m_isTouch then
        return
    end

    self.m_isTouch = true
    local name = sender:getName()
    self:clickLayer(name)
end

function LevelFirstCommomSaleHallNode:clickLayer(name)
    local view = G_GetMgr(G_REF.FirstCommonSale):showMainLayer({pos = "SlideClick"})
    self.m_isTouch = false

    -- 按钮名字  类型是url
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view,"FirstCommonSale",DotUrlType.UrlName,true,DotEntrySite.UpView,DotEntryType.Lobby)
    end
end

function LevelFirstCommomSaleHallNode:onEnter()
    LevelFirstCommomSaleHallNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function()
            if self.m_discount then 
                self:updateDisconut()
            elseif self.m_lb_coin then 
                self:updateCoin()
            end
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )

    self:runCsbAction("idle", true, nil, 60)
end

return LevelFirstCommomSaleHallNode
