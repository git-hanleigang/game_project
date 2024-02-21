--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-13 11:04:27
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-13 11:10:36
FilePath: /SlotNirvana/src/activities/Activity_VCoupon/net/VCounponNet.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local VCounponNet = class("VCounponNet", ActionNetModel)

function VCounponNet:sendUseTicketReq(_ticketId, _cb)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function (_result)
        if _cb then
            _cb()
        end
        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end
    gLobalSendDataManager:getNetWorkFeature():sendUseTicket(_ticketId, successCallback, failedCallback)
end

return VCounponNet