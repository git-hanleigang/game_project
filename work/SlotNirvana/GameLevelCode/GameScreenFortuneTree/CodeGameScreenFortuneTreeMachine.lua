---
-- island li
-- 2019年1月26日
-- CodeGameScreenFortuneTreeMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SendDataManager = require "network.SendDataManager"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenFortuneTreeMachine = class("CodeGameScreenFortuneTreeMachine", BaseSlotoManiaMachine)

CodeGameScreenFortuneTreeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenFortuneTreeMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_Q = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_J = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
-- CodeGameScreenFortuneTreeMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenFortuneTreeMachine.SYMBOL_TYPY_FLYUP_COIN = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_7 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14
CodeGameScreenFortuneTreeMachine.SYMBOL_TYPE_WILD_8 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15

CodeGameScreenFortuneTreeMachine.m_bIsSelectCall = nil
CodeGameScreenFortuneTreeMachine.m_iSelectID = nil
CodeGameScreenFortuneTreeMachine.m_iReelMinRow = 3
CodeGameScreenFortuneTreeMachine.m_vecReelRow = {3, 4, 5,}
CodeGameScreenFortuneTreeMachine.m_jackpotPos = 0
CodeGameScreenFortuneTreeMachine.m_vecTreeAnimationNames = 
{
    "Duofuduocai_facaishu_less_",
    "Duofuduocai_facaishu_more_",
    "Duofuduocai_facaishu_most_"
}

-- 构造函数
function CodeGameScreenFortuneTreeMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenFortuneTreeMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFortuneTreeMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FortuneTree"  
end


function CodeGameScreenFortuneTreeMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    
    if display.height < DESIGN_SIZE.height then
        mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height- uiH - uiBH)
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        local iY = (DESIGN_SIZE.height - display.height) / 27.25
        self.m_machineNode:setPositionY(iY)
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
    
end

function CodeGameScreenFortuneTreeMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    self:findChild("Lun_pan4x5"):setVisible(false)
    self:findChild("Lun_pan5x5"):setVisible(false)
    self:findChild("freespin3x5"):setVisible(false)
    self:findChild("normal3x5"):setVisible(true)
    
    -- 创建view节点方式
    -- self.m_FortuneTreeView = util_createView("CodeFortuneTreeSrc.FortuneTreeView")
    -- self:findChild("xxxx"):addChild(self.m_FortuneTreeView)
   
    self.m_FortuneTreeTree = util_spineCreate("Duofuduocai_facaishu", true, true)--util_createView("CodeFortuneTreeSrc.FortuneTreeTree")
    self:findChild("Node_facaishu"):addChild(self.m_FortuneTreeTree)
    util_spinePlay(self.m_FortuneTreeTree, "Duofuduocai_facaishu_more_idle", true)

    self.m_FortuneTreeEffect = util_spineCreateDifferentPath("Duofuduocai_facaishu_xingxing", "Duofuduocai_facaishu", true, true)
    self:findChild("Node_facaishu"):addChild(self.m_FortuneTreeEffect)
    self.m_FortuneTreeEffect:setVisible(false)
    
    self.m_guochang = util_spineCreate("Duofuduocai_guochangdonghua", true, true)
    self:addChild(self.m_guochang, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5)
    self.m_guochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guochang:setVisible(false)

    self.m_jackpotBar = util_createView("CodeFortuneTreeSrc.FortuneTreeJackpotBar")
    self:findChild("Node_Jackpot_normal"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)

    -- self.m_jackpotFreespinBar = util_createView("CodeFortuneTreeSrc.FortuneTreeJackpotBar", "freespin")
    -- self:findChild("Node_Jackpot_free"):addChild(self.m_jackpotFreespinBar)
    -- self.m_jackpotFreespinBar:initMachine(self)
    -- self.m_jackpotFreespinBar:setVisible(false)

    self.m_freespinBar = util_createView("CodeFortuneTreeSrc.FortuneTreeFreeSpinBar", "freespin")
    self:findChild("FsBar"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)

    self.m_chooseFSView = util_createView("CodeFortuneTreeSrc.FortuneTreeFSChooseView")
    self:findChild("chooseFS"):addChild(self.m_chooseFSView)
    self.m_chooseFSView:setVisible(false)
    -- 
    self:fitFortuneTree()
    if display.height > DESIGN_SIZE.height then--Lun_pan4x5

        local posY = (display.height - DESIGN_SIZE.height) * 0.5
        local nodeTree = self:findChild("Node_facaishu")
        nodeTree:setPositionY(nodeTree:getPositionY() - posY )
        local nodeFsBar = self:findChild("FsBar")
        nodeFsBar:setPositionY(nodeFsBar:getPositionY() - posY )
        local nodeReel = self:findChild("Lun_pan")
        nodeReel:setPositionY(nodeReel:getPositionY() - posY )
        local nodeChooseFS = self:findChild("chooseFS")
        nodeChooseFS:setPositionY(nodeChooseFS:getPositionY() - posY * 0.5)
        local nodeJackpot = self:findChild("Node_Jackpot_normal")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY * 0.8)
        local nodeFsJackpot = self:findChild("Node_Jackpot_free")
        nodeFsJackpot:setPositionY(nodeFsJackpot:getPositionY() + posY * 0.8 )
        self.m_jackpotPos = posY * 0.8 
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight =  util_getBangScreenHeight()
        local nodeJackpot = self:findChild("Node_Jackpot_normal")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - bangHeight )
        local nodeFsJackpot = self:findChild("Node_Jackpot_free")
        nodeFsJackpot:setPositionY(nodeFsJackpot:getPositionY() - bangHeight  )
        self.m_jackpotPos = self.m_jackpotPos - bangHeight  

    end

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundName = "FortuneTreeSounds/sound_FortuneTree_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenFortuneTreeMachine:fitFortuneTree(isFreespin)
    if isFreespin == true then
        
    else
        if display.height <= 1430 then
            self.m_FortuneTreeEffect:setScale(0.8)
            self.m_FortuneTreeTree:setScale(0.8)
        elseif display.height <= 1480 then
            self.m_FortuneTreeEffect:setScale(0.9)
            self.m_FortuneTreeTree:setScale(0.9)
        end
        
    end
