---
-- island li
-- 2019年1月26日
-- CodeGameScreenPiggyLegendPirateMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenPiggyLegendPirateMachine = class("CodeGameScreenPiggyLegendPirateMachine", BaseNewReelMachine)

CodeGameScreenPiggyLegendPirateMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenPiggyLegendPirateMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 --104
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 --103
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9 --102
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 --101
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 -- 105
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13 -- 106
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_RS_SCORE_BLANK = 100               --reSpin空信号 
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_SCORE_10 = 9

CodeGameScreenPiggyLegendPirateMachine.SYMBOL_WILD_2X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 18 --111
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_WILD_3X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 19 --112
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_WILD_5X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20 --113
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_WILD_8X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 21 --114
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_WILD_10X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 22 --115
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_WILD_25X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 23 --116
CodeGameScreenPiggyLegendPirateMachine.SYMBOL_WILD_100X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 24 --117

CodeGameScreenPiggyLegendPirateMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 --base下收集小猪
CodeGameScreenPiggyLegendPirateMachine.EFFECT_TYPE_COLLECT_FREE = GameEffect.EFFECT_SELF_EFFECT - 2 --free下收集小猪
CodeGameScreenPiggyLegendPirateMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --base下收集满

CodeGameScreenPiggyLegendPirateMachine.m_chipList = nil
CodeGameScreenPiggyLegendPirateMachine.m_playAnimIndex = 0
CodeGameScreenPiggyLegendPirateMachine.m_lightScore = 0

CodeGameScreenPiggyLegendPirateMachine.BASE_FS_RUN_STATES = 0
CodeGameScreenPiggyLegendPirateMachine.COllECT_FS_RUN_STATES1 = 1
CodeGameScreenPiggyLegendPirateMachine.COllECT_FS_RUN_STATES2 = 2
CodeGameScreenPiggyLegendPirateMachine.COllECT_FS_RUN_STATES3 = 3
CodeGameScreenPiggyLegendPirateMachine.COllECT_FS_RUN_STATES4 = 4

local BIG_LEVEL = {
    ONE_LEVEL = 2,
    TWO_LEVEL = 7,
    THREE_LEVEL = 13,
    FOUR_LEVEL = 20
}

-- 构造函数
function CodeGameScreenPiggyLegendPirateMachine:ctor()
    CodeGameScreenPiggyLegendPirateMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_bIsSelectCall = nil
    self.m_bonusData = {}
    self.m_lastFreeCollectNum = 0
    self.m_isFreeFlyCoin1 = true--free收集小猪是否可以飞钱 第一阶段
    self.m_isFreeFlyCoin2 = true--free收集小猪是否可以飞钱 第二阶段

    --reSpin bonus3坐标
    self.m_reSpinBonus3Pos = nil
    --reSpin 事件列表
    self.m_reSpinGameEffectList = {}
    --respin快滚坐标
    self.m_reSpinBonusQuickPos = nil
    --是否播放快滚动画
    self.m_isPlayReSpinQuick = false
    --金币赢钱
    self.m_scoreWinCoinList = {} 
    self.m_isTriggerLongRun = false --是否触发了快滚
    --jackpot赢钱
    self.m_jackpotWinCoinList = {} 
    self.m_reelRunSound = "PiggyLegendPirateSounds/sound_PiggyLegendPirate_QuickHit_reel.mp3"--快滚音效
    self.m_respinBulingSound = {}
    for i=1,5 do
        self.m_respinBulingSound[i] = false
    end
	--init
	self:initGame()
end

function CodeGameScreenPiggyLegendPirateMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("PiggyLegendPirateConfig.csv", "LevelPiggyLegendPirateConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {1,3,5}
end  



function CodeGameScreenPiggyLegendPirateMachine:initUI()

    util_csbScale(self.m_gameBg.m_numLabel, 1)

    self:initFreeSpinBar() -- FreeSpinbar
   
    -- jackpot
    self.m_jackPotBar = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateJackPotBarView", self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)

    -- 进度条
    self.m_progress = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateProgressView")
    self:findChild("Node_jindutiao"):addChild(self.m_progress)
    self:addClick(self.m_progress.m_jindutiaoTip:findChild("Button_1"))

    -- freewanted
    -- free界面上的 通缉令
    self.m_freewanted2 = util_createAnimation("PiggyLegendPirate_freewanted_2.csb")
    self:findChild("Node_freewanted"):addChild(self.m_freewanted2)
    self.m_freewanted2:runCsbAction("idleframe",true)
    self.m_freewanted2:setVisible(false)  

    self.m_freewanted1 = util_createAnimation("PiggyLegendPirate_freewanted_1.csb")
    self:findChild("Node_freewanted"):addChild(self.m_freewanted1)
    self.m_freewanted1:runCsbAction("idleframe",true)
    self.m_freewanted1:setVisible(false)
    self.m_freewanted1_zhu = util_spineCreate("Socre_PiggyLegendPirate_Bonus1", true, true)
    self.m_freewanted1:findChild("pig"):addChild(self.m_freewanted1_zhu)
    util_spinePlay(self.m_freewanted1_zhu, "idleframe4", true)   
    
    self.m_freewanted1_num = util_createAnimation("PiggyLegendPirate_freewanted_1_shuzi.csb")
    self.m_freewanted1:findChild("m_lb_num_0"):addChild(self.m_freewanted1_num)

    self.m_freewanted = util_createAnimation("PiggyLegendPirate_freewanted.csb")
    self:findChild("Node_freewanted"):addChild(self.m_freewanted)
    self.m_freewanted:runCsbAction("idleframe",true)
    self.m_freewanted:setVisible(false)
    self.m_freewanted_zhu = util_spineCreate("Socre_PiggyLegendPirate_Bonus1", true, true)
    self.m_freewanted:findChild("pig"):addChild(self.m_freewanted_zhu)
    util_spinePlay(self.m_freewanted_zhu, "idleframe4", true) 

    self.m_freewanted_num = util_createAnimation("PiggyLegendPirate_freewanted_1_shuzi.csb")
    self.m_freewanted:findChild("m_lb_num_0"):addChild(self.m_freewanted_num)

    -- self.m_freewantedQieHuan = util_createAnimation("PiggyLegendPirate_freewanted_qiehuan.csb")
    -- self:findChild("Node_freewanted"):addChild(self.m_freewantedQieHuan)
    -- self.m_freewantedQieHuan:setVisible(false)
    
    -- freebox
    self.m_freeBox = util_createAnimation("PiggyLegendPirate_basebaoxiang.csb")
    self:findChild("Node_baoxiang"):addChild(self.m_freeBox)
    self.m_freeBox:setVisible(false)

    self.m_freeBoxSpine = util_spineCreate("PiggyLegendPirate_box", true, true)
    self.m_freeBox:findChild("Node_baoxiang"):addChild(self.m_freeBoxSpine)
    util_spinePlay(self.m_freeBoxSpine,"idleframe",true)

    --reSpinBar
    self.m_reSpinBar = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateReSpinBar")
    self:findChild("Node_respinbar"):addChild(self.m_reSpinBar)
    self.m_reSpinBar:setVisible(false)
    
    --reSpinBox
    self.m_reSpinBox = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateReSpinWinBox")
    self:findChild("Node_baoxiang"):addChild(self.m_reSpinBox)
    self.m_reSpinBox:setVisible(false)

    -- freespin过场
    self.m_freeGuoChang = util_spineCreate("PiggyLegendPirate_free_guochang",true,true)            --过场
    self:findChild("freeguochang"):addChild(self.m_freeGuoChang)
    self.m_freeGuoChang:setVisible(false) 

    -- respin过场
    self.m_GuoChang = util_spineCreate("PiggyLegendPirate_respinguoc",true,true)            --过场
    self:findChild("guochang"):addChild(self.m_GuoChang)
    self.m_GuoChang:setVisible(false) 

    self:initBg()
    self:setReelBg(1)
    self:runCsbAction("idleframe",false)
    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
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
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if winRate <= 1 then
                soundIndex = 11
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 22
            elseif winRate > 3 then
                soundIndex = 33
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "PiggyLegendPirateSounds/sound_PiggyLegendPirate_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenPiggyLegendPirateMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "PiggyLegendPirateSounds/sound_PiggyLegendPirate_scatter_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath

        -- self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = "PiggyLegendPirateSounds/sound_PiggyLegendPirate_BonusDown.mp3"
    end
end

-- 重置respin 落地音效
function CodeGameScreenPiggyLegendPirateMachine:resetRespinBulingSound( )
    for i=1,5 do
        self.m_respinBulingSound[i] = false
    end
end

function CodeGameScreenPiggyLegendPirateMachine:initFreeSpinBar( )
     -- FreeSpinbar
     self.m_FreespinBarView = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateFreespinBarView")
     self.m_FreespinBarView:initViewData(self)
     self:findChild("Node_freebar"):addChild(self.m_FreespinBarView)
     self.m_FreespinBarView:setVisible(false)
 
     -- respinber
    --  self.m_reSpinBarView =  util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateRespinBerView")
    --  self:findChild("Node_respinbar"):addChild(self.m_reSpinBarView)
    --  self.m_reSpinBarView:setVisible(false)
end

function CodeGameScreenPiggyLegendPirateMachine:initBg( )
    self.m_baseBgSpine = util_spineCreate("PiggyLegendPirate_baseBG", true, true)
    self.m_gameBg:findChild("base_bg"):addChild(self.m_baseBgSpine)
    util_spinePlay(self.m_baseBgSpine, "idleframe", true)

    self.m_freeBgSpine = util_spineCreate("PiggyLegendPirate_freeBG", true, true)
    self.m_gameBg:findChild("free_bg"):addChild(self.m_freeBgSpine)
    util_spinePlay(self.m_freeBgSpine, "idleframe", true)

    self.m_respinBgSpine = util_spineCreate("PiggyLegendPirate_freeBG", true, true)
    self.m_gameBg:findChild("respin_bg"):addChild(self.m_respinBgSpine)
    util_spinePlay(self.m_respinBgSpine, "idleframe2", true)

end

--设置棋盘的背景
-- _BgIndex 1bace 2free 3respin
function CodeGameScreenPiggyLegendPirateMachine:setReelBg(_BgIndex,isPlay)
    
    self.m_gameBg:findChild("base_bg"):setVisible(false)
    self.m_gameBg:findChild("free_bg"):setVisible(false)
    self.m_gameBg:findChild("respin_bg"):setVisible(false)

    if _BgIndex == 1 then

        self.m_gameBg:runCsbAction("normal",false)
        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("Node_respinreel"):setVisible(false)
        self:findChild("Node_respinqipan1"):setVisible(false)
        self:findChild("Node_respinqipanxian"):setVisible(false)
        
    elseif _BgIndex == 2 then
       
        self.m_gameBg:runCsbAction("free",false)
        self.m_gameBg:findChild("free_bg"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("Node_respinreel"):setVisible(false)
        self:findChild("Node_respinqipan1"):setVisible(false)
        self:findChild("Node_respinqipanxian"):setVisible(false)
        
    elseif _BgIndex == 3 then
        self.m_gameBg:findChild("respin_bg"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("Node_respinreel"):setVisible(false)
        self:findChild("Node_respinqipan1"):setVisible(true)
        self:findChild("Node_respinqipanxian"):setVisible(false)
    end

end

-- 断线重连 
function CodeGameScreenPiggyLegendPirateMachine:MachineRule_initGame(  )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local freeType = selfData.freeType
    local collectPos = selfData.collectPos
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        if freeType and freeType == "COLLECT" then
            --
            self:freeSpinShow(true)
            self.m_fsReelDataIndex = self:getcollectFsStates(collectPos)
            self.m_bottomUI:showAverageBet()
        else
            self:freeSpinShow()
            
            self.m_lastFreeCollectNum = self.m_runSpinResultData.p_fsExtraData.collectNum

            if fsExtraData.collectNum then
                if fsExtraData.collectNum >= selfData.selectNumResult then
                    self.m_isFreeFlyCoin1 = false
                end

                if selfData.selectMaxNum then
                    if fsExtraData.collectNum >= selfData.selectMaxNum then
                        self.m_isFreeFlyCoin2 = false
                    end
                end
            end

            -- 刷新召集令
            self:freeCollectUpdata(false)
        end

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPiggyLegendPirateMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "PiggyLegendPirate"  
end

--小块
function CodeGameScreenPiggyLegendPirateMachine:getBaseReelGridNode()
    return "CodePiggyLegendPirateSrc.PiggyLegendPirateSlotNode"
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPiggyLegendPirateMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_BONUS1 then
        return "Socre_PiggyLegendPirate_Bonus1"
    end

    if symbolType == self.SYMBOL_BONUS2 then
        return "Socre_PiggyLegendPirate_Bonus2"
    end

    if symbolType == self.SYMBOL_BONUS3 then
        return "Socre_PiggyLegendPirate_Bonus3"
    end

    if symbolType == self.SYMBOL_RS_SCORE_BLANK then
        return "Socre_PiggyLegendPirate_reSpinBlank"
    end

    if symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_PiggyLegendPirate_Bonus1"
    end

    if symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_PiggyLegendPirate_Bonus1"
    end

    if symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_PiggyLegendPirate_Bonus1"
    end

    if symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_PiggyLegendPirate_Bonus1"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_PiggyLegendPirate_10"
    end

    if symbolType == self.SYMBOL_WILD_2X then        
        return "Socre_PiggyLegendPirate_Wild"
    end
    if symbolType == self.SYMBOL_WILD_3X then
        return "Socre_PiggyLegendPirate_Wild"
    end
    if symbolType == self.SYMBOL_WILD_5X then
        return "Socre_PiggyLegendPirate_Wild"
    end
    if symbolType == self.SYMBOL_WILD_8X then
        return "Socre_PiggyLegendPirate_Wild"
    end
    if symbolType == self.SYMBOL_WILD_10X then
        return "Socre_PiggyLegendPirate_Wild"
    end
    if symbolType == self.SYMBOL_WILD_25X then
        return "Socre_PiggyLegendPirate_Wild"
    end
    if symbolType == self.SYMBOL_WILD_100X then
        return "Socre_PiggyLegendPirate_Wild"
    end

    return nil
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenPiggyLegendPirateMachine:playInLineNodes()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply

    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if wildmultiply and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                if slotsNode.p_cloumnIndex == 3 then
                    slotsNode:runAnim("actionframe2",true)
                else
                    slotsNode:runLineAnim()
                end
            else
                slotsNode:runLineAnim()
            end
            
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end


---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenPiggyLegendPirateMachine:showLineFrameByIndex(winLines, frameIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply

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

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

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

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if wildmultiply and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        if slotsNode.p_cloumnIndex == 3 then
                            slotsNode:runAnim("actionframe2",true)
                        else
                            slotsNode:runLineAnim()
                        end
                    else
                        slotsNode:runLineAnim()
                    end
                    
                end
            end
        end
    end
end

function CodeGameScreenPiggyLegendPirateMachine:playCustomSpecialSymbolDownAct( slotNode )

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        if slotNode and  self:isFixSymbol(slotNode.p_symbolType) then
            local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
            slotNode:runAnim("buling",false,function()
                slotNode:runAnim("idle",true)
            end)
            -- gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_BonusDown.mp3")
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenPiggyLegendPirateMachine:playInLineNodesIdle()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if wildmultiply and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                if slotsNode.p_cloumnIndex == 3 then
                    slotsNode:runAnim("idleframe2",true)
                else
                    slotsNode:runIdleAnim()
                end
            else
                slotsNode:runIdleAnim()
            end
            
        end
    end
end

function CodeGameScreenPiggyLegendPirateMachine:resetMaskLayerNodes()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildmultiply = selfData.wildmultiply
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent, lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                if wildmultiply and lineNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    if lineNode.p_cloumnIndex == 3 then
                        lineNode:runAnim("idleframe2",true)
                    else
                        lineNode:runIdleAnim()
                    end
                else
                    lineNode:runIdleAnim()
                end
                
            end
        end
    end
end

-- 给respin小块进行赋值
function CodeGameScreenPiggyLegendPirateMachine:setSpecialNodeScoreBonus2(sender,param)
    local symbolNode = param[1]
    local runNodeNum = param[2]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType  then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local sScore = ""
    
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        local curBet = 1
        -- 根据网络数据获取停止滚动时respin小块的分数
        -- 存放的是respinBonus的网络数据
        local storedIcons = self.m_runSpinResultData.p_storedIcons 
        --获取分数（网络数据）
        local score = self:getReSpinBonus2Score(self:getPosReelIdx(iRow, iCol)) 
        if score ~= nil and type(score) ~= "string" then
            score = score * curBet
            sScore = util_formatCoins(score, 3)
        end
    else
        -- 获取随机分数（本地配置）
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) 
        local curBet = globalData.slotRunData:getCurTotalBet()
        score = score * curBet

        if iRow and iCol then
            local reSpinNodePos = self:getPosReelIdx(iRow, iCol)
            if reSpinNodePos == self.m_reSpinBonusQuickPos and symbolNode.p_symbolType == self.SYMBOL_BONUS2 then
                if runNodeNum == 1 then
                    local scoreNum = self:getReSpinBonus2Score(self:getPosReelIdx(iRow, iCol)) 
                    if scoreNum ~= 0 then
                        score = scoreNum
                    end
                end
            end
        end
        
        sScore = util_formatCoins(score, 3)
    end
    symbolNode:getCcbProperty("m_lb_score"):setString(sScore)
    -- self:updateLabelSize({label=symbolNode:getCcbProperty("m_lb_score"),sx=1,sy=1},125)
    symbolNode:runAnim("idleframe")
end

-- 给respin小块进行赋值
function CodeGameScreenPiggyLegendPirateMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
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
            -- local curBet = globalData.slotRunData:getCurTotalBet()
            local curBet = 1
            score = score * curBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                -- local symbol_node = symbolNode:checkLoadCCbNode()
                -- local spineNode = symbol_node:getCsbAct()
                if symbolNode.m_numLabel then
                    local lbs = symbolNode.m_numLabel:findChild("m_lb_coins")
                    if lbs and lbs.setString  then
                        lbs:setString(score)
                    end
                end
            end
        end

        symbolNode:runAnim("idleframe")

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                -- local lineBet = globalData.slotRunData:getCurTotalBet()
                local curBet = 1
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                if symbolNode  then
                    -- local symbol_node = symbolNode:checkLoadCCbNode()
                    -- local spineNode = symbol_node:getCsbAct()
                    if symbolNode.m_numLabel then
                        local lbs = symbolNode.m_numLabel:findChild("m_lb_coins")
                        if lbs and lbs.setString  then
                            lbs:setString(score)
                        end
                    end
                end
                
                symbolNode:runAnim("idleframe")
            end
        end
        
        
    end

end
-- 获取bonus2的分数
function CodeGameScreenPiggyLegendPirateMachine:getReSpinBonus2Score(_iPos)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local bonus2      = rsExtraData.bonus2 or {}
    for i,v in ipairs(bonus2) do
        if v[1] == _iPos then
            return v[2]
        end
    end
    return 0
end
-- 根据网络数据获得respinBonus小块的分数 (待删)
function CodeGameScreenPiggyLegendPirateMachine:getReSpinSymbolScore(id)
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

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR  then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR  then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_GRAND  then
        score = "GRAND"
    end

    return score
end
-- 从配置中获取一个随机倍数
function CodeGameScreenPiggyLegendPirateMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if self:isFixSymbol(symbolType) or self.SYMBOL_BONUS2 == symbolType then
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

function CodeGameScreenPiggyLegendPirateMachine:createPiggyLegendPirateBonusLab(_slotsNode)
    local labelCsb  = nil
    local labelName = "jinbi" 

    local csbNode = _slotsNode:getCCBNode()
    labelCsb = csbNode:getChildByName(labelName)
    if not labelCsb then
        labelCsb = util_createAnimation("Socre_PiggyLegendPirate_Jinbi.csb")
        csbNode:addChild(labelCsb)
        labelCsb:setName(labelName)
    end

    return labelCsb
end

function CodeGameScreenPiggyLegendPirateMachine:addLevelBonusSpine(_symbol)
    local bonusName = {"symbol","m_lb_coins","grand","major","minor","mini"}
    local cocosName = "Socre_PiggyLegendPirate_Jinbi.csb"

    if _symbol.m_numLabel == nil then
        _symbol.m_numLabel = util_createAnimation(cocosName)
        _symbol:addChild(_symbol.m_numLabel,2)
    end

    for i,vName in ipairs(bonusName) do
        _symbol.m_numLabel:findChild(vName):setVisible(false)
    end

    if _symbol.p_symbolType == self.SYMBOL_BONUS1 then
        _symbol.m_numLabel:findChild("m_lb_coins"):setString("")
        _symbol.m_numLabel:findChild("m_lb_coins"):setVisible(true)

    else
        _symbol.m_numLabel:findChild("m_lb_coins"):setVisible(false)
        if _symbol.p_symbolType == self.SYMBOL_FIX_GRAND then
            _symbol.m_numLabel:findChild("grand"):setVisible(true)
        elseif _symbol.p_symbolType == self.SYMBOL_FIX_MAJOR then
            _symbol.m_numLabel:findChild("major"):setVisible(true)
        elseif _symbol.p_symbolType == self.SYMBOL_FIX_MINOR then
            _symbol.m_numLabel:findChild("minor"):setVisible(true)
        elseif _symbol.p_symbolType == self.SYMBOL_FIX_MINI then
            _symbol.m_numLabel:findChild("mini"):setVisible(true)
        end
    end
end

function CodeGameScreenPiggyLegendPirateMachine:updateReelGridNode(node, runNodeNum)
    local symbolType = node.p_symbolType
    if self.SYMBOL_BONUS2 == symbolType then
        self:setSpecialNodeScoreBonus2(self,{node, runNodeNum})
    end

    -- if self:isFixSymbol(symbolType) then
    --     self:addLevelBonusSpine(node)
    --     if symbolType == self.SYMBOL_BONUS1 then
    --         self:setSpecialNodeScore(self,{node})
    --     end
    -- end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        if self:isFixSymbol(symbolType) then
            -- node:runAnim("idleframe2")
        end
    end
     --收集大关
     if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and node.p_cloumnIndex == 3 then
        if self:isShowWild(symbolType) then
            self:wildChangeTempNode(node,symbolType)
        else
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local wildmultiply = selfData.wildmultiply
            if wildmultiply then
                --根据倍数显示不同wild
                local skinName = self:getWildSkin(wildmultiply)
                self:wildChangeShow(node,skinName)
            end
        end
        
    end
end

function CodeGameScreenPiggyLegendPirateMachine:wildChangeTempNode(node,nodeType)
    local skinName = nil
    
    if nodeType == self.SYMBOL_WILD_2X then
        skinName = self:getWildSkin(2)
    elseif nodeType == self.SYMBOL_WILD_3X then
        skinName = self:getWildSkin(3)
    elseif nodeType == self.SYMBOL_WILD_5X then
        skinName = self:getWildSkin(5)
    elseif nodeType == self.SYMBOL_WILD_8X then
        skinName = self:getWildSkin(8)
    elseif nodeType == self.SYMBOL_WILD_10X then
        skinName = self:getWildSkin(10)
    elseif nodeType == self.SYMBOL_WILD_25X then
        skinName = self:getWildSkin(25)
    elseif nodeType == self.SYMBOL_WILD_100X then
        skinName = self:getWildSkin(100)
    end

    if skinName then
        self:wildChangeShow(node,skinName)
    end
end

function CodeGameScreenPiggyLegendPirateMachine:getWildSkin(times)
    if times == 2 then
        return "2X"
    elseif times == 3 then
        return "3X"
    elseif times == 5 then
        return "5X"
    elseif times == 8 then
        return "8X"
    elseif times == 10 then
        return "10X"
    elseif times == 25 then
        return "25X"
    elseif times == 100 then
        return "100X"
    end
    return "1X"
end

function CodeGameScreenPiggyLegendPirateMachine:wildChangeShow(node,skinName)
    if node.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD and self:isShowWild(node.p_symbolType) == false then
        return
    end
    local ccbNode = node:getCCBNode()
    if not ccbNode then
        node:checkLoadCCbNode()
    end
    ccbNode = node:getCCBNode()
    if ccbNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
    node:runAnim("idleframe2")
end

function CodeGameScreenPiggyLegendPirateMachine:isShowWild(symbolType)
    if symbolType == self.SYMBOL_WILD_2X or
        symbolType == self.SYMBOL_WILD_3X or
            symbolType == self.SYMBOL_WILD_5X or
                symbolType == self.SYMBOL_WILD_8X or
                    symbolType == self.SYMBOL_WILD_10X or
                        symbolType == self.SYMBOL_WILD_25X or
                            symbolType == self.SYMBOL_WILD_100X then
        return true
    end
    return false
end


function CodeGameScreenPiggyLegendPirateMachine:getcollectFsStates(pos)
    if pos == BIG_LEVEL.ONE_LEVEL then
        return self.COllECT_FS_RUN_STATES1
    elseif pos == BIG_LEVEL.TWO_LEVEL then
        return self.COllECT_FS_RUN_STATES2
    elseif pos == BIG_LEVEL.THREE_LEVEL then
        return self.COllECT_FS_RUN_STATES3
    elseif pos == BIG_LEVEL.FOUR_LEVEL then
        return self.COllECT_FS_RUN_STATES4
    else
        return self.COllECT_FS_RUN_STATES1
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPiggyLegendPirateMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenPiggyLegendPirateMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS1,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS2,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS3,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GRAND,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenPiggyLegendPirateMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS1 or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end


function CodeGameScreenPiggyLegendPirateMachine:beginReel()
    self.m_bCanClickMap = false
    self.m_gameEffects = {}
    CodeGameScreenPiggyLegendPirateMachine.super.beginReel(self)
end

--
--单列滚动停止回调
--
function CodeGameScreenPiggyLegendPirateMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenPiggyLegendPirateMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isTriggerLongRun then
        self.m_isTriggerLongRun = isTriggerLongRun
    end

    return isTriggerLongRun
end

function CodeGameScreenPiggyLegendPirateMachine:symbolBulingEndCallBack(_symbolNode)
    if _symbolNode and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isTriggerLongRun and _symbolNode.p_cloumnIndex ~= self.m_iReelColumnNum then
            local Col = _symbolNode.p_cloumnIndex
            for iCol = 1, Col do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName ~= "idle2" then
                        symbolNode:runAnim("idle", true)
                    end
                end
            end
        else
            _symbolNode:runAnim("idle", true)
        end
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenPiggyLegendPirateMachine:levelFreeSpinEffectChange()

end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenPiggyLegendPirateMachine:levelFreeSpinOverChangeEffect()

end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenPiggyLegendPirateMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        self:waitWithDelay(0.5, function()
            self:showBonusAndScatterLineTip(
                bonusLineValue,
                function()
                    -- self:playFreeSpinGuoChangAnim(function()
                        self:showBonusGameView(effectData)
                    -- end)
                end
            )
            bonusLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        end)
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenPiggyLegendPirateMachine:playScatterTipMusicEffect()
    -- free more触发音效
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_freeMore_trigger.mp3")
    else
        if self.m_ScatterTipMusicPath ~= nil then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        end
    end
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenPiggyLegendPirateMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode==nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        if slotNode==nil then
            slotNode = self:getFixSymbol(symPosData.iY , symPosData.iX)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end

            end
        end

        if slotNode ~= nil then--这里有空的没有管

            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            slotNode:runAnim("actionframe",false)
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenPiggyLegendPirateMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            self:waitWithDelay(1,function()
                self:resetMaskLayerNodes()
            end)
            callFun()
        end,
        util_max(2, animTime),
        self:getModuleName()
    )
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenPiggyLegendPirateMachine:showBonusGameView(effectData)
    -- 界面选择回调
    local function chooseCallBack(index)
       self.m_bIsSelectCall = true
       self.m_iSelectID = index
       self.m_gameEffect = effectData
       self:sendData(index)
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        --清空赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN) 
        self:showFreatureChooseView(chooseCallBack)
    end
    effectData.p_isPlay = true
end

-- 二选一界面
function CodeGameScreenPiggyLegendPirateMachine:showFreatureChooseView(func)
	local view = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateFeatureChooseView")
    self.m_freeSelectView = view
    view:initViewData(self, func, function()
        self:levelFreeSpinEffectChange()
    end)
    gLobalViewManager:showUI(view)
end

-- 点击二选一界面 发送消息
function CodeGameScreenPiggyLegendPirateMachine:sendData(index)
    -- local newData = {}
    -- newData.select = index
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index-1}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--spin结果
function CodeGameScreenPiggyLegendPirateMachine:spinResultCallFun(param)
    CodeGameScreenPiggyLegendPirateMachine.super.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        if param[1] == true then
            if param[2] and param[2].result then 
                globalData.slotRunData.freeSpinCount = param[2].result.freespin.freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = param[2].result.freespin.freeSpinsTotalCount
                local spinData = param[2]
                if spinData.action == "FEATURE" then
                    self:operaSpinResultData(param)
                end
                
                self:freeSpinShow()
                self.m_freeSelectView:closeView(function()
                    self.m_freeSelectView = nil
                    self.m_iOnceSpinLastWin = 0
                    self:triggerFreeSpinCallFun()
                    
                    self:waitWithDelay(0.5,function (  )
                        self:flyZhuToWarrant(function()
                            self.m_gameEffect.p_isPlay = true
                            self:playGameEffect() 
                        end)
                    end)
                end)

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Stop,false})
            end
        end
    end
    self.m_bIsSelectCall = false
