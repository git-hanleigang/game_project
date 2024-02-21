---
-- island li
-- 2019年1月26日
-- CodeGameScreenPalaceWishMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "PalaceWishPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local CodeGameScreenPalaceWishMachine = class("CodeGameScreenPalaceWishMachine", BaseReelMachine)

CodeGameScreenPalaceWishMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenPalaceWishMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型


-- CodeGameScreenPalaceWishMachine.SYMBOL_SCORE_WILD_CAT = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE 
CodeGameScreenPalaceWishMachine.SYMBOL_FIX_BLANK = 999
CodeGameScreenPalaceWishMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenPalaceWishMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1

CodeGameScreenPalaceWishMachine.SYMBOL_WILD_2X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20 -- 113
CodeGameScreenPalaceWishMachine.SYMBOL_WILD_3X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 21 -- 114
CodeGameScreenPalaceWishMachine.SYMBOL_WILD_5X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 22 -- 115
CodeGameScreenPalaceWishMachine.SYMBOL_WILD_8X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 23 -- 116
CodeGameScreenPalaceWishMachine.SYMBOL_WILD_10X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 24 -- 117
CodeGameScreenPalaceWishMachine.SYMBOL_WILD_25X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 25 -- 118
CodeGameScreenPalaceWishMachine.SYMBOL_WILD_100X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 26 -- 119

CodeGameScreenPalaceWishMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集bonus

CodeGameScreenPalaceWishMachine.APPEAR_JUESE = GameEffect.EFFECT_BIGWIN - 3 -- 人物出现

local SELECT_RESPIN_ID = 1
local SELECT_FREESPIN_ID = 2

local TARGET_SYMBOL_COUNT = {3,4,5,6,7}

local CHANGE_SPEED      =       2500 --升行速度

local effectOffset = 150

-- 构造函数
function CodeGameScreenPalaceWishMachine:ctor()
    CodeGameScreenPalaceWishMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    self.m_chooseRepin = false
    self.m_isSuperFree = false
    self.m_isTriggerRespin = false

    self.m_jueseAnimIsPlay = false
    self.m_isLongRun = false
    self.m_respinColEffect = {}
    self.m_isPlayCollect = nil
    self.m_reelUpLinesPanel = {}
    self.m_reelUpLines = {}
    self.m_chooseRepinNotCollect = false
    self.m_isSelectRespin = false
    self.m_jackpotOffsetY = 0
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
 
    --固定的wild
    self.m_lockNodes = {}
    --init
    self:initGame()
end

function CodeGameScreenPalaceWishMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("PalaceWishConfig.csv", "LevelPalaceConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenPalaceWishMachine:initGameStatusData(gameData)
    CodeGameScreenPalaceWishMachine.super.initGameStatusData(self, gameData)
    self.m_nodePos = gameData.gameConfig.extra.node
    if self.m_nodePos == nil then
        self.m_nodePos = 0
    end
    self.m_bonusPath = gameData.gameConfig.init.bonusPath

    --刷新收集数据
    if gameData.collect then
        self:updateCollectData(gameData.collect[1])
    end
end

--[[
    刷新当前收集数据
]]
function CodeGameScreenPalaceWishMachine:updateCollectData(collectData)
    if collectData then
        self.m_collectData = clone(collectData)
    end
end

--[[
    获取当前收集进度
]]
function CodeGameScreenPalaceWishMachine:getCurCollectPercent()
    if not self.m_collectData then
        return 0
    end
    local collectTotalCount = self.m_collectData.collectTotalCount
    local collectCount = self.m_collectData.collectLeftCount

    local percent = (collectTotalCount - collectCount) / collectTotalCount

    return percent
end

---
-- 获取最高的那一列
--
function CodeGameScreenPalaceWishMachine:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()

    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for iCol = 1, self.m_iReelColumnNum, 1 do
        local colNodeName = "sp_reel_" .. (iCol - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

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
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self:addChild(self.m_touchSpinLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
        local pos = util_convertToNodeSpace(self.m_csbOwner["sp_reel_0"],self)
        self.m_touchSpinLayer:setPosition(pos)
        self.m_touchSpinLayer:setName("touchSpin")

        --创建压黑层
        self:createBlackLayer(cc.size(slotW, slotH)) 

        --大信号层
        self.m_bigReelNodeLayer = util_require(self:getBigReelNode()):create({
            size = cc.size(slotW, slotH)
        })
        self.m_clipParent:addChild(self.m_bigReelNodeLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 50)
        self.m_bigReelNodeLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())

        
    end

    local iColNum = self.m_iReelColumnNum
    for iCol = 1, iColNum, 1 do
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))

        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / self.m_iReelRowNum

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = math.floor(columnData.p_slotColumnHeight / self.m_SlotNodeH + 0.5) -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPalaceWishMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "PalaceWish"  
end

-- 继承底层respinView
function CodeGameScreenPalaceWishMachine:getRespinView()
    return "PalaceWishSrc.PalaceWishRespinView"
end
-- 继承底层respinNode
function CodeGameScreenPalaceWishMachine:getRespinNode()
    return "PalaceWishSrc.PalaceWishRespinNode"
end

function CodeGameScreenPalaceWishMachine:getBottomUINode()
    return "PalaceWishSrc.PalaceWishBottomNode"
end

function CodeGameScreenPalaceWishMachine:getReelNode()
    return "PalaceWishSrc.PalaceWishReelNode"
end

function CodeGameScreenPalaceWishMachine:initFreeSpinBar()
    local node_bar = self:findChild("freeBar")
    self.m_baseFreeSpinBar = util_createView("PalaceWishSrc.PalaceWishFreespinBarView", self)
    node_bar:addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
end

function CodeGameScreenPalaceWishMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setFreeType(self.m_isSuperFree)
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar.m_normal_bar:runCsbAction("show", false)
end

function CodeGameScreenPalaceWishMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_baseFreeSpinBar.m_super_bar:setVisible(false)
end


