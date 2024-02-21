---
-- island li
-- 2019年1月26日
-- CodeGameScreenBingoldKoiMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "BingoldKoiPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenBingoldKoiMachine = class("CodeGameScreenBingoldKoiMachine", BaseNewReelMachine)

CodeGameScreenBingoldKoiMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBingoldKoiMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- bonus
CodeGameScreenBingoldKoiMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 

CodeGameScreenBingoldKoiMachine.BINGO_LINE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --bingo连线
CodeGameScreenBingoldKoiMachine.TRIGGER_BINGO_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --bingo连线触发
CodeGameScreenBingoldKoiMachine.COLLECT_TOP_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --往顶部收集鱼
CodeGameScreenBingoldKoiMachine.SUPER_RANDOM_ADD_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 --superfree清bingo盘后随机加的bonus
CodeGameScreenBingoldKoiMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 --收集bonus
CodeGameScreenBingoldKoiMachine.RANDOM_ADD_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6 --随机添加bonus
CodeGameScreenBingoldKoiMachine.FREESPIN_OVER_BINGO_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 7 --free下最后一次如果连线，free 弹板出来后去处理bingo盘


CodeGameScreenBingoldKoiMachine.UPDATE_WILD_MUTILPLE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10 --刷新wild倍数


-- 构造函数
function CodeGameScreenBingoldKoiMachine:ctor()
    CodeGameScreenBingoldKoiMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isBonusWin = false
    self.m_isBonusTrigger = false
    self.m_publicConfig = PublicConfig

    self.m_lineRespinNodes = {}
    self.m_bulingNodeList = {}
    self.m_isPlayGameEffect = nil
    self.m_bonusLineAnis = {}

    self.m_collectNodeTbl = {}

    --本次spin收集到的bonus
    self.m_curSpinCollectBonus = {}
 
    --init
    self:initGame()
end

function CodeGameScreenBingoldKoiMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("BingoldKoiConfig.csv", "LevelBingoldKoiConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

--[[
    初始化配置
]]
function CodeGameScreenBingoldKoiMachine:initGameStatusData(gameData)
    CodeGameScreenBingoldKoiMachine.super.initGameStatusData(self, gameData)
    
    --各个bet下对应的bingo轮盘
    self.m_betData = gameData.gameConfig.extra.betData

    --收集进度数据
    self.m_collectData = gameData.gameConfig.extra.collectData

    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.kind and extraData.kind == "super" then
        self.m_isSuperFree = true
        local selfData = self.m_runSpinResultData.p_selfMakeData

        self.m_superBingoData = gameData.gameConfig.extra.superBingoData
    end
end

--[[
    刷新本地存储数据
]]
function CodeGameScreenBingoldKoiMachine:updateLocalData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end
    -- --各个bet下对应的bingo轮盘
    if selfData.betData then
        self.m_betData = selfData.betData
    end

    --收集进度数据
    if selfData.collectData then
        self.m_collectData = selfData.collectData
    end

    if selfData.superBingoData then
        self.m_superBingoData = selfData.superBingoData
    end
end

function CodeGameScreenBingoldKoiMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 
    if betCoin >= self.m_specialBets[1].p_totalBetValue then
        level = 1
    end
    self.m_iBetLevel = level
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBingoldKoiMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BingoldKoi"  
end


-- 继承底层respinView
function CodeGameScreenBingoldKoiMachine:getRespinView()
    return "CodeBingoldKoiSrc.BingoldKoiRespinView"
end
-- 继承底层respinNode
function CodeGameScreenBingoldKoiMachine:getRespinNode()
    return "CodeBingoldKoiSrc.BingoldKoiRespinNode"
end

function CodeGameScreenBingoldKoiMachine:getBottomUINode()
    return "CodeBingoldKoiSrc.BingoldKoiBottomNode"
end

function CodeGameScreenBingoldKoiMachine:initFreeSpinBar()
    local node_bar = self:findChild("FreeSpins")
    self.m_baseFreeSpinBar = util_createView("CodeBingoldKoiSrc.BingoldKoiFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenBingoldKoiMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    --jackpot
    self.m_jackpotBar = util_createView("CodeBingoldKoiSrc.BingoldKoiJackPotBarView",{machine = self})
    self:findChild("Jackpot"):addChild(self.m_jackpotBar)

    --收集条
    self.m_collectBar = util_createView("CodeBingoldKoiSrc.BingoldKoiCollectBar",{machine = self})
    self:findChild("shouji"):addChild(self.m_collectBar)

    --bingo盘面控制类
    self.m_bingoControl = require("CodeBingoldKoiSrc.BingoldKoiBingoControl").new({machine = self})

    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Reel_base")
    self.m_reelBg[2] = self:findChild("Reel_free")

    self.m_reelLine = {}
    self.m_reelLine[1] = self:findChild("Node_jiange_base")
    self.m_reelLine[2] = self:findChild("Node_jiange_free")

    self.m_bgBottomType = {}
    self.m_bgBottomType[1] = self.m_gameBg:findChild("bingo")
    self.m_bgBottomType[2] = self.m_gameBg:findChild("FG")
    self.m_bgBottomType[3] = self.m_gameBg:findChild("superbingo")
    self.m_bgBottomType[4] = self.m_gameBg:findChild("bonuswheel")

    self.m_bgType = {}
    self.m_bgType[1] = self.m_gameBg:findChild("sp_bingo")
    self.m_bgType[2] = self.m_gameBg:findChild("sp_FG")
    self.m_bgType[3] = self.m_gameBg:findChild("sp_superbingo")
    self.m_bgType[4] = self.m_gameBg:findChild("sp_bonuswheel")

    self.m_maskAni = util_createAnimation("BingoldKoi_darkLeft.csb")
    self:findChild("qipanyaan"):addChild(self.m_maskAni)
    self.m_maskAni:setVisible(false)

    self.m_bingoSpine = util_spineCreate("BingoldKoi_Bingo",true,true)
    self:findChild("qipanyaan"):addChild(self.m_bingoSpine)
    self.m_bingoSpine:setVisible(false)

    self.m_waterSpine = util_spineCreate("BingoldKoi_Bingo_shui",true,true)
    self:findChild("qipanyaan"):addChild(self.m_waterSpine)
    self.m_waterSpine:setVisible(false)

    self.m_bonusLineNode = self:findChild("Node_bonusLine")

    self.bonusBigLineAni = util_createAnimation("WinFrameBingoldKoi_DaKuang.csb")
    self.m_bonusLineNode:addChild(self.bonusBigLineAni)
    self.bonusBigLineAni:setVisible(false)

    self.bingoAni = util_createAnimation("BingoldKoi_bingo.csb")
    self:findChild("qipanyaan"):addChild(self.bingoAni)
    self.bingoAni:setVisible(false)

    self.m_cutSceneSpine = util_spineCreate("BingoldKoi_guochang",true,true)
    self:findChild("Node_cut_scene"):addChild(self.m_cutSceneSpine)
    self.m_cutSceneSpine:setVisible(false)

    self.m_cutSceneSuperSpine = util_spineCreate("BingoldKoi_guochang_2",true,true)
    self:findChild("root"):addChild(self.m_cutSceneSuperSpine, 10)
    self.m_cutSceneSuperSpine:setVisible(false)

    self.m_panel_clipNode = self:findChild("panel_clipNode")

    self.m_topSymbolNode = self:findChild("Node_topSymbol")

    self.m_skip_click = self:findChild("Panel_skip_click")
    self.m_skip_click:setVisible(false)
    self:addClick(self.m_skip_click)
   
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
    
    -- self:runCsbAction("idle", true)
    self:changeBgSpine(1)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "BingoldKoi_xy.csb")
end

function CodeGameScreenBingoldKoiMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 4, 0, 1)
    end,0.2,self:getModuleName())
end

---
-- 进入关卡
--
function CodeGameScreenBingoldKoiMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()
    self.m_isPlayGameEffect = isPlayGameEffect

    local hasFeature = self:checkHasFeature()

    self.m_initReelFlag = false
    if hasFeature == false then
        self.m_initReelFlag = true
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()
end

function CodeGameScreenBingoldKoiMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBingoldKoiMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:updateBetLevel()
    self:addObservers()

    --显示respin界面
    self:showRespinView()

    --先添加25个光圈
    self:addBonusLineEffect()

    --刷新bingo盘面
    self:refreshBingoReel(nil, false, true, true)

    --刷新收集进度
    self:refreshCollectBar(true)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:refreshWildMutiple(nil, true)
        self.m_baseFreeSpinBar:setCurSpinType(self.m_isSuperFree)
    end

    if self.m_isSuperFree then
        self.m_bottomUI:showAverageBet()
        self.m_collectBar:playSuperIdle()
        self:changeBgSpine(3)
    else
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:changeBgSpine(2)
        end
        if self.m_iBetLevel ~= 0 then
            self.m_collectBar:showTips()
        end
    end

    --如果有bonus玩法，设置右边轮盘状态和压暗
    if self:curIsTriggerGameOther() and not self.m_initFeatureData then
        self.m_maskAni:setVisible(true)
        self.m_maskAni:runCsbAction("idle", true)
        self.m_panel_clipNode:setClippingEnabled(true)
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self.m_bingoControl:setBingoLineZorder(selfData.bingoLines, true)
    end

    -- 创建完成去执行相关的操作
    if self.m_isPlayGameEffect or #self.m_gameEffects > 0 then
        self.m_isPlayGameEffect = nil
        self:sortGameEffects()
        self:playGameEffect()
    end
    -- self:setCurMusicState()
end

--[[
    设置base下轮盘显示
]]
function CodeGameScreenBingoldKoiMachine:setBaseReelShow(isShow)
    self:findChild("Node_1"):setVisible(isShow)
end

