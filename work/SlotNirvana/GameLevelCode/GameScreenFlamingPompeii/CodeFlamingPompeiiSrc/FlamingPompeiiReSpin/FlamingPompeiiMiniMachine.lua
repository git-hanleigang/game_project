local BaseMiniMachine = require "Levels.BaseMiniMachine"
local FlamingPompeiiMiniMachine = class("FlamingPompeiiMiniMachine", BaseMiniMachine)
local GameEffectData = require "data.slotsdata.GameEffectData"
local FlamingPompeiiPublicConfig = require "FlamingPompeiiPublicConfig"

-- 构造函数
function FlamingPompeiiMiniMachine:ctor()
    FlamingPompeiiMiniMachine.super.ctor(self)

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_chipList = {}

    self.m_reSpinRow = 4
    --是否有特殊bonus参与触发reSpin
    self.m_bSpecialReSpin = false
    --特殊bonus金额
    self.m_specialMulti = 0
end
--[[
    data = {
        machine

    }
]]
function FlamingPompeiiMiniMachine:initData_(data)
    self.m_machine = data.machine

    --init
    self:initGame()
    self:initUI()
end

function FlamingPompeiiMiniMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FlamingPompeiiMiniConfig.csv", "LevelFlamingPompeiiCSVData.lua")
    self.m_moduleName = self:getModuleName()
    --初始化基本数据
    self:initMachine(self.m_moduleName)

    if self.m_touchSpinLayer then
        local bottomUi = self.m_machine.m_bottomUI
        local spinBtn  = bottomUi.m_spinBtn
        spinBtn:addTouchLayerClick(self.m_touchSpinLayer)
    end
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FlamingPompeiiMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FlamingPompeii"
end
--小块
function FlamingPompeiiMiniMachine:getBaseReelGridNode()
    return "CodeFlamingPompeiiSrc.FlamingPompeiiSlotNode"
end

-- 读取配置文件数据
function FlamingPompeiiMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData("FlamingPompeiiMiniConfig.csv")
    end
end

function FlamingPompeiiMiniMachine:initMachineCSB()
    self:createCsbNode("FlamingPompeii_reSpinReel.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end
function FlamingPompeiiMiniMachine:initUI()
    self.m_clipLayer = self:findChild("Panel_symbolClip")
    self.m_clipLayer:setClippingEnabled(false)
end
function FlamingPompeiiMiniMachine:initUIList(_uiList)
    --[[
        _uiList = {
            topBonus       = csb,
            reSpinBar      = csb,
            commonTopReel  = miniMachine,
            specialTopReel = miniMachine,
            reSpinTip      = csb,
        }
    ]]
    self.m_topBonus       = _uiList.topBonus
    self.m_reSpinBar      = _uiList.reSpinBar
    self.m_commonTopReel  = _uiList.commonTopReel
    self.m_specialTopReel = _uiList.specialTopReel
    self.m_reSpinTip      = _uiList.reSpinTip
    
    
    --上一次展示的buffReel
    self.m_lastBuffReelType = nil
end

function FlamingPompeiiMiniMachine:onEnter()
    FlamingPompeiiMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end
function FlamingPompeiiMiniMachine:initGridList(isFirstNoramlReel)
    FlamingPompeiiMiniMachine.super.initGridList(self, isFirstNoramlReel)
    
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        self.m_machine:changeFlamingPompeiiSlotsNodeType(_slotsNode, self.m_machine.SYMBOL_Blank)
    end)
end

function FlamingPompeiiMiniMachine:onExit()
    FlamingPompeiiMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function FlamingPompeiiMiniMachine:addObservers()
    FlamingPompeiiMiniMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:MachineRule_respinTouchSpinBntCallBack()
        end,
        ViewEventType.RESPIN_TOUCH_SPIN_BTN
    )
    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:reSpinReelDown()
        end,
        ViewEventType.NOTIFY_RESPIN_RUN_STOP
    )
end




--[[
    游戏暂停
]]
function FlamingPompeiiMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FlamingPompeiiMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function FlamingPompeiiMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end
--[[
    reSpinBar
]]
--ReSpin刷新数量
function FlamingPompeiiMiniMachine:changeReSpinUpdateUI(_curCount)
    local totalCount = self.m_reSpinBar.m_totalReSpinCount
    local curCount = totalCount - _curCount
    self:updateReSpinBar(curCount, totalCount)
end
function FlamingPompeiiMiniMachine:updateReSpinBar(_curCount, _totalCount)
    self.m_reSpinBar:showTimes(_curCount, _totalCount)
end
function FlamingPompeiiMiniMachine:addReSpinTimes(_addTimes)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_reSpinTimes_add)
    
    local curCount   = self.m_reSpinBar.m_curReSpinCount
    local totalCount = self.m_reSpinBar.m_totalReSpinCount + _addTimes
    self.m_reSpinBar:showTimes(curCount, totalCount)
    self.m_reSpinBar:playAddTimesAnim() 
end
--[[
    reSpin相关
]]
-- 继承底层respinView
function FlamingPompeiiMiniMachine:getRespinView()
    return "CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiRespinView"
end
-- 继承底层respinNode
function FlamingPompeiiMiniMachine:getRespinNode()
    return "CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiRespinNode"
end

-- 根据本关卡实际小块数量填写
function FlamingPompeiiMiniMachine:getRespinRandomTypes()
    local symbolList = {
        self.m_machine.SYMBOL_Blank,
        self.m_machine.SYMBOL_Bonus1,
        self.m_machine.SYMBOL_Bonus2,
    }
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function FlamingPompeiiMiniMachine:getRespinLockTypes()
    --落地效果移入代码内 手动在回弹时播放
    local symbolList = {
        {type = self.m_machine.SYMBOL_Bonus1, runEndAnimaName = "", bRandom = false},
        {type = self.m_machine.SYMBOL_Bonus2, runEndAnimaName = "", bRandom = false},
    }

    return symbolList
end


-- 触发时重置一下轮盘数据和展示
function FlamingPompeiiMiniMachine:initTriggerReel(_initData)
    --[[
        _initData = {
            reSpinCount       = 0,
            reSpinTotalCount  = 0,
            rsExtraData       = {},

            
            reSpinStoredIcons = {}
            reSpinRow         = 4
        }
    ]]
    --
    self.m_reSpinRow    = _initData.rsExtraData.rows
    self.m_specialMulti = _initData.rsExtraData.specialbonus or 0
    local addMultiList  = _initData.rsExtraData.addcredit or {}
    self:initReSpinTriggerReelSymbol(_initData.rsExtraData.reels, _initData.reSpinStoredIcons, addMultiList)
    -- reSpin 数据
    self.m_runSpinResultData.p_rsExtraData       = _initData.rsExtraData
    self.m_runSpinResultData.p_resWinCoins = 0
    self.m_runSpinResultData.p_reSpinCurCount    = _initData.reSpinCount
    self.m_runSpinResultData.p_reSpinsTotalCount = _initData.reSpinTotalCount
    self.m_runSpinResultData.p_reSpinStoredIcons = _initData.reSpinStoredIcons
    self.m_runSpinResultData.p_storedIcons       = _initData.reSpinStoredIcons
    --刷新次数
    local curCount = self.m_runSpinResultData.p_reSpinsTotalCount - self.m_runSpinResultData.p_reSpinCurCount
    self:updateReSpinBar(curCount, self.m_runSpinResultData.p_reSpinsTotalCount)
