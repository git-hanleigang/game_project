---
-- island li
-- 2019年1月26日
-- CodeGameScreenKoiBlissMachine.lua
--
-- 玩法：
--
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local PublicConfig = require "KoiBlissPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenKoiBlissMachine = class("CodeGameScreenKoiBlissMachine", BaseNewReelMachine)

CodeGameScreenKoiBlissMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_11 = 10

CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_0_HUI = 20
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_1_HUI = 21
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_2_HUI = 22
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_3_HUI = 23
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_4_HUI = 24
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_5_HUI = 25
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_6_HUI = 26
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_7_HUI = 27
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_8_HUI = 28
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_10_HUI = 29
CodeGameScreenKoiBlissMachine.SYMBOL_SCORE_11_HUI = 30

CodeGameScreenKoiBlissMachine.SYMBOL_BONUS_1 = 94
CodeGameScreenKoiBlissMachine.SYMBOL_BONUS_2 = 95
CodeGameScreenKoiBlissMachine.SYMBOL_BONUS_FAKER1 = 194
CodeGameScreenKoiBlissMachine.SYMBOL_BONUS_FAKER2 = 195
--194 195
CodeGameScreenKoiBlissMachine.SYMBOL_KAIMEN = 96

CodeGameScreenKoiBlissMachine.BONUSGAME_EFFECT = GameEffect.EFFECT_LINE_FRAME + 1--pick小游戏
CodeGameScreenKoiBlissMachine.BONUS2LONG_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2--bonus2图标变长收集
CodeGameScreenKoiBlissMachine.WILDCOLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3--收集wild
CodeGameScreenKoiBlissMachine.KAIMEN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4


-- 构造函数
function CodeGameScreenKoiBlissMachine:ctor()
    CodeGameScreenKoiBlissMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeKoiBlissSrc.KoiBlissSymbolExpect", self)

    -- 引入控制插件
    self.m_longRunControl = util_createView("KoiBlissLongRunControl", self)
    self.m_isPlayLineSound = true --是否播放连线音效
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_iBetLevel = 0
    self.m_isFirstChangeBet = true
    self.m_isAddBigWinLightEffect = true
    self.m_isLastRespin = false --是否是最后一次respin
    self.m_bonus2Tab = {}--存储要收集的bonus2图标
    self.m_scatteNum = 1
    self.m_lightScore = 0
    -- self.wenAnTotalCoins = 0

    self.waterList = {}

    --init
    self:initGame()
end

function CodeGameScreenKoiBlissMachine:getMachineConfigParseLuaName()
    return "LevelKoiBlissConfig.lua"
end

function CodeGameScreenKoiBlissMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenKoiBlissMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "KoiBliss"
end

function CodeGameScreenKoiBlissMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initJackPotBarView()
    self:initFreeSpinBar() -- FreeSpinbar

    --添加respin条
    self.m_respinBar = util_createAnimation("KoiBliss_respin_respinbar.csb")
    self:findChild("Node_fgbar"):addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)
    self.m_respinBar.updateNum = function(_time)
        --更新respin条数字
        self.m_respinBar:findChild("light_1"):setVisible(_time == 1)
        self.m_respinBar:findChild("light_2"):setVisible(_time == 2)
        self.m_respinBar:findChild("light_3"):setVisible(_time == 3)
    end
    
    
    self.m_lockUIBar = util_createAnimation("KoiBliss_base_choicemode.csb")
    self:findChild("Node_choicemode"):addChild(self.m_lockUIBar)
    self:addClick(self.m_lockUIBar:findChild("Button_1"))
    self:addClick(self.m_lockUIBar:findChild("Panel_unlock"))
    self:addClick(self.m_lockUIBar:findChild("Panel_tip"))
    self.m_lockUIBar.m_state = -1

    --添加开场动画
    self.m_kaichang = util_createAnimation("KoiBliss_free_kaichang.csb")
    self:findChild("Node_Fs_KaiChang"):addChild(self.m_kaichang)
    self.m_kaichang:setVisible(false)

    --添加totalwin框
    self.m_totalWinKuang = util_createAnimation("KoiBliss_respin_collectbouns.csb")
    self:findChild("Node_respin_collectbouns"):addChild(self.m_totalWinKuang)
    self.m_totalWinKuang:setVisible(false)
    self.m_totalWinKuang.m_currShowCoins = 0
    self.m_totalWinKuang.m_fk = util_createAnimation("KoiBliss_base_changebouns_tx.csb")
    self.m_totalWinKuang:findChild("Node_tx"):addChild(self.m_totalWinKuang.m_fk)
    self.m_totalWinKuang.m_fk:setVisible(false)

    self.respinDark = util_createAnimation("KoiBliss/ReSpinStart_dark.csb")
    self:findChild("Node_Gc"):addChild(self.respinDark,1)
    self.respinDark:setVisible(false)

    self.respinStartView = util_createView("CodeKoiBlissSrc.KoiBlissRespinStartView",self)
    self:findChild("Node_Gc"):addChild(self.respinStartView,10)
    self.respinStartView:setVisible(false)

    --respin过场（新）
    self.m_gcLighting = util_createAnimation("KoiBliss/ReSpinStart_gc_guang.csb")
    self:findChild("Node_Gc"):addChild(self.m_gcLighting,2)
    local light = util_spineCreate("KoiBliss_juese",true,true) 
    self.m_gcLighting:findChild("Node_guangquan"):addChild(light)
    self.m_gcLighting.light = light
    self.m_gcLighting:setVisible(false)

    self.jveSeNode = cc.Node:create()
    self:findChild("root"):addChild(self.jveSeNode)

end

function CodeGameScreenKoiBlissMachine:initSpineUI()

    self.m_spineBG = util_spineCreate("GameScreenKoiBlissBg",true,true)
    self.m_gameBg:findChild("root"):addChild(self.m_spineBG)

    --* self.m_machineRootScale
    local radius = 250 
    local worldPos = self:findChild("Node_doublefish"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_doublefish"):getPosition()))
    worldPos = cc.p(worldPos.x,worldPos.y )
    -- 无相加
    self.m_fishJuese1 = util_spineCreate("KoiBliss_juese",true,true) 
    self.m_fishJuese1:setPositionY(-225)
    self.m_fishJuese1.worldPos = worldPos
    self.m_fishJuese1.radius = radius
    local sizeX = 31
    local sizePix = display.width/sizeX
    local sizeY = math.ceil(display.height/sizePix) 
    self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D = PublicConfig.createGridNode(cc.size(sizeX,sizeY),self.m_fishJuese1 ) 
    PublicConfig.fishRippleAction1(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(worldPos), radius,true)
    -- PublicConfig.fishRippleAction2(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(worldPos), radius)
    self:findChild("Node_doublefish"):addChild(self.m_fishJuese1.p_gridNode,PublicConfig.fishZOrder.down)

    
    -- 有相加
    self.m_fishJuese2 = util_spineCreate("KoiBliss_juese2",true,true) 
    self.m_fishJuese2:setPositionY(-225)
    self.m_fishJuese2.worldPos = worldPos
    self.m_fishJuese2.radius = radius
    self.m_fishJuese2.p_gridNode, self.m_fishJuese2.p_grid3D = PublicConfig.createGridNode(cc.size(sizeX,sizeY),self.m_fishJuese2 ) 
    self:findChild("Node_doublefish"):addChild(self.m_fishJuese2.p_gridNode,PublicConfig.fishZOrder.mid)
    self.m_fishJuese2.m_actionName = nil

    self.m_fishJuese2.m_bowen = util_spineCreate("KoiBliss_juese2",true,true)
    util_spinePlay(self.m_fishJuese2.m_bowen, "shuiwen",true)
    self.m_fishJuese2.m_bowen:setPositionY(-225)
    self:findChild("Node_doublefish"):addChild(self.m_fishJuese2.m_bowen,PublicConfig.fishZOrder.top + 1)
    self.m_fishJuese2.m_bowen:setVisible(false)

    --盆地光效
    self.m_basinLighting = util_spineCreate("KoiBliss_juese2",true,true)
    util_spinePlay(self.m_basinLighting, "diguang",true)
    self.m_basinLighting:setPositionY(-225)
    self:findChild("Node_doublefish"):addChild(self.m_basinLighting,PublicConfig.fishZOrder.down - 1)
    -- self:showBasinLighting(true)

    --新增收集特效
    self.shouji_bd = util_spineCreate("KoiBliss_shouji_bd",true,true)
    self:findChild("Node_shuibowen"):addChild(self.shouji_bd)
    self.shouji_bd:setVisible(false)

    -- 添加文案
    self.m_wenan = util_createAnimation("KoiBliss_base_changebouns.csb")
    self:findChild("Node_changebouns"):addChild(self.m_wenan)
    self.m_wenan:setVisible(false)
    local fankui = util_createAnimation("KoiBliss_base_changebouns_tx.csb")
    self.m_wenan:findChild("Node_fankui"):addChild(fankui)
    self.m_wenan.m_fankui = fankui
    self.m_wenan.m_fankui:setVisible(false)

    --添加轮盘遮罩
    self.m_reelZhezhao = util_createAnimation("KoiBliss_zhezhao.csb")
    self:findChild("Node_Dark"):addChild(self.m_reelZhezhao)
    self.m_reelZhezhao:setVisible(false)

  

    self.m_totalWinKuang.m_fkCoinsTop = util_spineCreate("KoiBliss_yingqianjs1",true,true)
    self.m_totalWinKuang:addChild(self.m_totalWinKuang.m_fkCoinsTop,1)
    self.m_totalWinKuang.m_fkCoinsTop:setVisible(false)
    self.m_totalWinKuang.m_fkCoinsTop:setPositionY(-300)
    self.m_totalWinKuang.m_fkCoinsDown = util_spineCreate("KoiBliss_yingqianjs2",true,true)
    self.m_totalWinKuang:addChild(self.m_totalWinKuang.m_fkCoinsDown,-1)
    self.m_totalWinKuang.m_fkCoinsDown:setVisible(false)
    self.m_totalWinKuang.m_fkCoinsDown:setPositionY(-300)

    
    --添加pick小游戏界面
    self.m_pickGameLayer = util_createView("CodeKoiBlissSrc.KoiBlissPickGame",self)
    self:findChild("Node_pickNode"):addChild(self.m_pickGameLayer)
    self.m_pickGameLayer:hideLayer()


    self.m_bigWinEff =  util_spineCreate("KoiBliss_bigwin",true,true)
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
    self:findChild("root"):addChild(self.m_bigWinEff)
    self.m_bigWinEff:setPosition(cc.p((pos.x + 15),(pos.y - 25)))
    -- self:findChild("Node_bigwin"):addChild(self.m_bigWinEff)
    self.m_bigWinEff:setVisible(false)

    self.m_fsStartGc = util_spineCreate("KoiBliss_guochang_men",true,true)
    self:findChild("Node_Gc"):addChild(self.m_fsStartGc)
    self.m_fsStartGc:setVisible(false)

    self.m_fsStartYg = util_createAnimation("KoiBliss_free_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_fsStartYg)
    self.m_fsStartYg:setVisible(false)

    self.m_rsStartGc = util_spineCreate("KoiBliss_juese",true,true) 
    self:findChild("Node_Gc"):addChild(self.m_rsStartGc,2)
    self.m_rsStartGc:setVisible(false)

    -- 预告
    self:initRsYuGaoAnim()

    self:findChild("clipLayer"):setVisible(false)
    self:findChild("clipLayer"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    self:clearClipLayer()
    self:changeBgForStates(PublicConfig.base) 
end
function CodeGameScreenKoiBlissMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_bottomUI.m_btn_add:isTouchEnabled() or self.m_bottomUI.m_btn_sub:isTouchEnabled() then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.click)
        if name == "Button_1" or name == "Panel_tip" then
            self:showFortuneMode()
        end
        if name == "Panel_unlock" then
            self:unlockHigherBet()
        end
    end
end


function CodeGameScreenKoiBlissMachine:enterGamePlayMusic()
    self:delayCallBack(
        0.4,
        function()
            self:playEnterGameSound(PublicConfig.SoundConfig.music_KoiBliss_enter)
        end
    )
end

function CodeGameScreenKoiBlissMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenKoiBlissMachine.super.onEnter(self) -- 必须调用不予许删除

    self:addObservers()
    self:updateBetLevel()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local p_reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount or 0
    local p_reSpinsCurCount = self.m_runSpinResultData.p_reSpinCurCount or 0
    local p_resWinCoins = self.m_runSpinResultData.p_resWinCoins or 0
    local p_features = self.m_runSpinResultData.p_features or {}
    local wildCollectNum = selfData.wildCollectNum or 0
    local wildCollPro = self:getWildCollectProgress(wildCollectNum)
    self.m_fishJuese2.wildCollPro = wildCollPro
    -- self:updateFishPro(wildCollPro,true)
    if not self.m_bProduceSlots_InFreeSpin and p_reSpinsTotalCount <= 0 then
        self:showFortuneMode()
    end
    

end


function CodeGameScreenKoiBlissMachine:addObservers()
    CodeGameScreenKoiBlissMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画

            if self.m_isPlayLineSound == false then
                return
            end
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
            else
                soundIndex = 3
            end

            local soundTime = soundIndex
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = PublicConfig.SoundConfig["base_winLine_"..soundIndex] 
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                soundName = PublicConfig.SoundConfig["free_winLine_"..soundIndex]
            end
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    --bet切换
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )

    gLobalNoticManager:addObserver(self,function(self,params)
        self:pickGameShowJackpotView()
    end,"CodeGameScreenKoiBlissMachine_pickGameShowJackpotView")
end

function CodeGameScreenKoiBlissMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenKoiBlissMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    -- if self.m_wenanUpdateAction then
    --     self.m_totalWinKuang:stopAction(self.m_wenanUpdateAction)
    --     self.m_wenanUpdateAction = nil
    -- end
    if self.m_coinbonusUpdateAction then
        self.m_totalWinKuang:stopAction(self.m_coinbonusUpdateAction)
        self.m_coinbonusUpdateAction = nil
    end
end

--小块
function CodeGameScreenKoiBlissMachine:getBaseReelGridNode()
    return "CodeKoiBlissSrc.KoiBlissSlotsNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenKoiBlissMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_KoiBliss_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_KoiBliss_11"
    elseif symbolType == self.SYMBOL_BONUS_1 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        return "Socre_KoiBliss_Bouns1"
    elseif symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_KoiBliss_Bouns2"
    elseif symbolType == self.SYMBOL_KAIMEN then
        return "Socre_KoiBliss_MEN"
    elseif symbolType == self.SYMBOL_SCORE_0_HUI then
        return "Socre_KoiBliss_9_2"
    elseif symbolType == self.SYMBOL_SCORE_1_HUI then
        return "Socre_KoiBliss_8_2"
    elseif symbolType == self.SYMBOL_SCORE_2_HUI then
        return "Socre_KoiBliss_7_2"
    elseif symbolType == self.SYMBOL_SCORE_3_HUI then
        return "Socre_KoiBliss_6_2"
    elseif symbolType == self.SYMBOL_SCORE_4_HUI then
        return "Socre_KoiBliss_5_2"
    elseif symbolType == self.SYMBOL_SCORE_5_HUI then
        return "Socre_KoiBliss_4_2"
    elseif symbolType == self.SYMBOL_SCORE_6_HUI then
        return "Socre_KoiBliss_3_2"
    elseif symbolType == self.SYMBOL_SCORE_7_HUI then
        return "Socre_KoiBliss_2_2"
    elseif symbolType == self.SYMBOL_SCORE_8_HUI then
        return "Socre_KoiBliss_1_2"
    elseif symbolType == self.SYMBOL_SCORE_10_HUI then
        return "Socre_KoiBliss_10_2"
    elseif symbolType == self.SYMBOL_SCORE_11_HUI then
        return "Socre_KoiBliss_11_2"
    elseif symbolType == self.SYMBOL_BONUS_FAKER1 then
        return "Socre_KoiBliss_194"
    elseif symbolType == self.SYMBOL_BONUS_FAKER2 then
        return "Socre_KoiBliss_195"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenKoiBlissMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenKoiBlissMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_0_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_1_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_2_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_3_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_4_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_5_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_6_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_7_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_8_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11_HUI,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_1,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_2,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_KAIMEN,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_FAKER1,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_FAKER2,count = 2}


    return loadNode
