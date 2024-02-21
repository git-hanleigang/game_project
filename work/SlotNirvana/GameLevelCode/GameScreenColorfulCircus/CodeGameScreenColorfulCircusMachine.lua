---
-- island li
-- 2019年1月26日
-- CodeGameScreenColorfulCircusMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenColorfulCircusMachine = class("CodeGameScreenColorfulCircusMachine", BaseNewReelMachine)

-- local BaseDialog = class("BaseDialog", util_require("base.BaseView"))

local selectRespinId = 1
local selectFreeSpinId = 2

local transType1TimeCut = 60/30
local transType1TimeOver = 120/30
local transType2TimeCut = 40/30
local transType2TimeOver = 75/30

CodeGameScreenColorfulCircusMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenColorfulCircusMachine.m_chooseRepinNotCollect = false

CodeGameScreenColorfulCircusMachine.EFFECT_FISH_SWIMMING  =   GameEffect.EFFECT_LINE_FRAME + 3     --金鱼游动

CodeGameScreenColorfulCircusMachine.SYMBOL_FIX_ALL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14--107
CodeGameScreenColorfulCircusMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13--106
CodeGameScreenColorfulCircusMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 -- 105
CodeGameScreenColorfulCircusMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 --104
CodeGameScreenColorfulCircusMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 --103
CodeGameScreenColorfulCircusMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  --94
CodeGameScreenColorfulCircusMachine.SYMBOL_BLANCK = 100  --空信号

CodeGameScreenColorfulCircusMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 51 -- 收集
CodeGameScreenColorfulCircusMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- 集满bonus

CodeGameScreenColorfulCircusMachine.m_chipList = nil
CodeGameScreenColorfulCircusMachine.m_playAnimIndex = 0
CodeGameScreenColorfulCircusMachine.m_lightScore = 0

CodeGameScreenColorfulCircusMachine.m_triggerRespinRevive = nil --触发额外增加次数
CodeGameScreenColorfulCircusMachine.m_isShowRespinChoice = nil--是否显示额外弹窗
CodeGameScreenColorfulCircusMachine.m_isPlayCollect = nil  --是否正在播放收集动画
CodeGameScreenColorfulCircusMachine.m_triggerAllSymbol = nil  --是否触发 金辣椒(特殊气球)
CodeGameScreenColorfulCircusMachine.m_aimAllSymbolNodeList = {} --金辣椒列表(特殊气球)
CodeGameScreenColorfulCircusMachine.m_flyCoinsTime = 0.3
CodeGameScreenColorfulCircusMachine.m_reconnect = nil
CodeGameScreenColorfulCircusMachine.m_isRespinReelDown = false

CodeGameScreenColorfulCircusMachine.m_base = 0
CodeGameScreenColorfulCircusMachine.m_3RowFree = 1
CodeGameScreenColorfulCircusMachine.m_4RowFree = 2
CodeGameScreenColorfulCircusMachine.m_respin = 3
CodeGameScreenColorfulCircusMachine.m_duck = 4

CodeGameScreenColorfulCircusMachine.m_collectList = {}
CodeGameScreenColorfulCircusMachine.m_bonusData = {}

CodeGameScreenColorfulCircusMachine.m_bCanClickMap = nil
CodeGameScreenColorfulCircusMachine.m_bSlotRunning = nil

CodeGameScreenColorfulCircusMachine.m_iReelMinRow = 3
CodeGameScreenColorfulCircusMachine.m_iReelMaxRow = 4

CodeGameScreenColorfulCircusMachine.MAXROW_REEL_SCALE = 0.87
CodeGameScreenColorfulCircusMachine.MAXROW_REEL_POS_Y = -40

CodeGameScreenColorfulCircusMachine.MAIN_REEL_ADD_POS_Y = 10

CodeGameScreenColorfulCircusMachine.BASE_FS_RUN_STATES = 0
CodeGameScreenColorfulCircusMachine.COllECT_FS_RUN_STATES = 1

-- CodeGameScreenColorfulCircusMachine.m_superFreeSpinStart = false

local runStatus = {
    DUANG = 1,
    NORUN = 2
}

-- 构造函数
function CodeGameScreenColorfulCircusMachine:ctor()
    CodeGameScreenColorfulCircusMachine.super.ctor(self)

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

    -- self.m_superFreeSpinStart = false

    self.isShowRespinStartView = true

    self.m_betTotalCoins = 0

    self.m_betLevel = nil

    self.upClownList = {}

    self.m_playWinningNotice = false

    self.m_clownAnimIsPlay = false

    self.m_respinMulti = 1
    self.m_respinMultiBar = 1

    self.m_isLongRun = false

    self.m_isChangeBaseClown = false

    self.m_isX2Respin = false
    --init
    self:initGame()

    self.m_temp = {}
    self.m_respinQuickStop = false
    self.m_respinBulingSoundBonus = {}
    self.m_respinBulingSoundBonusSpecial = {}
    self.m_respinQuickPlayed = {}

    self.m_allRunningRespinNodes = {} --滚动的respinNode

    self.m_isBonusTrigger = false

    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
end

function CodeGameScreenColorfulCircusMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("ColorfulCircusConfig.csv", "LevelColorfulCircusConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end  

---
-- 进入关卡
--
function CodeGameScreenColorfulCircusMachine:enterLevel()
    
    self.m_reconnect = true
    
    CodeGameScreenColorfulCircusMachine.super.enterLevel(self)

end

function CodeGameScreenColorfulCircusMachine:requestSpinResult(spinType,selectIndex)

    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount-1,self.m_runSpinResultData.p_reSpinsTotalCount)
    end
    
    self.m_reconnect = false
    self.m_isRespinReelDown = false
    self.m_iBetLevel = self:getBetLevel()
    CodeGameScreenColorfulCircusMachine.super.requestSpinResult(self,spinType,selectIndex)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenColorfulCircusMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ColorfulCircus"  
end

function CodeGameScreenColorfulCircusMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local winCoinPos = coinLab:getParent():convertToWorldSpace(cc.p(coinLab:getPosition()))
    self.m_downPosY = winCoinPos.y
    local node_showTips = self.m_topUI:findChild("node_showTips")
    local node_showTipsPos = node_showTips:getParent():convertToWorldSpace(cc.p(node_showTips:getPosition()))
    self.m_topPosY = node_showTipsPos.y
    
    self.m_3RowFreeSpinBar = util_createView("CodeColorfulCircusSrc.ColorfulCircusFreespinBarView")
    self:findChild("Node_freebar"):addChild(self.m_3RowFreeSpinBar)
    self.m_3RowFreeSpinBar:setVisible(false)
    -- jackpot
    self.m_jackpotView = util_createView("CodeColorfulCircusSrc.ColorfulCircusJackPotBarView","ColorfulCircus_jackpot", self)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotView)
    self.m_jackpotView:initMachine(self)

    self.m_RsjackpotView = util_createView("CodeColorfulCircusSrc.ColorfulCircusJackPotBarView","ColorfulCircus_respin_jackpot", self)
    self:findChild("Node_respin_jackpot"):addChild(self.m_RsjackpotView)
    
    self.m_RsjackpotView:initMachine(self)
    self.m_RsjackpotView:setVisible(false)

    -- m_reSpinbar
    self.m_reSpinbar = util_createView("CodeColorfulCircusSrc.respin.ColorfulCircusReSpinBar",self)
    self:findChild("Node_respinbar"):addChild(self.m_reSpinbar)
    self.m_reSpinbar:setVisible(false)

    self.m_reSpinPrize = util_createView("CodeColorfulCircusSrc.respin.ColorfulCircusRespinPrize",self)
    self:findChild("Node_respinprize"):addChild(self.m_reSpinPrize)
    self.m_reSpinPrize:setVisible(false)
    
    
   
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    --收集条
    self.m_progress = util_createView("CodeColorfulCircusSrc.ColorfulCircusBonusProgress", self,
    self:findChild("Node_collect_xing"),
    self:findChild("Node_collect_qiqiu"),
    self:findChild("Node_collect_i"),
    self:findChild("Node_collect_tips"))
    self:findChild("Node_collect_jindutiao"):addChild(self.m_progress)
    
    --map帐篷
    self.loadingMap = util_createView("CodeColorfulCircusSrc.ColorfulCircusLoadfingMapView")
    self:findChild("Node_collect_zhangpen"):addChild(self.loadingMap)

    self.m_spineTanbanParent = cc.Node:create()
    self.m_spineTanbanParent:setOpacity(0)
    self:addChild(self.m_spineTanbanParent, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_spineTanbanParent:setPosition(display.center)

    -- self.m_FsLockWildNode = cc.Node:create()
    -- self.m_clipParent:addChild(self.m_FsLockWildNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    
    --小丑
    self.clown_base = util_spineCreate("ColorfulCircus_base_xiaochou",true,true)
    self:findChild("Node_xiaochou"):addChild(self.clown_base)
    -- util_spinePlay(self.clown_base,"idleframe",true)
    self:playClownAnim(  )
    self.clown_base:setPositionY(-40)

    table.insert(self.upClownList,self.clown_base)
    self.clown_free = util_spineCreate("ColorfulCircus_free_xiaochou",true,true)
    self:findChild("Node_xiaochou"):addChild(self.clown_free)
    self.clown_free:setVisible(false)
    self.clown_free:setPositionY(-40)
    table.insert(self.upClownList,self.clown_free)

    --respin压暗
    self.m_respinDark = util_createAnimation("ColorfulCircus_respin_yaan.csb")
    self:findChild("Node_yaan"):addChild(self.m_respinDark)
    self.m_respinDark:setVisible(false)
    --respin x2到位棋盘边框特效
    self.m_respinX2EdgeEffect1 = util_createAnimation("ColorfulCircus_respin_qipan_fankui.csb")
    self:findChild("Node_x2EffectEdge0"):addChild(self.m_respinX2EdgeEffect1)
    self.m_respinX2EdgeEffect1:setVisible(false)
    --respin x2到位棋盘边框特效
    self.m_respinX2EdgeEffect2 = util_createAnimation("ColorfulCircus_respin_qipan_fankui.csb")
    self:findChild("Node_x2EffectEdge1"):addChild(self.m_respinX2EdgeEffect2)
    self.m_respinX2EdgeEffect2:setVisible(false)

    self.m_x2Node1 = self:createX2Node()
    self.m_x2Node1:setVisible(false)
    self.m_x2Node2 = self:createX2Node()
    self.m_x2Node2:setVisible(false)


    --respin结算动画
    self.m_respinEndEffect = util_spineCreate("ColorfulCircus_dbigwin",true,true)
    self:findChild("Node_map"):addChild(self.m_respinEndEffect)
    self.m_respinEndEffect:setVisible(false)


    self.yuGaoView = util_createView("CodeColorfulCircusSrc.ColorfulCircusYuGaoView")  --jackpot
    self:findChild("Node_yaan"):addChild(self.yuGaoView)
    self.yuGaoView:setVisible(false)

    --spine背景
    self.bg1 = util_spineCreate("GameScreenColorfulCircusBg",true,true)
    self:findChild("bg"):addChild(self.bg1,10000)
    util_spinePlay(self.bg1,"idle",true)
    self.bg1:setVisible(false)

    -- 大赢前特效
    self.m_spineBigWin = util_spineCreate("ColorfulCircus_bigwin", true, true)
    self:findChild("Node_yaan"):addChild(self.m_spineBigWin, 0)
    self.m_spineBigWin:setPosition(0,0)
    self.m_spineBigWin:setVisible(false)

    self.tipsWaitNode = cc.Node:create()
    self:addChild(self.tipsWaitNode)

    --扔球动画延迟node
    self.m_actionDelayRollBall = cc.Node:create()
    self:addChild(self.m_actionDelayRollBall)


    self:addClick(self:findChild("Clown_Click"))
    self:findChild("Clown_Click"):setSwallowTouches(false)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount == 0 then
            else
                if not self.m_isAddBigWinLightEffect then
                    return
                end
            end
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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end
        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "ColorfulCircusSounds/music_ColorfulCircus_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "ColorfulCircusSounds/music_ColorfulCircus_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            self.m_winSoundsId = nil
        end)
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)


    self:changeMainUi(self.m_base )

    self:delayCallBack(5, function (  )
        self:trunBaseClown(  )  
    end)

end

function CodeGameScreenColorfulCircusMachine:createX2Node(  )
    local fly_x2_1 = util_createAnimation("ColorfulCircus_respin_x2.csb")
    local pos_x2_1 = util_convertToNodeSpace(self:findChild("Node_respinx2"), self:findChild("Node_x2pos_0"))
    self:findChild("Node_x2pos_0"):addChild(fly_x2_1)
    local backLight1 = util_createAnimation("ColorfulCircus_shuzhi_beiguang.csb")
    fly_x2_1:findChild("shuzhi_beiguang"):addChild(backLight1)
    backLight1:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
    backLight1:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    backLight1:findChild("Particle_1"):resetSystem()
    backLight1:playAction("idle", true)
    fly_x2_1:setPosition(cc.p(pos_x2_1))
    return fly_x2_1
end


function CodeGameScreenColorfulCircusMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "ColorfulCircusSounds/music_ColorfulCircus_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenColorfulCircusMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenColorfulCircusMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_3RowFreeSpinBar:changeFreeSpinByCount()
        self:freeSpinShow()
        self:changeMainUi(self.m_3RowFree )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
    else
        self.m_progress.m_FAQ:TipClick()
    end

    local pecent =  self:getProgressPecent(true)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    self.m_progress:setPercent(pecent)
    self:createMapScroll( )

    local totalBet = globalData.slotRunData:getCurTotalBet( )
    self.m_betTotalCoins = totalBet  
    self:upateBetLevel(true)

end

function CodeGameScreenColorfulCircusMachine:initRandomSlotNodes()
    CodeGameScreenColorfulCircusMachine.super.initRandomSlotNodes(self)

    self:firstInit()
end

