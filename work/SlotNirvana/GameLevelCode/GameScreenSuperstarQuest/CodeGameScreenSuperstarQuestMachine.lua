---
-- island li
-- 2019年1月26日
-- CodeGameScreenSuperstarQuestMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "SuperstarQuestPublicConfig"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local CodeGameScreenSuperstarQuestMachine = class("CodeGameScreenSuperstarQuestMachine", BaseReelMachine)

CodeGameScreenSuperstarQuestMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenSuperstarQuestMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenSuperstarQuestMachine.SYMBOL_WILD_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenSuperstarQuestMachine.SYMBOL_WILD_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenSuperstarQuestMachine.SYMBOL_WILD_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenSuperstarQuestMachine.SYMBOL_WILD_4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4
CodeGameScreenSuperstarQuestMachine.SYMBOL_SCATTER_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5
CodeGameScreenSuperstarQuestMachine.SYMBOL_SCATTER_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6
CodeGameScreenSuperstarQuestMachine.SYMBOL_SCATTER_4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7
-- 自定义动画的标识
CodeGameScreenSuperstarQuestMachine.RESUM_REEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1  --恢复轮盘
CodeGameScreenSuperstarQuestMachine.COLLECT_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2  --收集wild

local JACKPOT_TYPE = {
    "normal",
    "minor",
    "major",
    "mega"
}

-- 构造函数
function CodeGameScreenSuperstarQuestMachine:ctor()
    CodeGameScreenSuperstarQuestMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeSuperstarQuestSrc.SuperstarQuestSymbolExpect",{
        machine = self,
        symbolList = {
            {
                symbolTypeList = {
                    TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
                    self.SYMBOL_SCATTER_2,
                    self.SYMBOL_SCATTER_3,
                    self.SYMBOL_SCATTER_4
                }, --可触发的信号值
                triggerCount = 3,    --触发所需数量
                expectAni = "idleframe3",     --期待时间线 根据动效时间线调整
                idleAni = "idleframe2"      --根据动效时间线调整
            }
        }
    }) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("SuperstarQuestLongRunControl",{
        machine = self,
        symbolList = {
            {
                symbolTypeList = {
                    TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
                    self.SYMBOL_SCATTER_2,
                    self.SYMBOL_SCATTER_3,
                    self.SYMBOL_SCATTER_4
                }, --可触发的信号值
                triggerCount = 3    --触发所需数量
            }
        }
    }) 


    self.m_isSkip = false --是否跳过
    self.m_isAddWild = false --是否正在添加wild
    self.m_addWildCallFunc = nil
    self.m_isChangeBet = false

    self.m_free_sound_index = 1


    self.m_lockWildList = {}
    self.m_flyWildNodeList = {}
    self.m_flyNodeActionList = {}

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    --init
    self:initGame()

    --背景音乐
    self:setBackGroundMusic("SuperstarQuestSounds/music_SuperstarQuest_base.mp3")
    
end

function CodeGameScreenSuperstarQuestMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

function CodeGameScreenSuperstarQuestMachine:initGameStatusData(gameData)
    CodeGameScreenSuperstarQuestMachine.super.initGameStatusData(self, gameData)
    self.m_wildNumList = gameData.gameConfig.extra.basewildnum
    self.m_initWildList = gameData.gameConfig.extra.wildFirstnum
    self.m_maxWildList = gameData.gameConfig.extra.wildmaxnum
end

--[[
    获取当前wild数量
]]
function CodeGameScreenSuperstarQuestMachine:getCurWildNum(jpType)
    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local list = self.m_initWildList
    local key = tostring(totalBet) 

    if self.m_wildNumList and self.m_wildNumList[key] then
        list = self.m_wildNumList[key].mylist
    end

    if jpType == "mega" then
        return list[4]
    elseif jpType == "major" then
        return list[3]
    elseif jpType == "minor" then
        return list[2]
    end

    return list[1]
end

function CodeGameScreenSuperstarQuestMachine:getMaxWildNum(jpType)
    local list = self.m_maxWildList

    if jpType == "mega" then
        return list[4]
    elseif jpType == "major" then
        return list[3]
    elseif jpType == "minor" then
        return list[2]
    end

    return list[1]
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenSuperstarQuestMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "SuperstarQuest"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenSuperstarQuestMachine:getNetWorkModuleName()
    return "SuperstarQuestV2"
end

function CodeGameScreenSuperstarQuestMachine:getReelNode()
    return "CodeSuperstarQuestSrc.SuperstarQuestReelNode"
end

--[[
    创建压黑层
]]
function CodeGameScreenSuperstarQuestMachine:createBlackLayer(size)
    local sp_reel = self.m_csbOwner["sp_reel_0"]
    local startPos = cc.p(sp_reel:getPosition()) 

    local layerSize = cc.size(size.width / self.m_iReelColumnNum,size.height)

    self.m_blackNodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        local blackLayer = ccui.Layout:create()
        blackLayer:setContentSize(layerSize)
        blackLayer:setAnchorPoint(cc.p(0, 0))
        blackLayer:setTouchEnabled(false)
        self.m_clipParent:addChild(blackLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20 + iCol)
        blackLayer:setPosition(cc.p(startPos.x + layerSize.width * (iCol - 1),startPos.y))
        blackLayer:setBackGroundColor(cc.c3b(0, 0, 0))
        blackLayer:setBackGroundColorOpacity(180)
        blackLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        blackLayer:setVisible(false)
        self.m_blackNodes[iCol] = blackLayer
    end
end

--[[
    显示压黑层
]]
function CodeGameScreenSuperstarQuestMachine:showBlackLayer(colIndex)
    if not colIndex then
        for iCol = 1,self.m_iReelColumnNum do
            local blackLayer = self.m_blackNodes[iCol]
            blackLayer:setVisible(true)
            blackLayer:stopAllActions()
            util_nodeFadeIn(blackLayer,0.2,0,180)
        end
    else
        local blackLayer = self.m_blackNodes[colIndex]
        blackLayer:setVisible(true)
        blackLayer:stopAllActions()
        util_nodeFadeIn(blackLayer,0.2,0,180)
    end
    
end

--[[
    隐藏压黑层
]]
function CodeGameScreenSuperstarQuestMachine:hideBlackLayer(colIndex)
    if not colIndex then
        for iCol = 1,self.m_iReelColumnNum do
            local blackLayer = self.m_blackNodes[iCol]
            blackLayer:stopAllActions()
            util_fadeOutNode(blackLayer,0.2,function(  )
                blackLayer:setVisible(false)
            end)
        end
    else
        local blackLayer = self.m_blackNodes[colIndex]
        blackLayer:stopAllActions()
        util_fadeOutNode(blackLayer,0.2,function(  )
            blackLayer:setVisible(false)
        end)
    end
    