end

-- free选择界面 猪 飞
function CodeGameScreenPiggyLegendPirateMachine:flyZhu(freeView, index, func)
    local startPos = freeView:findChild("Node_choose"..index):getParent():convertToWorldSpace(cc.p(freeView:findChild("Node_choose"..index):getPosition()))
    local startPosWorld = self:convertToNodeSpace(startPos)
    local moveEndPos = cc.p(display.width * 0.5, display.height * 0.5)

    local actionList = {}
    self.m_flyZhu = util_spineCreate("Socre_PiggyLegendPirate_Bonus1",true,true)
    self:addChild(self.m_flyZhu, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    util_spinePlay(self.m_flyZhu,"start")
    
    self.m_flyZhu:setPosition(startPosWorld)

    actionList[#actionList + 1] = cc.MoveTo:create(15/30,moveEndPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        util_spinePlay(self.m_flyZhu,"actionframe2",false)
        util_spineEndCallFunc(self.m_flyZhu,"actionframe2",function ()
            util_spinePlay(self.m_flyZhu,"idle4",false)
            if func then
                func()
            end
        end)
    end)

    local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))

    self.m_flyZhu:runAction(cc.Sequence:create(spawnAct))
end

--屏幕中间的猪 飞到 通缉令
function CodeGameScreenPiggyLegendPirateMachine:flyZhuToWarrant( func)
    local moveEndPosWorld = self.m_freewanted:findChild("pig"):getParent():convertToWorldSpace(cc.p(self.m_freewanted:findChild("pig"):getPosition()))
    local moveEndPos = self:convertToNodeSpace(moveEndPosWorld)

    local actionList = {}

    util_spinePlay(self.m_flyZhu,"over")
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_free_zhuFlyToLing.mp3")

    actionList[#actionList + 1] = cc.EaseSineIn:create(cc.MoveTo:create(7/30,moveEndPos))
    self:waitWithDelay(7/30, function()
        if func then
            func()
        end
        self.m_freewanted:runCsbAction("shouji",false,function()
            self.m_freewanted:runCsbAction("idleframe",true)
        end)
        util_spinePlay(self.m_freewanted_zhu, "buling4", false)
        util_spineEndCallFunc(self.m_freewanted_zhu,"buling4",function ()
            util_spinePlay(self.m_freewanted_zhu, "idleframe4", true)
        end)   
        self.m_flyZhu:setVisible(false)
        self.m_flyZhu:removeFromParent()
        self.m_flyZhu = nil
    end)

    local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))

    self.m_flyZhu:runAction(cc.Sequence:create(spawnAct))
end

---------------------------------------------------------------------------
--free显示
function CodeGameScreenPiggyLegendPirateMachine:freeSpinShow(isSuperFree)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeType = selfData.freeType
    local lineBet = self.m_runSpinResultData.p_bet * self.m_runSpinResultData.p_payLineCount
    
    self.m_FreespinBarView:setVisible(true)
    self.m_progress:setVisible(false)

    if isSuperFree then
        self.m_freewanted:setVisible(false)
        self.m_freeBox:setVisible(false)
        self.m_jackPotBar:setVisible(true)
    else
        self.m_freewanted:setVisible(true)
        self.m_freeBox:setVisible(true)
        self.m_jackPotBar:setVisible(false)
        self.m_freewanted:runCsbAction("idleframe",true)
        self.m_freewanted:findChild("m_lb_num"):setString("0")
        self.m_freewanted_num:findChild("m_lb_num_0"):setString(selfData.selectNumResult - 0)
        self.m_freewanted:findChild("m_lb_coins"):setString(util_formatCoins(selfData.selectStoreResult*lineBet, 3))
    end
    self:setReelBg(2,true)
end

function CodeGameScreenPiggyLegendPirateMachine:freeSpinOverShow( )
    self.m_FreespinBarView:setVisible(false)
    self.m_progress:setVisible(true)

    self.m_freewanted:setVisible(false)
    self.m_freewanted1:setVisible(false)
    self.m_freewanted2:setVisible(false)
    self.m_freeBox:setVisible(false)
    self.m_jackPotBar:setVisible(true)

    self:setReelBg(1,true)
end

-- 显示free spin
function CodeGameScreenPiggyLegendPirateMachine:showEffect_FreeSpin(effectData)
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

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        
        if scatterLineValue.iLineSymbolNum ~= 0 then
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        end

        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

-- 触发freespin时调用
function CodeGameScreenPiggyLegendPirateMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_free_more.mp3")
            
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local collectOccur = selfData.collectOccur or false
            local freeType = selfData.freeType
            if freeType and freeType == "COLLECT" then
                self.m_bottomUI:showAverageBet()
                
                gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_superfree_start.mp3")
                self:showSuperFreeStart(self.m_mapNodePos,self.m_runSpinResultData.p_freeSpinsTotalCount,function (  )
                    self:playFreeSpinGuoChangAnim(function()
                        self:resetMusicBg(true)
                        self:checkTriggerOrInSpecialGame(function(  )
                            self:reelsDownDelaySetMusicBGVolume( ) 
                        end)
                        self:freeSpinShow(true)
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                end)
            else
            -- self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:freeSpinShow()

                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            -- end)
            end
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenPiggyLegendPirateMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        -- self:resetMusicBg(true)
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

function CodeGameScreenPiggyLegendPirateMachine:playFreeSpinGuoChangAnim(_switchFun)
    self.m_freeGuoChang:setVisible(true)
    util_spinePlay(self.m_freeGuoChang,"actionframe")
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_guochang_free.mp3")

    local switchTime = 20/30
    self:waitWithDelay(switchTime, function()
        if _switchFun then
            _switchFun()
        end
    end)

    self:waitWithDelay(70/30, function()
        self.m_freeGuoChang:setVisible(false)
    end)

end

