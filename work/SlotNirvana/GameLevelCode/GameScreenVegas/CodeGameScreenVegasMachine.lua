---
-- island li
-- 2019年1月26日
-- GameScreenVegasMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameScreenVegasMachine = class("GameScreenVegasMachine", BaseFastMachine)
local VegasSlotsNode = require "CodeVegasSrc.VegasSlotsNode"
GameScreenVegasMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

GameScreenVegasMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
GameScreenVegasMachine.SYMBOL_FIX_MINI = 101 --jackpot mini
GameScreenVegasMachine.SYMBOL_FIX_MINOR = 102 --jackpot minor
GameScreenVegasMachine.SYMBOL_FIX_MAJOR = 103 --jackpot major

GameScreenVegasMachine.SYMBOL_OPEN_DOOR_SYMBOL = 96
GameScreenVegasMachine.SYMBOL_OPEN_DOOR_LOCK_SYMBOL = 196

GameScreenVegasMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1

GameScreenVegasMachine.m_chipFly1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 19
GameScreenVegasMachine.m_chipFly2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20
GameScreenVegasMachine.m_chipFly3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 21
GameScreenVegasMachine.m_chipFly4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 22
GameScreenVegasMachine.m_chipFly5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 23
GameScreenVegasMachine.m_chipFly6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 24
GameScreenVegasMachine.m_chipFly7 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 25
GameScreenVegasMachine.m_chipFly8 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 26
GameScreenVegasMachine.m_chipFly9 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 27
--效果添加

GameScreenVegasMachine.OPEN_DOOR_TURN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 开门图标变成其他信号
GameScreenVegasMachine.OPEN_DOOR_LOCK_TURN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 开门图标锁定的信号展示
GameScreenVegasMachine.OPEN_DOOR_LOCK_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 开门图标锁定

GameScreenVegasMachine.m_LockOpenDoorList = {} -- suprFs锁定的图标
GameScreenVegasMachine.m_chipList = nil
GameScreenVegasMachine.m_playAnimIndex = 0
GameScreenVegasMachine.m_lightScore = 0

-- 构造函数
function GameScreenVegasMachine:ctor()
    BaseFastMachine.ctor(self)

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_bonusTrigger = false
    self.m_LockOpenDoorList = {}

    self.m_ScatterNum = 0
    self.m_chooseRepin = false
    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
end

function GameScreenVegasMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("VegasConfig.csv", "LevelVegasConfig.lua")
    self.m_configData:initMachine(self)
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function GameScreenVegasMachine:createSuperFsBar()
    self.m_SuperFsBar = util_createAnimation("Vegas_shoujitiao.csb")
    self:findChild("Node_shouji"):addChild(self.m_SuperFsBar)

    for i = 1, 10 do
        local point = util_createAnimation("Vegas_shoujitiao_dian.csb")
        self.m_SuperFsBar:findChild("Node_" .. i):addChild(point)
        self["m_SuperFsPoint_" .. i] = point
        point.m_reword = false
        point:runCsbAction("idleframe2")
    end
end

function GameScreenVegasMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar
    self:initRespinBar()

    self:initRespinWinView()

    self.m_jackPotBar = util_createView("CodeVegasSrc.VegasJackPotBarView", self)
    self:findChild("jackpot"):addChild(self.m_jackPotBar)

    self:runCsbAction("idle1")
    self:initTip()

    self:changeGameBg(1)

    self.m_RunDi = {}
    for i = 1, 5 do
        local longRunDi = util_createAnimation("WinFrameVegas_run_bg.csb")
        self:findChild("Node"):addChild(longRunDi, 1)
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_" .. (i - 1)):getPosition()))
        longRunDi:setVisible(false)
        table.insert(self.m_RunDi, longRunDi)
    end

    self:createSuperFsBar()

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 1
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 2
            elseif winRate > 3 then
                soundIndex = 3
                soundTime = 3
            end

            local soundName = "VegasSounds/sound_vegas_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end
function GameScreenVegasMachine:getBottomUINode()
    return "CodeVegasSrc.VegasBoottomNode"
end

--小块
function GameScreenVegasMachine:getBaseReelGridNode()
    return "CodeVegasSrc.VegasSlotsNode"
end

-- 断线重连
function GameScreenVegasMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_SuperFsBar:setVisible(false)
        self.m_jackPotBar:setVisible(false)
        self:changeGameBg(2)

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local fstype = fsExtraData.type -- 0 是普通 1 super
        if fstype then
            if fstype == 1 then -- 如果是superfree 就用带锁的csb
                self.m_bottomUI:showAverageBet()
                self:playOpenDoorLockInReel(nil, true)
            end
        end
    end
end

