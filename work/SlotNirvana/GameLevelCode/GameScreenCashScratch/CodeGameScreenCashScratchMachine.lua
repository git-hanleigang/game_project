---
-- island li
-- 2021年12月10日
-- CodeGameScreenCashScratchMachine.lua
--[[
    玩法：

    base:
        出现对应数量cash rush/wild cash rush图标获得对应奖池奖金
    free:
        每触发一次free收集次数+1，第10次触发free为superFree，superFree中 wild/cash rush 图标变为 wild cash rush
    bonsu:
        3个及以上的bonus图标触发刮刮卡玩法
        涂层下有9个图标，出现3个相同图标可获得赢钱，出现多种类型图标超过3个时只获得最大赢钱的图标类型奖励
        bonus档位 根据bet等级解锁
]]

local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCashScratchMachine = class("CodeGameScreenCashScratchMachine", BaseNewReelMachine)



CodeGameScreenCashScratchMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
-- 一些轮盘滚动信号
CodeGameScreenCashScratchMachine.SYMBOL_RapidWild = 100
CodeGameScreenCashScratchMachine.SYMBOL_RapidHits = 101
CodeGameScreenCashScratchMachine.SYMBOL_Bonus_1 = 102
CodeGameScreenCashScratchMachine.SYMBOL_Bonus_2 = 103
CodeGameScreenCashScratchMachine.SYMBOL_Bonus_3 = 104
CodeGameScreenCashScratchMachine.SYMBOL_Bonus_4 = 105
CodeGameScreenCashScratchMachine.SYMBOL_Bonus_5 = 106
-- 刮刮卡的icon信号
    -- 5x、3x、2x、1x、
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_5x = 205
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_3x = 204
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_2x = 203
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_1x = 202
    -- 西瓜、柠檬、山竹、苹果、樱桃 第一张卡的5张icon信号 后面的卡片icon信号依次+100
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon    = 301
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon         = 302
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen    = 303
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple         = 304
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry        = 305
    -- 第二张卡片的icon信号 
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_2    = 401
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_2         = 402
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_2    = 403
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_2         = 404
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_2        = 405
    -- 第三张卡片的icon信号 
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_3    = 501
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_3         = 502
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_3    = 503
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_3         = 504
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_3        = 505
    -- 第四张卡片的icon信号 
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_4    = 601
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_4         = 602
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_4    = 603
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_4         = 604
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_4        = 605
    -- 第五张卡片的icon信号 
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_5    = 701
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_5         = 702
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_5    = 703
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_5         = 704
CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_5        = 705



-- base收集Rapid图标玩法
CodeGameScreenCashScratchMachine.EFFECT_BASE_COLLECTRAPID  = GameEffect.EFFECT_SELF_EFFECT - 100
-- 触发bonus时的 卡片飞行 -> 卡片打印 (改为放在bonus时间触发时)
-- CodeGameScreenCashScratchMachine.EFFECT_BONUS_START_FLYCARD  = GameEffect.EFFECT_SELF_EFFECT - 90

-- 要求打印口的层级要跟随玩法发生变化
CodeGameScreenCashScratchMachine.ORDER = {
    EXPORT_UP       = 150,     -- 打印口 上
    BONUSCARD_UP    = 110,     -- bonus 上
    SPINE_TANBAN    = 100,     -- spineTanban挂点
    BONUSCARD_DOWN  = 90,      -- bonus 下
    REEL            = 60,      -- 棋盘
    EXPORT_DOWN     = 50,      -- 打印口 下
}

-- 构造函数
function CodeGameScreenCashScratchMachine:ctor()
    CodeGameScreenCashScratchMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true

    self.m_spinRestMusicBG = true

    -- superFG 和 平均bat值
    self.m_bInSuperFreeSpin = false
    self.m_avgBet = 0

    -- bet等级
    self.m_iBetLevel = 0
    
    -- bonus断线重连不播飞行
    self.m_bIsBonusReconnect = false

    self:clearBonusGameInitData()

    --init
    self:initGame()
end

function CodeGameScreenCashScratchMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCashScratchMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CashScratch"  
end

function CodeGameScreenCashScratchMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_topScreenList = {}
    for i=1,5 do
        local initData = {
            index = i,
            machine = self,
        }
        local topNodeParent = self:findChild( string.format("top_%d", i-1) )
        local topScreen = util_createView("CodeCashScratchSrc.CashScratchTopScreen", initData)
        topNodeParent:addChild(topScreen)
        table.insert(self.m_topScreenList, topScreen)
    end

    self:initTopScreenSg()
    
    self.m_cardBg = util_createAnimation("CashScratch_machine.csb") 
    self:findChild("machine"):addChild(self.m_cardBg)
    
    self:initTopScreenChaka()

    self.m_export = util_createView("CodeCashScratchSrc.CashScratchBonusExport", self)
    self:findChild("export"):addChild(self.m_export)

    self.m_rightScreen = util_createView("CodeCashScratchSrc.CashScratchRightScreen", self)
    self:findChild("right_screen"):addChild(self.m_rightScreen)
    
    self.m_rightPaytable = util_createView("CodeCashScratchSrc.CashScratchRightPaytable", self)
    self:findChild("right_paytable"):addChild(self.m_rightPaytable)
    self:setRightPaytableWinLineVisible(0)
    self.m_rightPaytable:setVisible(false)

    self.m_jackpotBar = util_createView("CodeCashScratchSrc.CashScratchJackPotBarView", self)
    self:findChild("jackpot"):addChild(self.m_jackpotBar)

    self.m_saoGuangJackpotRight = util_spineCreate("GameScreenCashScratch_jk",true,true)
    self:findChild("saoguang"):addChild(self.m_saoGuangJackpotRight)
    util_spinePlay(self.m_saoGuangJackpotRight, "idleframe", true)

    -- self.m_bonusGame = util_createView("CodeCashScratchSrc.CashScratchBonusGame", {machine=self})
    -- self:findChild("card"):addChild(self.m_bonusGame)
    -- self.m_bonusGame:setVisible(false)
    -- self.m_spineTanbanParent = self:findChild("Node_spineTanban")
    
    self.m_spineTanbanParent = cc.Node:create()
    self:addChild(self.m_spineTanbanParent, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +1)
    --挂点 缩放/坐标适配
    local x = display.width / DESIGN_SIZE.width
    local y = display.height / DESIGN_SIZE.height
    local scale = x / y
    self.m_spineTanbanParent:setScale( math.min(1, scale) )
    local nodePos  = self.m_spineTanbanParent:getParent():convertToNodeSpace(cc.p(display.width/2, display.height/2))
    self.m_spineTanbanParent:setPosition(nodePos)

    self.m_spineTanban_mask = util_createAnimation("CashScratch_dark.csb")
    self.m_spineTanbanParent:addChild(self.m_spineTanban_mask)
    self.m_spineTanban_mask:setVisible(false)

    -- 要求弹板大小放大到1.1
    local curScale = self.m_spineTanbanParent:getScale()
    self.m_spineTanbanParent:setScale(curScale*1.1)
    -- 重新分配一下挂点层级
    -- self.m_spineTanbanParent:setLocalZOrder(self.ORDER.SPINE_TANBAN)
    self:findChild("card"):setLocalZOrder(self.ORDER.BONUSCARD_DOWN)
    self:findChild("checkerboard"):setLocalZOrder(self.ORDER.REEL)

    self:changeGameBgVisible("base")
end


function CodeGameScreenCashScratchMachine:enterGamePlayMusic()
    self:playEnterGameSound( "CashScratchSounds/music_CashScratch_enter.mp3" )
end

function CodeGameScreenCashScratchMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    CodeGameScreenCashScratchMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- 切换数量展示是在时间线内操作的 只能把数量刷新 和 高亮刷新 放在解锁刷新后面
    self:noticCallBack_changeBet()
    if self.m_bIsBonusReconnect then
        -- bonus重连屏蔽spinBtn
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        self:upDateBonusReconnectShow()
        -- 
        local initData = self:getBonusGameInitData()
        local cardData = initData.cardData[initData.cardIndex]
        self:showTopScreenLight(cardData.symbolType)
    else
        -- 开始扫光
        self:startTopScreenSg() 
    end
    --
    self:upDateLockBetCoinsValue()
    -- 右侧free收集次数
    self.m_rightScreen:updateCollectFreeTimes(false)

    
end

