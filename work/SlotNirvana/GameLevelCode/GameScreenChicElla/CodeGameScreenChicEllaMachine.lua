---
-- island li
-- 2019年1月26日
-- CodeGameScreenChicEllaMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local ChicEllaMusic = util_require("CodeChicEllaSrc.ChicEllaMusic")
local CodeGameScreenChicEllaMachine = class("CodeGameScreenChicEllaMachine", BaseNewReelMachine)

CodeGameScreenChicEllaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenChicEllaMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenChicEllaMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenChicEllaMachine.SYMBOL_JACKPOT = 94

CodeGameScreenChicEllaMachine.RS_WILD_OPACITY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 53
CodeGameScreenChicEllaMachine.FS_WILD_OPACITY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 52
-- CodeGameScreenChicEllaMachine.FS_ADD_TIMES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 51
CodeGameScreenChicEllaMachine.FS_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50

CodeGameScreenChicEllaMachine.RS_WILD_ADD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 48

CodeGameScreenChicEllaMachine.JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 46

CodeGameScreenChicEllaMachine.FS_X2_DELAY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 45



CodeGameScreenChicEllaMachine.wildOpacity = 0.5


local util_setSymbolToClipReel = function (_MainClass, _iCol, _iRow, _type, _zorder)
    local targSp = _MainClass:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = _MainClass:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(_MainClass, index)
        local showOrder = _MainClass:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent(false)
        _MainClass.m_clipParent:addChild(targSp, _zorder + SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

-- local util_setSymbolToClipReel = function (_MainClass, _iCol, _iRow, _type, _zorder)
--     local targSp = _MainClass:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
--     if targSp ~= nil then
--         local index = _MainClass:getPosReelIdx(_iRow, _iCol)
--         local pos = util_getOneGameReelsTarSpPos(_MainClass, index)
--         local showOrder = _MainClass:getBounsScatterDataZorder(_type) - _iRow
--         targSp.m_showOrder = showOrder
--         targSp.p_showOrder = showOrder
--         targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
--         targSp:removeFromParent(false)
--         _MainClass.m_clipParent:addChild(targSp, _zorder + showOrder, targSp:getTag())
--         targSp:setPosition(cc.p(pos.x, pos.y))
--     end
--     return targSp
-- end


-- 构造函数
function CodeGameScreenChicEllaMachine:ctor()
    CodeGameScreenChicEllaMachine.super.ctor(self)
    self.m_lightScore = 0
    self.m_isFeatureOverBigWinInFree = true

    -- fs锁定位置 位置=倍数
    self.m_fsWildLockData = {}

    self.m_fsWildMultiPos = {} -- 记录单轮触发乘倍位置

    self.m_fsReplaceWildPosSymbol = {}

    self.m_spinRestMusicBG = true

    self.m_jackpotWin = {}

    self.m_isPlayWinningNotice = false

    self.m_symbolUpZOrderArray = {}

    self.m_isJackpotFastRun = {}
    for iCol = 1, 5 do
        self.m_isJackpotFastRun[iCol] = false
    end

    self.IsRespinColumnInit = false
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

	--init
	self:initGame()
end

function CodeGameScreenChicEllaMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ChicEllaConfig.csv", "LevelChicEllaConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenChicEllaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ChicElla"  
end




function CodeGameScreenChicEllaMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_fsWildLockNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_fsWildLockNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5000)

    self.m_rsWildLockNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_rsWildLockNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5001)

    

    -- self:initFreeSpinBar() -- FreeSpinbar

    -- 创建jackpot Bar
    self.m_jackPotBar = util_createView("CodeChicEllaSrc.ChicEllaJackPotBarView")
    -- self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:setVisible(true)

    local pos = util_convertToNodeSpace(self:findChild("Node_jackpot"), self.m_clipParent)
    self.m_jackPotBar:setPosition(pos)
    -- self.m_clipParent:addChild(self.m_jackPotBar, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 1500)
    self.m_clipParent:addChild(self.m_jackPotBar, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)

    -- 创建respin jackpot Bar
    self.m_jackPotRespinBar = util_createView("CodeChicEllaSrc.ChicEllaJackPotRespinBarView")
    -- self:findChild("Node_respinjackpot"):addChild(self.m_jackPotRespinBar)
    self.m_jackPotRespinBar:initMachine(self)
    self.m_jackPotRespinBar:setVisible(true)

    local pos = util_convertToNodeSpace(self:findChild("Node_respinjackpot"), self.m_clipParent)
    self.m_jackPotRespinBar:setPosition(pos)
    -- self.m_clipParent:addChild(self.m_jackPotBar, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 1500)
    self.m_clipParent:addChild(self.m_jackPotRespinBar, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1001)

    -- local lookSpineAnim = util_spineCreate("Socre_ChicElla_Wild", true, true)
    -- self:findChild("Node_jackpot"):addChild(lookSpineAnim, 10)
    -- lookSpineAnim:setPosition(0,0)
    -- util_spinePlay(lookSpineAnim, "actionframe", false)
    -- util_spineEndCallFunc(lookSpineAnim, "actionframe", function (  )
    --     util_spinePlay(lookSpineAnim, "idleframe", false)
    -- end)
    --     util_spinePlay(lookSpineAnim, "idleframe", false)
    -- self:waitWithDelay(nil, function()
    -- end, 2)

    -- 创建freespin Bar
    self.m_freeSpinBar = util_createView("CodeChicEllaSrc.ChicEllaFreespinBarView")
    self:findChild("Node_freebar"):addChild(self.m_freeSpinBar)
    self.m_freeSpinBar:setVisible(true)
    self:findChild("Node_freebar"):setLocalZOrder(1)
    self.m_particleNode1_2 = self.m_freeSpinBar:findChild("Node_1")

    -- mini轮盘 respin单列假滚
    self.m_oneColumnMiniMachine = util_createView("CodeChicEllaSrc.ChicEllaMiniMachine", self)
    self:findChild("columnFirst"):addChild(self.m_oneColumnMiniMachine)
    self.m_oneColumnMiniMachine:setVisible(false)

    -- respin 锁
    self.m_rsLockColumnSpine = util_spineCreate("ChicElla_respin_suoding", true, true)
    self:findChild("Node_respinsuo"):addChild(self.m_rsLockColumnSpine, 10)
    self.m_rsLockColumnSpine:setPosition(0,0)
    self.m_rsLockColumnSpine:setVisible(false)

    self.m_rsLockColumnAnim = util_createAnimation("ChicElla_respin_suo.csb")
    self:findChild("Node_respinsuo"):addChild(self.m_rsLockColumnAnim, 5)
    self.m_rsLockColumnAnim:setPosition(0,0)
    self.m_rsLockColumnAnim:setVisible(false)

    -- bigwin 中奖前动画
    self.m_bigWinPlayAnim = util_createAnimation("ChicElla_zhongdajiang.csb")
    self:findChild("Node_BigWinPlay"):addChild(self.m_bigWinPlayAnim, 5)
    self.m_bigWinPlayAnim:setPosition(0,0)
    self.m_bigWinPlayAnim:setVisible(false)

    -- 创建预告中奖
    self.m_preViewWinNode = util_createAnimation("ChicElla_yugaozhongjiang.csb")
    self:findChild("yugaozhongjiang"):addChild(self.m_preViewWinNode, 10)
    self.m_preViewWinNode:setPosition(0,0)
    self.m_preViewWinNode:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_preViewWinNode, true)
    self.m_preViewWinNodeImgUp = util_spineCreate("Socre_ChicElla_Wild", true, true)
    self.m_preViewWinNode:findChild("Node_yugaojuese"):addChild(self.m_preViewWinNodeImgUp)
    self.m_preViewWinNodeImgUp:setPosition(0,16)
    self.m_preViewWinNodeImgUp:setVisible(false)

    local maskW = 210 * 5
    local maskH = 480
    self.m_preViewWinNodeMask = cc.LayerColor:create(cc.c4f(0, 0, 0, 255 * 0.8), maskW, maskH)
    self.m_preViewWinNodeMask:setPosition(cc.p(-maskW / 2, -maskH / 2))
    self:findChild("yugaozhongjiang"):addChild(self.m_preViewWinNodeMask, 5)
    self.m_preViewWinNodeMask:setVisible(false)

    -- 过场
    self.m_transCutSpine = util_spineCreate("ChicElla_free_guochang", true, true)
    self:findChild("yugaozhongjiang"):addChild(self.m_transCutSpine, 10)
    self.m_transCutSpine:setPosition(0,0)
    self.m_transCutSpine:setVisible(false)

    self.m_transCutAnim = util_createAnimation("ChicElla_free_guochang.csb")
    self:findChild("yugaozhongjiang"):addChild(self.m_transCutAnim, 5)
    self.m_transCutAnim:setPosition(0,0)
    self.m_transCutAnim:setVisible(false)

    
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("yugaozhongjiang"):addChild(self.m_effectNode, 1)

    self.m_particleNode2_2 = self:findChild("base_reel_0")
 
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "ChicEllaSounds/sound_ChicElla_fg_line_win_".. soundIndex .. ".mp3"
        else
            soundName = "ChicEllaSounds/sound_ChicElla_base_line_win_".. soundIndex .. ".mp3"
        end
        
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    -- 更改bet时触发
    gLobalNoticManager:addObserver(self,function(self,params)

    end,ViewEventType.NOTIFY_BET_CHANGE)

    self.m_maskNodeTab = {}
    for col = 1,self.m_iReelColumnNum do
        --添加半透明遮罩
        local parentData = self.m_slotParents[col]
        local mask = cc.LayerColor:create(cc.c3b(0, 0, 0), parentData.reelWidth - 1 , parentData.reelHeight)
        mask:setOpacity(200)
        mask:setPositionX(parentData.reelWidth/2)
        parentData.slotParent:addChild(mask,REEL_SYMBOL_ORDER.REEL_ORDER_1 + 100)
        table.insert(self.m_maskNodeTab,mask)
        mask:setVisible(false)
    end

    -- respin触发黑遮
    self.m_maskAction = {}
    for col = 1,self.m_iReelColumnNum do
        --添加半透明遮罩
        local parentData = self.m_slotParents[col]
        local mask = cc.LayerColor:create(cc.c3b(0, 0, 0), parentData.reelWidth - 1 , parentData.reelHeight)
        mask:setOpacity(200)
        mask:setPositionX(parentData.reelWidth/2)
        parentData.slotParent:addChild(mask,REEL_SYMBOL_ORDER.REEL_ORDER_4)

        local worldPos = mask:getParent():convertToWorldSpace(cc.p(mask:getPositionX(), mask:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        mask:retain()
        mask:removeFromParent(false)
        self.m_clipParent:addChild(mask, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        mask:setPosition(pos)
        mask:release()

        table.insert(self.m_maskAction,mask)
        mask:setVisible(false)
    end
end

function CodeGameScreenChicEllaMachine:checkIsHaveSelfEffect(_effectType, _effectSelfType)
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

function CodeGameScreenChicEllaMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        -- self:playEnterGameSound( "ChicEllaSounds/music_ChicElla_enter.mp3" )


    end,0.4,self:getModuleName())
end

function CodeGameScreenChicEllaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenChicEllaMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()


    -- gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        
    -- end,ViewEventType.SHOW_FREE_SPIN_NUM)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:fsInitLockNode()
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self:rsInitLockNode()
    else
        
    end

    self:updateMainUI()
end

function CodeGameScreenChicEllaMachine:addObservers()
    CodeGameScreenChicEllaMachine.super.addObservers(self)

end

function CodeGameScreenChicEllaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]
        local reelNodeJackPot = v[3]
        local reelActJackPot = v[4]

        if not tolua.isnull(reelNodeJackPot) then
            if reelNodeJackPot:getParent() ~= nil then
                reelNodeJackPot:removeFromParent()
            end
            reelNodeJackPot:release()
        end

        if not tolua.isnull(reelActJackPot) then
            reelActJackPot:release()
        end
    end
    if self.m_reelRunAnimaBG ~= nil then
        for i, v in pairs(self.m_reelRunAnimaBG) do
            local reelNode = v[1]
            local reelAct = v[2]
            local reelNodeJackPot = v[3]
            local reelActJackPot = v[4]

            if not tolua.isnull(reelNodeJackPot) then
                if reelNodeJackPot:getParent() ~= nil then
                    reelNodeJackPot:removeFromParent()
                end
                reelNodeJackPot:release()
            end

            if not tolua.isnull(reelActJackPot) then
                reelActJackPot:release()
            end
        end
    end
    CodeGameScreenChicEllaMachine.super.onExit(self)      -- 必须调用不予许删除
    

    self.m_isJackpotFastRun = {}

    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    self.m_fsWildLockData = {}

    self.m_fsWildMultiPos = {}
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenChicEllaMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_JACKPOT then
        return "Socre_ChicElla_Jackpot"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_ChicElla_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_ChicElla_11"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenChicEllaMachine:getPreLoadSlotNodes()
    local loadNode = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 3}
    }

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 3}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_11, count = 3}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT,count =  3}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenChicEllaMachine:MachineRule_initGame(  )
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_freeSpinBar:changeFreeSpinByCount()
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenChicEllaMachine:slotOneReelDown(reelCol)    

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[3]:isVisible() then
            reelEffectNode[3]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[3]:isVisible() then
            reelEffectNode[3]:runAction(cc.Hide:create())
        end
    end

    local isTriggerLongRun = CodeGameScreenChicEllaMachine.super.slotOneReelDown(self,reelCol) 



    for iRow = 1,self.m_iReelRowNum do
        local node = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if node.p_symbolType >= 0 and node.p_symbolType <= 10 then
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) + (30 - node.p_rowIndex * 10)
        end
    end

    

   
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        self:reelStopHideMask(reelCol)
    end
    
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        if isTriggerLongRun and self:getGameSpinStage( ) ~= QUICK_RUN then
            --self:waitWithDelay(nil, function()
                self:fsScatterLongRunAnim(reelCol)
            --end, 10/30)
            
        end

        if reelCol == 3 and self:getGameSpinStage( ) ~= QUICK_RUN then
            if self:getSymbolCountWithReelResult(TAG_SYMBOL_TYPE.SYMBOL_SCATTER) <= 3 then
                self:fsResetScatterLongRunAnim()
            end
        end

    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenChicEllaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenChicEllaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenChicEllaMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("ChicEllaSounds/music_ChicElla_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_scatter_trigger)
            self:fsTriggerAddTimes(function (  )
                gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_more_start)

                if math.random(0, 100) > 50 then
                    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_freemore_start1)
                else
                    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_freemore_start2)
                end
                local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,true)
                view:findChild("root_scale"):setScale(self.m_machineRootScale)
                view:setBtnClickFunc(function (  )
                    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_more_over)
                end)
            end)
        else
            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_startview_start)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                self:transCutAni(function()
                    -- self:specialNodeUpReset()
                    self:triggerFreeSpinCallFun()
                    self:fsInitLockNode()
                    self:updateMainUI()
                    performWithDelay(self,function(  )

                        

                        effectData.p_isPlay = true
                        self:playGameEffect() 
                    end, 0.3)
                    
                end, true)
                      
            end)

            view:setBtnClickFunc(function (  )
                gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_startview_over)
            end)

            view:findChild("root_scale"):setScale(self.m_machineRootScale)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            showFSView()
        else
            self:fsTriggerScatterAnim(function()
                showFSView()
            end) 
        end
        
    end, 0.5)

