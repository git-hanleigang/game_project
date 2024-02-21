--[[
    成长基金网络
    author:{author}
    time:2023-03-10 15:53:37
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local GrowthFundNet = class("GrowthFundNet", BaseNetModel)

-- 领取奖励
function GrowthFundNet:collectReward(_position,_rewardType, _success, _failed)
    gLobalViewManager:addLoadingAnima()
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.position = _position
    tbData.data.params.type = _rewardType
    local acttionType = ActionType.GrowthFundCollect
    if G_GetMgr(G_REF.GrowthFund):checkIsNew() then
        acttionType = ActionType.GrowthFundV3Collect
    end
    self:sendActionMessage(acttionType, tbData, successFunc, failedFunc)
end

return GrowthFundNet
