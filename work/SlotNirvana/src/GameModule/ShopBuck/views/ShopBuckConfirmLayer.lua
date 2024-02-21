--[[
]]
local ShopBuckConfirmLayer = class("ShopBuckConfirmLayer", BaseLayer)

function ShopBuckConfirmLayer:initDatas(_price, _buckNum, _clickYes, _clickNo, _clickCancel)

    self.m_price = _price or "0" -- 价格
    self.m_buckNum = _buckNum or "0" -- 代币
    self.m_clickYes = _clickYes
    self.m_clickNo = _clickNo
    self.m_clickCancel = _clickCancel

    self:setLandscapeCsbName("ShopBuck/csb/ShopBuckConfirmLayer.csb")
    -- self:setPortraitCsbName("")
end

function ShopBuckConfirmLayer:initCsbNodes()
    self.m_nodeBuck = self:findChild("node_buck")
    self.m_lbCost = self:findChild("lb_number")
    self:setButtonLabelContent("btn_yes", "YES")
    self:setButtonLabelContent("btn_no", "NO")
end

function ShopBuckConfirmLayer:initView()
    self:initBuck()
    self:initCost()
    self:initLog()
end

function ShopBuckConfirmLayer:initLog()
    -- 这里不单独新增打点信息，使用上一个付费界面的打点信息
    local goodsInfo = gLobalSendDataManager:getLogIap():getGoodsInfo() or {}
    if goodsInfo.goodsTheme == nil then
        goodsInfo.goodsTheme = "ShopBuckConfirmLayer"
    end
    local purchaseInfo = gLobalSendDataManager:getLogIap():getPurchaseInfo() or {}
    local paySessionId = gLobalSendDataManager:getLogIap():getPaySessionId()
    gLobalSendDataManager:getLogIap():setPurchaseBuckInfo({tokenStatus = "ytoken"})
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, LOG_ENUM_TYPE.PaymentAction_buckConfirm_pop, paySessionId, self)
end

function ShopBuckConfirmLayer:initBuck()
    local view = G_GetMgr(G_REF.ShopBuck):createBuckTopNode()
    if view then
        self.m_nodeBuck:addChild(view)
    end
end

function ShopBuckConfirmLayer:initCost()
    self.m_lbCost:setString(self.m_buckNum)
end

-- function ShopBuckConfirmLayer:playShowAction()
--     ShopBuckConfirmLayer.super.playShowAction(self)
-- end

function ShopBuckConfirmLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function ShopBuckConfirmLayer:onEnter()
    ShopBuckConfirmLayer.super.onEnter(self)
end

function ShopBuckConfirmLayer:clickFunc(sender)
    if self.m_closed then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        self.m_closed = true
        self:closeUI(self.m_clickCancel)
    elseif name == "btn_info" then
        G_GetMgr(G_REF.ShopBuck):showConfirmInfoLayer()
    elseif name == "btn_yes" then
        self.m_closed = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI(self.m_clickYes)
    elseif name == "btn_no" then
        self.m_closed = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI(self.m_clickNo)
    end
end

return ShopBuckConfirmLayer