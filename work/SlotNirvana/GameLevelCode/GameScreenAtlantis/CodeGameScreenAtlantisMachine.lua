---
-- island li
-- 2019年1月26日
-- CodeGameScreenAtlantisMachine.lua
-- 
-- 玩法：
-- 

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseDialog = require "Levels.BaseDialog"

local CodeGameScreenAtlantisMachine = class("CodeGameScreenAtlantisMachine", BaseNewReelMachine)

--转场类型
local TYPE_BASE_TO_RESPIN           =           1   --base转respin
local TYPE_RESPIN_TO_FREESPIN       =           2   --respin转freespin
local TYPE_FREESPIN_TO_BASE         =           3   --freespin转base
local TYPE_BASE_IDLE                =           4   --base状态
local TYPE_RESPIN_IDLE              =           5   --respin状态
local TYPE_FREESPIN_IDLE            =           6   --freespin状态
local TYPE_NOTICE                   =           7   --预告中奖

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


CodeGameScreenAtlantisMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenAtlantisMachine.SYMBOL_BONUS_LINK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- bonus
CodeGameScreenAtlantisMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenAtlantisMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2

CodeGameScreenAtlantisMachine.EFFECT_COLLOCTION  =   GameEffect.EFFECT_LINE_FRAME + 1     --收集
CodeGameScreenAtlantisMachine.EFFECT_FLY_ANI  =   GameEffect.EFFECT_LINE_FRAME + 2     --收集

CodeGameScreenAtlantisMachine.m_csb_fps = 60     --csb帧率
CodeGameScreenAtlantisMachine.m_alreadyColloctScore = {}        --已收集的freespin分数

-- 构造函数
function CodeGameScreenAtlantisMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_spinRestMusicBG = true

    -- 小块，连线框，基础baseDialog弹板csb 根据实际帧率设置
    self.m_slotsAnimNodeFps = 60
    self.m_lineFrameNodeFps = 60 
    self.m_baseDialogViewFps = 60

    self.m_isRespin_normal = false
    self.m_isFeatureOverBigWinInFree = true

    self.m_reelRunSound = "AtlantisSounds/sound_Atlantis_quick_run.mp3.mp3"--快滚音效
    
    --init
    self:initGame()
end

function CodeGameScreenAtlantisMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("AtlantisConfig.csv", "LevelAtlantisConfig.lua")
    self.m_configData.m_machine = self
    --初始化基本数据
    self:initMachine(self.m_moduleName)

    local bgNode =  self:findChild("bg")
    bgNode:setScale(1.1)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 3 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "AtlantisSounds/sound_Atlantis_win_" .. i .. ".mp3"
    end
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAtlantisMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Atlantis"  
end

--[[
    获取respin界面
]]
function CodeGameScreenAtlantisMachine:getRespinView()
    return "CodeAtlantisSrc.AtlantisRespinView"
end

function CodeGameScreenAtlantisMachine:getRespinNode()
    return "CodeAtlantisSrc.AtlantisRespinNode"
end

function CodeGameScreenAtlantisMachine:initFreeSpinBar()

    local node_bar = self.m_bottomUI:findChild("node_bar")
    
    self.m_baseFreeSpinBar = util_createView("Levels.FreeSpinBar")
    node_bar:addChild(self.m_baseFreeSpinBar)
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,node_bar)
    self.m_baseFreeSpinBar:setPosition(cc.p(pos.x,73))
    self.m_baseFreeSpinBar:setScale(0.8)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

-- function CodeGameScreenAtlantisMachine:showFreeSpinBar()
--     if not self.m_baseFreeSpinBar then
--         return
--     end
--     util_setCsbVisible(self.m_baseFreeSpinBar, true)
--     self.m_baseFreeSpinBar:runCsbAction("start",false,function(  )
--         self.m_baseFreeSpinBar:runCsbAction("idle")
--     end)
-- end

-- function CodeGameScreenAtlantisMachine:hideFreeSpinBar()
--     if not self.m_baseFreeSpinBar then
--         return
--     end
--     self.m_baseFreeSpinBar:runCsbAction("over",false,function(  )
--         util_setCsbVisible(self.m_baseFreeSpinBar, false)
--     end)
    
-- end


function CodeGameScreenAtlantisMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_AtlantisView = util_createView("CodeAtlantisSrc.AtlantisView")
    -- self:findChild("xxxx"):addChild(self.m_AtlantisView)

    self:addClick(self:findChild("Panel"))
    for index=1,self.m_iReelColumnNum do
        self:addClick(self:findChild("sp_reel_"..(index - 1)))
    end
   
    --jackpot
    self.m_jackpot = util_createView("CodeAtlantisSrc.AtlantisJackPotBarView")
    self:findChild("Jackpot"):addChild(self.m_jackpot)
    self.m_jackpot:initMachine(self)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    --光效层
    self.m_lightEffectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_lightEffectNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    -- self.m_lightEffectNode:setScale(self.m_machineNode:getScale())
    

    --背景雕像
    self.m_bg_statue = util_spineCreate("Diaosu_Alantis", true, true)
    self:findChild("gold_reel"):addChild(self.m_bg_statue,GAME_LAYER_ORDER.LAYER_ORDER_BG)
 
    --收集条
    self.m_colloction_bar = util_createView("CodeAtlantisSrc.AtlantisColloctionbar",{machine = self})
    self:findChild("Collect"):addChild(self.m_colloction_bar)

    --respin bar
    self.m_respin_bar = util_createView("CodeAtlantisSrc.AtlantisRespinBar",{machine = self})
    self:findChild("gold_reel"):addChild(self.m_respin_bar,GAME_LAYER_ORDER.LAYER_ORDER_BG + 10)
    self.m_respin_bar:setShow(false)

    --freespin 收集栏
    self.m_free_colloction = util_createView("CodeAtlantisSrc.AtlantisFreespinColloction")
    self:findChild("gold_reel"):addChild(self.m_free_colloction,GAME_LAYER_ORDER.LAYER_ORDER_BG + 20)
    self.m_free_colloction:setVisible(false)

    --freespin赢钱节点
    self.m_fs_winCoin = util_createView("CodeAtlantisSrc.AtlantisWinCoinNode")
    self.m_fs_winCoin:setVisible(false)
    self:findChild("FreeSpins"):addChild(self.m_fs_winCoin,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)

    self.m_effect_fast_bg = {}  --快滚背景
    for index=1,5 do
        if index > 2 then
            local effect = util_createAnimation("LongRunFrame_Atlantis_bg.csb")
            effect:runCsbAction("run",true) 
            self:findChild("sp_reel_"..(index - 1)):addChild(effect)
            self.m_effect_fast_bg[index] = effect
            effect:setVisible(false)
        end
    end

    --预告中奖光效
    self.m_notice_effect = util_createAnimation("Atlantis/GameScreenAtlantis_reelyugao.csb")
    self:findChild('yugao'):addChild(self.m_notice_effect,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_notice_effect:setVisible(false)

    self:initLayerBlack()
end

--[[
    初始化黑色遮罩层
]]
function CodeGameScreenAtlantisMachine:initLayerBlack()

    local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_2 ,cc.c3b(0, 0, 0),130)
    self.m_layer_colors = colorLayers
    for key,layer in pairs(self.m_layer_colors) do
        layer:setVisible(false)
    end
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenAtlantisMachine:showLayerBlack(isShow)
    for key,layer in pairs(self.m_layer_colors) do
        layer:setVisible(isShow)
    end
