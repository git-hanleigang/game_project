---
--xcyy
--2018年5月23日
--MedusaManiaView.lua

local MedusaManiaJackpotView = class("MedusaManiaJackpotView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MedusaManiaPublicConfig"

function MedusaManiaJackpotView:initUI(_machine)

    self:createCsbNode("MedusaMania/MedusaMania_Jackpot.csb")

    self.m_machine = _machine
    self:initData()

    self:runCsbAction("idle", true)

    local fireLeft = util_createAnimation("MedusaMania_tanban_huoyan.csb")
    self:findChild("hyz"):addChild(fireLeft)
    fireLeft:runCsbAction("animation0", true)

    local fireRight = util_createAnimation("MedusaMania_tanban_huoyan.csb")
    self:findChild("hyy"):addChild(fireRight)
    fireRight:runCsbAction("animation0", true)

    self.m_jackPotBar = util_createView("CodeMedusaManiaSrc.MedusaManiaJackPotBarView", true)
    self.m_jackPotBar:initMachine(self.m_machine)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)

    for i=1, self.m_totalCount do
        self.tblJackpotNode[i] = util_createView("CodeMedusaManiaSrc.MedusaManiaJackpotNode", self.m_machine, self, i)
        self:findChild("Node_coins_"..i):addChild(self.tblJackpotNode[i])
    end

    self.m_jackPotWinView = util_createView("CodeMedusaManiaSrc.MedusaManiaJackpotWinView")
    self.m_machine:addChild(self.m_jackPotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_jackPotWinView:setVisible(false)

    self.m_liziNode = self:findChild("Node_lizi")

    local tblGrandNode = {}
    local tblMajorNode = {}
    local tblMinorNode = {}
    local tblMiniNode = {}
    for i=1, 3 do
        tblGrandNode[i] = self:findChild("grand"..i)
        tblMajorNode[i] = self:findChild("major"..i)
        tblMinorNode[i] = self:findChild("minor"..i)
        tblMiniNode[i] = self:findChild("mini"..i)
    end
    table.insert(self.m_jackpotTopNode, tblGrandNode)
    table.insert(self.m_jackpotTopNode, tblMajorNode)
    table.insert(self.m_jackpotTopNode, tblMinorNode)
    table.insert(self.m_jackpotTopNode, tblMiniNode)

    local tblJackpotName = {"grand_guang", "major_guang", "minor_guang", "mini_guang"}
    for i=1, 4 do
        self.m_topBarJackpotBar[i] = util_createAnimation("Socre_MedusaMania_dfdcjackpot_chufa.csb")
        self.m_jackPotBar:findChild(tblJackpotName[i]):addChild(self.m_topBarJackpotBar[i])
        self.m_topBarJackpotBar[i]:setVisible(false)
    end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)
end

function MedusaManiaJackpotView:initData()
    self.m_totalCount = 12
    self.tblJackpotNode = {}
    self.m_jackpotResult = nil
    self.m_jackpotProcess = nil
    self.m_jackpotCoins = nil

    self.m_topBarJackpotBar = {}
    self.m_jackpotTopNode = {}
end

function MedusaManiaJackpotView:resetJackpotData()
    self.m_tblLightNode = {}
    self.m_tblJackpotNodeState = {}
    self.m_randomActionData = {}
    self.m_remainJackpotData = {1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4}
    self.m_jackpotTopData = {}
    for i=1, 4 do
        self.m_jackpotTopData[i] = 0

        for j=1, 3 do
            local barNode = self.m_jackpotTopNode[i][j]
            if barNode then
                barNode:removeAllChildren()
            end
        end
    end
end

function MedusaManiaJackpotView:refreshData(selfData, endCallFunc)
    self:resetJackpotData()
    local jackpotCoins = 0
    local jackpotName = {"mini"}
    local jackpotProcess = {}
    if selfData and selfData.jackpot then
        jackpotCoins = selfData.jackpot.winValue
        jackpotName = selfData.jackpot.winJackpot
        jackpotProcess = selfData.jackpot.process
    end
    self.m_jackpotResult = jackpotName
    self.m_jackpotProcess = jackpotProcess
    self.m_jackpotCoins = jackpotCoins
    self.endCallFunc = endCallFunc
    self:refreshView()
    self:playJackpotNodeAction()
end

function MedusaManiaJackpotView:refreshView()
    for i=1, self.m_totalCount do
        self.tblJackpotNode[i]:refreshReward(5, true)
    end
end

