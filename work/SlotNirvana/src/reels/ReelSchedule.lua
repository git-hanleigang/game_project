--列滚动类
local ReelSchedule = class("ReelSchedule")
--状态
ReelSchedule.REEL_ILDE = 1 --待机中
ReelSchedule.REEL_BEFORE = 2 --准备滚动
ReelSchedule.REEL_RUNNING = 3 --滚动中
ReelSchedule.REEL_BACK = 4 --回弹中
ReelSchedule.REEL_DONE = 5 --完成滚动本列停止

ReelSchedule.m_state = ReelSchedule.REEL_ILDE --状态
--带子属性
ReelSchedule.m_currentDistance = nil --当前带子滚动距离
--基础滚动属性
ReelSchedule.m_reelBeginTime = nil --滚动前移动时间
ReelSchedule.m_reelTime = nil --滚动时间
ReelSchedule.m_longRunTime = nil --快滚时间
ReelSchedule.m_backTime = nil --回弹时间
ReelSchedule.m_quickDelayTime = nil --快停延时时间

ReelSchedule.m_beginDistance = nil --滚动前移动距离
ReelSchedule.m_moveDistance = nil --获得真实数据停止距离
ReelSchedule.m_backDistance = nil --回弹距离

ReelSchedule.m_reelMoveSpeed = nil --基础滚动速度
ReelSchedule.m_longRunMoveSpeed = nil --快滚速度

ReelSchedule.m_backType = nil --回弹类型
ReelSchedule.m_currentMoveSpeed = nil --当前滚动速度
ReelSchedule.m_isPerpareStop = nil --获得真实数据准备停止
ReelSchedule.m_isLongRun = nil --是否处于快滚中

ReelSchedule.m_configData = nil --滚动数据
function ReelSchedule:ctor()

end
--------------------初始化---------------------
function ReelSchedule:clearData()
    self.m_parentData = nil
    self.m_configData = nil
    self.m_quickDelayTime = nil
    self.m_reelMoveSpeed = nil
    self.m_backTime = nil
    self.m_backDistance = nil
    self.m_longRunMoveSpeed = nil
    self.m_longRunTime = nil
    self.m_reelBeginTime = nil
    self.m_beginDistance = nil
    self.m_backType = nil
    self.m_reelTime = nil 
    self.m_moveDistance = nil
    self.m_currentMoveSpeed = nil
    self.m_isPerpareStop = nil 
    self.m_isLongRun = nil 
end
--初始化滚动配置
function ReelSchedule:initData(parentData,configData)
    self.m_parentData = parentData
    self.m_configData = configData
    self.m_quickDelayTime = configData.p_quickStopDelayTime --快停延时时间
    self.m_reelMoveSpeed = configData.p_reelMoveSpeed --滚动速度
    self.m_backTime = configData.p_reelResTime --回弹时间
    self.m_backDistance = configData.p_reelResDis --回弹距离
    self.m_longRunMoveSpeed = configData.p_reelLongRunSpeed --快滚速度
    self.m_longRunTime = configData.p_reelLongRunTime -- 快滚时间
    self.m_reelBeginTime = configData.p_reelBeginJumpTime --点击spin向上跳的时间
    self.m_beginDistance = configData.p_reelBeginJumpHight --点击spin向上跳的高度

    self.m_backType = configData.p_reelResType --回弹类型 还没有实现
    self.m_reelTime = nil --滚动时间
    self.m_moveDistance = nil --获得真实数据停止距离

    self.m_maxMoveDis = 100 --每一帧滚动最大距离
    if parentData.reelHeight and parentData.rowNum then
        self.m_maxMoveDis = parentData.reelHeight/parentData.rowNum
    end
    self:resetReel()
end
--重置带子坐标
function ReelSchedule:resetReel()
    self.m_state = self.REEL_ILDE
    self.m_currentDistance = 0
end
--获得当前滚动距离
function ReelSchedule:getCurrentDistance()
    return self.m_currentDistance
end
--------------------状态---------------------
--设置状态
function ReelSchedule:setStatus(status)
    self.m_state = status
end
--返回状态
function ReelSchedule:getStatus()
    return self.m_state
end
--检测状态
function ReelSchedule:isReelDone()
    if self.m_state == self.REEL_DONE then
        return true
    else
        return false
    end
end
--------------------滚动---------------------
--准备滚动
function ReelSchedule:beginReelRun()
    --配置参数
    self.m_isPerpareStop = false --获得真实数据准备停止
    self.m_isLongRun = false --是否处于快滚中
    self.m_currentDistance = 0
    --调用滚动
    self:setStatus(self.REEL_RUNNING)
end
--准备停止
function ReelSchedule:beginReelStop(moveDistance)
    --配置参数
    self:reelMoveDistance(moveDistance)
end
--开始回弹
function ReelSchedule:beginReelBack()
    self:setStatus(self.REEL_BACK)
    self:reelBack()
end
--待机可以滚动状态
function ReelSchedule:reelIdle()
    self:setStatus(self.REEL_ILDE)
end
--设置距离快停 获得网络数据使用
function ReelSchedule:reelMoveDistance(moveDistance)
    self.m_isPerpareStop = true
    self.m_moveDistance = self.m_currentDistance+moveDistance
end
--快停
function ReelSchedule:quickStopDistance(moveDistance)
    self.m_moveDistance = self.m_moveDistance-moveDistance
end
--回弹函数
function ReelSchedule:reelBack()
    --回弹使用基类
    self:reelDone()
end
--本列停止
function ReelSchedule:reelDone()
    self:setStatus(self.REEL_DONE)
end
--刷新滚动
function ReelSchedule:updateReel(dt)
    if self.m_state ~= self.REEL_RUNNING then
        return
    end
    if not self.m_parentData.moveSpeed then
        self.m_parentData.moveSpeed = self.m_reelMoveSpeed
    end
    self.m_currentDistance = self.m_currentDistance + self:getMoveDis(dt)
    --是否进入最后一轮滚动
    if self.m_isPerpareStop then
        if self.m_currentDistance >= self.m_moveDistance then
            self.m_currentDistance = self.m_moveDistance
            self:beginReelBack()
            return
        end
    end
end
--刷新滚动
function ReelSchedule:getMoveDis(dt)
    local moveDis = dt * self.m_parentData.moveSpeed
    if moveDis>self.m_maxMoveDis then
        moveDis = self.m_maxMoveDis
    end
    return moveDis
end

return ReelSchedule
