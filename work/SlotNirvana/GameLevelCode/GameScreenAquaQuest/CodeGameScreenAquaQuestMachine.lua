---
-- island li
-- 2019年1月26日
-- CodeGameScreenAquaQuestMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "AquaQuestPublicConfig"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local CodeGameScreenAquaQuestMachine = class("CodeGameScreenAquaQuestMachine", BaseReelMachine)

CodeGameScreenAquaQuestMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenAquaQuestMachine.SYMBOL_FIX_SYMBOL_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenAquaQuestMachine.SYMBOL_FIX_SYMBOL_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenAquaQuestMachine.SYMBOL_FIX_SYMBOL_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenAquaQuestMachine.SYMBOL_FIX_SYMBOL_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7

CodeGameScreenAquaQuestMachine.m_chipList = nil
CodeGameScreenAquaQuestMachine.m_playAnimIndex = 0
CodeGameScreenAquaQuestMachine.m_lightScore = 0 

-- CodeGameScreenAquaQuestMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE


-- 自定义动画的标识
-- CodeGameScreenAquaQuestMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 



-- 构造函数
function CodeGameScreenAquaQuestMachine:ctor()
    CodeGameScreenAquaQuestMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeAquaQuestSrc.AquaQuestSymbolExpect", {
        machine = self,
        symbolList = {
            {
                symbolTypeList = {TAG_SYMBOL_TYPE.SYMBOL_SCATTER}, --可触发的信号值
                triggerCount = 3,    --触发所需数量
                expectAni = "idleframe2",     --期待时间线 根据动效时间线调整
                idleAni = "idleframe1"      --根据动效时间线调整
            }
        }
    })

    -- 引入控制插件
    self.m_longRunControl = util_createView("AquaQuestLongRunControl",{
        machine = self,
        symbolList = {
            {
                symbolTypeList = {TAG_SYMBOL_TYPE.SYMBOL_SCATTER}, --可触发的信号值
                triggerCount = 3    --触发所需数量
            }
        }
    }) 

    self.m_scatter_ary = {}

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0 

    self.m_isAddBigWinLightEffect = true


    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenAquaQuestMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAquaQuestMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "AquaQuest"  
end

---
-- 获取最高的那一列
--
function CodeGameScreenAquaQuestMachine:updateReelInfoWithMaxColumn()
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

        self:findChild("root"):addChild(self.m_touchSpinLayer)
        self.m_touchSpinLayer:setPosition(util_convertToNodeSpace(self.m_csbOwner["sp_reel_0"],self:findChild("root")))
        self.m_touchSpinLayer:setName("touchSpin")

        self.m_clipReelSize = cc.size(slotW, slotH)
        --创建压黑层
        self:createBlackLayer(cc.size(slotW, slotH)) 

        -- 测试数据，看点击区域范围
        -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 0, 0))
        -- self.m_touchSpinLayer:setBackGroundColorOpacity(0)
        -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)

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

--[[
    变更点击层大小
]]
function CodeGameScreenAquaQuestMachine:changeTouchLayerSize(startReelNode,reelNum,colNum)
    local pos = util_convertToNodeSpace(startReelNode,self:findChild("root"))
    self.m_touchSpinLayer:setPosition(pos)

    if reelNum == 1 then
        if colNum == 7 then
            local size = cc.size(self.m_clipReelSize.width * 1.3, self.m_clipReelSize.height)
            self.m_touchSpinLayer:setContentSize(size)
        end
    else
        local width = self.m_clipReelSize.width * 1.3
        local height = self.m_clipReelSize.height * 0.5
        if colNum == 5 then
            height = self.m_clipReelSize.height * 0.7
        end
        local size = cc.size(width, height)
        self.m_touchSpinLayer:setContentSize(size)
    end
end

--[[
    重置点击层大小
]]
function CodeGameScreenAquaQuestMachine:resetTouchLayerSize()
    self.m_touchSpinLayer:setContentSize(self.m_clipReelSize)
    self.m_touchSpinLayer:setPosition(util_convertToNodeSpace(self.m_csbOwner["sp_reel_0"],self:findChild("root")))
end

