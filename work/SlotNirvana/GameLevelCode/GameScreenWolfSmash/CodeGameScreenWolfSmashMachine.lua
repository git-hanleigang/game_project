---
-- island li
-- 2019年1月26日
-- CodeGameScreenWolfSmashMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "WolfSmashPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenWolfSmashMachine = class("CodeGameScreenWolfSmashMachine", BaseSlotoManiaMachine)

CodeGameScreenWolfSmashMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWolfSmashMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  -- 自定义的小块类型
CodeGameScreenWolfSmashMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- 自定义的小块类型
CodeGameScreenWolfSmashMachine.SYMBOL_SCORE_BONUS1 = 95  -- 自定义的小块类型
CodeGameScreenWolfSmashMachine.SYMBOL_SCORE_WILD2 = 93  -- 自定义的小块类型

CodeGameScreenWolfSmashMachine.MAP_ADD_PIG = GameEffect.EFFECT_SELF_EFFECT + 1 -- 自定义动画的标识
CodeGameScreenWolfSmashMachine.WOLF_SMASH_PIG = GameEffect.EFFECT_LINE_FRAME + 1
CodeGameScreenWolfSmashMachine.CHOOSE_PIG_FREE = GameEffect.EFFECT_FREE_SPIN + 1

CodeGameScreenWolfSmashMachine.BONUS_RUN_NUM = 4
CodeGameScreenWolfSmashMachine.LONGRUN_COL_ADD_BONUS = 5

local POINT_POS = {
    UP = 1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4,
}

-- 构造函数
function CodeGameScreenWolfSmashMachine:ctor()
    CodeGameScreenWolfSmashMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    --记录当前狼头位置
    self.pointPosByFree = 1

    self.m_selectList = {}


    self.isOneFreeSpin = false

    self.m_isPlayYuGao = false
    self.isBonusLongRun = false
 
    self.totalPigNum = 0

    self.curAddIndex = 1

    self.mapMoveDelayTime = 2       --横向移动
    self.mapMoveDelayTimeForVertical = 2     --竖向移动

    self.isMoveMapForLr = false         --防止移动多次
    self.isMoveMapForUd = false

    self.spinPigNum = 0         --当前spin小猪的个数
    self.shakeOldPos = cc.p(0,0)

    self.isFirstInGame = false          --是否是第一次触发free（第一次玩此关卡并且第一次触发free,服务器传过来的）

    self.waitChooseForBTest = false

    self.chooseIndexForABTest = 1

    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    self.chooseIndexForFree = 1
    --init
    self:initGame()
end

function CodeGameScreenWolfSmashMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWolfSmashMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WolfSmash"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenWolfSmashMachine:getNetWorkModuleName()
    if self:checkWolfSmashABTest() then
        return "WolfSmash"  
    else
        return "WolfSmashV2"
    end
    
end


function CodeGameScreenWolfSmashMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_effectNode = self:findChild("Node_effect")

    --角色
    self.jvese = util_spineCreate("Socre_WolfSmash_juese",true,true)
    self:findChild("Node_jvese"):addChild(self.jvese)

    --桌子
    self.desk = util_createAnimation("WolfSmash_zhuozi.csb")
    self:findChild("Node_zhuozi"):addChild(self.desk)

    --logo
    local logo = util_createAnimation("WolfSmash_logo.csb")
    self:findChild("Node_logo"):addChild(logo)

    self.m_spineGuochang = util_spineCreate("Socre_WolfSmash_guochang", true, true)
    self.m_spineGuochang:setScale(self.m_machineRootScale)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang:setVisible(false)

    self.m_spineGuochang2 = util_spineCreate("Socre_WolfSmash_Bonus", true, true)
    self.m_spineGuochang2:setScale(self.m_machineRootScale)
    self:addChild(self.m_spineGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_spineGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang2:setVisible(false)


    self:createYuGaoAct()       --预告
 
    self:changeAllMapChildShow(false)       --地图相关ui

    self:runCsbAction("idle3",true)

    if self:checkWolfSmashABTest() then
        self:createMapEffect()          --地图
    else  
        self:createMapEffectForABTetst()
    end
    

    self:changeBgShow()             --背景

    self.wolfNode = cc.Node:create()
    self:addChild(self.wolfNode)
    self:showJveSeIdle()

    self:createBigWinEffect()          --大赢

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)
    --大赢飘数字
    self:changeBottomBigWinLabUi("WolfSmash_fg_font.csb")
    self.m_bottomUI.m_bigWinLabCsb:setScale(self.m_machineRootScale)

    --大赢特效
    self.jiaqian = util_spineCreate("WolfSmash_jiaqian", true, true)
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,self:findChild("Node_bigwin"))
    self:findChild("Node_bigwin"):addChild(self.jiaqian,1000)
    self.jiaqian:setPosition(cc.p(pos.x,pos.y - 100))

    self.jiaqian:setVisible(false)

    --free角色预告
    self.Freejvese = util_spineCreate("Socre_WolfSmash_juese",true,true)
    self:findChild("Node_yugao_juese"):addChild(self.Freejvese)
    self.Freejvese:setVisible(false)
    self.Freejvese:setPosition(cc.p(0,0))

    --当前spin小猪的个数
    self.spinPigUi = util_createView("CodeWolfSmashSrc.WolfSmashBonusBarView")
    self:findChild("Node_base_pigui"):addChild(self.spinPigUi)
    self.spinPigUi:chooseShow(1)

    if display.width/display.height >= 1812/2176 then
        util_csbScale(self.m_gameBg.m_csbNode, 1.15)
    end

end


function CodeGameScreenWolfSmashMachine:createBigWinEffect()
    self.bigWin = util_spineCreate("WolfSmash_binwin", true, true)
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,self:findChild("Node_bigwin"))
    self:findChild("Node_bigwin"):addChild(self.bigWin)
    self.bigWin:setPosition(cc.p(pos.x,pos.y - 100))
    self.bigWin:setVisible(false)
end

function CodeGameScreenWolfSmashMachine:createMapEffect()
    self.m_map = util_createView("CodeWolfSmashSrc.map.WolfSmashMapView",self)
    self:findChild("Node_ditu"):addChild(self.m_map)
    self.m_map:setVisible(false)
end

function CodeGameScreenWolfSmashMachine:changeBgShow(index)
    if index == 1 then
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(true)
    else
        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
    end
end

function CodeGameScreenWolfSmashMachine:createYuGaoAct()
    --预告
    self.yuGao = util_createAnimation("WolfSmash_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.yuGao)
    self.yuGao:setVisible(false)
    --预告金币
    self.yuGaoGold = util_spineCreate("WolfSmash_yugao",true,true)
    self.yuGao:findChild("Node_yugao_jinbi"):addChild(self.yuGaoGold)
    self.yuGaoGold:setVisible(false)
end

--先播放3遍idleframe，再播放1遍idleframe2，再放2遍idleframe，再播放1遍idleframe3
function CodeGameScreenWolfSmashMachine:showJveSeIdle()
    self.wolfNode:stopAllActions()
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, "idleframe",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(2)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, "idleframe",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(2)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, "idleframe",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(2)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, "idleframe2",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(4)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, "idleframe",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(2)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, "idleframe",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(2)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, "idleframe3",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(2)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:showJveSeIdle()
    end)
    self.wolfNode:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenWolfSmashMachine:changeAllMapChildShow(isShow)
    self:findChild("Node_ditukuang_1"):setVisible(isShow)
    self:findChild("Node_ditukuang_2"):setVisible(isShow)
    self:findChild("Node_base_reel"):setVisible(not isShow)
    self:findChild("Node_free_reel"):setVisible(isShow)
    self:findChild("WolfSmash_zhujiemian_guang_2_1"):setVisible(isShow)
end

function CodeGameScreenWolfSmashMachine:initFreeSpinBar()
    local parent = self:findChild("Node_freebar")
    self.m_freeSpinBar = util_createView("CodeWolfSmashSrc.WolfSmashFreespinBarView")
    parent:addChild(self.m_freeSpinBar)
    util_setCsbVisible(self.m_freeSpinBar, false)
    self.m_freeSpinBar:setPosition(0, 0)
end


function CodeGameScreenWolfSmashMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound(PublicConfig.SoundConfig.sound_WolfSmash_enterGame)

    end,0.4,self:getModuleName())
end

function CodeGameScreenWolfSmashMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWolfSmashMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenWolfSmashMachine:addObservers()
    CodeGameScreenWolfSmashMachine.super.addObservers(self)
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
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig.SoundConfig["sound_WolfSmash_win_line_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_WolfSmash_fs_win_line_"..soundIndex] 
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(
        self,
        function(self)
            if self:checkWolfSmashABTest() then
                self.m_map:resetWolfPosForPortrait(self.pointPosByFree)
            end
            
        end,
        ViewEventType.NOTIFY_RESET_SCREEN
    )
