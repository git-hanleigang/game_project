

local ChilliFiestaNode = class("ChilliFiestaNode",
                                    util_require("Levels.RespinNode"))
ChilliFiestaNode.m_animState = 1
function ChilliFiestaNode:setMachine( machine )
    self.m_machine = machine
end
function ChilliFiestaNode:initClipNode()
    local nodeHeight = self.m_slotReelHeight / self.m_machineRow
    self.m_clipNode= cc.ClippingRectangleNode:create({x= -math.ceil( self.m_slotNodeWidth / 2 ) , y= - nodeHeight / 2, width = self.m_slotNodeWidth, height = nodeHeight + 1 })
    self:addChild(self.m_clipNode)
end
function ChilliFiestaNode:checkRemoveNextNode()
    return true
end

function ChilliFiestaNode:setAnimaState(state)
    self.m_animState = state
end
function ChilliFiestaNode:changeInitNodeDisplay( node )
    -- node:runAnim("Dack")
    node:setVisible(false)
end
function ChilliFiestaNode:changeNodeDisplay( node )
    if self.m_animState ~= 1 then
        self:changeInitNodeDisplay(node)
        return
    end
    if node and node.p_symbolType then
        if not self.m_machine:isFixSymbol(node.p_symbolType) then
            node:runAnim("Dack")
        else
            node:runAnim("idleframe")
        end
    end
end

function ChilliFiestaNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = self.m_machine.m_configData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = self.m_machine.m_configData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return ChilliFiestaNode