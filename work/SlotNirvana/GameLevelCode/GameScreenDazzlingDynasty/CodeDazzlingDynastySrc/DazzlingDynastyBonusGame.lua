--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-06 14:21:46
]]

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local DazzlingDynastyBonusGame = class("DazzlingDynastyBonusGame",BaseGame)

local kDazzlingDynastyBonusGame_AllJackPotRate = 
{
    "Grand","Major","Minor","Mini"
}

function DazzlingDynastyBonusGame:initUI()
    -- TODO 输入自己初始化逻辑
    local netWorkSlot = SendDataManager:getInstance():getNetWorkSlots()
    self.netWorkSlot = netWorkSlot
    self:__setClickFlag(true)
    self:__setPlayAnimCount(0)
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
    self:createCsbNode("DazzlingDynasty/BonusGame.csb",true)
    self.pickRemaining1 = self:findChild("DazzlingDynasty_WF_1PickRemaining_4")
    self.pickRemaining2 = self:findChild("DazzlingDynasty_WF_2PicksRemaining_3")
    self.pickRemaining3 = self:findChild("DazzlingDynasty_WF_3PicksRemaining_2")
    self.pickRemaining0 = self:findChild("DazzlingDynasty_WF_NoPicksRemaining_1")
    self:runCsbAction("idle",true)
    self:__setLeftCount(3)
end

function DazzlingDynastyBonusGame:__initItemUI()
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
        local itemUI = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyBonusItem")
        local parentUI = self:findChild(string.format("diamond_%d",i))
        local selectInfo = selectInfoMap[i]
        if selectInfo ~= nil then
            itemUI:setOpenedFlag(true)
            itemUI:setExtraInfo(self,i,selectInfo[1],selectInfo[2],selectInfo[3])
        else
            itemUI:setExtraInfo(self,i,0,nil,nil)
        end
        parentUI:addChild(itemUI)
        table.insert(itemUIList,itemUI)
    end
end

function DazzlingDynastyBonusGame:__updateTitleUI()
    local leftCount = self:getLeftCount()
    for i = 0,3 do
        local pickRemaining = self[string.format("pickRemaining%d",i)]
        pickRemaining:setVisible(leftCount == i)
    end
end

function DazzlingDynastyBonusGame:__setClickFlag(flag)
    self.clickFlag = flag
end

function DazzlingDynastyBonusGame:__setPlayAnimCount(count)
    self.playAnimCount = count
end

function DazzlingDynastyBonusGame:getPlayAnimCount()
    return self.playAnimCount
end

function DazzlingDynastyBonusGame:__addPlayAnimCount(count)
    self:__setPlayAnimCount(self:getPlayAnimCount() + count)
end

function DazzlingDynastyBonusGame:getClickFlag()
    return self.clickFlag
end

function DazzlingDynastyBonusGame:__setLeftCount(count)
    self.leftCount = count
    self:__updateTitleUI()
end

function DazzlingDynastyBonusGame:getLeftCount()
    return self.leftCount
end

function DazzlingDynastyBonusGame:__setWinAmount(count)
    self.winAmount = count
end

function DazzlingDynastyBonusGame:getWinAmount()
    return self.winAmount
end

function DazzlingDynastyBonusGame:getExtraData( )
    return self.extraData
end

function DazzlingDynastyBonusGame:__setSelectPosInfo(extra)
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

function DazzlingDynastyBonusGame:canClick(index)
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

function DazzlingDynastyBonusGame:initViewData(machine,callBackFun)
    self.m_machine = machine
    self.m_callFunc = callBackFun
    self:__initItemUI()
end

function DazzlingDynastyBonusGame:resetView(machine,bonusExtra,callBackFun)
    self.m_machine = machine
    self.m_callFunc = callBackFun
    self:__setLeftCount(bonusExtra.pickTimes)
    self:__setSelectPosInfo(bonusExtra)
    self:__initItemUI()
end

function DazzlingDynastyBonusGame:__handleClickLogic(clickPos,curOpenCount)
    local strClickPos = tostring(clickPos)
    local selectIndex = clickPos + 1
    local itemUIList = self.itemUIList
    local selectItemUI = itemUIList[selectIndex]
    local extraPosesList = self.extraPosesList
    local trigOtherFlag = self.extraTrigMap[selectIndex]
    selectItemUI:setOpenedFlag(true)
    --翻牌
    selectItemUI:openItemUI(trigOtherFlag and 2 or 1,self.jackPotPosMap[strClickPos],self.selectCoinMap[strClickPos],
    function()
        if trigOtherFlag then
            local flyCount = 0
            for i = 1,#extraPosesList do
                local nextIndex = extraPosesList[i + curOpenCount]
                if nextIndex ~= nil then
                    local nextItemUI = itemUIList[nextIndex + 1]
                    if nextItemUI ~= nil and not nextItemUI:getOpenedFlag() then
                        self:__addPlayAnimCount(1)
                        self:__flyTriggerAction(selectIndex,nextIndex + 1,
                        function()
                            self:__addPlayAnimCount(-1)
                            self:__handleClickLogic(nextIndex,curOpenCount)
                        end)
                        flyCount = flyCount + 1
                        if flyCount == 2 then
                            break
                        end
                    end
                end
            end
            curOpenCount = curOpenCount + 2
        end
    end,
    function()
        if self:getPlayAnimCount() > 0 then
            self:__addPlayAnimCount(-1)
        end
        self:__checkShowReward()
    end)
    self:__addPlayAnimCount(1)