function CodeGameScreenCashScratchMachine:addObservers()
    CodeGameScreenCashScratchMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        if nil ~= self.m_bonusGame then
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
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local curSpinMode = self:getCurrSpinMode()
        local soundName = ""
        if curSpinMode == FREE_SPIN_MODE then
            soundName = string.format("CashScratchSounds/sound_CashScratch_winCoin_free_%d.mp3", soundIndex)
        else
            soundName = string.format("CashScratchSounds/sound_CashScratch_winCoin_base_%d.mp3", soundIndex)
        end
        
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    -- bet切换
    gLobalNoticManager:addObserver(self,function(self,params)
        -- 不重写 BaseSlotoManiaMachine:requestSpinResult() 还想带入 betLevel
        self:noticCallBack_changeBet()
   end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenCashScratchMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCashScratchMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    self:stopTopScreenSg()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCashScratchMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == CodeGameScreenCashScratchMachine.SYMBOL_RapidWild then
        return "Socre_CashScratch_Rapid"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_RapidHits then 
        return "Socre_CashScratch_Rapid"

    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_Bonus_1 then 
        return "Socre_CashScratch_Bonus_1"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_Bonus_2 then 
        return "Socre_CashScratch_Bonus_2"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_Bonus_3 then 
        return "Socre_CashScratch_Bonus_3"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_Bonus_4 then 
        return "Socre_CashScratch_Bonus_4"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_Bonus_5 then 
        return "Socre_CashScratch_Bonus_5"

    -- 刮刮卡icon信号 虽然现在都用一个cocos工程 谁知道之后会不会改呢，先麻烦一点全加上
    -- 4乘倍
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_5x then 
        return "Socre_CashScratch_Bonus_4"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_3x then 
        return "Socre_CashScratch_Bonus_3"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_2x then 
        return "Socre_CashScratch_Bonus_2"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_1x then 
        return "Socre_CashScratch_Bonus_1"
    -- 五水果 (每张卡片有自己一套的图标)
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon then 
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen then  
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple then 
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry then 
        return "CashScratch_card_patterns"


    -- 五水果 2
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_2 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_2 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_2 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_2 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_2 then
        return "CashScratch_card_patterns"
    -- 五水果 3
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_3 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_3 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_3 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_3 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_3 then
        return "CashScratch_card_patterns"
    -- 五水果 4
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_4 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_4 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_4 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_4 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_4 then
        return "CashScratch_card_patterns"
     -- 五水果 5
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Watermelon_5 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Lemon_5 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Mangosteen_5 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Apple_5 then
        return "CashScratch_card_patterns"
    elseif symbolType == CodeGameScreenCashScratchMachine.SYMBOL_BONUSCARD_Cherry_5 then
        return "CashScratch_card_patterns"


    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCashScratchMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCashScratchMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_RapidWild,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_RapidHits,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus_1,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus_2,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus_3,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus_4,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus_5,count =  5}

    return loadNode
end

--[[
    ------------------- 一些界面控件
]]
-- 底层背景 | 右侧区域的 paytable 或 jackPot 展示一个
function CodeGameScreenCashScratchMachine:changeGameBgVisible(_modelName)
    local baseReelBg      = self:findChild("reel_bg_base")
    local freeReelBg      = self:findChild("reel_bg_free")
    baseReelBg:setVisible("base" == _modelName)
    freeReelBg:setVisible("base" ~= _modelName)

    
    local switchNode      = self.m_gameBg:findChild("switch")
    local switchBaseNode      = self.m_gameBg:findChild("switch_base")
    local switchFreeNode      = self.m_gameBg:findChild("switch_free")
    local switchSuperFreeNode = self.m_gameBg:findChild("switch_super")

    switchNode:setVisible(true)
    switchBaseNode:setVisible("base" == _modelName)
    switchFreeNode:setVisible("free" == _modelName)
    switchSuperFreeNode:setVisible("superFree" == _modelName)

    self.m_gameBg:runCsbAction("switch", false, function()
        self.m_gameBg:pauseForIndex(0)
        switchNode:setVisible(false)

        local baseNode      = self.m_gameBg:findChild("base")
        local freeNode      = self.m_gameBg:findChild("free")
        local superFreeNode = self.m_gameBg:findChild("super")

        baseNode:setVisible("base" == _modelName)
        freeNode:setVisible("free" == _modelName)
        superFreeNode:setVisible("superFree" == _modelName)
    end)


    local cardBaseNode      = self.m_cardBg:findChild("machine_base")
    local cardSuperFreeNode = self.m_cardBg:findChild("machine_super")

    cardBaseNode:setVisible("superFree" ~= _modelName)
    cardSuperFreeNode:setVisible("superFree" == _modelName)

    self.m_export:changeLightShow("superFree" == _modelName)
end

--[[
    右侧bonus玩法的paytable
]]
-- 根据信号刷新展示
function CodeGameScreenCashScratchMachine:upDateRightPaytableByType(_symbolType)
    self.m_rightPaytable:upDateByType(_symbolType)
end
-- 赢钱线动效可见性
function CodeGameScreenCashScratchMachine:setRightPaytableWinLineVisible(_winIndex)
    for winIndex=1,6 do
        local winNode = self.m_rightPaytable:findChild(string.format("%d", winIndex))
        winNode:setVisible(winIndex == _winIndex)
    end
end
-- 刮卡完成 刷新底栏 和 右侧paytable 展示
function CodeGameScreenCashScratchMachine:showRightPaytableLineAnim(_cardIndex,_cardSymbolType, _winIndex, _fun)
    local triggerJackpot = 6 == _winIndex
    
    -- 修改可见性播放闪烁动画
    self:setRightPaytableWinLineVisible(_winIndex)
    local animName = triggerJackpot and "actionframe2" or "actionframe"
    self.m_rightPaytable:runCsbAction(animName, false, function()

        -- self:levelPerformWithDelay(0.5, function()
            -- jackpot
            if triggerJackpot then
                local jackpotWinCoin = self.m_bonusGame:getCardWinCoins()
                local jockPotIndex   = self:getCashScratchJackpotIndex(_cardSymbolType, nil)
                self:showBonusJackpotView(jockPotIndex, _cardSymbolType, jackpotWinCoin, _fun)
            else
                if _fun then
                    _fun()
                end
            end
        -- end)
        
    end)
    
    -- 底栏赢钱
    self:upDateBonusWinCoins(false, true,_cardIndex)
end
-- 获取赢钱类型索引
function CodeGameScreenCashScratchMachine:getRightPaytableWinIndex(_winSymbolList)
    local wildList = {
        [self.SYMBOL_BONUSCARD_1x] = true,
        [self.SYMBOL_BONUSCARD_2x] = true,
        [self.SYMBOL_BONUSCARD_3x] = true,
        [self.SYMBOL_BONUSCARD_5x] = true,
    }

    -- 3个wild是jackpot赢钱 (6)
    local winSymbol = nil
    if #_winSymbolList > 1 then
        for i,_symbolType in ipairs(_winSymbolList) do
            if not wildList[_symbolType] then
                winSymbol = _symbolType
                break
            end
        end

        if not winSymbol then
            return 6
        end
    else
        winSymbol = _winSymbolList[1]
    end


    -- 其余的是水果赢钱 (1~5)
    local fruitList = {
        self.SYMBOL_BONUSCARD_Cherry,
        self.SYMBOL_BONUSCARD_Apple,
        self.SYMBOL_BONUSCARD_Mangosteen,
        self.SYMBOL_BONUSCARD_Lemon,
        self.SYMBOL_BONUSCARD_Watermelon,
    }

    local winIndex = 1
    for _winIndex,_winSymbol in ipairs(fruitList) do
        if _winSymbol == winSymbol then
            winIndex = _winIndex
            break
        end
    end

    return winIndex
end

--[[
    顶部打印口
]]
function CodeGameScreenCashScratchMachine:playExportAnim(_fun)
    release_print("[CodeGameScreenCashScratchMachine:playExportAnim]")
    self:showSpineTanbanMask(true)
    self:changeSlotsNodeToClipNode()

    self.m_export:getParent():setLocalZOrder(self.ORDER.EXPORT_UP)


    local bonusData = self:getBonusGameInitData()
    --^^^22.06.29bugly cardData is nil
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local sMsg = cjson.encode(selfData)
    print(sMsg)
    release_print(sMsg)
    --^^^
    local cardData  = bonusData.cardData
    local newCardData = {}
    for i,v in ipairs(cardData)do
        table.insert(newCardData,1, v)
    end
    self.m_export:setInitData(newCardData)

    local nextFun = function()
        self:closeSpineTanbanMask(function()
            self.m_export:getParent():setLocalZOrder(self.ORDER.EXPORT_DOWN)
        end)

        if _fun then
            _fun()
        end
    end

    -- 遮罩完全出现 0.5s
    self:levelPerformWithDelay(0.5, function()

        local nextFun_1 = nextFun
        self.m_export:playLightAnim(function()

            self.m_export:playExportAnim(1, function()

                if nextFun_1 then
                    nextFun_1()
                end
               
            end )
        end)
    end)