function CodeGameScreenColorfulCircusMachine:firstInit()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                if self:isFixSymbol(slotNode.p_symbolType) then
                    self:setSymbolToClipParent(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
                    slotNode:runAnim("idleframe2", true)
                end
            end
        end
    end
end

--提层
function CodeGameScreenColorfulCircusMachine:setSymbolToClipParent(_MainClass, _iCol, _iRow, _type, _zorder)
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

function CodeGameScreenColorfulCircusMachine:addObservers()
    CodeGameScreenColorfulCircusMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        if self:isNormalStates( )  then
            if self:getBetLevel() == 0 then
                self:unlockHigherBet()
            else
                self:showMapScroll(nil)

                -- self:createPickDuckView()
                -- self.m_pickDuckView:showDuckView()
                -- self.m_pickDuckView:beginDuckGame()
                -- self:changeMainUi(self.m_duck )
            end
        end
    end,"SHOW_BONUS_MAP")

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

function CodeGameScreenColorfulCircusMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    CodeGameScreenColorfulCircusMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenColorfulCircusMachine:drawReelArea()
    CodeGameScreenColorfulCircusMachine.super.drawReelArea(self)

    self.m_clipUpParent = self.m_csbOwner["sp_reel_respin_0"]:getParent()

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenColorfulCircusMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return "Socre_ColorfulCircus_Bonus1"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_ColorfulCircus_Bonus1"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_ColorfulCircus_Bonus1"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_ColorfulCircus_Bonus1"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_ColorfulCircus_Bonus1"
    elseif symbolType == self.SYMBOL_FIX_ALL then
        return "Socre_ColorfulCircus_Bonus2"
    elseif symbolType == self.SYMBOL_BLANCK then
        return "Socre_ColorfulCircus_Blanck"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "ColorfulCircus_Wild"
    end

    return nil
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenColorfulCircusMachine:MachineRule_initGame(  )

    -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
    --     self.m_3RowFreeSpinBar:changeFreeSpinByCount()
    --     self:freeSpinShow()
    --     self:changeMainUi(self.m_3RowFree )
    -- elseif self:getCurrSpinMode() == RESPIN_MODE then
    -- else
    --     self.m_progress.m_FAQ:TipClick()
    -- end
end


---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenColorfulCircusMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenColorfulCircusMachine:levelFreeSpinOverChangeEffect()

end


function CodeGameScreenColorfulCircusMachine:changeProChildShow(isShow)
    self.loadingMap:setVisible(isShow)
end
---------------------------------------------------------------------------


----------- FreeSpin相关
--改变展示小丑
function CodeGameScreenColorfulCircusMachine:changeShowUpClown(isShow)
    if isShow then
        for i,v in ipairs(self.upClownList) do
            if isShow == i then
                v:setVisible(true)
                util_spinePlay(v,"idleframe",true)
            else
                v:setVisible(false)
            end
        end
    else
        for i,v in ipairs(self.upClownList) do
            v:setVisible(false)
        end
    end
end

function CodeGameScreenColorfulCircusMachine:freeSpinShow( )
    self.loadingMap:setVisible(false)
    -- self.loadingIcon:setVisible(false)
    self.m_progress:setVisible(false)
    self:changeProChildShow(false)
    self.m_3RowFreeSpinBar:setVisible(true)
    self:changeShowUpClown(2)
end

function CodeGameScreenColorfulCircusMachine:freeSpinOverShow( )
    self.loadingMap:setVisible(true)
    -- self.loadingIcon:setVisible(true)
    self.m_progress:setVisible(true)
    self:changeProChildShow(true)
    self.m_3RowFreeSpinBar:setVisible(false)
    self:changeShowUpClown(1)
end

-- FreeSpinstart
function CodeGameScreenColorfulCircusMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        self:hideMapTipView(true)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
           
            effectData.p_isPlay = true
            self:playGameEffect()

        else

            self:freeSpinShow()

            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            if fsWinCoin ~= 0 then
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
            else
                self.m_bottomUI:updateWinCount("")
            end

            self:levelFreeSpinEffectChange()

            self:changeMainUi(self.m_3RowFree )

            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()
                            
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFSView()    
    end,0.5)

end

-- 重写
function CodeGameScreenColorfulCircusMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    
    if self.m_runSpinResultData.p_fsWinCoins == 0 then
        return self:showDialog("FreeSpinOver_NoWins", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        local dialog = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

        local node = dialog:findChild("m_lb_coins")
        self:updateLabelSize({label=node,sx=0.95,sy=1},723)
        node = dialog:findChild("m_lb_num")
        self:updateLabelSize({label=node,sx=1.2,sy=1.2},56)

        local guang = util_createAnimation("ColorfulCircus_tanban_guang.csb")
        dialog:findChild("guang"):addChild(guang)
        guang:playAction("animation0", true)

        util_setCascadeOpacityEnabledRescursion(dialog:findChild("guang"), true)

        return dialog
    end
end

function CodeGameScreenColorfulCircusMachine:showFreeSpinOverView()
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    local strCoins=util_formatCoins(freeSpinWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:showGuochang(transType1TimeCut, transType1TimeOver, 1, function (  )
                -- self.m_progress:restProgressEffect(0)
                self:changeMainUi(self.m_base )
                self.m_effectNode:setVisible(false)
                self.m_effectNode:removeAllChildren(true)
                self:freeSpinOverShow()
                
            end, function (  )
                self:triggerFreeSpinOverCallFun()
            end, true)
    end)

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_FreeOverPopupStart.mp3")
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_FreeOverPopupOver.mp3")
    end)
    
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenColorfulCircusMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    if self.m_winSoundsId then
        
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil

    end
    self.m_bSlotRunning = true

    self:hideMapScroll()

    self:hideMapTipView()
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenColorfulCircusMachine:addSelfEffect()
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
    else
        self.m_collectList ={}

        if self.m_betLevel == 1 and globalData.slotRunData.currSpinMode ~= RESPIN_MODE and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
       
            if not self.m_chooseRepinNotCollect then
                for iCol = 1, self.m_iReelColumnNum do
                    for iRow = self.m_iReelRowNum, 1, -1 do
                        local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                        if node then
                            if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                                if not self.m_collectList then
                                    self.m_collectList = {}
                                end
                                self.m_collectList[#self.m_collectList + 1] = node
                            end
                        end
                    end
                end
            end
    
            if self.m_chooseRepinNotCollect then
                self.m_chooseRepinNotCollect = false
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
        -- local bonusMode = selfData.bonusMode or ""
        local collectWin = selfData.collectWin
        local specialWin = selfData.specialWin

        --是否触发收集小游戏
        if specialWin or collectWin then 
            -- local baseSpecialCoins =  self:getBaseSpecialCoins()
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            -- if baseSpecialCoins > 0 then
                selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
            -- else
                -- selfEffect.p_effectOrder = GameEffect.EFFECT_FIVE_OF_KIND + 1
            -- end
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
            
        end
    end  
    
end

function CodeGameScreenColorfulCircusMachine:checkIsHaveSelfEffect(_effectType, _effectSelfType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        local selfType = self.m_gameEffects[i].p_selfEffectType
        if value == _effectType and selfType == _effectSelfType then
            return true
        end
    end

    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenColorfulCircusMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FLY_COIN_EFFECT then
        self:delayCallBack(5/30, function (  )
            self:showEffect_collectCoin(effectData)    
        end)
        

    elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
        local waitTime = 0
        if self.m_runSpinResultData.p_winLines == 0 then
            waitTime = 0
        else
            waitTime = 1
        end
        self:delayCallBack(waitTime,function (  )
            self.loadingMap:showActionFrame(function (  )
                self:showEffect_CollectBonus(effectData)
                
            end)
            self.m_progress:showJiMan(function (  )
                    
            end)
            -- self.loadingIcon:jiman()
            
        end)
        
    end
    
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenColorfulCircusMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenColorfulCircusMachine:playEffectNotifyNextSpinCall( )
    self.m_bSlotRunning = false
    CodeGameScreenColorfulCircusMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    if self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end

end

function CodeGameScreenColorfulCircusMachine:slotReelDown( )
    -- if self.m_isLongRun then
    --     --scatter期待动画还原
    --     self.m_isLongRun = false
    --     local featureLen = self.m_runSpinResultData.p_features or {}

    --     for iCol = 1,self.m_iReelColumnNum do
    --         for iRow = 1,self.m_iReelRowNum do
    --             local _slotNode = self:getFixSymbol(iCol,iRow)
    --             if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --                 local isTriggerScatter = false
    --                 if featureLen and #featureLen >= 2 then
    --                     if featureLen[2] == 5 then
    --                         isTriggerScatter = true
    --                     end
    --                 end
    --                 if _slotNode:getCurAnimName() == "idleframe3" then
    --                     if isTriggerScatter then --触发的话  播完变化 不触发的话直接切
    --                     else
    --                         _slotNode:runAnim("idleframe2", true)
    --                     end
    --                 end
                    
    --             end
    --         end
    --     end
        
    -- end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenColorfulCircusMachine.super.slotReelDown(self)
end

--中奖预告
function CodeGameScreenColorfulCircusMachine:winningNotice(func)
    -- local randomNum = math.random(1,2)
    -- if randomNum == 1 then
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_winningNotice1.mp3")
    -- else
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_winningNotice2.mp3")
    -- end
    
    self.yuGaoView:setVisible(true)

    self.yuGaoView:showYuGao(1)
    util_spinePlay(self.clown_base,"actionframe_yugao",false)
    util_spineEndCallFunc(self.clown_base,"actionframe_yugao", function (  )
        -- util_spinePlay(self.clown_base,"idleframe", true)
        self:playClownAnim(  )
    end)
    self:delayCallBack(140/60,function (  )
        self.yuGaoView:setVisible(false)
        -- util_spinePlay(self.upPeople,"idleframe",true)
        if func then
            func()
        end
    end)
end


function CodeGameScreenColorfulCircusMachine:hideMapTipView( _close )
    self.m_progress.m_FAQ:hideTips()
end

--[[
    **********************高低bet相关
]]

function CodeGameScreenColorfulCircusMachine:getBetLevel( )

    return self.m_betLevel
end

function CodeGameScreenColorfulCircusMachine:getMinBet( )
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
function CodeGameScreenColorfulCircusMachine:upateBetLevel(_isinit)
    local minBet = self:getMinBet( )
    self:updatProgressLock( minBet , _isinit) 
end

function CodeGameScreenColorfulCircusMachine:updatProgressLock( minBet , _isinit)

    local betCoin = globalData.slotRunData:getCurTotalBet()
    --高倍场进度条一直解锁
    if globalData.slotRunData.isDeluexeClub == true then
        if self.m_betLevel ~= 1 then
            self.m_betLevel = 1
            -- 解锁进度条
            self.m_progress:unlock(self.m_betLevel,_isinit)
            -- self.loadingIcon:unLock()
            if _isinit then
            else
                self.m_progress.m_FAQ:hideTips()
            end
            
        end
    elseif betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
            -- 解锁进度条
            self.m_progress:unlock(self.m_betLevel,_isinit)
            -- self.loadingIcon:unLock()
            if _isinit then
            else
                self.m_progress.m_FAQ:hideTips()
            end
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            -- 锁定进度条
            self.m_progress:lock(self.m_betLevel,_isinit)
            -- self.loadingIcon:Lock()

            self.m_progress.m_FAQ:TipClick()
        end
        
    end 
end

--点击更新bet
function CodeGameScreenColorfulCircusMachine:unlockHigherBet()
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
function CodeGameScreenColorfulCircusMachine:updateNetWorkData()
    -- self.m_runSpinResultData
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local num = 0
    local numBonus = 0
    local reels = self.m_runSpinResultData.p_reels
    if reels and #reels > 0 then
        for i,v in ipairs(reels) do
            for j,type in ipairs(v) do
                if type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    num = num + 1
                end
                if self:isFixSymbol(type) then
                    numBonus = numBonus + 1
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

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        if selfData.wild_position and #selfData.wild_position > 0 then
            self:ball2WildAnim(function (  )
                self:netBackStopReel()
            end)
        else
            self:netBackStopReel()
        end

        


    else
        if num >= 3 or numBonus >= 6 then
            local random = math.random(1,100)
            if random < 40 and self.m_chooseRepinNotCollect == false then
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


function CodeGameScreenColorfulCircusMachine:netBackStopReel( )
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()  -- end

end

-- 转轮开始滚动函数
function CodeGameScreenColorfulCircusMachine:beginReel()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_effectNode:setVisible(true)
    end
    -- 
    CodeGameScreenColorfulCircusMachine.super.beginReel(self)               
end

--创建单个球变wild
function CodeGameScreenColorfulCircusMachine:addOneBall2Wild(_posIdx)
    local startFishPos = util_getOneGameReelsTarSpPos(self, _posIdx)
    local startWild = util_spineCreate("ColorfulCircus_Wild",true,true)
    util_spinePlay(startWild,"idleframe", true)
    startWild:setPosition(startFishPos)
    self.m_effectNode:addChild(startWild, _posIdx, _posIdx)
end

--扔球动画 变wild
function CodeGameScreenColorfulCircusMachine:ball2WildAnim(_func)
    self.m_effectNode:removeAllChildren(true)
    self.m_effectNode:setVisible(true)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    

    if selfData.wild_position and #selfData.wild_position > 0 then
        self.yuGaoView:setVisible(true)

        local spineAnim = "actionframe_yugao"
        if #selfData.wild_position <= 5 then
            spineAnim = "actionframe_yugao3"
            self.yuGaoView:showYuGao(3)
        else
            spineAnim = "actionframe_yugao"
            self.yuGaoView:showYuGao(2)
        end
        util_spinePlay(self.clown_free,spineAnim,false)
        util_spineEndCallFunc(self.clown_free,spineAnim, function (  )
            util_spinePlay(self.clown_free,"idleframe", true)
        end)

        local temp = {}
        local randomWildPos = {}
        for i=1,#selfData.wild_position do
            table.insert(temp, selfData.wild_position[i])
        end
        local cnt = #temp
        for i=1,cnt do
            local rIdx = math.random(1, #temp)
            table.insert(randomWildPos, temp[rIdx])
            table.remove(temp, rIdx)
        end

        gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_free_ballfly.mp3")

        self:delayCallBack(10/30,function (  )
            self:flyBall(0, function (  )
                _func()
            end, randomWildPos)
        end)

        self:delayCallBack(200/60,function (  )
            
            self.yuGaoView:setVisible(false)
        end)

        
    end

end

function CodeGameScreenColorfulCircusMachine:flyBall(index, func, posArray)
    index = index + 1
    local node = util_createAnimation("ColorfulCircus_free_qiu.csb")
    local randomColor = math.random(1, 3)
    node:findChild("huang"):setVisible(randomColor == 1)
    node:findChild("lv"):setVisible(randomColor == 2)
    node:findChild("hon"):setVisible(randomColor == 3)

    node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
    node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    node:findChild("Particle_1"):resetSystem()

    self.m_effectNode:addChild(node, 100)
    local startP = util_getConvertNodePos(self:findChild("Node_xiaochou"), node)
    startP = cc.pAdd(startP, cc.p(0, 300))

    local posIdx = posArray[index]
    local pos = self:getRowAndColByPos(posIdx)
    local col = pos.iY
    local row = pos.iX

    local reelNode = self:findChild("sp_reel_" .. col - 1)
    local reelNodePos = util_convertToNodeSpace(reelNode, self.m_effectNode)
    local changeP = reelNodePos
    local reelH = self.m_fReelHeigth or 366
    changeP = cc.pAdd(changeP, cc.p(self.m_SlotNodeW/2, reelH))


    local posX = self.m_SlotNodeW * 0.5
    local posY = (row - 0.5) * self.m_SlotNodeH
    local endPos = cc.pAdd(reelNodePos, cc.p(posX, posY))
    -- local endPos = util_getOneGameReelsTarSpPos(self, posIdx)

    node:setPosition(startP)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(0)
    

    local time = 0.3

    local bez=cc.BezierTo:create(time,{cc.p(changeP.x, startP.y),changeP
        ,endPos})

        actionList[#actionList + 1] = bez

    -- actionList[#actionList + 1] = cc.MoveTo:create(time,endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        
        gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_free_ballfly_singleend.mp3")

        self:playExplosion(endPos, function (  )
            self:addOneBall2Wild(posIdx)
        end)
        node:findChild("huang"):setVisible(false)
        node:findChild("lv"):setVisible(false)
        node:findChild("hon"):setVisible(false)
        
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(2)
    actionList[#actionList + 1] = cc.CallFunc:create(function() 
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))

    --(130 - 10)/8
    self:delayCallBack(time,function (  )
        if index >= #posArray then
            if func then
                func()
            end
            return
        else
            self:flyBall(index, func, posArray)
        end
    end)
end

function CodeGameScreenColorfulCircusMachine:playExplosion(pos, _func)
    local node = util_createAnimation("ColorfulCircus_paodan.csb")
    self.m_effectNode:addChild(node, 50)
    node:setPosition(cc.p(pos))
    node:runCsbAction("actionframe", false, function (  )
        node:removeFromParent()
    end)
    self:delayCallBack(10/60,function (  )
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenColorfulCircusMachine:refreshFreeSpinWildsSlotDownFunc(reelCol )
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE or not selfData or not selfData.wild_position then
        return
    end

    local wildPos = selfData.wild_position
    for k, index in ipairs(wildPos) do
        local startPos = self:getRowAndColByPos(index)
        if startPos.iY == reelCol then
            local fixNode = self:getFixSymbol(startPos.iY , startPos.iX)
            fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)

            fixNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - fixNode.p_rowIndex)

        end
    end

    if reelCol == self.m_iReelColumnNum then
        
        self.m_actionDelayRollBall:stopAllActions()
        self.m_effectNode:setVisible(false)
        self.m_effectNode:removeAllChildren(true)

    end

end

--[[
    单列滚动停止
]]
function CodeGameScreenColorfulCircusMachine:slotOneReelDownFinishCallFunc( reelCol )
    CodeGameScreenColorfulCircusMachine.super.slotOneReelDownFinishCallFunc(self,reelCol)
    self:refreshFreeSpinWildsSlotDownFunc( reelCol )
end

function CodeGameScreenColorfulCircusMachine:showEffect_LineFrame(effectData)

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        self.m_effectNode:setVisible(false)
    end
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfData.collectWin or 0
    if collectWin > 0 then
        self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin - collectWin
        globalData.slotRunData.lastWinCoin = self.m_iOnceSpinLastWin
    end

    return CodeGameScreenColorfulCircusMachine.super.showEffect_LineFrame(self,effectData)
    

end

--[[
    *************** 选择玩法
--]]
---
-- 显示bonus 触发的小游戏
function CodeGameScreenColorfulCircusMachine:showEffect_Bonus(effectData)

    self.m_isBonusTrigger = true
    local bonusEffect = function ()
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

        self:bgMusicDown(1)

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

                self:playSpineAnim(self.clown_base, "actionframe2", false, function()
                    -- self:playSpineAnim(self.clown_base, "idleframe", true)
                    self:playClownAnim(  )
                end)

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
    
        end, 10/30)
            
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    end

    self:delayCallBack(0.5, function ()
        bonusEffect()
    end)

    return true
end

function CodeGameScreenColorfulCircusMachine:getScatterList( )
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
function CodeGameScreenColorfulCircusMachine:showScatterTrigger(num,scList,callFun)

    local animTime = 0

    for i = 1, num do
        local slotNode = nil
        if scList[i] then
            slotNode = scList[i]
        end
        if slotNode ~= nil then --这里有空的没有管
            if slotNode.p_symbolType == 90 then --设置idleframe
                slotNode:setIdleAnimName("idleframe2")
            end
            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

function CodeGameScreenColorfulCircusMachine:showBonusGameView( effectData )
   
    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    self.m_bottomUI:checkClearWinLabel()
    self:show_Choose_BonusGameView(effectData)
end

function CodeGameScreenColorfulCircusMachine:show_Choose_BonusGameView(effectData)
    
    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_choose_feature.mp3")

    local chooseView = util_createView("CodeColorfulCircusSrc.ColorfulCircusChooseView",self)
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
            --free
            self:showGuochang(transType1TimeCut, transType1TimeOver, 1,function (  )
                self:freeSpinShow()
                self:bonusOverAddFreespinEffect( )
                effectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮
            end, function()
            end)
        end
    end)
end


function CodeGameScreenColorfulCircusMachine:bonusOverAddFreespinEffect( )
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

function CodeGameScreenColorfulCircusMachine:dealSmallReelsSpinStates( )

    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false
    end

    CodeGameScreenColorfulCircusMachine.super.dealSmallReelsSpinStates(self )

end

function CodeGameScreenColorfulCircusMachine:requestSpinReusltData()

    CodeGameScreenColorfulCircusMachine.super.requestSpinReusltData(self)

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

function CodeGameScreenColorfulCircusMachine:playEffectNotifyChangeSpinStatus( )
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

function CodeGameScreenColorfulCircusMachine:spinResultCallFun(param)
    local isSucc = param[1]
    local spinData = param[2]

    CodeGameScreenColorfulCircusMachine.super.spinResultCallFun(self,param)
    if isSucc then

         --respin中触发了 额外奖励次数
        if spinData.result.respin.extra and spinData.result.respin.extra.options then
            self.m_triggerRespinRevive = true
        end

    end

end

-- 继承底层respinView
function CodeGameScreenColorfulCircusMachine:getRespinView()
    return "CodeColorfulCircusSrc.respin.ColorfulCircusRespinView"
end
-- 继承底层respinNode
function CodeGameScreenColorfulCircusMachine:getRespinNode()
    return "CodeColorfulCircusSrc.respin.ColorfulCircusRespinNode"
end
--触发respin
function CodeGameScreenColorfulCircusMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize(true)
    end

    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true
    self:changeMainUi(self.m_respin )

    self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
    
    self.m_reSpinPrize:updateView(0)
    self.m_reSpinPrize:runCsbAction("idleframe3")

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
            --  return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
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
function CodeGameScreenColorfulCircusMachine:isRespinInit()
    -- return true
    return self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount
end
--强制 执行变黑
function CodeGameScreenColorfulCircusMachine:respinInitDark()
    if self:isRespinInit() then
        local respinList = self.m_respinViewUp:getAllCleaningNode()
        for i=1,#respinList do
            respinList[i]:setVisible(false)
        end
    end
end

function CodeGameScreenColorfulCircusMachine:initRespinView(endTypes, randomTypes)
    -- self.upPeople:setVisible(false)
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
            end,2.2) --转场时间点  到开始的时间
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
function CodeGameScreenColorfulCircusMachine:runNextReSpinReel(_isDownStates)

    -- print("runNextReSpinReel!!!!!!!!!!!")
    if self.m_triggerRespinRevive then --触发respin奖励次数
        if  self.m_isShowRespinChoice then
            return
        end
        self.m_isShowRespinChoice = true
        --轮盘不允许点击
        -- print("runNextReSpinReel!!!!!!!!!!!111111111")
        self:delayCallBack(1,function()
            gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_choose.mp3")
            local view=util_createView("CodeColorfulCircusSrc.respin.ColorfulCircusRespinChose",self.m_runSpinResultData.p_rsExtraData,function()
                -- self.m_reSpinbar:runCsbAction("fankui", false, function (  )
                --     self.m_reSpinbar:runCsbAction("actionframe", false)
                -- end)
                self.m_reSpinbar:runCsbAction("actionframe", false)
                self:delayCallBack(11/60, function (  )     --第11帧播放对应数字变化
                    self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
                end)
                gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_choose_timesrefresh.mp3")

                self:delayCallBack(42/60, function (  )     --加个spin计数板动效
                    self.m_triggerRespinRevive = false
                    self.m_isShowRespinChoice = false
                    -- self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
                    CodeGameScreenColorfulCircusMachine.super.runNextReSpinReel(self)
                    if _isDownStates then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                    end
                end)
                
            end,self)
            if globalData.slotRunData.machineData.p_portraitFlag then
                view.getRotateBackScaleFlag = function(  ) return false end
            end
            view:findChild("root"):setScale(self.m_machineRootScale)
            -- view:findChild("root"):setScale(0.1)
            gLobalViewManager:showUI(view)

            -- print("ColorfulCircusRespinChose!!!!!!!!!!!111111111")
        end)
    else
        CodeGameScreenColorfulCircusMachine.super.runNextReSpinReel(self)
        if _isDownStates then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end

