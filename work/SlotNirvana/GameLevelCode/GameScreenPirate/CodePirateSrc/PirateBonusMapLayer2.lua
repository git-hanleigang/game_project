local BaseScroll = util_require "base.BaseScroll"
local Pirate = class("Pirate", BaseScroll)

Pirate.AUTO_STOP_SPEED = 1    -- 惯性滑动停止速度
Pirate.AUTO_IN_MOVE = 10      -- 手势滑动开启平均值
Pirate.AUTO_FRICTIONE = 0.8  -- 摩擦力
Pirate.AUTO_MAX_SPEED = 40   -- 速度峰值
Pirate.DELTA_SPEED = 0.3    -- 惯性初速度系数

Pirate.BOUNDRAY_LEN = 0    -- 边缘回弹距离
-- 构造函数
function Pirate:initContent(node)
    self.m_content = node
    local function onTouchBegan(touch, event)
        if self.m_parent:getMapCanTouch() == false then
            return false
        end
        self:touchBeginLogic(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        if self.m_parent:getMoveStop() == true then
            return
        end
        self:toucEndLogic(touch, event)
    end
    local function onTouchCancelled(touch, event)
        if self.m_parent:getMoveStop() == true then
            return
        end
        self:toucEndLogic(touch, event)
    end
    local function onTouchMoved(touch, event)
        if self.m_parent:getMoveStop() == true then
            return
        end
        self:touchMoveLogic(touch, event)
    end

    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(false)
    listener1:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener1:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listener1:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    listener1:registerScriptHandler(onTouchCancelled, cc.Handler.EVENT_TOUCH_CANCELLED)
    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, node)
    node:onUpdate(handler(self, self.update))
end

function Pirate:touchMoveLogic(touch, event)
    local delta = touch:getDelta()
    local target = event:getCurrentTarget()
    local posX, posY = target:getPosition()
    local touchBeginPosition = posX
    local touchMovePosition = (delta.x * self:getBoundaryFactor(delta.x)) * 0.6
    local newPosition = touchMovePosition + touchBeginPosition
    local locationInNode = target:convertToWorldSpace(touch:getLocation())
    self:move(newPosition)
    self:pushMoveDelta(touchMovePosition)
end

function Pirate:setParent(parent)
    self.m_parent = parent
end

return Pirate