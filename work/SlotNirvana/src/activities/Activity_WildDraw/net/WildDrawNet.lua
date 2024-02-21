--[[
    wild卡转盘
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local WildDrawNet = class("WildDrawNet", BaseNetModel)

function WildDrawNet:getInstance()
    if self.instance == nil then
        self.instance = WildDrawNet.new()
    end
    return self.instance
end

function WildDrawNet:sendWildDraw()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WILD_DRAM_GET_REWARD, {success = true, result = _result})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WILD_DRAM_GET_REWARD)
    end

    self:sendActionMessage(ActionType.WildDrawFreeDraw, tbData, successCallFun, failedCallFun)
end

-- 付费
function WildDrawNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WILD_DRAM_BUY_SALE)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalViewManager:addLoadingAnima(false, 1)

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.WILD_DRAW,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function(_result)
            gLobalViewManager:removeLoadingAnima()
            local result = {}
            if _result then
                result = cjson.decode(_result)
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WILD_DRAM_BUY_SALE, {success = true, result = result, type = "pay"})
        end,
        function(_errorInfo)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WILD_DRAM_BUY_SALE, {errorInfo = _errorInfo})
        end
    )
end

function WildDrawNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = " WildDraw"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = " WildDraw"
    purchaseInfo.purchaseStatus = " WildDraw"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return WildDrawNet
