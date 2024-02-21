---
-- island li
-- 2019年1月26日
-- CodeGameScreenScarabChestMachine.lua
-- 
-- 玩法：
--[[
    条件：
        1.wildbonus：会出现在任何位置
        2.scatter：会出现在任何位置
    收集玩法：
        1.free下收集jackpot；收集进度满了直接获得对应jackpot档位
    base:
        1.3个scatter触发free玩法
        2.3个及以上wildbonus图标触发bonus玩法（bonus上的倍数 X 连线的钱 = 总钱）
        3.三档jackpot：grand、major、minor
    free：
        1.fg内每次spin的连线赢钱会累计在基底池内
        2.fg里bonus玩法倍数累计；最后X基底
        3.fg里出scatter就是freeMore
]]
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "ScarabChestPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenScarabChestMachine = class("CodeGameScreenScarabChestMachine", BaseNewReelMachine)

CodeGameScreenScarabChestMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenScarabChestMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenScarabChestMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenScarabChestMachine.SYMBOL_SCORE_SPECIAL_WILD = 93
CodeGameScreenScarabChestMachine.SYMBOL_SCORE_JACKPOT_MINOR = 101
CodeGameScreenScarabChestMachine.SYMBOL_SCORE_JACKPOT_MAJOR = 102
CodeGameScreenScarabChestMachine.SYMBOL_SCORE_JACKPOT_GRAND = 103

-- 自定义动画的标识
CodeGameScreenScarabChestMachine.EFFECT_WILD_PLAY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2  --wild玩法
CodeGameScreenScarabChestMachine.EFFECT_SPECIAL_WILD_PLAY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3  --特殊wild玩法
CodeGameScreenScarabChestMachine.EFFECT_FREE_WILD_PLAY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4  --free-wild玩法
CodeGameScreenScarabChestMachine.EFFECT_FREE_LINE_PLAY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1  --free-连线玩法
CodeGameScreenScarabChestMachine.EFFECT_JACKPOT_COLLECT_PLAY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6  --free-jackpot收集

-- 构造函数
function CodeGameScreenScarabChestMachine:ctor()
    CodeGameScreenScarabChestMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeScarabChestSrc.ScarabChestSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("CodeScarabChestSrc/ScarabChestLongRunControl",self) 

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    -- 大赢光效
    self.m_isAddBigWinLightEffect = true

    -- 默认宝箱一级
    self.m_curBoxLevel = 1

    -- 底部加钱标记
    self.m_addBotomCoins = true

    --假滚拖尾
    self.m_falseParticleTbl = {}

    -- 当前scatter落地的个数
    self.m_curScatterBulingCount = 0
    -- free结束播放音效的index
    self.m_freeOverSoundIndex = 1
    -- base收集基底播放音效index
    self.m_baseCollectSoundIndex = 1

    -- 是否加拖尾
    self.m_isAddTuoWei = false

    --init
    self:initGame()
end

function CodeGameScreenScarabChestMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ScarabChestConfig.csv", "ScarabChestConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenScarabChestMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ScarabChest"  
end

--小块
function CodeGameScreenScarabChestMachine:getBaseReelGridNode()
    return "CodeScarabChestSrc.ScarabChestSlotNode"
end

function CodeGameScreenScarabChestMachine:getBottomUINode()
    return "CodeScarabChestSrc.ScarabChestBottomNode"
end

function CodeGameScreenScarabChestMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView()

    -- reel条
    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Node_base_reel")
    self.m_reelBg[2] = self:findChild("Node_FG_reel")

    -- 背景
    self.m_bgType = {}
    self.m_bgType[1] = self.m_gameBg:findChild("Base")
    self.m_bgType[2] = self.m_gameBg:findChild("Bonus")
    self.m_bgType[3] = self.m_gameBg:findChild("FG")

    -- 宝箱cocos动画
    self.m_boxAni = util_createAnimation("ScarabChest_baoxiang.csb")
    self:findChild("Node_baoxiang"):addChild(self.m_boxAni)

    -- 基底
    self.m_baseCoinsView = util_createView("CodeScarabChestSrc.ScarabChestBaseCoinsView", self)
    self.m_boxAni:findChild("Node_jidi"):addChild(self.m_baseCoinsView)
    self.m_baseCoinsView:setVisible(false)

    -- 乘倍
    self.m_mulView = util_createView("CodeScarabChestSrc.ScarabChestMulView", self)
    self.m_boxAni:findChild("Node_chengbei"):addChild(self.m_mulView)
    self.m_mulView:setVisible(false)

    -- base下玩法提示
    self.m_basePlayTipsView = util_createView("CodeScarabChestSrc.ScarabChestBasePlayTipsView", self)
    self:findChild("Node_UItishi"):addChild(self.m_basePlayTipsView)
    self.m_basePlayTipsView:setVisible(false)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "ScarabChest_yqq")

    --特效层
    self.m_effectNode = self:findChild("Node_topEffect")
   
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
    
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenScarabChestMachine:initSpineUI()
    -- 宝箱动画
    self.m_boxSpine = util_spineCreate("ScarabChest_baoxiang",true,true)
    self.m_boxAni:findChild("baoxiang"):addChild(self.m_boxSpine)
    util_spinePlay(self.m_boxSpine, "idle", true)

    -- 收集栏
    self.m_collectBarView = util_createView("CodeScarabChestSrc.ScarabChestCollectBarView", self)
    util_spinePushBindNode(self.m_boxSpine, "gd1", self.m_collectBarView)

    -- 宝箱上的钱
    self.m_boxCoinsView = util_createView("CodeScarabChestSrc.ScarabChestBoxCoinsView", self)
    util_spinePushBindNode(self.m_boxSpine, "gd2", self.m_boxCoinsView)
    self.m_boxCoinsView:setVisible(false)

    -- 结算时的钱
    self.m_freeEndCoinsSpineTbl = {}
    for i=1, 8 do
        local spineName = "ScarabChest_baoxiang_jinbi"..i
        self.m_freeEndCoinsSpineTbl[i] = util_spineCreate(spineName,true,true)
        self:findChild("Node_jinbi"):addChild(self.m_freeEndCoinsSpineTbl[i])
        self.m_freeEndCoinsSpineTbl[i]:setVisible(false)
    end

    -- 预告中奖
    self.m_yuGaoSpine = util_spineCreate("ScarabChest_yugao2",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpine)
    self.m_yuGaoSpine:setVisible(false)

    -- wild预告中奖
    self.m_yuGaoWildSpine = util_spineCreate("ScarabChest_yugao",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoWildSpine)
    self.m_yuGaoWildSpine:setVisible(false)

    -- 大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    worldPos.x = display.width/2
    self.m_bigWinSpine = util_spineCreate("ScarabChest_bigwin",true,true)
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setVisible(false)

    -- 底部的大赢
    self.m_bottomBigWinSpin = util_spineCreate("ScarabChest_yingqian",true,true)
    self.m_bottomBigWinSpin:setScale(self.m_machineRootScale)
    self.m_bottomBigWinSpin:setPosition(worldPos)
    self:addChild(self.m_bottomBigWinSpin, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bottomBigWinSpin:setVisible(false)

    -- 指示
    self.m_zhishiSpine = util_spineCreate("ScarabChest_zhishi",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_zhishiSpine)
    self.m_zhishiSpine:setVisible(false)

    -- freeMore动画
    self.m_freeMoreSpine = util_spineCreate("ScarabChest_yugao2",true,true)
    self:findChild("Node_FGmore"):addChild(self.m_freeMoreSpine)
    self.m_freeMoreSpine:setVisible(false)

    -- freeMore上的次数字体
    local freeMoreCountAni = util_createAnimation("Socre_ScarabChest_FreeMoreCount.csb")
    self.m_freeMoreCountText = freeMoreCountAni:findChild("m_lb_num")
    util_spinePushBindNode(self.m_freeMoreSpine, "more_shuzi", freeMoreCountAni)

    self:runCsbAction("idle", true)
    self:changeBgSpine(1)
end


function CodeGameScreenScarabChestMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        -- globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Enter_Game, 3, 0, 1)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Enter_Game)
    end)
