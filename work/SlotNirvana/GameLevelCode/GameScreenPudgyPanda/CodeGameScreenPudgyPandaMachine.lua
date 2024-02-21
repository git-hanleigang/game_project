---
-- island li
-- 2019年1月26日
-- CodeGameScreenPudgyPandaMachine.lua
-- 
-- 玩法：
--[[
    特殊信号：
        Bonus：94
        移动Bonus：95
        特殊Bonus：101、102
        收集Bonus：96
    条件：
        1.wild：只出现在2/3/4/5列reel
        2.Bonus：会出现在除FG模式外的任何位置
        3.移动Bonus：只出现在Base中，会出现在任何reel，同时出现在棋盘上的移动Bonus数量最多有四个
        4.收集Bonus：只出现在Base下第5列Reel
    收集玩法：
        1.Base下第五列reel会滚出可收集的Bonus图标，每个收集Bonus均会累计收集进度，进度累计到阈值时触发玩法
        2.共有三档不同等级的FG，Free Games：8 free spins，2*2 wild ； Super Free Games：8 free spins，3*3 wild ； Mega Free Games：8 free spins，4*4 wild
        3.玩家可以选择触发低等级的FG，或继续收集以触发高等级的FG，达到MegaFG时当次必触发
        4.玩家随时可选择触发已累计达到的FG玩法，玩法结束后，扣除该节点之前的收集进度
    base:
        1.会出现移动的Bonus图标，移动Bonus会出现在任何一列Reel，滚出前需要让玩家在界面内看到移动Bonus图标
        2.不会同时触发收集玩法和Fat Fortune
    free：
        1.FG玩法中，棋盘为5*5棋盘，特殊wild每次spin时会随机移动
        2.进入free games的bet为Average Bet
        3.特殊wild可能会移动到第一列reel，需要有wild连线分值
    Fat Fortune：
        触发条件：
            Base可触发，停轮后当棋盘上的bonus/移动bonus图标数量≥6个时，触发Fat Fortune玩法
        玩法说明：
            1.Fat Fortune玩法中，棋盘为5*5棋盘，初始棋盘中心会存在1*1的特殊wild
            2.停轮并结算连线后，若滚出Bonus图标，特殊wild图标会移动至Bonus图标位置并收集，每累积5个Bonus图标，特殊wild会升级，且剩余spin次数+1
            3.会滚出带有低等级Jackpot奖励（minor、mini）的特殊Bonus图标，收集特殊Bonus除进度+1外，还会立刻结算对应的Jackpot奖励
            4.特殊wild最多有五个等级：1*1/2*2/3*3/4*4/5*5
            5.特殊wild可能会移动到第一列reel，需要有wild连线分值
            6.当特殊wild升级到5*5时，会触发转盘玩法，原本的5*5棋盘会变为转盘，转盘spin次数承接Fat Fortune玩法当前剩余spin次数
            7.转盘奖励包含三档彩金（grand、mega、major）以及大额奖金
        结束条件：
            剩余spin次数归零且所有奖励结算完成后，玩法结束
]]
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "PudgyPandaPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenPudgyPandaMachine = class("CodeGameScreenPudgyPandaMachine", BaseNewReelMachine)

CodeGameScreenPudgyPandaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_BONUS = 94 -- 普通bonus
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_MOVE_BONUS = 95 -- 移动bonus
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_COLLECT_BONUS = 96 -- 收集bonus
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_FAT_FEATURE_BONUS = 97 -- fatFeature-bonus（本地定义）
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_BONUS_MINI = 101 -- 特殊bonus(mini)
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_BONUS_MINOR = 102 -- 特殊bonus(minor)

CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_BONUS_MAJOR = 103 -- 特殊bonus(major，本地定义)
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_BONUS_MEGA = 104 -- 特殊bonus(mega，本地定义)
CodeGameScreenPudgyPandaMachine.SYMBOL_SCORE_BONUS_GRAND = 105 -- 特殊bonus(grand，本地定义)


-- 自定义动画的标识
CodeGameScreenPudgyPandaMachine.EFFECT_BASE_COLLECT_TRIGGER_FREE = GameEffect.EFFECT_SELF_EFFECT - 2     -- base下收集触发free玩法
CodeGameScreenPudgyPandaMachine.EFFECT_BASE_COLLECT_BONUS = GameEffect.EFFECT_SELF_EFFECT - 3     -- 收集bonus玩法（只有第五列出）
CodeGameScreenPudgyPandaMachine.EFFECT_FAT_FEATURE_TRIGGET_WHEEL = GameEffect.EFFECT_SELF_EFFECT - 4     -- fatFeature玩法下触发大轮盘玩法
CodeGameScreenPudgyPandaMachine.EFFECT_FAT_FEATURE_COLLECT_BONUS = GameEffect.EFFECT_SELF_EFFECT - 6     -- fatFeature玩法下收集bonus

CodeGameScreenPudgyPandaMachine.m_symbolScale = 0.76 -- 小块需要缩放的尺寸


-- 构造函数
function CodeGameScreenPudgyPandaMachine:ctor()
    CodeGameScreenPudgyPandaMachine.super.ctor(self)

    -- self.m_isOnceClipNode = false
    --大赢光效
    self.m_isAddBigWinLightEffect = true

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    self.ENUM_FREE_TYPE = 
    {
        BASE_FREE = 1,
        SUPER_FREE = 2,
        MEGA_FREE = 3,
        FAT_FORTUNE_FREE = 4,
    }
    -- 当前free的类型base/superFree/megaFree/fatFortuneFree
    self.m_curFreeType = self.ENUM_FREE_TYPE.BASE_FREE

    -- base下收集配置
    self.m_baseCollectConfig = {0, 0, 0}
    -- base下收集的进度
    self.m_baseCurCollectNum = 0

    -- 所有的移动bonus（跳过功能使用）
    self.m_allMoveBonusTbl = {}

    -- free玩法时5行
    self.m_freeTypeRow = 5
    self.m_baseTypeRow = 3

    -- base和free下reel坐标
    self.m_baseReelPos = {cc.p(-394, -199.5), cc.p(-236, -199.5), cc.p(-78, -199.5), cc.p(80, -199.5), cc.p(238, -199.5)}
    self.m_freeReelPos = {cc.p(-391, -367.24), cc.p(-234, -367.24), cc.p(-76.84, -367.24), cc.p(81.34, -367.24), cc.p(238, -367.24)}

    -- free下中间wild信息
    self.m_midWildData = {}

    -- free下wild移动的方向
    -- 0代表不用变化方向
    self.ENUM_WILD_DIRECTION = 
    {
        WILD_MID = 1,
        WILD_LEFT = 2,
        WILD_RIGHT = 3,
    }
    -- 当前wild移动的方向
    self.m_curWildDirection = self.ENUM_WILD_DIRECTION.WILD_RIGHT

    -- 是否初始化了移动bonus（触发free，再进来播触发，没初始化）
    self.m_isInitFixBonus = false
    
    -- 断线标识
    self.m_isDuanXianComeIn = false

    -- 触发fatFeatureBonus音效索引
    self.m_triggerBonusSoundIndex = 1
    -- fatFeatureBonus升级时音效索引
    self.m_bonusEffectSoundIndex = 1
    self.m_winEffectSoundIndex = 1
    -- 刷新jackpotBar倍数
    self.m_refreshJackpotBar = false
    --init
    self:initGame()
end

function CodeGameScreenPudgyPandaMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("PudgyPandaConfig.csv", "LevelPudgyPandaConfig.lua")
    self.m_configData.m_machine = self
    
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPudgyPandaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "PudgyPanda"  
end

function CodeGameScreenPudgyPandaMachine:getBottomUINode()
    return "CodePudgyPandaSrc.PudgyPandaBottomNode"
end

function CodeGameScreenPudgyPandaMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    -- 背景
    self.m_bgType = {}
    self.m_bgType[1] = self.m_gameBg:findChild("Base")
    self.m_bgType[2] = self.m_gameBg:findChild("FG")
    self.m_bgType[3] = self.m_gameBg:findChild("Fortune")

    -- reel条
    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Reel_base")
    self.m_reelBg[2] = self:findChild("Reel_FG")
    self.m_reelBg[3] = self:findChild("Reel_Fortune")
    
    self:initFreeSpinBar() -- FreeSpinbar

    self:initWheelSpinBar() -- wheelSpinbar

    self:initJackPotBarView()

    -- base下收集view
    self.m_collectView = util_createView("CodePudgyPandaCollectSrc.PudgyPandaCollectView", self)
    self:findChild("Node_shouji"):addChild(self.m_collectView)

    -- free选择弹板
    self.m_chooseView = util_createView("CodePudgyPandaSrc.PudgyPandaChooseView", self)
    self:addChild(self.m_chooseView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_chooseView:setVisible(false)
    self.m_chooseView:scaleMainLayer(self.m_machineRootScale)

    -- 地图弹板
    self.m_mapView = util_createView("CodePudgyPandaCollectSrc.PudgyPandaMapView", self)
    self:addChild(self.m_mapView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_mapView:setVisible(false)
    self.m_mapView:scaleMainLayer(self.m_machineRootScale)

    -- free类型说明
    self.m_freeTypeDesView = util_createView("CodePudgyPandaFeatureSrc.PudgyPandaDescribeView")
    self:findChild("Node_FGshuoming"):addChild(self.m_freeTypeDesView)

    -- fatFeature玩法下的笼屉
    self.m_fatFeatureBasketView = util_createView("CodePudgyPandaFeatureSrc.PudgyPandaBasketView")
    self:findChild("Node_longti"):addChild(self.m_fatFeatureBasketView)

    -- fatFeature下遮罩
    self.m_maskAni = util_createAnimation("PudgyPanda_qipan_yaan.csb")
    self.m_maskAni:setVisible(false)
    self.m_clipParent:addChild(self.m_maskAni, 1000)

    self.m_maskNodeTab = {}
    for col = 1,self.m_iReelColumnNum do
        --添加半透明遮罩
        local parentData = self.m_slotParents[col]
        local mask = cc.LayerColor:create(cc.c3b(0, 0, 0), parentData.reelWidth - 1 , parentData.reelHeight)
        mask:setOpacity(155)
        mask.p_IsMask = true--不被底层移除的标记
        mask:setPositionX(parentData.reelWidth/2)
        parentData.slotParent:addChild(mask, REEL_SYMBOL_ORDER.REEL_ORDER_1 + 300)
        table.insert(self.m_maskNodeTab, mask)
        mask:setVisible(false)
    end

    self.m_moveEffectNode = self:findChild("Node_moveBonus")
    self.m_topEffectNode = self:findChild("Node_topEffect")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    -- 快停移动bonus跳过功能专用node
    self.m_scBonusWaitNode = cc.Node:create()
    self:addChild(self.m_scBonusWaitNode)

    self.m_timeWaitNode = cc.Node:create()
    self:addChild(self.m_timeWaitNode)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenPudgyPandaMachine:initSpineUI()
    -- fatFeature预告中奖
    self.m_yuGaoFatSpine = util_spineCreate("PudgyPanda_yugao",true,true)
    self:findChild("Node_yuGao"):addChild(self.m_yuGaoFatSpine)
    self.m_yuGaoFatSpine:setVisible(false)

    -- 收集预告中奖
    self.m_yuGaoCollectSpine = util_spineCreate("PudgyPanda_xm",true,true)
    self:findChild("Node_yuGao"):addChild(self.m_yuGaoCollectSpine)
    self.m_yuGaoCollectSpine:setVisible(false)

    --大赢下边
    self.m_bigWinSpine = util_spineCreate("PudgyPanda_bigwin",true,true)
    self:findChild("Node_BigWin"):addChild(self.m_bigWinSpine)
    self.m_bigWinSpine:setVisible(false)

    -- base-free过场
    self.m_baseToFreeSpine = util_spineCreate("PudgyPanda_guochang",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_baseToFreeSpine)
    self.m_baseToFreeSpine:setVisible(false)

    -- free-base过场
    self.m_freeToBaseSpine = util_spineCreate("PudgyPanda_guochang2",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_freeToBaseSpine)
    self.m_freeToBaseSpine:setVisible(false)

    -- base-fatFeature-free过场
    self.m_baseToFatFeatureSpine = util_spineCreate("PudgyPanda_guochang3",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_baseToFatFeatureSpine)
    self.m_baseToFatFeatureSpine:setVisible(false)

    -- fatFeature弹板动画
    self.m_freeFatFeatureSpine = util_spineCreate("PudgyPanda_xm",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_freeFatFeatureSpine, 10)
    self.m_freeFatFeatureSpine:setVisible(false)

    -- 轮盘玩法，后边的角色
    self.m_wheelRoleSpine = util_spineCreate("PudgyPanda_juese",true,true)
    self:findChild("Node_juese"):addChild(self.m_wheelRoleSpine, 10)
    self.m_wheelRoleSpine:setVisible(false)

    self:changeBgSpine(1)
end

function CodeGameScreenPudgyPandaMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Enter_Game, 3, 0, 1)
    end)
end

function CodeGameScreenPudgyPandaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenPudgyPandaMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self.m_isDuanXianComeIn = true
    self:initGameUI()
end