function MedusaManiaJackpotView:getCurRewardIndex()
    local rewardIndex = 5
    local rewardType
    if self.m_jackpotProcess and #self.m_jackpotProcess > 0 then
        rewardType = self.m_jackpotProcess[1]
        table.remove(self.m_jackpotProcess, 1)
    end

    if rewardType == "grand" then
        rewardIndex = 1
    elseif rewardType == "major" then
        rewardIndex = 2
    elseif rewardType == "minor" then
        rewardIndex = 3
    elseif rewardType == "mini" then
        rewardIndex = 4
    end
    
    return rewardIndex
end

function MedusaManiaJackpotView:isCanTouch()
    if self.m_jackpotProcess and #self.m_jackpotProcess > 0 then
        return true
    end
    return false
end

function MedusaManiaJackpotView:showJackpotView()
    local tblTemp = {}
    local rewardIndex = 4
    local rewardType = "mini"
    if self.m_jackpotResult and #self.m_jackpotResult > 0 then
        rewardType = self.m_jackpotResult[1]
    end

    if rewardType == "grand" then
        rewardIndex = 1
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_GRAND)
    elseif rewardType == "major" then
        rewardIndex = 2
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MAJOR)
    elseif rewardType == "minor" then
        rewardIndex = 3
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MINOR)
    elseif rewardType == "mini" then
        rewardIndex = 4
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MINI)
    end
    table.insert(tblTemp, rewardIndex)
    table.insert(tblTemp, self.m_jackpotCoins)

    local overCallFunc = function()
        self:hideSelf()
    end

    local runEndFunc = function()
        self:runEndCallFunc()
    end

    local cutSceneCallFunc = function()
        self.m_machine:jackpotGameOver(overCallFunc, runEndFunc)
        self:runCsbAction("animation", false, function()
            self:runCsbAction("idle", true)
        end)
    end

    self.m_scWaitNodeAction:stopAllActions()
    self.m_machine:playhBottomLight(self.m_jackpotCoins)

    --上边jackpotbar动效
    for i=1, 4 do
        self.m_topBarJackpotBar[i]:setVisible(false)
    end

    self.m_jackPotWinView:setVisible(true)
    self.m_jackPotWinView:refreshRewardType(tblTemp, self.m_machine, cutSceneCallFunc)
    self.m_jackPotWinView:runCsbAction("start",false, function()
        self.m_jackPotWinView:setClickState(true)
        self.m_jackPotWinView:runCsbAction("idle", true)
    end)
end

function MedusaManiaJackpotView:setDelayTimeRandomAction()
    performWithDelay(self.m_scWaitNodeAction, function()
        self:playJackpotNodeAction()
    end, 3.0)
end

function MedusaManiaJackpotView:setRandomNomalState()
    for i=1, #self.m_randomActionData do
        local index = self.m_randomActionData[i]
        if not self.m_tblJackpotNodeState[index] then
            if self.tblJackpotNode[index] then
                self.tblJackpotNode[index]:recoverActionState()
            end
        end
    end
    self.m_randomActionData = {}
    self.m_scWaitNodeAction:stopAllActions()
end

