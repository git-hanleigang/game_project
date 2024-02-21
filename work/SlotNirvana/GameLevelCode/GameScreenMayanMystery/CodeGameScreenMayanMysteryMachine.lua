---
-- island li
-- 2019年1月26日
-- CodeGameScreenMayanMysteryMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "MayanMysteryPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenMayanMysteryMachine = class("CodeGameScreenMayanMysteryMachine", BaseNewReelMachine)

CodeGameScreenMayanMysteryMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
    --
CodeGameScreenMayanMysteryMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94
CodeGameScreenMayanMysteryMachine.SYMBOL_WILD_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE -- 93
CodeGameScreenMayanMysteryMachine.SYMBOL_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7 -- 100

-- 自定义动画的标识
CodeGameScreenMayanMysteryMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT + 1
CodeGameScreenMayanMysteryMachine.EFFECT_BONUS_PICK = GameEffect.EFFECT_SELF_EFFECT + 2

-- 构造函数
function CodeGameScreenMayanMysteryMachine:ctor()
    CodeGameScreenMayanMysteryMachine.super.ctor(self)
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0 
    self.m_reSpinCurCount = -1
    self.m_collectOldWildInfo = {} -- 旧的锁定wild信息
    self.m_collectNewWildInfo = {} -- 新滚出来的锁定wild信息
    self.m_curbetWildTime = 2 -- 锁定wild的次数
    self.m_wildDoorStaus = {1, 1} -- 收集区域的状态值
    self.m_isAddBigWinLightEffect = true --大赢光效
    self.m_jackpotIndex = 0 -- jackpot赢钱弹板索引
    self.m_fullColNum = 0 -- respin 满列个数
    self.m_respinMulSpinNumIndex = 1 -- respin获得额外乘倍的次数索引
    self.m_respinColMul = {} -- 存储respin 每列的倍数 可能有一列多次加倍的情况
    self.m_curSpinSymbolList = {} --存储锁定图标 下面的图标
    self.m_isPlayUpdateRespinNums = true --是否播放刷新respin次数
    self.m_collectJinBiIndexList = {
        {1, 2, 3, 4, 5},
        {5, 3, 2, 1, 4},
        {3, 2, 4, 5, 1},
    } --收集金币索引

    self.m_spinRestMusicBG = true
    self.m_isFirstComeIn = true -- 第一次进入关卡
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    self.m_isPlayWildResetEnd = true -- wild重置动画是否播放完
    self.m_isFirstPlayWildResetEffect = true --是否第一次播放wild重置动画
    self.m_publicConfig = PublicConfig
 
    --init
    self:initGame()
end

function CodeGameScreenMayanMysteryMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("MayanMysteryConfig.csv", "LevelMayanMysteryConfig.lua") 

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMayanMysteryMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MayanMystery"  
end

--小块
function CodeGameScreenMayanMysteryMachine:getBaseReelGridNode()
    return "CodeMayanMysterySrc.MayanMysterySlotNode"
end

function CodeGameScreenMayanMysteryMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    
    --多福多彩1
    self.m_colorfulGameView = util_createView("CodeMayanMysterySrc.MayanMysteryColorfulGame",{machine = self})
    self:findChild("root"):addChild(self.m_colorfulGameView, 1)
    self.m_colorfulGameView:setVisible(false) 

    --多福多彩
    self.m_bonusGameView = util_createView("CodeMayanMysterySrc.MayanMysteryBonusView",{machine = self})
    self:findChild("root"):addChild(self.m_bonusGameView, 2)
    self.m_bonusGameView:setVisible(false) 

    self.m_suodingNode = self:findChild("Node_suoding")

    --tips框
    self.m_baseTipsNode = util_createAnimation("MayanMystery_base_wenan.csb")
    self:findChild("Node_base_wenan"):addChild(self.m_baseTipsNode)

    -- 大赢
    self.m_bigwinEffect = util_spineCreate("MayanMystery_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect)
    self.m_bigwinEffect:setVisible(false)

    -- 预告动画
    self.m_yugaoEffectSpine = util_spineCreate("MayanMystery_bigwin", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoEffectSpine)
    self.m_yugaoEffectSpine:setVisible(false)

    self.m_yugaoRoleSpine = util_spineCreate("MayanMystery_juese", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoRoleSpine)
    self.m_yugaoRoleSpine:setVisible(false)

    -- 多福多彩回base 过场
    self.m_colorFulGuoChang = util_spineCreate("MayanMystery_dfdc_guochang", true, true)
    self:findChild("root"):addChild(self.m_colorFulGuoChang, 3)
    self.m_colorFulGuoChang:setVisible(false)

    self:createTwoDoor()
    self:initJackPotBarView()
    self:createRespinView()
    self:setReelBg(1)
    self:addColorLayer()
end

--[[
    每列添加滚动遮罩
]]
function CodeGameScreenMayanMysteryMachine:addColorLayer()
    self.m_colorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        --单列卷轴尺寸
        local reel = self:findChild("sp_reel_"..i-1)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        --棋盘尺寸
        local offsetSize = cc.size(4.5, 4.5)
        reelSize.width = reelSize.width * scaleX + offsetSize.width
        reelSize.height = reelSize.height * scaleY + offsetSize.height
        --遮罩尺寸和坐标
        local clipParent = self.m_onceClipNode or self.m_clipParent
        local panelOrder = 10000--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(0)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        self.m_colorLayers[i] = panel
    end
end

function CodeGameScreenMayanMysteryMachine:scaleMainLayer()
    self.super.scaleMainLayer(self)

    if display.width/display.height <= 920/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.93)
        self.m_machineRootScale = self.m_machineRootScale * 0.93
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 30 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width/display.height <= 1152/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.93)
        self.m_machineRootScale = self.m_machineRootScale * 0.93
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 20 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width/display.height <= 1228/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.93)
        self.m_machineRootScale = self.m_machineRootScale * 0.93
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 15 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    end
        
end

--[[
    显示滚动遮罩
]]
function CodeGameScreenMayanMysteryMachine:showColorLayer()
    for index, maskNode in ipairs(self.m_colorLayers) do
        maskNode:setVisible(true)
        maskNode:setOpacity(0)
        maskNode:runAction(cc.FadeTo:create(0.3, 120))
    end
end

--[[
    列滚动停止 渐隐
]]
function CodeGameScreenMayanMysteryMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    local fadeAct = cc.FadeTo:create(0.1, 0)
    local func = cc.CallFunc:create( function()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2respin
]]
function CodeGameScreenMayanMysteryMachine:setReelBg(_BgIndex)
    if _BgIndex == 1 then
        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("respin_bg"):setVisible(false)
        self:findChild("qp"):setVisible(true)
        self:findChild("Node_respin"):setVisible(false)
    elseif _BgIndex == 2 then
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("respin_bg"):setVisible(true)
        self:findChild("qp"):setVisible(false)
        self:findChild("Node_respin"):setVisible(true)
        self.m_respinRoll:run()
    end
end

--[[
    创建两个收集的门
]]
function CodeGameScreenMayanMysteryMachine:createTwoDoor()
    -- 两个门
    self.m_doorSpine = {}
    self.m_leafSpine = {}

    -- 红色门
    self.m_doorSpine[1] = util_spineCreate("MayanMystery_base_dfdc",true,true)
    self:findChild("Node_dfdc1"):addChild(self.m_doorSpine[1])
    self.m_doorSpine[1]:setSkin("hong")

    -- 树叶
    self.m_leafSpine[1] = util_spineCreate("MayanMystery_base_dfdc_shuye",true,true)
    self:findChild("Node_dfdc1_shuye"):addChild(self.m_leafSpine[1])

    -- 蓝色门
    self.m_doorSpine[2] = util_spineCreate("MayanMystery_base_dfdc",true,true)
    self:findChild("Node_dfdc2"):addChild(self.m_doorSpine[2])
    self.m_doorSpine[2]:setSkin("lan")

    -- 树叶
    self.m_leafSpine[2] = util_spineCreate("MayanMystery_base_dfdc_shuye",true,true)
    self:findChild("Node_dfdc2_shuye"):addChild(self.m_leafSpine[2])
end

function CodeGameScreenMayanMysteryMachine:createRespinView( )
    -- respin界面
    self.m_respinNodeView = util_createAnimation("MayanMystery_respin_screen.csb")
    self:findChild("Node_respin"):addChild(self.m_respinNodeView)

    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_respinNodeView:findChild("touchSpin"))
    end

    --respinBar
    self.m_respinbar = util_createView("CodeMayanMysterySrc.Respin.MayanMysteryRespinBar")
    self.m_respinNodeView:findChild("Node_spins_bar"):addChild(self.m_respinbar)

    --respinMulBar
    self.m_respinMulBar = util_createView("CodeMayanMysterySrc.Respin.MayanMysteryRespinMulBar")
    self.m_respinNodeView:findChild("Node_mul_bar"):addChild(self.m_respinMulBar)

    --respinJackPotBarView
    self.m_respinJackPotBarView = util_createView("CodeMayanMysterySrc.Respin.MayanMysteryRespinJackPotBarView")
    self.m_respinJackPotBarView:initMachine(self)
    self.m_respinNodeView:findChild("Node_epic"):addChild(self.m_respinJackPotBarView)

    --respinWenan
    -- self.m_respinWenanView = util_createView("CodeMayanMysterySrc.Respin.MayanMysteryRespinWenAnView")
    -- self.m_respinNodeView:findChild("Node_wenan"):addChild(self.m_respinWenanView)

    -- 集满效果
    self.m_respinJiMan = util_createAnimation("MayanMystery_Bonus_jiman_tx.csb")
    self.m_respinNodeView:findChild("Node_jiman"):addChild(self.m_respinJiMan)
    self.m_respinJiMan:setVisible(false)
