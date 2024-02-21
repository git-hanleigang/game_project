---
-- island li
-- 2019年1月26日
-- CodeGameScreenDazzlingDiscoMachine.lua
-- 
-- 玩法：
-- 
local SlotParentData = require "data.slotsdata.SlotParentData"
local PublicConfig = require "DazzlingDiscoPublicConfig"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenDazzlingDiscoMachine = class("CodeGameScreenDazzlingDiscoMachine", BaseReelMachine)

CodeGameScreenDazzlingDiscoMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_WILD_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- wild2信号 93
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- Bonus信号 94
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7  -- 空信号 100
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8  -- mini信号 101
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- minor信号 102
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10  -- major信号 103
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_MEGA = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11  -- mega信号 104
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12  -- grand信号 105
CodeGameScreenDazzlingDiscoMachine.SYMBOL_SCORE_HEAD = 201  -- 头像信号


CodeGameScreenDazzlingDiscoMachine.CHANGE_MUTIPLE_BY_WINLINE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --连线后改变乘倍进度
CodeGameScreenDazzlingDiscoMachine.JACKPOT_REEL_OVER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --jackpot reel结束
CodeGameScreenDazzlingDiscoMachine.REFRESH_SPOT_VIEW_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --刷新点位信息数据

-- 构造函数
function CodeGameScreenDazzlingDiscoMachine:ctor(params)
    CodeGameScreenDazzlingDiscoMachine.super.ctor(self,params)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isShowOutGame = false
    self.m_isShowSystemView = false
    self.m_isTriggerJackpotReels = false
    self.m_isEnterOver = false
    self.m_isFreeSpinOver = false
    self.m_isShowFreeLight = false
    self.m_scheduleCallFuncs = {}
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效


    self.m_publicConfig = PublicConfig
    self.m_bonusSymbols = {}


    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
 
    --init
    self:initGame()
end

function CodeGameScreenDazzlingDiscoMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenDazzlingDiscoMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "DazzlingDisco"  
end

function CodeGameScreenDazzlingDiscoMachine:getReelNode()
    return "CodeDazzlingDiscoSrc.DazzlingDiscoClassicReelNode"
end

--小块
function CodeGameScreenDazzlingDiscoMachine:getBaseReelGridNode()
    return "CodeDazzlingDiscoSrc.DazzlingDiscoSlotsNode"
end

function CodeGameScreenDazzlingDiscoMachine:getBottomUINode()
    return "CodeDazzlingDiscoSrc.DazzlingDiscoBottomNode"
end

--绘制多个裁切区域
function CodeGameScreenDazzlingDiscoMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    
    self.m_slotParents = {}
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for iCol = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (iCol - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY
        

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(iCol)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local parentData = SlotParentData:new()
        parentData.cloumnIndex = iCol
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum
        parentData.startX = reelSize.width * 0.5
        parentData.reelWidth = reelSize.width
        parentData.reelHeight = reelSize.height
        parentData.slotNodeW = self.m_SlotNodeW
        parentData.slotNodeH = self.m_SlotNodeH
        parentData:reset()
        self.m_slotParents[iCol] = parentData

        local clipNode  
        clipNode = util_require(self:getReelNode()):create({
            parentData = parentData,      --列数据
            configData = self.m_configData,      --列配置数据
            doneFunc = handler(self,self.slotOneReelDown),        --列停止回调
            createSymbolFunc = handler(self,self.getSlotNodeWithPosAndType),--创建小块
            pushSlotNodeToPoolFunc = handler(self,self.pushSlotNodeToPoolBySymobolType),--小块放回缓存池
            updateGridFunc = handler(self,self.updateReelGridNode),  --小块数据刷新回调
            checkAddSignFunc = handler(self,self.checkAddSignOnSymbol), --小块添加角标回调
            direction = 0,      --0纵向 1横向 默认纵向
            colIndex = iCol,
            bigReelNode = self.m_bigReelNodeLayer,
            machine = self      --必传参数
        })
        self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        self.m_baseReelNodes[iCol] = clipNode
        clipNode:setPosition(cc.p(posX,posY))
    end

    self:findChild("Node_yinying"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10)

    --等裁切层加在父节点上之后再刷新大信号位置,否则坐标无法转化
    self:refreshBigRollNodePos()
end
---
-- 获取最高的那一列
--
function CodeGameScreenDazzlingDiscoMachine:updateReelInfoWithMaxColumn()
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

        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
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
    self.m_SlotNodeH = self.m_fReelHeigth / (self.m_iReelRowNum - 1)

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = 5
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

--[[
    初始化房间列表
]]
function CodeGameScreenDazzlingDiscoMachine:initRoomList()
    --房间列表
    self.m_roomList = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoRoomListView", {machine = self})
    self:findChild("Node_minetouxiang"):addChild(self.m_roomList)
    self.m_roomData = self.m_roomList.m_roomData

    
end

function CodeGameScreenDazzlingDiscoMachine:initFreeSpinBar()
    
end

function CodeGameScreenDazzlingDiscoMachine:showFreeSpinBar()

end

function CodeGameScreenDazzlingDiscoMachine:hideFreeSpinBar()

end

--[[
    创建背景
]]
function CodeGameScreenDazzlingDiscoMachine:initMachineBg()
    local gameBg = util_spineCreate("DazzlingDisco_bg",true,true)
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end

    self.m_gameBg = gameBg
    self.m_gameBg2 = util_spineCreate("DazzlingDisco_bg_2",true,true)
    self.m_gameBg3 = util_spineCreate("DazzlingDisco_bg_3",true,true)
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        bgNode:addChild(self.m_gameBg2, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
        bgNode:addChild(self.m_gameBg3, GAME_LAYER_ORDER.LAYER_ORDER_BG + 2)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        self:addChild(self.m_gameBg2, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
        self:addChild(self.m_gameBg3, GAME_LAYER_ORDER.LAYER_ORDER_BG + 2)
    end

    util_spinePlay(self.m_gameBg2,"idleframe3",true)
    util_spinePlay(self.m_gameBg3,"idleframe3",true)
    self.m_gameBg2:setVisible(false)
    self.m_gameBg3:setVisible(false)

    self:changeBgAni("base")
end

--[[
    修改背景动画
]]
function CodeGameScreenDazzlingDiscoMachine:changeBgAni(aniType)
    if aniType == "base" then
        util_spinePlay(self.m_gameBg,"idleframe",true)
        self.m_gameBg2:setVisible(false)
        self.m_gameBg3:setVisible(false)
    elseif aniType == "jackpotReel" then
        util_spinePlay(self.m_gameBg,"idleframe2",true)
        self.m_gameBg2:setVisible(false)
        self.m_gameBg3:setVisible(false)
    elseif aniType == "bonus2" then --特殊效果
        util_spinePlay(self.m_gameBg2,"idleframe4")
        util_spineEndCallFunc(self.m_gameBg2,"idleframe4",function(  )
            self:changeBgAni("bonus")
        end)
        self.m_gameBg2:setVisible(true)
        self.m_gameBg3:setVisible(true)
    elseif aniType == "bonus3" then
        util_spinePlay(self.m_gameBg2,"idleframestart")
        util_spineEndCallFunc(self.m_gameBg2,"idleframestart",function(  )
            util_spinePlay(self.m_gameBg2,"idleframe5",true)
        end)
        self.m_gameBg2:setVisible(true)
        self.m_gameBg3:setVisible(true)
    elseif aniType == "bonus4" then
        util_spinePlay(self.m_gameBg2,"idleframeover")
        util_spineEndCallFunc(self.m_gameBg2,"idleframeover",function(  )
            self:changeBgAni("bonus")
        end)
    elseif aniType == "showLine" then
        util_spinePlay(self.m_gameBg2,"idleframe6",true)
    elseif aniType == "bonus" then
        util_spinePlay(self.m_gameBg,"idleframe3",true)
        util_spinePlay(self.m_gameBg2,"idleframe3",true)
        util_spinePlay(self.m_gameBg3,"idleframe3",true)
        self.m_gameBg2:setVisible(true)
        self.m_gameBg3:setVisible(true)
    end
end


function CodeGameScreenDazzlingDiscoMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --计时器节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)
    self:startSchedule()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,1000)
    
    --初始化房间列表
    self:initRoomList()

    self:initFreeSpinBar() -- FreeSpinbar

    --乘倍栏
    self.m_multipleBar = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoMultipleBar",{machine = self})
    self:findChild("Node_chengbeilan"):addChild(self.m_multipleBar)

    --jackpot栏
    self.m_jackpotBar = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoJackPotBarView",{machine = self})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --点位收集栏
    self.m_spotView = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSpotView",{machine = self})
    self:findChild("node_main"):addChild(self.m_spotView)
    -- self.m_spotView:setVisible(false)

    --大赢光效spine
    self.m_spine_big_win = util_spineCreate("DazzlingDisco_bigwin",true,true)
    self:findChild("bigwin"):addChild(self.m_spine_big_win)
    self.m_spine_big_win:setVisible(false)

    --bonus玩法界面
    self.m_bonusView = util_createView("CodeDazzlingDiscoBonusGame.DazzlingDiscoBonusView",{machine = self})
    self:findChild("root"):addChild(self.m_bonusView)
    self.m_bonusView:setPosition(cc.p(-display.center.x,-display.center.y))
    self.m_bonusView:setVisible(false)

    --freeSpin轮盘光效
    self.m_light_free_bg = util_createAnimation("DazzlingDisco_qipan_xia.csb")
    self:findChild("qipan_xia"):addChild(self.m_light_free_bg)
    self.m_light_free_bg:setVisible(false)

    self.m_light_front = util_createAnimation("DazzlingDisco_qipan_shang.csb")
    self:findChild('qipan_shang'):addChild(self.m_light_front)
    self.m_light_front:setVisible(false)

    self.m_light_front_free = util_createAnimation("DazzlingDisco_qipan_shang_0.csb")
    self:findChild('qipan_shang'):addChild(self.m_light_front_free)
    self.m_light_front_free:setVisible(false)
    
end

--[[
    设置基础界面是否显示
]]
function CodeGameScreenDazzlingDiscoMachine:setBaseUiShow(isShow)
    self:findChild("node_main"):setVisible(isShow)
end


function CodeGameScreenDazzlingDiscoMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound(PublicConfig.SoundConfig.sound_DazzlingDisco_enter_game)

    end,0.4,self:getModuleName())