end


function CodeGameScreenSuperstarQuestMachine:initUI()

    local spinParent = self.m_bottomUI:findChild("free_spin_new")
    if spinParent then
        self.m_skipBtn = util_createView("CodeSuperstarQuestSrc.SuperstarQuestSkipBtn",{machine = self})
        spinParent:addChild(self.m_skipBtn)
        self.m_skipBtn:setVisible(false)
    end

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    self.m_effectNode2 = self:findChild("Node_effect")

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initJackPotBarView()

    --增加wild时的飞行特效
    self.m_flyNode = util_createAnimation("Socre_SuperstarQuest_Wild_tx.csb")
    self.m_effectNode2:addChild(self.m_flyNode,10000)
    self.m_flyNode:setVisible(false)
    
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_SuperstarQuestView = util_createView("CodeSuperstarQuestSrc.SuperstarQuestView")
    -- self:findChild("xxxx"):addChild(self.m_SuperstarQuestView)
   
end

--[[
    初始化jackpot
]]
function CodeGameScreenSuperstarQuestMachine:initJackPotBarView()
    -----------------
    self.m_base_minor = util_createView("CodeSuperstarQuestSrc.SuperstarQuestBaseTopNode",{machine = self,jpType = "Minor"})
    self:findChild("node_base_minor"):addChild(self.m_base_minor)

    self.m_free_minor = util_createView("CodeSuperstarQuestSrc.SuperstarQuestFreeTopNode",{machine = self,jpType = "Minor"})
    self:findChild("node_free_minor"):addChild(self.m_free_minor)
    self.m_free_minor:setVisible(false)


    --------------------
    self.m_base_major = util_createView("CodeSuperstarQuestSrc.SuperstarQuestBaseTopNode",{machine = self,jpType = "Major"})
    self:findChild("node_base_major"):addChild(self.m_base_major)

    self.m_free_major = util_createView("CodeSuperstarQuestSrc.SuperstarQuestFreeTopNode",{machine = self,jpType = "Major"})
    self:findChild("node_free_major"):addChild(self.m_free_major)
    self.m_free_major:setVisible(false)

    --------------------
    self.m_base_mega = util_createView("CodeSuperstarQuestSrc.SuperstarQuestBaseTopNode",{machine = self,jpType = "Mega"})
    self:findChild("node_base_mega"):addChild(self.m_base_mega)

    self.m_free_mega = util_createView("CodeSuperstarQuestSrc.SuperstarQuestFreeTopNode",{machine = self,jpType = "Mega"})
    self:findChild("node_free_mega"):addChild(self.m_free_mega)
    self.m_free_mega:setVisible(false)

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenSuperstarQuestMachine:initSpineUI()
    
end


function CodeGameScreenSuperstarQuestMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_SuperstarQuest_enter_level)
    end)
end

function CodeGameScreenSuperstarQuestMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isEnter = false
    CodeGameScreenSuperstarQuestMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:initCollectFlyNodeList()

    self:updateWildNum()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeUI()
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        local freeKind = fsExtraData.freekind
        --fs背景音乐
        if freeKind == 1 then
            self:setFsBackGroundMusic("SuperstarQuestSounds/music_SuperstarQuest_free_minor.mp3")
        elseif freeKind == 2 then
            self:setFsBackGroundMusic("SuperstarQuestSounds/music_SuperstarQuest_free_major.mp3")
        else
            self:setFsBackGroundMusic("SuperstarQuestSounds/music_SuperstarQuest_free_mega.mp3")
        end
    else
        self:hideFreeUI()
    end
    self.m_isEnter = true
end

--[[
    刷新wild数量显示
]]
function CodeGameScreenSuperstarQuestMachine:updateWildNum()

    local minorCount = self:getCurWildNum("minor")
    self.m_base_minor:updateCount(minorCount)
    self.m_free_minor:updateCount(minorCount)

    local majorCount = self:getCurWildNum("major")
    self.m_base_major:updateCount(majorCount)
    self.m_free_major:updateCount(majorCount)

    local megaCount = self:getCurWildNum("mega")
    self.m_base_mega:updateCount(megaCount)
    self.m_free_mega:updateCount(megaCount)
end

function CodeGameScreenSuperstarQuestMachine:updateWildCountByJpType(jpType,count)
    if jpType == "mega" then
        self.m_base_mega:updateCount(count)
        self.m_free_mega:updateCount(count)
    elseif jpType == "major" then
        self.m_base_major:updateCount(count)
        self.m_free_major:updateCount(count)
    elseif jpType == "minor" then
        self.m_base_minor:updateCount(count)
        self.m_free_minor:updateCount(count)
        
    end
end

function CodeGameScreenSuperstarQuestMachine:addObservers()
    CodeGameScreenSuperstarQuestMachine.super.addObservers(self)
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

        local selfData = self.m_runSpinResultData.p_selfMakeData

        local soundName = PublicConfig.SoundConfig["sound_SuperstarQuest_winline_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            local freeKind = fsExtraData.freekind
            if freeKind == 1 then
                soundName = PublicConfig.SoundConfig["sound_SuperstarQuest_winline_free_minor_"..soundIndex] 
            elseif freeKind == 2 then
                soundName = PublicConfig.SoundConfig["sound_SuperstarQuest_winline_free_major_"..soundIndex] 
            else
                soundName = PublicConfig.SoundConfig["sound_SuperstarQuest_winline_free_mega_"..soundIndex] 
            end
        elseif selfData and selfData.basetr_pos and #selfData.basetr_pos > 0 then
            soundName = PublicConfig.SoundConfig["sound_SuperstarQuest_winline_base_wild_"..soundIndex] 
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            -- self.m_isChangeBet = true
            self:stopFlyNode()
            self:updateWildNum()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenSuperstarQuestMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenSuperstarQuestMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
--设置bonus scatter 层级
function CodeGameScreenSuperstarQuestMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if self:isScatterSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif self:isWildSymbol(symbolType) then
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
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenSuperstarQuestMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_SuperstarQuest_10"
    elseif self:isWildSymbol(symbolType) then
        return "Socre_SuperstarQuest_Wild"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_SuperstarQuest_Scatter1"
    elseif symbolType == self.SYMBOL_SCATTER_2 then
        return "Socre_SuperstarQuest_Scatter2"
    elseif symbolType == self.SYMBOL_SCATTER_3 then
        return "Socre_SuperstarQuest_Scatter3"
    elseif symbolType == self.SYMBOL_SCATTER_4 then
        return "Socre_SuperstarQuest_Scatter4"
    end
    return nil
end

function CodeGameScreenSuperstarQuestMachine:isWildSymbol(symbolType)
    if symbolType == self.SYMBOL_WILD_1 or 
    symbolType == self.SYMBOL_WILD_2 or 
    symbolType == self.SYMBOL_WILD_3 or
    symbolType == self.SYMBOL_WILD_4 then
        return true
    end
    return false
end

function CodeGameScreenSuperstarQuestMachine:isScatterSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or 
    symbolType == self.SYMBOL_SCATTER_2 or 
    symbolType == self.SYMBOL_SCATTER_3 or
    symbolType == self.SYMBOL_SCATTER_4 then
        return true
    end
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenSuperstarQuestMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenSuperstarQuestMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenSuperstarQuestMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenSuperstarQuestMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenSuperstarQuestMachine:beginReel()
    self:showBlackLayer()
    CodeGameScreenSuperstarQuestMachine.super.beginReel(self)
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenSuperstarQuestMachine:resetReelDataAfterReel()
    CodeGameScreenSuperstarQuestMachine.super.resetReelDataAfterReel(self)
    -- self:clearAllLockWild()
end

--
--单列滚动停止回调
--
function CodeGameScreenSuperstarQuestMachine:slotOneReelDown(reelCol)    
    self:hideBlackLayer(reelCol)
    CodeGameScreenSuperstarQuestMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol,self.m_spcial_symbol_list) 

