---
-- island li
-- 2019年1月26日
-- CodeGameScreenHogHustlerMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

local CodeGameScreenHogHustlerMachine = class("CodeGameScreenHogHustlerMachine", BaseNewReelMachine)

CodeGameScreenHogHustlerMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenHogHustlerMachine.SYMBOL_FIX_SYMBOL_BONUSWILD     = 93   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_SYMBOL_BONUS         = 94   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_MINI                 = 95   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_MINOR                = 96   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_MAJOR                = 97   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_GRAND                = 98   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_BONUSWILD_MINI       = 950   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_BONUSWILD_MINOR      = 960   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_BONUSWILD_MAJOR      = 970   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_BONUSWILD_GRAND      = 980   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.SYMBOL_FIX_BLANK                = 999   -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.m_fixX = 0  --适配x坐标的移动
CodeGameScreenHogHustlerMachine.m_reelScale = 1  --适配x坐标的移动
CodeGameScreenHogHustlerMachine.GAME_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1  -- 自定义的小块类型
CodeGameScreenHogHustlerMachine.GAME_MAP_EFFECT = GameEffect.EFFECT_FREE_SPIN - 2  -- 自定义的小块类型

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

CodeGameScreenHogHustlerMachine.m_chipList = nil
CodeGameScreenHogHustlerMachine.m_playAnimIndex = 0
CodeGameScreenHogHustlerMachine.m_lightScore = 0


-- 构造函数
function CodeGameScreenHogHustlerMachine:ctor()
    CodeGameScreenHogHustlerMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true

    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_isLongRun = false

    self.m_beginFree = false
    self.m_beginChangeFree5Col = false
    self.m_beginChangeFree5ColAnim = false
    self.m_freeCreate5ColCount = 0
    self.m_disableSpinBtn = false

    self.m_respinStoreValue = {}
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
	--init
	self:initGame()

end

function CodeGameScreenHogHustlerMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("HogHustlerConfig.csv", "LevelHogHustlerConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    -- self.m_clipNode = {}
    self.m_reconnect = false
    self.m_isShowWinAni = false
    self.m_isHaseMapEffect = false

    self.m_notClick = true
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {1,2,3,4}

end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenHogHustlerMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "HogHustler"  
end




function CodeGameScreenHogHustlerMachine:initUI()

    --jackpotBar
    self.m_jackpotBar = util_createView("CodeHogHustlerSrc.HogHustlerJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar, 500)
    self.m_jackpotBar:initMachine(self)
    -- self.m_jackpotBar:setVisible(false)

    --freeBar
    self.m_freeBar = util_createView("CodeHogHustlerSrc.HogHustlerFreespinBarView")
    local nodePos_freebar = util_convertToNodeSpace(self:findChild("freebar"),  self:findChild("jackpot"))
    self:findChild("jackpot"):addChild(self.m_freeBar, 300)
    self.m_freeBar:setVisible(false)
    self.m_freeBar:setPosition(cc.p(nodePos_freebar))


    self.m_respinSpinbar = util_createView("CodeHogHustlerSrc.HogHustlerRespinBarView")
    local nodePos_respinSpinbar = util_convertToNodeSpace(self:findChild("freebar"),  self:findChild("jackpot"))
    self:findChild("jackpot"):addChild(self.m_respinSpinbar, 300)
    self.m_respinSpinbar:setVisible(false)
    self.m_respinSpinbar:setPosition(cc.p(nodePos_respinSpinbar))


    self.m_collectBar = util_createView("CodeHogHustlerSrc.HogHustlerCollectBarView", self)
    local nodePos_shoujitiao = util_convertToNodeSpace(self:findChild("shoujitiao"),  self.m_clipParent)
    -- self:findChild("jackpot"):addChild(self.m_collectBar, 300)
    self.m_clipParent:addChild(self.m_collectBar, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    self.m_collectBar:setPosition(cc.p(nodePos_shoujitiao))
    

    --地图
    self.m_map = util_createView("CodeHogHustlerSrc.Map.HogHustlerMainMap", self)
    self:findChild("dafuweng"):addChild(self.m_map,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_map:setVisible(false)

    --效果节点
    self.m_effectNode = cc.Node:create()
    self:findChild("Node_ui"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_effectNode:setPosition(cc.p(display.width / 2,display.height / 2))

    --预告中奖
    self.m_yugao = util_spineCreate("HogHustler_yugao", true, true)
    self:findChild("Node_ui"):addChild(self.m_yugao)
    self.m_yugao:setVisible(false)

    --free过场
    self.m_free_guochang = util_spineCreate("HogHustler_juese", true, true)
    self:findChild("Node_ui"):addChild(self.m_free_guochang, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_free_guochang:setVisible(false)

    --respin过场
    self.m_respin_guochang = util_spineCreate("HogHustler_tanban_juese", true, true)
    self:findChild("Node_ui"):addChild(self.m_respin_guochang, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_respin_guochang:setVisible(false)

    -- self.m_test = util_createSprite("HogHustlerSymbol/Socre_HogHustler_3.png")
    -- self.m_test = util_createAnimation("HogHustler_More.csb")
    -- self:findChild("Node_ui"):addChild(self.m_test, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)
    -- self:test()

    self.m_col5Effect = util_createAnimation("HogHustler_free_run_0.csb")
    local pos = util_convertToNodeSpace(self:findChild("sp_reel_4"),  self.m_clipParent)
    self.m_col5Effect:setPosition(cc.p(pos.x, pos.y))
    self.m_clipParent:addChild(self.m_col5Effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 5)
    -- self.m_col5Effect:playAction("idle", true)
    self.m_col5Effect:setVisible(false)

    self.m_col5Effect_idle = util_createAnimation("HogHustler_free_run.csb")
    local pos = util_convertToNodeSpace(self:findChild("sp_reel_4"),  self.m_clipParent)
    self.m_col5Effect_idle:setPosition(cc.p(pos.x, pos.y))
    self.m_clipParent:addChild(self.m_col5Effect_idle, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 4)
    -- self.m_col5Effect:playAction("idle", true)
    self.m_col5Effect_idle:setVisible(false)


    --reelPos
    self.m_reel_pos = cc.p(self:findChild("reel"):getPosition())


    self.m_gameBgSpine = util_spineCreate("GameScreenHogHustlerBg", true, true)
    self.m_gameBg:findChild("Node_18"):addChild(self.m_gameBgSpine, 1)
    self.m_gameBgSpine:setPositionY(0)
    self.m_gameBg:findChild("SmellyRich_guochang_up5_85"):setLocalZOrder(0)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --收集条引导
    self.m_collectBar_tip = util_createView("CodeHogHustlerSrc.HogHustlerCollectBarTipView")
    -- self:findChild("reel"):addChild(self.m_collectBar_tip)
    local nodePos_collectBar_tip = util_convertToNodeSpace(self:findChild("shoujitiao"),  self.m_clipParent)
    -- self:findChild("jackpot"):addChild(self.m_collectBar, 300)
    self.m_clipParent:addChild(self.m_collectBar_tip, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_collectBar_tip:setPosition(nodePos_collectBar_tip)
    self.m_collectBar_tip:setVisible(false)

    -- 大赢前特效
    self.m_spineBigWin = util_spineCreate("HogHustler_binwin", true, true)
    self:findChild("bigwin"):addChild(self.m_spineBigWin, 0)
    self.m_spineBigWin:setPosition(0,0)
    self.m_spineBigWin:setVisible(false)

    --大赢spine 多个
    local bigWin2NodePos = util_convertToNodeSpace(self:findChild("bigwin"),  self.m_clipParent)
    self.m_HogHustler_binwin2 = util_spineCreate("HogHustler_binwin2", true, true)
    -- self:findChild("bigwin"):addChild(self.m_HogHustler_binwin2, 1)
    self.m_clipParent:addChild(self.m_HogHustler_binwin2, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    self.m_HogHustler_binwin2:setPosition(cc.p(0, 0))
    self.m_HogHustler_binwin2:setVisible(false)
    self.m_HogHustler_binwin3 = util_spineCreate("HogHustler_binwin3", true, true)
    -- self:findChild("bigwin"):addChild(self.m_HogHustler_binwin3, 1)
    self.m_clipParent:addChild(self.m_HogHustler_binwin3, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    self.m_HogHustler_binwin3:setPosition(cc.p(0, 0))
    self.m_HogHustler_binwin3:setVisible(false)
    self.m_HogHustler_binwin4 = util_spineCreate("HogHustler_binwin4", true, true)
    -- self:findChild("bigwin"):addChild(self.m_HogHustler_binwin4, 1)
    self.m_clipParent:addChild(self.m_HogHustler_binwin4, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    self.m_HogHustler_binwin4:setPosition(cc.p(0, 0))
    self.m_HogHustler_binwin4:setVisible(false)

    --root同级节点
    self.m_rootEffectNode = cc.Node:create()
    self:addChild(self.m_rootEffectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    

    self.m_tips = util_createView("CodeHogHustlerSrc.HogHustlerTipsView", self, "HogHustler_tishixinxi.csb", false)
    self:findChild("tishixinxi"):addChild(self.m_tips)
    self.m_tips:setVisible(false)
    -- self:initTips()

    --通用遮罩
    self.m_mask = util_createAnimation("HogHustler_Mask.csb")
    self:findChild("Node_ui"):addChild(self.m_mask, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    self.m_mask:setVisible(false)

    --全屏幕防点击
    self.m_gobalTouchLayer = ccui.Layout:create()
    self.m_gobalTouchLayer:setContentSize(cc.size(50000, 50000))
    self.m_gobalTouchLayer:setAnchorPoint(cc.p(0, 0))
    self.m_gobalTouchLayer:setTouchEnabled(false)
    self.m_gobalTouchLayer:setSwallowTouches(false)
    -- self.m_gobalTouchLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    -- self.m_gobalTouchLayer:setBackGroundColor(cc.c3b(0, 150, 0))
    -- self.m_gobalTouchLayer:setBackGroundColorOpacity(150)
    self:addChild(self.m_gobalTouchLayer, GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 1)
    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if not (freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE) then
            if self.m_bIsBigWin then
                return 
            end
        end 

        if self:getCurrSpinMode() == RESPIN_MODE then
            return
        end
        if self.m_notClick then
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
        elseif winRate > 3 then
            soundIndex = 3
        end

        local name_str = "music_HogHustler_last_win_"
        if self.m_bProduceSlots_InFreeSpin then
            name_str = "music_HogHustler_last_freewin_"
        end
        local soundName = string.format("HogHustlerSounds/%s%d.mp3", name_str, soundIndex)
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenHogHustlerMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_entergame_music)

    end,0.1,self:getModuleName())
end

function CodeGameScreenHogHustlerMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_notClick = true
    CodeGameScreenHogHustlerMachine.super.onEnter(self)     -- 必须调用不予许删除
    self.m_notClick = false

    if self.m_runSpinResultData.p_freeSpinsLeftCount == nil or self.m_runSpinResultData.p_freeSpinsLeftCount <= 0  then
        --respin框架里此时没设置模式 free也仅限于触发时设置了
        if self.m_runSpinResultData.p_reSpinCurCount == nil or self.m_runSpinResultData.p_reSpinCurCount <= 0 then
            self:addEnterGameView()
            self:changeBg("base")
            self.m_tips:TipClick()
        else
            self:changeBg("respin")
            self.m_respinSpinbar:changeRespinTimes(self.m_runSpinResultData.p_reSpinCurCount, true)
        end
    else
        self:changeBg("free")
        self.m_freeBar:changeFreeSpinByCount()
    end


    if self.m_bProduceSlots_InFreeSpin then      --此值在 onenter中设置了 未设置mode
        self.m_ScatterShowCol = {1,2,3,4}
        self.m_beginChangeFree5Col = true
        -- self.m_col5Effect:setVisible(true)
        self.m_col5Effect_idle:setVisible(true)
        self.m_col5Effect_idle:playAction("idle", true)
        -- self.m_col5Effect:playAction("idle", true)
    end

    -- local k = self:getCurrSpinMode()

    -- local m = self.m_bProduceSlots_InFreeSpin
    
    self:addObservers()

    -- self:waitWithDelay(5, function()
    --     if self.m_tips then
    --         self:removeTips()
    --     end
    -- end)


    self:getSpecialBets()
end

function CodeGameScreenHogHustlerMachine:addObservers()
    CodeGameScreenHogHustlerMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,param)
        if self:isNormalStates() then
            self:showMap(true)
        else
            self.m_collectBar:resetClick()
        end
    end,"MAP_SHOW_CLICK_SMELLYRICH")

    gLobalNoticManager:addObserver(self,function(self,param)
        if self:isNormalStates() then
            self:clickMapTipView()
        end
    end,"TIP_SHOW_SMELLYRICH")

    gLobalNoticManager:addObserver(self,function(self,param)
        self:showFirstMap()
    end,"MAP_SHOWFIRST_CLICK_SMELLYRICH")

    gLobalNoticManager:addObserver(self,function(self,param)
        self:hideMap(param)
    end,"MAP_HIDE_CLICK_SMELLYRICH")
end

function CodeGameScreenHogHustlerMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenHogHustlerMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenHogHustlerMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_FIX_SYMBOL_BONUSWILD then
        return "Socre_HogHustler_Bonus2"
    elseif symbolType == self.SYMBOL_FIX_SYMBOL_BONUS then
        return "Socre_HogHustler_Bonus"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_HogHustler_Bonus"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_HogHustler_Bonus"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_HogHustler_Bonus"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_HogHustler_Bonus"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_MINI then
        return "Socre_HogHustler_Bonus2"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_MINOR then
        return "Socre_HogHustler_Bonus2"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_MAJOR then
        return "Socre_HogHustler_Bonus2"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_GRAND then
        return "Socre_HogHustler_Bonus2"
    elseif symbolType == self.SYMBOL_FIX_BLANK then
        return "Socre_HogHustler_Blank"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenHogHustlerMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenHogHustlerMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL_BONUSWILD, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL_BONUS, count =  10}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GRAND, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUSWILD_MINI, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUSWILD_MINOR, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUSWILD_MAJOR, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUSWILD_GRAND, count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BLANK, count =  10}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenHogHustlerMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
            self.m_reconnect = true
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenHogHustlerMachine:slotOneReelDown(reelCol)    
    CodeGameScreenHogHustlerMachine.super.slotOneReelDown(self,reelCol) 

    --respin
    local isplay= true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true and isplay then
            isplay = false
            -- respinbonus落地音效
            -- gLobalSoundManager:playSound("levelsTempleSounds/music_levelsTemple_fall_" .. reelCol ..".mp3") 
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenHogHustlerMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    -- self.m_freeBar:setVisible(true)
    -- self.m_collectBar:setVisible(false)
    -- local pos = cc.pAdd(self.m_reel_pos, cc.p(0, 15 * self.m_machineRootScale)) 
    -- self:findChild("reel"):setPosition(pos)
    self:changeBg("free")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenHogHustlerMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    -- self.m_freeBar:setVisible(false)
    -- self.m_collectBar:setVisible(true)
    -- self:findChild("reel"):setPosition(self.m_reel_pos)
    self:changeBg("base")
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenHogHustlerMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_more_popup)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            local node=view:findChild("m_lb_num")
            view:updateLabelSize({label=node,sx=1,sy=1},241)
            view.m_btnTouchSound = ""
            view:findChild("root"):setScale(self.m_machineRootScale)
            -- gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_custom_enter_more.mp3")
        else
            self.m_bottomUI:checkClearWinLabel() --清totalwin
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_free_guoChang.mp3")
                self:showFreeGuoChang(function()
                    self.m_iOnceSpinLastWin = 0     --单次赢钱清空 防止触发时 getWinCoinTime 时间过长
                    self:triggerFreeSpinCallFun()
                end, function()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end, true)
            end)
            local node=view:findChild("m_lb_num")
            view:updateLabelSize({label=node,sx=1,sy=1},241)
            view:findChild("root"):setScale(self.m_machineRootScale)
            -- gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_custom_enter_fs.mp3")
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_popupstart_start)
            view:setBtnClickFunc(function()
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_popupstart_over)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenHogHustlerMachine:showFreeSpinOverView()
    self.m_ScatterShowCol = {1,2,3,4,5}
    self.m_beginChangeFree5Col = false
    -- self.m_col5Effect:setVisible(false)
    self.m_col5Effect_idle:setVisible(false)
    self.m_beginChangeFree5ColAnim = false
    self.m_disableSpinBtn = false

    -- gLobalSoundManager:playSound("HogHustlerSounds/music_HogHustler_over_fs.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_free_guoChang2.mp3")
        self:showFreeGuoChang(function()
            self:levelFreeSpinOverChangeEffect()
        end, function()
            self:triggerFreeSpinOverCallFun()
        end, false)
    end)
    
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_popupover_start)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_popupover_over)
    end)

    self:addPopupCommonRole(view, nil, nil, "start_tanban2", "idle_tanban2")

    view:findChild("root"):setScale(self.m_machineRootScale)