function CodeGameScreenBingoldKoiMachine:addObservers()
    CodeGameScreenBingoldKoiMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
            self:clearWinLineEffect()
            self:refreshCollectBar(true)
            self.m_bingoControl:resetBonusAnisType()
            self.m_bingoControl:resetLinePosition()
            self.m_bingoControl:hideTipLight(true)
            --刷新bingo盘面
            self:refreshBingoReel(nil, false, true, true, true)
        end
        
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin or self.m_isBonusWin then
            return
        end

        if self:curIsTriggerFreeGame() then
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
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_isSuperFree then
                bgmType = "super"
            else
                bgmType = "fg"
            end
        else
            bgmType = "base"
        end

        local soundName = "BingoldKoiSounds/music_BingoldKoi_last_win_"..bgmType.."_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenBingoldKoiMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBingoldKoiMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenBingoldKoiMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0 - mainPosY

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
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width / display.height >= 1660/768 then
            mainScale = mainScale * 1.08
        elseif display.width / display.height >= 1530/768 then
            mainScale = mainScale * 1.08
        elseif display.width / display.height >= 1370/768 then
            mainScale = mainScale * 0.98
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 0.84
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.73
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 0.67
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY+tempPosY)
    end
end

function CodeGameScreenBingoldKoiMachine:addBonusLineEffect()
    for iRow = 1, self.m_iReelRowNum do
        self.m_bonusLineAnis[iRow] = {}
        for iCol = 1, self.m_iReelColumnNum do
            local bonusLineAni = util_createAnimation("WinFrameBingoldKoi_tishikuang.csb")
            bonusLineAni:setVisible(false)
            local pos = self:getPosReelIdx(iRow, iCol)
            local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
            -- local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
            -- local nodePos = self.m_bonusLineNode:convertToNodeSpace(worldPos)
            self.m_bonusLineAnis[iRow][iCol] = bonusLineAni
            -- bonusLineAni:setPosition(clipTarPos)
            -- self.m_clipParent:addChild(bonusLineAni, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol,iRow)
            bonusLineAni:setPosition(util_convertToNodeSpace(respinNode.m_baseFirstNode,self.m_respinView))
            local zOrder = respinNode.m_baseFirstNode:getLocalZOrder() + 10
            self.m_respinView:addChild(bonusLineAni, zOrder)
        end
    end
end

--[[
    刷新中奖光圈(只差一个获得bingo的时候)
]]
function CodeGameScreenBingoldKoiMachine:refreshTipLight(iRow, iCol)
    local lineAni = self.m_bonusLineAnis[iRow][iCol]
    if lineAni then
        lineAni:setVisible(true)
        lineAni:runCsbAction("actionframe", true)
    end
end

function CodeGameScreenBingoldKoiMachine:hideTipLight(iRow, iCol, isOnEnter)
    local lineAni = self.m_bonusLineAnis[iRow][iCol]
    if lineAni then
        if isOnEnter then
            lineAni:setVisible(false)
        else
            lineAni:runCsbAction("over", false, function()
                lineAni:setVisible(false)
            end)
        end
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBingoldKoiMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BONUS then
        return "Socre_BingoldKoi_BingoBonus"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BingoldKoi_10"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBingoldKoiMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBingoldKoiMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--绘制多个裁切区域
function CodeGameScreenBingoldKoiMachine:drawReelArea()
    CodeGameScreenBingoldKoiMachine.super.drawReelArea(self)
    local size = self.m_touchSpinLayer:getContentSize()
    -- 写算法没啥意思就这一关异常轮子，直接写死得了
    self.m_touchSpinLayer:setContentSize(cc.size(608 * 2, size.height))
    -- 测试数据，看点击区域范围
    -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_touchSpinLayer:setBackGroundColorOpacity(0)
    -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--默认按钮监听回调
function CodeGameScreenBingoldKoiMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_skip_click" then
        self:runSkipCollect()
    end
end

--接收到数据开始停止滚动
function CodeGameScreenBingoldKoiMachine:stopRespinRun()
    local callFunc = function()
        local storedNodeInfo = {}
        local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
        -- self:checkIsLongRun(unStoredReels)
        self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    --super随机添加bonus
    if self.m_isSuperFree and selfData and selfData.normalBonusCoins then
        for i=1, #selfData.normalBonusCoins do
            self.m_curSpinCollectBonus[#self.m_curSpinCollectBonus+1] = selfData.normalBonusCoins[i]
        end
        self:randomAddBonusToBingo(selfData.normalBonusCoins, true, false, callFunc)
    --当前bet没有配置的话，需要随机添加
    elseif selfData.baseBlankBonusCoins then
        self:randomAddBonusToBingo(selfData.baseBlankBonusCoins, true, false, callFunc)
    else
        callFunc()
    end
end

--检查本次是否是快滚
function CodeGameScreenBingoldKoiMachine:checkIsLongRun(unStoredReels)
    self.m_longRunStartReel = nil

    local scatterNum = 0
    local triggerNum = 2
    for iCol = 1, self.m_iReelColumnNum - 1 do --一共只有5列，但是第5列触发快滚需要从第6列开始快滚，所以只检测前4列
        for iRow = 1, self.m_iReelRowNum do
            if self.m_respinReelsType[iCol][iRow] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterNum = scatterNum + 1

                if scatterNum >= triggerNum then
                    self.m_longRunStartReel = iCol + 1
                    return
                end
            end
        end
    end
end

--重写获取每列滚动数据
function CodeGameScreenBingoldKoiMachine:getRespinReelsButStored(storedInfo)
    local reelData = CodeGameScreenBingoldKoiMachine.super.getRespinReelsButStored(self,storedInfo) or {}


    self.m_respinReelsType = {}
    for i = 1, 5 do
        self.m_respinReelsType[i] = {}
    end

    for i=1,#reelData do
        local symbolInfo = reelData[i] 
        table.insert(self.m_respinReelsType[symbolInfo.iY], symbolInfo.type)
    end

    return reelData
end

--
--单列滚动停止回调
--
function CodeGameScreenBingoldKoiMachine:slotLocalOneReelDown(_iCol)
    self:playReelDownSound(_iCol, self.m_reelDownSound)
end

-- 创建一个reels上层的特殊显示信号信号, scatter
function CodeGameScreenBingoldKoiMachine:createAnimSymbol(_tarNode,_baseOrder)
    if not _tarNode or not _tarNode.m_ccbName then
        return
    end

    local tarNode = _tarNode
  
    local resType = nil
    local animNode = nil 
    animNode,resType = util_spineCreate(_tarNode.m_ccbName, true, false)
    
    local worldPos = tarNode:getParent():convertToWorldSpace(cc.p(tarNode:getPositionX(), tarNode:getPositionY()))
    local pos = self.m_clipParent:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    local baseOrder = _baseOrder or SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE 
    local zorder = baseOrder + tarNode.p_cloumnIndex * 100 + tarNode.p_rowIndex 
    self.m_clipParent:addChild(animNode,zorder )
    animNode:setPosition(pos)

    return animNode
end

function CodeGameScreenBingoldKoiMachine:addbulingNodeList(_animNode,_node)
    local data = {}
    data.node = _animNode
    data.symbolType = _node.p_symbolType
    table.insert(self.m_bulingNodeList, data)
end

function CodeGameScreenBingoldKoiMachine:removeAllActionNode(hide)
    for k, v in pairs(self.m_bulingNodeList) do
        local data = v
        if data.node then
            data.node:removeFromParent()
        end
    end

    self.m_bulingNodeList = {}
end

--显示快滚特效
function CodeGameScreenBingoldKoiMachine:rsLongRunEffect(reelIndex)
    if self.m_rsLongRunEffectIndex ~= reelIndex and reelIndex >= 1 and reelIndex <= self.m_iReelColumnNum  then
        self.m_rsLongRunEffectIndex = reelIndex
        if self.m_rsLongRunEffectBg then
            self.m_rsLongRunEffectBg:removeFromParent()
            self.m_rsLongRunEffectBg = nil
        end

        if self.m_rsLongRunEffectLine then
            self.m_rsLongRunEffectLine:removeFromParent()
            self.m_rsLongRunEffectLine = nil
        end

        local curNode = self:findChild("sp_reel_" .. reelIndex-1 )
        local endWorldPos = curNode:getParent():convertToWorldSpace( cc.p(curNode:getPosition()) )

        self.m_rsLongRunEffectBg = util_createAnimation("WinFrameBingoldKoi_run_bg.csb")
        self.m_clipParent:addChild(self.m_rsLongRunEffectBg, -1)
        local endBgPos = self.m_clipParent:convertToNodeSpace( cc.p(endWorldPos) )
        self.m_rsLongRunEffectBg:setPosition(cc.p(endBgPos))
        self.m_rsLongRunEffectBg:runCsbAction("run", true)

        self.m_rsLongRunEffectLine = util_createAnimation("WinFrameBingoldKoi_run.csb")
        self.m_slotEffectLayer:addChild(self.m_rsLongRunEffectLine)
        local endActPos = self.m_slotEffectLayer:convertToNodeSpace( cc.p(endWorldPos) )
        self.m_rsLongRunEffectLine:setPosition(cc.p(endActPos))
        self.m_rsLongRunEffectLine:runCsbAction("run", true)
    end
end

--隐藏快滚特效
function CodeGameScreenBingoldKoiMachine:hideLongRunEffect()
    self.m_rsLongRunEffectIndex = 0
    if self.m_rsLongRunEffectBg then
        self.m_rsLongRunEffectBg:removeFromParent()
        self.m_rsLongRunEffectBg = nil
    end

    if self.m_rsLongRunEffectLine then
        self.m_rsLongRunEffectLine:removeFromParent()
        self.m_rsLongRunEffectLine = nil
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, { SpinBtn_Type.BtnType_Stop, true })
end

----------------------------- 玩法处理 -----------------------------------

--[[
    刷新收集进度
]]
function CodeGameScreenBingoldKoiMachine:refreshCollectBar(_onEnter, _callfunc, _isSuperOver)
    
    local curCollect = self.m_collectData.collect
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.kind and extraData.kind == "super"  then
        curCollect = 12
    end

    if self.m_iBetLevel == 0 then
        self.m_collectBar:lockAni()
    else
        self.m_collectBar:unLockAni()
    end

    if not self.m_isSuperFree or _isSuperOver then
        self.m_collectBar:refreshCollectCount(curCollect, _onEnter, _callfunc)
    else
        if _callfunc then
            _callfunc()
        end
    end