end

--播放
function CodeGameScreenDazzlingDiscoMachine:playCoinWinEffectUI(callBack)
    if self.m_bottomUI ~= nil then
        self.m_bottomUI:playCoinWinEffectUI(callBack)
        if self.m_bottomUI.coinBottomEffectNode and self.m_bottomUI.coinBottomEffectNode:findChild("Particle_1") then
            self.m_bottomUI.coinBottomEffectNode:findChild("Particle_1"):resetSystem()
        end
    end
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenDazzlingDiscoMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local isInFs = false
    if
        hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or (self.m_initSpinData.p_freeSpinsLeftCount > 0 and hasReSpinFeature == true))
     then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self:checkTriggerFsOver() then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end

        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end
function CodeGameScreenDazzlingDiscoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenDazzlingDiscoMachine.super.onEnter(self)     -- 必须调用不予许删除
    if self.m_isRunningEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
    self:addObservers()

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "DazzlingDisco_totalwin.csb")
    if self.m_bottomUI.coinBottomEffectNode then
        self.m_bottomUI.coinBottomEffectNode:setPositionY(-38)
    end

    --刷新当前乘倍进度
    self:updateCurMulti()

    if (self:getCurrSpinMode() == FREE_SPIN_MODE or self:checkTriggerFree()) and not self.m_isTriggerBonus then
        self:changeReelToTrigger()
        self:setFreeLightShow(true)
        self:changeBgAni("jackpotReel")
    end
    
    self.m_spotView:refreshView()

    self.m_isEnterOver = true

    if self:getCurrSpinMode() ==  NORMAL_SPIN_MODE and not self.m_isTriggerJackpotReels then
        self:showOrHideMailTip()
    end
    
end

function CodeGameScreenDazzlingDiscoMachine:addObservers()
    CodeGameScreenDazzlingDiscoMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

        -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --     --freespin最后一次spin不会播大赢,需单独处理
        --     local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
        --     if fsLeftCount <= 0 then
        --         self.m_bIsBigWin = false
        --     end
        -- end
        
        
        if self.m_isTriggerBonus then
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

        local soundName = PublicConfig.SoundConfig["sound_DazzlingDisco_winline_"..soundIndex] 
        if self.m_isTriggerJackpotReels then
            soundName = PublicConfig.SoundConfig.sound_DazzlingDisco_jackpot_symbol_trigger
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenDazzlingDiscoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()

    CodeGameScreenDazzlingDiscoMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    --需手动调用房间列表的退出方法,否则未加载完成退出游戏不会主动调用
    -- self.m_roomList:onExit()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenDazzlingDiscoMachine:showOrHideMailTip()
    if self.m_isTriggerBonus then
        return
    end

    local wins = self.m_roomData:getWinSpots()
    if wins and #wins > 0 then
        self:openMail()
        self.m_isShowMail = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end