end

-- 重写
function CodeGameScreenHogHustlerMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    
    if self.m_runSpinResultData.p_fsWinCoins == 0 then
        return self:showDialog("FreeSpinOver1", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        local dialog = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

        local node=dialog:findChild("m_lb_coins")
        dialog:updateLabelSize({label=node,sx=1,sy=1},732)
        local node=dialog:findChild("m_lb_num")
        dialog:updateLabelSize({label=node,sx=1,sy=1},57)

        return dialog
    end
end

function CodeGameScreenHogHustlerMachine:resetIdleAnim()
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local _slotNode = self:getFixSymbol(iCol,iRow)
            if _slotNode then
                if self:isFixSymbol(_slotNode.p_symbolType) then
                    _slotNode:runIdleAnim()
                end
            end
        end
    end
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenHogHustlerMachine:MachineRule_SpinBtnCall()
    self.m_isShowWinAni = false
    self.m_freeCreate5ColCount = 0
    self:setMaxMusicBGVolume( )
    -- self:setSymbolToReel()
    self:resetIdleAnim()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    if self.m_tips:isVisible() then
        self.m_tips:TipClick()
    end


    -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
    --     if self.m_col5Effect_idle:isVisible() then
    --         self.m_col5Effect_idle:playAction("start", false, function()
    --             self.m_col5Effect_idle:playAction("idle", true)
    --         end)
    --     end
    -- end

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenHogHustlerMachine:addSelfEffect()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.collect_icon then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_COLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_COLLECT_EFFECT -- 动画类型
        self.m_collectBar:setLetterNum(selfdata.collect_box)
    end

    if selfdata.coin then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_MAP_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_MAP_EFFECT -- 动画类型
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenHogHustlerMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.GAME_COLLECT_EFFECT then
        self:showEffect_gameCollect(effectData)
    elseif effectData.p_selfEffectType == self.GAME_MAP_EFFECT then
        self:showEffect_mapEffect(effectData)
    end

	return true
end

-- self.m_gameEffects 事件列表执行完毕时
function CodeGameScreenHogHustlerMachine:playEffectNotifyNextSpinCall()
	CodeGameScreenHogHustlerMachine.super.playEffectNotifyNextSpinCall( self )
	self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- 轮盘滚动停止时
function CodeGameScreenHogHustlerMachine:slotReelDown()
    -- if self.m_isLongRun then
    --     --scatter期待动画还原
    --     for iCol = 1,self.m_iReelColumnNum do
    --         for iRow = 1,self.m_iReelRowNum do
    --             local _slotNode = self:getFixSymbol(iCol,iRow)
    --             if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --                 _slotNode:runAnim("idleframe2", true)
    --             end
    --         end
    --     end
    --     self.m_isLongRun = false
    -- end


	CodeGameScreenHogHustlerMachine.super.slotReelDown(self)
	self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )


    -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
    --     if self.m_col5Effect_idle:isVisible() then
    --         self.m_col5Effect_idle:playAction("over", false)
    --     end
    -- end
end

function CodeGameScreenHogHustlerMachine:showEffect_gameCollect(effectData)
    local flyTime = 0.3
    local actionframeTimes = 0.5
    local isFresh = false
    local isFirst = true
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local reelsIndex = self:getPosReelIdx(iRow, iCol)
            local isCollect,collectNum = self:getCollectData(reelsIndex)
            if isCollect then
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and node.m_Coin then
                    -- 克隆收集图标
                    local tempCoin = util_createView("CodeHogHustlerSrc.HogHustlerReelsJiaoBiao", collectNum)
                    self.m_effectNode:addChild(tempCoin)
                    local startPos = util_convertToNodeSpace(node.m_Coin, self.m_effectNode)
                    tempCoin:setPosition(startPos)
                    tempCoin:runCsbAction("shouji")
                    --移除小块内的金币图标
                    node.m_Coin:stopAllActions()
                    node.m_Coin:removeFromParent()
                    node.m_Coin = nil
                    local endPos = util_convertToNodeSpace(self.m_collectBar:getTargetNode(collectNum), self.m_effectNode)
                    local actionList = {}
                    actionList[#actionList + 1] = cc.DelayTime:create(actionframeTimes)
                    actionList[#actionList + 1] =
                        cc.CallFunc:create(
                        function()
                            if not tolua.isnull(tempCoin) then
                                tempCoin:findChild("Particle_1"):resetSystem()
                                tempCoin:findChild("Particle_1"):setPositionType(0)
                                tempCoin:findChild("Particle_1_0"):resetSystem()
                                tempCoin:findChild("Particle_1_0"):setPositionType(0)
                            end
                            if isFirst then
                                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_collect_fly.mp3")
                                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_base_cornercolect_begin)
                                isFirst = false
                            end
                        end
                    )
                    actionList[#actionList + 1] = cc.BezierTo:create(flyTime,{startPos, cc.p(endPos.x, startPos.y), endPos})
                    actionList[#actionList + 1] =
                        cc.CallFunc:create(
                        function()
                            if not isFresh then
                                self.m_collectBar:refreshLabel()
                                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_collect_fankui.mp3")
                                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_base_cornercolect_end)
                                isFresh = true
                            end
                            if not tolua.isnull(tempCoin) then
                                tempCoin:findChild("Particle_1"):stopSystem()
                                tempCoin:findChild("Particle_1_0"):stopSystem()
                                tempCoin:findChild("Node_1"):setVisible(false)
                            end
                        end
                    )
                    actionList[#actionList + 1] = cc.DelayTime:create(0.2)
                    actionList[#actionList + 1] = cc.RemoveSelf:create()
                    local sq = cc.Sequence:create(actionList)
                    tempCoin:runAction(sq)
                end
            end
        end
    end
    local delay_tiem = 0.1
    if self:checkHasGameSelfEffectType(self.GAME_MAP_EFFECT) then
        delay_tiem = 2
    end
    self:waitWithDelay(delay_tiem, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)
end


function CodeGameScreenHogHustlerMachine:showEffect_mapEffect(effectData)
    self.m_isHaseMapEffect = true
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local diceNum = selfdata.diceNum or 0
    local coin = selfdata.coin
    local addNum = selfdata.addNum
    local prize = selfdata.level_prize
    local firstTime = selfdata.firstTime or false
    self.m_map:setMapPrizeInfo(prize)
    self.m_map:setFirstTime(firstTime)
    self.m_map:updataShowPrizeNum()
    self.m_map:initDiceNum(diceNum)
    self.m_collectBar:fankui(diceNum)
    self:waitWithDelay(2.2, function()
        self:clearWinLineEffect()
        if firstTime then
            self:showCollectTip()
        else
            if diceNum >= 100 then
                self:showFullDiceViw(function()
                    self:showChooseView(diceNum, coin)
                end)
            else
                self:showChooseView(diceNum, coin)
            end
        end
    end)
end

--选择弹板
function CodeGameScreenHogHustlerMachine:showChooseView(addNum, coin)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_chooseView_show.mp3")
    local csbName = coin > 0 and "DafuwengStart3" or "DafuwengStart4"
    local strCoins=util_formatCoins(coin,30)
    local ownerlist={}
    ownerlist["m_lb_num"] = addNum
    if coin > 0 then
        ownerlist["m_lb_coins"] = strCoins
    end
    local callFunc = function(name)
        local winLines = self.m_runSpinResultData.p_winLines or {}
        if #winLines <= 0 then
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coin,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin
            self:playCoinWinEffectUI()
        else
            --有连线 基础上加
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coin,true})
            self:playCoinWinEffectUI()
        end
        -- self:totalWinLabelEffect()

        
        if name == "Button_yes" then
            self:waitWithDelay(1, function()
                self:showRichManStart(addNum, coin)
            end)
        else
            self.m_collectBar:reset()
            if self.m_collectBar then
                self.m_collectBar:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            end
            if self.m_isHaseMapEffect then
                self:notifySelfGameEffectPlayComplete(self.GAME_MAP_EFFECT)
                self.m_isHaseMapEffect = false
            end
        end
    end
    local view = self:showDialog(csbName,ownerlist, callFunc)
    if coin > 0 then
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.7,sy=0.7},732)
    end
    view:findChild("root"):setScale(self.m_machineRootScale)

    self:addPopupCommonRole(view)

    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_out_popupstart_start)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_out_popupstart_over)
        
    end)

