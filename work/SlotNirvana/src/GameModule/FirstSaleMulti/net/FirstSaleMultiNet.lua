--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-25 10:57:53
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-25 15:00:25
FilePath: /SlotNirvana/src/GameModule/FirstSaleMulti/net/FirstSaleMultiNet.lua
Description: 三档首充 net
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local FirstSaleMultiNet = class("FirstSaleMultiNet", ActionNetModel)
local FirstSaleMultiConfig = util_require("GameModule.FirstSaleMulti.config.FirstSaleMultiConfig")

function FirstSaleMultiNet:goPurchase(_levelData)
    self._levelData = clone(_levelData)

    local goodsInfo = {}
    goodsInfo.discount = _levelData:getDiscount()
    goodsInfo.goodsId = _levelData:getKeyId()
    goodsInfo.goodsPrice = tostring(_levelData:getPrice())
    goodsInfo.totalCoins = _levelData:getCoins()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    local level = _levelData:getLevel() --购买档位
    self:sendIapLog(goodsInfo, level)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_levelData)
    gLobalSaleManager:purchaseActivityGoods(BUY_TYPE.FIRST_SALE_MULTI, level, BUY_TYPE.FIRST_SALE_MULTI,  goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end
function FirstSaleMultiNet:buySuccess()
    if self._levelData then
        local mergeBagList = self._levelData:getMergePropsBagList()
        G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):setPopPropsBagTempList(mergeBagList)
    end

    -- gLobalViewManager:checkBuyTipList(function() 
        gLobalNoticManager:postNotification(FirstSaleMultiConfig.EVENT_NAME.FIRST_SALE_MULTI_PAY_SUCCESS, self._levelData)
    -- end)
end
function FirstSaleMultiNet:buyFailed()
    print("FirstSaleMultiNet--buy--failed")
    gLobalNoticManager:postNotification(FirstSaleMultiConfig.EVENT_NAME.FIRST_SALE_MULTI_PAY_FAILD)
end

function FirstSaleMultiNet:sendIapLog(_goodsInfo, _level)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = BUY_TYPE.FIRST_SALE_MULTI
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = _goodsInfo.discount
    goodsInfo.totalCoins = _goodsInfo.totalCoins
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = BUY_TYPE.FIRST_SALE_MULTI
    purchaseInfo.purchaseStatus = _level
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

return FirstSaleMultiNet