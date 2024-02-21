---
-- island li
-- 2019年1月26日
-- CodeGameScreenWarriorAliceMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "WarriorAlicePublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenWarriorAliceMachine = class("CodeGameScreenWarriorAliceMachine", BaseNewReelMachine)

CodeGameScreenWarriorAliceMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWarriorAliceMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1     --bonus
CodeGameScreenWarriorAliceMachine.SYMBOL_FIX_DOOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8     --开门图标
CodeGameScreenWarriorAliceMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenWarriorAliceMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2


CodeGameScreenWarriorAliceMachine.OPEN_DOOR_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1          --开门
CodeGameScreenWarriorAliceMachine.SOLDIER_ELIMINATE_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2      --消除士兵
CodeGameScreenWarriorAliceMachine.SHOW_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 3       --获取jackpot
local NORMAL_INDEX = {
    INDEX_ONE = 1,
    INDEX_TWO = 2,
    INDEX_THREE = 3,
    INDEX_FOUR = 4,
    INDEX_FIVE = 5,
}

local BONUS_NUM = 4             --每列士兵最多的个数（行数）

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

CodeGameScreenWarriorAliceMachine.BONUS_RUN_NUM = 3
CodeGameScreenWarriorAliceMachine.LONGRUN_COL_ADD_BONUS = 5

-- 构造函数
function CodeGameScreenWarriorAliceMachine:ctor()
    CodeGameScreenWarriorAliceMachine.super.ctor(self)
    self.m_lightScore = 0

    self.m_isFeatureOverBigWinInFree = true

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    self.smallSoldierList = {}
    self.bossJackpotList = {}

    self.tempDoorList = {}
    self.m_bonus_down = {}
    self.m_scatter_down = {}

    self.tempCoins = {}
    self.tempCoinsIndex = 1

    self.specialLongRunAim = {}

    self.jackpotIndex = 1

    --记录respin消除移动的数量
    self.oneMoveNum = 0
    self.twoMoveNum = 0
    self.threeMoveNum = 0
    self.fourMoveNum = 0
    self.fiveMoveNum = 0

    --保存上次未消除
    self.oldDropBonus = {}

    self.bigWinList = {}

    self.isRespinInitGame = false

    self.m_isLongRun = false   --是否处于base快滚状态

    self.m_isQuickly = false

    self.isBonusLongRun = false

    self.m_isPlayYuGao = false

    self.isFreeToRespin = false

    --当前respin中快滚的列
    self.curLongReelNum = 0

    self.flyLineNode = nil

    --当前是否展示红皇后闪电动画
    self.curQueenShowAct = false

    --当前是否展示大将闪电动画
    self.curBigSoldiderShowAct = false

    self.m_falseParticleTbl = {}

    -- 是否播放震动
    self.m_isPlayShake = true

    self.m_isTriggerLongRunCol = 6 --触发快滚的时候 用来判断的标识

    self.m_isBeginLongRun = false --判断respin玩法 快滚是否开始了

    self.m_playBulingEffectIndex = 0 --播放buling动画的标识 动画结束才会执行后面逻辑

    self.m_isReconnection = false--是否是重连轮

    self.tipsIndex = 0

    self.respinOverSpundIndex = 0

    self.openDoorSoundId = nil

    --记录开门effect
    -- self.openDoorEffect = nil

    self.isAutoSpin = false

    self.m_grandShow = false

    self.lightingSound = nil
    self.lightingSound2 = nil
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

	--init
	self:initGame()

end

function CodeGameScreenWarriorAliceMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("WarriorAliceConfig.csv", "LevelWarriorAliceConfig.lua")


	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWarriorAliceMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WarriorAlice" 
end

function CodeGameScreenWarriorAliceMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initFreeSpinBar() -- FreeSpinbar

    --红皇后角色
    --播放动画前设置皮肤
    self.redQueen = util_spineCreate("WarriorAlice_juese",true,true)
    self:findChild("Node_redking"):addChild(self.redQueen)
    self.redQueen:setVisible(false)
    self.redQueen:getParent():setLocalZOrder(550)
    
    --Respin次数框
    self.m_respinBar = util_createView("CodeWarriorAliceSrc.WarriorAliceRespinBarView")        
    self:findChild("Node_respinbar"):addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)

    --Respin totalwin
    self.m_respinTotalWin = util_createAnimation("WarriorAlice_respintotalwin.csb")        
    self:findChild("Node_respintotalwin"):addChild(self.m_respinTotalWin)
    self.m_respinTotalWin:setVisible(false)

    --jackpotBar
    self.m_jackPotBar = util_createView("CodeWarriorAliceSrc.WarriorAliceJackPotBarView")  --jackpot
    self:findChild("Node_grand"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:setVisible(true)
    self.m_jackPotBar:getParent():setLocalZOrder(560)
    
    --下方赢钱区特效
    local node_bar = self.m_bottomUI
    self.m_jiesuanAct = util_spineCreate("WarriorAlice_yingqianqu",true,true)
    node_bar:addChild(self.m_jiesuanAct, -1)
    self.m_jiesuanAct:setPosition(util_convertToNodeSpace(self.m_bottomUI.coinWinNode, node_bar))
    self.m_jiesuanAct:setVisible(false)

    --大赢飘数字
    self.m_bigwinEffectNum = util_createAnimation("WarriorAlice_bigwin_num.csb")
    self.m_bottomUI.coinWinNode:addChild(self.m_bigwinEffectNum)
    self.m_bigwinEffectNum:setVisible(false)

    --预告中奖
    self.m_yugao  = util_spineCreate("Socre_WarriorAlice_Bonus",true,true)
    self:addChild(self.m_yugao,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_yugao:setPosition(util_convertToNodeSpace(self:findChild("yugao"),self))
    self.m_yugao:setVisible(false)

    --斩击红皇后的时候 
    self.m_GrandJiangLi  = util_spineCreate("WarriorAlice_grand_jiangli",true,true)
    self:findChild("yugao"):addChild(self.m_GrandJiangLi)
    self.m_GrandJiangLi:setVisible(false)

    --全屏动画
    self.m_quanPing  = util_spineCreate("Socre_WarriorAlice_Bonus",true,true)
    self:addChild(self.m_quanPing,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_quanPing:setPosition(util_convertToNodeSpace(self:findChild("yugao"),self))
    self.m_quanPing:setVisible(false)
    


    --全屏动画人物
    self.m_quanPingPeople = util_spineCreate("Socre_WarriorAlice_Bonus",true,true)
    self:addChild(self.m_quanPingPeople, GAME_LAYER_ORDER.LAYER_ORDER_TOP + 1)
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self)
    self.m_quanPingPeople:setPosition(display.cx, pos.y)
    self.m_quanPingPeople:setVisible(false)
    self.m_quanPingPeople:setScale(self.m_machineRootScale)

    --压黑
    self.yaHei = util_createAnimation("WarriorAlice_yahei.csb")
    self:findChild("Node_yahei"):addChild(self.yaHei)
    self:findChild("Node_yahei"):setLocalZOrder(600)
    self.yaHei:setVisible(false)

    --wenan
    self.wenAn = util_createAnimation("WarriorAlice_base_wenan.csb")
    self:findChild("Node_base_wenan"):addChild(self.wenAn)

    self.m_maskNodeTab = {}

    for col = 1,self.m_iReelColumnNum do
        --添加半透明遮罩
        local parentData = self.m_slotParents[col]
        local mask = cc.LayerColor:create(cc.c3b(0, 0, 0), parentData.reelWidth - 1 , parentData.reelHeight)
        mask:setOpacity(200)
        mask.p_IsMask = true--不被底层移除的标记
        mask:setPositionX(parentData.reelWidth/2)
        parentData.slotParent:addChild(mask, REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10)
        table.insert(self.m_maskNodeTab,mask)
        mask:setVisible(false)
    end

    self.m_spineGuochang = util_spineCreate("WarriorAlice_guochang1", true, true)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_UI + 10)
    self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang:setVisible(false)
    self:createGuoChang2Effect()

    self.m_openDoorNode = cc.Node:create()
    self:addChild(self.m_openDoorNode)

    self.m_QueenNode = cc.Node:create()
    self:addChild(self.m_QueenNode)

    self:changeReelKuang(NORMAL_INDEX.INDEX_ONE)
    self:changeGameBg(NORMAL_INDEX.INDEX_ONE)
    self:changeNodeReel(NORMAL_INDEX.INDEX_ONE)

    self:createSmallSoldier()

    self:createBigWinEffect()

    self:addSpecialLongRunEffect()

    self:runCsbAction("idle",true)

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)

    

    self.wenan_node = cc.Node:create()
    self:addChild(self.wenan_node)

    self:showTipsIdle()

    if display.width/display.height >= 1812/2176 then
        util_csbScale(self.m_gameBg.m_csbNode, 1.15)
    end
end

function CodeGameScreenWarriorAliceMachine:showTipsIdle()
    self.wenan_node:stopAllActions()
    performWithDelay(self.wenan_node,function ()
        if self.tipsIndex == 0 then
            self.wenAn:runCsbAction("jianyin",false,function ()
                self.tipsIndex = 1
                self:showTipsIdle()
            end)
        else
            self.wenAn:runCsbAction("jianyin2",false,function ()
                self.tipsIndex = 0
                self:showTipsIdle()
            end)
        end
    end,10)
end

--大赢动画
function CodeGameScreenWarriorAliceMachine:createBigWinEffect()
    self.bigWinList = {}
    
    for i=1,4 do
        local bigWin = util_spineCreate("WarriorAlice_BIGWIN"..i, true, true)
        bigWin.index = i
        self:findChild("bigwin_2"):addChild(bigWin, 100-i)
        bigWin:setVisible(false)
        self.bigWinList[#self.bigWinList + 1] = bigWin
    end
    for i=5,6 do
        local bigWin = util_spineCreate("WarriorAlice_BIGWIN"..i, true, true)
        bigWin.index = i
        self:findChild("bigwin_1"):addChild(bigWin, 100-i)
        bigWin:setVisible(false)
        self.bigWinList[#self.bigWinList + 1] = bigWin
    end
end

function CodeGameScreenWarriorAliceMachine:initFreeSpinBar()
    local parent = self:findChild("Node_freebar")
    self.m_baseFreeSpinBar = util_createView("CodeWarriorAliceSrc.WarriorAliceFreespinBarView")
    parent:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end


function CodeGameScreenWarriorAliceMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_WarriorAlice_enter_game)


    end,0.4,self:getModuleName())
end

function CodeGameScreenWarriorAliceMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWarriorAliceMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenWarriorAliceMachine:addObservers()
    CodeGameScreenWarriorAliceMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --freespin最后一次spin不会播大赢,需单独处理
            local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            if fsLeftCount <= 0 then
                self.m_bIsBigWin = false
            end
        end
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winCoin / lTatolBetNum
        local soundIndex = 1
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundIndex = 1
            elseif winRatio > 1 and winRatio <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig.SoundConfig["sound_WarriorAlice_win_line_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_WarriorAlice_fs_win_line_"..soundIndex] 
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenWarriorAliceMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWarriorAliceMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    --卸载自定义特殊金边
    self:clearSpecialLongRunList()

    self:clearAllSoldier()
    self.m_openDoorNode:stopAllActions()
    self.m_QueenNode:stopAllActions()

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWarriorAliceMachine:MachineRule_GetSelfCCBName(symbolType)

    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_WarriorAlice_Bonus"
    end
    if symbolType == self.SYMBOL_FIX_DOOR then
        return "Socre_WarriorAlice_Kaimen"
    end
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_WarriorAlice_10"
    end
    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_WarriorAlice_11"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWarriorAliceMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWarriorAliceMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_DOOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}

    return loadNode
end

--设置bonus scatter 层级
function CodeGameScreenWarriorAliceMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_FIX_SYMBOL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100
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
----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenWarriorAliceMachine:MachineRule_initGame(  )
    self.m_isReconnection = true

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount

    if reSpinCurCount > 0 then
        self.wenAn:setVisible(false)
        self.isRespinInitGame = true
        self:resetEliminateNum()
        --刷新上方士兵显示
        self:updateUpPeopleInitGame()
        --刷新上方士兵位置
        self:updateSoldierPos(false,nil)
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.wenAn:setVisible(false)
        self.m_baseFreeSpinBar:initFreeSpinCount(self.m_runSpinResultData.p_freeSpinsLeftCount,self.m_runSpinResultData.p_freeSpinsTotalCount)
        self:changeUiBaseToFree()
    end
    
end

-- --
--单列滚动停止回调
--
function CodeGameScreenWarriorAliceMachine:slotOneReelDown(reelCol)  
    self:slotOneReelDownByRespin(reelCol)
    local isTriggerLongRun = CodeGameScreenWarriorAliceMachine.super.slotOneReelDown(self,reelCol) 

    --设置快滚速度
    --比如 第二列开始有快滚 那么第一列 滚动停止之后 走下面的判断
    -- 如果第一列开始 就有快滚了 走的是 MachineRule_ResetReelRunData 里面的设置速度
    local specialList = self:getRespinLongRunForCol()
    self:sortSpecialList(specialList)
    if self:checkTriggerRespinLongRun() then
        if not self.m_isBeginLongRun then
            for i, _col in ipairs(specialList) do
                if _col-1 == reelCol then
                    self.m_isBeginLongRun = true

                    for i = _col, self.m_iReelColumnNum do
                        --后面列停止加速移动
                        local parentData = self.m_slotParents[i]
                
                        parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
                    end
                end
            end
            
        end
    end

    --期待感动画
    for iCol = 1,reelCol do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(symbolNode) then
                if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and isTriggerLongRun and symbolNode.m_currAnimName ~= "idleframe1" then
                    symbolNode:runAnim("idleframe1",true)
                end
            end
        end
    end
    
    --停轮后检查是否有拖尾，有的话直接删除
    for iRow = 1, self.m_iReelRowNum do
        local slotNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if slotNode and slotNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            slotNode:removeBonusBg()
        end
    end

    -- for iRow = 1, self.m_iReelRowNum do
    --     local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
    --     if symbolType == self.SYMBOL_FIX_SYMBOL then
    --         local symbolNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            
            -- if symbolNode.trailingNode then
            --     symbolNode.trailingNode:removeFromParent()
            --     symbolNode.trailingNode = nil
            -- end
    --     end
    -- end

    if not self.m_isLongRun then
        self.m_isLongRun = isTriggerLongRun
    end
    

    return isTriggerLongRun
