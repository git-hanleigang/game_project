---
-- island li
-- 2019年1月26日
-- CodeGameScreenDiscoFeverMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"
local SlotsDiscoNode = require "CodeDiscoFeverSrc.DiscoFeverSlotsNode"

local CodeGameScreenDiscoFeverMachine = class("CodeGameScreenDiscoFeverMachine", BaseSlotoManiaMachine)

CodeGameScreenDiscoFeverMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenDiscoFeverMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  -- 信号10
CodeGameScreenDiscoFeverMachine.SYMBOL_FREESPIN_MORE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  -- freespin + 1
CodeGameScreenDiscoFeverMachine.SYMBOL_JACKPOT_UP_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3  -- jPUp + 1
CodeGameScreenDiscoFeverMachine.SYMBOL_JACKPOT_UP_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4  -- jPUp + 2

CodeGameScreenDiscoFeverMachine.WILD_FLY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenDiscoFeverMachine.SCATTER_FLY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenDiscoFeverMachine.JPUP_1_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识
CodeGameScreenDiscoFeverMachine.JPUP_2_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 自定义动画的标识

CodeGameScreenDiscoFeverMachine.SYMBOL_SCATTER_BG = 3000 -- scatter 的背景
CodeGameScreenDiscoFeverMachine.SYMBOL_JpUp_BG = 3001 -- scatter 的背景

CodeGameScreenDiscoFeverMachine.FS_JACKPOT_POOL= {} -- jackpot奖池

CodeGameScreenDiscoFeverMachine.FS_JACKPOTBAR_ACT_INDEX= nil -- jackpot动画索引

CodeGameScreenDiscoFeverMachine.jackpotLevel = 0
CodeGameScreenDiscoFeverMachine.WildLevel = 0


CodeGameScreenDiscoFeverMachine.WILD_BET =  1
CodeGameScreenDiscoFeverMachine.BLANK_BET = 4
CodeGameScreenDiscoFeverMachine.JPUP_1_BET = 2
CodeGameScreenDiscoFeverMachine.JPUP_2_BET = 3


CodeGameScreenDiscoFeverMachine.m_betLevel = nil -- betlevel 0 1 2

CodeGameScreenDiscoFeverMachine.m_wildChangeList = {0,0,0,0,0}

CodeGameScreenDiscoFeverMachine.m_initGame  = false


local FIT_HEIGHT_MAX = 1281
local FIT_HEIGHT_MIN = 1136

-- 构造函数
function CodeGameScreenDiscoFeverMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.FS_JACKPOTBAR_ACT_INDEX = 1
    self.isInBonus = false
    self.m_wildChangeList = {0,0,0,0,0}
    self.FS_JACKPOT_POOL= {}

    self.m_betLevel = nil
    self.m_initGame  = true
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenDiscoFeverMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {2,3,4}

end


function CodeGameScreenDiscoFeverMachine:changeViewNodePos( )

    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5

        self:findChild("fsbar"):setPositionY(self:findChild("fsbar"):getPositionY() - posY)
        self:findChild("Panel_2"):setPositionY(self:findChild("Panel_2"):getPositionY() - posY)

        for i=1,self.m_iReelColumnNum do
            local pos = i -1
            self:findChild("sp_reel_"..pos):setPositionY(self:findChild("sp_reel_"..pos):getPositionY() - posY)

        end

        self:findChild("Node_Lunpan"):setPositionY(self:findChild("Node_Lunpan"):getPositionY() - posY)

        local nodeJackpot = self:findChild("jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - posY )

        local nodelogo = self:findChild("logo")
        nodelogo:setPositionY(nodelogo:getPositionY() - posY )

        local nodewheel = self:findChild("wheel")
        nodewheel:setPositionY(nodewheel:getPositionY() - posY )

        local jpLittleView = self:findChild("jpLittleView")
        jpLittleView:setPositionY(jpLittleView:getPositionY() - posY )

        local hightLowBet = self:findChild("hightLowBet")
        hightLowBet:setPositionY(hightLowBet:getPositionY() - posY )



        if (display.height / display.width) >= 1.76 and (display.height / display.width) < 2 then
            local nodeJackpot = self:findChild("jackpot")
            nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY -25 )

            local nodelogo = self:findChild("logo")
            nodelogo:setPositionY(nodelogo:getPositionY() + posY -25 )

            local nodewheel = self:findChild("wheel")
            nodewheel:setPositionY(nodewheel:getPositionY() + posY -50 )
        elseif (display.height / display.width) >= 2 then
            local nodeJackpot = self:findChild("jackpot")
            nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY  -120 )

            local nodelogo = self:findChild("logo")
            nodelogo:setPositionY(nodelogo:getPositionY() + posY + 25 )
            nodelogo:setScale(1.3)

            local nodewheel = self:findChild("wheel")
            nodewheel:setPositionY(nodewheel:getPositionY() + posY -50 )
        end





    elseif display.height < FIT_HEIGHT_MIN then


    end



    local bangDownHeight = util_getSaveAreaBottomHeight()
    local nodeJackpot = self:findChild("jackpot")
    nodeJackpot:setPositionY(nodeJackpot:getPositionY() - bangDownHeight )

end

function CodeGameScreenDiscoFeverMachine:scaleMainLayer()
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
        if display.height >= FIT_HEIGHT_MAX then
            mainScale = (FIT_HEIGHT_MAX + 80 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale + 0.05
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if (display.height / display.width) >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 23)
            else
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 23 )
            end

        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 10 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 2)
        else
            mainScale = (display.height + 25 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)

end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenDiscoFeverMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "DiscoFever"
end


