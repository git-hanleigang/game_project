--[[
    fullview 数据
]]
local RedecorFullViewNodeData = import(".RedecorFullViewNodeData")
local RedecorFullViewData = class("RedecorFullViewData")
function RedecorFullViewData:parseData(_netData)
    self.p_activityName = _netData.activityName
    self.p_nodes = {}
    if _netData.nodes and #_netData.nodes > 0 then
        for i = 1, #_netData.nodes do
            local fvNodeData = RedecorFullViewNodeData:create()
            fvNodeData:parseData(_netData.nodes[i])
            table.insert(self.p_nodes, fvNodeData)
        end
    end
end

function RedecorFullViewData:getActivityName()
    return self.p_activityName
end

function RedecorFullViewData:getNodes()
    return self.p_nodes
end

function RedecorFullViewData:getCompletedNodes()
    local completes = {}
    local nodes = self:getNodes()
    for i = 1, #nodes do
        local nodeData = nodes[i]
        if nodeData:isComplete() == true then
            table.insert(completes, nodeData)
        end
    end
    return completes
end

function RedecorFullViewData:getFurnitureDataByRefName(_refName)
    local nodes = self:getNodes()
    for i = 1, #nodes do
        local nodeData = nodes[i]
        if nodeData:getRefName() == _refName then
            return nodeData
        end
    end
end

function RedecorFullViewData:getFurnitureDataByNodeId(_nodeId)
    local nodes = self:getNodes()
    for i = 1, #nodes do
        local nodeData = nodes[i]
        if nodeData:getNodeId() == _nodeId then
            return nodeData
        end
    end
end

return RedecorFullViewData