--[[
    创建压黑层
]]
function CodeGameScreenAquaQuestMachine:createBlackLayer(size)
    --压黑层
    self.m_blackLayer = util_createAnimation("AquaQuest_reel_dark.csb")
    self.m_clipParent:addChild(self.m_blackLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20)
    self.m_blackLayer:setVisible(false)
end

--[[
    显示压黑层
]]
function CodeGameScreenAquaQuestMachine:showBlackLayer()
    self.m_blackLayer:setVisible(true)
    self.m_blackLayer:runCsbAction("start")
end

--[[
    隐藏压黑层
]]
function CodeGameScreenAquaQuestMachine:hideBlackLayer( )
    self.m_blackLayer:runCsbAction("over",false,function()
        self.m_blackLayer:setVisible(false)
    end)
end


function CodeGameScreenAquaQuestMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    self.m_waittingNode = cc.Node:create()
    self:addChild(self.m_waittingNode)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 


    -- 创建view节点方式
    -- self.m_AquaQuestView = util_createView("CodeAquaQuestSrc.AquaQuestView")
    -- self:findChild("xxxx"):addChild(self.m_AquaQuestView)
   
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenAquaQuestMachine:initSpineUI()
    
end


function CodeGameScreenAquaQuestMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig["sound_AquaQuest_enter_level"])
    end)
end

function CodeGameScreenAquaQuestMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isEnter = true
    CodeGameScreenAquaQuestMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_jackPotBarView:changJackpotBar(false)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:changeGameBg("base")
        self:findChild("Node_fg_reel"):setVisible(false)
        self:findChild("xian_base"):setVisible(true)
        self:findChild("xian_fg"):setVisible(false)
        if not self.m_runSpinResultData.p_reSpinCurCount or self.m_runSpinResultData.p_reSpinCurCount == 0 then
            self:showStartView()
        end
        
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeUI()
    end

    self.m_isEnter = false
end


--[[
    进入关卡弹板
]]
function CodeGameScreenAquaQuestMachine:showStartView()
    local ownerlist = {}
    local view = self:showDialog("Start", ownerlist)
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_click"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_hide_level_start_view"])
    end)

    local spine = util_spineCreate("Socre_AquaQuest_Bonus",true,true)
    view:findChild("pangxie"):addChild(spine)
    util_spinePlay(spine,"idleframe_tanban5",true)

    local spine2 = util_spineCreate("AquaQuest_guochang2",true,true)
    view:findChild("Node_ji"):addChild(spine2)
    util_spinePlay(spine2,"idleframe_tanban",true)

    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenAquaQuestMachine:addObservers()
    CodeGameScreenAquaQuestMachine.super.addObservers(self)
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

        local soundName = PublicConfig.SoundConfig["sound_AquaQuest_winline_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_AquaQuest_winline_free_"..soundIndex]
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenAquaQuestMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenAquaQuestMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenAquaQuestMachine:getBounsScatterDataZorder(symbolType)
    local symbolOrder = CodeGameScreenAquaQuestMachine.super.getBounsScatterDataZorder(self, symbolType)

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
    elseif self:isFixSymbol(symbolType) then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
    end

    return symbolOrder
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAquaQuestMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL_1  then
        return "Socre_AquaQuest_Bonus"
    elseif symbolType == self.SYMBOL_FIX_SYMBOL_2 then
        return "Socre_AquaQuest_Bonus"
    elseif symbolType == self.SYMBOL_FIX_SYMBOL_3 then
        return "Socre_AquaQuest_Bonus"
    elseif symbolType == self.SYMBOL_FIX_SYMBOL_EMPTY then
        return "Socre_AquaQuest_Empty"
    end 


    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAquaQuestMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenAquaQuestMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenAquaQuestMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAquaQuestMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenAquaQuestMachine:beginReel()
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()

    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local endCount = 0
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        local moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            parentData.moveSpeed = moveSpeed
            reelNode:changeReelMoveSpeed(moveSpeed)
        end
        reelNode:resetReelDatas()
        reelNode:startMove(function()
            endCount = endCount + 1
            if endCount >= #self.m_baseReelNodes then
                local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                local fsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                if self:getCurrSpinMode() == FREE_SPIN_MODE and fsLeftCount == fsTotalCount then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_enter_free"])
                    local csbAni = util_createAnimation("AquaQuest_free_kaichang.csb")
                    self:findChild("Node_reel1"):addChild(csbAni)
                    csbAni:runCsbAction("actionframe",false,function()
                        self:requestSpinReusltData()
                        if not tolua.isnull(csbAni) then
                            csbAni:removeFromParent()
                        end
                    end)
                else
                    self:requestSpinReusltData()
                end
            end
        end)
    end
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenAquaQuestMachine:resetReelDataAfterReel()
    CodeGameScreenAquaQuestMachine.super.resetReelDataAfterReel(self)
    self.m_scatter_ary = {}
