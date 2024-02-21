---
-- island li
-- 2019年1月26日
-- CodeGameScreenLuxuryDiamondMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenLuxuryDiamondMachine = class("CodeGameScreenLuxuryDiamondMachine", BaseFastMachine)

CodeGameScreenLuxuryDiamondMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenLuxuryDiamondMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenLuxuryDiamondMachine.QUICKHIT_SCORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenLuxuryDiamondMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识
CodeGameScreenLuxuryDiamondMachine.BIGWINPLAY_EFFECT = GameEffect.EFFECT_BIGWIN - 1
CodeGameScreenLuxuryDiamondMachine.SYMBOL_BLANK   = 100 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_LEVEL1  = 200 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_LEVEL2  = 201 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_LEVEL3  = 202 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_LEVEL4  = 203 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_LEVEL5  = 204 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_LEVEL6  = 205 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_LEVEL7  = 206 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_FREE1   = 207 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_FREE2   = 208 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_FREE3   = 209 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_COLLECT = 94  -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_MINI    = 101 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_MINOR   = 102 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_MAJOR   = 103 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_GRAND   = 104 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.SYMBOL_SUPER   = 105 -- 自定义的小块类型
CodeGameScreenLuxuryDiamondMachine.JACKPOT_NAME_LIST = {"super","grand", "major", "minor","mini" }


-- 构造函数
function CodeGameScreenLuxuryDiamondMachine:ctor()
    CodeGameScreenLuxuryDiamondMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_isOpenRewaedFreeSpin = true
    self.m_spinRestMusicBG = true
    self.m_lineScoreNodes = {}
    self.m_jackpotWinCoins = 0
    self.p_curBetMultiply = 1
	--init
	self:initGame()
end

function CodeGameScreenLuxuryDiamondMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LuxuryDiamondConfig.csv", "LevelLuxuryDiamondConfig.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
    self.m_maxColNum = 5     --最高的档位
    self.m_betValueTab = {}  --各个档位bet的临界值
    self.m_chooseIndex = 0   --当前选择的档位
    self.m_colWidth = 204    --每列遮罩的宽度
    self.m_jackpotIndex = 0  --当前jackpot的索引值
    self.m_isShowTip = false 
    self.m_iBetLevel = 0
    self.m_clipNode = {}
    self.m_isChanging = false
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLuxuryDiamondMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LuxuryDiamond"  
end




function CodeGameScreenLuxuryDiamondMachine:initUI()

    self.m_jackPotBar = util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondJackPotBarView")
    self.m_jackPotBar:initMachine(self)
    self:findChild("jackpot"):addChild(self.m_jackPotBar)

    self.m_colBtn = util_createAnimation("LuxuryDiamond_Reel.csb")
    self:findChild("reel_xuanze"):addChild(self.m_colBtn)
    self:addClick(self.m_colBtn:findChild("click_Btn"))

    self.m_bigWinPlayAnim = util_createAnimation("LuxuryDiamond_bigwin.csb")
    self:findChild("Node_bigwin"):addChild(self.m_bigWinPlayAnim)
    self.m_bigWinPlayAnim:setVisible(false)

    self.m_freeBar = util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondFreespinBarView")
    local freeBar_pos = util_convertToNodeSpace(self:findChild("freegamebar"),  self.m_clipParent)
    self.m_clipParent:addChild(self.m_freeBar, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    self.m_freeBar:setPosition(freeBar_pos)
    self.m_freeBar:setVisible(false)

    self.m_choose_view =  util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondChooseColView")
    local line_pos = util_convertToNodeSpace(self:findChild("reel_tishikuang"),  self.m_clipParent)
    self:addChild(self.m_choose_view,GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 2)
    self.m_choose_view:findChild("root"):setScale(self.m_machineRootScale)
    self.m_choose_view:setVisible(false)

    self.m_score_view =  util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondScoreView", self)
    self:findChild("paytable"):addChild(self.m_score_view)
    self:addClick(self.m_score_view:findChild("Panel_DetailShow"))

    self.m_score_detail_view =  util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondScoreDetailView", self)
    local line_pos = util_convertToNodeSpace(self:findChild("reel_tishikuang"),  self.m_clipParent)
    self:addChild(self.m_score_detail_view,GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 2)
    self.m_score_detail_view:findChild("root"):setScale(self.m_machineRootScale)
    self.m_score_detail_view:setVisible(false)


    self.m_reel_line = util_createAnimation("LuxuryDiamond_tishixian.csb")
    local line_pos = util_convertToNodeSpace(self:findChild("reel_tishikuang"),  self.m_clipParent)
    self.m_reel_line:setPosition(line_pos)
    self.m_clipParent:addChild(self.m_reel_line, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 5)

    self.m_reel_make = util_createAnimation("LuxuryDiamond_yaan.csb")
    local mask_pos = util_convertToNodeSpace(self:findChild("reel_yaan"),  self.m_clipParent)
    self.m_reel_make:setPosition(mask_pos)
    self.m_reel_make:setPositionY(self.m_reel_make:getPositionY() - 2)
    self.m_clipParent:addChild(self.m_reel_make, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 3)

    self.m_reelSuoAnim = {}
    self.m_reelSuoAnimTouch = {}
    for i=1,4 do
        self.m_reelSuoAnim[i] = util_createAnimation("LuxuryDiamond_Reelsuo.csb")
        local pos = util_convertToNodeSpace(self:findChild("sp_reel_" .. i),  self.m_clipParent)
        self.m_reelSuoAnim[i]:setPosition(cc.p(pos.x + 200/2, pos.y + 421/2))
        self.m_clipParent:addChild(self.m_reelSuoAnim[i], SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 4)

        self.m_reelSuoAnim[i]:setVisible(true)
        self.m_reelSuoAnim[i]:playAction("idle", true)


        self.m_reelSuoAnimTouch[i] = ccui.Layout:create()
        self.m_reelSuoAnimTouch[i]:setContentSize(cc.size(200, 421))
        self.m_reelSuoAnimTouch[i]:setAnchorPoint(cc.p(0, 0))
        self.m_reelSuoAnimTouch[i]:setTouchEnabled(true)
        self.m_reelSuoAnimTouch[i]:setSwallowTouches(true)
        self.m_clipParent:addChild(self.m_reelSuoAnimTouch[i], SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2 + 1)
        self.m_reelSuoAnimTouch[i]:setPosition(cc.p(pos.x, pos.y))
        self.m_reelSuoAnimTouch[i]:setName("Panel_Click" .. i)
        -- self.m_reelSuoAnimTouch[i]:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        -- self.m_reelSuoAnimTouch[i]:setBackGroundColor(cc.c3b(0, 150, 0))
        -- self.m_reelSuoAnimTouch[i]:setBackGroundColorOpacity(150)
        self:addClick(self.m_reelSuoAnimTouch[i])
    end
    

    self.m_progress = util_createView("CodeLuxuryDiamondSrc/LuxuryDiamondProgress", self)
    local freeBar_pos = util_convertToNodeSpace(self:findChild("jindutiao"),  self.m_clipParent)
    self.m_clipParent:addChild(self.m_progress, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    self.m_progress:setPosition(freeBar_pos)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_Guochang_Spine = util_spineCreate("LuxuryDiamond_chaopiao", true, true)
    self:addChild(self.m_Guochang_Spine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_Guochang_Spine:setPosition(display.width * 0.5, display.height * 0.5)
    -- self.m_Guochang_Spine:setScale(self.m_machineRootScale)
    self.m_Guochang_Spine:setVisible(false)

    self.m_freeGuochang_Spine = util_spineCreate("LuxuryDiamond_mubu", true, true)
    self:addChild(self.m_freeGuochang_Spine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_freeGuochang_Spine:setPosition(display.width * 0.5, display.height * 0.5)
    -- self.m_freeGuochang_Spine:setScale(self.m_machineRootScale)
    self.m_freeGuochang_Spine:setVisible(false)
    self.m_freeGuochang_Spine:setScale(1.02)
    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if not (freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE) then
            if self.m_bIsBigWin then
                return 
            end
        end 

        --free触发不播连线声
        local featureLen = self.m_runSpinResultData.p_features or {}
        if #featureLen >= 2 then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply
        if self.m_iAverageBet then
            totalBet = self.m_iAverageBet * 4
        end
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end
        local name_str = "music_LuxuryDiamond_last_win_"
        if self.m_bProduceSlots_InFreeSpin then
            local extraData = self.m_runSpinResultData.p_fsExtraData or {}
            if extraData and extraData.isCollect then
                name_str = "music_LuxuryDiamond_last_superfreewin_"
            else
                name_str = "music_LuxuryDiamond_last_freewin_"
            end
        end
        local soundName = string.format("LuxuryDiamondSounds/%s%d.mp3", name_str, soundIndex)
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)


    -- jackpot栏扫光
    self:runCsbAction("idle", true)

    self.m_jackpotEffectArray = {}
    for i=1,5 do
        local effect = util_createAnimation("LuxuryDiamond_Jackpot_win.csb")
        self:findChild("jackpot_win" .. i):addChild(effect)
        table.insert(self.m_jackpotEffectArray, effect)
        effect:runCsbAction("actionframe", true)
        effect:setVisible(false)
    end
    

    self:addClick(self:findChild("Panel_2"))

    self.m_tipNode = cc.Node:create()
    self:addChild(self.m_tipNode)
end


function CodeGameScreenLuxuryDiamondMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        if not self:checkHasGameEffectType(GameEffect.EFFECT_REWARD_FS_START) then
            gLobalSoundManager:playSound("LuxuryDiamondSounds/music_LuxuryDiamond_enter.mp3")
        end

    end,0.01,self:getModuleName())
end

function CodeGameScreenLuxuryDiamondMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:initCurBetLevel()

    if self.m_runSpinResultData.p_freeSpinsLeftCount == nil or self.m_runSpinResultData.p_freeSpinsLeftCount <= 0 then
        self.m_choose_view:playIdle()
        self.m_choose_view:setVisible(true)
        self.m_isShowTip = true

        self:changeBg("base", true)
    else
        for i=1,4 do
            if i <= self.m_iBetLevel then
                self.m_reelSuoAnim[i]:setVisible(false)
                self.m_reelSuoAnimTouch[i]:setVisible(false)
                -- self.m_reelSuoAnimTouch[i]:setBackGroundColorOpacity(0)
            end
        end
        
        local extraData = self.m_runSpinResultData.p_fsExtraData
        if extraData and extraData.isCollect then
            self:changeBg("super_free", true)
        else
            self:changeBg("free", true)
        end

        self.m_score_view:updateScore()
        self.m_score_detail_view:updateScore()
    end
    self.m_jackPotBar:updateUI(self.m_iBetLevel, true)
    self:addObservers()
end

function CodeGameScreenLuxuryDiamondMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        -- if globalData.slotRunData.isDeluexeClub == false then

        -- end
        self:updateBetLevel()
        if self.m_isShowTip then
            self.m_isShowTip = false
            self:initTips()
            self:waitWithDelay(2.5, function()
                self:removeTips()
            end)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        
        if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
            self:clickMapTipView()
        end        
    end,"SHOW_COLLECT_TIP_LUXDIA")

    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_isChanging == false then
            self:chooseBetLevel(params[1])
            self:showReelLineAndMake()
        end
        
    end,"CHOOSE_LUXDIA")
