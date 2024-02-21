local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local GameNetDataManager = require "network.SendDataManager"

local BaseGame = util_require("base.BaseGame")

local GoldenGhostBonusGame = class("GoldenGhostBonusGame",BaseGame)

local kGoldenGhostBonusGame_AllJackPotRate = 
{
    "Grand",
    "Major",
    "Minor",
    "Mini"
}

function GoldenGhostBonusGame:onExit()
    self.m_machine.bonusGame = nil
    self.m_machine:bonusChangeReelUiVisible(true)
    BaseGame.onExit(self)
end

function GoldenGhostBonusGame:initUI()
    -- TODO 输入自己初始化逻辑
    local netWorkSlot = GameNetDataManager:getInstance():getNetWorkSlots()
    self.netWorkSlot = netWorkSlot
    self:setClickFlag(true)
    self:setPlayAnimCount(0)
    --项列表
    self.itemUIList = {}
    --选择的位置列表
    self.selectPosList = nil
    --额外触发的位置列表
    self.extraTrigMap = {}
    --玩家选择的位置列表
    self.selectInfoMap = {}
    --选择的金币信息
    self.selectCoinMap = nil
    --额外打开的位置列表
    self.extraPosesList = nil
    --jackPot信息
    self.jackPotPosMap = nil
    -- 注释掉自动缩放
    self:createCsbNode("GoldenGhost/BonusGame.csb")
    -- self:createCsbNode("GoldenGhost/BonusGame.csb",true)

    self:runCsbAction("start",false,function ( ... )
        -- body
        self:runCsbAction("idle",false)
    end)
    --取消遮罩
    self:findChild("Panel_1"):setVisible(false)

    --先注释 两个描述文本 一个次数文本???
    -- self.pickRemaining0 = self:findChild("DazzlingDynasty_WF_NoPicksRemaining_1")
    -- self.titleDecLab = self:findChild("picks_remaining")
    -- self.titleNumLab = self:findChild("m_lb_num")

    -- 新的次数文本工程
    self.m_pickTimes = util_createAnimation("GoldenGhost_Game_Bonus_bar.csb")
    self:findChild("Bonus_Bar"):addChild(self.m_pickTimes)
end

function GoldenGhostBonusGame:initItemUI()
    local machine = self.m_machine
    local itemUIList = self.itemUIList
    local selectPosList = self.selectPosList
    local selectCoinMap = self.selectCoinMap
    local extraTrigMap = self.extraTrigMap
    local jackPotPosMap = self.jackPotPosMap
    local leftCount = self:getLeftCount()


    --显示之前翻开的牌
    local selectInfoMap = {}
    if selectPosList ~= nil then
        for k,v in ipairs(selectPosList) do
            local strV = tostring(v)
            selectInfoMap[v + 1] = {extraTrigMap[v + 1] and 2 or 1,jackPotPosMap[strV],selectCoinMap[strV]}
        end
    end
    self.selectInfoMap = selectInfoMap

    for i = 1,12 do
        local itemUI = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusItem")
        local parentUI = self:findChild(string.format("pumpkin_%d",i))
        local selectInfo = selectInfoMap[i]
        if selectInfo ~= nil then
            itemUI:setOpenedFlag(true)
            itemUI:setExtraInfo(self,i,selectInfo[1],selectInfo[2],selectInfo[3],machine)
        else
            itemUI:setExtraInfo(self,i,0,nil,nil,machine)
        end
        parentUI:addChild(itemUI)
        table.insert(itemUIList,itemUI)
    end
end

function GoldenGhostBonusGame:updateTitleUI()
    local leftCount = self:getLeftCount()

    local nopicks = self.m_pickTimes:findChild("nopick")
    local picks = self.m_pickTimes:findChild("picks")
    local onePick = self.m_pickTimes:findChild("pick")
    local labTimes = self.m_pickTimes:findChild("BitmapFontLabel_1")

    -- 剩余次数大于0
    if(leftCount > 0) then
        -- self.pickRemaining0:setVisible(false)
        -- self.titleDecLab:setVisible(true)
        -- self.titleNumLab:setString(tostring(leftCount))
        
        nopicks:setVisible(false)
        picks:setVisible(leftCount > 1)
        onePick:setVisible(leftCount == 1)
        labTimes:setString(tostring(leftCount))
    else
        -- self.pickRemaining0:setVisible(true)
        -- self.titleDecLab:setVisible(false)
        -- self.titleNumLab:setVisible(false)
        nopicks:setVisible(true)
        picks:setVisible(false)
        onePick:setVisible(false)
        labTimes:setVisible(false)
    end