--初始freespin tips
function GameScreenVegasMachine:initFreeSpinBar()
    local node_bar = self:findChild("fscounter")
    self.m_baseFreeSpinBar = util_createView("CodeVegasSrc.VegasFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

function GameScreenVegasMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:runCsbAction("idle1")
    self.m_baseFreeSpinBar:setVisible(true)

    self.m_baseFreeSpinBar:findChild("normal_img"):setVisible(true)
    self.m_baseFreeSpinBar:findChild("super_img"):setVisible(false)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fstype = fsExtraData.type -- 0 是普通 1 super
    if fstype then
        if fstype == 1 then -- 如果是superfree
            self.m_baseFreeSpinBar:findChild("normal_img"):setVisible(false)
            self.m_baseFreeSpinBar:findChild("super_img"):setVisible(true)
        end
    end
end

function GameScreenVegasMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function GameScreenVegasMachine:initTip()
    local node = self:findChild("jushu")
    self.m_Tip = util_createView("CodeVegasSrc.VegasTip")
    node:addChild(self.m_Tip)
    release_print("initTip")
    self.m_Tip:showTip()
end

function GameScreenVegasMachine:initRespinBar()
    local node_bar = self:findChild("rscounter")
    self.m_baseReSpinBar = util_createView("CodeVegasSrc.VegasRespinBarView")
    node_bar:addChild(self.m_baseReSpinBar)
    util_setCsbVisible(self.m_baseReSpinBar, false)
    self.m_baseReSpinBar:setPosition(0, 0)
end

function GameScreenVegasMachine:initRespinWinView()
    local node_bar = self:findChild("rswinner")
    local pos = cc.p(node_bar:getPosition())
    self.m_RespinWin = util_createView("CodeVegasSrc.VegasRespinWinView")
    self.m_clipParent:addChild(self.m_RespinWin, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    self.m_RespinWin:setPosition(pos)
    util_setCsbVisible(self.m_RespinWin, false)
end

function GameScreenVegasMachine:showRespinWinView()
    util_setCsbVisible(self.m_RespinWin, true)
    self.m_jackPotBar:setVisible(false)
    self.m_RespinWin:updateRespinWinCoins(0)
end

function GameScreenVegasMachine:HideRespinWinView()
    util_setCsbVisible(self.m_RespinWin, false)
    self.m_jackPotBar:setVisible(true)
    self.m_RespinWin:updateRespinWinCoins(0)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenVegasMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Vegas"
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function GameScreenVegasMachine:getNetWorkModuleName()
    return "VegasV2"
end

-- 继承底层respinView
function GameScreenVegasMachine:getRespinView()
    return "CodeVegasSrc.VegasRespinView"
end
-- 继承底层respinNode
function GameScreenVegasMachine:getRespinNode()
    return "CodeVegasSrc.VegasRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenVegasMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return "Socre_Vegas_Feature"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_Vegas_FeatureMini"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_Vegas_FeatureMinor"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_Vegas_FeatureMajor"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_Vegas_1"
    elseif symbolType == self.SYMBOL_OPEN_DOOR_SYMBOL then
        return "Socre_Vegas_OpenSymbol"
    elseif symbolType == self.SYMBOL_OPEN_DOOR_LOCK_SYMBOL then
        return "Socre_Vegas_OpenSymbol_Lock"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Vegas_10"
    end

    if symbolType == self.m_chipFly1 then
        return "Socre_Vegas_Feature_tw_1"
    end
    if symbolType == self.m_chipFly2 then
        return "Socre_Vegas_Feature_tw_2"
    end
    if symbolType == self.m_chipFly3 then
        return "Socre_Vegas_Feature_tw_3"
    end
    if symbolType == self.m_chipFly4 then
        return "Socre_Vegas_Feature_tw_4"
    end
    if symbolType == self.m_chipFly5 then
        return "Socre_Vegas_Feature_tw_5"
    end
    if symbolType == self.m_chipFly6 then
        return "Socre_Vegas_Feature_tw_6"
    end
    if symbolType == self.m_chipFly7 then
        return "Socre_Vegas_Feature_tw_7"
    end
    if symbolType == self.m_chipFly8 then
        return "Socre_Vegas_Feature_tw_8"
    end
    if symbolType == self.m_chipFly9 then
        return "Socre_Vegas_Feature_tw_9"
    end

    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function GameScreenVegasMachine:getReSpinSymbolScore(id)
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
    end

    return score
end

function GameScreenVegasMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给respin小块进行赋值
function GameScreenVegasMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --     symbolNode:runAnim("idle", true)
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
                symbolNode:runAnim("idleframe")
            end
        end
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
                if symbolNode then
                    if symbolNode:getCcbProperty("m_lb_score") then
                        symbolNode:getCcbProperty("m_lb_score"):setString(score)
                    end
                end
            end
        end
    end
end

function GameScreenVegasMachine:createOneActionSymbol(endNode, actionName)
    if not endNode or not endNode.m_ccbName then
        return
    end

    local fatherNode = endNode
    endNode:setVisible(false)

    local node = util_createAnimation(endNode.m_ccbName .. ".csb")
    local func = function()
        if fatherNode then
            fatherNode:setVisible(true)
        end
        if node then
            node:removeFromParent()
        end
    end
    node:playAction(actionName, true, func)

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("Node_2"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("Node_2"):addChild(node, 100000 + endNode.p_rowIndex)
    node:setPosition(pos)

    local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local symbolIndex = self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
    local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
    local index = 0
    if score ~= nil and type(score) ~= "string" then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        score = util_formatCoins(score, 3)
        local scoreNode = node:findChild("m_lb_score")
        if scoreNode then
            scoreNode:setString(score)
        end
    end

    return node
end
--设置bonus scatter 层级
function GameScreenVegasMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
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
function GameScreenVegasMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {node})
        self:runAction(callFun)
    end

    return node
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameScreenVegasMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINI, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly6, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly7, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly8, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly9, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_OPEN_DOOR_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_OPEN_DOOR_LOCK_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function GameScreenVegasMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function GameScreenVegasMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then

        self:playReelDownSound(reelCol,self.m_reelDownSound )

    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end

   

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    for iRow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]

        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self:getCurrSpinMode() ~= RESPIN_MODE then
                if (self.m_ScatterNum == 0 and reelCol >= 4) or (self.m_ScatterNum == 1 and reelCol == 5) then
                    --不播了
                else
                    local targSp = self:setScatterSymbolToClipReel(reelCol, iRow, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                    if targSp then
                        self.m_ScatterNum = self.m_ScatterNum + 1
                        targSp:runAnim(
                            "buling",
                            false,
                            function()
                                targSp:resetReelStatus()
                            end
                        )

                        local soundPath = nil

                        if self.m_ScatterNum == 1 then
                            soundPath = "VegasSounds/sound_vegas_scatter1.mp3"
                        elseif self.m_ScatterNum == 2 then
                            soundPath = "VegasSounds/sound_vegas_scatter2.mp3"
                        elseif self.m_ScatterNum >= 3 then
                            soundPath = "VegasSounds/sound_vegas_scatter3.mp3"
                        end

                        if soundPath then
                            if self.playBulingSymbolSounds then
                                self:playBulingSymbolSounds( reelCol,soundPath,TAG_SYMBOL_TYPE.SYMBOL_SCATTER )
                            else
                                gLobalSoundManager:playSound(soundPath)
                            end
                        end
                    end
                end
            end
        elseif symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR then
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                targSp:runAnim(
                    "buling1",
                    false,
                    function()
                        targSp:runAnim("idle2", true)
                    end
                )
                gLobalSoundManager:playSound("VegasSounds/sound_vegas_base_link_ground.mp3")
            end
        end
    end

    local isplay = true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true and isplay then
            isplay = false
        -- respinbonus落地音效
        -- gLobalSoundManager:playSound("VegasSounds/music_Vegas_fall_" .. reelCol ..".mp3")
        end
    end
    if reelCol > 2 then
        local rundi = self.m_RunDi[reelCol]
        if rundi:isVisible() then
            util_playFadeOutAction(
                rundi,
                0.3,
                function()
                    rundi:setVisible(false)
                end
            )
        end
    end
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

--添加金边
function GameScreenVegasMachine:creatReelRunAnimation(col)
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

    if col > 2 then
        local rundi = self.m_RunDi[col]
        if rundi then
            rundi:setVisible(true)
            util_setCascadeOpacityEnabledRescursion(rundi, true)
            rundi:setOpacity(0)
            util_playFadeInAction(rundi, 0.3)
        end
    end
    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode, true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode, 0.1)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function GameScreenVegasMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 动画触发
--改变背景动画等
function GameScreenVegasMachine:levelFreeSpinOverChangeEffect()
end
---------------------------------------------------------------------------

function GameScreenVegasMachine:setScatterSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        -- targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function GameScreenVegasMachine:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode == nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            -- slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode:runAnim("actionframe")

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

---
-- 显示free spin
function GameScreenVegasMachine:showEffect_FreeSpin(effectData)
    self.isInBonus = true

    return BaseFastMachine.showEffect_FreeSpin(self, effectData)
end

-- 触发freespin时调用
function GameScreenVegasMachine:showFreeSpinView(effectData)
    local delayTime = 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        delayTime = 1.5
    end
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("VegasSounds/sound_vegas_bonus_start.mp3")

            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self:showOneFsBarPointReword(
                function()
                    gLobalSoundManager:playSound("VegasSounds/sound_vegas_bonus_start.mp3")

                    self:showFreeSpinStart(
                        self.m_iFreeSpinTimes,
                        function()
                            self.m_jackPotBar:setVisible(false)
                            self.m_SuperFsBar:setVisible(false)

                            self:changeGameBg(2)
                            self:triggerFreeSpinCallFun()

                            self:runCsbAction("idle3")

                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        delayTime
    )
end

function GameScreenVegasMachine:showFreeSpinStart(num, func)
    local data = {}
    data.num = num
    data.csbname = "Vegas/FreeSpinStart.csb"
    -- freespin的 开门玩法
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fstype = fsExtraData.type -- 0 是普通 1 super
    if fstype then
        if fstype == 1 then
            data.csbname = "Vegas/SuperFreeSpinStart.csb"

            self.m_bottomUI:showAverageBet()
        end
    end

    local freeStartView = util_createView("CodeVegasSrc.VegasFreespinStartView", data)
    freeStartView:setFunCall(
        function()
            if func then
                func()
            end
        end
    )
    gLobalViewManager:showUI(freeStartView, ViewZorder.ZORDER_UI)

    -- return self:showVegasDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
end

function GameScreenVegasMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

--添加到 轮盘节点上 适配
function GameScreenVegasMachine:showVegasDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 触发freespin结束时调用
function GameScreenVegasMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("VegasSounds/sound_vegas_tip_over.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self.m_SuperFsBar:setVisible(true)
            self.m_jackPotBar:setVisible(true)
            -- 调用此函数才是把当前游戏置为freespin结束状态
            self:triggerFreeSpinOverCallFun()
            self:changeGameBg(4)
            self:runCsbAction("idle1")

            self:removeAllLockOpenDoor()

            local csbname = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
            -- freespin的 开门玩法
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
            local fstype = fsExtraData.type -- 0 是普通 1 super
            if fstype then
                if fstype == 1 then
                    self.m_bottomUI:hideAverageBet()
                    self:restAllFsBarPointReword()
                else
                    self:initFsBarPoint()
                end
            end
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 720)
end

function GameScreenVegasMachine:showFreeSpinOver(coins, num, func)
    local csbname = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    -- freespin的 开门玩法
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fstype = fsExtraData.type -- 0 是普通 1 super
    if fstype then
        if fstype == 1 then
            csbname = "SuperFreeSpinOver"
        end
    end

    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function GameScreenVegasMachine:showRespinJackpot(index, coins, func)
    gLobalSoundManager:playSound("VegasSounds/sound_vegas_jackpot_start.mp3")
    local jackPotWinView = util_createView("CodeVegasSrc.VegasJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self, index, coins, func)
end

-- 结束respin收集
function GameScreenVegasMachine:playLightEffectEnd()
    -- 通知respin结束
    self:respinOver()
end

function GameScreenVegasMachine:respinOver()
    self:setReelSlotsNodeVisible(true)
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:removeRespinNode()
    self:showRespinOverView()
end

--结束移除小块调用结算特效
function GameScreenVegasMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        local endAnimaName, loop = node:getSlotsNodeAnima()
        --respin结束 移除respin小块对应位置滚轴中的小块
        self:checkRemoveReelNode(node)
        --respin结束 把respin小块放回对应滚轴位置
        self:checkChangeRespinFixNode(node)
        --播放respin放回滚轴后播放的提示动画
        self:checkRespinChangeOverTip(node)
    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end

function GameScreenVegasMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        -- 此处跳出迭代
        self:playLightEffectEnd()
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(), chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)
    local startPos = cc.p(self:findChild("startNode"):getPosition())
    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol

    -- 根据网络数据获得当前固定小块的分数
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()

    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self:BaseMania_getJackpotScore(1)
            addScore = jackpotScore + addScore
            nJackpotType = 4
        elseif score == "MAJOR" then
            jackpotScore = self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINOR" then
            jackpotScore = self:BaseMania_getJackpotScore(3)
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "MINI" then
            jackpotScore = self:BaseMania_getJackpotScore(4)
            addScore = jackpotScore + addScore
            nJackpotType = 1
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim()
        else
            self:showRespinJackpot(
                nJackpotType,
                jackpotScore,
                function()
                    self.m_playAnimIndex = self.m_playAnimIndex + 1
                    self:playChipCollectAnim()
                end
            )
        end
    end
    -- 添加飞行轨迹
    local function lightFly()
        -- gLobalSoundManager:playSound("VegasSounds/sound_vegas_fly_light.mp3")
        gLobalSoundManager:playSound("VegasSounds/sound_vegas_boom.mp3")
        scheduler.performWithDelayGlobal(
            function()
                runCollect()

                self.m_RespinWin:updateRespinWinCoins(self.m_lightScore)
                self.m_RespinWin:playWinEffect()
            end,
            0.4,
            self:getModuleName()
        )
    end

    chipNode:runAnim("actionframe")
    lightFly()
end

--结束移除小块调用结算特效
function GameScreenVegasMachine:reSpinEndAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    util_setCsbVisible(self.m_baseReSpinBar, false)
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    self:showRespinWinView()

    if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum) then
        -- 如果全部都固定了，会中JackPot档位中的Grand
        local jackpotScore = self:BaseMania_getJackpotScore(1)
        self.m_lightScore = self.m_lightScore + jackpotScore
        self:showRespinJackpot(
            4,
            jackpotScore,
            function()
                self.m_RespinWin:updateRespinWinCoins(self.m_lightScore)
                self:playChipCollectAnim()
            end
        )
    else
        self:playChipCollectAnim()
    end
end

-- 根据本关卡实际小块数量填写
function GameScreenVegasMachine:getRespinRandomTypes()
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
        self.SYMBOL_FIX_MAJOR,
        self.SYMBOL_FIX_MINOR,
        self.SYMBOL_FIX_MINI,
        self.SYMBOL_FIX_SYMBOL
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function GameScreenVegasMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true}
    }
    return symbolList
