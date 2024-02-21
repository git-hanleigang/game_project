---
--xcyy
--2018年5月23日
--BingoldKoiWheelView.lua

local SendDataManager = require "network.SendDataManager"

local BingoldKoiWheelView = class("BingoldKoiWheelView",util_require("Levels.BaseLevelDialog"))

function BingoldKoiWheelView:initUI(params)
    self.m_machine = params.machine
    self._effectData = params._effectData
    self._wheelEndIndex = params._wheelEndIndex

    self:createCsbNode("BingoldKoi/GameScreenBonusWheel.csb")

    self:runCsbAction("dianji", true)
    -- self:findChild("Node_kuang"):setVisible(false)

    --创建横向滚轮
    self.m_reel_horizontal = self:createSpecialReelHorizontal()
    
    self:findChild("sp_wheel"):addChild(self.m_reel_horizontal)
    self.m_reel_horizontal:initSymbolNode()
    -- self.m_reel_horizontal:startMove()

    -- self.m_reel_horizontal:setIsWaitNetBack(false)

    self.m_waveSpine = util_spineCreate("BingoldKoi_zplh",true,true)
    self:findChild("hailang"):addChild(self.m_waveSpine)
    util_spinePlay(self.m_waveSpine, "animation", true)

    self.m_fishSpine = util_spineCreate("BingoldKoi_zhuanpan_yu",true,true)
    self:findChild("yu"):addChild(self.m_fishSpine)
    self.m_fishSpine:setVisible(false)

    self.m_maskAni = util_createAnimation("BingoldKoi_zyyan.csb")
    self:findChild("Node_Mask"):addChild(self.m_maskAni)
    self.m_maskAni:setVisible(false)

    self:addClick(self:findChild("sp_wheel"))
end

function BingoldKoiWheelView:onEnter()
    BingoldKoiWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

