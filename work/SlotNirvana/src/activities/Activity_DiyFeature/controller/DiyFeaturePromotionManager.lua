local DiyFeaturePromotionManager = class("DiyFeaturePromotionManager", BaseActivityControl)
local DiyFeaturePromotionNet = require("activities.Activity_DiyFeature.net.DiyFeaturePromotionNet")

function DiyFeaturePromotionManager:ctor()
    DiyFeaturePromotionManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiyFeatureOverSale)
    self.m_netModel = DiyFeaturePromotionNet:getInstance()
end

-- data {type = "NORMAL"} 标准版 or {type = "HIGH"} 豪华版
function DiyFeaturePromotionManager:requestBuyDiyFeature(data,failCall)
    if self.m_isRequestBuyDiyFeature then
        return
    end 
    self.m_isRequestBuyDiyFeature = true
    local successFunc = function()
        gLobalViewManager:checkBuyTipList(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DIYFEATURE_BUYOVERSALE_SUCCESS, {isSuc = true, data = data})
        end)
    end

    local failedCallFun = function()
        if failCall then
            failCall()
        end
        self.m_isRequestBuyDiyFeature = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DIYFEATURE_BUYOVERSALE_SUCCESS, false)
    end
    self.m_netModel:requestBuyDiyFeature(data, successFunc, failedCallFun)
end
function DiyFeaturePromotionManager:isRequestBuyDiyFeatureMark()
    return self.m_isRequestBuyDiyFeature
end

function DiyFeaturePromotionManager:clearRequestBuyDiyFeatureMark()
    self.m_isRequestBuyDiyFeature = false
end

function DiyFeaturePromotionManager:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("Promotion_DiyFeature") then
        return nil
    end
    local view = util_createView("Promotion_DiyFeature.Promotion_DiyFeature")  
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function DiyFeaturePromotionManager:isCanShowLayer()
    local key = self:getSaveLocalKey()
    local isConfirmClose = gLobalDataManager:getBoolByField(key, false) -- 确认关闭
    if isConfirmClose then
        return false
    end
    return DiyFeaturePromotionManager.super.isCanShowLayer(self)
end

function DiyFeaturePromotionManager:setLocalConfirmClose()
    local key = self:getSaveLocalKey()
    gLobalDataManager:setBoolByField(key, true)
end

function DiyFeaturePromotionManager:getSaveLocalKey()
    local data = self:getRunningData()
    if data then
        return "isConfirmCloseDiyFeatureOverSale" .. data:getExpireAt()
    end
    return "isConfirmCloseDiyFeatureOverSale"
end

function DiyFeaturePromotionManager:showCloseConfirmLayer(_params)
    if gLobalViewManager:getViewByExtendData("DiyFeaturePromotionConfirmLayer") then
        return nil
    end
    local view = util_createView("Promotion_DiyFeature.DiyFeaturePromotionConfirmLayer", _params)  
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function DiyFeaturePromotionManager:isReconnectDiyFeature()
    local data = self:getData()
    if data then
        local featureData = data:getDiyFeatureData()
        if featureData and featureData:getIsActivateGame() then
            local levelId = featureData:getInGameLevelId()
            gLobalViewManager:lobbyGotoGameScene(levelId)
            return true
        end
    end
    return false
end

return DiyFeaturePromotionManager