function CodeGameScreenPudgyPandaMachine:initGameUI()
    self:refreshCollectAndMapProcess()
    if not self.m_isInitFixBonus then
        self:updateFixedBonus()
    end
    self.m_isInitFixBonus = true
    -- 显示free轮盘
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 变轮盘高度
        local freeHeight = self.m_SlotNodeH * self.m_freeTypeRow

        -- self:changeShowRow(true)

        local selfData = self.m_runSpinResultData.p_selfMakeData
        local freeType = selfData.free_type
        -- 1:fatFeature
        if freeType == 1 then
            self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_FatFeature_Bg)--fs背景音乐
            self.m_curFreeType = self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE
        else
            -- free三个等级对应的标识符 2*2为1 3*3为2 4*4为3
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
            local selectType = fsExtraData.select_free_type
            self.m_curFreeType = selectType
            self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_FG_Bg)--fs背景音乐
        end
        self.m_fsReelDataIndex = self.m_curFreeType - 1
        self:showFeatureView()
        self:showStartWild(nil, true)
        self.m_refreshJackpotBar = true
    elseif self:getCurIsBonus(true) then
        self.m_fatFeatureBasketView:showOverAni(true)
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local freeType = selfData.free_type
        -- 1:fatFeature
        if freeType == 1 then
            self.m_curFreeType = self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE
        end
        self:changeBgSpine(4)
        self:setWheelSpinBarState(true)
    end
    -- performWithDelay(self.m_scWaitNode, function()
    --     self:addTest()
    -- end, 1.0)
end

function CodeGameScreenPudgyPandaMachine:addTest()
    local wildStatus = 1
    local wildNewStatus = wildStatus+1
    local wildPos = 6
    
    local wildSpineName = "Socre_PudgyPanda_Wild"..wildNewStatus
    local midWildSpine = util_spineCreate(wildSpineName,true,true)
    local pos = self:getWildMidPos(wildNewStatus, wildPos)
    midWildSpine:setPosition(pos)
    midWildSpine:setScale(1/self.m_symbolScale)
    util_spinePlay(midWildSpine, "idleframe2", true)
    -- 放在连线下边
    self.m_clipParent:addChild(midWildSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)



    local upgradeDirection = 3
    local upgradeName
    if upgradeDirection == 1 then
        upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_d"
    elseif upgradeDirection == 2 then
        upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_b"
    elseif upgradeDirection == 3 then
        upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_a"
    elseif upgradeDirection == 4 then
        upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_c"
    end

    local wildSpineName = "Socre_PudgyPanda_Wild"..wildStatus
    local upgradeWildSpine = util_spineCreate(wildSpineName,true,true)
    local pos = self:getUpgradeWildPos(wildNewStatus, wildPos, upgradeDirection)
    -- pos.x = pos.x - 4.5
    pos.y = pos.y - 30
    upgradeWildSpine:setPosition(pos)
    upgradeWildSpine:setScale(1/self.m_symbolScale)
    util_spinePlay(upgradeWildSpine, upgradeName, false)
    -- 放在连线下边
    self.m_clipParent:addChild(upgradeWildSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 99)
end

function CodeGameScreenPudgyPandaMachine:addObservers()
    CodeGameScreenPudgyPandaMachine.super.addObservers(self)
    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:clearWinLineEffect()
            self:updateFixedBonus()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_PudgyPanda_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_PudgyPanda_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenPudgyPandaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenPudgyPandaMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


function CodeGameScreenPudgyPandaMachine:changeShowRow(_isFree)
    local isFree = _isFree

    self.m_iReelRowNum = self.m_baseTypeRow
    local curHight = self.m_SlotNodeH * self.m_baseTypeRow
    local targetPos = self.m_baseReelPos
    if isFree then
        self.m_iReelRowNum = self.m_freeTypeRow
        curHight = self.m_SlotNodeH * self.m_freeTypeRow
        targetPos = self.m_freeReelPos

        -- 填充数据
        for i = self.m_baseTypeRow + 1, self.m_iReelRowNum, 1 do
            if self.m_stcValidSymbolMatrix[i] == nil then
                self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
            end
        end

        for i = 1, self.m_iReelColumnNum do
            self:changeReelRowNum(i,self.m_iReelRowNum,true)
        end
    end

    self:setReelInfoWithMaxColumn(isFree)

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local clipNode = slotParent:getParent()
        clipNode:setPositionY(targetPos[i].y)

        local slotParentBig = parentData.slotParentBig
        local clipNodeBig = slotParentBig:getParent()
        clipNodeBig:setPositionY(targetPos[i].y)

        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        reel:setPositionY(targetPos[i].y)

        parentData.reelHeight = curHight
        parentData.rowNum = self.m_iReelRowNum
    end

    local x, y = self.m_onceClipNode:getPosition()
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x,
            y = targetPos[1].y,
            width = rect.width,
            height = curHight
        }
    )
    
    -- 取底边  和 上边
    -- local prePosX = -1
    -- local slotW = 0
    -- for i = 1, #self.m_slotParents do
    --     local parentData = self.m_slotParents[1]
    --     parentData.rowNum = self.m_iReelRowNum
    --     local colNodeName = "sp_reel_" .. (i - 1)
    --     local reel = self:findChild(colNodeName)
    --     reel:setPositionY(targetPos[i].y)
    --     local reelSize = reel:getContentSize()

    --     local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
    --     clipNode:setPosition(targetPos[i].x - reelSize.width * 0.5, targetPos[i].y)

    --     local rect = clipNode:getClippingRegion()
    --     clipNode:setClippingRegion(
    --         {
    --             x = rect.x,
    --             y = rect.y,
    --             width = rect.width,
    --             height = curHight
    --         }
    --     )
    -- end

    -- 点击区域位置和大小修改
    local posX, posY = self.m_touchSpinLayer:getPosition()
    self.m_touchSpinLayer:setPosition(self:findChild("sp_reel_0"):getPosition())
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
end

-- 设置列数据
function CodeGameScreenPudgyPandaMachine:setReelInfoWithMaxColumn(_isFree)
    local isFree = _isFree
    local fReelMaxHeight = 0

    local curHight = self.m_SlotNodeH * self.m_baseTypeRow
    local targetPos = self.m_baseReelPos
    if isFree then
        self.m_iReelRowNum = self.m_freeTypeRow
        curHight = self.m_SlotNodeH * self.m_freeTypeRow
        targetPos = self.m_freeReelPos
    end

    local iColNum = self.m_iReelColumnNum
    for iCol = 1, iColNum, 1 do
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))

        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(targetPos[iCol].x, targetPos[iCol].y)
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = curHight

        if curHight > fReelMaxHeight then
            fReelMaxHeight = curHight
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
        -- columnData.p_showGridH = self.m_SlotNodeH
        columnData:updateShowColCount(self.m_iReelRowNum)
        -- columnData.p_showGridCount = math.floor(columnData.p_slotColumnHeight / self.m_SlotNodeH + 0.5) -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPudgyPandaMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_PudgyPanda_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_MOVE_BONUS then
        return "Socre_PudgyPanda_Move_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_COLLECT_BONUS then
        return "Socre_PudgyPanda_Collect_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_FAT_FEATURE_BONUS then
        return "Socre_PudgyPanda_Fat_Bonus"
    elseif self:getCurSymbolTypeIsJackpot(symbolType) then
        return "Socre_PudgyPanda_Jackpot_Bonus"
    elseif self:getCurSymbolTypeIsJackpotByWheel(symbolType) then
        return "Socre_PudgyPanda_Wheel_Bonus"
    end
    
    return nil
end

--假滚时调用的  加上层级
function CodeGameScreenPudgyPandaMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)
    parentData.symbolType = symbolType
    parentData.order = self:getBounsScatterDataZorder(symbolType)
end

---
--设置bonus scatter 层级
function CodeGameScreenPudgyPandaMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenPudgyPandaMachine.super.getBounsScatterDataZorder(self,symbolType)
    if symbolType >= self.SYMBOL_SCORE_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    return order
end

