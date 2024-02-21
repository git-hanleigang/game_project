
local BaseNetModel = require("net.netModel.BaseNetModel")
local JewelManiaNet = class("JewelManiaNet", BaseNetModel)
local JewelManiaConfig = require("activities.Activity_JewelMania.config.JewelManiaCfg")

-- 付费
function JewelManiaNet:buyChapterPay(_data, succCallFunc, failedCallFunc)
    if not _data then
        if failedCallFunc then
            failedCallFunc()
        end
        return
    end
   
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getkeyId()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    -- local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    -- gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.JEWELMANIASALE,
        _data:getkeyId(),
        _data:getPrice(),
        0,
        0,
        succCallFunc,
        failedCallFunc
    )
end

-- 领取
-- chapter 章节
-- type 传 free pay all
-- type 传all的时候 chapter传-1
function JewelManiaNet:sendCollectChapterReward(_chapterIndex, _type, _succ, _fail)
    local tbData = {
        data = {
            params = {
                chapter = _chapterIndex,
                type = _type
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _succ then
            _succ(_result)
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _fail then
            _fail()
        end
    end
    self:sendActionMessage(ActionType.JewelManiaCollect, tbData, successCallback, failedCallback)
end

-- 小游戏砸砖块
function JewelManiaNet:sendClickSlateReq(type, slateIndex, success, fail)
    local reqData = {
        data = {
            params = {
                slateIndex = slateIndex
            }
        }
    }

    local function successCallFunc(resData)
        print("砸砖块" .. slateIndex)
        if success then
            success(resData)
        end
    end

    local function failedCallFunc(code, errorMsg)
        if fail then
            fail()
        end
    end

    if type == "JewelManiaPlaySpecialChapter" then
         self:sendActionMessage(ActionType.JewelManiaPlaySpecialChapter, reqData, successCallFunc, failedCallFunc)
    else
        self:sendActionMessage(ActionType.JewelManiaPlay, reqData, successCallFunc, failedCallFunc)
    end

end

function JewelManiaNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "JewelManiaSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "JewelManiaSale"
    purchaseInfo.purchaseName = "JewelManiaSale"
    purchaseInfo.purchaseStatus = "JewelManiaSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end


return JewelManiaNet 