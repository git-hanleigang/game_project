local BrokenSaleSaleControl = class("BrokenSaleSaleControl", BaseGameControl)

function BrokenSaleSaleControl:ctor()
    BrokenSaleSaleControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BrokenSale)
end

--打开破产促销界面
function BrokenSaleSaleControl:showMainLayer()
    local viewPath = "views.sale.BrokenSaleLayer"
    local view = util_createView(viewPath)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

--展示收益界面
function BrokenSaleSaleControl:showBenifitsLayer(index)
    local view = util_createView(SHOP_CODE_PATH.ItemBenefitBoardLayer, G_GetActivityDataByRef(ACTIVITY_REF.BrokenSale), SHOP_VIEW_TYPE.COIN)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function BrokenSaleSaleControl:getConstConfig()
    local coldTime = globalData.constantData.BROKENSALE_COLDTIME
    local popupTimes = globalData.constantData.BROKENSALE_POPUPTIMES
    return coldTime,popupTimes
end

--是否在冷却CD中
function BrokenSaleSaleControl:isInColdCD()
    local coldTime,popupTimes = self:getConstConfig()
    local lastOpenTime = self:getLastOpenTime()
    local openTimes = self:getOpenTimes()
    
    if lastOpenTime == nil then
        return false
    else
        local curSec = math.floor(globalData.userRunData.p_serverTime)
        --上次打开的时间与这次小于冷却时间
        if curSec - lastOpenTime >= coldTime * 60 * 1000 then
            return false
        else
            return openTimes >= popupTimes
        end
    end
    return false
end


local kBrokenSaleClodCD = "kBrokenSaleClodCD"
function BrokenSaleSaleControl:signOpenTime()
    local coldTime,popupTimes = self:getConstConfig()
    
    local funcSign = function(sec)
        local curSec = sec or tostring(math.floor(globalData.userRunData.p_serverTime))
        gLobalDataManager:setStringByField(kBrokenSaleClodCD, curSec, true)
    end
    
    local lastOpenTime = self:getLastOpenTime()
    local openTimes = self:getOpenTimes()

    if lastOpenTime == nil then
        funcSign()
        self:setOpenTimes()
    else
        local curSec = math.floor(globalData.userRunData.p_serverTime)
        if curSec - lastOpenTime >= coldTime * 60 * 1000 then
            funcSign()
            self:setOpenTimes(0)
        else
            self:setOpenTimes()
        end
    end
end

function BrokenSaleSaleControl:getLastOpenTime()
    local data = gLobalDataManager:getStringByField(kBrokenSaleClodCD, "", true)
    return tonumber(data)
end


local kBrokenSaleOpenTimes = "kBrokenSaleOpenTimes"
function BrokenSaleSaleControl:setOpenTimes(times)
    local openTimes = times or self:getOpenTimes()
    gLobalDataManager:setStringByField(kBrokenSaleOpenTimes, tostring(openTimes + 1), true)
end

function BrokenSaleSaleControl:getOpenTimes()
    local data = gLobalDataManager:getStringByField(kBrokenSaleOpenTimes, 0, true)
    return tonumber(data) or 0
end

return BrokenSaleSaleControl