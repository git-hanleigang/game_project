--
--滑动基类 上下滑动 最大值是0就是起始点  最小值setMoveLen必须设置否则不能滑动
--
local PelicanBaseScroll = class("PelicanBaseScroll")

PelicanBaseScroll.AUTO_STOP_SPEED = 2 -- 惯性滑动停止速度
PelicanBaseScroll.AUTO_IN_MOVE = 20 -- 手势滑动开启平均值
PelicanBaseScroll.AUTO_FRICTIONE = 0.6 -- 摩擦力
PelicanBaseScroll.AUTO_MAX_SPEED = 70 -- 速度峰值
PelicanBaseScroll.DELTA_SPEED = 0.5 -- 惯性初速度系数

PelicanBaseScroll.BOUNDRAY_MOVE = 100 -- 边缘回弹检测
PelicanBaseScroll.BOUNDRAY_LEN = 500 -- 边缘回弹距离
PelicanBaseScroll.BOUNDRAY_TIME = 0.1 -- 边缘回弹时间

PelicanBaseScroll.contentPosition_y = nil
PelicanBaseScroll.isAuto = nil
PelicanBaseScroll.autoSpeed = nil
PelicanBaseScroll.moveList = nil
PelicanBaseScroll.moveIndex = nil
PelicanBaseScroll.m_moveFunc = nil
PelicanBaseScroll.m_moveLen = nil

require("socket")
local DELTA_TIME = 0.4 -- 滑动响应时间
PelicanBaseScroll.m_startTime = nil
function PelicanBaseScroll:ctor()
    self.contentPosition_y = 0
    self.m_moveLen = 0
    self:stopAutoScroll()
end

--需要滑动的node 起始坐标 滑动回调
function PelicanBaseScroll:initData_(node, startPos, func)
    self.m_startPos = startPos
    self.m_moveFunc = func

    self:initContent(node)

    self.contentPosition_y = self.m_startPos.y
    self.m_content:setPosition(self.m_startPos.x,self.contentPosition_y)
    
    
    self:initScroll()
end

--子类初始化
function PelicanBaseScroll:initScroll()
end

--可向右活动的区域负数 必须设置 例如可滑动500的距离就设置-500
function PelicanBaseScroll:setMoveLen(len, isChangeMover)
    self.m_moveLen = len
    if isChangeMover then
        self:startBoundary()
    end
end

function PelicanBaseScroll:getMoveLen()
    return self.m_moveLen
end

function PelicanBaseScroll:startAutoScroll(delta)
    self.isAuto = true
    self.autoSpeed = delta * self.DELTA_SPEED
end

function PelicanBaseScroll:stopAutoScroll()
    self.isAuto = false
    self.autoSpeed = 0
    self.moveList = {0, 0, 0, 0, 0, 0}
    self.moveIndex = 1
    self.m_startTime = 0
end

function PelicanBaseScroll:initContent(node)
    self.m_content = node
    local function onTouchBegan(touch, event)
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

function PelicanBaseScroll:getPosition()
    return self.m_content:getPosition()
end

function PelicanBaseScroll:touchBeginLogic(touch, event)
    self:stopAutoScroll()
    self.m_startTime = socket.gettime()
end

function PelicanBaseScroll:touchMoveLogic(touch, event)
    local delta = touch:getDelta()
    local target = event:getCurrentTarget()
    local posX, posY = target:getPosition()
    local touchBeginPosition = posY
    local touchMovePosition = delta.y * self:getBoundaryFactor(delta.y)
    local newPosition = touchMovePosition + touchBeginPosition
    local locationInNode = target:convertToWorldSpace(touch:getLocation())
    self:move(newPosition)
    self:pushMoveDelta(touchMovePosition)
end

function PelicanBaseScroll:toucEndLogic(touch, event)
    local spanTime = socket.gettime() - self.m_startTime
    local delta = self:getMoveDelta()
    if math.abs(delta) > self.AUTO_IN_MOVE and spanTime < DELTA_TIME then
        self:startAutoScroll(delta)
    else
        self:stopAutoScroll()
    end
    self:startBoundary()
end

function PelicanBaseScroll:pushMoveDelta(delta)
    self.moveList[self.moveIndex] = delta
    self.moveIndex = self.moveIndex + 1
    if self.moveIndex > 6 then
        self.moveIndex = 1
    end
