local BaseScroll = util_require "base.BaseScroll"
local GoldExpressBonusMapLayer1 = class("GoldExpressBonusMapLayer1", BaseScroll)

GoldExpressBonusMapLayer1.BOUNDRAY_LEN = 0    -- 边缘回弹距离
-- 构造函数
function GoldExpressBonusMapLayer1:initContent(node)
    self.m_content = node
    local function onTouchBegan(touch, event)
        if self.m_parent:getMapCanTouch() == false then
            return false
        end
        self:touchBeginLogic(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        self:toucEndLogic(touch, event)
    end
    local function onTouchCancelled(touch, event)
        self:toucEndLogic(touch, event)
    end
    local function onTouchMoved(touch, event)
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

function GoldExpressBonusMapLayer1:move(x)

    if x ~= nil then
        self.contentPosition_x = x
    end

    --边缘弹动
    if self:isBoundary() then
        self:stopAutoScroll()
        self.m_parent:setMoveStop(true)
    else
        self.m_parent:setMoveStop(false)
    end

    self.m_content:setPosition(self.contentPosition_x, self.m_startPos.y)
    if self.m_moveFunc then
        self.m_moveFunc(self.contentPosition_x)
    end
end

function GoldExpressBonusMapLayer1:setParent(parent)
    self.m_parent = parent
end

return GoldExpressBonusMapLayer1