end

-- function CodeGameScreenHogHustlerMachine:totalWinLabelEffect()
--     --totalwin 特效
--     local totalWinEffect = util_spineCreate("HogHustler_binwin2", true, true)
--     self.m_rootEffectNode:addChild(totalWinEffect, 1)
--     local endNode = self.m_bottomUI:findChild("font_last_win_value")
--     local totalWinpos = util_convertToNodeSpace(endNode, self.m_rootEffectNode)
--     totalWinEffect:setPosition(cc.p(totalWinpos))


--     util_spinePlay(totalWinEffect, "baodian", false)
--     local spineEndCallFunc = function()
--         totalWinEffect:setVisible(false)
--     end
--     util_spineEndCallFunc(totalWinEffect, "baodian", spineEndCallFunc)

--     self:waitWithDelay(2, function()
--         if totalWinEffect and not tolua.isnull(totalWinEffect) then
--             totalWinEffect:removeFromParent()
--         end
--     end)
-- end

function CodeGameScreenHogHustlerMachine:addPopupCommonRole(_view, _spineName, _nodeName, _spineStartName, _spineIdleName, _spineOverName)
    if not _view then
        return
    end
    local spineName = _spineName or "HogHustler_tanban_juese"
    local role = util_spineCreate(spineName, true, true)
    if not role then 
        return 
    end
    local nodeName = _nodeName or "juese"
    local juese = _view:findChild(nodeName)
    if not juese then
        return 
    end

    juese:addChild(role)
    role:setPosition(cc.p(0, 0))
    local spineStartName = _spineStartName or "start_tanban"
    local spineIdleName = _spineIdleName or "idle_tanban"
    util_spinePlay(role, spineStartName)
    util_spineEndCallFunc(role, spineStartName, function()
        if role and not tolua.isnull(role) then
            util_spinePlay(role, spineIdleName, true)
        end
    end)
    util_setCascadeOpacityEnabledRescursion(_view,true)

    if _spineOverName then
        _view:setBtnClickFunc(function (  )
            if role and not tolua.isnull(role) then
                util_spinePlay(role, _spineOverName, false)
            end
        end)
    end
    
end


--100提示弹板
function CodeGameScreenHogHustlerMachine:showFullDiceViw(callBack)
    local csbName = "Dafuweng_tishi"
    local view = self:showDialog(csbName,nil, callBack, BaseDialog.AUTO_TYPE_ONLY)

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_out_popupstart_start)
    -- view:setBtnClickFunc(function()
    --     gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_out_popupstart_over)
        
    -- end)
    self:waitWithDelay(155/60,function()
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_out_popupstart_over)
    end)

    self:addPopupCommonRole(view)
    
end


--大富翁开始弹板
function CodeGameScreenHogHustlerMachine:showRichManStart(addNum, coin, isFirst)
    self:showMap()
    self.m_map:setClick(true)
    self:waitWithDelay(3.25,function()
        self:showMapStart(addNum, coin, isFirst)
    end)
end

function CodeGameScreenHogHustlerMachine:setSlotsNodeSpineSkin(node, skinName)

    local ccbNode = node:getCCBNode()
    if not ccbNode then
        node:checkLoadCCbNode()
    end
    ccbNode = node:getCCBNode()
    if ccbNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
    -- node:runAnim(actionName,false,function()
    --     if func then
    --         func()
    --     end
    -- end)
end

function CodeGameScreenHogHustlerMachine:getSymbolSkin(symbolType)
    local skin_str = "default"
    if symbolType == self.SYMBOL_FIX_SYMBOL_BONUS then
        skin_str = "default"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        skin_str = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        skin_str = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        skin_str = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        skin_str = "GRAND"
    elseif symbolType == self.SYMBOL_FIX_SYMBOL_BONUSWILD then
        skin_str = "default"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_MINI then
        skin_str = "MINI"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_MINOR then
        skin_str = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_MAJOR then
        skin_str = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_BONUSWILD_GRAND then
        skin_str = "GRAND"
    end
    return skin_str
end

function CodeGameScreenHogHustlerMachine:updateReelGridNode(node)

    self:bonusHideScore(node)

    --移除小块内的金币图标
    if node.m_Coin then
        node.m_Coin:stopAllActions()
        node.m_Coin:removeFromParent()
        node.m_Coin = nil
    end
    -- 收集角标相关
    if node:isLastSymbol() then
        local reelsIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)

        -- local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        -- for i = 1, #selfdata.collect_icon do
        --     release_print(string.format("updateReelGridNode++++++  %d, %d", selfdata.collect_icon[i][1], selfdata.collect_icon[i][2]))
        --     print(string.format("updateReelGridNode++++++  %d, %d", selfdata.collect_icon[i][1], selfdata.collect_icon[i][2]))
        -- end
        -- print(string.format("updateReelGridNode %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,", 
        -- selfdata.collect_box[1],selfdata.collect_box[2],selfdata.collect_box[3],selfdata.collect_box[4],selfdata.collect_box[5],
        -- selfdata.collect_box[6],selfdata.collect_box[7],selfdata.collect_box[8],selfdata.collect_box[9],selfdata.collect_box[10]))
        
        local isCollect, collectNum = self:getCollectData(reelsIndex)
        -- print("updateReelGridNode",reelsIndex, isCollect, collectNum)
        if isCollect then -- 收集角标相关 绝对位置
            if node.m_Coin == nil then
                -- print("m_coin create")
                -- 填加收集金币
                node.m_Coin = util_createView("CodeHogHustlerSrc.HogHustlerReelsJiaoBiao", collectNum)
                node:addChild(node.m_Coin,2)
                node.m_Coin:setPosition(cc.p(77, -57))
            end
        end
    end

    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        local skin_str = self:getSymbolSkin(node.p_symbolType)
        self:setSlotsNodeSpineSkin(node, skin_str)
        node:runIdleAnim()


        self:setSpecialNodeScore(self,{node})
    end
end

function CodeGameScreenHogHustlerMachine:getCollectData(reelsIndex)
    local isCollect = false
    local collectNum = nil

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local coins = selfdata.collect_icon

    if coins and type(coins) == "table" then
        if table.nums(coins) ~= 0 then
            for k, v in pairs(coins) do
                local index = tonumber(v[1])
                if reelsIndex == index then
                    isCollect = true
                    collectNum = v[2]
                end
            end
        end
    end

    return isCollect, collectNum
end

function CodeGameScreenHogHustlerMachine:changeBg(showType)


    -- self:findChild("reel_base"):setVisible(showType == "base")
    self:findChild("reel_base"):setVisible(true)
    self:findChild("reel_free"):setVisible(showType == "free")
    -- self:findChild("Node_respinxian"):setVisible(showType == "respin")

    local aniStr = "bace"
    local spineY = 0
    if showType == "base" then
        aniStr = "bace"
    elseif showType == "free" then
        aniStr = "free"
    elseif showType == "respin" then
        aniStr = "respin"
        spineY = -10
    end


    
    util_spinePlay(self.m_gameBgSpine, aniStr, true)
    self.m_gameBgSpine:setPositionY(spineY)
    -- util_spineEndCallFunc(self.m_gameBgSpine, aniStr, function()

    -- end)


    self.m_collectBar:setVisible(showType == "base")
    self.m_freeBar:setVisible(showType == "free")
    self.m_respinSpinbar:setVisible(showType == "respin")
end

--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenHogHustlerMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

--延时
function CodeGameScreenHogHustlerMachine:waitWithDelay(time, endFunc, parent)
    time = time or 0
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

--isClick 是否是自己点击
function CodeGameScreenHogHustlerMachine:showMap(isClick)
    ---> globalMachineController:specialGameStart()
    self:clearCurMusicBg()
    self:setSpinTounchType(false)
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_trans_base2monopoly)
    self:baseOrMapChange("map", nil, function()
        self:removeSoundHandler() -- 移除监听
        self:resetMusicBg(nil,"HogHustlerSounds/music_HogHustler_monopoly_bg.mp3")
        

        if self.m_collectBar then
            self.m_collectBar:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        if self.m_lineSlotNodes then
            for index, node in ipairs(self.m_lineSlotNodes) do
                if node then
                    node:runIdleAnim()
                end
            end
        end
    end, isClick)
    util_playFadeOutAction(self.m_bottomUI,0.5, function()
        self.m_bottomUI:setVisible(false)
    end)
    if self.m_tips:isVisible() then
        self.m_tips:TipClick()
    end


    
end

function CodeGameScreenHogHustlerMachine:hideMap()
    local diceNum = self.m_map.m_diceNum
    self.m_collectBar:setDiceNum(diceNum)
    self.m_collectBar:reset()
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_trans_monopoly2base)
    self:baseOrMapChange("base", nil,function()
        self:resetMusicBg(true) 
        self:removeSoundHandler() -- 移除监听
        self:reelsDownDelaySetMusicBGVolume( ) 
        self.m_bottomUI:setVisible(true)
        self.m_map:resetBtnClickStates()
        self.m_collectBar:resetClick()
        util_playFadeInAction(self.m_bottomUI, 0.5)
        self:setSpinTounchType(true)
        if self.m_isHaseMapEffect then
            self:notifySelfGameEffectPlayComplete(self.GAME_MAP_EFFECT)
            self.m_isHaseMapEffect = false
        end
    end)