end

function CodeGameScreenWolfSmashMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWolfSmashMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWolfSmashMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_WolfSmash_10"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_WolfSmash_Bonus"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS1 then
        return "Socre_WolfSmash_Bonus"
    end
    if symbolType == self.SYMBOL_SCORE_WILD2 then
        return "Socre_WolfSmash_Wild3"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWolfSmashMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWolfSmashMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenWolfSmashMachine:MachineRule_initGame(  )
    
    --赋值self.isFirstInGame
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isFirst = selfData.isFirst or false
    self.isFirstInGame = isFirst
    self:chengeSpinMode()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self:checkWolfSmashABTest() then
            local mapBoatIndex = selfData.mapBoatIndex or self.pointPosByFree
            local mapMultiples = selfData.mapMultiples or {}
            --刷新free的spin次数显示
            local freeSpinNum = selfData.freeSpinNum or 0
            self.m_freeSpinBar:setVisible(true)
            self.m_freeSpinBar:updateFreespinCount(freeSpinNum)

            self.m_map:setVisible(true)
            --改变freeSpin次数
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount

            --榔头位置
            self.pointPosByFree = mapBoatIndex
            
            self:changeBgShow(1)
            self.spinPigUi:setVisible(false)
            self.jvese:setVisible(false)
            self.desk:setVisible(false)
            self:changeAllMapChildShow(true)
            self.m_map:setMachine(self)
            self.m_map.isMoveMapWithWolf = false
            self.m_map:initCreatePigForMap(mapMultiples)
            --创建已经砸过的小猪
            self.m_map:initSmashPig(mapBoatIndex)
            self.m_map:showPigIdeleFrame(mapBoatIndex)
            --地图位置
            self.m_map:initWolfPos(self.pointPosByFree)
            self:runCsbAction("idle",true)
            self.totalPigNum = #mapMultiples
            self.m_bottomUI.m_changeLabJumpTime = 0.3
        else
            --刷新free的spin次数显示
            local freeSpinNum = selfData.freeSpinNum or 0
            self.m_freeSpinBar:setVisible(true)
            self.m_freeSpinBar:updateFreespinCount(freeSpinNum)
            --改变freeSpin次数
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            self:changeBgShow(1)
            self.spinPigUi:setVisible(false)
            self.jvese:setVisible(false)
            self.desk:setVisible(false)
            self:changeAllMapChildShow(true)
            self:runCsbAction("idle",true)
            self.m_bottomUI.m_changeLabJumpTime = 0.3
            if self.m_newMap then
                local bonusMultipleNum = selfData.bonusMultipleNum or {}
                local multple = selfData.bonusSelect or 2
                local index = self:getIndexForMultple(multple)
                self.m_newMap:setVisible(true)
                self.m_newMap:resetViewShow(index)
                self.m_newMap:changePigNum(bonusMultipleNum)
                self:addChoosePigEffect() 
                self.waitChooseForBTest = true      
            end
        end
        
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if featureDatas and featureDatas[2] == 1 then
        self:MachineRule_initGameForBonusBar()
    end
end

function CodeGameScreenWolfSmashMachine:checkInitSpinWithEnterLevel()
    local isTriggerEffect,isPlayGameEffect = CodeGameScreenWolfSmashMachine.super.checkInitSpinWithEnterLevel(self)

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and not self:checkWolfSmashABTest() then
        if not isPlayGameEffect then
            isPlayGameEffect = true
        end
    end

    return isTriggerEffect, isPlayGameEffect
end

function CodeGameScreenWolfSmashMachine:MachineRule_initGameForBonusBar()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local num = 2
    if selfData and selfData.bonusIndexAndMultiple then
        local bonusIndexAndMultiple = selfData.bonusIndexAndMultiple or {}
        for k,v in pairs(bonusIndexAndMultiple) do
            self.spinPigNum = self.spinPigNum + 1
            if self.spinPigNum == 6 then
                self.spinPigUi:chooseShow(2)
            end
            self.spinPigUi:changeBonusByCount(self.spinPigNum,tonumber(v))
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenWolfSmashMachine:slotOneReelDown(reelCol)    
    local isLongRun = CodeGameScreenWolfSmashMachine.super.slotOneReelDown(self,reelCol) 

    
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        if reelCol == self.m_iReelColumnNum then
            if isLongRun then
                local features = self.m_runSpinResultData.p_features
                if not features or #features <= 1 then
                    local randomNum = math.random(1, 2)
                    if randomNum == 1 then
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_longRun_Before)
                    end
                end
            end
            
        end
    end
    
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWolfSmashMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWolfSmashMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

----------- FreeSpin相关

function CodeGameScreenWolfSmashMachine:getTempBonusForTrigger(node)
    local iCol = node.p_cloumnIndex
    local iRow = node.p_rowIndex
    local nodeIndex = self:getPosReelIdx(iRow, iCol)
    local multiple = self:getBonusMultipleForSelfData(nodeIndex)
    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newStartPos = self:findChild("Node_effect"):convertToNodeSpace(startPos)
    local newBonusSpine = util_spineCreate("Socre_WolfSmash_Bonus",true,true)
    if multiple == 10 then
        newBonusSpine:setSkin("gold")
    else
        newBonusSpine:setSkin("red")
    end
    local cocosName = "WolfSmash_chengbei.csb"
    local coinsView = util_createAnimation(cocosName)
    self:changeChengBeiShow(coinsView,multiple)
    util_spinePushBindNode(newBonusSpine,"cb",coinsView)
    coinsView:runCsbAction("idle")
    self:findChild("Node_effect"):addChild(newBonusSpine)
    newBonusSpine:setPosition(newStartPos)
    local zOder = self:getBounsScatterDataZorder(self.SYMBOL_FIX_SYMBOL)
    newBonusSpine:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - node.p_rowIndex)
    return newBonusSpine
end

function CodeGameScreenWolfSmashMachine:chengeSpinMode()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --增加次数
    local p_freeSpinNewCount = self.m_runSpinResultData.p_freeSpinNewCount or 0
    local featureDatas = self.m_runSpinResultData.p_features or {}
    
    if featureDatas and featureDatas[2] == 1 and p_freeSpinNewCount > 0 then
        self:setCurrSpinMode(FREE_SPIN_MODE)
    end
end

-- 显示free spin
function CodeGameScreenWolfSmashMachine:showEffect_FreeSpin(effectData)
    
    local tempBonus = {}
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
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
        self:clearCurMusicBg()
        -- 播放震动
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            -- freeMore时不播放
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
        end
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_trigger_forBonus)
        self.spinPigUi:triggerFreeGameByBonus()
        --触发动画
        
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and node.p_symbolType then
                    if node.p_symbolType == self.SYMBOL_SCORE_BONUS then
                        node:setVisible(false)
                        node:changeParentToOtherNode(self.m_clipParent)
                        local newBonusSpine = self:getTempBonusForTrigger(node)
                        tempBonus[#tempBonus + 1] = newBonusSpine
                        util_spinePlay(newBonusSpine, "actionframe2", false)
                        util_spineEndCallFunc(newBonusSpine, "actionframe2",function()
                            util_spinePlay(newBonusSpine, "idleframe", true)
                        end)
                    end
                end
            end
        end
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
                        if node.p_symbolType == self.SYMBOL_SCORE_BONUS then
                            node:setVisible(true)
                            node:runAnim("idleframe", true)
                        end
                    end
                end
            end
            self:showFreeSpinView(effectData)
        end)
    else
        self:showFreeSpinView(effectData)
    end
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenWolfSmashMachine:triggerFreeSpinCallFun()
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

