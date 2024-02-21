--[[
    author:JohnnyFred
    time:2020-06-15 14:44:50
]]
local PigSaleBoosterNet = class("PigSaleBoosterNet", util_require("baseActivity.BaseActivityManager"))

function PigSaleBoosterNet:getInstance()
    if self.instance == nil then
        self.instance = PigSaleBoosterNet.new()
    end
    return self.instance
end

-- 小猪银行 boost 选择buffer --
function PigSaleBoosterNet:sendPiggyBankBoosterChooseBuff(buffID, callFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    -- 开启等待 --
    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(responseTable)
        if callFun ~= nil then
            callFun(responseTable)
        end
        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.ChooseBooster)
    local extraData = {}
    extraData.booster = {buffId = buffID}

    actionData.data.extra = json.encode(extraData)

    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

return PigSaleBoosterNet