end

function CodeGameScreenAtlantisMachine:clickFunc(sender)
    self.m_colloction_bar:removeTips()

    --freespin结束数字跳动
    if self.m_endCoin then
        self.m_fs_winCoin:endJump(self.m_endCoin)
    end
end

--[[
    初始化随机轮盘
]]
function CodeGameScreenAtlantisMachine:randomSlotNodes( )
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local randIndex = math.random(1,#reelDatas)
        for rowIndex=1,rowCount do
            local symbolType = reelDatas[randIndex]
            randIndex = randIndex + 1
            if randIndex > #reelDatas then
                randIndex = 1
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex
           

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end
            
--            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )

           
        end
    end
    self:initGridList()
end

function CodeGameScreenAtlantisMachine:enterGamePlayMusic(  )

    scheduler.performWithDelayGlobal(function(  )
        
    self:playEnterGameSound( "AtlantisSounds/sound_Atlantis_enter.mp3" )
    scheduler.performWithDelayGlobal(function(  )
        if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            self:resetMusicBg()
            self:reelsDownDelaySetMusicBGVolume( ) 
        end
    end,3,self:getModuleName())
    

    end,0.4,self:getModuleName())
end

function CodeGameScreenAtlantisMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenAtlantisMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self, params)
        self.m_colloction_bar:removeTips()
    end,ViewEventType.NOTIFY_CLOSE_PIG_TIPS)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if self.m_bIsBigWin or self:getCurrSpinMode() == RESPIN_MODE then
            return
        end
        local winAmonut = params[1]
        if type(winAmonut) == "number" then
            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local winRatio = winAmonut / lTatolBetNum
            local soundName = nil
            local soundTime = 2
            if winRatio > 0 then
                if winRatio <= 1 then
                    soundName = self.m_winPrizeSounds[1]
                elseif winRatio > 1 and winRatio <= 3 then
                    soundName = self.m_winPrizeSounds[2]
                elseif winRatio > 3 then
                    soundName = self.m_winPrizeSounds[3]
                    soundTime = 3
                end
            end

            if soundName ~= nil then
                self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
            end
        end

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenAtlantisMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenAtlantisMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local index = 0
    local storedInfo = {}
    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            for i = 1, #storedIcons do
                if storedIcons[i] == index then
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


--[[
    玩法触发检测
]]
function CodeGameScreenAtlantisMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and 
        #self.m_runSpinResultData.p_features > 0 then
        
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i=1,featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的， 
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    else
                        -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                        globalData.slotRunData.totalFreeSpinCount = 0
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    end

                    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes

                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then  -- 触发respin 玩法
                    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 and 
                        #self.m_runSpinResultData.p_storedIcons == 15 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then  -- 其他小游戏

                    -- 添加 BonusEffect 
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end

            end
            
        end

    end
end


--[[
    刷新收集进度
]]
function CodeGameScreenAtlantisMachine:refreshColloctionBar()
    if not self.m_runSpinResultData.p_selfMakeData or not self.m_runSpinResultData.p_selfMakeData.freespinCount then
        return
    end

    self.m_colloction_bar:updateBar(self.m_runSpinResultData.p_selfMakeData.freespinCount)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAtlantisMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BONUS_LINK then
        return "Socre_Atlantis_Bonus"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Atlantis_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_Atlantis_11"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAtlantisMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--[[
    刷新小块
]]
function CodeGameScreenAtlantisMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType    --信号类型
    local reelNode = node
    if symbolType and symbolType == self.SYMBOL_BONUS_LINK then    --Bouns信号
        self:setSpecialNodeScore(node)
    end
end

--[[
    设置特殊小块分数
]]
function CodeGameScreenAtlantisMachine:setSpecialNodeScore(node)
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
        --获取真实分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        if storedIcons then
            score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) or 1
        end
        
    else
        --设置假滚Bonus,随机分数
        score = self:randomDownSymbolScore(symbolNode.p_symbolType)
        if score == nil then
            score = 1
        end
    end

    if score and type(score) ~= "string" then
        -- --获取当前下注
        -- local lineBet = globalData.slotRunData:getCurTotalBet()
        -- score = score * lineBet
        -- --格式化字符串
        -- score = util_formatCoins(score, 3)
        if symbolNode then
            local lbl_score = symbolNode:getCcbProperty("chengbei")
            if lbl_score then
                lbl_score:setString(score.."X")
                self:updateLabelSize({label=lbl_score,sx=0.4,sy=0.4},310)
            end
        end
    end