end
--[[
    轮盘裁剪区域
]]
function CodeGameScreenCashScratchMachine:changeSlotsNodeToClipNode()
    local clipNode = self.m_onceClipNodeEffect

    local childs = self.m_clipParent:getChildren()
    for i,_node in ipairs(childs) do
        if _node.p_layerTag ~= nil and _node.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            local pos = util_convertToNodeSpace(_node, clipNode)
            util_changeNodeParent(clipNode, _node, _node.m_showOrder)
            _node:setPosition(pos)
        end
    end
    -- 断线重连时轮盘上的超框信号
    local symbolList = {
        [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = true,
    }
    for _iCol,_slotParentData in ipairs(self.m_slotParents) do
        childs = _slotParentData.slotParent:getChildren()
        for i,_node in ipairs(childs) do
            if _node.m_isLastSymbol and _node.p_rowIndex <= self.m_iReelRowNum then
                if symbolList[_node.p_symbolType] then
                    local pos = util_convertToNodeSpace(_node, clipNode)
                    util_changeNodeParent(clipNode, _node, _node.m_showOrder)
                    _node:setPosition(pos)
                end
            end
        end
    end
end
function CodeGameScreenCashScratchMachine:changeSlotsNodeToReel()
    local childs = self.m_onceClipNodeEffect:getChildren()
    for i,_node in ipairs(childs) do
        -- 
        if _node.p_layerTag ~= nil and _node.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            local slotParent = self.m_slotParents[_node.p_cloumnIndex].slotParent
            local pos = util_convertToNodeSpace(_node, slotParent)
            util_changeNodeParent(slotParent, _node, _node.m_showOrder)
            _node:setPosition(pos)
        elseif _node.m_isLastSymbol and _node.p_rowIndex <= self.m_iReelRowNum then
            local slotParent = self.m_slotParents[_node.p_cloumnIndex].slotParent
            local pos = util_convertToNodeSpace(_node, slotParent)
            util_changeNodeParent(slotParent, _node, _node.m_showOrder)
            _node:setPosition(pos)
        end
    end
end

--[[
    顶部扫光
]]
function CodeGameScreenCashScratchMachine:initTopScreenSg()
    self.m_TopScreenSgList = {}


    for i,_topScreen in ipairs(self.m_topScreenList) do
        local parent = _topScreen:findChild("saoguang")
        local sgAnim =  util_createAnimation("CashScratch_top_screen_sg.csb")
        parent:addChild(sgAnim)
        table.insert(self.m_TopScreenSgList, sgAnim)
    end
end
function CodeGameScreenCashScratchMachine:startTopScreenSg()
    local scheduleNode =  self:findChild("top_screen")

    self.m_curSgBonusIndex = 1
    local topScreenSg   = self.m_TopScreenSgList[self.m_curSgBonusIndex]
    topScreenSg:runCsbAction("actionframe")

    self.m_upDateTopScreenSg = schedule(scheduleNode, function()
        
        -- 拿下一个入口的锁定状态
        if self.m_curSgBonusIndex + 1 > #self.m_topScreenList then
            self.m_curSgBonusIndex   =  1
        else
            self.m_curSgBonusIndex   =  self.m_curSgBonusIndex + 1
            local topScreen = self.m_topScreenList[self.m_curSgBonusIndex]
            if topScreen:getLockState() then
                self.m_curSgBonusIndex   = 1
            end
        end

        topScreenSg = self.m_TopScreenSgList[self.m_curSgBonusIndex]
        topScreenSg:runCsbAction("actionframe")
    end,50/60)
end
function CodeGameScreenCashScratchMachine:stopTopScreenSg()
    if self.m_upDateTopScreenSg then
        self:findChild("top_screen"):stopAllActions()
        self.m_upDateTopScreenSg = nil
        -- 停掉正在播放的扫光
        local topScreenSg = self.m_TopScreenSgList[self.m_curSgBonusIndex]
        topScreenSg:pauseForIndex(0)
    end
end
function CodeGameScreenCashScratchMachine:upDateTopScreenSg()
    if not self.m_upDateTopScreenSg then
        return
    end

    local topScreen = self.m_topScreenList[self.m_curSgBonusIndex]

    -- 判断一下当前播放的扫光入口是否被锁定了， 锁定时 重置扫光
    if topScreen:getLockState() then
        self:stopTopScreenSg()
        self:startTopScreenSg()
    end
end
--[[
    TopScreen
]]
function CodeGameScreenCashScratchMachine:resetTopScreenAllCardCount(_count,_changeLab)
    for i,_topScreen in ipairs(self.m_topScreenList) do
        _topScreen:resetCardCount(_count)
        if _changeLab then
            _topScreen:upDateCardCountLab()
        end
    end
end
function CodeGameScreenCashScratchMachine:playTopScreenFlyCardEndAnim(_symbolType)
    local bonusIndex = self:getCashScratchBonusSymbolIndex(_symbolType)
    local topScreen = self.m_topScreenList[bonusIndex]
    -- 首次飞行增加次数
    if topScreen.m_cardCount < 0 then
        topScreen:resetCardCount(0)
        topScreen:upDateCardCountLab(1)
    end
    topScreen:playFlyCardEndAnim()

    self:playTopScreenChakaAnim(_symbolType)
end
-- 投卡入口效果
function CodeGameScreenCashScratchMachine:initTopScreenChaka()
    local parent = self:findChild("top_screen")
    self.m_chakaAnim = {}
    for _bonusIndex=1,5 do
        local anim = util_createAnimation("CashScratch_machine_chaka.csb") 
        parent:addChild(anim)
        local fankuiNode   = self.m_cardBg:findChild( string.format("fankui%d", _bonusIndex) )
        local pos = util_convertToNodeSpace(fankuiNode, parent)
        anim:setPosition(pos)
        anim:setVisible(false)

        table.insert(self.m_chakaAnim, anim)
    end
end
function CodeGameScreenCashScratchMachine:playTopScreenChakaAnim(_symbolType)
    local bonusIndex = self:getCashScratchBonusSymbolIndex(_symbolType)
    local chakaAnim  = self.m_chakaAnim[bonusIndex]
    chakaAnim:setVisible(true)
    chakaAnim:runCsbAction("actionframe", false, function()
        chakaAnim:setVisible(false)
    end)
end
-- 播放刮卡时高亮时间线
function CodeGameScreenCashScratchMachine:showTopScreenLight(_symbolType)
    local bonusIndex = self:getCashScratchBonusSymbolIndex(_symbolType)
    for i,_topScreen in ipairs(self.m_topScreenList) do
        _topScreen:changLightAnim(bonusIndex == i)
    end
end
function CodeGameScreenCashScratchMachine:hideTopScreenLight()
    for i,_topScreen in ipairs(self.m_topScreenList) do
        _topScreen:changLightAnim(true)
        _topScreen:resetShowCoinsState()
    end
    self:upDateLockBetCoinsVisible(self:getCashScratchCurBet())
end

--[[
    解锁bet相关展示 TopScreen | rightScreen 
]]
function CodeGameScreenCashScratchMachine:upDateLockBetCoinsValue()
    if self.m_specialBets then
        for i=1,5 do
            if 1 ~= i then
                local index = i -1
                local betData = self.m_specialBets[index]

                if betData then
                    local topScreen = self.m_topScreenList[i]
                    topScreen:setLockBetCoins(betData.p_totalBetValue)

                    self.m_jackpotBar:setLockBetCoins(betData.p_totalBetValue, i)
                end
            end
        end

    end
end

function CodeGameScreenCashScratchMachine:upDateLockBetCoinsVisible(_betCoins)
    if self.m_specialBets then
        for i=1,5 do
            local topScreen = self.m_topScreenList[i]

            if 1 == i then
                topScreen:setLockBetVisible(false)
                self.m_jackpotBar:setLockBetVisible(false, i)
            else
                local index = i -1
                local betData = self.m_specialBets[index]

                if betData then
                    local visible = _betCoins < tonumber(betData.p_totalBetValue) 
                    topScreen:setLockBetVisible(visible)

                    self.m_jackpotBar:setLockBetVisible(visible, i) 
                end
            end
        end
    end
end

-- jackpotLock

----------------------------- 玩法处理 -----------------------------------
-- base收集图标
function CodeGameScreenCashScratchMachine:isTriggerBaseCollectRapid()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if selfData.rapidpos and selfData.rapidwin then
        return true
    end
    
    return false
end

function CodeGameScreenCashScratchMachine:playEffect_baseCollectRapid(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData

    local count = selfData.rapidcount or #selfData.rapidpos
    local coins = selfData.rapidwin
    
    gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_rapid_actionframe.mp3")
    -- 小块 和 jackpot栏动画
    for i,_sPos in ipairs(selfData.rapidpos) do
        local iPos = tonumber(_sPos)
        local fixPos = self:getRowAndColByPos(iPos)
        local slotsNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        
        self:removeRapidLine(iPos)
        local animName = slotsNode.p_symbolType == self.SYMBOL_RapidWild and "actionframe2" or "actionframe"
        slotsNode:runAnim(animName, true)
    end
    self.m_jackpotBar:playJackpotWinAnim(count)

    -- jackpot弹板
    local animTime = 90/30
    self:levelPerformWithDelay(animTime, function()

        local soundIndex = 0
        if count >= 9 then
            soundIndex = 9
        elseif count >= 7 then
            soundIndex = 7
        elseif count >= 5 then
            soundIndex = 5
        end
        local soundName = string.format("CashScratchSounds/sound_CashScratch_rapid_%d.mp3", soundIndex)
        gLobalSoundManager:playSound(soundName)

        local jockPotIndex = self:getCashScratchJackpotIndex(nil, count)
        local newFun = function()
            self.m_jackpotBar:hideJackpotWinAnim()

            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                -- freeSpin下特殊玩法的算钱逻辑
                if #self.m_vecGetLineInfo == 0  then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})
                    if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
                        self.m_iOnceSpinLastWin = self.m_serverWinCoins
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{coins, GameEffect.EFFECT_BONUS})
                        self:sortGameEffects()
                    end
                end
            else
                if #self.m_vecGetLineInfo == 0 then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})
                    if not self.m_bProduceSlots_InFreeSpin  then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                    end
                    if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
                        self.m_iOnceSpinLastWin = self.m_serverWinCoins
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{coins, GameEffect.EFFECT_BONUS})
                        self:sortGameEffects()
                    end
                end
            end

            if _fun then
                _fun()
            end
        end
        self:showJackPotView(jockPotIndex, count, coins, newFun)
    end)