end
--[[
    刷新bingo盘面
]]
function CodeGameScreenBingoldKoiMachine:refreshBingoReel(bonusCoins, isUseBonusData, isPlayLine, isOnEnter, isCutBet)
    self.m_bingoControl:refreshBingoReel(bonusCoins, isUseBonusData, isPlayLine, isOnEnter, isCutBet)
end

function CodeGameScreenBingoldKoiMachine:isJackpotSymbol(kind)
    local jackpots = {"mini","minor","major","mega","grand"}
    for k,jackpot in pairs(jackpots) do
        if kind == jackpot then
            return true
        end
    end

    return false
end

-- 断线重连 
function CodeGameScreenBingoldKoiMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin then
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenBingoldKoiMachine:slotOneReelDown(reelCol)    
    CodeGameScreenBingoldKoiMachine.super.slotOneReelDown(self,reelCol) 
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBingoldKoiMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBingoldKoiMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenBingoldKoiMachine:showEffect_Bonus(effectData)

    local wheelEndIndex =  self.m_runSpinResultData.p_selfMakeData.wheelIndex
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Wheel_Start)
    local playClickFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Click_Btn)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Wheel_Over)
    end
    
    local view = self:showWheelStartView(function()
        self:showCutSceneSuperAni(nil, function()
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                self.m_bottomUI:updateWinCount("")
            end
            self:changeBgSpine(4)
            --隐藏base轮盘
            self:setBaseReelShow(false)

            local reel = util_createView("BingoldKoiSpecialReel.BingoldKoiWheelView",{machine = self, _effectData = effectData, _wheelEndIndex = wheelEndIndex})
            self:findChild("root"):addChild(reel)
            reel:setPosition(cc.p(-display.width / 2,-display.height / 2))
        end)
    end)
    view:setBtnClickFunc(playClickFunc) 
    return true
end

function CodeGameScreenBingoldKoiMachine:bonusGameOver(effectData, endCallfunc)
    self:showCutSceneSuperAni(effectData, function()
        globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            if self.m_isSuperFree then
                self:changeBgSpine(3)
            else
                self:changeBgSpine(2)
            end
        else
            self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
            self:changeBgSpine(1)
        end
        
        self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_winAmount
        --刷新本地数据
        self:updateLocalData()
        --刷新bingo盘面
        self:refreshBingoReel(nil, false, false, true)
        --把连线上的bonus设置成动画idle状态
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self.m_bingoControl:setBonusGameOverBingoLineIdle(selfData.bingoLines)
        --bonus转盘结束后删除清除和随机添加事件（某些原因，kind不能在base下给super，只有在轮盘回来再给）
        self:removeTriggerSuperSomeEffect()
        --bonus转盘结束后检测添加随机bonus事件
        self:checkAddRandomEffect()

        --显示base轮盘
        self:setBaseReelShow(true)

        self.m_isBonusWin = true

        if type(endCallfunc) == "function" then
            endCallfunc()
        end
        -- effectData.p_isPlay = true
        -- self:playGameEffect()
    end)
end

function CodeGameScreenBingoldKoiMachine:showCutSceneSuperAni(_effectData, _callFunc)
    local callFunc = _callFunc
    local effectData = _effectData
    self.m_cutSceneSuperSpine:setVisible(true)
    if effectData then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Wheel_Cut_Scene_Back)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Wheel_Cut_Scene)
    end
    util_spinePlay(self.m_cutSceneSuperSpine,"actionframe_guochang",false)
    util_spineFrameEvent(self.m_cutSceneSuperSpine, "actionframe_guochang", "switch", function()
        if effectData then
            self:setCurMusicState()
        else
            self:resetMusicBg(nil, self.m_publicConfig.Music_Wheel_Bg)
        end
        
        if type(_callFunc) == "function" then
            _callFunc()
        end
    end)
    util_spineEndCallFunc(self.m_cutSceneSuperSpine, "actionframe_guochang", function()
        self.m_cutSceneSuperSpine:setVisible(false)
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end)
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenBingoldKoiMachine:checkHasGameEffect(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType and not self.m_gameEffects[i].p_isPlay then
            return true
        end
    end

    return false
end

function CodeGameScreenBingoldKoiMachine:changeBottomBgSpine(_bgType)
    for i=1, 4 do
        if i == _bgType then
            self.m_bgBottomType[i]:setVisible(true)
        else
            self.m_bgBottomType[i]:setVisible(false)
        end
    end
end

function CodeGameScreenBingoldKoiMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin；3.respin
    -- local actionName = {"base", "free", "respin"}
    self.m_gameBg:runCsbAction("idle", true)
    for i=1, 4 do
        if i == _bgType then
            self.m_bgType[i]:setVisible(true)
        else
            self.m_bgType[i]:setVisible(false)
        end
    end
    if _bgType <= 3 then
        local bgType = _bgType
        if bgType == 3 then
            bgType = 2
        end
        self:setReelBgState(bgType)
    end
end

function CodeGameScreenBingoldKoiMachine:setReelBgState(_bgType)
    for i=1, 2 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
            self.m_reelLine[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
            self.m_reelLine[i]:setVisible(false)
        end
    end
end

--[[
    显示轮盘开始弹板
]]
function CodeGameScreenBingoldKoiMachine:showWheelStartView(func)
    local ownerlist = {}

    local viewName = "WheelStart"
    local view = self:showDialog(viewName, ownerlist, func)
    local hlSpine = util_spineCreate("BingoldKoi_tanban_hl",true,true)
    util_spinePlay(hlSpine,"animation",true)
    view:findChild("hll"):addChild(hlSpine)

    local lightAni = util_createAnimation("BingoldKoi_lightNormal.csb")
    view:findChild("guang"):addChild(lightAni)
    lightAni:runCsbAction("idle", true)

    util_setCascadeOpacityEnabledRescursion(view, true)
    return view
end

--只是为了解决轮盘回来是否触发super，触发的话，除去addSelfEffect下加的事件，因为流程特殊，需要在弹板后添加清除和随机添加事件
function CodeGameScreenBingoldKoiMachine:removeTriggerSuperSomeEffect()
    if self:getCurIsFirstTriggrSuperFree() then
        --删除随机添加事件（弹板后添加）
        for i,effectData in ipairs(self.m_gameEffects) do
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT and 
            effectData.p_selfEffectType == self.RANDOM_ADD_BONUS_EFFECT and not effectData.p_isPlay then
                table.remove( self.m_gameEffects, i)
                break
            end
        end
    end
end

--[[
    bonus转盘结束后检测添加随机bonus事件
]]
function CodeGameScreenBingoldKoiMachine:checkAddRandomEffect()
    --检测是否添加收集(断线回来收集事件需要重新添加)
    local isAddCollectBonus = true
    for i,effectData in ipairs(self.m_gameEffects) do
        if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT and 
        effectData.p_selfEffectType == self.BINGO_LINE_EFFECT then
            isAddCollectBonus = false
            break
        end
    end
    if isAddCollectBonus then
        self.freeSpinOverRun = true
        self.m_curLineRandom = true
        for i=#self.m_gameEffects ,1,-1 do
            local effect = self.m_gameEffects[i]
            if effect.p_effectType == GameEffect.EFFECT_BONUS then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.BINGO_LINE_EFFECT
                table.insert(self.m_gameEffects,i+1, selfEffect)
                selfEffect.p_selfEffectType = self.BINGO_LINE_EFFECT -- 动画类型

                --添加顶部收集
                if not self.m_isSuperFree then
                    local selfEffect_2 = GameEffectData.new()
                    selfEffect_2.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect_2.p_effectOrder = self.BINGO_LINE_EFFECT + 1
                    table.insert(self.m_gameEffects,i+2, selfEffect_2)
                    selfEffect_2.p_selfEffectType = self.COLLECT_TOP_BONUS_EFFECT -- 动画类型
                end
                break
            end
        end
    end

    --检测是否添加随机bonus
    local isAddRandomBonus = true
    for i,effectData in ipairs(self.m_gameEffects) do
        if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT and 
        effectData.p_selfEffectType == self.RANDOM_ADD_BONUS_EFFECT and not effectData.p_isPlay then
            isAddRandomBonus = false
            break
        end
    end
    if isAddRandomBonus then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        --initBonusCoins 随机向bingo盘添加bonus信号(每个bet第一次spin和消除bingo线后会随机添加)
        if selfData and selfData.initBonusCoins and not self:getCurIsFirstTriggrSuperFree() and not self:getCurIsFreeGameLastSpin() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            local order = GameEffect.EFFECT_BONUS + 3
            selfEffect.p_effectOrder = order
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RANDOM_ADD_BONUS_EFFECT -- 动画类型
        end
    end
end

function CodeGameScreenBingoldKoiMachine:createBingoldKoiSymbol(_symbolType)
    local symbol = util_createView("CodeBingoldKoiSrc.BingoldKoiSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenBingoldKoiMachine:getTopSymbolPos(_pos)
    local clipTarPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
    local nodePos = self.m_topSymbolNode:convertToNodeSpace(worldPos)
    return nodePos
end

-- 显示free spin
function CodeGameScreenBingoldKoiMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        --停掉背景音乐
        self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end

    local waitTime = 0
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.kind and extraData.kind == "super" then
        --TODO
    else
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                -- local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                local slotNode = self.m_respinView:getRespinEndNode(iRow, iCol)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        -- --scatter播触发需要提层到上边收集栏的层级之上
                        -- if iRow == self.m_iReelRowNum then
                            local topSatterNode = self:createBingoldKoiSymbol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                            local scatterPos = self:getPosReelIdx(iRow, iCol)
                            local nodePos = self:getTopSymbolPos(scatterPos)

                            -- local posX, posY = slotNode:getPosition()
                            -- local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(posX, posY))
                            -- local nodePos = self.m_topSymbolNode:convertToNodeSpace(worldPos)

                            slotNode:setVisible(false)
                            topSatterNode:setPosition(nodePos)
                            local scatterZorder = 10 - iRow + iCol
                            self.m_topSymbolNode:addChild(topSatterNode, scatterZorder)
                            topSatterNode:runAnim("actionframe", false, function()
                                slotNode:setVisible(true)
                                slotNode:runAnim("idleframe", true)
                                topSatterNode:setVisible(false)
                            end)

                            local duration = topSatterNode:getAnimDurationTime("actionframe")
                            waitTime = util_max(waitTime,duration)
                        -- else
                        --     slotNode:runAnim("actionframe", false, function()
                        --         slotNode:runAnim("idleframe", true)
                        --     end)
                        --     local duration = slotNode:getAniamDurationByName("actionframe")
                        --     waitTime = util_max(waitTime,duration)
                        -- end
                        -- local parent = slotNode:getParent()
                        -- if parent ~= self.m_clipParent then
                        --     slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        -- end
                    end
                end
            end
        end
        self:playScatterTipMusicEffect()
    end
    
    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenBingoldKoiMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BingoldKoiSounds/music_BingoldKoi_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local hlSpine = util_spineCreate("BingoldKoi_tanban_hl",true,true)
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        local lightAni = util_createAnimation("BingoldKoi_lightNormal.csb")
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self.m_baseFreeSpinBar:setIsRefresh(true)
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_More_Start_Over)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            if not self.m_isSuperFree then
                view:findChild("guang"):addChild(lightAni)
                lightAni:runCsbAction("idle", true)
                util_spinePlay(hlSpine,"animation",true)
                view:findChild("hll"):addChild(hlSpine)
                util_setCascadeOpacityEnabledRescursion(view, true)
            end
        else
            globalData.coinsSoundType = 1
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            local playClickFunc = function()
                self.m_bottomUI:updateWinCount("")
                self:setLastWinCoin(0)
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Click_Btn)
                if self.m_isSuperFree then
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Super_Start_Over)
                    self.m_collectBar:triggerSuperFree()
                    self:changeBottomBgSpine(3)
                    self.m_gameBg:runCsbAction("switch", false, function()
                        self:changeBgSpine(3)
                    end)
                else
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Start_Over)
                end
            end
            
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes, function()
                self.m_baseFreeSpinBar:setCurSpinType(self.m_isSuperFree)
                if self.m_isSuperFree then
                    self.m_baseFreeSpinBar:setVisible(true)
                    self.m_baseFreeSpinBar:runCsbAction("actionframe", false)
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    -- self:changeBgSpine(3)
                else
                    self:showCutSceneAni(true, effectData, function()
                        self.m_baseFreeSpinBar:setVisible(true)
                        self:changeBgSpine(2)
                    end)  
                end
            end)
            view:setBtnClickFunc(playClickFunc)
            if not self.m_isSuperFree then
                view:findChild("guang"):addChild(lightAni)
                lightAni:runCsbAction("idle", true)
            end
            util_spinePlay(hlSpine,"animation",true)
            view:findChild("hll"):addChild(hlSpine)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenBingoldKoiMachine:showCutSceneAni(_isStart, _effectData, _callFunc)
    local callFunc = _callFunc
    self.m_cutSceneSpine:setVisible(true)
    if _isStart then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Cut_Scene)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_CutBack_Scene)
    end
    util_spinePlay(self.m_cutSceneSpine,"actionframe_guochang",false)
    util_spineFrameEvent(self.m_cutSceneSpine, "actionframe_guochang", "switch", function()
        if type(_callFunc) == "function" then
            _callFunc()
        end
    end)
    util_spineEndCallFunc(self.m_cutSceneSpine, "actionframe_guochang", function()
        if _isStart then
            self:triggerFreeSpinCallFun()
            _effectData.p_isPlay = true
            self:playGameEffect()
        else
            self:triggerFreeSpinOverCallFun()
        end
        self.m_cutSceneSpine:setVisible(false)
    end)