function CodeGameScreenPalaceWishMachine:initUI()

    self.m_changeSizeNode = cc.Node:create()
    self:addChild(self.m_changeSizeNode)

    self.m_respinQuickEffect = self:findChild("Node_respineffect")

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar()

    --收集条
    self.m_collectBar = util_createView("PalaceWishSrc.PalaceWishCollectBar",{machine = self})
    self:findChild("jindutiao"):addChild(self.m_collectBar)

    self.m_respinSpinbar = util_createView("PalaceWishSrc.PalaceWishRespinBarView")
    self:findChild("respinBar"):addChild(self.m_respinSpinbar)
    self.m_respinSpinbar:setVisible(false)

    --jackpot
    self.m_jackpotBar = util_createView("PalaceWishSrc.PalaceWishJackPotBarView",{machine = self})
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:setPositionY(self.m_jackpotOffsetY)

    --图标固定层
    self.m_lockLayer = cc.Node:create()
    self:findChild("root"):addChild(self.m_lockLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)

    self.m_freeWildWaitNode = cc.Node:create()
    self:addChild(self.m_freeWildWaitNode)

    --地图
    self.m_MapView = util_createView("PalaceWishSrc.PalaceWishMap.PalaceWishMapMainView",{machine = self})
    self:addChild(self.m_MapView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_MapView:setVisible(false)
    util_csbScale(self.m_MapView.m_csbNode, self.m_machineRootScale)

    --上方屋顶
    self.m_roofNodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        local roofNode = util_createAnimation("PalaceWish_roof_1.csb")
        self:findChild("roof"..iCol):addChild(roofNode)
        self.m_roofNodes[iCol] = roofNode
        roofNode:findChild("Node_minor"):setVisible(iCol == 3)
        roofNode:findChild("Node_major"):setVisible(iCol == 4)
        roofNode:findChild("Node_grand"):setVisible(iCol == 5)
        roofNode:setVisible(false)
    end

    --人物
    self.m_juese = util_spineCreate("Socre_PalaceWish_juese", true, true)
    self:findChild("juese"):addChild(self.m_juese)
    self.m_juese:setVisible(true)

    self.m_juesePreWin = util_spineCreate("Socre_PalaceWish_juese2", true, true)
    self:addChild(self.m_juesePreWin, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    self.m_juesePreWin:setPosition(display.center)
    self.m_juesePreWin:setVisible(false)

    self.m_effectPreWinDark = util_createAnimation("PalaceWish_respin_Dark.csb")
    self:findChild("Node_dark"):addChild(self.m_effectPreWinDark)
    self.m_effectPreWinDark:setVisible(false)

    self.m_jueseFront = util_spineCreate("Socre_PalaceWish_juese", true, true)
    self:addChild(self.m_jueseFront, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    self.m_jueseFront:setPosition(display.center)
    self.m_jueseFront:setVisible(false)

    --大赢前动效
    self.m_effectBigWin = util_spineCreate("PalaceWish_bigwin", true, true)
    self:findChild("Node_2"):addChild(self.m_effectBigWin)
    self.m_effectBigWin:setLocalZOrder(1000)
    self.m_effectBigWin:setVisible(false)
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode, self:findChild("Node_2"))
    self.m_effectBigWin:setPosition(cc.pAdd(cc.p(endPos), cc.p(0, -30)))


    self:findChild("juese"):setLocalZOrder(10)
    self:findChild("jackpot"):setLocalZOrder(20)
    self:findChild("Node_2"):setLocalZOrder(30)
    self:findChild("freeBar"):setLocalZOrder(40)
    self:findChild("respinBar"):setLocalZOrder(40)
    self:findChild("Node_dark"):setLocalZOrder(42)
    self:findChild("Node_tips"):setLocalZOrder(45)

    --respin wild压暗动效
    self.m_effectRespinWildDark = util_createAnimation("PalaceWish_bonus_tanban_zhezhao.csb")
    self:findChild("Node_center"):addChild(self.m_effectRespinWildDark,10)
    self.m_effectRespinWildDark:setVisible(false)
    self.m_effectRespinWildDark:setPositionY(5)

    --全满动画节点
    self.m_effectRespinFull = util_createAnimation("PalaceWish_bonus_tanban.csb")
    self:addChild(self.m_effectRespinFull, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    self.m_effectRespinFull:setPosition(display.center)
    -- self:findChild("Node_center"):addChild(self.m_effectRespinFull)
    self.m_effectRespinFull:setVisible(false)
    -- local lightEffect = util_createAnimation("PalaceWish_tanban_guang.csb")
    -- self.m_effectRespinFull:findChild("Node_guang"):addChild(lightEffect)
    -- lightEffect:runCsbAction("idle", true)
    -- lightEffect:findChild("Particle_1"):resetSystem()
    -- util_setCascadeOpacityEnabledRescursion(self.m_effectRespinFull:findChild("Node_guang"), true)

    self.m_FAQ = util_createView("PalaceWishSrc.PalaceWishTipsCommonView",self)
    self:findChild("Node_tips"):addChild(self.m_FAQ)
    self.m_FAQ:setVisible(false)

    --过场动画
    self.m_trans = util_spineCreate("Socre_PalaceWish_juese", true, true)
    self:addChild(self.m_trans, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    self.m_trans:setPosition(display.center)
    self.m_trans:setVisible(false)

    self.m_trans2 = util_spineCreate("PalaceWish_guochang", true, true)
    self:addChild(self.m_trans2, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    self.m_trans2:setPosition(display.center)
    self.m_trans2:setVisible(false)

    --respin列特效层
    self.m_respinColEffectLayer = cc.Node:create()
    self:findChild("root"):addChild(self.m_respinColEffectLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)

    self.m_effectRespinFullDark = util_createAnimation("PalaceWish_bonus_tanban_zhezhao.csb")
    -- self:findChild("Node_center"):addChild(self.m_effectRespinFullDark,10)
    local nodePos = util_convertToNodeSpace(self:findChild("Node_center"), self.m_respinColEffectLayer)
    self.m_respinColEffectLayer:addChild(self.m_effectRespinFullDark, 1000)
    self.m_effectRespinFullDark:setVisible(false)
    self.m_effectRespinFullDark:setPosition(cc.pAdd(cc.p(nodePos), cc.p(0, 5)))
    
    self:addClick(self:findChild("Panel_jueseClick"))


    self:createRespinCollectColFullEffect(  )
    self:runJueseIdleAni()
    self:changeWinCoinEffectCsb(true)--self:playCoinWinEffectUI()
    self:createUpEffectClip()

    self:initUpLine()



    

end

--升行条设置信息
function CodeGameScreenPalaceWishMachine:initUpLine()
    
    -- local reel0 = self:findChild("sp_reel_0")
    -- local posNode = util_convertToNodeSpace(reel0, self:findChild("Node_2"))
    -- for iCol = 2,self.m_iReelColumnNum do
    --     local line = self:findChild("reel_in"..(iCol - 1))
    --     if line then
    --         local oldSize = line:getContentSize()
    --         local rowH = self.m_SlotNodeH * TARGET_SYMBOL_COUNT[iCol]
    --         line:setContentSize(cc.size(rowH, oldSize.height))
    --         line:setAnchorPoint(cc.p(0, 0.5))

    --         posNode = cc.p(posNode)
    --         line:setPositionY(posNode.y)
    --     end

    -- end


    --5 是右侧   icol6
    local reel0 = self:findChild("sp_reel_0")
    local posNode = util_convertToNodeSpace(reel0, self:findChild("Node_2"))
    for iCol = 2,self.m_iReelColumnNum + 1 do
        local panel = self:findChild("Panel_ReelUp"..(iCol - 1))
        if panel then
            local oldSize = panel:getContentSize()
            local rowH = nil
            if iCol > self.m_iReelColumnNum then
                rowH = self.m_SlotNodeH * TARGET_SYMBOL_COUNT[5]
            else
                rowH = self.m_SlotNodeH * TARGET_SYMBOL_COUNT[iCol]
            end
            panel:setContentSize(cc.size(oldSize.width, rowH + 100))
            panel:setAnchorPoint(cc.p(0.5, 0))
            panel:setTouchEnabled(false)
            panel:setSwallowTouches(false)

            posNode = cc.p(posNode)
            panel:setPositionY(posNode.y)

            self.m_reelUpLinesPanel[iCol] = panel
            self.m_reelUpLines[iCol] = self:findChild("Node_ReelUp_"..(iCol - 1))
            self.m_reelUpLinesPanel[iCol]:setVisible(false)
        end
    end
end

--[[
    设置base界面是否显示
]]
function CodeGameScreenPalaceWishMachine:setBaseViewVisible(isShow)
    self:findChild("Node_1"):setVisible(isShow)
end


function CodeGameScreenPalaceWishMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "PalaceWishSounds/music_PalaceWish_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenPalaceWishMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self:setEndSize(false)

    -- if self.m_initSpinData then
    --     if self.m_initSpinData.p_reSpinsTotalCount ~= nil and self.m_initSpinData.p_reSpinsTotalCount > 0 and self.m_initSpinData.p_reSpinCurCount > 0 then
    --         self.m_iReelRowNum = 7
    --     end
    -- end
    

    CodeGameScreenPalaceWishMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    --刷新bet等级
    self:updateBetLevel(true)

    --刷新收集进度
    -- self.m_collectBar:updateProgress()
    
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        local selfData =  self.m_runSpinResultData.p_selfMakeData or {}
        local freespinType = selfData.freespinType
        if freespinType == "collect" then
            self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.node
            if self.m_nodePos == 0 then
                self.m_nodePos = #self.m_bonusPath
            end
            local gameType = self.m_bonusPath[self.m_nodePos]
            self.m_fsReelDataIndex = gameType

            self.m_collectBar:setVisible(false)
            self.m_bottomUI:showAverageBet()
            self.m_isSuperFree = true
            self.m_baseFreeSpinBar:setFreeType(self.m_isSuperFree)

            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

            self:showMainUI( "superFree", false, true)

            
        else
            self:setMaxReelSize()
            self:showMainUI( "free", false, true)
        end
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self:showMainUI( "respin", false, true)
    else
        self:showMainUI( "base", false, true)

        self.m_FAQ:TipClick(  )

        self:firstInit()
    end

end

function CodeGameScreenPalaceWishMachine:addObservers()
    CodeGameScreenPalaceWishMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if self.m_classicMachine then
            return
        end

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
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

        if winRate > 1 and not self.m_bIsBigWin then
            local rand = math.random(0, 100)
            if rand < 50 then
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_juese_language_4.mp3")
            else
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_juese_language_5.mp3")
            end
            
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "PalaceWishSounds/sound_PalaceWish_free_last_win_".. soundIndex .. ".mp3"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_isSuperFree then
                soundName = "PalaceWishSounds/sound_PalaceWish_superfree_last_win_".. soundIndex .. ".mp3"
            else
                soundName = "PalaceWishSounds/sound_PalaceWish_free_last_win_".. soundIndex .. ".mp3"
            end
        else
            soundName = "PalaceWishSounds/sound_PalaceWish_base_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
        end
        

    end,ViewEventType.NOTIFY_BET_CHANGE)
end

--[[
    刷新当前bet等级
]]
function CodeGameScreenPalaceWishMachine:updateBetLevel(_isInit)
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 
    if betCoin >= self.m_specialBets[1].p_totalBetValue then
        level = 1
    end

    if level == 0 and self.m_iBetLevel ~= level then
        self.m_collectBar:lockAni(_isInit)
    elseif level == 1 and self.m_iBetLevel ~= level then
        self.m_collectBar:unlockAni(_isInit)
    end

    self.m_iBetLevel = level
end

--[[
    切换至高bet
]]
function CodeGameScreenPalaceWishMachine:changeBetToHighLevel()
    if self.m_iBetLevel == 1 or not self:collectBarClickEnabled() then
        return
    end
    self.m_bottomUI:changeBetCoinNumToHight()
end

function CodeGameScreenPalaceWishMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    --停止计时器
    self.m_changeSizeNode:unscheduleUpdate()

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    CodeGameScreenPalaceWishMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPalaceWishMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_PalaceWish_Bonus"

    elseif symbolType == self.SYMBOL_FIX_BLANK then
        return "PalaceWish_respin_bg"

    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_PalaceWish_10"

    elseif self:isWildSymbol(symbolType) then
        return "Socre_PalaceWish_Wild"

    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPalaceWishMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenPalaceWishMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenPalaceWishMachine:MachineRule_initGame(  )

    local percent = self:getCurCollectPercent()
    self.m_collectBar:setPercent(percent)
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        
        
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenPalaceWishMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenPalaceWishMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

----------- respin相关
function CodeGameScreenPalaceWishMachine:showRespinView()
    self:delayCallBack(0.5, function (  )
        --先播放动画 再进入respin
        if not self.m_isSelectRespin then
            self:clearCurMusicBg()
        end
        

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        --清空赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        
        self.m_isTriggerRespin = true


        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_trigger.mp3")

        --respin触发动画
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    if self:isFixSymbol(node.p_symbolType) then
                        self:setSymbolToClipParent(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 0)
                        
                        node:runAnim("actionframe", false, function (  )
                            node:runAnim("idleframe2", true)
                        end)
                        
                    end
                end
            end
        end

        self:setSymbolToClipReel(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)

        if self.m_blackLayer then
            self.m_blackLayer:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - 50)
        end

        self:showBlackLayer()
        self:delayCallBack(2-0.2,function()
            self:hideBlackLayer( )
        end)
        
        if self.m_isSelectRespin then
            self:delayCallBack(0.2, function()
                self:changeSymbolToBlank(  )
            end)
            self:runJueseOverAni(function()
            end)
        else
        end

        local upRow = function()
            self:runJueseReelUpAni(function (  )
                self:runUpEffect(function ( col )
                    if col == 1 then
                        self:changeReelSize(function(  )
                            --可随机的普通信息
                            local randomTypes = self:getRespinRandomTypes( )
            
                            --可随机的特殊信号 
                            local endTypes = self:getRespinLockTypes()
                            
                            --构造盘面数据
                            self:triggerReSpinCallFun(endTypes, randomTypes)
            
                            
                        end)
                    end
                    if col == 3 or col == 4 or col == 5 then
                        --顶部动画
                        self:showJackpotRoofAnim( 6-col, "start", "idle", function (  )
                            
                        end )
                    end
                end, function()
                    --升行后设置roof
                    for iCol = 1,self.m_iReelColumnNum do
                        local roofNode = self.m_roofNodes[iCol]
                        roofNode:setVisible(true)
                
                        roofNode:findChild("Node_minor"):setVisible(iCol == 3)
                        roofNode:findChild("Node_major"):setVisible(iCol == 4)
                        roofNode:findChild("Node_grand"):setVisible(iCol == 5)
                    end


                    --升行结束
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    self.m_respinSpinbar:runCsbAction("show", false, function ()

                    end)

                    if self.m_isSelectRespin then
                        self:resetMusicBg(nil,"PalaceWishSounds/music_PalaceWish_Bg_respin.mp3")
                    end
                    
                end)
                
            end)
        end

        self:delayCallBack(2, function (  )
            if self.m_isSelectRespin then
                --选择respin
                upRow()
                
            else
                --base respin
                self:showReSpinStart(function()
                    self:runJueseOverAni(function() --角色下移
                        upRow()
                    end)
                    
                end, function (  )
                    -- self:setCurrSpinMode( RESPIN_MODE)
                    -- self:resetMusicBg() 
                    self:resetMusicBg(nil,"PalaceWishSounds/music_PalaceWish_Bg_respin.mp3")

                    --切ui
                    -- self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    
                    self:hideUIForChangeSize()
    
                    self:showMainUI( "respin" )

                    self:changeSymbolToBlank(  )
                end)

            end
            
        end)
        
    end)
    
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenPalaceWishMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_FIX_SYMBOL,
        self.SYMBOL_FIX_BLANK
        -- self.SYMBOL_SCORE_10,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenPalaceWishMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling", bRandom = false},
        -- {type = self.SYMBOL_BONUS_2, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

function CodeGameScreenPalaceWishMachine:initRespinView(endTypes, randomTypes)
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
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
            self:runNextReSpinReel()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function CodeGameScreenPalaceWishMachine:changeReSpinStartUI(respinCount)

    self.m_respinSpinbar:setVisible(true)
    self.m_respinSpinbar:changeRespinTimes(respinCount,true)
   
end

--ReSpin刷新数量
function CodeGameScreenPalaceWishMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_respinSpinbar:changeRespinTimes(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenPalaceWishMachine:changeReSpinOverUI()
    self.m_respinSpinbar:setVisible(false)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenPalaceWishMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = TARGET_SYMBOL_COUNT[iCol]
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if not symbolType then
                symbolType = self.SYMBOL_FIX_BLANK
            end

            if symbolType ~= 94 then
                symbolType = self.SYMBOL_FIX_BLANK
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


function CodeGameScreenPalaceWishMachine:respinOver()
    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self.m_respinQuickEffect:removeAllChildren()
    self:removeRespinNode()
    self:showRespinOverView()

    self.m_isSelectRespin = false
end

function CodeGameScreenPalaceWishMachine:showRespinOverView(effectData)
    local rand = math.random(0, 100)
    if rand < 50 then
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_overpopup_begin1.mp3")
    else
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_overpopup_begin2.mp3")
    end
    


    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:showTrans2( function (  )
            
            self:showMainUI( "base" , true)

            --设置UI最终尺寸
            self:setNormalReelSize()

            self:addJueseStartEffect()

            self:changeBlankSymbolToRandom(  )
        end, function (  )
            self:setCurrSpinMode( NORMAL_SPIN_MODE)
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_isTriggerRespin = false
            self.m_lightScore = 0
            self:resetMusicBg() 

            if self:BaseMania_isTriggerCollectBonus()  then
                self:addBonusEffect( )
            end 

            -- self:runJueseStartAni()
        end )
         
    end)
    view:setOverActBeginCallFunc(function()
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_overpopup_end.mp3")
    end)


    view:findChild("root"):setScale(self.m_machineRootScale)

    local spine = util_spineCreate("Socre_PalaceWish_tanban", true, true)
    view:findChild("spine_ren"):addChild(spine)
    util_setCascadeOpacityEnabledRescursion(view:findChild("spine_ren"), true)
    util_spinePlay(spine, "ClassicOver_start", false)
    local spineEndCallFunc = function()
        util_spinePlay(spine, "ClassicOver_idle", true)
    end
    util_spineEndCallFunc(spine, "ClassicOver_start", spineEndCallFunc)

    local lightEffect = util_createAnimation("PalaceWish_tanban_guang.csb")
    view:findChild("Node_guang"):addChild(lightEffect)
    lightEffect:runCsbAction("idle", true)
    lightEffect:findChild("Particle_1"):resetSystem()
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"), true)
    

    local label = view:findChild("m_lb_coins")
    view:updateLabelSize({label=label,sx=1,sy=1},681)

end

function CodeGameScreenPalaceWishMachine:showReSpinOver(coins,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 50)
    return self:showLocalDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER,ownerlist,func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenPalaceWishMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("PalaceWishSounds/music_PalaceWish_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            if self.m_isSuperFree then
                self:showMainUI( "superFree", false)
                self.m_collectBar:setVisible(false)

                local view = self:showLocalDialog("SuperFreeSpinStart", nil,function()
                    globalData.slotRunData.lastWinCoin = 0
                    self.m_bottomUI:checkClearWinLabel()
                    self.m_bottomUI:showAverageBet()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect() 

                    self:clearCurMusicBg()
                    self:resetMusicBg(nil,"PalaceWishSounds/music_PalaceWish_Bg_superFree.mp3")
                end)

                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_superfree_startpopup_begin.mp3")
                
                util_spinePlay(self.m_juese, "idleframe3", true)

                view:findChild("root"):setScale(self.m_machineRootScale)
                local spine = util_spineCreate("PalaceWish_tanban_di", true, true)
                view:findChild("Node_spine"):addChild(spine)
                util_setCascadeOpacityEnabledRescursion(view:findChild("Node_spine"), true)
                util_spinePlay(spine, "start", false)
                local spineEndCallFunc = function()
                    util_spinePlay(spine, "idle", true)
                end
                util_spineEndCallFunc(spine, "start", spineEndCallFunc)

                view:setOverActBeginCallFunc(function()

                    -- self:clearCurMusicBg()
                    self:bgMusicDown( 0.5 )

                    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_trans_popupup.mp3")

                    util_spinePlay(spine, "over", false)
                    
                end)
        
                view:findChild("BitmapFontLabel_1"):setString(globalData.slotRunData.totalFreeSpinCount)
                for index = 1,4 do
                    view:findChild("Node_daguan"..index):setVisible(self.m_fsReelDataIndex == index)
                end

                
            else
                self.m_fsReelDataIndex = 0
                self:runJueseOverAni(function() --角色下移
                    self:runJueseReelUpAni(function (  )
                        self:runUpEffect(function ( col )
                            if col == 1 then
                                self:changeReelSize(function(  )
                                    self:triggerFreeSpinCallFun()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()  
                                end)
                            end
                        end)
                        
                    end)
                end)
                

                -- self:resetMusicBg(nil,"PalaceWishSounds/music_PalaceWish_Bg_free.mp3")
            end

            
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenPalaceWishMachine:getFreeSpinMusicBG()
    if self.m_isSuperFree then
        return "PalaceWishSounds/music_PalaceWish_Bg_superFree.mp3"
    else
        return "PalaceWishSounds/music_PalaceWish_Bg_free.mp3"
    end
    -- return self.m_fsBgMusicName
end

function CodeGameScreenPalaceWishMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("PalaceWishSounds/music_PalaceWish_over_fs.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

        local cut = function()
            self:addJueseStartEffect() --添加人物出现effect

            if not self.m_isSuperFree then
                
                --变更裁切层大小
                self:clearWinLineEffect()

                --设置UI最终尺寸
                self:setNormalReelSize()
                self:showMainUI( "base" , true)

                
            else
                --重置 断线重连后直接进没重置问题
                self.m_collectBar:resetProgress()
                self.m_collectBar:mapIdle()

                self.m_bottomUI:hideAverageBet()
                self.m_collectBar:setVisible(true)
                self:showMainUI( "base" , true, false)
            end
            self.m_isSuperFree = false
        end
        if not self.m_isSuperFree then
            --free
            self:showTrans(40/30,70/30,"free",function (  )
                cut()
    
            end,function (  )
                self:triggerFreeSpinOverCallFun()
    
                -- self:runJueseStartAni()
            end,true,self.m_isSuperFree)
        else
            --super free
            local actionName = "actionframe_guochang"
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_trans_juese_superfree.mp3")
            
            util_spinePlay(self.m_juese, actionName, false)
            self.m_jueseAnimIsPlay = true
            self.m_jueseTemp = self.m_juese
            self:delayCallBack(1/30, function()
                local posNode = util_convertToNodeSpace(self:findChild("juese"), self)
                util_changeNodeParent(self, self.m_juese, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5) 
                self.m_juese:setPosition(posNode)
                
            end)
            self:delayCallBack(32/30, function (  )
                cut()
            end)

            -- self:delayCallBack(70/30, function()
                
            -- end)
            self:delayCallBack(80/30, function()
                self.m_juese = util_spineCreate("Socre_PalaceWish_juese", true, true)
                self:findChild("juese"):addChild(self.m_juese)
                self:setJueseOrderFront(10)
        
                -- util_spinePlay(self.m_juese, "start", false)
                -- local spineEndCallFunc = function()
                --     self.m_jueseAnimIsPlay = false
                --     self:runJueseIdleAni()
                -- end
                -- util_spineEndCallFunc(self.m_juese, "start", spineEndCallFunc)

                if self.m_jueseTemp and not tolua.isnull(self.m_jueseTemp) then
                    self.m_jueseTemp:removeFromParent()
                    self.m_jueseTemp = nil
                end

                self:triggerFreeSpinOverCallFun()
                self.m_fsReelDataIndex = 0
            end)

            
        end
        

        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},681)

end

function CodeGameScreenPalaceWishMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    local view
    if self.m_isSuperFree then
        view = self:showLocalDialog("SuperFreeSpinOver", ownerlist, func)

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_superfree_overpopup_begin.mp3")
    else
        view = self:showLocalDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

        local rand = math.random(0, 100)
        if rand < 50 then
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_free_overpopup_begin1.mp3")
        else
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_free_overpopup_begin2.mp3")
        end
        
    end
    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setOverActBeginCallFunc(function()
        if self.m_isSuperFree then
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_superfree_overpopup_end.mp3")
        else
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_free_overpopup_end.mp3")
        end
    end)

    local spine = util_spineCreate("Socre_PalaceWish_tanban", true, true)
    view:findChild("spine_ren"):addChild(spine)
    util_setCascadeOpacityEnabledRescursion(view:findChild("spine_ren"), true)
    util_spinePlay(spine, "ClassicOver_start", false)
    local spineEndCallFunc = function()
        util_spinePlay(spine, "ClassicOver_idle", true)
    end
    util_spineEndCallFunc(spine, "ClassicOver_start", spineEndCallFunc)

    local lightEffect = util_createAnimation("PalaceWish_tanban_guang.csb")
    view:findChild("Node_guang"):addChild(lightEffect)
    lightEffect:runCsbAction("idle", true)
    lightEffect:findChild("Particle_1"):resetSystem()
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"), true)
    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPalaceWishMachine:MachineRule_SpinBtnCall()
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:setMaxMusicBGVolume( )
   
    self.m_FAQ:hideTips(  )


    return false -- 用作延时点击spin调用
end

function CodeGameScreenPalaceWishMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")

    if self.m_classicMachine ~= nil then
        return
    end

    CodeGameScreenPalaceWishMachine.super.quicklyStopReel(self,colIndex)
   
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPalaceWishMachine:addSelfEffect()

    if self.m_iBetLevel == 1
    and globalData.slotRunData.currSpinMode ~= RESPIN_MODE and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE
    and self.m_runSpinResultData.p_storedIcons and #self.m_runSpinResultData.p_storedIcons > 0  then
        if not self.m_chooseRepinNotCollect then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
        end
        

        if self.m_chooseRepinNotCollect then
            self.m_chooseRepinNotCollect = false
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPalaceWishMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then

        self:collectBonusAni(function(  )
            if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
                self:delayCallBack(0.5,function(  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            else
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end)
        

    end

    if effectData.p_selfEffectType == self.APPEAR_JUESE then
        self:runJueseStartAni(effectData)
    end
    
    return true
end

--添加人物出现effect
function CodeGameScreenPalaceWishMachine:addJueseStartEffect()
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.APPEAR_JUESE
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.APPEAR_JUESE -- 动画类型

    self:sortGameEffects( )
end

--[[
    收集bonus动画
]]
function CodeGameScreenPalaceWishMachine:collectBonusAni(func)
    if type(func) == "function" then
        func()
    end

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                self:flyBonusAni(symbolNode,self.m_collectBar.m_coinIcon)
            end
        end
    end

    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_base_collect_fly_begin.mp3")

    self:delayCallBack(0.5,function(  )
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_base_collect_fly_end.mp3")
        self.m_collectBar:collectStart()
        --刷新收集进度
        self.m_collectBar:updateProgress()
    end)
end

--[[
    收集bonus飞行动画
]]
function CodeGameScreenPalaceWishMachine:flyBonusAni(startNode,endNode,func)
    
    local flyNode = util_createAnimation("Socre_PalaceWish_FixBonus_tuowei.csb")

    self.m_effectNode:addChild(flyNode)

    for index = 1,2 do
        local particle = flyNode:findChild("Particle_"..index)
        if particle then
            particle:setPositionType(0)
        end
    end

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.BezierTo:create(0.5,{startPos, cc.p(endPos.x, startPos.y), endPos}),
        cc.CallFunc:create(function(  )
            for index = 1,3 do
                local particle = flyNode:findChild("Particle_"..index)
                if particle then
                    particle:stopSystem()
                end
            end
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

function CodeGameScreenPalaceWishMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:delayCallBack(0.3,function(  )
            self:normalSpinBtnCall()
        end)
        
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end

function CodeGameScreenPalaceWishMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenPalaceWishMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenPalaceWishMachine:delaySlotReelDown( )
    CodeGameScreenPalaceWishMachine.super.delaySlotReelDown(self)
    for index = 1,#self.m_gameEffects do
        local effectData = self.m_gameEffects[index]
        local bonusGameEffect = GameEffectData.new()
        --freespin和收集同时触发时,保证收集在最后播
        if effectData.p_effectType == GameEffect.EFFECT_BONUS then
            effectData.p_effectOrder = GameEffect.EFFECT_DELAY_SHOW_BIGWIN + 1
        end
    end

    self:sortGameEffects( )
end

function CodeGameScreenPalaceWishMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    

    if #self.m_lockNodes > 0 then
        self:changeSymbolToWild()
    end

    
    
    


    CodeGameScreenPalaceWishMachine.super.slotReelDown(self)
end

--[[
    将卷轴上的小块变为wild
]]
function CodeGameScreenPalaceWishMachine:changeSymbolToWild()
    for index,lockNode in ipairs(self.m_lockNodes) do
        local posIndex = lockNode.m_posIndex
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX

        local symbolNode = self:getFixSymbol(iCol,iRow)
        --变更小块信号
        if symbolNode and symbolNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD)
            --更新皮肤
            if self:isWildSymbol(symbolNode.p_symbolType) then
                self:wildChangeShow(symbolNode)
            end
        end
    end

    self:clearLockWild()
end

--[[
    清空固定的wild信号
]]
function CodeGameScreenPalaceWishMachine:clearLockWild()
    self.m_lockNodes = {}
    self.m_lockLayer:removeAllChildren()
end

--[[
    判断是否为bonus小块
]]
function CodeGameScreenPalaceWishMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return true
    end
    
    return false
end

--[[
    刷新小块
]]
function CodeGameScreenPalaceWishMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end

    if self:isWildSymbol(symbolType) then
        self:wildChangeShow(node)
    end
end

function CodeGameScreenPalaceWishMachine:getWildSkinName(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "wild"
    elseif symbolType == self.SYMBOL_WILD_2X then
        return "wild_2"
    elseif symbolType == self.SYMBOL_WILD_3X then
        return "wild_3"
    elseif symbolType == self.SYMBOL_WILD_5X then
        return "wild_5"
    elseif symbolType == self.SYMBOL_WILD_8X then
        return "wild_8"
    elseif symbolType == self.SYMBOL_WILD_10X then
        return "wild_10"
    elseif symbolType == self.SYMBOL_WILD_25X then
        return "wild_25"
    elseif symbolType == self.SYMBOL_WILD_100X then
        return "wild_100"
    end
    return "default"
end

function CodeGameScreenPalaceWishMachine:wildChangeShow(node)
    if node.m_csbNode then
        node.m_csbNode = nil
    end
    local bonusName = self:getWildSkinName(node.p_symbolType)
    local ccbNode = node:getCCBNode()
    if not ccbNode then
        node:checkLoadCCbNode()
    end
    ccbNode = node:getCCBNode()
    if ccbNode then
        ccbNode.m_spineNode:setSkin(bonusName)
    end
end

-- 给respin小块进行赋值
function CodeGameScreenPalaceWishMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    -- local rowCount = 0
    -- if iCol ~= nil then
    --     local columnData = self.m_reelColDatas[iCol]
    --     rowCount = columnData.p_showGridCount
    -- end

    local score = 0
    if iRow ~= nil and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    
    if symbolNode and symbolNode.p_symbolType then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local isHigh = false
        if score >= 5 then
            isHigh = true
        end

        score = score * lineBet
        symbolNode.m_score = score
        
        
        score = util_formatCoins(score, 3)
        self:bonusShowScore(symbolNode, score, isHigh)
        
    end

end

--[[
    显示bonus分数
]]
function CodeGameScreenPalaceWishMachine:bonusShowScore(_symbolNode, _scoreStr, isHigh)
    if _symbolNode then
        local aniNode = _symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        if spine then
            util_spineRemoveSlotBindNode(spine, "zi")
            spine.m_scoreViewNode = nil
            if not spine.m_scoreViewNode then
                -- util_spineRemoveSlotBindNode(spine, "zi")
                local label
                if isHigh then
                    label = util_createAnimation("Socre_PalaceWish_FixBonus_0.csb")
                else
                    label = util_createAnimation("Socre_PalaceWish_FixBonus.csb")
                end
                 
                label:setScale(0.8)
                util_spinePushBindNode(spine, "zi", label)
                spine.m_scoreViewNode = label

                util_setCascadeOpacityEnabledRescursion(spine, true)
                
            end
            spine.m_scoreViewNode:setVisible(true)
            spine.m_scoreViewNode:findChild("m_lb_score"):setString(_scoreStr)
            self:updateLabelSize({label=spine.m_scoreViewNode:findChild("m_lb_score"),sx=1,sy=1},162)
        end

    end
end

--[[
    播放bonus分数动画
]]
function CodeGameScreenPalaceWishMachine:bonusPlayScore(_symbolNode, _animName, _loop, _func)
    if _symbolNode and not tolua.isnull(_symbolNode) then
        local aniNode = _symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        if spine and spine.m_scoreViewNode then
            if not tolua.isnull(spine.m_scoreViewNode) then
                if _loop then
                    spine.m_scoreViewNode:runCsbAction(_animName, _loop)
                else
                    if not tolua.isnull(spine.m_scoreViewNode.m_csbAct) then
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


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenPalaceWishMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local score = nil
    local idNode = nil

    local func = function(_id)
        for i=1, #storedIcons do
            local values = storedIcons[i]
            if values[1] == _id then
                score = values[2]
                idNode = values[1]
            end
        end
    end
    func(id)
    

    if score == nil then
        func(id + 20)   --转换到7行pos去查询 服务端给的是七行数据pos
        if score == nil then
            return self:randomDownRespinSymbolScore(self.SYMBOL_FIX_SYMBOL)
        end
        
    end

    -- local pos = self:getRowAndColByPos(idNode)

    return score
end

function CodeGameScreenPalaceWishMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

---
-- 处理spin 返回消息的数据结构
--
function CodeGameScreenPalaceWishMachine:operaSpinResultData(param)
    local spinData = param[2]
    self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)



    local triggerWinning = function()
        local currSpinMode = self:getCurrSpinMode()
        if (currSpinMode == NORMAL_SPIN_MODE or currSpinMode == AUTO_SPIN_MODE) and not self.m_chooseRepinNotCollect then
            self.m_isPlayWinningNotice = math.random(0, 100) < 40
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_isSuperFree then
        if spinData.result.selfData.free then
            self.m_runSpinResultData.p_reels = spinData.result.selfData.free.reels
            for iRow = 1,#self.m_runSpinResultData.p_reels do
                for iCol = 1,#self.m_runSpinResultData.p_reels[iRow] do
                    if self.m_runSpinResultData.p_reels[iRow][iCol] == -1000 then
                        self.m_runSpinResultData.p_reels[iRow][iCol] = math.random(0,8)
                    end
                end
            end

            self.m_runSpinResultData:parseWinLines(spinData.result.selfData.free,self.m_lineDataPool)

            self.m_runSpinResultData.p_reelsData = self.m_runSpinResultData.p_reels
        end
        
    elseif self.m_runSpinResultData.p_features[2] == 3 then
        triggerWinning()
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusMode
    if bonusTypes then
        if bonusTypes == "select"  then
            triggerWinning()
        end
    end
    
end

function CodeGameScreenPalaceWishMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or (self.m_isSuperFree) then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function CodeGameScreenPalaceWishMachine:updateNetWorkData()
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

    

    self:produceSlots()
    local selfData = self.m_runSpinResultData.p_selfMakeData

    -- local feature = self.m_runSpinResultData.p_features
    -- for index = 1,#feature do
    --     if feature[index] == SLOTO_FEATURE.FEATURE_RESPIN then
    --         self.m_iReelRowNum = 7
    --         break
    --     end
    -- end

    --刷新数据
    if self.m_runSpinResultData.p_collectNetData then
        self:updateCollectData(self.m_runSpinResultData.p_collectNetData[1])
    end
    if selfData and selfData.node then
        self.m_nodePos = selfData.node
    end

    local nextProcess = function (  )
        --添加固定wild
        if selfData and selfData.catWildPositions and #selfData.catWildPositions > 0 then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:runJueseWildRandomAni(function (  )
                    self:createLockWild(function(  )
                        
                    end, function (  )
                        if self.m_effectRespinWildDark:isVisible() then
                            self.m_effectRespinWildDark:runCsbAction("over", false, function (  )
                                self.m_effectRespinWildDark:setVisible(false)
                            end)
                        end
                    end)
                end, function (  )
                    
                end, "free")
                self:operaNetWorkData()
            elseif (self:getCurrSpinMode() == NORMAL_SPIN_MODE or 
            self:getCurrSpinMode() == AUTO_SPIN_MODE) then
                self:runJueseOverAni(function() --人物隐藏
                    self:runJueseWildRandomAni(function (  ) --喷雾
                        self:createLockWild(function(  )
                            
                        end, function (  )
    
                        end)
                    end, function (  )
                        self:runJueseStartAni(nil, function()
                        end)
                    end)
                    self:operaNetWorkData()
                end)
                
                
            end
            
        else
            self:operaNetWorkData()
        end
    end
    


    if self.m_isPlayWinningNotice then
        self:preViewWin(function()
            nextProcess()
        end)
    else
        nextProcess()
    end
    
end

--[[
    固定wild动画
]]
function CodeGameScreenPalaceWishMachine:createLockWild(func,func2)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wildPos = selfData.catWildPositions

    if not wildPos then
        return
    end
    for index = 1,#wildPos do
        local tarIndex = wildPos[index]
        local clipTarPos = util_getOneGameReelsTarSpPos(self, tarIndex)
        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
        local nodePos = self.m_lockLayer:convertToNodeSpace(worldPos)

        local lockNode = util_spineCreate("Socre_PalaceWish_Wild", true, true)
        self.m_lockLayer:addChild(lockNode)
        lockNode.m_posIndex = tarIndex
        lockNode:setPosition(nodePos)
        self.m_lockNodes[#self.m_lockNodes + 1] = lockNode 

        util_spinePlay(lockNode, "start", false)
        local spineEndCallFunc = function()
            util_spinePlay(lockNode, "idleframe", true)
            if index == 1 then
                func2()
            end
        end
        util_spineEndCallFunc(lockNode, "start", spineEndCallFunc)
    end

    if type(func) == "function" then
        func()
    end
end

--[[
    显示地图界面
]]
function CodeGameScreenPalaceWishMachine:showMapView( func )
    self.m_MapView:BonusTriggerShowMap( )
    self.m_MapView:setCanClick(false)
    self.m_MapView:updateRunLittleUINodeAct( self.m_nodePos,self.m_bonusPath )
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_map_start.mp3")
    self.m_MapView:runCsbAction("start",false,function(  )
        self.m_MapView:runCsbAction("idle",true)
        local littleUiAct = function(  )
            self.m_MapView:runLittleUINodeAct(self.m_nodePos,self.m_bonusPath,function(  )
                self:delayCallBack(1,function(  )
                    --重置收集进度
                    self.m_collectBar:resetProgress()
                    self.m_collectBar:mapIdle()
                    if func then
                        func()
                    end
                    self:delayCallBack(100/60,function(  )
                        self.m_MapView:BonusTriggercloseUi(function(  )
                        
                        end)
                    end)
                    
                end)
            end )
        end
        if self.m_nodePos == 1 then
            self.m_MapView.m_tipaCat:setVisible(true)
            local pos = cc.p(self.m_MapView["m_point_"..(self.m_nodePos -1)]:getParent():getPosition())
            self.m_MapView.m_tipaCat:setPosition(pos)
            -- self.m_MapView.m_tipaCat:playAction("animation0")
            self.m_MapView:playStart(  )
            -- self.m_MapView:catJump( pos,function(  )
                littleUiAct()
            -- end)
        else

            if self.m_bonusPath[self.m_nodePos] == 0 then
                --小节点
                self.m_MapView:beginLittleUiCatAct(self.m_nodePos,function(  )
                    littleUiAct()
                end )
            else
                --大节点
                self.m_MapView:beginLittleUiCatAct(self.m_nodePos,function(  )

                    self:delayCallBack(0.5,function(  )
                        littleUiAct()
                    end)

                end )
            end
        end
    end)
end

--[[
    是否触发收集小游戏
]]
function CodeGameScreenPalaceWishMachine:BaseMania_isTriggerCollectBonus()
    

    local features = self.m_runSpinResultData.p_features
    if features and features[2] and features[2] == 5 then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusTypes =  selfdata.bonusMode

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            if self:getCurrSpinMode() ~= RESPIN_MODE then
                if bonusTypes and bonusTypes == "collect"  then
                    return true
                end
            end
            
        end
          
    end

    return false

end

--[[
    初始化feature数据
]]
function CodeGameScreenPalaceWishMachine:initFeatureInfo(spinData,featureData)

    if featureData.p_bonus and featureData.p_bonus.status == "OPEN" then
        self.m_fsReelDataIndex = self.m_bonusPath[self.m_nodePos]
        self:addBonusEffect()
    end
end

--[[
    检测添加bonus事件
]]
function CodeGameScreenPalaceWishMachine:addBonusEffect( )
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_DELAY_SHOW_BIGWIN + 1
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    self.m_isRunningEffect = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

end

function CodeGameScreenPalaceWishMachine:showBonusGameView(effectData)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    self.m_bottomUI:checkClearWinLabel()
    

    local endFunc = function(  )
        self.m_bottomUI:hideAverageBet()
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusMode
    if bonusTypes then

        if bonusTypes == "select"  then
            
            -- 停掉背景音乐
            self:clearCurMusicBg()

            self:show_Choose_BonusGameView(endFunc)


        else
            --延时收集时间
            self:delayCallBack(1, function (  )
                --集满触发动画
                self.m_collectBar:collectFull(function (  )
                    if self:BaseMania_isTriggerCollectBonus()  then
                        self:showMapView(function(  )
                            self:show_Map_BonusGameView(endFunc)
                        end)
                    else
                        self:show_Map_BonusGameView(endFunc)
                    end  
                end)
                
            end)
            

        end

    else
        endFunc()
    end
end

--[[
    显示选择界面
]]
function CodeGameScreenPalaceWishMachine:show_Choose_BonusGameView(func)

    self:scatterTriggerAnim(function (  )
        local chooseView = util_createView("PalaceWishSrc.PalaceWishChooseView",self)
        gLobalViewManager:showUI(chooseView)
        chooseView:findChild("root"):setScale(self.m_machineRootScale)

        chooseView:setEndCall( function( selectId ) 

            if selectId == SELECT_RESPIN_ID then --选择respin
                self:showMainUI( "respin" )

                -- self:setCurrSpinMode( RESPIN_MODE)
                -- self:resetMusicBg() 
                -- self:resetMusicBg(nil,"PalaceWishSounds/music_PalaceWish_Bg_respin.mp3")
            else
                self:showMainUI( "free" )

                self:resetMusicBg(nil,"PalaceWishSounds/music_PalaceWish_Bg_free.mp3")
            end
            

        end, function ( selectId )
            if selectId == SELECT_RESPIN_ID then --选择respin
                self.m_iFreeSpinTimes = 0 
                globalData.slotRunData.freeSpinCount = 0
                globalData.slotRunData.totalFreeSpinCount = 0      
                self.m_bProduceSlots_InFreeSpin = false

                self.m_chooseRepin = true
                self.m_chooseRepinNotCollect = true
                self.m_isSelectRespin = true
            else
                self:bonusOverAddFreespinEffect( )
            end

            if type(func) == "function" then
                func()
            end

            if chooseView then
                chooseView:removeFromParent()
                -- chooseView:setVisible(false)
            end
        end)
    end)

    
end

function CodeGameScreenPalaceWishMachine:scatterTriggerAnim(func)
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_scatter_trigger.mp3")
    --播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "free")
    end
    
    --触发动画
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local posIdx = self:getPosReelIdx(iRow, iCol)

            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 处理断线重连后提层
                local nodeParent = node:getParent()
                if nodeParent and nodeParent ~= self.m_clipParent then
                    self:setSymbolToClipParent(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 0)
                end

                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    node:runAnim("actionframe",false, function()
                        node:runAnim("idleframe", true)
                    end)
                end
            end
        end 
    end
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    else

    end

    if self.m_blackLayer then
        self.m_blackLayer:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 50)
    end

    self:showBlackLayer()
    self:delayCallBack(90/30-0.2,function()
        self:hideBlackLayer( )
    end)

    self:triggerScatterAnim()

    self:delayCallBack(90/30, function (  )
        if func then
            func()
        end
    end)
end

function CodeGameScreenPalaceWishMachine:bonusOverAddFreespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            self:addFreeSpinEffect()
        end
    end
end

--[[
    添加free事件
]]
function CodeGameScreenPalaceWishMachine:addFreeSpinEffect( )
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return
    end
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

function CodeGameScreenPalaceWishMachine:show_Map_BonusGameView(func)

    self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.node
    local gameType = self.m_bonusPath[self.m_nodePos]
    self.m_fsReelDataIndex = gameType
    if gameType == 0 then
        --小节点
        -- self:delayCallBack(0.1,function(  )
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_classic_startPopup_begin.mp3")

            local view = self:showLocalDialog("ClassicStart", nil,function()
                
            end)

            local spine = util_spineCreate("PalaceWish_tanban_di", true, true)
            view:findChild("Node_spine"):addChild(spine)
            util_setCascadeOpacityEnabledRescursion(view:findChild("Node_spine"), true)
            util_spinePlay(spine, "start", false)
            local spineEndCallFunc = function()
                util_spinePlay(spine, "idle", true)
            end
            util_spineEndCallFunc(spine, "start", spineEndCallFunc)

            view:setOverActBeginCallFunc(function()
                -- self:clearCurMusicBg()
                self:bgMusicDown( 0.5 )
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_trans_popupup.mp3") --结束用trans的声音
                util_spinePlay(spine, "over", false)

                --弹板过场切
                self:delayCallBack(1, function (  )
                    

                    local data = {}
                    data.parent = self
                    data.paytable = self.m_runSpinResultData.p_selfMakeData.classicWinCoins
                    data.callFunc = func
                    local uiW, uiH = self.m_topUI:getUISize()
                    local uiBW, uiBH = self.m_bottomUI:getUISize()
                    data.height = uiH + uiBH
                    self:setBaseViewVisible(false)

                    self.m_classicMachine = util_createView("PalaceWishSrc.PalaceWishClassic.GameScreenPalaceWishClassicSlots" , data)
                    self:findChild("root"):addChild(self.m_classicMachine)
                    self.m_classicMachine:setPosition(cc.p(-display.center.x,-display.center.y))
                    self.m_bottomUI:showAverageBet()
                    self:clearWinLineEffect()
                    self:resetMaskLayerNodes()
                    if globalData.slotRunData.machineData.p_portraitFlag then
                        self.m_classicMachine.getRotateBackScaleFlag = function(  ) 
                            return false 
                        end
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = self.m_classicMachine})

                end)
            end)
        -- end)
        
    else

        self.m_isSuperFree = true
        self:addFreeSpinEffect()

        if type(func) == "function" then
            func()
        end
    end
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenPalaceWishMachine:showLocalDialog(ccbName,ownerlist,func,isAuto,index)
    local view = util_createView("PalaceWishSrc.PalaceWishBaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalViewManager:showUI(view)

    return view
end

function CodeGameScreenPalaceWishMachine:classicSlotOverView(winCoin, func)
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_classic_overPopup_begin.mp3")

    local view = self:showLocalDialog("ClassicOver", nil,function()

        self.m_collectBar:resetProgress()
        self.m_classicMachine:removeFromParent()
        self.m_classicMachine = nil
        self.m_bottomUI:hideAverageBet()
        self:updateBaseConfig()
        self:initSymbolCCbNames()
        self:initMachineData()

        if self:isHaveBigWin() then
            self.m_bottomUI:notifyTopWinCoin()
        end

        self.m_bIsInClassicGame = false
        if type(func) == "function" then
            func()
        end
        self:resetMusicBg(true)
        -- self:resetMusicBg(true,"PalaceWishSounds/music_PalaceWish_Bg_base.mp3")
        -- gLobalSoundManager:setBackgroundMusicVolume(1)
    end)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local node=view:findChild("m_lb_coins")
    node:setString(util_formatCoins(winCoin, 50))
    view:updateLabelSize({label=node,sx=1,sy=1},681)

    local spine = util_spineCreate("Socre_PalaceWish_tanban", true, true)
    view:findChild("spine_ren"):addChild(spine)
    util_setCascadeOpacityEnabledRescursion(view:findChild("spine_ren"), true)
    util_spinePlay(spine, "ClassicOver_start", false)
    local spineEndCallFunc = function()
        util_spinePlay(spine, "ClassicOver_idle", true)
    end
    util_spineEndCallFunc(spine, "ClassicOver_start", spineEndCallFunc)

    local lightEffect = util_createAnimation("PalaceWish_tanban_guang.csb")
    view:findChild("Node_guang"):addChild(lightEffect)
    lightEffect:runCsbAction("idle", true)
    lightEffect:findChild("Particle_1"):resetSystem()
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"), true)

    view:setOverActBeginCallFunc(function (  )

        if not self:isHaveBigWin() then
            self.m_bottomUI:notifyTopWinCoin()
        end

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_classic_overPopup_end.mp3")
    end)

    self:delayCallBack(0.5,function(  )
        self:setBaseViewVisible(true)
        self.m_classicMachine:setVisible(false)
    end)
end

--[[
    设置最终尺寸
]]
function CodeGameScreenPalaceWishMachine:setEndSize(isUp)
    --是否为升行
    if isUp then
        
        for iCol = 1,self.m_iReelColumnNum do
            local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * TARGET_SYMBOL_COUNT[iCol])
            -- local line = self:findChild("reel_in"..(iCol - 1))
            -- if line then
            --     local size = line:getContentSize()
            --     local percent = targetSize.height / size.width * 100
            --     line:setPercent(percent)
            -- end
            if self.m_reelUpLines[iCol] then
                self.m_reelUpLines[iCol]:setPositionY(targetSize.height)
            end

            local reelBg_free = self:findChild("reel_"..(iCol - 1))
            if reelBg_free then
                local size = reelBg_free:getContentSize()
                local percent = targetSize.height / size.width * 100
                reelBg_free:setPercent(percent)
            end

            local reelBlackBg = self:findChild("reel_bg_"..(iCol - 1))
            if reelBlackBg then
                local size = reelBlackBg:getContentSize()
                local percent = targetSize.height / size.width * 100
                reelBlackBg:setPercent(percent)
            end


            local roofNode = self.m_roofNodes[iCol]
            local posY = self.m_SlotNodeH * (TARGET_SYMBOL_COUNT[iCol] - 3)
            roofNode:setPositionY(posY)
        end

        local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * TARGET_SYMBOL_COUNT[5])

        -- local reel_right = self:findChild("reel_right")
        -- if reel_right then
        --     local size = reel_right:getContentSize()
        --     local percent = targetSize.height / size.width * 100
        --     reel_right:setPercent(percent)
        -- end

        --6是right边
        if self.m_reelUpLines[6] then
            self.m_reelUpLines[6]:setPositionY(targetSize.height)
        end
    else
        local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_fReelHeigth)
        for iCol = 1,self.m_iReelColumnNum do
            -- local line = self:findChild("reel_in"..(iCol - 1))
            -- if line then
            --     local size = line:getContentSize()
            --     local percent = targetSize.height / size.width * 100
            --     line:setPercent(percent)
            -- end
            if self.m_reelUpLines[iCol] then
                self.m_reelUpLines[iCol]:setPositionY(targetSize.height)
            end

            local reelBg_free = self:findChild("reel_"..(iCol - 1))
            if reelBg_free then
                local size = reelBg_free:getContentSize()
                local percent = targetSize.height / size.width * 100
                reelBg_free:setPercent(percent)
            end

            local reelBlackBg = self:findChild("reel_bg_"..(iCol - 1))
            if reelBlackBg then
                local size = reelBlackBg:getContentSize()
                local percent = targetSize.height / size.width * 100
                reelBlackBg:setPercent(percent)
            end

            local roofNode = self.m_roofNodes[iCol]
            local posY = 0
            roofNode:setPositionY(posY)
        end

        -- local reel_right = self:findChild("reel_right")
        -- if reel_right then
        --     local size = reel_right:getContentSize()
        --     local percent = targetSize.height / size.width * 100
        --     reel_right:setPercent(percent)
        -- end

        --6是right边
        if self.m_reelUpLines[6] then
            self.m_reelUpLines[6]:setPositionY(targetSize.height)
        end
    end