end

--
--单列滚动停止回调
--
function CodeGameScreenAquaQuestMachine:slotOneReelDown(reelCol)    
    CodeGameScreenAquaQuestMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol,self.m_spcial_symbol_list)
end

--[[
    滚轮停止
]]
function CodeGameScreenAquaQuestMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenAquaQuestMachine.super.slotReelDown(self)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAquaQuestMachine:addSelfEffect()

        
    -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAquaQuestMachine:MachineRule_playSelfEffect(effectData)

    -- if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then

        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        effectData.p_isPlay = true
        self:playGameEffect()

    -- end

    
    return true
end



function CodeGameScreenAquaQuestMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenAquaQuestMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenAquaQuestMachine:playScatterTipMusicEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_scatter_trigger_in_free"])
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_scatter_trigger"])
    end
    
end

-- 不用系统音效
function CodeGameScreenAquaQuestMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenAquaQuestMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenAquaQuestMachine:checkRemoveBigMegaEffect()
    CodeGameScreenAquaQuestMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenAquaQuestMachine:getShowLineWaitTime()
    local time = CodeGameScreenAquaQuestMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

function CodeGameScreenAquaQuestMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    
    bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

    self.m_baseGameBgSpine = util_spineCreate("AquaQuestBg_base",true,true)
    local parentNode = self.m_gameBg:findChild("base")
    parentNode:addChild(self.m_baseGameBgSpine)
    util_spinePlay(self.m_baseGameBgSpine,"base",true)
end

function CodeGameScreenAquaQuestMachine:changeGameBg(gameType)
    local baseNode = self.m_gameBg:findChild("base")
    local freeNode = self.m_gameBg:findChild("free")
    local respinNode = self.m_gameBg:findChild("respin")
    if gameType == "base" then
        baseNode:setVisible(true)
        freeNode:setVisible(false)
        respinNode:setVisible(false)
        self.m_gameBg:runCsbAction("base",true)
    elseif gameType == "free" then
        baseNode:setVisible(false)
        freeNode:setVisible(true)
        respinNode:setVisible(false)
        self.m_gameBg:runCsbAction("free",true)
    elseif gameType == "respin" then
        baseNode:setVisible(false)
        freeNode:setVisible(false)
        respinNode:setVisible(true)
        self.m_gameBg:runCsbAction("respin",true)
    elseif gameType == "changeScene1" then
        self.m_gameBg:runCsbAction("actionframe_guochang1")
    elseif gameType == "changeScene2" then
        self.m_gameBg:runCsbAction("actionframe_guochang2")
    end
    
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenAquaQuestMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeAquaQuestSrc.AquaQuestFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenAquaQuestMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenAquaQuestMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

--[[
    显示free相关UI
]]
function CodeGameScreenAquaQuestMachine:showFreeUI()
    self:changeGameBg("free")

    self:findChild("Node_base_reel"):setVisible(false)
    self:findChild("Node_fg_reel"):setVisible(true)

    self:findChild("xian_base"):setVisible(false)
    self:findChild("xian_fg"):setVisible(true)
end

--[[
    隐藏free相关UI
]]
function CodeGameScreenAquaQuestMachine:hideFreeUI()
    self:hideFreeSpinBar()
    self:changeGameBg("base")

    self:findChild("Node_base_reel"):setVisible(true)
    self:findChild("Node_fg_reel"):setVisible(false)


    self:findChild("xian_base"):setVisible(true)
    self:findChild("xian_fg"):setVisible(false)
    
end

function CodeGameScreenAquaQuestMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_show_fs_more"])
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self.m_baseFreeSpinBar:addFreeCountAni()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)

            view:findChild("root"):setScale(self.m_machineRootScale)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_show_fs_start"])
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_scene_to_free"])
                self:changeSceneToFree(function()
                    self:triggerFreeSpinCallFun()

                    self:showFreeUI()
                    
                end,function()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end)   
            end)
            view:setBtnClickFunc(function(  )
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_click"])
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_hide_fs_start"])
            end)

            view:findChild("root"):setScale(self.m_machineRootScale)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

--[[
    过场动画(free)
]]
function CodeGameScreenAquaQuestMachine:changeSceneToFree(keyFunc,keyFunc2,endFunc)
    local spine = util_spineCreate("AquaQuest_guochang",true,true)
    local rootNode = self:findChild("root")
    rootNode:addChild(spine)

    self:delayCallBack(40 / 30,keyFunc)
    self:delayCallBack(70 / 30,keyFunc2)
    util_spinePlayAndRemove(spine,"actionframe_guochang",endFunc)
end

function CodeGameScreenAquaQuestMachine:showFreeSpinOverView(effectData)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_show_fs_over_view"])

    local view = self:showFreeSpinOver(
        globalData.slotRunData.lastWinCoin, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_scene_to_base_from_free"])
            self:changeSceneToFree(function()
                self:hideFreeUI()
            end,function()
                self:triggerFreeSpinOverCallFun()
            end)
            
        end
    )

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_click"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_hide_fs_over_view"])
    end)

    view:findChild("root"):setScale(self.m_machineRootScale)
      
end

function CodeGameScreenAquaQuestMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}

    if coins > 0 then
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

        local spine1 = util_spineCreate("Socre_AquaQuest_Bonus",true,true)
        view:findChild("pangxie"):addChild(spine1)
        util_spinePlay(spine1,"idleframe_tanban1",true)

        local spine2 = util_spineCreate("Socre_AquaQuest_Bonus",true,true)
        view:findChild("pangxie"):addChild(spine2)
        util_spinePlay(spine2,"idleframe_tanban2",true)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.74,sy=0.74},900)  
        return view
    else
        local view = self:showDialog("FreeSpinOver_0", ownerlist, func)

        return view
    end

    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenAquaQuestMachine:showEffect_FreeSpin(effectData)
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
            table.remove(self.m_reelResultLines, i)
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
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

        --触发动画
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
function CodeGameScreenAquaQuestMachine:runScatterTriggerAni(func)
    self:showBlackLayer()
    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()
    local delayTime = 0
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) then
            if self:isFixSymbol(symbolNode.p_symbolType) then
                self:putSymbolBackToPreParent(symbolNode)
            elseif symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:changeParentToOtherNode(self.m_effectNode)
                symbolNode:runAnim("actionframe",false,function()
                    if not tolua.isnull(symbolNode) then
                        self:changeSymbolToClipParent(symbolNode)
                    end
                end)
                delayTime = symbolNode:getAniamDurationByName("actionframe")
            end
        end
    end

    self:delayCallBack(delayTime,function()
        self:hideBlackLayer()
        if type(func) == "function" then
            func()
        end
    end)
end

-- 继承底层respinView
function CodeGameScreenAquaQuestMachine:getRespinView()
    return "CodeAquaQuestSrc.AquaQuestRespinView"    
end

-- 继承底层respinNode
function CodeGameScreenAquaQuestMachine:getRespinNode()
    return "CodeAquaQuestSrc.AquaQuestRespinNode"    
end

function CodeGameScreenAquaQuestMachine:updateReelGridNode(symbolNode)
    if tolua.isnull(symbolNode) or not symbolNode.p_symbolType then
        return
    end
    local symbolType = symbolNode.p_symbolType
    if self.m_isEnter then
        if symbolType == self.SYMBOL_FIX_SYMBOL_1 then
            symbolNode:runAnim("idleframe4",true)
        elseif symbolType == self.SYMBOL_FIX_SYMBOL_2 then
            symbolNode:runAnim("idleframe5",true)
        elseif symbolType == self.SYMBOL_FIX_SYMBOL_3 then
            symbolNode:runAnim("idleframe6",true)
        end
        
    else
        if symbolType == self.SYMBOL_FIX_SYMBOL_1 then
            symbolNode:runAnim("idleframe1")
        elseif symbolType == self.SYMBOL_FIX_SYMBOL_2 then
            symbolNode:runAnim("idleframe2")
        elseif symbolType == self.SYMBOL_FIX_SYMBOL_3 then
            symbolNode:runAnim("idleframe3")
        end
    end 
