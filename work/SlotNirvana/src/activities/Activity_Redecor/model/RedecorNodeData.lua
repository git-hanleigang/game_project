--[[--
    家具数据
]]
local RedecorSimpleTreasureData = import(".RedecorSimpleTreasureData")
local RedecorWheelData = import(".RedecorWheelData")
local RedecorNodeData = class("RedecorNodeData")

-- 节点
-- message RedecorateNode {
--     optional int32 nodeId = 1;    //节点id
--     optional string name = 2; //名称
--     optional int32 material = 3;    //需要的材料数量
--     optional bool open = 4;    //是否开启
--     optional bool complete = 5;    //是否完成
--     repeated RedecorateSimpleTreasure treasures = 6;    //宝箱
--     optional int32 level = 7;    //节点等级（排行榜星星）
--     optional int32 curStyle = 8;    //当前风格
--     optional string refName = 9;    //引用名
--     repeated RedecorateWheel wheels = 10;    //转盘
--   }

function RedecorNodeData:parseData(_netData)
    self.p_nodeId = _netData.nodeId
    self.p_name = _netData.name
    self.p_material = _netData.material
    self.p_open = _netData.open
    self.p_complete = _netData.complete

    self.p_treasures = {}
    if _netData.treasures and #_netData.treasures > 0 then
        for i = 1, #_netData.treasures do
            local rData = RedecorSimpleTreasureData:create()
            rData:parseData(_netData.treasures[i])
            table.insert(self.p_treasures, rData)
        end
    end

    self.p_level = _netData.level
    self.p_curStyle = _netData.curStyle
    self.p_refName = _netData.refName

    self.p_wheels = {}
    if _netData.wheels and #_netData.wheels > 0 then
        for i = 1, #_netData.wheels do
            local wData = RedecorWheelData:create()
            wData:parseData(_netData.wheels[i])
            table.insert(self.p_wheels, wData)
        end
    end
end

-- 节点id
function RedecorNodeData:getNodeId()
    return self.p_nodeId
end
-- 名称
function RedecorNodeData:getName()
    return self.p_name
end
-- 需要的材料数量
function RedecorNodeData:getMaterial()
    return self.p_material
end
-- 是否开启
function RedecorNodeData:getOpen()
    return self.p_open
end
-- 是否完成
function RedecorNodeData:isComplete()
    return self.p_complete
end
-- 宝箱getTreasures
function RedecorNodeData:getTreasures()
    return self.p_treasures
end
-- 节点等级（排行榜星星）
function RedecorNodeData:getStar()
    return self.p_level
end
-- 当前风格
function RedecorNodeData:getCurStyle()
    return self.p_curStyle
end
-- 引用名
function RedecorNodeData:getRefName()
    return self.p_refName
end
-- 轮盘
function RedecorNodeData:getWheels()
    return self.p_wheels
end
----------------

-- 判断是否是清理
function RedecorNodeData:isClean()
    if self:getRefName() == "qingLi" then
        return true
    end
    return false
end

-- 轮盘
function RedecorNodeData:getWheelSectorNum()
    return #self.p_wheels
end

function RedecorNodeData:hasNormalReward(_hitIndexs, _cacheWheels)
    if _hitIndexs and #_hitIndexs > 0 then
        for i = 1, #_hitIndexs do
            local hitIdx = _hitIndexs[i]
            local wData = _cacheWheels[hitIdx]
            if not (wData:isGoldenReward() or wData:isEmptyReward()) then
                return true
            end
        end
    end
    return false
end

function RedecorNodeData:hasGoldenReward(_hitIndexs, _cacheWheels)
    if _hitIndexs and #_hitIndexs > 0 then
        for i = 1, #_hitIndexs do
            local hitIdx = _hitIndexs[i]
            local wData = _cacheWheels[hitIdx]
            if wData:isGoldenReward() then
                return true
            end
        end
    end
    return false
end

function RedecorNodeData:isAllEmptyReward(_hitIndexs, _cacheWheels)
    assert(_hitIndexs and #_hitIndexs > 0, "isAllEmptyReward _hitIndexs is wrong")
    local emptyNum = 0
    for i = 1, #_hitIndexs do
        local hitIdx = _hitIndexs[i]
        local wData = _cacheWheels[hitIdx]
        if wData:isEmptyReward() then
            emptyNum = emptyNum + 1
        end
    end
    return #_hitIndexs == emptyNum
end

return RedecorNodeData
