-- 花车玩法
local SendDataManager = require "network.SendDataManager"
local PublicConfig = require "CalacasParadePublicConfig"
local CalacasParadeCarGameView = class("CalacasParadeCarGameView", util_require("Levels.BaseLevelDialog"))

-- 玩法状态
CalacasParadeCarGameView.GameState = {
    Normal  = 0,   --玩法还没开始
    Start   = 2,   --正在进行
    Request = 3,   --正在请求下次数据
    Over    = 4,   --spin完毕 没有次数玩法结束
}
-- 奖励类型
CalacasParadeCarGameView.RewardType = {
    Coins = "",
    Collect = "COLLECT",
    --彩金
}

function CalacasParadeCarGameView:initUI(_data)
    self.m_machine  = _data.machine
    --玩法数据
    self.m_initData = {}
    self.m_initData.carExtra   = _data.carExtra
    self.m_initData.ticketList = _data.ticketList
    self.m_initData.fnOver     = _data.fnOver

    self:setGameState(self.GameState.Normal)
    --花车尺寸
    self.m_carSize   = cc.size(900, 1000)
    --移动路径宽度
    self.m_pathWidth = (display.width+self.m_carSize.width)/self.m_machine.m_machineRootScale
    --移动时间
    self.m_moveTime  = 8

    self:createCsbNode("CalacasParade/CalacasParadeCarGame.csb")
    self:initTotalWinBar()
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CalacasParadeCarGameView:initSpineUI()
    self:initCarSpine()

    self:initCarGameViewByData()
end
--根据初始化数据刷新界面
function CalacasParadeCarGameView:initCarGameViewByData()
    -- 总赢钱
    local totalCoins = self.m_initData.carExtra.carWin or 0
    self:upDateTotalWinBarByData(totalCoins)
end

--添加玩法数据返回监听
function CalacasParadeCarGameView:onEnter()
    CalacasParadeCarGameView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
end
function CalacasParadeCarGameView:onExit()
    self:stopCarMoveSound()
    CalacasParadeCarGameView.super.onExit(self)
end

--开始玩法
function CalacasParadeCarGameView:startGame()
    self:setGameState(self.GameState.Normal)
    self:sendSelectData()
end
--结束玩法
function CalacasParadeCarGameView:endGame()
    self:setGameState(self.GameState.Over)
    self.m_machine:levelPerformWithDelay(self, 0.5, function()
        local totalCoins = self.m_initData.carExtra.carWin or 0
        self.m_initData.fnOver(totalCoins)
    end)
end
--玩法状态
function CalacasParadeCarGameView:setGameState(_state)
    self.m_gameState = _state
end

--车队
function CalacasParadeCarGameView:initCarSpine()
    self.m_carCsbList = {}
    for _index=1,4 do
        --花车工程
        local csb = util_createAnimation("CalacasParade_hc.csb")
        self:findChild("Node_car"):addChild(csb)
        csb:setVisible(false)
        --花车spine
        local spineParent = csb:findChild("Node_spine")
        local spinePosNode = csb:findChild(string.format("position_%d", _index))
        local spineName = string.format("CalacasParade_huache%d", _index)
        csb.m_spine = util_spineCreate(spineName, true, true)
        spineParent:addChild(csb.m_spine)
        csb:setPosition(util_convertToNodeSpace(spinePosNode, spineParent))
        --花车奖励
        csb.m_rewardIndex   = 0    --会被收集的奖励索引
        csb.m_rewardCsbList = {}
        
        self.m_carCsbList[_index] = csb
    end