end

function CodeGameScreenLuxuryDiamondMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.p_curBetMultiply = 1
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    self.m_isChanging = false

    if self.m_tipNode and not tolua.isnull(self.m_tipNode) then
        self.m_tipNode:removeFromParent()
    end
    
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenLuxuryDiamondMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BLANK then
        return "Socre_LuxuryDiamond_Blank"
    elseif symbolType == self.SYMBOL_LEVEL1 then
        return "Socre_LuxuryDiamond_3"
    elseif symbolType == self.SYMBOL_LEVEL2 then
        return "Socre_LuxuryDiamond_4"
    elseif symbolType == self.SYMBOL_LEVEL3 then
        return "Socre_LuxuryDiamond_5"
    elseif symbolType == self.SYMBOL_LEVEL4 then
        return "Socre_LuxuryDiamond_6"
    elseif symbolType == self.SYMBOL_LEVEL5 then
        return "Socre_LuxuryDiamond_7"
    elseif symbolType == self.SYMBOL_LEVEL6 then
        return "Socre_LuxuryDiamond_8"
    elseif symbolType == self.SYMBOL_LEVEL7 then
        return "Socre_LuxuryDiamond_9"
    elseif self:isFixFreeSymbol(symbolType) then
        return "Socre_LuxuryDiamond_Scatter"
    elseif symbolType == self.SYMBOL_COLLECT then
        return "Socre_LuxuryDiamond_Key"
    elseif symbolType == self.SYMBOL_MINI then
        return "Socre_LuxuryDiamond_Mini"
    elseif symbolType == self.SYMBOL_MINOR then
        return "Socre_LuxuryDiamond_Minor"
    elseif symbolType == self.SYMBOL_MAJOR then
        return "Socre_LuxuryDiamond_Major"
    elseif symbolType == self.SYMBOL_GRAND then
        return "Socre_LuxuryDiamond_Grand"
    elseif symbolType == self.SYMBOL_SUPER then
        return "Socre_LuxuryDiamond_Super"
    end    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenLuxuryDiamondMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BLANK,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LEVEL1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LEVEL2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LEVEL3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LEVEL4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LEVEL5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LEVEL6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LEVEL7,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FREE1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FREE2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FREE3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_COLLECT,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_GRAND,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SUPER,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenLuxuryDiamondMachine:MachineRule_initGame(  )
    local percent = self:getBaseBarPercent()
    self.m_progress:restProgressEffect(percent)    

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local  selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        if selfdata.jackpot and #selfdata.jackpot > 0 then
            for i = 1, #selfdata.jackpot do
                local jackpot_info = selfdata.jackpot[i]
                local coins = jackpot_info.amount
                globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - coins
                if globalData.slotRunData.lastWinCoin <= 0 then
                    globalData.slotRunData.lastWinCoin = 0
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{0})
            end
            --QUICKHIT_SCORE_EFFECT
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.QUICKHIT_JACKPOT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
        end
        
        self.m_freeBar:changeFreeSpinByCount()
    end

end

---
-- 进入关卡
--
function CodeGameScreenLuxuryDiamondMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    --改
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local _slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if _slotNode then
                    if self:isFixJackpotSymbol(_slotNode.p_symbolType) or self:isFixFreeSymbol(_slotNode.p_symbolType) then
                        local nodeParent = _slotNode:getParent()
                        _slotNode.m_preParent = nodeParent
                        -- slotNode.m_showOrder = slotNode:getLocalZOrder()
                        _slotNode.m_preX = _slotNode:getPositionX()
                        _slotNode.m_preY = _slotNode:getPositionY()
                        _slotNode.m_preLayerTag = _slotNode.p_layerTag
                        util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                        self.m_clipNode[#self.m_clipNode + 1] = _slotNode
                    end
                end
            end
        end
    end

    --改

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function CodeGameScreenLuxuryDiamondMachine:getBaseBarPercent()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectData = selfdata.collectData or {}
    local collectTotalCount = collectData.request or 0
    local collectCount = collectData.collect or 0
    local percent = (collectCount / collectTotalCount) * 100
    return percent
end

--重写
--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenLuxuryDiamondMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            --改
            if self:isFixJackpotSymbol(_slotNode.p_symbolType) then
                symbolType = 101
            end
            if self:isFixFreeSymbol(_slotNode.p_symbolType) then
                symbolType = 207
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

--重写
-- 有特殊需求判断的 重写一下
function CodeGameScreenLuxuryDiamondMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            if (self:isFixFreeSymbol(_slotNode.p_symbolType) or self:isFixJackpotSymbol(_slotNode.p_symbolType) or _slotNode.p_symbolType == self.SYMBOL_COLLECT) and _slotNode.p_cloumnIndex <= self.m_iBetLevel + 1 then
                return true
            end
        end
    end

    return false
end

--重写
-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenLuxuryDiamondMachine:symbolBulingEndCallBack(node)
    if node.p_symbolType and self:isFixJackpotSymbol(node.p_symbolType) then
        node:runAnim("idleframe", true)
    end
end

--重写
function CodeGameScreenLuxuryDiamondMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg and _slotNode.p_cloumnIndex <= self.m_iBetLevel + 1 then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    local nodeParent = _slotNode:getParent()
                    _slotNode.m_preParent = nodeParent
                    -- slotNode.m_showOrder = slotNode:getLocalZOrder()
                    _slotNode.m_preX = _slotNode:getPositionX()
                    _slotNode.m_preY = _slotNode:getPositionY()
                    _slotNode.m_preLayerTag = _slotNode.p_layerTag


                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    self.m_clipNode[#self.m_clipNode + 1] = _slotNode

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
            end
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenLuxuryDiamondMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    self.m_freeBar:setVisible(true)
    self.m_progress:setVisible(false)
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.betLevel then
        if self.m_iBetLevel ~= extraData.betLevel then
            self.m_iBetLevel = extraData.betLevel
            self:initColBtn(self.m_iBetLevel + 1)
            self:initReelLineAndMake()
        end
    end
    if extraData and extraData.isCollect then
        local triggerJackpot = extraData.triggerJackpot
        for i,v in ipairs(self.JACKPOT_NAME_LIST) do
            self.m_freeBar:findChild(v):setVisible(v == triggerJackpot[1])
        end
        self.m_freeBar:runCsbAction("start2")
        -- self.m_superFreeLizi:setVisible(true)
        self.m_iAverageBet = self.m_runSpinResultData.p_selfMakeData.avgBet
        self.m_bottomUI:showAverageBet()

        self.m_score_view:updateScore()
        self.m_score_detail_view:updateScore()

        self:changeBg("super_free")
    else
        self.m_freeBar:runCsbAction("idle")

        self:changeBg("free")
    end
    self:removeTips()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenLuxuryDiamondMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    self.m_freeBar:setVisible(false)
    self.m_progress:setVisible(true)
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.isCollect then
        self.m_progress:restProgressEffect(0) 
        self.m_bottomUI:hideAverageBet()
        self.m_iAverageBet = nil
        -- self.m_superFreeLizi:setVisible(false)

        self.m_score_view:updateScore()
        self.m_score_detail_view:updateScore()
    end
    self:changeBg("base")
    self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenLuxuryDiamondMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self.m_iOnceSpinLastWin = 0  --重置本次赢钱信息，让free的第一次spin加快滚动
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                effectData.p_isPlay = true
                self:playGameEffect()   
            end)
        end
    end
    --  延迟0.5 不做特殊要求都这么延迟
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        showFSView()  
    else 
        performWithDelay(self,function(  )
            showFSView()    
        end,0.5)
    end 

end

function CodeGameScreenLuxuryDiamondMachine:showFreeSpinOverView()

   local extraData = self.m_runSpinResultData.p_fsExtraData
   if extraData and extraData.isCollect then
        local triggerJackpot = extraData.triggerJackpot
        local ownerlist={}
        ownerlist["m_lb_coin_0"] = util_formatCoins(extraData.lineWins, 30)
        ownerlist["m_lb_coin_1"] = util_formatCoins(extraData.jackpotWins, 30)
        ownerlist["m_lb_coin"] = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)

        self:stopLineMusic()
        local view = self:showDialog("FreeSpinOver_1",ownerlist,function()
            self:showGuoChange(function()
                self:levelFreeSpinOverChangeEffect()
            end, function()
                self:triggerFreeSpinOverCallFun()
            end, false)
        end)
        local node=view:findChild("m_lb_coin")
        view:updateLabelSize({label=node,sx=0.55,sy=0.55},893)
        local node1 = view:findChild("m_lb_coin_0")
        view:updateLabelSize({label=node1,sx=0.55,sy=0.55},823)
        local node2 = view:findChild("m_lb_coin_1")
        view:updateLabelSize({label=node2,sx=0.55,sy=0.55},753)
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_superFree_end.mp3")
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_popup_start.mp3")
        view:setOverAniRunFunc(function()
            gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_popup_end.mp3")
        end)
   else
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:showFreeGuoChange(function()
                self:levelFreeSpinOverChangeEffect()
            end, function()
                self:triggerFreeSpinOverCallFun()
            end, false)
        end)

        local spineBox = util_spineCreate("LuxuryDiamond_SuperFreeSpin", true, true)
        view:findChild("Node_spine"):addChild(spineBox)
        util_spinePlay(spineBox, "start_free", false)
        util_spineEndCallFunc(spineBox, "start_free", function()
            util_spinePlay(spineBox, "idle_free", true)
        end)

        local effectLight = util_createAnimation("LuxuryDiamond_tb_guang.csb")
        view:findChild("Node_guang"):addChild(effectLight)
        effectLight:runCsbAction("idle",true)

        self:flyMoney(view:findChild("Particle_1"))

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},751)

        view:updateLabelSize({label=view:findChild("m_lb_num"),sx=1,sy=1},100)
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_Free_end.mp3")
   end
