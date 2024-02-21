
local PublicConfig = require "KittysCatchPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenKittysCatchMachine = class("CodeGameScreenKittysCatchMachine", BaseNewReelMachine)

CodeGameScreenKittysCatchMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenKittysCatchMachine.BONUS_EAT_FISH_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 -- bonus吃鱼

CodeGameScreenKittysCatchMachine.SYMBOL_BONUS   = 94 -- 自定义的小块类型
CodeGameScreenKittysCatchMachine.SYMBOL_SCATTER_1   = 95 -- 自定义的小块类型   计数 scatter
CodeGameScreenKittysCatchMachine.SYMBOL_SCATTER_2   = 96 -- 自定义的小块类型   wild scatter
CodeGameScreenKittysCatchMachine.SYMBOL_WILD_2   = 97 -- 自定义的小块类型   wild 替换盘上时显示用

-- 构造函数
function CodeGameScreenKittysCatchMachine:ctor()
    CodeGameScreenKittysCatchMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    self.m_fsReplaceWildPosSymbol = {}
    self.m_fsRecordUnderWildPosSymbol = {}
    self.m_lastScatterLockData = {}
    self.m_symbolUpZOrderArray = {}

    self.m_bonusMultiData = {}

    self.m_moveFishTankEvent = {}

    self.m_isPlayWinningNotice = false
    self.m_fishTankNumsLast = {1,1,1,1,1}
    self.m_isShowMask = false
    self.m_isPlayFishTankMove = false
    self.m_playFishTankMoveTimes = 0
    self.m_fishTankMoveList = {}

    self.m_eatFishTriggerDelay = 0
    self.m_isLongRun = false

    self.m_baseScatterLockNodes = {}
    self.m_freeWildLockNodes = {}

    self.m_disableSpinBtn = false
    -- self.m_isPlaySoundCatjerky = false
    -- self.m_isPlaySoundMeow4 = false

    self.m_isTriggerStartFree = false

    self.m_longRunSoundId = nil
    self.m_playMoveSound = true
    self.m_isClearWinLine = true --切bet的时候 清理赢钱线的标识
    self.m_changeScatterSymbolByChangeBet = {}--切换bet之后 scatter变成的信号值 暂存
 
    --init
    self:initGame()
end

function CodeGameScreenKittysCatchMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenKittysCatchMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "KittysCatch"  
end

function CodeGameScreenKittysCatchMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    util_csbScale(self.m_gameBg2.m_csbNode, 1)

    self.m_baseScatterLockNodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local posIdx = self:getPosReelIdx(iRow, iCol)
            self.m_baseScatterLockNodes[posIdx] = cc.Node:create()
            self.m_clipParent:addChild(self.m_baseScatterLockNodes[posIdx], REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + posIdx)
            
        end
    end
    self.m_freeWildLockNodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local posIdx = self:getPosReelIdx(iRow, iCol)
            self.m_freeWildLockNodes[posIdx] = cc.Node:create()
            self.m_clipParent:addChild(self.m_freeWildLockNodes[posIdx], REEL_SYMBOL_ORDER.REEL_ORDER_2 + posIdx)
        end
    end
    

    self.m_delayNodeForMove = cc.Node:create()
    self:addChild(self.m_delayNodeForMove)
    
    
    --鱼缸
    self.m_fishTanks = {}
    self.m_fishTankPos = {}
    for i = 1, 5 do
        self.m_fishTanks[i], self.m_fishTankPos[i] = self:createFishTank(i) 
    end
   
    self.m_baseReelBg = self:findChild("Node_base_reel")
    self.m_freeReelBg = self:findChild("Node_free_reel")
    self.m_baseEdge = self:findChild("kuang_base")
    self.m_freeEdge = self:findChild("kuang_free")

    self.m_orderPicName = {"kuang_base", "KittysCatch_zhujiemian_qipan_3_8", "kuang_2", "xianshu_2", "kuang_1", "xianshu_1"}
    self.m_orderPicNodes = {}
    for i=1,#self.m_orderPicName do
        local node = self:findChild(self.m_orderPicName[i])
        local convert_pos = util_convertToNodeSpace(node,  self.m_clipParent)
        util_changeNodeParent(self.m_clipParent, node, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 50 + i)
        node:setPosition(convert_pos)
        table.insert(self.m_orderPicNodes, node)
    end
    
    for i=1,4 do
        self:findChild("lizi" .. i):stopSystem()
    end

    --freebar
    self.m_freeBarView = util_createView("CodeKittysCatchSrc.KittysCatchFreespinBarView")
    local freeBar_pos = util_convertToNodeSpace(self:findChild("Node_freebar"),  self.m_clipParent)
    self.m_clipParent:addChild(self.m_freeBarView, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 200)
    self.m_freeBarView:setPosition(freeBar_pos)
    self.m_freeBarView:setVisible(false)

    --猫头
    self.m_catHead = util_spineCreate("KittysCatch_yugao", true, true)
    self:findChild("Node_freemaotou"):addChild(self.m_catHead)
    self.m_catHead:setVisible(false)
    self:findChild("Node_freemaotou"):setPosition(cc.p(0,0))

    --过场遮罩
    self.m_maskTrans = util_createAnimation("KittysCatch_mask.csb")
    self:findChild("Node_trans"):addChild(self.m_maskTrans, 10)
    self.m_maskTrans:setVisible(false)

    self.m_trans = util_spineCreate("KittysCatch_guochang", true, true)
    self:findChild("Node_trans"):addChild(self.m_trans, 20)
    self.m_trans:setVisible(false)


    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    --吃鱼层
    self.m_eatFishNode = cc.Node:create()
    self:addChild(self.m_eatFishNode, GAME_LAYER_ORDER.LAYER_ORDER_TOP + 1)
    self.m_eatFishNode:setScale(self.m_machineRootScale)

    --黑遮罩
    self.m_maskEatFish = util_createAnimation("KittysCatch_mask.csb")
    self.m_maskEatFish:findChild("Panel_1"):setContentSize(cc.size(10000, 10000))
    self.m_eatFishNode:addChild(self.m_maskEatFish)
    self.m_maskEatFish:runCsbAction("idle")
    self.m_maskEatFish:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_maskEatFish:setVisible(false)


    self:addClick(self:findChild("Panel_CatClick"))

    -- 创建预告中奖
    self.m_preViewWinNode = util_spineCreate("KittysCatch_yugao", true, true)
    self:findChild("Node_trans"):addChild(self.m_preViewWinNode, 30)
    self.m_preViewWinNode:setPosition(0,0)
    self.m_preViewWinNode:setVisible(false)

    self.m_reelDark = self:findChild("dark")
    local node_pos = util_convertToNodeSpace(self.m_reelDark,  self.m_clipParent)
    util_changeNodeParent(self.m_clipParent, self.m_reelDark, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100)
    self.m_reelDark:setPosition(cc.p(node_pos))

    -- 大赢上层特效
    self.m_spineBigWin = util_spineCreate("KittysCatch_binwin", true, true)
    self:findChild("Node_bigWin"):addChild(self.m_spineBigWin)
    self.m_spineBigWin:setPosition(0,0)
    self.m_spineBigWin:setVisible(false)


    self:changeWinCoinEffectCsb(true)

end

function CodeGameScreenKittysCatchMachine:createFishTank(_idx, _order)
    local order = _order or 3000
    local fishTank = util_createView("CodeKittysCatchSrc.KittysCatchFishTankView")
    fishTank:initMachine(self, _idx)
    local node_pos = util_convertToNodeSpace(self:findChild("Node_yugang_" .. _idx),  self.m_clipParent)
    self.m_clipParent:addChild(fishTank, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + order + _idx)
    fishTank:setPosition(node_pos)
    return fishTank, node_pos
end

--默认按钮监听回调
function CodeGameScreenKittysCatchMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_CatClick" then
        if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_catHead:isVisible() and not self.m_catAnimIsPlay then
            self.m_catAnimIsPlay = true
            util_spinePlay(self.m_catHead, "actionframe2", false)
            local spineEndCallFunc = function()
                self:playCatHeadAnim()
                self.m_catAnimIsPlay = false
            end
            util_spineEndCallFunc(self.m_catHead, "actionframe2", spineEndCallFunc)

            gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_click.mp3")
            gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_click_cat.mp3")
        end
    end  
end

-- 预告中奖
function CodeGameScreenKittysCatchMachine:preViewWin(func)  
    self.m_isPlayWinningNotice = false

    self:setUiOrder(true)
    self:runCsbAction("dark", false, function (  )
        self:runCsbAction("idle2", true)
    end)

    self.m_preViewWinNode:setVisible(true)
    util_spinePlay(self.m_preViewWinNode, "actionframe", false)
    local spineEndCallFunc = function()
    end
    util_spineEndCallFunc(self.m_preViewWinNode, "actionframe", spineEndCallFunc)

    self:levelPerformWithDelay(95/30, function()
        self:runCsbAction("over", false, function (  )
            self:runCsbAction("idle1", true)
            self:setUiOrder(false)
        end)
    end)

    self:levelPerformWithDelay(95/30, function()
        if func then
            func()
        end
    end)


    gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_WinningNotice.mp3")
end


function CodeGameScreenKittysCatchMachine:enterGamePlayMusic(  )
    gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_enter_game.mp3")
end

--[[
    断线进来的时候 处理
]]
function CodeGameScreenKittysCatchMachine:updateBaseLockNodeOfComeIn()
    self:clearLockNode(true)

    local data = self:getStickScatterData()
    for i = 1, #data do
        local pos = data[i][1]
        local num = data[i][2]
        if num == 1 then
            local fixPos = self:getRowAndColByPos(pos)
            local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX , SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType then
                self:changeOneSymbol(symbolNode, self.SYMBOL_SCATTER_1)
                self:setSlotsNodeCornerNum(symbolNode, 1)
            end
        else
            local lockNode = self:createOneLockNode(pos, self.SYMBOL_SCATTER_1)
            lockNode:updateCornerNum(num)
        end
    end

end

function CodeGameScreenKittysCatchMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    --断线重连处理
    if self.m_runSpinResultData.p_freeSpinsLeftCount == nil or self.m_runSpinResultData.p_freeSpinsLeftCount <= 0 then
        self:changeBg("base", false)
        self:setFishTankNum()
        self:updateBaseLockNodeOfComeIn()

        local view = self:showDialog("GameStart", {}, function()
            
        end, 2)
        gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_GameStart_show.mp3")
        view:setBtnClickFunc(function (  )
            gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_GameStart_over.mp3")
        end)


        for iCol = 1,self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
                if node and node.p_symbolType == self.SYMBOL_BONUS then
                    self.setSymbolToClipReel(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 0)
                    node:runAnim("idleframe", true)
                end
            end 
        end
    else
        self:changeBg("free", false)

        if self.m_runSpinResultData.p_features[2] == 1 then --触发free
            if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                --free
                local ignore = self:getGameInitIgnore(self.SYMBOL_SCATTER_1)

                self:updateBaseLockNodeOfComeIn()
            else
                --more
                local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
                local wildIconsPos = fsExtraData.newStickWild or {}
                local ignore = {}
                for i=1,#wildIconsPos do
                    ignore[wildIconsPos[i]] = wildIconsPos[i]
                end
                self:initFreeLockNode(ignore)
            end
        else
            local ignore = self:getGameInitIgnore(self.SYMBOL_SCATTER_2)
            self:initFreeLockNode(ignore)
        end
        
    end



    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end

    self.m_curTotalBet = globalData.slotRunData:getCurTotalBet()