end

--[[
    滚轮停止
]]
function CodeGameScreenSuperstarQuestMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    for key,lockWild in pairs(self.m_lockWildList) do
        local posIndex = tonumber(key)
        local symbolNode = self:getSymbolByPosIndex(posIndex)
        local wildIndex = lockWild.wildIndex
        local symbolType = self.SYMBOL_WILD_1 + wildIndex - 1
        if not tolua.isnull(symbolNode) then
            self:changeSymbolType(symbolNode,symbolType)
            self:updateReelGridNode(symbolNode)
        end
    end
    self:clearAllLockWild()

    self.m_isSkip = false

    
    CodeGameScreenSuperstarQuestMachine.super.slotReelDown(self)
    
end

--新滚动使用
function CodeGameScreenSuperstarQuestMachine:updateReelGridNode(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end
    local symbolType = symbolNode.p_symbolType
    if symbolType == self.SYMBOL_WILD_1 then
        symbolNode:changeSkin("skin1")
    elseif symbolType == self.SYMBOL_WILD_2 then
        symbolNode:changeSkin("skin2")
    elseif symbolType == self.SYMBOL_WILD_3 then
        symbolNode:changeSkin("skin3")
    elseif symbolType == self.SYMBOL_WILD_4 then
        symbolNode:changeSkin("skin4")
    end

    if self:isWildSymbol(symbolType) then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local multi = 1
        if selfData and selfData.basefinalwild then
            for index = 1,#selfData.basefinalwild do
                local data = selfData.basefinalwild[index]
                if data[1] == posIndex then
                    multi = data[2]
                    
                    break
                end
            end
        end
        self:changeMiltiLblCsbOnWild(symbolNode,multi)
    end
end

--[[
    获取小块spine槽点上绑定的csb节点
]]
function CodeGameScreenSuperstarQuestMachine:changeMiltiLblCsbOnWild(symbolNode,multi)
    if tolua.isnull(symbolNode) then
        return
    end
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine then
        local csbNode1 = spine.m_csbNode1
        local csbNode2 = spine.m_csbNode2
        if not csbNode1 then
            csbNode1 = util_createAnimation("Socre_SuperstarQuest_Wild_chengbei.csb")
            util_spinePushBindNode(spine,"chengbei",csbNode1)
            spine.m_csbNode1 = csbNode1

            csbNode2 = util_createAnimation("Socre_SuperstarQuest_Wild_chengbei.csb")
            util_spinePushBindNode(spine,"chengbei2",csbNode2)
            spine.m_csbNode2 = csbNode2
        end
        for iMulti = 2,5 do
            csbNode1:findChild("sp_x"..iMulti):setVisible(iMulti == multi)
            csbNode2:findChild("sp_x"..iMulti):setVisible(iMulti == multi)
        end

    end

    return spine.m_bindCsbNode,spine
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenSuperstarQuestMachine:addSelfEffect()

    local reels = self.m_runSpinResultData.p_reels

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.wildsignal and #selfData.wildsignal > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_WILD_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenSuperstarQuestMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_WILD_EFFECT then
        --收集wild
        self:collectWildAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

--[[
    洒落wild
]]
function CodeGameScreenSuperstarQuestMachine:addWildToReelAni(func)
    if self.m_isSkip then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.basetr_pos then
        if type(func) == "function" then
            func()
        end
        return 
    end
    local wildList = selfData.basetr_pos

    local wildIndex = 1
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local freeKind = fsExtraData.freekind
    if fsExtraData and freeKind then
        wildIndex  = wildIndex + freeKind
    end

    local sp_reel = self:findChild("sp_reel_2")
    local reelPos = util_convertToNodeSpace(sp_reel,self.m_effectNode2)
    local reelSize = sp_reel:getContentSize()
    --轮盘中心点
    local centerPos = cc.p(reelPos.x + reelSize.width / 2,reelPos.y + reelSize.height / 2)

    local callBack = function(collectBar)
        self:setSkipBtnShow(true)
        local actionList = {
            cc.EaseCubicActionOut:create(cc.MoveTo:create(38 / 60,centerPos)),
            cc.CallFunc:create(function()
                if self.m_isSkip then
                    return
                end
                --逐个洒落wild
                self:addNextWildAni(collectBar,centerPos,wildList,1,wildIndex,function()
                    if self.m_isSkip then
                        return
                    end
                    if not tolua.isnull(self.m_flyNode) then
                        self.m_flyNode:runCsbAction("over",false,function()
                            self.m_flyNode:setVisible(false)
                        end)
                    end
                    if type(func) == "function" then
                        func()
                    end
                end)
            end)
        }
        self.m_flyNode:setVisible(true)
        for index = 1,4 do
            self.m_flyNode:findChild("wild_"..index):setVisible(index == wildIndex)
        end

        self.m_flyNode:runAction(cc.Sequence:create(actionList))
        self.m_flyNode:runCsbAction("start")
    end

    --base下玩法
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        local countBar = self.m_free_minor
        if freeKind == 2 then
            self:changeBgAni("major_trigger")
            countBar = self.m_free_major
        elseif freeKind == 3 then
            countBar = self.m_free_mega
            self:changeBgAni("mega_trigger")
        else
            self:changeBgAni("minor_trigger")
        end

        countBar:runCsbAction("actionframe",true)
        --人物spine播触发
        countBar:runTriggerAni()
        local startNode = countBar:findChild("Node_spine")
        local startPos = util_convertToNodeSpace(startNode,self.m_effectNode2)
        self.m_flyNode:setPosition(startPos)

        callBack(countBar)
    end
    
end

--[[
    添加wild光效飞向下个点位
]]
function CodeGameScreenSuperstarQuestMachine:flyAddWildAniToNextPos(endPos,centerPos,keyFunc,endFunc)
    if self.m_isSkip then
        return
    end
    self.m_flyNode:runCsbAction("start2",false)

    --先移动到中心点在移动到下个点位
    local actionList = {
        cc.MoveTo:create(28 / 60,endPos),
        cc.CallFunc:create(function()
            if self.m_isSkip then
                return
            end

            if type(keyFunc) == "function" then
                keyFunc()
            end
        end),
        cc.EaseQuadraticActionIn:create(cc.MoveTo:create(20 / 60,centerPos)),
        cc.CallFunc:create(function()
            if self.m_isSkip then
                return
            end
            if type(endFunc) == "function" then
                endFunc()
            end
        end),

    }

    self.m_flyNode:runAction(cc.Sequence:create(actionList))
end

--[[
    洒落下一个wild
]]
function CodeGameScreenSuperstarQuestMachine:addNextWildAni(collectBar,centerPos,list,index,wildIndex,func)
    if self.m_isSkip then
        return
    end
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end

    

    local data = list[index]
    local posIndex = data[1]
    local multi = data[2]
    local posData = self:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX

    local sp_reel = self:findChild("sp_reel_"..(iCol - 1))
    local reelPos = util_convertToNodeSpace(sp_reel,self.m_effectNode2)
    
    local position = cc.p(reelPos.x + self.m_SlotNodeW / 2,reelPos.y + self.m_SlotNodeH * (iRow - 0.5))

    local lockWild = self.m_lockWildList[tostring(posIndex)]
    if not lockWild then
        lockWild = util_spineCreate("Socre_SuperstarQuest_Wild",true,true)
        lockWild:setSkin("skin"..wildIndex)
        self.m_effectNode2:addChild(lockWild,posIndex)
        lockWild:setVisible(false)
        lockWild:setPosition(position)

        self.m_lockWildList[tostring(posIndex)] = lockWild
        lockWild.wildIndex = wildIndex
    end

    lockWild.m_multi = multi
    local soundIndex = math.ceil(index / 2)
    if soundIndex > 5 then
        soundIndex = 5
    end

    local jpType = "normal"
    if wildIndex == 2 then
        jpType = "minor"
    elseif wildIndex == 3 then
        jpType = "major"
    elseif wildIndex == 4 then
        jpType = "mega"
    end

    if index == 7 then
        if wildIndex == 2 then
            jpType = "minor"
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_minor_"..(self.m_free_sound_index % 2 + 1)])
        elseif wildIndex == 3 then
            jpType = "major"
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_major_"..(self.m_free_sound_index % 2 + 1)])
        elseif wildIndex == 4 then
            jpType = "mega"
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_mega_"..(self.m_free_sound_index % 2 + 1)])
        end
        self.m_free_sound_index  = self.m_free_sound_index + 1
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_add_wild_"..soundIndex])
    self:flyAddWildAniToNextPos(position,centerPos,function()
        if self.m_isSkip then
            return
        end
        if not tolua.isnull(lockWild) then
            lockWild:setVisible(true)
        end
        
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local curCount = self:getCurWildNum(jpType) + #list
            if self.m_runSpinResultData.p_freeSpinsLeftCount <= 0 then
                curCount =  #list
            end
            collectBar:updateCount(curCount - index)
        else
            collectBar:updateCount(#list - index)
        end
        
        self:runReelShakeAni()
        if multi == 1 then
            util_spinePlay(lockWild,"start")
        elseif multi >= 2 and multi <= 3 then
            util_spinePlay(lockWild,"start2")
        else
            util_spinePlay(lockWild,"start3_"..wildIndex)
        end

        if multi > 1 then
            local csbNode1 = lockWild.m_csbNode1
            local csbNode2 = lockWild.m_csbNode2
            if not csbNode1 then
                csbNode1 = util_createAnimation("Socre_SuperstarQuest_Wild_chengbei.csb")
                util_spinePushBindNode(lockWild,"chengbei",csbNode1)
                lockWild.m_csbNode1 = csbNode1

                csbNode2 = util_createAnimation("Socre_SuperstarQuest_Wild_chengbei.csb")
                util_spinePushBindNode(lockWild,"chengbei2",csbNode2)
                lockWild.m_csbNode2 = csbNode2
            end
            for iMulti = 2,5 do
                csbNode1:findChild("sp_x"..iMulti):setVisible(iMulti == multi)
                csbNode2:findChild("sp_x"..iMulti):setVisible(iMulti == multi)
            end
        end
    end,function()
        if self.m_isSkip then
            return
        end
        self:addNextWildAni(collectBar,centerPos,list,index + 1,wildIndex,func)
    end)
end

function CodeGameScreenSuperstarQuestMachine:refreshAllWild(list)

    for index = 1,#list do
        local data = list[index]
        local posIndex = data[1]
        local multi = data[2]
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX

        local wildIndex = 1
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local freeKind = fsExtraData.freekind
        if fsExtraData and freeKind then
            wildIndex  = wildIndex + freeKind
        end

        local sp_reel = self:findChild("sp_reel_"..(iCol - 1))
        local reelPos = util_convertToNodeSpace(sp_reel,self.m_effectNode2)
        
        local position = cc.p(reelPos.x + self.m_SlotNodeW / 2,reelPos.y + self.m_SlotNodeH * (iRow - 0.5))

        local lockWild = self.m_lockWildList[tostring(posIndex)]
        if not lockWild then
            lockWild = util_spineCreate("Socre_SuperstarQuest_Wild",true,true)
            lockWild:setSkin("skin"..wildIndex)
            self.m_effectNode2:addChild(lockWild,posIndex)
            lockWild:setPosition(position)

            self.m_lockWildList[tostring(posIndex)] = lockWild
            lockWild.wildIndex = wildIndex
        end

        lockWild.m_multi = multi

        local jpType = "normal"
        if wildIndex == 2 then
            jpType = "minor"
        elseif wildIndex == 3 then
            jpType = "major"
        elseif wildIndex == 4 then
            jpType = "mega"
        end

        util_spinePlay(lockWild,"idleframe2",true)

        local curCount = self:getCurWildNum(jpType)
        self:updateWildCountByJpType(jpType,curCount)

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_freeSpinsLeftCount <= 0 then
                self:updateWildCountByJpType(jpType,0)
            end
        end

        if multi > 1 then
            local csbNode1 = lockWild.m_csbNode1
            local csbNode2 = lockWild.m_csbNode2
            if not csbNode1 then
                csbNode1 = util_createAnimation("Socre_SuperstarQuest_Wild_chengbei.csb")
                util_spinePushBindNode(lockWild,"chengbei",csbNode1)
                lockWild.m_csbNode1 = csbNode1
    
                csbNode2 = util_createAnimation("Socre_SuperstarQuest_Wild_chengbei.csb")
                util_spinePushBindNode(lockWild,"chengbei2",csbNode2)
                lockWild.m_csbNode2 = csbNode2
            end
            for iMulti = 2,5 do
                csbNode1:findChild("sp_x"..iMulti):setVisible(iMulti == multi)
                csbNode2:findChild("sp_x"..iMulti):setVisible(iMulti == multi)
            end
        end
    end

    
end

--[[
    轮盘震动
]]
function CodeGameScreenSuperstarQuestMachine:runReelShakeAni()
    local actionList = {
        cc.MoveTo:create(2 / 60,cc.p(5,5)),
        cc.MoveTo:create(2 / 60,cc.p(-3,-3)),
        cc.MoveTo:create(2 / 60,cc.p(3,3)),
        cc.MoveTo:create(2 / 60,cc.p(-2,-2)),
        cc.MoveTo:create(2 / 60,cc.p(2,2)),
        cc.MoveTo:create(2 / 60,cc.p(-2,-2)),
        cc.MoveTo:create(2 / 60,cc.p(2,2)),
        cc.MoveTo:create(2 / 60,cc.p(0,0)),
    }
    local shakeNode = self:findChild("root1")
    shakeNode:stopAllActions()
    shakeNode:runAction(cc.Sequence:create(actionList))
end

--[[
    清理所有固定的wild
]]
function CodeGameScreenSuperstarQuestMachine:clearAllLockWild()
    for key,lockWild in pairs(self.m_lockWildList) do
        lockWild:removeFromParent()
    end
    self.m_lockWildList = {}
end

--[[
    收集wild动画
]]
function CodeGameScreenSuperstarQuestMachine:collectWildAni(func)    

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_collect_wild"])
    self:delayCallBack(36 / 60 + 5 / 30,function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_collect_wild_feed_back"])
    end)
    self:collectNextLevelWild(self.SYMBOL_WILD_1,function()
        if self:checkTriggerFree() then
            self:delayCallBack(36 / 60 + 5 / 30,func)
        else
            if type(func) == "function" then
                func()
            end
        end
        
    end)
    
end

--[[
    收集下个等级的wild
]]
function CodeGameScreenSuperstarQuestMachine:collectNextLevelWild(symbolType,func)
    if symbolType > self.SYMBOL_WILD_4 then
        if type(func) == "function" then
            func()
        end
        return
    end
    if not self.m_spcial_symbol_list[tostring(symbolType)] or symbolType == self.SYMBOL_WILD_1 then
        self:collectNextLevelWild(symbolType + 1,func)
        return
    end

    local wildSymbollist = self.m_spcial_symbol_list[tostring(symbolType)]

    local delayTime = 0
    local feedBackList = {}
    for index = 1,#wildSymbollist do
        local flyTime = self:flyWildToCollectBar(wildSymbollist[index],symbolType)
        if not feedBackList[tostring(symbolType)] then
            feedBackList[tostring(symbolType)] = true
        end

        if flyTime > delayTime then
            delayTime = flyTime
        end
    end

    local jpType = JACKPOT_TYPE[symbolType - self.SYMBOL_WILD_1 + 1]
    local jpCount = self:getCurWildNum(jpType)

    performWithDelay(self.m_effectNode2,function()
        for key,endNode in pairs(feedBackList) do
            local symbolType = tonumber(key)
            if symbolType == self.SYMBOL_WILD_2 then
                self.m_base_minor:collectFeedBackAni()
            elseif symbolType == self.SYMBOL_WILD_3 then
                self.m_base_major:collectFeedBackAni()
            elseif symbolType == self.SYMBOL_WILD_4 then
                self.m_base_mega:collectFeedBackAni()
            end
        end
        

        self:updateWildCountByJpType(jpType,jpCount)
    end,delayTime)
    
    self:collectNextLevelWild(symbolType + 1,func)
end

--[[
    停止wild飞行
]]
function CodeGameScreenSuperstarQuestMachine:stopFlyNode()
    self.m_effectNode2:stopAllActions()
    for index = 1,#self.m_flyNodeActionList do
        local flyNode = self.m_flyNodeActionList[index]
        flyNode:stopAllActions()
        self:pushCollectFlyNode(flyNode)
    end
    
    self.m_flyNodeActionList = {}
end

--[[
    wild飞行动画
]]
function CodeGameScreenSuperstarQuestMachine:flyWildToCollectBar(symbolNode,symbolType,func)
    if tolua.isnull(symbolNode) then
        if type(func) == "function" then
            func()
        end
        return
    end
    local startPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
    local endNode = nil
    
    

    local wildIndex = 1
    if symbolType == self.SYMBOL_WILD_2 then
        wildIndex = 2
        endNode = self.m_base_minor:findChild("Node_fankui")
    elseif symbolType == self.SYMBOL_WILD_3 then
        wildIndex = 3
        endNode = self.m_base_major:findChild("Node_fankui")
    elseif symbolType == self.SYMBOL_WILD_4 then
        wildIndex = 4
        endNode = self.m_base_mega:findChild("Node_fankui")
    end

    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local zOrder = symbolNode:getLocalZOrder()
    symbolNode:setLocalZOrder(zOrder + 10000)
    symbolNode:runMixAni("shouji",false,function()
        if not tolua.isnull(symbolNode) then
            symbolNode:setLocalZOrder(zOrder)
            symbolNode:runAnim("idleframe")
        end
    end)

    performWithDelay(self.m_effectNode2,function()
        for iCount = 1,4 do
            local flyNode = self:getCollectFlyNode()
            flyNode:setLocalZOrder(100 - iCount)
            flyNode:setVisible(false)
            flyNode:setPosition(startPos)
            for index = 1,4 do
                flyNode:findChild("Node_"..index):setVisible(iCount == index)
                flyNode:findChild("Node_lizi"..iCount.."_"..index):setVisible(wildIndex == index)
            end
            self.m_flyNodeActionList[#self.m_flyNodeActionList + 1] = flyNode
    
            local actionList = {
                cc.DelayTime:create((3 / 60) * (iCount - 1)),
                cc.CallFunc:create(function()
                    if not tolua.isnull(flyNode) then
                        flyNode:setVisible(true)
                    end
                end),
                cc.BezierTo:create(36 / 60,{startPos, cc.p((startPos.x + endPos.x) / 2,math.max(startPos.y,endPos.y) + 200), endPos}),
                
                cc.CallFunc:create(function()
                    if not tolua.isnull(flyNode) then
                        for index = 1,#self.m_flyNodeActionList do
                            if self.m_flyNodeActionList[index] == flyNode then
                                table.remove(self.m_flyNodeActionList,index)
                            end
                        end
                        
                        self:pushCollectFlyNode(flyNode)
                        
                    end
                end),
            }
    
            flyNode:runAction(cc.Sequence:create(actionList))
            flyNode:runCsbAction("fly")
            
        end
    end,5 / 30)
    return 36 / 60 + 5 / 30
end

--[[
    初始化飞行节点列表
]]
function CodeGameScreenSuperstarQuestMachine:initCollectFlyNodeList()

end

--[[
    收集wild飞行节点
]]
function CodeGameScreenSuperstarQuestMachine:getCollectFlyNode()

    local flyNode = util_createAnimation("Socre_SuperstarQuest_Wild_shouji.csb")
    self.m_effectNode:addChild(flyNode)
    
    return flyNode
end

function CodeGameScreenSuperstarQuestMachine:pushCollectFlyNode(flyNode)
    -- flyNode:stopAllActions()
    -- self.m_flyWildNodeList[#self.m_flyWildNodeList + 1] = flyNode
    -- for index = 1,4 do
    --     flyNode:findChild("Node_"..index):setVisible(true)
    --     for iCount = 1,4 do
    --         flyNode:findChild("Node_lizi"..iCount.."_"..index):setVisible(true)
    --     end
        
    -- end
    -- flyNode:setVisible(false)
    flyNode:removeFromParent()
end

function CodeGameScreenSuperstarQuestMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenSuperstarQuestMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenSuperstarQuestMachine:playScatterTipMusicEffect()
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_scatter_trigger"])
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenSuperstarQuestMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end


function CodeGameScreenSuperstarQuestMachine:checkRemoveBigMegaEffect()
    CodeGameScreenSuperstarQuestMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenSuperstarQuestMachine:getShowLineWaitTime()
    local time = CodeGameScreenSuperstarQuestMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenSuperstarQuestMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeSuperstarQuestSrc.SuperstarQuestFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    local parentNode = self:findChild("free_cishubar")
    parentNode:addChild(self.m_baseFreeSpinBar) --修改成自己的节点  
    parentNode:setLocalZOrder(500)  
end

function CodeGameScreenSuperstarQuestMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenSuperstarQuestMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

function CodeGameScreenSuperstarQuestMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("SuperstarQuestSounds/music_SuperstarQuest_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local view = self:showFreeSpinStart(function()
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()       
        end)
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

--[[
    显示free相关UI
]]
function CodeGameScreenSuperstarQuestMachine:showFreeUI()
    self:showFreeSpinBar()
    self:findChild("JackpotBar_Base"):setVisible(false)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local freeKind = fsExtraData.freekind

    if freeKind == 1 then
        self:changeBgAni("minor")
    elseif freeKind == 2 then
        self:changeBgAni("major")
    else
        self:changeBgAni("mega")
    end
 
    local node_base_minor = self:findChild("node_base_minor")
    local node_base_major = self:findChild("node_base_major")
    local node_base_mega = self:findChild("node_base_mega")

    node_base_minor:setLocalZOrder(40)
    node_base_major:setLocalZOrder(30)
    node_base_mega:setLocalZOrder(20)

    self.m_base_minor:clearDarkAni()
    self.m_base_major:clearDarkAni()
    self.m_base_mega:clearDarkAni()
    
    
    self.m_free_minor:setVisible(freeKind == 1)
    self.m_free_major:setVisible(freeKind == 2)
    self.m_free_mega:setVisible(freeKind == 3)
    if freeKind == 1 then
        self.m_free_minor:runIdleAni()
    elseif freeKind == 2 then
        self.m_free_major:runIdleAni()
    else
        self.m_free_mega:runIdleAni()
    end

    self:findChild("guang_base"):setVisible(false)
    self:findChild("guang_minor"):setVisible(freeKind == 1)
    self:findChild("guang_major"):setVisible(freeKind == 2)
    self:findChild("guang_mega"):setVisible(freeKind == 3)

    self:findChild("base_reel"):setVisible(false)
    self:findChild("free_reel_minor"):setVisible(freeKind == 1)
    self:findChild("free_reel_major"):setVisible(freeKind == 2)
    self:findChild("free_reel_mega"):setVisible(freeKind == 3)
end

--[[
    隐藏free相关UI
]]
function CodeGameScreenSuperstarQuestMachine:hideFreeUI()
    self:hideFreeSpinBar()

    self:findChild("JackpotBar_Base"):setVisible(true)
    
    self.m_free_minor:setVisible(false)
    self.m_free_major:setVisible(false)
    self.m_free_mega:setVisible(false)

    self:updateWildNum()

    self:findChild("guang_base"):setVisible(true)
    self:findChild("guang_minor"):setVisible(false)
    self:findChild("guang_major"):setVisible(false)
    self:findChild("guang_mega"):setVisible(false)

    self:findChild("base_reel"):setVisible(true)
    self:findChild("free_reel_minor"):setVisible(false)
    self:findChild("free_reel_major"):setVisible(false)
    self:findChild("free_reel_mega"):setVisible(false)

    self:changeBgAni("base")
end

--[[
    free开始弹板
]]
function CodeGameScreenSuperstarQuestMachine:showFreeSpinStart(func)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local freeKind = fsExtraData.freekind
    local view = util_createView("CodeSuperstarQuestSrc.SuperstarQuestFreeStartView",{
        freeCount = self.m_iFreeSpinTimes,
        machine = self,
        freeKind = freeKind,
        keyFunc = function(  )
            self:showFreeUI()
        end,
        endFunc = function()
            if type(func) == "function" then
                func()
            end
        end
    })


    --fs背景音乐
    if freeKind == 1 then
        self:setFsBackGroundMusic("SuperstarQuestSounds/music_SuperstarQuest_free_minor.mp3")
    elseif freeKind == 2 then
        self:setFsBackGroundMusic("SuperstarQuestSounds/music_SuperstarQuest_free_major.mp3")
    else
        self:setFsBackGroundMusic("SuperstarQuestSounds/music_SuperstarQuest_free_mega.mp3")
    end
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_show_fs_start"])

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenSuperstarQuestMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("SuperstarQuestSounds/music_SuperstarQuest_over_fs.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            
            self:triggerFreeSpinOverCallFun()
        end
    )

    view:findChild("root"):setScale(self.m_machineRootScale)

    self:delayCallBack(0.5,function()
        self:hideFreeUI()
    end)

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SuperstarQuest_btn_click)
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        local freeKind = fsExtraData.freekind

        if freeKind == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_hide_fs_mega_win"])
        elseif freeKind == 2 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_hide_fs_major_win"])
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_hide_fs_minor_win"])
        end
    end)

    

end

function CodeGameScreenSuperstarQuestMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}

    if globalData.slotRunData.lastWinCoin == 0 then
        local view = self:showDialog("FeatureOver", ownerlist, func)
        
        return view
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.1,sy=1.1},570)    

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        local freeKind = fsExtraData.freekind
        view:findChild("mega"):setVisible(freeKind == 3)
        view:findChild("major"):setVisible(freeKind == 2)
        view:findChild("minor"):setVisible(freeKind == 1)

        

        local ani = util_createAnimation("SuperstarQuest_FreeSpinOver_glow.csb")
        view:findChild("Node_glow"):addChild(ani)
        ani:runCsbAction("idle",true)

        ani:findChild("glow1"):setVisible(freeKind == 3)
        ani:findChild("glow2"):setVisible(freeKind == 2)
        ani:findChild("glow3"):setVisible(freeKind == 1)

        if freeKind == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_show_fs_mega_win"])
            local spine = util_spineCreate("SuperstarQuest_juese_1",true,true)
            view:findChild("Node_mega"):addChild(spine)
            util_spinePlay(spine,"tanban_idle",true)
        elseif freeKind == 2 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_show_fs_major_win"])
            local spine = util_spineCreate("SuperstarQuest_juese_2",true,true)
            view:findChild("Node_major"):addChild(spine)
            util_spinePlay(spine,"tanban_idle",true)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_show_fs_minor_win"])
            local spine = util_spineCreate("SuperstarQuest_juese_3",true,true)
            view:findChild("Node_minor"):addChild(spine)
            util_spinePlay(spine,"tanban_idle",true)
        end

        

        

        return view
    end
    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenSuperstarQuestMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self:clearCurMusicBg()
    
    self:runScatterTriggerAni(function()
        self:showFreeSpinView(effectData)
    end)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