end


-- 是不是 respinBonus小块
function CodeGameScreenAquaQuestMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL_1 or
        symbolType == self.SYMBOL_FIX_SYMBOL_2 or
        symbolType == self.SYMBOL_FIX_SYMBOL_3 then
        return true
    end
    return false    
end

function CodeGameScreenAquaQuestMachine:getJackpotScore(_jpName)
    local jackpotCoinData = self.m_runSpinResultData.p_jackpotCoins or {}
    local coins = jackpotCoinData[_jpName]
    return coins    
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenAquaQuestMachine:getRespinRandomTypes()
    local symbolList = {
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_EMPTY,
        self.SYMBOL_FIX_SYMBOL_1,
    }
    return symbolList    
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenAquaQuestMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL_1, runEndAnimaName = "buling1", bRandom = false,idleAniName = "idleframe4"}
    }
    return symbolList    
end

--[[
    bonus触发动画
]]
function CodeGameScreenAquaQuestMachine:runBonusTriggerAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_bonus_trigger"])
    local delayTime = 0
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) then
            if symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL_1 then
                symbolNode:runAnim("actionframe1",false,function()
                    symbolNode:runAnim("idleframe4",true)
                end)
                local aniTime = symbolNode:getAniamDurationByName("actionframe1")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            elseif symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL_2 then
                symbolNode:runAnim("actionframe2",false,function()
                    symbolNode:runAnim("idleframe5",true)
                end)
                local aniTime = symbolNode:getAniamDurationByName("actionframe2")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            elseif symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL_3 then
                symbolNode:runAnim("actionframe3",false,function()
                    symbolNode:runAnim("idleframe6",true)
                end)
                local aniTime = symbolNode:getAniamDurationByName("actionframe3")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end
        end
    end

    self:delayCallBack(delayTime,func)
end

function CodeGameScreenAquaQuestMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:delayCallBack(0.5,function()
        self:runBonusTriggerAni(function()
            self:showReSpinStart(function()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )
                --可随机的特殊信号
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)  

                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_scene_to_respin"])
                self:changeSceneToRespin(function()
                    self:changeGameBg("respin")
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                end,function()
                    self:resetMusicBg(true)
                    --大信号合图
                    self.m_respinReelView:changeToBigSymbol(function()
                        self:runNextReSpinReel()
                    end)
                end)
                
            end)
        end)
    end)
end

--[[
    过场动画(respin)
]]
function CodeGameScreenAquaQuestMachine:changeSceneToRespin(keyFunc,endFunc)
    local spine = util_spineCreate("AquaQuest_guochang2",true,true)
    local rootNode = self:findChild("root")
    rootNode:addChild(spine)

    self:delayCallBack(105 / 30,keyFunc)
    util_spinePlayAndRemove(spine,"actionframe_guochang1",endFunc)
end

function CodeGameScreenAquaQuestMachine:showReSpinStart(func)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if not rsExtraData then
        if type(func) == "function" then
            func()
        end
        return
    end
    local reelNum = rsExtraData.reelNum
    local reelColumns = rsExtraData.reelColumns
    local view
    if reelNum == 1 then
        if reelColumns == 5 then
            view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func)
        else
            view = self:showDialog("ReSpinStart_3x7", nil, func)
        end
    else
        if reelColumns == 5 then
            view = self:showDialog("ReSpinStart_2grids", nil, func)
        else
            view = self:showDialog("ReSpinStart_3x7s", nil, func)
        end
    end

    view:findChild("root"):setScale(self.m_machineRootScale)

    local spine = util_spineCreate("FreeSpinStart_bg",true,true)
    view:findChild("Node_tanban"):addChild(spine)
    util_spinePlay(spine,"start")
    util_spineEndCallFunc(spine,"start",function()
        util_spinePlay(spine,"idle",true)
    end)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_show_respin_start"])

    view:setBtnClickFunc(function()
        if not tolua.isnull(spine) then
            util_spinePlay(spine,"over")
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_click"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_hide_respin_start"])
    end)

    return view