end

function CodeGameScreenChicEllaMachine:showFreeSpinOverView()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_overview_start)
   -- gLobalSoundManager:playSound("ChicEllaSounds/music_ChicElla_over_fs.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:transCutAni(function()

            self:triggerFreeSpinOverCallFun()
        
            self:fsWildReplaceReelGrid()
            self:fsWildResetReelGrid(true)
            self.m_fsWildLockData = {}
            self.m_fsWildLockNode:removeAllChildren()
            
            self:updateMainUI()
            

        end, false)
        util_nodeFadeIn(self.m_freeSpinBar, 0.3, 255, 0, nil, function()
        end)
        
    end)
    view:findChild("root_scale"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(function (  )
        gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_overview_over)
    end)
    if self.m_runSpinResultData.p_fsWinCoins == 0 then
    else
        view:findChild("m_lb_coins_0"):setString(util_formatCoins(globalData.slotRunData.lastWinCoin, 20))
        local node=view:findChild("m_lb_coins_0")
        view:updateLabelSize({label=node,sx=0.385,sy=0.385}, 1371)

        
        view:findChild("m_lb_num_0"):setString(self.m_runSpinResultData.p_freeSpinsTotalCount)
    end
    

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenChicEllaMachine:MachineRule_SpinBtnCall()

     self:setMaxMusicBGVolume()
   


    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenChicEllaMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenChicEllaMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenChicEllaMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        if self:fsCheckAddWildIcon() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FS_WILD_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FS_WILD_EFFECT -- 动画类型
        end

        if self:fsCheckWildOpacityAnim() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FS_WILD_OPACITY_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FS_WILD_OPACITY_EFFECT -- 动画类型
        end
    end
    
    if self:getCurrSpinMode() == RESPIN_MODE then
        if self:rsCheckAddLock() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.RS_WILD_ADD_EFFECT 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RS_WILD_ADD_EFFECT
        end
        if self:rsCheckWildOpacityAnim() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.RS_WILD_OPACITY_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RS_WILD_OPACITY_EFFECT -- 动画类型
        end
    end

    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        if self.m_jackpotWin and self.m_jackpotWin[1] then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.JACKPOT_EFFECT 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.JACKPOT_EFFECT
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenChicEllaMachine:MachineRule_playSelfEffect(effectData)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if effectData.p_selfEffectType == self.FS_WILD_EFFECT then
            self:fsPlayWildLockEffect(effectData)
        end
        if effectData.p_selfEffectType == self.FS_WILD_OPACITY_EFFECT then
            self:WildOpacityAnimEffect(effectData, 1)
        end
        if effectData.p_selfEffectType == self.FS_X2_DELAY_EFFECT then
            self:fsX2DelayEffect(effectData)
        end
        
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        if effectData.p_selfEffectType == self.RS_WILD_ADD_EFFECT then
            self:rsPlayWildLockEffect(effectData)
        end
        if effectData.p_selfEffectType == self.RS_WILD_OPACITY_EFFECT then
            self:WildOpacityAnimEffect(effectData, 2)
        end
    end

    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        if effectData.p_selfEffectType == self.JACKPOT_EFFECT then
            self:showJackPotEffect(effectData)
        end
    end
    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenChicEllaMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


------------  respin 代码 这个respin就是不是单个小格滚动的那种 

