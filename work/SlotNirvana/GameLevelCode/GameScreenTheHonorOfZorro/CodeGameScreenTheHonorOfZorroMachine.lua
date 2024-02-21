---
-- island li
-- 2019年1月26日
-- CodeGameScreenTheHonorOfZorroMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local CodeGameScreenTheHonorOfZorroMachine = class("CodeGameScreenTheHonorOfZorroMachine", BaseReelMachine)

CodeGameScreenTheHonorOfZorroMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenTheHonorOfZorroMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- bonus
CodeGameScreenTheHonorOfZorroMachine.SYMBOL_SCORE_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3  -- bonus2
CodeGameScreenTheHonorOfZorroMachine.SYMBOL_SCORE_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  -- bonus3
CodeGameScreenTheHonorOfZorroMachine.SYMBOL_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7     --空信号 100
CodeGameScreenTheHonorOfZorroMachine.SYMBOL_SCORE_WILD_2 = 920  -- wild
CodeGameScreenTheHonorOfZorroMachine.SYMBOL_SCORE_WILD_3 = 921  -- wild
CodeGameScreenTheHonorOfZorroMachine.SYMBOL_SCORE_WILD_4 = 922  -- wild
CodeGameScreenTheHonorOfZorroMachine.SYMBOL_SCORE_WILD_5 = 923  -- wild
-- CodeGameScreenTheHonorOfZorroMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

-- CodeGameScreenTheHonorOfZorroMachine.EFFECT_BIG_WIN_LIGHT = GameEffect.EFFECT_SELF_EFFECT - 1 --大赢光效
CodeGameScreenTheHonorOfZorroMachine.EFFECT_COLLECT_BONUS_COINS_IN_FREE = GameEffect.EFFECT_SELF_EFFECT - 2 --free里获得jackpot

local RESPIN_ROW_NUM    =       8
local BASE_ROW_NUM      =       4

local JACKPOT_TYPE = {
    "grand",
    "major",
    "minor",
    "mini",
}

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenTheHonorOfZorroMachine:ctor()
    CodeGameScreenTheHonorOfZorroMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isSuperFree = false

    self.m_respinReelDownSound = {}
    self.m_lockSymbols = {}
    self.m_isLongRun = false        --是否触发快滚
    self.m_isScatterDown = false    --是否播放了scatter落地音效(快停时bonus和scatter同时落地只播scatter音效)
    self.m_isScatterRun = false     --是否为scatter快滚
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
 
    --init
    self:initGame()
end

function CodeGameScreenTheHonorOfZorroMachine:initGameStatusData(gameData)
    CodeGameScreenTheHonorOfZorroMachine.super.initGameStatusData(self, gameData)

    if gameData.gameConfig.extra.collectData then
        local collectData = gameData.gameConfig.extra.collectData
        self.m_collectTotalNum = gameData.gameConfig.extra.collectData.total
        self.m_collectCurNum = gameData.gameConfig.extra.collectData.triggers
    end
    


end

function CodeGameScreenTheHonorOfZorroMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("TheHonorOfZorroConfig.csv", "LevelTheHonorOfZorroConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取最高的那一列
--
function CodeGameScreenTheHonorOfZorroMachine:updateReelInfoWithMaxColumn()
    CodeGameScreenTheHonorOfZorroMachine.super.updateReelInfoWithMaxColumn(self)
    -- self.m_touchSpinLayer
    local pos = util_convertToNodeSpace(self.m_touchSpinLayer,self:findChild("root"))
    util_changeNodeParent(self:findChild("root"),self.m_touchSpinLayer)
    self.m_touchSpinLayer:setPosition(pos)
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenTheHonorOfZorroMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "TheHonorOfZorro"  
end

-- 继承底层respinView
function CodeGameScreenTheHonorOfZorroMachine:getRespinView()
    return "CodeTheHonorOfZorroSrc.TheHonorOfZorroRespinView"
end

-- 继承底层respinNode
function CodeGameScreenTheHonorOfZorroMachine:getRespinNode()
    return "CodeTheHonorOfZorroSrc.TheHonorOfZorroRespinNode"
end

--小块
function CodeGameScreenTheHonorOfZorroMachine:getBaseReelGridNode()
    return "CodeTheHonorOfZorroSrc.TheHonorOfZorroSlotsNode"
end

function CodeGameScreenTheHonorOfZorroMachine:getBottomUINode()
    return "CodeTheHonorOfZorroSrc.TheHonorOfZorroBottomNode"
end

--[[
    初始化背景
]]
function CodeGameScreenTheHonorOfZorroMachine:initMachineBg()
    local gameBg = util_spineCreate("TheHonorOfZorro_bg",true,true)
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end

    local particle = util_createAnimation("Socre_TheHonorOfZorro_bg.csb")
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        bgNode:addChild(particle, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        self:addChild(particle, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    end

    self.m_gameBg = gameBg
    self.m_bgParticle = particle
    
end

-- 重置当前背景音乐名称
function CodeGameScreenTheHonorOfZorroMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_isSuperFree then
            self.m_currentMusicBgName = "TheHonorOfZorroSounds/music_TheHonorOfZorro_super_free.mp3"
        end
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end

--[[
    修改背景动画
]]
function CodeGameScreenTheHonorOfZorroMachine:changeBgAni(aniType)
    if aniType == "base" then
        util_spinePlay(self.m_gameBg,"base_idle",true)
        self.m_bgParticle:findChild("base"):setVisible(true)
        self.m_bgParticle:findChild("s_f"):setVisible(false)
        self.m_bgParticle:findChild("Particle_3"):setVisible(false)
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
    elseif aniType == "free" then
        util_spinePlay(self.m_gameBg,"free_idle",true)
        self.m_bgParticle:findChild("base"):setVisible(false)
        self.m_bgParticle:findChild("s_f"):setVisible(false)
        self.m_bgParticle:findChild("Particle_3"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
    elseif aniType == "super_free" then
        util_spinePlay(self.m_gameBg,"s_free_idle",true)
        self.m_bgParticle:findChild("base"):setVisible(false)
        self.m_bgParticle:findChild("s_f"):setVisible(true)
        self.m_bgParticle:findChild("Particle_3"):setVisible(false)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
    elseif aniType == "respin" then

    end
end

function CodeGameScreenTheHonorOfZorroMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_freebar")
    self.m_baseFreeSpinBar = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    self:hideFreeSpinBar()
end

function CodeGameScreenTheHonorOfZorroMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:show(self.m_isSuperFree)
end

function CodeGameScreenTheHonorOfZorroMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:hide()
end

--[[
    震动root点
]]
function CodeGameScreenTheHonorOfZorroMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(cc.RepeatForever:create(seq2))

end

--[[
    重置root点位置
]]
function CodeGameScreenTheHonorOfZorroMachine:resetRootPos()
    local rootNode = self:findChild("root")
    rootNode:stopAllActions()
    rootNode:setPosition(display.center)
end


function CodeGameScreenTheHonorOfZorroMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar


    self:changeCoinWinEffectUI(self:getModuleName(), "TheHonorOfZorro_Towalwin.csb")
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,1000)

    --特效层
    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode2:setScale(self.m_machineRootScale)

    --图标固定层
    self.m_lockNode = self:findChild("Node_lockNode")

    --收集条
    self.m_collectBar = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroCollectBar",{machine = self})
    self:findChild("Node_basebar"):addChild(self.m_collectBar)

    --jackpotBar
    self.m_jackpotBar = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroJackPotBarView",{machine = self})
    self:findChild("Node_base_jackpot"):addChild(self.m_jackpotBar)

    --respin背景
    self.m_respinReelBg = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroRespinReelView",{machine = self})
    self:findChild("root"):addChild(self.m_respinReelBg)
    self.m_respinReelBg:setVisible(false)

    --角色
    self.m_human_zorro = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroHumanNode",{machine = self})
    self:findChild("Node_juese1"):addChild(self.m_human_zorro)
end

--播放
function CodeGameScreenTheHonorOfZorroMachine:playCoinWinEffectUI(winCoins,callBack)
    if self.m_bottomUI ~= nil then
        self.m_bottomUI:playCoinWinEffectUI(winCoins,callBack)
    end
end


function CodeGameScreenTheHonorOfZorroMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_enter_game)

    end,0.4,self:getModuleName())
end

--[[
    检测respin断线重连重置storedIcons数据
]]
function CodeGameScreenTheHonorOfZorroMachine:resetStoredIconsOnRespin()
    local features = self.m_runSpinResultData.p_features
    if not features then
        return
    end

    local isTriggerRespin = false
    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_RESPIN then
            isTriggerRespin = true
            break
        end
    end
    local freeSpinLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
    if freeSpinLeftCount > 0 or not isTriggerRespin and self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData then
            if selfData.restoreIcons then
                self.m_runSpinResultData.p_storedIcons = selfData.restoreIcons
            end
            if selfData.restoreReels then
                self.m_runSpinResultData.p_reels = selfData.restoreReels
            end
        end
    end
end

--[[
    检测是否触发free
]]
function CodeGameScreenTheHonorOfZorroMachine:checkTriggerFree()
    local features = self.m_runSpinResultData.p_features
    if features then
        for index = 1,#features do
            if features[index] == SLOTO_FEATURE.FEATURE_FREESPIN then
                return true
            end
        end
    end

    return false
end

function CodeGameScreenTheHonorOfZorroMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:checkUpateDefaultBet()
    if self:checkTriggerFree() then
        self.m_collectCurNum = self.m_collectCurNum - 1
    end

    self:updateBetLevel(true)

    self:resetStoredIconsOnRespin()

    CodeGameScreenTheHonorOfZorroMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_jackpotBar:showLockTip()

    --断线重连回来可能玩家在free触发的respin中,所以不做FREE_SPIN_MODE的判断
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and fsExtraData and fsExtraData.kind and fsExtraData.kind == "super" then
        self.m_isSuperFree = true
    else
        self:cleatAvgBet()
    end
    if self.m_isSuperFree then
        self:showFreeSpinUI()
        self:updateLockBonus()
        self:changeBgAni("super_free")

    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeSpinUI()
        self:changeBgAni("free")
    else
        self:changeBgAni("base")
    end
    self:runCsbAction("idleframe",true)

    if self:collectBarClickEnabled() and self.m_iBetLevel == 1 then
        self.m_collectBar:clickHelp()
    end
end

--[[
    高低bet
]]
function CodeGameScreenTheHonorOfZorroMachine:updateBetLevel(isInit)
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 
    if betCoin >= specialBets[1].p_totalBetValue then
        level = 1
    end
    self.m_iBetLevel = level

    if isInit then
        self.m_jackpotBar:initLockStatus(level == 0)
        self.m_respinReelBg.m_jackpotBar:initLockStatus(level == 0)
        self:updateCollectBar(isInit)
    else
        self.m_jackpotBar:setLockStatus(level == 0)
        self.m_respinReelBg.m_jackpotBar:setLockStatus(level == 0)
        self.m_collectBar:updateLockStatus(self.m_iBetLevel)
    end

    
end

function CodeGameScreenTheHonorOfZorroMachine:addObservers()
    CodeGameScreenTheHonorOfZorroMachine.super.addObservers(self)
    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        self:updateBetLevel()
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self)
        local rootNode = self:findChild("root")
        rootNode:setPosition(display.center)
    end,ViewEventType.NOTIFY_RESET_SCREEN)

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
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

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

        local soundName = PublicConfig.SoundConfig["sound_TheHonorOfZorro_winline_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_isSuperFree then
                soundName = PublicConfig.SoundConfig["sound_TheHonorOfZorro_winline_super_free_"..soundIndex] 
            else
                soundName = PublicConfig.SoundConfig["sound_TheHonorOfZorro_winline_free_"..soundIndex] 
            end
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenTheHonorOfZorroMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTheHonorOfZorroMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    刷新收集条
]]
function CodeGameScreenTheHonorOfZorroMachine:updateCollectBar(isInit)
    self.m_collectBar:updateUI(self.m_collectCurNum)
    if isInit then
        self.m_collectBar:initLockStatus(self.m_iBetLevel == 0)
    else
        self.m_collectBar:updateLockStatus(self.m_iBetLevel)
    end
    
