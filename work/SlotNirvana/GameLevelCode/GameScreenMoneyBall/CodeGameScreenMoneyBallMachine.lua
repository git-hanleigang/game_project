---
-- island li
-- 2019年1月26日
-- CodeGameScreenMoneyBallMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local MoneyBallSpinSlotNode = require "CodeMoneyBallSrc.MoneyBallSpinSlotNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenMoneyBallMachine = class("CodeGameScreenMoneyBallMachine", BaseNewReelMachine)

CodeGameScreenMoneyBallMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenMoneyBallMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
-- CodeGameScreenMoneyBallMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenMoneyBallMachine.m_vecAnimBonus = nil
CodeGameScreenMoneyBallMachine.m_vecMoveCoins = nil
CodeGameScreenMoneyBallMachine.m_vecMoveCoinPos =
{
    cc.p(184, 160),
    cc.p(85, 165),
    cc.p(0, 188),
    cc.p(-85, 165),
    cc.p(-184, 160)
}

local JACKPOT_SCALE_HIGH = 1160
local ADD_COIN_EFFECT_HIGH = 480
-- 构造函数
function CodeGameScreenMoneyBallMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
	--init
	self:initGame()
end

function CodeGameScreenMoneyBallMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("MoneyBallConfig.csv", "LevelMoneyBallConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMoneyBallMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MoneyBall"  
end

-- 此处十分重要  重写SlotNode 必须执行这一句 --
function CodeGameScreenMoneyBallMachine:getBaseReelGridNode()
    return "CodeMoneyBallSrc.MoneyBallSpinSlotNode"
end


function CodeGameScreenMoneyBallMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar
    
    self.m_fsTimeBar = util_createView("CodeMoneyBallSrc.MoneyBallFreespinBarView")
    self:findChild("Node_tishitiao"):addChild(self.m_fsTimeBar)
    self.m_fsTimeBar:updateTip()
    -- 创建view节点方式
    -- self.m_MoneyBallView = util_createView("CodeMoneyBallSrc.MoneyBallView")
    -- self:findChild("xxxx"):addChild(self.m_MoneyBallView)
    self.m_bigCoin = util_createView("CodeMoneyBallSrc.MoneyBallBigCoin")
    self:findChild("Node_bigcoins"):addChild(self.m_bigCoin)

    self.m_jackpotBar = util_createView("CodeMoneyBallSrc.MoneyBallJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)

    self.m_wheel = util_createView("CodeMoneyBallSrc.MoneyBallWheel", self)
    self:findChild("Node_wheel"):addChild(self.m_wheel)
    self.m_wheel:setVisible(false)
    if display.height < 1500 then
        self.m_wheel:updataUiPos()
    end

    self.m_reelEffect = util_createView("CodeMoneyBallSrc.MoneyBallReelEffect")
    self:findChild("Node_coin_run"):addChild(self.m_reelEffect)
    self.m_reelEffect:setVisible(false)

    self.m_nodeMultip = util_createView("CodeMoneyBallSrc.MoneyBallMultip")
    self:addChild(self.m_nodeMultip, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_multipPos = self:findChild("Node"):convertToWorldSpace(cc.p(self:findChild("Node_bigcoins"):getPosition()))
    self.m_nodeMultip:setPosition(self.m_multipPos)
    self.m_nodeMultip:setVisible(false)
    self.m_nodeMultip:setScale(self.m_machineRootScale)

    local scaleYList = {0.87,0.96,1.01,1.1,1.18}
    local rotaYList = {15,19,16,16,14}
    self.m_vecCoinsEffect = {}
    for i = 1, 5, 1 do
        local effect = util_createView("CodeMoneyBallSrc.MoneyBallCoinEffect", i)
        self:addChild(effect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
        local pos = self:findChild("Node"):convertToWorldSpace(cc.p(self:findChild("Node_coin_"..i):getPosition()))
        effect:setPosition(pos)
        effect:setScale(self.m_machineRootScale * scaleYList[i])
        effect:setRotation(rotaYList[i])
        self.m_vecCoinsEffect[i] = effect

    end

    if self.m_winCoinPos == nil then
        local coinLab = self.m_bottomUI.coinWinNode
        self.m_winCoinPos = coinLab:getParent():convertToWorldSpace(cc.p(coinLab:getPosition()))
    end

    local distance = self.m_vecCoinsEffect[1]:getPositionY() - self.m_winCoinPos.y
    if distance > ADD_COIN_EFFECT_HIGH then
        local scale = distance / ADD_COIN_EFFECT_HIGH
        for i = 1, 5, 1 do
            self.m_vecCoinsEffect[i]:setScaleY(scale * scaleYList[i])
        end
    end
    
    self.m_normalUI = self:findChild("base")
    self.m_fsUI = self:findChild("freespin")
    self.m_fsUI:setVisible(false)

    self.m_normalBG = self.m_gameBg:findChild("normal_bg")
    self.m_fsBG = self.m_gameBg:findChild("fs_bg")
    self.m_fsBG:setVisible(false)

    util_csbScale(self.m_gameBg.m_csbNode, self.m_machineRootScale)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 4
        end

        local soundName = "MoneyBallSounds/sound_MoneyBall_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    self.m_bonusBulingSoundArry[1] = "MoneyBallSounds/sound_MoneyBall_bonus_down_1.mp3"
    self.m_bonusBulingSoundArry[2] = "MoneyBallSounds/sound_MoneyBall_bonus_down_2.mp3"
    self.m_bonusBulingSoundArry[3] = "MoneyBallSounds/sound_MoneyBall_bonus_down_3.mp3"
end

function CodeGameScreenMoneyBallMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "MoneyBallSounds/sound_MoneyBall_scatter_down_" .. i .. ".mp3"
        
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenMoneyBallMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                local feature = self.m_runSpinResultData.p_features
                if self:getCurrSpinMode() ~= FREE_SPIN_MODE or #feature > 1 then
                    self:setMinMusicBGVolume( )
                end
                
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenMoneyBallMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i, 15, true)
    end
    -- util_setCascadeOpacityEnabledRescursion(self.m_bottomUI,true)
    -- self.m_bottomUI:setOpacity(100)
    -- self.m_bottomUI:setVisible(false)

    -- temp test tm --
    -- self:findChild("MoneyBall_kuang"):setVisible( false )


    -- Modified by tm ，为基础信号块图片创建mipmap，避免闪烁  -- 还是特么想错了, 模型只有一个,占屏幕百分比很高，所以mipmap暂时不起作用 --
    -- local baseTexture = display.getImage( "GameScreenMoneyBall/MoneyBall1.png" )
    -- if baseTexture ~= nil then
    --     baseTexture:generateMipmap()
    --     baseTexture:setTexParameters(gl.LINEAR_MIPMAP_LINEAR, gl.LINEAR, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
    -- end

    local pos = self.tmNode:getParent():convertToWorldSpace(cc.p(self.tmNode:getPosition()))
    local worldPos = cc.p(pos.x, 0)
    local nodePos = self.tmNode:getParent():convertToNodeSpace(worldPos)
    self.tmNode:setPosition(nodePos.x, nodePos.y)
    -- 开启动画 --
    self:initVertexPosition()
end

function CodeGameScreenMoneyBallMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

end

function CodeGameScreenMoneyBallMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    @desc: 假滚优化
    author:{author}
    time:2020-09-14 11:43:57
    --@little: 
    @return:
]]

--随机信号
function CodeGameScreenMoneyBallMachine:getReelSymbolType(parentData)
    local symbolType = nil
    if self.m_isWaitingNetworkData == true then
        symbolType = BaseNewReelMachine.getReelSymbolType(self, parentData)
    else
        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.bottomRollReels ~= nil
         and parentData.lastReelIndex ~= nil then
            local cloumnIndex = parentData.cloumnIndex
            local reelDatas = self.m_runSpinResultData.p_selfMakeData.bottomRollReels[parentData.cloumnIndex]
            local index = (parentData.lastReelIndex - self.m_iReelRowNum) % #reelDatas + 1
            symbolType = reelDatas[index]
        else
            symbolType = BaseNewReelMachine.getReelSymbolType(self, parentData)
        end
    end
    
    return symbolType
end

--顶部补块
function CodeGameScreenMoneyBallMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local rowIndex = parentData.rowIndex + 1
    local reelDatas = self.m_runSpinResultData.p_selfMakeData.topRollReels[parentData.cloumnIndex]
    local symbolType = reelDatas[rowIndex - self.m_iReelRowNum]
    parentData.symbolType = symbolType
    parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end

function CodeGameScreenMoneyBallMachine:addWinLabEffect(little)
    if little == true then
        self:playCoinWinEffectUI()

        -- local effect, act = util_csbCreate("MoneyBall_Coin_jiesuan.csb")
        -- util_csbPlayForKey(act, "actionframe", false, function ()
        --     effect:removeFromParent(true)
        -- end)
        -- self:addChild(effect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        -- effect:setPosition(cc.p(self.m_winCoinPos.x + 10, self.m_winCoinPos.y - 13))
    else
        self:playCoinWinEffectUI()
        -- local winLabEffect = util_createView("CodeMoneyBallSrc.MoneyBallWinLabEffect")
        -- self:addChild(winLabEffect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        -- winLabEffect:setPosition(cc.p(self.m_winCoinPos.x + 10, self.m_winCoinPos.y - 13))
        -- winLabEffect:showAnim()
    end
    
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMoneyBallMachine:MachineRule_GetSelfCCBName(symbolType)

    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMoneyBallMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenMoneyBallMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]
    local delayTime = 0
    if self.m_nodeMultip:isVisible() then
        delayTime = 0.67
    end
    performWithDelay(self, function()
        BaseNewReelMachine.checkOperaSpinSuccess(self, param)
    end, delayTime)

    print(json.encode(spinData))

    if spinData.action == "FEATURE" then
        release_print("消息返回胡来了")
        local bonusData = spinData.result.bonus
        self.m_wheel:initGameData(bonusData)
        self.m_bonusWinCoin = bonusData.bsWinCoins
    else
        self.m_ScatterAnimCol = {}
        local vecCol = {}
        local scatterNum = 0
        local vecReels = spinData.result.reels
        for i = 1, self.m_iReelColumnNum, 1 do

            for j = 1, self.m_iReelRowNum, 1 do
                local symbol = vecReels[j][i]
                if symbol == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    scatterNum = scatterNum + 1
                end
            end
            if i < 3 then
                self.m_ScatterAnimCol[i] = i
            elseif i == 3 then
                if scatterNum >= 3 then
                    self.m_ScatterAnimCol[i] = i
                end
            elseif i == 4 then
                if scatterNum >= 6 then
                    self.m_ScatterAnimCol[i] = i
                end
            elseif i == 5 then
                if scatterNum >= 9 then
                    self.m_ScatterAnimCol[i] = i
                end
            end
        end
    end
end

function CodeGameScreenMoneyBallMachine:updateNetWorkData()
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.ballScore ~= nil then
        self.m_bAddCoinsEnd = false
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_big_coin.mp3")
        self.m_bigCoin:triggerAnim(function()
            self.m_currentMusicBgName = "MoneyBallSounds/music_MoneyBall_coin_bgm.mp3"
            gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
            self:addCoinAnim(1) -- 从第一列开始
        end)
    elseif self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.randomMul ~= nil then
        self:playMultipAnim()
    else
        BaseNewReelMachine.updateNetWorkData(self)
    end
end

function CodeGameScreenMoneyBallMachine:addCoinAnim(col)
    if col > self.m_iReelColumnNum then
        self.m_bAddCoinsEnd = true
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_coin_end.mp3")
        BaseNewReelMachine.updateNetWorkData(self)
    else
        if self.m_bAddCoinsEnd == false then
            local vecCoins = self.m_runSpinResultData.p_selfMakeData.ballScore
            local vecScore = vecCoins[col]
            self:addCoinsByCol(col, vecScore)
        end
    end
    -- 金币玩法快停 按钮 暂时注销
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
end

function CodeGameScreenMoneyBallMachine:addCoinsByCol(col, vecScore)
    local startPos = self.m_vecMoveCoinPos[col]
    for i = 1, #vecScore, 1 do
        local score = vecScore[i]
        local coin = util_createView("CodeMoneyBallSrc.MoneyBallCoin")
        self:findChild("Node_coin_"..col):addChild(coin)
        coin:setPosition(startPos)
        if col < self.m_iReelColumnNum then
            coin:setScore(score)
        else
            coin:setMultip(score)
            self.m_reelEffect:setVisible(true)
        end
        
        if self.m_vecMoveCoins == nil then
            self.m_vecMoveCoins = {}
        end

        if self.m_vecMoveCoins[col] == nil then
            self.m_vecMoveCoins[col] = coin
            coin:setLocalZOrder(1)
        end
        if i == #vecScore then
            coin.isLastCoin = true
        end
        local delayTime = 1
        local moveTime = 1
        if col == self.m_iReelColumnNum then
            moveTime = 3
        end
        
        local handerldMoveCoin = scheduler.performWithDelayGlobal(function(  )
            self.m_moveCoin = coin
            if col == self.m_iReelColumnNum then
                coin:lastMoveAnim()
                gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_multip_move.mp3")
            else
                coin:moveAnim()
                gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_coin_move.mp3")
            end
            coin:runAction(cc.Sequence:create(cc.MoveTo:create(moveTime, cc.p(0, 0)), cc.CallFunc:create(function()
                if coin ~= self.m_vecMoveCoins[col] then
                    self.m_vecMoveCoins[col]:setScore(score)
                    coin:removeFromParent()
                else
                    local pos = coin:getParent():convertToWorldSpace(cc.p(coin:getPosition()))
                    util_changeNodeParent(self, coin, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    coin:setScale(self.m_machineRootScale)
                    coin:setPosition(pos)
                    local animName = "actionframe"
                    if col == self.m_iReelColumnNum then
                        animName = "actionframe1"
                    end
                    local effectNode, act = util_csbCreate("MoneyBall_Coin_stop.csb")
                    self:addChild(effectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    effectNode:setPosition(pos)
                    effectNode:setScale(self.m_machineRootScale)
                    util_csbPlayForKey(act, animName, false, function()
                        effectNode:removeFromParent()
                    end)
                end
                self.m_vecMoveCoins[col]:addAnim()
                if coin.isLastCoin == true then
                    if self.m_reelEffect:isVisible() and col == self.m_iReelColumnNum then
                        self.m_reelEffect:setVisible(false)
                    end
                    self:addCoinAnim(col + 1)
                end
    
                if col == self.m_iReelColumnNum then
                    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_multip_arrive.mp3")
                else
                    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_coin_arrive.mp3")
                end
                
            end)))
        end, (i - 1) * delayTime, self:getModuleName())
        if self.m_vecHanderld == nil then
            self.m_vecHanderld = {}
        end
        self.m_vecHanderld[#self.m_vecHanderld + 1] = handerldMoveCoin
    end
end

function CodeGameScreenMoneyBallMachine:playMultipAnim()
    globalMachineController:playBgmAndResume("MoneyBallSounds/sound_MoneyBall_xbei_start.mp3", 1.5, 0.4, 1)
    self.m_nodeMultip:setVisible(true)
    self.m_nodeMultip:showMultip(self.m_runSpinResultData.p_selfMakeData.randomMul, function()
        BaseNewReelMachine.updateNetWorkData(self)
    end)
end

function CodeGameScreenMoneyBallMachine:quicklyStopReel(colIndex)
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.ballScore ~= nil
     and self.m_bAddCoinsEnd == false then
        BaseNewReelMachine.updateNetWorkData(self)
        self:clearCurMusicBg()
        self.m_bAddCoinsEnd = true
        if self.m_vecHanderld ~= nil then
            for i = 1, #self.m_vecHanderld, 1 do
                local handerldMoveCoin = self.m_vecHanderld[i]
                scheduler.unscheduleGlobal(handerldMoveCoin)
                handerldMoveCoin = nil
            end
        end
        if self.m_moveCoin ~= nil then
            self.m_moveCoin:stopAllActions()
            self.m_moveCoin:removeFromParent()
        end
        
        
        local vecCoins = self.m_runSpinResultData.p_selfMakeData.ballScore
        for col = 1, self.m_iReelColumnNum, 1 do
            local vecScore = vecCoins[col]
            local score = 0
            for i = 1, #vecScore, 1 do
                score = score + vecScore[i]
            end
            if self.m_moveCoin == self.m_vecMoveCoins[col] then
                self.m_vecMoveCoins[col] = nil
            end
            local coin = self.m_vecMoveCoins[col]
            local node = self:findChild("Node_coin_"..col)
            local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            if coin == nil then
                coin = util_createView("CodeMoneyBallSrc.MoneyBallCoin")
                self:addChild(coin, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                self.m_vecMoveCoins[col] = coin
            else
                util_changeNodeParent(self, coin, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
            end
            coin:setScale(self.m_machineRootScale)
            coin:setPosition(pos)
            if col == 5 then
                coin:showLastIdle(score)
            else
                coin:showIdle()
                coin:setScore(score)
            end
        end
        self.m_moveCoin = nil
    end
    BaseNewReelMachine.quicklyStopReel(self, colIndex)
end

function CodeGameScreenMoneyBallMachine:getLongRunLen(col, index)
    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        if self:getInScatterShowCol(col) then 
            local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

        elseif col > scatterShowCol[#scatterShowCol] then
            local reelRunData = self.m_reelRunInfo[col - 1]
            local diffLen = 8
            local lastRunLen = reelRunData:getReelRunLen()
            len = lastRunLen + diffLen
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    end
    return len
end

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}
--返回本组下落音效和是否触发长滚效果
function CodeGameScreenMoneyBallMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum >= 6 then
            return runStatus.DUANG, true
        else
            return runStatus.NORUN, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum < 9  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    elseif col == 3 then
        if nodeNum >= 6 then
            return runStatus.DUANG, true
        elseif nodeNum >= 3 then
            return runStatus.DUANG, false
        else
            return runStatus.NORUN, false
        end
    else
        if nodeNum >= 6 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

--设置长滚信息
function CodeGameScreenMoneyBallMachine:setReelRunInfo()
    BaseNewReelMachine.setReelRunInfo(self)

    local bonusNum = 0
    for iCol = 1, self.m_iReelColumnNum - 1, 1 do
        for iRow = 1, self.m_iReelRowNum, 1 do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                bonusNum = bonusNum + 1
            end
        end
    end
    if bonusNum == 2 then
        local reelCol = self.m_iReelColumnNum
        local lastColLens = self.m_reelRunInfo[reelCol - 1]:getReelRunLen()
        self.m_reelRunInfo[reelCol - 1]:setNextReelLongRun(true)

        local columnData = self.m_reelColDatas[reelCol]
        local colHeight = columnData.p_slotColumnHeight
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

        local reelRunData = self.m_reelRunInfo[reelCol]
        local preRunLen = reelRunData:getReelRunLen()
        local addRun = runLen - preRunLen
        reelRunData:setReelRunLen(runLen)
        
    end
end

-- 断线重连 
function CodeGameScreenMoneyBallMachine:MachineRule_initGame(  )

    
end

--
--单列滚动停止回调
--
function CodeGameScreenMoneyBallMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
    if reelCol == 4 and self.m_bonusNum == 2 then
        self:creatReelRunAnimation(reelCol + 1)

        local parentData = self.m_slotParents[reelCol + 1]
        local slotParent = parentData.slotParent
        parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
    end
    local haveScatter = false
    for iRow = self.m_iReelRowNum, 1, -1 do
        local slotNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            haveScatter = true
            if self.m_ScatterAnimCol[reelCol] == nil then
                slotNode:runAnim("idleframe")
            else
                slotNode:runAnim("buling")
            end
            
            local lab = slotNode:getCcbProperty("m_lb_num")
            if lab then
                self.m_scatterNum = self.m_scatterNum + 1
                lab:setString(self.m_scatterNum)
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            self.m_bonusNum = self.m_bonusNum + 1
            if (self.m_bonusNum == 1 and reelCol == 1) or (self.m_bonusNum == 2 and reelCol == 3) 
             or (self.m_bonusNum == 3 and reelCol == 5) then
                slotNode:runAnim("buling", false, function()
                    slotNode:runAnim("idleframe2", true)
                end)

                local soundPath = self.m_bonusBulingSoundArry[self.m_bonusNum]
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath,TAG_SYMBOL_TYPE.SYMBOL_BONUS )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

                if self.m_vecAnimBonus == nil then
                    self.m_vecAnimBonus = {}
                end
                self.m_vecAnimBonus[#self.m_vecAnimBonus + 1] = slotNode
            end
        end
    end
    if haveScatter == true and self.m_ScatterAnimCol[reelCol] ~= nil then

        local soundPath = self.m_scatterBulingSoundArry[reelCol]
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath,TAG_SYMBOL_TYPE.SYMBOL_SCATTER )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
end

--
--所有列滚动停止
--
function CodeGameScreenMoneyBallMachine:slotReelDown()
    if self.m_vecAnimBonus ~= nil then
        for i = #self.m_vecAnimBonus, 1, -1 do
            local bonus = self.m_vecAnimBonus[i]
            bonus:runAnim("idleframe")
            table.remove(self.m_vecAnimBonus, i)
        end
    end
    
    BaseNewReelMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenMoneyBallMachine:reelDownNotifyPlayGameEffect( )
    -- 乘倍动画

    if self.m_runSpinResultData.p_selfMakeData.ballScore ~= nil and self.m_runSpinResultData.p_selfMakeData.ballWin == self.m_runSpinResultData.p_winAmount then
        local isNotifyUpdateTop = true
        if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
            isNotifyUpdateTop = false
        end
        local winCoin = self.m_runSpinResultData.p_selfMakeData.ballWin
        self.m_llBigOrMegaNum = winCoin
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoin, isNotifyUpdateTop})
        self:checkBigCoinsBigWin(winCoin)
    end

    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.randomMul ~= nil then
        self.m_nodeMultip:hideMultip(self.m_runSpinResultData.p_selfMakeData.randomMul)
        self:updateWinCoins()
        gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_xbei_reward.mp3")
        self.m_nodeMultip:runAction(cc.Sequence:create(cc.MoveTo:create(0.66, self.m_winCoinPos), cc.CallFunc:create(function()
            self.m_nodeMultip:setPosition(self.m_multipPos)
            self.m_nodeMultip:setVisible(false)
            self:addWinLabEffect()
            self:playGameEffect()
        end)))
    elseif self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.ballScore ~= nil then
        for i = 1, 4, 1 do
            local effect = self.m_vecCoinsEffect[i]
            effect:runAction(cc.Sequence:create(cc.DelayTime:create((i - 1) * 0.5), cc.CallFunc:create(function()
                gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_coin_reward.mp3")
                effect:showAnim()
                performWithDelay(self, function()
                    self:addWinLabEffect(true)
                end, 0.3)
            end)))
        end
        local lastEffect = self.m_vecCoinsEffect[#self.m_vecCoinsEffect]
        lastEffect:runAction(cc.Sequence:create(cc.DelayTime:create(2.1), cc.CallFunc:create(function()
            lastEffect:showAnim()
            gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_multip_reward.mp3")
            performWithDelay(self, function()
                self:addWinLabEffect()
            end, 1.1)
            performWithDelay(self, function()
                for i = 1, #self.m_vecMoveCoins, 1 do
                    self.m_vecMoveCoins[i]:idleAnim()
                end
            end, 2)
        end)))
        performWithDelay(self, function()
            self:resetMusicBg()
            self:playGameEffect()
        end, 5)
        performWithDelay(self, function()
            self:updateWinCoins()
        end, 0.5)
        
    else
        self:playGameEffect()
    end
end

function CodeGameScreenMoneyBallMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenMoneyBallMachine:checkNotifyUpdateWinCoin()

    local winLines = self.m_reelResultLines

    if self.m_runSpinResultData.p_selfMakeData ~= nil and (self.m_runSpinResultData.p_selfMakeData.randomMul or self.m_runSpinResultData.p_selfMakeData.ballScore ~= nil) then
        return
    end
    if #winLines <= 0  then
        return
    end
     
    self:updateWinCoins()
end

function CodeGameScreenMoneyBallMachine:updateWinCoins()
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMoneyBallMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"fs")
    self.m_normalBG:setVisible(false)
    self.m_fsBG:setVisible(true)
    self.m_normalUI:setVisible(false)
    self.m_fsUI:setVisible(true)
    self.m_fsTimeBar:showFsTime()
    self.m_bigCoin:idleFSAnim()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMoneyBallMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    self.m_normalBG:setVisible(true)
    self.m_fsBG:setVisible(false)
    self.m_normalUI:setVisible(true)
    self.m_fsUI:setVisible(false)
    self.m_fsTimeBar:updateTip()
    self.m_bigCoin:idleAnim()
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMoneyBallMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_fs_start.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_window_over.mp3")
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenMoneyBallMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_fs_over.mp3")
    performWithDelay(self, function()
        gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_fs_over_window.mp3")
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
        local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
                gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_window_over.mp3")
                self:triggerFreeSpinOverCallFun()
            end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

        performWithDelay(self, function()
            self:levelFreeSpinOverChangeEffect()
        end, 0.5)
    end, 3)
    
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenMoneyBallMachine:showBonusGameView(effectData)
   
    if self.m_vecMoveCoins ~= nil and #self.m_vecMoveCoins > 0 then
        for i = #self.m_vecMoveCoins, 1, -1 do
            local coin = self.m_vecMoveCoins[i]
            coin:hideAnim()
            table.remove(self.m_vecMoveCoins, i)
        end
        if self.m_bProduceSlots_InFreeSpin == true then
            self.m_bigCoin:idleFSAnim()
        else
            self.m_bigCoin:idleAnim()
        end
        
    end
    self.m_currentMusicBgName = "MoneyBallSounds/music_MoneyBall_wheel_bgm.mp3"
    gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
    self.m_wheel:setVisible(true)
    self:removeSoundHandler( )
    self.m_wheel:showWheel(function()
        self.m_wheel:hideWheel(function()
            self:checkFeatureOverTriggerBigWin(self.m_bonusWinCoin, GameEffect.EFFECT_BONUS)
            self:resetMusicBg()
            effectData.p_isPlay = true
            self:playGameEffect() -- 
        end)
        -- performWithDelay(self, function()
            self:scaleDown()
        -- end, 0.8)
    end)
    performWithDelay(self, function()
        self.m_bigCoin:hideAnim()
    end, 1)
    performWithDelay(self, function()
        
        self:scaleUp()
    end, 1)
    
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMoneyBallMachine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)
   
    if self.m_vecMoveCoins ~= nil and #self.m_vecMoveCoins > 0 then
        for i = #self.m_vecMoveCoins, 1, -1 do
            local coin = self.m_vecMoveCoins[i]
            coin:hideAnim()
            table.remove(self.m_vecMoveCoins, i)
        end
        if self.m_bProduceSlots_InFreeSpin == true then
            self.m_bigCoin:idleFSAnim()
        else
            self.m_bigCoin:idleAnim()
        end
    end
    
    if self.m_vecHanderld ~= nil and #self.m_vecHanderld > 0 then
        for i = #self.m_vecHanderld, 1, -1 do
            table.remove(self.m_vecHanderld, i)
        end
    end

    if self.m_nodeMultip:isVisible() then
        self.m_nodeMultip:stopAllActions()
        self.m_nodeMultip:setPosition(self.m_multipPos)
        self.m_nodeMultip:setVisible(false)
    end
    self.m_scatterNum = 0
    self.m_bonusNum = 0
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    return false -- 用作延时点击spin调用
end

function CodeGameScreenMoneyBallMachine:checkSymbolTypePlayTipAnima( symbolType )
    return false
end

-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenMoneyBallMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenMoneyBallMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenMoneyBallMachine:showEffect_Bonus(effectData)
    self:clearWinLineEffect()
    return BaseNewReelMachine.showEffect_Bonus(self, effectData)
end

---
-- 从参考的假数据中获取数据
--
function CodeGameScreenMoneyBallMachine:getRandomReelType(colIndex,reelDatas)
    
    if reelDatas == nil or #reelDatas == 0 then
        return self:getNormalSymbol(colIndex)
    end
    local reelLen = #reelDatas
    local symbolType = reelDatas[util_random(1,reelLen)]
    while symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER do
        symbolType = reelDatas[util_random(1,reelLen)]
    end
    return symbolType
end

function CodeGameScreenMoneyBallMachine:checktriggerSpecialGame( )
    local istrigger = false

    local features =  self.m_runSpinResultData.p_features

    if features then
       if #features > 1 and features[2] ~= 5 then
            istrigger = true
       end
    end

    return istrigger
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMoneyBallMachine:addSelfEffect()

        
        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMoneyBallMachine:MachineRule_playSelfEffect(effectData)

    -- if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then

        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        effectData.p_isPlay = true
        self:playGameEffect()

    -- end

    
	return true
end

--[[
    @desc: 检测金币赢钱大赢
    author:{author}
    time:2020-08-21 17:15:42
    @return:
]]
function CodeGameScreenMoneyBallMachine:checkBigCoinsBigWin(winAmonut)
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil and self:checkHasGameEffectType(winEffect) == false then
        local index = #self.m_gameEffects
        local delayEffect = GameEffectData.new()
        delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
        table.insert( self.m_gameEffects, index + 1, delayEffect )

        local effectData = GameEffectData.new()
        effectData.p_effectType = winEffect
        table.insert( self.m_gameEffects, index + 2, effectData )
    end
    self:setGameEffectOrder()

    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMoneyBallMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenMoneyBallMachine:checkOnceClipNode()
    if self.m_isOnceClipNode == false then
        return
    end
    local iColNum = self.m_iReelColumnNum
    local reel = self:findChild("sp_reel_0")
    local startX = reel:getPositionX()
    local startY = reel:getPositionY()
    local reelEnd = self:findChild("sp_reel_"..(iColNum-1))
    local endX = reelEnd:getPositionX()
    local endY = reelEnd:getPositionY()
    local reelSize = reelEnd:getContentSize()
    local scaleX = reelEnd:getScaleX()
    local scaleY = reelEnd:getScaleY()
    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY
    local offX = reelSize.width * 0.5
    endX = endX + reelSize.width - startX + offX*2
    endY = endY + reelSize.height - startY
    self.m_onceClipNode = cc.Node:create()
    self.m_onceClipNode:setContentSize(endX, endY)
    
    -- self.m_onceClipNode = cc.ClippingRectangleNode:create(
    --     {
    --         x = startX-offX,
    --         y = startY,
    --         width = endX,
    --         height = endY
    --     }
    -- )

    self.tmNode = cc.TPerspectiveLayer:create()
    
    self.m_clipParent:addChild(self.tmNode)
    self.tmNode:addChild(self.m_onceClipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    self.m_onceClipNode:setPosition(0, math.abs(startY))



    ----------------------------------- debug control ----------------------------------------
    if self.m_configData.DebugControl == true then
        local tmpLabel  = cc.Label:createWithSystemFont("A:开启形变\nS:关闭形变\nD:截图\nF:编辑界面"  , "", 24 )
        tmpLabel:setAnchorPoint( cc.p( 0.5 ,0.5) )
        tmpLabel:setPosition( cc.p( display.width-100 , display.cy ) )
        self:addChild( tmpLabel )


        local listener = cc.EventListenerKeyboard:create()
        listener:registerScriptHandler(function(code, event)
            if code == cc.KeyCode.KEY_A then
                print("你点击了A")
                self:initVertexPosition()
            elseif code == cc.KeyCode.KEY_S then
                print("你点击了S")
                self.tmNode:disableAction()
                self.DebugMark = nil
            elseif code == cc.KeyCode.KEY_D then
                self.tmNode:saveTextureToFile("HolyShit.png")
            elseif code == cc.KeyCode.KEY_F then
                self:drawDebugUI()
            elseif code == cc.KeyCode.KEY_Z then
                self:scaleUp()

            elseif code == cc.KeyCode.KEY_X then
                self:scaleDown()
            end
        end, cc.Handler.EVENT_KEYBOARD_RELEASED)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener,-1)
    end
    
end


-- Effect Node 初始化顶点位置 --
function CodeGameScreenMoneyBallMachine:initVertexPosition()

    -- 开启形变 --
    self.tmNode:enableAction(  cc.size(1,9) , 50 )

    -- 轮盘缩放比率 --
    self.tScale = self.m_machineRootScale

    -- 获取适配方案 --
    local winSize = cc.Director:getInstance():getWinSize()
    local winRate = winSize.width / winSize.height
    self.tPersLayerAtt = self.m_configData:getPersLayerAtt( winRate )
    -- 顶点信息 --
    self.vertexAtt = self.tPersLayerAtt.vertexAtt
     -- 横向顶点跨度
     self.xOffset  = display.width
     -- 更新顶点位置 --
     self.offsetY  = self.tPersLayerAtt.offsetY * self.tScale
     -- 最大UV --
     self.maxUV    = self.tPersLayerAtt.maxUV
    
    self.resetVertexAtt = function(  )
        
        -- 轮盘真实像素高度 --
        local fOriHeight  = self.tPersLayerAtt.reelSize.y
        local fOriWidth   = self.tPersLayerAtt.reelSize.x

        local mainHeight = fOriHeight * self.tScale
        local reelWidth  = fOriWidth  * self.tScale

        
        local vertex = self.vertexAtt
        local distance = {}
        for i = 2, 9 do
            local dis = cc.pGetDistance( cc.p(vertex[i+1].y , vertex[i+1].z ) , cc.p( vertex[i].y , vertex[i].z )  )
            distance[i] = dis
        end

        local uv = {}
        -- 前5个顶点的UV --
        uv[1] = 0
        uv[2] = mainHeight / 2048
        uv[3] = uv[2] + distance[2] / mainHeight * uv[2]
        uv[4] = uv[3] + distance[3] / mainHeight * uv[2]
        uv[5] = uv[4] + distance[4] / mainHeight * uv[2]

        -- 后五个顶点的UV 计算方式与前不一样  需要使用最大UV数值来矫正显示 --
        
        local length =  distance[5] + distance[6] + distance[7] + distance[8] + distance[9]
        uv[6] = uv[5] +  distance[5]  / length * ( self.maxUV - uv[5] )
        uv[7] = uv[6] +  distance[6]  / length * ( self.maxUV - uv[5] )
        uv[8] = uv[7] +  distance[7]  / length * ( self.maxUV - uv[5] )
        uv[9] = uv[8] +  distance[8]  / length * ( self.maxUV - uv[5] )
        uv[10]= self.maxUV

        self.yOffset  = display.cy - mainHeight - self.offsetY
        for i = 1 , 10  do
            -- 此行左顶点 --
            local v  = {}
            v.nIndex = cc.p( 0 , i-1 )
            v.vPos   = self.vertexAtt[i]
            v.pUV    = cc.p( 0 , uv[i] )
    
            -- local vertexOri = self.tmNode:getVertexPosition( v.nIndex )
            local verPos    = cc.vec3(  v.vPos.x ,  v.vPos.y * self.tScale + self.yOffset , v.vPos.z )
            self.tmNode:setVertexPosition( v.nIndex , verPos )
            self.tmNode:setVertexCoord( v.nIndex , v.pUV )
    
            -- 此行右顶点 --
            local v2 = {}
            v2.nIndex = cc.p( 1 , i-1 )
            v2.vPos   = cc.vec3add( self.vertexAtt[i], cc.vec3(self.xOffset ,0,0))  
            v2.pUV    = cc.p( 1 , uv[i] )
    
            verPos    = cc.vec3( v2.vPos.x ,  v2.vPos.y * self.tScale + self.yOffset , v.vPos.z )
            self.tmNode:setVertexPosition( v2.nIndex , verPos )
            self.tmNode:setVertexCoord( v2.nIndex , v2.pUV )
        end
    end
    self:resetVertexAtt()
    
    self.DebugMark = false

end

-- 

-- 执行轮盘缩放和平移 --
function CodeGameScreenMoneyBallMachine:scaleAndMoveNode( fScale , pPos )

    local winSize = cc.Director:getInstance():getWinSizeInPixels()
    local midPoint= cc.p( winSize.width / 2 , winSize.height / 2 )
    
    for i = 1 , 4 do
        local oriPos = self.tmNode:getCaptureVertexPosition( i-1 )

        -- 严格按照 SRT 顺序来操作顶点 -- 

        -- S 缩放 --
        local sx = oriPos.x + ( oriPos.x - midPoint.x ) * ( fScale - 1 )
        local sy = oriPos.y + ( oriPos.y - midPoint.y ) * ( fScale - 1 )
        local destPos= cc.vec3( sx , sy , oriPos.z )

        -- T 平移 --
        destPos = cc.vec3( destPos.x + pPos.x , destPos.y + pPos.y , destPos.z  )

        self.tmNode:setCaptureVertexPosition( i-1 , destPos )
    end

end

function CodeGameScreenMoneyBallMachine:scaleUp()
    -- 
    -- 执行csb放大动画 --
    self.m_bottomUI:checkClearWinLabel()
    self.m_fsTimeBar:stopUpdate()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"actionframe")
    local animName = "actionframe"
    if display.height > JACKPOT_SCALE_HIGH then
        animName = "actionframe1"
    end
    self:runCsbAction(animName, false , function (  )
        -- 默认动作完成 不在执行移动和缩放操纵 --
        self:unscheduleUpdate()
    end)
    -- local function update( dt )
    --     -- 1秒内缩放值到 134% --
    --     self.effNodeScale = self.effNodeScale or 1.0
    --     self.effNodeScale = self.effNodeScale + 0.34 * dt
    --     if self.effNodeScale >= 1.34 then
    --         self.effNodeScale = 1.34
    --         self:unscheduleUpdate()
    --     end
    --     -- 设置缩放 --
    --     self:scaleAndMoveNode( self.effNodeScale , cc.p(0,0) )
    -- end

    local moveDistance = 280 * self.m_machineRootScale
    local function update( dt )
        -- 1秒内缩放值到 134% --
        self.effNodeScale = self.effNodeScale or 1.0
        self.effNodeScale = self.effNodeScale + 0.34 * dt * 1.5
        if self.effNodeScale >= 1.34 then
            self.effNodeScale = 1.34
        end
        -- 1秒内同时向下移动280像素 --
        self.effNodePos     = self.effNodePos or 0
        self.effNodePos     = self.effNodePos + moveDistance * dt * 1.5
        if self.effNodePos >= moveDistance then
            self.effNodePos = moveDistance
        end
        self:scaleAndMoveNode( self.effNodeScale , cc.p(0, -self.effNodePos ) )
    end

    -- 开启定时器 并设置属性 --
    self:onUpdate(update)
    self.tmNode:setCaptureEnabled( true )
end
-- 恢复正常大小显示 --
function CodeGameScreenMoneyBallMachine:scaleDown(func)

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"resetReel")
    local animName = "resetReel"
    if display.height > JACKPOT_SCALE_HIGH then
        animName = "resetReel1"
    end
    self:runCsbAction(animName, false , function ()
        self:unscheduleUpdate()
        self.effNodeScale = 1.0
        self.effNodePos   = 0
        self.tmNode:setCaptureEnabled( false )
        self.m_fsTimeBar:updateTip()
        if self.m_bProduceSlots_InFreeSpin == true then
            self.m_bigCoin:idleFSAnim()
        else
            self.m_bigCoin:idleAnim()
        end
    end)

    local moveDistance = 280 * self.m_machineRootScale
    local function update( dt )
        -- 1秒内缩放值到 134% --
        self.effNodeScale = self.effNodeScale or 1.0
        self.effNodeScale = self.effNodeScale - 0.34 * dt * 1.5
        if self.effNodeScale <= 1.0 then
            self.effNodeScale = 1.0
        end
        -- 1秒内同时向下移动280像素 --
        self.effNodePos     = self.effNodePos or 0
        self.effNodePos     = self.effNodePos - moveDistance * dt * 1.5
        if self.effNodePos <= 0 then
            self.effNodePos = 0
        end
        self:scaleAndMoveNode( self.effNodeScale , cc.p(0, -self.effNodePos ) )
    end

    -- 开启定时器 并设置属性 --
    self:onUpdate(update)
    
    
end

-- 显示调试面板 主要执行一些适配工作 --
function CodeGameScreenMoneyBallMachine:drawDebugUI(  )

    if self.DebugMark == nil then
        return
    end

    self.DebugMark = not self.DebugMark

    if self.DebugMark == false then
        if self.debugPage ~= nil then
            self.debugPage:setVisible( false )
        end
        return
    end

    if self.debugPage == nil then
        self.debugPage = ccui.Layout:create()
        self.debugPage:setName( "Page" )
        self.debugPage:setTouchEnabled(true)
        self.debugPage:setSwallowTouches(false)
        self.debugPage:setAnchorPoint(0.0, 0.0)
        self.debugPage:setContentSize( display.width , display.height )
        self.debugPage:setPosition( cc.p( 0 ,0 ))
        self.debugPage:setClippingEnabled(false)
        self.debugPage:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
        self.debugPage:setBackGroundColor( cc.c4b(0, 0, 255 ) );
        self.debugPage:setBackGroundColorOpacity( 128 )
        self:addChild(self.debugPage , 100)

        -- 10组顶点位置 显示 --
        local posLabel = {}
        for i,v in ipairs( self.vertexAtt ) do
            local posStr    = "Vertex "..i.." Position: "..v.x.." "..v.y.." "..v.z
            local tLabel  = cc.Label:createWithSystemFont(posStr  , "", 24 )
            tLabel:setAnchorPoint( cc.p( 0 ,1) )
            tLabel:setPosition( cc.p( 0 , 330 - i * 30 ) )
            posLabel[i]     = tLabel
            self.debugPage:addChild( tLabel )
        end
        for i,v in ipairs( self.vertexAtt ) do
            local posStr    = "Vertex "..i.." Position: "..v.x.." "..v.y.." "..v.z
            local tLabel  = cc.Label:createWithSystemFont(posStr  , "", 24 )
            tLabel:setAnchorPoint( cc.p( 0 ,1) )
            tLabel:setPosition( cc.p( display.cx , 330 - i * 30 ) )
            self.debugPage:addChild( tLabel )
        end
        -- 当前屏幕信息 --
        local winSize = cc.Director:getInstance():getWinSize()
        local winRate = winSize.width / winSize.height
        local winAttStr = "width:"..winSize.width.."\nheight:"..winSize.height.."\nrate:"..winRate
        local winLabe = cc.Label:createWithSystemFont(winAttStr  , "", 24 )
        winLabe:setAnchorPoint( cc.p( 1 , 0 ) )
        winLabe:setPosition( cc.p( display.width - 50 , display.cy ) )
        self.debugPage:addChild( winLabe )

        local changeValue = function( nIndex , sType , fValue  )

            -- 处理UV --
            if sType == "UV" then
                self.maxUV = self.maxUV + fValue
                self.maxUVLabel:setString(""..self.maxUV )
                self:resetVertexAtt()
                return
            end

            -- 处理整体偏移量 --
            if sType == "YOffset" then
                self.offsetY = self.offsetY + fValue
                self.yOffsetLabel:setString( ""..self.offsetY )
                self:resetVertexAtt()
                return
            end

            -- 处理顶点位置 --
            if sType == "Y" then
                self.vertexAtt[nIndex].y = self.vertexAtt[nIndex].y + fValue 
                self.curVertexYLabel:setString( ""..self.vertexAtt[nIndex].y )
            elseif sType == "Z" then
                self.vertexAtt[nIndex].z = self.vertexAtt[nIndex].z + fValue 
                self.curVertexZLabel:setString( ""..self.vertexAtt[nIndex].z )
            end    
            posLabel[nIndex]:setString( "Vertex "..nIndex.." Position: "..self.vertexAtt[nIndex].x.." "..self.vertexAtt[nIndex].y.." "..self.vertexAtt[nIndex].z )

            -- 更改显示位置 --
            -- 此行左顶点 --
            local v  = {}
            v.nIndex = cc.p( 0 , nIndex - 1 )
            v.vPos   = self.vertexAtt[nIndex]
            
            local verPos    = cc.vec3(  v.vPos.x ,  v.vPos.y * self.tScale + self.yOffset , v.vPos.z )
            self.tmNode:setVertexPosition( v.nIndex , verPos )
            
            -- 此行右顶点 --
            local v2 = {}
            v2.nIndex = cc.p( 1 , nIndex - 1 )
            v2.vPos   = cc.vec3add( self.vertexAtt[nIndex], cc.vec3(self.xOffset  ,0,0))  

            verPos    = cc.vec3( v2.vPos.x ,  v2.vPos.y * self.tScale + self.yOffset , v.vPos.z )
            self.tmNode:setVertexPosition( v2.nIndex , verPos )
        end


        self.debugVertexIndex = 1
        -- 当前编辑顶点 --
        local tmpLable  = cc.Label:createWithSystemFont("当前编辑顶点索引"  , "", 24 )
        tmpLable:setAnchorPoint( cc.p( 0.5 ,0.5) )
        tmpLable:setPosition( cc.p( display.cx , display.height - 30 ) )
        self.debugPage:addChild( tmpLable )
        -- 
        self.curVertexIndexLabel= cc.Label:createWithSystemFont(""..self.debugVertexIndex  , "", 24 )
        self.curVertexIndexLabel:setAnchorPoint( cc.p( 0.5 ,0.5 ) )
        self.curVertexIndexLabel:setPosition( cc.p( display.cx , display.height - 60 ) )
        self.debugPage:addChild( self.curVertexIndexLabel )

        -- 选择当前编辑的顶点按钮
        local pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "-1" )
        pBtn:setPosition( display.cx - 100 ,  display.height - 60 )
        pBtn:addClickEventListener(function(sender)
            self.debugVertexIndex = math.max( self.debugVertexIndex - 1 , 1)
            self.curVertexIndexLabel:setString( ""..self.debugVertexIndex )

            local yValue = self.vertexAtt[self.debugVertexIndex].y
            local zValue = self.vertexAtt[self.debugVertexIndex].z
            self.curVertexYLabel:setString( ""..yValue )
            self.curVertexZLabel:setString( ""..zValue )
        end)
        self.debugPage:addChild(pBtn)

        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "+1" )
        pBtn:setPosition( display.cx + 100 ,  display.height - 60 )
        pBtn:addClickEventListener(function(sender)
            self.debugVertexIndex = math.min( self.debugVertexIndex + 1 , 10 )
            self.curVertexIndexLabel:setString( ""..self.debugVertexIndex )
            local yValue = self.vertexAtt[self.debugVertexIndex].y
            local zValue = self.vertexAtt[self.debugVertexIndex].z
            self.curVertexYLabel:setString( ""..yValue )
            self.curVertexZLabel:setString( ""..zValue )
        end)
        self.debugPage:addChild(pBtn)

        -- 当前顶点的Y轴数据 --
        tmpLable  = cc.Label:createWithSystemFont("当前顶点Y数值"  , "", 24 )
        tmpLable:setAnchorPoint( cc.p( 0.5 ,0.5) )
        tmpLable:setPosition( cc.p( display.cx , display.height - 120 ) )
        self.debugPage:addChild( tmpLable )

        local yValue = self.vertexAtt[self.debugVertexIndex].y
        self.curVertexYLabel= cc.Label:createWithSystemFont(""..yValue  , "", 24 )
        self.curVertexYLabel:setAnchorPoint( cc.p( 0.5 ,0.5 ) )
        self.curVertexYLabel:setPosition( cc.p( display.cx , display.height - 150 ) )
        self.debugPage:addChild( self.curVertexYLabel )
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Y-1" )
        pBtn:setPosition( display.cx - 100 ,  display.height - 150 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Y" , -1 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Y+1" )
        pBtn:setPosition( display.cx + 100 ,  display.height - 150 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Y" , 1 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Y-10" )
        pBtn:setPosition( display.cx - 200 ,  display.height - 150 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Y" , -10 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Y+10" )
        pBtn:setPosition( display.cx + 200 ,  display.height - 150 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Y" , 10 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Y-100" )
        pBtn:setPosition( display.cx - 300 ,  display.height - 150 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Y" , -100 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Y+100" )
        pBtn:setPosition( display.cx + 300 ,  display.height - 150 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Y" , 100 )
        end)
        self.debugPage:addChild(pBtn)

        -- 当前顶点的Z轴数据 --
        tmpLable  = cc.Label:createWithSystemFont("当前顶点Z数值"  , "", 24 )
        tmpLable:setAnchorPoint( cc.p( 0.5 ,0.5) )
        tmpLable:setPosition( cc.p( display.cx , display.height - 220 ) )
        self.debugPage:addChild( tmpLable )

        local zValue = self.vertexAtt[self.debugVertexIndex].z
        self.curVertexZLabel= cc.Label:createWithSystemFont(""..zValue  , "", 24 )
        self.curVertexZLabel:setAnchorPoint( cc.p( 0.5 ,0.5 ) )
        self.curVertexZLabel:setPosition( cc.p( display.cx , display.height - 250 ) )
        self.debugPage:addChild( self.curVertexZLabel )
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Z-1" )
        pBtn:setPosition( display.cx - 100 ,  display.height - 250 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Z" , -1 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Z+1" )
        pBtn:setPosition( display.cx + 100 ,  display.height - 250 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Z" , 1 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Z-10" )
        pBtn:setPosition( display.cx - 200 ,  display.height - 250 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Z" , -10 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Z+10" )
        pBtn:setPosition( display.cx + 200 ,  display.height - 250 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Z" , 10 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Z-100" )
        pBtn:setPosition( display.cx - 300 ,  display.height - 250 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Z" , -100 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "Z+100" )
        pBtn:setPosition( display.cx + 300 ,  display.height - 250 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "Z" , 100 )
        end)
        self.debugPage:addChild(pBtn)

        -- MaxUV 处理 --
        tmpLable  = cc.Label:createWithSystemFont("最大UV数值"  , "", 24 )
        tmpLable:setAnchorPoint( cc.p( 0.5 ,0.5) )
        tmpLable:setPosition( cc.p( display.cx , display.height - 320 ) )
        self.debugPage:addChild( tmpLable )

        self.maxUVLabel= cc.Label:createWithSystemFont(""..self.maxUV  , "", 24 )
        self.maxUVLabel:setAnchorPoint( cc.p( 0.5 ,0.5 ) )
        self.maxUVLabel:setPosition( cc.p( display.cx , display.height - 350 ) )
        self.debugPage:addChild( self.maxUVLabel )
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "MaxUV-0.01" )
        pBtn:setPosition( display.cx - 100 ,  display.height - 350 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "UV" , -0.01 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "MaxUV+0.01" )
        pBtn:setPosition( display.cx + 100 ,  display.height - 350 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "UV" , 0.01 )
        end)
        self.debugPage:addChild(pBtn)

        -- Y轴偏移量 整体移动Layer位置 --
        tmpLable  = cc.Label:createWithSystemFont("Y offset数值"  , "", 24 )
        tmpLable:setAnchorPoint( cc.p( 0.5 ,0.5) )
        tmpLable:setPosition( cc.p( display.cx , display.height - 420 ) )
        self.debugPage:addChild( tmpLable )

        self.yOffsetLabel= cc.Label:createWithSystemFont(""..self.offsetY  , "", 24 )
        self.yOffsetLabel:setAnchorPoint( cc.p( 0.5 ,0.5 ) )
        self.yOffsetLabel:setPosition( cc.p( display.cx , display.height - 450 ) )
        self.debugPage:addChild( self.yOffsetLabel )
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "OffY-1" )
        pBtn:setPosition( display.cx - 100 ,  display.height - 450 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "YOffset" , -1 )
        end)
        self.debugPage:addChild(pBtn)
        pBtn = ccui.Button:create("GameScreenMoneyBall/ui/btn.png", "GameScreenMoneyBall/ui/btn2.png")
        pBtn:setTitleText( "OffY+1" )
        pBtn:setPosition( display.cx + 100 ,  display.height - 450 )
        pBtn:addClickEventListener(function(sender)
            changeValue( self.debugVertexIndex , "YOffset" , 1 )
        end)
        self.debugPage:addChild(pBtn)

    end

    self.debugPage:setVisible( true )
    
    -- debug line --

    -- local drawNode = cc.DrawNode:create()
    -- local lt = display.cx - reelWidth * 2.5
    -- local rt = display.cx + reelWidth * 2.5
    -- local lb = display.cy - mainHeight
    -- local rb = display.cy - mainHeight
    -- local color = cc.c4f(1,1,1,1)
    -- drawNode:drawLine( cc.p(lt, display.cy ), cc.p( rt , display.cy ), color )
    -- drawNode:drawLine( cc.p(lt, display.cy ), cc.p( lt , lb ), color )
    -- drawNode:drawLine( cc.p(lt, lb ), cc.p( rt , rb ), color )
    -- drawNode:drawLine( cc.p(rt, display.cy ), cc.p( rt , rb ), color )
    -- self:addChild( drawNode ,100)
