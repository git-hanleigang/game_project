---
--SoaringWealthJackpotView.lua

local SoaringWealthJackpotView = class("SoaringWealthJackpotView",util_require("Levels.BaseLevelDialog"))
local SoaringWealthMusicConfig = require "CodeSoaringWealthSrc.SoaringWealthMusicConfig"

SoaringWealthJackpotView.m_machine = nil

function SoaringWealthJackpotView:initUI(_machine)

    self:createCsbNode("SoaringWealth/JackpotBonus.csb")
    
    self.m_machine = _machine
    self:initData()

    self.m_baseBgSpine = util_spineCreate("GameScreenSoaringWealthBG",true,true)
    self:findChild("bg"):addChild(self.m_baseBgSpine)
    util_spinePlay(self.m_baseBgSpine,"idleframe4",true)

    self.m_bigRedNode = self:findChild("Node_BigHongbao")
    self.bigRedBagAni = util_createAnimation("SoaringWealth_JackpotBonus_dahongbao.csb")
    self.m_bigRedNode:addChild(self.bigRedBagAni)

    self.m_lightSpine = util_createAnimation("SoaringWealth_Collection_Longzhufankui.csb")
    self.m_bigRedNode:addChild(self.m_lightSpine)
    self.m_lightSpine:setVisible(false)

    for i=1, 5 do
        self.tblRewardNode[i] = util_createView("CodeSoaringWealthSrc.SoaringWealthJackpotRewardNode", self.m_machine, self, i)
        self.tblNodeCoins[i] = self:findChild("Node_Coin"..i)
        self.tblNodeCoins[i]:addChild(self.tblRewardNode[i])

        self.tblRedBagNode[i] = util_createView("CodeSoaringWealthSrc.SoaringWealthJackpotSmallRedBag", self.m_machine, self, i)
        self.tblNodeRed[i] = self:findChild("Node_Hongbao"..i)
        self.tblRedBagNode[i]:setVisible(false)
        self.tblNodeRed[i]:addChild(self.tblRedBagNode[i])
    end

    self.pickTipNode = util_createAnimation("SoaringWealth_JackpotBonus_PickTips.csb")
    self:findChild("Node_PickTips"):addChild(self.pickTipNode)

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function SoaringWealthJackpotView:initData()
    self.tblRewardNode = {}
    self.tblNodeCoins = {}
    self.tblRedBagNode = {}
    self.tblNodeRed = {}

    self.tblCilckRewardNum = 0
    self.m_endCallFunc = nil
    self.m_rewardList = nil
    self.m_chooseBonus = nil
    self.m_unChooseBonus = nil
end

function SoaringWealthJackpotView:resetData()
    self:setSmallRedClick(true)
    self.pickTipNode:setVisible(false)
    self.tblCilckRewardNum = 0
    self.m_isRunRemove = false
    self:refreshPickBonus()
    self:setRandomRewardList()
    self.tblClickRedState = {}
end

function SoaringWealthJackpotView:scaleJackpotMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function SoaringWealthJackpotView:setRandomRewardList()
    self.m_randomRewardList = {}
    local tblTemp = clone(self.m_rewardList)

    for i=#tblTemp, 1, -1 do
        local randomNum = math.random(1, #tblTemp)
        table.insert(self.m_randomRewardList, tblTemp[randomNum])
        table.remove(tblTemp, randomNum)
    end
end

function SoaringWealthJackpotView:refreshRewardNode(_rewardList, _chooseBonus, _unChooseBonus, _endCallFunc)
    self.m_rewardList = _rewardList
    self.m_chooseBonus = _chooseBonus
    self.m_unChooseBonus = _unChooseBonus
    self.m_endCallFunc = _endCallFunc
    self:resetData()
    self.bigRedBagAni:runCsbAction("idle", true)
    for i=1, 5 do
        self.tblRedBagNode[i]:setSmallBagClick(false)
        self.tblRewardNode[i]:setVisible(false)
        local delayTime = 1.0 + (i-1)*10/60
        performWithDelay(self.m_scWaitNode, function()
            if i == 1 then
                self.m_machine:resetMusicBg(nil, SoaringWealthMusicConfig.Music_JackpotBonus_Bg)
                gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_appearFiveCoins)
            end
            self.tblRewardNode[i]:refreshReward(_rewardList[i])
            self.tblRewardNode[i]:setVisible(true)
            self.tblRewardNode[i]:runCsbAction("chuxian", false, function()
                self.tblRewardNode[i]:runCsbAction("idle2", true)
                if i == 5 then
                    self:rewardToRedBag()
                end
            end)
        end, delayTime)
    end