end

function CodeGameScreenFortuneTreeMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "FortuneTreeSounds/sound_FortuneTree_scatter_"..i..".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenFortuneTreeMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenFortuneTreeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenFortuneTreeMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

end

function CodeGameScreenFortuneTreeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFortuneTreeMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_TYPE_Q then
        return "Socre_FortuneTree_10"
    elseif symbolType == self.SYMBOL_TYPE_J then
        return "Socre_FortuneTree_11"
    elseif symbolType == self.SYMBOL_TYPY_FLYUP_COIN then
        return "Socre_FortuneTree_shouji_jinbi"
    elseif symbolType == self.SYMBOL_TYPE_WILD_1 or symbolType == self.SYMBOL_TYPE_WILD_2
     or symbolType == self.SYMBOL_TYPE_WILD_3 or symbolType == self.SYMBOL_TYPE_WILD_4
     or symbolType == self.SYMBOL_TYPE_WILD_5 or symbolType == self.SYMBOL_TYPE_WILD_6
     or symbolType == self.SYMBOL_TYPE_WILD_7 or symbolType == self.SYMBOL_TYPE_WILD_8
    then
        return "Socre_FortuneTree_diaoluo"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFortuneTreeMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_Q,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_J,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPY_FLYUP_COIN,count =  8}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_7,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_WILD_8,count =  2}
    
    return loadNode
end

function CodeGameScreenFortuneTreeMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex


end


function CodeGameScreenFortuneTreeMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)
    
    if symbolType == self.SYMBOL_TYPE_WILD_1 or symbolType == self.SYMBOL_TYPE_WILD_2
     or symbolType == self.SYMBOL_TYPE_WILD_3 or symbolType == self.SYMBOL_TYPE_WILD_4 
     or symbolType == self.SYMBOL_TYPE_WILD_5 or symbolType == self.SYMBOL_TYPE_WILD_6 
     or symbolType == self.SYMBOL_TYPE_WILD_7 or symbolType == self.SYMBOL_TYPE_WILD_8 
    then
        self:hideMultiple(reelNode, symbolType)
        if self.m_bReconnect ~= true and reelNode.m_isLastSymbol == true then
            reelNode:setVisible(false)
            if self.m_vecReelWild == nil then
                self.m_vecReelWild = {}
            end
            self.m_vecReelWild[#self.m_vecReelWild + 1] = reelNode
        end
    end

    return reelNode
end

function CodeGameScreenFortuneTreeMachine:hideMultiple(symbol, symbolType)
    for j = 1, 8, 1 do
        util_getChildByName(symbol, "multiple_"..j):setVisible(false)
    end
    local index = symbolType - 100
    if index > 1 then
        util_getChildByName(symbol, "multiple_"..index):setVisible(true)
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenFortuneTreeMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_fsExtraData ~= nil and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_bReconnect = true
            self.m_iSelectID = self.m_runSpinResultData.p_fsExtraData.select
            self.m_iReelRowNum = self.m_vecReelRow[self.m_iSelectID]
            if self.m_iReelRowNum > self.m_iReelMinRow then
                self:changeReelData()
            end
        end
    end
    
end

function CodeGameScreenFortuneTreeMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" then
        if featureData.p_data.freespin ~= nil and featureData.p_data.freespin.extra ~= nil and featureData.p_data.freespin.extra.select ~= nil then
            self.m_iSelectID = featureData.p_data.freespin.extra.select
            globalData.slotRunData.freeSpinCount = featureData.p_data.freespin.freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = featureData.p_data.freespin.freeSpinsTotalCount
            self.m_iReelRowNum = self.m_vecReelRow[self.m_iSelectID]
            if self.m_iReelRowNum > self.m_iReelMinRow then
                self:changeReelData()
            end
            self:triggerFreeSpinCallFun()
        end
        self:playGameEffect()
        return
    end

    if featureData.p_status == "OPEN" then
        local bonusView = util_createView("CodeFortuneTreeSrc.FortuneTreeBnousGameLayer", self.m_jackpotPos)
        bonusView:resetView(featureData, function(coins, jackpot)
                        
            self:bonusGameOver(coins, jackpot, function()
                        
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(coins))
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

                self:playGuoChangAnimation(0.33, function()
                    bonusView:removeFromParent()
                end, function()
                    self:playGameEffect()
                    self:resetMusicBg()
                    self:setMinMusicBGVolume()
                end)
            end)
            
        end, self)
        self.isInBonus = true
        
        self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        self.m_currentMusicBgName = "FortuneTreeSounds/music_FortuneTree_bs_bg.mp3"
        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        if globalData.slotRunData.machineData.p_portraitFlag then
            bonusView.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = bonusView})
       
        -- self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
        -- self.m_bottomUI:checkClearWinLabel()
        performWithDelay(self, function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end, 0.1)
    end
end