end

---
-- 触发respin 玩法
--
function GameScreenVegasMachine:showEffect_Respin(effectData)
    self.isInBonus = true

    return BaseFastMachine.showEffect_Respin(self, effectData)
end

function GameScreenVegasMachine:showRespinView(effectData)
    --先播放动画 再进入respin
    self:clearCurMusicBg()
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()
    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()
    self.m_effectData = effectData

    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)
end

--触发respin
function GameScreenVegasMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function GameScreenVegasMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()

            gLobalSoundManager:playSound("VegasSounds/sound_vages_respin_start.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    self:showReSpinStart(
                        function()
                            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                            -- 更改respin 状态下的背景音乐
                            self:changeReSpinBgMusic()
                            self:runNextReSpinReel()
                            self:changeGameBg(3)
                            -- self:runCsbAction("animation1")
                            local respinViewLine = util_createView("CodeVegasSrc.VegasRespinLine")
                            self.m_respinView:addChild(respinViewLine, REEL_SYMBOL_ORDER.REEL_ORDER_2 - 100)
                            respinViewLine:runCsbAction("animation0")
                            respinViewLine:setPositionY(-50)
                            self.m_respinView:getFirstNode()
                            self.m_respinView:allPlayIdle()
                        end
                    )
                end,
                3,
                self:getModuleName()
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    -- print("移除 scatter")
                    targSp:removeFromParent()
                    self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
                end
            end
        end
    end
