
local BaseGame = util_require("base.BaseGame")
local SendDataManager = require "network.SendDataManager"
local DragonParadeCollectGame = class("DragonParadeCollectGame", BaseGame)
DragonParadeCollectGame.m_coinList = {}
DragonParadeCollectGame.m_lastJackpotName = nil

function DragonParadeCollectGame:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("DragonParade_dfdc_qipan.csb")
    -- local panelNode = self:findChild("Panel_2")
    -- self:addClick(panelNode)
    self.m_CoinIdle = false
    self.m_bClick = false


    self.m_title = util_createAnimation("DragonParade_dfdc_title.csb")
    self:findChild("Node_title"):addChild(self.m_title)
    self.m_title:runCsbAction("animation0", true)
    self.m_logo = util_createAnimation("DragonParade_dfdc_Logo.csb")
    self:findChild("Node_Logo"):addChild(self.m_logo)
    self.m_logo:runCsbAction("idle", true)


    self.m_jackPotNode = util_createView("CodeDragonParadeSrc.DragonParadeJackPotBarView", self.m_machine, "dfdc")
    self:findChild("Node_jackpot"):addChild(self.m_jackPotNode)

    self:initCoin()

    self.m_CoinIdle = true
end

function DragonParadeCollectGame:onEnter()
    BaseGame.onEnter(self)
    schedule(
        self,
        function()
            if self.m_CoinIdle then
                self:updateCoinIdle()
            end
        end,
        3
    )
end

