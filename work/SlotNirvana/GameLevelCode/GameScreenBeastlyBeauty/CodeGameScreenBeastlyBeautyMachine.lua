---
-- island li
-- 2019年1月26日
-- CodeGameScreenBeastlyBeautyMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "BeastlyBeautyPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseDialog = util_require("Levels.BaseDialog")
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenBeastlyBeautyMachine = class("CodeGameScreenBeastlyBeautyMachine", BaseSlotoManiaMachine)

CodeGameScreenBeastlyBeautyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBeastlyBeautyMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  -- 自定义的小块类型 9
CodeGameScreenBeastlyBeautyMachine.SYMBOL_WILD2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE --93
CodeGameScreenBeastlyBeautyMachine.SYMBOL_BIGWILD1X3_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7 --100
CodeGameScreenBeastlyBeautyMachine.SYMBOL_BIGWILD1X3_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 --101
CodeGameScreenBeastlyBeautyMachine.SYMBOL_BIGWILD2X3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9 --102

CodeGameScreenBeastlyBeautyMachine.m_changeBigSymbolEffect = GameEffect.EFFECT_SELF_EFFECT - 1 --base下自定义动画 
CodeGameScreenBeastlyBeautyMachine.m_freeSpinWildChange = GameEffect.EFFECT_SELF_EFFECT - 2 --free下自定义动画
CodeGameScreenBeastlyBeautyMachine.m_reSpinWildChange = GameEffect.EFFECT_SELF_EFFECT - 3 --respin下自定义动画 

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenBeastlyBeautyMachine:ctor()
    CodeGameScreenBeastlyBeautyMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_lightScore = 0
    self.m_aFreeSpinWildArry = {} -- FreeSpin 过程中wild 个数
    self.m_bonusConfig = {} --进入关卡保存收集相关数据
    self.m_iBetLevel = 0 -- bet等级
    self.m_isPlayBulingSound = true --判断播放几次落地音效
    self.m_isPLayChangeBigWildSound = true --用来判断合成2x3的大图 音效只播放一次
    self.m_isPLayFlyCollectSound = true --用来判断收集2x3的大图 音效只播放一次
    self.m_preWildContinusPos = {}
    self.m_isTriggerLongRun = false
    self.m_curBigWild2x3List = {} --base下快停的时候 用来临时存储2x3大图标（因为先创建的2x3 50帧之后 才会把原来的1x3移除掉）
    self.m_curBigWild1x3List = {}
    self.m_quickStopEffect = false --是否点击了快停 停止合图
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

	--init
	self:initGame()
end

function CodeGameScreenBeastlyBeautyMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBeastlyBeautyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BeastlyBeauty"  
end

function CodeGameScreenBeastlyBeautyMachine:initUI()
    --快滚音效
    self.m_reelRunSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_quickRun

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建进度条
    self.m_pregress = util_createView("CodeBeastlyBeautySrc.BeastlyBeautyPregressBarView")
    self:findChild("Node_jindutiao"):addChild(self.m_pregress)
    self.m_pregress:initMachine(self)

    -- 更改 tip的层级
    local node = self.m_pregress.m_shoujiTips
    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    pos = self:findChild("Node_tips"):convertToNodeSpace(pos)
    util_changeNodeParent(self:findChild("Node_tips"), node, 10000)
    node:setPosition(pos.x, pos.y)

    --bonus界面
    self.m_bonusGameView = util_createView("CodeBeastlyBeautySrc.BeastlyBeautyBonusGameView",self)
    self:findChild("Node_bonus"):addChild(self.m_bonusGameView)
    -- self.m_bonusGameView:setPosition(-display.width * 0.5, -display.height * 0.5)
    self.m_bonusGameView:setVisible(false)

    -- respin玩法的动画
    self.m_respin_action = cc.Node:create()
    self.m_respin_action:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("Node_effect"):addChild(self.m_respin_action)

    -- 棋盘遮罩
    self.m_qiPanDark = util_createAnimation("BeastlyBeauty_wildrespin_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_qiPanDark)
    self.m_qiPanDark:setVisible(false)

    -- respin快滚的时候棋盘遮罩
    self.m_qiPanDarkRespin = util_createAnimation("BeastlyBeauty_respin_dark.csb")
    -- self:findChild("Node_dark"):addChild(self.m_qiPanDarkRespin)
    self.m_clipParent:addChild(self.m_qiPanDarkRespin, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER-1, SYMBOL_NODE_TAG * 200) -- 防止在最上层
    self.m_qiPanDarkRespin:setVisible(false)

    -- free预告动画
    self.m_yugaoEffect = util_spineCreate("BeastlyBeauty_yugao", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoEffect)
    self.m_yugaoEffect:setVisible(false)

    -- 大赢动画
    --棋盘下
    self.m_bigwinEffect = util_spineCreate("BeastlyBeauty_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect)
    self.m_bigwinEffect:setVisible(false)
    self.m_bigwinEffect1 = util_spineCreate("BeastlyBeauty_binwin_beifen", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect1)
    self.m_bigwinEffect1:setVisible(false)
    self.m_bigwinEffectLiZi = util_createAnimation("BeastlyBeauty_bigwin_lizi.csb")
    self:findChild("Node_dark"):addChild(self.m_bigwinEffectLiZi)
    self.m_bigwinEffectLiZi:setVisible(false)

    -- free过场动画
    self.m_freeGuoChangEffect = util_spineCreate("BeastlyBeauty_guochang", true, true)
    self:findChild("Node_guochang"):addChild(self.m_freeGuoChangEffect)
    self.m_freeGuoChangEffect:setVisible(false)

    -- 跳过
    self.m_openBonusSkip = util_createView("CodeBeastlyBeautySrc.BeastlyBeautySkip", self)
    self:findChild("Node_Skip"):addChild(self.m_openBonusSkip)
    self.m_openBonusSkip:setVisible(false)
    
    self:setReelBg(1)
end

function CodeGameScreenBeastlyBeautyMachine:addObservers()
    CodeGameScreenBeastlyBeautyMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        local features = self.m_runSpinResultData.p_features or {}
        if #features > 1 then
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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = nil
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_BeastlyBeauty_free_winLine"..soundIndex] 
        else
            soundName = self.m_publicConfig.SoundConfig["sound_BeastlyBeauty_winLine"..soundIndex] 
        end

        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            -- 切换bet解锁进度条
            self:changeBetCallBack()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)

        if self:isNormalStates( )  then
            if self.m_iBetLevel == 0 then
                self:unlockHigherBet()
            else
                if self.getGameSpinStage() == IDLE then
                    if not self.m_pregress.m_shoujiTips:isVisible() then
                        --打开提醒
                        self:showTipsOpenView()
                    else
                        self:showTipsOverView()
                    end
                end
            end
        end
    end,"SHOW_UNLOCK_PREGRESS")

    gLobalNoticManager:addObserver(self,function(self,params)

        if self.m_pregress.m_shoujiTips:isVisible() then
            self:showTipsOverView()
        else
            if self.getGameSpinStage() == IDLE then
                self:showTipsOpenView()
            end
        end

    end,"SHOW_BTN_Tip")
end

--[[
    打开tips
]]
function CodeGameScreenBeastlyBeautyMachine:showTipsOpenView( )
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_tips_open)

    self.m_pregress.m_shoujiTips:setVisible(true)
    self.m_pregress.m_shoujiTips:runCsbAction("start",false,function()
        self.m_pregress.m_shoujiTips:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self:showTipsOverView()
        end, 3)
    end)
    
end

--[[
    关闭tips
]]
function CodeGameScreenBeastlyBeautyMachine:showTipsOverView( )
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    self.m_pregress.m_shoujiTips:runCsbAction("over",false,function()
        self.m_pregress.m_shoujiTips:setVisible(false)
    end)
end

--[[
    切换bet 进度条变化
]]
function CodeGameScreenBeastlyBeautyMachine:changeBetCallBack(_betCoins, _isFirstComeIn)
    self.m_iBetLevel = 0
    local betCoins =_betCoins or globalData.slotRunData:getCurTotalBet()

    for _betLevel,_betData in ipairs(self.m_specialBets) do
        if betCoins < _betData.p_totalBetValue then
            break
        end
        self.m_iBetLevel = _betLevel
    end

    if self.m_iBetLevel == 0 then
        self:LockPregress(_isFirstComeIn)
        -- 进度条是否已经打开
        self.m_pregressIsHaveOpen = false
    else
        self:unLockPregress(_isFirstComeIn)
        -- 进度条是否已经打开
        self.m_pregressIsHaveOpen = true
    end
end

--[[
    设置棋盘的背景
    _BgIndex 1bace 2free 
]]
function CodeGameScreenBeastlyBeautyMachine:setReelBg(_BgIndex, switch)

    if _BgIndex == 1 then
        if switch then
            self.m_gameBg:runCsbAction("switch2", false, function()
                self.m_gameBg:runCsbAction("normal", true)
            end)
        else
            self.m_gameBg:runCsbAction("normal", true)
        end
        self:findChild("reel_bg_base"):setVisible(true)
        self:findChild("reel_bg_free"):setVisible(false)
    elseif _BgIndex == 2 then
        if switch then
            self.m_gameBg:runCsbAction("switch1", false, function()
                self.m_gameBg:runCsbAction("freespin", true)
            end)
        else
            self.m_gameBg:runCsbAction("freespin", true)
        end
        self:findChild("reel_bg_base"):setVisible(false)
        self:findChild("reel_bg_free"):setVisible(true)
    end
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenBeastlyBeautyMachine:setScatterDownScound( )
    for i = 1, 6 do
        local soundPath = nil
        soundPath = "BeastlyBeautySounds/sound_BeastlyBeauty_scatter_buling.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

--[[
    初始化free条
]]
function CodeGameScreenBeastlyBeautyMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("Node_freegamebar")
        self.m_baseFreeSpinBar = util_createView("CodeBeastlyBeautySrc.BeastlyBeautyFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
    end
end

--[[
    显示free条
]]
function CodeGameScreenBeastlyBeautyMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    util_nodeFadeIn(self.m_baseFreeSpinBar, 0.3, 0, 255, nil, function()
    end)
end

--[[
    隐藏free条
]]
function CodeGameScreenBeastlyBeautyMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_nodeFadeIn(self.m_baseFreeSpinBar, 0.3, 255, 0, nil, function()
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
    end)
    
end

--[[
    进入关卡音效
]]
function CodeGameScreenBeastlyBeautyMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_enterGame)

    end,0.4,self:getModuleName())
end

function CodeGameScreenBeastlyBeautyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBeastlyBeautyMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- 进入关卡先初始化一遍进度条
    self:changeBetCallBack(nil, true)

    local pecent = self:getProgressPecent()
    self.m_pregress:updateLoadingbar(pecent,false)

    -- 打开提醒框
    self:showTipsOpenView()
    
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and self.m_runSpinResultData and 
    self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features <= 1 then
        -- 打开开始弹板
        self:showEnterGameView()
    end
end

