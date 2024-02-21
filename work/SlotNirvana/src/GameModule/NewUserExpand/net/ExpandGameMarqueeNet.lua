--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-13 11:57:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-13 11:57:40
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/net/ExpandGameMarqueeNet.lua
Description: 扩圈游戏 跑马灯 spin 玩
--]]
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local ActionNetModel = import("net.netModel.ActionNetModel")
local ExpandGameMarqueeNet = class("ExpandGameMarqueeNet", ActionNetModel)

-- 玩游戏 3次 结束结算此游戏
function ExpandGameMarqueeNet:sendOverExpandGameReq(_successFunc)
    gLobalViewManager:addLoadingAnima(false, 2)

    local successFunc = function(_receiveData)
        if _successFunc then
            _successFunc(_receiveData)
        end 
        gLobalViewManager:removeLoadingAnima()
        -- gLobalNoticManager:postNotification(ExpandGameMarqueeConfig.EVENT_NAME.PLAY_EXPAND_MINI_GMAE_SUCCESS)
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        -- gLobalNoticManager:postNotification(ExpandGameMarqueeConfig.EVENT_NAME.PLAY_EXPAND_MINI_GMAE_FAILD)
    end
    local reqData = {}
    self.m_timeOutKickOff = true
    self:sendActionMessage(ActionType.ExpandCirclePyiCollect, reqData, successFunc, failedFunc)
end

return ExpandGameMarqueeNet