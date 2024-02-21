--[[
    网络模块
    author:{author}
    time:2023-10-25 13:59:48
]]
local BaseNetModel = import("net.netModel.BaseNetModel")
local BoxSystemNet = class("BoxSystemNet", BaseNetModel)

-- 领取奖励
function BoxSystemNet:requestCollectReward(groupName, succCallFunc, failedCallFunc)
    gLobalViewManager:addLoadingAnima(true, 1)

    local _succCallFunc = function(resData)
        gLobalViewManager:removeLoadingAnima()
        if succCallFunc then
            succCallFunc(resData)
        end
    end

    local _failedCallFunc = function(...)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(...)
        end
    end

    local tbData = {
        data = {
            params = {groupName = groupName}
        }
    }
    self:sendActionMessage(ActionType.PassMysteryBoxCollect, tbData, _succCallFunc, _failedCallFunc)
end

return BoxSystemNet