end

function CodeGameScreenMoneyBallMachine:perLoadSLotNodes()
    for i = 1, 10 do
        local node = MoneyBallSpinSlotNode:create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载

        self.m_reelNodePool[#self.m_reelNodePool + 1] = node
    end
end

function CodeGameScreenMoneyBallMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = MoneyBallSpinSlotNode:create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载

        reelNode = node
        release_print("创建了node BaseMachine")
    else
        -- print("从池子里面拿 SlotNode")

        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end

    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    -- print("hhhhh~ "..ccbName)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)

    return reelNode
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenMoneyBallMachine:changeToMaskLayerSlotNode(slotNode)

    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()

    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y + self.yOffset / self.m_machineRootScale)
    -- 切换图层
   -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    util_changeNodeParent(self.m_clipParent,slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s","slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end


--    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenMoneyBallMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y + self.yOffset / self.m_machineRootScale)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE



    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runLineAnim()
    end
    return slotNode
end

function CodeGameScreenMoneyBallMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self.m_clipParent:addChild(reelEffectNode, -1)
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        -- if reelType == "ccui.Layout" then
        --     reelEffectNode:setLocalZOrder(0)
        -- end
        reelEffectNode:setPosition(cc.p(reel:getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end

end

return CodeGameScreenMoneyBallMachine