end
--车队-整体的循环的初始化
function CalacasParadeCarGameView:playCarSpineLoop(_limitCarIndex, _dataIndex)
    local carIndex  = _limitCarIndex
    while carIndex == _limitCarIndex do
        carIndex = math.random(1, #self.m_carCsbList)
    end
    if 1 == _dataIndex then
        self:setGameState(self.GameState.Start)
    end
    self:playCarSpine_start(carIndex, _dataIndex)
end
--车队-单个花车-进入
function CalacasParadeCarGameView:playCarSpine_start(_carIndex, _dataIndex)
    self:playCarMoveSound()
    local csb = self.m_carCsbList[_carIndex]
    csb:stopAllActions()
    self:resetCarReward(_carIndex, _dataIndex, self:getRewardData(_dataIndex))
    self:playRewardLightAnim(_carIndex, nil)
    local startX  = self.m_pathWidth/2
    local targetX = 0
    csb:setPositionX(startX)
    csb:setVisible(true)
    local actList = {}
    table.insert(actList, cc.MoveTo:create(self.m_moveTime*0.5, cc.p(targetX, 0)))
    table.insert(actList, cc.CallFunc:create(function()
        self:playCarSpine_collect(_carIndex, _dataIndex)
    end))

    util_spinePlay(csb.m_spine, "idleframe2", true)
    csb:runAction(cc.Sequence:create(actList))
end
--车队-单个花车-收集奖励
function CalacasParadeCarGameView:playCarSpine_collect(_carIndex, _dataIndex)
    --隐藏原本的奖励
    local csb = self.m_carCsbList[_carIndex]
    local rewardCsb = csb.m_rewardCsbList[csb.m_rewardIndex]
    rewardCsb:setVisible(false)
    --隐藏跑马灯
    self:stopRewardLightAnim(_carIndex)
    --创建临时飞行奖励
    local bonus2Index = self:getCurTicketBonus2Index()
    local rewardData  = self:getRewardData(_dataIndex)
    local jpIndex = self.m_machine.JackpotTypeToIndex[rewardData.type]
    local bJackpot = nil ~= jpIndex
    local parent = self:findChild("Node_reward")
    local flyNode = self:createRewardCsb(bonus2Index, rewardData)
    parent:addChild(flyNode)
    local startPos = util_convertToNodeSpace(rewardCsb, parent)
    flyNode:setPosition(startPos)
    --飞行动作
    local actList = {}
    table.insert(actList, cc.DelayTime:create(24/60))
    local endPos = self:getTotalWinBarCollectEndPos(parent)
    table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(42/60, endPos), 4))
    table.insert(actList, cc.CallFunc:create(function()
        --收集栏反馈
        self:playTotalWinBarCollectAnim(nil)
        --金币
        if "" == rewardData.type then
            gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_collectFeedback)
            if self.m_machine:isHeightBonus1Coins(rewardData.coins) then
                gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_maxRdCollectFeedback)
            end
            self:totalWinBarJumpCoins(rewardData.coins)
        --彩金
        elseif bJackpot then
            gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_jpCollectFeedback)
            self:totalWinBarJumpCoins(rewardData.coins)
            self.m_machine:levelPerformWithDelay(self, 39/60, function()
                self.m_machine:showJackpotView(jpIndex, rewardData.coins, function()
                    self:playCarSpine_exit(_carIndex, _dataIndex)
                end)
            end)
        else
        end
    end))
    table.insert(actList, cc.RemoveSelf:create())

    if "" == rewardData.type then
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_collect)
    elseif bJackpot then
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_jpCollect)
    else
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_endCollect)
    end

    flyNode:runCsbAction("shouji", false)
    flyNode:runAction(cc.Sequence:create(actList))

    if not bJackpot then
        self:playCarSpine_exit(_carIndex, _dataIndex)
    end
end
--车队-单个花车-退场
function CalacasParadeCarGameView:playCarSpine_exit(_carIndex, _dataIndex)
    local csb = self.m_carCsbList[_carIndex]
    local actList = {}
    local targetX  = -self.m_pathWidth/2
    local moveTime = self.m_moveTime*0.5

    local actList = {}
    table.insert(actList, cc.Spawn:create(
        cc.MoveTo:create(moveTime, cc.p(targetX, 0)),
        cc.Sequence:create(
            cc.DelayTime:create(moveTime*0.5),
            cc.CallFunc:create(function()
                self:playCarSpine_over(_carIndex, _dataIndex)
            end)
        )
    ))
    table.insert(actList, cc.CallFunc:create(function()
        csb:setVisible(false)
    end))

    csb:runAction(cc.Sequence:create(actList))