end

function GoldenGhostBonusGame:setClickFlag(flag)
    self.clickFlag = flag
end

function GoldenGhostBonusGame:setPlayAnimCount(count)
    self.playAnimCount = count
end

function GoldenGhostBonusGame:getPlayAnimCount()
    return self.playAnimCount
end

function GoldenGhostBonusGame:addPlayAnimCount(count)
    self:setPlayAnimCount(self:getPlayAnimCount() + count)
end

function GoldenGhostBonusGame:getClickFlag()
    return self.clickFlag
end

function GoldenGhostBonusGame:setLeftCount(count)

    self.m_machine:setPickBonusTimes(count)

    self.leftCount = count
    self:updateTitleUI()
end

function GoldenGhostBonusGame:getLeftCount()
    return self.leftCount
end

function GoldenGhostBonusGame:setWinAmount(count)
    self.winAmount = count
end

function GoldenGhostBonusGame:getWinAmount()
    return self.winAmount
end

function GoldenGhostBonusGame:getExtraData( )
    return self.extraData
end

function GoldenGhostBonusGame:setSelectPosInfo(extra)
    self.extraData = extra
    self.selectPosList = extra.chooses
    self.selectCoinMap = extra.totalCoins
    self.extraPosesList = extra.extraPoses or {}
    self.jackPotPosMap = extra.jackpotPoses or {}
    local extraTrigMap = self.extraTrigMap
    local triggerPoses = extra.triggerPoses or {}
    for k,v in ipairs(triggerPoses) do
        extraTrigMap[v + 1] = true 
    end
end

function GoldenGhostBonusGame:canClick(index)
    local selectPosList = self.selectPosList
    local openFlag = true
    if selectPosList ~= nil then
        for k,v in ipairs(selectPosList) do
            if v == index - 1 then
                openFlag = false
                break
            end
        end
    end
    return self:getClickFlag() and self:getLeftCount() > 0 and self:getPlayAnimCount() == 0 and openFlag
end

function GoldenGhostBonusGame:initViewData(machine,callBackFun)
    self.m_machine = machine
    self.m_callFunc = callBackFun
    self:initItemUI()
    self:setLeftCount(3)
    self.m_machine:bonusChangeReelUiVisible(false)
end

function GoldenGhostBonusGame:resetView(machine,bonusExtra,callBackFun)
    self.m_machine = machine
    self.m_callFunc = callBackFun
    self:setLeftCount(bonusExtra.pickTimes)
    self:setSelectPosInfo(bonusExtra)
    self:initItemUI()
    self.m_machine:bonusChangeReelUiVisible(false)
end

function GoldenGhostBonusGame:handleClickLogic(clickPos,curOpenCount,trigOtherState)
    local strClickPos = tostring(clickPos)
    local itemUIList = self.itemUIList
    local selectIndex = clickPos + 1
    local selectItemUI = itemUIList[selectIndex]
    local extraPosesList = self.extraPosesList
    local trigOtherFlag = self.extraTrigMap[selectIndex]
    selectItemUI:setOpenedFlag(true)

    self:addPlayAnimCount(1)
    selectItemUI:openItemUI(trigOtherFlag and 2 or 1,self.jackPotPosMap[strClickPos],self.selectCoinMap[strClickPos],
    function()
        if self:getPlayAnimCount() > 0 then
            self:addPlayAnimCount(-1)
        end
        local trigOther = self.extraTrigMap[selectIndex]
        if trigOtherFlag then
            local flyCount = 0

            local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
            gLobalSoundManager:playSound(levelConfig.Sound_BonusPick_OpenItem_Gold_FlyOther)

            for i = 1,#extraPosesList do
                local nextIndex = extraPosesList[i + curOpenCount]
                if nextIndex ~= nil then
                    local nextItemUI = itemUIList[nextIndex + 1]
                    if nextItemUI ~= nil and not nextItemUI:getOpenedFlag() then
                        self:addPlayAnimCount(1)
                        local openOtherCount = flyCount + 1
                        self:flyTriggerAction(selectIndex,nextIndex + 1,
                        function()
                            self:addPlayAnimCount(-1)

                            if 1 == openOtherCount then
                                gLobalSoundManager:playSound(levelConfig.Sound_BonusPick_OpenItem)
                            end
                            
                            self:handleClickLogic(nextIndex,curOpenCount + 2,3)
                        end)
                        flyCount = flyCount + 1
                        if flyCount == 2 then
                            break
                        end
                    end
                end
            end
        else
            if self:getPlayAnimCount() <= 0 then
                self:checkShowReward()
            end
        end
    end,trigOtherState)
