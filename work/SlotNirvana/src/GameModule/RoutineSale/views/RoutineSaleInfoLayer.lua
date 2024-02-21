--[[
    新版常规促销
--]]

local RoutineSaleInfoLayer = class("RoutineSaleInfoLayer", BaseLayer)

function RoutineSaleInfoLayer:initDatas()
    self:setPortraitCsbName("Sale_New/csb/rule/SaleRule_shu.csb")
    self:setLandscapeCsbName("Sale_New/csb/rule/SaleRule.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("RoutineSaleInfoLayer")
end

function RoutineSaleInfoLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function RoutineSaleInfoLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function RoutineSaleInfoLayer:registerListener()
    RoutineSaleInfoLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(
        self,
        function()
            self:closeUI()
        end,
        ViewEventType.NOTIFY_ROUTINE_SALE_TIME_OUT
    )
end

return RoutineSaleInfoLayer