--下面气球往上飞
function CodeGameScreenColorfulCircusMachine:flyDarkIcon(func)
    if self.m_flyIndex > #self.m_chipList or self.m_flyIndex > #self.m_chipListUp then
        return
    end
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))

    local nodeEndSymbol =  self.m_chipListUp[self.m_flyIndex]
    local endPos = nodeEndSymbol:getParent():convertToWorldSpace(cc.p(nodeEndSymbol:getPosition()))

    self:runFlySymbolAction(nodeEndSymbol,0.01,21/30,startPos,endPos,function()
        -- self.m_flyIndex = self.m_flyIndex + 1
        -- if  self.m_flyIndex == #self.m_chipList + 1 then
        --     if func then
        --         func()
        --     end
        -- else
        --     self:flyDarkIcon(func)
        -- end
    end)

    self:delayCallBack(10/30, function ()
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

--下面棋盘气球往上棋盘飞
function CodeGameScreenColorfulCircusMachine:runFlySymbolAction(endNode,time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node = util_spineCreate("Socre_ColorfulCircus_Bonus1",true,true)
    -- local node = util_createAnimation("Socre_ColorfulCircus_Bonus1.csb")
    node:setVisible(false)

    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        util_spinePlay(node,"fly2",false)
        
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_flyUp.mp3")
    end)
    local bez=cc.BezierTo:create(flyTime,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
    cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
    local ease = cc.EaseQuadraticActionOut:create(bez)
    actionList[#actionList + 1] = ease
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_flyUp_fanKui.mp3")
        if callback then
            callback()
        end
    end)
    -- actionList[#actionList + 1] = cc.DelayTime:create(14/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        node:setVisible(false)
        node:removeFromParent()
        endNode:setVisible(true)
        endNode:runAnim("shouji2", false, function()
            endNode:runAnim("idleframe2", true)
        end)
    end)
    node:runAction(cc.Sequence:create(actionList))
end

--特殊气球 prize栏飞向气球
function CodeGameScreenColorfulCircusMachine:flyCenterToSymbol(func)
    -- print("flyCenterToSymbol++++++")
    -- print(self.m_flyIndex)
    -- print(#self.m_aimAllSymbolNodeList)
    if self.m_flyIndex > #self.m_aimAllSymbolNodeList then
        return
    end
    local startPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(self.m_reSpinPrize:getPosition()))
    local symbolNode =  self.m_aimAllSymbolNodeList[self.m_flyIndex]
    if symbolNode:getParent() == nil or  symbolNode:getPosition() == nil  then
        -- print("parent pos nil++++++")
        self.m_flyIndex = self.m_flyIndex + 1
        self:flyCenterToSymbol(func)
        return
    end
    local endPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
    symbolNode:runAnim("shouji", false, function (  )
        symbolNode:runAnim("idleframe2",true)
    end)
    -- self:delayCallBack(36/30,function (  )
    --     symbolNode:runAnim("idleframe2",true)
    -- end)
    self.m_reSpinPrize:runCsbAction("actionframe2")
    gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_respin_spBonus_fly_start.mp3")
    self:runFlyGoldAction(15/30, 10/30,startPos,endPos,function()
        local score = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple
        -- symbolNode
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        score = util_formatCoins(score, 3)
        if symbolNode.m_csbNode then
            symbolNode.m_csbNode:setVisible(true)

            self:setSymbolString(symbolNode, score)

            self:addAllOtherRespinSymbolLab(symbolNode )
            symbolNode.m_csbNode:runCsbAction("shouji")

            if symbolNode.m_csbNodeColorEffect then
                if not tolua.isnull(symbolNode.m_csbNodeColorEffect) then
                    symbolNode.m_csbNodeColorEffect:setVisible(true)
                    self:playSpineAnim(symbolNode.m_csbNodeColorEffect, "shouji", false, function()
                        -- if symbolNode and not tolua.isnull(symbolNode.m_csbNodeColorEffect) then
                        --     symbolNode.m_csbNodeColorEffect:setVisible(false)
                        -- end
                        
                    end)
                end
            end
        end
        
        self.m_flyIndex = self.m_flyIndex + 1

        self:delayCallBack(15/30,function (  )
            -- symbolNode:runAnim("over",false,function (  )
            --     symbolNode:runAnim("idleframe3",true)
            -- end)
            -- self:delayCallBack(16/30,function (  )
                
                if  self.m_flyIndex == #self.m_aimAllSymbolNodeList + 1 then
                    -- self:allOtherRespinSymbolDark(false)
                    -- print("flyend nil ++++++++++++")
                    self.m_aimAllSymbolNodeList = {}
                    if func then
                        func()
                    end
                else
                    self:flyCenterToSymbol(func)
                end
            -- end)
        end)
        
    end)

end

--prize 飞到特殊气球上
function CodeGameScreenColorfulCircusMachine:runFlyGoldAction(time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("ColorfulCircus_respin_tuoweilizi_teshu.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    node:setVisible(false)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        node:findChild("Particle_1"):resetSystem()
        node:findChild("Particle_1_0"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("Particle_1_0"):setPositionType(0)   --设置可以拖尾
        node:findChild("Particle_1_0"):resetSystem()
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_respin_spBonus_fly.mp3")
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        node:findChild("Particle_1_0"):stopSystem()--移动结束后将拖尾停掉
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(2)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenColorfulCircusMachine:runEndFlyGoldAction(time,flyTime,startPos,endPos,callback,chipNode,callback2,isDouble)
    local collectName = "shouji3"
    local delayTime = 0
    local isJackpot = false
    if chipNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
    elseif chipNode.p_symbolType == self.SYMBOL_FIX_ALL then
        -- delayTime = 9/30
    else
        if isDouble then
            collectName = "shoujix2"
        else
            collectName = "shouji4"
        end
        delayTime = 24/60
        isJackpot = true
    end

    local actionList = {}
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if chipNode then
            chipNode:runAnim(collectName)
            if isJackpot then
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_endCollectScale.mp3")
            end
            

            if self:isOtherRespinSymbol2(chipNode.p_symbolType) and chipNode.m_csbNode then
                if self.SYMBOL_FIX_ALL == chipNode.p_symbolType then
                    chipNode.m_csbNode:runCsbAction("shouji3")
                else
                    chipNode.m_csbNode:runCsbAction("dark1")
                end
                
            end
        end
    end)
    -- actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("ColorfulCircus_respin_prize_tuoweilizi.csb")
    
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)
    node:setVisible(false)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        node:findChild("Particle_1"):resetSystem()
    end)
    
    actionList[#actionList + 1] = cc.DelayTime:create(delayTime)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_endFly.mp3")
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)
    if isJackpot then
        actionList[#actionList + 1] = cc.DelayTime:create(25/60)
    end
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback2 then
            callback2()
        end
    end)
    -- actionList[#actionList + 1] = cc.DelayTime:create(0.3)
    
    actionList[#actionList + 1] = cc.DelayTime:create(2)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenColorfulCircusMachine:showRespinPrize(iRow, iCol)
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
function CodeGameScreenColorfulCircusMachine:flyCoins(func)
    if self.m_flyIndex > #self.m_chipList then
        return
    end

    -- fly
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))
    local endNode = self.m_reSpinPrize
    local endPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))

    -- self:runFlyCoinsAction(0.01,18/30,startPos,endPos,function()
    self:runFlyCoinsAction(0.01,0.4,startPos,endPos,function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_flyCoins_fankui.mp3")
        self.m_reSpinPrize:runCsbAction("actionframe")
        self:showRespinPrize(symbolStartNode.p_rowIndex,symbolStartNode.p_cloumnIndex)
        self.m_flyIndex = self.m_flyIndex + 1
        if  self.m_flyIndex >= #self.m_chipList + 1 then
            if func then
                func()
            end
        else
            self:flyCoins(func)
        end
    end, symbolStartNode)

end

function CodeGameScreenColorfulCircusMachine:runFlyCoinsAction(time,flyTime,startPos,endPos,callback,chipNode)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("ColorfulCircus_respin_prize_tuoweilizi.csb")
    node:setVisible(false)
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if chipNode then
            chipNode:runAnim("shouji", false, function (  )
                chipNode:runAnim("idleframe2", true)
            end)
        end
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        node:findChild("Particle_1"):resetSystem()
        -- util_spinePlay(node,"actionframe3",false)
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_flyCoins.mp3")
    end)
    local moveto=cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = moveto
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(2)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))