end
function FlamingPompeiiMiniMachine:initReSpinTriggerReelSymbol(_reels, _storedIcons, _addMultiList)
    local curBet   = globalData.slotRunData:getCurTotalBet()

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local slotsNode = self.m_respinView:getFlamingPompeiiSymbolNode(iRow, iCol)
            local symbolType = self.m_machine.SYMBOL_Blank
            local lineIndex  = self.m_iReelRowNum - iRow + 1
            local lineData   = _reels[lineIndex]
            if nil ~= lineData then
                symbolType = lineData[iCol]
            end
            local bBonus = self.m_machine:isFlamingPompeiiBonusSymbol(symbolType)
            -- 只要bonus
            if not bBonus then
                symbolType = self.m_machine.SYMBOL_Blank
            end
            self.m_machine:changeFlamingPompeiiSlotsNodeType(slotsNode, symbolType)

            -- 锁定状态变更
            local reSpinNode = self.m_respinView:getRespinNode(iRow, iCol)
            local iStatus = bBonus and RESPIN_NODE_STATUS.LOCK or RESPIN_NODE_STATUS.IDLE
            reSpinNode:setRespinNodeStatus(iStatus)
            if bBonus then
                local worldPos = slotsNode:getParent():convertToWorldSpace(cc.p(slotsNode:getPositionX(), slotsNode:getPositionY()))
                local pos = self.m_respinView:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                local bonusOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 10 * slotsNode.p_cloumnIndex - slotsNode.p_rowIndex
                util_changeNodeParent(self.m_respinView, slotsNode, bonusOrder)
                slotsNode:setTag(self.m_respinView.REPIN_NODE_TAG)
                slotsNode:setPosition(pos)
            else
                reSpinNode:setFirstSlotNode(slotsNode)
            end
            
            --刷新bonus图标的奖励
            if bBonus then
                local animNode = slotsNode:getCCBNode()
                local slotCsb  = animNode.m_slotCsb
                --
                local reelIndex = self:getPosReelIdx(iRow, iCol)
                local multi,multiType = self.m_machine:getMultiDataByList(_storedIcons, reelIndex)
                --是否是特殊形态jackpot+奖金
                local addMulti    = _addMultiList[reelIndex+1] or 0
                local addCoins    = curBet * addMulti
                local newBSpecial = "" ~= multiType and 0 ~= addMulti
                self.m_machine:upDateSlotsBonusJackpotAndCoins(slotsNode, multi, multiType, addMulti)
                self.m_machine:playBonusSymbolBreathingAnim(slotsNode)
                if newBSpecial then
                    local labCoins = slotCsb:findChild("m_lb_coins_2")
                    self.m_machine:upDateBonusSymbolCoinsLab(labCoins, addCoins)
                    labCoins:setVisible(true)
                end
            end
            if not self.m_runSpinResultData.p_reels[lineIndex] then
                self.m_runSpinResultData.p_reels[lineIndex] = {}
            end
            self.m_runSpinResultData.p_reels[lineIndex][iCol] = symbolType
        end
    end
    self:playAllReSpinNodeBreathingAnim()
end
function FlamingPompeiiMiniMachine:playReSpinUiStartAnim()
    local bFirstReSpin = self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount

    self.m_reSpinBar:setVisible(true)
    self.m_reSpinBar:playStartAnim()
    if bFirstReSpin then
        self.m_clipLayer:setClippingEnabled(true)
        self.m_reSpinTip:playIdleAnim()
    end
end
function FlamingPompeiiMiniMachine:playReSpinUiOverAnim()
    self.m_reSpinBar:playOverAnim(function()
        self.m_reSpinBar:setVisible(false)
    end)
    self:playBuffReelOverAnim(self.m_lastBuffReelType, function()
        
    end)

    self:setReSpinReelPosY(4, false)
    -- 不移除循环使用
    -- self:removeRespinNode()
    self.m_runSpinResultData.p_rsExtraData.specialcase = {}
end

--提前创建
function FlamingPompeiiMiniMachine:initMiniRespinView()
    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()
    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()
    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()
    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

function FlamingPompeiiMiniMachine:readyReSpinMove()
    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    local bFirstReSpin = self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount
    if bFirstReSpin then
        --设置弹板关闭回调
        self.m_reSpinTip:setOverCallBack(function()
            self.m_clipLayer:setClippingEnabled(false)
            self:playReSpinStartSpecialBonusAnim(function()
                self:upDateBuffNode(self.m_runSpinResultData.p_rsExtraData.specialcase, self.m_runSpinResultData.p_rsExtraData.specialcase, function()
                    self:playreSpinStartSpecialBonusOverAnim(function()
                        self:playCommonBuffReelFadeIn(function()
                            self:runNextReSpinReel()
                        end)
                    end)
                end)
            end)
        end)
        self.m_reSpinTip:startCountDown()
    else
        self:playCommonBuffReelFadeIn(function()
            self:upDateBuffNode(self.m_runSpinResultData.p_rsExtraData.specialcase, self.m_runSpinResultData.p_rsExtraData.specialcase, function()
                self:runNextReSpinReel()
            end)
        end)
    end

    self.m_respinView:changeReSpinNodeVisibleByLine(self.m_reSpinRow)
    --reSpinNode加滚调整
    self.m_respinView:upDateReSpinNodeReelData()
end
function FlamingPompeiiMiniMachine:playAllReSpinNodeBreathingAnim()
    local lockList = self.m_respinView:getLockSymbolList()
    for i,_bonusNode in ipairs(lockList) do
        self.m_machine:playBonusSymbolBreathingAnim(_bonusNode)
    end
end

