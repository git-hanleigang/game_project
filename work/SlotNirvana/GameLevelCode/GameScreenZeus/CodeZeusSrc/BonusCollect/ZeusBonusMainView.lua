---
--xcyy
--2018年5月23日
--ZeusBonusMainView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local ZeusBonusMainView = class("ZeusBonusMainView", BaseGame)

ZeusBonusMainView.m_itemsNum = 22

function ZeusBonusMainView:initUI(machine)
    self:createCsbNode("BonusView/GameScreen_Zeus_bonus.csb")

    self.m_machine = machine

    self.m_pressView = util_createView("CodeZeusSrc.BonusCollect.ZeusBonusPressView", self)
    self:findChild("bonus_press"):addChild(self.m_pressView)

    self:initLable()
    self:initItems()

    if display.height > DESIGN_SIZE.height then
        local posY = (display.height - DESIGN_SIZE.height) * 0.5

        local nameList = {"totalTimes", "zeus_bonus_of_5", "leftTimes", "zeus_bonus_dakuang3_65"}

        for i = 1, #nameList do
            local node = self:findChild(nameList[i])
            if node then
                node:setPositionY(node:getPositionY() - posY)
            end
        end
    end
end

function ZeusBonusMainView:initItems()
    self.m_itemList = {}

    for i = 1, self.m_itemsNum do
        local item = util_createView("CodeZeusSrc.BonusCollect.ZeusBonusItemView", self)
        self:findChild("bonus_" .. i):addChild(item)
        table.insert(self.m_itemList, item)
    end
end

-- function ZeusBonusMainView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function ZeusBonusMainView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function ZeusBonusMainView:setEndCallFunc(func)
    self.m_callFunc = func
end

function ZeusBonusMainView:updateTotalWinCoins(coins)
    local lb_totalWinCoins = self:findChild("totalWinCoins")
    if lb_totalWinCoins then
        lb_totalWinCoins:setString(util_formatCoins(coins, 50))
        self:updateLabelSize({label = lb_totalWinCoins, sx = 0.65, sy = 0.65}, 611)
    end
end

function ZeusBonusMainView:updateWinTimes(leftTimes, totalTimes)
    local lb_leftTimes = self:findChild("leftTimes")
    if lb_leftTimes then
        lb_leftTimes:setString(totalTimes - leftTimes)
    end
    local lb_totalTimes = self:findChild("totalTimes")
    if lb_totalTimes then
        lb_totalTimes:setString(totalTimes)
    end
end

function ZeusBonusMainView:initLable()
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}

    local totalWinCoins = self.m_machine.m_runSpinResultData.p_bonusWinCoins or 0
    local multipNum = selfdata.multiply or 0
    local leftTimes = selfdata.currentPlayCount or 0
    local totalTimes = selfdata.totalPlayCount or 0

    self:updateTotalWinCoins(0)
    self.m_machine.m_bottomUI.m_normalWinLabel:setString(util_getFromatMoneyStr(totalWinCoins))

    local lb_multipNum = self:findChild("multipNum")
    if lb_multipNum then
        lb_multipNum:setString("X" .. multipNum)
        self:updateLabelSize({label = lb_multipNum, sx = 1, sy = 1}, 98)
    end

    self:updateWinTimes(leftTimes, totalTimes)
end

function ZeusBonusMainView:updateItemCoins(coins)
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}

    local multipNum = selfdata.multiply or 0

    if #coins == 0 then
        return
    end

    for i = 1, #self.m_itemList do
        local item = self.m_itemList[i]
        local coinsNum = coins[i] / tonumber(multipNum)

        local lineBet = globalData.slotRunData:getCurTotalBet() or 1

        self.m_machine:findChildDealHightLowScore(item, coinsNum / lineBet)

        if item then
            item:findChild("m_lb_score"):setString(util_formatCoins(coinsNum, 3))
            item:findChild("m_lb_score_0"):setString(util_formatCoins(coinsNum, 3))
        end
    end
end

function ZeusBonusMainView:runOpenOneItemOpenAct(index, func)
    for i = 1, #self.m_itemList do
        local item = self.m_itemList[i]
        if item and (index == i - 1) then
            item:runCsbAction(
                "open",
                false,
                function()
                    if func then
                        func()
                    end
                end
            )

            break
        end
    end
end

function ZeusBonusMainView:runOneItemOpenAct(index, func)
    for i = 1, #self.m_itemList do
        local item = self.m_itemList[i]
        if item and (index == i - 1) then
            item:runCsbAction(
                "Hit",
                false,
                function()
                    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_BonusCollectMainSymbolOpen.mp3")

                    item:runCsbAction(
                        "open",
                        false,
                        function()
                            if func then
                                func()
                            end
                        end
                    )
                end
            )

            break
        end
    end
