--给bonus滚动使用的裁切节点
local PenguinsBoomsReelBigNode = class("PenguinsBoomsReelBigNode", util_require("Levels.BaseReel.BaseReelBigNode"))
--半个小块的高度
PenguinsBoomsReelBigNode.BigReelNodeOffsetHeight = 55

--裁切区域下方扩大一点
function PenguinsBoomsReelBigNode:createClipNode()
    PenguinsBoomsReelBigNode.super.createClipNode(self)

    self:updatePenguinsBoomsClipNodePosY(false)
    local newSize = CCSizeMake(self.m_clipSize.width * 1.2, self.m_clipSize.height + self.BigReelNodeOffsetHeight)
    self.m_clipNode:setContentSize(newSize)
end
--不升行时扩大底部裁切 升行时还原裁切到正常位置
function PenguinsBoomsReelBigNode:updatePenguinsBoomsClipNodePosY(_bUpRow)
    local curPosY = self.m_clipNode:getPositionY()
    local newPosY = _bUpRow and 0 or -self.BigReelNodeOffsetHeight
    local offsetY = newPosY - curPosY
    self.m_clipNode:setPositionY(newPosY)
    --子节点相反位置挪动
    local childs = self.m_clipNode:getChildren()
    for i,_node in ipairs(childs) do
        local nodePosY = _node:getPositionY() - offsetY
        _node:setPositionY(nodePosY)
    end
end

return PenguinsBoomsReelBigNode