--进入reSpin特殊bonus飞上顶部
function FlamingPompeiiMiniMachine:playReSpinStartSpecialBonusAnim(_fun)
    local specialBonusList = self.m_respinView:getSymbolList(self.m_machine.SYMBOL_Bonus1)
    local delayTime = 0
    if #specialBonusList > 0 then
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_topBonusFly)

        local flyTime  = 0.3
        local animTime = 2
        local overTime = 15/60
        delayTime = flyTime + animTime + overTime

        local endNode = self.m_machine:findChild("Node_zhanshi")
        local endPos  = util_convertToNodeSpace(endNode, self)
        local allMulti = 0
        for i,_slotsNode in ipairs(specialBonusList) do
            local iCol = _slotsNode.p_cloumnIndex
            local iRow = _slotsNode.p_rowIndex
            --临时bonus图标
            local flyNode = self.m_machine:createFlamingPompeiiTempSymbol(_slotsNode.p_symbolType, {})
            self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
            -- 锁定状态变更
            local reSpinNode = self.m_respinView:getRespinNode(iRow, iCol)
            local bStatus = false
            local iStatus = bStatus and RESPIN_NODE_STATUS.LOCK or RESPIN_NODE_STATUS.IDLE
            reSpinNode:setRespinNodeStatus(iStatus)
            if not bStatus then
                reSpinNode:setFirstSlotNode(_slotsNode)
                self.m_machine:changeFlamingPompeiiSlotsNodeType(_slotsNode, self.m_machine.SYMBOL_Blank)
            end

            local multi,multiType = self.m_machine:getReSpinSymbolMulti(self:getPosReelIdx(iRow, iCol))
            allMulti = allMulti + multi
            self.m_machine:upDateSlotsBonusJackpotAndCoins(flyNode, multi, multiType)
            self.m_machine:playBonusSymbolBreathingAnim(flyNode)
            flyNode:setPosition(util_convertToNodeSpace(_slotsNode, self))
            --飞行动作
            local actList ={}
            table.insert(actList, cc.MoveTo:create(flyTime, endPos))
            table.insert(actList, cc.RemoveSelf:create())
            
            flyNode:runAnim("actionframe_shang", false, function()
                flyNode:removeTempSlotsNode()
            end)

            flyNode:runAction(cc.Sequence:create(actList))
        end
        --停留的bonus图标
        local bonusNode = self.m_topBonus.m_bonusNode
        self.m_machine:upDateSlotsBonusJackpotAndCoins(bonusNode, allMulti, "") 
        self.m_topBonus:runAction(cc.Sequence:create(
            cc.DelayTime:create(flyTime),
            cc.CallFunc:create(function()
                gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_topBonusFlyOver)
                self.m_topBonus:runCsbAction("start")
                bonusNode:runAnim("actionframe", false, function()
                    self.m_machine:playBonusSymbolBreathingAnim(bonusNode)
                end)
                self.m_topBonus:setVisible(true)
            end)
        ))
    end
    
    self.m_machine:levelPerformWithDelay(self, delayTime, _fun)
end

function FlamingPompeiiMiniMachine:playreSpinStartSpecialBonusOverAnim(_fun)
    --停留的bonus图标
    local bonusNode = self.m_topBonus.m_bonusNode
    self.m_topBonus:runCsbAction("over", false, function()
        self.m_topBonus:setVisible(false)
        _fun()
    end)
end

function FlamingPompeiiMiniMachine:playCommonBuffReelFadeIn(_fun)
    local symbolType = self.m_machine.SYMBOL_Bonus2
    self:playBuffReelStartAnim(symbolType, _fun)
end

function FlamingPompeiiMiniMachine:shakeReelNode(_params)
    _params = _params or {}
    --随机幅度
    local changeMin     = 3
    local changeMax     = 10
    local shakeTimes    = _params.shakeTimes or 4
    local shakeOnceTime = _params.shakeOnceTime or 0.2

    local shakeNodeName = _params.shakeNodeName or {
        "Node_spinTimesBar",
        "Node_qipan",
        "Node_reSpinReel",
        "Node_randomSymbol",
        "Layer_lockBonus",
    }
    for i,_nodeName in ipairs(shakeNodeName) do
        local shakeNode = self.m_machine:findChild(_nodeName)
        local oldPos = cc.p(shakeNode:getPosition())
        local changePosY = math.random(changeMin, changeMax)
        local changePosX = math.random(changeMin, changeMax)
        local actList = {}
        for ii=1,shakeTimes do
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x + changePosX, oldPos.y + changePosY)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x, oldPos.y)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x - changePosX, oldPos.y - changePosY)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x, oldPos.y)))
        end
        table.insert(actList, cc.CallFunc:create(function()
            shakeNode:setPosition(oldPos)
        end))
        shakeNode:runAction(cc.Sequence:create(actList))
    end
end

function FlamingPompeiiMiniMachine:playFlameAnim(_reSpinNode)
    local flameSpine = util_spineCreate("FlamingPompeii_huoyan",true,true)
    self:addChild(flameSpine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    flameSpine:setPosition(util_convertToNodeSpace(_reSpinNode, self))
    local animName = "actionframe"
    util_spinePlay(flameSpine, animName, true)
    util_spineEndCallFunc(flameSpine, animName, function()
        flameSpine:setVisible(false)
        performWithDelay(flameSpine,function()
            flameSpine:removeFromParent()
        end,0)
    end)
    -- 第18帧出buff格子
    self.m_machine:levelPerformWithDelay(_reSpinNode, 18/30, function()
        _reSpinNode:playBuffStartAnim()
    end)
end

---判断结算
function FlamingPompeiiMiniMachine:reSpinReelDown(addNode)
    --有新掉落的bonus
    if #self.m_respinView.m_newLockPosList > 0 then
        self:addReSpinTimes(1)
    end
    
    --添加执行事件
    self:addReSpinGameEffect()
    self:playReSpinGameEffect(function()
        self:FlamingPompeiiMiniReSpinReelDown()
    end)
end
--重写底层 reSpinReelDown
function FlamingPompeiiMiniMachine:FlamingPompeiiMiniReSpinReelDown()
    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        --quest
        self:updateQuestBonusRespinEffectData()
        --结束
        self:reSpinEndAction()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false
        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end

    --继续
    self:runNextReSpinReel()

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end
function FlamingPompeiiMiniMachine:addReSpinGameEffect()
    self.m_reSpinGameEffectList = {}

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    -- buff转盘玩法-普通
    local buffBonusList = rsExtraData.wheelkinds or {}
    -- buff转盘玩法-特殊
    local specialBuffBonusList = rsExtraData.specialwheelkinds or {}

    if #buffBonusList + #specialBuffBonusList > 0 then
        table.insert(self.m_reSpinGameEffectList, {effectType = 1})
    end
    -- 新的buff格子
    local newSpecialcase = rsExtraData.newSpecialcase or {}
    if #newSpecialcase > 0 then
        table.insert(self.m_reSpinGameEffectList, {effectType = 2})
    end
end
function FlamingPompeiiMiniMachine:playReSpinGameEffect(_fun)
    if #self.m_reSpinGameEffectList < 1 then
        _fun()
        return
    end
    
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local reSpinGameEffect = table.remove(self.m_reSpinGameEffectList, 1)
    if 1 == reSpinGameEffect.effectType then
        self:playReSpinEffectBuffReel(0, self.m_lastBuffReelType, function()
            self:playReSpinGameEffect(_fun)
        end)
    elseif 2 == reSpinGameEffect.effectType then
        self:playReSpinEffectNewBuffCell(function()
            self:playReSpinGameEffect(_fun)
        end)
    end
end

--[[
    buff触发转盘
]]
function FlamingPompeiiMiniMachine:playReSpinEffectBuffReel(_posIndex, _lastSymbolType,_fun)
    local buffData,symbolType = self:getBuffDataAndSymbolType(_posIndex)
    local maxPosIndex = self.m_iReelColumnNum * self.m_iReelRowNum - 1
    while not buffData and _posIndex <= maxPosIndex do
        _posIndex = self:getNextPosIndex(_posIndex)
        buffData,symbolType = self:getBuffDataAndSymbolType(_posIndex)
    end

    if not buffData then
        _fun()
        return
    elseif nil ~= _lastSymbolType and symbolType ~= _lastSymbolType then
        self:playBuffReelOverAnim(_lastSymbolType, function()
            self:playBuffReelStartAnim(symbolType, function()
                self:playReSpinEffectBuffReel(_posIndex, symbolType, _fun)
            end)
        end)
        return
    elseif nil == _lastSymbolType then
        self:playBuffReelStartAnim(symbolType, function()
            self:playReSpinEffectBuffReel(_posIndex, symbolType, _fun)
        end)
        return
    end
    --区分轮盘
    local bCommon  = self.m_machine:isFlamingPompeiiCommonBonusSymbol(symbolType)
    local finalSymbolType = bCommon and 100 + buffData[2] or self.m_machine.SYMBOL_Buff2_bonus
    local buffReel = bCommon and self.m_commonTopReel or self.m_specialTopReel
    local fixPos = self:getRowAndColByPos(buffData[1]) 
    --特殊bonus转盘修改当前位置的bonus奖励
    local changeFixPos    = self:getRowAndColByPos(buffData[1]) 
    local changeBonusNode = self.m_respinView:getFlamingPompeiiSymbolNode(changeFixPos.iX, changeFixPos.iY)
    local curWinData = self.m_machine:getBonusLabWinData(changeBonusNode)
    -- bonus高亮
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bonus_triggerBuffReel)
    local slotsNode = self.m_respinView:getFlamingPompeiiSymbolNode(fixPos.iX, fixPos.iY)
    self.m_respinView:changeBonusNodeOrder(slotsNode, true)
    slotsNode:runAnim("start", false, function()
        slotsNode:runAnim("idle", false, function()
            --光同时消失
            slotsNode:runAnim("over", false, function()
                self.m_machine:playBonusSymbolBreathingAnim(slotsNode)
            end)
        end)
    end)
    -- 背景发光
    buffReel:playBgLightAnim_start()
    --滚动->停轮
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_run)
    buffReel:startMove()
    self.m_machine:levelPerformWithDelay(self, 1+1, function()
        buffReel:stopMove({
            curMultip    = curWinData.multip,
            curMultiType = curWinData.multipType,
            symbolType   = finalSymbolType,
            serverData   = buffData,
            nextFun = function()
                gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_stop)
               
                --中心爆光
                buffReel:playBgLightLiZiOverAnim(function()
                end)
                --中心光圈
                buffReel:playReelAnim_animation(function()
                    --添加奖励到棋盘
                    self:addBuffRewardToReel(symbolType, buffData, function()
                        self.m_respinView:changeBonusNodeOrder(slotsNode, false)
                        self:hideReSpinEffectNewBuffCell(fixPos.iX, fixPos.iY ,function()
                            self:playReSpinEffectBuffReel(self:getNextPosIndex(_posIndex), symbolType, _fun)
                        end)
                    end)
                end)
                --消散
                buffReel:playBgLightAnim_over(function()         
                end)
            end
        })   
    end)