end

function CodeGameScreenBingoldKoiMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local viewName = BaseDialog.DIALOG_TYPE_FREESPIN_START
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.kind and extraData.kind == "super" then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Super_Start_Start)
        viewName = "SuperBingoStart"
        self.m_isSuperFree = true
        self.m_bottomUI:showAverageBet()

        if self:getCurIsFirstTriggrSuperFree() then
            local selfData = self.m_runSpinResultData.p_selfMakeData
            if selfData and selfData.initBonusCoins then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                local order = self.RANDOM_ADD_BONUS_EFFECT
                selfEffect.p_effectOrder = order
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.RANDOM_ADD_BONUS_EFFECT -- 动画类型
            end
        end
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Start_Start)
    end

    if isAuto then
        return self:showDialog(viewName, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        return self:showDialog(viewName, ownerlist, func)
    end
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenBingoldKoiMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("BingoldKoiSounds/music_BingoldKoi_over_fs.mp3")
    
    if self.m_isSuperFree then
        self:addSuperFreeOverEffect()
    else
        if self.freeSpinOverRun then
            self:addFreeOverEffect()
            self.freeSpinOverRun = false 
        end
    end
    
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local playClickFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Click_Btn)
        if self.m_isSuperFree then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Super_Over_Over)
            self:changeBottomBgSpine(1)
            self.m_gameBg:runCsbAction("switch", false, function()
                self:changeBgSpine(1)
            end)
            self.m_baseFreeSpinBar:runCsbAction("over", false)
            self.m_collectBar:playBaseIdle()
            self:refreshCollectBar(true, nil, true)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Over_Over)
        end
    end
    if self.m_isSuperFree then
        self:superOverClearBonus(false)
    end
    if globalData.slotRunData.lastWinCoin > 0 then
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            if self.m_isSuperFree then
                self.m_bingoControl:recoveryBonusZorder()
                self.m_bottomUI:hideAverageBet()
                self.m_isSuperFree = false
                --还原中心wild倍数
                self.m_runSpinResultData.p_selfMakeData.wildMulti = 0
                self:triggerFreeSpinOverCallFun()
            else
                self:showCutSceneAni(false, nil, function()
                    self.m_baseFreeSpinBar:setVisible(false)
                    self:changeBgSpine(1)
                    self.m_bottomUI:hideAverageBet()
                    -- self:triggerFreeSpinOverCallFun()
                    self.m_isSuperFree = false
                    --还原中心wild倍数
                    self.m_runSpinResultData.p_selfMakeData.wildMulti = 0
                end)
            end
        end)
        view:setBtnClickFunc(playClickFunc) 
    else
        local hlSpine = util_spineCreate("BingoldKoi_tanban_hl",true,true)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_FG_NoWin_Start)
        local view = self:showFreeSpinOverNoWin(function()
            if self.m_isSuperFree then
                self.m_bingoControl:recoveryBonusZorder()
                self.m_bottomUI:hideAverageBet()
                self.m_isSuperFree = false
                --还原中心wild倍数
                self.m_runSpinResultData.p_selfMakeData.wildMulti = 0
            else
                self:showCutSceneAni(false, nil, function()
                    self.m_baseFreeSpinBar:setVisible(false)
                    self:changeBgSpine(1)
                    self.m_bottomUI:hideAverageBet()
                    self.m_isSuperFree = false
                    --还原中心wild倍数
                    self.m_runSpinResultData.p_selfMakeData.wildMulti = 0
                end)
            end
        end)
        view:setBtnClickFunc(playClickFunc)
        util_spinePlay(hlSpine,"animation",true)
        view:findChild("hll"):addChild(hlSpine)
        util_setCascadeOpacityEnabledRescursion(view, true)
    end
end

function CodeGameScreenBingoldKoiMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FeatureOver",nil,_func)
    return view
end

function CodeGameScreenBingoldKoiMachine:showFreeSpinOver(coins, num, func)
    -- self:clearCurMusicBg()
    local view
    if coins == 0 then
        view = self:showDialog("FeatureOver", {}, func)
    else
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

        local viewName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
        local extraData = self.m_runSpinResultData.p_fsExtraData
        if self.m_isSuperFree  then
            globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Super_Over_Start, 3, 0, 1)
            viewName = "SuperBingoOver"
        else
            globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_Over_Start, 3, 0, 1)
        end

        view = self:showDialog(viewName, ownerlist, func)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},691)
    end

    return view
    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

--superFreeSpin弹板结束后添加的事件
function CodeGameScreenBingoldKoiMachine:addSuperFreeOverEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.superEndBonusCoins then
        for i=#self.m_gameEffects ,1,-1 do
            local effect = self.m_gameEffects[i]
            if effect.p_effectType == GameEffect.EFFECT_BIGWIN or
            effect.p_effectType == GameEffect.EFFECT_MEGAWIN or
            effect.p_effectType == GameEffect.EFFECT_EPICWIN then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.SUPER_RANDOM_ADD_BONUS_EFFECT
                table.insert(self.m_gameEffects,i+1, selfEffect)
                selfEffect.p_selfEffectType = self.SUPER_RANDOM_ADD_BONUS_EFFECT -- 动画类型
            end
        end
    end
end