end

function CodeGameScreenScarabChestMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenScarabChestMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenScarabChestMachine:initGameUI()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeUiState(true)
    else
        self.m_jackPotBarView:resetShowJackpotState(false)
        self.m_boxAni:runCsbAction("idle", true)
        self.m_basePlayTipsView:showStart(true)
    end
end

-- freeUI布局
function CodeGameScreenScarabChestMachine:showFreeUiState(_onEnter)
    local onEnter = _onEnter
    self:changeBgSpine(3)
    -- 进free打开箱子
    util_spinePlay(self.m_boxSpine, "idle1", true)
    self.m_baseFreeSpinBar:changeFreeSpinByCount()
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_basePlayTipsView:setVisible(false)

    self.m_boxAni:runCsbAction("idle_free", true)
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local totalMulti = selfData.freespinExtra.total_multi
    local charLevel = selfData.charLevel
    local coinLevel = selfData.coinLevel
    local baseCoins = selfData.freespinExtra.base
    local jackpotList = selfData.freespinExtra.jackpotList
    local totalLineWin = selfData.freespinExtra.totalLineWin
    local finalWin = selfData.freespinExtra.finalWin

    -- 基底
    self.m_baseCoinsView:setBaseCoins(totalLineWin, true)
    self.m_baseCoinsView:setVisible(true)
    if onEnter then
        self.m_baseCoinsView:setIdle()
        -- 总钱数显示
        self.m_boxCoinsView:setLevelCoins(charLevel, coinLevel)
        self.m_boxCoinsView:setWinCoins(finalWin, onEnter)
        -- self.m_boxCoinsView:playJumpCoinsIdle()
    else
        self:runCsbAction("actionframe_guochang", false, function()
            self:runCsbAction("idle", true)
        end)
        self.m_baseCoinsView:enterFreeStart()
        self.m_bottomUI:checkClearWinLabel()
    end
    
    -- 总倍数显示
    self.m_mulView:setMul(totalMulti)
    self.m_mulView:setIdle()

    -- 三类jackpot的收集进度，依次为minor，major和grand
    -- 客户端反过来
    local tempList = {}
    tempList[1] = clone(jackpotList[3])
    tempList[2] = clone(jackpotList[2])
    tempList[3] = clone(jackpotList[1])
    self.m_jackPotBarView:resetShowJackpotState(true)
    self.m_jackPotBarView:initShowCollectNode(tempList)
end

function CodeGameScreenScarabChestMachine:addObservers()
    CodeGameScreenScarabChestMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

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
            bgmType = "fg"
        else
            bgmType = "base"
        end

        local soundName = "ScarabChestSounds/music_ScarabChest_last_win_".. bgmType.."_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenScarabChestMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenScarabChestMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenScarabChestMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0

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
            local ratio = display.height / display.width
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            if ratio == 1228 / 768 then
                mainScale = mainScale * 1.02
                tempPosY = 3
            elseif ratio >= 1152/768 and ratio < 1228/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            elseif ratio >= 920/768 and ratio < 1152/768 then
                local mul = (1152 / 768 - display.height / display.width) / (1152 / 768 - 920 / 768)
                mainScale = mainScale + 0.05 * mul + 0.03--* 1.16
                tempPosY = 25
            elseif ratio < 1152/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(tempPosY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenScarabChestMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_ScarabChest_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_ScarabChest_11"
    elseif symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
        return "Socre_ScarabChest_Wild1"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR then
        return "Socre_ScarabChest_WildBonus_Minor"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR then
        return "Socre_ScarabChest_WildBonus_Major"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_GRAND then
        return "Socre_ScarabChest_WildBonus_Grand"
    end
    
    return nil
end

-- 是否为jackpot类型
function CodeGameScreenScarabChestMachine:getCurSymbolIsJackpot(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR or symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR or symbolType == self.SYMBOL_SCORE_JACKPOT_GRAND then
        return true
    end
    return false
end

-- 是否为wild或者特殊wild类型
function CodeGameScreenScarabChestMachine:getCurSymbolIsWild(_symbolType)
    local symbolType = _symbolType
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
        return true
    end
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenScarabChestMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenScarabChestMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenScarabChestMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

function CodeGameScreenScarabChestMachine:initGameStatusData(gameData)
    CodeGameScreenScarabChestMachine.super.initGameStatusData(self,gameData)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenScarabChestMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenScarabChestMachine:beginReel()
    self.m_curScatterBulingCount = 0
    self.m_isAddTuoWei = true
    self.m_collectBarView:resetCollectWild()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:closeBonusAllAni()
    end
    self.collectBonus = false
    self.m_addBotomCoins = true
    self.m_isJackpot = false
    self.m_isPreFree = false
    CodeGameScreenScarabChestMachine.super.beginReel(self)
end

-- 下次spin关闭宝箱相关的动画
function CodeGameScreenScarabChestMachine:closeBonusAllAni()
    if self.collectBonus then
        self.m_mulView:closeMul()
        self.m_baseCoinsView:closeBaseCoins()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Box_Close_Sound)
        self.m_boxCoinsView:closeBoxCoins()
        self.m_collectBarView:closeCollectCell()
        performWithDelay(self.m_scWaitNode, function()
            self.m_basePlayTipsView:showStart()
        end, 10/60)
        -- 宝箱
        local actName = "actionframe3"
        if self.m_curBoxLevel then
            actName = "actionframe" .. self.m_curBoxLevel+2
        end
        util_spinePlay(self.m_boxSpine, actName, false)
        util_spineEndCallFunc(self.m_boxSpine, actName, function()
            util_spinePlay(self.m_boxSpine, "idle", true)
        end)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenScarabChestMachine:slotOneReelDown(reelCol)
    CodeGameScreenScarabChestMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)

    local curReelCol = reelCol
    --停轮后检查是否有拖尾，有的话直接删除
    for iRow = 1, self.m_iReelRowNum do
        local slotNode = self:getFixSymbol(curReelCol, iRow, SYMBOL_NODE_TAG)
        if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            slotNode:removeTuowei()
        end
    end
end

--[[
    滚轮停止
]]
function CodeGameScreenScarabChestMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenScarabChestMachine.super.slotReelDown(self)
end

function CodeGameScreenScarabChestMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    -- self.m_slotEffectLayer:addChild(reelEffectNode)
    local slotParent = self.m_slotParents[col].slotParent
    if slotParent then
        slotParent:addChild(reelEffectNode)
        reelEffectNode:setTag(1)
    end
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
    -- end
end