function CodeGameScreenBeastlyBeautyMachine:showEnterGameView()
    local enterView = util_createView("CodeBeastlyBeautySrc.BeastlyBeautyEnterGameView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        enterView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(enterView, ViewZorder.ZORDER_UI)
end

function CodeGameScreenBeastlyBeautyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBeastlyBeautyMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBeastlyBeautyMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_WILD2 then
        return "Socre_BeastlyBeauty_Wild_0"
    end

    if symbolType == self.SYMBOL_BIGWILD1X3_1 then
        return "Socre_BeastlyBeauty_Wild_big1"
    end

    if symbolType == self.SYMBOL_BIGWILD1X3_2 then
        return "Socre_BeastlyBeauty_Wild_big2"
    end

    if symbolType == self.SYMBOL_BIGWILD2X3 then
        return "Socre_BeastlyBeauty_Wild_big3"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BeastlyBeauty_10"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBeastlyBeautyMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBeastlyBeautyMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIGWILD1X3_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIGWILD1X3_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIGWILD2X3,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

--[[
    断线重连 
]]
function CodeGameScreenBeastlyBeautyMachine:MachineRule_initGame(  )
    self.m_isDuanXian = true
    if self.m_bProduceSlots_InFreeSpin and self.m_runSpinResultData.p_freeSpinsTotalCount ~= self.m_runSpinResultData.p_freeSpinsLeftCount then
        self:setReelBg(2)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

--[[
    进入关卡 处理一下断线respin
]]
function CodeGameScreenBeastlyBeautyMachine:enterLevel( )
    CodeGameScreenBeastlyBeautyMachine.super.enterLevel(self)

    -- 断线重连 处理一下respin玩法
    if self.m_runSpinResultData and self.m_runSpinResultData.p_reSpinCurCount then
        local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
        if reSpinCurCount > 0 then
            self.m_respin_action:setVisible(false)
            -- 处理大信号信息
            if self.m_hasBigSymbol == true then
                self.m_bigSymbolColumnInfo = {}
            else
                self.m_bigSymbolColumnInfo = nil
            end

            self:createRespinWild()
            self:respinChangeBigWild()
        end
    end
end

--[[
    单列滚动停止回调
]]
function CodeGameScreenBeastlyBeautyMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and self:getGameSpinStage() ~= QUICK_RUN then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

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
    end

    if not self.m_isTriggerLongRun then
        self.m_isTriggerLongRun = isTriggerLongRun
    end

    return isTriggerLongRun
   
end

function CodeGameScreenBeastlyBeautyMachine:symbolBulingEndCallBack(_symbolNode)
    -- 是否有快滚
    local showScatterQuick, showWildQuick = self:getNumByScatterAndWild()

    if _symbolNode and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and showScatterQuick then
        if self.m_isTriggerLongRun and _symbolNode.p_cloumnIndex ~= self.m_iReelColumnNum then
            local Col = _symbolNode.p_cloumnIndex
            for iCol = 1, Col do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType and symbolNode.m_currAnimName ~= "idleframe3" then
                        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            symbolNode:runAnim("idleframe3", true)
                        end
                    end
                end
            end
        else
            _symbolNode:runAnim("idleframe2", true)
        end
    end
end

-- 处理特殊关卡 遮罩层级
function CodeGameScreenBeastlyBeautyMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

--设置bonus scatter 层级
function CodeGameScreenBeastlyBeautyMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD2 then
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
    修改底层方法 快停的时候不显示快滚框
]]
function CodeGameScreenBeastlyBeautyMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true and (self:getGameSpinStage() ~= QUICK_RUN) then
        isTriggerLongRun = true -- 触发了长滚动

        for i = reelCol + 1, self.m_iReelColumnNum do
            --添加金边
            if i == reelCol + 1 then
                if self.m_reelRunInfo[i]:getReelLongRun() then
                    self:creatReelRunAnimation(i)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end

--[[
    播放freespin轮盘背景动画触发
    改变背景动画等
]]
function CodeGameScreenBeastlyBeautyMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

--[[
    播放freespinover 轮盘背景动画触发
    改变背景动画等
]]
function CodeGameScreenBeastlyBeautyMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


--[[
    FreeSpin相关
    FreeSpinstart
]]
function CodeGameScreenBeastlyBeautyMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        local view
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeMore)

            view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:resetMusicBg(nil, self:getFreeSpinMusicBG())
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeGuoChang)

                self:freeGuoChangEffect(function()
                    self:setReelBg(2, true)
                end,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end)  
            end)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeStart)
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click
            view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeOver
        end
        -- 弹板上的光
        local tanbanShine = util_createAnimation("BeastlyBeauty/BeastlyBeauty_freetb_shine.csb")
        view:findChild("Node_shine"):addChild(tanbanShine)
        tanbanShine:runCsbAction("idle",true)

        local guangSpine = util_spineCreate("BeastlyBeauty_tanban_guang", true, true)
        view:findChild("Node_guang1"):addChild(guangSpine)
        util_spinePlay(guangSpine,"idle",true)
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenBeastlyBeautyMachine:triggerFreeSpinCallFun()
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
    -- self:resetMusicBg()
end

--[[
    free过场的粒子
]]
function CodeGameScreenBeastlyBeautyMachine:freeGuoChangLizi()
    local moveStartPos = cc.p(display.width * 0.5, 0)
    local moveEndPos = cc.p(-display.width * 0.5, 0)

    local actionList = {}

    -- free过场动画的粒子
    local flyNode = util_createAnimation("BeastlyBeauty_guochang_lizi2.csb")
    self:findChild("Node_guochang"):addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
    flyNode:setPosition(moveStartPos)

    for _index = 1, 2 do
        -- flyNode:findChild("Particle_".._index):setDuration(2)     --设置拖尾时间(生命周期)
        flyNode:findChild("Particle_".._index):setPositionType(0)   --设置可以拖尾
    end

    actionList[#actionList + 1] = cc.BezierTo:create(2,{cc.p(0, -display.height * 0.5), cc.p(0, -display.height * 0.5), moveEndPos})
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        for _index = 1, 2 do
            flyNode:findChild("Particle_".._index):stopSystem()
        end

        self:waitWithDelay(function()
            flyNode:removeFromParent()
            flyNode = nil
        end,2)
        
    end)

    local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))

    flyNode:runAction(cc.Sequence:create(spawnAct))
end

--[[
    free玩法过场
]]
function CodeGameScreenBeastlyBeautyMachine:freeGuoChangEffect(func1,func2)
    self.m_freeGuoChangEffect:setVisible(true)
    util_spinePlay(self.m_freeGuoChangEffect,"actionframe",false)

    self:waitWithDelay(function()
        self:freeGuoChangLizi()
    end,35/30)

    self:waitWithDelay(function()
        if func1 then
            func1()
        end
    end,90/30)

    self:waitWithDelay(function()
        self:bonusGuoChangEffect(function()
            if func2 then
                func2()
            end
        end,nil,true)
    end,110/30)

    util_spineEndCallFunc(self.m_freeGuoChangEffect,"actionframe",function ()
        self:waitWithDelay(function()
            self.m_freeGuoChangEffect:setVisible(false)
        end,1)
    end)
end

--[[
    bonus玩法过场
]]
function CodeGameScreenBeastlyBeautyMachine:bonusGuoChangEffect(func, func1, isNoPlay)
    -- bonus过场动画
    self.m_bonusGuoChangEffect = util_spineCreate("BeastlyBeauty_guochang2", true, true)
    self:findChild("Node_guochang"):addChild(self.m_bonusGuoChangEffect)

    if isNoPlay then
        util_spinePlay(self.m_bonusGuoChangEffect,"actionframe_guochang",false)
    else
        util_spinePlay(self.m_bonusGuoChangEffect,"animation",false)
    end

    self:waitWithDelay(function()
        for _index = 1, 2 do
            self.m_bonusGuoChangEffect["flyHuaTuoWeiNode".._index] = util_createAnimation("BeastlyBeauty_guochang_lizi.csb")
            util_spinePushBindNode(self.m_bonusGuoChangEffect,"trail_0".._index,self.m_bonusGuoChangEffect["flyHuaTuoWeiNode".._index])
            self.m_bonusGuoChangEffect["flyHuaTuoWeiNode".._index]:findChild("Particle_1"):setDuration(5)     --设置拖尾时间(生命周期)
            self.m_bonusGuoChangEffect["flyHuaTuoWeiNode".._index]:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        end
    end,0.7)

    self:waitWithDelay(function()
        if func1 then
            func1()
        end
    end,45/30)

    self:waitWithDelay(function()
        self:waitWithDelay(function()
            self.m_bonusGuoChangEffect:setVisible(false)
            self.m_bonusGuoChangEffect:removeFromParent()
            self.m_bonusGuoChangEffect = nil
        end,2)

        if func then
            func()
        end
    end,90/30)
end
--[[
    ---
    显示free spin
]]
function CodeGameScreenBeastlyBeautyMachine:showEffect_FreeSpin(effectData)

    self:removeSoundHandler() -- 移除监听

    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_scatterTrigger_inFree)
    end

    local waitTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                    end
                    slotNode:runAnim("actionframe")
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
    end

    self:waitWithDelay(function()
        self:showFreeSpinView(effectData)
    end,waitTime)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)

    return true
end

--[[
    free玩法结束弹板
]]
function CodeGameScreenBeastlyBeautyMachine:showFreeSpinOverView()

    local strCoins=util_formatCoins(self.m_runSpinResultData.p_fsWinCoins,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeJieSuanGuoChang)
        self:freeGuoChangEffect(function()
            self:setReelBg(1, true)
            self:hideFreeSpinBar()
        end,function()
            self.m_llBigOrMegaNum = self.m_runSpinResultData.p_fsWinCoins or 0
            self:triggerFreeSpinOverCallFun()
        end)  
    end)

    if strCoins ~= "0" then
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},730)

        local random = math.random(1,10)
        if random <= 5 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeJieSuanStart_men)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeJieSuanStart_women)
        end
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeJieSuanOver

        -- 弹板上的光
        local tanbanShine = util_createAnimation("BeastlyBeauty/BeastlyBeauty_tbover_shine.csb")
        view:findChild("Node_shine"):addChild(tanbanShine)
        tanbanShine:runCsbAction("idle",true)

        local guangSpine = util_spineCreate("BeastlyBeauty_tanban_guang", true, true)
        view:findChild("Node_guang1"):addChild(guangSpine)
        util_spinePlay(guangSpine,"idle",true)

        -- 弹板角色
        local jiaose1 = util_spineCreate("Socre_BeastlyBeauty_7", true, true)
        view:findChild("Node_juese1"):addChild(jiaose1)
        util_spinePlay(jiaose1,"actionframe2",true)

        local jiaose2 = util_spineCreate("Socre_BeastlyBeauty_9", true, true)
        view:findChild("Node_juese2"):addChild(jiaose2)
        util_spinePlay(jiaose2,"actionframe2",true)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeJieSuan_noCoins_start)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeJieSuan_noCoins_over

        local guangSpine = util_spineCreate("BeastlyBeauty_tanban_guang", true, true)
        view:findChild("Node_guang2"):addChild(guangSpine)
        util_spinePlay(guangSpine,"idle2",true)
    end
end

--[[
    free玩法结束 两种弹板
]]
function CodeGameScreenBeastlyBeautyMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    if coins == "0" then
        return self:showDialog("FreeSpinOver_0",ownerlist,func)
    else
        --
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
    end
end

--[[
    处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
]]
-- function CodeGameScreenBeastlyBeautyMachine:specialSymbolActionTreatment( node)
--     if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--         local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)

--         symbolNode:runAnim("buling",false,function()
--             symbolNode:runAnim("idleframe2", true)
--         end)
--     end
-- end