end

function CodeGameScreenWarriorAliceMachine:slotOneReelDownByRespin(reelCol)
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        if self.curLongReelNum == reelCol then
            --停止迎击
            if self.curQueenShowAct then
                self.curQueenShowAct = false
                self:respinLongReelOver(reelCol)
                self:showGrandQueenAct(false)
            end
            if self.curBigSoldiderShowAct then
                self.curBigSoldiderShowAct = false
                self:respinLongReelOver(reelCol)
                self:hiteJackpotBossAct(reelCol)
            end
            if not tolua.isnull(self.flyLineNode) then
                self.flyLineNode:removeFromParent()
                self.flyLineNode = nil

                if self.m_isChangeParent then
                    -- grand 提层还原
                    self.m_jackPotBar:setPosition(util_convertToNodeSpace(self.m_jackPotBar, self:findChild("Node_grand")))
                    util_changeNodeParent(self:findChild("Node_grand"), self.m_jackPotBar)
                    if self.m_grandShow then
                        self.m_grandShow = false
                        self.m_jackPotBar:runCsbAction("over3", false)
                    else
                        
                    end
                    
                    self.m_isChangeParent = false
                end
            end
            
        end
        local longRunType = self:checkOneReelIsShowEffect(reelCol + 1) 
        if longRunType > 0 then
            if not tolua.isnull(self.flyLineNode) then
                self.flyLineNode:removeFromParent()
                self.flyLineNode = nil
            end
            if longRunType == 1 then
                self.curBigSoldiderShowAct = true
                self.flyLineNode = self:runFlyLineAct(reelCol + 1,false)
                self:showJackpotBossEngageAct(reelCol + 1)
            elseif longRunType == 2 then
                self.curQueenShowAct = true
                self.flyLineNode = self:runFlyLineAct(reelCol + 1,true)
                self:showGrandQueenAct(true)
            end
            
            self:respinLongReelStart(reelCol + 1)
            self.curLongReelNum = reelCol + 1
        end 
    end
end
-- ------------根据玩法改变ui
function CodeGameScreenWarriorAliceMachine:changeReelKuang(index)
    if index == NORMAL_INDEX.INDEX_ONE then
        self:findChild("Node_basekuang"):setVisible(true)
        self:findChild("Node_freerespinkuang"):setVisible(false)
    else
        self:findChild("Node_basekuang"):setVisible(false)
        self:findChild("Node_freerespinkuang"):setVisible(true)
    end
end


function CodeGameScreenWarriorAliceMachine:changeNodeReel(index)
    if index == NORMAL_INDEX.INDEX_ONE then
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("Node_respin_reel"):setVisible(false)
        self:findChild("Node_jiangexian"):setVisible(false)
    elseif index == NORMAL_INDEX.INDEX_TWO then
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("Node_respin_reel"):setVisible(false)
        self:findChild("Node_jiangexian"):setVisible(true)
    else
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("Node_respin_reel"):setVisible(true)
        self:findChild("Node_jiangexian"):setVisible(true)
    end
end

function CodeGameScreenWarriorAliceMachine:changeGameBg(index)
    if index == NORMAL_INDEX.INDEX_ONE then
        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("respin_bg"):setVisible(false)
    elseif index == NORMAL_INDEX.INDEX_TWO then
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(true)
        self.m_gameBg:findChild("respin_bg"):setVisible(false)
    else
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("respin_bg"):setVisible(true)
    end
end

-- -----------------------------上方角色
function CodeGameScreenWarriorAliceMachine:changeRedQueen(index)
    self.m_QueenNode:stopAllActions()
    if index == NORMAL_INDEX.INDEX_ONE then
        self.redQueen:setVisible(false)
    elseif index == NORMAL_INDEX.INDEX_TWO then
        self.redQueen:setVisible(true)
        self.redQueen:setSkin("FREE")
        self:playQueenIdle()
    else
        self.redQueen:setVisible(true)
        self.redQueen:setSkin("RESPIN")
        self:playQueenIdle()
    end
end

function CodeGameScreenWarriorAliceMachine:playQueenIdle()
    self.m_QueenNode:stopAllActions()
    local randNum = math.random(1,100)
    if randNum < 15 then
        util_spinePlay(self.redQueen,"idle2")
    else
        util_spinePlay(self.redQueen,"idle")
    end
    
    performWithDelay(self.m_QueenNode,function ()
        self:playQueenIdle()
    end,80/30)
end

--进入respin
function CodeGameScreenWarriorAliceMachine:playQueenActInRespin()
    self.m_QueenNode:stopAllActions()
    self.redQueen:setSkin("RESPIN")
    util_spinePlay(self.redQueen,"actionframe")
    performWithDelay(self.m_QueenNode,function ()
        self:playQueenIdle()
    end,80/30)
end

--红皇后受击
function CodeGameScreenWarriorAliceMachine:playQueenActEliminate()
    self.m_QueenNode:stopAllActions()
    self.redQueen:setSkin("RESPIN")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_queen_attacked)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_queen_ah)
    util_spinePlay(self.redQueen,"actionframe2")
    performWithDelay(self.m_QueenNode,function ()
        self:playQueenIdle()

        self.m_GrandJiangLi:setVisible(true)
        util_spinePlay(self.m_GrandJiangLi,"actionframe")
        util_spineEndCallFunc(self.m_GrandJiangLi, "actionframe", function()
            self.m_GrandJiangLi:setVisible(false)
        end)

        self.m_jackPotBar:runCsbAction("actionframe_zj", false)
    end,25/30)

    -- 界面震动
    if self.m_isPlayShake then
        self:shakeRootNode()
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWarriorAliceMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    -- self:changeUiBaseToFree()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWarriorAliceMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    -- self:changeUiFreeToBase()
end
---------------------------------------------------------------------------


----------- FreeSpin相关

-- 显示free spin
function CodeGameScreenWarriorAliceMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end
    -- 停掉背景音乐
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
    else
        self:clearCurMusicBg()
        -- 播放震动
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end

    --播放触发动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    node:setVisible(false)
                    node:changeParentToOtherNode(self.m_clipParent)
                    -- 重新创建一个scatter 层级放在锁定框上面
                    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    local newStartPos = self:findChild("yugao"):convertToNodeSpace(startPos)
                    local newScatterSpine = util_spineCreate("Socre_WarriorAlice_Scatter",true,true)
                    self:findChild("yugao"):addChild(newScatterSpine)
                    newScatterSpine:setPosition(newStartPos)
                    util_spinePlay(newScatterSpine, "actionframe", false)
                    util_spineEndCallFunc(newScatterSpine, "actionframe",function()
                        node:setVisible(true)
                        self:delayCallBack(1 / 60,function()
                            newScatterSpine:removeFromParent()
                            newScatterSpine = nil
                        end)
                    end)
                end
            end
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_scatter_trigger_in_free)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_scatter_trigger_in_base)
    end

    
    
    self:delayCallBack(2,function ()
        self:showFreeSpinView(effectData)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
        
    end)
    return true
end

function CodeGameScreenWarriorAliceMachine:showFreeSpinStart(num, func, isAuto)
    self.m_baseFreeSpinBar:setCurNum(globalData.slotRunData.totalFreeSpinCount)
    local function guoChangFunc()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_change_scene_from_base_to_free)
        --过场动画
        -- self.m_currentMusicBgName = "WarriorAliceSounds/music_WarriorAlice_freegame.mp3"
        self:resetMusicBg(nil,"WarriorAliceSounds/music_WarriorAlice_freegame.mp3")
        self:showGuochang(function ()
            self:changeUiBaseToFree()
            self.wenAn:setVisible(false)
            self.m_baseFreeSpinBar:setVisible(true)
            self:triggerFreeSpinCallFun()
            -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息
        end)
    end
    local params = {
        path = "WarriorAlice/FreeSpinStart.csb",
        btnName = "Button_1",
        endFunc = func,
        isAuto = false,
        num = num,
        guoChangFunc = guoChangFunc,
    }
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_free_spin_start)
    local view = util_createView("CodeWarriorAliceSrc.WarriorAliceShowView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenWarriorAliceMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local params = {
        path = "WarriorAlice/FreeSpinMore.csb",
        btnName = nil,
        endFunc = newFunc,
        isAuto = true,
        num = num,
        guoChangFunc = nil,
        isRespin = true
    }
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_free_spin_more)
    local view = util_createView("CodeWarriorAliceSrc.WarriorAliceShowView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

-- FreeSpinstart
function CodeGameScreenWarriorAliceMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("winSounds/music_win_custom_enter_fs.mp3")
    self.isFreeToRespin = true

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                
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

function CodeGameScreenWarriorAliceMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
    -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    -- self:resetMusicBg()
end

function CodeGameScreenWarriorAliceMachine:showFreeSpinOverView()
    self:clearCurMusicBg()
    -- gLobalSoundManager:playSound("winSounds/music_win_over_fs.mp3")
    self.isFreeToRespin = false
    if globalData.slotRunData.lastWinCoin == 0 then
        self:showNoWinView(function ()

            self:changeUiFreeToBase()
            self.wenAn:setVisible(true)
            self:showTipsIdle()
            self.m_baseFreeSpinBar:setVisible(false)

            self:triggerFreeSpinOverCallFun()

        end)
    else
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()

                self:changeUiFreeToBase()
                self.wenAn:setVisible(true)
                self:showTipsIdle()
                self.m_baseFreeSpinBar:setVisible(false)

                self:triggerFreeSpinOverCallFun()
            
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},622)
    end
end

function CodeGameScreenWarriorAliceMachine:showFreeSpinOver(coins, num, func)
    
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_free_spin_over)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_hide_free_spin_over)
    end)
    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end


--无赢钱
function CodeGameScreenWarriorAliceMachine:showNoWinView(func)
    local view = self:showDialog("NoWin", nil, func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenWarriorAliceMachine:changeUiBaseToFree()
    self:changeReelKuang(NORMAL_INDEX.INDEX_TWO)
    self:changeGameBg(NORMAL_INDEX.INDEX_TWO)
    self:changeNodeReel(NORMAL_INDEX.INDEX_TWO)
    self:changeRedQueen(NORMAL_INDEX.INDEX_TWO)
end

function CodeGameScreenWarriorAliceMachine:changeUiFreeToBase()
    self:changeReelKuang(NORMAL_INDEX.INDEX_ONE)
    self:changeGameBg(NORMAL_INDEX.INDEX_ONE)
    self:changeNodeReel(NORMAL_INDEX.INDEX_ONE)
    self:changeRedQueen(NORMAL_INDEX.INDEX_ONE)
end

------------------------------------respin消除士兵相关 start --------------------------------------------
--[[
    @desc: currentBonusIcon：本次spin需要消除的列表{棋盘出现bonus位置，消除钱数}//////dropBonus：本次spin结束后未消除的数量
    选中-斩击-出钱-移动钱-反馈
    流程：1、根据currentBonusIcon计算行列，记录每列消除的数量，在self.smallSoldierList中获取士兵item
         2、设置显示隐藏，创建需要飞的钱，飞钱
         3、每列item的rowIndex - 移动的数量 计算出需要移动的rowIndex，在self.smallSoldierList中获取需要移动的item
    author:{author}
    time:2022-12-23 11:18:48
    --@func: 
    @return:
]]

function CodeGameScreenWarriorAliceMachine:updateUpPeopleCheckAct(func)
    --播放压暗
    self.yaHei:setVisible(true)
    self.yaHei:runCsbAction("start",false,function ()
        self.yaHei:runCsbAction("idle")
    end)
    local selfData = self.m_runSpinResultData.p_selfMakeData

    --选中动画
    local function checkSoldier(col)
        --消除的数量
        local num = BONUS_NUM - self:getDropNum(col)
        for i=1,num do
            local smallSoldier = self.smallSoldierList[col][i]
            if smallSoldier and smallSoldier.isShow == true then
                smallSoldier:getParent():setLocalZOrder(1000 - i)
                --被选中动画
                smallSoldier:showCheckAct(col)
                
            end
        end
        
    end

    -- self:delayCallBack(20/60,function ()
        if selfData and selfData.currentBonusIcon then
            local currentBonusIcon = selfData.currentBonusIcon or {}
            if table_length(currentBonusIcon) > 0 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_soldier_select)
            end
            
            for i,v in ipairs(currentBonusIcon) do
                local info = v[1]
                local fixPos = self:getRowAndColByPos(tonumber(info))
                checkSoldier(fixPos.iY)
            end
        end
    -- end)

    if self:isShowGrandEliminate() then
        self.redQueen:getParent():setLocalZOrder(1000)
        self.m_jackPotBar:getParent():setLocalZOrder(1100)
    end

    self:delayCallBack(40/30,function ()
        --选中后进行消除
        self:updateUpPeople(func)
    end)
    
end

function CodeGameScreenWarriorAliceMachine:updateUpPeople(func)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_bonus_chop)
    --播放斩击动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                    node:runAnim("zhanji", false, function()
                        node:runAnim("idleframe4", true)
                    end)
                end
            end
        end
    end

    self:delayCallBack(20/30,function ()
        self.tempCoinsIndex = 1
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.currentBonusIcon then
            local currentBonusIcon = clone(selfData.currentBonusIcon) or {}
            for i,v in ipairs(currentBonusIcon) do
                local info = v[1]
                local fixPos = self:getRowAndColByPos(tonumber(info))
                --记录消除数量
                self:changeEliminateNum(fixPos.iY)
                self:showSoldierEliminate(fixPos.iY,fixPos.iX,v[2])
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_clear_soldier)
        end
        self:reelActForEliminate()
        --压暗消失
        self.yaHei:runCsbAction("over",false,function ()
            self.yaHei:setVisible(false)
            self.redQueen:getParent():setLocalZOrder(550)
            self.m_jackPotBar:getParent():setLocalZOrder(560)
        end)

        self:delayCallBack(35/30,function ()
            self:sortCoinsNode()
            local num = #self.tempCoins
            self:flyCoins(num,func)
        end)
    end)
    