function CodeGameScreenScarabChestMachine:setLongAnimaInfo(reelEffectNode, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local reelSize = reelNode:getContentSize()
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    reelEffectNode:setPosition(cc.p(reelSize.width/2,0))
    -- local worldPos, reelHeight, reelWidth = self:getReelPos(col)

    -- -- local pos = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    -- reelEffectNode:setPosition(cc.p(worldPos.x, worldPos.y))
end

---------------------------------------------------------------------------

---
-- 排序m_gameEffects 列表，根据 effectOrder
--
function CodeGameScreenScarabChestMachine:sortGameEffects()
    CodeGameScreenScarabChestMachine.super.sortGameEffects(self)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for i=#self.m_gameEffects ,1,-1 do
            local effect = self.m_gameEffects[i]
            if effect.p_effectOrder == GameEffect.EFFECT_FREE_SPIN then
                table.remove(self.m_gameEffects, i)
                table.insert(self.m_gameEffects, 1, effect)
                break
            end
        end
    end
end

-- 当前是否触发了bonus玩法
function CodeGameScreenScarabChestMachine:isTriggerBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.isBonus then
        return selfData.isBonus
    end
    return false
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenScarabChestMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local freespinExtra = selfData.freespinExtra
    local isBonus = selfData.isBonus
    self.m_isBonus = isBonus
    local jackpotPos = selfData.jackpotPos
    local lineWin = selfData.lineWin
    if isBonus then
        self.collectBonus = true
        self.m_addBotomCoins = false
        if self.m_isPreFree then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_SPECIAL_WILD_PLAY_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_SPECIAL_WILD_PLAY_EFFECT -- 动画类型
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self.collectBonus = false
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_FREE_WILD_PLAY_EFFECT -- 动画类型
        else
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_WILD_PLAY_EFFECT -- 动画类型
        end
    else
        self.m_collectBarView:isNotBonusCancelCollectAct()
    end

    if jackpotPos and next(jackpotPos) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_JACKPOT_COLLECT_PLAY_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_JACKPOT_COLLECT_PLAY_EFFECT -- 动画类型
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if lineWin and lineWin > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_FREE_LINE_PLAY_EFFECT -- 动画类型
        end

        if globalData.slotRunData.freeSpinCount == 0 then
            self.m_addBotomCoins = false
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenScarabChestMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_JACKPOT_COLLECT_PLAY_EFFECT then
        performWithDelay(self.m_scWaitNode, function()
            self:showCollectJackpotPlay(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end, 0.5)
    elseif effectData.p_selfEffectType == self.EFFECT_FREE_LINE_PLAY_EFFECT then
        self:playAddBaseCoins(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, true)
    elseif effectData.p_selfEffectType == self.EFFECT_SPECIAL_WILD_PLAY_EFFECT then
        self:showBonusPlay(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, true)
    elseif effectData.p_selfEffectType == self.EFFECT_WILD_PLAY_EFFECT then
        self:showBonusPlay(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_FREE_WILD_PLAY_EFFECT then
        self:showBonusPlay(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, false, true)
    end
    
    return true
end

-- free有连线赢钱；添加基底
function CodeGameScreenScarabChestMachine:playAddBaseCoins(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local freespinExtra = selfData.freespinExtra
    local charLevel = selfData.charLevel
    local coinLevel = selfData.coinLevel
    -- 当次spin赢的连线钱
    local lineWin = selfData.lineWin
    -- 当前spin赢的总连线钱
    local totalLineWin = freespinExtra.totalLineWin
    -- 当前基底*当前倍数（不包含本次spin的倍数）
    -- local finalWin = freespinExtra.finalWin
    local curFinalWin = (freespinExtra.total_multi - selfData.roundMulti) * totalLineWin
    local jumpTimes = 2.0
    
    local baseParms = {endCoins = totalLineWin, curWinCoins = lineWin, duration = jumpTimes}
    self.m_baseCoinsView:startJumpCouns(baseParms)

    local finalParms = {endCoins = curFinalWin, duration = jumpTimes, charLevel = charLevel, coinLevel = coinLevel}
    self.m_boxCoinsView:startJumpCouns(finalParms)

    performWithDelay(self.m_scWaitNode, function()
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, jumpTimes+0.2)
end

-- 收集Jackpot
function CodeGameScreenScarabChestMachine:showCollectJackpotPlay(_callFunc)
    local callFunc = _callFunc

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local freespinExtra = selfData.freespinExtra
    local jackpotPos = selfData.jackpotPos
    local jackpotHit = freespinExtra.jackpotHit
    local clientJackpotData = {}
    for k, v in pairs(jackpotPos) do
        local tempTbl = {}
        local pos = v[1]
        local symbolType = v[2]
        local fixPos = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        symbolNode:setIdleAnimName("idleframe2")
        tempTbl.p_pos = pos
        tempTbl.p_symbolType = symbolType
        tempTbl.p_rowIndex = fixPos.iX
        tempTbl.p_cloumnIndex = fixPos.iY
        tempTbl.p_symbolNode = symbolNode
        table.insert(clientJackpotData, tempTbl)
    end

    -- 本地排序
    table.sort(clientJackpotData, function(a, b)
        if a.p_cloumnIndex ~= b.p_cloumnIndex then
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
        if a.p_rowIndex ~= b.p_rowIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return false
    end)

    self:collectToTopJackpot(callFunc, clientJackpotData, jackpotHit, 0)
end

-- 收集jackpot
function CodeGameScreenScarabChestMachine:collectToTopJackpot(_callFunc, _clientJackpotData, _jackpotHit, _curIndex)
    local callFunc = _callFunc
    local clientJackpotData = _clientJackpotData
    local jackpotHit = _jackpotHit
    local curIndex = _curIndex + 1
    if curIndex > #clientJackpotData then
        performWithDelay(self.m_scWaitNode, function()
            self.m_effectNode:removeAllChildren()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, 1.0)
        return
    end

    local curJackpotData = clientJackpotData[curIndex]
    local symbolNode = curJackpotData.p_symbolNode
    local jackpotPos = curJackpotData.p_pos
    local curSymbolType = curJackpotData.p_symbolType
    local delayTime = 0.4

    local jackpotType = "Minor"
    local jackpotIndex = 3
    local jackpotCoins = 0
    local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    if curSymbolType == self.SYMBOL_SCORE_JACKPOT_MINOR then
        jackpotIndex = 3
        jackpotType = "Minor"
        jackpotCoins = allJackpotCoins["Minor"]
    elseif curSymbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR then
        jackpotIndex = 2
        jackpotType = "Major"
        jackpotCoins = allJackpotCoins["Major"]
    elseif curSymbolType == self.SYMBOL_SCORE_JACKPOT_GRAND then
        jackpotIndex = 1
        jackpotType = "Grand"
        jackpotCoins = allJackpotCoins["Grand"]
    else
        assert(false, "后端传错值了")
    end

    local startPos = util_convertToNodeSpace(symbolNode, self.m_effectNode)
    local endJackpotNode = self.m_jackPotBarView:getNextNode(jackpotIndex)
    local endPos = util_convertToNodeSpace(endJackpotNode, self.m_effectNode)

    local flyNode = util_createAnimation("ScarabChest_shouji_lizi.csb")
    local particleTbl = {}
    for i=1, 3 do
        particleTbl[i] = flyNode:findChild("Particle_"..i)
        particleTbl[i]:setPositionType(0)
        particleTbl[i]:setDuration(-1)
        particleTbl[i]:resetSystem()
    end
    flyNode:runCsbAction("idle", true)
    flyNode:setPosition(startPos)
    self.m_effectNode:addChild(flyNode)
    flyNode:setVisible(false)

    -- 当前是否显示jackpot弹板
    local isHaveJackpot = false
    local isTriggerJackpot = self.m_jackPotBarView:getCurIsJackpot(jackpotIndex)
    if next(jackpotHit) then
        for k, v in pairs(jackpotHit) do
            if v == curSymbolType then
                isHaveJackpot = true
            end
        end
    end

    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_Jackpot)
        symbolNode:runAnim("shouji", false, function()
            symbolNode:runAnim("idleframe2", true)
        end)
    end)
    -- 第5帧播飞fly
    tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        flyNode:setVisible(true)
    end)
    -- 飞行0.5s（fly动画时长30帧）
    tblActionList[#tblActionList+1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
    -- 反馈
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        for i=1, 3 do
            particleTbl[i]:stopSystem()
        end
        -- flyNode:setVisible(false)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_Jackpot_FeedBack)
        self.m_jackPotBarView:collectCurJackpotNode(jackpotIndex)
    end)
    -- 弹板
    if isTriggerJackpot and isHaveJackpot then
        self.m_isJackpot = true
        -- jackpot上边收集反馈
        tblActionList[#tblActionList+1] = cc.DelayTime:create(41/60)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Trigger_Jackpot)
            self.m_jackPotBarView:playTriggerAction(jackpotIndex)
        end)
        -- 触发1.5s后弹板
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.5)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if not tolua.isnull(flyNode) then
                flyNode:setVisible(false)
            end
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(1.0)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_jackPotBarView:setIdle()
            self:showJackpotView(jackpotCoins, jackpotType, function()
                self:playhBottomLight(jackpotCoins)
                performWithDelay(self.m_scWaitNode, function()
                    -- 收集下一个
                    self:collectToTopJackpot(callFunc, clientJackpotData, jackpotHit, curIndex)
                end, 2.5)
            end)
        end)
    else
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            -- 收集下一个
            self:collectToTopJackpot(callFunc, clientJackpotData, jackpotHit, curIndex)
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.5)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if not tolua.isnull(flyNode) then
                flyNode:setVisible(false)
            end
        end)
    end

    flyNode:runAction(cc.Sequence:create(tblActionList))