end
function CodeGameScreenCashScratchMachine:removeRapidLine(_iRapidPos)
    local fixPos = self:getRowAndColByPos(_iRapidPos)

    for _lineIndex=#self.m_reelResultLines,1,-1 do
        local lineData = self.m_reelResultLines[_lineIndex]
        for i=#lineData.vecValidMatrixSymPos,1,-1 do
            local lineSymbolPos = lineData.vecValidMatrixSymPos[i]
            if lineSymbolPos.iX == fixPos.iX and lineSymbolPos.iY == fixPos.iY then
                table.remove(lineData.vecValidMatrixSymPos, i)
            end
        end
        lineData.iLineSymbolNum = #lineData.vecValidMatrixSymPos
    end

end

function CodeGameScreenCashScratchMachine:showJackPotView(_jockPotIndex, _count, _coins, _fun)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_coins, _jockPotIndex)

    local view       = util_createView("CodeCashScratchSrc.CashScratchJackPotWinView", {
        machine      = self,
        count        = _count,
        coins        = _coins,
    })
    local secondView = util_createView("CodeCashScratchSrc.CashScratchJackPotWinView", {
        machine      = self,
        isSecondView = true,
        count        = _count,
        coins        = _coins,
    })

    local overFun = function()
        if _fun then
            _fun()
        end
        self.m_jackpotBar:upDateJackpotWinAnimVisible(0)
    end

    local clickFun = function()
        if view.m_updateAction then
            view:stopUpDateCoins()
            view:setFinalWinCoins()
        end
    end

    local data = {
        dialogName = "", 
        ownerlist  = {}, 
        autoType   = nil,   
        func       = overFun, 

        bindNode   = "shuzi6",
        skinName   = "Jackpot",

        view       = view,
        secondView = secondView,

        clickFun   = clickFun,
    }

    gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_jackpot_start.mp3")

    local view = self:addCocosViewToSpineTanban(data)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.05,sy=1.05}, 548)
end


-- 触发bonus玩法
function CodeGameScreenCashScratchMachine:isTriggerBonusFlyCard()
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra or {}
    local storedIcons = bonusExtra.storedIcons or {}
    local cardCount = bonusExtra.cardCount or 0

    return #storedIcons > 0 and cardCount > 0