--[[
    ---------------- Spin逻辑开始时触发
    用于延时滚动轮盘等
]]
function CodeGameScreenBeastlyBeautyMachine:MachineRule_SpinBtnCall()
    --重置一些标记
    self.m_preWildContinusPos = {}
    self.m_isTriggerLongRun = false

    self:setMaxMusicBGVolume()
   
    if self.m_scheduleId then
        self:showTipsOverView()
    end

    self:stopLinesWinSound()

    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenBeastlyBeautyMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

--------------------添加动画
--[[
    ---
    添加关卡中触发的玩法
]]
function CodeGameScreenBeastlyBeautyMachine:addSelfEffect()
    -- free下 wild上下移动
    if self:getCurrSpinMode() == FREE_SPIN_MODE and #self.m_aFreeSpinWildArry > 0 then
        local wildChangeEffect = GameEffectData.new()
        wildChangeEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        wildChangeEffect.p_effectOrder = self.m_freeSpinWildChange
        wildChangeEffect.p_selfEffectType = self.m_freeSpinWildChange
        self.m_gameEffects[#self.m_gameEffects + 1] = wildChangeEffect
        -- free下 相邻两列3个连续的异性wild 
        if self:isTriggerBigWild2x3() then -- 触发了小格子变化大格子effect
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.m_changeBigSymbolEffect
            selfEffect.p_selfEffectType = self.m_changeBigSymbolEffect
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        end
    end

    -- base下 相邻两列3个连续的异性wild 
    if self:isTriggerBigWild2x3() and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then -- 触发了小格子变化大格子effect
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.m_changeBigSymbolEffect
        selfEffect.p_selfEffectType = self.m_changeBigSymbolEffect
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    end
end

--[[
    是否触发合成2x3wild
]]
function CodeGameScreenBeastlyBeautyMachine:isTriggerBigWild2x3( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if selfData.fix and #selfData.fix > 0 then -- 触发了小格子变化大格子effect
        self.m_preWildContinusPos = selfData.fix
        return true
    end
    return false
end
--[[
    播放玩法动画
    实现自定义动画内容
]]
function CodeGameScreenBeastlyBeautyMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.m_freeSpinWildChange then
        self:freeSpinWildChange(function()
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end)
    elseif effectData.p_selfEffectType == self.m_changeBigSymbolEffect then
        self:baseChangeBigWild(function()
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end)
    elseif effectData.p_selfEffectType == self.m_reSpinWildChange then
        local respinOverColList = {2,3}
        self:changeBigWild2X3(false, respinOverColList, function()
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end)
    end
    
	return true
end

--[[
    合图的时候 获得新旧图标
]]
function CodeGameScreenBeastlyBeautyMachine:getOldAndNewSymbol(Col)
    local bigWild = nil
    local newNodeSymbolType = self.SYMBOL_BIGWILD1X3_1
    local nodeOld = self:getFixSymbol(Col, 1, SYMBOL_NODE_TAG)
    if nodeOld and nodeOld.p_symbolType == self.SYMBOL_WILD2 then
        newNodeSymbolType = self.SYMBOL_BIGWILD1X3_2
    end

    local nodeList = {}
    for _index = 1, self.m_iReelRowNum , 1 do
        local node = self:getFixSymbol(Col, _index, SYMBOL_NODE_TAG)
        if node ~= nil then -- 移除被覆盖度额小块
            table.insert(nodeList,node)
        end
    end

    -- 把这一列的长条信息添加到存储数据中
    self:addBigSymbolInfo(Col, newNodeSymbolType)

    bigWild = self:getSlotNodeWithPosAndType(newNodeSymbolType, 1, Col)
    bigWild.p_slotNodeH = self.m_SlotNodeH*3

    bigWild.m_bInLine = true

    local linePos = {}
    for lineRowIndex = 1, 3 do
        linePos[#linePos + 1] = {
            iX = lineRowIndex,
            iY = Col
        }
    end

    bigWild:setLinePos(linePos)

    return bigWild, nodeList
end

--[[
    base下变大wild
]]
function CodeGameScreenBeastlyBeautyMachine:baseChangeBigWild(_func)
    local isPlaySound = false
    for _bigWildIndex = 1, #self.m_preWildContinusPos do
        for _colIndex, vCol in ipairs(self.m_preWildContinusPos[_bigWildIndex]) do
            local Col = vCol+1
            local bigWild, nodeList = self:getOldAndNewSymbol(Col)
            bigWild:setVisible(false)

            local targSp = self:getFixSymbol(Col, 1, SYMBOL_NODE_TAG)

            local reelParent = self:getReelParent(Col)

            if targSp and targSp.p_symbolType then
                reelParent:addChild(bigWild, 3000 + targSp:getLocalZOrder() + vCol, targSp:getTag())
                bigWild:setPosition(targSp:getPositionX(), targSp:getPositionY())
            else
                local nodePos = util_getPosByColAndRow(self, Col, 1)
                reelParent:addChild(bigWild, 3000 + vCol, 0)
                bigWild:setPosition(nodePos)
            end

            if _colIndex == 2 and _bigWildIndex == #self.m_preWildContinusPos then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild1x3)
            end

            bigWild:runAnim("switch",false,function()
                bigWild:runAnim("switch2",false)
            end)
            self:delayCallBack(0.1, function()
                bigWild:setVisible(true)
            end)
            performWithDelay(self.m_openBonusSkip, function()
                for index=1, #nodeList do
                    local node = nodeList[index]
                    if node then
                        self:moveDownCallFun(node, node.p_cloumnIndex) 
                    end
                end

                if _colIndex == 2 then
                    self:changeBigWild2X3(true, self.m_preWildContinusPos[_bigWildIndex], function()
                        if _bigWildIndex == #self.m_preWildContinusPos then
                            if _func then
                                _func()
                            end
                        end
                    end)
                end
            end, (15+34)/30)
        end
    end

    self.m_openBonusSkip:setVisible(true)
    self.m_bottomUI:setSkipBonusBtnVisible(true)
    self.m_openBonusSkip:setSkipCallBack(function()
        self:quickStoptEffect(_func)
    end)
end

--[[
    隐藏快停
]]
function CodeGameScreenBeastlyBeautyMachine:hideQuickStopBtn( )
    self.m_openBonusSkip:clearSkipCallBack()
    self.m_openBonusSkip:setVisible(false)
    self.m_bottomUI:setSkipBonusBtnVisible(false)
end

--[[
    两个1x3的长条 合成一个2x3的长条
]]
function CodeGameScreenBeastlyBeautyMachine:changeBigWild2X3(isPlaySwitchEffect, colList, func)
    for _colIndex, _vCol in ipairs(colList) do
        local col = _vCol + 1
        local bigWild = nil
        local respinBigWild2X3 = nil
        local nodeList = {}
        for _index = 1, self.m_iReelRowNum , 1 do
            local node = self:getFixSymbol(col, _index, SYMBOL_NODE_TAG)
            if node ~= nil then -- 移除被覆盖度额小块
                table.insert(nodeList,node)
            end
        end
        -- 把这一列的长条信息添加到存储数据中
        self:addBigSymbolInfo(col, self.SYMBOL_BIGWILD2X3)
        if _colIndex == #colList then
            local linePos = {}
            for lineRowIndex = 1, 3 do
                linePos[#linePos + 1] = {iX = lineRowIndex, iY = col}
            end

            bigWild = self:getSlotNodeWithPosAndType(self.SYMBOL_BIGWILD2X3, 1, col)
            bigWild.p_slotNodeH = self.m_SlotNodeH*3
            bigWild.m_bInLine = true

            bigWild:setLinePos(linePos)

            local targSp = self:getFixSymbol(col, 1, SYMBOL_NODE_TAG)
            local reelParent = self:getReelBigParent(col)
            
            if targSp and targSp.p_symbolType then
                reelParent:addChild(bigWild, 3000 + targSp:getLocalZOrder(), targSp:getTag())
                bigWild:setPosition(targSp:getPositionX(), targSp:getPositionY())
            else
                local nodePos = util_getPosByColAndRow(self, col, 1)
                reelParent:addChild(bigWild, 3000, 0)
                bigWild:setPosition(nodePos)
            end

            local actionframe = "idleframe"
            -- 判断是否播放变身的动画
            if isPlaySwitchEffect then
                actionframe = "show"
                -- bigWild:setVisible(false)
                -- respinBigWild2X3 = self:createBigWild2X3(col)
                self:playSoundByChangeBigWild2x3()
            end

            bigWild:runAnim(actionframe,false,function()
                bigWild:runAnim("idleframe2", true)
            end)
            local delayTime = 0
            if isPlaySwitchEffect then
                delayTime = 60/30
            end
            performWithDelay(self.m_openBonusSkip,function()
                if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
                    self:hideQuickStopBtn()
                end

                if respinBigWild2X3 then
                    respinBigWild2X3:removeFromParent()
                    respinBigWild2X3 = nil
                end
                if bigWild then
                    bigWild:setVisible(true)
                end

                --进度条打开 显示收集动画
                if self.m_pregressIsHaveOpen then
                    self:BigWild2X3Fly(bigWild,function()
                        self:collectByEndPregressEffect(function()
                            local features = self.m_runSpinResultData.p_features
                            if #features > 1 and features[2] == 5 then
                                if func then
                                    func()
                                end
                            end
                        end)
                    end)

                    local features = self.m_runSpinResultData.p_features
                    if #features > 1 and features[2] == 5 then
                    else
                        -- 延迟0.3秒 确保先移除不需要的小块 在进行后续操作
                        performWithDelay(self.m_openBonusSkip,function()
                            if func then
                                func()
                            end
                        end,0.3)
                    end
                else
                    performWithDelay(self.m_openBonusSkip,function()
                        if func then
                            func()
                        end
                    end,0.3)
                end
            end,delayTime)
        end
        
        local delayTime = 0
        if isPlaySwitchEffect then
            delayTime = 63/30
        end

        performWithDelay(self.m_openBonusSkip,function()
            --走到这个地方 就不可以 在快停了
            self:hideQuickStopBtn()
            for index=1,#nodeList do
                local node = nodeList[index]
                if node then
                    self:moveDownCallFun(node, node.p_cloumnIndex) 
                end
            end
        end,delayTime)
    end
end

--[[
    播放合成2x3的音效
]]
function CodeGameScreenBeastlyBeautyMachine:playSoundByChangeBigWild2x3( )
    if self.m_isPLayChangeBigWildSound then
        self.m_isPLayChangeBigWildSound = false
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild_trigger)
        local random = math.random(1,10)
        if random <= 5 then
            local randomNew = math.random(1,2)
            if randomNew == 1 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild2x3_men)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild2x3_women)
            end
        end
    end
end

--[[
    收集之后 进度条相关的动画
]]
function CodeGameScreenBeastlyBeautyMachine:collectByEndPregressEffect(func)
    local features = self.m_runSpinResultData.p_features
    if #features > 1 and features[2] == 5 then
        --收集反馈，进度条增长
        self.m_pregress:updateLoadingbar(100,true)
    else
        -- 播放收集相关的动画
        local pecent = self:getProgressPecent()
        --收集反馈，进度条增长
        self.m_pregress:updateLoadingbar(pecent,true)
    end
    
    self.m_pregress:runCsbAction("actionframe",false,function()
        self.m_pregress:runCsbAction("idle",true)
        if #features > 1 and features[2] == 5 then
            if func then
                func()
            end
        end
    end)
