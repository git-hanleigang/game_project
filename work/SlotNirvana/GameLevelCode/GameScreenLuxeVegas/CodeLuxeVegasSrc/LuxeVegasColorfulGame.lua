---
--xcyy
--2018年5月23日
--LuxeVegasColorfulGame.lua
--多福多彩
local LuxeVegasColorfulGame = class("LuxeVegasColorfulGame",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "LuxeVegasPublicConfig"

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5,
}

function LuxeVegasColorfulGame:initUI(_machine, _jackpotBar)

    self:createCsbNode("LuxeVegas_dfdc.csb")

    self.m_machine = _machine
    self.m_jackPotBarView = _jackpotBar
    self:initData()

    for i=1, self.m_totalCount do
        self.tblJackpotParentNode[i] = self:findChild("Node_dfdc_"..i)
        self.tblJackpotNode[i] = util_createView("CodeLuxeVegasSrc.LuxeVegasColorfulItem", self.m_machine, self, i)
        self.tblJackpotParentNode[i]:addChild(self.tblJackpotNode[i])
    end

    self.m_jackpotTopNode = self.m_jackPotBarView:getAllNode()

    self.m_nodeTopEffect = self.m_machine:findChild("Node_topEffect")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)
end

function LuxeVegasColorfulGame:initData()
    self.m_totalCount = 15
    self.tblJackpotNode = {}
    self.tblJackpotParentNode = {}
    self.m_jackpotResult = nil
    self.m_jackpotProcess = nil
    self.m_jackpotCoins = nil
end

function LuxeVegasColorfulGame:resetJackpotData()
    self.m_tblJackpotNodeState = {}
    self.m_randomActionData = {}
    self.m_remainJackpotData = {}
    self.m_jackpotTopData = {}
    self.m_jackPotBarView:resetActData()
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_jackpotTopData[jackpotIndex] = 0
        for j=1, 3 do
            table.insert(self.m_remainJackpotData, jackpotIndex)
            local curJackpotNode = self.m_jackpotTopNode[jackpotType][j]
            if curJackpotNode then
                curJackpotNode:removeAllChildren()
                curJackpotNode:setVisible(false)
            end
        end
    end
end

function LuxeVegasColorfulGame:refreshData(pickData, endCallFunc)
    self:setVisible(true)
    self:resetJackpotData()
    local jackpotCoins = 0
    local jackpotName = {"Mini"}
    local jackpotProcess = {}
    if pickData then
        jackpotCoins = pickData.winCoins
        jackpotName = pickData.winJackpot
        jackpotProcess = pickData.rewardList
    end
    self.m_jackpotResult = jackpotName
    self.m_jackpotProcess = jackpotProcess
    self.m_jackpotCoins = jackpotCoins
    self.endCallFunc = endCallFunc

    self:refreshView()
    self:playJackpotNodeAction()
end

function LuxeVegasColorfulGame:refreshView()
    for i=1, self.m_totalCount do
        self.tblJackpotParentNode[i]:setLocalZOrder(i)
        self.tblJackpotNode[i]:refreshReward(6, true)
    end
end

function LuxeVegasColorfulGame:getCurRewardIndex()
    local rewardIndex = 6
    local rewardType
    if self.m_jackpotProcess and #self.m_jackpotProcess > 0 then
        rewardType = self.m_jackpotProcess[1]
        table.remove(self.m_jackpotProcess, 1)
    end

    if rewardType == "Grand" then
        rewardIndex = 1
    elseif rewardType == "Mega" then
        rewardIndex = 2
    elseif rewardType == "Major" then
        rewardIndex = 3
    elseif rewardType == "Minor" then
        rewardIndex = 4
    elseif rewardType == "Mini" then
        rewardIndex = 5
    end
    
    return rewardIndex
end

function LuxeVegasColorfulGame:isCanTouch()
    if self.m_jackpotProcess and #self.m_jackpotProcess > 0 then
        return true
    end
    return false
end

function LuxeVegasColorfulGame:showJackpotView()
    local overCallFunc = function()
        if type(self.endCallFunc) == "function" then
            self.endCallFunc()
            self.endCallFunc = nil
        end
    end
    self.m_machine:showJackpotView(self.m_jackpotCoins, self.m_jackpotResult[1], overCallFunc)
end

function LuxeVegasColorfulGame:setDelayTimeRandomAction()
    performWithDelay(self.m_scWaitNodeAction, function()
        self:playJackpotNodeAction()
    end, 3.0)
end

