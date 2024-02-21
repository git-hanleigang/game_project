---
-- island li
-- 2019年1月26日
-- CodeGameScreenMagneticBreakInMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "MagneticBreakInPublicConfig"
-- local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local CodeGameScreenMagneticBreakInMachine = class("CodeGameScreenMagneticBreakInMachine", BaseNewReelMachine)

CodeGameScreenMagneticBreakInMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMagneticBreakInMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  -- 自定义的小块类型
CodeGameScreenMagneticBreakInMachine.SYMBOL_SCORE_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- 磁铁红
CodeGameScreenMagneticBreakInMachine.SYMBOL_SCORE_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  -- 磁铁蓝
CodeGameScreenMagneticBreakInMachine.SYMBOL_SCORE_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3  -- bonus红
CodeGameScreenMagneticBreakInMachine.SYMBOL_SCORE_BONUS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4  -- bonus蓝
CodeGameScreenMagneticBreakInMachine.SYMBOL_SCORE_BONUS5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5  -- 开门红
CodeGameScreenMagneticBreakInMachine.SYMBOL_SCORE_BONUS6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6  -- 开门蓝


CodeGameScreenMagneticBreakInMachine.GAME_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1 -- 收集
CodeGameScreenMagneticBreakInMachine.GAME_MAGNET_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2 -- 磁铁吸bonus
CodeGameScreenMagneticBreakInMachine.GAME_BONUS_BULING = GameEffect.EFFECT_SELF_EFFECT + 3 -- 闪烁
CodeGameScreenMagneticBreakInMachine.GAME_OPENDOOR_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 5 -- 开门
CodeGameScreenMagneticBreakInMachine.GAME_FREE_MAGNET_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 6 -- 磁铁吸bonus
CodeGameScreenMagneticBreakInMachine.GAME_MAGNET_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 7 -- jackpot弹板
CodeGameScreenMagneticBreakInMachine.GAME_BONUS_RANDOM_ADD = GameEffect.EFFECT_SELF_EFFECT + 8 -- 添加

--p_storedIcons中存放的数据：values[1]：位置(1)；values[2]：分数或是free次数("1")；values[3]：类型(score或是free)；
                        --values[4]：颜色(red或是blue);values[5]：是否是jackpot(bonus或是jackpot)；values[6]：寿命

-- 构造函数
function CodeGameScreenMagneticBreakInMachine:ctor()
    CodeGameScreenMagneticBreakInMachine.super.ctor(self)
    
    self.m_spinRestMusicBG = true
    self.m_isFeatureOverBigWinInFree = true
    self.m_publicConfig = PublicConfig
    self.m_isOnceClipNode = false
    self.m_isAddBigWinLightEffect = true
    self.m_isLongRun = false
    self.m_specialBets = nil
    self.m_betLevel = nil

    self.magnetSound = nil

    self.collectBonusNum = 20
    self.bonusIndex_list = {}   --bonus可添加的节点
    self.bonus_list = {}        --bonus列表
    -- self.redBonus_list = {}        --bonus列表
    -- self.blueBonus_list = {}        --bonus列表
    self.bonusShowIndex = 1

    self.curBonusListForBet = {}

    self.randmoBonusForBet = {}
 
    self.curMagneticIndex = 0

    self.oneMagnetCoins = 0

    self.curBetCoins = 0

    self.isNearMiss = false

    self.changeLabOnce = true

    self.isInitReelSymbol = false
    --init
    self:initGame()
end

function CodeGameScreenMagneticBreakInMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("MagneticBreakInConfig.csv", "LevelMagneticBreakInConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMagneticBreakInMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MagneticBreakIn"  
end

function CodeGameScreenMagneticBreakInMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --特效节点
    self.m_effect = cc.Node:create()
    self:findChild("root"):addChild(self.m_effect,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    self.m_effect1 = cc.Node:create()
    self:findChild("root"):addChild(self.m_effect1,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    self.randomNode = cc.Node:create()
    self:addChild(self.randomNode)

    self.initBonusListNode = cc.Node:create()
    self:addChild(self.initBonusListNode)
    
    self:initFreeSpinBar() -- FreeSpinbar

    --jackpotBar
    self.m_jackpotBar = util_createView("CodeMagneticBreakInSrc.MagneticBreakInJackPotBarView")
    self.m_jackpotBar:initMachine(self)
    self:findChild("jackpot"):addChild(self.m_jackpotBar)

    --触发压暗
    self.m_triggerFsDark = util_createAnimation("MagneticBreakIn_qipan_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_triggerFsDark)

    self.m_spineGuochang = util_spineCreate("MagneticBreakIn_guochang1", true, true)
    self.m_spineGuochang:setScale(self.m_machineRootScale)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang:setVisible(false)

    self.m_spineGuochang2 = util_spineCreate("MagneticBreakIn_guochang2", true, true)
    self:addChild(self.m_spineGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_spineGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang2:setVisible(false)

    self.noClickLayer = util_createAnimation("MagneticBreakIn_NoClick.csb")
    self:addChild(self.noClickLayer, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.noClickLayer:setPosition(display.width * 0.5, display.height * 0.5)
    self.noClickLayer:setVisible(false)

    self.m_bonusYuGao = util_spineCreate("Socre_MagneticBreakIn_9",true,true)
    self:findChild("Node_yuGao"):addChild(self.m_bonusYuGao)
    self.m_bonusYuGao:setVisible(false)

    self.bigWinEffect = util_spineCreate("MagneticBreakIn_bigwin", true, true)
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
    self:findChild("root"):addChild(self.bigWinEffect)
    self.bigWinEffect:setPosition(cc.p(pos.x,(pos.y + 15)))
    self.bigWinEffect:setVisible(false)

    local endNode = self.m_bottomUI.coinWinNode
    self.m_totalWin = util_createAnimation("MagneticBreakIn_totalwin.csb")
    endNode:addChild(self.m_totalWin)
    self.m_totalWin:setPositionY(-10)

    self:addCiTieNode()

    self:showBaseAllUI()

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMagneticBreakInMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end


    return false -- 用作延时点击spin调用
end


--添加黑色遮罩用于滚动
function CodeGameScreenMagneticBreakInMachine:createBlackLayer()
    self.m_colorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        local offY = 122
        if i == 1 or i == 5 then
            offY = 122-34
        else
            offY = 122
        end
        local colNodeName = "sp_reel_" .. (i - 1)
        local size = self:findChild("reel_base_" .. (i - 1)):getContentSize()
        local parentData = self.m_slotParents[i]
        local mask = cc.LayerColor:create(cc.c3b(0,0,0), size.width, size.height):hide()
        mask:setOpacity(200)
        local posX = self.m_csbOwner[colNodeName]:getPositionX()
        local posY = self.m_csbOwner[colNodeName]:getPositionY()
        mask:setPosition(cc.p(posX,posY + offY))
        self.m_clipParent:addChild(mask, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20)
        self.m_colorLayers[i] = mask
    end
end

function CodeGameScreenMagneticBreakInMachine:showColorLayer(bfade)
    for i,v in ipairs(self.m_colorLayers) do
        v:show()
        if bfade then
            v:setOpacity(0)
            v:runAction(cc.FadeTo:create(0.3, 200))
        else   
            v:setOpacity(200)
        end
    end
end

function CodeGameScreenMagneticBreakInMachine:hideColorLayer(bfade)
    for i,v in ipairs(self.m_colorLayers) do
        if bfade then
            v:runAction(cc.Sequence:create(cc.FadeTo:create(0.3,0),cc.CallFunc:create(function(p)
                p:hide()
            end)))
        else 
            v:setOpacity(0) v:hide()
        end
    end
end

function CodeGameScreenMagneticBreakInMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    local fadeAct = cc.FadeTo:create(0.3, 0)
    local func = cc.CallFunc:create( function()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

function CodeGameScreenMagneticBreakInMachine:initFreeSpinBar()
    local parent = self:findChild("FreeSpinBar")
    self.m_freeSpinBar = util_createView("CodeMagneticBreakInSrc.MagneticBreakInFreespinBarView")
    parent:addChild(self.m_freeSpinBar)
    util_setCsbVisible(self.m_freeSpinBar, false)
    self.m_freeSpinBar:setPosition(0, 0)
end

function CodeGameScreenMagneticBreakInMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.music_MagneticBreakIn_enter)

    end,0.4,self:getModuleName())
end

function CodeGameScreenMagneticBreakInMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagneticBreakInMachine.super.onEnter(self)     -- 必须调用不予许删除

    self:addObservers()
    self:upateBetLevel()
    local betCoin = globalData.slotRunData:getCurTotalBet()
    self.curBetCoins = betCoin
    local curBonusListForBet =  self:getBonusForCurBet(false)
    self:initCollectBonus(curBonusListForBet)
end

function CodeGameScreenMagneticBreakInMachine:addObservers()
    CodeGameScreenMagneticBreakInMachine.super.addObservers(self)
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
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = self.m_publicConfig.SoundConfig["sound_MagneticBreakIn_win_line_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = self.m_publicConfig.SoundConfig["sound_MagneticBreakIn_fs_win_line_"..soundIndex] 
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
        --切换bet显示不同收集bonus
        local betCoin = globalData.slotRunData:getCurTotalBet()
        if self.curBetCoins ~= betCoin then
            self.curBetCoins = betCoin
            local curBonusListForBet =  self:getBonusForCurBet(false)
            self:initCollectBonus(curBonusListForBet)
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,"SHOW_BONUS_MAP")
end

function CodeGameScreenMagneticBreakInMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagneticBreakInMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    self:bonusRandom(false)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMagneticBreakInMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MagneticBreakIn_10"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS1 then
        return "Socre_MagneticBreakIn_Bonus3"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS2 then
        return "Socre_MagneticBreakIn_Bonus4"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS3 then
        return "Socre_MagneticBreakIn_Bonus1"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS4 then
        return "Socre_MagneticBreakIn_Bonus2"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS5 then
        return "Socre_MagneticBreakIn_Bonus5"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS6 then
        return "Socre_MagneticBreakIn_Bonus6"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMagneticBreakInMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMagneticBreakInMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS6,count =  2}

    return loadNode
end

-- 断线重连 
function CodeGameScreenMagneticBreakInMachine:MachineRule_initGame(  )
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeAllUI()
    else
        self:showBaseAllUI()
    end
end

--[[
    检测是否已经有大赢
]]
function CodeGameScreenMagneticBreakInMachine:checkHasBigWin()
    local isHaveBigWin = false
    isHaveBigWin = isHaveBigWin or self:checkHasGameEffectType(GameEffect.EFFECT_DELAY_SHOW_BIGWIN)
    isHaveBigWin = isHaveBigWin or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN)
    isHaveBigWin = isHaveBigWin or self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
    isHaveBigWin = isHaveBigWin or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
    return isHaveBigWin
end


--
--单列滚动停止回调
--
function CodeGameScreenMagneticBreakInMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenMagneticBreakInMachine.super.slotOneReelDown(self,reelCol) 
    self:reelStopHideMask(reelCol)
    --期待感动画
        for iCol = 1,reelCol do
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if not tolua.isnull(symbolNode) then
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if isTriggerLongRun and symbolNode.m_currAnimName ~= "idleframe3" then
                            symbolNode:runAnim("idleframe3",true)
                        end
                    end
                    
                end
            end
        end
    if not self.m_isLongRun then
        self.m_isLongRun = isTriggerLongRun
    end
    return isTriggerLongRun
end

function CodeGameScreenMagneticBreakInMachine:beginReel()
    self.m_isLongRun = false
    self.isInitReelSymbol = false
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:showColorLayer(true)
    else
        self.m_triggerFsDark:runCsbAction("start")
    end
    
    
    CodeGameScreenMagneticBreakInMachine.super.beginReel(self)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:upDateBonusIndex()
    end
    
end


function CodeGameScreenMagneticBreakInMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenMagneticBreakInMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if self:checkSymbolBulingAnimPlay(_slotNode) then
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
                
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                if self:isShowLongRun(_slotNode) then
                    
                else
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
end

function CodeGameScreenMagneticBreakInMachine:isShowLongRun(_slotNode)
    local reelCol = _slotNode.p_cloumnIndex
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN ) then
            return true
        end
    elseif self:isBonusSymbolNode(_slotNode) then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --获取磁铁最终颜色
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local magneticColor = selfData.magneticColor or nil
            if magneticColor == "red" then
                if _slotNode.p_symbolType ~= self.SYMBOL_SCORE_BONUS3 then
                    return true
                end
            elseif magneticColor == "blue" then
                if _slotNode.p_symbolType ~= self.SYMBOL_SCORE_BONUS4 then
                    return true
                end
            end
        end
        
    end
    return false
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenMagneticBreakInMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isLongRun and _slotNode.p_cloumnIndex < self.m_iReelColumnNum then
            if _slotNode.m_currAnimName ~= "idleframe3" then
                _slotNode:runAnim("idleframe3",true)
            end
        else
            _slotNode:runAnim("idleframe")
        end
    else
        _slotNode:runAnim("idleframe2",true)
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMagneticBreakInMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMagneticBreakInMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end

-- 显示paytableview 界面
function CodeGameScreenMagneticBreakInMachine:showPaytableView()
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

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMagneticBreakInMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collect = selfData.collect                        
    local collectBonusIndex = selfData.collectBonusIndex    --base收集
    local magneticAttract = selfData.magneticAttract        --base磁铁吸
    local doubleCollect = selfData.doubleCollect            --free开门
    local bonusCollect = selfData.bonusCollect              --free磁铁吸
    local jackpotInfo = selfData.jackpotInfo              --jackpot
    local randomAddBonus = selfData.randomAddBonus or {}          --随机添加
    if self.bonus_list then
        
    end

    if collect and table_length(collect) then               --每次spin刷新bet列表
        self.curBonusListForBet = collect
    end
    

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and table_length(randomAddBonus) > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_BONUS_RANDOM_ADD
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_BONUS_RANDOM_ADD -- 动画类型
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_BONUS_BULING
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_BONUS_BULING -- 动画类型
    end
     

    if collectBonusIndex and table_length(collectBonusIndex) > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_COLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_COLLECT_EFFECT -- 动画类型
    end
    if magneticAttract and table_length(magneticAttract) > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_MAGNET_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_MAGNET_EFFECT -- 动画类型
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --开门
        if doubleCollect and table_length(doubleCollect) > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.GAME_OPENDOOR_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.GAME_OPENDOOR_EFFECT -- 动画类型
        end
        --大磁铁吸
        if bonusCollect and table_length(bonusCollect) > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.GAME_FREE_MAGNET_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.GAME_FREE_MAGNET_EFFECT -- 动画类型
        end
    end
    --展示jackpot
    if jackpotInfo and table_length(jackpotInfo) > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_MAGNET_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_MAGNET_JACKPOT_EFFECT -- 动画类型
    end
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMagneticBreakInMachine:MachineRule_playSelfEffect(effectData)
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collect = selfData.collect
    local collectBonusIndex = selfData.collectBonusIndex    --base收集
    local magneticAttract = selfData.magneticAttract        --base磁铁吸
    local doubleCollect = selfData.doubleCollect            --free开门
    local bonusCollect = selfData.bonusCollect              --free磁铁吸
    local jackpotInfo = selfData.jackpotInfo              --jackpot
    local randomAddBonus = selfData.randomAddBonus         --随机添加

    if effectData.p_selfEffectType == self.GAME_BONUS_RANDOM_ADD then
        self:showBonusTriggerYuGao(function ()
            self:randomAddNewBonus(randomAddBonus,function ()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end
    if effectData.p_selfEffectType == self.GAME_COLLECT_EFFECT then
        self:addNewBonusCollectByShow(collectBonusIndex,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    end
    if effectData.p_selfEffectType == self.GAME_BONUS_BULING then
        self:showBonusBulingOrHide(function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    end
    if effectData.p_selfEffectType == self.GAME_MAGNET_EFFECT then
        self:bonusRandom(false)
        self.addScoreNum = 0
        self:absorbBonusForBase(1,magneticAttract,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    end
    if effectData.p_selfEffectType == self.GAME_OPENDOOR_EFFECT then
        self:showOpenDoorEffect(1,doubleCollect,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    if effectData.p_selfEffectType == self.GAME_FREE_MAGNET_EFFECT then
        
        self:absorbBonusForFree(bonusCollect,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    if effectData.p_selfEffectType == self.GAME_MAGNET_JACKPOT_EFFECT then
        self.showJackpotIndex = 1
        self:showJackpotWinView(jackpotInfo,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
-- function CodeGameScreenMagneticBreakInMachine:MachineRule_ResetReelRunData()
--     --self.m_reelRunInfo 中存放轮盘滚动信息
 
-- end

function CodeGameScreenMagneticBreakInMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMagneticBreakInMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    
    
end

function CodeGameScreenMagneticBreakInMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(node) and node.p_symbolType then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    if node.m_currAnimName == "idleframe3" then
                        node:runAnim("idleframe")
                    end
                end
            end
        end
    end
    
    self:hideColorLayer(false)
    CodeGameScreenMagneticBreakInMachine.super.slotReelDown(self)
end

function CodeGameScreenMagneticBreakInMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenMagneticBreakInMachine:initNoneFeature()
    self.isInitReelSymbol = true
    CodeGameScreenMagneticBreakInMachine.super.initNoneFeature(self)
    
end


function CodeGameScreenMagneticBreakInMachine:showBaseAllUI()
    self.m_gameBg:findChild("Node_1"):setVisible(true)
    self.m_gameBg:findChild("Node_2"):setVisible(false)
    self.m_gameBg:runCsbAction("idle",true)
    self.m_freeSpinBar:setVisible(false)
    self.bigMagnet:setVisible(false)
    self:findChild("Node_bonus"):setVisible(true)
    self.m_freeSpinBar.m_freespinCurrtTimes = 0
    self.m_freeSpinBar.m_freespinTotalTimes = 0
end

function CodeGameScreenMagneticBreakInMachine:showFreeAllUI()
    self.m_gameBg:findChild("Node_1"):setVisible(false)
    self.m_gameBg:findChild("Node_2"):setVisible(true)
    self.m_freeSpinBar:setVisible(true)
    self.bigMagnet:setVisible(true)
    util_spinePlay(self.bigMagnet, "idleframe3", true)
    self.bigMagnet.m_csbNode:findChild("BitmapFontLabel_1"):setString("")
    self:findChild("Node_bonus"):setVisible(false)
    
end

function CodeGameScreenMagneticBreakInMachine:updateBottomUICoins(_endCoins,isNotifyUpdateTop,_playWinSound,isPlayAnim,beiginCoins)
    local params = {_endCoins,isNotifyUpdateTop,isPlayAnim,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenMagneticBreakInMachine:checkNotifyUpdateWinCoin()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local magneticAttract = selfData.magneticAttract or {}       --base磁铁吸
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if magneticAttract and table_length(magneticAttract) > 0 and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop,nil,self.addScoreNum})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end

    
end

--[[
    延迟回调
]]
function CodeGameScreenMagneticBreakInMachine:delayCallBack(time, func)
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


----------------------------- 玩法处理 -----------------------------------
--[[
    @desc: 根据寿命判断闪烁和消失
    author:{author}
    time:2023-04-13 14:27:22
    @return:
]]
function CodeGameScreenMagneticBreakInMachine:showBonusBulingOrHide(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local magneticAttract = selfData.magneticAttract or {}       --base磁铁吸
    local collect = self.curBonusListForBet or selfData.collect                        --根据寿命判断闪烁和消失
    local betCoin = globalData.slotRunData:getCurTotalBet()
    local waitTime = 0
    if magneticAttract and table_length(magneticAttract) > 0 then
        waitTime = 10/30
    end 
    local collectList = collect[tostring(toLongNumber(betCoin))]
    -- print("11111:".. json.encode(a))
    local bulingList = {}
    local hideList = {}
    if collect and table_length(collect) > 0 then
        if collectList then
            for i,v in ipairs(collectList) do
                if v[6] <= 0 then                           --消失
                    hideList[#hideList + 1] = i
                elseif v[6] == 1 or v[6] == 2 then                       --闪烁
                    bulingList[#bulingList + 1] = i
                end
            end
        end
    end
    --寿命等于1时，闪烁
    for i,v in ipairs(bulingList) do
        local bonus = self.bonus_list[v]
        if not tolua.isnull(bonus) and bonus.bonusSpine then
            if not bonus.isShan then
                bonus.isShan = true
                util_spinePlay(bonus.bonusSpine, "over_idle",true)
            end
        end
    end

    --寿命小于等于0时，移除
    for i,v in ipairs(hideList) do
        for j,node in ipairs(self.bonus_list) do
            if node.index and v == node.index and node.bonusSpine then
                table.remove( self.bonus_list, j )
                util_spinePlay(node.bonusSpine, "over",false)
                util_setCascadeOpacityEnabledRescursion(node.bonusSpine, true)
                util_setCascadeColorEnabledRescursion(node.bonusSpine, true)
                local posIndex = node.posIndex
                self:findChild("bonus_"..posIndex).isAdd = true
                self:delayCallBack(10/30,function ()
                    if posIndex then
                        local children = self:findChild("bonus_"..posIndex):getChildren()
                        for k,_node in pairs(children) do
                            if not tolua.isnull(_node) then
                                _node:removeFromParent()
                            end
                        end
                    end 
                end)
                break
            end
        end
    end

    -- self:delayCallBack(10/30,function ()
        self:upDateBonusIndex()
        if #self.bonus_list == 0 and #collectList ~= 0 then
            self:showBonusTriggerYuGao(function()
                --随机新的bonus展示  并发给服务器
                local curBonusListForBet =  self:getBonusForCurBet(true)
                -- self:initCollectBonus(curBonusListForBet)
                self:randomAddNewBonus(curBonusListForBet,function ()
                    if type(func) == "function" then
                        func()
                    end
                end)
                
            end)
        else
            if type(func) == "function" then
                func()
            end
        end
    -- end)
    
end

--[[
    @desc: 随机展示收集区域bonus效果
    author:{author}
    time:2023-04-13 14:31:13
    @return:
]]
function CodeGameScreenMagneticBreakInMachine:getBonusItems()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collect = self.curBonusListForBet or selfData.collect                        --根据寿命判断闪烁和消失
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local hideOrBulingList = {}
    if collect and table_length(collect) > 0 then
        if collect[tostring(betCoin)] then
            for i,v in ipairs(collect[tostring(betCoin)]) do
                if v[6] > 2 then                           
                    hideOrBulingList[#hideOrBulingList + 1] = i
                end
            end
        end
    end
    return hideOrBulingList
end

function CodeGameScreenMagneticBreakInMachine:bonusRandom(isRandom)
    if isRandom then
        if self.m_randomRemindAction == nil then
            self.m_randomRemindAction = schedule(self.randomNode, function()
                self:randomRemindAnim()
            end, 3)
        end
    else
        if self.m_randomRemindAction then
            self:stopAction(self.m_randomRemindAction)
            self.m_randomRemindAction = nil
        end
    end
    
end

--随机抖动
function CodeGameScreenMagneticBreakInMachine:randomRemindAnim()
    local bonusItemsIndex = self:getBonusItems()
    if #bonusItemsIndex <= 0 then
        return
    end
    
    local randomNum = math.random(2, 3)
    for index = 1, randomNum, 1 do
        local randIndex = math.random(1,#bonusItemsIndex)
        local randItemIndex = bonusItemsIndex[randIndex]
        if randItemIndex then
            local randItem = self.bonus_list[randItemIndex]
            if not tolua.isnull(randItem) and randItem.index and  randItem.bonusSpine then
                util_spinePlay(randItem.bonusSpine, "idleframe4")
            end
        end
    end
end

function CodeGameScreenMagneticBreakInMachine:upDateBonusIndex()
    for i,v in ipairs(self.bonus_list) do
        if v and v.index then
            v.index = i
        elseif v and not v.index then
            table.remove( self.bonus_list, i )
        end
    end
end

--[[
    @desc: free下出现开门图标，相同颜色进行成倍
    author:{author}
    time:2023-04-13 14:32:52
    --@collectList: 
    @return:
]]
--开门图标数量
function CodeGameScreenMagneticBreakInMachine:getOpenDoorNum()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local doubleCollect = selfData.doubleCollect            --free开门
    local doorColor = nil
    if doubleCollect and table_length(doubleCollect) then
        if table_length(doubleCollect) == 2 then
            return 2,doorColor
        elseif table_length(doubleCollect) == 1 then
            doorColor = doubleCollect[1][3]
            return 1,doorColor
        else
            return 0,doorColor
        end
    else
        return 0,doorColor
    end
end

--棋盘是否掉落双色图标
function CodeGameScreenMagneticBreakInMachine:isHaveTwoColorForReel()
    local function getList(doorColor)
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local infoList = {}
        for i,v in ipairs(storedIcons) do
            local values = storedIcons[i]
            if values[4] == doorColor then
                return true
            end
        end
        return false
    end
    local redList = getList("red")
    local blueList = getList("blue")
    if redList and blueList then
        return true
    else
        return false
    end
end

--开门 ：下标、倍数、颜色
function CodeGameScreenMagneticBreakInMachine:showOpenDoorEffect(index,doubleCollect,func)
    if index > #doubleCollect then
        if type(func) == "function" then
            func()
        end
        return
    end

    if not doubleCollect[index] then
        if type(func) == "function" then
            func()
        end
        return
    end

    local doorIndex = doubleCollect[index][1]
    local doorMultiple = tonumber(doubleCollect[index][2])
    local doorColor = doubleCollect[index][3]
    --在p_storedIcons获取小块信息
    local infoList = self:getSymbolInfoForOpenDoor(doorColor)
    local doorSymbol = self:getSymbolByPosIndex(doorIndex)
    local ccbNode = doorSymbol:getCCBNode()
    if not ccbNode then
        doorSymbol:checkLoadCCbNode()
    end
    ccbNode = doorSymbol:getCCBNode()
    if ccbNode then
        if tonumber(doorMultiple) == 2 then
            ccbNode.m_spineNode:setSkin("X2")
        elseif tonumber(doorMultiple) == 3 then
            ccbNode.m_spineNode:setSkin("X3")
        elseif tonumber(doorMultiple) == 4 then
            ccbNode.m_spineNode:setSkin("X4")
        elseif tonumber(doorMultiple) == 5 then
            ccbNode.m_spineNode:setSkin("X5")
        end 
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_openDoor)
    doorSymbol:runAnim("start")
    
    self:delayCallBack(40/30,function ()
        self:showOpenDoorEffectIndex(1,doorIndex,doorMultiple,doorColor,infoList,function ()
            index = index + 1
            self:showOpenDoorEffect(index,doubleCollect,func)
        end)
    end)
    
    
end

function CodeGameScreenMagneticBreakInMachine:showOpenDoorEffectIndex(index,doorIndex,doorMultiple,doorColor,infoList,func)
    if index > #infoList then
        if type(func) == "function" then
            func()
        end
        return
    end
    local endNode = self:getSymbolByPosIndex(infoList[index][1])
    if endNode then
        local doorSymbol = self:getSymbolByPosIndex(doorIndex)
        local endPos = util_convertToNodeSpace(endNode,self.m_effect)
        local startPos = util_convertToNodeSpace(doorSymbol,self.m_effect)
        
        --触发动画
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_openDoor_toBonus)
        doorSymbol:runAnim("actionframe")
        --飞粒子
        self:runFlyLineAct(startPos, endPos,doorColor,function ()
            --bonus反馈
            --下一轮
            endNode:runAnim("actionframe")
            if endNode.m_csbNode then
                self:showBonusSymbolForMultiple(index,doorMultiple,endNode,infoList)
            end
            self:delayCallBack(1,function ()
                index = index + 1
                self:showOpenDoorEffectIndex(index,doorIndex,doorMultiple,doorColor,infoList,func)
            end)
            
        end)
    end
    
    
    
end

function CodeGameScreenMagneticBreakInMachine:showBonusSymbolForMultiple(index,doorMultiple,endNode,infoList)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local num = tonumber(infoList[index][2])
    local type = infoList[index][3]
    local jackpotType = infoList[index][5]
    local csbNode = endNode.m_csbNode
    local multiple = tonumber(doorMultiple)
    csbNode:runCsbAction("actionframe")
    if type == "score" then
        if self:isJackpotType(jackpotType) then
            self:showAddMultipleJackpotNodeForSymbol(jackpotType,csbNode)
            csbNode:findChild("m_lb_num"):setString("X"..multiple)
            csbNode:findChild("m_lb_num_dark"):setString("X"..multiple)
        else
            local score = num * lineBet * multiple
            csbNode:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
            csbNode:findChild("m_lb_coins_dark"):setString(util_formatCoins(score, 3))
        end
    else
        csbNode:findChild("m_lb_num2"):setString(num * multiple)
        csbNode:findChild("m_lb_num_dark2"):setString(num * multiple)
    end
end

--开门展示成倍时飞粒子
function CodeGameScreenMagneticBreakInMachine:runFlyLineAct(startPos, endPos,doorColor,func)
    --计算旋转角度
    local rotation = util_getAngleByPos(startPos, endPos)
    --计算两点之间距离
    local distance = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    -- -- 创建粒子
    local flyNode = util_createAnimation("MagneticBreakIn_chengbei_dianliu.csb")
    if doorColor == "red" then
        flyNode:findChild("Node_1"):setVisible(true)
        flyNode:findChild("Node_2"):setVisible(false)
    else
        flyNode:findChild("Node_1"):setVisible(false)
        flyNode:findChild("Node_2"):setVisible(true)
    end
    self.m_effect:addChild(flyNode, 100)
    flyNode:setPosition(startPos)
    flyNode:setRotation(-rotation)
    flyNode:setScaleX(distance / 270)

    flyNode:runCsbAction(
        "actionframe",
        false,
        function()
            if not tolua.isnull(flyNode) then
                flyNode:removeFromParent()
            end
        end
    )
    self:delayCallBack(0.25,function ()
        if func then
            func()
        end
    end)

end

--获取成倍时棋盘小块信息
function CodeGameScreenMagneticBreakInMachine:getSymbolInfoForOpenDoor(doorColor)
    local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local infoList = {}
    for i,v in ipairs(storedIcons) do
        local values = storedIcons[i]
        if values[4] == doorColor then
            if values[3] ~= "redMultiple" and values[3] ~= "blueMultiple" then
                infoList[#infoList + 1] = values
            end
            
        end
    end
    return infoList
end

--[[
    @desc: bonus收集相关  数据分别为：位置、分数、bonus类型、颜色、是否是jackpot、寿命
    author:{author}
    time:2023-03-27 14:42:13
    --@node: 
    @return:
]]
function CodeGameScreenMagneticBreakInMachine:initCollectBonus( collectList )
    self.initBonusListNode:stopAllActions()

	self:resetAllCollectIndexBonus()
    
    self:addNewBonusCollectForInit(collectList)

    self:delayCallBack(0.5,function ()
        self:bonusRandom(true)
    end)
    
end

--清理所有的收集区域bonus
function CodeGameScreenMagneticBreakInMachine:resetAllCollectIndexBonus(  )
	self.bonusIndex_list = {}
    self:bonusRandom(false)
    self.m_effect1:removeAllChildren()
    for i,_node in ipairs(self.bonus_list) do
        table.remove( self.bonus_list, i )
        self:upDateBonusIndex()
        if not tolua.isnull(_node) then
            _node:removeFromParent()
        end
    end

    self.bonus_list = {}

    for i=1,self.collectBonusNum do
        self.bonusIndex_list[i] = i
        self:findChild("bonus_"..i).isAdd = true
        local children = self:findChild("bonus_"..i):getChildren()
        for k,_node in pairs(children) do
            if not tolua.isnull(_node) then
                _node:removeFromParent()
            end
        end
    end
    randomShuffle(self.bonusIndex_list)

    
end

--进入游戏时添加bonus到收集区域
function CodeGameScreenMagneticBreakInMachine:addNewBonusCollectForInit( list )
	local bonusNum = table_length(list)
    for i=1,bonusNum do
        
        for j,v in ipairs(self.bonusIndex_list) do
            if self:findChild("bonus_"..v).isAdd then
                local bonus = self:createBonusForCollect(list[i],true)
                if bonus and bonus.bonusSpine then
                    local bonusLife = list[i][6] or 6
                    bonus.posIndex = v
                    bonus.index = #self.bonus_list + 1
                    self:findChild("bonus_" .. v):addChild(bonus)
                    self:findChild("bonus_"..v).isAdd = false
                    self.bonus_list[#self.bonus_list + 1] = bonus
                    local bonusType = bonus.showType or "score"
                    local actScaleIndex = self:getScaleForBonusType(bonusType)
                    bonus:setScale(actScaleIndex)
                    util_spinePlay(bonus.bonusSpine, "start")
                    util_setCascadeOpacityEnabledRescursion(bonus.bonusSpine, true)
                    util_setCascadeColorEnabledRescursion(bonus.bonusSpine, true)
                    performWithDelay(self.initBonusListNode,function ()
                        if not tolua.isnull(bonus) and bonus.bonusSpine then
                            if bonusLife > 2 then
                                util_spinePlay(bonus.bonusSpine, "idleframe5")
                            else
                                util_spinePlay(bonus.bonusSpine, "over_idle",true)
                            end
                        end
                    end,5/30)
                    break
                end
            end
        end
    end
end

--展示bonus压黑
function CodeGameScreenMagneticBreakInMachine:showReelBonusDark(symbolNode)
    if not self:isBonusSymbolNode(symbolNode) then
        return
    end
    if symbolNode then
        symbolNode:runAnim("dark")
        if symbolNode.m_csbNode then
            symbolNode.m_csbNode:runCsbAction("dark")
        end
    end
end

function CodeGameScreenMagneticBreakInMachine:addNewBonusCollectForRandom(addIndex, list,func )
	local bonusNum = table_length(list)
    if addIndex > bonusNum then
        if type(func) == "function" then
            func()
        end
    
        return
    end

    if list[addIndex] then
        for j,v in ipairs(self.bonusIndex_list) do
            if self:findChild("bonus_"..v).isAdd then
                local bonus = self:createBonusForCollect(list[addIndex],true)
                if bonus and bonus.bonusSpine then
                    local bonusLife = list[addIndex][6] or 6
                    bonus.posIndex = v
                    bonus.index = #self.bonus_list + 1
                    self:findChild("bonus_" .. v):addChild(bonus)
                    local bonusY = self:findChild("bonus_" .. v):getPositionY()
                    bonus:setPositionY(1000)
                    self:findChild("bonus_"..v).isAdd = false
                    self.bonus_list[#self.bonus_list + 1] = bonus
                    local bonusType = bonus.showType or "score"
                    local actScaleIndex = self:getScaleForBonusType(bonusType)
                    bonus:setScale(actScaleIndex)
                    if bonus.bonusSpine then
                        util_spinePlay(bonus.bonusSpine, "idleframe5")
                    end
                    
                    --下降并播拖尾
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_bonus_down)
                    if bonus.bonusTuoWei then
                        bonus.bonusTuoWei:setVisible(true)
                        local particle = bonus.bonusTuoWei:findChild("Particle_1")
                        if particle then
                            particle:setDuration(-1)     --设置拖尾时间(生命周期)
                            particle:setPositionType(0)   --设置可以拖尾
                            particle:resetSystem()
                        end
                        bonus.bonusTuoWei:runCsbAction("fly")
                    end
                    bonus:runAction(cc.EaseSineIn:create(cc.MoveTo:create(20/60,cc.p(0,0))))
                    performWithDelay(self.initBonusListNode,function ()
                        if particle then
                            particle:stopSystem()--移动结束后将拖尾停掉
                        end
                    end,20/60)
                    performWithDelay(self.initBonusListNode,function ()
                        if not tolua.isnull(bonus) and bonus.bonusTuoWei then
                            bonus.bonusTuoWei:setVisible(false)
                        end
                    end,1)
                    break
                end
            end
        end
    end
    

    self:delayCallBack(0.1,function ()
        addIndex = addIndex + 1
        self:addNewBonusCollectForRandom(addIndex,list,func)
    end)
    
end

function CodeGameScreenMagneticBreakInMachine:randomAddNewBonus(list,func)
    self:addNewBonusCollectForRandom(1,list,func)
end

--收集bonus时是否有jackpot
function CodeGameScreenMagneticBreakInMachine:isHaveJackpotBonus(list)
    for i,v in ipairs(list) do
        local nodeType,nodeScore,nodeColor = self:getBonusTypeForCollect(v)
        if self:isJackpotType(nodeType) then
            return true
        end
    end
    return false
end

--收集新出的bonus到收集区域
function CodeGameScreenMagneticBreakInMachine:addNewBonusCollectByShow( list,func )
	local bonusNum = table_length(list)
    local isHaveJackpot = self:isHaveJackpotBonus(list)
    for i=1,bonusNum do
        
        for j,v in ipairs(self.bonusIndex_list) do
            if self:findChild("bonus_"..v).isAdd then
                local bonus = self:createBonusForCollect(list[i],false)
                
                local flyBonus = self:createBonusForCollect(list[i],false)
                flyBonus.m_csbNode:setVisible(false)
                local startNode = self:getSymbolByPosIndex(list[i])
		        local startPos = util_convertToNodeSpace(startNode,self.m_effect1)
		        local endPos = util_convertToNodeSpace(self:findChild("bonus_" .. v),self.m_effect1)
		        self.m_effect1:addChild(flyBonus)
		        flyBonus:setPosition(startPos)
                if bonus and bonus.bonusSpine then
                    bonus.posIndex = v
                    bonus.index = #self.bonus_list + 1
                    self:findChild("bonus_" .. v):addChild(bonus)
                    self:findChild("bonus_"..v).isAdd = false
                    self.bonus_list[#self.bonus_list + 1] = bonus
                    local bonusType = bonus.showType or "score"
                    local actScaleIndex = self:getScaleForBonusType(bonusType)
                    bonus:setScale(actScaleIndex)
                    bonus:setVisible(false)
                    if i == 1 then
                        if isHaveJackpot then
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_jPbonus_fly)
                        else
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_bonus_fly)
                        end
                        
                    end
                    self:flyBonusForFeature(startNode,flyBonus,startPos,endPos,function ()
                        if not tolua.isnull(flyBonus) then
                            flyBonus:removeFromParent()
                        end
                        bonus:setVisible(true)
                        util_spinePlay(bonus.bonusSpine, "idleframe5")
                        -- util_changeNodeParent(self:findChild("bonus_" .. v),bonus)
                        -- bonus:setPosition(cc.p(0,0))
                    end)
                    break
                end
            end
        end
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local magneticAttract = selfData.magneticAttract        --base磁铁吸
    if magneticAttract and table_length(magneticAttract) > 0  then
        self:delayCallBack(1,function ()
            if type(func) == "function" then
                func()
            end
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
	
end

--根据不同类型获取不同缩放
function CodeGameScreenMagneticBreakInMachine:getScaleForBonusType(type)
    if type == "score" then
        return 1
    elseif type == "free" then
        return 1.2
    else
        return 1.2
    end
end

function CodeGameScreenMagneticBreakInMachine:magneticCollectOver(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collect = selfData.collect  
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local jackpotInfo = selfData.jackpotInfo              --jackpot
    self.m_bottomUI:notifyTopWinCoin()
    globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount
    --刷新赢钱
    if #self.m_runSpinResultData.p_winLines == 0 and #jackpotInfo == 0 then
        if self:checkHasBigWin() == false then
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.GAME_MAGNET_EFFECT)
        end
    end
    --判断收集区域是否无bonus
    if collect and table_length(collect[tostring(betCoin)]) == 0 then
        self:showBonusTriggerYuGao(function()
            --随机新的bonus展示  并发给服务器
            local curBonusListForBet =  self:getBonusForCurBet(true)
            self:randomAddNewBonus(curBonusListForBet,function ()
                --彻底吸完了！！！！
                if type(func) == "function" then
                    func()
                end
            end)
        end)
    else
        --彻底吸完了！！！！
        if type(func) == "function" then
            func()
        end
        self.m_bottomUI.m_changeLabJumpTime = nil
        self:delayCallBack(2,function ()
            self:bonusRandom(true)
        end)
        
    end
end

--吸收bonus（base下）
function CodeGameScreenMagneticBreakInMachine:absorbBonusForBase(moveIndex,magneticAttract,func)
    if moveIndex > #magneticAttract then
        self:magneticCollectOver(func)
        return
    end
    if not magneticAttract[moveIndex] then
        self:magneticCollectOver(func)
        return
    end
    self.isFirstIndexForMagnet = true
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local curBonusListForBet =  self.curBonusListForBet[tostring(betCoin)] 
    local magneticIndex = magneticAttract[moveIndex][1]
    local magneticColor = magneticAttract[moveIndex][2]
    local magneticCoins = magneticAttract[moveIndex][3]
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collect = selfData.collect
    local collect1 = collect[tostring(betCoin)]
    self.oneMagnetCoins = 0
    --创建新的磁铁用来播放吸收
    local tempMagneticNode,tempSpineNode,templightWave = self:createTempMagneticNode(magneticIndex,magneticColor)
    local realSymbolNode = self:getSymbolByPosIndex(magneticIndex)
    local endPos = util_convertToNodeSpace(realSymbolNode,self.m_effect)
    if realSymbolNode then
        realSymbolNode:setVisible(false)
    end
    --压暗
    self.m_triggerFsDark:runCsbAction("start",false,function ()
        self.m_triggerFsDark:runCsbAction("idle")
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_Magnetic_trigger)
    --触发动画
    util_spinePlay(tempSpineNode, "actionframe",false)
    self:showRotateForRow(tempMagneticNode,magneticIndex)

    self:delayCallBack(50/60,function ()
        util_spinePlay(tempSpineNode, "idleframe3",true)
        util_spinePlay(templightWave, "start",false)
        local tempList = self:getBonusForColor(magneticColor)
        for i,bonus in ipairs(tempList) do
            if not tolua.isnull(bonus) and bonus.showType and bonus.bonusSpine then
                if bonus.showType == "score" then
                    
                    util_spinePlay(bonus.bonusSpine, "shouji2_1",true)
                elseif bonus.showType == "free" then
                    bonus:runCsbAction("shouji2_2",true)
                    util_spinePlay(bonus.bonusSpine, "shouji2_2",true)
                else
                    bonus:runCsbAction("shouji2_3",true)
                    util_spinePlay(bonus.bonusSpine, "shouji2_3",true)
                end
            end
        end
        self:delayCallBack(1,function ()
            util_spinePlay(templightWave, "idle",true)
            local tempListNum = #tempList
            self.m_bottomUI.m_changeLabJumpTime = 0.2
            self:absorbBonusForMove(1,tempListNum,tempList,tempSpineNode,tempMagneticNode,endPos,function ()
                --磁铁over
                if not tolua.isnull(templightWave) then
                    util_spinePlay(templightWave, "over",false)
                    util_spineEndCallFunc(templightWave, "over", function ()
                        self:delayCallBack(0.1,function ()
                            templightWave:removeFromParent()
                        end)
                    end)
                end
                
                self:delayCallBack(25/30,function ()
                    self.m_triggerFsDark:runCsbAction("over")
                    util_spinePlay(tempSpineNode, "over2",false)
                    self:delayCallBack(15/30,function ()
                        --吸收完显示钱数并且真是小块也显示钱数
                        if realSymbolNode then
                            local csbNode = realSymbolNode.m_csbNode
                            if csbNode then

                                local score = magneticCoins
                                score = util_formatCoins(score, 3)
                                csbNode:findChild("m_lb_coins"):setString(score)
                                self:updateLabelSize({label = csbNode:findChild("m_lb_coins"),sx = 1,sy = 1},134)
                                csbNode:runCsbAction("idleframe")
                            end
                            realSymbolNode:setVisible(true)
                        end
                        if not tolua.isnull(tempMagneticNode) then
                            tempMagneticNode:removeFromParent()
                        end
                        moveIndex = moveIndex + 1
                        self:absorbBonusForBase(moveIndex,magneticAttract,func)
                    end) 
                end)
            end)
        end)
                
    end)
end

--磁铁收jackpotbonus时的钱数
function CodeGameScreenMagneticBreakInMachine:getJackpotCoins(bonusType)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotInfo = selfData.jackpotInfo or {}             --jackpot
    local coins = 0
    if #jackpotInfo <= 0 then
        return 0
    end
    for i,v in ipairs(jackpotInfo) do
        local index = jackpotInfo[i][1]
        if index == bonusType then
            coins = tonumber(jackpotInfo[i][2])
            break
        end
    end
    return coins
end

--磁铁收bonus间隔时间
function CodeGameScreenMagneticBreakInMachine:getMoveTime(bonus2)
    if tolua.isnull(bonus2) then
        return 0.4
    end
    if not tolua.isnull(bonus2) and bonus2.showType and bonus2.showType == "score" then
        return 0.2
    end
    return 0.4
end

function CodeGameScreenMagneticBreakInMachine:absorbBonusForMove(moveIndex,tempListNum,bonusList,tempSpineNode,tempMagneticNode,endPos,func)
    if moveIndex > tempListNum or table_length(bonusList) == 0 then
        if type(func) == "function" then
            func()
        end
        return
    end

    local bonus = bonusList[1]
    local bonus2 = bonusList[2]
    local waitTime = self:getMoveTime(bonus2)

    if not tolua.isnull(bonus) and bonus.bonusSpine then
        local bonusScore = tonumber(bonus.nodeScore) or 1
        local bonusType = bonus.showType or "score"
        local index = bonus.index
        table.remove( bonusList, 1 )
        table.remove( self.bonus_list, index )
        self:upDateBonusIndex()
        local posIndex = bonus.posIndex
        if posIndex then
            self:findChild("bonus_"..posIndex).isAdd = true
        end
        local pos = util_convertToNodeSpace(bonus,self.m_effect)

        --切换父节点
        util_changeNodeParent(self.m_effect,bonus)
        bonus:setPosition(pos)
        local children = self:findChild("bonus_"..posIndex):getChildren()
        
        for k,_node in pairs(children) do
            if not tolua.isnull(_node) then
                _node:removeFromParent()
            end
        end
        
        local scale = cc.ScaleTo:create(0.5, 1) -- 这个系数需要调整
        local move = cc.EaseSineIn:create(cc.MoveTo:create(0.5,endPos))
        local fanKuiFunc = cc.CallFunc:create(function ()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_Magnetic_collect)
        end)
        local act_move = cc.Spawn:create(scale, move)
        local act = cc.Sequence:create(act_move,fanKuiFunc)
        bonus:runAction(act)
            
        self:delayCallBack(waitTime,function ()
            moveIndex = moveIndex + 1
            self:absorbBonusForMove(moveIndex,tempListNum,bonusList,tempSpineNode,tempMagneticNode,endPos,func)
        end)

        self:delayCallBack(0.5,function ()
            local index = bonus.index
            util_spinePlay(bonus.bonusSpine, "over",false)
            util_setCascadeOpacityEnabledRescursion(bonus.bonusSpine, true)
            util_setCascadeColorEnabledRescursion(bonus.bonusSpine, true)
            util_spineEndCallFunc(bonus.bonusSpine, "over", function()
                self:delayCallBack(0.1,function ()
                    if not tolua.isnull(bonus) then
                        bonus:removeFromParent()
                    end
                end)
            end)
    
            local spineZi = tempMagneticNode.m_csbNode
            if spineZi and bonusType ~= "free" then
                spineZi:runCsbAction("actionframe2")
                local lineBet = globalData.slotRunData:getCurTotalBet()
                local score = bonusScore * lineBet + self.oneMagnetCoins
                local allScore = bonusScore * lineBet + self.addScoreNum
                if bonusType == "grand" or bonusType == "mega" or bonusType == "major" then
                    local coins = self:getJackpotCoins(bonusType)
                    if coins > 0 then
                        score = coins + self.oneMagnetCoins
                        allScore = coins + self.addScoreNum
                    end
                end
                local scoreStr = util_formatCoins(score, 3)
                if self.isFirstIndexForMagnet then
                    self.isFirstIndexForMagnet = false
                    spineZi:runCsbAction("actionframe")
                else
                    spineZi:runCsbAction("actionframe2")
                end
                
                spineZi:findChild("m_lb_coins"):setString(scoreStr)
                self:updateLabelSize({label = spineZi:findChild("m_lb_coins"),sx = 1,sy = 1},134)
                --刷新钱
                globalData.slotRunData.lastWinCoin = allScore
                self:updateBottomUICoins(allScore,true,true,true,self.addScoreNum)
                self.m_totalWin:runCsbAction("actionframe")
                self.addScoreNum = allScore
                self.oneMagnetCoins = score
            end  
            
            util_spinePlay(tempSpineNode, "actionframe2",false)
        end)

    else
        moveIndex = moveIndex + 1
        self:absorbBonusForMove(moveIndex,tempListNum,bonusList,tempSpineNode,tempMagneticNode,endPos,func)
    end
    
end


--吸收bonus（free下）
--下标、分数
function CodeGameScreenMagneticBreakInMachine:absorbBonusForFree(bonusCollect,func)
    local time = self.isNearMiss and 2 or 0

    if self.isNearMiss then
        if self.curMagneticIndex == 1 then
            util_spinePlay(self.bigMagnet, "fight1_1")
            util_spineEndCallFunc(self.bigMagnet, "fight1_1",function()
                util_spinePlay(self.bigMagnet, "idleframe3", true)
            end)
        elseif self.curMagneticIndex == 2 then
            util_spinePlay(self.bigMagnet, "fight1_2")
            util_spineEndCallFunc(self.bigMagnet, "fight1_2",function()
                util_spinePlay(self.bigMagnet, "idleframe3", true)
            end)
        end
        self.curMagneticIndex = 0
        self.isNearMiss = false
    end
    self:delayCallBack(time,function ()
        self.magnetSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_bonus_collect,true)
        if self.curMagneticIndex == 1 then
            util_spinePlay(self.bigMagnet, "shouji1")
            util_spineEndCallFunc(self.bigMagnet, "shouji1",function()
                util_spinePlay(self.bigMagnet, "shouji1_idleframe", true)
            end)
        elseif self.curMagneticIndex == 2 then
            util_spinePlay(self.bigMagnet, "shouji2")
            util_spineEndCallFunc(self.bigMagnet, "shouji2",function()
                util_spinePlay(self.bigMagnet, "shouji2_idleframe", true)
            end)
        else
            util_spinePlay(self.bigMagnet, "shouji3")
            util_spineEndCallFunc(self.bigMagnet, "shouji3",function()
                util_spinePlay(self.bigMagnet, "shouji3_idleframe", true)
            end)
        end
        --待触发抖动
        self:freeCollectBonusTrigger(bonusCollect)
        self:delayCallBack(time + 1,function ()
            self.absorbBonusIndexForFreeCoins = 0
            self.isFirstIndex = true
            self:delayCallBack(0.5,function ()
                self:absorbBonusForFreeIndex(1,bonusCollect,func)
            end)
        end)
    end)
    
    
end

function CodeGameScreenMagneticBreakInMachine:freeCollectBonusTrigger(bonusCollect)
    for i,v in ipairs(bonusCollect) do
        local bonusSymbolIndex = bonusCollect[i][1] or 5         --下标
        local bonusSymbol = self:getSymbolByPosIndex(tonumber(bonusSymbolIndex))
        bonusSymbol:runAnim("idleframe3",true)
    end
end

function CodeGameScreenMagneticBreakInMachine:absorbBonusForFreeIndex(index,bonusCollect,func)
    if index > #bonusCollect then
        if self.curMagneticIndex == 1 then
            util_spinePlay(self.bigMagnet, "shouji1_over")
        elseif self.curMagneticIndex == 2 then
            util_spinePlay(self.bigMagnet, "shouji2_over")
        else
            util_spinePlay(self.bigMagnet, "shouji3_over")
        end

        self:delayCallBack(0.5,function ()
            if self.magnetSound then
                gLobalSoundManager:stopAudio(self.magnetSound)
                self.magnetSound = nil
            end
            if self.curMagneticIndex == 1 then
                util_spinePlay(self.bigMagnet, "idleframe1",true)
            elseif self.curMagneticIndex == 2 then
                util_spinePlay(self.bigMagnet, "idleframe2",true)
            else
                util_spinePlay(self.bigMagnet, "idleframe3",true)
            end
        end)
        
        --无连线时：吸完主动刷新赢钱
        local winLines = self.m_reelResultLines
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local jackpotInfo = selfData.jackpotInfo              --jackpot
        if #winLines <= 0 and #jackpotInfo == 0 then
            -- 如果freespin 未结束，不通知左上角玩家钱数量变化
            local isNotifyUpdateTop = true
            if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
                isNotifyUpdateTop = false
            end
            if self:checkHasBigWin() == false then
                self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin,self.GAME_FREE_MAGNET_EFFECT)
            end
            self:updateBottomUICoins(self.m_iOnceSpinLastWin,isNotifyUpdateTop,true,true)
        end
        
        self:delayCallBack(5/30,function ()
            --彻底吸完了！！！！
            if type(func) == "function" then
                func()
            end
        end)
        
        return
    end
    local bonusSymbolIndex = bonusCollect[index][1] or 5         --下标
    local bonusSymbolCoins = bonusCollect[index][2] or 1         --分数、次数、倍数
    local bonusSymbolType = bonusCollect[index][3]  or "score"         --类型
    local isJackpot = bonusCollect[index][4] or "bonus"                --是否jackpot
    local bonusSymbol = self:getSymbolByPosIndex(tonumber(bonusSymbolIndex))
    local ciTieCsb = self.bigMagnet.m_csbNode

    local bonus = self:createBonusCollectForFree(bonusSymbolIndex,bonusSymbolCoins,bonusSymbolType,isJackpot)
    bonus.m_csbNode:setVisible(false)
    local startPos = util_convertToNodeSpace(bonusSymbol,self.m_effect)
    local endPos = util_convertToNodeSpace(self:findChild("Node_qian"),self.m_effect)
    self.m_effect:addChild(bonus)
    bonus:setPosition(startPos)
    if bonus then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_magnet_lighing)
        self:flyBonusForFeature(bonusSymbol,bonus,startPos,endPos,function ()
            self:delayCallBack(0.2,function ()
                if not tolua.isnull(bonus) then
                    bonus:removeFromParent()
                end
            end)
            self:delayCallBack(0.1,function ()
                if ciTieCsb then
                    self:changeCiTieStr(ciTieCsb,bonusSymbolCoins,bonusSymbolType,isJackpot)
                end
            end)
        end)
    end
    self:delayCallBack(0.5,function ()
        index = index + 1
        self:absorbBonusForFreeIndex(index,bonusCollect,func)
    end)
    
end

function CodeGameScreenMagneticBreakInMachine:changeCiTieStr(ciTieCsb,bonusSymbolCoins,bonusSymbolType,jackpotType)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local function changeStr()
        if bonusSymbolType == "score" then
            if self:isJackpotType(jackpotType) then
                local index = self:getJackpotIndexForStr(jackpotType)
                local value = self:BaseMania_updateJackpotScore(index)
                local score = tonumber(bonusSymbolCoins)* value + self.absorbBonusIndexForFreeCoins
                self.absorbBonusIndexForFreeCoins = score
                local scoreStr = util_formatCoins(score, 3)
                ciTieCsb:findChild("BitmapFontLabel_1"):setString(scoreStr)
            else
                local score = tonumber(bonusSymbolCoins)* lineBet + self.absorbBonusIndexForFreeCoins
                self.absorbBonusIndexForFreeCoins = score
                local scoreStr = util_formatCoins(score, 3)
                ciTieCsb:findChild("BitmapFontLabel_1"):setString(scoreStr)
            end
        else
            
        end
    end
    
    if self.isFirstIndex then
        self.isFirstIndex = false
        changeStr()
        ciTieCsb:runCsbAction("actionframe")
    else
        ciTieCsb:runCsbAction("actionframe2")
        changeStr()
        
    end
end

--创建临时bonus
function CodeGameScreenMagneticBreakInMachine:createBonusCollectForFree( bonusSymbolIndex,bonusSymbolCoins,bonusSymbolType,jackpotType )
    local bonus = nil
    local nodeType = nil
    local nodeScore = nil
    local nodeColor = nil
    local lineBet = globalData.slotRunData:getCurTotalBet()

    nodeType,nodeScore,nodeColor = self:getBonusTypeForCollect(bonusSymbolIndex) --获取分数（网络数据）
    
    if nodeColor == "red" then
        bonus = util_spineCreate("Socre_MagneticBreakIn_Bonus1", true, true)
    else
        bonus = util_spineCreate("Socre_MagneticBreakIn_Bonus2", true, true)
    end
    local csbNode = util_createAnimation("Socre_MagneticBreakIn_Bonus12_zi.csb")
    if bonusSymbolType == "score" then
        if self:isJackpotType(jackpotType) then
            csbNode:findChild("Node_coins"):setVisible(false)
            csbNode:findChild("Node_fg"):setVisible(false)
            csbNode:findChild("Node_jackpot"):setVisible(true)
            if tonumber(bonusSymbolCoins) > 1 then
                self:showAddMultipleJackpotNodeForSymbol(jackpotType,csbNode)
                csbNode:findChild("m_lb_num"):setString("X"..tonumber(bonusSymbolCoins))
                csbNode:findChild("m_lb_num_dark"):setString("X"..tonumber(bonusSymbolCoins))
            else
                self:showJackpotNodeForSymbol(jackpotType,csbNode)
            end
            
        else
            csbNode:findChild("Node_coins"):setVisible(true)
            csbNode:findChild("Node_fg"):setVisible(false)
            csbNode:findChild("Node_jackpot"):setVisible(false)
            local score = tonumber(bonusSymbolCoins) * lineBet
            csbNode:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
            csbNode:findChild("m_lb_coins_dark"):setString(util_formatCoins(score, 3))
        end
    else    --free次数
        csbNode:findChild("Node_coins"):setVisible(false)
        csbNode:findChild("Node_fg"):setVisible(true)
        csbNode:findChild("Node_jackpot"):setVisible(false)
        csbNode:findChild("m_lb_num2"):setString(tonumber(bonusSymbolCoins))
        csbNode:findChild("m_lb_num_dark2"):setString(tonumber(bonusSymbolCoins))
    end
    csbNode:runCsbAction("idleframe")
    util_spineRemoveSlotBindNode(bonus,"zi_guadian")
    self:util_spinePushBindNode(bonus,"zi_guadian",csbNode)
    bonus.m_csbNode = csbNode
	return bonus
end

function CodeGameScreenMagneticBreakInMachine:isJackpotType(nodeType)
    if nodeType == "grand" or nodeType == "mega" or nodeType == "major" or nodeType == "minor" or nodeType == "mini" then
        return true
    end
    return false
end

--根据颜色获取收集区域的bonus
function CodeGameScreenMagneticBreakInMachine:getBonusForColor(magneticColor)
    local function sortList(tempList)
        table.sort(tempList,function (a,b)
            local typeA = a.typeIndex or 1
            local typeB = b.typeIndex or 1
            local scoreA = tonumber(a.nodeScore) or 0.5
            local scoreB = tonumber(b.nodeScore) or 0.5
            if typeA ~= typeB then
                return a.typeIndex < b.typeIndex
            else
                return scoreA < scoreB
            end
        end)
    end
    
    local tempList = {}
    for i,v in ipairs(self.bonus_list) do
        if v.color and v.color == magneticColor then
            tempList[#tempList + 1] = v
        end
    end
    sortList(tempList)
    return tempList
end

--创建新的磁铁(用做base下收集)
function CodeGameScreenMagneticBreakInMachine:createTempMagneticNode(magneticIndex,magneticColor)
    local tempCsbNode = nil
    local tempSpineNode = nil
    local templightWave = nil

    if magneticColor == "red" then
        tempCsbNode = util_createAnimation("Socre_MagneticBreakIn_Bonus3dian.csb")
        tempSpineNode = util_spineCreate("Socre_MagneticBreakIn_Bonus3", true, true)
        templightWave = util_spineCreate("Socre_MagneticBreakIn_Bonus3", true, true)
    else
        tempCsbNode = util_createAnimation("Socre_MagneticBreakIn_Bonus4dian.csb")
        tempSpineNode = util_spineCreate("Socre_MagneticBreakIn_Bonus4", true, true)
        templightWave = util_spineCreate("Socre_MagneticBreakIn_Bonus4", true, true)
    end

    local csbNode = util_createAnimation("Socre_MagneticBreakIn_Bonus34_zi.csb")
    csbNode:findChild("Node_coins"):setVisible(true)
    csbNode:findChild("Node_fg"):setVisible(false)
    csbNode:findChild("Node_jackpot"):setVisible(false)
    csbNode:findChild("m_lb_coins"):setString("")
    self:updateLabelSize({label = csbNode:findChild("m_lb_coins"),sx = 1,sy = 1},134)
    tempCsbNode:findChild("Node_zi"):addChild(csbNode)
    csbNode:runCsbAction("idleframe")
    tempCsbNode.m_csbNode = csbNode

    tempCsbNode:findChild("Node_1"):addChild(tempSpineNode,2)
    -- tempCsbNode:findChild("Node_1"):addChild(templightWave,1)
    
    local posNode = self:getSymbolByPosIndex(magneticIndex)
    local pos = util_convertToNodeSpace(posNode,self:findChild("Node_yuGao"))
    self:findChild("Node_yuGao"):addChild(tempCsbNode)
    tempCsbNode:setPosition(pos)

    local posWave = util_convertToNodeSpace(tempCsbNode:findChild("Node_1"),self:findChild("Node_yugao"))
    self:findChild("Node_yugao"):addChild(templightWave)
    --cc.p(posWave.x + 50,posWave.y - 20)
    templightWave:setPosition(posWave)

    
    util_spinePlay(templightWave, "wu",false)
    return tempCsbNode,tempSpineNode,templightWave
end

--根据行数不同播旋转
function CodeGameScreenMagneticBreakInMachine:showRotateForRow(tempMagneticNode,magneticIndex)
    if not tempMagneticNode or not magneticIndex then
        return
    end
    --磁铁所在行数
    local posData = self:getRowAndColByPos(magneticIndex)
    local iRow = posData.iX
    if iRow == 1 then
        tempMagneticNode:runCsbAction("zhuan1",false,function ()
            tempMagneticNode:runCsbAction("zhuan1_idle")
        end)
    elseif iRow == 2 then
        tempMagneticNode:runCsbAction("zhuan2",false,function ()
            tempMagneticNode:runCsbAction("zhuan2_idle")
        end)
    else
        tempMagneticNode:runCsbAction("zhuan3",false,function ()
            tempMagneticNode:runCsbAction("zhuan3_idle")
        end)
    end
end

--飞临时bonus到磁铁
function CodeGameScreenMagneticBreakInMachine:flyBonusForFeature( startNode,flyBonus,startPos,endPos,func )
	util_changeNodeParent(self.m_effect1,flyBonus)
    flyBonus:setPosition(startPos)
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        util_spinePlay(flyBonus, "shouji2")
    else
        util_spinePlay(flyBonus.bonusSpine, "shouji")
    end

    if startNode then
        self:showReelBonusDark(startNode)
    end
    --
    local act_move = cc.EaseSineIn:create(cc.MoveTo:create(12/30,endPos))
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local bonusType = flyBonus.showType or "score"
        local actScaleIndex = self:getScaleForBonusType(bonusType)
        local scale = cc.ScaleTo:create(12/30, actScaleIndex)
        local move = cc.EaseSineOut:create(cc.BezierTo:create(12/30,{cc.p(startPos.x-50 , startPos.y), cc.p(startPos.x - 50, endPos.y), endPos}))
        if startPos.x > endPos.x then
            move = cc.EaseSineOut:create(cc.BezierTo:create(0.5,{cc.p(startPos.x+50 , startPos.y), cc.p(startPos.x + 50, endPos.y), endPos}))
        end
        act_move = cc.Spawn:create(scale, move)
    end

    local actList = {}
    actList[#actList + 1] = act_move
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            util_spinePlay(flyBonus.bonusSpine, "idleframe5")
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if type(func) == "function" then
            func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    flyBonus:runAction(sq)
end

function CodeGameScreenMagneticBreakInMachine:getCollectIndex(startPosX,endPosX)
    if startPosX > endPosX then
        return 1
    else
        return 2
    end
end

function CodeGameScreenMagneticBreakInMachine:getShowTypeIndex(nodeType)
    if nodeType == "score" then
        return 1
    elseif nodeType == "free" then
        return 7
    elseif nodeType == "mini" then
        return 2
    elseif nodeType == "minor" then
        return 3
    elseif nodeType == "major" then
        return 4
    elseif nodeType == "mega" then
        return 5
    elseif nodeType == "grand" then
        return 6
    else
        return 1
    end
end

--创建临时bonus
function CodeGameScreenMagneticBreakInMachine:createBonusForCollect( list,isInit )
    if isInit and list[6] <= 0 then
        return nil
    end
    local bonusSpine = nil
    local nodeType = nil
    local nodeScore = nil
    local nodeColor = nil
    if isInit then
        nodeType,nodeScore,nodeColor = self:getBonusTypeForInitCollect(list)
    else
        nodeType,nodeScore,nodeColor = self:getBonusTypeForCollect(list) --获取分数（网络数据）
    end
    local bonusTemp = util_createAnimation("MagneticBreakIn_jinbi.csb")
    if nodeColor == "red" then
        bonusSpine = util_spineCreate("Socre_MagneticBreakIn_Bonus1", true, true)
    else
        bonusSpine = util_spineCreate("Socre_MagneticBreakIn_Bonus2", true, true)
    end
    local bonusTuoWei = util_createAnimation("MagneticBreakIn_xialuo_tuowei.csb")
    bonusTemp:findChild("Node_1"):addChild(bonusSpine)
    bonusTemp:findChild("Node_2"):addChild(bonusTuoWei)
    bonusTuoWei:setVisible(false)
    bonusTemp.bonusTuoWei = bonusTuoWei
    bonusTemp.bonusSpine = bonusSpine
    self:addCsbToSymbolNodeForCollect(bonusTemp,nodeType,nodeScore)
    bonusTemp.color = nodeColor
    bonusTemp.showType = nodeType
    bonusTemp.typeIndex = self:getShowTypeIndex(nodeType)
    bonusTemp.nodeScore = nodeScore
    
	return bonusTemp
end

--jackpot/分数/free  
--获取p_storedIcons中的数据用来创建飞行bonus
function CodeGameScreenMagneticBreakInMachine:getBonusTypeForCollect(index)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local type = "score"
    local score = 1
    local color = "red"
    for i,v in ipairs(storedIcons) do
        local values = storedIcons[i]
        if tonumber(values[1]) == index then
            if values[5] == "bonus" then
                score = values[2]
                type = values[3]
                color = values[4]
            else
                type = values[5]
                score = values[2]
                color = values[4]
            end
        end
    end
    return type,score,color
end

--jackpot/分数/free  
function CodeGameScreenMagneticBreakInMachine:getBonusTypeForInitCollect(list)
    local type = "score"
    local score = 1
    local color = "red"
    if table_length(list) > 0 then
        if list[5] == "bonus" then
            score = list[2]
            type = list[3]
            color = list[4]
        else
            type = list[5]
            score = list[2]
            color = list[4]
        end
    end
    
    return type,score,color
end

--收集的node 添加csb
function CodeGameScreenMagneticBreakInMachine:addCsbToSymbolNodeForCollect(bonusTemp,nodeType,nodeScore)
    local csbNode = util_createAnimation("Socre_MagneticBreakIn_Bonus12_zi.csb")
    if nodeType == "score" then
        csbNode:findChild("Node_coins"):setVisible(true)
        csbNode:findChild("Node_fg"):setVisible(false)
        csbNode:findChild("Node_jackpot"):setVisible(false)
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local score = nodeScore * lineBet
        score = util_formatCoins(score, 3)
        csbNode:findChild("m_lb_coins"):setString(score)
        csbNode:findChild("m_lb_coins_dark"):setString(score)
    elseif nodeType == "free" then
        csbNode:findChild("Node_coins"):setVisible(false)
        csbNode:findChild("Node_fg"):setVisible(true)
        csbNode:findChild("Node_jackpot"):setVisible(false)
        csbNode:findChild("m_lb_num2"):setString(tonumber(nodeScore))
        csbNode:findChild("m_lb_num_dark2"):setString(tonumber(nodeScore))
        
    elseif self:isJackpotType(nodeType)  then
        csbNode:findChild("Node_coins"):setVisible(false)
        csbNode:findChild("Node_fg"):setVisible(false)
        csbNode:findChild("Node_jackpot"):setVisible(true)
        self:showJackpotNodeForSymbol(nodeType,csbNode)
    end
    local spineNode = bonusTemp.bonusSpine
    util_spineRemoveSlotBindNode(spineNode,"zi_guadian")
    self:util_spinePushBindNode(spineNode,"zi_guadian",csbNode)
    bonusTemp.m_csbNode = csbNode
end

--展示大磁铁效果，在停轮之前
function CodeGameScreenMagneticBreakInMachine:showBigMagnetChangeForFree(func)

    self.bigMagnet.m_csbNode:runCsbAction("over",false,function ()
        self.bigMagnet.m_csbNode:findChild("BitmapFontLabel_1"):setString("")
    end)

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local magneticColor = selfData.magneticColor or nil
    local function getFightName(index)
        local num = math.random( 1,2 )
        if index == 1 then
            if num > 1 then
                return "fight1_0"
            else
                return "fight1"
            end
        elseif index == 2 then
            if num > 1 then
                return "fight2_0"
            else
                return "fight2"
            end
        else
            if num > 1 then
                return "fight3_0"
            else
                return "fight3"
            end
        end
    end
    if magneticColor then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_magnetic_showChoose)
        if magneticColor == "red" then          --红色
            self.curMagneticIndex = 1
            local name = getFightName(1)
            util_spinePlay(self.bigMagnet, name)
            util_spineEndCallFunc(self.bigMagnet, name,function()
                util_spinePlay(self.bigMagnet, "idleframe1", true)
            end)
        elseif magneticColor == "blue" then     --蓝色
            self.curMagneticIndex = 2
            local name = getFightName(2)
            util_spinePlay(self.bigMagnet, name)
            util_spineEndCallFunc(self.bigMagnet, name,function()
                util_spinePlay(self.bigMagnet, "idleframe2", true)
            end)
        elseif magneticColor == "redAndBlue" then                               --红蓝(判断是否nearMiss)
            if self:isHaveTwoColorForReel() then        --是否有双色的bonus
                local doorNum,doorColor = self:getOpenDoorNum()
                if doorNum == 2 then--都成倍
                    self.isNearMiss = true
                    local randomColor = math.random(1,2)
                    if randomColor == 1 then
                        self.curMagneticIndex = 1
                        local name = getFightName(1)
                        util_spinePlay(self.bigMagnet, name)
                        util_spineEndCallFunc(self.bigMagnet, name,function()
                            util_spinePlay(self.bigMagnet, "idleframe1", true)
                        end)
                    else
                        self.curMagneticIndex = 2
                        local name = getFightName(2)
                        util_spinePlay(self.bigMagnet, name)
                        util_spineEndCallFunc(self.bigMagnet, name,function()
                            util_spinePlay(self.bigMagnet, "idleframe2", true)
                        end)
                    end
                elseif doorNum == 1 then--有一种成倍
                    local randomColor = math.random(1,2)
                    if randomColor == 1 then
                        self.isNearMiss = true
                        if doorColor then
                            if doorColor == "red" then      --红色则显示蓝色
                                self.curMagneticIndex = 2
                                local name = getFightName(2)
                                util_spinePlay(self.bigMagnet, name)
                                util_spineEndCallFunc(self.bigMagnet, name,function()
                                    util_spinePlay(self.bigMagnet, "idleframe2", true)
                                end)
                            else                            --蓝色则显示红色
                                self.curMagneticIndex = 1
                                local name = getFightName(1)
                                util_spinePlay(self.bigMagnet, name)
                                util_spineEndCallFunc(self.bigMagnet, name,function()
                                    util_spinePlay(self.bigMagnet, "idleframe1", true)
                                end)
                            end
                        end
                    else
                        self.curMagneticIndex = 0
                        local name = getFightName(0)
                        util_spinePlay(self.bigMagnet, name)
                        util_spineEndCallFunc(self.bigMagnet, name,function()
                            util_spinePlay(self.bigMagnet, "idleframe3", true)
                        end)
                    end
                else
                    self.curMagneticIndex = 0
                    local name = getFightName(0)
                    util_spinePlay(self.bigMagnet, name)
                    util_spineEndCallFunc(self.bigMagnet, name,function()
                        util_spinePlay(self.bigMagnet, "idleframe3", true)
                    end)
                end
            else
                self.curMagneticIndex = 0
                local name = getFightName(0)
                util_spinePlay(self.bigMagnet, name)
                util_spineEndCallFunc(self.bigMagnet, name,function()
                    util_spinePlay(self.bigMagnet, "idleframe3", true)
                end)
            end
        else 
            util_spinePlay(self.bigMagnet, "idleframe3", true)
        end
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
end

--添加free中的磁铁
function CodeGameScreenMagneticBreakInMachine:addCiTieNode()
    self.bigMagnet = util_spineCreate("MagneticBreakIn_citie", true, true)
    local pos = util_convertToNodeSpace(self:findChild("Node_fg_citie"),self.m_clipParent)
    self.m_clipParent:addChild(self.bigMagnet,800)
    self.bigMagnet:setPosition(pos)
    -- self:findChild("Node_fg_citie"):addChild(self.bigMagnet)
    local csbNode = util_createAnimation("MagneticBreakIn_citie.csb")
    csbNode:findChild("BitmapFontLabel_1"):setString("")
    util_spineRemoveSlotBindNode(self.bigMagnet,"shuzi")
    self:util_spinePushBindNode(self.bigMagnet,"shuzi",csbNode)
    self.bigMagnet.m_csbNode = csbNode
    self.bigMagnet:setVisible(false)
end

function CodeGameScreenMagneticBreakInMachine:getTempScatterForTrigger(node)
    local iCol = node.p_cloumnIndex
    local iRow = node.p_rowIndex
    local nodeIndex = self:getPosReelIdx(iRow, iCol)
    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newStartPos = self.m_effect:convertToNodeSpace(startPos)
    local newBonusSpine = util_spineCreate("Socre_MagneticBreakIn_Scatter",true,true)
    self.m_effect:addChild(newBonusSpine)
    newBonusSpine:setPosition(newStartPos)
    local zOder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    newBonusSpine:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - node.p_rowIndex)
    return newBonusSpine
end

-- 显示free spin
function CodeGameScreenMagneticBreakInMachine:showEffect_FreeSpin(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local triggerFreeMode = selfData.triggerFreeMode
    local tempScatter = {}
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        if triggerFreeMode == "scatterTrigger" then
            self.m_beInSpecialGameTrigger = true
    
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
            
    
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
            self.m_triggerFsDark:runCsbAction("start",false,function ()
                self.m_triggerFsDark:runCsbAction("idle")
            end)
            --触发动画
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_scatter_freeTrigger)
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if not tolua.isnull(node) and node.p_symbolType then
                        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            node:setVisible(false)
                            node:changeParentToOtherNode(self.m_clipParent)
                            local newBonusSpine = self:getTempScatterForTrigger(node)
                            tempScatter[#tempScatter + 1] = newBonusSpine
                            util_spinePlay(newBonusSpine, "actionframe", false)
                        end
                    end
                end
            end
            self:delayCallBack(5,function ()
                self.m_triggerFsDark:runCsbAction("over")
                --压黑结束在显示真正的图标
                self:delayCallBack(0.5,function ()
                    for i,v in ipairs(tempScatter) do
                        if not tolua.isnull(v) then
                            v:removeFromParent()
                        end
                    end
                    tempScatter = {}
                    for iCol = 1, self.m_iReelColumnNum do
                        for iRow = 1, self.m_iReelRowNum do
                            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                            if not tolua.isnull(node) and node.p_symbolType then
                                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                                    node:setVisible(true)
                                    node:runAnim("idleframe")
                                end
                            end
                        end
                    end
                    self:showFreeSpinView(effectData)
                end)
            end)
        else
            self:showFreeSpinView(effectData)
        end
    else
        self:showFreeSpinView(effectData)
    end
    
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end
function CodeGameScreenMagneticBreakInMachine:triggerFreeSpinCallFun()
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
function CodeGameScreenMagneticBreakInMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_spin_more)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            view:findChild("root"):setScale(self.m_machineRootScale)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:bonusRandom(false)
                self:resetMusicBg(nil,"MagneticBreakInSounds/music_MagneticBreakIn_free_bg.mp3")
                self:showGuochang2(function ()
                    self:showFreeAllUI()
                    self.m_freeSpinBar:changeFreeSpinByCount()
                end,function ()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)     
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFSView()    
    end,0.5)

    

end

function CodeGameScreenMagneticBreakInMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    self:delayCallBack(0.2,function ()
           gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_view_showStart)     
    end)
    local view = nil
    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_click)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_view_showOver)
    end)
    return view
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

--无赢钱
function CodeGameScreenMagneticBreakInMachine:showNoWinView(func)
    self:clearCurMusicBg()
    local view = self:showDialog("NoWin", nil, func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenMagneticBreakInMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("MagneticBreakInSounds/music_MagneticBreakIn_over_fs.mp3")
   self:clearCurMusicBg()
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    if globalData.slotRunData.lastWinCoin > 0 then
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:showGuochang(function ()
                    self:showBaseAllUI()
                    self:bonusRandom(true)
                end,function ()
                    self:triggerFreeSpinOverCallFun()
                end)
            end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},654)
    else
        local view = self:showNoWinView(function ()
            self:showGuochang(function ()
                self:showBaseAllUI()
                self:bonusRandom(true)
            end,function ()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
    end
    

end

function CodeGameScreenMagneticBreakInMachine:showFreeSpinOver(coins, num, func)

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    
    
    self:delayCallBack(0.2,function ()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_over_showStart)
    end)
    
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_click)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_over_showOver)
    end)
    return view
end

--[[
    @desc: 中jackpot
    author:{author}
    time:2023-04-13 14:37:41
    @return:
]]

function CodeGameScreenMagneticBreakInMachine:showJackpotWinView(jackpotInfo,func)
    if self.showJackpotIndex > #jackpotInfo then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --刷新赢钱
            local winLines = self.m_reelResultLines
            if #winLines <= 0 then
                -- 如果freespin 未结束，不通知左上角玩家钱数量变化
                local isNotifyUpdateTop = true
                if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
                    isNotifyUpdateTop = false
                end
                if self:checkHasBigWin() == false then
                    self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin,self.GAME_FREE_MAGNET_EFFECT)
                end
                
                self:updateBottomUICoins(self.m_iOnceSpinLastWin,isNotifyUpdateTop,true,true)
            end
        else
            --刷新赢钱
            if #self.m_runSpinResultData.p_winLines == 0 then
                if self:checkHasBigWin() == false then
                    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.GAME_MAGNET_EFFECT)
                end
                -- self:updateBottomUICoins(self.m_runSpinResultData.p_winAmount,true,true,true)
            end
        end
        --彻底弹完了！！！
        if type(func) == "function" then
            func()
        end
        return
    end
    local index = jackpotInfo[self.showJackpotIndex][1]
    local jackpotIndex = self:getJackpotIndexForStr(index)
    self.m_jackpotBar:showGetJackpotAct(jackpotIndex)
    self:delayCallBack(40/60,function ()
        self:showJackpotWinViewForIndex(jackpotInfo,function ()
            self.showJackpotIndex = self.showJackpotIndex + 1
            self:showJackpotWinView(jackpotInfo,func)
        end)
    end)
    
