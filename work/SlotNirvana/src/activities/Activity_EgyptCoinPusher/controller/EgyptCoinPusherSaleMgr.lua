--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local EgyptCoinPusherSaleMgr = class("EgyptCoinPusherSaleMgr", BaseActivityControl)

function EgyptCoinPusherSaleMgr:ctor()
    EgyptCoinPusherSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EgyptCoinPusherSale)
    self:addPreRef(ACTIVITY_REF.EgyptCoinPusher)
end

function EgyptCoinPusherSaleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function EgyptCoinPusherSaleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function EgyptCoinPusherSaleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function EgyptCoinPusherSaleMgr:showMainLayer(_isNoCoins)
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = gLobalViewManager:getViewByExtendData("EgyptCoinPusherPromotion")
    if uiView then
        return uiView
    end

    if _isNoCoins then
        local Config = G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):getConfig()
        uiView =
            self:createPopLayer(
            {
                inEntry = true,
                name = Config.RES.EgyptCoinPusherSaleMgr_NoPusherBuyView,
                itemName = Config.RES.EgyptCoinPusherSaleMgr_NoPusherBuyView_Cell,
                packItemName = Config.RES.EgyptCoinPusherSaleMgr_NoPusherBuyView_PACK_Cell
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

        uiView:setExtendData("EgyptCoinPusherPromotion")

        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end

    return uiView
end

return EgyptCoinPusherSaleMgr