function CodeGameScreenFortuneTreeMachine:initGameStatusData(gameData)
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end
--
--单列滚动停止回调
--
function CodeGameScreenFortuneTreeMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol) 
    
    for iRow = self.m_iReelRowNum, 1, -1 do
        local node = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, iRow, SYMBOL_NODE_TAG))
        if node then
            if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                if not self.m_collectList then
                    self.m_collectList = {}
                end
                self.m_collectList[#self.m_collectList + 1] = node
            end
        end
    end
    if self.m_collectList ~= nil and #self.m_collectList > 0 then
        --performWithDelay(self, function()
            self:collectWildCoin(reelCol)
        --end, 0.25)
    end
end

-- 每个reel条滚动到底
function CodeGameScreenFortuneTreeMachine:slotReelDown()
    if self.m_vecDropCoins ~= nil and #self.m_vecDropCoins > 0 then
        for i = #self.m_vecDropCoins, 1, -1 do
            local coin = self.m_vecDropCoins[i]
            coin:setVisible(false)
            table.remove(self.m_vecDropCoins, i)
        end
        for i = #self.m_vecReelWild, 1, -1 do
            local wild = self.m_vecReelWild[i]
            wild:setVisible(true)
            table.remove(self.m_vecReelWild, i)
        end
    end
    
    BaseSlotoManiaMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end

function CodeGameScreenFortuneTreeMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD 
      or symbolType == self.SYMBOL_TYPE_WILD_1 or symbolType == self.SYMBOL_TYPE_WILD_2 
      or symbolType == self.SYMBOL_TYPE_WILD_3 or symbolType == self.SYMBOL_TYPE_WILD_4 
      or symbolType == self.SYMBOL_TYPE_WILD_5 or symbolType == self.SYMBOL_TYPE_WILD_6 
      or symbolType == self.SYMBOL_TYPE_WILD_7 or symbolType == self.SYMBOL_TYPE_WILD_8 
    then
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

function CodeGameScreenFortuneTreeMachine:collectWildCoin(reelCol)
    local endPos = self.m_FortuneTreeTree:getParent():convertToWorldSpace(cc.p(self.m_FortuneTreeTree:getPosition()))
    endPos.y = endPos.y + 200
    gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_coin_fly.mp3")
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]

        if node.p_symbolType and  node.p_cloumnIndex == reelCol then
            node:runAnim("shouji")

            local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            local nodeStartPos = self:convertToNodeSpace(startPos)

            local delayTime = 0.08
            for j = 1, 8, 1 do
                local coins = self:getSlotNodeBySymbolType(self.SYMBOL_TYPY_FLYUP_COIN)
                self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                local xPow = math.random(1, 2)
                local yPow = math.random(1, 2)
                local newStartPos = cc.pAdd(nodeStartPos, cc.p(math.random(0, 40) * math.pow(-1, xPow), 30 + math.random(0, 40) * math.pow(-1, yPow)))
                coins:setPosition(newStartPos)
                if i == 1 and j == 8 then
                    coins.isLastOne = true
                end
                
                coins:runAnim("animation", true)
                coins:setScale(0)
                coins:setRotation(math.random(0, 360))
                local delayAction = cc.DelayTime:create((j - 1) * delayTime)
                local scale = 0.4 + math.random(0, 2) * 0.1
                local scaleTo = cc.ScaleTo:create(0.15, scale)
                -- local bez =
                -- cc.BezierTo:create(
                -- 0.5,
                -- {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})

                local bez =
                cc.BezierTo:create(
                0.65,
                {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x + (endPos.x - startPos.x) * 0.5, startPos.y), endPos})

                coins:runAction(cc.Sequence:create(delayAction, scaleTo, cc.EaseOut:create(bez, 1), cc.CallFunc:create(function()
                    if coins.isLastOne == true then
                        -- if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.bonusFeatures ~= nil
                        --  and self.m_runSpinResultData.p_selfMakeData.bonusFeatures[1] ~= nil and self.m_runSpinResultData.p_selfMakeData.bonusFeatures[1] == 1 
                        -- then

                        -- end
                        gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_wild_coin.mp3")
                    end
                    coins:removeFromParent()
                    local symbolType = coins.p_symbolType
                    self:pushSlotNodeToPoolBySymobolType(symbolType, coins)
                end)))
            end
        end

        

        table.remove(self.m_collectList, i)
    end

    self.m_FortuneTreeEffect:setVisible(true)
    util_spinePlay(self.m_FortuneTreeEffect, "Duofuduocai_facaishu_more_shouji", false)
    util_spineEndCallFunc(self.m_FortuneTreeEffect, "Duofuduocai_facaishu_more_shouji", function()
        self.m_FortuneTreeEffect:setVisible(true)
    end)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFortuneTreeMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
    self.m_freespinBar:setVisible(true)
    self.m_freespinBar:changeFreeSpinByCount()
    if self.m_iReelRowNum == self.m_iReelMinRow then
        self:findChild("freespin3x5"):setVisible(true)
        self:findChild("normal3x5"):setVisible(false)
    end
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFortuneTreeMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"nomal")
    self:findChild("normal3x5"):setVisible(true)
end

