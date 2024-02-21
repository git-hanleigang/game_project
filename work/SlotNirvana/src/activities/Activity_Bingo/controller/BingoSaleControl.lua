--[[
    
    author: 徐袁
    time: 2021-08-14 12:53:02
]]
local BingoSaleControl = class("BingoSaleControl", BaseActivityControl)

function BingoSaleControl:ctor()
    BingoSaleControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BingoSale)
    self:addPreRef(ACTIVITY_REF.Bingo)
end

-- 促销主界面
function BingoSaleControl:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = util_createFindView("Activity/Promotion_Bingo", _params)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI )

    return uiView
end

function BingoSaleControl:showNotEnoughBallLayer()
    local pData = self:getRunningData()
    if not pData then
        return nil
    end

    local notBallUI = util_createFindView("Activity/BingoGame/BingoNotBallUI", self)
    gLobalViewManager:showUI(notBallUI, ViewZorder.ZORDER_UI )

    return notBallUI
end

return BingoSaleControl