end
function FlamingPompeiiMiniMachine:getNextPosIndex(_curPosIndex)
    -- -- 左右 上下
    -- local nextPosIndex = _curPosIndex
    -- local fixPos = self:getRowAndColByPos(_curPosIndex)
    -- if fixPos.iX > 1 then
    --     nextPosIndex = self:getPosReelIdx(fixPos.iX - 1, fixPos.iY)
    -- elseif fixPos.iY < self.m_iReelColumnNum then
    --     nextPosIndex = self:getPosReelIdx(self.m_iReelRowNum, fixPos.iY + 1)
    -- else
    --     --越界了
    --     nextPosIndex = self.m_iReelColumnNum * self.m_iReelRowNum
    -- end

    local nextPosIndex = _curPosIndex + 1
    return nextPosIndex
end
function FlamingPompeiiMiniMachine:getBuffDataAndSymbolType(_posIndex)
    --[[
        buffData = {触发格子，触发类型(1~5)，具体效果，效果位置}
    ]]
    local rsExtraData   = self.m_runSpinResultData.p_rsExtraData
    local buffBonusList = rsExtraData.wheelkinds or {}
    local specialBuffBonusList = rsExtraData.specialwheelkinds or {}
    local symbolType = nil
    local buffData   = nil
    for i,_buffData in ipairs(buffBonusList) do
        if _posIndex == _buffData[1] then
            buffData   = _buffData
            symbolType = self.m_machine.SYMBOL_Bonus2
            return buffData,symbolType
        end
    end
    for i,_buffData in ipairs(specialBuffBonusList) do
        if _posIndex == _buffData[1] then
            buffData   = _buffData
            symbolType = self.m_machine.SYMBOL_Bonus1
            return buffData,symbolType 
        end
    end
    return buffData,symbolType
end
function FlamingPompeiiMiniMachine:playBuffReelStartAnim(_symbolType, _fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_start)

    self.m_lastBuffReelType = _symbolType
    local bCommon  = self.m_machine:isFlamingPompeiiCommonBonusSymbol(_symbolType)
    local buffReel = bCommon and self.m_commonTopReel or self.m_specialTopReel
    buffReel:setVisible(true)
    buffReel:playReelAnim_start(_fun)
end
function FlamingPompeiiMiniMachine:playBuffReelOverAnim(_symbolType, _fun)
    local bCommon  = self.m_machine:isFlamingPompeiiCommonBonusSymbol(_symbolType)
    local buffReel = bCommon and self.m_commonTopReel or self.m_specialTopReel
    buffReel:playReelAnim_over(function()
        buffReel:setVisible(false)
        _fun()
    end)
    self.m_lastBuffReelType = nil
end
function FlamingPompeiiMiniMachine:addBuffRewardToReel(_symbolType, _buffData, _fun)
    --[[
        _buffData = {触发格子，触发类型，具体效果，效果位置}
    ]]
    if self.m_machine:isFlamingPompeiiCommonBonusSymbol(_symbolType) then
        --随机bonus乘倍
        if 1 == _buffData[2] then
            self:addBuffReward_multi(_buffData, _fun)
        --升行
        elseif 2 == _buffData[2] then
            self:addBuffReward_upRow(_buffData, _fun)
        --增加spin次数
        elseif 3 == _buffData[2] then
            self:addBuffReward_addSpinTimes(_buffData, _fun)
        --所有bonus结算一次
        elseif 4 == _buffData[2] then
            self:addBuffReward_settlementBonusCoins(_buffData, _fun)
        --所有bonus钱数增加
        elseif 5 == _buffData[2] then
            self:addBuffReward_addBonusCoins(_buffData, _fun)
        else
            _fun()
        end
    else
        --触发位置随机乘倍 | 触发位置随机变为jackpot
        if 1 == _buffData[2] or 2 == _buffData[2] then
            self:addBuffReward_changeBonusReward(_buffData, _fun)
        else
            _fun()
        end
    end