end

-- 更新控制类数据
function CodeGameScreenHogHustlerMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end

--isToClip 是否提层
function CodeGameScreenHogHustlerMachine:MachineRule_BackAction(slotParent, parentData, isToClip)
    local fix_Y = isToClip and slotParent:getPositionY() or 0
    local back = cc.MoveTo:create(self.m_configData.p_reelResTime, cc.p(slotParent:getPositionX(), fix_Y))
    return back, self.m_configData.p_reelResTime
end

function CodeGameScreenHogHustlerMachine:baseOrMapChange(changeType, callFun1, callFun2, isClick)
    self:runCsbAction("actionframe")
    if changeType == "base" then
        self.m_gameBg:findChild("SmellyRich_guochang_up5_85"):setVisible(false)
        self.m_gameBgSpine:setVisible(false)
    else
        self.m_gameBg:findChild("SmellyRich_guochang_up5_85"):setVisible(true)
    end
    self.m_gameBg:runCsbAction("switch", false, function()
        if changeType == "base" then
            self:changeBg("base")
        elseif isClick then
            self.m_map:resetState()
        end
        if callFun2 then
            callFun2()
        end

    end)
    self:waitWithDelay(90/60, function()
        if changeType == "base" then
            self.m_gameBg:findChild("SmellyRich_guochang_up5_85"):setVisible(true)
            self.m_gameBgSpine:setVisible(true)
        else
            self.m_gameBg:findChild("SmellyRich_guochang_up5_85"):setVisible(false)
            self.m_gameBgSpine:setVisible(false)
        end
    end)
    self:waitWithDelay(1.5, function()
        self.m_map:setVisible(changeType == "map")
        self:findChild("reel"):setVisible(changeType == "base")
        if callFun1 then
            callFun1()
        end
        if changeType == "map" then
            self.m_map:showDiceIdle()
            self.m_map:setClickType(isClick)
            self.m_map:initLevelPrizeNum()
        end
    end)
end

--中奖
function CodeGameScreenHogHustlerMachine:showWinningTipAni(callFunc)
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_prewinning)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
    for i=1,12 do
        -- self:findChild("Particle_"..i):resetSystem()
        -- self:findChild("Particle_"..i):setDuration(3)
    end

    self:waitWithDelay(83/30, function()
        self:runCsbAction("over", false, function()
            self:runCsbAction("idleframe", true)
        end)
        if callFunc then
            callFunc()
        end
    end)

    self.m_yugao:setVisible(true)
    util_spinePlay(self.m_yugao, "actionframe_yugao")
    util_spineEndCallFunc(self.m_yugao, "actionframe_yugao", function()
        -- if callFunc then
        --     callFunc()
        -- end
        self.m_yugao:setVisible(false)
    end)
end

function CodeGameScreenHogHustlerMachine:checkOperaSpinSuccess(param)
    -- 触发了玩法 一定概率播特效
    local spinData = param[2]
    if spinData.action == "SPIN" then
        local rand = math.random(1, 100)
        if param[2].result.features[2] == 1 and  self:getCurrSpinMode() ~= FREE_SPIN_MODE and rand < 40 then
            self.m_isShowWinAni = true
            self:showWinningTipAni(
                function()
                    CodeGameScreenHogHustlerMachine.super.checkOperaSpinSuccess(self, param)
                end
            )
        else
            CodeGameScreenHogHustlerMachine.super.checkOperaSpinSuccess(self, param)
        end
    end
end

function CodeGameScreenHogHustlerMachine:showFreeGuoChang(callFunc1,callFunc2,_isToFree)

    local timeline = "actionframe_guochang"
    if _isToFree then
        timeline = "actionframe_guochang"
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_trans_base2free)
    else
        timeline = "actionframe_guochang2"
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_trans_free2base)
    end

    self.m_mask:setVisible(true)
    self.m_mask:playAction("start", false, function()
        self.m_mask:playAction("idle", true)
    end)
    

    self.m_free_guochang:setVisible(true)
    util_spinePlay(self.m_free_guochang, timeline)
    -- util_spineFrameEvent(self.m_free_guochang, "guochang","bianfree",function ()
    --     if callFunc1 then
    --         callFunc1()
    --     end
    -- end)
    self:waitWithDelay(82/30, function()
        if callFunc1 then
            callFunc1()
        end
    end)

    self:waitWithDelay(110/30, function()
        if callFunc2 then
            callFunc2()
        end
    end)
    util_spineEndCallFunc(self.m_free_guochang, timeline, function()
        -- if callFunc2 then
        --     callFunc2()
        -- end
        self.m_free_guochang:setVisible(false)
    end)

    self:waitWithDelay((104 - 15)/30, function()
        self.m_mask:playAction("over", false, function()
            self.m_mask:setVisible(false)
        end)
    end)

    
end

function CodeGameScreenHogHustlerMachine:showRespinGuoChang(callFunc1,callFunc2)
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_trans_base2respin)

    self.m_mask:setVisible(true)
    self.m_mask:playAction("start", false, function()
        self.m_mask:playAction("idle", true)
    end)

    self.m_respin_guochang:setVisible(true)
    util_spinePlay(self.m_respin_guochang, "actionframe_guochang")


    self:waitWithDelay(100/30, function()
        if callFunc1 then
            callFunc1()
        end
    end)

    self:waitWithDelay(120/30, function()
        if callFunc2 then
            callFunc2()
        end
    end)
    util_spineEndCallFunc(self.m_respin_guochang, "actionframe_guochang", function()
        self.m_respin_guochang:setVisible(false)
    end)

    self:waitWithDelay((120 - 15)/30, function()
        self.m_mask:playAction("over", false, function()
            self.m_mask:setVisible(false)
        end)
    end)
end

--适配
-- function CodeGameScreenHogHustlerMachine:scaleMainLayer()
--     local uiW, uiH = self.m_topUI:getUISize()
--     local uiBW, uiBH = self.m_bottomUI:getUISize()

--     local mainHeight = display.height - uiH - uiBH
--     local mainPosY = (uiBH - uiH - 30) / 2
--     local mainPosX = 0
--     local winSize = display.size
--     local mainScale = 1

--     local hScale = mainHeight / self:getReelHeight()
--     local wScale = winSize.width / self:getReelWidth()

--     if display.width <= 1228 then
--         if display.width <= 960 then
--             wScale = winSize.width / 1270
--         else
--             wScale = winSize.width / 1250
--         end
--     end
--     if hScale < wScale then
--         mainScale = hScale
--     else
--         mainScale = wScale
--         self.m_isPadScale = true
--     end
--     -- if (display.width / display.height) == 1024/768 or
--     --    (display.width / display.height) == 1228/768 or
--     --    (display.width / display.height) == 960/640 then
--     --     local x = display.width / DESIGN_SIZE.width
--     --     local y = display.height / DESIGN_SIZE.height
--     --     local pro = x / y
--     --     if pro > 1 then
--     --         pro = 1
--     --     end
--     --     local activity_width = 125 * pro + 5 --活动的弹板的宽度
--     --     local show_width = display.width - activity_width
--     --     local design_reel_width = 1170  --设计分辨率下棋盘的宽度
--     --     local reel_scale = show_width / (design_reel_width * mainScale)
--     --     mainPosX = activity_width / 2
--     --     self:findChild("reel"):setScale(reel_scale)
--     --     self.m_reelScale = reel_scale
--     -- end
--     -- mainScale = 0.4
--     util_csbScale(self.m_machineNode, mainScale)
--     self.m_machineRootScale = mainScale
--     -- self.m_fixX = mainPosX
--     self.m_machineNode:setPositionY(mainPosY + 8)
--     self.m_machineNode:setPositionX(mainPosX)
-- end

function CodeGameScreenHogHustlerMachine:scaleMainLayer()
    CodeGameScreenHogHustlerMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.83
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.9 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.98 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio >= 768/1370 then
        local mainScale = 0.99 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1370 and ratio >= 768/1530 then
        local mainScale = 0.99 - 0.05*((ratio-768/1530)/(768/1370 - 768/1530))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1530 and ratio >= 768/1660 then
        local mainScale = 0.99 - 0.05*((ratio-768/1660)/(768/1530 - 768/1660))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenHogHustlerMachine:MachineRule_ResetReelRunData()
    for index, runInfo in pairs(self.m_reelRunInfo) do
        -- if self.m_isShowWinAni or (self.m_bProduceSlots_InFreeSpin and index == 5) then
        if self.m_isShowWinAni then
            runInfo.m_bReelLongRun = false
            runInfo.m_bNextReelLongRun = false
            -- if self.m_bProduceSlots_InFreeSpin and index == 5 then
                -- local lastRunLen = self.m_reelRunInfo[4].m_reelRunLen
                -- runInfo.m_reelRunLen = lastRunLen + runInfo.initInfo.reelRunLen
                
            -- else
                runInfo.m_reelRunLen = runInfo.initInfo.reelRunLen
            -- end
            
        end
    end


end

function CodeGameScreenHogHustlerMachine:showCollectTip()
    local diceNum = self.m_collectBar.m_diceNum
    self.m_collectBar_tip:setDiceNum(diceNum)
    self.m_collectBar_tip:showTip()
end

function CodeGameScreenHogHustlerMachine:showFirstMap()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local coin = selfdata.coin
    local addNum = selfdata.addNum
    self:showRichManStart(addNum, coin, true)
    self:waitWithDelay(1.5, function()
        self.m_collectBar_tip:resetClick()
        self.m_collectBar_tip:setVisible(false)
    end)
end

--显示mapStart弹板
function CodeGameScreenHogHustlerMachine:showMapStart(addNum, coin, isFirst)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_richMan_start_show.mp3")
    local csbName = "DafuwengStart2"
    if isFirst and coin > 0 then
        csbName = "DafuwengStart1"
    end
    local strCoins=util_formatCoins(coin,30)
    local ownerlist={}
    ownerlist["m_lb_num"] = addNum
    if isFirst and coin > 0  then
        ownerlist["m_lb_coins"] = strCoins
    end
    local callFunc = function()
        self.m_map:resetBtnClickStates()
        self.m_map:showStart()           
    end
    local view = self:showDialog(csbName,ownerlist, callFunc)
    if isFirst and coin > 0 then
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.35,sy=0.35},732)
    end

    local node=view:findChild("m_lb_num")
    view:updateLabelSize({label=node,sx=1,sy=1},241)

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_in_popupstart_start)
    view:setBtnClickFunc(function()
        if isFirst and coin > 0 then
            self.m_bottomUI:notifyTopWinCoin()
        end
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_in_popupstart_over)
    end)
end

function CodeGameScreenHogHustlerMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 and self.m_initFeatureData == nil then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    end

    if  self:getGameSpinStage() ~= IDLE and not self.m_isRunningEffect then
        return false
    end

    if  globalData.slotRunData.gameEffStage == GAME_START_REQUEST_STATE then
        return false
    end

    return true
end

--删除m_gameEffects中的Effect动画
function CodeGameScreenHogHustlerMachine:notifySelfGameEffectPlayComplete(effectType)
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectLen == 0 then
        self:playGameEffect() -- 继续播放动画
        return
    end

    for i=1,effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType ==  effectType and effectData.p_isPlay == false then

            effectData.p_isPlay = true
            self:playGameEffect() -- 继续播放动画
            return
        end
    end
    self:playGameEffect() -- 继续播放动画
end


