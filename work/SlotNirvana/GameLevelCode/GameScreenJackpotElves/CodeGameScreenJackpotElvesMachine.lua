---
-- island li
-- 2019年1月26日
-- CodeGameScreenJackpotElvesMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "JackpotElvesPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenJackpotElvesMachine = class("CodeGameScreenJackpotElvesMachine", BaseNewReelMachine)

CodeGameScreenJackpotElvesMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_RED_2X = 102  -- wild2X 红色
CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_RED_3X = 103  -- wild3X 红色
CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_RED_4X = 104  -- wild4X 红色
CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_RED_5X = 105  -- wild5X 红色
CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_GREEN_2X = 202  -- wild2X 绿色
CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_GREEN_3X = 203  -- wild3X 绿色
CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_GREEN_4X = 204  -- wild4X 绿色
CodeGameScreenJackpotElvesMachine.SYMBOL_WILD_GREEN_5X = 205  -- wild5X 绿色

CodeGameScreenJackpotElvesMachine.COLLECT_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1 -- 收集wild
CodeGameScreenJackpotElvesMachine.COLORFUL_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2 -- 多福多彩玩法




-- 构造函数
function CodeGameScreenJackpotElvesMachine:ctor()
    CodeGameScreenJackpotElvesMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    self.m_publicConfig = PublicConfig

    self.m_upgrade = {false,false}

    self.m_isTriggerLongRun = false
    self.m_longRunSymbols = {}

    self.m_vecWilds = {}
    self.m_vecWildsNum = 0

    self.isShowWildIdle = false

    self.isSpecialGameOver = false

    self.m_grandLockBet = 0
    self.m_epicLockBet = 0

    self.peopleClick = true

    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

	--init
	self:initGame()
end

function CodeGameScreenJackpotElvesMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("JackpotElvesConfig.csv", "LevelJackpotElvesConfig.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenJackpotElvesMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "JackpotElves"  
end




function CodeGameScreenJackpotElvesMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --jackpotBar
    self.m_jackpotBar = util_createView("CodeJackpotElvesSrc.JackpotElvesJackPotBarView",{machine = self})
    self:findChild("Node_jackpot_base"):addChild(self.m_jackpotBar)

    --收集栏(红)
    self.m_redCollectBar = util_createView("CodeJackpotElvesSrc.JackpotElvesCollectBar",{machine = self,color = "hong"})
    self:findChild("Node_pen_red"):addChild(self.m_redCollectBar)
    
    --人物(红)
    self.m_redElve = util_spineCreate("JackpotElves_juese_hong", true, true)
    self:findChild("Node_role_red"):addChild(self.m_redElve)
    self:playElveIdle(self.m_redElve, true)

    --收集栏(绿)
    self.m_greenCollectBar = util_createView("CodeJackpotElvesSrc.JackpotElvesCollectBar",{machine = self,color = "lv"})
    self:findChild("Node_pen_green"):addChild(self.m_greenCollectBar)
    
    --人物(绿)
    self.m_greenElve = util_spineCreate("JackpotElves_juese_lv", true, true)
    self:findChild("Node_role_green"):addChild(self.m_greenElve)
    self:playElveIdle(self.m_greenElve, true)
    
    --提示文本
    local tip1 = util_createAnimation("JackpotElves_pick_wenben.csb")
    self.m_clipParent:addChild(tip1,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    
    local tip2 = util_createAnimation("JackpotElves_pick_wenben.csb")
    self.m_clipParent:addChild(tip2,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    
    local pos1 = util_convertToNodeSpace(self:findChild("Node_red"),self.m_clipParent)
    local pos2 = util_convertToNodeSpace(self:findChild("Node_green"),self.m_clipParent)
    
    tip1:setPosition(pos1)
    tip2:setPosition(pos2)
    tip1:setVisible(false)
    tip2:setVisible(false)
    self.m_upGradeTips = {tip1,tip2}

    --多福多彩界面
    self.m_colorfulGameView = util_createView("CodeJackpotElvesBonusGame.JackpotElvesColorfulGame",{machine = self})
    self:findChild("root"):addChild(self.m_colorfulGameView)

    self.m_spineGuochang = util_spineCreate("JackpotElves_GC", true, true)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang:setVisible(false)
    
    self.m_spineGuochang2 = util_spineCreate("JackpotElves_GC2", true, true)
    self:addChild(self.m_spineGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_spineGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang2:setVisible(false)
    --遮罩界面
    self.m_markView = util_createAnimation("JackpotElves_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_markView)
    self.m_markView:setVisible(false)

    --预告
    self.m_nodeYugao = util_createAnimation("JackpotElves_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_nodeYugao)
    self.m_nodeYugao:setVisible(false)

    --大赢动画
    self.m_bigWinAnim = util_spineCreate("JackpotElves_DY", true, true)
    self:addChild(self.m_bigWinAnim, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self)
    self.m_bigWinAnim:setPosition(display.cx, pos.y)
    self.m_bigWinAnim:setVisible(false)

    --大赢滚钱
    self.m_bigWinCoins = util_createView("CodeJackpotElvesSrc.JackpotElvesBigWinShowCoinsView")
    self:addChild(self.m_bigWinCoins, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT + 1)
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self)
    self.m_bigWinCoins:setPosition(display.cx, pos.y + 100)
    self.m_bigWinCoins:setVisible(false)

    self:setGameBgStatus("base")

    self:addClick(self:findChild("Panel_hong_dianji"))
    self:addClick(self:findChild("Panel_lv_dianji"))

end

function CodeGameScreenJackpotElvesMachine:enterLevel()
    self.isShowWildIdle = true
    CodeGameScreenJackpotElvesMachine.super.enterLevel(self)
end


--[[
    背景切换
]]
function CodeGameScreenJackpotElvesMachine:setGameBgStatus(gameStatus)
    self.m_gameBg:findChild("JackpotElves_BG_base"):setVisible(gameStatus == "base")   -- base game
    self.m_gameBg:findChild("JackpotElves_BG_dfdc"):setVisible(gameStatus == "bonus")  -- 多福多财
    self.m_gameBg:findChild("JackpotElves_BG_zhuanpan"):setVisible(gameStatus == "wheel") -- 转盘
end
--[[
    小精灵idle
]]
function CodeGameScreenJackpotElvesMachine:playElveIdle(spineElve, isInit)
    local animName = "idleframe"
    if isInit ~= true then
        local randomNum = math.random(2, 5)
        if spineElve == self.m_redElve and randomNum == 2 then
            animName = "idleframe2"
        elseif spineElve == self.m_greenElve and randomNum == 5 then
            randomNum = math.random(4, 5)
            animName = "idleframe"..randomNum
        end
    end

    self:playSpineAnim(spineElve, animName, false, function ()
        self:playElveIdle(spineElve)
    end)
end

--[[
    设置base界面是否显示
]]
function CodeGameScreenJackpotElvesMachine:setBaseUiShow(isShow)
    local node = self:findChild("Node_base")
    
    if isShow then
        node:setVisible(isShow)
        util_playFadeInAction(node, 0.5)
    else
        util_playFadeOutAction(node, 0.5, function()
            node:setVisible(isShow)
        end)
    end
    
    
    self:findChild("Node_jackpot_base"):setVisible(isShow)
end

--[[
    过场动画
]]
function CodeGameScreenJackpotElvesMachine:showGuochang(func, endFunc)
    self.m_spineGuochang:setVisible(true)
    util_spinePlay(self.m_spineGuochang, "guochang")
    util_spineEndCallFunc(self.m_spineGuochang, "guochang", function ()
        if endFunc ~= nil then
            endFunc()
        end
        self.m_spineGuochang:setVisible(false)
    end)
    if func ~= nil then
        self:delayCallBack(35 / 30, function ()
            if func then
                func()
            end
        end)
    end
end

function CodeGameScreenJackpotElvesMachine:showGuochang2(func, endFunc)
    self.m_spineGuochang2:setVisible(true)
    util_spinePlay(self.m_spineGuochang2, "guochang")
    util_spineEndCallFunc(self.m_spineGuochang2, "guochang", function ()
        if endFunc ~= nil then
            endFunc()
        end
        self.m_spineGuochang2:setVisible(false)
    end)
    if func ~= nil then
        self:delayCallBack(1, function ()
            if func then
                func()
            end
        end)
    end
end

function CodeGameScreenJackpotElvesMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_JackpotElves_enter_game)

    end,0.4,self:getModuleName())
end

function CodeGameScreenJackpotElvesMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    -- 创建大转盘
    local params = {
        wheel = self.m_wheelData,
        machine = self
    }
    self.m_wheelView = util_createView("CodeJackpotElvesWheelGame.JackpotElvesWheelView", params)
    self:findChild("root"):addChild(self.m_wheelView)
    self.m_wheelView:setVisible(false)

    CodeGameScreenJackpotElvesMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_iBetLevel = self:updateBetLevel()
    self.m_jackpotBar:initLockUI(self.m_iBetLevel)
    --刷新jackpot升级显示
    -- self:updateUpGradeShow()
    self:updateInUpGradeShow()
end

--[[
    刷新bet等级
]]
function CodeGameScreenJackpotElvesMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 

    for index = #self.m_specialBets,1,-1 do
        if betCoin >= self.m_specialBets[index].p_totalBetValue then
            level = index
            break
        end
    end
    local vecBetData = self:getBetDataLevel(betCoin) or {1, 1}
    self.m_redCollectBar:initBarStatus(vecBetData[1])
    self.m_greenCollectBar:initBarStatus(vecBetData[2])
    
    return level
end
--[[
    获取收集袋子的level
]]
function CodeGameScreenJackpotElvesMachine:getBetDataLevel(betCoin)
    local vecBetData = self.m_vecBetData["0"]["status"]
    local betData = nil
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.betData then
        betData = selfData.betData
        if betData[tostring(toLongNumber(betCoin))] and betData[tostring(toLongNumber(betCoin))]["status"] then
            vecBetData = betData[tostring(toLongNumber(betCoin))]["status"]
        else
            if self.m_vecBetData[tostring(toLongNumber(betCoin))] ~= nil then
                vecBetData = self.m_vecBetData[tostring(toLongNumber(betCoin))]["status"]
            end
        end
    else
        if self.m_vecBetData[tostring(toLongNumber(betCoin))] ~= nil then
            vecBetData = self.m_vecBetData[tostring(toLongNumber(betCoin))]["status"]
        end
    end

    
    
    
    return vecBetData
end
--[[
    解锁动画
]]
function CodeGameScreenJackpotElvesMachine:updateLockStatus()
    
    local betLevel = self:updateBetLevel()
    if self.m_iBetLevel ~= betLevel then
        local distance = betLevel - self.m_iBetLevel
        self.m_jackpotBar:unlockAnim(betLevel, distance)
        self.m_iBetLevel = betLevel
    end
end

function CodeGameScreenJackpotElvesMachine:addObservers()
    CodeGameScreenJackpotElvesMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
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
        
        --["sound_JackpotElves_winline_"..soundIndex] 
        local soundName = PublicConfig.SoundConfig[string.format("sound_JackpotElves_winline_%d", soundIndex)]
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            -- 切换bet解锁进度条
            self:updateLockStatus()
            --刷新升级
            self:changeBetUpdateUpGradeShow()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenJackpotElvesMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenJackpotElvesMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    屏幕抖动
]]
function CodeGameScreenJackpotElvesMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,10 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenJackpotElvesMachine:MachineRule_GetSelfCCBName(symbolType)
    if self:isRedWildSymbol(symbolType) then
        return "Socre_JackpotElves_Wild"
    end

    if self:isGreenWildSymbol(symbolType) then
        return "Socre_JackpotElves_Wild_0"
    end

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_JackpotElves_Bonus"
    end
    
    return nil
end

--[[
    红色wild
]]
function CodeGameScreenJackpotElvesMachine:isRedWildSymbol(symbolType)
    if symbolType == self.SYMBOL_WILD_RED_2X or 
    symbolType == self.SYMBOL_WILD_RED_3X or 
    symbolType == self.SYMBOL_WILD_RED_4X or 
    symbolType == self.SYMBOL_WILD_RED_5X then
        return true
    end

    return false
end

--[[
    绿色wild
]]
function CodeGameScreenJackpotElvesMachine:isGreenWildSymbol(symbolType)
    if symbolType == self.SYMBOL_WILD_GREEN_2X or 
    symbolType == self.SYMBOL_WILD_GREEN_3X or 
    symbolType == self.SYMBOL_WILD_GREEN_4X or 
    symbolType == self.SYMBOL_WILD_GREEN_5X then
        return true
    end

    return false
end

--[[
    判断是否为wild信号
]]
function CodeGameScreenJackpotElvesMachine:isWildSymbol(symbolType)
    if self:isRedWildSymbol(symbolType) then
        return true
    end

    if self:isGreenWildSymbol(symbolType) then
        return true
    end

    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenJackpotElvesMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenJackpotElvesMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

----------- 数据处理相关-------------------------------------------------------------------------
function CodeGameScreenJackpotElvesMachine:initGameStatusData(gameData)
    CodeGameScreenJackpotElvesMachine.super.initGameStatusData(self, gameData)
    self.m_upgrade = gameData.gameConfig.extra.upgrade
    self.m_vecBetData = gameData.gameConfig.extra.betData
    self.m_wheelData = gameData.gameConfig.extra.wheel

    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets or {}
    if nil ~= specialBets[2] then
        self.m_epicLockBet = specialBets[1].p_totalBetValue
    end

    if nil ~= specialBets[1] then
        self.m_grandLockBet = specialBets[2].p_totalBetValue
    end

end

function CodeGameScreenJackpotElvesMachine:checkWinRate(winAmount)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if self.m_runSpinResultData.p_features
    and #self.m_runSpinResultData.p_features > 1 then
        return false
    end
    if selfData and selfData.bonus then
        return false
    end
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winAmount / totalBet
    if winRate > 10 then
        return true
    end
    return false
end

function CodeGameScreenJackpotElvesMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()
    self.m_isPlayYuGao = false
    local randomNum = math.random(1, 100)
    if (self.m_runSpinResultData.p_features
         and #self.m_runSpinResultData.p_features > 1
         and randomNum <= 40 )then
        self.m_isPlayYuGao = true
    end
    if self.IsCollect == false  then
        self.m_isPlayYuGao = true
    end
    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    self:produceSlots()

    self.m_isWaitingNetworkData = false

    --检测是否jackpot升级
    if self:checkIsJackpotUpgrade() then
        self:runJackpotUpGradeAni(function(  )
            
            self:operaNetWorkData()
        end)
    else
        
        if self.m_runSpinResultData.p_features
         and #self.m_runSpinResultData.p_features > 1
         and self.m_isPlayYuGao == true then
            self:advanceNoticeReward(function(  )
            
                self:operaNetWorkData()
            end)
        elseif self:checkWinRate(self.m_runSpinResultData.p_winAmount) then
            self:advanceNoticeReward(function(  )
            
                self:operaNetWorkData()
            end)
        else
            self:operaNetWorkData()
        end
    end
    
    
    
end
--[[
    预告中奖
]]
function CodeGameScreenJackpotElvesMachine:advanceNoticeReward(func)
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_rewYuGao)
    self.m_nodeYugao:setVisible(true)
    self.m_nodeYugao:playAction("yugao", false, function()
        self.m_nodeYugao:setVisible(false)
        if func then
            func()
        end
    end)
    self:advanceNoticeAnim(self.m_redElve, self.m_redElve:getParent())
    self:advanceNoticeAnim(self.m_greenElve, self.m_greenElve:getParent())

