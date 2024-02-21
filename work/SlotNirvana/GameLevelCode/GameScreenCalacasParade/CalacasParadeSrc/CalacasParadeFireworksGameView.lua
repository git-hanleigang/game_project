--[[
    烟花玩法
]]
local SendDataManager = require "network.SendDataManager"
local PublicConfig = require "CalacasParadePublicConfig"
local CalacasParadeFireworksGameView = class("CalacasParadeFireworksGameView", util_require("Levels.BaseLevelDialog"))


-- 玩法状态
CalacasParadeFireworksGameView.GameState = {
    Normal  = 0,   --有次数 玩法还没开始
    Idle    = 1,   --有次数 可以spin
    Start   = 2,   --正在spin
    Request = 3,   --spin完毕 正在请求下次数据
    Over    = 4,   --spin完毕 没有次数玩法结束
}

function CalacasParadeFireworksGameView:initUI(_data)
    self.m_machine  = _data.machine
    --玩法数据
    self.m_initData = {}
    self.m_initData.fireworkExtra = _data.fireworkExtra  
    self.m_initData.fnOver = _data.fnOver
    self:setGameState(self.GameState.Normal)
    
    self:createCsbNode("CalacasParade/CalacasParadeFireworkGame.csb")
    self:initFireworksTotalWinBar()
    self.m_wenanCsb = util_createAnimation("CalacasParade_yh_wenan.csb")
    self:findChild("Node_wenan"):addChild(self.m_wenanCsb)

    self:addFireworksClickCall()
end
--初始化spine动画
function CalacasParadeFireworksGameView:initSpineUI()
    self:initFireworksSpine()

    self:initFireworksGameViewByData()
end
--根据初始化数据刷新界面
function CalacasParadeFireworksGameView:initFireworksGameViewByData()
    -- 基底和总赢钱
    local baseCoins  = self.m_initData.fireworkExtra.basic_credit or 0
    local totalCoins = self.m_initData.fireworkExtra.win_credit   or 0
    local lastWinCoins = self:getFireworksCurWinCoins()
    totalCoins = math.max(0, totalCoins-lastWinCoins)
    self:upDateTotalWinBarCoins(nil, totalCoins)
end

--添加玩法数据返回监听
function CalacasParadeFireworksGameView:onEnter()
    CalacasParadeFireworksGameView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
end



--开始玩法
function CalacasParadeFireworksGameView:startGame()
    self:setGameState(self.GameState.Idle)
end
--结束玩法
function CalacasParadeFireworksGameView:endGame()
    self:setGameState(self.GameState.Over)
    self.m_machine:levelPerformWithDelay(self, 0.5, function()
        local totalCoins = self.m_initData.fireworkExtra.win_credit   or 0
        self.m_initData.fnOver(totalCoins)
    end)
end
--玩法状态
function CalacasParadeFireworksGameView:setGameState(_state)
    self.m_gameState = _state
end


--烟花spine
function CalacasParadeFireworksGameView:initFireworksSpine()
    self.m_selectIndex = 1
    --烟花
    self.m_fireworksSpine = util_spineCreate("CalacasParade_pick", true, true)
    self:findChild("Node_spine"):addChild(self.m_fireworksSpine, 100)
    self:runFireworksSpineAnim("idleframe", true)
    --烟花-爆炸效果
    self.m_fireworksBgSpine = util_spineCreate("CalacasParade_yanhua", true, true)
    self:findChild("Node_spine"):addChild(self.m_fireworksBgSpine, 1000)
    self.m_fireworksBgSpine:setVisible(false)
    --烟花-奖励-未选中
    self.m_fireworksReward = {}
    for _index=1,3 do
        local boneName = string.format("wenzi%d", _index)
        local csb = util_createAnimation("CalacasParade_yh_reward.csb")
        util_spinePushBindNode(self.m_fireworksSpine, boneName, csb)
        self.m_fireworksReward[_index] = csb
        csb:setVisible(false)
        csb:findChild("root"):setRotation(-45+(_index-1)*45)
    end
    --烟花-奖励-选中
    self.m_selectRewardCsb = util_createAnimation("CalacasParade_yh_reward.csb")
    self:findChild("Node_reward"):addChild(self.m_selectRewardCsb)
    self.m_selectRewardCsb:setVisible(false)
end
--烟花spine-时间线
function CalacasParadeFireworksGameView:runFireworksSpineAnim(_name, _bLoop, _fun)
    util_spinePlay(self.m_fireworksSpine, _name, _bLoop)
    if nil ~= _fun then
        util_spineEndCallFunc(self.m_fireworksSpine,  _name, _fun)
    end