function CodeGameScreenFortuneTreeMachine:playGuoChangAnimation(delayTime, delayCall, overCall)
    performWithDelay(self, function()
        self.m_guochang:setVisible(true)
        util_spinePlay(self.m_guochang, "animation", false)
        if delayCall ~= nil then
            performWithDelay(self, function()
                delayCall()
            end, 1.4)
        end
        performWithDelay(self, function()
            gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_close_door.mp3")
        end, 0.3)
        util_spineFrameCallFunc(self.m_guochang, "animation", "show", function()
        end, function()
            self.m_guochang:setVisible(false)
            if overCall ~= nil then
                overCall()
            end
        end)
    end, delayTime)
end
---------------------------------------------------------------------------

function CodeGameScreenFortuneTreeMachine:spinResultCallFun(param)
    
    BaseSlotoManiaMachine.spinResultCallFun(self, param)
                    
    if param[1] == true and self.m_bIsSelectCall == true then
        local spinData = param[2]
        self:playGuoChangAnimation(0.33, function()
            globalData.slotRunData.freeSpinCount = spinData.result.freespin.freeSpinsLeftCount 
            globalData.slotRunData.totalFreeSpinCount = spinData.result.freespin.freeSpinsTotalCount
            self.m_iReelRowNum = self.m_vecReelRow[self.m_iSelectID]
            self:findChild("Node_facaishu"):setVisible(true)
            self:findChild("Lun_pan"):setVisible(true)
            self.m_chooseFSView:setVisible(false)
            if self.m_iReelRowNum > self.m_iReelMinRow then
                self:changeReelData()
            end
            self:levelFreeSpinEffectChange()
        end, function()
            self:triggerFreeSpinCallFun()
            self.m_effectData.p_isPlay = true
            self:playGameEffect()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end)
    end
end

function CodeGameScreenFortuneTreeMachine:updateNetWorkData()
    local animationTime = 0
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildPositions ~= nil and #self.m_runSpinResultData.p_selfMakeData.wildPositions > 0 then
        util_spinePlay(self.m_FortuneTreeTree, "actionframe")
            util_spineEndCallFunc(self.m_FortuneTreeTree, "actionframe", function()
                util_spinePlay(self.m_FortuneTreeTree, "Duofuduocai_facaishu_more_idle", true)
            end)

        local vecWild = self.m_runSpinResultData.p_selfMakeData.wildPositions
        local startPos = self.m_FortuneTreeTree:getParent():convertToWorldSpace(cc.p(self.m_FortuneTreeTree:getPosition()))
        startPos = self.m_clipParent:convertToNodeSpace(startPos)
        startPos.y = startPos.y - 40
        local delayTime = 0.08
        animationTime = delayTime * #vecWild + 0.2 + 0.1 + 2
        gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_wild_drop.mp3")
        for i = 1, #vecWild, 1 do
            local xPow = math.random(1, 2)
            local yPow = math.random(1, 2)
            local newStartPos = cc.pAdd(startPos, cc.p(math.random(0, 80) * math.pow(-1, xPow), math.random(0, 10) * math.pow(-1, yPow)))

            local index = vecWild[i]
            local pos = self:getRowAndColByPos(index)
            local iX = 56
            local iY = self.m_SlotNodeH * (pos.iX - 0.5)
            local colNodeName = "sp_reel_" .. (pos.iY - 1)
            local reel = self:findChild(colNodeName)
            local reelPos = cc.p(iX, iY)
            local worldPos = reel:convertToWorldSpace(reelPos)
            local nodePos = self.m_clipParent:convertToNodeSpace(worldPos)
            local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)
            local symbol = self:getSlotNodeBySymbolType(symbolType)
            self.m_clipParent:addChild(symbol, 1000000)
            symbol:setPosition(newStartPos)
            symbol.p_cloumnIndex = pos.iY
            symbol.p_rowIndex = pos.iX
            symbol.m_isLastSymbol = true
            self:hideMultiple(symbol, symbolType)
            symbol:setVisible(false)
            local delayAction = cc.DelayTime:create((i - 1) * delayTime + 0.2)
            local bez =
            cc.BezierTo:create(
            0.5,
            {cc.p(newStartPos.x + (newStartPos.x - nodePos.x) * 0.5, newStartPos.y), cc.p(nodePos.x, newStartPos.y), nodePos})

            symbol:runAction(cc.Sequence:create(delayAction, cc.CallFunc:create(function()
                symbol:setVisible(true)
                symbol:runAnim("diaoluo")
            end), cc.DelayTime:create(0.1), bez, cc.CallFunc:create(function()
                gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_wild_down.mp3")
                symbol:runAnim("buling", false, function()
                    symbol:runAnim("idleframe")
                end)
            end)))
            if self.m_vecDropCoins == nil then
                self.m_vecDropCoins = {}
            end
            self.m_vecDropCoins[#self.m_vecDropCoins + 1] = symbol
        end
    end
    performWithDelay(self, function()
        BaseSlotoManiaMachine.updateNetWorkData(self)
    end, animationTime)
    
end

function CodeGameScreenFortuneTreeMachine:playEffectNotifyNextSpinCall( )
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or 
    self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end
    self.m_bIsSelectCall = false
end

function CodeGameScreenFortuneTreeMachine:sendData(index)

    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)