end

--[[
    变更边框大小
]]
function CodeGameScreenPalaceWishMachine:changeUISize(offset, isReset)
    for iCol = 1,self.m_iReelColumnNum do

        local reelNode = self.m_baseReelNodes[iCol]
        
        -- local line = self:findChild("reel_in"..(iCol - 1))
        -- if line and not reelNode.m_isChangeEnd  then
        --     local size = line:getContentSize()
        --     local curPercent = line:getPercent()
        --     local percent = (curPercent + offset / size.width * 100)
        --     line:setPercent(percent)
        -- elseif line and reelNode.m_isChangeEnd and offset > 0  then
        --     local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * TARGET_SYMBOL_COUNT[iCol])
        --     local size = line:getContentSize()
        --     local percent = targetSize.height / size.width * 100
        --     line:setPercent(percent)
        -- end


        if self.m_reelUpLines[iCol] and not reelNode.m_isChangeEnd  then
            local curPosY = self.m_reelUpLines[iCol]:getPositionY()
            self.m_reelUpLines[iCol]:setPositionY(curPosY + offset)
        elseif self.m_reelUpLines[iCol] and reelNode.m_isChangeEnd and offset > 0  then
            local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * TARGET_SYMBOL_COUNT[iCol])
            self.m_reelUpLines[iCol]:setPositionY(targetSize.height)
        end

        local reelBg_free = self:findChild("reel_"..(iCol - 1))
        if reelBg_free and not reelNode.m_isChangeEnd then
            local size = reelBg_free:getContentSize()
            local curPercent = reelBg_free:getPercent()
            local percent = (curPercent + offset / size.width * 100)
            reelBg_free:setPercent(percent)
        elseif reelBg_free and reelNode.m_isChangeEnd and offset > 0  then
            local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * TARGET_SYMBOL_COUNT[iCol])
            local size = reelBg_free:getContentSize()
            local percent = targetSize.height / size.width * 100
            reelBg_free:setPercent(percent)
        elseif reelBg_free and reelNode.m_isChangeEnd and offset < 0 then
            local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * 3)
            local size = reelBg_free:getContentSize()
            local percent = targetSize.height / size.width * 100
            reelBg_free:setPercent(percent)
        end

        --黑底
        local reelBlackBg = self:findChild("reel_bg_"..(iCol - 1))
        if reelBlackBg and not reelNode.m_isChangeEnd then
            local size = reelBlackBg:getContentSize()
            local curPercent = reelBlackBg:getPercent()
            local percent = (curPercent + offset / size.width * 100)
            reelBlackBg:setPercent(percent)
        elseif reelBlackBg and reelNode.m_isChangeEnd and offset > 0 then
            local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * TARGET_SYMBOL_COUNT[iCol])
            local size = reelBlackBg:getContentSize()
            local percent = targetSize.height / size.width * 100
            reelBlackBg:setPercent(percent)
        elseif reelBlackBg and reelNode.m_isChangeEnd and offset < 0 then
            local targetSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH * 3)
            local size = reelBlackBg:getContentSize()
            local percent = targetSize.height / size.width * 100
            reelBlackBg:setPercent(percent)
        end

        local roofNode = self.m_roofNodes[iCol]
        if not reelNode.m_isChangeEnd then
            local posY = roofNode:getPositionY()
            posY = posY + offset
            roofNode:setPositionY(posY)
        else
            local posY = nil
            if isReset then
                posY = 0
            else
                posY = self.m_SlotNodeH * (TARGET_SYMBOL_COUNT[iCol] - 3)
            end
            roofNode:setPositionY(posY)
        end
    end

    -- local reel_right = self:findChild("reel_right")
    -- if reel_right then
    --     local size = reel_right:getContentSize()
    --     local curPercent = reel_right:getPercent()
    --     local percent = (curPercent + offset / size.width * 100)
    --     reel_right:setPercent(percent)
    -- end
    --6是right边
    if self.m_reelUpLines[6] then
        local curPosY = self.m_reelUpLines[6]:getPositionY()
        local newY = curPosY + offset
        if newY >= self.m_SlotNodeH * TARGET_SYMBOL_COUNT[5] then
            newY = self.m_SlotNodeH * TARGET_SYMBOL_COUNT[5]
        end
        self.m_reelUpLines[6]:setPositionY(newY)
    end