end

function CodeGameScreenLuxuryDiamondMachine:flyMoney(particle)
    if not tolua.isnull(particle) then
        -- particle:stopSystem()
        particle:setVisible(false)
        -- particle:setDuration(-1)
        util_setCascadeOpacityEnabledRescursion(particle, true)
        self:waitWithDelay(
            10 / 60,
            function()
                particle:setVisible(true)
                particle:resetSystem()
            end
        )
    end
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLuxuryDiamondMachine:MachineRule_SpinBtnCall()
    

    self:setMaxMusicBGVolume( )
    self:setSymbolToReel()
    self.m_lineScoreNodes = {}
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:removeTips()
    self.m_jackpotWinCoins = 0 --当前jackpot赢钱

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenLuxuryDiamondMachine:addSelfEffect()
    local  selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    if selfdata.lines and #selfdata.lines > 0 then
        --QUICKHIT_SCORE_EFFECT
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.QUICKHIT_SCORE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.QUICKHIT_SCORE_EFFECT -- 动画类型
    end

    if selfdata.jackpot and #selfdata.jackpot > 0 then
        --QUICKHIT_SCORE_EFFECT
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.QUICKHIT_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
    end

    local isHave = false
    if self.m_iBetLevel == 4 then
        local iCol = self.m_maxColNum
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node.p_symbolType == self.SYMBOL_COLLECT then
                isHave = true
                break
            end
        end 
    end
    if isHave then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.FLY_COIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT
    end

    if self.m_bProduceSlots_InFreeSpin then
        local extraData = self.m_runSpinResultData.p_fsExtraData
        if extraData and extraData.isCollect and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 and globalData.slotRunData.freeSpinCount ~= 0 then
            globalData.slotRunData.freeSpinCount =0
            self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
        end
    end

    -- while true
    -- do
    --     if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
    --         break
    --     end
    --     local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    --     if hasFsEffect then
    --         break
    --     end
    --     if self:getWinEffect(self.m_runSpinResultData.p_winAmount) ~= nil and math.random(0, 100) > 40
    --     and self.m_runSpinResultData.p_freeSpinNewCount == 0 then
    --         local selfEffect = GameEffectData.new()
    --         selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --         selfEffect.p_effectOrder = self.BIGWINPLAY_EFFECT 
    --         self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --         selfEffect.p_selfEffectType = self.BIGWINPLAY_EFFECT
    --     end

    --     break
    -- end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLuxuryDiamondMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.QUICKHIT_SCORE_EFFECT then
        self:showBounsScoreEffect(effectData)
    elseif effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then
        self:showJackpotScoreEffect(effectData)
    elseif effectData.p_selfEffectType == self.FLY_COIN_EFFECT then
        self:waitWithDelay(0.5, function()
            self:showEffect_collectCoin(effectData)
        end)
    -- elseif effectData.p_selfEffectType == self.BIGWINPLAY_EFFECT then
    --     self:showBigWinPlayEffect(effectData)
    end

	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenLuxuryDiamondMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


--[[
    @desc: 再有额外背景音乐需要播放时， 可以先调用这个函数，再调用resetMusicBg
    time:2018-07-26 17:32:47
    @return:
]]
--isFadaOut 是否淡出背景音乐
function CodeGameScreenLuxuryDiamondMachine:clearCurMusicBg(isFadaOut)
    if self.m_currentMusicId == nil then
        self.m_currentMusicId = gLobalSoundManager:getBGMusicId()
    end
    if self.m_currentMusicId ~= nil then
        if isFadaOut then
            self:removeSoundHandler()
            self:fadeOutBGM()
        else
            gLobalSoundManager:stopAudio(self.m_currentMusicId)
            self.m_currentMusicId = nil
        end
    end
end


function CodeGameScreenLuxuryDiamondMachine:chooseBetLevel(choose_index)
    local curBetLevel = self:getCurBetLevel()
    self.m_iBetLevel  = choose_index - 1
    local _curTotalBet = globalData.slotRunData:getCurTotalBet()
    if curBetLevel ~= self.m_iBetLevel then
        local betMulti = self:getCurBetLevelMulti()
        self.p_curBetMultiply = betMulti
        self:setSymbolToReel(true)
        self.m_jackPotBar:updateUI(self.m_iBetLevel)
    end
    local betId = globalData.slotRunData.iLastBetIdx
    self.m_bottomUI:changeBetCoinNum(betId, _curTotalBet, curBetLevel ~= self.m_iBetLevel, true)
    self:initColBtn(choose_index)
    local coins = self.m_betValueTab[choose_index]
    self:initColBtnCoins(coins)
    self.m_progress:lock(self.m_iBetLevel)
end

function CodeGameScreenLuxuryDiamondMachine:initCurBetLevel()
    local featureLen = self.m_runSpinResultData.p_features or {}
    if self:getCurrSpinMode() == FREE_SPIN_MODE or #featureLen >= 2  then
        local extraData = self.m_runSpinResultData.p_fsExtraData
        if extraData and extraData.betLevel then
            if self.m_iBetLevel ~= extraData.betLevel then
                self.m_iBetLevel = extraData.betLevel
            end
            local betMulti = self:getCurBetLevelMulti()
            self.p_curBetMultiply = betMulti
            self.m_bottomUI:updateBetCoin()
        end
    end
    local betCoin = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply
    self:initChooseBetLabel()
    self:initColBtn(self.m_iBetLevel + 1)
    self:initColBtnCoins(betCoin)
    self:initReelLineAndMake()
    self.m_progress:lock(self.m_iBetLevel)
end

--初始化chooseViewlabel
function CodeGameScreenLuxuryDiamondMachine:initChooseBetLabel()
    self.m_betValueTab = {}
    for index = 1,self.m_maxColNum do
        local betValue = self:getBetLevelCoins(index)
        table.insert(self.m_betValueTab, betValue )
    end
    self.m_choose_view:initcoins(self.m_betValueTab)
