---
--smy
--2018年4月18日
--SpookySnacksWheelView.lua

local SpookySnacksWheelView = class("SpookySnacksWheelView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "SpookySnacksPublicConfig"
SpookySnacksWheelView.m_randWheelIndex = nil
SpookySnacksWheelView.m_wheelSumIndex =  6 -- 轮盘有多少块
SpookySnacksWheelView.m_bIsTouch = false

function SpookySnacksWheelView:initUI(data)
    self.m_machine = data.machine
    
    self.m_callBack = data.callBack
    self.m_endPos = data.endPos
    self.m_jackpotType = data.JackpotType
    self.m_changeJackpotCallBack = data.changeJackpotCallBack
    self.m_soundId = nil

    self:createCsbNode("SpookySnacks/WheelSpookySnacks.csb") 

    self:changeBtnEnabled(false)

    local isJieSuo = self.m_machine.m_jackPotBarView:checkIsJieSuo()
    self.m_wheelStopData = self:getWheelStopIndex(data.JackpotType, isJieSuo)

    self:findChild("Node_grandsuoding"):setVisible(isJieSuo)
    

    self.m_wheel = util_require("CodeSpookySnacksSrc.SpookySnacksWheel.SpookySnacksWheelAction"):create(self:findChild("Node_zhuanpan"),self.m_wheelSumIndex,handler(self,self.rotateOver),function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()
    
    self:findChild("Particle_1"):stopSystem()

    self.m_spineEffect = util_spineCreate("SpookySnacks_wheel_effects",true,true)
    self:findChild("Node_guang"):addChild(self.m_spineEffect)
    self.m_spineEffect:setVisible(false)

    --引导小手
    self.m_shou = util_createAnimation("SpookySnacks_wheel_tips.csb")
    self:findChild("Node_tips"):addChild(self.m_shou)

    --中奖效果
    self.m_zhongjiang = util_createAnimation("SpookySnacks_wheel_win.csb")
    self:findChild("win"):addChild(self.m_zhongjiang)
    self.m_zhongjiang:setVisible(false)

    -- 点击layer
    self:addClick(self:findChild("cover"))
    
    self.m_shou:runCsbAction("start",false,function ()
        self.m_shou:runCsbAction("idle",true)
    end)
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_wheel_show)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        self.m_bIsTouch = true
    end)
end

-- 计算转盘停止的位置
function SpookySnacksWheelView:getWheelStopIndex(_JackpotType, _isJieSuo)
    -- if _isJieSuo then
        --{"grand", "mini", "minor", "major", "minor", "mini"} --转盘盘面上的jackpot 顺序
        self.m_wheelJackpotList = 
        {
            {3}, -- major
            {2,4}, -- minor
            {1,5}, -- mini
            {6}, -- grand
            
        }
        if _JackpotType == 1 then
            return self.m_wheelJackpotList[4][1]
        elseif _JackpotType == 2 then
            return self.m_wheelJackpotList[1][1]
        elseif _JackpotType == 3 then
            return self.m_wheelJackpotList[2][math.random(1,2)] 
        else
            return self.m_wheelJackpotList[3][math.random(1,2)] 
        end
    -- else
    --     --{"grand", "mini", "minor", "major", "minor", "mini"} --转盘盘面上的jackpot 顺序
    --     self.m_wheelJackpotList = 
    --     {
    --         {1}, -- grand
    --         {4}, -- major
    --         {3,5}, -- minor
    --         {2,6}, -- mini
    --     }
    --     if _JackpotType == 1 or _JackpotType == 2 then
    --         return self.m_wheelJackpotList[_JackpotType][1]
    --     else
    --         return self.m_wheelJackpotList[_JackpotType][math.random(1,2)] 
    --     end
    -- end
end

function SpookySnacksWheelView:rotateOver()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    -- self.m_spineWheelUp:setVisible(false)
    -- self.m_spineWheelDown:setVisible(false)

    -- 停止粒子
    self:findChild("Particle_1"):stopSystem()

    -- 隐藏4个jackpot图片
    for jackpotPic = 1, 4 do
        -- self:findChild("BlackFriday_jackpot_"..jackpotPic):setVisible(false)
    end
    -- 只显示中奖的jackpot 放大用
    -- self:findChild("BlackFriday_jackpot_"..self.m_jackpotType):setVisible(true)
    
    -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_wheel_xuanzhong)
    -- local random = math.random(1,2)
    -- --《转盘选中》音效播放时，50%几率随机播放配音
    -- if random == 1 then
    --     local randomPlay = math.random(1,2)
    --     gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig["sound_BlackFriday_wheel_zhongjiang"..randomPlay])
    -- end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_wheel_xuanzhong)
    self.m_zhongjiang:setVisible(true)
    self.m_zhongjiang:runCsbAction("actionframe2",true)
    
    self:runCsbAction("actionframe2",false,function()
            self.m_zhongjiang:setVisible(false)
        -- self:runCsbAction("actionframe3",false,function()
            -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_wheel_over)
            if type(self.m_changeJackpotCallBack) == "function" then
                self.m_changeJackpotCallBack()          --改变小块样式
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_wheel_hide)
            self:runCsbAction("over")

            -- 20帧的时候 轮盘上的小块 显示成带jackpot的
            local seq = cc.Sequence:create({
                cc.DelayTime:create(10/60),
                cc.MoveTo:create(0.3,self.m_endPos),

                cc.DelayTime:create(70/60 - 10/60 - 0.3),
                cc.CallFunc:create(function()
                    if type(self.m_callBack) == "function" then         --下一轮
                        self.m_callBack(self.m_featureData)
                    end
                    self:removeFromParent()
                end),
            })

            self:runAction(seq)

        -- end)
    end)
end

function SpookySnacksWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false
    self.m_shou:runCsbAction("over")
    self.m_spineEffect:setVisible(true)
    util_spinePlay(self.m_spineEffect, "actionframe",false)
    self:findChild("Particle_1"):resetSystem()
    self:runCsbAction("actionframe",false)         --放大（镜头拉伸）
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_wheel_run,true)
    self:beginWheelAction()
    
end

-- 转盘转动结束调用
function SpookySnacksWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        callBackFun()
    end
end

function SpookySnacksWheelView:onEnter()
    SpookySnacksWheelView.super.onEnter(self)
end

function SpookySnacksWheelView:onExit()
   SpookySnacksWheelView.super.onExit(self) 
end

function SpookySnacksWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("EpicElephant_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function SpookySnacksWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 350 --加速度
    wheelData.m_runV = 1000--匀速
    wheelData.m_runTime = 1.5 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 3 --减速圈数
    wheelData.m_stopV = 80 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = handler(self,self.rotateOver)

    self.m_wheel:changeWheelRunData(wheelData)

    -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_wheel_zhuandong)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()

    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_wheelStopData)
end

-- 返回上轮轮盘的停止位置
function SpookySnacksWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function SpookySnacksWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function SpookySnacksWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then

        self.distance_pre = self.distance_now 
            
    end
end

-- 设置轮盘网络消息
function SpookySnacksWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

return SpookySnacksWheelView