end

function CodeGameScreenKittysCatchMachine:getGameInitIgnore(_symbolType)
    local ignore = {}
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    local runResultData = self.m_runSpinResultData.p_reels
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolType = runResultData[reelRow - i + 1][j]
            if symbolType == _symbolType then
                local posIdx = self:getPosReelIdx(i, j)
                ignore[posIdx] = posIdx
            end
        end
    end

    return ignore
end

function CodeGameScreenKittysCatchMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenKittysCatchMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenKittysCatchMachine:addObservers()
    CodeGameScreenKittysCatchMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount == 0 then
            else
                return
            end
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
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "KittysCatchSounds/music_KittysCatch_last_win_base_1.mp3"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "KittysCatchSounds/music_KittysCatch_last_win_free_".. soundIndex .. ".mp3"
        else
            soundName = "KittysCatchSounds/music_KittysCatch_last_win_base_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)


    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateMainUi()
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenKittysCatchMachine:updateMainUi()
    self:updateBaseLockNode()
    self:updateChangeScatter()

    self:setFishTankNum()
    if self.m_fishTankMoveList then
        if #self.m_fishTankMoveList > 0 then
            for i=1,#self.m_fishTankMoveList do
                self.m_fishTankMoveList[i] = self:getFishTankNums()
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end


    CodeGameScreenKittysCatchMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenKittysCatchMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_KittysCatch_Bonus"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_KittysCatch_Scatter"
    elseif symbolType == self.SYMBOL_SCATTER_1 then
        return "Socre_KittysCatch_Scatter2"
    elseif symbolType == self.SYMBOL_SCATTER_2 then
        return "Socre_KittysCatch_Scatter2"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_KittysCatch_Wild"
    elseif symbolType == self.SYMBOL_WILD_2 then
        return "Socre_KittysCatch_Wild_2"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenKittysCatchMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenKittysCatchMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_2,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

---------------------------------------------------------------------------
--创建锁定块
function CodeGameScreenKittysCatchMachine:createOneLockNode(_posIndex, _symbolType)

    local node = util_require("CodeKittysCatchSrc.KittysCatchLockNode"):create(self, 1, _symbolType)
    local parentNode = self.m_baseScatterLockNodes[_posIndex]
    if _symbolType == 95 then
    elseif _symbolType == 96 or _symbolType == 97 then
        parentNode = self.m_freeWildLockNodes[_posIndex]
    end
    parentNode:addChild(node, 1, 1)
    node:setPosition(util_getOneGameReelsTarSpPos(self, _posIndex))

    return node

end
--更新base锁定块 初始 切bet .eg
function CodeGameScreenKittysCatchMachine:updateBaseLockNode(_ignorePos)
    local ignorePos = _ignorePos or {}
    self:clearLockNode(true)

    local data = self:getStickScatterData()
    for i = 1, #data do
        local pos = data[i][1]
        local num = data[i][2]
        if ignorePos[pos] then
        else
            local lockNode = self:createOneLockNode(pos, self.SYMBOL_SCATTER_1)
            lockNode:updateCornerNum(num)
        end
    end

end

--[[
    切换bet时 更新棋盘上的scatter（带数字）图标 95 
]]
function CodeGameScreenKittysCatchMachine:updateChangeScatter( )
    if self.m_isClearWinLine then
        self.m_isClearWinLine = false
        self:clearWinLineEffect()
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    -- 从scatter 切换变成其他信号
    if self.m_curTotalBet ~= totalBet then
        for iRow = self.m_iReelRowNum, 1, -1 do
            for iCol = 1, self.m_iReelColumnNum do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
                if node and node.p_symbolType == self.SYMBOL_SCATTER_1 then
                    local posIndex = self:getPosReelIdx(iRow, iCol)
                    if not self.m_changeScatterSymbolByChangeBet[posIndex] then
                        -- 暂存一下变得信号 保持一直切换的时候 不在变化
                        local randType = math.random(0, TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
                        self.m_changeScatterSymbolByChangeBet[posIndex] = randType
                    end
                    local randType = self.m_changeScatterSymbolByChangeBet[posIndex]
                    self:changeSymbolType(node, randType)
                    self:removeSlotsNodeCorner(node)
                end
            end
        end
    else
        -- 变会scatter 
        for iRow = self.m_iReelRowNum, 1, -1 do
            for iCol = 1, self.m_iReelColumnNum do
                local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
                if symbolType and type(symbolType) == "number" and symbolType == self.SYMBOL_SCATTER_1 then
                    if node and node.p_symbolType then
                        self:changeSymbolType(node, symbolType)
                        self:setSlotsNodeCornerNum(node, 3)
                    end
                end
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:addBaseLockNode()

    local data = self:getStickScatterData()
    for i = 1, #data do
        local pos = data[i][1]
        local num = data[i][2]
        if self.m_baseScatterLockNodes[pos] then
            local lockNode = self.m_baseScatterLockNodes[pos]:getChildByTag(1)
            if num == 3 then
                if not lockNode then
                    local lockNode = self:createOneLockNode(pos, self.SYMBOL_SCATTER_1)
                    lockNode:updateCornerNum(num)
                else
                    release_print("addBaseLockNode is Have Error!!!")
                end
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:initFreeLockNode(_ignorePosArray)
    local ignorePosArray = _ignorePosArray or {}

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildIconsPos = fsExtraData.stickWild or {}

    for i = 1, #wildIconsPos do
        local pos = wildIconsPos[i]
        if ignorePosArray[pos] then
        else
            local lockNode = self:createOneLockNode(pos, self.SYMBOL_WILD_2)
        end
    end
end

function CodeGameScreenKittysCatchMachine:addFreeLockNode(func)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildIconsPos = fsExtraData.newStickWild or {}

    local isHave = false
    for i = 1, #wildIconsPos do
        isHave = true
        
        local pos = wildIconsPos[i]
        local lockNode = self:createOneLockNode(pos, self.SYMBOL_SCATTER_2)

        self.m_freeWildLockNodes[pos]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100 + pos)
        lockNode:playLockAction("switch2", false, function()

        end)

        --禁止stop点击
        self.m_disableSpinBtn = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})

        if i == #wildIconsPos then
            if func then
                func()
            end
        end

        self:levelPerformWithDelay(39/30, function()
            self:clearLockNode(false, pos)
            self:createOneLockNode(pos, self.SYMBOL_WILD_2)

            self.m_freeWildLockNodes[pos]:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + pos)
            
            --还原stop点击
            self.m_disableSpinBtn = false
            if self.m_isWaitingNetworkData == false then --倒猫粮动画期间 不让点停轮
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            end
        end)
    end
    if not isHave then
        -- if func then
        --     func()
        -- end
    else
        gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_catfood_pour.mp3")
    end
    return isHave
end

--重写
function CodeGameScreenKittysCatchMachine:dealSmallReelsSpinStates()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_disableSpinBtn == false then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
end

function CodeGameScreenKittysCatchMachine:clearLockNode(_isBase, _idx)
    if _isBase then
        for i, v in pairs(self.m_baseScatterLockNodes) do
            if v then
                if _idx then
                    if _idx == i then
                        v:removeAllChildren()
                    end
                else
                    v:removeAllChildren()
                end
            end
        end
    else
        for i, v in pairs(self.m_freeWildLockNodes) do
            if v then
                if _idx then
                    if _idx == i then
                        v:removeAllChildren()
                    end
                else
                    v:removeAllChildren()
                end
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:hideLockNode(_isBase, _isHide, _checkLine)
    if _isBase then
        for i, v in pairs(self.m_baseScatterLockNodes) do
            if v then
                v:setVisible(not _isHide)
            end
        end
    else
        for i, v in pairs(self.m_freeWildLockNodes) do
            if v then
                if _checkLine then --不连线的不隐藏
                    if self:isPosInLine(i) then
                        v:setVisible(not _isHide)
                    end
                else
                    v:setVisible(not _isHide)
                end
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:orderLockNode(_isBase, _order)
    if _isBase then
        for i, v in pairs(self.m_baseScatterLockNodes) do
            if v then
                v:setLocalZOrder(_order + i)
            end
        end
    else
        for i, v in pairs(self.m_freeWildLockNodes) do
            if v then
                v:setLocalZOrder(_order + i)
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:wildOverLockNode()
    for i, v in pairs(self.m_freeWildLockNodes) do
        if v then
            local lockNode = v:getChildByTag(1)
            if lockNode then
                util_playFadeOutAction(lockNode, 10/30, function (  )
                end)
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:scatterLockNodeFadeIn()
    for i, v in pairs(self.m_baseScatterLockNodes) do
        if v then
            local lockNode = v:getChildByTag(1)
            if lockNode then
                lockNode:setOpacity(0)
                util_playFadeInAction(lockNode, 10/30, function (  )
                end)
            end
        end
    end
end