--freeSpin弹板结束后添加的事件
function CodeGameScreenBingoldKoiMachine:addFreeOverEffect()
    if self:getCurIsFreeGameLastSpin() then
        for i=#self.m_gameEffects ,1,-1 do
            local effect = self.m_gameEffects[i]
            if effect.p_effectType == GameEffect.EFFECT_BIGWIN or
            effect.p_effectType == GameEffect.EFFECT_MEGAWIN or
            effect.p_effectType == GameEffect.EFFECT_EPICWIN then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.RANDOM_ADD_BONUS_EFFECT
                table.insert(self.m_gameEffects,i+1, selfEffect)
                selfEffect.p_selfEffectType = self.RANDOM_ADD_BONUS_EFFECT -- 动画类型
                break
            end
        end
    end
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBingoldKoiMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end


    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBingoldKoiMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --判断这次spin连线的话，autospin时间不需要根据赢钱去增加
    self.m_curLineRandom = false
    --判断是否是bingo加钱（底部UI）
    self.collectBingo = false
    local isBonus = false
    if self:curIsTriggerGameOther() then
        isBonus = true
    end
    self.m_isBonusTrigger = isBonus
    self.freeSpinOverRun = false

    local isBingoLine = false
    --bingo连线
    if selfData and selfData.bingoLines then
        self.m_curLineRandom = true
        --添加触发，触发要先播放
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.TRIGGER_BINGO_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.TRIGGER_BINGO_EFFECT -- 动画类型

        --添加连线
        local selfEffect_1 = GameEffectData.new()
        selfEffect_1.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect_1.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        if isBonus then
            selfEffect_1.p_effectOrder = GameEffect.EFFECT_BONUS + 1
        end
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect_1
        selfEffect_1.p_selfEffectType = self.BINGO_LINE_EFFECT -- 动画类型
        isBingoLine = true 

        --添加收集
        local selfEffect_2 = GameEffectData.new()
        selfEffect_2.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect_2.p_effectOrder = selfEffect_1.p_effectOrder + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect_2
        selfEffect_2.p_selfEffectType = self.COLLECT_TOP_BONUS_EFFECT -- 动画类型
    end

    self.m_isBingoLine = isBingoLine

    --initBonusCoins 随机向bingo盘添加bonus信号(每个bet第一次spin和消除bingo线后会随机添加)
    --normalBonusCoins superfree中每次spin都会先随机添加bonus
    if selfData and selfData.initBonusCoins and not self:getCurIsFirstTriggrSuperFree() and not self:getCurIsFreeGameLastSpin() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        local order = self.RANDOM_ADD_BONUS_EFFECT
        --执行完连线后才随机添加bonus
        if isBingoLine and not self.m_isSuperFree then
            order = GameEffect.EFFECT_LINE_FRAME + 4
            if isBonus then
                order = GameEffect.EFFECT_BONUS + 3
            end
        end
        selfEffect.p_effectOrder = order
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.RANDOM_ADD_BONUS_EFFECT -- 动画类型
    end

    --轮盘上滚出bonus图标,收集到bingo盘
    if selfData and selfData.bonusCoins then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型

        for i=1, #selfData.bonusCoins do
            self.m_curSpinCollectBonus[#self.m_curSpinCollectBonus+1] = selfData.bonusCoins[i]
        end
    end

    --刷新轮盘中心wild倍数显示
    if self:getCurrSpinMode() == FREE_SPIN_MODE and selfData and selfData.wildMulti then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.UPDATE_WILD_MUTILPLE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.UPDATE_WILD_MUTILPLE_EFFECT -- 动画类型
    end

    --如果再super中有随机添加，并且没有收集也没用连线，需要刷新一次即将连线标志
    if self.m_isSuperFree and not isBingoLine and not selfData.bonusCoins and selfData.normalBonusCoins then
        self.m_bingoControl:refreshRightBingoLight()
    end
end

function CodeGameScreenBingoldKoiMachine:getCurSpinCollectBonus()
    return self.m_curSpinCollectBonus
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBingoldKoiMachine:MachineRule_playSelfEffect(effectData)
    --收集bonus图标到bingo盘
    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then

        self:collectBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.RANDOM_ADD_BONUS_EFFECT then --随机添加bonus图标
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self:randomAddBonusToBingo(selfData.initBonusCoins, true, true, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    elseif effectData.p_selfEffectType == self.UPDATE_WILD_MUTILPLE_EFFECT then --刷新中心wild分数
        self:refreshWildMutiple(function()
            
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.TRIGGER_BINGO_EFFECT then --bingo触发
        self:triggerBingoLine(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.BINGO_LINE_EFFECT then --bingo连线
        self:showBingoLine(function()

            self:checkNotifyUpdateWinCoin()
            --转盘结束检测大赢
            -- if self.m_isBonusWin then
                
                if not self:checkHasBigWin() then
                    --检测大赢
                    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS, true)
                end
            -- end
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if self.m_isSuperFree and self.m_runSpinResultData.p_fsExtraData.avgBet then
                lineBet = self.m_runSpinResultData.p_fsExtraData.avgBet
            end
            local betData = self.m_betData
            local bingoData = {}
            if betData[tostring( toLongNumber(lineBet) )] then
                bingoData = betData[tostring(toLongNumber(lineBet))]
            end

            --移除旧数据
            bingoData.oldBingoReels = nil
            if self.m_superBingoData then
                self.m_superBingoData.oldBingoReels = nil
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_TOP_BONUS_EFFECT then
        self:collectTopBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.FREESPIN_OVER_BINGO_EFFECT then --freespin结束后右边bingo盘再下潜，遮罩消失（要求）
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self:showBingoWinViewLater(selfData.bingoLines, self.m_isSuperFree, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.SUPER_RANDOM_ADD_BONUS_EFFECT then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self:randomAddBonusToBingo(selfData.superEndBonusCoins, true, true, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

--[[
    收集bonus图标到bingo盘
]]
function CodeGameScreenBingoldKoiMachine:collectBonus(func)
    if self.m_gameEffects and #self.m_gameEffects > 0 then
        for i=#self.m_gameEffects ,1,-1 do
            local effect = self.m_gameEffects[i]
            if effect.p_effectType == GameEffect.EFFECT_LINE_FRAME then
                table.remove(self.m_gameEffects, i)
                --关卡内有bingo连线时，收集和连线同时播放，且只播放一次
                self:showLineFrame()
                if self.m_isBingoLine then
                    performWithDelay(self.m_scWaitNode, function()
                        self:clearWinLineEffect()
                    end, 60/30)
                end
                break
            end
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local endCallFunc = function(_isSkip)
        if type(func) == "function" then
            --刷新bingo盘
            self:refreshBingoReel(selfData.bonusCoins, true, true)
            local isPlayLight = true
            if selfData.bingoLines then
                isPlayLight = false
            end
            self.m_bingoControl:playBonusBuLing(selfData.bonusCoins, func, _isSkip, isPlayLight)
        end
    end
    
    --轮盘上滚出bonus图标,收集到bingo盘
    if selfData and selfData.bonusCoins then
        local allCount = #selfData.bonusCoins
        for i,coinData in ipairs(selfData.bonusCoins) do
            local isLast = false
            local posData = self:getRowAndColByPos(coinData.loc)
            local iCol,iRow = posData.iY,posData.iX

            if i == allCount then
                isLast = true
            end
            
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol,iRow)
            if respinNode and respinNode.m_baseFirstNode then
                local endNode = self.m_bingoControl:getBonusAniByPos(iCol,iRow)
                self:flyBonusAni(respinNode.m_baseFirstNode, endNode, isLast, endCallFunc)
            end
        end
    end
end

--[[
    收集bonus飞行动画
]]
function CodeGameScreenBingoldKoiMachine:flyBonusAni(symbolNode,endNode,isLast,func)
    
    local isLast = isLast
    local func = func
    
    performWithDelay(self.m_scWaitNode, function()
        local flyNode = util_spineCreate("Socre_BingoldKoi_BingoBonus",true,true)
        util_spinePlay(flyNode,"fly4",false)
        --TODO
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self.m_respinView:getRespinEndNode(iRow, iCol)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_BONUS then
                    slotNode:runAnim("fly3", false, function()
                        slotNode:runAnim("idleframe", true)
                    end)
                end
            end
        end
        
        local startPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
        local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

        self.m_collectNodeTbl[#self.m_collectNodeTbl+1] = flyNode
        if isLast then
            self.m_soundFlyBonus = gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_FlyAndFeed,false)
            self:setSkipData(func, true)
        end

        local midPos = 12
        local clipTarPos = util_getOneGameReelsTarSpPos(self, midPos)
        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
        local nodePos = self.m_effectNode:convertToNodeSpace(worldPos)

        self.m_effectNode:addChild(flyNode)
        -- flyNode:setPosition(cc.p(nodePos.x, nodePos.y-70))
        flyNode:setPosition(startPos)

        local actionList = {}
        local delayTime = 19/30
        local disPosX, disPosY = 100, 300
        local bezier = {}
        bezier[1] = cc.p(startPos.x, startPos.y)
        bezier[2] = cc.p(startPos.x + disPosX, startPos.y + disPosY)
        bezier[3] = endPos
        actionList[#actionList+1] = cc.DelayTime:create(7/30)
        actionList[#actionList+1] = cc.MoveTo:create(delayTime, endPos)
        -- local bezierTo = cc.BezierTo:create(delayTime, bezier)
        -- actionList[#actionList+1] = cc.EaseSineInOut:create(bezierTo)
        actionList[#actionList+1] = cc.CallFunc:create(function()
            if isLast and type(func) == "function" then
                self.m_collectNodeTbl = {}
                self:setSkipData(func, false)
                func()
            end
            flyNode:removeFromParent()
        end)

        local seq = cc.Sequence:create(actionList)
        flyNode:runAction(seq)
    end, 10/30)
end

--设置飞行的bonus和callFunc，在点击的时候跳过移除
function CodeGameScreenBingoldKoiMachine:setSkipData(func, _state)
    self.m_skipFunc = func
    self.m_skip_click:setVisible(_state)
    self.m_bottomUI:setSkipBonusBtnVisible(_state)
end

function CodeGameScreenBingoldKoiMachine:runSkipCollect()
    self.m_skip_click:setVisible(false)
    if type(self.m_skipFunc) == "function" and #self.m_collectNodeTbl > 0 then
        for i=1, #self.m_collectNodeTbl do
            local flyNode = self.m_collectNodeTbl[i]
            if not tolua.isnull(flyNode) then
                flyNode:stopAllActions()
                flyNode:removeFromParent()
                self.m_collectNodeTbl[i] = nil
            end
        end
        self.m_bottomUI:setSkipBonusBtnVisible(false)
        self.m_skipFunc(true)
        self:setSkipData(nil, false)
        self.m_collectNodeTbl = {}
        if self.m_soundFlyBonus then
            gLobalSoundManager:stopAudio(self.m_soundFlyBonus)
            self.m_soundFlyBonus = nil
        end

        --TODO
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self.m_respinView:getRespinEndNode(iRow, iCol)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_BONUS then
                    slotNode:runAnim("idleframe", true)
                end
            end
        end
    end
end

--[[
    随机添加bonus信号
]]
function CodeGameScreenBingoldKoiMachine:randomAddBonusToBingo(bonusData, isUseBonusData, isPlayLine, func)
    self.m_bingoSpine:setVisible(true)
    util_spinePlay(self.m_bingoSpine,"start",false)
    -- if not self.m_maskAni:isVisible() then
        self.m_maskAni:setVisible(true)
        self.m_panel_clipNode:setClippingEnabled(true)
        self.m_maskAni:runCsbAction("start", false, function()
            self.m_maskAni:runCsbAction("idle", true)
        end)
    -- end
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Random_Fly_Bonus)
    self.m_flyNodeTbl = {}
    performWithDelay(self.m_scWaitNode, function()
        if bonusData and #bonusData > 0 then
            for i, coinData in ipairs(bonusData) do
                local posData = self:getRowAndColByPos(coinData.loc)
                local iCol,iRow = posData.iY,posData.iX
                local endNode = self.m_bingoControl:getBonusAniByPos(iCol,iRow)
    
                self.m_waterSpine:setVisible(true)
                util_spinePlay(self.m_waterSpine,"actionframe",false)

                local flyBonusAni = util_createAnimation("BingoldKoi_FlyBonus.csb")
                local flyNode = util_spineCreate("Socre_BingoldKoi_BingoBonus",true,true)
                local flyNode_X = flyBonusAni:findChild("Node_Fly_X")
                local flyNode_Y = flyBonusAni:findChild("Node_Fly_Y")
                
                local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
                self.m_flyNodeTbl[#self.m_flyNodeTbl+1] = flyBonusAni

                local midPos = 12
                local clipTarPos = util_getOneGameReelsTarSpPos(self, midPos)
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                local nodePos = self.m_effectNode:convertToNodeSpace(worldPos)
                nodePos.y = nodePos.y - 70
                flyNode_Y:addChild(flyNode)
                self.m_effectNode:addChild(flyBonusAni)
                flyBonusAni:setPosition(cc.p(nodePos.x, nodePos.y))

                --第一阶段位移
                local offsetX = endPos.x - nodePos.x
                local endPos_X = cc.p(offsetX, 0)
                --第二阶段位移
                local offsetY = endPos.y - nodePos.y
                local endPos_Y = cc.p(0, offsetY)

                util_spinePlay(flyNode,"fly6",false)
                performWithDelay(self.m_scWaitNode, function()
                    local move_X = cc.MoveTo:create(19/30, endPos_X)--cc.EaseIn:create(moveAction, 2), nil)
                    flyNode_X:runAction(move_X)
                    performWithDelay(self.m_scWaitNode, function()
                        local move_Y = cc.EaseIn:create(cc.MoveTo:create(8/30, endPos_Y), 2)
                        local funcAct = cc.CallFunc:create(function ()
                            if i == #bonusData then
                                self:refreshBingoReel(bonusData, isUseBonusData, isPlayLine)
                                self.m_bingoControl:playBonusBuLing(bonusData, function()
                                    if type(func) == "function" then
                                        for j=#self.m_flyNodeTbl, 1, -1 do
                                            local node = self.m_flyNodeTbl[j]
                                            if not tolua.isnull(node) then
                                                node:removeFromParent()
                                                self.m_flyNodeTbl[j] = nil
                                            end
                                        end
                                        self.m_bingoSpine:setVisible(false)
                                        self.m_waterSpine:setVisible(false)
                                        func()
                                    end
                                end)
                                self.m_maskAni:runCsbAction("over", false, function()
                                    self.m_panel_clipNode:setClippingEnabled(false)
                                    self.m_maskAni:setVisible(false)
                                end)
                            end
                            flyBonusAni:setVisible(false)
                        end)
                        local seq = cc.Sequence:create(move_Y,funcAct)
                        flyNode_Y:runAction(seq)
                    end, 9/30)
                end, 7/30)
            end
        end
    end, 10/30)
end

function CodeGameScreenBingoldKoiMachine:getAddRandomBonusTime(_pos)
    local pos = _pos + 1
    local offsetTime = 3/30
    local modNum = math.mod(pos, 5)
    local time = modNum*offsetTime
    return time
end

--[[
    刷新中心wild倍数
]]
function CodeGameScreenBingoldKoiMachine:refreshWildMutiple(func, _onEnter)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local mutilple = selfData.wildMulti or 0

    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(3,3)
    if respinNode then
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode then
            local callFunc = function()
                if type(func) == "function" then
                    func()
                end
            end
            if not _onEnter then
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Wild_Mul)
            end
            if mutilple == 0 then
                symbolNode:runAnim("actionframe", false, function()
                    symbolNode:setLineAnimName("actionframe")
                    callFunc()
                end)
            elseif mutilple == 2 then
                symbolNode:runAnim("switchto", false, function()
                    if symbolNode.p_symbolType then
                        symbolNode:setLineAnimName("actionframe2")
                        callFunc()
                    end
                end)
            elseif mutilple == 3 then
                symbolNode:runAnim("switchto2", false, function()
                    if symbolNode.p_symbolType then
                        symbolNode:setLineAnimName("actionframe3")
                        callFunc()
                    end
                end)
            elseif mutilple == 5 then
                symbolNode:runAnim("switchto3", false, function()
                    if symbolNode.p_symbolType then
                        symbolNode:setLineAnimName("actionframe4")
                        callFunc()
                    end
                end)
            elseif mutilple == 10 then
                symbolNode:runAnim("switchto4", false, function()
                    if symbolNode.p_symbolType then
                        symbolNode:setLineAnimName("actionframe5")
                        callFunc()
                    end
                end)
            end
        end
        
        return
    end

    if type(func) == "function" then
        func()
    end
    
end

--触发bingo
function CodeGameScreenBingoldKoiMachine:triggerBingoLine(_callFunc)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.bingoLines then
        -- bingo震动，superBingo不震动
        local curCount   = self.m_collectData.collect or 0
        local totalCount = self.m_collectData.request or 12
        if curCount > 0 and curCount ~= totalCount then
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end
        end
       

        self.m_bingoControl:setBingoLineZorder(selfData.bingoLines, self.m_isBonusTrigger)
        self.m_bingoControl:hideTipLight()
        self.m_maskAni:setVisible(true)
        self.m_panel_clipNode:setClippingEnabled(true)
        self.m_maskAni:runCsbAction("start", false, function()
            self.m_maskAni:runCsbAction("idle", true)
        end)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Trigger_Bingo)
        self.m_bingoControl:playBingoLineTrigger(selfData.bingoLines, self.m_isBonusTrigger, function()
            self.bingoAni:setVisible(true)
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Show_Bingo)
            self.bingoAni:runCsbAction("actionframe", false, function()
                self.bingoAni:setVisible(false)
                self.bonusBigLineAni:setVisible(true)
                local particle_1 = self.bonusBigLineAni:findChild("Particle_1")
                local particle_2 = self.bonusBigLineAni:findChild("Particle_2")
                particle_1:resetSystem()
                particle_2:resetSystem()
                self.bonusBigLineAni:runCsbAction("actionframe", false, function()
                    particle_1:stopSystem()
                    particle_2:stopSystem()
                    self.bonusBigLineAni:setVisible(false)
                    if type(_callFunc) == "function" then
                        _callFunc()
                    end
                end)
            end)
        end)
    end
end

--收集顶部bonus
function CodeGameScreenBingoldKoiMachine:collectTopBonus(_callFunc)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self:refreshCollectBar(false, function()
        if self:getCurIsFreeGameLastSpin() then
            if type(_callFunc) == "function" then
                self.freeSpinOverRun = true
                _callFunc()
            end
        else
            if type(_callFunc) == "function" then
                _callFunc()
            end
        end
    end)
end

--[[
    bingo连线
]]
function CodeGameScreenBingoldKoiMachine:showBingoLine(func)
    -- self:clearCurMusicBg()
    

    --把右侧连线bonus层级提到遮罩上边
    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    --显示bingo赢钱
    local winCois = 0
    self:showBingoWinView(selfData, 1, winCois, func)
end

function CodeGameScreenBingoldKoiMachine:superOverClearBonus(_isSuperFree)
    --bingo线上的下潜，其余的消失
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local bingoLines = nil
    if selfData and selfData.bingoLines then
        bingoLines = selfData.bingoLines
    else
        bingoLines = {}
    end
    self.m_bingoControl:resetLinePosition()
    self:showBingoWinViewLater(bingoLines, false)
    -- self.m_bingoControl:setBingoSpineLineOver(bingoLines, _isSuperFree)
end

--收集bingo连线之后的接口（封装起来，方便调用）
function CodeGameScreenBingoldKoiMachine:showBingoWinViewLater(bingoLines, isSuperFree, func)
    -- if self.m_isSuperFree and not self:getCurIsFirstTriggrSuperFree() and not self:getCurIsFreeGameLastSpin() then
    if self.m_isSuperFree and not self:getCurIsFirstTriggrSuperFree() and not self:getCurIsFreeGameLastSpin() then
        self.m_bingoControl:refreshRightBingoLight()
    end
    self.m_maskAni:runCsbAction("over", false, function()
        self.m_panel_clipNode:setClippingEnabled(false)
        self.m_maskAni:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
    -- end
    --bingo线上的下潜，其余的消失
    self.m_bingoControl:setBingoSpineLineOver(bingoLines, isSuperFree, function()
        -- if type(func) == "function" then
        --     func()
        -- end
    end)
end

--[[
    bingo赢钱界面
]]
function CodeGameScreenBingoldKoiMachine:showBingoWinView(selfData, index, winCois, func)
    -- local selfData = self.m_runSpinResultData.p_selfMakeData

    if not selfData.bingoLines or index > #selfData.bingoLines then
        if type(func) == "function" then
            func()
        end
        return
    end

    local lineData = selfData.bingoLines[index]

    --显示bingo线下边的金框
    self.m_bingoControl:showBingoBottomLight(lineData)

    self:collectLineCoins(index, lineData,1,winCois,function(winCois)
        if index < #selfData.bingoLines then
            --显示下一条bingo线的赢钱
            self:showBingoWinView(selfData, index + 1, winCois, func)
        else
            self.m_bingoControl:showBingoBottomLight()
            -- local selfData = self.m_runSpinResultData.p_selfMakeData
            if not self.m_isSuperFree then
                self:showBingoWinViewLater(selfData.bingoLines, self.m_isSuperFree)
            else
                if not self:getCurIsFreeGameLastSpin() then
                    self:showBingoWinViewLater(selfData.bingoLines, self.m_isSuperFree)
                end
            end
            
            local coins = self.m_runSpinResultData.p_selfMakeData.bingoWins
            local coins = coins or winCois
            local ownerlist = {}
            ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Bingo_Start)
            local playClickFunc = function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Click_Btn)
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Bingo_Over)
            end
            local view = self:showDialog("BingoOver", ownerlist, function()
                if not self.m_isSuperFree then
                    self.m_bingoControl:recoveryBonusZorder()
                else
                    if not self:getCurIsFreeGameLastSpin() then
                        self.m_bingoControl:recoveryBonusZorder()
                    end
                end
                if type(func) == "function" then
                    func()
                end
            end)
    
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=1,sy=1},691)
            view:setBtnClickFunc(playClickFunc)
        end
    end)