end
function FlamingPompeiiMiniMachine:addBuffReward_multi(_buffData, _fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_fly)

    local iPos      = _buffData[4]
    local fixPos    = self:getRowAndColByPos(iPos)
    local slotsNode = self.m_respinView:getFlamingPompeiiSymbolNode(fixPos.iX, fixPos.iY)
    local rewardParems = {
        bonusMulti = _buffData[3]
    }
    --移动参数
    local flyTime    = 30/60
    local startPos = util_convertToNodeSpace(self.m_commonTopReel, self)
    local endPos   = util_convertToNodeSpace(slotsNode, self)
    --乘倍图标飞行
    local flyNode = self.m_machine:createFlamingPompeiiTempSymbol(self.m_machine.SYMBOL_Buff1_multi,{})
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    flyNode:setScale(1.2)
    flyNode:setPosition(startPos)
    local label   = flyNode:getCcbProperty("m_lb_num")
    local sReward = string.format("X%d", _buffData[3])
    label:setString(sReward)
    self.m_machine:updateLabelSize({label=label, sx=0.7, sy=0.7}, 90)
    flyNode:runAnim("actionframe", false)
    --[[
        三段飞
        0~15  飞 20%
        15~36 飞 50%
        36～45 飞 30%
    ]]
    local length = math.sqrt(math.pow(endPos.x - startPos.x, 2) +  math.pow(endPos.y - startPos.y, 2))
    local rotation = util_getAngleByPos(startPos, endPos)
    local actList  = {}
    table.insert(actList, cc.MoveTo:create(15/60, cc.p(util_getCirclePointPos(startPos.x, startPos.y, length * 0.2, rotation)))) 
    table.insert(actList, cc.MoveTo:create(21/60, cc.p(util_getCirclePointPos(startPos.x, startPos.y, length * 0.7, rotation)))) 
    table.insert(actList, cc.MoveTo:create(9/60, endPos)) 
    table.insert(actList, cc.CallFunc:create(function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_flyOver)
        --爆光
        local bonusSymbol = self.m_machine:createFlamingPompeiiTempSymbol(self.m_machine.SYMBOL_Bonus1,{})
        self:addChild(bonusSymbol, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
        bonusSymbol:setPosition(endPos)
        bonusSymbol:runAnim("actionframe_shang2", false, function()
            bonusSymbol:removeTempSlotsNode()
        end)

        self:playBonusAddBonusCoinsAnim(slotsNode, rewardParems)
        self.m_machine:levelPerformWithDelay(self, 42/60, _fun)
    end)) 
    table.insert(actList, cc.RemoveSelf:create()) 
    flyNode:runAction(cc.Sequence:create(actList))
end
function FlamingPompeiiMiniMachine:addBuffReward_upRow(_buffData, _fun)
    local upRowCount = _buffData[3]
    local curRow     = self.m_reSpinRow
    local nextRow    = curRow + upRowCount

    if 1 == upRowCount then
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_upRow1)
    elseif 2 == upRowCount then
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_upRow2)
    end
    self.m_respinView:changeReSpinNodeVisibleByLine(nextRow)
    --震动
    local shakeTime  = 0.5
    local shakeOnceTime = 0.25
    self:shakeReelNode({
        shakeTimes = math.ceil(shakeTime/shakeOnceTime),
        shakeOnceTime = shakeOnceTime,
    })
    self.m_machine:levelPerformWithDelay(self, shakeTime, function()
        local animTime = self:setReSpinReelPosY(nextRow, true)
        self:shakeReelNode({
            shakeTimes    = math.ceil(animTime/shakeOnceTime),
            shakeOnceTime = shakeOnceTime,
        })
        if nextRow == self.m_iReelRowNum then
            self.m_machine.m_jackpotBar:setShowState("reSpin")
        end
        self.m_reSpinRow = nextRow
        self.m_machine:levelPerformWithDelay(self, animTime, _fun)
    end)
end
function FlamingPompeiiMiniMachine:addBuffReward_addSpinTimes(_buffData, _fun)
    local addTimes = _buffData[3]
    self:addReSpinTimes(addTimes)
    _fun()
end
function FlamingPompeiiMiniMachine:addBuffReward_settlementBonusCoins(_buffData, _fun)
    local symbolList = self.m_respinView:getLockSymbolList()
    self:playBonusCollectActionframe(symbolList, function()
        self:playBonusCollectAnim(1, symbolList, false, function()
            _fun()
        end)
    end)    
end
function FlamingPompeiiMiniMachine:addBuffReward_addBonusCoins(_buffData, _fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_fly)

    local curBet     = globalData.slotRunData:getCurTotalBet() 
    local addMulti   = _buffData[3]
    local symbolList = self.m_respinView:getLockSymbolList()
    local rewardParems = {
        addMulti = addMulti
    }
    --移动参数
    local startPos   = util_convertToNodeSpace(self.m_commonTopReel, self)
    local flyTime    = 42/60

    for i,_slotsNode in ipairs(symbolList) do
        local slotsNode = _slotsNode
        self:playTrailingParticleAnim(
            flyTime, 
            startPos,
            util_convertToNodeSpace(slotsNode, self),
            function()
                --金币上涨
                self:playBonusAddBonusCoinsAnim(slotsNode, rewardParems)
            end
        )
    end
    self.m_machine:levelPerformWithDelay(self, flyTime, function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_flyOver)
    end)


    local delayTime = flyTime + 42/60 + 39/60
    self.m_machine:levelPerformWithDelay(self, delayTime, _fun)
