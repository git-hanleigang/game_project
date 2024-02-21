
local RespinNode = util_require("Levels.RespinNode")
local PussNode = class("PussNode",RespinNode)

function PussNode:checkRemoveNextNode()
    return true
end
--子类继承修正裁框坐标
function PussNode:changeNodePos()
    local list = {
        2,
        1,
        1,
        0,
        -0.5,
        -1.5,
        -1.5
    }
    local posY = list[self.p_rowIndex]
    self.m_clipNode:setPosition(0,posY)
end
function PussNode:initClipNode(clipNode,opacity)
    if not clipNode then
          local nodeHeight = self.m_slotReelHeight / self.m_machineRow
          local size = cc.size(self.m_slotNodeWidth,nodeHeight-1)
          local pos = cc.p(-math.ceil( self.m_slotNodeWidth / 2 ),- nodeHeight / 2)
          self.m_clipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,pos)
          self:addChild(self.m_clipNode)
          --设置裁切块属性
          local originalPos = cc.p(0,0)
          util_setClipNodeInfo(self.m_clipNode,RESPIN_CLIPTYPE.SINGLE,RESPIN_CLIPMODE.RECT,size,originalPos)
    else
          self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity)
end
return PussNode