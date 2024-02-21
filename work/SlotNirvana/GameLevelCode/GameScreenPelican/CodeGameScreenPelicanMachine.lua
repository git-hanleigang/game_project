---
-- island li
-- 2019年1月26日
-- CodeGameScreenPelicanMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenPelicanMachine = class("CodeGameScreenPelicanMachine", BaseNewReelMachine)
-- local BaseDialog = class("BaseDialog", util_require("base.BaseView"))

local selectRespinId = 1
local selectFreeSpinId = 2

CodeGameScreenPelicanMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenPelicanMachine.m_chooseRepinNotCollect = false

CodeGameScreenPelicanMachine.EFFECT_FISH_SWIMMING  =   GameEffect.EFFECT_LINE_FRAME + 3     --金鱼游动

CodeGameScreenPelicanMachine.SYMBOL_FIX_ALL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14--107
CodeGameScreenPelicanMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13--106
CodeGameScreenPelicanMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 -- 105
CodeGameScreenPelicanMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 --104
CodeGameScreenPelicanMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 --103
CodeGameScreenPelicanMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  --94
CodeGameScreenPelicanMachine.SYMBOL_BLANCK = 100  --空信号

CodeGameScreenPelicanMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 51 -- 收集
CodeGameScreenPelicanMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- 集满bonus

CodeGameScreenPelicanMachine.m_chipList = nil
CodeGameScreenPelicanMachine.m_playAnimIndex = 0
CodeGameScreenPelicanMachine.m_lightScore = 0

CodeGameScreenPelicanMachine.m_triggerRespinRevive = nil --触发额外增加次数
CodeGameScreenPelicanMachine.m_isShowRespinChoice = nil--是否显示额外弹窗
CodeGameScreenPelicanMachine.m_isPlayCollect = nil  --是否正在播放收集动画
CodeGameScreenPelicanMachine.m_triggerAllSymbol = nil  --是否触发 金辣椒
CodeGameScreenPelicanMachine.m_aimAllSymbolNodeList = {} --金辣椒列表
CodeGameScreenPelicanMachine.m_flyCoinsTime = 0.3
CodeGameScreenPelicanMachine.m_reconnect = nil
CodeGameScreenPelicanMachine.m_isRespinReelDown = false

CodeGameScreenPelicanMachine.m_base = 0
CodeGameScreenPelicanMachine.m_3RowFree = 1
CodeGameScreenPelicanMachine.m_4RowFree = 2
CodeGameScreenPelicanMachine.m_respin = 3

CodeGameScreenPelicanMachine.m_collectList = {}
CodeGameScreenPelicanMachine.m_bonusData = {}

CodeGameScreenPelicanMachine.m_bCanClickMap = nil
CodeGameScreenPelicanMachine.m_bSlotRunning = nil

CodeGameScreenPelicanMachine.m_iReelMinRow = 3
CodeGameScreenPelicanMachine.m_iReelMaxRow = 4

CodeGameScreenPelicanMachine.MAXROW_REEL_SCALE = 0.87
CodeGameScreenPelicanMachine.MAXROW_REEL_POS_Y = -40

CodeGameScreenPelicanMachine.MAIN_REEL_ADD_POS_Y = 10

CodeGameScreenPelicanMachine.BASE_FS_RUN_STATES = 0
CodeGameScreenPelicanMachine.COllECT_FS_RUN_STATES = 1

CodeGameScreenPelicanMachine.m_superFreeSpinStart = false

local runStatus = {
    DUANG = 1,
    NORUN = 2
}

-- 构造函数
function CodeGameScreenPelicanMachine:ctor()
    CodeGameScreenPelicanMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_chooseRepin = false
    self.m_chooseRepinNotCollect = false

    self.m_aimAllSymbolNodeList = {}
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_bJackpotHeight = false

    self.m_base = 0
    self.m_3RowFree = 1
    self.m_4RowFree = 2
    self.m_respin = 3
 
    self.m_collectList = {}
    self.m_bonusData = {}

    self.m_bCanClickMap = nil
    self.m_bSlotRunning = nil

    self.m_superFreeSpinStart = false

    self.isShowRespinStartView = true

    self.m_betTotalCoins = 0

    self.m_betLevel = nil

    self.upPeopleList = {}

    self.m_playWinningNotice = false

    self.m_isBonusTrigger = false

    --init
    self:initGame()
end


function CodeGameScreenPelicanMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("PelicanConfig.csv", "LevelPelicanConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end  

---
-- 进入关卡
--
function CodeGameScreenPelicanMachine:enterLevel()
    
    self.m_reconnect = true
    
    CodeGameScreenPelicanMachine.super.enterLevel(self)

    --显示提示
    self:delayCallBack(0.3,function (  )
        if self:isNormalStates() then
            self.collectTipView:setVisible(true)
            self.collectTipView.m_states = "show"
            
            self.collectTipView:runCsbAction("show",false,function(  )
                self.collectTipView.m_states = "idle"
                self.collectTipView:runCsbAction("idle")
                self.tipsWaitNode:stopAllActions()
                performWithDelay(self.tipsWaitNode,function(  )
                    self.collectTipView:runCsbAction("over",false,function (  )
                        self.collectTipView.m_states = "idle"
                        self.collectTipView:setVisible(false)
                    end)
                end,5)
            end)
        end
    end)
end

function CodeGameScreenPelicanMachine:requestSpinResult(spinType,selectIndex)

    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount-1,self.m_runSpinResultData.p_reSpinsTotalCount)
    end
    
    self.m_reconnect = false
    self.m_isRespinReelDown = false
    self.m_iBetLevel = self:getBetLevel()
    CodeGameScreenPelicanMachine.super.requestSpinResult(self,spinType,selectIndex)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPelicanMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Pelican"  
end

function CodeGameScreenPelicanMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local winCoinPos = coinLab:getParent():convertToWorldSpace(cc.p(coinLab:getPosition()))
    self.m_downPosY = winCoinPos.y
    local node_showTips = self.m_topUI:findChild("node_showTips")
    local node_showTipsPos = node_showTips:getParent():convertToWorldSpace(cc.p(node_showTips:getPosition()))
    self.m_topPosY = node_showTipsPos.y
    
    self.m_3RowFreeSpinBar = util_createView("CodePelicanSrc.PelicanFreespinBarView")
    self:findChild("freespinbar"):addChild(self.m_3RowFreeSpinBar)
    self.m_3RowFreeSpinBar:setVisible(false)
    -- jackpot
    self.m_jackpotView = util_createView("CodePelicanSrc.PelicanJackPotBarView","Pelican_Jackpot")
    self:findChild("jackpot"):addChild(self.m_jackpotView)
    self.m_jackpotView:initMachine(self)

    self.m_RsjackpotView = util_createView("CodePelicanSrc.PelicanJackPotBarView","Pelican_Jackpot_Rs")
    self:findChild("jackpot"):addChild(self.m_RsjackpotView)
    
    self.m_RsjackpotView:initMachine(self)
    self.m_RsjackpotView:setVisible(false)

    -- m_reSpinbar
    self.m_reSpinbar = util_createView("CodePelicanSrc.respin.PelicanReSpinBar",self)
    self:findChild("respinBar"):addChild(self.m_reSpinbar)
    self.m_reSpinbar:setVisible(false)

    self.m_reSpinPrize = util_createView("CodePelicanSrc.respin.PelicanRespinPrize",self)
    self:findChild("Node_Respin_Prize"):addChild(self.m_reSpinPrize)
    self.m_reSpinPrize:setVisible(false)
    
    self:changeMainUi(self.m_base )
   
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    self.m_progress = util_createView("CodePelicanSrc.PelicanBonusProgress")
    self:findChild("Node_loadingbar"):addChild(self.m_progress)

    self.m_spineTanbanParent = cc.Node:create()
    self.m_spineTanbanParent:setOpacity(0)
    self:addChild(self.m_spineTanbanParent, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_spineTanbanParent:setPosition(display.center)

    self.m_FsLockWildNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_FsLockWildNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    
    self.upPeople = util_spineCreate("Pelican_juese1",true,true)
    self:findChild("player_node"):addChild(self.upPeople)
    util_spinePlay(self.upPeople,"idleframe",true)
    table.insert(self.upPeopleList,self.upPeople)
    self.upPeople2 = util_spineCreate("Pelican_juese2",true,true)
    self:findChild("player_node"):addChild(self.upPeople2)
    self.upPeople2:setVisible(false)
    table.insert(self.upPeopleList,self.upPeople2)

    -- local BottomNode_bar = self.m_bottomUI:findChild("font_last_win_value")
    -- self.m_jiesuanAct = util_createAnimation("Pelican_Totalwin.csb")
    -- local bottomNodePos = util_convertToNodeSpace(BottomNode_bar,self)
    -- self:addChild(self.m_jiesuanAct,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    -- self.m_jiesuanAct:setPosition(bottomNodePos)
    -- self.m_jiesuanAct:setVisible(false)

    self.yuGaoView = util_createView("CodePelicanSrc.PelicanYuGaoView")  --jackpot
    self:findChild("Node_yugao"):addChild(self.yuGaoView)
    self.yuGaoView:setVisible(false)

    self.collectTipView = util_createView("CodePelicanSrc.PelicanTipsView")      --提示按钮
    self.m_clipParent:addChild(self.collectTipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.collectTipView.m_states = nil
    local collectTipViewWorldPos = self.m_progress:findChild("Node_tips"):getParent():convertToWorldSpace(cc.p(self.m_progress:findChild("Node_tips"):getPosition()))
    local collectTipViewPos = self.m_clipParent:convertToNodeSpace(collectTipViewWorldPos)
    
    self.collectTipView:setPosition(collectTipViewPos)
    self.collectTipView:setVisible(false)

    --spine背景
    self.bg1 = util_spineCreate("GameScreenPelicanBg",true,true)
    self:findChild("bg"):addChild(self.bg1,10000)
    self.bg2 = util_spineCreate("GameScreenPelicanBg2",true,true)
    self:findChild("bg"):addChild(self.bg2,10001)
    util_spinePlay(self.bg1,"idleframe",true)
    self.bg2:setVisible(false)

    self.dark = util_createView("CodePelicanSrc.PelicanDarkView")
    self.m_spineTanbanParent:addChild(self.dark,100)
    self.dark:setVisible(false)

    self.tipsWaitNode = cc.Node:create()
    self:addChild(self.tipsWaitNode)

    --进度条上的船和地图人
    self.loadingMap = util_createView("CodePelicanSrc.PelicanLoadfingMapView")
    self:findChild("Node_loadingbar_map"):addChild(self.loadingMap)
    self.loadingIcon = util_createView("CodePelicanSrc.PelicanLoadingIconView")
    self:findChild("Node_loadingbar_icon"):addChild(self.loadingIcon)

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
            soundIndex = 4
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end
        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "PelicanSounds/music_Pelican_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "PelicanSounds/music_Pelican_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            self.m_winSoundsId = nil
        end)
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenPelicanMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "PelicanSounds/music_Pelican_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenPelicanMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenPelicanMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local pecent =  self:getProgressPecent(true)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusMode = selfData.bonusMode 
    if bonusMode then
        if bonusMode == "collect" then
            pecent = 0 -- 完成pick小游戏断线 重置为 0 
        end
    end
    self.m_progress:setPercent(pecent)
    self:createMapScroll( )

    local totalBet = globalData.slotRunData:getCurTotalBet( )
    self.m_betTotalCoins = totalBet  
    self:upateBetLevel()
end

function CodeGameScreenPelicanMachine:addObservers()
    CodeGameScreenPelicanMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        if self:isNormalStates( )  then
            if self:getBetLevel() == 0 then
                self:unlockHigherBet()
            else
                self:showMapScroll(nil,true)
            end
        end
    end,"SHOW_BONUS_MAP")

    gLobalNoticManager:addObserver(self,function(self,params)
        
        if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
          
            self:clickMapTipView()

        end
        
    end,"SHOW_BONUS_Tip")

    gLobalNoticManager:addObserver(
        self,
        function(self)
            if self.m_spineTanban then
                -- 使用的屏幕大小换算的坐标
                local posX, posY = self.m_spineTanban:getPosition()
                self.m_spineTanban:setPosition(cc.p(posY, posX))
                if self.m_spineTanban.m_btnView then
                    local posBtnX,posBtnY = self.m_spineTanban.m_btnView:getPosition()
                    self.m_spineTanban.m_btnView:setPosition(cc.p(posBtnY,posBtnX))
                end
                if self.m_spineTanban.m_btnView_2 then
                    local posBtnX,posBtnY = self.m_spineTanban.m_btnView_2:getPosition()
                    self.m_spineTanban.m_btnView_2:setPosition(cc.p(posBtnY,posBtnX))
                end
            end
        end,
        ViewEventType.NOTIFY_RESET_SCREEN
    )

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()

        local totalBet = globalData.slotRunData:getCurTotalBet( )

        -- 不同的bet切换才刷新框
        if self.m_betTotalCoins ~=  totalBet  then
            self.m_betTotalCoins = totalBet
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenPelicanMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenPelicanMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenPelicanMachine:drawReelArea()
    CodeGameScreenPelicanMachine.super.drawReelArea(self)

    self.m_clipUpParent = self.m_csbOwner["sp_reel_respin_0"]:getParent()

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPelicanMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return "Socre_Pelican_Bonus1"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_Pelican_Bonus2"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_Pelican_Bonus3"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_Pelican_Bonus4"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_Pelican_Bonus5"
    elseif symbolType == self.SYMBOL_FIX_ALL then
        return "Socre_Pelican_Bonus6"
    elseif symbolType == self.SYMBOL_BLANCK then
        return "Socre_Pelican_Blanck"
    end

    return nil
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenPelicanMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_3RowFreeSpinBar:changeFreeSpinByCount()
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""
        local selectReel = fsExtraData.freeRow or ""
        self:freeSpinShow()
        self.m_fsReelDataIndex = 0
        if FreeType == "selectFree" then
            self:changeMainUi(self.m_3RowFree )

        elseif FreeType == "collectFree" then

            self.m_bottomUI:showAverageBet()
            -- self:freeSpinShow()
            if tostring(selectReel)  == "4" then
                self:changeMainUi(self.m_4RowFree )
                self.m_iReelRowNum = self.m_iReelMaxRow
                self:changeReelData()
            else
                self:changeMainUi(self.m_3RowFree )
            end
            
            self:initSupperWildNode()

        end
    end
    
end


---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenPelicanMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    self.bg1:setVisible(false)
    self.bg2:setVisible(true)
    util_spinePlay(self.bg2,"idleframe",true)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenPelicanMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.bg1:setVisible(true)
    self.bg2:setVisible(false)
    util_spinePlay(self.bg1,"idleframe",true)
end


function CodeGameScreenPelicanMachine:changeProChildShow(isShow)
    self.loadingMap:setVisible(isShow)
    self.loadingIcon:setVisible(isShow)
end
---------------------------------------------------------------------------


----------- FreeSpin相关
--改变展示上方鹈鹕
function CodeGameScreenPelicanMachine:changeShowUpPeople(isShow)
    if isShow then
        for i,v in ipairs(self.upPeopleList) do
            if isShow == i then
                v:setVisible(true)
                util_spinePlay(v,"idleframe",true)
            else
                v:setVisible(false)
            end
        end
    else
        for i,v in ipairs(self.upPeopleList) do
            v:setVisible(false)
        end
    end
end

function CodeGameScreenPelicanMachine:freeSpinShow( )
    self.loadingMap:setVisible(false)
    self.loadingIcon:setVisible(false)
    self.m_progress:setVisible(false)
    self:changeProChildShow(false)
    self.m_3RowFreeSpinBar:setVisible(true)
    self:changeShowUpPeople(2)
end

function CodeGameScreenPelicanMachine:freeSpinOverShow( )
    self.loadingMap:setVisible(true)
    self.loadingIcon:setVisible(true)
    self.m_progress:setVisible(true)
    self:changeProChildShow(true)
    self.m_3RowFreeSpinBar:setVisible(false)
    self:changeShowUpPeople(1)
end

--[[
    由于开始的次数挂点和结束的钱数挂点相同，所以m_lb_coins   = num,
]]
function CodeGameScreenPelicanMachine:showSuperFreeStart(num,func)
    self:clearCurMusicBg()
    local dialogName = "FreeSpinOver"
    local ownerlist = {
        m_lb_coins   = num,
    }
    local autoType   = nil
    local skinName   = "superstart"
    gLobalSoundManager:playSound("PelicanSounds/music_Pelican_superFree_start.mp3")
    self:addViewToSpineTanban(dialogName, ownerlist, autoType, func, skinName)
end

---
-- 显示free spin
function CodeGameScreenPelicanMachine:showEffect_FreeSpin(effectData)
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
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

-- FreeSpinstart
function CodeGameScreenPelicanMachine:showFreeSpinView(effectData)
    self.m_isBonusTrigger = false
    local showFSView = function ( ... )
        self:hideMapTipView(true)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
           
            effectData.p_isPlay = true
            self:playGameEffect()

        else
            
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
            local FreeType = fsExtraData.FreeType or ""
            local selectReel = fsExtraData.freeRow or ""
    
            if FreeType == "collectFree" then
                --super开始弹板
                self:showSuperFreeStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function (  )
                    self:clearSpineTanbanAddView(function (  )
                        self:showGuochang(1,nil,function (  )
                            self:freeSpinShow()
                            self.m_superFreeSpinStart = true
        
                            self.m_fsReelDataIndex = 0
                            
                
                            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
                            if fsWinCoin ~= 0 then
                                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
                            else
                                self.m_bottomUI:updateWinCount("")
                            end
                
                            self:levelFreeSpinEffectChange()
                
                            if tostring(selectReel) == "4" then
                                self:changeMainUi(self.m_4RowFree )
                                self.m_iReelRowNum = self.m_iReelMaxRow
                                self:changeReelData()
                            else
                                self:changeMainUi(self.m_3RowFree )
                            end
                
                            self:initSupperWildNode()
                
                            self:triggerFreeSpinCallFun()
                            
                        end)
                        self:delayCallBack(45/30,function (  )
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end)
                          
                    end)
                    
                end)
            else
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect() 
            end
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFSView()    
    end,0.5)

