--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 16:28:45
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 16:28:53
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/net/ExpandGamePlinkoNet.lua
Description: 扩圈游戏 弹珠 spin 玩
--]]
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")
local ActionNetModel = import("net.netModel.ActionNetModel")
local ExpandGamePlinkoNet = class("ExpandGamePlinkoNet", ActionNetModel)

-- 玩游戏 3次 结束结算此游戏
function ExpandGamePlinkoNet:sendOverExpandGameReq(_successFunc)
    gLobalViewManager:addLoadingAnima(false, 2)

    local successFunc = function(_receiveData)
        if _successFunc then
            _successFunc(_receiveData)
        end 
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        -- gLobalViewManager:showReConnect()
    end
    local reqData = {}
    self.m_timeOutKickOff = true
    self:sendActionMessage(ActionType.ExpandCircleTqCollect, reqData, successFunc, failedFunc)
end

return ExpandGamePlinkoNet