end
----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenColorfulCircusMachine:reateRespinNodeInfoUp()
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
function CodeGameScreenColorfulCircusMachine:getBounsScatterDataZorder(symbolType )
   
    local order = CodeGameScreenColorfulCircusMachine.super.getBounsScatterDataZorder(self,symbolType )
    if self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    
    return order

end

function CodeGameScreenColorfulCircusMachine:getReelPosUp(col)

    local reelNode = self:findChild("sp_reel_respin_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

--- respin 快停
function CodeGameScreenColorfulCircusMachine:quicklyStop()
    self.m_respinQuickStop = true
    CodeGameScreenColorfulCircusMachine.super.quicklyStop(self)
    self.m_respinViewUp:quicklyStop()
end

--开始滚动
function CodeGameScreenColorfulCircusMachine:startReSpinRun()

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
    else
        self.m_respinViewUp:startMove()
    end
    
    CodeGameScreenColorfulCircusMachine.super.startReSpinRun(self)
    self.m_temp = {}
    self.m_respinQuickStop = false
    self.m_respinBulingSoundBonus = {}
    self.m_respinBulingSoundBonusSpecial = {}
    self.m_respinQuickPlayed = {}

    self.m_allRunningRespinNodes = {}
    for i=1,#self.m_respinView.m_respinNodes do
        local respinNode = self.m_respinView.m_respinNodes[i]
        if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_allRunningRespinNodes[#self.m_allRunningRespinNodes + 1] = respinNode
        end
    end
    for i=1,#self.m_respinViewUp.m_respinNodes do
        local respinNode = self.m_respinViewUp.m_respinNodes[i]
        if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_allRunningRespinNodes[#self.m_allRunningRespinNodes + 1] = respinNode
        end
    end
end

function CodeGameScreenColorfulCircusMachine:playRespinReelStopSound(colIndex)
    if not self.m_temp[colIndex] then
        self.m_temp[colIndex] = gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_reelStop.mp3")
    end
end

--respin buling音效
function CodeGameScreenColorfulCircusMachine:playRespinBulingSound(col, endNode)
    if not endNode or tolua.isnull(endNode) then
        return
    end
    if not self.m_allRunningRespinNodes then
        return
    end

    local isHaveSpecialBonus = false
    local isHaveBonus = false
    local isQuickHaveSpecialBonus = false
    local isQuickHaveBonus = false
    for i=1,#self.m_allRunningRespinNodes do
        local respinNode = self.m_allRunningRespinNodes[i]
        if respinNode and respinNode.m_lastNode and not tolua.isnull(respinNode.m_lastNode) then
            if self:isFixSymbol(respinNode.m_lastNode.p_symbolType) then
                if respinNode.p_colIndex == endNode.p_cloumnIndex then
                    if endNode.p_symbolType == self.SYMBOL_FIX_ALL then
                        isHaveSpecialBonus = true
                    else
                        isHaveBonus = true
                    end
                end
                
                if endNode.p_symbolType == self.SYMBOL_FIX_ALL then
                    isQuickHaveSpecialBonus = true
                else
                    isQuickHaveBonus = true
                end
            end
        end
    end


    if self.m_respinQuickStop then
        if isQuickHaveSpecialBonus then
            if not self.m_respinQuickPlayed[endNode.p_symbolType] then
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_respin_spBonus_down.mp3")
                self.m_respinQuickPlayed[endNode.p_symbolType] = 1
            end
        elseif isQuickHaveBonus then
            if not self.m_respinQuickPlayed[endNode.p_symbolType] then
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_down.mp3")
                self.m_respinQuickPlayed[endNode.p_symbolType] = 1
            end
        end
        
    else
        -- if symbolType == 107 then
        --     if not self.m_respinBulingSoundBonusSpecial[col] then
        --         gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_respin_spBonus_down.mp3")
        --         self.m_respinBulingSoundBonusSpecial[col] = 1
        --     end
        -- else
        --     if not self.m_respinBulingSoundBonus[col] then
        --         gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_down.mp3")
        --         self.m_respinBulingSoundBonus[col] = 1
        --     end
        -- end

        if isHaveSpecialBonus then
            if not self.m_respinBulingSoundBonusSpecial[col] then
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_respin_spBonus_down.mp3")
                self.m_respinBulingSoundBonusSpecial[col] = 1
            end
        elseif isHaveBonus then
            if not self.m_respinBulingSoundBonus[col] then
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_down.mp3")
                self.m_respinBulingSoundBonus[col] = 1
            end
        else
        end
    end
end

---判断结算
function CodeGameScreenColorfulCircusMachine:reSpinReelDown(addNode)
    if self.m_isRespinReelDown then
        return
    end
    self.m_isRespinReelDown = true
 
    local inner = function(_isHaveSpecialSymbol)

        self:setGameSpinStage(STOP_RUN)

        self:updateQuestUI()
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
            self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            --quest
            self:updateQuestBonusRespinEffectData()
            
            local time = 0
            if _isHaveSpecialSymbol then
                time = 15/60
            else
                time = 25/30
            end
            performWithDelay(self,function()
                -- 获得所有固定的respinBonus小块
                -- local upList = self.m_respinViewUp:getAllCleaningNode()

                -- local List = self.m_respinView:getAllCleaningNode()
                -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_respin_endCollect.mp3")
                -- for i,v in ipairs(List) do
                --     local tempNode = List[i]
                --     tempNode:runAnim("actionframe")
                -- end
                -- for i,v in ipairs(upList) do
                --     local tempUpNode = upList[i]
                --     tempUpNode:runAnim("actionframe")
                -- end
                --结束
                self:reSpinEndAction()
            end, time)

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
    -- print("down inner before!!!!!!!!!!!")
    -- print(self.m_triggerAllSymbol)
    -- if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.sp then
    -- end
    
    -- if self.m_triggerAllSymbol == false and #self.m_runSpinResultData.p_rsExtraData.sp > 0 then
    --     local a = 1
    -- end
    -- if self.m_triggerAllSymbol then
    --此处修改为用服务器数据判断
    if #self.m_runSpinResultData.p_rsExtraData.sp and #self.m_runSpinResultData.p_rsExtraData.sp > 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        -- self:delayCallBack(0.5,function (  )
            -- self:allOtherRespinSymbolDark(true)
        -- end)
        -- print("111111")
        self:delayCallBack(25/30,function (  )
            self.m_flyIndex = 1
            self:sortSpecialBonus(  )
            -- print("222222")
            self:flyCenterToSymbol(function()
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                -- print("down inner after!!!!!!!!!!!")
                -- print(self.m_triggerAllSymbol)
                self.m_triggerAllSymbol = false
                self.m_aimAllSymbolNodeList = {}
                inner(true)
            end)
        end)
    else
        inner(false)
    end
end

--排序 先飞上面栏特殊气球
function CodeGameScreenColorfulCircusMachine:sortSpecialBonus(  )
    if not self.m_aimAllSymbolNodeList then
        return
    end
    if #self.m_aimAllSymbolNodeList < 0 then
        return
    end
    table.sort(self.m_aimAllSymbolNodeList, function(a, b)
        local respinView1 = a:getParent()
        local respinView2 = b:getParent()

        if respinView1 == self.m_respinViewUp and respinView2 == self.m_respinView then
            return true
        elseif respinView1 == self.m_respinView and respinView2 == self.m_respinViewUp then
            return false
        else
            if a.p_cloumnIndex == b.p_cloumnIndex then
                return a.p_rowIndex > b.p_rowIndex
            else
                return a.p_cloumnIndex < b.p_cloumnIndex
            end
            -- local posA = self:getPosReelIdx(a.p_rowIndex, a.p_cloumnIndex)
            -- local posB = self:getPosReelIdx(b.p_rowIndex, b.p_cloumnIndex)
            -- return posA < posB
        end
    end)
end

function CodeGameScreenColorfulCircusMachine:isOtherRespinSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end

function CodeGameScreenColorfulCircusMachine:isOtherRespinSymbol2(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or self.SYMBOL_FIX_ALL then
        return true
    end
    return false
end

-- function CodeGameScreenColorfulCircusMachine:checkIsShowLight( )
--     local upList = self.m_respinViewUp:getFixSlotsNode()
--     local List = self.m_respinView:getFixSlotsNode()
--     for i=1,#upList do
--         List[#List + 1] = upList[i]
--     end
--     for i,v in ipairs(List) do
--         v.isLight = 2
--     end
--     for i,v in ipairs(self.m_aimAllSymbolNodeList) do
--         for j,k in ipairs(List) do
--             if v.p_cloumnIndex == k.p_cloumnIndex and 
--                 v.p_rowIndex == k.p_rowIndex and 
--                     v.p_symbolType == k.p_symbolType and
--                         v:getParent() == k:getParent() then
--                             k.isLight = 1
--             else
--                 if k.isLight then
--                     if k.isLight ~= 1 then
--                         k.isLight = 2
--                     end
--                 else
--                     k.isLight = 2
--                 end
--             end
--         end
--     end
--     return List
-- end

function CodeGameScreenColorfulCircusMachine:addAllOtherRespinSymbolLab(_symbolNode )
    local lbs = _symbolNode.m_csbNode:findChild("m_lb_score")
    local str = lbs:getString()

    if not tolua.isnull(_symbolNode.m_csbNode) then
        _symbolNode.m_csbNode:removeFromParent()
        _symbolNode.m_csbNode = nil
    end

    self:addLabToSpine( _symbolNode)


    self:setSymbolString(_symbolNode, str)
end

-- function CodeGameScreenColorfulCircusMachine:allOtherRespinSymbolDark(isDark)
--     local List = self:checkIsShowLight()

--     for i,v in ipairs(List) do
--         if v.isLight and v.isLight == 2 then
--             if isDark then
--                 v:runAnim("dark1",false)
--                 if v.m_csbNode then
--                     if self:isOtherRespinSymbol2(v.p_symbolType) then
--                         self:addAllOtherRespinSymbolLab(v )
--                         v.m_csbNode:runCsbAction("dark1")
--                     end
--                 end
--             else
--                 v:runAnim("dark2",false,function (  )
--                     -- if v.p_symbolType == self.SYMBOL_FIX_ALL then
--                         -- v:runAnim("idleframe3",true)
--                     -- else
--                         v:runAnim("idleframe2",true)
--                     -- end
--                 end)
--                 if v.m_csbNode then
--                     if self:isOtherRespinSymbol2(v.p_symbolType) then
--                         self:addAllOtherRespinSymbolLab(v )
--                         v.m_csbNode:runCsbAction("dark2")
--                     end
--                 end
--             end
--         end

--     end

-- end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenColorfulCircusMachine:checkFeatureOverTriggerBigWin( winAmonut , feature)
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
    if winRatio >= self.m_HugeWinLimitRate then
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
function CodeGameScreenColorfulCircusMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    else
        if self:isFixSymbolJackpot(node.p_symbolType) then
            if self.m_isX2Respin then
                node:runAnim("idleframe4", true)
            else
                node:runAnim("idleframe2", true)
            end
        else
            node:runAnim("idleframe2", true)
            if self:isOtherRespinSymbol2(node.p_symbolType) and node.m_csbNode then
                node.m_csbNode:runCsbAction("idleframe")
            end
        end
    end
end
--结束移除小块调用结算特效
function CodeGameScreenColorfulCircusMachine:removeRespinNode()
    CodeGameScreenColorfulCircusMachine.super.removeRespinNode(self)
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

--重写
--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenColorfulCircusMachine:checkChangeRespinFixNode(node)
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

function CodeGameScreenColorfulCircusMachine:MachineRule_respinTouchSpinBntCallBack()

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
function CodeGameScreenColorfulCircusMachine:stopRespinRun()

    CodeGameScreenColorfulCircusMachine.super.stopRespinRun(self)

    local storedNodeInfoUp = self:getRespinSpinDataUp()
    local unStoredReelsUp = self:getRespinReelsButStoredUp(storedNodeInfoUp)
    self.m_respinViewUp:setRunEndInfo(storedNodeInfoUp, unStoredReelsUp)
end
function CodeGameScreenColorfulCircusMachine:getMatrixPosSymbolTypeUp(iRow, iCol)
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
function CodeGameScreenColorfulCircusMachine:getRespinSpinDataUp()
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
function CodeGameScreenColorfulCircusMachine:getRespinReelsButStoredUp(storedInfo)
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
function CodeGameScreenColorfulCircusMachine:getReSpinSymbolScore(id,onlyGetScore)
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
function CodeGameScreenColorfulCircusMachine:getReSpinSymbolScoreUp(id,onlyGetScore)
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

function CodeGameScreenColorfulCircusMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()  
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenColorfulCircusMachine:setSpecialNodeScore(param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex



    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    -- print("setSpecialNodeScore per")
    -- print(iRow)
    -- print(rowCount)
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        if symbolNode.p_symbolType == self.SYMBOL_FIX_ALL and self.m_reconnect == false then
            self.m_triggerAllSymbol = true
            -- print("setSpecialNodeScore++++++++")
            -- print(self.m_triggerAllSymbol)
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

                self:setSymbolString(symbolNode, "")

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
            score = util_formatCoins(score, 3)


            self:setSymbolString(symbolNode, score)
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）

        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)

            self:setSymbolString(symbolNode, score)
        end

    end

end

function CodeGameScreenColorfulCircusMachine:addLabToSpine( _symbol)
    local cocosName = "Socre_ColorfulCircus_Bonus_num.csb"
    if _symbol.p_symbolType == self.SYMBOL_FIX_ALL then
        cocosName = "Socre_ColorfulCircus_Bonus_num_cai.csb"
    end
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    util_spineRemoveSlotBindNode(spineNode,"zi")
    -- if spineNode and not tolua.isnull(spineNode) then
    --     local bonusNum = spineNode:getChildByTag(1032110)
    --     if bonusNum and not tolua.isnull(bonusNum) then
    --         bonusNum:removeFromParent()
    --     end
    -- end
    local coinsView = util_createAnimation(cocosName)
    coinsView:findChild("m_lb_score"):setString("")
    if coinsView:findChild("m_lb_score2") then
        coinsView:findChild("m_lb_score2"):setString("")
    end
    if _symbol.p_symbolType == self.SYMBOL_FIX_ALL then
        coinsView:setScale(1.11)
    else
        coinsView:setScale(1.1)
    end
    
    coinsView:setPositionY(1)

    self:util_spinePushBindNode(spineNode,"zi",coinsView)
    -- coinsView:setScale(4)
    -- spineNode:addChild(coinsView, 10, 1032110)
    -- coinsView:setPositionY(10)
    _symbol.m_csbNode = coinsView

    if _symbol.p_symbolType == self.SYMBOL_FIX_ALL then
        _symbol.m_csbNodeColorEffect = util_spineCreate("Socre_ColorfulCircus_Bonus_num_cai2",true,true)
        coinsView:findChild("spine"):addChild(_symbol.m_csbNodeColorEffect)
        _symbol.m_csbNodeColorEffect:setVisible(false)
    end
end

function CodeGameScreenColorfulCircusMachine:util_spinePushBindNode(spNode, slotName, bindNode)
    -- 与底层区分开
    spNode:pushBindNode(slotName, bindNode)
end

function CodeGameScreenColorfulCircusMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)
    if not tolua.isnull(node.m_csbNode) then
        node.m_csbNode:removeFromParent()
        node.m_csbNode = nil
    end
    CodeGameScreenColorfulCircusMachine.super.pushSlotNodeToPoolBySymobolType(self,symbolType, node)
end

function CodeGameScreenColorfulCircusMachine:addLevelBonusSpine(_symbol)
    self:addLabToSpine( _symbol)

    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if _symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL or _symbol.p_symbolType == self.SYMBOL_FIX_ALL then
        spineNode:setSkin("wenzi")
    end
end

function CodeGameScreenColorfulCircusMachine:getBonusSkinName(symbolType)
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

function CodeGameScreenColorfulCircusMachine:bonusChangeShow(node)
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

function CodeGameScreenColorfulCircusMachine:updateReelGridNode(node)
    CodeGameScreenColorfulCircusMachine.super.updateReelGridNode(self, node)

    if not tolua.isnull(node.m_csbNode) then
        node.m_csbNode:removeFromParent()
        node.m_csbNode = nil
    end

    if node.p_symbolType == self.SYMBOL_FIX_SYMBOL or node.p_symbolType == self.SYMBOL_FIX_ALL then
            self:addLevelBonusSpine(node)
            -- print("updateReelGridNode+++")
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
function CodeGameScreenColorfulCircusMachine:setSpecialNodeScoreUp(param)
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
            -- print("setSpecialNodeScoreUp++++++++")
            -- print(self.m_triggerAllSymbol)
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

                self:setSymbolString(symbolNode, "")

            end
            return
        end
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self:getReSpinSymbolScoreUp(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)

            self:setSymbolString(symbolNode, score)
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)

            self:setSymbolString(symbolNode, score)
        end

    end

end

function CodeGameScreenColorfulCircusMachine:setSymbolString(symbolNode, str)
    if symbolNode then
        if symbolNode.m_csbNode then
            local lbs = symbolNode.m_csbNode:findChild("m_lb_score")
            if lbs and lbs.setString  then
                lbs:setString(str)
            end
            local lbs2 = symbolNode.m_csbNode:findChild("m_lb_score2")
            if lbs2 and lbs2.setString  then
                lbs2:setString(str)
            end
        end
    end
end

function CodeGameScreenColorfulCircusMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = CodeGameScreenColorfulCircusMachine.super.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_ALL then
            -- print("getxxxxxxxxx+++")
        self:setSpecialNodeScore({reelNode})
    end
    return reelNode
end

function CodeGameScreenColorfulCircusMachine:getSlotNodeWithPosAndTypeUp(symbolType, row, col,isLastSymbol)
    local reelNode = CodeGameScreenColorfulCircusMachine.super.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_ALL
    then
        self:setSpecialNodeScoreUp({reelNode})
    end
    return reelNode
end

--- 是不是 respinBonus小块
function CodeGameScreenColorfulCircusMachine:isFixSymbol(symbolType)
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

function CodeGameScreenColorfulCircusMachine:isFixSymbolJackpot(symbolType)
    if symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end


function CodeGameScreenColorfulCircusMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeColorfulCircusSrc.ColorfulCircusJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    jackPotWinView:findChild("root_0"):setScale(self.m_machineRootScale)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)

end
-- 结束respin收集
function CodeGameScreenColorfulCircusMachine:playLightEffectEnd()
    self.m_RsjackpotView:resetJackpotHitEffect()
    -- 通知respin结束
    self:respinOver()

end
--
function CodeGameScreenColorfulCircusMachine:respinOver()

    self:showRespinOverView()
end

function CodeGameScreenColorfulCircusMachine:getChipCosin(_index )
    local coins = 0
    local winlines = self.m_runSpinResultData.p_winLines or {}
    for k,_lineInfo in pairs(winlines) do
        local pos =_lineInfo.p_iconPos[1]
        if _index == pos then
            coins = _lineInfo.p_amount * self.m_respinMulti
            break
        end
    end
    return coins
end
function CodeGameScreenColorfulCircusMachine:playChipCollectAnim(isDouble)

    if self.m_playAnimIndex > #self.m_chipList then
        self.m_isPlayCollect = nil
        local waitTime = 1

        self:delayCallBack(waitTime,function()
            self:playLightEffectEnd()
        end)

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

    local worldPos = cc.p(self:findChild("Node_respinbar"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_respinbar"):getPosition())))
    local endPos = cc.p(self:convertToNodeSpace(worldPos))

    local waitTime = 0.4
    -- if self:checkIsTopRsNode( chipNode ) then
    --     waitTime = 0.6
    -- end
    

    if nJackpotType ~= 0 then
        self.m_RsjackpotView:setJackpotHitEffect(nJackpotType)
    end


    -- local delayTime = 0
    -- if nJackpotType ~= 0 then
    -- end

   --最终收集阶段
   self:runEndFlyGoldAction(0,waitTime,nodePos,endPos,function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_bonus_endFanKui.mp3")
        self.m_reSpinbar:runCsbAction("actionframe2")
        self.m_reSpinbar:updateRewordCoins(self.m_lightScore,lastNum)

        
        
        
    end,chipNode, function (  )
        runCollect()
    end,isDouble)
end

function CodeGameScreenColorfulCircusMachine:checkIsTopRsNode( _rsnode )
    local topChipList = self.m_respinViewUp:getAllCleaningNode()

    for k,v in pairs(topChipList) do
        local node = v
        if node == _rsnode then
            return true
        end
    end
end

--结束移除小块调用结算特效
function CodeGameScreenColorfulCircusMachine:reSpinEndAction()
    self.m_temp = {}
    self.m_respinQuickStop = false
    self.m_respinBulingSoundBonus = {}
    self.m_respinBulingSoundBonusSpecial = {}
    self.m_respinQuickPlayed = {}
    self.m_allRunningRespinNodes = {}
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- self:clearCurMusicBg()

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
            self:delayCallBack(2, function()
                self:playChipCollectAnim(isDouble)
            end)

        end
    end

    local goonNext = function ( isDouble )

        gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_RespinCollectBonusTrigger.mp3")

        self.m_respinEndEffect:setVisible(true)
        self:playSpineAnim(self.m_respinEndEffect,"actionframe",false,function (  )
            self.m_respinEndEffect:setVisible(false)
        end)

        for i,v in ipairs(self.m_chipList) do
            local tempUpNode = v
            if isDouble and self:isFixSymbolJackpot(tempUpNode.p_symbolType) then
                tempUpNode:runAnim("actionframe3", false, function()
                    tempUpNode:runAnim("idleframe4", true)
                end)
            else
                tempUpNode:runAnim("actionframe", false, function()
                    tempUpNode:runAnim("idleframe2", true)
                end)
            end
            
        end

        self.m_reSpinbar:runCsbAction("switch")

        self.m_reSpinPrize:runCsbAction("over2", false)

        gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_RespinBarSwitch.mp3")


        innerCollect(isDouble)

    end


    if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)*2 then
        self.m_respinMulti = 2
        self.m_isX2Respin = true

        self:playX2Anim(function (  )
            self.m_respinMultiBar = 2

            --播放数字变化动画和jackpot x2动画
            for i=1,#self.m_chipList do
                local respinNode = self.m_chipList[i]
                if respinNode then
                    if respinNode.p_symbolType == self.SYMBOL_FIX_SYMBOL or respinNode.p_symbolType == self.SYMBOL_FIX_ALL then
                        if respinNode.m_csbNode then
                            respinNode.m_csbNode:runCsbAction("actionframe2")
                        end
                    else
                        --jackpot
                        respinNode:runAnim("actionframe2", false, function()
                            respinNode:runAnim("idleframe4", true)
                        end)
                        
                    end
                    

                    local index = self:getPosReelIdx(respinNode.p_rowIndex ,respinNode.p_cloumnIndex)
                    if i > self.upSymbolNum then
                        index = index + 15
                    end
                    local addScore = self:getChipCosin(index)
                    addScore = util_formatCoins(addScore, 3)

                    self:setSymbolString(respinNode, addScore)
                end
                
            end
            
            --延时15帧 变化数字
            -- self:delayCallBack(15/60, function (  )
            --     for i=1,#self.m_chipList do
            --         local respinNode = self.m_chipList[i]
                    
            --         if respinNode then
            --             local index = self:getPosReelIdx(respinNode.p_rowIndex ,respinNode.p_cloumnIndex)
            --             if i > self.upSymbolNum then
            --                 index = index + 15
            --             end
            --             local addScore = self:getChipCosin(index)
            --             addScore = util_formatCoins(addScore, 3)
    
            --             self:setSymbolString(respinNode, addScore)
    
            --         end
            --     end
            -- end)
            

            
        end, function (  )
            goonNext(true)
        end)
    else
        goonNext(false)
    end

end

--飞x2动画
function CodeGameScreenColorfulCircusMachine:playX2Anim(func, func2)

    local posOrigin = util_convertToNodeSpace(self:findChild("Node_respinx2"), self:findChild("Node_x2pos_0"))
    self.m_x2Node1:setPosition(cc.p(posOrigin))
    self.m_x2Node1:setVisible(true)
    self.m_x2Node1:playAction("start", false, function (  )
        -- fly_x2_1:playAction("idle", true)
    end)

    self:delayCallBack(30/60 + 60/60, function (  )
        self:respinDarkShow(  ) --压暗棋盘

        local posOrigin = util_convertToNodeSpace(self:findChild("Node_respinx2"), self:findChild("Node_x2pos_0"))
        self.m_x2Node2:setPosition(cc.p(posOrigin))
        self.m_x2Node2:setVisible(true)
        self.m_x2Node2:playAction("idle", true)
        -- fly_x2_2:playAction("start", false, function (  )
        --     fly_x2_2:playAction("idle", true)
        -- end)

        self.m_x2Node1:playAction("fly", false)
        self.m_x2Node2:playAction("fly", false)

        local endPos1 = cc.p(util_convertToNodeSpace(self:findChild("Node_x2pos_0"), self:findChild("Node_x2pos_0")))
        local endPos2 = cc.p(util_convertToNodeSpace(self:findChild("Node_x2pos_1"), self:findChild("Node_x2pos_0")))


        local actionList = {}
        actionList[#actionList + 1] = cc.MoveTo:create(30/60, cc.p(endPos1.x,endPos1.y) )
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            self.m_x2Node1:playAction("actionframe", false)
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(60/60)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self.m_x2Node1:setVisible(false)
            local posOrigin = util_convertToNodeSpace(self:findChild("Node_respinx2"), self:findChild("Node_x2pos_0"))
            self.m_x2Node1:setPosition(cc.p(posOrigin))
        end)
        self.m_x2Node1:runAction(cc.Sequence:create(actionList))

        local actionList1 = {}
        actionList1[#actionList1 + 1] = cc.MoveTo:create(30/60, cc.p(endPos2.x,endPos2.y) )
        actionList1[#actionList1 + 1] = cc.CallFunc:create(function(  )
            self.m_x2Node2:playAction("actionframe", false)
            self:respinEdgeEffectShow()

            self:respinDarkHide( function (  )

            end )
        end)
        -- actionList1[#actionList1 + 1] = cc.DelayTime:create(15/60)
        -- actionList1[#actionList1 + 1] = cc.CallFunc:create(function(  )
            
            
        -- end)
        actionList1[#actionList1 + 1] = cc.DelayTime:create(45/60)
        actionList1[#actionList1 + 1] = cc.CallFunc:create(function()
            if func then
                func()
            end

            self.m_x2Node2:setVisible(false)

            -- self:respinDarkHide( function (  )
                -- if func2 then
                    -- func2()
                -- end
            -- end )
            local posOrigin = util_convertToNodeSpace(self:findChild("Node_respinx2"), self:findChild("Node_x2pos_0"))
            self.m_x2Node2:setPosition(cc.p(posOrigin))
        end)
        actionList1[#actionList1 + 1] = cc.DelayTime:create((30+30)/60)
        actionList1[#actionList1 + 1] = cc.CallFunc:create(function(  )
            
            if func2 then
                func2()
            end
        end)
        self.m_x2Node2:runAction(cc.Sequence:create(actionList1))

    end)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenColorfulCircusMachine:getRespinRandomTypes( )
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
function CodeGameScreenColorfulCircusMachine:getRespinLockTypes( )
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

function CodeGameScreenColorfulCircusMachine:showRespinView()

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

    end,2)

end

--ReSpin开始改变UI状态
function CodeGameScreenColorfulCircusMachine:changeReSpinStartUI(respinCount)
    
end

--ReSpin刷新数量
function CodeGameScreenColorfulCircusMachine:changeReSpinUpdateUI(curCount)
    -- print("当前展示位置信息  %d ", curCount)

end

function CodeGameScreenColorfulCircusMachine:triggerReSpinOverCallFun(score)

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
function CodeGameScreenColorfulCircusMachine:changeReSpinOverUI(callback)


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
function CodeGameScreenColorfulCircusMachine:changeRespinOverCCbName( )
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

function CodeGameScreenColorfulCircusMachine:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    -- self:clearCurMusicBg()

    self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenColorfulCircusMachine:showRespinOverView(effectData)
    local strCoins=util_formatCoins(self.m_serverWinCoins,15)
    local view = self:showReSpinOver(strCoins,function()
        self:showGuochang(transType1TimeCut,transType1TimeOver,1,function (  )
            self.m_respinMulti = 1
            self.m_respinMultiBar = 1

            self.m_progress:setVisible(true)
            self:changeProChildShow(true)
            self.m_effectNode:setVisible(false)
            self.m_effectNode:removeAllChildren(true)
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
        end, function()
            self.m_isX2Respin = false
        end, true)
    end)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local node = view:findChild("m_lb_coins")
    self:updateLabelSize({label=node,sx=0.95,sy=1},725)

    local guang = util_createAnimation("ColorfulCircus_tanban_guang.csb")
    view:findChild("guang"):addChild(guang)
    guang:playAction("animation0", true)
    util_setCascadeOpacityEnabledRescursion(view:findChild("guang"), true)

    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respinOverPopupStart.mp3")
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respinOverPopupOver.mp3")
    end)
end


-- --重写组织respinData信息
function CodeGameScreenColorfulCircusMachine:getRespinSpinData()
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

function CodeGameScreenColorfulCircusMachine:showEffect_Respin(effectData)
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

                CodeGameScreenColorfulCircusMachine.super.showEffect_Respin(self,effectData)

            end
        end,1)
    end
    return true

end

function CodeGameScreenColorfulCircusMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        if _trigger then
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * (self.m_iReelRowNum * 2 + 0.5 )))
        else
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
        end
       
    end
end

function CodeGameScreenColorfulCircusMachine:playChangeScene(_func,isChoose)
    if not isChoose then
        --过场动画
        self:showGuochang(transType1TimeCut,transType1TimeOver,1,function (  )
            self.isShowRespinStartView = true
            if _func then
                _func()
            end
        end, function (  )
            
        end)
    else
        --开始弹板
        self:showReSpinStart(function (  )
            --过场动画
            self:showGuochang(transType1TimeCut,transType1TimeOver,1,function (  )
                if _func then
                    _func()
                end
            end, function()
            end)
        end)
    end
    
end
function CodeGameScreenColorfulCircusMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    -- self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_NOMAL)
    local view = self:showDialog("ReSpinStartNew", nil, func)
    view:findChild("root"):setScale(self.m_machineRootScale)


    local guang = util_createAnimation("ColorfulCircus_tanban_guang.csb")
    view:findChild("guang"):addChild(guang)
    guang:playAction("animation0", true)

    local lock = util_createAnimation("ColorfulCircus_tanban_shanshuo.csb")
    view:findChild("shanshuo"):addChild(lock)
    lock:playAction("animation0", true)

    util_setCascadeOpacityEnabledRescursion(view:findChild("guang"), true)

    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_RespinStartPopupStart.mp3")--弹出声
    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_choose_feature_respin.mp3")--人物声
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_RespinStartPopupOver.mp3")
    end)

    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function CodeGameScreenColorfulCircusMachine:changeMainUi(_type )

    self:findChild("Node_sp_respin"):setVisible(false)
    self:findChild("basefreeqipan"):setVisible(false)
    self:findChild("respinqipan"):setVisible(false)
    -- self.m_gameBg:findChild("base_bg"):setVisible(false)
    -- self.m_gameBg:findChild("free_bg"):setVisible(false)
    self.m_gameBg:findChild("respin_bg"):setVisible(false)
    self.m_gameBg:findChild("pick_bg"):setVisible(false)
    self.bg1:setVisible(false)


    self.m_3RowFreeSpinBar:setPosition(cc.p(0,0))
    self.m_RsjackpotView:setVisible(false)
    self.m_jackpotView:setVisible(false)

    self.m_reSpinbar:setVisible(false)
    self.m_reSpinPrize:setVisible(false)

    self:findChild("Node_base_reel"):setVisible(false)
    self:findChild("Node_free_reel"):setVisible(false)
    
    if _type == self.m_base then
        self:findChild("basefreeqipan"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(true)
        self.m_jackpotView:setVisible(true)
        self.m_progress:setUI("base")

        self.bg1:setVisible(true)
        util_spinePlay(self.bg1,"idle",true)

        self:changeShowUpClown(1)
    elseif _type == self.m_3RowFree then
        self:findChild("basefreeqipan"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(true)
        self.m_jackpotView:setVisible(true)
        self.m_progress:setUI("free")

        self.bg1:setVisible(true)
        util_spinePlay(self.bg1,"idle2",true)

        self:changeShowUpClown(2)
    elseif _type == self.m_respin then
        self.m_reSpinbar:updateShowStates( 0 )
        self.m_reSpinbar:setVisible(true)
        self.m_reSpinbar:runCsbAction("actionframe")
        self.m_reSpinPrize:setVisible(true)
        self:findChild("Node_sp_respin"):setVisible(true)
        self:findChild("respinqipan"):setVisible(true)
        self.m_RsjackpotView:setVisible(true)
        self.m_gameBg:findChild("respin_bg"):setVisible(true)
        self.m_progress:setUI("respin")

        self:changeShowUpClown()
    elseif _type == self.m_duck then
        self.m_gameBg:findChild("pick_bg"):setVisible(true)
        self.m_progress:setUI("duck")

        self:changeShowUpClown()
    end
    
end

function CodeGameScreenColorfulCircusMachine:hideUpReelSlots( )
    for col=1,self.m_iReelColumnNum do
        local upSlot = self:getFixSymbol(col, self.m_iReelRowNum + 1)
        if upSlot then
            upSlot:setVisible(false)
        end
    end
    
end

function CodeGameScreenColorfulCircusMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    ******************* 收集玩法相关    
--]]
function CodeGameScreenColorfulCircusMachine:getProgressPecent(_init)
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


