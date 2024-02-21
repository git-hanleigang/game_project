--
--滑动基类 左右滑动 最大值是0就是起始点  最小值setMoveLen必须设置否则不能滑动
--
local BaseScroll = class("BaseScroll")

BaseScroll.AUTO_STOP_SPEED = 2 -- 惯性滑动停止速度
BaseScroll.AUTO_IN_MOVE = 20 -- 手势滑动开启平均值
BaseScroll.AUTO_FRICTIONE = 0.6 -- 摩擦力
BaseScroll.AUTO_MAX_SPEED = 70 -- 速度峰值
BaseScroll.DELTA_SPEED = 0.5 -- 惯性初速度系数

BaseScroll.BOUNDRAY_MOVE = 100 -- 边缘回弹检测
BaseScroll.BOUNDRAY_LEN = 500 -- 边缘回弹距离
BaseScroll.BOUNDRAY_TIME = 0.1 -- 边缘回弹时间

BaseScroll.contentPosition_x = nil
BaseScroll.isAuto = nil
BaseScroll.autoSpeed = nil
BaseScroll.moveList = nil
BaseScroll.moveIndex = nil
BaseScroll.m_moveFunc = nil
BaseScroll.m_moveLen = nil
require("socket")
local DELTA_TIME = 0.4 -- 滑动响应时间
BaseScroll.m_startTime = nil
function BaseScroll:ctor()
    self.contentPosition_x = 0
    self.m_moveLen = 0
    self:initAutoScroll()
end

--需要滑动的node 起始坐标 滑动回调
function BaseScroll:initData_(node, startPos, func, scrollType)
    if scrollType then
        self.m_scrollType = scrollType
    else
        self.m_scrollType = 1
    end
    self.m_startPos = startPos
    self.m_moveFunc = func
    self:initContent(node)
    self.contentPosition_x = self.m_startPos.x
    self.contentPosition_y = self.m_startPos.y
    if self.m_scrollType == 1 then
        self.m_content:setPosition(self.contentPosition_x, self.m_startPos.y)
    else
        self.m_content:setPosition(self.m_startPos.x, self.contentPosition_y)
    end

    self:initScroll()
end

function BaseScroll:removeScrollEvent()
    if not tolua.isnull(self.m_content) then
        local eventDispatcher = self.m_content:getEventDispatcher()
        eventDispatcher:removeEventListenersForTarget(self.m_content)
    end
end

--手动滑动时使用 摩擦力
function BaseScroll:setUseAutoFrictionsOnHandState(isUse)
    self.m_useAutoFrictionsOnHandState = isUse
end

--子类初始化
function BaseScroll:initScroll()
end

function BaseScroll:initAutoScroll()
    self.isAuto = false
    self.autoSpeed = 0
    self.moveList = {0, 0, 0, 0, 0, 0}
    self.moveIndex = 1
    self.m_startTime = 0
end

--可向右活动的区域负数 必须设置 例如可滑动500的距离就设置-500
function BaseScroll:setMoveLen(len, isChangeMover)
    self.m_moveLen = len
    if isChangeMover then
        self:startBoundary()
    end
end

function BaseScroll:getMoveLen()
    return self.m_moveLen
end

function BaseScroll:isAutoScroll()
    return self.isAuto
end

function BaseScroll:startAutoScroll(delta)
    self.isAuto = true
    self.autoSpeed = delta * self.DELTA_SPEED
end

function BaseScroll:stopAutoScroll()
    self:initAutoScroll()
    -- if not self.isAuto then
    --     gLobalNoticManager:postNotification("Notify_Scroll_Stop")
    -- end
end

function BaseScroll:initContent(node)
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

function BaseScroll:getPosition()
    return self.m_content:getPosition()
end

function BaseScroll:touchBeginLogic(touch, event)
    self:initAutoScroll()
    self.m_startTime = socket.gettime()
end

