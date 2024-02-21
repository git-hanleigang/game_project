local BaseScroll = util_require "base.BaseScroll"
local ClawStallMapLayer = class("ClawStallMapLayer", BaseScroll)
-- 构造函数
ClawStallMapLayer.AUTO_STOP_SPEED = 0.5    -- 惯性滑动停止速度
ClawStallMapLayer.AUTO_IN_MOVE = 5      -- 手势滑动开启平均值
ClawStallMapLayer.AUTO_FRICTIONE = 0.9  -- 摩擦力
ClawStallMapLayer.AUTO_MAX_SPEED = 20   -- 速度峰值
ClawStallMapLayer.DELTA_SPEED = 0.1    -- 惯性初速度系数

ClawStallMapLayer.BOUNDRAY_LEN = 0    -- 边缘回弹距离

function ClawStallMapLayer:ctor()
    ClawStallMapLayer.super.ctor(self)
    self.m_isTouchMoveEnabled = true
end
-- 构造函数
function ClawStallMapLayer:initContent(node)
    self.m_content = node
    local function onTouchBegan(touch, event)
        if not self.m_isTouchMoveEnabled then
            return false
        end
        self:touchBeginLogic(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        if not self.m_isTouchMoveEnabled then
            return false
        end
        self:toucEndLogic(touch, event)
    end
    local function onTouchCancelled(touch, event)
        if not self.m_isTouchMoveEnabled then
            return false
        end
        self:toucEndLogic(touch, event)
    end
    local function onTouchMoved(touch, event)
        if not self.m_isTouchMoveEnabled then
            return false
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

--[[
    设置是否可滑动
]]
function ClawStallMapLayer:setMoveEnabled(isEnabled)
    self.m_isTouchMoveEnabled = isEnabled
end

return ClawStallMapLayer