end

--[[
    respin 每列添加滚动遮罩
]]
function CodeGameScreenMayanMysteryMachine:addRespinColorLayer()
    self.m_respinColorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        --单列卷轴尺寸
        local reel = self.m_respinNodeView:findChild("sp_reel_"..i-1)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        --棋盘尺寸
        local offsetSize = cc.size(4.5, 4.5)
        reelSize.width = reelSize.width * scaleX + offsetSize.width
        reelSize.height = reelSize.height * scaleY + offsetSize.height
        --遮罩尺寸和坐标
        local clipParent = self.m_respinView
        local panelOrder = 3--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(0)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        self.m_respinColorLayers[i] = panel
    end
end

function CodeGameScreenMayanMysteryMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_Enter_Game)
    end)
end

function CodeGameScreenMayanMysteryMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    
    self.m_isFirstComeIn = true

    local data = clone(self:getBaseSpinbetDataByTotalBet())
    self:updateBoxStatus(1, "idle", true, data)
    self:updateBoxStatus(2, "idle", true, data)

    CodeGameScreenMayanMysteryMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:createNewLockWild(self:getWildTimeLine(3, self.m_curbetWildTime), true)
end

function CodeGameScreenMayanMysteryMachine:addObservers()
    CodeGameScreenMayanMysteryMachine.super.addObservers(self)
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
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundName = self.m_publicConfig.SoundConfig["sound_MayanMystery_winLines" .. soundIndex]
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        local totalBet = globalData.slotRunData:getCurTotalBet( )
        if self.m_curbetTotalCoins ~= totalBet then
            self.m_curbetTotalCoins = totalBet
            self.m_curbetWildTime = self:getBaseSpinbetDataByTotalBet().fixedWildTimes or 2
            self.m_wildDoorStaus = self:getBaseSpinbetDataByTotalBet().wildStatus or {1,1}
    
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            self:clearWinLineEffect()
            
            self.m_effectNode:stopAllActions()
            self.m_effectNode:removeAllChildren(true)
            self:changeBetCallBack()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

