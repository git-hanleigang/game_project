---
--smy
--2018年4月26日
--CashRushJackpotsPickView.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "CashRushJackpotsPublicConfig"
local CashRushJackpotsPickView = class("CashRushJackpotsPickView",BaseGame )

CashRushJackpotsPickView.m_isOver = false

function CashRushJackpotsPickView:initUI(machine)
    self:createCsbNode("CashRushJackpots/PickCashRushJackpots.csb")

    self.m_machine = machine

    self:initData()

    self:runCsbAction("idle2", true)

    self.m_matchView = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsMatch")
    self:findChild("Node_match"):addChild(self.m_matchView)

    for i=1, self.m_totalCount do
        self.m_pickNodeAni[i] = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsPickItem",self, i)
        self:findChild("Node_"..i):addChild(self.m_pickNodeAni[i])
    end

    self.m_liziNode = self:findChild("Node_lizi")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CashRushJackpotsPickView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function CashRushJackpotsPickView:initData()
    self.m_totalCount = 20
    -- pickNode
    self.m_pickNodeAni = {}

    --发送过程中不允许再次点击
    self.m_isClick = true
end

function CashRushJackpotsPickView:resetDate()
    self.m_isClick = true
    -- 抖动时的状态
    self.m_tblPickNodeState = {}
    -- 随机抖动的数据
    self.m_randomActionData = {}
    -- pick结束时，中pick的选项
    self.m_winSelectPickData = {}
    -- pick剩余的类型
    self.m_remainPickData = 
    {
        1, 1, 1,
        2, 2, 2,
        3, 3, 3,
        4, 4, 4,
        5, 5, 5,
        6, 6, 6,
        7, 7
    }
    -- 已经掀开的位置
    self.m_openPickPos = {}

    for i=1, self.m_totalCount do
        self.m_pickNodeAni[i]:setItemIdle()
        self.m_pickNodeAni[i]:setClickState(true)
    end

    self.m_matchView:resetDate()
end

function CashRushJackpotsPickView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function CashRushJackpotsPickView:onEnter()
    CashRushJackpotsPickView.super.onEnter(self)
end

function CashRushJackpotsPickView:onExit()
    CashRushJackpotsPickView.super.onExit(self)
end

function CashRushJackpotsPickView:refreshView(_bonusExtra, _endCallFunc, _onEnter)
    self:runCsbAction("idle2", true)
    local bonusExtra = _bonusExtra
    self.endCallFunc = _endCallFunc
    local onEnter = _onEnter
    local pickConfig = bonusExtra.pickConfig or {}
    --初始化界面
    self:resetDate()
    self.m_matchView:refreshConfigView(pickConfig, onEnter)
    self:refreshPickData(bonusExtra, onEnter)
    self:playPickNodeAction()
end

--刷新界面
function CashRushJackpotsPickView:refreshPickData(_bonusExtra, _onEnter, _isPickOver)
    local bonusExtra = _bonusExtra
    local onEnter = _onEnter
    local isPickOver = _isPickOver
    local pickConfig = bonusExtra.pickConfig or {}
    local selectList = bonusExtra.selectList or {}
    local historySelects = bonusExtra.historySelects or {}
    
    local winAmount = self.m_machine.m_runSpin
    --随机抖动的设置常态
    self:setRandomNomalState()

    if onEnter then
        self:playLastMatchAction(pickConfig)
        for i=1, #selectList do
            local selectIndex = selectList[i]
            local selectReward = tonumber(historySelects[i])
            self:removeOpenPickType(selectReward)
            self:addOpenPickPos(selectIndex)
            local isSuper = selectReward == 7 and true or false
            self.m_pickNodeAni[selectIndex]:refreshItemView(pickConfig[selectReward], isSuper, onEnter)
            --设置当前node状态(是否已经掀开)
            self.m_tblPickNodeState[selectIndex] = true
        end
    else
        local endIndex = #selectList
        if endIndex > 0 then
            local selectIndex = selectList[endIndex]
            local selectReward = tonumber(historySelects[endIndex])
            self:removeOpenPickType(selectReward)
            self:addOpenPickPos(selectIndex)
            local isSuper = selectReward == 7 and true or false
            self.m_pickNodeAni[selectIndex]:refreshItemView(pickConfig[selectReward], isSuper, onEnter)

            self:flyParticleToMatch(pickConfig, selectIndex, selectReward, isSuper)

            if isPickOver then
                -- 获取中的是哪档
                local winMatchIndex = 1
                if bonusExtra.hitIndex then
                    winMatchIndex = bonusExtra.hitIndex + 1
                end
        
                -- 获取pick选项
                for k, v in pairs(historySelects) do
                    local rewardIndex = tonumber(v)
                    if rewardIndex == winMatchIndex or rewardIndex == 7 then
                        local tempTbl = {}
                        tempTbl.isSuper = rewardIndex == 7 and true or false
                        tempTbl.selectIndex = selectList[k]
                        table.insert(self.m_winSelectPickData, tempTbl)
                    end
                end
        
                performWithDelay(self.m_scWaitNode, function()
                    self:playTriggerPickAction(winMatchIndex, pickConfig)
                end, 1.0)
            end
        end
    end