function CodeGameScreenDiscoFeverMachine:initUI()

    self.m_reelRunSound = "DiscoFeverSounds/music_DiscoFever_LongRun.mp3"

    self.m_WildActNode =  cc.Node:create()
    self:findChild("root"):addChild(self.m_WildActNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_scaleChild = {self.m_gameBg,self.m_topUI,self.m_bottomUI,self.m_root}
    self.m_scaleChildOldScaleList = {}
    for i,j in pairs(self.m_scaleChild) do
        local scale = j:getScale()
        table.insert( self.m_scaleChildOldScaleList,scale )
    end

    self:initFreeSpinBar() -- FreeSpinbar
    self.m_baseFreeSpinBar = self:findChild("fsbar")
    self.m_baseFreeSpinBar:setVisible(false)

    -- 创建view节点方式
    -- self.m_DiscoFeverView = util_createView("CodeDiscoFeverSrc.DiscoFeverView")
    -- self:findChild("xxxx"):addChild(self.m_DiscoFeverView)

    self.m_BgActionView = util_createView("CodeDiscoFeverSrc.DiscoFeverBgActionView")
    self:findChild("Node_1"):addChild(self.m_BgActionView)
    self.m_BgActionView:runCsbAction("animation0",true)
    self.m_BgActionView:showOneAction( 0)

    self:changeGameBg( )


    self.m_BetLogoView = util_createView("CodeDiscoFeverSrc.DiscoFeverBetLogoView",self)
    self:findChild("hightLowBet"):addChild(self.m_BetLogoView)
    self.m_BetLogoView:setVisible(true)




    --高低bet选择
    self.m_hightLowbetView = util_createView("CodeDiscoFeverSrc.DiscoFeverHightLowbetView")
    self:addChild(self.m_hightLowbetView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    -- self.m_hightLowbetView:setPosition(cc.p(-display.width/2,-display.height/2))
    self.m_hightLowbetView:setVisible(false)
    self.m_hightLowbetView:initMachine(self)

    -- 过场
    self.m_GuoChangView = util_createView("CodeDiscoFeverSrc.DiscoFeverGuoChangeView")
    self:addChild(self.m_GuoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1) -- :findChild("guoChange")
    self.m_GuoChangView:setPosition(cc.p(display.width/2,display.height/2))
    -- self.m_GuoChangView:runCsbAction("actionframe",true)
    self.m_GuoChangView:setVisible(false)

    self:findChild("guoChange"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 500)

    -- logo
    self.m_LogoView = util_createView("CodeDiscoFeverSrc.DiscoFeverLogoView")
    self:findChild("logo"):addChild(self.m_LogoView)
    self.m_LogoView:runCsbAction("idle",true)

    -- wild收集个数
    self.m_WildNumBar = util_createView("CodeDiscoFeverSrc.DiscoFeverWildNumBarView")
    self:findChild("left"):addChild(self.m_WildNumBar)
    self.m_WildNumBar.m_sumNum = 0
    self.m_WildNumBar:findChild("BitmapFontLabel_1"):setString(0)

    -- freespin剩余次数
    self.m_freespinTimesBar = util_createView("CodeDiscoFeverSrc.DiscoFeverFreespinBarView")
    self:findChild("right"):addChild(self.m_freespinTimesBar)


    self.m_CollectAct_right = util_createView("CodeDiscoFeverSrc.DiscoFeverCollectActView")
    self:findChild("right"):addChild(self.m_CollectAct_right)
    self.m_CollectAct_right:setVisible(false)

    self.m_CollectAct_left = util_createView("CodeDiscoFeverSrc.DiscoFeverCollectActView")
    self:findChild("left"):addChild(self.m_CollectAct_left)
    self.m_CollectAct_left:setVisible(false)



    -- jackpotbar
    self.m_jackPorBar = util_createView("CodeDiscoFeverSrc.DiscoFeverJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackPorBar,-1)
    self.m_jackPorBar:initMachine(self)
    self.m_jackPorBar:runCsbAction("UIblue",true)

    self:findChild("jpLittleView"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self.m_JPWinLittleView = util_createView("CodeDiscoFeverSrc.DiscoFeverJPWinLittleView")
    self:findChild("jpLittleView"):addChild(self.m_JPWinLittleView)
    -- self.m_GuoChangView:runCsbAction("actionframe",true)
    self.m_GuoChangView:setVisible(false)


    local jplevel = {100,65,40,20}
    for i=1,4 do
        local jpScoreName = "jpScoreLab"..i
        self[jpScoreName] = util_createView("CodeDiscoFeverSrc.DiscoFeverWildJpScoreView")
        self:findChild("Score"..i):addChild(self[jpScoreName])
        self[jpScoreName]:findChild("BitmapFontLabel_1"):setString(jplevel[i])
    end

    -- self:createWheelView()


    self:dealWildLevelNumNode( false)
    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(1)
    self:updatejackPotLevelUI(false )

    self.m_soundNode = cc.Node:create()
    self:addChild(self.m_soundNode)


    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin or self.m_initGame then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 0
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
            soundTime = 2
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        else
            soundIndex = 3
            soundTime = 3
        end
        local soundName = "DiscoFeverSounds/music_DiscoFever_last_win_".. soundIndex ..".mp3"
        globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
                                                        

        -- performWithDelay(self.m_soundNode,function(  )
        --     if self.m_winSoundsId then
        --         gLobalSoundManager:stopAudio(self.m_winSoundsId)
        --         self.m_winSoundsId = nil
        --         gLobalSoundManager:playSound("DiscoFeverSounds/music_DiscoFever_last_win_over.mp3",false)
        --     end


        --     gLobalSoundManager:setBackgroundMusicVolume(1)

        -- end,soundIndex)



    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenDiscoFeverMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "DiscoFeverSounds/DiscoFever_scatter_down_1.mp3"
        elseif i == 2 then
            soundPath = "DiscoFeverSounds/DiscoFever_scatter_down_2.mp3"
        else
            soundPath = "DiscoFeverSounds/DiscoFever_scatter_down_3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenDiscoFeverMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        gLobalSoundManager:playSound("DiscoFeverSounds/music_DiscoFever_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end

        end,3.6,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenDiscoFeverMachine:checkShowChooseBetView( )
    local features =  self.m_runSpinResultData.p_features or {}
    local isShow = true

    for k,v in pairs(features) do
        if v == 1 then --触发freespin时
            isShow = false
        elseif  v == 3  then -- 触发respin时
            isShow = false
        end
    end

    -- 在freespin玩法中
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isShow = false
    end

    -- 在respin玩法中
    if self:getCurrSpinMode() == RESPIN_MODE then
        isShow = false
    end

    -- autospin
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        isShow = false
    end

    return isShow
end

function CodeGameScreenDiscoFeverMachine:showHightLowBetView( )
    if self:getBetLevel() == 0 then
        self.m_hightLowbetView:setVisible(true)
        self.m_hightLowbetView:initMachine(self)
        local data = {}
        data.minBet = self:getMinBet( )
        data.betLevel = self:getBetLevel()
        self.m_hightLowbetView:initMachineBetDate(data)
        local norScore = self.m_hightLowbetView:findChild("unlockcoins")
        if norScore then
            norScore:setString(util_formatCoins(data.minBet,30))
            self.m_hightLowbetView:updateLabelSize({label=norScore,sx=1,sy=1},293)
        end
    end

end

function CodeGameScreenDiscoFeverMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:upateBetLevel()

    if self:checkShowChooseBetView( ) then


        self:showHightLowBetView( )


    end





end

function CodeGameScreenDiscoFeverMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
   end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenDiscoFeverMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenDiscoFeverMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_DiscoFever_10"
    elseif symbolType == self.SYMBOL_FREESPIN_MORE then
        return "Socre_DiscoFever_freespin"
    elseif symbolType == self.SYMBOL_JACKPOT_UP_1 then
        return "Socre_DiscoFever_Single"
    elseif symbolType == self.SYMBOL_JACKPOT_UP_2 then
        return "Socre_DiscoFever_Double"
    elseif symbolType == self.SYMBOL_SCATTER_BG then
        return "DiscoFever_Scatter_guangbo"
    elseif symbolType == self.SYMBOL_JpUp_BG then
        return "DiscoFever_Scatter_guangbo_0"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenDiscoFeverMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 20}
    }


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  20}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FREESPIN_MORE,count =  20}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_UP_1,count =  20}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_UP_2,count =  20}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_BG,count =  20}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JpUp_BG,count =  20}



    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

---
-- 进入关卡
--
function CodeGameScreenDiscoFeverMachine:enterLevel()
    BaseSlotoManiaMachine.enterLevel(self)

    -- self:changeSlotParentZOrderOutLine()

    self:runScatterIdleFrame4( )

end

-- 断线重连
function CodeGameScreenDiscoFeverMachine:MachineRule_initGame(  )



    self:updataFSJackPotPoolToNormal()


    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        self.m_hightLowbetView:setVisible(false)
        self.m_BetLogoView:setVisible(false)

        local index = nil
        if self.m_runSpinResultData.p_fsExtraData then
            if self.m_runSpinResultData.p_fsExtraData.wildLevel then
                index = self.m_runSpinResultData.p_fsExtraData.wildLevel + 1
                self.WildLevel = index
            end
        end
        if index then
            self.m_jackPorBar:showOneJPAction( index )
        end

        self:dealWildLevelNumNode( true)

        scheduler.performWithDelayGlobal(function (  )
            self.m_jackPorBar:runMusicalSpineAction(true )
        end,4,self:getModuleName())

        self.m_jackPorBar:toFreespin( )

        self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
        self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
        self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
        self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
        self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)

        self:updatejackPotLevelUI(true )
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData then
            if fsExtraData.jackpotLevel then
                self.jackpotLevel = fsExtraData.jackpotLevel
                self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(fsExtraData.jackpotLevel )
            end
        end


        self:updataFSJackPotPool()

        self.m_WildNumBar.m_sumNum = 0
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData then
            if fsExtraData.wildCount then
                self.m_WildNumBar.m_sumNum = fsExtraData.wildCount
            end
        end

        self.m_WildNumBar:findChild("BitmapFontLabel_1"):setString(self.m_WildNumBar.m_sumNum)
        self.m_WildNumBar:updateLabelSize({label=self.m_WildNumBar:findChild("BitmapFontLabel_1"),sx=1.3,sy=1.3},46)

    end



end