end

---
--设置bonus scatter 层级
function CodeGameScreenTheHonorOfZorroMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_WILD then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_WILD - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenTheHonorOfZorroMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_TheHonorOfZorro_Bonus1"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS_2 or symbolType == self.SYMBOL_SCORE_BONUS_3 then
        return "Socre_TheHonorOfZorro_Bonus2"
    end

    if symbolType == self.SYMBOL_SCORE_WILD_2 or symbolType == self.SYMBOL_SCORE_WILD_3 or symbolType == self.SYMBOL_SCORE_WILD_4 or symbolType == self.SYMBOL_SCORE_WILD_5 then
        return "Socre_TheHonorOfZorro_Wild"
    end

    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_TheHonorOfZorro_Empty"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenTheHonorOfZorroMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenTheHonorOfZorroMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_EMPTY, count = 10}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_BONUS, count = 10}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_BONUS_2, count = 10}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_BONUS_3, count = 10}


    return loadNode
end

---
-- 预创建内存池中的节点， 在LaunchLayer 里面，
--
function CodeGameScreenTheHonorOfZorroMachine:preLoadSlotsNodeBySymbolType(symbolType, count)
    --    if (symbolType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 and symbolType <= TAG_SYMBOL_TYPE.SYMBOL_WILD) == false then
    --    	return
    --    end

    for i = 1, count, 1 do
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        if ccbName == nil or ccbName == "" then
            return
        end
        local fullName = cc.FileUtils:getInstance():fullPathForFilename(ccbName .. ".csb")
        local hasSymbolCCB = cc.FileUtils:getInstance():isFileExist(fullName)
        if hasSymbolCCB == true then
            local node = SlotsAnimNode:create()
            node:loadCCBNode(ccbName, symbolType)
            node:retain()

            self:pushAnimNodeToPool(node, symbolType)
        else    --加载spine文件
            local spineName = cc.FileUtils:getInstance():fullPathForFilename(ccbName .. ".skel")
            local hasSpine = cc.FileUtils:getInstance():isFileExist(spineName)
            if hasSpine then
                local node = SlotsSpineAnimNode:create()
                node:loadCCBNode(ccbName, symbolType)
                node:retain()
                self:pushAnimNodeToPool(node, symbolType)
            end
        end
    end
end

function CodeGameScreenTheHonorOfZorroMachine:getAnimNodeFromPool(symbolType, ccbName)
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
    ccbName = self:getSymbolCCBNameByType(self, symbolType)

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
            node:loadCCBNode(ccbName, symbolType, spineSymbolData[3])
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

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenTheHonorOfZorroMachine:MachineRule_initGame(  )

    
end

--
--单列滚动停止回调
--
function CodeGameScreenTheHonorOfZorroMachine:slotOneReelDown(reelCol)    
    local isLongRun = CodeGameScreenTheHonorOfZorroMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isLongRun then
        self.m_isLongRun = isLongRun
    end
    if self.m_isLongRun and self.m_isScatterRun then
        for iCol = 1,reelCol do
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol,iRow)
                if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName ~= "idleframe3" then
                    self:runSymbolIdleLoop(symbolNode,"idleframe3")
                end
            end
        end
    end
    
    return isLongRun
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenTheHonorOfZorroMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenTheHonorOfZorroMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

--[[
    显示free相关UI
]]
function CodeGameScreenTheHonorOfZorroMachine:showFreeSpinUI()
    self.m_collectBar:setVisible(false)
    self:showFreeSpinBar()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    if self.m_isSuperFree then
        self.m_collectBar:initLockStatus(self.m_iBetLevel == 0)
        self.m_bottomUI:showAverageBet()
    end

end

--[[
    显示base相关UI
]]
function CodeGameScreenTheHonorOfZorroMachine:showBaseUI()
    self.m_collectBar:setVisible(true)
    self:hideFreeSpinBar()
    self:changeBgAni("base")
    self.m_bottomUI:hideAverageBet()
end

----------- FreeSpin相关

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenTheHonorOfZorroMachine:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    self.m_human_zorro:runTriggerAni()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_scatter_trigger_free)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_scatter_trigger_base)
    end
    

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow)
            if node and node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                node:changeParentToOtherNode(self.m_clipParent)
                node:runAnim("actionframe",false,function()
                    self:putSymbolBackToPreParent(node)
                    self:runSymbolIdleLoop(node,"idleframe2")
                end)
                animTime = util_max(animTime, node:getAniamDurationByName("actionframe"))
            end
        end
    end

    self:delayCallBack(animTime,function()
        if type(callFun) == "function" then
            callFun()
        end
    end)
end

---
-- 显示free spin
function CodeGameScreenTheHonorOfZorroMachine:showEffect_FreeSpin(effectData)
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

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- 播放震动

        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
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
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end
-- FreeSpinstart
function CodeGameScreenTheHonorOfZorroMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("TheHonorOfZorroSounds/music_TheHonorOfZorro_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            view:findChild("root"):setScale(self.m_machineRootScale)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                if self.m_isSuperFree then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_change_scene_to_super_free)
                else
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_change_scene_to_free)
                end
                --过场动画
                self:changeSceneToFree(function()
                    self:showFreeSpinUI()
                    if self.m_isSuperFree then
                        self:changeBgAni("super_free")
                    else
                        self:changeBgAni("free")
                    end
                end,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()    
                end)
            end) 
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.collectData then
        self.m_collectTotalNum = selfData.collectData.total
        self.m_collectCurNum = selfData.collectData.triggers
    end

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.kind and fsExtraData.kind == "super" then
        self.m_isSuperFree = true
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_iBetLevel == 0 then
        self:delayCallBack(0.5,function()
            showFSView()
        end)
    else
        --刷新收集进度
        self.m_collectBar:showAddProcessAni(self.m_collectCurNum,self.m_isSuperFree,function()
            self.m_collectBar:updateUI(self.m_collectCurNum)
            showFSView()
        end)
    end
    
end

function CodeGameScreenTheHonorOfZorroMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local viewName = BaseDialog.DIALOG_TYPE_FREESPIN_START
    if self.m_isSuperFree then
        viewName = "SuperFreeSpinStart"
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_super_free_start)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_free_start)
    end

    

    local view
    if isAuto then
        view = self:showDialog(viewName, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(viewName, ownerlist, func)
    end

    local light = util_createAnimation("TheHonorOfZorro_tanban_guang.csb")
    view:findChild("guang"):addChild(light)

    util_setCascadeOpacityEnabledRescursion(view:findChild("guang"),true)
    light:runCsbAction("idle1",true)

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_btn_click)
        if self.m_isSuperFree then
            viewName = "SuperFreeSpinStart"
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hide_super_free_start)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hide_free_start)
        end
        
    end)

    view:findChild("root"):setScale(self.m_machineRootScale)

    return view
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenTheHonorOfZorroMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local viewName = BaseDialog.DIALOG_TYPE_FREESPIN_MORE
    if self.m_isSuperFree then
        viewName = "SuperFreeSpinMore"
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_free_more)

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(viewName, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(viewName, ownerlist, newFunc)
    end
end

--[[
    过场动画(free)
]]
function CodeGameScreenTheHonorOfZorroMachine:changeSceneToFree(keyFunc,endFunc)
    
    local aniName = "actionframe_guochang"
    if self.m_isSuperFree then
        aniName = "actionframe_guochang2"
    end
    local spine = util_spineCreate("TheHonorOfZorro_guochang",true,true)
    self.m_effectNode:addChild(spine)
    spine:setScale(self.m_bgScale)
    util_spinePlay(spine,aniName)
    util_spineEndCallFunc(spine,aniName,function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(60 / 30,function()
        spine:runAction(cc.FadeOut:create(10 / 30))
    end)

    self:delayCallBack(40 / 30,keyFunc)
end

--[[
    过场动画(free - base)
]]
function CodeGameScreenTheHonorOfZorroMachine:changeSceneFromFreeToBase(keyFunc,endFunc)
    if self.m_isSuperFree then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_change_scene_from_super_free_to_base)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_change_scene_from_free_to_base)
    end
    
    self:changeSceneToFree(keyFunc,endFunc)
end

--[[
    清理固定的图标
]]
function CodeGameScreenTheHonorOfZorroMachine:clearLockBonus()
    self.m_lockNode:removeAllChildren()
    self.m_lockSymbols = {}
end

--[[
    刷新锁定的bonus图标
]]
function CodeGameScreenTheHonorOfZorroMachine:updateLockBonus()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if not fsExtraData or not fsExtraData.stickIcons or #fsExtraData.stickIcons == 0 then
        return
    end
    self:clearLockBonus()

   
    local stickIcons = fsExtraData.stickIcons

    for index = 1,#stickIcons do
        local iconData = stickIcons[index]
        --固定小块数据信息
        local posIndex = iconData[1]
        local multi = iconData[2]
        local jackpotType
        if iconData[3] and iconData[3] ~= "normal" then
            jackpotType = string.lower(iconData[3]) 
        end
        local symbolType = iconData[4]

        local lineBet = self:getTotalBet()
        local score = multi * lineBet

        local csbName = self:getSymbolCCBNameByType(self,symbolType)
        
        local lockNode = util_spineCreate(csbName,true,true)
        self.m_lockSymbols[#self.m_lockSymbols + 1] = lockNode
        self.m_lockNode:addChild(lockNode)

        if not lockNode.m_lbl_score then

            local lblName = "Socre_TheHonorOfZorro_Bonus_zi.csb"
            local label = util_createAnimation(lblName)
            util_spinePushBindNode(lockNode,"zi",label)
            lockNode.m_lbl_score = label
            if label:findChild("Node_3") then
                label:findChild("Node_3"):setVisible(false)
            end
            
        end

        self:updateLockBonusShow(lockNode.m_lbl_score,symbolType,score,jackpotType,1)

        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX

        --将轮盘上的小块变为对应的bonus
        local symbolNode = self:getFixSymbol(iCol,iRow)
        if symbolNode and symbolNode.p_symbolType ~= symbolType then
            self:changeSymbolType(symbolNode,symbolType)
            local labelCsb = self:getLblOnBonusSymbol(symbolNode)
            if labelCsb then
                self:updateLockBonusShow(labelCsb,symbolNode.p_symbolType,score,jackpotType,1)
            end
        end

        local clipTarPos = util_getOneGameReelsTarSpPos(self, posIndex)
        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
        local nodePos = self.m_lockNode:convertToNodeSpace(worldPos)
        
        lockNode:setVisible(false)
        lockNode:setPosition(nodePos)
        lockNode.m_posIndex = posIndex
        lockNode:setLocalZOrder(posIndex)
        lockNode.isUnlock = posIndex > 14
    end
end

--[[
    移动固定图标
]]
function CodeGameScreenTheHonorOfZorroMachine:moveLockBonus(func)
    local delayTime = 0

    local isMoveLockNode = false
    for index = 1,#self.m_lockSymbols do
        local lockNode = self.m_lockSymbols[index]
        local posIndex = lockNode.m_posIndex
        local posData = self:getRowAndColByPos(posIndex)
        

        local iCol,iRow = posData.iY,posData.iX
        --在最下层的图标不固定
        if not lockNode.isUnlock then
            isMoveLockNode = true
            --固定图标的位置随机一个其他图标
            local symbolNode = self:getSymbolByPosIndex(posIndex)
            if symbolNode then
                local randType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
                self:changeSymbolType(symbolNode,randType)
            end

            delayTime = 60 / 30
            lockNode:setVisible(true)

            local nodePos = cc.p(lockNode:getPosition())
            local isHide = false
            if iRow - 1 > 0 then
                --图标向下移动一格
                local tarIndex = self:getPosReelIdx(iRow - 1,iCol)
                local clipTarPos = util_getOneGameReelsTarSpPos(self, tarIndex)
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                nodePos = self.m_lockNode:convertToNodeSpace(worldPos)
                lockNode.m_posIndex = tarIndex
            else
                isHide = true
                nodePos.y = nodePos.y - self.m_SlotNodeH 
            end
            lockNode:runAction(cc.Sequence:create({
                cc.MoveTo:create(1,nodePos),
                cc.CallFunc:create(function()
                    lockNode:setPosition(nodePos)
                    util_spinePlay(lockNode,"buling")
                    if isHide then
                        lockNode:setVisible(false)
                    end
                end)
            }))
        else
            lockNode:setVisible(false)
            lockNode.m_posIndex = -1
        end
        
    end

    if isMoveLockNode then
        self:delayCallBack(1,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_bonus_down)
        end)
    end
    
    if type(func) == "function" then
        func()
    end
end

function CodeGameScreenTheHonorOfZorroMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("TheHonorOfZorroSounds/music_TheHonorOfZorro_over_fs.mp3")

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.collectData then
        self.m_collectTotalNum = selfData.collectData.total
        self.m_collectCurNum = selfData.collectData.triggers
    end
    if self.m_isSuperFree then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_super_free_over)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_free_over)
    end

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        --过场动画
        self:changeSceneFromFreeToBase(function()
            self:cleatAvgBet()
            self:showBaseUI()
            self:updateCollectBar(true)
            self:clearLockBonus()
        end,function()
            self:triggerFreeSpinOverCallFun()
            self.m_isSuperFree = false   
        end)
    end)
    

    
    if view:findChild("hua") then
        local flower = util_createAnimation("TheHonorOfZorro_tanban_hua.csb")
        flower:runCsbAction("idle",true)
        view:findChild("hua"):addChild(flower)
    end
    

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_btn_click)
        if self.m_isSuperFree then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hide_super_free_over)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hide_free_over)
        end
        
    end)
    local node=view:findChild("m_lb_coins")
    if node then
        view:updateLabelSize({label=node,sx=0.9,sy=0.9},680)
    end

    

end

function CodeGameScreenTheHonorOfZorroMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()

    local viewName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    if self.m_isSuperFree then
        viewName = "SuperFreeSpinOver"
    end
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    if globalData.slotRunData.lastWinCoin == 0 then
        viewName = "NoWins"
        ownerlist = {}
    end

    
    return self:showDialog(viewName, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenTheHonorOfZorroMachine:MachineRule_SpinBtnCall()
    
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
function CodeGameScreenTheHonorOfZorroMachine:addSelfEffect()
        local selfData = self.m_runSpinResultData.p_selfMakeData
        -- 自定义动画创建方式
        if self:getCurrSpinMode() == FREE_SPIN_MODE and selfData and selfData.storedIconsLines then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_COLLECT_BONUS_COINS_IN_FREE
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_COLLECT_BONUS_COINS_IN_FREE -- 动画类型
        end
        

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTheHonorOfZorroMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_COLLECT_BONUS_COINS_IN_FREE then
        self:collectBonusCoinsInFree(function()
            effectData.p_isPlay = true
            self:playGameEffect()  
        end)
         
    end
    return true
end

--[[
    free中收集bonus上的钱
]]
function CodeGameScreenTheHonorOfZorroMachine:collectBonusCoinsInFree(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.storedIconsLines then
        if type(func) == "function" then
            func()
        end
        return 
    end

    --当前赢钱区显示的钱
    self.m_curWinAmount = self.m_runSpinResultData.p_fsWinCoins - self.m_runSpinResultData.p_winAmount

    local storedIconsLines = selfData.storedIconsLines
    util_bubbleSort(storedIconsLines,function(a,b)
        local pos1 = a.icons[1]
        local pos2 = b.icons[1]

        local posData1 = self:getRowAndColByPos(pos1)
        local posData2 = self:getRowAndColByPos(pos2)
        local iCol1,iRow1= posData1.iY,posData1.iX
        local iCol2,iRow2= posData2.iY,posData2.iX
        --升序排序 相同大小按索引排序
        return iCol1 < iCol2 or (iCol1 == iCol2 and iRow1 > iRow2)
    end)

    self:delayCallBack(0.5,function()
        self:collectNextBonusCoinsInFree(storedIconsLines,1,func)
    end)
    
end

--[[
    收集下一个bonus上的钱
]]
function CodeGameScreenTheHonorOfZorroMachine:collectNextBonusCoinsInFree(storedIconsLines,index,func)
    if index > #storedIconsLines then
        if type(func) == "function" then
            func()
        end
        return 
    end

    local iconData = storedIconsLines[index]
    local winCoins = iconData.amount
    local posIndex = iconData.icons[1]

    self.m_curWinAmount = self.m_curWinAmount + winCoins

    --播放连线赢钱时需要从加完jackpot赢钱后的钱数开始
    self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin - winCoins

    local score,jackpotType,addTimes = self:getReSpinSymbolScore(posIndex)
    local symbolNode = self:getSymbolByPosIndex(posIndex)
    if symbolNode then
        if not jackpotType then
            symbolNode:runAnim("shouji")
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_collect_bonus_to_win_coins)
            self:flyParticleAni(0.5,symbolNode,self.m_bottomUI.coinWinNode,function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_collect_bonus_to_win_coins_feed_back)
                self:playCoinWinEffectUI(winCoins)
                --刷新赢钱
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_curWinAmount))
                self:collectNextBonusCoinsInFree(storedIconsLines,index + 1,func)
            end)
        else
            self.m_human_zorro:getJackpotInFree()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hit_jp_bonus)
            symbolNode:runAnim("jackpot_shouji",false,function()
                self:showJackpotView(winCoins,jackpotType,addTimes,function()
                    self.m_human_zorro:humanBackAfterJackpot(function()
                        self:collectNextBonusCoinsInFree(storedIconsLines,index + 1,func)
                    end)
                    self:playCoinWinEffectUI(winCoins)
                    --刷新赢钱
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_curWinAmount))
                end)
            end)
            local lblCsb = self:getLblOnBonusSymbol(symbolNode)
            if lblCsb then
                lblCsb:runCsbAction("jackpot_shouji")
                if lblCsb:findChild("Node_3") then
                    lblCsb:findChild("Node_3"):setVisible(true)
                end
                for index = 1,4 do
                    local particle = lblCsb:findChild("Particle_"..index)
                    if particle then
                        particle:resetSystem()
                    end
                end
            end
        end
    else
        self:collectNextBonusCoinsInFree(storedIconsLines,index + 1,func)
    end
    
end

--[[
    金币跳动
]]
function CodeGameScreenTheHonorOfZorroMachine:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 1   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local lblScale = params.lblScale or 1
    local maxCount = params.maxCount or 50 --保留最大的位数
    local jumpSound --= PublicConfig.SoundConfig.sound_WitchyHallowin_jump_coins
    local jumpSoundEnd --= PublicConfig.SoundConfig.sound_WitchyHallowin_jump_coins_end

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (60  * duration)

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
    label:stopAllActions()
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            label:stopAllActions()
            label:setString("+"..util_formatCoins(endCoins,maxCount))
            local info={label = label,sx = lblScale,sy = lblScale}
            self:updateLabelSize(info,maxWidth)

            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString("+"..util_formatCoins(curCoins,maxCount))

            local info={label = label,sx = lblScale,sy = lblScale}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenTheHonorOfZorroMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenTheHonorOfZorroMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenTheHonorOfZorroMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenTheHonorOfZorroMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_isSuperFree then
        self:moveLockBonus()
    end
    self.m_isNotice = false
    self.m_isLongRun = false
    self.m_isScatterDown = false

    self.m_jackpotBar:hideLockTip()
    self.m_collectBar:hideTip()
    
    CodeGameScreenTheHonorOfZorroMachine.super.beginReel(self)
end

function CodeGameScreenTheHonorOfZorroMachine:slotReelDown( )


    self.m_isScatterDown = false
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    local feature = self.m_runSpinResultData.p_features
    if self.m_isLongRun and feature and #feature == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_quick_run_without_feature)
    end

    CodeGameScreenTheHonorOfZorroMachine.super.slotReelDown(self)

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName == "idleframe3" then
                self:runSymbolIdleLoop(symbolNode,"idleframe2")
            end
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_isSuperFree then
        self:updateLockBonus()
    end
end

function CodeGameScreenTheHonorOfZorroMachine:delaySlotReelDown()
    CodeGameScreenTheHonorOfZorroMachine.super.delaySlotReelDown(self)
    self.m_isScatterRun = false

end

function CodeGameScreenTheHonorOfZorroMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    判断是否为bonus小块
]]
function CodeGameScreenTheHonorOfZorroMachine:isFixSymbol(symbolType)
    local bonusAry = {
        self.SYMBOL_SCORE_BONUS,
        self.SYMBOL_SCORE_BONUS_2,
        self.SYMBOL_SCORE_BONUS_3
    }

    for k,bonusType in pairs(bonusAry) do
        if symbolType == bonusType then
            return true
        end
    end
    
    return false
end

--[[
    刷新小块
]]
function CodeGameScreenTheHonorOfZorroMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end
end

-- 给respin小块进行赋值
function CodeGameScreenTheHonorOfZorroMachine:setSpecialNodeScore(symbolNode)
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

    local score = 0
    local jackpotType = nil
    local addTimes = 1
    if symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score,jackpotType,addTimes = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local labelCsb,aniNode = self:getLblOnBonusSymbol(symbolNode)
        if labelCsb then
            
            self:updateLockBonusShow(labelCsb,symbolNode.p_symbolType,score,jackpotType,addTimes)
        end
        if symbolNode.p_symbolImage then
            self:updateLockBonusShow(symbolNode.p_symbolImage,symbolNode.p_symbolType,score,jackpotType,addTimes)
            symbolNode.p_symbolImage:setVisible(false)
        end
    else
        
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if symbolNode.p_symbolImage then
            self:updateLockBonusShow(symbolNode.p_symbolImage,symbolNode.p_symbolType,score,jackpotType,addTimes)
        end
    end
end

--[[
    检测是否需要再bonus上添加label
]]
function CodeGameScreenTheHonorOfZorroMachine:getLblOnBonusSymbol(symbolNode)
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and not spine.m_lbl_score then

        local lblName = "Socre_TheHonorOfZorro_Bonus_zi.csb"
        local label = util_createAnimation(lblName)
        util_spinePushBindNode(spine,"zi",label)
        spine.m_lbl_score = label
        if label:findChild("Node_3") then
            label:findChild("Node_3"):setVisible(false)
        end
    end

    if symbolType == self.SYMBOL_SCORE_BONUS_3 then
        spine.m_lbl_score:runCsbAction("idleframe2")
    else
        spine.m_lbl_score:runCsbAction("idleframe")
    end

    return spine.m_lbl_score,aniNode
end

--[[
    刷新固定bonus小块显示
]]
function CodeGameScreenTheHonorOfZorroMachine:updateLockBonusShow(lockNode,symbolType,score,jackpotType,addTimes)
    if symbolType == self.SYMBOL_SCORE_BONUS_3 then
        lockNode:runCsbAction("idleframe2")
        lockNode:findChild("Node_blade"):setVisible(true)
        lockNode:findChild("Node_di"):setVisible(false)
        lockNode:findChild("Node_gao"):setVisible(false)
        lockNode:findChild("Node_jackpot"):setVisible(false)
        lockNode:findChild("Node_jackpot_x2"):setVisible(false)
        
    else
        lockNode:runCsbAction("idleframe")
        lockNode.m_score = score
        lockNode.m_jackpotType = jackpotType
        
        --只用白色字体
        lockNode:findChild("Node_di"):setVisible(true and not jackpotType)
        lockNode:findChild("Node_gao"):setVisible(false)
        lockNode:findChild("Node_jackpot"):setVisible(jackpotType ~= nil and addTimes == 1)

        if jackpotType then
            for index = 1,#JACKPOT_TYPE do
                lockNode:findChild(JACKPOT_TYPE[index]):setVisible(jackpotType == JACKPOT_TYPE[index])
            end
        end

        local lbl_coins_1 = lockNode:findChild("m_lb_coins_1")
        local lbl_coins_2 = lockNode:findChild("m_lb_coins_2")
        
        if lbl_coins_1 then
            lbl_coins_1:setString(util_formatCoins(score,3))
            self:updateLabelSize({label=lbl_coins_1,sx=1,sy=1},112)
            
        end
        if lbl_coins_2 then
            lbl_coins_2:setString(util_formatCoins(score,3))
            self:updateLabelSize({label=lbl_coins_2,sx=0.5,sy=0.5},216)
        end

        lockNode:findChild("Node_blade"):setVisible(false)
        lockNode:findChild("Node_jackpot_x2"):setVisible(jackpotType ~= nil and addTimes > 1)
        
        if jackpotType then
            for index = 1,#JACKPOT_TYPE do
                lockNode:findChild(JACKPOT_TYPE[index].."2"):setVisible(jackpotType == JACKPOT_TYPE[index])
            end
        end
    end
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenTheHonorOfZorroMachine:getReSpinSymbolScore(id)
    
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local multi = nil
    local jackpotType = nil
    local addTimes = 1

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            multi = values[2]
            if values[3] ~= "normal" then
                jackpotType = values[3]
                if jackpotType then
                    jackpotType = string.lower(jackpotType)
                end
                
            end
            addTimes = values[4] or 1
            break
        end
    end

    if multi == nil then
       return 0,jackpotType,addTimes
    end

    local lineBet = self:getTotalBet()
    local score = multi * lineBet

    return score,jackpotType,addTimes