end

function ZeusBonusMainView:runOneItemCloseAct(index, func)
    for i = 1, #self.m_itemList do
        local item = self.m_itemList[i]
        if item and (index == i - 1) then
            item:runCsbAction(
                "close",
                false,
                function()
                    if func then
                        func()
                    end
                end
            )
            break
        end
    end
end

function ZeusBonusMainView:collectCoinsAct(turnPosList, callfunc)
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local symbolCoins = selfdata.coins or {}
    local multipNum = selfdata.multiply or 0

    local waitTime = 1.5

    local showCoins = 0

    for i = 1, #turnPosList do
        local func = nil
        local index = turnPosList[i]
        if i == #turnPosList then
            func = function()
                showCoins = showCoins + symbolCoins[index + 1] / tonumber(multipNum)

                self.m_showCoins = showCoins

                self:updateTotalWinCoins(showCoins)

                if callfunc then
                    callfunc()
                end
            end
        else
            func = function()
                showCoins = showCoins + symbolCoins[index + 1] / tonumber(multipNum)

                self.m_showCoins = showCoins

                self:updateTotalWinCoins(showCoins)
            end
        end
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Bonus_Collect.mp3")

                self:runRespinCollectFlyAct(
                    self.m_itemList[index + 1],
                    self:findChild("Node_1"),
                    "Socre_Zeus_Shouji",
                    function()
                        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Bonus_Collect_down.mp3")
                        self:runCsbAction("collect")

                        if func then
                            func()
                        end
                    end
                )
            end,
            (i - 1) * waitTime
        )
    end
end

--数据接收
function ZeusBonusMainView:recvBaseData(featureData)
    self.m_pressView:setVisible(false)

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local totalWinCoins = self.m_machine.m_runSpinResultData.p_bonusWinCoins or 0
    local leftTimes = selfdata.currentPlayCount or 0
    local totalTimes = selfdata.totalPlayCount or 0
    local multipNum = selfdata.multiply or 0
    local turnPosList = selfdata.turnOverCoinPositions or {}
    local symbolCoins = selfdata.coins or {}

    table.sort(
        turnPosList,
        function(a, b)
            return a < b
        end
    )

    self:updateItemCoins(symbolCoins)

    self:updateWinTimes(leftTimes, totalTimes)

    performWithDelay(
        self,
        function()
            self.m_machine:findChild("root_zeusMan"):setVisible(true)
        end,
        0
    )

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang.mp3")

    self.m_machine:showBonusZeusHeroAct(
        function()
            gLobalSoundManager:playSound("ZeusSounds/music_Zeus_BonusCollectMain_Pi.mp3")

            local waitTime = 0.2

            for i = 1, #turnPosList do
                local func = nil
                local index = turnPosList[i]
                if i == #turnPosList then
                    func = function()
                        -- 收集

                        self:collectCoinsAct(
                            turnPosList,
                            function()
                                performWithDelay(
                                    self,
                                    function()
                                        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Bonus_Collect.mp3")
                                        self:runRespinCollectFlyAct(
                                            self:findChild("Node_4"),
                                            self:findChild("Node_1"),
                                            "Socre_Zeus_Shouji",
                                            function()
                                                gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Bonus_Collect_down.mp3")
                                                self:runCsbAction("collect")
                                                if self.m_showCoins then
                                                    self:updateTotalWinCoins(self.m_showCoins * tonumber(multipNum))
                                                end

                                                self.m_machine.m_bottomUI.m_normalWinLabel:setString(util_getFromatMoneyStr(totalWinCoins))

                                                performWithDelay(
                                                    self,
                                                    function()
                                                        self:showOtherItem(
                                                            function()
                                                                local isOver = self:getIsBonusOver()

                                                                if isOver then
                                                                    self:closeUi()
                                                                else
                                                                    -- for i=1,#turnPosList do
                                                                    --     local func2 = nil
                                                                    --     local index2 = turnPosList[i]
                                                                    --     if i == 1 then
                                                                    --         func2 = function(  )

                                                                    --             self.m_action=self.ACTION_RECV
                                                                    --             self.m_pressView:setVisible(true)
                                                                    --         end

                                                                    --     end
                                                                    --     self:runOneItemCloseAct( index2,func2  )
                                                                    -- end

                                                                    for i = 1, self.m_itemsNum do
                                                                        local func2 = nil
                                                                        local index2 = i - 1
                                                                        if i == 1 then
                                                                            func2 = function()
                                                                                self:runCsbAction(
                                                                                    "xipai",
                                                                                    false,
                                                                                    function()
                                                                                        performWithDelay(
                                                                                            self,
                                                                                            function()
                                                                                                self.m_action = self.ACTION_RECV
                                                                                                self.m_pressView:setVisible(true)
                                                                                            end,
                                                                                            0.5
                                                                                        )
                                                                                    end
                                                                                )
                                                                            end
                                                                        end
                                                                        self:runOneItemCloseAct(index2, func2)
                                                                    end
                                                                end
                                                            end
                                                        )
                                                    end,
                                                    2.5
                                                )
                                            end
                                        )
                                    end,
                                    1
                                )
                            end
                        )
                    end
                end
                performWithDelay(
                    self,
                    function()
                        self:runOneItemOpenAct(index, func)
                    end,
                    (i - 1) * waitTime
                )
            end
        end,
        function()
            self.m_machine:findChild("root_zeusMan"):setVisible(false)
        end
    )