end
--拖尾粒子通用飞行
function FlamingPompeiiMiniMachine:playTrailingParticleAnim(_flyTime, _startPos, _endPos, _fun)
    --飞行粒子
    local flyCsb = util_createAnimation("FlamingPompeii_twlz.csb")
    self:addChild(flyCsb, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    flyCsb:setPosition(_startPos)
    local particleNode = flyCsb:findChild("Particle_1")
    particleNode:stopSystem()
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(_flyTime, _endPos),
        cc.CallFunc:create(function()
            particleNode:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particleNode, true)
            particleNode:runAction(cc.FadeOut:create(0.5))
            _fun()
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
end
--通用bonus奖励增加
function FlamingPompeiiMiniMachine:playBonusAddBonusCoinsAnim(_slotsNode, _rewardParems)
    --[[
        _rewardParems = {
            -- 增加bet倍数的金币
            addMulti   = 1,
            -- 乘倍的类型jackpot
            multiType  = "grand",
            -- bonus本身奖励乘倍
            bonusMulti = 2,
        }
    ]]
    local iCol = _slotsNode.p_cloumnIndex
    local iRow = _slotsNode.p_rowIndex
    local curWinData = self.m_machine:getBonusLabWinData(_slotsNode)
    local curMulti     = curWinData.multip
    local curMultiType = curWinData.multipType
    local curAddMultip = curWinData.addMultip
    local curBSpecial  = "" ~= curMultiType and 0 ~= curAddMultip
    local curBet   = globalData.slotRunData:getCurTotalBet()
    local animNode = _slotsNode:getCCBNode()
    local slotCsb  = animNode.m_slotCsb
    --刷新添加金币上涨csb奖励
    local addmoneyNode      = slotCsb:findChild("Node_addmoney")
    local addMoneyCsb = util_createAnimation("FlamingPompeii_addmoney.csb")
    self:addChild(addMoneyCsb, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    addMoneyCsb:setPosition(util_convertToNodeSpace(addmoneyNode, self))

    --特殊形态jackpot + addCoins
    local newBSpecial  = false
    local newMulti     = curMulti
    local newAddMultip = curAddMultip
    if nil ~= _rewardParems.addMulti then
        newBSpecial = "" ~= curMultiType
        newMulti    = curMulti + _rewardParems.addMulti
        --不是特殊状态的话不计入增加奖金倍数,会直接呈现在金币上.
        newAddMultip   = newBSpecial and curAddMultip + _rewardParems.addMulti or 0
        local addCoins = curBet * _rewardParems.addMulti
        --增加奖励上升，bonus上的金币跳钱到新的奖励
        local labAddCoins = addMoneyCsb:findChild("m_lb_num")
        local sCoins   = util_formatCoins(addCoins, 3)
        sCoins         = string.format("+%s", sCoins)
        labAddCoins:setString(sCoins)
        local labInfo = {label=labAddCoins, sx=0.4, sy=0.4, width = 273}
        self:updateLabelSize(labInfo, labInfo.width)
        labAddCoins:setVisible(true)
        --上涨动画 42/60
        addMoneyCsb:runCsbAction("actionframe", false, function()
            addMoneyCsb:removeFromParent()
        end)
        self.m_machine:upDateSlotsBonusJackpotAndCoins(_slotsNode, newMulti, curMultiType, newAddMultip)

        local labName        = newBSpecial and "m_lb_coins_2" or "m_lb_coins"
        local curAddCoins    = (curBSpecial or newBSpecial) and curBet * curAddMultip or curBet * curMulti
        local targetAddCoins = curAddCoins + addCoins

        local labCoins = slotCsb:findChild(labName)
        labCoins:setVisible(true)
        self:jumpCoins(labCoins, curAddCoins, targetAddCoins, 42/60)
    elseif nil ~= _rewardParems.bonusMulti then
        newMulti = curMulti * _rewardParems.bonusMulti
        local curCoins = curBet * curMulti
        local addCoins = curCoins * (_rewardParems.bonusMulti - 1)
        addCoins = math.max(0, addCoins)

        local labAddCoins = addMoneyCsb:findChild("m_lb_num")
        local sCoins   = util_formatCoins(addCoins, 3)
        sCoins         = string.format("+%s", sCoins)
        labAddCoins:setString(sCoins)
        local labInfo = {label=labAddCoins, sx=0.4, sy=0.4, width = 273}
        self:updateLabelSize(labInfo, labInfo.width)
        labAddCoins:setVisible(true)
        -- 乘倍buff落到特殊状态的bonus上时，只将金币部分跳钱
        local curAddCoins    = curBSpecial and curBet * curAddMultip or curBet * curMulti
        local targetAddCoins = curAddCoins * _rewardParems.bonusMulti
        newAddMultip         = curBSpecial and curAddMultip * _rewardParems.bonusMulti or 0
        local labName        = curBSpecial and "m_lb_coins_2" or "m_lb_coins"

        local labCoins = slotCsb:findChild(labName)
        labCoins:setVisible(true) 
        self:jumpCoins(labCoins, curAddCoins, targetAddCoins, 42/60)
        self.m_machine:levelPerformWithDelay(self, 45/60, function()
            self.m_machine:upDateSlotsBonusJackpotAndCoins(_slotsNode, newMulti, curMultiType, newAddMultip)
        end)
        addMoneyCsb:runCsbAction("actionframe", false, function()
            addMoneyCsb:removeFromParent()
        end)
    end
end
function FlamingPompeiiMiniMachine:jumpCoins(_lab, _curCoins, _targetCoins, _time)
    local offsetValue = _targetCoins - _curCoins
    if offsetValue <= 0 then
        return
    end

    local coinRiseNum =  offsetValue / (_time * 60)
    local sRandomCoinRiseNum   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = math.ceil(tonumber(sRandomCoinRiseNum))  
    schedule(_lab, function()
        _curCoins = _curCoins + coinRiseNum
        _curCoins = math.min(_targetCoins, _curCoins)
        self.m_machine:upDateBonusSymbolCoinsLab(_lab, _curCoins)
        if _curCoins >= _targetCoins then
            _lab:stopAllActions()
        end
    end,0.008)
end

function FlamingPompeiiMiniMachine:upDateBuff2BonusSymbol(_bonusSymbol, _multip, _multiType, _bonusMulti)
    local jpIndex  = self.m_machine.JackpotNameToIndex[_multiType]
    local animNode = _bonusSymbol:getCCBNode()
    local slotCsb  = animNode.m_slotCsb

    if nil ~= jpIndex then
        local jackpotNode = slotCsb:findChild(_multiType)
        jackpotNode:setVisible(true) 
    else
        local bonusMulti = tonumber(_bonusMulti)
        local coins      = _multip * globalData.slotRunData:getCurTotalBet()
        local sCoins     = util_formatCoins(coins, 3)
        local label      = slotCsb:findChild("m_lb_coins")
        label:setString(sCoins)
        local labInfo = {label=label, sx=1, sy=1, width = 117}
        self:updateLabelSize(labInfo, labInfo.width)
        label:setVisible(true) 

        local multiNodeName = string.format("sp_multip_%d", _bonusMulti)
        local multiNode     = slotCsb:findChild(multiNodeName)
        if multiNode then
            multiNode:setVisible(true)
        end
    end
end
function FlamingPompeiiMiniMachine:addBuffReward_changeBonusReward(_buffData, _fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_fly)
    local bJackpot  = 2 == _buffData[2]
    local fixPos    = self:getRowAndColByPos(_buffData[1])
    local slotsNode = self.m_respinView:getFlamingPompeiiSymbolNode(fixPos.iX, fixPos.iY)
    local curWinData = self.m_machine:getBonusLabWinData(slotsNode)
    local curMultip  = curWinData.multip
    local curMultiType  = curWinData.multipType
    local newMultip,newMultiType = curMultip,curMultiType
    if bJackpot then
        newMultip    = _buffData[3]
        newMultiType = _buffData[4]
    else
        newMultip    = curMultip * _buffData[3]
    end
    --飞行bonus
    local flyBonus = self.m_machine:createFlamingPompeiiTempSymbol(self.m_machine.SYMBOL_Bonus1,{})
    self:addChild(flyBonus, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self:upDateBuff2BonusSymbol(flyBonus, newMultip, newMultiType, _buffData[3])
    local startPos   = util_convertToNodeSpace(self.m_commonTopReel, self)
    local endPos     = util_convertToNodeSpace(slotsNode, self)
    flyBonus:setPosition(startPos)
    --[[
        三段飞
        0~12  飞 20%
        12~33 飞 50%
        33～39 飞 30%
    ]]
    local length = math.sqrt(math.pow(endPos.x - startPos.x, 2) +  math.pow(endPos.y - startPos.y, 2))
    local rotation = util_getAngleByPos(startPos, endPos)
    local actList  = {}
    table.insert(actList, cc.MoveTo:create(12/60, cc.p(util_getCirclePointPos(startPos.x, startPos.y, length * 0.2, rotation)))) 
    table.insert(actList, cc.MoveTo:create(21/60, cc.p(util_getCirclePointPos(startPos.x, startPos.y, length * 0.7, rotation)))) 
    table.insert(actList, cc.MoveTo:create(6/60, endPos)) 
    table.insert(actList, cc.CallFunc:create(function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffReel_flyOver)
        --飞到终点后爆炸效果
        self.m_machine:levelPerformWithDelay(self, 3/30, function()
            local animNode = flyBonus:getCCBNode()
            local slotCsb  = animNode.m_slotCsb
            slotCsb:findChild("sp_multip_2"):setVisible(false)
            slotCsb:findChild("sp_multip_3"):setVisible(false)
            slotCsb:findChild("sp_multip_4"):setVisible(false)
        end)
        flyBonus:runAnim("actionframe_shang2", false, function()
            flyBonus:removeTempSlotsNode()
        end)
        
        --刷新bonus奖励
        self.m_machine:upDateSlotsBonusJackpotAndCoins(slotsNode, newMultip,newMultiType)
    end)) 
    local flyTime  = 39/60
    local animTime = 1 
    flyBonus:runAnim("idle_fly", false)
    flyBonus:runAction(cc.Sequence:create(actList))

    local delayTime = flyTime + animTime
    self.m_machine:levelPerformWithDelay(self, delayTime, _fun)
end
--新掉落的bonus是否触发了buff格子
function FlamingPompeiiMiniMachine:isTriggerBuffCell(_iCol, _iRow)
    local posIndex = self:getPosReelIdx(_iRow, _iCol)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    local bTrigger = false
    -- buff转盘玩法-普通
    if not bTrigger then
        local buffBonusList = rsExtraData.wheelkinds or {}
        for i,v in ipairs(buffBonusList) do
            if posIndex == v[1] then
                bTrigger = true
                break
            end
        end
    end
    -- buff转盘玩法-特殊
    if not bTrigger then
        local specialBuffBonusList = rsExtraData.specialwheelkinds or {}
        for i,v in ipairs(specialBuffBonusList) do
            if posIndex == v[1] then
                bTrigger = true
                break
            end
        end
    end
    
    
    return bTrigger
end
--[[
    buff格子变动
]]
function FlamingPompeiiMiniMachine:playReSpinEffectNewBuffCell(_fun)
    local rsExtraData    = self.m_runSpinResultData.p_rsExtraData
    local newSpecialcase = rsExtraData.newSpecialcase or {}
    local buffList       = self.m_runSpinResultData.p_rsExtraData.specialcase
    self:upDateBuffNode(newSpecialcase, buffList, _fun)
end
function FlamingPompeiiMiniMachine:hideReSpinEffectNewBuffCell(_iRow, _iCol, _fun)
    local reSpinNode = self.m_respinView:getRespinNode(_iRow, _iCol)
    local animTime   = reSpinNode:playBuffOverAnim()
    self.m_machine:levelPerformWithDelay(self, animTime, function()
        self.m_respinView:setReSpinNodeOrder(_iRow, _iCol, false)
        _fun()
    end)
end

function FlamingPompeiiMiniMachine:playBuffNodeBgSpine(_fun)
    --抖动
    self:shakeReelNode({shakeNodeName = {"Spine_bgg"} })

    local bgSpine = self.m_machine.m_guochang2Spine_down
    bgSpine:setVisible(true)
    util_spinePlay(bgSpine, "actionframe", false)
    util_spineEndCallFunc(bgSpine, "actionframe", function()
        bgSpine:setVisible(false)
    end)

    local bgSpine2 = self.m_machine.m_guochang2Spine_down2
    bgSpine2:setVisible(true)
    util_spinePlay(bgSpine2, "actionframe2", false)
    util_spineEndCallFunc(bgSpine2, "actionframe2", function()
        bgSpine2:setVisible(false)
    end)

    self.m_machine:levelPerformWithDelay(self, 55/30, _fun)
end
function FlamingPompeiiMiniMachine:upDateBuffNode(_newBuffList, _buffList, _fun)
    self.m_machine:levelPerformWithDelay(self, 1.5, function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_buffCell_start)

        self:playBuffNodeBgSpine(function()
            --buff出现
            local time = 0
            for i,_iPos in ipairs(_newBuffList) do
                local fixPos     = self:getRowAndColByPos(_iPos)
                local reSpinNode = self.m_respinView:getRespinNode(fixPos.iX, fixPos.iY)
                time = reSpinNode:getBuffStartAnimTime()
                -- 火焰 + 出现
                self:playFlameAnim(reSpinNode)
            end
            local posList = {}
            for i,_iPos in ipairs(_buffList) do
                local fixPos     = self:getRowAndColByPos(_iPos)
                table.insert(posList, fixPos)
            end
            self.m_respinView:upDateReSpinNodeOrder(posList)
            local delayTime = 9/30 + time
            self.m_machine:levelPerformWithDelay(self, delayTime, _fun)
        end)
    end)
end

function FlamingPompeiiMiniMachine:reSpinEndAction()
    local symbolList = self.m_respinView:getLockSymbolList()
    self:playBonusCollectActionframe(symbolList, function()
        self:playBonusCollectAnim(1, symbolList, true, function()
            self:respinOver()
        end)
    end)
    --buff格子切换为普通格子
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local buffList    = rsExtraData.specialcase or {}
    for i,_buffPos in ipairs(buffList) do
        local fixPos     = self:getRowAndColByPos(_buffPos)
        local reSpinNode = self.m_respinView:getRespinNode(fixPos.iX, fixPos.iY)
        reSpinNode:playBuffOverAnim()
    end
end
--全体先播一遍触发动画
function FlamingPompeiiMiniMachine:playBonusCollectActionframe(_symbolList, _fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bonus_collectActionframe)

    for i,_slotsNode in ipairs(_symbolList) do
        local slotsNode = _slotsNode
        slotsNode:runAnim("actionframe_jiesuan", false, function()
            self.m_machine:playBonusSymbolBreathingAnim(slotsNode)
        end)
    end

    self.m_machine:levelPerformWithDelay(self, 2 , _fun)
end
function FlamingPompeiiMiniMachine:playBonusCollectAnim(_index , _symbolList, _bDark, _fun)
    local slotsNode = _symbolList[_index]
    if not slotsNode then
        _fun()
        return
    end
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bonus_collect)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local iCol = slotsNode.p_cloumnIndex
    local iRow = slotsNode.p_rowIndex
    local curWinData   = self.m_machine:getBonusLabWinData(slotsNode)
    local curMultip    = curWinData.multip
    local curMultiType = curWinData.multipType
    local bJackpot     = curMultiType and "" ~= curMultiType
    local curBet       = globalData.slotRunData:getCurTotalBet() 
    local reelPos      = self:getPosReelIdx(iRow, iCol)
    local winCoins = 0
    local winLines = self.m_runSpinResultData.p_winLines
    for i,_winData in ipairs(winLines) do
        local iPos = _winData.p_iconPos[1]
        if iPos == reelPos then
            winCoins = _winData.p_amount
        end
    end
    -- if bJackpot then
    --     local jackpotName      = self.m_machine.MultiTypeToJackpotKey[curMultiType]
    --     local jackpotBaseCoins = self.m_runSpinResultData.p_jackpotCoins[jackpotName] or 0
    --     local reelPos          = self:getPosReelIdx(iRow, iCol)
    --     local addMultiList     = rsExtraData.addcredit or {}
    --     local addMulti         = addMultiList[reelPos+1] or 0
    --     local addCoins         = curBet * addMulti
    --     winCoins = jackpotBaseCoins + addCoins
    -- else
    --     winCoins = curBet * curMultip
    -- end
    --图标收集时间线
    local animName = _bDark and "actionframe3" or "actionframe4"
    slotsNode:runAnim(animName, false, function()
        self.m_machine:playBonusSymbolBreathingAnim(slotsNode)
    end)
    local animTime   = 0.4
    --底栏反馈
    local bottomUi   = self.m_machine.m_bottomUI
    local bottomCoins = self.m_machine:getnFlamingPompeiiCurBottomWinCoins()
    self.m_machine:setLastWinCoin(bottomCoins + winCoins)
    bottomUi.m_changeLabJumpTime = animTime
    self.m_machine:updateBottomUICoins(0, winCoins, nil, true)
    bottomUi.m_changeLabJumpTime = nil
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bottomCollectFeedback)
    self.m_machine:playCoinWinEffectUI(nil)
    self.m_machine:levelPerformWithDelay(self, animTime + 0.1, function()
        --jakpot弹板
        if bJackpot then
            self.m_machine:showJackpotView(curMultiType, winCoins, function()
                self:playBonusCollectAnim(_index+1, _symbolList, _bDark, _fun)
            end)
        else
            self:playBonusCollectAnim(_index+1, _symbolList, _bDark, _fun)
        end
    end)