end

function CodeGameScreenMagneticBreakInMachine:getJackpotIndexForStr(jackpotStr)
    if jackpotStr == "grand" then
        return 1
    elseif jackpotStr == "mega" then
        return 2
    elseif jackpotStr == "major" then
        return 3
    elseif jackpotStr == "minor" then
        return 4
    else
        return 5
    end
end

--展示jackpot赢钱
function CodeGameScreenMagneticBreakInMachine:showJackpotWinViewForIndex(jackpotInfo,func)
    local jackpotInfoIndex = jackpotInfo[self.showJackpotIndex]
    local betCoin = globalData.slotRunData:getCurTotalBet()
    local index = self:getJackpotIndexForStr(jackpotInfoIndex[1])       
    local coins = tonumber(jackpotInfoIndex[2])                 --钱数
    local multiple = tonumber(jackpotInfoIndex[3]) or 0                          --倍数
    -- index 1- 5 grand - mini
    local jackPotWinView = nil
    if index == 1 then
        jackPotWinView = util_createView("CodeMagneticBreakInSrc.MagneticBreakInGrandJackPotWinView")
    else
        jackPotWinView = util_createView("CodeMagneticBreakInSrc.MagneticBreakInJackPotWinView")
    end
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    local date = {
        coins = coins,
        index = index,
        multiple = multiple,
        machine = self
    }
    jackPotWinView:initViewData(date)
    jackPotWinView:setOverAniRunFunc(function ()
        self.m_jackpotBar:showIdleAct()
        if type(func) == "function" then
            func()
        end
    end)