end
--烟花spine-点击后发射一支
function CalacasParadeFireworksGameView:playFireworksActionframe(_fireworksIndex)
    if self.m_gameState ~= self.GameState.Idle then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_clickFireworks)
    self:setGameState(self.GameState.Start)

    self:playFireworksRewardDark(_fireworksIndex, function()
    end)
    local animIndex = _fireworksIndex
    local animName  = string.format("actionframe%d", animIndex)
    --发射效果
    self:runFireworksSpineAnim(animName, false, function()
    end)
    --爆炸效果
    local fireworksBgAnimName = animName
    if self.m_initData.fireworkExtra.enfFlag then
        fireworksBgAnimName = string.format("actionframe%d_2", animIndex)
    end
    self.m_fireworksBgSpine:setVisible(true)
    util_spinePlay(self.m_fireworksBgSpine, fireworksBgAnimName, false)
    util_spineEndCallFunc(self.m_fireworksBgSpine,  fireworksBgAnimName, function()
        self.m_fireworksBgSpine:setVisible(false)
    end)
    --关键帧 奖励出现和收集
    self.m_machine:levelPerformWithDelay(self, 81/30, function()
        self:playFireworksRewardCollect(function()
            self:playFireworksActionframeCall()
        end)
    end)
end
--烟花spine-单次发射结束回调
function CalacasParadeFireworksGameView:playFireworksActionframeCall()
    --还未结束
    if not self.m_initData.fireworkExtra.enfFlag then
        self:sendSelectData()
    --已经结束
    else
        self:endGame()
    end
end
--烟花spine-奖励-刷新展示
function CalacasParadeFireworksGameView:upDateFireworksRewardCsb(_rewardCsb, _rewardData)
    local bCoins = _rewardData ~= 0
    local labCoins = _rewardCsb:findChild("m_lb_coins")
    labCoins:setVisible(bCoins)
    _rewardCsb:findChild("Node_gameOver"):setVisible(not bCoins)
    if bCoins then
        local sCoins = util_formatCoins(_rewardData, 3)
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins, sx=1, sy=1}, 161)
    end
end
--烟花spine-奖励-压暗
function CalacasParadeFireworksGameView:playFireworksRewardDark(_selectIndex, _fun)
    --[[
        首次    双金币
        非结束时 1个collect 1个金币
        结束    双金币
    ]]
    local rewardIndex = self.m_initData.fireworkExtra.currentFirework or 1
    local baseCoins   = self.m_initData.fireworkExtra.basic_credit or 0
    local randomRewardList = {}
    table.insert(randomRewardList, baseCoins)
    if self.m_initData.fireworkExtra.enfFlag or 1 == rewardIndex then
        table.insert(randomRewardList, baseCoins)
    else
        table.insert(randomRewardList, 0)
    end
    for _index,csb in ipairs(self.m_fireworksReward) do
        if _index ~= _selectIndex then
            local rewardData  = table.remove(randomRewardList, math.random(1, #randomRewardList))
            self:upDateFireworksRewardCsb(csb, rewardData)
            csb:runCsbAction("darkstart", false)
            csb:setVisible(true)
        end
    end
    self.m_machine:levelPerformWithDelay(self, 30/60, _fun)
end
--烟花spine-奖励-选中的奖励飞行收集
function CalacasParadeFireworksGameView:playFireworksRewardCollect(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_rdStart)
    local randomPos  = cc.p(math.random(-20, 20), math.random(-20, 20))
    local rewardData = self:getFireworksCurWinCoins()
    self:upDateFireworksRewardCsb(self.m_selectRewardCsb, rewardData)
    self.m_selectRewardCsb:setPosition(randomPos)
    self.m_selectRewardCsb:setVisible(true)

    self.m_selectRewardCsb:runCsbAction("start", false, function()
        --结束了
        if 0 == rewardData then
            self.m_selectRewardCsb:runCsbAction("idle", true)
            _fun()
        --未结束
        else
            gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_rdCollect)
            local actList = {}
            local endPos = self:getTotalWinBarCollectEndPos(self.m_selectRewardCsb:getParent())
            table.insert(actList, cc.DelayTime:create(96/60))
            table.insert(actList, cc.MoveTo:create(24/60, endPos))
            table.insert(actList, cc.CallFunc:create(function()
                gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_rdCollectFeedback)
                self.m_selectRewardCsb:setVisible(false)
                local newTotalWinCoins = self.m_initData.fireworkExtra.win_credit or 0
                self:upDateTotalWinBarCoins(nil, newTotalWinCoins)
                self:playTotalWinBarCollectAnim(_fun)
            end))
            self.m_selectRewardCsb:runCsbAction("shouji", false)
            self.m_selectRewardCsb:runAction(cc.Sequence:create(actList))
        end
    end)
end
--烟花spine-复原界面
function CalacasParadeFireworksGameView:playFireworksSpineReset(_selectIndex, _fun)
    local offsetTime = (xcyy.SlotsUtil:getMilliSeconds() - self.m_lastSendTime) / 1000
    local delayTime = 1 - offsetTime
    self.m_machine:levelPerformWithDelay(self, delayTime, function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_fireworksReset)
        if 2 == self.m_initData.fireworkExtra.currentFirework then
            gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_rdFirstReset)
        end
        local animName = string.format("over%d", _selectIndex)
        self:runFireworksSpineAnim(animName, false, function()
            for _index,csb in ipairs(self.m_fireworksReward) do
                csb:setVisible(false)
            end
            self:runFireworksSpineAnim("start", false, function()
                self:runFireworksSpineAnim("idleframe", true)
                _fun()
            end)
        end)
    end)