end

--[[
    在棋盘上面创建一个 2x3的大图标
]]
function CodeGameScreenBeastlyBeautyMachine:createBigWild2X3(vCol)
    local startWorldPos =  self:getNodePosByColAndRow( 1, vCol)
    local startPos = self.m_respin_action:convertToNodeSpace(startWorldPos)
    local respinBigWild2X3 = self:createNewWildSpine(self.SYMBOL_BIGWILD2X3)
    respinBigWild2X3:setPosition(startPos)
    self.m_respin_action:addChild(respinBigWild2X3, 20)
    self.m_respin_action:setVisible(true)

    util_spinePlay(respinBigWild2X3,"show",false)
    util_spineEndCallFunc(respinBigWild2X3,"show",function()
        util_spinePlay(respinBigWild2X3,"idleframe2",true)
    end)

    return respinBigWild2X3
end

--[[
    添加大信号信息
]]
function CodeGameScreenBeastlyBeautyMachine:addBigSymbolInfo(icol, bigSymbolType)
    local iColumn = self.m_iReelColumnNum
    local iRow = self.m_iReelRowNum

    if not self.m_bigSymbolColumnInfo then
        self.m_bigSymbolColumnInfo = {}
    end
    local rowIndex = 1
    while true do
        if rowIndex > iRow then
            break
        end
        local symbolType = bigSymbolType
        -- 判断是否有大信号内容
        if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil  then
            local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG,changeRows = {}}
            local colDatas = self.m_bigSymbolColumnInfo[icol]
            if colDatas == nil then
                colDatas = {}
                self.m_bigSymbolColumnInfo[icol] = colDatas
            end           

            colDatas[#colDatas + 1] = bigInfo     
            local symbolCount = self.m_bigSymbolInfos[symbolType]
            local hasCount = symbolCount
            bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex
            if symbolCount == hasCount or rowIndex > 1 then  -- 表明从对应索引开始的
                bigInfo.startRowIndex = rowIndex
            else
                bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
            end
            rowIndex = rowIndex + hasCount - 1  -- 跳过上面有的

        end
        rowIndex = rowIndex + 1
    end
end

--[[
    合成一个2x3的图标 收集动画
]]
function CodeGameScreenBeastlyBeautyMachine:BigWild2X3Fly(node, func)
    local moveStartPosWorld = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local moveStartPos = self:findChild("Node_dark"):convertToNodeSpace(moveStartPosWorld)
    moveStartPos.x = moveStartPos.x - self.m_SlotNodeW*0.5
    moveStartPos.y = moveStartPos.y + self.m_SlotNodeH

    local moveEndPosWorld = self.m_pregress:findChild("Node_fly"):getParent():convertToWorldSpace(cc.p(self.m_pregress:findChild("Node_fly"):getPosition()))
    local moveEndPos = self:findChild("Node_dark"):convertToNodeSpace(moveEndPosWorld)

    local actionList = {}

    local flyNode = util_createAnimation("BeastlyBeauty_shouji_tw.csb")
    self:findChild("Node_dark"):addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
    flyNode:setPosition(moveStartPos)

    for i=1,4 do
        flyNode:findChild("Particle_"..i):setDuration(1)     --设置拖尾时间(生命周期)
        flyNode:findChild("Particle_"..i):setPositionType(0)   --设置可以拖尾
    end

    actionList[#actionList + 1] = cc.BezierTo:create(15/30,{cc.p(moveStartPos.x-150, moveStartPos.y), cc.p(moveEndPos.x, moveEndPos.y-150), moveEndPos})
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        if func then
            func()
        end
        self:waitWithDelay(function()
            flyNode:removeFromParent()
            flyNode = nil
        end,0.5)
        
    end)

    local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))

    if self.m_isPLayFlyCollectSound then
        self.m_isPLayFlyCollectSound = false
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_fly_collect)
    end

    flyNode:runAction(cc.Sequence:create(spawnAct))
end

--[[
    freeSpin wild change
    free玩法 wild上下移动
]]
function CodeGameScreenBeastlyBeautyMachine:freeSpinWildChange(_func)
    local delayTime = 0.5
    local runTime = 0.5 
    local isPlaySound = false
    for _index = 1, #self.m_aFreeSpinWildArry, 1 do
        local temp = self.m_aFreeSpinWildArry[_index]
        local iRow = temp.row
        local iCol = temp.col
        local currRow = iRow
        
        local iTempRow = {} --隐藏小块避免穿帮
        if temp.direction == "up" then --    4,3,2 
            currRow =  temp.row + 1 - 3
        end

        local maxZOrder = 0
        local nodeList = {}
        local symbolType = 0
        for _row = 1, self.m_iReelRowNum , 1 do
            local node =  self:getFixSymbol(iCol , _row, SYMBOL_NODE_TAG)
            if node ~= nil and (node.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD and node.p_symbolType ~= self.SYMBOL_WILD2) then -- 移除被覆盖度额小块
                table.insert(nodeList,node)
                if maxZOrder <  node:getLocalZOrder() then
                    maxZOrder = node:getLocalZOrder()
                end
            end
            if node ~= nil and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or node.p_symbolType == self.SYMBOL_WILD2) then
                if maxZOrder <  node:getLocalZOrder() then
                    maxZOrder = node:getLocalZOrder()
                end
                symbolType = node.p_symbolType
            end
        end

        local newNodeSymbolType = self.SYMBOL_BIGWILD1X3_1
        if symbolType == self.SYMBOL_WILD2 then
            newNodeSymbolType = self.SYMBOL_BIGWILD1X3_2
        end

        local posIndex = self:getPosReelIdx(currRow, iCol)
        local targSp = self:getSlotNodeWithPosAndType(newNodeSymbolType, currRow, iCol, false)   

        -- 把这一列的长条信息添加到存储数据中
        self:addBigSymbolInfo( iCol, newNodeSymbolType)

        if targSp then 
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            
            local linePos = {}
            for row = 1,self.m_iReelRowNum do
                linePos[#linePos + 1] = {iX = row, iY = iCol}
            end
            
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
            self:getReelParent(iCol):addChild(targSp,maxZOrder+30, targSp.p_cloumnIndex * SYMBOL_NODE_TAG + targSp.p_rowIndex)
            targSp.p_rowIndex = 1
            

            local pos =  cc.p(self:getPosByColAndRow(iCol, currRow))
            local posEnd =  cc.p(self:getPosByColAndRow(iCol,1))
            if temp.direction == "up" then 
                posEnd =  cc.p(self:getPosByColAndRow(iCol, 1))
            end

            targSp:setPosition(pos)
            
            local distance = posEnd.y
            local actionList = {}
            actionList[#actionList + 1] = cc.MoveTo:create(runTime, cc.p(posEnd.x, posEnd.y))
            actionList[#actionList + 1] = cc.CallFunc:create(function ()
                local newSysbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
                if symbolType ~= 0 then
                    newSysbolType = symbolType
                end

                for index=1,#nodeList do
                    local node = nodeList[index]
                    if node ~= nil and node.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD and node.p_symbolType ~= self.SYMBOL_WILD2 then -- 移除被覆盖度额小块
                        node:changeCCBByName(self:MachineRule_GetSelfCCBName(newSysbolType),newSysbolType)
                        local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(self:getSymbolCCBNameByType(self, newSysbolType))
                        if imageName ~= nil then
                            node:spriteChangeImage(node.p_symbolImage, imageName[1])
                        end
                    end
                end

                self:moveDownCallFun(targSp, targSp.p_cloumnIndex)

                if _index == #self.m_aFreeSpinWildArry then
                    self:waitWithDelay(function()
                        if _func then
                            _func()
                        end
                    end, 0.5)
                end
            end)

            if _index == #self.m_aFreeSpinWildArry then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_freeWildMove)
            end

            self:playFreeMoveEffect(iCol, temp.direction)
            targSp:runAnim("idleframe2")
            local seq = cc.Sequence:create(actionList)
            targSp:runAction(seq)
        end
    end
end

--[[
    free玩法wild上下移动的时候特效
]]
function CodeGameScreenBeastlyBeautyMachine:playFreeMoveEffect(iCol, direction)
    local startWorldPos =  self:getNodePosByColAndRow( 2, iCol)
    local startPos = self.m_respin_action:convertToNodeSpace(startWorldPos)
    local freeMoveEffect = util_createAnimation("BeastlyBeauty_tuiyi.csb")
    freeMoveEffect:setPosition(startPos)
    self.m_respin_action:addChild(freeMoveEffect)
    self.m_respin_action:setVisible(true)
    if direction == "up" then
        freeMoveEffect:runCsbAction("actionframe2",false)
    else
        freeMoveEffect:runCsbAction("actionframe",false)
    end
    self:waitWithDelay(function()
        freeMoveEffect:removeFromParent()
    end,56/60)
end

--[[
    获取棋盘某个位置的坐标
]]
function CodeGameScreenBeastlyBeautyMachine:getPosByColAndRow(col, row)
    local posX = self.m_SlotNodeW
    local posY = (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

--[[
    重新构造free玩法 wild上下移动的信息
]]
function CodeGameScreenBeastlyBeautyMachine:MachineRule_network_InterveneSymbolMap()
    -- free wild上下移动
    for _index = #self.m_aFreeSpinWildArry, 1, -1 do
        table.remove(self.m_aFreeSpinWildArry, _index)
    end

    self.m_aFreeSpinWildArry = {} 

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        for iCol = 1, self.m_iReelColumnNum do --列
            local tempRow = nil
            for iRow = self.m_iReelRowNum, 1, -1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD or self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_WILD2 then
                    tempRow = iRow
                else
                    break
                end
            end
            if tempRow ~= nil and tempRow ~= 1 then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "down"}
            end

            tempRow = nil
            for iRow = 1, self.m_iReelRowNum, 1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD or self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_WILD2 then
                    tempRow = iRow
                else
                    break
                end
            end

            if tempRow ~= nil and tempRow ~= self.m_iReelRowNum then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "up"}
            end
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.collect then
        self.m_bonusConfig.collect = selfData.collect
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBeastlyBeautyMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

--[[
    判断开始respin玩法之前 是否需要拆开合图
]]
function CodeGameScreenBeastlyBeautyMachine:changeSmallWildByRespin( )
    local isNeedBigWild = self:getIsNeedBigWild()
    local isDelay = false
    local colList = {2,6} --判断合图的列
    for i,vCol in ipairs(colList) do
        local node = self:getFixSymbol(vCol, 1, SYMBOL_NODE_TAG)
        if node ~= nil and node.p_symbolType == self.SYMBOL_BIGWILD2X3 then -- 移除被覆盖度额小块
            isDelay = true
            local targSp = node
            
            for iCol = vCol-1, vCol do
                if isNeedBigWild then
                    local newNodeSymbolType = self.SYMBOL_BIGWILD1X3_2
                    if iCol == vCol-1 then
                        newNodeSymbolType = self.SYMBOL_BIGWILD1X3_1
                    end
                    local smallWild = self:getSlotNodeWithPosAndType(newNodeSymbolType, 1, iCol)

                    local reelParent = self:getReelParent(iCol)
                    
                    reelParent:addChild(smallWild, 1 + targSp:getLocalZOrder() - 300, targSp:getTag())

                    smallWild:setPosition(targSp:getPositionX(), targSp:getPositionY())

                    smallWild:runAnim("idleframe", true)
                else
                    for iRow = 1,self.m_iReelRowNum do
                        local newNodeSymbolType = self.SYMBOL_WILD2
                        if iCol == vCol-1 then
                            newNodeSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
                        end
                        local smallWild = self:getSlotNodeWithPosAndType(newNodeSymbolType, iRow, iCol)

                        local reelParent = self:getReelParent(iCol)
                        
                        reelParent:addChild(smallWild, iRow + targSp:getLocalZOrder() - 300, targSp:getTag())

                        if iRow == 1 then
                            smallWild:setPosition(targSp:getPositionX(), targSp:getPositionY())
                        elseif iRow == 2 then
                            smallWild:setPosition(targSp:getPositionX(), targSp:getPositionY()+self.m_SlotNodeH)
                        elseif iRow == 3 then
                            smallWild:setPosition(targSp:getPositionX(), targSp:getPositionY()+2*self.m_SlotNodeH)
                        end
                    end
                end
            end
            local bigWild = self:createBigWildChaiTu(1, vCol)
            self:moveDownCallFun(targSp, targSp.p_cloumnIndex) 

            util_nodeFadeIn(bigWild, 0.5, 255, 0, nil, function()
                bigWild:removeFromParent()
            end)
            
        end
    end

    return isDelay, isNeedBigWild
end

--[[
    拆图的时候 判断是否需要拆成1x3的大图
    如果1 2列 5 6列都合成2x3的大图了
    拆图的时候 需要拆成4个1x3的
    其他情况都拆成1x1的小图
]]
function CodeGameScreenBeastlyBeautyMachine:getIsNeedBigWild()
    local nodeNum = 0
    local colList = {2,6} --判断合图的列
    for i,vCol in ipairs(colList) do
        local node = self:getFixSymbol(vCol, 1, SYMBOL_NODE_TAG)
        if node ~= nil and node.p_symbolType == self.SYMBOL_BIGWILD2X3 then -- 移除被覆盖度额小块
            nodeNum = nodeNum + 1
        end
    end

    if nodeNum > 1 then
        return true
    else
        return false
    end
end

--[[
    拆解合图的时候 创建一个在棋盘之上
]]
function CodeGameScreenBeastlyBeautyMachine:createBigWildChaiTu(row, col)
    local startWorldPos =  self:getNodePosByColAndRow( row, col)
    local startPos = self.m_respin_action:convertToNodeSpace(startWorldPos)
    local bigWild = self:createNewWildSpine(self.SYMBOL_BIGWILD2X3)
    bigWild:setPosition(startPos)
    self.m_respin_action:addChild(bigWild,1)

    util_spinePlay(bigWild,"idleframe",true)

    return bigWild
end
------------  respin 代码 这个respin就是不是单个小格滚动的那种 

function CodeGameScreenBeastlyBeautyMachine:showRespinView(effectData)
    local isDelay, isNeedBigWild = self:changeSmallWildByRespin()
    local isDelayTime = 0
    if isDelay or self.m_isDuanXian then
        isDelayTime = 0.5
    end
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    
    self:clearWinLineEffect()

    self:waitWithDelay(function()
        local callBack = function()
            --先播放动画 再进入respin
            self:setCurrSpinMode( RESPIN_MODE )
            self.m_specialReels = false

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)

            self:waitWithDelay(function()

                -- 隐藏遮罩
                if self.m_qiPanDarkRespin:isVisible() then
                    self.m_qiPanDarkRespin:runCsbAction("over",false,function(  )
                        self.m_qiPanDarkRespin:setVisible(false)
                    end)
                end

            end,130/60)
            
            self.m_qiPanDark:runCsbAction("over",false,function(  )
                self.m_qiPanDark:setVisible(false)
            end)

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_respinAuto)

            -- 添加显示遮罩
            self.m_qiPanDarkRespin:setVisible(true)
            self.m_qiPanDarkRespin:runCsbAction("start",false,function(  )
                self.m_qiPanDarkRespin:runCsbAction("idle",true)
            end)

            self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, function()
                effectData.p_isPlay = true
                self:playEffectNotifyNextSpinCall()

                self.m_isInReSpin = true
            end, BaseDialog.AUTO_TYPE_ONLY)
        end

        -- 避免断线的时候 多余播放触发动画
        if reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount then
            --触发respin
            local delayTime = 0.1
            if isNeedBigWild then
                self:createRespinWild()
            else
                self:createRespinWild(true)
                delayTime = 34/30
            end
            self.m_respin_action:setVisible(true)

            self:waitWithDelay(function()
                self.m_qiPanDark:setVisible(true)
                self.m_qiPanDark:runCsbAction("start",false,function(  )
                    self.m_qiPanDark:runCsbAction("idle",true)
                    -- 把落地已经 提层的先还原
                    self:checkChangeBaseParent()
                end)

                self:waitWithDelay(function()
                    -- 扔花
                    self.m_rengHuaEffect = util_createAnimation("BeastlyBeauty_renghua.csb")
                    self:findChild("Node_effect"):addChild(self.m_rengHuaEffect, 100)
                    self.m_rengHuaEffect:runCsbAction("actionframe",false)
                    
                end,47/30)

                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_respinStart_hua_fly)
                
                util_spinePlay(self.m_respinNvWild,"actionframe2",false)
                util_spinePlay(self.m_respinNanWild,"actionframe2",false)
                util_spineEndCallFunc(self.m_respinNanWild,"actionframe2",function()
                    
                    util_spinePlay(self.m_respinNvWild,"idleframe5",true)
                    util_spinePlay(self.m_respinNanWild,"idleframe5",true)

                    if not tolua.isnull(self.m_rengHuaEffect) then
                        self.m_rengHuaEffect:removeFromParent()
                        self.m_rengHuaEffect = nil
                    end

                    callBack()

                end)
            end,delayTime)
        else
            callBack()
        end
        
    end, isDelayTime)
