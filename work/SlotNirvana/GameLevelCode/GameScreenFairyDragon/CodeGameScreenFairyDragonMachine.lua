---
-- island li
-- 2019年1月26日
-- CodeGameScreenFairyDragonMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenFairyDragonMachine = class("CodeGameScreenFairyDragonMachine", BaseFastMachine)

CodeGameScreenFairyDragonMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFairyDragonMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenFairyDragonMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenFairyDragonMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3 
CodeGameScreenFairyDragonMachine.SYMBOL_MEN = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1


CodeGameScreenFairyDragonMachine.CHANGE_MEN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 变门图标
CodeGameScreenFairyDragonMachine.MOVE_MEN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 移动门

CodeGameScreenFairyDragonMachine.DEALY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- 等待事件第一个执行

CodeGameScreenFairyDragonMachine.m_isPlayFirstReelEffect = false
CodeGameScreenFairyDragonMachine.m_isRSAutoSpin = true
CodeGameScreenFairyDragonMachine.m_respinReelRun = false

-- 构造函数
function CodeGameScreenFairyDragonMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_jackpotSymbolNum = 0
    self.m_scatterSymbolNum = 0
    self.m_isPlayFirstReelEffect = false
    self.m_isRSAutoSpin = true
    self.m_respinReelRun = false
    self.m_isBonusTrigger = false
    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
end

function CodeGameScreenFairyDragonMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FairyDragonConfig.csv")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenFairyDragonMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "FairyDragonSounds/FairyDragon_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "FairyDragonSounds/FairyDragon_scatter_down2.mp3"
        else
            soundPath = "FairyDragonSounds/FairyDragon_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFairyDragonMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FairyDragon"
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenFairyDragonMachine:getNetWorkModuleName()
    return "FairyDragonV2"
end

function CodeGameScreenFairyDragonMachine:changeConfigData()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FairyDragonConfig.csv", "LevelFairyDragonConfig.lua")
    globalData.slotRunData.levelConfigData = self.m_configData
end
function CodeGameScreenFairyDragonMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_reelRunSound = "FairyDragonSounds/FairyDragonSounds_longRun.mp3"
    
    -- 创建view节点方式
    self.m_FairyDragonView = util_createView("FairyDragonSrc.FairyDragonJackPotBarView")
    self.m_FairyDragonView:initMachine(self)
    self:findChild("jackpot"):addChild(self.m_FairyDragonView)

    self.m_jpGrandDarkImg = self.m_FairyDragonView:findChild("an")
    self.m_jpGrandSuo = util_createAnimation("FairyDragon_suo.csb")
    self.m_FairyDragonView:findChild("suo"):addChild(self.m_jpGrandSuo)
    self.m_jpGrandSuoLight = util_createAnimation("FairyDragon_suo_jiesuo.csb")
    self.m_FairyDragonView:findChild("suo"):addChild(self.m_jpGrandSuoLight)
    self.m_jpGrandDarkImg:setVisible(false)
    self.m_jpGrandSuo:setVisible(false)
    self.m_jpGrandSuoLight:setVisible(false)
    self.m_jpGrandSuo:runCsbAction("actionframe",true)

    self.m_betChangeWaitNode = cc.Node:create()
    self:addChild(self.m_betChangeWaitNode)
    

    self:findChild("sp_reel_5"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 1
            if winRate <= 1 then
                soundIndex = 1
                soundTime = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 1.5
            elseif winRate > 3 then
                soundIndex = 3
                soundTime = 2
            end

            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
            if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE  then
                print("freespin最后一次 无论是否大赢都播放赢钱音效")
            else

                if winRate >= self.m_HugeWinLimitRate then
                    return
                elseif winRate >= self.m_MegaWinLimitRate then
                    return
                elseif winRate >= self.m_BigWinLimitRate then
                    return
                end
                
            end

            local soundName = "FairyDragonSounds/music_FairyDragon_last_win_".. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
            
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end


function CodeGameScreenFairyDragonMachine:initFreeSpinBar()

    local node_bar = self.m_bottomUI:findChild("node_bar")
    self.m_baseFreeSpinBar = util_createView("Levels.FreeSpinBar")
    node_bar:addChild(self.m_baseFreeSpinBar)
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,node_bar)
    self.m_baseFreeSpinBar:setPosition(cc.p(pos.x,73))
    self.m_baseFreeSpinBar:setScale(0.8)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenFairyDragonMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()

            gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if self.isRespin then
                        
                    else
                        if not self.isInBonus then
                            self:resetMusicBg()
                            self:setMinMusicBGVolume( )
                        end
                    end
                    self.isRespin = false
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenFairyDragonMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self.m_iBetLevel = self:updateBetLevel()

    if self.m_iBetLevel == 0 then
        self.m_jpGrandDarkImg:setVisible(true)
        self.m_jpGrandSuo:setVisible(true)
    end
    
end

function CodeGameScreenFairyDragonMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)

        local perBetLevel = self:updateBetLevel()
        if self.m_iBetLevel ~= perBetLevel then
            self.m_iBetLevel = perBetLevel

            self.m_betChangeWaitNode:stopAllActions()

            if self.m_iBetLevel == 0  then

                
                self.m_jpGrandDarkImg:setVisible(true)
                self.m_jpGrandSuo:setVisible(true)
                self.m_jpGrandSuo:runCsbAction("actionframe",true)

            else
                
                gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_changeBetToUnlock.mp3")

                performWithDelay(self.m_betChangeWaitNode,function(  )
                    
                    self.m_jpGrandSuo:setVisible(false)
                    self.m_jpGrandSuoLight:setVisible(false)
                end,0.5)
                self.m_jpGrandSuoLight:setVisible(true)
                self.m_jpGrandDarkImg:setVisible(false)
                self.m_jpGrandSuo:runCsbAction("jiesuo")
                
                self.m_jpGrandSuoLight:findChild("Particle_1"):resetSystem()
                self.m_jpGrandSuoLight:runCsbAction("jiesuo")
            end

        end

    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end

function CodeGameScreenFairyDragonMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


function CodeGameScreenFairyDragonMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("bgNode"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFairyDragonMachine:MachineRule_GetSelfCCBName(symbolType)
    if self.SYMBOL_SCORE_10 == symbolType then
        return "Socre_FairyDragon_10"
    elseif self.SYMBOL_SCORE_11 == symbolType then
        return "Socre_FairyDragon_11"
    elseif self.SYMBOL_SCORE_12 == symbolType then
        return "Socre_FairyDragon_12"
    elseif self.SYMBOL_MEN == symbolType then
        return "Socre_FairyDragon_men"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFairyDragonMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_11, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_12, count = 2}
    -- loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JACJKPOT, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MEN, count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenFairyDragonMachine:MachineRule_initGame()
    if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        self.m_baseFreeSpinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount,"")        --断线重连刷新free次数
    end
    if self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self.isRespin = true
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenFairyDragonMachine:slotOneReelDown(reelCol)
    BaseFastMachine.slotOneReelDown(self, reelCol)

    for iRow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]

        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self.m_scatterSymbolNum = self.m_scatterSymbolNum + 1

            if (reelCol == 1 and self.m_scatterSymbolNum == 1) or (reelCol == 5 and self.m_scatterSymbolNum == 2) then
                
                if reelCol == 1 then
                    gLobalSoundManager:playSound("FairyDragonSounds/FairyDragon_scatter_down1.mp3")
    
                elseif reelCol == 5 then
                    gLobalSoundManager:playSound("FairyDragonSounds/FairyDragon_scatter_down2.mp3")
    
                -- elseif reelCol == 4 then
                --     gLobalSoundManager:playSound("FairyDragonSounds/FairyDragon_scatter_down3.mp3")
                    
                end

                local targSp = self:setSymbolToClipReel(reelCol, iRow, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                if targSp then
                    targSp:runAnim(
                        "buling",
                        false,
                        function()
                            local currSp = targSp
                            targSp:runAnim(
                                "idleframe3",
                                false,
                                function()
                                    currSp:runAnim("idleframe4",true)
                                end
                            )
                        end
                    )
                end
            end
        end
    end

    
    
end


function CodeGameScreenFairyDragonMachine:slotOneReelDownFinishCallFunc(reelCol)
    if reelCol == 1 then
        self:playFirstColReelMove()
    end
    CodeGameScreenFairyDragonMachine.super.slotOneReelDownFinishCallFunc(self,reelCol)
end

function CodeGameScreenFairyDragonMachine:getFirstColReelMoveArray()
    local FirstFreeSpinMoveArry = {}
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        
        local isMove = false

        local tempRow = nil
        for iRow = self.m_iReelRowNum, 1, -1 do --行
            if self.m_stcValidSymbolMatrix[iRow][1] == self.SYMBOL_MEN then
                tempRow = iRow
            else
                break
            end
        end
        if tempRow ~= nil and tempRow ~= 1 then
            FirstFreeSpinMoveArry[#FirstFreeSpinMoveArry + 1] = {col = 1, row = tempRow, direction = "down"}
        end
        tempRow = nil
        for iRow = 1, self.m_iReelRowNum, 1 do --行
            if self.m_stcValidSymbolMatrix[iRow][1] == self.SYMBOL_MEN then
                tempRow = iRow
            else
                break
            end
        end

        if tempRow ~= nil and tempRow ~= self.m_iReelRowNum then
            FirstFreeSpinMoveArry[#FirstFreeSpinMoveArry + 1] = {col = 1, row = tempRow, direction = "up"}
        end
    end

    return FirstFreeSpinMoveArry
end

function CodeGameScreenFairyDragonMachine:showFirstMoveTip(iRow , iCol , direction,func )
    

    gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_FirstReelMove_Tip.mp3")

    local index = self:getPosReelIdx(iRow, iCol)
    local pos = util_getOneGameReelsTarSpPos(self,index ) 
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
    local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
    local tipNode = util_createAnimation("Socre_FairyDragon_men_jiantou.csb")
    self:findChild("sp_reel_5"):addChild(tipNode,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)
    tipNode:runCsbAction("actionframe",true)
    tipNode:setPosition(startPos)
    
    if direction == "down" then
        tipNode:setScale(-1) 
    else 
        iRow = iRow - self.m_iReelRowNum + 1
    end
    
    local distance = (1 - iRow) * self.m_SlotNodeH
    local runTime = 1 

    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(1)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end
        
    end)
    actList[#actList + 1] = cc.MoveBy:create(runTime, cc.p(0, distance))
    actList[#actList + 1] = cc.DelayTime:create(1)
    actList[#actList + 1] =cc.CallFunc:create(
        function()
            tipNode:removeFromParent()
        end
    )
    local seq = cc.Sequence:create( actList )
    tipNode:runAction(seq)

end

function CodeGameScreenFairyDragonMachine:playOtherFirstReelMove(MoveArry)

    gLobalSoundManager:playSound("FairyDragonSounds/FairyDragonSounds_Men_Move.mp3")

    local delayTime = 0

    local icolList = {}

    for i = 1, #MoveArry, 1 do
        local temp = MoveArry[i]
        local iRow = temp.row
        local iCol = temp.col
        local moveNode = {} --移动的门
        local iTempRow = {} --隐藏小块避免穿帮
        if temp.direction == "up" then -- 由下向上

            for i = 1,  self.m_iReelRowNum do
                local row = i

                if row <= iRow then
                     -- 创建 门图标的位置
                    local index = self:getPosReelIdx(row, iCol)
                    local pos = util_getOneGameReelsTarSpPos(self,index ) 
                    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                    local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                    local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                    symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row + 100 )
                    symbol:runCsbAction("actionframe2")
                    local symbolInfo = {}
                    symbolInfo.symbol = symbol
                    table.insert(moveNode, symbolInfo)
                else
                     -- 创建其他图标
                     local index = self:getPosReelIdx(row, iCol)
                     local pos = util_getOneGameReelsTarSpPos(self,index ) 
                     local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                     local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
 
                     local symbolType = self.m_stcValidSymbolMatrix[row][iCol]
                     local symbol = self:createMoveSymbolActNode(startPos, self:findChild("sp_reel_5"),symbolType) 
                     symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row  )
                     local symbolInfo = {}
                     symbolInfo.symbol = symbol
                     table.insert(moveNode, symbolInfo)
                     -- print("第 " .. iCol .. "列New row ============" .. symbolInfo.row)
                end
                
            end

            -- 创建屏幕下的图标
            for i = 1, (self.m_iReelRowNum - iRow) do
                local row = 1 - i
                local index = self:getPosReelIdx(row, iCol)
                local pos = util_getOneGameReelsTarSpPos(self,index ) 
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row )
                symbol:runCsbAction("actionframe2")
                local symbolInfo = {}
                symbolInfo.symbol = symbol
                table.insert(moveNode, symbolInfo)
            end

            iRow = iRow - self.m_iReelRowNum + 1
        elseif temp.direction == "down" then -- 由上向下


            for i = 1, self.m_iReelRowNum do
                if i >= iRow then
                     -- 创建门图标
                    local row = i
                    local index = self:getPosReelIdx(row, iCol)
                    local pos = util_getOneGameReelsTarSpPos(self,index ) 
                    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                    local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                    local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                    symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row + 100 )
                    symbol:runCsbAction("actionframe2")
                    local symbolInfo = {}
                    symbolInfo.symbol = symbol
                    table.insert(moveNode, symbolInfo)
                    -- print("第 " .. iCol .. "列New row ============" .. symbolInfo.row)
                else
                     -- 创建其他图标
                    local row = i
                    local index = self:getPosReelIdx(row, iCol)
                    local pos = util_getOneGameReelsTarSpPos(self,index ) 
                    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                    local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)

                    local symbolType = self.m_stcValidSymbolMatrix[row][iCol]
                    local symbol = self:createMoveSymbolActNode(startPos, self:findChild("sp_reel_5"),symbolType) 
                    symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row  )
                    local symbolInfo = {}
                    symbolInfo.symbol = symbol
                    table.insert(moveNode, symbolInfo)
                    -- print("第 " .. iCol .. "列New row ============" .. symbolInfo.row)
                end
                
            end
           

            -- 创建超过上屏幕的图标
            for i = 1, iRow do
                local row = i + self.m_iReelRowNum

                local index = self:getPosReelIdx(row, iCol)
                local pos = util_getOneGameReelsTarSpPos(self,index ) 
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row )
                symbol:runCsbAction("actionframe2")
                local symbolInfo = {}
                symbolInfo.symbol = symbol
                table.insert(moveNode, symbolInfo)

            end
            
        end

        local distance = (1 - iRow) * self.m_SlotNodeH
        local runTime = 1 -- math.abs(distance) / 500
        delayTime = math.max(delayTime, runTime)
        for i, v in ipairs(moveNode) do
            local symbol = v.symbol
            local seq =
                cc.Sequence:create(
                cc.MoveBy:create(runTime, cc.p(0, distance)),
                cc.CallFunc:create(
                    function()
                       
                        symbol:removeFromParent()
                    end
                )
            )
            symbol:runAction(seq)
        end

        
        table.insert(icolList,iCol)
        for iRow = 1, self.m_iReelRowNum do
            local targetNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targetNode then
                targetNode:setVisible(false)
            end
            
        end 
     
    end

    
    


    local actNdoe = cc.Node:create()
    self:addChild(actNdoe)

    performWithDelay(actNdoe,function()
      

        for i=1,#icolList do
            local iCol = icolList[i]
            for iRow = 1, self.m_iReelRowNum do
                local targetNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targetNode then
                    targetNode:setVisible(true)
                    
                    if targetNode.p_symbolImage  then
                        targetNode.p_symbolImage:removeFromParent()
                        targetNode.p_symbolImage = nil
                    end
                    targetNode.m_ccbName = ""
                    targetNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_MEN), self.SYMBOL_MEN)
                    targetNode:runAnim("idle2")
                end
               
            end
        end
        
        actNdoe:removeFromParent()
    end,delayTime)


    return delayTime