end

function SoaringWealthJackpotView:rewardToRedBag()
    local delayTime = 0.5
    performWithDelay(self.m_scWaitNode, function()
        for i=1, 5 do
            self.tblRewardNode[i]:runCsbAction("weiyi", false)
            performWithDelay(self.m_scWaitNode, function()
                if i == 5 then
                    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_FiveCoinsMove)
                    self:moveToBigRedNode()
                end
            end, 15/60)
        end
    end, delayTime)
end

function SoaringWealthJackpotView:moveToBigRedNode()
    local actionDelayTime = 20/60
    for i=1, 5 do
        local targetPos = util_convertToNodeSpace(self.m_bigRedNode, self.tblNodeCoins[i])
        local particle = self.tblRewardNode[i]:findChild("Particle_1")
        particle:setPositionType(0)
        particle:setDuration(-1)
        particle:resetSystem()
        util_playMoveToAction(self.tblRewardNode[i],actionDelayTime,targetPos,function()
            particle:stopSystem()
            
            self.tblRewardNode[i]:findChild("Node_Jackpot"):setVisible(false)
            if i == 5 then
                self.m_lightSpine:setVisible(true)
                self.m_lightSpine:runCsbAction("fankui2", false, function()
                    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_redBagChange)
                    self.m_lightSpine:setVisible(false)
                    self:bigRedChangeSmallRed()
                end)
            end
            performWithDelay(self.m_scWaitNode, function()
                self.tblRewardNode[i]:setVisible(false)
                self.tblRewardNode[i]:setPosition(cc.p(0, 0))
            end, 1.0)
        end)
    end
end

function SoaringWealthJackpotView:bigRedChangeSmallRed()
    local actionDelayTime = 18/60
    self.bigRedBagAni:runCsbAction("bian", false)
    for i=1, 5 do
        local redBagPos = util_convertToNodeSpace(self.m_bigRedNode, self.tblNodeRed[i])
        self.tblRedBagNode[i]:setPosition(redBagPos)
        self.tblRedBagNode[i]:setVisible(true)
        local targetPosX, targetPosY = self.tblNodeRed[i]:getPosition()
        local endPos = cc.p(0, 0)
        self.tblRewardNode[i]:refreshReward(self.m_randomRewardList[i])
        self.tblRedBagNode[i]:runCsbAction("chuxian", false, function()
            self.tblRedBagNode[i]:runCsbAction("idle", true)
        end)
        if i == 5 then
            gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_redBagMove)
        end
        util_playMoveToAction(self.tblRedBagNode[i],actionDelayTime,endPos,function()
            if i == 5 then
                self.pickTipNode:setVisible(true)
                self.pickTipNode:runCsbAction("chuxian", false, function()
                    self.pickTipNode:runCsbAction("idle", true)
                    for j=1, 5 do
                        self.tblRedBagNode[j]:setSmallBagClick(true)
                    end
                end)
            end
        end)
    end
end