end

function CodeGameScreenLuxuryDiamondMachine:updateBetLevel()
    local betCoin = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply
    self:changeColBtnCoins(betCoin)

    self.m_score_view:updateScore()
    self.m_score_detail_view:updateScore()
end

--重写
function CodeGameScreenLuxuryDiamondMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply

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
    local operaId = self:sendActionData_Spin(httpSendMgr, betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenLuxuryDiamondMachine:sendActionData_Spin(self, betCoin, currentCoins, winCoin, isFreeSpin, slotName, bLevelUp, nextLevel, nextProVal, messageData, isShowTournament)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    globalData.slotRunData.isClickQucikStop = false

    local actType = nil

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    self.levelName = slotName
    actType = ActionType.SpinV2

    local clickPos = nil
    local bonusSelect = nil
    local collectData = nil
    local choose = nil
    local jackpotData = nil
    local unlockFeature = nil
    local betLevel = nil
    local coins = nil
    local extra = nil
    local kangaroosShopData = nil -- 袋鼠商店兑换特殊玩法
    local mermaidVersion = nil -- 美人鱼服务器兼容字段
    if messageData and type(messageData) == "table" then
        if messageData.clickPos then
            clickPos = messageData.clickPos
        end

        if messageData.bonusSelect then
            bonusSelect = messageData.bonusSelect
        end

        if messageData.mermaidVersion then
            mermaidVersion = messageData.mermaidVersion
        end

        if messageData.msg == MessageDataType.MSG_BONUS_COLLECT then
            actType = ActionType.Bonus

            collectData = messageData.data
        elseif messageData.msg == MessageDataType.MSG_BONUS_SELECT then
            actType = ActionType.BonusV2
            choose = messageData.data
            jackpotData = messageData.jackpot
            betLevel = messageData.betLevel
            coins = messageData.coins
            extra = messageData.extra
        elseif messageData.msg == MessageDataType.MSG_SPIN_PROGRESS then
            collectData = messageData.data
            jackpotData = messageData.jackpot
            unlockFeature = messageData.unlockFeature
            betLevel = messageData.betLevel
        elseif messageData.msg == MessageDataType.MSG_MISSION_COMLETED then
            actType = ActionType.MissionCollect
        elseif messageData.msg == MessageDataType.MSG_BONUS_SPECIAL then
            actType = ActionType.BonusSpecial
            choose  = messageData.choose
            kangaroosShopData = messageData.data
        elseif messageData.msg == MessageDataType.MSG_LUCKY_SPIN then
            actType = ActionType.LuckSpinAward
        elseif messageData.msg == MessageDataType.MSG_DELUXE_CHANGE_COIN then
            actType = ActionType.HighLimitCollectCoin
        elseif messageData.msg == MessageDataType.MSG_TEAM_MISSION_OPTION then
            --关卡团队任务玩家操作
            actType = ActionType.TeamMissionOption
        elseif messageData.msg == MessageDataType.MSG_TEAM_MISSION_STORE then
            actType = ActionType.TeamMissionStore
        elseif messageData.msg == MessageDataType.MSG_TEAM_MISSION_JOIN then
            actType = ActionType.TeamMissionJoin
        end
    end

    if globalData.slotRunData.isDeluexeClub == true then
        if string.find(self.levelName, "_H") == nil then
            self.levelName = self.levelName .. "_H"
        end

        if actType == ActionType.SpinV2 then
            actType = ActionType.HighLimitSpin
        elseif actType == ActionType.BonusV2 then
            actType = ActionType.HighLimitBonus
        elseif actType == ActionType.BonusSpecial then
            actType = ActionType.HighLimitBonusSpecial
        end
    end

    local actionData = self:getSendActionData(actType, self.levelName)

    -- if winType == 0 then
    --     winType = 1
    -- end
    -- 改
    -- 修改bet值
    actionData.data.betCoins = betCoin--globalData.slotRunData:getCurTotalBet()
    -- 改

    actionData.data.betGems = 0

    actionData.data.winCoins = winCoin
    -- actionData.data.winGems = 0
    actionData.data.balanceCoins = 0
    actionData.data.balanceCoinsNew = get_integer_string(currentCoins)
    actionData.data.balanceGems = 0

    if false then
        local tournamentName = gLobalTournamentData:getTournamentName(betCoin)
        actionData.tournamentName = tournamentName
    end

    -- 判断是否升级
    local addBetExp = betCoin
    local currProVal = nextProVal
    local totalProVal = globalData.userRunData:getLevelUpgradeNeedExp(nextLevel)

    actionData.data.freespin = isFreeSpin
    -- actionData.data.winType = winType
    actionData.data.exp = currProVal
    actionData.data.addExp = addBetExp
    actionData.data.levelup = bLevelUp
    actionData.data.level = nextLevel
    actionData.data.betId = globalData.slotRunData.iLastBetIdx

    actionData.data.version = self:getVersionNum()

    -- for i = 1, #slotData do
    --     actionData.data.table:append(slotData[i])
    -- end
    --    actionData.data.table:append(nil)  -- 这里是附加freeSpin下之前获得的spin coin目前不使用了
    local extraData = {}

    extraData[ExtraType.spinAccumulation] = globalData.spinAccumulation or {["time"] = os.time(), ["amount"] = 0}

    --存救济金
    extraData[ExtraType.reliefTimes] = globalData.reliefFundsTimes

    --如果存在收集数据 存储
    if collectData and type(collectData) == "table" and #collectData > 0 then
        extraData.collect = {}
        for i = 1, #collectData do
            extraData.collect[i] = {}
            extraData.collect[i].collectTotalCount = collectData[i].p_collectTotalCount
            extraData.collect[i].collectLeftCount = collectData[i].p_collectLeftCount
            extraData.collect[i].collectCoinsPool = collectData[i].p_collectCoinsPool
            extraData.collect[i].collectChangeCount = collectData[i].p_collectChangeCount
        end
    end

    if jackpotData and type(jackpotData) == "table" and #jackpotData > 0 then
        extraData.jackpot = jackpotData
    end

    local findData = {}
    findData["findLock"] = globalData.findLock
    extraData["find"] = findData

    actionData.data.extra = cjson.encode(extraData)

    local logSpinType = "normal"

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
        logSpinType = "auto"
    end

    --spin附加参数
    local paramsData = {}
    paramsData.spinSessionId = gL_logData:getGameSessionId()
    paramsData.type = logSpinType
    local levelName = globalData.slotRunData.machineData.p_levelName
    paramsData.order = gLobalSendDataManager:getLogSlots():getLevelOrder(levelName)
    gLobalSendDataManager:getLogSlots():addSlotData(paramsData)
    local maxBetData = globalData.slotRunData:getMaxBetData()
    if maxBetData then
        paramsData.maxBet = maxBetData.p_totalBetValue
    end
    if choose then
        paramsData["select"] = choose
    end
    if unlockFeature then
        paramsData["unlockFeature"] = unlockFeature
    end
    if jackpotData and type(jackpotData) == "table" and #jackpotData > 0 then
        paramsData.jackpot = jackpotData
    end
    if betLevel ~= nil then
        paramsData["betLevel"] = betLevel
    end

    if kangaroosShopData then
        paramsData["level"] = kangaroosShopData.pageIndex
        paramsData["select"] = kangaroosShopData.pageCellIndex
        paramsData["selectSuperFree"] = kangaroosShopData.selectSuperFree
    end

    if clickPos then
        paramsData["clickPos"] = clickPos
    end

    if bonusSelect then
        paramsData["bonusSelect"] = bonusSelect
    end

    if mermaidVersion then
        paramsData["mermaidVersion"] = mermaidVersion
    end

    if coins then
        paramsData["coins"] = coins
    end

    if extra then
        paramsData["extra"] = extra
    end
    

    if actType == ActionType.TeamMissionOption then
        paramsData.action = messageData.action
        if not paramsData.extra then
            paramsData.extra = {}
        end
        paramsData.extra.choose = messageData.choose or {}
    end
    if actType == ActionType.TeamMissionStore then
        if not paramsData.extra then
            paramsData.extra = {}
        end
        paramsData.extra.choose = messageData.choose or 0
    end
    if actType == ActionType.TeamMissionJoin then
        if not paramsData.extra then
            paramsData.extra = {}
        end
        paramsData.extra.choose = messageData.choose or 0
        paramsData.game = messageData.game
        paramsData.roomId = messageData.roomId
        paramsData.chairId = messageData.chairId
    end

    actionData.data.params = json.encode(paramsData)

    globalData.slotRunData.gameEffStage = GAME_START_REQUEST_STATE
    globalData.slotRunData.spinNetState = GAME_START_REQUEST_STATE

    if actType == ActionType.TeamMissionJoin then
        self:sendMessageData(actionData)
    else
        self:sendMessageData(actionData, self.spinResultSuccessCallFun, self.spinResultFaildCallFun)
    end
    --spin 重置 firebase 弹窗
    if globalNoviceGuideManager then
        globalNoviceGuideManager.guideBubbleAddBetPopup = nil
        globalNoviceGuideManager.guideBubbleMaxBetPopup = nil
        globalNoviceGuideManager.guideBubbleReturnLobbyPopup = nil
    end
end

function CodeGameScreenLuxuryDiamondMachine:getCurBetLevel()
    return self.m_iBetLevel
end

function CodeGameScreenLuxuryDiamondMachine:getCurBetLevelMulti()
    local betMulti = 1 
    if self.m_specialBetMulti then
        betMulti = self.m_specialBetMulti[self.m_iBetLevel + 1]
    end
    return betMulti or 1
end

function CodeGameScreenLuxuryDiamondMachine:initColBtn(col)
    for index = 1,self.m_maxColNum do
        self.m_colBtn:findChild("tiao_"..index):setVisible(index <= col)
    end

    self.m_score_detail_view:initColBtn(col)
end

function CodeGameScreenLuxuryDiamondMachine:initColBtnCoins(coins)
    local strCoins = util_formatCoins(coins,3)
    self.m_colBtn:findChild("m_lb_coin"):setString(strCoins)

    self.m_score_detail_view:initColBtnCoins(coins)
end

function CodeGameScreenLuxuryDiamondMachine:changeColBtnCoins(coins)
    self:initColBtnCoins(coins)
end

function CodeGameScreenLuxuryDiamondMachine:getBetLevelCoins(index)
    local betMulti = 1 
    if self.m_specialBetMulti then
        betMulti = self.m_specialBetMulti[index]
    end
    local betIndex = globalData.slotRunData:getCurBetIndex()
    local totalBetValue = globalData.slotRunData:getCurBetValueByIndex(betIndex)
    local betValue = totalBetValue * betMulti
    return betValue
end

--默认按钮监听回调
function CodeGameScreenLuxuryDiamondMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "click_Btn" then
        if self:isNormalStates() then
            if self.m_isChanging == false then
                gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
                self:initChooseBetLabel()
                self.m_choose_view:showView()
            end
        end
    elseif name == "Panel_DetailShow" then
        if self:isNormalStates() then
            self.m_score_detail_view:showView()
            gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
        end
    elseif name == "Panel_2" then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            local endPos = sender:getTouchEndPosition()
            -- print(string.format("#############pos: x: %d, y: %d", endPos.x, endPos.y))
            local uiW, uiH = self.m_topUI:getUISize()
            local uiBW, uiBH = self.m_bottomUI:getUISize()
            if endPos.y > display.height * 0.33 and endPos.y < display.height - uiH then
                local clickEffect = util_createAnimation("LuxuryDiamond_fankui.csb")
                clickEffect:runCsbAction("actionframe", false, function()
                    clickEffect:removeFromParent(true)
                end)
                self:findChild("Panel_2"):addChild(clickEffect)
                local pos = self:findChild("Panel_2"):convertToNodeSpace(endPos)
                clickEffect:setPosition(pos)

                gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
            end
        end
    elseif string.find(name, "Panel_Click") ~= nil then
        if self:isNormalStates() and self.m_signalCredit then
            if self.m_isChanging == false and string.len(name) == 12 then
                local num = tonumber(string.sub(name, 12, string.len(name)))
                gLobalNoticManager:postNotification("CHOOSE_LUXDIA", {num + 1})
                self.m_choose_view:setUI(num + 1, true)
    
                gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
            end
        end
    end
    
end

function CodeGameScreenLuxuryDiamondMachine:initReelLineAndMake()
    self.m_chooseIndex = self.m_iBetLevel + 1
    self.m_reel_line:findChild("reel_0"):setContentSize(cc.size((self.m_chooseIndex) * self.m_colWidth,484))
    self.m_reel_make:findChild("reel"):setContentSize(cc.size((self.m_maxColNum - self.m_chooseIndex) * self.m_colWidth,422)) 
end

function CodeGameScreenLuxuryDiamondMachine:showReelLineAndMake()
    local tempChooseIndex = self.m_chooseIndex
    self.m_chooseIndex = self.m_iBetLevel + 1
    if tempChooseIndex == self.m_chooseIndex then
        return
    end

    local isPlayLock = false
    local isPlayUnLock = false
    if tempChooseIndex < self.m_chooseIndex then
        isPlayUnLock = true
    elseif tempChooseIndex > self.m_chooseIndex then
        isPlayLock = true
    end
    if isPlayLock then
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_reel_coin_lock.mp3")
    end
    if isPlayUnLock then
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_reel_coin_unlock.mp3")
    end
    self.m_isChanging = true
    self.m_reel_make:setVisible(true)
    self:setSpinTounchType(false)
    local max_index = 10
    local actionList = {}
    local step_width = math.abs(self.m_chooseIndex - tempChooseIndex) * self.m_colWidth/10
    step_width = step_width * ((tempChooseIndex - self.m_chooseIndex) /  math.abs(self.m_chooseIndex - tempChooseIndex))
    for i=1,max_index do
        local step_index = i
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            local cur_size = self.m_reel_make:findChild("reel"):getContentSize()
            self.m_reel_make:findChild("reel"):setContentSize(cc.size( cur_size.width + step_width, cur_size.height))
            local cur_size2 = self.m_reel_line:findChild("reel_0"):getContentSize()
            self.m_reel_line:findChild("reel_0"):setContentSize(cc.size(cur_size2.width - step_width, cur_size2.height))
            if step_index == max_index then
                self:setSpinTounchType(true)

                
                for j=1,#self.m_reelSuoAnim do
                    if tempChooseIndex < self.m_chooseIndex then
                        if tempChooseIndex < j + 1 and j + 1 <= self.m_chooseIndex then
                            self.m_reelSuoAnim[j]:playAction("jiesuo", false, function (  )
                                self.m_reelSuoAnim[j]:setVisible(false)
                                self.m_reelSuoAnimTouch[j]:setVisible(false)
                                -- self.m_reelSuoAnimTouch[j]:setBackGroundColorOpacity(0)
                                self.m_isChanging = false
                                
                            end)
                            
                        end
                    elseif tempChooseIndex > self.m_chooseIndex then
                        if tempChooseIndex >= j + 1 and j + 1 > self.m_chooseIndex then
                            self.m_reelSuoAnim[j]:setVisible(true)
                            self.m_reelSuoAnimTouch[j]:setVisible(true)
                            -- self.m_reelSuoAnimTouch[j]:setBackGroundColorOpacity(150)
                            self.m_reelSuoAnim[j]:playAction("suo", false, function (  )
                                self.m_reelSuoAnim[j]:playAction("idle", true)
                                self.m_isChanging = false
                            end)
                            
                        end
                    end
                    
                    
                end

                
            end
        end)
        if step_index ~= max_index then
            actionList[#actionList + 1] = cc.DelayTime:create(0.05)
        end
    end
    actionList[#actionList + 1] = cc.CallFunc:create( function()

    end)
    self.m_reel_make:runAction(cc.Sequence:create(actionList))
end

-- 是不是free小块
function CodeGameScreenLuxuryDiamondMachine:isFixFreeSymbol(symbolType)
    if symbolType == self.SYMBOL_FREE1 or
        symbolType == self.SYMBOL_FREE2 or
        symbolType == self.SYMBOL_FREE3 then--or
        return true
    end
    return false
end

-- 是不是free小块
function CodeGameScreenLuxuryDiamondMachine:isFixJackpotSymbol(symbolType)
    if symbolType == self.SYMBOL_MINI or
        symbolType == self.SYMBOL_MINOR or
        symbolType == self.SYMBOL_MAJOR or
        symbolType == self.SYMBOL_GRAND or
        symbolType == self.SYMBOL_SUPER then--or
        return true
    end
    return false
end

-- 是不是score小块
function CodeGameScreenLuxuryDiamondMachine:isFixScoreSymbol(symbolType)
    if symbolType == self.SYMBOL_LEVEL1 or
        symbolType == self.SYMBOL_LEVEL2 or
        symbolType == self.SYMBOL_LEVEL3 or
        symbolType == self.SYMBOL_LEVEL4 or
        symbolType == self.SYMBOL_LEVEL5 or
        symbolType == self.SYMBOL_LEVEL6 or
        symbolType == self.SYMBOL_LEVEL7 then--or
        return true
    end
    return false
end

--新滚动使用
function CodeGameScreenLuxuryDiamondMachine:updateReelGridNode(symblNode)
    if self:isFixFreeSymbol(symblNode.p_symbolType) then 
        -- if symblNode.p_symbolType == self.SYMBOL_FREE1 then
        --     symblNode:setIdleAnimName("idleframe1")
        -- elseif symblNode.p_symbolType == self.SYMBOL_FREE2 then
        --     symblNode:setIdleAnimName("idleframe2")
        -- elseif symblNode.p_symbolType == self.SYMBOL_FREE3 then
        --     symblNode:setIdleAnimName("idleframe3")
        -- end
        -- symblNode:runIdleAnim()

        local skin_str = self:getFreeSymbolSkin(symblNode.p_symbolType)
        self:setSlotsNodeSpineSkin(symblNode, skin_str)
        symblNode:runIdleAnim()
    elseif self:isFixJackpotSymbol(symblNode.p_symbolType) then 
        symblNode:runAnim("idleframe",true)
    elseif self:isFixScoreSymbol(symblNode.p_symbolType) then 

    elseif symblNode.p_symbolType == 100 then
        local ccbNode = symblNode:getCCBNode()
        local ccbSp = util_getChildByName(ccbNode, "Sprite_1")
        ccbSp:setOpacity(255*0.7)
    elseif symblNode.p_symbolType == 94 then
        local ccbNode = symblNode:getCCBNode()
        if ccbNode then
            local ccbSp = util_getChildByName(ccbNode, "Sprite_3")
            if ccbSp then
                ccbSp:setOpacity(255)
            end
            local ccbSpKey = util_getChildByName(ccbNode, "Sprite_2")
            if ccbSpKey then
                ccbSpKey:setVisible(true)
            end
        end
    end
end

function CodeGameScreenLuxuryDiamondMachine:setSlotsNodeSpineSkin(node, skinName)

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

function CodeGameScreenLuxuryDiamondMachine:getFreeSymbolSkin(symbolType)
    local skin_str = "skin1"
    if symbolType == self.SYMBOL_FREE2 then
        skin_str = "skin2"
    elseif symbolType == self.SYMBOL_FREE3 then
        skin_str = "skin3"
    end
    return skin_str
end

function CodeGameScreenLuxuryDiamondMachine:showBounsScoreEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local lines = selfdata.lines
    local features = self.m_runSpinResultData.p_features or {}
    local isLoop = #features < 2

    self.m_lineScoreNodes = {}
    if lines then
        for _,value in ipairs(lines) do
            local icons = value.icons
            for _,pos in ipairs(icons) do
                local fixPos = self:getRowAndColByPos(pos)
                local targSp = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)

                local runFunc
                runFunc = function(sp)
                    if sp then
                        if self.m_lineScoreNodes[sp] then
                            sp:runAnim("actionframe", false, function()
                                runFunc(sp)
                            end)
                        elseif self.m_lineScoreNodes[sp] == false then
                            sp:runAnim("idleframe", true)
                        end
                    end
                end
                
                if targSp then
                    if isLoop then
                        self.m_lineScoreNodes[targSp] = true
                        runFunc(targSp)
                    else
                        targSp:runAnim("actionframe",isLoop)
                    end
                end
            end
        end
    end

    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_line_money.mp3")

    -- local cor_num = self.m_iBetLevel + 1
    -- for iCol = 1,cor_num do
    --     for iRow = self.m_iReelRowNum, 1, -1 do
    --         local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
    --         if node and node.p_symbolType == self.SYMBOL_BLANK then
    --             node:runAnim("actionframe",false)
    --         end
    --     end 
    -- end

    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local oldCoins = globalData.slotRunData.lastWinCoin or 0
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE then
        isNotifyUpdateTop = false
    end
    if oldCoins == 0 and self.m_iOnceSpinLastWin > 0 then
        globalData.slotRunData.lastWinCoin = self.m_iOnceSpinLastWin
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin - self.m_jackpotWinCoins,isNotifyUpdateTop})
    globalData.slotRunData.lastWinCoin = oldCoins

    local time = 0.42
    local extraData = self.m_runSpinResultData.p_fsExtraData or {}
    if extraData and extraData.isCollect and self:checkHasGameSelfEffectType(self.FLY_COIN_EFFECT) then
        time = 2.5
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
        or self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN)
        or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
        or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        time = 0.5
    end
    self:waitWithDelay(time, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)