end

--每列未消除的数量
function CodeGameScreenWarriorAliceMachine:getDropNum(col)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    local dropBonus = clone(selfData.dropBonus)
    for k,v in pairs(dropBonus) do
        local dropNum = tonumber(k) + 1
        if col == dropNum then
            if v < 0 then
                return 0
            else
                return v
            end
            
        end
    end
end

function CodeGameScreenWarriorAliceMachine:isShowGrandEliminate()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData and selfData.currentJackpotResult then
        if table_length(selfData.currentJackpotResult) > 0 then
            local jackpotList = selfData.currentJackpotResult or {}
            for k,v in pairs(jackpotList) do
                local info = jackpotList[k]
                local jackpotIndex = self:getJackpotIndex(info.jackpot)
                if jackpotIndex == 1 then
                    return true
                end
            end
        end
    end
    return false
end

--消除小兵/对应位置显示钱数
function CodeGameScreenWarriorAliceMachine:showSoldierEliminate(col,row,winCoins)

    --若有grand出现,上方人物受击
    if self:isShowGrandEliminate() then
        --上方框idle
        -- self.m_jackPotBar:isShowJackpotIdle(true)
        self:playQueenActEliminate()
    end
    
    --消除的数量
    local num = BONUS_NUM - self:getDropNum(col)
    self.tempCoins = {}
    for i=1,num do
        local smallSoldier = self.smallSoldierList[col][i]
        if smallSoldier and smallSoldier.isShow == true then
            smallSoldier.isShow = false
            --被斩击动画
            smallSoldier:showEliminateAct(col)
            self:createSoldierJinBiEffect(smallSoldier)
            self:delayCallBack(11/30,function ()
                smallSoldier:hideJackpotAct(false)
                self:createSoldierCoins(col,i,smallSoldier,winCoins)
            end)
            self:delayCallBack(22/30,function ()
                smallSoldier:setVisible(false)
            end)
            return
        end
    end
end

function CodeGameScreenWarriorAliceMachine:createSoldierJinBiEffect(smallSoldier)
    local pos = cc.p(0, 0)
    local jinBiSpine = util_spineCreate("WarriorAlice_shibing_jinbi",true,true)
    if smallSoldier.isBoss then
        if not tolua.isnull(smallSoldier.m_jackpotNode) then
            pos = util_convertToNodeSpace(smallSoldier.m_jackpotNode, self:findChild("root"))
        else
            pos = util_convertToNodeSpace(smallSoldier:findChild("node_jackpot"), self:findChild("root"))
        end
    else
        pos = util_convertToNodeSpace(smallSoldier,self:findChild("root"))
    end
    self:findChild("root"):addChild(jinBiSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 7)
    jinBiSpine:setPosition(pos)
    util_spinePlay(jinBiSpine, "actionframe2")

    self:delayCallBack(25/30,function ()
        jinBiSpine:removeFromParent()
        jinBiSpine = nil
    end)
end

function CodeGameScreenWarriorAliceMachine:createSoldierCoins(col,row,smallSoldier,winCoins)
    local pos = cc.p(0, 0)
    local coins = util_createAnimation("WarriorAlice_soldier_coins.csb")
    if smallSoldier.isBoss then
        self.bossJackpotList[col]:setVisible(false)
        local jackpotType = self:getItemJackpotType(col)
        coins = util_createView("CodeWarriorAliceSrc.WarriorAliceItemJackPotBarView",jackpotType)  --jackpot
        coins:showCoinsForLabel(winCoins)
        
        coins:isShowJackpotIdle(true)
        coins:initMachine(nil)
        coins.isBoss = true
        if not tolua.isnull(smallSoldier.m_jackpotNode) then
            pos = util_convertToNodeSpace(smallSoldier.m_jackpotNode, self:findChild("root"))
        else
            pos = util_convertToNodeSpace(smallSoldier:findChild("node_jackpot"), self:findChild("root"))
        end
        self:findChild("root"):addChild(coins,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 7)
    else
        coins:findChild("m_lb_coins"):setString(util_formatCoins(winCoins,3))
        coins.isBoss = false
        pos = util_convertToNodeSpace(smallSoldier,self:findChild("root"))
        self:findChild("root"):addChild(coins,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 8)
    end
    
    coins:setPosition(pos)
    coins.col = col
    coins.row = row
    coins.pos = pos
    coins.winCoins = winCoins
    self.tempCoins[#self.tempCoins + 1] = coins
end

function CodeGameScreenWarriorAliceMachine:updateUpPeopleInitGame()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    --每列未消除的数量
    local dropBonus = clone(selfData.dropBonus) or {}
    if selfData and selfData.dropBonus then
        for k,v in pairs(dropBonus) do
            --列数
            local col = tonumber(k) + 1
            if v < 0 then
                v = 0
            end
            local num = BONUS_NUM - v
            for i=1,num do
                local smallSoldier = self.smallSoldierList[col][i]
                if smallSoldier and smallSoldier.isShow == true then
                    
                    self:changeEliminateNum(col)
                    smallSoldier.isShow = false
                    smallSoldier:setVisible(false)
                    if smallSoldier.isBoss then
                        --jackpot
                        self.bossJackpotList[col]:setVisible(false)
                    end
                end
            end
        end
    end
end

function CodeGameScreenWarriorAliceMachine:createSmallSoldier()
    
    self.smallSoldierList = {}
    self.bossJackpotList = {}
    --列数
    for i=1,5 do
        self.smallSoldierList[i] = {}
        --行数
        for j=1,4 do
            local Item = nil
            if j == 4 then
                --创建bossItem
                local params = {i,j}
                Item = util_createView("CodeWarriorAliceSrc.WarriorAliceBossItem",params)
                local jackpotType = self:getItemJackpotType(i)

                local itemJackPotBar = util_createView("CodeWarriorAliceSrc.WarriorAliceItemJackPotBarView",jackpotType)  --jackpot
                Item:addJackpotToNode(i,itemJackPotBar)

                
                util_changeNodeParent(self:findChild("Node_soldiersmall"), itemJackPotBar, 590)
                local jackpotPos = util_convertToNodeSpace(self:findChild("Node_"..i.."_"..j), self:findChild("Node_soldiersmall"))
                itemJackPotBar:setPosition(cc.p(jackpotPos.x + 21,jackpotPos.y + 10))
                if i == 3 then
                    local posY = itemJackPotBar:getPositionY()
                    itemJackPotBar:setPositionY(posY + 10)
                elseif i == 2 or i == 4 then
                    local posY = itemJackPotBar:getPositionY()
                    itemJackPotBar:setPositionY(posY + 5)
                end
                self.bossJackpotList[i] = itemJackPotBar
                
                itemJackPotBar:initMachine(self)
                Item.isBoss = true
            else
                local params = {i,j}
                --创建士兵item
                Item = util_createView("CodeWarriorAliceSrc.WarriorAliceSoldierSItem",params)
                Item.isBoss = false
            end
            self:findChild("Node_"..i.."_"..j):addChild(Item)
            self:findChild("Node_"..i.."_"..j):setLocalZOrder((4 - j) + self:getSoldierZOrder(i))
            Item.oldZOrder = (4 - j) + self:getSoldierZOrder(i)
            Item.colIndex = i
            Item.rowIndex = j
            Item.isShow = true
            self.smallSoldierList[i][j] = Item
        end
    end
end

--[[
    士兵的层级要求
    第三列最高 然后第二列 第四列 第一列 第五例外
]]
function CodeGameScreenWarriorAliceMachine:getSoldierZOrder(_col)
    if _col == 3 then
        return 500
    elseif _col == 2 then
        return 400
    elseif _col == 4 then
        return 300
    elseif _col == 1 then
        return 200
    elseif _col == 5 then
        return 100
    end
end

--大将在对应列停轮后播idle
function CodeGameScreenWarriorAliceMachine:hiteJackpotBossAct(reelCol)
    local boss = self.smallSoldierList[reelCol][4]
    if boss and boss.isShow and boss.isBoss then
        boss:showResetAllIttemByBoss(4,reelCol)
    end
end

function CodeGameScreenWarriorAliceMachine:showCoinsOverAct()
    for i,v in ipairs(self.tempCoins) do
        if v.isBoss then
            -- local jackpotType = self:getItemJackpotType(v.col)
            -- v:showJackpotLizi(jackpotType)
            -- v:runCsbAction("over", false)
            -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_item_jackpot_bar_over)
        else
            -- v:runCsbAction("over")
        end
        
    end
    self:delayCallBack(1,function ()
        self:clearTempCoins()
    end)
end

function CodeGameScreenWarriorAliceMachine:flyCoins(num,func)
    -- local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("node_bar"),self:findChild("root"))
    local endPos1 = util_convertToNodeSpace(self:findChild("Node_respintotalwin"),self:findChild("root"))
    local endPos = cc.p(endPos1.x + 94,endPos1.y)
    if self.tempCoinsIndex > num or table_length(self.tempCoins) == 0  then
        --若有grand出现
        if self:isShowGrandEliminate() then
            self:showRespinJackpot(function ()
                -- self:showCoinsOverAct()
                self:updateSoldierPos(true,func)
                self.jackpotIndex = 1
            end)
        else
            -- self:showCoinsOverAct()
            self:updateSoldierPos(true,func)
            self.jackpotIndex = 1
        end
        
        return
    end

    local function flyEveryCoins (coins)
        local actList = {}
        local winCoins = coins.winCoins or 0
        local flyParticlePos = coins.pos
        if coins.isBoss then
            actList[#actList + 1] = cc.CallFunc:create(function ()
                coins:runCsbAction("actionframe2")
            end)
            actList[#actList + 1] = cc.DelayTime:create(1)
            actList[#actList + 1] = cc.CallFunc:create(function ()
                
                self:showRespinJackpot(function ()
                    self.m_respinTotalWin:runCsbAction("shouji",false)
                    for i=1,2 do
                        self.m_respinTotalWin:findChild("Particle_"..i):resetSystem()
                    end
                    self:updateTotalCoinsByRespin(winCoins)
                    local jackpotType = self:getItemJackpotType(coins.col)
                    coins:showJackpotLizi(jackpotType)
                    coins:runCsbAction("over", false)
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_item_jackpot_bar_over)
                    self.tempCoinsIndex = self.tempCoinsIndex + 1
                    self:delayCallBack(0.5,function ()
                        coins:setVisible(false)
                        coins:removeFromParent()
                        table.remove(self.tempCoins,1)
                        self:flyCoins(num,func)
                    end)
                end)
            end)
        else
            -- actList[#actList + 1] = cc.CallFunc:create(function ()
            --     coins:runCsbAction("actionframe")
            -- end)
            -- actList[#actList + 1] = cc.DelayTime:create(1/6)
            actList[#actList + 1] = cc.CallFunc:create(function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_collect_coin_to_total_win)
                -- self:flyParticle(flyParticlePos, endPos)
                self:newFlyParticle(coins,endPos)

            end)
            actList[#actList + 1] = cc.DelayTime:create(0.3)

            actList[#actList + 1] = cc.CallFunc:create(function ()
                self.m_respinTotalWin:runCsbAction("shouji",false)
                for i=1,2 do
                    self.m_respinTotalWin:findChild("Particle_"..i):resetSystem()
                end
                self:updateTotalCoinsByRespin(winCoins)
                self.tempCoinsIndex = self.tempCoinsIndex + 1
            end)
            -- actList[#actList + 1] = cc.DelayTime:create(0.5)
            actList[#actList + 1] = cc.CallFunc:create(function ()
                table.remove(self.tempCoins,1)
                coins:removeFromParent()
                -- if coins.isBoss then
                --     coins:runCsbAction("actionframe2", false, function()
                --         self:showRespinJackpot(function ()
                --             self:flyCoins(func)
                --         end)
                --     end)
                -- else
                    self:flyCoins(num,func)
                -- end
            end)
        end
        -- actList[#actList + 1] = cc.RemoveSelf:create()
        coins:runAction(cc.Sequence:create(actList))
    end
    
    flyEveryCoins(self.tempCoins[1])
    
end

function CodeGameScreenWarriorAliceMachine:showBottomAct(winCoins)
    self.m_jiesuanAct:setVisible(true)
    self:updateBottomCoins(winCoins,false,true)

    util_spinePlay(self.m_jiesuanAct, "actionframe1")
    util_spineEndCallFunc(self.m_jiesuanAct, "actionframe1", function()
        self.m_jiesuanAct:setVisible(true)
    end)
end

function CodeGameScreenWarriorAliceMachine:newFlyParticle(coins,endPos,func)
    -- -- 创建粒子
    -- local flyNode =  util_createAnimation("WarriorAlice_soldier_lizitw.csb")
    -- coins:findChild("Node_1"):addChild(flyNode)
    -- local particle1 = flyNode:findChild("Particle_1")
    -- local particle2 = flyNode:findChild("Particle_2")
    -- local particle3 = flyNode:findChild("Particle_3")
    local actList = {}
    -- actList[#actList + 1] = cc.CallFunc:create(function (  )
    --     particle1:setDuration(-1)     --设置拖尾时间(生命周期)
    --     particle1:setPositionType(0)   --设置可以拖尾
    --     particle1:resetSystem()

    --     particle2:setDuration(-1)
    --     particle2:setPositionType(0)
    --     particle2:resetSystem()

    --     particle3:setDuration(-1)
    --     particle3:setPositionType(0)
    --     particle3:resetSystem()
    -- end)
    actList[#actList + 1] = cc.EaseIn:create(cc.MoveTo:create(0.4, endPos),2)
    -- actList[#actList + 1] = cc.CallFunc:create(function (  )
    --     particle1:stopSystem()--移动结束后将拖尾停掉
    --     particle2:stopSystem()
    --     particle3:stopSystem()
    -- end) 
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end) 
    -- actList[#actList + 1] = cc.CallFunc:create(function (  )
    --     flyNode:removeFromParent()
    -- end) 
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if coins then
            coins:setVisible(false)
        end
    end) 
    coins:runAction(cc.Sequence:create( actList))
end

function CodeGameScreenWarriorAliceMachine:flyParticle(startPos,endPos,func)
    -- -- 创建粒子
    local flyNode =  util_createAnimation("WarriorAlice_soldier_lizitw.csb")
    self:findChild("root"):addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 9)
    
    flyNode:setPosition(cc.p(startPos))
    local particle1 = flyNode:findChild("Particle_1")
    local particle2 = flyNode:findChild("Particle_2")
    local particle3 = flyNode:findChild("Particle_3")
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        particle1:setDuration(-1)     --设置拖尾时间(生命周期)
        particle1:setPositionType(0)   --设置可以拖尾
        particle1:resetSystem()

        particle2:setDuration(-1)
        particle2:setPositionType(0)
        particle2:resetSystem()

        particle3:setDuration(-1)
        particle3:setPositionType(0)
        particle3:resetSystem()
    end)
    actList[#actList + 1] = cc.MoveTo:create(0.3, endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        particle1:stopSystem()--移动结束后将拖尾停掉
        particle2:stopSystem()
        particle3:stopSystem()
    end) 
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end) 
    actList[#actList + 1 ] = cc.DelayTime:create(0.5)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        flyNode:removeFromParent()
    end) 
    flyNode:runAction(cc.Sequence:create( actList))