--进度条动画
function CodeGameScreenColorfulCircusMachine:showEffect_collectCoin(effectData)
    --如果低bet，直接返回
    if self:getBetLevel() == 0 then 
        effectData.p_isPlay = true
        self:playGameEffect()
        return 
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfData.collectWin
    local specialWin = selfData.specialWin

    local nodeCollect = self:findChild("Node_collect_qiqiu")
    local progressPos = nodeCollect:getParent():convertToWorldSpace(cc.p(nodeCollect:getPosition()))
    local newProgressPos = self:convertToNodeSpace(progressPos)
    local endPos = cc.p(newProgressPos)

    local function flyShow(startPos,endPos,func)
        local actionList = {}

        local node = util_spineCreate("Socre_ColorfulCircus_Bonus1",true,true)

        self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)

        node:setPosition(startPos)
        -- actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            -- node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
            -- node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
            -- node:findChild("Particle_1"):resetSystem()
        -- end)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            util_spinePlay(node,"fly",false)
            -- node:runCsbAction("actionframe",false)
        end)
        -- actionList[#actionList + 1] = cc.CallFunc:create(function()
            
        -- end)
        actionList[#actionList + 1] = cc.MoveTo:create(21/30, cc.p(endPos.x,endPos.y) )
        actionList[#actionList + 1] = cc.CallFunc:create(function()

            -- ship:removeFromParent()

            if func then
                func()
            end
        end)
        -- actionList[#actionList + 1] = cc.DelayTime:create(0.5)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            -- node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
            node:setVisible(false)
            node:removeFromParent()
        end)
        node:runAction(cc.Sequence:create(actionList))
    end

    
    local pecent = self:getProgressPecent()
    if specialWin or collectWin then
        pecent = 100
    end
    -- if #self.m_collectList > 0 then
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_wildCollect_fly.mp3")
    -- end
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        flyShow(newStartPos,endPos)
        table.remove(self.m_collectList, i)

    end

    local isHaveBonusGames = false
    isHaveBonusGames = self:checkIsHaveSelfEffect(GameEffect.EFFECT_SELF_EFFECT, self.BONUS_GAME_EFFECT)
    --是否有收集小游戏 
    if not isHaveBonusGames then
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_CollectBonusBegin.mp3")
    self:delayCallBack(21/30,function (  )
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_CollectBonusEnd.mp3")
        self.m_progress:collectFanKui()
        -- self.loadingIcon:showActionFrame()
        -- if specialWin or collectWin then
        --     self.m_progress:updatePercent(100)
        -- else
        --     self.m_progress:updatePercent(pecent)
        -- end

        self.m_progress:updatePercent(pecent, function (  )
            if isHaveBonusGames then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
            
        end)
    end)

end

--集满进入地图 effect
function CodeGameScreenColorfulCircusMachine:showEffect_CollectBonus(effectData)

    -- gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_Trigger_Bonus.mp3")
    
    -- self:clearCurMusicBg()

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = 1
    if selfData.pos == 0 then
        currentPos = 20
    else
        currentPos = selfData.pos
    end
    self.m_mapNodePos = currentPos -- 更新最新位置
    local collectWin = selfData.collectWin or 0
    local specialWin = selfData.specialWin
    self.m_map:setMapCanTouch(false)


    self.m_bCanClickMap = false
    self:hideMapTipView(true)
    self:removeSoundHandler( )
    self.m_map:setVisible(true)
    self.m_map:mapAppear(function()
        self.m_bCanClickMap = true

        self.m_map:signalMove(function(  )
            
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}

            if specialWin then
                local currNode = self.m_map.m_items[self.m_mapNodePos]

                -- self:clearCurMusicBg()
                self:bgMusicDown( 1 )
                self:showGuochang(transType2TimeCut,transType2TimeOver,2,function (  )
                    self.m_progress:restProgressEffect(0)
                    self.m_map:mapDisappear(function (  )
                        self.m_map:setMapCanTouch(true)
                        -- self:resetMusicBg(true)
                    end)

                    self:changeMainUi(self.m_duck )

                    self:createPickDuckView(function (  )
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end, self.m_mapNodePos)
                    self.m_pickDuckView:showDuckView()

                    self:clearCurMusicBg()
                    self:resetMusicBg(nil,"ColorfulCircusSounds/music_ColorfulCircus_duck.mp3")
                end,function (  )
                    self.m_pickDuckView:beginDuckGame()


                    --最后一关后重置为初始
                    if self.m_mapNodePos == 20 then
                        self.m_map:resetMapPos(0)
                    end
                end)
                
            else
                local currNode = self.m_map.m_items[self.m_mapNodePos]
                local numNode = currNode:findChild("Node_1")
                currNode:idle()
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_collect_small_coinsfly.mp3")
                self:createParticleFly(30/60,numNode,collectWin,function(  )
                    currNode:runComplete()


                    local onceWin = self.m_runSpinResultData.p_winAmount
                    local isHaveCollect, type, coins = self:checkIsHaveCollect()
                    if isHaveCollect then
                        onceWin = coins
                    end
                    self.m_bottomUI:setMapWinTime(true)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{onceWin,true})
                    self:playCoinWinEffectUI()
                    self.m_bottomUI:setMapWinTime(false)
                    
                    self:delayCallBack(2, function()  --打对号后地图消失间隔
                        self.m_map:setMapCanTouch(true)
                        self.m_progress:restProgressEffect(0)
                        self.m_map:mapDisappear(function(  )
                            -- self:resetMusicBg(true)
                            effectData.p_isPlay = true
                            self:playGameEffect()
                
                        end)
                    end)
                end)
            end


        end, self.m_bonusData.map, self.m_mapNodePos, collectWin)


    end)