--随机添加抖动的node
function MedusaManiaJackpotView:playJackpotNodeAction()
    self.m_scWaitNodeAction:stopAllActions()
    util_schedule(self.m_scWaitNodeAction, function()
        local bRandom = {1,2,3,4,5,6,7,8,9,10,11,12}
        self.m_randomActionData = {}
        for i=1, #bRandom do
            local random = math.random(1, #bRandom)
            local index = bRandom[random]
            table.remove(bRandom, random)
            if not self.m_tblJackpotNodeState[index] then
                self.m_randomActionData[#self.m_randomActionData+1] = index
            end
            if #self.m_randomActionData >= 3 then
                break
            end
        end

        for i=1, #self.m_randomActionData do
            local index = self.m_randomActionData[i]
            if self.tblJackpotNode[index] then
                self.tblJackpotNode[index]:runRandomAction()
            end
        end
    end, 2.5)
end

function MedusaManiaJackpotView:runEndCallFunc()
    if type(self.endCallFunc) == "function" then
        self.endCallFunc()
        self.endCallFunc = nil
    end
end

function MedusaManiaJackpotView:hideSelf()
    self:setVisible(false)
end

function MedusaManiaJackpotView:onExit()
    MedusaManiaJackpotView.super.onExit(self)
end

--刷新顶部jackpot数据和UI
function MedusaManiaJackpotView:refreshTopJackpot(_curType, _curIndex)
    --设置当前node状态(是否已经掀开)
    self.m_tblJackpotNodeState[_curIndex] = true
    --随机抖动的设置常态
    self:setRandomNomalState()
    --剔除掀开的jackpot
    for i = #self.m_remainJackpotData, 1, -1 do
        if _curType == self.m_remainJackpotData[i] then
            table.remove(self.m_remainJackpotData, i)
            break
        end
    end
    if self.m_jackpotTopData[_curType] < 3 then
        self.m_jackpotTopData[_curType] = self.m_jackpotTopData[_curType] + 1
    end
    local jacpotData = clone(self.m_jackpotTopData)

    local curJackpotNode = self.m_jackpotTopNode[_curType][jacpotData[_curType]]
    if curJackpotNode then
        --粒子飞行
        local delayTime = 0.3
        local startPos = util_convertToNodeSpace(self:findChild("Node_coins_".._curIndex), self.m_liziNode)
        local endPos = util_convertToNodeSpace(curJackpotNode, self.m_liziNode)

        local flyNode = util_createAnimation("MedusaMania_duofuduocaijackpot_twlz.csb")
        flyNode:setPosition(startPos.x, startPos.y)
        self.m_liziNode:addChild(flyNode)

        local particle = flyNode:findChild("Particle_1")
        particle:setPositionType(0)
        particle:setDuration(-1)
        particle:resetSystem()

        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Collect)
        util_playMoveToAction(flyNode, delayTime, endPos,function()
            particle:stopSystem()
            local bombNode = util_createAnimation("MedusaMania_Jackpot_zhakai.csb")
            curJackpotNode:addChild(bombNode)
            bombNode:runCsbAction("idleframe4", false, function()
                bombNode:setVisible(false)
            end)

            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Collect_FeedBack)

            local coinsNode = util_createAnimation("MedusaMania_jackpotscatter.csb")
            curJackpotNode:addChild(coinsNode)

            self:checkCurTypeIsLastJackpot(jacpotData, _curType)
            if jacpotData[_curType] == 2 or jacpotData[_curType] == 1 then
                self:setDelayTimeRandomAction()
            end
        end)
    end
end

function MedusaManiaJackpotView:checkCurTypeIsLastJackpot(_jacpotData, _curType)
    if _jacpotData[_curType] == 2 then
        local curJackpotNode = self.m_jackpotTopNode[_curType][3]
        local bonusNode = util_createAnimation("MedusaMania_Jackpot_tishi.csb")
        curJackpotNode:addChild(bonusNode)
        bonusNode:runCsbAction("idleframe3", true)
        util_setCascadeOpacityEnabledRescursion(bonusNode, true)
        self.m_tblLightNode[#self.m_tblLightNode+1] = bonusNode
    elseif _jacpotData[_curType] == 3 then
        --会切动画，加个延时
        for i=1, #self.m_tblLightNode do
            local lightNode = self.m_tblLightNode[i]
            if not tolua.isnull(lightNode) then
                local delayTime = 0.5
                local actionTbl = {}
                actionTbl[#actionTbl+1] = cc.FadeOut:create(0.5)
                actionTbl[#actionTbl+1] = cc.DelayTime:create(0.5)
                actionTbl[#actionTbl+1] = cc.CallFunc:create(function()
                    lightNode:removeFromParent()
                    self.m_tblLightNode[i] = nil
                end)
                local seq = cc.Sequence:create(actionTbl)
                lightNode:runAction(seq)
            end
        end
        performWithDelay(self.m_scWaitNode, function()
            self:playJackpotActionFrame(_curType)
        end, 20/30)
    end
end

function MedusaManiaJackpotView:playJackpotActionFrame(_curType)
    gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_TriggerDialg)
    for i=1, self.m_totalCount do
        local jackpotNodeType = self.tblJackpotNode[i]:getCurJackpotNodeType()
        if jackpotNodeType == _curType then
            self.tblJackpotNode[i]:playActionFrame()
        elseif jackpotNodeType == 5 then
            local randomNum = math.random(1, #self.m_remainJackpotData)
            local randomType = self.m_remainJackpotData[randomNum]
            table.remove(self.m_remainJackpotData, randomNum)
            self.tblJackpotNode[i]:playDarkIdle(randomType)
        else
            --等未中奖的反过来一起播放dark_idle
            self.tblJackpotNode[i]:playOtherDarkIdle()
        end
    end

    --上边jackpotbar动效
    for i=1, 4 do
        if i == _curType then
            self.m_topBarJackpotBar[i]:setVisible(true)
        else
            self.m_topBarJackpotBar[i]:setVisible(false)
        end
    end
    self.m_topBarJackpotBar[_curType]:runCsbAction("actionframe", true)
    -- --棋盘压暗
    -- self:playDarkAni()

    --播放jackpot奖励弹窗 35 + 15
    performWithDelay(self.m_scWaitNode, function()
        self:showJackpotView()
    end, 60/30)
end

return MedusaManiaJackpotView
