--[[
    网络模块
    author:{author}
    time:2023-10-25 13:59:48
]]
local BaseNetModel = import("net.netModel.BaseNetModel")
local AChargeNet = class("AChargeNet", BaseNetModel)

-- 领取奖励
function AChargeNet:requestCollectAChargeReward(productId, succCallFunc, failedCallFunc)
    gLobalViewManager:addLoadingAnima()

    local _succCallFunc = function(protoResult)
        gLobalViewManager:removeLoadingAnima()

        -- user 跟 result 同级
        if protoResult:HasField("user") then
            globalData.syncSimpleUserInfo(protoResult.user)
        end

        local resResults = {}
        -- 解析result的json字符串
        if protoResult.results then
            resResults = protoResult.results
        end

        for i = 1, #resResults do
            local resResultsData = resResults[i]
            if resResultsData.code == 1 then
                release_print("----collectAChargeReward 成功")
                print("----collectAChargeReward 成功")
                -- globalData.isPurchaseCallback = true            

                -- 解析result数据
                gLobalSendDataManager:getNetWorkIap():parsePurchaseResultData(resResultsData)

                -- gLobalSendDataManager:getLogIap():createGoodsInfo(order, "success")

                -- globalData.isPurchaseCallback = false
                if succCallFunc ~= nil then
                    local result = nil
                    if resResultsData:HasField("result") then
                        result = resResultsData.result
                    end
                    succCallFunc(result)
                end
                -- gLobalSaleManager:deleteUserIapOrder(order)
                -- gLobalSendDataManager:getLogIap():sendOrderLog("success")
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PURCHASE_SUCCESS, {result = resResultsData.result})
            else
                local bHas = false
                if resResultsData.code == 12 then --订单验证失败
                elseif resResultsData.code == 13 then --订单已经存在
                    bHas = true
                end
                -- if resResultsData.code == 9 then
                --     gLobalSaleManager:deleteUserIapOrder(order)
                -- end
                release_print("----collectAChargeReward 购买 failed ")
                print("----collectAChargeReward 购买 failed")
                -- gLobalSendDataManager:getLogIap():sendOrderLog("failed")
                if failedCallFunc ~= nil then
                    failedCallFunc(bHas)
                end
            end
        end
    end

    local _failedCallFunc = function(...)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(...)
        end
    end

    local params = {
        productId = productId
    }

    self:sendMessage(ProtoConfig.APP_CHARGE_COLLECT, params, _succCallFunc, _failedCallFunc)
end

return AChargeNet