end

function CodeGameScreenPelicanMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    local selectReel = fsExtraData.freeRow or ""

    local dialogName = "FreeSpinOver"
    local ownerlist = {
        m_lb_num   = num,
        m_lb_coins = util_formatCoins(coins, 30),
    }
    local autoType   = nil
    local skinName   = "freespinover"
    if FreeType == "collectFree" then
        skinName   = "superover"
    end
    if FreeType == "collectFree" then
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_superFree_over.mp3")
    else
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_free_over.mp3")
    end
    self:addViewToSpineTanban(dialogName, ownerlist, autoType, func, skinName)

end

--[[
    @desc: 处理free和reSpin的弹板spine , 将start和over弹板绑定在spine上
]]
function CodeGameScreenPelicanMachine:addViewToSpineTanban(_dialogName, _ownerlist, _autoType, _func, _skinName)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""

    local spineTanbanParent = self.m_spineTanbanParent

    --创建spine，将cocos挂到spine上
    self.m_spineTanban  = util_spineCreate("Pelican_tanban",true,true)
    spineTanbanParent:addChild(self.m_spineTanban,10000)
    self.m_spineTanban:setSkin(_skinName)
    self.m_spineTanban:setScale(self.m_machineRootScale)
   
    --按钮
    local btnView = util_createView("CodePelicanSrc.PelicanTanBanBtnView",_skinName)
    util_spinePushBindNode(self.m_spineTanban,"anniu",btnView)
    -- btnView:initViewData(_func)
    self.m_spineTanban.m_btnView = btnView
    
    --钱数
    if _ownerlist.m_lb_coins ~= nil then
        local coinsView = util_createAnimation("Pelican/FreeSpinOver_num.csb")
        coinsView:findChild("m_lb_coins"):setString(_ownerlist.m_lb_coins)
        coinsView:findChild("Node_1_0"):setVisible(false)
        if _skinName ~= "superstart" then
            self:updateLabelSize({label=coinsView:findChild("m_lb_coins"),sx=0.6,sy=0.63},1104)
        end
        util_spinePushBindNode(self.m_spineTanban,"A_shuzi",coinsView)
    end
    --次数
    if _ownerlist.m_lb_num ~= nil then
        local numView = util_createAnimation("Pelican/FreeSpinOver_num.csb")
        numView:findChild("m_lb_coins"):setString(_ownerlist.m_lb_num)
        numView:findChild("Node_1_0"):setVisible(false)
        if FreeType == "collectFree" then
            util_spinePushBindNode(self.m_spineTanban,"B_shuzi",numView)
        else
            util_spinePushBindNode(self.m_spineTanban,"C_shuzi",numView)
        end
    end

    util_spinePlay(self.m_spineTanban,"start",false)
    util_spineEndCallFunc(self.m_spineTanban,"start",function(  )
        util_spinePlay(self.m_spineTanban,"idle",true)
        local pos = util_convertToNodeSpace(btnView,self.m_spineTanban)
        btnView:setVisible(false)

        local btnView2 = util_createView("CodePelicanSrc.PelicanTanBanBtnView",_skinName)
        btnView2:initViewData(_func)
        self.m_spineTanban.m_btnView_2 = btnView2
        self.m_spineTanban:addChild(btnView2)

        btnView2:setPosition(pos)
        btnView2:setIsClick(true)
    end)
    self.dark:setVisible(true)
    self.dark:runCsbAction("start")
end

function CodeGameScreenPelicanMachine:clearSpineTanbanAddView(func)
    local btnView = self.m_spineTanban.m_btnView
    if btnView then
        btnView:setVisible(true)
        if self.m_spineTanban.m_btnView_2 then
            self.m_spineTanban.m_btnView_2:setVisible(false)
        end
    end
    
    util_spinePlay(self.m_spineTanban,"over",false)
    self.dark:runCsbAction("over",false,function (  )
        self.dark:setVisible(false)
    end)
    self:delayCallBack(2/3,function (  )
        if func then
            func()
        end
        if self.m_spineTanban then
            self.m_spineTanban:removeFromParent()
            self.m_spineTanban = nil
        end
    end)
end

function CodeGameScreenPelicanMachine:showFreeSpinOverView()
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    local strCoins=util_formatCoins(freeSpinWinCoin,50)
    self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            self:clearSpineTanbanAddView(function (  )
                self.m_fsReelDataIndex = 0
            
                local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                local currentPos = selfData.pos or 0

                local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
                local FreeType = fsExtraData.FreeType or ""
                local selectReel = fsExtraData.freeRow or ""

                if FreeType == "collectFree" then
                    self.m_bottomUI:hideAverageBet()
                    if tostring(selectReel)  == "4" then
                        self.m_iReelRowNum = self.m_iReelMinRow
                        self:hideUpReelSlots()
                        self:changeReelData()
                    end
                    -- 取消掉赢钱线的显示
                    self:clearWinLineEffect()
                    self.m_progress:restProgressEffect(0)

                    self:removeAllSupperWildNode( )

                    self.m_mapNodePos = currentPos -- 更新最新位置
                    self.m_map.m_currPos = self.m_mapNodePos
                end
                self:changeMainUi(self.m_base )
                self.m_effectNode:setVisible(false)
                self.m_effectNode:removeAllChildren(true)
                self:freeSpinOverShow()
                self:triggerFreeSpinOverCallFun()
            end)
            
    end)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPelicanMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    if self.m_winSoundsId then
        
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil

    end
    self.m_bSlotRunning = true

    self:hideMapScroll()

    self.m_FsLockWildNode:setVisible(true)
    self:hideMapTipView()
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPelicanMachine:addSelfEffect()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        if selfData.wildPos and not selfData.moveRoute then
            --金鱼游动
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_FISH_SWIMMING
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_FISH_SWIMMING -- 动画类型
        end
    else
        self.m_collectList ={}

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end

        if self.m_collectList and #self.m_collectList > 0 then

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FLY_COIN_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT
        
        end

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusMode = selfData.bonusMode or ""
        local collectWin = selfData.collectWin

        --是否触发收集小游戏
        if bonusMode == "collect" or collectWin then 
            local baseSpecialCoins =  self:getBaseSpecialCoins()
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            if baseSpecialCoins > 0 then
                selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
            else
                selfEffect.p_effectOrder = GameEffect.EFFECT_FIVE_OF_KIND + 1
            end
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
            
        end
    end  
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPelicanMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_FISH_SWIMMING then    --金鱼游动
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData.wildPos and not selfData.moveRoute then
            self:refreshFreeSpinWilds()
        end
        self:delayCallBack(1,function (  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    elseif effectData.p_selfEffectType == self.FLY_COIN_EFFECT then

        self:showEffect_collectCoin(effectData)

    elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
        local waitTime = 0
        if self.m_runSpinResultData.p_winLines == 0 then
            waitTime = 0
        else
            waitTime = 1
        end
        self:delayCallBack(waitTime,function (  )
            self.loadingMap:showActionFrame()
            self.loadingIcon:jiman()
            self.m_progress:showJiMan(function (  )
                self:showEffect_CollectBonus(effectData)
            end)
        end)
        
    end
    
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPelicanMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenPelicanMachine:playEffectNotifyNextSpinCall( )
    self.m_bSlotRunning = false
    CodeGameScreenPelicanMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    if self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end

end

function CodeGameScreenPelicanMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenPelicanMachine.super.slotReelDown(self)
end

--中奖预告
function CodeGameScreenPelicanMachine:winningNotice(func)
    local randomNum = math.random(1,2)
    if randomNum == 1 then
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_winningNotice1.mp3")
    else
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_winningNotice2.mp3")
    end
    
    self.yuGaoView:setVisible(true)

    self.yuGaoView:showYuGao()
    util_spinePlay(self.upPeople,"actionframe",false)
    self:delayCallBack(3,function (  )
        self.yuGaoView:setVisible(false)
        util_spinePlay(self.upPeople,"idleframe",true)
        if func then
            func()
        end
    end)
end

--提示
function CodeGameScreenPelicanMachine:clickMapTipView( )
    if self.m_map:getMapIsShow() ~= true and self.m_bSlotRunning ~= true then
        if not self.collectTipView:isVisible() then
            self:showMapTipView( )
        else    
            self:hideMapTipView( )
        end
    end
end

function CodeGameScreenPelicanMachine:showMapTipView( )
    if self:isNormalStates( ) then  --是否可以点击
        if self.collectTipView.m_states == nil or  self.collectTipView.m_states == "idle" then
            self.collectTipView:setVisible(true)
            self.collectTipView.m_states = "show"
            self.collectTipView:stopAllActions()
            self.collectTipView:runCsbAction("show",false,function(  )
                self.collectTipView.m_states = "idle"
                self.collectTipView:stopAllActions()
                self.collectTipView:runCsbAction("idle")
                self.tipsWaitNode:stopAllActions()
                performWithDelay(self.tipsWaitNode,function (  )
                    self.collectTipView:stopAllActions()
                    self.collectTipView:runCsbAction("over",false,function (  )
                        self.collectTipView.m_states = "idle"
                        self.collectTipView:setVisible(false)
                    end)
                end,5)
            end)  
        end
    end
end

function CodeGameScreenPelicanMachine:hideMapTipView( _close )
    if self.collectTipView.m_states == "idle" then
        self.collectTipView.m_states = "over"
        self.collectTipView:stopAllActions()
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)   
    end
    if _close then
        self.collectTipView:setVisible(false)
        self.collectTipView.m_states = "over"
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)
    end