end

----------------------------- 玩法处理 -----------------------------------
--通过reels里是否有95判断是否在respin中
function CodeGameScreenKoiBlissMachine:isInRespin()
    local p_reels = self.m_runSpinResultData.p_reels or {}
    local num = #p_reels
    for i=1,num do
        local data = p_reels[i]
        for i, type in ipairs(data) do
            if type == 94 then
                return false
            end
        end
    end
    return true
end

-- 断线重连
function CodeGameScreenKoiBlissMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local p_reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount or 0
    local p_reSpinsCurCount = self.m_runSpinResultData.p_reSpinCurCount or 0
    local p_resWinCoins = self.m_runSpinResultData.p_resWinCoins or 0
    local p_features = self.m_runSpinResultData.p_features or {}
    if #p_features > 0 and p_features[2] and p_features[2] == 3 then
        if self:isInRespin() then
            self.m_lightScore = p_resWinCoins
            self:changeReSpinStartUI(p_reSpinsCurCount)
        end
    else
        if p_reSpinsTotalCount > 0 then   --在respin里
            if p_reSpinsCurCount == 0 then
            else
                self.m_lightScore = p_resWinCoins
                self:changeReSpinStartUI(p_reSpinsCurCount)
            end
            
        elseif self.m_bProduceSlots_InFreeSpin then
            self:changeBgForStates(PublicConfig.fs)
        end
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenKoiBlissMachine:MachineRule_SpinBtnCall()
    self.m_scatteNum = 1
    self.m_symbolExpectCtr:MachineSpinBtnCall()

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_isLastRespin = false
    if self:getCurrSpinMode() == RESPIN_MODE then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1,true)
        if self.m_runSpinResultData.p_reSpinCurCount - 1 == 0 then
            self.m_isLastRespin = true
        end
        for col,symbolNodes in ipairs(self:findChild("clipLayer").m_symbolNodeTab) do
            for row,symbolNode in ipairs(symbolNodes) do
                symbolNode:setOriginalDistance(symbolNode:getPositionY())
            end
        end
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenKoiBlissMachine:requestSpinResult()
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or -1
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE and freeSpinsLeftCount == freeSpinsTotalCount then
        self.m_kaichang:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_door_trigger)
        self.m_kaichang:playAction("actionframe",false,function ()
            self.m_kaichang:setVisible(false)
            CodeGameScreenKoiBlissMachine.super.requestSpinResult(self)
        end)
    else
        CodeGameScreenKoiBlissMachine.super.requestSpinResult(self)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenKoiBlissMachine:slotOneReelDown(reelCol)
    CodeGameScreenKoiBlissMachine.super.slotOneReelDown(self, reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        -- 隐藏掉无效行
        local symbolNode = self:getFixSymbol(reelCol, 1, SYMBOL_NODE_TAG)
        symbolNode:setVisible(false)
    end
end

--[[
    滚轮停止
]]
function CodeGameScreenKoiBlissMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    if self:getCurrSpinMode() == RESPIN_MODE then
        self:clearClipLayer()
    end

    CodeGameScreenKoiBlissMachine.super.slotReelDown(self)
end

--清除裁切层
function CodeGameScreenKoiBlissMachine:clearClipLayer()
    self:findChild("clipLayer"):removeAllChildren()
    self:findChild("clipLayer"):setVisible(false)
    self:findChild("clipLayer").m_symbolNodeTab = {}
end

---------------------------------------------------------------------------

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenKoiBlissMachine:addSelfEffect()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local replaceMystery = fsExtraData.replaceMystery
    if self:getCurrSpinMode() == FREE_SPIN_MODE and replaceMystery and #replaceMystery > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.KAIMEN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.KAIMEN_EFFECT
    end

    local wild = selfData.wild
    if wild and #wild > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.WILDCOLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.WILDCOLLECT_EFFECT
    end

    self.m_pickGameWinCoins = 0
    local pickRound = selfData.pickRound
    if pickRound and pickRound[1] and #pickRound[1] > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BONUSGAME_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUSGAME_EFFECT

        for i,v in ipairs(selfData.pickRound[1]) do
            self.m_pickGameWinCoins = self.m_pickGameWinCoins + v.winValue
        end
    end

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local currentWinCoins = rsExtraData.currentWinCoins
    if currentWinCoins and currentWinCoins > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BONUS2LONG_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS2LONG_EFFECT
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenKoiBlissMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.KAIMEN_EFFECT then
        performWithDelay(
            self,
            function()
                self:kaiMenAction(effectData)
            end,
            0.5
        )
    elseif effectData.p_selfEffectType == self.BONUS2LONG_EFFECT then
        performWithDelay(self,function ()
            self:collectBonus2()
        end,0.5)
    elseif effectData.p_selfEffectType == self.WILDCOLLECT_EFFECT then
        self:collectWild(effectData)
    elseif effectData.p_selfEffectType == self.BONUSGAME_EFFECT then
        performWithDelay(self,function ()
            self:showPickGame()
        end,0.5)
    end
    return true
end


--开始pick小游戏
function CodeGameScreenKoiBlissMachine:showPickGame()
    local winLines = self.m_reelResultLines
    if #winLines <= 0 then          --目的：将多福多彩的钱数先减掉，防止刷新每一轮jackpot时钱数显示不对
        if self.m_pickGameWinCoins > 0 and globalData.slotRunData.lastWinCoin >= self.m_pickGameWinCoins then
            globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - self.m_pickGameWinCoins
        end
        
    end
    -- self.m_pickGameWinCoins1 = 0
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:checkClearWinLabel()
        globalData.slotRunData.lastWinCoin = 0
    end

    self:setMaxMusicBGVolume()
    self.m_currPickProgress = 1
    globalPlatformManager:deviceVibrate(6)
    self:clearCurMusicBg()
    self:clearWinLineEffect()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.jveSeNode:stopAllActions()
    --触发玩法
    self.m_fishJuese1.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.mid )
    self.m_fishJuese2.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.down)
    -- 播放鱼触发动画
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_trigger)
    self.shouji_bd:stopAllActions()
    self.shouji_bd:setVisible(true)
    util_spinePlay(self.shouji_bd,"actionframe_base")
    local bdTime = self.shouji_bd:getAnimationDurationTime("actionframe_base") 
    performWithDelay(self.shouji_bd,function ()
        self.shouji_bd:setVisible(false)
    end,bdTime)
    PublicConfig.fishRippleActionForJackpot(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos))
    util_spinePlay(self.m_fishJuese2,"actionframe")
    self.m_fishJuese2.m_actionName = "actionframe"
    util_spinePlay(self.m_fishJuese1,"actionframe")
    self:delayCallBack(4,function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_toPick_guochang)
        self:showGuochang(PublicConfig.pickStart,function ()
            self:changeBgForStates(PublicConfig.pick)
            self.m_pickGameLayer:setVisible(true)
            self.m_pickGameLayer:initView()
        end,function ()
            self:resetMusicBg(false,PublicConfig.SoundConfig.pickBgm)
            self.m_pickGameLayer:startGame()
        end)
    end)
    -- util_spineEndCallFunc(self.m_fishJuese2,"actionframe",function()
        
    -- end)
    
   
end

function CodeGameScreenKoiBlissMachine:pickGameShowJackpotView()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local winType = selfData.pickRound[1][self.m_currPickProgress].winJackpot[1]
    local index = 1
    if winType == "Grand" then
        index = 1
    elseif winType == "Major" then
        index = 2
    elseif winType == "Minor" then
        index = 3
    elseif winType == "Mini" then
        index = 4
    end
    local coins = selfData.pickRound[1][self.m_currPickProgress].winValue
    local params = {}
    params.jackpotType = winType
    params.winCoin = coins
    params.func = function()
        self.m_pickGameLayer:changeJackpotBarState(1)
        self:onePickGameEnd()
    end
    params.machine = self

    local jackPotWinView = util_createView("CodeKoiBlissSrc.KoiBlissJackpotWinView",params)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:findChild("Node_root"):setScale(self.m_machineRootScale)
    if winType == "Grand" then
        local light = util_createAnimation("KoiBliss_tanban_guang2.csb")
        jackPotWinView:findChild("guang"):addChild(light)
        light:runCsbAction("idle",true)
        local fishAnim = util_spineCreate("KoiBliss_yugao_tanban_yu",true,true) 
        jackPotWinView:findChild("yu"):addChild(fishAnim)
        util_spinePlay(fishAnim,"actionframe3",true)
        local fishAnim2 = util_spineCreate("KoiBliss_yugao_tanban_yu",true,true) 
        jackPotWinView:findChild("yu_2"):addChild(fishAnim2)
        util_spinePlay(fishAnim2,"actionframe5",true)
    else 
        local light = util_createAnimation("KoiBliss_tanban_guang1.csb")
        jackPotWinView:findChild("guang"):addChild(light)
        light:runCsbAction("idle",true)
        local fishAnim = util_spineCreate("KoiBliss_yugao_tanban_yu",true,true) 
        jackPotWinView:findChild("yu"):addChild(fishAnim)
        util_spinePlay(fishAnim,"actionframe2",true)
    end
    local winCoins = selfData.pickRound[1][self.m_currPickProgress].winValue
    -- self.m_pickGameWinCoins1 = self.m_pickGameWinCoins1 + winCoins
    -- local lastCoins = self.m_pickGameWinCoins1
    globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + winCoins
    
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    self.m_isPlayLineSound = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoins,false,true})
    self.m_isPlayLineSound = true
    
end

function CodeGameScreenKoiBlissMachine:onePickGameEnd()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    if selfData.pickRound[1][self.m_currPickProgress].selectPick == 1 then
        self.m_pickGameLayer:playPickAni(function ()
            self.m_currPickProgress = self.m_currPickProgress + 1

            self.m_pickGameLayer:playItemResetAinm(function()
                self.m_pickGameLayer:initView()
                self.m_pickGameLayer:startGame()
            end)
            
            
        end)
    else
        self:pickGameEnd()
    end
end

function CodeGameScreenKoiBlissMachine:pickGameEnd()
    self.m_bottomUI:notifyTopWinCoin()
    -- local isNotifyUpdateTop = true
    -- if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
    --     isNotifyUpdateTop = false
    -- end
    -- self.m_isPlayLineSound = false
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_pickGameWinCoins,isNotifyUpdateTop})
    -- self.m_isPlayLineSound = true
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        globalData.slotRunData.lastWinCoin = self.m_iOnceSpinLastWin
    end
    
    self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, self.BONUSGAME_EFFECT)
    self:clearCurMusicBg(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_guochang)
    self:showGuochang(PublicConfig.pickOver,function ()

        self.m_pickGameLayer:hideLayer()
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:changeBgForStates(PublicConfig.fs)
        else
            self:changeBgForStates(PublicConfig.base)
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_iOnceSpinLastWin))
        end
        PublicConfig.fishRippleAction1(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius,false)
    end,function ()
        self:resetMusicBg()
        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.BONUSGAME_EFFECT})
    end)
end

--创建裁切层的小块
function CodeGameScreenKoiBlissMachine:createClipSymbolNode(symbolType,_iCol,_iRow)
    local symbolNode = require(self:getBaseReelGridNode()):create()
    symbolNode:initOnExit()
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    symbolNode:initSlotNodeByCCBName(ccbName, symbolType)
    symbolNode.p_cloumnIndex = _iCol
    symbolNode.p_rowIndex = _iRow
    symbolNode.m_isLastSymbol = true
    self:updateReelGridNode(symbolNode)

    self:findChild("clipLayer"):addChild(symbolNode)
    symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) + _iCol * 10 - _iRow)

    local worldPos = self:getWorldPositionByColRow(_iCol,_iRow)
    local position = symbolNode:getParent():convertToNodeSpace(worldPos)
    symbolNode:setPosition(position)

    return symbolNode
end