end
--车队-单个花车-流程结束(下一辆进入 当前车票结束 所有车票结束)
function CalacasParadeCarGameView:playCarSpine_over(_carIndex, _dataIndex)
    local nextDataIndex = _dataIndex+1
    local nextReward = self:getRewardData(nextDataIndex)
    if not nextReward then
        --单张车票结束
        if self.m_initData.carExtra.currentTicket < self.m_initData.carExtra.TotalTicket then
            self:setGameState(self.GameState.Normal)
            self:sendSelectData()
        --全部车票结束
        else
            self:stopCarMoveSound()
            self:endGame()
        end
    --下一辆进场
    else
        self:playCarSpineLoop(_carIndex, nextDataIndex)
    end
end

--车队-单个花车-奖励
function CalacasParadeCarGameView:createRewardCsb(_bonus2Index, _rewardData)
    local csb = nil
    --金币
    if "" == _rewardData.type then
        local coins = _rewardData.coins
        csb = util_createAnimation("CalacasParade_hc_reward_1.csb")
        csb:findChild(string.format("ticket_%d", _bonus2Index)):setVisible(true)
        local parent   = csb:findChild("Node_coins")
        local coinsCsb = util_createAnimation("CalacasParade_hc_coins.csb")
        parent:addChild(coinsCsb)
        local bHeight = self.m_machine:isHeightBonus1Coins(coins)
        local labName = bHeight and "m_lb_coins_2" or "m_lb_coins_1"
        local labCoins = coinsCsb:findChild(labName)
        labCoins:setString(util_formatCoins(coins, 3))
        self:updateLabelSize({label=labCoins,  sx=1, sy=1}, 161)
        labCoins:setVisible(true)
        --区分每辆车的shouji光效
        csb:findChild(string.format("Node_%d", _bonus2Index)):setVisible(true)
    --彩金
    elseif nil ~= self.m_machine.JackpotTypeToIndex[_rewardData.type] then
        csb = util_createAnimation("CalacasParade_hc_reward_2.csb")
        local jpIndex = self.m_machine.JackpotTypeToIndex[_rewardData.type]
        local diName = string.format("jackpot_di_%d", jpIndex)
        for i,_node in ipairs(csb:findChild("Node_jackpot_di"):getChildren()) do
            local nodeName = _node:getName()
            _node:setVisible(diName == nodeName)
        end
        local ziName = string.format("jackpot_zi_%d", jpIndex)
        for i,_node in ipairs(csb:findChild("Node_jackpot_zi"):getChildren()) do
            local nodeName = _node:getName()
            _node:setVisible(ziName == nodeName)
        end
    --游戏结束
    else
        csb = util_createAnimation("CalacasParade_hc_reward_1.csb")
        csb:findChild("Node_gameOver"):setVisible(true)
    end
    csb.m_rewardData = _rewardData
    --跑马灯
    csb.m_rewardLight = util_createAnimation("CalacasParade_hc_reward_3.csb")
    csb:findChild("Node_light"):addChild(csb.m_rewardLight)
    csb.m_rewardLight:setVisible(false)

    return csb
end
--车队-单个花车-奖励-重置
function CalacasParadeCarGameView:resetCarReward(_carIndex, _dataIndex, _rewardData)
    local csb = self.m_carCsbList[_carIndex]
    local bonus2Index = self:getCurTicketBonus2Index()
    --删除
    csb.m_rewardCsbList = {}
    local rewardParent = csb:findChild("Node_reward")
    rewardParent:removeAllChildren()
    --随机
    local maxCount    = 3
    local rewardIndex = math.random(1, maxCount)
    csb.m_rewardIndex = rewardIndex
    -- 花车玩法中前4辆车不要有complete，并且同一辆车最多只有一个complete
    local fnCheckRandomData = function(_data, _dataList)
        if _dataIndex <= 4 and _data.type == self.RewardType.Collect then
            return false
        end
        for k,v in pairs(_dataList) do
            if _data.type == v.type then
                if _data.type == self.RewardType.Coins then
                    if _data.coins == v.coins then
                        return false
                    end
                else
                    return false
                end 
            end
        end
        return true
    end
    local dataList = {}
    dataList[rewardIndex] = _rewardData
    for i=1,maxCount do
        if i ~= rewardIndex then
            local randomData = self:getRandomRewardData(bonus2Index)
            while not fnCheckRandomData(randomData, dataList)do
                randomData = self:getRandomRewardData(bonus2Index)
            end
            dataList[i] = randomData
        end
    end
    --附加
    for i,_data in ipairs(dataList) do
        local rewardCsb = self:createRewardCsb(bonus2Index, _data)
        local posNode = csb:findChild(string.format("reward_%d_%d", _carIndex, i))
        rewardParent:addChild(rewardCsb)
        rewardCsb:setPosition(util_convertToNodeSpace(posNode, rewardParent))
        csb.m_rewardCsbList[i] = rewardCsb
        rewardCsb:runCsbAction("idle", true)
    end