end

function CodeGameScreenWarriorAliceMachine:runFlyLineAct(col,isQueen)
    
    local endPos = util_convertToNodeSpace(self:findChild("endLine_"..col),self:findChild("root"))
    local startPos = util_convertToNodeSpace(self:findChild("Node_"..col.."_1"),self:findChild("root"))
    if isQueen then
        
        endPos = util_convertToNodeSpace(self:findChild("endLine_"..col),self:findChild("yugao"))
        if col == 1 then
            startPos = util_convertToNodeSpace(self:findChild("Node_grand_1"),self:findChild("yugao"))
        elseif col == 5 then
            startPos = util_convertToNodeSpace(self:findChild("Node_grand_5"),self:findChild("yugao"))
        else
            startPos = util_convertToNodeSpace(self:findChild("Node_grand"),self:findChild("yugao"))
        end
    end
    --计算两点之间距离
    local distance = math.sqrt(math.pow(startPos.x - endPos.x , 2) + math.pow(startPos.y - endPos.y , 2))
    local flyNode =  nil
    if isQueen then
        self.lightingSound2 = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_queen_light,false,function ()
            self.lightingSound2 = nil
        end)
        flyNode =  util_createAnimation("WarriorAlice_guangxian.csb")
        self:findChild("yugao"):addChild(flyNode,1)
    else
        self.lightingSound2 = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_soldier_light,false,function ()
            self.lightingSound2 = nil
        end)
        flyNode =  util_createAnimation("WarriorAlice_guangxian2.csb")
        self:findChild("root"):addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    end
    
    flyNode:setPosition(startPos)
    
    if isQueen then
        self.m_isChangeParent = true
        -- grand 提层
        self.m_jackPotBar:setPosition(util_convertToNodeSpace(self.m_jackPotBar, self:findChild("yugao")))
        util_changeNodeParent(self:findChild("yugao"), self.m_jackPotBar, 2)
        if self.m_isQuickly then
            
        else
            self.m_jackPotBar:runCsbAction("start3", false,function ()
                self.m_grandShow = true
                self.m_jackPotBar:runCsbAction("idle3", true)
            end)
        end
        
        -- performWithDelay(self.m_grandShowNode,function ()
        --     self.m_grandShow = true
            
        -- end,1/6)
        --不同列旋转角度
        if col == 1 then
            flyNode:setRotation(20)
        elseif col == 2 then
            flyNode:setRotation(14)
        elseif col == 4 then
            flyNode:setScaleX(-1)
            flyNode:setRotation(-14)
        elseif col == 5 then
            flyNode:setScaleX(-1)
            flyNode:setRotation(-20)
        end
        flyNode:setScaleY(distance/650)
    end
    
    flyNode:runCsbAction("actionframe",true)
    return flyNode
end

function CodeGameScreenWarriorAliceMachine:updateSoldierPos(isMove,func)
    local showOneSound = true
    local delayTime = 0
    if isMove then
        delayTime = 21/60
    end
    --延迟目的是等钱数播over
    -- self:delayCallBack(delayTime,function ()
        
        local isPlayMoveSound = false
        for iCol=1,5 do
            local curSoldierList = self.smallSoldierList[iCol]
            --获取需要移动的列

            local num = self:getMoveNum(iCol)
            if num > 0 then
                for j,v in ipairs(curSoldierList) do
                    if v.isShow then
                        local row = v.rowIndex - num
                        local endPos = util_convertToNodeSpace(self:findChild("Node_"..iCol.."_"..row),v:getParent())
                        local endPosJackpot1 = util_convertToNodeSpace(self:findChild("Node_"..iCol.."_"..row),self:findChild("Node_soldiersmall"))
                        local endPosJackpot = cc.p(endPosJackpot1.x + 21,endPosJackpot1.y + 10)
                        if iCol == 3 then
                            endPosJackpot = cc.p(endPosJackpot1.x + 21,endPosJackpot1.y + 20)
                        elseif iCol == 2 or iCol == 4 then
                            endPosJackpot = cc.p(endPosJackpot1.x + 21,endPosJackpot1.y + 15)
                        end
                        
                        if isMove then
                            if self:getDropNum(iCol) == 1 then
                                if v.isBoss then
                                    v:showSoldierMoveByBoss(iCol)--只剩一个BOSS
                                else
                                    v:showSoldierMove(iCol)
                                end
                                
                            else
                                v:showSoldierMove(iCol)
                            end
                            isPlayMoveSound = true
                            v:runAction(cc.MoveTo:create(40/30, endPos))
                            if v.isBoss then
                                self.bossJackpotList[iCol]:runAction(cc.MoveTo:create(40/30, endPosJackpot))
                            end
                            
                            self:delayCallBack(40/30,function ()
                                if self:getDropNum(iCol) == 1 then
                                    if v.isBoss then
                                        v:showResetAllIttemByBoss(row,iCol)--只剩一个BOSS
                                    else
                                        v:showResetAllIttem(row,iCol)
                                    end
                                    
                                else
                                    v:showResetAllIttem(row,iCol)
                                end
                            end)
                        else
                            v:setPosition(endPos)
                            if v.isBoss then
                                self.bossJackpotList[iCol]:setPosition(endPosJackpot)
                            end
                        end
                        v.rowIndex = row
                    end
                end
            end
            
        end
        if isPlayMoveSound then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_move_soldier) 
        end
        if isPlayMoveSound then
            self:delayCallBack(40/30,function ()
                --将playGameEffect传到这，移动才算是一次消除结束
                if func then
                    func()
                end
            end)
        else
            --将playGameEffect传到这，移动才算是一次消除结束
            if func then
                func()
            end
        end
        
    -- end)
    

end

--判断消除对象若为对应列boss(消息回来时调用)
function CodeGameScreenWarriorAliceMachine:showJackpotBossEngageAct(col)
    local function isBossForCol(col)
        for k,v in pairs(self.oldDropBonus) do
            if tonumber(k) + 1 == col then
                if v == 1 then
                    return true
                end
            end
        end
        return false
    end

    if isBossForCol(col) then
        local smallSoldier = self.smallSoldierList[col][4]
        if smallSoldier and smallSoldier.isShow == true and smallSoldier.isBoss then
            smallSoldier:showToEngageAct(4,col)
        end
    end

end

function CodeGameScreenWarriorAliceMachine:showGrandQueenAct(isShow)
    if isShow then
        self.m_QueenNode:stopAllActions()
        self.redQueen:setSkin("RESPIN")
        util_spinePlay(self.redQueen,"actionframe3",true)
    else
        self:changeRedQueen(NORMAL_INDEX.INDEX_THREE)
    end
end


function CodeGameScreenWarriorAliceMachine:changeEliminateNum(col)
    if col == NORMAL_INDEX.INDEX_ONE then
        self.oneMoveNum = self.oneMoveNum + 1
    elseif col == NORMAL_INDEX.INDEX_TWO then
        self.twoMoveNum = self.twoMoveNum + 1
    elseif col == NORMAL_INDEX.INDEX_THREE then
        self.threeMoveNum = self.threeMoveNum + 1
    elseif col == NORMAL_INDEX.INDEX_FOUR then
        self.fourMoveNum = self.fourMoveNum + 1
    elseif col == NORMAL_INDEX.INDEX_FIVE then
        self.fiveMoveNum = self.fiveMoveNum + 1
    end
end

function CodeGameScreenWarriorAliceMachine:resetEliminateNum()
    self.oneMoveNum = 0
    self.twoMoveNum = 0
    self.threeMoveNum = 0
    self.fourMoveNum = 0
    self.fiveMoveNum = 0
end

function CodeGameScreenWarriorAliceMachine:getItemJackpotType(index)
    if index == 1 or index == 5 then
        return 4
    elseif index == 2 or index == 4 then
        return 3
    elseif index == 3 then
        return 2
    end
end

function CodeGameScreenWarriorAliceMachine:getMoveNum(col)
    if col == NORMAL_INDEX.INDEX_ONE then
        return self.oneMoveNum
    elseif col == NORMAL_INDEX.INDEX_TWO then
        return self.twoMoveNum 
    elseif col == NORMAL_INDEX.INDEX_THREE then
        return self.threeMoveNum
    elseif col == NORMAL_INDEX.INDEX_FOUR then
        return self.fourMoveNum
    elseif col == NORMAL_INDEX.INDEX_FIVE then
        return self.fiveMoveNum
    end
    return 0
end

function CodeGameScreenWarriorAliceMachine:resetAllSoldier()
    for i=1,5 do
        for j=1,4 do
            local smallSoldier = self.smallSoldierList[i][j]
            local oldZOrder = smallSoldier.oldZOrder or (4 - j) + self:getSoldierZOrder(i)
            smallSoldier:getParent():setLocalZOrder(oldZOrder)
            smallSoldier:setPosition(cc.p(0,0))
            smallSoldier.isShow = true
            smallSoldier.colIndex = i
            smallSoldier.rowIndex = j
            smallSoldier:setVisible(true)
            smallSoldier:showResetAllIttem(j,i)
        end
    end
    for i=1,5 do
        local bossJackpot = self.bossJackpotList[i]
        local pos = util_convertToNodeSpace(self:findChild("Node_"..i.."_"..4), self:findChild("Node_soldiersmall"))
        local newPos = cc.p(pos.x + 21,pos.y + 10)
        bossJackpot:setPosition(newPos)
        bossJackpot:setVisible(true)
        if i == 3 then
            local posY = bossJackpot:getPositionY()
            bossJackpot:setPositionY(posY + 10)
        elseif i == 2 or i == 4 then
            local posY = bossJackpot:getPositionY()
            bossJackpot:setPositionY(posY + 5)
        end
    end
end

function CodeGameScreenWarriorAliceMachine:clearAllSoldier()
    for i=1,5 do
        for j=1,4 do
            local smallSoldier = self.smallSoldierList[i][j]
            if smallSoldier then
                smallSoldier:removeFromParent()
            end
        end
    end
    self.smallSoldierList = {}
end

function CodeGameScreenWarriorAliceMachine:sortCoinsNode()
    table.sort(
        self.tempCoins,
        function(a, b)
            if a.col ~= b.col then
                return a.col < b.col
            else
                return a.row < b.row
            end
        end
    )
end

function CodeGameScreenWarriorAliceMachine:clearTempCoins()
    
    for i,v in ipairs(self.tempCoins) do
        if v then
            v:removeFromParent()
        end
    end
    self.tempCoins = {}
end

function CodeGameScreenWarriorAliceMachine:reelActForEliminate()
    self:runCsbAction("actionframe",false,function ()
        self:runCsbAction("idle",true)
    end)
end

------------------------------------respin消除士兵相关 end --------------------------------------------


------------------------------------开门 start --------------------------------------------
--[[
    @desc: mysteryChange：{开门图标位置，改变后的信号值}
    流程：1、根据开门图标的位置创建一个假的开门图标做开门动画
         2、将棋盘的开门图标改变成改变后的信号值
         3、做完开门图标后移除掉
    author:{author}
    time:2022-12-23 11:41:00
    @return:
]]

function CodeGameScreenWarriorAliceMachine:clearDoorList( )
    for i, vNode in ipairs(self.tempDoorList) do
        if not tolua.isnull(vNode) then
            vNode:removeFromParent()
        end
    end
    self.tempDoorList = {}
end

