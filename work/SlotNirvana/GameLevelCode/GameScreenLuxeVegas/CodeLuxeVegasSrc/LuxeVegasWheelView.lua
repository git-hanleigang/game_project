---
--smy
--2018年4月18日
--LuxeVegasWheelView.lua
local SendDataManager = require "network.SendDataManager"
local PublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasWheelView = class("LuxeVegasWheelView",util_require("Levels.BaseLevelDialog"))

function LuxeVegasWheelView:initUI(params)
    self.m_machine = params.machine
    self._effectData = params._effectData
    self._wheelEndIndex = params._wheelEndIndex
    self._curFreeCountData = params._curFreeCountData

    self:createCsbNode("LuxeVegas/GameScreenWheel.csb")
    self.wheelSpinNode = self:findChild("Node_wheelSpin")
    self.wheelSpinNode:setOpacity(0)

    self.m_isWaiting = true

    self:runCsbAction("idle", true)

    --创建竖向滚轮
    self.m_reel_vertical = self:createSpecialReeVertical()
    
    self:findChild("sp_wheel"):addChild(self.m_reel_vertical)
    self.m_reel_vertical:initSymbolNode()

    self:addClick(self:findChild("sp_wheel"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    local actionList = {}
    actionList[#actionList+1] = cc.DelayTime:create(2.0)
    actionList[#actionList+1] = cc.CallFunc:create(function()
        self.m_reel_vertical:startMove()
    end)
    actionList[#actionList+1] = cc.DelayTime:create(0.5)
    actionList[#actionList+1] = cc.CallFunc:create(function()
        self.m_isWaiting = false
    end)
    local seq = cc.Sequence:create(actionList)
    self.m_scWaitNode:runAction(seq)
end

function LuxeVegasWheelView:onEnter()
    LuxeVegasWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(self, params)
        self:featureResultCallFun(params)
    end, ViewEventType.NOTIFY_GET_SPINRESULT)
end

--[[
    创建特殊轮子-纵向
]]
function LuxeVegasWheelView:createSpecialReeVertical()
    local sp_wheel = self:findChild("sp_wheel")
    local wheelSize = sp_wheel:getContentSize()
    local reelData = self.m_machine.m_runSpinResultData.p_selfMakeData.wheelShow
    if not reelData then
        reelData = {"free1", "free2", "free3", "Major", "Mega", "Grand"}
    end
    local reelNode =  util_require("CodeLuxeVegasSrc.LuxeVegasWheelVertical"):create({
        parentData = {
            reelDatas = reelData,
            beginReelIndex = 1,
            slotNodeW = wheelSize.width,
            slotNodeH = wheelSize.height / 5,
            reelHeight = wheelSize.height,
            reelWidth = wheelSize.width,
            isDone = false
        },      --列数据
        configData = {
            p_reelMoveSpeed = 1000,
            p_rowNum = 6,
            p_reelBeginJumpTime = 0.2,
            p_reelBeginJumpHight = 20,
            p_reelResTime = 0.15,
            p_reelResDis = 4,
            p_reelRunDatas = {46}
        },      --列配置数据
        doneFunc = function()--列停止回调
            self.wheelSpinNode:runAction(cc.FadeOut:create(0.5))
            self.m_machine:delayCallBack(0.5,function()
                if self.m_soundMove then
                    gLobalSoundManager:stopAudio(self.m_soundMove)
                    self.m_soundMove = nil
                end
                gLobalSoundManager:playSound(PublicConfig.Music_BigWheel_Select)
                self:runCsbAction("actionframe", true)
                performWithDelay(self.m_scWaitNode, function()
                    local hideSelf = function()
                        self:removeFromParent()
                    end
                    self.m_machine:bonusGameOver(self._effectData, hideSelf, self.m_rewardType)
                end, 2.0)
            end)
        end,        
        createSymbolFunc = function(symbolType, rowIndex, colIndex, isLastNode)--创建小块
            local symbolNode = self:createWheelNode(symbolType)
            symbolNode.m_isLastSymbol = isLastNode
            return symbolNode
        end,
        pushSlotNodeToPoolFunc = function(symbolType,symbolNode)
            
        end,--小块放回缓存池
        updateGridFunc = function(symbolNode)
            
        end,  --小块数据刷新回调
        direction = 0,      --0纵向 1横向 默认纵向
        colIndex = 1,
        machine = self.m_machine      --必传参数
    })

    return reelNode
end

function LuxeVegasWheelView:createWheelNode(symbolType)
    local symbol = util_createAnimation("Wheel_LuxeVegas_10X.csb")
    if symbolType == "free1" then
        local freeCount = self._curFreeCountData[1] or 0
        local symbol = util_createAnimation("Wheel_LuxeVegas_10X.csb")
        symbol:findChild("m_lb_num"):setString(freeCount)
        return symbol
    elseif symbolType == "free2" then
        local freeCount = self._curFreeCountData[2] or 0
        local symbol = util_createAnimation("Wheel_LuxeVegas_25X.csb")
        symbol:findChild("m_lb_num"):setString(freeCount)
        return symbol
    elseif symbolType == "free3" then
        local freeCount = self._curFreeCountData[3] or 0
        local symbol = util_createAnimation("Wheel_LuxeVegas_50X.csb")
        symbol:findChild("m_lb_num"):setString(freeCount)
        return symbol
    elseif symbolType == "Major" then
        local symbol = util_createAnimation("Wheel_LuxeVegas_Major.csb")
        return symbol
    elseif symbolType == "Mega" then
        local symbol = util_createAnimation("Wheel_LuxeVegas_Mega.csb")
        symbol.jackpotType = "mini"
        return symbol
    elseif symbolType == "Grand" then
        local symbol = util_createAnimation("Wheel_LuxeVegas_Grand.csb")
        return symbol
    end
    return symbol
end

--默认按钮监听回调
function LuxeVegasWheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    self:sendData()
end

--[[
    数据发送
]]
function LuxeVegasWheelView:sendData()
    if self.m_isWaiting then
        return
    end
    --防止连续点击
    self.m_isWaiting = true

    gLobalSoundManager:playSound(PublicConfig.Music_Click_BigWheel)
    self.m_soundMove = gLobalSoundManager:playSound(PublicConfig.Music_BigWheel_Start_Move,false)
    self:runCsbAction("over", false, function()
        self.wheelSpinNode:runAction(cc.FadeIn:create(0.5))
        self:runCsbAction("wheel_idle", true)
    end)
    self.m_scWaitNode:stopAllActions()
    self.m_reel_vertical:startMove(nil, true)
    
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,betLevel = self.m_machine.m_iBetLevel}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function LuxeVegasWheelView:featureResultCallFun(param)
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
function LuxeVegasWheelView:recvBaseData(featureData)
    self.m_featureData = featureData
    --更新machine数据 
    self.m_machine.m_runSpinResultData:parseResultData(featureData, self.m_machine.m_lineDataPool)
    --计算停轮时的轮盘
    local endIndex = 1
    local reelData = self.m_machine.m_runSpinResultData.p_selfMakeData.wheelShow
    if not reelData then
        reelData = {"free1", "free2", "free3", "Major", "Mega", "Grand"}
    end
    if self.m_machine.m_runSpinResultData.p_selfMakeData.wheelType then
        local wheelType = self.m_machine.m_runSpinResultData.p_selfMakeData.wheelType
        self.m_rewardType = wheelType
        for k, v in pairs(reelData) do
            if wheelType == v then
                endIndex = k
                break
            end
        end
    end
    local lastList = {}
    --第3个为中间的点,所以要从结束点开始向前取2个加在前面
    for index = 2,1,-1 do
        local symbolIndex = endIndex - index
        if symbolIndex < 1 then
            symbolIndex = symbolIndex + #reelData
        end
        local symbolType = reelData[symbolIndex]
        lastList[#lastList + 1] = symbolType
    end
    for index = 1,#reelData - 2 do
        local symbolType = reelData[endIndex + index - 1]
        if symbolType then
            lastList[#lastList + 1] = symbolType
        end
    end

    self.m_reel_vertical:setSymbolList(lastList)

    self.m_reel_vertical.m_needDeceler = true
    self.m_reel_vertical.m_runTime = 0
end


return LuxeVegasWheelView