--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenHogHustlerMachine:checkHasGameSelfEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i=1 ,effectLen , 1 do
        local value = self.m_gameEffects[i].p_selfEffectType or 0
        if value == effectType then
            return true
        end
    end

    return false
end

function CodeGameScreenHogHustlerMachine:initTips()
    -- self.m_tips = util_createAnimation("HogHustler_tishixinxi.csb")
    -- self:findChild("tishixinxi"):addChild(self.m_tips)
    -- self.m_tips:setVisible(true)
    -- self.m_tips:playAction("start")
    -- self.b_showTips = true
end


function CodeGameScreenHogHustlerMachine:removeTips()
    -- if  self.b_showTips == false then
    --     return
    -- end
    -- --gLobalSoundManager:playSound("")
    -- self.b_showTips = false
    -- if self.m_tips then
    --     self.m_tips:playAction("over",false, function()
    --         self.m_tips:setVisible(false)
    --     end, 60)
    -- end
end

function CodeGameScreenHogHustlerMachine:clickMapTipView()
    -- if self.m_tips:isVisible() then
    --     self:removeTips()
    -- else
    --     self:initTips()
    -- end
    self.m_tips:TipClick()
end

function CodeGameScreenHogHustlerMachine:setSpinTounchType(isTouch)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, isTouch})
end

function CodeGameScreenHogHustlerMachine:addEnterGameView()
    local enterView = util_createView("CodeHogHustlerSrc.HogHustlerEnterGameView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        enterView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(enterView)
end

--获取上ui的高度
function CodeGameScreenHogHustlerMachine:getTopUIHeight()
    local uiW, uiH = self.m_topUI:getUISize()
    return uiH
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenHogHustlerMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    -- local thresholdValue = self.m_bProduceSlots_InFreeSpin and 1 or 2
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum == 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum == 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

function CodeGameScreenHogHustlerMachine:initRandomSlotNodes()
    CodeGameScreenHogHustlerMachine.super.initRandomSlotNodes(self)

    self:firstInitToClip()
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线  
--TO:就该了一个点击音效
function CodeGameScreenHogHustlerMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("CodeHogHustlerSrc.HogHustlerDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    -- view.m_btnTouchSound = "HogHustlerSounds/sound_smellyRich_dialog_click.mp3"
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
    return view
end

function CodeGameScreenHogHustlerMachine:firstInitToClip()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:isFixSymbol(slotNode.p_symbolType) then
                    -- self:setSymbolToClip(slotNode)
                    self:setSymbolToClipParent(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        slotNode:runAnim("idleframe2", true)
                    elseif self:isFixSymbol(slotNode.p_symbolType) then
                        slotNode:runAnim("idleframe2", true)
                        self:bonusPlayScore(slotNode, "idleframe", true)
                    end
                end
            end
        end
    end
end

function CodeGameScreenHogHustlerMachine:initGameStatusData(gameData)
    if gameData.gameConfig and gameData.gameConfig.extra then
        local extra = gameData.gameConfig.extra
        local collect_box = extra.collect_box
        if collect_box then  --收集数据
            self.m_collectBar:setLetterNum(collect_box)
            self.m_collectBar:refreshLabel(true)
        end

        local diceNum = extra.diceNum  --骰子数量
        if diceNum and tonumber(diceNum) >= 0 then
            self.m_collectBar:setDiceNum(tonumber(diceNum))
        end

        local mapInfo = {}
        mapInfo.mapPropInfo = extra.map             --地图道具信息
        mapInfo.mapPos = extra.mapPos               --地图角色位置
        mapInfo.prize = extra.level_prize or 0      --地图角色位置
        mapInfo.diceNum = extra.diceNum or 0
        mapInfo.mapMul = extra.mapMul or {1, 1, 1}
        self.m_map:initMap(mapInfo)
    end
    CodeGameScreenHogHustlerMachine.super.initGameStatusData(self, gameData)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
]]
function CodeGameScreenHogHustlerMachine:setScatterDownScound()
    -- for i = 1, 6 do
    --     local soundPath = nil
    --     soundPath = "HogHustlerSounds/sound_smellyRich_scatterTrigger.mp3"
    --     self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    -- end
end

---
-- 显示free spin
function CodeGameScreenHogHustlerMachine:showEffect_FreeSpin(effectData)
    local winLines = self.m_reelResultLines or {}

    local freeSpinNext = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        


        self.m_ScatterShowCol = {1,2,3,4}
        -- 停掉背景音乐
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            --free
            self:clearCurMusicBg()
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end

            self.m_beginChangeFree5Col = false
            self.m_beginChangeFree5ColAnim = false
            self.m_disableSpinBtn = true

            self.m_beginFree = true
            -- self.m_col5Effect:setVisible(false)
            self.m_col5Effect_idle:setVisible(false)

            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_trigger)
        else
            --more
            -- self.m_col5Effect:setVisible(true)
            self.m_col5Effect_idle:setVisible(true)

            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_fs_trigger)
        end


        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        
        --触发动画
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self:setSymbolToClipParent(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 0)
                        node:runAnim("actionframe", false, function()
                            node:runAnim("idleframe2", true)
                        end)
                    end
                end
            end
        end

        self:waitWithDelay(70/30, function()
            self:showFreeSpinView(effectData)
        end)


        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    end
    if #winLines > 0 then
        -- self:waitWithDelay(2, function()
            freeSpinNext()
        -- end)
    else
        freeSpinNext()
    end
    

    
    return true
end

-- 显示paytableview 界面
function CodeGameScreenHogHustlerMachine:showPaytableView()
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
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function CodeGameScreenHogHustlerMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()
    self:lineLogicWinLines()
    -- 根据features 添加具体玩法
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end

function CodeGameScreenHogHustlerMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenHogHustlerMachine.super.getBounsScatterDataZorder(self, symbolType)
    if self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    return order
end

----------------------------------------RESPIN----------------------------------------
-- 继承底层respinView
function CodeGameScreenHogHustlerMachine:getRespinView()
    return "CodeHogHustlerSrc.HogHustlerRespinView"
end
-- 继承底层respinNode
function CodeGameScreenHogHustlerMachine:getRespinNode()
    return "CodeHogHustlerSrc.HogHustlerRespinNode"
end
-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenHogHustlerMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_BONUSWILD_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_BONUSWILD_MINOR then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR or symbolType == self.SYMBOL_FIX_BONUSWILD_MAJOR then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_GRAND or symbolType == self.SYMBOL_FIX_BONUSWILD_GRAND then
        score = "GRAND"
    end

    return score
end
function CodeGameScreenHogHustlerMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if self:isFixSymbol(symbolType) then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end


    return score
end
-- 给respin小块进行赋值
function CodeGameScreenHogHustlerMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not symbolNode.p_symbolType then
        return
    end
    if not self:isScoreFixSymbol(symbolNode.p_symbolType) then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            -- if symbolNode:getCcbProperty("m_lb_coins") then
            --     symbolNode:getCcbProperty("m_lb_coins"):setString(score)
            -- end
            self:bonusShowScore(symbolNode, score)
        end

        symbolNode:runAnim("idleframe")

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                -- if symbolNode:getCcbProperty("m_lb_coins") then
                --     symbolNode:getCcbProperty("m_lb_coins"):setString(score)
                -- end
                self:bonusShowScore(symbolNode, score)
                
                symbolNode:runAnim("idleframe")
            end
        end
        
        
    end

end

--显示bonus分数node
function CodeGameScreenHogHustlerMachine:bonusShowScore(_symbolNode, _scoreStr)
    if _symbolNode then
        
        -- if not _symbolNode.m_scoreViewNode then
        --     _symbolNode.m_scoreViewNode = util_createAnimation("HogHustler_jinsuanshuzi.csb")
        --     _symbolNode:addChild(_symbolNode.m_scoreViewNode, 10)
        --     -- _symbolNode.m_scoreViewNode:setPositionY(-40)
        --     -- _symbolNode.m_scoreViewNode:setName("bonusScoreNode")
        -- end
        -- if tolua.isnull(_symbolNode.m_scoreViewNode) then
        --     release_print("CodeGameScreenHogHustlerMachine:bonusShowScore null 33 Error!!!")
        -- else
        --     _symbolNode.m_scoreViewNode:setVisible(true)
        --     _symbolNode.m_scoreViewNode:findChild("m_lb_coins"):setString(_scoreStr)
        -- end


        local aniNode = _symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        if spine then
            if not spine.m_scoreViewNode then
                local label = util_createAnimation("Socre_HogHustler_Bonus_Num.csb")
                spine:addChild(label, 10)
                spine.m_scoreViewNode = label
            end
            spine.m_scoreViewNode:setVisible(true)
            spine.m_scoreViewNode:findChild("m_lb_coins"):setString(_scoreStr)
        end

    end
end
--隐藏bonus分数node
function CodeGameScreenHogHustlerMachine:bonusHideScore(_symbolNode)
    if _symbolNode then    
        local aniNode = _symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode  
        if spine and spine.m_scoreViewNode then
            -- if tolua.isnull(_symbolNode.m_scoreViewNode) then
            --     release_print("CodeGameScreenHogHustlerMachine:bonusHideScore null 44 Error!!!")
            -- else
            --     -- _symbolNode.m_scoreViewNode:setVisible(false)
            --     _symbolNode.m_scoreViewNode:removeFromParent()
            --     _symbolNode.m_scoreViewNode = nil
            -- end

            spine.m_scoreViewNode:setVisible(false)
        end
    end
end
--动画bonus分数node
function CodeGameScreenHogHustlerMachine:bonusPlayScore(_symbolNode, _animName, _loop, _func)
    if _symbolNode and not tolua.isnull(_symbolNode) then
        local aniNode = _symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        -- if _symbolNode.m_scoreViewNode then
        --     if tolua.isnull(_symbolNode.m_scoreViewNode) then
        --         release_print("CodeGameScreenHogHustlerMachine:bonusPlayScore null 11 Error!!!")
        --     else
        --         if _loop then
        --             _symbolNode.m_scoreViewNode:runCsbAction(_animName, _loop)
        --         else
        --             if tolua.isnull(_symbolNode.m_scoreViewNode.m_csbAct) then
        --                 release_print("CodeGameScreenHogHustlerMachine:bonusPlayScore null 22 Error!!!")
        --             else
        --                 _symbolNode.m_scoreViewNode:runCsbAction(_animName, _loop, function (  )
        --                     if _func then
        --                         _func()
        --                     end
        --                 end)
        --             end
                    
        --         end
        --     end
            
        -- end

        if spine and spine.m_scoreViewNode then
            if tolua.isnull(spine.m_scoreViewNode) then
                release_print("CodeGameScreenHogHustlerMachine:bonusPlayScore null 11 Error!!!")
            else
                if _loop then
                    spine.m_scoreViewNode:runCsbAction(_animName, _loop)
                else
                    if tolua.isnull(spine.m_scoreViewNode.m_csbAct) then
                        release_print("CodeGameScreenHogHustlerMachine:bonusPlayScore null 22 Error!!!")
                    else
                        spine.m_scoreViewNode:runCsbAction(_animName, _loop, function (  )
                            if _func then
                                _func()
                            end
                        end)
                    end
                    
                end
            end
            
        end
    end
end

function CodeGameScreenHogHustlerMachine:showRespinJackpot(index,coins,func,funcClick)
    
    local jackPotWinView = util_createView("CodeHogHustlerSrc.HogHustlerJackPotWinView", self)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func,funcClick)