function CodeGameScreenChicEllaMachine:showRespinView(effectData)
    
        --触发respin
        --先播放动画 再进入respin

        -- self:clearCurMusicBg()
         
        self:setCurrSpinMode( RESPIN_MODE )
        self.m_specialReels = false

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        
        -- self:clearWinLineEffect()
        -- self:clearWinLineEffectNoRest()

        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)

        -- respin 锁定盘初始
        self:rsInitLockNode()

        gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_rg_respin_trigger)


        -- local worldPos = self.m_rsWildLockNode:getParent():convertToWorldSpace(cc.p(self.m_rsWildLockNode:getPositionX(), self.m_rsWildLockNode:getPositionY()))
        -- local pos = self:findChild("yugaozhongjiang"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        -- self.m_rsWildLockNode:retain()
        -- self.m_rsWildLockNode:removeFromParent(false)
        -- self:findChild("yugaozhongjiang"):addChild(self.m_rsWildLockNode, 10)
        -- self.m_rsWildLockNode:setPosition(pos)
        -- self.m_rsWildLockNode:release()


        self:reelShowMaskAction(10/30)
        performWithDelay(self, function()
            self:reelHideMaskAction(10/30)
        end, 50/30)


        performWithDelay(self, function()

            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_rg_startview_start)
            self:showReSpinStart(function()

                gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_rs_lock_column)
                -- 锁第一列
                self:rsLockFirstColumn(function()
                    self.m_jackPotRespinBar:setVisible(true)
                    self.m_jackPotRespinBar:runCsbAction("actionframe", false, function()
                        self.m_jackPotRespinBar:runCsbAction("idle", true)
                        self:updateMainUI()
                    end)
                end, true, true)
            
                performWithDelay(self, function()
                    self:resetGridNodes()-- 开始时重置

                    self:rsInitFirstColumn()   -- 第一列初始

                    effectData.p_isPlay = true
                    self:playGameEffect()
                end, 90/60)         -- 锁第一列+jackpot栏动画

                self:waitWithDelay(nil, function()
                    self:rsMoveFirstColumn()   -- 第一列启动
                    self:resetMusicBg(true)
                end, 130/60)        -- respin callSpinBtn 有半秒延时BaseMachineGameEffect:playEffectNotifyNextSpinCall()
                
    
            end )
    
        end, 120/60)


end

--接收到数据开始停止滚动
function CodeGameScreenChicEllaMachine:stopRespinRun()
    -- print("已经得到了数据")
end

--ReSpin开始改变UI状态
function CodeGameScreenChicEllaMachine:changeReSpinStartUI(respinCount)
   
end

--ReSpin刷新数量
function CodeGameScreenChicEllaMachine:changeReSpinUpdateUI(curCount)
    -- print("当前展示位置信息  %d ", curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenChicEllaMachine:changeReSpinOverUI()

end


function CodeGameScreenChicEllaMachine:showRespinOverView(effectData)

    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    if reSpinCurCount == 0 then
        local curReels  = self.m_runSpinResultData.p_reels
        self.m_oneColumnMiniMachine:setColumnReelDataFinally(curReels)
        self.m_oneColumnMiniMachine:setStop(function()
            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_rs_unlock_column)
            self:rsLockFirstColumn(function()
                -- 隐藏清理第一列
                self.m_oneColumnMiniMachine:setVisible(false)
                self.m_oneColumnMiniMachine:clearSlideSymbolToPool()

                

                self:waitWithDelay(nil, function()  
                    CodeGameScreenChicEllaMachine.super.addLineEffect(self) -- over后触发连线
                    self:sortGameEffects()

                    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
                    effectData.p_isPlay = true
                    self:triggerReSpinOverCallFun(self.m_lightScore)
                    self.m_lightScore = 0
                    -- self:clearCurMusicBg()
                    -- self:resetMusicBg() 
                    self.m_rsWildLockNode:removeAllChildren()
                end, 0.2)

                

                self:waitWithDelay(nil, function()
                    self.m_jackPotBar:setVisible(true)
                    self.m_jackPotRespinBar:runCsbAction("actionframe2", false, function()
                        self.m_jackPotRespinBar:runCsbAction("idle", true)
                        self.m_jackPotRespinBar:setVisible(false)
    
                        self:updateMainUI()
                    end)
                end, 1)
                

            end, true, false)
        end)
    end
    

    
end

-- 重写
function CodeGameScreenChicEllaMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        notAdd = true
    end
    return notAdd
end

-- 重写
---
--添加连线动画
function CodeGameScreenChicEllaMachine:addLineEffect()
    if self:getCurrSpinMode() == RESPIN_MODE then
        local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
        if reSpinCurCount == 0 then
            -- 连线效果改为respinover后添加
            return
        end
    end

    CodeGameScreenChicEllaMachine.super.addLineEffect(self)
end

function CodeGameScreenChicEllaMachine:MachineRule_respinTouchSpinBntCallBack()
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


-- function CodeGameScreenChicEllaMachine:playEffectNotifyNextSpinCall( )

--     CodeGameScreenChicEllaMachine.super.playEffectNotifyNextSpinCall( self )

--     self:checkTriggerOrInSpecialGame(function(  )
--         self:reelsDownDelaySetMusicBGVolume( ) 
--     end)

-- end

function CodeGameScreenChicEllaMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:fsWildSetOpacity(false)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        
    end

    --还原scatter提层
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if self.m_runSpinResultData.p_features and self.m_runSpinResultData.p_features[2] == 1 then
                else
                    util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                end
            end
        end
    end

    for iCol = 1, self.m_iReelColumnNum do
        self.m_isJackpotFastRun[iCol] = false
    end

    CodeGameScreenChicEllaMachine.super.slotReelDown(self)
end

function CodeGameScreenChicEllaMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenChicEllaMachine:setScatterDownScound()
    for i = 1, 5 do
        -- local soundPath = nil
        -- if i >= 3 then
        --     soundPath = "Sounds/bonus_scatter_3.mp3"
        -- else
        --     soundPath = "Sounds/bonus_scatter_" .. i .. ".mp3"
        -- end
        -- self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

-- scatter触发动画
function CodeGameScreenChicEllaMachine:fsTriggerScatterAnim(func)
    self:clearCurMusicBg()
    -- gLobalSoundManager:playSound("MagicianSounds/sound_Magician_scatter_trigger.mp3")
    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_bg2fg_scatter_trigger)

    -- self:specialNodeUpReset()
    self.m_symbolUpZOrderArray = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                table.insert(self.m_symbolUpZOrderArray, symbolNode)
                --提层
                symbolNode:changeParentToOtherNode(self.m_effectNode)
            end
        end
    end

    if #self.m_symbolUpZOrderArray >= 3 then
        for i,v in ipairs(self.m_symbolUpZOrderArray) do
            v:runAnim("actionframe", false)
            v:setIdleAnimName( "idle" )
        end
        performWithDelay(self, function()    
            if func then
                func()
            end
        end, 45/30)
    else
        if func then
            func()
        end
    end
end

-- scatter触发动画提层reset
function CodeGameScreenChicEllaMachine:specialNodeUpReset()
    if not self.m_symbolUpZOrderArray then
        return
    end
    for i, symbolNode in ipairs(self.m_symbolUpZOrderArray) do
        symbolNode:putBackToPreParent()
    end
    self.m_symbolUpZOrderArray = {}
end

-- scatter快滚触发动画
function CodeGameScreenChicEllaMachine:fsScatterLongRunAnim(reelCol)
    local nodes = {}
    -- self.m_symbolUpZOrderArray = {}
    for iCol = 1,reelCol do
        if iCol > 2 then
            break
        end
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:runAnim("idle2", true)
            end
        end
    end
end

-- scatter快滚触发动画重置
function CodeGameScreenChicEllaMachine:fsResetScatterLongRunAnim()
    local nodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        if iCol > 2 then
            break
        end
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if symbolNode:getCurAnimName() == "idle2" then
                    symbolNode:runAnim("idle", true)
                    -- util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                end
            end
        end
    end

    -- for i,v in ipairs(self.m_symbolUpZOrderArray) do
    --     if v:getCurAnimName() == "idle2" then
    --         v:runAnim("idle", true)
    --     end
    -- end
end

-- freegame scatter+1 动画
function CodeGameScreenChicEllaMachine:fsTriggerAddTimes(func)

    self.m_symbolUpZOrderArray = {}
    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(1, iRow, SYMBOL_NODE_TAG)
        if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            table.insert(self.m_symbolUpZOrderArray, symbolNode)
            symbolNode:changeParentToOtherNode(self.m_effectNode)
            symbolNode:runAnim("actionframe", false, function (  )
                symbolNode:runAnim("idle", true)
                func()
            end)
        end
    end
end

-- 重写
--播放提示动画
function CodeGameScreenChicEllaMachine:playReelDownTipNode(slotNode)

    -- self:playScatterBonusSound(slotNode)
    
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

-- 重写
-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenChicEllaMachine:specialSymbolActionTreatment( node)
    -- if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --     --修改小块层级
    --     local scatterOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
    --     local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,scatterOrder)
        
    -- end
end