end
----------- FreeSpin相关
-- FreeSpinstart

function CodeGameScreenFortuneTreeMachine:showFreeSpinView(effectData)
    -- 界面选择回调
    local function chooseCallBack(index)
        self:sendData(index)
        self.m_bIsSelectCall = true
        self.m_iSelectID = index
        self.m_effectData = effectData
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        self:findChild("Node_facaishu"):setVisible(false)
        self:findChild("Lun_pan"):setVisible(false)
        self.m_chooseFSView:setVisible(true)
        self.m_chooseFSView:appear()
        self.m_chooseFSView:initViewData(chooseCallBack)
        gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_pop_choose_fs.mp3")
    else
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:showFreeSpinMore(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            true
        )
        -- gLobalSoundManager:setBackgroundMusicVolume(0.4)
        -- gLobalSoundManager:playSound("LightCherrySounds/music_lightcherry_custom_enter_fs_2.mp3",false, function(  )
        --     gLobalSoundManager:setBackgroundMusicVolume(1)
        -- end)
    end
end

function CodeGameScreenFortuneTreeMachine:showFreeSpinOverView()

    performWithDelay(self, function()
        gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_over_fs.mp3")
   
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:playGuoChangAnimation(1, function()
                    if self.m_iReelRowNum > self.m_iReelMinRow then
                        self.m_iReelRowNum = self.m_iReelMinRow
                        self:clearWinLineEffect()
                        self:changeReelData()
                    end
                    self.m_jackpotBar:setVisible(true)
                    -- self.m_jackpotFreespinBar:setVisible(false)
                    -- self.m_jackpotFreespinBar:resetBarDisplay()
                    self.m_freespinBar:setVisible(false)
                    -- self:removeAllReelsNode()
                    -- self:createRandomReelsNode()
                    self:levelFreeSpinOverChangeEffect()
                end, function()
                    self:triggerFreeSpinOverCallFun()
                end)
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.85,sy=0.85}, 660)
    end, 1)
end

function CodeGameScreenFortuneTreeMachine:removeAllReelsNode()

    self:clearWinLineEffect()
    for iCol = 1, self.m_iReelColumnNum do

        for iRow = 1, self.m_iReelRowNum do

            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            
            if targSp then
                targSp:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end

        end
    end
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if child.removeFromParent ~= nil then
            child:removeFromParent()
        end
    end
end

