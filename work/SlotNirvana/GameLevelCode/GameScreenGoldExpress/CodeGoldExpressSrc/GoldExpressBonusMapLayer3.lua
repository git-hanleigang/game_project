local BaseScroll = util_require "base.BaseScroll"
local GoldExpressBonusMapLayer3 = class("GoldExpressBonusMapLayer3", BaseScroll)
-- 构造函数
GoldExpressBonusMapLayer3.AUTO_STOP_SPEED = 0.5    -- 惯性滑动停止速度
GoldExpressBonusMapLayer3.AUTO_IN_MOVE = 5      -- 手势滑动开启平均值
GoldExpressBonusMapLayer3.AUTO_FRICTIONE = 0.9  -- 摩擦力
GoldExpressBonusMapLayer3.AUTO_MAX_SPEED = 20   -- 速度峰值
GoldExpressBonusMapLayer3.DELTA_SPEED = 0.1    -- 惯性初速度系数

GoldExpressBonusMapLayer3.BOUNDRAY_LEN = 0    -- 边缘回弹距离
-- 构造函数
function GoldExpressBonusMapLayer3:initContent(node)
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

function GoldExpressBonusMapLayer3:touchMoveLogic(touch, event)
    local delta = touch:getDelta()
    local target = event:getCurrentTarget()
    local posX, posY = target:getPosition()
    local touchBeginPosition = posX
    local touchMovePosition = (delta.x * self:getBoundaryFactor(delta.x)) * 0.3
    local newPosition = touchMovePosition + touchBeginPosition
    local locationInNode = target:convertToWorldSpace(touch:getLocation())
    self:move(newPosition)
    self:pushMoveDelta(touchMovePosition)
end

function GoldExpressBonusMapLayer3:setParent(parent)
    self.m_parent = parent
end

return GoldExpressBonusMapLayer3