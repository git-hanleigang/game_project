--[[
    多档促销
]]

local MultiSpanControl = class("MultiSpanControl", BaseActivityControl)

function MultiSpanControl:ctor()
    MultiSpanControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MultiSale)
end

function MultiSpanControl:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

return MultiSpanControl