end

--[[
    **********************高低bet相关
]]

function CodeGameScreenPelicanMachine:getBetLevel( )

    return self.m_betLevel
end

function CodeGameScreenPelicanMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据(数值配高低bet列表)
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenPelicanMachine:upateBetLevel()
    local minBet = self:getMinBet( )
    self:updatProgressLock( minBet ) 
end

function CodeGameScreenPelicanMachine:updatProgressLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    --高倍场进度条一直解锁
    if globalData.slotRunData.isDeluexeClub == true then
        if self.m_betLevel ~= 1 then
            self.m_betLevel = 1
            -- 解锁进度条
            self.m_progress:unlock(self.m_betLevel)
            self.loadingIcon:unLock()
        end
    elseif betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
            -- 解锁进度条
            self.m_progress:unlock(self.m_betLevel)
            self.loadingIcon:unLock()
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            -- 锁定进度条
            self.m_progress:lock(self.m_betLevel)
            self.loadingIcon:Lock()
        end
        
    end 
end

--点击更新bet
function CodeGameScreenPelicanMachine:unlockHigherBet()
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

    self:hideMapTipView()
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

--[[
    ****************  freespin玩法相关
]]
--[[
    接收网络回调
]]
function CodeGameScreenPelicanMachine:updateNetWorkData()
    -- self.m_runSpinResultData
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local num = 0
    local reels = self.m_runSpinResultData.p_reels
    if reels and #reels > 0 then
        for i,v in ipairs(reels) do
            for j,type in ipairs(v) do
                if type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    num = num + 1
                end
            end
        end
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        self:produceSlots()
    
        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""

        if FreeType == "collectFree" then
            -- 网络消息已经赋值成功开始进行击随机固定wild的判断逻辑
            self:netBackCheckAddWildAction( )
        else
            -- 刷新wild
            self:refreshFreeSpinWilds()
            self:netBackStopReel()
            
        end
    else
        if num >= 3 then
            local random = math.random(1,3)
            if random < 2 then
                --播放预告动画
                self.m_playWinningNotice = true
                self:winningNotice(function (  )
                    self:produceSlots()         --将它写在此处为了等self.m_playWinningNotice设为true
                    local isWaitOpera = self:checkWaitOperaNetWorkData()    --每一步都加上，防止后续修改遗漏条件
                    if isWaitOpera == true then
                        return
                    end
                    self.m_isWaitingNetworkData = false
                    self:operaNetWorkData()  -- end
                end)
            else
                self:produceSlots()
                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData()  -- end
            end
        else
            self:produceSlots()
            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData()  -- end
        end
        
    end
end

function CodeGameScreenPelicanMachine:netBackCheckAddWildAction( )
    
    if self.m_superFreeSpinStart then

        self.m_superFreeSpinStart = false
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            -- 第一次进superfree锁定wild的位置
            -- self:runSuperFreeSpinLockWildNode( function(  )
                self:netBackStopReel( )
            -- end )
        end
        

    else
        self:netBackStopReel( )
    end
       
end


function CodeGameScreenPelicanMachine:netBackStopReel( )
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()  -- end

end

-- 转轮开始滚动函数
function CodeGameScreenPelicanMachine:beginReel()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_effectNode:setVisible(true)
    end
    -- 
    CodeGameScreenPelicanMachine.super.beginReel(self)               
end

--[[
    刷新移动Wild图标
]]
function CodeGameScreenPelicanMachine:refreshFreeSpinWilds()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_effectNode:removeAllChildren(true)
    local moveRoute = selfData.moveRoute
    local wildPos = selfData.wildPos
    if not wildPos then
        return
    end

    self.m_effectNode:setVisible(true)

    if moveRoute then
        
        for index=1,#moveRoute do
            local startIndex = moveRoute[index][1]
            local endIndex = moveRoute[index][2]

            local startPos = self:getRowAndColByPos(startIndex)
            --开始小块节点
            local startFishPos = util_getOneGameReelsTarSpPos(self, startIndex) 

            local endPos = self:getRowAndColByPos(endIndex)
            --终止小块节点
            local endFishPos = util_getOneGameReelsTarSpPos(self, endIndex) 

            --开始小块倍数
            local startTimes = moveRoute[index][3]
            --结束小块倍数
            local endTimes = wildPos[tostring(endIndex)]
            local startWild = util_spineCreate("Socre_Pelican_Wild",true,true)
            local skinName = self:getWildSkin(startTimes)
            startWild:setSkin(skinName)
            util_spinePlay(startWild,"idleframe",true)
            startWild:setPosition(cc.p(startFishPos))
            self.m_effectNode:addChild(startWild,endIndex,endIndex)
            if index == 1 then
                gLobalSoundManager:playSound("PelicanSounds/Pelican_free_wildMove.mp3")
            end
            if endTimes == 1 then
                local name = self:getWildSkin(endTimes)
                startWild:setSkin(name)
                startWild:runAction(cc.Sequence:create({
                    cc.CallFunc:create(function(  )
                        util_spinePlay(startWild,"actionframe2",false)
                    end),
                    
                    cc.MoveTo:create(35/30,cc.p(endFishPos)),
                    cc.DelayTime:create(25/30)
                }) )
            elseif endIndex == -1 then
               
                local pos = cc.p(startWild:getPosition()) 
                pos.x = pos.x - 230
                startWild:runAction(cc.Sequence:create({
                    cc.CallFunc:create(function (  )
                        util_spinePlay(startWild,"over",false)
                        util_spineEndCallFunc(startWild,"over",function (  )
                            startWild:setVisible(false)
                        end)
                    end),
                    cc.MoveTo:create(35/30,pos),
                    cc.CallFunc:create(function (  )
                        
                    end),
                    
                }) )
            else
                local name = self:getWildSkin(endTimes)
                startWild:setSkin(name)
                local isShowStart = false
                startWild:runAction(cc.Sequence:create({
                    cc.CallFunc:create(function(  )
                        if startTimes == endTimes then
                            util_spinePlay(startWild,"actionframe2",false)
                        else 
                            isShowStart = true
                            util_spinePlay(startWild,"start",false)
                        end
                    end),
                    cc.MoveTo:create(35/30,cc.p(endFishPos)),
                    cc.CallFunc:create(function(  )
                        if isShowStart then
                            gLobalSoundManager:playSound("PelicanSounds/Pelican_free_chengbei_show.mp3")
                        end
                    end),
                    cc.DelayTime:create(25/30),
                    -- cc.CallFunc:create(function(  )
                    --     if endTimes > startTimes then
                            -- 
                            -- util_spinePlay(startWild,"idleframe",true)
                            -- local fixNode = self:getFixSymbol(endPos.iY , endPos.iX)
                            -- if fixNode then
                            --     fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                            --     local ccbNode = fixNode:getCCBNode()
                            --     if not ccbNode then
                            --         fixNode:checkLoadCCbNode()
                            --     end
                            --     ccbNode = fixNode:getCCBNode()
                            --     if ccbNode then
                            --         local name = self:getWildSkin(endTimes)
                            --         ccbNode.m_spineNode:setSkin(name)
                            --     end
                            -- end

                        -- else
                           
                        -- end

                    -- end)
                }) )
            end
        end
    else
        for index,times in pairs(wildPos) do
            local startPos = self:getRowAndColByPos(index)
            --开始小块节点
            local startFishPos = util_getOneGameReelsTarSpPos(self, index)

            local startWild = util_spineCreate("Socre_Pelican_Wild",true,true)
            local skinName = self:getWildSkin(startTimes)
            startWild:setSkin(skinName)
            startWild:setPosition(startFishPos)
            self.m_effectNode:addChild(startWild,index,index)

            self.m_effectNode:setVisible(false)
        end
    end
end

function CodeGameScreenPelicanMachine:getWildSkin(times)
    if times == 1 then
        return "x1"
    elseif times == 2 then
        return "x2"
    elseif times == 3 then
        return "x3"
    elseif times == 4 then
        return "x4"
    end
    return "x1"
end

function CodeGameScreenPelicanMachine:refreshFreeSpinWildsSlotDownFunc(reelCol )
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE or not selfData or not selfData.wildPos then
        return
    end
    local moveRoute = selfData.moveRoute
    local wildPos = selfData.wildPos
    for index,times in pairs(wildPos) do
        local startPos = self:getRowAndColByPos(index)
        if startPos.iY == reelCol then
            local fixNode = self:getFixSymbol(startPos.iY , startPos.iX)
            fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
            if times > 1 then
                local ccbNode = fixNode:getCCBNode()
                if not ccbNode then
                    fixNode:checkLoadCCbNode()
                end
                ccbNode = fixNode:getCCBNode()
                if ccbNode then
                    local name = self:getWildSkin(times)
                    ccbNode.m_spineNode:setSkin(name)
                end
            else
                local ccbNode = fixNode:getCCBNode()
                if not ccbNode then
                    fixNode:checkLoadCCbNode()
                end
                ccbNode = fixNode:getCCBNode()
                if ccbNode then
                    local name = self:getWildSkin(times)
                    ccbNode.m_spineNode:setSkin(name)
                end
            end
            
            fixNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - fixNode.p_rowIndex)

        end
    end

    if reelCol == self.m_iReelColumnNum then
        
        self.m_effectNode:setVisible(false)
        self.m_effectNode:removeAllChildren(true)
        for index,times in pairs(wildPos) do
            local startPos = self:getRowAndColByPos(index)
            --开始小块节点
            local startFishPos = util_getOneGameReelsTarSpPos(self, index) 

            local startWild = util_spineCreate("Socre_Pelican_Wild",true,true)
            local name = self:getWildSkin(times)
            startWild:setSkin(name)
            util_spinePlay(startWild,"idleframe",true)
            startWild:setPosition(cc.p(startFishPos))
            self.m_effectNode:addChild(startWild)
        end
    end

end

--[[
    单列滚动停止
]]
function CodeGameScreenPelicanMachine:slotOneReelDownFinishCallFunc( reelCol )
    CodeGameScreenPelicanMachine.super.slotOneReelDownFinishCallFunc(self,reelCol)
    self:refreshFreeSpinWildsSlotDownFunc( reelCol )
end

function CodeGameScreenPelicanMachine:showEffect_LineFrame(effectData)

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        self.m_effectNode:setVisible(false)
    end
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfData.collectWin or 0
    if collectWin > 0 then
        self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin - collectWin
        globalData.slotRunData.lastWinCoin = self.m_iOnceSpinLastWin
    end

    return CodeGameScreenPelicanMachine.super.showEffect_LineFrame(self,effectData)
    

end

