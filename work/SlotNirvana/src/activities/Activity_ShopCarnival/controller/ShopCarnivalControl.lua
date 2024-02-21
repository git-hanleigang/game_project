--[[
    Echo Win
]]
local ShopCarnivalControl = class("ShopCarnivalControl", BaseActivityControl)

function ShopCarnivalControl:ctor()
    ShopCarnivalControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ShopCarnival)
end

function ShopCarnivalControl:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local viewLayer = util_createView("shopCarnival.Activity_ShopCarnival")
    if viewLayer then
        viewLayer:setName("Activity_ShopCarnival")
        gLobalViewManager:showUI(viewLayer, ViewZorder.ZORDER_POPUI)
    end
    return viewLayer
end

function ShopCarnivalControl:getMainLayer()
    return gLobalViewManager:getViewByName("Activity_ShopCarnival")
end

function ShopCarnivalControl:playStartAction(_over)
    local layer = self:getMainLayer()
    if layer then
        layer:playStartAction(_over)
    end
end

return ShopCarnivalControl