end

--接收到数据开始停止滚动
function CodeGameScreenBeastlyBeautyMachine:stopRespinRun()
    print("已经得到了数据")
end

--ReSpin开始改变UI状态
function CodeGameScreenBeastlyBeautyMachine:changeReSpinStartUI(respinCount)
   
end

--ReSpin刷新数量
function CodeGameScreenBeastlyBeautyMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
   
    print("dadadad")
end

--ReSpin结算改变UI状态
function CodeGameScreenBeastlyBeautyMachine:changeReSpinOverUI()

end

---
-- 触发respin 玩法
--
function CodeGameScreenBeastlyBeautyMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
    -- 播放震动
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
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenBeastlyBeautyMachine:showEffect_RespinOver(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    self:removeRespinNode()
    -- self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenBeastlyBeautyMachine:showRespinOverView(effectData)

    effectData.p_isPlay = true
    self:triggerReSpinOverCallFun(self.m_lightScore)
    self.m_lightScore = 0
end

function CodeGameScreenBeastlyBeautyMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_preReSpinStoredIcons = nil

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
    else
        if self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.freeSpinCount ~= 0 then
            if #self.m_runSpinResultData.p_features > 1 and self.m_runSpinResultData.p_features[2] == 5 then
            else
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_resWinCoins, GameEffect.EFFECT_RESPIN_OVER)
                self:postReSpinOverTriggerBigWIn(self.m_runSpinResultData.p_resWinCoins)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_resWinCoins, true})
            end
        end
    end

    if self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
        if globalData.slotRunData.freeSpinCount == 0 then
            local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
            if not hasFsOverEffect then
                local fsOverEffect = GameEffectData.new()
                fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
                fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
                self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
            end
        end
    end
    
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()

    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenBeastlyBeautyMachine:showBonusGameView( effectData )
    local features = self.m_runSpinResultData.p_features
    local bonusWinCoins = self.m_runSpinResultData.p_bonusWinCoins
    local bonusTimes = self.m_runSpinResultData.p_bonusExtra.times

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_BonusStart)

    util_spinePlay(self.m_pregress.m_jiManNode, "actionframe", false)
    util_spineEndCallFunc(self.m_pregress.m_jiManNode,"actionframe",function ()
        util_spinePlay(self.m_pregress.m_jiManNode, "idle2", true)
        if features and #features == 2 and features[2] == 5 then
            self.m_bottomUI:checkClearWinLabel()
            local ownerlist = {}
            ownerlist["m_lb_coins"] = self.m_bonusConfig.pick_time

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickStart)

            local view = self:showDialog(BaseDialog.DIALOG_TYPE_BONUS_START, ownerlist, function()

                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickGuoChang)

                self:removeSoundHandler()
                self:resetMusicBg(nil,"BeastlyBeautySounds/music_BeastlyBeauty_pick_bgm.mp3")

                self:bonusGuoChangEffect(function()
                    self.m_bonusGameView:beginBonusEffect(bonusWinCoins, bonusTimes, function()
                        self:playGameEffect()
                    end)
    
                    self:findChild("Node_base"):setVisible(false)
                end, function()
                    self.m_bonusGameView:setVisible(true)
                    self.m_bonusGameView:runCsbAction("show",false,function()
                        self.m_bonusGameView:runCsbAction("idleframe",true)
                    end)
                end)
                
                effectData.p_isPlay = true
    
                self:waitWithDelay(function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                end, 0.1)
    
            end)

            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click
            view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickOver

            -- 弹板上的光
            local tanbanShine = util_createAnimation("BeastlyBeauty/BeastlyBeauty_bonusstart_shine.csb")
            view:findChild("Node_shine"):addChild(tanbanShine)
            tanbanShine:runCsbAction("idle",true)

            -- 弹板上的角色
            local menSpine = util_spineCreate("BeastlyBeauty_tanban_nan", true, true)
            view:findChild("Node_nan"):addChild(menSpine)
            util_spinePlay(menSpine,"idleframe_tanban",true)

            local womenSpine = util_spineCreate("BeastlyBeauty_tanban_nv", true, true)
            view:findChild("Node_nv"):addChild(womenSpine)
            util_spinePlay(womenSpine,"idleframe_tanban",true)

            local guangSpine = util_spineCreate("BeastlyBeauty_tanban_guang", true, true)
            view:findChild("Node_guang2"):addChild(guangSpine)
            util_spinePlay(guangSpine,"idle2",true)
        end
    end)
end

function CodeGameScreenBeastlyBeautyMachine:MachineRule_respinTouchSpinBntCallBack()
    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == RESPIN_MODE then 
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        release_print("STR_TOUCH_SPIN_BTN 触发了 free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        release_print("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            release_print("STR_TOUCH_SPIN_BTN 触发了 normal")
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            release_print("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end 

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN  then  -- 表明滚动了起来。。
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end

function CodeGameScreenBeastlyBeautyMachine:slotReelDown( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName == "idleframe3" then
                local ccbNode = symbolNode:getCCBNode()
                if ccbNode then
                    util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idleframe2", 0.5)
                end
                symbolNode:runAnim("idleframe2", true)
            end
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    
    CodeGameScreenBeastlyBeautyMachine.super.slotReelDown(self)

end

--判断改变 reSpin 的 状态
function CodeGameScreenBeastlyBeautyMachine:changeReSpinModeStatus()
    if self:getCurrSpinMode() == RESPIN_MODE then
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then -- reSpin spin 模式结束
            local effectData = GameEffectData.new()
            effectData.p_effectType = GameEffect.EFFECT_RESPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.m_reSpinWildChange
            selfEffect.p_selfEffectType = self.m_reSpinWildChange
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect

        end

        self:respinChangeBigWild(function()
            self.m_respin_action:setVisible(false)
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                self.m_respin_action:removeAllChildren()
                self.m_respinNvWild = false
                self.m_respinNanWild = false
            end
        end)
    end
end

function CodeGameScreenBeastlyBeautyMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    延时函数
]]
function CodeGameScreenBeastlyBeautyMachine:waitWithDelay(endFunc, time)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(endFunc) == "function" then
                endFunc()
            end
        end,
        time
    )

    return waitNode