end

function PelicanBaseScroll:getMoveDelta()
    local delta = 0
    for i = 1, 6 do
        delta = delta + self.moveList[i]
    end
    return delta
end

-- function PelicanBaseScroll:getBoundaryFactor(autoSpeed)
--     return 1
-- end

function PelicanBaseScroll:update(dt)
    if not dt then
        return
    end
    if self.isAuto then
        if math.abs(self.autoSpeed) <= self.AUTO_STOP_SPEED or self:isMoveBoundary() then
            self:stopAutoScroll()
            self:startBoundary()
            return
        end
        self.autoSpeed = self.autoSpeed - self.autoSpeed * self.AUTO_FRICTIONE * 0.1 * dt * 60
        if self.autoSpeed > self.AUTO_MAX_SPEED then
            self:move(self.contentPosition_y + self.AUTO_MAX_SPEED * self:getBoundaryFactor(self.autoSpeed))
        elseif self.autoSpeed < -self.AUTO_MAX_SPEED then
            self:move(self.contentPosition_y - self.AUTO_MAX_SPEED * self:getBoundaryFactor(self.autoSpeed))
        else
            self:move(self.contentPosition_y + self.autoSpeed * self:getBoundaryFactor(self.autoSpeed))
        end
        if self:isBoundary() then
            self:startBoundary()
        end
    end
end

function PelicanBaseScroll:move(y, secs)
    secs = secs or 0

    if y ~= nil then
        self.contentPosition_y = y
    end

    --边缘弹动
    if self:isBoundary() then
        self:stopAutoScroll()
    end


    if secs > 0 then
        self.m_content:runAction(cc.MoveTo:create(secs, cc.p(self.m_startPos.x,self.contentPosition_y)))
    else
        self.m_content:setPosition(self.m_startPos.x, self.contentPosition_y)
    end

    
    if self.m_moveFunc then
        self.m_moveFunc(self.contentPosition_y)
    end
end
--------
--[[
    @desc: 
    time:2018-09-01 17:01:35
    --@dir: 回弹相关
    @return:
]] function PelicanBaseScroll:getBoundaryFactor(dir)
    if self:getBoundaryType() == 1 and dir < 0 then
        return 0.5
    elseif self:getBoundaryType() == 2 and dir > 0 then
        return 0.5
    end
    return 1
end

function PelicanBaseScroll:getBoundaryType()
    if self.contentPosition_y < self.m_moveLen then
        return 1
    elseif self.contentPosition_y > 0 then
        return 2
    end
    return 0
end

--滑动判断
function PelicanBaseScroll:isMoveBoundary()
    if self.contentPosition_y <= self.m_moveLen - self.BOUNDRAY_MOVE then
        self.contentPosition_y = self.m_moveLen - self.BOUNDRAY_MOVE
        return true
    elseif self.contentPosition_y >= 0 then
        if self.contentPosition_y >= 0 + self.BOUNDRAY_MOVE then
            self.contentPosition_y = 0 + self.BOUNDRAY_MOVE
            return true
        end
    end
end

function PelicanBaseScroll:isBoundary()
    if self.contentPosition_y <= self.m_moveLen - self.BOUNDRAY_LEN then
        self.contentPosition_y = self.m_moveLen - self.BOUNDRAY_LEN
        return true
    elseif self.contentPosition_y >= 0 then
        if self.contentPosition_y >= 0 + self.BOUNDRAY_LEN then
            self.contentPosition_y = 0 + self.BOUNDRAY_LEN
            return true
        end
    end
end

function PelicanBaseScroll:startBoundary()
    if self:getBoundaryType() == 1 then
        self.contentPosition_y = self.m_moveLen
    elseif self:getBoundaryType() == 2 then
        self.contentPosition_y = 0
    else
        return
    end
    self:stopAutoScroll()
    self.m_content:runAction(cc.MoveTo:create(self.BOUNDRAY_TIME, cc.p(self.m_startPos.x,self.contentPosition_y )))

    if self.m_moveFunc then
        self.m_moveFunc(self.contentPosition_y)
    end
end

function PelicanBaseScroll:getCurrentOffset()
    return self.contentPosition_y
end

return PelicanBaseScroll
-- endregion