end

function CodeGameScreenFairyDragonMachine:playFirstReelMove(MoveArry)

    gLobalSoundManager:playSound("FairyDragonSounds/FairyDragonSounds_Men_Move.mp3")

    local delayTime = 0


    for i = 1, #MoveArry, 1 do
        local temp = MoveArry[i]
        local iRow = temp.row
        local iCol = temp.col
        local moveNode = {} --移动的门
        local iTempRow = {} --隐藏小块避免穿帮
        if temp.direction == "up" then -- 由下向上

            for i = 1,  self.m_iReelRowNum do
                local row = i

                if row <= iRow then
                     -- 创建 门图标的位置
                    local index = self:getPosReelIdx(row, iCol)
                    local pos = util_getOneGameReelsTarSpPos(self,index ) 
                    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                    local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                    local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                    symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row + 100 )
                    symbol:runCsbAction("actionframe2")
                    local symbolInfo = {}
                    symbolInfo.symbol = symbol
                    table.insert(moveNode, symbolInfo)
                else
                     -- 创建其他图标
                     local index = self:getPosReelIdx(row, iCol)
                     local pos = util_getOneGameReelsTarSpPos(self,index ) 
                     local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                     local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
 
                     local symbolType = self.m_stcValidSymbolMatrix[row][iCol]
                     local symbol = self:createMoveSymbolActNode(startPos, self:findChild("sp_reel_5"),symbolType) 
                     symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row  )
                     local symbolInfo = {}
                     symbolInfo.symbol = symbol
                     table.insert(moveNode, symbolInfo)
                     -- print("第 " .. iCol .. "列New row ============" .. symbolInfo.row)
                end
                
            end

            -- 创建屏幕下的图标
            for i = 1, (self.m_iReelRowNum - iRow) do
                local row = 1 - i
                local index = self:getPosReelIdx(row, iCol)
                local pos = util_getOneGameReelsTarSpPos(self,index ) 
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row )
                symbol:runCsbAction("actionframe2")
                local symbolInfo = {}
                symbolInfo.symbol = symbol
                table.insert(moveNode, symbolInfo)
            end

            iRow = iRow - self.m_iReelRowNum + 1
        elseif temp.direction == "down" then -- 由上向下


            for i = 1, self.m_iReelRowNum do
                if i >= iRow then
                     -- 创建门图标
                    local row = i
                    local index = self:getPosReelIdx(row, iCol)
                    local pos = util_getOneGameReelsTarSpPos(self,index ) 
                    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                    local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                    local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                    symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row + 100 )
                    symbol:runCsbAction("actionframe2")
                    local symbolInfo = {}
                    symbolInfo.symbol = symbol
                    table.insert(moveNode, symbolInfo)
                    -- print("第 " .. iCol .. "列New row ============" .. symbolInfo.row)
                else
                     -- 创建其他图标
                    local row = i
                    local index = self:getPosReelIdx(row, iCol)
                    local pos = util_getOneGameReelsTarSpPos(self,index ) 
                    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                    local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)

                    local symbolType = self.m_stcValidSymbolMatrix[row][iCol]
                    local symbol = self:createMoveSymbolActNode(startPos, self:findChild("sp_reel_5"),symbolType) 
                    symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row )

                    local symbolInfo = {}
                    symbolInfo.symbol = symbol
                    table.insert(moveNode, symbolInfo)
                    -- print("第 " .. iCol .. "列New row ============" .. symbolInfo.row)
                end
                
            end
           

            -- 创建超过上屏幕的图标
            for i = 1, iRow do
                local row = i + self.m_iReelRowNum

                local index = self:getPosReelIdx(row, iCol)
                local pos = util_getOneGameReelsTarSpPos(self,index ) 
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                local startPos = self:findChild("sp_reel_5"):convertToNodeSpace(worldPos)
                local symbol = self:createSymbolActNode(startPos, self:findChild("sp_reel_5")) 
                symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 - row )
                symbol:runCsbAction("actionframe2")
                local symbolInfo = {}
                symbolInfo.symbol = symbol
                table.insert(moveNode, symbolInfo)

            end
            
        end

        local distance = (1 - iRow) * self.m_SlotNodeH
        local runTime = 1 -- math.abs(distance) / 500
        delayTime = math.max(delayTime, runTime)
        for i, v in ipairs(moveNode) do
            local symbol = v.symbol
            local seq =
                cc.Sequence:create(
                cc.MoveBy:create(runTime, cc.p(0, distance)),
                cc.CallFunc:create(
                    function()
                       
                        symbol:removeFromParent()
                    end
                )
            )
            symbol:runAction(seq)
        end

    end

    for iRow = 1, self.m_iReelRowNum do
        local targetNode = self:getFixSymbol(1, iRow, SYMBOL_NODE_TAG)
        if targetNode then
            targetNode:setVisible(false)
        end
       
    end


    local actNdoe = cc.Node:create()
    self:addChild(actNdoe)

    performWithDelay(actNdoe,function()
      
        for iRow = 1, self.m_iReelRowNum do
            local targetNode = self:getFixSymbol(1, iRow, SYMBOL_NODE_TAG)
            if targetNode then
                targetNode:setVisible(true)
                
                if targetNode.p_symbolImage  then
                    targetNode.p_symbolImage:removeFromParent()
                    targetNode.p_symbolImage = nil
                end
                targetNode.m_ccbName = ""
                targetNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_MEN), self.SYMBOL_MEN)
                targetNode:runAnim("idle2")
            end
           
        end
        actNdoe:removeFromParent()
        self.m_isPlayFirstReelEffect = false
        self:changeEffectToPlayed(self.DEALY_EFFECT )
    end,delayTime)


end