end

--不同玩法 ui显示
function CodeGameScreenPalaceWishMachine:showMainUI( type, isDownCut, isInit)
    self.m_juese:setVisible(false)
    -- self.m_respinSpinbar:setVisible(false)
    if not isDownCut then
        self.m_collectBar:setVisible(false)
    end
    
    self.m_gameBg:findChild("Node_base"):setVisible(false)
    self.m_gameBg:findChild("Node_free"):setVisible(false)
    self.m_gameBg:findChild("Node_respin"):setVisible(false)
    self.m_gameBg:findChild("Node_superFree"):setVisible(false)
    if type == "base" then
        if isInit then
            self.m_juese:setVisible(true)
            self:runJueseIdleAni()
        end
        self.m_respinSpinbar:setVisible(false)

        if not isDownCut then
            self.m_collectBar:setVisible(true)
        end
        
        -- self:showUIForChangeSize()
        self.m_jackpotBar:runIdle(1)

        self.m_gameBg:findChild("Node_base"):setVisible(true)

        --线数
        self:findChild("PalaceWish_rl_ear_1_0"):setVisible(true)
        self:findChild("PalaceWish_rl_ear_1"):setVisible(true)
        self:findChild("PalaceWish_rl_ear_1_0_0"):setVisible(false)
        self:findChild("PalaceWish_rl_ear_1_1"):setVisible(false)

        self:hideFreeSpinBar()
    elseif type == "free" then
        if not isInit then
            self.m_juese:setVisible(true)
        end
        
        self:hideUIForChangeSize()
        self.m_jackpotBar:runIdle(2)

        self.m_gameBg:findChild("Node_free"):setVisible(true)
    elseif type == "respin" then
        if not isInit then
            self.m_juese:setVisible(true)
        end
        self:hideUIForChangeSize()
        -- self.m_respinSpinbar:setVisible(true)
        self.m_jackpotBar:runIdle(2)

        

        self.m_gameBg:findChild("Node_respin"):setVisible(true)
    -- elseif type == "base" then
    elseif type == "superFree" then
        self.m_juese:setVisible(true)
        self:runJueseIdleAni()
        self.m_gameBg:findChild("Node_superFree"):setVisible(true)

        self.m_baseFreeSpinBar:setVisible(true)
        self.m_baseFreeSpinBar.m_normal_bar:setVisible(false)
        self.m_baseFreeSpinBar.m_super_bar:setVisible(true)
    end