end


--赢钱栏
function CalacasParadeFireworksGameView:initFireworksTotalWinBar()
    local parent = self:findChild("Node_totalwin")
    self.m_fireworksTotalWinBar = util_createAnimation("CalacasParade_yh_totalwin.csb")
    parent:addChild(self.m_fireworksTotalWinBar)
    self.m_fireworksTotalWinBar:runCsbAction("idle")
    local curBet = globalData.slotRunData:getCurTotalBet()
    self:upDateTotalWinBarCoins(curBet, 0)
end
--赢钱栏-刷新金额
function CalacasParadeFireworksGameView:upDateTotalWinBarCoins(_baseCoins, _totalCoins)
    if _baseCoins then
        self.m_fireworksTotalWinBar.m_baseCoins  = _baseCoins
        local labCoins = self.m_fireworksTotalWinBar:findChild("m_lb_coins_2")
        local sCoins = util_formatCoins(_baseCoins, 50)
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins, sx=1, sy=1}, 340)
    end
    if _totalCoins then
        self.m_fireworksTotalWinBar.m_totalCoins  = _totalCoins
        local labCoins = self.m_fireworksTotalWinBar:findChild("m_lb_coins_1")
        local sCoins = _totalCoins <= 0 and "" or util_formatCoins(_totalCoins, 50)
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins, sx=1, sy=1}, 587)
    end
end
--赢钱栏-飞行终点
function CalacasParadeFireworksGameView:getTotalWinBarCollectEndPos(_parent)
    local posNode = self.m_fireworksTotalWinBar:findChild("m_lb_coins_1")
    return util_convertToNodeSpace(posNode, _parent)
end
--赢钱栏-收集反馈
function CalacasParadeFireworksGameView:playTotalWinBarCollectAnim(_fun)
    self.m_fireworksTotalWinBar:runCsbAction("shouji", false, _fun)
end


--点击事件-注册
function CalacasParadeFireworksGameView:addFireworksClickCall()
    for i=1,3 do
        local fireworksIndex = i
        local clickNode = self:findChild( string.format("Panel_click%d", fireworksIndex) )
        clickNode:addTouchEventListener(function(sender, eventType)
            return self:clickFireworks(fireworksIndex, sender, eventType)
        end)
    end
end
--点击事件-触发
function CalacasParadeFireworksGameView:clickFireworks(_index, _sender, _eventType)
    if _eventType ~= ccui.TouchEventType.ended then
        return
    end
    if self.m_gameState ~= self.GameState.Idle then
        return
    end
    self.m_selectIndex = _index
    print("[CalacasParadeFireworksGameView:clickFireworks]", self.m_selectIndex)
    self:autoSpin()
end
--烟花-自动spin
function CalacasParadeFireworksGameView:autoSpin()
    self:playFireworksActionframe(self.m_selectIndex)
end

--数据交互-发送
function CalacasParadeFireworksGameView:sendSelectData()
    if self.m_gameState ~= self.GameState.Start then
        return
    end
    self:setGameState(self.GameState.Request)
    self.m_lastSendTime = xcyy.SlotsUtil:getMilliSeconds()
    local messageData = {}
    messageData.msg  = MessageDataType.MSG_BONUS_SELECT
    messageData.data = {}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end
--数据交互-返回
function CalacasParadeFireworksGameView:featureResultCallFun(_params)
    if _params[1] == true then
        local spinData = _params[2]
        if spinData.action == "FEATURE" then
            local result = spinData.result
            local selfData = result.selfData
            if selfData.fireworkExtra then
                local sMsg = string.format("[CalacasParadeFireworksGameView:featureResultCallFun] %s", cjson.encode(result))
                print(sMsg)
                release_print(sMsg)
                self.m_initData.fireworkExtra = selfData.fireworkExtra
                self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
                self.m_machine:operaWinCoinsWithSpinResult(_params)
                self:playFireworksSpineReset(self.m_selectIndex, function()
                    self:setGameState(self.GameState.Idle)
                end)
            end
        end
    else
        gLobalViewManager:showReConnect()
    end   
end

--数据处理-获取本次spin赢钱结果
function CalacasParadeFireworksGameView:getFireworksCurWinCoins()
    local coins = 0
    if not self.m_initData.fireworkExtra.enfFlag then
        local rewardIndex    = self.m_initData.fireworkExtra.currentFirework or 1
        local rewardDataList = self.m_initData.fireworkExtra.winList or {}
        coins = rewardDataList[rewardIndex] or 0
    end
    return coins
end

return CalacasParadeFireworksGameView