-- 判断是否jackpot信号
function CodeGameScreenPudgyPandaMachine:getCurSymbolTypeIsJackpot(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_BONUS_MINI or _symbolType == self.SYMBOL_SCORE_BONUS_MINOR then
        return true
    end
    return false
end

-- 判断是否为轮盘jackpot信号
function CodeGameScreenPudgyPandaMachine:getCurSymbolTypeIsJackpotByWheel(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_BONUS_MAJOR or _symbolType == self.SYMBOL_SCORE_BONUS_MEGA or _symbolType == self.SYMBOL_SCORE_BONUS_GRAND then
        return true
    end
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPudgyPandaMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenPudgyPandaMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

-- 刷新收集进度和地图进度
function CodeGameScreenPudgyPandaMachine:refreshCollectAndMapProcess()
    -- 初始收集化进度
    self.m_collectView:initProcess(self.m_baseCurCollectNum)
    -- 初始化地图进度
    self.m_mapView:initProcess(self.m_baseCurCollectNum)
end

-- 添加移动bonus数据
function CodeGameScreenPudgyPandaMachine:addMoveBonusData(_moveBonusNode, _bonusIndex)
    local tempTbl = {}
    tempTbl.p_moveBonusNode = _moveBonusNode
    -- 判断是否在轮盘里，在轮盘里加个标记（fatFeature-free触发时使用）
    if _bonusIndex >= 0 and _bonusIndex <= 14 then
        tempTbl.p_isReel = true
        tempTbl.p_pos = _bonusIndex
    end
    table.insert(self.m_allMoveBonusTbl, tempTbl)
end

-- 固定移动bonus
-- 只有base下显示
function CodeGameScreenPudgyPandaMachine:updateFixedBonus(_isFreeOver)
    self.m_moveEffectNode:removeAllChildren()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE or _isFreeOver then
        self:setMoveBonusEndPos()
    end
end

-- 设置移动bonus位置init
function CodeGameScreenPudgyPandaMachine:setMoveBonusEndPos()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    self.m_allMoveBonusTbl = {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local moveBonusData = self:getCurBetMoveBonusData(selfData)
    for k, bonusData in pairs(moveBonusData) do
        local startIndex = bonusData[1]
        local endIndex = bonusData[2]
        local moveBonusNode = self:createPudgyPandaSymbol(self.SYMBOL_SCORE_MOVE_BONUS)
        local bonusEndPos = self:getMoveBonusPos(endIndex)
        moveBonusNode:setPosition(bonusEndPos)
        local zorder = endIndex + 10
        self.m_moveEffectNode:addChild(moveBonusNode, zorder)
        -- 添加移动bonus数据
        self:addMoveBonusData(moveBonusNode, endIndex)
        -- 上方出现
        if startIndex < 0 and startIndex == endIndex then
            moveBonusNode:runAnim("idleframe2_no", true)
        -- 下方消失
        elseif startIndex > 14 and startIndex == endIndex then
            moveBonusNode:setVisible(false)
        -- 中间的移动bonus
        else
            -- 刚从上边到棋盘
            if startIndex < 0 and endIndex >= 0 then
                moveBonusNode:runAnim("idleframe2", true)
            -- 在棋盘中间移动
            elseif startIndex >= 0 and endIndex <= 14 then
                moveBonusNode:runAnim("idleframe2", true)
            -- 出棋盘
            elseif endIndex > 14 then
                moveBonusNode:runAnim("idleframe2_no", true)
            end
        end
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenPudgyPandaMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if selfData.free_type ~= 1 then
            --平均bet值 展示
            self.m_bottomUI:showAverageBet()
        end
    end

    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local bonusState = self.m_runSpinResultData.p_bonusStatus
    if self:getCurIsBonus() then
        self.m_wheelRoleSpine:setVisible(true)
        util_spinePlay(self.m_wheelRoleSpine, "idle", true)
        local endCallFunc = function()
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_bonusWinCoins, GameEffect.EFFECT_BONUS)
            self:playGameEffect() 
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self:showBonusGameView(endCallFunc, true)
    end
end

function CodeGameScreenPudgyPandaMachine:initGameStatusData(gameData)
    local featureData = gameData.feature
    local spinData = gameData.spin
    if featureData and spinData and featureData.bonus and spinData.bonus then
        if spinData.bonus.bsWinCoins and featureData.bonus.bsWinCoins then
            spinData.bonus.bsWinCoins = featureData.bonus.bsWinCoins
        end
        if spinData.bonus.status and featureData.bonus.status then
            spinData.bonus.status = featureData.bonus.status
        end
        if spinData.bonus.extra and featureData.bonus.extra then
            spinData.bonus.extra = featureData.bonus.extra
        end
        if spinData.features and featureData.features then
            spinData.features = featureData.features
        end
    end
    CodeGameScreenPudgyPandaMachine.super.initGameStatusData(self,gameData)
    local gameConfig = gameData.gameConfig
    if gameConfig and gameConfig.extra then
        -- 收集配置
        if gameConfig.extra.collect_config then
            self.m_baseCollectConfig = gameConfig.extra.collect_config
        end

        -- 收集进度
        if gameConfig.extra.collect_num then
            self.m_baseCurCollectNum = gameConfig.extra.collect_num
        end
    end

    -- special
    local specialData = gameData.special
    if specialData then
        local freespinData = specialData.freespin
        local feature = specialData.features
        if feature then
            self.m_runSpinResultData.p_features = feature
            self.m_runSpinResultData.p_fsExtraData = freespinData.extra
            self.m_runSpinResultData.p_freeSpinsLeftCount = freespinData.freeSpinsLeftCount
            self.m_runSpinResultData.p_freeSpinsTotalCount = freespinData.freeSpinsTotalCount
        end
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPudgyPandaMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenPudgyPandaMachine:normalSpinBtnCall()
    if self.m_mapView:isVisible() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        return
    end
    CodeGameScreenPudgyPandaMachine.super.normalSpinBtnCall(self)
end

function CodeGameScreenPudgyPandaMachine:beginReel()
    -- free下开始spin时；把中心点wild变idle
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setMidWildSpineAction()
    else
        self:beginReelShowMask()
    end
    self.m_isDuanXianComeIn = false
    CodeGameScreenPudgyPandaMachine.super.beginReel(self)
end

-- free下开始spin时；把中心点wild变idle
function CodeGameScreenPudgyPandaMachine:setMidWildSpineAction()
    local midWildSpine = self.m_midWildData.p_midWildSpine
    local curPlayActName = self.m_midWildData.p_curPlayActName
    if not tolua.isnull(midWildSpine) and curPlayActName ~= "idleframe2" then
        self.m_midWildData.p_curPlayActName = "idleframe2"
        util_spinePlay(midWildSpine, "idleframe2", true)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenPudgyPandaMachine:slotOneReelDown(reelCol)    
    CodeGameScreenPudgyPandaMachine.super.slotOneReelDown(self,reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenPudgyPandaMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    -- 以防万一（基本不会出现没移动到终点位置，停轮的情况）
    self:runSkipMove()
    CodeGameScreenPudgyPandaMachine.super.slotReelDown(self)
end

---
-- 点击快速停止reel
--
function CodeGameScreenPudgyPandaMachine:newQuickStopReel(colIndex)
    -- 快停移动bonus到终点位置
    self:runSkipMove()
    CodeGameScreenPudgyPandaMachine.super.newQuickStopReel(self, colIndex)
end

---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPudgyPandaMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData

    -- 是否有收集玩法(base下)
    local collectBonusData = selfData.collect_bonus
    
    -- base当前的收集进度
    local baseCurCollectNum = selfData.collect_num
    self.m_baseCurCollectNum = baseCurCollectNum or 0

    -- base收集bonus
    if collectBonusData and next(collectBonusData) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_COLLECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_COLLECT_BONUS -- 动画类型
    end

    -- base下最后触发free事件
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and baseCurCollectNum and table_vIn(self.m_baseCollectConfig, baseCurCollectNum) then
        self.m_baseCurCollectNum = baseCurCollectNum
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 15
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_COLLECT_TRIGGER_FREE -- 动画类型
    end

    -- fatFeature玩法下收集bonus
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local curCollectNum = fsExtraData.collect_num
        if curCollectNum and curCollectNum > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 10
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_FAT_FEATURE_COLLECT_BONUS -- 动画类型
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPudgyPandaMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BASE_COLLECT_BONUS then
        performWithDelay(self.m_scWaitNode, function()
            -- 落地播完再收集
            self:playBaseCollectBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end, 0.0)
    elseif effectData.p_selfEffectType == self.EFFECT_BASE_COLLECT_TRIGGER_FREE then
        local delayTime = 0
        if #self.m_vecGetLineInfo > 0 then
            delayTime = 2
        end
        self:delayCallBack(delayTime, function()
            self:playCollectFreeTrigger(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_FAT_FEATURE_COLLECT_BONUS then
        local delatTime = 0.5
        if #self.m_vecGetLineInfo > 0 then
            delatTime = 1.95
        end
        performWithDelay(self.m_scWaitNode, function()
            self:plyCollectFatFeatureBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end, delatTime)
    end
    
    return true
end

-- base移动bonus
-- 在棋盘中的移动bonus坐标 
-- -5到-1：代表在棋盘上方出现
-- 0-14：代表在棋盘里
-- 15-19：代表在下方，即将要消失
function CodeGameScreenPudgyPandaMachine:playMoveBonus(_callFunc)
    local callFunc = _callFunc
    self.m_moveEffectNode:removeAllChildren()
    self.m_allMoveBonusTbl = {}
    local delayTime = 1.0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local moveBonusData = self:getCurBetMoveBonusData(selfData)
    local isPlaySound = false
    for k, bonusData in pairs(moveBonusData) do
        local endIndex = bonusData[2]
        if endIndex <= 14 then
            isPlaySound = true
            break
        end
    end
    for k, bonusData in pairs(moveBonusData) do
        if isPlaySound then
            self.m_moveBonusSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_MoveBonus_MoveSound)
            isPlaySound = false
        end
        local startIndex = bonusData[1]
        local endIndex = bonusData[2]
        local moveBonusNode = self:createPudgyPandaSymbol(self.SYMBOL_SCORE_MOVE_BONUS)
        local bonusStartPos = self:getMoveBonusPos(startIndex)
        local bonusEndPos = self:getMoveBonusPos(endIndex)
        moveBonusNode:setPosition(bonusStartPos)
        local zorder = endIndex + 10
        self.m_moveEffectNode:addChild(moveBonusNode, zorder)
        self:addMoveBonusData(moveBonusNode, endIndex)
        -- 上方出现
        if startIndex < 0 and startIndex == endIndex then
            moveBonusNode:runAnim("start", false, function()
                moveBonusNode:runAnim("idleframe2_no", true)
            end)
        -- 下方消失
        elseif startIndex > 14 and startIndex == endIndex then
            moveBonusNode:runAnim("over", false, function()
                moveBonusNode:setVisible(false)
            end)
        -- 中间的移动bonus
        else
            -- 刚从上边到棋盘
            if startIndex < 0 and endIndex >= 0 then
                moveBonusNode:runAnim("move_start", false, function()
                    moveBonusNode:runAnim("idleframe2", true)
                end)
            -- 在棋盘中间移动
            elseif startIndex >= 0 and endIndex <= 14 then
                moveBonusNode:runAnim("idleframe2", true)
            -- 出棋盘
            elseif endIndex > 14 then
                moveBonusNode:runAnim("move_over", false, function()
                    moveBonusNode:runAnim("idleframe2_no", true)
                end)
            end
        end

        -- 移动
        local moveToAct = cc.MoveTo:create(delayTime, bonusEndPos)
        moveBonusNode:runAction(moveToAct)
    end

    self:setSkipState(true)
    
    if type(callFunc) == "function" then
        callFunc()
    end
    performWithDelay(self.m_scBonusWaitNode, function()
        self:setSkipState(nil)
    end, delayTime+0.1)
end

-- base收集bonus
function CodeGameScreenPudgyPandaMachine:playBaseCollectBonus(_callFunc)
    local callFunc = _callFunc
    self.m_topEffectNode:removeAllChildren()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collectBonusPos = selfData.collect_bonus[1]
    local curCollectNum = selfData.collect_num

    local tblActionList = {}
    local delayTime = 12/30
    local fixPos = self:getRowAndColByPos(collectBonusPos)
    -- local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
    local flyBonusNode = self:createPudgyPandaSymbol(self.SYMBOL_SCORE_COLLECT_BONUS)
    local startPos = self:getWorldToNodePos(self.m_topEffectNode, collectBonusPos)
    local endPos = util_convertToNodeSpace(self.m_collectView:getCollectBonusNode(), self.m_topEffectNode)
    flyBonusNode:setPosition(startPos)
    self.m_topEffectNode:addChild(flyBonusNode)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_CollectBonus_FeedBack)
        flyBonusNode:runAnim("shouji", false, function()
            flyBonusNode:setVisible(false)
        end)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(0/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if callFunc then
            callFunc()
        end
    end)
    -- 收集动画15帧；5-15帧飞行
    tblActionList[#tblActionList+1] = cc.EaseSineIn:create(cc.MoveTo:create(15/30, endPos))
    -- 涨进度条
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        -- 下边收集动画
        self.m_collectView:playCollectAction()
        -- 收集的进度
        self.m_collectView:setCurProcess(curCollectNum, false)
    end)

    flyBonusNode:runAction(cc.Sequence:create(tblActionList))
end

-- 所有事件完成后再播free触发
function CodeGameScreenPudgyPandaMachine:playCollectFreeTrigger(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isCollect = self:cheakCollectBonus() --看下是否收集 这次spin 不然不弹弹板

    self:clearLineAndFrame()

    -- 当前的收集进度
    local curCollectNum = selfData.collect_num
    local triggerFreeType = 0
    -- free
    if curCollectNum == self.m_baseCollectConfig[1] and isCollect then
        triggerFreeType = 1
    end

    -- super
    if curCollectNum == self.m_baseCollectConfig[2] and isCollect then
        triggerFreeType = 2
    end

    -- mega
    if curCollectNum == self.m_baseCollectConfig[3] and isCollect then
        triggerFreeType = 3
    end

    if triggerFreeType == 0 then
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    -- ① 棋盘上所有奖励结算完成后0.3s
    -- ② 切换为待触发状态后0.3s
    performWithDelay(self.m_scWaitNode, function()
        self.m_collectView:playTriggerAction(triggerFreeType, function()
            if triggerFreeType == 3 then
                if type(callFunc) == "function" then
                    callFunc()
                end
            else
                -- 触发玩法，需要弹板
                self:showChooseView(triggerFreeType, callFunc)
            end
        end)
    end, 0.3)
end

----------------------------- 以下为fatFeature玩法逻辑 ----------------------
-- fatFeature下收集bonus玩法
function CodeGameScreenPudgyPandaMachine:plyCollectFatFeatureBonus(_callFunc)
    --清理连线
    self:clearWinLineEffect()
    local callFunc = _callFunc
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    -- 收集bonus位置信息
    local bonusLocation = clone(fsExtraData.bonus_location)
    -- 最终边长
    local wildEndStatus = fsExtraData.wild_new_status
    -- 最终位置
    local wildNewLocation = fsExtraData.wild_new_location
    
    local parmsData = {m_curIndex = 0, m_fsExtraData = fsExtraData, m_bonusLocation = bonusLocation}

    self:showMask(true)
    performWithDelay(self.m_scWaitNode, function()
        self:playCollectFatFeatureBonusByMovePath(function()
            -- 收集结束更新中心wild信息
            self:refreshMidWildData(nil, wildNewLocation, wildEndStatus)
            self:showMask(false)
            if self:checkHasBigWin() then
                self:delayCallBack(0.4, function()
                    if type(callFunc) == "function" then
                        callFunc()
                    end
                end)
            else
                if type(callFunc) == "function" then
                    callFunc()
                end
            end
        end, parmsData)
    end, 0.3)
end

-- fatFeature根据路径一个一个收集
function CodeGameScreenPudgyPandaMachine:playCollectFatFeatureBonusByMovePath(_callFunc, _parmsData)
    local callFunc = _callFunc
    local curIndex = _parmsData.m_curIndex + 1
    local fsExtraData = _parmsData.m_fsExtraData
    -- 记录当前要收集的数据
    local bonusLocation = _parmsData.m_bonusLocation
    -- 当前步wild旋转的方向
    local curDirection = _parmsData.m_curDirection
    -- 当前收集的个数
    local curCollectNum = _parmsData.m_curCollectNum or 0
    -- 收集的路径
    local movePath = fsExtraData.move_path
    -- 之前的大小
    local wildStatus = fsExtraData.wild_status

    if curIndex > #movePath then
        if self.m_wildMoveSound then
            gLobalSoundManager:stopAudio(self.m_wildMoveSound)
            self.m_wildMoveSound = nil
        end
        -- 收集完成
        performWithDelay(self.m_scWaitNode, function()
            self:playCollectFatFeatureBonusToBasket(callFunc, 0)
        end, 0.3)
        return
    end

    -- 是否为最后一个
    local isLastCollect = curIndex == #movePath and true or false
    -- 当前移动的位置
    local curWildIndex = movePath[curIndex]
    -- 每走一步就要判断当前的位置是否是收集
    local curMovePos = self:getWildMidPos(wildStatus, curWildIndex)

    local spineFirstMoveName, spineFirstMoveIdleName
    local spineMoveName, spineMoveIdleName
    if curIndex == 1 then
        -- 上一次spin-wild位置
        local wildLocation = fsExtraData.wild_location
        curDirection = self:getMoveWildDirection(wildLocation, curWildIndex)
        -- 第一步要有预备动画
        spineFirstMoveName, spineFirstMoveIdleName = self:getWildRotateDierection(curDirection)
        self.m_midWildData.m_curMoveIdle = spineFirstMoveIdleName

        local nextWildIndex = movePath[curIndex+1]
        if nextWildIndex then
            curDirection = self:getMoveWildDirection(curWildIndex, nextWildIndex)
            spineMoveName, spineMoveIdleName = self:getWildRotateDierection(curDirection)
        else
            spineMoveIdleName = spineFirstMoveIdleName
        end
    else
        local nextWildIndex = movePath[curIndex+1]
        if not nextWildIndex then
            nextWildIndex = curWildIndex
        end
        curDirection = self:getMoveWildDirection(curWildIndex, nextWildIndex)
        spineMoveName, spineMoveIdleName = self:getWildRotateDierection(curDirection)
    end

    local parmsData = {m_curIndex = curIndex, m_fsExtraData = fsExtraData, m_bonusLocation = bonusLocation, m_curDirection = curDirection, m_curCollectNum = curCollectNum}
    
    local midWildSpine = self.m_midWildData.p_midWildSpine

    local tblActionList = {}
    local delayTime = 9/30
    if curIndex == 1 then
        self.m_midWildData.m_curMoveIdle = spineFirstMoveIdleName
        -- 预备动画26帧
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Wild_MoveStart)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            util_spinePlay(midWildSpine, spineFirstMoveName, false)
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(26/30)
        -- 旋转idle
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_wildMoveSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FatFeature_Wild_MoveIdle, true)
            util_spinePlay(midWildSpine, spineFirstMoveIdleName, true)
        end)
    end
    tblActionList[#tblActionList+1] = cc.MoveTo:create(delayTime, curMovePos)
    -- 移动到下个位置之后，判断当前位置是否有收集数据
    local bonusDataTbl = self:getCurPosCollectBonusData(wildStatus, curWildIndex, bonusLocation)
    if bonusDataTbl and next(bonusDataTbl) then
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:fatFeatureCollectCurBonus(callFunc, parmsData, bonusDataTbl, 0, spineMoveIdleName)
        end)
    else
        if self.m_midWildData.m_curMoveIdle ~= spineMoveIdleName then
            self.m_midWildData.m_curMoveIdle = spineMoveIdleName
            util_spinePlay(midWildSpine, spineMoveIdleName, true)
        end
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:playCollectFatFeatureBonusByMovePath(callFunc, parmsData)
        end)
    end
    midWildSpine:runAction(cc.Sequence:create(tblActionList))