end

-- bonus玩法
function CodeGameScreenScarabChestMachine:showBonusPlay(_callFunc, _isRotate, _isFree)
    local callFunc = _callFunc
    local isRotate = _isRotate
    local isFree = _isFree

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wildData = selfData.wildPos
    local clientWildData = {}
    for k, v in pairs(wildData) do
        local tempTbl = {}
        local pos = v[1]
        local mul = v[2]
        local fixPos = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if isRotate then
            -- 先把93信号改成92
            symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
            if symbolNode.p_symbolImage then
                symbolNode.p_symbolImage:removeFromParent()
                symbolNode.p_symbolImage = nil
            end
            symbolNode:runAnim("idleframe3", true)
        end
        tempTbl.p_pos = pos
        tempTbl.p_mul = mul
        tempTbl.p_rowIndex = fixPos.iX
        tempTbl.p_cloumnIndex = fixPos.iY
        tempTbl.p_symbolNode = symbolNode
        table.insert(clientWildData, tempTbl)
    end

    -- 本地排序
    table.sort(clientWildData, function(a, b)
        if a.p_cloumnIndex ~= b.p_cloumnIndex then
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
        if a.p_rowIndex ~= b.p_rowIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return false
    end)

    -- 如果是不带钱的面；需要先翻过来
    if isRotate then
        performWithDelay(self.m_scWaitNode, function()
            self:showBonusRotate(callFunc, clientWildData, 0)
        end, 0.3)
    elseif isFree then
        self:showFreeBoxAndMul(callFunc, clientWildData, selfData)
    else
        self:showBoxAndMul(callFunc, clientWildData, selfData)
    end
end

-- bonus玩法先翻过来
function CodeGameScreenScarabChestMachine:showBonusRotate(_callFunc, _clientWildData, _curIndex)
    local callFunc = _callFunc
    local clientWildData = _clientWildData
    local curIndex = _curIndex + 1
    if curIndex > #clientWildData then
        performWithDelay(self.m_scWaitNode, function()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, 0.5)
        return
    end

    local curWildData = clientWildData[curIndex]
    local symbolNode = curWildData.p_symbolNode
    local curMul = curWildData.p_mul
    local rotateName = "actionframe1"
    if curMul >= 5 then
        rotateName = "actionframe2"
    end

    self:setSpecialNodeScoreWild(symbolNode)
    local nodeScore = symbolNode:getChildByName("wild_tag")
    if not tolua.isnull(nodeScore) then
        util_resetCsbAction(nodeScore.m_csbAct)
        nodeScore:runCsbAction("actionframe1", false, function()
            nodeScore:runCsbAction("idleframe", true)
        end)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_WildRotate_Sound)
    symbolNode:runAnim(rotateName, false, function()
        symbolNode:runAnim("idleframe1", true)
    end)

    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.DelayTime:create(0.7)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:showBonusRotate(callFunc, clientWildData, curIndex)
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- bonus玩法（带钱的）
function CodeGameScreenScarabChestMachine:showBoxAndMul(_callFunc, _clientWildData, _selfData)
    local callFunc = _callFunc
    local clientWildData = _clientWildData
    local selfData = _selfData
    self:setMaxMusicBGVolume()

    local lineWin = selfData.lineWin
    -- 默认宝箱一级
    self.m_curBoxLevel = 1
    local tblActionList = {}

    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 指示动画
        self.m_zhishiSpine:setVisible(true)
        util_spinePlay(self.m_zhishiSpine, "actionframe", false)
        util_spineEndCallFunc(self.m_zhishiSpine, "actionframe", function()
            self.m_zhishiSpine:setVisible(false)
        end)
        if self.m_baseCollectSoundIndex > 2 then
            self.m_baseCollectSoundIndex = 1
        end
        local soundName = self.m_publicConfig.SoundConfig.Music_CollectBaseCoins_Sound[self.m_baseCollectSoundIndex]
        if soundName then
            gLobalSoundManager:playSound(soundName)
        end
        self.m_baseCollectSoundIndex = self.m_baseCollectSoundIndex + 1
    end)
    -- 24帧后出现
    tblActionList[#tblActionList+1] = cc.DelayTime:create(24/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Box_Open_Sound)
        -- 24帧后出现基底
        self.m_baseCoinsView:setBaseCoins(lineWin, true)
        self.m_baseCoinsView:showStart()
        self.m_basePlayTipsView:closeBasePlayTips()

        -- 宝箱
        self.m_boxCoinsView:setVisible(false)
        util_spinePlay(self.m_boxSpine, "actionframe1", false)
        util_spineEndCallFunc(self.m_boxSpine, "actionframe1", function()
            util_spinePlay(self.m_boxSpine, "idle1", true)
        end)
    end)
    -- 基底出现40帧
    tblActionList[#tblActionList+1] = cc.DelayTime:create(40/60)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        -- 切背景
        self:changeBgSpine(1, "switch1")
    end)

    tblActionList[#tblActionList+1] = cc.DelayTime:create(40/30)
    -- 宝箱actionframe1第60帧时，乘倍再弹出
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        -- 乘倍
        self.m_mulView:showStart()
    end)

    -- 宝箱actionframe1时长
    tblActionList[#tblActionList+1] = cc.DelayTime:create(25/30)
    -- 上一动画结束后0.2s
    tblActionList[#tblActionList+1] = cc.DelayTime:create(0.2)
    -- 收集
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:collectFlyBonus(callFunc, clientWildData, selfData, 0)
    end)

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 收集bonus
function CodeGameScreenScarabChestMachine:collectFlyBonus(_callFunc, _clientWildData, _selfData, _curIndex)
    local callFunc = _callFunc
    local clientWildData = _clientWildData
    local selfData = _selfData
    local curIndex = _curIndex + 1
    local charLevel = selfData.charLevel
    local coinLevel = selfData.coinLevel
    if curIndex > #clientWildData then
        self.m_effectNode:removeAllChildren()
        return
    end

    local curWildData = clientWildData[curIndex]
    local symbolNode = curWildData.p_symbolNode
    local wildPos = curWildData.p_pos
    local curMul = curWildData.p_mul
    local curRow = curWildData.p_rowIndex
    local curCol = curWildData.p_cloumnIndex
    local delayTime = 0.4
    -- 最终总赢钱
    local totalWinCoins = self.m_runSpinResultData.p_winAmount
    -- 是否开始上涨钱
    local isStartJumpCoins = false
    -- 上涨的时长
    local jumpTimes = 0
    if curIndex == 1 then
        isStartJumpCoins = true
        if #clientWildData == 1 then
            jumpTimes = 1.5
        else
            jumpTimes = (#clientWildData - 1) * 1.8--(#clientWildData - 1) * (delayTime + 5/30)
        end
    end
    local startPos = cc.p(util_getOneGameReelsTarSpPos(self, wildPos))
    local endPos = util_convertToNodeSpace(self.m_mulView:getMulTextNode(), self.m_effectNode)

    local flyNode = self:createScarabChestSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    flyNode:setPosition(startPos)
    self.m_effectNode:addChild(flyNode)
    flyNode:setVisible(false)

    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        symbolNode.m_isCollect = true
        local nodeScore = symbolNode:getChildByName("wild_tag")
        if not tolua.isnull(nodeScore) then
            util_resetCsbAction(nodeScore.m_csbAct)
            nodeScore:runCsbAction("shouji", false, function()
                nodeScore:runCsbAction("idleframe5", true)
            end)
        end
        symbolNode:runAnim("shouji", false, function()
            symbolNode:runAnim("idleframe4", true)
        end)
    end)
    -- 第5帧播飞fly
    tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_CollectWild_ToBox)
        flyNode:setVisible(true)
        flyNode:runAnim("fly", false)
    end)
    -- 飞行0.4s（fly动画时长12帧）
    -- 不是第三列的话需要贝塞尔曲线
    local midCol = 3
    if curCol ~= midCol then
        local intervalCol = curCol - midCol
        local disPosX, disPosY = 160*intervalCol, 60
        local bezier = {}
        bezier[1] = cc.p(startPos.x, startPos.y)
        bezier[2] = cc.p(endPos.x + disPosX, endPos.y - disPosY)
        bezier[3] = endPos
        local bezierTo = cc.BezierTo:create(delayTime, bezier)
        tblActionList[#tblActionList+1] = cc.EaseSineInOut:create(bezierTo)
    else
        tblActionList[#tblActionList+1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
    end
    -- 反馈
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_CollectWild_ToBox_FeedBack)
        flyNode:setVisible(false)
        self.m_mulView:playFeedBack(curMul)
        -- 倍数上涨
        self.m_mulView:setMul(curMul)
        -- 金币开始涨
        if isStartJumpCoins then
            local parms = {endCoins = totalWinCoins, duration = jumpTimes, charLevel = charLevel, coinLevel = coinLevel, endCallFunc = callFunc}
            self.m_boxCoinsView:startJumpCouns(parms)
        end
    end)
    -- 延长0.15s收集
    tblActionList[#tblActionList+1] = cc.DelayTime:create(0.15)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        -- 收集下一个
        self:collectFlyBonus(callFunc, clientWildData, selfData, curIndex)
    end)

    flyNode:runAction(cc.Sequence:create(tblActionList))