end

--[[
    初始化bet信息
]]
function CodeGameScreenBeastlyBeautyMachine:initGameStatusData(gameData)

    CodeGameScreenBeastlyBeautyMachine.super.initGameStatusData(self, gameData)
    self.m_bonusConfig = gameData.gameConfig.extra
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_initSpinData and #self.m_initSpinData.p_features > 1 and self.m_initSpinData.p_features[2] == 3 then
        if self.m_initSpinData.p_reSpinsTotalCount == 0 and self.m_initSpinData.p_reSpinCurCount == 0 and gameData.feature then
            self.m_initSpinData.p_reSpinsTotalCount = gameData.feature.respin.reSpinsTotalCount
            self.m_initSpinData.p_reSpinCurCount = gameData.feature.respin.reSpinCurCount
            self.m_initSpinData.p_resWinCoins = gameData.feature.respin.resWinCoins
        end
    end
end

--[[
    收集小游戏 断线处理
]]
function CodeGameScreenBeastlyBeautyMachine:initFeatureInfo(spinData,featureData)
    if featureData.p_status and featureData.p_status ~= "CLOSED"  then
        self.m_bonusGameView:setVisible(true)
        self.m_bonusGameView:runCsbAction("idleframe",true)
        self.m_bonusGameView:beginBonusEffect(featureData.p_bonus.bsWinCoins, featureData.p_bonus.extra.times, function()
            self:playGameEffect()
        end)

        self:findChild("Node_base"):setVisible(false)

        self:waitWithDelay(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end, 0.1)
    end
end

--[[
    @desc: 
    author:{author}
    time:2022-09-07 10:54:44
    @return:
]]
function CodeGameScreenBeastlyBeautyMachine:isNormalStates( )
    
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

--[[
    解锁进度条
]]
function CodeGameScreenBeastlyBeautyMachine:unlockHigherBet()
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

    self:unLockPregress()
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

--[[
    获取解锁进度条对应的bet
]]
function CodeGameScreenBeastlyBeautyMachine:getMinBet()
    local minBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end
    return minBet
end

--[[
    打开进度条
]]
function CodeGameScreenBeastlyBeautyMachine:unLockPregress(_isFirstComeIn)
    if self.m_pregressIsHaveOpen then
        return
    end
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click)

    util_spinePlay(self.m_pregress.m_suoDingNode1, "unlock", false)
    util_spinePlay(self.m_pregress.m_suoDingNode2, "unlock", false)
    util_spineEndCallFunc(self.m_pregress.m_suoDingNode1,"unlock",function ()
        self.m_pregress.m_suoDingNode1:setVisible(false)
        self.m_pregress.m_suoDingNode2:setVisible(false)
    end)
    if not _isFirstComeIn then
        for _index = 4, 6 do
            self.m_pregress:findChild("Particle_".._index):setVisible(true)
            self.m_pregress:findChild("Particle_".._index):resetSystem()
        end
    else
        for _index = 4, 6 do
            self.m_pregress:findChild("Particle_".._index):setVisible(false)
        end
    end
end

--[[
    上锁进度条
]]
function CodeGameScreenBeastlyBeautyMachine:LockPregress(_isFirstComeIn)
    if not _isFirstComeIn and not self.m_pregressIsHaveOpen then
        return
    end

    self.m_pregress.m_suoDingNode1:setVisible(true)
    self.m_pregress.m_suoDingNode2:setVisible(true)
    util_spinePlay(self.m_pregress.m_suoDingNode1, "lock", false)
    util_spinePlay(self.m_pregress.m_suoDingNode2, "lock", false)
    util_spineEndCallFunc(self.m_pregress.m_suoDingNode1,"lock",function ()
        util_spinePlay(self.m_pregress.m_suoDingNode1, "idle1", true)
        util_spinePlay(self.m_pregress.m_suoDingNode2, "idle1", true)
    end)
end

--[[
    计算进度条百分比
]]
function CodeGameScreenBeastlyBeautyMachine:getProgressPecent()
    
    local percent = (self.m_bonusConfig.collect / self.m_bonusConfig.need * 100) > 100 and 100 or self.m_bonusConfig.collect / self.m_bonusConfig.need * 100

    return percent or 0
end

--[[
    bonus 玩法结算弹板
]]
function CodeGameScreenBeastlyBeautyMachine:showBonusGameOverView(coins, func, func1)

    self:clearCurMusicBg()

    local bonusOverView = util_createView("CodeBeastlyBeautySrc.BeastlyBeautyBonusGameOverView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        bonusOverView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(bonusOverView)
    bonusOverView:initViewData(self,coins, function()

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickJieSuanGuoChang)

        self:bonusGuoChangEffect(function()
            if func1 then
                func1()
            end
        end,function()
            if func then
                self:findChild("Node_base"):setVisible(true)
                func()
            end
        end)
    end)
end

--[[
    检查是否更新金币
]]
function CodeGameScreenBeastlyBeautyMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        isNotifyUpdateTop = false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        if self.m_runSpinResultData.p_reSpinCurCount == 0 and self.m_runSpinResultData.p_fsWinCoins > self.m_runSpinResultData.p_resWinCoins then
            globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins
        else
            globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_resWinCoins + self.m_runSpinResultData.p_fsWinCoins
        end
        self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_winAmount
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

--[[
    增加赢钱后的 效果
]]
function CodeGameScreenBeastlyBeautyMachine:addLastWinSomeEffect() -- add big win or mega win
    if self:getCurrSpinMode() == RESPIN_MODE then
        --respin最后一次 弹板显示总赢钱
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_resWinCoins
        end
    end
    CodeGameScreenBeastlyBeautyMachine.super.addLastWinSomeEffect(self)
end

function CodeGameScreenBeastlyBeautyMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    end
    -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenBeastlyBeautyMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = CodeGameScreenBeastlyBeautyMachine.super.checkTriggerINFreeSpin(self)

    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        if self.m_runSpinResultData.p_resWinCoins and self.m_runSpinResultData.p_resWinCoins > 0 then
            -- 发送事件显示赢钱总数量
            local params = {self.m_runSpinResultData.p_resWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        end
    end

    return isPlayGameEff
end

--[[
    显示所有的连线框
]]
function CodeGameScreenBeastlyBeautyMachine:showAllFrame(winLines)
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
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                local node = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                if node ~= nil and node.p_symbolType ~= self.SYMBOL_BIGWILD2X3 and 
                node.p_symbolType ~= self.SYMBOL_BIGWILD1X3_1 and node.p_symbolType ~= self.SYMBOL_BIGWILD1X3_2 then
                    addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                    local columnData = self.m_reelColDatas[symPosData.iY]

                    local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen()

                    local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
                    local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY

                    local node = self:getFrameWithPool(lineValue, symPosData)
                    node:setPosition(cc.p(posX, posY))

                    checkIndex = checkIndex + 1
                    self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
                end
            end
        end
    end
end


function CodeGameScreenBeastlyBeautyMachine:showLineFrame()
    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
        self.m_showLineHandlerID = nil
    end
    CodeGameScreenBeastlyBeautyMachine.super.showLineFrame(self)
end
--[[
    逐条线显示 线框和 Node 的actionframe
]]
function CodeGameScreenBeastlyBeautyMachine:showLineFrameByIndex(winLines, frameIndex)
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
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            -- end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end
    local checkIndex = 0

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local node = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
        if node ~= nil and node.p_symbolType ~= self.SYMBOL_BIGWILD2X3 and 
        node.p_symbolType ~= self.SYMBOL_BIGWILD1X3_1 and node.p_symbolType ~= self.SYMBOL_BIGWILD1X3_2 then

            local columnData = self.m_reelColDatas[symPosData.iY]

            local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
            local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
            -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

            local node = nil
            -- if i <= hasCount then
            --     node = inLineFrames[#inLineFrames]
            --     inLineFrames[#inLineFrames] = nil
            -- else
                node = self:getFrameWithPool(lineValue, symPosData)
            -- end
            node:setPosition(cc.p(posX, posY))

            checkIndex = checkIndex + 1
            if node:getParent() == nil then
                if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                    self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
                else
                    self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
                end

                -- if runTimes ~= nil then
                --     node:runDefaultFrameTime(runTimes)
                -- else
                --     node:runDefaultAnim()
                -- end
                node:runAnim("actionframe", true)
            else
                node:runAnim("actionframe", true)
                node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end

    self:showEachLineSlotNodeLineAnim(frameIndex)
end

--[[
    播放在线上的SlotsNode 动画
]]
function CodeGameScreenBeastlyBeautyMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 or slotsNode.p_symbolType == self.SYMBOL_BIGWILD1X3_1 or slotsNode.p_symbolType == self.SYMBOL_BIGWILD1X3_2 then 
                local symbol_node = slotsNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                if self.m_isInReSpin then
                    if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 then
                        spineNode:setSkin("x5")
                    else
                        spineNode:setSkin("x2")
                    end
                else
                    if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 then
                        spineNode:setSkin("x2")
                    else
                        spineNode:setSkin("x1")
                    end
                end
            end
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

--[[
    播放连线动画 显示成倍
]]
function CodeGameScreenBeastlyBeautyMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 or slotsNode.p_symbolType == self.SYMBOL_BIGWILD1X3_1 or slotsNode.p_symbolType == self.SYMBOL_BIGWILD1X3_2 then 
                        local symbol_node = slotsNode:checkLoadCCbNode()
                        local spineNode = symbol_node:getCsbAct()
                        if self.m_isInReSpin then
                            if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 then
                                spineNode:setSkin("x5")
                            else
                                spineNode:setSkin("x2")
                            end
                        else
                            if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 then
                                spineNode:setSkin("x2")
                            else
                                spineNode:setSkin("x1")
                            end
                        end
                    end
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

--[[
    播放在线上的SlotsNode 动画
]]
function CodeGameScreenBeastlyBeautyMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 or slotsNode.p_symbolType == self.SYMBOL_BIGWILD1X3_1 or slotsNode.p_symbolType == self.SYMBOL_BIGWILD1X3_2 then 
                local symbol_node = slotsNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                if self.m_isInReSpin then
                    if slotsNode.p_symbolType == self.SYMBOL_BIGWILD2X3 then
                        spineNode:setSkin("x5")
                    else
                        spineNode:setSkin("x2")
                    end
                else
                    spineNode:setSkin("x1")
                end
            end
            slotsNode:runIdleAnim()
        end
    end
end

--[[
    获取轮盘结果 特殊图标个数
]]
function CodeGameScreenBeastlyBeautyMachine:getNumByScatterAndWild( )
    local scatterNum = 0 -- 前5列超过2个将会触发free快滚 两个快滚同时触发 优先free快滚
    local wildNumByCol = 0 --第一列wild数量 第一列全部wild将会触发respin快滚
    for iCol = 1, self.m_iReelColumnNum-1 do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self:getSpinResultReelsType(iCol, iRow)
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterNum = scatterNum + 1
            end
            if iCol == 1 then
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    wildNumByCol = wildNumByCol + 1
                end
            end
        end
    end

    -- 是否有快滚
    local showScatterQuick = false
    local showWildQuick = false

    if scatterNum >= 2 then
        showScatterQuick = true
    end

    if wildNumByCol >= 3 then
        showWildQuick = true
    end

    return showScatterQuick, showWildQuick
end

--[[
    设置长滚信息
]]
function CodeGameScreenBeastlyBeautyMachine:setReelRunInfo()
    -- 是否有快滚
    local showScatterQuick = false
    local showWildQuick = false
    showScatterQuick, showWildQuick = self:getNumByScatterAndWild()

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
        
        -- 只有respin快滚
        if showWildQuick and not showScatterQuick then
            bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_WILD, col , bonusNum, bRunLong)
        else
            --统计bonus scatter 信息
            scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        end
        
    end --end  for col=1,iColumn do

end

--[[
    设置bonus scatter 信息
]]
function CodeGameScreenBeastlyBeautyMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then 
        bRun = true
        bPlayAni = true
    end
    
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then 
        soundType, nextReelLong = self:getRunStatusByWild(column, allSpecicalSymbolNum, showCol)
    else
        if self.m_isPlayYuGaoEffect then
            soundType, nextReelLong = runStatus.DUANG, false
        else
            soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
        end
    end

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then 
                    soundType, nextReelLong = self:getRunStatusByWild(column, allSpecicalSymbolNum, showCol)
                else
                    if self.m_isPlayYuGaoEffect then
                        soundType, nextReelLong = runStatus.DUANG, false
                    else
                        soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                    end
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

--[[
    返回本组下落音效和是否触发长滚效果
]]
function CodeGameScreenBeastlyBeautyMachine:getRunStatusByWild(col, nodeNum, showCol)
    if col == 5 then
        return runStatus.DUANG, true
    else
        return runStatus.DUANG, false
    end
end

---
--[[
    添加金边 快滚框相关
]]
function CodeGameScreenBeastlyBeautyMachine:creatReelRunAnimation(col)
    -- 是否有快滚
    local showScatterQuick = false
    local showWildQuick = false
    showScatterQuick, showWildQuick = self:getNumByScatterAndWild()

    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")
    -- 只有respin快滚
    for i=1,3 do
        util_getChildByName(reelEffectNode, "Node_"..i):setVisible(false)
    end

    -- 只有respin快滚
    if showWildQuick and not showScatterQuick then
        util_getChildByName(reelEffectNode, "Node_2"):setVisible(true)
        if reelEffectNode.m_huaban1 then
            util_spinePlay(reelEffectNode.m_huaban1, "actionframe", true)
            util_spinePlay(reelEffectNode.m_huaban2, "actionframe", true)
        else
            reelEffectNode.m_huaban1 = util_spineCreate("WinFrameBeastlyBeauty_run", true, true)
            util_getChildByName(reelEffectNode, "spine_hua"):addChild(reelEffectNode.m_huaban1)
            reelEffectNode.m_huaban2 = util_spineCreate("WinFrameBeastlyBeauty_run1", true, true)
            util_getChildByName(reelEffectNode, "spine_hua"):addChild(reelEffectNode.m_huaban2)

            util_spinePlay(reelEffectNode.m_huaban1, "actionframe", true)
            util_spinePlay(reelEffectNode.m_huaban2, "actionframe", true)

        end
        -- 前五列有超过2个scatter不压暗
        local scatterNum = 0
        for iCol = 1, 5  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp and targSp.p_symbolType then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        scatterNum = scatterNum + 1
                    end
                end
            end
        end
        if scatterNum <= 1 then
            -- 添加显示遮罩
            self.m_qiPanDarkRespin:setVisible(true)
            self.m_qiPanDarkRespin:runCsbAction("start",false,function(  )
                self.m_qiPanDarkRespin:runCsbAction("idle",true)
            end)
        end
    elseif showWildQuick and showScatterQuick then --两个快滚都有
        util_getChildByName(reelEffectNode, "Node_3"):setVisible(true)
    else--只有free快滚
        util_getChildByName(reelEffectNode, "Node_1"):setVisible(true)
    end
    
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end
        -- 只有respin快滚
        for i=1,3 do
            util_getChildByName(reelEffectNodeBG, "Node_"..i):setVisible(false)
        end

        -- 只有respin快滚
        if showWildQuick and not showScatterQuick then
            util_getChildByName(reelEffectNodeBG, "Node_2"):setVisible(true)
        elseif showWildQuick and showScatterQuick then --两个快滚都有
            util_getChildByName(reelEffectNodeBG, "Node_3"):setVisible(true)
        else--只有free快滚
            util_getChildByName(reelEffectNodeBG, "Node_1"):setVisible(true)
        end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenBeastlyBeautyMachine:beginReel( )

    CodeGameScreenBeastlyBeautyMachine.super.beginReel(self)

    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_respin_action:setVisible(true)
        local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
        if reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount then
            self:createRespinWild()
        end

        if not self.m_qiPanDark:isVisible() then
            self.m_qiPanDark:setVisible(true)
            self.m_qiPanDark:runCsbAction("start",false,function(  )
                self.m_qiPanDark:runCsbAction("idle",true)
                -- 把落地已经 提层的先还原
                self:checkChangeBaseParent()
            end)
        end
        -- 棋盘遮罩 的花瓣
        local huaban = util_createAnimation("BeastlyBeauty_respin_huanban.csb")
        self:findChild("Node_dark"):addChild(huaban,100)
        self:waitWithDelay(function()
            huaban:removeFromParent()
        end,4)
    else
        self.m_isInReSpin = false
    end

    self.m_isDuanXian = false

    self.m_isPlayYuGaoEffect = false

    self.m_isPlayBulingSound = true

    self.m_isPLayChangeBigWildSound = true

    self.m_isPLayFlyCollectSound = true
end

--[[
    创建respin移动的wild
]]
function CodeGameScreenBeastlyBeautyMachine:createRespinWild(isPlaySwitch)
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local colList = {1,6}
    if reSpinCurCount == 1 then 
        colList = {2,5}
    elseif reSpinCurCount == 0 then 
        colList = {3,4}
    end
    -- 女角色
    if not self.m_respinNvWild then
        local startWorldPos =  self:getNodePosByColAndRow( 1, colList[1])
        local startPos = self.m_respin_action:convertToNodeSpace(startWorldPos)
        self.m_respinNvWild = self:createNewWildSpine(self.SYMBOL_BIGWILD1X3_1)
        self.m_respinNvWild:setPosition(startPos)
        self.m_respin_action:addChild(self.m_respinNvWild,2)
        if isPlaySwitch then
            util_spinePlay(self.m_respinNvWild,"switch",false)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild1x3)
        else
            util_spinePlay(self.m_respinNvWild,"idleframe",true)
        end
    end

    -- 男角色
    if not self.m_respinNanWild then
        local startWorldPos =  self:getNodePosByColAndRow( 1, colList[2])
        local startPos = self.m_respin_action:convertToNodeSpace(startWorldPos)
        self.m_respinNanWild = self:createNewWildSpine(self.SYMBOL_BIGWILD1X3_2)
        self.m_respinNanWild:setPosition(startPos)
        self.m_respin_action:addChild(self.m_respinNanWild,1)
        if isPlaySwitch then
            util_spinePlay(self.m_respinNanWild,"switch",false)
        else
            util_spinePlay(self.m_respinNanWild,"idleframe",true)
        end
    end
end 

function CodeGameScreenBeastlyBeautyMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

--[[
    respin玩法开始移动
]]
function CodeGameScreenBeastlyBeautyMachine:beginMoveRespinWild(func)
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_respinBigWildMove)

    if reSpinCurCount == 1 then --表示第一次移动
        util_spinePlay(self.m_respinNvWild,"actionframe3",false)
        util_spinePlay(self.m_respinNanWild,"actionframe3",false)

        self:waitWithDelay(function()
            local startWorldPos1 =  self:getNodePosByColAndRow( 1, 2)
            local startPos1 = self.m_respin_action:convertToNodeSpace(startWorldPos1)
            if not tolua.isnull(self.m_respinNvWild) then
                self.m_respinNvWild:setPosition(startPos1)
                util_spinePlay(self.m_respinNvWild,"idleframe3",true)
            end

            local startWorldPos2 =  self:getNodePosByColAndRow( 1, 5)
            local startPos2 = self.m_respin_action:convertToNodeSpace(startWorldPos2)
            if not tolua.isnull(self.m_respinNanWild) then
                self.m_respinNanWild:setPosition(startPos2)
                util_spinePlay(self.m_respinNanWild,"idleframe3",true)
            end

            self.m_qiPanDark:runCsbAction("over",false,function(  )
                self.m_qiPanDark:setVisible(false)
            end)

            if func then
                func()
            end
        end,30/30)
    elseif reSpinCurCount == 0 then --表示第二次移动
        util_spinePlay(self.m_respinNvWild,"actionframe4",false)
        util_spinePlay(self.m_respinNanWild,"actionframe4",false)

        self:waitWithDelay(function()
            local startWorldPos1 =  self:getNodePosByColAndRow( 1, 3)
            local startPos1 = self.m_respin_action:convertToNodeSpace(startWorldPos1)
            if not tolua.isnull(self.m_respinNvWild) then
                self.m_respinNvWild:setPosition(startPos1)
                util_spinePlay(self.m_respinNvWild,"idleframe4",true)
            end

            local startWorldPos2 =  self:getNodePosByColAndRow( 1, 4)
            local startPos2 = self.m_respin_action:convertToNodeSpace(startWorldPos2)
            if not tolua.isnull(self.m_respinNanWild) then
                self.m_respinNanWild:setPosition(startPos2)
                util_spinePlay(self.m_respinNanWild,"idleframe4",true)
            end

            self.m_qiPanDark:runCsbAction("over",false,function(  )
                self.m_qiPanDark:setVisible(false)
            end)
        end,60/30)

        self:waitWithDelay(function()

            self:changeBigWildByRespin2X3(function()
                if func then
                    func()
                end
            end)
        end,45/30)
    end
end

--[[
    respin玩法合成2x3的大图 
]]
function CodeGameScreenBeastlyBeautyMachine:changeBigWildByRespin2X3(func)
    local startWorldPos =  self:getNodePosByColAndRow( 1, 4)
    local startPos = self.m_respin_action:convertToNodeSpace(startWorldPos)
    local respinBigWild2X3 = self:createNewWildSpine(self.SYMBOL_BIGWILD2X3)
    respinBigWild2X3:setPosition(startPos)
    self.m_respin_action:addChild(respinBigWild2X3, 20)

    util_spinePlay(respinBigWild2X3,"show",false)
    util_spineEndCallFunc(respinBigWild2X3,"show",function()
        util_spinePlay(respinBigWild2X3,"idleframe2",true)
    end)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild_trigger)
    local random = math.random(1,10)
    if random <= 5 then
        local randomNew = math.random(1,2)
        if randomNew == 1 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild2x3_men)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_changeBigWild2x3_women)
        end
    end

    self:waitWithDelay(function()
        if func then
            func()
        end
    end,60/30)