end

--重写
function CodeGameScreenLuxuryDiamondMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply
    local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    if self.m_iOnceSpinLastWin > 0 then
        showTime = 1
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            showTime = 1
        end
    end

    return showTime
end

function CodeGameScreenLuxuryDiamondMachine:showJackpotScoreEffect(effectData)
    self.m_jackpotIndex = 0
    self:showJackpot(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)
end

function CodeGameScreenLuxuryDiamondMachine:showJackpot(callBack)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local jackpot = selfdata.jackpot
    self.m_jackpotIndex = self.m_jackpotIndex + 1
    if self.m_jackpotIndex > #jackpot then
        if callBack then
            callBack()
        end
    else

        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_jackpot_trigger.mp3")

        local jackpot_info = jackpot[self.m_jackpotIndex]
        local pos = jackpot_info.loc
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if targSp then
            targSp:setLocalZOrder(targSp:getLocalZOrder() + 5)
            targSp:runAnim("actionframe",false, function()
                targSp:runAnim("idleframe",true)
                targSp:setLocalZOrder(targSp:getLocalZOrder() - 5)
            end)
        end
        local typeString = jackpot_info.type
        local coins = jackpot_info.amount
        local index = 1
        if typeString == "grand" then
            index = 2
        elseif typeString == "major" then
            index = 3
        elseif typeString == "minor" then
            index = 4
        elseif typeString == "mini" then
            index = 5
        end

        for i=1,5 do
            self.m_jackpotEffectArray[i]:setVisible(index == 6 - i)
        end
        self:waitWithDelay(2, function()
            -- 如果freespin 未结束，不通知左上角玩家钱数量变化
            self.m_jackpotWinCoins  = self.m_jackpotWinCoins + coins
            local isNotifyUpdateTop = true
            if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE then
                isNotifyUpdateTop = false
            end
            local oldCoins = globalData.slotRunData.lastWinCoin 
            globalData.slotRunData.lastWinCoin = oldCoins + self.m_jackpotWinCoins - self.m_iOnceSpinLastWin
            if globalData.slotRunData.lastWinCoin < self.m_jackpotWinCoins then
                globalData.slotRunData.lastWinCoin = self.m_jackpotWinCoins
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isNotifyUpdateTop})
            globalData.slotRunData.lastWinCoin = oldCoins
            self:showRespinJackpot(index, coins, function()
                self:showJackpot(callBack)
            end)

            for i=1,5 do
                self.m_jackpotEffectArray[i]:setVisible(false)
            end

            
        end)
    end
