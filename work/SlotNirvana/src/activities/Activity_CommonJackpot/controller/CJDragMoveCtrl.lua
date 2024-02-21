--[[
]]
local CJDragMoveCtrl = class("CJDragMoveCtrl", BaseSingleton)

function CJDragMoveCtrl:setParentNode(_parentNode, _dragSize)
    self.m_parentNode = _parentNode
    self.m_dragSize = _dragSize
end

function CJDragMoveCtrl:createDragLayer()
    assert(self.m_parentNode, "设置拖拽的父节点")
    assert(self.m_dragSize, "设置拖拽区域尺寸")
    self.m_dragLayer = cc.LayerColor:create(cc.c3b(250, 0, 0))
    self.m_dragLayer:setContentSize(cc.size(self.m_dragSize.width, self.m_dragSize.height))
    self.m_dragLayer:setOpacity(0)
    self.m_dragLayer:ignoreAnchorPointForPosition(false)
    self.m_dragLayer:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_dragLayer:setPosition(cc.p(0, 0))
    self.m_parentNode:addChild(self.m_dragLayer)

    local rect = {
        x = -self.m_dragSize.width / 2,
        y = -self.m_dragSize.height / 2,
        width = self.m_dragSize.width,
        height = self.m_dragSize.height
    }
    local beganPosition, dispos
    self.m_dragLayer:onTouch(
        function(event)
            if event.name == "began" then
                beganPosition = cc.p(event.x, event.y)
                local parentPos = cc.p(self.m_parentNode:getPosition())
                dispos = cc.pSub(beganPosition, parentPos)
                if cc.rectContainsPoint(rect, dispos) == false then
                    return false
                end
                return true
            elseif event.name == "moved" then
                local movePosition = cc.p(event.x, event.y)
                local newPos = cc.pSub(movePosition, dispos)
                self.m_parentNode:setPosition(newPos)
            elseif event.name == "ended" then
                local endPosition = cc.p(event.x, event.y)
                local newPos = cc.pSub(endPosition, dispos)
                self:updatePosition()
            end
            return true
        end,
        false,
        false
    )
end

function CJDragMoveCtrl:updatePosition()
    local offsetX = 10
    local offsetY = 20
    local curPos = cc.p(self.m_parentNode:getPosition())
    -- 计算x y
    local endPosX = display.width - self.m_dragSize.width / 2 - offsetX
    local endPosY = curPos.y
    -- 判断上下 是否超过规定界限
    local limitHeight_top = globalData.gameRealViewsSize.topUIHeight
    local limitHeight_bottom = globalData.gameRealViewsSize.bottomUIHeight
    local maxY = display.height - limitHeight_top - self.m_dragSize.height / 2
    local minY = limitHeight_bottom + self.m_dragSize.height / 2 + offsetY
    if curPos.y > maxY then
        endPosY = maxY
    elseif curPos.y < minY then
        endPosY = minY
    end
    -- 动作
    local endPos = cc.p(endPosX, endPosY)
    local moveTo = cc.MoveTo:create(0.2, endPos)
    self.m_parentNode:runAction(moveTo)
end

return CJDragMoveCtrl