function CodeGameScreenWarriorAliceMachine:showOpenDoorEffect(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mysteryChange = selfData.mysteryChange or {}
    for k,symbolType in pairs(mysteryChange) do
        local info = tonumber(k)
        local fixPos = self:getRowAndColByPos(info)
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        --创建一个假的门图标，用来打开
        local pos = util_convertToNodeSpace(symbolNode,self.m_clipParent)
        local tempDoor = util_spineCreate("Socre_WarriorAlice_Kaimen",true,true)
        self.m_clipParent:addChild(tempDoor,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5)
        tempDoor:setPosition(cc.p(pos))
        table.insert(self.tempDoorList,tempDoor)
        
        if symbolNode then
            --改变门下图标
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            symbolNode:changeCCBByName(ccbName, symbolType)
            
            symbolNode:changeSymbolImageByName(ccbName)
            if symbolType == self.SYMBOL_FIX_SYMBOL then
                symbolNode:runAnim("idleframe6",true)
            end
        end
    end
    -- self.openDoorEffect = effectData
    self:showOpenDoorAction(function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
            self.m_isQuickly = false
        end
    end)
end

function CodeGameScreenWarriorAliceMachine:showOpenDoorAction(endFunc)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mysteryChange = selfData.mysteryChange or {}
    local actName,delayFrame = "actionframe",5
    if table_length(mysteryChange) >= 4 then
        actName,delayFrame = "actionframe1",10
    end
    local actList = {}
    local actList1 = {}

    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        local isH1 = false
        local isBonus = false
        
        for j,symbolType in pairs(mysteryChange) do
            if symbolType == 0 then
                isH1 = true
                break
            end
        end
        for j,symbolType in pairs(mysteryChange) do
            if symbolType == 94 then
                isBonus = true
                break
            end
        end
        if isH1 and not isBonus then
            self.openDoorSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_open_doorForH1,false,function (  )
                self.openDoorSoundId = nil
            end)
        elseif not isH1 and isBonus then
            self.openDoorSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_open_door,false,function (  )
                self.openDoorSoundId = nil
            end)
        elseif isH1 and isBonus then
            self.openDoorSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_open_door,false,function (  )
                self.openDoorSoundId = nil
            end)
        else
            if table_length(self.tempDoorList) > 0 then
                self.openDoorSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_open_door,false,function (  )
                    self.openDoorSoundId = nil
                end)
            end
        end
        for i,v in ipairs(self.tempDoorList) do
            util_spinePlay(v,actName,false)
            util_spineEndCallFunc(v,actName,function ()
                v:setVisible(false)
            end)
        end
        
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(0.9)

    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        self:clearDoorList()
        --检测是否有大赢 free respin
        if self:getEffectType() then
            if type(endFunc) == "function" then
                -- self.openDoorEffect = nil
                endFunc()
            end
        -- elseif not self:getEffectType() and self.isAutoSpin then
        --     if type(endFunc) == "function" then
        --         self.isAutoSpin = false
        --         endFunc()
        --     end
        end
        
    end)

    actList1[#actList1 + 1] = cc.DelayTime:create(delayFrame/30)
    actList1[#actList1 + 1]  = cc.CallFunc:create(function(  )
        
        for k,v in pairs(mysteryChange) do
            local info = tonumber(k)
            local fixPos = self:getRowAndColByPos(info)
            local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType then
                if symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                    symbolNode:runAnim("idleframe7",false,function()
                        symbolNode:runAnim("idleframe4",true)
                    end)
                end
                
            end
        end
        
    end)
    

    local spawn = cc.Spawn:create({cc.Sequence:create( actList),cc.Sequence:create( actList1)})
    self.m_openDoorNode:runAction(spawn)

    --没有大赢 free respin
    if not self:getEffectType() then
        -- 开门不卡spin 直接进行下面流程
        if type(endFunc) == "function" then
            -- self.openDoorEffect = nil
            endFunc()
        end
    end
end

--[[
    开门图标 动画的时候 判断有没有大赢 free respin
]]
function CodeGameScreenWarriorAliceMachine:getEffectType( )
    if self:checkHasBigWin() then
        return true
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
        return true
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
        return true
    end

    return false
end

function CodeGameScreenWarriorAliceMachine:quicklyStopReel(colIndex)
    self.m_isQuickly = true
    
    CodeGameScreenWarriorAliceMachine.super.quicklyStopReel(self,colIndex)
end


------------------------------------开门 end --------------------------------------------

--快停
function CodeGameScreenWarriorAliceMachine:operaQuicklyStopReel()
    if self.m_quickStopReelIndex then
        return
    end
    --有停止并且未回弹的停止快停
    self.m_quickStopReelIndex = nil
    if self:checkTriggerRespinLongRun() then
        
    else
        for i=1,#self.m_reels do
            if self.m_reels[i]:isReelDone() then
                self.m_quickStopReelIndex = i
            end
        end
        
    end
    if not self.m_quickStopReelIndex then
        self:newQuickStopReel(1)
    end
end

--新快停逻辑
function CodeGameScreenWarriorAliceMachine:newQuickStopReel(index)
    --快停后检查是否有拖尾，有的话直接删除
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                slotNode:removeBonusBg()
            end
        end
    end
    self:removeSlotNodeParticle()
    CodeGameScreenWarriorAliceMachine.super.newQuickStopReel(self,index)
end

--清除拖尾
function CodeGameScreenWarriorAliceMachine:removeSlotNodeParticle()
    for i = 1, #self.m_falseParticleTbl do
        local particleNode = self.m_falseParticleTbl[i]
        if not tolua.isnull(particleNode) then
            particleNode:removeFromParent()
            self.m_falseParticleTbl[i] = nil
        end
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWarriorAliceMachine:MachineRule_SpinBtnCall()

    self:setMaxMusicBGVolume()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_bonus_down = {}
    self.m_scatter_down = {}

    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenWarriorAliceMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenWarriorAliceMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWarriorAliceMachine:addSelfEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if selfData and selfData.mysteryChange then
        if table_length(selfData.mysteryChange) > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.OPEN_DOOR_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.OPEN_DOOR_EFFECT -- 动画类型
        end
            
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        if selfData and selfData.currentBonusIcon then
            if table_length(selfData.currentBonusIcon) > 0 then
                -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.SOLDIER_ELIMINATE_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.SOLDIER_ELIMINATE_EFFECT -- 动画类型
            end
                
        end
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWarriorAliceMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.OPEN_DOOR_EFFECT then
        self:showOpenDoorEffect(effectData)
    end

    if effectData.p_selfEffectType == self.SOLDIER_ELIMINATE_EFFECT then
        if globalData.slotRunData.currSpinMode == RESPIN_MODE then
            if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            end
            local selfData = self.m_runSpinResultData.p_selfMakeData
            self.oldDropBonus = clone(selfData.dropBonus) or {}
            
            --消除上方小兵
            self:resetEliminateNum()
            self:updateUpPeopleCheckAct(function ()
                if effectData then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end)
        else
            if effectData then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end
    end

	return true
end

function CodeGameScreenWarriorAliceMachine:getJackpotIndex(index)
    if index == "grand" then
        return 1
    elseif index == "major" then
        return 2
    elseif index == "minor" then
        return 3
    else
        return 4
    end
end

function CodeGameScreenWarriorAliceMachine:showRespinJackpot(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentJackpotResult = selfData.currentJackpotResult
    if self.jackpotIndex > #currentJackpotResult then
        self.jackpotIndex = 1
        if func then
            func()
        end
        return
    end
    local jackPotWinView = util_createView("CodeWarriorAliceSrc.WarriorAliceJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)

    table.sort(currentJackpotResult, function(a, b)
        return a.position < b.position
    end)

    local info = currentJackpotResult[self.jackpotIndex]
    local index1 = info.jackpot
    local coins = info.jackpotCoins
    self.jackpotIndex = self.jackpotIndex + 1
    local date = {
        coins = coins,
        index = self:getJackpotIndex(index1),
        machine = self
    }
    jackPotWinView:initViewData(date)
    jackPotWinView:setOverAniRunFunc(function ()
        if self:getJackpotIndex(index1) == 1 then
            self.m_respinTotalWin:runCsbAction("shouji",false)
            for i=1,2 do
                self.m_respinTotalWin:findChild("Particle_"..i):resetSystem()
            end
            self:updateTotalCoinsByRespin(coins)
            -- self:updateBottomCoins(coins,false,false)
        end
        if func then
            func()
        end
    end)
    
end

--开始滚动
function CodeGameScreenWarriorAliceMachine:beginReel()
    self.m_isBeginLongRun = false
    self.m_isLongRun = false
    self.m_isQuickly = false
    self.m_playBulingEffectIndex = 0
    self.m_isReconnection = false--是否是重连轮

    CodeGameScreenWarriorAliceMachine.super.beginReel(self)
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
        end

        self:playLongRunIdleByReSpin()
    else
        for i, _LongRunAimNode in ipairs(self.specialLongRunAim) do
            if not tolua.isnull(_LongRunAimNode) and _LongRunAimNode:isVisible() == true then
                _LongRunAimNode:setVisible(false)
            end
        end
    end
    
    -- 再次spin的 时候 如果有还没有关闭的门 直接清理掉
    self.m_openDoorNode:stopAllActions()
    
    -- if self.openDoorEffect then
    --     self.openDoorEffect.p_isPlay = true
    --     self:playGameEffect()
    --     self.openDoorEffect = nil
    -- end
    if self.openDoorSoundId then
        gLobalSoundManager:stopAudio(self.openDoorSoundId)
        self.openDoorSoundId = nil
    end
    self:clearDoorList()
end

--[[
    延迟回调
]]
function CodeGameScreenWarriorAliceMachine:delayCallBack(time, func)
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
    spine 动画
]]
function CodeGameScreenWarriorAliceMachine:playSpineAnim(spNode, animName, isLoop, func)
    util_spinePlay(spNode, animName, isLoop == true)
    if func ~= nil then
        util_spineEndCallFunc(spNode, animName, function()
            func()
        end)
    end
end

-- ---------------------------respin滚动效果  start---------------------

function CodeGameScreenWarriorAliceMachine:createSpecialReelEffect(col)

    local reelEffectAct = util_createView("CodeWarriorAliceSrc.WarriorAliceSpecialReelAct",col)

    self.m_slotEffectLayer:addChild(reelEffectAct)
    self.specialLongRunAim[col] = reelEffectAct

    reelEffectAct:setVisible(false)

    return reelEffectAct
end

function CodeGameScreenWarriorAliceMachine:addSpecialLongRunEffect()
    for i = 1, self.m_iReelColumnNum do
        local reelEffectNode= self:createSpecialReelEffect(i)
        self:setLongAnimaInfo(reelEffectNode, i)
    end
end

function CodeGameScreenWarriorAliceMachine:respinLongReelStart(icol)
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        return
    end
    local reelEffectNode = self.specialLongRunAim[icol]
    reelEffectNode:setVisible(true)
    self.lightingSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_reel_light,false,function (  )
        self.lightingSound = nil
    end)
    reelEffectNode:runCsbAction("actionframe",false,function ()
        reelEffectNode:runCsbAction("idle1",true)
    end)
end

function CodeGameScreenWarriorAliceMachine:respinLongReelOver(icol)
    if self.lightingSound then
        gLobalSoundManager:stopAudio(self.lightingSound)
        self.lightingSound = nil
    end
    if self.lightingSound2 then
        gLobalSoundManager:stopAudio(self.lightingSound2)
        self.lightingSound2 = nil
    end
    local reelEffectNode = self.specialLongRunAim[icol]
    reelEffectNode:runCsbAction("over",false,function ()
        reelEffectNode:runCsbAction("idle",true)
    end)
end

function CodeGameScreenWarriorAliceMachine:hideRespinLongReel()
    for i, _LongRunAimNode in ipairs(self.specialLongRunAim) do
        if _LongRunAimNode then
            _LongRunAimNode:showReelActForCol(i, false)
            _LongRunAimNode:setVisible(false)
        end
    end
end

function CodeGameScreenWarriorAliceMachine:clearSpecialLongRunList()
    for i,v in ipairs(self.specialLongRunAim) do
        if v then
            v:removeFromParent()
        end
        
    end
    self.specialLongRunAim = {}
end

--判断列是否要显示reelEffect  返回1是大将闪电效果，返回2是红皇后闪电效果
function CodeGameScreenWarriorAliceMachine:checkOneReelIsShowEffect(col)
    for k,v in pairs(self.oldDropBonus) do
        if tonumber(k) + 1 == col then
            if v == 1 then
                return 1
            elseif v < 1 then
                return 2
            end
        end
    end
    return 0
end

-- ---------------------------respin滚动效果  end---------------------

--[[
    @desc: respin快滚逻辑：上方消除剩下一个的时候当列触发特殊快滚，增加期待效果
    author:{author}
    time:2022-12-21 10:52:14
    @return:
]]
function CodeGameScreenWarriorAliceMachine:checkTriggerRespinLongRun()
    for k,v in pairs(self.oldDropBonus) do
        if v <= 1 then
            return true
        end
    end
    return false
end