-- FreeSpinstart
function CodeGameScreenWolfSmashMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                effectData.p_isPlay = true
                self:playGameEffect()
        else
            self.isOneFreeSpin = true
            self:delayCallBack(2,function ()
                --播放背景音乐
                self:resetMusicBg(nil,"WolfSmashSounds/music_WolfSmash_freeGame.mp3")
            end)
            self:showGuochang(function ()
                if self:checkWolfSmashABTest() then
                    self:show_Choose_GameView(function ()
                    
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end,function ()
                        self.totalPigNum = #self.m_selectList
                        self.pointPosByFree = 1
                        self.m_map:setVisible(true)
                        self.spinPigUi:setVisible(false)
                        self.jvese:setVisible(false)
                        self.desk:setVisible(false)
                        self:changeAllMapChildShow(true)
                        self.m_map:setMachine(self)
                        self.m_map.isMoveMapWithWolf = false
                        self.m_map.isMoveForVertical = false
                        self.m_map:initCreatePigForMap(self.m_selectList)
                        self.m_map:initWolfPos(self.pointPosByFree)
                        self:runCsbAction("idle",true)
                        --刷新free的spin次数显示
                        local selfData = self.m_runSpinResultData.p_selfMakeData
                        local freeSpinNum = selfData.freeSpinNum or 0
                        self.m_freeSpinBar:updateFreespinCount(freeSpinNum)
                        self.m_freeSpinBar:setVisible(true)
                        self.m_bottomUI.m_changeLabJumpTime = 0.3
                    end)
                else
                    self:showFreeSpinStart(nil,function ()
                        self.spinPigUi:setVisible(false)
                        self.jvese:setVisible(false)
                        self.desk:setVisible(false)
                        self:changeAllMapChildShow(true)
                        self:runCsbAction("idle",true)
                        --刷新free的spin次数显示
                        local selfData = self.m_runSpinResultData.p_selfMakeData
                        local freeSpinNum = selfData.freeSpinNum or 0
                        self.m_freeSpinBar:updateFreespinCount(freeSpinNum)
                        self.m_freeSpinBar:setVisible(true)
                        self.m_bottomUI.m_changeLabJumpTime = 0.3
                        if self.m_newMap then
                            local bonusMultipleNum = selfData.bonusMultipleNum or {}
                            local multple = selfData.bonusSelect or 2
                            local index = self:getIndexForMultple(multple)
                            self.m_newMap:setVisible(true)
                            self.m_newMap:resetViewShow(index)
                            self.m_newMap:changePigNum(bonusMultipleNum)
                            self:addChoosePigEffect()
                            self.waitChooseForBTest = true
                        end
                    end,function ()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end)
                end
                
                
            end)
            
                
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenWolfSmashMachine:addChoosePigEffect()
    if not self:checkHasEffectType(self.CHOOSE_PIG_FREE) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.CHOOSE_PIG_FREE
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHOOSE_PIG_FREE -- 动画类型
    end
    
end


function CodeGameScreenWolfSmashMachine:show_Choose_GameView(func1,func2)
    
    local chooseView = util_createView("CodeWolfSmashSrc.map.WolfSmashSelectView",self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        chooseView.getRotateBackScaleFlag = function(  ) return false end
    end
    
    -- gLobalViewManager:showUI(chooseView)
    self:addChild(chooseView,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
    
    chooseView:findChild("root"):setScale(self.m_machineRootScale)
    chooseView:setEndCall(func1,func2)
end

function CodeGameScreenWolfSmashMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    
    self:showFreeSpinOverView()
end

function CodeGameScreenWolfSmashMachine:showFreeSpinOver(coins, num, func)

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_over_show)
    self:clearCurMusicBg()
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_over_hide)
    end)
    return view
end

function CodeGameScreenWolfSmashMachine:showFreeSpinOverView()
    self:delayCallBack(0.5,function ()
        --改变freeSpin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local freeSpinNum = selfData.freeSpinNum or 0
        if self:checkWolfSmashABTest() then
            self.m_map:resetWolfTipsParent()
        end
        
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_over_complete)
        self:runCsbAction("start",false,function ()
                
                self:runCsbAction("idle2")
        end)
        self:delayCallBack(32/60 + 0.8,function ()
            local view = self:showFreeSpinOver( strCoins, 
            freeSpinNum,function()
                self:showGuochang2(function ()
                    if self:checkWolfSmashABTest() then
                        self.pointPosByFree = 1
                        self.m_map:setVisible(false)
                        self.m_map.isMoveMapWithWolf = false
                        self.m_map.pigNumForMap = 0
                        self.m_map:initWolfPos(self.pointPosByFree)
                        self.m_map:clearAllPig()
                        self.m_map:clearAllSmashPig()
                        self.m_map:resetSelfPos()
                    else
                        self.m_newMap:setVisible(false)
                        self.m_newMap:stopUpdate()
                    end
                    
                    
                    self:changeBgShow()
                    self.spinPigUi:setVisible(true)
                    self.spinPigUi:chooseShow(1)
                    self.spinPigNum = 0
                    self.spinPigUi:resetPigShow()
                    
                    self.jvese:setVisible(true)
                    self.desk:setVisible(true)
                    self:showJveSeIdle()
                    self:runCsbAction("idle3",true)
                    self:changeAllMapChildShow(false)
                    self.m_freeSpinBar:setVisible(false)
                    self:triggerFreeSpinOverCallFun()
                    self.b_gameTipFlag = false
                    self.m_bottomUI.m_changeLabJumpTime = nil
                end)
            end)
            local lighting = util_createAnimation("WolfSmash_tanban_guang.csb")
            view:findChild("Node_tanban_g"):addChild(lighting)
            local jvse = util_spineCreate("Socre_WolfSmash_juese",true,true)
            view:findChild("Node_juese"):addChild(jvse)
            util_spinePlay(jvse, "idleframe",true)
            lighting:runCsbAction("idle",true)
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=1,sy=1},621)
            view:findChild("root"):setScale(self.m_machineRootScale)
        end)
    end)
   
    

end

--spin时更改free次数
function CodeGameScreenWolfSmashMachine:checkChangeFsCount()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount ~= nil and globalData.slotRunData.freeSpinCount > 0 then
        --减少free spin 次数
        -- globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1
        -- print(" globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1")
        -- globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount - 1
        -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        globalData.userRate:pushFreeSpinCount(1)
    end
end