end

--[[
    收集bingo线上的线
]]
function CodeGameScreenBingoldKoiMachine:collectLineCoins(lineIndex, lineData,index,winCois,func)
    --递归出口
    if index > #lineData then
        if type(func) == "function" then
            func(winCois)
        end
        return
    end

    --判断当前的bonus是否应该消失（重叠的话，最后一个消失）
    local isOver = self:getCurBingoLineIsOver(lineIndex, lineData[index].loc)

    winCois = winCois + lineData[index].amount

    local isLastBonus = self:getCurBonusIsLast(lineIndex, index)
    
    self.m_bingoControl:collectBingoLineAni(lineData[index], lineData[index].loc, lineData[index].amount, isOver, isLastBonus, function()
        --jackpot赢钱
        if lineData[index].jackpot > 0 then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_Start)
            self:showJackpotWin(lineData[index].kind,lineData[index].jackpot,function()
                self:collectLineCoins(lineIndex, lineData,index + 1,winCois,func)
            end)
        else
            self:collectLineCoins(lineIndex, lineData,index + 1,winCois,func)
        end
    end)
end

--[[
    显示jackpot赢钱
]]
function CodeGameScreenBingoldKoiMachine:showJackpotWin(jackpotType,coins,func)
    local view = util_createView("CodeBingoldKoiSrc.BingoldKoiJackPotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        func = function()
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
end

--判断当前的bonus是否应该消失（重叠的话，最后一个消失）
function CodeGameScreenBingoldKoiMachine:getCurBingoLineIsOver(lineIndex, pos)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if lineIndex < #selfData.bingoLines then
        local startIndex = lineIndex+1
        for i=startIndex, #selfData.bingoLines do
            local lineData = selfData.bingoLines[i]
            for j=1, #lineData do
                local curPos = lineData[j].loc
                if curPos == pos then
                    return false
                end
            end
        end
    end

    return true
end

--判断当前的bonus是否是最后一个（最后一个等回调消失）
function CodeGameScreenBingoldKoiMachine:getCurBonusIsLast(lineIndex, _index)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if _index == 5 and lineIndex == #selfData.bingoLines then
        return true
    end
    return false
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBingoldKoiMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenBingoldKoiMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenBingoldKoiMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenBingoldKoiMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    延迟回调
]]
function CodeGameScreenBingoldKoiMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