function CodeGameScreenChicEllaMachine:hasScatterInFirstCol(iReelColumnNum)
    local reelData = self.m_runSpinResultData.p_reels
    local ScatterNums = 0
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, iReelColumnNum do
            if reelData[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                ScatterNums = ScatterNums + 1
                if iReelColumnNum == 1 then
                    return true
                elseif iReelColumnNum == 2 then
                    if ScatterNums > 1 then
                        return true
                    end
                elseif iReelColumnNum == 3 then
                    if ScatterNums > 2 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function CodeGameScreenChicEllaMachine:checkInitRespinCol(slotNode)
    
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        if self.m_runSpinResultData.p_features and self.m_runSpinResultData.p_features[2] == 3 
        and slotNode.p_cloumnIndex == 1 and not self.IsRespinColumnInit and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self.IsRespinColumnInit = true

            local curReels  = self.m_runSpinResultData.p_reels
            self.m_oneColumnMiniMachine:setColumnReelData(curReels)
        end
    end
    
end

-- 重写  落地动画
function CodeGameScreenChicEllaMachine:playCustomSpecialSymbolDownAct(slotNode, speedActionTable)
    local downBack = function()
        --回弹
        local newSpeedActionTable = {}
        for i = 1, #speedActionTable do
            if i == #speedActionTable then
                -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                local resTime = self.m_configData.p_reelResTime
                local index = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
                local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
            else
                newSpeedActionTable[i] = speedActionTable[i]
            end
        end

        local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
        slotNode:runAction(actSequenceClone)

        
    end
    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            slotNode:runAnim("buling",false,function()
                slotNode:runAnim("idle",true)
            end)
            util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
            downBack()
        else
            if self:hasScatterInFirstCol(slotNode.p_cloumnIndex) then
                if slotNode:getCurAnimName() == "idle2" then
                else
                    slotNode:runAnim("buling",false,function()
                        slotNode:runAnim("idle",true)
                        self:checkInitRespinCol(slotNode)
                    end)
                end

                util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 6000)
                downBack()

            else
                slotNode:runAnim("idle",true)
            end
        end
    elseif slotNode.p_symbolType == self.SYMBOL_JACKPOT then
        slotNode:runAnim("buling",false)
    elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local posIdx = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
            local multi = self.m_fsWildMultiPos[posIdx]
            if multi then -- 乘倍直接变 不播buling
                local lockNode = self.m_fsWildLockNode:getChildByTag(posIdx)
                if lockNode then
                    -- self.m_fsWildLockData[posIdx] = multi
                    lockNode:setShowType(1)
                    lockNode:playAction(multi, true, true)
                    lockNode:setLocalZOrder(posIdx + 1000)  -- 提本层层级

                    local str = "actionframe1_2"
                    if multi == 2 then
                        str = "actionframe1_2"
                    elseif multi == 3 then
                        str = "actionframe1_3"
                    end
                    slotNode:runAnim(str,false,function()
                        slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
                    end)

                end
            else
                slotNode:runAnim("buling",false,function()
                    slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
                end)
            end

            util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 6000)
            downBack()
            local linePos = {}
            linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
            slotNode.m_bInLine = true
            slotNode:setLinePos(linePos)
        elseif self:getCurrSpinMode() == RESPIN_MODE then
            slotNode:runAnim("buling",false,function()
                slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
            end)

            util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 6000)
            downBack()
            local linePos = {}
            linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
            slotNode.m_bInLine = true
            slotNode:setLinePos(linePos)
        end
    end
end

--重写
-- 有特殊需求判断的 重写一下
function CodeGameScreenChicEllaMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _slotNode.p_symbolType == 94 then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                -- if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    
                -- end

                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
                        return true
                    end
                elseif _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    if self:hasScatterInFirstCol(_slotNode.p_cloumnIndex) then
                        return true
                    end
                else
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenChicEllaMachine:fsCreateOneLockNode(_posIndex)

    local wild = util_require("CodeChicEllaSrc.ChicEllaWildNode"):create(self, 1)
    self.m_fsWildLockNode:addChild(wild)
    wild:setPosition(util_getOneGameReelsTarSpPos(self, _posIndex))
    wild:setTag(_posIndex)
    wild:setLocalZOrder(_posIndex + 1000)

    return wild

end

function CodeGameScreenChicEllaMachine:fsCheckAddWildIcon()
    local isAdd = false
    
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    -- 返回位置和倍数
    local wildIconsPos = fsExtraData.wildIcons or {}

    for i=1, #wildIconsPos do
        if not wildIconsPos[i][1] then
            print("wildIcons error!!!")
            break
        end
        local pos = wildIconsPos[i][1]
        local multi = wildIconsPos[i][2]

        if not self.m_fsWildLockData[pos] then
            isAdd = true
            break
        elseif self.m_fsWildLockData[pos] and self.m_fsWildLockData[pos] < multi then
            isAdd = true
            break
        end
    end

    return isAdd
end

function CodeGameScreenChicEllaMachine:fsPlayWildLockEffect(effectData)
    -- gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Lock.mp3")

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    -- 返回位置和倍数
    local wildIconsPos = fsExtraData.wildIcons or {}


    performWithDelay(self, function()

        local isPlayTriggerSound = false
        for i=1, #wildIconsPos do
            if not wildIconsPos[i][1] then
                print("wildIcons error!!!")
                break
            end
            local pos = wildIconsPos[i][1]
            local multi = wildIconsPos[i][2]
            local lockNode = self.m_fsWildLockNode:getChildByTag(pos)
            if not lockNode then
                lockNode = self:fsCreateOneLockNode(pos)
                self.m_fsWildLockData[pos] = multi
                lockNode:playAction(multi, true)
            else
                if self.m_fsWildLockData[pos] and self.m_fsWildLockData[pos] < multi then
                    self.m_fsWildLockData[pos] = multi
                    lockNode:playAction(multi, true)
                    lockNode:setLocalZOrder(pos + 1000)  -- 提本层层级

                    if not isPlayTriggerSound then
                        isPlayTriggerSound = true
                        gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_multi_buling)
                    end
                    
                end
            end
    
        end

    end, 10/30)


    

    performWithDelay(self, function()

        effectData.p_isPlay = true
        self:playGameEffect()

    end, 70/30)
    
    
end

-- 判断fs wild 是否乘倍
function CodeGameScreenChicEllaMachine:fsProcessWildIsUp()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    -- 返回位置和倍数
    local wildIconsPos = fsExtraData.wildIcons or {}

    local isHaveMulti = false
    for i=1, #wildIconsPos do
        local pos = wildIconsPos[i][1]
        local multi = wildIconsPos[i][2]
        if self.m_fsWildLockData[pos] and self.m_fsWildLockData[pos] < multi then
            self.m_fsWildMultiPos[pos] = multi
            isHaveMulti = true
        end
    end


    
    if isHaveMulti then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.FS_X2_DELAY_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FS_X2_DELAY_EFFECT -- 动画类型

        self:sortGameEffects()
    end
end

function CodeGameScreenChicEllaMachine:fsX2DelayEffect(effectData)
    performWithDelay(self, function()

        effectData.p_isPlay = true
        self:playGameEffect()

    end, 0.5)
end

-- 重写
function CodeGameScreenChicEllaMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    -- ownerlist["m_lb_num"] = num
    -- ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    if self.m_runSpinResultData.p_fsWinCoins == 0 then
        return self:showDialog("FreeSpinOver_0", ownerlist, func)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end
    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end
-- 重写
function CodeGameScreenChicEllaMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        -- self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        -- self.m_freeSpinBar:runCsbAction("actionframe", false, function()
        --     self.m_freeSpinBar:runCsbAction("idle", true)
        -- end)

        if func then
            func()
        end
    end

    local ownerlist = {}
    -- ownerlist["m_lb_num"] = num

    local view
    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end

    -- 创建fs +1 光效
    local addTimesEffect = util_createAnimation("ChicElla/FreeSpinMore_g.csb")
    view:findChild("ef_g"):addChild(addTimesEffect)
    addTimesEffect:setPosition(0,0)
    addTimesEffect:setVisible(false)
    addTimesEffect:runCsbAction("actionframe", true)
    
    self:waitWithDelay(view, function()
        if addTimesEffect then
            addTimesEffect:setVisible(true)
        end
    end, 10/60)

    local particleNode1_1 = view:findChild("ef_zuanshi")
    self:waitWithDelay(view, function()
        self:flyParticleAni(particleNode1_1, self.m_particleNode1_2, function()
            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg_times_add)
            self.m_freeSpinBar:runCsbAction("actionframe", false, function()
                self.m_freeSpinBar:runCsbAction("idle", true)
            end)
        end)
    end, 90/60)

    return view
end

function CodeGameScreenChicEllaMachine:fsInitLockNode()
    
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    -- 返回位置和倍数
    local wildIconsPos = fsExtraData.wildIcons or {}


    for i=1, #wildIconsPos do
        local pos = wildIconsPos[i][1]
        local multi = wildIconsPos[i][2]
        local lockNode = self:fsCreateOneLockNode(pos)
        self.m_fsWildLockData[pos] = multi
        lockNode:playAction(multi, true)
    end

end
-- 重置锁定块的层级
function CodeGameScreenChicEllaMachine:fsResetLockOrder()

    local childs = self.m_fsWildLockNode:getChildren()
    for k, spineNode in ipairs(childs) do
        local posIdx = spineNode:getTag()
        spineNode:setLocalZOrder(posIdx)
    end

end

function CodeGameScreenChicEllaMachine:rsResetLockOrder()

    local childs = self.m_rsWildLockNode:getChildren()
    for k, spineNode in ipairs(childs) do
        local posIdx = spineNode:getTag()
        spineNode:setLocalZOrder(posIdx)
    end

end

function CodeGameScreenChicEllaMachine:fsWildSetOpacity(isHide)

    local childs = self.m_fsWildLockNode:getChildren()
    for k, spineNode in ipairs(childs) do
        if isHide then
            spineNode:setShowType(2)
            spineNode.m_static:setOpacity(255*self.wildOpacity)
            self.m_fsWildLockNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
        else
        end
    end

end

