---
-- 2021年4月12日
-- CodeGameScreenPepperBlastMachine.lua
--[[
    玩法1:消除
    条件:出现bonus wild（）时
    展示:轮盘上的低级图标L1~L6会消失，上方落下新的图标，直到全部为高级图标

    玩法2:FreeGame
    条件:3,4,或者5个scatter时，触发8,12,25次FreeSpin
    展示:玩法内可触发其他玩法

    玩法3:SuperFreeGame
    条件:第五次触发FreeGame时，玩法进阶为SuperFreeGame,获得配置数量的FreeSpin次数
    展示:轮盘第3行第3列固定一个wild图标,玩法内可触发其他玩法

    玩法4:ReSpin/jcakPot
    条件:轮盘上出现6个及以上的wild图标时
    展示:
        普通wild触发普通respin，特殊wild触发特殊respin，特殊respin时jackPot上的钱会更多
        初始获得3次spin次数，出现新的特殊wild图标，spin次数重置为3
        玩法结束后按照当前的特殊wild图标数目获得对应档位的 jackpot。
        该玩法中wild不会参与连线
        spin次数小于等于0玩法结束
]]
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenPepperBlastMachine = class("CodeGameScreenPepperBlastMachine", BaseFastMachine)
local BaseDialog = util_require("Levels.BaseDialog")
local PepperBlastTransitionAnim = util_require("CodePepperBlastSrc.PepperBlastTransitionAnim")

CodeGameScreenPepperBlastMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
----自定义信号
--特殊wild
CodeGameScreenPepperBlastMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenPepperBlastMachine.SYMBOL_SCORE_SPECIAL_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE
----自定义事件
CodeGameScreenPepperBlastMachine.EFFECT_SPECIAL_WILD_FIRSTWIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10 --动效事件:消除玩法首次连线
CodeGameScreenPepperBlastMachine.EFFECT_SPECIAL_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 9 --玩法事件:消除
CodeGameScreenPepperBlastMachine.EFFECT_TIRIGGER_SCATTER = GameEffect.EFFECT_SELF_EFFECT - 8 --动效事件:触发FreeGame时播放scatter指定动画
CodeGameScreenPepperBlastMachine.EFFECT_SUPER_FREEGAME = GameEffect.EFFECT_SELF_EFFECT - 6 --动效事件:SuperFreeSpin滚动结束时固定wild参与连线

----自定义的一些变量

--消除类型的小块信号值
local lowSymbolList = {
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_1] = 1,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_2] = 1,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_3] = 1,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_4] = 1,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_5] = 1,
    [CodeGameScreenPepperBlastMachine.SYMBOL_SCORE_10] = 1
}
--背景Spine的播放概率
local jueseRandom = {}
--分值
CodeGameScreenPepperBlastMachine.m_lightScore = 0
--适配参数
CodeGameScreenPepperBlastMachine.MAIN_ADD_POSY = 0 -- -60
--重写快滚判断 设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