end

function CodeGameScreenJackpotElvesMachine:advanceNoticeAnim(spineElve, oldParent)
    local parentNode = self:findChild("root")
    local pos = util_convertToNodeSpace(spineElve, parentNode)
    self:delayCallBack(0.5, function()
        util_changeNodeParent(parentNode, spineElve, 1)
        spineElve:setPosition(pos)
    end)
    self:delayCallBack(86 / 30, function()
        util_changeNodeParent(oldParent, spineElve)
        spineElve:setPosition(0, 0)
    end)
    self:playSpineAnim(spineElve, "actionframe_yugao", false, function()
        self:playElveIdle(spineElve, true)
    end)
end

--[[
    检测jackpot是否升级
]]
function CodeGameScreenJackpotElvesMachine:checkIsJackpotUpgrade()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.bonus then
        if selfData and selfData.old_upgrade then
            for index = 1,#selfData.old_upgrade do
                --jackpot升级判定
                if selfData.old_upgrade[index] and not self.m_upgrade[index] then
                    return true
                end
            end
        end
    else
        if selfData and selfData.upgrade then
            for index = 1,#selfData.upgrade do
                --jackpot升级判定
                if selfData.upgrade[index] and not self.m_upgrade[index] then
                    return true
                end
            end
        end
    end
    
    -- if selfData and selfData.upgrade then
    --     for index = 1,#selfData.upgrade do
    --         --jackpot升级判定
    --         if selfData.upgrade[index] and not self.m_upgrade[index] then
    --             return true
    --         end
    --     end
    -- end

    return false
end

------------------------------------------------------------------------------------

