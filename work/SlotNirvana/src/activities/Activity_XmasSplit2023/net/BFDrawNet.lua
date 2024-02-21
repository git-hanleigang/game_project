--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-03 17:00:15
]]
--[[
    装修网络层
    author: 徐袁
    time: 2021-09-09 11:28:23
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local BFDrawNet = class(" BFDrawNet", BaseNetModel)

function BFDrawNet:getInstance()
    if self.instance == nil then
        self.instance = BFDrawNet.new()
    end
    return self.instance
end

-- 请求抽奖
function BFDrawNet:requestDraw(_spin)
    local tbData = {
        data = {
            params = {
                spin = _spin
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then
            -- 失败
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BFDRAW_DRAW, false)
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BFDRAW_DRAW, _result)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BFDRAW_DRAW, false)
    end

    self:sendActionMessage(ActionType.BlackFridayLotteryCollect, tbData, successCallback, failedCallback)
end

return BFDrawNet