function CodeGameScreenFortuneTreeMachine:createRandomReelsNode()
    
    local reels = {}
    
    for iRow = 1, 3 do
        reels[iRow] = self.m_runSpinResultData.p_selfMakeData.reels[#self.m_runSpinResultData.p_selfMakeData.reels - iRow + 1]
    end

    for iCol = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[iCol]
        local slotParent = parentData.slotParent

        for iRow = 1, 3 do

            local symbolType = reels[iRow][iCol]
            
            if symbolType then

                local newNode =  self:getSlotNodeWithPosAndType( symbolType , iRow, iCol , false)
                if newNode:getParent() then
                    print("qaq")
                end
                newNode:removeFromParent()  -- 暂时补丁
                -- parentData.slotParent:addChild(
                --     newNode,
                --     REEL_SYMBOL_ORDER.REEL_ORDER_2,
                --     iCol * SYMBOL_NODE_TAG + iRow
                -- )

                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(newNode.p_symbolType) then
                    slotParentBig:addChild(newNode,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 - iRow , iCol * SYMBOL_NODE_TAG + iRow)
                else
                    parentData.slotParent:addChild(newNode,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 - iRow , iCol * SYMBOL_NODE_TAG + iRow)
                end

                newNode.m_symbolTag = SYMBOL_NODE_TAG
                newNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
                newNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                newNode.m_isLastSymbol = true
                newNode.m_bRunEndTarge = false
                local columnData = self.m_reelColDatas[iCol]
                newNode.p_slotNodeH = columnData.p_showGridH         
                newNode:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                local halfNodeH = columnData.p_showGridH * 0.5
                newNode:setPositionY(  (iRow - 1) * columnData.p_showGridH + halfNodeH )
            end

        end
    end
end

function CodeGameScreenFortuneTreeMachine:changeReelData()
    self:findChild("Lun_pan3x5"):setVisible(false)
    self:findChild("Lun_pan4x5"):setVisible(false)
    self:findChild("Lun_pan5x5"):setVisible(false)
    self:findChild("Lun_pan"..self.m_iReelRowNum.."x5"):setVisible(true)
    if self.m_iReelRowNum == self.m_iReelMinRow then
        self.m_FortuneTreeTree:setPositionY(0)
        self.m_freespinBar:setPositionY(0)
        self.m_stcValidSymbolMatrix[4] = nil 
        self.m_stcValidSymbolMatrix[5] = nil
    else
        local nodeH = self.m_SlotNodeH * 1.18
        self.m_FortuneTreeTree:setPositionY(nodeH * (self.m_iReelRowNum - self.m_iReelMinRow))
        self.m_freespinBar:setPositionY(nodeH * (self.m_iReelRowNum - self.m_iReelMinRow))
        for i = self.m_iReelMinRow + 1, self.m_iReelRowNum, 1 do
            if self.m_stcValidSymbolMatrix[i] == nil then
                self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
            end
        end
        self.m_jackpotBar:setVisible(false)
        -- self.m_jackpotFreespinBar:setVisible(true)
        -- self.m_jackpotFreespinBar:changeBarDisplay()
        self:addNewRandomSymbol()
    end
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x, 
                y = rect.y, 
                width = rect.width, 
                height = columnData.p_slotColumnHeight
            }
        )
    end
end

function CodeGameScreenFortuneTreeMachine:addNewRandomSymbol()
    for colIndex=1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = self.m_iReelRowNum
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = self.m_iReelMinRow + 1, resultLen do
            local children = parentData.slotParent:getChildren()
            local haveSymbol = false
            for i = 1, #children, 1 do
                local child = children[i]
                if child.p_cloumnIndex == colIndex and child.p_rowIndex == rowIndex then
                    haveSymbol = true
                    break
                end
            end
            if haveSymbol == false then
                local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
                local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
                node.p_slotNodeH = reelColData.p_showGridH      
                
                node.p_symbolType = symbolType
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
            
                -- parentData.slotParent:addChild(node,
                -- node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)

                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,node.p_showOrder - rowIndex , colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,node.p_showOrder - rowIndex , colIndex * SYMBOL_NODE_TAG + rowIndex)
                end

                node.p_reelDownRunAnima = parentData.reelDownAnima

                node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )
            end
        end
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFortuneTreeMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_bReconnect = false


    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenFortuneTreeMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFortuneTreeMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFortuneTreeMachine:addSelfEffect()
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFortuneTreeMachine:MachineRule_playSelfEffect(effectData)
    
	return true
end