function CodeGameScreenWolfSmashMachine:updateNetWorkData()
    CodeGameScreenWolfSmashMachine.super.updateNetWorkData(self)
    --赋值self.isFirstInGame
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isFirst = selfData.isFirst or false
    self.isFirstInGame = isFirst
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        --刷新free的spin次数显示
        local freeSpinNum = selfData.freeSpinNum or 0
        self.m_freeSpinBar:updateFreespinCount(freeSpinNum)
    end
    
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWolfSmashMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.spinPigNum = 0
        self.spinPigUi:resetPigShow()
    end
    self.waitChooseForBTest = false

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWolfSmashMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:checkWolfSmashABTest() then
            if selfData and selfData.bonusIndexAndMultiple then
                if table_length(selfData.bonusIndexAndMultiple) > 0 then
                    -- 自定义动画创建方式
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = self.MAP_ADD_PIG
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.MAP_ADD_PIG -- 动画类型
                end
            end
        else
            local storedIcons = self.m_runSpinResultData.p_storedIcons
            if table_length(storedIcons) > 0 then
                -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.MAP_ADD_PIG
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.MAP_ADD_PIG -- 动画类型
            end
        end
        
        if selfData and selfData.multipleBeforeWinCount then
            if selfData.multipleBeforeWinCount > 0 then
                -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.WOLF_SMASH_PIG
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.WOLF_SMASH_PIG -- 动画类型
            end
        end
        if selfData and selfData.isSelect then   --B组Free选择
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.CHOOSE_PIG_FREE
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.CHOOSE_PIG_FREE -- 动画类型
        end
        
        
    end
        

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWolfSmashMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.MAP_ADD_PIG then
        if self:checkWolfSmashABTest() then
            local addList = self:getNewPigList()
            -- 记得完成所有动画后调用这两行
            -- 作用：标识这个动画播放完结，继续播放下一个动画
            if #addList > 0 then
                self.isMoveMapForLr = true
                self.isMoveMapForUd = true

                self:addPigForMapEffect(addList,function ()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            else
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        else
            self:addPigForMapEffectForABTest(function ()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end
        
        
        

    end
    if effectData.p_selfEffectType == self.WOLF_SMASH_PIG then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        if self:checkWolfSmashABTest() then
            self:wolfSmashPigEffect(function ()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        else
            self:wolfSmashPigEffectForABTest(function ()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end
        
    end

    if effectData.p_selfEffectType == self.CHOOSE_PIG_FREE then
        self:showMapEffectForBeforeBeginReel(function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

--放大测试
function CodeGameScreenWolfSmashMachine:scaleWolfAndPig(curPigIndex,posX,posY)
    local pig = self.m_map:getSelectPig(curPigIndex)
    local wolf = self.m_map:getWolfTips()
    if pig and wolf then
        local pigPos = util_convertToNodeSpace(pig,self)
        local wolfPos = util_convertToNodeSpace(wolf,self)
        local endPigPos = cc.p(pigPos.x + self.m_map.scalePosX ,pigPos.y + self.m_map.scalePosY)
        local wolfPigPos = cc.p(wolfPos.x + self.m_map.scalePosX ,wolfPos.y + self.m_map.scalePosY)
        local scaleAct = cc.ScaleTo:create(1, 1.5)
        local pigMoveAct = cc.MoveTo:create(1,endPigPos)
        local wolfMoveAct = cc.MoveTo:create(1,wolfPigPos)
        pig:runAction(cc.Sequence:create(scaleAct,pigMoveAct))
        wolf:runAction(cc.Sequence:create(scaleAct,wolfMoveAct))
    end
    
end
------------------free狼砸猪相关部分

function CodeGameScreenWolfSmashMachine:wolfSmashPigEffect(func)
    local node = cc.Node:create()
    self:addChild(node)
    local curPigIndex = self.pointPosByFree
    local pigParent = nil
    local wolfParent = nil
    local pig = self.m_map:getSelectPig(curPigIndex)
    local wolf = self.m_map:getWolfTips()
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if pig and wolf then
            pigParent = pig:getParent()
            wolfParent = wolf:getParent()
            --切换层级
            if not wolf.isChangeParent then
                local wolfPos = util_convertToNodeSpace(wolf, self.m_effectNode)
                util_changeNodeParent(self.m_effectNode, wolf, 12)
                wolf:setPosition(wolfPos)
            end
            
            --切换层级
            local pigPos = util_convertToNodeSpace(pig, self.m_effectNode)
            util_changeNodeParent(self.m_effectNode, pig, 10)
            pig:setPosition(pigPos)
        end
        
        self:runCsbAction("start_zj",false,function ()
            self:runCsbAction("idle_zj")
        end)
    end)
    actList[#actList + 1] = cc.DelayTime:create(15/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self.m_map:showWolfSmashPig(curPigIndex)
    end)
    actList[#actList + 1] = cc.DelayTime:create(35/30)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        local startPosNode = self.m_map:getEndNode(curPigIndex)
        local startPos = util_convertToNodeSpace(startPosNode,self.m_effectNode)
        local curMultiple = self.m_map:getCurPigMultiple(curPigIndex)
        self:runCsbAction("over_zj")
        if curMultiple >= 5 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_chengbei_down)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_chengbei_down2)
        end
        
        self:flyChengBeiStr(startPos,curMultiple,curPigIndex)
    end)
    actList[#actList + 1] = cc.DelayTime:create(1)
    actList[#actList + 1] = cc.CallFunc:create(function (  )

        if pig and wolf then
            if not wolf.isChangeParent then
                local wolfPos = util_convertToNodeSpace(wolf, wolfParent)
                util_changeNodeParent(wolfParent, wolf)
                wolf:setPosition(wolfPos)
            end
            
            --切换层级
            local pigPos = util_convertToNodeSpace(pig, pigParent)
            util_changeNodeParent(pigParent, pig)
            pig:setPosition(pigPos)
            self.m_map:changeSmashPigParent(curPigIndex)
        end

        self:showSelfActionFrame(curPigIndex)
    end)
    actList[#actList + 1] = cc.DelayTime:create(90/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        node:removeFromParent()
        if self:checkHasBigWin() then
            --大赢弹板时间延后
            self:delayCallBack(3,function ()
                if type(func) == "function" then
                    func()
                end
            end)
        else
            if type(func) == "function" then
                func()
            end
        end
        
    end)
    node:runAction(cc.Sequence:create( actList))
end

--根据倍数播放棋盘震动动画
function CodeGameScreenWolfSmashMachine:showSelfActionFrame(curPigIndex)
    local curMultiple = self.m_map:getCurPigMultiple(curPigIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local multipleBeforeWinCount = selfData.multipleBeforeWinCount or 0
    if curMultiple < 5 then
        self:runCsbAction("actionframe",false,function ()
            self:runCsbAction("idle",true)
        end)
        local coins = multipleBeforeWinCount
        self:playBigWinNum(coins)
        self.jiaqian:setVisible(true)
        util_spinePlay(self.jiaqian, "actionframe", false)
        util_spineEndCallFunc(self.jiaqian, "actionframe", function()
            self.jiaqian:setVisible(false)
        end)
        self:delayCallBack(82/60,function ()
            self:showNewLineFrame()         --砸完猪后显示每一条线
        end)
    else
        self:runCsbAction("actionframe2",false,function ()
            self:runCsbAction("idle",true)
        end)
        local coins = multipleBeforeWinCount
        self:playBigWinNum(coins)
        self.jiaqian:setVisible(true)
        util_spinePlay(self.jiaqian, "actionframe", false)
        util_spineEndCallFunc(self.jiaqian, "actionframe", function()
            self.jiaqian:setVisible(false)
    end)
        self:delayCallBack(82/60,function ()
            self:showNewLineFrame()
        end)
    end
end

function CodeGameScreenWolfSmashMachine:changeSmashForSelf(node,nodeParent)
    
    local samashPos = util_convertToNodeSpace(node, self.m_effectNode)
    util_changeNodeParent(self.m_effectNode, node,11)
    node:setPosition(samashPos)
end

function CodeGameScreenWolfSmashMachine:showChengBeiStr(node,multiple)
    local chengbeiList = {
        "Node_X2",
        "Node_X3",
        "Node_X5",
        "Node_X10",
    }
    for i,v in ipairs(chengbeiList) do
        node:findChild(v):setVisible(false)
    end
    if multiple == 2 then
        node:findChild(chengbeiList[1]):setVisible(true)
    elseif multiple == 3 then
        node:findChild(chengbeiList[2]):setVisible(true)
    elseif multiple == 5 then
        node:findChild(chengbeiList[3]):setVisible(true)
    elseif multiple == 10 then
        node:findChild(chengbeiList[4]):setVisible(true)
    end
end

function CodeGameScreenWolfSmashMachine:flyChengBeiStr(startPos,multiple,curPigIndex)
    local chengbeiNode =  util_createAnimation("WolfSmash_chengbei.csb")
    self.m_effectNode:addChild(chengbeiNode,GAME_LAYER_ORDER.LAYER_ORDER_EFFECT + 20)
    chengbeiNode:runCsbAction("idle")
    chengbeiNode:setPosition(startPos)
    local endPos = util_convertToNodeSpace(self:findChild("Node_chengbei"),self.m_effectNode)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self:showChengBeiStr(chengbeiNode,multiple)
        chengbeiNode:runCsbAction("actionframe2")
    end)
    actList[#actList + 1] = cc.DelayTime:create(20/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        
        local smashPig = self.m_map:getSmashPig(curPigIndex)
        if smashPig then
            self:delayCallBack(5/60,function ()
                local curPigForView = smashPig.coinsView
                curPigForView:runCsbAction("start")
            end)
        end
        
        chengbeiNode:runCsbAction("actionframe")
        if multiple >= 5 then
            -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_show_fiveOrTen)
        end
    end)
    actList[#actList + 1] = cc.MoveTo:create(24/60, endPos)
    actList[#actList + 1] = cc.DelayTime:create(24/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        chengbeiNode:removeFromParent()
    end)
    chengbeiNode:runAction(cc.Sequence:create( actList))
end

function CodeGameScreenWolfSmashMachine:resetMapMove(func)
    local delayTime = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local multipleBeforeWinCount = selfData.multipleBeforeWinCount or 0
    if multipleBeforeWinCount > 0 then
        delayTime = 1
    end
    
    self.mapMoveDelayTime = 2
    self.curAddIndex = 1
    if self.m_map:isResetMapPos() then      --是否横向移动了
        delayTime = delayTime + 2
        self:delayCallBack(1,function ()
            self.m_map:resetMapPos()        --reset横向
        end)
    else
        if self.m_map:isResetMapPosForUd() then         --是否纵向移动了
            delayTime = delayTime + 2
            self:delayCallBack(1,function ()
                self.m_map:updateVerticalMove(true)     --reset纵向
            end)
        end
    end
    
    self:delayCallBack(delayTime,function ()
        self.isMoveMapForUd = false
        self.isMoveMapForLr = false
        if type(func) == "function" then
            func()
        end
    end)
end

--free增加小猪相关
function CodeGameScreenWolfSmashMachine:addPigForMapEffect(list,func)
    if self.curAddIndex > #list then
        self:resetMapMove(func)
        return
    end
    local startPos = nil
    --不同情况下，延迟时间不同，故用延迟做
    --地图移动
    local isMoveNow = self.m_map:isMoveMap(self.totalPigNum + 1)
    if isMoveNow then
        -- if self.isMoveMapForLr then
            self.isMoveMapForUd = false     --如果需要左右移动  那么就不考虑上下移动了
            self.isMoveMapForLr = false
            self.mapMoveDelayTime = 2
            self.m_map:updateMapPos(self.totalPigNum + 1)       --改变地图位置（以左右移动为主）
        -- else
        --     self.mapMoveDelayTime = 0
        -- end
    else
        --当前是否上移
        if self.m_map.isMoveForVertical then
            if self.isMoveMapForUd and self.m_map:isDownList(self.totalPigNum + 1) then
                self.isMoveMapForUd = false
                self.mapMoveDelayTime = 2
                self.m_map:updateVerticalMove(false)            --改变地图位置（以上下移动为主）
            else
                self.mapMoveDelayTime = 0
            end
            
        else
            self.mapMoveDelayTime = 0
        end
        
    end

    self:delayCallBack(self.mapMoveDelayTime,function ()
        local num = list[self.curAddIndex][1]
        local fixPos = self:getRowAndColByPos(tonumber(num))
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_bonus_add_pig)
        symbolNode:runAnim("shouji")
        startPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
        self.totalPigNum = self.totalPigNum + 1
        local endPosNode = self.m_map:getEndNode(self.totalPigNum)
        local endPos = util_convertToNodeSpace(endPosNode,self.m_effectNode)
        self:FlyParticle(startPos,endPos,function ()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_bonus_add_pig_fankui)
        end)
    end)

    self:delayCallBack(self.mapMoveDelayTime + 0.5,function ()
        --地图增加猪
        local multiple = list[self.curAddIndex][2]
        self.m_map:createNewPigForMap(self.totalPigNum,tonumber(multiple))
    end)

    self:delayCallBack(self.mapMoveDelayTime + 0.5,function ()
        if self.m_map:isMoveMap(self.totalPigNum + 1) then
            self.mapMoveDelayTime = 0.5
        else
            self.mapMoveDelayTime = 0
        end
        self:delayCallBack(self.mapMoveDelayTime,function ()
            self.curAddIndex = self.curAddIndex + 1
            self:addPigForMapEffect(list,func)
        end)
    end)
end


function CodeGameScreenWolfSmashMachine:getNewPigList()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local indexAndMultiples = clone(selfData.indexAndMultiples)
    if indexAndMultiples and #indexAndMultiples > 0 then
        return indexAndMultiples
    end
    return {}
end


---飞行粒子相关
function CodeGameScreenWolfSmashMachine:FlyParticle(startPos,endPos,func)
    -- -- 创建粒子
    local flyNode =  util_createAnimation("Socre_WolfSmash_tv.csb")
    self.m_effectNode:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_EFFECT + 11)
    flyNode:setPosition(startPos)
    
    local particle1 = flyNode:findChild("Particle_3")
    local particle2 = flyNode:findChild("Particle_1")
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        particle1:setDuration(-1)     --设置拖尾时间(生命周期)
        particle1:setPositionType(0)   --设置可以拖尾
        particle1:resetSystem()

        particle2:setDuration(-1)
        particle2:setPositionType(0)
        particle2:resetSystem()
    end)
    actList[#actList + 1] = cc.MoveTo:create(0.5, endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        particle1:stopSystem()--移动结束后将拖尾停掉
        particle2:stopSystem()
    end) 
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if type(func) == "function" then
            func()
        end
    end) 
    actList[#actList + 1] = cc.DelayTime:create(1)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        flyNode:removeFromParent()
    end) 
    flyNode:runAction(cc.Sequence:create( actList))