--打开邮件
function CodeGameScreenDazzlingDiscoMachine:openMail()
    local mailTip = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoMailTip",{machine = self})
    mailTip:setClickEnable(false)
    self:findChild("Node_Mail"):addChild(mailTip)
    local movePos = util_convertToNodeSpace(self:findChild("root"),self:findChild("Node_Mail"))--cc.p(self:findChild("MailFlyNode"):getPosition())
    local delay = cc.DelayTime:create(64 / 60)
    local moveTo = cc.MoveTo:create(22 / 60, movePos)
    mailTip:runAction(cc.Sequence:create(delay, moveTo))
    mailTip:runCsbAction(
        "actionframe",
        false,
        function()
            mailTip:removeFromParent()
        end,
        60
    )

    self:delayCallBack(110 / 60,function(  )
        self:showSpotMailWinView()
    end)
end

--邮箱获得奖励弹板
function CodeGameScreenDazzlingDiscoMachine:showSpotMailWinView()

    local winCoins = self.m_roomData:getMailWinCoins()

    local winView = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSpotMailWin",{
        machineRootScale = self.m_machineRootScale,
        winCoins = winCoins,
        func = function(  )

            local gameName = self:getNetWorkModuleName()
            local winSpots = self.m_roomData:getWinSpots()
            local index = -1
            --发送领奖消息
            gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
                function()
                    globalData.slotRunData.lastWinCoin = 0
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                        winCoins, true, true
                    })
                    
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                    --重新刷新房间消息
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
                    self.m_isShowMail = false
                end,
                function(errorCode, errorData)
                    
                end
            )
        end
    })

    gLobalViewManager:showUI(winView)
    winView:setPosition(display.center)

    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

--[[
    退出到大厅
]]
function CodeGameScreenDazzlingDiscoMachine:showOutGame( )

    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end

--[[
    暂停轮盘
]]
function CodeGameScreenDazzlingDiscoMachine:pauseMachine()
    CodeGameScreenDazzlingDiscoMachine.super.pauseMachine(self)
    self.m_isShowSystemView = true
    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

--[[
    恢复轮盘
]]
function CodeGameScreenDazzlingDiscoMachine:resumeMachine()
    CodeGameScreenDazzlingDiscoMachine.super.resumeMachine(self)
    self.m_isShowSystemView = false
    if self.m_isTriggerBonus then
        return
    end
    --重新刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
end

--[[
    获取邮件奖励
]]
function CodeGameScreenDazzlingDiscoMachine:showMailWinView()
    local winView = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoMailWin",{machine = self})
    local _winCoins = self.m_roomData:getMailWinCoins()
    winView:initViewData(_winCoins)
    winView:setPosition(display.width / 2,display.height / 2)
    --检测大赢
    self:checkFeatureOverTriggerBigWin(_winCoins, GameEffect.EFFECT_BONUS)

    winView:setFunc(
        function()
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                _winCoins, true, true
            })
            --为了播放大赢动画
            self:playGameEffect()
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            --重新刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
        end
    )
    gLobalViewManager:showUI(winView)

    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

---
--设置bonus scatter 层级
function CodeGameScreenDazzlingDiscoMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType == self.SYMBOL_SCORE_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType >= self.SYMBOL_SCORE_MINI then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + symbolType * 10
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCORE_WILD_2 then
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


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenDazzlingDiscoMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_HEAD then
        return "Socre_DazzlingDisco_Rentou"
    end

    if symbolType == self.SYMBOL_SCORE_WILD_2 then
        return "Socre_DazzlingDisco_WildBonus"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_DazzlingDisco_Bonus"
    end

    if symbolType == self.SYMBOL_SCORE_EMPTY then
        return "Socre_DazzlingDisco_Empty"
    end

    if self:isJackpotSymbol(symbolType) then
        return "Socre_DazzlingDisco_Jackpot"
    end
    return nil
end

--[[
    是否为jackpot信号
]]
function CodeGameScreenDazzlingDiscoMachine:isJackpotSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_MINI 
        or symbolType == self.SYMBOL_SCORE_MINOR 
        or symbolType == self.SYMBOL_SCORE_MAJOR 
        or symbolType == self.SYMBOL_SCORE_MEGA 
        or symbolType == self.SYMBOL_SCORE_GRAND then
            return true
    end
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenDazzlingDiscoMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenDazzlingDiscoMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

----------------------------- 数据处理 -----------------------------------

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenDazzlingDiscoMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self.m_isTriggerJackpotReels then --jackpot玩法
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(1, parentData.cloumnIndex)
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
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
-------------------------------------------------------------------------------------------------------------------------



----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenDazzlingDiscoMachine:MachineRule_initGame(  )

    
end

function CodeGameScreenDazzlingDiscoMachine:callSpinBtn()
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            self.m_reelRunInfo[i]:setReelRunLenToFreespinReelRunLen()
        end
    end

    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    self:notifyClearBottomWinCoin()

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if not self:checkSpecialSpin() and not self.m_isTriggerJackpotReels and
    self:getCurrSpinMode() ~= FREE_SPIN_MODE and 
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
    self:getCurrSpinMode() ~= RESPIN_MODE and 
    betCoin > totalCoin and
    self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE then
        
        self:operaUserOutCoins()
    else
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and 
        self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and 
        self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and 
        not self.m_isTriggerJackpotReels
        and not self:checkSpecialSpin() then
            self:callSpinTakeOffBetCoin(betCoin)
        else
            self:takeSpinNextData()
        end

        --统计quest spin次数
        self:staticsQuestSpinData()

        self:spinBtnEnProc()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()
    end
    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end

function CodeGameScreenDazzlingDiscoMachine:beginReel()
    self:startSchedule()
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()
    self.m_bonusSymbols = {}

    if self.m_spotView.m_isShow then
        self.m_spotView:hideView()
    end
    
    local endCount = 0
    local maxCount = #self.m_baseReelNodes
    if self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_isTriggerJackpotReels then
        maxCount = maxCount - 1
    end
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        local moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            parentData.moveSpeed = moveSpeed
            reelNode:changeReelMoveSpeed(moveSpeed)
        end
        reelNode:resetReelDatas()
        if iCol == 2 and self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_isTriggerJackpotReels then
            reelNode.m_parentData.isDone = false
        else
            reelNode:startMove(function()
                endCount = endCount + 1
                if endCount >= maxCount then
                    self:requestSpinReusltData()
                end
            end)
        end
        
    end

    --重置自动退出时间间隔
    self.m_roomList:resetLogoutTime()
end