-- 触发freespin结束时调用
function CodeGameScreenPiggyLegendPirateMachine:showFreeSpinOverView()

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.collectPos or 0
    local freeType = selfData.freeType
    
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsTotalCount > 0 then
        local strCoins = util_formatCoins(freeSpinWinCoin, 50)
        if freeType and freeType == "COLLECT" then
            local view = self:showSuperFreeSpinOver(strCoins, 
                self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                    if self.m_mapNodePos == 20 then
                        self.m_mapNodePos = 0 -- 更新最新位置
                    end
                    self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
                    self:freeSpinOverShow()
                    self.m_bottomUI:hideAverageBet()
                    -- 调用此函数才是把当前游戏置为freespin结束状态
                    self:triggerFreeSpinOverCallFun()
                end)
            view:findChild("m_lb_num_0_0"):setVisible(false)
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_superfree_over.mp3")
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=1,sy=1},800)
        else
            local view = self:showFreeSpinOver( strCoins, 
                self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                    self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
                    self:freeSpinOverShow()
                    self.isInBonus = false
                    self.m_lastFreeCollectNum = 0
                    -- 调用此函数才是把当前游戏置为freespin结束状态
                    self:triggerFreeSpinOverCallFun()
                end)
                
            local freeCoins = util_formatCoins(fsExtraData.lastWin,3)
            local boxCoins = util_formatCoins(fsExtraData.collectSelectWin + fsExtraData.collectSelectMaxWin,3)
            local freeCoinsTotal = util_formatCoins(self.m_runSpinResultData.p_fsWinCoins,3)
            local xiaozhu = util_createAnimation("PiggyLegendPirate_fgtanbanpig1.csb")
            util_setCascadeOpacityEnabledRescursion(view:findChild("Node_pig1"), true)
            util_setCascadeColorEnabledRescursion(view:findChild("Node_pig1"), true)
            util_setCascadeOpacityEnabledRescursion(view:findChild("Node_pig2"), true)
            util_setCascadeColorEnabledRescursion(view:findChild("Node_pig2"), true)

            if fsExtraData.collectNum then
                view:findChild("Button_1"):setBright(false)
                view:findChild("Button_1"):setTouchEnabled(false)
                -- 没有完成收集任务
                if fsExtraData.collectNum <= selfData.selectNumResult then
                    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_over_fs2.mp3")
                    view:findChild("Node_goal2"):setVisible(false)
                    view:findChild("Node_pig1"):addChild(xiaozhu)
                    xiaozhu:runCsbAction("idle1",false)
                    self:waitWithDelay(55/60,function (  )
                        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_over_fail_jian.mp3")
                        if not tolua.isnull(xiaozhu) then
                            xiaozhu:runCsbAction("actionframe2",false,function()
                                xiaozhu:runCsbAction("idle3",false)
                            end) 
                        end
                    end)
                    self:waitWithDelay(95/60,function (  )
                        view:findChild("Button_1"):setBright(true)
                        view:findChild("Button_1"):setTouchEnabled(true)
                    end)
                else
                    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_over_fs1.mp3")
                    
                    view:findChild("Node_goal1"):setVisible(false)
                    view:findChild("m_lb_coins_0"):setString(freeCoins.."+"..boxCoins.."="..freeCoinsTotal)
                    view:findChild("Node_pig2"):addChild(xiaozhu)
                    xiaozhu:runCsbAction("idle1",false)
                    self:waitWithDelay(55/60,function (  )
                        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_over_jian.mp3")
                        if not tolua.isnull(xiaozhu) then
                            xiaozhu:runCsbAction("actionframe1",false,function()
                                xiaozhu:runCsbAction("idle2",false)
                            end) 
                        end
                    end)
                    self:waitWithDelay(110/60,function (  )
                        view:findChild("Button_1"):setBright(true)
                        view:findChild("Button_1"):setTouchEnabled(true)
                    end)
                end
                view:findChild("m_lb_num_0_0"):setString(fsExtraData.collectNum.."/"..selfData.selectNumResult)
            end

            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=1,sy=1},800)
        end
        self.m_isFreeFlyCoin1 = true
        self.m_isFreeFlyCoin2 = true
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    end
end

function CodeGameScreenPiggyLegendPirateMachine:showSuperFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num_0"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog("SuperFreeSpinOver", ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenPiggyLegendPirateMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num_0"] = num
    ownerlist["m_lb_num_1"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenPiggyLegendPirateMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("Levels.BaseDialog")
    
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)
    view.m_btnTouchSound = "PiggyLegendPirateSounds/sound_PiggyLegendPirates_Click.mp3"

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

function CodeGameScreenPiggyLegendPirateMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func,self)
end

-- 结束respin收集
function CodeGameScreenPiggyLegendPirateMachine:playLightEffectEnd()
    
    -- 通知respin结束
    self:respinOver()
 
end

function CodeGameScreenPiggyLegendPirateMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)  then
            -- 如果全部都固定了，会中JackPot档位中的Grand
            local jackpotScore = self:BaseMania_getJackpotScore(1)
            self.m_lightScore = self.m_lightScore + jackpotScore
            self:showRespinJackpot(
                4,
                util_formatCoins(jackpotScore, 12),
                function()
                    -- 此处跳出迭代
                    self:playLightEffectEnd()        
                end
            )
        else
            -- 此处跳出迭代
            self:playLightEffectEnd()
        
        end
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    -- 根据网络数据获得当前固定小块的分数
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    -- local lineBet = globalData.slotRunData:getCurTotalBet()
    local curBet = 1
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self:BaseMania_getJackpotScore(1)
            addScore = jackpotScore + addScore
            nJackpotType = 4
        elseif score == "MAJOR" then
            jackpotScore = self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINOR" then
            jackpotScore =  self:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                  ---self:BaseMania_getJackpotScore(3)
            nJackpotType = 2
        elseif score == "MINI" then
            jackpotScore = self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                      ---self:BaseMania_getJackpotScore(4)
            nJackpotType = 1
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self. m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else
            self:showRespinJackpot(nJackpotType, util_formatCoins(jackpotScore,12), function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end)
          
        end
    end
    runCollect()    
end

--结束移除小块调用结算特效
function CodeGameScreenPiggyLegendPirateMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    
    --隐藏小块快滚提示
    -- self.m_respinView:changeLastOneAnimTipVisible(false)
    if self.m_isPlayReSpinQuick then
        self.m_isPlayReSpinQuick = false
        local chipList = self.m_respinView:getAllCleaningNode()
        if #chipList >= 15 then
            self.m_respinView:playIdle3ByQuickOver()
        end
    end

    -- 换一种结算方式
    -- 获得所有固定的respinBonus小块 
    -- self.m_chipList = self.m_respinView:getAllCleaningNode()    
    -- self:playChipCollectAnim()

    self:waitWithDelay(0.5,function (  )
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_jiesuanBox.mp3")
        util_spinePlay(self.m_reSpinBox.m_respinBoxSpine,"actionframe1",false)
        util_spineEndCallFunc(self.m_reSpinBox.m_respinBoxSpine, "actionframe1", function()
            self.m_respinView:playActionframe3ByQuickOver()
            self:respinOver()
        end)
    end)
end

--[[
    reSpin相关
]]
function CodeGameScreenPiggyLegendPirateMachine:showRespinView()
    self.m_bCanClickMap = false
    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if self:isFixSymbol(node.p_symbolType) then
                    local symbolNode = util_setSymbolToClipReel(self,iCol, iRow, node.p_symbolType,0)
                    curBonusList[#curBonusList + 1] = node
                end
            end
        end
    end

    for _, _bonusNode in ipairs(curBonusList) do
        _bonusNode:runAnim("actionframe",false,function (  )
            _bonusNode:runAnim("idle",true)
        end)
    end
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_BonusTrigger.mp3")

    self:waitWithDelay(2,function (  )
        --先播放动画 再进入respin
        self:playReSpinGuoChangAnim(
            function()
                self:checkChangeBaseParent()

                local reSpinWinCoins = self.m_runSpinResultData.p_resWinCoins or 0
                -- 断线之后 需要重新计算赢钱 所以有赢钱的话 先减去
                local lastWinCoins = 0
                if self.m_runSpinResultData.p_rsExtraData.bonus2 then
                    for i,v in ipairs(self.m_runSpinResultData.p_rsExtraData.bonus2) do
                        lastWinCoins = lastWinCoins + v[2]
                    end
                end
                if self.m_runSpinResultData.p_rsExtraData.bonus3 and self.m_runSpinResultData.p_rsExtraData.bonus3.bonus1 then
                    for i,v in ipairs(self.m_runSpinResultData.p_rsExtraData.bonus3.bonus1) do
                        lastWinCoins = lastWinCoins + v[2]
                    end
                end
                self.m_reSpinBox:updateWinCoinsLabel(reSpinWinCoins-lastWinCoins)
                self.m_reSpinBox:playStartAnim()
                self.m_reSpinBar:showTimes(self.m_runSpinResultData.p_reSpinCurCount)
                self.m_reSpinBar:playStartAnim()
                self:setReelBg(3)

                self.m_progress:setVisible(false)

                --清空赢钱
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

                self:clearCurMusicBg()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )
                --可随机的特殊信号 
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)
            end,
            function()
                self:showReSpinStart(
                    function()
                        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                        -- 更改respin 状态下的背景音乐
                        self:changeReSpinBgMusic()
                        self:addPiggyLegendPirateReSpinGameEffect()
                        self:waitWithDelay(0.5, function()
                            self:playPiggyLegendPirateReSpinGameEffect(function()
                                self:runNextReSpinReel()
                            end)
                        end)
                    end)
            end)
    end)
end

--开始下次ReSpin
function CodeGameScreenPiggyLegendPirateMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:resetRespinBulingSound()
                self.m_respinQuickStop = false
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end

--- respin 快停
function CodeGameScreenPiggyLegendPirateMachine:quicklyStop()
    self.m_respinQuickStop = true
    self.m_respinView:quicklyStop()
end

function CodeGameScreenPiggyLegendPirateMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_reSpinBonusQuickPos = self.m_runSpinResultData.p_rsExtraData.bonus3NextPos

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            
        end
    )
    for _, nodeInfo in ipairs(respinNodeInfo) do
        if nodeInfo.Type == self.SYMBOL_BONUS3 then
            local reSpinSlotsNode = self.m_respinView:getPiggyLegendPirateSymbolNode(nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY)
            local bonus3Pos   = util_convertToNodeSpace(reSpinSlotsNode, self:findChild("Node_respinBonus"))
            local bonus3TempNode =  util_spineCreate("Socre_PiggyLegendPirate_Bonus3", true, true) 
            self:findChild("Node_respinBonus"):addChild(bonus3TempNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+10)
            -- bonus3TempNode:setScale(self.m_machineRootScale*1.1)
            bonus3TempNode:setPosition(bonus3Pos)
            util_spinePlay(bonus3TempNode,"idle",true)
        end
    end
    
    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenPiggyLegendPirateMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if not self:isFixSymbol(symbolType) then
                if symbolType ~= self.SYMBOL_BONUS2 and symbolType ~= self.SYMBOL_BONUS3 then
                    symbolType = self.SYMBOL_RS_SCORE_BLANK
                end
            end

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

function CodeGameScreenPiggyLegendPirateMachine:showReSpinStart(func)
    self:clearCurMusicBg()
        
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_start.mp3")
    self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_ONLY,nil,false)
end

function CodeGameScreenPiggyLegendPirateMachine:showRespinOverView(effectData)

    local strCoins = util_formatCoins(self.m_serverWinCoins, 30)
    local view = self:showReSpinOver(strCoins,function()
        self.m_reSpinBox:playOverAnim()
        self.m_reSpinBar:playOverAnim()

        self:setReelBg(1)
        self.m_progress:setVisible(true)
        self.m_bCanClickMap = true

        self:triggerReSpinOverCallFun(self.m_serverWinCoins)
        self.m_lightScore = 0
        self:resetMusicBg() 
    end)

    local respinOverEffect = util_createAnimation("PiggyLegendPirate/ReSpinOver_g.csb")
    view:findChild("ef_g"):addChild(respinOverEffect)
    respinOverEffect:runCsbAction("actionframe",true)
    util_setCascadeOpacityEnabledRescursion(view:findChild("ef_g"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("ef_g"), true)

    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_over.mp3")

    if view:findChild("m_lb_coins") then
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},800)
    end
end

function CodeGameScreenPiggyLegendPirateMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    if coins == "0" then
        return self:showDialog("ReSpinOver_0", ownerlist, func, nil, index)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func, nil, index)
    end
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

function CodeGameScreenPiggyLegendPirateMachine:playReSpinGuoChangAnim(_switchFun,_endFun)
    self.m_GuoChang:setVisible(true) 
    util_spinePlay(self.m_GuoChang,"actionframe")

    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_guochang_respin.mp3")

    self:runCsbAction("actionframe",false,function (  )
        self:runCsbAction("idleframe",false)
        self.m_GuoChang:setVisible(false) 
        util_spinePlay(self.m_respinBgSpine, "idleframe2", true)
    end)

    local switchTime = 231/60
    self:waitWithDelay(switchTime, function()
        if _switchFun then
            _switchFun()
        end
    end)

    local endTime = 380/60
    self:waitWithDelay(endTime, function()
        if _endFun then
            _endFun()
        end
    end)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenPiggyLegendPirateMachine:getRespinRandomTypes( )
    local symbolList = { 
        self.SYMBOL_BONUS1,
        self.SYMBOL_BONUS2,
        self.SYMBOL_BONUS3,
        self.SYMBOL_RS_SCORE_BLANK,
    }

    return symbolList
end
-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenPiggyLegendPirateMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS1, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling2", bRandom = true},
    }

    return symbolList
end
-- 继承底层respinView
function CodeGameScreenPiggyLegendPirateMachine:getRespinView()
    return "CodePiggyLegendPirateSrc.PiggyLegendPirateRespinView"
end
-- 继承底层respinNode
function CodeGameScreenPiggyLegendPirateMachine:getRespinNode()
    return "CodePiggyLegendPirateSrc.PiggyLegendPirateRespinNode"
end