----------------------------- 玩法处理 -----------------------------------
--[[
    jackpot升级动画
]]
function CodeGameScreenJackpotElvesMachine:runJackpotUpGradeAni(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local upgrade = selfData.upgrade
    if selfData and selfData.bonus then
        upgrade = selfData.old_upgrade
    end
    if selfData and upgrade then
        for index = 1,#upgrade do
            --jackpot升级判定
            if upgrade[index] and not self.m_upgrade[index] then
                local betCoin = globalData.slotRunData:getCurTotalBet() or 0
                local vecBetData = self:getBetDataLevel(betCoin) or {1, 1}
                local spineElve = self.m_greenElve
                local collectBar = self.m_greenCollectBar
                local changeTime = 1.5
                if index == 1 then
                    spineElve = self.m_redElve
                    -- collectBar = self.m_redCollectBar
                    changeTime = 17 / 30
                end
                -- self:playSpineAnim(spineElve, "actionframe", false, function()
                local flyTime = 50/30
                local animName = "actionframe5"
                if spineElve == self.m_redElve then
                    -- util_changeNodeParent(self:findChild("Node_role_red"), self.m_redElve)
                    animName = "actionframe3"
                    flyTime = 33/30
                else
                    -- util_changeNodeParent(self:findChild("Node_role_green"), self.m_greenElve)
                end
                spineElve:setPosition(0, 0)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_colorfullUpdate)
                self:playSpineAnim(spineElve, animName, false, function()
                    self:playElveIdle(spineElve, true)
                    
                end)

                self:delayCallBack(flyTime,function ()
                    local startPos = util_convertToNodeSpace(self:findChild("Node_lv"), self:findChild("root"))
                    if spineElve == self.m_redElve then
                        startPos = util_convertToNodeSpace(self:findChild("Node_hong"), self:findChild("root"))
                    end
                    local flyNode = util_createAnimation("JackpotElves_tw_lizi.csb")
                    for id = 1, 3, 1 do
                        local particle = flyNode:findChild("ef_lizi"..id)
                        particle:setPositionType(0)
                        particle:resetSystem()
                    end
                    self:findChild("root"):addChild(flyNode)
                    
                    local endPos = util_convertToNodeSpace(self.m_upGradeTips[index], self:findChild("root"))
                    flyNode:setPosition(startPos)
                    
                    local moveTo = cc.MoveTo:create(0.5, endPos)
                    local callFunc = cc.CallFunc:create(function ()
                        for id = 1, 3, 1 do
                            local particle = flyNode:findChild("ef_lizi"..id)
                            particle:stopSystem()
                        end
                        self:delayCallBack(0.5, function ()
                            flyNode:removeFromParent()
                        end)
                        self.m_upGradeTips[index]:setVisible(true)
                        self.m_upGradeTips[index]:playAction("actionframe", false, function ()
                            
                        end)
                    end)
                    flyNode:runAction(cc.Sequence:create(moveTo, callFunc))
                end)
                -- self:delayCallBack(0.5,function ()
                --     if type(func) == "function" then
                --         func()
                --     end
                -- end)

                    
                -- end)

                -- self:delayCallBack(changeTime, function()
                --     local parentNode = self:findChild("Node_pick_pen")
                --     local pos = util_convertToNodeSpace(spineElve, parentNode)
                --     util_changeNodeParent(parentNode, spineElve, collectBar:getLocalZOrder() - 1)
                --     spineElve:setPosition(pos)
                -- end)
                self.m_upgrade = upgrade
            end
        end
    end
    
    self:delayCallBack(90/30,function ()
        if type(func) == "function" then
            func()
        end
    end)

end

--[[
    刷新jackpot升级UI显示
]]
function CodeGameScreenJackpotElvesMachine:updateUpGradeShow()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.upgrade then
        for index,isUpGrade in pairs(selfData.upgrade) do
            self.m_upGradeTips[index]:setVisible(isUpGrade)
            self.m_upGradeTips[index]:playAction("idle")
        end

        self.m_upgrade = selfData.upgrade
    else
        for index = 1,#self.m_upGradeTips do
            self.m_upGradeTips[index]:setVisible(false)
        end
    end
end

function CodeGameScreenJackpotElvesMachine:updateInUpGradeShow()
    local upgrade = {false,false}
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    if self.m_vecBetData[tostring(toLongNumber(totalBet) )] and self.m_vecBetData[tostring(toLongNumber(totalBet))].upgrade then
        upgrade = self.m_vecBetData[tostring(toLongNumber(totalBet))].upgrade
    end

    for index,isUpGrade in pairs(upgrade) do
        self.m_upGradeTips[index]:setVisible(isUpGrade)
        self.m_upGradeTips[index]:playAction("idle")
    end
    self.m_upgrade = upgrade
end

function CodeGameScreenJackpotElvesMachine:changeBetUpdateUpGradeShow()
    local upgrade = {false,false}
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local betData = nil
    if selfData and selfData.betData then
        betData = selfData.betData
        if betData[tostring(toLongNumber(totalBet))] and betData[tostring(toLongNumber(totalBet))].upgrade then
            upgrade = betData[tostring(toLongNumber(totalBet))].upgrade
        else
            if self.m_vecBetData[tostring(toLongNumber(totalBet))] and self.m_vecBetData[tostring(toLongNumber(totalBet))].upgrade then
                upgrade = self.m_vecBetData[tostring(toLongNumber(totalBet))].upgrade
            end
        end
    else
        if self.m_vecBetData[tostring(toLongNumber(totalBet))] and self.m_vecBetData[tostring(toLongNumber(totalBet))].upgrade then
            upgrade = self.m_vecBetData[tostring(toLongNumber(totalBet))].upgrade
        end
    end

    for index,isUpGrade in pairs(upgrade) do
        self.m_upGradeTips[index]:setVisible(isUpGrade)
    end

    self.m_upgrade = upgrade
end

