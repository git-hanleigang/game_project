-- 集卡商店 网络协议

local BaseActivityManager = util_require("baseActivity.BaseActivityManager")
local CardStoreNet = class("CardStoreNet", BaseActivityManager)

function CardStoreNet:getInstance()
    if self.instance == nil then
        self.instance = CardStoreNet.new()
    end
    return self.instance
end

-- 集卡商店刷新商店
function CardStoreNet:requestCardStoreReset(refreshType, successCallFun, failedCallFun)
    local function successFunc(resData)
        if resData:HasField("simpleUser") == true then
            globalData.syncSimpleUserInfo(resData.simpleUser)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        end
        if successCallFun then
            successCallFun()
        end
    end

    local function failedFunc(target, errorCode, errorData)
        if failedCallFun then
            failedCallFun()
        end
    end
    local params = {
        refreshType = refreshType
    }
    self:sendMsgBaseFunc(ActionType.CardStoreV2RefreshStore, nil, params, successFunc, failedFunc)
end

-- 集卡商店免费礼物领取
function CardStoreNet:requestCardStoreGiftCollect(successCallFun, failedCallFun)
    local function successFunc(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil then
            if successCallFun then
                successCallFun(result)
            end
        else
            if failedCallFun then
                failedCallFun()
            end
        end
    end

    local function failedFunc(target, errorCode, errorData)
        if failedCallFun then
            failedCallFun()
        end
    end

    local params = {}
    self:sendMsgBaseFunc(ActionType.CardStoreV2FreeGetGift, nil, params, successFunc, failedFunc)
end

-- 集卡商店兑换
function CardStoreNet:requestCardStoreExchange(item_id, item_num, item_type, successCallFun, failedCallFun)
    local function successFunc(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil then
            if successCallFun then
                successCallFun(result)
            end
        else
            if failedCallFun then
                failedCallFun()
            end
        end
    end

    local function failedFunc(target, errorCode, errorData)
        if failedCallFun then
            failedCallFun()
        end
    end

    local params = {
        id = item_id,
        num = item_num,
        type = item_type
    }
    self:sendMsgBaseFunc(ActionType.CardStoreV2Exchange, nil, params, successFunc, failedFunc)
end

-- 集卡商店赛季结算引导
function CardStoreNet:requestCardStoreGuide()
    self:sendMsgBaseFunc(ActionType.CardStoreV2UpdateShowGuide)
end

return CardStoreNet