function CodeGameScreenFairyDragonMachine:playFirstColReelMove()

    local FirstFreeSpinMoveArry = self:getFirstColReelMoveArray()
    if #FirstFreeSpinMoveArry > 0 then

        self.m_isPlayFirstReelEffect = true

        local temp = FirstFreeSpinMoveArry[1]
        local iRow = temp.row
        local iCol = temp.col
        local direction = temp.direction  
        self:showFirstMoveTip(iRow , iCol,direction,function(  )
            local delayTime = self:playFirstReelMove(FirstFreeSpinMoveArry)  
        end)

    end
    
end

function CodeGameScreenFairyDragonMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end
--[[
    @desc: 断线重连时处理 是否有feature 
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenFairyDragonMachine:checkHasReSpinFeature()
    local hasFeature = false

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then
        for i = 1, #self.m_initSpinData.p_features do
            local featureID = self.m_initSpinData.p_features[i]
            if featureID == SLOTO_FEATURE.FEATURE_RESPIN then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)

    if self:getCurrSpinMode() == RESPIN_MODE then
        hasFeature = true
    end

    return hasFeature
end

---
-- 进入关卡
--
function CodeGameScreenFairyDragonMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        if self:checkHasReSpinFeature() then
            self:initHasFeature()
        else
            self:initHasFeature()
        end
    end

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFairyDragonMachine:levelFreeSpinEffectChange()

    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or -1
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    if freeSpinsLeftCount ~= freeSpinsTotalCount then
        self.m_gameBg:runCsbAction("freespinidle")
    end
    

    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFairyDragonMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关

function CodeGameScreenFairyDragonMachine:setSlotNodeEffectParent(slotNode)

    return slotNode
end

function CodeGameScreenFairyDragonMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)

    -- 延迟回调播放 界面提示 bonus  freespin
    -- scheduler.performWithDelayGlobal(function()
        self:resetMaskLayerNodes()
        callFun()
    -- end,util_max(2,animTime),self:getModuleName())
end

function CodeGameScreenFairyDragonMachine:checkNormalWinLinesNum( )
    
    local winLines = self.m_runSpinResultData.p_winLines or {}

    for i=1,#winLines do
        local line = winLines[i]
        if line.p_id and line.p_id > 0  then
            return true
        end
    end

    return false
end

function CodeGameScreenFairyDragonMachine:showEffect_FreeSpin(  effectData )

    

    local time = 0
    if self:checkNormalWinLinesNum( ) then
        time = globalData.slotRunData.levelConfigData:getShowLinesTime() or 0
    end
    performWithDelay(self,function(  )
        BaseFastMachine.showEffect_FreeSpin( self, effectData )
    end,time)
    
    return true
end

-- FreeSpinstart
function CodeGameScreenFairyDragonMachine:showFreeSpinView(effectData)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    self.m_bottomUI:resetWinLabel()
    if fsWinCoins > 0 then
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoins))
    else
        self.m_bottomUI:updateWinCount("")
    end
    


    local showFSView = function(...)


        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

            local symbolList = {}
            for iCol = 1, self.m_iReelColumnNum do --列
                for iRow = self.m_iReelRowNum, 1, -1 do --行
                    local targetNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targetNode and targetNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        local symbol = util_spineCreate("Socre_FairyDragon_Scatter",true,true) 
                        local worldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPosition()))
                        local startPos = self:convertToNodeSpace(worldPos)
                        symbol:setPosition(startPos)
                        util_spinePlay(symbol,"actionframe")
                        symbol:setScale(self.m_machineRootScale)
                        self:addChild(symbol, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                        table.insert(symbolList,symbol)
                      
                    end
                end
            end

            performWithDelay(self,function(  )

                for i=1,#symbolList do
                    local symbol = symbolList[i]
                    if symbol then
                        symbol:removeFromParent()
                    end
                end
                gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_FreeSpinMore.mp3")

                self:showFreeSpinMore(
                    self.m_runSpinResultData.p_freeSpinNewCount,
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    false
                )
            end,2)
            
            
        else
            
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()
            self:runCsbAction("guochang")
                       
        end
    end
    local daleytimes = 0
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        daleytimes = 0
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        daleytimes
    )
end

function CodeGameScreenFairyDragonMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin( globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:clearCurMusicBg()


    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_FreeSpinEnd.mp3")

    performWithDelay(self,function(  )

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearFrames_Fun()
        -- 重置连线信息
        -- self:resetMaskLayerNodes()
        self:showFreeSpinOverView()

    end,3)


    
end

function CodeGameScreenFairyDragonMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_FreeSpinOverView.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()

            gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_FreeSpinOverGuoChang.mp3")

            self.m_gameBg:runCsbAction(
                "freespinover2",
                false,
                function()
                    self:triggerFreeSpinOverCallFun()
                end
            )
            
            self:runCsbAction("normal", false)
            -- self:runCsbAction(
            --     "freespinover2",
            --     false,
            --     function()
            -- self:runCsbAction("freespinover1", false)
            --     end
            -- )
        end
    )
    view.m_allowClick = false
    self:localDealyFunc(0.5,function(  )
        view.m_allowClick = true
    end )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFairyDragonMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )

    if self.m_MiniGameReel then
        if self.m_MiniGameReel.m_TipViewWaitNode then
            
            self.m_MiniGameReel.m_TipViewWaitNode:stopAllActions()
            self.m_MiniGameReel.m_TipViewWaitNode:removeFromParent()
            self.m_MiniGameReel.m_TipViewWaitNode = nil

            self.m_MiniGameReel.m_TipView:runCsbAction(
                "animation2",
                false,
                function()
                    if self.m_MiniGameReel.m_TipView then
                        self.m_MiniGameReel.m_TipView:removeFromParent()
                        self.m_MiniGameReel.m_TipView = nil
                    end
                end
                )
        end
    end

    if self.m_TriggerRsWaitNode then
        self.m_TriggerRsWaitNode:stopAllActions()
        self.m_TriggerRsWaitNode:removeFromParent()
        self.m_TriggerRsWaitNode = nil
    end
    
    self.m_isRSAutoSpin = true

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenFairyDragonMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFairyDragonMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

--------------------添加动画