function LuxeVegasColorfulGame:setRandomNomalState()
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
function LuxeVegasColorfulGame:playJackpotNodeAction()
    self.m_scWaitNodeAction:stopAllActions()
    util_schedule(self.m_scWaitNodeAction, function()
        local bRandom = {}
        for i=1, self.m_totalCount do
            table.insert(bRandom, i)
        end
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

function LuxeVegasColorfulGame:hideSelf()
    self.m_nodeTopEffect:removeAllChildren()
    self:setVisible(false)
end

function LuxeVegasColorfulGame:onExit()
    LuxeVegasColorfulGame.super.onExit(self)
end

function LuxeVegasColorfulGame:setJackpotNodeState(_curIndex)
    --设置当前node状态(是否已经掀开)
    self.m_tblJackpotNodeState[_curIndex] = true
end

--刷新顶部jackpot数据和UI
function LuxeVegasColorfulGame:refreshTopJackpot(_curType, _curIndex)
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

    local curJackpotNode
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        if _curType == jackpotIndex then
            curJackpotNode = self.m_jackpotTopNode[jackpotType][jacpotData[_curType]]
            break
        end
    end

    if curJackpotNode then
        --粒子飞行
        local delayTime = 0.3
        local startPos = util_convertToNodeSpace(self:findChild("Node_dfdc_".._curIndex), self.m_nodeTopEffect)
        local endPos = util_convertToNodeSpace(curJackpotNode, self.m_nodeTopEffect)
        local size = curJackpotNode:getContentSize()

        local flyNode = util_createAnimation("LuxeVegas_jindutiao.csb")
        flyNode:setPosition(startPos)
        self.m_nodeTopEffect:addChild(flyNode)

        local particleTbl = {}
        for i=1, 2 do
            particleTbl[i] = flyNode:findChild("Particle_"..i)
            particleTbl[i]:setPositionType(0)
            particleTbl[i]:setDuration(-1)
            particleTbl[i]:resetSystem()
        end

        util_playMoveToAction(flyNode, delayTime, endPos,function()
            gLobalSoundManager:playSound(PublicConfig.Music_Click_Bonus_FeedBack)
            for i=1, 2 do
                particleTbl[i]:stopSystem()
            end
            performWithDelay(self.m_scWaitNode, function()
                if not tolua.isnull(flyNode) then
                    flyNode:removeFromParent()
                end
            end, 1.0)
            -- 反馈
            self.m_jackPotBarView:collectFeedBackAni(_curType)
            local bombNode = util_createAnimation("LuxeVegas_Jackpot_bomb.csb")
            bombNode:setPosition(cc.p(size.width/2, size.height/2))
            curJackpotNode:addChild(bombNode)
            bombNode:runCsbAction("actionframe", false, function()
                bombNode:setVisible(false)
            end)
            performWithDelay(self.m_scWaitNode, function()
                curJackpotNode:setVisible(true)
            end, 5/60)
            self:checkCurTypeIsLastJackpot(jacpotData, _curType)
            if jacpotData[_curType] == 2 or jacpotData[_curType] == 1 then
                self:setDelayTimeRandomAction()
            end
        end)
    end
end

function LuxeVegasColorfulGame:checkCurTypeIsLastJackpot(_jacpotData, _curType)
    if _jacpotData[_curType] == 2 then
        self.m_jackPotBarView:collectBarLight(_curType)
    elseif _jacpotData[_curType] == 3 then
        self:playJackpotActionFrame(_curType)
    end
end

function LuxeVegasColorfulGame:playJackpotActionFrame(_curType)
    local isPlaySound = true
    for i=1, self.m_totalCount do
        local jackpotNodeType = self.tblJackpotNode[i]:getCurJackpotNodeType()
        if jackpotNodeType == _curType then
            if isPlaySound then
                gLobalSoundManager:playSound(PublicConfig.Music_Bonus_Trigger)
                isPlaySound = false
            end
            self.tblJackpotParentNode[i]:setLocalZOrder(100+i)
            self.tblJackpotNode[i]:playActionFrame()
        elseif jackpotNodeType == 6 then
            local randomNum = math.random(1, #self.m_remainJackpotData)
            local randomType = self.m_remainJackpotData[randomNum]
            table.remove(self.m_remainJackpotData, randomNum)
            self.tblJackpotNode[i]:playDarkIdle(randomType)
        else
            --等未中奖的反过来一起播放dark_idle
            self.tblJackpotNode[i]:playOtherDarkIdle()
        end
    end
    -- 触发
    self.m_jackPotBarView:showHitLight(_curType)

    --第44帧出弹板
    performWithDelay(self.m_scWaitNode, function()
        self:showJackpotView()
    end, 44/30)
end

return LuxeVegasColorfulGame