--重写
---
-- 显示free spin
function CodeGameScreenKittysCatchMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil 
    end

    --触发动画
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            while true 
            do
                --锁定上的   free中为空
                local posIdx = self:getPosReelIdx(iRow, iCol)
                if self.m_baseScatterLockNodes[posIdx] then
                    local lockNode = self.m_baseScatterLockNodes[posIdx]:getChildByTag(1)
                    if lockNode then
                        self.m_baseScatterLockNodes[posIdx]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 50 + posIdx)
                        lockNode:playLockAction("actionframe2", false, function()
                            lockNode:runIdleAction()
                        end)
                        lockNode:playCornerOverAction()
                        break
                    end
                end
                --还未到锁定上的
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node and (node.p_symbolType == self.SYMBOL_SCATTER_1 or 
                node.p_symbolType == self.SYMBOL_SCATTER_2 or
                node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    -- 处理断线重连后提层
                    local nodeParent = node:getParent()
                    if nodeParent and nodeParent ~= self.m_clipParent then
                        self.setSymbolToClipReel(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 0)
                    end

                    node:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 50 + posIdx)
                    if node.p_symbolType == self.SYMBOL_SCATTER_1 then
                        self:playSlotsNodeCornerOver(node)
                        node:runAnim("actionframe2",false, function()
                            node:runAnim("idleframe", true)
                        end)
                    elseif node.p_symbolType == self.SYMBOL_SCATTER_2 then
                        node:runAnim("actionframe3",false, function()
                            node:runAnim("idleframe2", true)
                        end)
                    elseif node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        node:runAnim("actionframe",false, function()
                            node:runAnim("idleframe", true)
                        end)
                    end
                end

               break 
            end
            
        end 
    end
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_FreeGameIn_trigger.mp3")
    else
        gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_FreeGame_trigger.mp3")
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end
    

    self:levelPerformWithDelay(1.6, function()
        self:showFreeSpinView(effectData)
    end)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenKittysCatchMachine:scatterChangeToWild( func )

    gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_catfood_pour.mp3")

    --change动画
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if node and node.p_symbolType == self.SYMBOL_SCATTER_1 then
                local posIdx = self:getPosReelIdx(iRow, iCol)
                local oldZOrder = node:getLocalZOrder()
                node:runAnim("switch",false, function()
                end)
            end
        end 
    end
    --锁定上的change动画
    for i, v in pairs(self.m_baseScatterLockNodes) do
        if v then
            local lockNode = v:getChildByTag(1)
            if lockNode then
                lockNode:playLockAction("switch", false, function (  )
                end)
            end
        end
    end

    self:levelPerformWithDelay((39)/30, function()
        if func() then
            func()
        end
    end)
end

function CodeGameScreenKittysCatchMachine:IsHaveLockScatter()
    local ret = false

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if node and node.p_symbolType == self.SYMBOL_SCATTER_1 then
                ret = true
            end
        end 
    end
    --锁定上的change动画
    for i, v in pairs(self.m_baseScatterLockNodes) do
        if v then
            local lockNode = v:getChildByTag(1)
            if lockNode then
                ret = true
            end
        end
    end

    return ret
end

-- 改变背景动画等
function CodeGameScreenKittysCatchMachine:levelFreeSpinEffectChange()

end

--改变背景动画等
function CodeGameScreenKittysCatchMachine:levelFreeSpinOverChangeEffect()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        self.m_playMoveSound = false
    end
end

function CodeGameScreenKittysCatchMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenKittysCatchMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, true)

            local node=view:findChild("m_lb_num")
            view:updateLabelSize({label=node,sx=1,sy=1},231)

            local catSpine = util_spineCreate("KittysCatch_yugao", true, true)
            view:findChild("juese"):addChild(catSpine)
            util_spinePlay(catSpine, "start", false)
            local spineEndCallFunc = function()
                util_spinePlay(catSpine, "idle", true)
            end
            util_spineEndCallFunc(catSpine, "start", spineEndCallFunc)

            gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_FreeGameMore_auto.mp3")
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showTrans(function ()
                    
                    local triggerFree = function ()
                        self.m_isTriggerStartFree = true

                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                    if self:IsHaveLockScatter() then
                        self:scatterChangeToWild(function ()
                            triggerFree()
                        end)
                    else
                        triggerFree()
                    end
                    
                end, function ()
                    self:changeBg("free", true)

                    --猫渐隐出现后播摇铃铛
                    self:levelPerformWithDelay(30/30, function()
                        self.m_catAnimIsPlay = true
                        gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_bigCat_anim.mp3")
                        util_spinePlay(self.m_catHead, "actionframe3", false)
                        local spineEndCallFunc = function()
                            self:playCatHeadAnim()
                            self.m_catAnimIsPlay = false
                        end
                        util_spineEndCallFunc(self.m_catHead, "actionframe3", spineEndCallFunc)
                        
                    end)
                    
                end, true)     
            end)

            local node=view:findChild("m_lb_num")
            view:updateLabelSize({label=node,sx=1,sy=1},231)

            local catSpine = util_spineCreate("KittysCatch_yugao", true, true)
            view:findChild("juese"):addChild(catSpine)
            util_spinePlay(catSpine, "start", false)
            local spineEndCallFunc = function()
                util_spinePlay(catSpine, "idle", true)
            end
            util_spineEndCallFunc(catSpine, "start", spineEndCallFunc)
            

            gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_FreeGameStart_Start.mp3")
            view:setBtnClickFunc(function (  )
                self:levelPerformWithDelay(15/60, function()
                    gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_FreeGameStart_End.mp3")
                end)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenKittysCatchMachine:showFreeSpinOverView()

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            self:clearWinLineEffect()
            self:showTrans(function ()
                self:checkFishTankMove()
                self:triggerFreeSpinOverCallFun()

            end, function (  )
                self:changeBg("base", true)

                --还原成锁定下的小块
                self:fsResetUnderLockWildSymbol()
                --更新还原base下锁定块
                self:updateBaseLockNodeOfComeIn()

                self:scatterLockNodeFadeIn()
                self:wildOverLockNode()
                self:levelPerformWithDelay(10/30, function()
                    self:clearLockNode(false)
                end)
            end, false)
        
    end)
    gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_FreeGameOver_Start.mp3")
    view:setBtnClickFunc(function (  )
        self:levelPerformWithDelay(15/60, function()
            gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_FreeGameOver_End.mp3")
        end)
        
    end)
    self:hideLockNode(false, false) --显示锁定wild
end

-- 重写
function CodeGameScreenKittysCatchMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    
    if self.m_runSpinResultData.p_fsWinCoins == 0 then
        return self:showDialog("FreeSpinOver_1", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        local dialog = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
        local node=dialog:findChild("m_lb_coins")
        dialog:updateLabelSize({label=node,sx=1,sy=1},671)
        node=dialog:findChild("m_lb_num")
        dialog:updateLabelSize({label=node,sx=1,sy=1},56)
        return dialog
    end
end

--过场
function CodeGameScreenKittysCatchMachine:showTrans(callBack1, callBack2, isStart)
    local animName = "guochang"
    local time1 = 90
    local time2 = 80
    if isStart then
        gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_freeGuoChang_show.mp3")
    else
        gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_freeGuoChang_end.mp3")
        animName = "guochang2"
        time1 = 70
        time2 = 60
    end

    self.m_maskTrans:setVisible(true)
    self.m_maskTrans:runCsbAction("start", false, function ()
        self.m_maskTrans:runCsbAction("idle", false)
    end)

    self:levelPerformWithDelay(time2/30, function()
        self.m_maskTrans:runCsbAction("over", false, function ()
            self.m_maskTrans:setVisible(false)
        end)
    end)
    
    self.m_trans:setVisible(true)
    util_spinePlay(self.m_trans, animName, false)
    util_spineEndCallFunc(self.m_trans, animName, function()
        self.m_trans:setVisible(false)
    end)

    self:levelPerformWithDelay(time1/30, function()
        if callBack1 then 
            callBack1()
        end
    end)

    self:levelPerformWithDelay((time2 - 15)/30, function()
        if callBack2 then 
            callBack2()
        end
    end)
end

function CodeGameScreenKittysCatchMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil 
    end
    return false -- 用作延时点击spin调用
end

function CodeGameScreenKittysCatchMachine:createSelfEffect(_type)
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = _type
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = _type
end

function CodeGameScreenKittysCatchMachine:addSelfEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
    else
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata and selfdata.bonusLines then
            if #selfdata.bonusLines > 0 then
                self:createSelfEffect(self.BONUS_EAT_FISH_EFFECT)
            end
        end
    end       
end

function CodeGameScreenKittysCatchMachine:MachineRule_playSelfEffect(effectData)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

    else
        if effectData.p_selfEffectType == self.BONUS_EAT_FISH_EFFECT then
            self:resetFishTankMove()    --还原鱼缸

            self:levelPerformWithDelay(math.max(0, self.m_eatFishTriggerDelay), function()    --延迟个落地动画的时间
                self:playBonusTrigger(function()
                    self:playBonusEatFishEffect(effectData)
                end)
                self:fishTankUp()

                gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_cat_eat_fish.mp3")
            end)
        end
    end
    
    return true
end

function CodeGameScreenKittysCatchMachine:checkFishTankMove(_isDelayWithJump)
    -- if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
    -- else
        --记录更新
        local nums = self:getFishTankNums()
        self:addFishTankMove(nums)
        if _isDelayWithJump then
            local jumpTime = self.m_bottomUI:getCoinsShowTimes(self.m_iOnceSpinLastWin)
            self:fishTankMoveWithDelay(jumpTime, function()
                self:playFishTankMove()
            end)
        else
            self:playFishTankMove()
        end
    -- end
end

function CodeGameScreenKittysCatchMachine:addFishTankMove(_scoreList)
    if self.m_fishTankMoveList then
        table.insert(self.m_fishTankMoveList, _scoreList)
        if #self.m_fishTankMoveList > 2 then
            table.remove(self.m_fishTankMoveList, 1)
        end
    end
end

function CodeGameScreenKittysCatchMachine:playFishTankMove()
    if not self.m_fishTankMoveList then
        return
    end
    if #self.m_fishTankMoveList <= 0 then
        return
    end
    if self.m_isPlayFishTankMove then
        self.m_playFishTankMoveTimes = self.m_playFishTankMoveTimes + 1
        return
    end
    self.m_isPlayFishTankMove = true

    local moveNums = self.m_fishTankMoveList[1]
    table.remove(self.m_fishTankMoveList, 1)

    local newFishTank = self:createFishTank(1, 3000 - 10)
    self.m_lastFishTank = self.m_fishTanks[5]
    self.m_lastFishTank:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 3000 - 10)
    

    for i=5,1,-1 do
        if i == 1 then
            self.m_fishTanks[i] = newFishTank
        else
            self.m_fishTanks[i] = self.m_fishTanks[i - 1]
        end
    end

    self:setFishTankNum(moveNums)

    for i=2,5 do
        self.m_fishTanks[i]:runCsbAction("chuandi", false, function (  )
            self.m_fishTanks[i]:runCsbAction("idle1", true)
        end)
    end

    self:fishTankMoveWithDelay(30/60, function()
        if self.m_playMoveSound then
            gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_fishtank_move.mp3")
        else
            self.m_playMoveSound = true
        end   

        for i=1,5 do
            if i == 1 then
                self.m_fishTanks[i]:runCsbAction("start", false, function (  )
            
                end)
                self.m_fishTanks[i]:playFishTankAnim("start", false, function()
                    self.m_fishTanks[i]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 3000 + 1)
                    self.m_fishTanks[i]:playFishTankAnim("idleframe", true)
                end)
            else
                self.m_fishTanks[i]:setPosition(self.m_fishTankPos[i - 1])
                local endPos = self.m_fishTankPos[i]
        
                local actLsit = {}
                actLsit[#actLsit + 1] = cc.MoveTo:create(40/60, endPos)
                actLsit[#actLsit + 1] = cc.CallFunc:create( function()
                    
                end)
                self.m_fishTanks[i]:runAction(cc.Sequence:create(actLsit))
                self.m_fishTanks[i]:playFishTankAnim("idleframe2", false, function()
                    self.m_fishTanks[i]:playFishTankAnim("idleframe", true)
                end) 
            end
               
        end

        if self.m_lastFishTank and not tolua.isnull(self.m_lastFishTank) then
            self.m_lastFishTank:runCsbAction("over", false, function (  )
            
            end)
            self.m_lastFishTank:playFishTankAnim("over", false, function()
    
            end)
        end
        
        self:fishTankMoveWithDelay(1, function()
            if self.m_lastFishTank and not tolua.isnull(self.m_lastFishTank) then
                self.m_lastFishTank:removeFromParent()
                self.m_lastFishTank = nil
            end
        end)
    end)

    self:fishTankMoveWithDelay(55/60, function()
        for i=2,5 do
            self.m_fishTanks[i].m_yugang2:setVisible(true)
            self.m_fishTanks[i].m_yugang2:runCsbAction("chuandifankui", false, function (  )
                self.m_fishTanks[i].m_yugang2:setVisible(false)
            end)
        end
    end)

    self:fishTankMoveWithDelay((20 + 60)/30, function()
        self.m_isPlayFishTankMove = false
        if self.m_playFishTankMoveTimes > 0 then
            self.m_playFishTankMoveTimes = self.m_playFishTankMoveTimes - 1
            self:playFishTankMove()
        end
    end)
