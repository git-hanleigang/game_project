--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-11 18:13:37
    describe:小猪转盘网络层
]]
--[[
    -- 活动网络通信模块
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local GoodWheelPiggyNet = class("GoodWheelPiggyNet", BaseNetModel)

function GoodWheelPiggyNet:requestSpin(data, successCallFunc, failedCallFunc)
    local tbData = {
        data = {
            params = {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        -- if resData:HasField("result") == true then
        --     result = cjson.decode(resData.result)
        -- end
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    self:sendActionMessage(ActionType.PigDishRewardData, tbData, successCallback, failedCallback)
end

return GoodWheelPiggyNet