end
-- 结束respin收集
function CodeGameScreenHogHustlerMachine:playLightEffectEnd()
    
    self.m_respinView:playRespinOverAnim()
    -- 通知respin结束
    self:respinOver()
 
end

function CodeGameScreenHogHustlerMachine:respinOver()
    -- self:setReelSlotsNodeVisible(true)

    -- -- 更新游戏内每日任务进度条 -- r
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    -- self:removeRespinNode()


    self:showRespinOverView()
end

function CodeGameScreenHogHustlerMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        self:waitWithDelay(25/60, function()    --延迟25  score变黑
            self:playLightEffectEnd()
        end)
        
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 
    local posIdx = self:getPosReelIdx(iRow ,iCol)
    -- 根据网络数据获得当前固定小块的分数
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self:getJackpotValue(posIdx) or self:BaseMania_getJackpotScore(1)
            addScore = jackpotScore + addScore
            nJackpotType = 4
        elseif score == "MAJOR" then
            jackpotScore = self:getJackpotValue(posIdx) or self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINOR" then
            jackpotScore =  self:getJackpotValue(posIdx) or self:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                  ---self:BaseMania_getJackpotScore(3)
            nJackpotType = 2
        elseif score == "MINI" then
            jackpotScore = self:getJackpotValue(posIdx) or self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                      ---self:BaseMania_getJackpotScore(4)
            nJackpotType = 1
        end
    end

    -- util_printLog("add 1score++++++  ")
    -- util_printLog(addScore)
    self.m_lightScore = self.m_lightScore + addScore
    -- util_printLog("total 1all score++++++  ")
    -- util_printLog(self.m_lightScore)
    

    local function runCollect()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else
            self:showRespinJackpot(nJackpotType, jackpotScore, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end, function()
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_lightScore, false, false})
                globalData.slotRunData.lastWinCoin = lastWinCoin
                self:playCoinWinEffectUI()
            end)
          
        end
    end
    

    local runCollectAnim = function()
        
        chipNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self:getPosReelIdx(chipNode.p_rowIndex, chipNode.p_cloumnIndex) + 100)
        local time = 0.5
        if self:isScoreFixSymbol(chipNode.p_symbolType) then
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_bonus_collect2allwinstart)
            chipNode:runAnim("shouji", false, function()
                chipNode:runAnim("darkstart", false, function()
                    chipNode:runAnim("darkidle", true)
                end)
                chipNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self:getPosReelIdx(chipNode.p_rowIndex, chipNode.p_cloumnIndex))
            end)
            self:bonusPlayScore(chipNode, "shouji", false, function()
                -- self:bonusPlayScore(chipNode, "idleframe", true)
                self:bonusPlayScore(chipNode, "darkstart", false, function()
                    self:bonusPlayScore(chipNode, "darkidle", true)
                end)
            end)

            
        else
            -- local anim = "actionframe"
            -- if self:isFixSymbolBonus1(chipNode.p_symbolType) then
            --     anim = "actionframe"
            -- else
            --     anim = "actionframe"
            -- end
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_bonusjackpot_collect2allwinstart)
            chipNode:runAnim("actionframe2", false, function()
                chipNode:runAnim("darkstart", false, function()
                    chipNode:runAnim("darkidle", true)
                end)
                chipNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self:getPosReelIdx(chipNode.p_rowIndex, chipNode.p_cloumnIndex))
                self.m_jackpotBar:hideEffectLight(nJackpotType)
            end)
            time = 2 - 18/60
            self:shakeOneNodeForeverRootNode(time)


            self.m_jackpotBar:showEffectLight(nJackpotType)
        end
        
        local winLabelUpdate = function()
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_lightScore, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin
            self:playCoinWinEffectUI()
        end
        
        if self:isScoreFixSymbol(chipNode.p_symbolType) then
            self:createParticleFly(0.5,chipNode,function (  )
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_bonus_collect2allwinend)
                winLabelUpdate()
            end)
        else
            -- winLabelUpdate()
        end
        

        

        self:waitWithDelay(time, function()
            runCollect()
        end)
    end
    
    -- runCollect()

    runCollectAnim()
end



-- function CodeGameScreenHogHustlerMachine:runRespinCollectFlyAct(startNode,endNode,csbName,func,endAddY)

--     -- 创建粒子
--     local flyNode =  util_createAnimation( csbName ..".csb")
--     self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

--     local startPos = util_getConvertNodePos(startNode,flyNode)

--     flyNode:setPosition(cc.p(startPos))

--     local endPos = cc.p(util_getConvertNodePos(endNode,flyNode))
--     if endAddY then
--         endPos = cc.p(endPos.x,endPos.y + endAddY)
--     end

--     local angle = self:getAngleByPos(startPos,endPos)
--     flyNode:findChild("Node_1"):setRotation( - angle)

--     local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
--     flyNode:findChild("Node_1"):setScaleX(scaleSize / 342)

--     flyNode:runCsbAction("actionframe",false,function(  )

--             if func then
--                 func()
--             end

--             flyNode:stopAllActions()
--             flyNode:removeFromParent()
--     end)

--     return flyNode

-- end

-- 创建飞行粒子
function CodeGameScreenHogHustlerMachine:createParticleFly(time,currNode,func)

    local fly = util_createAnimation("Socre_HogHustler_Bonus_lizi.csb")
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    fly:setPosition(cc.p(util_getConvertNodePos(currNode, fly)))
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local startPos = cc.p(fly:getPosition())
    local endPos = util_convertToNodeSpace(endNode,self)
    -- local centerPos = cc.p((endPos.x + startPos.x) / 2, (endPos.y + startPos.y) / 2)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        fly:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        fly:findChild("Particle_1"):resetSystem()
    end)
    -- local dir = col <= 3
    -- local bezier = self:getBezier(startPos, endPos, dir)
    -- animation[#animation + 1] = cc.EaseIn:create(cc.BezierTo:create(time, bezier), 2)
    animation[#animation + 1] = cc.EaseIn:create(cc.MoveTo:create(time, endPos), 1)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        -- fly:findChild("Particle_1_0"):stopSystem()--移动结束后将拖尾停掉

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



--结束移除小块调用结算特效
function CodeGameScreenHogHustlerMachine:reSpinEndAction()  
    
    --延迟个落地时间
    self:waitWithDelay(30/60, function()

        self.m_respinSpinbar:changeRespinTimes(0)

        -- 播放收集动画效果
        self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
        self.m_playAnimIndex = 1

        -- self:clearCurMusicBg()
        
        -- 获得所有固定的respinBonus小块
        self.m_chipList = self.m_respinView:getAllCleaningNode()    


        --结束播放一次触发动画
        for i=1, #self.m_chipList do
            local chipNode = self.m_chipList[i]
            local anim = "actionframe"
            if self:isFixSymbolBonus1(chipNode.p_symbolType) then
                anim = "actionframe"
            else
                anim = "actionframe3"
            end
            if self:isScoreFixSymbol(chipNode.p_symbolType) then
                
                chipNode:runAnim(anim, false, function()
                    chipNode:runAnim("idleframe2", true)
                end)
                self:bonusPlayScore(chipNode, "actionframe3", false, function()
                    self:bonusPlayScore(chipNode, "idleframe", true)
                end)
            else
                chipNode:runAnim(anim, false, function()
                    chipNode:runAnim("idleframe2", true)
                end)
            end
        end
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_over_trigger)

        -- self:waitWithDelay(60/30, function()
            if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)  then

                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_collect_golbaleffect)
                --中grand
                self.m_spineBigWin:setVisible(true)
                local animName = "actionframe_bigwin3"
                util_spinePlay(self.m_spineBigWin, animName, false)
                local spineEndCallFunc = function()
                    self.m_spineBigWin:setVisible(false)
                end
                util_spineEndCallFunc(self.m_spineBigWin, animName, spineEndCallFunc)
        
                
                self.m_HogHustler_binwin2:setVisible(true)
                self.m_HogHustler_binwin3:setVisible(true)
                self.m_HogHustler_binwin4:setVisible(true)
                local anim234Name = "actionframe_bigwin3"
                util_spinePlay(self.m_HogHustler_binwin2, anim234Name, false)
                local spineEndCallFunc = function()
                    self.m_HogHustler_binwin2:setVisible(false)
                end
                util_spineEndCallFunc(self.m_HogHustler_binwin2, anim234Name, spineEndCallFunc)

                util_spinePlay(self.m_HogHustler_binwin3, anim234Name, false)
                local spineEndCallFunc = function()
                    self.m_HogHustler_binwin3:setVisible(false)
                end
                util_spineEndCallFunc(self.m_HogHustler_binwin3, anim234Name, spineEndCallFunc)

                util_spinePlay(self.m_HogHustler_binwin4, anim234Name, false)
                local spineEndCallFunc = function()
                    self.m_HogHustler_binwin4:setVisible(false)
                end
                util_spineEndCallFunc(self.m_HogHustler_binwin4, anim234Name, spineEndCallFunc)
        
                self:waitWithDelay(61/30, function()
                    self.m_jackpotBar:hideEffectLight(4)

                    -- 如果全部都固定了，会中JackPot档位中的Grand
                    local jackpotScore = self:BaseMania_getJackpotScore(1)
                    -- util_printLog("add 1score++++++  ")
                    -- util_printLog(jackpotScore)

                    self.m_lightScore = self.m_lightScore + jackpotScore
                    -- util_printLog("total 1all score++++++  ")
                    -- util_printLog(self.m_lightScore)
        
                    local lastWinCoin = globalData.slotRunData.lastWinCoin
                    globalData.slotRunData.lastWinCoin = 0
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_lightScore, false, false})
                    globalData.slotRunData.lastWinCoin = lastWinCoin
                    self:playCoinWinEffectUI()
        
                    self:showRespinJackpot(
                        4,
                        jackpotScore,
                        function()
                            
                            self:playChipCollectAnim()
                        end
                    )
                end)
                self:shakeOneNodeForever(60/30)

                self.m_jackpotBar:showEffectLight(4)
            else
                self:waitWithDelay(61/30, function()
                    self:playChipCollectAnim()
                end)
                
            end
        -- end)

    end)

    

end

-- 根据本关卡实际小块数量填写
function CodeGameScreenHogHustlerMachine:getRespinRandomTypes( )
    -- local symbolList = { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
    --     TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
    --     self.SYMBOL_FIX_SYMBOL_BONUS}

        local symbolList = {
        self.SYMBOL_FIX_BLANK,
        self.SYMBOL_FIX_SYMBOL_BONUS}


    return symbolList
end

-- 是不是 respinBonus小块
function CodeGameScreenHogHustlerMachine:isFixSymbol(symbolType)
    if  symbolType == self.SYMBOL_FIX_SYMBOL_BONUS or 
        symbolType == self.SYMBOL_FIX_SYMBOL_BONUSWILD or
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_GRAND or
        symbolType == self.SYMBOL_FIX_BONUSWILD_MINI or 
        symbolType == self.SYMBOL_FIX_BONUSWILD_MINOR or 
        symbolType == self.SYMBOL_FIX_BONUSWILD_MAJOR or 
        symbolType == self.SYMBOL_FIX_BONUSWILD_GRAND then
        return true
    end
    return false
end

function CodeGameScreenHogHustlerMachine:isFixSymbolBonus1(symbolType)
    if  symbolType == self.SYMBOL_FIX_SYMBOL_BONUS or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end

