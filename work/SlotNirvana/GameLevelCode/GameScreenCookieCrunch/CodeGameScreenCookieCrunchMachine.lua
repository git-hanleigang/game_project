--[[
    玩法:
        随机wild:
            滚动或消除下落bonus图标时，
            bonus1会将随机位置和自身变为wild，bonus2会将当前列变为wild
            变换位置覆盖时wild会升级
        消除:
            所有参与连线的小块连线后会被消除，直到没有连线触发。
            触发Free玩法时打断并保存当前盘面，立刻进入free玩法，free结束时会恢复盘面并继续被打断的流程
        
]]
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCookieCrunchMachine = class("CodeGameScreenCookieCrunchMachine", BaseNewReelMachine)
local CookieCrunchRightBar = require "CodeCookieCrunchSrc.CookieCrunchRightBar"

CodeGameScreenCookieCrunchMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- 一些定义信号
CodeGameScreenCookieCrunchMachine.SYMBOL_Bonus_1 = 94
CodeGameScreenCookieCrunchMachine.SYMBOL_Bonus_2 = 95

CodeGameScreenCookieCrunchMachine.SYMBOL_Wild_2x = 101
CodeGameScreenCookieCrunchMachine.SYMBOL_Wild_3x = 102
CodeGameScreenCookieCrunchMachine.SYMBOL_Wild_4x = 103
CodeGameScreenCookieCrunchMachine.SYMBOL_Wild_5x = 104

CodeGameScreenCookieCrunchMachine.SYMBOL_CookieBg = 150
-- 一些自定义事件
    --随机wild
CodeGameScreenCookieCrunchMachine.EFFECT_RandomWild = GameEffect.EFFECT_SELF_EFFECT - 100
    --掉落玩法(随机wild-> 连线 -> 右边栏涨进度 | 消除掉落) 
CodeGameScreenCookieCrunchMachine.EFFECT_Down = GameEffect.EFFECT_SELF_EFFECT - 90

-- 构造函数
function CodeGameScreenCookieCrunchMachine:ctor()
    CodeGameScreenCookieCrunchMachine.super.ctor(self)
    --不展示顶部的下一个小块
    self.m_bCreateResNode = false
    self.m_isFeatureOverBigWinInFree = true

    self.m_spinRestMusicBG = true
    -- base和free的jackpot数值
    self.m_baseJackpot = {0, 0, 0, 0}
    self.m_freeJackpot = {0, 0, 0, 0}
    -- 预告中奖标记
    self.m_isPlayWinningNotice = false
    -- 首次freeSpin标记
    self.m_isPlayFirstFree = false
    -- 是否在free中 用于freeOver弹板前后的两次连线做区分
    self.m_isCookieCrunchFree = false
    --处理bonus相互覆盖的情况 (在列表内的坐标一律不升级，等待自己升级)
    self.m_bonusWildLevel = {}
    --init
    self:initGame()
end

function CodeGameScreenCookieCrunchMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCookieCrunchMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CookieCrunch"  
end




function CodeGameScreenCookieCrunchMachine:initUI()

    --预告中奖
    self.m_yugaoAnim = util_createAnimation("CookieCrunch_Yugao.csb")
    self:findChild("Node_yuGao"):addChild(self.m_yugaoAnim)
    self.m_yugaoAnim:setVisible(false)

    -- freespinBar
    self.m_freeSpinBar = util_createView("CodeCookieCrunchSrc.CookieCrunchFreespinBarView")
    self:findChild("FreeSpinBar"):addChild(self.m_freeSpinBar)
    self.m_freeSpinBar:setVisible(false)

    --free过场
    self.m_freeGuochang = util_createAnimation("CookieCrunch_Free_AddBonus.csb")
    self:findChild("Node_yuGao"):addChild(self.m_freeGuochang)
    self.m_freeGuochang:setVisible(false)
    
    -- 右侧进度条
    self.m_rightBarManager = util_createView("CodeCookieCrunchSrc.CookieCrunchRightBarManager", self, {
        -- 进度栏
        {parent = self:findChild("Node_Loading_1"), jpIndex = 0},
        {parent = self:findChild("Node_Loading_2"), jpIndex = 0},
        {parent = self:findChild("Node_Loading_3"), jpIndex = 0},
        {parent = self:findChild("Node_Loading_4"), jpIndex = 0},
        -- jackpot
        {parent = self:findChild("Node_mini"),  jpIndex = 4},
        {parent = self:findChild("Node_minor"), jpIndex = 3},
        {parent = self:findChild("Node_major"), jpIndex = 2},
        {parent = self:findChild("Node_grand"), jpIndex = 1},
    })
    self:findChild("LoadingBar"):addChild(self.m_rightBarManager)
    self.m_rightBarManager:upDateProgress(0, false)

    --右侧提示栏
    self.m_rightBarTips = util_createView("CodeCookieCrunchSrc.CookieCrunchRightBarTips", self, {
        clickNode = self:findChild("Panel_touch"),
        tipList   = {
            {index = 1, parent = self:findChild("Node_Tips_1")},
            {index = 2, parent = self:findChild("Node_Tips_2")},
            {index = 3, parent = self:findChild("Node_Tips_3")},
        },
    })
    self:findChild("Node_Tip"):addChild(self.m_rightBarTips)
    
    -- 连线框
    self.m_lineFrameManager = util_createView("CodeCookieCrunchSrc.CookieCrunchLineFrameManager", self,{self.m_slotFrameLayer})
    self:addChild(self.m_lineFrameManager)

    -- 掉落的轮盘
    self:findChild("ReelClipLayer"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)

    --背景-旋转饼干
    local bgParent = self:findChild("gameBg")
    self.m_bgSpine = util_spineCreate("CookieCrunch_bg_turn",true,true)
    bgParent:addChild(self.m_bgSpine, GAME_LAYER_ORDER.LAYER_ORDER_BG+1)
    util_spinePlay(self.m_bgSpine, "idleframe", true)

    -- 底栏效果
    local winAnimParent = self.m_bottomUI:findChild("win")
    local winAnimOrder  = -1
    self.m_littleWinAnim = util_createAnimation("CookieCrunch_littlewin.csb")
    winAnimParent:addChild(self.m_littleWinAnim, winAnimOrder)
    self.m_littleWinAnim:setVisible(false)
    self.m_littleWinIndex = 0

    --初始化一些界面展示
    self:changeLevelBgAndReel(CookieCrunchRightBar.MODEL.BASE, false)
end


function CodeGameScreenCookieCrunchMachine:enterGamePlayMusic(  )
    self:playEnterGameSound( "CookieCrunchSounds/music_CookieCrunch_enter.mp3" )
end

function CodeGameScreenCookieCrunchMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_lineFrameManager:upDataPosition()
    local bottomEffectPos = util_convertToNodeSpace(self.m_bottomUI:findChild("WinNode_fly"), self.m_littleWinAnim:getParent())
    self.m_littleWinAnim:setPosition(bottomEffectPos)
    self.m_winTextPos = cc.p(self.m_bottomUI.m_normalWinLabel:getParent():getPosition()) 

    CodeGameScreenCookieCrunchMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_rightBarTips:openTipView()
    
    -- base 刷新右边栏的数值
    if not self.m_bProduceSlots_InFreeSpin then
        self.m_rightBarManager:upDateAllJackpotBarValue(CookieCrunchRightBar.MODEL.BASE, false)
    -- free 不播放过场时 刷新
    else
        local collectLeftCount  = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        if collectLeftCount ~= collectTotalCount then
            self.m_rightBarManager:upDateAllJackpotBarValue(CookieCrunchRightBar.MODEL.FREE, false)
        else
            self.m_rightBarManager:upDateAllJackpotBarValue(CookieCrunchRightBar.MODEL.BASE, false)
        end
    end
end

function CodeGameScreenCookieCrunchMachine:initHasFeature()
    CodeGameScreenCookieCrunchMachine.super.initHasFeature(self)

    --free断线重连重连 重置棋盘
    self:reconnectResetReel()
end