end

--[[
    随机bonus分数
]]
function CodeGameScreenTheHonorOfZorroMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    
    local lineBet = self:getTotalBet()
    local multi = self.m_configData:getFixSymbolPro()
    score = multi * lineBet


    return score
end

--[[
    获取平均bet
]]
function CodeGameScreenTheHonorOfZorroMachine:getTotalBet()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.avgBet then
        return fsExtraData.avgBet
    end
    return globalData.slotRunData:getCurTotalBet()
end

--[[
    清理平均bet
]]
function CodeGameScreenTheHonorOfZorroMachine:cleatAvgBet()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.avgBet then
        fsExtraData.avgBet = nil
    end
end

--------------------------------------------Respin----------------------------------------------------------------

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenTheHonorOfZorroMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                local rsExtraData = self.m_runSpinResultData.p_rsExtraData
                if rsExtraData and rsExtraData.newReels then
                    self.m_runSpinResultData.p_reels = rsExtraData.newReels
                end
                self:getRandomList()

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
        return true
    end
    return false
end

--ReSpin开始改变UI状态
function CodeGameScreenTheHonorOfZorroMachine:changeReSpinStartUI(respinCount)
    self.m_respinReelBg:setVisible(true)
    self.m_jackpotBar:setVisible(false)
    self:findChild("Node_main"):setVisible(false)
    self:changeReSpinUpdateUI(respinCount,true)
    self:changeBgAni("free")
    self.m_human_zorro:setVisible(false)

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        self.m_respinReelBg:refreshLockBarInfo(rsExtraData.unlockRequire,rsExtraData.rowState,true)
    end
    
end

--ReSpin结算改变UI状态
function CodeGameScreenTheHonorOfZorroMachine:changeReSpinOverUI()
    self.m_respinReelBg:setVisible(false)
    self.m_jackpotBar:setVisible(true)
    self:findChild("Node_main"):setVisible(true)
    
    self.m_human_zorro:setVisible(true)
    if self.m_isSuperFree then
        self:updateLockBonus()
    end

    if self.m_bProduceSlots_InFreeSpin then
        if self.m_isSuperFree then
            self:changeBgAni("super_free")
        end
        -- 
    else
        self:changeBgAni("base")
    end

    self.m_iReelRowNum = BASE_ROW_NUM
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    

    self:changeTouchSpinLayerSize()
end

--[[
    刷新当前respin剩余次数
]]
function CodeGameScreenTheHonorOfZorroMachine:changeReSpinUpdateUI(curCount,isInit)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinReelBg:updateRespinCount(curCount,isInit)
end
-- 根据本关卡实际小块数量填写
function CodeGameScreenTheHonorOfZorroMachine:getRespinRandomTypes( )
    local symbolList = {}
    for index = 1,20 do
        symbolList[index] = self.SYMBOL_EMPTY
    end
    symbolList[#symbolList + 1] = self.SYMBOL_SCORE_BONUS
    symbolList[#symbolList + 1] = self.SYMBOL_SCORE_BONUS_3

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenTheHonorOfZorroMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_SCORE_BONUS, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_SCORE_BONUS_2, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_SCORE_BONUS_3, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

--[[
    respin触发动画
]]
function CodeGameScreenTheHonorOfZorroMachine:triggerRespinAni()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_bonus_trigger)
    self.m_human_zorro:runTriggerAni()
    --触发动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow)
            if node and node.p_symbolType then
                if self:isFixSymbol(node.p_symbolType) then
                    node:changeParentToOtherNode(self.m_clipParent)
                    node:runAnim("actionframe",false,function()
                        self:runSymbolIdleLoop(node,"idleframe2")
                        self:putSymbolBackToPreParent(node)
                    end)
                end
            end
        end
    end
end

function CodeGameScreenTheHonorOfZorroMachine:showRespinView()
    self.m_triggerRespin = false
    self.m_isScatterDown = false

    --先播放动画 再进入respin
    self:clearCurMusicBg()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin1")
    end

    --触发动画
    self:triggerRespinAni()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.m_lightScore = 0

    self.m_iReelRowNum = RESPIN_ROW_NUM  
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()
    
    --触发动画播完0.5s后弹start弹板
    self:delayCallBack(60 / 30 + 0.5,function()
        self:showReSpinStart(function()

            --刷新base下bonus数据
            local rsExtraData = self.m_runSpinResultData.p_rsExtraData
            local lockStatusData
            --检测轮盘上是否有jackpot
            local hasJackpot = self:checkHasJackpot()
            --替换数据
            if rsExtraData then
                if rsExtraData.initStoredIcons then
                    self.m_runSpinResultData.p_storedIcons = rsExtraData.initStoredIcons
                end

                if rsExtraData.reels then
                    self.m_runSpinResultData.p_reels = rsExtraData.newReels
                end
                lockStatusData = rsExtraData.rowState
            end

            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_change_scene_to_respin)
            self:changeSceneToRespinAni(function()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )
                --可随机的特殊信号 
                local endTypes = self:getRespinLockTypes()
        
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)
                self.m_respinView:setVisible(false)
                self.m_respinReelBg:resetView()
                
            end,function()
                if self.m_respinView then
                    self.m_respinView:setVisible(true)
                    self.m_respinView:runShowLineAni()
                    self.m_respinReelBg:showViewAni(lockStatusData,function()
                        
                        self.m_respinView:runFadeAni()
                        self.m_respinReelBg:runFadeAni()
                        -- util_nodeFadeIn(self.m_respinView,0.5,0,255)
                    end,function()
                        self:showAddBonusScoreAni(true,function()
                            self:runNextReSpinReel()
                        end)
                    end)
                end
                
            end)
            
        end)
    end)
end

--[[
    检测轮盘上是否有jackpot
]]
function CodeGameScreenTheHonorOfZorroMachine:checkHasJackpot()
    --刷新base下bonus数据
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    if rsExtraData then
        local storedIcons = rsExtraData.storedIcons
        local rowState = rsExtraData.rowState
        local unLockRow = 4
        --计算上面4行解锁的行数
        local lockCount = 0
        for iRow = 1,4 do
            if rowState[iRow] == "lock" then
                lockCount = lockCount + 1
            end
        end
        unLockRow  = unLockRow + (4 - lockCount)

        for index = 1,#storedIcons do
            local iconData = storedIcons[index]
            local iconPos = iconData[1]
            local posData = self:getRowAndColByPos(iconPos)
            local iCol,iRow = posData.iY,posData.iX

            if iconData[3] and iconData[3] ~= "normal" and iRow <= unLockRow then
                return true
            end
        end
        
    end
    return false
end

function CodeGameScreenTheHonorOfZorroMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func)
    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_respin_start)
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hide_respin_start)
    end)

    local light = util_createAnimation("TheHonorOfZorro_tanban_guang.csb")
    view:findChild("guang"):addChild(light)
    light:runCsbAction("idle",true)

    local star = util_createAnimation("TheHonorOfZorro_tanban_xing.csb")
    view:findChild("xing"):addChild(star)
    star:runCsbAction("actionframe",true)
    return view
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

--触发respin
function CodeGameScreenTheHonorOfZorroMachine:triggerReSpinCallFun(endTypes, randomTypes)

    
    self.m_specialReels = true

    self:changeTouchSpinLayerSize()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

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
    self.m_respinReelBg:findChild("Node_sp_reel"):addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    

    self:initRespinView(endTypes, randomTypes)

    self:setCurrSpinMode(RESPIN_MODE)

    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    self:resetMusicBg()
end

--[[
    改变点击区域大小
]]
function CodeGameScreenTheHonorOfZorroMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
       
    end
end

function CodeGameScreenTheHonorOfZorroMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_SlotNodeH * 8)

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

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenTheHonorOfZorroMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = self.m_iReelRowNum
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getRespinPosSymbolType(iRow, iCol)
            if not self:isFixSymbol(symbolType) then
                symbolType = self.SYMBOL_EMPTY
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self.m_respinReelBg:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * 0.9 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH * 0.9
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

function CodeGameScreenTheHonorOfZorroMachine:getRespinReelPos(col)
    return self.m_respinReelBg:getRespinReelPos(col)
end

function CodeGameScreenTheHonorOfZorroMachine:getRespinPosSymbolType(iRow, iCol)
    local reels = self.m_runSpinResultData.p_rsExtraData.newReels
    local rowCount = #reels
    for rowIndex = 1, rowCount do
        local rowDatas = reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