--
--单列滚动停止回调
--
function CodeGameScreenDazzlingDiscoMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    --检测播放落地动画
    self:checkPlayBulingAni(reelCol)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self:triggerLongRunChangeBtnStates()

        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            reelNode:changeReelMoveSpeed(parentData.moveSpeed)
        end
        
    end

    --检测滚动是否全部停止
    local stopCount = 0
    for iCol,parentData in ipairs(self.m_slotParents) do
        if parentData.isDone then
            stopCount = stopCount + 1
        end
    end

    local maxCount = self.m_iReelColumnNum
    if self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_isTriggerJackpotReels then
        maxCount = maxCount - 1
    end

    --滚动彻底停止
    if stopCount >= maxCount then
        local delayTime = self.m_configData.p_reelResTime
        self:delayCallBack(delayTime,function()
            self:slotReelDown()
        end)
        
    end

    return isTriggerLongRun
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenDazzlingDiscoMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenDazzlingDiscoMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------



----------- FreeSpin相关
---
-- 显示free spin
function CodeGameScreenDazzlingDiscoMachine:showEffect_FreeSpin(effectData)
    --设置free spin状态
    self:setCurrSpinMode(FREE_SPIN_MODE)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_trigger_free)
    effectData.p_isPlay = true
    self:playGameEffect()
    return true
end
-- FreeSpinstart
function CodeGameScreenDazzlingDiscoMachine:showFreeSpinView(effectData)
    
end

--[[
    显示free光效
]]
function CodeGameScreenDazzlingDiscoMachine:setFreeLightShow(isShow)
    --显示光效
    self.m_light_free_bg:setVisible(isShow)
    if isShow then
        self.m_light_free_bg:runCsbAction("idle",true)
        self.m_light_front:runCsbAction("idle",true)
        self.m_light_front_free:runCsbAction("idle",true)

        if self.m_isTriggerJackpotReels then
            self.m_light_front:setVisible(true)
            self.m_light_front_free:setVisible(false)
            util_nodeFadeIn(self.m_light_front, 0.3, 0, 255, nil)
        else
            self.m_light_front:setVisible(false)
            self.m_light_front_free:setVisible(true)
            util_nodeFadeIn(self.m_light_front_free, 0.3, 0, 255, nil)
        end 
    else
        if self.m_isTriggerJackpotReels then
            self.m_light_front:setVisible(true)
            self.m_light_front_free:setVisible(false)
            util_fadeOutNode(self.m_light_front,0.3,function()
                self.m_light_front:setVisible(false)
            end)
        else
            self.m_light_front:setVisible(false)
            self.m_light_front_free:setVisible(true)
            util_fadeOutNode(self.m_light_front_free,0.3,function()
                self.m_light_front_free:setVisible(false)
            end)
        end
        
    end

    self.m_isShowFreeLight = isShow
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenDazzlingDiscoMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    self.m_isTriggerBonus = false

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
function CodeGameScreenDazzlingDiscoMachine:addSelfEffect()

    --检测是否触发bonus玩法
    self:checkTriggerBonus()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 更改乘倍进度
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME - 2
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.CHANGE_MUTIPLE_BY_WINLINE_EFFECT -- 动画类型

    if self.m_isTriggerJackpotReels and self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        -- 更改乘倍进度
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.JACKPOT_REEL_OVER_EFFECT -- 动画类型
    end

    --刷新点位数据
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.REFRESH_SPOT_VIEW_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.REFRESH_SPOT_VIEW_EFFECT -- 动画类型
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenDazzlingDiscoMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.CHANGE_MUTIPLE_BY_WINLINE_EFFECT then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:changeMultipleAni(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.JACKPOT_REEL_OVER_EFFECT then
        self:delayCallBack(1,function(  )
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            
            self:showJackpotView(function(  )
                self:changeBgAni("base")
                self:resetMusicBg(false,"DazzlingDiscoSounds/music_DazzlingDisco_base.mp3")
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    self:setFreeLightShow(true)
                    self:changeBgAni("jackpotReel")
                    --重置轮盘为触发轮盘
                    self:changeReelToTrigger(function(  )
                        effectData.p_isPlay = true
                        self:playGameEffect()   
                    end)
                    if self.m_wildSymbol then
                        self.m_wildSymbol:runAnim("idleframe2",true)
                    end
                else
                    self:setFreeLightShow(false)
                    effectData.p_isPlay = true
                    self:playGameEffect()   
                end
            end)
        end)
    elseif effectData.p_selfEffectType == self.REFRESH_SPOT_VIEW_EFFECT then --刷新点位数据
        
        self:refreshSpotView(function(  )
            self.m_roomList:updateSpotNum()
            effectData.p_isPlay = true
            self:playGameEffect()   
        end)
    end
    return true
end

--[[
    金币跳动
]]
function CodeGameScreenDazzlingDiscoMachine:jumpCoins(params)
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
            label:setString("+"..util_formatCoins(endCoins,50))
            local info={label = label,sx = lblScale,sy = lblScale}
            self:updateLabelSize(info,maxWidth)

            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString("+"..util_formatCoins(curCoins,50))

            local info={label = label,sx = lblScale,sy = lblScale}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    刷新点位数据
]]
function CodeGameScreenDazzlingDiscoMachine:refreshSpotView(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.bonusCols and selfData.bonusCols > 0 then --自己中bonus
        --禁止点击按钮
        self.m_spotView:setBtnClickEnable(false)

        --等待落地播完
        self:delayCallBack(16 / 30,function(  )
            --bonus图标播触发动画
            for k,symbolNode in pairs(self.m_bonusSymbols) do
                symbolNode:runAnim("actionframe",false,function()
                    symbolNode:runAnim("idleframe2",true)
                end)
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_bonus_symbol_trigger)
            
            --等待触发动画播完
            self:delayCallBack(90 / 30,function(  )
                local collectData = selfData.collectData
                local winCoins = 0
                if collectData then
                    winCoins = collectData.coins
                end
                --显示点位赢钱弹板
                self:showSpotWinView(winCoins,function(  )
                    self.m_spotView:showView(function(  )
                        --显示获得的点位
                        self.m_spotView:showCurSpotAni(collectData,function(  )
                            self:delayCallBack(1,function()
                                self.m_spotView:hideView(function(  )
                                    --恢复按钮点击
                                    if not self.m_isTriggerBonus then
                                        self.m_spotView:setBtnClickEnable(true)
                                    end
                                    
                                    self.m_spotView:refreshView()

                                    if type(func) == "function" then
                                        func()
                                    end
                                end)
                            end)
                        end)
                    end)
                end)
            end)
            
        end)
    else    --自己未中只刷新
        self.m_spotView:refreshView()
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    显示点位赢钱分弹板
]]
function CodeGameScreenDazzlingDiscoMachine:showSpotWinView(coins,func)
    -- self.m_effectNode
    local view = util_createAnimation("DazzlingDisco_spot_tanban.csb")
    self.m_effectNode:addChild(view)

    local m_lb_coins = view:findChild("m_lb_coins")
    m_lb_coins:setString(util_formatCoins(coins,50))
    local info1={label=m_lb_coins,sx=1,sy=1}
    self:updateLabelSize(info1,640)

    local light = util_createAnimation("DazzlingDisco_spot_tanban_glow.csb")
    view:findChild("glow"):addChild(light)
    light:runCsbAction("idle",true)

    util_setCascadeOpacityEnabledRescursion(view:findChild("glow"),true)

    local params = {}
    params[#params + 1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = view,   --执行动画节点  必传参数
        soundFile = PublicConfig.SoundConfig.sound_DazzlingDisco_show_spot_win,  --播放音效 执行动作同时播放 可选参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
        actionList = {}, --动作列表 序列动作必传参数
    }
    params[#params + 1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = view,   --执行动画节点  必传参数
        actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
        actionList = {}, --动作列表 序列动作必传参数
    }
    params[#params + 1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = view,   --执行动画节点  必传参数
        soundFile = PublicConfig.SoundConfig.sound_DazzlingDisco_hide_spot_win,  --播放音效 执行动作同时播放 可选参数
        actionName = "over", --动作名称  动画必传参数,单延时动作可不传
        actionList = {}, --动作列表 序列动作必传参数
        callBack = function(  )
            view:removeFromParent()
            if type(func) == "function" then
                func()
            end
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)
end