end

--设置bonus显示相关
--新滚动使用
function CodeGameScreenWolfSmashMachine:updateReelGridNode(symblNode)
    CodeGameScreenWolfSmashMachine.super.updateReelGridNode(self, symblNode)
    
    if not tolua.isnull(symblNode.m_csbNode) then
        symblNode.m_csbNode:removeFromParent()
        symblNode.m_csbNode = nil
    end
    if symblNode.p_symbolType == self.SYMBOL_SCORE_BONUS or symblNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 then
        self:setBonusNodeScore({symblNode})
    end
end

-- 给bonus小块进行赋值
function CodeGameScreenWolfSmashMachine:setBonusNodeScore(param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local multiple = 2


    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        local nodeIndex = self:getPosReelIdx(iRow, iCol)
        multiple = self:getBonusMultipleForSelfData(nodeIndex)
    else
        multiple = self:randomBonusMultiple(symbolNode)
    end
    --更换皮肤
    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        local ccbNode = symbolNode:getCCBNode()
        if not ccbNode then
            symbolNode:checkLoadCCbNode()
        end
        ccbNode = symbolNode:getCCBNode()
        if ccbNode then
            if multiple == 10 then
                ccbNode.m_spineNode:setSkin("gold")
            else
                ccbNode.m_spineNode:setSkin("red")
            end
            
        end
    elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 then
        local ccbNode = symbolNode:getCCBNode()
        if not ccbNode then
            symbolNode:checkLoadCCbNode()
        end
        ccbNode = symbolNode:getCCBNode()
        if ccbNode then
            ccbNode.m_spineNode:setSkin("gold")
        end
    end
    self:addLevelBonusSpine(symbolNode,multiple)
end

function CodeGameScreenWolfSmashMachine:randomBonusMultiple(symbolNode)
    local multipleList = {
        2,
        3,
        5
    }
    local randomIndex = math.random(1,3)
    local multipleIndex = multipleList[randomIndex]
    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 then
        multipleIndex = 10
    end
    return multipleIndex
end

function CodeGameScreenWolfSmashMachine:getBonusMultipleForSelfData(nodeIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local num = 2
    if selfData and selfData.bonusIndexAndMultiple then
        local bonusIndexAndMultiple = selfData.bonusIndexAndMultiple or {}
        for k,v in pairs(bonusIndexAndMultiple) do
            local reelIndex = tonumber(k)
            if reelIndex == nodeIndex then
                return tonumber(v)
            end
        end
    end
    return num
end

function CodeGameScreenWolfSmashMachine:changeChengBeiShow(coinsView,multiple)
    local curChild = {
        "Node_X2",
        "Node_X3",
        "Node_X5",
        "Node_X10",
    }
    for i,v in ipairs(curChild) do
        coinsView:findChild(v):setVisible(false)
    end
    if multiple == 2 then
        coinsView:findChild(curChild[1]):setVisible(true)
    elseif multiple == 3 then
        coinsView:findChild(curChild[2]):setVisible(true)
    elseif multiple == 5 then
        coinsView:findChild(curChild[3]):setVisible(true)
    elseif multiple == 10 then
        coinsView:findChild(curChild[4]):setVisible(true)
    end
end

function CodeGameScreenWolfSmashMachine:addLevelBonusSpine(_symbol,multiple)
    local cocosName = "WolfSmash_chengbei.csb"
    
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    util_spineRemoveSlotBindNode(spineNode,"cb")
    local coinsView = util_createAnimation(cocosName)
    self:changeChengBeiShow(coinsView,multiple)
    self:util_spinePushBindNode(spineNode,"cb",coinsView)
    coinsView:runCsbAction("idle")
    _symbol.m_csbNode = coinsView
end

function CodeGameScreenWolfSmashMachine:util_spinePushBindNode(spNode, slotName, bindNode)
    -- 与底层区分开
    spNode:pushBindNode(slotName, bindNode)
end


-- ---------------------- 特殊快滚相关
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWolfSmashMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
    if self.m_isPlayYuGao == false then
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            if self:checkTriggerAddBonusLongRun() then
                self.isBonusLongRun = true
                for iCol = self.LONGRUN_COL_ADD_BONUS, self.m_iReelColumnNum do
                    local reelRunInfo = self.m_reelRunInfo
                    local reelRunData = self.m_reelRunInfo[iCol]
                    local columnData = self.m_reelColDatas[iCol]
        
                    reelRunData:setReelLongRun(true)
                    reelRunData:setNextReelLongRun(true)
        
                    local reelLongRunTime = 2.5
                    if iCol > self.m_iReelColumnNum then
                        reelLongRunTime = 2.5
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
        
    
                    local columnSlotsList = self.m_reelSlotsList[iCol]  -- 提取某一列所有内容
                    local runLen = self:getLongRunLen(iCol)
                    local preRunLen = reelRunData:getReelRunLen()
                    local addRun = runLen - preRunLen
    
                    reelRunData:setReelRunLen(runLen)
    
                    for checkRunIndex = preRunLen + iRow,1,-1 do
                        local checkData = columnSlotsList[checkRunIndex]
                        if checkData == nil then
                            break
                        end
                        columnSlotsList[checkRunIndex] = nil
                        columnSlotsList[checkRunIndex + addRun] = checkData
                    end
                end
            end
        end
        
    end
end

function CodeGameScreenWolfSmashMachine:checkTriggerAddBonusLongRun( )
    local bonusNum = 0
    for iCol = 1 ,(self.m_iReelColumnNum - 1) do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
            if symbolType then
                if symbolType == self.SYMBOL_SCORE_BONUS or symbolType == self.SYMBOL_SCORE_BONUS1 then
                    bonusNum = bonusNum + 1  
                end
            end
            
        end
        
    end

    if bonusNum >= self.BONUS_RUN_NUM and not self.m_isPlayYuGao then
        self:setLongRunCol()
        return true
    end

    return false
end

function CodeGameScreenWolfSmashMachine:setLongRunCol( )
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

function CodeGameScreenWolfSmashMachine:getColBonusNum(colNum)
    local bonusNum = 0
    for iCol = 1 , colNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
            if symbolType then
                if symbolType == self.SYMBOL_SCORE_BONUS or symbolType == self.SYMBOL_SCORE_BONUS1 then
                    bonusNum = bonusNum + 1  
                end
            end
        end 
    end
    return bonusNum
end

function CodeGameScreenWolfSmashMachine:getReelDownBonusNum()
    local bonusNum = 0
    local reels = self.m_runSpinResultData.p_reels or {}
    
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1 , self.m_iReelColumnNum do
            local symbolType = reels[iRow][iCol]
        
            if symbolType then
                if symbolType == self.SYMBOL_SCORE_BONUS or symbolType == self.SYMBOL_SCORE_BONUS1 then
                    bonusNum = bonusNum + 1  
                end
            end
        end 
    end
    return bonusNum
end



function CodeGameScreenWolfSmashMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == self.SYMBOL_SCORE_BONUS or node.p_symbolType == self.SYMBOL_SCORE_BONUS1 then
                    if node.m_currAnimName == "idleframe3" then
                        node:runAnim("idleframe2", true)
                    end
                end
            end
        end
    end

    self.isBonusLongRun = false
    self.m_isPlayYuGao = false

    CodeGameScreenWolfSmashMachine.super.slotReelDown(self)
    if self.spinPigNum >= 6 then
        self.spinPigUi:chooseShow(2)
        self.spinPigUi:changeBonusByCount(self.spinPigNum,0)
    end
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenWolfSmashMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 then
                    --播buling的时候刷新收集
                    self.spinPigNum = self.spinPigNum + 1
                    if self.spinPigNum < 6 then
                        local multiple = self:getMultipForBonusBar(_slotNode)
                        self.spinPigUi:changeBonusByCount(self.spinPigNum,multiple)
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

function CodeGameScreenWolfSmashMachine:getMultipForBonusBar(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local nodeIndex = self:getPosReelIdx(iRow, iCol)
    local multiple = self:getBonusMultipleForSelfData(nodeIndex)
    return multiple
end

function CodeGameScreenWolfSmashMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenWolfSmashMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode then
        if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 then
            if self.isBonusLongRun then
                _slotNode:runAnim("idleframe3",true)
            else
                _slotNode:runAnim("idleframe2",true)
            end
            
        end
    end
    
end

function CodeGameScreenWolfSmashMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenWolfSmashMachine:requestSpinResult()
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

    
    

    local bonusSelect = 2
    if not self:checkWolfSmashABTest() then
        bonusSelect = self:getChooseMul()
    end
    
    self:setSpecialSpinStates(false )
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --free第一次时将选择列表传给服务器
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount

        if self:checkWolfSmashABTest() then
            if self.isOneFreeSpin and freeSpinsTotalCount > 0 and freeSpinsLeftCount == freeSpinsTotalCount then
                self.isOneFreeSpin = false
                -- 拼接 collect 数据， jackpot 数据
                messageData = {
                    msg = MessageDataType.MSG_BONUS_SELECT,
                    data = self.m_selectList,
                    jackpot = self.m_jackpotList,
                    betLevel = self.m_iBetLevel,
                }
            else
                messageData = {
                    msg = MessageDataType.MSG_SPIN_PROGRESS,
                    data = self.m_collectDataList,
                    jackpot = self.m_jackpotList,
                    betLevel = self.m_iBetLevel
                }
            end
        else
            messageData = {
                msg = MessageDataType.MSG_SPIN_PROGRESS,
                data = self.m_collectDataList,
                jackpot = self.m_jackpotList,
                betLevel = self.m_iBetLevel,
                bonusSelect = {bonusSelect,self.chooseIndexForFree}
            }
        end
    end
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenWolfSmashMachine:getChooseMul()
    local index = self.m_newMap.curChoose or 1
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local multple = selfData.bonusSelect or 2       --服务器发的选择

    if index == 1 then
        return 2
    elseif index == 2 then
        return 3
    elseif index == 3 then
        return 5
    elseif index == 4 then
        return 10
    else
        return multple
    end
end

--[[
    过场动画
]]
function CodeGameScreenWolfSmashMachine:showGuochang(func)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.wolfNode:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_free_select_show)
    util_spinePlay(self.jvese, "actionframe_guochang", false)
    self:delayCallBack(5/30,function ()
        self.m_spineGuochang:setVisible(true)
        util_spinePlay(self.m_spineGuochang, "actionframe_guochang")
        util_spineEndCallFunc(self.m_spineGuochang, "actionframe_guochang", function ()
            self.m_spineGuochang:setVisible(false)
        end)
        if func ~= nil then
            self:delayCallBack(40 / 30, function ()
                if type(func) == "function" then
                    func()
                end
            end)
        end
    end)
    
end

function CodeGameScreenWolfSmashMachine:showGuochang2(func)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_spineGuochang2:setVisible(true)
    self.m_spineGuochang2:setSkin("gold")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fgTobase_guochang)
    util_spinePlay(self.m_spineGuochang2, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang2, "actionframe_guochang", function ()
        self.m_spineGuochang2:setVisible(false)
    end)
    if func ~= nil then
        self:delayCallBack(76 / 30, function ()
            if type(func) == "function" then
                func()
            end
        end)
    end
end

--开始滚动
function CodeGameScreenWolfSmashMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:checkWolfSmashABTest() then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local mapBoatIndex = selfData.mapBoatIndex or self.pointPosByFree
            --狼头移动
        if mapBoatIndex ~= self.pointPosByFree then
            --改变freeSpin次数
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            self.m_map:showSmashPigIdle()
            self.m_map:changeWolfPos(self.pointPosByFree,mapBoatIndex)
            self.pointPosByFree = mapBoatIndex
        end
        CodeGameScreenWolfSmashMachine.super.beginReel(self)
    else
        CodeGameScreenWolfSmashMachine.super.beginReel(self)
    end
end

function CodeGameScreenWolfSmashMachine:getPigTypeNum()
    local num = 0
    local isOnePig = false
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusMultipleNum = selfData.bonusMultipleNum or {}
    for k, info in pairs(bonusMultipleNum) do
        if info[2] > 0 then
            num = num + 1
        end
    end
    if num <= 1 then
        isOnePig = true
    end
    return isOnePig
end

function CodeGameScreenWolfSmashMachine:showMapEffectForBeforeBeginReel(func)
    local waitTime = 1
    if self.waitChooseForBTest then
        waitTime = 1
    end
    self:delayCallBack(waitTime,function ()
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        --改变freeSpin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if table_length(selfData) > 0 then
            if self:checkWolfSmashABTest() then
                if func then
                    func()
                end
            else
                -- 先选择、狼头移动
                if self.m_newMap then
                    if self.m_newMap.isAuto then    --自动：使用服务器给的下标
                        -- local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                        local multple = selfData.bonusSelect or 2
                        self.chooseIndexForFree = 2
                        local index = self:getIndexForMultple(multple)
                        self.m_newMap:setChoosePigIndex(index)
                        --对应猪播反馈
                        self.m_newMap:showPigFankui(index)
                        self.m_newMap:setChooseIndexForABTest()
                        self.m_newMap:setWolfNodePosition(false)
                        print("自动:=" .. multple)
                        --等待移动结束在继续，不然会导致点击快停后，选择跟不上棋盘滚动
                        -- self:delayCallBack(17/60 + 0.2,function ()
                            if func then
                                func()
                            end
                        -- end)
                    else                            --弹窗：让玩家自己选择
                        if self:getPigTypeNum() then        --只剩下一种猪自动选择不弹窗
                            local multple = selfData.bonusSelect or 2
                            self.chooseIndexForFree = 4
                            local index = self:getIndexForMultple(multple)
                            self.m_newMap:setChoosePigIndex(index)
                            --对应猪播反馈
                            self.m_newMap:showPigFankui(index)
                            self.m_newMap:setChooseIndexForABTest()
                            self.m_newMap:setWolfNodePosition(false)
                            print("自动:=" .. multple)
                            --等待移动结束在继续，不然会导致点击快停后，选择跟不上棋盘滚动
                            -- self:delayCallBack(17/60 + 0.2,function ()
                                if func then
                                    func()
                                end
                        else
                            local bonusMultipleNum = selfData.bonusMultipleNum or {}
                            local multple = selfData.bonusSelect or 2
                            local index = self:getIndexForMultple(multple)
                            self.m_newMap:setChoosePigIndex(index)

                            self.m_newMap:showDarkAct(function ()
                                if func then
                                    func()
                                end
                            end,bonusMultipleNum)
                        end
                        -- local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                        
                    end
                else
                    if func then
                        func()
                    end
                end
            end
        else
            if func then
                func()
            end 
        end
    end)
        
end


--free预告
function CodeGameScreenWolfSmashMachine:showFreeYuGao(func)
    self.Freejvese:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_freeSpin_yugao)
    util_spinePlay(self.Freejvese, "actionframe3",false)
    self:delayCallBack(110/30,function ()
        self.Freejvese:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenWolfSmashMachine:isShowFreeYuGao()
    -- local winCoin = self.m_runSpinResultData.p_winAmount
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local multipleBeforeWinCount = selfData.multipleBeforeWinCount or 0
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = multipleBeforeWinCount / totalBet
    local randomNum = math.random(1, 16)
    if randomNum <  4 and winRate > 5 then
        return true
    end
    return false
end

-- 播放预告中奖统一接口
-- 子类重写接口
function CodeGameScreenWolfSmashMachine:showFeatureGameTip(_func)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local featureDatas = self.m_runSpinResultData.p_features or {}
    
    if featureDatas and featureDatas[2] == 1 then
        local randomNum = math.random(1, 10)
        if randomNum <= 5 then
            self.b_gameTipFlag = true
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:getReelDownBonusNum() >= 3 or self:isShowFreeYuGao() then
            self:showFreeYuGao(function ()
                _func()
            end)
        else
            _func()
        end
        
    else
        if self.b_gameTipFlag then
            self.m_isPlayYuGao = true
            self.yuGao:setVisible(true)
            self.yuGaoGold:setVisible(true)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_base_yuGao)
            util_spinePlay(self.yuGaoGold, "actionframe", false)
            self.yuGao:runCsbAction("actionframe", false, function()
                self.yuGao:setVisible(false)
                self.yuGaoGold:setVisible(false)
                self.b_gameTipFlag = false
                _func()
            end)
        else
            _func() 
        end
    end
end

--[[
    大赢飘数字
]]
function CodeGameScreenWolfSmashMachine:playBigWinNum1(winCoins)
    self.m_bottomUI.m_bigWinLabCsb:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_totalWin_show)
    self.m_bottomUI.m_bigWinLabCsb:runCsbAction("start",false,function ()
        self.m_bottomUI.m_bigWinLabCsb:runCsbAction("idleframe",false)
    end)
    self.m_bottomUI:setBigWinLabCoins(winCoins)