end
--车队-单个花车-奖励跑马灯
function CalacasParadeCarGameView:playRewardLightAnim(_carIndex, _lastPos)
    local csb = self.m_carCsbList[_carIndex]
    local rewardCsbList = csb.m_rewardCsbList
    --固定循环
    local newPos = (_lastPos and _lastPos < 3) and _lastPos+1 or 1
    --区分当前奖励类型
    local rewardCsb  = rewardCsbList[newPos]
    local rewardData = rewardCsb.m_rewardData
    local bReward2   = nil ~= self.m_machine.JackpotTypeToIndex[rewardData.type]
    local lightCsb = rewardCsb.m_rewardLight
    rewardCsb:stopAllActions()
    lightCsb:stopAllActions()
    lightCsb:setVisible(true)
    --播放一遍后 延时21/60播下一个 飞行奖励时关闭轮播
    local actList = {}
    table.insert(actList, cc.DelayTime:create(21/60))
    table.insert(actList, cc.CallFunc:create(function()
        lightCsb:setVisible(false)
    end))
    -- table.insert(actList, cc.DelayTime:create(21/60))
    table.insert(actList, cc.CallFunc:create(function()
        self:playRewardLightAnim(_carIndex, newPos)
    end))
    lightCsb:findChild("light_1"):setVisible(not bReward2)
    lightCsb:findChild("light_2"):setVisible(bReward2)
    lightCsb:runCsbAction("idle", false)
    lightCsb:runAction(cc.Sequence:create(actList))
    --整个奖励缩放
    local actList2 = {}
    table.insert(actList2, cc.ScaleTo:create(9/60, 1.3))
    table.insert(actList2, cc.ScaleTo:create(12/60, 1))
    rewardCsb:runAction(cc.Sequence:create(actList2))
end
--车队-单个花车-奖励跑马灯-暂停
function CalacasParadeCarGameView:stopRewardLightAnim(_carIndex)
    local csb = self.m_carCsbList[_carIndex]
    for i,_rewardCsb in ipairs(csb.m_rewardCsbList) do
        _rewardCsb:stopAllActions()
        local lightCsb = _rewardCsb.m_rewardLight
        lightCsb:stopAllActions()
        util_setCsbVisible(lightCsb, false)
    end
end
--车队-单个花车-移动音效
function CalacasParadeCarGameView:playCarMoveSound()
    if self.m_soundIdCarMove then
        return
    end
    self.m_soundIdCarMove = gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_move, true)
end
function CalacasParadeCarGameView:stopCarMoveSound()
    if self.m_soundIdCarMove then
        gLobalSoundManager:stopAudio(self.m_soundIdCarMove)
        self.m_soundIdCarMove = nil
    end
end

--赢钱栏
function CalacasParadeCarGameView:initTotalWinBar()
    local parent = self:findChild("Node_totalwin")
    self.m_totalWinBar = util_createAnimation("CalacasParade_hc_totalwin.csb")
    parent:addChild(self.m_totalWinBar)
    self.m_totalWinBar:runCsbAction("idle")

    self.m_totalWinBar.m_totalCoins  = 0
    self.m_totalWinBar.m_targetCoins = 0

    self:initTicketList()
end
--赢钱栏-玩法数据初始化
function CalacasParadeCarGameView:upDateTotalWinBarByData(_totalCoins)
    self.m_totalWinBar.m_targetCoins = _totalCoins
    self:upDateTotalWinBarCoins(_totalCoins)