--开始下次ReSpin
function CodeGameScreenTheHonorOfZorroMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    self.m_respinReelDownSound = {}
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if globalData.slotRunData.gameSpinStage == IDLE then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end

--开始滚动
function CodeGameScreenTheHonorOfZorroMachine:startReSpinRun()
    self.m_bonus_down = {}
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

    self:requestSpinReusltData()
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinView:startMove()
end


--[[
    respin单列停止
]]
function CodeGameScreenTheHonorOfZorroMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            gLobalSoundManager:playSound("TheHonorOfZorroSounds/sound_TheHonorOfZorro_reel_down.mp3")
        else
            gLobalSoundManager:playSound("TheHonorOfZorroSounds/sound_TheHonorOfZorro_reel_down_quick.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

---判断结算
function CodeGameScreenTheHonorOfZorroMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self:setGameSpinStage(STOP_RUN)

    local isRunUnLockAni = false
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        isRunUnLockAni = self.m_respinReelBg:refreshLockBarInfo(rsExtraData.unlockRequire,rsExtraData.rowState)
    end
    if isRunUnLockAni then
        self:celebrateOnAddScore()
    end

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()

    self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    
    local func = function()
        self:showAddBonusScoreAni(false,function()
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        
                --quest
                self:updateQuestBonusRespinEffectData()
        
                
        
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        
                self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
                self.m_isWaitingNetworkData = false

                self:delayCallBack(0.5,function()
                    --结束
                    self:reSpinEndAction()
                end)
        
                return
            end
        
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        
            self:setGameSpinStage(IDLE)
            --继续
            self:runNextReSpinReel()
        
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end)
    end

    if isRunUnLockAni then
        self:delayCallBack(80 / 60,func)
    else
        func()
    end
end

--[[
    加钱时庆祝动画
]]
function CodeGameScreenTheHonorOfZorroMachine:celebrateOnAddScore(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_sword_light)
    local spine = util_spineCreate("Socre_TheHonorOfZorro_guochang2",true,true)
    self.m_effectNode:addChild(spine)
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function()
        if type(func) == "function" then
            func()
        end
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
    end)
end

--[[
    bonus图标加钱动画
]]
function CodeGameScreenTheHonorOfZorroMachine:showAddBonusScoreAni(isInit,func)
    local rsExtraData = clone(self.m_runSpinResultData.p_rsExtraData)
    if not rsExtraData or not rsExtraData.spBonus then
        if type(func) == "function" then
            func()
        end
        return
    end

    local addBonusData = rsExtraData.spBonus
    
    -- if isInit then
    --     self:addNextBonusScore(addBonusData,1,function()
    --         if type(func) == "function" then
    --             func()
    --         end
    --     end)
    -- else
    --     self:celebrateOnAddScore(function()
    --         self:addNextBonusScore(addBonusData,1,function()
    --             if type(func) == "function" then
    --                 func()
    --             end
    --         end)
    --     end)
    -- end

    self:delayCallBack(0.5,function()
        self:addNextBonusScore(addBonusData,1,function()
            if type(func) == "function" then
                func()
            end
        end)
    end)
end

--[[
    加下一组bonus的钱数
]]
function CodeGameScreenTheHonorOfZorroMachine:addNextBonusScore(addBonusData,index,func)
    if index > #addBonusData then
        if type(func) == "function" then
            func()
        end
        return
    end

    local data = addBonusData[index]
    local storedIcons = data.storedIcons
    local iconPos = data.icon
    local addResult = data.addResult

    self:addNextResultAni(iconPos,addResult,storedIcons,1,function()
        --等待1s后收集下一个
        self:delayCallBack(1,function()
            self:addNextBonusScore(addBonusData,index + 1,func)
        end)
    end)
end

--[[
    加下一个bonus的钱数
]]
function CodeGameScreenTheHonorOfZorroMachine:addNextResultAni(iconPos,addResult,storedIcons,index,func)
    if index > #addResult then
        if type(func) == "function" then
            func()
        end
        return
    end

    --前一个小块的位置
    local prePos = iconPos
    if index > 1 then
        prePos = addResult[index - 1][1]
    end
    local prePosData = self:getRowAndColByPos(prePos)
    local preSymbol = self.m_respinView:getSymbolByRowAndCol(prePosData.iY,prePosData.iX)

    --当前小块位置
    local data = addResult[index]
    local iconPos = data[1]
    local posData = self:getRowAndColByPos(iconPos)
    local iCol,iRow = posData.iY,posData.iX
    local symbolNode = self.m_respinView:getSymbolByRowAndCol(iCol,iRow)
    if preSymbol and symbolNode and self:isFixSymbol(symbolNode.p_symbolType) then
        local score,jackpotType,addTimes = self:getScoreByPos(iconPos,storedIcons)
        if preSymbol.p_symbolType == self.SYMBOL_SCORE_BONUS_3 then
            preSymbol:runAnim("actionframe3")
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_collect_bonus_to_other_bonus)
        --飞粒子动画
        self:flyParticleAni(0.5,preSymbol,symbolNode,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_collect_bonus_to_other_bonus_feed_back)
            --反馈动效
            local feedBackAni = util_createAnimation("Socre_TheHonorOfZorro_Bonus_bao.csb")
            local endPos = util_convertToNodeSpace(symbolNode,self.m_effectNode2)
            self.m_effectNode2:addChild(feedBackAni)
            feedBackAni:setPosition(endPos)
            feedBackAni:runCsbAction("actionframe",false,function()
                feedBackAni:removeFromParent()
            end)

            local labelCsb = self:getLblOnBonusSymbol(symbolNode)
            --变化小块类型的不需要显示数字变化
            local isNeedRunChange = false

            local symbolType = symbolNode.p_symbolType
            if symbolNode.p_symbolType ~= self.SYMBOL_SCORE_BONUS_2 then
                self:changeSymbolType(symbolNode,self.SYMBOL_SCORE_BONUS_2,true)
                labelCsb = self:getLblOnBonusSymbol(symbolNode)
                
            end
            isNeedRunChange = true

            if isNeedRunChange then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_turn_around_bonus)
                symbolNode:runAnim("switchtoBonus2",false,function()
                    self:runSymbolIdleLoop(symbolNode,"idleframe2")
                end)
            end
            --刷新bonus显示
            if labelCsb then
                self:updateLockBonusShow(labelCsb,symbolNode.p_symbolType,score,jackpotType,addTimes)
                if symbolType == self.SYMBOL_SCORE_BONUS_3 then
                    labelCsb:runCsbAction("switch")
                elseif not jackpotType then
                    labelCsb:runCsbAction("actionframe")
                end
            end

            self:addNextResultAni(iconPos,addResult,storedIcons,index + 1,func)
        end)
    else
        self:addNextResultAni(iconPos,addResult,storedIcons,index + 1,func)
    end
end

--[[
    加钱飞粒子动画
]]
function CodeGameScreenTheHonorOfZorroMachine:flyParticleAni(time,startNode,endNode,func)
    local flyNode = util_createAnimation("Socre_TheHonorOfZorro_Bonus_lizi.csb")
    self.m_effectNode2:addChild(flyNode)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode2)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode2)

    flyNode:setPosition(startPos)
    for index = 1,2 do
        local particle = flyNode:findChild("Particle_"..index)
        if particle then
            particle:setPositionType(0)
        end
    end

    local seq = cc.Sequence:create({
        cc.BezierTo:create(time,{startPos, cc.p(startPos.x, endPos.y), endPos}),
        cc.CallFunc:create(function(  )
            for index = 1,2 do
                local particle = flyNode:findChild("Particle_"..index)
                if particle then
                    particle:stopSystem()
                end
            end

            self:delayCallBack(1,function()
                flyNode:removeFromParent()
            end)
            

            if type(func) == "function" then
                func()
            end
        end)
    })

    flyNode:runAction(seq)
end

--[[
    跳动金币
]]
function CodeGameScreenTheHonorOfZorroMachine:jumpCoinsOnBonus(labelCsb,startCoins,coins,func)
    local lbl_coins_1 = labelCsb:findChild("m_lb_coins_1")
    local lbl_coins_2 = labelCsb:findChild("m_lb_coins_2")
        
    self:jumpCoins({
        label = lbl_coins_1,
        startCoins = 0,
        duration = 0.5,
        maxCount = 3,
        endCoins = coins,
        maxWidth = 112,
        lblScale = 1
    })

    self:jumpCoins({
        label = lbl_coins_2,
        startCoins = 0,
        duration = 0.5,
        maxCount = 3,
        endCoins = coins,
        maxWidth = 216,
        lblScale = 0.5
    })
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenTheHonorOfZorroMachine:getScoreByPos(posIndex,storedIcons)
    local multi = nil
    local jackpotType = nil
    local addTimes = 1

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == posIndex then
            multi = values[2]
            if values[3] ~= "normal" then
                jackpotType = values[3]
                jackpotType = string.lower(jackpotType)
                addTimes = values[4] or 1
            end
            
        end
    end

    if multi == nil then
       return 0,jackpotType,addTimes
    end

    local lineBet = self:getTotalBet()
    local score = multi * lineBet

    return score,jackpotType,addTimes