--
--单列滚动停止回调
--
function CodeGameScreenDiscoFeverMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1)
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end


    local icol = reelCol
    local wildChangeAct = self.m_wildChangeList[icol]
    if wildChangeAct  and wildChangeAct ~= 0 then
        wildChangeAct:runCsbAction("over",false,function(  )
            if self.m_wildChangeList[icol] and self.m_wildChangeList[icol] ~= 0 then
                self.m_wildChangeList[icol]:setVisible(false)
            end
        end)
    end

    -- if  self:getGameSpinStage() ~= QUICK_RUN  then

    -- end

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then

        self:beginShake()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    -- self:changeSlotParentZOrder()


    local isHaveFSMoreSymbol = false
    local isHaveScatter = false
    local isHaveJpUp = false
    local isPlayScatterDown = false

    for k = 1, self.m_iReelRowNum do
        if self.m_stcValidSymbolMatrix[k][reelCol] == self.SYMBOL_FREESPIN_MORE then
            isHaveFSMoreSymbol = true
            -- local tarspr = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
            -- if tarspr then
            --     tarspr:runAnim("actionframe",true)
            -- end
        elseif self.m_stcValidSymbolMatrix[k][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            -- local tarspr = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
            -- if tarspr then
            --     tarspr:runAnim("buling",false,function(  )
            --         tarspr:runAnim("idleframe2",true)
            --     end)
            -- end
            isHaveScatter = true
        elseif self.m_stcValidSymbolMatrix[k][reelCol] == self.SYMBOL_JACKPOT_UP_1 then
            isHaveJpUp = true
            local tarspr = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
            -- if tarspr then
            --     tarspr:runAnim("buling",false,function(  )
            --         tarspr:runAnim("idleframe",true)
            --     end)
            -- end

        elseif self.m_stcValidSymbolMatrix[k][reelCol] == self.SYMBOL_JACKPOT_UP_2 then
            isHaveJpUp = true
            local tarspr = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
            if tarspr then
                -- tarspr:runAnim("buling",false,function(  )
                --     tarspr:runAnim("idleframe",true)
                -- end)

            end
        elseif self.m_stcValidSymbolMatrix[k][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            local tarspr = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
            if tarspr then
                -- tarspr:runAnim("idleframe",true)

            end
        end


        local slotNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
        if slotNode then
            if self:isPlayTipAnima(reelCol, k,slotNode) == true then
                isPlayScatterDown = true
            end
        end



    end


    if self.m_reelDownSoundPlayed  then
        if self:checkIsPlayReelDownSound( reelCol ) then
            if not isPlayScatterDown then
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if self.m_machineIndex == 1 and reelCol <= self.m_iCurrReelCol then
            if not isPlayScatterDown then
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
    end

    

    if isHaveJpUp then
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_JPUp_down.mp3")
    end

end

function CodeGameScreenDiscoFeverMachine:runScatterIdleFrame4( )

    for reelCol=1,self.m_iReelColumnNum do
        for k = 1, self.m_iReelRowNum do
            --if self.m_stcValidSymbolMatrix[k][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local tarspr = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                if tarspr.p_symbolType and tarspr.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    if not self:getFreatureIsFreeSpin() then
                        tarspr:runAnim("idleframe4",true)
                    end

                end

            --end
        end
    end
end

function CodeGameScreenDiscoFeverMachine:reelDownNotifyPlayGameEffect( )
    local waitTime = 0
    local selfMakeData =  self.m_runSpinResultData.p_selfMakeData
   if selfMakeData then
        local  wildColumn = selfMakeData.wildColumn
        if wildColumn then
            for k,v in pairs(wildColumn) do
                local col = v + 1
                if col >= 1  then
                    waitTime = 0.5
                    break
                end

            end


        end

   end



   scheduler.performWithDelayGlobal(function (  )

        if self then
            self.m_WildActNode:removeAllChildren()
            for k,v in pairs(self.m_wildChangeList) do
                if v ~= 0 then
                    print("移除 列 ".. k)
                    self.m_wildChangeList[k] = 0
                end
            end

            scheduler.performWithDelayGlobal(function (  )
                if self then
                    BaseMachine.reelDownNotifyPlayGameEffect(self)
                end

            end,0.1,self:getModuleName())
        end



    end,waitTime,self:getModuleName())


end

function CodeGameScreenDiscoFeverMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    self:runScatterIdleFrame4()

    BaseMachine.slotReelDown(self)

end
function CodeGameScreenDiscoFeverMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenDiscoFeverMachine.super.playEffectNotifyNextSpinCall(self)
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenDiscoFeverMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenDiscoFeverMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")

end
---------------------------------------------------------------------------

function CodeGameScreenDiscoFeverMachine:getHightBetGiftId( )
    local id = self.BLANK_BET
    local endIndex = 0
    local wheelDataExtra  = {}
    local wildNum = 0
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData then

        if fsExtraData.select then
            endIndex  =  fsExtraData.select + 1
        end

        if fsExtraData.wheelExtra then
            wheelDataExtra = fsExtraData.wheelExtra

            for k,v in pairs(wheelDataExtra) do
                if k ==  endIndex then
                    if v.type == "wild" then
                        id = self.WILD_BET
                        wildNum = v.num

                    elseif v.type == "levelUp" then
                        if v.num == 1 then
                            id = self.JPUP_1_BET
                        elseif v.num == 2 then
                            id = self.JPUP_2_BET
                        end

                    elseif  v.type == "blank" then
                        id = self.BLANK_BET
                    end

                    break
                end

            end
        end
    end

    return id,wildNum
end

----------- FreeSpin相关

---
-- 显示free spin
function CodeGameScreenDiscoFeverMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if scatterLineValue ~= nil then


        if self.m_soundNode then
            self.m_soundNode:stopAllActions()
        end
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        gLobalSoundManager:stopAllAuido()

        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showFreeSpinView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end

-- FreeSpinstart
function CodeGameScreenDiscoFeverMachine:showFreeSpinView(effectData)

    self.isInBonus = true



    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:createWheelView(function(  )

                gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenView.mp3")

                self:clearCurMusicBg()

                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                    -- gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_CloseView.mp3")

                    performWithDelay(self,function(  )
                        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_GuoChang.mp3")

                        self.m_GuoChangView:setVisible(true)
                        self.m_GuoChangView:runCsbAction("guochangdonghua",false,function(  )
                            self.m_GuoChangView:setVisible(false)
                        end)
                        performWithDelay(self,function(  )

                            if self.m_wheel then
                                self.m_wheel:removeFromParent()
                                self.m_wheel = nil
                            end

                            self.m_hightLowbetView:setVisible(false)
                            self.m_BetLogoView:setVisible(false)

                            self.m_jackPorBar:showOneJPAction( 1 )
                            self:updatejackPotLevelUI(true )
                            self:dealWildLevelNumNode( true)
                            self.m_jackPorBar:toFreespin( )
                            self.m_jackPorBar:runMusicalSpineAction(false )
                            self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
                            self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
                            self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
                            self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
                            self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
                            self:showFreeSpinBar()
                            self:setCurrSpinMode( FREE_SPIN_MODE )
                            self.m_bProduceSlots_InFreeSpin = true


                            local fsStartFunc = function(  )
                                local index = nil
                                if self.m_runSpinResultData.p_fsExtraData then
                                    if self.m_runSpinResultData.p_fsExtraData.wildLevel then
                                        index = self.m_runSpinResultData.p_fsExtraData.wildLevel + 1
                                        self.WildLevel = index
                                    end
                                end
                                if index then
                                    self.m_jackPorBar:showOneJPAction( index )
                                end

                                self.isInBonus = false
                                self:dealWildLevelNumNode( true)

                                self.m_jackPorBar:toFreespin( )

                                self.m_jackPorBar:runMusicalSpineAction(true )
                                self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
                                self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
                                self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
                                self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
                                self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)

                                self:updataFSJackPotPool( )


                                self:triggerFreeSpinCallFun()
                            end
                            local id,num = self:getHightBetGiftId( )
                            if self:getBetLevel() == 0 then
                                id = 4
                            end
                            if id == self.WILD_BET then

                                performWithDelay(self,function()
                                    self:WILD_Bet_EFFECT( effectData,function(  )
                                        fsStartFunc()
                                    end,num)
                                end,1)


                            elseif id == self.JPUP_1_BET then
                                performWithDelay(self,function()
                                    self:JPUP_1_Bet_EFFECT(effectData ,function(  )
                                        fsStartFunc()
                                    end)
                                end,1)

                            elseif id == self.JPUP_2_BET then
                                performWithDelay(self,function()
                                    self:JPUP_2_Bet_EFFECT(effectData,function(  )
                                        fsStartFunc()
                                    end )
                                end,1)

                            else
                                fsStartFunc()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        end,21/30)
                    end,2)


                end)
            end)

        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()
    end,1.5)



end