end

-- freeBonus玩法
function CodeGameScreenScarabChestMachine:showFreeBoxAndMul(_callFunc, _clientWildData, _selfData)
    local callFunc = _callFunc
    local clientWildData = _clientWildData
    local selfData = _selfData
    self:collectFreeFlyBonus(callFunc, clientWildData, selfData, 0)
end

-- free收集
function CodeGameScreenScarabChestMachine:collectFreeFlyBonus(_callFunc, _clientWildData, _selfData, _curIndex)
    local callFunc = _callFunc
    local clientWildData = _clientWildData
    local selfData = _selfData
    local curIndex = _curIndex + 1
    local charLevel = selfData.charLevel
    local coinLevel = selfData.coinLevel
    if curIndex > #clientWildData then
        self.m_effectNode:removeAllChildren()
        -- 结束后把倍数安全重置(以防加错)
        local totalMulti = selfData.freespinExtra.total_multi
        self.m_mulView:setMul(totalMulti, true)
        return
    end

    local curWildData = clientWildData[curIndex]
    local symbolNode = curWildData.p_symbolNode
    local wildPos = curWildData.p_pos
    local curMul = curWildData.p_mul
    local delayTime = 0.4
    -- 最终总赢钱
    local totalWinCoins = selfData.freespinExtra.finalWin
    -- 是否开始上涨钱
    local isStartJumpCoins = false
    -- 上涨的时长
    local jumpTimes = 0
    if curIndex == 1 then
        isStartJumpCoins = true
        if #clientWildData == 1 then
            jumpTimes = 1.5
        else
            jumpTimes = (#clientWildData - 1) * 1.5--(#clientWildData - 1) * (delayTime + 5/30)
        end
    end
    local startPos = cc.p(util_getOneGameReelsTarSpPos(self, wildPos))
    local endPos = util_convertToNodeSpace(self.m_mulView:getMulTextNode(), self.m_effectNode)

    local flyNode = self:createScarabChestSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    flyNode:setPosition(startPos)
    self.m_effectNode:addChild(flyNode)
    flyNode:setVisible(false)

    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        symbolNode.m_isCollect = true
        local nodeScore = symbolNode:getChildByName("wild_tag")
        if not tolua.isnull(nodeScore) then
            util_resetCsbAction(nodeScore.m_csbAct)
            nodeScore:runCsbAction("shouji", false, function()
                nodeScore:runCsbAction("idleframe5", true)
            end)
        end
        symbolNode:runAnim("shouji", false, function()
            symbolNode:runAnim("idleframe4", true)
        end)
    end)
    -- 第5帧播飞fly
    tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_CollectWild_ToBox)
        flyNode:setVisible(true)
        flyNode:runAnim("fly", false)
    end)
    -- 飞行0.4s（fly动画时长12帧）
    tblActionList[#tblActionList+1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
    -- 反馈
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_CollectWild_ToBox_FeedBack)
        flyNode:setVisible(false)
        self.m_mulView:playFeedBack(curMul)
        -- 倍数上涨
        self.m_mulView:setMul(curMul)
        -- 金币开始涨
        if isStartJumpCoins then
            local parms = {endCoins = totalWinCoins, duration = jumpTimes, charLevel = charLevel, coinLevel = coinLevel, endCallFunc = callFunc, isFreeBonus = true}
            self.m_boxCoinsView:startJumpCouns(parms)
        end
    end)
    -- 延长0.15s收集
    tblActionList[#tblActionList+1] = cc.DelayTime:create(0.15)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        -- 收集下一个
        self:collectFreeFlyBonus(callFunc, clientWildData, selfData, curIndex)
    end)

    flyNode:runAction(cc.Sequence:create(tblActionList))
end

-- 宝箱动画切换等级
function CodeGameScreenScarabChestMachine:boxSpineSwitchLevel(_switchLevel)
    local switchLevel = _switchLevel
    self.m_curBoxLevel = switchLevel
    local switchName, idleName
    if switchLevel == 2 then
        switchName = "switch1_2"
        idleName = "idle2"
    elseif switchLevel == 3 then
        switchName = "switch1_3"
        idleName = "idle3"
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Box_Upgradate)
    util_spinePlay(self.m_boxSpine, switchName, false)
    util_spineEndCallFunc(self.m_boxSpine, switchName, function()
        util_spinePlay(self.m_boxSpine, idleName, true)
    end)
end

function CodeGameScreenScarabChestMachine:createScarabChestSymbol(_symbolType)
    local symbol = util_createView("CodeScarabChestSrc.ScarabChestSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

-- bonus玩法结束
function CodeGameScreenScarabChestMachine:showBonusOverView(_endCallFunc)
    local endCallFunc = _endCallFunc
    -- 切背景
    self:changeBgSpine(1, "switch2")
    -- 宝箱关闭背光
    local overName = "over1"
    local idleName = "idle1"
    if self.m_curBoxLevel then
        overName = "over" .. self.m_curBoxLevel
        idleName = "idle" .. self.m_curBoxLevel + 3
    end
    util_spinePlay(self.m_boxSpine, overName, false)
    util_spineEndCallFunc(self.m_boxSpine, overName, function()
        util_spinePlay(self.m_boxSpine, idleName, true)
    end)

    -- 赢钱
    local winCoins = self.m_runSpinResultData.p_winAmount
    self:playhBottomLight(winCoins)
    self:clearWinLineEffect()
    self:showLineFrame()
    performWithDelay(self.m_scWaitNode, function()
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end, 2.5)
end

-- free里bonus玩法结束
function CodeGameScreenScarabChestMachine:showFreeBonusOverView(_endCallFunc, _isFreeBonus)
    local endCallFunc = _endCallFunc
    local isFreeBonus = _isFreeBonus
    if isFreeBonus then
        self:clearWinLineEffect()
        self:showLineFrame(true)
    end
    if type(endCallFunc) == "function" then
        endCallFunc()
    end
end

--判断当前是否为free下最后一次spin
function CodeGameScreenScarabChestMachine:getCurIsFreeGameLastSpin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenScarabChestMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenScarabChestMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, "actionframe_bigwin", false)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe_bigwin", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(rootNode,5,10,aniTime)
end

function CodeGameScreenScarabChestMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    local randomNum = math.random(1, 10)
    if randomNum <= 3 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_WinEffect)
    end
    CodeGameScreenScarabChestMachine.super.showEffect_runBigWinLightAni(self, effectData)
    return true
end

function CodeGameScreenScarabChestMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenScarabChestMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

--新快停逻辑
function CodeGameScreenScarabChestMachine:newQuickStopReel(colIndex)
    --快停后检查是否有拖尾，有的话直接删除
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                slotNode:removeTuowei()
            end
        end
    end
    self:removeSlotNodeParticle()
    CodeGameScreenScarabChestMachine.super.newQuickStopReel(self, colIndex)
end

--清除拖尾
function CodeGameScreenScarabChestMachine:removeSlotNodeParticle()
    for i = 1, #self.m_falseParticleTbl do
        local particleNode = self.m_falseParticleTbl[i]
        if not tolua.isnull(particleNode) then
            particleNode:stopAllActions()
            particleNode:removeFromParent()
            self.m_falseParticleTbl[i] = nil
        end
    end
end

-- free和freeMore特殊需求
function CodeGameScreenScarabChestMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FreeMore_ScatterTrigger)
        else
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenScarabChestMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenScarabChestMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenScarabChestMachine:checkRemoveBigMegaEffect()
    CodeGameScreenScarabChestMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenScarabChestMachine:getShowLineWaitTime()
    local time = CodeGameScreenScarabChestMachine.super.getShowLineWaitTime(self)
    if self.collectBonus then
        time = 2
    end
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenScarabChestMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeScarabChestSrc.ScarabChestFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_FGbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenScarabChestMachine:showEffect_FreeSpin(effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.m_beInSpecialGameTrigger = true
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:clearCurMusicBg()
        end
        self:levelDeviceVibrate(6, "free")
        local waitTime = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        else
                            slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 5)
                        end
                        slotNode:runAnim("actionframe", false, function()
                            slotNode:runAnim("idleframe1", true)
                        end)
                        
                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime,duration)
                    end
                end
            end
        end
        self:playScatterTipMusicEffect(true)
        
        performWithDelay(self,function()
            self:showFreeSpinView(effectData)
        end,waitTime)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end, 0.5)
    return true  
end

function CodeGameScreenScarabChestMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("ScarabChestSounds/music_ScarabChest_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FgMore_Start)
            self.m_baseFreeSpinBar:setFreeAni(true)
            self.m_freeMoreCountText:setString(self.m_runSpinResultData.p_freeSpinNewCount)
            self.m_freeMoreSpine:setVisible(true)
            local playName = "actionframe_add1"
            if self.m_runSpinResultData.p_freeSpinNewCount > 1 then
                playName = "actionframe_add2"
            end
            -- 60帧播反馈
            performWithDelay(self.m_scWaitNode, function()
                gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            end, 100/30)
            util_spinePlay(self.m_freeMoreSpine, playName, false)
            util_spineEndCallFunc(self.m_freeMoreSpine, playName, function()
                self.m_freeMoreSpine:setVisible(false)
                self:resetMusicBg(true)
                -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        else
            local selfData = self.m_runSpinResultData.p_selfMakeData
            local charLevel = selfData.charLevel
            local coinLevel = selfData.coinLevel
            local baseCoins = selfData.freespinExtra.base
            local scCount = selfData.scCount
            local freeStartSpine = util_spineCreate("ScarabChest_yugao2",true,true)
            util_spinePlay(freeStartSpine, "start", false)
            util_spineEndCallFunc(freeStartSpine, "start", function()
                util_spinePlay(freeStartSpine, "idle", true)
            end)

            local cutSceneFunc = function()
                util_spinePlay(freeStartSpine, "over", false)
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Normal_Click)
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_startOver)
                -- 过场
                performWithDelay(self.m_scWaitNode, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Fg_CutScene)
                end, 60/60)
                -- 75帧切过场
                performWithDelay(self.m_scWaitNode, function()
                    self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_FG_Bg)
                    self:showFreeUiState()
                end, 75/30)
            end

            local callFunc = function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()    
            end
            
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                local parms = {endCoins = baseCoins, duration = 2.0, charLevel = charLevel, coinLevel = coinLevel, isFreeStart = true, endCallFunc = callFunc}
                self.m_boxCoinsView:startJumpCouns(parms)
            end)

            view.m_allowClick = false
            performWithDelay(view,function ()
                view.m_allowClick = true
            end,80/60)

            -- 显示scatter个数
            for i=3, 5 do
                local spCount = view:findChild("sp_ScCount_"..i)
                if spCount then
                    if scCount == i then
                        spCount:setVisible(true)
                    else
                        spCount:setVisible(false)
                    end
                end
            end
            view:setBtnClickFunc(cutSceneFunc)
            view:findChild("m_lb_coins"):setString(util_formatCoins(baseCoins,3))
            view:findChild("Node_jinzita"):addChild(freeStartSpine)
            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

---
-- 显示free spin over 动画
function CodeGameScreenScarabChestMachine:showEffect_FreeSpinOver()
    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")
    -- if #self.m_reelResultLines == 0 then
    --     self.m_freeSpinOverCurrentTime = 1
    -- end
    self.m_freeSpinOverCurrentTime = 0
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
        self.m_fsOverHandlerID =
            scheduler.scheduleGlobal(
            function()
                if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
                    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
                else
                    self:showEffect_newFreeSpinOver()
                end
            end,
            0.1
        )
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenScarabChestMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    local curBoxLevel = self.m_curBoxLevel or 1
    local resultName = "jiesuan"..curBoxLevel
    local curCount = 5
    if curBoxLevel == 2 then
        curCount = 6
    elseif curBoxLevel == 3 then
        curCount = 8
    end

    local winCoins = self.m_runSpinResultData.p_fsWinCoins
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local finalWin = selfData.freespinExtra.finalWin
    local charLevel = selfData.charLevel
    local coinLevel = selfData.coinLevel

    -- 新建一个假的字体在上边
    local startPos = util_convertToNodeSpace(self.m_boxAni:findChild("jiangjin"), self.m_effectNode)
    local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self.m_effectNode)
    local freeBoxCoinsView = util_createView("CodeScarabChestSrc.ScarabChestBoxCoinsView", self)
    -- 总钱数显示
    freeBoxCoinsView:setLevelCoins(charLevel, coinLevel)
    freeBoxCoinsView:setWinCoins(finalWin, true, true)
    freeBoxCoinsView:setPosition(startPos)
    self.m_effectNode:addChild(freeBoxCoinsView)
    self.m_boxCoinsView:setVisible(false)
    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        -- self.m_boxCoinsView:playTextTrigger()
        freeBoxCoinsView:playTextTrigger()
        if self.m_freeOverSoundIndex > 3 then
            self.m_freeOverSoundIndex = 1
        end
        local soundName = self.m_publicConfig.SoundConfig.Music_FgOver_CollectCoins_Sound[self.m_freeOverSoundIndex]
        if soundName then
            gLobalSoundManager:playSound(soundName)
        end
        self.m_freeOverSoundIndex = self.m_freeOverSoundIndex + 1
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(150/60)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        -- self.m_boxCoinsView:closeBoxCoins()
        util_spinePlay(self.m_boxSpine, resultName, false)
        util_spineEndCallFunc(self.m_boxSpine, resultName, function()
            util_spinePlay(self.m_boxSpine, "idle", true)
        end)
        for i=1, curCount do
            self.m_freeEndCoinsSpineTbl[i]:setVisible(true)
            util_spinePlay(self.m_freeEndCoinsSpineTbl[i], "jiesuan", false)
        end
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
    -- 在jiesuan播到第5帧的时候播；把钱砸下来
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        freeBoxCoinsView:playFlyCoinsAct()
        startPos.y = startPos.y + 40
        local moveAct1 = cc.EaseSineOut:create(cc.MoveTo:create(10/60, startPos))
        local moveAct2 = cc.EaseSineIn:create(cc.MoveTo:create(30/60, endPos))
        freeBoxCoinsView:runAction(cc.Sequence:create(moveAct1, moveAct2))
    end)
    -- 金币向下撒第15帧UI框播消失
    tblActionList[#tblActionList+1] = cc.DelayTime:create(10/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_mulView:closeMul()
        self.m_baseCoinsView:closeBaseCoins()
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(10/30)
    -- 在jiesuan播到第25帧的时候播
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:playhBottomLight(winCoins, true)
    end)
    -- 赢钱区奖金涨钱字体增长  2.5s左右
    tblActionList[#tblActionList+1] = cc.DelayTime:create(2.5)
    -- 上一流程结束0.5s后
    tblActionList[#tblActionList+1] = cc.DelayTime:create(1.0)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_effectNode:removeAllChildren()
        self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearFrames_Fun()
        -- 重置连线信息
        -- self:resetMaskLayerNodes()
        self:clearCurMusicBg()
        self:showFreeSpinOverView()
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

function CodeGameScreenScarabChestMachine:showFreeSpinOverView(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 2, 0, 1)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local lightAni = util_createAnimation("ScarabChest_tb_guang1.csb")
    local lightAni2 = util_createAnimation("ScarabChest_tb_guang2.csb")
    
    self.collectBonus = false
    
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
        end, 5/60)
    end
    
    local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
        self:clearWinLineEffect()
        self:showFreeOverCutScene(function()
            self:triggerFreeSpinOverCallFun()
        end)
    end)
    view:setBtnClickFunc(cutSceneFunc)
    view:findChild("Node_guang1"):addChild(lightAni)
    view:findChild("Node_guang2"):addChild(lightAni2)
    lightAni:runCsbAction("idle", true)
    lightAni2:runCsbAction("idle", true)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.89,sy=1.0},781)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenScarabChestMachine:showFreeOverCutScene(_func)
    local callFunc = _func
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Base_CutScene)
    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe_guochang", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe_guochang", function()
        self.m_yuGaoSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)

    -- 第66帧切
    performWithDelay(self.m_scWaitNode, function()
        self:changeBgSpine(1)
        self.m_boxAni:runCsbAction("idle", true)
        self.m_collectBarView:resetCollectWild()
        self.m_baseFreeSpinBar:setVisible(false)
        self.m_jackPotBarView:resetShowJackpotState(false)
        self.m_mulView:closeMul(true)
        self.m_baseCoinsView:closeBaseCoins(true)
        self.m_basePlayTipsView:showStart(true)
    end, 66/30)