end

--[[
    大赢飘数字:模仿底层
]]
function CodeGameScreenWolfSmashMachine:playBigWinNum(beforeWinCoins)
    self.m_bottomUI.m_bigWinLabCsb:setVisible(true)
    local winCoins = self.m_runSpinResultData.p_winAmount
    local coinsText = self.m_bottomUI.m_bigWinLabCsb:findChild("m_lb_coins")
    self.m_bottomUI:setBigWinLabCoins(beforeWinCoins)
    if winCoins then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_totalWin_jump)
        local curCoins = beforeWinCoins
        local jumpTime = 90/60
        local coinRiseNum = winCoins / (jumpTime * 60)
        local str   = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
        coinRiseNum = tonumber(str)
        coinRiseNum = math.floor(coinRiseNum)
        self.m_scWaitNodeAction:stopAllActions()
        util_schedule(self.m_scWaitNodeAction, function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= winCoins then
                self.m_bottomUI:setBigWinLabCoins(winCoins)
                self.m_scWaitNodeAction:stopAllActions()
                self:delayCallBack(0.6,function ()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_totalWin_hide)
                    self.m_bottomUI.m_bigWinLabCsb:runCsbAction("over",false, function()
                        if self:getCurrSpinMode() == FREE_SPIN_MODE then
                            if self:checkHasBigWin() == true then
                                self:shakeNode()
                                self.bigWin:setVisible(true)
                                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_bigWin_yugao)
                                util_spinePlay(self.bigWin, "actionframe")
                                util_spineEndCallFunc(self.bigWin, "actionframe", function ()
                                    self.bigWin:setVisible(false)
                                end)
                            end
                        end
                        
                        self.m_bottomUI.m_bigWinLabCsb:setVisible(false)
                    end)
                    if self:getCurrSpinMode() == FREE_SPIN_MODE  then
                        self:delayCallBack(12/60,function ()
                            self:playCoinWinEffectUI()
                            self:checkNotifyUpdateWinCoin()
                        end)
                    end
                end)
                
            else
                self.m_bottomUI:setBigWinLabCoins(curCoins)
            end
        end, 1/60)
    end
    self.m_bottomUI.m_bigWinLabCsb:runCsbAction("idle", false)
    self.jiaqian:setVisible(true)
    util_spinePlay(self.jiaqian, "actionframe", false)
    util_spineEndCallFunc(self.jiaqian, "actionframe", function()
        self.jiaqian:setVisible(false)
    end)