--[[
    更新小块
]]
function CodeGameScreenBingoldKoiMachine:updateReelGridNode(symbolNode)

    if not symbolNode or not symbolNode.p_symbolType  then
        return
    end

    -- if symbolNode.p_symbolType then
    --     symbolNode:setLineAnimName("actionframe")
    --     symbolNode:setIdleAnimName( "idleframe" )
    -- end

    local nodeScore = symbolNode:getChildByName("bonus_tag")
    if nodeScore then
        nodeScore:removeFromParent()
    end
    if symbolNode.p_symbolType == self.SYMBOL_BONUS then
        self:setSpecialNodeScore(symbolNode)
    end
end

function CodeGameScreenBingoldKoiMachine:setSpecialNodeScore(symbolNode)

    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local nodeScore = util_createAnimation("Socre_BingoldKoi_LeftBingoCoins.csb")
    symbolNode:addChild(nodeScore, 100)
    nodeScore:setPosition(cc.p(0, 0))
    nodeScore:setName("bonus_tag")
    
    local score,kind = 1,"normal"

    nodeScore:findChild("money"):setVisible(true)
    nodeScore:findChild("jackpot"):setVisible(false)
    if symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        score,kind = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        
        if kind and kind ~= "normal" then
            nodeScore:findChild("money"):setVisible(false)
            nodeScore:findChild("jackpot"):setVisible(true)

            nodeScore:findChild("mini"):setVisible(kind == "mini")
            nodeScore:findChild("minor"):setVisible(kind == "minor")
            nodeScore:findChild("major"):setVisible(kind == "major")
            nodeScore:findChild("mega"):setVisible(kind == "mega")
            nodeScore:findChild("grand"):setVisible(kind == "grand")
        end
    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) or 1 -- 获取随机分数（本地配置）
    end

    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_isSuperFree and self.m_runSpinResultData.p_fsExtraData.avgBet then
        lineBet = self.m_runSpinResultData.p_fsExtraData.avgBet
    end
    local multi = score
    score = score * lineBet
    score = util_formatCoins(score, 3)

    local label = nodeScore:findChild("m_lb_coins")
    if label then
        if multi >= 5 then
            label:setFntFile("BingoldKoiFont/BingoldKoi_font9.fnt")
        else
            label:setFntFile("BingoldKoiFont/BingoldKoi_font2.fnt")
        end
        label:setString(score)
        self:updateLabelSize({label=label,sx=0.82,sy=0.82},99)
    end
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenBingoldKoiMachine:getReSpinSymbolScore(posIndex)
    local score,kind = 1,"normal"

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.bonusCoins then
        for i,data in ipairs(selfData.bonusCoins) do
            if posIndex == data.loc then
                return data.initCoins,data.initKind
            end
        end
    end

    return score,kind
end

function CodeGameScreenBingoldKoiMachine:randomDownRespinSymbolScore(symbolType)
    local score = self.m_configData:getBnBasePro()

    return score
end

---------------------------------单个滚动相关接口---------------------------------------------
--[[
    显示respin界面
]]
function CodeGameScreenBingoldKoiMachine:showRespinView()
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()
    
    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)
end

--触发respin
function CodeGameScreenBingoldKoiMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = true

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenBingoldKoiMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()
    self.m_initReelFlag = false

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenBingoldKoiMachine:getRespinRandomTypes( )
    local symbolList = { 
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenBingoldKoiMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = false},
        {type = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

-- --重写组织respinData信息
function CodeGameScreenBingoldKoiMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    return storedInfo
end

function CodeGameScreenBingoldKoiMachine:getMatrixPosSymbolType(iRow, iCol)
    local rowCount = #self.m_runSpinResultData.p_reels
    if self.m_initReelFlag and type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(iCol)
        local symbolType = initDatas[iRow]
        return symbolType
    end
    if rowCount == 0 then

        --中间固定为wild
        if iRow == 3 and iCol == 3 then
            return TAG_SYMBOL_TYPE.SYMBOL_WILD
        end

        local symbolType = 0
        local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        symbolType = symbol.p_symbolType
        return symbolType
    end
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end
---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenBingoldKoiMachine:normalSpinBtnCall()
    --暂停中点击了spin不自动开始下一次
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.normalSpinBtnCall then
                self:normalSpinBtnCall()
            end
        end
        return
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    print("触发了 normalspin")

    local time1 = xcyy.SlotsUtil:getMilliSeconds()

    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local isContinue = true
    if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
        if self.m_showLineFrameTime ~= nil then
            local waitTime = time1 - self.m_showLineFrameTime
            if waitTime < (self.m_lineWaitTime * 1000) then
                isContinue = false --时间不到，spin无效
            end
        end
    end

    if not isContinue then
        return
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    -- 引导打点：进入关卡-4.点击spin
    if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1) then
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 4)
    end
    --新手引导相关
    local isComplete = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskStart1, true)
    if isComplete then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS, {1, false})
    end
    if self.m_isWaitingNetworkData == true then -- 真实数据未返回，所以不处理点击
        return
    end

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    local time2 = xcyy.SlotsUtil:getMilliSeconds()
    release_print("normalSpinBtnCall 消耗时间1 .. " .. (time2 - time1))

    if self:getGameSpinStage() == WAIT_RUN then
        return
    end

    self:firstSpinRestMusicBG()

    local isWaitCall = self:MachineRule_SpinBtnCall()
    if isWaitCall == false then
        self:runNextReSpinReel()
    else
        self:setGameSpinStage(WAIT_RUN)
    end

    local timeend = xcyy.SlotsUtil:getMilliSeconds()

    release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")
end

--开始下次ReSpin
function CodeGameScreenBingoldKoiMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    self.m_isBonusWin = false
    self.m_isBingoLine = false
    self.m_isBonusTrigger = false
    self.m_curSpinCollectBonus = {}

    self:resetReelDataAfterReel()
    self:notifyClearBottomWinCoin()
    self.m_collectBar:spinCloseTips()

    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if not self:checkSpecialSpin(  ) and
        self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
            self:getCurrSpinMode() ~= RESPIN_MODE and betCoin > totalCoin and
                self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE  then

        self:operaUserOutCoins()
    else
        if  self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
                self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
                    not self:checkSpecialSpin(  ) then
            
            self:callSpinTakeOffBetCoin(betCoin)
        else
            self:takeSpinNextData()
        end

        --统计quest spin次数
        self:staticsQuestSpinData()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})

        if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
            self:startReSpinRun()
        end
    end
end

--开始滚动
function CodeGameScreenBingoldKoiMachine:startReSpinRun()
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)
    self.m_topSymbolNode:removeAllChildren()
    self:requestSpinReusltData()
    self.m_respinView:startMove()
    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(3,3)
    if respinNode then
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode then
            symbolNode:setLineAnimName("actionframe")
            local curAniName = symbolNode.m_currAnimName
            if curAniName and curAniName ~= "idleframe" then
                symbolNode:runAnim("idleframe", true)
            end
        end
    end
end

function CodeGameScreenBingoldKoiMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        performWithDelay(
            self,
            function()
                self:requestSpinResult()
            end,
            0.5
        )
    else
        self:requestSpinResult()
    end

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage(WAITING_DATA)
    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function CodeGameScreenBingoldKoiMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()
    
    self:setSpecialSpinStates(false )

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