end

function GoldenGhostBonusGame:playTriggerAction(node)
end

function GoldenGhostBonusGame:flyTriggerAction(startIndex,endIndex,callBack)
    local itemUIList = self.itemUIList
    local startItemUI = itemUIList[startIndex]
    local endItemUI = itemUIList[endIndex]
    local startPos = startItemUI.tuowei:getParent():convertToWorldSpace(cc.p(startItemUI.tuowei:getPosition()))
    local endPos = endItemUI.tuowei:getParent():convertToWorldSpace(cc.p(endItemUI.tuowei:getPosition()))
    -- 创建粒子
    local flyNode = util_createAnimation( "GoldenGhost_Pick_tuowei.csb" )
    self:addChild(flyNode,util_getNodeCount(self))
    flyNode:setPosition(startPos)

    local angle = util_getAngleByPos(startPos,endPos)
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
    flyNode:setScaleX(scaleSize / 350 )

    flyNode:runCsbAction("actionframe",true,function()
        flyNode:stopAllActions()
        flyNode:removeFromParent()
        if callBack then
            callBack()
        end
    end)

end

function GoldenGhostBonusGame:showAllReward()
    local selectCoinMap = self.selectCoinMap
    local jackPotPosMap = self.jackPotPosMap
    local selectInfoMap = self.selectInfoMap
    local extraTrigMap = self.extraTrigMap
    local extraTrigCount = table_nums(extraTrigMap)
    local jackPotCount = table_nums(jackPotPosMap)
    local itemUIList = self.itemUIList
    local randomGrayDiamondBgMap = {}
    local randomGrayJackPotMap = {}
    local jackPotMap = {}
    for k,v in pairs(jackPotPosMap) do
        jackPotMap[v] = true
    end

    local notOpenExtraTrigKeyList = {}
    for k,v in ipairs(itemUIList) do
        if not v:getOpenedFlag() and extraTrigMap[k - 1] == nil then
            table.insert(notOpenExtraTrigKeyList,k)
        end
    end

    --随机爆炸位置
    if #notOpenExtraTrigKeyList > 0 then
        for i = extraTrigCount + 1,4 do
            local rateIndex = math.random(1,#notOpenExtraTrigKeyList)
            local randomKey = notOpenExtraTrigKeyList[rateIndex]
            randomGrayDiamondBgMap[randomKey] = true
            table.remove(notOpenExtraTrigKeyList,rateIndex)
        end
    end

    --随机jackpot
    local randomJackPotMap = {}
    for k,v in ipairs(kGoldenGhostBonusGame_AllJackPotRate) do
        if not jackPotMap[v] then
            table.insert(randomJackPotMap,v)
        end
    end
    
    local notOpenKeyList = {}
    for k,v in ipairs(itemUIList) do
        if not v:getOpenedFlag() and randomGrayDiamondBgMap[k] == nil then
            table.insert(notOpenKeyList,k)
        end
    end

    if jackPotCount == 0 then
        local rateIndex = math.random(1,#notOpenKeyList)
        local randomKey = notOpenKeyList[rateIndex]
        local randomJackPotKey = math.random(1,#randomJackPotMap)
        for k,v in ipairs(itemUIList) do
            if k == randomKey then
                randomGrayJackPotMap[tostring(k - 1)] = randomJackPotMap[randomJackPotKey]
            end
        end
    end

    for k,v in ipairs(itemUIList) do
        local strK = tostring(k - 1)
        if extraTrigMap[k] then
            v:openGrayItemUI(2,jackPotPosMap[strK] or randomGrayJackPotMap[strK],selectCoinMap[strK])
        else
            v:openGrayItemUI(randomGrayDiamondBgMap[k] and 3 or 1,jackPotPosMap[strK] or randomGrayJackPotMap[strK],selectCoinMap[strK])
        end
    end

end

function GoldenGhostBonusGame:setGameOverFlag(flag)
    self.gameOverFlag = flag
end

--弹出结算奖励
function GoldenGhostBonusGame:checkShowReward()
    local leftCount = self:getLeftCount()
    if not self.gameOverFlag and leftCount == 0 and self:getPlayAnimCount() == 0 then
        self:showAllReward()
        self:setGameOverFlag(true)
        util_performWithDelay(self,
        function()
            self:showBonusOverView()
        end,1.5)
    end
end

function GoldenGhostBonusGame:showBonusOverView()
    gLobalSoundManager:pauseBgMusic()
    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    gLobalSoundManager:playSound(levelConfig.Sound_BonusPick_Over)

    local winAmount = self:getWinAmount() - globalData.slotRunData.lastWinCoin

    self.m_machine:showGoldenGhostBonusOverView(winAmount, handler(self,self.callBackFunc))

    -- local gameOverUI = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusGameOverUI")
    -- gameOverUI:setExtraInfo(self,handler(self,self.callBackFunc))
    -- self:addChild(gameOverUI,util_getNodeCount(self))
    -- gLobalSoundManager:pauseBgMusic()

end

function GoldenGhostBonusGame:updateTopUI()
    -- 底栏赢钱 修改为:不计算 连线赢钱
    local winCoins = globalData.slotRunData.lastWinCoin
    -- local winCoins = self.m_serverWinCoins
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{winCoins, GameEffect.EFFECT_BONUS})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoins,false,false,true})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)    
end