end


----------------------------预告中奖----------------------------------------
function CodeGameScreenMagneticBreakInMachine:updateNetWorkData()
    self.randmoBonusForBet = {}
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --磁铁变化
        self:showBigMagnetChangeForFree(function ()
            self.m_triggerFsDark:runCsbAction("over")
            self:showColorLayer(true)
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

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end)
        
    else
        self:showFeatureGameTip(
        function()
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

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end
    )
    end
end

--[[
    播放预告中奖概率
]]
function CodeGameScreenMagneticBreakInMachine:getFeatureGameTipChance(isFree)
    if isFree then
        local isNotice = (math.random(1, 100) <= 40) 
        return isNotice
    else
        local isNotice = (math.random(1, 100) <= 60)
        return isNotice
    end

    return false
end

-- 播放预告中奖统一接口
function CodeGameScreenMagneticBreakInMachine:showFeatureGameTip(_func)
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then

        -- 出现预告动画
        local isNotice = self:getFeatureGameTipChance(true)
       
        if isNotice then
            --播放预告中奖动画
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_trigger_yugao)
            self:playFeatureNoticeAni(function()
                if type(_func) == "function" then
                    _func()
                end
            end)
        else
            if type(_func) == "function" then
                _func()
            end
        end
    else
        if type(_func) == "function" then
            _func()
        end
    end