-- 断线重连 
function CodeGameScreenJackpotElvesMachine:MachineRule_initGame(  )

end

-- function CodeGameScreenJackpotElvesMachine:checkSymbolTypePlayTipAnima(symbolType)
--     return false
-- end

--
--单列滚动停止回调
--
function CodeGameScreenJackpotElvesMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenJackpotElvesMachine.super.slotOneReelDown(self,reelCol) 
    if isTriggerLongRun and self.m_isTriggerLongRun ~= true then
        self.m_isTriggerLongRun = isTriggerLongRun
    end
    for iRow = 1, self.m_iReelRowNum, 1 do
        local symbolNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if symbolNode and self:isWildSymbol(symbolNode.p_symbolType) then
            -- symbolNode:runAnim("buling", false, function()
            --     symbolNode:runAnim("idleframe",true)
            -- end)
            self.m_vecWilds[#self.m_vecWilds + 1] = symbolNode
            
        end
    end

    return isTriggerLongRun
end

--播放提示动画
function CodeGameScreenJackpotElvesMachine:playReelDownTipNode(slotNode)

    self.m_longRunSymbols[#self.m_longRunSymbols + 1] = slotNode
    --修改小块层级
    local scatterOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex
    util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,scatterOrder)
    slotNode:runAnim("buling", false, function()
        if not self.m_isTriggerLongRun then
            slotNode:runAnim("idleframe2",true)
        else
            slotNode:runAnim("idleframe3",true)
        end 
    end)
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenJackpotElvesMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenJackpotElvesMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenJackpotElvesMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("JackpotElvesSounds/music_JackpotElves_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenJackpotElvesMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("JackpotElvesSounds/music_JackpotElves_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenJackpotElvesMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )
   
    self.m_longRunSymbols = {}
    self.m_vecWilds = {}
    self.isSpecialGameOver = false
    self.isShowWildIdle = false
    self.peopleClick = false
    self.m_jackpotBar:isClickShow(false)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenJackpotElvesMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenJackpotElvesMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
--[[
    检测轮盘内是否有wild
]]
function CodeGameScreenJackpotElvesMachine:checkHaveWildSymbol( )
    local reels = self.m_runSpinResultData.p_reels
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1,self.m_iReelColumnNum do
            local symbolType = reels[iRow][iCol]
            if self:isWildSymbol(symbolType) then
                return true
            end
        end
    end

    return false
end
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenJackpotElvesMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --检测是否需要收集wild图标
    if self:checkHaveWildSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_WILD_EFFECT -- 动画类型

        self.m_vecBetData = selfData.betData
    end

    --多福多彩玩法
    
    if selfData and selfData.bonus then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLORFUL_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLORFUL_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenJackpotElvesMachine:MachineRule_playSelfEffect(effectData)

    --收集wild图标
    if effectData.p_selfEffectType == self.COLLECT_WILD_EFFECT then
        self.IsCollect = true
        self:collectWild(function ()
            self.IsCollect = false
            self.peopleClick = true
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    elseif effectData.p_selfEffectType == self.COLORFUL_EFFECT then --多福多彩
        self.isSpecialGameOver = true
        self:showColorFulGameView(function(  )
            self.peopleClick = true
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
	return true
end

--[[
    收集Wild
]]
function CodeGameScreenJackpotElvesMachine:collectWild(func)
    self.peopleClick = false

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local vecBetData = clone(self:getBetDataLevel(betCoin))
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local redFlag = false
    local greenFlag = false
    local parentNode = self:findChild("root")
    self.m_vecWildsNum = self.m_vecWilds
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wildCollectUp)
    for id = 1, #self.m_vecWilds, 1 do
        local wild = self.m_vecWilds[id]
        wild:runAnim("shouji", false, function()
            wild:runAnim("idleframe",true)
        end)
        
        local endPos = util_convertToNodeSpace(self:findChild("Node_pen_red"), parentNode)

        if self:isGreenWildSymbol(wild.p_symbolType) then
            endPos = util_convertToNodeSpace(self:findChild("Node_pen_green"), parentNode)
            greenFlag = true
        else
            redFlag = true
        end
        local startPos = util_convertToNodeSpace(wild, parentNode)

        local flyNode = util_createAnimation("JackpotElves_tw_lizi.csb")
        for id = 1, 3, 1 do
            local particle = flyNode:findChild("ef_lizi"..id)
            particle:setPositionType(0)
            particle:resetSystem()
        end
        parentNode:addChild(flyNode)
        flyNode:setPosition(startPos)

        local moveTo = cc.MoveTo:create(0.5, endPos)
        local callFunc = cc.CallFunc:create(function()
            for id = 1, 3, 1 do
                local particle = flyNode:findChild("ef_lizi"..id)
                particle:stopSystem()
            end
            self:delayCallBack(0.5, function ()
                flyNode:removeFromParent()
            end)
            
        end)
        flyNode:runAction(cc.Sequence:create(moveTo, callFunc))
    end
    self:delayCallBack(0.5,function ()
        -- if id == #self.m_vecWilds then
            if selfData.bonus ~= nil then
                if selfData.wildType == 0 then
                    vecBetData[1] = 3
                elseif selfData.wildType == 1 then
                    vecBetData[2] = 3
                end
                
                if redFlag == true then
                    self.m_redCollectBar:collectAnim(vecBetData[1], function()
                        if selfData.wildType == 0 then
                            self:trrigerColorFulGameAnim(self.m_redElve, self.m_redCollectBar, function ()
                                if func ~= nil then
                                    func()
                                end
                            end)
                        end
                    end)
                    self:playSpineAnim(self.m_redElve, "shouji", false, function()
                        self:playElveIdle(self.m_redElve, true)
                    end)
                end
                if greenFlag == true then
                    self.m_greenCollectBar:collectAnim(vecBetData[2], function()
                        if selfData.wildType == 1 then
                            
                            self:trrigerColorFulGameAnim(self.m_greenElve, self.m_greenCollectBar, function ()
                                if func ~= nil then
                                    func()
                                end
                            end)
                        end
                    end)
                    self:playSpineAnim(self.m_greenElve, "shouji", false, function()
                        self:playElveIdle(self.m_greenElve, true)
                    end)
                end
            else
                if redFlag == true then
                    self.m_redCollectBar:collectAnim(vecBetData[1])
                    self:playSpineAnim(self.m_redElve, "shouji", false, function()
                        self:playElveIdle(self.m_redElve, true)
                    end)
                end
                if greenFlag == true then
                    self.m_greenCollectBar:collectAnim(vecBetData[2])
                    self:playSpineAnim(self.m_greenElve, "shouji", false, function()
                        self:playElveIdle(self.m_greenElve, true)
                    end)
                end
                -- if func ~= nil then
                --     func()
                -- end
            end
        -- end
    end)
    if selfData.bonus == nil then
        if func ~= nil then
            func()
        end
    end
end

--[[
    多福多财触发动画
]]
function CodeGameScreenJackpotElvesMachine:trrigerColorFulGameAnim(spineElven, collectBar, func)
    self.peopleClick = false
    self:clearCurMusicBg()

    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "pickFeature")
    end

    local parentNode = self:findChild("root")
    local pos = util_convertToNodeSpace(spineElven, collectBar)
    util_changeNodeParent(collectBar, spineElven, 0)
    spineElven:setPosition(pos)
    self:playSpineAnim(spineElven, "actionframe", true)
    self:delayCallBack(1.5, function ()
        spineElven:setLocalZOrder(-1)
    end)
    self.m_markView:setVisible(true)
    self.m_markView:playAction("start2")
    -- self:delayCallBack(27/30,function ()
        if spineElven == self.m_redElve then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_triggerRedColorfull)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_triggerLvColorfull)
        end
    -- end)
    collectBar:collectCompleted(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_enterColorfull)
        self:playSpineAnim(spineElven, "actionframe_guochang", false, function ()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_UpTips)
            collectBar:setPosition(cc.p(0, 0))

            if spineElven == self.m_redElve then
                util_changeNodeParent(self:findChild("Node_pen_red"), collectBar)
                util_changeNodeParent(self:findChild("Node_role_red"), self.m_redElve)
            else
                util_changeNodeParent(self:findChild("Node_pen_green"), collectBar)
                util_changeNodeParent(self:findChild("Node_role_green"), self.m_greenElve)
            end
            collectBar:initBarStatus(1)
            spineElven:setPosition(cc.p(0, 0))
            self:playElveIdle(spineElven, true)
            self:updateUpGradeShow()

        end)
        self:playSpineAnim(collectBar.m_spinNode, "actionframe_guochang")
        self:delayCallBack(8/30, function ()
            local pos = util_convertToNodeSpace(collectBar, parentNode)
            util_changeNodeParent(parentNode, collectBar, 2)
            collectBar:setPosition(pos)

            pos = util_convertToNodeSpace(spineElven, parentNode)
            util_changeNodeParent(parentNode, spineElven, 1)
            spineElven:setPosition(pos)
        end)
        
        self:delayCallBack(30/30, function ()
            self:setBaseUiShow(false)
            self:setGameBgStatus("bonus")
            if func then
                func()
            end
        end)
        
        self:delayCallBack(2.2, function()
            self.m_markView:setVisible(false)
        end)
    end)

