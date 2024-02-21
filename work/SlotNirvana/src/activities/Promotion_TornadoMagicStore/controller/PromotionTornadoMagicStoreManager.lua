local PromotionTornadoMagicStoreManager = class("PromotionTornadoMagicStoreManager", BaseActivityControl)
local DuckShotNet = require("activities.Promotion_TornadoMagicStore.net.PromotionTornadoMagicStoreDataNet")

function PromotionTornadoMagicStoreManager:ctor()
    PromotionTornadoMagicStoreManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TornadoMagicStore)

    self._net = DuckShotNet:getInstance()
end

function PromotionTornadoMagicStoreManager:getNet()
    return self._net
end

function PromotionTornadoMagicStoreManager:sendGetRewards(...)
    self._net:sendGetRewards(...)
end

local kPromotionTornadoMagicStoreManagerLastBuyType = "MagicStoreManagerLastBuyType"
function PromotionTornadoMagicStoreManager:setLastBuyType(index)
    local dataStr = index == 1 and "LEFT" or "RIGHT"
    gLobalDataManager:setStringByField(kPromotionTornadoMagicStoreManagerLastBuyType,dataStr,true)
end

function PromotionTornadoMagicStoreManager:getLastBuyType()
    local default = "LEFT"
    local res = gLobalDataManager:getStringByField(kPromotionTornadoMagicStoreManagerLastBuyType,default,true)
    return res
end

function PromotionTornadoMagicStoreManager:setBuyStatus(status)
    self._buyStatus = status
end

function PromotionTornadoMagicStoreManager:getBuyStatus()
    return self._buyStatus
end

function PromotionTornadoMagicStoreManager:getHallPath(hallName)
    return "" .. hallName .. "/" .. hallName ..  "HallNode"
end

function PromotionTornadoMagicStoreManager:getSlidePath(slideName)
    return "" .. slideName .. "/" .. slideName ..  "SlideNode"
end

function PromotionTornadoMagicStoreManager:getPopPath(popName)
    return "" .. popName .. "/" .. popName
end

return PromotionTornadoMagicStoreManager