end

--[[
    获取小块真实分数
]]
function CodeGameScreenAtlantisMachine:getSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenAtlantisMachine:randomDownSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS_LINK then
        score = self.m_configData:getBnBasePro(1)
    end

    return score
end

function CodeGameScreenAtlantisMachine:updateNetWorkData()

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
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.reward then
    -- if true then
        self:showLayerBlack(true)
        self:statueAni(TYPE_NOTICE,function(  )
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData()  -- end
        end)
    else
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()  -- end
    end

    
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenAtlantisMachine:MachineRule_initGame(  )
    self:refreshColloctionBar()
    
    self:statueAni(TYPE_BASE_IDLE)

    if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        self:setCurrSpinMode(FREE_SPIN_MODE)
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        

        
        self.m_fs_winCoin:showView()
        self.m_colloction_bar:setShow(false)
        local fsData = self.m_runSpinResultData.p_fsExtraData

        local selfData = self.m_runSpinResultData.p_selfMakeData
        local isSuperFs = false
        if selfData.freespinCount >= 10 or selfData.freespinCount == 0 then
            self.m_bottomUI:showAverageBet()
            isSuperFs = true
        end

        if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
            self:statueAni(TYPE_RESPIN_IDLE)
        else
            self:statueAni(TYPE_FREESPIN_IDLE)
            if isSuperFs then
                self.m_free_colloction:showSuperFsTipIdle()
            end
        end

        --刷新收集栏
        self.m_free_colloction:refreshUI(fsData)
        if fsData.index then
            --显示freespin收集栏
            self.m_free_colloction:setVisible(true)
            self.m_free_colloction:idleAni()
            for curIndex = 1,fsData.index do
                self.m_alreadyColloctScore[curIndex] = true
            end
        end
        
    end

    -- if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
    --     self:statueAni(TYPE_BASE_IDLE)
    -- end
end

---
-- 检测上次feature 数据
--
function CodeGameScreenAtlantisMachine:checkNetDataFeatures()

    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    local selfData = self.m_initSpinData.p_selfMakeData
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN and (selfData and selfData.freespinCount ~= 0) then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true
            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                end
                if checkEnd == true then
                    break
                end

            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            local params = {self.m_runSpinResultData.p_fsWinCoins,false,false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)

            -- self:sortGameEffects( )
            -- self:playGameEffect()

        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then  -- respin 玩法一并通过respinCount 来进行判断处理
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true
            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})


            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then

                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                    
                end
                
                if checkEnd == true then
                    break
                end

            end

            -- self:sortGameEffects( )
            -- self:playGameEffect()


        end
    end

end

function CodeGameScreenAtlantisMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:checkNotifyUpdateWinCoin()
    end

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            if frameIndex > #winLines  then
                frameIndex = 1
                if self.m_showLineHandlerID ~= nil then

                    scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                    self.m_showLineHandlerID = nil
                    self:showAllFrame(winLines)
                    self:playInLineNodes()
                    showLienFrameByIndex()
                end
                return
            end
            self:playInLineNodesIdle()
            -- 跳过scatter bonus 触发的连线
            while true do
                if frameIndex > #winLines then
                    break
                end
                -- print("showLine ... ")
                local lineData = winLines[frameIndex]

                if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                    end
                else
                    break
                end
            end
            -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
            -- 所以打上一个判断
            if frameIndex > #winLines  then
                frameIndex = 1
            end

            self:showLineFrameByIndex(winLines,frameIndex)

            frameIndex = frameIndex + 1
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
        self:getCurrSpinMode() == FREE_SPIN_MODE then


        self:showAllFrame(winLines)  -- 播放全部线框

        -- if #winLines > 1 then
            showLienFrameByIndex()
        -- end

    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end


        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines,1)
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
function CodeGameScreenAtlantisMachine:checkTriggerINFreeSpin( )
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
    if hasFreepinFeature == false and 
            self.m_initSpinData.p_freeSpinsTotalCount ~= nil and 
            self.m_initSpinData.p_freeSpinsTotalCount > 0 and 
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or 
                (hasReSpinFeature == true  or hasBonusFeature == true)) then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self:checkTriggerFsOver( ) then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end

        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins,false,false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end

function CodeGameScreenAtlantisMachine:checkSymbolTypePlayTipAnima( symbolType )

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
        return true
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS  then
        return true
    elseif symbolType == self.SYMBOL_BONUS_LINK  then
        return true
    end

end