end

--[[
    播放预告中奖动画
    预告中奖通用规范
    命名:关卡名+_yugao
    时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
    挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
]]
function CodeGameScreenMagneticBreakInMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("node_yugao")
    if not parentNode then
        parentNode = self:findChild("root")
    end
    local aniName = "Socre_MagneticBreakIn_9"
        self.b_gameTipFlag = true
        --创建对应格式的spine
        local spineAni = util_spineCreate(aniName,true,true)
        if parentNode and not tolua.isnull(spineAni) then
            parentNode:addChild(spineAni)
            util_spinePlay(spineAni,"yugao1")
            util_spineEndCallFunc(spineAni,"yugao1",function()
                spineAni:setVisible(false)
                --延时0.1s移除spine,直接移除会导致闪退
                self:delayCallBack(0.1,function()
                    spineAni:removeFromParent()
                end)
                
            end)
        end
        
        aniTime = spineAni:getAnimationDurationTime("yugao1")

    if self.b_gameTipFlag then
        --计算延时,预告中奖播完时需要刚好停轮
        local delayTime = self:getRunTimeBeforeReelDown()

        --预告中奖时间比滚动时间短,直接返回即可
        if aniTime <= delayTime then
            if type(func) == "function" then
                func()
            end
        else
            self:delayCallBack(aniTime - delayTime,function()
                if type(func) == "function" then
                    func()
                end
            end)
        end
        return
    end

    if type(func) == "function" then
        func()
    end