end

function CodeGameScreenScarabChestMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeScarabChestSrc.ScarabChestJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenScarabChestMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeScarabChestSrc.ScarabChestJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        jackpotBar = self.m_jackPotBarView,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

function CodeGameScreenScarabChestMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 
end

function CodeGameScreenScarabChestMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态
    end
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenScarabChestMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenScarabChestMachine.super.MachineRule_ResetReelRunData(self)    
end

function CodeGameScreenScarabChestMachine:updateReelGridNode(_symbolNode)
    if self:getCurSymbolIsJackpot(_symbolNode.p_symbolType) then
        _symbolNode:setIdleAnimName("idleframe")
    end
    if _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        self:setSpecialNodeScoreWild(_symbolNode)
        _symbolNode:runAnim("idleframe", true)
         --修正层级
        local showOrder = self:getBounsScatterDataZorder(_symbolNode.p_symbolType)
        _symbolNode.m_showOrder = showOrder
        _symbolNode:setLocalZOrder(showOrder)
        if self.m_isAddTuoWei then
            _symbolNode:addTuoweiParticle(self.m_slotParents[_symbolNode.p_cloumnIndex].slotParent, self.m_falseParticleTbl)
        end
    else
        local nodeScore = _symbolNode:getChildByName("wild_tag")
        if not tolua.isnull(nodeScore) then
            nodeScore:removeFromParent()
        end
    end
end

-- 给respin小块进行赋值
function CodeGameScreenScarabChestMachine:setSpecialNodeScoreWild(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end
    _symbolNode.m_isCollect = nil
    local wildNodeScore, curMul
    local nodeScore = _symbolNode:getChildByName("wild_tag")
    if not tolua.isnull(nodeScore) then
        wildNodeScore = nodeScore
    else
        wildNodeScore = util_createAnimation("Socre_ScarabChest_wild_coins.csb")
        symbolNode:addChild(wildNodeScore, 100)
        wildNodeScore:setPosition(cc.p(0, 0))
        wildNodeScore:setName("wild_tag")
    end

    if symbolNode.m_isLastSymbol == true then
        curMul = self:getSpinBonusScore(self:getPosReelIdx(iRow, iCol))
    else
        -- 获取随机分数（本地配置）
        curMul = self:randomDownSpinSymbolScore(symbolNode.p_symbolType)
    end
    wildNodeScore:setVisible(true)
    self:setWildMulState(wildNodeScore, curMul)
end

-- 设置wild上字体的倍数
function CodeGameScreenScarabChestMachine:setWildMulState(_wildNodeScore, _curMul)
    util_resetCsbAction(_wildNodeScore.m_csbAct)
    _wildNodeScore:runCsbAction("idleframe", true)
    _wildNodeScore:findChild("Node_mul_1"):setVisible(_curMul == 1)
    _wildNodeScore:findChild("Node_mul_2"):setVisible(_curMul == 2)
    _wildNodeScore:findChild("Node_mul_5"):setVisible(_curMul == 5)
    _wildNodeScore:findChild("Node_mul_10"):setVisible(_curMul == 10)
end

--[[
    获取小块真实分数
]]
function CodeGameScreenScarabChestMachine:getSpinBonusScore(id)
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wildPosData = selfData.wildPos

    local mul = 1
    for i=1, #wildPosData do
        local values = wildPosData[i]
        if values[1] == id then
            mul = values[2]
        end
    end

    return mul
end

--[[
    随机wild倍数
]]
function CodeGameScreenScarabChestMachine:randomDownSpinSymbolScore(symbolType)
    local mul = self.m_configData:getBnBasePro(1)

    return mul
end

-- 获取当前玩法是否是特殊wild
function CodeGameScreenScarabChestMachine:setCurSpinIsSpecialWild()
    self.m_isPreFree = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.pre_free then
        self.m_isPreFree = selfData.pre_free == 1 and true or false
    end
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenScarabChestMachine:showFeatureGameTip(_func)
    self:setCurSpinIsSpecialWild()
    if self:getFeatureGameTipChance(60) then
        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
    elseif self.m_isPreFree then
        self:playWildFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
    else
        if type(_func) == "function" then
            _func()
        end
    end    
end

-- 当前是否是free
function CodeGameScreenScarabChestMachine:getCurFeatureIsFree()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        return true
    end

    return false
end

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenScarabChestMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Sound)
    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe_yugao", function()
        self.m_yuGaoSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end) 
end

-- 处理93（wild反面预告中奖）
function CodeGameScreenScarabChestMachine:playWildFeatureNoticeAni(_func)
    local callFunc = _func
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_SpecialYuGao_Sound)
    self.m_yuGaoWildSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoWildSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_yuGaoWildSpine, "actionframe_yugao", function()
        self.m_yuGaoWildSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end) 
end

---
-- 在这里不影响groupIndex 和 rowIndex 等到结果数据来时使用
-- 有预告中奖假滚92变93
function CodeGameScreenScarabChestMachine:getReelDataWithWaitingNetWork(parentData)
    CodeGameScreenScarabChestMachine.super.getReelDataWithWaitingNetWork(self, parentData)
    if self.m_isPreFree and parentData.symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        parentData.symbolType = self.SYMBOL_SCORE_SPECIAL_WILD
    end