---------------------------------弹版----------------------------------
function CodeGameScreenDiscoFeverMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num

    local nameList = {"DiscoFever_give_wild","DiscoFever_fs_text2_4","DiscoFever_fs_text1_3"}

    local id,wildnum = self:getHightBetGiftId( )
    if self:getBetLevel() == 0 then
        id = 4
    end
    if id == self.WILD_BET then

        local View =  self:showDialog("FreeSpinStart1",ownerlist,func)
        View:findChild("m_lb_num1"):setString(wildnum)

        for k,v in pairs(nameList) do
            local node = View:findChild(v)
            if node then
                if k == self.WILD_BET then
                    node:setVisible(true)
                else
                    node:setVisible(false)
                end
            end
        end

        return View


    elseif id == self.JPUP_1_BET then
        local View =  self:showDialog("FreeSpinStart1",ownerlist,func)
        for k,v in pairs(nameList) do
            local node = View:findChild(v)
            if node then
                if k == self.JPUP_1_BET then
                    node:setVisible(true)
                else
                    node:setVisible(false)
                end
            end
        end
        return View
    elseif id == self.JPUP_2_BET then
        local View =  self:showDialog("FreeSpinStart1",ownerlist,func)
        for k,v in pairs(nameList) do
            local node = View:findChild(v)
            if node then
                if k == self.JPUP_2_BET then
                    node:setVisible(true)
                else
                    node:setVisible(false)
                end
            end
        end
        return View

    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    end


    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenDiscoFeverMachine:showFreeSpinOverView()

    local index = nil
    local waitTime = 0
    -- if self.m_runSpinResultData.p_fsExtraData then
    --     if self.m_runSpinResultData.p_fsExtraData.wildLevel then
    --         index = self.m_runSpinResultData.p_fsExtraData.wildLevel + 1
    --         waitTime = 2
    --     end
    -- end
    -- self.m_jackPorBar:showOneJPAction( index )

    if self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines > 0 then

    else

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self:getLastWinCoin(),false,true})
    end

    performWithDelay(self,function(  )
            gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenView.mp3")

            local fsOverView = util_createView("CodeDiscoFeverSrc.DiscoFeverFreespinOverView")
            self:addChild(fsOverView,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
            if globalData.slotRunData.machineData.p_portraitFlag then
                fsOverView.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = fsOverView})

            -- fsOverView:setPosition(-display.width/2,-display.height/2)
            local jpscore =  0
            if self.m_runSpinResultData.p_fsExtraData then
                if self.m_runSpinResultData.p_fsExtraData.jackpotWin then
                    jpscore = self.m_runSpinResultData.p_fsExtraData.jackpotWin
                end
            end
            local norScore = globalData.slotRunData.lastWinCoin - jpscore

            local total = util_formatCoins(globalData.slotRunData.lastWinCoin,30)
            local jp = util_formatCoins(jpscore,30)
            local nor= util_formatCoins(norScore,30)

            fsOverView:changeLab(jp,nor,total )

            fsOverView:initCallFunc( function(  )

                -- gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_CloseView.mp3")

                performWithDelay(self,function(  )
                    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_GuoChang.mp3")
                    self.m_GuoChangView:setVisible(true)
                    self.m_GuoChangView:runCsbAction("guochangdonghua",false,function(  )
                        self.m_GuoChangView:setVisible(false)
                    end)
                    performWithDelay(self,function(  )

                        self.m_hightLowbetView:setVisible(false)
                        self.m_BetLogoView:setVisible(true)

                        self.jackpotLevel = 0

                        self:updatejackPotLevelUI(false )
                        self:updataFSJackPotPoolToNormal()
                        self:triggerFreeSpinOverCallFun()

                        self:dealWildLevelNumNode( false)

                        self.m_jackPorBar:runMusicalSpineAction(false )
                        self.m_jackPorBar:updateMusicalSpine( )
                        self.FS_JACKPOTBAR_ACT_INDEX = 1
                        self.m_jackPorBar:toNormal( )

                        self:changeGameBg( )
                        self.m_jackPorBar:hideAllJPAction( )
                        self.m_jackPorBar:hideAllJpWinImg(  )

                        self.m_WildNumBar.m_sumNum = 0
                        self.m_WildNumBar:findChild("BitmapFontLabel_1"):setString(0)

                        self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(1)

                        self.m_BgActionView:showOneAction(0)

                    end,21/30)
                end,2)

            end)
    end,waitTime)




end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenDiscoFeverMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    self.m_initGame = false

    -- if self.m_soundNode then
    --     self.m_soundNode:stopAllActions()
    -- end
    -- if self.m_winSoundsId then
    --     gLobalSoundManager:stopAudio(self.m_winSoundsId)
    --     self.m_winSoundsId = nil
    --     gLobalSoundManager:playSound("DiscoFeverSounds/music_DiscoFever_last_win_over.mp3",false)
    -- end



    self.isInBonus = false

    -- self:restSlotParentZOrder()
    for k,v in pairs(self.m_wildChangeList) do
        if v ~= 0 then
            self.m_wildChangeList[k]:removeFromParent()
            self.m_wildChangeList[k] = 0
        end
    end



    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenDiscoFeverMachine:MachineRule_network_InterveneSymbolMap()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenDiscoFeverMachine:MachineRule_afterNetWorkLineLogicCalculate()


    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

end



--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenDiscoFeverMachine:addSelfEffect()

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local wildNum = self:getSymbolCountWithReelResult(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            if wildNum and wildNum > 0 then
                 -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.WILD_FLY_EFFECT -- 动画类型
            end

            local fsMoreNum = self:getSymbolCountWithReelResult(self.SYMBOL_FREESPIN_MORE )
            if fsMoreNum and fsMoreNum > 0 then
                 -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.SCATTER_FLY_EFFECT -- 动画类型
            end

            local jpUp_1_Num = self:getSymbolCountWithReelResult(self.SYMBOL_JACKPOT_UP_1 )
            if jpUp_1_Num and jpUp_1_Num > 0 then
                 -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.JPUP_1_EFFECT -- 动画类型
            end

            local jpUp_2_Num = self:getSymbolCountWithReelResult(self.SYMBOL_JACKPOT_UP_2 )
            if jpUp_2_Num and jpUp_2_Num > 0 then
                 -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.JPUP_2_EFFECT -- 动画类型
            end

        end


end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenDiscoFeverMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.WILD_FLY_EFFECT then
        self:WILD_FLY_EFFECT( effectData)
    elseif effectData.p_selfEffectType == self.SCATTER_FLY_EFFECT then
        self:SCATTER_FLY_EFFECT(effectData )
    elseif effectData.p_selfEffectType == self.JPUP_1_EFFECT then
        self:JPUP_1_EFFECT(effectData )
    elseif effectData.p_selfEffectType == self.JPUP_2_EFFECT then
        self:JPUP_2_EFFECT(effectData )
    end


	return true
end

function CodeGameScreenDiscoFeverMachine:WILD_Bet_EFFECT( effectData,CallFunc,wildSumNum)

    if wildSumNum == 0 or wildSumNum == nil then

        if CallFunc then
            CallFunc()
        end

        effectData.p_isPlay = true
        self:playGameEffect()

        return
    end
    local wildNum = 0

    local dealyTime = 0.2

    for i=1,wildSumNum do
        wildNum = wildNum + 1
        local nowWildNum = wildNum
        local func = function(  )

                -- self.m_CollectAct_left:setVisible(true)
                -- self.m_CollectAct_left:runCsbAction("actionframe",false,function(  )
                --     self.m_CollectAct_left:setVisible(false)
                -- end)

                self.m_WildNumBar:runCsbAction("animation0")
                self.m_WildNumBar.m_sumNum = self.m_WildNumBar.m_sumNum + 1
                self.m_WildNumBar:findChild("BitmapFontLabel_1"):setString(self.m_WildNumBar.m_sumNum)
                self.m_WildNumBar:updateLabelSize({label=self.m_WildNumBar:findChild("BitmapFontLabel_1"),sx=1.3,sy=1.3},46)
                if nowWildNum == wildSumNum then
                    local index = nil
                    local ispplay = false
                    local times = 0
                    if self.m_runSpinResultData.p_fsExtraData then
                        if self.m_runSpinResultData.p_fsExtraData.wildLevel then
                            index = self.m_runSpinResultData.p_fsExtraData.wildLevel + 1

                            if self.WildLevel ~= index then
                                self.WildLevel = index
                                ispplay = true
                                times = 0.8
                            end

                        end
                    end
                    if index then

                        performWithDelay(self,function(  )
                            self.m_jackPorBar:showOneJPAction( index )
                        end,times)

                    end
                    if ispplay then


                        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")
                        self.m_jackPorBar.m_jpUpgradeView2:setVisible(true)
                        self.m_jackPorBar.m_jpUpgradeView2:runCsbAction("animation0",false,function(  )
                            self.m_jackPorBar.m_jpUpgradeView2:setVisible(false)
                        end)
                        self.m_jackPorBar.m_jpUpgradeView2:updateSpriteVisible( 6 - index)
                    end



                    performWithDelay(self,function(  )
                        if CallFunc then
                            CallFunc()
                        end

                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,1.5 + times)
                end
            end


        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_reels_stop1.mp3")

            func()
        end,(wildNum - 1)*(dealyTime ) )
    end



end