function CodeGameScreenChicEllaMachine:rsWildSetOpacity(isHide)

    local childs = self.m_rsWildLockNode:getChildren()
    for k, spineNode in ipairs(childs) do
        if isHide then
            spineNode:setShowType(2)
            spineNode.m_static:setOpacity(255*self.wildOpacity)

            -- self.m_rsWildLockNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
        else

        end
    end

end

-- 渐隐效果
-- type 1 freegame 2 respin
function CodeGameScreenChicEllaMachine:WildOpacityAnimEffect(effectData, type)

    local childs
    if type == 1 then
        childs = self.m_fsWildLockNode:getChildren()
    else
        childs = self.m_rsWildLockNode:getChildren()
    end

    local isSetZOrder = false
    local isFade = false
    for k, spineNode in ipairs(childs) do
        while true
        do
            -- 乘倍的 不半透过渡
            if type == 1 then
                local posIdx = spineNode:getTag()
                local multi = self.m_fsWildMultiPos[posIdx]
                if multi then
                    break
                end
            end
            if not isFade then
                isFade = true
            end

            util_nodeFadeIn(spineNode.m_static, 0.3, 255*self.wildOpacity, 255, nil, function()
                spineNode:setShowType(1)
                if not isSetZOrder then
                    if type == 1 then
                        self.m_fsWildLockNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5000)
                    else
                        -- self.m_rsWildLockNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5001)
                    end
                    isSetZOrder = true
                end
            end)


            break
        end
    end
    if not isFade then
        if type == 1 then
            self.m_fsWildLockNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5000)
        else
            -- self.m_rsWildLockNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5001)
        end
    end

    performWithDelay(self, function()

        if type == 2 then
            -- 半透恢复 锁定块回归盘上
            local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
            if reSpinCurCount == 0 then
                self:rsWildReplaceReelGrid()
            end
        end
        


        effectData.p_isPlay = true
        self:playGameEffect()

    end, 0.3)

end


function CodeGameScreenChicEllaMachine:fsCheckWildOpacityAnim()
    local childs = self.m_fsWildLockNode:getChildren()
    return #childs > 0
end

function CodeGameScreenChicEllaMachine:rsCheckWildOpacityAnim()
    local childs = self.m_rsWildLockNode:getChildren()
    return #childs > 0
end

function CodeGameScreenChicEllaMachine:fsWildSetVisible(isVisible)
    local childs = self.m_fsWildLockNode:getChildren()
    for k, spineNode in ipairs(childs) do
        spineNode:setVisible(isVisible)
    end
end

function CodeGameScreenChicEllaMachine:fsWildReplaceReelGrid()
    for posIdx, multi in pairs(self.m_fsWildLockData) do
        local pos = self:getRowAndColByPos(posIdx)
        local row = pos.iX
        local col = pos.iY
        local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)      
        if targSp then
            local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
            local oldType = targSp.p_symbolType
            self.m_fsReplaceWildPosSymbol[posIdx] = targSp.p_symbolType

            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            targSp:changeCCBByName(ccbName, symbolType)
            
            -- targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) - targSp.p_rowIndex)

            if oldType ~= 92 then
                --替换的如果不是wild需要提层
                -- print(string.format("替换前 order    col: %d, row: %d, type: %d, order: %d, zorder: %d", targSp.p_cloumnIndex, targSp.p_rowIndex, targSp.p_symbolType, targSp.p_showOrder, targSp:getLocalZOrder()))
                
                util_setSymbolToClipReel(self, targSp.p_cloumnIndex, targSp.p_rowIndex, targSp.p_symbolType, 0)

                -- print(string.format("替换后 order    col: %d, row: %d, type: %d, order: %d, zorder: %d", targSp.p_cloumnIndex, targSp.p_rowIndex, targSp.p_symbolType, targSp.p_showOrder, targSp:getLocalZOrder()))
                local linePos = {}
                linePos[#linePos + 1] = {iX = targSp.p_rowIndex, iY = targSp.p_cloumnIndex}
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)
            else
                --在buling后已经提层
                -- local showOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - targSp.p_rowIndex
                -- targSp.m_showOrder = showOrder
                -- targSp.p_showOrder = showOrder
                -- targSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + targSp.p_showOrder)
            end

            if multi == 1 then
                targSp:setLineAnimName("actionframe")
                targSp:setIdleAnimName("idleframe")
                targSp:changeSymbolImageByName("Socre_ChicElla_Wild")
            elseif multi == 2 then
                targSp:setLineAnimName("actionframe2")
                targSp:setIdleAnimName("idleframe2")
                targSp:changeSymbolImageByName("Socre_ChicElla_Wildx2")
            elseif multi == 3 then
                targSp:setLineAnimName("actionframe3")
                targSp:setIdleAnimName("idleframe3")
                targSp:changeSymbolImageByName("Socre_ChicElla_Wildx3")
            end
            targSp:runIdleAnim()
        end
    end

end
-- respin替换盘上块
function CodeGameScreenChicEllaMachine:rsWildReplaceReelGrid()
    
    local childs = self.m_rsWildLockNode:getChildren()
    for k, spineNode in ipairs(childs) do
        local posIdx = spineNode:getTag()

        local pos = self:getRowAndColByPos(posIdx)
        local row = pos.iX
        local col = pos.iY
        local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)      
        if targSp then
            local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            targSp:changeCCBByName(ccbName, symbolType)
            targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) - targSp.p_rowIndex)
        end
    end

end

function CodeGameScreenChicEllaMachine:fsWildResetReelGrid(_notChangeCCB)
    for posIdx, multi in pairs(self.m_fsWildLockData) do
        if self.m_fsReplaceWildPosSymbol[posIdx] then
            local pos = self:getRowAndColByPos(posIdx)
            local row = pos.iX
            local col = pos.iY
            local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)      
            if targSp then
                if not _notChangeCCB then --是否不改变小块
                    local symbolType = self.m_fsReplaceWildPosSymbol[posIdx]

                    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
                    targSp:changeCCBByName(ccbName, symbolType)
                    targSp:changeSymbolImageByName(ccbName)
                    targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType))

                    targSp:setLineAnimName("actionframe")
                    targSp:setIdleAnimName("idleframe")
                else
                    -- if targSp.p_symbolType == 92 then
                    --     targSp:changeSymbolImageByName("Socre_ChicElla_Wild")
                    -- end
                end
                

                -- targSp:setLineAnimName("actionframe")
                -- targSp:setIdleAnimName("idleframe")
                
            end
        end
    end
    self.m_fsReplaceWildPosSymbol = {}
end

function CodeGameScreenChicEllaMachine:updateMainUI()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_jackPotBar:setVisible(true)
        self.m_freeSpinBar:setVisible(true)
        util_nodeFadeIn(self.m_freeSpinBar, 0.3, 0, 255, nil, function()
        end)
        self.m_jackPotRespinBar:setVisible(false)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_jackPotRespinBar:setVisible(true)
        self.m_freeSpinBar:setVisible(false)
        self.m_jackPotBar:setVisible(false)
    else
        self.m_jackPotBar:setVisible(true)
        self.m_jackPotRespinBar:setVisible(false)
        self.m_freeSpinBar:setVisible(false)
    end

end

--轮盘滚动显示遮罩
function CodeGameScreenChicEllaMachine:beginReelShowMask()
    for i,maskNode in ipairs(self.m_maskNodeTab) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            util_nodeFadeIn(maskNode,0.3,0,200,nil,nil)
        end
    end
end

--轮盘停止隐藏遮罩
function CodeGameScreenChicEllaMachine:reelStopHideMask(col)
    local maskNode = self.m_maskNodeTab[col]
    local act = cc.FadeOut:create(0.3)
    maskNode:runAction(act)

    self:waitWithDelay(nil,function()
        maskNode:setVisible(false)
    end,0.3)
end

-- 显示黑遮
function CodeGameScreenChicEllaMachine:reelShowMaskAction(time)
    for i,maskNode in ipairs(self.m_maskAction) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            util_nodeFadeIn(maskNode,time,0,200,nil,nil)
        end
    end
end

-- 隐藏黑遮
function CodeGameScreenChicEllaMachine:reelHideMaskAction(time)
    for i=1, #self.m_maskAction do
        local maskNode = self.m_maskAction[i]
        local act = cc.FadeOut:create(time)
        maskNode:runAction(act)

        self:waitWithDelay(nil,function()
            maskNode:setVisible(false)
        end,time)
    end
    
end

function CodeGameScreenChicEllaMachine:initMachineUI( )
    
    CodeGameScreenChicEllaMachine.super.initMachineUI( self )

    
end

-- 重写
function CodeGameScreenChicEllaMachine:spinBtnEnProc()
    self.m_fsWildMultiPos = {}
    --改
    self:specialNodeUpReset() -- need before beginReel
    --改
    self.IsRespinColumnInit = false

    --TODO 处理repeat逻辑

    if self.m_isChangeBGMusic then
        gLobalSoundManager:playFreeSpinBackMusic(self:getFreeSpinMusicBG())
        self.m_isChangeBGMusic = false
    end

    if CC_NEWS_PERIOD_SHOW then
        self:newsPeriodShow()
    end

    self:beginReel()

    -- 修改
    -- 半透显示
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:fsWildSetOpacity(true)
        self:fsResetLockOrder()

        self:fsWildSetVisible(true)
        self:fsWildResetReelGrid()
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self:rsWildSetOpacity(true)
        self:rsResetLockOrder()
    end

    
end

function CodeGameScreenChicEllaMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        -- 棋盘遮罩
        self:beginReelShowMask()
    end


    CodeGameScreenChicEllaMachine.super.beginReel(self)