end

-- 去除已经掀开的类型
function CashRushJackpotsPickView:removeOpenPickType(_pickType)
    local pickType = _pickType
    for i=1, #self.m_remainPickData do
        if self.m_remainPickData[i] == pickType then
            table.remove(self.m_remainPickData, i)
            break
        end
    end
end

-- 添加已经掀开的位置
function CashRushJackpotsPickView:addOpenPickPos(_pickPos)
    local pickPos = _pickPos
    table.insert(self.m_openPickPos, pickPos)
end

-- 差一个集满播放特效
function CashRushJackpotsPickView:playLastMatchAction(_pickConfig)
    local pickConfig = _pickConfig
    for k, v in pairs(pickConfig) do
        local curProcess = v.ball
        if curProcess == 2 then
            self.m_matchView:playLastMatchAction(k)
        end
    end
end

--触发动画，未掀开的播放压暗
function CashRushJackpotsPickView:playTriggerPickAction(_winMatchIndex, _pickConfig)
    local winMatchIndex = _winMatchIndex
    local pickConfig = _pickConfig

    -- 序列动画
    local tblActionList = {}
    -- 播放未掀开的动画
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        for i=1, self.m_totalCount do
            local isClose = true
            for k, pos in pairs(self.m_openPickPos) do
                if i == pos then
                    isClose = false
                    break
                end
            end
            if isClose then
                local rewardIndex = self.m_remainPickData[1] or 1
                table.remove(self.m_remainPickData, 1)
                local isSuper = rewardIndex == 7 and true or false
                self.m_pickNodeAni[i]:gameOverRefreshItemView(pickConfig[rewardIndex], isSuper)
                -- self.m_pickNodeAni[i]:refreshItemView(pickConfig[rewardIndex], isSuper, nil, true)
            end
        end
    end)
    -- 掀开动画时长50/60
    -- tblActionList[#tblActionList+1] = cc.DelayTime:create(50/60)
    -- 播放未中奖的压暗动画
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        for i=1, self.m_totalCount do
            local isNotReward = true
            for j=1, #self.m_winSelectPickData do
                local tempTbl = self.m_winSelectPickData[j]
                local index = tempTbl.selectIndex
                if i == index then
                    isNotReward = false
                    break
                end
            end
            if isNotReward then
                self.m_pickNodeAni[i]:setDarkAction()
            end
        end
    end)
    -- 播放触发动画
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_matchView:playTriggerMatchAction(winMatchIndex)
        gLobalSoundManager:playSound(PublicConfig.Music_Pick_Collect_Full)
        for i=1, #self.m_winSelectPickData do
            local tempTbl = self.m_winSelectPickData[i]
            local index = tempTbl.selectIndex
            if tempTbl.isSuper then
                self.m_pickNodeAni[index]:setSuperActionframe()
            else
                self.m_pickNodeAni[index]:setActionframe()
            end
        end
    end)
    -- pickGame结束
    tblActionList[#tblActionList+1] = cc.DelayTime:create(3.0)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:pickGameOver()
    end)

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 粒子飞到match
function CashRushJackpotsPickView:flyParticleToMatch(_pickConfig, _selectIndex, _selectReward, _isSuper)
    local pickConfig = _pickConfig
    local selectIndex = _selectIndex
    local selectReward = _selectReward
    local isSuper = _isSuper
    --设置当前node状态(是否已经掀开)
    self.m_tblPickNodeState[selectIndex] = true
    -- 抽到万能的每个点都要飞粒子
    if isSuper then
        local isPlay = true
        gLobalSoundManager:playSound(PublicConfig.Music_Pick_Wild_Fly)
        for i=1, 6 do
            --粒子飞行
            local delayTime = 0.3
            local startPos = util_convertToNodeSpace(self:findChild("Node_"..selectIndex), self.m_liziNode)
            local curProcess = pickConfig[i].ball
            local processWorldPos = self.m_matchView:getNodeWorldPos(curProcess, i)
            local endPos = self.m_liziNode:convertToNodeSpace(processWorldPos)

            local flyNode = util_createAnimation("CashRushJackpots_pick_lizi.csb")
            flyNode:setPosition(startPos.x, startPos.y)
            self.m_liziNode:addChild(flyNode)

            local particle = flyNode:findChild("Particle_1")
            particle:setPositionType(0)
            particle:setDuration(-1)
            particle:resetSystem()

            util_playMoveToAction(flyNode, delayTime, endPos,function()
                particle:stopSystem()
                if isPlay then
                    gLobalSoundManager:playSound(PublicConfig.Music_Pick_Wild_FeedBack)
                    isPlay = false
                end
                self.m_matchView:refreshProcess(i, pickConfig[i])
                self:playLastMatchAction(pickConfig)
                performWithDelay(self.m_scWaitNode, function()
                    flyNode:removeFromParent()
                end, 0.5)
            end)
        end
    else
        --粒子飞行
        local delayTime = 0.3
        local startPos = util_convertToNodeSpace(self:findChild("Node_"..selectIndex), self.m_liziNode)
        local curProcess = pickConfig[selectReward].ball
        local processWorldPos = self.m_matchView:getNodeWorldPos(curProcess, selectReward)
        local endPos = self.m_liziNode:convertToNodeSpace(processWorldPos)

        local flyNode = util_createAnimation("CashRushJackpots_pick_lizi.csb")
        flyNode:setPosition(startPos.x, startPos.y)
        self.m_liziNode:addChild(flyNode)

        local particle = flyNode:findChild("Particle_1")
        particle:setPositionType(0)
        particle:setDuration(-1)
        particle:resetSystem()

        gLobalSoundManager:playSound(PublicConfig.Music_Pick_Normal_Fly)
        util_playMoveToAction(flyNode, delayTime, endPos,function()
            particle:stopSystem()
            gLobalSoundManager:playSound(PublicConfig.Music_Pick_Normal_FeedBack)
            self.m_matchView:refreshProcess(selectReward, pickConfig[selectReward])
            self:playLastMatchAction(pickConfig)
            performWithDelay(self.m_scWaitNode, function()
                flyNode:removeFromParent()
            end, 0.5)
        end)
    end
