---
--xcyy
--2018年5月23日
--FrozenJewelryReelControl.lua

local FrozenJewelryReelControl = class("FrozenJewelryReelControl",util_require("reels.ReelControl"))

--检测停止距离
function FrozenJewelryReelControl:checkNormalStopReel()
    if self.m_reelRunInfo then
        if not self.m_reelSchedule:isReelDone() then
            self.m_reelSchedule:reelDone()
            self:resetQuickStopReel(self.m_reelRunInfo)
            self.m_reelRunInfo = nil
            return
        else
            self.m_reelRunInfo = nil
        end
    end
    --正常停止
    if self.m_isPerpareStop then
        self.m_isPerpareStop = nil
        self.m_isNetWorkData = true
        local offDistance = self.m_currentDistance-self.m_lastDistance
        local moveDistance
        if self.m_machine.m_isDoubleReel and self.m_iColIndex == 3 then
            moveDistance = (self.m_stopReelCount - self.m_columnData.p_showGridCount + self.m_configData.p_rowNum + 1)* self.m_gridH
        else
            moveDistance = (self.m_stopReelCount-self.m_columnData.p_showGridCount+self.m_gridCount)* self.m_gridH
        end
        
        local targetDistance = moveDistance - offDistance
        self.m_reelSchedule:reelMoveDistance(targetDistance)
    end
end

--刷新小块坐标
function FrozenJewelryReelControl:updateGrid()
    self:checkNormalStopReel()
    if self.m_currentDistance-self.m_lastDistance>=self.m_gridH then
        --刷新信号
        self.m_lastDistance = self.m_lastDistance+self.m_gridH
        local gridNode = self.m_gridList:pop() --挪动中信号
        local list,start,over = self.m_gridList:getList()
        local lastNode = list[over] --顶部信号
        local firstNode = list[start] --底部信号
        --节点在关卡中被移除了、
        if tolua.isnull(gridNode) or not gridNode or not gridNode.updateGrid then
            return
        end
        gridNode.p_cloumnIndex = self.m_iColIndex
        -- local index,pos,count = lastNode:getBigSymbolInfo()
        self:updateNextData()
        -- if not self.m_parentData.m_isLastSymbol then
        --     if index and index ~= count then
        --         --补齐大信号
        --         self.m_parentData.symbolType = lastNode.p_symbolType
        --     end
        -- end
        gridNode:updateGrid()
        -- --大信号检测
        -- local symbolCount = self.m_bigSymbolInfos[gridNode.p_symbolType]
        -- if symbolCount then
        --     --大信号
        --     if gridNode.p_symbolType == lastNode.p_symbolType then
        --         local index,pos,count = lastNode:getBigSymbolInfo()
        --         if index and index ~= symbolCount then
        --             --非首个延续上一个参数+1
        --             gridNode:updateBigSymbolInfo(index+1,pos-self.m_gridH,symbolCount)
        --             gridNode:setVisible(false)
        --         else
        --             --已满开新的大图
        --             gridNode:updateBigSymbolInfo(1,0,symbolCount)
        --         end
        --     else
        --         --新的大图
        --         gridNode:updateBigSymbolInfo(1,0,symbolCount)
        --     end
        -- end
        if self.m_updateGridFunc then
            self.m_updateGridFunc(gridNode)
        end

        if self.m_checkAddSignFunc then
            self.m_checkAddSignFunc(gridNode)
        end
        gridNode:setOriginalDistance(gridNode:getOriginalDistance()+self.m_gridLen)
        gridNode:updateDistance(self.m_currentDistance)
        self.m_gridList:push(gridNode)
        -- --底部大信号显示检测
        -- if firstNode.m_bigSymbolIndex then
        --     firstNode:setVisible(true)
        -- end
        --快停和下一个信号检测
        if self.m_currentDistance-self.m_lastDistance>=self.m_gridH then
            return self:updateGrid()
        end
    end
end

return FrozenJewelryReelControl