end

function DazzlingDynastyBonusGame:playTriggerAction(node)
    local nodePos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    --触发特效
    local triggerActionNode,triggerAction = util_csbCreate("Socre_DazzlingDynasty_Wild_xuanzhong.csb",true)
    util_csbPauseForIndex(triggerAction,0)
    self:addChild(triggerActionNode,util_getNodeCount(self))
    triggerActionNode:setPosition(nodePos)
    util_csbPlayForKey(triggerAction,"actionframe",false,
    function()
        triggerActionNode:removeFromParent()
    end)
end

function DazzlingDynastyBonusGame:__flyTriggerAction(startIndex,endIndex,callBack)
    local itemUIList = self.itemUIList
    local startItemUI = itemUIList[startIndex]
    local endItemUI = itemUIList[endIndex]
    local startPos = startItemUI:getParent():convertToWorldSpace(cc.p(startItemUI:getPosition()))
    local endPos = endItemUI:getParent():convertToWorldSpace(cc.p(endItemUI:getPosition()))
    local collectEffect = cc.ParticleSystemQuad:create("Effect/tx_lizi_shouji_mini.plist")
    self:addChild(collectEffect,util_getNodeCount(self))
    collectEffect:setScale(1.5)
    collectEffect:setPosition(startPos)
    collectEffect:runAction(cc.Sequence:create(
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function(sender)
            callBack()
            sender:removeFromParent()
        end)
    ))
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Collect_Gold.mp3")
end

function DazzlingDynastyBonusGame:__showAllReward()
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
    for k,v in ipairs(kDazzlingDynastyBonusGame_AllJackPotRate) do
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
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Game_OpenItem.mp3")
end

function DazzlingDynastyBonusGame:__setGameOverFlag(flag)
    self.gameOverFlag = flag
end

--弹出结算奖励
function DazzlingDynastyBonusGame:__checkShowReward()
    local leftCount = self:getLeftCount()
    if not self.gameOverFlag and leftCount == 0 and self:getPlayAnimCount() == 0 then
        self:__showAllReward()
        self:__setGameOverFlag(true)
        util_performWithDelay(self,
        function()
            local gameOverUI = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyBonusGameOverUI")
            gameOverUI:setExtraInfo(self,handler(self,self.callBackFunc))
            self:addChild(gameOverUI,util_getNodeCount(self))
            gLobalSoundManager:pauseBgMusic()
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Result_PopupBg.mp3")
        end,1.5)
    end
end

function DazzlingDynastyBonusGame:__updateTopUI()
    local winCoins = self.m_serverWinCoins
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{winCoins, GameEffect.EFFECT_BONUS})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoins,false,false,true})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)    
end

function DazzlingDynastyBonusGame:callBackFunc()
    self:__updateTopUI()
    self.m_callFunc(self:getExtraData())
end

function DazzlingDynastyBonusGame:close()
    self:removeFromParent()
end

function DazzlingDynastyBonusGame:onExit()
    self.m_machine.bonusGame = nil
    BaseGame.onExit(self)
end

--数据发送
function DazzlingDynastyBonusGame:sendData(index)
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
    self:__setLeftCount(extra.pickTimes)
    self:__setSelectPosInfo(extra)
    self:__handleClickLogic(extra.clickPos,0)]]
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

function DazzlingDynastyBonusGame:sendActionData_Spin(betCoin,currentCoins,winCoin,isFreeSpin,
                                                    slotName, bLevelUp,nextLevel,nextProVal,messageData)
    local netWorkSlot = self.netWorkSlot
    if gLobalSendDataManager:isLogin() == false then
          return      
    end

    local actType = nil
    local time = xcyy.SlotsUtil:getMilliSeconds()

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    self.levelName = slotName
    actType=ActionType.SpinV2

    if globalData.slotRunData.isDeluexeClub == true then
        if string.find(self.levelName, "_H") == nil then
            self.levelName = self.levelName .. "_H"
        end

        if actType == ActionType.SpinV2 then
            actType = ActionType.HighLimitSpin
        elseif actType == ActionType.BonusV2 then
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

    local findData = {}
    findData["findLock"] = globalData.findLock
    extraData["find"] = findData

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
        if self.__setClickFlag ~= nil then
            netWorkSlot.spinResultSuccessCallFun(netWorkSlot,resultData)
            self:__setClickFlag(true)
        end
    end

    local function spinResultFaildCallFun(sender,errorCode)
        if self.__setClickFlag ~= nil then
            netWorkSlot.spinResultFaildCallFun(netWorkSlot,errorCode)
            self:__setClickFlag(true)
        end
    end

    netWorkSlot:sendMessageData(actionData,spinResultSuccessCallFun,spinResultFaildCallFun)
    self:__setClickFlag(false)
end

function DazzlingDynastyBonusGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local result = spinData.result
        dump(result, "featureResultCallFun data", 6)
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
function DazzlingDynastyBonusGame:recvBaseData(result)
    local bonus = result.bonus
    self:__setWinAmount(result.bonus.bsWinCoins)
    if bonus ~= nil then
        local extra = bonus.extra
        if extra ~= nil then
            self:__setLeftCount(extra.pickTimes)
            self:__setSelectPosInfo(extra)
            self:__handleClickLogic(extra.clickPos,0)
        end
    end
end

return DazzlingDynastyBonusGame