

local ChilliFiestaNode = class("ChilliFiestaNode",
                                    util_require("Levels.RespinNode"))

ChilliFiestaNode.m_animState = 1
local NODE_TAG = 10
local MOVE_SPEED = 2600     --滚动速度 像素/每秒
local RES_DIS = 20

--初始化子类可以重写
function ChilliFiestaNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end
function ChilliFiestaNode:checkRemoveNextNode()
    return true
end

function ChilliFiestaNode:initClipNode()
    local nodeHeight = self.m_slotReelHeight / self.m_machineRow
    self.m_clipNode= cc.ClippingRectangleNode:create({x= -math.ceil( self.m_slotNodeWidth / 2 ) , y= - nodeHeight / 2, width = self.m_slotNodeWidth, height = nodeHeight + 1 })
    self:addChild(self.m_clipNode)
end

function ChilliFiestaNode:setAnimaState(state)
    self.m_animState = state
end

function ChilliFiestaNode:changeNodeDisplay( node )
    if self.m_animState ~= 1 then
        self:changeInitNodeDisplay(node)
        return
    end
    if node and node.p_symbolType then
        if not self:isFixSymbol(node.p_symbolType) then
            node:runAnim("Dack")
        else
            node:runAnim("idleframe")
        end
    end
end
function ChilliFiestaNode:changeInitNodeDisplay( node )
    -- node:runAnim("Dack")
    node:setVisible(false)
end
function ChilliFiestaNode:isFixSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 or
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13 or
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 or
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 or
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 or
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 then
        return true
    end
    return false
end
return ChilliFiestaNode