function CodeGameScreenHogHustlerMachine:isScoreFixSymbol(symbolType)
    if  symbolType == self.SYMBOL_FIX_SYMBOL_BONUS or 
        symbolType == self.SYMBOL_FIX_SYMBOL_BONUSWILD then
        return true
    end
    return false
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenHogHustlerMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_SYMBOL_BONUSWILD, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_BONUSWILD_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_BONUSWILD_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_BONUSWILD_MAJOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_BONUSWILD_GRAND, runEndAnimaName = "buling", bRandom = true},
        
    }

    return symbolList
end

function CodeGameScreenHogHustlerMachine:showRespinView()

          --先播放动画 再进入respin
        self:clearCurMusicBg()

        self.m_bottomUI:checkClearWinLabel()
      

        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )

        --可随机的特殊信号 
        local endTypes = self:getRespinLockTypes()
        

        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_trigger)
        --触发动画
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    if self:isFixSymbol(node.p_symbolType) then
                        self:setSymbolToClipParent(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 1000)
                        if self:isFixSymbolBonus1(node.p_symbolType) then
                            node:runAnim("actionframe", false)
                        else
                            node:runAnim("actionframe3", false)
                        end
                        
                        self:bonusPlayScore(node, "actionframe3", false)
                    end
                end
            end
        end
    
        self:waitWithDelay(60/30, function ()
            self:showReSpinStart(function() 
                self:showRespinGuoChang(function (  )

                    self:setSymbolToClipReel() --降层

                    --构造盘面数据
                    self:triggerReSpinCallFun(endTypes, randomTypes)

                    self:changeBg("respin")


                    -- if self.m_col5Effect:isVisible() then
                    --     self.m_col5Effect:setVisible(false)
                    -- end
                    if self.m_col5Effect_idle:isVisible() then
                        self.m_col5Effect_idle:setVisible(false)
                    end
                end, function (  )
                    


                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:runNextReSpinReel()

                end)
            end)
        end)

end

function CodeGameScreenHogHustlerMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_popupstart_start)
    
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_NOMAL)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)

    -- local curNum = self.m_runSpinResultData.p_reSpinCurCount or 3
    -- view:findChild("m_lb_num"):setString(tostring(curNum))

    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_popupstart_over)
    end)
end

function CodeGameScreenHogHustlerMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            -- self:showReSpinStart(
                -- function()
                    -- self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- -- 更改respin 状态下的背景音乐
                    -- self:changeReSpinBgMusic()
                    -- self:runNextReSpinReel()
                -- end
            -- )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function CodeGameScreenHogHustlerMachine:changeReSpinStartUI(respinCount)
    self.m_respinSpinbar:changeRespinTimes(respinCount,true)
    if not self.m_respinSpinbar:isVisible() then
        self.m_respinSpinbar:runCsbAction("start")
        self.m_respinSpinbar:setVisible(true)
    end
end

--ReSpin刷新数量
function CodeGameScreenHogHustlerMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
   
    self.m_respinSpinbar:changeRespinTimes(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenHogHustlerMachine:changeReSpinOverUI()

end

function CodeGameScreenHogHustlerMachine:showRespinOverView(effectData)
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_popupover_start)

    local strCoins=util_formatCoins(self.m_serverWinCoins,30)
    local view=self:showReSpinOver(strCoins,function()

        self:showRespinGuoChang(function (  )

            --respinOver逻辑---------
            self:setReelSlotsNodeVisible(true)
            -- 更新游戏内每日任务进度条 -- r
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
            self:removeRespinNode()
            --respinOver逻辑---------

            -- self.m_respinSpinbar:runCsbAction("over",false,function(  )
                self.m_respinSpinbar:setVisible(false)
            -- end)
            
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            -- self:resetMusicBg() 


            if self.m_bProduceSlots_InFreeSpin then
                self:changeBg("free")
                -- self.m_col5Effect:setVisible(true)
                self.m_col5Effect_idle:setVisible(true)
            else
                self:changeBg("base")
            end
            
        end, function (  )
            self:playGameEffect()
        end)

        

        
    end)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_popupover_over)
    end)

    -- gLobalSoundManager:playSound("levelsTempleSounds/music_levelsTemple_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},732)

    view:findChild("root"):setScale(self.m_machineRootScale)
    
    self:addPopupCommonRole(view, nil, nil, "start_tanban2", "idle_tanban2")
end


--重写
function CodeGameScreenHogHustlerMachine:triggerReSpinOverCallFun(score)
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
    self:resetReSpinMode()
    -- self:playGameEffect() --改
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    if self:isHaveBigWin() then --改 respin返回时 有大赢不播背景音
        self:setMinMusicBGVolume()
    end
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--重写
--结束移除小块调用结算特效
function CodeGameScreenHogHustlerMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        local endAnimaName, loop = node:getSlotsNodeAnima()
        if self:isFixSymbol(node.p_symbolType) then -- 改 不改原有进入时小块
            --respin结束 移除respin小块对应位置滚轴中的小块
            self:checkRemoveReelNode(node)
            --respin结束 把respin小块放回对应滚轴位置
            self:checkChangeRespinFixNode(node)
        else
            self:checkRemoveReelNodeCoin(node)
        end
        
        --播放respin放回滚轴后播放的提示动画
        self:checkRespinChangeOverTip(node)
    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end

--移除角标  respin回后
function CodeGameScreenHogHustlerMachine:checkRemoveReelNodeCoin(node)
    local targSp = self:getReelParent(node.p_cloumnIndex):getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    local slotParentBig = self:getReelBigParent(node.p_cloumnIndex)
    if targSp == nil and slotParentBig then
        targSp = slotParentBig:getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    end
    if targSp then
        if targSp.m_Coin then
            targSp.m_Coin:stopAllActions()
            targSp.m_Coin:removeFromParent()
            targSp.m_Coin = nil
        end
    end
end


-- --重写组织respinData信息
function CodeGameScreenHogHustlerMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

--重写
--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenHogHustlerMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
    node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
end

--重写  改变初始小块类型
----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenHogHustlerMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            --改
            if not self:isFixSymbol(symbolType) then
                symbolType = self.SYMBOL_FIX_BLANK
            end
            --改

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end
----------------------------------------RESPIN----------------------------------------


--重写
function CodeGameScreenHogHustlerMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self.m_clipParent:addChild(reelEffectNode, -1)
        reelEffectNode:setTag(SYMBOL_NODE_TAG + 100) --改 respin退出时会显示出来
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        if reelType == "ccui.Layout" then
            reelEffectNode:setLocalZOrder(0)
        end
        reelEffectNode:setPosition(cc.p(reel:getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end
end

function CodeGameScreenHogHustlerMachine:showBigWinEffect(effectData)
    local animName = "actionframe_bigwin2"
    -- if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
    --     animName = "actionframe_bigwin2"
    -- else
    --     animName = "actionframe_bigwin"
    -- end

    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_bigwin_globaleffect)

    self.m_spineBigWin:setVisible(true)
    
    util_spinePlay(self.m_spineBigWin, animName, false)
    local spineEndCallFunc = function()
        self.m_spineBigWin:setVisible(false)
    end
    util_spineEndCallFunc(self.m_spineBigWin, animName, spineEndCallFunc)


    -- self.m_HogHustler_binwin2:setVisible(true)
    -- self.m_HogHustler_binwin3:setVisible(true)
    -- self.m_HogHustler_binwin4:setVisible(true)
    -- local anim234Name = "actionframe_bigwin3"
    -- util_spinePlay(self.m_HogHustler_binwin2, anim234Name, false)
    -- local spineEndCallFunc = function()
    --     self.m_HogHustler_binwin2:setVisible(false)
    -- end
    -- util_spineEndCallFunc(self.m_HogHustler_binwin2, anim234Name, spineEndCallFunc)

    -- util_spinePlay(self.m_HogHustler_binwin3, anim234Name, false)
    -- local spineEndCallFunc = function()
    --     self.m_HogHustler_binwin3:setVisible(false)
    -- end
    -- util_spineEndCallFunc(self.m_HogHustler_binwin3, anim234Name, spineEndCallFunc)

    -- util_spinePlay(self.m_HogHustler_binwin4, anim234Name, false)
    -- local spineEndCallFunc = function()
    --     self.m_HogHustler_binwin4:setVisible(false)
    -- end
    -- util_spineEndCallFunc(self.m_HogHustler_binwin4, anim234Name, spineEndCallFunc)
    


    self:shakeOneNodeForever(60/30)
    self:waitWithDelay(60/30, function()

        effectData.p_isPlay = true
        self:playGameEffect()

    end)

end


function CodeGameScreenHogHustlerMachine:isHaveBigWin()
    local ret = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        ret = true
    end
    return ret
end

--重写
function CodeGameScreenHogHustlerMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = CodeGameScreenHogHustlerMachine.super.setReelLongRun(self, reelCol)
    
    -- if not self.m_isLongRun and isTriggerLongRun then
    --     --scatter播期待动画
    --     for iCol = 1,reelCol do
    --         for iRow = 1,self.m_iReelRowNum do
    --             local symbol = self:getFixSymbol(iCol,iRow)
    --             if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --                 symbol:runAnim("idleframe3", true)
    --             end
    --         end
    --     end

    --     self.m_isLongRun = isTriggerLongRun
    -- end

    return isTriggerLongRun
end

--重写
-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenHogHustlerMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isLongRun then
            _slotNode:runAnim("idleframe3", true)
        else
            _slotNode:runAnim("idleframe2", true)
        end
    end

    if self:isFixSymbol(_slotNode.p_symbolType) then
        _slotNode:runAnim("idleframe2", true)
        self:bonusPlayScore(_slotNode, "idleframe", true)
    end
end

--重写
--播放提示动画
function CodeGameScreenHogHustlerMachine:playReelDownTipNode(slotNode)

    -- self:playScatterBonusSound(slotNode)
    -- slotNode:runAnim("buling")
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenHogHustlerMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif self:isFixSymbol(_slotNode.p_symbolType) then
                if self:checkSymbolBonusBulingSoundPlay(_slotNode) then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

--bonus是否buling
function CodeGameScreenHogHustlerMachine:checkSymbolBonusBulingSoundPlay(_slotNode)
    if not _slotNode then
        return false
    end
    if _slotNode.p_cloumnIndex < 4 then
        return true
    else
        local lastCol = _slotNode.p_cloumnIndex
        local bonusCount = 0
        local isPlay = false
        for i=1, lastCol do
            for j = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(i, j, SYMBOL_NODE_TAG)
                if targSp and self:isFixSymbol(targSp.p_symbolType)  then
                    bonusCount = bonusCount + 1
                end
            end
        end
        if _slotNode.p_cloumnIndex == 4 and bonusCount >= 3 then
            isPlay = true
        elseif _slotNode.p_cloumnIndex == 5 and bonusCount >= 6 then
            isPlay = true
        end
        return isPlay
    end
    return false
end

function CodeGameScreenHogHustlerMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                    -- util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    self:setSymbolToClipParent(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
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
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )

                if self:isFixSymbol(_slotNode.p_symbolType) then
                    self:bonusPlayScore(_slotNode, "buling", false)
                end
                
            end
        end
    end
end

--提层
function CodeGameScreenHogHustlerMachine:setSymbolToClipParent(_MainClass, _iCol, _iRow, _type, _zorder)
    local targSp = _MainClass:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = _MainClass:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(_MainClass, index)
        local showOrder = _MainClass:getBounsScatterDataZorder(_type) - _iRow
        local nodeParent = targSp:getParent()
        targSp.p_preParent = nodeParent
        targSp.p_preX = targSp:getPositionX()
        targSp.p_preY = targSp:getPositionY()

        targSp.m_showOrder = showOrder
        targSp.p_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent(false)
        _MainClass.m_clipParent:addChild(targSp, _zorder + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

--降层
function CodeGameScreenHogHustlerMachine:setSymbolToClipReel()

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local _slotNode = self:getFixSymbol(iCol,iRow)
            if _slotNode then
                local preParent = _slotNode.p_preParent
                if preParent ~= nil then
                    util_changeNodeParent(preParent, _slotNode, _slotNode.p_showOrder)
                    _slotNode:setPosition(_slotNode.p_preX, _slotNode.p_preY)
                    _slotNode:setTag(_slotNode.p_cloumnIndex * SYMBOL_NODE_TAG + _slotNode.p_rowIndex)
                    -- self:changeBaseParent(_slotNode)
                    _slotNode:runIdleAnim()
                end
            end
        end
    end
end

--重写
function CodeGameScreenHogHustlerMachine:getClipParentChildShowOrder(slotNode)
    return self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex
    -- return REEL_SYMBOL_ORDER.REEL_ORDER_3
end

--重写 用于free第五列动态改数据
function CodeGameScreenHogHustlerMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)

    parentData.symbolType = symbolType
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local cloumnIndex = parentData.cloumnIndex
        if cloumnIndex == 5 and self.m_beginChangeFree5Col == false and self.m_beginFree then
            parentData.symbolType = self:getRandomSymbolType() --未开始时用随机的symbol了
        end
    end

end

function CodeGameScreenHogHustlerMachine:createSlotNextNode(parentData)
    if self.m_isWaitingNetworkData == false and self:getCurrSpinMode() == FREE_SPIN_MODE then
        local cloumnIndex = parentData.cloumnIndex
        if cloumnIndex == 5 and self.m_beginChangeFree5Col == false and self.m_beginFree then
            self.m_freeCreate5ColCount = self.m_freeCreate5ColCount + 1 --网络回后创建数
            if self.m_freeCreate5ColCount >= 1 and self.m_beginChangeFree5ColAnim == false then
                self:changeFreeCol5()
                self.m_beginChangeFree5ColAnim = true
            end
            if self.m_freeCreate5ColCount >= 1 + 9 then
                self.m_beginChangeFree5Col = true
                self.m_beginFree = false
            end
        end
    end

    CodeGameScreenHogHustlerMachine.super.createSlotNextNode(self, parentData)
    
end

function CodeGameScreenHogHustlerMachine:changeFreeCol5()
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_free_col5change)
    self.m_col5Effect:playAction("switch", false, function()
        self.m_disableSpinBtn = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
        -- self.m_col5Effect:playAction("idle", true)
        self.m_col5Effect:setVisible(false)
    end)
    self.m_col5Effect:setVisible(true)
    self.m_col5Effect_idle:setVisible(true)
    self.m_col5Effect_idle:playAction("switch", false, function()
        self.m_col5Effect_idle:playAction("idle", true)
    end)
end

--重写
function CodeGameScreenHogHustlerMachine:dealSmallReelsSpinStates()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_disableSpinBtn == false then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
end


-- shake
function CodeGameScreenHogHustlerMachine:shakeOneNodeForever(time)
    local oldPos = cc.p(self:findChild("Node_ui"):getPosition())
    local changePosY = math.random( 1, 5)
    local changePosX = math.random( 1, 5)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    self:findChild("Node_ui"):runAction(action)

    performWithDelay(self,function()
        self:findChild("Node_ui"):stopAction(action)
        self:findChild("Node_ui"):setPosition(oldPos)
    end,time)
end

-- shake
function CodeGameScreenHogHustlerMachine:shakeOneNodeForeverRootNode(time)
    
    self.m_gobalTouchLayer:setTouchEnabled(true)
    self.m_gobalTouchLayer:setSwallowTouches(true)

    local time2 = 0.07
    local time1 = math.max(0, time - time2)

    local root_shake = self
    local root_scale = self:getParent()

    local oldPos = cc.p(root_shake:getPosition())
    local oldRootPos = cc.p(root_scale:getPosition())
    local oldScale = root_scale:getScale()
    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    root_shake:runAction(action)

    local action1 = cc.ScaleTo:create(time1, 1.15)
    root_scale:runAction(action1)

    performWithDelay(self,function()
        root_shake:stopAction(action)
        root_scale:stopAction(action1)
        root_shake:setPosition(oldPos)
        root_scale:setPosition(oldRootPos)
        
        local actionOver = cc.ScaleTo:create(time2, oldScale)
        root_scale:runAction(actionOver)
        performWithDelay(self,function()
            root_scale:stopAction(actionOver)
            root_scale:setScale(oldScale)
            if self.m_gobalTouchLayer then
                self.m_gobalTouchLayer:setTouchEnabled(false)
                self.m_gobalTouchLayer:setSwallowTouches(false)
            end
            
        end, time2)
    end, time1)
end

--重写
--小块
function CodeGameScreenHogHustlerMachine:getBaseReelGridNode()
    return "CodeHogHustlerSrc.HogHustlerSlotNode"
end

-- --重写   播放totalwin
-- function CodeGameScreenHogHustlerMachine:playCoinWinEffectUI(callBack)
--     if self.m_bottomUI ~= nil then
--         self.m_bottomUI:playCoinWinEffectUI(callBack)

--         --改
--         --totalwin 特效
--         local totalWinEffect = util_spineCreate("HogHustler_binwin2", true, true)
--         self.m_rootEffectNode:addChild(totalWinEffect, 1)
--         local endNode = self.m_bottomUI:findChild("font_last_win_value")
--         local totalWinpos = util_convertToNodeSpace(endNode, self.m_rootEffectNode)
--         totalWinEffect:setPosition(cc.p(totalWinpos))


--         util_spinePlay(totalWinEffect, "baodian", false)
--         local spineEndCallFunc = function()
--             totalWinEffect:setVisible(false)
--         end
--         util_spineEndCallFunc(totalWinEffect, "baodian", spineEndCallFunc)

--         self:waitWithDelay(2, function()
--             if totalWinEffect and not tolua.isnull(totalWinEffect) then
--                 totalWinEffect:removeFromParent()
--             end
--         end)
--     end
-- end

function CodeGameScreenHogHustlerMachine:getSpecialBets()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    local a = 1
end

--重写
--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenHogHustlerMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            --改
            if self:isFixSymbol(_slotNode.p_symbolType) then    --公用同一声音
                symbolType = 94
            end
            --改
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                end
            end
        end
    end
end

--重写 每轮停轮声音
function CodeGameScreenHogHustlerMachine:playReelDownSound(_iCol, _path)
    if self:checkIsPlayReelDownSound(_iCol) then
        if self:getGameSpinStage() == QUICK_RUN then
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_reel_stop_quick)
        else
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_reel_stop_normal)
        end
    end
    self:setReelDownSoundId(_iCol, self.m_reelDownSoundPlayed)