end

function CodeGameScreenKittysCatchMachine:fishTankMoveWithDelay(_time, _fun)
    if not self.m_delayNodeForMove then
        self.m_delayNodeForMove = cc.Node:create()
        self:addChild(self.m_delayNodeForMove)
    end
    performWithDelay(self.m_delayNodeForMove,function()
        _fun()
    end, _time)
end

function CodeGameScreenKittysCatchMachine:resetFishTankMove()
    if not self.m_isPlayFishTankMove then
        return
    end

    for i=1,5 do
        self.m_fishTanks[i]:stopAllActions()
        self.m_fishTanks[i]:playFishTankAnim("idleframe", true)
        self.m_fishTanks[i]:setPosition(self.m_fishTankPos[i])
        self.m_fishTanks[i]:findChild("Node_1"):setScale(1)
        self.m_fishTanks[i].m_yugang3:setVisible(false)
        self.m_fishTanks[i]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 3000 + i)
    end

    if self.m_lastFishTank and not tolua.isnull(self.m_lastFishTank) then
        self.m_lastFishTank:removeFromParent()
        self.m_lastFishTank = nil
    end

    if #self.m_fishTankMoveList > 0 then
        local lastNums = self.m_fishTankMoveList[#self.m_fishTankMoveList]
        self:setFishTankNum(lastNums)

        self.m_fishTankMoveList = {}
    end

    self.m_isPlayFishTankMove = false
    self.m_playFishTankMoveTimes = 0

    if self.m_delayNodeForMove then
        -- self.m_delayNodeForMove:stopAllActions()
        self.m_delayNodeForMove:removeFromParent()
        self.m_delayNodeForMove = nil
    end
    
end

--bonus 吃鱼效果
function CodeGameScreenKittysCatchMachine:playBonusEatFishEffect(effectData)

    local singleDelay = 35/30 + 0.8
    local oldTotalLastWinCoin = globalData.slotRunData.lastWinCoin

    local delayFunc = function (_curBonusWin, _onceBonusWin, _isLast, _bonusMulti)

        --吃鱼动画
        local multiData = _bonusMulti
        local pos = multiData[1]
        local multi = multiData[2]
        local fixPos = self:getRowAndColByPos(pos)
        self.m_fishTanks[fixPos.iY]:fishJump(fixPos.iX, function ()
            
        end, function()
            if _isLast then
                gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_fish_enter_water.mp3")
            end
        end)
        if _isLast then
            -- gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_cat_eat_fish.mp3")
        end

        self.m_fishTanks[fixPos.iY]:setUpEffect()

        local bonusSymbol =  self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if bonusSymbol then
            local anim = "feature_actionframe1"
            if fixPos.iX == 1 then
                anim = "feature_actionframe4"
            elseif fixPos.iX == 2 then
                anim = "feature_actionframe3"
            elseif fixPos.iX == 3 then
                anim = "feature_actionframe2"
            elseif fixPos.iX == 4 then
                anim = "feature_actionframe1"
            end
            bonusSymbol:runAnim(anim, false, function()
                bonusSymbol:runAnim("idleframe", true)
            end)
        end

        self:levelPerformWithDelay(35/30, function() --吃到鱼时间点
            self.m_fishTanks[fixPos.iY]:runCsbAction("fankui", false, function (  )
                self.m_fishTanks[fixPos.iY]:runCsbAction("idle1", true)
            end)
            if _isLast then
                gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_particle_beginFly.mp3")
            end
            
            self:createParticleFly(0.7,self.m_fishTanks[fixPos.iY],function (  )
                self.m_fishTanks[fixPos.iY]:resetUpEffect()
            end, fixPos.iY)

            if _isLast then
                
                self:levelPerformWithDelay(0.8, function()
                    gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_particle_entertoWin.mp3")
                    --吃鱼赢钱
                    globalData.slotRunData.lastWinCoin = 0
        
                    local isNotifyTop = false
                    local winLines = self.m_reelResultLines
                    if winLines and #winLines > 0 then
                    else
                        isNotifyTop = true
                    end
        
                    self.m_bottomUI:setCoinsShowTimesIsFixed(true)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {_curBonusWin, false, false})
                    if isNotifyTop then
                        self.m_bottomUI:notifyTopWinCoin()
                    end
                    self.m_bottomUI:setCoinsShowTimesIsFixed(false)
                    globalData.slotRunData.lastWinCoin = oldTotalLastWinCoin


                    --还原鱼缸提层
                    for posY, value in pairs(self.m_upFishTankPosY) do
                        -- local pos = util_convertToNodeSpace(self.m_fishTanks[posY], self.m_eatFishNode)
                        local node_pos = util_convertToNodeSpace(self:findChild("Node_yugang_" .. posY),  self.m_clipParent)
                        util_changeNodeParent(self.m_clipParent, self.m_fishTanks[posY], SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 3000 + posY)
                        self.m_fishTanks[posY]:setPosition(cc.p(node_pos))
                    end

                    self:specialNodeUpReset()

                    --next
                    effectData.p_isPlay = true
                    self:playGameEffect()

                    local winLines = self.m_reelResultLines
                    if #winLines > 0 then
                    else
                        if self.m_runSpinResultData.p_features[2] == 1 then --有触发 不播鱼缸move
                        else
                            if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
                                self.m_playMoveSound = false
                            end
                            
                            self:checkFishTankMove(false)
                        end
                    end




                end)

                --黑遮去掉
                self.m_maskEatFish:runCsbAction("over", false, function (  )
                    self.m_maskEatFish:setVisible(false)
                end)
            end
        end)
    end
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.bonusLines then
        if #selfdata.bonusLines ~= #selfdata.bonusMulti then
            release_print("bonusLines num not equal bonusMulti error!!!")
        end
        if #selfdata.bonusLines > 0 then
            local curBonusWin = 0
            for i=1,#selfdata.bonusLines do
                local isLast = i == #selfdata.bonusLines
                curBonusWin = curBonusWin + selfdata.bonusLines[i].amount
                delayFunc(curBonusWin, selfdata.bonusLines[i].amount, isLast, selfdata.bonusMulti[i])
            end
        end
    end

    -- self:levelPerformWithDelay(singleDelay, function()

    --     --还原鱼缸提层
    --     for posY, value in pairs(self.m_upFishTankPosY) do
    --         -- local pos = util_convertToNodeSpace(self.m_fishTanks[posY], self.m_eatFishNode)
    --         local node_pos = util_convertToNodeSpace(self:findChild("Node_yugang_" .. posY),  self.m_clipParent)
    --         util_changeNodeParent(self.m_clipParent, self.m_fishTanks[posY], SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 3000 + posY)
    --         self.m_fishTanks[posY]:setPosition(cc.p(node_pos))
    --     end

    --     self:specialNodeUpReset()

    --     --next
    --     effectData.p_isPlay = true
    --     self:playGameEffect()

    --     local winLines = self.m_reelResultLines
    --     if #winLines > 0 then
    --     else
    --         if self.m_runSpinResultData.p_features[2] == 1 then --有触发 不播鱼缸move
    --         else
    --             if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
    --                 self.m_playMoveSound = false
    --             end
                
    --             self:checkFishTankMove(false)
    --         end
    --     end
            
    -- end)

end

--bonus触发动画
function CodeGameScreenKittysCatchMachine:playBonusTrigger(_func)
    self.m_symbolUpZOrderArray = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if symbolNode then
                if symbolNode.p_symbolType == self.SYMBOL_BONUS then
                    --提层
                    table.insert(self.m_symbolUpZOrderArray, symbolNode)
                    symbolNode:upToParent(self.m_eatFishNode, true)
                    
                    symbolNode:runAnim("actionframe2", false)
                end
            end
        end
    end

    self:levelPerformWithDelay(35/30, function()
        if _func then
            _func()
        end
    end)
end

--鱼缸提层+遮罩
function CodeGameScreenKittysCatchMachine:fishTankUp()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_upFishTankPosY = {}
    if selfdata and selfdata.bonusMulti then
        for i=1,#selfdata.bonusMulti do
            local multiData = selfdata.bonusMulti[i]
            local pos = multiData[1]
            local fixPos = self:getRowAndColByPos(pos)
            self.m_upFishTankPosY[fixPos.iY] = 1
        end
    end
    for posY, value in pairs(self.m_upFishTankPosY) do
        local pos = util_convertToNodeSpace(self.m_fishTanks[posY], self.m_eatFishNode)
        util_changeNodeParent(self.m_eatFishNode, self.m_fishTanks[posY], 100000)
        self.m_fishTanks[posY]:setPosition(pos)
    end
        
    self.m_maskEatFish:setVisible(true)
    self.m_maskEatFish:runCsbAction("start", false, function (  )
        self.m_maskEatFish:runCsbAction("idle", true)
    end)
    
end

function CodeGameScreenKittysCatchMachine:getBezier(pos, endPos, _isLeft)
    -- local bezier = {}
    -- local num1 = 230
    -- local num2 = 180
    -- local num3 = 140
    -- local num4 = 310
    -- if _isLeft then
    --     bezier[1] = cc.p(pos.x - num1, pos.y - num2)
    -- else
    --     bezier[1] = cc.p(pos.x + num1, pos.y - num2)
    -- end
    -- if _isLeft then
    --     bezier[2] = cc.p(endPos.x + num3, endPos.y + num4)
    -- else
    --     bezier[2] = cc.p(endPos.x - num3, endPos.y + num4)
    -- end
    
    -- bezier[3] = endPos


    local bezier = {}
    local num1 = 170
    local num2 = 50
    local num3 = 170
    local num4 = 410
    if _isLeft then
        bezier[1] = cc.p(pos.x - num1, pos.y - num2)
    else
        bezier[1] = cc.p(pos.x + num1, pos.y - num2)
    end
    if _isLeft then
        bezier[2] = cc.p(pos.x - num3, pos.y - num4)
    else
        bezier[2] = cc.p(pos.x + num3, pos.y - num4)
    end
    
    bezier[3] = endPos
    
    return bezier