function CodeGameScreenFairyDragonMachine:addSelfEffect()


    local FirstFreeSpinMoveArry =  self:getFirstColReelMoveArray()
    if #FirstFreeSpinMoveArry > 0 and self.m_isPlayFirstReelEffect then
        -- 加的等待事件
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.DEALY_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DEALY_EFFECT -- 动画类型
    end

    --free下只有在第一列有门时 其余列有门也上拉下拉
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_aFreeSpinMoveArry = {}
        local isMove = false
        for iCol = 1, self.m_iReelColumnNum do --列
            local tempRow = nil
            for iRow = self.m_iReelRowNum, 1, -1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_MEN then
                    tempRow = iRow
                else
                    break
                end
            end

            if tempRow ~= nil and tempRow ~= 1 and iCol ~= 1 then
                self.m_aFreeSpinMoveArry[#self.m_aFreeSpinMoveArry + 1] = {col = iCol, row = tempRow, direction = "down"}
            end
            if iCol == 1 and tempRow ~= nil then
                isMove = true
            end
            tempRow = nil
            for iRow = 1, self.m_iReelRowNum, 1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_MEN then
                    tempRow = iRow
                else
                    break
                end
            end

            if tempRow ~= nil and tempRow ~= self.m_iReelRowNum and iCol ~= 1 then
                self.m_aFreeSpinMoveArry[#self.m_aFreeSpinMoveArry + 1] = {col = iCol, row = tempRow, direction = "up"}
            end
            if iCol == 1 and tempRow ~= nil then
                isMove = true
            end
        end
        if isMove and #self.m_aFreeSpinMoveArry > 0 then
            local moveEffect = GameEffectData.new()
            moveEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            moveEffect.p_effectOrder = self.MOVE_MEN_EFFECT
            moveEffect.p_selfEffectType = self.MOVE_MEN_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = moveEffect
        end
    end

    --所有的门变成随机图标
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.mystery then
        if selfdata.mystery.positions and #selfdata.mystery.positions > 0 then
            local changeEffect = GameEffectData.new()
            changeEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            changeEffect.p_effectOrder = self.CHANGE_MEN_EFFECT
            changeEffect.p_selfEffectType = self.CHANGE_MEN_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = changeEffect
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFairyDragonMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.MOVE_MEN_EFFECT then

        self:freeSpinChange(effectData)

    elseif effectData.p_selfEffectType == self.CHANGE_MEN_EFFECT then

        self:playMenChangeEffect(effectData)
    
    elseif effectData.p_selfEffectType == self.DEALT_EFFECT then


        effectData.p_isPlay = true
        self:playGameEffect()
            
    end
    return true
end

function CodeGameScreenFairyDragonMachine:createMoveSymbolActNode(pos, _parent,symbolType)
    local currName = self:getSymbolCCBNameByType(self, symbolType)

    local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)

    local targSp = nil 

    if spineSymbolData ~= nil then
        targSp = util_spineCreate(currName, true, true)  
        targSp.m_isSpine = true
        
    else
        targSp = util_createAnimation(currName..".csb")
        
    end

    _parent:addChild(targSp, REEL_SYMBOL_ORDER.REEL_ORDER_4)
    targSp:setPosition(cc.p(pos))
    targSp.p_IsMask = true

    if targSp.m_isSpine  then
        util_spinePlay(targSp, "idleframe")
    else
        targSp:runCsbAction("idleframe")
    end

    return targSp
end

function CodeGameScreenFairyDragonMachine:createSymbolActNode(pos, _parent)
    local currName = "Socre_FairyDragon_men.csb"
    local targSp = util_createAnimation(currName)
    _parent:addChild(targSp, REEL_SYMBOL_ORDER.REEL_ORDER_4)
    targSp:setPosition(cc.p(pos))
    targSp.p_IsMask = true
    return targSp
end

function CodeGameScreenFairyDragonMachine:playMenChangeEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.mystery and #selfdata.mystery.positions > 0 then
        local posData = selfdata.mystery.positions
        local targetType = selfdata.mystery.signal

        gLobalSoundManager:playSound("FairyDragonSounds/FairyDragonSounds_Men_Open.mp3")

        for i = 1, #posData, 1 do
            local pos = posData[i]
            local fixPos = self:getRowAndColByPos(pos)
            local targetNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if targetNode then
                local actNode = self:createSymbolActNode(cc.p(targetNode:getPosition()), targetNode:getParent())
                if actNode then
                    actNode:runCsbAction(
                        "actionframe",
                        false,
                        function()
                            actNode:removeFromParent()
                        end
                    )
                end

                if targetNode.p_symbolImage  then
                    targetNode.p_symbolImage:removeFromParent()
                    targetNode.p_symbolImage = nil
                end

                targetNode.m_ccbName = ""

                targetNode:changeCCBByName(self:getSymbolCCBNameByType(self, targetType), targetType)
                
                local zorder = self:getBounsScatterDataZorder(targetNode.p_symbolType)
                targetNode.p_showOrder = zorder - fixPos.iX
                targetNode:setLocalZOrder(zorder - fixPos.iX )
            end
        end
    end

    performWithDelay(self,function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end,1)

end

function CodeGameScreenFairyDragonMachine:createMoveSymbol(_iCol, _iRow)
    local symbol = self:getSlotNodeBySymbolType(self.SYMBOL_MEN)
    self:getReelParent(_iCol):addChild(symbol, 200)
    local startpos = self:getNodePosByColAndRow(_iRow, _iCol)
    symbol:setPosition(startpos)
    return symbol
end

function CodeGameScreenFairyDragonMachine:freeSpinChange(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local targetType = 0
    if selfdata then
        targetType = selfdata.mystery.signal
    end

    local delayTime = self:playOtherFirstReelMove(self.m_aFreeSpinMoveArry)

    local actNdoe = cc.Node:create()
    self:addChild(actNdoe)

    performWithDelay(actNdoe,function()
      
        gLobalSoundManager:playSound("FairyDragonSounds/FairyDragonSounds_Men_Open.mp3")

        for iCol = 1, self.m_iReelColumnNum do --列
            for iRow = self.m_iReelRowNum, 1, -1 do --行
                local targetNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

                if targetNode and targetNode.p_symbolType == self.SYMBOL_MEN then
                    local actNode = self:createSymbolActNode(cc.p(targetNode:getPosition()), targetNode:getParent())
                    if actNode then
                        actNode:runCsbAction(
                            "actionframe",
                            false,
                            function()
                                actNode:removeFromParent()
                            end
                        )
                    end

                    if targetNode.p_symbolImage  then
                        targetNode.p_symbolImage:removeFromParent()
                        targetNode.p_symbolImage = nil
                    end
                    targetNode.m_ccbName = ""

                    targetNode:changeCCBByName(self:getSymbolCCBNameByType(self, targetType), targetType)
                    local zorder = self:getBounsScatterDataZorder(targetNode.p_symbolType)
                    targetNode.p_showOrder = zorder - iRow 
                    targetNode:setLocalZOrder(zorder - iRow )
                end
            end
        end

        local actNdoe_1 = cc.Node:create()
        self:addChild(actNdoe_1)

        performWithDelay(actNdoe_1,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,0.5)
        
        actNdoe:removeFromParent()
    end,delayTime + 0.8)


end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenFairyDragonMachine:getNodePosByColAndRow(row, col)
    local posX, posY = 0, 0
    posX = posX + self.m_SlotNodeW
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end
---

---
-- 触发respin 玩法
--
function CodeGameScreenFairyDragonMachine:showEffect_Respin(effectData)


    local time = 0
    if self:checkNormalWinLinesNum( ) then
        time = globalData.slotRunData.levelConfigData:getShowLinesTime() or 0
    end
    performWithDelay(self,function(  )

        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "respin")
        end
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        -- gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_JPGame_Trigger.mp3")

        performWithDelay(
            self,
            function()
                self:playTransitionEffect(effectData)
            end,
            0
        )

        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)

    end,time)


    
    return true
end

--过场
function CodeGameScreenFairyDragonMachine:playTransitionEffect(effectData)

    gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_JackpotGameGuoChang.mp3")

    local transitionView = util_createView("FairyDragonSrc.FairyDragonTransitionView")
    self:findChild("veiwNode"):addChild(transitionView)
    -- transitionView:setScale(2)
    transitionView:runCsbAction(
        "actionframe1",
        false,
        function()
            transitionView:runCsbAction(
                "actionframe2",
                false,
                function()
                    transitionView:removeFromParent()
                end
            )
            self:showRespinView(effectData)
        end
    )
    performWithDelay(
        self,
        function()
            self:findChild("Node_30"):setVisible(false)
        end,
        25 / 30
    )
