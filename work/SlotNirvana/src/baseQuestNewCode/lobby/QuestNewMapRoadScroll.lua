--
--滑动配置
--
local BaseScroll = util_require "base.BaseScroll"
local QuestNewMapRoadScroll = class("QuestNewMapRoadScroll", BaseScroll)
function QuestNewMapRoadScroll:initScroll()
    self.BOUNDRAY_LEN = 0 --回弹距离
    -- self.AUTO_FRICTIONE = 0.5  -- 摩擦力
    self.AUTO_MAX_SPEED = 40 -- 速度峰值
    self.DELTA_SPEED = 0.6 -- 惯性初速度系数

    self.m_canMove = false
end

-- 禁止移动
function QuestNewMapRoadScroll:setMoveState(canMove)
    self.m_canMove = canMove
end

function QuestNewMapRoadScroll:startMove(_moveX)
    self:move(_moveX)
end

function QuestNewMapRoadScroll:move(x)
    BaseScroll.move(self, x)
end

function QuestNewMapRoadScroll:isGuide()
    return false
end

function QuestNewMapRoadScroll:touchBeginLogic(touch, event)
    if not self.m_canMove then
        return
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isInGuide() then
        return
    end
    BaseScroll.touchBeginLogic(self, touch, event)
end

function QuestNewMapRoadScroll:touchMoveLogic(touch, event)
    if not self.m_canMove then
        return
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isInGuide() then
        return
    end
    BaseScroll.touchMoveLogic(self, touch, event)
end

function QuestNewMapRoadScroll:toucEndLogic(touch, event)
    if not self.m_canMove then
        return
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isInGuide() then
        return
    end
    BaseScroll.toucEndLogic(self, touch, event)
end

return QuestNewMapRoadScroll
-- endregion
