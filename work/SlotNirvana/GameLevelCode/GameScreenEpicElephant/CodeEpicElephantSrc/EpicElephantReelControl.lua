---
--xcyy
--2018年5月23日
--EpicElephantReelControl.lua

local EpicElephantReelControl = class("EpicElephantReelControl",util_require("reels.ReelControl"))

--刷新滚动
function EpicElephantReelControl:updateReel(dt)
    if self.m_isReelDone then
        return
    end
    
    self.m_reelSchedule:updateReel(dt)
    self.m_currentDistance = self.m_reelSchedule:getCurrentDistance()
    local list,start,over = self.m_gridList:getList()
    for i =start,over do
        local gridNode = list[i]
        if gridNode and gridNode.updateDistance then
            -- 信号值低于90的滚动的时候 透明度修改
            if gridNode.p_symbolType < 90 then
                util_setChildNodeOpacity(gridNode, 150)
            else
                util_setChildNodeOpacity(gridNode, 255)
            end
            gridNode:updateDistance(self.m_currentDistance)
        end
    end
    self:updateGrid()
    if self.m_reelSchedule:isReelDone() then
        self.m_isReelDone = true
        if self.m_doneFunc then
            self.m_doneFunc(self.m_parentData)
        end
    end
end

return EpicElephantReelControl