--[[
    把棋盘上的wild 图标 变成普通图标
]]
function CodeGameScreenMayanMysteryMachine:changeWildToCommonSymbol( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and (symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolNode.p_symbolType == self.SYMBOL_WILD_2) then
                local randomType = math.random(0, 7)
                self:changeSymbolType(symbolNode, randomType)
            end
        end
    end
end

--[[
    切换bet 刷新
]]
function CodeGameScreenMayanMysteryMachine:changeBetCallBack()
    self:showSymbolByWild()

    local child = self.m_suodingNode:getChildren()
    if #child > 0 then
        self.m_suodingNode:removeAllChildren(true)
    end
    self.m_suodingNode:setVisible(true)

    if not self.m_isFirstComeIn then
        self:changeWildToCommonSymbol()
    end

    local data = clone(self:getBaseSpinbetDataByTotalBet())
    self:updateBoxStatus(1, "idle", false, data)
    self:updateBoxStatus(2, "idle", false, data)
    
    self.m_collectNewWildInfo = {}
    local fixedWild = self:getBaseSpinbetDataByTotalBet().fixedWild or {}
    if table.nums(fixedWild) > 0 then
        for _wildPos, _wildType in pairs(fixedWild) do
            local wildInfo = {tonumber(_wildPos), _wildType}
            table.insert(self.m_collectNewWildInfo, wildInfo)
        end
    end
    self:createNewLockWild(self:getWildTimeLine(3, self.m_curbetWildTime))

end

function CodeGameScreenMayanMysteryMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMayanMysteryMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenMayanMysteryMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:changeReelsWildByRespin()
    self:initCloumnSlotNodesByNetData()
end

--[[
    触发respin 断线进来 判断修改棋盘
]]
function CodeGameScreenMayanMysteryMachine:changeReelsWildByRespin( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fixedwilds = selfdata.fixedWild or {}
    local features = self.m_runSpinResultData.p_features or {}

    if #features >= 2 and features[2] == 3 then
        if table.nums(fixedwilds) > 0 then
            for _wildpos, _wildType in pairs(fixedwilds) do
                local pos = self:getRowAndColByPos(_wildpos)
                self:changeReelsByRespin(pos.iX, pos.iY, _wildType)
            end
        end
    end
end

--[[
    显示隐藏的图标
]]
function CodeGameScreenMayanMysteryMachine:showSymbolByWild( )
    for _, _symbolNode in ipairs(self.m_curSpinSymbolList) do
        if not tolua.isnull(_symbolNode) then
            _symbolNode:setVisible(true)
        end
    end
    self.m_curSpinSymbolList = {}
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMayanMysteryMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_BONUS  then
        return "Socre_MayanMystery_Link"
    end

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_MayanMystery_Wild1"
    end

    if symbolType == self.SYMBOL_WILD_2 then
        return "Socre_MayanMystery_Wild2"
    end

    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_MayanMystery_Empty"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMayanMysteryMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMayanMysteryMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_2,count =  2}

    return loadNode
end

-- 初始化小块时 规避某个信号接口 （包含随机创建的两个函数，根据网络消息创建的函数）
function CodeGameScreenMayanMysteryMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
    if symbolType == self.SYMBOL_EMPTY then
        return math.random(0, 7)
    end
    return symbolType
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMayanMysteryMachine:MachineRule_initGame()
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMayanMysteryMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenMayanMysteryMachine:slotOneReelDown(reelCol)    
    CodeGameScreenMayanMysteryMachine.super.slotOneReelDown(self,reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenMayanMysteryMachine:slotReelDown( )
    if self.m_curbetWildTime < 0 then
        self.m_curbetWildTime = 2
        local child = self.m_suodingNode:getChildren()
        if #child > 0 then
            self.m_suodingNode:removeAllChildren(true)
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenMayanMysteryMachine.super.slotReelDown(self)
end

---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMayanMysteryMachine:addSelfEffect()

    if self:isTriggerCollectSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_TYPE_COLLECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT 
    end

    if self:isTriggerBonusPick() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_PICK
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_PICK 
    end

end

--[[
    判断是否 触发wild收集相关
]]
function CodeGameScreenMayanMysteryMachine:isTriggerCollectSymbol( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fixedwilds = selfdata.fixedWild or {}
    self.m_collectOldWildInfo = {}
    self.m_collectNewWildInfo = {}
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        if table.nums(fixedwilds) > 0 then
            for _wildpos, _wildType in pairs(fixedwilds) do
                local infoList = {tonumber(_wildpos), _wildType}
                local suodingOldNode = self.m_suodingNode:getChildByName(tostring(_wildpos))
                if suodingOldNode then
                    table.insert(self.m_collectOldWildInfo, infoList)
                else
                    table.insert(self.m_collectNewWildInfo, infoList)
                end
            end
            return true
        end
    end
    return false
end

--[[
    判断是否 触发wild收集相关
]]
function CodeGameScreenMayanMysteryMachine:isTriggerBonusPick( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.jackpot and selfdata.jackpot.process and #selfdata.jackpot.process > 0 then
        return true
    end
    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMayanMysteryMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        self:onUpdate( function( dt )
            if self.m_isPlayWildResetEnd then
                self.m_isPlayWildResetEnd = false
                self:unscheduleUpdate()

                local delayTime = 0
                if self:getIsHaveWild() and #self.m_collectOldWildInfo <= 0 then
                    delayTime = 0.5
                end
                self:delayCallBack(delayTime, function()
                    self:collecWildffect(function()
                        if self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
                            self:showSymbolByWild()
                            -- 动画都走完了 隐藏锁定的wild
                            self.m_suodingNode:setVisible(false)
                        end
                        -- 记得完成所有动画后调用这两行
                        -- 作用：标识这个动画播放完结，继续播放下一个动画
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                end)
            end
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_PICK then
        self:playEffect_bonusGame(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

--[[
    判断棋盘上是否有新滚出来的wild
]]
function CodeGameScreenMayanMysteryMachine:getIsHaveWild( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and (symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolNode.p_symbolType == self.SYMBOL_WILD_2) then
                return true
            end
        end
    end
    return false
end

--[[
    收集wild
]]
function CodeGameScreenMayanMysteryMachine:collecWildffect(_func)
    self:createNewLockWild()

    self:playChangeWildEffect(function()
        self:wildCollectFlyEffect(_func)
    end)
end

function CodeGameScreenMayanMysteryMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _slotNode.p_symbolType == self.SYMBOL_WILD_2 then
        if self.m_isFirstPlayWildResetEffect then
            self.m_isFirstPlayWildResetEffect = false
            self:playWildResetEffect()
        end
        _slotNode:runAnim("idleframe3", true)
    elseif _slotNode.p_symbolType == self.SYMBOL_BONUS then
        _slotNode:runAnim("idleframe1", true)
    end
end

--[[
    触发respin的时候 棋盘上有wild 修改reels信息
]]
function CodeGameScreenMayanMysteryMachine:changeReelsByRespin(_row, _col, _symbolType)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local features = self.m_runSpinResultData.p_features or {}

    if #features >= 2 and features[2] == 3 then
        local row = 2
        if _row == 1 then
            row = 3
        elseif _row == 3 then
            row = 1
        end
        self.m_runSpinResultData.p_reels[row][_col] = _symbolType
    end
end

--[[
    锁定wild位置 棋盘上的图标 变成wild
]]
function CodeGameScreenMayanMysteryMachine:playChangeWildEffect(_func)
    local changeSymbol = function()
        local data = self:getBaseSpinbetDataByTotalBet()

        for _index, _wildInfo in ipairs(self.m_collectOldWildInfo) do
            local wildPos = _wildInfo[1]
            local wildType = _wildInfo[2]
            local pos = self:getRowAndColByPos(wildPos)
            -- 棋盘滚出来的图标 变成wild
            local symbolNode = self:getFixSymbol(pos.iY, pos.iX, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType then
                self:changeSymbolType(symbolNode, wildType)
                local zOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
                symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex
                
                local lineName = self:getWildTimeLine(3, data.fixedWildTimes)
                symbolNode:runAnim(lineName, true)
                util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)

                local linePos = {}
                linePos[#linePos + 1] = {iX = symbolNode.p_rowIndex, iY = symbolNode.p_cloumnIndex }
                symbolNode:setLinePos(linePos)

                self:changeReelsByRespin(pos.iX, pos.iY, wildType)

                symbolNode:setVisible(false)
                table.insert(self.m_curSpinSymbolList, symbolNode)
            end
        end
    end

    changeSymbol()
    if _func then
        _func()
    end
end

--[[
    旧的wild 播放重置动画
]]
function CodeGameScreenMayanMysteryMachine:playWildResetEffect()
    if #self.m_collectOldWildInfo > 0 and #self.m_collectNewWildInfo > 0 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_wild_reset)
        
        for _index, _wildInfo in ipairs(self.m_collectOldWildInfo) do
            local wildPos = _wildInfo[1]
            local resetActionFrameName = self:getWildTimeLine(6, self.m_curbetWildTime)

            -- 棋盘上锁定的wild
            local suodingOldNode = self.m_suodingNode:getChildByName(tostring(wildPos))
            util_spinePlay(suodingOldNode, resetActionFrameName, false)
            if _index == 1 then
                self:delayCallBack(30/30, function()
                    self.m_isPlayWildResetEnd = true
                end)
            end
        end
    else
        self.m_isPlayWildResetEnd = true
    end
end

--[[
    创建新的锁定wild
]]
function CodeGameScreenMayanMysteryMachine:createNewLockWild(_idlefrmae, _isComeIn)
    for _index, _wildInfo in ipairs(self.m_collectNewWildInfo) do
        local wildPos = _wildInfo[1]
        local wildType = _wildInfo[2]
        local fixPos = self:getRowAndColByPos(wildPos)
        local slotsNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if slotsNode and slotsNode.p_symbolType then
            local newWildSpine = util_spineCreate(self:getSymbolCCBNameByType(self, wildType), true, true)
            self.m_suodingNode:addChild(newWildSpine, tonumber(wildPos))
            newWildSpine:setName(tostring(wildPos))
            if _idlefrmae then
                util_spinePlay(newWildSpine, _idlefrmae, true)
            else
                util_spinePlay(newWildSpine, "idleframe3", true)
            end
            newWildSpine:setPosition(util_convertToNodeSpace(slotsNode, self.m_suodingNode))

            -- 进入关卡判断是否 需要修改 触发respin的 reels
            if _isComeIn then
                self:changeReelsByRespin(fixPos.iX, fixPos.iY, wildType)
            end

            slotsNode:setVisible(false)
            table.insert(self.m_curSpinSymbolList, slotsNode)
        end
    end
end

--[[
    收集wild动画
]]
function CodeGameScreenMayanMysteryMachine:wildCollectFlyEffect(_func)
    local data = clone(self:getBaseSpinbetDataByTotalBet())
    local isTrigger = self:isTriggerBonus()
    local fixedwilds = data.fixedWild or {}
    local isFirst = true
    if table.nums(fixedwilds) > 0 then
        for _wildPos, _wildType in pairs(fixedwilds) do
            local wildPos = _wildPos
            local suodingOldNode = self.m_suodingNode:getChildByName(tostring(wildPos))
            if suodingOldNode then
                local actionFrameName = self:getWildTimeLine(4, data.fixedWildTimes)
                local idleFrameName = self:getWildTimeLine(3, data.fixedWildTimes)

                util_spinePlay(suodingOldNode, actionFrameName, false)
                util_spineEndCallFunc(suodingOldNode, actionFrameName, function()
                    util_spinePlay(suodingOldNode, idleFrameName, true)
                end)

                self:wildFlyEffect(suodingOldNode, _wildType, function()
                    if isFirst then
                        isFirst = false
                        local doorType = _wildType == TAG_SYMBOL_TYPE.SYMBOL_WILD and 1 or 2
                        self:updateBoxStatus(doorType, "fankui", false, data, isTrigger)
                    end
                end)
            end
        end
    end
    self:delayCallBack(10/30, function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_wild_collect)
    end)

    local delayTime = 0
    if self:getIsTriggerFeature() then --收集的时候 触发了其他玩法 等收集反馈播完
        delayTime = delayTime + 35/30 + 20/30
    end
    self:delayCallBack(delayTime, function()
        if _func then
            _func()
        end
    end)
end

--[[
    wild飞
]]
function CodeGameScreenMayanMysteryMachine:wildFlyEffect(_startNode, _wildType, _func)
    local startPos = util_convertToNodeSpace(_startNode, self.m_effectNode)
    local endPos = cc.p(0, 0)
    if _wildType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        endPos = util_convertToNodeSpace(self:findChild("Node_dfdc1"), self.m_effectNode)
    elseif _wildType == self.SYMBOL_WILD_2 then
        endPos = util_convertToNodeSpace(self:findChild("Node_dfdc2"), self.m_effectNode)
    end
    endPos.y = endPos.y + 70

    local flyNode = cc.Node:create()
    self.m_effectNode:addChild(flyNode)
    flyNode:setScale(self.m_machineRootScale)
    flyNode:setPosition(startPos)

    local delayTime = 10/30
    local flyTime  = 15/30
    flyNode.m_coinsSpine = {}
    flyNode.m_coinsIndex = {}
    local isChangeIndex = math.random(1, 3)
    for index = 1, 5 do
        local jinBiIndex = self.m_collectJinBiIndexList[isChangeIndex][index]
        flyNode.m_coinsSpine[jinBiIndex] = util_spineCreate("Socre_MayanMystery_Wild_jinbi", true, true)
        flyNode:addChild(flyNode.m_coinsSpine[jinBiIndex])
        
        local delayTimeFly = (index - 1) * (2 / 30)
        self:delayCallBack(delayTimeFly, function()
            if not tolua.isnull(flyNode) then
                util_spinePlay(flyNode.m_coinsSpine[jinBiIndex], "shouji"..jinBiIndex, false)
            end
        end)
    end

    flyNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(delayTime),
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))

    performWithDelay(self.m_effectNode, function()
        if _func then
            _func()
        end
    end, delayTime+flyTime)
end

--[[
    开始多福多彩2
]]
function CodeGameScreenMayanMysteryMachine:playEffect_bonusGame(_func)
    -- 播放罐子的触发动画
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "pickFeature")
    end

    self:playTriggerEffectByBonus(2, function()
        self:playGuoChangColorFul(function()
            self:resetMusicBg(nil, "MayanMysterySounds/music_MayanMystery_colorFul.mp3")
            self:setMaxMusicBGVolume()

            self.m_bonusGameView:setVisible(true)
            self.m_bonusGameView:startGame(self.m_runSpinResultData, function()
                self:showJackpotView(self.m_runSpinResultData, function()
                    self:playGuoChangToBaseColorFul(function()
                        self.m_bonusGameView:setVisible(false)
                    end, function()
                        self:removeGameEffectType(GameEffect.EFFECT_BIG_WIN_LIGHT)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

                        if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
                            local params = {self.m_serverWinCoins, false, false}
                            params[self.m_stopUpdateCoinsSoundIndex] = true
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                        end

                        self:resetMusicBg()
                        self:checkTriggerOrInSpecialGame(function(  )
                            self:reelsDownDelaySetMusicBGVolume( ) 
                        end)

                        if _func then
                            _func()
                        end
                    end)
                end)
            end)
        end, false)
    end)
end

--[[
    触发玩法时 播放罐子和人物的触发
]]
function CodeGameScreenMayanMysteryMachine:playTriggerEffectByBonus(_type, _func)
    self:clearCurMusicBg()

    self:clearWinLineEffect()
    self:stopLinesWinSound()

    local data = self:getBaseSpinbetDataByTotalBet()
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and (symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolNode.p_symbolType == self.SYMBOL_WILD_2) then
                local lineName = self:getWildTimeLine(3, data.fixedWildTimes)
                symbolNode:runAnim(lineName, true)
            end
        end
    end

    --修改收集 门 父节点 提升层级
    util_changeNodeParent(self:findChild("Node_collect".._type), self.m_doorSpine[_type])
    if _type == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_colorFul_trigger)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_bonusGame_trigger)
    end

    util_spinePlay(self.m_doorSpine[_type], "actionframe", false)
    util_spinePlay(self.m_leafSpine[_type], "actionframe", false)
    util_spineEndCallFunc(self.m_doorSpine[_type], "actionframe", function()
        util_changeNodeParent(self:findChild("Node_dfdc".._type), self.m_doorSpine[_type])
        self:delayCallBack(0.5, function()
            local data = clone(self:getBaseSpinbetDataByTotalBet())
            self:updateBoxStatus(_type, "idle", false, data)
        end)
    end)
    
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:delayCallBack(3, function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenMayanMysteryMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMayanMysteryMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenMayanMysteryMachine:beginReel( )
    self.m_featureDataClone = nil
    self.m_jackpotIndex = 0
    self.m_fullColNum = 0
    self.m_respinMulSpinNumIndex = 1
    self.m_isPlayWildResetEnd = true
    self.m_isFirstPlayWildResetEffect = true
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        if not self.m_isFirstComeIn then
            self:changeWildToCommonSymbol()
        end

        self:showSymbolByWild()

        -- 开始spin的时候 显示锁定的wild
        self.m_suodingNode:setVisible(true)

        local data = self:getBaseSpinbetDataByTotalBet()
        if table.nums(data.fixedWild) > 0 then
            self.m_curbetWildTime = data.fixedWildTimes - 1
            if self.m_curbetWildTime > -1 then
                self:updateWildCount(self.m_curbetWildTime)
            end
        end
    end
    self.m_isFirstComeIn = false
    self:showColorLayer()

    CodeGameScreenMayanMysteryMachine.super.beginReel(self)
end

--重写列停止
function CodeGameScreenMayanMysteryMachine:reelSchedulerCheckColumnReelDown(parentData)
    local  slotParent = parentData.slotParent
    if parentData.isDone ~= true then
        parentData.isDone = true
        slotParent:stopAllActions()
        local slotParentBig = parentData.slotParentBig 
        if slotParentBig then
            slotParentBig:stopAllActions()
        end
        self:slotOneReelDown(parentData.cloumnIndex)
        local speedActionTable = nil
        local addTime = nil
        local quickStopY = -35 --快停回弹距离
        if self.m_quickStopBackDistance then
            quickStopY = -self.m_quickStopBackDistance
        end
        -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
        if self.m_isNewReelQuickStop then
            slotParent:setPositionY(quickStopY)
            if slotParentBig then
                slotParentBig:setPositionY(quickStopY)
            end
            speedActionTable = {}
            speedActionTable[1], addTime = self:MachineRule_BackAction(slotParent, parentData)
        else
            speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
        end
        if slotParentBig then
            local seq = cc.Sequence:create(speedActionTable)
            slotParentBig:runAction(seq:clone())
        end
        local tipSlotNoes = nil
        local nodeParent = parentData.slotParent
        local nodes = nodeParent:getChildren()
        if slotParentBig then
            local nodesBig = slotParentBig:getChildren()
            for i=1,#nodesBig do
                nodes[#nodes+1]=nodesBig[i]
            end
        end

        -- 播放配置信号的落地音效
        self:playSymbolBulingSound(nodes)
        -- 播放配置信号的落地动效
        self:playSymbolBulingAnim(nodes, speedActionTable)

        --添加提示节点
        tipSlotNoes = self:addReelDownTipNode(nodes)
 
        if tipSlotNoes ~= nil then
            local nodeParent = parentData.slotParent
            for i = 1, #tipSlotNoes do
                --播放提示动画
                self:playReelDownTipNode(tipSlotNoes[i])
            end -- end for
        end

        self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

        local actionFinishCallFunc = cc.CallFunc:create(
        function()
            parentData.isResActionDone = true
            if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                self:newQuickStopReel(self.m_quickStopReelIndex)
            end
            self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
        end)

        
        speedActionTable[#speedActionTable + 1] = actionFinishCallFunc
        slotParent:runAction(cc.Sequence:create(speedActionTable))

        self:reelStopHideMask(parentData.cloumnIndex)
    end
    return 0.1
end

--[[
    更新锁定wild的次数
]]
function CodeGameScreenMayanMysteryMachine:updateWildCount(_wildTimes, _func)
    local data = self:getBaseSpinbetDataByTotalBet()
    if(not _wildTimes)then
        _wildTimes = data.fixedWildTimes or 0
    end
  
    local timelineType = 5
    local actionFrameName = self:getWildTimeLine(timelineType, _wildTimes)
    local idleFrameName = self:getWildTimeLine(3, _wildTimes)

    if table.nums(data.fixedWild) > 0 then
        local isFirst = true
        for _wildPos, _wildType in pairs(data.fixedWild) do
            local suodingOldNode = self.m_suodingNode:getChildByName(tostring(_wildPos))
            if suodingOldNode then
                util_spinePlay(suodingOldNode, actionFrameName, false)
                util_spineEndCallFunc(suodingOldNode, actionFrameName, function()
                    if isFirst then
                        isFirst = false
                        if _func then
                            _func()
                        end
                        if actionFrameName == "switch3" then
                            self:delayCallBack(0.1, function()
                                local child = self.m_suodingNode:getChildren()
                                if #child > 0 then
                                    self.m_suodingNode:removeAllChildren(true)
                                end
                            end)
                        end
                    end

                    if actionFrameName ~= "switch3" then
                        util_spinePlay(suodingOldNode, idleFrameName, true)
                    end
                end)
            else
                if isFirst then
                    isFirst = false
                    if _func then
                        _func()
                    end
                end
            end
        end
    else
        if _func then
            _func()
        end
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenMayanMysteryMachine:initGameStatusData(_gamedata)
    
    CodeGameScreenMayanMysteryMachine.super.initGameStatusData(self, _gamedata)

    self.m_featureDataClone = clone(self.m_initFeatureData)
    local gf = _gamedata.gameConfig

    if(gf and gf.extra and gf.extra.bet)then
        self.m_stBaseSpinbet = gf.extra.bet
    end

    local betid = (_gamedata.betId or -1)
    if(betid > 0)then
        local betcion = 0
        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
        for _,v in ipairs(betList) do
            if(v.p_betId == betid)then
                betcion = v.p_totalBetValue
            end
        end
        self.m_curbetTotalCoins = betcion

        if self.m_stBaseSpinbet then
            if self.m_stBaseSpinbet[tostring(betcion)] then
                if #self.m_runSpinResultData.p_features > 1 and self.m_runSpinResultData.p_features[2] == 3 then
                    self.m_stBaseSpinbet[tostring(betcion)].fixedWildTimes = self.m_runSpinResultData.p_selfMakeData.oldfixed_wild_times or 0
                end
                self.m_curbetWildTime = self.m_stBaseSpinbet[tostring(betcion)].fixedWildTimes
                local fixedWild = self.m_stBaseSpinbet[tostring(betcion)].fixedWild
                if table.nums(fixedWild) > 0 then
                    for _wildPos, _wildType in pairs(fixedWild) do
                        local wildInfo = {tonumber(_wildPos), _wildType}
                        table.insert(self.m_collectNewWildInfo, wildInfo)
                    end
                end
                self.m_wildDoorStaus = self.m_stBaseSpinbet[tostring(betcion)].wildStatus
            end
        end
    end
end

--[[
    更新两个收集门的状态
    _doorType 表示两个门 红色为1 蓝色为2
    _lineStatus 表示播放那种时间线 idle fankui
]]
function CodeGameScreenMayanMysteryMachine:updateBoxStatus(_doorType, _lineStatus, _isComein, _data, _isTrigger)
    if _data and _data.wildStatus then
        local status = _data.wildStatus[_doorType]
        if _lineStatus == "idle" then
            if _isComein  then
                status = self.m_wildDoorStaus[_doorType]
            end
            if _isTrigger then
                status = 3
            end
            util_spinePlay(self.m_doorSpine[_doorType], "idle"..status, true)
            util_spinePlay(self.m_leafSpine[_doorType], "idle"..status, true)
        elseif _lineStatus == "fankui" then
            local switchName = "actionframe_fankui"..self.m_wildDoorStaus[_doorType]
            -- 表示门的状态发生变化
            if self.m_wildDoorStaus[_doorType] ~= status or _isTrigger then
                --修改收集 门 父节点 提升层级
                util_changeNodeParent(self:findChild("Node_collect".._doorType), self.m_doorSpine[_doorType])

                if _isTrigger then
                    status = 3
                end
                if self.m_wildDoorStaus[_doorType] ~= 3 then
                    if self.m_wildDoorStaus[_doorType] == 1 and status == 2 then
                        switchName = "switch1"
                    elseif self.m_wildDoorStaus[_doorType] == 1 and status == 3 then
                        switchName = "switch2"
                    elseif self.m_wildDoorStaus[_doorType] == 2 and status == 3 then
                        switchName = "switch3"
                    end
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_collect_upgrade)
                end
            else
                switchName = "actionframe_fankui"..status
            end
            -- 重新赋值
            self.m_wildDoorStaus = _data.wildStatus
            local doorType = clone(_doorType)
            local data = clone(_data)
            util_spinePlay(self.m_doorSpine[_doorType], switchName, false)
            util_spinePlay(self.m_leafSpine[_doorType], switchName, false)

            util_spineEndCallFunc(self.m_doorSpine[_doorType], switchName, function()
                util_changeNodeParent(self:findChild("Node_dfdc"..doorType), self.m_doorSpine[doorType])
                self:updateBoxStatus(doorType, "idle", false, data, _isTrigger)
            end)
        end
    end
end

--[[
    是否触发了多福多彩
]]
function CodeGameScreenMayanMysteryMachine:isTriggerBonus( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpot = selfdata.jackpot or {}
    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID
    if #features >= 2 and features[2] == 5 then
        return true
    end

    if jackpot.process and #jackpot.process > 0 then
        return true
    end

    return false
end

--[[
    获取不同bet下wild数据
]]
function CodeGameScreenMayanMysteryMachine:getBaseSpinbetDataByTotalBet(_bettotal)
    if(not _bettotal)then
        _bettotal = globalData.slotRunData:getCurTotalBet( )
    end

    local spindata =  self.m_stBaseSpinbet[tostring(_bettotal)]
    if(not spindata)then
        spindata = { fixedWildTimes = 0,fixedWild = {},wildStatus = {1,1}, newWild = {}}
        self.m_stBaseSpinbet[tostring(_bettotal)] = spindata
    end
    return spindata
end

--[[
    spin之后 存储当前bet下wild数据
]]
function CodeGameScreenMayanMysteryMachine:updateBaseSpinData( )
    local makedata = self.m_runSpinResultData.p_selfMakeData
    if makedata and makedata.fixedWildTimes then
        local data = self:getBaseSpinbetDataByTotalBet()
        data.fixedWildTimes = makedata.fixedWildTimes or 0
        if #self.m_runSpinResultData.p_features > 1 and self.m_runSpinResultData.p_features[2] == 3 then
            data.fixedWildTimes = makedata.oldfixed_wild_times or 0
        end
        data.wildStatus = makedata.wildStatus or {}
  
        data.newWild = {}
        for pos,val in pairs(makedata.fixedWild) do
            if(not data.fixedWild[pos])then
                table.insert(data.newWild, tonumber(pos))
            end
        end
        
        data.fixedWild = makedata.fixedWild or {}
    end
    self:isTriggerCollectSymbol()

    if #self.m_collectOldWildInfo > 0 and #self.m_collectNewWildInfo > 0 then 
        self.m_isPlayWildResetEnd = false
    end
end

-- 不用系统音效
function CodeGameScreenMayanMysteryMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

----------------------------新增接口插入位---------------------------------------------
    -----------------------------respin相关接口------------------------------------------------
-- 继承底层respinView
function CodeGameScreenMayanMysteryMachine:getRespinView()
    return "CodeMayanMysterySrc.Respin.MayanMysteryRespinView"
end
-- 继承底层respinNode
function CodeGameScreenMayanMysteryMachine:getRespinNode()
    return "CodeMayanMysterySrc.Respin.MayanMysteryRespinNode"
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenMayanMysteryMachine:getReSpinSymbolScore(id)
    
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusScore = selfMakeData.bonusScore or {}
    local multi = nil

    for _pos, _multi in pairs(bonusScore) do
        if tonumber(_pos) == id then
            multi = _multi
        end
    end

    if multi == nil then
       return 0
    end

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenMayanMysteryMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local multi = math.random(1, 5)
    score = multi * lineBet

    return score
end

--[[
    刷新小块显示
]]
function CodeGameScreenMayanMysteryMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    elseif node and (symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2) then
        if not self.m_isFirstComeIn then
            node:addTuoWeiSpine()
        end
    end
end

-- 给respin小块进行赋值
function CodeGameScreenMayanMysteryMachine:setSpecialNodeScore(symbolNode, _isMul)
    if tolua.isnull(symbolNode) or not symbolNode.p_symbolType then
        return
    end

    local symbolType = symbolNode.p_symbolType
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local score = 0

    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local coinsView
    if not spineNode.m_csbNode then
        coinsView = util_createAnimation("Socre_MayanMystery_LinkCoins.csb")
        util_spinePushBindNode(spineNode, "shuzi", coinsView)
        spineNode.m_csbNode = coinsView
    else
        spineNode.m_csbNode:setVisible(true)
        coinsView = spineNode.m_csbNode
    end

    if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        local posIndex = self:getPosReelIdx(iRow, iCol)
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(posIndex) --获取分数（网络数据）
        if _isMul then
            score = score * self.m_respinColMul[iCol]
        end
    else
        score =  self:randomDownRespinSymbolScore(symbolType)
    end

    self:changeBonusCoins(symbolNode, score, false)
end

--ReSpin开始改变UI状态
function CodeGameScreenMayanMysteryMachine:changeReSpinStartUI(respinCount)
   self.m_respinbar:setVisible(true)
end

--ReSpin刷新数量
function CodeGameScreenMayanMysteryMachine:changeReSpinUpdateUI(curCount,isInit)
    self.m_respinbar:updateCount(curCount,isInit)
end

--ReSpin结算改变UI状态
function CodeGameScreenMayanMysteryMachine:changeReSpinOverUI()
    self.m_respinbar:setVisible(false)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenMayanMysteryMachine:getRespinRandomTypes( )
    local symbolList = { self.SYMBOL_BONUS, self.SYMBOL_EMPTY,}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenMayanMysteryMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = true},
        {type = TAG_SYMBOL_TYPE.SYMBOL_WILD, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_WILD_2, runEndAnimaName = "buling", bRandom = true},
    }

    return symbolList
end

function CodeGameScreenMayanMysteryMachine:createRespinRoll( )
    --respinRoll
    self.m_respinRoll = util_createView("CodeMayanMysterySrc.Respin.MayanMysteryRespinRoll")
    self.m_respinNodeView:findChild("Node_mul_baoshi"):addChild(self.m_respinRoll)
    self.m_respinRoll:initMachine(self)

    --respinWenan
    self.m_respinPress = nil
    self.m_respinPress = util_createView("CodeMayanMysterySrc.Respin.MayanMysteryRespinPress")
    -- self.m_respinRoll:findChild("Node_press_start"):addChild(self.m_respinPress)
    util_changeNodeParent(self.m_respinView, self.m_respinPress, 310)
    local startPos = util_convertToNodeSpace(self.m_respinRoll:findChild("Node_press_start"), self.m_respinView)
    self.m_respinPress:setPosition(startPos)
end

--[[
    respin触发动画
]]
function CodeGameScreenMayanMysteryMachine:triggerRespinAni(func)
    local delayTime = 0
    local data = self:getBaseSpinbetDataByTotalBet()
    
    self:showSymbolByWild()
    -- 动画都走完了 隐藏锁定的wild
    self.m_suodingNode:setVisible(false)

    --触发动画
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
            util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
            symbolNode:runAnim("actionframe", false, function()
                symbolNode:runAnim("idleframe1", true)
            end)
            local aniTime = symbolNode:getAniamDurationByName("actionframe")
            if delayTime < aniTime then
                delayTime = aniTime
            end
        end
        if not tolua.isnull(symbolNode) and (symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolNode.p_symbolType == self.SYMBOL_WILD_2) then
            local lineName = self:getWildTimeLine(8, data.fixedWildTimes)
            local idleName = self:getWildTimeLine(3, data.fixedWildTimes)
            util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
            symbolNode:runAnim(lineName, false, function()
                symbolNode:runAnim(idleName, true)
            end)
            local aniTime = symbolNode:getAniamDurationByName(lineName)
            if delayTime < aniTime then
                delayTime = aniTime
            end
        end
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_bonus_trigger)

    if type(func) == "function" then
        self:delayCallBack(delayTime + 0.5,func)
    end
end

---
-- 触发respin 玩法
--
function CodeGameScreenMayanMysteryMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:levelDeviceVibrate(6, "respin")
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        self:stopLinesWinSound()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        self:delayCallBack(0.5, function()
            self:showRespinView(effectData)
        end)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenMayanMysteryMachine:showRespinView()

    self:clearCurMusicBg()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.m_lightScore = 0   

    --先播放动画 再进入respin
    self:triggerRespinAni(function()
        self:showReSpinStart(function()
            self:playGuoChangRespin(function()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )
                --可随机的特殊信号 
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)

                self:setReelBg(2)
            end, function()

            end, true)
        end)
    end)
end

--触发respin
function CodeGameScreenMayanMysteryMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

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
    self.m_respinNodeView:findChild("Node_sp_reel"):addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)

    self:addRespinColorLayer()
end

function CodeGameScreenMayanMysteryMachine:initRespinView(endTypes, randomTypes)
    self.m_respinNodeView:runCsbAction("idle2", false)

    self:createRespinRoll()

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
            
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount, true)
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()

            self:playScaleByRespin(function()
                -- self.m_respinWenanView:setCallBack(function()
                    self:changeWildToBonusByRespin(function()
                        self:delayCallBack(0.5, function()
                            self.m_reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount - 1
                            self:addRespinLightEffect()
                            self:runNextReSpinReel()
                        end)
                    end)
                -- end)
                -- self.m_respinWenanView:palyStartAnim()
            end)
        end
    )