end

function CodeGameScreenColorfulCircusMachine:bgMusicDown( time )
    -- local time = 1
    if self.m_updateBgMusicHandlerID ~= nil then
        return
    end
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
end

function CodeGameScreenColorfulCircusMachine:initGameStatusData( gameData )
    CodeGameScreenColorfulCircusMachine.super.initGameStatusData( self, gameData )
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


function CodeGameScreenColorfulCircusMachine:createMapScroll( )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.pos or 0

    self.m_mapNodePos = currentPos
    -- local changeY = self:mapChangePosY()
    -- self:findChild("Node_map"):setPosition(cc.p(display.width/2,changeY))
    self.m_map = util_createView("CodeColorfulCircusSrc.Map.ColorfulCircusMapMain", self, self.m_bonusData.map, self.m_mapNodePos)
    self:findChild("Node_map"):addChild(self.m_map,GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 5 )
    -- local w = self.m_map:getContentSize().width
    -- local h = self.m_map:getContentSize().height
    -- self.m_map:setPosition(cc.p(-768 / 2, -1370 / 2))
    -- if display.height >= 1024 and display.height <= 1064 then
    --     self.m_map:setScale(1.1)
    -- end
    -- self.m_map:setClickPosition()
    -- self.m_map:findChild("root"):setScale(self.m_machineRootScale)
    self.m_map:setVisible(false)


