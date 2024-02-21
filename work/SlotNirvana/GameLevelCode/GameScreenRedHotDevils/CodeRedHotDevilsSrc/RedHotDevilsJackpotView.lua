---
--RedHotDevilsJackpotView.lua

local RedHotDevilsJackpotView = class("RedHotDevilsJackpotView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "RedHotDevilsPublicConfig"

RedHotDevilsJackpotView.m_machine = nil

function RedHotDevilsJackpotView:initUI(_machine)

    self:createCsbNode("RedHotDevils/RedHotDevils_jackpot.csb")
    
    self.m_machine = _machine
    self:initData()

    self.m_jackPotBar = util_createView("CodeRedHotDevilsSrc.RedHotDevilsJackPotBarView", true)
    self.m_jackPotBar:initMachine(self.m_machine )
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)

    self.m_liziNode = self:findChild("Node_lizi")

    local tblGrandNode = {}
    local tblMajorNode = {}
    local tblMinorNode = {}
    local tblMiniNode = {}
    for i=1, 3 do
        tblGrandNode[i] = self.m_jackPotBar:findChild("Node_Grand_"..i)
        tblMajorNode[i] = self.m_jackPotBar:findChild("Node_Major_"..i)
        tblMinorNode[i] = self.m_jackPotBar:findChild("Node_Minor_"..i)
        tblMiniNode[i] = self.m_jackPotBar:findChild("Node_Mini_"..i)
    end
    table.insert(self.m_jackpotTopNode, tblGrandNode)
    table.insert(self.m_jackpotTopNode, tblMajorNode)
    table.insert(self.m_jackpotTopNode, tblMinorNode)
    table.insert(self.m_jackpotTopNode, tblMiniNode)

    self.m_topBarJackpotNode[1] = self.m_jackPotBar:findChild("GRAND_win")
    self.m_topBarJackpotNode[2] = self.m_jackPotBar:findChild("MAJOR_win")
    self.m_topBarJackpotNode[3] = self.m_jackPotBar:findChild("MINOR_win")
    self.m_topBarJackpotNode[4] = self.m_jackPotBar:findChild("MINI_win")

    self.m_jackPotWinView = util_createView("CodeRedHotDevilsSrc.RedHotDevilsJackpotWinView")
    self.m_machine:addChild(self.m_jackPotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_jackPotWinView:setVisible(false)
    self.m_jackPotWinView:findChild("root"):setScale(self.m_machine.m_machineRootScale * 0.9)

    for i=1, self.m_totalCount do
        self.tblJackpotNode[i] = util_createView("CodeRedHotDevilsSrc.RedHotDevilsJackpotNode", self.m_machine, self, i)
        self:findChild("Node_jinbi_"..i):addChild(self.tblJackpotNode[i])
    end

    self.m_darkAni = util_createAnimation("RedHotDevils_qipan_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_darkAni)
    self.m_darkAni:setVisible(false)

    self.m_curClickCount = self:findChild("m_lb_num")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听
end

function RedHotDevilsJackpotView:initData()
    self.m_totalCount = 12
    self.tblJackpotNode = {}
    self.m_jackpotResult = nil
    self.m_jackpotPools = nil
    self.m_jackpotProcess = nil
    self.m_jackpotCoins = nil

    self.m_topBarJackpotNode = {}
    self.m_jackpotTopNode = {}
end

function RedHotDevilsJackpotView:scaleMainLayer(_posY)
    self:setPositionY(self:getPositionY() + _posY)
end

function RedHotDevilsJackpotView:resetJackpotData()
    self.m_tblLightNode = {}
    self.m_tblJackpotNodeState = {}
    self.m_randomActionData = {}
    self.m_remainJackpotData = {1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4}
    self.m_jackpotTopData = {}
    self.m_darkAni:setVisible(false)
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

function RedHotDevilsJackpotView:refreshData(selfData, jackpotCoins, endCallFunc)
    self:resetJackpotData()
    self.m_jackpotResult = selfData.jackpotResult
    self.m_jackpotPools = selfData.jackpotPools
    self.m_jackpotProcess = selfData.jackpotProcess
    self.m_jackpotCoins = jackpotCoins
    self.endCallFunc = endCallFunc
    self:refreshView()
    self:playJackpotNodeAction()
end

function RedHotDevilsJackpotView:setDelayTimeRandomAction()
    performWithDelay(self.m_scWaitNodeAction, function()
        self:playJackpotNodeAction()
    end, 3.0)
end

function RedHotDevilsJackpotView:setRandomNomalState()
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
function RedHotDevilsJackpotView:playJackpotNodeAction()
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

function RedHotDevilsJackpotView:refreshView()
    self:refreshTopCount()
    for i=1, self.m_totalCount do
        self.tblJackpotNode[i]:refreshReward(5, true)
    end
end

function RedHotDevilsJackpotView:refreshTopCount()
    local count = #self.m_jackpotProcess
    self.m_curClickCount:setString(3)
end

function RedHotDevilsJackpotView:scaleJackpotMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function RedHotDevilsJackpotView:getCurRewardIndex()
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

function RedHotDevilsJackpotView:isCanTouch()
    if self.m_jackpotProcess and #self.m_jackpotProcess > 0 then
        return true
    end
    return false
end

function RedHotDevilsJackpotView:showJackpotView()
    local tblTemp = {}
    local rewardIndex = 4
    local rewardType = "mini"
    local rewardCoins = 0
    if self.m_jackpotResult and #self.m_jackpotResult > 0 then
        rewardType = self.m_jackpotResult
    end

    if rewardType == "grand" then
        rewardIndex = 1
        rewardCoins = self.m_jackpotCoins["Grand"]
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_GRAND)
    elseif rewardType == "major" then
        rewardIndex = 2
        rewardCoins = self.m_jackpotCoins["Major"]
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MAJOR)
    elseif rewardType == "minor" then
        rewardIndex = 3
        rewardCoins = self.m_jackpotCoins["Minor"]
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MINOR)
    elseif rewardType == "mini" then
        rewardIndex = 4
        rewardCoins = self.m_jackpotCoins["Mini"]
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MINI)
    end
    table.insert(tblTemp, rewardIndex)
    table.insert(tblTemp, rewardCoins)

    local overCallFunc = function()
        self:hideSelf()
    end

    self.m_scWaitNodeAction:stopAllActions()
    self.m_machine:playhBottomLight(rewardCoins)

    self.m_jackPotWinView:setVisible(true)
    self.m_jackPotWinView:refreshRewardType(tblTemp, self.m_machine, overCallFunc)
    self.m_jackPotWinView:runCsbAction("start",false, function()
        self.m_darkAni:runCsbAction("over", false)
        self.m_jackPotWinView:setClickState(true)
        self.m_jackPotWinView:setSpineIdle()
        self.m_jackPotWinView:runCsbAction("idle", true)
    end)