end

--bonus预告
function CodeGameScreenMagneticBreakInMachine:showBonusTriggerYuGao(func)
    if self.m_bonusYuGao then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_Magnetic_yugao)
        self.m_bonusYuGao:setVisible(true)
        util_spinePlay(self.m_bonusYuGao,"yugao2")
        self:delayCallBack(60/30,function ()
            if type(func) == "function" then
                func()
            end
        end)
        self:delayCallBack(86/30,function ()
            self.m_bonusYuGao:setVisible(false)
        end)
    else    
        if type(func) == "function" then
            func()
        end
    end

end

---------------------------------------预告中奖  end--------------------------------------------------


----------bonus显示相关
function CodeGameScreenMagneticBreakInMachine:isMagnetSymbolNode(_slotNode)
    if _slotNode then
        if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS2 then
            return true
        end
    end
    return false
end

function CodeGameScreenMagneticBreakInMachine:isBonusSymbolNode(_slotNode)
    if _slotNode then
        if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS3 or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS4 then
            return true
        end
    end
    return false
end

function CodeGameScreenMagneticBreakInMachine:isDoorSymbolNode(_slotNode)
    if _slotNode then
        if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS5 or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS6 then
            return true
        end
    end
    return false
end

function CodeGameScreenMagneticBreakInMachine:updateReelGridNode(symblNode)
    
    if self:isMagnetSymbolNode(symblNode) then      --磁铁图标
        self:addCsbToMagneticNode(symblNode)
        if not symblNode:isLastSymbol() then
            if not self.isInitReelSymbol then
                symblNode:runAnim("tuowei",true)
            end
            
        end
    end
    if self:isBonusSymbolNode(symblNode) then       --bonus图标
        self:setSpecialNodeScore(self,{symblNode})
    end
    if self:isDoorSymbolNode(symblNode) then
        symblNode:runAnim("idleframe1")
    end