end

--打鸭子
function CodeGameScreenColorfulCircusMachine:createPickDuckView(effectData,pos)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local multi = selfData.multi or 1
    local specialWin = selfData.specialWin or {}
    local spinNum = selfData.spinNum or 0
    local avgBet = selfData.avgBet or 0

    -- local multi = 38
    -- local specialWin = {
    --     {1, 2, 5},
    --     {2, 1, 20},
    --     {3, 2, 2},
    --     {4, 2, 15},
    --     {5, 2, 2},
    --     {6, 2, 10},
    --     {7, 2, 5},
    --     {8, 2, 2},
    --     {9, 2, 30},
    --     {10, 2, 3},
    --     {11, 2, 5},
    --     {12, 2, 3},
    -- }
    -- local spinNum = 10
    -- local avgBet = 5000000000


    local nodePos_map = util_convertToNodeSpace(self:findChild("Node_map"), self)
    self.m_pickDuckView = util_createView("CodeColorfulCircusSrc.PickDuck.ColorfulCircusPickMainView", self, multi, specialWin, spinNum, avgBet, effectData, pos)
    self:addChild(self.m_pickDuckView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1 )
    self.m_pickDuckView:setPosition(cc.p(nodePos_map))

    -- self.m_pickDuckView:setPosition(cc.p(-768 / 2, -1370 / 2))
    self.m_pickDuckView:findChild("root"):setScale(self.m_machineRootScale)
    self.m_pickDuckView:setVisible(false)
end

-- function CodeGameScreenColorfulCircusMachine:mapChangePosY( )
--     local changeY = self.m_downPosY
--     if display.height >= DESIGN_SIZE.height then
--         local cutSizeY = (1660 - 1370) / (30 - self.m_downPosY)
--         changeY = ((display.height - DESIGN_SIZE.height) + (150 * cutSizeY)) / cutSizeY
--     else
--         local cutSizeY = (1370 - 1024) / (self.m_downPosY - 200)
--         changeY = ((display.height - DESIGN_SIZE.height) + (200 * cutSizeY)) / cutSizeY - 60
--     end
    
--     return changeY

-- end

function CodeGameScreenColorfulCircusMachine:isNormalStates( )
    
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

function CodeGameScreenColorfulCircusMachine:isCanClickTip(  )
    if self:getGameSpinStage() > IDLE then
        return false
    end
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    end
    return true
end

function CodeGameScreenColorfulCircusMachine:hideMapScroll()

    
    if self.m_map:getMapIsShow() == true then

        self.m_bCanClickMap = false

        
        self.m_map:mapDisappear(function()
            self.m_map:setVisible(false)
            self:resetMusicBg(true)
            self.m_bCanClickMap = true
        end)
    end

end

function CodeGameScreenColorfulCircusMachine:showMapScroll(callback)

    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true or self:getCurrSpinMode() == AUTO_SPIN_MODE) and callback == nil then
        return
    end

    self.m_bCanClickMap = false

    if self.m_map:getMapIsShow() == true then
        self.m_map:mapDisappear(function()
            self.m_map:setVisible(false)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            self.m_bCanClickMap = true
        end)
        
    else

        self:hideMapTipView(true)
        self:removeSoundHandler( )
        self.m_map:setVisible(true)
        self.m_map:mapAppear(function()
            
            self.m_bCanClickMap = true

            if callback then
                callback()
            end
        end)
        
 
    end

end

-- 创建飞行粒子
function CodeGameScreenColorfulCircusMachine:createParticleFly(time,currNode,coins,func)

    local fly = util_createAnimation("ColorfulCircus_map_xiaodian_shuzhi.csb")

    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    fly:setPosition(cc.p(util_convertToNodeSpace(currNode, self)))
    fly:findChild("m_lb_coins"):setString(util_formatCoins(coins, 3))
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:runCsbAction("fly",false)
    end)
    animation[#animation + 1] = cc.DelayTime:create(10/60)
    -- animation[#animation + 1] = cc.CallFunc:create(function(  )
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_collect_smallCoins.mp3")
    -- end)
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        -- fly:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
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

-- function CodeGameScreenColorfulCircusMachine:reelDownNotifyPlayGameEffect( )
--     CodeGameScreenColorfulCircusMachine.super.reelDownNotifyPlayGameEffect( self)
-- end

function CodeGameScreenColorfulCircusMachine:changeSymbolToWild(_posList )
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

-- function CodeGameScreenColorfulCircusMachine:showLineFrame( )
--     CodeGameScreenColorfulCircusMachine.super.showLineFrame(self )
-- end

function CodeGameScreenColorfulCircusMachine:getBaseSpecialCoins( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfdata.collectWin or 0 -- bonus

    return collectWin
end

function CodeGameScreenColorfulCircusMachine:duckShowOver(_func, _func2)
    self:showGuochang(transType2TimeCut,transType2TimeOver,2,function (  )
        if _func then
            _func()
        end
    end,function (  )
        if _func2 then
            _func2()
        end
    end,true)
end

--1 free respin other 2 打鸭子
function CodeGameScreenColorfulCircusMachine:showGuochang(timeCut,timeOver,type,func1,func2,isBack)
    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    local guoChangView = nil
    local actionName = "actionframe_guochang"
    if type and type == 1 then
        guoChangView = util_spineCreate("ColorfulCircus_guochang2",true,true)
        actionName = "actionframe_guochang"

        if isBack then--返回
            gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_OtherTobase.mp3")
        else
            gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_baseToOther.mp3")
        end
        
    elseif type and type == 2 then
        guoChangView = util_spineCreate("ColorfulCircus_guochang3",true,true)
        actionName = "actionframe_guochang"

        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_baseToDuck.mp3")
    end
    self:addChild(guoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    guoChangView:setPosition(display.center)

    util_spinePlay(guoChangView,actionName,false)
    performWithDelay(waitNode,function (  )
        if func1 then
            func1()
        end
    end,timeCut)
    performWithDelay(waitNode,function (  )
        if func2 then
            func2()
        end
        guoChangView:removeFromParent()
        waitNode:removeFromParent()
    end, timeOver)
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenColorfulCircusMachine:specialSymbolActionTreatment( node)
    if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --修改小块层级
        local scatterOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
        local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,scatterOrder)
        self:playScatterBonusSound(symbolNode)
    end
end

--播放提示动画
function CodeGameScreenColorfulCircusMachine:playReelDownTipNode(slotNode)

    -- self:playScatterBonusSound(slotNode)
    slotNode:runAnim("buling", false, function (  )
        if slotNode and not tolua.isnull(slotNode) and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self.m_isLongRun then
                slotNode:runAnim("idleframe3", true)
                -- self:runScatterIdle(slotNode,false)
            else
                slotNode:runAnim("idleframe2", true)
            end
        end
    end)
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

function CodeGameScreenColorfulCircusMachine:playCustomSpecialSymbolDownAct( slotNode )

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        if slotNode and  self:isFixSymbol(slotNode.p_symbolType) then
            local bonusOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex
            local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_FIX_SYMBOL,bonusOrder)
            self:playScatterBonusSound(slotNode)
            slotNode:runAnim("buling", false, function (  )
                if slotNode and not tolua.isnull(slotNode) then
                    slotNode:runAnim("idleframe2", true)
                end
            end)
        end
    end
end

function CodeGameScreenColorfulCircusMachine:slotOneReelDown(reelCol)    
    CodeGameScreenColorfulCircusMachine.super.slotOneReelDown(self,reelCol) 
    if reelCol == 5 then
        self.m_playWinningNotice = false


        if self.m_isLongRun then
            --scatter期待动画还原
            self.m_isLongRun = false
            local featureLen = self.m_runSpinResultData.p_features or {}
    
            for iCol = 1,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local _slotNode = self:getFixSymbol(iCol,iRow)
                    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        _slotNode:runAnim("idleframe2", true)
                    end
                end
            end
            
        end
    end
end

--设置bonus scatter 信息
function CodeGameScreenColorfulCircusMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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

function CodeGameScreenColorfulCircusMachine:scaleMainLayer()
    CodeGameScreenColorfulCircusMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.69
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 17)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.81 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 12)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.87 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio >= 1200/2000 then
        local mainScale = 0.95 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 1200/2000 and ratio >= 768/1370 then
        local mainScale = 1 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 2)
    elseif ratio < 768/1370 and ratio >= 768/1530 then
        local mainScale = 1 - 0.05*((ratio-768/1530)/(768/1370 - 768/1530))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1530 and ratio >= 768/1660 then
        local mainScale = 1 - 0.05*((ratio-768/1660)/(768/1530 - 768/1660))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

function CodeGameScreenColorfulCircusMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "ColorfulCircusSounds/ColorfulCircus_scatter_down.mp3"
        local soundPathBonus = "ColorfulCircusSounds/ColorfulCircus_bonus_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
        self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = soundPathBonus
    end
end

-- 特殊信号下落时播放的音效
function CodeGameScreenColorfulCircusMachine:playScatterBonusSound(slotNode)
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

--重写
function CodeGameScreenColorfulCircusMachine:playQuickStopBulingSymbolSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        if _iCol == self.m_iReelColumnNum then
            local soundIds = {}
            local bulingDatas = self.m_symbolQsBulingSoundArray

            --改 同时有时 只播scatter
            local haveScatterSound = false
            local haveBonusSound = false
            for k,v in pairs(bulingDatas) do
                if k == "94" then
                    haveBonusSound = true
                elseif k == "90" then
                    haveScatterSound = true
                end
            end

            local bulingDatasTemp = {}
            if haveScatterSound and haveBonusSound and (self:getCurrSpinMode() == NORMAL_SPIN_MODE or 
            self:getCurrSpinMode() == AUTO_SPIN_MODE) then
                for k,v in pairs(bulingDatas) do
                    if k ~= "94" then
                        bulingDatasTemp[k] = v
                    end
                end
            else
                for k,v in pairs(bulingDatas) do
                    bulingDatasTemp[k] = v
                end
            end

            for soundType, soundPaths in pairs(bulingDatasTemp) do
                local soundPath = soundPaths[#soundPaths]
                local soundId = gLobalSoundManager:playSound(soundPath)
                table.insert(soundIds, soundId)
            end

            return soundIds
        end
    end
end

--判断快停 有scatter不播bonus声音
-- function CodeGameScreenColorfulCircusMachine:checkIsHaveScatter( col )
--     if not self.m_runSpinResultData and not self.m_runSpinResultData.p_reelsData then
--         return false
--     end
--     for i = 1, #self.m_runSpinResultData.p_reelsData do
--         local reels = self.m_runSpinResultData.p_reelsData[i]
--         for j = 1, #reels do
--             local type = reels[j]
--             if type == 90 and j >= col then
--                 return true
--             end
--         end 
--     end

--     return false
-- end

-- 显示paytableview 界面
function CodeGameScreenColorfulCircusMachine:showPaytableView()
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
function CodeGameScreenColorfulCircusMachine:delayCallBack(time, func)
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



--重写 每轮停轮声音
function CodeGameScreenColorfulCircusMachine:playReelDownSound(_iCol, _path)
    if self:checkIsPlayReelDownSound(_iCol) then
        if self:getGameSpinStage() == QUICK_RUN then
            gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_reelStop_quick.mp3")
        else
            gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_reelStop.mp3")
        end
    end
    self:setReelDownSoundId(_iCol, self.m_reelDownSoundPlayed)
end

function CodeGameScreenColorfulCircusMachine:operaUserOutCoins( )
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

--设置top层级
function CodeGameScreenColorfulCircusMachine:setTopUIZOrder(_isDuckMode)
    if self.m_topUI then
        if _isDuckMode then
            self.m_topUI:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
        else
            self.m_topUI:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP)
        end
    end