--收集bonus2图标
function CodeGameScreenKoiBlissMachine:collectBonus2()
    -- 显示裁切层
    self:findChild("clipLayer"):setVisible(true)
    --在裁切层上添加跟轮盘上一样的图标
    for col = 1,self.m_iReelColumnNum do
        self:findChild("clipLayer").m_symbolNodeTab[col] = {}
    end

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local moveBonusDataTab = rsExtraData.moveBonus or {}
    if #moveBonusDataTab > 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_collect_bonus_move)
        --有上下拉，先拉一波
        local moveTime = 9/30
        for i,moveBonusData in ipairs(moveBonusDataTab) do
            local moveCol = moveBonusData[2] + 1
            local startRow = self.m_iReelRowNum - moveBonusData[1]
            local endRowColData = self:getRowAndColByPos(moveBonusData[3])

            for row = 1,self.m_iReelRowNum + 1 do
                local reelSymbolNode = self:getFixSymbol(moveCol, row, SYMBOL_NODE_TAG)
                reelSymbolNode:setVisible(false)
                local symbolNode = self:createClipSymbolNode(reelSymbolNode.p_symbolType,moveCol,row)
                symbolNode.flash = util_spineCreate("Socre_KoiBliss_Bouns2",true,true)
                symbolNode:addChild(symbolNode.flash,1111)
                symbolNode.flash:setVisible(false)
                table.insert(self:findChild("clipLayer").m_symbolNodeTab[moveCol],symbolNode)
            end

            endRowColData.iX = 3--需求都拉到轮盘中间行
            for j,symbolNode in ipairs(self:findChild("clipLayer").m_symbolNodeTab[moveCol]) do
                local difRow = endRowColData.iX - startRow
                symbolNode.p_rowIndex = symbolNode.p_rowIndex + difRow
                local worldPos = self:getWorldPositionByColRow(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex)
                local position = symbolNode:getParent():convertToNodeSpace(worldPos)

                local moveTo = cc.MoveTo:create(moveTime,position)
                if i == #moveBonusDataTab and j == #self:findChild("clipLayer").m_symbolNodeTab[moveCol] then
                    local delay = cc.DelayTime:create(0.2 + moveTime)
                    local callFunc = cc.CallFunc:create(function ()
                        self:clearClipLayer()
                        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
                        self:respinCollectBonus()
                    end)
                    local seq = cc.Sequence:create(moveTo,delay,callFunc)
                    symbolNode:runAction(seq)
                else
                    symbolNode:runAction(moveTo)
                end

                --修改目标位置的轮盘图标
                local reelSymbolNode = self:getFixSymbol(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, SYMBOL_NODE_TAG)
                if reelSymbolNode then
                    reelSymbolNode:clearLabelNode()
                    if reelSymbolNode.p_symbolImage ~= nil then
                        reelSymbolNode.p_symbolImage:removeFromParent()
                        reelSymbolNode.p_symbolImage = nil
                    end
                    reelSymbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolNode.p_symbolType), symbolNode.p_symbolType)
                    if symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
                        if difRow > 0 then
                            symbolNode:runAnim("idleframe1",true) 

                            -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_collect_bonus_move)
                            util_spinePlay(symbolNode.flash,"move1")
                            reelSymbolNode:runAnim("idleframe1",true) 
                            symbolNode.flash:setVisible(true)
                        else
                            symbolNode:runAnim("idleframe1",true) 

                            
                            util_spinePlay(symbolNode.flash,"move2")
                            reelSymbolNode:runAnim("idleframe1",true) 
                            symbolNode.flash:setVisible(true)
                        end
                    else
                        reelSymbolNode:runAnim("idleframe")
                    end
                    reelSymbolNode:updateLayer()
                    self:updateReelGridNode(reelSymbolNode)
                    reelSymbolNode:setLocalZOrder(self:getBounsScatterDataZorder(reelSymbolNode.p_symbolType) + reelSymbolNode.p_cloumnIndex * 10 - reelSymbolNode.p_rowIndex)
                end
            end

            --这里设计上是bonus2图标拉到轮盘中间 ，多拉的话这里就不适用了，重新搞吧
            if startRow > endRowColData.iX then
                local reelSymbolNode = self:getFixSymbol(moveCol, endRowColData.iX + 1, SYMBOL_NODE_TAG)
                if reelSymbolNode then
                    reelSymbolNode:setVisible(false)
                end

                for row = endRowColData.iX + 2,self.m_iReelRowNum + 1  do
                    local reelSymbolNode = self:getFixSymbol(moveCol, row, SYMBOL_NODE_TAG)
                    if reelSymbolNode then
                        reelSymbolNode:clearLabelNode()
                        local randSymbolType = math.random(0,10)
                        if reelSymbolNode.p_symbolImage ~= nil then
                            reelSymbolNode.p_symbolImage:removeFromParent()
                            reelSymbolNode.p_symbolImage = nil
                        end
                        reelSymbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, randSymbolType), randSymbolType)
                        reelSymbolNode:updateLayer()
                        reelSymbolNode:runAnim("idleframe1")
                    end
                end
            elseif startRow < endRowColData.iX then
                for row = 1,endRowColData.iX - 1  do
                    local reelSymbolNode = self:getFixSymbol(moveCol, row, SYMBOL_NODE_TAG)
                    if reelSymbolNode then
                        reelSymbolNode:setVisible(false)
                    end
                end
            end
        end

    else
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
        self:respinCollectBonus()
    end
end

-- 如果有不在正中心的bonus 需要拉到正中心
function CodeGameScreenKoiBlissMachine:changeBonus2ToMid()


end

--ReSpin刷新数量
function CodeGameScreenKoiBlissMachine:changeReSpinUpdateUI(curCount,isPlayAnimation)

    self.m_respinBar.updateNum(curCount)
    if isPlayAnimation == true then
        if curCount == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_rsNum_update)
            self.m_respinBar:runCsbAction("actionframe")
        end
    end
end

--收集bonus2
function CodeGameScreenKoiBlissMachine:respinCollectBonus()
    self.m_bonus2Tab = {}
    local time = 0
    for col = 1,self.m_iReelColumnNum do
        -- local slotParent = self:getReelParent(col)
        -- if slotParent then
        --     slotParent:getParent():setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE )
        -- end
        -- local slotBigParent = self:getReelBigParent(col)
        -- if slotBigParent then
        --     slotBigParent:getParent():setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000 )
        -- end
        for row = 2,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
            symbolNode:setVisible(true)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
                -- if slotParent then
                --     slotParent:getParent():setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + col)
                -- end
                -- if slotBigParent then
                --     slotBigParent:getParent():setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000 + col )
                -- end
                table.insert(self.m_bonus2Tab,symbolNode)
                -- symbolNode:runAnim("actionframe",false,function()
                --     symbolNode:runAnim("idleframe1",true) 
                -- end)
                symbolNode:setLocalZOrder(symbolNode:getLocalZOrder() *2)
                -- time = util_max(time, symbolNode:getAniamDurationByName("actionframe")) 
            end
        end
    end
    -- performWithDelay(self,function ()
        self:startCollectBonus2()
    -- end,time + 0.5)
end

function CodeGameScreenKoiBlissMachine:startCollectBonus2()
    if #self.m_bonus2Tab == 0 then
        performWithDelay(self,function ()
            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.BONUS2LONG_EFFECT})
        end,0.5)
        return
    end
    local symbolNode = self.m_bonus2Tab[1]
    table.remove(self.m_bonus2Tab,1)

    symbolNode:runAnim("shouji",false,function ()
        symbolNode:runAnim("idleframe3",true)
    end)

    --KoiBliss_yugao_yu1,actionframe_fankui
    local flyNode = util_spineCreate("KoiBliss_respin_shouji3",true,true)
    self:findChild("Node_rsFlyNode"):addChild(flyNode)  
    local index = self:getPosReelIdxForKoiBliss(symbolNode.p_rowIndex,symbolNode.p_cloumnIndex) or 1
    local animName = "shouji" .. index
    --flyNode:getAnimationDurationTime(animName)
    local time = 15/30
    util_spinePlay(flyNode,animName)
    local actionList = {}
    actionList[#actionList+1] = cc.DelayTime:create(time)
    actionList[#actionList+1] = cc.CallFunc:create(function ()
        --respin收集水波纹
        PublicConfig.fishRippleActionForRespin(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos))
        self.m_lightScore = self.m_lightScore + self.m_runSpinResultData.p_rsExtraData.bonus2WinCoins
        self:updateTotalWinKuang(true,function()
            self:startCollectBonus2()
        end)
        flyNode:removeFromParent()
    end)
    local seq = cc.Sequence:create(actionList)
    flyNode:runAction(seq)

end

function CodeGameScreenKoiBlissMachine:getPosReelIdxForKoiBliss(iRow, iCol)
    local index = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index + 1
end

--收集wild图标
function CodeGameScreenKoiBlissMachine:collectWild(_effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
     
    local pickRound = selfData.pickRound
    local immediatelyNextEffect = true
    if pickRound and pickRound[1] and #pickRound[1] > 0 then
        immediatelyNextEffect = false
    end


    local wildCollectNum = selfData.wildCollectNum or 0
    local wildCollPro = self:getWildCollectProgress(wildCollectNum)
    local waitTime = 0 -- 升级时需要等升级完毕再播触发动画
    if self.m_fishJuese2.wildCollPro ~= wildCollPro then
        waitTime = self.m_fishJuese2:getAnimationDurationTime("shengji" .. wildCollPro)
    elseif immediatelyNextEffect == false then
        waitTime = self.m_fishJuese2:getAnimationDurationTime("shengji" .. 3)   
    end

    local wild = selfData.wild
    if #wild > 0 then

        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_wild_collect_up )
    end
    
    for i,wildData in ipairs(wild) do
        local rowColData = self:getRowAndColByPos(wildData[1])
        local symbolNode = self:getFixSymbol(rowColData.iY,rowColData.iX,SYMBOL_NODE_TAG)
       
        local flySymbol = util_spineCreate("KoiBliss_Bonus_shouji1",true,true)
        self:findChild("Node_fly"):addChild(flySymbol,self:getBounsScatterDataZorder(symbolNode.p_symbolType) - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10)
        --棋盘wild图标动画
        local symbolAct = "shouji1"
        if self.m_iBetLevel >= 1 then
            symbolAct = "shouji2"
        end
        symbolNode:runAnim(symbolAct,false,function ()
            if self.m_iBetLevel >= 1 then
                symbolNode:runAnim("idleframe4",true)
            else
                symbolNode:runAnim("idleframe1",true)
            end
        end)
        local playName = "shouji" .. PublicConfig.wlildPlayId[wildData[1] + 1]
        
        util_spinePlay(flySymbol, playName)
        local time = flySymbol:getAnimationDurationTime(playName) - 0.5
        local actionList = {}
        actionList[#actionList+1] = cc.DelayTime:create(0.5)
        actionList[#actionList+1] = cc.CallFunc:create(function ()
            -- flySymbol:removeFromParent()
            if i == #wild then

                gLobalSoundManager:playSound(PublicConfig.SoundConfig.collFK )
                self:updateFishPro(wildCollPro,false,immediatelyNextEffect == false)
                -- if immediatelyNextEffect == false then
                --     performWithDelay(self,function()
                --         _effectData.p_isPlay = true
                --         self:playGameEffect()
                --     end,waitTime)
                -- end
            end
        end)
        actionList[#actionList+1] = cc.DelayTime:create(time)
        actionList[#actionList+1] = cc.CallFunc:create(function ()
            flySymbol:removeFromParent()
            if i == #wild then

                -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.collFK )
                -- self:updateFishPro(wildCollPro,false,immediatelyNextEffect == false)
                if immediatelyNextEffect == false then
                    performWithDelay(self,function()
                        _effectData.p_isPlay = true
                        self:playGameEffect()
                    end,waitTime)
                end
            end
        end)
        local seq = cc.Sequence:create(actionList)
        flySymbol:runAction(seq)
    end

    if immediatelyNextEffect == true then
        if self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
            performWithDelay(self,function ()
                _effectData.p_isPlay = true
                self:playGameEffect()
            end,0.5)
        elseif self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) or self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
            performWithDelay(self,function ()
                _effectData.p_isPlay = true
                self:playGameEffect()
            end,1.5)
        else
            _effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
end

--开门图标变为普通图标
function CodeGameScreenKoiBlissMachine:kaiMenAction(_effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local bonusNum = #selfData.storedIcons
    local kaimenNum = #fsExtraData.replaceMystery
    local wildNum = #selfData.wild
    local time = 0
    if kaimenNum > 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_door_show)
    end
    for i, kaimenSymbolData in ipairs(fsExtraData.replaceMystery) do
        local rowColData = self:getRowAndColByPos(kaimenSymbolData[1])
        local symbolNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, kaimenSymbolData[3]), kaimenSymbolData[3])
        symbolNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, kaimenSymbolData[3]))
        symbolNode:setVisible(true)
        self:updateReelGridNode(symbolNode)
       
        local kaimenSymbol = util_spineCreate("Socre_KoiBliss_MEN",true,true) 
        self.m_clipParent:addChild(kaimenSymbol, self:getBounsScatterDataZorder(symbolNode.p_symbolType) - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10)
        kaimenSymbol.m_row = symbolNode.p_rowIndex
        kaimenSymbol.m_col = symbolNode.p_cloumnIndex
        local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        local pos = kaimenSymbol:getParent():convertToNodeSpace(worldPos)
        kaimenSymbol:setPosition(pos)

        local bonusKenengNum = bonusNum + kaimenNum
        if self.m_iBetLevel > 0 then
            bonusKenengNum = bonusKenengNum + wildNum
        end
        if bonusKenengNum >= 6 then
        else
        end
        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolNode.p_symbolType == self.SYMBOL_BONUS_1 then
            symbolNode:runAnim("idleframe5")
        end
        util_spinePlay(kaimenSymbol,"actionframe")
        local animTime = kaimenSymbol:getAnimationDurationTime("actionframe")
        self:delayCallBack(15/30,function ()
            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                if self.m_iBetLevel >= 1 then
                    symbolNode:runAnim("show1")
                else
                    symbolNode:runAnim("show")
                end 
            else
                symbolNode:runAnim("show")
            end
            
            -- symbolNode:setScale(0.25)
            -- util_playScaleToAction(symbolNode,0.5, 1)

        end)
        time = util_max(time,animTime)
        performWithDelay(
            kaimenSymbol,
            function()
                kaimenSymbol:removeFromParent()
            end,
            animTime
        )
    end

    performWithDelay(
        self,
        function()
            _effectData.p_isPlay = true
            self:playGameEffect()
        end,
        time
    )
end

function CodeGameScreenKoiBlissMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenKoiBlissMachine.super.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- free和freeMore特殊需求
function CodeGameScreenKoiBlissMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_free_more)
        else
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        end
    end
end

-- 不用系统音效
function CodeGameScreenKoiBlissMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenKoiBlissMachine.super.checkSymbolTypePlayTipAnima(self, symbolType)
    end

    return false
end

function CodeGameScreenKoiBlissMachine:checkRemoveBigMegaEffect()
    CodeGameScreenKoiBlissMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenKoiBlissMachine:getShowLineWaitTime()
    local time = CodeGameScreenKoiBlissMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------

function CodeGameScreenKoiBlissMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeKoiBlissSrc.KoiBlissFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_fgbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点
end

function CodeGameScreenKoiBlissMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("KoiBlissSounds/music_KoiBliss_custom_enter_fs.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_free_more_show)
            local view =
                self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_free_num_add)
                    self.m_baseFreeSpinBar:runCsbAction("actionframe")
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
            local fishAnim = util_spineCreate("KoiBliss_yugao_tanban_yu",true,true) 
            view:findChild("Node_yu"):addChild(fishAnim)
            util_spinePlay(fishAnim,"actionframe1",true)
            view:findChild("Node_root"):setScale(self.m_machineRootScale)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_baseToFree_guochang)
            self:showGuochang(PublicConfig.fsStart,function ()
                self:changeBgForStates(PublicConfig.fs)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_freeStart_show)
                local view =
                    self:showFreeSpinStart(
                    self.m_iFreeSpinTimes,
                    function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
                view:setBtnClickFunc(function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.click)
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_freeStart_hide)
                end)
                local fishAnim = util_spineCreate("KoiBliss_yugao_tanban_yu",true,true) 
                view:findChild("Node_yu"):addChild(fishAnim)
                util_spinePlay(fishAnim,"actionframe1",true)
                view:findChild("Node_root"):setScale(self.m_machineRootScale)
            end)

            
        end
    end

    self:delayCallBack(
        0.5,
        function()
            showFSView()  
        end
    )
end

function CodeGameScreenKoiBlissMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("KoiBlissSounds/music_KoiBliss_over_fs.mp3")
    --globalData.slotRunData.lastWinCoin
    self:clearCurMusicBg()
    local strCoins = tonumber(self.m_runSpinResultData.p_fsWinCoins)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_freeOver_show)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_freeToBase_guoChang)
            self:showGuochang(PublicConfig.fsStart,function ()
                self:changeBgForStates(PublicConfig.base)
                self:triggerFreeSpinOverCallFun()
            end)
        end
    )
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_freeOver_hide)
    end)
    local fishAnim = util_spineCreate("KoiBliss_yugao_tanban_yu",true,true) 
    view:findChild("Node_yu"):addChild(fishAnim)
    util_spinePlay(fishAnim,"actionframe2",true)
    view:findChild("Node_root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenKoiBlissMachine:showFreeSpinOver(coins, num, func)
    if not coins or coins <= 0 then
        return self:showDialog("NoWin", {}, func)
    else
        local view = CodeGameScreenKoiBlissMachine.super.showFreeSpinOver(self,util_formatCoins(coins,50), num, func)
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 0.97, sy = 1}, 633)
        return view
    end
end

function CodeGameScreenKoiBlissMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
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

    performWithDelay(
        self,
        function()
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                -- 停掉背景音乐
                self:clearCurMusicBg()
                -- freeMore时不播放
                self:levelDeviceVibrate(6, "free")
            end
            local waitTime = 0
            if scatterLineValue ~= nil then
                -- 播放提示时播放音效
                self:playScatterTipMusicEffect()
                local frameNum = scatterLineValue.iLineSymbolNum
                for i = 1, frameNum do
                    local symPosData = scatterLineValue.vecValidMatrixSymPos[i]
                    local slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    if slotNode then
                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, scatterLineValue.enumSymbolType, 0)
                        end
                        slotNode:runAnim("actionframe")
                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime, duration)
                    end
                end
                scatterLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            else
                if device.platform == "mac" then
                    assert(false, "服务器没给连线数据")
                end
            end
            performWithDelay(
                self,
                function()
                    self:showFreeSpinView(effectData)
                end,
                waitTime
            )
        end,
        0.5
    )
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenKoiBlissMachine:showRespinView(effectData)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    else
        --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:checkClearWinLabel()
    end
    --触发respin
    --先播放动画 再进入respin
    self:stopLinesWinSound()
    self.m_specialReels = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:clearWinLineEffect()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    -- 停掉背景音乐
    self:clearCurMusicBg()
    --触发玩法
    self.m_lightScore = self.m_runSpinResultData.p_resWinCoins
    if self:isInitRespin() == true then

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bonus_trigger)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bonus_trigger2)
        end
        
        --播触发动画
        local time = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 2, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == self.SYMBOL_BONUS_1 then
                        slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
                        slotNode:runAnim("actionframe",false,function ()
                            slotNode:runAnim("idleframe1",true)
                        end)
                        time = util_max(slotNode:getAniamDurationByName("actionframe"),time) 
                    end
                    if self.m_iBetLevel > 0 and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
                        slotNode:runAnim("actionframe2",false,function ()
                            if self.m_iBetLevel >= 1 then
                                slotNode:runAnim("idleframe4",true)
                            else
                                slotNode:runAnim("idleframe1",true)
                            end
                        end)
                        time = util_max(slotNode:getAniamDurationByName("actionframe3"),time) 
                    end
                end
            end
        end
        performWithDelay(self,function ()

            self:showRespinWenanCollectBonus(function()
                self.m_reelZhezhao:playAction("over",false,function ()
                    self.m_reelZhezhao:setVisible(false)
                    for i,bonus1 in ipairs(self.m_bonus1Tab) do
                        bonus1:removeFromParent()
                    end
                    self.m_bonus1Tab = {}
                end)
                self.m_wenan:playAction("over",false,function ()
                    self.m_wenan:setVisible(false)
                end)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_toRespin_guochang)
                self:showGuochang(PublicConfig.rsStart,function ()
                    self:setReelSymbolToAn()
                    self:setCurrSpinMode( RESPIN_MODE )
                    self:changeBgForStates(PublicConfig.rs)
                    self:resetMusicBg()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                end,function()
                    self:showReSpinStart(function ()
                        --  self:setCurrSpinMode( RESPIN_MODE )
                         self:notifyGameEffectPlayComplete(GameEffect.EFFECT_RESPIN)
                    end)
                end)
            end)
            
        end,time + 0.5)
    else
        self:setCurrSpinMode( RESPIN_MODE )
        self:setReelSymbolToAn()
        self:resetMusicBg()
        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

--ReSpin开始改变UI状态
function CodeGameScreenKoiBlissMachine:changeReSpinStartUI(curCount)
    -- self:resetMusicBg()
    self.m_respinBar:setVisible(true)
    self:changeBgForStates(PublicConfig.rs)
    self:changeReSpinUpdateUI(curCount)
    self:updateTotalWinKuang()
end

function CodeGameScreenKoiBlissMachine:showReSpinStart(func)
    self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) --检测删除freeover Effect
    
    -- local ownerlist={}
    local totalbet = globalData.slotRunData:getCurTotalBet()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local coins = rsExtraData.bonus2Multiple * totalbet
    self.respinStartView:setVisible(true)
    self.respinDark:setVisible(true)
    self.respinStartView:showView(coins)
    self.respinStartView:setEndFunc(function ()
        self.respinDark:setVisible(false)
        self.respinStartView:setVisible(false)
        if func then
            func()
        end
    end)
    -- ownerlist["m_lb_coins"] = util_formatCoins(coins, 3)
    -- local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,ownerlist,func)

    -- local tanbanBG = util_spineCreate("KoiBliss_juese",true,true)
    -- view:findChild("Node_guangquan"):addChild(tanbanBG)
    -- util_spinePlay(tanbanBG,"tanban_BG",true)
    

    -- local node = view:findChild("m_lb_coins")
    -- view:updateLabelSize({label = node,sx = 0.85,sy = 0.85},216)

    -- view:setBtnClickFunc(function ()
    --     gLobalSoundManager:playSound(PublicConfig.SoundConfig.click)
    -- end)
    -- view.m_btnTouchSound = SoundConfig.GOLDCAULDRON_SOUND_6
    -- view:findChild("Node_root"):setScale(self.m_machineRootScale)
end

--显示respin文案收集bonus1
function CodeGameScreenKoiBlissMachine:showRespinWenanCollectBonus(_func)
    self.m_collectEndFunc = _func
    self.m_reelZhezhao:setVisible(true)
    self.m_reelZhezhao:playAction("start")
    self.m_wenan:setVisible(true)
    self.m_wenan.m_showCoins = 0
    -- self.wenAnTotalCoins = 0
    self.m_wenan:findChild("m_lb_coins"):setString(self.m_wenan.m_showCoins)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_wenan_show)
    self.m_wenan:playAction("start",false,function ()
        self.m_wenan:playAction("idle",true)
        performWithDelay(self,function()
            self:collectBonus1()
        end,0.5)
        
    end)

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.storedIcons then
        --文案层创建图标
        self.m_bonus1Tab = {}
        self.m_bonus1Index = 1
        for i,data in ipairs(selfData.storedIcons) do
            local rowcoldata = self:getRowAndColByPos(data[1])
            local reelSymbol = self:getFixSymbol(rowcoldata.iY, rowcoldata.iX, SYMBOL_NODE_TAG)

            local collectNode = util_spineCreate("Socre_KoiBliss_Bouns1",true,true) 
            local label = util_createAnimation("Socre_KoiBliss_Bouns1_Lab.csb")
            label:findChild("m_lb_coins"):setString(util_formatCoins(data[3], 3))
            collectNode:addChild(label)
            collectNode.m_labNode = label
            self:setBonusZiVisible(collectNode,data[3])
            self:findChild("Node_respinwenan"):addChild(collectNode)
            collectNode.m_row = rowcoldata.iX
            collectNode.m_col = rowcoldata.iY
            collectNode.m_coins = data[3]
            table.insert(self.m_bonus1Tab,collectNode)
            local worldPos = reelSymbol:getParent():convertToWorldSpace(cc.p(reelSymbol:getPosition()))
            local pos = collectNode:getParent():convertToNodeSpace(worldPos)
            collectNode:setPosition(pos)
            util_spinePlay(collectNode,"idleframe1",true)
        end
    end
    table.sort(self.m_bonus1Tab,function (a,b)
        if a.m_col == b.m_col then
            return a.m_row > b.m_row
        end
        return a.m_col < b.m_col
    end)
end

function CodeGameScreenKoiBlissMachine:updateWenanCollectCoins(addCoins)
    if self.m_wenanUpdateAction then
        self.m_totalWinKuang:stopAction(self.m_wenanUpdateAction)
        self.m_wenanUpdateAction = nil
        self.m_wenan:findChild("m_lb_coins"):setString(util_formatCoins(self.wenAnTotalCoins,3))
    end

    

    local realCoins = self.m_wenan.m_showCoins + addCoins
    self.wenAnTotalCoins = realCoins
    local showTime = 0.1
    local coinRiseNum = addCoins / (showTime * 60)  -- 每秒60帧

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)
    self.m_wenanUpdateAction = schedule(self.m_wenan,function()
        self.m_wenan.m_showCoins = self.m_wenan.m_showCoins + coinRiseNum
        if self.m_wenan.m_showCoins > realCoins then
            self.m_wenan.m_showCoins = realCoins
        end
        self.m_wenan:findChild("m_lb_coins"):setString(util_formatCoins(self.m_wenan.m_showCoins,3))
        if self.m_wenan.m_showCoins >= realCoins then
            self.m_wenan.m_showCoins = realCoins
            if self.m_wenanUpdateAction then
                self.m_totalWinKuang:stopAction(self.m_wenanUpdateAction)
                self.m_wenanUpdateAction = nil
            end
        end
    end,1/60)

    -- self.m_wenan.m_showCoins = self.m_wenan.m_showCoins + addCoins
    -- self.m_wenan:findChild("m_lb_coins"):setString(util_formatCoins(self.m_wenan.m_showCoins,3))
end

function CodeGameScreenKoiBlissMachine:collectBonus1()
    if self.m_bonus1Index > #self.m_bonus1Tab then
        performWithDelay(self,function ()
            if self.m_collectEndFunc then
                self.m_collectEndFunc()
            end
        end,0.5)
        return
    end
    local collectNode = self.m_bonus1Tab[self.m_bonus1Index]
    self.m_bonus1Index = self.m_bonus1Index + 1
    util_spinePlay(collectNode,"shouji")
    local flySymbol = util_spineCreate("KoiBliss_Bonus_shouji2",true,true)
    self:findChild("Node_respinwenan"):addChild(flySymbol)
    local posIdx = self:getPosReelIdx(collectNode.m_row, collectNode.m_col) 
    local playName = "shouji" .. PublicConfig.wlildPlayId[posIdx + 1]
    util_spinePlay(flySymbol, playName)
    local time = flySymbol:getAnimationDurationTime(playName) - 0.1
    local isEnd = false
    if self.m_bonus1Index <= #self.m_bonus1Tab then
        performWithDelay(self,function ()
            self:collectBonus1()
        end,0.4)
    else
        isEnd = true
    end
    local actionList = {}
    actionList[#actionList+1] = cc.DelayTime:create(time)
    actionList[#actionList+1] = cc.CallFunc:create(function ()
        self:addWenAnCois(collectNode.m_coins)
        util_resetCsbAction(self.m_wenan.m_fankui.m_csbAct)
        self.m_wenan.m_fankui:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bonus_collect)
        self.m_wenan.m_fankui:playAction("actionframe",false,function()
            self.m_wenan.m_fankui:setVisible(false)
        end)

    end)
    actionList[#actionList+1] = cc.DelayTime:create(0.1)
    actionList[#actionList+1] = cc.CallFunc:create(function ()
        flySymbol:removeFromParent()
        if isEnd == true then
            self:collectBonus1()
        end
    end)

    local seq = cc.Sequence:create(actionList)
    flySymbol:runAction(seq)

end

function CodeGameScreenKoiBlissMachine:addWenAnCois(addCoins)
    self:updateWenanCollectCoins(addCoins)
    -- self.m_wenan.m_showCoins = self.m_wenan.m_showCoins + addCoins
    -- self.m_wenan:findChild("m_lb_coins"):setString(util_formatCoins(self.m_wenan.m_showCoins,3))
end

--是不是respin触发轮
function CodeGameScreenKoiBlissMachine:isInitRespin()
    if self.m_runSpinResultData.p_features and self.m_runSpinResultData.p_features[2] then
        if self.m_runSpinResultData.p_features[2] == 3 and (self.m_runSpinResultData.p_rsExtraData.currentWinCoins == nil or self.m_runSpinResultData.p_rsExtraData.currentWinCoins == 0)  then
            return true
        end
    end
    return false
end


--图标变暗
function CodeGameScreenKoiBlissMachine:setReelSymbolToAn()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum + 1 do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if iRow == self.m_iReelRowNum + 1 then
                    slotNode:clearLabelNode()
                    if slotNode.p_symbolImage ~= nil then
                        slotNode.p_symbolImage:removeFromParent()
                        slotNode.p_symbolImage = nil
                    end
                    if slotNode.p_symbolType <= 10 then
                        slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, slotNode.p_symbolType + 20), slotNode.p_symbolType + 20)
                    else
                        local randSymbolType = math.random(20,30)
                        slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, randSymbolType), randSymbolType)
                    end
                    slotNode:runAnim("idleframe")
                    self:updateReelGridNode(slotNode)
                    slotNode:setLocalZOrder(self:getBounsScatterDataZorder(slotNode.p_symbolType) + slotNode.p_cloumnIndex * 10 - slotNode.p_rowIndex)
                else
                    if slotNode.p_symbolType <= 10 then
                        slotNode:clearLabelNode()
                        if slotNode.p_symbolImage ~= nil then
                            slotNode.p_symbolImage:removeFromParent()
                            slotNode.p_symbolImage = nil
                        end
                        slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, slotNode.p_symbolType + 20), slotNode.p_symbolType + 20)
                        slotNode:runAnim("idleframe")
                        self:updateReelGridNode(slotNode)
                        slotNode:setLocalZOrder(self:getBounsScatterDataZorder(slotNode.p_symbolType) + slotNode.p_cloumnIndex * 10 - slotNode.p_rowIndex)
                    end
                end
            end
        end
    end