--reSpin过程中的事件
function CodeGameScreenPiggyLegendPirateMachine:reSpinReelDown(addNode)
    --隐藏小块快滚提示
    -- self.m_respinView:changeLastOneAnimTipVisible(false)
    if self.m_isPlayReSpinQuick then
        self.m_isPlayReSpinQuick = false
        local chipList = self.m_respinView:getAllCleaningNode()
        if #chipList >= 15 then
            self.m_respinView:playIdle3ByQuickOver()
        end
    end
    -- self.m_reSpinBonusQuickPos = self.m_respinView:getSymbolQuickPos()
    self.m_reSpinBonusQuickPos = self.m_runSpinResultData.p_rsExtraData.bonus3NextPos
    self.m_serverWinCoins = self.m_runSpinResultData.p_resWinCoins or self.m_serverWinCoins
    self:addPiggyLegendPirateReSpinGameEffect()
    self:waitWithDelay(0.3, function()
        self.m_RESPIN_RUN_TIME = 1.2
        self:playPiggyLegendPirateReSpinGameEffect(function()
            
            CodeGameScreenPiggyLegendPirateMachine.super.reSpinReelDown(self,addNode) 
        end)
    end)
    
end
function CodeGameScreenPiggyLegendPirateMachine:addPiggyLegendPirateReSpinGameEffect()
    self.m_reSpinGameEffectList = {}

    local reSpinExtraData = self.m_runSpinResultData.p_rsExtraData or {}

    if nil ~= reSpinExtraData.bonus3 then
        local reSpinGameEffect = {
            effectType = 2,
            effectData = reSpinExtraData.bonus3,
        }
        table.insert(self.m_reSpinGameEffectList, reSpinGameEffect)
    end
    if reSpinExtraData.bonus2 and #reSpinExtraData.bonus2 > 0 then
        local reSpinGameEffect = {
            effectType = 1,
            effectData = reSpinExtraData.bonus2,
        }
        table.insert(self.m_reSpinGameEffectList, reSpinGameEffect)
    end

end
function CodeGameScreenPiggyLegendPirateMachine:playPiggyLegendPirateReSpinGameEffect(_func)
    if #self.m_reSpinGameEffectList < 1 then
        if _func then
            _func()
        end
        return
    end

    local reSpinGameEffect = table.remove(self.m_reSpinGameEffectList, 1)
    if 1 == reSpinGameEffect.effectType then
        self:playReSpinEffect_bonus2(reSpinGameEffect.effectData, function()
            self:playPiggyLegendPirateReSpinGameEffect(_func)
        end)
    elseif 2 == reSpinGameEffect.effectType then
        self:playReSpinEffect_bonus3(reSpinGameEffect.effectData, function()
            self:playPiggyLegendPirateReSpinGameEffect(_func)
        end)
    end
end
-- reSpinGameEffect 收集bonus2
function CodeGameScreenPiggyLegendPirateMachine:playReSpinEffect_bonus2(_data, _func)
    local flyInterval = 0.1
    local blankType = self.SYMBOL_RS_SCORE_BLANK
    local endPos = util_convertToNodeSpace(self.m_reSpinBox:findChild("Node_respintotalwin"), self:findChild("Node_respinBonus"))
    for _index, _bonus2Info in ipairs(_data) do
        local index = _index
        local iPos  = _bonus2Info[1]
        local multi = _bonus2Info[2]
        local fixPos     = self:getRowAndColByPos(iPos)
        local reSpinSlotsNode = self.m_respinView:getPiggyLegendPirateSymbolNode(fixPos.iX, fixPos.iY)
        local startPos = cc.p(0,0)
        if reSpinSlotsNode and reSpinSlotsNode.p_symbolType then
            startPos = util_convertToNodeSpace(reSpinSlotsNode, self:findChild("Node_respinBonus"))
            --隐藏原图标
            local ccbName = self:getSymbolCCBNameByType(self, blankType)
            reSpinSlotsNode:changeCCBByName(ccbName, blankType)
            reSpinSlotsNode:changeSymbolImageByName(ccbName)
            reSpinSlotsNode:runIdleAnim()
        end
        
        --创建飞行节点
        local flyNode = util_createAnimation("Socre_PiggyLegendPirate_Bonus2.csb")
        self:findChild("Node_respinBonus"):addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+100)
        flyNode:setPosition(startPos)
        local curBet = 1
        local score  = curBet * multi
        local sScore = util_formatCoins(score, 3)
        flyNode:findChild("m_lb_score"):setString(sScore)
        
        if index == #_data then
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_jinbi_fly.mp3")
        end

        flyNode:runCsbAction("actionframe", false, function()
            -- 拖尾粒子
            local tuowei = util_createAnimation("PiggyLegendPirate_symbol_tw.csb")
            flyNode:findChild("Node_tuowei"):addChild(tuowei)
            for ParticleIndex = 1, 2 do
                local particle = tuowei:findChild("Particle_"..ParticleIndex)
                if particle then
                    particle:setPositionType(0)
                    particle:setDuration(0.5)
                    particle:stopSystem()
                    particle:resetSystem() 
                end
            end
            --动作
            local actList = {}
            table.insert(actList, cc.EaseSineIn:create(cc.MoveTo:create(30/60, endPos)))
            self:waitWithDelay(30/60, function()
                self.m_reSpinBox:collectWinCoins(score,index == 1)
            end)
            flyNode:runCsbAction("feixing", false, function()
                for i=1,2 do
                    local particle = tuowei:findChild("Particle_"..i)
                    particle:stopSystem()
                end
                self:waitWithDelay(0.5, function()
                    flyNode:removeFromParent()
                end)
                
            end)
            flyNode:runAction(cc.Sequence:create(actList))
        end)

    end
    self:waitWithDelay(1.2, function()
        if #self.m_scoreWinCoinList > 0 or #self.m_jackpotWinCoinList > 0 then
            self:waitWithDelay(1, function()
                self:playBonus1BombCollect(self.m_scoreWinCoinList, self.m_jackpotWinCoinList, _func)
            end)
        else
            if _func then
                _func()
            end
        end
    end)
end

-- reSpinGameEffect bonus3爆炸
function CodeGameScreenPiggyLegendPirateMachine:playReSpinEffect_bonus3(_data, _func)
    local bonus3iPos = _data.pos
    local bonus3FixPos = self:getRowAndColByPos(bonus3iPos)
    local bonus3ReSpinNode = self.m_respinView:getRespinNode(bonus3FixPos.iX, bonus3FixPos.iY)
    local bonus3SlotsNode  = self.m_respinView:getPiggyLegendPirateSymbolNode(bonus3FixPos.iX, bonus3FixPos.iY)
    local bonus3Pos = util_convertToNodeSpace(bonus3SlotsNode, self:findChild("Node_respinBonus"))
    -- {{0,1}, {2,3}}
    -- 斜着算爆炸梯度
    local bonus1BombList = {}
    local bombInterval   = 0.12
    local intervalDistance = cc.pGetDistance(cc.p(0,0), cc.p(self.m_SlotNodeW, self.m_SlotNodeH))
    local curBet = 1
    local maxDelayTime = 0
    for i,_bonus1Data in ipairs(_data.bonus1) do
        local iPos = _bonus1Data[1]
        local winMulti = _bonus1Data[2]
        local fixPos = self:getRowAndColByPos(iPos)
        local reSpinNode = self.m_respinView:getRespinNode(fixPos.iX, fixPos.iY)
        local slotsNode = self.m_respinView:getPiggyLegendPirateBonus1Node(fixPos.iX, fixPos.iY)
        local distance = cc.pGetDistance(bonus3Pos, util_convertToNodeSpace(slotsNode, self:findChild("Node_respinBonus")))

        bonus1BombList[iPos] = {
            delayTime   = bombInterval * math.ceil(distance / intervalDistance),
            reSpinNode  = reSpinNode,
            slotsNode   = slotsNode,
            winCoinData = {
                curBet * winMulti,
                _bonus1Data[3] or "",
            },
        }
        maxDelayTime = math.max(maxDelayTime, bonus1BombList[iPos].delayTime)
    end

    local reSpinBlankType = self.SYMBOL_RS_SCORE_BLANK
    local reSpinBlankCcbName = self:getSymbolCCBNameByType(self, reSpinBlankType)

    self:findChild("Node_respinBonus"):removeAllChildren()

    -- 原地变空
    bonus3SlotsNode:changeCCBByName(reSpinBlankCcbName, reSpinBlankType)
    bonus3SlotsNode:changeSymbolImageByName(reSpinBlankCcbName)
    bonus3SlotsNode:runIdleAnim()
    -- 锁定状态变更
    if RESPIN_NODE_STATUS.IDLE ~= bonus3ReSpinNode:getRespinNodeStatus() then
        bonus3ReSpinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
        bonus3ReSpinNode:setFirstSlotNode(bonus3SlotsNode)
    end
    -- 临时炸弹 
    local bonus3Type = self.SYMBOL_BONUS3
    local bonus3TempNode =  util_spineCreate("Socre_PiggyLegendPirate_Bonus3", true, true) 
    self:findChild("Node_respinBonus"):addChild(bonus3TempNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+103)
    bonus3TempNode:setPosition(bonus3Pos)

    self:waitWithDelay(0.2+36/30, function()
        self:shakeNode()
    end)

    util_spinePlay(bonus3TempNode,"actionframe",false)
    self.m_respinView:playIdle3ByQuick()

    self:waitWithDelay(75/30, function()
        bonus3TempNode:removeFromParent()
    end)

    self:playBonus1BombEffect(bonus1BombList, reSpinBlankCcbName, reSpinBlankType)
    -- 有正式资源时需要修改时间长度
    local animTime = 2
    
    self:waitWithDelay(maxDelayTime + animTime, function()
        if #self.m_reSpinGameEffectList <= 0 then
            self:playBonus1BombCollect(self.m_scoreWinCoinList, self.m_jackpotWinCoinList, _func)
        else
            if _func then
                _func()
            end
        end
    end)
end

--[[
    按照距离依次爆炸bonus1
]]
function CodeGameScreenPiggyLegendPirateMachine:playBonus1BombEffect(bonus1BombList, reSpinBlankCcbName, reSpinBlankType)
    local winCoinList = {}
    --按照距离依次爆炸
    for _iPos, _bombData in pairs(bonus1BombList) do
        --[[
            _bombData = {
                delayTime   = 0,          --触发延时
                reSpinNode  = cc.Node,    --reSpin格子
                slotsNode   = cc.Node,    --reSpin的图标小块
                winCoinData = {
                    [1]     = 0,          --赢钱总数
                    [2]     = "",         --赢钱类型 (普通:"", jackpot:"mini" | "minor" | "major" | "grand")
                }
            }
        ]]
        local bombData = _bombData
        local postion = util_convertToNodeSpace(_bombData.slotsNode, self:findChild("Node_respinBonus"))
        
        -- 临时奖励
        local winCoinSymbol =  util_createAnimation("Socre_PiggyLegendPirate_Jinbi.csb") 
        winCoinSymbol._iPos = _iPos
        self:findChild("Node_respinBonus"):addChild(winCoinSymbol, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+100)
        winCoinSymbol:setPosition(postion)
        winCoinSymbol:setVisible(false)
        local winCoins = bombData.winCoinData[1]
        local winType  = bombData.winCoinData[2]
        winCoinSymbol:findChild("m_lb_coins"):setVisible(winType == "")
        winCoinSymbol:findChild("grand"):setVisible(winType == "grand")
        winCoinSymbol:findChild("major"):setVisible(winType == "major")
        winCoinSymbol:findChild("minor"):setVisible(winType == "minor")
        winCoinSymbol:findChild("mini"):setVisible( winType == "mini")
        if winType == "" then
            local sCoins = util_formatCoins(winCoins, 3)
            winCoinSymbol:findChild("m_lb_coins"):setString(sCoins)
        end
        --插入奖励列表
        table.insert(winCoinList,{
            slotsNode  = winCoinSymbol,
            winCoinData = bombData.winCoinData,
        })
        self:waitWithDelay(1.35+bombData.delayTime, function()
            -- 原地变空
            bombData.slotsNode:changeCCBByName(reSpinBlankCcbName, reSpinBlankType)
            bombData.slotsNode:changeSymbolImageByName(reSpinBlankCcbName)
            bombData.slotsNode:runIdleAnim()

            -- 锁定状态变更
            if RESPIN_NODE_STATUS.IDLE ~= bombData.reSpinNode:getRespinNodeStatus() then
                bombData.reSpinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
                bombData.reSpinNode:setFirstSlotNode(bombData.slotsNode) 
            end
            
            -- 临时信号
            local bonus1TempNode = util_spineCreate("PiggyLegendPirate_zhuposui", true, true)
            self:findChild("Node_respinBonus"):addChild(bonus1TempNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+102)
            bonus1TempNode:setPosition(postion)
            -- 破碎效果
            winCoinSymbol:setVisible(true)
            winCoinSymbol:runCsbAction("idleframe",true)

            util_spinePlay(bonus1TempNode, "actionframe", false)
            self:waitWithDelay(22/30, function()
                bonus1TempNode:removeFromParent()
            end)
        end)
    end
    
    self.m_scoreWinCoinList = {} --金币赢钱
    self.m_jackpotWinCoinList = {} --jackpot赢钱
    for i,v in ipairs(winCoinList) do
        if v.winCoinData[2] == "" then
            table.insert(self.m_scoreWinCoinList, v)
        else
            table.insert(self.m_jackpotWinCoinList, v)
        end
    end

    table.sort(self.m_jackpotWinCoinList, function(a, b)
        if a.winCoinData[1] == b.winCoinData[1] then
            return a.slotsNode._iPos < b.slotsNode._iPos
        end
        return a.winCoinData[1] < b.winCoinData[1]
    end)
end

-- 收集bonus1爆炸后的奖励
function CodeGameScreenPiggyLegendPirateMachine:playBonus1BombCollect(_scoreWinCoinList, _jackpotWinCoinList, _func)
    
    -- local data = _winCoinList[_animIndex]
    --[[
        data = {
            slotsNode = cc.Node, --飞行节点
            winCoinData = {
                [1] = 0,   --赢钱数值
                [2] = "",  --赢钱类型
            },
        }
    ]]
    for index, data in ipairs(_scoreWinCoinList) do
        local endPos = util_convertToNodeSpace(self.m_reSpinBox:findChild("Node_respintotalwin"), self:findChild("Node_respinBonus"))

        local flyNode = data.slotsNode
        local winCoinData = data.winCoinData

        if index == #_scoreWinCoinList then
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_jinbi_fly.mp3")
        end

        flyNode:runCsbAction("actionframe", false, function()
            -- 拖尾粒子
            local tuowei = util_createAnimation("PiggyLegendPirate_symbol_tw.csb")
            flyNode:findChild("Node_tuowei"):addChild(tuowei)
            for ParticleIndex = 1, 2 do
                local particle = tuowei:findChild("Particle_"..ParticleIndex)
                if particle then
                    particle:setPositionType(0)
                    particle:setDuration(0.5)
                    particle:stopSystem()
                    particle:resetSystem() 
                end
            end

            --动作
            local actList = {}
            table.insert(actList, cc.EaseSineIn:create(cc.MoveTo:create(30/60, endPos)))
            self:waitWithDelay(30/60, function()
                self.m_reSpinBox:collectWinCoins(winCoinData[1], index == 1)
            end)
            flyNode:setZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+100)
            flyNode:runCsbAction("feixing", false, function()
                for ParticleIndex = 1, 2 do
                    local particle = tuowei:findChild("Particle_"..ParticleIndex)
                    if particle then
                        particle:stopSystem()
                    end
                end
                self:waitWithDelay(0.5, function()
                    flyNode:removeFromParent()
                end)
            end)
            flyNode:runAction(cc.Sequence:create(actList))
        end)
    end

    self:waitWithDelay(75/60, function()
        -- 有jackpot赢钱
        if #_jackpotWinCoinList > 0 then
            self:waitWithDelay(1, function()
                self:playBonus1BombCollectJackpot(1, _jackpotWinCoinList, _func)
            end)
        else
            self.m_scoreWinCoinList = {} --金币赢钱
            self.m_jackpotWinCoinList = {} --jackpot赢钱
            if _func then
                _func()
            end
        end
    end)
end

-- 收集bonus1爆炸后的奖励
function CodeGameScreenPiggyLegendPirateMachine:playBonus1BombCollectJackpot(_animIndex, _jackpotWinCoinList, _func)
    if _animIndex > #_jackpotWinCoinList then
        self.m_scoreWinCoinList = {} --金币赢钱
        self.m_jackpotWinCoinList = {} --jackpot赢钱
        if _func then
            _func()
        end
        return
    end

    local data = _jackpotWinCoinList[_animIndex]
    --[[
        data = {
            slotsNode = cc.Node, --飞行节点
            winCoinData = {
                [1] = 0,   --赢钱数值
                [2] = "",  --赢钱类型
            },
        }
    ]]
    local endPos = util_convertToNodeSpace(self.m_reSpinBox:findChild("Node_respintotalwin"), self:findChild("Node_respinBonus"))

    local flyNode     = data.slotsNode
    local winCoinData = data.winCoinData
    self.m_jackPotBar:playJackPotActionframe(winCoinData[2])

    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_jackpot_fly.mp3")

    flyNode:runCsbAction("actionframe", false, function()
        -- 拖尾粒子
        local tuowei = util_createAnimation("PiggyLegendPirate_symbol_tw.csb")
        flyNode:findChild("Node_tuowei"):addChild(tuowei)
        for ParticleIndex = 1, 2 do
            local particle = tuowei:findChild("Particle_"..ParticleIndex)
            if particle then
                particle:setPositionType(0)
                particle:setDuration(0.5)
                particle:stopSystem()
                particle:resetSystem() 
            end
        end

        --动作
        local actList = {}
        table.insert(actList, cc.EaseSineIn:create(cc.MoveTo:create(30/60, endPos)))
        self:waitWithDelay(21/60, function()
            self.m_reSpinBox:collectWinCoins(winCoinData[1],true,true)
            self:waitWithDelay(0.5, function()
                self:showRespinJackpot(winCoinData[2], winCoinData[1], function()
                    self:playBonus1BombCollectJackpot(_animIndex+1, _jackpotWinCoinList, _func)
                end)
            end)
        end)

        flyNode:setZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+100)
        flyNode:runCsbAction("feixing", false, function()
            for ParticleIndex = 1 , 2 do
                local particle = tuowei:findChild("Particle_"..ParticleIndex)
                if particle then
                    particle:stopSystem()
                end
            end
            self:waitWithDelay(0.5, function()
                flyNode:removeFromParent()
            end)
        end)
        flyNode:runAction(cc.Sequence:create(actList))
    end)
end
--========================reSpin相关 end

--ReSpin开始改变UI状态
function CodeGameScreenPiggyLegendPirateMachine:changeReSpinStartUI(respinCount)
   print("[CodeGameScreenPiggyLegendPirateMachine:changeReSpinStartUI]", respinCount)
end

--ReSpin刷新数量
function CodeGameScreenPiggyLegendPirateMachine:changeReSpinUpdateUI(curCount)
    print("[CodeGameScreenPiggyLegendPirateMachine:changeReSpinUpdateUI]", curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenPiggyLegendPirateMachine:changeReSpinOverUI()
    print("[CodeGameScreenPiggyLegendPirateMachine:changeReSpinOverUI]")
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPiggyLegendPirateMachine:MachineRule_SpinBtnCall()
    self.m_isTriggerLongRun = false
    self:setMaxMusicBGVolume()

    if self.m_scheduleId then
        self:showTipsOverView()
    end

    return false -- 用作延时点击spin调用
end

---
-- 进入关卡
--
function CodeGameScreenPiggyLegendPirateMachine:enterLevel()
    
    CodeGameScreenPiggyLegendPirateMachine.super.enterLevel(self)

    --显示提示
    self:waitWithDelay(0.3,function (  )
        self:showTipsOpenView()
    end)
end

function CodeGameScreenPiggyLegendPirateMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
       self:playEnterGameSound("PiggyLegendPirateSounds/music_PiggyLegendPirate_enter.mp3")

    end,0.4,self:getModuleName())
end

function CodeGameScreenPiggyLegendPirateMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenPiggyLegendPirateMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    local pecent =  self:getProgressPecent(true)
    self.m_progress:updateLoadingbar(pecent,false)
end

function CodeGameScreenPiggyLegendPirateMachine:addObservers()
    CodeGameScreenPiggyLegendPirateMachine.super.addObservers(self)
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:showMapScroll(nil)
    end,"SHOW_BONUS_MAP")

end

function CodeGameScreenPiggyLegendPirateMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenPiggyLegendPirateMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

end

--gameConfig数据
function CodeGameScreenPiggyLegendPirateMachine:initGameStatusData( gameData )
    CodeGameScreenPiggyLegendPirateMachine.super.initGameStatusData( self, gameData )
    if gameData then
        if gameData.gameConfig then
            if gameData.gameConfig.extra then
                if gameData.gameConfig.extra.map then
                    self.m_bonusData = clone(gameData.gameConfig.extra)
                end
            end
        end
    end
end

function CodeGameScreenPiggyLegendPirateMachine:getProgressPecent(_init)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local collectProcess = nil 
    local maxCount = 0
    local currCount = 0

    -- 第一次进入取gameConfig的数据
    if  not collectProcess and _init then
        collectProcess = self.m_bonusData.collectProcess
        if collectProcess then
            maxCount = collectProcess.target or 0
            currCount = collectProcess.collect or 0
            selfData.collectPos = collectProcess.pos
        end
    else
        if selfData.collectPos and selfData.collectNum and selfData.collectNumAll then
            collectProcess = {}
            collectProcess.pos = selfData.collectPos
            collectProcess.collectNum = selfData.collectNum
            collectProcess.collectNumAll = selfData.collectNumAll
        end
        if collectProcess ~= nil then
            maxCount = collectProcess.collectNumAll or 0
            currCount = collectProcess.collectNum or 0
        end
    end

    local percent = currCount / maxCount * 100

    return percent
end

-- ------------玩法处理 -- 
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPiggyLegendPirateMachine:addSelfEffect()
        
    --base收集
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.storedIcons 
        and #self.m_runSpinResultData.p_selfMakeData.storedIcons > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_TYPE_COLLECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
    end 

    --free收集
    if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.storedIcons 
        and #self.m_runSpinResultData.p_fsExtraData.storedIcons > 0 then 
        if self.m_runSpinResultData.p_fsExtraData.collectNum <= self.m_runSpinResultData.p_selfMakeData.selectMaxNum or 
            self.m_lastFreeCollectNum < self.m_runSpinResultData.p_selfMakeData.selectMaxNum then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_TYPE_COLLECT_FREE
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT_FREE
        end
        self.m_lastFreeCollectNum = self.m_runSpinResultData.p_fsExtraData.collectNum
    end 

    -- base收集满 触发
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectOccur = selfData.collectOccur or false
    local collectWinCoins = selfData.collectWinCoins
    if collectWinCoins or collectOccur then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        if collectWinCoins then
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
        else
            selfEffect.p_effectOrder = GameEffect.EFFECT_FIVE_OF_KIND + 1
        end
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
    end

    -- reSpin的bonus3提示坐标
    if self.m_runSpinResultData.p_rsExtraData then
        local reSpinExtraData = self.m_runSpinResultData.p_rsExtraData
        self.m_reSpinBonus3Pos = reSpinExtraData.bonus3NextPos or nil
        self.m_reSpinBonusQuickPos = reSpinExtraData.bonus3NextPos
    end
end

-- 检查进度条集满
function CodeGameScreenPiggyLegendPirateMachine:checkEffetJiMan( )
    if self:checkGameEffectType(self.EFFECT_TYPE_COLLECT_FREE) or 
        self:checkGameEffectType(self.BONUS_GAME_EFFECT) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
        
        return true
    end
    return false
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenPiggyLegendPirateMachine:checkGameEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_selfEffectType
        if value == effectType then
            return true
        end
    end

    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPiggyLegendPirateMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        self.m_bCanClickMap = false
        self:waitWithDelay(0.5,function (  )
            self:showEffect_collectCoin(effectData)
        end)
    end

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT_FREE then
        self:waitWithDelay(0.5,function (  )
            self:showEffect_collectCoin_Free(effectData)
        end)
    end

    if effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
        local waitTime = 0
        if self.m_runSpinResultData.p_winLines == 0 then
            waitTime = 0
        else
            waitTime = 1
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local collectWin = selfData.collectWinCoins or 0
            globalData.userRunData:setCoins(globalData.userRunData.coinNum - collectWin)
        end
        self.m_bCanClickMap = false

        self:waitWithDelay(waitTime,function (  )
            self:clearCurMusicBg()
            self.m_progress:showJiMan(function (  )
                self:showEffect_CollectBonus(effectData)
            end)
        end)
    end

	return true
end

 -- 小猪收集的时候 棋盘上的小猪 播放反馈动画
function CodeGameScreenPiggyLegendPirateMachine:playXiaoZhuBonusCollectEffect(_func)
    if _func then
        _func()
    end
end

