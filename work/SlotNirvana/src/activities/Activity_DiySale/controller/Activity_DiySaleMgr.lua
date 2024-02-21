--diy促销
require("activities.Activity_DiySale.config.DiySaleConfig")
local Activity_DiySaleMgr = class("Activity_DiySaleMgr", BaseActivityControl)
local Activity_DiySaleNet = require("activities.Activity_DiySale.net.Activity_DiySaleNet")

function Activity_DiySaleMgr:ctor()
    Activity_DiySaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiySale)
    self.m_netModel = Activity_DiySaleNet:getInstance()
end

function Activity_DiySaleMgr:parseData(_data)
    local data = self:getData()
    if data and _data then
        data:parseData(_data)
    end
end

function Activity_DiySaleMgr:showBuffTips(_callback)
    if self:isCanShowLayer() then
        if gLobalViewManager:getViewByExtendData("Activity_DiyTips") then
            return nil
        end
        local view = util_createView("Activity_DiySale.Activity_DiyTips",_callback)
        self:showLayer(view, ViewZorder.ZORDER_UI)
        return view
    end
    return nil
end

function Activity_DiySaleMgr:showBuffSaleLayer()
    if self:isCanShowLayer() then
        if gLobalViewManager:getViewByExtendData("Activity_DiySale") then
            return nil
        end
        local view = util_createView("Activity_DiySale.Activity_DiySale")
        self:showLayer(view, ViewZorder.ZORDER_UI)
        return view
    end
    return nil
end

function Activity_DiySaleMgr:popBuffSaleLayer()
    -- local ex = self:getEx()
    -- if ex then
    --     self:showBuffSaleLayer()
    --     return true
    -- end
    return self:showBuffSaleLayer()
end

-- function Activity_DiySaleMgr:isCanShowLayer()
--     -- 判断资源是否下载
--     if not self:isDownloadRes() then
--         return false
--     end

--     local _data = self:getData()
--     if not _data or (_data.isSleeping and _data:isSleeping()) then
--         -- 无数据或在睡眠中
--         return false
--     end

--     return true
-- end

function Activity_DiySaleMgr:buyBuffSale(_data)
    if not _data then
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    globalData.iapRunData.p_contentId = _data.p_seq
    local function success()
        gLobalViewManager:checkBuyTipList(function ()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DIY_BUFF_SALE,{index = _data.p_seq})
        end)
    end
    local function fail()
    end
    local ret = gLobalSaleManager:purchaseGoods(BUY_TYPE.DIY_BUFFSALE, _data.p_keyId, _data.p_price, 0, 0, success, fail)
end

function Activity_DiySaleMgr:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "DIYWheelSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "DIYWheelSale"
    purchaseInfo.purchaseStatus = "DIYWheelSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

function Activity_DiySaleMgr:requestCancleBack(callback)
    local success_call_fun = function(resData)
        if callback then
            callback()
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    self.m_netModel:requestCancleBack(success_call_fun, faild_call_fun)
end

-- function Activity_DiySaleMgr:getEx()
--     local data = self:getData()
--     if not data then
--         return
--     end
    
--     return data:getEx()
-- end

function Activity_DiySaleMgr:getIsAll()
    local data = self:getData()
    if not data then
        return
    end

    return data:IsAll()
end

return Activity_DiySaleMgr