end

--触发respin
function CodeGameScreenAquaQuestMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    local reelNum = rsExtraData.reelNum --轮盘数量
    local colNum = rsExtraData.reelColumns --respin列数

    self.m_respinReelView = util_createView("CodeAquaQuestSrc.AquaQuestRespinReelView",{
        machine = self,
        colNum = colNum,
        rowNum = self.m_iReelRowNum,
        isDouble = reelNum > 1,
        endTypes = endTypes,
        randomTypes = randomTypes,
        getSlotNodeWithPosAndType = function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        pushSlotNodeToPoolBySymobolType = function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end,
    })
    self:findChild("Node_respin"):addChild(self.m_respinReelView)
    self.m_respinReelView:createRespinView()
    self.m_respinReelView:setVisible(false)

    self:changeTouchLayerSize(self.m_respinReelView:getFirstReelNode(),reelNum,colNum)

    

    
end

function CodeGameScreenAquaQuestMachine:initRespinView(endTypes, randomTypes)

    

    -- --构造盘面数据
    -- local respinNodeInfo = self:reateRespinNodeInfo()

    -- --继承重写 改变盘面数据
    -- self:triggerChangeRespinNodeInfo(respinNodeInfo)

    -- self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    -- self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    -- self.m_respinView:initRespinElement(
    --     respinNodeInfo,
    --     self.m_iReelRowNum,
    --     self.m_iReelColumnNum,
    --     function()
    --         self:reSpinEffectChange()
    --         self:playRespinViewShowSound()
    --         self:showReSpinStart(
    --             function()
    --                 self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    --                 -- 更改respin 状态下的背景音乐
    --                 self:changeReSpinBgMusic()
    --                 self:runNextReSpinReel()
    --             end
    --         )
    --     end
    -- )

    -- --隐藏 盘面信息
    -- self:setReelSlotsNodeVisible(false)
end

--开始下次ReSpin
function CodeGameScreenAquaQuestMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    self.m_waittingNode:stopAllActions()
    performWithDelay(self.m_waittingNode,function()
        self:startReSpinRun()
    end,self.m_RESPIN_RUN_TIME)
end

function CodeGameScreenAquaQuestMachine:MachineRule_respinTouchSpinBntCallBack()
    if self.m_respinReelView and self.m_respinReelView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        self.m_waittingNode:stopAllActions()
        self.m_respinReelView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
        self:startReSpinRun()
    elseif self.m_respinReelView and self.m_respinReelView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        --快停
        self:quicklyStop()
    end
end

--- respin 快停
function CodeGameScreenAquaQuestMachine:quicklyStop()
    self.m_respinReelView:quicklyStop()
end

--开始滚动
function CodeGameScreenAquaQuestMachine:startReSpinRun()
    if self.m_respinReelView.m_isRunning then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    self:requestSpinReusltData()
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinReelView:startMove()
end

--接收到数据开始停止滚动
function CodeGameScreenAquaQuestMachine:stopRespinRun()
    self.m_respinReelView:stopRespinRun()
end

---判断结算
function CodeGameScreenAquaQuestMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:delayCallBack(0.6,function()
        self.m_respinReelView:changeToBigSymbol(function()
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                self.m_respinReelView:hideRespinBar()
                
                self.m_respinReelView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        
                --quest
                self:updateQuestBonusRespinEffectData()
        
                --结束
                self:reSpinEndAction()
        
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        
                self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
                self.m_isWaitingNetworkData = false
        
                return
            end
        
            self.m_respinReelView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            end
            --继续
            self:runNextReSpinReel()
        
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end)
    end)
end

function CodeGameScreenAquaQuestMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:removeRespinNode()

    self:delayCallBack(0.5,function()
        
        self.m_respinReelView:runEndTriggerAni(function()
            
            self.m_respinReelView:changeSymbolToCoins(function()
                self:showRespinOverView()
            end)
        end)
    end)
    
    
end

--结束移除小块调用结算特效
function CodeGameScreenAquaQuestMachine:removeRespinNode()
    self.m_respinReelView:removeRespinNode()
end