end

function CodeGameScreenFairyDragonMachine:showRespinView(effectData)
    self.m_effectData = effectData
    self:clearCurMusicBg()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = false

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:showMiniReel(false)
end
--[[
    @desc: 显示bonus 轮盘
    --@_isReConnet: false or true 是否断线重连
]]
function CodeGameScreenFairyDragonMachine:showMiniReel(_isReConnet)
    local winCoins = self.m_runSpinResultData.p_selfMakeData
    local data = {}
    data.parent = self
    self.m_bBonusGame = true
    self.m_MiniGameReel = util_createView("FairyDragonSrc.FairyDragonMiniMachine", data)
    self:findChild("MiniNode"):addChild(self.m_MiniGameReel)
    self.m_MiniGameReel:setPositionY(638)

    local win_txt = self.m_bottomUI:findChild("win_txt")
    if win_txt then
        local addPosY = 20
        if display.height <= 1069 then
            addPosY = 25
        end

        local win_txtPos = cc.p(win_txt:getPosition())
        local worldPos = win_txt:getParent():convertToWorldSpace(cc.p(win_txtPos.x,win_txtPos.y + addPosY ))
        local currPos = self:findChild("MiniNode"):getParent():convertToNodeSpace(worldPos)
        self:findChild("MiniNode"):setPositionY(currPos.y) 
    end
    

        
    self:resetMusicBg()
    
    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount or 0
    local leftFsCount = 5 - globalData.slotRunData.iReSpinCount 
    local totalFsCount = 5
    self.m_MiniGameReel.m_RespinBarView:updateRespinCount(leftFsCount,totalFsCount)

    self.m_MiniGameReel:playShowAction()
    self.m_gameBg:runCsbAction("guochang")
    local extraData = self.m_runSpinResultData.p_rsExtraData
    if extraData and extraData.jackpots then
        self.m_MiniGameReel:initMiniBgData(extraData.jackpots, self)
    end
    --显示摇到第几层线了
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.counts then
        self.m_MiniGameReel:setWinLines(selfdata.counts)
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE or self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
        -- if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        --     gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        -- end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        -- globalData.slotRunData.m_isAutoSpinAction = false
    end

    if _isReConnet == false then

        self.m_isRSAutoSpin = false

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            waitNode:removeFromParent()
            waitNode = nil

            self.m_effectData.p_isPlay = true
            self:playGameEffect()
                
            if self.m_handerIdAutoSpin ~= nil then
                scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
                self.m_handerIdAutoSpin = nil
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end,3)

        self.m_TriggerRsWaitNode = cc.Node:create()
        self:addChild(self.m_TriggerRsWaitNode)

        performWithDelay(self.m_TriggerRsWaitNode,function()
            self.m_TriggerRsWaitNode:removeFromParent()
            self.m_TriggerRsWaitNode = nil

            self:normalSpinBtnCall()
                
        end,5)

    else
        self.m_baseFreeSpinBar:setVisible(false)
        self:runCsbAction("respin")
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_runSpinResultData.p_bonusWinCoins))
    end
    self.m_bottomUI:checkClearWinLabel()
end

----
--- 处理spin 成功消息
--
function CodeGameScreenFairyDragonMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    local result = spinData.result
    local selfData = result.selfData
    if selfData.selectType then
        self:featureResultCallFun(param)
        -- self.bonusChooseType = selfData.selectType
    elseif spinData.action == "SPIN" or spinData.action == "FEATURE" then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        gLobalNoticManager:postNotification("TopNode_updateRate")

        if self.m_MiniGameReel ~= nil then
            --设置主轮盘数据  防止阻塞
            self.m_isWaitingNetworkData = false
            self:setGameSpinStage(GAME_MODE_ONE_RUN)
            --设置副轮盘 数据
            local resultData = spinData.result
            local reeldata = {21,21,22,29,30}
            if resultData.selfData then
                if resultData.selfData.jackpotReels then
                    reeldata = resultData.selfData.jackpotReels
                end
            end
            resultData.reels = reeldata
            self.m_MiniGameReel:netWorkCallFun(resultData)
        else
            self:updateNetWorkData()
        end
    end
end

function CodeGameScreenFairyDragonMachine:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result

            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

            self.m_featureData:parseFeatureData(spinData.result)        --解析feature 数据
            if self.chooseView then
                self.chooseView:recvBaseData(self.m_featureData)
            end
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            if self.chooseView then
                self.chooseView:recvBaseData(self.m_featureData)
            end
            -- 
        else
            dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function CodeGameScreenFairyDragonMachine:beginReel()

    for cloumIndex = 1,self.m_iReelColumnNum do
        self.m_reelRunInfo[cloumIndex]:setReelRunLen(self.m_configData.p_reelRunDatas[cloumIndex])
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self.m_respinReelRun = true
    end

    if self.m_MiniGameReel ~= nil then
        
        gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
        self.m_MiniGameReel:beginMiniReel()
        self.m_respinReelRun = true
        return
    end
    BaseFastMachine.beginReel(self)
    self.m_jackpotSymbolNum = 0
    self.m_scatterSymbolNum = 0
end

function CodeGameScreenFairyDragonMachine:setNormalAllRunDown()
    self:setGameSpinStage(STOP_RUN)
    if self.m_respinReelRun then
        self.m_respinReelRun = false
    end
    BaseFastMachine.playEffectNotifyChangeSpinStatus(self)
end

function CodeGameScreenFairyDragonMachine:MachineRule_respinTouchSpinBntCallBack()
    if self.m_respinReelRun ~= true then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end

function CodeGameScreenFairyDragonMachine:showBonusGameOver(winCoins, func)

    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_JackPotView.mp3")

    self:clearCurMusicBg()

    local strCoins = util_formatCoins(winCoins, 50)
    local view =
        self:showReSpinOver(
        strCoins,
        function()

            performWithDelay(self,function(  )
                self:removeMiniReel(winCoins )

                if func then
                    func()
                end

                -- 更新游戏内每日任务进度条
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                -- 通知bonus 结束， 以及赢钱多少
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{winCoins, GameEffect.EFFECT_RESPIN})

                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoins,true,true})
                globalData.slotRunData.lastWinCoin = lastWinCoin 
                
                self:add_QUEST_DONE_Effect( )

                local  isTrigger = false
                if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                    local effectData = GameEffectData.new()
                    effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                    self.m_bottomUI:checkClearWinLabel()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
                    isTrigger = true
                end

                if isTrigger then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
                end

                self:playGameEffect()
            end,0)
            

            
            
        end
    )
    view.m_allowClick = false
    self:localDealyFunc(0.5,function(  )
        view.m_allowClick = true
    end )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
end
function CodeGameScreenFairyDragonMachine:removeMiniReel(_coins)
    if self.m_MiniGameReel ~= nil then
        self.m_MiniGameReel:removeFromParent()
        self.m_MiniGameReel = nil
        self:triggerReSpinOverCallFun(_coins)
        self.m_bottomUI:checkClearWinLabel()
        self.m_gameBg:runCsbAction("respin_normal")
        self:runCsbAction("normal", false)
        self:findChild("Node_30"):setVisible(true)
    end
    self.m_respinReelRun = false
    self:updateBaseConfig()
    self:initSymbolCCbNames()
    self:initMachineData()
end