end

--图标变亮
function CodeGameScreenKoiBlissMachine:setReelSymbolToLiang()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum + 1 do
            local symbolType = 0
            if iRow == 1 or iRow == self.m_iReelRowNum + 1 then
                symbolType = math.random(0,10)
            else
                local selfDataReels = self.m_runSpinResultData.p_selfMakeData.reels
                symbolType = selfDataReels[self.m_iReelRowNum - iRow + 1][iCol]
            end
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            slotNode:clearLabelNode()
            if slotNode.p_symbolImage ~= nil then
                slotNode.p_symbolImage:removeFromParent()
                slotNode.p_symbolImage = nil
            end
            slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
            self:updateReelGridNode(slotNode)
            slotNode:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) + slotNode.p_cloumnIndex * 10 - slotNode.p_rowIndex)
            slotNode.p_showOrder = self:getBounsScatterDataZorder(symbolType) + slotNode.p_cloumnIndex * 10 - slotNode.p_rowIndex
            self:changeBaseParent(slotNode)
            if slotNode.p_symbolType == self.SYMBOL_BONUS_1 then
                slotNode:runAnim("idleframe1",true)
            elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                if self.m_iBetLevel >= 1 then
                    slotNode:runAnim("idleframe4",true)
                else
                    slotNode:runAnim("idleframe1",true)
                end
            else
                slotNode:runAnim("idleframe")
            end
        end
        local reel = clone(self.m_runSpinResultData.p_selfMakeData.reels)
        table.insert( reel, 1, {math.random(0,10),math.random(0,10),math.random(0,10),math.random(0,10),math.random(0,10)})
        local slotParentDatas = self.m_slotParents
        local parentData = slotParentDatas[iCol]
        self:changeSlotsParentZOrder(0,parentData,parentData.slotParent,reel)
    end

    
end

function CodeGameScreenKoiBlissMachine:addFreespinOverEff()
    if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        local freeSpinEffect = GameEffectData.new()
        freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
        freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
        self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
    end
end

function CodeGameScreenKoiBlissMachine:changeReSpinOverViewUI()
    self:setReelSymbolToLiang()
    self.m_respinBar:setVisible(false)
    if self.m_bProduceSlots_InFreeSpin then
        self:changeBgForStates(PublicConfig.fs)
    else
        self:changeBgForStates(PublicConfig.base)
    end
    PublicConfig.fishRippleAction1(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius,false)
end

function CodeGameScreenKoiBlissMachine:showRespinOverView(effectData)

    self.m_totalWinKuang.m_fkCoinsTop:setVisible(true)
    self.m_totalWinKuang.m_fkCoinsDown:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_rsTotal_win)
    util_spinePlay(self.m_totalWinKuang.m_fkCoinsTop,"actionframe")
    util_spinePlay(self.m_totalWinKuang.m_fkCoinsDown,"actionframe")
    util_spineEndCallFunc(self.m_totalWinKuang.m_fkCoinsTop,"actionframe",function()
        -- 停掉背景音乐
        self:clearCurMusicBg()
        local strCoins = util_formatCoins(self.m_serverWinCoins, 50)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_rsOver_show)
        local view =
            self:showReSpinOver(
            strCoins,
            function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_respin_guochang)
                self:showGuochang(PublicConfig.rsOver,function ()
                    self.m_totalWinKuang.m_fkCoinsTop:setVisible(false)
                    self.m_totalWinKuang.m_fkCoinsDown:setVisible(false) 
                    self:resetReSpinMode()
                    self:changeReSpinOverViewUI()
                end,function ()
                    self:addFreespinOverEff()
                    effectData.p_isPlay = true
                    self:triggerReSpinOverCallFun(self.m_lightScore)
                    self.m_lightScore = 0
                    self:stopLinesWinSound()
                    self:resetMusicBg()
                end)
            end
        )
        view:setBtnClickFunc(
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_rsOver_hide)
        end
        )
        -- gLobalSoundManager:playSound("KoiBlissSounds/music_KoiBliss_linghtning_over_win.mp3")
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 0.97, sy = 1}, 633)
        view:findChild("Node_root"):setScale(self.m_machineRootScale)
    end)
   
end

function CodeGameScreenKoiBlissMachine:MachineRule_respinTouchSpinBntCallBack()
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

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN then -- 表明滚动了起来。。
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end


function CodeGameScreenKoiBlissMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)

end

function CodeGameScreenKoiBlissMachine:setReelRunInfo()
    -- assert(nil, "自己配置快滚信息")
    local reels = self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    local longRunConfigs = {}
    table.insert(longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"], ["symbolType"] = {90}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenKoiBlissMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenKoiBlissMachine.super.MachineRule_ResetReelRunData(self)
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenKoiBlissMachine:isPlayExpect(reelCol)
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
function CodeGameScreenKoiBlissMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为30%
        local probability = 40
        if _probability then
            probability = _probability
        end
        local isNotice = (math.random(1, 100) <= probability) 
        if features[2] == SLOTO_FEATURE.FEATURE_FREESPIN or features[2] == SLOTO_FEATURE.FEATURE_RESPIN then
            return isNotice 
        end
    end
    
    -- return true
    return false
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenKoiBlissMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance() then 
        --播放预告中奖动画
        self:playFeatureNoticeAni(
            function()
                if type(_func) == "function" then
                    _func()
                end
            end
        )
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
function CodeGameScreenKoiBlissMachine:playFeatureNoticeAni(func)
  
    self.b_gameTipFlag = true
    local aniTime = 0

    local features = self.m_runSpinResultData.p_features or {}
    if features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_free_yuGao)
        self.m_fsStartYg:setVisible(true)
        self.m_fsStartYg:runCsbAction("actionframe_yugao",false,function()
            self.m_fsStartYg:setVisible(false)
        end)
        aniTime = 150/60
    elseif features[2] == SLOTO_FEATURE.FEATURE_RESPIN then
        aniTime = self:playRsYuGaoAnim()
    end
 


    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()
    --预告中奖时间比滚动时间短,直接返回即可
    if aniTime <= delayTime then
        if type(func) == "function" then
            func()
        end
    else
        self:delayCallBack(
            aniTime - delayTime,
            function()
                if type(func) == "function" then
                    func()
                end
            end
        )
    end
end

--[[
        des:获取连线赢钱
        能通过其他简单的方式获取连线赢钱的时候就重写下该接口
        目前是通过for循环的形式获取的赢钱数，感觉有些浪费
    ]]
function CodeGameScreenKoiBlissMachine:getLinsWinCoins()
    local lineWinCoins = 0
    local lines = self.m_runSpinResultData.p_winLines or {}
    for _, lineInfo in ipairs(lines) do
        local p_amount = lineInfo.p_amount
        lineWinCoins = lineWinCoins + p_amount
    end
    return lineWinCoins
end

--[[
        des:通知更新结算框赢钱（底栏）
        winCoins：          本次增加的赢钱
        isNotifyUpdateTop： 是否刷新顶栏
        isPlayAni：         是否滚动上涨
        isNotPlayLineSound   是否不播放赢钱音效
    ]]
function CodeGameScreenKoiBlissMachine:notifyUpdateWinCoin(winCoins, isNotifyUpdateTop, isPlayAni, isNotPlayLineSound)
    local lastWinCoins = globalData.slotRunData.lastWinCoin
    lastWinCoins = lastWinCoins + winCoins
    globalData.slotRunData.lastWinCoin = lastWinCoins
    local params = {}
    params[1] = winCoins --本次增加的赢钱
    params[2] = isNotifyUpdateTop --是否刷新顶栏
    if isPlayAni ~= nil then
        params[3] = isPlayAni --是否以跳动的方式刷新底栏
    end
    if isNotPlayLineSound ~= nil then
        params[self.m_stopUpdateCoinsSoundIndex] = isNotPlayLineSound --是否不播放赢钱音效
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
end

--[[
        @desc: 处理用户的spin赢钱信息
        time:2020-07-10 17:50:08
    ]]
-- function CodeGameScreenKoiBlissMachine:operaWinCoinsWithSpinResult(param)
--     local spinData = param[2]
--     local userMoneyInfo = param[3]
--     self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
--     --发送测试赢钱数
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN, self.m_serverWinCoins)
--     globalData.userRate:pushCoins(self.m_serverWinCoins)

--     if spinData.result.freespin.freeSpinsTotalCount == 0 then --处理非free的赢钱
--         self:setLastWinCoin(0)
--     else --处理free的赢钱
--         --[[
--             *************************************************************
--             spinData.result.freespin.fsWinCoins要保证这个字段在freeGame中表示
--             的是当前freeGame累计的总赢钱,如不是找服务器协商解决
--             *************************************************************
--         ]]
--         local lasetWin = spinData.result.freespin.fsWinCoins - spinData.result.winAmount
--         self:setLastWinCoin(lasetWin)
--     end
--     globalData.userRunData.coinNum = userMoneyInfo.resultCoins
-- end

function CodeGameScreenKoiBlissMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self.m_pickGameWinCoins > 0 and globalData.slotRunData.lastWinCoin >= self.m_pickGameWinCoins then     
        --目的：将多福多彩的钱数先减掉，防止刷新每一轮jackpot时钱数显示不对
         globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - self.m_pickGameWinCoins
        local LinesCoins = self.m_iOnceSpinLastWin - self.m_pickGameWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {LinesCoins, false})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end

    
end

--freespin下的respin钱停留在win框 
function CodeGameScreenKoiBlissMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE  then
        if self.m_bProduceSlots_InFreeSpin == true then
            local isClearWin = false
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN,isClearWin)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
        end
    else
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    end
end
-- function CodeGameScreenKoiBlissMachine:checkNotifyUpdateWinCoin()
--     local winLines = self.m_reelResultLines
--     if #winLines <= 0  then
--         return
--     end
--     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
--     local isNotifyUpdateTop = true
--     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
--         isNotifyUpdateTop = false
--     end
--     local showCoins = self.m_iOnceSpinLastWin
--     local lastWinCoin = globalData.slotRunData.lastWinCoin
--     local beginCoins = nil
--     if self.m_pickGameWinCoins > 0 then
--         globalData.slotRunData.lastWinCoin = 0
--         showCoins = showCoins - self.m_pickGameWinCoins

--         if self:getCurrSpinMode() == FREE_SPIN_MODE then
--             local fsTotalWinCoins = self.m_runSpinResultData.p_fsWinCoins
--             beginCoins = fsTotalWinCoins - self.m_runSpinResultData.p_winAmount
--             showCoins = showCoins + beginCoins
--         end
--     end
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{showCoins,isNotifyUpdateTop,true,beginCoins})
--     globalData.slotRunData.lastWinCoin = lastWinCoin
-- end

function CodeGameScreenKoiBlissMachine:updateBetLevel()
    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 1
    else
        local betCoin = globalData.slotRunData:getCurTotalBet()
        if self.m_specialBets and #self.m_specialBets > 0 then
            self.m_iBetLevel = #self.m_specialBets
            for i = 1, #self.m_specialBets do
                if betCoin < self.m_specialBets[i].p_totalBetValue then
                    self.m_iBetLevel = i - 1
                    break
                end
            end
        else
            self.m_iBetLevel = 0
        end
    end

    if self.m_iBetLevel > 0 then
        self:lockUIBarUnLock()
    else
        self:lockUIBarLock()
    end
    self.m_isFirstChangeBet = false
end

function CodeGameScreenKoiBlissMachine:lockUIBarUnLock()
    if self.m_lockUIBar.m_state ~= 1 then
        self.m_lockUIBar.m_state = 1
        util_resetCsbAction(self.m_lockUIBar.m_csbAct)
        if self.m_isFirstChangeBet == true then
            self.m_lockUIBar:playAction("idle", true)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bet_unLock)
            self.m_lockUIBar:playAction(
                "unlock",
                false,
                function()
                    self.m_lockUIBar:playAction("idle", true)
                end
            )
        end
        self.m_lockUIBar:findChild("Panel_unlock"):setVisible(false)
        self.m_lockUIBar:findChild("Panel_tip"):setVisible(true)
    end
end

function CodeGameScreenKoiBlissMachine:lockUIBarLock()
    if self.m_lockUIBar.m_state ~= 0 then
        self.m_lockUIBar.m_state = 0
        util_resetCsbAction(self.m_lockUIBar.m_csbAct)
        if self.m_isFirstChangeBet == true then
            self.m_lockUIBar:playAction("idle1", true)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bet_lock)
            self.m_lockUIBar:playAction(
                "lock",
                false,
                function()
                    self.m_lockUIBar:playAction("idle1", true)
                end
            )
        end
        self.m_lockUIBar:findChild("Panel_unlock"):setVisible(true)
        self.m_lockUIBar:findChild("Panel_tip"):setVisible(false)
    end
end