end
--赢钱栏-飞行终点
function CalacasParadeCarGameView:getTotalWinBarCollectEndPos(_parent)
    local posNode = self.m_totalWinBar:findChild("m_lb_coins")
    return util_convertToNodeSpace(posNode, _parent)
end
--赢钱栏-收集反馈
function CalacasParadeCarGameView:playTotalWinBarCollectAnim(_fun)
    self.m_totalWinBar:runCsbAction("shouji", false, _fun)
end
--赢钱栏-跳钱
function CalacasParadeCarGameView:totalWinBarJumpCoins(_addCoins)
    local labCoins = self.m_totalWinBar:findChild("m_lb_coins")
    labCoins:stopAllActions()

    local jumpTime                    = 1
    local curCoins                    = self.m_totalWinBar.m_targetCoins
    local newTargetCoins              = curCoins + _addCoins
    self.m_totalWinBar.m_targetCoins  = newTargetCoins
    local coinRiseNum =  _addCoins / (jumpTime * 60)
    local str         = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum       = tonumber(str)
    coinRiseNum       = math.ceil(coinRiseNum)

    self.m_updateAction = schedule(labCoins, function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < newTargetCoins and curCoins or newTargetCoins
        self:upDateTotalWinBarCoins(curCoins)
        if curCoins >= newTargetCoins then
            labCoins:stopAllActions()
        end
    end,0.008)
end
--赢钱栏-刷新金额
function CalacasParadeCarGameView:upDateTotalWinBarCoins(_totalCoins)
    self.m_totalWinBar.m_totalCoins  = _totalCoins
    local labCoins = self.m_totalWinBar:findChild("m_lb_coins")
    local sCoins = _totalCoins <= 0 and "" or util_formatCoins(_totalCoins, 50)
    labCoins:setString(sCoins)
    self:updateLabelSize({label=labCoins, sx=1, sy=1}, 553)
end


--赢钱栏-车票栏
function CalacasParadeCarGameView:initTicketList()
    self.m_tickeList  = {}
    local index = 1
    for _bonus2Index=1,4 do
        local count = self.m_initData.ticketList[_bonus2Index] or 0
        if count > 0 then
            local parent = self.m_totalWinBar:findChild(string.format("4_%d", index))
            local csb = util_createAnimation("CalacasParade_hc_ticket.csb")
            parent:addChild(csb)
            csb:findChild(string.format("ticket_%d", _bonus2Index)):setVisible(true)
            csb.m_bonus2Index = _bonus2Index
            table.insert(self.m_tickeList, csb)
            index = index+1
        end
    end
    self:upDateTicketListDark()
end
--赢钱栏-车票栏-刷新置灰状态
function CalacasParadeCarGameView:upDateTicketListDark()
    local bonus2Index = self:getCurTicketBonus2Index()
    -- idleframe
    for i,_csb in ipairs(self.m_tickeList) do
        local bDark = bonus2Index and _csb.m_bonus2Index < bonus2Index
        local idleName = bDark and "darkidle" or "idleframe"
        _csb:findChild("ticket_dark"):setVisible(bDark)
        _csb:runCsbAction(idleName, false)
    end
end
--赢钱栏-车票栏-获取一个类型的车票
function CalacasParadeCarGameView:getTicketCsbByBonus2Index(_bonus2Index)
    for i,_csb in ipairs(self.m_tickeList) do
        if _csb.m_bonus2Index == _bonus2Index then
            return _csb
        end
    end
end