end

--[[
    隐藏升行相关UI
]]
function CodeGameScreenPalaceWishMachine:hideUIForChangeSize()
    self.m_collectBar:setVisible(false)
    -- self.m_jackpotBar:setVisible(self.m_isTriggerRespin)
    
    for key, value in pairs(self.m_reelUpLinesPanel) do
        value:setVisible(true)
    end

    --线数
    self:findChild("PalaceWish_rl_ear_1_0"):setVisible(false)
    self:findChild("PalaceWish_rl_ear_1"):setVisible(false)
    self:findChild("PalaceWish_rl_ear_1_0_0"):setVisible(true)
    self:findChild("PalaceWish_rl_ear_1_1"):setVisible(true)
    
    

    self:findChild("PalaceWish_reel22_3"):setVisible(false)
    self:findChild("PalaceWish_reel22_3_0"):setVisible(false)

    for iCol = 1,self.m_iReelColumnNum do
        local reelBg_base = self:findChild("reel_reel_"..(iCol - 1))
        if reelBg_base then
            reelBg_base:setVisible(false)
        end
        local roofNode = self.m_roofNodes[iCol]
        roofNode:setVisible(true)

        -- if not self.m_isTriggerRespin then
            roofNode:findChild("Node_minor"):setVisible(false)
            roofNode:findChild("Node_major"):setVisible(false)
            roofNode:findChild("Node_grand"):setVisible(false)
        -- else
        --     roofNode:findChild("Node_minor"):setVisible(iCol == 3)
        --     roofNode:findChild("Node_major"):setVisible(iCol == 4)
        --     roofNode:findChild("Node_grand"):setVisible(iCol == 5)
        -- end
        roofNode:runCsbAction("idle", true)
    end
end

--[[
    显示升行相关UI
]]
function CodeGameScreenPalaceWishMachine:showUIForChangeSize()
    self.m_collectBar:setVisible(true)
    self.m_jackpotBar:setVisible(true)

    for key, value in pairs(self.m_reelUpLinesPanel) do
        value:setVisible(false)
    end

    --线数
    self:findChild("PalaceWish_rl_ear_1_0"):setVisible(true)
    self:findChild("PalaceWish_rl_ear_1"):setVisible(true)
    self:findChild("PalaceWish_rl_ear_1_0_0"):setVisible(false)
    self:findChild("PalaceWish_rl_ear_1_1"):setVisible(false)

    self:findChild("PalaceWish_reel22_3"):setVisible(true)
    self:findChild("PalaceWish_reel22_3_0"):setVisible(true)

    for iCol = 1,self.m_iReelColumnNum do
        local reelBg_base = self:findChild("reel_reel_"..(iCol - 1))
        if reelBg_base then
            reelBg_base:setVisible(true)
        end
        local roofNode = self.m_roofNodes[iCol]
        roofNode:setVisible(false)
    end
end

--[[
    变更点击区域大小
]]
function CodeGameScreenPalaceWishMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
    end
end

--[[
    变更裁切层大小
]]
function CodeGameScreenPalaceWishMachine:changeReelSize(func)
    self:hideUIForChangeSize()
    local endCount = 0
    local endFunc = function(  )
        endCount = endCount + 1
        if endCount < self.m_iReelColumnNum then
            return
        end
        --停止计时器
        self.m_changeSizeNode:unscheduleUpdate()

        --设置UI最终尺寸
        self:setEndSize(true)

        if type(func) == "function" then
            func()
        end
    end
    
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        local targetSymbolCount = TARGET_SYMBOL_COUNT[iCol]
        local targetHight = self.m_SlotNodeH * targetSymbolCount

        reelNode:changClipSizeToTarget(targetHight,CHANGE_SPEED,endFunc)

        --将第四行变更为93信号
        local symbolNode = self:getFixSymbol(iCol,self.m_iReelRowNum + 1)
        if symbolNode then
            if self.m_isTriggerRespin then
                self:changeSymbolType(symbolNode,self.SYMBOL_FIX_BLANK)
            else
                self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD)
            end
        end

        local roofNode = self.m_roofNodes[iCol]
        roofNode:setPositionY(0)
        roofNode:setVisible(true)
    end

    self.m_iReelRowNum = 7
    self:changeTouchSpinLayerSize()
    self:resetValidSymbolMatrixArray(self.m_iReelRowNum)

    self.m_changeSizeNode:onUpdate(function(dt)
        if globalData.slotRunData.gameRunPause then
            return
        end

        local offset = math.floor(CHANGE_SPEED * dt)
        

        for iCol = 1,self.m_iReelColumnNum do
            local reelNode = self.m_baseReelNodes[iCol]
            reelNode:dynamicChangeSize(dt)

            self:updateUpClipSize(iCol, reelNode)
        end

        self:changeUISize(offset) --需要在dynamicChangeSize后设置
    end)
    
end

--[[
    重置裁切层大小
]]
function CodeGameScreenPalaceWishMachine:resetReelSize(func)
    local endCount = 0
    local endFunc = function()
        endCount = endCount + 1
        if endCount < self.m_iReelColumnNum then
            return
        end
        --停止计时器
        self.m_changeSizeNode:unscheduleUpdate()

        --设置UI最终尺寸
        self:setEndSize(false)

        if type(func) == "function" then
            func()
        end
    end

    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        local targetSymbolCount = TARGET_SYMBOL_COUNT[iCol]
        local targetHight = self.m_SlotNodeH * 3
        reelNode:changClipSizeToTarget(targetHight,CHANGE_SPEED,endFunc)
    end

    self.m_iReelRowNum = 3
    self:changeTouchSpinLayerSize()
    self:resetValidSymbolMatrixArray(self.m_iReelRowNum)

    self.m_changeSizeNode:onUpdate(function(dt)
        if globalData.slotRunData.gameRunPause then
            return
        end

        local offset = math.floor(CHANGE_SPEED * dt)
        

        for iCol = 1,self.m_iReelColumnNum do
            local reelNode = self.m_baseReelNodes[iCol]
            reelNode:dynamicChangeSize(dt)
        end

        self:changeUISize(-offset, true)
    end)
end

--[[
    将裁切层变为最大
]]
function CodeGameScreenPalaceWishMachine:setMaxReelSize()
    self:hideUIForChangeSize()

    self.m_iReelRowNum = 7
    self:changeTouchSpinLayerSize()
    self:resetValidSymbolMatrixArray(self.m_iReelRowNum)
    
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        local targetSymbolCount = TARGET_SYMBOL_COUNT[iCol]
        local targetHight = self.m_SlotNodeH * targetSymbolCount

        reelNode:changClipSizeWithoutAni(targetHight, true)

        local roofNode = self.m_roofNodes[iCol]
        roofNode:setVisible(true)
    end

    --设置UI最终尺寸
    self:setEndSize(true)

end

--[[
    将裁切层变为正常
]]
function CodeGameScreenPalaceWishMachine:setNormalReelSize()
    self:showUIForChangeSize()

    self.m_iReelRowNum = 3
    self:changeTouchSpinLayerSize()
    self:resetValidSymbolMatrixArray(self.m_iReelRowNum)
    
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        local targetSymbolCount = 3
        local targetHight = self.m_SlotNodeH * targetSymbolCount

        reelNode:changClipSizeWithoutAni(targetHight, false)

        local roofNode = self.m_roofNodes[iCol]
        roofNode:setVisible(false)
    end

    --设置UI最终尺寸
    self:setEndSize(false)

end

function CodeGameScreenPalaceWishMachine:resetValidSymbolMatrixArray(maxRow)
    self.m_stcValidSymbolMatrix = table_createTwoArr(maxRow, self.m_iReelColumnNum, TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE)
end

