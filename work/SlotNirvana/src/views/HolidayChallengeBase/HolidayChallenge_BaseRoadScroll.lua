--
--滑动配置
--
local BaseScroll = util_require "base.BaseScroll"
local HolidayChallenge_BaseRoadScroll = class("HolidayChallenge_BaseRoadScroll", BaseScroll)
function HolidayChallenge_BaseRoadScroll:initScroll()
    self.BOUNDRAY_LEN = 0 --回弹距离
    -- self.AUTO_FRICTIONE = 0.5  -- 摩擦力
    self.AUTO_MAX_SPEED = 40 -- 速度峰值
    self.DELTA_SPEED = 0.2 -- 惯性初速度系数

    self.m_canMove = true
end

-- 禁止移动
function HolidayChallenge_BaseRoadScroll:setMoveState(canMove)
    self.m_canMove = canMove
end

function HolidayChallenge_BaseRoadScroll:startMove(_moveX)
    self:move(_moveX)
end

function HolidayChallenge_BaseRoadScroll:move(x)
    BaseScroll.move(self, x)
end

function HolidayChallenge_BaseRoadScroll:isGuide()
    return false
end

function HolidayChallenge_BaseRoadScroll:touchBeginLogic(touch, event)
    if not self.m_canMove then
        return
    end
    BaseScroll.touchBeginLogic(self, touch, event)
end

function HolidayChallenge_BaseRoadScroll:touchMoveLogic(touch, event)
    if not self.m_canMove then
        return
    end
    BaseScroll.touchMoveLogic(self, touch, event)
end

function HolidayChallenge_BaseRoadScroll:toucEndLogic(touch, event)
    if not self.m_canMove then
        return
    end
    BaseScroll.toucEndLogic(self, touch, event)
end

return HolidayChallenge_BaseRoadScroll
-- endregion