end
function CodeGameScreenCashScratchMachine:playEffect_bonusFlyCard(_fun)
    if self.m_bIsBonusReconnect then
        self:changeSlotsNodeToClipNode()

        if _fun then
            _fun()
        end
        return
    end

    local soundList = {
        "CashScratchSounds/sound_CashScratch_bonus_actionframe_1.mp3",
        "CashScratchSounds/sound_CashScratch_bonus_actionframe_2.mp3"
    }
    local soundName = soundList[math.random(1, #soundList)]
    gLobalSoundManager:playSound(soundName)

    local flyTime  = 12/30
    local animTime = 18/30
    -- 不计算粒子时间 被覆盖也可以
    local cardTime = flyTime -- + 25/60

    local bonusExtra = self.m_runSpinResultData.p_bonusExtra or {}
    local storedIcons = bonusExtra.storedIcons or {}

    for i,_cardData in ipairs(storedIcons) do
        local cardIndex = i
       
        self:levelPerformWithDelay((i-1)*cardTime, function()
            local cardData = storedIcons[cardIndex]
            -- 创建
            local iPos = tonumber(cardData[1])
            local fixPos = self:getRowAndColByPos(iPos)
            local slotsNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            local flyNode = self:createCashScratchTempSymbol(slotsNode.p_symbolType)
            local order = GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1
            self:addChild(flyNode, order)
            flyNode:setScale(self.m_machineRootScale)
            -- 飞行
            local startPos = util_convertToNodeSpace(slotsNode, self)
            local endPos   = self:getFlyCardEndPos(slotsNode.p_symbolType)
            flyNode:setPosition(startPos)

            local actPlayAnim = cc.CallFunc:create(function()
                gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_card_shouji.mp3")
                self:runCashScratchTempSymbolAnim(flyNode, "shouji", false)
            end)
            local actMove     = cc.MoveTo:create(flyTime, endPos)
            local actDelay    = cc.DelayTime:create(animTime-flyTime)
            local actFun      = cc.CallFunc:create(function()
                self:playTopScreenFlyCardEndAnim(cardData[2])
            end)
            local actRemove   = cc.RemoveSelf:create()
            local actSeq    = cc.Sequence:create(
                actPlayAnim,
                actMove, 
                actDelay,
                actFun,
                actRemove
            )

            flyNode:runAction(actSeq)
        end)
    end
    
    -- 所有卡片飞行时间
    self:levelPerformWithDelay(#storedIcons * cardTime+25/60, function()

        -- 打印卡片列表
        self:playExportAnim(_fun)
    end)
end
function CodeGameScreenCashScratchMachine:getFlyCardEndPos(_symbolType)
    local endPos = util_convertToNodeSpace(self.m_cardBg:findChild("fankui1"), self) 

    for cardSymbolType=self.SYMBOL_Bonus_1,self.SYMBOL_Bonus_5 do
        if _symbolType == cardSymbolType then
            -- fankui1 ~ fankui5
            local nodeIndex = cardSymbolType - self.SYMBOL_Bonus_1 + 1
            local endNode   = self.m_cardBg:findChild( string.format("fankui%d", nodeIndex) )
            endPos = util_convertToNodeSpace(endNode, self)
            return  endPos
        end
    end

    return endPos
end

function CodeGameScreenCashScratchMachine:upDateBonusReconnectShow()
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra or {}
    local storedIcons = bonusExtra.storedIcons or {}
    local totalTimes   = #storedIcons
    local surplusTimes = tonumber(bonusExtra.cardCount)
    local cardIndex = totalTimes - surplusTimes + 1

    -- 顶部卡片数量
    local cardCountList = {}
    for i,_cardData in ipairs(storedIcons) do
        local bonusIndex = self:getCashScratchBonusSymbolIndex(_cardData[2])
        if cardCountList[bonusIndex] then
            cardCountList[bonusIndex] = cardCountList[bonusIndex] + 1
        else
            cardCountList[bonusIndex] = 1
        end

        -- 断线前刮过了
        if i < cardIndex then
            cardCountList[bonusIndex] = cardCountList[bonusIndex] - 1
        end
    end

    for _bonusIndex,_count in pairs(cardCountList) do
        local topScreen = self.m_topScreenList[_bonusIndex]
        topScreen:playFlyCardEndAnim(_count)
    end
end
--[[
    临时信号小块，不使用 池子的那一套，有可能泄漏
    create
    runAnim
]]
function CodeGameScreenCashScratchMachine:createCashScratchTempSymbol(_symbolType)
    local symbol = nil

    local spineSymbolData = self.m_configData:getSpineSymbol(_symbolType)
    local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
    -- 区分 spine 和 cocos
    if nil ~= spineSymbolData then
        symbol = util_spineCreate(ccbName,true,true)
    else
        symbol = util_createAnimation( string.format("%s.csb", ccbName) )
    end

    -- 存一下自身的一些数据
    symbol.m_symbolType = _symbolType

    return symbol
end
function CodeGameScreenCashScratchMachine:runCashScratchTempSymbolAnim(_tempSymbol,  _animName, _loop, _fun)
    local symbolType = _tempSymbol.m_symbolType
    local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
    -- 区分 spine 和 cocos
    if nil ~= spineSymbolData then
        util_spinePlay(_tempSymbol, _animName, _loop)
        if _fun ~= nil then
            util_spineEndCallFunc(_tempSymbol, _animName, _fun)
        end
    else
        util_csbPlayForKey(_tempSymbol.m_csbAct, _animName, _loop, _fun)
    end
end


---
-- 初始化上次游戏状态数据
--
function CodeGameScreenCashScratchMachine:initGameStatusData(gameData)
    CodeGameScreenCashScratchMachine.super.initGameStatusData(self, gameData)

    -- print(cjson.encode(gameData))
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    self.m_avgBet = 0
    if gameData then
        if gameData.spin then
            if gameData.spin.freespin then
                if gameData.spin.freespin.extra then
                    if gameData.spin.freespin.extra.avgBet then
                        self.m_avgBet = gameData.spin.freespin.extra.avgBet
                    end
                end
            end
        end
    end

end
-- 断线重连 
function CodeGameScreenCashScratchMachine:MachineRule_initGame(  )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if self.m_bProduceSlots_InFreeSpin then

        local curTimes   = selfData.triggerTimes or 0
        local totalTimes = selfData.totalFreespinCount or 10
        self.m_bInSuperFreeSpin = curTimes == totalTimes

        local resultData = self.m_runSpinResultData
        if resultData.p_freeSpinsLeftCount ~= resultData.p_freeSpinsTotalCount then
            -- 刷新根据玩法展示的控件
            local modelName = self:getCashScratchCurModelName(false)
            self:changeGameBgVisible(modelName)
            self.m_rightScreen:changeShowByModel(modelName)
            if self.m_bInSuperFreeSpin then
                self.m_bottomUI:showAverageBet()
            end
            self.m_rightScreen:changeFreeSpinByCount()
        end
        
    end

    if self:isTriggerBonusFlyCard() then
        self.m_bIsBonusReconnect = true
        
        self:saveBonusGameInitData()
        self:upDateBonusWinCoins(true, false)
    else
        -- 处理处于free模式中 刚好把刮卡次数用完 然后重连的情况
        if self.m_bProduceSlots_InFreeSpin then
            local bonusExtra = self.m_runSpinResultData.p_bonusExtra or {}
            local storedIcons = bonusExtra.storedIcons or {}
            local cardCount = bonusExtra.cardCount or 0

            if #storedIcons > 0 then
                self:upDateBonusWinCoins(true, false)
            end
        end
    end
    self:changeBonusEffectOrder()
end

function CodeGameScreenCashScratchMachine:initFeatureInfo(spinData, featureData)
    if self:isTriggerBonusFlyCard() then
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        local collectLeftCount = globalData.slotRunData.freeSpinCount
        if (collectLeftCount > 0 and collectLeftCount ~= collectTotalCount) then
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN + 1
        else
            
        end

        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    end
end


--
--单列滚动停止回调
--
function CodeGameScreenCashScratchMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCashScratchMachine.super.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCashScratchMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCashScratchMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenCashScratchMachine:showFreeSpinView(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local nextFun = function()
            effectData.p_isPlay = true
            self:playGameEffect()       
        end
        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,nextFun,true )
    else
        local curTimes   = selfData.triggerTimes or 0
        local totalTimes = selfData.totalFreespinCount or 10
        self.m_bInSuperFreeSpin = curTimes == totalTimes

        self.m_rightScreen:changeFreeSpinByCount()

        local nextFun = function()
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()       
        end
        local overFun = function()
            -- 刷新根据玩法展示的控件
            local modelName = self:getCashScratchCurModelName()
            self:changeGameBgVisible(modelName)
            self.m_rightScreen:changeShowByModel(modelName)
            if self.m_bInSuperFreeSpin then
                self.m_bottomUI:showAverageBet()
                self:noticCallBack_changeBet()
            end
            
        end

        -- 右侧free收集次数
        local animTime = self.m_rightScreen:updateCollectFreeTimes(true)
        self:levelPerformWithDelay(animTime, function()
            self:showFreeSpinStart(self.m_iFreeSpinTimes,nextFun, nil, overFun)
        end)
    end

end
-- @ overFun : 结束时间线开始时执行的逻辑
function CodeGameScreenCashScratchMachine:showFreeSpinStart(num, func, isAuto, overFun)
    local dialogName = self.m_bInSuperFreeSpin and "SuperFreeSpinStart" or BaseDialog.DIALOG_TYPE_FREESPIN_START 

    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local skinName = self.m_bInSuperFreeSpin and "SuperFreeStart" or BaseDialog.DIALOG_TYPE_FREESPIN_START
    local bindNode = self.m_bInSuperFreeSpin and "shuzi2" or "shuzi8"

    local data = {
        dialogName      = dialogName, 
        ownerlist       = ownerlist, 
        autoType        = isAuto and BaseDialog.AUTO_TYPE_NOMAL,   
        func            = func, 

        bindNode        = bindNode,
        skinName        = skinName,

        btnClickFunc    = overFun,
    }

    local soundName = ""
    if self.m_bInSuperFreeSpin then
        soundName = "CashScratchSounds/sound_CashScratch_superView_start.mp3"
    else
        soundName = "CashScratchSounds/sound_CashScratch_freeView_start.mp3"
    end
    gLobalSoundManager:playSound(soundName)

    return self:addCocosViewToSpineTanban(data)
end

function CodeGameScreenCashScratchMachine:showFreeSpinMore(num, func, isAuto)
    local dialogName = self.m_bInSuperFreeSpin and "SuperFreeSpinMore" or BaseDialog.DIALOG_TYPE_FREESPIN_MORE

    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local skinName = self.m_bInSuperFreeSpin and "SuperFreeSpinMore" or "FreeSpinMore"

    local function newFunc()
        self:resetMusicBg(true)

        -- 刷新freeSpin次数
        gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_free_addTimes.mp3")
        
        local curTotalTimes = self.m_rightScreen.m_freespinTotalTimes
        local newTotalTimes = globalData.slotRunData.totalFreeSpinCount
        if curTotalTimes ~= newTotalTimes then
            self.m_rightScreen:playFreeSpinMoreAnim()
        end
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local data = {
        dialogName = dialogName, 
        ownerlist  = ownerlist, 
        autoType   = isAuto and BaseDialog.AUTO_TYPE_ONLY,   
        func       = newFunc, 

        bindNode   = "shuzi8",
        skinName   = skinName,
    }

    local soundName = ""
    if self.m_bInSuperFreeSpin then
        soundName = "CashScratchSounds/sound_CashScratch_superView_more.mp3"
    else
        soundName = "CashScratchSounds/sound_CashScratch_freeView_more.mp3"
    end
    gLobalSoundManager:playSound(soundName)

    return self:addCocosViewToSpineTanban(data)
end

function CodeGameScreenCashScratchMachine:showFreeSpinOverView()
    -- 右侧free收集次数
    self.m_rightScreen:updateCollectFreeTimes(false)
   -- gLobalSoundManager:playSound("CashScratchSounds/music_CashScratch_over_fs.mp3")

   local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( 
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            -- 刷新根据玩法展示的控件
            local modelName = self:getCashScratchCurModelName()
            self:changeGameBgVisible(modelName)
            self.m_rightScreen:changeShowByModel(modelName)
            if self.m_bInSuperFreeSpin then
                self.m_bottomUI:hideAverageBet()
                self.m_bInSuperFreeSpin = false
                self:noticCallBack_changeBet()
            end

            self:triggerFreeSpinOverCallFun()
        end
    )
end

function CodeGameScreenCashScratchMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()

    local dialogName = self.m_bInSuperFreeSpin and "SuperFreeSpinOver" or BaseDialog.DIALOG_TYPE_FREESPIN_OVER

    local ownerlist = {}
    ownerlist["m_lb_num"]   = num
    ownerlist["m_lb_coins"] = coins
    
    local skinName = self.m_bInSuperFreeSpin and "SuperFreeOver" or BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    local bindNode = self.m_bInSuperFreeSpin and "shuzi4" or "shuzi1"

    local data = {
        dialogName = dialogName, 
        ownerlist  = ownerlist, 
        autoType   = nil,   
        func       = func, 

        bindNode   = bindNode,
        skinName   = skinName,
    }

    local soundName = ""
    if self.m_bInSuperFreeSpin then
        soundName = "CashScratchSounds/sound_CashScratch_superView_over.mp3"
    else
        soundName = "CashScratchSounds/sound_CashScratch_freeView_over.mp3"
    end
    gLobalSoundManager:playSound(soundName)

    local view = self:addCocosViewToSpineTanban(data)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.05,sy=1.05}, 548)

    return view
end