function CodeGameScreenPalaceWishMachine:isWildSymbol(_symbolType)
    if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or
    _symbolType == self.SYMBOL_WILD_2X or
    _symbolType == self.SYMBOL_WILD_3X or
    _symbolType == self.SYMBOL_WILD_5X or
    _symbolType == self.SYMBOL_WILD_8X or
    _symbolType == self.SYMBOL_WILD_10X or
    _symbolType == self.SYMBOL_WILD_25X or
    _symbolType == self.SYMBOL_WILD_100X then
        return true
    end
    return false
end

--[[
    精灵待机idle
]]
function CodeGameScreenPalaceWishMachine:runJueseIdleAni()
    -- self:setJueseOrderFront(false)
    -- self.m_juese:setVisible(true)

    self.m_jueseAnimIsPlay = false
    
    local randIndex = math.random(2, 6)
    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        -- soundFile = (randIndex == 3) and nil or nil,  --播放音效 执行动作同时播放 可选参数
        actionName = "idleframe"..randIndex, --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            self:runJueseIdleAni()
        end
    }
    util_runAnimations(params)
end

--[[
    精灵 出现
]]
function CodeGameScreenPalaceWishMachine:runJueseStartAni(effectData, func)
    -- self:setJueseOrderFront(false)
    

    util_spinePlay(self.m_juese, "start", false)
    local spineEndCallFunc = function()
        self:runJueseIdleAni()
    end
    util_spineEndCallFunc(self.m_juese, "start", spineEndCallFunc)

    self.m_juese:setVisible(true)

    self:delayCallBack(17/30, function()
        if func then
            func()
            return
        end
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        
    end)
end

--[[
    精灵 隐藏
]]
function CodeGameScreenPalaceWishMachine:runJueseOverAni(func)
    -- self:setJueseOrderFront(false)
    

    -- util_spinePlay(self.m_juese, "over", false)
    -- local spineEndCallFunc = function()
    --     self.m_juese:setVisible(false)
    -- end
    -- util_spineEndCallFunc(self.m_juese, "over", spineEndCallFunc)

    -- self.m_juese:setVisible(true)

    -- self:delayCallBack(20/30, function()
    --     if func then
    --         func()
    --     end
    -- end)

    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_juese_overanim.mp3")

    self.m_jueseAnimIsPlay = true
    util_spinePlay(self.m_juese, "actionframe_yugao", false)
    local spineEndCallFunc = function()
    end
    util_spineEndCallFunc(self.m_juese, "actionframe_yugao", spineEndCallFunc)

    self.m_jueseTemp = self.m_juese
    --20 jackpot前  32 棋盘前  65 后面人物出现
    self:delayCallBack(20/30, function()
        self:setJueseOrderFront(25)
    end)
    self:delayCallBack(32/30, function()
        local posNode = util_convertToNodeSpace(self:findChild("juese"), self)
        util_changeNodeParent(self, self.m_juese, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5) 
        self.m_juese:setPosition(posNode)
        
    end)
    -- self:delayCallBack(65/30, function()
        -- self.m_juese = util_spineCreate("Socre_PalaceWish_juese", true, true)
        -- self:findChild("juese"):addChild(self.m_juese)
        -- self:setJueseOrderFront(10)

        -- util_spinePlay(self.m_juese, "start", false)
        -- local spineEndCallFunc = function()
        --     self.m_jueseAnimIsPlay = false
        --     self:runJueseIdleAni()
        -- end
        -- util_spineEndCallFunc(self.m_juese, "start", spineEndCallFunc)
    -- end)

    --切
    -- self:delayCallBack(65/30, function()
    --     if func then
    --         func()
    --     end
    -- end)

    --over
    self:delayCallBack(80/30, function()
        self.m_juese = util_spineCreate("Socre_PalaceWish_juese", true, true)
        self:findChild("juese"):addChild(self.m_juese)
        self:setJueseOrderFront(10)
        self.m_juese:setVisible(false)

        if self.m_jueseTemp and not tolua.isnull(self.m_jueseTemp) then
            self.m_jueseTemp:removeFromParent()
            self.m_jueseTemp = nil
        end

        if func then
            func()
        end
    end)
end

--[[
    精灵 scatter触发 bonus触发
]]
function CodeGameScreenPalaceWishMachine:runJueseScatterTriggerAni()
    -- self:setJueseOrderFront(false)
    -- self.m_juese:setVisible(true)
    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        actionName = "actionframe3", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            self:runJueseIdleAni()
        end
    }
    util_runAnimations(params)
end

--[[
    精灵 升行打响指动画
]]
function CodeGameScreenPalaceWishMachine:runJueseReelUpAni(func)
    -- self:setJueseOrderFront(true)
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_role_toUpReel.mp3")

    self.m_jueseFront:setVisible(true)

    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_jueseFront,   --执行动画节点  必传参数
        actionName = "actionframe4", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            self.m_jueseFront:setVisible(false)
        end
    }
    util_runAnimations(params)

    self:delayCallBack(30/30, function (  )
        if func then
            func()
        end
    end)
end

--[[
    精灵 free wild 喷雾
]]
function CodeGameScreenPalaceWishMachine:runJueseWildRandomAni(_func, _func2, type)
    -- self:setJueseOrderFront(true)
    self.m_freeWildWaitNode:stopAllActions()
    self.m_jueseFront:setVisible(true)

    if type and type == "free" then
        self.m_effectRespinWildDark:setVisible(true)
        self.m_effectRespinWildDark:runCsbAction("start", false, function (  )
            self.m_effectRespinWildDark:runCsbAction("idle", true)
        end)
    end
    
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_juese_leftappear.mp3")

    performWithDelay(self.m_freeWildWaitNode, function (  )
        if _func then
            _func()
        end
    end, 50/30)
    performWithDelay(self.m_freeWildWaitNode, function (  )
        if _func2 then
            _func2()
        end
    end, 65/30)

    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_jueseFront,   --执行动画节点  必传参数
        actionName = "actionframe5", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            self.m_jueseFront:setVisible(false)
        end
    }
    util_runAnimations(params)
end
--wild 快停直接设置
function CodeGameScreenPalaceWishMachine:quickStopSetWild()
    if self.m_lockNodes then
        self.m_freeWildWaitNode:stopAllActions()
        self.m_effectRespinWildDark:setVisible(false)
        self:resetAct(self.m_effectRespinWildDark)
        self.m_jueseFront:setVisible(false)

        if #self.m_lockNodes <= 0 then
            self:createLockWild(function(  )
                            
            end, function (  )
            end)
            for i = 1, #self.m_lockNodes do
                local lockNode = self.m_lockNodes[i]
                util_spinePlay(lockNode, "idleframe", true)
            end
            
        else
            for i = 1, #self.m_lockNodes do
                local lockNode = self.m_lockNodes[i]
                util_spinePlay(lockNode, "idleframe", true)
            end
        end

        if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
            if self.m_juese:isVisible() == false then
                self:runJueseStartAni(nil, function()
                end)
            end
        end
    end
end

--人物点击
function CodeGameScreenPalaceWishMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_jueseClick" then
 
        if (self:getCurrSpinMode() == NORMAL_SPIN_MODE or 
        self:getCurrSpinMode() == AUTO_SPIN_MODE or (self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_isSuperFree)) and not self.m_jueseAnimIsPlay then
            self.m_jueseAnimIsPlay = true

            local rand = math.random(0, 100)
            if rand < 50 then
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_juese_language_2.mp3")
            else
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_juese_language_3.mp3")
            end

            -- gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_.mp3")

            util_spinePlay(self.m_juese, "actionframe", false)
            local spineEndCallFunc = function()
                self.m_jueseAnimIsPlay = false
                if (self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_isSuperFree) then
                    util_spinePlay(self.m_juese, "idleframe3", true)
                else
                    self:runJueseIdleAni()
                end
                
            end
            util_spineEndCallFunc(self.m_juese, "actionframe", spineEndCallFunc)
        end
    end  
end

--重写
-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenPalaceWishMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isLongRun then
            _slotNode:runAnim("idleframe3", true)
        else
            _slotNode:runAnim("idleframe2", true)
        end
    end

    if self:isFixSymbol(_slotNode.p_symbolType) then
        _slotNode:runAnim("idleframe2", true)
    end
end

function CodeGameScreenPalaceWishMachine:slotOneReelDown(reelCol)    
    CodeGameScreenPalaceWishMachine.super.slotOneReelDown(self,reelCol) 
    if reelCol == 5 then
        -- self.m_playWinningNotice = false


        if self.m_isLongRun then
            --scatter期待动画还原
            self.m_isLongRun = false
            for iCol = 1,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local _slotNode = self:getFixSymbol(iCol,iRow)
                    if _slotNode and _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        _slotNode:runAnim("idleframe2", true)
                    end
                end
            end
        end

        if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
            --free快停 直接设置
            self:quickStopSetWild()
        end
    end
end

--重写
function CodeGameScreenPalaceWishMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = CodeGameScreenPalaceWishMachine.super.setReelLongRun(self, reelCol)
    
    if not self.m_isLongRun and isTriggerLongRun then
        --scatter播期待动画
        self.m_isLongRun = isTriggerLongRun
        for iCol = 1,reelCol do
            for iRow = 1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol,iRow)
                if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    symbol:runAnim("idleframe3", true)
                end
            end
        end
    end

    return isTriggerLongRun
end

-- 预告中奖
function CodeGameScreenPalaceWishMachine:preViewWin(func)  
    self.m_isPlayWinningNotice = false
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_preWinning.mp3")

    self.m_effectPreWinDark:setVisible(true)
    self.m_effectPreWinDark:runCsbAction("start", false, function (  )
        self.m_effectPreWinDark:runCsbAction("idle", true)
    end)

    self.m_jueseAnimIsPlay = true
    util_spinePlay(self.m_juese, "yugao", false)
    local spineEndCallFunc = function()
        self.m_jueseAnimIsPlay = false
        self:runJueseIdleAni()
    end
    util_spineEndCallFunc(self.m_juese, "yugao", spineEndCallFunc)

    self.m_juesePreWin:setVisible(true)
    util_spinePlay(self.m_juesePreWin, "yugao", false)
    local spineEndCallFunc = function()
        self.m_juesePreWin:setVisible(false)
    end
    util_spineEndCallFunc(self.m_juesePreWin, "yugao", spineEndCallFunc)

    self:delayCallBack(65/30 - 30/60, function()
        self.m_effectPreWinDark:runCsbAction("over", false, function (  )
            self.m_effectPreWinDark:setVisible(false)
        end)
    end)
    self:delayCallBack(65/30, function()
        if func then
            func()
        end
    end)

end

-- shake
function CodeGameScreenPalaceWishMachine:shakeOneNodeForever(time)
    local oldPos = cc.p(self:findChild("Node_2"):getPosition())
    local changePosY = math.random( 1, 5)
    local changePosX = math.random( 1, 5)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    self:findChild("Node_2"):runAction(action)

    performWithDelay(self,function()
        self:findChild("Node_2"):stopAction(action)
        self:findChild("Node_2"):setPosition(oldPos)
    end,time)
end

function CodeGameScreenPalaceWishMachine:isHaveBigWin()
    local ret = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        ret = true
    end
    return ret
end

function CodeGameScreenPalaceWishMachine:resetAct(node)
    if node and not tolua.isnull(node) then
        if node.m_csbAct and not tolua.isnull(node.m_csbAct) then
            util_resetCsbAction(node.m_csbAct)
        end
    end
end

function CodeGameScreenPalaceWishMachine:checkIsHaveSelfEffect(_effectType, _effectSelfType)
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

--重写
-- 有特殊需求判断的 重写一下
function CodeGameScreenPalaceWishMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif self:isFixSymbol(_slotNode.p_symbolType) then
                return true
            end
        end
    end

    return false
end

--scatter触发动画
function CodeGameScreenPalaceWishMachine:triggerScatterAnim()
    self:runJueseScatterTriggerAni()
end

function CodeGameScreenPalaceWishMachine:setJueseOrderFront( order )
    self:findChild("juese"):setLocalZOrder(order)
end

--过场动画
function CodeGameScreenPalaceWishMachine:showTrans(timeCut,timeOver,type,func1,func2,isBack)
    
    local actionName = "actionframe_guochang1"

    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_trans_juese.mp3")
    if isBack then--返回
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_OtherTobase.mp3")
    else
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_baseToOther.mp3")
    end
        

    self.m_trans:setVisible(true)
    util_spinePlay(self.m_trans, actionName, false)
    self:delayCallBack(timeCut, function (  )
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(timeOver, function (  )
        if func2 then
            func2()
        end
        self.m_trans:setVisible(false)
    end)
end

--过场动画事件帧型 全屏  只有respin退出用
function CodeGameScreenPalaceWishMachine:showTrans2( funcCut, funcEnd )
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_trans_light.mp3")

    self.m_trans2:setVisible(true)
    util_spinePlay(self.m_trans2, "actionframe_guochang", false)
    util_spineFrameCallFunc(self.m_trans2, "actionframe_guochang", "qieBJ", function (  )
        if funcCut then
            funcCut()
        end
    end, function (  )
        self.m_trans2:setVisible(false)
        if funcEnd then
            funcEnd()
        end
    end)
end

function CodeGameScreenPalaceWishMachine:showReSpinStart(func, func2)
    

    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_startPopup_begin.mp3")

    local view = self:showLocalDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
    local bgSpine = util_spineCreate("PalaceWish_tanban_di", true, true)
    view:findChild("Node_spine"):addChild(bgSpine)
    view:findChild("root"):setScale(self.m_machineRootScale)

    util_spinePlay(bgSpine, "start", false)
    local spineEndCallFunc = function()
        util_spinePlay(bgSpine, "idle", true)
    end
    util_spineEndCallFunc(bgSpine, "start", spineEndCallFunc)

    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_spine"), true)

    view:setOverActBeginCallFunc(function (  )
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_trans_popupup.mp3")

        util_spinePlay(bgSpine, "over", false)

        --切ui
        self:delayCallBack(1, function (  )
            if func2 then
                func2()
            end
        end)
    end)
end

--提层
function CodeGameScreenPalaceWishMachine:setSymbolToClipParent(_MainClass, _iCol, _iRow, _type, _zorder)
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

function CodeGameScreenPalaceWishMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenPalaceWishMachine.super.getBounsScatterDataZorder(self, symbolType)
    if self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif self:isWildSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    end
    return order
end

--创建respin 列集满特效
function CodeGameScreenPalaceWishMachine:createRespinCollectColFullEffect(  )
    self.m_respinColEffect = {}
    
    local nodeName = {"Minor", "Major", "Grand"}
    --3 4 5 列特效
    for i=1,3 do
        local reelNode = self:findChild("sp_reel_" .. (i + 1))
        local effect = util_createAnimation("PalaceWish_respin_jackpot_jiman.csb")

        local targetPos = util_convertToNodeSpace(reelNode, self.m_respinColEffectLayer)
        self.m_respinColEffectLayer:addChild(effect)
        effect:setPosition(cc.p(targetPos))
        self.m_respinColEffect[i + 2] = effect
        effect:setVisible(false)

        for j=1,#nodeName do
            local node = effect:findChild(nodeName[j])
            if i == j then
                node:setVisible(true)
                local particle = effect:findChild("Particle_" .. (4-i))
                if particle then
                    particle:resetSystem()
                end
            else
                node:setVisible(false)
            end
            
        end
        
    end
end
--显示respin 列集满特效
function CodeGameScreenPalaceWishMachine:showRespinCollectColFullEffect( col, isShow)
    if self.m_respinColEffect and self.m_respinColEffect[col] then
        if isShow then
            self.m_respinColEffect[col]:runCsbAction("start", false, function()
                self.m_respinColEffect[col]:runCsbAction("idleframe", true)
            end)
        end
        self.m_respinColEffect[col]:setVisible(isShow)
    end
end

--修改赢钱区特效
function CodeGameScreenPalaceWishMachine:changeWinCoinEffectCsb(_isChange)
    local effectCsbName = "GameBottomNodePortrait_jiesuan.csb"
    if _isChange then
        effectCsbName = "PalaceWish_totalwin.csb"
    else
        if globalData.slotRunData.isPortrait == true then
            effectCsbName = "GameBottomNodePortrait_jiesuan.csb"
        else
            effectCsbName = "GameBottomNode_jiesuan.csb"
        end
    end
    
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), effectCsbName)
end