--[[
    scatterc触发动画
]]
function CodeGameScreenSuperstarQuestMachine:runScatterTriggerAni(func)
    self:playScatterTipMusicEffect()

    local scatterCount = 0
    local specialScatterCount = 0
    local reels = self.m_runSpinResultData.p_reels
    for iRow = 1, #reels do
        if reels[iRow] then
            for iCol = 1, #reels[iRow] do
                if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    scatterCount  = scatterCount + 1
                elseif self:isScatterSymbol(reels[iRow][iCol]) then
                    specialScatterCount = specialScatterCount + 1
                end
            end
        end
        
    end

    local delayTime = 0

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local freeKind = fsExtraData.freekind

    if scatterCount >= 2 and specialScatterCount >= 1 then -- scatter触发
        for posIndex = 1,self.m_iReelRowNum * self.m_iReelColumnNum do
            local symbolNode = self:getSymbolByPosIndex(posIndex - 1)
            if not tolua.isnull(symbolNode) and self:isScatterSymbol(symbolNode.p_symbolType) then
                self:changeSymbolToClipParent(symbolNode)
                symbolNode:setLocalZOrder(11000)
                symbolNode:runAnim("actionframe",false,function()
                    symbolNode:runAnim("idleframe2",true)
                end)
                local aniTime = symbolNode:getAniamDurationByName("actionframe")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end
        end
    else --收集上限触发

        
    end

    local node_base_minor = self:findChild("node_base_minor")
    local node_base_major = self:findChild("node_base_major")
    local node_base_mega = self:findChild("node_base_mega")

    local countBar = self.m_base_minor
    if freeKind == 2 then
        countBar = self.m_base_major
        node_base_major:setLocalZOrder(100)
    elseif freeKind == 3 then
        countBar = self.m_base_mega
        node_base_mega:setLocalZOrder(100)
    else
        node_base_minor:setLocalZOrder(100)
    end

    local node_base = self:findChild("JackpotBar_Base")
    node_base:setLocalZOrder(10000)



    local aniTime = countBar:runTriggerAni()
    if aniTime > delayTime then
        delayTime = aniTime
    end

    self:delayCallBack(delayTime,func)
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenSuperstarQuestMachine:showFeatureGameTip(_func)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.wildnum then
        self.m_wildNumList = selfData.wildnum
    end
    if selfData and selfData.basetr_pos and #selfData.basetr_pos > 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then

        self.m_isAddWild = true

        

        self.m_addWildCallFunc = function()
            self.m_addWildCallFunc = nil
            self:setSkipBtnShow(false)
            self.m_isAddWild = false
            
            -- self:hideBlackLayer( )
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData
            local freeKind = fsExtraData.freekind
            if freeKind == 1 then
                self:changeBgAni("minor")
            elseif freeKind == 2 then
                self:changeBgAni("major")
            else
                self:changeBgAni("mega")
            end
            
            if type(_func) == "function" then
                _func()
            end
        end


        self:addWildToReelAni(function()
            if self.m_isSkip then
                return
            end
            if type(self.m_addWildCallFunc) == "function" then
                self.m_addWildCallFunc()
            end
        end)
    elseif self:getFeatureGameTipChance(40) then

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
function CodeGameScreenSuperstarQuestMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 0
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_notice_win"])

    --获取父节点
    local parentNode = self:findChild("Node_yugao")

    self.b_gameTipFlag = true
    --创建对应格式的spine
    local spineAni = util_spineCreate("SuperstarQuest_yugao_2",true,true)
    if parentNode and not tolua.isnull(spineAni) then
        parentNode:addChild(spineAni)
        util_spinePlayAndRemove(spineAni,"actionframe_yugao")
    end

    self:changeBgAni("featureTip")
    
    local aniTime = spineAni:getAnimationDurationTime("actionframe_yugao")

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