end

-- 一个一个收集
function CodeGameScreenPudgyPandaMachine:fatFeatureCollectCurBonus(_callFunc, _parmsData, _bonusDataTbl, _curCollectIndex, _spineMoveIdleName)
    local callFunc = _callFunc
    local parmsData = _parmsData
    local bonusDataTbl = _bonusDataTbl
    local spineMoveIdleName = _spineMoveIdleName
    local fsExtraData = _parmsData.m_fsExtraData
    -- 当前步wild旋转的方向
    local curDirection = _parmsData.m_curDirection
    -- 路线索引
    local curIndex = _parmsData.m_curIndex
    -- 收集的路径
    local movePath = fsExtraData.move_path

    -- 是否为最后一个
    local isLastCollect = curIndex == #movePath and true or false

    -- 当前收集的个数
    local curCollectNum = _parmsData.m_curCollectNum or 0
    -- 当前位置收集bonus索引
    local curCollectIndex = _curCollectIndex + 1

    local totalCollectCount = #bonusDataTbl

    if curCollectIndex > totalCollectCount then
        self:playCollectFatFeatureBonusByMovePath(callFunc, parmsData)
        return
    end
    local midWildSpine = self.m_midWildData.p_midWildSpine
    local topMinWildSpine = midWildSpine.m_topMinWildSpine
    local iconNodeScore = midWildSpine.m_iconNodeScore

    local tblActionList = {}

    local showCollectNum = curCollectNum + 1
    local showCollectNumStr = showCollectNum > 1 and showCollectNum or ""
    parmsData.m_curCollectNum = showCollectNum
    
    local curBonusData = bonusDataTbl[curCollectIndex]
    
    local rowIndex = curBonusData.p_rowIndex
    local cloumnIndex = curBonusData.p_cloumnIndex
    local symbolNode = self:getFixSymbol(cloumnIndex, rowIndex, SYMBOL_NODE_TAG)
    if symbolNode then
        if not self:getCurSymbolTypeIsJackpot(curBonusData[1]) then
            self:changeSymbolCCBByName(symbolNode, self.SYMBOL_SCORE_FAT_FEATURE_BONUS)
        end

        -- 棋盘上的小块播收集动画(shouji动画25帧)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            symbolNode:runAnim("shouji", false)
        end)
        -- shouji动画15帧
        tblActionList[#tblActionList+1] = cc.DelayTime:create(15/30)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            symbolNode:setVisible(false)
        end)
        
        -- bonus上边的wild播收集
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if not tolua.isnull(topMinWildSpine) then
                topMinWildSpine:setVisible(true)
                util_spinePlay(topMinWildSpine, "shouji1", false)
            end
        end)

        -- 收集播放12帧后，下边的中间wild切换方向
        tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if self.m_midWildData.m_curMoveIdle ~= spineMoveIdleName then
                self.m_midWildData.m_curMoveIdle = spineMoveIdleName
                util_spinePlay(midWildSpine, spineMoveIdleName, true)
            end

            -- 如果是最后一个；切换成静帧
            if isLastCollect then
                util_spinePlay(midWildSpine, "idleframe2", true)
            end
        end)

        -- 当Socre_PudgyPanda_Wild1-5的shouji1播放到第20帧切换数字
        tblActionList[#tblActionList+1] = cc.DelayTime:create(8/30)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if not tolua.isnull(iconNodeScore) then
                util_resetCsbAction(iconNodeScore.m_csbAct)
                iconNodeScore:findChild("m_lb_num"):setString(showCollectNumStr)
                iconNodeScore:setVisible(true)
                -- 如果是第一个，需要播放开始动画
                if showCollectNum == 1 then
                    iconNodeScore:runCsbAction("start", false, function()
                        iconNodeScore:runCsbAction("idle", true)
                    end)
                else
                    iconNodeScore:runCsbAction("actionframe", false, function()
                        iconNodeScore:runCsbAction("idle", true)
                    end)
                end
            end
        end)
        -- 收集动画40帧
        tblActionList[#tblActionList+1] = cc.DelayTime:create(2/30)
        -- 收集下一个
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if not tolua.isnull(topMinWildSpine) then
                topMinWildSpine:setVisible(false)
            end
        end)

        if self:getCurSymbolTypeIsJackpot(curBonusData[1]) then
            if self.m_wildMoveSound then
                gLobalSoundManager:stopAudio(self.m_wildMoveSound)
                self.m_wildMoveSound = nil
            end
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_JackpotBonus_FeedBack)
            local jackpotName = "Mini"
            local jackpotIndex = 5
            if curBonusData[1] == self.SYMBOL_SCORE_BONUS_MINI then
                jackpotName = "Mini"
                jackpotIndex = 5
            elseif curBonusData[1] == self.SYMBOL_SCORE_BONUS_MINOR then
                jackpotName = "Minor"
                jackpotIndex = 4
            end
            local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
            local jackpotCoins = allJackpotCoins[jackpotName] or 0
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self.m_jackPotBarView:playTriggerJackpot(jackpotIndex)
                self:showJackpotView(jackpotCoins, jackpotName, function()
                    self.m_jackPotBarView:setJackpotIdle(1)
                    self:playBottomLight(jackpotCoins)
                    if not self.m_wildMoveSound then
                        self.m_wildMoveSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FatFeature_Wild_MoveIdle, true)
                    end
                    self:fatFeatureCollectCurBonus(callFunc, parmsData, bonusDataTbl, curCollectIndex, spineMoveIdleName)
                end)
            end)
        elseif curBonusData[1] == self.SYMBOL_SCORE_BONUS then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Wild_MoveToBonus_FeedBack)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:fatFeatureCollectCurBonus(callFunc, parmsData, bonusDataTbl, curCollectIndex, spineMoveIdleName)
            end)
        else
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:fatFeatureCollectCurBonus(callFunc, parmsData, bonusDataTbl, curCollectIndex, spineMoveIdleName)
            end)
        end
    else
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:fatFeatureCollectCurBonus(callFunc, parmsData, bonusDataTbl, curCollectIndex, spineMoveIdleName)
        end)
    end
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 收集bonus到右侧笼屉（一个一个收集，收集过程中会升级）
function CodeGameScreenPudgyPandaMachine:playCollectFatFeatureBonusToBasket(_callFunc, _curIndex)
    local callFunc = _callFunc
    local curIndex = _curIndex + 1
    
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    -- 当前spin收集的个数
    local curCollectNum = fsExtraData.collect_num
    -- 当次spin是否有升级
    local if_wild_upgrade = fsExtraData.if_wild_upgrade
    -- 升级的方向
    -- 触发升级后的wild扩展方向 0为不扩展 1为右下 2为右上 3为左上 4为左下
    local upgradeDirection = fsExtraData.upgrade_direction
    -- 上一次wild边长
    local wildStatus = fsExtraData.wild_status
    -- 升级后的边长
    local wildNewStatus = fsExtraData.wild_new_status
    -- 最终位置
    local wildNewLocation = fsExtraData.wild_new_location

    if curIndex > curCollectNum then
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    -- 升级动画的名字
    local upgradeName = ""
    local upgradeWildSpine, upgradeWildLightSpine
    if self.m_fatFeatureBasketView:getCurIsUpgrade() and if_wild_upgrade then
        if upgradeDirection == 1 then
            upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_d"
        elseif upgradeDirection == 2 then
            upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_b"
        elseif upgradeDirection == 3 then
            upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_a"
        elseif upgradeDirection == 4 then
            upgradeName = "switch"..wildStatus.."_"..wildNewStatus.."_c"
        end

        local wildSpineName = "Socre_PudgyPanda_Wild"..wildStatus
        upgradeWildSpine = util_spineCreate(wildSpineName,true,true)
        local pos = self:getUpgradeWildPos(wildNewStatus, wildNewLocation, upgradeDirection)
        upgradeWildSpine:setPosition(pos)
        upgradeWildSpine:setVisible(false)
        upgradeWildSpine:setScale(1/self.m_symbolScale)

        -- 加角标
        local iconNodeScore = util_createAnimation("PudgyPanda_Wild_jiaobiao.csb")
        util_spinePushBindNode(upgradeWildSpine, "baozi_jb" ,iconNodeScore)
        upgradeWildSpine.m_iconNodeScore = iconNodeScore

        -- 放在连线上边
        self.m_clipParent:addChild(upgradeWildSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)

        -- 升级时上边的光效
        upgradeWildLightSpine = util_spineCreate("PudgyPanda_shengji",true,true)
        upgradeWildLightSpine:setPosition(pos)
        upgradeWildLightSpine:setVisible(false)
        upgradeWildLightSpine:setScale(1/self.m_symbolScale)
        -- 放在连线下边
        self.m_clipParent:addChild(upgradeWildLightSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 99)
    end

    local midWildSpine = self.m_midWildData.p_midWildSpine
    local iconNodeScore = midWildSpine.m_iconNodeScore

    local showCollectNum = curCollectNum - curIndex
    local showCollectNumStr = showCollectNum > 1 and showCollectNum or ""

    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(midWildSpine, "shouji2", false)
    end)
    -- 当shouji2播放到第12帧，角标做数字切换
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Wild_Eat_Bonus)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if not tolua.isnull(iconNodeScore) then
            iconNodeScore:setVisible(true)
            iconNodeScore:findChild("m_lb_num"):setString(showCollectNumStr)
            util_resetCsbAction(iconNodeScore.m_csbAct)
            if showCollectNum == 0 then
                iconNodeScore:runCsbAction("over", false, function()
                    iconNodeScore:setVisible(false)
                end)
            else
                iconNodeScore:runCsbAction("idle", true)
            end
        end
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(11/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_fatFeatureBasketView:playAddCollecteffect()
    end)
    -- shouji2-55帧
    tblActionList[#tblActionList+1] = cc.DelayTime:create(19/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(midWildSpine, "idleframe2", true)
    end)
    -- 判断是否升级；有升级，右侧笼屉触发30帧后升级
    if self.m_fatFeatureBasketView:getCurIsUpgrade() and if_wild_upgrade then
        tblActionList[#tblActionList+1] = cc.DelayTime:create(35/30)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if showCollectNum == 0 then
                upgradeWildSpine.m_iconNodeScore:setVisible(false)
            else
                upgradeWildSpine.m_iconNodeScore:runCsbAction("idle")
                upgradeWildSpine.m_iconNodeScore:findChild("m_lb_num"):setString(showCollectNumStr)
            end
            upgradeWildSpine:setVisible(true)
            upgradeWildLightSpine:setVisible(true)
            -- midWildSpine:setVisible(false)
            midWildSpine:removeFromParent()
            util_spinePlay(upgradeWildSpine, upgradeName, false)
            util_spinePlay(upgradeWildLightSpine, upgradeName, false)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Wild_Upgrade)
            if self.m_bonusEffectSoundIndex > 2 then
                self.m_bonusEffectSoundIndex = 1
            end
            local soundName = self.m_publicConfig.SoundConfig.Music_Oh_SoundEffect[self.m_bonusEffectSoundIndex]
            if soundName then
                gLobalSoundManager:playSound(soundName)
            end
            self.m_bonusEffectSoundIndex = self.m_bonusEffectSoundIndex + 1
        end)
        -- 升级动画25帧
        tblActionList[#tblActionList+1] = cc.DelayTime:create(25/30)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            upgradeWildSpine:removeFromParent()
            upgradeWildLightSpine:removeFromParent()
            -- 重新添加中间wild数据
            self:addMidBonusData(wildNewStatus, wildNewLocation, showCollectNum)
            -- 更新中心wild上的信息
            local midWildSpine = self.m_midWildData.p_midWildSpine
            util_spinePlay(midWildSpine, "idleframe2", true)
            midWildSpine:setVisible(true)
            local iconNodeScore = midWildSpine.m_iconNodeScore
            if not tolua.isnull(iconNodeScore) then
                iconNodeScore:setVisible(true)
                iconNodeScore:findChild("m_lb_num"):setString(showCollectNumStr)
            end
        end)
        -- freeBar涨次数
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FatFeature_AddTimes)
            if self:getCurIsBonus(true) then
                local bonusExtra = self.m_runSpinResultData.p_bonusExtra
                local bonusTotalCount = bonusExtra.freespin_total_count
                self.m_baseFreeSpinBar:refreshWheelSpinCount(bonusTotalCount)
            else
                self.m_baseFreeSpinBar:setFreeAni(true)
                gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            end
        end)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:playCollectFatFeatureBonusToBasket(callFunc, curIndex)
        end)
    else
        -- shouji2-动画55帧
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:playCollectFatFeatureBonusToBasket(callFunc, curIndex)
        end)
    end
    
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 判断当前位置是否可以收集bonus（fatFeature使用）
function CodeGameScreenPudgyPandaMachine:getCurPosCollectBonusData(_wildStatus, _curWildIndex, _bonusLocation)
    local wildStatus = _wildStatus
    local curWildIndex = _curWildIndex
    local bonusLocation = _bonusLocation
    -- 根据边长算出当前包含的位置
    local wildPosTbl = {}
    for i=1, wildStatus do
        -- 一行一行加位置
        local stepRowWildPos = curWildIndex+(i-1)*self.m_iReelRowNum
        -- 当前行的所有位置
        for j=1, wildStatus do
            -- 横向位置
            local horizontalPos = stepRowWildPos + (j-1)
            table.insert(wildPosTbl, horizontalPos)
        end
        
        -- -- 横向位置
        -- local horizontalPos = curWildIndex + (i-1)
        -- -- 纵向位置
        -- local verticalPos = curWildIndex + (i-1)*self.m_iReelRowNum
        -- table.insert(wildPosTbl, horizontalPos)
        -- table.insert(wildPosTbl, verticalPos)
    end

    local bonusDataTbl = {}
    -- 遍历所有位置，看是否有要收集的信息（存在收集多个）
    for k, v in pairs(bonusLocation) do
        if not v.m_isCollect then
            for i=1, #wildPosTbl do
                if v[2] == wildPosTbl[i] then
                    v.m_isCollect = true
                    local tempBonusData = clone(v)
                    -- 添加行列信息
                    local fixPos = self:getRowAndColByPos(v[2])
                    tempBonusData.p_rowIndex = fixPos.iX
                    tempBonusData.p_cloumnIndex = fixPos.iY
                    table.insert(bonusDataTbl, tempBonusData)
                end
            end
        end
    end

    -- 多个的话;依照从左到右，从上到下的顺序逐个走收集流程
    if bonusDataTbl and #bonusDataTbl > 1 then
        table.sort(bonusDataTbl, function(a, b)
            if a.p_cloumnIndex ~= b.p_cloumnIndex then
                return a.p_cloumnIndex < b.p_cloumnIndex
            end
            if a.p_rowIndex ~= b.p_rowIndex then
                return a.p_rowIndex > b.p_rowIndex
            end
            return false
        end)
    end

    return bonusDataTbl
