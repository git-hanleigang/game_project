--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-31 11:04:03
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-31 11:04:03
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/net/IcebreakerSaleNet.lua
Description: 新破冰促销 net
--]]
local BaseNetModel = import("net.netModel.BaseNetModel")
local IcebreakerSaleConfig = util_require("GameModule.IcebreakerSale.config.IcebreakerSaleConfig")
local IcebreakerSaleNet = class("IcebreakerSaleNet", BaseNetModel)

function IcebreakerSaleNet:sendCollectReq(_positionList, _successFunc)
    gLobalViewManager:addLoadingAnima(true)
    local successFunc = function(protoResult)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc and protoResult then
            _successFunc(protoResult)
        else
            gLobalNoticManager:postNotification(IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_COLLECT_FAILED)
        end 
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_COLLECT_FAILED)
    end
    local reqData = {
        data = {
            params = {
                positions = _positionList,
            }
        }
    }
    self:sendActionMessage(ActionType.IceBrokenSaleCollect, reqData, successFunc, faildFunc)
end

-- 充值
function IcebreakerSaleNet:goPurchase(_gameData)
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _gameData:getKeyId()
    goodsInfo.goodsPrice = tostring(_gameData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_gameData)
    gLobalSaleManager:purchaseGoods(BUY_TYPE.ICE_BROKEN_SLAE,  goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))

end
function IcebreakerSaleNet:buySuccess()
    gLobalViewManager:checkBuyTipList(function() 
        gLobalNoticManager:postNotification(IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_SALE_BUY_SUCCESS)
    end)
end
function IcebreakerSaleNet:buyFailed()
    print("IcebreakerSaleNet--buy--failed")
    gLobalNoticManager:postNotification(IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_SALE_BUY_FAILED)
end

function IcebreakerSaleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = BUY_TYPE.ICE_BROKEN_SLAE
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = BUY_TYPE.ICE_BROKEN_SLAE
    purchaseInfo.purchaseStatus = BUY_TYPE.ICE_BROKEN_SLAE
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

return IcebreakerSaleNet