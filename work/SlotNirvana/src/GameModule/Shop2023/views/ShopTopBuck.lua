--[[
]]
local ShopTopBuck = class("ShopTopBuck", BaseView)

function ShopTopBuck:initDatas(_isPortrait)
    self.m_isPortrait = _isPortrait
end

function ShopTopBuck:getCsbName()
    if self.m_isPortrait then
        return SHOP_RES_PATH.BuckNodeV
    end
    return SHOP_RES_PATH.BuckNodeH
end

function ShopTopBuck:initCsbNodes()
    self.m_lbBuck = self:findChild("txt_buck")
end

function ShopTopBuck:initUI()
    ShopTopBuck.super.initUI(self)
    self:initBucks()
end

function ShopTopBuck:initBucks()
    local bucks = G_GetMgr(G_REF.ShopBuck):getBuckNum()
    self:updateBuckLabel(bucks)    
end

function ShopTopBuck:updateBuckLabel(_bucks)
    if _bucks == nil then   
        _bucks = G_GetMgr(G_REF.ShopBuck):getBuckNum()
    end
    if self.m_bucks ~= _bucks then
        self.m_bucks = _bucks
        self.m_lbBuck:setString(util_cutCoins(self.m_bucks, true, 2))
        self:updateLabelSize({label = self.m_lbBuck, sx = 1, sy = 1}, 110)
    end
end

function ShopTopBuck:onEnter()
    ShopTopBuck.super.onEnter(self)
    -- 购买代币
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateBuckLabel()
        end,
        ViewEventType.NOTIFY_PURCHASE_BUCK_SUCCESS
    )    
    -- 花费代币
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.isConsumeBuck then
                self:updateBuckLabel()
            end
        end,
        ViewEventType.NOTIFY_PURCHASE_SUCCESS
    )
end

function ShopTopBuck:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buck" or name == "btn_touch" then
        G_GetMgr(G_REF.ShopBuck):showMainLayer()
    end
end

return ShopTopBuck