end

-- 创建飞行粒子
function CodeGameScreenKittysCatchMachine:createParticleFly(time,currNode,func, col)

    local fly = util_createAnimation("KittysCatch_yugang_tuowei.csb")
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    fly:setPosition(cc.p(util_getConvertNodePos(currNode:findChild("shuzi"),fly)))
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local startPos = cc.p(fly:getPosition())
    local endPos = util_convertToNodeSpace(endNode,self)
    local centerPos = cc.p((endPos.x + startPos.x) / 2, (endPos.y + startPos.y) / 2)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        fly:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        fly:findChild("Particle_1"):resetSystem()
        fly:findChild("Particle_1_0"):setDuration(-1)     --设置拖尾时间(生命周期)
        fly:findChild("Particle_1_0"):setPositionType(0)   --设置可以拖尾
        fly:findChild("Particle_1_0"):resetSystem()
    end)
    local dir = col <= 3
    local bezier = self:getBezier(startPos, endPos, dir)
    animation[#animation + 1] = cc.EaseIn:create(cc.BezierTo:create(time, bezier), 2)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        fly:findChild("Particle_1_0"):stopSystem()--移动结束后将拖尾停掉
        self:playCoinWinEffectUI()
        if func then
            func()
        end
    end)
    animation[#animation + 1] = cc.DelayTime:create(0.4)
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))
end


--重写
function CodeGameScreenKittysCatchMachine:getFixSymbol(iCol, iRow, iTag)
    if not iTag then
        iTag = SYMBOL_NODE_TAG
    end
    local fixSp = nil
    fixSp = self.m_eatFishNode:getChildByTag(self:getNodeTag(iCol, iRow, iTag)) --改
    if fixSp == nil then
        fixSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
        if fixSp == nil and (iCol >= 1 and iCol <= self.m_iReelColumnNum) then
            fixSp = self.m_slotParents[iCol].slotParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
            if fixSp == nil then
                local slotParentBig = self.m_slotParents[iCol].slotParentBig
                if slotParentBig then
                    fixSp = slotParentBig:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
                end
            end
        end
    end
    return fixSp
end

--重写
--小块
function CodeGameScreenKittysCatchMachine:getBaseReelGridNode()
    return "CodeKittysCatchSrc.KittysCatchSlotsNode"
end

-- 提层reset
function CodeGameScreenKittysCatchMachine:specialNodeUpReset()
    if not self.m_symbolUpZOrderArray then
        return
    end
    for i, symbolNode in ipairs(self.m_symbolUpZOrderArray) do
        symbolNode:downToBase(self.m_clipParent)
    end
    self.m_symbolUpZOrderArray = {}
end

--改变小块
function CodeGameScreenKittysCatchMachine:changeOneSymbol(_symbolNode, _symbolType)
    if _symbolNode.p_symbolImage ~= nil and _symbolNode.p_symbolImage:getParent() ~= nil then
        _symbolNode.p_symbolImage:removeFromParent()
    end
    _symbolNode.p_symbolImage = nil
    _symbolNode.m_ccbName = ""

    local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
    _symbolNode:changeCCBByName(ccbName, _symbolType)
    _symbolNode:changeSymbolImageByName(ccbName)
    _symbolNode:resetReelStatus()
    
    local posIdx = self:getPosReelIdx(_symbolNode.p_rowIndex, _symbolNode.p_cloumnIndex)
    local order = self:getBounsScatterDataZorder(_symbolType) + posIdx
    _symbolNode:setLocalZOrder(order)
    _symbolNode.p_showOrder = order

    _symbolNode:setLineAnimName("actionframe")
    _symbolNode:setIdleAnimName("idleframe")
end

--连线
--固定的替换到棋盘
function CodeGameScreenKittysCatchMachine:fsLockWildReplaceReelGrid()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildIconsPos = fsExtraData.stickWild or {}

    for i = 1, #wildIconsPos do
        local posIdx = wildIconsPos[i]
        if self:isPosInLine(posIdx) then
            local pos = self:getRowAndColByPos(posIdx)
            local row = pos.iX
            local col = pos.iY
            local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
            if targSp then
                self.m_fsReplaceWildPosSymbol[posIdx] = targSp.p_symbolType
                if targSp.p_symbolType == self.SYMBOL_SCATTER_2 then
                    self:changeOneSymbol(targSp, self.SYMBOL_SCATTER_2)
                else
                    self:changeOneSymbol(targSp, self.SYMBOL_WILD_2)
                end
            end
        end
    end
end

--连线
--还原替换的
function CodeGameScreenKittysCatchMachine:fsResetReelGrid()
    for posIdx, symbolType in pairs(self.m_fsReplaceWildPosSymbol) do
        local pos = self:getRowAndColByPos(posIdx)
        local row = pos.iX
        local col = pos.iY
        local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
        if targSp then
            self:changeOneSymbol(targSp, symbolType)
        end
    end
    self.m_fsReplaceWildPosSymbol = {}
end