--[[
    *************** 选择玩法
--]]
---
-- 显示bonus 触发的小游戏
function CodeGameScreenPelicanMachine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
    self.isInBonus = true

    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self.isInBonus = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    local time = 1
    local changeNum = 1/(time * 60) 
    local curvolume = 1
    self.m_updateBgMusicHandlerID = scheduler.scheduleUpdateGlobal(function()
        curvolume = curvolume - changeNum
        if curvolume <= 0 then

            curvolume = 0

            if self.m_updateBgMusicHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
                self.m_updateBgMusicHandlerID = nil
            end
        end

        gLobalSoundManager:setBackgroundMusicVolume(curvolume)
    end)

    performWithDelay(self,function(  )
        -- 停止播放背景音乐
        self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        local num,scList = self:getScatterList()
        -- 播放bonus 元素不显示连线
        if num > 0 then
            -- --由于提层导致找不到sc小块没播放触发动画
            self:checkChangeBaseParent()
            self:showScatterTrigger(num,scList,function (  )
                performWithDelay(self,function(  )
                    self:showBonusGameView(effectData)
                end,0.5)
            end)
            -- 播放提示时播放音效        
            self:playScatterTipMusicEffect()

        else
            self:showBonusGameView(effectData)
        end
 
    end,time)
        
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenPelicanMachine:getScatterList( )
    local scList = {}
    local num = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if node.p_symbolType == 90 then
                    table.insert( scList, node)
                    num = num + 1
                end
            end
        end
    end
    return num,scList
end

---
-- 重写sc触发逻辑
--
function CodeGameScreenPelicanMachine:showScatterTrigger(num,scList,callFun)

    local animTime = 0

    for i = 1, num do
        local slotNode = nil
        if scList[i] then
            slotNode = scList[i]
        end
        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

function CodeGameScreenPelicanMachine:showBonusGameView( effectData )
   
    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    self.m_bottomUI:checkClearWinLabel()
    self:show_Choose_BonusGameView(effectData)
end

function CodeGameScreenPelicanMachine:show_Choose_BonusGameView(effectData)
    
    gLobalSoundManager:playSound("PelicanSounds/music_Pelican_choose_feature.mp3")

    local chooseView = util_createView("CodePelicanSrc.PelicanChooseView",self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        chooseView.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(chooseView)
    chooseView:findChild("root"):setScale(self.m_machineRootScale)
    chooseView:setEndCall( function( selectId ) 
        if chooseView then
            chooseView:removeFromParent()
        end
        if selectId == selectRespinId then
            self.m_iFreeSpinTimes = 0 
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0      
            self.m_bProduceSlots_InFreeSpin = false

            self:setSpecialSpinStates(true )
            self.m_chooseRepin = true
            self.m_chooseRepinGame = true --选择respin
            self.isShowRespinStartView = false
            self.m_chooseRepinNotCollect = true

            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        else
            self:showGuochang(45/30,selectId,function (  )
                self:freeSpinShow()
                self:bonusOverAddFreespinEffect( )
                effectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮
            end)
        end
    end)
end


function CodeGameScreenPelicanMachine:bonusOverAddFreespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

function CodeGameScreenPelicanMachine:dealSmallReelsSpinStates( )

    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false
    end

    CodeGameScreenPelicanMachine.super.dealSmallReelsSpinStates(self )

end

function CodeGameScreenPelicanMachine:requestSpinReusltData()

    CodeGameScreenPelicanMachine.super.requestSpinReusltData(self)

    -- 设置stop 按钮处于不可点击状态
    if not self.m_chooseRepinGame  then
        if self:getCurrSpinMode() == RESPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Spin,false,true})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Stop,false,true})
        end
    end
    
end

function CodeGameScreenPelicanMachine:playEffectNotifyChangeSpinStatus( )
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
            if not self.m_chooseRepinGame  then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,true})
            end
            
        end
    end

end

--[[
    ************** respin 玩法    
--]]

function CodeGameScreenPelicanMachine:spinResultCallFun(param)
    local isSucc = param[1]
    local spinData = param[2]

    CodeGameScreenPelicanMachine.super.spinResultCallFun(self,param)
    if isSucc then

         --respin中触发了 额外奖励次数
        if spinData.result.respin.extra and spinData.result.respin.extra.options then
            self.m_triggerRespinRevive = true
        end

    end

end

-- 继承底层respinView
function CodeGameScreenPelicanMachine:getRespinView()
    return "CodePelicanSrc.respin.PelicanRespinView"
end
-- 继承底层respinNode
function CodeGameScreenPelicanMachine:getRespinNode()
    return "CodePelicanSrc.respin.PelicanRespinNode"
end
--触发respin
function CodeGameScreenPelicanMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize(true)
    end

    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true
    self:changeMainUi(self.m_respin )

    self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
    
    self.m_reSpinPrize:updateView(0)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    if self:isRespinInit() then
        self.m_respinView:setAnimaState(0)
    end
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --转换storeicons
    local storeIcons = {}
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    for i=1,#storedIcons do
        local pos = self:getRowAndColByPos(storedIcons[i][1])
        storeIcons[#storeIcons + 1] = {iX = pos.iX,iY = pos.iY, score = storedIcons[i][2]}
    end

    self.m_respinView:setStoreIcons(storeIcons)


     -- 创建炸弹respin层
    self.m_respinViewUp = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinViewUp:setMachine(self)
    if self:isRespinInit() then
        self.m_respinViewUp:setAnimaState(0)
    else
        local score = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        self.m_reSpinPrize:updateView(score)
        
     end
     self.m_respinViewUp:setCreateAndPushSymbolFun(
         function(symbolType,iRow,iCol,isLastSymbol)
             return self:getSlotNodeWithPosAndTypeUp(symbolType,iRow,iCol,isLastSymbol)
         end,
         function(targSp)
             self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
         end
     )
     self.m_clipUpParent:addChild(self.m_respinViewUp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 10)

      --转换storeicons
    local storeIcons2 = {}
    local storedIcons2 = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    for i=1,#storedIcons2 do
        local pos = self:getRowAndColByPos(storedIcons2[i][1])
        storeIcons2[#storeIcons2 + 1] = {iX = pos.iX,iY = pos.iY, score = storedIcons2[i][2]}
    end
    self.m_respinViewUp:setStoreIcons(storeIcons2)

    self:initRespinView(endTypes, randomTypes)----1

end
function CodeGameScreenPelicanMachine:isRespinInit()
    -- return true
    return self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount
end
--强制 执行变黑
function CodeGameScreenPelicanMachine:respinInitDark()
    if self:isRespinInit() then
        local respinList = self.m_respinViewUp:getAllCleaningNode()
        for i=1,#respinList do
            respinList[i]:setVisible(false)
        end
    end
end

function CodeGameScreenPelicanMachine:initRespinView(endTypes, randomTypes)
    self.upPeople:setVisible(false)
    self:changeProChildShow(false)
    self.m_progress:setVisible(false)
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
            performWithDelay(self,function()
                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                -- 更改respin 状态下的背景音乐
                self:changeReSpinBgMusic()
                if self:isRespinInit() then
                    self.m_flyIndex = 1
                    self.m_chipList = {}
                    self.m_chipListUp = {}
                    self.m_chipList = self.m_respinView:getAllCleaningNode()

                    self.m_chipListUp = self.m_respinViewUp:getAllCleaningNode()

                    --fly 动画
                    self.m_collScore = 0
                    self.m_reSpinPrize:repeatChangBig()
                    self:delayCallBack(2/3,function (  )
                        self:flyCoins(function()
                            self:delayCallBack(25/60,function (  )
                                self.m_reSpinPrize:resetSize()
                                self.m_flyIndex = 1
                                self:flyDarkIcon(function()
                                    self.m_respinViewUp:setAnimaState(1)
                                    self.m_respinView:setAnimaState(1)
                                    self:runNextReSpinReel()--开始滚动
                                end)
                            end)
                        end)
                    end)
                else
                    self:runNextReSpinReel()--开始滚动
                end
            end,1)
        end
    )

    -- self.m_respinView:changeClipRowNode(3,cc.p(0,1))

    self.m_respinViewUp:setEndSymbolType(endTypes, randomTypes)
    self.m_respinViewUp:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    local respinNodeInfoUp = self:reateRespinNodeInfoUp()

    self.m_respinViewUp:initRespinElement(
        respinNodeInfoUp,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:respinInitDark()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--开始下次ReSpin
function CodeGameScreenPelicanMachine:runNextReSpinReel(_isDownStates)

    if self.m_triggerRespinRevive then --触发respin奖励次数
        if  self.m_isShowRespinChoice then
            return
        end
        self.m_isShowRespinChoice = true
        --轮盘不允许点击
        -- performWithDelay(self,function()
            gLobalSoundManager:playSound("PelicanSounds/music_Pelican_respin_choose.mp3")
            local view=util_createView("CodePelicanSrc.respin.PelicanRespinChose",self.m_runSpinResultData.p_rsExtraData,function()
                self.m_triggerRespinRevive = false
                self.m_isShowRespinChoice = false
                self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
                CodeGameScreenPelicanMachine.super.runNextReSpinReel(self)
                if _isDownStates then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                end
            end,self)
            if globalData.slotRunData.machineData.p_portraitFlag then
                view.getRotateBackScaleFlag = function(  ) return false end
            end
            view:findChild("root"):setScale(self.m_machineRootScale)
            gLobalViewManager:showUI(view)
        -- end,1)
    else
        CodeGameScreenPelicanMachine.super.runNextReSpinReel(self)
        if _isDownStates then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end

--下面辣椒往上飞
function CodeGameScreenPelicanMachine:flyDarkIcon(func)
    if self.m_flyIndex > #self.m_chipList or self.m_flyIndex > #self.m_chipListUp then
        return
    end
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))

    local nodeEndSymbol =  self.m_chipListUp[self.m_flyIndex]
    local endPos = nodeEndSymbol:getParent():convertToWorldSpace(cc.p(nodeEndSymbol:getPosition()))

    self:runFlySymbolAction(nodeEndSymbol,0.01,18/30,startPos,endPos,function()
        self.m_flyIndex = self.m_flyIndex + 1
        if  self.m_flyIndex == #self.m_chipList + 1 then
            if func then
                func()
            end
        else
            self:flyDarkIcon(func)
        end
    end)

end

function CodeGameScreenPelicanMachine:runFlySymbolAction(endNode,time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node = util_spineCreate("Socre_Pelican_Bonus1",true,true)
    node:setVisible(false)

    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        util_spinePlay(node,"actionframe2",false)
        
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_flyUp.mp3")
    end)
    local bez=cc.BezierTo:create(flyTime,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
    cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
    local ease = cc.EaseQuadraticActionOut:create(bez)
    actionList[#actionList + 1] = ease
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_flyUp_fanKui.mp3")
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(14/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        node:setVisible(false)
        node:removeFromParent()
        endNode:setVisible(true)
    end)
    node:runAction(cc.Sequence:create(actionList))
end

--金色的辣椒
function CodeGameScreenPelicanMachine:flyCenterToSymbol(func)
    if self.m_flyIndex > #self.m_aimAllSymbolNodeList then
        return
    end
    local startPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(self.m_reSpinPrize:getPosition()))
    local symbolNode =  self.m_aimAllSymbolNodeList[self.m_flyIndex]
    if symbolNode:getParent() == nil or  symbolNode:getPosition() == nil  then
        self.m_flyIndex = self.m_flyIndex + 1
        self:flyCenterToSymbol(func)
        return
    end
    local endPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
    symbolNode:runAnim("start")
    self:delayCallBack(1/3,function (  )
        symbolNode:runAnim("idleframe2",true)
    end)
    self:runFlyGoldAction(1/3,0.5,startPos,endPos,function()
        local score = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple
        -- symbolNode
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        score = util_formatCoins(score, 4)
        if symbolNode.m_csbNode then
            symbolNode.m_csbNode:setVisible(true)
            local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
            if lbs and lbs.setString  then
                lbs:setString(score)
                self:updateLabelSize({label=lbs,sx=0.9,sy=0.9},314)
            end
            local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")
            if lbs2 and lbs2.setString  then
                gLobalSoundManager:playSound("PelicanSounds/Pelican_respin_spBonus_fankui.mp3")
                lbs2:setString(score)
                self:updateLabelSize({label=lbs2,sx=0.9,sy=0.9},314)
            end
            self:addAllOtherRespinSymbolLab(symbolNode )
            symbolNode.m_csbNode:runCsbAction("start")
        end
        
        self.m_flyIndex = self.m_flyIndex + 1

        self:delayCallBack(15/30,function (  )
            symbolNode:runAnim("over",false,function (  )
                symbolNode:runAnim("idleframe3",true)
            end)
            self:delayCallBack(0.3,function (  )
                
                if  self.m_flyIndex == #self.m_aimAllSymbolNodeList + 1 then
                    self:allOtherRespinSymbolDark(false)
                    self.m_aimAllSymbolNodeList = {}
                    if func then
                        func()
                    end
                else
                    self:flyCenterToSymbol(func)
                end
            end)
        end)
        
    end)

end

function CodeGameScreenPelicanMachine:runFlyGoldAction(time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("Pelican_Respin_Prize_1.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        node:findChild("Particle_1"):resetSystem()
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_respin_spBonus_fly.mp3")
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        node:setVisible(false)
        node:removeFromParent()
        if callback then
            callback()
        end
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenPelicanMachine:runEndFlyGoldAction(time,flyTime,startPos,endPos,callback,chipNode)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("Socre_Pelican_Bonus_lizi.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        node:findChild("Particle_1"):resetSystem()
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if chipNode then
            chipNode:runAnim("shouji")
        end
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_endFly.mp3")
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(0.3)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        node:setVisible(false)
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenPelicanMachine:showRespinPrize(iRow, iCol)
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol),true) --获取分数（网络数据）
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local lastScore = self.m_collScore
    self.m_collScore = self.m_collScore + score * lineBet
    self.m_reSpinPrize:updateView(self.m_collScore,lastScore)
    
end

--[[
    @desc: 初始阶段飞金币
    author:{author}
    time:2019-08-20 14:10:50
    --@func:
    @return:
]]
function CodeGameScreenPelicanMachine:flyCoins(func)
    if self.m_flyIndex > #self.m_chipList then
        return
    end

    -- fly
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))
    local endNode = self.m_reSpinPrize
    local endPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))

    self:runFlyCoinsAction(0.01,18/30,startPos,endPos,function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_flyCoins_fankui.mp3")
        self.m_reSpinPrize:runCsbAction("repeatshouji")
        self:showRespinPrize(symbolStartNode.p_rowIndex,symbolStartNode.p_cloumnIndex)
        self.m_flyIndex = self.m_flyIndex + 1
        if  self.m_flyIndex >= #self.m_chipList + 1 then
            if func then
                func()
            end
        else
            self:flyCoins(func)
        end
    end)