function CodeGameScreenKoiBlissMachine:showFortuneMode()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bet_show)
    local view =
        self:showDialog(
        "ModeKoiBliss",
        {m_lb_coins = util_formatCoins(self.m_specialBets[1].p_totalBetValue, 30)},
        function(senderName)
            if senderName == "Button_gaobet" then
                
                self:unlockHigherBet()
            end
        end
    )
    -- view.m_btnTouchSound = 
    view:setBtnClickFunc(
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bet_hide)
        end
    )
    view:setPosition(display.center)
    view:findChild("Node_root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenKoiBlissMachine:unlockHigherBet()
    if self.m_iBetLevel >= 1 then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_specialBets[1].p_totalBetValue then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenKoiBlissMachine:playSymbolBulingAnim(nodes, speedActionTable)
    for i=1,#nodes do
        local symbolNode = nodes[i]
        if symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
            if symbolNode.p_rowIndex > 1 and symbolNode.p_rowIndex <= self.m_iReelRowNum   then
                self:showBonus2Lighting(symbolNode)
                symbolNode:runAnim("buling",false,function()
                    symbolNode:runAnim("idleframe1",true) 
                end) 
            end
        end
    end
    CodeGameScreenKoiBlissMachine.super.playSymbolBulingAnim(self,nodes, speedActionTable)
end

function CodeGameScreenKoiBlissMachine:showBonus2Lighting(symbolNode)
    local pos = util_convertToNodeSpace(symbolNode,self:findChild("root"))
    local tempLight = util_spineCreate("KoiBliss_Bouns2_bulingtx",true,true)
    self:findChild("root"):addChild(tempLight,1000)
    tempLight:setPosition(pos)
    util_spinePlay(tempLight,"buling")
    util_spineEndCallFunc(tempLight,"buling",function()
        self:delayCallBack(0.1,function()
            tempLight:removeFromParent()
        end)
    end)
end

function CodeGameScreenKoiBlissMachine:updateReelGridNode(symbolNode)

    symbolNode.p_reelDownRunAnima = nil
    symbolNode.p_reelDownRunAnimaSound = nil
    symbolNode.p_reelDownRunAnimaTimes = nil

    if symbolNode.p_symbolType == self.SYMBOL_BONUS_1 then
        symbolNode:runAnim("idleframe1",true)
        symbolNode:addLabel()
        local totalbet = globalData.slotRunData:getCurTotalBet()
        local iCol = symbolNode.p_cloumnIndex
        local iRow = symbolNode.p_rowIndex

        if iRow ~= nil and iRow >= 2 and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            local posIdx = self:getPosReelIdx(iRow, iCol)
            local coinsTab = self.m_runSpinResultData.p_selfMakeData.storedIcons
            local coins = 0
            if coinsTab then
                for i,v in ipairs(coinsTab) do
                    if v[1] == posIdx then
                        coins = v[3]
                        break
                    end
                end
            end
            if coins ~= nil then
                self:setBonusZiVisible(symbolNode,coins,self.SYMBOL_BONUS_1)
                coins = util_formatCoins(coins, 3,nil,nil,true)
                symbolNode.m_labNode:findChild("m_lb_coins"):setString(coins)
            end
        else
            local multiple = 1
            if self.m_initGridNode == true then
                multiple = self.m_configData:getBonus1MaxSymbolPro()
            else
                multiple = self.m_configData:getBonus1SymbolPro()
            end

            if multiple ~= nil then
                local score = util_formatCoins(totalbet * multiple, 3,nil,nil,true)
                symbolNode.m_labNode:findChild("m_lb_coins"):setString(score)
                self:setBonusZiVisible(symbolNode,totalbet * multiple,self.SYMBOL_BONUS_1)
            end
        end
    elseif symbolNode.p_symbolType == self.SYMBOL_BONUS_FAKER1 then
            local totalbet = globalData.slotRunData:getCurTotalBet()
            local multiple = 1
            if self.m_initGridNode == true then
                multiple = self.m_configData:getBonus1MaxSymbolPro()
            else
                multiple = self.m_configData:getBonus1SymbolPro()
            end

            if multiple ~= nil then
                local score = util_formatCoins(totalbet * multiple, 3,nil,nil,true)
                symbolNode:getCcbProperty("m_lb_coins"):setString(score)
                self:setBonusZiVisibleFaker(symbolNode,totalbet * multiple,self.SYMBOL_BONUS_FAKER1)
            end
    elseif symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
        symbolNode:addLabel()
        local totalbet = globalData.slotRunData:getCurTotalBet()
        local iCol = symbolNode.p_cloumnIndex
        local iRow = symbolNode.p_rowIndex

        local multiple = self.m_runSpinResultData.p_rsExtraData.bonus2Multiple
        if multiple ~= nil then
            local score = util_formatCoins(totalbet * multiple, 3,nil,nil,true)
            symbolNode.m_labNode:findChild("m_lb_coins"):setString(score)
        end
        symbolNode:runAnim("idleframe",true)

        
        -- 看着像是不同倍数显示不同字体，先留着吧，以免有用
        -- local coinType = self.m_runSpinResultData.p_rsExtraData.bonus2Type
        -- if coinType then
            -- for i = 1,3 do
            --     if i == coinType then
            --         symbolNode.m_labNode:findChild("m_lb_coins_"..(i - 1)):setVisible(true)
            --     else
            --         symbolNode.m_labNode:findChild("m_lb_coins_"..(i - 1)):setVisible(false)
            --     end
            -- end
        -- end
    elseif symbolNode.p_symbolType == self.SYMBOL_BONUS_FAKER2 then
        local totalbet = globalData.slotRunData:getCurTotalBet()
        local multiple = self.m_runSpinResultData.p_rsExtraData.bonus2Multiple
        if multiple ~= nil then
            local score = util_formatCoins(totalbet * multiple, 3,nil,nil,true)
            symbolNode:getCcbProperty("m_lb_coins"):setString(score)
        end
    elseif symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        -- symbolNode:runAnim("idleframe1",true)
    elseif symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        if self.m_iBetLevel >= 1 then
            symbolNode:setLineAnimName("actionframe4")
            symbolNode:setIdleAnimName("idleframe2")
        else
            symbolNode:setLineAnimName("actionframe3")
            symbolNode:setIdleAnimName("idleframe1")
        end
    end
end

function CodeGameScreenKoiBlissMachine:playCustomSpecialSymbolDownAct(slotNode)
    CodeGameScreenKoiBlissMachine.super.playCustomSpecialSymbolDownAct(self, slotNode)
    if slotNode.p_symbolType and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        if self.m_iBetLevel >= 1 then
            slotNode:runAnim("idleframe4",true)
        else
            slotNode:runAnim("idleframe1",true)
        end
    end
end

function CodeGameScreenKoiBlissMachine:setBonusZiVisibleFaker(_symbolNode,_coins,_symbolType)
    if _symbolType == self.SYMBOL_BONUS_FAKER1 then
        local totalbet = globalData.slotRunData:getCurTotalBet()
        local mul = tonumber(_coins/totalbet)
        local jackpotType = self.m_configData:getMulJackpotType(mul)
        if jackpotType then
            jackpotType = string.lower(jackpotType)
            _symbolNode:getCcbProperty("grand"):setVisible(jackpotType == "grand")
            _symbolNode:getCcbProperty("major"):setVisible(jackpotType == "major")
            _symbolNode:getCcbProperty("minor"):setVisible(jackpotType == "minor")
            _symbolNode:getCcbProperty("mini"):setVisible(jackpotType == "mini")
            _symbolNode:getCcbProperty("m_lb_coins"):setVisible(false)
        else
            _symbolNode:getCcbProperty("m_lb_coins"):setVisible(true)
            _symbolNode:getCcbProperty("grand"):setVisible(false)
            _symbolNode:getCcbProperty("major"):setVisible(false)
            _symbolNode:getCcbProperty("minor"):setVisible(false)
            _symbolNode:getCcbProperty("mini"):setVisible(false)
        end
    end
end

function CodeGameScreenKoiBlissMachine:setBonusZiVisible(_symbolNode,_coins,_symbolType)
    local totalbet = globalData.slotRunData:getCurTotalBet()
    local mul = tonumber(_coins/totalbet)
    local jackpotType = self.m_configData:getMulJackpotType(mul)
    self:changeLabShow(_symbolNode,jackpotType)
    -- if jackpotType == "Mini" then
    --     _symbolNode.m_labNode:findChild("m_lb_coins"):setVisible(false)
        
    --     if _symbolNode.checkLoadCCbNode then
    --         local ccbNode = _symbolNode:checkLoadCCbNode()
    --         local spine = ccbNode.m_spineNode
    --         spine:setSkin("mini")
    --     else
    --         _symbolNode:setSkin("mini")
    --     end
    -- elseif jackpotType == "Minor" then
    --     _symbolNode.m_labNode:findChild("m_lb_coins"):setVisible(false)
        
    --     if _symbolNode.checkLoadCCbNode then
    --         local ccbNode = _symbolNode:checkLoadCCbNode()
    --         if not tolua.isnull(ccbNode) and ccbNode.m_spineNode then
    --             ccbNode.m_spineNode:setSkin("minor")
    --         end
    --     else
    --         _symbolNode:setSkin("minor")
    --     end
    -- else
    --     if _symbolNode.checkLoadCCbNode then
    --         local ccbNode = _symbolNode:checkLoadCCbNode()
    --         local spine = ccbNode.m_spineNode
    --         spine:setSkin("default")
    --     else
    --         _symbolNode:setSkin("default")
    --     end
    --     _symbolNode.m_labNode:findChild("m_lb_coins"):setVisible(true)
    -- end
end

function CodeGameScreenKoiBlissMachine:changeLabShow(_symbolNode,jackpotType)
    if jackpotType then
        jackpotType = string.lower(jackpotType)
        _symbolNode.m_labNode:findChild("grand"):setVisible(jackpotType == "grand")
        _symbolNode.m_labNode:findChild("major"):setVisible(jackpotType == "major")
        _symbolNode.m_labNode:findChild("minor"):setVisible(jackpotType == "minor")
        _symbolNode.m_labNode:findChild("mini"):setVisible(jackpotType == "mini")
        _symbolNode.m_labNode:findChild("m_lb_coins"):setVisible(false)
    else
        _symbolNode.m_labNode:findChild("m_lb_coins"):setVisible(true)
        _symbolNode.m_labNode:findChild("grand"):setVisible(false)
        _symbolNode.m_labNode:findChild("major"):setVisible(false)
        _symbolNode.m_labNode:findChild("minor"):setVisible(false)
        _symbolNode.m_labNode:findChild("mini"):setVisible(false)
    end

end

function CodeGameScreenKoiBlissMachine:changeBgForStates(_states)
    self:findChild("Node_reel"):setVisible(_states ~= PublicConfig.pick )
    self:findChild("Node_jackpotbar"):setVisible(_states ~= PublicConfig.pick )
    self:findChild("Node_base_reel"):setVisible(_states == PublicConfig.base )
    self:findChild("Node_choicemode"):setVisible( _states == PublicConfig.base or _states == PublicConfig.free)
    self:findChild("Node_base_kuang"):setVisible(_states == PublicConfig.base )
    self:findChild("Node_free_kuang"):setVisible(_states == PublicConfig.fs )
    self:findChild("Node_free_reel"):setVisible(_states == PublicConfig.fs )
    self:findChild("Node_respin_kuang"):setVisible(_states == PublicConfig.rs )
    self:findChild("Node_respin_reel"):setVisible(_states == PublicConfig.rs )
    self.m_totalWinKuang:setVisible(_states == PublicConfig.rs )
    self.m_fishJuese2.m_bowen:setVisible(_states ~= PublicConfig.rs )
    self.m_baseFreeSpinBar:setVisible(_states == PublicConfig.fs )
    
    if _states == PublicConfig.base then
        util_spinePlay(self.m_spineBG,"idle1",true)
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local wildCollectNum = selfData.wildCollectNum or 0
        local wildCollPro = self:getWildCollectProgress(wildCollectNum)
        self.m_fishJuese2.wildCollPro = wildCollPro
        self.jveSeNode:stopAllActions()
        self:updateFishPro(wildCollPro,true)
        self:showBasinLighting(true)
    elseif _states == PublicConfig.fs then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local wildCollectNum = selfData.wildCollectNum or 0
        local wildCollPro = self:getWildCollectProgress(wildCollectNum)
        self.m_fishJuese2.wildCollPro = wildCollPro
        self.jveSeNode:stopAllActions()
        self:updateFishPro(wildCollPro,true)
        util_spinePlay(self.m_spineBG,"idle2",true)
        self:showBasinLighting(true)
    elseif _states == PublicConfig.rs then
        self.jveSeNode:stopAllActions()
        self.m_fishJuese1.p_gridNode:stopAllActions()
        self.m_fishJuese2.p_gridNode:stopAllActions()
        self.m_fishJuese1.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.mid )
        self.m_fishJuese2.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.down)
        self:findChild("Node_doublefish"):stopAllActions()
        util_spinePlay(self.m_fishJuese2,"jackpot_idleframe",true)
        self.m_fishJuese2.m_actionName = "jackpot_idleframe"
        util_spinePlay(self.m_fishJuese1,"jackpot_idleframe",true)
        util_spinePlay(self.m_spineBG,"idle3",true)
        self:showBasinLighting(false)
    elseif _states == PublicConfig.pick then
        self.jveSeNode:stopAllActions()
        self.m_fishJuese1.p_gridNode:stopAllActions()
        self.m_fishJuese2.p_gridNode:stopAllActions()
        self.m_fishJuese1.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.mid )
        self.m_fishJuese2.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.down)
        self:findChild("Node_doublefish"):stopAllActions()
        util_spinePlay(self.m_fishJuese2,"jackpot_idle",true)
        self.m_fishJuese2.m_actionName = "jackpot_idle"
        util_spinePlay(self.m_fishJuese1,"jackpot_idle",true)
        util_spinePlay(self.m_spineBG,"idle3",true)
        self:showBasinLighting(false)
    end
    
end

function CodeGameScreenKoiBlissMachine:getWildCollectProgress(_wildCollectNum)
    local collectNumTab = PublicConfig.collectNumTab 
    local totalNum = _wildCollectNum
    local wildCollectPro = #collectNumTab + 1
    for i,v in ipairs(collectNumTab) do
        if totalNum < v then
            wildCollectPro = i
            break
        end
    end
    return wildCollectPro
end

