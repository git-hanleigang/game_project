--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-06 11:06:11
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-06 11:07:50
FilePath: /SlotNirvana/src/GameModule/SysNoviceTask/controller/SysNoviceTaskMgr.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SysNoviceTaskMgr = class("SysNoviceTaskMgr", BaseGameControl)
local SysNoviceTaskConfig = util_require("GameModule.SysNoviceTask.config.SysNoviceTaskConfig")

function SysNoviceTaskMgr:ctor()
    SysNoviceTaskMgr.super.ctor(self)
    
    self:setRefName(G_REF.SysNoviceTask)
    self:setDataModule("GameModule.SysNoviceTask.model.SysNoviceTaskData")
end

-- 获取网络 obj
function SysNoviceTaskMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local FirstSaleMultiNet = util_require("GameModule.SysNoviceTask.net.SysNoviceTaskNet")
    self.m_net = FirstSaleMultiNet:getInstance()
    return self.m_net
end

-- 创建新手任务UI
function SysNoviceTaskMgr:createNoviceView()
    if not self:getRunningData() then
        return
    end

    local view = util_createView("GameModule.SysNoviceTask.views.SysNoviceTaskUI")
    return view
end

-- 新手任务是否可用
function SysNoviceTaskMgr:checkEnabled()
    local data = self:getData()
    if not data then
        return false
    end

    local status = data:getSysStatus()
    return status ~= SysNoviceTaskConfig.SYS_STATUS.CLOSE
end

-- 关卡spin更新任务
function SysNoviceTaskMgr:spinUpdateTaskInfo(_data)
    if type(_data) ~= "table" then
        return
    end
    local taskInfo = _data.task or {}
    if table.nums(taskInfo) == 0 then
        return
    end

    local data = self:getData()
    if not data then
        return
    end

    data:spinUpdateTaskInfo(taskInfo)
    gLobalNoticManager:postNotification(SysNoviceTaskConfig.EVENT_NAME.NOTICE_SYS_NOVICE_TASK_UPDATE)
end

-- 升级了更新下 新手任务UI
function SysNoviceTaskMgr:spinUpgradeLv()
    local data = self:getRunningData()
    if not data then
        return
    end
    
    gLobalNoticManager:postNotification(SysNoviceTaskConfig.EVENT_NAME.NOTICE_SYS_NOVICE_TASK_UPDATE)
end

-- 领取任务奖励
function SysNoviceTaskMgr:sendCollectTaskReq()
    self:getNetObj():sendCollectReq()
end
return SysNoviceTaskMgr