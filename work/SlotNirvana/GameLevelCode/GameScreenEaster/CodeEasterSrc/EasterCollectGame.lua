--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-02-18 10:58:29
]]
local BaseGame = util_require("base.BaseGame")
local SendDataManager = require "network.SendDataManager"
local EasterCollectGame = class("EasterCollectGame", BaseGame)
EasterCollectGame.m_eggList = {}
EasterCollectGame.m_lastJackpotName = nil

function EasterCollectGame:initUI(data)
    self:createCsbNode("Easter/BonusGame.csb")
    local panelNode = self:findChild("Panel_2")
    self:addClick(panelNode)
    self.m_EggIdle = false
    self.m_bClick = false
end

function EasterCollectGame:onEnter()
    BaseGame.onEnter(self)
    schedule(
        self,
        function()
            if self.m_EggIdle then
                self:updateEggIdle()
            end
        end,
        3
    )
end

function EasterCollectGame:clickFunc(sender)
    if not self.m_bClick then
        return
    end
    local name = sender:getName()
    if name == "Panel_2" then
        self:palyOverEffect()
    end
end

function EasterCollectGame:palyOverEffect()
    if not self.m_bClick then
        return
    end
    self.m_bClick = false
    self:runCsbAction(
        "over",
        false,
        function()
            self:findChild("Panel_2"):setVisible(false)
            self:playAllEggLightEffect()
        end
    )
end

function EasterCollectGame:onExit()
    BaseGame.onExit(self)
end

function EasterCollectGame:initMachine(machine)
    self.m_machine = machine
end

function EasterCollectGame:getJpEggNum(_data)
    local grandNum = 0
    local majorNum = 0
    local minorNum = 0
    local miniNum = 0

    for i = 1, #_data do
        local jpName = _data[i]
        if jpName == "Grand" then
            grandNum = grandNum + 1
        elseif jpName == "Major" then
            majorNum = majorNum + 1
        elseif jpName == "Minor" then
            minorNum = minorNum + 1
        elseif jpName == "Mini" then
            miniNum = miniNum + 1
        end
    end

    return grandNum, majorNum, minorNum, miniNum
end

function EasterCollectGame:setJpBarEggNum(_data)
    local grandNum, majorNum, minorNum, miniNum = self:getJpEggNum(_data)

    self.m_jackPotNode:updateEggNum("grand", grandNum)
    self.m_jackPotNode:updateEggNum("major", majorNum)
    self.m_jackPotNode:updateEggNum("minor", minorNum)
    self.m_jackPotNode:updateEggNum("mini", miniNum)
end

function EasterCollectGame:initView(data, callBackFunc)
    self.m_data = clone(data)
    self.m_callBackFunc = callBackFunc

    self.m_jackPotNode = util_createView("CodeEasterSrc.EasterCollectJackPotBarView", {machine = self.m_machine, gameMachine = self})
    self:findChild("Jackpotbar"):addChild(self.m_jackPotNode)
    self:setJpBarEggNum(data)
    self.m_jackPotNode:updateEggVisible()

    self:showJackpotFrameEffect()

    self:initEgg(data)

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_bClick = true
            self:runCsbAction(
                "idle",
                false,
                function()
                    self:palyOverEffect()
                end
            )
        end
    )
end

function EasterCollectGame:playAllEggLightEffect()
    if self.m_EggIdle then
        return
    end
    for i = 1, 12 do
        local egg = self.m_eggList[i]
        egg:runCsbAction("actionframe3", false)
    end
    performWithDelay(
        self,
        function()
            -- 断线重连时恢复鸡蛋被刷子刷过的状态
            self:updateEgg(self.m_initData)
            self.m_EggIdle = true
        end,
        1
    )
end

function EasterCollectGame:initEgg(_data)
    for i = 1, 12 do
        local data = {}
        data.index = i
        data.callfunc = handler(self, self.eggCallFunc)
        local egg = util_createView("CodeEasterSrc.EasterCollectGameEgg", data)
        local node = self:findChild("egg_" .. i)
        local pos = cc.p(node:getPosition())
        self:findChild("EggNode"):addChild(egg)
        egg:findChild("click"):setVisible(false)
        egg:setPosition(pos)

        self:hideEggEffect(egg)
        self.m_eggList[i] = egg
    end
    self.m_initData = _data
    -- 断线重连时恢复鸡蛋被刷子刷过的状态
    -- self:updateEgg(_data)
