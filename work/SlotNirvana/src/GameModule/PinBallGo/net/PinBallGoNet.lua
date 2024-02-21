--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local PinBallGoNet = class("PinBallGoNet", BaseNetModel)
local ShopItem = util_require("data.baseDatas.ShopItem")


function PinBallGoNet:sendPlayGame(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_PINBALL_GAME, {success = false})
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_PINBALL_GAME, {success = true} )
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_PINBALL_GAME, {success = false})
    end

    self:sendActionMessage(ActionType.PinballPlay,tbData,successCallback,failedCallback)
end

function PinBallGoNet:sendCollectReward(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_COLLECT_PINBALL_REWARD, {success = false})
            return
        end
        if _result then
            if _result.items ~= nil then
                local itemData = {}
                for index, value in ipairs(_result.items) do
                    local shopItem = ShopItem:create()
                    shopItem:parseData(value, true)
                    itemData[index] = shopItem
                end
                _result.items = itemData
            end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_COLLECT_PINBALL_REWARD, {success = true,result = _result} )
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_COLLECT_PINBALL_REWARD, {success = false})
    end

    self:sendActionMessage(ActionType.PinballCollect,tbData,successCallback,failedCallback)
end

function PinBallGoNet:sendHitCell(_index,_pos)
    local tbData = {
        data = {
            params = {
                index = _index,
                pos = _pos
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_HIT_PINBALL_CELL, {success = true,result = _result} )
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_HIT_PINBALL_CELL, {success = false})
    end

    self:sendActionMessage(ActionType.PinballHitGrid,tbData,successCallback,failedCallback)
end
return PinBallGoNet