end

--刷新顶部jackpot数据和UI
function RedHotDevilsJackpotView:refreshTopJackpot(_curType, _curIndex)
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
        local startPos = util_convertToNodeSpace(self:findChild("Node_jinbi_".._curIndex), self.m_liziNode)
        local endPos = util_convertToNodeSpace(curJackpotNode, self.m_liziNode)

        local flyNode = util_createAnimation("RedHotDevils_jackpot_shouji.csb")
        flyNode:setPosition(startPos.x, startPos.y)
        self.m_liziNode:addChild(flyNode)

        local particle = flyNode:findChild("Particle_1")
        particle:setPositionType(0)
        particle:setDuration(-1)
        particle:resetSystem()

        util_playMoveToAction(flyNode, delayTime, endPos,function()
            particle:stopSystem()
            -- self:refreshTopCount()
            local coinsNode = util_createAnimation("RedHotDevils_jackpotkuang_jackpot_jinbi.csb")
            curJackpotNode:addChild(coinsNode)
            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Collect_FeedBack)
            coinsNode:runCsbAction("start", false, function()
                self:checkCurTypeIsLastJackpot(jacpotData, _curType)
                if jacpotData[_curType] == 2 or jacpotData[_curType] == 1 then
                    self:setDelayTimeRandomAction()
                end
            end)
            performWithDelay(self.m_scWaitNode, function()
                flyNode:removeFromParent()
            end, 0.5)
        end)
    end
end

function RedHotDevilsJackpotView:checkCurTypeIsLastJackpot(_jacpotData, _curType)
    if _jacpotData[_curType] == 2 then
        local actionframeName = "actionframe_mini"
        if _curType == 1 then
            actionframeName = "actionframe_grand"
        elseif _curType == 2 then
            actionframeName = "actionframe_major"
        elseif _curType == 3 then
            actionframeName = "actionframe_minor"
        elseif _curType == 4 then
            actionframeName = "actionframe_mini"
        end
        local curJackpotNode = self.m_jackpotTopNode[_curType][3]
        local bonusNode = util_createAnimation("RedHotDevils_bonus.csb")
        curJackpotNode:addChild(bonusNode)
        bonusNode:runCsbAction(actionframeName, true)
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

function RedHotDevilsJackpotView:playJackpotActionFrame(_curType)
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
            self.m_topBarJackpotNode[i]:setVisible(true)
        else
            self.m_topBarJackpotNode[i]:setVisible(false)
        end
    end
    self.m_jackPotBar:runCsbAction("actionframe", false)
    --棋盘压暗
    self:playDarkAni()

    --播放jackpot奖励弹窗 35 + 15
    performWithDelay(self.m_scWaitNode, function()
        self:showJackpotView()
    end, 50/30)
end

function RedHotDevilsJackpotView:playDarkAni()
    self.m_darkAni:setVisible(true)
    self.m_darkAni:runCsbAction("start", false, function()
        self.m_darkAni:runCsbAction("idle", true)
    end)
end

function RedHotDevilsJackpotView:hideSelf()
    self:setVisible(false)
    self.m_machine:jackpotGameOver(self.endCallFunc)
end

function RedHotDevilsJackpotView:onExit()
    RedHotDevilsJackpotView.super.onExit(self)
end

return RedHotDevilsJackpotView