--[[
    创建升行特效裁切
]]
function CodeGameScreenPalaceWishMachine:createUpEffectClip()
    self.m_colUpEffectClip = {}
    self.m_colUpEffect = {}

    for i=1,5 do
        local reelNode = self:findChild("sp_reel_" .. (i - 1))
        local targetPos = util_convertToNodeSpace(reelNode, self.m_respinColEffectLayer)
        

        self.m_colUpEffectClip[i] = ccui.Layout:create()
        self.m_colUpEffectClip[i]:setAnchorPoint(cc.p(0.5, 0))
        self.m_colUpEffectClip[i]:setTouchEnabled(false)
        self.m_colUpEffectClip[i]:setSwallowTouches(false)

        local size = cc.size(self.m_SlotNodeW, self.m_SlotNodeH * 3) 
        self.m_colUpEffectClip[i]:setPosition(cc.pAdd(cc.p(targetPos), cc.p(self.m_SlotNodeW/2, 0)))

        self.m_colUpEffectClip[i]:setContentSize(size)
        self.m_colUpEffectClip[i]:setClippingEnabled(true)
        self.m_respinColEffectLayer:addChild(self.m_colUpEffectClip[i])

        --显示区域
        -- self.m_colUpEffectClip[i]:setBackGroundColor(cc.c3b(0, 255, 0))
        -- self.m_colUpEffectClip[i]:setBackGroundColorOpacity(90)
        -- self.m_colUpEffectClip[i]:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)

        local effect = util_createAnimation("PalaceWish_respin_L.csb")
        self.m_colUpEffectClip[i]:addChild(effect)
        effect:setPosition(cc.p(self.m_SlotNodeW/2, -100))
        self.m_colUpEffect[i] = effect
        effect:runCsbAction("actionframe", true)

        self.m_colUpEffectClip[i]:setVisible(false)
        self.m_colUpEffect[i]:setVisible(false)
    end
    
end

--[[
    升行特效
]]
function CodeGameScreenPalaceWishMachine:runUpEffect( upCallBack, finishCallback )
    
    local effectDistance = 195 * 4
    
    for i=1,5 do
        self.m_colUpEffectClip[i]:setVisible(true)
        self.m_colUpEffectClip[i]:setContentSize(cc.size(self.m_SlotNodeW, self.m_SlotNodeH * 3))
        self.m_colUpEffect[i]:setVisible(true)
        self.m_colUpEffect[i]:setPosition(cc.p(self.m_SlotNodeW/2, -effectOffset))

        local actionList = {}
        -- actionList[#actionList + 1] = cc.DelayTime:create(time)
        local runTime = (self.m_SlotNodeH * TARGET_SYMBOL_COUNT[i] + effectDistance + effectOffset) / CHANGE_SPEED

        actionList[#actionList + 1] = cc.MoveTo:create(runTime,  cc.p(self.m_SlotNodeW/2, self.m_SlotNodeH * TARGET_SYMBOL_COUNT[i] + effectDistance))
        -- actionList[#actionList + 1] = cc.CallFunc:create(function()

        -- end)
        self.m_colUpEffect[i]:runAction(cc.Sequence:create(actionList))

        local arrivedUpTime = (self.m_SlotNodeH * TARGET_SYMBOL_COUNT[i] + effectOffset) / CHANGE_SPEED
        self:delayCallBack(arrivedUpTime, function (  )
            if upCallBack then
                upCallBack(i)
                if i == 5 then
                    if finishCallback then
                        finishCallback()
                    end
                    self:hideUpEffect(  )
                end
            end
        end)
    end

end

function CodeGameScreenPalaceWishMachine:hideUpEffect(  )
    for i=1,5 do
        self.m_colUpEffectClip[i]:setVisible(false)
        self.m_colUpEffect[i]:setVisible(false)
        self.m_colUpEffect[i]:setPosition(cc.p(self.m_SlotNodeW/2, -effectOffset))
    end
end
--更新裁切高度
function CodeGameScreenPalaceWishMachine:updateUpClipSize( col, reelNode )
    if self.m_colUpEffectClip then
        if self.m_colUpEffectClip[col] and reelNode and reelNode.m_clipNode then
            local size = reelNode.m_clipNode:getContentSize()
            self.m_colUpEffectClip[col]:setContentSize(cc.size(self.m_SlotNodeW, size.height))
        end
    end
end

function CodeGameScreenPalaceWishMachine:reSpinEndAction()
    self.m_lightScore = 0
    -- self:respinOver()

    self.m_chipList = {}
    self.m_playAnimIndex = 1
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    self.m_rolFullIsPlayed = {}

    local nextFun = function (  )
        self:playChipCollectAnim()
    end

    local funTrigger = function (  )
        --respin结算前 触发动画
        for i,v in ipairs(self.m_chipList) do
            local respinSymbol = v
            if self:isFixSymbol(respinSymbol.p_symbolType) then
                respinSymbol:runAnim("actionframe", false, function()
                    respinSymbol:runAnim("idleframe2", true)
                end)
            end
        end
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_full_overtrigger.mp3")
        
        self:delayCallBack(2, function (  )
            nextFun()
        end)
    end
    
    

    if #self.m_chipList >= 25 then
        self:playRespinFullAnim( function (  )
            funTrigger()
        end )
    else
        funTrigger()
    end
end

--收集
function CodeGameScreenPalaceWishMachine:playChipCollectAnim()

    if self.m_playAnimIndex > #self.m_chipList then
        self.m_isPlayCollect = nil
        local waitTime = 1

        self:delayCallBack(waitTime,function()
            self:playLightEffectEnd()
        end)

        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]


    local playCollect = function ( isJackpot, nJackpotType, score )
        if isJackpot then
            --触发
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_jackpot_top_begin.mp3")
            self:showJackpotRoofAnim(nJackpotType, "actionframe2", "idle", function (  )
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_jackpot_top_fly_begin.mp3")
                --飞行
                self:createRespinJackpotFly(0.5, function (  )
                    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_jackpot_top_fly_end.mp3")
                    self.m_jackpotBar:runCollect(nJackpotType) --jackpot反馈

                    self:showRespinCollectColFullEffect( 6-nJackpotType, false )--光柱特效hide

                    self:delayCallBack((30+60) / 60, function() --彩金栏播完弹jackpot弹板
                        self:showRespinJackpot(nJackpotType, score, function()
                            self.m_jackpotBar:runIdle(2)
                            self:playChipCollectAnim()
                        end)
                        self.m_lightScore = self.m_lightScore + score
                        self:updateWinLabelNum( score )
                    end)
                    
                end, nJackpotType)
            end)
            
        else
            local index = self:getPosReelIdx(chipNode.p_rowIndex ,chipNode.p_cloumnIndex)
            local addScore = self:getChipCoin(index) 
            self.m_lightScore = self.m_lightScore + addScore

            chipNode:runAnim("shouji", false, function (  )
                chipNode:runAnim("yaan_idle", true)
            end)
            self:createRespinParticleFly(0.5, chipNode, function (  )
                self:updateWinLabelNum( addScore )
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim()

                local lightAni = util_createAnimation("PalaceWish_respin_WinningNums.csb")
                self.m_bottomUI.coinWinNode:addChild(lightAni)
                lightAni:findChild("m_lb_coins"):setString("+"..util_formatCoins(addScore,30))
                local info1={label=lightAni:findChild("m_lb_coins"),sx=1,sy=1}
                self:updateLabelSize(info1,470)
                lightAni:runCsbAction("actionframe",false,function(  )
                    lightAni:removeFromParent()
                end)
            end)
        end

    end

    if chipNode.p_cloumnIndex == 3 or chipNode.p_cloumnIndex == 4 or chipNode.p_cloumnIndex == 5 then
        local isColFull = self.m_respinView:checkReelFull( chipNode.p_cloumnIndex )
        
        if isColFull and self.m_rolFullIsPlayed[chipNode.p_cloumnIndex] == nil then
            self.m_rolFullIsPlayed[chipNode.p_cloumnIndex] = 1
            local nJackpotType = 0
            if chipNode.p_cloumnIndex == 3 then
                nJackpotType = 3
            elseif chipNode.p_cloumnIndex == 4 then
                nJackpotType = 2
            elseif chipNode.p_cloumnIndex == 5 then
                nJackpotType = 1
            end
            local score = self:getJackpotWin( nJackpotType )
            playCollect(true, nJackpotType, score)
        else
            playCollect(false)
        end
    else
        playCollect(false)
    end
end

function CodeGameScreenPalaceWishMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("PalaceWishSrc.PalaceWishJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData({
        coins   = coins,
        index   = index,
        machine = self,
    })
    jackPotWinView:setOverAniRunFunc(function (  )
        if func then
            func()
        end
    end)
end

--更新winlabel
function CodeGameScreenPalaceWishMachine:updateWinLabelNum( curAddScore )
    if self.m_lightScore and curAddScore then
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_lightScore, false, true, self.m_lightScore - curAddScore})
        globalData.slotRunData.lastWinCoin = lastWinCoin
        self:playCoinWinEffectUI()
    end
    
end

