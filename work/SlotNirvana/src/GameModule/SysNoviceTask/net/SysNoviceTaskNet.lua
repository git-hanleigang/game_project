--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-06 11:20:12
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-06 11:20:39
FilePath: /SlotNirvana/src/GameModule/SysNoviceTask/net/SysNoviceTaskNet.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local SysNoviceTaskNet = class("SysNoviceTaskNet", ActionNetModel)
local SysNoviceTaskConfig = util_require("GameModule.SysNoviceTask.config.SysNoviceTaskConfig")

-- 新手任务领取
function SysNoviceTaskNet:sendCollectReq()
    gLobalViewManager:addLoadingAnima(true)
    local successFunc = function(_receiveData)
        gLobalNoticManager:postNotification(SysNoviceTaskConfig.EVENT_NAME.COLLECT_SYS_NOVICE_TASK_SUCCESS, _receiveData)
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end
    self:sendActionMessage(ActionType.NewUserGuideCollect, nil, successFunc, failedFunc)
end

return SysNoviceTaskNet