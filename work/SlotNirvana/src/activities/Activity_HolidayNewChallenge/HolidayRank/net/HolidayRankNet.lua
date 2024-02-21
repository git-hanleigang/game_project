--[[
   圣诞聚合 -- 排行榜
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local HolidayRankNet = class("HolidayRankNet",BaseNetModel)

function HolidayRankNet:getInstance()
    if self.instance == nil then
        self.instance = HolidayRankNet.new()
    end
    return self.instance
end

-- 发送获取排行榜消息
function HolidayRankNet:sendActionRank(_flag)
    if _flag then
        gLobalViewManager:addLoadingAnima()
    end
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local function successFunc(resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData then
            --local rankData = cjson.decode(resultData)
            local act_data = G_GetMgr(ACTIVITY_REF.HolidayNewRank):getRunningData()
            if act_data and resultData then
                act_data:parseRankConfig(resultData)
                act_data:setRankJackpotCoins(0)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.HolidayNewRank})
            end
        else
            failedFunc()
        end
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.HolidayNewChallengeRank, tbData, successFunc, failedFunc)
end


return HolidayRankNet
