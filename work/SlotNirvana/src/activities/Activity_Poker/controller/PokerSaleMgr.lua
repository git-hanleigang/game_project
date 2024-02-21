--[[
    扑克促销 管理器
]]
local PokerSaleMgr = class("PokerSaleMgr", BaseActivityControl)

function PokerSaleMgr:ctor()
    PokerSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PokerSale)
    self:addPreRef(ACTIVITY_REF.Poker)
end

function PokerSaleMgr:showMainLayer(params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("Promotion_Poker") ~= nil then
        return nil
    end
    local isShowGoto = false
    if params then
        if params == "PokerMainGameButton" then
            isShowGoto = true
        end
    end
    local uiView = util_createView("Activity.Promotion_Poker", {inEntry = isShowGoto})
    uiView:setName("Promotion_Poker")
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

return PokerSaleMgr