function GoldenGhostBonusGame:callBackFunc()
    self:updateTopUI()
    self.m_callFunc(self:getExtraData())
end

function GoldenGhostBonusGame:playCloseAnim()
    self:runCsbAction("over",false,function ( ... )
        -- body
        self:removeFromParent()
    end)
end



--数据发送
function GoldenGhostBonusGame:sendData(index)
    --[[local extra = 
    {
        chooses = 
        {
            2,8,3,1,4
        },
        clickPos = 2,
        extraPoses =
        {   
            8,3,1,4
        },
        triggerPoses = 
        {
            2,3
        },
        pickTimes = 3,
        totalCoins = 
        {
            ["1"] = 1000000,
            ["2"] = 1000000,
            ["3"] = 2000000,
            ["4"] = 3000000,
            ["8"] = 5000000,
        },
        jackpotPoses = 
        {

        },
    }
    self:setLeftCount(extra.pickTimes)
    self:setSelectPosInfo(extra)
    self:handleClickLogic(extra.clickPos,0)]]
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, clickPos = index - 1}
    -- 请求feature 结果数据
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local isFreeSpin = true
    local totalCoin = globalData.userRunData.coinNum
    local currProVal = globalData.userRunData.currLevelExper
    local curLevel = globalData.userRunData.levelNum
    self:sendActionData_Spin(totalBet,totalCoin, 0,isFreeSpin,
                            globalData.slotRunData.gameNetWorkModuleName, false,curLevel,currProVal,messageData)
end