function SoaringWealthJackpotView:playEndAni(_index)
    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_clickReward)
    self.tblCilckRewardNum = self.tblCilckRewardNum + 1
    local clickIndex = _index
    local randomIndex = math.random(1, #self.m_randomRewardList)
    local m_reward = self.m_randomRewardList[randomIndex]
    if not self.m_isRunRemove and self.m_unChooseBonus[1][1] == m_reward[1] and self.m_unChooseBonus[1][2] == m_reward[2] then
        table.remove(self.m_randomRewardList, randomIndex)
        randomIndex = math.random(1, #self.m_randomRewardList)
        m_reward = self.m_randomRewardList[randomIndex]
        table.remove(self.m_randomRewardList, randomIndex)
        self.m_isRunRemove = true
    else
        table.remove(self.m_randomRewardList, randomIndex)
    end
    self.tblRewardNode[clickIndex]:refreshReward(m_reward)
    self:setSmallRedClick(false)
    self.tblRewardNode[clickIndex]:setVisible(true)
    self:setClickRedState(clickIndex)
    self:showWinAndOverView(clickIndex, m_reward)
end

function SoaringWealthJackpotView:showWinAndOverView(_clickIndex, _m_reward)
    local clickIndex = _clickIndex
    local m_reward = _m_reward
    local showLastAniFunc = nil
    self.tblRewardNode[clickIndex]:runCsbAction("fankui", false, function()
        self.tblRewardNode[clickIndex]:runCsbAction("idle", true)
        self:refreshPickBonus()
        local colseCallFunc = function()
            self.m_machine:resetMusicBg(true)
            self:hideSelf()
        end
        local clickStateFunc = function()
            if self.tblCilckRewardNum < 4 then
                self:setSmallRedClick(true)
            end
        end
        local callFunc = function()
            local totalReward = 0
            for i=1, 4 do
                totalReward = totalReward + self.m_chooseBonus[i][2]
            end
            self.m_machine:showJackpotOverView(totalReward, colseCallFunc)
        end
        if self.tblCilckRewardNum >= 4 then
            showLastAniFunc = function()
                local lastIndex = self:getLastRedState()
                if lastIndex then
                    self.tblRewardNode[lastIndex]:setVisible(true)
                    self.tblRewardNode[lastIndex]:refreshReward(self.m_unChooseBonus[1], true)
                    self.tblRewardNode[lastIndex]:runCsbAction("idle", true)
                    self.tblRedBagNode[lastIndex]:runCsbAction("xiaoshi", false)
                    self.tblRewardNode[lastIndex]:runCsbAction("bianan", false, function()
                        if callFunc then
                            callFunc()
                            callFunc = nil
                        end
                    end)  
                end
            end
        end
        local winCallFunc = function()
            if m_reward[1] > 0 then
                self.m_machine:showJackpotWinView(m_reward, clickStateFunc, showLastAniFunc)
            else
                if clickStateFunc then
                    clickStateFunc()
                    clickStateFunc = nil
                end
                if showLastAniFunc then
                    showLastAniFunc()
                    showLastAniFunc = nil
                end
            end
        end

        local rewardCoins = m_reward[2]
        local startPos = util_convertToNodeSpace(self.tblNodeCoins[clickIndex], self.m_machine)
        self:flyParticleToBottom(startPos, rewardCoins, winCallFunc)
    end)
end

function SoaringWealthJackpotView:flyParticleToBottom(_startPos, _rewardCoins, _winCallFunc)
    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_collectReward)
    local startPos = _startPos
    local rewardCoins = _rewardCoins
    local winCallFunc = _winCallFunc
    local delayTime = 20/60
    local m_bottomUI = self.m_machine:getBottomUi()
    local endPos = util_convertToNodeSpace(m_bottomUI.m_normalWinLabel, self.m_machine)

    local jackPotNode = util_createAnimation("SoaringWealth_JackpotBonus_Jinbi.csb")
    jackPotNode:setPosition(startPos)
    self.m_machine:addChild(jackPotNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
    jackPotNode:runCsbAction("shouji")
    local particle = jackPotNode:findChild("Particle_1")
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:resetSystem()

    util_playMoveToAction(jackPotNode, delayTime, endPos,function()
        gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_collectFeedback)
        particle:stopSystem()
        self.m_machine:playhBottomLight(rewardCoins, winCallFunc)
        performWithDelay(self.m_scWaitNode, function()
            jackPotNode:removeFromParent()
        end, 0.5)
    end)
end

function SoaringWealthJackpotView:setSmallRedClick(_clickState)
    local clickState = _clickState
    for i=1, 5 do
        self.tblRedBagNode[i]:setClickState(clickState)
    end
end

function SoaringWealthJackpotView:refreshPickBonus()
    if self.tblCilckRewardNum == 3 then
        self.pickTipNode:runCsbAction("qiehuan", false, function()
            self.pickTipNode:runCsbAction("idle2", true)
        end)
    else
        local pickNum = 4 - self.tblCilckRewardNum
        self.pickTipNode:findChild("m_lb_num"):setString(pickNum)
    end
end

function SoaringWealthJackpotView:hideSelf()
    self:runCsbAction("over", false, function()
        if self.m_endCallFunc then
            self.m_endCallFunc()
            self.m_endCallFunc = nil
        end
        self.tblCilckRewardNum = 0
        self:setVisible(false)
    end)
end

function SoaringWealthJackpotView:setClickRedState(_clickIndex)
    local clickIndex = _clickIndex
    self.tblClickRedState[clickIndex] = true
end

function SoaringWealthJackpotView:getLastRedState()
    for i=1, 5 do
        if not self.tblClickRedState[i] then
            return i
        end
    end
    return false
end

function SoaringWealthJackpotView:onExit()
    SoaringWealthJackpotView.super.onExit(self)
end

return SoaringWealthJackpotView