end

function CodeGameScreenPelicanMachine:runFlyCoinsAction(time,flyTime,startPos,endPos,callback,chipNode)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_spineCreate("Socre_Pelican_Bonus1",true,true)

    node:setVisible(false)
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if chipNode then
            chipNode:runAnim("shouji")
        end
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        util_spinePlay(node,"actionframe3",false)
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_flyCoins.mp3")
    end)
    local moveto=cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = moveto
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))

end
----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenPelicanMachine:reateRespinNodeInfoUp()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolTypeUp(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPosUp(iCol)
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

---
--设置bonus scatter 层级
function CodeGameScreenPelicanMachine:getBounsScatterDataZorder(symbolType )
   
    local order = CodeGameScreenPelicanMachine.super.getBounsScatterDataZorder(self,symbolType )
    if self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    
    return order

end

function CodeGameScreenPelicanMachine:getReelPosUp(col)

    local reelNode = self:findChild("sp_reel_respin_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

--- respin 快停
function CodeGameScreenPelicanMachine:quicklyStop()
    CodeGameScreenPelicanMachine.super.quicklyStop(self)
    self.m_respinViewUp:quicklyStop()
end

--开始滚动
function CodeGameScreenPelicanMachine:startReSpinRun()

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
    else
        self.m_respinViewUp:startMove()
    end
    
    CodeGameScreenPelicanMachine.super.startReSpinRun(self)
    self.m_temp = {}
end

---判断结算
function CodeGameScreenPelicanMachine:reSpinReelDown(addNode)
    if self.m_isRespinReelDown then
        return
    end
    self.m_isRespinReelDown = true
 
    local inner = function()

        self:setGameSpinStage(STOP_RUN)

        self:updateQuestUI()
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
            self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            --quest
            self:updateQuestBonusRespinEffectData()
            
            performWithDelay(self,function()
                -- 获得所有固定的respinBonus小块
                local upList = self.m_respinViewUp:getAllCleaningNode()

                local List = self.m_respinView:getAllCleaningNode()
                gLobalSoundManager:playSound("PelicanSounds/Pelican_respin_endCollect.mp3")
                for i,v in ipairs(List) do
                    local tempNode = List[i]
                    tempNode:runAnim("actionframe")
                end
                for i,v in ipairs(upList) do
                    local tempUpNode = upList[i]
                    tempUpNode:runAnim("actionframe")
                end
                --结束
                self:reSpinEndAction()
            end,4/3)

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false

            return
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

        if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        end

        --继续
        self:runNextReSpinReel(true)

    end
    if self.m_triggerAllSymbol then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self:delayCallBack(0.5,function (  )
            self:allOtherRespinSymbolDark(true)
        end)
        self:delayCallBack(1.5,function (  )
            self.m_flyIndex = 1
            self:flyCenterToSymbol(function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                self.m_triggerAllSymbol = false
                self.m_aimAllSymbolNodeList = {}
                inner()
            end)
        end)
    else
        inner()
    end
end

function CodeGameScreenPelicanMachine:isOtherRespinSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end

function CodeGameScreenPelicanMachine:isOtherRespinSymbol2(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or self.SYMBOL_FIX_ALL then
        return true
    end
    return false
end

function CodeGameScreenPelicanMachine:checkIsShowLight( )
    local upList = self.m_respinViewUp:getFixSlotsNode()
    local List = self.m_respinView:getFixSlotsNode()
    for i=1,#upList do
        List[#List + 1] = upList[i]
    end
    for i,v in ipairs(List) do
        v.isLight = 2
    end
    for i,v in ipairs(self.m_aimAllSymbolNodeList) do
        for j,k in ipairs(List) do
            if v.p_cloumnIndex == k.p_cloumnIndex and 
                v.p_rowIndex == k.p_rowIndex and 
                    v.p_symbolType == k.p_symbolType and
                        v:getParent() == k:getParent() then
                            k.isLight = 1
            else
                if k.isLight then
                    if k.isLight ~= 1 then
                        k.isLight = 2
                    end
                else
                    k.isLight = 2
                end
            end
        end
    end
    return List
end

function CodeGameScreenPelicanMachine:addAllOtherRespinSymbolLab(_symbolNode )
    local lbs = _symbolNode.m_csbNode:findChild("m_lb_score")
    local str = lbs:getString()

    if not tolua.isnull(_symbolNode.m_csbNode) then
        _symbolNode.m_csbNode:removeFromParent()
        _symbolNode.m_csbNode = nil
    end

    self:addLabToSpine( _symbolNode)
    local lbs1 = _symbolNode.m_csbNode:findChild("m_lb_score")
    local lbs2 = _symbolNode.m_csbNode:findChild("m_lb_score2")
    if lbs1 and lbs1.setString  then
        lbs1:setString(str)
        self:updateLabelSize({label=lbs1,sx=0.9,sy=0.9},314)
    end
    if lbs2 and lbs2.setString  then
        lbs2:setString(str)
        self:updateLabelSize({label=lbs2,sx=0.9,sy=0.9},314)
    end
end

function CodeGameScreenPelicanMachine:allOtherRespinSymbolDark(isDark)
    local List = self:checkIsShowLight()

    for i,v in ipairs(List) do
        if v.isLight and v.isLight == 2 then
            if isDark then
                v:runAnim("dark1",false)
                if v.m_csbNode then
                    if self:isOtherRespinSymbol2(v.p_symbolType) then
                        self:addAllOtherRespinSymbolLab(v )
                        v.m_csbNode:runCsbAction("dark1")
                    end
                end
            else
                v:runAnim("dark2",false,function (  )
                    if v.p_symbolType == self.SYMBOL_FIX_ALL then
                        v:runAnim("idleframe3",true)
                    else
                        v:runAnim("idleframe2",true)
                    end
                end)
                if v.m_csbNode then
                    if self:isOtherRespinSymbol2(v.p_symbolType) then
                        self:addAllOtherRespinSymbolLab(v )
                        v.m_csbNode:runCsbAction("dark2")
                    end
                end
            end
        end

    end

end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenPelicanMachine:checkFeatureOverTriggerBigWin( winAmonut , feature)
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
        for i=1,#self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert( self.m_gameEffects, i + 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, i + 2, effectData )
                break
            end
        end
        if isAddEffect == false then
            self.m_llBigOrMegaNum = winAmonut


            local delayEffect = GameEffectData.new()
            delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
            delayEffect.p_effectOrder = feature + 1
            table.insert( self.m_gameEffects, #self.m_gameEffects + 1, delayEffect )

            local effectData = GameEffectData.new()
            effectData.p_effectType = winEffect
            table.insert( self.m_gameEffects, #self.m_gameEffects + 1, effectData )

        end

    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end

--播放respin放回滚轴后播放的提示动画
function CodeGameScreenPelicanMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    else
        node:runAnim("idleframe", true)
    end
end
--结束移除小块调用结算特效
function CodeGameScreenPelicanMachine:removeRespinNode()
    CodeGameScreenPelicanMachine.super.removeRespinNode(self)
    if self.m_respinViewUp == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNodeUp = self.m_respinViewUp:getAllEndSlotsNode()
    for i = 1, #allEndNodeUp do
        local node = allEndNodeUp[i]
        node:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
    end
    self.m_respinViewUp:removeFromParent()
    self.m_respinViewUp = nil
end

function CodeGameScreenPelicanMachine:MachineRule_respinTouchSpinBntCallBack()

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)

        self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)

        self:startReSpinRun()
    elseif self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        --快停
        self:quicklyStop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end


end

--接收到数据开始停止滚动
function CodeGameScreenPelicanMachine:stopRespinRun()

    CodeGameScreenPelicanMachine.super.stopRespinRun(self)

    local storedNodeInfoUp = self:getRespinSpinDataUp()
    local unStoredReelsUp = self:getRespinReelsButStoredUp(storedNodeInfoUp)
    self.m_respinViewUp:setRunEndInfo(storedNodeInfoUp, unStoredReelsUp)
end
function CodeGameScreenPelicanMachine:getMatrixPosSymbolTypeUp(iRow, iCol)
    local rowCount = #self.m_runSpinResultData.p_rsExtraData.upLastReels
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_rsExtraData.upLastReels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end
function CodeGameScreenPelicanMachine:getRespinSpinDataUp()
    if not self.m_runSpinResultData.p_rsExtraData then
        return {}
    end
    local storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons--p_storedIcons
    local index = 0
    local storedInfo = {}
    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            for i = 1, #storedIcons do
                if storedIcons[i] == index then
                    local type = self:getMatrixPosSymbolTypeUp(iRow, iCol)

                    local pos = {iX = iRow, iY = iCol, type = type}
                    storedInfo[#storedInfo + 1] = pos
                end
            end
            index = index + 1
        end
    end
    return storedInfo
end
function CodeGameScreenPelicanMachine:getRespinReelsButStoredUp(storedInfo)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and  storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
           local type = self:getMatrixPosSymbolTypeUp(iRow, iCol)
           if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
           end
        end
    end
    return reelData
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenPelicanMachine:getReSpinSymbolScore(id,onlyGetScore)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons == nil then
        storedIcons = {}
    end
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
    if onlyGetScore then
        return score
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


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenPelicanMachine:getReSpinSymbolScoreUp(id,onlyGetScore)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    if storedIcons == nil then
        storedIcons = {}
    end
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
    if onlyGetScore then
        return score
    end
    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolTypeUp(pos.iX, pos.iY)

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

function CodeGameScreenPelicanMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()  
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenPelicanMachine:setSpecialNodeScore(param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex



    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        if symbolNode.p_symbolType == self.SYMBOL_FIX_ALL and self.m_reconnect == false then
            self.m_triggerAllSymbol = true
            print("m_aimAllSymbolNodeList-----------")
            if self.m_aimAllSymbolNodeList == nil then
                self.m_aimAllSymbolNodeList = {}
            end
            local has = false
            for i=1,#self.m_aimAllSymbolNodeList do
                if self.m_aimAllSymbolNodeList[i] == symbolNode then
                    has = true
                    break
                end
            end
            if has == false then
                self.m_aimAllSymbolNodeList[#self.m_aimAllSymbolNodeList+1] = symbolNode
                if symbolNode.m_csbNode then
                    local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
                    local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")
                    if lbs and lbs.setString  then
                        lbs:setString("")
                    end
                    if lbs2 and lbs2.setString  then
                        lbs2:setString("")
                    end
                end
                

            end
            return
        end
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 4)
            if symbolNode then

                if symbolNode.m_csbNode then
                    local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
                    local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")
                    if lbs and lbs.setString  then
                        lbs:setString(score)
                        self:updateLabelSize({label=lbs,sx=0.9,sy=0.9},314)
                    end
                    if lbs2 and lbs2.setString  then
                        lbs2:setString(score)
                        self:updateLabelSize({label=lbs2,sx=0.9,sy=0.9},314)
                    end
                end
            end
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）

        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 4)
            if symbolNode then

                if symbolNode.m_csbNode then
                    local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
                    local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")

                    if lbs and lbs.setString  then
                        lbs:setString(score)
                        self:updateLabelSize({label=lbs,sx=0.9,sy=0.9},314)
                    end
                    if lbs2 and lbs2.setString  then
                        lbs2:setString(score)
                        self:updateLabelSize({label=lbs2,sx=0.9,sy=0.9},314)
                    end
                end
            end
        end

    end

end

function CodeGameScreenPelicanMachine:addLabToSpine( _symbol)
    local cocosName = "Socre_Pelican_Bonus_num.csb"
    if _symbol.p_symbolType == self.SYMBOL_FIX_ALL then
        cocosName = "Socre_Pelican_bonus6_num.csb"
    end
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    util_spineRemoveSlotBindNode(spineNode,"shuzi")
    local coinsView = util_createAnimation(cocosName)
    coinsView:findChild("m_lb_score"):setString("")
    if coinsView:findChild("m_lb_score2") then
        coinsView:findChild("m_lb_score2"):setString("")
    end
    
    self:util_spinePushBindNode(spineNode,"shuzi",coinsView)
    _symbol.m_csbNode = coinsView
end

function CodeGameScreenPelicanMachine:util_spinePushBindNode(spNode, slotName, bindNode)
    -- 与底层区分开
    spNode:pushBindNode(slotName, bindNode)
end

function CodeGameScreenPelicanMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)
    if not tolua.isnull(node.m_csbNode) then
        node.m_csbNode:removeFromParent()
        node.m_csbNode = nil
    end
    CodeGameScreenPelicanMachine.super.pushSlotNodeToPoolBySymobolType(self,symbolType, node)
end

function CodeGameScreenPelicanMachine:addLevelBonusSpine(_symbol)
    self:addLabToSpine( _symbol)

    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if _symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL then
        spineNode:setSkin("shuzi")
    end
end

function CodeGameScreenPelicanMachine:getBonusSkinName(symbolType)
    if symbolType == self.SYMBOL_FIX_GRAND then
        return "grand"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "major"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "minor"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "mini"
    end
    return "mini"
end

function CodeGameScreenPelicanMachine:bonusChangeShow(node)
    if node.m_csbNode then
        node.m_csbNode = nil
    end
    local bonusName = self:getBonusSkinName(node.p_symbolType)
    local ccbNode = node:getCCBNode()
    if not ccbNode then
        node:checkLoadCCbNode()
    end
    ccbNode = node:getCCBNode()
    if ccbNode then
        ccbNode.m_spineNode:setSkin(bonusName)
    end
end

function CodeGameScreenPelicanMachine:updateReelGridNode(node)
    CodeGameScreenPelicanMachine.super.updateReelGridNode(self, node)

    if not tolua.isnull(node.m_csbNode) then
        node.m_csbNode:removeFromParent()
        node.m_csbNode = nil
    end

    --重置wild皮肤
    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        local ccbNode = node:getCCBNode()
        if not ccbNode then
            node:checkLoadCCbNode()
        end
        ccbNode = node:getCCBNode()
        if ccbNode then
            ccbNode.m_spineNode:setSkin("x1")
        end
    end
    if node.p_symbolType == self.SYMBOL_FIX_SYMBOL or node.p_symbolType == self.SYMBOL_FIX_ALL then
            self:addLevelBonusSpine(node)
            self:setSpecialNodeScore({node})
    end

    --jackpot小块
    if node.p_symbolType == self.SYMBOL_FIX_GRAND or
        node.p_symbolType == self.SYMBOL_FIX_MAJOR or
            node.p_symbolType == self.SYMBOL_FIX_MINOR or 
                node.p_symbolType == self.SYMBOL_FIX_MINI then
        --更换皮肤
        self:bonusChangeShow(node)
    end
end
-- 给respin小块进行赋值
function CodeGameScreenPelicanMachine:setSpecialNodeScoreUp(param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        if symbolNode.p_symbolType == self.SYMBOL_FIX_ALL and self.m_reconnect == false then
            self.m_triggerAllSymbol = true
            -- print("m_aimAllSymbolNodeList-----------")
            if self.m_aimAllSymbolNodeList == nil then
                self.m_aimAllSymbolNodeList = {}
            end
            local has = false
            for i=1,#self.m_aimAllSymbolNodeList do
                if self.m_aimAllSymbolNodeList[i] == symbolNode then

                    has = true
                    break
                end
            end
            if has == false then
                self.m_aimAllSymbolNodeList[#self.m_aimAllSymbolNodeList+1] = symbolNode

                if symbolNode.m_csbNode then
                    local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
                    if lbs and lbs.setString  then
                        lbs:setString("")
                    end
                    local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")
                    if lbs2 and lbs2.setString  then
                        lbs2:setString("")
                    end
                end

            end
            return
        end
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self:getReSpinSymbolScoreUp(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 4)

            if symbolNode then

                if symbolNode.m_csbNode then
                    local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
                    if lbs and lbs.setString  then
                        lbs:setString(score)
                        self:updateLabelSize({label=lbs,sx=0.9,sy=0.9},314)
                    end
                    local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")
                    if lbs2 and lbs2.setString  then
                        lbs2:setString(score)
                        self:updateLabelSize({label=lbs2,sx=0.9,sy=0.9},314)
                    end
                end
            end
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 4)

            if symbolNode then

                if symbolNode.m_csbNode then
                    local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
                    if lbs and lbs.setString  then
                        lbs:setString(score)
                        self:updateLabelSize({label=lbs,sx=0.9,sy=0.9},314)
                    end
                    local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")
                    if lbs2 and lbs2.setString  then
                        lbs2:setString(score)
                        self:updateLabelSize({label=lbs2,sx=0.9,sy=0.9},314)
                    end
                end
            end
        end

    end

end

function CodeGameScreenPelicanMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = CodeGameScreenPelicanMachine.super.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_ALL then
        self:setSpecialNodeScore({reelNode})
    end
    return reelNode
end

function CodeGameScreenPelicanMachine:getSlotNodeWithPosAndTypeUp(symbolType, row, col,isLastSymbol)
    local reelNode = CodeGameScreenPelicanMachine.super.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_ALL
    then
        self:setSpecialNodeScoreUp({reelNode})
    end
    return reelNode
end

--- 是不是 respinBonus小块
function CodeGameScreenPelicanMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_ALL or
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end


function CodeGameScreenPelicanMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodePelicanSrc.PelicanJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)

end
-- 结束respin收集
function CodeGameScreenPelicanMachine:playLightEffectEnd()

    -- 通知respin结束
    self:respinOver()

end
--
function CodeGameScreenPelicanMachine:respinOver()

    self:showRespinOverView()
end

function CodeGameScreenPelicanMachine:getChipCosin(_index )
    local coins = 0
    local winlines = self.m_runSpinResultData.p_winLines or {}
    for k,_lineInfo in pairs(winlines) do
        local pos =_lineInfo.p_iconPos[1]
        if _index == pos then
            coins = _lineInfo.p_amount
            break
        end
    end
    return coins
end
function CodeGameScreenPelicanMachine:playChipCollectAnim(isDouble)

    if self.m_playAnimIndex > #self.m_chipList then
        self.m_isPlayCollect = nil
        local waitTime = 2
        if isDouble then
            self:delayCallBack(waitTime,function (  )
                self.m_reSpinbar:runCsbAction("chengbei")
                self:delayCallBack(0.75,function (  )
                    self.m_reSpinbar:showDouble()
                end)
                self:delayCallBack(55/60,function (  )
                    self.m_reSpinbar:updateRewordCoins(util_formatCoins(self.m_lightScore * 2,50))
                end)
            end)
            self:delayCallBack(waitTime + 0.75 + 55/60,function (  )
                self:playLightEffectEnd()
            end)
        else
            performWithDelay(self,function()
                self:playLightEffectEnd()
            end,waitTime)
        end
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    local index = self:getPosReelIdx(chipNode.p_rowIndex ,chipNode.p_cloumnIndex)
    if self.m_playAnimIndex > self.upSymbolNum then
        index = index + 15
    end
    local addScore = self:getChipCosin(index) 
    local nJackpotType = 0
   if chipNode.p_symbolType == self.SYMBOL_FIX_GRAND then
        nJackpotType = 1
    elseif chipNode.p_symbolType == self.SYMBOL_FIX_MAJOR then
        nJackpotType = 2
    elseif chipNode.p_symbolType == self.SYMBOL_FIX_MINOR then
        nJackpotType = 3
    elseif chipNode.p_symbolType == self.SYMBOL_FIX_MINI then
        nJackpotType = 4
    end
    local lastNum = self.m_lightScore
    self.m_lightScore = self.m_lightScore + addScore
    local function runCollect()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim(isDouble)
        else
            self:showRespinJackpot(nJackpotType, addScore, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim(isDouble)
            end)
        end
    end

    local worldPos = cc.p(self:findChild("respinBar"):getParent():convertToWorldSpace(cc.p(self:findChild("respinBar"):getPosition())))
    local endPos = cc.p(self:convertToNodeSpace(worldPos))

    local waitTime = 0.6
    if self:checkIsTopRsNode( chipNode ) then
        waitTime = 0.6
    end
    

   --最终收集阶段
   self:runEndFlyGoldAction(0,waitTime,nodePos,endPos,function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_endFanKui.mp3")
        self.m_reSpinbar:runCsbAction("shouji")
        self.m_reSpinbar:updateRewordCoins(self.m_lightScore,lastNum)

        runCollect()
        
        
    end,chipNode)
end

function CodeGameScreenPelicanMachine:checkIsTopRsNode( _rsnode )
    local topChipList = self.m_respinViewUp:getAllCleaningNode()

    for k,v in pairs(topChipList) do
        local node = v
        if node == _rsnode then
            return true
        end
    end
end

--结束移除小块调用结算特效
function CodeGameScreenPelicanMachine:reSpinEndAction()
    self.m_temp = {}
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinViewUp:getAllCleaningNode()


    local upList = self.m_respinView:getAllCleaningNode()

    self.upSymbolNum = #self.m_respinViewUp:getAllCleaningNode()

    for i=1,#upList do
        self.m_chipList[#self.m_chipList + 1] = upList[i]
    end

    local innerCollect = function(isDouble)
        if self.m_isPlayCollect == nil then
            self.m_isPlayCollect = true

            self.m_reSpinbar:updateShowStates( 1 )
            self.m_reSpinbar:updateRewordCoins(0)
            performWithDelay(self,function()
                self:playChipCollectAnim(isDouble)
            end,1.5)
        end
    end

    if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)*2  then
        innerCollect(true)
    else
        innerCollect(false)
    end



end

-- 根据本关卡实际小块数量填写
function CodeGameScreenPelicanMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_FIX_SYMBOL,
        self.SYMBOL_FIX_GRAND,
        self.SYMBOL_FIX_MAJOR,
        self.SYMBOL_FIX_MINOR,
        self.SYMBOL_FIX_MINI,
        self.SYMBOL_BLANCK,
        self.SYMBOL_FIX_ALL
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenPelicanMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_ALL, runEndAnimaName = "buling", bRandom = true}
    }


    return symbolList
end

function CodeGameScreenPelicanMachine:showRespinView()

    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:notifyTopWinCoin()
    self.m_bottomUI:checkClearWinLabel()

    --先播放动画 再进入respin
    self:clearCurMusicBg()
    
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()
    -- self:checkChangeBaseParent()
    self:playBonusTipMusicEffect()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if self:isFixSymbol(node.p_symbolType) then
                    node:runAnim("actionframe",false)
                end
            end
        end
    end

    performWithDelay(self,function()
        self:checkChangeBaseParent()
        self:playChangeScene(function()
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end,self.isShowRespinStartView)

    end,1.5)

end

--ReSpin开始改变UI状态
function CodeGameScreenPelicanMachine:changeReSpinStartUI(respinCount)
    
end

--ReSpin刷新数量
function CodeGameScreenPelicanMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)

end

function CodeGameScreenPelicanMachine:triggerReSpinOverCallFun(score)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print(
            "================== respin  server=" ..
                self.m_serverWinCoins .. "    client=" .. score .. " ===================="
        )
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    performWithDelay(self,function()
        if self.m_bProduceSlots_InFreeSpin then
            local addCoin = self.m_serverWinCoins
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self:getLastWinCoin(),false,false})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end

    end,2)

    self:changeReSpinOverUI(function()

        local coins = nil
        if self.m_bProduceSlots_InFreeSpin then
            coins = self:getLastWinCoin() or 0
        else
            coins = self.m_serverWinCoins or 0
        end
        if self.postReSpinOverTriggerBigWIn then
            self:postReSpinOverTriggerBigWIn( coins)
        end

        self:resetMusicBg(true)
        self:playGameEffect()
        self.m_iReSpinScore = 0

        if
            self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or
                self.m_bProduceSlots_InFreeSpin
         then
            --不做处理
        else
            --停掉屏幕长亮
            globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
        end
    end)