end

--[[
    获取新respin小块的信号值
]]
function CodeGameScreenTheHonorOfZorroMachine:getRespinSymbolTypeByPos(posIndex)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if not rsExtraData then
        return
    end

    local posData = self:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX
    local reels = rsExtraData.reels
    return reels[self.m_iReelRowNum - iRow + 1][iCol]
end

function CodeGameScreenTheHonorOfZorroMachine:reSpinEndAction()
    self.m_lightScore = 0
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    --已解锁的行数
    local unLockRow = 4
    if rsExtraData then
        local rowState = rsExtraData.rowState
        --计算上面4行解锁的行数
        local lockCount = 0
        for iRow = 1,4 do
            if rowState[iRow] == "lock" then
                lockCount = lockCount + 1
            end
        end
        unLockRow  = unLockRow + (4 - lockCount)
    end

    local allNodes = self.m_respinView:getAllCleaningNode(unLockRow)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_respin_over_trigger)
    --播中奖动效
    for index = 1,#allNodes do
        local symbolNode = allNodes[index]
        symbolNode:runAnim("actionframe2",false,function()
            self:runSymbolIdleLoop(symbolNode,"idleframe2")
        end)
    end

    self:delayCallBack(30 / 30,function()
        self:collectNextBonusScore(allNodes,1,function()
            self:respinOver()
        end)
        
    end)
end

--[[
    收集下个bonus到赢钱区
]]
function CodeGameScreenTheHonorOfZorroMachine:collectNextBonusScore(allNodes,index,func)
    if index > #allNodes then
        if type(func) == "function" then
            func()
        end
        return
    end

    local symbolNode = allNodes[index]
    local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local score,jackpotType,addTimes = self:getReSpinSymbolScore(posIndex)
    local winScore = self:getWinCoinsByPosIndex(posIndex)

    --粒子飞行时间
    local flyTime = 0.5

    self.m_lightScore = self.m_lightScore + winScore
    if not jackpotType then
        symbolNode:runAnim("shouji")
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_collect_bonus_to_win_coins)
        self:flyParticleAni(flyTime,symbolNode,self.m_bottomUI.coinWinNode,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_collect_bonus_to_win_coins_feed_back)
            self:playCoinWinEffectUI(winScore)
            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
            self:collectNextBonusScore(allNodes,index + 1,func)
        end)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hit_jp_bonus)
        symbolNode:runAnim("jackpot_shouji",false,function()
            self:showJackpotView(winScore,jackpotType,addTimes,function()
                self:playCoinWinEffectUI(winScore)
                --刷新赢钱
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
                self:collectNextBonusScore(allNodes,index + 1,func)
            end)
        end)
        local lblCsb = self:getLblOnBonusSymbol(symbolNode)
        if lblCsb then
            lblCsb:runCsbAction("jackpot_shouji")
            if lblCsb:findChild("Node_3") then
                lblCsb:findChild("Node_3"):setVisible(true)
            end
            for index = 1,4 do
                local particle = lblCsb:findChild("Particle_"..index)
                if particle then
                    particle:resetSystem()
                end
            end
        end
        
    end
    
end

--[[
    显示jackpot弹板
]]
function CodeGameScreenTheHonorOfZorroMachine:showJackpotView(coins,jackpotType,multi,func)
    local view = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroJackPotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        multi = multi,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    根据索引获取赢钱
]]
function CodeGameScreenTheHonorOfZorroMachine:getWinCoinsByPosIndex(posIndex)
    local winLines = self.m_runSpinResultData.p_winLines

    local winCoins = 0

    for index = 1,#winLines do
        local lineData = winLines[index]
        local iconPos = lineData.p_iconPos
        if iconPos[1] == posIndex then
            return lineData.p_amount
        end
    end

    return winCoins
end

function CodeGameScreenTheHonorOfZorroMachine:respinOver()
    self:delayCallBack(0.5,function()
        self:setReelSlotsNodeVisible(true)

        -- 更新游戏内每日任务进度条 -- r
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData then
            if selfData.restoreIcons then
                self.m_runSpinResultData.p_storedIcons = selfData.restoreIcons
            end
            if selfData.restoreReels then
                self.m_runSpinResultData.p_reels = selfData.restoreReels
            end
        end

        
        self:showRespinOverView()
    end)
    
end

function CodeGameScreenTheHonorOfZorroMachine:triggerReSpinOverCallFun(score)
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
        local params = {self:getLastWinCoin(), false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    else
        coins = self.m_serverWinCoins or 0
        local params = {self.m_serverWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
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

function CodeGameScreenTheHonorOfZorroMachine:showRespinOverView(effectData)

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:changeSceneFromRespin(function()
            self:removeRespinNode()
            self:changeReSpinOverUI()
        end,function()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self:resetMusicBg() 
            self.m_lightScore = 0
        end)
    end)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_respin_over)

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hide_respin_over)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_btn_click)
    end)

    view:setBtnClickFunc(function(  )
        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.9,sy=0.9},680)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    过场动画(respin到base)
]]
function CodeGameScreenTheHonorOfZorroMachine:changeSceneFromRespin(keyFunc,endFunc)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_chang_scene_from_respin)
    self:changeSceneToRespinAni(keyFunc,endFunc)
end

--结束移除小块调用结算特效
function CodeGameScreenTheHonorOfZorroMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        local symbolType = node.p_symbolType
        
        --respin结束 把respin小块放回对应滚轴位置
        self:checkChangeRespinFixNode(node)
    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenTheHonorOfZorroMachine:checkChangeRespinFixNode(node)
    local colIndex = node.p_cloumnIndex
    local rowIndex = node.p_rowIndex
    local symbolType = node.p_symbolType

    self.m_iReelRowNum = BASE_ROW_NUM
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    local symbolNode = self:getFixSymbol(colIndex,rowIndex)
    if symbolNode then
        symbolNode:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(symbolNode.p_symbolType, symbolNode)

        local reels = self.m_runSpinResultData.p_reels
        if reels then
            local symbolType
            local rowData =  reels[BASE_ROW_NUM - rowIndex + 1]
            if rowData then
                symbolType = rowData[node.p_cloumnIndex]
            end
            if symbolType then
                self:changeSymbolType(node,symbolType)
                if self:isFixSymbol(node.p_symbolType) then
                    if not node.p_symbolImage or not node.p_symbolImage.m_lbl_score then
                        node:initSlotNodeByCCBName(self:getSymbolCCBNameByType(self,node.p_symbolType),node.p_symbolType)
                    end
                    self:updateReelGridNode(node)
                    -- node.p_symbolImage:setVisible(true)
                    -- local aniNode = node:checkLoadCCbNode() 
                    -- aniNode:setVisible(false)
                end
                
            else
                local randType = math.random(0,TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
                self:changeSymbolType(node,randType)
            end
        end
    else
        --把respin上的小块放回池子
        node:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
    end
end

--[[
    过场动画
]]
function CodeGameScreenTheHonorOfZorroMachine:changeSceneToRespinAni(keyFunc,endFunc)
    local spine = util_spineCreate("Socre_TheHonorOfZorro_guochang2",true,true)
    self.m_effectNode:addChild(spine)
    spine:setScale(self.m_bgScale)
    util_spinePlay(spine,"guochang")
    util_spineEndCallFunc(spine,"guochang",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(0.7,keyFunc)
end
--------------------------------------------Respin End----------------------------------------------------------------


------------------------------网络消息相关-----------------------------------------------------------


function CodeGameScreenTheHonorOfZorroMachine:updateNetWorkData()
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

    

    
    
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then

        -- 出现预告动画概率30%
        self.m_isNotice = (math.random(1, 100) <= 30) 

        self:produceSlots()
       
        if self.m_isNotice then
            self:playNoticeAni()
            self:delayCallBack(1.5,function()
                self:operaNetWorkData() -- end
            end)
        else
            self:operaNetWorkData() -- end
        end
        
    else
        self:produceSlots()
        self.m_isNotice = false
        self:operaNetWorkData() -- end
    end
    
end

function CodeGameScreenTheHonorOfZorroMachine:dealSmallReelsSpinStates()
    if not self.m_isNotice then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
    
end

--[[
    预告中奖
]]
function CodeGameScreenTheHonorOfZorroMachine:playNoticeAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_notice_win)
    local noticeAni = util_createAnimation("TheHonorOfZorro_yugao.csb")
    self:findChild("Node_notice"):addChild(noticeAni)

    noticeAni:runCsbAction("actionframe_yugao",false,function()
        noticeAni:removeFromParent()
        if type(func) == "function" then
            func()
        end
    end)

    for index= 1,4 do
        local particle = noticeAni:findChild("Particle_"..index)
        if particle then
            particle:setVisible(false)
        end
    end

    self:delayCallBack(60 / 60,function()
        if not tolua.isnull(noticeAni) then
            for index= 1,4 do
                local particle = noticeAni:findChild("Particle_"..index)
                if particle then
                    particle:setVisible(true)
                    particle:resetSystem()
                end
            end
        end
        
    end)

    self:delayCallBack(105 / 60,function()
        local spine = util_spineCreate("Socre_TheHonorOfZorro_guochang2",true,true)
        self:findChild("root"):addChild(spine)
        util_spinePlay(spine,"guochang2")
        util_spineEndCallFunc(spine,"guochang2",function()
            self:delayCallBack(0.1,function()
                spine:removeFromParent()
            end)
        end)
    end)

    self.m_human_zorro:runNoticeAni(function()
        self:shakeRootNode()
    end,function()
        self:resetRootPos()
    end)
end



------------------------------网络消息相关 end-----------------------------------------------------------

------------------------------快滚 落地相关---------------------------------------------------------- 
--设置长滚信息
function CodeGameScreenTheHonorOfZorroMachine:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    local isScRunLong,isBnRunLong = false,false
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            local reelNode = self.m_baseReelNodes[col]
            reelNode:setRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        
        --统计bonus scatter 信息
        scatterNum, isScRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, isScRunLong)
        bonusNum, isBnRunLong = self:setBonusScatterInfo(self.SYMBOL_SCORE_BONUS, col , bonusNum, isBnRunLong)
        bRunLong = isScRunLong or isBnRunLong
        if isBnRunLong then
            self.m_ScatterShowCol = {1,2,3,4,5}
        else
            self.m_ScatterShowCol = {2,3,4}
        end
    end --end  for col=1,iColumn do