--[[
    重置轮盘为触发轮盘
]]
function CodeGameScreenDazzlingDiscoMachine:changeReelToTrigger(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.freeTriggerReSpinReels then
        local reels = selfData.freeTriggerReSpinReels
        for iRow = 1,self.m_iReelRowNum do
            for iCol = 1,self.m_iReelColumnNum do
                local symbolType = reels[self.m_iReelRowNum - iRow + 1][iCol]
                local symbolNode = self:getFixSymbol(iCol,iRow)
                if symbolNode and symbolType then
                    self:changeSymbolType(symbolNode,symbolType)
                    if symbolType == self.SYMBOL_SCORE_WILD_2 and iRow == 3 then
                        self.m_wildSymbol = symbolNode
                    end
                end
            end
        end
    else
        for iCol = 1,self.m_iReelColumnNum do
            local iRow = 3
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_WILD_2 then
                self.m_wildSymbol = symbolNode
                break
            end
        end
    end

    if self.m_wildSymbol then
        self.m_wildSymbol:runAnim("idleframe2",true)
    end

    if type(func) == "function" then
        func()
    end
end

--[[
    修改乘倍进度
]]
function CodeGameScreenDazzlingDiscoMachine:changeMultipleAni(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --当前连续赢钱次数
    local consecutiveWins = 0
    if selfData and selfData.consecutiveWins then
        consecutiveWins = selfData.consecutiveWins
    end

    if consecutiveWins == 9 then
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "respin")
        end
    end
    self.m_multipleBar:addMultiAni(consecutiveWins,func)
end

--[[
    显示乘倍动画
]]
function CodeGameScreenDazzlingDiscoMachine:showMultiAni(startNode,multiple,func)
    local ani = util_createAnimation("DazzlingDisco_base_chengbei.csb")
    self:findChild("Node_chengbei"):addChild(ani)
    ani:findChild("m_lb_num"):setString(multiple)
    

    local startPos = util_convertToNodeSpace(startNode,self:findChild("Node_chengbei"))
    ani:setPosition(startPos)

    local actionList = {
        cc.DelayTime:create(8 / 60),
        cc.EaseExponentialIn:create(cc.MoveTo:create(24 / 60,cc.p(0,0)))
    }
    local action = cc.Sequence:create(actionList)
    ani:runAction(action)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_multi_to_reel)
    ani:runCsbAction("chengbei",false,function(  )
        ani:removeFromParent()
    end)

    self:delayCallBack(60 / 60,function(  )
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    刷新当前乘倍进度
]]
function CodeGameScreenDazzlingDiscoMachine:updateCurMulti( )
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --当前连续赢钱次数
    local consecutiveWins = 0
    if selfData and selfData.consecutiveWins then
        consecutiveWins = selfData.consecutiveWins
    end

    self.m_multipleBar:updateCurMulti(consecutiveWins)
end


--[[
    检测是否触发bonus
]]
function CodeGameScreenDazzlingDiscoMachine:checkTriggerBonus()

    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k,gameEffect in pairs(self.m_gameEffects) do
        if gameEffect and gameEffect.p_effectType == GameEffect.EFFECT_BONUS then
            return true
        end
    end
    
    --有玩家触发Bonus
    local result = self.m_roomData:getSpotResult()

    --测试代码
    -- local fileUtil = cc.FileUtils:getInstance()
    -- local fullPath = fileUtil:fullPathForFilename("CodeDazzlingDiscoSrc/resultData.json")
    -- local jsonStr = fileUtil:getStringFromFile(fullPath) 
    -- local result = cjson.decode(jsonStr)

    if result then
        -- util_printTable(result)
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
        self:addBonusEffect(result)
        return true
    end

    return false
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenDazzlingDiscoMachine:addBonusEffect(result)
    -- self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local effect = GameEffectData.new()
    effect.p_effectType = GameEffect.EFFECT_BONUS
    effect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = effect
    --进入玩法后需要使用拷贝出来的result结果,本地roomData中的result需要清空,防止重复触发玩法
    effect.resultData = clone(result) 

    self.m_isTriggerBonus = true
end