function CodeGameScreenDiscoFeverMachine:WILD_FLY_EFFECT( effectData,CallFunc)


    gLobalSoundManager:setBackgroundMusicVolume(0.4)

    local wildSumNum = self:getSymbolCountWithReelResult(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    local wildNum = 0

    local dealyTime = 0.5

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                if targSp.p_symbolType and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    wildNum = wildNum + 1

                    local startPosWord = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPosition()))
                    local startPos = cc.p(self.m_root:convertToNodeSpace(startPosWord))
                    local endPosWord = self:findChild("fsbar"):convertToWorldSpace(cc.p(self:findChild("left"):getPosition()))
                    local endPos = cc.p(self.m_root:convertToNodeSpace(endPosWord))
                    local nowWildNum = wildNum
                    local func = function(  )

                            self.m_CollectAct_left:setVisible(true)
                            self.m_CollectAct_left:runCsbAction("actionframe",false,function(  )
                                self.m_CollectAct_left:setVisible(false)
                            end)

                            self.m_WildNumBar.m_sumNum = self.m_WildNumBar.m_sumNum + 1
                            self.m_WildNumBar:findChild("BitmapFontLabel_1"):setString(self.m_WildNumBar.m_sumNum)
                            self.m_WildNumBar:updateLabelSize({label=self.m_WildNumBar:findChild("BitmapFontLabel_1"),sx=1.3,sy=1.3},46)
                            if nowWildNum == wildSumNum then
                                local index = nil
                                local ispplay = false
                                local times = 0
                                if self.m_runSpinResultData.p_fsExtraData then
                                    if self.m_runSpinResultData.p_fsExtraData.wildLevel then
                                        index = self.m_runSpinResultData.p_fsExtraData.wildLevel + 1
                                        if self.WildLevel ~= index then
                                            self.WildLevel = index
                                            ispplay = true
                                            times = 0.3
                                        end

                                    end
                                end
                                if index then

                                    performWithDelay(self,function(  )
                                        self.m_jackPorBar:showOneJPAction( index )
                                    end,times)

                                end
                                if ispplay then


                                    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")
                                    self.m_jackPorBar.m_jpUpgradeView2:setVisible(true)
                                    self.m_jackPorBar.m_jpUpgradeView2:runCsbAction("animation0",false,function(  )
                                        self.m_jackPorBar.m_jpUpgradeView2:setVisible(false)
                                    end)
                                    self.m_jackPorBar.m_jpUpgradeView2:updateSpriteVisible( 6 - index)
                                end



                                performWithDelay(self,function(  )
                                    if CallFunc then
                                        CallFunc()
                                    end

                                    gLobalSoundManager:setBackgroundMusicVolume(1)

                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end,1.5 + times)
                            end
                        end


                    performWithDelay(self,function(  )

                        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_collect_wild.mp3")

                        self:createCandyBingoFly( startPos ,endPos,dealyTime,true,func )
                    end,(wildNum - 1)*(dealyTime + 0.2) )

                end


            end
        end
    end




end

function CodeGameScreenDiscoFeverMachine:SCATTER_FLY_EFFECT(effectData ,CallFunc)


    gLobalSoundManager:setBackgroundMusicVolume(0.4)

    local fsMoreSumNum = self:getSymbolCountWithReelResult(self.SYMBOL_FREESPIN_MORE )
    local fsMoreNum = 0

    local dealyTime = 0.5

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                if targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FREESPIN_MORE then
                    fsMoreNum = fsMoreNum + 1

                    local startPosWord = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPosition()))
                    local startPos = cc.p(self.m_root:convertToNodeSpace(startPosWord))
                    local endPosWord = self:findChild("fsbar"):convertToWorldSpace(cc.p(self:findChild("right"):getPosition()))
                    local endPos = cc.p(self.m_root:convertToNodeSpace(endPosWord))
                    local nowWildNum = fsMoreNum
                    local func = function(  )

                        self.m_CollectAct_right:setVisible(true)
                        self.m_CollectAct_right:runCsbAction("actionframe",false,function(  )
                            self.m_CollectAct_right:setVisible(false)
                        end)

                        self.m_freespinTimesBar.m_freespinCurrtTimes = self.m_freespinTimesBar.m_freespinCurrtTimes + 1

                        self.m_freespinTimesBar:updateFreespinCount( self.m_freespinTimesBar.m_freespinCurrtTimes )

                        if nowWildNum == fsMoreSumNum then
                                performWithDelay(self,function(  )
                                    if CallFunc then
                                        CallFunc()
                                    end

                                    gLobalSoundManager:setBackgroundMusicVolume(1)

                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end,1)
                            end

                        end


                    performWithDelay(self,function(  )

                        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_collect_fsmore.mp3")

                        self:createCandyBingoFly( startPos ,endPos,dealyTime,false,func )

                    end,(fsMoreNum - 1)*(dealyTime + 0.2) )

                end


            end
        end
    end

end

function CodeGameScreenDiscoFeverMachine:JPUP_1_Bet_EFFECT(effectData ,CallFunc)


    if self.jackpotLevel >=  9 then
        if CallFunc then
            CallFunc()
        end
        effectData.p_isPlay = true
        self:playGameEffect()

        return
    end


    local func = function(  )
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")

        self.m_jackPorBar.m_jpUpgradeView:setVisible(true)
        self.m_jackPorBar.m_jpUpgradeView:runCsbAction("animation0",false,function(  )
            self.m_jackPorBar.m_jpUpgradeView:setVisible(false)
        end)

        performWithDelay(self,function(  )
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            if fsExtraData then
                if fsExtraData.jackpotLevel then
                    self.jackpotLevel = fsExtraData.jackpotLevel
                    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(fsExtraData.jackpotLevel)
                end
            end

            self:updataFSJackPotPool( )

            self.FS_JACKPOTBAR_ACT_INDEX = self.FS_JACKPOTBAR_ACT_INDEX + 1
            if self.FS_JACKPOTBAR_ACT_INDEX > 4 then
                self.FS_JACKPOTBAR_ACT_INDEX = 1
            end
            self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
        end,0.6)

        performWithDelay(self,function( )

            gLobalSoundManager:setBackgroundMusicVolume(1)

            if CallFunc then
                CallFunc()
            end
            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.5)


    end


    gLobalSoundManager:setBackgroundMusicVolume(0.1)

    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenLittleView.mp3")

    self.m_JPWinLittleView:setVisible(true)
    self.m_JPWinLittleView:runCsbAction("auto",false,function(  )
        self.m_JPWinLittleView:setVisible(false)
        func()
    end)





end


function CodeGameScreenDiscoFeverMachine:JPUP_1_EFFECT(effectData ,CallFunc)


    if self.jackpotLevel >=  9 then
        if CallFunc then
            CallFunc()
        end
        effectData.p_isPlay = true
        self:playGameEffect()

        return
    end


    local func = function(  )
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")

        self.m_jackPorBar.m_jpUpgradeView:setVisible(true)
        self.m_jackPorBar.m_jpUpgradeView:runCsbAction("animation0",false,function(  )
            self.m_jackPorBar.m_jpUpgradeView:setVisible(false)
        end)

        performWithDelay(self,function(  )
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            if fsExtraData then
                if fsExtraData.jackpotLevel then
                    self.jackpotLevel = fsExtraData.jackpotLevel
                    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(fsExtraData.jackpotLevel )
                end
            end

            self:updataFSJackPotPool( )

            self.FS_JACKPOTBAR_ACT_INDEX = self.FS_JACKPOTBAR_ACT_INDEX + 1
            if self.FS_JACKPOTBAR_ACT_INDEX > 4 then
                self.FS_JACKPOTBAR_ACT_INDEX = 1
            end
            self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
        end,0.6)

        performWithDelay(self,function( )

            gLobalSoundManager:setBackgroundMusicVolume(1)

            if CallFunc then
                CallFunc()
            end
            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.5)


    end





    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                if targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_JACKPOT_UP_1 then

                    self:createOneActionSymbol(targSp,"actionframe",true)
                    gLobalSoundManager:setBackgroundMusicVolume(0.1)

                    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_JPUp_zhongjang.mp3")

                    targSp:runAnim("actionframe",false,function(  )



                        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenLittleView.mp3")

                        self.m_JPWinLittleView:setVisible(true)
                        self.m_JPWinLittleView:runCsbAction("auto",false,function(  )
                            self.m_JPWinLittleView:setVisible(false)
                            func()
                        end)

                        targSp:runAnim("idleframe",true)
                    end)

                end

            end

        end

    end




end

