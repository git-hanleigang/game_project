--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local CoinPusherSaleMgr = class("CoinPusherSaleMgr", BaseActivityControl)

function CoinPusherSaleMgr:ctor()
    CoinPusherSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinPusherSale)
    self:addPreRef(ACTIVITY_REF.CoinPusher)
end

function CoinPusherSaleMgr:showMainLayer(_isNoCoins)
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = gLobalViewManager:getViewByExtendData("CoinPusherPromotion")
    if uiView then
        return uiView
    end

    if _isNoCoins then
        local Config = G_GetMgr(ACTIVITY_REF.CoinPusher):getConfig()
        uiView =
            self:createPopLayer(
            {
                inEntry = true,
                name = Config.RES.CoinPusherSaleMgr_NoPusherBuyView,
                itemName = Config.RES.CoinPusherSaleMgr_NoPusherBuyView_Cell
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

        uiView:setExtendData("CoinPusherPromotion")

        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end

    return uiView
end

function CoinPusherSaleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function CoinPusherSaleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function CoinPusherSaleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return CoinPusherSaleMgr