end

function EasterCollectGame:updateEgg(_data)
    if _data then
        local eggTable = {}
        for i = 1, #_data do
            local index = i
            local jackpotName = _data[i]

            local eggNode = self.m_eggList[index]
            if eggNode then
                if jackpotName == "NONE" then -- 没有被点击
                    self.m_eggList[i]:findChild("click"):setVisible(true)
                    table.insert(eggTable, eggNode)
                else
                    self.m_eggList[i]:findChild("click"):setVisible(false)

                    local jackpotName = string.lower(jackpotName) -- grand , major , ninor ,mini

                    self:hideEggEffect(eggNode, jackpotName)
                    eggNode:setEggName(jackpotName)

                    -- 蛋被刷开
                    eggNode:runCsbAction("idle3")
                end
            end
        end
    end
end

function EasterCollectGame:hideEggEffect(_eggNode, _jackpotName)
    local jackpot = {"grand", "major", "minor", "mini"}
    for i = 1, #jackpot do
        if jackpot[i] == _jackpotName then
            _eggNode:findChild(jackpot[i]):setVisible(true)
        else
            _eggNode:findChild(jackpot[i]):setVisible(false)
        end
    end
end
function EasterCollectGame:hideJackpotEffect(_jackPotNode)
    local jackpot = {"grand", "major", "minor", "mini"}
    for i = 1, #jackpot do
        _jackPotNode:findChild("Sprite_" .. jackpot[i] .. "L"):setVisible(false)
    end
end

function EasterCollectGame:eggCallFunc(_index)
    self.m_eggIndex = _index

    for i = 1, 12 do
        self.m_eggList[i]:findChild("click"):setVisible(false)
    end
    self:sendCollectData(_index)
end

function EasterCollectGame:startBrushEggs(_index, _fun, _data)
    gLobalSoundManager:playSound("EasterSounds/sound_Easter_click_egg.mp3")

    local jackpotName = string.lower(_data[_index]) -- grand , major , ninor ,mini
    self.m_lastJackpotName = jackpotName
    if not self.m_brush then
        self.m_brush = util_spineCreate("Easter_BonusGameShuazi", true, true)
        self:findChild("EggNode"):addChild(self.m_brush)
    else
        self.m_brush:setVisible(true)
        util_spinePlay(self.m_brush, "idleframe", false)
    end

    local eggNode = self.m_eggList[_index]
    local endWorldPos = eggNode:getParent():convertToWorldSpace(cc.p(eggNode:getPosition()))
    local endPos = self.m_brush:getParent():convertToNodeSpace(endWorldPos)
    self.m_brush:setPosition(cc.p(endPos.x, endPos.y + 150))
    self.m_brush:setLocalZOrder(200)

    self:hideEggEffect(eggNode, jackpotName)
    eggNode:setEggName(jackpotName)
    eggNode:setLocalZOrder(100)
    eggNode:runCsbAction(
        "actionframe",
        false,
        function()
            if _fun then
                _fun()
            end
        end
    )

    util_spinePlay(self.m_brush, "actionframe", false)
    performWithDelay(
        self,
        function()
            -- self.m_brush:setVisible(false)
            self.m_jackPotNode:playAnimEgg(jackpotName)
            self:setJpBarEggNum(_data)

            local jackpotNum = self.m_jackPotNode:getEggNum(jackpotName)
            local name = "Node_" .. string.lower(_data[_index]) .. "L"
            self:hideJackpotFremeEffect(name, jackpotNum)

            self.m_jackPotNode:findChild(name):setVisible(true)

            gLobalSoundManager:playSound("EasterSounds/sound_Easter_jackpot_collect.mp3")
            if jackpotNum == 1 then
                self.m_jackPotNode:runCsbAction(
                    "actionframe1",
                    false,
                    function()
                        if self:getBarPlayActionLoop() then
                            self:hideJackpotFremeEffect()
                            self.m_jackPotNode:runCsbAction("actionframe2", true)
                        end
                    end
                )
            elseif jackpotNum == 2 then
                self.m_jackPotNode:runCsbAction("actionframe2", true)
            elseif jackpotNum == 3 then
                self.m_jackPotNode:runCsbAction("actionframe2", true)
                performWithDelay(
                    self,
                    function()
                        gLobalSoundManager:setBackgroundMusicVolume(0)
                        self.m_jackPotNode:runCsbAction("actionframe3")
                        self:playEggCollectOver(jackpotName)
                    end,
                    1
                )
            end
        end,
        45 / 30
    )