end

-- 延时函数
function CodeGameScreenChicEllaMachine:waitWithDelay(parent, endFunc, time)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

-- 重写
--设置bonus 层级
function CodeGameScreenChicEllaMachine:getBounsScatterDataZorder(symbolType)
    local order = CodeGameScreenChicEllaMachine.super.getBounsScatterDataZorder(self,symbolType)
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
        elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
        end
    end
    
    return order
end

-- 重写
---
-- 进入关卡
--
function CodeGameScreenChicEllaMachine:enterLevel()
    CodeGameScreenChicEllaMachine.super.enterLevel(self)

    self:bgCutAni(nil, false)

    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_come_level)


    -- 初始提层级
    local hasFeature = self:checkHasFeature()
    if hasFeature == false then
        --wild提层
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                end
            end
        end
    end
end

function CodeGameScreenChicEllaMachine:rsInitLockNode()
    local lockPosIndexs = {}
    if self.m_runSpinResultData.p_features and self.m_runSpinResultData.p_features[2] == 3 then
        for iRow = self.m_iReelRowNum, 1, -1 do
            for iCol = 1, self.m_iReelColumnNum, 1 do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD and targSp.p_cloumnIndex ~= 1 then
                        local posIdx = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex)
                        table.insert(lockPosIndexs, posIdx)
                    end
                end
            end
        end
    else
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
        lockPosIndexs = rsExtraData.lockPosArray or {}
    end
    

    for i=1,#lockPosIndexs do
        local posIdx = lockPosIndexs[i]
        self:rsCreateOneLockNode(posIdx)
    end

end

function CodeGameScreenChicEllaMachine:rsCreateOneLockNode(_posIndex, type)

    local wild = util_require("CodeChicEllaSrc.ChicEllaWildNode"):create(self, 1)
    self.m_rsWildLockNode:addChild(wild)
    wild:setPosition(util_getOneGameReelsTarSpPos(self, _posIndex))
    wild:setTag(_posIndex)
    wild:setLocalZOrder(_posIndex + 1000)
    if type and type == 1 then
        util_spinePlay(wild.m_spine,"actionframe5")
    else
        util_spinePlay(wild.m_spine,"actionframe4")
    end
    
    
    return wild

end

function CodeGameScreenChicEllaMachine:rsCheckAddLock()
    local isAdd = false
    
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local lockPosIndexs = rsExtraData.lockPosArray or {}

    for i=1,#lockPosIndexs do
        local pos = lockPosIndexs[i]
        local lockNode = self.m_rsWildLockNode:getChildByTag(pos)
        if not lockNode then
            isAdd = true
            break
        end
    end

    return isAdd
end

function CodeGameScreenChicEllaMachine:rsPlayWildLockEffect(effectData)
  
    -- gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Lock.mp3")

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local lockPosIndexs = rsExtraData.lockPosArray or {}

    for i=1,#lockPosIndexs do
        local pos = lockPosIndexs[i]

        local lockNode = self.m_rsWildLockNode:getChildByTag(pos)
        if not lockNode then
            lockNode = self:rsCreateOneLockNode(pos, 1) --动画播5
        end

    end

    performWithDelay(self,function(  )
        effectData.p_isPlay = true
        self:playGameEffect()

    end,80/30)
end

-- 锁
function CodeGameScreenChicEllaMachine:rsLockFirstColumn(func, isPlayAni, isLock)
    self.m_rsLockColumnSpine:setVisible(true)
    if isPlayAni then
        self.m_rsLockColumnAnim:setVisible(true)
        self.m_rsLockColumnAnim:findChild("Particle_1"):resetSystem()
        self.m_rsLockColumnAnim:findChild("Particle_2"):resetSystem()
        self.m_rsLockColumnAnim:findChild("Particle_1_0"):resetSystem()
        self.m_rsLockColumnAnim:findChild("Particle_2_0"):resetSystem()
        self.m_rsLockColumnAnim:runCsbAction("actionframe", false, function()
            self.m_rsLockColumnAnim:setVisible(false)

            -- stopSystem()
        end)

        local aniName = util_cond_test(isLock, "start", "over")
        util_spinePlay(self.m_rsLockColumnSpine, aniName, false)
        util_spineEndCallFunc(self.m_rsLockColumnSpine, aniName, function()
            if isLock then
                util_spinePlay(self.m_rsLockColumnSpine, "idle", true)
            else
                self.m_rsLockColumnSpine:setVisible(false)
            end
            if func then
                func()
            end
        end)
    else
        util_spinePlay(self.m_rsLockColumnSpine, "idle", true)
        if func then
            func()
        end
    end
    
end

-- 初始respin第一列假滚动
function CodeGameScreenChicEllaMachine:rsInitFirstColumn()
    self.m_oneColumnMiniMachine:setVisible(true)
    if not self.IsRespinColumnInit then
        local curReels  = self.m_runSpinResultData.p_reels
        self.m_oneColumnMiniMachine:setColumnReelData(curReels)
    end
end

function CodeGameScreenChicEllaMachine:rsMoveFirstColumn()
    self.m_oneColumnMiniMachine:startSlideMove()
end

-- 重写
function CodeGameScreenChicEllaMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_NOMAL)
    
    view:findChild("root_scale"):setScale(self.m_machineRootScale)
    -- 创建光效
    local addEffect = util_createAnimation("ChicElla/JackpotWinView_g.csb")
    view:findChild("ef_g"):addChild(addEffect)
    addEffect:setPosition(0,0)
    addEffect:setVisible(true)
    addEffect:runCsbAction("actionframe", true)

    local particleNode1_1 = view:findChild("wanfa")
    self:waitWithDelay(view, function()
        self:flyParticleAni(particleNode1_1, self.m_particleNode2_2, function()
            
        end)
    end, 180/60)
end

-- 重写
function CodeGameScreenChicEllaMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func, nil, index)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

-- 重写
----
--- 处理spin 成功消息
--
function CodeGameScreenChicEllaMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "spinResult"
        gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
    end
    if spinData.action == "SPIN" then

        self:operaSpinResultData(param)

        --改
        self.m_jackpotWin = {}
        if param[2].result.jackpotCoins then
            local jackpotCoins = param[2].result.jackpotCoins
            if jackpotCoins.Minor then
                self.m_jackpotWin[1] = "Minor"
                self.m_jackpotWin[2] = jackpotCoins.Minor
                self.m_jackpotWin[3] = 3
            end
            if jackpotCoins.Major then
                self.m_jackpotWin[1] = "Major"
                self.m_jackpotWin[2] = jackpotCoins.Major
                self.m_jackpotWin[3] = 2
            end
            if jackpotCoins.Grand then
                self.m_jackpotWin[1] = "Grand"
                self.m_jackpotWin[2] = jackpotCoins.Grand
                self.m_jackpotWin[3] = 1
            end
        end
        if self.m_runSpinResultData.p_features[2] == 1 or self.m_runSpinResultData.p_features[2] == 3 then
            local currSpinMode = self:getCurrSpinMode()
            if currSpinMode == NORMAL_SPIN_MODE or currSpinMode == AUTO_SPIN_MODE then
                self.m_isPlayWinningNotice = math.random(0, 100) < 40
            end
        end
        --改

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function CodeGameScreenChicEllaMachine:showJackPotView(index, coins, func)
    
    local jackPotWinView = util_createView("CodeChicEllaSrc.ChicEllaJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index, coins, self, func)

    jackPotWinView:findChild("root_scale"):setScale(self.m_machineRootScale)
end

-- jackpot效果
function CodeGameScreenChicEllaMachine:showJackPotEffect(effectData)

    self:runJackPotAnim(function()
        
    end)


    

    
    performWithDelay(self, function()

        local coins = self.m_jackpotWin[2]  
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,true})
        globalData.slotRunData.lastWinCoin = lastWinCoin

        if self.m_jackpotWin[3] == 1 then
            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_jackpot_pop_1)
        elseif self.m_jackpotWin[3] == 2 then
            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_jackpot_pop_2)
        elseif self.m_jackpotWin[3] == 3 then
            gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_jackpot_pop_3)
        end

        self.m_jackPotBar:runCsbAction("idleframe", true)
        self:showJackPotView(self.m_jackpotWin[3], self.m_jackpotWin[2], function()

            if not self:checkBigWin() then
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, self.JACKPOT_EFFECT)
                self:sortGameEffects()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        self:specialNodeUpReset()
    end, 120/60 + 0.5)
end

function CodeGameScreenChicEllaMachine:runJackPotAnim(func)
    local colLimit = 3
    local str = "ChicElla_grand_di"
    if self.m_jackpotWin[3] == 1 then
        colLimit = 5
        str = "ChicElla_grand_di"
    elseif self.m_jackpotWin[3] == 2 then
        colLimit = 4
        str = "ChicElla_major_di"
    elseif self.m_jackpotWin[3] == 3 then
        colLimit = 3
        str = "ChicElla_minor_di"
    end

    self.m_symbolUpZOrderArray = {}
    for iCol = 1,self.m_iReelColumnNum do
        if iCol <= colLimit then
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_JACKPOT then
                    table.insert(self.m_symbolUpZOrderArray, symbolNode)
                    --提层
                    symbolNode:changeParentToOtherNode(self.m_effectNode)

                    self:flyParticleAni(symbolNode, self.m_jackPotBar:findChild(str), function()
                    end)
                end
            end
        end
    end

    self:waitWithDelay(nil, function()
        if self.m_jackpotWin[3] == 1 then
            self.m_jackPotBar:runCsbAction("actionframe", true)
        elseif self.m_jackpotWin[3] == 2 then
            self.m_jackPotBar:runCsbAction("actionframe" .. (self.m_jackpotWin[3] - 1), true)
        elseif self.m_jackpotWin[3] == 3 then
            self.m_jackPotBar:runCsbAction("actionframe" .. (self.m_jackpotWin[3] - 1), true)
        end
        gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_jackpot_edge_anim)


        if #self.m_symbolUpZOrderArray > 0 then
            for i=1,#self.m_symbolUpZOrderArray do
                if i == 1 then
                    self.m_symbolUpZOrderArray[i]:runAnim("actionframe", false, function ()
                        if func then
                            func()
                        end
                    end)
                else
                    self.m_symbolUpZOrderArray[i]:runAnim("actionframe", false)
                end
            end
        else
            if func then
                func()
            end
        end

        gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_bg_jackpot_trigger)
    end, 0.5)