--[[
    是否播放落地动画
]]
function CodeGameScreenAtlantisMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
    local nodeData = self.m_reelRunInfo[matrixPosY]:getSlotsNodeInfo()

    if node.p_symbolType == self.SYMBOL_BONUS_LINK then
        return true
    end

    if nodeData ~= nil and #nodeData ~= 0 then
        for i = 1, #nodeData do
            if self.m_bigSymbolInfos[node.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[node.p_symbolType]
                local startRowIndex = node.p_rowIndex
                local endRowIndex = node.p_rowIndex + symbolCount
                if nodeData[i].x >= matrixPosX and nodeData[i].x <= endRowIndex and nodeData[i].y == matrixPosY then
                    if nodeData[i].bIsPlay == true then
                        return true
                    end
                end
            else
                if nodeData[i].x == matrixPosX and nodeData[i].y == matrixPosY then
                    if nodeData[i].bIsPlay == true then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function CodeGameScreenAtlantisMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_BONUS_LINK, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

function CodeGameScreenAtlantisMachine:getLongRunLen(col, index)
    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
    len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    return len
end

--设置bonus scatter 信息
function CodeGameScreenAtlantisMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  false,false--reelRunData:getSpeicalSybolRunInfo(symbolType)

    if symbolType == self.SYMBOL_BONUS_LINK then
        bRun, bPlayAni = true,true
    end
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

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenAtlantisMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    -- if nodeNum < 4 then
    --     return runStatus.NORUN, false
    -- else
    --     return runStatus.DUANG, true
    -- end
    
    --没有快滚玩法
    return runStatus.NORUN, false
end

--[[
    添加快滚特效
]]
function CodeGameScreenAtlantisMachine:creatReelRunAnimation(col)
    CodeGameScreenAtlantisMachine.super.creatReelRunAnimation(self,col)
    if col > 2 then
        self.m_effect_fast_bg[col]:setVisible(true)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenAtlantisMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
    if reelCol > 2 then
        self.m_effect_fast_bg[reelCol]:setVisible(false)
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        local slotNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if slotNode.p_symbolType == self.SYMBOL_BONUS_LINK then
            gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_bonus_down.mp3")
            break;
        end
    end
end


---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenAtlantisMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenAtlantisMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenAtlantisMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("AtlantisSounds/music_Atlantis_custom_enter_fs.mp3")

    

    local showFSView = function ( ... )
        self.m_colloction_bar:setShow(false)
        -- self.m_bg_statue:setVisible(false)
        --freespin次数条
        self:showFreeSpinBar()
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_fs_winCoin:showView()

        self:showLayerBlack(true)

        --刷新收集栏
        self.m_free_colloction:refreshUI(self.m_runSpinResultData.p_fsExtraData)

        --清空赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

        local selfData = self.m_runSpinResultData.p_selfMakeData
        local isSuperFs = false
        --超级freespin
        if selfData.freespinCount >= 10 or selfData.freespinCount == 0 then
            self.m_bottomUI:showAverageBet()
            isSuperFs = true
        end

        --结束动画
        self.m_respin_bar:setShow(true)
        self.m_respin_bar:refreshUI(self.m_runSpinResultData,true)
        self.m_respin_bar:OverAni1(function(  )
            --雕塑执行下沉动作
            self:statueAni(TYPE_RESPIN_TO_FREESPIN,function(  )
                --显示freespin收集栏
                self.m_free_colloction:showAni(isSuperFs,function()
                    self:colloctFsCountAni(function(  )
                        --freespin弹版
                        self:showFreeSpinStart(globalData.slotRunData.freeSpinCount,function(  )
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect() 
                        end)
                    end)
                end)
            end)
            self.m_respin_bar:OverAni2(function()
                self.m_respin_bar:setShow(false)
            end)
        end)
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

--[[
    收集freespin次数动画
]]
function CodeGameScreenAtlantisMachine:colloctFsCountAni(func)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    util_bubbleSort(storedIcons,function(a,b)
        --升序排序 相同大小按索引排序
        return a[2] < b[2] or (a[2] == b[2] and a[1] < b[1])
    end)
    
    performWithDelay(self,function(  )
        --开始收集
        self:colloctNextBonus(storedIcons,1,function()
            if type(func) == "function" then
                func()
            end
        end) 
    end,1)
    
end

--[[
    收集下个bonus
]]
function CodeGameScreenAtlantisMachine:colloctNextBonus(data,index,func)
    if index > #data then
        if type(func) == "function" then
            func()
        end
        return
    end

    local bonusInfo = data[index]

    local pos = self:getRowAndColByPos(bonusInfo[1])
    local symbol = self:getFixSymbol(pos.iY , pos.iX)
    local endNode = self.m_free_colloction:getNodeByIndex(index)
    endNode:findChild("di_1"):setVisible(false)

    --关键帧回调
    local keyCallFunc = function(  )
        self.m_free_colloction:activeAni(index,self.m_runSpinResultData.p_fsExtraData)
    end

    --结束回调
    local endFunc = function(  )
        self:colloctNextBonus(data,index + 1,func)
    end

    symbol:runAnim("dark",false,function(  )
        symbol:runAnim("idleframe2")
    end)

    --飞粒子效果
    self:runFlyLineAct(symbol,endNode,keyCallFunc,endFunc)

end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenAtlantisMachine:showDialog(ccbName,ownerlist,func,isAuto,index,isView)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index,self.m_baseDialogViewFps)
    view:updateOwnerVar(ownerlist)

    

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    if isView then
        gLobalViewManager:showUI(view)
    else
        self:findChild("Node_reel"):addChild(view,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    end
    

    return view
end

function CodeGameScreenAtlantisMachine:showFreeSpinStart(num,func)
    self.m_sound_fsStart = gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_show_freespin_start.mp3")
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    local view = self:showDialog("FreeSpinStartNode",ownerlist,function(  )
        --压黑信号恢复普通状态
        for iCol=1,self.m_iReelColumnNum do
            for iRow=1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol, iRow)
                symbol:runAnim("idleframe")
            end
        end

        self:showLayerBlack(false)

        if self.m_sound_fsStart then
            gLobalSoundManager:stopAudio(self.m_sound_fsStart)
            self.m_sound_fsStart = nil
        end
        if type(func) == "function" then
            func()
        end
    end,BaseDialog.AUTO_TYPE_NOMAL)
    local csb_bg = util_createAnimation("Qiu_Atlantis.csb")
    csb_bg:runCsbAction("idle",true)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    self.m_alreadyColloctScore = {}

    csb_bg:runCsbAction("idle")
    view:findChild("node_qiu"):addChild(csb_bg)

    --超级freespin
    view:findChild("Atlantis_superfreegamesaward"):setVisible(self.m_isSuperFs)
    view:findChild("Atlantis_freegamesaward"):setVisible(not self.m_isSuperFs)

    view:addClick(view:findChild("Panel"))
    return view
end

