--[[
    fullview 家具数据
]]
-- fullview 节点
-- message RedecorateNode {
--     optional int32 nodeId = 1;    //节点id
--     optional string name = 2; //名称
--     optional bool complete = 13;    //是否完成
--     optional int32 curStyle = 16;    //当前风格
--     optional string refName = 18;    //引用名
--   }

local RedecorFullViewNodeData = class("RedecorFullViewNodeData")
function RedecorFullViewNodeData:parseData(_netData)
    self.p_nodeId = _netData.nodeId
    self.p_name = _netData.name
    self.p_complete = _netData.complete
    self.p_curStyle = _netData.curStyle
    self.p_refName = _netData.refName
end

function RedecorFullViewNodeData:getNodeId()
    return self.p_nodeId
end
function RedecorFullViewNodeData:getName()
    return self.p_name
end
function RedecorFullViewNodeData:isComplete()
    return self.p_complete
end
function RedecorFullViewNodeData:getCurStyle()
    return self.p_curStyle
end
function RedecorFullViewNodeData:getRefName()
    return self.p_refName
end

function RedecorFullViewNodeData:setCurStyle(_style)
    self.p_curStyle = _style
end

-- 判断是否是清理
function RedecorFullViewNodeData:isClean()
    if self:getRefName() == "qingLi" then
        return true
    end
    return false
end

return RedecorFullViewNodeData
