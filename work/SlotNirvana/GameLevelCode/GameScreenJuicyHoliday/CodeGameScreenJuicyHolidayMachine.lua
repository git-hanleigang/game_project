---
-- island li
-- 2019年1月26日
-- CodeGameScreenJuicyHolidayMachine.lua
-- 
-- 玩法：
--
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "JuicyHolidayPublicConfig"
local BaseReelMachine = require "Levels.BaseReel.BaseReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local CodeGameScreenJuicyHolidayMachine = class("CodeGameScreenJuicyHolidayMachine", BaseReelMachine)

CodeGameScreenJuicyHolidayMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
-- CodeGameScreenJuicyHolidayMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE


-- 自定义动画的标识
CodeGameScreenJuicyHolidayMachine.COLORFUL_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --多福多彩
CodeGameScreenJuicyHolidayMachine.SHOW_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --显示wild
CodeGameScreenJuicyHolidayMachine.COLLECT_SCATTER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --收集scatter
CodeGameScreenJuicyHolidayMachine.CELEBRATE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 --庆祝动效(倍数达到25倍)
CodeGameScreenJuicyHolidayMachine.SHOW_WILD_TIP_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 --乘倍条提示动效
CodeGameScreenJuicyHolidayMachine.LINE_MULTI_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6 --连线乘倍动效

local NODE_ZORDER   =   {
    FreeSpinBar     =       5,
    Panel_1         =       10,
    CishuBar        =       15,
    Node_qipan      =       20,
    jackpot         =       25,
}

local MULTI_CONFIG = {1,2,3,5,10,25}

-- 构造函数
function CodeGameScreenJuicyHolidayMachine:ctor()
    CodeGameScreenJuicyHolidayMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeJuicyHolidaySrc.JuicyHolidaySymbolExpect", {
        machine = self,
        symbolList = {
            {
                symbolTypeList = {TAG_SYMBOL_TYPE.SYMBOL_SCATTER}, --可触发的信号值
                triggerCount = 3    --触发所需数量
            }
        }
    }) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("JuicyHolidayLongRunControl",{
        machine = self,
        symbolList = {
            {
                symbolTypeList = {TAG_SYMBOL_TYPE.SYMBOL_SCATTER}, --可触发的信号值
                triggerCount = 3    --触发所需数量
            }
        }
    }) 

    self.m_collectScatters = {}
    self.m_wildSymbol = nil
    self.m_bigWinSoundIndex = 1

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    self.m_isCollect = false
    self.m_colorfulWin = 0
    --init
    self:initGame()
end

--绘制多个裁切区域
function CodeGameScreenJuicyHolidayMachine:drawReelArea()
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
            machine = self      --必传参数
        })
        self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        self.m_baseReelNodes[iCol] = clipNode
        clipNode:setPosition(cc.p(posX,posY))
    end
end

function CodeGameScreenJuicyHolidayMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenJuicyHolidayMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "JuicyHoliday"  
end

function CodeGameScreenJuicyHolidayMachine:getReelNode()
    return "CodeJuicyHolidaySrc.JuicyHolidayReelNode"
end


function CodeGameScreenJuicyHolidayMachine:initUI()
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)
    --重置节点层级
    for nodeName,zOrder in pairs(NODE_ZORDER) do
        local node = self:findChild(nodeName)
        if not tolua.isnull(node) then
            node:setLocalZOrder(zOrder)
        end
    end

    local AllwinBar = self:findChild("AllwinBar")
    AllwinBar:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - 100)
    AllwinBar:setTag(10)

    local Node_kuang = self:findChild("Node_kuang")
    Node_kuang:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - 150)
    Node_kuang:setTag(11)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    ---初始化次数Bar
    self.m_leftTimeBar = util_createView("CodeJuicyHolidaySrc.JuicyHolidayLeftTimesBar",{machine = self})
    self:findChild("CishuBar"):addChild(self.m_leftTimeBar)
    -- self.m_leftTimeBar:setVisible(false)

    --初始化倍数Bar
    self.m_multiBar = util_createView("CodeJuicyHolidaySrc.JuicyHolidayMultiBar",{machine = self})
    self:findChild("AllwinBar"):addChild(self.m_multiBar)
    -- self.m_multiBar:setVisible(false)

    --收集条
    self.m_collectBar = util_createView("CodeJuicyHolidaySrc.JuicyHolidayCollectBar",{machine = self})
    self:findChild("shouji"):addChild(self.m_collectBar)
    -- self.m_collectBar:setVisible(false)

    --多福多彩
    self.m_colorfulGameView = util_createView("CodeJuicyHolidaySrc.JuicyHolidayColorfulGame",{machine = self})
    self:findChild("root"):addChild(self.m_colorfulGameView)
    self.m_colorfulGameView:setVisible(false) 

    self:initJackPotBarView() 
   
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenJuicyHolidayMachine:initSpineUI()
    
end


function CodeGameScreenJuicyHolidayMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_JuicyHoliday_enter_level)
    end)
