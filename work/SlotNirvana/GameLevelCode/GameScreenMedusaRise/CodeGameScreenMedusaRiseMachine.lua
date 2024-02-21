---
-- island li
-- 2019年1月26日
-- CodeGameScreenMedusaRiseMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenMedusaRiseMachine = class("CodeGameScreenMedusaRiseMachine", BaseFastMachine)

CodeGameScreenMedusaRiseMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenMedusaRiseMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型

CodeGameScreenMedusaRiseMachine.FLY_SCATTER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenMedusaRiseMachine.WILD_MOVE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenMedusaRiseMachine.EFFECT_REMOVE_LOW = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenMedusaRiseMachine.EFFECT_SHOW_FIRST_WINLINE = GameEffect.EFFECT_SELF_EFFECT - 4

CodeGameScreenMedusaRiseMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenMedusaRiseMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenMedusaRiseMachine.SYMBOL_WILD2 = 102
CodeGameScreenMedusaRiseMachine.SYMBOL_WILD3 = 103

CodeGameScreenMedusaRiseMachine.m_vecReelsAnimation = {"3x5", "6x5", "9x5"}
CodeGameScreenMedusaRiseMachine.m_vecRespinMedusaPos = {-350, -40, 270}
CodeGameScreenMedusaRiseMachine.m_bTriggerFsOver = nil
CodeGameScreenMedusaRiseMachine.m_vecBigWilds = nil
-- 构造函数
function CodeGameScreenMedusaRiseMachine:ctor()
    BaseFastMachine.ctor(self)


	--init
	self:initGame()
end

function CodeGameScreenMedusaRiseMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("MedusaRiseConfig.csv", "LevelMedusaRiseConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
    self.m_scatterBulingSoundArry["auto"] = "MedusaRiseSounds/sound_MedusaRise_scatter_down.mp3"
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMedusaRiseMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MedusaRise"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenMedusaRiseMachine:getNetWorkModuleName()
    return "MedusaRiseV2"
end

function CodeGameScreenMedusaRiseMachine:getGameLineType()
    --TODO 修改对应本关卡moduleName，必须实现  , 例如 E_GAME_LINE_TYPE.LINE_3X5X50_TYPE  
     return ""
end


function CodeGameScreenMedusaRiseMachine:scaleMainLayer()
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
    if globalData.slotRunData.isPortrait == true then
        if display.height < 1080 then
            mainScale = 0.65
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        elseif display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

function CodeGameScreenMedusaRiseMachine:initUI()

    self:setReelRunSound("MedusaRiseSounds/sound_MedusaRise_quick_run.mp3")
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    self.m_effectNode = self:findChild("effect")

    -- self.m_medusaRiseMagic = util_createView("CodeMedusaRiseSrc.MedusaRiseMagic")
    -- self.m_effectNode:addChild(self.m_medusaRiseMagic)
    -- self.m_medusaRiseMagic:setVisible(false)

    self.m_medusaRiseGuochang = util_createView("CodeMedusaRiseSrc.MedusaRiseGuochang")
    self.m_effectNode:addChild(self.m_medusaRiseGuochang)

    self.m_npcMedusa = util_spineCreate("MedusaRise_medusa", true, true)
    self:findChild("woman"):addChild(self.m_npcMedusa)
    util_spinePlay(self.m_npcMedusa, "idleframe1", true)

    local data = {}
    data.index = 2
    data.parent = self
    self.m_medusaMachine2 = util_createView("CodeMedusaRiseSrc.MedusaOtherMachine", data)
    self:findChild("reel_MedusaRise1"):addChild(self.m_medusaMachine2)
    self.m_medusaMachine2:setVisible(false)

    data.index = 3
    self.m_medusaMachine3 = util_createView("CodeMedusaRiseSrc.MedusaOtherMachine", data)
    self:findChild("reel_MedusaRise2"):addChild(self.m_medusaMachine3)
    self.m_medusaMachine3:setVisible(false)

    -- self.m_logo = util_createView("CodeMedusaRiseSrc.MedusaRiseLogo")
    -- self:findChild("logo"):addChild(self.m_logo)

    self.m_baseFreeSpinBar = util_createView("CodeMedusaRiseSrc.MedusaRiseFreespinBar")
    self:findChild("total"):addChild(self.m_baseFreeSpinBar)
    
    self.m_fsTimesCount = util_createView("CodeMedusaRiseSrc.MedusaFsTimesCount")
    self:findChild("bet"):addChild(self.m_fsTimesCount)

    -- self.m_fsTittle = util_createView("CodeMedusaRiseSrc.MedusaRiseFsTittle")
    -- self:findChild("freespin"):addChild(self.m_fsTittle)

    self.m_collectScatter = util_createView("CodeMedusaRiseSrc.MedusaRiseCollectScatter")
    self:findChild("Node_tishi_sc"):addChild(self.m_collectScatter)

    -- self.m_gameTip = util_createView("CodeMedusaRiseSrc.MedusaRiseTip")
    -- self:findChild("freespin_tishi"):addChild(self.m_gameTip)

    local bgEffect, act = util_csbCreate("MedusaRise/GameScreenMedusaRiseBg_light.csb")
    self.m_gameBg:findChild("Node_effect_bg"):addChild(bgEffect)
    util_csbPlayForKey(act, "idleframe", true)

    util_csbScale(self.m_gameBg.m_csbNode, self.m_machineRootScale)

    self:updateRespinBar(false)
    self:updateFsBar(false)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
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
        elseif winRate > 3  then
            soundIndex = 3
        end
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "MedusaRiseSounds/sound_MedusaRise_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
            self.m_winSoundsId = nil
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenMedusaRiseMachine:updateRespinBar(isVisible)
    self.m_collectScatter:setVisible(isVisible)
end

function CodeGameScreenMedusaRiseMachine:updateFsBar(isVisible)
    self.m_baseFreeSpinBar:setVisible(isVisible)
    -- self.m_fsTittle:setVisible(isVisible)
end

function CodeGameScreenMedusaRiseMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:reelsDownDelaySetMusicBGVolume()
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenMedusaRiseMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local selfdata =  self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinTriggerCnt = selfdata.freeSpinTriggerCnt or self.m_currFsCount or 0
    if freeSpinTriggerCnt > 0 then
        self.m_fsTimesCount:showItemIdle(freeSpinTriggerCnt)
    end
end

function CodeGameScreenMedusaRiseMachine:addObservers()
    BaseFastMachine.addObservers(self)

end

function CodeGameScreenMedusaRiseMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMedusaRiseMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_MedusaRise_Wild1"
    elseif symbolType == self.SYMBOL_WILD2 then
        return "Socre_MedusaRise_Wild2"
    elseif symbolType == self.SYMBOL_WILD3 then
        return "Socre_MedusaRise_Wild3"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MedusaRise_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_MedusaRise_11"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMedusaRiseMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMedusaRiseMachine:MachineRule_initGame(  )

    
end

function CodeGameScreenMedusaRiseMachine:slotReelDown()

    local vecWildCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
    local delayTime = 0
    -- if vecWildCol ~= nil then
    --     for key, value in pairs(vecWildCol) do
    --         local iCol = tonumber(key) + 1
    --         if value < self.m_iReelRowNum then
    --             delayTime = 0.5
    --             for iRow = 1, self.m_iReelRowNum do
    --                 local type = self.m_stcValidSymbolMatrix[iRow][iCol]
    --                 if type == self.SYMBOL_WILD2 then
    --                     local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    --                     if node ~= nil then
    --                         node:runAnim("shake")
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end
    
    -- local delayTime = 0
    -- for row = 1, self.m_iReelRowNum, 1 do
    --     for col = 1, self.m_iReelColumnNum, 1 do
    --         local symbolType = self.m_stcValidSymbolMatrix[row][col]
    --         if symbolType == self.SYMBOL_WILD2 then
    --             delayTime = 0.5
    --             local node = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
    --             if node ~= nil then
    --                 node:runAnim("shake")
    --             end
    --         end
    --     end
    -- end
    if delayTime > 0 then
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_shake.mp3")
    end
    performWithDelay(self, function()
        BaseFastMachine.slotReelDown(self) 
    end, delayTime)
end

--
--单列滚动停止回调
--
function CodeGameScreenMedusaRiseMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 
    local haveSpecial = false
    for iRow = 1, self.m_iReelRowNum, 1 do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if symbolType == self.SYMBOL_WILD2 then
            haveSpecial = true
            break
        end
    end
    if haveSpecial == true then
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_down.mp3")
    end
end

function CodeGameScreenMedusaRiseMachine:getNextReelIsLongRun(reelCol)
    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    else
        return BaseFastMachine.getNextReelIsLongRun(self, reelCol)
    end
end

function CodeGameScreenMedusaRiseMachine:setReelLongRun(reelCol)
    if self:getCurrSpinMode() == RESPIN_MODE then
        return
    else
        BaseFastMachine.setReelLongRun(self, reelCol)
    end
end

function CodeGameScreenMedusaRiseMachine:setReelRunInfo()
    if self:getCurrSpinMode() == RESPIN_MODE then
        return
    else
        BaseFastMachine.setReelRunInfo(self)
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMedusaRiseMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle2")
    self.m_gameBg:findChild("Node_effect_bg"):setVisible(false)
    -- self.m_fsTittle:setVisible(true)
    -- self.m_logo:setVisible(false)
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:changeFreeSpinByCount()
    self.m_fsTimesCount:setVisible(false)
    if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
        self.m_bottomUI:showAverageBet()
        -- self.m_fsTittle:showSpecialAnim()
        -- self.m_gameTip:changeUI(1)
    else
        -- self.m_fsTittle:showNormalAnim()
        -- self.m_gameTip:changeUI(0)
    end
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMedusaRiseMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"actionframe2")
    -- self.m_fsTittle:setVisible(false)
    -- self.m_gameTip:changeUI()
    -- self.m_logo:setVisible(true)
    self.m_fsTimesCount:setVisible(true)
    self.m_gameBg:findChild("Node_effect_bg"):setVisible(true)
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMedusaRiseMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE or self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_fs_start.mp3")
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
                gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_window_close.mp3")
            end,true)
            performWithDelay(self, function()
                if self.m_collectScatter:isVisible() == true then
                    self.m_collectScatter:hideAnim(function()
                        self.m_collectScatter:setVisible(false)
                    end)
                end
            end, 0.5)
        else
            self.m_fsTimesCount:showItemAnim(self.m_runSpinResultData.p_selfMakeData.freeSpinTriggerCnt, function()
                util_spinePlay(self.m_npcMedusa, "guochang")
                gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_guochang.mp3")
                self.m_medusaRiseGuochang:showGuochang(function()
                    util_spinePlay(self.m_npcMedusa, "idleframe1", true)
                    gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_fs_start.mp3")
                    local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                        self.m_iFreeSpinTimes = 0 
                        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_window_close.mp3")      
                    end)
                    if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
                        view:findChild("Node_fs"):setVisible(false)
                    else
                        view:findChild("Node_superfs"):setVisible(false)
                    end
                end)
                performWithDelay(self, function()
                    self.m_baseFreeSpinBar:setVisible(true)
                    self.m_baseFreeSpinBar:changeFreeSpinByCount()
                    -- self.m_fsTittle:setVisible(true)
                    self.m_fsTimesCount:setVisible(false)
                    -- self.m_logo:setVisible(false)
                    if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
                        self.m_bottomUI:showAverageBet()
                        -- self.m_fsTittle:showSpecialAnim()
                        -- self.m_gameTip:changeUI(1)
                    else
                        -- self.m_fsTittle:showNormalAnim()
                        -- self.m_gameTip:changeUI(0)
                    end
                    if self.m_collectScatter:isVisible() == true then
                        self.m_collectScatter:hideAnim(function()
                            self.m_collectScatter:setVisible(false)
                        end)
                    end
                    self.m_gameBg:findChild("Node_effect_bg"):setVisible(false)
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"actionframe1")
                end, 2.5)
            end)
            
            -- self.m_runSpinResultData.p_selfMakeData.scatterNum
            
        end
    end

    performWithDelay(self, function()
        showFSView()
    end, 0.5)