-- 构造函数
function CodeGameScreenPepperBlastMachine:ctor()
    BaseFastMachine.ctor(self)
    --策划要求不展示顶部的下一个小块
    self.m_bCreateResNode = false

    self.m_spinRestMusicBG = true

    --当前游戏模式展示的Ui类型 1:base 2:fs 3:rs :superFs
    self.m_gameFeature = 0
    --是否需要播放中奖预告 事件的判断条件
    self.m_isPlayWinningNotice = false
    self.m_symbolWinningNotice = {} --一些临时小块
    -- superFG 和 平均bat值
    self.m_bInSuperFreeSpin = false
    self.m_avgBet = 0
    self.m_initAvgBet = 0
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenPepperBlastMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("PepperBlastConfig.csv", "LevelPepperBlastConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenPepperBlastMachine:initUI()
    self.m_spineGuochang = util_spineCreate("PepperBlast_guochang", true, true)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_spineGuochang:setVisible(false)
    self.m_spineGuochang:setPosition(cc.p(display.width / 2, display.height / 2))
    local spineGuochang_scale = 0.8
    self.m_spineGuochang:setScale(spineGuochang_scale)
    local pro = display.height / display.width
    if pro > 2 then
        spineGuochang_scale = 0.9
        self.m_spineGuochang:setScale(spineGuochang_scale)
    end

    self:initJackPotBar() --奖金池
    self:initFreeSpinBar() --freeSpin次数进度
    self:initSuperCollectBar() --freeGame次数进度
    self:initReSpinTimesBar() --reSpin次数进度

    self:initBgSpine() --背景人物动画
    self:inieLockWild() --固定wild初始化创建

    self:changeGameFeature(1)
    self:upDateSpineAnim()

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end
            --如果是消除玩法触发的就播放连线音效
            if self.m_bIsBigWin then
                if(self.m_isFirstLinesWinCoin)then
                    self.m_isFirstLinesWinCoin = false
                else
                    return
                end
            end
            
            --触发freeSpin时不播连线音效
            local scatterNum = 0
            local getScatterNum = function(_node, _iCol, _iRow)
                if (_node and _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    scatterNum = scatterNum+1   
                end
            end
            self:reelForeach(getScatterNum)
            if(scatterNum>=3)then
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
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end
            -- 赢钱音效，背景避让
            local soundName = "PepperBlastSounds/music_PepperBlast_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId, self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenPepperBlastMachine:initJackPotBar()
    local parent = self:findChild("jackpot")
    self.m_jackPotBar = util_createView("CodePepperBlastSrc.PepperBlastJackPotBarView")
    self.m_jackPotBar:initMachine(self)
    parent:addChild(self.m_jackPotBar)
    -- util_setCsbVisible(self.m_jackPotBar, true)
    self.m_jackPotBar:setPosition(0, 0)
end
function CodeGameScreenPepperBlastMachine:initFreeSpinBar()
    local parent = self:findChild("loadingBar")
    self.m_baseFreeSpinBar = util_createView("CodePepperBlastSrc.PepperBlastFreespinBarView")
    parent:addChild(self.m_baseFreeSpinBar)
    -- util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

--===超级freeSpin收集进度
function CodeGameScreenPepperBlastMachine:initSuperCollectBar()
    local parent = self:findChild("loadingBar")
    self.m_superCollectBar = util_createView("CodePepperBlastSrc.PepperBlastSuperCollectBar")
    parent:addChild(self.m_superCollectBar)
    -- util_setCsbVisible(self.m_superCollectBar, true)
    self.m_superCollectBar:setPosition(0, 0)
end

function CodeGameScreenPepperBlastMachine:upDateSuperCollectBar(endFun)
    if (nil ~= self.m_superCollectBar) then
        --spin里面的收集数据会在断线时拿不到
        local collectNetData = self.m_runSpinResultData.p_collectNetData[1]
        self.m_superCollectBar:changeSuperCollectByCount(collectNetData, endFun)
    end
end
--提示按钮触摸状态 @other_check : 其他条件
function CodeGameScreenPepperBlastMachine:upDateSuperCollectBtnEnable(other_check)
    if (nil ~= self.m_superCollectBar) then
        local isNormalSpin = self.getCurrSpinMode() == NORMAL_SPIN_MODE
        local isEnable = other_check and isNormalSpin
        self.m_superCollectBar:setBotTouch(isEnable)
    end
end

--===reSpin次数
function CodeGameScreenPepperBlastMachine:initReSpinTimesBar()
    local parent = self:findChild("loadingBar")
    self.m_reSpinTimesBar = util_createView("CodePepperBlastSrc.PepperBlastReSpinTimesBar")
    parent:addChild(self.m_reSpinTimesBar)
    self.m_reSpinTimesBar:setPosition(0, 0)
end
--===过场动画FreeGame
function CodeGameScreenPepperBlastMachine:initTransitionAnim(parent)
    --jackPot过场
    self.m_transitionAnim = PepperBlastTransitionAnim:create()
    parent:addChild(self.m_transitionAnim)
    self.m_transitionAnim:setVisible(false)
end
function CodeGameScreenPepperBlastMachine:playMainUiTransitionAnim(delayFun)
    --主界面过场动画

    self.m_spineGuochang:setVisible(true)
    --过场音效
    gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_RS_Guochang.mp3")

    local animName = "actionframe"
    util_spinePlay(self.m_spineGuochang, animName)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            if delayFun then
                delayFun()
                delayFun = nil
            end
            performWithDelay(
                waitNode,
                function()
                    self.m_spineGuochang:setVisible(false)
                    waitNode:removeFromParent()
                end,
                0.8
            )
        end,
        0.5
    )
end

--===背景Spine
function CodeGameScreenPepperBlastMachine:initBgSpine()
    local parent = self:findChild("dajuese")
    self.m_spineJuese = util_spineCreate("PepperBlast_Juese", true, true)
    parent:addChild(self.m_spineJuese)

    --背景Spine2 的父节点层级
    self:findChild("aheadJuese"):setLocalZOrder(9999999)
end
--刷新背景Spine动画 并在结束后按概率 重置为 基础模式 下的动画播放
function CodeGameScreenPepperBlastMachine:upDateSpineAnim(animName, isLoop, endFun)
    if (not self.m_spineJuese) then
        return
    end
    if (not animName) then
        --初始化一下概率表
        if (not jueseRandom or #jueseRandom < 1) then
            jueseRandom = {}
            --从小到大的排序
            local names = {
                {"idleframe2", 20},
                {"idleframe3", 20},
                {"idleframe", 60}
            }
            local all_weight = 0

            for _index, _data in ipairs(names) do
                all_weight = all_weight + _data[2]
            end

            local progress = 0
            local value = 0
            for _index, _data in ipairs(names) do
                progress = math.floor(_data[2] / all_weight * 100)
                value = value + progress
                table.insert(jueseRandom, {_data[1], value})
            end
        end
        --随机取一个动画名称
        local random_value = math.random(1, 100)
        for _index, _data in ipairs(jueseRandom) do
            if (random_value <= _data[2] or _index == #jueseRandom) then
                animName = _data[1]
                break
            end
        end
    end

    util_spinePlay(self.m_spineJuese, animName, isLoop)
    util_spineEndCallFunc(
        self.m_spineJuese,
        animName,
        function()
            if (endFun) then
                endFun()
            end

            self:upDateSpineAnim()
        end
    )
end
--预告中奖
function CodeGameScreenPepperBlastMachine:playAheadJueseSpine(endFun)
    --初始化一个
    if (not self.m_spineAheadJuese) then
        local parent = self:findChild("aheadJuese")
        self.m_spineAheadJuese = util_spineCreate("PepperBlast_Juese2", true, true)
        parent:addChild(self.m_spineAheadJuese)
    end

    --预告中奖音效
    self.m_noticeSoundId = gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_notice.mp3")

    local animName = "actionframe"
    --人物
    util_spinePlay(self.m_spineJuese, animName)
    util_spineEndCallFunc(
        self.m_spineJuese,
        animName,
        function()
            self:upDateSpineAnim()
            if (endFun) then
                endFun()
            end
        end
    )
    --辣椒掉落
    util_spinePlay(self.m_spineAheadJuese, animName, false)
    --爆炸 -> 压暗
    self:playZhaAction(
        "actionframe",
        false,
        function()
        end
    )
    local time = 120 / 60

    scheduler.performWithDelayGlobal(
        function()
            self.m_csbAn:setVisible(true)
            self.m_csbAn:runCsbAction("actionframe", true)
        end,
        time,
        self:getModuleName()
    )

end
function CodeGameScreenPepperBlastMachine:playZhaAction(actName, loop, endFun)
    if (not self.m_csbZha) then
        local parent = self:findChild("zha")
        --爆炸 和 淡出
        self.m_csbZha = util_createAnimation("PepperBlast_zha.csb")
        parent:addChild(self.m_csbZha)
        --压暗
        self.m_csbAn = util_createAnimation("PepperBlast_zha_0.csb")
        local parent2 = self.m_csbZha:findChild("Node_PepperBlast_zha_0")
        parent2:addChild(self.m_csbAn)
        util_setCascadeOpacityEnabledRescursion(self.m_csbAn, true)
        self.m_csbAn:setVisible(false)
    end

    self.m_csbZha:runCsbAction(
        actName,
        loop,
        function()
            if (endFun) then
                endFun()
            end
        end
    )
end

--======固定Wild
-- @wordPos : 修改坐标的对应世界坐标
function CodeGameScreenPepperBlastMachine:inieLockWild(wordPos)
    local parent = self:findChild("aheadJuese")
    if (not self.m_lockWild) then
        self.m_lockWild = util_createAnimation("PepperBlast_wildL_lock.csb")
        parent:addChild(self.m_lockWild)
        self.m_lockWild:setVisible(false)
    end
    if (wordPos) then
        local pos = parent:convertToNodeSpace(wordPos)
        self.m_lockWild:setPosition(pos.x, pos.y)
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenPepperBlastMachine:initGameStatusData(gameData)
    BaseFastMachine.initGameStatusData(self,gameData)
    if gameData and gameData.spin and gameData.spin.avgBet  then
        self.m_initAvgBet = gameData.spin.avgBet
    end
end

-- 断线重连
function CodeGameScreenPepperBlastMachine:MachineRule_initGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bet = selfData.bet or self.m_initAvgBet

     --是否重连reSpin模式
    self.m_bIsRespinReconnect = (self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0)
    if(self.m_bIsRespinReconnect)then
        self.m_jackPotBar:setWinMultiple()
    end

    --超级FreeSpin进度条
    self:upDateSuperCollectBar()
    if (not self.m_bProduceSlots_InFreeSpin) then
        self.m_superCollectBar:ShowTip()
    end

    --SuperFreeSpin一些展示
    if (self.m_bProduceSlots_InFreeSpin) then
        --superFreeSpin
        local frssSpinType = selfData and selfData.freeSpinType or 1

        self.m_bInSuperFreeSpin = 0 == frssSpinType
        if (self.m_bInSuperFreeSpin) then
            --平均值bet
            self.m_avgBet = bet

            --消除玩法固定小块添加
            self:playWildAddToReel(false)

            self.m_bottomUI:showAverageBet()
        end
    end
   
    
    if(self.m_bProduceSlots_InFreeSpin or self.m_bIsRespinReconnect)then
        --超级FreeSpin提示界面
        self:upDateSuperCollectBtnEnable(false)
    end
end

function CodeGameScreenPepperBlastMachine:reSpinResetReelShow(finalReels)
    local resetSymbol = function(_node, _iCol, _iRow)
        if (_node) then
            --数据的行索引
            local data_iRow = 1 + (3 - _iRow)
            local symbolType = finalReels[data_iRow][_iCol]
            --修改一下信号类型
            _node.p_symbolType = symbolType

            local ccbName = self:getSymbolCCBNameByType(self, _node.p_symbolType)
            _node:initSlotNodeByCCBName(ccbName, _node.p_symbolType)
            _node:resetReelStatus()
        end
    end
    self:reelForeach(resetSymbol)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPepperBlastMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "PepperBlast"
end

-- 继承底层respinView
function CodeGameScreenPepperBlastMachine:getRespinView()
    return "CodePepperBlastSrc.PepperBlastRespinView"
end
-- 继承底层respinNode
function CodeGameScreenPepperBlastMachine:getRespinNode()
    return "CodePepperBlastSrc.PepperBlastRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPepperBlastMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
        return "Socre_PepperBlast_Wild"
    elseif (symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD) then
        return "Socre_PepperBlast_Wild1"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_PepperBlast_10"
    end

    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenPepperBlastMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
        return 0
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        score = "GRAND"
    end

    return score
end

function CodeGameScreenPepperBlastMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenPepperBlastMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_SMALL_FIX_BONUS then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            symbolNode:getCcbProperty("m_lb_score"):setString(score)
        end

        symbolNode:runAnim("idleframe")
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                symbolNode:getCcbProperty("m_lb_score"):setString(score)

                symbolNode:runAnim("idleframe")
            end
        end
    end
end

function CodeGameScreenPepperBlastMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        self:setSpecialNodeScore(self, {node})
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPepperBlastMachine:getPreLoadSlotNodes()
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 15}
    }
    loadNodes[#loadNodes + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 15}
    loadNodes[#loadNodes + 1] = {symbolType = self.SYMBOL_SCORE_SPECIAL_WILD, count = 15}

    return loadNodes
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenPepperBlastMachine:isFixSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
        return true
    end

    return false
end

function CodeGameScreenPepperBlastMachine:changeSymbolVisible(reelCol)
    --最顶部的
    local targSp = self:getFixSymbol(reelCol, self.m_iReelRowNum + 1, SYMBOL_NODE_TAG)
    if (targSp) then
    end
    for iRow = 1, self.m_iReelRowNum do
        targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if (targSp) then
        -- targSp
        end
    end
end
--
--单列滚动停止回调
--
function CodeGameScreenPepperBlastMachine:slotOneReelDown(reelCol)
    BaseFastMachine.slotOneReelDown(self, reelCol)
    --对顶部不展示区域的信号可见性做处理
    self:changeSymbolVisible(reelCol)

    --super
    local fixCol, fixRow = 3, 1
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isSuperFreeGame = self:isTriggerSuperFreeSpinEffect()

    local isplay = true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        --中奖预告小块的父节点
        local parent = self:findChild("aheadJuese")

        local sybmolName = ""
        local nameList = {
            [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = "Scatter",
            [self.SYMBOL_SCORE_SPECIAL_WILD] = "Wild"
        }
        --特殊小块 都播音效和落地动画 就不拆为两个循环了
        for iRow = 1, self.m_iReelRowNum do
            --SuperFreeGame模式下 固定的特殊wild不播落地动画
            if ((fixCol ~= reelCol or fixRow ~= iRow) or not isSuperFreeGame) then
                local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
                if self:isFixSymbol(symbolType) then
                    isHaveFixSymbol = true
                    
                    local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
                    if (targSp) then
                        --scatter必须在有机会触发FG时才播放连线
                        if(TAG_SYMBOL_TYPE.SYMBOL_SCATTER == targSp.p_symbolType)then
                            if(reelCol<=2)then
                                sybmolName = nameList[targSp.p_symbolType] or ""
                            else
                                local scatterCount = self:getSymbolCountByType(targSp.p_symbolType, reelCol)
                                if(scatterCount>= 3 - (self.m_iReelColumnNum-reelCol))then
                                    sybmolName = nameList[targSp.p_symbolType] or ""
                                end
                            end
                        else
                            sybmolName = nameList[targSp.p_symbolType] or ""
                        end
                        --每掉落一个播一次，不再是一列播一次
                        if(""~=sybmolName)then
                            local soundName = string.format("PepperBlastSounds/music_PepperBlast_%s_reelDown_%d.mp3", sybmolName, reelCol)  
                            gLobalSoundManager:playSound(soundName)
                        end
                        

                        --中奖预告 创建层级较高的小块
                        if (self.m_isPlayWinningNotice and TAG_SYMBOL_TYPE.SYMBOL_SCATTER == targSp.p_symbolType) then
                            --通常落地
                            local newSymbol = self:createMaxZOrderSymbol(targSp, parent)
                            table.insert(self.m_symbolWinningNotice, newSymbol)
                            newSymbol:runAnim(
                                "buling",
                                false,
                                function()
                                    newSymbol:resetReelStatus()
                                end
                            )
                        else
                            targSp:runAnim(
                                "buling",
                                false,
                                function()
                                    targSp:resetReelStatus()
                                end
                            )
                        end
                    end
                end
            end
        end 
        -- if isHaveFixSymbol == true and isplay then
        --     isplay = false
        --     if(""~=sybmolName)then
        --         --scatter落地音效,wild
        --         local soundName = string.format("PepperBlastSounds/music_PepperBlast_%s_Down_%d.mp3", sybmolName, reelCol)  
        --         gLobalSoundManager:playSound(soundName)
        --     end
        -- end
    end

    --中奖预告 火焰淡出
    if (self.m_isPlayWinningNotice) then
        if (reelCol == 3) then
            self:playZhaAction(
                "actionframe2",
                false,
                function()
                    --进来后先把标记去掉
                    self.m_isPlayWinningNotice = false
                    --隐藏且暂停
                    self.m_csbAn:setVisible(false)
                    self.m_csbAn:pauseForIndex(0)
                    --移除预告的临时小块
                    for _index = #self.m_symbolWinningNotice, 1, -1 do
                        local _symbol = self.m_symbolWinningNotice[_index]
                        _symbol:removeFromParent()
                        self:pushSlotNodeToPoolBySymobolType(_symbol.p_symbolType, _symbol)
                        table.remove(self.m_symbolWinningNotice, _index)
                    end
                end
            )
        end
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenPepperBlastMachine:levelFreeSpinEffectChange()
    print("[CodeGameScreenPepperBlastMachine:levelFreeSpinEffectChange]")
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenPepperBlastMachine:levelFreeSpinOverChangeEffect()
    print("[CodeGameScreenPepperBlastMachine:levelFreeSpinOverChangeEffect]")
end
---------------------------------------------------------------------------

-- 触发freespin时调用
function CodeGameScreenPepperBlastMachine:showFreeSpinView(effectData)
    local showFSView = function(fsType)
        local view = {}
        local endFunction = function()
            --下一个事件
            effectData.p_isPlay = true
            self:playGameEffect()
        end

        --是否普通freeSpin
        local isCommonFs = 1 == fsType
        self.m_bInSuperFreeSpin = not isCommonFs
        local csbName = ""
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            csbName = BaseDialog.DIALOG_TYPE_FREESPIN_MORE
            -- csbName = (isCommonFs and "" or "Super") .. BaseDialog.DIALOG_TYPE_FREESPIN_MORE
            view =
                self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    endFunction()
                end,
                csbName,
                true
            )
            --修改节点展示 区分 common 和 super
            local img_common = view:findChild("PepperBlast_tanban_wenzi_5_7")
            local img_super = view:findChild("PepperBlast_tanban_wenzi_4_8")
            img_common:setVisible(isCommonFs)
            img_super:setVisible(not isCommonFs)
        else
            csbName = BaseDialog.DIALOG_TYPE_FREESPIN_START
            -- csbName = (isCommonFs and "" or "Super") .. BaseDialog.DIALOG_TYPE_FREESPIN_START
            local endFun = function()
                self:triggerFreeSpinCallFun()
                endFunction()
            end

            view =
                self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    if (isCommonFs) then
                        --超级FreeSpin 添加固定小块
                        endFun()
                    else
                        -- scheduler.performWithDelayGlobal(
                        --     function()
                                self:playWildAddToReel(true, endFun)
                                --平均bet值 展示
                                self.m_bottomUI:showAverageBet()
                        --     end,
                        --     2.5,
                        --     self:getModuleName()
                        -- )
                    end
                end,
                csbName
            )

            --修改节点展示 区分 common 和 super
            local img_common = view:findChild("PepperBlast_tanban_wenzi_6_4")
            local img_super = view:findChild("PepperBlast_tanban_wenzi_3_8")
            img_common:setVisible(isCommonFs)
            img_super:setVisible(not isCommonFs)
        end
        --添加spine
        local parent = view:findChild("spine_guochang")
        self:initTransitionAnim(parent)
        self.m_transitionAnim:playTransitionEffectStart()
        --第60帧切换背景
        local delayTime = 60 / 60
        local delayNode = cc.Node:create()
        self:addChild(delayNode)
        performWithDelay(
            delayNode,
            function()
                --切换游戏模式展示
                self:showFreeSpinBar()
                delayNode:removeFromParent()
            end,
            delayTime
        )
    
        util_spinePlay(self.m_spineJuese, "idleframe4", true)
        
        --单独重写一下 over展示接口，可以满足要求的话就不新写一个类继承实现了
        view.showOver = function(name)
            if view.isShowOver then
                return
            end
            view.isShowOver = true
            if view.m_btnClickFunc then
                view.m_btnClickFunc()
                view.m_btnClickFunc = nil
            end
            local time
            if view.m_status == view.STATUS_IDLE then
                --over
                time = view:getAnimTime(view.m_over_name)
                view:runCsbAction(view.m_over_name)
                --第25帧播放spine
                local delayTime = 25 / 60
                local delayNode = cc.Node:create()
                view:addChild(delayNode)
                performWithDelay(
                    delayNode,
                    function()
                        if (self.m_transitionAnim) then
                            self.m_transitionAnim:playTransitionEffectOver()
                            self.m_transitionAnim = nil
                        end
                    end,
                    delayTime
                )
            else
                view.m_status = view.STATUS_OVER
                if view.m_overRuncallfunc then
                    view.m_overRuncallfunc()
                    view.m_overRuncallfunc = nil
                end

                if view.m_callfunc then
                    view.m_callfunc()
                    view.m_callfunc = nil
                end
                view:removeFromParent()
                return
            end
            view.m_status = view.STATUS_OVER
            if not time or time <= 0 or time > 100 then
                time = view.m_overTime
            end
            performWithDelay(
                view,
                function()
                    if view.m_overRuncallfunc then
                        view.m_overRuncallfunc()
                        view.m_overRuncallfunc = nil
                    end

                    if view.m_callfunc then
                        view.m_callfunc()
                        view.m_callfunc = nil
                    end
                    view:removeFromParent()
                end,
                time
            )
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local endFun = function()
        --延迟0.5 不做特殊要求都这么延迟
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        --3.展示freeGame弹板
        performWithDelay(
            waitNode,
            function()
                showFSView(selfData.freeSpinType)
                waitNode:removeFromParent()
            end,
            0.5
        )
    end

    --1.收集条上涨
    local scatterCollectEndFun = function()
        --2.大角色弹琴
        self:upDateSpineAnim("actionframe2", false, endFun)
        gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_Juese_TanQin_Yuyin.mp3")
    end
    self:playScatterEffect(scatterCollectEndFun)
end

-- 触发freespin结束时调用
function CodeGameScreenPepperBlastMachine:showFreeSpinOverView()
    local endFun = function()
        self.m_spineJuese:setVisible(false)
        self:triggerFreeSpinOverView()
    end
    local animName = "actionframe3"
    --玩法结束弹琴60帧
    gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_Juese_TanQin_60.mp3")
    util_spinePlay(self.m_spineJuese, animName, false)
    util_spineEndCallFunc(
        self.m_spineJuese,
        animName,
        function()
            endFun()
        end
    )
end
-- 将原 showFreeSpinOverView 的内容搬运到这个接口，原接口处理动画播放完毕再调用此接口展示面板
function CodeGameScreenPepperBlastMachine:triggerFreeSpinOverView()
    local fsType = self.m_baseFreeSpinBar:getFreeSpinType()
    local isCommon = 1 == fsType
    local view = {}

    local coins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local num = self.m_runSpinResultData.p_freeSpinsTotalCount
    local csbName = (isCommon and "" or "Super") .. BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    if(not isCommon)then
        --平均bet值 隐藏
       self.m_bottomUI:hideAverageBet()
    end
    view =
        self:showFreeSpinOver(
        coins,
        num,
        csbName,
        function()
            --截断音效
            if(self.m_fsOverSoundId)then
                gLobalSoundManager:stopAudio(self.m_fsOverSoundId)
                self.m_fsOverSoundId = nil
            end
            self:upDateSuperCollectBar()
            

            -- 调用此函数才是把当前游戏置为freespin结束状态
            self:triggerFreeSpinOverCallFun()
            self:upDateSuperCollectBtnEnable(true)
            self.m_bInSuperFreeSpin = false
            --
            self.m_spineJuese:setVisible(true)
        end
    )

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.5, sy = 0.5}, 1312)
    node = view:findChild("m_lb_num")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 70)
    self:reSetSuperLockWildOrder()
