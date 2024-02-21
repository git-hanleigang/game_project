---
--smy
--2018年4月18日
--EpicElephantWheelView.lua

local SendDataManager = require "network.SendDataManager"
local EpicElephantWheelView = class("EpicElephantWheelView", util_require("Levels.BaseLevelDialog"))
EpicElephantWheelView.m_randWheelIndex = nil
EpicElephantWheelView.m_wheelSumIndex =  10 -- 轮盘有多少块
EpicElephantWheelView.m_wheelData = {} -- 大轮盘信息
EpicElephantWheelView.m_wheelNode = {} -- 大轮盘Node 
EpicElephantWheelView.m_bIsTouch = nil

function EpicElephantWheelView:initUI(data)
    self.m_machine = data.machine
    self.m_wheelData = self.m_machine.m_shopConfig.wheel
    self.m_callBack = data.callBack
    self:createCsbNode("EpicElephant/EpicElephantWheel.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel = util_require("CodeEpicElephantSrc.EpicElephantWheelAction"):create(self:findChild("Node_wheel"),self.m_wheelSumIndex,handler(self,self.rotateOver),function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:getWheelSymbol()

    -- 点击layer
    self:addClick(self:findChild("cover"))

    -- 中奖效果
    self.m_zhongjiangEffect = util_createAnimation("EpicElephant_zhuanpan.csb")
    self:findChild("zhongjiang"):addChild(self.m_zhongjiangEffect)
    self.m_zhongjiangEffect:setVisible(false)

    -- 敲鼓spine
    self.m_qiaogu = util_spineCreate("Socre_EpicElephant_Bonus1_zhuanpan",true,true)
    self:findChild("Node_spine"):addChild(self.m_qiaogu)
    self.m_qiaogu:setVisible(false)
    
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_wheel_start)
    self:runCsbAction("start",false,function()
        self:runCsbAction("dianji",true)
    end)
end

function EpicElephantWheelView:rotateOver()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    self.m_qiaogu:setVisible(true)
    -- 停掉背景音乐
    self.m_machine:clearCurMusicBg()

    util_spinePlay(self.m_qiaogu, "start", false)
    util_spineEndCallFunc(self.m_qiaogu, "start", function()
        
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_wheel_zhongjiang_dagu)

        util_spinePlay(self.m_qiaogu, "actionframe2", false)
        util_spineEndCallFunc(self.m_qiaogu, "actionframe2", function()
            
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_wheel_over)

            self:runCsbAction("over",false,function()
                if type(self.m_callBack) == "function" then
                    self.m_callBack(self.m_featureData)
                end
                self:removeFromParent()
            end)
        end)

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_wheel_zhongjiang)

        self.m_zhongjiangEffect:setVisible(true)
        self.m_zhongjiangEffect:runCsbAction("actionframe",false,function()
            self.m_zhongjiangEffect:runCsbAction("actionframe",false,function()
                self.m_zhongjiangEffect:runCsbAction("actionframe",false,function()

                end)
            end)
        end)
    end)
end

function EpicElephantWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_click)

    self:runCsbAction("xiaoshi",false,function()
        self.m_soundId = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_wheel_zhuandong,true)
        self:beginWheelAction()
    end)
    -- self.m_qiaogu:setVisible(true)
    -- util_spinePlay(self.m_qiaogu, "start", false)
    -- util_spineEndCallFunc(self.m_qiaogu, "start", function()
    --     util_spinePlay(self.m_qiaogu, "actionframe", false)
    -- end)
end

-- 转盘转动结束调用
function EpicElephantWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        callBackFun()
    end
end

function EpicElephantWheelView:onEnter()
    EpicElephantWheelView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function EpicElephantWheelView:onExit()
   EpicElephantWheelView.super.onExit(self) 
end

function EpicElephantWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("EpicElephant_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function EpicElephantWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 250 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 1 --匀速时间
    wheelData.m_slowA = 50 --动态减速度
    wheelData.m_slowQ = 3 --减速圈数
    wheelData.m_stopV = 30 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = handler(self,self.rotateOver)

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()

    self:sendData()
    -- self.m_wheel:recvData(math.random(1,self.m_wheelSumIndex))

    
end

-- 返回上轮轮盘的停止位置
function EpicElephantWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function EpicElephantWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function EpicElephantWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        -- gLobalSoundManager:playSound("EpicElephantSounds/sound_EpicElephant_wheel_rptate.mp3")       
    end
end

-- 设置轮盘网络消息
function EpicElephantWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function EpicElephantWheelView:getWheelSymbol(  )
    self.m_bigWheelNode = {}
    
end

--[[
    数据发送
]]
function EpicElephantWheelView:sendData()
    if self.m_isWaiting then
        return
    end

    --防止连续点击
    self.m_isWaiting = true
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = true}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function EpicElephantWheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self:recvBaseData(spinData.result)
        end
    else
        gLobalViewManager:showReConnect(true)
    end
end


--[[
    接收数据
]]
function EpicElephantWheelView:recvBaseData(featureData)
    self.m_featureData = featureData
    local selfData = featureData.selfData
    if not selfData then
        return
    end
    if not selfData.wheelConfig then
        return
    end
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(selfData.wheelConfig[2] + 1)
end

return EpicElephantWheelView