end

--[[
    大赢动画重写连线
]]
--[[
    @desc: 1：普通状态下spin：正常连线、若有大赢，弹大赢数字
            2:free状态下spin:先出现成倍之前的钱数，小块震动，砸下成倍后，正常连线，若有大赢，弹数字
    author:{author}
    time:2023-02-17 15:02:30
    --@effectData: 
    @return:
]]
function CodeGameScreenWolfSmashMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end
    --free下，先播全线，走完砸猪流程后，再继续播每一条线
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.multipleBeforeWinCount then
            if selfData.multipleBeforeWinCount > 0 then
                local coins = selfData.multipleBeforeWinCount
                self:playBigWinNum1(coins)
                
            end
        end
        self:showBeforeLineFrame()
        -- self:showLineFrame()
    else
        self:showLineFrame()
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        effectData.p_isPlay = true
        self:playGameEffect()
    else
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            --大赢弹板时间延后
            self:delayCallBack(0.5,function ()
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

--大赢震动
function CodeGameScreenWolfSmashMachine:shakeNode()
    local changePosY = 10
    local changePosX = 5
    local actionList2 = {}
    self.shakeOldPos = cc.p(self:findChild("root"):getPosition())

    for i=1,5 do
        actionList2[#actionList2 + 1] = cc.MoveTo:create(2 / 30, cc.p(self.shakeOldPos.x + changePosX, self.shakeOldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(2 / 30, cc.p(self.shakeOldPos.x, self.shakeOldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(2 / 30, cc.p(self.shakeOldPos.x - changePosX, self.shakeOldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(2 / 30, cc.p(self.shakeOldPos.x, self.shakeOldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(2 / 30, cc.p(self.shakeOldPos.x + changePosX, self.shakeOldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(2 / 30, cc.p(self.shakeOldPos.x, self.shakeOldPos.y))
    end

    local seq2 = cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

--[[
    @desc: 优化：free状态下，播震动动画，砸完成倍后正常播连线
    author:{author}
    time:2023-02-17 14:47:19
    @return:
]]

function CodeGameScreenWolfSmashMachine:showBeforeLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    -- self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()      


    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then

        self:showAllFrame(winLines) -- 播放全部线框

    end
end

function CodeGameScreenWolfSmashMachine:showNewLineFrame()
    local winLines = self.m_reelResultLines
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
    
    
    self:playInLineNodes()
    self:showAllFrame(winLines) -- 播放全部线框
    showLienFrameByIndex()
end

function CodeGameScreenWolfSmashMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenWolfSmashMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenWolfSmashMachine:scaleMainLayer()
    CodeGameScreenWolfSmashMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    local offsetY = 0 - (DESIGN_SIZE.height - display.height)/2
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
    elseif ratio < 768/1370 and ratio >= 768/1530 then
    end
    if display.width/display.height >= 1812/2176 then
        local mainScale = 0.58
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    self.m_machineNode:setPositionY(offsetY)
end

-- 显示paytableview 界面
function CodeGameScreenWolfSmashMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"
    if not self:checkWolfSmashABTest() then
        csbFileName = "PayTableLayer" .. self.m_moduleName .. "_b" .. ".csb"
    end

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
    延迟回调
]]
function CodeGameScreenWolfSmashMachine:delayCallBack(time, func)
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

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenWolfSmashMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenWolfSmashMachine:showEffect_runBigWinLightAni(effectData)
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
function CodeGameScreenWolfSmashMachine:showBigWinLight(_func)
    self.m_bIsBigWin = false
    self.wolfNode:stopAllActions()
    util_spinePlay(self.jvese, "actionframe2",false)
    util_spineEndCallFunc(self.jvese, "actionframe2", function ()
        self:showJveSeIdle()
    end)
    self.bigWin:setVisible(true)
    self:shakeNode()
    util_spinePlay(self.bigWin, "actionframe")
    util_spineEndCallFunc(self.bigWin, "actionframe", function ()
        self.bigWin:setVisible(false)
    end)
    self:playBigWinNum(0)
    
    self:delayCallBack(1.5, function()
        if type(_func) == "function" then
            _func()
        end
    end)