--重写
function CodeGameScreenKittysCatchMachine:showEffect_LineFrame(effectData)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:fsLockWildReplaceReelGrid()
        self:hideLockNode(false, true, true)
    end

    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    --改
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
    else
        if self.m_runSpinResultData.p_features[2] == 1 then
        else
            self:checkFishTankMove(false)
        end
    end
    

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        local time = 0.5
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            time
        )
    else
        -- free下连线后不让立即点击 原有触发freemore后不用处理
        if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_features[2] ~= 1 then
            self:levelPerformWithDelay(0.2,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    return true
end

function CodeGameScreenKittysCatchMachine:getGameEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType then
            return self.m_gameEffects[i]
        end
    end

    return nil
end

--记录free锁定下原有的小块类型
function CodeGameScreenKittysCatchMachine:fsRecordUnderLockWildSymbol()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildIconsPos = fsExtraData.stickWild or {}

    self.m_fsRecordUnderWildPosSymbol = {}
    for i = 1, #wildIconsPos do
        local posIdx = wildIconsPos[i]
        local pos = self:getRowAndColByPos(posIdx)
        local row = pos.iX
        local col = pos.iY
        local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
        if targSp then
            self.m_fsRecordUnderWildPosSymbol[posIdx] = targSp.p_symbolType
        end
    end

    local k = 1
end
--重置回reel
function CodeGameScreenKittysCatchMachine:fsResetUnderLockWildSymbol()

    for posIdx, symbolType in pairs(self.m_fsRecordUnderWildPosSymbol) do
        local pos = self:getRowAndColByPos(posIdx)
        local row = pos.iX
        local col = pos.iY
        local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
        if targSp then
            self:changeOneSymbol(targSp, symbolType)
        end
    end
    self.m_fsRecordUnderWildPosSymbol = {}
end

function CodeGameScreenKittysCatchMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenKittysCatchMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenKittysCatchMachine:slotReelDown( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --记录原有块
        self:fsRecordUnderLockWildSymbol()
    end

    if self.m_isLongRun then
        --scatter播期待动画
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                local _slotNode = self:getFixSymbol(iCol,iRow)
                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_SCATTER_1 or _slotNode.p_symbolType == self.SYMBOL_SCATTER_2 then
                    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_SCATTER_1 then
                        _slotNode:runAnim("idleframe", true)
                    elseif _slotNode.p_symbolType == self.SYMBOL_SCATTER_2 then
                        _slotNode:runAnim("idleframe2", true)
                    end
    
                    --期待本节点还原
                    local posIdx = self:getPosReelIdx(iRow, iCol)
                    _slotNode:setLocalZOrder(_slotNode.p_showOrder)
                end
            end
        end

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            for k,v in pairs(self.m_baseScatterLockNodes) do
                if v then
                    local lockNode = v:getChildByTag(1)
                    if lockNode then
                        lockNode:playLockAction("idleframe", true)

                        --期待本节点还原
                        v:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + k)
                    end
                end
            end
        end
        

        self.m_isLongRun = false

        if self.m_longRunSoundId then
            gLobalSoundManager:stopAudio(self.m_longRunSoundId)
            self.m_longRunSoundId = nil
        end
        
    end

    self:addOrRemoveScatter()

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenKittysCatchMachine.super.slotReelDown(self)

end

--[[
    停轮之后操作固定scatter 添加或者移除
]]
function CodeGameScreenKittysCatchMachine:addOrRemoveScatter( )
    if not self.m_bProduceSlots_InFreeSpin then
        --锁定scatter
        if self:checkIsAddLockScatter() then
            self:addBaseLockNode() 
        end
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local posIdx = self:getPosReelIdx(iRow, iCol)
            if self.m_baseScatterLockNodes[posIdx] then
                local lockNode = self.m_baseScatterLockNodes[posIdx]:getChildByTag(1)
                if lockNode then
                    local isSpecialSc, isLast, lastNum = self:isSpecialScatter(iCol, iRow)
                    if isSpecialSc and isLast then
                        local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
                        if symbolNode then
                            self:changeOneSymbol(symbolNode, self.SYMBOL_SCATTER_1)
                            self.m_baseScatterLockNodes[posIdx]:removeAllChildren()
                            self:setSlotsNodeCornerNum(symbolNode, 1)
                        end
                    end
                end
            end
        end
    end

    -- 滚轮停止的时候 多加个判断 如果本地锁定scatter和服务器不一致 以服务器为准 删除本地的
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        for _pos, _node in pairs(self.m_baseScatterLockNodes) do
            if _node then
                local lockNode = _node:getChildByTag(1)
                if lockNode then
                    local data = self:getStickScatterData()
                    local isRemove = true
                    for index = 1, #data do
                        if data[index][1] == _pos then
                            isRemove = false
                        end
                    end
                    if isRemove then
                        _node:removeAllChildren()
                    end
                end
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--重写
function CodeGameScreenKittysCatchMachine:initGameStatusData(gameData)
    self.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.betData then
        self:updateData(gameData.gameConfig.extra.betData, nil)
    end

    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.initMulti then
        self:updateData(nil, gameData.gameConfig.extra.initMulti)
    end
end

--更新数据
function CodeGameScreenKittysCatchMachine:updateData(_betData, _initMulti)
    if _betData then
        self.m_allBetData = _betData
    end
    if _initMulti then
        self.m_initMulti = _initMulti
    end
end

--获取鱼缸数值数组
function CodeGameScreenKittysCatchMachine:getFishTankNums()
    local ret = {}
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local totalBetStr = tostring(toLongNumber(totalBet))
    if self.m_allBetData and self.m_allBetData[totalBetStr] then
        for i = 1, #self.m_allBetData[totalBetStr].upReel do
            table.insert(ret, self.m_allBetData[totalBetStr].upReel[i])
        end
    else
        if self.m_initMulti then
            for i = 1, 5 do
                table.insert(ret, totalBet * tonumber(self.m_initMulti[i]))
            end
        else
            release_print("KittysCatch m_initMulti Error!!!")
            for i = 1, 5 do
                table.insert(ret, 10000)
            end
        end
    end
    return ret
end

--设置鱼缸数值
function CodeGameScreenKittysCatchMachine:setFishTankNum(_nums)
    local tempNums
    if _nums and #_nums == 5 then
        tempNums = _nums
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()

    local nums = tempNums or self:getFishTankNums()
    for i = 1, #self.m_fishTanks do
        self.m_fishTanks[i]:setString(util_formatCoins(nums[i],3))

        local winRatio = nums[i] / lTatolBetNum
        if winRatio >= self.m_BigWinLimitRate then
            self.m_fishTanks[i]:showBigNumEffect(true)
        else
            self.m_fishTanks[i]:showBigNumEffect(false)
        end
    end

end

--获取固定scatter数据
function CodeGameScreenKittysCatchMachine:getStickScatterData()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local totalBetStr = tostring(toLongNumber(totalBet))
    local ret = {}
    if self.m_allBetData and self.m_allBetData[totalBetStr] then
        for i = 1, #self.m_allBetData[totalBetStr].stickSc do
            table.insert(ret, self.m_allBetData[totalBetStr].stickSc[i])
        end
    end
    return ret
end

function CodeGameScreenKittysCatchMachine:checkIsAddLockScatter()
    local data = self:getStickScatterData()
    for i = 1, #data do
        if data[i][2] == 3 then
            return true
        end
    end
    return false
end

--适配
-- function CodeGameScreenKittysCatchMachine:scaleMainLayer()
--     local uiW, uiH = self.m_topUI:getUISize()
--     local uiBW, uiBH = self.m_bottomUI:getUISize()

--     local mainHeight = display.height - uiH - uiBH
--     local mainPosY = (uiBH - uiH - 30) / 2
--     local mainPosX = 0

--     local winSize = display.size
--     local mainScale = 1

--     local hScale = mainHeight / self:getReelHeight()
--     local wScale = winSize.width / self:getReelWidth()
--     if hScale < wScale then
--         mainScale = hScale
--     else
--         mainScale = wScale
--         self.m_isPadScale = true
--     end

--     if winSize.width < 1370 then --过宽设备效果图以高适配
--         mainScale = mainHeight / 640
--     end

--     -- mainScale = 0.9
--     util_csbScale(self.m_machineNode, mainScale)
--     self.m_machineRootScale = mainScale
--     self.m_machineNode:setPositionY(mainPosY)
--     self.m_machineNode:setPositionX(mainPosX)
-- end

function CodeGameScreenKittysCatchMachine:scaleMainLayer()
    CodeGameScreenKittysCatchMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.98
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.94 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.93 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio >= 768/1370 then
        local mainScale = 0.96 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1370 and ratio >= 768/1530 then
        local mainScale = 0.96 - 0.05*((ratio-768/1530)/(768/1370 - 768/1530))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1530 and ratio >= 768/1660 then
        local mainScale = 0.96 - 0.05*((ratio-768/1660)/(768/1530 - 768/1660))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

-- 背景切换
function CodeGameScreenKittysCatchMachine:changeBg(showType, isPlayAni)
    if self.m_showType and showType == self.m_showType then
        return 
    end
    self.m_showType = showType
    local time = 1
    if isPlayAni then
        
        if showType == "free" then
            self.m_catHead:setVisible(true)
            self.m_catHead:setOpacity(0)
            self:playCatHeadAnim(true)
            util_playFadeInAction(self.m_catHead, time, function (  )
            end)

            for i = 1, 5 do
                util_playFadeOutAction(self.m_fishTanks[i], time, function (  )
                    self.m_fishTanks[i]:setVisible(false)
                    self.m_fishTanks[i]:setOpacity(255)
                end)

                if self.m_fishTanks[i].m_isMultiBigNum then
                    self.m_fishTanks[i].m_bigNumEffect2:setVisible(false)
                end
            end

            util_playFadeOutAction(self.m_baseEdge, time, function (  )
                self.m_baseEdge:setVisible(false)
                self.m_baseEdge:setOpacity(255)
            end)

            self.m_freeEdge:setVisible(true)
            self.m_freeEdge:setOpacity(0)
            util_playFadeInAction(self.m_freeEdge, time, function (  )
                
            end)

            self.m_freeBarView:setVisible(true)
            self.m_freeBarView:setOpacity(0)
            util_playFadeInAction(self.m_freeBarView, time, function (  )
                
            end)

            
        else
            util_playFadeOutAction(self.m_catHead, time, function (  )
                self.m_catHead:setVisible(false)
                self.m_catHead:setOpacity(255)
            end)

            for i = 1, 5 do
                self.m_fishTanks[i]:setVisible(true)
                self.m_fishTanks[i]:setOpacity(0)
                util_playFadeInAction(self.m_fishTanks[i], time, function (  )
                    
                    if self.m_fishTanks[i].m_isMultiBigNum then
                        self.m_fishTanks[i].m_bigNumEffect2:setVisible(true)
                    end
                end)

                
            end

            self.m_baseEdge:setVisible(true)
            self.m_baseEdge:setOpacity(0)
            util_playFadeInAction(self.m_baseEdge, time, function (  )
                
            end)

            util_playFadeOutAction(self.m_freeEdge, time, function (  )
                self.m_freeEdge:setVisible(false)
                self.m_freeEdge:setOpacity(255)
            end)

            util_playFadeOutAction(self.m_freeBarView, time, function (  )
                self.m_freeBarView:setVisible(false)
                self.m_freeBarView:setOpacity(255)
            end)
        end
        
    else
        self.m_catHead:setVisible(showType == "free")
        self:playCatHeadAnim(true)
        
        for i = 1, 5 do
            self.m_fishTanks[i]:setVisible(showType == "base")
        end
        self.m_baseEdge:setVisible(showType == "base")
        self.m_freeEdge:setVisible(showType == "free")

        self.m_freeBarView:setVisible(showType == "free")

        self.m_gameBg:findChild("free"):setVisible(showType == "free")
        self.m_gameBg2:findChild("bace"):setVisible(showType == "base")
    end

    self.m_baseReelBg:setVisible(showType == "base")
    self.m_freeReelBg:setVisible(showType == "free")


    self.m_gameBg2:findChild("bace"):setVisible(false)
    self.m_gameBg:findChild("free"):setVisible(false)

    self.m_gameBg2:findChild("free"):setVisible(false)
    self.m_gameBg:findChild("bace"):setVisible(false)
    if showType == "free" then
        self.m_gameBg2:runCsbAction("idle", true)
        self.m_gameBg:runCsbAction("switch", false, function()
            self.m_gameBg:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BG)
            self.m_gameBg2:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
        end)
    else
        self.m_gameBg:runCsbAction("idle", true)
        self.m_gameBg2:runCsbAction("switch", false, function()
            self.m_gameBg2:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BG)
            self.m_gameBg:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
        end)
    end

    self.m_freeBarView:changeFreeSpinByCount()
end

--重写
function CodeGameScreenKittysCatchMachine:initMachineBg()
    CodeGameScreenKittysCatchMachine.super.initMachineBg(self)

    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    local gameBg2 = util_createView("views.gameviews.GameMachineBG")
    if bgNode then
        bgNode:addChild(gameBg2, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    else
        self:addChild(gameBg2, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg2:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg2 = gameBg2

    self.m_gameBg:findChild("base_bg"):setVisible(true)
    self.m_gameBg:findChild("free_bg"):setVisible(false)

    self.m_gameBg2:findChild("base_bg"):setVisible(false)
    self.m_gameBg2:findChild("free_bg"):setVisible(true)
end

--重写
function CodeGameScreenKittysCatchMachine:operaSpinResultData(param)
    local spinData = param[2]

    self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)


    if self.m_runSpinResultData.p_features[2] == 1 then
        local currSpinMode = self:getCurrSpinMode()
        if currSpinMode == NORMAL_SPIN_MODE or currSpinMode == AUTO_SPIN_MODE then
            self.m_isPlayWinningNotice = math.random(0, 100) < 40
        end
    end
end

--重写
function CodeGameScreenKittysCatchMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    local nextFun = function()       
        --spin后更新 betData
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata and selfdata.betData then
            self:updateData(selfdata.betData)
        end
        self.m_curTotalBet = globalData.slotRunData:getCurTotalBet()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
 
    end

    if self.m_isPlayWinningNotice then
        self:preViewWin(function()
            nextFun()
        end)
    else
        nextFun()
        self:setColOneLongRunStates()
    end
end

function CodeGameScreenKittysCatchMachine:getWinCoinTime()

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_features and self.m_runSpinResultData.p_features[2] == 1 then
        return 0
    end

    --自动时  有吃鱼 去掉时间
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local isHaveBonus = false
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata and selfdata.bonusLines then
            if #selfdata.bonusLines > 0 then
                isHaveBonus = true
            end
        end

        local isHaveLine = false
        local winLines = self.m_reelResultLines
        if winLines and #winLines > 0 then
            isHaveLine = true
        end

        if isHaveBonus then
            if not isHaveLine then
                if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
                    return 0
                else
                    return 1
                end
            else
                return 0
            end
        end
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    if self.m_iOnceSpinLastWin > 0 then
        showTime = 1.5
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            showTime = 1
        end
    end

    return showTime
end

--重写
function CodeGameScreenKittysCatchMachine:beginReel()
    -- self.m_isPlaySoundCatjerky = false
    -- self.m_isPlaySoundMeow4 = false
    self.m_isLongRun = false
    self.m_isClearWinLine = true
    self.m_changeScatterSymbolByChangeBet = {}

    self.m_fishTankNumsLast =  self:getFishTankNums()
    --改
    self:specialNodeUpReset() -- need before beginReel
    --改
    self:beforeBeginReel(function()
        --锁定的order还原
        if self.m_baseScatterLockNodes then
            for k, v in pairs(self.m_baseScatterLockNodes) do
                v:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + k)
            end
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
        else
            self:playFishTankMove()
        end

        if self.m_isTriggerStartFree then
            self.m_isTriggerStartFree = false
            self:clearLockNode(true)
            self:clearLockNode(false)
            self:initFreeLockNode()
            self:hideLockNode(false, false)
        end

        CodeGameScreenKittysCatchMachine.super.beginReel(self)
        
    end)
