--
--滑动配置
--
local BaseScroll = util_require "base.BaseScroll"
local HolidayChallenge_BaseBuildingScroll = class("HolidayChallenge_BaseBuildingScroll", BaseScroll)
function HolidayChallenge_BaseBuildingScroll:initScroll()
    self.BOUNDRAY_LEN = 0 --回弹距离
    self.AUTO_FRICTIONE = 0.5 -- 摩擦力
    self.AUTO_MAX_SPEED = 40 -- 速度峰值
    self.DELTA_SPEED = 0.2 -- 惯性初速度系数

    self.m_canMove = true
end

function HolidayChallenge_BaseBuildingScroll:setFriction(_num)
    self.AUTO_FRICTIONE = _num -- 摩擦力
end

-- 禁止移动
function HolidayChallenge_BaseBuildingScroll:setMoveState(canMove)
    self.m_canMove = canMove
end

function HolidayChallenge_BaseBuildingScroll:isBoundary()
    if self.contentPosition_x <= self.m_moveLen - self.BOUNDRAY_LEN then
        self.contentPosition_x = self.m_moveLen - self.BOUNDRAY_LEN
        return true
    elseif self.contentPosition_x >= 0 then
        if self.m_isSpecialMode then
            self.contentPosition_x = 0
            return true
        end
        if self.contentPosition_x >= 0 + self.BOUNDRAY_LEN then
            self.contentPosition_x = 0 + self.BOUNDRAY_LEN
            return true
        end
    end
end

function HolidayChallenge_BaseBuildingScroll:startMove(_moveX)
    -- 普通的move 需要摩擦系数
    _moveX = _moveX * self:getBoundaryFactor(_moveX) * self.AUTO_FRICTIONE
    self:move(_moveX)
end

-- 复写的父类方法
function HolidayChallenge_BaseBuildingScroll:move(x)
    BaseScroll.move(self, x)
end

function HolidayChallenge_BaseBuildingScroll:isGuide()
    return false
end

function HolidayChallenge_BaseBuildingScroll:touchBeginLogic(touch, event)
    if not self.m_canMove then
        return
    end
    BaseScroll.touchBeginLogic(self, touch, event)
end

function HolidayChallenge_BaseBuildingScroll:touchMoveLogic(touch, event)
    if not self.m_canMove then
        return
    end
    local delta = touch:getDelta()
    local target = event:getCurrentTarget()
    local posX, posY = target:getPosition()
    local touchBeginPosition = posX
    local touchMovePosition = (delta.x * self:getBoundaryFactor(delta.x)) * self.AUTO_FRICTIONE
    local newPosition = touchMovePosition + touchBeginPosition
    local locationInNode = target:convertToWorldSpace(touch:getLocation())
    self:move(newPosition)
    self:pushMoveDelta(touchMovePosition)
end

function HolidayChallenge_BaseBuildingScroll:toucEndLogic(touch, event)
    if not self.m_canMove then
        return
    end
    BaseScroll.toucEndLogic(self, touch, event)
end

return HolidayChallenge_BaseBuildingScroll
-- endregion