end

--[[
    显示多福多彩玩法
]]
function CodeGameScreenJackpotElvesMachine:showColorFulGameView(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.bonus then
        if type(func) == "function" then
            func()
        end
        return
    end


    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local bonusData = clone(selfData.bonus) 
    bonusData.wildType = selfData.wildType
    bonusData.upgrade = self.m_upgrade
    self:resetMusicBg(true,PublicConfig.SoundConfig.sound_JackpotElves_colorFullMusic)
    self:setMaxMusicBGVolume()
    self.m_colorfulGameView:showView(bonusData,function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_colorfullToBase)
        self:showGuochang(function()
            util_playFadeOutAction(self.m_colorfulGameView, 0.5, function()
                self.m_colorfulGameView:setVisible(false)
            end)
            self:resetMusicBg()
            self:setBaseUiShow(true)
            self:setGameBgStatus("base")
            if not self:checkHasBigWin() then
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
            end
        end, function()
            if type(func) == "function" then
                globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount
                func()
            end
        end)
    end)
end

function CodeGameScreenJackpotElvesMachine:showEffect_NewWin(effectData, winType)
    CodeGameScreenJackpotElvesMachine.super.showEffect_NewWin(self,effectData, winType)
    self:updateTopCoins()
end

--刷新赢钱
function CodeGameScreenJackpotElvesMachine:updateBottomCoins(winCoin, isUpdateTopUI, isPlayAnim, beiginCoins)
    
    self.m_bottomUI:notifyUpdateWinLabel(winCoin, isUpdateTopUI, isPlayAnim,beiginCoins)
end

function CodeGameScreenJackpotElvesMachine:updateTopCoins()
    
    self.m_bottomUI:notifyTopWinCoin()
end

function CodeGameScreenJackpotElvesMachine:showEffect_Bonus(effectData)
    --防止恢复暂停时多次执行
    if self.m_isPlayBonusEffect then
        return true
    end
    self.peopleClick = false
    self.m_isPlayBonusEffect = true
    CodeGameScreenJackpotElvesMachine.super.showEffect_Bonus(self,effectData)
end