function CodeGameScreenSuperstarQuestMachine:setReelRunInfo()
    self.m_longRunControl:checkTriggerLongRun()   
end

--[[
    检测播放落地动画
]]
function CodeGameScreenSuperstarQuestMachine:checkPlayBulingAni(colIndex)
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

                --获取拖尾
                local tail
                if self:isWildSymbol(symbolNode.p_symbolType) and symbolNode.p_symbolType ~= self.SYMBOL_WILD_1 then
                    local reelNode = self.m_baseReelNodes[colIndex]
                    tail = reelNode:getTailByRowIndex(iRow)
                end
                
                --提层
                if symbolCfg[1] then
                    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
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

                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    --2.播落地动画
                    symbolNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(symbolNode)
                        end
                    )
                    if not tolua.isnull(tail) then
                        util_spinePlayAndRemove(tail,"buling")
                    end
                    --bonus落地音效
                    if self:isWildSymbol(symbolNode.p_symbolType) then
                        self:checkPlayBonusDownSound(colIndex)
                    end
                    --scatter落地音效
                    if self:isScatterSymbol(symbolNode.p_symbolType) then
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
function CodeGameScreenSuperstarQuestMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SuperstarQuest_wild_down)
end

--[[
    播放scatter落地音效
]]
function CodeGameScreenSuperstarQuestMachine:playScatterDownSound(colIndex)
    if colIndex < self.m_iReelColumnNum then
        local scatterList = self.m_spcial_symbol_list["90"] or {}
        local scatterCount = #scatterList
        if scatterCount >= 3 then
            scatterCount = 3
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_scatter_down_"..scatterCount])
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_jp_scatter_down"])
    end