--[[
    Bonus玩法
]]
function CodeGameScreenDazzlingDiscoMachine:showEffect_Bonus(effectData)
    --重置界面状态
    local function resetViewStatus()
        effectData.p_isPlay = true
        self:playGameEffect()
        --重置bonus触发状态
        self.m_isTriggerBonus = false
        self.m_spotView:setBtnClickEnable(true)

        if self.m_isTriggerJackpotReels or self:getCurrSpinMode() == FREE_SPIN_MODE or self:checkTriggerFree() then
            --显示光效
            self:setFreeLightShow(true)
            self:changeBgAni("jackpotReel")
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
        end

        --重新刷新房间数据
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
        
        self.m_spotView:refreshView()
    end

    --bonus结束回调
    local function bonusEnd()
        --变更轮盘状态
        -- if globalData.slotRunData.m_isAutoSpinAction then
        --     self:setCurrSpinMode(AUTO_SPIN_MODE)
        -- else
        --     self:setCurrSpinMode(NORMAL_SPIN_MODE)
        -- end

        self:resetMusicBg(false,"DazzlingDiscoSounds/music_DazzlingDisco_base.mp3")

        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_change_scene_to_base)
        self:changeSceneAni(function(  )
            self.m_bonusView:hideView()
            self:setBaseUiShow(true)
            self:changeBgAni("base")
        end,function(  )
            resetViewStatus()
        end)

        
    end

    globalData.slotRunData.lastWinCoin = 0
    self.m_spotView:setBtnClickEnable(false)

    if self.m_isTriggerJackpotReels or self:getCurrSpinMode() == FREE_SPIN_MODE or self:checkTriggerFree() then
        --隐藏光效
        self:setFreeLightShow(false)
    end

    --重置bonus界面及数据
    self.m_bonusView:resetView(effectData.resultData.data,bonusEnd)

    --触发bonus
    self:triggerBonusAni(function(  )
        local spotCount = self.m_roomList:getSelfSpotCount()

        local callBack = function()
            self:showBonusStart(function()
                self.m_bottomUI:updateWinCount("")
                self:showBonusGameView() 
                self.m_roomData.m_teamData.room.result = nil
                self.m_spotView:refreshView()
                self.m_roomList:updateSpotNum()
            end)
        end

        if spotCount > 0 then
            callBack()
        else
            self:showSkipView(function(isLeave)
                if isLeave then
                    self.m_roomData.m_teamData.room.result = nil
                    resetViewStatus()
                    self.m_roomList:sendChangeRoom()
                else
                    callBack()
                end
                
            end)
        end
        
    end)
    
    return true
end

--[[
    显示是否跳过界面
]]
function CodeGameScreenDazzlingDiscoMachine:showSkipView(func)
    local view = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSkipTipView",{
        machineRootScale = self.m_machineRootScale,
        func = function(isLeave)
            if type(func) == "function" then
                func(isLeave)
            end
        end
    })

    gLobalViewManager:showUI(view)
    -- view:setPosition(display.center)
end


--[[
    触发bonus动画
]]
function CodeGameScreenDazzlingDiscoMachine:triggerBonusAni(func)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_bonus_trigger)
    self:triggerBonusSpineAni(function(  )
        self:resetRootPos()
        if type(func) == "function" then
            func()
        end
        
    end)

    self:shakeRootNode()
end

--[[
    触发bonus骨骼动画
]]
function CodeGameScreenDazzlingDiscoMachine:triggerBonusSpineAni(func)
    self.m_spine_big_win:setVisible(true)
    util_spinePlay(self.m_spine_big_win,"actionframe_chufa")
    util_spineEndCallFunc(self.m_spine_big_win,"actionframe_chufa",function(  )
        self.m_spine_big_win:setVisible(false)   
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    bonusStart弹板
]]
function CodeGameScreenDazzlingDiscoMachine:showBonusStart(func)
    local view = util_createAnimation("DazzlingDisco_bonus_start.csb")
    self.m_effectNode:addChild(view)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_bonus_start)

    view:runCsbAction("actionframe",false,function(  )
        view:removeFromParent()
        --黑色遮罩
        local mask = util_createAnimation("DazzlingDisco_mask.csb")
        self.m_effectNode:addChild(mask)
        mask:runCsbAction("animation0")

        local spine = util_spineCreate("DazzlingDisco_SocialStart",true,true)
        self.m_effectNode:addChild(spine,100)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_social_start)
        util_spinePlay(spine,"actionframe")
        util_spineEndCallFunc(spine,"actionframe",function(  )
            spine:setVisible(false)
            self:delayCallBack(0.1,function(  )
                spine:removeFromParent()
            end)
        end)

        self:delayCallBack(60 / 30,function(  )
            self:setBaseUiShow(false)
            self:resetMusicBg(false,"DazzlingDiscoSounds/music_DazzlingDisco_bonus.mp3")
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_change_scene_to_bonus)
            self:changeSceneAni(function(  )
                self:changeBgAni("bonus")
                
                if type(func) == "function" then
                    func()
                end
            end)
        end)

        self:delayCallBack(80 / 30,function(  )
            mask:runCsbAction("animation2",false,function()
                mask:removeFromParent()
            end)
        end)
    end)
end

--[[
    切换场景动画
]]
function CodeGameScreenDazzlingDiscoMachine:changeSceneAni(func,endFunc)
    --切换场景spine
    local changeSpine = util_spineCreate("DazzlingDisco_bg",true,true)
    self.m_effectNode:addChild(changeSpine,50)
    
    
    --播切换场景动画
    util_spinePlay(changeSpine,"actionframe_guochang")
    util_spineFrameCallFunc(changeSpine,"actionframe_guochang","show",function(  )
    
        if type(func) == "function" then
            func()
        end
    end,function(  )
        changeSpine:setVisible(false)
        if type(endFunc) == "function" then
            endFunc()
        end
        
        self:delayCallBack(0.1,function(  )
            changeSpine:removeFromParent()
        end)
    end)
end

--[[
    显示bonus玩法界面
]]
function CodeGameScreenDazzlingDiscoMachine:showBonusGameView()
    
    self.m_bonusView:showView()
end

--[[
    bonus结束
]]
function CodeGameScreenDazzlingDiscoMachine:showBonusOverView(winCoins,func)
    self:clearCurMusicBg()
    --检测是否获得大奖
    self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_bonus_over)

    local view = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoBonusOverView",{
        machineRootScale = self.m_machineRootScale,
        winCoins = winCoins,
        func = function(  )

            local gameName = self:getNetWorkModuleName()
            local winSpots = self.m_roomData:getWinSpots()
            local index = #winSpots - 1
            --发送领奖消息
            gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

                    if type(func) == "function" then
                        func()
                    end
                end,
                function(errorCode, errorData)
                    
                end
            )
        end
    })

    gLobalViewManager:showUI(view)
    view:setPosition(display.center)
    
    return view
end

--[[
    显示排行榜
]]
function CodeGameScreenDazzlingDiscoMachine:showRankListView(rankList,collectData,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_top_winner)
    local view = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoRankListView",{
        machineRootScale = self.m_machineRootScale,
        rankList = rankList,
        collectData = collectData,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:setPosition(display.center)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local fire = util_createAnimation("DazzlingDisco_fire.csb")
    view:addChild(fire)
    fire:runCsbAction("actionframe")
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenDazzlingDiscoMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenDazzlingDiscoMachine:playEffectNotifyNextSpinCall( )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self.m_isTriggerJackpotReels then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end

    if not self.m_isTriggerBonus then
        self:checkTriggerOrInSpecialGame(function(  )
            self:reelsDownDelaySetMusicBGVolume( ) 
        end)
    end
