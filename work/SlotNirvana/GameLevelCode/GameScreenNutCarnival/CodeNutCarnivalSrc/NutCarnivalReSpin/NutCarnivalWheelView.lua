local NutCarnivalWheelView = class("NutCarnivalWheelView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "NutCarnivalPublicConfig"

NutCarnivalWheelView.m_randomWheelIndex = nil
NutCarnivalWheelView.m_wheelSumIndex =  12 -- 轮盘有多少块
NutCarnivalWheelView.m_wheelData = {}      -- 大轮盘信息
NutCarnivalWheelView.m_wheelNode = {}      -- 大轮盘Node 
NutCarnivalWheelView.m_bIsTouch = nil

function NutCarnivalWheelView:initDatas(_machine)
    self.m_machine = _machine
    --轮盘次数的配置,进入关卡初始化
    self.m_wheelCfg = {}
    self.m_bIsTouch = false
end

function NutCarnivalWheelView:initUI()
    self:createCsbNode("NutCarnival/NutCarnivalWheel.csb") 

    self.m_roleSpine = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    self:findChild("Node_juese"):addChild(self.m_roleSpine)
    self.m_roleSpine:setVisible(false)

    self.m_wheel = require("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalWheelAction"):create(
        self:findChild("Node_wheel"),
        self.m_wheelSumIndex,
        -- 滚动结束调用
        function()
        end,
        -- 滚动实时调用
        function(distance,targetStep,isBack)
            self.distance_now = distance / targetStep
    
            if self.distance_now < self.distance_pre then
                self.distance_pre = self.distance_now 
            end
            local floor = math.floor(self.distance_now - self.distance_pre)
            if floor > 0 then
                self.distance_pre = self.distance_now 
            
                -- gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_wheel_rotate.mp3")       
            end
        end
    )
    self:addChild(self.m_wheel)

    self:addClick(self:findChild("Panel_spin"))
    self:setWheelSpinBtnEnable(false)
    util_setCascadeOpacityEnabledRescursion(self, true)
end
--[[
    转盘配置和展示
]]
function NutCarnivalWheelView:setWheelConfig(_config)
    self.m_wheelCfg = {}
    for _index,_sValue in ipairs(_config) do
        local value = tonumber(_sValue) or _sValue
        self.m_wheelCfg[_index] = value
    end
end
function NutCarnivalWheelView:updateReward()
    local labIndex = 1
    for i,_sReward in ipairs(self.m_wheelCfg) do
        local times = tonumber(_sReward)
        if times then
            local labTimes = self:findChild(string.format("m_lb_num_%d", labIndex))
            if not labTimes then
                break
            end
            labTimes:setString(string.format("+%d", times))
            labIndex = labIndex + 1
        end
    end
end

function NutCarnivalWheelView:startGame(_data)
    --[[
        _data = {
            addTimes     = 0,
            jackpot      = "",
            wheelDownFun = function,
            overFun      = function,
        }
    ]]
    self.m_data = _data
    self.m_randomWheelIndex = self:getWheelIndexByAward()
    self.m_bIsTouch = true
    self:setWheelSpinBtnEnable(true)
end
function NutCarnivalWheelView:getWheelIndexByAward()
    local randomWheelIndex = 0
    local maxIndex = #self.m_wheelCfg
    local startIndex = math.random(1, maxIndex)
    local runTimes = 0
    while runTimes <= maxIndex do
        runTimes = runTimes + 1
        if 0 ~= self.m_data.addTimes and self.m_wheelCfg[startIndex] == self.m_data.addTimes then
            randomWheelIndex = startIndex
            break
        end
        if "" ~= self.m_data.jackpot and self.m_wheelCfg[startIndex] == self.m_data.jackpot then
            randomWheelIndex = startIndex
            break
        end
        startIndex = startIndex < maxIndex and startIndex + 1 or 1
    end

    util_printLog(string.format("[NutCarnivalWheelView:getWheelIndexByAward] %d", randomWheelIndex) , true)
    return randomWheelIndex
end


--[[
    时间线
]]
--未触发状态的idle
function NutCarnivalWheelView:playNormalIdleAnim()
    self:runCsbAction("idle2", false)
end
--触发状态扫光idle
function NutCarnivalWheelView:playIdleAnim()
    self:runCsbAction("idleframe", true)
end
function NutCarnivalWheelView:playMoveAnim(_bExit, _fun)
    local actTime    = _bExit and 30/60 or 30/60
    local wheelPos   = _bExit and cc.p(0, 0) or cc.p(0, -600)
    local wheelScale = _bExit and 1 or 1.75
    local animName   = _bExit and "xiayi" or "shangyi"
    self:findChild("Node_zhuangshi"):setVisible(not _bExit)

    local actlist = {}
    --调整缩放位置
    table.insert(actlist, cc.Spawn:create(
        cc.MoveTo:create(actTime, wheelPos),
        cc.ScaleTo:create(actTime, wheelScale)
    ))
    --棋盘的松果出现
    table.insert(actlist, cc.CallFunc:create(function()
        self:runCsbAction(animName, false, function()
            if not _bExit then
                self:playIdleAnim()
            else
                self:playNormalIdleAnim()
            end
            _fun()
        end)
        if not _bExit then
            --角色出现
            self:playRoleStartAnim()
        end
    end))
    self:runAction(cc.Sequence:create(actlist))
end
--角色出现
function NutCarnivalWheelView:playRoleStartAnim()
    self.m_roleSpine:setVisible(true)
    self.m_roleSpine:playWheelStartAnim(function()
        self.m_roleSpine:playWheelIdleAnim()
    end)
end
function NutCarnivalWheelView:playClickAnim(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinWheel_click)
    self:runCsbAction("fankui", false, function()
        self:runCsbAction("actionframe2", false)
        if _fun then
            _fun()
        end
    end)
    self:playRoleClickAnim()
    --转盘放大
    local actTime    = 5
    local wheelScale = 2.3
    self:runAction(cc.ScaleTo:create(actTime, wheelScale))
end
function NutCarnivalWheelView:playRoleClickAnim()
    self.m_roleSpine:playWheelBeginRotateAnim()
end

function NutCarnivalWheelView:playActionframeAnim()
    if self.m_rotationSoundId then
        gLobalSoundManager:stopAudio(self.m_rotationSoundId)
        self.m_rotationSoundId = nil
    end
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinWheel_rotateOver)
    self:runCsbAction("actionframe", true)
    self.m_machine:levelPerformWithDelay(self, 1.5, function()
        self.m_roleSpine:setVisible(false)
        self.m_data.overFun()
    end)
    -- 暂时取消角色再次出现
    -- self.m_roleSpine:playWheelActionframeAnim(function()
    --     self.m_roleSpine:setVisible(false)
    --     self.m_data.overFun()
    -- end)
    self.m_data.wheelDownFun()