----------- Bonus相关
function CodeGameScreenCashScratchMachine:showBonusGameView(effectData)
    self.m_bonusEffect = effectData
    --停止顶部扫光
    self:stopTopScreenSg()
    -- 触发bonus时有连线则等一下连线 不希望第二次连线框出现
    local delayTime = 0.1
    if self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
        delayTime = 1 + 1 - 0.1
    end

    self:levelPerformWithDelay(delayTime, function()
        self:clearWinLineEffect()

        -- 清理连线
        if not self.m_bIsBonusReconnect and not self.m_bProduceSlots_InFreeSpin then
            self:setLastWinCoin(0)

            -- 底栏
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                self.m_bottomUI:resetWinLabel()
                self.m_bottomUI:checkClearWinLabel()
            end
        end

        self:resetMusicBg(nil,"CashScratchSounds/music_CashScratch_bonus.mp3")

        -- 卡片飞行 | 打印卡片 
        self:playEffect_bonusFlyCard(function()
            -- 切换展示 
            self.m_rightScreen:changeShowByModel("bonus")
            self.m_rightPaytable:setVisible(true)
            self.m_rightPaytable:showPaytableAnim()
            self.m_saoGuangJackpotRight:setVisible(false)
            self.m_jackpotBar:hideJackpotBar(function()
                self.m_jackpotBar:setVisible(false)
            end)
            local modelName = self:getCashScratchCurModelName(false)
            self:changeGameBgVisible(modelName)

            -- 开始刮卡
            self.m_bonusGame = util_createView("CodeCashScratchSrc.CashScratchBonusGame", {machine=self})
            self:findChild("card"):addChild(self.m_bonusGame)
            local initData = self:getBonusGameInitData()
            self.m_bonusGame:setInitData(initData)
            self.m_bonusGame:startBonusGame()
        end)
    end)
end

-- 组织整理一下回传数据 先保存，之后使用
function CodeGameScreenCashScratchMachine:saveBonusGameInitData()
    self:clearBonusGameInitData()
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local storedIcons = bonusExtra.storedIcons or {}

    local totalTimes   = #storedIcons
    local surplusTimes = tonumber(bonusExtra.cardCount)

    self.m_bonusInitData.machine = self 
    -- 当前卡片索引 = 总次数 - 剩余次数 + 1
    self.m_bonusInitData.cardIndex = totalTimes - surplusTimes + 1

    -- 每张卡片的 坐标、卡片类型、赢钱、赢钱信号、9个icon
    self.m_bonusInitData.cardData = {}
    for _index,_data in ipairs(storedIcons) do
        local cardData = {
            cardIndex       = _index,
            iPos            = tonumber(_data[1]),
            symbolType      = tonumber(_data[2]),
            winCoin         = tonumber(_data[3]),
            winSymbolType   = clone(_data[4]), 
            curJackpot      = tonumber(_data[5]),
            icon            = clone(bonusExtra.icon[_index]),
        }
        table.insert(self.m_bonusInitData.cardData, cardData)
    end

    -- 玩法结束回调
    self.m_bonusInitData.overFun = function()
        if self.m_bonusGame then
            self.m_bonusGame:removeFromParent()
            self.m_bonusGame = nil
        end
        -- self.m_bonusGame:setVisible(false)

        self:resetMusicBg()
        self:setMaxMusicBGVolume( )

        local modelName = self:getCashScratchCurModelName()
        self:changeGameBgVisible(modelName)
        self.m_rightScreen:changeShowByModel(modelName)
        self.m_rightPaytable:hidePaytableAnim(function()
            self.m_rightPaytable:setVisible(false)
        end)
        self.m_jackpotBar:setVisible(true)
        self.m_jackpotBar:showJackpotBar(function()
            self.m_saoGuangJackpotRight:setVisible(true)
        end)
        -- 恢复顶部扫光
        self:startTopScreenSg()

        self:changeSlotsNodeToReel()
        self:clearBonusGameInitData()
        self.m_bIsBonusReconnect = false

        if nil ~= self.m_bonusEffect then
            self.m_bonusEffect.p_isPlay= true
            self.m_bonusEffect = nil
            self:playGameEffect()
        end
    end

    release_print("[CodeGameScreenCashScratchMachine:saveBonusGameInitData]")
end
function CodeGameScreenCashScratchMachine:clearBonusGameInitData()
    release_print("[CodeGameScreenCashScratchMachine:clearBonusGameInitData]")
    self.m_bonusInitData = {}
end
function CodeGameScreenCashScratchMachine:getBonusGameInitData()
    release_print("[CodeGameScreenCashScratchMachine:getBonusGameInitData]")
    return self.m_bonusInitData
end

function CodeGameScreenCashScratchMachine:showBonusJackpotView(_jockPotIndex, _cardSymbolType, _coins, _fun) 
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_coins, _jockPotIndex)

    local view       = util_createView("CodeCashScratchSrc.CashScratchBonusJackPotWinView", {
        machine        = self,
        jockPotIndex   = _jockPotIndex,
        cardSymbolType = _cardSymbolType,
        coins          = _coins,
    })
    local secondView = util_createView("CodeCashScratchSrc.CashScratchBonusJackPotWinView", {
        isSecondView   = true,
        machine        = self,
        jockPotIndex   = _jockPotIndex,
        cardSymbolType = _cardSymbolType,
        coins          = _coins,
    })

    local clickFun = function()
        if view.m_updateAction then
            view:stopUpDateCoins()
            view:setFinalWinCoins()
        end
    end

    local data = {
        dialogName = "", 
        ownerlist  = {}, 
        autoType   = nil,   
        func       = _fun, 

        bindNode   = "suzi1",
        skinName   = "CardJackpot",

        view       = view,
        secondView = secondView,

        clickFun   = clickFun,
    }

    gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_jackpot_start.mp3")
    -- gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_bonusJackpot_start.mp3")

    self:addCocosViewToSpineTanban(data)
end