end
function FlamingPompeiiMiniMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:showRespinOverView()
end
-- bonus结束 关闭mini 轮盘
function FlamingPompeiiMiniMachine:showRespinOverView(effectData)
    self:removeGameEffectType(GameEffect.EFFECT_RESPIN)

    self:triggerReSpinOverCallFun(0)
end
-- 触发reSPin结束，不发送更新赢钱事件
function FlamingPompeiiMiniMachine:triggerReSpinOverCallFun(score)
    if nil ~= self.m_reSpinOverCallBack then
        self.m_reSpinOverCallBack()
    end
end

function FlamingPompeiiMiniMachine:setiMiniMachineReSpinOverCallBack(_fun)
    self.m_reSpinOverCallBack = _fun
end







--[[
    升行相关
]]
function FlamingPompeiiMiniMachine:getReSpinReelPosY(_iRow)
    local posY = 0 - (self.m_iReelRowNum -  _iRow) * self.m_SlotNodeH
    return posY
end
function FlamingPompeiiMiniMachine:setReSpinReelPosY(_nextRow, _playAnim)
    local startReelPosY = self:getReSpinReelPosY(4)
    local nextReelPosY  = self:getReSpinReelPosY(_nextRow)
    local offsetPosY    = nextReelPosY - startReelPosY
    local offsetRow     = math.abs(_nextRow - self.m_reSpinRow)
    local oneRowTime    = 0.6
    local moveTime      = oneRowTime * offsetRow

    --棋盘
    local reel = self:findChild("Node_sp_reel")
    if not _playAnim then
        reel:setPositionY(nextReelPosY)
    else
        reel:runAction(cc.MoveTo:create(moveTime, cc.p(0, nextReelPosY)))
    end

    --边框和顶栏
    local reelFrame    = self.m_machine:findChild("Node_reelFrame")
    local reelFrameTop = self.m_machine:findChild("Node_reelFrameTop")
    if not _playAnim then
        reelFrame:setPositionY(offsetPosY)
        reelFrameTop:setPositionY(offsetPosY)
    else
        reelFrame:runAction(cc.MoveTo:create(moveTime, cc.p(0, offsetPosY)))
        reelFrameTop:runAction(cc.MoveTo:create(moveTime, cc.p(0, offsetPosY)))
    end

    --reSpinBar
    if not _playAnim then
        self.m_reSpinBar:setPositionY(offsetPosY)
    else
        self.m_reSpinBar:runAction(cc.MoveTo:create(moveTime, cc.p(0, offsetPosY)))
    end
    
    --buffReel
    if not _playAnim then
        self.m_commonTopReel:setPositionY(offsetPosY)
        self.m_specialTopReel:setPositionY(offsetPosY)
    else
        self.m_commonTopReel:runAction(cc.MoveTo:create(moveTime, cc.p(0, offsetPosY)))
        self.m_specialTopReel:runAction(cc.MoveTo:create(moveTime, cc.p(0, offsetPosY)))
    end
   
    local animTime = _playAnim and moveTime or 0
    return animTime
end
--[[
    模拟滚动
]]
function FlamingPompeiiMiniMachine:beginMiniReel()
    FlamingPompeiiMiniMachine.super.beginReel(self)
end
--更新reSpin小块
function FlamingPompeiiMiniMachine:updateReelGridNode(symblNode)
    self.m_machine:addSpineSymbolCsbNode(symblNode)
    self:upDateBonusReward(symblNode)
end
function FlamingPompeiiMiniMachine:upDateBonusReward(_slotsNode)
    local multi,multiType = 0,""

    local symbolType = _slotsNode.p_symbolType
    if not self.m_machine:isFlamingPompeiiBonusSymbol(symbolType) then
        return
    end

    if not _slotsNode.m_isLastSymbol or  _slotsNode.p_rowIndex > self.m_iReelRowNum then
        local bCommon = self.m_machine:isFlamingPompeiiCommonBonusSymbol(symbolType)
        if bCommon then
            local reSpinReelCfg = self.m_configData
            multi = reSpinReelCfg:getReSpinSymbolRandomMulti()
            self.m_machine:upDateBonusJackpotAndCoins(_slotsNode, multi)
        else
            multi = self.m_specialMulti
            self.m_machine:upDateBonusJackpotAndCoins(_slotsNode, multi)
        end
    else
        local reelIndex = self:getPosReelIdx(_slotsNode.p_rowIndex, _slotsNode.p_cloumnIndex)
        multi,multiType = self.m_machine:getReSpinSymbolMulti(reelIndex)
        self.m_machine:upDateSlotsBonusJackpotAndCoins(_slotsNode, multi, multiType)
    end
end
-- 消息返回
function FlamingPompeiiMiniMachine:netWorkCallFun(param)
    local data = param[2]
    local spinResult = data.result
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:updateNetWorkData()
    --reSpin可以快停
    self.m_machine:setGameSpinStage(GAME_MODE_ONE_RUN)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
end

--[[
    覆盖底层
]]

--事件不能被暂停
-- function FlamingPompeiiMiniMachine:checkGameResumeCallFun()
--     return true
-- end
function FlamingPompeiiMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end
function FlamingPompeiiMiniMachine:clearCurMusicBg()
end
function FlamingPompeiiMiniMachine:specialSymbolActionTreatment(node)
end
function FlamingPompeiiMiniMachine:dealSmallReelsSpinStates()
end
--[[
    转交给主棋盘执行
]]
function FlamingPompeiiMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
    return ccbName
end
function FlamingPompeiiMiniMachine:getBounsScatterDataZorder(symbolType)
    return self.m_machine:getBounsScatterDataZorder(symbolType)
end
--[[
    一些工具
]]
-- 循环处理轮盘小块
function FlamingPompeiiMiniMachine:baseReelSlotsNodeForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if isJumpFun then
                return
            end
        end
    end
end


return FlamingPompeiiMiniMachine