function CodeGameScreenDiscoFeverMachine:JPUP_2_Bet_EFFECT(effectData,CallFunc )

    if self.jackpotLevel >=  9 then

        if CallFunc then
            CallFunc()
        end
        effectData.p_isPlay = true
        self:playGameEffect()

        return
    end


    local func2 = function(  )
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")
        self.m_jackPorBar.m_jpUpgradeView:setVisible(true)
        self.m_jackPorBar.m_jpUpgradeView:runCsbAction("animation0",false,function(  )
            self.m_jackPorBar.m_jpUpgradeView:setVisible(false)
        end)

        performWithDelay(self,function(  )
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            if fsExtraData then
                if fsExtraData.jackpotLevel then
                    self.jackpotLevel = fsExtraData.jackpotLevel
                    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(fsExtraData.jackpotLevel )
                end
            end

            self.FS_JACKPOTBAR_ACT_INDEX = self.FS_JACKPOTBAR_ACT_INDEX + 1
            if self.FS_JACKPOTBAR_ACT_INDEX > 4 then
                self.FS_JACKPOTBAR_ACT_INDEX = 1
            end
            self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)

            self:updataFSJackPotPool( )
        end,0.6)



        performWithDelay(self,function( )
            gLobalSoundManager:setBackgroundMusicVolume(1)

            if CallFunc then
                CallFunc()
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.5)

    end

    local func = function(  )
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")
        self.m_jackPorBar.m_jpUpgradeView:setVisible(true)
        self.m_jackPorBar.m_jpUpgradeView:runCsbAction("animation0",false,function(  )
            self.m_jackPorBar.m_jpUpgradeView:setVisible(false)
        end)

        performWithDelay(self,function(  )
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            if fsExtraData then
                if fsExtraData.jackpotLevel then
                    self.jackpotLevel = fsExtraData.jackpotLevel - 1
                    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(fsExtraData.jackpotLevel - 1 )
                end
            end

            self.FS_JACKPOTBAR_ACT_INDEX = self.FS_JACKPOTBAR_ACT_INDEX + 1
            if self.FS_JACKPOTBAR_ACT_INDEX > 4 then
                self.FS_JACKPOTBAR_ACT_INDEX = 1
            end
            self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)

            self:updataLastTimesFSJackPotPool( )
        end,0.6)



        performWithDelay(self,function( )

            gLobalSoundManager:setBackgroundMusicVolume(0.1)

            gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenLittleView.mp3")
            self.m_JPWinLittleView:setVisible(true)
            self.m_JPWinLittleView:runCsbAction("auto",false,function(  )
                self.m_JPWinLittleView:setVisible(false)
                func2()
            end)

        end,2.5)
    end


    gLobalSoundManager:setBackgroundMusicVolume(0.1)
    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenLittleView.mp3")
    self.m_JPWinLittleView:setVisible(true)
    self.m_JPWinLittleView:runCsbAction("auto",false,function(  )
        self.m_JPWinLittleView:setVisible(false)
        func()
    end)

end

function CodeGameScreenDiscoFeverMachine:JPUP_2_EFFECT(effectData,CallFunc )

    if self.jackpotLevel >=  9 then

        if CallFunc then
            CallFunc()
        end
        effectData.p_isPlay = true
        self:playGameEffect()

        return
    end


    local func2 = function(  )
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")
        self.m_jackPorBar.m_jpUpgradeView:setVisible(true)
        self.m_jackPorBar.m_jpUpgradeView:runCsbAction("animation0",false,function(  )
            self.m_jackPorBar.m_jpUpgradeView:setVisible(false)
        end)

        performWithDelay(self,function(  )
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            if fsExtraData then
                if fsExtraData.jackpotLevel then
                    self.jackpotLevel = fsExtraData.jackpotLevel
                    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(fsExtraData.jackpotLevel )
                end
            end

            self.FS_JACKPOTBAR_ACT_INDEX = self.FS_JACKPOTBAR_ACT_INDEX + 1
            if self.FS_JACKPOTBAR_ACT_INDEX > 4 then
                self.FS_JACKPOTBAR_ACT_INDEX = 1
            end
            self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)

            self:updataFSJackPotPool( )
        end,0.6)



        performWithDelay(self,function( )
            gLobalSoundManager:setBackgroundMusicVolume(1)

            if CallFunc then
                CallFunc()
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.5)

    end

    local func = function(  )
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_jp_shengji.mp3")
        self.m_jackPorBar.m_jpUpgradeView:setVisible(true)
        self.m_jackPorBar.m_jpUpgradeView:runCsbAction("animation0",false,function(  )
            self.m_jackPorBar.m_jpUpgradeView:setVisible(false)
        end)

        performWithDelay(self,function(  )
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            if fsExtraData then
                if fsExtraData.jackpotLevel then
                    self.jackpotLevel = fsExtraData.jackpotLevel -1
                    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setString(fsExtraData.jackpotLevel-1 )
                end
            end

            self.FS_JACKPOTBAR_ACT_INDEX = self.FS_JACKPOTBAR_ACT_INDEX + 1
            if self.FS_JACKPOTBAR_ACT_INDEX > 4 then
                self.FS_JACKPOTBAR_ACT_INDEX = 1
            end
            self:changeGameBg(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_jackPorBar:changeFsJPAction(self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_jackPorBar:updateMusicalSpine(self.FS_JACKPOTBAR_ACT_INDEX )
            self.m_freespinTimesBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)
            self.m_WildNumBar:changeImg( self.FS_JACKPOTBAR_ACT_INDEX)

            self:updataLastTimesFSJackPotPool( )
        end,0.6)



        performWithDelay(self,function( )

            gLobalSoundManager:setBackgroundMusicVolume(0.1)

            gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenLittleView.mp3")
            self.m_JPWinLittleView:setVisible(true)
            self.m_JPWinLittleView:runCsbAction("auto",false,function(  )
                self.m_JPWinLittleView:setVisible(false)
                func2()
            end)

        end,2.5)
    end

    self:runUpDoubleSymbol(function(  )
        func()
    end )




end

function CodeGameScreenDiscoFeverMachine:runUpDoubleSymbol( func)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                if targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_JACKPOT_UP_2 then
                    self:createOneActionSymbol(targSp,"actionframe",true)

                    gLobalSoundManager:setBackgroundMusicVolume(0.1)

                    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_JPUp_zhongjang.mp3")

                    targSp:runAnim("actionframe",false,function(  )



                        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_OpenLittleView.mp3")
                        self.m_JPWinLittleView:setVisible(true)
                        self.m_JPWinLittleView:runCsbAction("auto",false,function(  )
                            self.m_JPWinLittleView:setVisible(false)
                            func()
                        end)

                        targSp:runAnim("idleframe",true)
                    end)
                end

            end

        end

    end
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenDiscoFeverMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end


function CodeGameScreenDiscoFeverMachine:createWheelView(callfunc )

    local data = {}
    data.m_endIndex =   3
    data.m_wheelData = {1,2,3,4,5,6,7,8,9,10,11,0}
    data.m_wheelDataExtra = {}
    data.m_betlevel = self:getBetLevel()
    data.m_machine = self

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData then
        if fsExtraData.wheel then
            data.m_wheelData = fsExtraData.wheel
        end

        if fsExtraData.select then
            data.m_endIndex  =  fsExtraData.select
        end

        if fsExtraData.wheelExtra then
            data.m_wheelDataExtra = fsExtraData.wheelExtra
        end
    end

    self:findChild("wheel"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self.m_wheel =  util_createView("CodeDiscoFeverSrc.DiscoFeverWheelView",data)
    self:findChild("wheel"):addChild(self.m_wheel)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_wheel.getRotateBackScaleFlag = function(  ) return false end
    end


    self.m_wheel:runCsbAction("idle")
    self.m_wheel:initCallBack(function(  )

        if callfunc then
            callfunc()
        end

    end)
    self.m_wheel:setVisible(false)

    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_GuoChang.mp3")
    self.m_GuoChangView:setVisible(true)
    self.m_GuoChangView:runCsbAction("guochangdonghua",false,function(  )
        self.m_GuoChangView:setVisible(false)
    end)
    performWithDelay(self,function(  )

        self:resetMusicBg(nil,"DiscoFeverSounds/DiscoFever_WheelBG.mp3")

        self.m_wheel:setVisible(true)
    end,21/30)


end

function CodeGameScreenDiscoFeverMachine:updataLastTimesFSJackPotPool( )
    self.FS_JACKPOT_POOL = {}

    local fsExtraData =  self.m_runSpinResultData.p_fsExtraData
    if fsExtraData then
        local jackpot = fsExtraData.lastJackpot
        if jackpot then
           for k,v in pairs(jackpot) do
               table.insert( self.FS_JACKPOT_POOL, v )
           end

        end
    end

end

function CodeGameScreenDiscoFeverMachine:updataFSJackPotPool( )
    self.FS_JACKPOT_POOL = {}

    local fsExtraData =  self.m_runSpinResultData.p_fsExtraData
    if fsExtraData then
        local jackpot = fsExtraData.jackpot
        if jackpot then
           for k,v in pairs(jackpot) do
               table.insert( self.FS_JACKPOT_POOL, v )
           end

        end
    end

end

function CodeGameScreenDiscoFeverMachine:updataFSJackPotPoolToNormal( )
    self.FS_JACKPOT_POOL = {}
    for index = 5,1,-1 do
        local  totalBet=globalData.slotRunData:getCurTotalBet()
        local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
        local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index],true,totalBet)
        table.insert( self.FS_JACKPOT_POOL, baseScore )
    end

