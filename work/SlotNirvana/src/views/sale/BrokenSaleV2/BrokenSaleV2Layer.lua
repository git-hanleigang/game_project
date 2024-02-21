local BrokenSaleV2Layer = class("BrokenSaleV2Layer", BaseLayer)

function BrokenSaleV2Layer:ctor()
    BrokenSaleV2Layer.super.ctor(self)
    self:setPortraitCsbName("BrokenSaleV2/csd/BrokenSale_shu.csb")
    self:setLandscapeCsbName("BrokenSaleV2/csd/BrokenSale.csb")
    self:setPauseSlotsEnabled(true)
end

function BrokenSaleV2Layer:initDatas()
    self.m_saleData = G_GetMgr(G_REF.BrokenSaleV2):getRunningData()
    self.m_saleItemList = {}
end

function BrokenSaleV2Layer:onShowedCallFunc()
    self:runCsbAction("idle", true)
    gLobalSendDataManager:getLogFeature():sendOpenNewLevelLog("Open", {pn = "GoBrokeSale"})
end

--刷新UI
function BrokenSaleV2Layer:initCsbNodes()
    self.m_node_all = self:findChild("node_all")
end

function BrokenSaleV2Layer:initView()
    self:initSaleItems()
    self:initPackPurchase()
end

function BrokenSaleV2Layer:initSaleItems()
    for i = 1, 3 do
        local baseNode = self:findChild("node_coin" .. i)
        local _saleItem = self.m_saleData:getSaleItemByIndex(i)
        if _saleItem then
            local cellView =
                util_createView(
                "views.sale.BrokenSaleV2.BrokenSaleV2Cell",
                {
                    saleItem = _saleItem,
                    delegate = self
                }
            )
            baseNode:addChild(cellView)
            table.insert(self.m_saleItemList, cellView)
        end
    end
end

-- 打包购买节点
function BrokenSaleV2Layer:initPackPurchase()
    local packPurchase = util_createAnimation("BrokenSaleV2/csd/BrokenSale_getall.csb")
    packPurchase.clickFunc = function(target, sender)
        local name = sender:getName()
        if name == "btn_buy" then
            local params = self:getPackData()
            self.m_buyTipData = self.m_saleData:getBuyTipData()
            self.m_buyTipCoins = self.m_saleData:getCoins()
            G_GetMgr(G_REF.BrokenSaleV2):requestBuySale(params, handler(self, self.buySuccess), handler(self, self.buyFailed))
        end
    end
    packPurchase:setButtonLabelContent("btn_buy", "$" .. self.m_saleData:getPrice())
    packPurchase:setBtnBuckVisible(packPurchase:findChild("btn_buy"), BUY_TYPE.BROKENSALEV2)
    self.m_node_all:addChild(packPurchase)
end

function BrokenSaleV2Layer:getPackData()
    local params = {}
    params.getKey = function()
        return self.m_saleData:getKey()
    end
    params.getPrice = function()
        return self.m_saleData:getPrice()
    end
    params.getDiscount = function()
        return 0
    end
    params.getCoins = function()
        return 0
    end
    params.getIndex = function()
        return 0
    end
    return params
end

-- 打包购买成功
function BrokenSaleV2Layer:buySuccess()
    if not tolua.isnull(self) then
        self:closeLayer(
            function()
                local levelUpNum = gLobalSaleManager:getLevelUpNum()
                local buyType = BUY_TYPE.BROKENSALEV2
                local view = util_createView("GameModule.Shop.BuyTip")
                view:initBuyTip(buyType, self.m_buyTipData, self.m_buyTipCoins, levelUpNum)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BROKENSALE_BUY_SUCCESS)
            end
        )
    end
end

-- 打包购买失败
function BrokenSaleV2Layer:buyFailed(_errorInfo)
    -- if not tolua.isnull(self) then
    --     self:closeLayer()
    -- end
end

--刷新UI
function BrokenSaleV2Layer:refreshUI()
    for i, v in ipairs(self.m_saleItemList) do
        v:refreshUI(self.m_saleData:getSaleItemByIndex(i))
    end
end

function BrokenSaleV2Layer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeLayer()
    end
end

function BrokenSaleV2Layer:closeLayer(_cb)
    self:closeUI(
        function()
            G_GetMgr(G_REF.BrokenSaleV2):setCoolDownTime()
            if _cb then
                _cb()
            else
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        end
    )
end

function BrokenSaleV2Layer:onEnter()
    BrokenSaleV2Layer.super.onEnter(self)
end

return BrokenSaleV2Layer
