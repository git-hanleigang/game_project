--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-05 11:58:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-05 12:02:48
FilePath: /SlotNirvana/src/GameModule/LuckySpin/net/LuckySpinNet.lua
Description: LuckySpin 网络net  
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local LuckySpinNet = class("LuckySpinNet", ActionNetModel)
local LuckySpinConfig = util_require("GameModule.LuckySpin.config.LuckySpinConfig")

-- 充值
function LuckySpinNet:goPurchase(_buyType, _extraStr)
    if not _buyType then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = globalData.luckySpinData.p_product
    goodsInfo.goodsPrice = globalData.luckySpinData.p_price
    -- goodsInfo.totalCoins slot机spin 设置了
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    gLobalSaleManager:purchaseActivityGoods(BUY_TYPE.LUCKY_SPIN_TYPE .. "_".. _buyType, _extraStr, BUY_TYPE.LUCKY_SPIN_TYPE, goodsInfo.goodsId, goodsInfo.goodsPrice, goodsInfo.totalCoins, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end

function LuckySpinNet:buySuccess()
    gLobalNoticManager:postNotification(LuckySpinConfig.EVENT_NAME.LUCKY_SPIN_BUY_SUCCESS)
end

function LuckySpinNet:buyFailed()
    print("LuckySpinNet--buy--failed")
end

function LuckySpinNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "lucky"
    -- purchaseInfo.purchaseStatus slot机spin 设置了
    gLobalSendDataManager:getLogIap():openIapLogInfo(_goodsInfo, purchaseInfo, nil, nil, self)
end

-- 充值
function LuckySpinNet:goPurchaseV2(_buyType, _extraStr)
    if not _buyType then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = globalData.luckySpinV2:getProut()
    goodsInfo.goodsPrice = globalData.luckySpinV2:getPrice()
    -- goodsInfo.totalCoins slot机spin 设置了
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    gLobalSaleManager:purchaseActivityGoods(BUY_TYPE.LUCKY_SPINV2_TYPE .. "_".. _buyType, _extraStr, BUY_TYPE.LUCKY_SPINV2_TYPE, goodsInfo.goodsId, goodsInfo.goodsPrice, goodsInfo.totalCoins, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end

return LuckySpinNet