function CodeGameScreenKoiBlissMachine:updateFishPro(_pro,_isInit,_isTrigger)
    self:findChild("Node_doublefish"):stopAllActions()
    local pro = _pro 
    local isUpdateMaxPro = false
    local isShowIdle = true
    if _isTrigger then
        pro = 3
    end
    local waitTime = 0
    local isInit = _isInit
    if not isInit then
        if self.m_fishJuese2.wildCollPro ~= pro then
            if not _isTrigger then
                if pro == 2 then
                    -- 1->2
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_shengji_1)
                    util_spinePlay(self.m_fishJuese2,"shengji" .. 1)
                    self.m_fishJuese2.m_actionName = "shengji1"
                    util_spinePlay(self.m_fishJuese1,"shengji" .. 1)
                    self.shouji_bd:stopAllActions()
                    self.shouji_bd:setVisible(true)
                    util_spinePlay(self.shouji_bd,"shouji2")
                    local bdTime = self.shouji_bd:getAnimationDurationTime("shouji2") 
                    performWithDelay(self.shouji_bd,function ()
                        self.shouji_bd:setVisible(false)
                    end,bdTime)
                    waitTime = self.m_fishJuese2:getAnimationDurationTime("shengji" .. 2) 
                elseif pro == 3 then
                    -- 2->3
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_shengji_2)
                    util_spinePlay(self.m_fishJuese2,"shengji" .. 2)
                    self.m_fishJuese2.m_actionName = "shengji2"
                    util_spinePlay(self.m_fishJuese1,"shengji" .. 2)
                    self.shouji_bd:stopAllActions()
                    self.shouji_bd:setVisible(true)
                    util_spinePlay(self.shouji_bd,"shouji3")
                    local bdTime = self.shouji_bd:getAnimationDurationTime("shouji3") 
                    performWithDelay(self.shouji_bd,function ()
                        self.shouji_bd:setVisible(false)
                    end,bdTime)
                    isUpdateMaxPro = true
                    waitTime = self.m_fishJuese2:getAnimationDurationTime("shengji" .. 1) 
                end
            else
                if self.m_fishJuese2.wildCollPro == 2 then
                    -- 2->3
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_shengji_2)
                    util_spinePlay(self.m_fishJuese2,"shengji" .. 2)
                    self.m_fishJuese2.m_actionName = "shengji2"
                    util_spinePlay(self.m_fishJuese1,"shengji" .. 2)
                    self.shouji_bd:stopAllActions()
                    self.shouji_bd:setVisible(true)
                    util_spinePlay(self.shouji_bd,"shouji2")
                    local bdTime = self.shouji_bd:getAnimationDurationTime("shouji2") 
                    performWithDelay(self.shouji_bd,function ()
                        self.shouji_bd:setVisible(false)
                    end,bdTime)
                    waitTime = self.m_fishJuese2:getAnimationDurationTime("shengji" .. 2) 
                    
                elseif self.m_fishJuese2.wildCollPro == 1 then
                    -- 1->3
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_shengji_3)
                    util_spinePlay(self.m_fishJuese2,"shengji" .. 3)
                    self.m_fishJuese2.m_actionName = "shengji3"
                    util_spinePlay(self.m_fishJuese1,"shengji" .. 3)
                    self.shouji_bd:stopAllActions()
                    self.shouji_bd:setVisible(true)
                    util_spinePlay(self.shouji_bd,"shouji3")
                    local bdTime = self.shouji_bd:getAnimationDurationTime("shouji3") 
                    performWithDelay(self.shouji_bd,function ()
                        self.shouji_bd:setVisible(false)
                    end,bdTime)
                    waitTime = self.m_fishJuese2:getAnimationDurationTime("shengji" .. 3)
                    
                end
            end
        else
            if not _isTrigger then
                if pro == 3 then
                    PublicConfig.fishRippleAction2(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius)
                    self:delayCallBack(1,function ()
                        PublicConfig.fishRippleAction1(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius,false)
                    end)
                    self.shouji_bd:stopAllActions()
                    self.shouji_bd:setVisible(true)
                    util_spinePlay(self.shouji_bd,"shouji3")
                    local bdTime = self.shouji_bd:getAnimationDurationTime("shouji3") 
                    performWithDelay(self.shouji_bd,function ()
                        self.shouji_bd:setVisible(false)
                    end,bdTime)
                    waitTime = self.m_fishJuese2:getAnimationDurationTime("shouji" .. 3) 
                else
                    -- util_spinePlay(self.m_fishJuese2,"shouji" .. pro)
                    self:showCollectLight(pro)
                    isShowIdle = false
                    -- util_playFadeOutAction(self.m_fishJuese2,0.2)
                    -- util_spinePlay(self.m_fishJuese1,"idle" .. pro)
                    self.shouji_bd:stopAllActions()
                    self.shouji_bd:setVisible(true)
                    util_spinePlay(self.shouji_bd,"shouji" .. pro)
                    local bdTime = self.shouji_bd:getAnimationDurationTime("shouji" .. pro) 
                    performWithDelay(self.shouji_bd,function ()
                        self.shouji_bd:setVisible(false)
                    end,bdTime)
                    waitTime = self.m_fishJuese2:getAnimationDurationTime("shouji" .. pro)
                end
            elseif self.m_fishJuese2.wildCollPro ~= 3 then
                -- 触发那一次不是等级3，那肯定得先升级到最高档
                PublicConfig.fishRippleAction2(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius)
                self:delayCallBack(1,function ()
                    PublicConfig.fishRippleAction1(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius,false)

                end)
                self.shouji_bd:stopAllActions()
                self.shouji_bd:setVisible(true)
                util_spinePlay(self.shouji_bd,"shouji3")
                local bdTime = self.shouji_bd:getAnimationDurationTime("shouji3") 
                performWithDelay(self.shouji_bd,function ()
                    self.shouji_bd:setVisible(false)
                end,bdTime)
                waitTime = self.m_fishJuese2:getAnimationDurationTime("shouji" .. 3) 
            elseif self.m_fishJuese2.wildCollPro == 3 then
                PublicConfig.fishRippleAction2(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius)

                self:delayCallBack(1,function ()
                    PublicConfig.fishRippleAction1(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius,false)

                end)

                self.shouji_bd:stopAllActions()
                self.shouji_bd:setVisible(true)
                util_spinePlay(self.shouji_bd,"shouji3")
                local bdTime = self.shouji_bd:getAnimationDurationTime("shouji3") 
                performWithDelay(self.shouji_bd,function ()
                    self.shouji_bd:setVisible(false)
                end,bdTime)
                waitTime = self.m_fishJuese2:getAnimationDurationTime("shouji" .. 3) 
            end
        end
    else
        waitTime = 0
    end
    

    local updateFunc = function()
        
        if self.m_fishJuese2:getOpacity() <= 0 then
            util_playFadeInAction(self.m_fishJuese2,1/30)
        end
        if pro == 1 then
            self.m_fishJuese1.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.down)
            self.m_fishJuese2.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.mid)
            if self.m_fishJuese2.m_actionName ~= "idle1" then
                self.jveSeNode:stopAllActions()
                util_spinePlay(self.m_fishJuese2,"idle1",true)
                self.m_fishJuese2.m_actionName = "idle1"
            end
            
            if isShowIdle then
                util_spinePlay(self.m_fishJuese1,"idle1" ,true)
            end
            
        elseif pro == 2 then
            self.m_fishJuese1.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.down)
            self.m_fishJuese2.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.mid)
            if self.m_fishJuese2.m_actionName ~= "idle2" then
                self.jveSeNode:stopAllActions()
                util_spinePlay(self.m_fishJuese2,"idle2",true)
                self.m_fishJuese2.m_actionName = "idle2"
            end
            
            if isShowIdle then
                util_spinePlay(self.m_fishJuese1,"idle2" ,true)
            end
            
        elseif pro == 3 then
            self.m_fishJuese1.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.mid)
            self.m_fishJuese2.p_gridNode:setLocalZOrder(PublicConfig.fishZOrder.down)
            if _isInit then
                self:showFishJueseIdle3()
            else
                if isUpdateMaxPro then
                    self:showFishJueseIdle3()
                end
            end
            
        end
    end
    if waitTime > 0 then
        performWithDelay(self:findChild("Node_doublefish"),function()
            updateFunc()
        end,waitTime)
    else
        updateFunc()
    end
    
    self.m_fishJuese2.wildCollPro = pro
end

function CodeGameScreenKoiBlissMachine:showFishJueseIdle3()
    self.jveSeNode:stopAllActions()
    local idleTime = self.m_fishJuese2:getAnimationDurationTime("idle3")
    local actTime = self.m_fishJuese2:getAnimationDurationTime("actionframe2")
    local isNotice = (math.random(1, 100) <= 10) 
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if self.m_fishJuese2.m_actionName ~= "idle3" then
            util_spinePlay(self.m_fishJuese2,"idle3")
            self.m_fishJuese2.m_actionName = "idle3"
        end
        util_spinePlay(self.m_fishJuese1,"idle3")
    end)
    actList[#actList + 1] = cc.DelayTime:create(idleTime)
    if isNotice then
        actList[#actList + 1] = cc.CallFunc:create(function ()
            
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_collect_faker)
            util_spinePlay(self.m_fishJuese1,"actionframe2",false)
            util_spinePlay(self.m_fishJuese2,"actionframe2",false)
            --波纹
            PublicConfig.fishRippleActionForRespin(self.m_fishJuese2.p_gridNode, self.m_fishJuese2.p_grid3D, cc.p(self.m_fishJuese2.worldPos))
            PublicConfig.fishRippleActionForRespin(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos))
        end)
        actList[#actList + 1] = cc.DelayTime:create(actTime)
        actList[#actList + 1] = cc.CallFunc:create(function ()
            PublicConfig.fishRippleAction1(self.m_fishJuese1.p_gridNode, self.m_fishJuese1.p_grid3D, cc.p(self.m_fishJuese1.worldPos), self.m_fishJuese1.radius,false)
        end)
    end
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:showFishJueseIdle3()
    end)
    self.jveSeNode:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenKoiBlissMachine:showCollectLight(pro)
    local light = util_spineCreate("KoiBliss_juese2",true,true) 
    light:setPositionY(-225)
    self:findChild("Node_doublefish"):addChild(light,PublicConfig.fishZOrder.mid + 1)
    local waitTime = light:getAnimationDurationTime("shouji" .. pro) 
    util_spinePlay(light,"shouji" .. pro)
    self:delayCallBack(waitTime + 0.1 ,function ()
        light:removeFromParent()
    end)
end

function CodeGameScreenKoiBlissMachine:showGuochang(guochangType,func1,func2)
    self:showBasinLighting(false)
    if guochangType == PublicConfig.fsStart or guochangType == PublicConfig.fsOver then

        self.m_fsStartGc:setVisible(true)
        util_spinePlay(self.m_fsStartGc,"actionframe_guochang")
        util_spineEndCallFunc(self.m_fsStartGc,"actionframe_guochang",function()
            self.m_fsStartGc:setVisible(false)
            if func2 then
                func2()
            end
        end)
        
        performWithDelay(self,function()
            if func1 then
                func1()
            end
        end,84/30)
            
    
    elseif guochangType == PublicConfig.rsStart then

        self.m_gcLighting:setVisible(true)
        self.m_gcLighting:runCsbAction("start")
        -- self.m_rsStartGc:setVisible(true)
        if self.m_gcLighting.light then
            util_spinePlay(self.m_gcLighting.light,"actionframe_guochang2")
        end
        util_spinePlay(self.m_rsStartGc,"actionframe_guochang2")
        self:delayCallBack(80/30,function ()
            if func1 then
                func1()
            end
        end)
        -- performWithDelay(self,function()
        --     if func1 then
        --         func1()
        --     end
        -- end,80/30)
        self:delayCallBack(83/30,function ()
            if func2 then
                func2()
            end
        end)
        local gcTime = self.m_rsStartGc:getAnimationDurationTime("actionframe_guochang2") 
        self:delayCallBack(gcTime,function ()
            if self.m_gcLighting.light then
                util_spinePlay(self.m_gcLighting.light,"tanban_BG",true)
            end
            
        end)
        -- util_spineEndCallFunc(self.m_rsStartGc,"actionframe_guochang2",function()
        --     self.m_rsStartGc:setVisible(false)
        --     -- if func2 then
        --     --     func2()
        --     -- end
            
        -- end)

        

    elseif guochangType == PublicConfig.pickStart or guochangType == PublicConfig.pickOver or guochangType == PublicConfig.rsOver then

        self.m_rsStartGc:setVisible(true)
        util_spinePlay(self.m_rsStartGc,"actionframe_guochang1")
        util_spineEndCallFunc(self.m_rsStartGc,"actionframe_guochang1",function()
            self.m_rsStartGc:setVisible(false)
            if func2 then
                func2()
            end
        end)

        performWithDelay(self,function()
            if func1 then
                func1()
            end
        end,80/30)
    end
end

-- 通知某种类型动画播放完毕
function CodeGameScreenKoiBlissMachine:notifyGameEffectPlayComplete(param)
    local effectType
    if type(param) == "table" then
        effectType = param[1]
    else
        effectType = param
    end
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == GameEffect.EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    for i = 1, effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 继续播放动画
                    break
                end
            else
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
                break
            end
        end
    end
end

--设置bonus scatter 层级
function CodeGameScreenKoiBlissMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_FAKER2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1
    elseif symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_FAKER1 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分值越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order
end

--根据行列获取世界坐标
function CodeGameScreenKoiBlissMachine:getWorldPositionByColRow(col,row)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX,posY))
    return worldPos
end

function CodeGameScreenKoiBlissMachine:playBulingAnimFunc(_slotNode,_symbolCfg)

    local ainmName = _symbolCfg[2]
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_scatteNum <= 1 then
            ainmName = _symbolCfg[2]
        elseif self.m_scatteNum <= 2 then
            ainmName = "buling2"
        else
            ainmName = "buling3"
        end
        local soundPath = self:getSoundPathForScatterNum()
        if soundPath then
            self:playBulingSymbolSounds(_slotNode.p_cloumnIndex, soundPath, _slotNode.p_symbolType)
        end
        self.m_scatteNum = self.m_scatteNum + 1
    end
    _slotNode:runAnim(
        ainmName,
        false,
        function()
            self:symbolBulingEndCallBack(_slotNode)
        end
    )
end

function CodeGameScreenKoiBlissMachine:getSoundPathForScatterNum()
    local path = nil
    if self.m_scatteNum == 1 then
        path = PublicConfig.SoundConfig.scatter_buling_1
    elseif self.m_scatteNum == 2 then
        path = PublicConfig.SoundConfig.scatter_buling_2
    else
        path = PublicConfig.SoundConfig.scatter_buling_3
    end
    return path