end

--[[
    判断是否添加差一个格子 动画 和 整列动画
]]
function CodeGameScreenMayanMysteryMachine:addRespinLightEffect( )
    self.m_respinView.m_isPlayKuangSound = true
    self.m_respinView.m_isPlayKuangColSound = true

    local fullColNum = 0
    for _col = 1, 5 do
        local bonusNum = self.m_respinView:addRespinLightEffectSingle(_col, true)
        if bonusNum and bonusNum == 3 then
            fullColNum = fullColNum + 1
        end
        self.m_respinColMul[_col] = 1
    end
    if fullColNum ~= self.m_fullColNum then
        self.m_fullColNum = fullColNum
        self.m_respinMulBar:updataRespinCount(self.m_fullColNum, true)
    end

    self.m_respinView:checkQuickCols()
end

--[[
    respin 每个bonus落地之后 处理
]]
function CodeGameScreenMayanMysteryMachine:playUpdataRespinCountEffect(_num)
    self.m_fullColNum = _num
    self.m_respinMulBar:updataRespinCount(self.m_fullColNum, true)
end

function CodeGameScreenMayanMysteryMachine:showReSpinStart(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_startView)

    local view = self:showDialog("ReSpinStart", nil, func, 1)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenMayanMysteryMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD and symbolType ~= self.SYMBOL_WILD_2 and symbolType ~= self.SYMBOL_BONUS then
                symbolType = self.SYMBOL_EMPTY
            end
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReSpinReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = 141
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