end

function EasterCollectGame:playEggCollectOver(_jackpotName)
    gLobalSoundManager:playSound("EasterSounds/sound_Easter_bonus_win.mp3")
    for i = 1, 12 do
        local egg = self.m_eggList[i]
        local name = egg:getEggName()
        if name == _jackpotName then
            egg:runCsbAction("actionframe2", true)
            if _jackpotName == "grand" then
                egg:findChild("major_eff"):setVisible(false)
                egg:findChild("min_eff"):setVisible(false)
            elseif _jackpotName == "major" then
                egg:findChild("grand_eff"):setVisible(false)
                egg:findChild("min_eff"):setVisible(false)
            else
                egg:findChild("grand_eff"):setVisible(false)
                egg:findChild("major_eff"):setVisible(false)
            end
        end
    end
end

function EasterCollectGame:playCollectEggIdle(_jackpotName)
    for i = 1, 12 do
        local egg = self.m_eggList[i]
        local name = egg:getEggName()
        if name == _jackpotName then
            egg:runCsbAction("idle3", false)
            if _jackpotName == "grand" then
                egg:findChild("major_eff"):setVisible(false)
                egg:findChild("min_eff"):setVisible(false)
            elseif _jackpotName == "major" then
                egg:findChild("grand_eff"):setVisible(false)
                egg:findChild("min_eff"):setVisible(false)
            else
                egg:findChild("grand_eff"):setVisible(false)
                egg:findChild("major_eff"):setVisible(false)
            end
        end
    end
end

function EasterCollectGame:hideJackpotFremeEffect(_jpName, _eggNum)
    local jackpot = {"grand", "major", "minor", "mini"}
    for i = 1, #jackpot do
        local jpName = jackpot[i]
        if _eggNum == 3 then
            if jpName ~= _jpName then
                self.m_jackPotNode:findChild("Node_" .. jackpot[i] .. "L"):setVisible(false)
            end
        else
            local eggNum = self.m_jackPotNode:getEggNum(jpName)
            if eggNum < 2 then
                self.m_jackPotNode:findChild("Node_" .. jackpot[i] .. "L"):setVisible(false)
            end
        end
    end
end

function EasterCollectGame:getBarPlayActionLoop()
    local jackpot = {"grand", "major", "minor", "mini"}
    for i = 1, #jackpot do
        local jpName = jackpot[i]
        local eggNum = self.m_jackPotNode:getEggNum(jpName)
        if eggNum >= 2 then
            return true
        end
    end
    return false
end

function EasterCollectGame:showJackpotFrameEffect()
    local jackpot = {"grand", "major", "minor", "mini"}
    for i = 1, #jackpot do
        self.m_jackPotNode:findChild("Node_" .. jackpot[i] .. "L"):setVisible(true)
    end
    self.m_jackPotNode:runCsbAction("idle1", true)
end

function EasterCollectGame:checkBonusOver()
    local states = self.m_machine.m_runSpinResultData.p_bonusStatus or ""

    if states == "CLOSED" then
        return true
    end

    return false
end

function EasterCollectGame:setEggCanClick()
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local cells = selfdata.cells or {}
    local eggTable = {}
    for i = 1, #cells do
        local index = i
        local jackpotName = cells[i]

        local eggNode = self.m_eggList[index]
        if eggNode then
            if jackpotName == "NONE" then -- 没有被点击
                self.m_eggList[i]:findChild("click"):setVisible(true)
                table.insert(eggTable, eggNode)
            else
                self.m_eggList[i]:findChild("click"):setVisible(false)
            end
        end
    end
end