end

function CodeGameScreenLuxuryDiamondMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondJackPotWinView", self)
    jackPotWinView:initViewData(index,coins,func)
    gLobalViewManager:showUI(jackPotWinView)

end

function CodeGameScreenLuxuryDiamondMachine:showEffect_collectCoin(effectData)
    local progressPos = self.m_progress:getCollectPos()
    local newProgressPos = self.m_effectNode:convertToNodeSpace(progressPos)
    local endPos = cc.p(newProgressPos)

    local old_pecent = self.m_progress:getCurPercent()
    local pecent = self:getBaseBarPercent()
    local isCollect = false
    local iCol = self.m_maxColNum
    for iRow = self.m_iReelRowNum, 1, -1 do
        local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
        if node and node.p_symbolType == self.SYMBOL_COLLECT then
            

            node:runAnim("actionframe",false)
            self:waitWithDelay(55/60, function(  )
                local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                local newStartPos = self.m_effectNode:convertToNodeSpace(startPos)
        
                local tuowei = util_createAnimation("Socre_LuxuryDiamond_Key_shouji.csb")
                if not isCollect then
                    tuowei.m_isLastSymbol = true
                    isCollect = true
                end
                tuowei:runCsbAction("shouji",false)
                tuowei:setPosition(newStartPos)
                self.m_effectNode:addChild(tuowei, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                local actLsit = {}
                actLsit[#actLsit + 1] = cc.EaseSineIn:create(cc.MoveTo:create(20/60, endPos))
                actLsit[#actLsit + 1] = cc.CallFunc:create( function()
                    if tuowei.m_isLastSymbol == true then
                        self.m_progress:updatePercent(pecent)
                    end
                end)
                actLsit[#actLsit + 1] = cc.DelayTime:create(30/60)
                actLsit[#actLsit + 1] = cc.CallFunc:create( function()
                    tuowei:removeFromParent()
                end)
                tuowei:runAction(cc.Sequence:create(actLsit ))


                local ccbNode = node:getCCBNode()
                if ccbNode then
                    local ccbSp = util_getChildByName(ccbNode, "Sprite_3")
                    if ccbSp then
                        util_nodeFadeIn(ccbSp, 0.1, 255, 255*0.7)
                    end
                    local ccbSpKey = util_getChildByName(ccbNode, "Sprite_2")
                    if ccbSpKey then
                        ccbSpKey:setVisible(false)
                    end
                end
                

            end) 

        end
    end 
    -- self:waitWithDelay(0.5, function(  )
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_bouns_collect.mp3")
    -- end)
    self:waitWithDelay(1, function(  )
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_bouns_collect_toProgress.mp3")
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_bouns_collect_end.mp3")
    end)
    
    local time = 0
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.isCollect and not self:checkHasGameSelfEffectType(self.QUICKHIT_SCORE_EFFECT) then
        time = 2.5
    end
    self:waitWithDelay(time, function(  )
        effectData.p_isPlay = true
        self:playGameEffect()
    end)    
end

---------------------------------弹版----------------------------------
function CodeGameScreenLuxuryDiamondMachine:showFreeSpinStart(num,func)
    local extraData = self.m_runSpinResultData.p_fsExtraData
    if extraData and extraData.isCollect then
        local triggerJackpot = extraData.triggerJackpot
        local chooseView = util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondChooseView", triggerJackpot, function()
            gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_superFree_Show.mp3")
            local view = self:showDialog("FreeSpinStart_1",nil,function()
                self:clearCurMusicBg()
                self:showGuoChange(function()
                    self:triggerFreeSpinCallFun()
                end, function()
                    self.m_bottomUI:checkClearWinLabel()
                    if func then
                        func()
                    end
                end, true)
            end)
            for i,v in ipairs(self.JACKPOT_NAME_LIST) do
                view:findChild(v):setVisible(v == triggerJackpot[1] )
            end
            local spineBox = util_spineCreate("LuxuryDiamond_SuperFreeSpin", true, true)
            view:findChild("Node_spine"):addChild(spineBox)
            util_spinePlay(spineBox, "start_free", false)
            util_spineEndCallFunc(spineBox, "start_free", function()
                util_spinePlay(spineBox, "idle_free", true)
            end)

            
            local effectLight = util_createAnimation("LuxuryDiamond_tb_guang.csb")
            view:findChild("Node_guang"):addChild(effectLight)
            effectLight:runCsbAction("idle",true)

            self:flyMoney(view:findChild("Particle_1"))
            
        end)
        gLobalViewManager:showUI(chooseView)
    else
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_Free_show.mp3")
        local ownerlist={}
        ownerlist["m_lb_num"]=num
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,function()
            self:showFreeGuoChange(function()
                self:triggerFreeSpinCallFun()
            end, function()
                self.m_bottomUI:checkClearWinLabel()
                if func then
                    func()
                end
            end, true)
        end)
        view:setOverAniRunFunc(function()
            gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_Free_PopupPanel_back.mp3")
        end)

        self:flyMoney(view:findChild("Particle_1"))

        local effectLight = util_createAnimation("LuxuryDiamond_tb_guang.csb")
        view:findChild("Node_guang"):addChild(effectLight)
        effectLight:runCsbAction("idle",true)

        return view

        
    end
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

--过场
function CodeGameScreenLuxuryDiamondMachine:showGuoChange(callBack1,callBack2, isStart)
    if isStart then
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_superfreeGuoChang_show.mp3")
    else
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_superfreeGuoChang_end.mp3")
    end
    
    self.m_Guochang_Spine:setVisible(true)
    util_spinePlay(self.m_Guochang_Spine, "guochang3", false)
    util_spineEndCallFunc(self.m_Guochang_Spine, "guochang3", function()
        if callBack2 then 
            callBack2()
        end
        self.m_Guochang_Spine:setVisible(false)
    end)
    self:waitWithDelay(0.85, function()
        if callBack1 then 
            callBack1()
        end
    end)
end

function CodeGameScreenLuxuryDiamondMachine:showFreeGuoChange(callBack1,callBack2, isStart)
    if isStart then
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_freeGuoChang_show.mp3")
    else
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_freeGuoChang_end.mp3")
    end
    
    self.m_freeGuochang_Spine:setVisible(true)
    util_spinePlay(self.m_freeGuochang_Spine, "guochang", false)
    util_spineEndCallFunc(self.m_freeGuochang_Spine, "guochang", function()
        if callBack2 then 
            callBack2()
        end
        self.m_freeGuochang_Spine:setVisible(false)
    end)
    self:waitWithDelay(0.6, function()
        if callBack1 then 
            callBack1()
        end
    end)
end

function CodeGameScreenLuxuryDiamondMachine:stopLineMusic()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
end

-- 显示free spin
function CodeGameScreenLuxuryDiamondMachine:showEffect_FreeSpin(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
    local extraData = self.m_runSpinResultData.p_fsExtraData
    local delayTime = 2
    if extraData and extraData.isCollect then
        self.m_progress:showSuperFankui()
        self:setFsBackGroundMusic("LuxuryDiamondSounds/music_LuxuryDiamond_superFree_bg.mp3")--fs背景音乐
        delayTime = 1
    else
        -- 停掉背景音乐
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        else
            self:clearCurMusicBg()
            -- freeMore时不播放
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
        end

        local betLevel = self.m_iBetLevel or -1
        local cor_num = betLevel + 1
        for iCol = 1,cor_num do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node and self:isFixFreeSymbol(node.p_symbolType) then
                    -- node:runAnim("actionframe",false)

                    local timeLineName = "actionframe1"
                    if node.p_symbolType == self.SYMBOL_FREE1 then
                        timeLineName = "actionframe1"
                    elseif node.p_symbolType == self.SYMBOL_FREE2 then
                        timeLineName = "actionframe2"
                    elseif node.p_symbolType == self.SYMBOL_FREE3 then
                        timeLineName = "actionframe3"
                    end
                    node:setLocalZOrder(node:getLocalZOrder() + 5)
                    node:runAnim(timeLineName, false, function()
                        node:setLocalZOrder(node:getLocalZOrder() - 5)
                        -- node:runAnim("idleframe", true)
                    end)
                end
            end 
        end

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_free_trigger4.mp3")
        else
            local idx = math.random(1, 3)
            gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_free_trigger" .. idx .. ".mp3")
        end
    end
    self:waitWithDelay(delayTime, function()
        self:showFreeSpinView(effectData)
    end)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenLuxuryDiamondMachine:clickMapTipView()
    if self.m_tips then
        self:removeTips()
    else
        self:initTips()
    end
end

function CodeGameScreenLuxuryDiamondMachine:initTips()

    self.m_tips = util_createAnimation("LuxuryDiamond_tishikuang.csb")
    self:findChild("tishikuang"):addChild(self.m_tips)
    self.m_tips:playAction("start")
    self.b_showTips = true

    if self.m_tipNode and not tolua.isnull(self.m_tipNode) then
        self.m_tipNode:stopAllActions()
        performWithDelay(self.m_tipNode, function(  )
            self:removeTips()
        end, 5)
    end
end

function CodeGameScreenLuxuryDiamondMachine:removeTips()
    if  self.b_showTips == false then
        return
    end

    self.b_showTips  = false
    if self.m_tips then
        self.m_tips:playAction("over",false, function()
            self.m_tips:removeFromParent()
            self.m_tips = nil
        end, 60)
    end
end

--切换背景
function CodeGameScreenLuxuryDiamondMachine:changeBg(showType, isInit)
    if self.m_showType and showType == self.m_showType then
        return 
    end
    self.m_showType = showType
    self:findChild("reel_bg_base"):setVisible(showType == "base")
    self:findChild("reel_bg_free"):setVisible(showType == "free")
    self:findChild("reel_bg_superfree"):setVisible(showType == "super_free")

    self:findChild("freegame_guang"):setVisible(showType ~= "base")
    if showType == "base" then
        self.m_gameBg:runCsbAction("bace", true)
    elseif showType == "free" then
        self.m_gameBg:runCsbAction("Free", true)
    elseif showType == "super_free" then
        self.m_gameBg:runCsbAction("SuperFree", true)
    end
    
    self:findChild("Node_guang"):removeAllChildren()
    if showType ~= "base" then
        local anim = util_createAnimation("LuxuryDiamond_reel_guang.csb")
        self:findChild("Node_guang"):addChild(anim)
        anim:playAction("idle", true)
    end
end

function CodeGameScreenLuxuryDiamondMachine:isNormalStates( )
    
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

--isToClip 是否提层
function CodeGameScreenLuxuryDiamondMachine:MachineRule_DownAction3(slotParent, parentData, isToClip)
    local back, backTime = self:MachineRule_BackAction(slotParent, parentData, isToClip)
    local speedActionTable = {}
    local dis = self.m_configData.p_reelResDis
    local speedStart = parentData.moveSpeed
    local preSpeed = speedStart / 118
    local timeDown = backTime
    if self:getGameSpinStage() ~= QUICK_RUN then
        for i = 1, 10 do
            speedStart = speedStart - preSpeed * (11 - i) * 2
            local moveDis = dis / 10
            local time = moveDis / speedStart
            timeDown = timeDown + time
            local fix_X = isToClip and 0 or slotParent:getPositionX()
            local moveBy = cc.MoveBy:create(time, cc.p(fix_X, -moveDis))
            speedActionTable[#speedActionTable + 1] = moveBy
        end
    end

    speedActionTable[#speedActionTable + 1] = back
    return speedActionTable, timeDown
end

--isToClip 是否提层
function CodeGameScreenLuxuryDiamondMachine:MachineRule_BackAction(slotParent, parentData, isToClip)
    local fix_Y = isToClip and slotParent:getPositionY() or 0
    local back = cc.MoveTo:create(self.m_configData.p_reelResTime, cc.p(slotParent:getPositionX(), fix_Y))
    return back, self.m_configData.p_reelResTime
end

--将图标恢复到轮盘层
function CodeGameScreenLuxuryDiamondMachine:setSymbolToReel(isBet)
    for i, slotNode in ipairs(self.m_clipNode) do
        local preParent = slotNode.m_preParent
        if preParent ~= nil then
            slotNode.p_layerTag = slotNode.m_preLayerTag

            local nZOrder = slotNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder

            util_changeNodeParent(preParent, slotNode, nZOrder)
            slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)

            if isBet then
                if self.m_lineScoreNodes[slotNode] and slotNode.p_symbolType ~= 94 then
                    self.m_lineScoreNodes[slotNode] = false
                end
            else
                if slotNode.p_symbolType ~= 94 then
                    slotNode:runIdleAnim()
                end
            end
        end
    end
    self.m_clipNode = {}
end

function CodeGameScreenLuxuryDiamondMachine:getBottomUINode( )
    return "CodeLuxuryDiamondSrc.LuxuryDiamondBoottomUiView"
end

function CodeGameScreenLuxuryDiamondMachine:checkIsAddLastWinSomeEffect( )
    local  selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local notAdd  = true
    if (selfdata.lines and #selfdata.lines > 0) or (selfdata.jackpot and #selfdata.jackpot > 0) then
        notAdd = false
    end
    return notAdd
end

function CodeGameScreenLuxuryDiamondMachine:BaseMania_updateJackpotScore(index,totalBet)
    if not totalBet then
        totalBet=globalData.slotRunData:getCurTotalBet() --/ self:getCurBetLevelMulti()
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools or not jackpotPools[index] then
        return 0
    end
    if self.m_iAverageBet then
        totalBet = self.m_iAverageBet
    end
    local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index],true,totalBet)
    return totalScore
end

--服务器没有基础值初始化一份
function CodeGameScreenLuxuryDiamondMachine:updateJackpotList()
    self.m_jackpotList = {}

    local totalBet=globalData.slotRunData:getCurTotalBet()
    if self.m_iAverageBet then
        totalBet = self.m_iAverageBet
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index, poolData in pairs(jackpotPools) do
            local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData, false, totalBet)
            self.m_jackpotList[index] = totalScore - baseScore
        end
    end
end

function CodeGameScreenLuxuryDiamondMachine:initGameStatusData(gameData)
    self.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.betMulti then
        self.m_specialBetMulti = gameData.gameConfig.extra.betMulti
    end

    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.signalCredit then
        self.m_signalCredit = gameData.gameConfig.extra.signalCredit
        self.m_score_view:updateScore()
        self.m_score_detail_view:updateScore()
    end
end

function CodeGameScreenLuxuryDiamondMachine:showFreeSpinMore(num,func,isAuto)
    local betLevel = self.m_iBetLevel or -1
    local cor_num = betLevel + 1
    local end_pos = util_convertToNodeSpace(self.m_freeBar:findChild("m_lb_num_2"), self.m_effectNode)
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_freeMore_colloct.mp3")

    self:waitWithDelay(0.5,function()
        -- self:resetMusicBg()
        self.m_freeBar:showFankui()
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_freeMore_fankui.mp3")
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end)
end

--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function CodeGameScreenLuxuryDiamondMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        -- if self.m_bProduceSlots_InFreeSpin == false then
        -- end
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_ULTRAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
    end

    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true  then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_ULTRAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
    end

end

function CodeGameScreenLuxuryDiamondMachine:setSpinTounchType(isTouch)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, isTouch})
end