end

function CodeGameScreenDazzlingDiscoMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenDazzlingDiscoMachine.super.slotReelDown(self)

    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()

    if self.m_isShowFreeLight and self:getCurrSpinMode() ~= FREE_SPIN_MODE and not self:checkTriggerFree() and not self.m_isTriggerJackpotReels then
        --隐藏光效
        self:setFreeLightShow(false)
    end

    if self.m_isFreeSpinOver then
        self:changeBgAni("base")
        self.m_isFreeSpinOver = false
        if self.m_wildSymbol then
            self.m_wildSymbol:runAnim("idleframe")
            self.m_wildSymbol = nil
        end
    end
end

---
-- 点击快速停止reel
--
function CodeGameScreenDazzlingDiscoMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self:getGameSpinStage() == QUICK_RUN then
        return
    end
    self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。

    for iCol,parentData in ipairs(self.m_slotParents) do
        if iCol == 2 and self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_isTriggerJackpotReels then
            
        else
            --还未停止的列执行快停
            if not parentData.isDone then
                self.m_baseReelNodes[iCol]:quickStop()
            end
        end
        
    end
end

---
--判断改变freespin的状态
function CodeGameScreenDazzlingDiscoMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then -- free spin 模式结束
            self:setCurrSpinMode(NORMAL_SPIN_MODE)
            self.m_isFreeSpinOver = true
        end
    end
end

function CodeGameScreenDazzlingDiscoMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

---
-- 触发respin 玩法
--
function CodeGameScreenDazzlingDiscoMachine:showEffect_Respin(effectData)
    self.m_isTriggerJackpotReels = true
    
    self:showJackpotReelView(function(  )
        self:resetMusicBg(false,"DazzlingDiscoSounds/music_DazzlingDisco_jackpot.mp3")
        self:setFreeLightShow(true)
        effectData.p_isPlay = true
        self:playGameEffect()
    end)
    
    return true
end

--[[
    触发jackpot reel弹板
]]
function CodeGameScreenDazzlingDiscoMachine:showJackpotReelView(func)
    local view = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoJackpotReelStartView",{
        machineRootScale = self.m_machineRootScale,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:setPosition(display.center)
    
    return view
end

--[[
    显示jackpot弹板
]]
function CodeGameScreenDazzlingDiscoMachine:showJackpotView(func)

    self.m_isTriggerJackpotReels = false
    local winLine = self.m_runSpinResultData.p_winLines[1]
    local symbolType = winLine.p_type
    local jackpotType = self:getJakcpotTypeBySymbolType(symbolType)
    local winCoins = winLine.p_amount

    local view = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = winCoins,
        machineRootScale = self.m_machineRootScale,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:setPosition(display.center)
end

--[[
    根据信号类型获取回应的jackpot
]]
function CodeGameScreenDazzlingDiscoMachine:getJakcpotTypeBySymbolType(symbolType)
    if symbolType == self.SYMBOL_SCORE_MINI then
        return "mini"
    elseif symbolType == self.SYMBOL_SCORE_MINOR then
        return "minor"
    elseif symbolType == self.SYMBOL_SCORE_MAJOR then
        return "major"
    elseif symbolType == self.SYMBOL_SCORE_MEGA then
        return "mega"
    elseif symbolType == self.SYMBOL_SCORE_GRAND then
        return "grand"
    end

    return ""
end

--新滚动使用
function CodeGameScreenDazzlingDiscoMachine:updateReelGridNode(symbolNode)
    if symbolNode and symbolNode.p_symbolType then
        local symbolType = symbolNode.p_symbolType
        if symbolType == self.SYMBOL_SCORE_WILD_2 then --刷新wild信号
            self:updateWildSymbol(symbolNode)
        elseif self:isJackpotSymbol(symbolType) then --刷新jackpot信号
            self:updateJackpotSymbol(symbolNode)
        end
    end
end

--[[
    刷新wild信号
]]
function CodeGameScreenDazzlingDiscoMachine:updateWildSymbol(symbolNode)

end

--[[
    刷新jackpot信号
]]
function CodeGameScreenDazzlingDiscoMachine:updateJackpotSymbol(symbolNode)
    local symbolType = symbolNode.p_symbolType

    local skinName = self:getJakcpotTypeBySymbolType(symbolType)
    if skinName ~= "" then
        local aniNode = symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        spine:setSkin(skinName)
    end
end

function CodeGameScreenDazzlingDiscoMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    -- if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
    --     isNotifyUpdateTop = false
    -- end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenDazzlingDiscoMachine:showLineFrame()
    CodeGameScreenDazzlingDiscoMachine.super.showLineFrame(self)
    self:runCsbAction("actionframe")
end

---
-- 显示所有的连线框
--
function CodeGameScreenDazzlingDiscoMachine:showAllFrame(winLines)
    
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenDazzlingDiscoMachine:showLineFrameByIndex(winLines, frameIndex)

    self:showEachLineSlotNodeLineAnim(frameIndex)
end

function CodeGameScreenDazzlingDiscoMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        if lineNode ~= nil then
            self.m_lineSlotNodes[lineNodeIndex] = nil
            local nZOrder = lineNode.p_showOrder

            local colIndex = lineNode.p_cloumnIndex
            --将小块放回原层级
            self.m_baseReelNodes[colIndex]:putSymbolBackToRollNode(lineNode.p_rowIndex,lineNode,nZOrder)

            if lineNode and lineNode.p_symbolType and lineNode.p_symbolType == self.SYMBOL_SCORE_WILD_2 then
                lineNode:runAnim("idleframe2",true)
            elseif lineNode and lineNode.p_symbolType then
                lineNode:runIdleAnim()
            end
            
        end
    end
end

--[[
    检测播放落地动画
]]
function CodeGameScreenDazzlingDiscoMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            --特殊wild在两边出现时不播落地
            if symbolNode.p_symbolType == self.SYMBOL_SCORE_WILD_2  then
                if iRow ~= 3 or colIndex ~= 2 then
                    return
                end
            end

            --记录落地的bonus图标
            if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                self.m_bonusSymbols[#self.m_bonusSymbols + 1] = symbolNode
            end

            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                --提层
                if symbolCfg[1] then
                    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    symbolNode:setPositionY(curPos.y)
                end
                --播放爆点动画
                if symbolNode.p_symbolType == self.SYMBOL_SCORE_WILD_2 then
                    local isTriggerFree = self:checkTriggerFree()
                    
                    if isTriggerFree then
                        --轮盘灯
                        self:runCsbAction("actionframe")
                        self.m_wildSymbol = symbolNode
                        local ani = util_createAnimation("DazzlingDisco_baodian.csb")
                        self:findChild("baodian"):addChild(ani)
                        ani:runCsbAction("actionframe",false,function(  )
                            ani:removeFromParent()
                            
                        end)
                        --显示光效
                        self:setFreeLightShow(true)
                        self:changeBgAni("jackpotReel")

                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_wild_down)
                    end
                    
                end

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

