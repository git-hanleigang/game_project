--[[
]]
local ReturnTaskData = class("ReturnTaskData")

-- message ReturnSignTask {
--     optional string taskId = 1;
--     optional string description = 2;
--     repeated int64 process = 3;
--     repeated int64 params = 4;
--     optional int32 passExp = 5;
--     optional bool completed = 6;
--     optional bool collected = 7;
--   }
function ReturnTaskData:parseData(_netData, _serverIndex)
    self.p_taskId = _netData.taskId
    self.p_description = _netData.description
    
    self.p_process = {}
    if _netData.process and #_netData.process > 0 then
        for i = 1, #_netData.process do
            table.insert(self.p_process, tonumber(_netData.process[i]))
        end
    end
    self.p_params = {}
    if _netData.params and #_netData.params > 0 then
        for i = 1, #_netData.params do
            table.insert(self.p_params, tonumber(_netData.params[i]))
        end
    end

    self.p_passExp = _netData.passExp
    self.p_completed = _netData.completed
    self.p_collected = _netData.collected

    self.p_description = string.gsub(self.p_description, "%%s", tostring(self.p_params[#self.p_params]))

    self.m_serverIndex = _serverIndex -- 服务器的排序
end

function ReturnTaskData:getServerIndex()
    return self.m_serverIndex
end

function ReturnTaskData:getTaskId()
    return self.p_taskId
end

function ReturnTaskData:getDesc()
    return self.p_description
end

function ReturnTaskData:getProcess()
    return self.p_process
end

function ReturnTaskData:getParams()
    return self.p_params
end

function ReturnTaskData:getPassExp()
    return self.p_passExp
end

function ReturnTaskData:isCompleted()
    return self.p_completed
end

function ReturnTaskData:isCollected()
    return self.p_collected
end

function ReturnTaskData:getCur()
    return self.p_process[#self.p_process] or 0
end

function ReturnTaskData:getMax()
    return self.p_params[#self.p_params] or 0
end

return ReturnTaskData
