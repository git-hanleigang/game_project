---
--smy
--2018年4月18日
--OrcaCaptainWheelView.lua
local SendDataManager = require "network.SendDataManager"
local OrcaCaptainPublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainWheelView = class("OrcaCaptainWheelView", util_require("Levels.BaseLevelDialog"))
OrcaCaptainWheelView.m_randWheelIndex = nil
OrcaCaptainWheelView.m_nearMissWheelIndex = nil
OrcaCaptainWheelView.m_wheelSumIndex =  18 -- 轮盘有多少块
OrcaCaptainWheelView.m_wheelData = {} -- 大轮盘信息
OrcaCaptainWheelView.m_wheelNode = {} -- 大轮盘Node 
OrcaCaptainWheelView.m_bIsTouch = nil
local MIN_SPEED     =   10          --最小速度(每秒转动的角度)

function OrcaCaptainWheelView:initUI(data)
    
    self:createCsbNode("OrcaCaptain/GameScreenWheel.csb") 

    self:changeBtnEnabled(false)
    self.m_isNearMiss = false

    self.m_bIsTouch = false
    self.m_wheel = require("CodeOrcaCaptainSrc.OrcaCaptainWheelAction"):create(self:findChild("Node_wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    -- self:setWheelData(data.wheel ) -- 设置轮盘信息
    self.m_randWheelIndex = 0
    self.m_nearMissWheelIndex = 0

    self.m_featureData = nil

    self.m_machine = data.machine

    self:initWheelSymbol()


    -- 点击layer
    self:setTouchLayer()

     self:createAllUI()
     --计时器节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    self.rotateSound = nil
end

function OrcaCaptainWheelView:createAllUI()
    self.wheelTx =  util_createAnimation("OrcaCaptain/GameScreenWheel_tx.csb")
    self:findChild("Node_tx"):addChild(self.wheelTx)
    
    self.wheelTx:setVisible(false)

    self.wheelJveSe = util_spineCreate("OrcaCaptain_juese", true, true)
    self:findChild("Node_juese"):addChild(self.wheelJveSe)
    self.wheelJveSe:setVisible(false)

    self.jveseShou = util_spineCreate("OrcaCaptain_juese", true, true)
    self:findChild("Node_juese2"):addChild(self.jveseShou)
    self.jveseShou:setVisible(false)


    self.tiShi = util_createAnimation("OrcaCaptain_Wheel_tishi.csb")
    self:findChild("Node_tishi"):addChild(self.tiShi)
    self.shou = util_spineCreate("OrcaCaptain_shou", true, true)
    self.tiShi:findChild("Node_shou"):addChild(self.shou)
    self.tiShi:setVisible(false)
    self.shou:setVisible(false)
end

function OrcaCaptainWheelView:showWheelStart()
    --重置轮盘角度
    self:findChild("Node_wheel"):setRotation(0)
    self.m_nearMissWheelIndex = 0
    self.m_isNearMiss = false
    self.rotateSound = nil
    self.m_featureData = nil
    self.m_curRotation = 0
    self:startSchedule()
    self:setTouchLayer()
    self.tiShi:setVisible(true)
    self.shou:setVisible(true)
    self.jveseShou:setVisible(true)
    self.wheelJveSe:setVisible(true)
    util_spinePlay(self.wheelJveSe, "idleframe_wheel",true)
    util_spinePlay(self.jveseShou, "idleframe_wheel2",true)
    util_spinePlay(self.shou, "idleframe",true)
    
    self:runCsbAction("start",false,function ()
        self.m_bIsTouch = true
        self:runCsbAction("idle",true)
    end)
end

function OrcaCaptainWheelView:showWheelAct(wheelResult)
    if wheelResult == "coins" then
        self:runCsbAction("actionframe",true)
    else
        self:runCsbAction("actionframe2_start",false,function ()
            self:runCsbAction("actionframe2",true)
        end)
    end
    
end

function OrcaCaptainWheelView:hideWheelAct()
    self.wheelTx:runCsbAction("over",false,function ()
        self.wheelTx:setVisible(false)
    end)
    --是否有nearMiss
    if self.m_isNearMiss and self.m_nearMissWheelIndex ~= 0 then
        --角色动画
        
        util_spinePlay(self.wheelJveSe, "actionframe_wheel3")    --一共八十帧
        util_spinePlay(self.jveseShou, "actionframe_wheel4")
        util_spineEndCallFunc(self.wheelJveSe, "actionframe_wheel3", function ()
            util_spinePlay(self.jveseShou, "idleframe_wheel2",true)
            util_spinePlay(self.wheelJveSe, "idleframe_wheel",true)
        end)
        local beforeDistance = 360 - (self.m_nearMissWheelIndex - 1) * self.m_wheel.m_targetStep
        local moveDistance = 360 - (self.m_randWheelIndex - 1) * self.m_wheel.m_targetStep  --需要移动的距离
        local differDistance = moveDistance - beforeDistance
            
        local node = self:findChild("Node_wheel")
        local actList = {}
        actList[#actList + 1] = cc.DelayTime:create(45/30)
        actList[#actList + 1] = cc.CallFunc:create(function( )
            gLobalSoundManager:playSound(OrcaCaptainPublicConfig.SoundConfig.sound_OrcaCaptain_wheel_nearMiss_show)
        end)
        actList[#actList + 1] = cc.RotateTo:create(15 / 30, (beforeDistance + differDistance/2))     --45帧拨动一次
        actList[#actList + 1] = cc.DelayTime:create(6/30)
        actList[#actList + 1] = cc.RotateTo:create(15 / 30, (beforeDistance + differDistance))     --66帧拨动一次
        actList[#actList + 1] = cc.DelayTime:create(15/30)
        actList[#actList + 1] = cc.CallFunc:create(function( )
            self:newHideWheelAct()
        end)
        local sq = cc.Sequence:create(actList)
        node:runAction(sq)
        
    else
        self:newHideWheelAct()
    end
end

function OrcaCaptainWheelView:newHideWheelAct()
    local selfData = self.m_featureData.selfData
    local wheelResult = selfData.wheelResult
    self:showWheelAct(wheelResult[2])
    local time = 1.5
    if self.rotateSound then
        gLobalSoundManager:stopAudio(self.rotateSound)
        self.rotateSound = nil
    end
    if wheelResult[2] == "coins" then
        self.jveseShou:setVisible(false)
        gLobalSoundManager:playSound(OrcaCaptainPublicConfig.SoundConfig.sound_OrcaCaptain_wheel_coins_show)
        util_spinePlay(self.wheelJveSe, "actionframe_guochang3")
        --若为钱数，则刷新赢钱区
        self.m_machine:bonusOverAddCoinsEffect()
        self.m_machine:delayCallBack(2,function ()
            if self.m_callFunc then
                self.m_callFunc()
            end
        end)
    else
        if wheelResult[2] == "jackpot" then
            gLobalSoundManager:playSound(OrcaCaptainPublicConfig.SoundConfig.sound_OrcaCaptain_wheel_color_show)
        else
            gLobalSoundManager:playSound(OrcaCaptainPublicConfig.SoundConfig.sound_OrcaCaptain_wheel_free_show)
        end
        util_spinePlay(self.wheelJveSe, "idleframe2_wheel",true)
        util_spinePlay(self.jveseShou, "idleframe2_wheel2",true)
    
        self.m_machine:delayCallBack(time,function ()
            if self.m_callFunc then
                self.m_callFunc()
            end
        end)
    end
    
    
end

function OrcaCaptainWheelView:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:clickFunc()
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()    
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function OrcaCaptainWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false
    self.tiShi:setVisible(false)
    self.shou:setVisible(false)
    util_spinePlay(self.wheelJveSe, "actionframe_wheel")
    util_spinePlay(self.jveseShou, "actionframe_wheel2")
    util_spineEndCallFunc(self.wheelJveSe, "actionframe_wheel", function ()
        util_spinePlay(self.jveseShou, "idleframe_wheel2",true)
        util_spinePlay(self.wheelJveSe, "idleframe_wheel",true)
    end)
    if self.rotateSound then
        gLobalSoundManager:stopAudio(self.rotateSound)
        self.rotateSound = nil
    end
    self.rotateSound = gLobalSoundManager:playSound(OrcaCaptainPublicConfig.SoundConfig.sound_OrcaCaptain_wheel_rotate_show)
    -- self.m_machine:delayCallBack(15/30,function ()
        self:sendData()
        --停止计时器
        self.m_scheduleNode:unscheduleUpdate()
        self:beginWheelAction()
    -- end)
    

end

-- 转盘转动结束调用
function OrcaCaptainWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        callBackFun()
    end
end

function OrcaCaptainWheelView:onEnter()
    OrcaCaptainWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function OrcaCaptainWheelView:onExit()
   OrcaCaptainWheelView.super.onExit(self) 
   --停止计时器
   self.m_scheduleNode:unscheduleUpdate()
end

function OrcaCaptainWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("OrcaCaptain_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function OrcaCaptainWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 250 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 3 --匀速时间
    wheelData.m_slowA = 20 --动态减速度
    wheelData.m_slowQ = 5 --减速圈数
    wheelData.m_stopV = 30 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_currentDistance = self.m_curRotation
    wheelData.m_func = function ()
        self:hideWheelAct()
    end

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    self.wheelTx:setVisible(true)
    self.wheelTx:runCsbAction("start",false,function ()
        self.wheelTx:runCsbAction("idle",true)
    end)
    -- 设置轮盘功能滚动结束停止位置
    -- self.m_wheel:recvData(self.m_randWheelIndex)

    
end

-- 返回上轮轮盘的停止位置
function OrcaCaptainWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

function OrcaCaptainWheelView:setLastEndIndex(index)
    self.m_randWheelIndex = index
     
 end

-- 设置轮盘实时滚动调用
function OrcaCaptainWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function OrcaCaptainWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now 
        -- gLobalSoundManager:playSound("OrcaCaptainSounds/sound_OrcaCaptain_wheel_rptate.mp3")       
    end
end

function OrcaCaptainWheelView:initWheelSymbol()
    self.m_bigWheelNode = {}
    for index = 1, self.m_wheelSumIndex, 1 do
        local symbolNode = util_createAnimation("OrcaCaptain_Wheel_coin.csb")
        self:findChild("Node_coin_"..index):addChild(symbolNode)
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = symbolNode
    end
end

-- 设置轮盘网络消息
function OrcaCaptainWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

--初始化轮盘信息
function OrcaCaptainWheelView:updateWheelSymbol(  )
    -- self.m_bigWheelNode = {}

    for index = 1, self.m_wheelSumIndex, 1 do
        local symbolData = self.m_bigWheelData[index]
        local symbolNode = self.m_bigWheelNode[index]
        if symbolData[2] == "coins" then
            symbolNode:findChild("Node_little_0"):setVisible(true)
            symbolNode:findChild("Node_little"):setVisible(true)
            symbolNode:findChild("Node_FG"):setVisible(false)
            symbolNode:findChild("Node_jackpot"):setVisible(false)
            local coinsArray,splitNum = self:splitCoinsLab(symbolData[1])
            self:showSplitCoins(coinsArray,splitNum,symbolNode)
        elseif symbolData[2] == "free" then
            symbolNode:findChild("Node_little_0"):setVisible(false)
            symbolNode:findChild("Node_little"):setVisible(false)
            symbolNode:findChild("Node_FG"):setVisible(true)
            symbolNode:findChild("Node_jackpot"):setVisible(false)
            self:setFreeSpinNum(symbolData[1],symbolNode)
        elseif symbolData[2] == "jackpot" then
            symbolNode:findChild("Node_little_0"):setVisible(false)
            symbolNode:findChild("Node_little"):setVisible(false)
            symbolNode:findChild("Node_FG"):setVisible(false)
            symbolNode:findChild("Node_jackpot"):setVisible(true)
        end
        --存储小块数据
        symbolNode.m_symbolData = symbolData
        --小块索引
        symbolNode.m_index = index
    end
    
end

--拆分显示钱数的字符串
function OrcaCaptainWheelView:splitCoinsLab(coins)
    local str = util_formatCoinsLN(coins, 3) 
    if str == nil or type(str) ~= "string" then
        return {}
    end

    local strArray = {}

    local strLen = string.len( str )
    local index = 0
    for i=1,strLen do
        local charStr =  string.sub(str,i,i)
        table.insert( strArray, charStr )
        index = index + 1
    end

    return strArray,index
end

function OrcaCaptainWheelView:showSplitCoins(Array,splitNum,symbolNode)

    for i=1,6 do
        local str = Array[i] or ""
        if symbolNode:findChild("m_lb_coins_0_"..i) then
            symbolNode:findChild("m_lb_coins_0_"..i):setString(tostring(str))
        end
        if symbolNode:findChild("m_lb_coins_1_"..i) then
            symbolNode:findChild("m_lb_coins_1_"..i):setString(tostring(str))
        end
    end

end

function OrcaCaptainWheelView:setFreeSpinNum(num,symbolNode)
    if symbolNode:findChild("m_lb_num") then
        symbolNode:findChild("m_lb_num"):setString(num)
    end
end

function OrcaCaptainWheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "FEATURE" then
            
            local userMoneyInfo = param[3]
            self.m_machine.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            if spinData.result.freespin.freeSpinsTotalCount == 0 then
                self.m_machine:setLastWinCoin(spinData.result.winAmount)
            else
                self.m_machine:setLastWinCoin(spinData.result.freespin.fsWinCoins)
            end
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            self:recvBaseData(spinData.result)
        end
    end
end

--[[
    数据发送
]]
function OrcaCaptainWheelView:sendData()
    
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT,betLevel = nil}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--[[
    接收数据
]]
function OrcaCaptainWheelView:recvBaseData(featureData)
    self.m_featureData = featureData
    self.m_isWaiting = false

    local selfData = featureData.selfData
    self.m_randWheelIndex = selfData.wheelIndex + 1
    local wheelResult = selfData.wheelResult
    self.m_machine:setRecvData(wheelResult)
    local freespin = featureData.freespin or {}
    self.m_machine.m_runSpinResultData.p_fsWinCoins = freespin.fsWinCoins or 0            -- fs 累计赢钱数量
    self.m_machine.m_runSpinResultData.p_selfMakeData = selfData
    self.m_machine.m_runSpinResultData.p_features = featureData.features
    if wheelResult[2] == "free" then
        self.m_machine:bonusOverAddFreespinEffect(featureData)
    end
    if wheelResult[2] == "jackpot" then
        self.m_machine:bonusOverAddColorfulEffect(featureData)
    end
    self:checkNeedNearMiss(featureData)
    -- 设置轮盘功能滚动结束停止位置
    if self.m_isNearMiss then
        if self.m_nearMissWheelIndex ~= 0 then
            self.m_wheel:recvData(self.m_nearMissWheelIndex)
        else
            self.m_wheel:recvData(self.m_randWheelIndex)
        end
    else
        self.m_wheel:recvData(self.m_randWheelIndex)
    end
    
end

function OrcaCaptainWheelView:checkNeedNearMiss(featureData)
    self.m_nearMissWheelIndex = 0
    
    local probability = 30
    local selfData = featureData.selfData
    local wheelResult = selfData.wheelResult
    --前一个奖励
    local preIndex = self.m_randWheelIndex - 1
    if preIndex <= 0 then
        preIndex = self.m_wheelSumIndex
    end
    --后一个奖励
    local nextIndex = self.m_randWheelIndex + 1
    if nextIndex > self.m_wheelSumIndex then
        nextIndex = 1
    end

    
    local nearMissList = self:checkNeedNearMissList(preIndex,nextIndex,wheelResult)
    

    local isNotice = (math.random(1, 100) <= probability) 
    if isNotice and #nearMissList > 0 then
        local changeIndex = math.random(1,#nearMissList)
        self.m_isNearMiss = true
        self.m_nearMissWheelIndex = nearMissList[changeIndex] or self.m_randWheelIndex
    end
end

function OrcaCaptainWheelView:checkNeedNearMissList(preIndex,nextIndex,wheelResult)
    local changeIndex = 0
    local nearMissList = {}
    local preRewardData = self.m_bigWheelData[preIndex]
    local nextRewardData = self.m_bigWheelData[nextIndex]
    --对比前后两个奖励
    if wheelResult[2] == "free" then
        if preRewardData[2] == "free" then      
            if tonumber(wheelResult[1]) >  tonumber(preRewardData[1]) then
                nearMissList[#nearMissList + 1] = preIndex
            end
        elseif preRewardData[2] == "jackpot" then

        else
            nearMissList[#nearMissList + 1] = preIndex
        end

        if nextRewardData[2] == "free" then
            if tonumber(wheelResult[1]) >  tonumber(nextRewardData[1]) then
                nearMissList[#nearMissList + 1] = nextIndex
            end
        elseif nextRewardData[2] == "jackpot" then

        else
            nearMissList[#nearMissList + 1] = nextIndex
        end
    elseif wheelResult[2] == "jackpot" then
        if preRewardData[2] == "free" then      
            
        elseif preRewardData[2] == "jackpot" then

        else
            nearMissList[#nearMissList + 1] = preIndex
        end

        if nextRewardData[2] == "free" then
            
        elseif nextRewardData[2] == "jackpot" then

        else
            nearMissList[#nearMissList + 1] = nextIndex
        end
    else
        if preRewardData[2] == "free" then      
            
        elseif preRewardData[2] == "jackpot" then

        else
            if tonumber(wheelResult[1]) >  tonumber(preRewardData[1]) then
                nearMissList[#nearMissList + 1] = preIndex
            end
        end

        if nextRewardData[2] == "free" then
            
        elseif nextRewardData[2] == "jackpot" then

        else
            if tonumber(wheelResult[1]) >  tonumber(nextRewardData[1]) then
                nearMissList[#nearMissList + 1] = nextIndex
            end
        end
    end
    return nearMissList
end

--[[
    开启计时器
]]
function OrcaCaptainWheelView:startSchedule()
    self.m_scheduleNode:onUpdate(function(dt)
        -- if globalData.slotRunData.gameRunPause then
        --     return
        -- end

        -- --刷新速度
        -- self:updateSpeed(dt)

        --计算偏移量
        local offset = dt * MIN_SPEED

        --当前的偏转角度
        self.m_curRotation  = (self.m_curRotation + offset) % 360

        self:findChild("Node_wheel"):setRotation(self.m_curRotation)

        -- if not self.m_isWaittingNetBack then
        --     self.m_rotationAfterNetBack  = self.m_rotationAfterNetBack + offset

        --     --判断是否停轮
        --     if self.m_direction == DIRECTION.CLOCK_WISE then
        --         if self.m_rotationAfterNetBack >= (360 - self.m_rotationOnNetBack) + 360 * self.m_needTurnNum + (self.m_endRotation - self.m_startRotation) then
        --             self:wheelDown()
        --         end
        --     else
        --         if self.m_rotationAfterNetBack >= (360 - self.m_rotationOnNetBack) + 360 * self.m_needTurnNum + (self.m_startRotation - self.m_endRotation) then
        --             self:wheelDown()
        --         end
        --     end
        -- end
    end)
end

return OrcaCaptainWheelView