end

function CodeGameScreenMedusaRiseMachine:showFreeSpinOverView()
    
   gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_fs_over.mp3")
   
   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_window_close.mp3")
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.6,sy=0.6},1046)

    if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
        view:findChild("Node_fs"):setVisible(false)
        view:findChild("m_lb_super_num"):setString(self.m_runSpinResultData.p_freeSpinsTotalCount)
    else
        view:findChild("Node_superfs"):setVisible(false)
    end

    performWithDelay(self, function()
        self.m_gameBg:findChild("Node_effect_bg"):setVisible(true)
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"actionframe2")
        -- self.m_fsTittle:setVisible(false)
        -- self.m_gameTip:changeUI()
        self.m_baseFreeSpinBar:setVisible(false)
        self.m_fsTimesCount:setVisible(true)
        -- self.m_logo:setVisible(true)
        if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
            self.m_bottomUI:hideAverageBet()
            self.m_fsTimesCount:resetUI()
        end
    end, 0.5)
end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMedusaRiseMachine:MachineRule_SpinBtnCall()
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self.m_respinReelRun = false
    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenMedusaRiseMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenMedusaRiseMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end

function CodeGameScreenMedusaRiseMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    node.p_rowIndex = row
    node.p_cloumnIndex = col
    node.p_symbolType = symbolType
    node.m_isLastSymbol = isLastSymbol or false

    if symbolType == self.SYMBOL_WILD2
        or symbolType == self.SYMBOL_WILD3
        or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
    then
        --下帧调用 才可能取到 x y值
        if self.m_bProduceSlots_InFreeSpin == true then
            if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
                node:setLineAnimName("actionframe3")
            else
                node:setLineAnimName("actionframe2")
            end
        else
            node:setLineAnimName("actionframe1")
        end
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMedusaRiseMachine:addSelfEffect()

    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildColumns ~= nil then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.WILD_MOVE_EFFECT -- 动画类型
    end

    if self:isTriggerFirstWinLine() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 5
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SHOW_FIRST_WINLINE
    end

    if self:isTriggerGlodWildEffect() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 4
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_REMOVE_LOW
    end
    if self:getCurrSpinMode() == RESPIN_MODE or (self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0) then
        if self.m_runSpinResultData.p_reSpinCurCount == 0 and self.m_runSpinResultData.p_selfMakeData.scatterNum < 3 then
            return
        end
        for row = 1, self.m_iReelRowNum, 1 do
            for col = 1, self.m_iReelColumnNum, 1 do
                local symbolType = self.m_stcValidSymbolMatrix[row][col]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local node = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
                    if node ~= nil then
                        local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                        if self.m_scatterPos == nil then
                            self.m_scatterPos = {}
                        end
                        self.m_scatterPos[#self.m_scatterPos + 1] = pos
                    end
                end
            end
        end
        if self.m_scatterPos ~= nil and #self.m_scatterPos > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FLY_SCATTER_EFFECT -- 动画类型
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMedusaRiseMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.WILD_MOVE_EFFECT then

        self:wildMoveAction(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_REMOVE_LOW then
        self:playMedusaEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_SHOW_FIRST_WINLINE then
        self:playFirstWinLineEffect(effectData)
    elseif effectData.p_selfEffectType == self.FLY_SCATTER_EFFECT then
        self:flyScatterAnim(effectData)
    end

    
	return true
end

function CodeGameScreenMedusaRiseMachine:wildMoveAction(effectData)
    local vecWildCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
    local delayTime = 0
    for key, value in pairs(vecWildCol) do
        local iCol = tonumber(key) + 1
        if value < self.m_iReelRowNum then
            delayTime = 0.6
            local direction = nil
            local rowIndex = nil
            for iRow = 1, self.m_iReelRowNum do
                local type = self.m_stcValidSymbolMatrix[iRow][iCol]
                if direction == nil then
                    if type == self.SYMBOL_WILD2 then
                        direction = "up"
                    else
                        direction = "down"
                    end
                else
                    if direction == "up" and type ~= self.SYMBOL_WILD2 then
                        rowIndex = iRow - 1
                        break
                    elseif direction == "down" and type == self.SYMBOL_WILD2 then
                        rowIndex = iRow
                        break
                    end
                end
            end
            
            local addWildNum = self.m_iReelRowNum - rowIndex
            if direction == "down" then
                addWildNum = rowIndex - 1
                rowIndex = self.m_iReelRowNum
            end
            local colIndex = iCol
            local reelColData = self.m_reelColDatas[colIndex]
            local parentData = self.m_slotParents[colIndex]
            local halfNodeH = reelColData.p_showGridH * 0.5
            for i = 1, addWildNum, 1 do
                if direction == "up" then
                    rowIndex = 1 - i
                else
                    rowIndex = rowIndex + 1
                end

                local symbolType = self.SYMBOL_WILD2
                local currNode = self:getReelChildByRowCol(rowIndex, colIndex)
                if currNode ~= nil then
                    currNode:setVisible(false)
                end
                local showOrder = self:getBounsScatterDataZorder(symbolType)
                local node = self:getCacheNode(colIndex, symbolType)
                if node == nil then
                    node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                    local slotParentBig = parentData.slotParentBig
                    if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                        slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                    else
                        parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                    end
                else
                    local tmpSymbolType = self:convertSymbolType(symbolType)
                    node:setVisible(true)
                    node:setLocalZOrder(showOrder - rowIndex)
                    node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                    local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                    node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                    self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
                end
                node.p_slotNodeH = reelColData.p_showGridH

                node.p_symbolType = symbolType
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

                node.p_reelDownRunAnima = parentData.reelDownAnima

                node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
                -- else
                --     if currNode.p_symbolType ~= symbolType then
                --         currNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                --     end
                -- end
                

            end

            self:foreachSlotParent(colIndex, function(index, realIndex, child)
                local distance = reelColData.p_showGridH * addWildNum
                if direction == "down" then
                    distance = -distance
                end
                -- child:setVisible(true)
                local moveBy = cc.MoveBy:create(0.5, cc.p(0, distance))
                child:runAction(moveBy)
            end)
        end
    end
    if delayTime > 0 then
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_move.mp3")
    end
    
    performWithDelay(self, function()
        self:addBigWild(function()
            -- if self.m_collectScatter:isVisible() == false then
            --     self.m_collectScatter:setVisible(true)
            --     self.m_collectScatter:showAnim()
            -- end
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end, delayTime)
    
end

function CodeGameScreenMedusaRiseMachine:addBigWild(func)
    local vecWildCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
    if self.m_vecBigWilds == nil then
        self.m_vecBigWilds = {}
    end
    local isPlaySound = false
    for key, value in pairs(vecWildCol) do
        isPlaySound = true
        local iCol = tonumber(key) + 1
        local colIndex = iCol
        local rowIndex= 1
        local reelColData = self.m_reelColDatas[colIndex]
        local parentData = self.m_slotParents[colIndex]
        local halfNodeH = reelColData.p_showGridH * 0.5
        
        local symbolType = self.SYMBOL_WILD3
        local showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
        local node = self:getCacheNode(colIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            local slotParentBig = parentData.slotParentBig
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(showOrder - rowIndex)
            node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
        end
        node.p_slotNodeH = reelColData.p_showGridH

        node.p_symbolType = symbolType
        node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)

        local linePos = {}
        for i = 1, self.m_iReelRowNum, 1 do
            linePos[#linePos + 1] = {iX = i, iY = colIndex}
            -- self.m_stcValidSymbolMatrix[i][colIndex] = self.SYMBOL_WILD2
        end
        node.m_bInLine = true
        node:setLinePos(linePos)
        node:runAnim("actionframe")
        self.m_vecBigWilds[#self.m_vecBigWilds + 1] = node
    end
    local delayTime = 0
    if isPlaySound == true then
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_light.mp3")
        delayTime = 0.5
    end
    
    performWithDelay(self, function()
        if func ~= nil then
            func()
        end
    end, delayTime)
end

function CodeGameScreenMedusaRiseMachine:bigWildAnim(func)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearWinLineEffect()
    local delayTime = 0
    if self.m_vecBigWilds ~= nil and #self.m_vecBigWilds > 0 then
        delayTime = 1.4
        for i = #self.m_vecBigWilds, 1, -1 do
            local node = self.m_vecBigWilds[i]
            local parent = node:getParent()
            local pos = cc.p(node:getPosition())
            if parent ~= nil then
                pos = parent:convertToWorldSpace(pos)
                pos = self.m_effectNode:convertToNodeSpace(pos)
                local effect, act = util_csbCreate("MedusaRise_Wild3_light.csb")
                self.m_effectNode:addChild(effect)
                effect:setPosition(pos)
                local index = i
                util_csbPlayForKey(act, "actionframe", false, function()
                    node:runAnim("idleframe1", true)
                    -- if index == 1 then
                    --     if func ~= nil then
                    --         func()
                    --     end
                    --     func = nil
                    -- end
                    effect:removeFromParent()
                end)
            end
            table.remove(self.m_vecBigWilds, i)
        end
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_trigger.mp3")
    else
        -- func()
    end
    self.m_vecBigWilds = {}
    return delayTime
end


function CodeGameScreenMedusaRiseMachine:flyScatterAnim(effectData)
    if self.m_scatterPos ~= nil and #self.m_scatterPos > 0 then
        local iCount = 0
        table.sort(self.m_scatterPos, function(a, b)
            return a.x > b.x
        end)
        for i = #self.m_scatterPos, 1, -1 do
            local pos = self.m_scatterPos[i] --self.m_clipParent:convertToNodeSpace(self.m_scatterPos[i])
            if self.m_collectScatter:isVisible() == false then
                self.m_collectScatter:setVisible(true)
                self.m_collectScatter:showAnim()
            end
            performWithDelay(self, function()
                local scatter, act = util_csbCreate("MedusaRise_scatter_collect.csb")
                util_csbPlayForKey(act, "idleframe", false, function()
                    self.m_collectScatter:showCollectAnim(self.m_runSpinResultData.p_selfMakeData.freeSpinTimes)
                    scatter:removeFromParent()
                end)
                self:addChild(scatter, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                scatter:setPosition(pos)
                gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_scatter_fly.mp3")
                local endPos = self.m_collectScatter:getEndPos()
                -- endPos = self.m_clipParent:convertToNodeSpace(endPos)
                local moveTo = cc.MoveTo:create(1, endPos)
                scatter:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
                end), moveTo))
            end, iCount )
            iCount = iCount + 1.5
            table.remove(self.m_scatterPos, i)
        end
        self.m_scatterPos = {}
        
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 2 + iCount)
    end
end

function CodeGameScreenMedusaRiseMachine:getReelChildByRowCol(rowIndex, colIndex)
    local slotParentData = self.m_slotParents[colIndex]
    if slotParentData ~= nil then
        local slotParent = slotParentData.slotParent
        local slotParentBig = slotParentData.slotParentBig
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j=1,#newChilds do
                childs[#childs+1]=newChilds[j]
            end
        end
        for i = 1, #childs, 1 do
            local child = childs[i]
            if child.p_cloumnIndex == colIndex and child.p_rowIndex == rowIndex then
                return child
            end
        end
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMedusaRiseMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

---
-- 处理spin 返回结果
function CodeGameScreenMedusaRiseMachine:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    
    self:checkTestConfigType(param)
    
    local isOpera = self:checkOpearReSpinAndSpecialReels(param)  -- 处理respin逻辑
    if isOpera == true then
        return 
    end

    if param[1] == true then                -- 处理spin成功
        self:checkOperaSpinSuccess(param)
        local spinData = param[2]
        local results = spinData.result.selfData.spinResults
        if results ~= nil then
            for i = 1, #results, 1 do
                local result = results[i]
                result.bet = spinData.result.bet
                self["m_medusaMachine"..(i + 1)]:netWorkCallFun(result)
            end
        end
    else                                    -- 处理spin失败
        self:checkOpearSpinFaild(param)                            
    end
end

--[[
    @desc: 处理用户的spin赢钱信息
    time:2020-07-10 17:50:08
]]
function CodeGameScreenMedusaRiseMachine:operaWinCoinsWithSpinResult( param ) 
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
    --发送测试赢钱数
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN,self.m_serverWinCoins)
    globalData.userRate:pushCoins(self.m_serverWinCoins)

    if spinData.result.freespin.freeSpinsTotalCount > 0 then
        self:setLastWinCoin( spinData.result.freespin.fsWinCoins )
    elseif spinData.result.respin.reSpinsTotalCount > 0 then
        self:setLastWinCoin( spinData.result.respin.resWinCoins )
    elseif spinData.result.freespin.freeSpinsTotalCount == 0 then
        self:setLastWinCoin( spinData.result.winAmount )
    end
    globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
end

function CodeGameScreenMedusaRiseMachine:showEffect_Respin(effectData)

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
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
            -- if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE then
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(),childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            childs[i]:removeFromParent()
            childs[i]:setPosition(cc.p(pos.x, pos.y))
            self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
            -- end
        end
    end

    if  self:getLastWinCoin() > 0 then  -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝

        scheduler.performWithDelayGlobal(function()
            removeMaskAndLine()
            self:showRespinView(effectData)
        end, 2, self:getModuleName())

    else
        self:showRespinView(effectData)
    end
    
    return true

end

function CodeGameScreenMedusaRiseMachine:showRespinView(effectData)
    local index = self.m_runSpinResultData.p_reSpinCurCount
    -- self:updateMedusaMachine(index, function()
    local total = self.m_runSpinResultData.p_reSpinsTotalCount
    if total > 1 then
        if index == 2 then
            self.m_medusaMachine2:setVisible(true)
            self.m_medusaMachine2:runCsbAction("BaseReel6x5_up")
        elseif index == 3 then
            self.m_medusaMachine3:setVisible(true)
            self.m_medusaMachine2:setVisible(true)
            self.m_medusaMachine2:runCsbAction("BaseReel9x5_mid")
            self.m_medusaMachine3:runCsbAction("BaseReel6x5_up")
        end
        self:runCsbAction(self.m_vecReelsAnimation[index].."idle")
    end
    if self.m_runSpinResultData.p_resWinCoins > 0 and self.m_bProduceSlots_InFreeSpin ~= true then
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_runSpinResultData.p_resWinCoins))
    end
    self:setCurrSpinMode( RESPIN_MODE )
    if self.m_collectScatter:isVisible() == false and self.m_runSpinResultData.p_selfMakeData.scatterNum > 0 then
        self.m_collectScatter:setVisible(true)
        self.m_collectScatter:idleAnim(self.m_runSpinResultData.p_selfMakeData.scatterNum, self.m_runSpinResultData.p_selfMakeData.freeSpinTimes)
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true then
        self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
        self.m_bTriggerFsOver = true
    end
    
    effectData.p_isPlay = true
    self:playGameEffect()
    -- end)
    -- self.m_vecReelsAnimation