end

--重写
function CodeGameScreenHogHustlerMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        -- self:resetMusicBg(true) --改
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

--重写
--连线时间点 到大赢弹板需要两秒 去掉0.5延迟
function CodeGameScreenHogHustlerMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        -- performWithDelay(
        --     self,
        --     function()
        --         effectData.p_isPlay = true
        --         self:playGameEffect()
        --     end,
        --     0.5
        -- )
        effectData.p_isPlay = true
        self:playGameEffect()
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true
end

--重写
--触发连线同时触发大富翁 如果有集字母多余钱时 不通知updatetop  剩余钱崩时通知
function CodeGameScreenHogHustlerMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    local mode = self:getCurrSpinMode()
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE then --改    进入free前触发连线 赢钱通知上方top
    -- if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end


    --改
    if isNotifyUpdateTop and (self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE) then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata.coin and selfdata.coin > 0 then
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin - selfdata.coin, false})
            local firstTime = selfdata.firstTime or false
            if firstTime then               --引导时通知上方top 收集多余钱在大富翁里面进行更新 。。。
                self.m_bottomUI:notifyTopWinCoin(selfdata.coin)    --通知的要减去字母多余的。。
            end
            globalData.slotRunData.lastWinCoin = lastWinCoin
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
    

    
end

--重写
function CodeGameScreenHogHustlerMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            2,  --改 连线触发时间等待
            self:getModuleName()
        )
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

--重写 respinover 后触发大赢
function CodeGameScreenHogHustlerMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
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

--触发free时 当前轮 不因effect更改free状态 在触发后更改m_bProduceSlots_InFreeSpin
function CodeGameScreenHogHustlerMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --改
    --如果有fs
    -- if bHasFsEffect then
    --     if self.m_bProduceSlots_InFreeSpin == false then
    --         self.m_bProduceSlots_InFreeSpin = true
    --     end
    -- end
    --改
end

--重写
function CodeGameScreenHogHustlerMachine:addLastWinSomeEffect() -- add big win or mega win
    local notAddEffect = self:checkIsAddLastWinSomeEffect()

    if notAddEffect then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    --有触发大富翁多余钱时 大赢触发减去这个值 多余钱不算到大赢里
    local bigWinCoinsReduce = 0
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata.coin and selfdata.coin > 0 then
            bigWinCoinsReduce = selfdata.coin
        end
    end
    local bigWinCoins = math.max(self.m_iOnceSpinLastWin - bigWinCoinsReduce, 0)

    self.m_fLastWinBetNumRatio = bigWinCoins / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    local curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = bigWinCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = bigWinCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = bigWinCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = bigWinCoins
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

function CodeGameScreenHogHustlerMachine:getBottomUINode( )
    return "CodeHogHustlerSrc.HogHustlerBoottomUiView"
end

--重写
function CodeGameScreenHogHustlerMachine:operaSpinResultData(param)
    local spinData = param[2]

    self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

    if spinData.result.storedIcons then
        self.m_respinStoreValue = spinData.result.storedIcons
    end
    
end

--重写
function CodeGameScreenHogHustlerMachine:operaWinCoinsWithSpinResult(param)
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
    --发送测试赢钱数
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN, self.m_serverWinCoins)
    globalData.userRate:pushCoins(self.m_serverWinCoins)

    if spinData.result.freespin.freeSpinsTotalCount == 0 then
        self:setLastWinCoin(spinData.result.winAmount)
    else
        self:setLastWinCoin(spinData.result.freespin.fsWinCoins)
    end
    globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

    if spinData.result.storedIcons then
        self.m_respinStoreValue = spinData.result.storedIcons
    end
end

function CodeGameScreenHogHustlerMachine:getJackpotValue(_posIdx)
    if self.m_respinStoreValue and _posIdx then
        for key, value in pairs(self.m_respinStoreValue) do
            if value and value[1] and value[3] then
                if _posIdx == value[1] then
                    -- util_printLog("getjackpotValue")
                    -- util_printLog(_posIdx)
                    -- util_printLog(value[3])
                    return value[3]
                end
            end
        end
    end
    return nil
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenHogHustlerMachine:showBigWinLight(_func)
    local animName = "actionframe_bigwin2"

    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_bigwin_globaleffect)

    self.m_spineBigWin:setVisible(true)
    
    util_spinePlay(self.m_spineBigWin, animName, false)
    local spineEndCallFunc = function()
        self.m_spineBigWin:setVisible(false)
    end
    util_spineEndCallFunc(self.m_spineBigWin, animName, spineEndCallFunc)

    self:shakeOneNodeForever(60/30)
    self:waitWithDelay(60/30, function()
        if type(_func) == "function" then
            _func()
        end
    end)
end

return CodeGameScreenHogHustlerMachine