--[[
    创建特殊轮子-横向
]]
function BingoldKoiWheelView:createSpecialReelHorizontal()
    local sp_wheel = self:findChild("sp_wheel")
    local wheelSize = sp_wheel:getContentSize()
    local reelData = self.m_machine.m_runSpinResultData.p_selfMakeData.wheelConfig
    if not reelData then
        reelData = {10,200,20,40,50,25,200,15,1000,8}
    end
    local reelNode =  util_require("BingoldKoiSpecialReel.BingoldKoiSpecialReelNodeHorizontal"):create({
        parentData = {
            reelDatas = reelData,
            beginReelIndex = 1,
            slotNodeW = wheelSize.width / 9,
            slotNodeH = wheelSize.height,
            reelHeight = wheelSize.height,
            reelWidth = wheelSize.width,
            isDone = false
        },      --列数据
        configData = {
            p_reelMoveSpeed = 1000,
            p_rowNum = 9,
            p_reelBeginJumpTime = 0.2,
            p_reelBeginJumpHight = 20,
            p_reelResTime = 0.15,
            p_reelResDis = 4,
            p_reelRunDatas = {51}
        },      --列配置数据
        doneFunc = function()--列停止回调
            self.m_machine:delayCallBack(0.1,function()
                util_spinePlay(self.m_waveSpine, "animation", true)
                if self.m_soundMove then
                    gLobalSoundManager:stopAudio(self.m_soundMove)
                    self.m_soundMove = nil
                end
                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Wheel_Select)
                self.m_maskAni:setVisible(true)
                self.m_maskAni:runCsbAction("yaan_start", false, function()
                    self.m_maskAni:runCsbAction("yaan_idle", true)
                end)
                self:runCsbAction("actionframe3_over", false, function()
                    self:runCsbAction("actionframe2", false, function()
                        self:runCsbAction("actionframe", true)
                        self.m_fishSpine:setVisible(true)
                        util_spinePlay(self.m_fishSpine, "actionframe1", false)
                        performWithDelay(self.m_machine.m_scWaitNode, function()
                            local hideSelf = function()
                                self:removeFromParent()
                            end
                            self.m_machine:bonusGameOver(self._effectData, hideSelf)
                        end, 42/30)
                    end)
                end)
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
        direction = 1,      --0纵向 1横向 默认纵向
        colIndex = 1,
        machine = self.m_machine      --必传参数
    })

    --计算停轮时的轮盘
    local endIndex
    if self.m_machine.m_runSpinResultData.p_selfMakeData.wheelIndex then
        endIndex = self.m_machine.m_runSpinResultData.p_selfMakeData.wheelIndex + 1
    else
        endIndex = self._wheelEndIndex + 1
    end
    local lastList = {}
    --第五个为中间的点,所以要从结束点开始向前取4个加在前面
    for index = 4,1,-1 do
        local symbolIndex = endIndex - index
        if symbolIndex < 1 then
            symbolIndex = symbolIndex + #reelData
        end
        local symbolType = reelData[symbolIndex]
        lastList[#lastList + 1] = symbolType
    end
    for index = 1,#reelData - 4 do
        local symbolType = reelData[endIndex + index - 1]
        lastList[#lastList + 1] = symbolType
    end

    reelNode:setSymbolList(lastList)

    return reelNode
end

function BingoldKoiWheelView:createWheelNode(symbolType)
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    local jackpotType = ""
    for i,jackpotCfg in ipairs(jackpotPools) do
        if jackpotCfg.p_configData.p_multiple == symbolType then
            jackpotType = jackpotCfg.p_configData.p_name
        end
    end

    if jackpotType == "GRAND" then
        local symbol = util_createAnimation("Wheel_BingoldKoi_grand.csb")
        symbol.jackpotType = "grand"
        return symbol
    elseif jackpotType == "MEGA" then
        local symbol = util_createAnimation("Wheel_BingoldKoi_mega.csb")
        symbol.jackpotType = "mega"
        return symbol
    elseif jackpotType == "MAJOR" then
        local symbol = util_createAnimation("Wheel_BingoldKoi_major.csb")
        symbol.jackpotType = "major"
        return symbol
    elseif jackpotType == "MINOR" then
        local symbol = util_createAnimation("Wheel_BingoldKoi_minor.csb")
        symbol.jackpotType = "minor"
        return symbol
    elseif jackpotType == "MINI" then
        local symbol = util_createAnimation("Wheel_BingoldKoi_mini.csb")
        symbol.jackpotType = "mini"
        return symbol
    end
    
    local symbol = util_createAnimation("Wheel_BingoldKoi_coins.csb")
    symbol.jackpotType = ""
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_machine.m_isSuperFree and self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet
    end
    if symbolType >= 5 then
        symbol:findChild("m_lb_coins"):setFntFile("BingoldKoiFont/BingoldKoi_font10.fnt")
    else
        symbol:findChild("m_lb_coins"):setFntFile("BingoldKoiFont/BingoldKoi_font3.fnt")
    end
    local coins = util_formatCoins(lineBet * symbolType,3)
    local len = string.len(coins)
    local str = ""
    --将文字转换为纵向显示
    for index = 1,len do
        local char = string.sub(coins,index,index)
        if char ~= "," then
            str = str..char.."\n"
        end
    end

    symbol:findChild("m_lb_coins"):setString(str)
    return symbol
end

--默认按钮监听回调
function BingoldKoiWheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    self:sendData()
end

--[[
    数据发送
]]
function BingoldKoiWheelView:sendData()
    if self.m_isWaiting then
        return
    end
    --防止连续点击
    self.m_isWaiting = true
    self:runCsbAction("over", false, function()
        self:runCsbAction("actionframe3_start", false, function()
            self:runCsbAction("actionframe3", true)
        end)
    end)
    util_spinePlay(self.m_waveSpine, "animation2", true)

    self.m_soundMove = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Wheel_Start_Move,false)
    self.m_reel_horizontal:startMove()
    
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,betLevel = self.m_machine.m_iBetLevel}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function BingoldKoiWheelView:featureResultCallFun(param)
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
function BingoldKoiWheelView:recvBaseData(featureData)
    self.m_featureData = featureData
    --更新machine数据 
    self.m_machine.m_runSpinResultData:parseResultData(featureData, self.m_machine.m_lineDataPool)
    -- self.m_machine.m_runSpinResultData.p_selfMakeData.bingoLines = featureData.selfData.bingoLines
    -- self.m_machine.m_runSpinResultData.p_selfMakeData.initBonusCoins = featureData.selfData.initBonusCoins
    -- self.m_machine.m_runSpinResultData.p_winAmount = self.m_serverWinCoins
    
    -- self.m_reel_horizontal:setIsWaitNetBack(false)
    self.m_reel_horizontal.m_needDeceler = true
    self.m_reel_horizontal.m_runTime = 0

end


return BingoldKoiWheelView