end

--[[
    转盘点击
]]
function NutCarnivalWheelView:setWheelSpinBtnEnable(_enable)
    --不置灰 改为用图层遮挡
    self:findChild("Panel_spinMask"):setVisible(not _enable)
    -- self:findChild("btn_spin"):setEnabled(_enable)
end
function NutCarnivalWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end
    self.m_bIsTouch = false
    self:setWheelSpinBtnEnable(false)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinWheel_rotateBegin)
    -- self.m_rotationSoundId = gLobalSoundManager:playSound(NutCarnivalMusicConfig.sound_NutCarnival_jackpotWheel_rotation, true)
    self:playClickAnim(nil)
    self:beginWheelAction()
end


-- 设置转盘盘滚动参数
function NutCarnivalWheelView:beginWheelAction()
    local wheelData = {}
    wheelData.m_startA         = 200  --加速度
    wheelData.m_runV           = 600  --匀速
    wheelData.m_runTime        = 3    --匀速时间
    wheelData.m_slowA          = 50   --动态减速度
    wheelData.m_slowQ          = 3    --减速圈数
    wheelData.m_stopV          = 30   --停止时速度
    wheelData.m_backTime       = 0    --回弹前停顿时间
    wheelData.m_stopNum        = 0    --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = function()
        self:playActionframeAnim()
    end

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randomWheelIndex)
end




--切换层级
function NutCarnivalWheelView:setWheelOrder(_bUp)
    local newParent = _bUp and self.m_machine:findChild("Node_wheel_up") or self.m_machine:findChild("Node_wheel_down")
    local newPos = util_convertToNodeSpace(self, newParent)
    util_changeNodeParent(newParent, self)
    self:setPosition(newPos)
end
--[[
    grand锁定
]]
function NutCarnivalWheelView:setGrandLockState(_bLock)
    local lockNode = self:findChild("Node_grandLock")
    lockNode:setVisible(_bLock)
end

return NutCarnivalWheelView