end

-- 预告中奖
function CodeGameScreenChicEllaMachine:preViewWin(func)
    self.m_preViewWinNode:setVisible(true)
    self.m_preViewWinNodeMask:setVisible(true)
    self.m_preViewWinNode:runCsbAction("actionframe", true)
    self.m_isPlayWinningNotice = false
    performWithDelay(self, function()
        if self.m_preViewWinNode:isVisible() then
            util_nodeFadeIn(self.m_preViewWinNode, 0.8, 255, 0, nil, function()
                self.m_preViewWinNode:setVisible(false)
                util_nodeFadeIn(self.m_preViewWinNode, 0, 255, 255)
            end)
            util_nodeFadeIn(self.m_preViewWinNodeMask, 0.8, 255 * 0.8, 0, nil, function()
                self.m_preViewWinNodeMask:setVisible(false)
                self.m_preViewWinNodeMask:setOpacity(255 * 0.8)
            end)
        end
    end, 90/60)

    self.m_preViewWinNodeImgUp:setVisible(true)
    util_spinePlay(self.m_preViewWinNodeImgUp, "actionframe6", false)
    util_spineEndCallFunc(self.m_preViewWinNodeImgUp, "actionframe6", function (  )
        self.m_preViewWinNodeImgUp:setVisible(false)
    end)

    performWithDelay(self, function()
        if func then
            func()
        end
    end, 90/60)

    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_pre_winning)
end

-- 重写
function CodeGameScreenChicEllaMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    local nextFun = function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end


        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:fsProcessWildIsUp()
        end
        
    end

    if self.m_isPlayWinningNotice then
        self:preViewWin(function()
            nextFun()
        end)
    else
        nextFun()
    end
end

-- 关卡重写方法
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenChicEllaMachine:MachineRule_ResetReelRunData()
    if self.m_isPlayWinningNotice then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local preRunLen = reelRunData.initInfo.reelRunLen
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()
            
            reelRunData:setReelRunLen(preRunLen)
            reelRunData:setReelLongRun(false)
            reelRunData:setNextReelLongRun(false)

            -- 提取某一列所有内容， 一些老关在创建最终信号小块时会以此列表作为最终信号的判断条件
            local columnSlotsList = self.m_reelSlotsList[iCol]  
            -- 新的关卡父类可能没有这个变量
            if columnSlotsList then

                local curRunLen = reelRunData:getReelRunLen()
                local iRow = columnData.p_showGridCount
                -- 将 老的最终列表 依次放入 新的最终列表 对应索引处
                local maxIndex = runLen + iRow
                for checkRunIndex = maxIndex,1,-1 do
                    local checkData = columnSlotsList[checkRunIndex]
                    if checkData == nil then
                        break
                    end
                    columnSlotsList[checkRunIndex] = nil
                    columnSlotsList[curRunLen + iRow - (maxIndex - checkRunIndex)] = checkData
                end

            end
            
        end
    end
end

-- 过场
function CodeGameScreenChicEllaMachine:transCutAni(func, isToFree)
    self.m_transCutAnim:setVisible(true)
    self.m_transCutAnim:runCsbAction("actionframe", false, function()
        if func then
            func()
        end
    end)

    local particle = self.m_transCutAnim:findChild("Particle_1")
    particle:resetSystem()


    self.m_transCutSpine:setVisible(true)
    util_spinePlay(self.m_transCutSpine, "actionframe", false)
    local spineEndCallFunc = function()
        self.m_transCutSpine:setVisible(false)
    end
    util_spineEndCallFunc(self.m_transCutSpine, "actionframe", spineEndCallFunc)

    performWithDelay(self, function()
        self:bgCutAni(isToFree, true)
    end, 60/60)

    if isToFree then
        gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_bg2fg_trans)
    else
        gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fg2bg_trans)
    end
    

end

-- 背景切换
function CodeGameScreenChicEllaMachine:bgCutAni(isToFree, isPlayAni)
    if isPlayAni then
        if isToFree then
            self.m_gameBg:runCsbAction("normal_free", false, function()
                self.m_gameBg:runCsbAction("free", true)
            end)
        else
            self.m_gameBg:runCsbAction("free_normal", false, function()
                self.m_gameBg:runCsbAction("normal", true)
            end)
        end
    else
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self.m_gameBg:runCsbAction("free", true)
        else
            self.m_gameBg:runCsbAction("normal", true)
        end
    end

end

-- 适配
-- function CodeGameScreenChicEllaMachine:scaleMainLayer()
--     local uiW, uiH = self.m_topUI:getUISize()
--     local uiBW, uiBH = self.m_bottomUI:getUISize()

--     local mainHeight = display.height - uiH - uiBH
--     local mainPosY = (uiBH - uiH - 30) / 2

--     local winSize = display.size
--     local mainScale = 1

--     local hScale = mainHeight / self:getReelHeight()
--     local wScale = winSize.width / self:getReelWidth()
--     if hScale < wScale then
--         mainScale = hScale
--     else
--         mainScale = wScale
--         self.m_isPadScale = true
--     end
--     if globalData.slotRunData.isPortrait == true then
--         if display.height < DESIGN_SIZE.height then
--             mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
--             util_csbScale(self.m_machineNode, mainScale)
--             self.m_machineRootScale = mainScale
--         end
--     else
--         util_csbScale(self.m_machineNode, mainScale)
--         self.m_machineRootScale = mainScale
--         -- self.m_machineNode:setPositionY(mainPosY + self.m_RootNodeAddY )
--         -- self.m_machineNode:setPositionY(mainPosY + 24 )
--         self.m_machineNode:setPositionY(mainPosY + 6)
--     end

-- end

function CodeGameScreenChicEllaMachine:scaleMainLayer()
    CodeGameScreenChicEllaMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.75
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.81 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.88 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio >= 768/1370 then
        local mainScale = 0.98 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1370 and ratio >= 768/1530 then
        local mainScale = 0.98 - 0.05*((ratio-768/1530)/(768/1370 - 768/1530))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1530 and ratio >= 768/1660 then
        local mainScale = 0.98 - 0.05*((ratio-768/1660)/(768/1530 - 768/1660))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

-- 显示paytableview 界面
function CodeGameScreenChicEllaMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    if view then
        view:findChild("root_scale"):setScale(self.m_machineRootScale)
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

--重写 假滚层级
function CodeGameScreenChicEllaMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)

    parentData.symbolType = symbolType
    parentData.order = self:getBounsScatterDataZorder(symbolType)
end

function CodeGameScreenChicEllaMachine:checkBigWin()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        
        return true
    end
    return false
end

function CodeGameScreenChicEllaMachine:clearWinLineEffectNoRest()
    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    self:clearLineAndFrame()

    -- 隐藏长条模式下 大长条的遮罩问题
    self:operaBigSymbolMask(false)
end

-- 重写
function CodeGameScreenChicEllaMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 改
        -- 取消掉赢钱线的显示
        self:clearWinLineEffectNoRest()

        local nodeLen = #self.m_lineSlotNodes
        for lineNodeIndex = nodeLen, 1, -1 do
            local lineNode = self.m_lineSlotNodes[lineNodeIndex]
            if lineNode ~= nil then
                lineNode:runIdleAnim()
            end
        end

        -- self:resetMaskLayerNodes()
        -- 改

        -- -- 处理特殊信号
        -- local childs = self.m_lineSlotNodes
        -- for i = 1, #childs do
        --     --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
        --     local cloumnIndex = childs[i].p_cloumnIndex
        --     if cloumnIndex then
        --         local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
        --         local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
        --         self:changeBaseParent(childs[i])
        --         childs[i]:setPosition(pos)
        --         self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
        --     end
        -- end
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

function CodeGameScreenChicEllaMachine:resetGridNodes()
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

--重写
--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenChicEllaMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        reelDatas = self.m_configData:getRespinReelDatasByColumnIndex(parentData.cloumnIndex)
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

-- 重写
--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenChicEllaMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
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
                --改
                effectData.p_effectOrder = winEffect    --用于respin结束时 先连线
                --改
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
                    --改
                    effectData.p_effectOrder = winEffect    --用于base jackpot 震动时顺序问题
                    --改
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