end

function CodeGameScreenDiscoFeverMachine:getNetJackpotScore(index,totalBet)
    if not totalBet then
        totalBet=globalData.slotRunData:getCurTotalBet()
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return 0
    end
    local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index],true,totalBet)

    local currtScore = totalScore - baseScore
    local netbaseFSJackPotScore = 0
    if #self.FS_JACKPOT_POOL >= 5 then
        netbaseFSJackPotScore = self.FS_JACKPOT_POOL[6 - index]
    end



    local fsJackPotScore = currtScore + netbaseFSJackPotScore

    return fsJackPotScore
end

function CodeGameScreenDiscoFeverMachine:checkJpBarIsJump(index)
    local isjump = true


    return isjump
end


--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenDiscoFeverMachine:getReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenDiscoFeverMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end


-- 创建飞行粒子
function CodeGameScreenDiscoFeverMachine:createCandyBingoFly( startPos ,endPos,time,isWild,func )

    local csbName = "DiscoFever_freespin_shouji"
    if isWild then
        csbName = "DiscoFever_wild_shouji"
    end
    local fly =  util_createView("CodeDiscoFeverSrc.DiscoFeveParticleFly",csbName)
    fly:setPosition(startPos)
    -- fly:setScale(1.5)
    self.m_root:addChild(fly,300000)
    fly:findChild("Particle_1"):setDuration(time)
    fly:runCsbAction("actionframe")

    local animation = {}

    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos))
    animation[#animation + 1] = cc.CallFunc:create(function(  )

            if func then
                func()
            end
            fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))



end

function CodeGameScreenDiscoFeverMachine:updatejackPotLevelUI(state )
    self.m_jackPorBar:findChild("DiscoFever_fs_diban_1"):setVisible(state)
    self.m_jackPorBar:findChild("DiscoFever_level_98"):setVisible(state)
    self.m_jackPorBar:findChild("BitmapFontLabel_21"):setVisible(state)
end




---
--设置bonus scatter 层级
function CodeGameScreenDiscoFeverMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1000
    elseif symbolType ==  self.SYMBOL_FREESPIN_MORE then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType ==  self.SYMBOL_JACKPOT_UP_1 or
        symbolType ==  self.SYMBOL_JACKPOT_UP_2 then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 2000
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 -- + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    print("order = "..order.."   symbolType = "..symbolType)
    return  order

end

function CodeGameScreenDiscoFeverMachine:changeMachineGameBg(index )
    local actName = "DiscoFever_bg"
    local normalName = "DiscoFever_bg"
    local showIndex = index

    --self.m_gameBg:runCsbAction("hide",false,function(  )

        for i=1,4 do
            self:findChild(actName..i):setVisible(false)
        end
        self:findChild(normalName):setVisible(false)

        if showIndex then
            self:findChild(actName..showIndex):setVisible(true)
        else
            self:findChild(normalName):setVisible(true)
        end
        if self.m_showIndex ~= index then
            self:runCsbAction("show",false)
        end
    --end)

end

function CodeGameScreenDiscoFeverMachine:changeGameBg(index )

    if index == nil then
        self.m_BgActionView:showOneAction( 0)
    else
        self.m_BgActionView:showOneAction( index)
    end



    self:changeMachineGameBg(index )

    local actName = "DiscoFever_bg"
    local normalName = "DiscoFever_bg"
    local showIndex = index

    --self.m_gameBg:runCsbAction("hide",false,function(  )

        for i=1,4 do
            self.m_gameBg:findChild(actName..i):setVisible(false)
        end
        self.m_gameBg:findChild(normalName):setVisible(false)

        if showIndex then
            self.m_gameBg:findChild(actName..showIndex):setVisible(true)
        else
            self.m_gameBg:findChild(normalName):setVisible(true)
        end

        if self.m_showIndex ~= index then
            self.m_gameBg:runCsbAction("show",false)
        end
        self.m_showIndex = index
    --end)

end

function CodeGameScreenDiscoFeverMachine:dealWildLevelNumNode( states)
    for i=1,4 do
        local name = "Score"..i
        local node =  self:findChild(name)
        if node then
            node:setVisible(states)
        end
    end
end



---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenDiscoFeverMachine:initCloumnSlotNodesByNetData()

    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do

        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do

            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1;
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP  = true
                end
                for checkRowIndex = changeRowIndex + 1,rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if  checkIndex == rowNum then
                                -- body
                                isUP  = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break;
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)

            -- parentData.slotParent:addChild(node,
            --     REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder)
                node:setVisible(true)
            end

            node.p_symbolType = symbolType
--            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH )

            -- if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_WILD  then
            --     node:runAnim("idleframe2",true)
            -- else
                node:runIdleAnim()
            -- end

            rowIndex = rowIndex - stepCount
        end  -- end while

    end

end

function CodeGameScreenDiscoFeverMachine:randomSlotNodes( )
    BaseSlotoManiaMachine.randomSlotNodes(self)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                targSp:runIdleAnim()
            end
        end
    end



end


function CodeGameScreenDiscoFeverMachine:randomSlotNodesByReel( )
    BaseSlotoManiaMachine.randomSlotNodesByReel(self)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                targSp:runIdleAnim()
            end
        end
    end

end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenDiscoFeverMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = #lineValue.vecValidMatrixSymPos

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent

        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)

                        break
                    end
                end

            end
        end

        if slotNode ~= nil then--这里有空的没有管

            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = 2 --util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenDiscoFeverMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        performWithDelay(self,function(  )
            self:resetMaskLayerNodes()
        end,0.5)

        callFun()
    end,animTime,self:getModuleName())
end

function CodeGameScreenDiscoFeverMachine:createOneActionSymbol(endNode,actionName,isSpine)
    if not endNode or not endNode.m_ccbName  then
          return
    end

    local fatherNode = endNode
    endNode:setVisible(false)

    local node= nil
    if isSpine then
        node = util_spineCreate(endNode.m_ccbName,true,true)
    else
        node = util_createAnimation(endNode.m_ccbName..".csb")
    end

    local func = function(  )
          if fatherNode then
                fatherNode:setVisible(true)
          end
          if node then
                node:setVisible(false)
                performWithDelay(self,function(  )
                    node:removeFromParent()
                end,0.01)

          end

    end

    if isSpine then
        util_spinePlay(node,actionName)
        util_spineEndCallFunc(node, actionName, func)

    else
        node:playAction(actionName,false,func)
    end


    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("root"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("root"):addChild(node , 1000 + endNode.p_rowIndex)
    node:setPosition(pos)

    return node
end
function CodeGameScreenDiscoFeverMachine:checkWinLinesIcons(posIndex )
    local isIn = false
    local winLines =  self.m_runSpinResultData.p_winLines
    if winLines and type(winLines) == "table" then
        for k,v in pairs(winLines) do
            local line = v
            if line.p_iconPos then
                for i,j in ipairs(line.p_iconPos) do
                    if j == posIndex then

                        isIn = true

                        return isIn
                    end
                end
            end

        end
    end


    return isIn
end

function CodeGameScreenDiscoFeverMachine:setSlotsNodeDark( )
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local childs = slotParent:getChildren()

        for k,v in pairs(childs) do
            local symbolNode = v
            if symbolNode:getTag() == -1 then
                v:runAnim("DarkAct")
            end
        end

    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do

            local iconsPos = self:getPosReelIdx(iRow, iCol)
            if not self:checkWinLinesIcons(iconsPos ) then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp  then
                    targSp:runAnim("DarkAct")

                end
            end


        end

    end
end

function CodeGameScreenDiscoFeverMachine:showLineFrame( )
    BaseMachineGameEffect.showLineFrame(self)

    if not self:getFreatureIsFreeSpin() then
        self:setSlotsNodeDark( )
    end

end

function CodeGameScreenDiscoFeverMachine:getFreatureIsFreeSpin()
    if self.m_runSpinResultData then
        if self.m_runSpinResultData.p_features then
            local freature = self.m_runSpinResultData.p_features

            if freature[1] and freature[1] == 0 then
                if freature[2] and freature[2] == 1 then
                    return true
                end
            end
        end
    end

    return false
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenDiscoFeverMachine:specialSymbolActionTreatment( node)
    if not node then
        return
    end

    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        self:beginEnlarge()
        node:runAnim("buling",false,function(  )

            node:runAnim("idleframe",true)

        end)
    end
end

function CodeGameScreenDiscoFeverMachine:beginEnlarge( )

    for k,v in pairs(self.m_scaleChild) do
        local node = v
        local oldScale = self.m_scaleChildOldScaleList[k]
        self:enlargeOneNode(oldScale,node)
    end
end

function CodeGameScreenDiscoFeverMachine:enlargeOneNode(oldScale,node )

    local actionList2={}
    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )

    end)
    actionList2[#actionList2+1]=cc.ScaleTo:create(0.1,oldScale + 0.02)
    actionList2[#actionList2+1]=cc.ScaleTo:create(0.05,oldScale )
    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )

    end)

    local seq2=cc.Sequence:create(actionList2)
    node:runAction(seq2)
