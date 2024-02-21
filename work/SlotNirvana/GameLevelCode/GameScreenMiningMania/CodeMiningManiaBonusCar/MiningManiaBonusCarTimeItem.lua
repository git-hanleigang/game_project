---
--xcyy
--2018年5月23日
--MiningManiaBonusCarTimeItem.lua

local MiningManiaBonusCarTimeItem = class("MiningManiaBonusCarTimeItem",util_require("Levels.BaseLevelDialog"))
MiningManiaBonusCarTimeItem.m_curTime = 0
MiningManiaBonusCarTimeItem.m_curFrameTime = 0
MiningManiaBonusCarTimeItem.m_isEndPlay = false
MiningManiaBonusCarTimeItem.m_isOver = false
MiningManiaBonusCarTimeItem.m_totalTime = 0

function MiningManiaBonusCarTimeItem:initUI(_machine, _index, _timeRedAni)

    self:createCsbNode("MiningMania_Shejiao2_TimeProcess.csb")

    self:runCsbAction("idle", true)

    self.m_machineCar = _machine
    self.m_index = _index
    self.m_timeRedAni = _timeRedAni

    self.ENUM_CAR_TYPE = 
    {
        RED = 1,
        BLUE = 2,
        GREED = 3,
    }

    self:findChild("sp_red"):setVisible(false)
    self:findChild("sp_blue"):setVisible(false)
    self:findChild("sp_green"):setVisible(false)

    local spProcess = self:findChild("sp_red")
    if _index == self.ENUM_CAR_TYPE.RED then
        spProcess = self:findChild("sp_red")
    elseif _index == self.ENUM_CAR_TYPE.BLUE then
        spProcess = self:findChild("sp_blue")
    elseif _index == self.ENUM_CAR_TYPE.GREED then
        spProcess = self:findChild("sp_green")
    end
    
    self.processTimer = cc.ProgressTimer:create(spProcess)
    self.processTimer:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self:findChild("Node_process"):addChild(self.processTimer)

    self.m_textTime = self:findChild("m_lb_num")
    self.m_m_textTimeMe = self:findChild("m_lb_num_me")
end

function MiningManiaBonusCarTimeItem:resetData(_times)
    self.m_curTime = 0
    self.m_curFrameTime = 0
    if _times then
        self.m_curTime = self.m_curTime + _times
    end
    self:runCsbAction("idle", true)
    self.m_timeRedAni:startAni()
    self.m_isEndPlay = false
    self.m_isOver = false
    self.m_totalTime = 0
    self.processTimer:setVisible(true)
    self:setTextRefreshState(true)
    self:setTextVisibleState()
end

function MiningManiaBonusCarTimeItem:setTotalTime(_times)
    self.m_totalTime = self.m_totalTime + _times
end

function MiningManiaBonusCarTimeItem:addTimes(_times, _onEnter, _mySelf)
    if _times then
        self.m_curTime = self.m_curTime + _times
        if _times > 0 then
            self:setTotalTime(_times)
            if not _onEnter and _mySelf then
                self:setTextRefreshState(false)
            end
        end
    end
    if self.m_curTime <= 3 then
        self:playEndTimeAct()
    end
    self:setTimes()
end

-- 添加时间
function MiningManiaBonusCarTimeItem:addTimesRefresh()
    self.m_isEndPlay = false
    self:setTextRefreshState(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("add", false, function()
        self:runCsbAction("idle", true)
    end)
end

-- 倒计时3秒
function MiningManiaBonusCarTimeItem:playEndTimeAct()
    if self.m_isEndPlay then
        return
    end
    self.m_isEndPlay = true
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", true)
    self.m_timeRedAni:endTimesTrigger()
end

function MiningManiaBonusCarTimeItem:setTimes()
    if self.m_curTime > 0 then
        local curTime = math.ceil(self.m_curTime)
        self:setTextTimes(curTime)
    else
        if self.m_isOver then
            return
        end
        self.processTimer:setVisible(false)
        self.m_isOver = true
        self:setTextTimes(0)
        self:runCsbAction("over", false)
        self.m_timeRedAni:overAni()
    end
end

function MiningManiaBonusCarTimeItem:setTextTimes(_times)
    if self.m_isFlyEnd then
        self.processTimer:setPercentage((self.m_totalTime-self.m_curTime) / self.m_totalTime * 100)
        self.m_textTime:setString(_times)
        self.m_m_textTimeMe:setString(_times)
    end
end

-- 控制状态刷新文本
function MiningManiaBonusCarTimeItem:setTextRefreshState(_state)
    self.m_isFlyEnd = _state
end

function MiningManiaBonusCarTimeItem:addFrameTime(_frameTime)
    self.m_curFrameTime = self.m_curFrameTime + _frameTime
end

function MiningManiaBonusCarTimeItem:getTimes()
    local remainTimes = self.m_curTime - self.m_curFrameTime
    return self.m_curTime
end

function MiningManiaBonusCarTimeItem:startAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

function MiningManiaBonusCarTimeItem:overAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false)
end

-- 自己的字体区别
function MiningManiaBonusCarTimeItem:setTextVisibleState(_state)
    if _state then
        self.m_textTime:setVisible(false)
        self.m_m_textTimeMe:setVisible(true)
    else
        self.m_textTime:setVisible(true)
        self.m_m_textTimeMe:setVisible(false)
    end
end

-- 暂停
function MiningManiaBonusCarTimeItem:pauseAction()
    util_pause_node_recursion(self)
end

-- 恢复
function MiningManiaBonusCarTimeItem:resumeAction()
    util_resume_node_recursion(self)
end

return MiningManiaBonusCarTimeItem