end

-- 根据index转换需要节点坐标系
function CodeGameScreenPudgyPandaMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

------------------------------ 分割线（base移动bonus玩法） --------------------------------
-- 获取当前bet下移动bonus的数据
-- 在棋盘中的移动bonus坐标 
-- -5到-1：代表再棋盘上方出现
-- 0-14：代表再棋盘里
-- 15-19：代表再下方，即将要消失
function CodeGameScreenPudgyPandaMachine:getCurBetMoveBonusData(_selfData)
    local selfData = _selfData
    local moveBonusConfig = selfData.move_bonus_config
    local curBet = globalData.slotRunData:getCurTotalBet()
    local moveBonusData = {}

    if moveBonusConfig and moveBonusConfig[tostring( toLongNumber(curBet) )] then
        local curBetMoveBonusData = moveBonusConfig[tostring(toLongNumber(curBet))]
        moveBonusData = curBetMoveBonusData.move_bonus_location
    end

    return moveBonusData
end

-- 获取移动bonus的位置
function CodeGameScreenPudgyPandaMachine:getMoveBonusPos(_bonusIndex)
    local bonusIndex = _bonusIndex
    local bonusPos = cc.p(0, 0)
    local slotNodeH = 154
    if bonusIndex >= 0 and bonusIndex <= 14 then
        bonusPos = self:getWorldToNodePos(self.m_moveEffectNode, bonusIndex)
    elseif bonusIndex < 0 then
        -- 棋盘上边一行下边的位置
        local lowerBonusIndex = bonusIndex + self.m_iReelColumnNum
        bonusPos = self:getWorldToNodePos(self.m_moveEffectNode, lowerBonusIndex)
        bonusPos.y = bonusPos.y + slotNodeH
    elseif bonusIndex > 14 then
        -- 棋盘下边一行上边的位置
        local upperBonusIndex = bonusIndex - self.m_iReelColumnNum
        bonusPos = self:getWorldToNodePos(self.m_moveEffectNode, upperBonusIndex)
        bonusPos.y = bonusPos.y - slotNodeH
    end
    return bonusPos
end

function CodeGameScreenPudgyPandaMachine:createPudgyPandaSymbol(_symbolType)
    local symbol = util_createView("CodePudgyPandaSrc.PudgyPandaSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

-- 轮盘设置按钮状态
function CodeGameScreenPudgyPandaMachine:setWheelBtnState(_state)
    self.m_bottomUI:setWheelBtnVisible(_state)
end

-- base移动bonus，在点击的时候跳过
function CodeGameScreenPudgyPandaMachine:setSkipState(_state)
    self.m_isQuickSkip = _state
end

function CodeGameScreenPudgyPandaMachine:runSkipMove()
    if self.m_isQuickSkip then
        for index, bonusData in pairs(self.m_allMoveBonusTbl) do
            local bonusNode = bonusData.p_moveBonusNode
            if not tolua.isnull(bonusNode) then
                bonusNode:stopAllActions()
            end
        end
        self.m_moveEffectNode:removeAllChildren()
        self.m_scBonusWaitNode:stopAllActions()

        -- 直接设置到终点位置
        self:setMoveBonusEndPos()
        self:setSkipState(nil)
        self:stopMoveBonusSound()
    end
end

-- 停止移动bonus音效
function CodeGameScreenPudgyPandaMachine:stopMoveBonusSound()
    if self.m_moveBonusSound then
        gLobalSoundManager:stopAudio(self.m_moveBonusSound)
        self.m_moveBonusSound = nil
    end
end

-- 显示地图
function CodeGameScreenPudgyPandaMachine:openCollectMap()
    self.m_mapView:showMap(self.m_baseCurCollectNum)
end

---
-- 根据Bonus Game 每关做的处理
-- 选择free类型
function CodeGameScreenPudgyPandaMachine:showChooseView(_triggerFreeType, _endCallFunc)
    local triggerFreeType = _triggerFreeType
    local endCallFunc = _endCallFunc

    -- self:clearCurMusicBg()
    self:setMaxMusicBGVolume()
    self.m_chooseView:showFeatureChoose(triggerFreeType, endCallFunc)
end

function CodeGameScreenPudgyPandaMachine:addPlayEffect()
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if not featureDatas then
        return
    end

    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

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

-- 改为指定信号
function CodeGameScreenPudgyPandaMachine:changeSymbolCCBByName(_slotNode, _symbolType)
    if _slotNode.p_symbolImage then
        _slotNode.p_symbolImage:removeFromParent()
        _slotNode.p_symbolImage = nil
    end
    _slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, _symbolType), _symbolType)
    _slotNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, _symbolType))
end

--[[
    free/fatFeature
]]
function CodeGameScreenPudgyPandaMachine:showFeatureView()
    self.m_moveEffectNode:removeAllChildren()
    self.m_baseFreeSpinBar:changeFreeSpinByCount()
    self.m_baseFreeSpinBar:setVisible(true)

    self:clearCurMusicBg()

    --清理连线
    self:clearWinLineEffect()

    if not self.m_isDuanXianComeIn then
        --清空赢钱
        self.m_bottomUI:checkClearWinLabel()
    end

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    
    -- wild等级 2*2为2 3*3为3 4*4为4
    local wildEndStatus = fsExtraData.wild_new_status
    -- 初始位置(wild左上角所在位置)
    local wildPos = fsExtraData.wild_new_location
    
    self:changeShowRow(true)

    if self.m_curFreeType == self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE then
        self:changeBgSpine(3)
        -- 当前收集的进度
        local storedBonusNum = fsExtraData.stored_bonus_num
        self.m_fatFeatureBasketView:setCurCollectProcess(storedBonusNum, true)
    else
        self:changeBgSpine(2)
        -- free三个等级对应的标识符 2*2为1 3*3为2 4*4为3
        local selectType = fsExtraData.select_free_type
        self.m_freeTypeDesView:setCurFreeType(selectType)
    end

    -- 信号随机
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                local randomSymbolType = math.random(1, 8)
                self:changeSymbolCCBByName(slotNode, randomSymbolType)
            end
        end
    end

    -- 添加中间的bonus
    self:addMidBonusData(wildEndStatus, wildPos)
end

-- 中间bonus信息；固定位置；添加行列（连线使用）
function CodeGameScreenPudgyPandaMachine:addMidBonusData(_wildEndStatus, _wildPos, _showCollectNum)
    local wildSpineName = "Socre_PudgyPanda_Wild".._wildEndStatus
    local midWildSpine = util_spineCreate(wildSpineName,true,true)
    local pos = self:getWildMidPos(_wildEndStatus, _wildPos)
    midWildSpine:setPosition(pos)
    midWildSpine:setScale(1/self.m_symbolScale)
    -- 放在连线下边
    self.m_clipParent:addChild(midWildSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
    midWildSpine:setVisible(false)

    -- fatFeature玩法上边加个收集用的wild（一劳永逸）
    if self.m_curFreeType == self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE then
        local wildTopSpineName = "Socre_PudgyPanda_Wild".._wildEndStatus
        local topMidWildSpine = util_spineCreate(wildTopSpineName,true,true)
        midWildSpine:addChild(topMidWildSpine)
        topMidWildSpine:setVisible(false)
        midWildSpine.m_topMinWildSpine = topMidWildSpine

        -- 加角标
        local iconNodeScore = util_createAnimation("PudgyPanda_Wild_jiaobiao.csb")
        util_spinePushBindNode(midWildSpine, "baozi_jb" ,iconNodeScore)
        iconNodeScore:setVisible(false)
        midWildSpine.m_iconNodeScore = iconNodeScore
        if _showCollectNum and _showCollectNum > 0 then
            iconNodeScore:setVisible(true)
            iconNodeScore:runCsbAction("idle")
            iconNodeScore:findChild("m_lb_num"):setString(_showCollectNum)
        end
    end
    
    self:refreshMidWildData(midWildSpine, _wildPos, _wildEndStatus)
end

-- 更新中心wild数据
function CodeGameScreenPudgyPandaMachine:refreshMidWildData(_midWildSpine, _wildPos, _wildEndStatus)
    if _midWildSpine then
        self.m_midWildData.p_midWildSpine = _midWildSpine
    end
    self.m_midWildData.p_pos = _wildPos

    local fixPos = self:getRowAndColByPos(_wildPos)

    -- 左上角中心点；添加最大横纵行列；最小横纵行列；连线使用(最大和最小差边长)
    self.m_midWildData.p_maxRowIndex = fixPos.iX
    self.m_midWildData.p_minRowIndex = fixPos.iX - _wildEndStatus + 1

    self.m_midWildData.p_maxCloumnIndex = fixPos.iY + _wildEndStatus - 1
    self.m_midWildData.p_minCloumnIndex = fixPos.iY
end

-- 生成wild
function CodeGameScreenPudgyPandaMachine:showStartWild(_callFunc, _onEnter)
    local callFunc = _callFunc
    local midWildSpine = self.m_midWildData.p_midWildSpine
    midWildSpine:setVisible(true)
    self.m_midWildData.p_curPlayActName = "idleframe2"
    if _onEnter then
        util_spinePlay(midWildSpine, "idleframe2", true)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Wild_Appear)
        util_spinePlay(midWildSpine, "start", false)
        util_spineEndCallFunc(midWildSpine ,"start",function()
            util_spinePlay(midWildSpine, "idleframe2", true)
            if type(callFunc) == "function" then
                callFunc()
            end
        end)
    end
end

-- 显示遮罩
function CodeGameScreenPudgyPandaMachine:showMask(_showState)
    local showState = _showState
    
    if _showState then
        if not self.m_maskAni:isVisible() then
            self.m_maskAni:setVisible(true)
            util_resetCsbAction(self.m_maskAni.m_csbAct)
            self.m_maskAni:runCsbAction("start", false, function()
                self.m_maskAni:runCsbAction("idle", true)
            end)
        end
    else
        if self.m_maskAni:isVisible() then
            util_resetCsbAction(self.m_maskAni.m_csbAct)
            self.m_maskAni:runCsbAction("over", false, function()
                self.m_maskAni:setVisible(false)
            end)
        end
    end
end

--轮盘滚动显示遮罩
function CodeGameScreenPudgyPandaMachine:beginReelShowMask()
    for i,maskNode in ipairs(self.m_maskNodeTab) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            maskNode:setOpacity(0)
            maskNode:runAction(cc.FadeTo:create(0.2,155))
        end
    end
end

--轮盘停止隐藏遮罩
function CodeGameScreenPudgyPandaMachine:reelStopHideMask(col)
    local maskNode = self.m_maskNodeTab[col]
    local fadeAct = cc.FadeTo:create(0.2,0)
    local func = cc.CallFunc:create(function ()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct,func))
end

--重写列停止
function CodeGameScreenPudgyPandaMachine:reelSchedulerCheckColumnReelDown(parentData)
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

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:reelStopHideMask(parentData.cloumnIndex)
        end
    end
    return 0.1
end


--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenPudgyPandaMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    self.m_bigWinSpine:setVisible(true)
    local bigwinName = "actionframe_bigwin"
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        bigwinName = "actionframe_bigwin2"
    end
    util_spinePlay(self.m_bigWinSpine, bigwinName, false)
    util_spineEndCallFunc(self.m_bigWinSpine, bigwinName, function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(rootNode,5,10,aniTime)
end

function CodeGameScreenPudgyPandaMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    return CodeGameScreenPudgyPandaMachine.super.showEffect_runBigWinLightAni(self,effectData)
end

function CodeGameScreenPudgyPandaMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenPudgyPandaMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

-- free和freeMore特殊需求
function CodeGameScreenPudgyPandaMachine:playScatterTipMusicEffect()
    if self.m_triggerBonusSoundIndex > 2 then
        self.m_triggerBonusSoundIndex = 1
    end
    local soundName = self.m_publicConfig.SoundConfig.Music_Trigger_Bonus_Sound[self.m_triggerBonusSoundIndex]
    if soundName then
        globalMachineController:playBgmAndResume(soundName, 3, 0, 1)
    end
    self.m_triggerBonusSoundIndex = self.m_triggerBonusSoundIndex + 1
end

-- 不用系统音效
function CodeGameScreenPudgyPandaMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end


function CodeGameScreenPudgyPandaMachine:checkRemoveBigMegaEffect()
    CodeGameScreenPudgyPandaMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenPudgyPandaMachine:getShowLineWaitTime()
    local time = CodeGameScreenPudgyPandaMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------

function CodeGameScreenPudgyPandaMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("PudgyPandaSounds/music_PudgyPanda_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        -- fatFeature
        if self.m_curFreeType == self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE then
            self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_FatFeature_Bg)--fs背景音乐
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FatFeature_StartStart)
            self.m_freeFatFeatureSpine:setVisible(true)
            util_spinePlay(self.m_freeFatFeatureSpine, "actionframe", false)
            util_spineEndCallFunc(self.m_freeFatFeatureSpine, "actionframe", function()
                self.m_freeFatFeatureSpine:setVisible(false)
                self:showBaseToFatFeatureFreeSceneAni(function()
                    self:showStartWild(function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect() 
                    end)
                end)
                -- self:resetMusicBg(true)
                -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            end)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
            self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_FG_Bg)--fs背景音乐
            -- 收集free
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}

            local freeStartSpine = util_spineCreate("PudgyPanda_FGstartTB",true,true)
            local titleSpine = util_spineCreate("PudgyPanda_FGstartTB",true,true)
            local titleIdleName = "title".. self.m_curFreeType.. "_idle"
            local pandaSpine = util_spineCreate("Socre_PudgyPanda_Wild1",true,true)
            local lightAni = util_createAnimation("PudgyPanda_tb_guang.csb")

            util_spinePlay(freeStartSpine, "start", false)
            util_spineEndCallFunc(freeStartSpine, "start", function()
                util_spinePlay(freeStartSpine, "idle", true)
            end)
            util_spinePlay(titleSpine, titleIdleName, true)
            util_spinePushBindNode(freeStartSpine, "xiongmao2", pandaSpine)
            util_spinePlay(pandaSpine, "tanban1", true)
            lightAni:runCsbAction("idleframe", true)

            local cutSceneFunc = function()
                util_spinePlay(freeStartSpine, "over", false)
                performWithDelay(self.m_scWaitNode, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartOver)
                end, 5/60)
            end

            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showBaseToFreeSceneAni(function()
                    self:showStartWild(function()
                        --平均bet值 展示
                        self.m_bottomUI:showAverageBet()

                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect() 
                    end)
                end)     
            end)

            local freeNodeName = {"Node_FG", "Node_superFG", "Node_megaFG"}
            for index, nodeName in pairs(freeNodeName) do
                view:findChild(nodeName):setVisible(index==self.m_curFreeType)
            end
            view:setBtnClickFunc(cutSceneFunc)
            local titleNodeName = "Node_title_idle_"..self.m_curFreeType
            view:findChild(titleNodeName):addChild(titleSpine)
            view:findChild("Node_spine"):addChild(freeStartSpine)
            view:findChild("Node_bg"):addChild(lightAni)
            util_setCascadeOpacityEnabledRescursion(view, true)
            view:findChild("root"):setScale(self.m_machineRootScale)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

-- base到free过场
function CodeGameScreenPudgyPandaMachine:showBaseToFreeSceneAni(_callFunc)
    local callFunc = _callFunc
    self:fadeOutBgMusic()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Fg_CutScene)
    self.m_baseToFreeSpine:setVisible(true)
    util_spinePlay(self.m_baseToFreeSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_baseToFreeSpine, "actionframe_guochang", function()
        self.m_baseToFreeSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    
    -- 73帧切
    performWithDelay(self.m_scWaitNode, function()
        self.m_refreshJackpotBar = true
        self:changeSymbolParentNode(false)
        self:showFeatureView()
    end, 73/30)
end

-- free到base过场
function CodeGameScreenPudgyPandaMachine:showFreeToBaseSceneAni(_callFunc, _wheelHideCallFunc)
    local callFunc = _callFunc
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Base_CutScene)
    local wheelHideCallFunc = _wheelHideCallFunc
    self.m_freeToBaseSpine:setVisible(true)
    util_spinePlay(self.m_freeToBaseSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_freeToBaseSpine, "actionframe_guochang", function()
        self.m_freeToBaseSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    
    -- 35帧切
    performWithDelay(self.m_scWaitNode, function()
        self.m_refreshJackpotBar = false
        --清理连线
        self:clearWinLineEffect()
        self.m_baseFreeSpinBar:setVisible(false)
        self:changeSymbolParentNode(false)
        self:changeShowRow()
        self:changeBgSpine(1)
        local midWildSpine = self.m_midWildData.p_midWildSpine
        if not tolua.isnull(midWildSpine) then
            midWildSpine:removeFromParent()
        end
        self.m_midWildData = {}
        self:updateFixedBonus(true)
        self:refreshCollectAndMapProcess()
        if type(wheelHideCallFunc) == "function" then
            -- 隐藏轮盘和bar
            wheelHideCallFunc()
            self:setWheelSpinBarState(false)
            self.m_wheelRoleSpine:setVisible(false)
        end
        -- 把fatFeature里的自定义信号换成随机信号
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_FAT_FEATURE_BONUS then
                    -- slotNode:runAnim("idleframe", true)
                    local randomSymbolType = math.random(1, 8)
                    self:changeSymbolCCBByName(slotNode, randomSymbolType)
                end
            end
        end
    end, 35/30)
end

-- base到fatFeature-free过场
function CodeGameScreenPudgyPandaMachine:showBaseToFatFeatureFreeSceneAni(_callFunc)
    local callFunc = _callFunc
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_FatFeature_CutScene)
    self.m_baseToFatFeatureSpine:setVisible(true)
    util_spinePlay(self.m_baseToFatFeatureSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_baseToFatFeatureSpine, "actionframe_guochang", function()
        self.m_baseToFatFeatureSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    
    -- 20帧切
    performWithDelay(self.m_scWaitNode, function()
        self:changeSymbolParentNode(false)
        self:showFeatureView()
        
        for _, _node in ipairs(self.m_triggerBonusList) do
            _node:setVisible(true)
        end

        for _, _node in ipairs(self.m_curBonusList) do
            if not tolua.isnull(_node)then
                _node:removeFromParent()
            end
        end
        self.m_triggerBonusList = {}
        self.m_curBonusList = {}
    end, 20/30)
end

function CodeGameScreenPudgyPandaMachine:showFreeSpinOverView(_callFunc, _wheelHideCallFunc)
    local callFunc = _callFunc
    local wheelHideCallFunc = _wheelHideCallFunc
    local freeOverSpine = util_spineCreate("PudgyPanda_FGstartTB",true,true)
    local pandaSpine = util_spineCreate("PudgyPanda_xm",true,true)
    util_spinePlay(pandaSpine, "tb_idle", true)
    freeOverSpine:setVisible(false)

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    if callFunc then
        strCoins = util_formatCoins(self.m_runSpinResultData.p_bonusWinCoins, 30)
    end

    if self.m_curFreeType == self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE then
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_FatFeature_OverStart, 2, 0, 1)
    else
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 3, 0, 1)
    end

    local cutSceneFunc = function()
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
        end, 5/60)
    end

    local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
        self:showFreeToBaseSceneAni(function()
            if self.m_curFreeType ~= self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE then
                --平均bet值 隐藏
                self.m_bottomUI:hideAverageBet()
            end
            self:triggerFreeSpinOverCallFun()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, wheelHideCallFunc)
    end)

    view.m_allowClick = false
    local time = view:getAnimTime("start")
    performWithDelay(self.m_scWaitNode, function()
        view.m_allowClick = true
        if not tolua.isnull(freeOverSpine) and not tolua.isnull(pandaSpine) then
            freeOverSpine:setVisible(true)
            util_spinePlay(freeOverSpine, "title4_idle", true)
        end
    end, time)

    view:setBtnClickFunc(cutSceneFunc)
    view:findChild("m_lb_num_super"):setString(self.m_runSpinResultData.p_freeSpinsTotalCount)
    view:findChild("m_lb_num_mega"):setString(self.m_runSpinResultData.p_freeSpinsTotalCount)

    local freeTitleName = {"Node_FG_zi", "Node_superFG_zi", "Node_megaFG_zi", "Node_fatFeature"}
    for k, nodeName in pairs(freeTitleName) do
        view:findChild(nodeName):setVisible(self.m_curFreeType == k)
    end
    
    view:findChild("Node_title4_idle"):addChild(freeOverSpine)
    view:findChild("Node_juese"):addChild(pandaSpine)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.08,sy=1.08},572)
    util_setCascadeOpacityEnabledRescursion(view, true)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

-- 触发free或者回base；把小块层级放在slotParent上
function CodeGameScreenPudgyPandaMachine:changeSymbolParentNode(_onTop)
    local onTop = _onTop
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                slotNode:setVisible(true)
                if onTop then
                    self:putSymbolBackToPreParent(slotNode, true)
                else
                    self:putSymbolBackToPreParent(slotNode, false)
                end
            end
        end
    end
end

--[[
    将小块放回原父节点
]]
function CodeGameScreenPudgyPandaMachine:putSymbolBackToPreParent(symbolNode, isInTop)
    if not tolua.isnull(symbolNode) and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
        local parentData = self.m_slotParents[symbolNode.p_cloumnIndex]
        if not symbolNode.m_baseNode then
            symbolNode.m_baseNode = parentData.slotParent
        end

        if not symbolNode.m_topNode then
            symbolNode.m_topNode = parentData.slotParentBig
        end

        symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        local zOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
        -- local isInTop = self:isSpecialSymbol(symbolNode.p_symbolType)
        symbolNode.m_isInTop = isInTop
        symbolNode:putBackToPreParent()

        symbolNode:setTag(self:getNodeTag(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex,SYMBOL_NODE_TAG))
    end
end

-- 背景音乐淡出
function CodeGameScreenPudgyPandaMachine:fadeOutBgMusic()
    local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0
    util_schedule(self.m_timeWaitNode, function()
        if volume <= 0 then
            volume = 0
        end
        gLobalSoundManager:setBackgroundMusicVolume(volume)
        if volume <= 0 then
            if self.m_timeWaitNode ~= nil then
                self.m_timeWaitNode:stopAllActions()
            end
        end
        volume = volume - 1/60/2.5
    end, 1/60)
end

function CodeGameScreenPudgyPandaMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:levelDeviceVibrate(6, "free")
    local waitTime = 0

    self.m_triggerBonusList = {} -- 临时存一下触发的bonus
    self.m_curBonusList = {} --创建的假的bonus

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- fat fortune玩法为1 
    local freeType = selfData.free_type
    if freeType == 1 then
        -- 停掉背景音乐
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:clearCurMusicBg()
        end
        self.m_curFreeType = self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE

        if not self.m_isInitFixBonus then
            self.m_isInitFixBonus = true
            self:updateFixedBonus()
        end
        for index, bonusData in pairs(self.m_allMoveBonusTbl) do
            local bonusNode = bonusData.p_moveBonusNode
            local isReel = bonusData.p_isReel
            if not tolua.isnull(bonusNode) and isReel then
                bonusNode:runAnim("actionframe")
            end
        end

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                    end
                    slotNode:runAnim("actionframe")
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)

                    if not self.m_isDuanXianComeIn then
                        slotNode:setVisible(false)
                        table.insert(self.m_triggerBonusList, slotNode)

                        -- 创建个假的bonus
                        local symbolName = self:getSymbolCCBNameByType(self, slotNode.p_symbolType)
                        local curBonusSpine = util_spineCreate(symbolName, true, true)
                        self.m_moveEffectNode:addChild(curBonusSpine, self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)+10)
                        curBonusSpine:setPosition(util_convertToNodeSpace(slotNode, self.m_moveEffectNode))
                        util_spinePlay(curBonusSpine, "actionframe", false)
                        table.insert(self.m_curBonusList, curBonusSpine)
                    end
                end
            end
        end
        self:playScatterTipMusicEffect(true)
    else
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        -- free三个等级对应的标识符 2*2为1 3*3为2 4*4为3
        local selectType = fsExtraData.select_free_type
        self.m_curFreeType = selectType

        if self.m_curFreeType ~= self.ENUM_FREE_TYPE.MEGA_FREE then
            if self.m_isInitFixBonus then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Enjoy_Effect)
            end
        end
    end
    
    self.m_fsReelDataIndex = self.m_curFreeType - 1
    performWithDelay(self,function()
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true   
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenPudgyPandaMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:setWheelSpinBarState(true)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    self:levelDeviceVibrate(6, "bonus")

    local midWildSpine = self.m_midWildData.p_midWildSpine
    if not tolua.isnull(midWildSpine)then
        midWildSpine:removeFromParent()
    end

    local wheelWildSpine = util_spineCreate("Socre_PudgyPanda_Wild5",true,true)
    -- local pos = self:getWildMidPos(5, 0)
    wheelWildSpine:setPositionY(14)
    self:findChild("Node_wheel"):addChild(wheelWildSpine, 100)
    util_spinePlay(wheelWildSpine, "idleframe2", true)
    
    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_fatFeatureBasketView:showOverAni()
    end)
    -- 笼屉动画20帧
    tblActionList[#tblActionList+1] = cc.DelayTime:create(20/60)
    -- 大wild播触发
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Trigger_Wheel_Play)
        util_spinePlay(wheelWildSpine, "actionframe", false)
        self:runCsbAction("fatFeature_to_wheel", false)
        -- 播放bonus 元素不显示连线
        self:showBonusGameView(function()
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_bonusWinCoins, GameEffect.EFFECT_BONUS)
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        self.m_wheelReel:setWheelData()
    end)
    -- 触发130帧
    tblActionList[#tblActionList+1] = cc.DelayTime:create(130/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        wheelWildSpine:removeFromParent()
        self.m_wheelReel:showTips()
        self.m_wheelRoleSpine:setVisible(true)
        util_spinePlay(self.m_wheelRoleSpine, "start", false)
    end)
    -- 熊猫start时长
    tblActionList[#tblActionList+1] = cc.DelayTime:create(20/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_wheelReel:resetWheelData()
        util_spinePlay(self.m_wheelRoleSpine, "idle", true)
    end)

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

-- 大轮盘
function CodeGameScreenPudgyPandaMachine:showBonusGameView(callFunc, _onEnter)
    self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Wheel_Bg)
    --判断是否轮盘加钱（底部UI）
    self.collectWheel = true
    local midWildSpine = self.m_midWildData.p_midWildSpine
    if not tolua.isnull(midWildSpine)then
        midWildSpine:removeFromParent()
    end
    self.m_wheelReel = util_createView("CodePudgyPandaFeatureSrc.PudgyPandaWheelView",{machine = self, _endCallFunc = callFunc})
    self:findChild("Node_wheel"):addChild(self.m_wheelReel)
    
    local bonusWinCoins = self.m_runSpinResultData.p_bonusWinCoins
    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(bonusWinCoins))
    if _onEnter then
        self:setWheelBtnState(true)
    end
end

-- 
function CodeGameScreenPudgyPandaMachine:playTriggerRole()
    util_spinePlay(self.m_wheelRoleSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_wheelRoleSpine, "actionframe", function()
        util_spinePlay(self.m_wheelRoleSpine, "idle", true)
    end)  
end

-- 大轮盘结束
function CodeGameScreenPudgyPandaMachine:bonusGameOver(_endCallFunc, _wheelHideCallFunc, _rewardType)
    local endCallFunc = _endCallFunc
    local wheelHideCallFunc = _wheelHideCallFunc
    local rewardType = _rewardType
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local bonusState = self.m_runSpinResultData.p_bonusStatus
    local delayTime = 2

    local overCallFunc = function()
        performWithDelay(self.m_scWaitNode, function()
            if bonusState and bonusExtra.freespin_left_count > 0 then
                local bonusLeftCount = bonusExtra.freespin_left_count
                local bonusTotalCount = bonusExtra.freespin_total_count
                self.m_wheelSpinSpinBar:refreshAllCount(bonusLeftCount, bonusTotalCount)
                if not tolua.isnull(self.m_wheelReel)then
                    self.m_wheelReel:resetWheelData()
                end
            else
                self.collectWheel = false
                self:showFreeSpinOverView(function()
                    if type(endCallFunc) == "function" then
                        endCallFunc()
                    end
                    -- if type(hideCallFunc) == "function" then
                    --     hideCallFunc()
                    -- end
                end, wheelHideCallFunc)
            end
        end, delayTime)
    end

    local winAmount = self.m_runSpinResultData.p_winAmount
    local params = {
        overCoins  = winAmount,
        jumpTime   = 1.5,
        animName   = "actionframe3",
    }
    if rewardType == "" then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_Coins_Jump)
        self:playBottomBigWinLabAnim(params)
        self:playBottomLight(winAmount)
        overCallFunc()
    else
        local jackpotName = "Mini"
        local jackpotIndex = 3
        if rewardType == "grand" then
            jackpotName = "Grand"
            jackpotIndex = 1
        elseif rewardType == "mega" then
            jackpotName = "Mega"
            jackpotIndex = 2
        elseif rewardType == "major" then
            jackpotName = "Major"
            jackpotIndex = 3
        end

        self.m_jackPotBarView:playTriggerJackpot(jackpotIndex)
        self:showJackpotView(winAmount, jackpotName, function()
            self.m_jackPotBarView:setJackpotIdle(1)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_Coins_Jump)
            self:playBottomBigWinLabAnim(params)
            self:playBottomLight(winAmount)
            overCallFunc()
        end)
    end
end

-- 大转盘次数
function CodeGameScreenPudgyPandaMachine:setWheelSpinBarState(_isShow, _isStartSpin)
    self.m_wheelSpinSpinBar:setVisible(_isShow)
    self.m_baseFreeSpinBar:setVisible(false)
    if _isShow then
        local bonusExtra = self.m_runSpinResultData.p_bonusExtra
        local bonusLeftCount = bonusExtra.freespin_left_count
        local bonusTotalCount = bonusExtra.freespin_total_count
        if bonusLeftCount and bonusTotalCount then
            self.m_wheelSpinSpinBar:refreshAllCount(bonusLeftCount, bonusTotalCount)
        end
    end
end

-- 轮盘spin时，刷新次数
function CodeGameScreenPudgyPandaMachine:refreshWheelSpinBarLeftCount()
    self.m_wheelSpinSpinBar:refreshLeftCount()
end

-- 轮盘spin按钮发消息
function CodeGameScreenPudgyPandaMachine:sendSelectWheelData()
    if not tolua.isnull(self.m_wheelReel)then
        self.m_wheelReel:sendData()
    end
end

function CodeGameScreenPudgyPandaMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodePudgyPandaSrc.PudgyPandaJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

function CodeGameScreenPudgyPandaMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodePudgyPandaSrc.PudgyPandaFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_spinbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenPudgyPandaMachine:initWheelSpinBar()
    self.m_wheelSpinSpinBar = util_createView("CodePudgyPandaFeatureSrc.PudgyPandaWheelSpinBarView")
    self.m_wheelSpinSpinBar:setVisible(false)
    self:findChild("Node_spinbar"):addChild(self.m_wheelSpinSpinBar) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenPudgyPandaMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodePudgyPandaSrc.PudgyPandaJackpotWinView",{
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

function CodeGameScreenPudgyPandaMachine:updateReelGridNode(_symbolNode)
    
    -- jackpot信号设置皮肤
    if self:getCurSymbolTypeIsJackpot(_symbolNode.p_symbolType) then
        self:setSpecialSymbolSkin(_symbolNode)
    end
    if _symbolNode.m_isLastSymbol == true then
        local tetst = 14
    end
end

-- jackpot信号设置皮肤
function CodeGameScreenPudgyPandaMachine:setSpecialSymbolSkin(_symbolNode)
    local skinName = "mini"
    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_MINI then
        skinName = "mini"
    elseif _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_MINOR then
        skinName = "minor"
    end

    local ccbNode = _symbolNode:checkLoadCCbNode()
    if not tolua.isnull(ccbNode) and ccbNode.m_spineNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
end

-- 获取wild升级时的位置（服务器给的是左上角的位置；根据wild的边长转换wild中心点位置，要根据方向做偏移）
-- 触发升级后的wild扩展方向 0为不扩展 1为右下 2为右上 3为左上 4为左下
function CodeGameScreenPudgyPandaMachine:getUpgradeWildPos(_wildStatus, _wildPos, _upgradeDirection)
    local parentData = self.m_slotParents[1]
    local soltNodeW = parentData.slotNodeW
    local soltNodeH = parentData.slotNodeH

    local pos = cc.p(util_getOneGameReelsTarSpPos(self,_wildPos))
    local offsetX = (_wildStatus-1)/2*soltNodeW
    local offsetY = (_wildStatus-1)/2*soltNodeH
    pos.x = pos.x + offsetX
    pos.y = pos.y - offsetY

    local diffX = 0
    local diffY = 0
    -- reel条偏移
    local reelX = 1.7--2.0
    local diffReelX = 0
    -- 拿中心点的位置进行偏移（取当前边长，半个wild的长宽）（都是反方向偏移）
    if _upgradeDirection == 1 then
        -- 需要向左上偏移
        diffX = -_wildStatus/2*soltNodeW
        diffY = _wildStatus/2*soltNodeH
        -- diffReelX = -reelX*(_wildStatus*2-1)
    elseif _upgradeDirection == 2 then
        -- 需要向左下偏移
        diffX = -_wildStatus/2*soltNodeW
        diffY = -_wildStatus/2*soltNodeH
        -- diffReelX = -reelX*(_wildStatus*2-1)
    elseif _upgradeDirection == 3 then
        -- 需要向右下偏移
        diffX = _wildStatus/2*soltNodeW
        diffY = -_wildStatus/2*soltNodeH
        diffReelX = reelX*(_wildStatus*2-1)
    elseif _upgradeDirection == 4 then
        -- 需要向右下偏移
        diffX = _wildStatus/2*soltNodeW
        diffY = _wildStatus/2*soltNodeH
        diffReelX = reelX*(_wildStatus*2-1)
    end

    pos.x = pos.x + diffX
    pos.y = pos.y + diffY

    -- reel条偏移
    pos.x = pos.x + diffReelX

    return pos
end

-- 获取wild中心点位置（服务器给的是左上角的位置；根据wild的边长转换wild中心点位置）
function CodeGameScreenPudgyPandaMachine:getWildMidPos(_wildEndStatus, _wildPos)
    local parentData = self.m_slotParents[1]
    local soltNodeW = parentData.slotNodeW
    local soltNodeH = parentData.slotNodeH

    local pos = cc.p(util_getOneGameReelsTarSpPos(self,_wildPos))
    local offsetX = (_wildEndStatus-1)/2*soltNodeW
    local offsetY = (_wildEndStatus-1)/2*soltNodeH
    pos.x = pos.x + offsetX
    pos.y = pos.y - offsetY

    -- reel条偏移
    local reelX = 2.0
    local diffReelX = 0
    diffReelX = reelX*(_wildEndStatus-1)
    pos.x = pos.x + diffReelX

    return pos
end

-- 获取当前是否bonus玩法
function CodeGameScreenPudgyPandaMachine:getCurIsBonus(_onEnter)
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local bonusState = self.m_runSpinResultData.p_bonusStatus
    if bonusExtra and bonusState and bonusState == "OPEN" then
        local bonusLeftCount = bonusExtra.freespin_left_count
        local bonusTotalCount = bonusExtra.bonus_total_count
        if _onEnter then
            return true
        else
            if bonusLeftCount and bonusTotalCount and bonusLeftCount ~= bonusTotalCount then
                return true
            end
        end
    end

    return false
end

-- 当前是否是free
function CodeGameScreenPudgyPandaMachine:getCurFeatureIsFree()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        return true
    end

    return false
end

--[[
    播放预告中奖概率
    GD.SLOTO_FEATURE = {
        FEATURE_FREESPIN = 1,
        FEATURE_FREESPIN_FS = 2, -- freespin 中再次触发fs
        FEATURE_RESPIN = 3, -- 触发respin 玩法
        FEATURE_MINI_GAME_COLLECT = 4, -- 收集玩法小游戏
        FEATURE_MINI_GAME_OTHER = 5, -- 其它小游戏
        FEATURE_JACKPOT = 6 -- 触发 jackpot
    }
]]
function CodeGameScreenPudgyPandaMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.free_type then
        return false
    end

    -- fat fortune玩法为1 
    local freeType = selfData.free_type

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if self:getCurFeatureIsFree() and freeType == 1 then
        -- 出现预告动画概率默认为30%
        local probability = 30
        if _probability then
            probability = _probability
        end
        local isNotice = (math.random(1, 100) <= probability) 
        return isNotice
    end
    
    return false
end

-- 判断当前收集进度是否触发free玩法
function CodeGameScreenPudgyPandaMachine:getCurCollectIsTriggerFree()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.collect_num then
        return false
    end

    -- 当前收集的进度
    local curCollectNum = selfData.collect_num
    if curCollectNum == self.m_baseCollectConfig[1] or curCollectNum == self.m_baseCollectConfig[2] or curCollectNum == self.m_baseCollectConfig[3] then
        if self:cheakCollectBonus() then
            return true
        end
    end

    return false
end

-- 收到网络消息移动bonus(base)
function CodeGameScreenPudgyPandaMachine:receiveNetDataMoveBonus(_func)
    local func = _func
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        -- base下移动bonus
        local moveBonusData = self:getCurBetMoveBonusData(selfData)
        -- base移动bonus
        if moveBonusData and next(moveBonusData) then
            self:playMoveBonus(function()
                if type(func) == "function" then
                    func()
                end
            end)
        else
            if type(func) == "function" then
                func()
            end
        end
    else
        if type(func) == "function" then
            func()
        end
    end
end

-- free下移动wild到指定位置
function CodeGameScreenPudgyPandaMachine:playMoveWildByFree(_callFunc)
    local callFunc = _callFunc
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    -- 边长
    local wildEndStatus = fsExtraData.wild_new_status
    -- 路径
    local movePath = fsExtraData.move_path
    -- 起点
    local wildLocation = fsExtraData.wild_location
    -- 终点
    local wildNewLocation = fsExtraData.wild_new_location
    -- 当前的方向
    local curDirection = self:getMoveWildDirection(wildLocation, wildNewLocation)
    -- wild移动的路线
    local wildPosTbl = self:getMoveWildRoadPos(wildEndStatus, movePath)
    -- 更新中心wild信息
    self:refreshMidWildData(nil, wildNewLocation, wildEndStatus)

    local midWildSpine = self.m_midWildData.p_midWildSpine

    local tblActionList = {}
    local delayTime = 6/30
    local spineMoveName, spineMoveIdleName = self:getWildRotateDierection(curDirection)
    -- 预备动画26帧
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Wild_MoveStart)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(midWildSpine, spineMoveName, false)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(26/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_wildMoveSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Wild_MoveIdle)
        util_spinePlay(midWildSpine, spineMoveIdleName, true)
    end)
    for k, pos in pairs(wildPosTbl) do
        tblActionList[#tblActionList+1] = cc.MoveTo:create(delayTime, pos)
    end
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if self.m_wildMoveSound then
            gLobalSoundManager:stopAudio(self.m_wildMoveSound)
            self.m_wildMoveSound = nil
        end
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Wild_MoveOver)
        util_spinePlay(midWildSpine, "idleframe2", true)
        if callFunc then
            callFunc()
        end 
    end)
    midWildSpine:runAction(cc.Sequence:create(tblActionList))