-- self.m_gameEffects 事件列表执行完毕时
function CodeGameScreenLuxuryDiamondMachine:playEffectNotifyNextSpinCall()
	CodeGameScreenLuxuryDiamondMachine.super.playEffectNotifyNextSpinCall( self )
	self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- 轮盘滚动停止时
function CodeGameScreenLuxuryDiamondMachine:slotReelDown()
	CodeGameScreenLuxuryDiamondMachine.super.slotReelDown(self)
	self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenLuxuryDiamondMachine:waitWithDelay(time, endFunc)
    if time <= 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

-- function CodeGameScreenLuxuryDiamondMachine:scaleMainLayer()
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
--     -- if (display.width / display.height) < (DESIGN_SIZE.width / DESIGN_SIZE.height) then
--     --     local x = display.width / DESIGN_SIZE.width
--     --     local y = display.height / DESIGN_SIZE.height
--     --     local pro = x / y
--     --     if pro > 1 then
--     --         pro = 1
--     --     end
--     --     local activity_width = 125 * pro --活动的弹板的宽度
--     --     local show_width = display.width - activity_width
--     --     local design_reel_width = 1128  --设计分辨率下棋盘的宽度
--     --     mainPosX = (show_width - mainScale * design_reel_width) / 2
--     --     mainScale  = show_width / design_reel_width - 0.016
--     -- end

