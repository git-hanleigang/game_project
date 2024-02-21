---
--xcyy
--2018年5月23日
--LottoPartySpotBonusView.lua
local LottoPartySpotBonusView = class("LottoPartySpotBonusView", util_require("base.BaseView"))
local multiData = {"3X", "4X", "5X", "10X", "15X", "20X", "50X"}
local multiNumData = {3, 4, 5, 10, 15, 20, 50}
local reelMoveNum = {18, 18, 16, 14, 12, 10, 1}
--每一轮的随机光标移动时间
local moveTimes = {
    {0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3, 0.5, 0.6, 0.7, 0.8, 1},
    {0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3, 0.5, 0.6, 0.7, 0.8, 1},
    {0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.5, 0.6, 0.7, 0.8, 1},
    {0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.5, 0.7, 0.8, 1},
    {0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.5, 0.7, 0.8, 1},
    {0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.5, 0.8, 1}
}

function LottoPartySpotBonusView:initUI(_resultData)
    self:createCsbNode("LottoParty/BonusGame.csb")
    self.m_WinResult = _resultData
    self:InitRightAndLeftUI()
    self:InitPlayersUI()
    self:InitMoveData()
    self:initBonusViewData()
    self:playShowAction()
    self.m_WinCoins = 0
   
end

--可移动的点及对应的点的位置
function LottoPartySpotBonusView:InitMoveData()
    self.m_movePosData = {}
    for i = 1, 11 do
        local data = {}
        data.firstPos = i
        data.bMove = true
        if i <= 8 then
            data.secondPos = 20 - i
        elseif i > 8 then
            data.secondPos = 22 - i + 9
        end
        self.m_movePosData[#self.m_movePosData + 1] = data
    end

    local index = 1
    for i = 12, 19 do
        local data = {}
        data.bMove = true
        data.firstPos = i
        data.secondPos = 9 - index
        self.m_movePosData[#self.m_movePosData + 1] = data
        index = index + 1
    end

    index = 1
    for i = 20, 22 do
        local data = {}
        data.bMove = true
        data.firstPos = i
        data.secondPos = 12 - index
        self.m_movePosData[#self.m_movePosData + 1] = data
        index = index + 1
    end
end

function LottoPartySpotBonusView:setFunc(callFun1, callFun2)
    self.m_callFun1 = callFun1
    self.m_callFun2 = callFun2
end

function LottoPartySpotBonusView:setMachine(_machine)
    self.m_Machine = _machine
end

function LottoPartySpotBonusView:playShowAction()
    self:runCsbAction(
        "show",
        false,
        function()
        end,
        60
    )
    self:showWinLoading()
end

function LottoPartySpotBonusView:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

--左右显示每一轮的倍数
function LottoPartySpotBonusView:InitRightAndLeftUI()
    self.m_MultipleItem = {}

    for i = 1, #multiData do
        local multiCsb = {}
        local multi1 = util_createAnimation("LottoParty_BonusMulti.csb")
        local multiLab1 = multi1:findChild("m_lb_num")
        local multiLab2 = multi1:findChild("m_lb_num_0")
        multiLab1:setString(multiData[i])
        multiLab2:setString(multiData[i])
        local multiNode1 = self:findChild("Node_BonusMulti_" .. i .. "_L")
        multiNode1:addChild(multi1)
        multiCsb[1] = multi1

        local multi2 = util_createAnimation("LottoParty_BonusMulti.csb")
        local multiLab1 = multi2:findChild("m_lb_num")
        local multiLab2 = multi2:findChild("m_lb_num_0")
        multiLab1:setString(multiData[i])
        multiLab2:setString(multiData[i])
        local multiNode2 = self:findChild("Node_BonusMulti_" .. i .. "_R")
        multiNode2:addChild(multi2)
        multiCsb[2] = multi2
        self.m_MultipleItem[i] = multiCsb
    end
end

--切换倍数
function LottoPartySpotBonusView:palyMultiHightByIndex(_index)
    if _index > 1 then
        local multiCsb = self.m_MultipleItem[_index]
        for i = 1, 2 do
            local multi = multiCsb[i]
            multi:runCsbAction("actionframe", false, nil, 60)
        end
        --playDark
        local Previndex = _index - 1
        local multiCsb = self.m_MultipleItem[Previndex]
        for i = 1, 2 do
            local multi = multiCsb[i]
            multi:runCsbAction("dark", false, nil, 60)
        end
    else
        local multiCsb = self.m_MultipleItem[_index]
        for i = 1, 2 do
            local multi = multiCsb[i]
            multi:runCsbAction("actionframe", false, nil, 60)
        end
    end
end
--初始化 所在房间内玩家的的位置 带椅子的
function LottoPartySpotBonusView:InitPlayersUI()
    local WinResult = self.m_WinResult --LottoPartyManager:getSpotResult()
    local rankData
    if WinResult and WinResult.data and WinResult.data.rank then
        rankData = WinResult.data.rank
    end
    local index = 1
    for i = 1, 8 do
        local collectata = {}
        if i <= #rankData then
            collectata = rankData[i]
        end
        local playerCsb = util_createView("CodeLottoPartySpotSrc.LottoPartyBonusSpot", collectata)
        if i <= 3 then
            playerCsb:findChild("Slots_M"):setVisible(false)
            playerCsb:findChild("Slots_R"):setVisible(false)
        elseif i > 3 and i <= 5 then
            playerCsb:findChild("Slots_L"):setVisible(false)
            playerCsb:findChild("Slots_R"):setVisible(false)
        else
            playerCsb:findChild("Slots_L"):setVisible(false)
            playerCsb:findChild("Slots_M"):setVisible(false)
        end
        local playerNode = self:findChild("Node_BonusSlots_" .. i)
        playerNode:addChild(playerCsb)
    end
end

--初始化 所有玩家的数据
function LottoPartySpotBonusView:initBonusViewData()
    self.m_rewardPosition = self.m_WinResult.data.rewardPosition
    self.m_rewardRecord = self.m_WinResult.data.rewardRecord
    self.m_collectsData = self.m_WinResult.data.collects

    self.m_spotCsb = {}
    for i = 1, #self.m_collectsData do
        local data = self.m_collectsData[i]
        local node = self:findChild("Node_Spot_" .. i)
        local pos = cc.p(node:getPosition())

        local itemCsb1 = self:createBonusSpotItemByIndex(i, data, 1, pos)
        local itemCsb2 = self:createBonusSpotItemByIndex(i, data, 2, pos)
        local itemCsb3 = self:createBonusSpotItemByIndex(i, data, 3, pos)
        local itemCsb4 = self:createBonusSpotItemByIndex(i, data, 4, pos)
        local itemCsb5 = self:createBonusSpotItemByIndex(i, data, 5, pos)
        local itemCsb6 = self:createBonusSpotItemByIndex(i, data, 6, pos)
        local csbData = {}

        csbData[1] = itemCsb1
        csbData[2] = itemCsb2
        csbData[3] = itemCsb3
        csbData[4] = itemCsb4
        csbData[5] = itemCsb5
        csbData[6] = itemCsb6

        self.m_spotCsb[i] = csbData
    end
end

function LottoPartySpotBonusView:resetAllSpot()
    for i, v in ipairs(self.m_spotCsb) do
        local itemCsbData = self.m_spotCsb[i]
        for i = 1, #itemCsbData do
            local itemCsb = itemCsbData[i]
            itemCsb:resetSpot()
        end
    end
    for i, v in ipairs(self.m_MultipleItem) do
        local multiCsb = self.m_MultipleItem[i]
        for i = 1, 2 do
            local multi = multiCsb[i]
            multi:runCsbAction("idleframe", false, nil, 60)
        end
    end
end

--创建玩家
function LottoPartySpotBonusView:createBonusSpotItem(_num, collectata)
    local spotItem = util_createView("CodeLottoPartySpotSrc.LottoPartySpot", collectata)
    spotItem:setSpotNum(_num)
    return spotItem
end

function LottoPartySpotBonusView:createBonusSpotItemByIndex(_num, _collectata, _index, _pos)
    local spotItem = util_createView("CodeLottoPartySpotSrc.LottoPartySpot" .. _index, _collectata)
    spotItem:setSpotNum(_num)
    spotItem:setPosition(_pos)
    self:findChild("Node_Spot"):addChild(spotItem, _index)
    return spotItem
end

--判断每一轮自己的赢钱
function LottoPartySpotBonusView:getRoundWinCoins()
    local winCoin = 0
    local mutil = multiNumData[self.m_RoundIndex]
    local winData = self.m_rewardPosition[self.m_RoundIndex]
    local winPos = {}

    for key, v in pairs(winData) do
        pos = v + 1
        table.insert(winPos, pos)
    end
    for i = 1, #winPos do
        local pos = winPos[i]
        local collectData = self.m_collectsData[pos]
        if self:isMySelf(collectData.udid) then
            winCoin = winCoin + collectData.coins * mutil
        end
    end
    return winCoin
end

function LottoPartySpotBonusView:onEnter()
end

--开场动效
function LottoPartySpotBonusView:showWinLoading()
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_loading.mp3")
    local loadingView = util_createAnimation("LottoParty_Spotloading.csb")
    loadingView:runCsbAction(
        "show",
        false,
        function()
            loadingView:runCsbAction("idleframe", false, nil, 60)
            performWithDelay(
                self,
                function()
                    self:runCsbAction(
                        "start",
                        false,
                        function()
                            loadingView:removeFromParent()
                            self:showUpdataTime()
                        end,
                        60
                    )
                end,
                20 / 60
            )
        end,
        60
    )
    self:findChild("Node_loading"):addChild(loadingView)
end
--倒计时
function LottoPartySpotBonusView:showUpdataTime()
    local timeView = util_createAnimation("LottoParty_Spot_dumiao.csb")
    timeView:runCsbAction(
        "show",
        false,
        function()
            gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_times.mp3")
            timeView:runCsbAction(
                "actionframe",
                false,
                function()
                    self.m_Machine:setSpotBonusMusic()
                    timeView:runCsbAction(
                        "over",
                        false,
                        function()
                            timeView:removeFromParent()
                            self:playChooseWinSpotEffcet()
                        end,
                        60
                    )
                end,
                60
            )
        end,
        60
    )
    self:findChild("Node_champion"):addChild(timeView)
end

--显示冠军弹板
function LottoPartySpotBonusView:showChampionView()
    self.m_Machine:clearCurMusicBg()

    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_show_champion_player.mp3")
    local shampionView = util_createAnimation("LottoParty_Spot_champion.csb")
    shampionView:runCsbAction(
        "show",
        false,
        function()
            self:resetAllSpot()
            shampionView:runCsbAction(
                "idle",
                false,
                function()
                    shampionView:runCsbAction("over", false, nil, 60)
                    self:runCsbAction(
                        "over2",
                        false,
                        function()
                            self.championCsb:removeFromParent()
                            shampionView:removeFromParent()
                            self:closeUI()
                        end,
                        60
                    )
                end,
                60
            )
        end,
        60
    )
    self:findChild("Node_champion"):addChild(shampionView)
end

--创建冠军头像
function LottoPartySpotBonusView:playChampionPlayer()
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_show_champion_player._frame.mp3")
    local winData = self.m_rewardPosition[self.m_RoundIndex]

    local mutil = multiNumData[self.m_RoundIndex]

    local pos = winData[1] + 1
    local championData = self.m_collectsData[pos]

    local node = self:findChild("Node_Spot_" .. pos)
    local position = cc.p(node:getPosition())

    local itemCsbData = self.m_spotCsb[pos]
    for i = 1, #itemCsbData do
        local spotItem = itemCsbData[i]
        spotItem:setSpotBetCoins(championData.coins * mutil)
        -- spotItem:runCsbAction("actionframe", false, nil, 60)
        spotItem:setVisible(false)
    end

    local winCsb = self:createBonusSpotItem(pos, championData)
    winCsb:setSpotBetCoins(championData.coins * mutil)
    winCsb:runCsbAction("actionframe", false, nil, 60)
    winCsb:setPosition(position)
    self:findChild("Node_Spot"):addChild(winCsb, 100)

    local spotItem = itemCsbData[1]
    local frame = self:createSpotWinFrame()

    frame:setPosition(position)
    self:findChild("Node_Spot"):addChild(frame, 1000)

    frame:runCsbAction(
        "actionframe1",
        false,
        function()
            frame:removeFromParent()
        end,
        60
    )

    performWithDelay(
        self,
        function()
            self.m_WinCoins = self.m_WinCoins + self:getRoundWinCoins()
            self.championCsb = self:createBonusSpotItem(pos, championData)
            self.championCsb:setSpotBetCoins(championData.coins * mutil)
            local championNode = self:findChild("Node_champion")

            local posWorld = spotItem:getParent():convertToWorldSpace(cc.p(spotItem:getPositionX(), spotItem:getPositionY()))
            local pos = championNode:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            self.championCsb:setPosition(pos)
            championNode:addChild(self.championCsb, 100)
            self.championCsb:runCsbAction("actionframe1", false, nil, 60)
            local delay = cc.DelayTime:create(30 / 60)
            local moveTo = cc.MoveTo:create(30 / 60, cc.p(0, 15))
            self.championCsb:runAction(
                cc.Sequence:create(
                    delay,
                    moveTo,
                    cc.CallFunc:create(
                        function()
                            winCsb:removeFromParent()
                            for i = 1, #itemCsbData do
                                local spotItem = itemCsbData[i]
                                spotItem:setSpotBetCoins(championData.coins * mutil)
                                spotItem:runCsbAction("idleframe1", false, nil, 60)
                                spotItem:setVisible(true)
                            end
                        end
                    )
                )
            )
            self:showChampionView()
        end,
        120 / 60
    )
end

function LottoPartySpotBonusView:onExit()
end

function LottoPartySpotBonusView:setClickFunc(_func)
    self.m_func = _func
end

function LottoPartySpotBonusView:getReelStartMovePos(_endPos)
    local index = _endPos
    local maxMoveNum = reelMoveNum[self.m_RoundIndex]
    local moveNum = 0
    while true do
        if self.m_movePosData[index].bMove == true then
            moveNum = moveNum + 1
            if moveNum >= maxMoveNum then
                return self.m_movePosData[index].firstPos
            end
        end
        index = index - 1
        if index < 1 then
            index = 22
        end
    end
end

function LottoPartySpotBonusView:playChooseWinSpotEffcet()
    self.m_RoundIndex = 1
    self.m_MoveMaxReel = 22
    self.m_maxMoveNum = reelMoveNum[self.m_RoundIndex]
    self:getMoveEndPos() --获取停止位置
    self.m_moveReelPos1 = self:getReelStartMovePos(self.m_moveEndReelPos1) --math.random(1, 3) --开始位置1
    self.m_moveReelPos2 = self:getReelStartMovePos(self.m_moveEndReelPos2) --math.random(4, 7) --开始位置2
    self.m_bMoving1 = true
    self.m_bMoving2 = true
    self:palyMultiHightByIndex(self.m_RoundIndex)
    self:ceateMoveReel() --创建随机光柱
    self:startUpdate() --开始移动
end

--移除已经中奖的点
function LottoPartySpotBonusView:clearMovePos(_endPos)
    for i = 1, #self.m_movePosData do
        if _endPos == self.m_movePosData[i].firstPos or _endPos == self.m_movePosData[i].secondPos then
            self.m_movePosData[i].bMove = false
        end
    end
end

--获取停止的位置
function LottoPartySpotBonusView:getMoveEndPos()
    local endPos = self.m_rewardRecord[self.m_RoundIndex]
    --第一个数组对应行数 第二个数组对应列数
    if self.m_RoundIndex <= 3 then
        if #endPos[1] > 0 then
            if #endPos[1] == 1 then
                self.m_moveEndReelPos1 = endPos[1][1] + 9 --行
                if #endPos[2] > 0 then
                    self.m_moveEndReelPos2 = endPos[2][1] + 1 --列
                end
            end
        else
            if #endPos[2] == 2 then
                self.m_moveEndReelPos1 = endPos[2][1] + 1 --列
                self.m_moveEndReelPos2 = endPos[2][2] + 1
            end
        end
    else
        if #endPos[1] == 1 then
            self.m_moveEndReelPos1 = endPos[1][1] + 9 -----行
        end
        if #endPos[2] == 1 then
            self.m_moveEndReelPos1 = endPos[2][1] + 1 ------列
        end
    end
end

function LottoPartySpotBonusView:playNextChooseWinSpotEffcet()
    self:clearMovePos(self.m_moveEndReelPos1)
    self:clearMovePos(self.m_moveEndReelPos2)
    self.m_RoundIndex = self.m_RoundIndex + 1
    self.m_maxMoveNum = reelMoveNum[self.m_RoundIndex]
    self:getMoveEndPos() --获取停止位置
    self:palyMultiHightByIndex(self.m_RoundIndex)
    if self.m_RoundIndex == 7 then
        self:playChampionPlayer()
    else
        self:showRoundView(self.m_RoundIndex)
        if self.m_RoundIndex <= 3 then
            self.m_bMoving1 = true
            self.m_bMoving2 = true
            self.m_moveReelPos1 = self:getReelStartMovePos(self.m_moveEndReelPos1)
            self.m_moveReelPos2 = self:getReelStartMovePos(self.m_moveEndReelPos2)
            self:showMoveReel(self.m_MoveReel1, self.m_moveReelPos1)
            self:showMoveReel(self.m_MoveReel2, self.m_moveReelPos2)
        else
            self.m_bMoving1 = true
            self.m_moveReelPos1 = self:getReelStartMovePos(self.m_moveEndReelPos1)
            self:showMoveReel(self.m_MoveReel2, self.m_moveReelPos2)
        end
    end
end

--下一轮开始
function LottoPartySpotBonusView:showRoundView(_index)
    local RoundView = util_createAnimation("LottoParty_Spot_Xbei.csb")
    local roundMutil = RoundView:findChild("m_lb_num")
    local mutil = multiData[_index]
    roundMutil:setString(mutil)
    if _index >= 2 and _index <= 6 then
        local soundName = "LottoPartySounds/sound_LottoParty_mutil" .. _index .. ".mp3"
        gLobalSoundManager:playSound(soundName)
    end
    self:changeMoveReelMutilNum()
    RoundView:runCsbAction(
        "actionframe",
        false,
        function()
            RoundView:removeFromParent()
            self:startUpdate()
        end,
        60
    )
    self:findChild("Node_champion"):addChild(RoundView)
end

--开始滚动 所有的效果重置
function LottoPartySpotBonusView:startUpdate()
    self.m_MoveNum = 1
    self.m_updataTime = moveTimes[self.m_RoundIndex][self.m_MoveNum]
    if self.m_RoundIndex <= 3 then
        self.m_MoveReel1:setVisible(true)
        self.m_MoveReel2:setVisible(true)
    else
        self.m_MoveReel1:setVisible(true)
    end

    -- self.m_randomNum = math.random(3, 4) --随机差三到四个时开始减速
    self:beginUpdate()
end

--开始随机
function LottoPartySpotBonusView:beginUpdate()
    scheduler.performWithDelayGlobal(
        function()
            self:updateMove()
        end,
        self.m_updataTime,
        "LottoParty"
    )
end

function LottoPartySpotBonusView:isSlow()
    if self.m_MoveNum == self.m_maxMoveNum then
        return true
    end
    return false
end

function LottoPartySpotBonusView:updateMove()
    if self:isSlow() then
        self.m_MoveNum = self.m_MoveNum + 1
        self.m_updataTime = moveTimes[self.m_RoundIndex][self.m_MoveNum]
        self:beginEndUpdata()
        return
    end
    self.m_MoveNum = self.m_MoveNum + 1
    self.m_updataTime = moveTimes[self.m_RoundIndex][self.m_MoveNum]
    self:updataMovePos()
    self:beginUpdate()
end

function LottoPartySpotBonusView:isMoveEndPos(_movePos, _endPos)
    if _movePos == _endPos and self.m_MoveNum == self.m_maxMoveNum then
        return true
    end
    return false
end

--移动光轴
function LottoPartySpotBonusView:updataMovePos()
    if self.m_RoundIndex <= 3 then
        if not self:isMoveEndPos(self.m_moveReelPos1, self.m_moveEndReelPos1) then
            self.m_moveReelPos1 = self:getNextMovPos(self.m_moveReelPos1)
            self:showMoveReel(self.m_MoveReel1, self.m_moveReelPos1)
        else
            self.m_bMoving1 = false
            self:clearMovePos(self.m_moveEndReelPos1)
        end
        if not self:isMoveEndPos(self.m_moveReelPos2, self.m_moveEndReelPos2) then
            self.m_moveReelPos2 = self:getNextMovPos(self.m_moveReelPos2)
            self:showMoveReel(self.m_MoveReel2, self.m_moveReelPos2)
        else
            self.m_bMoving2 = false
            self:clearMovePos(self.m_moveEndReelPos2)
        end
    else
        if not self:isMoveEndPos(self.m_moveReelPos1, self.m_moveEndReelPos1) then
            self.m_moveReelPos1 = self:getNextMovPos(self.m_moveReelPos1)
            self:showMoveReel(self.m_MoveReel1, self.m_moveReelPos1)
        else
            self.m_bMoving1 = false
        end
    end

    if self.m_RoundIndex >= 1 and self.m_RoundIndex <= 6 then
        local soundName = "LottoPartySounds/sound_LottoParty_biao" .. self.m_RoundIndex .. ".mp3"
        gLobalSoundManager:playSound(soundName)
    end
end
--获取下一个可移动的位置
function LottoPartySpotBonusView:getNextMovPos(_pos)
    while true do
        _pos = _pos + 1
        if _pos > 22 then
            _pos = 1
        end
        local posData = self.m_movePosData[_pos]
        if posData.bMove == true then
            return _pos
        end
    end
end

--开始减速
function LottoPartySpotBonusView:beginEndUpdata()
    scheduler.performWithDelayGlobal(
        function()
            self:updateEndMove()
        end,
        self.m_updataTime,
        "LottoParty"
    )
end

--停止
function LottoPartySpotBonusView:updateEndMove()
    self.m_MoveReel1:setVisible(false)
    self.m_MoveReel2:setVisible(false)
    self:playRoundWinPlayer()
    performWithDelay(
        self,
        function()
            local winCoins = self:getRoundWinCoins()
            self.m_WinCoins = self.m_WinCoins + winCoins
            if winCoins > 0 then
                self:showRoundWinCoinsView(winCoins)
            else
                self:playNextChooseWinSpotEffcet()
            end
        end,
        135 / 60
    )
end

function LottoPartySpotBonusView:ceateMoveReel()
    self.m_MoveReel1 = util_createAnimation("LottoParty_spot_gundongtiao.csb")
    self.m_MoveReel2 = util_createAnimation("LottoParty_spot_gundongtiao.csb")
    self:findChild("Node_gundong"):addChild(self.m_MoveReel1)
    self:findChild("Node_gundong"):addChild(self.m_MoveReel2)
    self:showMoveReel(self.m_MoveReel1, self.m_moveReelPos1)
    self:showMoveReel(self.m_MoveReel2, self.m_moveReelPos2)
end

function LottoPartySpotBonusView:playRoundWinPlayer()
    local mutil = multiNumData[self.m_RoundIndex]
    local winData = self.m_rewardPosition[self.m_RoundIndex]
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_show_player._frame.mp3")
    for key, v in pairs(winData) do
        local pos = v + 1
        local collectData = self.m_collectsData[pos]

        local itemCsbData = self.m_spotCsb[pos]
        for i = 1, #itemCsbData do
            local spotItem = itemCsbData[i]
            spotItem:setSpotBetCoins(collectData.coins * mutil)
        end

        local frame = self:createSpotWinFrame()
        local node = self:findChild("Node_Spot_" .. pos)
        local position = cc.p(node:getPosition())
        frame:setPosition(position)
        self:findChild("Node_Spot"):addChild(frame, 1000)
        frame:runCsbAction(
            "actionframe1",
            false,
            function()
                frame:removeFromParent()
                for i = 1, #itemCsbData do
                    local spotItem = itemCsbData[i]
                    spotItem:runCsbAction("dark", false, nil, 60)
                end
            end,
            60
        )
    end
end

function LottoPartySpotBonusView:createSpotWinFrame()
    local frame = util_createAnimation("LottoParty_Playerzj.csb")
    return frame
end

function LottoPartySpotBonusView:changeMoveReelMutilNum()
    local _mutil = multiData[self.m_RoundIndex]
    for i = 1, 4 do
        local mutilLab = self.m_MoveReel1:findChild("BonusMulti" .. i)
        mutilLab:setString(_mutil)
        if self.m_RoundIndex > 3 then
            mutilLab:setScale(0.85)
        end
    end
    for i = 1, 4 do
        local mutilLab = self.m_MoveReel2:findChild("BonusMulti" .. i)
        mutilLab:setString(_mutil)
        if self.m_RoundIndex > 3 then
            mutilLab:setScale(0.85)
        end
    end
end

function LottoPartySpotBonusView:showMoveReel(_moveReel, _movePos)
    local node1 = _moveReel:findChild("Node_1")
    local node2 = _moveReel:findChild("Node_2")
    local node3 = _moveReel:findChild("Node_3")
    local node4 = _moveReel:findChild("Node_4")
    node1:setVisible(false)
    node2:setVisible(false)
    node3:setVisible(false)
    node4:setVisible(false)
    if _movePos >= 1 and _movePos <= 8 then
        node2:setVisible(true)
    elseif _movePos >= 9 and _movePos <= 11 then
        node3:setVisible(true)
    elseif _movePos >= 12 and _movePos <= 19 then
        node1:setVisible(true)
    else
        node4:setVisible(true)
    end
    local posNode = self:findChild("Node_reel" .. _movePos)
    local pos = cc.p(posNode:getPosition())
    _moveReel:setPosition(pos)
end

function LottoPartySpotBonusView:showRoundWinCoinsView(_coins)
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_spot_win_show.mp3")
    local winView = util_createAnimation("LottoParty_Spot_guanjunban.csb")
    local winCoins = winView:findChild("m_lb_coins")
    winCoins:setString(util_formatCoins(_coins, 10))
    self:findChild("Node_WinTip"):addChild(winView)

    local eff1 = util_spineCreate("Socre_LottoParty_Bonus", true, true)
    util_spinePlay(eff1, "idleframe6", true)

    local eff2 = util_spineCreate("Socre_LottoParty_Bonus", true, true)
    util_spinePlay(eff2, "idleframe6", true)
    util_setCascadeOpacityEnabledRescursion(winCoins, true)

    winView:findChild("LottoParty_tbstar_4"):addChild(eff1)
    winView:findChild("LottoParty_tbstar_4_0"):addChild(eff2)

    if not self.m_totalWinView then
        winView:runCsbAction(
            "auto",
            false,
            function()
                local moveTo = cc.MoveTo:create(25 / 60, cc.p(0, -150))
                winView:runAction(
                    cc.Sequence:create(
                        moveTo,
                        cc.CallFunc:create(
                            function()
                                self:showTotalWinView()
                                performWithDelay(
                                    self,
                                    function()
                                        winView:removeFromParent()
                                    end,
                                    5 / 60
                                )
                            end
                        )
                    )
                )
                winView:runCsbAction("over2", false, nil, 60)
            end,
            60
        )
    else
        winView:runCsbAction(
            "auto",
            false,
            function()
                winView:runCsbAction(
                    "over1",
                    false,
                    function()
                        winView:removeFromParent()
                        self:updataTotalWinView()
                    end,
                    60
                )
            end,
            60
        )
    end
end

function LottoPartySpotBonusView:showTotalWinView()
    self.m_totalWinView = util_createAnimation("LottoParty_TotalBonus.csb")
    local winCoins = self.m_totalWinView:findChild("m_lb_coins")
    winCoins:setString(util_formatCoins(self.m_WinCoins, 10))
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_spot_win_down.mp3")
    self.m_totalWinView:runCsbAction(
        "show",
        false,
        function()
            self:playNextChooseWinSpotEffcet()
        end,
        60
    )
    self:findChild("Node_TotalBonus"):addChild(self.m_totalWinView)
end

function LottoPartySpotBonusView:updataTotalWinView()
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_spot_win_down.mp3")
    self.m_totalWinView:runCsbAction(
        "add",
        false,
        function()
            self:playNextChooseWinSpotEffcet()
        end,
        60
    )
    performWithDelay(
        self,
        function()
            local winCoins = self.m_totalWinView:findChild("m_lb_coins")
            winCoins:setString(util_formatCoins(self.m_WinCoins, 10))
        end,
        10 / 60
    )
end

function LottoPartySpotBonusView:closeUI()
    performWithDelay(
        self,
        function()
            if self.m_callFun1 then
                self.m_callFun1()
            end
            self:runCsbAction(
                "over",
                false,
                function()
                    if self.m_callFun2 then
                        self.m_callFun2(self.m_WinCoins)
                    end
                    self:removeFromParent()
                end,
                60
            )
        end,
        30 / 60
    )
end

return LottoPartySpotBonusView
