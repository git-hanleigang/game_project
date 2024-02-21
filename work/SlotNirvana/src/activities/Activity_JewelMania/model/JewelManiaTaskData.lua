--[[
]]
local JewelManiaTaskData = class("JewelManiaTaskData")

function JewelManiaTaskData:ctor()
end

-- message JewelManiaTask {
--     optional string type = 1;//任务类型
--     optional int32 index = 2;//小任务序号
--     optional int32 points = 3;//奖励点数
--     optional string icon = 4;//资源图
--     optional string description = 5;//描述
--     optional string status = 6;//任务状态(init/completed/tomorrow/allDone/comeSoon)
--     optional int32 unCollected = 7;//未领取次数
--     optional int32 taskPosition = 8;//任务位置
--     optional int32 countLimit = 9;//任务限制次数
--     optional int32 completedCount = 10;//完成次数
--     optional int32 dailyCountLimit = 11;//任务每日限制次数
--     optional int32 dailyCompletedCount = 12;//每日完成次数
--     optional int64 progress = 13;//当前进度
--     optional int64 param = 14;//进度最大值
--   }

-- message JewelManiaTask {
--     optional string taskType = 1;//任务类型
--     optional int32 index = 2;//小任务序号
--     optional int32 points = 3;//奖励点数
--     optional string icon = 4;//资源图
--     optional string description = 5;//描述
--     repeated string paramList = 6;//参数列表
--   }

function JewelManiaTaskData:parseData(_netData)
    self.p_taskType = _netData.taskType
    self.p_index = _netData.index
    self.p_points = _netData.points
    self.p_icon = _netData.icon
    self.p_description = _netData.description
    self.p_paramList = {}
    if _netData.paramList and #_netData.paramList > 0 then
        for i=1,#_netData.paramList do
            table.insert(self.p_paramList, _netData.paramList[i])
        end
    end
end

function JewelManiaTaskData:getTaskType()
    return self.p_taskType
end
function JewelManiaTaskData:getIndex()
    return self.p_index
end
function JewelManiaTaskData:getPoints()
    return self.p_points
end
function JewelManiaTaskData:getIcon()
    return self.p_icon
end
function JewelManiaTaskData:getDescription()
    return self.p_description
end
function JewelManiaTaskData:getParamList()
    return self.p_paramList
end

return JewelManiaTaskData