end

--设置bonus scatter 信息
function CodeGameScreenTheHonorOfZorroMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    local needCount = 2
    local isBonus = false
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = {2,3,4}
        
        if column >= 4 then
            bRun = false
        end
    else
        isBonus = true
        needCount = 3
        showCol = {1,2,3,4,5}
    end
    
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol,needCount)
    if isBonus then
        bRun = true
    end

    local columnData = self.m_reelColDatas[column]
    

    local resultReel = self.m_runSpinResultData.p_reels

    local iRow = #resultReel

    for row = 1, iRow do
        if resultReel and resultReel[row] and 
        resultReel[row][column] and 
        (resultReel[row][column] == symbolType or 
        (isBonus and self:isFixSymbol(resultReel[row][column]))) then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol,needCount)

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

            if not isBonus then
                break
            end
        end
        
    end

    if self.m_isNotice then
        return 0,false
    end

    if bRun == true and nextReelLong == true and bRunLong == false and (self:checkIsInLongRun(column + 1, symbolType) == true or isBonus) then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)

        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self.m_isScatterRun = true
        end
    end
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenTheHonorOfZorroMachine:getRunStatus(col, nodeNum, showCol,needCount)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum >= needCount then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= needCount  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum >= needCount then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

--[[
    fs中检测是否播落地
]]
function CodeGameScreenTheHonorOfZorroMachine:checkPlayBulingInFs(posIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
   
    if self.m_isSuperFree then
        if selfData and selfData.newStickIcons then
            local newStickIcons = selfData.newStickIcons
            for index = 1,#newStickIcons do
                if newStickIcons[index][1] == posIndex then
                    return true
                end
            end
        end
    end
    

    return false
end

--[[
    检测播放落地动画
]]
function CodeGameScreenTheHonorOfZorroMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                --提层
                if symbolCfg[1] then
                    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    symbolNode:setPositionY(curPos.y)

                    --回弹
                    local actList = {}
                    local moveTime = self.m_configData.p_reelResTime
                    local dis = self.m_configData.p_reelResDis
                    local pos = cc.p(curPos)
                    local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                    local action2 = cc.MoveTo:create(moveTime / 2,pos)
                    actList = {action1,action2}
                    symbolNode:runAction(cc.Sequence:create(actList))
                end

                local posIndex = self:getPosReelIdx(iRow, colIndex)
                local isPlayBuling = true
                if self.m_isSuperFree and self:isFixSymbol(symbolNode.p_symbolType) and not self:checkPlayBulingInFs(posIndex) then
                    isPlayBuling = false
                end

                if isPlayBuling then
                    if self:checkSymbolBulingAnimPlay(symbolNode) then
                        --2.播落地动画
                        symbolNode:runAnim(
                            symbolCfg[2],
                            false,
                            function()
                                self:symbolBulingEndCallBack(symbolNode)
                            end
                        )
                        
                        --scatter落地音效
                        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            self:checkPlayScatterDownSound(colIndex)
                        end

                        --bonus落地音效
                        if self:isFixSymbol(symbolNode.p_symbolType) then
                            self:checkPlayBonusDownSound(colIndex)
                        end
                    end
                end
            end
            
        end
    end
end
--[[
    图标落地回调
]]
function CodeGameScreenTheHonorOfZorroMachine:symbolBulingEndCallBack(symbolNode)

    if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isLongRun and self.m_isScatterRun then
            if symbolNode.m_currAnimName ~= "idleframe3" then
                self:runSymbolIdleLoop(symbolNode,"idleframe3")
            end
        else
            self:runSymbolIdleLoop(symbolNode,"idleframe2")
        end
    elseif symbolNode and self:isFixSymbol(symbolNode.p_symbolType) then
        self:runSymbolIdleLoop(symbolNode,"idleframe2")
    end
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenTheHonorOfZorroMachine:playBonusDownSound(colIndex)
    if self:getGameSpinStage() == QUICK_RUN and self.m_isScatterDown then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_bonus_down)
end

--[[
    播放scatter落地音效
]]
function CodeGameScreenTheHonorOfZorroMachine:playScatterDownSound(colIndex)
    if self:getGameSpinStage() == QUICK_RUN then
        self.m_isScatterDown = true
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_scatter_down)
end

--[[
    图标idle
]]
function CodeGameScreenTheHonorOfZorroMachine:runSymbolIdleLoop(symbolNode,aniName)
    if symbolNode and symbolNode.p_symbolType and symbolNode.m_currAnimName ~= aniName then
        symbolNode:runAnim(aniName,true)
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenTheHonorOfZorroMachine:checkSymbolBulingSoundPlay(_slotNode)
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
                return true
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenTheHonorOfZorroMachine:isPlayTipAnima(colIndex, rowIndex, node)
    local symbolType = node.p_symbolType

    local reels = self.m_runSpinResultData.p_reels
    local symbolCount = 0
    if colIndex <= 2 then
        return true
    elseif colIndex >= 3 then
        for iRow = 1,#reels do
            for iCol = 1,3 do
                if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    symbolCount = symbolCount + 1
                end
            end
        end
        if symbolCount == 2 and colIndex == 3 then
            return true
        elseif symbolCount >= 2 then
            return true
        end
    end

    return false
end
------------------------------快滚 落地 相关 end-----------------------------------------------------------

function CodeGameScreenTheHonorOfZorroMachine:scaleMainLayer()
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

    self.m_bgScale = 1
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    if ratio <= 2176 / 1800 then
        mainScale = 0.60
        mainPosY = mainPosY + 28
        self:findChild("bg"):setScale(1.2)
        self.m_bgScale = 1.2
    elseif ratio > 2176 / 1800 and ratio <= 1024 / 768 then
        mainScale = 0.69
        mainPosY = mainPosY + 28
    elseif ratio > 1024 / 768 and ratio <= 960 / 640 then
        mainScale = 0.81
        mainPosY = mainPosY + 25
    elseif ratio > 960 / 640 and ratio <= 1228 / 768 then
        mainScale = 0.87
        mainPosY = mainPosY + 10
    elseif ratio > 1228 / 768 and ratio < 1368 / 768 then
        mainScale = 0.87
        mainPosY = mainPosY + 10
    elseif ratio >= 1368 / 768 and ratio < 1560 / 768 then
        mainScale = 1
    else
        mainScale = 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale

    self.m_machineNode:setPositionY(mainPosY)
end

function CodeGameScreenTheHonorOfZorroMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "respin" == _sFeature then
        return
    end
    if CodeGameScreenTheHonorOfZorroMachine.super.levelDeviceVibrate then
        CodeGameScreenTheHonorOfZorroMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenTheHonorOfZorroMachine:showEffect_runBigWinLightAni(effectData)
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
function CodeGameScreenTheHonorOfZorroMachine:showBigWinLight(_func)
    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,self.m_effectNode)
    --人物大赢动作
    self.m_human_zorro:runBigWinAction()
    --震动屏幕
    self:shakeRootNode()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_big_win)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_big_win_1)

    local lbl_winCoins = util_createAnimation("TheHonorOfZorro_bigwin.csb")
    self.m_effectNode:addChild(lbl_winCoins)
    lbl_winCoins:setPosition(cc.p(pos.x,pos.y))
    lbl_winCoins:runCsbAction("actionframe",false,function()
        
        self:resetRootPos()
        if type(_func) == "function" then
            _func()
        end
        lbl_winCoins:removeFromParent()
    end)

    local light = util_spineCreate("TheHonorOfZorro_totalwin",true,true)
    lbl_winCoins:findChild("Node_totalwin"):addChild(light)

    util_spinePlay(light,"actionframe")
    

    local winCoins = self.m_runSpinResultData.p_winAmount

    self:jumpCoins({
        label = lbl_winCoins:findChild("m_lb_coins"),
        startCoins = 0,
        endCoins = winCoins,
        maxWidth = 500,
        lblScale = 1,
        endFunc = function()
            
        end
    })
end

return CodeGameScreenTheHonorOfZorroMachine