function CodeGameScreenFairyDragonMachine:triggerReSpinOverCallFun(score)


    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self.m_specialReels = false
    self.m_iReSpinScore = 0
    self.m_preReSpinStoredIcons = nil

    -- if self.m_bProduceSlots_InFreeSpin then
    --     local addCoin = self.m_serverWinCoins
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    -- else
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    -- end

    local coins = score or 0
    if self.postReSpinOverTriggerBigWIn then
        self:postReSpinOverTriggerBigWIn( coins)
    end

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    -- self:playGameEffect()

    self:resetMusicBg(true)

    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

function CodeGameScreenFairyDragonMachine:showRespinGrandJackpot(coins, func)


        performWithDelay(self,function(  )
            if func then
                func()
            end
    
            self:removeMiniReel(coins)
    
            
            -- 更新游戏内每日任务进度条
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
            -- 通知bonus 结束， 以及赢钱多少
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{coins, GameEffect.EFFECT_RESPIN})
    
            
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin 
    
    
            self:add_QUEST_DONE_Effect( )
    
            local isTrigger = false
            if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                local effectData = GameEffectData.new()
                effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                self.m_bottomUI:checkClearWinLabel()
                isTrigger = true
            end
    
    
            if isTrigger then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            end
            
            self:playGameEffect()
    
        end,0)
        
   
    
end

function CodeGameScreenFairyDragonMachine:showRespinJackpot(index, coins, func)

    

    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_JackPotView.mp3")

    local jackPotWinView = util_createView("FairyDragonSrc.FairyDragonJackpotWin")

    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(
        index,
        coins,
        function()

            performWithDelay(self,function(  )
                if func then
                    func()
                end
    
                self:removeMiniReel(coins)
    
                
                -- 更新游戏内每日任务进度条
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                -- 通知bonus 结束， 以及赢钱多少
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{coins, GameEffect.EFFECT_RESPIN})
    
                
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,true})
                globalData.slotRunData.lastWinCoin = lastWinCoin 
    
                self:add_QUEST_DONE_Effect( )
                
                local isTrigger = false
                if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                    local effectData = GameEffectData.new()
                    effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                    self.m_bottomUI:checkClearWinLabel()
                    isTrigger = true
                end
    
    
                if isTrigger then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
                end
                
                self:playGameEffect()
            end,0)
           

        end
    )

    
end

function CodeGameScreenFairyDragonMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    if self.m_iOnceSpinLastWin > 0 then
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 1.5
        elseif winRate > 3 and winRate <= 6 then
            showTime = 2.5
        elseif winRate > 6 then
            showTime = 3
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
         or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            showTime = 1
        end
    end

    return showTime
end


function CodeGameScreenFairyDragonMachine:playEffectNotifyNextSpinCall()

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
        
        -- if self.m_reelResultLines ~= nil and #self.m_reelResultLines > 0 then
        --     delayTime = math.max(self.m_autoSpinDelayTime, self.m_changeLineFrameTime)
        -- end

        delayTime = delayTime + self:getWinCoinTime()

         -- 触发freespin那一次 等待0.5秒
         local feature = self.m_runSpinResultData.p_features or {}
         if #feature == 2 and feature[2] == 1  then
             delayTime = 0.5
         end

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                if self.m_isRSAutoSpin then
                    self:normalSpinBtnCall()
                end
                
            end,
            1,
            self:getModuleName()
        )
    end
end


function CodeGameScreenFairyDragonMachine:changeEffectToPlayed(selfEffectType )
    for i=1,#self.m_gameEffects do
        local  effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType == selfEffectType then
            if effectData.p_isPlay == false then
                effectData.p_isPlay = true
                self:playGameEffect()
                break
            end
            
            
        end
    end
end

function CodeGameScreenFairyDragonMachine:dealSmallReelsSpinStates( )

    local FirstFreeSpinMoveArry =  self:getFirstColReelMoveArray()
    if #FirstFreeSpinMoveArry > 0 then
        -- 触发了第一列 动画
        print("不允许快停")
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true}) 
    end
    

end

function CodeGameScreenFairyDragonMachine:setLastReelSymbolList()

    local FirstFreeSpinMoveArry =  self:getFirstColReelMoveArray()
    local addRunNum = 0
    if #FirstFreeSpinMoveArry > 0 then
        addRunNum = 90
         -- 修改假滚滚动长度
        for cloumIndex = 2,self.m_iReelColumnNum do
            self.m_reelRunInfo[cloumIndex]:setReelRunLen(self.m_configData.p_reelRunDatas[cloumIndex] + addRunNum )
        end
    end

   
    

    BaseFastMachine.setLastReelSymbolList(self)

end

---
-- 点击快速停止reel
--
function CodeGameScreenFairyDragonMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")

    if self.m_MiniGameReel == nil then
        BaseFastMachine.quicklyStopReel(self,colIndex)
    end 
    

end

function CodeGameScreenFairyDragonMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do

            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                targSp:runAnim("idleframe")

            end
        end

    end
    


    BaseFastMachine.slotReelDown(self)
  
end

function CodeGameScreenFairyDragonMachine:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex,reelDatas  )
    
   

    local changedSymbolType = 0

    if colIndex and reelDatas  then

        if self.m_m_initNodeIndex == nil then
            self.m_m_initNodeIndex = math.random(1,#reelDatas) 
        end

        self.m_m_initNodeIndex = self.m_m_initNodeIndex + 1
        if self.m_m_initNodeIndex > #reelDatas then
            self.m_m_initNodeIndex = 1
        end

        changedSymbolType = reelDatas[self.m_m_initNodeIndex]

    else
        changedSymbolType = symbolType
    end
    
    if changedSymbolType == self.SYMBOL_MEN then
        changedSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    end

    return changedSymbolType
end

function CodeGameScreenFairyDragonMachine:localDealyFunc(time,func )
    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        if func then
            func()
        end
        node:removeFromParent()
    end,time)
end


---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenFairyDragonMachine:MachineRule_ResetReelRunData()

    local addReel5LongRun = false
    for iRow = 1 ,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][1]
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            addReel5LongRun = true
            break
        end
    end

    if addReel5LongRun then
        local reelRunData = self.m_reelRunInfo[5]
        local columnData = self.m_reelColDatas[5]

        local iRow = columnData.p_showGridCount

        local lastColLens = self.m_reelRunInfo[4]:getReelRunLen()
        local colHeight = columnData.p_slotColumnHeight
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

        local preRunLen = reelRunData:getReelRunLen()
        reelRunData:setReelRunLen(runLen)

       
        self.m_reelRunInfo[4]:setNextReelLongRun(true)
        self.m_reelRunInfo[5]:setNextReelLongRun(true)
        self.m_reelRunInfo[5]:setReelLongRun(true)
        
        
        
    end
    
    
    
end

---
--设置bonus scatter 层级
function CodeGameScreenFairyDragonMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or 
        -- symbolType == self.SYMBOL_JACJKPOT or 
            symbolType == self.SYMBOL_MEN  then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

function CodeGameScreenFairyDragonMachine:showLineFrame( )
    
        local lineLen = #self.m_reelResultLines
        local scatterLineValue = nil
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                scatterLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end

        BaseFastMachine.showLineFrame( self )
    
end