end

function CodeGameScreenSuperstarQuestMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenSuperstarQuestMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_big_win_light"])
    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local spine = util_spineCreate("SuperstarQuest_bigwin",true,true)
    rootNode:addChild(spine)
    spine:setPosition(pos)
    local aniTime = util_spinePlayAndRemove(spine,"actionframe_bigwin")

    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenSuperstarQuestMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if self:isScatterSymbol(_slotNode.p_symbolType) then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
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

function CodeGameScreenSuperstarQuestMachine:isPlayTipAnima(colIndex, rowIndex, symbolNode)
    if colIndex < 4 then
        return true
    end
    local reels = self.m_runSpinResultData.p_reels
    local symbolType = symbolNode.p_symbolType
    local symbolCount = 0
    --获取小块数量
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1,colIndex - 1 do
            if self:isScatterSymbol(reels[iRow][iCol]) then
                symbolCount  = symbolCount + 1
            end
        end
    end

    if symbolCount >= 2 then
        return true
    elseif colIndex == 4 and symbolCount >= 1 then
        return true
    end
    return false
end

--[[
    检测是否触发free
]]
function CodeGameScreenSuperstarQuestMachine:checkTriggerFree()
    local features = self.m_runSpinResultData.p_features
    if features then
        for index = 1,#features do
            if features[index] == SLOTO_FEATURE.FEATURE_FREESPIN then
                return true
            end
        end
    end

    return false