function CodeGameScreenFortuneTreeMachine:showEffect_Bonus(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    if self.m_runSpinResultData.p_selfMakeData.bonusFeatures[1] == 1 then
        if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
            self.m_questView:hideQuestView()
        end
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

        -- gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_trriger_bonus.mp3", false, function()
        --     self.m_currentMusicBgName = "FortuneTreeSounds/music_FortuneTree_bs_bg.mp3"
        --     self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        -- end)
        local triggerAnimation = function()
            gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_trriger_bonus.mp3")
            util_spinePlay(self.m_FortuneTreeTree, "actionframe2")
            util_spineEndCallFunc(self.m_FortuneTreeTree, "actionframe2", function()
                local bonusView = nil
                util_spinePlay(self.m_FortuneTreeTree, "Duofuduocai_facaishu_more_idle", true)
                self:playGuoChangAnimation(1, function()
                    bonusView = util_createView("CodeFortuneTreeSrc.FortuneTreeBnousGameLayer", self.m_jackpotPos)
                    bonusView:initViewData(function(coins, jackpot)
                                
                        self:bonusGameOver(coins, jackpot, function()
                            
                            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(coins))
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    
                            self:playGuoChangAnimation(0.33, function()
                                bonusView:removeFromParent()
                            end, function()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                                self:resetMusicBg()
                                self:setMinMusicBGVolume()
                            end)
                        end)
    
                    end, self)
                    self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                    if globalData.slotRunData.machineData.p_portraitFlag then
                        bonusView.getRotateBackScaleFlag = function(  ) return false end
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = bonusView})

                end, function()
                    bonusView:appearAnimation()
                    self.m_currentMusicBgName = "FortuneTreeSounds/music_FortuneTree_bs_bg.mp3"
                    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
                end)
            end)
        end
        performWithDelay(self, function()
            triggerAnimation()
        end, 0.8)
        
    else
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearWinLineEffect()
        performWithDelay(self, function()
            
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
            if scatterLineValue ~= nil then        
                -- 
                self:showBonusAndScatterLineTip(scatterLineValue,function()
                    -- self:visibleMaskLayer(true,true)            
                    gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                    self:showFreeSpinView(effectData)
                end)
                scatterLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue        
                -- 播放提示时播放音效        
                gLobalSoundManager:stopAudio(self.m_winSoundsId)
                self.m_winSoundsId = nil
                self:playScatterTipMusicEffect()
            else
                self:showFreeSpinView(effectData)
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_runSpinResultData.p_winAmount))
            end
        end, 1)
    end
   

    return true
end

function CodeGameScreenFortuneTreeMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 
      or (self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.bonusFeatures ~= nil and self.m_runSpinResultData.p_selfMakeData.bonusFeatures[1] == 0) then
         isNotifyUpdateTop = false
     end 

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})  
end

function CodeGameScreenFortuneTreeMachine:bonusGameOver(coins, jackpot, func)
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_pop_jackpot.mp3")
    self.m_grandShare = nil
    local jackpotIndex = jackpot == "Grand" and 1 or nil

    local playIdleFunc = function()
        self:jumpCoinsFinish(jackpotIndex)
    end

    local view = self:showDialog("Jackpot_"..jackpot, ownerlist, func)
    self:createGrandShare(self, view)
    if jackpot == "Grand" then
        view:setPlayIdleFunc(playIdleFunc)
        view:setPlayOverState(true)
    end
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.85,sy=0.85}, 660)
end

function CodeGameScreenFortuneTreeMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeFortuneTreeSrc.FortuneTreeBaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
    gLobalViewManager:showUI(view)
    -- end

    return view
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFortuneTreeMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

--[[
    自动分享 | 手动分享
]]
function CodeGameScreenFortuneTreeMachine:createGrandShare(_machine, _view)
    local parent      = _view:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function CodeGameScreenFortuneTreeMachine:jumpCoinsFinish(_jackpotIndex)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(_jackpotIndex)
    end
end

function CodeGameScreenFortuneTreeMachine:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function CodeGameScreenFortuneTreeMachine:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    end
end

return CodeGameScreenFortuneTreeMachine






