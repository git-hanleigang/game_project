local BaseScroll = util_require "base.BaseScroll"
local CloverHatBonusMapLayer2 = class("CloverHatBonusMapLayer2", BaseScroll)

CloverHatBonusMapLayer2.AUTO_STOP_SPEED = 1    -- 惯性滑动停止速度
CloverHatBonusMapLayer2.AUTO_IN_MOVE = 10      -- 手势滑动开启平均值
CloverHatBonusMapLayer2.AUTO_FRICTIONE = 0.8  -- 摩擦力
CloverHatBonusMapLayer2.AUTO_MAX_SPEED = 40   -- 速度峰值
CloverHatBonusMapLayer2.DELTA_SPEED = 0.3    -- 惯性初速度系数

CloverHatBonusMapLayer2.BOUNDRAY_LEN = 0    -- 边缘回弹距离
-- 构造函数
function CloverHatBonusMapLayer2:initContent(node)
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

function CloverHatBonusMapLayer2:touchMoveLogic(touch, event)
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

function CloverHatBonusMapLayer2:setParent(parent)
    self.m_parent = parent
end

return CloverHatBonusMapLayer2