-- 重写 jackpot快滚
---
--添加金边
function CodeGameScreenChicEllaMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    local reelEffectNodeJackPot = nil
    local reelActJackPot = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct, reelEffectNodeJackPot, reelActJackPot = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
        reelEffectNodeJackPot = reelObj[3]
        reelActJackPot = reelObj[4]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)
    reelEffectNodeJackPot:setScaleX(1)
    reelEffectNodeJackPot:setScaleY(1)

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
    self:setLongAnimaInfo(reelEffectNodeJackPot, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")
    if self.m_isJackpotFastRun[col] then
        reelEffectNodeJackPot:setVisible(true)
        util_csbPlayForKey(reelActJackPot, "run", true)
    else
        reelEffectNode:setVisible(true)
        util_csbPlayForKey(reelAct, "run", true)
    end
    

    

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        local reelEffectNodeBGJackPot = nil
        local reelActBGJackPot = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG, reelEffectNodeBGJackPot, reelActBGJackPot = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
            reelEffectNodeBGJackPot = reelBGObj[3]
            reelActBGJackPot = reelBGObj[4]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)
        reelEffectNodeBGJackPot:setScaleX(1)
        reelEffectNodeBGJackPot:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end

        if self.m_isJackpotFastRun[col] then
            reelEffectNodeBGJackPot:setVisible(true)
            util_csbPlayForKey(reelActBGJackPot, "run", true)
        else
            reelEffectNodeBG:setVisible(true)
            util_csbPlayForKey(reelActBG, "run", true)
        end
        
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

-- 重写
function CodeGameScreenChicEllaMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_slotEffectLayer:addChild(reelEffectNode)
    -- self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)


    -- 加jackpot
    local reelEffectNodeJackPot, effectActJackPot = util_csbCreate("WinFrameChicElla_run2.csb")
    reelEffectNodeJackPot:retain()
    effectActJackPot:retain()

    self.m_slotEffectLayer:addChild(reelEffectNodeJackPot)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct, reelEffectNodeJackPot, effectActJackPot}

    reelEffectNodeJackPot:setVisible(false)

    return reelEffectNode, effectAct, reelEffectNodeJackPot, effectActJackPot
end

-- 重写
function CodeGameScreenChicEllaMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self.m_clipParent:addChild(reelEffectNode, -1)
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        if reelType == "ccui.Layout" then
            reelEffectNode:setLocalZOrder(0)
        end
        reelEffectNode:setPosition(cc.p(reel:getPosition()))
        -- self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        -- 加jackpot
        local reelEffectNodeJackPot, effectActJackPot = util_csbCreate("WinFrameChicElla_run_bg2.csb")
        reelEffectNodeJackPot:retain()
        effectActJackPot:retain()

        self.m_clipParent:addChild(reelEffectNodeJackPot, -1)
        if reelType == "ccui.Layout" then
            reelEffectNodeJackPot:setLocalZOrder(0)
        end
        reelEffectNodeJackPot:setPosition(cc.p(reel:getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct, reelEffectNodeJackPot, effectActJackPot}

        reelEffectNodeJackPot:setVisible(false)

        return reelEffectNode, effectAct, reelEffectNodeJackPot, effectActJackPot
    end
end

local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenChicEllaMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    local soundType, nextReelLong, nextReelLongJackPot = runStatus.NORUN, false, false
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            -- return runStatus.NORUN, false
            soundType = runStatus.NORUN
            nextReelLong = false
        elseif nodeNum == 2 then
            -- return runStatus.DUANG, true
            soundType = runStatus.DUANG
            nextReelLong = true
        else
            -- return runStatus.DUANG, false
            soundType = runStatus.DUANG
            nextReelLong = false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2  then
            -- return runStatus.NORUN, false
            soundType = runStatus.NORUN
            nextReelLong = false
        else
            -- return runStatus.DUANG, false
            soundType = runStatus.DUANG
            nextReelLong = false
        end
    else
        if nodeNum == 2 then
            -- return runStatus.DUANG, true
            soundType = runStatus.DUANG
            nextReelLong = true
        else
            -- return runStatus.DUANG, false
            soundType = runStatus.DUANG
            nextReelLong = false
        end
    end

    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        local iRow = self.m_iReelRowNum
        local jackPotNum = 0
        local colNoHave = {}
        for i=1,col do
            colNoHave[i] = true
        end
        for colIdx = 1, col do
            for row = 1, iRow do
                local symbolType = self.m_stcValidSymbolMatrix[row][colIdx]
                if symbolType == self.SYMBOL_JACKPOT then
                    jackPotNum = jackPotNum + 1
                    colNoHave[colIdx] = false
                end
            end
        end
    

        local isRunJackPotFast = true
        for i=1,col do
            if colNoHave[i] then
                isRunJackPotFast = false
            end
        end
        if jackPotNum >= 2 and isRunJackPotFast then
            soundType = runStatus.DUANG
            nextReelLong = true
            nextReelLongJackPot = true
        end
    end
    
    

    return soundType, nextReelLong, nextReelLongJackPot
end

-- 重写
--设置bonus scatter 信息
function CodeGameScreenChicEllaMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  true, true--reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false
    local nextReelLongJackPot = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong, nextReelLongJackPot = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    if nextReelLongJackPot then
        self.m_ScatterShowCol = {1,2,3,4,5}
    else
        self.m_ScatterShowCol = self.m_configData.p_scatterShowCol
    end

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong, nextReelLongJackPot = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

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

    self.m_isJackpotFastRun[column + 1] = nextReelLongJackPot
    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

-- 重写
---
-- 显示free spin
function CodeGameScreenChicEllaMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
    end
    

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

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
    else
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
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
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end


-- 重写
---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenChicEllaMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        -- slotNode.p_showOrder = slotNode:getLocalZOrder()

        -- print(string.format("line order parent   col: %d, row: %d, type: %d, order: %d", slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, slotNode.p_showOrder))
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()

        -- print(string.format("line order   col: %d, row: %d, type: %d, order: %d", slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, slotNode.p_showOrder))
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- 切换图层
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    util_changeNodeParent(self.m_clipParent, slotNode, 1500 + self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    -- print(string.format("连线   col: %d, row: %d, type: %d, order: %d, zorder: %d", slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, slotNode.p_showOrder, slotNode:getLocalZOrder()))
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

-- shake
function CodeGameScreenChicEllaMachine:shakeOneNodeForever(time)
    local oldPos = cc.p(self:getPosition())
    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    self:runAction(action)

    performWithDelay(self,function()
        self:stopAction(action)
        self:setPosition(oldPos)
    end,time)
end

-- 飞粒子
function CodeGameScreenChicEllaMachine:flyParticleAni(startNode,endNode,func)
    local ani = util_createAnimation("ChicElla_jackpot_lizi.csb")
    ani:findChild("Particle_1"):setPositionType(0)
    ani:findChild("Particle_2"):setPositionType(0)
    self:addChild(ani, GAME_LAYER_ORDER.LAYER_ORDER_UI + 1)

    ani:setPosition(util_convertToNodeSpace(startNode,self))

    local endPos = util_convertToNodeSpace(endNode,self)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.4, endPos),
        cc.CallFunc:create(function(  )
            if type(func) == "function" then
                func()
            end

            ani:findChild("Particle_1"):stopSystem()
            ani:findChild("Particle_2"):stopSystem()

        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })
    ani:runAction(seq)
end

--重写
--重写列停止
function CodeGameScreenChicEllaMachine:reelSchedulerCheckColumnReelDown(parentData)
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
        tipSlotNoes = self:addReelDownTipNode(nodes, speedActionTable)
 
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
    end
    return 0.1
end

--重写
--增加提示节点
function CodeGameScreenChicEllaMachine:addReelDownTipNode(nodes, speedActionTable)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then

            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode, speedActionTable)
            
            if self:checkSymbolTypePlayTipAnima( slotNode.p_symbolType )then
                
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex,slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            --                            break
            end
        --                        end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end

--重写
function CodeGameScreenChicEllaMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        if self.m_runSpinResultData.p_features 
        and self.m_runSpinResultData.p_features[2] then
        else
            delayTime = delayTime + self:getWinCoinTime()
        end


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
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
end

-- 重写
function CodeGameScreenChicEllaMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    -- 改
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:fsWildSetVisible(false)
        self:fsWildReplaceReelGrid()
    end
    -- 改

    self:showLineFrame()

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            0.5
        )
    else
        if self.m_runSpinResultData.p_features 
        and self.m_runSpinResultData.p_features[2] 
        and (self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE) then
            performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            2
        )
        else
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                performWithDelay(
                    self,
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    0.5
                )
            else
                effectData.p_isPlay = true
                self:playGameEffect()
            end
            
            
        end

        
    end

    return true
end

--重写
function CodeGameScreenChicEllaMachine:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    self:removeRespinNode()
    
    self:showRespinOverView(effectData)

    return true
end

--重写
function CodeGameScreenChicEllaMachine:triggerReSpinOverCallFun(score)
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
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        coins = self.m_serverWinCoins or 0

        -- respin退出时 连线后加的 所以声音两次  修改 声音会在后面效果连线中播放
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    -- self:resetMusicBg(true)
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

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenChicEllaMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    if math.random(0, 100) < 40 and not (self.m_jackpotWin and self.m_jackpotWin[1]) then
        self.m_isAddBigWinLightEffect = true
    else
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenChicEllaMachine:showBigWinLight(_func)
    self:shakeOneNodeForever(138/60)

    gLobalSoundManager:playSound(ChicEllaMusic.sound_ChicElla_fullscreen_celebrate)

    self.m_bigWinPlayAnim:setVisible(true)
    self.m_bigWinPlayAnim:runCsbAction("actionframe", false, function (  )
        self.m_bigWinPlayAnim:setVisible(false)
    end)

    performWithDelay(self, function()
        if type(_func) == "function" then
            _func()
        end
    end, 138/60)
end

return CodeGameScreenChicEllaMachine