end

function CodeGameScreenSuperstarQuestMachine:initMachineBg()
    local gameBg = util_spineCreate("SuperstarQuest_bg",true,true)
    local bgNode = self:findChild("bg")
    
    bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)

    self.m_gameBg = gameBg
end

--切换背景动画
function CodeGameScreenSuperstarQuestMachine:changeBgAni(bgType)
    if bgType == "base" then
        util_spinePlay(self.m_gameBg,"idleframe_base",true)
    elseif bgType == "base_trigger" then
        util_spinePlay(self.m_gameBg,"actionframe_base",true)
    elseif bgType == "minor" then
        util_spinePlay(self.m_gameBg,"idleframe_juese3",true)
    elseif bgType == "major" then
        util_spinePlay(self.m_gameBg,"idleframe_juese2",true)
    elseif bgType == "mega" then
        util_spinePlay(self.m_gameBg,"idleframe_juese1",true)
    elseif bgType == "minor_trigger" then
        util_spinePlay(self.m_gameBg,"actionframe_juese3",true)
    elseif bgType == "major_trigger" then
        util_spinePlay(self.m_gameBg,"actionframe_juese2",true)
    elseif bgType == "mega_trigger" then
        util_spinePlay(self.m_gameBg,"actionframe_juese1",true)
    elseif bgType == "featureTip" then
        util_spinePlay(self.m_gameBg,"actionframe_yugao")
        util_spineEndCallFunc(self.m_gameBg,"actionframe_yugao",function()
            self:changeBgAni('base')
        end)
    end
