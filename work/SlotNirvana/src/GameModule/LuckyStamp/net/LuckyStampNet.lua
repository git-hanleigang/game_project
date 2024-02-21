--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local LuckyStampNet = class("LuckyStampNet", BaseNetModel)

-- LuckyStampV2Collect = 307;//LuckyStampV2领奖
-- LuckyStampV2Play = 308;//LuckyStampV2抽奖

function LuckyStampNet:requestCollect(successCallFun, failedCallFun)
    gLobalViewManager:addLoadingAnimaDelay()
    local failedFunc = function(p1, p2, p3)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFun then
            failedCallFun()
        end
    end
    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successCallFun then
            successCallFun(resJson)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    -- tbData.data.params.key = _key
    -- tbData.data.params.game = _levelName
    self:sendActionMessage(ActionType.LuckyStampV2Collect, tbData, successFunc, failedFunc)
end

function LuckyStampNet:requestRoll(successCallFun, failedCallFun)
    gLobalViewManager:addLoadingAnimaDelay()
    local failedFunc = function(p1, p2, p3)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFun then
            failedCallFun()
        end
    end
    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successCallFun then
            successCallFun(resJson)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    -- tbData.data.params.key = _key
    -- tbData.data.params.game = _levelName
    self:sendActionMessage(ActionType.LuckyStampV2Play, tbData, successFunc, failedFunc)
end

return LuckyStampNet