function CodeGameScreenMayanMysteryMachine:getRespinSpinData()
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusScore = selfMakeData.bonusScore or {}
    local index = 0
    local storedInfo = {}
    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            for _pos, _ in pairs(bonusScore) do
                if tonumber(_pos) == index then
                    local type = self:getMatrixPosSymbolType(iRow, iCol)

                    local pos = {iX = iRow, iY = iCol, type = type}
                    storedInfo[#storedInfo + 1] = pos
                end
            end
            index = index + 1
        end
    end
    return storedInfo
end

--开始滚动
function CodeGameScreenMayanMysteryMachine:startReSpinRun()
    self.m_isPlayUpdateRespinNums = true
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}

    CodeGameScreenMayanMysteryMachine.super.startReSpinRun(self)
end

---
--
function CodeGameScreenMayanMysteryMachine:getReSpinReelPos(col)
    local reelNode = self.m_respinNodeView:findChild("sp_reel_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

-- 是不是 respinBonus小块
function CodeGameScreenMayanMysteryMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return true
    end
    return false
end

---判断结算
function CodeGameScreenMayanMysteryMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()

    for _col = 1, 5 do
        self.m_respinColMul[_col] = 1
    end

    self.m_respinView:checkQuickCols()

    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self.m_reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount - 1
    end
    --继续
    self:runNextReSpinReel()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

--[[
    respin结束动作
]]
function CodeGameScreenMayanMysteryMachine:reSpinEndAction()
    local callBack = function()
        self.m_respinView:removeAllColEffect()
        self:showRespinJackpotView(function()
            local chipList = self.m_respinView:getAllCleaningNode()
            table.sort(chipList, function(a, b)
                if a.p_cloumnIndex == b.p_cloumnIndex then
                    return a.p_rowIndex > b.p_rowIndex 
                end
                return a.p_cloumnIndex < b.p_cloumnIndex 
            end)

            --所有的bonus小块播放一遍结算触发动画(时间线根据各关需求而定)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_bonus_shouji_trigger)

            local delayTime = 0
            for index ,symbolNode in ipairs(chipList) do
                symbolNode:runAnim("actionframe")
                local aniTime = symbolNode:getAniamDurationByName("actionframe")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end

            --开始收集流程
            self:delayCallBack(delayTime,function()
                --依次结算bonus
                self:collectNextBonusScore(chipList,1,function()
                    self:respinOver()
                end)
            end)
        end)
    end

    self.m_respinView:removeAllSingle()

    self.m_chipList = self.m_respinView:getAllCleaningNode()
    --1.判断是否有随机乘倍
    --2.有-随机倍数
    --3.没有 收集
    local columnsMultipleListx = self.m_runSpinResultData.p_selfMakeData.columnsMultipleList or {}
    if(#columnsMultipleListx > 0)then
        self.m_respinPress:setCallBack(function()
            self:respinCollect(function()
                callBack()
            end)
        end)
        self.m_respinPress:showPress()
    else
        callBack()
    end
end

function CodeGameScreenMayanMysteryMachine:respinCollect(_func)
    --列 随机效果
    local num, cols, noCols = self:getRespinFullColnum(self.m_runSpinResultData.p_reels)
    local columnsMultipleListx = self.m_runSpinResultData.p_selfMakeData.columnsMultipleList or {}
    if self.m_respinMulSpinNumIndex > #columnsMultipleListx then
        self.m_respinRoll:changeRollParent()
        if _func then
            _func()
        end
        return
    end

    local info = columnsMultipleListx[self.m_respinMulSpinNumIndex]
    local col, mult = 0,0
    for _col, _mul in pairs(info) do
        col = tonumber(_col) + 1
        mult = _mul
    end

    self.m_respinMulBar:updataRespinCount(num - self.m_respinMulSpinNumIndex, false)

    self.m_respinRoll:produceDatas({col = col, num = mult})
    self.m_respinRoll:beginRun()

    self.m_respinRoll:setRunEndCallFuncBack(function()
        self.m_respinView:stopRuneffect(col)
        self:hideColorLayerByRespin()
    end,
    function()
        self.m_respinView:updateMultiple(col, mult, function()
            self.m_respinColMul[col] = self.m_respinColMul[col] * mult
            self.m_respinMulSpinNumIndex = self.m_respinMulSpinNumIndex + 1
            self:respinCollect(_func)
        end)
    end)
    
    if(#cols > 1)then
        self.m_respinView:randomMultipleCol(cols, col)
    else
        self.m_respinView:playRuneffect(col)
    end
    self:showColorLayerByRespin(noCols)
end

--[[
    respin每列刚好集满效果
]]
function CodeGameScreenMayanMysteryMachine:playJiQiEffectByRespinCil( )
    if not self.m_respinJiMan:isVisible() then
        self.m_respinJiMan:setVisible(true)
        self.m_respinJiMan:runCsbAction("actionframe1", false, function()
            self.m_respinJiMan:setVisible(false)
        end)
    end
end

--[[
    respin 玩法 jackpot
]]
function CodeGameScreenMayanMysteryMachine:showRespinJackpotView(_func)
    local chipList = self.m_respinView:getAllCleaningNode()
    if #chipList >= 15 then
        self.m_respinJackPotBarView:playJackpotEffect()

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_man)

        util_shakeNode(self:findChild("root"), 5, 10, 1.5)
        self.m_respinJiMan:setVisible(true)
        self.m_respinJiMan:runCsbAction("actionframe", false, function()
            self.m_respinJiMan:setVisible(false)
            local winCoin = 0
            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.jackpot and 
                self.m_runSpinResultData.p_selfMakeData.jackpot.jackpotCoins then
                    
                winCoin = self.m_runSpinResultData.p_selfMakeData.jackpot.jackpotCoins
            end
            local view = util_createView("CodeMayanMysterySrc.MayanMysteryJackpotWinView",{
                jackpotType = "epic",
                winCoin = winCoin,
                machine = self,
                func = function(  )
                    self.m_lightScore  = self.m_lightScore + winCoin
                    self:playCoinWinEffectUI()
                    --刷新赢钱
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))

                    if _func then
                        _func()
                    end
                end
            })
            gLobalViewManager:showUI(view)
            view:findChild("root"):setScale(self.m_machineRootScale)   
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    获取满列数据
]]
function CodeGameScreenMayanMysteryMachine:getRespinFullColnum( reels )
    if not reels or #reels == 0 then
        reels = self.m_runSpinResultData.p_reels
    end
  
    local columns = 0
    local cols = {}
    local noCols = {}
  
    local count  = 0
    for _col = 1, 5 do
        count = 0
        for _row = 1, 3 do
            if reels[_row][_col] == self.SYMBOL_BONUS then
                count = count + 1
            end
        end
    
        if(count == 3)then
            columns = columns + 1
            table.insert(cols, _col)
        else
            table.insert(noCols, _col)
        end
  
    end
    return columns, cols, noCols