function BaseScroll:touchMoveLogic(touch, event)
    local delta = touch:getDelta()
    local target = event:getCurrentTarget()
    local posX, posY = target:getPosition()
    if self.m_scrollType == 1 then
        local touchBeginPosition = posX
        local touchMovePosition = delta.x * self:getBoundaryFactor(delta.x)
        if self.m_useAutoFrictionsOnHandState then
            touchMovePosition = touchMovePosition * self.AUTO_FRICTIONE
        end
        local newPosition = touchMovePosition + touchBeginPosition
        --local locationInNode = target:convertToWorldSpace(touch:getLocation())
        self:move(newPosition)
        self:pushMoveDelta(touchMovePosition)
    else
        local touchBeginPosition = posY
        local touchMovePosition = delta.y * self:getBoundaryFactor(delta.y)
        if self.m_useAutoFrictionsOnHandState then
            touchMovePosition = touchMovePosition * self.AUTO_FRICTIONE
        end
        local newPosition = touchMovePosition + touchBeginPosition
        --local locationInNode = target:convertToWorldSpace(touch:getLocation())
        self:move(newPosition)
        self:pushMoveDelta(touchMovePosition)
    end
end

function BaseScroll:toucEndLogic(touch, event)
    local spanTime = socket.gettime() - self.m_startTime
    local delta = self:getMoveDelta()
    if math.abs(delta) > self.AUTO_IN_MOVE and spanTime < DELTA_TIME then
        self:startAutoScroll(delta)
    else
        self:stopAutoScroll()
    end
    self:startBoundary()
end

function BaseScroll:pushMoveDelta(delta)
    self.moveList[self.moveIndex] = delta
    self.moveIndex = self.moveIndex + 1
    if self.moveIndex > 6 then
        self.moveIndex = 1
    end
end

function BaseScroll:getMoveDelta()
    local delta = 0
    for i = 1, 6 do
        delta = delta + self.moveList[i]
    end
    return delta
end

-- function BaseScroll:getBoundaryFactor(autoSpeed)
--     return 1
-- end

function BaseScroll:update(dt)
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
            if self.m_scrollType == 1 then
                self:move(self.contentPosition_x + self.AUTO_MAX_SPEED * self:getBoundaryFactor(self.autoSpeed))
            else
                self:move(self.contentPosition_y + self.AUTO_MAX_SPEED * self:getBoundaryFactor(self.autoSpeed))
            end
        elseif self.autoSpeed < -self.AUTO_MAX_SPEED then
            if self.m_scrollType == 1 then
                self:move(self.contentPosition_x - self.AUTO_MAX_SPEED * self:getBoundaryFactor(self.autoSpeed))
            else
                self:move(self.contentPosition_y - self.AUTO_MAX_SPEED * self:getBoundaryFactor(self.autoSpeed))
            end
        else
            if self.m_scrollType == 1 then
                self:move(self.contentPosition_x + self.autoSpeed * self:getBoundaryFactor(self.autoSpeed))
            else
                self:move(self.contentPosition_y + self.autoSpeed * self:getBoundaryFactor(self.autoSpeed))
            end
        end
        if self:isBoundary() then
            self:startBoundary()
        end
    end
end

function BaseScroll:move(dis, secs)
    secs = secs or 0
    if self.m_scrollType == 1 then
        if dis ~= nil then
            self.contentPosition_x = dis
        end
        --边缘弹动
        if self:isBoundary() then
            self:stopAutoScroll()
        end
        if secs > 0 then
            self.m_content:runAction(cc.MoveTo:create(secs, cc.p(self.contentPosition_x, self.m_startPos.y)))
        else
            self.m_content:setPosition(self.contentPosition_x, self.m_startPos.y)
        end
        if self.m_moveFunc then
            self.m_moveFunc(self.contentPosition_x)
        end
    else
        if dis ~= nil then
            self.contentPosition_y = dis
        end

        --边缘弹动
        if self:isBoundary() then
            self:stopAutoScroll()
        end
        if secs > 0 then
            self.m_content:runAction(cc.MoveTo:create(secs, cc.p(self.m_startPos.x, self.contentPosition_y)))
        else
            self.m_content:setPosition(self.m_startPos.x, self.contentPosition_y)
        end
        if self.m_moveFunc then
            self.m_moveFunc(self.contentPosition_y)
        end
    end