end

function CodeGameScreenKittysCatchMachine:beforeBeginReel(_func)

    self.m_lastScatterLockData = self:getStickScatterData()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:hideLockNode(false, false)
        self:fsResetReelGrid()
        self:clearWinLineEffect()

        local isHave = self:addFreeLockNode(function()
            if _func then
                _func()
            end
        end)

        if not isHave then
            self:levelPerformWithDelay(0, function()
                if _func then
                    _func()
                end
            end)
        end

        return
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local posIdx = self:getPosReelIdx(iRow, iCol)
            if self.m_baseScatterLockNodes[posIdx] then
                local lockNode = self.m_baseScatterLockNodes[posIdx]:getChildByTag(1)
                if lockNode then
                    local isSpecialSc, isLast, lastNum = self:isSpecialScatter(iCol, iRow)
                    if isSpecialSc and not isLast then
                        lockNode:updateCornerNum(math.max(lastNum - 1, 0), true)
                    end
                end
            end
        end
    end

    self:levelPerformWithDelay(0, function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenKittysCatchMachine:isSpecialScatter(iCol, iRow)
    local data = self:getStickScatterData()
    local posIdx = self:getPosReelIdx(iRow, iCol)
    for i = 1, #data do
        if data[i][1] == posIdx and data[i][2] == 1 then
            return true, true, data[i][2]
        end
        if data[i][1] == posIdx and data[i][2] ~= 1 then
            return true, false, data[i][2]
        end
    end
    return false, false, 0
end

--延时
function CodeGameScreenKittysCatchMachine:levelPerformWithDelay(_time, _fun)
    if not self.m_waitNode then
        self.m_waitNode = cc.Node:create()
        self:addChild(self.m_waitNode)
    end
    performWithDelay(self.m_waitNode,function()
        _fun()
    end, _time)
end

--重写
function CodeGameScreenKittysCatchMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenKittysCatchMachine.super.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_SCATTER_1 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_SCATTER_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_WILD_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    end
    return order
end

--重写
function CodeGameScreenKittysCatchMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    self.setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then

                if _slotNode.p_symbolType == self.SYMBOL_BONUS then
                    local spinStage = self:getGameSpinStage()
                    if spinStage == QUICK_RUN then
                        self.m_eatFishTriggerDelay = 47/60
                    else
                        if _slotNode.p_cloumnIndex == 1 then
                            -- 59
                            -- 61
                            self.m_eatFishTriggerDelay = 2/60
                        elseif _slotNode.p_cloumnIndex == 2 then
                            -- 48
                            -- 61
                            self.m_eatFishTriggerDelay = 13/60
                        elseif _slotNode.p_cloumnIndex == 3 then
                            -- 38
                            self.m_eatFishTriggerDelay = 23/60
                        elseif _slotNode.p_cloumnIndex == 4 then
                            self.m_eatFishTriggerDelay = 33/60
                        elseif _slotNode.p_cloumnIndex == 5 then
                            self.m_eatFishTriggerDelay = 47/60
                        end
                    end
                end               

                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            end
        end
    end
end

--重写
-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenKittysCatchMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_SCATTER_1 then
        if self.m_isLongRun then
            self:playLookingForwardTo(_slotNode)
        else
            _slotNode:runAnim("idleframe", true)
        end
        
        -- if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and math.random(0, 100) < 30 and self.m_isPlaySoundCatjerky == false then
        --     self.m_isPlaySoundCatjerky = true
        --     gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_scatter_SoundCatjerky.mp3")
        -- end
    elseif _slotNode.p_symbolType == self.SYMBOL_BONUS then
        _slotNode:runAnim("idleframe", true)
        -- if not self.m_bIsBigWin and math.random(0, 100) < 30 and self.m_isPlaySoundMeow4 == false then
            -- self.m_isPlaySoundMeow4 = true
            -- gLobalSoundManager:playSound("KittysCatchSounds/music_KittysCatch_scatter_SoundMeow4.mp3")
        -- end
    elseif _slotNode.p_symbolType == self.SYMBOL_SCATTER_2 then
        if self.m_isLongRun then
            self:playLookingForwardTo(_slotNode)
        else
            _slotNode:runAnim("idleframe2", true)
        end
        
    end
end

--重写
-- 有特殊需求判断的 重写一下
function CodeGameScreenKittysCatchMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_BONUS
            or _slotNode.p_symbolType == self.SYMBOL_SCATTER_1
            or _slotNode.p_symbolType == self.SYMBOL_SCATTER_2
            then
                return true
            end
        end
    end

    return false
end

--重写
--播放提示动画
function CodeGameScreenKittysCatchMachine:playReelDownTipNode(slotNode)
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

--重写
function CodeGameScreenKittysCatchMachine:createSlotNextNode(parentData)
    if self.m_isWaitingNetworkData == true then
        -- 等待网络数据返回时， 还没开始滚动真信号，所以肯定为false 2018-12-15 18:15:51
        parentData.m_isLastSymbol = false
        self:getReelDataWithWaitingNetWork(parentData)

        --改
        local showOrder = self:getBounsScatterDataZorder(parentData.symbolType)
        parentData.order = showOrder - parentData.rowIndex
        --改
        return
    end
    parentData.lastReelIndex = parentData.lastReelIndex + 1
    local cloumnIndex = parentData.cloumnIndex
    local columnData = self.m_reelColDatas[cloumnIndex]
    local nodeCount = self.m_reelRunInfo[cloumnIndex]:getReelRunLen()
    if parentData.lastReelIndex<=nodeCount or parentData.lastReelIndex>nodeCount+columnData.p_showGridCount then
        if parentData.fillCount and parentData.fillCount>0 and parentData.lastReelIndex>=nodeCount-parentData.fillCount then
            --大信号补块
            parentData.m_isLastSymbol = false
            parentData.symbolType = self:getSymbolTypeForNetData(cloumnIndex,1)
        else
            parentData.m_isLastSymbol = false
            self:getReelDataWithWaitingNetWork(parentData)
        end
        local symbolCount = self.m_bigSymbolInfos[parentData.symbolType]
        if symbolCount then
            if parentData.fillCount then
                symbolCount = symbolCount + parentData.fillCount
            end
            if parentData.lastReelIndex + symbolCount >nodeCount then
                --假滚轴大信号覆盖到了真数据重新获取数据
                local symbolType = self:getReelSymbolType(parentData)
                local breakIndex = 0
                while self.m_bigSymbolInfos[symbolType] do
                    symbolType = self:getReelSymbolType(parentData)
                    breakIndex = breakIndex +1
                    if breakIndex>=10 then
                        --理论不会报错 预防一下
                        break
                    end
                end
                parentData.symbolType = symbolType
            end
        end
        --改
        local showOrder = self:getBounsScatterDataZorder(parentData.symbolType)
        parentData.order = showOrder - parentData.rowIndex
        --改
        return
    end
    parentData.fillCount = 0
    local columnRowNum = columnData.p_showGridCount
    parentData.rowIndex = parentData.lastReelIndex-nodeCount
    local symbolType = self:getSymbolTypeForNetData(cloumnIndex,parentData.rowIndex)
    local showOrder = self:getBounsScatterDataZorder(symbolType)
    parentData.symbolType = symbolType

    local posIdx = self:getPosReelIdx(parentData.rowIndex, cloumnIndex)
    parentData.order = showOrder + posIdx

    parentData.tag = cloumnIndex * SYMBOL_NODE_TAG + parentData.rowIndex

    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    if parentData.rowIndex == columnRowNum then --self.m_iReelRowNum then
        parentData.isLastNode = true
    end
    parentData.m_isLastSymbol = true
    self:changeReelDownAnima(parentData)
end

function CodeGameScreenKittysCatchMachine.setSymbolToClipReel(_MainClass, _iCol, _iRow, _type, _zorder)
    local targSp = _MainClass:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = _MainClass:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(_MainClass, index)

        local posIdx = _MainClass:getPosReelIdx(_iRow, _iCol)
        -- local showOrder = _MainClass:getBounsScatterDataZorder(_type) - _iRow
        local showOrder = _MainClass:getBounsScatterDataZorder(_type) + posIdx
        targSp.m_showOrder = showOrder
        targSp.p_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent(false)
        _MainClass.m_clipParent:addChild(targSp, _zorder + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

--重写
function CodeGameScreenKittysCatchMachine:getClipParentChildShowOrder(slotNode)
    local posIdx = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
    return self:getBounsScatterDataZorder(slotNode.p_symbolType) + posIdx
end

--重写
--新滚动使用
function CodeGameScreenKittysCatchMachine:updateReelGridNode(symblNode)
    self:removeSlotsNodeCorner(symblNode)
    if symblNode.p_symbolType == self.SYMBOL_SCATTER_1 then
        self:setSlotsNodeCornerNum(symblNode, 3)
    end
end

--设置symbol数字值
function CodeGameScreenKittysCatchMachine:setSlotsNodeCornerNum(_symblNode, _num)
    if _symblNode then
        local rightDownNumNode = util_getChildByName(_symblNode, "rightDownNum")
        if not rightDownNumNode then
            rightDownNumNode = util_createAnimation("KittysCatch_scatterjiaobiao.csb")
            _symblNode:addChild(rightDownNumNode, 10)
            rightDownNumNode:setName("rightDownNum")
            rightDownNumNode:setPosition(cc.p(50, -50))
        end
        rightDownNumNode:playAction("idle", true)
        local label = util_getChildByName(rightDownNumNode, "m_lb_num_1")

        if label then
            label:setString(_num)
            if _num == 1 then
                label:setPositionX(-2)
            else
                label:setPositionX(0)
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:removeSlotsNodeCorner(_symblNode)
    if _symblNode then
        local rightDownNumNode = util_getChildByName(_symblNode, "rightDownNum")
        if rightDownNumNode then
            rightDownNumNode:removeFromParent()
        end
    end
end

function CodeGameScreenKittysCatchMachine:playSlotsNodeCornerOver(_symblNode)
    if _symblNode then
        local rightDownNumNode = util_getChildByName(_symblNode, "rightDownNum")
        if rightDownNumNode then
            rightDownNumNode:playAction("over", false, function()
                rightDownNumNode:playAction("idle2", true)
            end)
        end
    end
end

--重写 连线赢钱时 去掉bonus赢钱 bonus赢钱动画时加
function CodeGameScreenKittysCatchMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true

    local showWinCoin = self.m_iOnceSpinLastWin --单次总钱
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    else
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata and selfdata.bonusLines then
            local bonusTotal = 0
            for i=1,#selfdata.bonusLines do
                bonusTotal = bonusTotal + selfdata.bonusLines[i].amount
            end
            showWinCoin = self.m_iOnceSpinLastWin - bonusTotal
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {showWinCoin, isNotifyUpdateTop})
end

---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenKittysCatchMachine:MachineRule_ResetReelRunData()

    if self.m_isPlayWinningNotice then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local preRunLen = reelRunData.initInfo.reelRunLen
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()
            
            reelRunData:setReelRunLen(preRunLen)
            reelRunData:setReelLongRun(false)
            reelRunData:setNextReelLongRun(false)

            -- 提取某一列所有内容， 一些老关在创建最终信号小块时会以此列表作为最终信号的判断条件
            local columnSlotsList = self.m_reelSlotsList[iCol]  
            -- 新的关卡父类可能没有这个变量
            if columnSlotsList then

                local curRunLen = reelRunData:getReelRunLen()
                local iRow = columnData.p_showGridCount
                -- 将 老的最终列表 依次放入 新的最终列表 对应索引处
                local maxIndex = runLen + iRow
                for checkRunIndex = maxIndex,1,-1 do
                    local checkData = columnSlotsList[checkRunIndex]
                    if checkData == nil then
                        break
                    end
                    columnSlotsList[checkRunIndex] = nil
                    columnSlotsList[curRunLen + iRow - (maxIndex - checkRunIndex)] = checkData
                end

            end
            
        end
    else
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local reelLongRunTime = 1
            local scatterReelNum = self:getScatterNumByCol(iCol-1)
            local scatterLockNum = self:getScatterLockNum()
            local scatterNum = scatterReelNum + scatterLockNum
            if scatterNum >= 2 then
                local iRow = columnData.p_showGridCount
                local lastColLens = reelRunInfo[1]:getReelRunLen()
                if iCol ~= 1 then
                    lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                    reelRunInfo[iCol - 1 ]:setNextReelLongRun(true)
                    reelLongRunTime = 1
                else
                    lastColLens = 0
                    reelLongRunTime = 0.9
                end

                local colHeight = columnData.p_slotColumnHeight
                local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    
                local preRunLen = reelRunData:getReelRunLen()
                reelRunData:setReelRunLen(runLen)

                if 5 ~= iCol then
                    reelRunData:setReelLongRun(true)
                    reelRunData:setNextReelLongRun(true)
                end
            else
                reelRunData:setReelLongRun(false)
                reelRunData:setNextReelLongRun(false)
            end
        end
    end
end

function CodeGameScreenKittysCatchMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = CodeGameScreenKittysCatchMachine.super.setReelLongRun(self,reelCol)
    
    if not self.m_isLongRun and isTriggerLongRun then
        --scatter播期待动画
        for iCol = 1,reelCol do
            for iRow = 1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol,iRow)
                self:playLookingForwardTo(symbol)
            end
        end

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            for k,v in pairs(self.m_baseScatterLockNodes) do
                if v then
                    local lockNode = v:getChildByTag(1)
                    if lockNode then
                        lockNode:playLockAction("actionframe4", true)

                        --期待本节点提层
                        v:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + k)
                    end
                end
            end
        end
        

        self.m_isLongRun = isTriggerLongRun

        if self.m_longRunSoundId == nil then
            self.m_longRunSoundId = gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_reelRunSound.mp3", true)
        end
    end

    return isTriggerLongRun