end

--ReSpin结算改变UI状态
function CodeGameScreenPelicanMachine:changeReSpinOverUI(callback)


    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:removeRespinNode()

        --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeMainUi(self.m_3RowFree )
    else
        self:changeMainUi(self.m_base )
    end
    
    self:changeRespinOverCCbName()
    performWithDelay(self,function()
        
        if callback then
            callback()
        end
    end,1)
end

--respin结束改变空信号的ccb
function CodeGameScreenPelicanMachine:changeRespinOverCCbName( )
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow,SYMBOL_NODE_TAG)
            if symbol ~= nil and self:isFixSymbol(symbol.p_symbolType) == false then
                local type = math.random(2,8)
                symbol:changeCCBByName(self:getSymbolCCBNameByType(self, type), type)
            end
        end
    end
end

function CodeGameScreenPelicanMachine:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    -- self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenPelicanMachine:showReSpinOver(strCoins,func)
    self:clearCurMusicBg()
    local dialogName = "FreeSpinOver"
    local ownerlist = {
        m_lb_coins = util_formatCoins(strCoins, 30),
    }
    local autoType   = nil
    local skinName   = "respinover"
    gLobalSoundManager:playSound("PelicanSounds/music_Pelican_respinOver.mp3")
    self:addViewToSpineTanban(dialogName, ownerlist, autoType, func, skinName)