end

function CodeGameScreenSuperstarQuestMachine:scaleMainLayer()
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
        mainScale = 0.6
        mainPosY  = mainPosY + 35

    elseif ratio >=  920 / 768 and ratio < 1152 / 768 then --920
        mainScale = 0.6
        mainPosY  = mainPosY + 35

    elseif ratio >= 1152 / 768 and ratio < 1228 / 768 then --1152
        mainScale = 0.81
        mainPosY  = mainPosY + 25
    elseif ratio >= 1228 / 768 and ratio < 1368 / 768 then --1228
        mainScale = 0.87
        mainPosY  = mainPosY + 20
    else --1370以上
        mainScale = 1
        mainPosY  = mainPosY + 15
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

function CodeGameScreenSuperstarQuestMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_clipParent:addChild(reelEffectNode,-1)
    reelEffectNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + 50)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function CodeGameScreenSuperstarQuestMachine:setLongAnimaInfo(reelEffectNode, col)
    local worldPos, reelHeight, reelWidth = self:getReelPos(col)

    local pos = self.m_clipParent:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    reelEffectNode:setPosition(cc.p(pos.x, pos.y))
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenSuperstarQuestMachine:checkUpdateReelDatas(parentData,isBaseGame)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    if isBaseGame then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(1, parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--[[
    设置跳过按钮是否显示
]]
function CodeGameScreenSuperstarQuestMachine:setSkipBtnShow(isShow)
    self.m_skipBtn:setVisible(isShow)
    self.m_bottomUI.m_spinBtn:setVisible(not isShow)
end

--[[
    跳过回调
]]
function CodeGameScreenSuperstarQuestMachine:skipFunc()
    if not self.m_isAddWild then
        return
    end
    
    self.m_isSkip = true
    self.m_flyNode:setVisible(false)
    self.m_flyNode:stopAllActions()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.basefinalwild then
        local basefinalwild = selfData.basefinalwild
        self:refreshAllWild(basefinalwild)
    end

    if type(self.m_addWildCallFunc) == "function" then
        self.m_addWildCallFunc()
    end
end

return CodeGameScreenSuperstarQuestMachine






