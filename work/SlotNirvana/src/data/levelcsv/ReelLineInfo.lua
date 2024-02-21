---
--island
--2017年8月26日
--ReelLineInfo.lua
--

local ReelLineInfo = class("ReelLineInfo")

ReelLineInfo.enumSymbolType = nil
ReelLineInfo.enumSymbolEffectType = nil
ReelLineInfo.iLineIdx = nil
ReelLineInfo.iLineSymbolNum = nil
ReelLineInfo.iLineMulti = nil
ReelLineInfo.vecSymbolPos = nil --存入所有线上信号坐标用于画线
ReelLineInfo.vecValidMatrixSymPos = nil --放入以上vecSymbolPos中有效symbol pos
ReelLineInfo.iLineSelfMulti = nil -- 为单条线增加倍数新添的变量

-- 构造函数
function ReelLineInfo:ctor()
    
    self.enumSymbolEffectType = 0 --EFFECT_IDLE
    self.iLineIdx = 0
    self.iLineSymbolNum = 0
--    self.vecSymbolPos = {}
    self.iLineMulti = 1
    self.iLineSelfMulti = 1
    self.vecValidMatrixSymPos = {}
end


---
-- @param lineInfo ReelLineInfo 比较的数据对象
function ReelLineInfo:isEqual(lineInfo)
    
    if enumSymbolType == _linlineInfoeInfo.enumSymbolType              and
           enumSymbolEffectType == lineInfo.enumSymbolEffectType  and
           iLineIdx     == lineInfo.iLineIdx                     and
           iLineMulti   == lineInfo.iLineMulti                    and
           self:PointIsEqual(lineInfo.vecSymbolPos)                    and
           self:POSIsEqual(lineInfo.vecValidMatrixSymPos) then
    
        return true
    end
    
    return false
    
end

---
-- 处理存储了 CCPoint 的数组是否相等
-- @param _point vector ,
function ReelLineInfo:PointIsEqual(_point)
    
--    local symPosLen = table_length(self.vecSymbolPos)
--    local pointSize = table_length(_point)
--    
--    if symPosLen ~= pointSize then
--        return false
--    elseif symPosLen == 0 then -- 两个都相同
--        return true
--    else
--        
--        for i = 1, symPosLen , 1 do
--            
--            local symValue = self.vecSymbolPos[i]
--            local pointValue = _point[i]
--            if symValue.x ~= pointValue.x or symValue.y ~= pointValue.y then
--            	return false
--            end
--        end
--        
--        return true
--    end
    return true
end

---
-- @param _point vector
function ReelLineInfo:POSIsEqual_MatrixPos(_point)
    local symPosLen = #self.vecValidMatrixSymPos
    local pointSize = #_point
    
    if symPosLen ~= pointSize then
        return false
    elseif symPosLen == 0 then -- 两个都相同
        return true
    else
        
        for i = 1, symPosLen , 1 do
            local validMatrixValue = self.vecValidMatrixSymPos[i]
            local pointValue = _point[i]
            
            if validMatrixValue:isEqual(pointValue) == false then
            	return false
            end
            
        end
        
        return true
    end
    
end

---
--
function ReelLineInfo:clone()
    local lineInfo = ReelLineInfo.new()
    
    lineInfo.enumSymbolType = self.enumSymbolType
    lineInfo.enumSymbolEffectType = self.enumSymbolEffectType
    lineInfo.iLineIdx = self.iLineIdx
    lineInfo.iLineSymbolNum = self.iLineSymbolNum
    lineInfo.iLineMulti = self.iLineMulti
    lineInfo.iLineSelfMulti = self.iLineSelfMulti
    
    local matrixPosLen = #self.vecValidMatrixSymPos
    for i=1,matrixPosLen do
        
        local value = self.vecValidMatrixSymPos[i]

        table.insert(lineInfo.vecValidMatrixSymPos,{iX = value.iX,iY = value.iY})
    end

    return lineInfo
end

function ReelLineInfo:clean()

    self.enumSymbolType = nil
    self.enumSymbolEffectType = 0
    self.iLineIdx = 0
    self.iLineSymbolNum = 0
    self.iLineMulti = 1
    self.iLineSelfMulti = 1
    self.vecSymbolPos = nil -- 这个以后我会废弃掉它
    if self.vecValidMatrixSymPos ~= nil and #self.vecValidMatrixSymPos > 0 then
        
        for i= #self.vecValidMatrixSymPos, 1,-1 do
            self.vecValidMatrixSymPos[i] = nil
        end
    end
    
end



return ReelLineInfo