end

-- 获取wild旋转的方向
function CodeGameScreenPudgyPandaMachine:getWildRotateDierection(_curDirection)
    local curDirection = _curDirection
    local spineMoveName = "move_you"
    local spineMoveIdleName = "move_idle_you"
    if curDirection == self.ENUM_WILD_DIRECTION.WILD_LEFT then
        spineMoveName = "move_zuo"
        spineMoveIdleName = "move_idle_zuo"
    elseif curDirection == self.ENUM_WILD_DIRECTION.WILD_MID then
        if self.m_midWildData.m_curMoveIdle then
            spineMoveIdleName = self.m_midWildData.m_curMoveIdle
        end
    end

    return spineMoveName, spineMoveIdleName
end

-- 获取移动路径的具体位置
function CodeGameScreenPudgyPandaMachine:getMoveWildRoadPos(_wildEndStatus, _movePath)
    local wildEndStatus = _wildEndStatus
    local movePath = _movePath

    local wildPosTbl = {}
    for k, wildPos in pairs(movePath) do
        local pos = self:getWildMidPos(wildEndStatus, wildPos)
        table.insert(wildPosTbl, pos)
    end
    
    return wildPosTbl
end

-- 移动时判断wild移动的方向
function CodeGameScreenPudgyPandaMachine:getMoveWildDirection(_wildLocation, _wildNewLocation)
    local wildLocation = _wildLocation
    local wildNewLocation = _wildNewLocation

    -- 默认方向为右
    local direction = self.ENUM_WILD_DIRECTION.WILD_RIGHT
    local startLoctionMod = wildLocation%self.m_iReelColumnNum--math.mod(wildLocation, self.m_iReelColumnNum)
    local endLocationMod = wildNewLocation%self.m_iReelColumnNum--math.mod(wildNewLocation, self.m_iReelColumnNum)
    if startLoctionMod > endLocationMod then
        direction = self.ENUM_WILD_DIRECTION.WILD_LEFT
    elseif startLoctionMod == endLocationMod then
        direction = self.ENUM_WILD_DIRECTION.WILD_MID
    end
    return direction
end

-- 判断当前是否触发移动
function CodeGameScreenPudgyPandaMachine:getCurSpinIsTriggerMoveWild()
    if self.m_curFreeType < self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local movePath = fsExtraData.move_path
        if movePath and next(movePath) then
            return true
        end
    end

    return false
end

-- fatFeature玩法有升级的话加free次数
-- 重新赋值free次数
-- 当次spin是否有升级
function CodeGameScreenPudgyPandaMachine:addFreeTimes()
    if self.m_curFreeType == self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local if_wild_upgrade = fsExtraData.if_wild_upgrade
        if if_wild_upgrade then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        end
    end
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenPudgyPandaMachine:showFeatureGameTip(_func)
    -- free下移动wild
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:getCurSpinIsTriggerMoveWild() then
            -- free下移动wild
            self:playMoveWildByFree(function()
                if _func then
                    _func()
                end 
            end)
        else
            self:addFreeTimes()
            if _func then
                _func()
            end 
        end
    else
        local isFatFeature = self:getFeatureGameTipChance(60)
        -- 先把移动bonus赋值
        self:receiveNetDataMoveBonus(function()
            if isFatFeature then
                --播放fatFeature预告中奖动画
                self:playFatFeatureNoticeAni(function()
                    if type(_func) == "function" then
                        _func()
                    end
                end)
            elseif self:getCurCollectIsTriggerFree() then
                --播放收集预告中奖动画
                self:playCollectFeatureNoticeAni(function()
                    if type(_func) == "function" then
                        _func()
                    end
                end)
            else
                if type(_func) == "function" then
                    _func()
                end
            end
        end)
    end
    
end

function CodeGameScreenPudgyPandaMachine:playCollectFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Free_Sound)
    self.m_yuGaoCollectSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoCollectSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_yuGaoCollectSpine, "actionframe_yugao", function()
        self.m_yuGaoCollectSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)  
end

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenPudgyPandaMachine:playFatFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_FatFeature_Sound)
    self.m_yuGaoFatSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoFatSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_yuGaoFatSpine, "actionframe_yugao", function()
        self.m_yuGaoFatSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)  
end

function CodeGameScreenPudgyPandaMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin；3.fatFeature；4.wheel
    local bgIdleName = {"idle_base", "idle_free", "idle_fatFeature", "idle_wheel"}
    if bgIdleName[_bgType] then
        self:runCsbAction(bgIdleName[_bgType])
    end

    local bgType = _bgType > 3 and 3 or _bgType
    for i=1, 3 do
        if i == bgType then
            self.m_bgType[i]:setVisible(true)
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_bgType[i]:setVisible(false)
            self.m_reelBg[i]:setVisible(false)
        end
    end
    self:findChild("Node_lianzi"):setVisible(_bgType ~= 1)
end

---
--判断改变freespin的状态
function CodeGameScreenPudgyPandaMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 and not self:getCurIsBonus(true) then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end
end

--[[
    @desc: 处理用户的spin赢钱信息
    time:2020-07-10 17:50:08
]]
function CodeGameScreenPudgyPandaMachine:operaWinCoinsWithSpinResult(param)
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
    --发送测试赢钱数
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN, self.m_serverWinCoins)
    globalData.userRate:pushCoins(self.m_serverWinCoins)

    if spinData.result.freespin.freeSpinsTotalCount == 0 and not self:getCurIsBonus(true) then
        self:setLastWinCoin(spinData.result.winAmount)
    else
        self:setLastWinCoin(spinData.result.freespin.fsWinCoins)
    end
    globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
end

function CodeGameScreenPudgyPandaMachine:playBottomLight(_endCoins)
    self.m_bottomUI:playCoinWinEffectUI()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_JumpCoins)
    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenPudgyPandaMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenPudgyPandaMachine:getCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

function CodeGameScreenPudgyPandaMachine:tipsBtnIsCanClick()
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_isRunningEffect == true
    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local features = self.m_runSpinResultData.p_features or {}
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end

    return true
end

function CodeGameScreenPudgyPandaMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local lineWinCoins  = self:getClientWinCoins()
    -- self.m_iOnceSpinLastWin = lineWinCoins

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local bottomWinCoin = self:getCurBottomWinCoins()
        if self.m_isDuanXianComeIn then
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
        else
            self:setLastWinCoin(bottomWinCoin + lineWinCoins)
        end

        if lineWinCoins and lineWinCoins > 0 and self:getCurRewardCoinsIsBigWin(lineWinCoins) then
            if self.m_winEffectSoundIndex > 2 then
                self.m_winEffectSoundIndex = 1
            end
            local soundName = self.m_publicConfig.SoundConfig.Music_Celebrate_WinEffect[self.m_winEffectSoundIndex]
            if soundName then
                gLobalSoundManager:playSound(soundName)
            end
            self.m_winEffectSoundIndex = self.m_winEffectSoundIndex + 1
        end
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lineWinCoins, isNotifyUpdateTop})
end

-- 获取当前bet；super里获取平均bet
function CodeGameScreenPudgyPandaMachine:getCurRewardCoinsIsBigWin(_rewardCoins)
    local rewardCoins = _rewardCoins
    local curBet = globalData.slotRunData:getCurTotalBet()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData and self.m_runSpinResultData.p_avgBet and self.m_runSpinResultData.p_avgBet > 0 then
        curBet = self.m_runSpinResultData.p_avgBet
    end
    local mul = rewardCoins/curBet
    local iBigWinLimit = self.m_BigWinLimitRate
    if mul >= iBigWinLimit then
        return true
    end
    return false
end

-- 连线全部播放一遍
function CodeGameScreenPudgyPandaMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        if self:curWildIsContainSlotNode(slotsNode) then
                            self:setSpecialSpineLine(slotsNode)
                        else
                            slotsNode:runLineAnim()
                        end
                    else
                        slotsNode:runLineAnim()
                    end
                end
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenPudgyPandaMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if self:curWildIsContainSlotNode(slotsNode) then
                    self:setSpecialSpineLine(slotsNode)
                else
                    slotsNode:runLineAnim()
                end
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

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenPudgyPandaMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:setSpecialSpineIdle(slotsNode)
            end
            slotsNode:runIdleAnim()
        end
    end
end

--播放中间大wild连线动画
function CodeGameScreenPudgyPandaMachine:setSpecialSpineLine(_slotsNode)
    if self.m_midWildData and next(self.m_midWildData) then
        local midWildSpine = self.m_midWildData.p_midWildSpine
        local curPlayActName = self.m_midWildData.p_curPlayActName
        if not tolua.isnull(midWildSpine) and curPlayActName ~= "actionframe" then
            self.m_midWildData.p_curPlayActName = "actionframe"
            util_spinePlay(midWildSpine, "actionframe", true)
        end
    end
end

-- 播放中间wild的idle
function CodeGameScreenPudgyPandaMachine:setSpecialSpineIdle(_slotsNode)
    if self.m_midWildData and next(self.m_midWildData) then
        local midWildSpine = self.m_midWildData.p_midWildSpine
        local curPlayActName = self.m_midWildData.p_curPlayActName
        if not tolua.isnull(midWildSpine) and curPlayActName ~= "idleframe2" then
            self.m_midWildData.p_curPlayActName = "idleframe2"
            util_spinePlay(midWildSpine, "idleframe2", true)
        end
    end
end

-- 判断当前小块是否在中间大wild的里面
function CodeGameScreenPudgyPandaMachine:curWildIsContainSlotNode(_slotsNode)
    local curRow = _slotsNode.p_rowIndex
    local curCol = _slotsNode.p_cloumnIndex

    -- 取最大最小行列比较
    local maxRowIndex = self.m_midWildData.p_maxRowIndex
    local minRowIndex = self.m_midWildData.p_minRowIndex

    local maxCloumnIndex = self.m_midWildData.p_maxCloumnIndex
    local minCloumnIndex = self.m_midWildData.p_minCloumnIndex

    if curRow >= minRowIndex and curRow <= maxRowIndex and curCol >= minCloumnIndex and curCol <= minCloumnIndex then
        return true
    end
    return false
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenPudgyPandaMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        _slotNode:runAnim("idleframe2", true)
    elseif self:getCurSymbolTypeIsJackpot(_slotNode.p_symbolType) then
        _slotNode:runAnim("idleframe2", true)
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenPudgyPandaMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    return self:getBonusStatus(_slotNode.p_cloumnIndex)
                end
                return true
            end
        end
    end

    return false
end

--[[
    bonus是否播放落地动画
]]
function CodeGameScreenPudgyPandaMachine:getBonusStatus(_col)
    if _col <= 3 or (self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_curFreeType == self.ENUM_FREE_TYPE.FAT_FORTUNE_FREE) then
        return true
    else
        local bonusNums = 0
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local moveBonusData = self:getCurBetMoveBonusData(selfData)
        if moveBonusData and next(moveBonusData) then
            for k, bonusData in pairs(moveBonusData) do
                local endIndex = bonusData[2]
                if endIndex >= 0 and endIndex <= 14 then
                    local fixPos = self:getRowAndColByPos(endIndex)
                    if fixPos.iY <= _col then
                        bonusNums = bonusNums + 1
                    end
                end
            end
        end

        for iCol = 1, _col do
            for iRow = 1, self.m_iReelRowNum do
                local symbol = self:getMatrixPosSymbolType(iRow, iCol)
                if symbol == self.SYMBOL_SCORE_BONUS then
                    bonusNums = bonusNums + 1
                end
            end
        end

        if bonusNums >= 3 and _col == 4 then
            return true
        elseif bonusNums >= 6 and _col == 5 then
            return true
        end
    
        return false
    end
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenPudgyPandaMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 11
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

--[[
    检查棋盘数据 是否存在96
]]
function CodeGameScreenPudgyPandaMachine:cheakCollectBonus( )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbol = self:getMatrixPosSymbolType(iRow, iCol)
            if symbol == self.SYMBOL_SCORE_COLLECT_BONUS then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenPudgyPandaMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.4
        if not self:checkHasSelfGameEffectType(self.EFFECT_FAT_FEATURE_COLLECT_BONUS) then
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

--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenPudgyPandaMachine:checkHasSelfGameEffectType(selfEffectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_selfEffectType
        if value == selfEffectType then
            return true
        end
    end

    return false
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenPudgyPandaMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                local delayTime = 0
                -- 动效特殊要求 收集bonus 延迟2帧在播放 落地
                if _slotNode.p_symbolType == self.SYMBOL_SCORE_COLLECT_BONUS then
                    delayTime = 2/30
                end
                self:delayCallBack(delayTime, function()
                    --2.播落地动画
                    _slotNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(_slotNode)
                        end
                    )
                end)
            end
        end
    end
end

function CodeGameScreenPudgyPandaMachine:scaleMainLayer()
    CodeGameScreenPudgyPandaMachine.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if display.width / display.height <= 920/768 then
        mainScale = mainScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width / display.height <= 1152/768 then
        mainScale = mainScale * 0.96
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width / display.height <= 1228/768 then
        mainScale = mainScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )   
    else
        mainScale = mainScale * 0.97
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

return CodeGameScreenPudgyPandaMachine