-- 创建respin收集粒子
function CodeGameScreenPalaceWishMachine:createRespinParticleFly(time,currNode,func)

    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_over_fly_begin.mp3")

    local fly = util_createAnimation("Socre_PalaceWish_FixBonus_tuowei.csb")
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    fly:setPosition(cc.p(util_getConvertNodePos(currNode, fly)))
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local startPos = cc.p(fly:getPosition())
    local endPos = util_convertToNodeSpace(endNode,self)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        self:resetFlyParticle(fly:findChild("Particle_1"))
        self:resetFlyParticle(fly:findChild("Particle_2"))
        self:resetFlyParticle(fly:findChild("Particle_3"))
    end)

    animation[#animation + 1] = cc.EaseIn:create(cc.MoveTo:create(time, endPos), 1)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        self:stopFlyParticle( fly:findChild("Particle_1") )
        self:stopFlyParticle( fly:findChild("Particle_2") )
        self:stopFlyParticle( fly:findChild("Particle_3") )
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_over_fly_end.mp3")
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

-- 创建jackpot收集粒子
function CodeGameScreenPalaceWishMachine:createRespinJackpotFly(time, func, type)

    local fly = util_createAnimation("PalaceWish_jackpot_fly.csb")
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    local roof = nil
    if type == 1 then
        roof = self.m_roofNodes[5]
    elseif type == 2 then
        roof = self.m_roofNodes[4]
    elseif type == 3 then
        roof = self.m_roofNodes[3]
    end

    fly:setPosition(cc.p(util_getConvertNodePos(roof, fly)))

    local endNode = self.m_jackpotBar:getJackpotLabel( type )
    local startPos = cc.p(fly:getPosition())
    local endPos = util_convertToNodeSpace(endNode,self)

    local strName = {"Grand", "Major", "Minor"}
    for i=1,3 do
        if i == type then
            fly:findChild(strName[i]):setVisible(true)
        else
            fly:findChild(strName[i]):setVisible(false)
        end
    end


    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        if type == 1 then
            self:resetFlyParticle(fly:findChild("Particle_1"))
            self:resetFlyParticle(fly:findChild("Particle_2"))
        elseif type == 2 then
            self:resetFlyParticle(fly:findChild("Particle_3"))
            self:resetFlyParticle(fly:findChild("Particle_4"))
        elseif type == 3 then
            self:resetFlyParticle(fly:findChild("Particle_5"))
            self:resetFlyParticle(fly:findChild("Particle_6"))
        end
        
    end)

    animation[#animation + 1] = cc.EaseIn:create(cc.MoveTo:create(time, endPos), 1)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        if type == 1 then
            self:stopFlyParticle( fly:findChild("Particle_1") )
            self:stopFlyParticle( fly:findChild("Particle_2") )
        elseif type == 2 then
            self:stopFlyParticle( fly:findChild("Particle_3") )
            self:stopFlyParticle( fly:findChild("Particle_4") )
        elseif type == 3 then
            self:stopFlyParticle( fly:findChild("Particle_5") )
            self:stopFlyParticle( fly:findChild("Particle_6") )
        end
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

function CodeGameScreenPalaceWishMachine:getChipCoin(_index )
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

function CodeGameScreenPalaceWishMachine:resetFlyParticle( particle )
    if particle then
        particle:setDuration(-1)     --设置拖尾时间(生命周期)
        particle:setPositionType(0)   --设置可以拖尾
        particle:resetSystem()
    end
end

function CodeGameScreenPalaceWishMachine:stopFlyParticle( particle )
    if particle then
        particle:stopSystem()--移动结束后将拖尾停掉
    end
end

-- 结束respin收集
function CodeGameScreenPalaceWishMachine:playLightEffectEnd()
    -- 通知respin结束
    self:respinOver()

end

--jackpot顶部动画
function CodeGameScreenPalaceWishMachine:showJackpotRoofAnim( type, timeline1, timeline2, func )
    local roof = nil
    if type == 1 then
        roof = self.m_roofNodes[5]
    elseif type == 2 then
        roof = self.m_roofNodes[4]
    elseif type == 3 then
        roof = self.m_roofNodes[3]
    end
    roof:runCsbAction(timeline1, false, function (  )
        if timeline2 then
            roof:runCsbAction(timeline2, true)
        end
        if func then
            func()
        end
    end)
    
end

--播放respin放回滚轴后播放的提示动画
function CodeGameScreenPalaceWishMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    else
        if self:isFixSymbol(node.p_symbolType) then
            node:runAnim("idleframe2", true)
        end
    end
end
--获取jackpot赢钱
function CodeGameScreenPalaceWishMachine:getJackpotWin( type )
    if self.m_runSpinResultData then
        local selfData =  self.m_runSpinResultData.p_selfMakeData or {}
        if selfData.allJackpotWinCoins then
            if type == 3 then
                if selfData.allJackpotWinCoins.Minor then
                    return selfData.allJackpotWinCoins.Minor
                end
            elseif type == 2 then
                if selfData.allJackpotWinCoins.Major then
                    return selfData.allJackpotWinCoins.Major
                end
            elseif type == 1 then
                if selfData.allJackpotWinCoins.Grand then
                    return selfData.allJackpotWinCoins.Grand
                end
            end
        end
    end
    return 0
end

--获取全满赢钱
function CodeGameScreenPalaceWishMachine:getRespinFullWin()
    if self.m_runSpinResultData then
        local selfData =  self.m_runSpinResultData.p_selfMakeData or {}
        if selfData.fullWinCoins then
            return tonumber(selfData.fullWinCoins)
        end
    end
    return 0
end

--播全满动画
function CodeGameScreenPalaceWishMachine:playRespinFullAnim( func )

    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_full_popup_begin.mp3")

    self.m_effectRespinFull:setVisible(true)
    self.m_effectRespinFull:setPosition(display.center)

    --压黑
    self.m_effectRespinFullDark:setVisible(true)

    self.m_effectRespinFull:runCsbAction("start", false, function (  )
        self.m_effectRespinFull:runCsbAction("idle", true)
    end)
    self.m_effectRespinFullDark:runCsbAction("start", false, function (  )
        self.m_effectRespinFullDark:runCsbAction("idle", true)
    end)
    self.m_effectRespinFull:findChild("Particle_1"):resetSystem()
    self.m_effectRespinFull:findChild("Particle_2"):resetSystem()
    self.m_effectRespinFull:findChild("Particle_3"):resetSystem()
    self.m_effectRespinFull:findChild("Particle_4"):resetSystem()

    local score = self:getRespinFullWin()
    local tempScore = score
    self.m_lightScore = self.m_lightScore + score
    score = util_formatCoins(score, 50)
    self.m_effectRespinFull:findChild("m_lb_coins"):setString(score)
    
    self:updateLabelSize({label=self.m_effectRespinFull:findChild("m_lb_coins"),sx=0.71,sy=0.71},817)
    local posY = self.m_effectRespinFull:findChild("Node_1"):getPositionY()

    self:delayCallBack(90/60 + 1, function (  )
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_full_popup_over.mp3")

        self.m_effectRespinFull:runCsbAction("over", false)
        self.m_effectRespinFullDark:runCsbAction("over", false, function (  )
            self.m_effectRespinFullDark:setVisible(false)
        end)

        self:delayCallBack(20/60, function (  )
            local endNode = self.m_bottomUI:findChild("font_last_win_value")
            local endPos = util_convertToNodeSpace(endNode,self)
            endPos = cc.pAdd(endPos, cc.p(0, -posY))

            local animation = {}
            -- animation[#animation + 1] = cc.CallFunc:create(function(  )

            -- end)
            animation[#animation + 1] = cc.EaseIn:create(cc.MoveTo:create(0.3, endPos), 1)
            -- animation[#animation + 1] = cc.DelayTime:create(0.4)
            animation[#animation + 1] = cc.CallFunc:create(function(  )
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_full_popup_over_fankui.mp3")

                self.m_effectRespinFull:setVisible(false)
                self:updateWinLabelNum( tempScore )
                if func then
                    func()
                end
            end)

            self.m_effectRespinFull:runAction(cc.Sequence:create(animation))

        end)
    end)
end


--重写去掉触发动画
---
-- 显示free spin
function CodeGameScreenPalaceWishMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- local lineLen = #self.m_reelResultLines
    -- local scatterLineValue = nil
    -- for i = 1, lineLen do
    --     local lineValue = self.m_reelResultLines[i]
    --     if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
    --         scatterLineValue = lineValue
    --         table.remove(self.m_reelResultLines, i)
    --         break
    --     end
    -- end
    
    
    -- if scatterLineValue ~= nil then
    --     --
    --     self:showBonusAndScatterLineTip(
    --         scatterLineValue,
    --         function()
    --             -- self:visibleMaskLayer(true,true)
    --             -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
    --             self:showFreeSpinView(effectData)
    --         end
    --     )
    --     scatterLineValue:clean()
    --     self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
    --     -- 播放提示时播放音效
    --     self:playScatterTipMusicEffect()
    -- else
        --
        self:showFreeSpinView(effectData)
    -- end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

--改变非94小块到999
function CodeGameScreenPalaceWishMachine:changeSymbolToBlank(  )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if symbolNode then
                if not self:isFixSymbol(symbolNode.p_symbolType) then
                    self:changeSymbolType(symbolNode, self.SYMBOL_FIX_BLANK)
                end
            end
        end
    end
end

--改变非999小块到随机
function CodeGameScreenPalaceWishMachine:changeBlankSymbolToRandom(  )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 3, 1, -1 do
            local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if symbolNode then
                if symbolNode.p_symbolType == self.SYMBOL_FIX_BLANK then
                    self:changeSymbolType(symbolNode, math.random(0,8))
                end
            end
        end
    end
end

---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenPalaceWishMachine:MachineRule_ResetReelRunData()

    if self.m_isPlayWinningNotice then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            local preRunLen = reelRunData.initInfo.reelRunLen
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()
            
            reelRunData:setReelRunLen(preRunLen)
            local reelNode = self.m_baseReelNodes[iCol]
            if reelNode and not tolua.isnull(reelNode) then
                if reelNode.setRunLen then
                    reelNode:setRunLen(preRunLen)
                end
            end

            reelRunData:setReelLongRun(false)
            reelRunData:setNextReelLongRun(false)
        end
    else

        local isHaveAnim = false
        local selfData = self.m_runSpinResultData.p_selfMakeData
        --添加固定wild
        if selfData and selfData.catWildPositions and #selfData.catWildPositions > 0 then
            isHaveAnim = true
        end



        --同步滚动距离 否则free不生效
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            local preRunLen = reelRunData.initInfo.reelRunLen
            local preRunLenFree = reelRunData.initInfo.freeSpinreelRunLen
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()

            local RunLenInit = preRunLen
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                RunLenInit = preRunLenFree
            end
            if RunLenInit == runLen and isHaveAnim then
                
                local runData = {31,34,37,40,43}
                reelRunData:setReelRunLen(runData[iCol])
            end

            runLen = reelRunData:getReelRunLen()
            local reelNode = self.m_baseReelNodes[iCol]
            if reelNode and not tolua.isnull(reelNode) then
                if reelNode.setRunLen then
                    reelNode:setRunLen(runLen)
                end
            end
        end

    end
end

-- 获取对应列及其之前的scatter数量
-- function CodeGameScreenPalaceWishMachine:getScatterNumByCol(_Col)
--     local scatterNum = 0
--     for iCol = 1, _Col do
--         for iRow = 1 ,self.m_iReelRowNum do
--             local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
--             if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--                 scatterNum = scatterNum + 1
--             end
--         end
--     end
--     return scatterNum
-- end

function CodeGameScreenPalaceWishMachine:firstInit()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                if self:isFixSymbol(slotNode.p_symbolType) then
                    -- self:setSymbolToClipParent(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
                    slotNode:runAnim("idleframe2", true)
                end
            end
        end
    end
end

--重写 更改order
function CodeGameScreenPalaceWishMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
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
                effectData.p_effectOrder = winEffect --改
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
                    effectData.p_effectOrder = winEffect --改
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
                effectData.p_effectOrder = winEffect --改
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


function CodeGameScreenPalaceWishMachine:scaleMainLayer()
    CodeGameScreenPalaceWishMachine.super.scaleMainLayer(self)
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
        self.m_jackpotOffsetY = 80
    end
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

function CodeGameScreenPalaceWishMachine:showPaytableView()
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

function CodeGameScreenPalaceWishMachine:checkPlayBulingAni(colIndex)
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

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = symbolNode.p_rowIndex, iY = symbolNode.p_cloumnIndex}
                    symbolNode.m_bInLine = true
                    symbolNode:setLinePos(linePos)

                    --回弹
                    local moveTime = self.m_configData.p_reelResTime
                    local dis = self.m_configData.p_reelResDis
                    symbolNode:stopAllActions()
                    local seq = {}
                    local pos = cc.p(symbolNode:getPosition())
                    local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                    local action2 = cc.MoveTo:create(moveTime / 2,pos)
                    local action3 = cc.CallFunc:create(function()
                        local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
                        local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                        symbolNode:setPosition(cc.p(tarSpPos))
                    end)
                    seq = {action1,action2}
                    local sequece =cc.Sequence:create(seq)
                    symbolNode:runAction(sequece)
                end

                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    --2.播落地动画
                    symbolNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(symbolNode)
                        end
                    )
                    --bonus落地音效
                    if self:isFixSymbol(symbolNode.p_symbolType) then
                        self:checkPlayBonusDownSound(colIndex)
                    end
                    --scatter落地音效
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self:checkPlayScatterDownSound(colIndex)
                    end
                end
            end
            
        end
    end
end

--降层
function CodeGameScreenPalaceWishMachine:setSymbolToClipReel(symbolType)

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local _slotNode = self:getFixSymbol(iCol,iRow)
            if _slotNode then
                if _slotNode.p_symbolType == symbolType then
                    self:putSymbolBackToPreParent(_slotNode)
                end
            end
        end
    end
end


--[[
    播放bonus落地音效
]]
function CodeGameScreenPalaceWishMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_bonus_buling.mp3")
end

--[[
    播放scatter落地音效
]]
function CodeGameScreenPalaceWishMachine:playScatterDownSound(colIndex)
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_scatter_buling.mp3")
end

function CodeGameScreenPalaceWishMachine:isMultiWildSymbol(_symbolType)
    if _symbolType == self.SYMBOL_WILD_2X or
    _symbolType == self.SYMBOL_WILD_3X or
    _symbolType == self.SYMBOL_WILD_5X or
    _symbolType == self.SYMBOL_WILD_8X or
    _symbolType == self.SYMBOL_WILD_10X or
    _symbolType == self.SYMBOL_WILD_25X or
    _symbolType == self.SYMBOL_WILD_100X then
        return true
    end
    return false
end
function CodeGameScreenPalaceWishMachine:showLineFrame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_isSuperFree then
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                local _slotNode = self:getFixSymbol(iCol,iRow)
                if _slotNode then
                    if self:isMultiWildSymbol(_slotNode.p_symbolType) then
                        _slotNode:setLineAnimName("actionframe3")
                        _slotNode:setIdleAnimName("idleframe2")
                    end
                end
            end
        end
    end
    CodeGameScreenPalaceWishMachine.super.showLineFrame(self)
end

function CodeGameScreenPalaceWishMachine:triggerFreeSpinCallFun()
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
    -- self:resetMusicBg()    --改
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenPalaceWishMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    -- self:clearCurMusicBg() --改
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        self:showBonusAndScatterLineTip(
            bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenPalaceWishMachine:beginReel()
    --改    引用底层改不能连着点击
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end
    --改
    CodeGameScreenPalaceWishMachine.super.beginReel(self)
end

function CodeGameScreenPalaceWishMachine:bgMusicDown( time )
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

--[[
    显示大赢光效事件
]]
function CodeGameScreenPalaceWishMachine:showEffect_runBigWinLightAni(effectData)
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
function CodeGameScreenPalaceWishMachine:showBigWinLight(_func)
    local animName = "win1"

    if (self:getCurrSpinMode() == NORMAL_SPIN_MODE or 
    self:getCurrSpinMode() == AUTO_SPIN_MODE) or (globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and self.m_isSuperFree) then
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and self.m_isSuperFree then
            self.m_juese:setVisible(true)
            util_spinePlay(self.m_juese, "win2", false)
            local spineEndCallFunc = function()
                -- self.m_juese:setVisible(false)
                util_spinePlay(self.m_juese, "idleframe3", true)
                self.m_jueseAnimIsPlay = false
            end
            util_spineEndCallFunc(self.m_juese, "win2", spineEndCallFunc)
        else
            self.m_juese:setVisible(true)
            util_spinePlay(self.m_juese, animName, false)
            local spineEndCallFunc = function()
                -- self.m_juese:setVisible(false)
                self.m_jueseAnimIsPlay = false
                self:runJueseIdleAni()
            end
            util_spineEndCallFunc(self.m_juese, animName, spineEndCallFunc)
        end
        
    end
    
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_bigwin_global.mp3")

    self.m_effectBigWin:setVisible(true)
    util_spinePlay(self.m_effectBigWin, "actionframe", false)
    local spineEndCallFunc = function()
        self.m_effectBigWin:setVisible(false)
    end
    util_spineEndCallFunc(self.m_effectBigWin, "actionframe", spineEndCallFunc)
    

    
    --崩数字
    local lightAni = util_createAnimation("PalaceWish_respin_WinningNums.csb")
    self.m_bottomUI.coinWinNode:addChild(lightAni)
    -- lightAni:findChild("m_lb_coins"):setString("+"..util_formatCoins(addScore,30))

    local labelNum = lightAni:findChild("m_lb_coins")
    local coins = self.m_iOnceSpinLastWin
    self:updateLabelSize({label=labelNum, sx = 1, sy = 1},774)
    labelNum:setString("")
    local addValue = coins / 60
    util_jumpNum(labelNum, 0, coins, addValue, 1 / 60, {30}, "+", nil, function()
    end, function()
        local info1={label=labelNum,sx=1,sy=1}
        self:updateLabelSize(info1,470)
    end)
    lightAni:runCsbAction("start",false,function(  )--18帧
        lightAni:runCsbAction("idle",true)
    end)

    self:delayCallBack(18/60 + 2, function()
        lightAni:runCsbAction("over",false,function(  )
            labelNum:unscheduleUpdate()
            lightAni:removeFromParent()
        end)
    end)


    self:shakeOneNodeForever(90/30)
    
    self:delayCallBack(90/30, function()
        self:stopLinesWinSound()
        
        if type(_func) == "function" then
            _func()
        end
    end)

end

return CodeGameScreenPalaceWishMachine