end

--------------v2/ABTest

-- ABTest 
function CodeGameScreenWolfSmashMachine:checkWolfSmashABTest()
    --
    return globalData.GameConfig:checkABtestGroupA("WolfSmash")
end

function CodeGameScreenWolfSmashMachine:setChooseIndexForABTest(index)
    self.chooseIndexForABTest = index
    
end


--V2:free中每次spin之前选择一个成倍，发给服务器。（如果没选择，则使用服务器给的默认值）
function CodeGameScreenWolfSmashMachine:createMapEffectForABTetst()
    self.m_newMap = util_createView("CodeWolfSmashSrc.newFree.WolfSmashFreeSpinNewMapView",self)
    self:findChild("Node_ditu2"):addChild(self.m_newMap)
    self.m_newMap:setVisible(false)
end

function CodeGameScreenWolfSmashMachine:wolfSmashPigEffectForABTest(func)
    local node = cc.Node:create()
    self:addChild(node)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusMultipleNum = selfData.bonusMultipleNum or {}
        self.m_newMap:showWolfStrikePig(bonusMultipleNum,function ()
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local bonusMultipleNum = selfData.bonusMultipleNum or {}
            self.m_newMap:changePigNum(bonusMultipleNum)
        end)   --40帧
    end)
    actList[#actList + 1] = cc.DelayTime:create(20/30)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        local startPosNode = self.m_newMap:getEndNode()
        local startPos = util_convertToNodeSpace(startPosNode,self.m_effectNode)
        local curMultiple = self.m_newMap:getCurPigMultiple()
        -- self:runCsbAction("over_zj")
        if curMultiple >= 5 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_chengbei_down)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_chengbei_down2)
        end
        
        self:flyChengBeiStrForABTest(startPos,curMultiple,self.m_newMap.curChoose)      --68帧
    end)
    actList[#actList + 1] = cc.DelayTime:create(68/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        
        self:showSelfActionFrameForABTest()
    end)
    actList[#actList + 1] = cc.DelayTime:create(120/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        node:removeFromParent()
        if self:checkHasBigWin() then
            --大赢弹板时间延后
            self:delayCallBack(3,function ()
                if type(func) == "function" then
                    func()
                end
            end)
        else
            if type(func) == "function" then
                func()
            end
        end
        
    end)
    node:runAction(cc.Sequence:create( actList))
end

function CodeGameScreenWolfSmashMachine:flyChengBeiStrForABTest(startPos,multiple,curPigIndex)
    local chengbeiNode =  util_createAnimation("WolfSmash_chengbei.csb")
    self.m_effectNode:addChild(chengbeiNode,GAME_LAYER_ORDER.LAYER_ORDER_EFFECT + 20)
    chengbeiNode:runCsbAction("idle")
    chengbeiNode:setPosition(startPos)
    local endPos = util_convertToNodeSpace(self:findChild("Node_chengbei"),self.m_effectNode)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self:showChengBeiStr(chengbeiNode,multiple)
        chengbeiNode:runCsbAction("actionframe2")
    end)
    actList[#actList + 1] = cc.DelayTime:create(20/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        
        -- local smashPig = self.m_map:getSmashPig(curPigIndex)
        -- if smashPig then
        --     self:delayCallBack(5/60,function ()
        --         local curPigForView = smashPig.coinsView
        --         curPigForView:runCsbAction("start")
        --     end)
        -- end
        
        chengbeiNode:runCsbAction("actionframe")
        if multiple >= 5 then
            -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_show_fiveOrTen)
        end
    end)
    actList[#actList + 1] = cc.MoveTo:create(24/60, endPos)
    actList[#actList + 1] = cc.DelayTime:create(24/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        chengbeiNode:removeFromParent()
    end)
    chengbeiNode:runAction(cc.Sequence:create( actList))
end

function CodeGameScreenWolfSmashMachine:showFreeSpinStart(num, func1,func2)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusMultipleNum = selfData.bonusMultipleNum or {}
    local view = util_createView("CodeWolfSmashSrc.newFree.WolfSmashNewFreeSpinStartView",{bonusMultipleNum = bonusMultipleNum,endFunc1 = func1,endFunc2 = func2})
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
    
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--根据倍数播放棋盘震动动画
function CodeGameScreenWolfSmashMachine:showSelfActionFrameForABTest()
    local curMultiple = self.m_newMap:getCurPigMultiple()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local multipleBeforeWinCount = selfData.multipleBeforeWinCount or 0
    if curMultiple < 5 then
        self:runCsbAction("actionframe",false,function ()
            self:runCsbAction("idle",true)
        end)
        local coins = multipleBeforeWinCount
        self:playBigWinNum(coins)
        self.jiaqian:setVisible(true)
        util_spinePlay(self.jiaqian, "actionframe", false)
        util_spineEndCallFunc(self.jiaqian, "actionframe", function()
            self.jiaqian:setVisible(false)
        end)
        self:delayCallBack(82/60,function ()
            self:showNewLineFrame()         --砸完猪后显示每一条线
        end)
    else
        self:runCsbAction("actionframe2",false,function ()
            self:runCsbAction("idle",true)
        end)
        local coins = multipleBeforeWinCount
        self:playBigWinNum(coins)
        self.jiaqian:setVisible(true)
        util_spinePlay(self.jiaqian, "actionframe", false)
        util_spineEndCallFunc(self.jiaqian, "actionframe", function()
            self.jiaqian:setVisible(false)
    end)
        self:delayCallBack(82/60,function ()
            self:showNewLineFrame()
        end)
    end
end

--free增加小猪相关 list中有位置和下标
function CodeGameScreenWolfSmashMachine:addPigForMapEffectForABTest(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusMultipleNum = selfData.bonusMultipleNum or {}
    local bonusMultipleNumBeforeSmash = selfData.bonusMultipleNumBeforeSmash or {}
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local pigCollectAct = {false,false,false,false}
    local function getPigIndexForMultiples(mul)
        if mul == 2 then
            return 1
        elseif mul == 3 then
            return 2
        elseif mul == 5 then
            return 3
        elseif mul == 10 then
            return 4
        end
    end
    local isSound1 = true
    local isSound2 = true
    for i, v in ipairs(storedIcons) do
        local pigIndex = getPigIndexForMultiples(tonumber(v[2]))
        local fixPos = self:getRowAndColByPos(v[1])
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if isSound1 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_bonus_add_pig)
            isSound1 = false
        end
        symbolNode:runAnim("shouji")
        local startPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
        local endPosNode = self.m_newMap:getEndNode2(pigIndex)
        local endPos = util_convertToNodeSpace(endPosNode,self.m_effectNode)
        self:FlyParticle(startPos,endPos,function ()
            if not pigCollectAct[pigIndex] then
                pigCollectAct[pigIndex] = true
                --反馈
                self.m_newMap:showPigFankui(pigIndex)
            end
            if isSound2 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_bonus_add_pig_fankui)
                isSound2 = false
            end
        end)
    end
    --刷新个数
    self:delayCallBack(0.5,function ()
        self.m_newMap:changePigNum(bonusMultipleNumBeforeSmash)
        if func then
            func()
        end
    end)
end

function CodeGameScreenWolfSmashMachine:getIndexForMultple()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local multple = selfData.bonusSelect or 2
    if multple == 2 then
        return 1
    elseif multple == 3 then
        return 2
    elseif multple == 5 then
        return 3
    elseif multple == 10 then
        return 4
    end
end

function CodeGameScreenWolfSmashMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        if self:getCurrSpinMode() == FREE_SPIN_MODE and not self:checkWolfSmashABTest() then
            
        else
            delayTime = delayTime + self:getWinCoinTime()
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
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
end

return CodeGameScreenWolfSmashMachine