---
-- 处理spin 返回结果
function CodeGameScreenBingoldKoiMachine:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    -- 把spin数据写到文件 便于找数据bug
    if param[1] == true then
        if device.platform == "mac"  then 
            if param[2] and param[2].result then
                release_print("消息返回胡来了")
                -- print(cjson.encode(param[2].result))
            end
        end
        dumpStrToDisk(param[2].result, "------------> result = ", 50)
    else
        dumpStrToDisk({"false"}, "------------> result = ", 50)
    end
    self:checkTestConfigType(param)
    local isOpera = self:checkOpearReSpinAndSpecialReels(param) -- 处理respin逻辑
    if isOpera == true then
        return
    end

    if param[1] == true then -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else -- 处理spin失败
        self:checkOpearSpinFaild(param)
    end
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenBingoldKoiMachine:checkOpearReSpinAndSpecialReels(param)
    if param[1] == true then
        local spinData = param[2]
        -- print("respin"..cjson.encode(param[2]))
        if spinData.action == "SPIN" then
            self:operaUserInfoWithSpinResult(param)

            self.m_isWaitingNetworkData = false

            self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
            self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

            --刷新本地存储数据
            self:updateLocalData()

            self:MachineRule_RestartProbabilityCtrl()
            
            self:getRandomList()

            self:setGameSpinStage(GAME_MODE_ONE_RUN)

            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            
            --可以在这里处理预告中奖
            
            self:stopRespinRun()

        end
    else
        --TODO 佳宝 给与弹板玩家提示。。
        gLobalViewManager:showReConnect(true)
    end
    return true
end

---判断结算
function CodeGameScreenBingoldKoiMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)

    self:updateQuestUI()

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    -- self:checkRestSlotNodePos()

    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()
end

function CodeGameScreenBingoldKoiMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    --没有bingo连线或触发bonus时刷新下方赢钱
    if not self.m_isBingoLine or self.m_isBonusTrigger then
        self:checkNotifyUpdateWinCoin()
    end
    

    self.m_lineSlotNodes = {}
    self.m_lineRespinNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框

        showLienFrameByIndex()
    else

        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

function CodeGameScreenBingoldKoiMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
        bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex = 1, #self.m_lineRespinNodes do
                local checkNode = self.m_lineRespinNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineRespinNodes[#self.m_lineRespinNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end
            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig

                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY,symPosData.iX)

                checkAddLineSlotNode(respinNode)

                if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType then
                    if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                        self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = respinNode.m_baseFirstNode
                    end
    
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = respinNode.m_baseFirstNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上(本关提到respinView上)
--
function CodeGameScreenBingoldKoiMachine:changeToMaskLayerSlotNode(respinNode)
    self.m_lineRespinNodes[#self.m_lineRespinNodes + 1] = respinNode

    self.m_respinView:changeRespinNodeLockStatus(respinNode,true,true)
end

function CodeGameScreenBingoldKoiMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineRespinNodes

    for i,respinNode in ipairs(self.m_lineRespinNodes) do
        self.m_respinView:changeRespinNodeLockStatus(respinNode,false)
        if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType then
            respinNode.m_baseFirstNode:runIdleAnim()
        end
    end

    self.m_lineRespinNodes = {}
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenBingoldKoiMachine:resetReelDataAfterReel()
    self.m_waitChangeReelTime = 0

    --添加线上打印
    local logName = self:getModuleName()
    if logName then
        release_print("beginReel ... GameLevelName = " .. logName)
    else
        release_print("beginReel ... GameLevelName = nil")
    end

    self:stopAllActions()
    self:beforeCheckSystemData()
    -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
    self.m_nScatterNumInOneSpin = 0
    self.m_nBonusNumInOneSpin = 0

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager.p_ViewLayer })
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        self.m_gameEffects[i] = nil
    end

    self:clearWinLineEffect()

    self.m_showLineFrameTime = nil

    self:resetreelDownSoundArray()
    self:resetsymbolBulingSoundArray()
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenBingoldKoiMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_respinView:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY,symPosData.iX)
        node:setPosition(util_convertToNodeSpace(respinNode.m_baseFirstNode,self.m_respinView))

        local zOrder = respinNode.m_baseFirstNode:getLocalZOrder() + 10

        if node:getParent() == nil then
            
            self.m_respinView:addChild(node, zOrder, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            node:setLocalZOrder(zOrder)
        end
    end

    self:showEachLineSlotNodeLineAnim( frameIndex )
end

---
-- 显示所有的连线框
--
function CodeGameScreenBingoldKoiMachine:showAllFrame(winLines)
    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0

    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_respinView:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY,symPosData.iX)

                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(util_convertToNodeSpace(respinNode.m_baseFirstNode,self.m_respinView))

                local zOrder = respinNode.m_baseFirstNode:getLocalZOrder() + 10

                if symPosData.iY == 3 then
                    print("zOrder is "..zOrder.." row is "..symPosData.iX)
                end
                checkIndex = checkIndex + 1
                self.m_respinView:addChild(node, zOrder, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

function CodeGameScreenBingoldKoiMachine:clearLineAndFrame()
    if not self.m_respinView then
        return
    end
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_respinView:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end
end

function CodeGameScreenBingoldKoiMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenBingoldKoiMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

function CodeGameScreenBingoldKoiMachine:getWinCoinTime()
    local showTime = CodeGameScreenBingoldKoiMachine.super.getWinCoinTime(self)
    if self.m_curLineRandom then
        showTime = 0
        self.m_curLineRandom = false
    end
    return showTime
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenBingoldKoiMachine:checkFeatureOverTriggerBigWin(winAmonut, feature, isCurentLase)
    if winAmonut == nil then
        return
    end

    -- if self.m_bProduceSlots_InFreeSpin == true and (feature == GameEffect.EFFECT_RESPIN_OVER or feature == GameEffect.EFFECT_BONUS) then
    --     return
    -- end
    if isCurentLase and self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    if self.m_isSuperFree and self.m_runSpinResultData.p_fsExtraData.avgBet then
        lTatolBetNum = self.m_runSpinResultData.p_fsExtraData.avgBet
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i = 1, #self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert(self.m_gameEffects, i + 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, i + 2, effectData)
                break
            end
        end
        if isAddEffect == false then
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert(self.m_gameEffects, 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, 2, effectData)
            end
        end
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end


--判断当前是否为free或者super下最后一次spin
function CodeGameScreenBingoldKoiMachine:getCurIsFreeGameLastSpin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

--判断当前是否为刚开始super，还没有spin
function CodeGameScreenBingoldKoiMachine:getCurIsFirstTriggrSuperFree()
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.kind and extraData.kind == "super" and
    self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsTotalCount and
    self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
        return true
    end
    return false
end

--判断这次spin数据里是否有scatter（仅判断快停落地音效）
function CodeGameScreenBingoldKoiMachine:getCurReelDataHaveScatter()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and iCol < 4 then
                return true
            end
        end
    end
    return false
end

--判断当前列scatter是否播放落地
function CodeGameScreenBingoldKoiMachine:getCurSymbolIsPlayBuLing(_slotNode)
    if _slotNode.p_cloumnIndex < 4 then
        return true
    else
        local lastCol = _slotNode.p_cloumnIndex - 1
        local bonusCount = 0
        local isPlay = false
        for iCol = 1, lastCol do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    bonusCount = bonusCount + 1
                end
            end
        end
    
        if _slotNode.p_cloumnIndex == 4 and bonusCount > 0 then
            isPlay = true
        elseif _slotNode.p_cloumnIndex == 5 and bonusCount > 1 then
            isPlay = true
        end
        return isPlay
    end
end

--判断当前是否触发了bonus玩法
function CodeGameScreenBingoldKoiMachine:curIsTriggerGameOther()
    local featureData = self.m_runSpinResultData.p_features or {}
    for key,featureID in pairs(featureData) do
        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            return true
        end
    end
    return false
end

--判断当前是否触发了freegame
function CodeGameScreenBingoldKoiMachine:curIsTriggerFreeGame()
    local featureData = self.m_runSpinResultData.p_features or {}
    for key,featureID in pairs(featureData) do
        if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
            return true
        end
    end
    return false
end

function CodeGameScreenBingoldKoiMachine:playScatterTipMusicEffect()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_More_Trigger)
    else
        if self.m_ScatterTipMusicPath ~= nil then
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 4, 0, 1)
        end
    end
end

function CodeGameScreenBingoldKoiMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenBingoldKoiMachine:getBottomUi()
    return self.m_bottomUI
end

--BottomUI接口
function CodeGameScreenBingoldKoiMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenBingoldKoiMachine:playhBottomLight(_endCoins, _endCallFunc)
    self.collectBingo = true
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

function CodeGameScreenBingoldKoiMachine:getCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

function CodeGameScreenBingoldKoiMachine:tipsBtnIsCanClick()
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_isRunningEffect == true
    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local features = self.m_runSpinResultData.p_features or {}
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end

    return true
end

function CodeGameScreenBingoldKoiMachine:setCurMusicState()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self.m_isSuperFree then
            self:resetMusicBg(nil, self.m_publicConfig.Music_SupeerFG_Bg)
        else
            self:resetMusicBg(nil, self.m_publicConfig.Music_FG_Bg)
        end
    else
        self:resetMusicBg(nil, self.m_publicConfig.Music_Base_Bg)
    end
end

---
-- 获取关卡下对应的free spin bg
--BigMegaView
function CodeGameScreenBingoldKoiMachine:getFreeSpinMusicBG()
    if self.m_isSuperFree then
        return self.m_publicConfig.Music_SupeerFG_Bg
    end
    return self.m_fsBgMusicName
end

--@isMustPlayMusic 是否必须播放音乐
--@musicName 需要修改的音乐路径
function CodeGameScreenBingoldKoiMachine:resetMusicBg(isMustPlayMusic, musicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    self:resetCurBgMusicName(musicName)

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        self:clearCurMusicBg()
    end
end
-------------------------------------------------------------------------------------

return CodeGameScreenBingoldKoiMachine






