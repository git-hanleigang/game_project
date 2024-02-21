--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local NewCoinPusherSaleMgr = class("NewCoinPusherSaleMgr", BaseActivityControl)

function NewCoinPusherSaleMgr:ctor()
    NewCoinPusherSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewCoinPusherSale)
    self:addPreRef(ACTIVITY_REF.NewCoinPusher)
end

function NewCoinPusherSaleMgr:showMainLayer(_isNoCoins)
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = gLobalViewManager:getViewByExtendData("NewCoinPusherPromotion")
    if uiView then
        return uiView
    end

    if _isNoCoins then
        local Config = G_GetMgr(ACTIVITY_REF.NewCoinPusher):getConfig()
        uiView =
            self:createPopLayer(
            {
                inEntry = true,
                name = Config.RES.NewCoinPusherSaleMgr_NoPusherBuyView,
                itemName = Config.RES.NewCoinPusherSaleMgr_NoPusherBuyView_Cell
            }
        )
    else
        uiView = self:createPopLayer()
    end

    if uiView then
        local themeName = self:getThemeName()
        if gLobalSendDataManager.getLogIap and gLobalSendDataManager:getLogIap().setEnterOpen then
            gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", themeName)
        end

        uiView:setExtendData("NewCoinPusherPromotion")

        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end

    return uiView
end

return NewCoinPusherSaleMgr