end

function CodeGameScreenMedusaRiseMachine:beginReel()
    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
    -- if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_respinReelRun = true
    end
    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 1 then
        local total = self.m_runSpinResultData.p_reSpinCurCount
        for i = 1, total, 1 do
            if self["m_medusaMachine"..i] then
                self["m_medusaMachine"..i]:setCurrSpinMode( RESPIN_MODE )
                self["m_medusaMachine"..i]:beginMiniReel()
            end
        end
    end
    BaseFastMachine.beginReel(self)
end

function CodeGameScreenMedusaRiseMachine:updateMedusaMachine(index, func)
    if self["m_medusaMachine"..index] and self["m_medusaMachine"..index]:isVisible() == false then
        
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_add_reel.mp3")
        self["m_medusaMachine"..index]:setVisible(true)
        -- self["m_medusaMachine"..index]:initReelSlotNodes(self.m_stcValidSymbolMatrix)
        self:runCsbAction(self.m_vecReelsAnimation[index].."show", false, function()
        end)
        if func ~= nil then
            func()
        end
        if index == 2 then
            scheduler.performWithDelayGlobal(function (  )
                self.m_medusaMachine2:runCsbAction("BaseReel6x5_up")
                gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_add_reel_down.mp3")
            end, 25 / 30, self:getModuleName())
        elseif index == 3 then
            scheduler.performWithDelayGlobal(function (  )
                self.m_medusaMachine2:runCsbAction("BaseReel9x5_mid")
                self.m_medusaMachine3:runCsbAction("BaseReel6x5_up")
                gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_add_reel_down.mp3")
            end, 27 / 30, self:getModuleName())
        end
    else
        if index == 3 then
            for i = index -1, 2, 1 do
                if self["m_medusaMachine"..i] and self["m_medusaMachine"..i]:isVisible() == false then
                    self["m_medusaMachine"..i]:setVisible(true)
                end
            end
           
            if func ~= nil then
                func()
            end
            
        else
            gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_sub_reel.mp3")
            
            local hideID = index + 1
            if self["m_medusaMachine"..hideID] and self["m_medusaMachine"..hideID]:isVisible() == true then
                self:runCsbAction(self.m_vecReelsAnimation[hideID].."over", false, function()
                    self["m_medusaMachine"..hideID]:setVisible(false)
                end)
                performWithDelay(self, function()
                    if func ~= nil then
                        func()
                    end
                end, 1)
            else
                if func ~= nil then
                    func()
                end
            end
            
            if index == 2 then
                performWithDelay(self, function()
                    self.m_medusaMachine2:runCsbAction("BaseReel6x5_up")
                end, 1 / 30)
            end
        end
    end