function CodeGameScreenCookieCrunchMachine:addObservers()
    CodeGameScreenCookieCrunchMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        --大赢跳出 不播连线音效
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

        local soundName = string.format("CookieCrunchSounds/music_CookieCrunch_last_win_base_%d.mp3", soundIndex)
        if self.m_isCookieCrunchFree then
            soundName = string.format("CookieCrunchSounds/music_CookieCrunch_last_win_free_%d.mp3", soundIndex)
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
    --bet数值切换
    gLobalNoticManager:addObserver(self,function(self,params)
        self.m_rightBarManager:upDateAllJackpotBarValue(nil, false)
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenCookieCrunchMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCookieCrunchMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCookieCrunchMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_Bonus_1 then
        return "Socre_CookieCrunch_bonus_1"
    elseif symbolType == self.SYMBOL_Bonus_2 then
        return "Socre_CookieCrunch_bonus_2"
    elseif symbolType == self.SYMBOL_Wild_2x then
        return "Socre_CookieCrunch_Wild_0"
    elseif symbolType == self.SYMBOL_Wild_3x then
        return "Socre_CookieCrunch_Wild_1"
    elseif symbolType == self.SYMBOL_Wild_4x then
        return "Socre_CookieCrunch_Wild_2"
    elseif symbolType == self.SYMBOL_Wild_5x then
        return "Socre_CookieCrunch_Wild_3"
    elseif symbolType == self.SYMBOL_CookieBg then
        return "CookieCrunch_Bingganxiaochu"
        
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCookieCrunchMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCookieCrunchMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

-----------------------------主界面上挂载的控件-----------------------------------
--[[
    背景 和 reel 条
]]
function CodeGameScreenCookieCrunchMachine:changeLevelBgAndReel(_sModel, _playAnim)
    local isFree = _sModel == CookieCrunchRightBar.MODEL.FREE
    --reel条
    local reelBg_base = self:findChild("reel_bg_base")
    local reelBg_free = self:findChild("reel_bg_free")
    

    --背景
    if _playAnim then
        local animName = isFree and "base_free" or "free_base"
        local idleName = isFree and "idleframe2" or "idleframe"
        self:runCsbAction(animName, false, function()
            self:runCsbAction(idleName, true)
        end)

        local bgAnimName = isFree and "normal_free" or "free_normal"
        local bgIdleName = isFree and "free" or "normal"
        self.m_gameBg:runCsbAction(bgAnimName, false, function()
            self.m_gameBg:runCsbAction(bgIdleName, true)

            reelBg_base:setVisible(not isFree)
            reelBg_free:setVisible(isFree)
        end)
    else
        reelBg_base:setVisible(not isFree)
        reelBg_free:setVisible(isFree)

        local idleName = isFree and "idleframe2" or "idleframe"
        self:runCsbAction(idleName, true)

        local bgIdleName = isFree and "free" or "normal"
        self.m_gameBg:runCsbAction(bgIdleName, true)
    end
end

--[[
    底栏小赢效果
]]
function CodeGameScreenCookieCrunchMachine:getLittleWinAnimIndex(_winCoins, _clearTimes)
    local animIndex = 0

    if 1 > self.m_littleWinIndex then
        local betCoins   = globalData.slotRunData:getCurTotalBet()
        local multi      = _winCoins / betCoins 
        if multi > 1 then
            animIndex = 1
        end
    elseif 1 == self.m_littleWinIndex and _clearTimes > 1 then
        animIndex = 2
    elseif 2 <= self.m_littleWinIndex then
        animIndex = 3
    end
    
    return animIndex
end
function CodeGameScreenCookieCrunchMachine:playLittleWinAnim(_animIndex)
    self.m_littleWinIndex = _animIndex

    local nodeList = {
        [2] = "level2",
        [3] = "level3",
    }
    for _levelValue,_nodeName in pairs(nodeList) do
        local levelNode = self.m_littleWinAnim:findChild(_nodeName)
        levelNode:setVisible(_animIndex >= _levelValue)
    end
    
    if not self.m_littleWinAnim:isVisible() then
        self.m_littleWinAnim:setVisible(true)
        self.m_littleWinAnim:runCsbAction("start", false, function()
            self.m_littleWinAnim:runCsbAction("idle", true)
        end)
    end
end
function CodeGameScreenCookieCrunchMachine:hideLittleWinAnim()
    if self.m_littleWinAnim:isVisible() then
        self.m_littleWinAnim:runCsbAction("over", false, function()
            self.m_littleWinAnim:setVisible(false)
            self.m_littleWinIndex = 0
        end)
    end
end

----------------------------- 玩法处理 -----------------------------------
function CodeGameScreenCookieCrunchMachine:isTriggerRandomWild(_data)
    if _data.randomWild and #_data.randomWild > 0 then
        return true
    end

    return false
end
function CodeGameScreenCookieCrunchMachine:playEffect_RandomWild(_data, _fun)
    --处理bonus相互覆盖的情况 (在列表内的坐标一律不升级，等待自己升级)
    self.m_bonusWildLevel = {}
    local randomWild = clone(_data.randomWild) or {}
    -- bonus2 全体一起播，bonus1 单独播
    table.sort(randomWild, function(a,b)
        if a and b then
            local fixPos_a      = self:getRowAndColByPos(a[1])
            local bonusSymbol_a = self:getFixSymbol(fixPos_a.iY, fixPos_a.iX)
            local fixPos_b      = self:getRowAndColByPos(b[1])
            local bonusSymbol_b = self:getFixSymbol(fixPos_b.iY, fixPos_b.iX)
            --bonus2 排到前面
            if bonusSymbol_a.p_symbolType ~= bonusSymbol_b.p_symbolType then
                return bonusSymbol_a.p_symbolType == self.SYMBOL_Bonus_2
            end
        end
        return false
    end)

    --是否存在bonus2
    local isBonus2   = false
    if #randomWild > 0 then
        local randomWildData = randomWild[1]
        local fixPos         = self:getRowAndColByPos(randomWildData[1])
        local bonusSymbol    = self:getFixSymbol(fixPos.iY, fixPos.iX)
        isBonus2 = bonusSymbol.p_symbolType == self.SYMBOL_Bonus_2
        self.m_bouns2SoundFlag = true
    end

    self:playRandomWildCreateAnim(
        1, 
        randomWild, 
        isBonus2,
        function()
            self.m_bonusWildLevel = {}
            _fun()
        end
    )
end
function CodeGameScreenCookieCrunchMachine:playRandomWildCreateAnim(_index, _list, _isBonus2, _fun)
    local data = _list[_index]
    -- 存在bonus2时, 结束 和 bonus1播放 都要延时一下
    local delayTime = _isBonus2 and 40/30 or 0
    if not data then
        self:levelPerformWithDelay(delayTime, function()
            _fun()
        end)
        return
    end

    local pos         = data[1]
    local fixPos      = self:getRowAndColByPos(pos)
    local bonusSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
    local bonusType   = bonusSymbol.p_symbolType

    if bonusType == self.SYMBOL_Bonus_1 then
        self:levelPerformWithDelay(delayTime, function()
            self:playRandomWildFlyAnim_bonus1(data, function()
                self:playRandomWildCreateAnim(_index+1, _list, false, _fun)
            end)
        end)
    elseif bonusType == self.SYMBOL_Bonus_2 then
        self:playRandomWildFlyAnim_bonus2(data, _isBonus2, function()
            self:playRandomWildCreateAnim(_index+1, _list, _isBonus2, _fun)
        end)
    --出现两个信号之外的信号，就卡住吧 不做容错了
    end
end

function CodeGameScreenCookieCrunchMachine:playRandomWildFlyAnim_bonus1(_bonusData, _fun)
    local pos         = _bonusData[1]
    local fixPos      = self:getRowAndColByPos(pos)
    local bonusSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)

    
    local startPos = util_convertToNodeSpace(bonusSymbol, self)
    local spriteWidth = 750
    
    local startInterval = 0.3
    local flyInterval = 0.1
    local flyTime     = 27/60
    -- 扩散 actionframe:60/30
    local tempSymbolLayer = self:findChild("Layout_tempSymbol")
    local tempBonusSymbol = self:createnCookieCrunchTempSymbol(self.SYMBOL_Bonus_1)
    tempSymbolLayer:addChild(tempBonusSymbol)
    tempBonusSymbol:setPosition(util_convertToNodeSpace(bonusSymbol, tempSymbolLayer))
    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_Bonus1_actionframe.mp3")
    tempBonusSymbol:runAnim("actionframe", false)
    bonusSymbol:setVisible(false)
    
    local flyCount    = 0
    local bPlayLaunchSound = false
    for i,_wildPos in ipairs(_bonusData[2]) do
        local wildFixPos = self:getRowAndColByPos(_wildPos)
        local wildSymbol = self:getFixSymbol(wildFixPos.iY, wildFixPos.iX)
        if wildSymbol.p_symbolType == self.SYMBOL_Bonus_1 or wildSymbol.p_symbolType == self.SYMBOL_Bonus_2 then
            self:insertBonusWildLevel(_wildPos)
        end
        
        if nil == self.m_bonusWildLevel[_wildPos] then
            
            local curWildLevel = 0
            local levelData  = self:getCookieCrunchWildLevelData(nil, wildSymbol.p_symbolType)
            local nextLevelData = nil
            if nil ~= levelData then
                curWildLevel = levelData[1]
                nextLevelData  = self:getCookieCrunchWildLevelData(curWildLevel+1, nil)
            else
                nextLevelData  = self:getCookieCrunchWildLevelData(1, nil)
            end
            -- wild 出现|升级
            if nil ~= nextLevelData then
                local ccbName = self:getSymbolCCBNameByType(self, nextLevelData[2])
                local endPos   = util_convertToNodeSpace(wildSymbol, self)
                local rotation = util_getAngleByPos(startPos, endPos)
                local distance = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
                local scale = distance / spriteWidth

                self:levelPerformWithDelay(startInterval + flyCount * flyInterval, function()
                    if not bPlayLaunchSound then
                        bPlayLaunchSound = true
                        gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_Bonus1_launch.mp3")
                    end
                    local flyNode = util_createAnimation("CookieCrunch_Tuowei.csb")
                    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
                    flyNode:setScale(self.m_machineRootScale)
                    flyNode:setPosition(startPos)
                    flyNode:setRotation(- rotation)
                    flyNode:setScaleX(scale)
                    flyNode:runCsbAction("actionframe", false, function()
                        flyNode:removeFromParent()
                    end)
                    --第27帧 wild出现 爆点
                    self:levelPerformWithDelay(27/60, function()
                        gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_Bonus1_createWild.mp3")
                        wildSymbol:changeCCBByName(ccbName, nextLevelData[2])
                        wildSymbol:changeSymbolImageByName(ccbName)
                        wildSymbol:runAnim("start", false)
                        --爆点
                        local baodianPos = util_convertToNodeSpace(wildSymbol, self)
                        local isSpecialWild = nextLevelData[1] > 1
                        self:playCreateWildBaodianAnim(baodianPos, isSpecialWild)
                    end)
                    
                end)
                flyCount = flyCount + 1
            end
        end
    end
    --自身变为wild
    local delayTime = startInterval + (#_bonusData[2] - 2) * flyInterval + 52/60
    self:levelPerformWithDelay(delayTime, function()
        local wildLevel  = self.m_bonusWildLevel[_bonusData[1]]
        self.m_bonusWildLevel[_bonusData[1]] = nil
        local levelData  = self:getCookieCrunchWildLevelData(wildLevel, nil)
        local symbolType = levelData[2]
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        

        tempBonusSymbol:runAnim("idleframe2", false, function()
            bonusSymbol:setVisible(true)
            bonusSymbol:changeCCBByName(ccbName, symbolType)
            bonusSymbol:changeSymbolImageByName(ccbName)
            bonusSymbol:runAnim("start", false, function()
                _fun()
            end)
            --爆点
            local baodianPos = util_convertToNodeSpace(bonusSymbol, self)
            local isSpecialWild = levelData[1] > 1
            self:playCreateWildBaodianAnim(baodianPos, isSpecialWild)

            tempBonusSymbol:runAction(cc.RemoveSelf:create())
        end)
    end)
end
function CodeGameScreenCookieCrunchMachine:playRandomWildFlyAnim_bonus2(_bonusData, _isBonus2, _fun)
    local pos         = _bonusData[1]
    local fixPos      = self:getRowAndColByPos(pos)
    local bonusSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
    --排序
    local wildList = clone(_bonusData[2]) 
    table.sort(wildList, function(a, b)
        return a < b
    end)
    local startIndex  = 1
    local maxDistance = self.m_iReelRowNum
    for i,_iPos in ipairs(wildList) do
        if pos == _iPos then
            startIndex = i
            maxDistance = math.max((i-1), (#wildList-i))
            break
        end
    end
    --临时bonus
    local tempSymbolLayer = self:findChild("Layout_tempSymbol")
    local startPos = util_convertToNodeSpace(bonusSymbol, tempSymbolLayer)
    local tempSymbol = self:createnCookieCrunchTempSymbol(self.SYMBOL_Bonus_2)
    tempSymbolLayer:addChild(tempSymbol)
    tempSymbol:setPosition(startPos)
    if self.m_bouns2SoundFlag then
        self.m_bouns2SoundFlag = false
        gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_Bonus2_actionframe.mp3")
    end
    
    tempSymbol:runAnim("actionframe", false, function()
        tempSymbol:runAction(cc.RemoveSelf:create())
    end)
    bonusSymbol:setVisible(false)

    --连续出wild
    local bonus2DelayTime = 0.5
    local intervalTime = 0.1
    for _distance=1,maxDistance do
        local upPos   = wildList[startIndex + _distance]
        local downPos = wildList[startIndex - _distance]
        local upWildSymbol   = nil
        local downWildSymbol = nil
        local upWildNextData   = nil
        local downWildNextData   = nil

        if nil ~= upPos then
            local upFixPos     = self:getRowAndColByPos(upPos)
            upWildSymbol = self:getFixSymbol(upFixPos.iY, upFixPos.iX)

            if upWildSymbol.p_symbolType == self.SYMBOL_Bonus_1 or upWildSymbol.p_symbolType == self.SYMBOL_Bonus_2 then
                self:insertBonusWildLevel(upPos)
            else
                local levelData = self:getCookieCrunchWildLevelData(nil, upWildSymbol.p_symbolType)
                upWildNextData  = nil ~= levelData and self:getCookieCrunchWildLevelData(levelData[1]+1, nil) or self:getCookieCrunchWildLevelData(1, nil)
            end
        end
        if nil ~= downPos then
            local downFixPos     = self:getRowAndColByPos(downPos)
            downWildSymbol = self:getFixSymbol(downFixPos.iY, downFixPos.iX)

            if downWildSymbol.p_symbolType == self.SYMBOL_Bonus_1 or downWildSymbol.p_symbolType == self.SYMBOL_Bonus_2 then
                self:insertBonusWildLevel(downPos)
            else
                local levelData = self:getCookieCrunchWildLevelData(nil, downWildSymbol.p_symbolType)
                downWildNextData  = nil ~= levelData and self:getCookieCrunchWildLevelData(levelData[1]+1, nil) or self:getCookieCrunchWildLevelData(1, nil)
            end
        end

        local delayTime = (_distance) * intervalTime + bonus2DelayTime
        self:levelPerformWithDelay(delayTime, function()
            if nil ~= upWildNextData then
                local ccbName = self:getSymbolCCBNameByType(self, upWildNextData[2])
                upWildSymbol:changeCCBByName(ccbName, upWildNextData[2])
                upWildSymbol:changeSymbolImageByName(ccbName)
                upWildSymbol:runAnim("start", false)
                --爆点
                local baodianPos = util_convertToNodeSpace(upWildSymbol, self)
                local isSpecialWild = upWildNextData[1] > 1
                self:playCreateWildBaodianAnim(baodianPos, isSpecialWild)
            end
            if nil ~= downWildNextData then
                local ccbName = self:getSymbolCCBNameByType(self, downWildNextData[2])
                downWildSymbol:changeCCBByName(ccbName, downWildNextData[2])
                downWildSymbol:changeSymbolImageByName(ccbName)
                downWildSymbol:runAnim("start", false)
                --爆点
                local baodianPos = util_convertToNodeSpace(downWildSymbol, self)
                local isSpecialWild = downWildNextData[1] > 1
                self:playCreateWildBaodianAnim(baodianPos, isSpecialWild)
            end
        end)
    end
    --自身变为wild
    self:insertBonusWildLevel(wildList[startIndex])
    self:levelPerformWithDelay(1/60 + bonus2DelayTime, function()
        local wildLevel  = self.m_bonusWildLevel[_bonusData[1]]
        self.m_bonusWildLevel[_bonusData[1]] = nil
        local levelData  = self:getCookieCrunchWildLevelData(wildLevel, nil)
        local ccbName = self:getSymbolCCBNameByType(self, levelData[2])
    
        bonusSymbol:changeCCBByName(ccbName, levelData[2])
        bonusSymbol:changeSymbolImageByName(ccbName)
        bonusSymbol:runAnim("start", false)
        bonusSymbol:setVisible(true)
        --爆点
        local baodianPos    = util_convertToNodeSpace(bonusSymbol, self)
        local isSpecialWild = wildLevel > 1
        self:playCreateWildBaodianAnim(baodianPos, isSpecialWild)
    end)

    -- 直接下一步
    -- local delayTime = _isBonus2 and 0 or 40/30
    local delayTime = 0
    self:levelPerformWithDelay(delayTime, function()
        _fun()
    end)
end
function CodeGameScreenCookieCrunchMachine:playCreateWildBaodianAnim(_pos, _isSpecialWild)
    local baodianAnim = util_createAnimation("CookieCrunch_Baodian.csb")
    self:addChild(baodianAnim, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+2)
    baodianAnim:setScale(self.m_machineRootScale)
    baodianAnim:setPosition(_pos)
    local animName = _isSpecialWild and "actionframe1" or "actionframe"
    baodianAnim:runCsbAction(animName, false, function()
        baodianAnim:removeFromParent()
    end)
end
function CodeGameScreenCookieCrunchMachine:insertBonusWildLevel(_iPos)
    if nil == self.m_bonusWildLevel[_iPos] then
        self.m_bonusWildLevel[_iPos] = 1
    else
        self.m_bonusWildLevel[_iPos] = self.m_bonusWildLevel[_iPos] + 1
    end
end

function CodeGameScreenCookieCrunchMachine:isTriggerDown()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.down and #selfData.down > 0 then
        return true
    end

    return false
end
function CodeGameScreenCookieCrunchMachine:playEffect_Down(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local down     = selfData.down
    local bFree = self.m_bProduceSlots_InFreeSpin

    --触发free那次的jackpot还拿base奖池
    local downWinCoins = self:getDownListWinCoins(down, bFree)
    local winType      = self:isTriggerCookieCrunchBigWin(downWinCoins)
    local isBigWin  = winType > 1
    local delayTome = isBigWin and 0.5 or 0

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_bottomUI:checkClearWinLabel()
    end
    self:playDownAnim(1, down, bFree, function()
        self:levelPerformWithDelay(delayTome, function()
            _fun()
        end)
    end)
end
function CodeGameScreenCookieCrunchMachine:playDownAnim(_index, _list, _isFree, _fun)
    local data = _list[_index]
    if not data then
        self:playDownEffectOverShowJackpot(_list, _isFree, _fun)
        return
    end

    --连线    
    self:playDownAnim_lines(data, function()
        --右边栏进度 和 消除下落 同时播放
        local animTime = self.m_rightBarManager:upDateProgress(data.clearTimes, true)
        local clearTimesSound = {
            [3] = "CookieCrunchSounds/music_CookieCrunch_clearTimes_3.mp3",
            [4] = "CookieCrunchSounds/music_CookieCrunch_clearTimes_4.mp3",
            [5] = "CookieCrunchSounds/music_CookieCrunch_clearTimes_5.mp3",
            [6] = "CookieCrunchSounds/music_CookieCrunch_clearTimes_6.mp3",
            [7] = "CookieCrunchSounds/music_CookieCrunch_clearTimes_7.mp3",
            [8] = "CookieCrunchSounds/music_CookieCrunch_clearTimes_8.mp3",
        }
        local soundName = data.clearTimes >= 8 and clearTimesSound[8] or clearTimesSound[data.clearTimes]
        if nil ~= soundName then
            gLobalSoundManager:playSound(soundName)
        end

        -- self:levelPerformWithDelay(animTime, function()
            --消除下落
            self:playDownAnim_drop(data.lines, data.downReel, function()
                --随机wild
                self:playEffect_RandomWild(data, function()
                    self:playDownAnim(_index+1, _list, _isFree, _fun)
                end)
            end)
        -- end)
    end)
end
--消除前的连线
function CodeGameScreenCookieCrunchMachine:playDownAnim_lines(_downData, _fun)
    local _lines = _downData.lines
    local winCoins = 0 
    local linePos  = {}
    for _lineIndex,_lineData in ipairs(_lines) do
        winCoins = winCoins + _lineData.amount
        for i,_iPos in ipairs(_lineData.icons) do
            linePos[_iPos] = true
        end
    end
    -- 跳钱
    local bottomWinCoin = self:getnCookieCrunchCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + winCoins)
    self:updateBottomUICoins(0, winCoins, nil, true)
    local littleWinAnimIndex = self:getLittleWinAnimIndex(bottomWinCoin + winCoins, _downData.clearTimes)
    if littleWinAnimIndex > 0 then
        self:playLittleWinAnim(littleWinAnimIndex)
    end
    --修改底栏字体颜色 并 弹跳
    self:updateBottomWinCoinLabFont(1, littleWinAnimIndex)
    
    -- 连线
    for _iPos,v in pairs(linePos) do
        local fixPos = self:getRowAndColByPos(_iPos)
        local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
        symbol:runLineAnim()
        self.m_lineFrameManager:runLineFrame(fixPos.iY, fixPos.iX)
    end
    -- 第36帧开始消除
    self:levelPerformWithDelay(35/30, function()
        self.m_lineFrameManager:stopAllLineFrame()
        _fun()
    end)
end
--消除前的连线
function CodeGameScreenCookieCrunchMachine:playDownAnim_drop(_lines, _downReel, _fun)
    -- 连线位置 和 下落列表
    local linePos  = {}
    --[[
        [列] = {
            [行1] = 需要下落的格数,
            [行2] = 需要下落的格数,
            [行3] = 需要下落的格数,
        }
    ]]
    local downList = {}
    local baseCol  = {}
    for iRow=1,self.m_iReelRowNum*2 do
        baseCol[iRow] = 0
    end
    for _lineIndex,_lineData in ipairs(_lines) do
        for i,_iPos in ipairs(_lineData.icons) do
            linePos[_iPos] = _iPos            
        end
    end
    for _iPos,v in pairs(linePos) do
        local fixPos = self:getRowAndColByPos(_iPos)
        local iCol   = fixPos.iY
        -- 初始化一下 列的掉落数据
        if nil == downList[iCol] then
            downList[iCol] = clone(baseCol)
        end
        -- 移除本列消除的行
        downList[iCol][fixPos.iX] = nil
        -- 将本行上面的行需要掉落的数量 +1
        for iRow=fixPos.iX,self.m_iReelRowNum*2 do
            if iRow ~= fixPos.iX then
                if downList[iCol][iRow] then
                    downList[iCol][iRow] = downList[iCol][iRow] + 1
                end
            end
        end
    end
    -- 移除不需要移动的小块 和 多余小块
    for _iCol,_colData in pairs(downList) do
        for _iRow,_moveNum in pairs(_colData) do
            if _moveNum <= 0 or (_iRow-_moveNum) > self.m_iReelRowNum then
                _colData[_iRow] = nil
            end
        end
        if not next(_colData) then
            downList[_iCol] = nil
        end
    end
    local clipLayer = self:findChild("ReelClipLayer")
    local tempSymbolLayer = self:findChild("Layout_tempSymbol")
    -- 上层图标切掉 下层饼干碎掉
    local specialDisappear = {
        [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = "idleframe2",
    }
    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_symbolDisappear.mp3")
    local disappearTime = 18/60--30/60--42/60
    for _iPos,v in pairs(linePos) do
        local fixPos = self:getRowAndColByPos(_iPos)
        local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
        symbol:setVisible(false)

        local tempSymbolType     = self.SYMBOL_CookieBg
        local tempSymbolAnimName = "actionframe"
        -- 一些特殊图标有消除动画 不需要饼干碎
        if nil ~= specialDisappear[symbol.p_symbolType] then
            tempSymbolType     = symbol.p_symbolType
            tempSymbolAnimName = specialDisappear[symbol.p_symbolType]
        end
        local tempSymbol = self:createnCookieCrunchTempSymbol(tempSymbolType)
        tempSymbolLayer:addChild(tempSymbol, REEL_SYMBOL_ORDER.REEL_ORDER_3)
        tempSymbol:setPosition(util_convertToNodeSpace(symbol, clipLayer))
        tempSymbol:runAnim(tempSymbolAnimName,false,function()
            tempSymbol:removeTempSlotsNode()
        end)
    end

    --下落时间
    local moveTime  = 6/30          
    --回弹时间
    local resTime   = 3/30 * 2     
    --回弹距离   
    local resDistance = 3         
    --信号落地动画时间
    local bulingAnimTime    = 21/30 
    local bHaveBulingSymbol = false
    -- 掉落
    self:levelPerformWithDelay(disappearTime, function()
        local bulingSoundList = {}

        -- 下落
        local bPlayBulingSound = false
        for _iCol,_colData in pairs(downList) do
            for _iRow,_moveNum in pairs(_colData) do
                -- 修改移动两端图标的可见性 和 初始坐标
                local slotsNodeWorldPos =  self:getSlotsNodeWorldPos(_iCol, _iRow)
                local startPos = cc.p(clipLayer:convertToNodeSpace(slotsNodeWorldPos))
                local endRow = _iRow - _moveNum
                local endLine = self.m_iReelRowNum - endRow + 1
                local endSymbolType = _downReel[_iCol][endLine]
                local endSlotsNode = self:getFixSymbol(_iCol, endRow)
                if _iRow <= self.m_iReelRowNum then
                    local startSymbol = self:getFixSymbol(_iCol, _iRow)
                    startSymbol:setVisible(false)
                end
                --修改信号 层级
                local ccbName = self:getSymbolCCBNameByType(self, endSymbolType)
                endSlotsNode:changeCCBByName(ccbName, endSymbolType)
                endSlotsNode:changeSymbolImageByName(ccbName)
                endSlotsNode.p_showOrder = self:getBounsScatterDataZorder(endSymbolType)
                endSlotsNode:setLocalZOrder(endSlotsNode.p_showOrder)
                local curWorldPos = endSlotsNode:getParent():convertToWorldSpace(cc.p(endSlotsNode:getPosition()))
                self:changeBaseParent(endSlotsNode)
                endSlotsNode:setPosition(endSlotsNode:getParent():convertToNodeSpace(curWorldPos))
                endSlotsNode:runAnim("idleframe", false)
                --算移动距离
                local moveDistance = _moveNum * self.m_SlotNodeH
                --创建需要掉落的临时小块
                local downSymbol = self:createnCookieCrunchTempSymbol(endSymbolType)
                clipLayer:addChild(downSymbol)
                local order = endSlotsNode.p_showOrder + _iCol * 100 - endRow * 10
                downSymbol:setLocalZOrder(endSlotsNode.p_showOrder)
                downSymbol:setPosition(startPos)
                downSymbol:runAnim("idleframe", false)
                local actList = {}
                --下落
                table.insert(actList, cc.MoveBy:create(moveTime*0.2, cc.p(0, -moveDistance*0.15)))
                table.insert(actList, cc.MoveBy:create(moveTime*0.2, cc.p(0, -moveDistance*0.2)))
                table.insert(actList, cc.MoveBy:create(moveTime*0.2, cc.p(0, -moveDistance*0.3)))
                table.insert(actList, cc.MoveBy:create(moveTime*0.2, cc.p(0, -moveDistance*0.2)))
                table.insert(actList, cc.MoveBy:create(moveTime*0.2, cc.p(0, -moveDistance*0.15)))
                -- 上方区域的特殊图标落地
                local bulingDelayTime = 0
                if _iRow > self.m_iReelRowNum then
                    local downSymbolBuling = {
                        [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = {"buling", 21/30, "CookieCrunchSounds/sound_CookieCrunch_Scatter_buling.mp3"},
                        [self.SYMBOL_Bonus_1] = {"buling", 15/30, "CookieCrunchSounds/sound_CookieCrunch_Bonus_buling.mp3"},
                        [self.SYMBOL_Bonus_2] = {"buling", 15/30, "CookieCrunchSounds/sound_CookieCrunch_Bonus_buling.mp3"},
                    }

                    if  nil ~= downSymbolBuling[endSymbolType] then
                        bHaveBulingSymbol = true
                        bulingDelayTime = math.max(0, bulingAnimTime - resTime) 
                        local animName = downSymbolBuling[endSymbolType][1]
                        local animTime = downSymbolBuling[endSymbolType][2]
                        local animSound = downSymbolBuling[endSymbolType][3]
                        table.insert(actList, cc.CallFunc:create(function()
                            util_setSymbolToClipReel(self, endSlotsNode.p_cloumnIndex, endSlotsNode.p_rowIndex, endSlotsNode.p_symbolType, REEL_SYMBOL_ORDER.REEL_ORDER_2_2)
                            local downSymbol_pos = util_convertToNodeSpace(downSymbol, tempSymbolLayer)
                            util_changeNodeParent(tempSymbolLayer, downSymbol, endSlotsNode.p_showOrder)
                            downSymbol:setPosition(downSymbol_pos)
                            downSymbol:runAnim(animName, false)

                            --播放特殊图标的落地音效
                            local bPlaySpecialBulingSound = true
                            for i,v in ipairs(bulingSoundList) do
                                if v == animSound then
                                    bPlaySpecialBulingSound = false
                                    break
                                end
                            end
                            if bPlaySpecialBulingSound then
                                table.insert(bulingSoundList, animSound)
                                gLobalSoundManager:playSound(animSound)
                            end
                            
                            
                        end))
                    end
                end
                --落地音效
                table.insert(actList, cc.CallFunc:create(function()
                    if not bPlayBulingSound then
                        bPlayBulingSound = true
                        gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_symbolBuling.mp3")
                    end 
                end))
                --向上回弹
                table.insert(actList, cc.MoveBy:create(resTime/2*0.25, cc.p(0, resDistance*0.2)))
                table.insert(actList, cc.MoveBy:create(resTime/2*0.5,  cc.p(0, resDistance*0.6)))
                table.insert(actList, cc.MoveBy:create(resTime/2*0.25, cc.p(0, resDistance*0.2)))
                table.insert(actList, cc.MoveBy:create(resTime/2, cc.p(0, -resDistance)))
                if bulingDelayTime > 0 then
                    table.insert(actList, cc.DelayTime:create(bulingDelayTime))
                end
                table.insert(actList, cc.CallFunc:create(function()
                    endSlotsNode:setVisible(true)
                end))
                table.insert(actList, cc.RemoveSelf:create())
                downSymbol:runAction(cc.Sequence:create(actList))
            end
        end

        -- 下一步流程
        local downTime  = moveTime + resTime + 0.1
        if bHaveBulingSymbol then
            downTime = downTime + bulingAnimTime
        end
        self:levelPerformWithDelay(downTime, function()
            _fun()
        end)
    end)
    
    
end

function CodeGameScreenCookieCrunchMachine:playDownEffectOverShowJackpot(_list, _isFree, _fun)
    -- 本次消除由freeMore打断
    if self.m_isFreeMoreDown then
        --移除大赢
        local bigWinEffectType = {
            GameEffect.EFFECT_BIGWIN,
            GameEffect.EFFECT_MEGAWIN,
            GameEffect.EFFECT_EPICWIN
        }
        for i,_effectType in ipairs(bigWinEffectType) do
            if self:checkHasGameEffectType(_effectType) == true then 
                self:removeGameEffectType(_effectType)
                break
            end
        end
        _fun()
    -- 本次消除由free打断
    elseif self.m_isFreeTriggerDown then
        -- 右边栏清空
        self.m_rightBarManager:playDownOverAnim(0, self.m_isFreeTriggerDown, function()
            self:hideLittleWinAnim()
            self:updateBottomWinCoinLabFont(0, 0)
            _fun()
        end)
    -- 其他消除模式
    else
        local down     = _list
        local times    = down[#down].clearTimes
        local isFree   = _isFree
        local jpIndex  = self.m_rightBarManager:getJackpotIndexByTimes(times)

        -- 右边栏清空
        self.m_rightBarManager:playDownOverAnim(times, false, function()
            if jpIndex > 0 then
                local winCoins = self:getCookieCrunchJackpotValue(isFree, jpIndex)
                -- 跳钱
                local bottomWinCoin = self:getnCookieCrunchCurBottomWinCoins()
                self:setLastWinCoin(bottomWinCoin + winCoins)
                self:updateBottomUICoins(0, winCoins)
                --弹板
                self:showJackpotView(winCoins, jpIndex, function()
                    self.m_rightBarManager:clearProgress()
                    if not self.m_bProduceSlots_InFreeSpin then
                        globalData.coinsSoundType = -1
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                    end
                    
                    self:hideLittleWinAnim()
                    self:updateBottomWinCoinLabFont(0, 0)
                    -- 消除结束后如果当前在free模式则需要将，最终赢钱重置为fsWinCoin,否则free最后一次spin时 消除赢钱会讲最终赢钱变小
                    if self.m_bProduceSlots_InFreeSpin then
                        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
                    end
                    _fun()
                end) 
            else
            end
        end)
        
        if jpIndex > 0 then
        else
            if not self.m_bProduceSlots_InFreeSpin then
                globalData.coinsSoundType = -1
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            end
            self:hideLittleWinAnim()
            self:updateBottomWinCoinLabFont(0, 0)
            -- 消除结束后如果当前在free模式则需要将，最终赢钱重置为fsWinCoin,否则free最后一次spin时 消除赢钱会讲最终赢钱变小
            if self.m_bProduceSlots_InFreeSpin then
                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            end
            _fun()
        end
    end
    
end

function CodeGameScreenCookieCrunchMachine:playFreeMoreDownAnim(_fun)
    local freeExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeMore  = freeExtra.freeMore
    if not freeMore then
        _fun()
        return
    end

   --随机wild
   self:playEffect_RandomWild(freeMore, function()
       --继续消除
       local down     = freeMore.down
       self:playDownAnim(1, down, true, _fun)
   end)
end
function CodeGameScreenCookieCrunchMachine:addFreeMoreOverBigWinGameEffect()
    local freeExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeMore  = freeExtra.freeMore
    if not freeMore then
        return
    end
    -- 弹板前后的两次消除列表都要计算
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local down     = selfData.down or {}

    local winCoins_1 = #down > 0 and self:getDownListWinCoins(down, true) or 0
    local winCoins_2 = self:getDownListWinCoins(freeMore.down, true)

    local winCoins = winCoins_1 + winCoins_2
    -- 添加大赢事件 大 -> 小
    local bigWinGameEffect = {
        [GameEffect.EFFECT_EPICWIN] = self.m_HugeWinLimitRate,
        [GameEffect.EFFECT_MEGAWIN] = self.m_MegaWinLimitRate,
        [GameEffect.EFFECT_BIGWIN] = self.m_BigWinLimitRate,   
    }
    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local curRate     = winCoins / curTotalBet
    for _effectType,_limitRate in pairs(bigWinGameEffect) do
        if curRate >= _limitRate then
            self.m_llBigOrMegaNum = winCoins

            local effectData = GameEffectData.new()
            effectData.p_effectType = _effectType
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData
            break
        end
    end
end
--[[
    断线重连 | 进入关卡
]]
function CodeGameScreenCookieCrunchMachine:initGameStatusData(gameData)
    CodeGameScreenCookieCrunchMachine.super.initGameStatusData(self,gameData)

    if gameData.gameConfig.extra ~= nil then
        self.m_baseJackpot = {}
        self.m_freeJackpot = {}
        for i,_jackpotMulti in ipairs(gameData.gameConfig.extra.baseJackpot) do
            table.insert(self.m_baseJackpot, 1, _jackpotMulti)
        end
        for i,_jackpotMulti in ipairs(gameData.gameConfig.extra.freeJackpot) do
            table.insert(self.m_freeJackpot, 1, _jackpotMulti)
        end
    end
    print("[CodeGameScreenCookieCrunchMachine:initGameStatusData]")
end

 
function CodeGameScreenCookieCrunchMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin then
        local collectLeftCount  = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        -- 切换一下free的展示
        if collectLeftCount ~= collectTotalCount then
            self.m_isCookieCrunchFree = true
            self:changeLevelBgAndReel(CookieCrunchRightBar.MODEL.FREE, false)
            self.m_rightBarManager:upDateModel(CookieCrunchRightBar.MODEL.FREE, false) 
            self.m_freeSpinBar:changeFreeSpinByCount()
            self.m_freeSpinBar:showBar()

            --处理下freeMore
            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        end
    end
    
end

function CodeGameScreenCookieCrunchMachine:reconnectResetReel()
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local finalReel = selfData.finalReel
    if not finalReel then 
        return
    end
    -- freeMore 重连时 不直接恢复为最终轮盘
    -- local freeExtra = self.m_runSpinResultData.p_fsExtraData or {}
    -- local freeMore  = freeExtra.freeMore
    -- if nil ~= freeMore then
    --     return
    -- end

    --恢复轮盘
    for _line,_lineData in ipairs(finalReel) do
        local iRow = self.m_iReelRowNum - _line + 1
        for _iCol,_symbolType in ipairs(_lineData) do
            local slotsNode = self:getFixSymbol(_iCol, iRow)
            local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
            slotsNode:changeCCBByName(ccbName, _symbolType)
            slotsNode:changeSymbolImageByName(ccbName)
            slotsNode.p_showOrder = self:getBounsScatterDataZorder(_symbolType)
            slotsNode:setLocalZOrder(slotsNode.p_showOrder)
            slotsNode:runAnim("idleframe", false)
        end
    end
    --wild等级
    local wildAll = selfData.randomWildAll or {}
    for i,_wildData in ipairs(wildAll) do
        local iPos = _wildData[1]
        local wildLevel = _wildData[2]
        local levelData = self:getCookieCrunchWildLevelData(wildLevel, nil)
        local wildSymbolType = levelData[2]
        --
        local fixPos    = self:getRowAndColByPos(iPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX)
        local ccbName = self:getSymbolCCBNameByType(self, wildSymbolType)
        slotsNode:changeCCBByName(ccbName, wildSymbolType)
        slotsNode:changeSymbolImageByName(ccbName)
        slotsNode.p_showOrder = self:getBounsScatterDataZorder(wildSymbolType)
        slotsNode:setLocalZOrder(slotsNode.p_showOrder)
        slotsNode:runAnim("idleframe", false)
    end
end
--
--单列滚动停止回调
--
function CodeGameScreenCookieCrunchMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCookieCrunchMachine.super.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCookieCrunchMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCookieCrunchMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenCookieCrunchMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_freeMore_start.mp3")
            self:showFreeSpinMore( 
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    --freeMore触发的消除标记
                    self.m_isFreeMoreDown = false
                    self:playFreeMoreDownAnim(function()
                        self:addFreeMoreOverBigWinGameEffect()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                    
                end,
                true
            )
        else
            gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_freeStart_start.mp3")
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self.m_isCookieCrunchFree = true
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
                
                self.m_freeSpinBar:changeFreeSpinByCount()
                self.m_freeSpinBar:showBar()

                gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_freeGuoChang.mp3")
                self.m_freeGuochang:setVisible(true)
                self.m_freeGuochang:runCsbAction("actionframe", false, function()
                    self.m_freeGuochang:setVisible(false)

                    self:changeLevelBgAndReel(CookieCrunchRightBar.MODEL.FREE, true)
                    self.m_rightBarManager:upDateModel(CookieCrunchRightBar.MODEL.FREE, true)   
                    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_rightJackpot_enterFree.mp3")
                    self.m_rightBarManager:upDateAllJackpotBarValue(CookieCrunchRightBar.MODEL.FREE, true)
                end)   
            end)

            local startTime = 70/60
            self:levelPerformWithDelay(startTime, function()
                self:freeStartChangeReel()
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenCookieCrunchMachine:showFreeSpinOverView()
   gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_freeOver_start.mp3")

    local allWinCoins      = self.m_runSpinResultData.p_fsWinCoins
    local freeOverWinCoins = self:getFreeOverWinCoins()
    local freeWinCoins     = allWinCoins - freeOverWinCoins
    local freeCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local view = self:showFreeSpinOver( 
        freeWinCoins, 
        freeCount,
        function()
            self:changeLevelBgAndReel(CookieCrunchRightBar.MODEL.BASE, true)
            self.m_rightBarManager:upDateModel(CookieCrunchRightBar.MODEL.BASE, false)    
            self.m_rightBarManager:upDateAllJackpotBarValue(CookieCrunchRightBar.MODEL.BASE, false) 
            self.m_freeSpinBar:hideBar()
            --恢复baseReel
            self:freeOverChangeReel(function()
                self:triggerFreeSpinOverCallFun()
            end)

            
        end
    )
end

-- 重写一下freeStart界面
function CodeGameScreenCookieCrunchMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local isAuto = isAuto
    if nil == isAuto then
        isAuto = self:getCurrSpinMode() == AUTO_SPIN_MODE
    end
    
    local view = util_createView("CodeCookieCrunchSrc.CookieCrunchFreespinStartView")
    gLobalViewManager:showUI(view)
    view:initViewData(ownerlist, func, isAuto)

    return view
end
-- 重写一下freeOver界面
function CodeGameScreenCookieCrunchMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()

    local csbName = "FreeSpinOver_NoWins"
    local ownerlist = {}
    if coins > 0 then
        csbName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    end

    local view = self:showDialog(csbName, ownerlist, func)

    local lb_coins = view:findChild("m_lb_coins")
    if lb_coins then
        view:updateLabelSize({label=lb_coins,sx=1,sy=1},701)
    end 
    
    local lb_num = view:findChild("m_lb_num")
    if lb_num then
        if num < 100 then
            self:updateLabelSize({label=lb_num,sx=1,sy=1}, 71)
        else
            self:updateLabelSize({label=lb_num,sx=0.76,sy=0.76}, 109)
        end
    end
end

function CodeGameScreenCookieCrunchMachine:freeStartChangeReel()
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            --不要bonus图标
            local randomType = self:getNormalSymbol(iCol) 
            while randomType == self.SYMBOL_Bonus_1 or randomType == self.SYMBOL_Bonus_2 do
                randomType = self:getNormalSymbol(iCol) 
            end
        
            local slotsNode  = self:getFixSymbol(iCol, iRow)
            local ccbName = self:getSymbolCCBNameByType(self, randomType)
            slotsNode:changeCCBByName(ccbName, randomType)
            slotsNode:changeSymbolImageByName(ccbName)
            slotsNode:runAnim("idleframe", false)
        end
    end
end
function CodeGameScreenCookieCrunchMachine:freeOverChangeReel(_fun)
    self.m_isCookieCrunchFree = false

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeOverData = selfData.freeOver
    if not freeOverData then
        print("[CodeGameScreenCookieCrunchMachine:freeOverChangeReel] error freeOverData is nil")
        release_print("[CodeGameScreenCookieCrunchMachine:freeOverChangeReel] error freeOverData is nil")
        dump(selfData, "selfData:")
        _fun()
        return
    end

    local actList = {}
    local fadeTime = 0.2
    table.insert(actList, cc.FadeOut:create(fadeTime))
    table.insert(actList, cc.RemoveSelf:create())
    local actSeq = cc.Sequence:create(actList)
    --恢复轮盘
    for _iCol,_colData in ipairs(freeOverData.reels) do
        for _line,_symbolType in ipairs(_colData) do
            local iRow = self.m_iReelRowNum - _line + 1
            local slotsNode = self:getFixSymbol(_iCol, iRow)
            local curSymbolType = slotsNode.p_symbolType
            -- 底层信号
            local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
            slotsNode:changeCCBByName(ccbName, _symbolType)
            slotsNode:changeSymbolImageByName(ccbName)
            slotsNode:runAnim("idleframe", false)
            slotsNode:setVisible(false)
            -- 修改层级
            local curWorldPos = slotsNode:getParent():convertToWorldSpace(cc.p(slotsNode:getPosition()))
            self:changeBaseParent(slotsNode)
            slotsNode:setPosition(slotsNode:getParent():convertToNodeSpace(curWorldPos))
            if self.m_configData:checkSpecialSymbol(_symbolType) then
                slotsNode = util_setSymbolToClipReel(self, slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, slotsNode.p_symbolType, 0)
            end
            --创建上层临时信号
            local tempSymbolLayer = self:findChild("Layout_tempSymbol")
            local tempSymbol = self:createnCookieCrunchTempSymbol(curSymbolType)
            tempSymbolLayer:addChild(tempSymbol)
            local startPos = util_convertToNodeSpace(slotsNode, tempSymbolLayer)
            tempSymbol:setPosition(startPos)
            --
            util_setCascadeOpacityEnabledRescursion(tempSymbol, true)
            tempSymbol:runAction(actSeq:clone())
            self:levelPerformWithDelay(fadeTime*0.6, function()
                slotsNode:setVisible(true)
            end)
        end
    end

    self:levelPerformWithDelay(fadeTime, function()
        --随机wild
        self:playEffect_RandomWild(freeOverData, function()
            --继续消除
            local down     = freeOverData.down
            self:playDownAnim(1, down, false, _fun)
        end)
    end)
end
-- free结算时 后端会把回到base时的赢钱一起给过来 前端需要扣除一下
function CodeGameScreenCookieCrunchMachine:getFreeOverWinCoins()
    local winCoins = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeOverData = selfData.freeOver
    if not freeOverData then
        return winCoins
    end

    winCoins = self:getDownListWinCoins(freeOverData.down, false)
    return winCoins
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCookieCrunchMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    self.m_rightBarTips:playOverAnim()

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCookieCrunchMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    
    if self:isTriggerRandomWild(selfData) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_RandomWild
        selfEffect.p_selfEffectType = self.EFFECT_RandomWild
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    end

    self.m_bTriggerDown = false
    if self:isTriggerDown() then
        self.m_bTriggerDown = true

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_Down
        selfEffect.p_selfEffectType = self.EFFECT_Down
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCookieCrunchMachine:MachineRule_playSelfEffect(effectData)    
    if effectData.p_selfEffectType == self.EFFECT_RandomWild then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        self:playEffect_RandomWild(selfData, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_Down then
        --free触发的消除标记
        self.m_isFreeTriggerDown = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        --freeMore触发的消除标记
        self.m_isFreeMoreDown = self.m_runSpinResultData.p_freeSpinNewCount > 0
        self:playEffect_Down(function()
            self.m_isFreeTriggerDown = false

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

-- 处理首次freeSpin时立即假滚
function CodeGameScreenCookieCrunchMachine:playEffectNotifyNextSpinCall( )
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        -- 正常滚动0.5
        local delayTime = 0.5

        --!!! free模式 且为首次freeSpin时 取消延时
        if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.totalFreeSpinCount == globalData.slotRunData.freeSpinCount then
            delayTime = 0
        --!!! 有掉落
        elseif self.m_bTriggerDown then
            delayTime = 0.2
        --!!! 本关卡不计算连线时间
        else
            -- delayTime = delayTime + self:getWinCoinTime()
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

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenCookieCrunchMachine:slotReelDown( )
    CodeGameScreenCookieCrunchMachine.super.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenCookieCrunchMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    临时信号小块，不使用 池子的那一套，有可能泄漏
    create
    change
    runAnim
]]
function CodeGameScreenCookieCrunchMachine:createnCookieCrunchTempSymbol(_symbolType)
    local symbol = util_createView("CodeCookieCrunchSrc.CookieCrunchTempSymbol")
    symbol:initDatas(self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end
--[[
    工具相关
]]
-- free结算时 后端会把回到base时的赢钱一起给过来 前端需要扣除一下
function CodeGameScreenCookieCrunchMachine:getDownListWinCoins(_down,_isFree)
    local winCoins = 0
    local down = _down

    for _index,_data in ipairs(down) do
        winCoins = winCoins + _data.winCoins
    end

    local times = down[#down].clearTimes
    local jpIndex  = self.m_rightBarManager:getJackpotIndexByTimes(times)
    local jackpotWinCoins = 0
    if jpIndex > 0 then
        jackpotWinCoins = self:getCookieCrunchJackpotValue(_isFree, jpIndex)
        winCoins = winCoins + jackpotWinCoins
    end

    return winCoins
end

--事件中是否有大赢
function CodeGameScreenCookieCrunchMachine:isTriggerCookieCrunchBigWinEffect()
    if self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then  
        return true
    end
    return false
end
-- 展示jackpot弹板
function CodeGameScreenCookieCrunchMachine:showJackpotView(_coins, _jackpotIndex, _fun)
    local curMode = self:getCurrSpinMode()
    local isAuto = curMode == AUTO_SPIN_MODE or curMode == FREE_SPIN_MODE
    local data = {
        machine = self,
        coins = _coins,
        jackpotIndex = _jackpotIndex,
        isAuto  = isAuto,
    }
    local newFun = function()
        _fun()
        
    end
    local jackPotWinView = util_createView("CodeCookieCrunchSrc.CookieCrunchJackPotWinView", data)
    jackPotWinView:setOverAniRunFunc(newFun)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData()
end

function CodeGameScreenCookieCrunchMachine:getSlotsNodeWorldPos(_iCol, _iRow)
    local worldPos = cc.p(0, 0)
    local reelParent = self:getReelParent(_iCol)
    if nil ~= reelParent then
        local reelPos = util_getPosByColAndRow(self, _iCol, _iRow)
        worldPos = reelParent:convertToWorldSpace(reelPos)
    end
    
    return  worldPos
end

--BottomUI接口
function CodeGameScreenCookieCrunchMachine:getnCookieCrunchCurBottomWinCoins()
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
function CodeGameScreenCookieCrunchMachine:updateBottomUICoins( _beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound )
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end
-- 修改底栏文本资源 播完动画再还原
function CodeGameScreenCookieCrunchMachine:updateBottomWinCoinLabFont(_fontIndex, _animIndex)
    local label       = self.m_bottomUI.m_normalWinLabel

    -- local newFontName = ""
    -- -- 原本的资源
    -- if 0 == _fontIndex then
    --     if globalData.slotRunData.isDeluexeClub then
    --         newFontName = "GameNode/font/jinse_1.fnt"
    --     else
    --         newFontName = "GameNode/font/zise_1.fnt"
    --     end
    -- -- 效果资源
    -- elseif 1 == _fontIndex then
    --     if globalData.slotRunData.isDeluexeClub then
    --         newFontName = "CookieCrunchFont/Font_06.fnt"
    --     else
    --         newFontName = "CookieCrunchFont/Font_06.fnt"
    --     end
    -- end

    -- if "" ~= newFontName then
    --     local curString = label:getString()
    --     label:setFntFile(newFontName)
    --     self.m_bottomUI:updateWinCount(curString)
    -- end

    local actList = {}
    if _animIndex >= 2 or 0 == _fontIndex then
        local curPos = cc.p(label:getParent():getPosition())
        if 0 == _fontIndex then
            if curPos.x ~= self.m_winTextPos.x or curPos.y ~= self.m_winTextPos.y then
                table.insert(actList ,cc.Spawn:create(cc.ScaleTo:create(0.5, 1) , cc.MoveTo:create(0.5, self.m_winTextPos)))
            end
        else
            if curPos.x == self.m_winTextPos.x and curPos.y == self.m_winTextPos.y then
                table.insert(actList ,cc.Spawn:create(cc.ScaleTo:create(0.5, 1.7) , cc.MoveTo:create(0.5, cc.p(self.m_winTextPos.x, self.m_winTextPos.y+60))))
            end
        end
    end
    if #actList > 0 then
        -- 不能用label执行动画
        label:getParent():runAction(cc.Sequence:create(actList))
    end
end

function CodeGameScreenCookieCrunchMachine:getCookieCrunchWildLevelData(_level, _symbolType)
    local list = {
        TAG_SYMBOL_TYPE.SYMBOL_WILD,
        self.SYMBOL_Wild_2x,
        self.SYMBOL_Wild_3x,
        self.SYMBOL_Wild_4x,
        self.SYMBOL_Wild_5x,
    }

    for level,symbolType in ipairs(list) do
        if level == _level then
            return {level, symbolType}
        end
        if symbolType == _symbolType then
            return {level, symbolType}
        end
    end

    return nil
end
-- 通用延时接口
function CodeGameScreenCookieCrunchMachine:levelPerformWithDelay(_time, _fun)
    if _time <= 0 then
        _fun()
        return
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        _fun()

        waitNode:removeFromParent()
    end, _time)

    return waitNode
end
-- jackpot池
function CodeGameScreenCookieCrunchMachine:getCookieCrunchJackpotValue(_isFree, _jpIndex, _totalBet)
    local pool  = _isFree and self.m_freeJackpot or self.m_baseJackpot

    if not _totalBet then
        _totalBet = globalData.slotRunData:getCurTotalBet()
    end

    local multi = pool[_jpIndex]
    local value = multi * _totalBet
     
    -- local sMsg = string.format("[CodeGameScreenCookieCrunchMachine:getCookieCrunchJackpotValue] _isFree=(%s) _jpIndex=(%d) _totalBet=(%d) value=(%d)", (_isFree and "true" or "false"), _jpIndex, _totalBet, value)
    -- release_print(sMsg)
    -- print(sMsg)

    return value
end
--[[
    大赢相关
]]
-- 参考 BaseMachine:addLastWinSomeEffect()
function CodeGameScreenCookieCrunchMachine:isTriggerCookieCrunchBigWin(_winCoins, _betCoins)
    local betCoins   = _betCoins or globalData.slotRunData:getCurTotalBet()
    local multi      = _winCoins / betCoins 

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate

    local winType = WinType.Normal

    if multi >= iEpicWinLimit then
        winType = WinType.EpicWin
    elseif multi >= iMegaWinLimit then
        winType = WinType.MegaWin
    elseif multi >= iBigWinLimit then
        winType = WinType.BigWin
    end

    return winType
end
--[[
    重写底层接口
]]
--小块
function CodeGameScreenCookieCrunchMachine:getBaseReelGridNode()
    return "CodeCookieCrunchSrc.CookieCrunchSlotsNode"
end

---
-- 显示free spin
function CodeGameScreenCookieCrunchMachine:showEffect_FreeSpin(effectData)
    --!!! 处于free模式时 freeMore在断线重连时不在展示弹板
    local curTotalTimes = self.m_freeSpinBar.m_freespinTotalTimes
    local newTotalTimes = globalData.slotRunData.totalFreeSpinCount
    if curTotalTimes == newTotalTimes and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        effectData.p_isPlay = true
        self:playGameEffect() 
        return  
    end

    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
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
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_Scatter_actionframe_more.mp3")
    else
        -- gLobalSoundManager:setLockBgMusic(false)
        -- 停掉背景音乐
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_Scatter_actionframe.mp3")
    end

    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end

    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)

    return true
end

---
--设置bonus scatter 层级
function CodeGameScreenCookieCrunchMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or
        symbolType == self.SYMBOL_Bonus_1 or
        symbolType == self.SYMBOL_Bonus_2 then
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

function CodeGameScreenCookieCrunchMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

--[[
    预告中奖
]]
function CodeGameScreenCookieCrunchMachine:operaSpinResultData(param)
    CodeGameScreenCookieCrunchMachine.super.operaSpinResultData(self,param)

    -- 首次free
    self.m_isPlayFirstFree = self:playFirstFreeAnim()
    -- 预告中奖标记
	self.m_isPlayWinningNotice = self:playYugaoAnim()
end


function CodeGameScreenCookieCrunchMachine:playYugaoAnim()
    if self.m_isPlayFirstFree  then
        return false
    end

    local features      = self.m_runSpinResultData.p_features or {}
    
    -- local winCoins      = self.m_runSpinResultData.p_winAmount
    -- local winType       = self:isTriggerCookieCrunchBigWin(winCoins)
    -- local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    -- local down          = selfData.down or {}
    -- local clearTimes    = #down > 0 and down[#down].clearTimes or 0

    local probability   = (math.random(1,3) <= 1)
    -- local bPlayYugao = ((winType > 1 and clearTimes >= 3) or #features > 1) and probability
    local bPlayYugao = #features > 1 and probability

    if bPlayYugao then
        gLobalSoundManager:playSound("CookieCrunchSounds/music_CookieCrunch_yuGao.mp3")
        self.m_yugaoAnim:setVisible(true)
        self.m_yugaoAnim:runCsbAction("actionframe", false, function()
            self.m_yugaoAnim:setVisible(false)
        end)
        return true
    end

    return false
end

function CodeGameScreenCookieCrunchMachine:playFirstFreeAnim()
    if self.m_freeGuochang:isVisible() then
        return true
    end
    
    return false
end
-- 关卡重写方法
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCookieCrunchMachine:MachineRule_ResetReelRunData()
    if self.m_isPlayWinningNotice or self.m_isPlayFirstFree then
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
function CodeGameScreenCookieCrunchMachine:updateNetWorkData()
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
    -- 将下一步的逻辑包裹一下
    local nextFun = function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    -- 判断本次spin的预告中奖标记
    if self.m_isPlayWinningNotice then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            nextFun()
            waitNode:removeFromParent()
        -- 时间线长度
        end, 180/60)
    elseif self.m_isPlayFirstFree then
        local nowTime       = xcyy.SlotsUtil:getMilliSeconds()
        local startSpinTime = self.m_startSpinTime or 0
        local waitTime      = (nowTime - startSpinTime) / 1000
        local animTime      = 135/60 
        local delayTime = math.max(0, animTime - waitTime) 
        self:levelPerformWithDelay(delayTime, function()
            nextFun()
        end)
    else
        nextFun()
    end
end

---
-- 增加赢钱后的 效果
function CodeGameScreenCookieCrunchMachine:addLastWinSomeEffect()
    -- !!!移除连线检测
    -- local notAddEffect = self:checkIsAddLastWinSomeEffect()

    -- if notAddEffect then
    --     return
    -- end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    local curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

function CodeGameScreenCookieCrunchMachine:calculateLastWinCoin()
    CodeGameScreenCookieCrunchMachine.super.calculateLastWinCoin(self)
    
    local leftCount  = self.m_runSpinResultData.p_freeSpinsLeftCount
    local totalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    if 0 == totalCount then
    -- free触发时不播大赢
    -- free结束时检测大赢时 需要用总赢钱(包含打断流程的赢钱)
    elseif 0 == leftCount or leftCount == totalCount then
        self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_fsWinCoins
    end

    
end

-- 处理free首次的假滚第一列和最后一列移除 特殊信号
function CodeGameScreenCookieCrunchMachine:checkUpdateReelDatas(parentData)
    local reelDatas = CodeGameScreenCookieCrunchMachine.super.checkUpdateReelDatas(self, parentData)
    local newReelDatas = clone(reelDatas)

    if self:getCurrSpinMode() == FREE_SPIN_MODE and 
        globalData.slotRunData.totalFreeSpinCount == globalData.slotRunData.freeSpinCount then

        if 1 == parentData.cloumnIndex or self.m_iReelColumnNum == parentData.cloumnIndex then
            local specialSymbol = {
                [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
                [self.SYMBOL_Bonus_1] = self.SYMBOL_Bonus_1,
                [self.SYMBOL_Bonus_2] = self.SYMBOL_Bonus_2,
            }
            for i=#newReelDatas,1,-1 do
                local symbolType = newReelDatas[i]
                if nil ~= specialSymbol[symbolType] then
                    table.remove(newReelDatas, i)
                end
            end

            parentData.reelDatas = newReelDatas
        end
    end

    return newReelDatas
end

--顶部补块 解决消除关卡顶部出现较大图标的问题
function CodeGameScreenCookieCrunchMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        --!!!
        symbolType = 0
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    parentData.symbolType = symbolType
    if self.m_bigSymbolInfos[symbolType] ~= nil then
        parentData.order =  self:getBounsScatterDataZorder(symbolType) - rowIndex
    else
        parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
    end
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end
-- 处理freeOver结束恢复背景音效的逻辑放在大赢后
function CodeGameScreenCookieCrunchMachine:triggerFreeSpinOverCallFun()
    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    self:postFreeSpinOverTriggerBigWIn(_coins)
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    if self:isTriggerCookieCrunchBigWinEffect() then
    else
        self:resetMusicBg()
    end
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenCookieCrunchMachine:showEffect_NewWin(effectData, winType)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg", winType)
    bigMegaWin:initViewData(
        self.m_llBigOrMegaNum,
        winType,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_OVER_BIGWIN_EFFECT, {winType = winType})
            -- cxc 2023年11月30日15:02:44  spinWin 需要监测弹（评分，绑定fb, 打开推送）
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("SpinWin", "SpinWin_" .. winType)
            if view then
                view:setOverFunc(function()
                    if not tolua.isnull(self) then
                        if self.playGameEffect then
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                end)
            else
                effectData.p_isPlay = true
                self:playGameEffect()
                if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) then
                    self:resetMusicBg()
                end
            end
        end
    )
    gLobalViewManager:showUI(bigMegaWin)
end

function CodeGameScreenCookieCrunchMachine:scaleMainLayer()
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
        if display.width / display.height > 1370/768 then
            mainScale = mainScale * 0.98
            mainPosY = mainPosY + 5
        elseif display.width / display.height >= 1228/768 then

        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.98
            mainPosY = mainPosY + 5
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 1.02
            mainPosY = mainPosY + 5
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

return CodeGameScreenCookieCrunchMachine