end

function CodeGameScreenMagneticBreakInMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType or not self:isBonusSymbolNode(symbolNode) then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时bonus小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local nodeType,nodeScore = self:getBonusTypeForIndex(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        self:addCsbToSymbolNode(symbolNode,nodeType,nodeScore)
        symbolNode:runAnim("idleframe")

    else
        local nodeType,nodeScore = self:randomBonusStored()
        self:addCsbToSymbolNode(symbolNode,nodeType,nodeScore)
        symbolNode:runAnim("idleframe")
    end

end

function CodeGameScreenMagneticBreakInMachine:randomBonusStored()

    local type = "score"
    local score = 0.2
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        type,score = self.m_configData:getReelSymbolShowType(true)
    else
        type,score = self.m_configData:getReelSymbolShowType(false)
    end
    
    return type,score
end

--jackpot/分数/free  
function CodeGameScreenMagneticBreakInMachine:getBonusTypeForIndex(index)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local type = nil
    local score = nil
    for i,v in ipairs(storedIcons) do
        local values = storedIcons[i]
        if tonumber(values[1]) == index then
            if values[5] == "bonus" then
                score = values[2]
                type = values[3]
            else
                type = values[5]
                score = values[2]
            end
        end
    end
    return type,score
end

function CodeGameScreenMagneticBreakInMachine:showJackpotNodeForSymbol(nodeType,csbNode)
    local jackpotName = {
        {"grand","grand_dark"},
        {"mega","mega_dark"},
        {"major","major_dark"},
        {"minor","minor_dark"},
        {"mini","mini_dark"},
    }
    csbNode:findChild("Node_chenglv"):setVisible(false)
    csbNode:findChild("Node_3"):setVisible(true)
    for i,v in ipairs(jackpotName) do
        local type = jackpotName[i][1]
        if nodeType == type then
            csbNode:findChild(jackpotName[i][1]):setVisible(true)
            csbNode:findChild(jackpotName[i][2]):setVisible(true)
        else
            csbNode:findChild(jackpotName[i][1]):setVisible(false)
            csbNode:findChild(jackpotName[i][2]):setVisible(false)
        end
    end

end

function CodeGameScreenMagneticBreakInMachine:showAddMultipleJackpotNodeForSymbol(nodeType,csbNode)
    local jackpotName = {
        {"grand","grand_cheng","grand_dark_cheng"},
        {"mega","mega_cheng","mega_dark_cheng"},
        {"major","major_cheng","major_dark_cheng"},
        {"minor","minor_cheng","minor_dark_cheng"},
        {"mini","mini_cheng","mini_dark_cheng"},
    }

    csbNode:findChild("Node_chenglv"):setVisible(true)
    csbNode:findChild("Node_3"):setVisible(false)
    
    for i,v in ipairs(jackpotName) do
        local type = jackpotName[i][1]
        if nodeType == type then
            csbNode:findChild(jackpotName[i][2]):setVisible(true)
            csbNode:findChild(jackpotName[i][3]):setVisible(true)
        else
            csbNode:findChild(jackpotName[i][2]):setVisible(false)
            csbNode:findChild(jackpotName[i][3]):setVisible(false)
        end
    end

end

--滚动的symbol
function CodeGameScreenMagneticBreakInMachine:addCsbToSymbolNode(symbolNode,nodeType,nodeScore)
    local csbNode = util_createAnimation("Socre_MagneticBreakIn_Bonus12_zi.csb")
    if nodeType == "score" then
        csbNode:findChild("Node_coins"):setVisible(true)
        csbNode:findChild("Node_fg"):setVisible(false)
        csbNode:findChild("Node_jackpot"):setVisible(false)
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local score = nodeScore * lineBet
        score = util_formatCoins(score, 3)
        csbNode:findChild("m_lb_coins"):setString(score)
        csbNode:findChild("m_lb_coins_dark"):setString(score)
    elseif nodeType == "free" then
        csbNode:findChild("Node_coins"):setVisible(false)
        csbNode:findChild("Node_fg"):setVisible(true)
        csbNode:findChild("Node_jackpot"):setVisible(false)
        csbNode:findChild("m_lb_num2"):setString(tonumber(nodeScore))
        csbNode:findChild("m_lb_num_dark2"):setString(tonumber(nodeScore))
        
    elseif self:isJackpotType(nodeType)  then
        csbNode:findChild("Node_coins"):setVisible(false)
        csbNode:findChild("Node_fg"):setVisible(false)
        csbNode:findChild("Node_jackpot"):setVisible(true)
        self:showJackpotNodeForSymbol(nodeType,csbNode)
    end
    -- csbNode:setScale(0.5)
    self:addLevelBonusSpine(symbolNode,csbNode)
end


function CodeGameScreenMagneticBreakInMachine:addCsbToMagneticNode(symbolNode)
    local csbNode = util_createAnimation("Socre_MagneticBreakIn_Bonus34_zi.csb")
    csbNode:findChild("Node_coins"):setVisible(true)
    csbNode:findChild("Node_fg"):setVisible(false)
    csbNode:findChild("Node_jackpot"):setVisible(false)
    csbNode:findChild("m_lb_coins"):setString("")
    self:updateLabelSize({label = csbNode:findChild("m_lb_coins"),sx = 1,sy = 1},134)
    self:addLevelBonusSpine(symbolNode,csbNode)
end


function CodeGameScreenMagneticBreakInMachine:addLevelBonusSpine(_symbol,view)
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    util_spineRemoveSlotBindNode(spineNode,"zi_guadian")
    self:util_spinePushBindNode(spineNode,"zi_guadian",view)
    _symbol.m_csbNode = view
end

function CodeGameScreenMagneticBreakInMachine:util_spinePushBindNode(spNode, slotName, bindNode)
    -- 与底层区分开
    spNode:pushBindNode(slotName, bindNode)
end


--[[
    过场动画
]]
function CodeGameScreenMagneticBreakInMachine:showGuochang(func1,func2)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_free_base_guochang)
    self.noClickLayer:setVisible(true)
    self.m_spineGuochang:setVisible(true)
    util_spinePlay(self.m_spineGuochang, "actionframe")
    util_spineEndCallFunc(self.m_spineGuochang, "actionframe", function ()
        self.noClickLayer:setVisible(false)
        self.m_spineGuochang:setVisible(false)
        if type(func2) == "function" then
            func2()
        end
    end)
    util_spineFrameCallFunc(self.m_spineGuochang,"actionframe","switch", function()
        if type(func1) == "function" then
            func1()
        end
    end)
    
