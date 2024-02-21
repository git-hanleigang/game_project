--单个轴滚动
local BaseRunReel = class("BaseRunReel", cc.Node)
BaseRunReel.ACTION_READY = 1  --准备
BaseRunReel.ACTION_RUNNING = 2  --进行
BaseRunReel.ACTION_STOP = 3   --减速停止
BaseRunReel.ACTION_BACK = 4   --回弹
function BaseRunReel:ctor(node,moveFunc,overFunc)
    self.m_target = node
    self.m_moveFunc = moveFunc
    self.m_overFunc = overFunc
    self.m_status = self.ACTION_READY
    self.m_moveDistance = 0 --移动距离
    self.m_targetDistance = 0 --停止时的目标距离
    self.m_frameStep = 0 --帧率
    self:initReelConfig()
end

--初始化参数 可以重写
function BaseRunReel:initReelConfig()
    self.m_velocity = 0 --秒速度
    self.m_miniVelocity = 100 --秒速度
    self.m_maxVelocity = 2900 --秒速度
    self.m_velocityA = 1200 --加速度
    self.m_slowA = 0 --减速度 自动获取
end

--开始转动
function BaseRunReel:beginReel()
    local function update(dt)
        self:updateReel(dt)
    end
    self:onUpdate(update)
    self.m_status = self.ACTION_RUNNING
end

--开始停止滚动
function BaseRunReel:stopReel(targetDistance)
    self.m_targetDistance = targetDistance
    self.m_status = self.ACTION_STOP
    self.m_slowA = (self.m_velocity * self.m_velocity - self.m_miniVelocity * self.m_miniVelocity)/(2*targetDistance)
end

--刷新滚动
function BaseRunReel:updateReel(dt)
    self.m_frameStep = dt
    if self.m_status == self.ACTION_READY then
    elseif self.m_status == self.ACTION_RUNNING then
        self:runningReel()
    elseif self.m_status == self.ACTION_STOP then
        self:stoppingReel()
    elseif self.m_status == self.ACTION_BACK then
        
    end
end

--获取滚动距离
function BaseRunReel:getMoveDistance()
    return self.m_moveDistance
end

--滚动位移不同情况重写
function BaseRunReel:changePosition(value)
    self.m_moveDistance = self.m_moveDistance-value
    self.m_target:setPositionY(self.m_moveDistance)
    if self.m_moveFunc then
        self.m_moveFunc(self.m_moveDistance)
    end
end

--匀速滚动中
function BaseRunReel:runningReel()
    self.m_velocity = self.m_velocity + self.m_velocityA*self.m_frameStep
    if self.m_velocity>=self.m_maxVelocity then
        self.m_velocity = self.m_maxVelocity
    end
    local offsetValue = self.m_velocity*self.m_frameStep
    self:changePosition(offsetValue)
end

--开始减速停止
function BaseRunReel:stoppingReel()
    if self.m_targetDistance <=0 then
        return
    end
    self.m_velocity = self.m_velocity-self.m_slowA*self.m_frameStep
    if self.m_velocity<self.m_miniVelocity then
        self.m_velocity = self.m_miniVelocity
    end
    local offsetValue = self.m_velocity*self.m_frameStep
    if self.m_targetDistance-offsetValue>=0 then
        self.m_targetDistance = self.m_targetDistance - offsetValue
        self:changePosition(offsetValue)
    else
        self:changePosition(self.m_targetDistance)
        self.m_targetDistance = 0
    end
    if self.m_targetDistance <=0 then
        self:backReel()
    end
end

--回弹
function BaseRunReel:backReel()
    self.m_status = self.ACTION_BACK
    self:overReel()
end

--结束滚动
function BaseRunReel:overReel()
    if self.m_overFunc then
        self.m_overFunc()
    end
    self.m_status = self.ACTION_READY
    self:stopAllActions()
end

return BaseRunReel