function CodeGameScreenCashScratchMachine:showCashScratchBonusOverView(_winCoin, _fun)

    local view       = util_createView("CodeCashScratchSrc.CashScratchBonusOverView", {
        coins          = _winCoin,
    })
    local secondView = util_createView("CodeCashScratchSrc.CashScratchBonusOverView", {
        isSecondView = true,
        coins        = _winCoin,
    })

    local clickFun = function()
        if view.m_updateAction then
            view:stopUpDateCoins()
            view:setFinalWinCoins()
        end
    end

    local data = {
        dialogName = "", 
        ownerlist  = {}, 
        autoType   = nil,   
        func       = _fun, 

        bindNode   = "suzi1",
        skinName   = "BonusOver",

        view       = view,
        secondView = secondView,

        clickFun   = clickFun,
    }

    gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_bonusView_over.mp3")

    self:addCocosViewToSpineTanban(data)
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCashScratchMachine:MachineRule_SpinBtnCall()

    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCashScratchMachine:addSelfEffect()
    if self:isTriggerBaseCollectRapid() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType  = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_COLLECTRAPID
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_COLLECTRAPID 

        
    end
    
    if self:isTriggerBonusFlyCard() then
        self:saveBonusGameInitData()
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType  = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = self.EFFECT_BONUS_START_FLYCARD
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.EFFECT_BONUS_START_FLYCARD 
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCashScratchMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BASE_COLLECTRAPID then
        self:playEffect_baseCollectRapid(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    -- elseif effectData.p_selfEffectType == self.EFFECT_BONUS_START_FLYCARD then
    --     self:playEffect_bonusFlyCard(function()
    --         effectData.p_isPlay = true
    --         self:playGameEffect()
    --     end)
        
    end

    
    return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCashScratchMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenCashScratchMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenCashScratchMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenCashScratchMachine:slotReelDown( )
    CodeGameScreenCashScratchMachine.super.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenCashScratchMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


--[[
    事件通知监听
]]
function CodeGameScreenCashScratchMachine:noticCallBack_changeBet(_betCoins)
    self.m_iBetLevel = 0
    local betCoins =_betCoins or self:getCashScratchCurBet()

    for _betLevel,_betData in ipairs(self.m_specialBets) do
        if betCoins < _betData.p_totalBetValue then
            break
        end
        self.m_iBetLevel = _betLevel
    end

    self:upDateLockBetCoinsVisible(betCoins)

    self:upDateTopScreenSg()
end
--[[
    其他判断逻辑 和 工具接口
]]
-- ABTest A组五个刮刮卡使用五套资源 B组五个刮刮卡使用另外一套资源
function CodeGameScreenCashScratchMachine:checkCashScratchABTest()
    return globalData.GameConfig:checkABtestGroupA("CashScratchSymbol")
end

function CodeGameScreenCashScratchMachine:getCashScratchCurBet()
    if self.m_bInSuperFreeSpin and self.m_avgBet ~= 0 then
        return self.m_avgBet
    else
        return globalData.slotRunData:getCurTotalBet()
    end
end
-- 点击jackpot解锁bet等级
function CodeGameScreenCashScratchMachine:isCanUnLockJackpot(_unLockCoin)
    -- 没有初始化解锁数值
    if 0 == _unLockCoin then
        return
    end

    -- 没有停轮
    local spinStage =  self:getGameSpinStage()
    if spinStage ~= IDLE then
        return false
    end

    -- 不在base
    local spinMode  = self:getCurrSpinMode()
    if spinMode ~= NORMAL_SPIN_MODE then
        return false
    end

    -- 在执行一个事件玩法
    if true == self.m_isRunningEffect then
        return false
    end

    return true
end
function CodeGameScreenCashScratchMachine:clickUnLockBet(_unLockCoin)
    if 0 == _unLockCoin then
        return
    end
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()

    for i,_betData in ipairs(betList) do
        if _betData.p_totalBetValue >= _unLockCoin then
            globalData.slotRunData.iLastBetIdx = _betData.p_betId
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
            break
        end
    end
end


--[[
    _cardData = {
        winSymbolType = 0,
        winCoin       = 0,
        symbolType    = 0,
        curJackpot    = 0
    }
]]
function CodeGameScreenCashScratchMachine:getBonusCardWinUpCoins(_cardData)
    local coins = 0

    local winIndex = self:getRightPaytableWinIndex(_cardData.winSymbolType)
    -- jackpot赢钱
    if 6 == winIndex then
       coins = _cardData.winCoin
    -- 普通赢钱
    else
        coins = _cardData.curJackpot
    end

    return coins
end
-- 处理bonus赢钱展示 (包含断线重连)
function CodeGameScreenCashScratchMachine:upDateBonusWinCoins(_addAllWinCoins,_playWinSound,_cardIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local storedIcons = bonusExtra.storedIcons or {}

    -- 当前卡片索引 ，卡片总赢钱
    local cardIndex     = _cardIndex
    local cardWinCoins  = 0

    if not cardIndex then
        -- 当前卡片索引 = 总次数 - 剩余次数 + 1
        local totalTimes   = #storedIcons
        local surplusTimes = tonumber(bonusExtra.cardCount)
        cardIndex = totalTimes - surplusTimes + 1
    end
    
    -- 最近一张卡片的赢钱
    local lastCardWinCoins = 0

    for _cardIndex,_data in ipairs(storedIcons) do
        if _cardIndex < cardIndex then
            lastCardWinCoins = tonumber(_data[3])
            cardWinCoins     = cardWinCoins + lastCardWinCoins
        else
            break
        end
    end

    local lastWinCoin = 0

    local addValue = _addAllWinCoins and cardWinCoins or lastCardWinCoins
    lastWinCoin = globalData.slotRunData.lastWinCoin + addValue
    self:setLastWinCoin(lastWinCoin)
    
    self:updateBottomUICoins(0, lastCardWinCoins, false, _playWinSound)
end
--BottomUI接口
function CodeGameScreenCashScratchMachine:updateBottomUICoins( _beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound )
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end
-- 
function CodeGameScreenCashScratchMachine:getCashScratchJackpotIndex(_topSymbolType, _cashCount)
    local index = 1
    if nil ~= _topSymbolType then
        local bonusIndex = self:getCashScratchBonusSymbolIndex(_topSymbolType)
        -- 左 -> 右 : 5 -> 1
        index = 5 - bonusIndex + 1
        return index
    end

    if nil ~= _cashCount then
        -- 上 -> 下 : 6 -> 10
        index = 9 - _cashCount + 1 + 5
        return index
    end

    return index
end
-- 传入信号类型获取bonus索引
function CodeGameScreenCashScratchMachine:getCashScratchBonusSymbolIndex(_symbolType)
    local index = 0

    if self.SYMBOL_Bonus_1 <= _symbolType and _symbolType <= self.SYMBOL_Bonus_5 then
        index = 1 + _symbolType - self.SYMBOL_Bonus_1
    end

    return index
end
-- gameBg、reghtScreen 使用
function CodeGameScreenCashScratchMachine:getCashScratchCurModelName(_checkBonus)
    local modelName = "base"

    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}

    if _checkBonus and self:isTriggerBonusFlyCard() then
        modelName = "bonus"
    elseif globalData.slotRunData.freeSpinCount > 0 then
        local curTimes   = selfData.triggerTimes or 0
        local totalTimes = selfData.totalFreespinCount or 10

        modelName = (curTimes > 0 and curTimes == totalTimes) and "superFree" or "free"
    end

    return modelName
end
function CodeGameScreenCashScratchMachine:levelPerformWithDelay(_time, _fun)
    local fun = _fun
    if _time <= 0 then
        fun()
        return
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        fun()

        waitNode:removeFromParent()
    end, _time)

    return waitNode
end

--[[
    cocos弹板添加到spine弹板 并展示
    _params = {
        dialogName = "", 
        ownerlist  = {}, 
        autoType   = 0,   
        func       = function, 

        bindNode   = ""
        skinName   = "",

        -- 非底层 BaseDialog 创建的弹板,需要在外面创建好丢进来
        view       = view,
        secondView = secondView,

        -- 执行一次的按钮点击回调( jackpot跳钱部分需要使用 )
        clickFun   = function,    
        -- 播放over时间线时调用的方法
        btnClickFunc = function,
    }
]]
function CodeGameScreenCashScratchMachine:addCocosViewToSpineTanban(_params)
    self:showSpineTanbanMask()

    self.m_export:getParent():setLocalZOrder(self.ORDER.EXPORT_DOWN)

    --spine做背景 一定要确保逻辑内不会出现两个spine弹板同时出现的情况
    self.m_spineTanban  = util_spineCreate("CashScratch_Tanban",true,true)
    self.m_spineTanbanParent:addChild(self.m_spineTanban, 100)
    self.m_spineTanban:setSkin(_params.skinName)

    -- 1.展示界面 不做逻辑处理
    local view = _params.view
    if not view then
        view = util_createView("Levels.BaseDialog")
        view:initViewData(self, _params.dialogName, nil, _params.autoType)
        view:updateOwnerVar(_params.ownerlist)
    end
    view.m_allowClick = false
    util_spinePushBindNode(self.m_spineTanban, _params.bindNode,view)
    self.m_spineTanban.m_bindView = view

    -- 2.逻辑界面 不展示
    local secondView = self:createSecondCocosView(view, _params)
    self:bindSecondViewBtnState(view, secondView, _params)

    return view
end
--创建第二个cocos界面, 解决cocos按钮挂载在spine上面不生效的问题, 第二界面不做展示 只触发事件
-- _firstView : 解决坐标移动问题
function CodeGameScreenCashScratchMachine:createSecondCocosView(_firstView, _params)
    local view = _params.secondView
    if not view then
        view = util_createView("Levels.BaseDialog")
    end
    self:reSetDialogFun_runCsbAction(view)
    view:initViewData(self, _params.dialogName, nil, _params.autoType)
    
    self.m_spineTanbanParent:addChild(view, 1000)
    -- 等start播放完毕 才能点击
    view.m_allowClick = false
    local startAnimTime = 21/30
    self:levelPerformWithDelay(startAnimTime, function()
        if tolua.isnull(_firstView) or tolua.isnull(view)  then 
            return 
        end
        local nodePos   = util_convertToNodeSpace(_firstView, view:getParent())
        view:setPosition(nodePos)
        -- 这个数值是目测的 每个关卡提供的资源缩放会不一样
        view:setScale(0.85)

        view.m_allowClick = true
    end)
    --修改所有节点展示状态: button 打开可见性，清零 透明度, 只有root一层
    self:setSecondViewNodeShowState(view:findChild("root"))

    -- 遮罩消失时机 弹板播放 over 的第6帧 或 弹板播放 auto 的第70帧
    view:setBtnClickFunc(function()
        if nil == _params.autoType then
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(waitNode,function()
                self:closeSpineTanbanMask()
                waitNode:removeFromParent()
            end, 6/30)
        end

        if _params.clickFun then
            _params.clickFun()
        end
        if _params.btnClickFunc then
            _params.btnClickFunc()
        end
        
    end)
    --等over时间线播放完毕再移除
    view:setOverAniRunFunc(function()
        if _params.func then
            _params.func()
        end
        self:clearSpineTanbanAddView()
    end)

    return view
end

function CodeGameScreenCashScratchMachine:setSecondViewNodeShowState(_node)
    local childList = _node:getChildren()
    for _index,_child in ipairs(childList) do
        if tolua.type(_child) == "ccui.Button" then
            _child:setVisible(true)
            _child:setOpacity(0)
        elseif(tolua.type(_child) == "ccui.Layout")then
            _child:setVisible(true)
            _child:setOpacity(0)
        else
            _child:setVisible(false)
        end
    end
end
function CodeGameScreenCashScratchMachine:reSetDialogFun_runCsbAction(_csbView)
    --重写view的指定方法
    _csbView.runCsbAction = function(_dialog,key, loop, func, fps)
        if nil ~= _dialog then
            --播放csb时间线的 通知播放spine时间线,函数回调放在spine结束回调内。
            util_csbPlayForKey(_dialog.m_csbAct, key, loop, nil, fps)

            util_spinePlay(self.m_spineTanban,key,loop)
            util_spineEndCallFunc(self.m_spineTanban,key,handler(nil,function(  )
                if nil ~= func then
                    func()
                end
            end))

            --处理auto弹板的遮罩隐藏
            if "auto" == key then
                self:levelPerformWithDelay(70/30, function()
                    self:closeSpineTanbanMask()
                end)
            end
            
        end
    end
end