end

function CodeGameScreenDiscoFeverMachine:beginShake( )
    local oldPos = cc.p(self:getPosition())

   self:shakeOneNodeForever( oldPos ,self,function(  )
    end)
end

function CodeGameScreenDiscoFeverMachine:shakeOneNodeForever( oldPos ,node,func)

    local changePosY = 1
    local actionList2={}
    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )

        if func then
            func()
        end
        changePosY = 1.5 --math.random( 3,3 )
    end)
    actionList2[#actionList2+1]=cc.MoveTo:create(0.07,cc.p(oldPos.x,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.07,cc.p(oldPos.x,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    node:runAction(cc.RepeatForever:create(seq2))
end


function CodeGameScreenDiscoFeverMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local waitTime = 0
    local selfMakeData =  self.m_runSpinResultData.p_selfMakeData
    if selfMakeData then
        local  wildColumn = selfMakeData.wildColumn
        if wildColumn and #wildColumn > 0 then

            gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_col_showWIld.mp3")

            for k,v in pairs(wildColumn) do
                local col = v + 1
                local pos = self:getNodePosByColAndRow(1, col)
                local wildChange = util_createView("CodeDiscoFeverSrc.DiscoFeverWildChangeView")
                self.m_WildActNode:addChild(wildChange,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
                wildChange:setPosition(pos)
                wildChange:runCsbAction("start",false,function(  )
                    wildChange:runCsbAction("idle",true)
                end,20)

                self.m_wildChangeList[col] = wildChange

            end

            waitTime = 0.5
        end

   end

   performWithDelay(self,function(  )
        if not self.m_isWaitChangeReel then
            self.m_isWaitChangeReel=true
            self:produceSlots()
            --存在等待时间延后调用下面代码
            if self.m_waitChangeReelTime and self.m_waitChangeReelTime>0 then
                scheduler.performWithDelayGlobal(function()
                    self.m_waitChangeReelTime=nil
                    self:updateNetWorkData()
                end, self.m_waitChangeReelTime,self:getModuleName())
                return
            end
        end

        self.m_isWaitChangeReel=nil
        self.m_isWaitingNetworkData = false

        self:operaNetWorkData()
   end,waitTime)

end


---
-- 根据类型获取对应节点
--
function CodeGameScreenDiscoFeverMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
        
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    reelNode:setMachine(self )
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

function CodeGameScreenDiscoFeverMachine:getBaseReelGridNode()
    return "CodeDiscoFeverSrc.DiscoFeverSlotsNode"
end


function CodeGameScreenDiscoFeverMachine:restSlotParentZOrder( )
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent:getParent()
        slotParent:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    end
end

function CodeGameScreenDiscoFeverMachine:changeSlotParentZOrderOutLine( )

    local Zorder= {1,2}

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent:getParent()

        for k = 1, self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(i, k, SYMBOL_NODE_TAG)
            if symbolNode then
                local symbolType =  symbolNode.p_symbolType

                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    slotParent:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + Zorder[1])
                end

                if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
                    symbolType ==  self.SYMBOL_FREESPIN_MORE or
                    symbolType ==  self.SYMBOL_JACKPOT_UP_1 or
                    symbolType ==  self.SYMBOL_JACKPOT_UP_2 then

                    slotParent:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + Zorder[2])
                end

            end


        end
    end
end

function CodeGameScreenDiscoFeverMachine:changeSlotParentZOrder( )

    self:restSlotParentZOrder( )

    local Zorder= {1,2}

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent:getParent()

        for k = 1, self.m_iReelRowNum do

            local symbolType =  self.m_stcValidSymbolMatrix[k][i]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                slotParent:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + Zorder[1])
            end

            if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
                symbolType ==  self.SYMBOL_FREESPIN_MORE or
                symbolType ==  self.SYMBOL_JACKPOT_UP_1 or
                symbolType ==  self.SYMBOL_JACKPOT_UP_2 then

                slotParent:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + Zorder[2])
            end

        end
    end
end

----------------  betlevel

function CodeGameScreenDiscoFeverMachine:getBetLevel( )
    return self.m_betLevel
end


function CodeGameScreenDiscoFeverMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
    self:getCurrSpinMode() ~= RESPIN_MODE
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,data=self.m_collectDataList,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( ) }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)


end


function CodeGameScreenDiscoFeverMachine:updatJackPotLock( minBet )
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1

            gLobalSoundManager:playSound("DiscoFeverSounds/sound_DiscoFever_unlock.mp3")

            self.m_BetLogoView:runCsbAction("unlock",false,function(  )
                if self.m_betLevel == 1 then
                    self.m_BetLogoView:runCsbAction("idle",true)
                end

            end)

        end
    else


        if self.m_betLevel == nil or self.m_betLevel == 1 then

            local betLogoLab = self.m_BetLogoView:findChild("bet_shuzi")
            if betLogoLab then
                betLogoLab:setString(util_formatCoins(minBet,6))
                self.m_BetLogoView:updateLabelSize({label=betLogoLab,sx=0.47,sy=0.47},237)
            end

            self.m_betLevel = 0
            self.m_BetLogoView:runCsbAction("lock",true)

        end

    end






end

function CodeGameScreenDiscoFeverMachine:getMinBet( )
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
function CodeGameScreenDiscoFeverMachine:upateBetLevel()

    local minBet = self:getMinBet( )

    self:updatJackPotLock( minBet )
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenDiscoFeverMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()

    end

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenDiscoFeverMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end


--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenDiscoFeverMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("CodeDiscoFeverSrc.DiscoFeverDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
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


function CodeGameScreenDiscoFeverMachine:scheduleSetMusciVolume(time )


    if self.m_soundVolumeId ~= nil then
        scheduler.unscheduleGlobal(self.m_soundVolumeId)
        self.m_soundVolumeId = nil
        print("ting -----")
    end


    local volume = 1
    local cutNum = volume / (time / 0.1)
    self.m_soundVolumeId =  scheduler.scheduleGlobal( function()

        if volume <= 0 then
            volume = 0
        end
        print("jakjaksjkd   -----")
        gLobalSoundManager:setBackgroundMusicVolume(volume)

        if volume <= 0 then
            if self.m_soundVolumeId ~= nil then
                scheduler.unscheduleGlobal(self.m_soundVolumeId)
                self.m_soundVolumeId = nil
                print("ting -----")
            end


            print("没听   -----")

        end

        volume = volume - cutNum


    end, 0.1)
end


function CodeGameScreenDiscoFeverMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end

    self:scheduleSetMusciVolume(1.5 )

    performWithDelay(self,function(  )

        if self.m_soundVolumeId ~= nil then
            scheduler.unscheduleGlobal(self.m_soundVolumeId)
            self.m_soundVolumeId = nil
            print("ting -----")
        end

        gLobalSoundManager:setBackgroundMusicVolume(1)
        self:checkFeatureOverTriggerBigWin( globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearFrames_Fun()
        -- 重置连线信息
        -- self:resetMaskLayerNodes()
        self:clearCurMusicBg()
        self:showFreeSpinOverView()
    end,2)


end

function CodeGameScreenDiscoFeverMachine:isShowChooseBetOnEnter()
    return self:checkShowChooseBetView()
end


return CodeGameScreenDiscoFeverMachine






