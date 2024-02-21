--[[
    第二货币抽奖
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local MegaWinPartyNet = class("MegaWinPartyNet", BaseNetModel)
local ShopItem = util_require("data.baseDatas.ShopItem")

function MegaWinPartyNet:getInstance()
    if self.instance == nil then
        self.instance = MegaWinPartyNet.new()
    end
    return self.instance
end

--[[
    type：0 | 1 (0-丢弃宝箱，1-花费钻石开宝箱)    position：0 | 1~4  (0-额外宝箱，1~4 - 已有宝箱位置)
]]
function MegaWinPartyNet:requestDropOrGemOpenBox(type,pos,dtp,callback)
    local tbData = {
        data = {
            params = {
                type = type,
                position = pos,
                dtp = dtp 
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if callback then
            callback()
        end
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEGAWIN_AFTEDROPORGEMOPEN,{isSuccess = false,type = type, pos = pos})
            return
        end

        if _result then
            if _result.boxItems ~= nil then
                local rewardDatas = {}
                for i=1,#_result.boxItems do
                    local oneDate = _result.boxItems[i]
                    local itemDataVec = {}
                    if oneDate.items and #oneDate.items > 0 then
                        for index, value in ipairs(oneDate.items) do
                            local shopItem = ShopItem:create()
                            shopItem:parseData(value, true)
                            itemDataVec[index] = shopItem
                        end
                        oneDate.items = itemDataVec
                    end

                    table.insert(rewardDatas, oneDate)
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEGAWIN_AFTEDROPORGEMOPEN, {isSuccess = true,type = type, pos = pos, result = rewardDatas})
            end
        end
        
    end

    local failedCallback = function (errorCode, errorData)
        if callback then
            callback()
        end
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEGAWIN_AFTEDROPORGEMOPEN,{isSuccess = false,type = type, pos = pos})
    end

    self:sendActionMessage(ActionType.MegaWinDealExtraBox,tbData,successCallback,failedCallback)
end

--[[
    领取到时宝箱
]]
function MegaWinPartyNet:requestOpenBox(callback,failCall)
    local tbData = {
        data = {
            params = {
                type = 0,
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if callback then
            callback()
        end

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEGAWIN_AFTERCOLLECTBOX,{isSuccess = false})
            return
        end
        if _result then
            if _result.boxItems ~= nil then
                local rewardDatas = {}
                for i=1,#_result.boxItems do
                    local oneDate = _result.boxItems[i]
                    local itemDataVec = {}
                    if oneDate.items and #oneDate.items > 0 then
                        for index, value in ipairs(oneDate.items) do
                            local shopItem = ShopItem:create()
                            shopItem:parseData(value, true)
                            itemDataVec[index] = shopItem
                        end
                        oneDate.items = itemDataVec
                    end

                    table.insert(rewardDatas, oneDate)
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEGAWIN_AFTERCOLLECTBOX, {isSuccess = true, result = rewardDatas})
            end
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failCall then
            failCall()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEGAWIN_AFTERCOLLECTBOX,{isSuccess = false})
    end

    self:sendActionMessage(ActionType.MegaWinCollectReward,tbData,successCallback,failedCallback)
end

return MegaWinPartyNet