end

--[[
    修改respin bonus上的钱数
]]
function CodeGameScreenMayanMysteryMachine:changeBonusCoins(_symbolNode, _coins, _isAddMul)
    if _symbolNode then
        local symbol_node = _symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        if spineNode and spineNode.m_csbNode then
            local coinsView = spineNode.m_csbNode
            local lineBet = globalData.slotRunData:getCurTotalBet()
            local multi = _coins / lineBet
            local labCoins = coinsView:findChild("m_lb_coins_1")
            local labCoins1 = coinsView:findChild("m_lb_coins_11")
            coinsView:runCsbAction("idleframe")

            -- if multi >= 5 then
            if _isAddMul then
                labCoins = coinsView:findChild("m_lb_coins_2")
                labCoins1 = coinsView:findChild("m_lb_coins_22")
                coinsView:findChild("Node_1"):setVisible(false)
                coinsView:findChild("Node_1_0"):setVisible(true)
            else
                coinsView:findChild("Node_1"):setVisible(true)
                coinsView:findChild("Node_1_0"):setVisible(false)
            end
            labCoins:setString(util_formatCoins(_coins, 3))
            self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 172)
            labCoins1:setString(util_formatCoins(_coins, 3))
            self:updateLabelSize({label = labCoins1,sx = 1,sy = 1}, 172)
        end
    end
end

function CodeGameScreenMayanMysteryMachine:respinOver()

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    -- self:removeRespinNode()
    self:delayCallBack(1, function()
        self:showRespinOverView()
    end)
end

function CodeGameScreenMayanMysteryMachine:showRespinOverView(effectData)
    self:clearCurMusicBg()

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view = self:showReSpinOver(strCoins,function()
        self:playGuoChangRespin(function()
            self:removeRespinNode()
            self:setReelBg(1)
            self:changeReSpinOverUI()
            self.m_curSpinSymbolList = {}
            self.m_suodingNode:removeAllChildren(true)

            self.m_respinRoll:removeFromParent()
            self.m_respinRoll = nil
            self.m_respinColorLayers = {}

            local data = self:getBaseSpinbetDataByTotalBet()
            data.fixedWild = {}
            data.newWild = {}
            data.fixedWildTimes = 0

        end,function()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
        end, false)
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_overView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_MayanMystery_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_overView_over)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},610)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenMayanMysteryMachine:triggerReSpinOverCallFun(score)
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
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
    收集下个bonus到赢钱区
]]
function CodeGameScreenMayanMysteryMachine:collectNextBonusScore(chipList,index,func)
    if index > #chipList then
        if type(func) == "function" then
            func()
        end
        return
    end

    local symbolNode = chipList[index]
    local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local winScore = self:getReSpinSymbolScore(posIndex)
    winScore = winScore * self.m_respinColMul[symbolNode.p_cloumnIndex]

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_bonus_shouji)

    symbolNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 100)
    symbolNode:runAnim("jiesuan", false, function()
        symbolNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex)
    end)
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if spineNode and spineNode.m_csbNode then
        local coinsView = spineNode.m_csbNode
        coinsView:runCsbAction("dark")
    end
    
    self.m_lightScore  = self.m_lightScore + winScore
    self:playCoinWinEffectUI()
    --刷新赢钱
    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
    self:delayCallBack(0.4, function()
        self:collectNextBonusScore(chipList,index + 1,func)
    end)
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenMayanMysteryMachine:checkChangeRespinFixNode(node)
    if node.p_symbolType == self.SYMBOL_EMPTY then
        local randType = math.random(0, 7)
        self:changeSymbolType(node, randType)
    else
        node:runAnim("idleframe1", true)
        local symbol_node = node:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        if spineNode and spineNode.m_csbNode then
            local coinsView = spineNode.m_csbNode
            coinsView:runCsbAction("idleframe")
        end
    end

    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local nodePos = util_getPosByColAndRow(self, node.p_cloumnIndex, node.p_rowIndex)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node) 
    node:setPosition(nodePos)
    local zOrder = self:getBounsScatterDataZorder(node.p_symbolType)
    node:setZOrder(zOrder - node.p_rowIndex + node.p_cloumnIndex * 10)