end

--[[
    创建一个新的wild spine
]]
function CodeGameScreenBeastlyBeautyMachine:createNewWildSpine(symbolType)
    local newWildSpineName = self:getSymbolCCBNameByType(self,symbolType)

    local newWildSpine = util_spineCreate(newWildSpineName, true, true)

    return newWildSpine
end

--[[
    respin玩法 棋盘上的1x1小块 直接变成1x3
]]
function CodeGameScreenBeastlyBeautyMachine:respinChangeBigWild(func)
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local preWildContinusPos = {1, 6}
    if reSpinCurCount == 1 then --表示第一次移动
        preWildContinusPos = {2, 5}
    elseif reSpinCurCount == 0 then --表示第二次移动
        preWildContinusPos = {3, 4}
    end

    local isPlaySound = false
    for _index, _vCol in ipairs(preWildContinusPos) do
        local bigWild, nodeList = self:getOldAndNewSymbol(_vCol)

        if reSpinCurCount == 1 then
            bigWild:runAnim("idleframe3",false)
        elseif reSpinCurCount == 0 then
            bigWild:runAnim("idleframe4",false)
        else
            bigWild:runAnim("idleframe",false)
        end

        local targSp = self:getFixSymbol(_vCol, 1, SYMBOL_NODE_TAG)

        local reelParent = self:getReelParent(_vCol)

        if targSp and targSp.p_symbolType then
            reelParent:addChild(bigWild, 30 + targSp:getLocalZOrder(), targSp:getTag())
            bigWild:setPosition(targSp:getPositionX(), targSp:getPositionY())
        else
            local nodePos = util_getPosByColAndRow(self, _vCol, 1)
            reelParent:addChild(bigWild, 30, 0)
            bigWild:setPosition(nodePos)
        end

        if _index == #preWildContinusPos then
            if func then
                func()
            end
        end

        for _nodeIndex = 1, #nodeList do
            local node = nodeList[_nodeIndex]
            if node then
                self:moveDownCallFun(node, node.p_cloumnIndex) 
            end
        end
    end

end

--[[
    播放预告中奖
]]
function CodeGameScreenBeastlyBeautyMachine:playYuGaoAct(func)
    self.m_yugaoEffect:setVisible(true)
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_yugao)

    util_spinePlay(self.m_yugaoEffect,"actionframe",false)

    util_spineEndCallFunc(self.m_yugaoEffect,"actionframe",function ()
        self.m_yugaoEffect:setVisible(false)

        if func then
            func()
        end
    end)
end

--[[
    服务器返回消息之后 处理预告等逻辑
]]
function CodeGameScreenBeastlyBeautyMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local callBack = function()
        self:produceSlots()

        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end

        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        self:beginMoveRespinWild(function()
            callBack()
        end)
    else
        if self.m_bProduceSlots_InFreeSpin then
            callBack()
        else
            local features = self.m_runSpinResultData.p_features or {}
            if #features >= 2 and features[2] == 1 then
                -- c出现预告动画概率40%
                local yuGaoId = math.random(1, 10)
                if yuGaoId <= 4 then
                    -- 播放预告动画 之后 不在播放快滚
                    self.m_isPlayYuGaoEffect = true
                    self:playYuGaoAct(function()
                        callBack()
                    end)
                else
                    callBack()
                end
            else
                callBack()
            end
        end
    end
end

--[[
    bonus玩法 结束之后 判断有没有触发其他玩法
]]
function CodeGameScreenBeastlyBeautyMachine:featuresOverAddFreespinEffect(featureData)
    local featureDatas = featureData.features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = featureData.freespin.freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = featureData.freespin.freeSpinsTotalCount

            self.m_iFreeSpinTimes = featureData.freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
            globalData.slotRunData.iReSpinCount = featureData.respin.reSpinCurCount
            self.m_runSpinResultData.p_reSpinCurCount = featureData.respin.reSpinCurCount
            self.m_runSpinResultData.p_reSpinsTotalCount = featureData.respin.reSpinsTotalCount

            local respinEffect = GameEffectData.new()
            respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
            respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN

            self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

            --发送测试特殊玩法
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
        end
    end
end

--[[
    连线播大赢前光效
]]
function CodeGameScreenBeastlyBeautyMachine:showEffect_BigWinLight(func)

    self.m_bigwinEffect:setVisible(true)
    self.m_bigwinEffect1:setVisible(true)
    self.m_bigwinEffectLiZi:setVisible(true)

    local actionName = "actionframe"
    if self.m_bProduceSlots_InFreeSpin then
        actionName = "actionframe1"
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_bigWin)

    self:shakeNode()

    util_spinePlay(self.m_bigwinEffect,actionName)
    util_spineEndCallFunc(self.m_bigwinEffect,actionName,function()
        self.m_bigwinEffect:setVisible(false)
        self.m_bigwinEffect1:setVisible(false)
        self.m_bigwinEffectLiZi:setVisible(false)

        if func then
            func()
        end
    end)

    util_spinePlay(self.m_bigwinEffect1,"actionframe")
    for i=1,4 do
        self.m_bigwinEffectLiZi:findChild("Particle_"..i):resetSystem()
    end
end

--[[
    wild respin玩法每次滚动 有连线的话 停留时间加长
]]
function CodeGameScreenBeastlyBeautyMachine:playEffectNotifyNextSpinCall()
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
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        local delayTime = 0.5
        if self.m_runSpinResultData.p_reSpinCurCount ~= self.m_runSpinResultData.p_reSpinsTotalCount then
            delayTime = delayTime + self:getWinCoinTime()
        end

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenBeastlyBeautyMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(1, parentData.cloumnIndex)
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

---
--[[
    显示赢钱掉落金币动画
]]
function CodeGameScreenBeastlyBeautyMachine:showEffect_NormalWin(effectData)
    local features = self.m_runSpinResultData.p_features
    if #features >= 2 and features[2] == 3 then
        self:waitWithDelay(function()
            effectData.p_isPlay = true -- 临时写法
            self:playGameEffect()
        end,2)
    else
        effectData.p_isPlay = true -- 临时写法
        self:playGameEffect()
    end

    return true
end

--[[
    适配
]]
function CodeGameScreenBeastlyBeautyMachine:scaleMainLayer()
    CodeGameScreenBeastlyBeautyMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.78
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.86 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.92 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.98 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
end

--[[
    棋盘震动
]]
function CodeGameScreenBeastlyBeautyMachine:shakeNode()
    local changePosY = 15
    local changePosX = 7.5
    local actionList2 = {}
    local oldPos = cc.p(self:findChild("root"):getPosition())

    for i=1,4 do
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

--下面内容基本都是快停相关
function CodeGameScreenBeastlyBeautyMachine:getBottomUINode( )
    return "CodeBeastlyBeautySrc.BeastlyBeautyBottomUI"
end

-- 快停直接显示合图结果
function CodeGameScreenBeastlyBeautyMachine:quickStoptEffect(_func)
    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then -- 自动 模式
        return
    end
    --不存在合图数据包
    if not self.m_preWildContinusPos or #self.m_preWildContinusPos < 1 then
        return
    end

    self.m_openBonusSkip:stopAllActions()
    self.m_respin_action:removeAllChildren()

    for _index, _colList in ipairs(self.m_preWildContinusPos) do
        for _colIndex, _vCol in ipairs(_colList) do
            local Col = _vCol + 1 
            local reelParent = self:getReelParent(Col)
            local childNode = reelParent:getChildren()
            for _, _node in ipairs(childNode) do
                if _node.p_symbolType == self.SYMBOL_BIGWILD1X3_1 or _node.p_symbolType == self.SYMBOL_BIGWILD1X3_2 or _node.p_symbolType == self.SYMBOL_BIGWILD2X3 then
                    if not tolua.isnull(_node) then
                        self:moveDownCallFun(_node, _node.p_cloumnIndex) 
                    end
                end
            end
        end

        self:changeBigWild2X3(false, _colList, function()
            if _index == 1 then
                if _func then
                    _func()
                end
            end
        end)
    end
    
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenBeastlyBeautyMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeBeastlyBeautySrc.BeastlyBeautyDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

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

function CodeGameScreenBeastlyBeautyMachine:MachineRule_BackAction(slotParent, parentData)
    local moveTime = self.m_configData.p_reelResTime
    if self:getGameSpinStage() == QUICK_RUN then
        moveTime = 0.3
    end
    if parentData.cloumnIndex == 6 then
        -- 隐藏遮罩
        if self.m_qiPanDarkRespin:isVisible() then
            self.m_qiPanDarkRespin:runCsbAction("over",false,function(  )
                self.m_qiPanDarkRespin:setVisible(false)
            end)
        end
    end
    local back = cc.MoveTo:create(moveTime, cc.p(slotParent:getPositionX(), parentData.moveDistance))
    return back, self.m_configData.p_reelResTime
end

function CodeGameScreenBeastlyBeautyMachine:operaBigSymbolShowMask(childNode)
    -- 这行是获取每列的显示行数， 为了适应多不规则轮盘
    local colIndex = childNode.p_cloumnIndex
    local columnData = self.m_reelColDatas[colIndex]
    local rowCount = self:getBigSymbolMaskRowCount(colIndex)

    local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
    local startRowIndex = childNode.p_rowIndex

    local chipH = 0
    if startRowIndex < 1 then -- 起始格子在屏幕的下方
        chipH = (symbolCount + startRowIndex - 1) * columnData.p_showGridH
    elseif startRowIndex > 1 then -- 起始格子在屏幕上方
        local diffCount = startRowIndex + symbolCount - 1 - rowCount
        if diffCount > 0 then
            chipH = (symbolCount - diffCount) * columnData.p_showGridH
        else
            chipH = symbolCount * columnData.p_showGridH
        end
    else -- 起始格子处于屏幕范围内
        chipH = symbolCount * columnData.p_showGridH
    end

    local clipY = 0
    if startRowIndex < 1 then
        clipY = math.abs((startRowIndex - 1) * columnData.p_showGridH)
    end

    clipY = clipY - columnData.p_showGridH * 0.5

    -- local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + colIndex)
    local clipNode = self:getClipNodeForTage(CLIP_NODE_TAG + colIndex)
    local reelW = clipNode:getClippingRegion().width * 2

    childNode:showBigSymbolClip(clipY, reelW, chipH)
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenBeastlyBeautyMachine:showBigWinLight(func)

    self.m_bigwinEffect:setVisible(true)
    self.m_bigwinEffect1:setVisible(true)
    self.m_bigwinEffectLiZi:setVisible(true)

    local actionName = "actionframe"
    if self.m_bProduceSlots_InFreeSpin then
        actionName = "actionframe1"
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BeastlyBeauty_bigWin)

    self:shakeNode()

    util_spinePlay(self.m_bigwinEffect,actionName)
    util_spineEndCallFunc(self.m_bigwinEffect,actionName,function()
        self.m_bigwinEffect:setVisible(false)
        self.m_bigwinEffect1:setVisible(false)
        self.m_bigwinEffectLiZi:setVisible(false)

        if func then
            func()
        end
    end)

    util_spinePlay(self.m_bigwinEffect1,"actionframe")
    for i=1,4 do
        self.m_bigwinEffectLiZi:findChild("Particle_"..i):resetSystem()
    end
end

return CodeGameScreenBeastlyBeautyMachine






