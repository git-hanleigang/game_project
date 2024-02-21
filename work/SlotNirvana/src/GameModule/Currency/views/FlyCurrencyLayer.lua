--[[

    author:{author}
    time:2022-05-15 16:55:27
]]
local FlyCurrencyLayer = class("FlyCurrencyLayer", BaseLayer)

function FlyCurrencyLayer:initDatas()
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
end

function FlyCurrencyLayer:onExit()
    G_GetMgr(G_REF.Currency):onExitFlyLayer()
    -- gLobalNoticManager:postNotification(ViewEventType.RESET_COIN_LABEL)
    FlyCurrencyLayer.super.onExit(self)
end
-- function FlyCurrencyLayer:onEnter()
--     FlyCurrencyLayer.super.onEnter(self)
--     gLobalNoticManager:addObserver(
--         self,
--         function()
--             self:removeFromParent()
--         end,
--         "NotifyFlyCurrencyOver"
--     )
-- end

return FlyCurrencyLayer
