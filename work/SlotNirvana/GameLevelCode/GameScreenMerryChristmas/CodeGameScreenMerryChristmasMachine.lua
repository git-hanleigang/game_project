---
-- island li
-- 2019年1月26日
-- CodeGameScreenMerryChristmasMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SendDataManager = require "network.SendDataManager"
local CodeGameScreenMerryChristmasMachine = class("CodeGameScreenMerryChristmasMachine", BaseNewReelMachine)

CodeGameScreenMerryChristmasMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMerryChristmasMachine.SYMBOL_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 自定义的小块类型
CodeGameScreenMerryChristmasMachine.SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenMerryChristmasMachine.SYMBOL_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3

--Classicl 信号块对应的id
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_2X = 192
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_3X = 193
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_5X = 195
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_Red7 = 100
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_Blue7 = 101
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_Bar1 = 104
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_Bar2 = 103
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_Bar3 = 102
CodeGameScreenMerryChristmasMachine.SYMBOL_Classicl_None = 999

CodeGameScreenMerryChristmasMachine.FS_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

-- 构造函数
function CodeGameScreenMerryChristmasMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_ScatterAndReel = {}
    self.m_collectScatterEffectTimes = 0
    --init
    self.isInBonus = false
    self.m_iBonusWinCoins = 0
    self.m_FsDownTimes = 0
    self.m_bCollectMax = false --是否收集到最大数量
    self.m_spinRestMusicBG = true
    self.m_isFeatureOverBigWinInFree = true
    
    self:initGame()
end

function CodeGameScreenMerryChristmasMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMerryChristmasMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MerryChristmas"
end

function CodeGameScreenMerryChristmasMachine:getBaseReelGridNode()
    return "CodeMerryChristmasSrc.MerryChristmasSlotsNode"
end

function CodeGameScreenMerryChristmasMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_jackpotbar = util_createView("CodeMerryChristmasSrc.MerryChristmasJackPotBarView")
    self.m_jackpotbar:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotbar)

    self.m_fsCollect = util_createView("CodeMerryChristmasSrc.MerryChristmasFsCollect")
    self:findChild("Node_fs_tishitiao"):addChild(self.m_fsCollect)
    self.m_fsCollect:setVisible(false)

    self.m_tree = util_createView("CodeMerryChristmasSrc.MerryChristmasTree")
    self:findChild("Node_shu"):addChild(self.m_tree)

    -- 创建过场
    self.m_guochang = util_createAnimation("MerryChristmasGuoChang.csb")
    self:addChild(self.m_guochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_guochang:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang:setVisible(false)

    self.m_guochang2 = util_spineCreate("MerryChristmas_guochang", true, true)
    self:addChild(self.m_guochang2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 2)
    self.m_guochang2:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang2:setVisible(false)
    self:runCsbAction("deng_man", true)
    self:showMaskLayer()
    self.m_MaskLayer:setVisible(false)

    self:initFsMiniMachine()
end

function CodeGameScreenMerryChristmasMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self.m_bottomUI:findChild("node_bar")
        self.m_baseFreeSpinBar = util_createView("CodeMerryChristmasSrc.MerryChristmasFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_baseFreeSpinBar:setPosition(0, 25)
        self.m_baseFreeSpinBar:setScale(0.6)
    end
end

function CodeGameScreenMerryChristmasMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_enter.mp3")
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenMerryChristmasMachine:getFsCollectNode()
    return self.m_fsCollect:getCollectNode()
end

function CodeGameScreenMerryChristmasMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()

    if globalData.slotRunData.isPortrait == true then
        mainScale = wScale
        util_csbScale(self.m_machineNode, wScale)
    else
        mainScale = hScale
        local ratio = display.height / display.width
        if ratio >= 768 / 1024 then
            mainScale = 0.85
        elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
            mainScale = 0.90 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end
end

function CodeGameScreenMerryChristmasMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenMerryChristmasMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin or self.isInBonus then
                return
            end
            self:stopLinesWinSound()
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

            local soundName = "MerryChristmasSounds/sound_MerryChristmas_win" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, 3, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenMerryChristmasMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMerryChristmasMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_MerryChristmas_bonus1"
    elseif symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_MerryChristmas_bonus2"
    elseif symbolType == self.SYMBOL_BONUS_3 then
        return "Socre_MerryChristmas_bonus3"
    end
    return nil
end

----------------------------- 玩法处理 -----------------------------------
-- 断线重连
function CodeGameScreenMerryChristmasMachine:MachineRule_initGame(initSpinData)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- local fsTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
        local count = initSpinData.p_fsExtraData.reelCount
        self.m_ScatterAndReel = initSpinData.p_fsExtraData.scatterAndReel
        self:sortScatterAndReelData()
        self:showFsMiniMachine(count)
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData then
            local count = selfData.freeGameTriggerCount
            if count == 5 or count == 10 or count == 20 then
                self.m_bottomUI:showAverageBet()
            end
        end
    end
    self:updataOpenTree(true)
end

--收集scatter 对应的轮盘数 从服务器获取数据后重新排序
function CodeGameScreenMerryChristmasMachine:sortScatterAndReelData()
    local data = {}
    for k, v in pairs(self.m_ScatterAndReel) do
        local dataInfo = {}
        dataInfo.reelNum = tonumber(v)
        dataInfo.needNum = tonumber(k)
        table.insert(data, dataInfo)
    end
    table.sort(
        data,
        function(a, b)
            return a.reelNum < b.reelNum
        end
    )
    self.m_ScatterAndReel = data
end

--刷新圣诞树的收集个数
function CodeGameScreenMerryChristmasMachine:updataOpenTree(_bReconnet)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        local count = selfData.freeGameTriggerCount
        if _bReconnet then
            if self.m_bProduceSlots_InFreeSpin == true then
                if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                    count = count - 1
                end
            end
            self.m_tree:initReconnetUI(count)
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                if count == 20 then
                    self.m_tree:playTreeOver()
                end
            end
        else
            self.m_tree:updataOpenBoxNum(count)
        end
    end
end
--
--单列滚动停止回调
--
function CodeGameScreenMerryChristmasMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self, reelCol)
    for iRow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if self:isBonusType(symbolType) then
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                targSp = self:setSymbolToClipReel(reelCol, iRow, symbolType)
                targSp:runAnim("buling")

                local soundPath = "MerryChristmasSounds/sound_MerryChristmas_bonus_ground.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

            end
        end
        local reelsIndex = self:getPosReelIdx(iRow, reelCol)
        local isHave = self:getHaveScatter(reelsIndex)
        if isHave then
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if targSp and isHave then
                targSp:playScatterTagAction(
                    "buling",
                    false,
                    function()
                        targSp:playScatterTagAction("idle", true)
                    end
                )

                local soundPath = "MerryChristmasSounds/sound_MerryChristmas_Scatter.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end


            end
        end
    end
end

function CodeGameScreenMerryChristmasMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent(false)
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMerryChristmasMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMerryChristmasMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMerryChristmasMachine:showFreeSpinView(effectData)
    self:stopLinesWinSound()
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_guochang.mp3")
            self:playTransitionEffect(
                function()
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    if selfData then
                        local count = selfData.freeGameTriggerCount
                        --是否是super free
                        if count == 5 or count == 10 or count == 20 then
                            self.m_bottomUI:showAverageBet()
                        end
                        self.m_tree:updataOpenBoxNum(count)
                    end
                    self:setFsStartDataAndReels()
                end,
                function()
                    gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_FreeSpinStart.mp3")
                    local view =
                        self:showFreeSpinStart(
                        self.m_iFreeSpinTimes,
                        function()
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                    local particle1 = view:findChild("Particle_1")
                    particle1:resetSystem()
                end
            )
        end
    end
    local delayTime = 2
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        self:playScatterCollect()
        delayTime = 3.5
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

function CodeGameScreenMerryChristmasMachine:showFreeSpinStart(num, func)
    local count = 1
    if self.m_runSpinResultData.p_fsExtraData.reelCount then
        count = self.m_runSpinResultData.p_fsExtraData.reelCount
    end
    local ownerlist = {}
    ownerlist["m_lb_num"] = num --触发次数
    ownerlist["m_lb_miniNum"] = count --轮盘个数
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
end

function CodeGameScreenMerryChristmasMachine:creatflyScatter()
    local csb = util_createAnimation("Socre_MerryChristmas_Scatter_tips.csb")
    csb:setScale(0.5)
    return csb
end

function CodeGameScreenMerryChristmasMachine:creatflyTouWei()
    local csb = util_createAnimation("Socre_MerryChristmas_tuowei1.csb")
    local particle1 = csb:findChild("tuoweishuye")
    local particle2 = csb:findChild("tuoweilizi")
    local particle3 = csb:findChild("tuoweishizi")
    particle1:setPositionType(0)
    particle2:setPositionType(0)
    particle3:setPositionType(0)
    return csb
end

function CodeGameScreenMerryChristmasMachine:creatflyTouWei2()
    local csb = util_createAnimation("Socre_MerryChristmas_tuowei2.csb")
    local particle1 = csb:findChild("tuoweilingdang_0")
    local particle2 = csb:findChild("tuoweishuye_0")
    local particle3 = csb:findChild("tuoweilizi_0")
    local particle4 = csb:findChild("tuoweilingdang")
    local particle5 = csb:findChild("tuoweishuye")
    local particle6 = csb:findChild("tuoweilizi")
    particle1:setPositionType(0)
    particle2:setPositionType(0)
    particle3:setPositionType(0)
    particle4:setPositionType(0)
    particle5:setPositionType(0)
    particle6:setPositionType(0)
    return csb
end

--添加一个灰色遮罩
function CodeGameScreenMerryChristmasMachine:showMaskLayer()
    if not self.m_MaskLayer then
        self.m_MaskLayer = util_createAnimation("MerryChristmas_Mask.csb")
        self.m_MaskLayer:setPosition(cc.p(display.width / 2, display.height / 2))
        self:addChild(self.m_MaskLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    end
    self.m_MaskLayer:setVisible(true)
    self.m_MaskLayer:runCsbAction("show")
end

--获取触发圣诞树的位置坐标
function CodeGameScreenMerryChristmasMachine:getTreeEndPos()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local count = selfData.freeGameTriggerCount
    local endNode = self.m_tree:getMoveToTreeNode(count)
    if not endNode then
        print("圣诞树获取坐标出错")
        return cc.p(0, 0)
    end
    local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    return endPos
end

--触发freespin 播放收集到圣诞树的效果
function CodeGameScreenMerryChristmasMachine:playScatterCollect()
    gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_FreeSpin_trigger.mp3")
    self:showMaskLayer()
    local endPos = self:getTreeEndPos()
    local num = 0
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_Scatter_collect.mp3")
        end,
        6 / 30
    )

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local reelsIndex = self:getPosReelIdx(iRow, iCol)
            local isHave = self:getHaveScatter(reelsIndex)
            if isHave then
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if node then
                    -- 对应位置创建 scatter 图标
                    local newScatter = self:creatflyScatter()
                    newScatter:runCsbAction("idle", true)
                    self:addChild(newScatter, GAME_LAYER_ORDER.LAYER_ORDER_TOP)
                    local pos = cc.p(util_getConvertNodePos(node.m_scatterTag, newScatter))
                    node:removeScatterTag()
                    newScatter:setPosition(pos)
                    local firstMovePos = cc.p(cc.p((pos.x - 180), (pos.y + 70)))
                    local actionList = {}
                    actionList[#actionList + 1] = cc.DelayTime:create(0.2)
                    actionList[#actionList + 1] =
                        cc.CallFunc:create(
                        function()
                            newScatter:runCsbAction(
                                "buling2",
                                false,
                                function()
                                    newScatter:removeFromParent()
                                end
                            )
                            self:playFlyScatterTouWei(pos, firstMovePos)
                        end
                    )
                    local bezier = self:getBezier(pos, firstMovePos)
                    actionList[#actionList + 1] = cc.BezierTo:create(0.3, bezier)
                    actionList[#actionList + 1] = cc.DelayTime:create(0.5)
                    actionList[#actionList + 1] =
                        cc.CallFunc:create(
                        function()
                            if num == 0 then
                                gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_Scatter_collect_ground.mp3")
                                self:flyEndToTree(endPos)
                            end
                            self:playFlyScatterTouWei2(firstMovePos, endPos)
                            num = num + 1
                        end
                    )
                    local sq = cc.Sequence:create(actionList)
                    newScatter:runAction(sq)
                end
            end
        end
    end
end

function CodeGameScreenMerryChristmasMachine:showDarkLayer()
    local nowHeight = self.m_iReelRowNum * self.m_SlotNodeH + 20
    local nowWidth = 800
    if not self.m_DarkLayer then
        self.m_DarkLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 200))
        self.m_DarkLayer:setContentSize(nowWidth, nowHeight)
        local reel = self:findChild("sp_reel_0")
        local posWorld = reel:getParent():convertToWorldSpace(cc.p(reel:getPosition()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        pos.y = pos.y - 10
        self.m_DarkLayer:setPosition(pos)
        self.m_clipParent:addChild(self.m_DarkLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 5)
    end
    self.m_DarkLayer:setVisible(true)
end
--
function CodeGameScreenMerryChristmasMachine:flyEndToTree(endPos)
    performWithDelay(
        self,
        function()
            --播发飞到圣诞树的效果
            self:playTreeCollect(endPos)
            self:updataOpenTree(false)
        end,
        15 / 30
    )
end

--飞行的拖尾粒子
function CodeGameScreenMerryChristmasMachine:playFlyScatterTouWei(pos, firstMovePos)
    local bezier = self:getBezier(pos, firstMovePos)
    local wei = self:creatflyTouWei()
    wei:setPosition(pos)
    self:addChild(wei, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local actionlistqar = {}
    actionlistqar[#actionlistqar + 1] = cc.BezierTo:create(0.3, bezier)
    actionlistqar[#actionlistqar + 1] =
        cc.CallFunc:create(
        function()
            wei:removeFromParent()
        end
    )
    actionlistqar[#actionlistqar + 1] = cc.DelayTime:create(0.2)
    local sq = cc.Sequence:create(actionlistqar)
    wei:runAction(sq)
end

--贝塞尔曲线计算
function CodeGameScreenMerryChristmasMachine:getBezier(pos, firstMovePos)
    local bezier = {}
    bezier[1] = cc.p(pos.x, pos.y)
    bezier[2] = cc.p(firstMovePos.x, firstMovePos.y - 150)
    bezier[3] = firstMovePos
    return bezier
end

--第二次向上飞拖尾粒子添加
function CodeGameScreenMerryChristmasMachine:playFlyScatterTouWei2(firstMovePos, endPos)
    local wei = self:creatflyTouWei2()
    wei:setPosition(firstMovePos)
    self:addChild(wei, GAME_LAYER_ORDER.LAYER_ORDER_TOP)
    local actionList1 = {}
    actionList1[#actionList1 + 1] = cc.DelayTime:create(0.2)
    actionList1[#actionList1 + 1] = cc.MoveTo:create(0.5, cc.p(endPos.x, endPos.y))
    actionList1[#actionList1 + 1] = cc.DelayTime:create(0.2)
    actionList1[#actionList1 + 1] =
        cc.CallFunc:create(
        function()
            wei:removeFromParent()
        end
    )
    local sq = cc.Sequence:create(actionList1)
    wei:runAction(sq)
end

--圣诞树上层爆炸效果添加
function CodeGameScreenMerryChristmasMachine:playTreeCollect(endPos)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        local count = selfData.freeGameTriggerCount
        local csbName = "MerryChristmas_box.csb"
        if count == 5 or count == 10 or count == 20 then
            csbName = "MerryChristmas_jackpot_tips.csb"
        end
        local csb = util_createAnimation(csbName)
        csb:setPosition(endPos)
        self:addChild(csb, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
        local actionName = ""
        if num == 5 or num == 10 then
            actionName = "super"
        elseif num == 20 then
            actionName = "grand"
        else
            actionName = "chuxiantexiao"
        end
        csb:runCsbAction(
            actionName,
            false,
            function()
                csb:removeFromParent()
                self.m_MaskLayer:setVisible(false)
            end
        )
    end
end

--fs 开始设置轮子及存储数据
function CodeGameScreenMerryChristmasMachine:setFsStartDataAndReels()
    if self.m_runSpinResultData.p_fsExtraData then
        if self.m_runSpinResultData.p_fsExtraData then
            if self.m_runSpinResultData.p_fsExtraData.scatterAndReel then
                self.m_ScatterAndReel = self.m_runSpinResultData.p_fsExtraData.scatterAndReel
                self:sortScatterAndReelData()
            end
            if self.m_runSpinResultData.p_fsExtraData.reelCount then
                local count = self.m_runSpinResultData.p_fsExtraData.reelCount
                self:showFsMiniMachine(count)
            end
        end
    end
end

--显示fs下收集的个数
function CodeGameScreenMerryChristmasMachine:showFsCollect()
    local collectNum = self.m_runSpinResultData.p_fsExtraData.collected
    local needNum = 0
    local reelNum = 0
    if collectNum and collectNum > 0 then
        for k, v in pairs(self.m_ScatterAndReel) do
            if collectNum < v.needNum then
                needNum = v.needNum
                reelNum = v.reelNum
                break
            end
        end
        if reelNum > 0 and reelNum > 0 then
            self.m_fsCollect:showColletNum(needNum, reelNum, collectNum)
        else
            local maxData = self.m_ScatterAndReel[#self.m_ScatterAndReel]
            self.m_bCollectMax = true
            self.m_fsCollect:showColletNum(maxData.needNum, maxData.reelNum, collectNum, true)
        end
    else
        if self.m_ScatterAndReel and #self.m_ScatterAndReel > 1 then
            local data = self.m_ScatterAndReel[1]
            self.m_fsCollect:showColletNum(data.needNum, data.reelNum, 0)
        end
    end
end

--刷新 freespin 收集的礼盒个数
function CodeGameScreenMerryChristmasMachine:updataFsCollect()
    if self.m_runSpinResultData.p_fsExtraData then
        local collectNum = self.m_runSpinResultData.p_fsExtraData.collected or 0
        local needNum = 0
        local reelNum = 0
        if collectNum and collectNum > 0 then
            for k, v in pairs(self.m_ScatterAndReel) do
                if collectNum < v.needNum then
                    needNum = v.needNum
                    reelNum = v.reelNum
                    break
                end
            end
        end
        if reelNum > 0 and reelNum > 0 then
            self.m_fsCollect:updataChangeColletNum(needNum, reelNum, collectNum)
            self.m_fsCollect:runCsbAction("actionframe")
        else
            local maxData = self.m_ScatterAndReel[#self.m_ScatterAndReel]
            self.m_bCollectMax = true
            self.m_fsCollect:runCsbAction("actionframe")
            self.m_fsCollect:updataChangeColletNum(maxData.needNum, maxData.reelNum, collectNum, true)
        end
    end
end

function CodeGameScreenMerryChristmasMachine:initFsMiniMachine()
    self.m_miniWheelBg = util_createAnimation("MerryChristmas_Mini_reelsBg.csb")
    self:findChild("miniReels"):addChild(self.m_miniWheelBg)
    self.m_vecMiniWheel = {} -- mini轮盘列表
    for i = 1, 9 do
        local name = "reel" .. i
        local addNode = self.m_miniWheelBg:findChild(name)
        if addNode then
            local data = {}
            data.index = i
            data.parent = self
            local miniMachine = util_createView("CodeMerryChristmasSrc.MerryChristmasMiniMachine", data)
            addNode:addChild(miniMachine)
            table.insert(self.m_vecMiniWheel, miniMachine)
            miniMachine:setVisible(false)
            if self.m_bottomUI.m_spinBtn.addTouchLayerClick  then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniMachine.m_touchSpinLayer)
            end
        end
    end
end

--fs初始化小轮盘
function CodeGameScreenMerryChristmasMachine:showFsMiniMachine(_num)
    self.m_jackpotbar:setVisible(false)
    self.m_fsCollect:setVisible(true)
    self:showFsCollect()

    self.m_tree:setVisible(false)
    self:findChild("Node_reels"):setVisible(false)
    self:findChild("Node_mainDeng"):setVisible(false)

    self.m_miniWheelBg:runCsbAction("idle" .. _num)

    for i = 1, _num do
        local miniMachine = self.m_vecMiniWheel[i]
        miniMachine:setVisible(true)
    end
    self.m_iMiniWheelNum = _num
    if _num == 1 then
        local miniWheel = self.m_vecMiniWheel[1]
        local dengNode = miniWheel:findChild("Node_fs_reels")
        self.m_miniWheelDeng = util_createAnimation("MerryChristmas_mini_deng.csb")
        self.m_miniWheelDeng:runCsbAction("idle1", true)
        dengNode:addChild(self.m_miniWheelDeng)
    end
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
end

--fs初始化小轮盘
function CodeGameScreenMerryChristmasMachine:changeMiniMachine(_num)
    if _num > 1 then
        if self.m_miniWheelDeng then
            self.m_miniWheelDeng:removeFromParent()
            self.m_miniWheelDeng = nil
        end
    end
    if _num > self.m_iMiniWheelNum then
        local beginNum = self.m_iMiniWheelNum
        for i = beginNum + 1, _num do
            local miniMachine = self.m_vecMiniWheel[i]
            miniMachine:setVisible(true)
        end
        self.m_iMiniWheelNum = _num
        self.m_miniWheelBg:runCsbAction(beginNum .. "to" .. _num, false)
    end
end

--移除小轮盘
function CodeGameScreenMerryChristmasMachine:removeAllMiniMachine()
    self.m_jackpotbar:setVisible(true)
    self.m_fsCollect:setVisible(false)
    self.m_tree:setVisible(true)
    self:findChild("Node_reels"):setVisible(true)
    self:findChild("Node_mainDeng"):setVisible(true)
    for i = 1, #self.m_vecMiniWheel do
        local reels = self.m_vecMiniWheel[i]
        reels:setVisible(false)
        reels:clearFrames_Fun()
        reels:clearWinLineEffect()
    end
    self.m_iMiniWheelNum = 0
    self.m_ScatterAndReel = {}
end

function CodeGameScreenMerryChristmasMachine:showFreeSpinOverView()
    self:stopLinesWinSound()
    gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_FreeSpinOver.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_guochang.mp3")
            self:playTransitionEffect(
                function()
                    if self.m_runSpinResultData.p_selfMakeData then
                        local count = self.m_runSpinResultData.p_selfMakeData.freeGameTriggerCount
                        if count == 20 then
                            self.m_tree:playTreeOver()
                        end
                    end
                    self:hideFreeSpinBar()
                    self.m_bottomUI:hideAverageBet()
                    -- self:updataOpenTree(false)
                    self:removeAllMiniMachine()
                end,
                function()
                    self.m_bCollectMax = false
                    self:triggerFreeSpinOverCallFun()
                end
            )
        end
    )
    local node = view:findChild("m_lb_coins")
    local particle1 = view:findChild("Particle_1")
    particle1:resetSystem()
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 720)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMerryChristmasMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self:stopLinesWinSound()

    self.m_collectScatterEffectTimes = 0
    self.m_FsDownTimes = 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_fsExtraData then
            if self.m_runSpinResultData.p_fsExtraData.reelCount then
                local count = self.m_runSpinResultData.p_fsExtraData.reelCount
                print("轮盘数量 ================================ " .. count)
                if count > self.m_iMiniWheelNum then
                    self:changeMiniMachine(count)
                -- return true
                end
            end
        end
    end

    return false -- 用作延时点击spin调用
end

--------------------添加动画
function CodeGameScreenMerryChristmasMachine:addSelfEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 自定义动画创建方式
        if self:checkAllMiniIsHaveScatter() and not self.m_bCollectMax then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FS_COLLECT_EFFECT -- 动画类型
        end
    end
end

function CodeGameScreenMerryChristmasMachine:checkAllMiniWinCoins()
    for i = 1, self.m_iMiniWheelNum do
        local minireel = self.m_vecMiniWheel[i]
        local winLines = minireel:getResultLines()
        if winLines and #winLines > 0 then
            return true
        end
    end
    return false
end

function CodeGameScreenMerryChristmasMachine:checkAllMiniIsHaveScatter()
    local isHave = false
    for i = 1, self.m_iMiniWheelNum do
        local minireel = self.m_vecMiniWheel[i]
        if minireel:checkIsHaveScatter() then
            isHave = true
        end
    end
    return isHave
end

-- 实现自定义动画内容
function CodeGameScreenMerryChristmasMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.FS_COLLECT_EFFECT then
        self:playFsCollectScatter()
    end
    return true
end

function CodeGameScreenMerryChristmasMachine:playFsCollectScatter()
    local isHave = self:checkAllMiniIsHaveScatter()
    if isHave then
        gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_Scatter_collect.mp3")
        for i = 1, self.m_iMiniWheelNum do
            local miniReel = self.m_vecMiniWheel[i]
            miniReel:runCollectScatterEffect()
        end
    end
end

-- 设置自定义游戏事件
function CodeGameScreenMerryChristmasMachine:restSelfEffect(selfEffect)
    for i = 1, #self.m_gameEffects, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and effectData.p_selfEffectType == selfEffect then
            effectData.p_isPlay = true
            self:playGameEffect()
            break
        end
    end
end

function CodeGameScreenMerryChristmasMachine:playCollectScatterEffect()
    self.m_collectScatterEffectTimes = self.m_collectScatterEffectTimes + 1

    if self.m_collectScatterEffectTimes == self.m_iMiniWheelNum then
        gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_Scatter_collect_ground.mp3")
        -- 恢复各个轮盘的等待状态
        self:updataFsCollect()
        self.m_collectScatterEffectTimes = 0
        local data = self.m_runSpinResultData
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if data.p_freeSpinsLeftCount > 0 then
                self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
            end
        end
        if data.p_freeSpinsLeftCount > globalData.slotRunData.freeSpinCount then
            globalData.slotRunData.freeSpinCount = data.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = data.p_freeSpinsTotalCount
            self.m_baseFreeSpinBar:addTotalFreeSpinCount()
        end

        performWithDelay(
            self,
            function()
                if self:checkAllMiniWinCoins() then
                    self:checkNotifyUpdateWinCoin()
                end
                for i = 1, self.m_iMiniWheelNum do
                    local minireel = self.m_vecMiniWheel[i]
                    minireel:restSelfEffect(self.FS_COLLECT_EFFECT)
                end
                if self:isTriggerBigWin() then
                    scheduler.performWithDelayGlobal(
                        function(delay)
                            self:restSelfEffect(self.FS_COLLECT_EFFECT)
                            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                        end,
                        0.5,
                        self:getModuleName()
                    )
                else
                    self:restSelfEffect(self.FS_COLLECT_EFFECT)
                end
            end,
            1
        )
    end
end

--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function CodeGameScreenMerryChristmasMachine:checkRemoveBigMegaEffect()
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
    local bFsOver = false
    local data = self.m_runSpinResultData
    if globalData.slotRunData.freeSpinCount == 0 and data.p_freeSpinsLeftCount == 0 then
        bFsOver = true
    end
    if hasFsOverEffect == true and bFsOver == true then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
    end
end
function CodeGameScreenMerryChristmasMachine:slotReelDown()
    BaseNewReelMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenMerryChristmasMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

--显示scatter所在位置
function CodeGameScreenMerryChristmasMachine:updateReelGridNode(node)
    local isLastSymbol = node.m_isLastSymbol
    if isLastSymbol == true then
        local symbolType = node.p_symbolType
        local row = node.p_rowIndex
        local col = node.p_cloumnIndex
        local reelsIndex = self:getPosReelIdx(row, col)
        local isHave = self:getHaveScatter(reelsIndex)
        if node and isHave then
            self:createScatterTag(node)
        end
    end
end

function CodeGameScreenMerryChristmasMachine:createScatterTag(node)
    if node.m_scatterTag == nil then
        local scatterTag = util_createAnimation("Socre_MerryChristmas_Scatter_tips.csb")
        scatterTag:setScale(0.5)
        scatterTag:setPosition(100, -30)
        node.m_scatterTag = scatterTag
        node:addChild(scatterTag, 100)
    end
end

--寻找scatter位置
function CodeGameScreenMerryChristmasMachine:getHaveScatter(reelsIndex)
    local isHave = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.scatters then
        local scatters = selfData.scatters
        if scatters then
            for k, v in pairs(scatters) do
                local index = tonumber(v)
                if reelsIndex == index then
                    isHave = true
                    break
                end
            end
        end
    end
    return isHave
end

function CodeGameScreenMerryChristmasMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:resetReelDataAfterReel()
        --fs小轮盘开始转动
        for i = 1, self.m_iMiniWheelNum do
            local reels = self.m_vecMiniWheel[i]
            reels:beginMiniReel()
        end
    else
        BaseNewReelMachine.beginReel(self)
    end
end

---
-- 处理spin 返回结果
function CodeGameScreenMerryChristmasMachine:spinResultCallFun(param)
    BaseNewReelMachine.spinResultCallFun(self, param)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if param[1] == true then
            local spinData = param[2]
            if spinData.result then
                if spinData.result.freespin then
                    if spinData.result.freespin.extra then
                        if spinData.result.freespin.extra.allSpinResult then
                            --处理小轮盘收到消息
                            local datas = spinData.result.freespin.extra.allSpinResult
                            print("收到信息 轮盘的个数" .. #datas)
                            print("现在显示 轮盘的个数" .. self.m_iMiniWheelNum)
                            for i = 1, self.m_iMiniWheelNum do
                                local miniReelsData = datas[i]
                                miniReelsData.bet = 0
                                miniReelsData.payLineCount = 0
                                local reels = self.m_vecMiniWheel[i]
                                reels:netWorkCallFun(miniReelsData)
                            end
                        end
                    end
                end
            end
        end
    end
end

--freespin下主轮调用父类停止函数
function CodeGameScreenMerryChristmasMachine:slotReelDownInFS()
    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex
    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:stopAllActions()
    if self:isTriggerBigWin() then
        scheduler.performWithDelayGlobal(
            function(delay)
                self:reelDownNotifyPlayGameEffect()
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            end,
            0.5,
            self:getModuleName()
        )
    else
        self:reelDownNotifyPlayGameEffect()
    end
    --有收集的话不算钱； 已经收集到了最大值直接算钱不收集
    if not self:checkAllMiniIsHaveScatter() or self.m_bCollectMax then
        if self:checkAllMiniWinCoins() then
            self:checkNotifyUpdateWinCoin()
        end
    end
end

function CodeGameScreenMerryChristmasMachine:isTriggerBigWin()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        return true
    end
    return false
end

function CodeGameScreenMerryChristmasMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end
    if self.m_iOnceSpinLastWin > 0 then
        notAdd = false
    end

    return notAdd
end

function CodeGameScreenMerryChristmasMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    else
        BaseNewReelMachine.playEffectNotifyChangeSpinStatus(self)
    end
end

function CodeGameScreenMerryChristmasMachine:setFsAllRunDown(times)
    self.m_FsDownTimes = self.m_FsDownTimes + times

    if self.m_FsDownTimes == self.m_iMiniWheelNum then
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) and self:getCurrSpinMode() == FREE_SPIN_MODE then
            print("啥也不做")
        else
            BaseNewReelMachine.playEffectNotifyChangeSpinStatus(self)
            if self:isTriggerBigWin() then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            end
        end

        self.m_FsDownTimes = 0
    end
end

function CodeGameScreenMerryChristmasMachine:sendBonusData()
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil
    if self.m_isBonusCollect then
        messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = {}}
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

--判断类型
function CodeGameScreenMerryChristmasMachine:isBonusType(_type)
    if _type == self.SYMBOL_BONUS_1 or _type == self.SYMBOL_BONUS_2 or _type == self.SYMBOL_BONUS_3 then
        return true
    end
    return false
end

function CodeGameScreenMerryChristmasMachine:getBonusData()
    local isHave = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.scatters then
        local scatters = selfData.scatters
        if scatters then
            for k, v in pairs(scatters) do
                local index = tonumber(v)
                if reelsIndex == index then
                    isHave = true
                    break
                end
            end
        end
    end
    return isHave
end

--获取所有bonus  图标
function CodeGameScreenMerryChristmasMachine:setBonusList(_bReconnet)
    self.m_bonusSymbolList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if self:isBonusType(node.p_symbolType) then
                    -- if _bReconnet then
                        node = self:setSymbolToClipReel(iCol, iRow, node.p_symbolType)
                    -- end
                    local nodeInfo = {}
                    local reelsIndex = self:getPosReelIdx(iRow, iCol)
                    nodeInfo.reelsIndex = reelsIndex
                    nodeInfo.icol = iCol
                    nodeInfo.irow = iRow
                    nodeInfo.node = node
                    table.insert(self.m_bonusSymbolList, nodeInfo)
                end
            end
        end
    end
end

function CodeGameScreenMerryChristmasMachine:showBonusGameView(effectData)
    self:clearCurMusicBg()
    self:clearFrames_Fun()
    self:clearWinLineEffect()
    self.m_effectData = effectData
    self:setBonusList()
    self:showDarkLayer()
    for k, v in pairs(self.m_bonusSymbolList) do
        local nodeInfo = v
        local node = nodeInfo.node
        node:runAnim("actionframe", false)
    end
    self:playBonusMusicBgm()
    scheduler.performWithDelayGlobal(
        function(delay)
            self.isInBonus = true
            self.m_iBonusPlayIndex = 1
            self.m_iTipsIndex = 0
            self.m_iBonusWinCoins = globalData.slotRunData.lastWinCoin
            self:playBonusClassiclEffect()
        end,
        2.5,
        self:getModuleName()
    )
end

function CodeGameScreenMerryChristmasMachine:playBonusClassiclEffect()
    if self.m_iBonusPlayIndex > #self.m_bonusSymbolList then
        scheduler.performWithDelayGlobal(
            function(delay)
                if self.m_DarkLayer then
                    self.m_DarkLayer:setVisible(false)
                end
                self.isInBonus = false
                if self.m_effectData then
                    self.m_effectData.p_isPlay = true
                end
                self:checkFeatureOverTriggerBigWin(self.m_iBonusWinCoins, GameEffect.EFFECT_BONUS)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

                self:hideBonusJackpotTips()
                self:resetMusicBg()
                -- self:clearCurMusicBg()
                self:playGameEffect()
            end,
            1.0,
            self:getModuleName()
        )
        return
    end
    local bonusData = self.m_bonusSymbolList[self.m_iBonusPlayIndex]
    if bonusData then
        local bonusNode = bonusData.node
        local _index = bonusData.icol
        if self.m_iTipsIndex ~= _index then
            if not self.m_tips then
                self:showBonusJackpotTips(_index)
                self.m_iTipsIndex = _index
            else
                self:hideBonusJackpotTips(
                    function()
                        self:showBonusJackpotTips(_index)
                        self.m_iTipsIndex = _index
                    end
                )
            end
        else
            self:setTipsWinTypeVisible(false)
        end
        self.m_bonusZhuanId = gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_bonus_zhuan.mp3", false)
        bonusNode:runAnim(
            "start",
            false,
            function()
                bonusNode:runAnim("idle", true)
            end
        )
        self:sendBonusData()
    end
end

function CodeGameScreenMerryChristmasMachine:setBonusSymbolWinInfo(node, data)
    for i = 1, 3 do
        for j = 1, 3 do
            local sprite = node:getCcbProperty("reel_" .. j .. "_" .. i)
            if sprite then
                local id = data[i][j]
                if id == self.SYMBOL_Classicl_None then
                    sprite:setVisible(false)
                else
                    local sprName = self:getBonusSymbolImgById(id)
                    util_changeTexture(sprite, sprName)
                    sprite:setVisible(true)
                end
            end
        end
    end
end

function CodeGameScreenMerryChristmasMachine:getBonusSymbolImgById(id)
    local name = ""
    if id == self.SYMBOL_Classicl_2X then
        name = "Common/2x.png"
    elseif id == self.SYMBOL_Classicl_3X then
        name = "Common/3x.png"
    elseif id == self.SYMBOL_Classicl_5X then
        name = "Common/5x.png"
    elseif id == self.SYMBOL_Classicl_Red7 then
        name = "Common/r7.png"
    elseif id == self.SYMBOL_Classicl_Blue7 then
        name = "Common/b7.png"
    elseif id == self.SYMBOL_Classicl_Bar1 then
        name = "Common/BAR1.png"
    elseif id == self.SYMBOL_Classicl_Bar2 then
        name = "Common/BAR2.png"
    elseif id == self.SYMBOL_Classicl_Bar3 then
        name = "Common/BAR3.png"
    end
    return name
end

function CodeGameScreenMerryChristmasMachine:checkBonusReel(classicReels, pos)
    if classicReels and #classicReels then
        local data = {}
        for k, v in pairs(classicReels) do
            if pos == k then
                data = v
            end
        end
        return data
    end
end

function CodeGameScreenMerryChristmasMachine:showBonusSymbleWin()
    scheduler.performWithDelayGlobal(
        function(delay)
            local bonusData = self.m_bonusSymbolList[self.m_iBonusPlayIndex]
            if bonusData then
                local bonusExtraData = self.m_runSpinResultData.p_bonusExtra
                local classicReels = bonusExtraData.classicReels
                local data = self:checkBonusReel(classicReels, tostring(bonusData.reelsIndex))
                local bonusNode = bonusData.node
                self:setBonusSymbolWinInfo(bonusNode, data)
                --设置bonus 中奖信号
                if self.m_bonusZhuanId then
                    gLobalSoundManager:stopAudio(self.m_bonusZhuanId)
                    self.m_bonusZhuanId = nil
                end
                bonusNode:runAnim("over", false)
                scheduler.performWithDelayGlobal(
                    function(delay)
                        --获取赢钱 通过id
                        local winCoins = self:getBonusWinCoins(bonusExtraData, tostring(bonusData.reelsIndex))
                        globalData.slotRunData.lastWinCoin = self.m_iBonusWinCoins + winCoins
                        --显示赢钱
                        if winCoins > 0 then
                            gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_classical_win.mp3")
                            self:showTipsWinLinesType()
                            self:showBonusWinLines(
                                bonusNode,
                                function()
                                    self:showBonusWinCoins(bonusNode, winCoins)
                                    if self:isWinJackpot(bonusExtraData) then
                                        local jackpotType = bonusExtraData.JackpotType
                                        local jackpotCoins = bonusExtraData.JackpotCoins
                                        self:showJackpotWin(
                                            jackpotType,
                                            jackpotCoins,
                                            function()
                                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {globalData.slotRunData.lastWinCoin, false, true, self.m_iBonusWinCoins})
                                                self.m_iBonusWinCoins = globalData.slotRunData.lastWinCoin
                                                self.m_iBonusPlayIndex = self.m_iBonusPlayIndex + 1
                                                self:playBonusClassiclEffect()
                                            end
                                        )
                                    else
                                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {globalData.slotRunData.lastWinCoin, false, true, self.m_iBonusWinCoins})
                                        self.m_iBonusWinCoins = globalData.slotRunData.lastWinCoin
                                        self.m_iBonusPlayIndex = self.m_iBonusPlayIndex + 1
                                        self:playBonusClassiclEffect()
                                    end
                                end
                            )
                        else
                            self.m_iBonusPlayIndex = self.m_iBonusPlayIndex + 1
                            self:playBonusClassiclEffect()
                        end
                    end,
                    1.5,
                    self:getModuleName()
                )
            end
        end,
        2.5,
        self:getModuleName()
    )
end

--获取这次spin的赢钱
function CodeGameScreenMerryChristmasMachine:getBonusWinCoins(bonusExtraData, pos)
    if bonusExtraData.posWin then
        local winCoins = 0
        for k, v in pairs(bonusExtraData.posWin) do
            if pos == k then
                winCoins = v
                break
            end
        end
        return winCoins
    end
end

--计算bonus赢钱线
function CodeGameScreenMerryChristmasMachine:getBonusWinLines()
    local linesData = {}
    local winLines = self.m_runSpinResultData.p_winLines
    for k, v in pairs(winLines) do
        local lineNum = v.p_id
        table.insert(linesData, lineNum)
    end
    return linesData
end

--显示弹板中奖框
function CodeGameScreenMerryChristmasMachine:showTipsWinLinesType()
    if self.m_tips then
        self.m_tips:runCsbAction("idle2", true)
        self:setTipsWinTypeVisible(false)
        local bonusWinData = self:getBonusWinLinesType()
        for k, v in pairs(bonusWinData) do
            local _type = v
            local _index = self:getWinIndexByType(_type)
            local winNode = self.m_tips:findChild("winType_" .. _index)
            winNode:setVisible(true)
        end
    end
end

function CodeGameScreenMerryChristmasMachine:setTipsWinTypeVisible(_bVisible)
    for i = 1, 10 do
        local winNode = self.m_tips:findChild("winType_" .. i)
        winNode:setVisible(_bVisible)
    end
end

--计算bonus赢钱线类型
function CodeGameScreenMerryChristmasMachine:getBonusWinLinesType()
    local linesData = {}
    local winLines = self.m_runSpinResultData.p_winLines
    for k, v in pairs(winLines) do
        local lineType = v.p_type
        table.insert(linesData, lineType)
    end
    return linesData
end

--通过赢钱类型 显示对应的中线框
function CodeGameScreenMerryChristmasMachine:getWinIndexByType(_winType)
    print("CodeGameScreenMerryChristmasMachine ===============_winType ==" .. _winType)
    if _winType == self.SYMBOL_Classicl_2X or _winType == self.SYMBOL_Classicl_3X or _winType == self.SYMBOL_Classicl_5X then
        return 1
    elseif _winType == 1002 then --对应两个有两个wild的
        return 2
    elseif _winType == 1001 then --对应两个有一个wild的
        return 3
    elseif _winType == self.SYMBOL_Classicl_Red7 then
        return 4
    elseif _winType == self.SYMBOL_Classicl_Blue7 then
        return 5
    elseif _winType == self.SYMBOL_Classicl_Bar1 then
        return 8
    elseif _winType == self.SYMBOL_Classicl_Bar2 then
        return 7
    elseif _winType == self.SYMBOL_Classicl_Bar3 then
        return 6
    elseif _winType == 1007 then --对应any7
        return 9
    elseif _winType == 1008 then --对应anybar
        return 10
    end
end

--显示bonus玩法赢钱线
function CodeGameScreenMerryChristmasMachine:showBonusWinLines(bonusNode, func)
    local bonusWinData = self:getBonusWinLines()
    for i = 1, #bonusWinData do
        local lineNum = bonusWinData[i] + 1
        local lineNode = bonusNode:getCcbProperty("Line" .. lineNum)
        if lineNode then
            lineNode:setVisible(true)
        end
    end

    scheduler.performWithDelayGlobal(
        function(delay)
            if func then
                func()
            end
        end,
        2.5,
        self:getModuleName()
    )
end

--显示单个bonus信号块 赢钱
function CodeGameScreenMerryChristmasMachine:showBonusWinCoins(_bonusNode, _winCoins)
    local winCsb = self:createBonusWinCsb(_winCoins)
    winCsb:runCsbAction("actionframe")
    local csbNode = _bonusNode:getCcbProperty("Node_51")
    _bonusNode.m_bonusTips = winCsb
    csbNode:addChild(winCsb)
end

function CodeGameScreenMerryChristmasMachine:isWinJackpot(_bonusData)
    --判断是否中jackpot JackpotType 类型； JackpotCoins 赢钱
    if _bonusData.JackpotType and _bonusData.JackpotCoins then
        return true
    end
    return false
end

--创建
function CodeGameScreenMerryChristmasMachine:createBonusWinCsb(_winCoins)
    local winCsb = util_createAnimation("Socre_MerryChristmas_bonuswin.csb")
    local lab = winCsb:findChild("BitmapFontLabel_1")
    lab:setString(util_formatCoins(_winCoins, 3))
    winCsb:runCsbAction("idle2")
    return winCsb
end

--显示bonus玩法jackpot提示小弹板
function CodeGameScreenMerryChristmasMachine:showBonusJackpotTips(_index)
    local tipsName = "MerryChristmas_minor_tips.csb"
    if _index == 1 then
        tipsName = "MerryChristmas_minor_tips.csb"
    elseif _index == 2 then
        tipsName = "MerryChristmas_major_tips.csb"
    elseif _index == 3 then
        tipsName = "MerryChristmas_grand_tips.csb"
    end

    self.m_tips = util_createAnimation(tipsName)
    self:findChild("Node_jackpot_" .. _index):addChild(self.m_tips)
    self.m_tips:runCsbAction("actionframe")
end

--显示bonus玩法jackpot提示小弹板
function CodeGameScreenMerryChristmasMachine:hideBonusJackpotTips(func)
    if self.m_tips then
        -- self:setTipsWinTypeVisible(false)
        self.m_tips:runCsbAction(
            "over",
            false,
            function()
                self.m_tips:removeFromParent()
                self.m_tips = nil
                if func then
                    func()
                end
            end
        )
    end
end

-- bonus小游戏断线重连
function CodeGameScreenMerryChristmasMachine:initFeatureInfo(spinData, featureData)
    if spinData.p_bonusStatus == "OPEN" then
        self.isInBonus = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end

function CodeGameScreenMerryChristmasMachine:enterLevel()
    BaseNewReelMachine.enterLevel(self)
    if self.isInBonus == true then
        self:initReconnetBonusGame()
    end
end

--bonus断线重连 处理
function CodeGameScreenMerryChristmasMachine:initReconnetBonusGame()
    local choseData = self.m_initFeatureData.p_chose
    local bonusExtraData = self.m_initFeatureData.p_extra
    local classicReels = bonusExtraData.classicReels
    local symPostions = bonusExtraData.positions
    self:setBonusList(true)

    local chooseNum = 0
    local winCoins = 0
    for i, reelIndex in ipairs(choseData) do
        for j, value in ipairs(self.m_bonusSymbolList) do
            local bonusData = value
            if bonusData.reelsIndex == reelIndex then
                local bonusNode = bonusData.node
                local data = self:checkBonusReel(classicReels, tostring(bonusData.reelsIndex))
                bonusNode:runAnim("overidle")
                self:setBonusSymbolWinInfo(bonusNode, data)

                local winCoin = self:getBonusWinCoins(bonusExtraData, tostring(bonusData.reelsIndex))
                if winCoin > 0 then
                    local winCsb = self:createBonusWinCsb(winCoin)
                    local csbNode = bonusNode:getCcbProperty("Node_51")
                    bonusNode.m_bonusTips = winCsb
                    csbNode:addChild(winCsb)
                end
                winCoins = winCoins + winCoin
            end
        end
        chooseNum = chooseNum + 1
    end
    self.m_iBonusWinCoins = winCoins
    if chooseNum == #self.m_bonusSymbolList then
        self.isInBonus = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        return
    else
        if self.m_iBonusWinCoins > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_iBonusWinCoins))
        end
        self:clearCurMusicBg()
        self:playBonusMusicBgm()
        self:showDarkLayer()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end

    scheduler.performWithDelayGlobal(
        function(delay)
            self.m_iBonusPlayIndex = chooseNum + 1
            self.m_iTipsIndex = 0
            self:playBonusClassiclEffect()
        end,
        2.5,
        self:getModuleName()
    )
end

--过场动画
function CodeGameScreenMerryChristmasMachine:playTransitionEffect(funcFrame, funcEnd)
    self.m_guochang:setVisible(true)
    self.m_guochang:runCsbAction(
        "guochang",
        false,
        function()
            self.m_guochang:setVisible(false)
        end
    )
    local particle1 = self.m_guochang:findChild("Particle_1")
    local particle2 = self.m_guochang:findChild("Particle_1_0")
    local particle3 = self.m_guochang:findChild("Particle_1_0_0")
    particle1:resetSystem()
    particle2:resetSystem()
    particle3:resetSystem()

    scheduler.performWithDelayGlobal(
        function(delay)
            self.m_guochang2:setVisible(true)
            util_spinePlay(self.m_guochang2, "actionframe", false)
            -- 动画帧事件
            util_spineFrameEvent(
                self.m_guochang2,
                "actionframe",
                "Show",
                function()
                    if funcFrame then
                        funcFrame()
                    end
                end
            )
            -- 动画结束
            util_spineEndCallFunc(
                self.m_guochang2,
                "actionframe",
                function()
                    self.m_guochang2:setVisible(false)
                    if funcEnd then
                        funcEnd()
                    end
                end
            )
        end,
        15 / 30,
        self:getModuleName()
    )
end

--消息返回
function CodeGameScreenMerryChristmasMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or spinData.action == "FEATURE" then
        release_print("消息返回胡来了")
        print(cjson.encode(spinData))

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)
        if spinData.action == "FEATURE" then
            self:showBonusSymbleWin()
        end

        if spinData.action == "SPIN" then
            self:updateNetWorkData()
        end
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function CodeGameScreenMerryChristmasMachine:showJackpotWin(jackPot, coins, func)
    gLobalSoundManager:playSound("MerryChristmasSounds/sound_MerryChristmas_tip_show.mp3")
    local jackPotWinView = util_createView("CodeMerryChristmasSrc.MerryChristmasJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self, jackPot, coins, func)
end

function CodeGameScreenMerryChristmasMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if #winLines <= 0 then
            return
        end
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenMerryChristmasMachine:playBonusMusicBgm()
    self.m_currentMusicBgName = "MerryChristmasSounds/music_MerryChristmas_bonus_bgm.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

return CodeGameScreenMerryChristmasMachine