--获取需要长滚的列
function CodeGameScreenWarriorAliceMachine:getRespinLongRunForCol()
    local specialList = {}
    for k,v in pairs(self.oldDropBonus) do
        if v <= 1 then
            specialList[#specialList + 1] = tonumber(k) + 1
        end
    end
    return specialList
end

--将specialList排序
function CodeGameScreenWarriorAliceMachine:sortSpecialList(list)
    table.sort( list ,function (a,b)
        return a < b
    end)
end

-- 当前列是否有快滚框
function CodeGameScreenWarriorAliceMachine:getIsHaveRun(_col, _specialList)
    for i,v in ipairs(_specialList) do
        if _col == v then
            return true
        end
    end
    return false
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWarriorAliceMachine:MachineRule_ResetReelRunData()
    CodeGameScreenWarriorAliceMachine.super.MachineRule_ResetReelRunData(self)
    -- self.m_reelRunInfo 中存放轮盘滚动信息
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        local reelSpecialTime = 2   --快滚效果持续时间
        local cutTime = 0.2 --普通滚动间隔时间
        local specialList = self:getRespinLongRunForCol()
        self:sortSpecialList(specialList)
        if self:checkTriggerRespinLongRun() then
            
            for i,v in ipairs(specialList) do
                for j=v,self.m_iReelColumnNum do
                    local isHave = self:getIsHaveRun(j, specialList)
                    local reelRunInfo = self.m_reelRunInfo
                    local reelRunData = self.m_reelRunInfo[j]
                    local columnData = self.m_reelColDatas[j]

                    reelRunData:setReelLongRun(true)
                    local lastColLens = 0
                    if j > 1 then
                        lastColLens = reelRunInfo[j-1]:getReelRunLen()
                    end

                    local colHeight = columnData.p_slotColumnHeight
                    local reelCount = (cutTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                    if isHave then
                        reelCount = (reelSpecialTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                    end
                    
                    local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

                    reelRunData:setReelRunLen(runLen)
                    local parentData = self.m_slotParents[j]
                    -- 第一列是快滚的话 后续直接设置 加速
                    if v == 1 then
                        self.m_isBeginLongRun = true
                        parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
                    end
                end 
                break--循环一遍就行 不然同时有多列快滚的话specialList（多个值），后面列设置的快滚长度就有问题了 
            end
            
        end
    else
        if self.m_isPlayYuGao == false then
            if self:checkTriggerAddBonusLongRun() then
                self.isBonusLongRun = true
                for iCol = self.LONGRUN_COL_ADD_BONUS, self.m_iReelColumnNum do
                    local reelRunInfo = self.m_reelRunInfo
                    local reelRunData = self.m_reelRunInfo[iCol]
                    local columnData = self.m_reelColDatas[iCol]
        
                    reelRunData:setReelLongRun(true)
                    reelRunData:setNextReelLongRun(true)
        
                    local reelLongRunTime = 2
                    if iCol > self.m_iReelColumnNum then
                        reelLongRunTime = 2
                        reelRunData:setReelLongRun(false)
                        reelRunData:setNextReelLongRun(false)
                    end
        
                    local iRow = columnData.p_showGridCount
                    local lastColLens = reelRunInfo[1]:getReelRunLen()
                    if iCol ~= 1 then
                        lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                        reelRunInfo[iCol - 1 ]:setNextReelLongRun(true)
                    end
        
                    local colHeight = columnData.p_slotColumnHeight
                    local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                    local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
        
                    local preRunLen = reelRunData:getReelRunLen()
                    reelRunData:setReelRunLen(runLen)
        
                end
            end
        end
        
    end
 
end

-- ---------------------- 特殊快滚
function CodeGameScreenWarriorAliceMachine:checkTriggerAddBonusLongRun( )
    local bonusNum = 0
    for iCol = 1 ,(self.m_iReelColumnNum - 1) do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
            if symbolType and symbolType == self.SYMBOL_FIX_SYMBOL then
                bonusNum = bonusNum + 1  
            end
        end
        
    end

    if bonusNum >= self.BONUS_RUN_NUM and not self.m_isPlayYuGao then
        self:setLongRunCol()
        return true
    end

    return false
end

function CodeGameScreenWarriorAliceMachine:setLongRunCol( )
    --前1列bonus大于等于4，第2列开始
    if self:getColBonusNum(1) >= self.BONUS_RUN_NUM then
        self.LONGRUN_COL_ADD_BONUS = 2
    --前2列bonus大于等于4，第3列开始
    elseif self:getColBonusNum(2) >= self.BONUS_RUN_NUM then
        self.LONGRUN_COL_ADD_BONUS = 3
    --前3列bonus大于等于4，第4列开始
    elseif self:getColBonusNum(3) >= self.BONUS_RUN_NUM then
        self.LONGRUN_COL_ADD_BONUS = 4
    elseif self:getColBonusNum(4) >= self.BONUS_RUN_NUM then
        self.LONGRUN_COL_ADD_BONUS = 5
    end
end

function CodeGameScreenWarriorAliceMachine:getColBonusNum(colNum)
    local bonusNum = 0
    for iCol = 1 , colNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
            if symbolType and symbolType == self.SYMBOL_FIX_SYMBOL then
                bonusNum = bonusNum + 1  
            end
        end 
    end
    return bonusNum
end

------------  respin 代码 这个respin就是不是单个小格滚动的那种 

function CodeGameScreenWarriorAliceMachine:showRespinView(effectData)
    local tempBonus = {}
    local winCoins = self.m_runSpinResultData.p_resWinCoins or 0
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    else
        --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:notifyTopWinCoin()
        self.m_bottomUI:checkClearWinLabel()
    end

    if not self.isRespinInitGame then
        self:updateWinCoinsLabel(0)
        self.m_lightScore = 0
        globalData.slotRunData.lastWinCoin = self.m_lightScore
    else
        self:updateWinCoinsLabel(winCoins)
        self.m_lightScore = winCoins
        globalData.slotRunData.lastWinCoin = self.m_lightScore
    end

    -- free玩法最后一次触发了respin 删除freeover 时间 之后在添加上
    self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)

    self:clearCurMusicBg()
    
    self:clearWinLineEffect()
    --触发respin
    --先播放动画 再进入respin
    --播放触发动画
    if not self.isRespinInitGame then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and node.p_symbolType then
                    if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                        node:setVisible(false)
                        node:changeParentToOtherNode(self.m_clipParent)
                        -- 重新创建一个scatter 层级放在锁定框上面
                        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                        local newStartPos = self:findChild("yugao"):convertToNodeSpace(startPos)
                        local newScatterSpine = util_spineCreate("Socre_WarriorAlice_Bonus",true,true)
                        self:findChild("yugao"):addChild(newScatterSpine)
                        newScatterSpine:setPosition(newStartPos)
                        local zOder = self:getBounsScatterDataZorder(self.SYMBOL_FIX_SYMBOL)
                        newScatterSpine:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - node.p_rowIndex)
                        tempBonus[#tempBonus + 1] = newScatterSpine
                        util_spinePlay(newScatterSpine, "actionframe2", false)
                        util_spineEndCallFunc(newScatterSpine, "actionframe2",function()
                            util_spinePlay(newScatterSpine, "idleframe4", true)
                        end)
                    end
                end
            end
        end
        -- for iCol = 1, self.m_iReelColumnNum do
        --     for iRow = 1, self.m_iReelRowNum do
        --         local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        --         if node and node.p_symbolType then
        --             if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
        --                 node:runAnim("actionframe2", false, function()
        --                     node:runAnim("idleframe4", true)
        --                 end)
        --             end
        --         end
        --     end
        -- end
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_bonus_trigger)
    
    
    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = false
    

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:delayCallBack(2,function ()
        for i,v in ipairs(tempBonus) do
            if v then
                v:removeFromParent()
            end
        end
        tempBonus = {}
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and node.p_symbolType then
                    if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                        node:setVisible(true)
                        node:runAnim("idleframe4", true)
                    end
                end
            end
        end
        self:showReSpinStart(function ()
            self.m_respinBar:setCurNum(self.m_runSpinResultData.p_reSpinCurCount)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_atmosphere_respin_start)
            self:playQueenActInRespin()
            self:showAllSoldierInRespin()
            self:delayCallBack(2,function ()
                local selfData = self.m_runSpinResultData.p_selfMakeData
                self.oldDropBonus = clone(selfData.dropBonus) or {}
                if self.isRespinInitGame then
                    self.isRespinInitGame = false
                    effectData.p_isPlay = true
                    self:playGameEffect()
                else
                    self:resetEliminateNum()
                    self:updateUpPeopleCheckAct(function ()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                end
                
            end)
        end)
    end)
end

---
-- 触发respin 玩法
--
-- function CodeGameScreenWarriorAliceMachine:showEffect_Respin(effectData)
--     self.m_beInSpecialGameTrigger = true

--     -- 停掉背景音乐
--     self:clearCurMusicBg()
--     if self.levelDeviceVibrate then
--         self:levelDeviceVibrate(6, "respin")
--     end
--     local removeMaskAndLine = function()
--         self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

--         -- 取消掉赢钱线的显示
--         self:clearWinLineEffect()

--         self:resetMaskLayerNodes()

--         -- 处理特殊信号
--         local childs = self.m_lineSlotNodes
--         for i = 1, #childs do
--             --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
--             local cloumnIndex = childs[i].p_cloumnIndex
--             if cloumnIndex then
--                 local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
--                 local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
--                 self:changeBaseParent(childs[i])
--                 childs[i]:setPosition(pos)
--                 self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
--             end
--         end
--     end

--     if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
--         scheduler.performWithDelayGlobal(
--             function()
--                 removeMaskAndLine()
--                 self:showPlayRespinView(effectData)
--             end,
--             1,
--             self:getModuleName()
--         )
--     else
--         self:showPlayRespinView(effectData)
--     end
--     gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
--     return true
-- end

--[[
    判断bonus落地动画 全部 播放完了 
    不然 可能会打断落地
]]
function CodeGameScreenWarriorAliceMachine:showPlayRespinView(effectData)
    -- self.m_timeScheduler = schedule(self, function ()
    --     if self.m_playBulingEffectIndex <= 0 then
    --         if self.m_timeScheduler then
    --             self:stopAction(self.m_timeScheduler)
    --             self.m_timeScheduler = nil
    --         end

    --         self:showRespinView(effectData)
    --     end
    -- end, 1/30)
    self:delayCallBack(1,function ()
        self:showRespinView(effectData)
    end)
end

--进入respin时播动作
function CodeGameScreenWarriorAliceMachine:showAllSoldierInRespin()
    local a = self.smallSoldierList
    for i=1,5 do
        for j=1,4 do
            local smallSoldier = self.smallSoldierList[i][j]
            if smallSoldier.isShow == true then
                smallSoldier:showInRespin(i)
                self:delayCallBack(42/30,function ()
                    smallSoldier:showResetAllIttem(j,i)
                end)
            end
        end
    end
end

function CodeGameScreenWarriorAliceMachine:showReSpinStart(func)

    local function guoChangFunc()
        
        --过场动画
        -- if self.isFreeToRespin then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_change_scene_from_base_to_respin)
            self:resetMusicBg(nil,"WarriorAliceSounds/music_WarriorAlice_respin.mp3")
            self:showGuochang2(NORMAL_INDEX.INDEX_TWO,function()
                if func then
                    func()
                end
            end,function ()
                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                self:beginReelShowMask()
                self.m_respinTotalWin:setVisible(true)
                self:changeParentByRespin()
            end)
        -- else
        --     self:showGuochang(function ()
        --         self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
        --         self:beginReelShowMask()
        --         self.m_respinTotalWin:setVisible(true)
        --         self:changeParentByRespin()
        --     end, function()
        --         if func then
        --             func()
        --         end
        --     end)
        -- end
        -- --断线重连
        -- if self.isRespinInitGame then
        --     self:resetEliminateNum()
        --     --刷新上方士兵显示
        --     self:updateUpPeopleInitGame()
        --     --刷新上方士兵位置
        --     self:updateSoldierPos(false,nil)
        -- end
    end

    local params = {
        path = "WarriorAlice/ReSpinStart.csb",
        btnName = "Button_1",
        endFunc = nil,
        isAuto = false,
        num = nil,
        guoChangFunc = guoChangFunc,
        isRespin = true
    }

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_respin_start)
    local view = util_createView("CodeWarriorAliceSrc.WarriorAliceShowView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    respin开始之前 棋盘上的开门图标和scatter图标 放到遮罩下面
    开门图标 只能变成bonus和兔子 处理兔子图标即可
]]
function CodeGameScreenWarriorAliceMachine:changeParentByRespin( )
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == 0 or node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local pos = util_convertToNodeSpace(node, self.m_slotParents[iCol].slotParent)
                    node:setPosition(pos)
                    self:changeBaseParent(node)
     
                    self:changeSymbolType(node, 0)
                end
            end
        end
    end
end

--接收到数据开始停止滚动
function CodeGameScreenWarriorAliceMachine:stopRespinRun()
    print("已经得到了数据")
end

--respin刷新赢钱
function CodeGameScreenWarriorAliceMachine:updateBottomCoins(winCoin, isUpdateTopUI, isPlayAnim, beiginCoins)
    globalData.slotRunData.lastWinCoin = winCoin
    self.m_bottomUI:notifyUpdateWinLabel(winCoin, isUpdateTopUI, isPlayAnim,beiginCoins)
end

--respin刷新赢钱 totalwin
function CodeGameScreenWarriorAliceMachine:updateTotalCoinsByRespin(winCoin)
    self:stopUpDateCoins()
    self:updateWinCoinsLabel(self.m_lightScore)

    self:jumpCoins(self.m_lightScore + winCoin, self.m_lightScore)

    self.m_lightScore = self.m_lightScore + winCoin
    globalData.slotRunData.lastWinCoin = self.m_lightScore
end

function CodeGameScreenWarriorAliceMachine:updateWinCoinsLabel(_winCoins)
    local sCoins = util_formatCoins(_winCoins, 30)
    local label  = self.m_respinTotalWin:findChild("m_lb_coins")
    if sCoins == "0" then
        label:setString("")
    else
        label:setString(sCoins)
    end
    self:updateLabelSize({label=label,sx=0.65,sy=0.65}, 414)
end

function CodeGameScreenWarriorAliceMachine:jumpCoins(coins, _curCoins)
    -- local curCoins = _curCoins or 0
    -- -- 每秒60帧
    -- local coinRiseNum =  (coins - _curCoins) / (0.3 * 60)  

    -- local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    -- coinRiseNum = tonumber(str)
    -- coinRiseNum = math.ceil(coinRiseNum ) 

    -- local node = self.m_respinTotalWin:findChild("m_lb_coins")

    -- self.m_updateAction = schedule(self,function()
    --     curCoins = curCoins + coinRiseNum
    --     curCoins = curCoins < coins and curCoins or coins
        --curCoins
        local sCoins = util_formatCoins(coins, 30)
        local label  = self.m_respinTotalWin:findChild("m_lb_coins")
        label:setString(sCoins)
        self:updateLabelSize({label=label,sx=0.65,sy=0.65}, 414)

    --     if curCoins >= coins then
    --         self:stopUpDateCoins()
    --     end
    -- end,0.008)
end

function CodeGameScreenWarriorAliceMachine:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
end