end

function CodeGameScreenMagneticBreakInMachine:showGuochang2(func1,func2)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_base_free_guochang)
    self.noClickLayer:setVisible(true)
    self.m_spineGuochang2:setVisible(true)
    util_spinePlay(self.m_spineGuochang2, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang2, "actionframe_guochang", function ()
        self.noClickLayer:setVisible(false)
        self.m_spineGuochang2:setVisible(false)
        if type(func2) == "function" then
            func2()
        end
    end)
    self:delayCallBack(70/30,function ()
        if type(func1) == "function" then
            func1()
        end
    end)
    
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenMagneticBreakInMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        if self.changeLabOnce then
            self.changeLabOnce = false
            self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
            local posY = self.m_bottomUI.m_bigWinLabCsb:getPositionY()
            posY = posY + 15
            self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
        end
        
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1,
        animName   = "actionframe3",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenMagneticBreakInMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)
    self.bigWinEffect:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagneticBreakIn_bigWin_yugao)
    util_spinePlay(self.bigWinEffect, "actionframe")
    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        self.bigWinEffect:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--绘制多个裁切区域
function CodeGameScreenMagneticBreakInMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local offsetY = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        if i == 1 or i == 5 then
            reelSize.height = 434
        else
            reelSize.height = 366
        end
        -- reelSize.height = 810
        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
        else
            if i == 1 or i == 5 then
                offsetY = 122-34
            else
                offsetY = 122
            end
            clipNode =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0 + offsetY,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            clipNodeBig =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0 + offsetY,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            self.m_clipParent:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000)
        end

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)
        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()
        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

        --创建压黑层
        self:createBlackLayer() 


    -- 测试数据，看点击区域范围
    -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_touchSpinLayer:setBackGroundColorOpacity(0)
    -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    end
end

function CodeGameScreenMagneticBreakInMachine:getReelPosForMagnetic(col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY() + 120
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height - 244
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

function CodeGameScreenMagneticBreakInMachine:setLongAnimaInfo(reelEffectNode, col)
    local worldPos, reelHeight, reelWidth = self:getReelPosForMagnetic(col)

    local pos = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    reelEffectNode:setPosition(cc.p(pos.x, pos.y))
end

---
--添加金边
function CodeGameScreenMagneticBreakInMachine:creatReelRunAnimation(col)
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

        local worldPos, reelHeight, reelWidth = self:getReelPosForMagnetic(col)

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

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenMagneticBreakInMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self.m_clipParent:addChild(reelEffectNode, -1,SYMBOL_NODE_TAG * 100)
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        if reelType == "ccui.Layout" then
            reelEffectNode:setLocalZOrder(0)
        end
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        reelEffectNode:setPosition(cc.p(posX,(posY + 120)))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end
end

--初始化收集的数据（gameConf+ig里存对应bet的收集列表）
function CodeGameScreenMagneticBreakInMachine:initGameStatusData( gameData )
    CodeGameScreenMagneticBreakInMachine.super.initGameStatusData(self,gameData)
    self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
	local gameConfig = gameData.gameConfig
    if gameConfig and gameConfig.extra then
        if gameConfig.extra.collect then
            self:initBetNetCollectData(gameConfig.extra.collect)
        else
            self.curBonusListForBet = {}
        end
    else
        self.curBonusListForBet = {}
    end
    
end

function CodeGameScreenMagneticBreakInMachine:initBetNetCollectData( bets )
	if bets then
		self.curBonusListForBet = bets
	end
end

function CodeGameScreenMagneticBreakInMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenMagneticBreakInMachine:upateBetLevel()
    local minBet = self:getMinBet( )
    self:updatProgressLock( minBet ) 
end

function CodeGameScreenMagneticBreakInMachine:updatProgressLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
            -- 解锁jackpot
            self.m_jackpotBar:showJackpotUnLock()
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            -- 锁定jackpot
            self.m_jackpotBar:showJackpotLock()
        end
    end 
end

function CodeGameScreenMagneticBreakInMachine:getBetLevel( )

    return self.m_betLevel
end

function CodeGameScreenMagneticBreakInMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
        if bets.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = bets.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end


function CodeGameScreenMagneticBreakInMachine:requestSpinResult()
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
    self.m_iBetLevel = self.m_betLevel
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel,
    }
    if table_length(self.randmoBonusForBet) > 0 then
        messageData = {
            msg = MessageDataType.MSG_SPIN_PROGRESS,
            data = self.m_collectDataList,
            jackpot = self.m_jackpotList,
            betLevel = self.m_iBetLevel,
            bonusSelect = self.randmoBonusForBet
        }
    end
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
    
end


function CodeGameScreenMagneticBreakInMachine:scaleMainLayer()
    CodeGameScreenMagneticBreakInMachine.super.scaleMainLayer(self)
    local ratio = display.height / display.width
    local mainScale = self.m_machineRootScale
    local mainPosY = 0
    if  ratio >= 1370/768 or (ratio < 1370/768 and ratio > 1228/768) then
        mainScale = mainScale + 0.01
    elseif ratio <= 1228/768 and ratio > 960/640 then
        mainPosY = 8
        mainScale = 0.89 - 0.05*((ratio - 1228/768)/(960/640 - 1228/768))
    elseif ratio <= 960/640 and ratio > 1024/768 then
        mainPosY = 18
        mainScale = 0.81 - 0.05*((ratio-960/640)/(1024/768 - 960/640))

    elseif ratio <= 1024/768 then
        mainPosY = 20
        mainScale = mainScale + 0.07

    end
    if display.width/display.height >= 1812/2176 then
        mainPosY = 15
        self:findChild("bg"):setScale(1.2)
        mainScale = 0.61
    end
    self.m_machineRootScale = mainScale
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineNode:setPositionY(mainPosY)
    self:findChild("root"):setPosition(display.center)
end

-- ---------随机未找到的bet相关

--出现个数的权重 5-1，6-1，7-1，8-1
--颜色：red-1,blue-1
--bonus:bonusScore-10,freeTimes-1
--低bet:分数：0.4-4500，0.8-3000，1-1500，3-600，5-200，10（mini）-110,20(minor)-60,50(major)-24,100(mega)-5,1000(grand)-0
    --free次数:free5-600,free10-300,free15-100
--高bet:分数：0.4-4500，0.8-3000，1-1500，3-600，5-200，10（mini）-110,20(minor)-60,50(major)-24,100(mega)-5,1000(grand)-1
    --free次数:free5-600,free10-300,free15-100

function CodeGameScreenMagneticBreakInMachine:getBonusForCurBet(isAddRandom)
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    if not isAddRandom then
        local curBonusListForBet =  self.curBonusListForBet[tostring(betCoin)] 
        if curBonusListForBet and table_length(curBonusListForBet) > 0 then
            return curBonusListForBet
        end

        local curBonusListForBet2 = self.randmoBonusForBet[tostring(betCoin)]
        if curBonusListForBet2 and table_length(curBonusListForBet2) > 0 then
            return curBonusListForBet2
        end
    end
    

    local betLevel = self:getBetLevel()
    local tempListForBonus = self.m_configData:randomBonusByBet(betLevel)
    self.randmoBonusForBet[tostring(betCoin)] = tempListForBonus
    return tempListForBonus
end


return CodeGameScreenMagneticBreakInMachine