--[[
    bonus玩法(转盘)
]]
function CodeGameScreenJackpotElvesMachine:showBonusGameView(effectData)
    self:clearWinLineEffect()
    self.isSpecialGameOver = true
    self.m_jackpotBar:isClickShow(false)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_triggerWheel)
    -- 触发动画
    for k,symbolNode in pairs(self.m_longRunSymbols) do
        symbolNode:runAnim("actionframe", false, function ()
            symbolNode:runAnim("idleframe2", true)
        end)
    end
    
    -- 创建大转盘
    -- 轮盘网络数据
    local callBack = function (winCoins)
        -- self.bonusWinCoins = winCoins
        self.m_serverWinCoins = self.m_serverWinCoins + winCoins
        globalData.slotRunData.lastWinCoin = self.m_serverWinCoins
        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_BONUS)
        --刷新赢钱
        self:updateBottomCoins(self.m_serverWinCoins, true, true,0)
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
        --     self.m_serverWinCoins, true, true
        -- })
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelToBaseGuoChang)
        self:showGuochang(function()
            self:resetMusicBg()
            util_changeNodeParent(self:findChild("Node_jackpot_base"),self.m_jackpotBar)
            self.m_jackpotBar:setPosition(0,0)
            self.m_wheelView:hideViewAni()
            self:setBaseUiShow(true)
            self:setGameBgStatus("base")
            util_changeNodeParent(self:findChild("Node_role_red"), self.m_redElve)
            util_changeNodeParent(self:findChild("Node_role_green"), self.m_greenElve)
            self.m_redElve:setVisible(true)
            self.m_greenElve:setVisible(true)
            self:playElveIdle(self.m_redElve, true)
            self:playElveIdle(self.m_greenElve, true)
            
        end, function ()
            self.peopleClick = true
            self.m_isPlayBonusEffect = false
            self.m_jackpotBar:isClickShow(true)
            
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end)
        
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local params = {
        bonusData = self.m_runSpinResultData.p_bonusExtra,
        wheel = self.m_wheelData,
        callFunc = callBack
    }
    

    -- 人物过场
    self:delayCallBack(2, function ()
        self.peopleClick = false
        self:playSpineAnim(self.m_redElve, "actionframe2", false)
        self:playSpineAnim(self.m_greenElve, "actionframe2", false, function()
            self:playElveIdle(self.m_redElve, true)
            self:playElveIdle(self.m_greenElve, true)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelGuoChang)
            self:showGuochang2(function()
                self.m_redElve:setVisible(false)
                self.m_greenElve:setVisible(false)
                util_changeNodeParent(self.m_wheelView:findChild("Node_jackpot"),self.m_jackpotBar)
                util_changeNodeParent(self.m_wheelView:findChild("Node_red"), self.m_redElve)
                util_changeNodeParent(self.m_wheelView:findChild("Node_green"), self.m_greenElve)
                self:resetMusicBg(true,PublicConfig.SoundConfig.sound_JackpotElves_wheelMusic)
                self:setMaxMusicBGVolume()
                self:setBaseUiShow(false)
                self:setGameBgStatus("wheel")
                self.m_wheelView:setElves(self.m_redElve, self.m_greenElve)
                self.m_wheelView:showWheelAni(params, function()
                    
                end)
            end)
        end)
    end)
end

function CodeGameScreenJackpotElvesMachine:showJackpotBarAction(jackpotList)
    self.m_jackpotBar:hideJackpotAim(jackpotList)
end

function CodeGameScreenJackpotElvesMachine:showJackpotBarIdle()
    self.m_jackpotBar:showJackpotIdleAim()
end

--[[
    转盘结束赢钱界面
]]
function CodeGameScreenJackpotElvesMachine:showWheelOverView(winCoins,func)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelViewOver)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(winCoins, 50)
    local view = self:showDialog("WheelOver", ownerlist,func)
    view:setBtnClickFunc(function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelViewOverhite)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},715)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local elve_red = util_spineCreate("JackpotElves_juese_hong", true, true)
    view:findChild("juesehong"):addChild(elve_red)
    self:playSpineAnim(elve_red, "start_tanban", false, function ()
        self:playSpineAnim(elve_red, "idle_tanban", true)
    end)

    local elve_green = util_spineCreate("JackpotElves_juese_lv", true, true)
    view:findChild("jueselv"):addChild(elve_green)
    self:playSpineAnim(elve_green, "start_tanban", false, function ()
        self:playSpineAnim(elve_green, "idle_tanban", true)
    end)
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenJackpotElvesMachine:MachineRule_ResetReelRunData()
    CodeGameScreenJackpotElvesMachine.super.MachineRule_ResetReelRunData(self)
    --self.m_reelRunInfo 中存放轮盘滚动信息
    if self.m_isPlayYuGao == true then
        for i = 1, #self.m_reelRunInfo do
            local runInfo = self.m_reelRunInfo[i]
            runInfo:setReelRunLen(runInfo.initInfo.reelRunLen)
            runInfo:setNextReelLongRun(runInfo.initInfo.bReelRun)      
            runInfo:setReelLongRun(true)
        end
    end
end

function CodeGameScreenJackpotElvesMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenJackpotElvesMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenJackpotElvesMachine:slotReelDown( )


    if self.m_isTriggerLongRun then
        for k,symbolNode in pairs(self.m_longRunSymbols) do
            if symbolNode.m_currAnimName == "idleframe3" then
                symbolNode:runAnim("idleframe2",true)
            end
        end
    end
    self.m_isTriggerLongRun = false

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenJackpotElvesMachine.super.slotReelDown(self)
    if (self.m_runSpinResultData.p_features
    and #self.m_runSpinResultData.p_features > 1)then
        self.peopleClick = false
        self.m_jackpotBar:isClickShow(false)
    else
        self.peopleClick = true
        self.m_jackpotBar:isClickShow(true)
    end
    
    
end



function CodeGameScreenJackpotElvesMachine:delaySlotReelDown()
    CodeGameScreenJackpotElvesMachine.super.delaySlotReelDown(self)
    --多福多彩与转盘同时触发时,要先进转盘玩法
    for k,effectData in pairs(self.m_gameEffects) do
        if effectData.p_effectType == GameEffect.EFFECT_BONUS then
            effectData.p_effectOrder = self.COLLECT_WILD_EFFECT - 1
            break
        end
    end
    --重新排序
    self:sortGameEffects()
end


function CodeGameScreenJackpotElvesMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--新滚动使用
function CodeGameScreenJackpotElvesMachine:updateReelGridNode(symbolNode)
    if symbolNode and self:isWildSymbol(symbolNode.p_symbolType) then
        local symbolType = symbolNode.p_symbolType
        local spineNode = symbolNode:getCCBNode().m_spineNode
        
        local numNode = util_createAnimation("Socre_JackpotElves_Wild_Words_0.csb")
        if self:isRedWildSymbol(symbolType) then
            util_spineRemoveSlotBindNode(spineNode, "1_zi")
            util_spinePushBindNode(spineNode, "1_zi", numNode)
        else
            util_spineRemoveSlotBindNode(spineNode, "1_zi")
            util_spinePushBindNode(spineNode, "1_zi", numNode)
        end
        
        local lbl_multi = numNode:findChild("m_lb_num")
        local multiple = symbolType % 10
        lbl_multi:setString("X"..multiple)
        if self.isShowWildIdle == false then
            symbolNode:runAnim("idleframe2",true)
        end
        
    end
end

function CodeGameScreenJackpotElvesMachine:chooseSoundForType(jackpotType)
    if jackpotType == "epic" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotEpic)
    elseif jackpotType == "grand" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotGrand)
    elseif jackpotType == "ultra" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotUltra)
    elseif jackpotType == "mega" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotMega)
    elseif jackpotType == "major" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotMajor)
    elseif jackpotType == "minor" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotMinor)
    elseif jackpotType == "mini" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotMini)
    end
end

--[[
    显示jackpot赢钱界面
]]
function CodeGameScreenJackpotElvesMachine:showJackpotWinView(jackpotType,winCoins,func)
    local view = util_createView("CodeJackpotElvesSrc.JackpotElveJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = winCoins,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })
    self:chooseSoundForType(jackpotType)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenJackpotElvesMachine:showTwoJackpotWinView(jackpotList,func)
    local view = util_createView("CodeJackpotElvesSrc.JackpotElvesTwoJackpotView",{
        jackpotList = jackpotList,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    延迟回调
]]
function CodeGameScreenJackpotElvesMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

--[[
    spine 动画
]]
function CodeGameScreenJackpotElvesMachine:playSpineAnim(spNode, animName, isLoop, func)
    util_spinePlay(spNode, animName, isLoop == true)
    if func ~= nil then
        util_spineEndCallFunc(spNode, animName, function()
            func()
        end)
    end
end

function CodeGameScreenJackpotElvesMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.peopleClick == false then
        return
    end
    if name == "Panel_hong_dianji" then
        self:playSpineAnim(self.m_redElve, "shouji", false, function()
            self:playElveIdle(self.m_redElve, true)
        end)
    elseif name == "Panel_lv_dianji" then
        self:playSpineAnim(self.m_greenElve, "shouji", false, function()
            self:playElveIdle(self.m_greenElve, true)
        end)
    end
end

function CodeGameScreenJackpotElvesMachine:scaleMainLayer()
    CodeGameScreenJackpotElvesMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.68
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 10)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.79 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.88 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.95 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio <= 768/1370 then
    end
    if display.width/display.height >= 1812/2176 then
        local mainScale = 0.58
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

--重写，不添加GameEffect.EFFECT_FIVE_OF_KIND
function CodeGameScreenJackpotElvesMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()

    local isFiveOfKind = self:lineLogicWinLines()

    -- if isFiveOfKind then
    --     self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    -- end

    -- 根据features 添加具体玩法
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenJackpotElvesMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) and self:getCurSymbolIsPlaySound(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                end
            end
        end
    end
end

--所有玩法里，当有多个图标同时落地时，只播一个音效，且优先播放scatter落地
function CodeGameScreenJackpotElvesMachine:getCurSymbolIsPlaySound(_slotNode)
    local curCol = _slotNode.p_cloumnIndex
    if _slotNode then
        if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            return true
        elseif self:isRedWildSymbol(_slotNode.p_symbolType) or self:isGreenWildSymbol(_slotNode.p_symbolType) then
            local bounsList = {}
            for row=1, self.m_iReelRowNum do
                local node = self:getFixSymbol(curCol , row, SYMBOL_NODE_TAG)
                if node then 
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        return false
                    elseif self:isRedWildSymbol(node.p_symbolType) or self:isGreenWildSymbol(node.p_symbolType)  then
                        bounsList[#bounsList + 1] = node
                    end
                end
            end
            if #bounsList > 0 then
                if _slotNode.p_rowIndex == bounsList[1].p_rowIndex then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenJackpotElvesMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if _sFeature ~= "bonus" and _sFeature ~= "pickFeature" then
        return
    end
    if CodeGameScreenJackpotElvesMachine.super.levelDeviceVibrate then
        CodeGameScreenJackpotElvesMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenJackpotElvesMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData and selfData.bonus then
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenJackpotElvesMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenJackpotElvesMachine:showBigWinLight(_func)
    self.m_bigWinAnim:setVisible(true)
    self.m_bigWinCoins:setVisible(true)
    self.m_bigWinCoins:setSpinCoins(self.m_runSpinResultData.p_winAmount)
    self.m_bigWinCoins:updateCoins()
    self:shakeRootNode( )
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_bigWInYuGao)
    self:playSpineAnim(self.m_bigWinAnim, "actionframe", false, function()
        self.m_bigWinCoins:setVisible(false)
        self.m_bigWinAnim:setVisible(false)
    end)

    self:delayCallBack(8 / 3, function ()
        if _func then
            _func()
        end
    end)
end

return CodeGameScreenJackpotElvesMachine