end

function CodeGameScreenMedusaRiseMachine:playEffectNotifyNextSpinCall( )

    if self.m_iMachineNum ~= nil and self.m_iMachineNum > 0 then
        self.m_iMachineNum = self.m_iMachineNum - 1
    end
    if self.m_iMachineNum ~= nil and self.m_iMachineNum > 0 then
        return
    end
    self.m_iMachineNum = self.m_runSpinResultData.p_reSpinCurCount
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
        
        local index = self.m_runSpinResultData.p_reSpinCurCount
        local delayTime = 0
        if self.m_runSpinResultData.p_winAmount and self.m_runSpinResultData.p_winAmount > 0 then
            delayTime = math.max(self.m_autoSpinDelayTime, self.m_changeLineFrameTime)
        end
        if self.m_runSpinResultData.p_reSpinsTotalCount == 1 then
            delayTime = 0
        end
        performWithDelay(self, function()
            self.m_medusaMachine2:clearWinLineEffect()
            self.m_medusaMachine3:clearWinLineEffect()
            local animTime = self:bigWildAnim()
            performWithDelay(self, function()
                self:updateMedusaMachine(index, function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})
                    self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
                        self:normalSpinBtnCall()
                    end, 0.5, self:getModuleName())
                end)
            end, animTime)
        end, delayTime)
        
        
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenMedusaRiseMachine:playEffectNotifyChangeSpinStatus( )
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Auto,true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Auto,true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
                    self:normalSpinBtnCall()
                end, 0.5,self:getModuleName())
            end
        else
            if self:getCurrSpinMode() ~= RESPIN_MODE then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin,true})
            end
        end
    end