end

function CodeGameScreenScarabChestMachine:createSlotNextNode(parentData)
    CodeGameScreenScarabChestMachine.super.createSlotNextNode(self, parentData)
    if self.m_isPreFree and parentData.symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        parentData.symbolType = self.SYMBOL_SCORE_SPECIAL_WILD
    end
end

function CodeGameScreenScarabChestMachine:playhBottomLight(_endCoins, _isOver)
    self.m_addBotomCoins = true
    self.m_bottomUI:playCoinWinEffectUI()
    self.m_bottomBigWinSpin:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_JumpCoins)
    util_spinePlay(self.m_bottomBigWinSpin, "actionframe", false)
    util_spineEndCallFunc(self.m_bottomBigWinSpin, "actionframe", function()
        self.m_bottomBigWinSpin:setVisible(false)
    end)

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    if _isOver then
        totalWinCoin = _endCoins
    end
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin, isNotifyUpdateTop)
    self.m_addBotomCoins = false
end

--BottomUI接口
function CodeGameScreenScarabChestMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenScarabChestMachine:getCurBottomWinCoins()
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

function CodeGameScreenScarabChestMachine:changeBgSpine(_bgType, _switchName)
    -- 1.base；2.bonus；3.freespin
    local switchName = _switchName
    if switchName then
        for i=1, 2 do
            self.m_bgType[i]:setVisible(true)
        end
        if switchName == "switch1" then
            self.m_gameBg:runCsbAction("switch1", false, function()
                self.m_bgType[2]:setVisible(true)
                self.m_gameBg:runCsbAction("idle", true)
            end)
        elseif switchName == "switch2" then
            self.m_gameBg:runCsbAction("switch2", false, function()
                self.m_bgType[2]:setVisible(false)
                self.m_gameBg:runCsbAction("idle", true)
            end)
        end
    else
        for i=1, 3 do
            if i == _bgType then
                self.m_bgType[i]:setVisible(true)
            else
                self.m_bgType[i]:setVisible(false)
            end
        end
    end
    
    if _bgType ~= 2 then
        local bgType = _bgType
        if bgType == 3 then
            bgType = 2
        end
        self:setReelBgState(bgType)
    end
end

function CodeGameScreenScarabChestMachine:setReelBgState(_bgType)
    for i=1, 2 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

function CodeGameScreenScarabChestMachine:showLineFrame(_isFreeLine)
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin(_isFreeLine)

    self.m_lineSlotNodes = {}
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

        -- if #winLines > 1 then
        showLienFrameByIndex()
    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end

        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

function CodeGameScreenScarabChestMachine:checkNotifyUpdateWinCoin(_isFreeLine)
    local winLines = self.m_reelResultLines

    if #winLines <= 0 or _isFreeLine then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

-- 所有玩法结束后；设置收集区域的钱
function CodeGameScreenScarabChestMachine:setPlayEndCoins()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    end
end

function CodeGameScreenScarabChestMachine:getWinCoinTime()
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
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            showTime = 1
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        showTime = 0
    end

    return showTime
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenScarabChestMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    local scatterSoundTbl = self.m_publicConfig.SoundConfig.Music_Scatter_Buling

    local isQuickHaveScatter = false
    -- 检查下前三列是否有scatter（前三列有scatter必然播落地）
    if self:getGameSpinStage() == QUICK_RUN then
        local reels = self.m_runSpinResultData.p_reels
        local curBonusCount = 0
        for iCol = 1, 3 do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = reels[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isQuickHaveScatter = true
                    break
                end
            end
        end
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self.m_curScatterBulingCount = self.m_curScatterBulingCount + 1
                        if self.m_curScatterBulingCount > 3 then
                            self.m_curScatterBulingCount = 3
                        end
                        soundPath = scatterSoundTbl[self.m_curScatterBulingCount]
                        if self:getGameSpinStage() == QUICK_RUN then
                            if self:getCurFeatureIsFree() then
                                soundPath = scatterSoundTbl[3]
                            else
                                soundPath = scatterSoundTbl[1]
                            end
                        end
                    end

                    -- 快停时；有scatter 不播bonus
                    if self:getCurSymbolIsWild(symbolType) then
                        if not isQuickHaveScatter then
                            self:playBulingSymbolSounds(iCol, soundPath, nil)
                        end
                    else
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
        end
    end
end

function CodeGameScreenScarabChestMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    local time = self:getShowLineWaitTime()
    if time then
        performWithDelay(self.m_scWaitNode, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, time)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenScarabChestMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            self:setSpecialNodeLine(slotsNode)
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

-- 连线全部播放一遍
function CodeGameScreenScarabChestMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    self:setSpecialNodeLine(slotsNode)
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

--播放wild上字体的连线动画
function CodeGameScreenScarabChestMachine:setSpecialNodeLine(_slotsNode)
    if _slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        local nodeScore = _slotsNode:getChildByName("wild_tag")
        if not tolua.isnull(nodeScore) then
            -- 收集后半透明
            util_resetCsbAction(nodeScore.m_csbAct)
            if _slotsNode.m_isCollect then
                nodeScore:runCsbAction("actionframe5", true)
            else
                -- 触发bonus玩法，第一遍不透明
                if self.m_isBonus then
                    nodeScore:runCsbAction("actionframe4", true)
                else
                    nodeScore:runCsbAction("actionframe", false, function()
                        nodeScore:setVisible(false)
                    end)
                end
            end  
        end
    end
end

--播放wild上字体的idle
function CodeGameScreenScarabChestMachine:setSpecialNodeIdle(_slotsNode)
    if _slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        local nodeScore = _slotsNode:getChildByName("wild_tag")
        if not tolua.isnull(nodeScore) then
            -- 收集后半透明
            -- util_resetCsbAction(nodeScore.m_csbAct)
            if _slotsNode.m_isCollect then
                nodeScore:runCsbAction("idleframe5", true)
            else
                if self.m_isBonus then
                    nodeScore:runCsbAction("idleframe", true)
                else
                    nodeScore:setVisible(false)
                end
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenScarabChestMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            self:setSpecialNodeIdle(slotsNode)
            slotsNode:runIdleAnim()
        end
    end
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenScarabChestMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
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

            -- wild的话加上边收集
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount and self:getCurSymbolIsWild(_slotNode.p_symbolType) then
                if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                    self.m_collectBarView:collectWildNode(_slotNode.p_cloumnIndex)
                end
            end
            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                _slotNode:runAnim(symbolCfg[2], false, function()
                    self:symbolBulingEndCallBack(_slotNode)
                end)
                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    local nodeScore = _slotNode:getChildByName("wild_tag")
                    if not tolua.isnull(nodeScore) then
                        util_resetCsbAction(nodeScore.m_csbAct)
                        nodeScore:runCsbAction("buling", false, function()
                            nodeScore:runCsbAction("idleframe", true)
                        end)
                    end
                end
            end
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenScarabChestMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif self:getCurSymbolIsWild(_slotNode.p_symbolType) then
                if self:isPlayTipAnimaByWild(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                return true
            end
        end
    end

    return false
end

-- scatter落地条件
function CodeGameScreenScarabChestMachine:isPlayTipAnima(colIndex, rowIndex, node)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return true
    end
    local reels = self.m_runSpinResultData.p_reels
    local scatterCount = 0
    for iCol = 1,colIndex - 1 do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterCount  = scatterCount + 1
            end
        end
    end

    if colIndex < 4 then
        return true
    elseif colIndex == 4 and scatterCount >= 1 then
        return true
    elseif colIndex == 5 and scatterCount >= 2 then
        return true
    end

    return false
end

-- wild落地条件
function CodeGameScreenScarabChestMachine:isPlayTipAnimaByWild(colIndex, rowIndex, node)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return true
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isBonus = selfData.isBonus
    if colIndex < 4 then
        return true
    else
        return isBonus
    end

    return false
end

return CodeGameScreenScarabChestMachine