---
-- 显示free spin over 动画
function CodeGameScreenAtlantisMachine:showEffect_FreeSpinOver()

    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")
    self.m_freeSpinOverCurrentTime = 1

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
        self.m_fsOverHandlerID =scheduler.scheduleGlobal(function()
            if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
                self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
            else
                self:showEffect_newFreeSpinOver()
            end
        end,0.1)
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenAtlantisMachine:showFreeSpinOverView()
    -- gLobalSoundManager:playSound("AtlantisSounds/music_Atlantis_over_fs.mp3")

    self.m_alreadyColloctScore = {}
    self.m_isFsOver = true
    self:freeSpinCleanAni(function(  )
        self.m_isFsOver = false
        
        local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,30)
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            waitNode:removeFromParent(true)
            self.m_bottomUI:hideAverageBet()
            self.m_isSuperFs = false
            self.m_fs_winCoin:hideView()
            self.m_free_colloction:hideSuperTip()
            self.m_free_colloction:setVisible(false)
            self.m_colloction_bar:setShow(true)
            self.m_colloction_bar:idleAni()
            self.m_colloction_bar:updateBar(self.m_runSpinResultData.p_selfMakeData.freespinCount) 
            self.m_bg_statue:setVisible(true)     
            util_spinePlay(self.m_bg_statue,"idle_base")
            
            local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:statueAni(TYPE_FREESPIN_TO_BASE)
                self:triggerFreeSpinOverCallFun()
            end)
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=0.95,sy=0.95},686)
        end,0.5)
        
    end)
    
end

function CodeGameScreenAtlantisMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_show_freespin_over.mp3")
    
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=coins
    local isAuto = (self:getCurrSpinMode() == AUTO_SPIN_MODE) and BaseDialog.AUTO_TYPE_NOMAL or nil
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func,isAuto,nil,true)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local light = util_createAnimation("Atlantis/FreeSpinOver_bg_guang.csb")
    light:runCsbAction("idle",true)

    view:findChild("node_guang"):addChild(light)

    local freeSpinCount = self.m_runSpinResultData.p_selfMakeData.freespinCount

    local node_superFree = view:findChild("Atlantis_insuperfree")
    local node_freeGames = view:findChild("Atlantis_infreegames")
    node_superFree:getChildByName("m_lb_num"):setString(num)
    node_freeGames:getChildByName("m_lb_num"):setString(num)

    self.m_isRespin_normal = false

    if freeSpinCount == 0 then  --是否处于超级freespin
        node_superFree:setVisible(true)
        node_freeGames:setVisible(false)
    else
        node_superFree:setVisible(false)
        node_freeGames:setVisible(true)
    end

    return view
end

--[[
    freespin结算动效
]]
function CodeGameScreenAtlantisMachine:freeSpinCleanAni(func)
    --开始收集
    self:cleanNext(1,function(  )
        if type(func) == "function" then
            func()
        end
    end)
end


--[[
    结算下个bonus
]]
function CodeGameScreenAtlantisMachine:cleanNext(index,func)
    local fsData = self.m_runSpinResultData.p_fsExtraData
    if index > #fsData.freeWinCoins then
        if type(func) == "function" then
            func()
        end
        return
    end

    if tonumber(fsData.freeWinCoins[index]) == 0 then
        self:cleanNext(index + 1,func)
        return
    end

    local startNode = self.m_free_colloction:getNodeByIndex(index)
    local endNode = self.m_bottomUI.coinWinNode

    --关键帧回调
    local keyCallFunc = function(  )
        local totalWin = 0
        for i = 1,index do
            totalWin = totalWin + tonumber(fsData.freeWinCoins[i]) --* fsData.multiplies[index]
        end
        --刷新赢钱
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWin))

        -- local light_temp = util_createAnimation("TotalWin_Atlantis.csb")
        -- endNode:addChild(light_temp)
        -- local params = {}
        -- params[1] = {
        --     type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        --     node = light_temp,   --执行动画节点  必传参数
        --     actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        --     fps = self.m_csb_fps,    --帧率  可选参数
        --     callBack = function(  )
        --         light_temp:removeFromParent(true)
        --     end,   --回调函数 可选参数
        -- }
        -- util_runAnimations(params)
        self:playCoinWinEffectUI()
    end

    --结束回调
    local endFunc = function(  )
        self:cleanNext(index + 1,func)
    end
    startNode:runCsbAction("idleframe3")
    --飞粒子效果
    self:runFlyLineAct(startNode,endNode,keyCallFunc,endFunc)

end




---------------- Spin逻辑开始时触发

