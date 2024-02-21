--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-05 11:40:11
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local MemoryLaneNet = class(" MemoryLaneNet", BaseNetModel)

function MemoryLaneNet:getInstance()
    if self.instance == nil then
        self.instance = MemoryLaneNet.new()
    end
    return self.instance
end

-- 请求奖励
function MemoryLaneNet:requestRewardCollect(_type, _photoId)
    local tbData = {
        data = {
            params = {
                Type = _type,
                PhotoId = _photoId
            }
        }
    }
    
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            -- 失败
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MEMORYLANE_REWARD, false)
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MEMORYLANE_REWARD, {result = _result, type = _type, photoId = _photoId})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MEMORYLANE_REWARD, false)
    end

    self:sendActionMessage(ActionType.MemoryLaneCollectReward, tbData, successCallback, failedCallback)
end

return MemoryLaneNet