end

function CodeGameScreenJuicyHolidayMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isEnter = true
    self:checkUpateDefaultBet()
    self:updateCurWildData()
    CodeGameScreenJuicyHolidayMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    

    self:initCollectBar()

    --刷新剩余次数和倍数
    self:updateLeftTimes(self.m_leftTime,true)
    self:updateCurMulti()

    self:findChild("free"):setVisible(false)
    self:changeBg("base")

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeSpinUI()
    end
    self.m_isEnter = false
end

--[[
    刷新收集条
]]
function CodeGameScreenJuicyHolidayMachine:initCollectBar()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local curLevel = 1
    if selfData and selfData.collect_status then
        curLevel = selfData.collect_status
    end

    if selfData and selfData.process then
        curLevel = 1
    end


    self.m_collectBar:initLevel(curLevel)
end

--[[
    刷新当前玩法数据
]]
function CodeGameScreenJuicyHolidayMachine:updateCurWildData()
    local totalBet = self:getTotalBet()
    --剩余次数
    self.m_leftTime = 0
    --当前倍数
    self.m_curMulti = 1
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self.m_wild_config[tostring( toLongNumber(totalBet) )] then
            local data = self.m_wild_config[tostring(toLongNumber(totalBet))]
            self.m_curMulti = data[1]
            self.m_leftTime = data[2]
            if self.m_leftTime == 0 then
                self.m_curMulti = 1
            end
        end
    else
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.free_multi then
            self.m_curMulti = selfData.free_multi
        end
    end
    
end

--[[
    获取平均bet
]]
function CodeGameScreenJuicyHolidayMachine:getTotalBet()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.avgBet then
        return fsExtraData.avgBet
    end
    return globalData.slotRunData:getCurTotalBet()
end

function CodeGameScreenJuicyHolidayMachine:addObservers()
    CodeGameScreenJuicyHolidayMachine.super.addObservers(self)
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

        local soundName = PublicConfig.SoundConfig["sound_JuicyHoliday_winline_base_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_JuicyHoliday_winline_free_"..soundIndex]
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateCurWildData()
            self:updateCurMulti()
            self:updateLeftTimes(self.m_leftTime,true)
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenJuicyHolidayMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_scheduleNode:stopAllActions()
    CodeGameScreenJuicyHolidayMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenJuicyHolidayMachine:MachineRule_GetSelfCCBName(symbolType)
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenJuicyHolidayMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenJuicyHolidayMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenJuicyHolidayMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 

end

function CodeGameScreenJuicyHolidayMachine:initGameStatusData(gameData)
    CodeGameScreenJuicyHolidayMachine.super.initGameStatusData(self, gameData)

    self.m_wild_config = gameData.gameConfig.extra.wild_config
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenJuicyHolidayMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenJuicyHolidayMachine:resetReelDataAfterReel()
    CodeGameScreenJuicyHolidayMachine.super.resetReelDataAfterReel(self)
    self.m_scheduleNode:stopAllActions()
    self.m_collectScatters = {}
    self.m_lineSlotNodes = {}
    self.m_wildSymbol = nil
    self.m_colorfulWin = 0
    self.m_bClickQuickStop = false
    self.m_isCollect = false
    self.m_networkBack = false
    
    --刷新剩余次数和倍数
    self:updateLeftTimes(self.m_leftTime - 1,false)
    self:updateCurMulti()
end

function CodeGameScreenJuicyHolidayMachine:beginReel()
    CodeGameScreenJuicyHolidayMachine.super.beginReel(self)
    
end

--
--单列滚动停止回调
--
function CodeGameScreenJuicyHolidayMachine:slotOneReelDown(reelCol)    
    CodeGameScreenJuicyHolidayMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol,self.m_spcial_symbol_list)
end

--[[
    滚轮停止
]]
function CodeGameScreenJuicyHolidayMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenJuicyHolidayMachine.super.slotReelDown(self)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenJuicyHolidayMachine:addSelfEffect()

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then

        --收集scatter
        if #self.m_collectScatters > 0 then
            self.m_isCollect = true
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COLLECT_SCATTER_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_SCATTER_EFFECT -- 动画类型
        end
    end
    
    --拉伸wild
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.if_wild or selfData.if_free_wild then
        self.m_showWild = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.SHOW_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SHOW_WILD_EFFECT -- 动画类型
    end

    --多福多彩
    if selfData and selfData.process then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLORFUL_GAME_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLORFUL_GAME_EFFECT -- 动画类型

        self:removeSoundHandler()
    end

    local winLines = self.m_runSpinResultData.p_winLines

    --连线乘倍动效
    if self.m_curMulti >= 2 and #winLines > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME - 3
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.LINE_MULTI_EFFECT -- 动画类型
    end
    --庆祝动画
    if self.m_curMulti >= 10 and #winLines > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME - 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CELEBRATE_EFFECT -- 动画类型
    end

    --有wild图标参与连线
    if not tolua.isnull(self.m_wildSymbol) and self:checkWildIsInLine() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME - 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SHOW_WILD_TIP_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenJuicyHolidayMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLORFUL_GAME_EFFECT then
        self:showColorfulGame(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_SCATTER_EFFECT then
        self:collectScatterAni(function() --收集scatter
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.SHOW_WILD_EFFECT then --拉伸wild
        local delayTime = 0
        local selfData = self.m_runSpinResultData.p_selfMakeData
        --快停且未触发多福多彩
        if self.m_bClickQuickStop and (not selfData or not selfData.process) and not self.m_isCollect then
            delayTime = 22 / 30
        end
        self:delayCallBack(delayTime,function()
            self:showAllWildAni(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.CELEBRATE_EFFECT then --庆祝动效
        self:runCelebrateAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.SHOW_WILD_TIP_EFFECT then --wild倍数提示
        self:showWildTipAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.LINE_MULTI_EFFECT then --连线乘倍动效
        self:showLineMultiAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    return true
end

--[[
    连线乘倍动效
]]
function CodeGameScreenJuicyHolidayMachine:showLineMultiAni(func)
    local csbAni = util_createAnimation("JuicyHoliday_chengbei.csb")
    local rootNode = self:findChild("root")
    rootNode:addChild(csbAni)
    for index = 1,#MULTI_CONFIG do
        local multi = MULTI_CONFIG[index]
        csbAni:findChild("Node_"..multi):setVisible(multi == self.m_curMulti)
    end

    for index = 1,3 do
        local particle = csbAni:findChild("Particle_"..self.m_curMulti.."_"..index)
        if not tolua.isnull(particle) then
            particle:setVisible(false)
        end
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_show_multi_tip"])
    csbAni:runCsbAction("actionframe",false,function()
        self:delayCallBack(1,function()
            if not tolua.isnull(csbAni) then
                csbAni:removeFromParent()
            end
        end)
    end)

    self:delayCallBack(35 / 60,function()
        if not tolua.isnull(csbAni) then
            for index = 1,3 do
                local particle = csbAni:findChild("Particle_"..self.m_curMulti.."_"..index)
                if not tolua.isnull(particle) then
                    particle:setVisible(true)
                    particle:resetSystem()
                end
            end
        end
    end)

    
    self:delayCallBack(50 / 60,function()
        if type(func) == "function" then
            func()
        end
    end)
    
end

--[[
    wild倍数提示
]]
function CodeGameScreenJuicyHolidayMachine:showWildTipAni(func)
    self.m_multiBar:showMultiTipAni()
    if type(func) == "function" then
        func()
    end
end

--[[
    庆祝动效
]]
function CodeGameScreenJuicyHolidayMachine:runCelebrateAni(func)
    local rootNode = self:findChild("root")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_show_side_fruit"])
    local spine = util_spineCreate("JuicyHoliday_qingzhu",true,true)
    rootNode:addChild(spine)

    util_spinePlayAndRemove(spine,"actionframe",function()
        
    end)

    if type(func) == "function" then
        func()
    end
end

--[[
    拉伸wild
]]
function CodeGameScreenJuicyHolidayMachine:showAllWildAni(func)
    
    local isShowAll = true

    local isUp = false
    local reels = self.m_runSpinResultData.p_reels
    for iRow = self.m_iReelRowNum,1,-1 do
        if reels[iRow][3] ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            isShowAll = false
            break
        elseif iRow == self.m_iReelRowNum then
            isUp = true
        end
    end

    local endFunc = function()
        if tolua.isnull(self.m_wildSymbol) then
            return
        end
        -- --移除第三列滚动点上的小块
        local reelNode = self.m_baseReelNodes[3]
        if not tolua.isnull(reelNode) then
            local rollNodes = reelNode.m_rollNodes
            local iRow = 1
            self.m_scheduleNode:stopAllActions()
            util_schedule(self.m_scheduleNode,function()
                if iRow > #rollNodes then
                    self.m_scheduleNode:stopAllActions()
                    return
                end
                if iRow <= self.m_iReelRowNum then
                    --如果不是全显示需要拉伸,则需移除原滚动点上的小块
                    if not self.m_wildSymbol.m_isShowAll then
                        reelNode:removeSymbolByRowIndex(iRow)
                    end
                else
                    --如果是向下拉伸,上面的滚动点需重新补块
                    if not self.m_wildSymbol.isUp then
                        reelNode:reloadRollNode(rollNodes[iRow],iRow)
                    end
                end
                iRow  = iRow + 1
            end,1 / 60)
        end
        --将wild小块从长条裁切层移到clipParent上
        self:changeSymbolToClipParent(self.m_wildSymbol)
        if self.m_wildSymbol.m_longClipNode then
            self.m_wildSymbol.m_longClipNode:removeFromParent()
            self.m_wildSymbol.m_longClipNode = nil
        end
        if self.m_wildSymbol.m_longInfo then
            self.m_wildSymbol.m_longInfo.curCount = 5
        end
        
        --乘倍动效
        self.m_wildSymbol:runAnim("actionframe_xb",false,function()
            self.m_wildSymbol:runAnim("idleframe2",true)

            local winlines = self.m_runSpinResultData.p_winLines
            if #winlines == 0 and self.m_showWild then
                self.m_showWild = false
                self:hideBlackLayer()
            end

            if type(func) == "function" then
                func()
            end
        end)
        
        self:delayCallBack(20 / 30,function()
            self.m_multiBar:updateMultiShowWithAni(self.m_curMulti)
        end)

        self:delayCallBack(35 / 30,function()
            self.m_leftTimeBar:updateTimes(0)
            self.m_leftTimeBar:resetTimesAni(0,function()
                

                
            end)
        end)
        
    end
    if not tolua.isnull(self.m_wildSymbol) then
        self.m_wildSymbol.m_isUp = isUp
        self.m_wildSymbol.m_isShowAll = isShowAll
    end

    --提层的小块放回去
    for index = 1,#self.m_collectScatters do
        local symbolNode = self.m_collectScatters[index]
        if not tolua.isnull(symbolNode) then
            self:putSymbolBackToPreParent(symbolNode)
        end
    end

    self:showBlackLayer()

    if not isShowAll and not tolua.isnull(self.m_wildSymbol) then 
        --变更wild信号行索引
        self.m_wildSymbol.p_rowIndex = 1

        local aniName = "actionframe_down"
        if isUp then
            aniName = "actionframe_up"
        end

        self.m_wildSymbol:runAnim(aniName,false,function()
            if not tolua.isnull(self.m_wildSymbol) then

                --计算拉伸的最终位置
                local posIndex = self:getPosReelIdx(self.m_wildSymbol.p_rowIndex, self.m_wildSymbol.p_cloumnIndex)
                local pos = util_getOneGameReelsTarSpPos(self, posIndex)
                local worldPos = self.m_clipParent:convertToWorldSpace(pos)
                local nodePos = self.m_wildSymbol:getParent():convertToNodeSpace(worldPos)

                local actionList = {
                    cc.EaseIn:create(cc.MoveTo:create(0.3,nodePos),1),
                    -- cc.DelayTime:create(0.5),
                    -- cc.MoveTo:create(0.3,nodePos),
                    cc.CallFunc:create(function()
                        endFunc()
                    end)
                }

                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_wild_pull"])
                self.m_wildSymbol:runAction(cc.Sequence:create(actionList))
            end
        end)
    else
        
        endFunc()
    end

    
end

--[[
    检测是否触发free
]]
function CodeGameScreenJuicyHolidayMachine:checkTriggerFree()
    local features = self.m_runSpinResultData.p_features or {}
    if features then
        for index = 1, #features do 
            local featureId = features[index]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then
                return true
            end
        end
    end

    return false
end

--[[
    收集scatter动效
]]
function CodeGameScreenJuicyHolidayMachine:collectScatterAni(func)
    local isTriggerFs = self:checkTriggerFree()
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local level = 1
    if selfData and selfData.collect_status then
        level = selfData.collect_status
    end

    local isTriggerBonus = false
    if selfData and selfData.process then
        isTriggerBonus = true
    end

    if #self.m_collectScatters > 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_collect_scatter"])
    end

   
    for index = 1,#self.m_collectScatters do
        local symbolNode = self.m_collectScatters[index]
        if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            symbolNode:runMixAni("actionframe_sj",false,function()
                if not tolua.isnull(symbolNode) then
                    symbolNode:runAnim("idleframe2",true)
                end
            end)

            local delayTime = 0
            for iCount = 1,5 do
                self:delayCallBack(delayTime,function()
                    self:flyFruitToCollectBar(symbolNode,self.m_collectBar)
                end)
                delayTime  = delayTime + 2 / 60
            end
            
        end
    end

    local winLines = self.m_runSpinResultData.p_winLines
    local isMultiLines = false

    --连线乘倍动效
    if self.m_curMulti >= 2 and #winLines > 0 then
        isMultiLines = true
    end

    local isShowWild = false
    if selfData and selfData.if_wild or selfData.if_free_wild then
        isShowWild = true
    end

    if #self.m_collectScatters > 0 then
        self:delayCallBack(30 / 60,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_collect_scatter_feed_back"])
            self.m_collectBar:feedBackAni(level,isTriggerBonus,function()
                if isTriggerFs or isTriggerBonus or isShowWild or isMultiLines then
                    if type(func) == "function" then
                        func()
                    end
                end
            end)
        end)
    end


    if not isTriggerFs and not isTriggerBonus and not isShowWild and not isMultiLines then
        if type(func) == "function" then
            func()
        end
    end

    

end

--[[
    飞水果
]]
function CodeGameScreenJuicyHolidayMachine:flyFruitToCollectBar(startNode,endNode)
    local parent = self.m_clipParent
    local startPos = util_convertToNodeSpace(startNode,parent)
    local endPos = util_convertToNodeSpace(endNode,parent)
    endPos.y  = endPos.y + 360
    local endPos1 = cc.p((startPos.x + endPos.x) / 2,endPos.y + 180)

    local flyNode = util_createAnimation("JuicyHoliday_shouji_shuiguo.csb")
    parent:addChild(flyNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - 50)
    flyNode:setPosition(startPos)

    local randIndex = math.random(1,4)
    for index = 1,4 do
        local sprite = flyNode:findChild("sp_"..index)
        if not tolua.isnull(sprite) then
            sprite:setVisible(index == randIndex)
        end
    end
    
    local actList = {}
    actList[#actList + 1] = cc.EaseOut:create(cc.MoveTo:create(20/60, endPos1),1)
    actList[#actList + 1] = cc.CallFunc:create(function()
        if not tolua.isnull(flyNode) then
            -- flyNode:setLocalZOrder(15)
            local newParent = self:findChild("Node_base")
            local pos = util_convertToNodeSpace(flyNode,newParent)
            util_changeNodeParent(newParent,flyNode,8)
            flyNode:setPosition(pos)
        end
    end)
    actList[#actList + 1] = cc.EaseIn:create(cc.MoveTo:create(10/60, endPos),1)
    actList[#actList + 1] = cc.CallFunc:create(function()
        if not tolua.isnull(flyNode) then
            flyNode:removeFromParent()
        end
    end)

    flyNode:runCsbAction("actionframe")
    flyNode:runAction(cc.Sequence:create(actList))
end

--[[
    刷新当前次数
]]
function CodeGameScreenJuicyHolidayMachine:updateLeftTimes(times,isInit,func)
    if type(func) == "function" then
        func()
    end

    self.m_leftTimeBar:updateTimes(times,isInit)
    
end

--[[
    刷新当前倍数
]]
function CodeGameScreenJuicyHolidayMachine:updateCurMulti(func)
    if type(func) == "function" then
        func()
    end
    self.m_multiBar:updateMultiShow(self.m_curMulti)
end



function CodeGameScreenJuicyHolidayMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenJuicyHolidayMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenJuicyHolidayMachine:playScatterTipMusicEffect()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_scatter_trigger"])
end

-- 不用系统音效
function CodeGameScreenJuicyHolidayMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenJuicyHolidayMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenJuicyHolidayMachine:checkRemoveBigMegaEffect()
    CodeGameScreenJuicyHolidayMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenJuicyHolidayMachine:getShowLineWaitTime()
    local time = CodeGameScreenJuicyHolidayMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenJuicyHolidayMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeJuicyHolidaySrc.JuicyHolidayFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("FreeSpinBar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenJuicyHolidayMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenJuicyHolidayMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

--[[
    显示free相关UI
]]
function CodeGameScreenJuicyHolidayMachine:showFreeSpinUI()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.free_multi then
        self.m_curMulti = selfData.free_multi
    else
        self.m_curMulti = 1
    end
    self:updateCurMulti()
    self.m_leftTimeBar:setVisible(false)
    self.m_collectBar:setVisible(false)
    self:findChild("base"):setVisible(false)
    self:findChild("free"):setVisible(true)
    self:showFreeSpinBar()
    self:changeBg("free")
end

--[[
    隐藏free相关UI
]]
function CodeGameScreenJuicyHolidayMachine:hideFreeSpinUI()
    self.m_leftTimeBar:setVisible(true)
    self.m_collectBar:setVisible(true)
    self:updateCurWildData()
    self:updateCurMulti()
    self:updateLeftTimes(self.m_leftTime,true)
    self:initCollectBar()
    self:findChild("base"):setVisible(true)
    self:findChild("free"):setVisible(false)
    self:changeBg("base")
    
    self:hideFreeSpinBar()

    self:clearWinLineEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.last_base_reel then
        local triggerReels = selfData.last_base_reel
        for iCol,reelNode in ipairs(self.m_baseReelNodes) do
            local lastList = {}
            for iRow = 1,#triggerReels do
                table.insert(lastList,1,triggerReels[iRow][iCol])
            end
            reelNode:setSymbolList(lastList)
            reelNode:initSymbolNode(true)
        end
    end
    

end

function CodeGameScreenJuicyHolidayMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("JuicyHolidaySounds/music_JuicyHoliday_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:setCurrSpinMode(FREE_SPIN_MODE)
                self:resetMusicBg()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_change_scene_to_free"])
                self:changeSceneToFree(function()
                    self:showFreeSpinUI()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end,function()
                    
                end)      
            end)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenJuicyHolidayMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local autoType = nil
    if isAuto then
        autoType = BaseDialog.AUTO_TYPE_NOMAL
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_show_free_start"])
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, autoType)

    local spine = util_spineCreate("JuicyHoliday_tb_4",true,true)
    view:findChild("Node_tb_4"):addChild(spine)
    util_spinePlay(spine,"start")
    util_spineEndCallFunc(spine,"start",function()
        util_spinePlay(spine,"idle",true)
    end)

    local bgLight = util_createAnimation("JuicyHoliday_tb_guang.csb")
    view:findChild("Node_guang"):addChild(bgLight)
    bgLight:runCsbAction("idleframe",true)

    local btnLight = util_spineCreate("JuicyHoliday_anniu_sg",true,true)
    view:findChild("Node_anniu_sg"):addChild(btnLight)
    util_spinePlay(btnLight,"idle",true)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JuicyHoliday_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_hide_free_start"])
        if not tolua.isnull(spine) then
            util_spinePlay(spine,"over")
        end
    end)

    view:findChild("root"):setScale(self.m_machineRootScale)


    util_setCascadeOpacityEnabledRescursion(view,true)

    return view

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

--[[
    过场动画 free
]]
function CodeGameScreenJuicyHolidayMachine:changeSceneToFree(keyFunc,endFunc)
    local spine = util_spineCreate("JuicyHoliday_guochang",true,true)
    self:findChild("root"):addChild(spine)
    spine:setScale(self.m_bgScale)
    self:delayCallBack(99 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)

    util_spinePlayAndRemove(spine,"actionframe_guochang",function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--[[
    过场动画 free到base
]]
function CodeGameScreenJuicyHolidayMachine:changeSceneToBaseFromFree(keyFunc,endFunc)
    local spine = util_spineCreate("JuicyHoliday_shouji",true,true)
    self:findChild("root"):addChild(spine)
    spine:setScale(self.m_bgScale)
    self:delayCallBack(24 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
    util_spinePlayAndRemove(spine,"actionframe_guochang",function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

function CodeGameScreenJuicyHolidayMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("JuicyHolidaySounds/music_JuicyHoliday_over_fs.mp3")
    local view = self:showFreeSpinOver(
        globalData.slotRunData.lastWinCoin, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_change_scene_to_base_from_free"])
            self:changeSceneToBaseFromFree(function()
                self:setCurrSpinMode(NORMAL_SPIN_MODE)
                self:hideFreeSpinUI()
            end,function()
                self:triggerFreeSpinOverCallFun()
            end)
            
        end
    )
    
end

function CodeGameScreenJuicyHolidayMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if globalData.slotRunData.lastWinCoin > 0 then
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_show_free_over"])
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

        local spine = util_spineCreate("JuicyHoliday_tb_3",true,true)
        view:findChild("Node_tb_3"):addChild(spine)
        util_spinePlay(spine,"start")
        util_spineEndCallFunc(spine,"start",function()
            util_spinePlay(spine,"idle",true)
        end)


        local btnLight = util_spineCreate("JuicyHoliday_anniu_sg",true,true)
        view:findChild("Node_anniu_sg"):addChild(btnLight)
        util_spinePlay(btnLight,"idle",true)

        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JuicyHoliday_btn_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_hide_free_over"])
            if not tolua.isnull(spine) then
                util_spinePlay(spine,"over")
            end
        end)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},623)   
        util_setCascadeOpacityEnabledRescursion(view,true) 
        view:findChild("root"):setScale(self.m_machineRootScale)
        return view
    else
        local view = self:showDialog("FreeSpinOver1", ownerlist, func)

        local spine = util_spineCreate("JuicyHoliday_tb_1",true,true)
        view:findChild("Node_tb_1"):addChild(spine)
        util_spinePlay(spine,"start")
        util_spineEndCallFunc(spine,"start",function()
            util_spinePlay(spine,"idle",true)
        end)

        local btnLight = util_spineCreate("JuicyHoliday_anniu_sg",true,true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_show_free_over"])
        view:findChild("Node_anniu_sg"):addChild(btnLight)
        util_spinePlay(btnLight,"idle",true)

        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JuicyHoliday_btn_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_hide_free_over"])
            if not tolua.isnull(spine) then
                util_spinePlay(spine,"over")
            end
        end)

        util_setCascadeOpacityEnabledRescursion(view,true)
        view:findChild("root"):setScale(self.m_machineRootScale)
        return view
    end
    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenJuicyHolidayMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            scatterLineValue:clean()
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    

    self:delayCallBack(0.5,function()
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            -- 停掉背景音乐
            self:clearCurMusicBg()
            -- freeMore时不播放
            self:levelDeviceVibrate(6, "free")
        end

        self:runScatterTriggerAni(function()
            self:showFreeSpinView(effectData)
        end)
    end)
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

--[[
    scatter触发动画
]]
function CodeGameScreenJuicyHolidayMachine:runScatterTriggerAni(func)
    self:playScatterTipMusicEffect()
    local waitTime = 0
    for index = 1,self.m_iReelRowNum * self.m_iReelColumnNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local parent = symbolNode:getParent()
            if parent ~= self.m_clipParent then
                self:changeSymbolToClipParent(symbolNode)
            end
            symbolNode:runAnim("actionframe")
            local duration = symbolNode:getAniamDurationByName("actionframe")
            waitTime = util_max(waitTime,duration)
        end
    end

    self:delayCallBack(waitTime,func)
end

function CodeGameScreenJuicyHolidayMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeJuicyHolidaySrc.JuicyHolidayJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenJuicyHolidayMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeJuicyHolidaySrc.JuicyHolidayJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
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

function CodeGameScreenJuicyHolidayMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)
    return false    
end

function CodeGameScreenJuicyHolidayMachine:setReelRunInfo()
    local totalBet = self:getTotalBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.wild_config then
        if selfData.wild_config[tostring(toLongNumber(totalBet))] then
            self.m_wild_config[tostring(toLongNumber(totalBet))] = selfData.wild_config[tostring(toLongNumber(totalBet))]
        end
    end

    self.m_networkBack = true

    self:updateCurWildData()

    self.m_longRunControl:checkTriggerLongRun() -- 设置快滚状态
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenJuicyHolidayMachine:MachineRule_ResetReelRunData()
    CodeGameScreenJuicyHolidayMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenJuicyHolidayMachine:isPlayExpect(reelCol)
    if reelCol <= self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() then
            return true
        end
    end
    return false    
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenJuicyHolidayMachine:showFeatureGameTip(_func)
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
function CodeGameScreenJuicyHolidayMachine:playFeatureNoticeAni(func)
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("Node_zong")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_notice_win"])
    self.b_gameTipFlag = true
    --创建对应格式的spine
    local spineAni = util_spineCreate("JuicyHoliday_yugao",true,true)
    parentNode:addChild(spineAni)
    util_spinePlayAndRemove(spineAni,"actionframe_yugao")
    
    aniTime = spineAni:getAnimationDurationTime("actionframe_yugao")

    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
        end
    end) 
end

--[[
        bonus玩法
    ]]
function CodeGameScreenJuicyHolidayMachine:showColorfulGame(func)
    self:clearCurMusicBg()

    if not self:checkHasBigWin() then
        self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin,GameEffect.EFFECT_BONUS)
    end

    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    local selfData = self.m_runSpinResultData.p_selfMakeData

    self.m_colorfulWin = winCoins
    
    local bonusData = {
        rewardList = selfData.process,    --奖励列表
        winJackpot = jackpotType        --获得的jackpot
    }

    --重置bonus界面
    self.m_colorfulGameView:resetView(bonusData,function()
        self:showJackpotView(winCoins,jackpotType,function()
            -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winCoins))

            if self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines == 0 then
                local params = {winCoins, true,true}
                params[self.m_stopUpdateCoinsSoundIndex] = true
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
            else
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winCoins))
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_change_scene_to_base_from_colorful"])
            self:changeSceneToBaseFromBonus(function()
                self:hideBonusUI()
            end,function()
                self:resetMusicBg()
                self:reelsDownDelaySetMusicBGVolume() 
                if type(func) == "function" then
                    func()
                end
            end)
            
        end)
        
    end)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_colorful_trigger"])
    self.m_collectBar:runTriggerAni(function()
        self:showBonusUI()
    end,function()
        self:resetMusicBg(false,"JuicyHolidaySounds/music_JuicyHoliday_colorfulGame.mp3")
    end)
    
end

--[[
    过场动画 多福多彩到base
]]
function CodeGameScreenJuicyHolidayMachine:changeSceneToBaseFromBonus(keyFunc,endFunc)
    -- JuicyHoliday_shouji
    local spine = util_spineCreate("JuicyHoliday_shouji",true,true)
    self:findChild("root"):addChild(spine)
    spine:setScale(self.m_bgScale)
    self:delayCallBack(24 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
    util_spinePlayAndRemove(spine,"actionframe_guochang",function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--[[
    显示bonus相关UI
]]
function CodeGameScreenJuicyHolidayMachine:showBonusUI()
    self.m_colorfulGameView:showView()
    self:findChild("Node_base"):setVisible(false)
    self:changeBg("bonus")
end

--[[
    隐藏bonus相关UI
]]
function CodeGameScreenJuicyHolidayMachine:hideBonusUI()
    self:updateCurMulti()
    self.m_colorfulGameView:hideView()
    self:findChild("Node_base"):setVisible(true)
    self:initCollectBar()
    self:changeBg("base")
end

--[[
        获取jackpot类型及赢得的金币数
    ]]
function CodeGameScreenJuicyHolidayMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        return string.lower(jackpotType),coins
    end
    return "",0    
end

--[[
    检测wild是否在连线内
]]
function CodeGameScreenJuicyHolidayMachine:checkWildIsInLine()
    local winLines = self.m_runSpinResultData.p_winLines

    for index = 1,#winLines do
        local lineData = winLines[index]
        local p_iconPos = lineData.p_iconPos
        for i,posIndex in ipairs(p_iconPos) do
            local posData = self:getRowAndColByPos(posIndex)
            local colIndex = posData.iY
            if colIndex == 3 then
                return true
            end
        end
    end
    return false
end

--[[
    检测播放落地动画
]]
function CodeGameScreenJuicyHolidayMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.m_collectScatters[#self.m_collectScatters + 1] = symbolNode
            end
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then

                self:pushToSpecialSymbolList(symbolNode)
                --提层
                if symbolCfg[1] then
                    
                    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        -- if self:checkWildIsInLine() then
                        --     --wild提层
                        --     self:changeToMaskLayerSlotNode(symbolNode)
                        -- end

                        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_wild_down"])
                        --wild提层
                        self:changeToMaskLayerSlotNode(symbolNode)
                        
                        self.m_wildSymbol = symbolNode
                    else
                        
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

--[[
    播放scatter落地音效
]]
function CodeGameScreenJuicyHolidayMachine:playScatterDownSound(colIndex)
    local scatterNum = #self.m_collectScatters
    if scatterNum == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_scatter_down_1"])
    elseif scatterNum == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_scatter_down_2"])
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_scatter_down_3"])
    end
end

function CodeGameScreenJuicyHolidayMachine:isPlayTipAnima(colIndex, rowIndex, node)
    if colIndex <= 2 then
        return true
    end
    local reels = self.m_runSpinResultData.p_reels
    local scatterNum = 0
    for iCol = 1,colIndex do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterNum  = scatterNum + 1
            end
        end
    end
    if colIndex == 3 and scatterNum >= 2 then
        return true
    elseif colIndex >= 4 and scatterNum >= 3 then
        return true
    end

    return false
end

function CodeGameScreenJuicyHolidayMachine:showLineFrame()
    if self.m_showWild then
        self.m_showWild = false
        self:hideBlackLayer()
    end
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
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

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框

        -- if #winLines > 1 then
        showLienFrameByIndex()
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
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

--新滚动使用
function CodeGameScreenJuicyHolidayMachine:updateReelGridNode(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end
    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        

        if self.m_isEnter then
            symbolNode:changeSkin("25")
            symbolNode:runAnim("idleframe2",true)
        else
            local multi = self.m_curMulti
            if not self.m_networkBack or not symbolNode.m_isLastSymbol then
                multi = self:getNextMulti()
            end
            symbolNode:changeSkin(tostring(multi))
        end
    end
end

--[[
    获取下一阶段乘倍
]]
function CodeGameScreenJuicyHolidayMachine:getNextMulti()
    if self.m_curMulti == 25 then
        return self.m_curMulti
    end
    for index = 1,#MULTI_CONFIG do
        if MULTI_CONFIG[index] == self.m_curMulti then
            return MULTI_CONFIG[index + 1]
        end
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenJuicyHolidayMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_big_win_light"])

    if math.random(1,100) <= 30 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_big_win_"..self.m_bigWinSoundIndex])
        self.m_bigWinSoundIndex  = self.m_bigWinSoundIndex + 1
        if self.m_bigWinSoundIndex > 2 then
            self.m_bigWinSoundIndex = 1
        end
    end

    local spine = util_spineCreate("JuicyHoliday_bigwin",true,true)
    rootNode:addChild(spine)
    spine:setPosition(pos)
    util_spinePlay(spine,"actionframe_bigwin")

    local aniTime = spine:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(self:findChild('Node_qipan'),5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if not tolua.isnull(spine) then
            spine:removeFromParent()
        end
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenJuicyHolidayMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop,true,self.m_colorfulWin})
end

---
--设置bonus scatter 层级
function CodeGameScreenJuicyHolidayMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
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
    修改背景
]]
function CodeGameScreenJuicyHolidayMachine:changeBg(gameType)
    self.m_gameBg:findChild("base"):setVisible(gameType == "base")
    self.m_gameBg:findChild("pick"):setVisible(gameType == "bonus")
    self.m_gameBg:findChild("fg"):setVisible(gameType == "free")

    self:findChild("fg_bj_guang"):setVisible(gameType == "free")
end

function CodeGameScreenJuicyHolidayMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

    local winSize = display.size
    local mainScale = 1
    self.m_bgScale = 1

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
    if ratio < 920 / 768 then  --920以下
        mainScale = 0.59
        mainPosY  = mainPosY + 30
        self:findChild("bg"):setScale(1.2)

    elseif ratio >=  920 / 768 and ratio < 1152 / 768 then --920
        mainScale = 0.6
        mainPosY  = mainPosY + 40
        self:findChild("bg"):setScale(1.2)
        self.m_bgScale = 1.2

    elseif ratio >= 1152 / 768 and ratio < 1228 / 768 then --1152
        mainScale = 0.81
        mainPosY  = mainPosY + 28
    elseif ratio >= 1228 / 768 and ratio < 1368 / 768 then --1228
        mainScale = 0.86
        mainPosY  = mainPosY + 20
    else --1370以上
        mainScale = 1
        mainPosY  = mainPosY + 10
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end


return CodeGameScreenJuicyHolidayMachine






