local BrokenSaleV2Layer = class("BrokenSaleV2Layer", BaseLayer)

function BrokenSaleV2Layer:ctor()
    BrokenSaleV2Layer.super.ctor(self)
    self:setPortraitCsbName("BrokenSaleV2/csd/BrokenSale_buff_main_shu.csb")
    self:setLandscapeCsbName("BrokenSaleV2/csd/BrokenSale_buff_main.csb")
    self:setPauseSlotsEnabled(true)
end

function BrokenSaleV2Layer:initDatas(_buffData)
    if _buffData then
        self.m_buffData = _buffData
    else
        self.m_data = G_GetMgr(G_REF.BrokenSaleV2):getData()
        self.m_buffData = self.m_data:getActiveBuff()
    end
    self.m_coins = 0
end

function BrokenSaleV2Layer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

--刷新UI
function BrokenSaleV2Layer:initCsbNodes()
    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_spin_num = self:findChild("lb_number_1")
    self.m_multiple = self:findChild("lb_number_2")
    self.m_limit = self:findChild("lb_number_3")
end

function BrokenSaleV2Layer:initView()
    self:initInfo()
end

function BrokenSaleV2Layer:initInfo()
    if self.m_buffData then
        self.m_coins = self.m_buffData:getBuffCoins()
        self.m_lb_coin:setString(util_formatCoins(self.m_coins, 9))
        local uiList = {
            {node = self.m_sp_coin},
            {node = self.m_lb_coin, alignX = 3}
        }
        util_alignCenter(uiList)

        self.m_spin_num:setString("" .. self.m_buffData:getCount())
        self.m_multiple:setString(self.m_buffData:getMultiple() .. "%")
        self.m_limit:setString(util_formatCoins(self.m_buffData:getBuffCoinsLimit(), 6))
    end
end

function BrokenSaleV2Layer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function BrokenSaleV2Layer:onEnter()
    BrokenSaleV2Layer.super.onEnter(self)
    if self.m_buffData:isCanCollect() then
        G_GetMgr(G_REF.BrokenSaleV2):requestBuffCoinsReward(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_BROKENSALE_BUFF)
                self:flyCoins()
            end,
            function()
                self:closeUI()
            end
        )
    end
end

function BrokenSaleV2Layer:flyCoins()
    if self.m_coins > toLongNumber(0) then
        local flyList = {}
        local btnCollect = self.m_sp_coin
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        G_GetMgr(G_REF.Currency):playFlyCurrency(
            flyList,
            function()
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end
        )
    else
        self:closeUI()
    end
end

return BrokenSaleV2Layer