function GoldenGhostBonusGame:sendActionData_Spin(betCoin,currentCoins,winCoin,isFreeSpin,
                                                    slotName, bLevelUp,nextLevel,nextProVal,messageData)
    local netWorkSlot = self.netWorkSlot
    if gLobalSendDataManager:isLogin() == false then
          return      
    end

    local actType = nil
    local time = xcyy.SlotsUtil:getMilliSeconds()

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    self.levelName = slotName
    --jms小魔女和ct奢华风不一样?
    actType=ActionType.SpinV2

    if globalData.slotRunData.isDeluexeClub == true then
        if string.find(self.levelName, "_H") == nil then
            self.levelName = self.levelName .. "_H"
        end

        if actType == ActionType.SpinV2 then
            actType = ActionType.HighLimitSpin
        elseif actType == ActionType.Bonus then
            actType = ActionType.HighLimitBonus
        elseif actType == ActionType.BonusSpecial then
            actType = ActionType.HighLimitBonusSpecial
        end
    end

    local clickPos = messageData.clickPos
    local actionData = netWorkSlot:getSendActionData(actType, slotName)

    -- if winType == 0 then
    --     winType = 1
    -- end
    actionData.data.betCoins = globalData.slotRunData:getCurTotalBet()

    actionData.data.betGems = 0

    actionData.data.winCoins = winCoin
    -- actionData.data.winGems = 0
    actionData.data.balanceCoins = 0
    actionData.data.balanceCoinsNew = get_integer_string(currentCoins)
    actionData.data.balanceGems = 0     
    
    -- 判断是否升级
    local addBetExp = betCoin
    local currProVal = nextProVal
    local totalProVal = globalData.userRunData:getLevelUpgradeNeedExp(nextLevel)

    actionData.data.freespin = isFreeSpin
    -- actionData.data.winType = winType
    actionData.data.exp = currProVal
    actionData.data.addExp = addBetExp
    actionData.data.levelup = bLevelUp
    actionData.data.level = nextLevel
    actionData.data.betId = globalData.slotRunData.iLastBetIdx

    actionData.data.version = netWorkSlot:getVersionNum()


    local extraData = {}

    extraData[ExtraType.spinAccumulation] = globalData.spinAccumulation or { ["time"] = os.time(), ["amount"] = 0 } 

    --存救济金
    extraData[ExtraType.reliefTimes] = globalData.reliefFundsTimes


    actionData.data.extra = cjson.encode(extraData)

    local logSpinType = "normal"
    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
          logSpinType = "auto"
    end

    --spin附加参数
    local paramsData = {}
    paramsData.spinSessionId = gL_logData:getGameSessionId()
    paramsData.type = logSpinType
    local levelName = globalData.slotRunData.machineData.p_levelName
    paramsData.order = gLobalSendDataManager:getLogSlots():getLevelOrder(levelName)
    gLobalSendDataManager:getLogSlots():addSlotData(paramsData)
    local maxBetData = globalData.slotRunData:getMaxBetData()
    if maxBetData then
          paramsData.maxBet = maxBetData.p_totalBetValue
    end
    paramsData["clickPos"] = clickPos
    actionData.data.params = json.encode(paramsData) 

    local function spinResultSuccessCallFun(sender,resultData)
        if self.setClickFlag ~= nil then
            netWorkSlot.spinResultSuccessCallFun(netWorkSlot,resultData)
            self:setClickFlag(true)
        end
    end

    local function spinResultFaildCallFun(sender,errorCode)
        if self.setClickFlag ~= nil then
            netWorkSlot.spinResultFaildCallFun(netWorkSlot,errorCode)
            self:setClickFlag(true)
        end
    end

    netWorkSlot:sendMessageData(actionData,spinResultSuccessCallFun,spinResultFaildCallFun)
    self:setClickFlag(false)
end

function GoldenGhostBonusGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local result = spinData.result
        -- dump(result, "featureResultCallFun data", 6)
        local userMoneyInfo = param[3]
        globalData.userRate:pushCoins(result.winAmount)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_serverWinCoins = result.bonus.bsWinCoins  -- 记录下服务器返回赢钱的结果
            self:recvBaseData(result)
        end
    end
end

--数据接收
function GoldenGhostBonusGame:recvBaseData(result)
    local bonus = result.bonus
    self:setWinAmount(result.bonus.bsWinCoins)
    if bonus ~= nil then
        local extra = bonus.extra
        if extra ~= nil then
            self:setLeftCount(extra.pickTimes)
            self:setSelectPosInfo(extra)
            -- 金南瓜 和 普通南瓜
            local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
            local soundName = levelConfig.Sound_BonusPick_OpenItem
            if self.extraTrigMap and self.extraTrigMap[extra.clickPos +1 ] then
                soundName = levelConfig.Sound_BonusPick_OpenItem_Gold
            end
            gLobalSoundManager:playSound(soundName)
            
            self:handleClickLogic(extra.clickPos,0)
        end
    end
end

return GoldenGhostBonusGame