--ReSpin开始改变UI状态
function CodeGameScreenAquaQuestMachine:changeReSpinStartUI(respinCount)
    self:findChild("Node_base_fg"):setVisible(false)
    self.m_respinReelView:updateRespinCount(respinCount)

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    local reelNum = rsExtraData.reelNum --轮盘数量
    local colNum = rsExtraData.reelColumns --respin列数

    util_changeNodeParent(self.m_respinReelView:findChild("Node_jackpot"),self.m_jackPotBarView)
    self.m_jackPotBarView:changJackpotBar(reelNum > 1 or colNum > 5)

    self.m_respinReelView:setVisible(true)
end

--ReSpin刷新数量
function CodeGameScreenAquaQuestMachine:changeReSpinUpdateUI(curCount)
    self.m_respinReelView:updateRespinCount(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenAquaQuestMachine:changeReSpinOverUI()
    self:findChild("Node_base_fg"):setVisible(true)
    
    self:resetTouchLayerSize()
    if self.m_bProduceSlots_InFreeSpin then
        self:showFreeUI()
    else
        self:changeGameBg("base")
    end

    util_changeNodeParent(self:findChild("Node_jackpot"),self.m_jackPotBarView)
    self.m_jackPotBarView:changJackpotBar(false)
end

function CodeGameScreenAquaQuestMachine:showRespinOverView(effectData)
    self:clearCurMusicBg()
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()

        self:delayCallBack(0.5,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_scene_to_base_from_respin"])
            self:changeSceneToBaseFromRespin(function()
                self:changeReSpinOverUI()
                self.m_respinReelView:removeFromParent()
                self.m_respinReelView = nil
            end,function()
                self:triggerReSpinOverCallFun(self.m_lightScore)
                self.m_lightScore = 0
                self:resetMusicBg()
            end)
        end)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.74,sy=0.74},900)    

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_show_respin_over_view"])

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_click"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_hide_respin_over_view"])
    end)

    view:findChild("root"):setScale(self.m_machineRootScale)
end


function CodeGameScreenAquaQuestMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

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
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
    过场动画(respin)
]]
function CodeGameScreenAquaQuestMachine:changeSceneToBaseFromRespin(keyFunc,endFunc)
    local spine = util_spineCreate("AquaQuest_guochang2",true,true)
    local rootNode = self:findChild("root")
    rootNode:addChild(spine)

    self:delayCallBack(145 / 30,keyFunc)
    util_spinePlayAndRemove(spine,"actionframe_guochang2",endFunc)
end

function CodeGameScreenAquaQuestMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeAquaQuestSrc.AquaQuestJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenAquaQuestMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeAquaQuestSrc.AquaQuestJackpotWinView",{
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

function CodeGameScreenAquaQuestMachine:setReelRunInfo()
    self.m_longRunControl:checkTriggerLongRun()  
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenAquaQuestMachine:MachineRule_ResetReelRunData()
    CodeGameScreenAquaQuestMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
    检测播放落地动画
]]
function CodeGameScreenAquaQuestMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                self:pushToSpecialSymbolList(symbolNode)

                if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    self.m_scatter_ary[#self.m_scatter_ary + 1] = symbolNode
                end
                --提层
                if symbolCfg[1] then
                    -- local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                    -- util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    -- symbolNode:setPositionY(curPos.y)
                    self:changeSymbolToClipParent(symbolNode)
                    local curPos = cc.p(symbolNode:getPosition())

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
    播放bonus落地音效
]]
function CodeGameScreenAquaQuestMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AquaQuest_bonus_down)
end

--[[
    播放scatter落地音效
]]
function CodeGameScreenAquaQuestMachine:playScatterDownSound(colIndex)
    if #self.m_scatter_ary == 0 then
        return
    end
    if #self.m_scatter_ary == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AquaQuest_scatter_down_1)
    elseif #self.m_scatter_ary == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AquaQuest_scatter_down_2)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AquaQuest_scatter_down_3)
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenAquaQuestMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end

            elseif self:isFixSymbol(_slotNode.p_symbolType) then
                return true
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenAquaQuestMachine:isPlayTipAnima(colIndex, rowIndex, node)
    local scatterNum = #self.m_scatter_ary
    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        scatterNum  = scatterNum - 1
    end

    if colIndex <= 3 then
        return true
    elseif colIndex == 4 then
        if scatterNum >= 1  then
            return true
        end
    elseif colIndex == 5 then
        if scatterNum >= 2  then
            return true
        end
    end
    return false