end

function CodeGameScreenPelicanMachine:showRespinOverView(effectData)
    local strCoins=util_formatCoins(self.m_serverWinCoins,15)
    self:showReSpinOver(strCoins,function()
        self:clearSpineTanbanAddView(function (  )
            self:showGuochang(45/30,nil,function (  )
                self.m_progress:setVisible(true)
                self.upPeople:setVisible(true)
                self:changeProChildShow(true)
                self.m_effectNode:setVisible(false)
                self.m_effectNode:removeAllChildren(true)
                self:triggerReSpinOverCallFun(self.m_lightScore)
                self.m_lightScore = 0
            end)
            
        end)
    end)
end


-- --重写组织respinData信息
function CodeGameScreenPelicanMachine:getRespinSpinData()
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

function CodeGameScreenPelicanMachine:showEffect_Respin(effectData)
    -- effectData.p_isPlay = true
    if self.m_reconnect then
        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )
        --可随机的特殊信号
        local endTypes = self:getRespinLockTypes()

        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
    else
        performWithDelay(self,function()
            if self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount then

                for i=1,#self.m_slotParents do
                    local parentNode = self.m_slotParents[i].slotParent
                    local childs = parentNode:getChildren()
                    for index=1, #childs do
                        local slotNode = childs[index]
                        if slotNode.p_rowIndex <= 3 and self:isFixSymbol(slotNode.p_symbolType) then
                                -- p_rowIndex
                            slotNode:runAnim("actionframe")
                        end
                    end
                end

                CodeGameScreenPelicanMachine.super.showEffect_Respin(self,effectData)

            end
        end,1)
    end
    return true

end

function CodeGameScreenPelicanMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        if _trigger then
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * (self.m_iReelRowNum * 2 + 0.5 )))
        else
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
        end
       
    end
end

function CodeGameScreenPelicanMachine:showReSpinStartView(func)
    -- self:clearCurMusicBg()
    local dialogName = "FreeSpinOver"
    local ownerlist = {
    }
    local autoType   = nil
    local skinName   = "respinstart"
    gLobalSoundManager:playSound("PelicanSounds/music_Pelican_respin_start.mp3")
    self:addViewToSpineTanban(dialogName, ownerlist, autoType, func, skinName)
end

function CodeGameScreenPelicanMachine:playChangeScene(_func,isChoose)
    if not isChoose then
        --过场动画
        self:showGuochang(45/30,nil,function (  )
            self.isShowRespinStartView = true
            if _func then
                _func()
            end
        end)
    else
        --开始弹板
        self:showReSpinStartView(function (  )
            self:clearSpineTanbanAddView(function (  )
                --过场动画
                self:showGuochang(45/30,nil,function (  )
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    end
    
end

function CodeGameScreenPelicanMachine:showCocosLins(isShow)
    self:findChild("reel_er_1"):setVisible(isShow)
    self:findChild("reel_lines_11"):setVisible(isShow)
    self:findChild("reel_er_1_0"):setVisible(isShow)
    self:findChild("reel_lines_12"):setVisible(isShow)
end

function CodeGameScreenPelicanMachine:changeMainUi(_type )
    self:findChild("node_respin"):setVisible(false)
    self:findChild("node_baseWheel_4"):setVisible(false)
    self:findChild("Pelican_reel_down"):setVisible(true)
    self:showCocosLins(true)

    self.m_3RowFreeSpinBar:setPosition(cc.p(0,0))
    self.m_RsjackpotView:setVisible(false)
    self.m_jackpotView:setVisible(false)

    self.m_reSpinbar:setVisible(false)
    self.m_reSpinPrize:setVisible(false)

    if _type == self.m_base then
        self.m_jackpotView:setVisible(true)
        self:runCsbAction("idle1")
    elseif _type == self.m_3RowFree then
        self.m_jackpotView:setVisible(true)
        self:runCsbAction("idle2")
    elseif _type == self.m_4RowFree then
        self.m_RsjackpotView:setVisible(true)
        self.m_RsjackpotView:runCsbAction("idle",true)
        self:findChild("node_baseWheel_4"):setVisible(true)
        local changeY = self:findChild("freespinbar_4"):getPositionY() - self:findChild("freespinbar"):getPositionY()
        self.m_3RowFreeSpinBar:setPositionY(changeY)
        self.upPeople2:setPositionY(changeY - 50)
        self:runCsbAction("idle2")
        self:findChild("Pelican_reel_down"):setVisible(false)
        self:showCocosLins(false)
        
    elseif _type == self.m_respin then
        self.m_reSpinbar:updateShowStates( 0 )
        self.m_reSpinbar:setVisible(true)
        self.m_reSpinPrize:setVisible(true)
        self:findChild("node_respin"):setVisible(true)
        self.m_RsjackpotView:setVisible(true)
        self.m_RsjackpotView:runCsbAction("idle",true)
        self:runCsbAction("idle3")
    end
    
end

function CodeGameScreenPelicanMachine:hideUpReelSlots( )
    for col=1,self.m_iReelColumnNum do
        local upSlot = self:getFixSymbol(col, self.m_iReelRowNum + 1)
        if upSlot then
            upSlot:setVisible(false)
        end
    end
    
end

function CodeGameScreenPelicanMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    ******************* 收集玩法相关    
--]]
function CodeGameScreenPelicanMachine:getProgressPecent(_init)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local collectProcess = nil 
    

    -- 第一次进入取gameConfig的数据
    if  not collectProcess and _init then
        collectProcess = self.m_bonusData.collectProcess
    end

    if selfData.pos and selfData.collect and selfData.target then
        collectProcess = {}
        collectProcess.pos = selfData.pos
        collectProcess.collect = selfData.collect
        collectProcess.target = selfData.target
    end

    local maxCount = collectProcess.target or 0
    local currCount = collectProcess.collect or 0
    local percent = currCount / maxCount * 100

    return percent
end

function CodeGameScreenPelicanMachine:showEffect_collectCoin(effectData)
    --如果低bet，直接返回
    if self:getBetLevel() == 0 then 
        effectData.p_isPlay = true
        self:playGameEffect()
        return 
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusMode = selfData.bonusMode or ""
    local collectWin = selfData.collectWin

    local node = self.m_progress:findChild("Node_shoujibd")
    local progressPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newProgressPos = self:convertToNodeSpace(progressPos)
    local endPos = cc.p(newProgressPos)

    local function flyShow(startPos,endPos,func)
        local actionList = {}
        local node = util_createAnimation("Pelican_loadingbar_shouji.csb")
        local ship = util_spineCreate("Socre_Pelican_Wild",true,true)
        node:findChild("Node_1"):addChild(ship)
        self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)

        node:setPosition(startPos)
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
            node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
            node:findChild("Particle_1"):resetSystem()
        end)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            util_spinePlay(ship,"shouji",false)
            node:runCsbAction("actionframe",false)
        end)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            
        end)
        actionList[#actionList + 1] = cc.MoveTo:create(0.5, cc.p(endPos.x,endPos.y) )
        actionList[#actionList + 1] = cc.CallFunc:create(function()

            ship:removeFromParent()

            if func then
                func()
            end
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(0.5)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
            node:setVisible(false)
            node:removeFromParent()
        end)
        node:runAction(cc.Sequence:create(actionList))
    end

    
    local pecent = self:getProgressPecent()

    if #self.m_collectList > 0 then
        gLobalSoundManager:playSound("PelicanSounds/Pelican_wildCollect_fly.mp3")
    end
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        flyShow(newStartPos,endPos)
        table.remove(self.m_collectList, i)

    end
    self:delayCallBack(0.5,function (  )
        
        self.m_progress:collectFanKui()
        self.loadingIcon:showActionFrame()
        if bonusMode == "collect" or collectWin then
            self.m_progress:updatePercent(100)
        else
            self.m_progress:updatePercent(pecent)
        end
    end)

    

    local time = 0

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfData.collectWin 

    local features = self.m_runSpinResultData.p_features or {}

    --触发收集小游戏 播放完收集
    if collectWin or #features >= 2 then 
        time = (18 + 30 + 15 )/30
    end

    performWithDelay(self,function(  )

        effectData.p_isPlay = true
        self:playGameEffect()
        
    end,time)
    



end

-- function CodeGameScreenPelicanMachine:showWinJieSunaAct( )
--     self.m_jiesuanAct:setVisible(true)
--     self.m_jiesuanAct:findChild("Particle_1"):resetSystem()
--     self.m_jiesuanAct:runCsbAction("actionframe")
-- end

function CodeGameScreenPelicanMachine:showEffect_CollectBonus(effectData)

    -- gLobalSoundManager:playSound("PelicanSounds/music_Pelican_Trigger_Bonus.mp3")
    
    self:clearCurMusicBg()

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
    -- self.m_bottomUI:resetWinLabel()
    -- self.m_bottomUI:notifyTopWinCoin()
    -- self.m_bottomUI:checkClearWinLabel()
    self.m_bottomUI:showAverageBet()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = 1
    if selfData.pos == 0 then
        currentPos = 60
    else
        currentPos = selfData.pos
    end
    self.m_mapNodePos = currentPos -- 更新最新位置
    local collectWin = selfData.collectWin or 0
    local bonusMode = selfData.bonusMode or ""
    if bonusMode == "collect" then
    else
        self.m_map:updateLittleLevelCoins( self.m_mapNodePos,collectWin )
    end
    self.m_map:setMapCanTouch(false)

    self:showMapScroll(function(  )

        self.m_map:pandaMove(function(  )
            
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            -- local bonusMode = selfData.bonusMode or ""
            if bonusMode == "collect" then
                -- local currNode = self.m_map.m_mapLayer.m_vecNodeLevel[self.m_mapNodePos]
                self.m_progress:restProgressEffect(0)
                self.m_progress:runCsbAction("idle",true)
                self.m_map:mapDisappear(function (  )
                    self.m_map:setMapCanTouch(true)
                    self:resetMusicBg(true)
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            else
                local currNode = self.m_map.m_mapLayer.m_vecNodeLevel[self.m_mapNodePos]
                self:createParticleFly(0.3,currNode,collectWin,function(  )
                    self.m_map:setMapCanTouch(true)
                    local selfData = self.m_runSpinResultData
                    local beginCoins =  self.m_serverWinCoins - collectWin
                    self:updateBottomUICoins(beginCoins,collectWin,true )
                    if #self.m_runSpinResultData.p_winLines == 0 then
                        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.BONUS_GAME_EFFECT)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true})
                    end
                    self.m_progress:restProgressEffect(0)
                    self.m_progress:runCsbAction("idle",true)
                    self.m_map:mapDisappear(function(  )
                        self.m_bottomUI:hideAverageBet()
                        self:resetMusicBg(true)
                        effectData.p_isPlay = true
                        self:playGameEffect()
            
                    end)

                    
                end)
            end


        end, self.m_bonusData.map, self.m_mapNodePos,collectWin)

        
    end,false)

end

function CodeGameScreenPelicanMachine:initGameStatusData( gameData )
    CodeGameScreenPelicanMachine.super.initGameStatusData( self, gameData )
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


function CodeGameScreenPelicanMachine:createMapScroll( )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.pos or 0

    self.m_mapNodePos = currentPos
    local changeY = self:mapChangePosY()
    self:findChild("Node_map"):setPosition(cc.p(display.width/2,changeY))
    self.m_map = util_createView("CodePelicanSrc.PelicanMap.PelicanBonusMapScrollView", self.m_bonusData.map, self.m_mapNodePos,self)
    self:findChild("Node_map"):addChild(self.m_map,GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 5 )
    if display.height >= 1024 and display.height <= 1064 then
        self.m_map:setScale(1.1)
    end
    -- self.m_map:setClickPosition()
    self.m_map:setVisible(false)


end

function CodeGameScreenPelicanMachine:mapChangePosY( )
    local changeY = self.m_downPosY
    if display.height >= DESIGN_SIZE.height then
        local cutSizeY = (1660 - 1370) / (30 - self.m_downPosY)
        changeY = ((display.height - DESIGN_SIZE.height) + (150 * cutSizeY)) / cutSizeY
    else
        local cutSizeY = (1370 - 1024) / (self.m_downPosY - 200)
        changeY = ((display.height - DESIGN_SIZE.height) + (200 * cutSizeY)) / cutSizeY - 60
    end
    
    return changeY

end

function CodeGameScreenPelicanMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return false
    end

    if self.m_bonusReconnect and self.m_bonusReconnect == true then
        return false
    end

    return true
end

function CodeGameScreenPelicanMachine:hideMapScroll()

    
    if self.m_map:getMapIsShow() == true then

        self.m_bCanClickMap = false

        
        self.m_map:mapDisappear(function()
            self.m_map:setVisible(false)
            self:resetMusicBg(true)
            self.m_bCanClickMap = true
        end)
    end

end

function CodeGameScreenPelicanMachine:showMapScroll(callback,canTouch)

    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true or self:getCurrSpinMode() == AUTO_SPIN_MODE) and callback == nil then
        return
    end

    self.m_bCanClickMap = false

    if self.m_map:getMapIsShow() == true then
        -- self:resetMusicBg(true)
        self.m_map:mapDisappear(function()
            self.m_map:setVisible(false)
            self:resetMusicBg(true)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            self.m_bCanClickMap = true
        end)
        
    else

        self:clearCurMusicBg()

        self:hideMapTipView(true)
        self:removeSoundHandler( )
        self.m_map:setVisible(true)
        self.m_map:mapAppear(function()
            if canTouch then
                self:resetMusicBg(nil,"PelicanSounds/music_Pelican_map.mp3")
            else
                gLobalSoundManager:playSound("PelicanSounds/Pelican_Bonus_showMap.mp3")
            end
            
            self.m_bCanClickMap = true

            if callback then
                callback()
            end
        end)
        
 
    end

end

function CodeGameScreenPelicanMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop )
    -- free下不需要考虑更新左上角赢钱
    local endCoins = beiginCoins + currCoins
    globalData.slotRunData.lastWinCoin = self.m_serverWinCoins
    local params = {endCoins,isNotifyUpdateTop,nil,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    
    


end

-- 创建飞行粒子
function CodeGameScreenPelicanMachine:createParticleFly(time,currNode,coins,func)

    local fly = util_createAnimation("Pelican_Map_level1_qian.csb")

    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    fly:setPosition(cc.p(util_getConvertNodePos(currNode:findChild("Node_2"),fly)))
    fly:findChild("m_lb_coins"):setString(util_formatCoins(coins, 3))
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        currNode:findChild("m_lb_coins"):setString("")
    end)
    -- animation[#animation + 1] = cc.DelayTime:create(4/3)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:runCsbAction("actionframe",false)
    end)
    animation[#animation + 1] = cc.DelayTime:create(20/60)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        fly:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        fly:findChild("Particle_1"):resetSystem()
    end)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("PelicanSounds/Pelican_collect_smallCoins.mp3")
    end)
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        --反馈
        -- self:showWinJieSunaAct()
        self:playCoinWinEffectUI()
        if func then
            func()
        end
    end)
    animation[#animation + 1] = cc.DelayTime:create(0.1)
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))

    
    
end

function CodeGameScreenPelicanMachine:changeReelData()

    for i = self.m_iReelRowNum , 1, - 1 do
        if self.m_stcValidSymbolMatrix[i] == nil then
            self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
        end
    end
    

    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelRowNum,true)
    end

    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x, 
                y = rect.y, 
                width = rect.width, 
                height = columnData.p_slotColumnHeight
            }
        )
    end

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
end

function CodeGameScreenPelicanMachine:reelDownNotifyPlayGameEffect( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local fixPos = fsExtraData.wildFrame or {}
        self:changeSymbolToWild(fixPos )
    end
    

    CodeGameScreenPelicanMachine.super.reelDownNotifyPlayGameEffect( self)

end


function CodeGameScreenPelicanMachine:changeSymbolToWild(_posList )
    for i=1,#_posList do
        local index = _posList[i]
        local fixPos = self:getRowAndColByPos(index)
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            if self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ) == symbolNode.m_ccbName then 
                print("wild不处理")
            else
                symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                if symbolNode.p_symbolImage ~= nil then
                    symbolNode.p_symbolImage:removeFromParent()
                    symbolNode.p_symbolImage = nil
                end
            end
            
        end

    end

end

function CodeGameScreenPelicanMachine:showLineFrame( )

    BaseNewReelMachine.showLineFrame(self )
    -- 有连线的时候假的隐藏
    self.m_FsLockWildNode:setVisible(false)


end

function CodeGameScreenPelicanMachine:removeAllSupperWildNode( )
    self.m_FsLockWildNode:removeAllChildren()
end

function CodeGameScreenPelicanMachine:getSupperWildNode(_pos )

    return self.m_FsLockWildNode:getChildByName(_pos)
end

function CodeGameScreenPelicanMachine:initSupperWildNode(  )
    
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fixPos = fsExtraData.wildFrame or {1,5,6,7}

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName( self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD))
    local imgName = nil
    if imageName == nil then  
        print("没有开启使用滚动替代图，会导致不能新创建的wild锁定静态图")
    else
        local offsetX = 0
        local offsetY = 0
        local scale = 1
        if tolua.type(imageName) == "table" then
            imgName = imageName[1]
            if #imageName == 3 then
                offsetX = imageName[2]
                offsetY = imageName[3]
            elseif #imageName == 4 then
                offsetX = imageName[2]
                offsetY = imageName[3]
                scale = imageName[4]
            end
        end

        for i=1,#fixPos do
            local pos = fixPos[i]
            local node = cc.Node:create()
            self.m_FsLockWildNode:addChild(node)
            local wildSpr = display.newSprite(imgName)
            node:addChild(wildSpr)
            wildSpr:setScale(scale)
            wildSpr:setPositionX(offsetX)
            wildSpr:setPositionY(offsetY)
            node:setName(pos)
            node:setPosition(util_getOneGameReelsTarSpPos(self,pos))
            
        end

    end
    self.m_FsLockWildNode:setVisible(true)
    

end

function CodeGameScreenPelicanMachine:runSuperFreeSpinLockWildNode(  _func  )

    -- gLobalSoundManager:setBackgroundMusicVolume(0.1)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fixPos = fsExtraData.wildFrame or {1,5,6,7}

      
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        local maxWaitTime = 0

        for i=1,#fixPos do

            maxWaitTime = 0.2 * (i -1) 
            local pos = fixPos[i]
            local node = cc.Node:create()
            self.m_FsLockWildNode:addChild(node)
            local wildSpr = util_spineCreate("Socre_Pelican_Wild",true,true)
            node:addChild(wildSpr)
            node:setPosition(util_getOneGameReelsTarSpPos(self,pos))
            wildSpr:setVisible(false)
 
            local wildsuperSp =  self:getSupperWildNode(pos)
            if wildsuperSp then
                wildsuperSp:setVisible(false)
            end

            
            performWithDelay(node,function(  )
                local node_1 = node
                local pos_1 = pos
                local wildsuperSp_1 = wildsuperSp

                performWithDelay(node_1,function(  )
                    local node_2 = node_1
                    local pos_2 = pos_1
                    local wildsuperSp_2 = wildsuperSp_1
                    wildSpr:setVisible(true)
            
                    performWithDelay(node_2,function(  )

                        node_2:removeFromParent()

                        if wildsuperSp_2 then
                            wildsuperSp_2:setVisible(true)
                        end
                    end,48/30)
                end,6/30)



            end,maxWaitTime)
           
            
        end
        self:delayCallBack(maxWaitTime + 0.5,function (  )
            self:initSupperWildNode()
        end)
        performWithDelay(waitNode,function(  )
            
            performWithDelay(waitNode,function(  )

                gLobalSoundManager:setBackgroundMusicVolume(1)
                
                if _func then
                    _func()
                end
                
                waitNode:removeFromParent()
            end,51/30)

        end,maxWaitTime + 0.5) 
        
        

    end,30/30)




end

-- function CodeGameScreenPelicanMachine:checkIsAddLastWinSomeEffect( )
    
--     local notAdd  = false

--     if #self.m_vecGetLineInfo == 0 then
--         notAdd = true
--     end



--     local baseSpecialCoins =  self:getBaseSpecialCoins()


--     if (baseSpecialCoins ) > 0 then
--         -- special 赢钱不为0 则检测大赢
--         notAdd  = false

--     end


--     return notAdd
-- end

function CodeGameScreenPelicanMachine:getBaseSpecialCoins( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfdata.collectWin or 0 -- bonus

    return collectWin
end

function CodeGameScreenPelicanMachine:showGuochang(time,type,func)
    gLobalSoundManager:playSound("PelicanSounds/music_Pelican_baseToRespin.mp3")
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    local guoChangView = util_spineCreate("Pelican_guochang",true,true)
    self:addChild(guoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    guoChangView:setPosition(display.center)
    local actionName = "guochang"
    if type and type == 1 then
        actionName = "guochang_free"
    elseif type and type == 2 then
        actionName = "guochang_respin"
    end
    util_spinePlay(guoChangView,actionName,false)
    performWithDelay(waitNode,function (  )
        if func then
            func()
        end
    end,time)
    performWithDelay(waitNode,function (  )
        guoChangView:removeFromParent()
        waitNode:removeFromParent()
    end,2)
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenPelicanMachine:specialSymbolActionTreatment( node)
    if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --修改小块层级
        local scatterOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
        local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,scatterOrder)
        self:playScatterBonusSound(symbolNode)
    end
end

function CodeGameScreenPelicanMachine:playCustomSpecialSymbolDownAct( slotNode )

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        if slotNode and  self:isFixSymbol(slotNode.p_symbolType) then
            local bonusOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex
            local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_FIX_SYMBOL,bonusOrder)
            self:playScatterBonusSound(slotNode)
            slotNode:runAnim("buling")
        end
    end
end

function CodeGameScreenPelicanMachine:slotOneReelDown(reelCol)    
    CodeGameScreenPelicanMachine.super.slotOneReelDown(self,reelCol) 
    if reelCol == 5 then
        self.m_playWinningNotice = false
    end
end

--设置bonus scatter 信息
function CodeGameScreenPelicanMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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
    if (nextReelLong and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then     --如果有中奖预告就不播放快滚
        nextReelLong = not self.m_playWinningNotice
    end

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                if (nextReelLong and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    nextReelLong = not self.m_playWinningNotice
                end
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

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenPelicanMachine:scaleMainLayer()
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
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            local offsetScale = 1
            offsetScale = offsetScale - (DESIGN_SIZE.height - display.height) / 100 * 0.0851
            
            local offsetY = 0
            if display.height >= 1024 and display.height < 1152 then
                offsetY = offsetY + (DESIGN_SIZE.height - display.height) / 100 * 2
                mainScale = offsetScale
            elseif display.height >= 1152 and display.height < 1228 then
                offsetY = offsetY + (DESIGN_SIZE.height - display.height) / 100 * 2
                mainScale = offsetScale
            elseif display.height >= 1228 and display.height < 1370 then
                offsetY = offsetY + (DESIGN_SIZE.height - display.height) / 100 * 1.5
                mainScale = offsetScale
            end
            if display.height >1259 and display.height <=1369 then
                mainScale = 0.93
            end
            self.m_machineNode:setPositionY(offsetY)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        else

        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function CodeGameScreenPelicanMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "PelicanSounds/Pelican_scatter_down.mp3"
        local soundPathBonus = "PelicanSounds/Pelican_bonus_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
        self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = soundPathBonus
    end
end

-- 特殊信号下落时播放的音效
function CodeGameScreenPelicanMachine:playScatterBonusSound(slotNode)
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
                soundPath = self.m_scatterBulingSoundArry[1]
            end
        elseif  self:isFixSymbol(slotNode.p_symbolType) then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            else
                soundPath = self.m_bonusBulingSoundArry[1]
            end
        end

        if soundPath then
            self:playBulingSymbolSounds( iCol,soundPath,soundType )
        end
    end
end

-- 显示paytableview 界面
function CodeGameScreenPelicanMachine:showPaytableView()
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

--延迟回调
function CodeGameScreenPelicanMachine:delayCallBack(time, func)
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

function CodeGameScreenPelicanMachine:playRespinReelStopSound(colIndex)
    if not self.m_temp[colIndex] then
        self.m_temp[colIndex] = gLobalSoundManager:playSound("PelicanSounds/music_Pelican_reelStop.mp3")
    end
end

function CodeGameScreenPelicanMachine:operaUserOutCoins( )
    --金币不足
    -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
    self.m_bSlotRunning = false
    gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NoCoins)
    end
    gLobalPushViewControl:setEndCallBack(function()
        local betCoin = self:getSpinCostCoins() or toLongNumber(0)
        local totalCoin = globalData.userRunData.coinNum or 1
        if betCoin <= totalCoin then
            globalData.rateUsData:resetBankruptcyNoPayCount()
            self:showLuckyVedio()
            return
        end

        -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
        globalData.rateUsData:addBankruptcyNoPayCount()
        local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
        if view then
            view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
        else
            self:showLuckyVedio()
        end
    end)
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
    end
end

function CodeGameScreenPelicanMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenPelicanMachine.super.levelDeviceVibrate then
        CodeGameScreenPelicanMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenPelicanMachine