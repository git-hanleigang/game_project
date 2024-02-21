---
-- xcyy
-- 2018-12-18
-- MerryChristmasMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local SlotParentData = require "data.slotsdata.SlotParentData"

local MerryChristmasMiniMachine = class("MerryChristmasMiniMachine", BaseMiniMachine)

MerryChristmasMiniMachine.m_machineIndex = nil -- csv 文件模块名字

MerryChristmasMiniMachine.gameResumeFunc = nil
MerryChristmasMiniMachine.gameRunPause = nil

local MainReelId = 1
MerryChristmasMiniMachine.FS_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

-- 构造函数
function MerryChristmasMiniMachine:ctor()
    BaseMiniMachine.ctor(self)
end

function MerryChristmasMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent
    self.m_maxReelIndex = data.maxReelIndex
    self.m_reelId = data.index
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function MerryChristmasMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MerryChristmasMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MerryChristmas"
end

function MerryChristmasMiniMachine:getMachineConfigName()
    local str = "Mini"
    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MerryChristmasMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

function MerryChristmasMiniMachine:getBaseReelGridNode()
    return "CodeMerryChristmasSrc.MerryChristmasSlotsNode"
end

---
-- 读取配置文件数据
--
function MerryChristmasMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function MerryChristmasMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("MerryChristmas_mini_reel.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function MerryChristmasMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    BaseMiniMachine.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function MerryChristmasMiniMachine:addSelfEffect()
    local data = self.m_runSpinResultData
    if self.m_parent:checkAllMiniIsHaveScatter() and not self.m_parent.m_bCollectMax then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FS_COLLECT_EFFECT
    end
end

function MerryChristmasMiniMachine:MachineRule_playSelfEffect(effectData)
    return true
end

function MerryChristmasMiniMachine:readSoundConfigData()
    --音乐
    self:setBackGroundMusic(self.m_configData.p_musicBg)
    --背景音乐
    self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)
    --fs背景音乐
    self:setRsBackGroundMusic(self.m_configData.p_musicReSpinBg)
    --respin背景
    self.m_ScatterTipMusicPath = self.m_configData.p_soundScatterTip --scatter提示音
    self.m_BonusTipMusicPath = self.m_configData.p_soundBonusTip --bonus提示音
    if self.m_reelId == MainReelId then
        self:setReelDownSound(self.m_configData.p_soundReelDown)
    --下落音
    end

    self:setReelRunSound(self.m_configData.p_reelRunSound)
    --快滚音效
end

function MerryChristmasMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MerryChristmasMiniMachine:removeObservers()
    BaseMiniMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function MerryChristmasMiniMachine:dealSmallReelsSpinStates()
end

---
-- 清空掉产生的数据
--
function MerryChristmasMiniMachine:clearSlotoData()
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MerryChristmasMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function MerryChristmasMiniMachine:clearCurMusicBg()
end

function MerryChristmasMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function MerryChristmasMiniMachine:reelDownNotifyChangeSpinStatus()
    -- 发送freespin停止回调
    if self.m_reelId == MainReelId then
        if self.m_parent then
            self.m_parent:slotReelDownInFS()
        end
    end
end

function MerryChristmasMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:setFsAllRunDown(1)
end

function MerryChristmasMiniMachine:quicklyStopReel(colIndex)
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        BaseMiniMachine.quicklyStopReel(self, colIndex)
    end
end

function MerryChristmasMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function MerryChristmasMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

function MerryChristmasMiniMachine:beginMiniReel()
    BaseMiniMachine.beginReel(self)
end

-- 消息返回更新数据
function MerryChristmasMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)

    self:updateNetWorkData()
end

function MerryChristmasMiniMachine:enterLevel()
    BaseMiniMachine.enterLevel(self)
end

function MerryChristmasMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
    self:perpareStopReel()
end

-- 轮盘停止回调(自己实现)
function MerryChristmasMiniMachine:setDownCallFunc(func)
    self.m_reelDownCallback = func
end

function MerryChristmasMiniMachine:playEffectNotifyNextSpinCall()
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

function MerryChristmasMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines
end

function MerryChristmasMiniMachine:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function MerryChristmasMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MerryChristmasMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function MerryChristmasMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

function MerryChristmasMiniMachine:initRandomSlotNodes()
    --初始化节点
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end

function MerryChristmasMiniMachine:addLastWinSomeEffect() -- add big win or mega win
end

function MerryChristmasMiniMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()

    local isFiveOfKind = self:lineLogicWinLines()
end

function MerryChristmasMiniMachine:stopMiniScatterAct()
    local collectList = self:getCollectList()

    if collectList then
        for i = 1, #collectList do
            local node = collectList[i]
            node:runAnim("idleframe")
        end
    end
end

function MerryChristmasMiniMachine:getCollectList()
    local collectList = {}

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local reelsIndex = self:getPosReelIdx(iRow, iCol)
            local isHave = self:getHaveScatter(reelsIndex)
            if isHave then
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if node then
                    collectList[#collectList + 1] = node
                end
            end
        end
    end
    if collectList and #collectList > 0 then
        return collectList
    end
end

function MerryChristmasMiniMachine:checkIsHaveScatter()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isHave = false
    if selfData and selfData.scatters then
        local scatters = selfData.scatters
        if scatters and #scatters > 0 then
            isHave = true
        end
    end
    return isHave
end

-- 设置自定义游戏事件
function MerryChristmasMiniMachine:restSelfEffect(selfEffect)
    for i = 1, #self.m_gameEffects, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and effectData.p_selfEffectType == selfEffect then
            effectData.p_isPlay = true
            self:playGameEffect()

            break
        end
    end
end

function MerryChristmasMiniMachine:creatflyScatter()
    local csb = util_createAnimation("Socre_MerryChristmas_Scatter_tips.csb")
    csb:setScale(0.5)
    return csb
end

function MerryChristmasMiniMachine:runCollectScatterEffect()
    local collectList = self:getCollectList()
    if collectList and #collectList > 0 then
        local endNode = self.m_parent:getFsCollectNode()
        local endWorldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))

        local moveTimes = 0.5
        for i = 1, #collectList do
            local node = collectList[i]

            local flyNode = self:creatflyScatter()
            flyNode:runCsbAction("idle", true)
            self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)

            local pos = cc.p(util_getConvertNodePos(node.m_scatterTag, flyNode))

            flyNode:setPosition(pos)
            node:removeScatterTag()
            local firstMovePos = cc.p(cc.p((pos.x - 180), (pos.y + 70)))
            -- local endPos = flyNode:getParent():convertToNodeSpace(cc.p(endWorldPos.x, endWorldPos.y))

            local actList = {}
            local bezier = {}
            bezier[1] = cc.p(pos.x, pos.y)
            bezier[2] = cc.p(firstMovePos.x, firstMovePos.y - 150)
            bezier[3] = firstMovePos
            actList[#actList + 1] = cc.DelayTime:create(0.2)
            actList[#actList + 1] =
                cc.CallFunc:create(
                function()
                    flyNode:runCsbAction(
                        "buling2",
                        false,
                        function()
                            flyNode:removeFromParent()
                        end
                    )
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
            )

            actList[#actList + 1] = cc.BezierTo:create(0.3, bezier)
            actList[#actList + 1] =
                cc.CallFunc:create(
                function()
                    performWithDelay(
                        self,
                        function()
                            local wei = self:creatflyTouWei2()
                            self.m_parent:addChild(wei, GAME_LAYER_ORDER.LAYER_ORDER_TOP)
                            local worldPos = self:convertToWorldSpace(firstMovePos)
                            local startPos = wei:getParent():convertToNodeSpace(worldPos)
                            wei:setPosition(startPos)

                            local actionList1 = {}
                            actionList1[#actionList1 + 1] = cc.DelayTime:create(0.2)
                            actionList1[#actionList1 + 1] = cc.MoveTo:create(0.5, endWorldPos)
                            actionList1[#actionList1 + 1] = cc.DelayTime:create(0.2)
                            actionList1[#actionList1 + 1] =
                                cc.CallFunc:create(
                                function()
                                    wei:removeFromParent()
                                end
                            )
                            local sq = cc.Sequence:create(actionList1)
                            wei:runAction(sq)
                        end,
                        16 / 30
                    )
                end
            )
            local sq = cc.Sequence:create(actList)
            flyNode:runAction(sq)
        end

        scheduler.performWithDelayGlobal(
            function()
                self.m_parent:playCollectScatterEffect()
            end,
            2.0,
            self:getModuleName()
        )
    else
        self.m_parent:playCollectScatterEffect()
    end
end

function MerryChristmasMiniMachine:creatflyTouWei()
    local csb = util_createAnimation("Socre_MerryChristmas_tuowei1.csb")
    local particle1 = csb:findChild("tuoweishuye")
    local particle2 = csb:findChild("tuoweilizi")
    local particle3 = csb:findChild("tuoweishizi")
    particle1:setPositionType(0)
    particle2:setPositionType(0)
    particle3:setPositionType(0)
    particle1:resetSystem()
    particle2:resetSystem()
    particle3:resetSystem()
    return csb
end

function MerryChristmasMiniMachine:creatflyTouWei2()
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
    particle1:resetSystem()
    particle2:resetSystem()
    particle3:resetSystem()
    particle4:resetSystem()
    particle5:resetSystem()
    particle6:resetSystem()
    return csb
end

--显示scatter所在位置
function MerryChristmasMiniMachine:updateReelGridNode(node)
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

function MerryChristmasMiniMachine:createScatterTag(node)
    if node.m_scatterTag == nil then
        local scatterTag = util_createAnimation("Socre_MerryChristmas_Scatter_tips.csb")
        scatterTag:setScale(0.5)
        scatterTag:setPosition(100, -30)
        node.m_scatterTag = scatterTag
        node:addChild(scatterTag, 100)
    end
end

--寻找scatter位置
function MerryChristmasMiniMachine:getHaveScatter(reelsIndex)
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

--单列滚动停止回调
--
function MerryChristmasMiniMachine:slotOneReelDown(reelCol)
    BaseMiniMachine.slotOneReelDown(self, reelCol)
    for iRow = 1, self.m_iReelRowNum do
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
            end
        end
    end
end

return MerryChristmasMiniMachine