end

function CodeGameScreenMedusaRiseMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self:getCurrSpinMode() == RESPIN_MODE or self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
end

function CodeGameScreenMedusaRiseMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    else
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN,isClearWin)
    end
        -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44


end

function CodeGameScreenMedusaRiseMachine:showEffect_RespinOver(effectData)
    -- self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)

    -- self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- self:clearFrames_Fun()
    if self.m_collectScatter:isVisible() == true then
        self.m_collectScatter:hideAnim(function()
            self.m_collectScatter:setVisible(false)
        end)
    end
    
    -- local test = self:getLastWinCoin()
    if self.m_bProduceSlots_InFreeSpin then
    --     local addCoin = self.m_serverWinCoins
    --     -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self:getLastWinCoin(),false})
    else
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end
    self:resetReSpinMode()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()

    if
        self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or
            self.m_bProduceSlots_InFreeSpin
     then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
    
    if self.m_bTriggerFsOver == true then
        self.m_bTriggerFsOver = false
        if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end
    end

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

function CodeGameScreenMedusaRiseMachine:MachineRule_respinTouchSpinBntCallBack()
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

function CodeGameScreenMedusaRiseMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD2 or symbolType == self.SYMBOL_WILD3 then
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

function CodeGameScreenMedusaRiseMachine:reelDownNotifyPlayGameEffect()
    self:playGameEffect()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
    end
end

function CodeGameScreenMedusaRiseMachine:initGameStatusData(gameData)

    self.m_currFsCount = gameData.gameConfig.extra.freeSpinTriggerCnt
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end


--[[
    @desc: 掉落玩法
    author:{author}
    time:2020-06-20 16:50:22
    --@winLineData:
	--@lineInfo: 
    @return:
]]
function CodeGameScreenMedusaRiseMachine:getFirstWinLineSymboltType(winLineData, lineInfo)
    local iconsPos = winLineData.icons
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex = 1, #iconsPos do
        local posData = iconsPos[posIndex]

        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData -- 连线元素的 pos信息

        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            enumSymbolType = symbolType
        end
    end
    return enumSymbolType
end