end

function CodeGameScreenKoiBlissMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            local iCol = _slotNode.p_cloumnIndex
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- self.scatterNum = self.scatterNum + 1
                -- local soundPath = self:getSoundPathForScatterNum()
                -- if soundPath then
                --     self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                -- end
            else
                if symbolCfg then
                    
                    local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                    if soundPath then
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
            
        end
    end
end


--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenKoiBlissMachine:showBigWinLight(func)
    local currFunc = function()
        self.m_bigWinEff:setVisible(false)
        if func then
            func()
        end
    end
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bigWin_yuGao)
    local isNotice = (math.random(1, 100) <= 30) 
    if isNotice then
        local isNotice2 = (math.random(1, 100) <= 50) 
        if isNotice2 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_yuGao_your_day)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_yuGao_good_luck)
        end
    end
    self.m_bigWinEff:setVisible(true)
    util_spinePlay(self.m_bigWinEff,"actionframe_bigwin")

    self:delayCallBack(aniTime,function()
        currFunc()
    end)
    -- CodeGameScreenKoiBlissMachine.super.showBigWinLight(self,currFunc)
end

function CodeGameScreenKoiBlissMachine:playRsYuGaoAnim()
    local time = 60/30
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_respin_yuGao)
    for i=1,#self.m_yuGoaList do
        local node = self.m_yuGoaList[i]
        node:setVisible(true)
        util_spinePlay(node,"actionframe_yugao")
        util_spineEndCallFunc(node,"actionframe_yugao",function()
            node:setVisible(false) 
        end)
    end
    return time
end

function CodeGameScreenKoiBlissMachine:initRsYuGaoAnim()
    self.m_yuGoaList = {}
    local spineCoins1 = util_spineCreate("KoiBliss_yugao_jinbi1",true,true)
    self:findChild("Node_yugao"):addChild(spineCoins1)
    local spineCoins2 = util_spineCreate("KoiBliss_yugao_jinbi2",true,true)
    self:findChild("Node_yugao"):addChild(spineCoins2)
    local spineCoins3 = util_spineCreate("KoiBliss_yugao_jinbi3",true,true)
    self:findChild("Node_yugao"):addChild(spineCoins3)
    local spineYu1 = util_spineCreate("KoiBliss_yugao_yu1",true,true)
    self:findChild("Node_yugao"):addChild(spineYu1)
    local spineYu2 = util_spineCreate("KoiBliss_yugao_yu2",true,true)
    self:findChild("Node_yugao"):addChild(spineYu2)
    local spineYu3 = util_spineCreate("KoiBliss_yugao_yu3",true,true)
    self:findChild("Node_yugao"):addChild(spineYu3)
    local spineYu4 = util_spineCreate("KoiBliss_yugao_yu4",true,true)
    self:findChild("Node_yugao"):addChild(spineYu4)
    table.insert(self.m_yuGoaList,spineYu1)
    table.insert(self.m_yuGoaList,spineYu2)
    table.insert(self.m_yuGoaList,spineYu3)
    table.insert(self.m_yuGoaList,spineYu4)
    table.insert(self.m_yuGoaList,spineCoins1)
    table.insert(self.m_yuGoaList,spineCoins2)
    table.insert(self.m_yuGoaList,spineCoins3)

    for i=1,#self.m_yuGoaList do
        local node = self.m_yuGoaList[i]
        node:setVisible(false)
    end
end

function CodeGameScreenKoiBlissMachine:stopLastWinAddCoins(isShowcurCoinsToLastCoins)
    if self.m_coinbonusUpdateAction then
        self.m_totalWinKuang:stopAction(self.m_coinbonusUpdateAction)
        self.m_coinbonusUpdateAction = nil
    end
    if isShowcurCoinsToLastCoins == true then
        self.m_totalWinKuang:findChild("m_lb_coins_0"):setString(util_formatCoins(self.m_lightScore,30))
        self.m_totalWinKuang.m_currShowCoins = self.m_lightScore
        self.m_totalWinKuang:updateLabelSize({label = self.m_totalWinKuang:findChild("m_lb_coins_0"),sx=0.98,sy=1},633)
    end
end

function CodeGameScreenKoiBlissMachine:updateTotalWinKuang(isPlayAni,func)
    if isPlayAni == true then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bonus_collect_fankui)
        self.m_totalWinKuang:runCsbAction("actionframe")

        self:stopLastWinAddCoins(false)
        local showTime = 0.5
        local coinRiseNum = (self.m_lightScore - self.m_totalWinKuang.m_currShowCoins) / (showTime * 60)  -- 每秒60帧

        local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
        coinRiseNum = tonumber(str)
        coinRiseNum = math.ceil(coinRiseNum)
        local node = self.m_totalWinKuang:findChild("m_lb_coins_0")
        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECTCOINBONUS_EFFECT})
        -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_bonus_update_win)
        self.m_coinbonusUpdateAction = schedule(self.m_totalWinKuang,function()
            self.m_totalWinKuang.m_currShowCoins = self.m_totalWinKuang.m_currShowCoins + coinRiseNum
            self.m_totalWinKuang.m_currShowCoins = self.m_totalWinKuang.m_currShowCoins < self.m_lightScore and self.m_totalWinKuang.m_currShowCoins or self.m_lightScore
            node:setString(util_formatCoins(self.m_totalWinKuang.m_currShowCoins,30))
            self.m_totalWinKuang:updateLabelSize({label = node,sx=0.98,sy=1},633)
            if self.m_totalWinKuang.m_currShowCoins >= self.m_lightScore then
                if func then
                    func()
                end
                self:stopLastWinAddCoins(true)
            end
        end,1/60)

        local num = 0
        local perBonus2WinCoins = self.m_runSpinResultData.p_rsExtraData.bonus2WinCoins
        if perBonus2WinCoins then
            num = self.m_lightScore/perBonus2WinCoins - 1
            if num < 0 then
                num = 0
            end
        end
        self.m_totalWinKuang:findChild("m_lb_num_0"):setString(num)
    else
        if self.m_lightScore == 0 then
            self.m_totalWinKuang:findChild("m_lb_coins_0"):setString("")
        else
            self.m_totalWinKuang:findChild("m_lb_coins_0"):setString(util_formatCoins(self.m_lightScore,30))
            self.m_totalWinKuang:updateLabelSize({label = self.m_totalWinKuang:findChild("m_lb_coins_0"),sx=0.98,sy=1},633)
            
        end
        self.m_totalWinKuang.m_currShowCoins = self.m_lightScore
        local perBonus2WinCoins = self.m_runSpinResultData.p_rsExtraData.bonus2WinCoins
        local num = 0
        if perBonus2WinCoins then
            num = self.m_lightScore/perBonus2WinCoins - 1
        end
        if num < 1 then
            self.m_totalWinKuang:findChild("m_lb_num_0"):setString("0")
        else
            self.m_totalWinKuang:findChild("m_lb_num_0"):setString(num)
        end
        self.m_totalWinKuang:updateLabelSize({label = self.m_totalWinKuang:findChild("m_lb_coins_0"),sx=0.98,sy=1},633)
        if func then
            func()
        end
    end
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenKoiBlissMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        reelDatas = self.m_configData:getNormalRespinCloumnByColumnIndex(parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas
    if parentData.beginReelIndex > #reelDatas then
        parentData.beginReelIndex = nil
    end
    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function CodeGameScreenKoiBlissMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenKoiBlissMachine:initGameStatusData(gameData)
    if self.m_specialBets == nil then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if gameData.spin and gameData.spin.reels and gameData.spin.nextReel then
        table.insert(gameData.spin.reels,gameData.spin.nextReel)
    end
    CodeGameScreenKoiBlissMachine.super.initGameStatusData(self,gameData)
end

function CodeGameScreenKoiBlissMachine:checkOperaSpinSuccess(param)

    table.insert(param[2].result.reels,param[2].result.nextReel)
    self.super.checkOperaSpinSuccess(self, param)
end

function CodeGameScreenKoiBlissMachine:checkOnceClipNode()
    if self.m_isOnceClipNode == false then
        return
    end
    local iRowNum = self.m_iReelRowNum
    local iColNum = self.m_iReelColumnNum
    local reel = self:findChild("sp_reel_0")
    local startX = reel:getPositionX()
    local startY = reel:getPositionY()
    local reelEnd = self:findChild("sp_reel_"..(iColNum-1))
    local endX = reelEnd:getPositionX()
    local endY = reelEnd:getPositionY()
    local reelSize = reelEnd:getContentSize()
    local scaleX = reelEnd:getScaleX()
    local scaleY = reelEnd:getScaleY()
    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY
    local offX = reelSize.width * 0.5
    endX = endX + reelSize.width - startX + offX*2
    startY = startY + reelSize.height/iRowNum
    endY = endY + reelSize.height - startY
    self.m_onceClipNode = cc.ClippingRectangleNode:create(
        {
            x = startX-offX,
            y = startY,
            width = endX,
            height = endY
        }
    )
    self.m_clipParent:addChild(self.m_onceClipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    self.m_onceClipNode:setPosition(0,0)
end

-- 处理特殊关卡 遮罩层级
-- function CodeGameScreenKoiBlissMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent,_reels)
    -- local maxzorder = 0
    -- local zorder = 0
    -- local reel = _reels or self.m_stcValidSymbolMatrix
    -- for i=2,self.m_iReelRowNum do

    --     local symbolType = reel[i][parentData.cloumnIndex]
    --     local zorder = self:getBounsScatterDataZorder(symbolType)
    --     if zorder >  maxzorder then
    --         maxzorder = zorder
    --     end
    -- end

    -- slotParent:getParent():setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
    -- local slotParentBig = parentData.slotParentBig
    -- if slotParentBig then
    --     slotParentBig:getParent():setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000 + maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
    -- end

-- end

function CodeGameScreenKoiBlissMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeKoiBlissSrc.KoiBlissJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpotbar"):addChild(self.m_jackPotBarView) --修改成自己的节点
    local ratio = display.height / display.width
    if ratio == 1530/768 then
        self.m_jackPotBarView:setPosition(cc.p(0,70))
    elseif ratio == 1970/768 then
        self.m_jackPotBarView:setPosition(cc.p(0,140))
    end
end

function CodeGameScreenKoiBlissMachine:checkIsAddLastWinSomeEffect()
    local notAdd = CodeGameScreenKoiBlissMachine.super.checkIsAddLastWinSomeEffect(self)
    if self.m_pickGameWinCoins and self.m_pickGameWinCoins > 0 then
        notAdd = true
    end
    return notAdd
end

--播放
function CodeGameScreenKoiBlissMachine:playBottomBigWinLabAnim(_params)
    _params.overCoins = _params.overCoins - self.m_pickGameWinCoins
    CodeGameScreenKoiBlissMachine.super.playBottomBigWinLabAnim(self,_params)
end

--金鱼盆背光
function CodeGameScreenKoiBlissMachine:showBasinLighting(isShow)
    if isShow then
        -- self.m_basinLighting:setOpacity(255)
        self.m_basinLighting:setVisible(true)
    else
        -- self.m_basinLighting:runAction(cc.Sequence:create(cc.FadeTo:create(0.2,0),cc.CallFunc:create(function()
            self.m_basinLighting:setVisible(false)
        -- end)))
    end
    
end

function CodeGameScreenKoiBlissMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0

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
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            local ratio = display.height / display.width
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            if ratio == 1228 / 768 then
                mainScale = mainScale * 1.02
                tempPosY = 5
            elseif ratio >= 1152/768 and ratio < 1228/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            elseif ratio >= 920/768 and ratio < 1152/768 then
                local mul = (1152 / 768 - display.height / display.width) / (1152 / 768 - 920 / 768)
                mainScale = mainScale + 0.05 * mul + 0.03--* 1.16
                tempPosY = 25
            elseif ratio < 1152/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(tempPosY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

---
--添加金边
function CodeGameScreenKoiBlissMachine:creatReelRunAnimation(col)
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

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run")
    self:delayCallBack(30/60,function ()
        --播放水花效果
        self:showLongRunWater(col)
    end)
    

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

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--快滚水花创建
function CodeGameScreenKoiBlissMachine:createLongRunWater(col)
    local water = util_spineCreate("KoiBliss_run_shui",true,true)
    self:findChild("Node_run_tx"..col):addChild(water)
    self.waterList[col] = water
    return water
end

function CodeGameScreenKoiBlissMachine:showLongRunWater(col)
    local water = self.waterList[col]
    if not tolua.isnull(water) then
        water:setVisible(true)
        util_spinePlay(water, "actionframe", false)
        util_spineEndCallFunc(water,"actionframe",function()
            water:setVisible(false)
        end)
    else
        water = self:createLongRunWater(col)
        water:setVisible(true)
        util_spinePlay(water, "actionframe", false)
        util_spineEndCallFunc(water,"actionframe",function()
            water:setVisible(false)
        end)
    end
end

-- --创建csb节点
-- function CodeGameScreenKoiBlissMachine:createCsbNode(filePath, isAutoScale)
--     self.m_baseFilePath = filePath
--     local fullPath = cc.FileUtils:getInstance():fullPathForFilename(filePath)
--     -- print("fullPath =".. fullPath)

--     self.m_csbNode, self.m_csbAct = util_csbCreate(self.m_baseFilePath, self.m_isCsbPathLog)
    

--     local sizeX = 31
--     local sizePix = display.width/sizeX
--     local sizeY = math.ceil(display.height/sizePix) 
--     self.m_csbNode.m_gridNode, self.m_csbNode.m_grid3D = PublicConfig.createGridNode(cc.size(sizeX,sizeY),self.m_csbNode ) 
    
--     self:addChild(self.m_csbNode.m_gridNode)
--     self:bindingEvent(self.m_csbNode)
--     self:pauseForIndex(0)
--     self:setAutoScale(isAutoScale)

--     self:initCsbNodes()
-- end

-- function CodeGameScreenKoiBlissMachine:beginReel()
--     CodeGameScreenKoiBlissMachine.super.beginReel(self)
--     -- PublicConfig.selfRippleAction(self.m_csbNode.m_gridNode, self.m_csbNode.m_grid3D, cc.p(display.width/2,display.height/2))
-- end

function CodeGameScreenKoiBlissMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)

    parentData.symbolType = symbolType

    parentData.order = self:getBounsScatterDataZorder(parentData.symbolType)
    parentData.order = parentData.order - parentData.beginReelIndex
end

return CodeGameScreenKoiBlissMachine