-- 绑定两个界面的按钮状态，逻辑界面的按钮被点击时 展示界面的按钮状态也要发生变化
function CodeGameScreenCashScratchMachine:bindSecondViewBtnState(_view, _secondView, _params)
    -- 触摸开始
    _secondView.clickStartFunc = function(_viewObj,_sender)
        if _secondView.m_allowClick then
            if not tolua.isnull(_view) then
                local btnName = _sender:getName()
                local btnNode = _view:findChild(btnName)
                if btnNode.setEnabled then
                    btnNode:setEnabled(false)
                end
            end
        end
    end

    -- 触摸结束
    _secondView.clickEndFunc = function(_viewObj,_sender)
        if _secondView.m_allowClick then
            if not tolua.isnull(_view) then

                local btnName = _sender:getName()
                local btnNode = _view:findChild(btnName)
                btnNode:setEnabled(true)
                
            end
        end
        
    end
end

function CodeGameScreenCashScratchMachine:clearSpineTanbanAddView()
    --弹板
    if self.m_spineTanban then
        util_spineRemoveBindNode(self.m_spineTanban, self.m_spineTanban.m_bindView)

        -- 移除挂载的spine
        self.m_spineTanban:removeFromParent()
        self.m_spineTanban = nil
    end
    --第二弹板，父类方法会自动移除
end

--[[
    spine弹板遮罩相关
]]
--展示spine弹板遮罩
-- _isInReel : 层级是否在轮盘上
function CodeGameScreenCashScratchMachine:showSpineTanbanMask(_isInReel)
    local mask   = self.m_spineTanban_mask
    local parent = mask:getParent()
    local nextParent = _isInReel and self:findChild("Node_spineTanban") or self.m_spineTanbanParent

    if parent ~= nextParent then
        local order = _isInReel and self.ORDER.SPINE_TANBAN or 0
        local pos = util_convertToNodeSpace(mask, nextParent)
        util_changeNodeParent(nextParent, mask, order)
        mask:setPosition(pos)
    end

    mask:setVisible(true)   
    mask:runCsbAction("start", false)
end
--隐藏spine弹板遮罩
function CodeGameScreenCashScratchMachine:closeSpineTanbanMask(_fun)
    self.m_spineTanban_mask:runCsbAction("over", false, function()
        self.m_spineTanban_mask:setVisible(false) 
        if _fun then
            _fun()
        end
    end)
end


function CodeGameScreenCashScratchMachine:upDateRapidSymbol(_symbolNode)
    if _symbolNode.p_symbolType == self.SYMBOL_RapidWild then
        _symbolNode:setLineAnimName("actionframe3")
        _symbolNode:setIdleAnimName("idleframe2")

        _symbolNode:runIdleAnim()
    end
end

function CodeGameScreenCashScratchMachine:changeBonusEffectOrder()
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local collectLeftCount = globalData.slotRunData.freeSpinCount

    for i,_effectData in ipairs(self.m_gameEffects) do
        -- 单独处理一下 free玩法中同时触发 freeMore和bonus的情况 (freeMore - > bonus)
        if _effectData.p_effectType == GameEffect.EFFECT_BONUS and 
            (collectLeftCount > 0 and collectLeftCount ~= collectTotalCount) then
            _effectData.p_effectOrder = GameEffect.EFFECT_FREE_SPIN + 1
        end
    end
end
--[[
    ----------- 一些重写方法
]]
---
-- 处理spin 返回结果
function CodeGameScreenCashScratchMachine:spinResultCallFun(param)
    CodeGameScreenCashScratchMachine.super.spinResultCallFun(self, param)

    self.m_avgBet = 0
    if param and param[1] then
        local spinData = param[2]
        if spinData.result then
            if spinData.result.freespin then
                if spinData.result.freespin.extra then
                    if spinData.result.freespin.extra.avgBet then
                        self.m_avgBet = spinData.result.freespin.extra.avgBet
                    end
                end
            end
        end
    end
end
function CodeGameScreenCashScratchMachine:BaseMania_updateJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end

    if self.m_bInSuperFreeSpin and self.m_avgBet ~= 0 then
        totalBet = self.m_avgBet
    end

    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools or not jackpotPools[index] then
        local msg = "[CodeGameScreenCashScratchMachine:BaseMania_updateJackpotScore] "
        msg = msg .. " p_id = " .. (globalData.slotRunData.machineData.p_id or "nil")
        msg = msg .. " index = " .. (index or "nil")
        msg = msg .. "\n" .. tostring(debug.traceback())

        if DEBUG == 2 then
            error(msg)
        else
            if util_sendToSplunkMsg then
                util_sendToSplunkMsg("CashScratch_2182_luaError",msg)
            end
        end
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)

    return totalScore
end

function CodeGameScreenCashScratchMachine:checkOnceClipNode()
    CodeGameScreenCashScratchMachine.super.checkOnceClipNode(self)
    -- 创建一个和轮盘区域等大的裁剪区域
    local iColNum = self.m_iReelColumnNum
    local reel = self:findChild("sp_reel_0")
    local startX = reel:getPositionX()
    local startY = reel:getPositionY()
    local reelEnd = self:findChild("sp_reel_" .. (iColNum - 1))
    local endX = reelEnd:getPositionX()
    local endY = reelEnd:getPositionY()
    local reelSize = reelEnd:getContentSize()
    local scaleX = reelEnd:getScaleX()
    local scaleY = reelEnd:getScaleY()
    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY
    endX = endX + reelSize.width - startX 
    endY = endY + reelSize.height - startY
    self.m_onceClipNodeEffect =
        cc.ClippingRectangleNode:create(
        {
            x = startX ,
            y = startY,
            width = endX,
            height = endY
        }
    )
    self.m_clipParent:addChild(self.m_onceClipNodeEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)
    self.m_onceClipNodeEffect:setPosition(0, 0)
end

function CodeGameScreenCashScratchMachine:updateReelGridNode(node)
    -- Rapid 公用spine区分
    self:upDateRapidSymbol(node)

end

function CodeGameScreenCashScratchMachine:playCustomSpecialSymbolDownAct(slotNode)
    -- 落地动画 后期 {时间线， 音效}
    local bulingType = {
        [self.SYMBOL_RapidWild] = {"buling2", "CashScratchSounds/sound_CashScratch_wildRapid_buling.mp3"},
        [self.SYMBOL_RapidHits] = {"buling", "CashScratchSounds/sound_CashScratch_rapid_buling.mp3"}, 

        [self.SYMBOL_Bonus_1] = {"buling", "CashScratchSounds/sound_CashScratch_bonus_buling.mp3"}, 
        [self.SYMBOL_Bonus_2] = {"buling", "CashScratchSounds/sound_CashScratch_bonus_buling.mp3"},
        [self.SYMBOL_Bonus_3] = {"buling", "CashScratchSounds/sound_CashScratch_bonus_buling.mp3"},
        [self.SYMBOL_Bonus_4] = {"buling", "CashScratchSounds/sound_CashScratch_bonus_buling.mp3"},
        [self.SYMBOL_Bonus_5] = {"buling", "CashScratchSounds/sound_CashScratch_bonus_buling.mp3"},
    }
    local bulingInfo = bulingType[slotNode.p_symbolType]
    if nil ~= bulingInfo then
        slotNode:runAnim(bulingInfo[1], false)
        self:playBulingSymbolSounds(slotNode.p_cloumnIndex, bulingInfo[2])
    end
end

function CodeGameScreenCashScratchMachine:setScatterDownScound()
    self.m_scatterBulingSoundArry["auto"] = "CashScratchSounds/sound_CashScratch_scatter_buling.mp3"
    -- for i = 1, 5 do
    --     local soundPath = nil
    --     if i >= 3 then
    --         soundPath = "Sounds/bonus_scatter_3.mp3"
    --     else
    --         soundPath = "Sounds/bonus_scatter_" .. i .. ".mp3"
    --     end
    --     self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    -- end
end


---
-- 显示free spin
function CodeGameScreenCashScratchMachine:showEffect_FreeSpin(effectData)

    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
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

    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()

    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)

    return true
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenCashScratchMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
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
    if winRatio >= self.m_HugeWinLimitRate then
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

-----by he 将除自定义动画之外的动画层级赋值
--
function CodeGameScreenCashScratchMachine:setGameEffectOrder()
    CodeGameScreenCashScratchMachine.super.setGameEffectOrder(self)
    
    self:changeBonusEffectOrder()
end
-- 适当缩小小于 1370 屏幕的适配缩放
function CodeGameScreenCashScratchMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

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
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width < DESIGN_SIZE.width then
            mainScale = mainScale * 0.93
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

-- 显示paytableview 界面
function CodeGameScreenCashScratchMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"
     --!!! ABTest
     if self:checkCashScratchABTest() then
        csbFileName = "PayTableLayer" .. self.m_moduleName .. "_abtest.csb"
    end

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName

   
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    if view then
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

return CodeGameScreenCashScratchMachine