end

function GameScreenVegasMachine:showReSpinStart(func)
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("VegasSounds/sound_vegas_bonus_start.mp3")
    local bonusView = util_createView("CodeVegasSrc.VegasRespinStartView")
    bonusView:setFunCall(
        function()
            self.m_SuperFsBar:setVisible(false)
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinsTotalCount)

            if func then
                func()
            end
        end
    )
    gLobalViewManager:showUI(bonusView, ViewZorder.ZORDER_UI)
end

function GameScreenVegasMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_baseReSpinBar, true)
    self.m_baseReSpinBar:showRespinBar(respinCount)
end

--ReSpin刷新数量
function GameScreenVegasMachine:changeReSpinUpdateUI(curCount)
    self.m_baseReSpinBar:updateLeftCount(curCount, false)
end

--ReSpin结算改变UI状态
function GameScreenVegasMachine:changeReSpinOverUI()
    -- util_setCsbVisible(self.m_baseReSpinBar, false)
end

function GameScreenVegasMachine:showRespinOverView(effectData)
    local strCoins = util_formatCoins(self.m_serverWinCoins, 50)
    local view =
        self:showReSpinOver(
        strCoins,
        function()
            self.m_SuperFsBar:setVisible(true)
            self:changeGameBg(5)
            -- self:runCsbAction("animation1")
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg()
            self:HideRespinWinView()
        end
    )
    gLobalSoundManager:playSound("VegasSounds/sound_vegas_tip_over.mp3")
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 720)
end