end

function CodeGameScreenKittysCatchMachine:playLookingForwardTo(symbol)
    if symbol and (symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbol.p_symbolType == self.SYMBOL_SCATTER_1 or symbol.p_symbolType == self.SYMBOL_SCATTER_2) then
        if symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            symbol:runAnim("actionframe2",true)
        elseif symbol.p_symbolType == self.SYMBOL_SCATTER_1 then
            symbol:runAnim("actionframe4",true)
        elseif symbol.p_symbolType == self.SYMBOL_SCATTER_2 then
            symbol:runAnim("actionframe5",true)
        end


        local posIdx = self:getPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex)
        symbol:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + posIdx)
    end 
end

--获取对应列及其之前的scatter数量
function CodeGameScreenKittysCatchMachine:getScatterNumByCol(_Col)
    local scatterNum = 0
    for iCol = 1, _Col do
        for iRow = 1 ,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_1 or symbolType == self.SYMBOL_SCATTER_2 then
                scatterNum = scatterNum + 1
            end
        end
    end
    return scatterNum
end

--获取锁定scatter数量 只有base下有
function CodeGameScreenKittysCatchMachine:getScatterLockNum()
    local scatterNum = 0
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local scatterData = self.m_lastScatterLockData
        if scatterData and #scatterData > 0 then
            for i = 1, #scatterData do
                if scatterData[i][2] ~= 1 then
                    scatterNum = scatterNum + 1
                end
            end
            return scatterNum
        end
    end
    return scatterNum
end

---
-- 接到消息后 处理第一列快滚
function CodeGameScreenKittysCatchMachine:setColOneLongRunStates()

    local scatterLockNum = self:getScatterLockNum()

    if scatterLockNum >= 2 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        for i =  1 , self.m_iReelColumnNum do
            --添加金边
            if i == 1 then
                if self.m_reelRunInfo[1]:getReelLongRun() then
                    self:creatReelRunAnimation(1)
                end
            end
            --后面列停止加速移动
            if self.m_longRunSoundId == nil then
                self.m_longRunSoundId = gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_reelRunSound.mp3", true)
            end
            

            local parentData = self.m_slotParents[i]
            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end

        if not self.m_isLongRun then
            --scatter播期待动画
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                for k,v in pairs(self.m_baseScatterLockNodes) do
                    if v then
                        local lockNode = v:getChildByTag(1)
                        if lockNode then
                            lockNode:playLockAction("actionframe4", true)

                            --期待本节点提层
                            v:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + k)
                        end
                    end
                end
            end 
            self.m_isLongRun = true
        end
    end

end

--判断Pos是否在连线中
function CodeGameScreenKittysCatchMachine:isPosInLine(_Pos)
    if self.m_reelResultLines ~= nil then
        for i,w in ipairs(self.m_reelResultLines) do
            for j,v in ipairs(self.m_reelResultLines[i].vecValidMatrixSymPos) do
                local posIdx = self:getPosReelIdx(v.iX, v.iY)
                if _Pos == posIdx then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenKittysCatchMachine:playCatHeadAnim(_isIdle1Anim)
    local percent = math.random(0, 100) < 70
    local animName = "idleframe"
    if percent then
    else
        animName = "idleframe2"
    end
    if _isIdle1Anim then
        animName = "idleframe"
    end
    util_spinePlay(self.m_catHead, animName, false)

    local spineEndCallFunc = function()
        self:playCatHeadAnim()
    end
    util_spineEndCallFunc(self.m_catHead, animName, spineEndCallFunc)
end

--修改赢钱区特效
function CodeGameScreenKittysCatchMachine:changeWinCoinEffectCsb(_isChange)
    local effectCsbName = "GameBottomNodePortrait_jiesuan.csb"
    if _isChange then
        effectCsbName = "KittysCatch_totalwin.csb"
    else
        if globalData.slotRunData.isPortrait == true then
            effectCsbName = "GameBottomNodePortrait_jiesuan.csb"
        else
            effectCsbName = "GameBottomNode_jiesuan.csb"
        end
    end
    
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), effectCsbName)
end

--重写  只有bonus时也出现大赢
function CodeGameScreenKittysCatchMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata and selfdata.bonusLines and #selfdata.bonusLines > 0 then
        else
            notAdd = true
        end
    end

    return notAdd
end

function CodeGameScreenKittysCatchMachine:setUiOrder(_isUp)
    local order = _isUp and SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 2900 or SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 50
    for i=1,#self.m_orderPicNodes do
        self.m_orderPicNodes[i]:setLocalZOrder(order + i)
    end
end

-- shake
function CodeGameScreenKittysCatchMachine:shakeOneNodeForever(time)
    local oldPos = cc.p(self:getPosition())
    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    self:runAction(action)

    self:levelPerformWithDelay(time,function()
        self:stopAction(action)
        self:setPosition(oldPos)
    end)
end

--重写
function CodeGameScreenKittysCatchMachine:getBottomUINode( )
    return "CodeKittysCatchSrc.KittysCatchGameBottomNode"
end

function CodeGameScreenKittysCatchMachine:getEatFishTotalWinNum(  )
    local curBonusWin = 0
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.bonusLines then
        if #selfdata.bonusLines ~= #selfdata.bonusMulti then
            release_print("getEatFishTotalWinNum bonusLines num not equal bonusMulti error!!!")
        end
        if #selfdata.bonusLines > 0 then
            for i=1,#selfdata.bonusLines do
                curBonusWin = curBonusWin + selfdata.bonusLines[i].amount
            end
        end
    end
    return curBonusWin
end

---
--添加金边
function CodeGameScreenKittysCatchMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    -- gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    -- self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

-- 显示paytableview 界面
function CodeGameScreenKittysCatchMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    if view then
        view:findChild("root"):setScale(self.m_machineRootScale)
        view:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                gLobalViewManager:viewResume(
                    function()
                        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
                    end
                )
            end
        )
    end
end

function CodeGameScreenKittysCatchMachine:pauseMachine()
    CodeGameScreenKittysCatchMachine.super.pauseMachine(self)
    if self.m_longRunSoundId then
        gLobalSoundManager:setSoundVolumeByID(self.m_longRunSoundId, 0)
    end
end

function CodeGameScreenKittysCatchMachine:resumeMachine()
    CodeGameScreenKittysCatchMachine.super.resumeMachine(self)
    if self.m_longRunSoundId then
        gLobalSoundManager:setSoundVolumeByID(self.m_longRunSoundId, 1)
    end
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenKittysCatchMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.bonusLines then
        if #selfdata.bonusLines > 0 then
            self.m_isAddBigWinLightEffect = false
        end
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenKittysCatchMachine:showBigWinLight(_func)
    for i=1,4 do
        self:findChild("lizi" .. i):resetSystem()
    end
    self.m_spineBigWin:setVisible(true)
    local animName = self:getCurrSpinMode() == FREE_SPIN_MODE and "actionframe2" or "actionframe"
    util_spinePlay(self.m_spineBigWin, animName, false)
    local spineEndCallFunc = function()
        self.m_spineBigWin:setVisible(false)
    end
    util_spineEndCallFunc(self.m_spineBigWin, animName, spineEndCallFunc)
    
    gLobalSoundManager:playSound("KittysCatchSounds/sound_KittysCatch_globalCelebrate.mp3")

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_catAnimIsPlay = true
        util_spinePlay(self.m_catHead, "actionframe4", false)
        local spineEndCallFunc = function()
            self.m_catAnimIsPlay = false
            self:playCatHeadAnim()
        end
        util_spineEndCallFunc(self.m_catHead, "actionframe4", spineEndCallFunc)
    end
    
    self:delayCallBack(1.5, function()
        if type(_func) == "function" then
            _func()
        end
    end)
end

return CodeGameScreenKittysCatchMachine