end

--打鸭子Over
function CodeGameScreenColorfulCircusMachine:showPickOverStart(func)
    self:clearCurMusicBg()
    -- self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_NOMAL)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local multi = selfData.multi or 0
    local avgBet = selfData.avgBet or 0

    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(multi*avgBet, 30)
    local view = self:showDialog("PickOver", ownerlist, func)

    local node = view:findChild("m_lb_coins")
    self:updateLabelSize({label=node,sx=0.95,sy=1},723)

    local guang = util_createAnimation("ColorfulCircus_tanban_guang.csb")
    view:findChild("guang"):addChild(guang)
    guang:playAction("animation0", true)
    util_setCascadeOpacityEnabledRescursion(view:findChild("guang"), true)

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_duckOverPopupStart.mp3")
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_duckOverPopupOver.mp3")
    end)

    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function CodeGameScreenColorfulCircusMachine:duckOverCheckBigwin()
    local onceWin = self.m_runSpinResultData.p_winAmount
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{onceWin,true})
end

function CodeGameScreenColorfulCircusMachine:playSpineAnim(_spine, _timeline, _loop, _func)
    local loop = not not _loop
    util_spinePlay(_spine, _timeline, loop)
    if loop == false and _func then
        util_spineEndCallFunc(_spine, _timeline, function()
            if _func then
                _func()
            end
        end)
    end
end

--默认按钮监听回调
function CodeGameScreenColorfulCircusMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Clown_Click" then

        -- self.m_respinMulti = 2
        -- self:showRespinJackpot(1,999999999998,function()
        -- end)


        if (self:getCurrSpinMode() == NORMAL_SPIN_MODE or 
        self:getCurrSpinMode() == AUTO_SPIN_MODE) and not self.m_clownAnimIsPlay then
            self.m_clownAnimIsPlay = true

            gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_clown_clicksound.mp3")

            util_spinePlay(self.clown_base, "actionframe", false)
            local spineEndCallFunc = function()
                self.m_clownAnimIsPlay = false
                -- util_spinePlay(self.clown_base, "idleframe", true)
                self:playClownAnim(  )
            end
            util_spineEndCallFunc(self.clown_base, "actionframe", spineEndCallFunc)
        end
        



        -- local node = util_createAnimation("ColorfulCircus_free_qiu.csb")
        -- local randomColor = math.random(1, 3)
        -- node:findChild("huang"):setVisible(randomColor == 1)
        -- node:findChild("lv"):setVisible(randomColor == 2)
        -- node:findChild("hon"):setVisible(randomColor == 3)

        -- node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        -- node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        -- node:findChild("Particle_1"):resetSystem()

        -- self.m_effectNode:addChild(node, 100)
        -- local startP = util_getConvertNodePos(self:findChild("Node_xiaochou"), node)
        -- startP = cc.pAdd(startP, cc.p(0, 300))

        -- local posIdx = 10
        -- local pos = self:getRowAndColByPos(posIdx)
        -- local col = pos.iY
        -- local row = pos.iX

        -- local reelNode = self:findChild("sp_reel_" .. col - 1)
        -- local reelNodePos = util_convertToNodeSpace(reelNode, self.m_effectNode)
        -- local changeP = reelNodePos
        -- local reelH = self.m_fReelHeigth or 366
        -- changeP = cc.pAdd(changeP, cc.p(self.m_SlotNodeW/2, reelH + 300))


        -- local posX = self.m_SlotNodeW * 0.5
        -- local posY = (row - 0.5) * self.m_SlotNodeH
        -- local endPos = cc.pAdd(reelNodePos, cc.p(posX, posY))
        -- -- local endPos = util_getOneGameReelsTarSpPos(self, posIdx)

        -- node:setPosition(startP)
        -- local actionList = {}
        -- actionList[#actionList + 1] = cc.DelayTime:create(0)
        

        -- local time = 1
        -- local bez=cc.BezierTo:create(time,{cc.p(changeP.x, startP.y),changeP
        -- ,endPos})
        -- -- actionList[#actionList + 1] = cc.MoveTo:create(time,endPos)
        -- actionList[#actionList + 1] = bez
        -- actionList[#actionList + 1] = cc.CallFunc:create(function()
        --     node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
            
        --     node:findChild("huang"):setVisible(false)
        --     node:findChild("lv"):setVisible(false)
        --     node:findChild("hon"):setVisible(false)
            
        -- end)
        -- actionList[#actionList + 1] = cc.DelayTime:create(2)
        -- actionList[#actionList + 1] = cc.CallFunc:create(function() 
        --     node:removeFromParent()
        -- end)
        -- node:runAction(cc.Sequence:create(actionList))
    end  
end

function CodeGameScreenColorfulCircusMachine:respinDarkShow(  )
    self.m_respinDark:setVisible(true)
    self.m_respinDark:runCsbAction("start", false, function (  )
        self.m_respinDark:runCsbAction("idle", true)
    end)
end

function CodeGameScreenColorfulCircusMachine:respinDarkHide( func )
    self:resetAct(self.m_respinDark)
    self.m_respinDark:runCsbAction("over", false, function (  )
        if func then
            func()
        end
        self.m_respinDark:setVisible(false)
    end)
end

function CodeGameScreenColorfulCircusMachine:resetAct(node)
    if node and not tolua.isnull(node) then
        if node.m_csbAct and not tolua.isnull(node.m_csbAct) then
            util_resetCsbAction(node.m_csbAct)
        end
    end
end

function CodeGameScreenColorfulCircusMachine:respinEdgeEffectShow(  )
    if self.m_respinX2EdgeEffect1 and self.m_respinX2EdgeEffect2 then
        self.m_respinX2EdgeEffect1:setVisible(true)
        self.m_respinX2EdgeEffect1:runCsbAction("qipan_fankui", false, function (  )
            self.m_respinX2EdgeEffect1:setVisible(false)
        end)

        self.m_respinX2EdgeEffect1:findChild("Particle_3"):resetSystem()
        self.m_respinX2EdgeEffect1:findChild("Particle_3_0"):resetSystem()
        self.m_respinX2EdgeEffect1:findChild("Particle_3_1"):resetSystem()
        self.m_respinX2EdgeEffect1:findChild("Particle_3_0_0"):resetSystem()
        self.m_respinX2EdgeEffect1:findChild("Particle_3_0_0_0"):resetSystem()
        self.m_respinX2EdgeEffect1:findChild("Particle_3_0_0_0_0"):resetSystem()

        self.m_respinX2EdgeEffect2:setVisible(true)
        self.m_respinX2EdgeEffect2:runCsbAction("qipan_fankui", false, function (  )
            self.m_respinX2EdgeEffect2:setVisible(false)
        end)

        self.m_respinX2EdgeEffect2:findChild("Particle_3"):resetSystem()
        self.m_respinX2EdgeEffect2:findChild("Particle_3_0"):resetSystem()
        self.m_respinX2EdgeEffect2:findChild("Particle_3_1"):resetSystem()
        self.m_respinX2EdgeEffect2:findChild("Particle_3_0_0"):resetSystem()
        self.m_respinX2EdgeEffect2:findChild("Particle_3_0_0_0"):resetSystem()
        self.m_respinX2EdgeEffect2:findChild("Particle_3_0_0_0_0"):resetSystem()
    end
end

--重写
function CodeGameScreenColorfulCircusMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = CodeGameScreenColorfulCircusMachine.super.setReelLongRun(self, reelCol)
    
    if not self.m_isLongRun and isTriggerLongRun then
        --scatter播期待动画
        self.m_isLongRun = isTriggerLongRun
        for iCol = 1,reelCol do
            for iRow = 1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol,iRow)
                if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    symbol:runAnim("idleframe3", true)
                    -- self:runScatterIdle(symbol,true)
                end
            end
        end

        -- self.m_isLongRun = isTriggerLongRun
    end

    return isTriggerLongRun
end

-- function CodeGameScreenColorfulCircusMachine:runScatterIdle(symbol, checkTimeLine)
--     if self.m_isLongRun then
--         if symbol and not tolua.isnull(symbol) then
--             if symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--                 if checkTimeLine then
--                     if symbol:getCurAnimName() == "idleframe2" then
--                         symbol:runAnim("idleframe3", false, function()
--                             if symbol and not tolua.isnull(symbol) then
--                                 self:runScatterIdle(symbol,checkTimeLine)
--                             end
--                         end)
--                     end
--                 else
--                     symbol:runAnim("idleframe3", false, function()
--                         if symbol and not tolua.isnull(symbol) then
--                             self:runScatterIdle(symbol,checkTimeLine)
--                         end
--                     end)
--                 end
--             end
--         end
--     else
--         if symbol and not tolua.isnull(symbol) then
--             if symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--                 symbol:runAnim("idleframe2", true)
--             end
--         end
--         return
--     end
    
-- end

--重写
function CodeGameScreenColorfulCircusMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local onceWin = self.m_iOnceSpinLastWin
    local isHaveCollect, type, coins = self:checkIsHaveCollect()
    if isHaveCollect then
        --显示连线赢钱 且不通知
        onceWin = self.m_runSpinResultData.p_winAmount
        globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount
        onceWin = onceWin - coins
        isNotifyUpdateTop = false

        local temp = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {onceWin, isNotifyUpdateTop})
        globalData.slotRunData.lastWinCoin = temp
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {onceWin, isNotifyUpdateTop})
    end

    
end

--获取收集信息
function CodeGameScreenColorfulCircusMachine:checkIsHaveCollect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local collectWin = selfData.collectWin
    local specialWin = selfData.specialWin

    -- type  1 小关 2 大关    赢钱
    if collectWin then
        return true, 1, collectWin
    end
    if specialWin then
        local multi = selfData.multi or 0
        local avgBet = selfData.avgBet or 0
        return true, 2, multi*avgBet
    end

    return false,0,0
end

function CodeGameScreenColorfulCircusMachine:getBottomUINode( )
    return "CodeColorfulCircusSrc.ColorfulCircusBottomUiView"
end

function CodeGameScreenColorfulCircusMachine:trunBaseClown(  )
    if self:isNormalStates( ) and self.m_clownAnimIsPlay == false then
        self.m_isChangeBaseClown = true
    end

    local randTime = math.random(5, 10)
    self:delayCallBack(randTime, function (  )
        self:trunBaseClown(  )  
    end)
end

function CodeGameScreenColorfulCircusMachine:playClownAnim(  )
    if self.m_isChangeBaseClown == true then
        self.m_isChangeBaseClown = false

        local randIdle = math.random(1,100)
        if randIdle < 50 then
            util_spinePlay(self.clown_base,"idleframe2",false)
            util_spineEndCallFunc(self.clown_base,"idleframe2", function (  )
                self.m_clownAnimIsPlay = false
                self:playClownAnim(  )
            end)
        else
            util_spinePlay(self.clown_base,"idleframe3",false)
            util_spineEndCallFunc(self.clown_base,"idleframe3", function (  )
                self.m_clownAnimIsPlay = false
                self:playClownAnim(  )
            end)
        end
    else
        util_spinePlay(self.clown_base,"idleframe",false)
        util_spineEndCallFunc(self.clown_base,"idleframe", function (  )
            self.m_clownAnimIsPlay = false
            self:playClownAnim(  )
        end)
    end
    
end

function CodeGameScreenColorfulCircusMachine:isHaveBigWin()
    local ret = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        ret = true
    end
    return ret
end

-- shake
function CodeGameScreenColorfulCircusMachine:shakeOneNodeForever(time)
    local oldPos = cc.p(self:findChild("Node_reel"):getPosition())
    local changePosY = math.random( 1, 5)
    local changePosX = math.random( 1, 5)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    self:findChild("Node_reel"):runAction(action)

    performWithDelay(self,function()
        self:findChild("Node_reel"):stopAction(action)
        self:findChild("Node_reel"):setPosition(oldPos)
    end,time)
end

--重写 小关 大关 无连线时加入大赢判断
function CodeGameScreenColorfulCircusMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local collectWin = selfData.collectWin
        local specialWin = selfData.specialWin
        if collectWin or specialWin then
            notAdd = false
        else
            notAdd = true
        end
    end

    return notAdd
end

--重写 修改basedialog
function CodeGameScreenColorfulCircusMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("CodeColorfulCircusSrc.ColorfulCircusDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    -- view.m_btnTouchSound = "HogHustlerSounds/sound_smellyRich_dialog_click.mp3"
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
    return view
end

function CodeGameScreenColorfulCircusMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenColorfulCircusMachine.super.levelDeviceVibrate then
        CodeGameScreenColorfulCircusMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenColorfulCircusMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectWin = selfData.collectWin
    local specialWin = selfData.specialWin
    if collectWin or specialWin then--小关大关没大赢动效
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenColorfulCircusMachine:showBigWinLight(_func)
    local animName = "actionframe"
    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_glabol_celebrate.mp3")

    self.m_spineBigWin:setVisible(true)
    
    util_spinePlay(self.m_spineBigWin, animName, false)
    local spineEndCallFunc = function()
        self.m_spineBigWin:setVisible(false)
    end
    util_spineEndCallFunc(self.m_spineBigWin, animName, spineEndCallFunc)


    self:shakeOneNodeForever(100/30)
    --大赢小丑动画
    if self:isNormalStates( ) then
        self:delayCallBack(10/30, function()
            self:playSpineAnim(self.clown_base, "actionframe3", false, function()
                self:playClownAnim(  )
            end)
        end)
    end
    
    self:delayCallBack(100/30, function()
        if type(_func) == "function" then
            _func()
        end
    end)
end

return CodeGameScreenColorfulCircusMachine