-- --重写组织respinData信息
function GameScreenVegasMachine:getRespinSpinData()
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
function GameScreenVegasMachine:MachineRule_SpinBtnCall()
    self.isInBonus = false

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:setMaxMusicBGVolume()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_gameBg:runCsbAction("freespin", true)
    end
    self.m_ScatterNum = 0

    self:closeLockOpenDoor()

    return false -- 用作延时点击spin调用
end

function GameScreenVegasMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("VegasSounds/sound_vegas_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.isInBonus then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    end
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function GameScreenVegasMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self:initFsBarPoint()
end

function GameScreenVegasMachine:addObservers()
    BaseFastMachine.addObservers(self)
end

function GameScreenVegasMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

-- 重写 getSlotNodeBySymbolType 方法
function GameScreenVegasMachine:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
    local reelNode = BaseFastMachine.getSlotNodeWithPosAndType(self, symbolType, iRow, iCol, isLastSymbol)

    if self:getCurrSpinMode() == RESPIN_MODE then
        if symbolType == self.SYMBOL_FIX_SYMBOL then
            self:setSpecialNodeScore(nil, {reelNode})
        end
    end
    return reelNode
end

---
-- 添加关卡中触发的玩法
--
function GameScreenVegasMachine:addSelfEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- freespin的 开门玩法
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local fstype = fsExtraData.type -- 0 是普通
        if fstype then
            if fstype == 0 then
                -- 开门图标变成其他信号
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.OPEN_DOOR_TURN_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.OPEN_DOOR_TURN_EFFECT -- 动画类型
            else
                -- superFs开门图标固定信号
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.OPEN_DOOR_LOCK_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.OPEN_DOOR_LOCK_EFFECT -- 动画类型

                -- 开门图标变成其他信号
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.OPEN_DOOR_LOCK_TURN_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.OPEN_DOOR_LOCK_TURN_EFFECT -- 动画类型
            end
        end
    end
end

function GameScreenVegasMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        if self.m_bProduceSlots_InFreeSpin == false then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
        end
    end
    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
    end
    --触发 bonus 大赢不触发
    local hasBonusEffect = self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    if hasBonusEffect == true then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function GameScreenVegasMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.OPEN_DOOR_TURN_EFFECT then
        self:playOpenDoorTurn(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    elseif effectData.p_selfEffectType == self.OPEN_DOOR_LOCK_EFFECT then
        self:playOpenDoorLockInReel(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    elseif effectData.p_selfEffectType == self.OPEN_DOOR_LOCK_TURN_EFFECT then
        self:playOpenDoorLockTurnInReel(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function GameScreenVegasMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function GameScreenVegasMachine:checkPosInLine(pos)
    for i = 1, #self.m_runSpinResultData.p_winLines do
        local winLine = self.m_runSpinResultData.p_winLines[i]
        for j = 1, #winLine.p_iconPos do
            local posInLine = self:getRowAndColByPos(winLine.p_iconPos[j])
            if posInLine.iX == pos.iX and posInLine.iY == pos.iY then
                return true
            end
        end
    end
    return false
end

function GameScreenVegasMachine:MachineRule_network_InterveneSymbolMap()
end

function GameScreenVegasMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    BaseFastMachine.slotReelDown(self)
end
--
function GameScreenVegasMachine:changeGameBg(_type)
    if _type == 1 then
        self.m_gameBg:runCsbAction("normal", true)
        self.m_Tip:setVisible(true)
        self.m_Tip:showTip()
    elseif _type == 2 then
        self.m_gameBg:runCsbAction(
            "normal_freespin",
            false,
            function()
                self.m_gameBg:runCsbAction("freespin", true)
            end
        )
        self.m_Tip:HideTip()
    elseif _type == 3 then
        self.m_gameBg:runCsbAction(
            "normal_respin",
            false,
            function()
                self.m_gameBg:runCsbAction("respin", true)
            end
        )
        self.m_Tip:HideTip()
    elseif _type == 4 then
        self.m_gameBg:runCsbAction(
            "freespin_normal",
            false,
            function()
                self.m_gameBg:runCsbAction("normal", true)
            end
        )
        self.m_Tip:setVisible(true)
        self.m_Tip:showTip()
    elseif _type == 5 then
        self.m_gameBg:runCsbAction(
            "respin_normal",
            false,
            function()
                self.m_gameBg:runCsbAction("normal", true)
            end
        )
        self.m_Tip:setVisible(true)
        self.m_Tip:showTip()
    end
end

function GameScreenVegasMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue then
        -- 关卡特殊处理 不显示scatter赢钱线动画
        if lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            -- print("scatter")
        else
            BaseFastMachine.showLineFrameByIndex(self, winLines, frameIndex)
        end
    end
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function GameScreenVegasMachine:getResNodeSymbolType(parentData)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end
    if
        symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR or
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
     then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8
    end
    return symbolType
end

--respin结束 移除respin小块对应位置滚轴中的小块
function GameScreenVegasMachine:checkRemoveReelNode(node)
    local targSp = self:getReelParent(node.p_cloumnIndex):getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    local slotParentBig = self:getReelBigParent(node.p_cloumnIndex)
    if targSp == nil and slotParentBig then
        targSp = slotParentBig:getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    end
    if targSp == nil then
        --找不到 提层级了
        targSp = self:getFixSymbol(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG)
    end
    if targSp then
        targSp:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
    end
end
--播放respin放回滚轴后播放的提示动画
function GameScreenVegasMachine:checkRespinChangeOverTip(node, endAnimaName, loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
end

function GameScreenVegasMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    BaseFastMachine.playEffectNotifyNextSpinCall(self)
end

function GameScreenVegasMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        local ReelParent = self:getReelParent(iCol)
        if ReelParent then
            ReelParent:setVisible(status)
        end
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then
            slotParentBig:setVisible(status)
        end
    end

    -- --如果为空则从 clipnode获取
    -- local childs = self.m_clipParent:getChildren()
    -- local childCount = #childs
    -- self.m_clipParent:setVisible(status)
end

-- 开门图标变成其他信号
function GameScreenVegasMachine:playOpenDoorTurn(func)
    -- 找到所有开门图标
    local OpenDoorSymbolList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_OPEN_DOOR_SYMBOL then
                table.insert(OpenDoorSymbolList, slotNode)
            end
        end
    end

    -- 没有在轮盘找到开门图标，那就直接结束
    if #OpenDoorSymbolList == 0 then
        if func then
            func()
        end

        return
    end

    gLobalSoundManager:playSound("VegasSounds/VegasSounds_openDoor.mp3")

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local symbolType = fsExtraData.mysteryToSignal -- 0 是普通

    for i = 1, #OpenDoorSymbolList do
        local symbolNode = OpenDoorSymbolList[i]
        local currParent = symbolNode:getParent()
        local pos = cc.p(symbolNode:getPosition())
        local isLock = false
        local actNode = self:createOneSymbolActNode(pos, currParent, isLock)

        if self:getSymbolCCBNameByType(self, symbolType) == symbolNode.m_ccbName then
            symbolNode.m_ccbName = ""
        end
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
        if symbolNode.p_symbolImage ~= nil then
            symbolNode.p_symbolImage:removeFromParent()
            symbolNode.p_symbolImage = nil
        end

        if i == #OpenDoorSymbolList then
            actNode:runCsbAction(
                "open",
                false,
                function()
                    actNode:removeFromParent()
                    if func then
                        func()
                    end
                end
            )
        else
            actNode:runCsbAction(
                "open",
                false,
                function()
                    actNode:removeFromParent()
                end
            )
        end
    end
end

--------------
----------
-------
----
-- 自定义动画

function GameScreenVegasMachine:createOneSymbolActNode(pos, currParent, isLock, isBig)
    local currName = "Socre_Vegas_OpenSymbol.csb"
    if isLock then
        currName = "Socre_Vegas_OpenSymbol_Lock.csb"
    elseif isBig then
        currName = "Socre_Vegas_OpenSymbol_Lock_Big.csb"
    end

    local targSp = util_createAnimation(currName)

    currParent:addChild(targSp, REEL_SYMBOL_ORDER.REEL_ORDER_4)
    targSp:setPosition(cc.p(pos))

    return targSp
end

function GameScreenVegasMachine:playOpenDoorLockTurnInReel(func)
    if #self.m_LockOpenDoorList == 0 then
        if func then
            func()
        end

        return
    end

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local symbolType = fsExtraData.mysteryToSignal
    local mysteryPositions = fsExtraData.mysteryPositions or 0

    local playOneLockSymbol = function(index)
        local fixPos = self:getRowAndColByPos(index)
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            if self:getSymbolCCBNameByType(self, symbolType) == symbolNode.m_ccbName then
                symbolNode.m_ccbName = ""
            end
            symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
            if symbolNode.p_symbolImage ~= nil then
                symbolNode.p_symbolImage:removeFromParent()
                symbolNode.p_symbolImage = nil
            end
        end
    end

    gLobalSoundManager:playSound("VegasSounds/VegasSounds_openDoor.mp3")

    for i = 1, #self.m_LockOpenDoorList do
        local actNode = self.m_LockOpenDoorList[i]
        local index = actNode.index
        local isAll = actNode.isAll

        if i == #self.m_LockOpenDoorList then
            actNode:runCsbAction(
                "open",
                false,
                function()
                    if func then
                        func()
                    end
                end
            )
        else
            actNode:runCsbAction(
                "open",
                false,
                function()
                end
            )
        end

        -- 更新小块显示
        if isAll then
            -- 如果是全锁定状态
            for i = 1, (self.m_iReelRowNum * self.m_iReelColumnNum) do
                local index = i - 1
                playOneLockSymbol(index)
            end

            break
        else
            playOneLockSymbol(index)
        end
    end
end

function GameScreenVegasMachine:checkIsInLockOpenDoorList(posIndex)
    for i = 1, #self.m_LockOpenDoorList do
        local node = self.m_LockOpenDoorList[i]
        if node.index and node.index == posIndex then
            return true
        end
    end

    return false
end

function GameScreenVegasMachine:closeLockOpenDoor()
    local isCloseAni = false

    for i = 1, #self.m_LockOpenDoorList do
        local actNode = self.m_LockOpenDoorList[i]

        if actNode.isInitOut then
            actNode.isInitOut = nil
        else
            if actNode then
                isCloseAni = true
                actNode:runCsbAction(
                    "close",
                    false,
                    function()
                    end
                )
            end
        end
    end

    if isCloseAni then
        gLobalSoundManager:playSound("VegasSounds/VegasSounds_CloseDoor.mp3")
    end
end

function GameScreenVegasMachine:playOpenDoorLockInReel(func, isInit)
    local csbActName = "lock"
    if isInit then
        csbActName = "idleframe"
    end

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local symbolType = fsExtraData.mysteryToSignal
    local mysteryPositions = fsExtraData.mysteryPositions or {1, 2, 3, 4, 5, 6}

    -- 移除掉已经添加上的
    for i = #mysteryPositions, 1, -1 do
        local posIndex = mysteryPositions[i]

        if self:checkIsInLockOpenDoorList(posIndex) then
            table.remove(mysteryPositions, i)
        end
    end

    local isReturn = false

    if #mysteryPositions == 0 then
        isReturn = true
    end

    -- 如果有大块了就不在新固定了
    for i = 1, #self.m_LockOpenDoorList do
        local lockSymbol = self.m_LockOpenDoorList[i]
        if lockSymbol then
            if lockSymbol.isAll then
                isReturn = true

                break
            end
        end
    end

    -- 没有在轮盘找到开门图标，那就直接结束
    if isReturn then
        if func then
            func()
        end

        return
    end

    local currFunc = function()
        if #self.m_LockOpenDoorList == (self.m_iReelColumnNum * self.m_iReelRowNum) then
            -- 创建
            local index = 7
            local fixPos = self:getRowAndColByPos(index)
            local currParent = self.m_clipParent
            local pos = cc.p(util_getOneGameReelsTarSpPos(self, index))
            local isbig = true
            local actNode_light = util_createAnimation("Socre_Vegas_OpenSymbol_Lock_ToBig.csb")
            currParent:addChild(actNode_light, REEL_SYMBOL_ORDER.REEL_ORDER_4 + 110)
            actNode_light:setPosition(cc.p(pos))
            local particle = actNode_light:findChild("Particle_1")
            if particle then
                particle:resetSystem()
            end
            actNode_light:runCsbAction(
                "actionframe",
                false,
                function()
                    actNode_light:removeFromParent()
                end
            )
            local actNode = self:createOneSymbolActNode(pos, currParent, nil, isbig)
            actNode.index = index
            actNode.isAll = true
            if isInit then
                actNode.isInitOut = true
            end
            actNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)

            if isInit then
                for i = 1, #self.m_LockOpenDoorList do
                    local lockSymbol = self.m_LockOpenDoorList[i]
                    if lockSymbol then
                        lockSymbol:removeFromParent()
                    end
                end

                self.m_LockOpenDoorList = {}

                table.insert(self.m_LockOpenDoorList, actNode)
                actNode:runCsbAction(
                    csbActName,
                    false,
                    function()
                        if func then
                            func()
                        end
                    end
                )
            else
                actNode:runCsbAction("actionframe", false)
                local particle = actNode:findChild("Particle_1")
                if particle then
                    particle:resetSystem()
                end
                actNode:runCsbAction(
                    "lock",
                    false,
                    function()
                        for i = 1, #self.m_LockOpenDoorList do
                            local lockSymbol = self.m_LockOpenDoorList[i]
                            if lockSymbol then
                                lockSymbol:removeFromParent()
                            end
                        end

                        self.m_LockOpenDoorList = {}

                        table.insert(self.m_LockOpenDoorList, actNode)

                        if func then
                            func()
                        end
                    end
                )
            end
        else
            if func then
                func()
            end
        end
    end

    for i = 1, #mysteryPositions do
        local index = mysteryPositions[i]
        local fixPos = self:getRowAndColByPos(index)
        local currParent = self.m_clipParent
        local pos = cc.p(util_getOneGameReelsTarSpPos(self, index))
        local isLock = true
        local actNode = self:createOneSymbolActNode(pos, currParent, isLock)
        actNode.index = index
        if isInit then
            actNode.isInitOut = true
        end

        actNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100 - index)
        table.insert(self.m_LockOpenDoorList, actNode)

        if i == #mysteryPositions then
            actNode:runCsbAction(
                csbActName,
                false,
                function()
                    if currFunc then
                        currFunc()
                    end
                end
            )
        else
            actNode:runCsbAction(csbActName)
        end
    end
end

function GameScreenVegasMachine:removeAllLockOpenDoor()
    for i = 1, #self.m_LockOpenDoorList do
        local node = self.m_LockOpenDoorList[i]
        if node then
            node:removeFromParent()
        end
    end
    self.m_LockOpenDoorList = {}
end

function GameScreenVegasMachine:initFsBarPoint()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local totalFsBarPoint = selfdata.totalFreespinCount
    local rewordFsBarPoint = selfdata.freespinCount

    if rewordFsBarPoint then
        for i = 1, 10 do
            if i <= rewordFsBarPoint then
                local point = self["m_SuperFsPoint_" .. i]
                if point then
                    point.m_reword = true
                    point:runCsbAction("idleframe")
                end
            end
        end
    end
end

function GameScreenVegasMachine:showOneFsBarPointReword(func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local totalFsBarPoint = selfdata.totalFreespinCount
    local rewordFsBarPoint = selfdata.freespinCount

    local waitTime = 0
    local pointRewordNum = 0
    for i = 1, 10 do
        local point = self["m_SuperFsPoint_" .. i]
        if point and point.m_reword == true then
            pointRewordNum = pointRewordNum + 1
        end
    end

    if pointRewordNum < rewordFsBarPoint then
        for i = 1, 10 do
            local point = self["m_SuperFsPoint_" .. i]
            if point and point.m_reword == false then
                point:setVisible(true)
                point.m_reword = true
                if i == 10 then
                    point:runCsbAction("shouji2")
                else
                    point:runCsbAction("shouji")
                end
                waitTime = (21 + 30) / 30 -- 播放完 延迟一秒

                break
            end
        end
    end

    if waitTime > 0 then
        gLobalSoundManager:playSound("VegasSounds/VegasSounds_CollectFSPoints.mp3")
    end

    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        waitTime
    )
end

function GameScreenVegasMachine:restAllFsBarPointReword()
    for i = 1, 10 do
        local point = self["m_SuperFsPoint_" .. i]
        if point then
            point.m_reword = false
            point:runCsbAction("idleframe2")
        end
    end
end

function GameScreenVegasMachine:beginReel()
    self.m_fsReelDataIndex = 0
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fstype = fsExtraData.type -- 0 是普通 1 super
    if fstype then
        if fstype == 1 then -- 如果是superfree 就用带锁的csb
            self.m_fsReelDataIndex = 1
        end
    end

    BaseFastMachine.beginReel(self)
end

return GameScreenVegasMachine