end

function CodeGameScreenAquaQuestMachine:symbolBulingEndCallBack(_slotNode)
    if tolua.isnull(_slotNode) then
        return
    end
    local symbolType = _slotNode.p_symbolType
    if symbolType == self.SYMBOL_FIX_SYMBOL_1 then
        _slotNode:runAnim("idleframe4",true)
    elseif symbolType == self.SYMBOL_FIX_SYMBOL_2 then
        _slotNode:runAnim("idleframe5",true)
    elseif symbolType == self.SYMBOL_FIX_SYMBOL_3 then
        _slotNode:runAnim("idleframe6",true)
    end
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenAquaQuestMachine:isPlayExpect(reelCol)
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
function CodeGameScreenAquaQuestMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance(40) then

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
function CodeGameScreenAquaQuestMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("root")
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_notice_win"])
    self.b_gameTipFlag = true
    local csbAni = util_createAnimation("AquaQuest_yugao.csb")
    
    if parentNode and not tolua.isnull(csbAni) then
        parentNode:addChild(csbAni)
        csbAni:runCsbAction("actionframe",false,function()
            csbAni:removeFromParent()
        end)
        aniTime = util_csbGetAnimTimes(csbAni.m_csbAct,"actionframe")
    end

     --计算延时,预告中奖播完时需要刚好停轮
     local delayTime = self:getRunTimeBeforeReelDown()

     --预告中奖时间比滚动时间短,直接返回即可
     if aniTime <= delayTime then
         if type(func) == "function" then
             func()
         end
     else
         self:delayCallBack(aniTime - delayTime,function()
             if type(func) == "function" then
                 func()
             end
         end)
     end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenAquaQuestMachine:showBigWinLight(func)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_show_big_win_light"])
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local spine1 = util_spineCreate("AquaQuest_bigwindi",true,true)
    self:findChild("Node_bigwin_bg"):addChild(spine1)
    util_spinePlayAndRemove(spine1,"actionframe_bigwin")

    local spine2 = util_spineCreate("AquaQuest_bigwin",true,true)
    self:findChild("Node_bigwin"):addChild(spine2)
    local aniTime = util_spinePlayAndRemove(spine2,"actionframe_bigwin",function()
        if type(func) == "function" then
            func()
        end
    end)

    util_shakeNode(rootNode,5,10,aniTime)
end


--播放
function CodeGameScreenAquaQuestMachine:playCoinWinEffectUI(curWinCoins,totalWinCoins,callBack)
    if self.m_bottomUI ~= nil then
        self.m_bottomUI:playCoinWinEffectUI(callBack)
    end

    self.m_bottomUI:setBigWinLabCoins(curWinCoins)

    local params = {
        overCoins  = curWinCoins,
        jumpTime   = 0.1,
        animName   = "actionframe",
    }
    self:playBottomBigWinLabAnim(params)

    --刷新赢钱
    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoins))
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenAquaQuestMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end

    --scatter连线不播连线框,但是有赢钱
    if lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return
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
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end

    self:showEachLineSlotNodeLineAnim(frameIndex)
end

---
-- 显示所有的连线框
--
function CodeGameScreenAquaQuestMachine:showAllFrame(winLines)
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

        --scatter连线不播连线框,但是有赢钱
        if lineValue.enumSymbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            for i = 1, frameNum do
                local symPosData = lineValue.vecValidMatrixSymPos[i]
    
                if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
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

function CodeGameScreenAquaQuestMachine:scaleMainLayer()
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
    if ratio > 768 / 920 then  --920以下
        mainScale = 0.80
    elseif ratio <= 768 / 920 and ratio > 768 / 1152 then --920
        mainScale = 0.67
    elseif ratio <= 768 / 1152 and ratio > 768 / 1228 then --1152
        mainScale = 0.82
        mainPosY  = mainPosY - 10
    elseif ratio <= 768 / 1228 and ratio > 768 / 1370 then --1228
        mainScale = 0.9
        mainPosY  = mainPosY - 10
    else --1370以上
        mainScale = 1
        mainPosY  = mainPosY - 10
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

return CodeGameScreenAquaQuestMachine