--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenFairyDragonMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end

        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end


    local FirstFreeSpinMoveArry = self:getFirstColReelMoveArray()
    if #FirstFreeSpinMoveArry > 0 then
        symbolType = math.random( TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, self.SYMBOL_SCORE_12 )
    end

    return symbolType

end

function CodeGameScreenFairyDragonMachine:checkSelfRemoveGameEffectType(effectType)
    
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return 
    end

    for i = effectLen,1,-1 do

        local value = self.m_gameEffects[i].p_effectType
        if value == effectType  then
           table.remove(self.m_gameEffects,i)
        end
    end

end

function CodeGameScreenFairyDragonMachine:add_QUEST_DONE_Effect( )
    if self.m_gameEffects == nil then
        return 
    end

    self:checkSelfRemoveGameEffectType(GameEffect.EFFECT_QUEST_DONE)


    local questEffect = GameEffectData:create()
    questEffect.p_effectType =  GameEffect.EFFECT_QUEST_DONE  --创建属性
    questEffect.p_effectOrder = 999999  --动画播放层级 用于动画播放顺序排序
    self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
end

function CodeGameScreenFairyDragonMachine:checkAddQuestDoneEffectType( )

    if self.m_MiniGameReel == nil then

        if self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE) == false then
            local questEffect = GameEffectData:create()
            questEffect.p_effectType =  GameEffect.EFFECT_QUEST_DONE  --创建属性
            questEffect.p_effectOrder = 999999  --动画播放层级 用于动画播放顺序排序
            self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
        end

    end
    

end

function CodeGameScreenFairyDragonMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet() 
    if  betCoin == nil or betCoin >= self.m_BetChooseGear then
        return 1
    else
        return 0        
    end
end

function CodeGameScreenFairyDragonMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or 
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and 
    self:getGameSpinStage() ~= IDLE ) or 
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or 
    self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self.m_MiniGameReel  
    then
        return
    end


    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

-------------------------------------------------选择---------------------------------------------------

function CodeGameScreenFairyDragonMachine:showEffect_Bonus( effectData)
    self.m_isBonusTrigger = true
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    -- self.isInBonus = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    -- if self.m_winSoundsId then
    --     gLobalSoundManager:stopAudio(self.m_winSoundsId)
    --     self.m_winSoundsId = nil
    -- end
    --     local time = 1
    --     local changeNum = 1/(time * 60) 
    --     local curvolume = 1
    --     self.m_updateBgMusicHandlerID = scheduler.scheduleUpdateGlobal(function()
    --         curvolume = curvolume - changeNum
    --         if curvolume <= 0 then

    --             curvolume = 0

    --             if self.m_updateBgMusicHandlerID ~= nil then
    --                 scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
    --                 self.m_updateBgMusicHandlerID = nil
    --             end
    --         end

    --         gLobalSoundManager:setBackgroundMusicVolume(curvolume)
    --     end)

        -- performWithDelay(self,function(  )

            -- 停止播放背景音乐
            self:clearCurMusicBg()
            self:showBonusGameView(effectData)
        -- end,time)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

--三个sc触发
function CodeGameScreenFairyDragonMachine:showBonusGameView(effectData)
    self:playShowChooseGameStartEffect(function (  )
        self:chooseGameView(effectData)
    end)
end

--scatter飞
function CodeGameScreenFairyDragonMachine:playShowChooseGameStartEffect(_fun)

    self:playScatterTipMusicEffect()    --sactter触发音效

    local maskView = util_createView("FairyDragonSrc.FairyDragonFreespinMaskView")
    self:findChild("maskNode"):addChild(maskView)
    local moveSymbol = {}
    local height = display.height + 50
    for iCol = 1, self.m_iReelColumnNum do --列
        for iRow = self.m_iReelRowNum, 1, -1 do --行
            local targetNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targetNode and targetNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local symbol = util_spineCreate("Socre_FairyDragon_Scatter",true,true)  
                local worldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPosition()))
                local startPos = self:convertToNodeSpace(worldPos)
                symbol:setPosition(startPos)
                symbol:setScale(self.m_machineRootScale)
                self:addChild(symbol, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)

                util_spinePlay(symbol,"actionframe")

                local dealy = cc.DelayTime:create(2)
                local endPos = cc.p(startPos.x, height)
                local bez
                --scatter改为1，5列
                if iCol == 1 then
                    endPos = cc.p(startPos.x + 600, height)
                    bez = cc.BezierTo:create(1.2, {cc.p(startPos.x, startPos.y), cc.p(startPos.x - 200, startPos.y), endPos})
                elseif iCol == 5 then
                    endPos = cc.p(startPos.x - 1200, height - 200)
                    bez = cc.BezierTo:create(1.5, {cc.p(startPos.x, startPos.y), cc.p(startPos.x + 100, startPos.y), endPos})
                end
                local fun =
                    cc.CallFunc:create(
                    function()
                        symbol:removeFromParent()
                    end
                )
                symbol:runAction(cc.Sequence:create(dealy, bez, fun))
            end
        end
    end

    performWithDelay(
        self,
        function()

            gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_ScatterFly.mp3")

            self:runCsbAction("freespinstart1")
            self.m_gameBg:runCsbAction(
                "freespin",
                false,
                function()
                    if _fun then
                        _fun()
                    end

                end
            )
        end,
        1.5
    )
    performWithDelay(
        self,
        function()
            maskView:removeFromParent()
        end,
        2
    )
end

--玩法选择弹板
function CodeGameScreenFairyDragonMachine:chooseGameView(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local selectType = selfdata.selectType
    self.chooseView = util_createView("FairyDragonSrc.FairyDragonChooseView",self)
    self:findChild("veiwNode"):addChild(self.chooseView)
    local par = self.chooseView:findChild("Particle_1")
    par:setVisible(false)
    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_ShowFreeSpinStartView.mp3")
    self.chooseView:showStartAct()
    performWithDelay(           --播放粒子
        self,
        function()
            par:setVisible(true)
            par:resetSystem()
        end,
        23 / 60
    )
    self.chooseView:setEndCall(function (  )
        self.chooseView:stopAllActions()
        self.chooseView:runCsbAction("over",false)
        performWithDelay(self,function (  )
            print("已经知道玩家选择，并且本地已更新好数据")
            -- 手动添加对应的effect
            self:checkLocalGameNetDataFeatures()
            effectData.p_isPlay = true
            self:playGameEffect()
            if self.chooseView then
                self.chooseView:removeFromParent()
            end
        end,0.25)
        
    end)
    return self.chooseView
end


--
-- 自己添加freespin 事件
--
function CodeGameScreenFairyDragonMachine:checkLocalGameNetDataFeatures()

    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect


            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                end
                if checkEnd == true then
                    break
                end

            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            local params = {self.m_runSpinResultData.p_fsWinCoins,false,false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)

            -- self:sortGameEffects( )
            -- self:playGameEffect()

        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then  -- respin 玩法一并通过respinCount 来进行判断处理
            globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 and 
                        #self.m_runSpinResultData.p_storedIcons == 15 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            


            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

         
            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then

                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                    
                end
                
                if checkEnd == true then
                    break
                end

            end

            -- self:sortGameEffects( )
            -- self:playGameEffect()


        end
    end

end

function CodeGameScreenFairyDragonMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenFairyDragonMachine.super.levelDeviceVibrate then
        CodeGameScreenFairyDragonMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenFairyDragonMachine
