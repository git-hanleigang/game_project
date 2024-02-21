---
-- island li
-- 2019年1月26日
-- CodeGameScreenMagicianMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local CodeGameScreenMagicianMachine = class("CodeGameScreenMagicianMachine", BaseNewReelMachine)

local BaseDialog = require "Levels.BaseDialog"

CodeGameScreenMagicianMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


CodeGameScreenMagicianMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenMagicianMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenMagicianMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenMagicianMachine.SYMBOL_MYSTERY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenMagicianMachine.SYMBOL_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7
CodeGameScreenMagicianMachine.SYMBOL_TREASURE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenMagicianMachine.SYMBOL_MULTIPLE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenMagicianMachine.SYMBOL_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenMagicianMachine.SYMBOL_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenMagicianMachine.SYMBOL_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenMagicianMachine.SYMBOL_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
-- CodeGameScreenMagicianMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenMagicianMachine.RESPIN_MULTIPLE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- respin乘倍特效

local JACKPOT_SYMBOL = {
    Mini = CodeGameScreenMagicianMachine.SYMBOL_MINI,
    Minor = CodeGameScreenMagicianMachine.SYMBOL_MINOR,
    Major = CodeGameScreenMagicianMachine.SYMBOL_MAJOR,
    Grand = CodeGameScreenMagicianMachine.SYMBOL_GRAND,
}

local JACKPOT_COUNT = {
    [CodeGameScreenMagicianMachine.SYMBOL_MINI] = 1,
    [CodeGameScreenMagicianMachine.SYMBOL_MINOR] = 2,
    [CodeGameScreenMagicianMachine.SYMBOL_MAJOR] = 3,
    [CodeGameScreenMagicianMachine.SYMBOL_GRAND] = 5,
}

-- 构造函数
function CodeGameScreenMagicianMachine:ctor()
    CodeGameScreenMagicianMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    self.m_nodes_scatter = {}

    self.m_isNotice = false
 
    self.m_respinWin = 0
    --init
    self:initGame()
end

function CodeGameScreenMagicianMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("MagicianConfig.csv", "LevelMagicianConfig.lua")
    self.m_configData.m_machine = self

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMagicianMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Magician"  
end

--[[
    获取respin界面
]]
function CodeGameScreenMagicianMachine:getRespinView()
    return "CodeMagicianSrc.MagicianRespinView"
end

function CodeGameScreenMagicianMachine:getRespinNode()
    return "CodeMagicianSrc.MagicianRespinNode"
end

function CodeGameScreenMagicianMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

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
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    if ratio <= 1024 / 768 then
        mainScale = 0.73
        mainPosY = mainPosY + 38
    elseif ratio > 1024 / 768 and ratio <= 960 / 640 then
        mainScale = 0.84
        mainPosY = mainPosY + 30
    elseif ratio > 960 / 640 and ratio <= 1228 / 768 then
        mainScale = 0.90
        mainPosY = mainPosY + 20
    elseif ratio > 1228 / 768 and ratio < 1368 / 768 then
        mainScale = 0.90
        mainPosY = mainPosY + 20
    else
        mainScale = 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

function CodeGameScreenMagicianMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_SpinNum")
    self.m_baseFreeSpinBar = util_createView("CodeMagicianSrc.MagicianFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenMagicianMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, true)
    self.m_baseFreeSpinBar:setViewType("free")
end

function CodeGameScreenMagicianMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenMagicianMachine:showRespinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, true)
    self.m_baseFreeSpinBar:setViewType("respin")
    local leftCount = self.m_runSpinResultData.p_reSpinCurCount
    self.m_baseFreeSpinBar:refreshRespinCount(leftCount,true)
end

function CodeGameScreenMagicianMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self:findChild("Panel_1"):setTouchEnabled(false)

    local rootNode = self:findChild("root")

    self.m_jackpot = util_createView("CodeMagicianSrc.MagicianJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackpot)
    self.m_jackpot:initMachine(self)
    

    --特效层
    self.m_effectNode = cc.Node:create()
    rootNode:addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode2:setScale(self.m_machineRootScale)

    --spine人物 用于执行idle动画
    self.m_spine_magician_idle = util_spineCreate("Magician_Juese",true,true)
    self:findChild("node_spine"):addChild(self.m_spine_magician_idle)
    self:magicianIdleAni()

    --用于执行特殊动作
    self.m_spine_magician = util_spineCreate("Magician_Juese",true,true)
    self:findChild("node_spine"):addChild(self.m_spine_magician)
    self.m_spine_magician:setVisible(false)

    --spine人物 上
    self.m_spine_magician_shang = util_spineCreate("Magician_Juese_shang",true,true)
    self:findChild("node_spine_shang"):addChild(self.m_spine_magician_shang)
    self.m_spine_magician_shang:setVisible(false)
    
    --free过场动画
    self.m_changeSceneAni_free = util_spineCreate("Magician_free_guochang",true,true)
    rootNode:addChild(self.m_changeSceneAni_free,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)
    self.m_changeSceneAni_free:setVisible(false)
    self.m_particle_free = util_createAnimation("Magician_free_guochang.csb")
    rootNode:addChild(self.m_particle_free,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1001)
    self.m_particle_free:setVisible(false)

    --link过场动画
    self.m_changeSceneAni_Link = util_spineCreate("Magician_respin_guochang",true,true)
    self:findChild("node_spine"):addChild(self.m_changeSceneAni_Link)
    self.m_changeSceneAni_Link:setVisible(false)
    self.m_changeSceneAni_Link2 = util_spineCreate("Magician_respin_guochang2",true,true)
    rootNode:addChild(self.m_changeSceneAni_Link2,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 2000)
    self.m_changeSceneAni_Link2:setVisible(false)
end

--[[
    初始化jackpot收集数量
]]
function CodeGameScreenMagicianMachine:initJackpotLeftCount()
    for symbolType,totalCount in pairs(JACKPOT_COUNT) do
        local count = self:getLeftJackpotCount(symbolType)
        self.m_jackpot:refreshLeftCount(symbolType,count)
    end
end


function CodeGameScreenMagicianMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound( "MagicianSounds/sound_Magician_enter.mp3" )
        -- self:delayCallBack(5,function()
        --     if self:getCurrSpinMode() <= AUTO_SPIN_MODE then
        --         self:resetMusicBg()
        --         self:reelsDownDelaySetMusicBGVolume( ) 
        --     end
            
        -- end)
    end)
end

function CodeGameScreenMagicianMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagicianMachine.super.onEnter(self)     -- 必须调用不予许删除
    
    self:changeSpecicalSymbolParent()
    self:addObservers()

    self:initJackpotLeftCount()
end

function CodeGameScreenMagicianMachine:getFixSymbol(iCol, iRow, iTag)
    local posIndex = self:getPosReelIdx(iRow, iCol)
    if not tolua.isnull(self.m_nodes_scatter[tostring(posIndex)]) then
        return self.m_nodes_scatter[tostring(posIndex)]
    end

    return CodeGameScreenMagicianMachine.super.getFixSymbol(self,iCol, iRow, iTag)
end

--[[
    修改bonus和scatter父节点
]]
function CodeGameScreenMagicianMachine:changeSpecicalSymbolParent()
    --初始棋盘时把bonus和scatter提出裁切层
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and (symbolNode.p_symbolType == self.SYMBOL_BONUS or symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                --提升层级
                local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
                local pos = util_getOneGameReelsTarSpPos(self,index) 
                local worldPos = self.m_clipParent:convertToWorldSpace(pos)
                local nodePos = self.m_effectNode:convertToNodeSpace(worldPos)
                util_changeNodeParent(self.m_effectNode,symbolNode,self:getBounsScatterDataZorder(symbolNode.p_symbolType) - symbolNode.p_rowIndex)
                symbolNode:setPosition(nodePos)
        
                self.m_nodes_scatter[tostring(index)] = symbolNode
            end
        end
    end
end

function CodeGameScreenMagicianMachine:addObservers()
    CodeGameScreenMagicianMachine.super.addObservers(self)

    -- 监听按钮的状态变化
    gLobalNoticManager:addObserver(self,function(self,params)
        local isTouchEnable = params[2]
        
        if self.m_touchSpinLayer then
            self.m_touchSpinLayer:setTouchEnabled(isTouchEnable)
            self.m_touchSpinLayer:setVisible(isTouchEnable)
        end
    end,ViewEventType.NOTIFY_SPIN_BTN_STATUS)

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

        local soundName = ""
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "MagicianSounds/sound_Magician_free_win_sound_".. soundIndex .. ".mp3"
        else
            soundName = "MagicianSounds/sound_Magician_win_sound_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

--[[
    spine角色idle动画
]]
function CodeGameScreenMagicianMachine:magicianIdleAni()
    local func = function()
        self:magicianIdleAni()
    end
    local params = {}
    params[1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_spine_magician_idle,   --执行动画节点  必传参数
        actionName = "idleframe1", --动作名称  动画必传参数,单延时动作可不传
    }
    local probability = math.random(1,100)
    --10%概率播放actionframe2,25%概率播放actionframe1
    if probability <= 10 then
        params[2] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_magician_idle,   --执行动画节点  必传参数
            actionName = "actionframe2", --动作名称  动画必传参数,单延时动作可不传
            callBack = func,   --回调函数 可选参数
        }
    elseif probability > 10 and probability <= 35 then
        local isPlayRoundSound = false
        if self.m_spine_magician_idle:isVisible() and self:getCurrSpinMode() >= FREE_SPIN_MODE then
            isPlayRoundSound = true
        end
        params[2] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_magician_idle,   --执行动画节点  必传参数
            soundFile = isPlayRoundSound and "MagicianSounds/sound_Magician_round_the_magic_wand.mp3" or nil,
            actionName = "actionframe1", --动作名称  动画必传参数,单延时动作可不传
            callBack = func,   --回调函数 可选参数
        }
    else
        params[1].callBack = func
    end
    
    util_runAnimations(params)
end

function CodeGameScreenMagicianMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagicianMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function CodeGameScreenMagicianMachine:initMachineBg()
    local gameBg = util_spineCreate("Magician_bg",true,true)
    util_spinePlay(gameBg,"idle",true)
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end

    self.m_gameBg = gameBg

    self:changeGameBg("base")
end

--[[
    变更背景
]]
function CodeGameScreenMagicianMachine:changeGameBg(bgType)
    if bgType == "base" then
        self.m_gameBg:setSkin("skin1")
    elseif bgType == "freegame" then
        self.m_gameBg:setSkin("skin2")
    else
        self.m_gameBg:setSkin("skin3")
    end
    
end

function CodeGameScreenMagicianMachine:getMysteryType(symbolType)
    if symbolType == self.SYMBOL_MYSTERY then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.mysterySignal then
            symbolType = selfData.mysterySignal
        else
            symbolType = 0
        end
    end
    return symbolType
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMagicianMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_MYSTERY then
        symbolType = self:getMysteryType(symbolType)
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Magician_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_Magician_11"
    end

    if symbolType == self.SYMBOL_BONUS then
        return "Socre_Magician_Bonus"
    end
    
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_Magician_wild"
    end

    if symbolType == self.SYMBOL_EMPTY then --空信号
        return "Socre_Magician_Empty"
    end

    if symbolType == self.SYMBOL_TREASURE then --宝箱
        return "Socre_Magician_Bonus2"
    end

    if symbolType == self.SYMBOL_MULTIPLE then --乘倍
        return "Socre_Magician_Bonus3"
    end

    if symbolType == self.SYMBOL_GRAND then
        return "Socre_Magician_Grand"
    end

    if symbolType == self.SYMBOL_MAJOR then
        return "Socre_Magician_Major"
    end

    if symbolType == self.SYMBOL_MINOR then
        return "Socre_Magician_Minor"
    end

    if symbolType == self.SYMBOL_MINI then
        return "Socre_Magician_Mini"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMagicianMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMagicianMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMagicianMachine:MachineRule_initGame(  )

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:changeGameBg("freegame")
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenMagicianMachine:slotOneReelDown(reelCol)    
    CodeGameScreenMagicianMachine.super.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMagicianMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMagicianMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMagicianMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:setCurrSpinMode(FREE_SPIN_MODE)
            self:delayCallBack(0.5,function()
                
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_freespin_start.mp3")
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
                self:delayCallBack(25 / 60,function()
                    self:showFreeSpinBar()
                    self:changeGameBg("freegame")
                end)
            end)
        end
    end

    self.m_baseFreeSpinBar:changeFreeSpinByCount()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        self:showScatterTriggerAni(function()
            showFSView()   
        end)
    end,0.5)
end

function CodeGameScreenMagicianMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local view
    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL,nil,true)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func,nil,nil,true)
    end

    local lianzi = util_spineCreate("Magician_tanban",true,true)
    view:findChild("spine_lian"):addChild(lianzi)
    util_spinePlay(lianzi, "over")

    view:setBtnClickFunc(function()
        util_spinePlay(lianzi, "start")
    end)

    return view
end

--[[
    scatter触发动画
]]
function CodeGameScreenMagicianMachine:showScatterTriggerAni(func)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_scatter_trigger.mp3")
    local nodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local pos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
                util_changeNodeParent(self.m_effectNode,symbolNode)
                symbolNode:setPosition(pos)

                local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
                self.m_nodes_scatter[tostring(index)] = symbolNode
            end
        end
    end

    for k,symbolNode in pairs(self.m_nodes_scatter) do
        if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            symbolNode:runAnim("actionframe")
        end
    end
    
    self:delayCallBack(60 / 30,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    free过场动画
]]
function CodeGameScreenMagicianMachine:changeSceneAni_Free(func)
    self.m_changeSceneAni_free:setVisible(true)
    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_change_scene_free.mp3")
    util_spinePlay(self.m_changeSceneAni_free,"actionframe",false)
    util_spineEndCallFunc(self.m_changeSceneAni_free,"actionframe",function(  )
        self.m_changeSceneAni_free:setVisible(false)
        self.m_particle_free:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
    
    self:delayCallBack(15 / 30,function()
        self:changeGameBg("freegame")
        self.m_particle_free:setVisible(true)
        self.m_particle_free:findChild("Particle_1"):resetSystem()
        self.m_particle_free:findChild("Particle_2"):resetSystem()
    end)
end

--[[
    link过场动画
]]
function CodeGameScreenMagicianMachine:changeSceneAni_Link(func,keyFunc)
    self.m_changeSceneAni_Link:setVisible(true)
    self.m_changeSceneAni_Link2:setVisible(true)
    self.m_spine_magician_idle:setVisible(false)

    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_change_scene_respin.mp3")
    util_spinePlay(self.m_changeSceneAni_Link,"actionframe",false)

    util_spinePlay(self.m_changeSceneAni_Link2,"actionframe",false)
    util_spineFrameCallFunc(self.m_changeSceneAni_Link2,"actionframe","Show",keyFunc,function(  )
        self.m_changeSceneAni_Link:setVisible(false)
        self.m_changeSceneAni_Link2:setVisible(false)
        self.m_spine_magician_idle:setVisible(true)
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenMagicianMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("MagicianSounds/sound_Magician_freespin_over.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
        --修改背景
        self:changeGameBg("base")
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},665)

    local lianzi = util_spineCreate("Magician_tanban",true,true)
    view:findChild("spine_lian"):addChild(lianzi)
    util_spinePlay(lianzi, "over")

    view:setBtnClickFunc(function()
        util_spinePlay(lianzi, "start")
    end)
    
end

function CodeGameScreenMagicianMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func,nil,nil,true)
    return view
end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMagicianMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )

    self.m_isNotice = false
   
    self.m_respinWin = 0

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenMagicianMachine:spinBtnEnProc()

    --scatter和bonus图标放回原层级
    local slotsParents = self.m_slotParents
    for key,symbol in pairs(self.m_nodes_scatter) do
        if symbol then
            local parentData = slotsParents[symbol.p_cloumnIndex]
            local parentNode = parentData.slotParentBig
            if not parentNode then
                parentNode = parentData.slotParent
            end
            local pos = util_getOneGameReelsTarSpPos(self,tonumber(key))
            util_changeNodeParent(parentNode,symbol,self:getBounsScatterDataZorder(symbol.p_symbolType) - symbol.p_rowIndex)
            symbol:setPosition(pos)
            self.m_nodes_scatter[key] = nil
        end
    end
    CodeGameScreenMagicianMachine.super.spinBtnEnProc(self)
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMagicianMachine:addSelfEffect()

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMagicianMachine:MachineRule_playSelfEffect(effectData)

    -- if effectData.p_selfEffectType == self.RESPIN_MULTIPLE_EFFECT then

        effectData.p_isPlay = true
        self:playGameEffect()

    -- end

    
    return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMagicianMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenMagicianMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMagicianMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenMagicianMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenMagicianMachine.super.slotReelDown(self)
end

--[[
    延迟回调
]]
function CodeGameScreenMagicianMachine:delayCallBack(time, func)
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
    刷新小块
]]
function CodeGameScreenMagicianMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType    --信号类型
    local reelNode = node
    node.m_score = 0
    if symbolType and symbolType == self.SYMBOL_BONUS or symbolType == self.SYMBOL_MULTIPLE then    --Bouns信号
        self:setSpecialNodeScore(node)
    end

    if symbolType and symbolType == self.SYMBOL_TREASURE then
        local lbl_score = node:getCcbProperty("m_lb_coins")
        if lbl_score then
            lbl_score:setString(0)
            lbl_score:setVisible(false)
        end
    end
end

--[[
    设置特殊小块分数
]]
function CodeGameScreenMagicianMachine:setSpecialNodeScore(node)
    local symbolNode = node
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 1
    --判断是否为真实数据
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        if node.p_symbolType == self.SYMBOL_BONUS then
            --获取真实分数
            score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) or 1
        elseif node.p_symbolType == self.SYMBOL_MULTIPLE then
            score = self:getSpinSymbolMultiple(self:getPosReelIdx(iRow, iCol)) or 2
        end
        
        
    else
        if node.p_symbolType == self.SYMBOL_BONUS then
            --设置假滚Bonus,随机分数
            score = self:randomDownSymbolScore(symbolNode.p_symbolType) or 1
        elseif node.p_symbolType == self.SYMBOL_MULTIPLE then
            score = self:randomDownSymbolScore(symbolNode.p_symbolType) or 2
        end
    end

    if score then
        if node.p_symbolType == self.SYMBOL_BONUS then
            --获取当前下注
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
        end
        
        
        if symbolNode then
            local lbl_score = symbolNode:getCcbProperty("m_lb_coins")
            symbolNode.m_score = score
            if lbl_score then
                
                if node.p_symbolType == self.SYMBOL_BONUS then
                    -- --格式化字符串
                    score = util_formatCoins(score, 3)
                    lbl_score:setString(score)
                    self:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
                elseif node.p_symbolType == self.SYMBOL_MULTIPLE then
                    lbl_score:setString("X"..score)
                    self:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},330)
                end
                
            end
        end
    end
end

--[[
    获取小块真实分数
]]
function CodeGameScreenMagicianMachine:getSpinSymbolScore(id)
    local bonusStoreData = self.m_runSpinResultData.p_selfMakeData.bonusStoreData
    local score = bonusStoreData[tostring(id)]

    return score
end

--[[
    获取小块倍数
]]
function CodeGameScreenMagicianMachine:getSpinSymbolMultiple(id)
    local positionMultiple = self.m_runSpinResultData.p_selfMakeData.positionMultiple
    local score = positionMultiple[tostring(id)]

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenMagicianMachine:randomDownSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS or symbolType == self.SYMBOL_MULTIPLE then
        score = self.m_configData:getBnBasePro(1)
    end

    return score
end

--播放提示动画
function CodeGameScreenMagicianMachine:playReelDownTipNode(slotNode)

    
    if slotNode.p_symbolType == self.SYMBOL_BONUS or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --提升层级
        local index = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
        local pos = util_getOneGameReelsTarSpPos(self,index) 
        local worldPos = self.m_clipParent:convertToWorldSpace(pos)
        local nodePos = self.m_effectNode:convertToNodeSpace(worldPos)
        util_changeNodeParent(self.m_effectNode,slotNode,self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex)
        slotNode:setPosition(nodePos)

        self.m_nodes_scatter[tostring(index)] = slotNode
    end

    self:playScatterBonusSound(slotNode)
    slotNode:runAnim("buling")
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenMagicianMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "MagicianSounds/sound_Magician_scatter_down_tip.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath

        self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = "MagicianSounds/sound_Magician_bonus_down_tip.mp3"
    end
end

-- 特殊信号下落时播放的音效
function CodeGameScreenMagicianMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        local soundType = slotNode.p_symbolType
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end

            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        elseif slotNode.p_symbolType == self.SYMBOL_BONUS then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        end

        if soundPath then
            self:playBulingSymbolSounds(iCol, soundPath, soundType)
        end
    end
end

--增加提示节点
function CodeGameScreenMagicianMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]
        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then

            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex,slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            elseif self:checkSymbolTypePlayTipAnima( slotNode.p_symbolType )then
                
                tipSlotNoes[#tipSlotNoes + 1] = slotNode

            end
        end

        
    end
    return tipSlotNoes
end

function CodeGameScreenMagicianMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return true
    elseif symbolType == self.SYMBOL_BONUS then
        return true
    end
end

---
--设置bonus scatter 层级
function CodeGameScreenMagicianMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
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


--[[
    显示ReSpinView
]]
function CodeGameScreenMagicianMachine:showRespinView(effectData)
    local temp = {
        [self.SYMBOL_EMPTY] = 280,
        [self.SYMBOL_BONUS] = 32,
        [self.SYMBOL_TREASURE] = 8,
        [self.SYMBOL_MULTIPLE] = 2,
        [self.SYMBOL_GRAND] = 7,
        [self.SYMBOL_MAJOR] = 6,
        [self.SYMBOL_MINOR] = 4,
        [self.SYMBOL_MINI] = 4
    }
    --可随机的普通信息
    local randomTypes = {}
    for symbolType,count in pairs(temp) do
        for index = 1,count do
            randomTypes[#randomTypes + 1] = symbolType
        end
    end

    --可随机的特殊信号
    local endTypes = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_TREASURE, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_MULTIPLE, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_GRAND, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_MAJOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_MINI, runEndAnimaName = "buling2", bRandom = true},
    }

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)


    local function startAction(  )

        --开始触发respin
        self:triggerReSpinCallFun(endTypes, randomTypes)
    end

    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS then
                    curBonusList[#curBonusList + 1] = node
                end
            end
        end
    end
    for key,symbol in pairs(self.m_nodes_scatter) do
        if symbol and symbol.p_symbolType == self.SYMBOL_BONUS then
            curBonusList[#curBonusList + 1] = symbol
        end
    end

    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_turn_round.mp3")
    for i,v in ipairs(curBonusList) do
        v:runAnim("actionframe",false,function (  )
            v:runAnim("idleframe",true)
        end)
    end

    

    self:delayCallBack(1.5,function()
        startAction()
    end)

end


function CodeGameScreenMagicianMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.bonusStoreData
    local storedInfo = {}
    for index,mutilples in pairs(storedIcons) do
        local pos = self:getRowAndColByPos(index)
        local iCol,iRow = pos.iY,pos.iX
        local type = self:getMatrixPosSymbolType(iRow, iCol)

        storedInfo[#storedInfo + 1] = {iX = iRow, iY = iCol, type = type}
    end
    return storedInfo
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenMagicianMachine:showDialog(ccbName,ownerlist,func,isAuto,index,isView)
    local view=util_createView("Levels.BaseDialog")
    
    view:initViewData(self,ccbName,func,isAuto,index,self.m_baseDialogViewFps)
    view:updateOwnerVar(ownerlist)
    view.m_btnTouchSound = 'MagicianSounds/sound_Magician_btn_click.mp3'

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    if isView then
        gLobalViewManager:showUI(view)
    else
        self:findChild("node_respin_start"):addChild(view,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    end
    

    return view
end

function CodeGameScreenMagicianMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    
    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_respin_start.mp3")
    self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_ONLY,nil,false)
end

--[[
    收集bonus分数
]]
function CodeGameScreenMagicianMachine:collectBonusScore(func)
    local respinNodes = self.m_respinView.m_respinNodes

    self:delayCallBack(0.5,function()
        gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_turn_round.mp3")
        for key,node in pairs(respinNodes) do
            if node.m_baseFirstNode.p_symbolType == self.SYMBOL_BONUS then
                node.m_baseFirstNode:runAnim("actionframe")
            end
        end
    end)

    self:delayCallBack(0.5 + 60 / 60,function()
        self:collectNextBonusScore(1,function()
            if type(func) == "function" then
                func()
            end
        end)
    end)
    
end

--[[
    收集下一个bonus分数
]]
function CodeGameScreenMagicianMachine:collectNextBonusScore(index,func)
    local respinNodes = self.m_respinView.m_respinNodes
    if index > #respinNodes then
        self:delayCallBack(0.5,func)
        return
    end

    --不是bonus图标跳过收集下一个
    if respinNodes[index].m_baseFirstNode.p_symbolType ~= self.SYMBOL_BONUS then
        self:collectNextBonusScore(index + 1,func)
        return
    end

    local endPos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,self.m_effectNode2)

    --创建临时图标
    local tempSymbol = util_createAnimation("Socre_Magician_Bonus.csb")
    self.m_effectNode2:addChild(tempSymbol)
    tempSymbol:setPosition(util_convertToNodeSpace(respinNodes[index],self.m_effectNode2))

    local str = respinNodes[index].m_baseFirstNode:getCcbProperty("m_lb_coins"):getString()
    tempSymbol:findChild("m_lb_coins"):setString(str)
    local score = respinNodes[index].m_baseFirstNode.m_score or 0
    

    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_fly_to_totalwin.mp3")
    --收集图标动作
    local seq = cc.Sequence:create({
        cc.DelayTime:create(10 / 60),
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_fly_to_totalwin_feedback.mp3")
            local endNode = self.m_bottomUI.coinWinNode

            --光效
            self:playCoinWinEffectUI()
            -- local light_temp = util_createAnimation("Magician_totalwin.csb")
            -- endNode:addChild(light_temp)
            -- light_temp:runCsbAction("actionframe",false,function()
            --     light_temp:removeFromParent(true)
            -- end)
            -- local Particle_1 = light_temp:findChild("Particle_1")
            -- Particle_1:resetSystem()
            
            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_respinWin))
            

            tempSymbol:findChild("Particle_1"):stopSystem()
            tempSymbol:findChild("Node_1"):setVisible(false)
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    self:delayCallBack(30 / 60,function()
        self.m_respinWin = self.m_respinWin + score
        --收集下一个
        self:collectNextBonusScore(index + 1,func)
    end)

    tempSymbol:runAction(seq)
    tempSymbol:runCsbAction("shouji")
    tempSymbol:findChild("Particle_1"):setPositionType(0)
    tempSymbol:findChild("Particle_1"):setDuration(-1)

end

--[[
    显示jackpot
]]
function CodeGameScreenMagicianMachine:showJackpotWinView(func)
    local jackpots = {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.jackpots.Mini then
        jackpots[#jackpots + 1] = "Mini"
    end
    if selfData.jackpots.Minor then
        jackpots[#jackpots + 1] = "Minor"
    end
    if selfData.jackpots.Major then
        jackpots[#jackpots + 1] = "Major"
    end
    if selfData.jackpots.Grand then
        jackpots[#jackpots + 1] = "Grand"
    end

    self:showNextJackpot(1,jackpots,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示下一个jackpot
]]
function CodeGameScreenMagicianMachine:showNextJackpot(index,jackpots,func)
    if index > #jackpots then
        if type(func) == "function" then
            func()
        end
        return
    end

    

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local viewType = jackpots[index]
    local winCoin = selfData.jackpotCoins[viewType]
    self.m_respinWin = self.m_respinWin + winCoin

    if viewType == "Mini" or viewType == "Minor" then
        gLobalSoundManager:playSound("MagicianSounds/sound_Magician_show_jackpot_magic.mp3")
    else
        gLobalSoundManager:playSound("MagicianSounds/sound_Magician_show_jackpot_magnificent.mp3")
    end

    self.m_respinView:showCurJackpotSymbolAni(JACKPOT_SYMBOL[viewType],function()
        --刷新赢钱
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_respinWin))
        local view = util_createView("CodeMagicianSrc.MagicianJackpotWinView",{
            machine = self,
            viewType = viewType,
            winCoin = selfData.jackpotCoins[viewType],
            func = function()
                self:showNextJackpot(index + 1,jackpots,func)
            end
        })

        gLobalViewManager:showUI(view)
    end)
    

end



--[[
    respin结束
]]
function CodeGameScreenMagicianMachine:respinOver()
    self:clearCurMusicBg()
    --收集bonus分数
    self:collectBonusScore(function()
        if self.m_runSpinResultData.p_selfMakeData.jackpotWin and self.m_runSpinResultData.p_selfMakeData.jackpotWin > 0 then
            self:showJackpotWinView(function()
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_respin_over_short_music.mp3")
                CodeGameScreenMagicianMachine.super.respinOver(self)
                self:changeSpecicalSymbolParent()
                
            end)
        else
            gLobalSoundManager:playSound("MagicianSounds/sound_Magician_respin_over_short_music.mp3")
            CodeGameScreenMagicianMachine.super.respinOver(self)
            self:changeSpecicalSymbolParent()
        end
        
    end)
end

--[[
    respin结束界面
]]
function CodeGameScreenMagicianMachine:showRespinOverView()
    local coins = self.m_runSpinResultData.p_resWinCoins
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, function()
        self:triggerReSpinOverCallFun(ownerlist["m_lb_coins"])
        
        --替换空图标
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if symbol and symbol.p_symbolType == self.SYMBOL_EMPTY then
                    local randSymbolType = math.random(0,10)
                    symbol:changeCCBByName(self:getSymbolCCBNameByType(self,randSymbolType), randSymbolType)
                end
            end
        end
        
    end, nil,nil,true)

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},665)

    local lianzi = util_spineCreate("Magician_tanban",true,true)
    view:findChild("spine_lian"):addChild(lianzi)
    util_spinePlay(lianzi, "over")

    view:setBtnClickFunc(function()
        util_spinePlay(lianzi, "start")
    end)

    self:delayCallBack(30 / 60,function()
        if self.m_bProduceSlots_InFreeSpin == true then
             --修改背景
            self:changeGameBg("freegame")
            self:showFreeSpinBar()
        else
             --修改背景
            self:changeGameBg("base")
            self:hideFreeSpinBar()
        end
    end)
    

    self.m_jackpot:resetJackpotAni()
    self.m_jackpot:showDiamond(false)
end

function CodeGameScreenMagicianMachine:playRespinViewShowSound()
    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_start.mp3")
end

function CodeGameScreenMagicianMachine:initRespinView(endTypes, randomTypes)
    --把图标放回裁切层
    local slotsParents = self.m_slotParents
    for key,symbol in pairs(self.m_nodes_scatter) do
        if symbol then
            local parentData = slotsParents[symbol.p_cloumnIndex]
            local slotParentBig = parentData.slotParentBig
            local pos = util_getOneGameReelsTarSpPos(self,tonumber(key))
            util_changeNodeParent(slotParentBig,symbol,self:getBounsScatterDataZorder(symbol.p_symbolType))
            symbol:setPosition(pos)
            self.m_nodes_scatter[key] = nil
        end
    end
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self:initJackpotLeftCount()

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:showReSpinStart(function()
                self:delayCallBack(0.5,function()
                    self:changeSceneAni_Link(function()
                        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                        

                        self.m_respinView:initJackpotInReels()
                        --触发后还没spin
                        local isTrigger = self.m_runSpinResultData.p_selfMakeData.triggerBonus
                        if isTrigger then
                            self.m_respinView:startCollectBonusOnTrigger(function()
                                -- 更改respin 状态下的背景音乐
                                self:changeReSpinBgMusic()
                                self:showAddCoinsAni(function()
                                    self:runNextReSpinReel()
                                end)
                            end)
                        else
                            -- 更改respin 状态下的背景音乐
                            self:changeReSpinBgMusic()
                            self.m_respinView:checkJackpotInReels()
                            self:showAddCoinsAni(function()
                                self:runNextReSpinReel()
                            end)
                        end  
                    end,function()
                        self:changeGameBg("respin")
                        self.m_jackpot:showDiamond(true)
                        local respinNodes = self.m_respinView.m_respinNodes
                        for k,node in pairs(respinNodes) do
                            if node.m_baseFirstNode and not self.m_respinView:getTypeIsEndType(node.m_baseFirstNode.p_symbolType) then
                                local symbolNode = node.m_baseFirstNode
                                --替换原图标为空图标
                                symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_EMPTY), self.SYMBOL_EMPTY)
                            end
                            
                        end
                
                        self:showRespinBar()
                    end)
                end)
                
            end)
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--[[
    检查轮盘中是否出现箱子
]]
function CodeGameScreenMagicianMachine:checkHasBox()
    local reels = self.m_runSpinResultData.p_reels

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == self.SYMBOL_TREASURE then
                return true
            end
        end

    end

    return false
end

--[[
    增加金币动画
]]
function CodeGameScreenMagicianMachine:showAddCoinsAni(func)
    local isHasBox = self:checkHasBox()

    local isMultipleAni = false
    local positionMultiple = self.m_runSpinResultData.p_selfMakeData.positionMultiple
    --轮盘是否集满
    local forceTreasure = self.m_runSpinResultData.p_selfMakeData.forceTreasure
    
    if positionMultiple and next(positionMultiple) then
        isMultipleAni = true
    end

    --乘倍动画
    if isMultipleAni then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:runBonusMultipleAni(function()
            if isHasBox then
                self.m_respinView:collectBonusWithBox(function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                    if type(func) == "function" then
                        func()
                    end
                end)
            elseif forceTreasure then --轮盘集满时根据服务器提供的位置编一个宝箱出来
                self.m_respinView:collectBonusOnFull(self.m_runSpinResultData.p_selfMakeData.treasurePosition,function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
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
    else
        if isHasBox then--宝箱收集
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:collectBonusWithBox(function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                if type(func) == "function" then
                    func()
                end
            end)
        elseif forceTreasure then --轮盘集满时根据服务器提供的位置编一个宝箱出来
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:collectBonusOnFull(self.m_runSpinResultData.p_selfMakeData.treasurePosition,function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
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
end

--开始下次ReSpin
function CodeGameScreenMagicianMachine:runNextReSpinReel()

    CodeGameScreenMagicianMachine.super.runNextReSpinReel(self)

end

function CodeGameScreenMagicianMachine:reSpinEndAction()
    local isMultipleAni = false
    local positionMultiple = self.m_runSpinResultData.p_selfMakeData.positionMultiple
    
    if positionMultiple and next(positionMultiple) then
        isMultipleAni = true
    end

    --乘倍动画
    if isMultipleAni then
        self.m_respinView:runBonusMultipleAni(function()
            CodeGameScreenMagicianMachine.super.reSpinEndAction(self)
        end)
    else
        CodeGameScreenMagicianMachine.super.reSpinEndAction(self)
    end
end

---判断结算
function CodeGameScreenMagicianMachine:reSpinReelDown(addNode)

    local func = function()
        self:setGameSpinStage(STOP_RUN)

        local leftCount = self.m_runSpinResultData.p_reSpinCurCount
        self.m_baseFreeSpinBar:refreshRespinCount(leftCount)

        -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        self:updateQuestUI()
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            --quest
            self:updateQuestBonusRespinEffectData()

            --结束
            self:reSpinEndAction()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false

            return
        end

        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        --    dump(self.m_runSpinResultData,"m_runSpinResultData")
        if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        end
        --    --下轮数据
        --    self:operaSpinResult()
        --    self:getRandomList()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        
        --继续
        self:showAddCoinsAni(function()
            self:runNextReSpinReel()
        end)
        
    end

    local jackpotNodes = self.m_respinView.m_jackpot_nodes
    if #jackpotNodes == 0 then
        func()
    else
        self:delayCallBack(0.5,function()
            for k,symbolNode in pairs(jackpotNodes) do
                self:flyJackpotAni(symbolNode)    
            end
            self:delayCallBack(15 / 60,function()
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_collect_diamond.mp3")
            end)
            self:delayCallBack(35 / 60,function()
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_collect_diamond_feed_back.mp3")
                func()
            end)
        end)
        
    end
end

--[[
    收集jackpot动效
]]
function CodeGameScreenMagicianMachine:flyJackpotAni(symbolNode)
    local symbolType = symbolNode.p_symbolType
    local ani = util_createAnimation("Socre_Magician_Grand_shouji.csb")
    self.m_effectNode:addChild(ani)

    ani:findChild("mini"):setVisible(symbolType == self.SYMBOL_MINI)
    ani:findChild("minor"):setVisible(symbolType == self.SYMBOL_MINOR)
    ani:findChild("major"):setVisible(symbolType == self.SYMBOL_MAJOR)
    ani:findChild("grand"):setVisible(symbolType == self.SYMBOL_GRAND)

    ani:findChild("Particle_1"):setPositionType(0)
    ani:findChild("Particle_1"):setDuration(-1)
    ani:findChild("Particle_1_0"):setPositionType(0)
    ani:findChild("Particle_1_0"):setDuration(-1)
    ani:findChild("Particle_3"):setPositionType(0)
    ani:findChild("Particle_3"):setDuration(-1)
    ani:findChild("Particle_4"):setPositionType(0)
    ani:findChild("Particle_4"):setDuration(-1)

    local targetNode = self.m_jackpot:getTargetNode(symbolType)

    local startPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(targetNode,self.m_effectNode)

    ani:setPosition(startPos)

    local leftCount = self:getLeftJackpotCount(symbolType)

    local seq = cc.Sequence:create({
        cc.DelayTime:create(15 / 60),
        cc.MoveTo:create(20 / 60,endPos),
        cc.CallFunc:create(function()
            ani:findChild("Socre_Magician_mini_3"):setVisible(false)
            ani:findChild("Socre_Magician_minor_4"):setVisible(false)
            ani:findChild("Socre_Magician_major_2"):setVisible(false)
            ani:findChild("Socre_Magician_grand_1"):setVisible(false)

            ani:findChild("Particle_1"):stopSystem()
            ani:findChild("Particle_1_0"):stopSystem()
            ani:findChild("Particle_3"):stopSystem()
            ani:findChild("Particle_4"):stopSystem()

            self.m_jackpot:collectAni(symbolType,leftCount)
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()
    })

    ani:runAction(seq)
    ani:runCsbAction("actionframe")

    --飞宝石的过程中需要把文字提上来
    local sp = symbolNode:getCcbProperty("Score_img_0")
    if sp and sp:isVisible() then
        local frame = sp:getSpriteFrame()
        local temp = cc.Sprite:createWithSpriteFrame(frame)
        local pos = util_convertToNodeSpace(sp,self.m_effectNode)
        self.m_effectNode:addChild(temp,100)
        temp:setPosition(pos)
        temp:setScale(0.5)
        sp:setVisible(false)
        --把文字再放回去
        self:delayCallBack(25 / 60,function()
            temp:removeFromParent()
            sp:setVisible(true)
        end)
    end
end

--[[
    获取剩余jackpot数量
]]
function CodeGameScreenMagicianMachine:getLeftJackpotCount(symbolType)
    --获取轮盘上的数量
    local count = 0
    local totalCount = JACKPOT_COUNT[symbolType] or 0
    local reels = self.m_runSpinResultData.p_reels
    if not next(reels) or self:getCurrSpinMode() ~= RESPIN_MODE then
        return totalCount
    end
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == symbolType then
                count = count + 1
            end
        end
    end

    

    return totalCount - count
end
    
function CodeGameScreenMagicianMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()
    
    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    self.m_isWaitingNetworkData = false

    -- 出现预告动画概率30%
    self.m_isNotice = (math.random(1, 100) <= 30) 

    self:produceSlots()
    
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then
       
        if self.m_isNotice then
            self:playYuGaoAct()
            self:delayCallBack(2.5,function()
                self:operaNetWorkData() -- end
            end)
        else
            self:operaNetWorkData() -- end
        end
        
    else
        self:operaNetWorkData() -- end
    end
    
end

--播放中奖预告
function CodeGameScreenMagicianMachine:playYuGaoAct(func)
    local lizi1 =  self:findChild("Particle_1")
    local lizi2 =  self:findChild("Particle_1_0")
    local lizi3 =  self:findChild("Particle_3")
    local lizi4 =  self:findChild("Particle_3_0")

    local randIndex = math.random(1,2)
    local soundFile = ""
    if self:getCurrSpinMode() == RESPIN_MODE then
        soundFile = "MagicianSounds/sound_Magician_notice_winning_respin_"..randIndex..".mp3"
    else
        soundFile = "MagicianSounds/sound_Magician_notice_winning_"..randIndex..".mp3"
    end
    gLobalSoundManager:playSound(soundFile)
    self:runCsbAction("actionframe_yugao",false,function(  )
        if func then
            func()
        end

        self.m_spine_magician_shang:setVisible(false)

        lizi1:stopSystem()
        lizi2:stopSystem()
        lizi3:stopSystem()
        lizi4:stopSystem()
    end)
    lizi1:resetSystem()
    lizi2:resetSystem()
    lizi3:resetSystem()
    lizi4:resetSystem()

    self.m_spine_magician:setVisible(true)
    self.m_spine_magician_idle:setVisible(false)

    util_spinePlay(self.m_spine_magician,"actionframe2")
    util_spineEndCallFunc(self.m_spine_magician,"actionframe2",function(  )
        self.m_spine_magician_shang:setVisible(true)
        util_spinePlay(self.m_spine_magician_shang,"actionframe_yugao")
        util_spinePlay(self.m_spine_magician,"actionframe_yugao")
        util_spineEndCallFunc(self.m_spine_magician,"actionframe_yugao",function(  )
            self.m_spine_magician:setVisible(false)
            self.m_spine_magician_idle:setVisible(true)
            self.m_spine_magician_shang:setVisible(false)
        end)
    end)
end

--播放中奖预告
function CodeGameScreenMagicianMachine:playYuGaoActForBox(func)
    local lizi1 =  self:findChild("Particle_1")
    local lizi2 =  self:findChild("Particle_1_0")
    local lizi3 =  self:findChild("Particle_3")
    local lizi4 =  self:findChild("Particle_3_0")

    local randIndex = math.random(1,2)
    local soundFile = ""
    if self:getCurrSpinMode() == RESPIN_MODE then
        soundFile = "MagicianSounds/sound_Magician_notice_winning_respin_"..randIndex..".mp3"
    else
        soundFile = "MagicianSounds/sound_Magician_notice_winning_"..randIndex..".mp3"
    end
    gLobalSoundManager:playSound(soundFile)
    self:runCsbAction("actionframe_yugao",false,function(  )
        if func then
            func()
        end

        

        lizi1:stopSystem()
        lizi2:stopSystem()
        lizi3:stopSystem()
        lizi4:stopSystem()
    end)
    lizi1:resetSystem()
    lizi2:resetSystem()
    lizi3:resetSystem()
    lizi4:resetSystem()

   

    self.m_spine_magician:setVisible(true)
    self.m_spine_magician_idle:setVisible(false)
    util_spinePlay(self.m_spine_magician,"actionframe2")
    util_spineEndCallFunc(self.m_spine_magician,"actionframe2",function(  )
        self.m_spine_magician_shang:setVisible(true)
        util_spinePlay(self.m_spine_magician_shang,"actionframe_yugao")
        util_spinePlay(self.m_spine_magician,"actionframe_yugao")
        util_spineEndCallFunc(self.m_spine_magician,"actionframe_yugao",function(  )
            self.m_spine_magician:setVisible(false)
            self.m_spine_magician_idle:setVisible(true)
            self.m_spine_magician_shang:setVisible(false)
        end)
    end)
    
    
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenMagicianMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                self.m_runSpinResultData.p_selfMakeData.jackpotCoins = spinData.result.jackpotCoins
                self.m_runSpinResultData.p_selfMakeData.jackpotMultiple = spinData.result.jackpotMultiple
                self.m_runSpinResultData.p_selfMakeData.jackpots = spinData.result.jackpots
                self:getRandomList()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                
                
                local isHaveBox = self:checkHasBox()
                self.m_isNotice = (isHaveBox and math.random(1, 100) <= 60)
                if self.m_isNotice then
                    self:playYuGaoAct(function()
                        
                    end)
                    self:delayCallBack(1.5,function()
                        self:stopRespinRun()
                    end)
                    
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
                    self:stopRespinRun()
                end
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
        return true
    end
    return false
end

--开始滚动
function CodeGameScreenMagicianMachine:startReSpinRun()
    self.m_isNotice = false
    CodeGameScreenMagicianMachine.super.startReSpinRun(self)
    local leftCount = self.m_runSpinResultData.p_reSpinCurCount
    self.m_baseFreeSpinBar:refreshRespinCount(leftCount - 1)
end

--[[
    检测中的jackpot
]]
function CodeGameScreenMagicianMachine:checkJackpot()
    local jackpotTypes = {
        [self.SYMBOL_MINI] = 1,
        [self.SYMBOL_MINOR] = 2,
        [self.SYMBOL_MAJOR] = 3,
        [self.SYMBOL_GRAND] = 5,
    }

    local symbolCounts = {}
    local reels = self.m_runSpinResultData.p_reels
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = reels[iRow][iCol]
            if symbolType >= self.SYMBOL_GRAND and symbolType <= self.SYMBOL_MINI then
                if not symbolCounts[symbolType] then
                    symbolCounts[symbolType] = 0
                end
                symbolCounts[symbolType] = symbolCounts[symbolType] + 1
            end
        end
    end

    local hitJackpot = {}
    for symbolType,count in pairs(symbolCounts) do
        if count >= jackpotTypes[symbolType] then
            hitJackpot[#hitJackpot + 1] = symbolType
        end
    end

    -- if #hitJackpot > 0 then
    --     self.m_jackpot:hitJackpotAni(hitJackpot)
    -- end
end

function CodeGameScreenMagicianMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
end

function CodeGameScreenMagicianMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print(debug.traceback())
        release_print("sever传回的数据：  " .. (globalData.slotRunData.severGameJsonData or "isnil"))
        release_print(
            "error_userInfo_ udid=" ..
                (globalData.userRunData.userUdid or "isnil") .. " machineName=" .. (globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. (globalData.seqId or "")
        )
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:" .. ccbName)
        return nil
    end
    symbolType = self:getMysteryType(symbolType)
    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node:runDefaultAnim()

        -- print("从尺子里面拿 SlotsAnimNode")

        return node
    end
end

---
-- 从参考的假数据中获取数据
--
function CodeGameScreenMagicianMachine:getRandomReelType(colIndex, reelDatas)
    if reelDatas == nil or #reelDatas == 0 then
        return self:getNormalSymbol(colIndex)
    end
    local reelLen = #reelDatas

    if self.m_randomSymbolSwitch then
        -- 根据滚轮真实假滚数据初始化轮子信号小块
        if self.m_randomSymbolIndex == nil then
            self.m_randomSymbolIndex = util_random(1, reelLen)
        end
        self.m_randomSymbolIndex = self.m_randomSymbolIndex + 1
        if self.m_randomSymbolIndex > reelLen then
            self.m_randomSymbolIndex = 1
        end

        local symbolType = reelDatas[self.m_randomSymbolIndex]
        symbolType = self:getMysteryType(symbolType)
        return symbolType
    else
        while true do
            local symbolType = reelDatas[util_random(1, reelLen)]
            symbolType = self:getMysteryType(symbolType)
            return symbolType
        end
    end

    return nil
end

--设置bonus scatter 信息
function CodeGameScreenMagicianMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if not self.m_isNotice and bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end
return CodeGameScreenMagicianMachine