end

--[[
    进入respin 如果有wild 变成bonus
]]
function CodeGameScreenMayanMysteryMachine:changeWildToBonusByRespin(_func)
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    local isHaveWild = false
    for _, _node in ipairs(allEndNode) do
        if _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _node.p_symbolType == self.SYMBOL_WILD_2 then
            isHaveWild = true
        end
    end
    if isHaveWild then
        self:delayCallBack(0.5, function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_changeWildToBonus)
            local data = self:getBaseSpinbetDataByTotalBet()
            for _, _node in ipairs(allEndNode) do
                if _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _node.p_symbolType == self.SYMBOL_WILD_2 then
                    local symbolName = self:getSymbolCCBNameByType(self, _node.p_symbolType)
                    local newWild = util_spineCreate(symbolName, true, true)
                    local startPos = util_convertToNodeSpace(_node, self.m_effectNode)
                    newWild:setPosition(startPos)
                    self.m_effectNode:addChild(newWild)
                    local actionFrameName = self:getWildTimeLine(9, data.fixedWildTimes)
                    util_spinePlay(newWild, actionFrameName, false)
                    self:delayCallBack(45/30, function()
                        newWild:removeFromParent()
                    end)

                    self:changeSymbolType(_node, self.SYMBOL_BONUS, true)
                    self:setSpecialNodeScore(_node)
                    _node:setScale(0.95)
                    _node:runAnim("show")
                end
            end
            self:delayCallBack(45/30, function()
                if _func then
                    _func()
                end
            end)
        end)
    else
        if _func then
            _func()
        end
    end
end

-----------------------------respin相关接口  end------------------------------------------------ 
function CodeGameScreenMayanMysteryMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeMayanMysterySrc.MayanMysteryJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
    显示jackpotWin
]]
function CodeGameScreenMayanMysteryMachine:showJackpotView(_data, _func)
    self.m_jackpotIndex = self.m_jackpotIndex + 1
    local jackpotData = nil
    local jackpot = nil
    if _data.selfData and _data.selfData.jackpot then
        jackpotData = _data.selfData.jackpot.winjackpotname or {}
        jackpot = _data.selfData.jackpot
    else
        if _data.p_selfMakeData and _data.p_selfMakeData.jackpot then
            jackpotData = _data.p_selfMakeData.jackpot.winjackpotname or {}
            jackpot = _data.p_selfMakeData.jackpot
        end
    end
    if not jackpotData or self.m_jackpotIndex > #jackpotData then
        if type(_func) == "function" then
            _func()
        end
        return
    end
    -- 两种jackpot 需要排序
    if #jackpot.JackpotwinValue > 1 then
        self:jackpotWinDataSort(jackpot)
    end

    local jackpotName = {}
    local view = util_createView("CodeMayanMysterySrc.MayanMysteryJackpotWinView",{
        jackpotType = jackpot.winjackpotname[self.m_jackpotIndex],
        winCoin = jackpot.JackpotwinValue[self.m_jackpotIndex],
        machine = self,
        func = function(  )
            self:showJackpotView(_data, _func)
        end
    })
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

--[[
    同时中奖多个jackpot 排序
]]
function CodeGameScreenMayanMysteryMachine:jackpotWinDataSort(_jackpot)
    if _jackpot.JackpotwinValue[1] > _jackpot.JackpotwinValue[2] then
        local winCoins = clone(_jackpot.JackpotwinValue[1])
        local winJackpot = clone(_jackpot.winjackpotname[1])
        _jackpot.JackpotwinValue[1] = _jackpot.JackpotwinValue[2]
        _jackpot.winjackpotname[1] = _jackpot.winjackpotname[2]

        _jackpot.JackpotwinValue[2] = winCoins
        _jackpot.winjackpotname[2] = winJackpot
    end
end

function CodeGameScreenMayanMysteryMachine:updateNetWorkData()
    if self.m_curbetWildTime == -1 then
        self:updateWildCount(self.m_curbetWildTime, function()
            self:updateBaseSpinData()
            CodeGameScreenMayanMysteryMachine.super.updateNetWorkData(self)
        end)
        return
    end

    self:updateBaseSpinData()
    CodeGameScreenMayanMysteryMachine.super.updateNetWorkData(self)
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenMayanMysteryMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance() then

        --播放预告中奖动画
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
end

--[[
    播放预告中奖动画
    预告中奖通用规范
    命名:关卡名+_yugao
    时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
    挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
    下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
]]
function CodeGameScreenMayanMysteryMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = true
    --动效执行时间
    local aniTime = 0
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_yugao)

    self.m_yugaoRoleSpine:setVisible(true)
    util_spinePlay(self.m_yugaoRoleSpine, "actionframe_yugao2", false)
    util_spineEndCallFunc(self.m_yugaoRoleSpine, "actionframe_yugao2", function()
        self.m_yugaoRoleSpine:setVisible(false)
    end)
    self:delayCallBack(20/30, function()
        self.m_yugaoEffectSpine:setVisible(true)
        util_spinePlay(self.m_yugaoEffectSpine, "actionframe_yugao", false)
        util_spineEndCallFunc(self.m_yugaoEffectSpine, "actionframe_yugao", function()
            self.m_yugaoEffectSpine:setVisible(false)

            if type(func) == "function" then
                func()
            end
        end)
    end)
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenMayanMysteryMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_bigwin_yugao_say)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_bigwin_yugao)

    self.m_bigwinEffect:setVisible(true)
    util_spinePlay(self.m_bigwinEffect, "actionframe", false)
    util_spineEndCallFunc(self.m_bigwinEffect, "actionframe", function()
        self:stopLinesWinSound()

        self.m_bigwinEffect:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigwinEffect:getAnimationDurationTime("actionframe")
    util_shakeNode(rootNode,5,10,aniTime)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenMayanMysteryMachine:showEffect_Bonus(effectData)
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
    self:clearCurMusicBg()
    
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

--[[
    bonus玩法
]]
function CodeGameScreenMayanMysteryMachine:showEffect_Bonus(effectData)
    -- 播放震动
    self:levelDeviceVibrate(6, "bonus")

    self:playTriggerEffectByBonus(1, function()
        self:playGuoChangColorFul(function()
            self:resetMusicBg(nil, "MayanMysterySounds/music_MayanMystery_colorFul_bonus.mp3")
            self:setMaxMusicBGVolume()

            --在调用showView之前需重置界面显示
            local endFunc = function(_data)
                self.m_bonusGameView:setVisible(true)
                self.m_bonusGameView:startGame(_data, function()
                    self:showJackpotView(_data, function()
                        self:playGuoChangToBaseColorFul(function()
                            self.m_bonusGameView:setVisible(false)
                        end, function()
                            self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, self.EFFECT_TYPE_COLLECT)
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

                            --刷新赢钱
                            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(globalData.slotRunData.lastWinCoin))

                            self:resetMusicBg()
                            self:checkTriggerOrInSpecialGame(function(  )
                                self:reelsDownDelaySetMusicBGVolume( ) 
                            end)

                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end)
                    end)
                end)
            end
            self.m_colorfulGameView:resetView(self.m_featureDataClone, endFunc)
            self.m_colorfulGameView:showView() 
        end, true)
    end)
    return true
end

--[[
    获取jackpot类型及赢得的金币数
]]
function CodeGameScreenMayanMysteryMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        return string.lower(jackpotType),coins
    end
    return "",0    
end

--[[
    bonus断线重连
]]
function CodeGameScreenMayanMysteryMachine:initFeatureInfo(spinData,featureData)
    --若服务器返回数据中没有status字段必须要求服务器加上,触发时可不返回
    if featureData.p_bonus and featureData.p_bonus.extra and featureData.p_bonus.extra.introFinished then
        self:addBonusEffect()
    end    
end

--[[
    添加bonus事件
]]
function CodeGameScreenMayanMysteryMachine:addBonusEffect()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})    
end

--[[
    处理wild 时间线
    根据状态来播对应的时间线
    时间线id:
    1:落地(buling)
    2:静帧(idleframe)
    3:idle动画(idleframe1,idleframe2,idleframe3)
    4:收集 (shouji1,shouji2,shouji3)
    5:更新进度 减(switch)
    6:重置进度 
    7:连线动画
    8:触发动画
    9:变BONUS
]]
function CodeGameScreenMayanMysteryMachine:getWildTimeLine(timelineId, n_count)
    local data = self:getBaseSpinbetDataByTotalBet()
    local count = data.fixedWildTimes
  
    if(n_count)then
        count = n_count
    end
  
    local timelineKey = ""
  
    if(timelineId == 3)then
        if(count == 2)then
            timelineKey = "idleframe3"
        elseif(count == 1)then
            timelineKey = "idleframe2"
        else
            timelineKey = "idleframe1"
        end
  
    elseif(timelineId == 4)then
        if(count == 2)then
            timelineKey = "shouji_3"
        elseif(count == 1)then
            timelineKey = "shouji_2"
        else
            timelineKey = "shouji_1"
        end
  
    elseif(timelineId == 5)then
        if(count == 1)then
            timelineKey = "switch1"
        elseif(count == 0)then
            timelineKey = "switch2"
        elseif(count == -1)then
            timelineKey = "switch3"
        else
            timelineKey = ""
        end
  
    elseif(timelineId == 6)then
        local frontcount = self.m_curbetWildTime
        if(frontcount == 2)then
            timelineKey = ""
        elseif(frontcount == 1)then
            timelineKey = "reset1" --2格变3格
        else
            timelineKey = "reset2" --1格变3格
        end
  
    elseif(timelineId == 7)then
        if(count == 2)then
            timelineKey = "actionframe_3"
        elseif(count == 1)then
            timelineKey = "actionframe_2"
        else
            timelineKey = "actionframe_1"
        end
    
    elseif(timelineId == 8)then
        if(count == 2)then
            timelineKey = "actionframe2_3"
        elseif(count == 1)then
            timelineKey = "actionframe2_2"
        else
            timelineKey = "actionframe2_1"
        end
  
    elseif(timelineId == 9)then
        if(count == 2)then
            timelineKey = 'change3'
        elseif(count == 1)then
            timelineKey = 'change2'
        else
            timelineKey = 'change1'
        end
    end
  
    return timelineKey
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenMayanMysteryMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or slotsNode.p_symbolType == self.SYMBOL_WILD_2 then
                self:playWildLineAnim(slotsNode)
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

function CodeGameScreenMayanMysteryMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or slotsNode.p_symbolType == self.SYMBOL_WILD_2 then
                        self:playWildLineAnim(slotsNode)
                    else
                        slotsNode:runLineAnim()
                    end
                end
            end
        end
    end
end

--播放wild连线动画
function CodeGameScreenMayanMysteryMachine:playWildLineAnim(_slotsNode)
    if not tolua.isnull(_slotsNode) then
        local data = self:getBaseSpinbetDataByTotalBet()
        local lineName = self:getWildTimeLine(7, data.fixedWildTimes)
        _slotsNode:runAnim(lineName, true)
    end
end

--[[
    判断收集的时候 是否触发了其他玩法
]]
function CodeGameScreenMayanMysteryMachine:getIsTriggerFeature( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpot = selfdata.jackpot or {}
    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID
    if #features >= 2 and features[2] > 0 then
        return true
    end

    if jackpot.process and #jackpot.process > 0 then
        return true
    end

    return false
end

--[[
    播放多福多彩 过场
]]
function CodeGameScreenMayanMysteryMachine:playGuoChangColorFul(_func, _isColorFul)
    if _isColorFul then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_base_to_colorful_guochang)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_bonusGame_guochang)
    end

    self.m_yugaoRoleSpine:setVisible(true)
    util_spinePlay(self.m_yugaoRoleSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_yugaoRoleSpine, "actionframe", function()
        self.m_yugaoRoleSpine:setVisible(false)

        if _func then
            _func()
        end
    end)
end

--[[
    播放多福多彩 过场 回到base
]]
function CodeGameScreenMayanMysteryMachine:playGuoChangToBaseColorFul(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_bonusGame_to_base_guochang)
    self.m_colorFulGuoChang:setVisible(true)
    util_spinePlay(self.m_colorFulGuoChang, "actionframe_guochang", false)

    self:delayCallBack(30/30, function()
        if _func1 then
            _func1()
        end
    end)

    util_spineEndCallFunc(self.m_colorFulGuoChang, "actionframe_guochang", function()
        self.m_colorFulGuoChang:setVisible(false)
        if _func2 then
            _func2()
        end
    end)
end

--[[
    播放respin 过场
]]
function CodeGameScreenMayanMysteryMachine:playGuoChangRespin(_func1, _func2, _isComeRespin)
    if _isComeRespin then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_guochang_toRespin)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_respin_guochang)
    end

    self.m_yugaoRoleSpine:setVisible(true)
    util_spinePlay(self.m_yugaoRoleSpine, "actionframe_guochang", false)

    self:delayCallBack(75/30, function()
        if _func1 then
            _func1()
        end
    end)

    util_spineEndCallFunc(self.m_yugaoRoleSpine, "actionframe_guochang", function()
        self.m_yugaoRoleSpine:setVisible(false)
        if _func2 then
            _func2()
        end
    end)
end

--[[
    respin过场中间 开始缩放界面
]]
function CodeGameScreenMayanMysteryMachine:playScaleByRespin(_func)
    self:delayCallBack(5/30, function()
        self.m_gameBg:runCsbAction("actionframe_guochang", false, function()
            self.m_gameBg:runCsbAction("idle2", false)
        end)
    
        self.m_respinNodeView:runCsbAction("actionframe_guochang", false, function()
            self.m_respinNodeView:runCsbAction("idle2", false)
            if _func then
                _func()
            end
        end)
    end)
end

--[[
    多福多彩2 添加大赢
]]
function CodeGameScreenMayanMysteryMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpot = selfData.jackpot or {}

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end

    if notAdd then
        if jackpot.process and #jackpot.process > 0 then
            return false
        end
    end

    return notAdd
end

---
--设置bonus scatter 层级
function CodeGameScreenMayanMysteryMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  self.SYMBOL_WILD_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
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
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenMayanMysteryMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                self:getRandomList()

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                if self.m_respinView and not self.m_respinView:isLastSpin() then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
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

function CodeGameScreenMayanMysteryMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenMayanMysteryMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenMayanMysteryMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    -- if nodeParent == self.m_clipParent then
    --     slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode)
    -- else
        slotNode.p_showOrder = slotNode:getLocalZOrder()+slotNode.p_cloumnIndex
    -- end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- 切换图层
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

--[[
    检测播放bonus落地音效
]]
function CodeGameScreenMayanMysteryMachine:checkPlayBonusDownSound(_node)
    local colIndex = _node.p_cloumnIndex
    if not self.m_bonus_down[colIndex] then
        --播放bonus
        if _node.p_symbolType == self.SYMBOL_BONUS then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MayanMystery_bonus_buling)
        end
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_bonus_down[iCol] = true
        end
    else
        self.m_bonus_down[colIndex] = true
    end
end

--[[
    respin单列停止
]]
function CodeGameScreenMayanMysteryMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            gLobalSoundManager:playSound("MayanMysterySounds/sound_MayanMystery_reelDown.mp3")
        else
            gLobalSoundManager:playSound("MayanMysterySounds/sound_MayanMystery_quickReelDown.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

function CodeGameScreenMayanMysteryMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local params = {self.m_iOnceSpinLastWin, isNotifyUpdateTop}
    if self:checkHasGameSelfEffectType(self.EFFECT_BONUS_PICK) then
        params[self.m_stopUpdateCoinsSoundIndex] = true
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenMayanMysteryMachine:checkHasGameSelfEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_selfEffectType
        if value and value == effectType then
            return true
        end
    end

    return false
end

--随机信号
function CodeGameScreenMayanMysteryMachine:getReelSymbolType(parentData)
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2 then
        local child = self.m_suodingNode:getChildren()
        if #child > 0 and self.m_curbetWildTime > -1 then
            local wildType = nil
            for _index, _wildInfo in ipairs(self.m_collectOldWildInfo) do
                wildType = _wildInfo[2]
                break
            end
            if wildType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
            else
                symbolType = self.SYMBOL_WILD_2
            end
        end
    end

    return symbolType
end

--[[
    respin玩法 bonus的列压暗
]]
function CodeGameScreenMayanMysteryMachine:showColorLayerByRespin(_cols)
    for _, _col in ipairs(_cols) do
        local maskNode = self.m_respinColorLayers[_col]
        if not maskNode:isVisible() then
            maskNode:setVisible(true)
            maskNode:setOpacity(0)
            maskNode:runAction(cc.FadeTo:create(0.2, 153))
            
            self:changeRespinBonusZorder(_col)
            if self.m_respinView.m_effectNode_respinCol[_col] and self.m_respinView.m_effectNode_respinCol[_col]:isVisible() then
                self.m_respinView.m_effectNode_respinCol[_col]:setZOrder(1)
            end
        end
    end
end

--[[
    respin玩法 结束 隐藏压暗
]]
function CodeGameScreenMayanMysteryMachine:hideColorLayerByRespin()
    for col = 1, 5 do
        local maskNode = self.m_respinColorLayers[col]
        if maskNode:isVisible() then
            local maskNode = self.m_respinColorLayers[col]
            local fadeAct = cc.FadeTo:create(0.1, 0)
            local func = cc.CallFunc:create( function()
                maskNode:setVisible(false)
            end)
            maskNode:runAction(cc.Sequence:create(fadeAct, func))

            for _, _node in ipairs(self.m_chipList) do
                if _node.p_cloumnIndex == col then
                    local pos = util_convertToNodeSpace(_node, self.m_respinView)
                    util_changeNodeParent(self.m_respinView, _node,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - _node.p_rowIndex + _node.p_cloumnIndex)
                    _node:setTag(self.m_respinView.REPIN_NODE_TAG)
                    _node:setPosition(pos)
                end
            end

            if self.m_respinView.m_effectNode_respinCol[col] and self.m_respinView.m_effectNode_respinCol[col]:isVisible() then
                self.m_respinView.m_effectNode_respinCol[col]:setZOrder(200 + col)
            end
        end
    end
end

--[[
    修改respin bonus图标层级
]]
function CodeGameScreenMayanMysteryMachine:changeRespinBonusZorder(_col)
    for _, _node in ipairs(self.m_chipList) do
        if _node.p_cloumnIndex == _col then
            for i=1, #self.m_respinView.m_respinNodes do
                local _redspinNode = self.m_respinView.m_respinNodes[i]
                if _node.p_cloumnIndex == _redspinNode.p_colIndex and _node.p_rowIndex == _redspinNode.p_rowIndex then
                    local pos = util_convertToNodeSpace(_node, _redspinNode.m_clipNode)
                    util_changeNodeParent(_redspinNode.m_clipNode, _node,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - _node.p_rowIndex + _node.p_cloumnIndex)
                    _node:setPosition(pos)
                end
            end
        end
    end
end

return CodeGameScreenMayanMysteryMachine