--[[
    判断是否为bonus小块(需要在子类重写)
]]
function CodeGameScreenDazzlingDiscoMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return true
    end
    
    return false
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenDazzlingDiscoMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_bonus_down)
end

function CodeGameScreenDazzlingDiscoMachine:symbolBulingEndCallBack(_slotNode)
    if self.m_wildSymbol then
        self:putSymbolBackToPreParent(self.m_wildSymbol)
        self.m_wildSymbol:runAnim("idleframe2",true)
    end
end

--[[
    检测是否触发free玩法
]]
function CodeGameScreenDazzlingDiscoMachine:checkTriggerFree()
    local features = self.m_runSpinResultData.p_features
    if not features then
        return false 
    end

    for i,featureID in ipairs(features) do
        if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
            return true
        end
    end

    return false 
end

function CodeGameScreenDazzlingDiscoMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
        
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
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenDazzlingDiscoMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]

    local reels = self.m_runSpinResultData.p_reels
    local allSpecicalSymbolNum = 0

    if self.m_isTriggerJackpotReels and column >= 2 then
        if reels[3][1] > self.SYMBOL_SCORE_MINI and reels[3][1] == reels[3][2] then
            allSpecicalSymbolNum = 2   
            bRunLong = true
        end
    end
    

    if self.m_isTriggerJackpotReels and bRunLong and column ~= self.m_iReelColumnNum then
        
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--[[
    震动root点
]]
function CodeGameScreenDazzlingDiscoMachine:shakeRootNode( )

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
function CodeGameScreenDazzlingDiscoMachine:resetRootPos()
    local rootNode = self:findChild("root")
    rootNode:stopAllActions()
    rootNode:setPosition(display.center)
end

function CodeGameScreenDazzlingDiscoMachine:scaleMainLayer()
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
    local winSize = cc.Director:getInstance():getWinSize()
    if ratio >= 1812 / 2176 then
        mainScale = 0.78
    elseif ratio < 1812 / 2176 and ratio >= 768 / 1024 then
        mainScale = 0.87
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        mainScale = 0.96
        mainPosY = mainPosY
    elseif ratio < 640 / 960 and ratio > 768 / 1370 then
        mainScale = 1
    elseif ratio >= 768 / 1370 then
        mainScale = 1
    else
        mainScale = 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

--[[
    开启定时器
]]
function CodeGameScreenDazzlingDiscoMachine:startSchedule()
    self.m_scheduleNode:onUpdate(function(dt)

        if globalData.slotRunData.gameRunPause then
            return
        end

        for colIndex,callFunc in pairs(self.m_scheduleCallFuncs) do
            if type(callFunc) == "function" then
                callFunc(dt)
            end
        end
    end)
end

--[[
    注册定时器回调
]]
function CodeGameScreenDazzlingDiscoMachine:registScheduleCallBack(colIndex,func)
    self.m_scheduleCallFuncs[colIndex] = func
end

--[[
    取消定时器回调
]]
function CodeGameScreenDazzlingDiscoMachine:unRegistScheduleCallBack(colIndex)
    self.m_scheduleCallFuncs[colIndex] = nil
end

function CodeGameScreenDazzlingDiscoMachine:reelsDownDelaySetMusicBGVolume()
    if self.m_isTriggerBonus then
        return
    end
    self:removeSoundHandler()

    self.m_soundHandlerId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_soundHandlerId = nil
            local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0

            if self.m_isTriggerBonus then
                self:removeSoundHandler()
                self:setMaxMusicBGVolume()
                return
            end

            self.m_soundGlobalId =
                scheduler.scheduleGlobal(
                function()
                    --播放广告过程中暂停逻辑
                    if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                        return
                    end

                    if self.m_isTriggerBonus then
                        self:removeSoundHandler()
                        self:setMaxMusicBGVolume()
                        return
                    end

                    if volume <= 0 then
                        volume = 0
                    end

                    print("缩小音量 = " .. tostring(volume))
                    gLobalSoundManager:setBackgroundMusicVolume(volume)

                    if volume <= 0 then
                        if self.m_soundGlobalId ~= nil then
                            scheduler.unscheduleGlobal(self.m_soundGlobalId)
                            self.m_soundGlobalId = nil
                        end
                    end

                    volume = volume - 0.04
                end,
                0.1
            )
        end,
        self.m_bgmReelsDownDelayTime,
        "SoundHandlerId"
    )

    self:setReelDownSoundFlag(true)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenDazzlingDiscoMachine:operaEffectOver()
    CodeGameScreenDazzlingDiscoMachine.super.operaEffectOver(self)
    self.m_gameEffects = {}
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenDazzlingDiscoMachine:showEffect_runBigWinLightAni(effectData)
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
function CodeGameScreenDazzlingDiscoMachine:showBigWinLight(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_big_win_light)
    self.m_spine_big_win:setVisible(true)
    util_spinePlay(self.m_spine_big_win,"actionframe_bigwin")
    util_spineEndCallFunc(self.m_spine_big_win,"actionframe_bigwin",function(  )
        self.m_spine_big_win:setVisible(false)
        if type(_func) == "function" then
            _func()
        end
    end)
    

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,self.m_effectNode)

    local lbl_winCoins = util_createAnimation("DazzlingDisco_totalwinshuzi.csb")
    self.m_effectNode:addChild(lbl_winCoins)
    lbl_winCoins:setPosition(cc.p(pos.x,pos.y))
    lbl_winCoins:runCsbAction("actionframe",false,function()
        lbl_winCoins:removeFromParent()
    end)

    local winCoins = self.m_runSpinResultData.p_winAmount

    self:jumpCoins({
        label = lbl_winCoins:findChild("m_lb_coins"),
        startCoins = 0,
        endCoins = winCoins,
        maxWidth = 1100,
        lblScale = 0.5,
        endFunc = function()
            self:delayCallBack(0.5,function()
                
            end)
            
        end
    })
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenDazzlingDiscoMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_BIGWIN - 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

return CodeGameScreenDazzlingDiscoMachine