--     util_csbScale(self.m_machineNode, mainScale)
--     self.m_machineRootScale = mainScale
--     self.m_machineNode:setPositionY(mainPosY)
--     self.m_machineNode:setPositionX(mainPosX)

--     self:findChild("Panel_2"):setPositionY(-mainPosY)
--     self:findChild("Panel_2"):setScale(1/mainScale)
--     self:findChild("Panel_2"):setContentSize(cc.size(display.width, display.height))

-- end

function CodeGameScreenLuxuryDiamondMachine:scaleMainLayer()
    CodeGameScreenLuxuryDiamondMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.75
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.84 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.9 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio >= 768/1370 then
        local mainScale = 0.94 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
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
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)

    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local mainPosX = 0

    self:findChild("Panel_2"):setPositionY(-mainPosY)
    self:findChild("Panel_2"):setScale(1/self.m_machineRootScale)
    self:findChild("Panel_2"):setContentSize(cc.size(display.width, display.height))
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenLuxuryDiamondMachine:checkHasGameSelfEffectType(effectType)
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

-- 重写
function CodeGameScreenLuxuryDiamondMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local extraData = self.m_runSpinResultData.p_fsExtraData or {}
        if extraData and extraData.isCollect then
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(1, parentData.cloumnIndex)
        else
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        end
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--重写
function CodeGameScreenLuxuryDiamondMachine:getSpinCostCoins()
    local betValue = CodeGameScreenLuxuryDiamondMachine.super.getSpinCostCoins(self)
    return betValue * self.p_curBetMultiply
end

--重写
-- 增加赢钱后的 效果
function CodeGameScreenLuxuryDiamondMachine:addLastWinSomeEffect() -- add big win or mega win
    local notAddEffect = self:checkIsAddLastWinSomeEffect()

    if notAddEffect then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet() * self.p_curBetMultiply
    end
    if self.m_iAverageBet then
        lTatolBetNum = self.m_iAverageBet * 4
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    -- curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

--重写
function CodeGameScreenLuxuryDiamondMachine:getWinEffect(_winAmonut)
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply
    if self.m_iAverageBet then
        lTatolBetNum = self.m_iAverageBet * 4
    end
    local winRatio = _winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end
    return winEffect
end

--重写
function CodeGameScreenLuxuryDiamondMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet() * self.p_curBetMultiply
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet() * self.p_curBetMultiply
    end
    if self.m_iAverageBet then
        lTatolBetNum = self.m_iAverageBet * 4
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
                effectData.p_effectOrder = winEffect
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
                    effectData.p_effectOrder = winEffect
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
                effectData.p_effectOrder = winEffect
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

    -- if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
    --     if winEffect ~= nil and math.random(0, 100) > 40 then
    --         local selfEffect = GameEffectData.new()
    --         selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --         selfEffect.p_effectOrder = self.BIGWINPLAY_EFFECT 
    --         self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --         selfEffect.p_selfEffectType = self.BIGWINPLAY_EFFECT
    --         self:sortGameEffects()
    --     end
    -- end
    
end

function CodeGameScreenLuxuryDiamondMachine:showBigWinPlayEffect( effectData )
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_freeGuoChang_show.mp3")

    self:shakeOneNodeForever(120/60)

    self.m_bigWinPlayAnim:setVisible(true)
    self.m_bigWinPlayAnim:runCsbAction("actionframe", false, function (  )
        self.m_bigWinPlayAnim:setVisible(false)
    end)
    self.m_bigWinPlayAnim:findChild("Particle_1"):resetSystem()
    self.m_bigWinPlayAnim:findChild("Particle_2"):resetSystem()
    self.m_bigWinPlayAnim:findChild("Particle_3"):resetSystem()
    self.m_bigWinPlayAnim:findChild("Particle_4"):resetSystem()
    self.m_bigWinPlayAnim:findChild("Particle_4_0"):resetSystem()
    performWithDelay(self, function()

        effectData.p_isPlay = true
        self:playGameEffect()

    end, 120/60)
end

-- shake
function CodeGameScreenLuxuryDiamondMachine:shakeOneNodeForever(time)
    local oldPos = cc.p(self:getPosition())
    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    self:runAction(action)

    performWithDelay(self,function()
        self:stopAction(action)
        self:setPosition(oldPos)
    end,time)
end

return CodeGameScreenLuxuryDiamondMachine