--赢钱栏-车票栏-飘出一张车票
function CalacasParadeCarGameView:playTicketStart(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_ticketStart)
    local maskCtr = self.m_machine.m_maskCtr
    maskCtr:playLevelMaskStart(0, function()
        local curBonus2Index  = self:getCurTicketBonus2Index()
        local lastBonus2Index = self:getCurTicketBonus2Index(self.m_initData.carExtra.currentTicket-1)
        local bSame = lastBonus2Index and curBonus2Index == lastBonus2Index

        local parent = self:findChild("Node_reward")
        local tempSymbol = util_createView("CalacasParadeSrc.CalacasParadeTempSymbol", {machine=self.m_machine})
        local ticketSymbolType = self.m_machine:getCalacasParadeBonus2SymbolType(curBonus2Index)
        tempSymbol:changeSymbolCcb(ticketSymbolType)
        parent:addChild(tempSymbol)
        tempSymbol:runAnim("actionframe3", false, function()
            tempSymbol:removeTempSlotsNode()
            maskCtr:playLevelMaskOver()
            self.m_machine:levelPerformWithDelay(self, 0.5, function()
                gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_ticketBar_light)
                local ticketCsb = self:getTicketCsbByBonus2Index(curBonus2Index)
                ticketCsb:runCsbAction("actionframe", false)
                if not bSame and lastBonus2Index then
                    local lastTicketCsb = self:getTicketCsbByBonus2Index(lastBonus2Index)
                    lastTicketCsb:findChild("ticket_dark"):setVisible(true)
                    lastTicketCsb:runCsbAction("darkover", false)
                end
                _fun()
            end)
        end)
    end)
end


--数据交互-发送
function CalacasParadeCarGameView:sendSelectData()
    if self.m_gameState ~= self.GameState.Normal then
        return
    end
    self:setGameState(self.GameState.Request)
    local messageData = {}
    messageData.msg  = MessageDataType.MSG_BONUS_SELECT
    messageData.data = {}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end
--数据交互-返回
function CalacasParadeCarGameView:featureResultCallFun(_params)
    if _params[1] == true then
        local spinData = _params[2]
        if spinData.action == "FEATURE" then
            local result = spinData.result
            local selfData = result.selfData
            if selfData.carExtra then
                local sMsg = string.format("[CalacasParadeCarGameView:featureResultCallFun] %s", cjson.encode(result))
                print(sMsg)
                release_print(sMsg)
                self.m_initData.carExtra  = selfData.carExtra
                self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
                self.m_machine:operaWinCoinsWithSpinResult(_params)
                self:playTicketStart(function()
                    self:playCarSpineLoop(nil, 1)
                end)
            end
        end
    else
        gLobalViewManager:showReConnect()
    end   
end
--数据处理-获取当前车票的bonus2Index
function CalacasParadeCarGameView:getCurTicketBonus2Index(_index)
    local index = _index or self.m_initData.carExtra.currentTicket
    local list  = self.m_initData.carExtra.carList
    local bonus2Index = list[index]
    return bonus2Index
end
--数据处理-获取当前车票上指定索引的奖励类型
function CalacasParadeCarGameView:getRewardData(_dataIndex)
    local reward = {}
    reward.type  = ""  -- "" "JackpotType" "COLLECT"
    reward.coins = 0

    local typeList   = self.m_initData.carExtra.typeList or {}
    local creditList = self.m_initData.carExtra.creditList or {}
    reward.type = typeList[_dataIndex]
    if not reward.type then
        return nil
    end

    --金币
    if "" == reward.type then
        reward.coins = tonumber(creditList[_dataIndex])
    --彩金
    elseif nil ~= self.m_machine.JackpotTypeToIndex[reward.type] then
        reward.coins = tonumber(creditList[_dataIndex])
    --游戏结束
    else
        reward.type  = self.RewardType.Collect  -- "" "JackpotType" "COLLECT"
    end
    return reward
end
--数据处理-随机奖励
function CalacasParadeCarGameView:getRandomRewardData(_bonus2Index)
    local reward = {}
    reward.type  = ""  -- "" "JackpotType" "COLLECT"
    reward.coins = 0

    local sMultip = self.m_machine.m_configData:getBonus2RandomReward(_bonus2Index)
    local iMultip = tonumber(sMultip)
    --金币
    if iMultip and iMultip > 0 then
        reward.type  = ""
        reward.coins = iMultip * globalData.slotRunData:getCurTotalBet()
    --彩金
    elseif nil ~= self.m_machine.JackpotTypeToIndex[sMultip] then
        reward.type  = sMultip
    --游戏结束
    else
        reward.type  = self.RewardType.Collect
    end
    return reward
end

return CalacasParadeCarGameView