-- base下收集
function CodeGameScreenPiggyLegendPirateMachine:showEffect_collectCoin(effectData)
    local collectList = self.m_runSpinResultData.p_selfMakeData.storedIcons
    local endNode = self.m_progress:findChild("pig")
    local progressPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local newProgressPos = self:convertToNodeSpace(progressPos)
    local endPos = cc.p(newProgressPos)
    local function flyShow ( startPos,endPos,indexPos,index)
        local actionList = {}
        local actionList1 = {}
        local collectNode = util_spineCreate("Socre_PiggyLegendPirate_Bonus1",true,true)
        util_spinePlay(collectNode, "idleframe2", false)   
        self:addChild(collectNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + indexPos)

        collectNode:setPosition(startPos)
        actionList[#actionList + 1] = cc.EaseSineIn:create(cc.BezierTo:create(10/30,{cc.p(startPos.x , startPos.y), cc.p(endPos.x, startPos.y), endPos}))
        self:waitWithDelay(10/30, function()
            collectNode:setVisible(false)
            collectNode:removeFromParent()
            self.m_progress:runCsbAction("actionframe",false,function()
                self.m_progress:runCsbAction("idle",true)
            end)
            if index == #collectList then
                gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_Bonus_progress_collect.mp3")
            end
        end)

        actionList1[#actionList1 + 1] = cc.ScaleTo:create(10/30, 0.5)

        local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList), cc.Sequence:create(actionList1))

        collectNode:runAction(cc.Sequence:create(spawnAct))
    end
    
    for index = #collectList, 1, -1 do
        local fixPos1 = self:getRowAndColByPos(collectList[index][1])
        local startPos =  self:getNodePosByColAndRow( fixPos1.iX, fixPos1.iY)
        local newStartPos = self:convertToNodeSpace(startPos)
        flyShow(newStartPos,endPos,collectList[index][1], index)
    end
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_BonusFly.mp3")
        
    local pecent = self:getProgressPecent()

    local isJiman = self:checkEffetJiMan()
    if not isJiman then
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    self:waitWithDelay(10/30+42/60,function (  )
        self:playXiaoZhuBonusCollectEffect(function()
            local time = 0
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local collectWin = selfData.collectWinCoins 
            local features = self.m_runSpinResultData.p_features or {}

            --触发收集小游戏 播放完收集
            if collectWin or #features >= 2 then 
                time = 30/30
            end

            self:waitWithDelay(time,function(  )
                self.m_bCanClickMap = true
                if isJiman then
                    self.m_bCanClickMap = false
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end)
        end)
        --收集反馈，进度条增长
        self.m_progress:updateLoadingbar(pecent,true)
        util_spinePlay(self.m_progress.m_progressZhuSpine, "actionframe", false)
        util_spineEndCallFunc(self.m_progress.m_progressZhuSpine, "actionframe", function()
            util_spinePlay(self.m_progress.m_progressZhuSpine, "idleframe", true)
        end)
    end)
end

function CodeGameScreenPiggyLegendPirateMachine:showEffect_CollectBonus(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self.m_bottomUI:showAverageBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = 1
    currentPos = selfData.collectPos
    self.m_mapNodePos = currentPos -- 更新最新位置
    local collectWinCoins = selfData.collectWinCoins or 0
    local collectOccur = selfData.collectOccur or false

    self.m_bCanClickMap = true
    
    self:showMapScroll(function(  )
        self:waitWithDelay(0.5,function (  )
            self.m_progress:updateLoadingbar(0,false)
            if self.m_map then
                self.m_map:pandaMove(function(  )
                    if collectOccur then
                        self.m_fsReelDataIndex = self:getcollectFsStates(self.m_mapNodePos)
                        self:waitWithDelay(0.5,function (  )
                            self:hideMapScroll(function (  )
                            end)
                        end)
                        self:resetMusicBg(true)
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    else
                        self:waitWithDelay(0.5,function (  )
                            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                            local collectWin = selfData.collectWinCoins or 0
                            globalData.userRunData:setCoins(globalData.userRunData.coinNum + collectWin)
                            local view = self:showMapXiaoguanView(collectWinCoins,function(  )
                                self:playCoinWinEffectUI()
                                local beginCoins =  self.m_serverWinCoins - collectWinCoins
                                self:updateBottomUICoins(beginCoins,collectWinCoins,true,nil,false)
        
                                if #self.m_runSpinResultData.p_winLines == 0 then
                                    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.BONUS_GAME_EFFECT)
                                end
                                self:hideMapScroll(function (  )
                                    self.m_bottomUI:hideAverageBet()
                                    self:resetMusicBg(true)
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end)
                            end)
                            local respinOverEffect = util_createAnimation("PiggyLegendPirate/ReSpinOver_g.csb")
                            view:findChild("ef_g"):addChild(respinOverEffect)
                            respinOverEffect:runCsbAction("actionframe",true)
                            util_setCascadeOpacityEnabledRescursion(view:findChild("ef_g"), true)
                            util_setCascadeColorEnabledRescursion(view:findChild("ef_g"), true)

                            local node=view:findChild("m_lb_coins")
                            view:updateLabelSize({label=node,sx=1,sy=1},800)
                        end)
                    end
                end, self.m_bonusData.map, currentPos, collectWinCoins)
            end
        end)
    end,self.m_mapNodePos,true)
end

function CodeGameScreenPiggyLegendPirateMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop,isPlayAnim,isRespin)
    -- free下不需要考虑更新左上角赢钱
    local endCoins = beiginCoins + currCoins
    if isRespin then
        globalData.slotRunData.lastWinCoin = beiginCoins + currCoins
    else
        globalData.slotRunData.lastWinCoin = self.m_serverWinCoins
    end

    local params = {endCoins,isNotifyUpdateTop,isPlayAnim,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

-- 显示地图小关 赢钱弹板
function CodeGameScreenPiggyLegendPirateMachine:showMapXiaoguanView(coins,func1)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins,50)

    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_map_xiaoguan_over.mp3")

    return self:showDialog("MapXiaoGuanOver",ownerlist,func1)

    --也可以这样写 
end

-- free下收集
function CodeGameScreenPiggyLegendPirateMachine:showEffect_collectCoin_Free(effectData)
    local collectList = self.m_runSpinResultData.p_fsExtraData.storedIcons
    local endNode = self:findChild("Node_freewanted")
    local progressPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local newProgressPos = self:convertToNodeSpace(progressPos)
    local endPos = cc.p(newProgressPos)
    endPos.y = endPos.y + 70
    local function flyShow ( startPos,endPos,indexPos,index)
        local actionList = {}
        local actionList1 = {}
        local collectNode = util_spineCreate("Socre_PiggyLegendPirate_Bonus1",true,true)
        util_spinePlay(collectNode, "idleframe2", false)   
        self:addChild(collectNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + indexPos)

        collectNode:setPosition(startPos)

        actionList[#actionList + 1] = cc.EaseSineIn:create(cc.BezierTo:create(10/30,{cc.p(startPos.x , startPos.y), cc.p(endPos.x, startPos.y), endPos}))
        self:waitWithDelay(10/30, function()
            collectNode:setVisible(false)
            collectNode:removeFromParent()
            if index == #collectList then
                gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_Bonus_free_collect.mp3")
            end
        end)
        actionList1[#actionList1 + 1] = cc.ScaleTo:create(10/30, 0.8)

        local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList), cc.Sequence:create(actionList1))

        collectNode:runAction(cc.Sequence:create(spawnAct))
    end
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_free_BonusFly.mp3")

    for i = #collectList, 1, -1 do
        local fixPos1 = self:getRowAndColByPos(collectList[i][1])
        local startPos =  self:getNodePosByColAndRow( fixPos1.iX, fixPos1.iY)
        local newStartPos = self:convertToNodeSpace(startPos)
        flyShow(newStartPos,endPos,collectList[i][1],i)
    end
    
    self:waitWithDelay(10/30,function (  )
        --收集反馈
        self:freeCollectUpdata(true, function()
            self:playXiaoZhuBonusCollectEffect(function()
                local time = 0
                self:waitWithDelay(time,function(  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)
        end)
    end)
end

--free 收集的 时候 赢钱 飞
function CodeGameScreenPiggyLegendPirateMachine:freeFlyCopins(node, coin, func)
    local moveStartPosWorld = node:findChild("m_lb_coins"):getParent():convertToWorldSpace(cc.p(node:findChild("m_lb_coins"):getPosition()))
    local moveStartPos = self:convertToNodeSpace(moveStartPosWorld)
    local moveEndPosWorld = self.m_freeBox:findChild("Node_baoxiang"):getParent():convertToWorldSpace(cc.p(self.m_freeBox:findChild("Node_baoxiang"):getPosition()))
    local moveEndPos = self:convertToNodeSpace(moveEndPosWorld)

    local actionList = {}
    local flyNode = util_createAnimation("PiggyLegendPirate_m_lb_coins.csb")
    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(coin, 3))
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
    flyNode:setPosition(moveStartPos)
    actionList[#actionList + 1] = cc.MoveTo:create(7/30,moveEndPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_free_boxCoinFly_end.mp3")
        if func then
            func()
        end
        flyNode:setVisible(false)
        flyNode:removeFromParent()
        flyNode = nil
    end)
    local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_free_boxCoinFly.mp3")
    flyNode:runAction(cc.Sequence:create(spawnAct))
end

--[[
    播放FreeWanted 动画
]]
function CodeGameScreenPiggyLegendPirateMachine:playFreeWantedEffect( )
    util_spinePlay(self.m_freewanted_zhu, "buling4", false)
    util_spineEndCallFunc(self.m_freewanted_zhu,"buling4",function ()
        util_spinePlay(self.m_freewanted_zhu, "idleframe4", true)
    end) 
end

--[[
    播放FreeWanted1 动画
]]
function CodeGameScreenPiggyLegendPirateMachine:playFreeWanted1Effect( )
    util_spinePlay(self.m_freewanted1_zhu, "buling4", false)
    util_spineEndCallFunc(self.m_freewanted1_zhu,"buling4",function ()
        util_spinePlay(self.m_freewanted1_zhu, "idleframe4", true)
    end) 
end

--[[
    播放Freebox 动画
]]
function CodeGameScreenPiggyLegendPirateMachine:playFreeBoxEffect( )
    util_spinePlay(self.m_freeBoxSpine,"actionframe",false)
    util_spineEndCallFunc(self.m_freeBoxSpine,"actionframe",function ()
        util_spinePlay(self.m_freeBoxSpine,"idleframe",true)
    end)
end
-- free收集 刷新进度
function CodeGameScreenPiggyLegendPirateMachine:freeCollectUpdata(isPlay, func)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local lineBet = self.m_runSpinResultData.p_bet * self.m_runSpinResultData.p_payLineCount

    if fsExtraData.collectNum then
        if fsExtraData.collectNum < selfMakeData.selectNumResult then
            self.m_freewanted:setVisible(true)
            self.m_freewanted1:setVisible(false)
            self.m_freewanted2:setVisible(false)
            self.m_freewanted:findChild("m_lb_num"):setString(fsExtraData.collectNum)
            self.m_freewanted_num:runCsbAction("actionframe",false)
            self.m_freewanted_num:findChild("m_lb_num_0"):setString(selfMakeData.selectNumResult - fsExtraData.collectNum)
            if isPlay then
                self.m_freewanted:runCsbAction("shouji",false,function()
                    self.m_freewanted:runCsbAction("idleframe",true)
                    if func then
                        func()
                    end
                end)
                self:playFreeWantedEffect()
            end
        else
            if self.m_isFreeFlyCoin1 then
                self.m_isFreeFlyCoin1 = false
                self:playFreeWantedEffect()
                
                local chaNum = selfMakeData.selectNumResult - fsExtraData.collectNum
                self.m_freewanted:findChild("m_lb_num"):setString(fsExtraData.collectNum)
                self.m_freewanted_num:findChild("m_lb_num_0"):setString(chaNum <= 0 and 0 or chaNum)
                self.m_freewanted:runCsbAction("shouji",false,function()
                    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_free_collect_faguang.mp3")
                    self.m_freewanted:runCsbAction("actionframe",false,function()
                        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_free_collect_coin_faguang.mp3")
                        self.m_freewanted:runCsbAction("zhanshi",false,function()
                            self:freeFlyCopins(self.m_freewanted,selfMakeData.selectStoreResult*lineBet,function()
                                -- 检查是否有大赢 没有的话 判断添加
                                if not self:checkBigWin() then
                                    self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin,self.EFFECT_TYPE_COLLECT_FREE)
                                end
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, false, true})
                                
                                self.m_freeBox:runCsbAction("actionframe",false,function()
                                    self.m_freeBox:runCsbAction("idleframe",false)

                                    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_free_shouji_qiehuan.mp3")
                                    self.m_freewanted:runCsbAction("qiehuan",false,function()
                                        self.m_freewanted:setVisible(false)
                                    end)
                                    self.m_freewanted1:findChild("m_lb_num"):setString(fsExtraData.collectNum)
                                    self.m_freewanted1_num:findChild("m_lb_num_0"):setString(selfMakeData.selectMaxNum - fsExtraData.collectNum)
                                    
                                    self.m_freewanted1:findChild("m_lb_coins"):setString(util_formatCoins(selfMakeData.selectMaxStore*lineBet, 3))
                                    self.m_freewanted1:runCsbAction("idleframe",true)

                                    self.m_freewanted1:setVisible(true)
                                    self.m_freewanted2:setVisible(false)

                                    if func then
                                        func()
                                    end
                                end)

                                self:playFreeBoxEffect()
                            end)
                        end)
                    end)
                end)
            else
                if fsExtraData.collectNum < selfMakeData.selectMaxNum then
                    self.m_freewanted:setVisible(false)
                    self.m_freewanted1:setVisible(true)
                    self.m_freewanted2:setVisible(false)
                    self.m_freewanted1:findChild("m_lb_num"):setString(fsExtraData.collectNum)

                    self.m_freewanted1_num:runCsbAction("actionframe",false)
                    self.m_freewanted1_num:findChild("m_lb_num_0"):setString(selfMakeData.selectMaxNum - fsExtraData.collectNum)
                    self.m_freewanted1:findChild("m_lb_coins"):setString(util_formatCoins(selfMakeData.selectMaxStore*lineBet, 3))
                    if isPlay then
                        self.m_freewanted1:runCsbAction("shouji",false,function()
                            self.m_freewanted1:runCsbAction("idleframe",true)
                            if func then
                                func()
                            end
                        end)
                        self:playFreeWanted1Effect()
                    end
                else
                    if self.m_isFreeFlyCoin2 then
                        self.m_isFreeFlyCoin2 = false
                        self:playFreeWanted1Effect()

                        local chaNum = selfMakeData.selectMaxNum - fsExtraData.collectNum
                        self.m_freewanted1:findChild("m_lb_num"):setString(fsExtraData.collectNum)

                        self.m_freewanted1_num:runCsbAction("actionframe",false)
                        self.m_freewanted1_num:findChild("m_lb_num_0"):setString(chaNum <= 0 and 0 or chaNum)

                        self.m_freewanted1:findChild("m_lb_coins"):setString(util_formatCoins(selfMakeData.selectMaxStore*lineBet, 3))
                        self.m_freewanted1:runCsbAction("shouji",false,function()
                            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_free_collect_faguang.mp3")
                            self.m_freewanted1:runCsbAction("actionframe",false,function()
                                gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_free_collect_coin_faguang.mp3")
                                self.m_freewanted1:runCsbAction("zhanshi",false,function()
                                    self:freeFlyCopins(self.m_freewanted1,selfMakeData.selectMaxStore*lineBet,function()
                                        -- 检查是否有大赢 没有的话 判断添加
                                        if not self:checkBigWin() then
                                            self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin,self.EFFECT_TYPE_COLLECT_FREE)
                                        end
                                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, false, true})
                                        
                                        self.m_freeBox:runCsbAction("actionframe",false,function()
                                            self.m_freeBox:runCsbAction("idleframe",false)

                                            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_free_shouji_qiehuan.mp3")
                                            self.m_freewanted1:runCsbAction("qiehuan",false,function()
                                                self.m_freewanted1:setVisible(false)
                                            end)
                                            self.m_freewanted:setVisible(false)
                                            self.m_freewanted2:setVisible(true)

                                            if func then
                                                func()
                                            end
                                        end)

                                        self:playFreeBoxEffect()
                                    end)
                                end)
                            end)
                        end)                      
                    else
                        self.m_freewanted:setVisible(false)
                        self.m_freewanted1:setVisible(false)
                        self.m_freewanted2:setVisible(true)

                        if func then
                            func()
                        end
                    end
                end
            end
        end
    end
end

-- 检查大赢
function CodeGameScreenPiggyLegendPirateMachine:checkBigWin( )
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        
        return true
    end
    return false
end

function CodeGameScreenPiggyLegendPirateMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPiggyLegendPirateMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenPiggyLegendPirateMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenPiggyLegendPirateMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenPiggyLegendPirateMachine:slotReelDown( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName == "idle2" then
                local ccbNode = symbolNode:getCCBNode()
                if ccbNode then
                    util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idle", 0.5)
                end
                symbolNode:runAnim("idle", true)
            end
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_bCanClickMap = true
    
    CodeGameScreenPiggyLegendPirateMachine.super.slotReelDown(self)

end

function CodeGameScreenPiggyLegendPirateMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

-- 延时函数
function CodeGameScreenPiggyLegendPirateMachine:waitWithDelay(time, func)
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

----------------
-- 地图玩法相关
----------------

function CodeGameScreenPiggyLegendPirateMachine:showSuperFreeStart(index,num,func)
    --
    self.m_fsReelDataIndex = self:getcollectFsStates(self.m_mapNodePos)
    local data = {
        index = index,
        num = num,
        func = func
    }
    local view = util_createView("CodePiggyLegendPirateSrc.PiggyLegendPirateSuperFreeStartView",data)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(view)

end

function CodeGameScreenPiggyLegendPirateMachine:createMapScroll(mapNodePos)

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = 0
    -- local currentPos = self.m_bonusData.collectProcess.pos or 0
    if mapNodePos then
        currentPos = mapNodePos-1
    else
        if selfData and selfData.collectPos then
            currentPos = selfData.collectPos
            self.m_mapNodePos = currentPos
        else
            self.m_mapNodePos = currentPos
        end
    end
    self.m_map = util_createView("CodePiggyLegendPirateSrc.map.PiggyLegendPirateMapView", self.m_bonusData.map, currentPos,self)
    -- self:addChild(self.m_map,GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 5 )
    gLobalViewManager:showUI(self.m_map)
    self.m_map:findChild("root"):setScale(self.m_machineRootScale)
    self.m_map:setVisible(false)
end

function CodeGameScreenPiggyLegendPirateMachine:hideMapScroll(fun)

    -- self:findChild("Node_reel"):setVisible(true)
    if self.m_map and self.m_map:getMapIsShow() == true then

        self.m_bCanClickMap = false
        
        self.m_map:mapDisappear(function()
            if fun then
                fun()
            end
            self.m_map:setVisible(false)
            self:waitWithDelay(0.0,function()      -- 下一帧 remove spine 不然会崩溃
                self.m_map:removeFromParent()
                self.m_map = nil
            end)
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local freeType = selfData.freeType
            if freeType and freeType == "COLLECT" then
                self:clearCurMusicBg()
            else
                self:resetMusicBg(true)
                self:checkTriggerOrInSpecialGame(function(  )
                    self:reelsDownDelaySetMusicBGVolume( ) 
                end)
            end
            
            self.m_bCanClickMap = true
        end)
    end

end

function CodeGameScreenPiggyLegendPirateMachine:showMapScroll(callback,mapNodePos,isNoClick)
    if (self.m_bCanClickMap == false or self:getCurrSpinMode() == AUTO_SPIN_MODE) and callback == nil then
        return
    end
    self:createMapScroll(mapNodePos)

    self.m_bCanClickMap = false
    self:clearWinLineEffect()
    if self.m_map:getMapIsShow() == true then
        self.m_map:mapDisappear(function()
            self.m_map:setVisible(false)
            self:resetMusicBg(true)
            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)
            self.m_bCanClickMap = true
        end)
    else
        self:clearCurMusicBg()
        self:removeSoundHandler( )
        self.m_map:setVisible(true)
        -- 地图上的按钮 不可点击
        if isNoClick then
            self.m_map:findChild("Button_1"):setBright(false)
            self.m_map:findChild("Button_1"):setTouchEnabled(false)
        end
        
        self.m_map:mapAppear(function()
            self:resetMusicBg(nil,"PiggyLegendPirateSounds/music_PiggyLegendPirate_mapBg.mp3")
            
            self.m_bCanClickMap = true

            if callback then
                callback()
            end
        end,isNoClick)
    end
end

-- 预告相关
--播放中奖预告
function CodeGameScreenPiggyLegendPirateMachine:playYuGaoAct(func)
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_yugao.mp3")

    util_spinePlay(self.m_baseBgSpine, "yugao", false)
    util_spineEndCallFunc(self.m_baseBgSpine,"yugao",function ()
        util_spinePlay(self.m_baseBgSpine, "idleframe", true)
    end)

    self:runCsbAction("yugao",false,function (  )
        self:runCsbAction("idleframe",false)
        if func then
            func()
        end
    end)
end

function CodeGameScreenPiggyLegendPirateMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    local features = self.m_runSpinResultData.p_features or {}
    if self.m_bProduceSlots_InFreeSpin then
        self:produceSlots()

        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end

        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    else
        if (#features >= 2 and features[2] == 3) or (#features >= 2 and features[2] == 5) then
            -- c出现预告动画概率30%
            local yuGaoId = math.random(1, 100)
            if yuGaoId <= 30  then
                self:playYuGaoAct(function()
                    self:produceSlots()
        
                    local isWaitOpera = self:checkWaitOperaNetWorkData()
                    if isWaitOpera == true then
                        return
                    end
                    self.m_isWaitingNetworkData = false
                    self:operaNetWorkData() -- end
                end)
            else
                self:produceSlots()

                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end
            
        else
            self:produceSlots()

            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end
    end
end

-- 点击函数
function CodeGameScreenPiggyLegendPirateMachine:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            return
        end

        if self.m_progress.m_progressTips:isVisible() then
            self:showTipsOverView()
        else
            if self.getGameSpinStage() == IDLE then
                self:showTipsOpenView()
            end
        end
    end
end

--打开tips
function CodeGameScreenPiggyLegendPirateMachine:showTipsOpenView( )
    self.m_progress.m_progressTips:setVisible(true)
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_tips_open.mp3")
    self.m_progress.m_progressTips:runCsbAction("start",false,function()
        self.m_progress.m_progressTips:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self:showTipsOverView()
        end, 4)
    end)
end

--关闭tips
function CodeGameScreenPiggyLegendPirateMachine:showTipsOverView( )
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_tips_close.mp3")
    self.m_progress.m_progressTips:runCsbAction("over",false,function()
        self.m_progress.m_progressTips:setVisible(false)
    end)
end

--触发respin
function CodeGameScreenPiggyLegendPirateMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol, runNodeNum)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol, runNodeNum)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenPiggyLegendPirateMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol, runNodeNum)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol

    self:updateReelGridNode(symblNode,runNodeNum)
    return symblNode
end

function CodeGameScreenPiggyLegendPirateMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local winCoin = self.m_iOnceSpinLastWin
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.collectWinCoins then
        globalData.slotRunData.lastWinCoin = 0
        winCoin = self.m_iOnceSpinLastWin - self.m_runSpinResultData.p_selfMakeData.collectWinCoins
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winCoin, isNotifyUpdateTop})
end

-- 适配
function CodeGameScreenPiggyLegendPirateMachine:scaleMainLayer()
    CodeGameScreenPiggyLegendPirateMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.8
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        -- 
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.86 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.93 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.98 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

--震动
function CodeGameScreenPiggyLegendPirateMachine:shakeNode()
    local changePosY = 15
    local changePosX = 7.5
    local actionList2 = {}
    local oldPos = cc.p(self:findChild("root"):getPosition())

    for i=1,2 do
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

function CodeGameScreenPiggyLegendPirateMachine:initSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local startIndex = 1
        --大信号数量
        local bigSymbolCount = 0
        for rowIndex = 1, rowCount do
            local symbolType = initDatas[startIndex]
            startIndex = startIndex + 1
            if startIndex > #initDatas then
                startIndex = 1
            end

            --判断是否是否属于需要隐藏
            local isNeedHide = false
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                bigSymbolCount = bigSymbolCount + 1
                if bigSymbolCount > 1 then
                    isNeedHide = true
                    symbolType = 0
                end

                if bigSymbolCount == self.m_bigSymbolInfos[symbolType] then
                    bigSymbolCount = 0
                end
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if isNeedHide then
                node:setVisible(false)
            end

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
            if node.p_symbolType == self.SYMBOL_BONUS1 then
                node:runAnim("idle",true)
            end
        end
    end
    self:initGridList()
end

return CodeGameScreenPiggyLegendPirateMachine
