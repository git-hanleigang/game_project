--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local ShopBuckNet = class("ShopBuckNet", BaseNetModel)

-- message BuckPurchaseRequest {
--     optional string price = 1; //价格，单位美元e
--     optional string buyType = 2; //购买类型
--     optional string extra = 3; //附加信息（小游戏、存钱罐）
--     optional string orderId = 4;// 订单号
--   }
function ShopBuckNet:useBuckToBuy(_order, _buyType, _extra, _price, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        if funF then
            funF()
        end
        return
    end
    -- 断网检查,网络未连接则直接失败
    if gLobalSendDataManager:checkShowNetworkDialog() == true then
        if funF then
            funF()
        end
        return
    end

    gLobalViewManager:addLoadingAnima()

    local successCall = function(responseTable, headers)
        gLobalViewManager:removeLoadingAnima()

        local responseData = responseTable

        -- user 跟 result 同级
        if responseData:HasField("user") then
            globalData.syncSimpleUserInfo(responseData.user)
        end

        -- 解析result的json字符串
        local resResults = {}
        if responseData.results then
            resResults = responseData.results
        end
        if #resResults > 0 then
            for i = 1, #resResults do
                local resResultsData = resResults[i]
                if resResultsData.code == 1 then
                    release_print("----Purchase Bucks 成功")
                    print("----Purchase Bucks 成功")
                    -- globalData.isPurchaseCallback = true
    
                    -- 解析result数据
                    gLobalSendDataManager:getNetWorkIap():parsePurchaseResultData(resResultsData)
                    
                    -- 支付订单成功
                    gLobalSendDataManager:getLogIap():createGoodsInfo(_order, "success")
    
                    -- globalData.isPurchaseCallback = false
                    if funS ~= nil then
                        local result = nil
                        if resResultsData:HasField("result") then
                            result = resResultsData.result
                        end
                        funS(result)
                    end
                    gLobalSaleManager:deleteUserIapOrder(_order)
                    gLobalSendDataManager:getLogIap():sendOrderLog("success")
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PURCHASE_SUCCESS, {result = resResultsData.result, isConsumeBuck = true})
                    -- 消耗代币
                    local now = G_GetMgr(G_REF.ShopBuck):getBuckNum()
                    G_GetMgr(G_REF.Currency):setBucks(now)
                else
                    local bHas = false
                    if resResultsData.code == 12 then --订单验证失败
                    elseif resResultsData.code == 13 then --订单已经存在
                        bHas = true
                    end
                    if resResultsData.code == 9 then
                        gLobalSaleManager:deleteUserIapOrder(_order)
                    end
                    gLobalSendDataManager:getLogIap():sendOrderLog("failed")
                    release_print("----Purchase Bucks 购买 failed 1")
                    print("----Purchase Bucks 购买 failed 1")
                    if funF then
                        funF(bHas)
                    end                
                end
            end        
        else
            release_print("----Purchase Bucks 购买 failed 11")
            print("----Purchase Bucks 购买 failed 11")
            if funF then
                funF()
            end  
        end
    end
    local faildCall = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print("----Purchase Bucks 购买 failed 2")
        print("----Purchase Bucks 购买 failed 2")        
        if funF then
            funF(errorCode, errorData)
        end
    end
    
    -- 参数
    local tbData = {}
    tbData.buyType = _buyType
    tbData.price = _price
    tbData.extra = cjson.encode(_extra or {})
    tbData.orderId = _order
    self:sendMessage(ProtoConfig.USE_BUCK_PURCHASE, tbData, successCall, faildCall)
    return true    
end

return ShopBuckNet