end

function CashRushJackpotsPickView:isCanTouch()
    if self.m_isClick then
        return true
    end
    return false
end

function CashRushJackpotsPickView:pickGameOver()
    
    self.m_machine:bonusPickGameOver(self.endCallFunc, function()
        -- self:hideSelf()
    end)
end

function CashRushJackpotsPickView:setRandomNomalState()
    for i=1, #self.m_randomActionData do
        local index = self.m_randomActionData[i]
        if not self.m_tblPickNodeState[index] then
            if self.m_pickNodeAni[index] then
                self.m_pickNodeAni[index]:setItemIdle()
            end
        end
    end
    self.m_randomActionData = {}
    self.m_scWaitNodeAction:stopAllActions()
end

function CashRushJackpotsPickView:setDelayTimeRandomAction()
    self:playPickNodeAction()
end

--随机添加抖动的node
function CashRushJackpotsPickView:playPickNodeAction()
    self.m_scWaitNodeAction:stopAllActions()
    util_schedule(self.m_scWaitNodeAction, function()
        local bRandom = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20}
        self.m_randomActionData = {}
        for i=1, #bRandom do
            local random = math.random(1, #bRandom)
            local index = bRandom[random]
            table.remove(bRandom, random)
            if not self.m_tblPickNodeState[index] then
                self.m_randomActionData[#self.m_randomActionData+1] = index
            end
            if #self.m_randomActionData >= 3 then
                break
            end
        end

        for i=1, #self.m_randomActionData do
            local index = self.m_randomActionData[i]
            if self.m_pickNodeAni[index] then
                self.m_pickNodeAni[index]:runRandomAction()
            end
        end
    end, 2.0)
end

--数据接收
--选择次数返回的数据
function CashRushJackpotsPickView:recvBaseData(featureData)

    local bonusdata = featureData.p_bonus or {}

    if bonusdata.extra and bonusdata.status then
        local isPickOver = bonusdata.status == "CLOSED" and true or false
        self:refreshPickData(bonusdata.extra, false, isPickOver)
        if not isPickOver then
            self.m_isClick = true
            self:setDelayTimeRandomAction()
        else
            for i=1, self.m_totalCount do
                self.m_pickNodeAni[i]:setClickState(false)
            end
        end
    end
end

--数据发送(选择次数)
function CashRushJackpotsPickView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    self.m_isClick = false
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= selectIndex , mermaidVersion = 0 } 
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--[[
    接受网络回调
]]

function CashRushJackpotsPickView:featureResultCallFun(param)
    if self:isVisible() and param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_runSpinResultData = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData()
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function CashRushJackpotsPickView:hideSelf()
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

return CashRushJackpotsPickView