function CodeGameScreenAtlantisMachine:playEffectNotifyNextSpinCall( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    if (self.m_bQuestComplete or self.m_isRespin_normal) and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        if self.m_bQuestComplete then
            self:showQuestCompleteTip()
        end
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenAtlantisMachine:normalSpinBtnCall()
    BaseNewReelMachine.normalSpinBtnCall(self)

    --freespin模式下逻辑
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local fsData = self.m_runSpinResultData.p_fsExtraData
        local curIndex = fsData.index or 0
        self.m_free_colloction:runCurItemAni(curIndex + 1)
    end
    
    self.m_colloction_bar:removeTips()
    self.m_colloction_bar.m_isWaitting = true
end

function CodeGameScreenAtlantisMachine:callSpinBtn()

    if globalData.GameConfig.checkNormalReel  then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end 
    end
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToAutospinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
            end
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE  then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToFreespinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToFreespinReelRunLen()
            end
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE
     and self:getCurrSpinMode() ~= RESPIN_MODE and betCoin > totalCoin then
        self:operaUserOutCoins()
    else
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
            self:getCurrSpinMode() ~= RESPIN_MODE
         then
            self:callSpinTakeOffBetCoin(betCoin)

        else
            self:takeSpinNextData()
        end

        --统计quest spin次数
        self:staticsQuestSpinData()


        self:spinBtnEnProc()

        self:setGameSpinStage( GAME_MODE_ONE_RUN )

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

-- 用于延时滚动轮盘等
function CodeGameScreenAtlantisMachine:MachineRule_SpinBtnCall()
    
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    -- self:setMaxMusicBGVolume( )
   

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAtlantisMachine:addSelfEffect()

    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    --收集玩法特效
    if selfData.freespinCount > self.m_colloction_bar.m_collot_count then
        local selfGameEffect = GameEffectData.new()
        selfGameEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfGameEffect.p_effectOrder = self.EFFECT_COLLOCTION
        self.m_gameEffects[#self.m_gameEffects + 1] = selfGameEffect
        selfGameEffect.p_selfEffectType = self.EFFECT_COLLOCTION -- 动画类型
    end

    --freespin飞粒子特效
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        
        
        local selfGameEffect = GameEffectData.new()
        selfGameEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfGameEffect.p_effectOrder = self.EFFECT_FLY_ANI
        self.m_gameEffects[#self.m_gameEffects + 1] = selfGameEffect
        selfGameEffect.p_selfEffectType = self.EFFECT_FLY_ANI -- 动画类型
    end
end

--服务端网络数据返回成功后处理

function CodeGameScreenAtlantisMachine:MachineRule_afterNetWorkLineLogicCalculate()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end

    for key,mode in pairs(self.m_runSpinResultData.p_features) do
        if mode == SLOTO_FEATURE.FEATURE_RESPIN then
            self.m_isRespin_normal = true
            break
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAtlantisMachine:MachineRule_playSelfEffect(effectData)
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local fsData = self.m_runSpinResultData.p_fsExtraData
    --超级freespin收集
    if effectData.p_selfEffectType == self.EFFECT_COLLOCTION then
        self:superFreeColloction(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    --freespin飞粒子
    if effectData.p_selfEffectType == self.EFFECT_FLY_ANI then
        self:freespinWinCoin(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    return true
end

--[[
    freespin赢钱
]]
function CodeGameScreenAtlantisMachine:freespinWinCoin(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local fsData = self.m_runSpinResultData.p_fsExtraData

    local curIndex = fsData.index
    local winCoin = self.m_runSpinResultData.p_winAmount
    if winCoin and winCoin > 0 then
        --创建赢钱lable
        -- self.m_fs_winCoin:showView()

        local curMultiplies = fsData.multiplies[curIndex]
        --当前结束跳动金币数
        self.m_endCoin = winCoin / curMultiplies
        --延时节点
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        --跳动金币
        self.m_fs_winCoin:jumpCoin(0,self.m_endCoin,1,handler(nil, function(  )
            self.m_alreadyColloctScore[curIndex] = true
            local node_colloct = self.m_free_colloction:getNodeByIndex(fsData.index) 
            local coinWinNode = self.m_fs_winCoin.m_lb_coins
            --数字跳动完0.5s后飞粒子
            performWithDelay(waitNode,handler(nil,function(  )
                local flyNode = self:runFlyLineAct(node_colloct,coinWinNode,handler(nil, function (  )
                    -- self.m_fs_winCoin:lightAni()
                    self.m_fs_winCoin:jumpCoin(self.m_endCoin,winCoin,2,handler(nil, function(  )
                        --刷新收集板数据
                        self.m_free_colloction:rewardAni(curIndex,fsData)
                        self.m_endCoin = nil
                        
                        --数字跳动完0.5s后飞粒子
                        performWithDelay(waitNode,function(  )
                            --移除延时节点
                            waitNode:removeFromParent(true)
                            -- self.m_fs_winCoin:hideView()
                            self.m_free_colloction:refreshUI(fsData)
                            if type(func) == "function" then
                                func()
                            end
                        end,0.5)
                    end))
                    
                    self.m_endCoin = winCoin
                end))
                --获取乘倍标签
                local lbl_multiplied = node_colloct:findChild("chengbei")
                --创建临时乘倍标签和粒子一起飞下去
                local lbl_fnt_temp = ccui.TextBMFont:create()
                lbl_fnt_temp:setFntFile("Font/font_02.fnt")
                lbl_fnt_temp:setString(lbl_multiplied:getString())
                lbl_fnt_temp:setScale(0.5)
                lbl_fnt_temp:setAnchorPoint(0.5, 0.5)
                lbl_fnt_temp:setPosition(util_convertToNodeSpace(lbl_multiplied,self.m_effectNode))
                self.m_effectNode:addChild(lbl_fnt_temp)
                lbl_fnt_temp:setLocalZOrder(flyNode:getLocalZOrder() + 1)
                lbl_fnt_temp:runAction(cc.Sequence:create({
                    cc.MoveTo:create(0.27,util_convertToNodeSpace(coinWinNode,self.m_effectNode)),
                    cc.RemoveSelf:create(true)
                }))
                --隐藏原来的乘倍标签
                lbl_multiplied:setVisible(false)

            end),0.5)
            
        end))
        
    else
        self.m_free_colloction:refreshUI(fsData)
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    超级freespin收集进度动画
]]
function CodeGameScreenAtlantisMachine:superFreeColloction(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_respin_trigger.mp3")
    --bonus图标播放动作
    for iRow =1,self.m_iReelRowNum do
        for iCol=1,self.m_iReelColumnNum do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol.p_symbolType ~= nil and symbol.p_symbolType == self.SYMBOL_BONUS_LINK  then
                symbol:getCCBNode():runAnim("actionframe",false,function(  )
                    symbol:getCCBNode():runAnim("idleframe",true)
                end,self.m_csb_fps)
            end
        end
    end

    -- local waitNode1 = cc.Node:create()
    -- self:addChild(waitNode1)
    -- performWithDelay(waitNode1,function (  )
    --     waitNode1:removeFromParent(true)
    --     --刷新收集进度
    --     self.m_colloction_bar:colloctionAni(selfData.freespinCount)
    -- end,0.75)

    local waitNode2 = cc.Node:create()
    self:addChild(waitNode2)
    performWithDelay(waitNode2,function (  )
        waitNode2:removeFromParent(true)
        gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_colloct.mp3")
        self.m_colloction_bar:colloctionAni(selfData.freespinCount,function(  )
            if selfData.freespinCount >= 10 then
                self.m_isSuperFs = true
                
                self.m_colloction_bar:colloctFullAni(function(  )
                    --雕塑转场
                    self:statueAni(TYPE_BASE_TO_RESPIN,function(  )
                        if type(func) == "function" then
                            func()
                        end
                    end)
                end)
            else
                --雕塑转场
                self:statueAni(TYPE_BASE_TO_RESPIN,function(  )
                    if type(func) == "function" then
                        func()
                    end
                end)
            end
        end)
    end,2)
end

--[[
    过场
    aniType 'start' 开始 "over"消失
]]
function CodeGameScreenAtlantisMachine:changeSceneAni(aniType,func)
    local ani = util_createAnimation("Socre_Atlantis_guochang.csb")
    self:findChild("root"):addChild(ani,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)
    local actionName = "guochang"
    if aniType == "over" then
        actionName = "guochang1"
    end

    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = ani,   --执行动画节点  必传参数
        actionName = actionName, --动作名称  动画必传参数,单延时动作可不传
        soundFile = "AtlantisSounds/sound_Atlantis_changeScene.mp3",
        fps = self.m_csb_fps,    --帧率  可选参数
        callBack = function(  )
            if type(func) == "function" then
                func()
            end
            ani:removeFromParent(true)
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)
end

--[[
    雕塑动作

]]
function CodeGameScreenAtlantisMachine:statueAni(aniType,func)
    self.m_bg_statue:setVisible(true)
    if aniType == TYPE_BASE_TO_RESPIN then  --base转respin
        
        self:runCsbAction("idle")
        util_runAnimations({
            {
                type = "spine",
                node = self.m_bg_statue,   
                actionName = "upReel", 
                soundFile = "AtlantisSounds/sound_Atlantis_statue_knock.mp3",
                callBack = function (  )
                    self:statueAni(TYPE_RESPIN_IDLE)
                end,   --回调函数 可选参数
            }
        })

        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent(true)
            
            if type(func) == "function" then
                func()
            end
        end,0.27)

    elseif aniType == TYPE_RESPIN_IDLE then    --respin状态静帧
        self:runCsbAction("freespin")
        --respin和freespin静帧
        util_spinePlay(self.m_bg_statue,"idle_free")
        --更换背景
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"respin",true})
    elseif aniType == TYPE_FREESPIN_IDLE then  --freespin状态下隐藏
        self:runCsbAction("freespin")
        self.m_bg_statue:setVisible(false)
        --freespin下用respin的背景
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"respin",true})
        -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"freespin",true})
    elseif aniType == TYPE_BASE_IDLE then   --base下静帧
        self:runCsbAction("idle")
        --respin和freespin静帧
        util_spinePlay(self.m_bg_statue,"idle_base")
        --更换背景
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"normal",true})
    elseif aniType == TYPE_FREESPIN_TO_BASE then --freespin转base
        --更换背景
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"free_base",false,function (  )
            self:statueAni(TYPE_BASE_IDLE)
        end})
        
    elseif aniType == TYPE_RESPIN_TO_FREESPIN then  --respin转freeSpin
        
        self.m_bg_statue:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BG + 11)
        util_runAnimations({
            {
                type = "spine",
                node = self.m_bg_statue,   
                actionName = "upReel", 
                soundFile = "AtlantisSounds/sound_Atlantis_statue_knock.mp3",
                callBack = function (  )
                    self:runCsbAction("down",false,nil,self.m_csb_fps)
                end,   --回调函数 可选参数
            },
            {
                type = "spine",
                node = self.m_bg_statue,   
                actionName = "down", 
                callBack = function (  )
                    self.m_bg_statue:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BG)
                    self:statueAni(TYPE_FREESPIN_IDLE)
                end,   --回调函数 可选参数
            }
        })

        local wait_node1 = cc.Node:create()
        self:addChild(wait_node1)
        performWithDelay(wait_node1,function(  )
            wait_node1:removeFromParent(true)
            --更换背景
            -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"respin_free",false,function (  )
                
            -- end})
        end,0.85)

        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent(true)
            if type(func) == "function" then
                func()
            end
        end,1.5)
    elseif aniType == TYPE_NOTICE then
        self.m_noticeSoundId = gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_notice.mp3")
        util_runAnimations({
            {
                type = "spine",
                node = self.m_bg_statue,   
                actionName = "start_qidai", 
                callBack = function (  )
                    util_spinePlay(self.m_bg_statue,"idle_qidai",true)
                    if type(func) == "function" then
                        func()
                    end
                end,   --回调函数 可选参数
            }
        })
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent(true)
            --预告中奖
            self.m_notice_effect:setVisible(true)
            util_runAnimations({
                {
                    type = "animation",
                    node = self.m_notice_effect,   
                    actionName = "start", 
                    callBack = function (  )
                        self.m_notice_effect:runCsbAction("idle",true)
                    end,   --回调函数 可选参数
                }
            })
            self:runCsbAction("yugao",true)
        end,0.27)
    end