function EasterCollectGame:updateData(_data)
    local index = self.m_eggIndex

    local fun = nil

    if self:checkBonusOver() then
        fun = function()
            -- 播放完毕
            self:brushEggEnd()
        end
    end

    if not self:checkBonusOver() then
        -- 进入下一轮
        self.m_EggIdle = true
        self:setEggCanClick()
    end

    self:startBrushEggs(index, fun, _data)
end

function EasterCollectGame:sendCollectData(collectIndex)
    --select 从0开始
    self.m_EggIdle = false
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = collectIndex - 1, jackpot = self.m_machine.m_jackpotList}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function EasterCollectGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        local serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        globalData.userRate:pushCoins(serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        self.m_serverWinCoins = serverWinCoins

        if spinData.action == "FEATURE" then
            -- self.m_featureData:parseFeatureData(spinData.result)
            -- self:recvBaseData(self.m_featureData)

            -- 更新控制类数据
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)

            --刷新
            self:updateData(self.m_machine.m_runSpinResultData.p_selfMakeData.cells)
        end
    else
        -- 处理消息请求错误情况
    end
end

--鸡蛋刷完了
function EasterCollectGame:brushEggEnd()
    performWithDelay(
        self,
        function()
            self:playEggDark(self.m_lastJackpotName)

            local jpIndex = 1
            if self.m_lastJackpotName == "grand" then
                jpIndex = 1
            elseif self.m_lastJackpotName == "major" then
                jpIndex = 2
            elseif self.m_lastJackpotName == "minor" then
                jpIndex = 3
            elseif self.m_lastJackpotName == "mini" then
                jpIndex = 4
            end
            performWithDelay(
                self,
                function()
                    self:playCollectEggIdle(self.m_lastJackpotName)
                    self:showBonusOver(
                        jpIndex,
                        self.m_serverWinCoins,
                        function()
                            -- 更新游戏内每日任务进度条
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                            -- 通知bonus 结束， 以及赢钱多少
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_serverWinCoins, GameEffect.EFFECT_BONUS})

                            local lastWinCoin = globalData.slotRunData.lastWinCoin
                            globalData.slotRunData.lastWinCoin = 0
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, true, true})
                            globalData.slotRunData.lastWinCoin = lastWinCoin
                            if self.m_callBackFunc then
                                self.m_callBackFunc()
                            end
                        end
                    )
                end,
                3
            )
        end,
        1
    )
end

function EasterCollectGame:playEggDark(_jackpotName)
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local otherPositions = selfdata.otherPositions or {}
    local cells = selfdata.cells or {}

    for i = 1, #otherPositions do
        local posIndex = otherPositions[i] + 1
        local jackpotName = string.lower(cells[posIndex])
        local eggNode = self.m_eggList[posIndex]
        self:hideEggEffect(eggNode, jackpotName)
        eggNode:runCsbAction("dark")
    end

    for i = 1, 12 do
        local egg = self.m_eggList[i]
        local name = egg:getEggName()
        if name ~= nil and name ~= _jackpotName then
            egg:runCsbAction("dark", false)
        end
    end
end

--弹出结算界面
function EasterCollectGame:showBonusOver(_index, _coins, _callBackFun)
    gLobalSoundManager:playSound("EasterSounds/sound_Easter_jackpot_win.mp3")
    local easterJackPotWinView = util_createView("CodeEasterSrc.EasterJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        easterJackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    easterJackPotWinView:initViewData(self.m_machine, _index, _coins, _callBackFun)
    gLobalViewManager:showUI(easterJackPotWinView)
end

function EasterCollectGame:updateEggIdle()
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local cells = selfdata.cells or {}
    local eggTable = {}
    for i = 1, #cells do
        local index = i
        local jackpotName = cells[i]

        local eggNode = self.m_eggList[index]
        if eggNode then
            if jackpotName == "NONE" then -- 没有被点击
                self.m_eggList[i]:findChild("click"):setVisible(true)
                table.insert(eggTable, eggNode)
            end
        end
    end

    if #eggTable > 0 then
        local random = math.random(1, #eggTable)
        local eggNode = eggTable[random]
        eggNode:runCsbAction("idle")
    end
end

return EasterCollectGame