function DragonParadeCollectGame:updateCoinIdle()
    local list = {}
    for i = 1, 12 do
        local coin = self.m_coinList[i]
        local name = coin:getCoinName()
        if name == "none" then
            table.insert(list, coin)
        end
    end

    if #list > 3 then
        local randNum = math.random(2, 3)

        for i=1,randNum do
            local idx = math.random(1, #list)
            --扫光
            local coin = list[idx]
            coin:runCsbAction("idle", false)
            table.remove(list, idx)
        end
    elseif #list >= 1 then
        local idx = math.random(1, #list)
        --扫光
        local coin = list[idx]
        coin:runCsbAction("idle", false)
    end
end

function DragonParadeCollectGame:clickFunc(sender)
    -- if not self.m_bClick then
        -- return
    -- end
    -- local name = sender:getName()
    -- if name == "Panel_2" then
    --     self:palyOverEffect()
    -- end
end

function DragonParadeCollectGame:onExit()
    BaseGame.onExit(self)
end

function DragonParadeCollectGame:getJpCoinNum()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local pickJackpots = selfData.pickJackpots or {}

    local jackpot = {"grand", "major", "minor", "mini"}
    local jackpotNums = {0, 0, 0, 0}
    for key, value in pairs(pickJackpots) do
        for i = 1, #jackpot do
            if value == jackpot[i] then
                jackpotNums[i] = jackpotNums[i] + 1
                break
            end
        end
    end
    return jackpotNums
end

-- function DragonParadeCollectGame:setJpBarCoinNum()
--     local grandNum, majorNum, minorNum, miniNum = self:getJpCoinNum()


-- end

function DragonParadeCollectGame:initView(data, callBackFunc)
    -- self.m_data = clone(data)
    self.m_callBackFunc = callBackFunc

    self.m_jackPotNode:resetEffect()

    self:updateCoin(data)

    --初始更新jackpot
    local jackNums = self:getJpCoinNum()
    for i = 1, 4 do
        local num = jackNums[i]
        self.m_jackPotNode:setJackpotCoin(i, num, false)
    end

end

function DragonParadeCollectGame:initCoin(_data)
    for i = 1, 12 do
        local data = {}
        data.index = i
        data.callfunc = handler(self, self.coinCallFunc)
        local coin = util_createView("CodeDragonParadeSrc.DragonParadeCollectGameCoin", data)
        local node = self:findChild("Node_" .. (i-1))
        local pos = cc.p(node:getPosition())
        self:findChild("Node_coin"):addChild(coin, i)
        coin:findChild("click"):setVisible(false)
        coin:setPosition(pos)

        self:hideCoinEffect(coin)
        self.m_coinList[i] = coin
    end
end

function DragonParadeCollectGame:updateCoin(_data)
    if _data then
        for i = 1, 12 do
            local coinNode = self.m_coinList[i]
            if coinNode then
                if _data[tostring(i-1)] then
                    --翻开
                    coinNode:findChild("click"):setVisible(false)

                    local jackpotName = string.lower(_data[tostring(i-1)]) -- grand , major , ninor ,mini
                    self:hideCoinEffect(coinNode, jackpotName)
                    coinNode:setCoinName(jackpotName)

                    coinNode:runCsbAction("idle_actionframe", true)
                else
                    --未翻
                    coinNode:findChild("click"):setVisible(true)

                    coinNode:runCsbAction("idle2", true)
                    coinNode:resetCoinName()
                end
            end
        end
    end
end

function DragonParadeCollectGame:hideCoinEffect(_coinNode, _jackpotName)
    local jackpot = {"grand", "major", "minor", "mini"}

    local light = {"Grand_guang", "Major_guang", "Minor_guang", "Mini_guang"}
    local dark = {"grand_dark", "major_dark", "minor_dark", "mini_dark"}

    for i = 1, #jackpot do
        if jackpot[i] == _jackpotName then
            _coinNode:findChild(jackpot[i]):setVisible(true)
            _coinNode:findChild(light[i]):setVisible(true)
            _coinNode:findChild(dark[i]):setVisible(true)
        else
            _coinNode:findChild(jackpot[i]):setVisible(false)
            _coinNode:findChild(light[i]):setVisible(false)
            _coinNode:findChild(dark[i]):setVisible(false)
        end
    end
end
function DragonParadeCollectGame:hideJackpotEffect(_jackPotNode)
    -- local jackpot = {"grand", "major", "minor", "mini"}
    -- for i = 1, #jackpot do
    --     _jackPotNode:findChild("Sprite_" .. jackpot[i] .. "L"):setVisible(false)
    -- end
end

function DragonParadeCollectGame:coinCallFunc(_index)
    self.m_coinIndex = _index

    for i = 1, 12 do
        self.m_coinList[i]:findChild("click"):setVisible(false)
    end
    self:sendCollectData(_index)
end

function DragonParadeCollectGame:startBrushCoins(_index, _fun, _data)
    -- gLobalSoundManager:playSound("EasterSounds/sound_Easter_click_coin.mp3")

    -- local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    -- local pickJackpots = selfData.pickJackpots or {}
    -- self.m_jackPotNode:updateDFDCCoin(pickJackpots)

    local jackpotName = string.lower(_data[tostring(_index-1)]) -- grand , major , ninor ,mini
    self.m_lastJackpotName = jackpotName
    -- if not self.m_brush then
    --     self.m_brush = util_spineCreate("Easter_BonusGameShuazi", true, true)
    --     self:findChild("CoinNode"):addChild(self.m_brush)
    -- else
    --     self.m_brush:setVisible(true)
    --     util_spinePlay(self.m_brush, "idleframe", false)
    -- end

    local jackpotIdx = self:getJackpotIndex()

    local coinNode = self.m_coinList[_index]
    -- local endWorldPos = coinNode:getParent():convertToWorldSpace(cc.p(coinNode:getPosition()))

    self:hideCoinEffect(coinNode, jackpotName)
    coinNode:setCoinName(jackpotName)
    coinNode:setLocalZOrder(100)
    --翻开
    coinNode:runCsbAction(
        "actionframe2",
        false,
        function()
            
        end
    )
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_dfdc_coin_open.mp3")

    performWithDelay(self, function()
        coinNode:runCsbAction("idle_actionframe", true)
 
        --飞粒子
        -- local jackpotIdx = self:getJackpotIndex()
        local jackNums = self:getJpCoinNum()
        local num = jackNums[jackpotIdx]


        local coinNodeEnd = self.m_jackPotNode:getCoinNode(jackpotIdx, num)

        local startPos = util_convertToNodeSpace(coinNode, self)
        local endPos = util_convertToNodeSpace(coinNodeEnd, self)

        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_dfdc_coin_fly_begin.mp3")
        self:runFlyCoinAction(0, 0.5, startPos, endPos, function()
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_dfdc_coin_fly_end.mp3")
            self.m_jackPotNode:setJackpotCoin(jackpotIdx, num, true)
        end, jackpotIdx, jackpotName)


        if _fun then
            _fun()
        end
    end, 30/60)
end


function DragonParadeCollectGame:runFlyCoinAction(time,flyTime,startPos,endPos,callback,jackpotIdx,jackpotName)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("DragonParade_dfdc_coin.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    node:setVisible(false)
    node:setPosition(startPos)

    local particle = util_createAnimation("DragonParade_dfdc_tuoweilizi.csb")
    node:addChild(particle)
    local nodeName = {"Particle_red", "Particle_violet", "Particle_blue", "Particle_green"}
    for i = 1, 4 do
        local particleNode = particle:findChild(nodeName[i])
        if jackpotIdx == i then
            particleNode:setVisible(true)
        else
            particleNode:setVisible(false)
        end
    end

    self:hideCoinEffect(node, jackpotName)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        for i = 1, 4 do
            particle:findChild(nodeName[i]):setDuration(-1)     --设置拖尾时间(生命周期)
            particle:findChild(nodeName[i]):setPositionType(0)   --设置可以拖尾
            particle:findChild(nodeName[i]):resetSystem()
        end

        node:runCsbAction("actionframe", false)
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()

    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
    end)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        for i = 1, 4 do
            particle:findChild(nodeName[i]):stopSystem()--移动结束后将拖尾停掉
        end
        
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(1)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function DragonParadeCollectGame:checkBonusOver()
    local states = self.m_machine.m_runSpinResultData.p_bonusStatus or ""

    if states == "CLOSED" then
        return true
    end

    return false
end

function DragonParadeCollectGame:setCoinCanClick()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local pickJackpots = selfData.pickJackpots or {}
    local coinTable = {}
    for i = 1, 12 do
        local coinNode = self.m_coinList[i]
        if coinNode then
            if pickJackpots[tostring(i-1)] then
                --翻开
                coinNode:findChild("click"):setVisible(false)
            else
                --未翻
                coinNode:findChild("click"):setVisible(true)
            end
        end
    end
end

function DragonParadeCollectGame:updateData(_data)
    local index = self.m_coinIndex

    local fun = nil

    if self:checkBonusOver() then
        fun = function()
            -- 播放完毕
            self:brushCoinEnd()
        end
    end

    if not self:checkBonusOver() then
        -- 进入下一轮
        self.m_CoinIdle = true
        self:setCoinCanClick()
    end

    self:startBrushCoins(index, fun, _data)
end

function DragonParadeCollectGame:sendCollectData(collectIndex)
    --select 从0开始
    self.m_CoinIdle = false
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = collectIndex - 1, jackpot = self.m_machine.m_jackpotList}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function DragonParadeCollectGame:featureResultCallFun(param)
    if not self:isVisible() then
        return
    end
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
            self:updateData(self.m_machine.m_runSpinResultData.p_selfMakeData.pickJackpots)
        end
    else
        -- 处理消息请求错误情况
    end
end


function DragonParadeCollectGame:brushCoinEnd()
    performWithDelay(
        self,
        function()
            self:playFinishAnim(self.m_lastJackpotName)

            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_dfdc_hit_jackpot.mp3")

            self.m_jackPotNode:resetJackpotCoin() --置回小点状态

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

            self.m_jackPotNode:runEffect(jpIndex)


            performWithDelay(
                self,
                function()
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
                40*3/60 + 0.3
            )
        end,
        1
    )
end

function DragonParadeCollectGame:playFinishAnim(_jackpotName)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local pickJackpots = selfData.pickJackpots or {}

    local lastRandom = self:getLastRandomJackpotName()

    local index = 1
    for i = 1, 12 do
        local coin = self.m_coinList[i]
        local name = coin:getCoinName()
        if name == "none" then
            --设置随机jackpot
            if lastRandom[index] then
                local jackpotName = lastRandom[index]
                self:hideCoinEffect(coin, jackpotName)
                index = index + 1
            end
            --翻转
            coin:runCsbAction("over", false)
        elseif name == _jackpotName then
            --中奖的
            coin:runCsbAction("shouji", false, function()
                coin:runCsbAction("shouji", false, function()
                    coin:runCsbAction("shouji", false, function()

                    end)
                end)
            end)
        end
    end
    --over时间线
    performWithDelay(self, function()
        --置灰
        for i = 1, 12 do
            local coin = self.m_coinList[i]
            local name = coin:getCoinName()
            if name ~= _jackpotName then
                coin:runCsbAction("dark", false)
            end
        end
    end, 35/60)

end

--弹出结算界面
function DragonParadeCollectGame:showBonusOver(_index, _coins, _callBackFun)
    self.m_machine:showJackpot(_index, _coins, function()
        if _callBackFun then
            _callBackFun()
        end
    end)
end

function DragonParadeCollectGame:getLastRandomJackpotName()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local pickJackpots = selfData.pickJackpots or {}

    local jackpot = {"grand","grand","grand", "major","major","major", "minor","minor","minor", "mini", "mini", "mini"}

    for key, value in pairs(pickJackpots) do
        for i = 1, #jackpot do
            if value == jackpot[i] then
                table.remove(jackpot, i)
                break
            end
        end
        
    end

    local ret = {}
    while #jackpot > 0
    do
        local randIdx = math.random(1, #jackpot)
        table.insert(ret, jackpot[randIdx])
        table.remove(jackpot, randIdx)
    end
    
    return ret
end

function DragonParadeCollectGame:getJackpotIndex()
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
    return jpIndex
end

return DragonParadeCollectGame