end

--[[
    ReSpin过场
]]
function CodeGameScreenAtlantisMachine:showReSpinStart(func)

    self:clearCurMusicBg()

    --过场动画
    self:changeSceneAni("start",function(  )
        local waitNode1 = cc.Node:create()
        self:addChild(waitNode1)

        self.m_bottomUI:updateWinCount("")
        
        --等待0.5s自动开始respin
        performWithDelay(waitNode1,function ()
            waitNode1:removeFromParent(true)
            if func then
                func()
            end
        end,0.5)
    end)

    
    

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function (  )
        waitNode:removeFromParent(true)
        
        self.m_respin_bar:setShow(true)
        self.m_respin_bar:showAni()
        self.m_respin_bar:refreshUI(self.m_runSpinResultData,true)
        self.m_colloction_bar:setShow(false)
        --更换背景
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"base_free",false,function (  )
            self:statueAni(TYPE_RESPIN_IDLE)    
        end})
    end,1.2)
end

--respin 模式下更换背景音乐
function CodeGameScreenAtlantisMachine:changeReSpinBgMusic()
    if self.m_rsBgMusicName ~= nil then
        self:removeSoundHandler()
        self:setMaxMusicBGVolume( )
        self.m_currentMusicBgName = self.m_rsBgMusicName
        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_rsBgMusicName)
    end
end

--[[
    显示respin
]]
function CodeGameScreenAtlantisMachine:showRespinView(effectData)
    --可随机的普通信息
    local randomTypes = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
        self.SYMBOL_SCORE_10,
        self.SYMBOL_SCORE_11
    }

    --可随机的特殊信号
    local endTypes = {
        {type = self.SYMBOL_BONUS_LINK, runEndAnimaName = "", bRandom = true}
    }

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    function startAction(  )
        if effectData ~= nil then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        self:showLayerBlack(false)
        --开始触发respin
        self:triggerReSpinCallFun(endTypes, randomTypes)
    end

    startAction()
end

--[[
    respin开始滚动
]]
function CodeGameScreenAtlantisMachine:respinStartRun( )
    self.m_respin_bar:refreshTimes(self.m_runSpinResultData.p_reSpinCurCount - 1)
    --bonus数量
    local bonus_count = #self.m_runSpinResultData.p_storedIcons
    local jackpot_index = bonus_count - 11
    self.m_jackpot:changeCurLight(jackpot_index)

    self.m_gameEffects = {}
end

--[[
    respin滚动结束
]]
function CodeGameScreenAtlantisMachine:respinRunEnd()
    self.m_respin_bar:refreshUI(self.m_runSpinResultData,false)

    --bonus数量
    local bonus_count = #self.m_runSpinResultData.p_storedIcons
    local jackpot_index = bonus_count - 11
    self.m_jackpot:changeCurLight(jackpot_index)
end

--[[
    respin玩法结束
]]
function CodeGameScreenAtlantisMachine:showRespinOverView(effectData)
    self.m_effectNode:removeAllChildren(true)
    self:showLayerBlack(true)
    local addFsEffect = function(  )
        local fsEffect = GameEffectData.new()
        fsEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
        fsEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = fsEffect

        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:sortGameEffects()
        self:playGameEffect()
    end

    local bonus_count = #self.m_runSpinResultData.p_storedIcons
    local jackpotIndex = -1
    local winCoin = self.m_runSpinResultData.p_winAmount
    if winCoin and winCoin > 0 then
        jackpotIndex = 4 - (bonus_count - 12)
        if jackpotIndex > 4 or jackpotIndex < 0 then
            jackpotIndex = 4
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
        --清理背景音乐
        self:clearCurMusicBg()
        self.m_jackpot:prizeLight(jackpotIndex,function(  )
            --显示jackpotWin
            gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_jackpot_trigger.mp3")
            self:showJackpotWinView(jackpotIndex,winCoin,function(  )
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                addFsEffect()
            end)
        end)
        
    else
        addFsEffect()
    end
    
    --respin结束后进入freespin
    self:setCurrSpinMode(FREE_SPIN_MODE)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenAtlantisMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenAtlantisMachine:slotReelDown( )

    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_colloction_bar.m_isWaitting = false
    --预告中奖音效
    if self.m_noticeSoundId then
        gLobalSoundManager:stopAudio(self.m_noticeSoundId)
        self.m_noticeSoundId = nil
    end

    --隐藏预告光效
    if self.m_notice_effect:isVisible() then
        self:runCsbAction("idle")
        util_runAnimations({
            {
                type = "animation",
                node = self.m_notice_effect,   
                actionName = "over", 
                callBack = function (  )
                    self.m_notice_effect:setVisible(false)
                end,   --回调函数 可选参数
            }
        })
    end
    
    
    BaseNewReelMachine.slotReelDown(self)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenAtlantisMachine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end


function CodeGameScreenAtlantisMachine:showJackpotWinView(index,coins,func)
    -- index 1- 4 grand - mini
    self:clearCurMusicBg()
    local jackPotWinView = util_createView("CodeAtlantisSrc.AtlantisJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)

    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)

    --jackpotBar回复状态
    self.m_jackpot:idleAni()

    local curCallFunc = function(  )
        if func then
            func()
        end
    end
    jackPotWinView:initViewData(self,index,coins,curCallFunc)
end

--[[
    飞粒子动画
]]
function CodeGameScreenAtlantisMachine:runFlyLineAct(startNode,endNode,keyFunc,endFunc)

    -- 创建粒子
    local flyNode =  util_createAnimation("Socre_Atlantis_tuowei.csb")
    self.m_effectNode:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1 )

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    if endPos.y < startPos.y then   --向下飞
        startPos.y = startPos.y - 30
    end
    
    flyNode:setPosition(startPos)

    

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 525 )
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = flyNode,   --执行动画节点  必传参数
        actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        soundFile = self.m_isFsOver and "AtlantisSounds/sound_Atlantis_fly_over.mp3" or "AtlantisSounds/sound_Atlantis_fly.mp3",
        fps = 60,    --帧率  可选参数
        callBack = function(  ) --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end
            flyNode:stopAllActions()
            flyNode:removeFromParent()
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        if self.m_isFsOver then
            gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_fly_over_down.mp3")
        else
            gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_fly_down.mp3")
        end
        
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end,0.27)

    return flyNode

end

return CodeGameScreenAtlantisMachine