end

function CodeGameScreenPepperBlastMachine:reSetSuperLockWildOrder()
    --修改固定wild节点 层级和父节点
    if (self.m_SuperLockWild) then
        local iCol, iRow = 3, 1
        self.m_SuperLockWild:resetReelStatus()
        local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(self.m_SuperLockWild:getPositionX(), self.m_SuperLockWild:getPositionY()))
        local pos = self.m_slotParents[iCol].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        self.m_SuperLockWild:removeFromParent()
        --层级改为wild层级
        local showOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD, self.m_SuperLockWild.p_cloumnIndex, self.m_SuperLockWild.p_rowIndex)
        self.m_SuperLockWild:setLocalZOrder(showOrder + iCol)
        self.m_SuperLockWild:setPosition(cc.p(pos.x, pos.y))
        self.m_SuperLockWild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        self.m_slotParents[iCol].slotParent:addChild(self.m_SuperLockWild)
        --
        self.m_SuperLockWild = nil
    end
end
--=====重写覆盖父类的freeSpin三个弹板接口
function CodeGameScreenPepperBlastMachine:showFreeSpinMore(num, func, csbName, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    isAuto = isAuto and BaseDialog.AUTO_TYPE_NOMAL
    return self:showDialog(csbName, ownerlist, newFunc, isAuto)
end
function CodeGameScreenPepperBlastMachine:showFreeSpinStart(num, func, csbName, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    isAuto = isAuto and BaseDialog.AUTO_TYPE_NOMAL

    gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_FG_Start.mp3")
    return self:showDialog(csbName, ownerlist, func, isAuto)
end
function CodeGameScreenPepperBlastMachine:showFreeSpinOver(coins, num, csbName, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = coins

    self.m_fsOverSoundId = gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_FG_Over.mp3")
    return self:showDialog(csbName, ownerlist, func)
end
--添加一个Wild到指定位置 @playAnim 是否播放固定动画
function CodeGameScreenPepperBlastMachine:playWildAddToReel(playAnim, endFun)
    --第三列第三行
    local iCol, iRow = 3, 1
    local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    local wildNode = self:getSlotNodeBySymbolType(self.SYMBOL_SCORE_SPECIAL_WILD)
    if (symbolNode) then
        wildNode.m_isLastSymbol = symbolNode.m_isLastSymbol
        --放进池子
        symbolNode:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(symbolNode.p_symbolType, symbolNode)
    else
        wildNode.m_isLastSymbol = false
    end
    --修改行列索引
    wildNode.p_cloumnIndex = iCol
    wildNode.p_rowIndex = iRow
    wildNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
    --固定节点层级只要最高就行 -- 尤其突出显示效果
    local showOrder = self:getBounsScatterDataZorder(self.SYMBOL_SCORE_SPECIAL_WILD, iCol, iRow)
    wildNode.m_showOrder = showOrder
    self.m_clipParent:addChild(wildNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder)
    --修改标记
    local tag = self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG)
    wildNode:setTag(tag)
    --位置
    local startPos = cc.p(self.m_SlotNodeW, (iRow - 0.5) * self.m_SlotNodeH)
    local slotParent = self:getReelParent(iCol)
    local posWorld = slotParent:convertToWorldSpace(cc.p(startPos.x, startPos.y))
    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
    wildNode:setPosition(pos)
    --连线
    local linePos = {}
    linePos[#linePos + 1] = {iX = iCol, iY = iRow}
    wildNode.m_bInLine = true
    wildNode:setLinePos(linePos)
    self.m_SuperLockWild = wildNode
    --添加固定Wild小块时 是否播放动画
    if (playAnim) then
        self:inieLockWild(posWorld)
        self.m_lockWild:setVisible(true)
        --固定wild音效
        gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_lockWild.mp3")
        self.m_lockWild:runCsbAction(
            "actionframe",
            false,
            function()
                self.m_lockWild:setVisible(false)
                if (endFun) then
                    endFun()
                end
            end
        )
    else
        if (nil ~= endFun) then
            endFun()
        end
    end
end
--runQuick
function CodeGameScreenPepperBlastMachine:showRespinJackpot(index, collectNum, coins, lajiaoShowType, func)
    local endFun = function()
        local jackPotWinView = util_createView("CodePepperBlastSrc.PepperBlastJackPotWinView")
        --解决活动返回时弹板尺寸缩小问题
        if globalData.slotRunData.machineData.p_portraitFlag then
            jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
        end
        --jackpot弹板弹出
        gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_JackpotView_Start.mp3")
        gLobalViewManager:showUI(jackPotWinView)
        --结算界面缩放适配，主要对高度调整,保证能全部展示出来
        -- local view_size = jackPotWinView:findChild("Panel_1"):getContentSize()
        -- if(display.height < view_size.height and globalData.slotRunData.machineData.p_portraitFlag)then
        --     local scaleH = display.height / view_size.height / 0.7--高没有完全铺满
        --     local scaleW = display.width / view_size.width

        --     local scale = scaleH<scaleW and scaleH or scaleW
        --     jackPotWinView:findChild("Node_1"):setScale(scale)
        -- end

        jackPotWinView:setAnchorPoint(cc.p(0.5, 0.5))
        jackPotWinView:setPosition(0, 0)
        jackPotWinView:initViewData(index, collectNum, coins, lajiaoShowType, func)
    end
    --配合结算面板的展示,面板结束后 需要重置为 基础模式下 的随机展示
    local animName = "actionframe4"
    util_spinePlay(self.m_spineJuese, animName)
    util_spineEndCallFunc(
        self.m_spineJuese,
        animName,
        function()
            endFun()
        end
    )
end

-- 结束respin收集
function CodeGameScreenPepperBlastMachine:playLightEffectEnd()
    -- 通知respin结束
    self:respinOver()
end
--
function CodeGameScreenPepperBlastMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if (not self.m_playAnimEnd) then
            return
        end

        local endFun = function()
            --jackPot弹板关闭 播过场动画
            self:playMainUiTransitionAnim(
                function()
                    self:playLightEffectEnd()
                    --切换模式展示
                    if (self.m_bProduceSlots_InFreeSpin) then
                        self:showFreeSpinBar()
                    else
                        self:changeGameFeature(1)
                    end
                    if(self.m_SuperLockWild)then
                        self.m_SuperLockWild:setVisible(true)
                    end

                    self.m_jackPotBar:upDateLajiaoShow(1)
                    self.m_jackPotBar:setWinMultiple(1)
                end
            )
        end

        local jackpotScore = self.m_jackPotBar:getReSpinCollectScore()
        if (jackpotScore > 0) then
            self.m_lightScore = jackpotScore
            local curJockPotIndex = self.m_jackPotBar:getCollectLevelByNum(#self.m_chipList)
            local collectNum = #self.m_chipList

            self:showRespinJackpot(curJockPotIndex, collectNum, jackpotScore, self.m_jackPotBar.m_lajiaoShowType, endFun)
        else
            endFun()
        end
        return
    end
    --固定小块
    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local cur_index = self.m_playAnimIndex
    chipNode:runAnim(
        "actionframe4",
        false,
        function()
            chipNode:runAnim("idleframe")
            if (1 == cur_index) then
                --动画结束标记
                self.m_playAnimEnd = true
                self:playChipCollectAnim()
            end
        end
    )
    self.m_playAnimIndex = self.m_playAnimIndex + 1
    self:playChipCollectAnim()
end

--结束移除小块调用结算特效
function CodeGameScreenPepperBlastMachine:reSpinEndAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    self.m_playAnimEnd = false

    --玩法结束弹琴60帧
    gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_Juese_TanQin_60.mp3")
    self:upDateSpineAnim("actionframe3", false, function()
    end)
    --棋盘上wild和奖金栏同时播放
    self:playChipCollectAnim()
    local curJockPotIndex = self.m_jackPotBar:getCollectLevelByNum(#self.m_chipList)
    self.m_jackPotBar:playLightAnim(
        curJockPotIndex,
        false,
        function()
            self.m_jackPotBar:playLightAnim(curJockPotIndex, false)
        end
    )
end

-- 根据本关卡实际小块数量填写 文档要求滚动不出现其它图标
function CodeGameScreenPepperBlastMachine:getRespinRandomTypes()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,

        TAG_SYMBOL_TYPE.SYMBOL_WILD,
        self.SYMBOL_SCORE_SPECIAL_WILD
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenPepperBlastMachine:getRespinLockTypes()
    local symbolList = {
        {type = TAG_SYMBOL_TYPE.SYMBOL_WILD, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_SCORE_SPECIAL_WILD, runEndAnimaName = "buling", bRandom = true}
    }

    return symbolList
end

function CodeGameScreenPepperBlastMachine:showRespinView()
    --是否有特殊wild参与触发ReSpin, 播放特殊wild jackPot动画
    local isSpecialWildTrigger = false
    local checkSpecialWild = function(_node, _iCol, _iRow)
        if (_node and _node.p_symbolType == CodeGameScreenPepperBlastMachine.SYMBOL_SCORE_SPECIAL_WILD) then
            isSpecialWildTrigger = true
            return true
        end
    end
    self:reelForeach(checkSpecialWild)
    --本次触发类型
    local showType = isSpecialWildTrigger and CodeGameScreenPepperBlastMachine.SYMBOL_SCORE_SPECIAL_WILD or TAG_SYMBOL_TYPE.SYMBOL_WILD

    local endFun = function()
        --先播放动画 再进入respin
        self:clearCurMusicBg()

        self:playMainUiTransitionAnim(
            function()
                --切换模式展示
                self:changeGameFeature(3)
                util_spinePlay(self.m_spineJuese, "idleframe4", true)
                --superFreeGame 进入 reSpin 隐藏固定wild
                if(self.m_SuperLockWild)then
                    self.m_SuperLockWild:setVisible(false)
                end
                --不为fs则清空底部赢钱
                if(not self.m_bProduceSlots_InFreeSpin)then
                    self.m_bottomUI:checkClearWinLabel()
                end
                
                --reSpin次数栏
                self.m_reSpinTimesBar:showTimes(self.m_runSpinResultData.p_reSpinCurCount)
                --初始化固定wild类型

                self.m_reSpinSymbolType = showType
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes()
                --可随机的特殊信号
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)
                --05.08
                self.m_respinView:playAllWildIdleAnim()
                --设置ReSpin 每列滚动结束回调
                self.m_respinView:setOneReelDownCallback(
                    function(_iCol, _lastCol)
                        --掉落了新的固定小块
                        if (self.m_runSpinResultData.p_reSpinCurCount == 3) then
                            --最后一列滚动停止
                            if (_iCol == _lastCol) then
                                -- self.m_reSpinTimesBar:playResetTimesEffect()
                                self.m_jackPotBar:updateReSpinCollectNum(#self.m_runSpinResultData.p_storedIcons)
                            end
                        end
                        -- if (_iCol == _lastCol) then
                        --     self.m_reSpinTimesBar:showTimes(self.m_runSpinResultData.p_reSpinCurCount)
                        -- end
                    end
                )
            end
        )
    end

    local spineEndFun = function()
        local parent = self:findChild("aheadJuese")
        local playWildAnim = function(_node, _iCol, _iRow)
            if (_node and _node.p_symbolType == showType) then
                local newSymbol = self:createMaxZOrderSymbol(_node, parent)
                _node:setVisible(false)
                newSymbol:runAnim(
                    "actionframe1",
                    false,
                    function()
                        _node:setVisible(true)
                        newSymbol:removeFromParent()
                        self:pushSlotNodeToPoolBySymobolType(newSymbol.p_symbolType, newSymbol)
                    end
                )
            end
        end
        --respin触发音效
        gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_RS_Start.mp3")

        --红辣椒触发respin升阶音效
        if(isSpecialWildTrigger)then
            gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_Jackpot_SpecialWild.mp3")
        end
        --superFreeGame触发红辣椒reSpin
        if(self.m_SuperLockWild and  showType == self.m_SuperLockWild.p_symbolType)then
            local parent = self:findChild("aheadJuese")
            local newSymbol = self:createMaxZOrderSymbol(self.m_SuperLockWild, parent)
            self.m_SuperLockWild:setVisible(false)
            newSymbol:runAnim(
                "actionframe1",
                false,
                function()
                    self.m_SuperLockWild:setVisible(true)
                    newSymbol:removeFromParent()
                    self:pushSlotNodeToPoolBySymobolType(newSymbol.p_symbolType, newSymbol)
                end
            )
        end
        self:reelForeach(playWildAnim)

        self.m_jackPotBar:setCurReSpinState(true)

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                --特殊wild升阶动画
                self.m_jackPotBar:playTriggerReSpinAnim(isSpecialWildTrigger, self.m_bIsRespinReconnect, #self.m_runSpinResultData.p_storedIcons, endFun)
                waitNode:removeFromParent()
            end,
            0.5
        )
    end
    --大角色弹琴
    self:upDateSpineAnim("actionframe2", false, spineEndFun)
    gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_Juese_TanQin.mp3")
end
--没有ReSpin开始弹板重写接口
function CodeGameScreenPepperBlastMachine:showReSpinStart(func)
    self:clearCurMusicBg()

    --wild播动画
    self.m_respinView:playAllWildIdleAnim()
    if func then
        func()
    end
    self.m_bIsRespinReconnect = nil
end

--ReSpin开始改变UI状态
function CodeGameScreenPepperBlastMachine:changeReSpinStartUI(respinCount)
    -- print("[CodeGameScreenPepperBlastMachine:changeReSpinStartUI] =", respinCount)
end

--ReSpin启动 刷新数量 --修改为棋盘停止时再刷新
function CodeGameScreenPepperBlastMachine:changeReSpinUpdateUI(curCount)
    if(not curCount)then
        return
    end
    self.m_reSpinTimesBar:showTimes(curCount)
end

--ReSpin结算改变UI状态 reSpin->baseGame  连线动画 -> 过场动画
function CodeGameScreenPepperBlastMachine:changeReSpinOverUI()
    if (#self.m_reelResultLines > 1) then
        self:showLineFrame()
    end
end

function CodeGameScreenPepperBlastMachine:showRespinOverView(effectData)
    self.m_jackPotBar:updateReSpinCollectNum(nil)

    local endFun = function()
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self:upDateSuperCollectBtnEnable(true)
        self.m_lightScore = 0
        self:resetMusicBg()
        --切换模式展示
        if (self.m_bProduceSlots_InFreeSpin) then
            util_spinePlay(self.m_spineJuese, "idleframe4", true)
        else
            self:upDateSpineAnim()
        end
        --重置主棋盘小块层级
        self:playInLineNodesResetReelShow()
    end
    endFun()
end

-- --重写组织respinData信息
function CodeGameScreenPepperBlastMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPepperBlastMachine:MachineRule_SpinBtnCall()
    -- 移除监听
    self:removeSoundHandler()
    self:setMaxMusicBGVolume()
    --移除赢钱音效
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    --超级FreeSpin提示 隐藏
    self.m_superCollectBar:HideTip()
    self:upDateSuperCollectBtnEnable(false)
    return false -- 用作延时点击spin调用
end

function CodeGameScreenPepperBlastMachine:enterGamePlayMusic()
    self:playEnterGameSound( "PepperBlastSounds/music_PepperBlast_enterLevel.mp3" )
end

function CodeGameScreenPepperBlastMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    --初始化刷新关卡控件
    self:upDateSuperCollectBar()
end

function CodeGameScreenPepperBlastMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            if (self.m_runSpinResultData.p_reSpinCurCount == 3) then
                self.m_reSpinTimesBar:playResetTimesEffect()
            end
            self.m_reSpinTimesBar:showTimes(self.m_runSpinResultData.p_reSpinCurCount)
        end,
        ViewEventType.NOTIFY_RESPIN_RUN_STOP
    )

end

function CodeGameScreenPepperBlastMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

--这个不能用 父类会调
function CodeGameScreenPepperBlastMachine:showFreeSpinBar()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local freeSpinType = selfData and selfData.freeSpinType or 1 --断线重连可能没有带回fsType字段
    self.m_baseFreeSpinBar:setFreeSpinType(freeSpinType)
    self.m_baseFreeSpinBar:changeFreeSpinByCount({})
    self.m_baseFreeSpinBar:updateFreespinVisible()

    local showType = (1 == freeSpinType) and 2 or 4
    self:changeGameFeature(showType)
end

function CodeGameScreenPepperBlastMachine:hideFreeSpinBar()
    self:changeGameFeature(1)
    self:upDateSpineAnim()
end
-- @showType 展示类型  1:基础游戏 2:freeSpin模式 3:reSpin模式 4:superFreeSpin模式
function CodeGameScreenPepperBlastMachine:changeGameFeature(showType)
    if (not self.m_baseFreeSpinBar or not self.m_superCollectBar or not self.m_reSpinTimesBar) then
        return
    end
    if (self.m_gameFeature == showType) then
        return
    end
    self.m_gameFeature = showType

    local isCommon = 1 == showType
    local isFreeSpin = 2 == showType
    local isReSpin = 3 == showType
    local isSuperFreeSpin = 4 == showType
    --几个进度栏的展示
    util_setCsbVisible(self.m_superCollectBar, isCommon)
    util_setCsbVisible(self.m_baseFreeSpinBar, (isFreeSpin or isSuperFreeSpin))
    util_setCsbVisible(self.m_reSpinTimesBar, isReSpin)

    if (isCommon) then
        self.m_superCollectBar:upDateLastOneAction()

        self.m_jackPotBar:setCurReSpinState(false)
        self.m_jackPotBar:setJackPotDiVisibleByCollectNum(7, 15)
        self.m_jackPotBar:playJackPotBarAllIdleAction()
    end

    --超级FreeSpin提示 触摸状态
    if (not isCommon) then
        self.m_superCollectBar:HideTip()
    else
        self:upDateSuperCollectBtnEnable(true)
    end
    
    

    --背景
    local bg_name = {
        [1] = {"BASE"},
        [2] = {"FREEGAMES", "FREEGAMES2"},
        [3] = {"RESPIN"},
        [4] = {"FREEGAMES", "FREEGAMES2"}
    }
    local bg_node = {}
    for _type, _names in ipairs(bg_name) do
        for _index, _name in ipairs(_names) do
            bg_node = self.m_gameBg:findChild(_name)
            util_setCsbVisible(bg_node, false)
        end
    end
    for _type, _names in ipairs(bg_name) do
        if (_type == showType) then
            for _index, _name in ipairs(_names) do
                bg_node = self.m_gameBg:findChild(_name)
                util_setCsbVisible(bg_node, true)
            end
            break
        end
    end
    --底板的背景
    self:findChild("reel_free"):setVisible(isFreeSpin or isSuperFreeSpin)

    --背景动画
    if (isFreeSpin or isSuperFreeSpin) then
        self.m_gameBg:runCsbAction("idle", true)
    else
        self.m_gameBg:pauseForIndex(0)
    end


end
-- ------------玩法处理 --

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPepperBlastMachine:addSelfEffect()
    if (self:isTriggerFirstWinLineEffect()) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_SPECIAL_WILD_FIRSTWIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SPECIAL_WILD_FIRSTWIN_EFFECT
    end

    if (self:isTriggerSpecialWildEffect()) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_SPECIAL_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SPECIAL_WILD_EFFECT
    end

    if (self:isTriggerSuperFreeSpinEffect()) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_SUPER_FREEGAME
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SUPER_FREEGAME
    end
end
--事件触发检测:消除玩法首次连线
function CodeGameScreenPepperBlastMachine:isTriggerFirstWinLineEffect()
    local firstLineInfo = {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --是否有消除后赢钱
    if selfData.fallWinAmount then
        --消除前连线赢钱
        self.m_fisrtLinesWinCoin = self.m_runSpinResultData.p_winAmount - selfData.fallWinAmount
        self.m_fisrtLinesLastWinCoin = 0
        if (self.m_runSpinResultData.p_freeSpinsTotalCount <= 0 or (self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount)) then
            self.m_fisrtLinesLastWinCoin = self.m_runSpinResultData.p_winAmount - selfData.fallWinAmount
        else
            self.m_fisrtLinesLastWinCoin = self.m_runSpinResultData.p_fsWinCoins - selfData.fallWinAmount
        end
        self:setLastWinCoin(self.m_fisrtLinesLastWinCoin)
    end
    --首次赢钱连线数据
    local winLines = selfData.beforeFallLines
    if winLines and #winLines > 0 then
        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.icons
            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:getFirstWinLineSymboltType(winLineData, lineInfo)
            if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
                if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
                elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                end
            end

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.amount / (self.m_runSpinResultData:getBetValue())

            firstLineInfo[#firstLineInfo + 1] = lineInfo
        end
    end
    --重置并保存最新的消除首次连线数据
    self:keepCurrentFirstSpinData(firstLineInfo)
    if (#self.m_FirstReelResultLines > 0) then
        return true
    end
    return false
end

function CodeGameScreenPepperBlastMachine:isTriggerSpecialWildEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData ~= nil then
        if selfData.fallSignals ~= nil and #selfData.fallSignals > 0 then
            return true
        end
    end

    return false
end

function CodeGameScreenPepperBlastMachine:isTiriggerScatterEffect()
    local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    local fsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount

    local startFreeSpin = fsLeftCount > 0 and fsLeftCount == fsTotalCount

    return startFreeSpin
end

function CodeGameScreenPepperBlastMachine:isTriggerSuperFreeSpinEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData ~= nil then
        if (selfData.freeSpinType and 0 == selfData.freeSpinType and self:getCurrSpinMode() == FREE_SPIN_MODE) then
            return true
        end
    end
    return false
end

function CodeGameScreenPepperBlastMachine:getFirstWinLineSymboltType(winLineData, lineInfo)
    local iconsPos = winLineData.icons
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex = 1, #iconsPos do
        local posData = iconsPos[posIndex]
        local rowColData = self:getRowAndColByPos(posData)
        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData -- 连线元素的 pos信息
        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if (symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD) then
            enumSymbolType = symbolType
        end
    end
    return enumSymbolType
end
function CodeGameScreenPepperBlastMachine:keepCurrentFirstSpinData(firstLineInfo) --保留本轮数据
    self.m_FirstReelResultLines = {}
    if #firstLineInfo ~= 0 then
        local lines = firstLineInfo
        local lineLen = #lines
        local hasBonus = false
        local hasScatter = false
        for i = 1, lineLen do
            local value = lines[i]
            local function copyLineValue()
                local cloneValue = clone(value)
                table.insert(self.m_FirstReelResultLines, cloneValue)
            end

            if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS or value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS and hasBonus == false then
                    copyLineValue()
                    hasBonus = true
                elseif value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN and hasScatter == false then
                    copyLineValue()
                    hasScatter = true
                end
            else
                copyLineValue()
            end
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPepperBlastMachine:MachineRule_playSelfEffect(effectData)
    if (effectData.p_selfEffectType == self.EFFECT_SPECIAL_WILD_FIRSTWIN_EFFECT) then
        self:playFirstWinLineEffect(effectData)
    elseif (effectData.p_selfEffectType == self.EFFECT_SPECIAL_WILD_EFFECT) then
        --消除触发
        local animName = "start"
        util_spinePlay(self.m_spineJuese, animName)
        util_spineEndCallFunc(
            self.m_spineJuese,
            animName,
            function()
                util_spinePlay(self.m_spineJuese, "idleframe6", true)
            end
        )
        self:playSpecialWildEffect(effectData)
    elseif (effectData.p_selfEffectType == self.EFFECT_SUPER_FREEGAME) then
        local endFun = function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        self:playSuperFreeSpinEffect(endFun)
    end

    return true
end

function CodeGameScreenPepperBlastMachine:playFirstWinLineEffect(effectData)
    local winLines = self.m_FirstReelResultLines
    if #winLines <= 0 then
        return
    end
    --移除scatter连线
    for _index = #winLines, 1, -1 do
        local lineData = self.m_FirstReelResultLines[_index]
        if lineData then
            if lineData.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                table.remove(winLines, _index)
            end
        end
    end

    --音效
    self.m_isFirstLinesWinCoin = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_fisrtLinesWinCoin, false})

    --连线
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)
    self:clearFrames_Fun()
    self:playInLineNodes()
    self:showAllFrame(winLines) -- 播放全部线框
    --进入下一个事件
    local delayTime = self.m_changeLineFrameTime --连线框时间
    scheduler.performWithDelayGlobal(
        function()
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        delayTime,
        self:getModuleName()
    )
end
function CodeGameScreenPepperBlastMachine:playSpecialWildEffect(effectData)
    local endFunction = function()
        local endFun = function()
            --恢复背景音乐
            self:resetMusicBg(true)

            effectData.p_isPlay = true
            self:playGameEffect()
        end

        --消除结束 停掉2播3
        gLobalSoundManager:stopAudio(self.m_curBgMusicId)
        gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_Juese_TanQin3.mp3")
        self:upDateSpineAnim("over", false, endFun)
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if (not selfData or not selfData.fallSignals) then
        endFunction()
        return
    end

    local animEndFun = function()
        local actEndFun = function()
            --每轮第一个开始掉落
            gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_Eliminate_newSymbol.mp3")
            if (self.m_runSpinResultData.p_freeSpinsTotalCount <= 0 or (self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount)) then
                self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
            else
                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            end
            --递归掉落
            self:specialWildFall(1, endFunction)
        end

        --首次移除低级图标
        local lowSymbols = {}
        local removeFun = function(_node, _iCol, _iRow)
            if _node then
                if (nil ~= lowSymbolList[_node.p_symbolType]) then
                    table.insert(lowSymbols, _node)
                end
            end
        end

        self:reelForeach(removeFun)
        for _index, _node in ipairs(lowSymbols) do
            --线上bug 函数链较长 拆分下 再看看后台具体报错定位
            local symbolParent = _node:getParent()
            local wordPos = symbolParent:convertToWorldSpace(cc.p(_node:getPosition()))
            if (_index == #lowSymbols) then
                --火球音效
                gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_Huoqiu.mp3")
                self:playHuoqiuCsbAction(_node, wordPos, actEndFun)
            else
                self:playHuoqiuCsbAction(_node, wordPos, nil)
            end
        end
    end

    -- 音效 -> 播放落地动画 -> 递归掉落
    --切换背景音乐
    self.m_curBgMusicId = gLobalSoundManager:playBgMusic("PepperBlastSounds/PepperBlastSounds_Juese_TanQin2.mp3")
    --消除触发音效
    local soundName = ""
    if(self.m_bInSuperFreeSpin)then
        soundName = "PepperBlastSounds/music_PepperBlast_Trigger_eliminate_super.mp3"
    else
        soundName = "PepperBlastSounds/music_PepperBlast_Trigger_eliminate.mp3"
    end
    gLobalSoundManager:playSound(soundName)
    --特殊wild列表
    local specialWilds = self:getCurSpecialWildList()
    for _index, _wild in ipairs(specialWilds) do
        if (1 == _index) then
            _wild:runAnim(
                "actionframe2",
                false,
                function()
                    animEndFun()
                    --移除临时wild
                    for _index, _wildNode in ipairs(specialWilds) do
                        _wildNode:removeFromParent()
                        self:pushSlotNodeToPoolBySymobolType(_wildNode.p_symbolType, _wildNode)
                    end
                end
            )
        else
            _wild:runAnim("actionframe2")
        end
    end
end

function CodeGameScreenPepperBlastMachine:playScatterEffect(endFun)
    --收集进度上涨
    gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_collectRise.mp3")
    self:upDateSuperCollectBar(endFun)
end
--去除固定wild小块移入棋盘内参与连线 @endFun :可选参数 延时结束回调
function CodeGameScreenPepperBlastMachine:playSuperFreeSpinEffect(endFun)
    local iCol, iRow = 3, 1
    local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
    if targSp then
        --移除该位置小块和固定小块，新建wild小块添加到该列
        if self.m_SuperLockWild then
            local symbolType = self.m_SuperLockWild.p_symbolType
            self.m_SuperLockWild:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(symbolType, self.m_SuperLockWild)
            self.m_SuperLockWild = nil
        end

        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        local wild = self:getSlotNodeBySymbolType(self.SYMBOL_SCORE_SPECIAL_WILD)
        wild.p_cloumnIndex = iCol
        wild.p_rowIndex = iRow
        wild.m_isLastSymbol = false
        local showOrder = self:getBounsScatterDataZorder(self.SYMBOL_SCORE_SPECIAL_WILD, iCol, iRow)
        wild.m_showOrder = showOrder
        wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        wild:setPosition(cc.p(pos.x, pos.y))
        -- self:getReelParent(iCol):addChild(wild, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        self.m_clipParent:addChild(wild, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:removeFromParent()
        local symbolType = targSp.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, targSp)
        local linePos = {}
        linePos[#linePos + 1] = {iX = iRow, iY = iCol}
        wild.m_bInLine = true
        wild:setLinePos(linePos)
        self.m_SuperLockWild = wild
    end
    --进入下一个事件
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(
        waitNode,
        function()
            if (nil ~= endFun) then
                endFun()
            end
            waitNode:removeFromParent()
        end,
        0.5
    )
end

function CodeGameScreenPepperBlastMachine:specialWildFall(animIndex, endFunction)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --线上bug 容错处理
    local maxIndex = selfData.fallSignals and #selfData.fallSignals or 0
    --跳出递归
    if (animIndex > maxIndex) then
        endFunction()
        return
    end
    --对当前棋盘小块需要掉落的进行移动
    local fun = function(_node, _iCol, _iRow)
        if (_node) then
            local moveNum = self:getNeedMoveRowNum(_iCol, _iRow)
            if (moveNum > 0) then
                local endPos = cc.p(0, -moveNum * self.m_SlotNodeH)
                local actMoveTo = cc.MoveBy:create(0.2, endPos)
                local actCallFun =
                    cc.CallFunc:create(
                    function()
                        --修改标记
                        local tag = self:getNodeTag(_iCol, _iRow - moveNum, SYMBOL_NODE_TAG)
                        _node:setTag(tag)
                    end
                )
                --修改连线位置
                local linePos = {}
                linePos[#linePos + 1] = {iX = _iRow - moveNum, iY = _iCol}
                _node.m_bInLine = true
                _node:setLinePos(linePos)
                --
                _node:runAction(cc.Sequence:create(actMoveTo, actCallFun))
            end
        end
    end
    self:reelForeach(fun)
    --存在消除时 等最后一个消除完毕后再下一步，不存在直接下一步
    local endFun = function()
        local waitNode = cc.Node:create()
        self:addChild(waitNode)

        performWithDelay(
            waitNode,
            function()
                self:specialWildFall(animIndex + 1, endFunction)
                waitNode:removeFromParent()
            end,
            0.2
        )
    end
    --创建新的小块并移动
    local fallSymbolInfo = selfData.fallSignals[animIndex]
    local isPlay = false
    --这一轮开始掉落音效
    gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_Eliminate_newSymbol.mp3")
    for i, v in ipairs(fallSymbolInfo) do
        local nodePos, nodeType = v[1], v[2]
        local fixPos = self:getRowAndColByPos(nodePos)
        local symbolNode = self:getSlotNodeBySymbolType(nodeType)
        --修改行列索引
        symbolNode.p_cloumnIndex = fixPos.iY
        symbolNode.p_rowIndex = fixPos.iX
        --修改标记
        local tag = self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        symbolNode:setTag(tag)
        --层级
        local showOrder = self:getBounsScatterDataZorder(nodeType, fixPos.iY, fixPos.iX)
        symbolNode.m_showOrder = showOrder
        self:getReelParent(fixPos.iY):addChild(symbolNode, showOrder)
        --起始位置偏移3行

        local startpos = cc.p(self.m_SlotNodeW, (symbolNode.p_rowIndex - 0.5) * self.m_SlotNodeH + 3 * self.m_SlotNodeH)
        symbolNode:setPosition(startpos)
        if (nil ~= lowSymbolList[symbolNode.p_symbolType]) then
            local wordPos = symbolNode:getParent():convertToWorldSpace(cc.p(startpos.x, startpos.y - 3 * self.m_SlotNodeH))

            if (not isPlay) then
                isPlay = true
                --火球音效
                gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_Huoqiu.mp3")
                self:playHuoqiuCsbAction(symbolNode, wordPos, endFun)
            else
                self:playHuoqiuCsbAction(symbolNode, wordPos, nil)
            end
        end

        --掉落
        local actMoveTo = cc.MoveBy:create(0.2, cc.p(0, -3 * self.m_SlotNodeH))
        local actCallFun =
            cc.CallFunc:create(
            function()
                --scatter 和特殊wild 当作特殊符号类型 提升层级展示
                if (symbolNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_WILD or symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    --落地动画
                    symbolNode:runAnim("buling")
                    -- if symbolNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                    symbolNode.m_bInLine = true
                    symbolNode:setLinePos(linePos)
                -- end
                end
            end
        )
        symbolNode:runAction(cc.Sequence:create(actMoveTo, actCallFun))
    end

    if (not isPlay) then
        endFun()
    end
end

--播放火球消除动画
function CodeGameScreenPepperBlastMachine:playHuoqiuCsbAction(symbolNode, wordPos, endFun)
    local actParent = self:findChild("aheadJuese")
    local diaoluo_csb, baozha_csb = self:getHuoqiuCsbNode()

    local nodePos = actParent:convertToNodeSpace(wordPos)
    actParent:addChild(diaoluo_csb[1], 99999)
    actParent:addChild(baozha_csb[1], 99999)
    diaoluo_csb[1]:setPosition(nodePos.x, nodePos.y)
    baozha_csb[1]:setPosition(nodePos.x, nodePos.y)

    -- 开始不能展示
    baozha_csb[1]:setVisible(false)

    local actionName = "actionframe"
    local time = 30 / 60
    util_csbPlayForKey(diaoluo_csb[2], actionName)
    --掉落动效 第 30 帧 播放 爆炸动效
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            baozha_csb[1]:setVisible(true)
            time = 5 / 60
            util_csbPlayForKey(
                baozha_csb[2],
                actionName,
                false,
                function()
                    diaoluo_csb[1]:removeFromParent()
                    baozha_csb[1]:removeFromParent()

                    if (nil ~= endFun) then
                        endFun()
                    end
                end
            )
            --爆炸动效 第20帧 移除小块
            performWithDelay(
                waitNode,
                function()
                    --此处移除小块展示
                    symbolNode:removeFromParent()
                    self:pushSlotNodeToPoolBySymobolType(symbolNode.p_symbolType, symbolNode)
                    waitNode:removeFromParent()
                end,
                time
            )
        end,
        time
    )
end

function CodeGameScreenPepperBlastMachine:getHuoqiuCsbNode()
    -- 掉落 -> 爆炸
    local diaoluo_node, dialuo_act = util_csbCreate("PepperBlast_wildL_huoqiu.csb")
    local baozha_node, baozha_act = util_csbCreate("PepperBlast_wildL.csb")

    return {diaoluo_node, dialuo_act}, {baozha_node, baozha_act}
end

function CodeGameScreenPepperBlastMachine:getNeedMoveRowNum(iCol, iRow)
    local moveNum = 0
    --行数-1 开始找不存在小块的位置 存在则需要移动
    for _row = iRow - 1, 1, -1 do
        local node = self:getFixSymbol(iCol, _row, SYMBOL_NODE_TAG)
        if (node == nil) then
            moveNum = moveNum + 1
        end
    end

    return moveNum
end
function CodeGameScreenPepperBlastMachine:reelForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if (isJumpFun) then
                return
            end
        end
    end
end
function CodeGameScreenPepperBlastMachine:getCurSpecialWildList()
    --棋盘上所有特殊wild
    local specialWilds = {}
    local fun = function(_node, _iCol, _iRow)
        if _node then
            if _node.p_symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
                table.insert(specialWilds, _node)
            end
        end
    end
    self:reelForeach(fun)

    --添加临时特殊wild
    local parent = self:findChild("aheadJuese")
    local tempWilds = {}
    for _index, _wild_node in ipairs(specialWilds) do
        local wildSymbol = self:createMaxZOrderSymbol(_wild_node, parent)
        wildSymbol:setLocalZOrder(self.m_iReelColumnNum - wildSymbol.p_cloumnIndex)
        table.insert(tempWilds, wildSymbol)
    end

    return tempWilds
end
--创建高层级小块不参与连线和棋盘时间
function CodeGameScreenPepperBlastMachine:createMaxZOrderSymbol(symbol, parent)
    local symbolType = symbol.p_symbolType
    local newSymbol = self:getSlotNodeBySymbolType(symbolType)
    local cloumnIndex = symbol.p_cloumnIndex or 1
    local rowIndex = symbol.p_rowIndex or 1
    newSymbol.p_cloumnIndex = cloumnIndex
    newSymbol.p_rowIndex = rowIndex
    local order = self:getBounsScatterDataZorder(symbol.p_symbolType, cloumnIndex, rowIndex) 
    parent:addChild(newSymbol, order)
    local wordPos = symbol:getParent():convertToWorldSpace(cc.p(symbol:getPositionX(), symbol:getPositionY()))
    local pos = parent:convertToNodeSpace(wordPos)
    newSymbol:setPosition(pos.x, pos.y)
    return newSymbol
end

--移除压暗效果和层级之上的scatter小块
function CodeGameScreenPepperBlastMachine:playRemoveZhaActionNodeEffect(effectData)
    local actEndFun = function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    --遮罩淡出效果
    self:playZhaAction(
        "actionframe3",
        false,
        function()
            actEndFun()
        end
    )
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPepperBlastMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenPepperBlastMachine:playEffectNotifyNextSpinCall()
    BaseFastMachine.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenPepperBlastMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    --预告中奖音效
    if self.m_noticeSoundId then
        gLobalSoundManager:stopAudio(self.m_noticeSoundId)
        self.m_noticeSoundId = nil
    end
    --
    self:upDateSuperCollectBtnEnable(true)
    --重置主棋盘小块层级
    self:playInLineNodesResetReelShow()
    
    BaseFastMachine.slotReelDown(self)
end

function CodeGameScreenPepperBlastMachine:getSymbolCountByType(symbolType, limitCol)
    local count = 0
    if (not self.m_runSpinResultData or not self.m_runSpinResultData.p_reels) then
        return count
    end
    for _iRow, _row_data in ipairs(self.m_runSpinResultData.p_reels) do
        for _iCol, _symbolType in ipairs(_row_data) do
            if ((not limitCol or _iCol<=limitCol) and symbolType == _symbolType) then
                count = count + 1
            end
        end
    end

    return count
end
--===========================================================================================一些特殊操作需要重写父类接口
-- 处理spin 返回结果
function CodeGameScreenPepperBlastMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self, param)
    --!!!新增平均值bet解析
    self.m_avgBet = 0
    if param and param[1] then
        local spinData = param[2]
        if spinData.result then
            if spinData.result then
                 --平均值bet
                if spinData.result.avgBet then
                    --如果本次是触发superFG的spin则取 selfData的数据
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    if(selfData and selfData.bet)then
                        self.m_avgBet = selfData.bet
                    else
                        self.m_avgBet = spinData.result.avgBet
                    end
                end
            end
        end
    end
end

-- 解决:superFreespin 使用平均Bet
function CodeGameScreenPepperBlastMachine:BaseMania_updateJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end
    --!!!新增逻辑
    if self.m_bInSuperFreeSpin and self.m_avgBet ~= 0 then
        totalBet = self.m_avgBet
    end

    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    --!!!线上bug 新增容错判断：认为是在奖金池没有初始化完成时 取了空的数据，增加容错后，在初始化完成后就能拿到正确展示,同时在更新展示的地方 添加 value > 0，的判断
    if not jackpotPools or not jackpotPools[index] then
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)
    return totalScore
end

function CodeGameScreenPepperBlastMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end

    
    local params = {self.m_iOnceSpinLastWin,isNotifyUpdateTop}
    
    --!!!新增逻辑
    if(self.m_fisrtLinesLastWinCoin)then
        params[1] = globalData.slotRunData.lastWinCoin
        --消除后第二次连线赢钱从上一次基础数值开始增加
        params[4] = self.m_fisrtLinesLastWinCoin
        self.m_fisrtLinesLastWinCoin = nil
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
end

---
-- 进入关卡
-- 解决进入关卡层级不对问题
function CodeGameScreenPepperBlastMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
        --!!!解决 红辣椒reSping模式 和 普通热 Spin模式 重连时，棋盘数据不是消除后的数据、层级异常 问题
        if (self.m_bIsRespinReconnect) then
            local selfData = self.m_runSpinResultData.p_selfMakeData
            local finalReels = selfData and selfData.finalReels or {}
            if (#finalReels > 0) then
                self:reSpinResetReelShow(finalReels)
            end
        end
    end
    --!!!重置主棋盘小块层级
    self:playInLineNodesResetReelShow()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects( )
        self:playGameEffect()
    end
end

--解决问题：触发scatter 同时 触发 大赢弹板时 时间延迟了0.5s 导致 连线晚移除了，触发时修延时为0
function CodeGameScreenPepperBlastMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    self:showLineFrame()

    local lineFrameEndFun = function()
        --重置主棋盘小块层级
        self:playInLineNodesResetReelShow()
        effectData.p_isPlay = true
        self:playGameEffect()
    end
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        --!!!主要修改此处
        local time = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) and 0 or 0.5
        scheduler.performWithDelayGlobal(
            function()
                lineFrameEndFun()
            end,
            time,
            self:getModuleName()
        )
    else
        lineFrameEndFun()
    end

    return true
end

--解决问题:scatter连线时其他小块不播放 idle动画

function CodeGameScreenPepperBlastMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent, lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                --!!!没有触发scatter才播放idle
                if (not self:isTiriggerScatterEffect()) then
                    lineNode:runIdleAnim()
                else
                    lineNode:resetReelStatus()
                end
            end
        end
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe     --解决层级问题 中线的>不中线的,
--
function CodeGameScreenPepperBlastMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
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
    if self.m_eachLineSlotNode ~= nil then
        --!!!重置所有小块为正常层级
        self:playInLineNodesResetReelShow()

        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    --!!! 信号层级+ 一列的数值
                    local order = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, slotsNode.p_cloumnIndex, slotsNode.p_rowIndex)
                    slotsNode:setLocalZOrder(order + 100)

                    slotsNode:runLineAnim()
                end
            end
        end
    end
end
--重置主棋盘所有小块为正常层级
function CodeGameScreenPepperBlastMachine:playInLineNodesResetReelShow()
    local resetSymbol = function(_node, _iCol, _iRow)
        if (_node) then
            --修改一下层级和信号类型
            local order = self:getBounsScatterDataZorder(_node.p_symbolType, _iCol, _iRow)
            _node:setLocalZOrder(order)
        end
    end
    self:reelForeach(resetSymbol)
end

---
--设置bonus scatter 层级   --解决一些特殊信号
function CodeGameScreenPepperBlastMachine:getBounsScatterDataZorder(symbolType, iCol, iRow)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        --!!!修改了这里
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif (symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCORE_SPECIAL_WILD) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end

    --!!!新增行列 右压左 下压上
    if (iCol and iRow) then
        order = order + iCol * 100 - iRow
    end
    
    return order
end

---
-- 显示free spin   --解决消除玩法时 scatter连线展示不正确
function CodeGameScreenPepperBlastMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            --!!!scatter连线排除其他图标
            scatterLineValue = lineValue

            scatterLineValue.vecValidMatrixSymPos = {}
            local checkSpecialWild = function(_node, _iCol, _iRow)
                if (_node and _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    table.insert(scatterLineValue.vecValidMatrixSymPos, {iY = _iCol, iX = _iRow})
                end
            end
            self:reelForeach(checkSpecialWild)
            scatterLineValue.iLineSymbolNum = #scatterLineValue.vecValidMatrixSymPos
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
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
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

--设置bonus scatter 信息  --解决快滚逻辑 不能和中奖预告一起播放
function CodeGameScreenPepperBlastMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
    --!!!此处插入特殊需求代码 ，快滚只在不播放中奖预告时播放
    if (nextReelLong and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
        -- local count = self:getSymbolCountByType(symbolType)
        -- nextReelLong = count < 3
        nextReelLong = not self.m_isPlayWinningNotice
    end

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column, row, runLen) == symbolType then
            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                --!!!此处插入特殊需求代码 ，快滚只在不播放中奖预告时播放
                if (nextReelLong and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    -- local count = self:getSymbolCountByType(symbolType)
                    -- nextReelLong = count < 3
                    nextReelLong = not self.m_isPlayWinningNotice
                end

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
    return allSpecicalSymbolNum, bRunLong
end

--消息返回判断播放 背景Spine动画
function CodeGameScreenPepperBlastMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    --添加标记
    local isTiriggerScatter = self:isTiriggerScatterEffect()
    local random_value = math.random(1, 3)
    self.m_isPlayWinningNotice = isTiriggerScatter and (1 == random_value)

    --期内含有快滚逻辑
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    if(self.m_isPlayWinningNotice)then
        self:playAheadJueseSpine(function()
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end)
    else
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end
end

-- --构造respin所需要的数据
-- @machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenPepperBlastMachine:reateRespinNodeInfo()
    --重写此接口是因为reSpin取基础盘面数据 不能拿服务器数据，应该拿消除后的盘面数据，因为可能出现特殊wild消除了原先的小块

    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型 --==========主要替换这个接口就可以
            local symbolType = self:getPepperBlastMatrixPosSymbolType(iRow, iCol)
            -- local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end
--获取消除玩法后棋盘上的信号值
function CodeGameScreenPepperBlastMachine:getPepperBlastMatrixPosSymbolType(iRow, iCol)
    local symbolType = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local finalReels = selfData and selfData.finalReels or {}
    --数据的行索引
    local data_iRow = 1 + (3 - iRow)

    --优先拿 服务器消除玩法后的数据列表
    if (#finalReels > 0) then
        --其次
        symbolType = finalReels[data_iRow][iCol]
    else
        local getCurSymbolTypeByPos = function(_node, _iCol, _iRow)
            if (_iCol == iCol and _iRow == iRow) then
                symbolType = _node and _node.p_symbolType or 0
                return true
            end
        end
        self:reelForeach(getCurSymbolTypeByPos)
    end

    return symbolType
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenPepperBlastMachine:setScatterDownScound( )

end

return CodeGameScreenPepperBlastMachine
