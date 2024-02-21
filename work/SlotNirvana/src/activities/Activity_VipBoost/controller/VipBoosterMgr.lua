--[[
]]
local VipBoosterMgr = class("VipBoosterMgr", BaseActivityControl)

function VipBoosterMgr:ctor()
    VipBoosterMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.VipBoost)
end

function VipBoosterMgr:showShopVip()
    if not self:checkIsCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("VipBoostLayerUI") then
        return false
    end
    local shopVipLayer = util_createView("Activity.VipBoostLayerUI")
    if shopVipLayer then
        local data = self:getRunningData()
        local time = data:getExpireAt()
        gLobalDataManager:setNumberByField("selfTimeVipBoost", time)
        shopVipLayer:setName("VipBoostLayerUI")
        self:showLayer(shopVipLayer, ViewZorder.ZORDER_POPUI)
    end
    return shopVipLayer
end

function VipBoosterMgr:getLogoLayer()
    return gLobalViewManager:getViewByName("VipBoostLayerUI")
end

function VipBoosterMgr:playStartAction(_over)
    local layer = self:getLogoLayer()
    if layer then
        layer:playStartAction(_over)
    end
end

function VipBoosterMgr:checkIsCanShowLayer()
    --资源是否下载
    if not self:isCanShowLayer() then
        return false
    end
    local selfTime = gLobalDataManager:getNumberByField("selfTimeVipBoost", 0)
    local data = self:getRunningData()
    local time = data:getExpireAt()
    if time > selfTime then
        return true
    end
    return false
end

return VipBoosterMgr