function CodeGameScreenMedusaRiseMachine:compareFirstScatterWinLines(winLines)
    local scatterLines = {}
    local winAmountIndex = -1
    for i = 1, #winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.icons
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        for posIndex = 1, #iconsPos do
            local posData = iconsPos[posIndex]
            local rowColData = self:getRowAndColByPos(posData)

            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            scatterLines[#scatterLines + 1] = {i, winLineData.p_amount}
            if winLineData.amount > 0 then
                winAmountIndex = i
            end
        end
    end

    if #scatterLines > 0 and winAmountIndex > 0 then
        for i = #scatterLines, 1, -1 do
            local lineData = scatterLines[i]
            if lineData[2] == 0 then
                table.remove(winLines, lineData[1])
            end
        end
    end
end

function CodeGameScreenMedusaRiseMachine:isTriggerGlodWildEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            return true
        end
    end
    return false
end

--是否触发 glod wild 掉落玩法
function CodeGameScreenMedusaRiseMachine:isTriggerFirstWinLine()
    self.m_vecFirstGetLineInfo = {}
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local winLines = selfdata.fallLines
    if selfdata.fallWinAmount then
        self.m_fisrtLinesWinCoin = self.m_runSpinResultData.p_winAmount - selfdata.fallWinAmount
        if
            self.m_runSpinResultData.p_freeSpinsTotalCount == 0 or
                (self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount)
         then
            self:setLastWinCoin(self.m_fisrtLinesWinCoin)
        else
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins - selfdata.fallWinAmount)
        end
    end

    if winLines and #winLines > 0 then
        self:compareFirstScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.icons

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()

            local enumSymbolType = self:getFirstWinLineSymboltType(winLineData, lineInfo)

            if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
                if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
                elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                end
            end

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >= 5 then
            -- isFiveOfKind = true
            end

            self.m_vecFirstGetLineInfo[#self.m_vecFirstGetLineInfo + 1] = lineInfo
        end
    end
    self:keepCurrentFirstSpinData()
    if self.m_FirstReelResultLines ~= nil and #self.m_FirstReelResultLines > 0 then
        return true
    end
    return false
end

local function cloneLineInfo(originValue, targetValue)
    targetValue.enumSymbolType = originValue.enumSymbolType
    targetValue.enumSymbolEffectType = originValue.enumSymbolEffectType
    targetValue.iLineIdx = originValue.iLineIdx
    targetValue.iLineSymbolNum = originValue.iLineSymbolNum
    targetValue.iLineMulti = originValue.iLineMulti
    targetValue.lineSymbolRate = originValue.lineSymbolRate

    local matrixPosLen = #originValue.vecValidMatrixSymPos
    for i = 1, matrixPosLen do
        local value = originValue.vecValidMatrixSymPos[i]

        table.insert(targetValue.vecValidMatrixSymPos, {iX = value.iX, iY = value.iY})
    end
end

function CodeGameScreenMedusaRiseMachine:keepCurrentFirstSpinData() --保留本轮数据
    self.m_FirstReelResultLines = {}
    if #self.m_vecFirstGetLineInfo ~= 0 then
        local lines = self.m_vecFirstGetLineInfo
        local lineLen = #lines
        local hasBonus = false
        local hasScatter = false
        for i = 1, lineLen do
            local value = lines[i]

            local function copyLineValue()
                local cloneValue = self:getReelLineInfo()
                cloneLineInfo(value, cloneValue)
                table.insert(self.m_FirstReelResultLines, cloneValue)

                if #cloneValue.vecValidMatrixSymPos > 5 then
                -- printInfo("")
                end
            end

            if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS or value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS and hasBonus == false then
                    copyLineValue()
                    hasBonus = true
                elseif value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN and hasScatter == false then
                    copyLineValue()
                    hasScatter = true
                end
            else
                copyLineValue()
            end
        end
    end
end

function CodeGameScreenMedusaRiseMachine:playFirstWinLineEffect(effectData)
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    local winLines = self.m_FirstReelResultLines
    if #winLines <= 0 then
        return
    end
    self:removeFirstScatterWinLines()
    self.m_firstWinCoin = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_fisrtLinesWinCoin, false})

    self.m_lineSlotNodes = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    self:showAllFrame(winLines) -- 播放全部线框
    -- 判断什么时候停调用
    local delayTime = self.m_changeLineFrameTime
    scheduler.performWithDelayGlobal(
        function()
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        delayTime,
        self:getModuleName()
    )
end

function CodeGameScreenMedusaRiseMachine:removeFirstScatterWinLines()
    if self.m_FirstReelResultLines and type(self.m_FirstReelResultLines) == "table" then
        local scatterLineValue = nil
        for i = #self.m_FirstReelResultLines, 1, -1 do
            local lineData = self.m_FirstReelResultLines[i]
            if lineData then
                if lineData.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    table.remove(self.m_FirstReelResultLines, i)
                end
            end
        end
    end
end

function CodeGameScreenMedusaRiseMachine:playMedusaEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    self.m_iFallNum = 1 --下落次数
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            self.m_medusaRiseMagic:setVisible(true)
            if self.m_soundStone ~= nil  then
                gLobalSoundManager:stopAudio(self.m_soundStone)
                self.m_soundStone = nil
            end
            self.m_soundStone = gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_stone.mp3")
            util_spinePlay(self.m_npcMedusa, "actionframe")
            util_spineEndCallFunc(self.m_npcMedusa, "actionframe", function()
                util_spinePlay(self.m_npcMedusa, "idleframe1", true)
            end)
            self.m_medusaRiseMagic:showMagic(function()
                self.m_medusaRiseMagic:setVisible(false)
            end)
            performWithDelay(self, function()
                self:playRemoveLowSymbolEffect()
                
            end, 2.4)
            -- scheduler.performWithDelayGlobal(
            --     function()
            --         self:playRemoveLowSymbolEffect()
            --     end,
            --     0.5,
            --     self:getModuleName()
            -- )
            self.m_effectData = effectData
        end
    end
end

--消除低级图标
function CodeGameScreenMedusaRiseMachine:playRemoveLowSymbolEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.removeSignals ~= nil and #selfdata.removeSignals > 0 then
            if #selfdata.removeSignals >= self.m_iFallNum then
                local removeSymbolInfo = selfdata.removeSignals[self.m_iFallNum]
                gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_symbol_broken.mp3")
                for i, v in ipairs(removeSymbolInfo) do
                    local fixPos = self:getRowAndColByPos(v)
                    local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    if targSp then
                        targSp:runAnim(
                            "animation1",
                            false,
                            function()
                                targSp:removeFromParent()
                                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
                            end
                        )
                    end
                end
                scheduler.performWithDelayGlobal(
                    function()
                        self:playFallSymbolEffect()
                    end,
                    2.1,
                    self:getModuleName()
                )
            else
                self.m_effectData.p_isPlay = true
                self:playGameEffect()
            end
        end
    end
end

function CodeGameScreenMedusaRiseMachine:isNeedMove(_col, _row)
    for iRow = self.m_iReelRowNum, 1, -1 do
        local node = self:getFixSymbol(_col, iRow, SYMBOL_NODE_TAG)
        if _row > iRow and node == nil then
            return true
        end
    end
    return false
end

function CodeGameScreenMedusaRiseMachine:needMovePos(_col, _row)
    local num = 0
    for iRow = _row, 1, -1 do
        local node = self:getFixSymbol(_col, iRow, SYMBOL_NODE_TAG)
        if node == nil then
            num = num + 1
        end
    end
    return num
end

function CodeGameScreenMedusaRiseMachine:getColNum(_col, _row)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local upNum = 1
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            if #selfdata.fallSignals >= self.m_iFallNum then
                local fallSymbolInfo = selfdata.fallSignals[self.m_iFallNum]
                for i, v in ipairs(fallSymbolInfo) do
                    local pos = v[1]
                    local fixPos = self:getRowAndColByPos(pos)
                    if _col == fixPos.iY and _row > fixPos.iX then
                        upNum = upNum + 1
                    end
                end
            end
        end
    end
    return upNum
