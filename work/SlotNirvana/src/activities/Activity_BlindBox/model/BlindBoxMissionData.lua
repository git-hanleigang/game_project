--[[
    集装箱任务数据
    author:{author}
    time:2023-11-21 19:15:02
]]
-- message BlindBoxMission {
--     optional int64 expireAt = 1; //结束时间
--     repeated BlindBoxMissionInfo missionList = 2; //任务列表
-- }

local BlindBoxMissionInfo = require("activities.Activity_BlindBox.model.BlindBoxMissionInfo")
local BlindBoxMissionData = class("BlindBoxMissionData")

function BlindBoxMissionData:parseData(data, _isUnlockPass)
    self.m_expireAt = data.expireAt or 0

    self.m_missionInfos = {}
    for i = 1, #(data.missionList or {}) do
        local _info = BlindBoxMissionInfo:create()
        _info:parseData(data.missionList[i], _isUnlockPass, self.m_expireAt)
        table.insert(self.m_missionInfos, _info)
    end
    -- 金色任务优先级最高
    local function sortFunc(a, b)
        local aPassIdx = a:isPassTask() == true and 1 or 2
        local bPassIdx = b:isPassTask() == true and 1 or 2
        local aId = a:getId()
        local bId = b:getId()
        if aPassIdx == bPassIdx then
            return aId < bId
        else
            return aPassIdx < bPassIdx
        end
    end
    table.sort(self.m_missionInfos, sortFunc)
end

function BlindBoxMissionData:getMissionInfos()
    return self.m_missionInfos
end

function BlindBoxMissionData:getMissionInfoById(_id)
    if self.m_missionInfos and #self.m_missionInfos > 0 then
        for i=1,#self.m_missionInfos do
            if _id == self.m_missionInfos[i]:getId() then
                return self.m_missionInfos[i]
            end
        end
    end
    return
end

-- 获取完成但是没有领奖的任务
-- pass任务需要解锁了pass才能计入
function BlindBoxMissionData:getUnCollectMissions()
    local unCollects = {}
    if self.m_missionInfos and #self.m_missionInfos > 0 then
        for i=1,#self.m_missionInfos do
            local info = self.m_missionInfos[i]
            if info:isPassTask() then
                if info:getStatus() == BlindBoxConfig.MissionStatus.Complete then
                    if info:isUnlockPass() then
                        table.insert(unCollects, info)
                    end
                end
            else
                if info:getStatus() == BlindBoxConfig.MissionStatus.Complete then
                    table.insert(unCollects, info)
                end
            end
        end
    end
    return unCollects
end

return BlindBoxMissionData