end

function ZeusBonusMainView:isInArray(array, value)
    for k, v in pairs(array) do
        if value == v then
            return true
        end
    end

    return false
end

function ZeusBonusMainView:showOtherItem(func)
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}

    local turnPosList = selfdata.turnOverCoinPositions or {}

    local isAdd = false

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_BonusCollectMainSymbolOpen.mp3")

    for i = 1, self.m_itemsNum do
        local func2 = nil
        local index2 = i - 1
        if not self:isInArray(turnPosList, index2) then
            if isAdd == false then
                isAdd = true

                func2 = function()
                    if func then
                        func()
                    end
                end
            end

            self:runOpenOneItemOpenAct(index2, func2)
        end
    end
end

function ZeusBonusMainView:getIsBonusOver()
    local isover = false
    local bonusStates = self.m_machine.m_runSpinResultData.p_bonusStatus

    if bonusStates == "CLOSED" then
        isover = true
    end

    return isover
end

function ZeusBonusMainView:closeUi()
    performWithDelay(
        self,
        function()
            self.m_machine:findChild("root_zeusMan"):setVisible(false)
            self.m_machine:showGuoChang(
                function()
                    self.m_machine:findChild("root_zeusMan"):setVisible(true)
                    self.m_machine:changeGameBG()

                    local totalWinCoins = self.m_machine.m_runSpinResultData.p_bonusWinCoins or 0

                    -- 更新游戏内每日任务进度条
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {totalWinCoins, true, false})
                    -- 通知bonus 结束， 以及赢钱多少
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {totalWinCoins, GameEffect.EFFECT_BONUS})

                    self.m_machine.m_bottomUI.m_normalWinLabel:setString(util_getFromatMoneyStr(totalWinCoins))

                    if self.m_callFunc then
                        self.m_callFunc()
                    end
                end,
                nil,
                true
            )
        end,
        2
    )
end

function ZeusBonusMainView:checkAllBtnClickStates()
    local notClick = false

    if self.m_action == self.ACTION_SEND then
        notClick = true
    end

    return notClick
end

function ZeusBonusMainView:beginSendData()
    if self:checkAllBtnClickStates() then
        return
    end

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_ChooseView_Click.mp3")

    self:sendData()
end
--数据发送
function ZeusBonusMainView:sendData(pos)
    self.m_action = self.ACTION_SEND

    self:updateTotalWinCoins(0)

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function ZeusBonusMainView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result

            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)

            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function ZeusBonusMainView:showReward(chooseId)
end

function ZeusBonusMainView:getAngleByPos(p1, p2)
    local p = {}
    p.x = p2.x - p1.x
    p.y = p2.y - p1.y

    local r = math.atan2(p.y, p.x) * 180 / math.pi
    print("夹角[-180 - 180]:", r)
    return r
end

function ZeusBonusMainView:runRespinCollectFlyAct(startNode, endNode, csbName, func, endAddY)
    -- 创建粒子
    local flyNode = util_createAnimation(csbName .. ".csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = util_getConvertNodePos(startNode, flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = cc.p(util_getConvertNodePos(endNode, flyNode))
    if endAddY then
        endPos = cc.p(endPos.x, endPos.y + endAddY)
    end

    local angle = self:getAngleByPos(startPos, endPos)
    flyNode:findChild("Node_1"):setRotation(-angle)

    local scaleSize = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    flyNode:findChild("Node_1"):setScaleX(scaleSize / 342)

    flyNode:runCsbAction(
        "actionframe",
        false,
        function()
            if func then
                func()
            end

            flyNode:stopAllActions()
            flyNode:removeFromParent()
        end
    )

    return flyNode
end

return ZeusBonusMainView