end

function CodeGameScreenMedusaRiseMachine:getNodePosByColAndRow(col, row)
    local posX, posY = 0, 0
    posX = posX + self.m_SlotNodeW
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

--是否是低级图标
function CodeGameScreenMedusaRiseMachine:getIsLowType(_type)
    if
        _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 or _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 or _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_2 or
            _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 or
            _type == self.SYMBOL_SCORE_10 or _type == self.SYMBOL_SCORE_11 
     then
        return true
    end
    return false
end

function CodeGameScreenMedusaRiseMachine:playFallSymbolEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            
            if #selfdata.fallSignals >= self.m_iFallNum then
                for iCol = 1, self.m_iReelColumnNum, 1 do
                    for iRow = self.m_iReelRowNum, 1, -1 do
                        if self:isNeedMove(iCol, iRow) then
                            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                            if targSp then
                                local posNum = self:needMovePos(iCol, iRow)
                                local pos = cc.p(targSp:getPosition())
                                pos.y = pos.y - posNum * self.m_SlotNodeH
                                local moveTo = cc.MoveTo:create(0.2, pos)
                                local fun =
                                    cc.CallFunc:create(
                                    function()
                                        local tag = self:getNodeTag(iCol, iRow - posNum, SYMBOL_NODE_TAG)
                                        targSp:setTag(tag)
                                    end
                                )
                                -- if targSp.p_symbolType == self.SYMBOL_SCORE_GOLD_WILD then
                                    local linePos = {}
                                    linePos[#linePos + 1] = {iX = iRow - posNum, iY = iCol}
                                    targSp.m_bInLine = true
                                    targSp:setLinePos(linePos)
                                -- end
                                targSp:runAction(cc.Sequence:create(moveTo, fun))
                            end
                        end
                    end
                end
                local fallSymbolInfo = selfdata.fallSignals[self.m_iFallNum]
                --破碎音效
                -- self:playSymbolSuiSound(fallSymbolInfo)
                --破碎动画
                for i, v in ipairs(fallSymbolInfo) do
                    local pos = v[1]
                    local _type = v[2]
                    local fixPos = self:getRowAndColByPos(pos)
                    local symbol = self:getSlotNodeBySymbolType(_type)
                    local tag = self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    symbol.p_cloumnIndex = fixPos.iY
                    symbol.p_rowIndex = fixPos.iX
                    symbol:setTag(tag)
                    local showOrder = self:getBounsScatterDataZorder(_type) - fixPos.iX
                    symbol.m_showOrder = showOrder
                    self:getReelParent(fixPos.iY):addChild(symbol, showOrder)
                    local num = self:getColNum(fixPos.iY, fixPos.iX)
                    local startpos = self:getNodePosByColAndRow(fixPos.iY, 3 + num)
                    symbol:setPosition(startpos)

                    local endPos = self:getNodePosByColAndRow(fixPos.iY, fixPos.iX)
                    local moveTo = cc.MoveTo:create(0.2, endPos)
                    local fun =
                        cc.CallFunc:create(
                        function()
                            if _type == self.SYMBOL_SCORE_GOLD_WILD or _type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                                self:changeToMaskLayerSlotNode(symbol)
                                if _type == self.SYMBOL_SCORE_GOLD_WILD then
                                    local linePos = {}
                                    linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                                    symbol.m_bInLine = true
                                    symbol:setLinePos(linePos)
                                end
                            end
                            if i == #fallSymbolInfo then
                                
                            end
                            if #selfdata.fallSignals > self.m_iFallNum then
                                self.m_medusaRiseMagic:setVisible(true)
                                if self.m_soundStone ~= nil  then
                                    gLobalSoundManager:stopAudio(self.m_soundStone)
                                    self.m_soundStone = nil
                                end
                                self.m_soundStone = gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_stone.mp3")
                                util_spinePlay(self.m_npcMedusa, "actionframe")
                                util_spineEndCallFunc(self.m_npcMedusa, "actionframe", function()
                                    util_spinePlay(self.m_npcMedusa, "idleframe1", true)
                                end)
                                self.m_medusaRiseMagic:showMagic(function()
                                    self.m_medusaRiseMagic:setVisible(false)
                                end)
                                performWithDelay(self, function()
                                    if self:getIsLowType(_type) then
                                        symbol:runAnim(
                                            "animation1",
                                            false,
                                            function()
                                                symbol:removeFromParent()
                                                self:pushSlotNodeToPoolBySymobolType(symbol.p_symbolType, symbol)
                                            end
                                        )
                                    end
                                    
                                    if i == #fallSymbolInfo then
                                        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_symbol_broken.mp3")
                                        scheduler.performWithDelayGlobal(
                                        function()
                                            self.m_iFallNum = self.m_iFallNum + 1
                                            self:playFallSymbolEffect()
                                        end,
                                        2.1,
                                        self:getModuleName())
                                    end
                                end, 2.4)
                            else
                                if i == #fallSymbolInfo then
                                    scheduler.performWithDelayGlobal(
                                    function()
                                        self.m_iFallNum = self.m_iFallNum + 1
                                        self:playFallSymbolEffect()
                                    end,
                                    0.8,
                                    self:getModuleName())
                                end
                            end
                            
                        end)
                    symbol:runAction(cc.Sequence:create(moveTo, fun))
                end
                
            else
                self.m_effectData.p_isPlay = true
                local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
                if hasFsEffect == true then
                    self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                    self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                    self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
                end
                self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_selfMakeData.fallWinAmount
                if self.m_bProduceSlots_InFreeSpin == true then
                    self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
                else
                    self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
                end
                
                self:playGameEffect()
            end
        end
    end
end

return CodeGameScreenMedusaRiseMachine