--ReSpin开始改变UI状态
function CodeGameScreenWarriorAliceMachine:changeReSpinStartUI(respinCount)
    self.wenAn:setVisible(false)
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_respinBar:setVisible(true)
    self:changeNodeReel(NORMAL_INDEX.INDEX_THREE)
    self:changeGameBg(NORMAL_INDEX.INDEX_THREE)
    self:changeRedQueen(NORMAL_INDEX.INDEX_THREE)
    self:changeReelKuang(NORMAL_INDEX.INDEX_TWO)
    self:changeReSpinUpdateUI(respinCount,true)
end

--ReSpin刷新数量
function CodeGameScreenWarriorAliceMachine:changeReSpinUpdateUI(curCount,isInit)

    self.m_respinBar:updateRespinCount(curCount,isInit)

end

--ReSpin结算改变UI状态
function CodeGameScreenWarriorAliceMachine:changeReSpinOverUI()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.wenAn:setVisible(false)
        self.m_baseFreeSpinBar:setVisible(true)
        self.m_respinBar:setVisible(false)
        self:changeNodeReel(NORMAL_INDEX.INDEX_TWO)
        self:changeRedQueen(NORMAL_INDEX.INDEX_TWO)
        self:changeGameBg(NORMAL_INDEX.INDEX_TWO)
    else
        self.wenAn:setVisible(true)
        self:showTipsIdle()
        self.m_baseFreeSpinBar:setVisible(false)
        self.m_respinBar:setVisible(false)
        self:changeNodeReel(NORMAL_INDEX.INDEX_ONE)
        self:changeRedQueen(NORMAL_INDEX.INDEX_ONE)
        self:changeGameBg(NORMAL_INDEX.INDEX_ONE)
        self:changeReelKuang(NORMAL_INDEX.INDEX_ONE)
    end
    self.isRespinInitGame = false
end

function CodeGameScreenWarriorAliceMachine:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    self:removeRespinNode()
    -- self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenWarriorAliceMachine:showRespinOverView(effectData)
    -- free玩法最后一次触发了respin ，再次添加freeover事件
    if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsTotalCount > 0 then
        if not self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end
    end
    if not tolua.isnull(self.flyLineNode) then
        self.flyLineNode:removeFromParent()
        self.flyLineNode = nil
    end
    if self.m_lightScore == 0 then
        self:showNoWinView(function ()

            self:resetAllSoldier()
            self.oldDropBonus = {}
            self:hideRespinLongReel()
            self.m_respinBar:setVisible(false)
            self.m_respinTotalWin:setVisible(false)
            self:reelStopHideMask()
            effectData.p_isPlay = true

            self:resetReSpinMode()
            self:changeReSpinOverUI()

            self.m_lightScore = 0
            self:resetMusicBg() 
            self:triggerReSpinOverCallFun(self.m_lightScore)
            
        end)
    else
        self:delayCallBack(0.8,function ()
            self:flyTotalWinByRespin(function()
                self:delayCallBack(0.7,function ()
                    local strCoins=util_formatCoins(self.m_lightScore,50)
                    local view = self:showReSpinOver(strCoins,function()

                        self:resetAllSoldier()
                        self.oldDropBonus = {}
                        self:hideRespinLongReel()
                        self.m_respinBar:setVisible(false)
                        self.m_respinTotalWin:setVisible(false)
                        self:reelStopHideMask()
                        effectData.p_isPlay = true
                        
                        self:resetReSpinMode()
                        self:changeReSpinOverUI()

                        self.m_lightScore = 0
                        self:resetMusicBg() 
                        self:triggerReSpinOverCallFun(self.m_lightScore)
                        if self.m_winSoundsId then
                            gLobalSoundManager:stopAudio(self.m_winSoundsId)
                            self.m_winSoundsId = nil
                        end
                        
                    end)
                    
                    local node=view:findChild("m_lb_coins")
                    view:updateLabelSize({label=node,sx=1,sy=1},622)
                end)
            end)
        end)
    end
end

function CodeGameScreenWarriorAliceMachine:showReSpinOver(coins, func, index)
    
        self:clearCurMusicBg()
        local ownerlist = {}
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        if self.respinOverSpundIndex == 0 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_respin_over_view1)
            self.respinOverSpundIndex = 1
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_respin_over_view2)
            self.respinOverSpundIndex = 0
        end
        
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func, nil, index)
        view:findChild("root"):setScale(self.m_machineRootScale)

        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_btn_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_hide_respin_over_view3)
            
        end)
        return view
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

function CodeGameScreenWarriorAliceMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        coins = self.m_serverWinCoins or 0

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    -- self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    -- self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
    respin结算之前 totalwin 飞
]]
function CodeGameScreenWarriorAliceMachine:flyTotalWinByRespin(_func)
    -- -- 创建粒子
    self.m_respinTotalWin:setVisible(false)
    local flyNode =  util_createAnimation("WarriorAlice_respintotalwin.csb")
    self:findChild("root"):addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 9)
    flyNode:setPosition(util_convertToNodeSpace(self.m_respinTotalWin, self:findChild("root")))
    local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("node_bar"),self:findChild("root"))

    local sCoins = util_formatCoins(self.m_lightScore, 30)
    local label  = flyNode:findChild("m_lb_coins")
    label:setString(sCoins)
    self:updateLabelSize({label=label,sx=0.65,sy=0.65}, 414)

    -- 棋盘中间的坐标
    local qipanPos = util_convertToNodeSpace(self:findChild("Node_flyTotalWin"),self:findChild("root"))
    local actList = {}
    actList[#actList + 1] = cc.MoveTo:create(20/60, qipanPos)--移动到棋盘中间
    actList[#actList + 1] = cc.DelayTime:create(40/60)
    actList[#actList + 1] = cc.MoveTo:create(30/60, cc.p(qipanPos.x, qipanPos.y+70))--往上移动一点
    actList[#actList + 1] = cc.MoveTo:create(8/60, endPos)--砸下去
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self.m_bProduceSlots_InFreeSpin then
            local winCoins = self.m_runSpinResultData.p_fsWinCoins or self.m_lightScore
            self:showBottomAct(winCoins)
        else
            self:showBottomAct(self.m_lightScore)
        end
    end) 
    actList[#actList + 1] = cc.DelayTime:create(0.5)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if _func then
            _func()
        end
        flyNode:removeFromParent()
    end) 
    flyNode:runAction(cc.Sequence:create( actList))
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_collect_total_win)
    
    flyNode:runCsbAction("fly")
end

function CodeGameScreenWarriorAliceMachine:MachineRule_respinTouchSpinBntCallBack()
    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == RESPIN_MODE then 
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        release_print("STR_TOUCH_SPIN_BTN 触发了 free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        release_print("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            release_print("STR_TOUCH_SPIN_BTN 触发了 normal")
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            release_print("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end 

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN  then  -- 表明滚动了起来。。
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end


function CodeGameScreenWarriorAliceMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenWarriorAliceMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenWarriorAliceMachine:slotReelDown( )

    self.curLongReelNum = 0

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                    if node.m_currAnimName == "idleframe3" then
                        node:runAnim("idleframe4", true)
                    end
                elseif node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and node.m_currAnimName == "idleframe1" then--只有播期待动画的图标播idle
                    node:runAnim("idleframe2", true)
                end
            end
        end
    end

    self.isBonusLongRun = false
    self.m_isPlayYuGao = false
    CodeGameScreenWarriorAliceMachine.super.slotReelDown(self)
end

function CodeGameScreenWarriorAliceMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenWarriorAliceMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

--是否触发全屏动画
function CodeGameScreenWarriorAliceMachine:isShowQuanPing()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.currentJackpotResult then
        if table_length(selfData.currentJackpotResult) > 0 then
            -- 50%概率 触发
            local random = math.random(1, 10)
            if random <= 5 then
                return true
            else
                return false
            end
        end
    end
    return false
end

function CodeGameScreenWarriorAliceMachine:playQuanPingAnim()
    local animTime = 0

    if self.m_isPlayYuGao then
        animTime  = 60/30
        self.m_quanPing:setVisible(true)
        self.m_quanPingPeople:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_full_screen_ani)
        util_spinePlay(self.m_quanPing, "actionframe3", false)
        util_spineEndCallFunc( self.m_quanPing,"actionframe3",function()
            self.m_quanPing:setVisible(false)
        end)
        util_spinePlay(self.m_quanPingPeople, "actionframe", false)
        util_spineEndCallFunc( self.m_quanPingPeople,"actionframe",function()
            self.m_quanPingPeople:setVisible(false)
        end)
    end

    return animTime
end

--是否触发中奖预告
function CodeGameScreenWarriorAliceMachine:isShowYuGao()
    if self:getCurrSpinMode() == RESPIN_MODE then
        return self:isShowQuanPing()
    end
    local features = self.m_runSpinResultData.p_features
    if #features >= 0 and features[2] == 3 then
        local random = math.random(1,10)
        if random < 5 then
            return true
        end
    end
    return false
end

--[[
    @desc: 预告中奖
]]
function CodeGameScreenWarriorAliceMachine:playYugaoAnim()
    local animTime = 0

    if self.m_isPlayYuGao then
        animTime  = 60/30
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_notice_win)
        self.m_yugao:setVisible(true)
        util_spinePlay(self.m_yugao, "actionframe_yugao", false)
        util_spineEndCallFunc( self.m_yugao,"actionframe_yugao",function()
            self.m_yugao:setVisible(false)
        end)
    end

    return animTime
end

function CodeGameScreenWarriorAliceMachine:updateNetWorkData()
    

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    if self:isShowYuGao() then
        self.m_isPlayYuGao = true
    end
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    self.m_isWaitingNetworkData = false

    if self:getCurrSpinMode() == RESPIN_MODE then
        local func = function()
            local longRunType = self:checkOneReelIsShowEffect(NORMAL_INDEX.INDEX_ONE)
            if longRunType > 0 then
                if not tolua.isnull(self.flyLineNode) then
                    self.flyLineNode:removeFromParent()
                    self.flyLineNode = nil
                end
                if longRunType == 1 then
                    self.curBigSoldiderShowAct = true
                    self.flyLineNode = self:runFlyLineAct(NORMAL_INDEX.INDEX_ONE,false)
                    self:showJackpotBossEngageAct(NORMAL_INDEX.INDEX_ONE)
                elseif longRunType == 2 then
                    self.curQueenShowAct = true
                    self.flyLineNode = self:runFlyLineAct(NORMAL_INDEX.INDEX_ONE,true)
                    self:showGrandQueenAct(true)
                end 
                
                self:respinLongReelStart(NORMAL_INDEX.INDEX_ONE)
                self.curLongReelNum = NORMAL_INDEX.INDEX_ONE
            end

            self:operaNetWorkData() -- end
        end
        --是否播全屏预告
        if self.m_isPlayYuGao then
            local animTime = self:playQuanPingAnim()
            self:delayCallBack(animTime,func)
        else
            func()
        end
        
    else
        if self.m_isPlayYuGao then
            local animTime = self:playYugaoAnim()
            self:delayCallBack(animTime,function ()
                self:operaNetWorkData() -- end
            end)
        else
            self:operaNetWorkData() -- end
        end
        
    end
    
end

function CodeGameScreenWarriorAliceMachine:dealSmallReelsSpinStates()
    CodeGameScreenWarriorAliceMachine.super.dealSmallReelsSpinStates(self)
    --是否触发respin特殊长滚
    if self:checkTriggerRespinLongRun() then
        --stop按钮不允许点击
        -- self:triggerLongRunChangeBtnStates()
    end
end


--[[
    过场动画
]]
function CodeGameScreenWarriorAliceMachine:showGuochang(func, func1)
    self.m_spineGuochang:setVisible(true)
    util_spinePlay(self.m_spineGuochang, "actionframe")
    util_spineEndCallFunc(self.m_spineGuochang, "actionframe", function ()
        self.m_spineGuochang:setVisible(false)
    end)
    if func ~= nil then
        self:delayCallBack(51 / 30, function ()
            if func then
                func()
            end
        end)
    end

    if func1 ~= nil then
        self:delayCallBack(60 / 30, function ()
            if func1 then
                func1()
            end
        end)
    end
end

function CodeGameScreenWarriorAliceMachine:createGuoChang2Effect()
    self.m_spineGuochang2 = util_spineCreate("WarriorAlice_guochang2", true, true)
    self:addChild(self.m_spineGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_UI + 14)
    self.m_spineGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang2:setVisible(false)

    self.m_spineGuochang3 = util_spineCreate("WarriorAlice_guochang2", true, true)
    self:addChild(self.m_spineGuochang3, GAME_LAYER_ORDER.LAYER_ORDER_UI + 11)
    self.m_spineGuochang3:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang3:setVisible(false)

    self.jveseGuoChang = util_spineCreate("WarriorAlice_juese", true, true)
    self:addChild(self.jveseGuoChang, GAME_LAYER_ORDER.LAYER_ORDER_UI + 13)
    self.jveseGuoChang:setPosition(display.width * 0.5, display.height * 0.5)
    self.jveseGuoChang:setVisible(false)

    self.bonusGuoChang = util_spineCreate("Socre_WarriorAlice_Bonus", true, true)
    self:addChild(self.bonusGuoChang, GAME_LAYER_ORDER.LAYER_ORDER_UI + 15)
    self.bonusGuoChang:setPosition(display.width * 0.5, display.height * 0.5)
    self.bonusGuoChang:setVisible(false)
end

function CodeGameScreenWarriorAliceMachine:showGuochang2(index,func,changeFunc)
    -- local blackEffect = util_createAnimation("WarriorAlice_yahei.csb")
    -- self:addChild(blackEffect, GAME_LAYER_ORDER.LAYER_ORDER_UI + 10)
    -- blackEffect:setPosition(display.width * 0.5, display.height * 0.5)
    -- blackEffect:runCsbAction("start")

    self.bonusGuoChang:setVisible(true)
    util_spinePlay(self.bonusGuoChang, "actionframe_guochang", false)
    util_spineEndCallFunc( self.bonusGuoChang,"actionframe_guochang",function()
        self.bonusGuoChang:setVisible(false)
    end)

    if index == NORMAL_INDEX.INDEX_ONE then
        self.jveseGuoChang:setSkin("FREE")
    else
        self.jveseGuoChang:setSkin("RESPIN")
    end
    self.jveseGuoChang:setVisible(true)
    util_spinePlay(self.jveseGuoChang, "actionframe_guochang", false)
    util_spineEndCallFunc( self.jveseGuoChang,"actionframe_guochang",function()
        self.jveseGuoChang:setVisible(false)
    end)
    self.m_spineGuochang2:setVisible(true)
    util_spinePlay(self.m_spineGuochang2, "actionframe_guochang_S")
    util_spineEndCallFunc(self.m_spineGuochang2, "actionframe_guochang_S", function ()
        self.m_spineGuochang2:setVisible(false)
    end)
    self.m_spineGuochang3:setVisible(true)
    util_spinePlay(self.m_spineGuochang3, "actionframe_guochang_X")
    util_spineEndCallFunc(self.m_spineGuochang3, "actionframe_guochang_X", function ()
        self.m_spineGuochang3:setVisible(false)
    end)
    self:delayCallBack(80/30,function ()
        -- blackEffect:runCsbAction("over",false,function ()
        --     blackEffect:removeFromParent()
        -- end)
    end)
    if changeFunc then
        self:delayCallBack(60/30,function ()
            changeFunc()
        end)
    end
    if func ~= nil then
        self:delayCallBack(100/30, function ()
            if func then
                func()
            end
        end)
    end
end

--[[
    大赢飘数字
]]
function CodeGameScreenWarriorAliceMachine:playBigWinNum(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_line_big_win)
    self.m_jiesuanAct:setVisible(true)
    util_spinePlay(self.m_jiesuanAct, "actionframe")
    util_spineEndCallFunc(self.m_jiesuanAct, "actionframe", function()
        self.m_jiesuanAct:setVisible(false)
    end)

    self.m_bigwinEffectNum:setVisible(true)
    local winCoins = self.m_runSpinResultData.p_winAmount
    local coinsText = self.m_bigwinEffectNum:findChild("m_lb_coins")
    if winCoins then
        local strCoins = "+" .. util_formatCoins(winCoins, 15)
        coinsText:setVisible(true)

        local curCoins = 0
        local coinRiseNum =  winCoins / (1 * 60)  -- 每秒60帧
        local curRiseStrCoins = "+" .. util_formatCoins(coinRiseNum, 15)
        coinsText:setString(curRiseStrCoins)
        self:updateLabelSize({label=coinsText,sx=1,sy=1},520)

        self.m_scWaitNodeAction:stopAllActions()
        util_schedule(self.m_scWaitNodeAction, function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= winCoins then
                coinsText:setString(strCoins)
                self:updateLabelSize({label=coinsText,sx=1,sy=1},520)
                self.m_scWaitNodeAction:stopAllActions()
                self:delayCallBack(0.6,function ()
                    self.m_bigwinEffectNum:runCsbAction("over",false, function()
                        self.m_bigwinEffectNum:setVisible(false)
                    end)
                end)
                
            else
                local curStrCoins = "+" .. util_formatCoins(curCoins, 15)
                coinsText:setString(curStrCoins)
                self:updateLabelSize({label=coinsText,sx=1,sy=1},520)
            end
        end, 1/60)
    end
    self.m_bigwinEffectNum:runCsbAction("start",false, function()
        self.m_bigwinEffectNum:runCsbAction("idle", true)
    end)
    
    self:delayCallBack(1.5, function ()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenWarriorAliceMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    end
end

function CodeGameScreenWarriorAliceMachine:scaleMainLayer()
    CodeGameScreenWarriorAliceMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.68
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 10)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.79 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.87 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.95 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio <= 768/1370 then
    end
    if display.width/display.height >= 1812/2176 then
        local mainScale = 0.58
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenWarriorAliceMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isLongRun and _slotNode.p_cloumnIndex < self.m_iReelColumnNum then
            if _slotNode.m_currAnimName ~= "idleframe1" then
                _slotNode:runAnim("idleframe1",true)
            end
            
        else
            _slotNode:runAnim("idleframe2",true)
        end
        -- self:checkPlayScatterDownSound(_slotNode.p_cloumnIndex)
    elseif _slotNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
        -- self:checkPlayBonusDownSound(_slotNode.p_cloumnIndex)
    end
end

--[[
    检测播放bonus落地音效
]]
function CodeGameScreenWarriorAliceMachine:checkPlayBonusDownSound(colIndex)
    if not self.m_bonus_down[colIndex] then
        --播放bonus
        self:playBonusDownSound(colIndex)
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_bonus_down[iCol] = true
        end
    else
        self.m_bonus_down[colIndex] = true
    end
end

--[[
    检测播放scatter落地音效
]]
function CodeGameScreenWarriorAliceMachine:checkPlayScatterDownSound(colIndex)
    if not self.m_scatter_down[colIndex] then
        --播放bonus
        self:playScatterDownSound(colIndex)
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_scatter_down[iCol] = true
        end
    else
        self.m_scatter_down[colIndex] = true
    end
end


--[[
    播放bonus落地音效
]]
function CodeGameScreenWarriorAliceMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_bonus_down)
end

--[[
    播放scatter落地音效
]]
-- function CodeGameScreenWarriorAliceMachine:playScatterDownSound(colIndex)
--     gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_scatter_down)
-- end

