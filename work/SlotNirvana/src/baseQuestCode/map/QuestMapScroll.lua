--
--滑动配置
--
local BaseScroll = util_require "base.BaseScroll"
local QuestMapScroll = class("QuestMapScroll", BaseScroll)
function QuestMapScroll:initScroll()
    self.BOUNDRAY_LEN = 0 --回弹距离
    self.AUTO_FRICTIONE = 0.7 -- 摩擦力
    self.AUTO_MAX_SPEED = 40 -- 速度峰值
    self.DELTA_SPEED = 0.2 -- 惯性初速度系数

    self.m_canMove = true
end
--迷雾模式
function QuestMapScroll:openSpecialMode()
    self.m_isSpecialMode = true
    self.BOUNDRAY_LEN = 300
end

-- 禁止移动
function QuestMapScroll:setMoveState(canMove)
    self.m_canMove = true
end

function QuestMapScroll:isBoundary()
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

function QuestMapScroll:move(x)
    if not self.m_canMove then
        return
    end
    BaseScroll.move(self, x)
end

return QuestMapScroll