end
--------
--[[
    @desc: 
    time:2018-09-01 17:01:35
    --@dir: 回弹相关
    @return:
]] function BaseScroll:getBoundaryFactor(dir)
    if self:getBoundaryType() == 1 and dir < 0 then
        return 0.5
    elseif self:getBoundaryType() == 2 and dir > 0 then
        return 0.5
    end
    return 1
end

function BaseScroll:getBoundaryType()
    if self.m_scrollType == 1 then
        if self.contentPosition_x < self.m_moveLen then
            return 1
        elseif self.contentPosition_x > 0 then
            return 2
        end
    else
        if self.contentPosition_y > self.m_moveLen then
            return 2
        elseif self.contentPosition_y < 0 then
            return 1
        end
    end
    return 0
end

--滑动判断
function BaseScroll:isMoveBoundary()
    if self.m_scrollType == 1 then
        if self.contentPosition_x <= self.m_moveLen - self.BOUNDRAY_MOVE then
            self.contentPosition_x = self.m_moveLen - self.BOUNDRAY_MOVE
            return true
        elseif self.contentPosition_x >= 0 then
            if self.contentPosition_x >= 0 + self.BOUNDRAY_MOVE then
                self.contentPosition_x = 0 + self.BOUNDRAY_MOVE
                return true
            end
        end
    else
        if self.contentPosition_y >= self.m_moveLen - self.BOUNDRAY_MOVE then
            self.contentPosition_y = self.m_moveLen - self.BOUNDRAY_MOVE
            return true
        elseif self.contentPosition_y <= 0 then
            if self.contentPosition_y <= 0 + self.BOUNDRAY_MOVE then
                self.contentPosition_y = 0 + self.BOUNDRAY_MOVE
                return true
            end
        end
    end
end

function BaseScroll:isBoundary()
    if self.m_scrollType == 1 then
        if self.contentPosition_x <= self.m_moveLen - self.BOUNDRAY_LEN then
            self.contentPosition_x = self.m_moveLen - self.BOUNDRAY_LEN
            return true
        elseif self.contentPosition_x >= 0 then
            if self.contentPosition_x >= 0 + self.BOUNDRAY_LEN then
                self.contentPosition_x = 0 + self.BOUNDRAY_LEN
                return true
            end
        end
    else
        if self.contentPosition_y >= self.m_moveLen - self.BOUNDRAY_LEN then
            self.contentPosition_y = self.m_moveLen - self.BOUNDRAY_LEN
            return true
        elseif self.contentPosition_y <= 0 then
            if self.contentPosition_y <= 0 + self.BOUNDRAY_LEN then
                self.contentPosition_y = 0 + self.BOUNDRAY_LEN
                return true
            end
        end
    end
end

function BaseScroll:startBoundary()
    if self.m_scrollType == 1 then
        if self:getBoundaryType() == 1 then
            self.contentPosition_x = self.m_moveLen
        elseif self:getBoundaryType() == 2 then
            self.contentPosition_x = 0
        else
            return
        end
        self:initAutoScroll()
        self.m_content:runAction(cc.MoveTo:create(self.BOUNDRAY_TIME, cc.p(self.contentPosition_x, self.m_startPos.y)))
        if self.m_moveFunc then
            self.m_moveFunc(self.contentPosition_x)
        end
    else
        if self:getBoundaryType() == 1 then
            self.contentPosition_y = 0
        elseif self:getBoundaryType() == 2 then
            self.contentPosition_y = self.m_moveLen
        else
            return
        end
        self:initAutoScroll()
        self.m_content:runAction(cc.MoveTo:create(self.BOUNDRAY_TIME, cc.p(self.m_startPos.x, self.contentPosition_y)))
        if self.m_moveFunc then
            self.m_moveFunc(self.contentPosition_y)
        end
    end
end

function BaseScroll:getCurrentOffset()
    if self.m_scrollType == 1 then
        return self.contentPosition_x
    else
        return self.contentPosition_y
    end
end

return BaseScroll
-- endregion