-- 有特殊需求判断的 重写一下
function CodeGameScreenWarriorAliceMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:getScatterIsRun(_slotNode.p_cloumnIndex) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                if _slotNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                    return true
                else
                    -- 开门图标提层 目的是让开出来的bonus图标层级在最高
                    -- 开门图标不播放落地动画
                    return false
                end
            end
        end
    end

    return false
end

--[[
    判断scatter是否快滚
]]
function CodeGameScreenWarriorAliceMachine:getScatterIsRun(_col)
    local scatterNum = 0
    for iCol = 1, _col do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    scatterNum = scatterNum + 1
                end
            end
        end
    end
    if _col <= 3 then
        return true
    elseif _col == 4 then
        if scatterNum >= 2 then
            return true
        else
            return false
        end
    elseif _col == 5 then
        if scatterNum >= 3 then
            return true
        else
            return false
        end
    end
end

-- respin玩法 每列消除的士兵 还剩1个 或者全部消除完棋盘上对应的快滚框 需要一直播放idle
function CodeGameScreenWarriorAliceMachine:playLongRunIdleByReSpin( )
    
    for iCol = 1, self.m_iReelColumnNum do
        local dropBonusNum = self:getDropNum(iCol)
        if dropBonusNum <= 1 then
            local reelEffectNode = self.specialLongRunAim[iCol]
            if reelEffectNode then
                if dropBonusNum == 0 then
                    reelEffectNode:showReelActForCol(iCol, true)
                else
                    reelEffectNode:showReelActForCol(iCol, false)
                end
                
                reelEffectNode:setVisible(true)
                reelEffectNode:runCsbAction("idle",true)
            end
        end
    end
end

--轮盘滚动显示遮罩
function CodeGameScreenWarriorAliceMachine:beginReelShowMask()
    for i,maskNode in ipairs(self.m_maskNodeTab) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            maskNode:setOpacity(0)
            maskNode:runAction(cc.FadeTo:create(0.5,150))
        end
    end
end

--轮盘停止隐藏遮罩
function CodeGameScreenWarriorAliceMachine:reelStopHideMask()
    for i,maskNode in ipairs(self.m_maskNodeTab) do
        if maskNode:isVisible() == true then
            local fadeAct = cc.FadeTo:create(0.5, 0)
            local func = cc.CallFunc:create(function ()
                maskNode:setVisible(false)
            end)
            maskNode:runAction(cc.Sequence:create(fadeAct,func))
        end
    end
end

function CodeGameScreenWarriorAliceMachine:playCustomSpecialSymbolDownAct( slotNode )
    if slotNode and slotNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
        local reelEffectNode = self.specialLongRunAim[slotNode.p_cloumnIndex]
        local buLingName = "buling"
        -- respin 玩法 有快滚的时候 播放buling2
        if reelEffectNode and reelEffectNode:isVisible() then
            buLingName = "buling2"
            -- 棋盘震动
            if self.m_isPlayShake then
                self:shakeQiPanNode()
            end
        end

        local symbolNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        self.m_playBulingEffectIndex = self.m_playBulingEffectIndex + 1
        symbolNode:runAnim(buLingName,false,function()
            self.m_playBulingEffectIndex = self.m_playBulingEffectIndex - 1
            if self.isBonusLongRun then
                slotNode:runAnim("idleframe3",true)
            else
                slotNode:runAnim("idleframe4",true)
            end
        end)
    end
end

--[[
    界面震动
    respin玩法 红皇后受到砍击的时候
]]
function CodeGameScreenWarriorAliceMachine:shakeRootNode( )
    self.m_isPlayShake = false
    local changePosY = 5
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,3 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    actionList2[#actionList2 + 1] = cc.CallFunc:create(function ()
        self.m_isPlayShake = true
    end)
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

--[[
    棋盘震动
    respin玩法 快滚列滚出来bonus 播落地动画的时候
]]
function CodeGameScreenWarriorAliceMachine:shakeQiPanNode( )
    self.m_isPlayShake = false
    local changePosY = 3
    local changePosX = 0
    local actionList2={}
    local oldPos = cc.p(self:findChild("Node_reel"):getPosition())
    for i = 1,1 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    actionList2[#actionList2 + 1] = cc.CallFunc:create(function ()
        self.m_isPlayShake = true
    end)
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("Node_reel"):runAction(seq2)
end

--大赢震动
function CodeGameScreenWarriorAliceMachine:shakeNode()
    local changePosY = 10
    local changePosX = 5
    local actionList2 = {}
    local oldPos = cc.p(self:findChild("root"):getPosition())

    for i=1,5 do
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    end

    local seq2 = cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function CodeGameScreenWarriorAliceMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do
        local columnData = self.m_reelColDatas[colIndex]

        local rowCount,rowNum,rowIndex = self:getinitSlotRowDatatByNetData(columnData )

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            -- 如果是开门 图标 看看需不需要替换
            if symbolType == self.SYMBOL_FIX_DOOR then
                symbolType = self:initChangeSymbol(rowIndex, colIndex, symbolType)
            end

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end
            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:runIdleAnim()      
            rowIndex = rowIndex - 1
        end  -- end while
    end
    self:initGridList()
end

--[[
    断线进入的时候 如果是开门图标则替换成 需要的图标
]]
function CodeGameScreenWarriorAliceMachine:initChangeSymbol(rowIndex, colIndex, symbolType)
    if self.m_initSpinData.p_selfMakeData and self.m_initSpinData.p_selfMakeData.mysteryChange then
        local index = (rowIndex - 1) * self.m_iReelColumnNum + (colIndex - 1)
        local mysteryChange = self.m_initSpinData.p_selfMakeData.mysteryChange or {}
        for posIndex, changeSymbolType in pairs(mysteryChange) do
            if tonumber(posIndex) == index then
                return changeSymbolType
            end
        end
    end 
    return symbolType
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenWarriorAliceMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        -- respin玩法 假滚数据 根据剩余小兵数量决定
        if self:getCurrSpinMode() == RESPIN_MODE then
            local dropBonusNUm = self:getDropNum(parentData.cloumnIndex)
            local respinModelID = 1
            if dropBonusNUm >= 3 then
                respinModelID = 1
            elseif dropBonusNUm == 2 then
                respinModelID = 2
            else
                respinModelID = 3
            end
            reelDatas = self.m_configData:getRespinReelDatasByColumnIndex(respinModelID, parentData.cloumnIndex)
        else
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        end
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function CodeGameScreenWarriorAliceMachine:getBottomUINode( )
    return "CodeWarriorAliceSrc.WarriorAliceBottomNode"
end

function CodeGameScreenWarriorAliceMachine:getBaseReelGridNode()
    return "CodeWarriorAliceSrc.WarriorAliceSlotNode"
end

--[[
    添加bonus拖尾
]]
function CodeGameScreenWarriorAliceMachine:updateReelGridNode(node)
    if self:getCurrSpinMode() == RESPIN_MODE then
        if node.p_symbolType and node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            if self.m_isReconnection then
                --重连不显示收集的图标拖尾
                return
            end
            node:addTrailing(self.m_slotParents[node.p_cloumnIndex].slotParent,self.m_falseParticleTbl)
        end
        -- if node:isLastSymbol() then
        --     if self.m_isReconnection then
        --         --重连不显示收集的图标
        --         return
        --     end

        --     local symnolType = node.p_symbolType
        --     if symnolType == self.SYMBOL_FIX_SYMBOL then
        --         if not node.trailingNode then
        --             node.trailingNode = util_createAnimation("WarriorAlice_Bonus_tuowei.csb")
        --             node:addChild(node.trailingNode,-1)
        --         end
        --     end
        -- else
        --     if self.m_isReconnection then
        --         --重连不显示收集的图标
        --         return
        --     end
        --     local symnolType = node.p_symbolType
        --     if symnolType == self.SYMBOL_FIX_SYMBOL then
        --         node:addTrailing(self.m_slotParents[node.p_cloumnIndex].slotParent)
        --     end
        -- end
    else
        if node.p_symbolType and node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            node:removeBonusBg()
        end
    end
end

-- 显示paytableview 界面
function CodeGameScreenWarriorAliceMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    view:findChild("root"):setScale(self.m_machineRootScale)
    if view then
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

--[[
    显示大赢光效事件
]]
function CodeGameScreenWarriorAliceMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenWarriorAliceMachine:showBigWinLight(_func)
    self.m_bIsBigWin = false
    for k,v in pairs(self.bigWinList) do
        v:setVisible(true)
        util_spinePlay(v, "actionframe")
        util_spineEndCallFunc(v, "actionframe", function ()
            v:setVisible(false)
        end)
    end

    self:playBigWinNum(_func)
    self:shakeNode()
end

return CodeGameScreenWarriorAliceMachine