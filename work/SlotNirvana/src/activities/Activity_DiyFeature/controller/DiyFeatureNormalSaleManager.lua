--[[--
    diy 跟功能一起开的促销
]]
local DiyFeatureNormalSaleManager = class("DiyFeatureNormalSaleManager", BaseActivityControl)

function DiyFeatureNormalSaleManager:ctor()
    DiyFeatureNormalSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiyFeatureNormalSale)
end

function DiyFeatureNormalSaleManager:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("Promotion_DiyFeatureNormal") then
        return nil
    end
    local view = util_createView("Promotion_DiyFeatureNormal.Promotion_DiyFeatureNormal")  
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function DiyFeatureNormalSaleManager:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function DiyFeatureNormalSaleManager:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function DiyFeatureNormalSaleManager:getPopPath(popName)
    return popName .. "/" .. popName
end

return DiyFeatureNormalSaleManager
