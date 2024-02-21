local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BombPurrglarMiniMachine = class("BombPurrglarMiniMachine", BaseMiniMachine)

-- 掉落时间
local FallDownTime = 0.2
local ResilienceTime = 0.1

-- 构造函数
function BombPurrglarMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    -- 临时滑动小块列表, 8列,(3+1)行
    self.m_slideSymbol = {}
    -- 当前reSpin次数
    self.m_curSpinTimes = 0
    -- 每列的乘倍卷轴
    self.m_userMultipleReel = {}
    -- 乘倍卷轴长度
    self.m_multipleReelLength = 0
    -- 轮盘实时信号(用于消除触发后获取轮盘当前信号数据)
    self.m_spinReels = {}

    --是否可以全炸
    self.m_bCanAllBomb = true
    --首次出现金钥匙
    self.m_bFallGoldKey = false
    --播放结束提示
    self.m_bPlayOverTip = false
end
--[[
    data = {
        machine

    }
]]
function BombPurrglarMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machine = data.machine

    --滚动节点缓存列表
    -- self.cacheNodeMap = {}

    --init
    self:initGame()
end

function BombPurrglarMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function BombPurrglarMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BombPurrglar"
end

---
-- 读取配置文件数据
--
function BombPurrglarMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData("BombPurrglarMiniConfig.csv", "LevelBombPurrglarConfig.lua")
    end
end

function BombPurrglarMiniMachine:initMachineCSB()
    self:createCsbNode("BombPurrglar/GameScreenBombPurrglar_bonus.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function BombPurrglarMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    BaseMiniMachine.initMachine(self)

    self.m_reSpinNodeSize = cc.size(self.m_SlotNodeW, self.m_SlotNodeH)

    self.m_bigReelClipNode = self:findChild("Panel_SpReel")
    self.m_bigReelClipSize = self.m_bigReelClipNode:getContentSize()
    --
    self:initBombPurrglarClipNode()
    self:initPlayerItem()
    self:initCreditBox()
    self:initTopLight()
    self:initRespinRunEffect()

    self.m_overTip = util_createAnimation("BombPurrglar_wenzitishi.csb")
    self:findChild("Node_wenzitishi"):addChild(self.m_overTip)
    self.m_overTip:setVisible(false)

    self.m_bigReelDikuang = util_createAnimation("BombPurrglar/GameScreenBombPurrglar_bonus_kuang.csb")
    self:findChild("reel_kuangBig"):addChild(self.m_bigReelDikuang, -1)

    -- 遮罩在初始化棋盘时隐藏掉 播放一次时间线后打开可见性
    self.m_dark = util_createAnimation("BombPurrglar_Bonus_boom.csb")
    self:findChild("Node_BonusBoom"):addChild(self.m_dark)
    self.m_dark:setVisible(false)

    self.m_bonusJuese_cat = util_spineCreate("Socre_BombPurrglar_9", true, true)
    self.m_dark:findChild("Node_mao"):addChild(self.m_bonusJuese_cat)

    -- respin金钥匙滚动效果

    self:addMiniMachineObserver()
end
function BombPurrglarMiniMachine:addMiniMachineObserver()
    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:reSpinReelDown()
        end,
        ViewEventType.NOTIFY_RESPIN_RUN_STOP
    )
end

function BombPurrglarMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    -- 读取图集资源的话要等到图集载入缓存之后
    self:initPlayerProgress()

    self.m_machineConfig = self.m_machine.m_configData
end

function BombPurrglarMiniMachine:addObservers()
    BaseMiniMachine.addObservers(self)
end

function BombPurrglarMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_moveHandler then
        scheduler.unscheduleGlobal(self.m_moveHandler)
        self.m_moveHandler = nil
    end
    if self.m_moveDownHandler then
        scheduler.unscheduleGlobal(self.m_moveDownHandler)
        self.m_moveDownHandler = nil
    end

    if self.m_progressMoveHandler then
        scheduler.unscheduleGlobal(self.m_progressMoveHandler)
        self.m_progressMoveHandler = nil
    end
end

function BombPurrglarMiniMachine:removeObservers()
    BaseMiniMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function BombPurrglarMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
    return ccbName
end

function BombPurrglarMiniMachine:checkGameResumeCallFun()
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

function BombPurrglarMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function BombPurrglarMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function BombPurrglarMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function BombPurrglarMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function BombPurrglarMiniMachine:clearCurMusicBg()
end

function BombPurrglarMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function BombPurrglarMiniMachine:playEffectNotifyChangeSpinStatus()
    -- self.m_machine:reelShowSpinNotify( )
end

function BombPurrglarMiniMachine:slotReelDown()
    BombPurrglarMiniMachine.super.slotReelDown(self)
end

function BombPurrglarMiniMachine:reelDownNotifyPlayGameEffect()
    BombPurrglarMiniMachine.super.reelDownNotifyPlayGameEffect(self)
end

----------------------------- 玩法处理 -----------------------------------
function BombPurrglarMiniMachine:beginMiniReel()
    BaseMiniMachine.beginReel(self)
end

function BombPurrglarMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

function BombPurrglarMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function BombPurrglarMiniMachine:quicklyStopReel(colIndex)
    BaseMiniMachine.quicklyStopReel(self, colIndex)
end

--[[
    reSpin相关
]]
-- 继承底层respinView
function BombPurrglarMiniMachine:getRespinView()
    return "CodeBombPurrglarSrc.BombPurrglarMini.BombPurrglarRespinView"
end
-- 继承底层respinNode
function BombPurrglarMiniMachine:getRespinNode()
    return "CodeBombPurrglarSrc.BombPurrglarMini.BombPurrglarRespinNode"
end

-- 根据本关卡实际小块数量填写
function BombPurrglarMiniMachine:getRespinRandomTypes()
    local symbolList = {
        self.m_machine.SYMBOL_BONUSGAME_BLANK,
        self.m_machine.SYMBOL_BONUS_3
    }
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function BombPurrglarMiniMachine:getRespinLockTypes()
    --落地效果移入代码内 手动在回弹时播放
    local symbolList = {
        {type = self.m_machine.SYMBOL_BONUSGAME_GOLDKEY, runEndAnimaName = "", bRandom = false},
        {type = self.m_machine.SYMBOL_BONUSGAME_MULTI_RED, runEndAnimaName = "", bRandom = false},
        {type = self.m_machine.SYMBOL_BONUSGAME_MULTI_SILVER, runEndAnimaName = "", bRandom = false}
    }

    return symbolList
end

function BombPurrglarMiniMachine:showRespinView(effectData)
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()
    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()
    self:triggerReSpinCallFun(endTypes, randomTypes)

    --初始化一下首次棋盘的乘倍
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local lastNode = self.m_respinView:getBombPurrglarSymbolNode(iRow, iCol)
            self:upDateMultiSymbolScore(lastNode)
        end
    end

    -- 获得reSpin小块的宽高, 裁剪区域 reSpin小块计算的 单个小块 高度是 118 和 base模式的 110 有些差距需要重新算一下裁剪区域
    -- 原因:没设置mini的轮盘的缩放
    local respinNodeInfo = self:reateRespinNodeInfo()
    local startPos, clipSize = self.m_respinView:getReelInfo(respinNodeInfo)
    if startPos and clipSize then
        self.m_reSpinNodeSize = clipSize
    end

    local parent = self.m_clipParent
    local reel0 = self:findChild("sp_reel_0")
    local pos = util_convertToNodeSpace(reel0, parent)

    local clipData = {
        x = pos.x,
        y = pos.y,
        width = clipSize.width * self.m_iReelColumnNum,
        height = clipSize.height * self.m_iReelRowNum
    }
    self.m_tempSymbolClip:setClippingRegion(clipData)
end
function BombPurrglarMiniMachine:showReSpinStart(func)
    if func then
        func()
    end
end
--开始滚动
function BombPurrglarMiniMachine:startReSpinRun()
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    -- self:requestSpinReusltData()

    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    else
        return
    end

    -- 当前spin次数
    self.m_curSpinTimes = self.m_curSpinTimes + 1

    --reSpin即将结束提示
    self:playRespinOverTip(
        function()
            self.m_respinView:startMove()
            --!!!数据返回
            self.m_machine:levelPerformWithDelay(
                1.5,
                function()
                    local spinResult = self.m_resultData.data.userMultipleList[self.m_curSpinTimes]
                    self:netWorkCallFun(spinResult)
                end
            )
        end
    )
end
---判断结算
function BombPurrglarMiniMachine:reSpinReelDown(addNode)
    self.m_spinReels = clone(self.m_runSpinResultData.p_reels)
    self:spinUpDateUserMultipleReel()
    self.m_bCanAllBomb = true

    self:playFallSymbolEffect(
        function()
            self:upDateFirstPLayerEffect()

            self:reSpinReelDown_BombPurrglar(addNode)
            -- BombPurrglarMiniMachine.super.reSpinReelDown(self,addNode)
        end
    )
end

-- 重写一下底层的 reSpinReelDown 取消回复spin按钮的 事件发送
function BombPurrglarMiniMachine:reSpinReelDown_BombPurrglar(addNode)
    self:setGameSpinStage(STOP_RUN)
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        -- self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
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

function BombPurrglarMiniMachine:reSpinEndAction()
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()

    --最后一次落地火星动画播放
    self.m_machine:levelPerformWithDelay(
        0.5,
        function()
            self:endGame(
                function()
                    -- 通知respin结束
                    self:respinOver()
                end
            )
        end
    )
end
-- bonus结束 关闭mini 轮盘
function BombPurrglarMiniMachine:showRespinOverView(effectData)
    self:removeGameEffectType(GameEffect.EFFECT_RESPIN)

    self:triggerReSpinOverCallFun(0)
end
-- 触发reSPin结束，不发送更新赢钱事件
function BombPurrglarMiniMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        coins = self.m_serverWinCoins or 0
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

---
-- 清空掉产生的数据
--
function BombPurrglarMiniMachine:clearSlotoData()
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

function BombPurrglarMiniMachine:addSelfEffect()
end

function BombPurrglarMiniMachine:MachineRule_playSelfEffect(effectData)
    -- if effectData.p_selfEffectType == self.BONUS_FS_ADD_EFFECT then

    -- end

    return true
end

function BombPurrglarMiniMachine:specialSymbolActionTreatment(node)
end

function BombPurrglarMiniMachine:slotOneReelDown(reelCol)
    BombPurrglarMiniMachine.super.slotOneReelDown(self, reelCol)
end

--设置bonus scatter 层级
function BombPurrglarMiniMachine:getBounsScatterDataZorder(symbolType)
    return self.m_machine:getBounsScatterDataZorder(symbolType)
end

function BombPurrglarMiniMachine:enterLevel()
end

function BombPurrglarMiniMachine:enterLevelMiniSelf()
    BombPurrglarMiniMachine.super.enterLevel(self)
end

function BombPurrglarMiniMachine:dealSmallReelsSpinStates()
end

function BombPurrglarMiniMachine:checkNotifyUpdateWinCoin()
end

--[[
    其他Ui组件
]]
-- 裁剪区域
function BombPurrglarMiniMachine:initBombPurrglarClipNode()
    local parent = self.m_clipParent
    local reel0 = self:findChild("sp_reel_0")
    local scaleX = reel0:getScaleX()
    local scaleY = reel0:getScaleY()
    local reelSize = reel0:getContentSize()

    local pos = util_convertToNodeSpace(reel0, parent)

    local clipData = {
        x = pos.x,
        y = pos.y,
        width = reelSize.width * scaleX * self.m_iReelColumnNum,
        height = reelSize.height * scaleY
    }
    self.m_tempSymbolClip = cc.ClippingRectangleNode:create(clipData)
    parent:addChild(self.m_tempSymbolClip, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

    --^^^测试代码 用于看裁剪区域大小
    -- local colorLayer = cc.LayerColor:create(cc.c3b(250, 0, 0))
    -- colorLayer:setContentSize(cc.size(clipData.width, clipData.height))
    -- colorLayer:setAnchorPoint(cc.p(0, 0))
    -- colorLayer:setPosition(pos)
    -- self:addChild(colorLayer, clipOrder)
end
-- 下方玩家头像
function BombPurrglarMiniMachine:initPlayerItem()
    self.m_playerItems = {}
    self.m_machine.RespinPlayerItem = {}
    for _index = 1, self.m_iReelColumnNum do
        local item = util_createView("CodeBombPurrglarSrc.BombPurrglarMini.BombPurrglarMiniPlayerItem")
        local parent = self:findChild(string.format("Node_%d", _index))
        parent:addChild(item)
        table.insert(self.m_playerItems, item)

        self.m_machine:initRSPlayerItem(parent)
    end
end
function BombPurrglarMiniMachine:reSetPlayerItemShow()
    for _index = 1, self.m_iReelColumnNum do
        local item = self.m_playerItems[_index]
        item:resetShow()
    end

    for _index = 1, self.m_iReelColumnNum do
        local item = self.m_machine.RespinPlayerItem[_index]
        item:resetShow()
    end
end

function BombPurrglarMiniMachine:upDatePlayerItem()
    local data = self.m_resultData.data.sets

    for _index = 1, self.m_iReelColumnNum do
        local item = self.m_playerItems[_index]
        item:refreshData(data[_index])

        item:refreshHead()
        item:upDateMultiLab(0)
        item:runCsbAction("idleframe", true)
    end

    for _index = 1, self.m_iReelColumnNum do
        local item = self.m_machine.RespinPlayerItem[_index]
        item:refreshData(data[_index])

        item:refreshHead()
        item:upDateMultiLab(0)
        item:runCsbAction("idleframe", true)
    end
end

function BombPurrglarMiniMachine:upDatePlayerMultiple(_iCol, _addMulti)
    _addMulti = _addMulti or 0

    local item = self.m_playerItems[_iCol]
    local newMulti = item.m_playerInfo.curMulti + _addMulti
    item:upDateMultiLab(newMulti)

    local rsItem = self.m_machine.RespinPlayerItem[_iCol]
    local rsNewMulti = rsItem.m_playerInfo.curMulti + _addMulti
    rsItem:upDateMultiLab(rsNewMulti)
end

function BombPurrglarMiniMachine:upDateFirstPLayerEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local userMulit = selfData.userMulit or {}

    local maxMuti = 0
    local maxColList = {}
    for iCol, _muti in ipairs(userMulit) do
        if _muti > maxMuti then
            maxMuti = _muti
            maxColList = {iCol}
        elseif _muti == maxMuti then
            table.insert(maxColList, iCol)
        end
    end

    for iCol, _item in ipairs(self.m_playerItems) do
        local muti = userMulit[iCol] or 0
        local actionName = "idleframe"
        if maxMuti > 0 and #maxColList <= 2 and muti == maxMuti then
            actionName = "actionframe"
        end

        _item:runCsbAction(actionName, true)
    end

    for iCol, _item in ipairs(self.m_machine.RespinPlayerItem) do
        local muti = userMulit[iCol] or 0
        local actionName = "idleframe"
        if maxMuti > 0 and #maxColList <= 2 and muti == maxMuti then
            actionName = "actionframe"
        end

        _item:runCsbAction(actionName, true)
    end
end

function BombPurrglarMiniMachine:changePlayerItemVisible(_visible)
    for iCol, _item in ipairs(self.m_playerItems) do
        _item:setVisible(_visible)
    end
end
function BombPurrglarMiniMachine:changePlayerItemArrowVisible(_visible)
    for iCol, _item in ipairs(self.m_playerItems) do
        _item:refreshArrow(_visible)
    end

    for iCol, _item in ipairs(self.m_machine.RespinPlayerItem) do
        _item:refreshArrow(_visible)
    end
end
-- 玩家机器进入玩法时应在底部屏幕之外，缓缓移入指定位置
function BombPurrglarMiniMachine:initPlayerItemStartPos()
    local oneItem = self.m_playerItems[1]
    local arrow = oneItem:findChild("ARROW")
    local arrowSize = arrow:getContentSize()
    local topY = arrow:getPositionY() + arrowSize.height / 2

    local nodePos = oneItem:getParent():convertToNodeSpace(cc.p(0, -topY))
    local posY = nodePos.y
    for iCol, _item in ipairs(self.m_playerItems) do
        _item:setPositionY(posY)
    end
end
function BombPurrglarMiniMachine:playPlayerItemEnterAnim(_moveTime)
    for iCol, _item in ipairs(self.m_playerItems) do
        if _moveTime <= 0 then
            _item:stopAllActions()
            _item:setPositionY(0)
        else
            _item:runAction(cc.MoveTo:create(_moveTime, cc.p(0, 0)))
        end
    end
end

function BombPurrglarMiniMachine:getAllPlayerInfo()
    local dataList = {}
    for iCol, _item in ipairs(self.m_playerItems) do
        table.insert(dataList, _item.m_playerInfo)
    end
    return dataList
end

--右侧乘倍宝箱
function BombPurrglarMiniMachine:initCreditBox()
    self.m_creditBox = util_createAnimation("BombPurrglar_Credits_bonus_box.csb")
    self:findChild("Node_credit_box"):addChild(self.m_creditBox)
end
function BombPurrglarMiniMachine:upDateCreditBox(_multi)
    local labCoins = self.m_creditBox:findChild("m_lb_coins")
    labCoins:setString(string.format("X%d", _multi))
    self:updateLabelSize({label = labCoins, sx = 0.3, sy = 0.3}, 270)

    self.m_creditBox:runCsbAction("idleframe", true)
end

-- 右侧玩家进度条
function BombPurrglarMiniMachine:initPlayerProgress()
    self.m_progress = util_createAnimation("BombPurrglar_Credits_bonus.csb")
    self:findChild("Node_credit"):addChild(self.m_progress)
    self.m_progress.m_curAnimName = "idleframe"
    self.m_progress:runCsbAction("idleframe", true)
    --波纹的裁剪
    local bowenClipParent = self.m_progress:findChild("Node_bowenClip")
    local childList = bowenClipParent:getChildren()
    local bowenMask = display.newSprite("#common/BombPurrglar_jindu_mask.png")
    local maskSize = bowenMask:getContentSize()
    local bowenClip = cc.ClippingNode:create()
    bowenClipParent:addChild(bowenClip)
    self.m_progress.m_csbOwner["bowenClip"] = bowenClip
    bowenClip:setAlphaThreshold(0.05)
    bowenClip:setStencil(bowenMask)
    bowenClip:setInverted(false)
    local maskPos = cc.p(maskSize.width * 0.5, maskSize.height * 0.475)
    bowenMask:setPosition(maskPos)
    for i, _childNode in ipairs(childList) do
        util_changeNodeParent(bowenClip, _childNode, 100)
    end

    -- 进度条上的小头像
    local itemParent = self.m_progress:findChild("Node_playerItem")
    self.m_progressPlayers = {}
    -- 每个头像的目标高度
    self.m_progressMaxY = 0
    self.m_progressTargetY = {}
    for iCol = 1, 8 do
        local item = util_createAnimation("BombPurrglar_Credits_bonus_head.csb")
        itemParent:addChild(item)

        table.insert(self.m_progressPlayers, item)
        table.insert(self.m_progressTargetY, 0)
        -- 初始的X坐标，旋转，缩放
        local posX = iCol <= 4 and -70 or 70
        item:setPositionX(posX)

        local scale = 0.8
        item:setScale(scale)

        local rotation = iCol <= 4 and -90 or 90
        item:findChild("sp_headFrame"):setRotation(rotation)
        item:findChild("sp_headFrame_me"):setRotation(rotation)
    end
end
function BombPurrglarMiniMachine:initProgressPlayerHead()
    local dataList = self.m_resultData.data.sets

    for iCol, _item in ipairs(self.m_progressPlayers) do
        local data = {}
        for ii, _setData in ipairs(dataList) do
            if _setData.chairId + 1 == iCol then
                data = _setData
                break
            end
        end

        local isMe = data.udid == globalData.userRunData.userUdid
        -- 刷新头像
        _item:findChild("sp_headBg_me"):setVisible(isMe)
        _item:findChild("sp_headBg"):setVisible(not isMe)
        _item:findChild("sp_headFrame_me"):setVisible(isMe)
        _item:findChild("sp_headFrame"):setVisible(not isMe)
        local head = _item:findChild("sp_head")
        head:removeAllChildren(true)
        local facebookId = data.facebookId or ""
        local headId = data.head or ""

        util_setHead(head, facebookId, headId, nil, false)
    end
end

function BombPurrglarMiniMachine:upDateProgressCoins()
    local coins = 0
    local sets = self.m_resultData.data.sets or {}
    for iCol, _data in ipairs(sets) do
        if _data.udid == globalData.userRunData.userUdid then
            coins = _data.coins
            break
        end
    end

    local labCoin = self.m_progress:findChild("m_lb_coins")
    local coisStr = util_formatCoins(coins, 3)
    labCoin:setString(coisStr)
    self:updateLabelSize({label = labCoin, sx = 1, sy = 1}, 84)
end

function BombPurrglarMiniMachine:upDateProgressPlayerPos(_playAnim)
    local maxHeight = 370
    self.m_progressMaxY = 0
    -- 刷新一下最新的进度数据
    for iCol = 1, 8 do
        local multipleReel = self.m_userMultipleReel[iCol] or {}
        local progress = (self.m_multipleReelLength - #multipleReel) / (self.m_multipleReelLength)
        local posY = math.floor(progress * maxHeight)

        self.m_progressTargetY[iCol] = posY
        self.m_progressMaxY = math.max(self.m_progressMaxY, posY)
    end

    -- 刷新裁剪节点的遮罩区域
    local upDateClipNodeSize = function(_maxY)
        local progress = _maxY / maxHeight

        -- local clipNode = self.m_progress:findChild("Panel_dikuang")
        local clipNode_bowen = self.m_progress:findChild("bowenClip")
        local bowen = self.m_progress:findChild("Node_shuimian")
        local bowenSprite = self.m_progress:findChild("Sprite_27")
        local bowen_size = bowenSprite:getContentSize()
        local bowen_posY = _maxY - bowen_size.height / 2
        bowen:setVisible(bowen_posY > 0)
        bowen:setPositionY(bowen_posY)

        local yeti = self.m_progress:findChild("Node_yeti")
        local yetiSprite = self.m_progress:findChild("yeti")
        local yeti_size = yetiSprite:getContentSize()
        local yeti_posY = 0 - (1 - progress) * yeti_size.height
        yeti:setPositionY(yeti_posY)

        clipNode_bowen:setContentSize(cc.size(60, _maxY))

        local idleAnim = "idleframe"
        local animIndex = math.floor(progress / 0.25)
        if animIndex > 0 then
            idleAnim = string.format("idleframe%d", animIndex)
        end

        if idleAnim ~= self.m_progress.m_curAnimName then
            --  切换进度播放idle时 记录一下 防止切换过于频繁，展示有问题
            self.m_progress.m_curAnimName = idleAnim
            self.m_progress:runCsbAction(idleAnim, true)
        end
    end

    if not _playAnim then
        if self.m_progressMoveHandler then
            scheduler.unscheduleGlobal(self.m_progressMoveHandler)
            self.m_progressMoveHandler = nil
        end

        for iCol = 1, 8 do
            local item = self.m_progressPlayers[iCol]
            local posY = self.m_progressTargetY[iCol]
            item:setLocalZOrder(posY)
            item:setPositionY(posY)
        end

        upDateClipNodeSize(self.m_progressMaxY)
        return
    end

    if nil ~= self.m_progressMoveHandler then
        return
    end

    local moveSpeed = 40
    self.m_progressMoveHandler =
        scheduler.scheduleUpdateGlobal(
        function(dt)
            local moveDistance = moveSpeed * dt

            local curMaxY = 0
            local bMove = false
            for iCol = 1, 8 do
                local item = self.m_progressPlayers[iCol]
                local curPosY = item:getPositionY()
                local targetPosY = self.m_progressTargetY[iCol]
                if curPosY < targetPosY then
                    bMove = true
                    local nextPosY = math.min(targetPosY, curPosY + moveDistance)
                    item:setPositionY(nextPosY)
                    item:setLocalZOrder(nextPosY)
                end
                curMaxY = math.max(curMaxY, item:getPositionY())
            end

            if bMove then
                upDateClipNodeSize(curMaxY)
            else
                if self.m_progressMoveHandler then
                    scheduler.unscheduleGlobal(self.m_progressMoveHandler)
                    self.m_progressMoveHandler = nil
                end
            end
        end
    )

    -- 播放最高位置玩家的火焰动效
    -- for _iCol,_item in pairs(self.m_progressPlayers) do
    --     local curPosY =  _item:getPositionY()
    --     local actionName = (curPosY>0 and curPosY==maxPosY) and "idleframe1" or "idleframe"
    --     _item:runCsbAction(actionName, true)
    -- end
end

-- 快要结束时的顶部光效
function BombPurrglarMiniMachine:initTopLight()
    self.m_topLight = util_createAnimation("BombPurrglar_dingguang.csb")
    self:findChild("Node_dingguang"):addChild(self.m_topLight)
    self.m_topLight:setVisible(false)
end
function BombPurrglarMiniMachine:changeTopLightVisible(_visible)
    util_setCsbVisible(self.m_topLight, _visible)

    if _visible then
        self.m_topLight:runCsbAction("idle", true)
    end
end

--金钥匙出现的列光效
function BombPurrglarMiniMachine:initRespinRunEffect()
    local effectParent = self.m_slotEffectLayer
    self.m_reSpinRunEffect = {}
    for iCol = 1, self.m_iReelColumnNum do
        local runEffect = util_createAnimation("BombPurrglar_yaoshi_run.csb")
        local spReelNode = self:findChild(string.format("sp_reel_%d", iCol - 1))
        local effectPos = util_convertToNodeSpace(spReelNode, effectParent)
        effectParent:addChild(runEffect)
        runEffect:setPosition(effectPos)
        runEffect:setVisible(false)

        table.insert(self.m_reSpinRunEffect, runEffect)
    end
end
function BombPurrglarMiniMachine:changeRunEffectVisible(_visible)
    for iCol, _effect in ipairs(self.m_reSpinRunEffect) do
        util_setCsbVisible(_effect, _visible)
    end

    if not _visible then
        if self.m_runEffectSoundId then
            gLobalSoundManager:stopAudio(self.m_runEffectSoundId)
            self.m_runEffectSoundId = nil
        end
    end
end
function BombPurrglarMiniMachine:playRunEffectAnim(_iCol)
    local effect = self.m_reSpinRunEffect[_iCol]
    if not effect:isVisible() then
        effect:setVisible(true)
        effect:runCsbAction("run", true)

        -- 光柱音效
        if self.m_runEffectSoundId then
            gLobalSoundManager:stopAudio(self.m_runEffectSoundId)
            self.m_runEffectSoundId = nil
        end
        if not self.m_runEffectSoundId then
            self.m_runEffectSoundId = gLobalSoundManager:playSound(self.m_machineConfig.Sound_Bonus_getGoldKey_run)
        end
    end
end

----主棋盘调用接口:
function BombPurrglarMiniMachine:initResultData(_resultData)
    -- print("[BombPurrglarMiniMachine:initResultData] = ",cjson.encode(_resultData.data))
    self:insertResultData(_resultData)
    self.m_spinReels = {}
    -- 生成每列的初始乘倍卷轴
    self.m_userMultipleReel = {}
    self.m_multipleReelLength = #_resultData.data.initMultipleReel
    for _iCol = 1, self.m_iReelColumnNum do
        self.m_userMultipleReel[_iCol] = clone(_resultData.data.initMultipleReel)
    end
    -- 初始化轮盘 和 其他Ui组件
    self:initTriggerReel()
    self:upDatePlayerItem()
    self:initProgressPlayerHead()
    self:upDateProgressPlayerPos(false)
    self:upDateProgressCoins()
    local winnerMultiple = _resultData.data.winnerMultiple or 0
    self:upDateCreditBox(winnerMultiple)
    self.m_dark:setVisible(false)
    self:changeRunEffectVisible(false)
    -- 展示大轮盘
    self.m_bigReelDikuang:pauseForIndex(0)
    self:changeBigReelVisible(true)
    -- 隐藏base轮盘
    self:changeSlotParentsVisible(false)
    -- 隐藏底部的玩家列表
    self:initPlayerItemStartPos()
    self:changePlayerItemArrowVisible(true)
    -- reSpin 数据
    self.m_runSpinResultData.p_reSpinsTotalCount = #(_resultData.data.userMultipleList) -- respin 总次数
    self.m_runSpinResultData.p_reSpinCurCount = self.m_runSpinResultData.p_reSpinsTotalCount -- respin 剩余次数
    self.m_runSpinResultData.p_resWinCoins = 0
    self.m_runSpinResultData.p_reSpinStoredIcons = {} -- 本轮锁定 icons 的pos 列表
    -- reSpin事件
    local respinEffect = GameEffectData.new()
    respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
    respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect
    --重置一些轮盘基础变量
    self.m_curSpinTimes = 0
    self.m_bFallGoldKey = false
    self.m_bPlayOverTip = false
end
function BombPurrglarMiniMachine:startGame(_fun)
    self.m_endFunc = _fun

    self:sortGameEffects()
    self:playGameEffect()
end
function BombPurrglarMiniMachine:endGame(_func)
    if self.m_endFunc then
        self.m_endFunc(_func)
    end
end

-- 补充一些spin默认数据
function BombPurrglarMiniMachine:insertResultData(_resultData)
    self.m_resultData = _resultData
    local endType = self:getRespinLockTypes()

    local spinList = self.m_resultData.data.userMultipleList
    for _spinTimes, _data in ipairs(spinList) do
        _data.bet = 0
        _data.lines = {}
        _data.respin = {
            reSpinsTotalCount = #spinList,
            reSpinCurCount = #spinList - _spinTimes,
            resWinCoins = 0
        }
        _data.prevReel = {123, 123, 123, 123, 123, 123, 123, 123}
        _data.winAmount = 0
        _data.winAmountValue = 0

        _data.storedIcons = {}
        for iLineIndex, LineData in ipairs(_data.reels) do
            for iCol, _symbolType in ipairs(LineData) do
                for _index, _lockData in ipairs(endType) do
                    if _symbolType == _lockData.type then
                        local posIndex = (iCol - 1) + (self.m_iReelRowNum - iLineIndex) * self.m_iReelColumnNum
                        table.insert(_data.storedIcons, posIndex)
                        break
                    end
                end
            end
        end
    end
end
-- 触发时重置一下轮盘数据和展示
function BombPurrglarMiniMachine:initTriggerReel()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(true)
                local symbolType = self:getSymbolTypeByReelPos(iCol, iRow)
                -- 重置一下轮盘数据
                local lineIndex = self.m_iReelRowNum + 1 - iRow
                if not self.m_runSpinResultData.p_reels[lineIndex] then
                    self.m_runSpinResultData.p_reels[lineIndex] = {}
                end
                self.m_runSpinResultData.p_reels[lineIndex][iCol] = symbolType
                -- 修改信号展示
                local ccbName = self:getSymbolCCBNameByType(self, symbolType)
                node:changeCCBByName(ccbName, symbolType)
                node:changeSymbolImageByName(ccbName)
                self:updateReelGridNode(node)
                -- 乘倍分值
                self:upDateMultiSymbolScore(node)
            end
        end
    end
end

--[[
    玩法结束隐藏除了金钥匙外所有的小块 , 做一个淡出 和 之后的压黑衔接上
    _moveData = {
        moveTime = 0,
        distance = 0,
    }
]]
function BombPurrglarMiniMachine:reSpinOverHideAllSymbol(_moveData)
    local bool = false

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local lastNode = self.m_respinView:getBombPurrglarSymbolNode(iRow, iCol)
            if lastNode:isVisible() then
                lastNode:setVisible(false)
                local tempNode = self:createBombPurrglarTempSymbol(lastNode.p_symbolType, iCol, iRow)
                self:upDateMultiSymbolScore(tempNode, tempNode.p_cloumnIndex, tempNode.p_rowIndex)
                local pos = util_convertToNodeSpace(lastNode, tempNode:getParent())
                tempNode:setPosition(pos)

                local act_move = cc.EaseSineIn:create(cc.MoveBy:create(_moveData.moveTime, cc.p(0, -_moveData.distance)))
                local act_fun =
                    cc.CallFunc:create(
                    function()
                        if not bool then
                            bool = true
                            if self.m_respinView then
                                self.m_respinView:setVisible(false)
                            end
                        end

                        tempNode:removeFromParent()
                        self:pushSlotNodeToPoolBySymobolType(tempNode.p_symbolType, tempNode)
                    end
                )
                tempNode:runAction(cc.Sequence:create(act_move, act_fun))
            end
        end
    end
end

--[[
    消除玩法
    1.全体消除

    2.按行消除
]]
function BombPurrglarMiniMachine:spinUpDateUserMultipleReel()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local setMultipleReel = selfData.setMultipleReel or {}

    for _iCol, _setData in ipairs(setMultipleReel) do
        --拿到玩家当前的乘倍卷轴
        local multipleReel = self.m_userMultipleReel[_iCol]
        for _sPos, _iMulti in pairs(_setData) do
            local iPos = tonumber(_sPos)
            -- 卷轴可能已经缩减过了，获取一下正确的位置
            local curPos = iPos - (self.m_multipleReelLength - #multipleReel)
            if multipleReel[curPos] then
                multipleReel[curPos] = _iMulti
            end
        end
    end
end

function BombPurrglarMiniMachine:playFallSymbolEffect(_fun)
    local rsView = self.m_respinView

    local bombList = rsView:getSymbolList(self.m_machine.SYMBOL_BONUS_3)
    local bombCount = #bombList

    if bombCount >= 6 and self.m_bCanAllBomb then
        self:playAllBombAnim(
            function()
                self:playFallSymbolEffect(_fun)
            end
        )
    else
        self.m_bCanAllBomb = false
        bombCount =
            self:playOneLineBombAnim(
            function()
                self:playFallSymbolEffect(_fun)
            end
        )
    end

    -- 没有可消除的信号
    if bombCount <= 0 then
        if _fun then
            _fun()
        end
    end
end
-- 超过6个炸弹 的动画
function BombPurrglarMiniMachine:playAllBombAnim(_fun)
    local rsView = self.m_respinView

    --2.全炸动画
    local playAllBombAnim = function()
        self.m_dark:setVisible(true)

        self.m_dark:runCsbAction(
            "actionframe",
            false,
            function()
                if _fun then
                    _fun()
                end
            end
        )
        -- "start" 114帧(60)
        gLobalSoundManager:playSound(self.m_machineConfig.Sound_BonusCat_bombAll)
        util_spinePlay(self.m_bonusJuese_cat, "start", false)
        -- util_spineEndCallFunc(self.m_bonusJuese_cat, "start", function()
        -- end)
        -- 第120帧播放小块爆炸动画
        self.m_machine:levelPerformWithDelay(
            114 / 60,
            function()
                --开始掉落
                local bombData = {}
                local fallData = {}

                for iCol = 1, self.m_iReelColumnNum do
                    local moveNum = self.m_iReelRowNum
                    for iRow = 1, self.m_iReelRowNum do
                        -- 第一行小块上方存在金钥匙的话，修改移动格子数量
                        if 1 == iRow then
                            for _iRow = iRow, self.m_iReelRowNum do
                                local symbolType = self:getSymbolTypeByReelPos(iCol, _iRow)
                                if symbolType == self.m_machine.SYMBOL_BONUSGAME_GOLDKEY then
                                    moveNum = _iRow - 1
                                    break
                                end
                            end
                        end

                        -- 金钥匙不能被炸
                        local lastNode = self.m_respinView:getBombPurrglarSymbolNode(iRow, iCol)
                        if lastNode.p_symbolType ~= self.m_machine.SYMBOL_BONUSGAME_GOLDKEY then
                            -- 创建爆炸小块
                            local bombNode = self:createBombPurrglarTempSymbol(lastNode.p_symbolType, iCol, iRow)
                            self:upDateMultiSymbolScore(bombNode, bombNode.p_cloumnIndex, bombNode.p_rowIndex)
                            local pos = util_convertToNodeSpace(lastNode, bombNode:getParent())
                            bombNode:setPosition(pos)
                            local multi = nil
                            if self:isBombPurrglarBonusMuti(lastNode.p_symbolType) then
                                multi = self:getMultiByReelPos(iCol, iRow)
                            end

                            local bombAnim = "actionframe"
                            if bombNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS_3 then
                                bombAnim = "xiaoshi"
                            end

                            table.insert(
                                bombData,
                                {
                                    bombNode = bombNode,
                                    bombAnim = bombAnim,
                                    iCol = iCol,
                                    iRow = iRow,
                                    moveNum = moveNum,
                                    multi = multi,
                                    delayTime = 0,
                                    -- flyDelayTime = 40/60,
                                    -- 按照列做延时 列:0.1
                                    flyDelayTime = (iCol - 1) * 0.1,
                                    bCollectAnim = false
                                }
                            )
                        end

                        -- 创建移动小块
                        local moveNode = self:upDateFallSymbolPos(iCol, iRow, moveNum)
                        table.insert(
                            fallData,
                            {
                                moveNode = moveNode,
                                iCol = iCol,
                                iRow = iRow,
                                moveNum = moveNum,
                                -- 不做延时
                                delayTime = 0,
                                -- 按照行列做延时 列:0.2 行:0.5
                                -- delayTime = (iCol-1) * 0.2 + (iRow-1) * FallDownTime,

                                -- 按照列数做延时 列:0.2
                                -- delayTime = (iCol-1) * 0.2,

                                bLuodiAnim = iRow == 1
                            }
                        )
                    end

                    -- 移除乘倍卷轴的 前n个格子
                    for iRow = 1, self.m_iReelRowNum do
                        table.remove(self.m_userMultipleReel[iCol], 1)
                    end
                end
                gLobalSoundManager:playSound(self.m_machineConfig.Sound_BonusSymbol_bombAll)
                self:playBombSymbolAnim(
                    bombData,
                    function()
                        gLobalSoundManager:playSound(self.m_machineConfig.Sound_Bonus_reelMoveDown)
                        self:playFallDownAnim(fallData)
                    end
                )
            end
        )
    end

    --1.全部爆炸小块播放触发动画
    local bombList = rsView:getSymbolList(self.m_machine.SYMBOL_BONUS_3)
    if #bombList > 0 then
        gLobalSoundManager:playSound(self.m_machineConfig.Sound_BonusSymbol_bombAllTip)
    end

    local bPlayBombFun = false
    for i, _bombSymbol in ipairs(bombList) do
        _bombSymbol:runAnim(
            "actionframe2",
            false,
            function()
                if not bPlayBombFun then
                    bPlayBombFun = true
                    playAllBombAnim()
                end
            end
        )
    end

    if #bombList < 1 then
        bPlayBombFun = true
        playAllBombAnim()
    end
end

-- 按行消除
function BombPurrglarMiniMachine:playOneLineBombAnim(_fun)
    local rsView = self.m_respinView
    local moveNum = 1

    local bHaveBomb = false
    --触发消除的列索引
    local fallDownCol = {}
    -- 从底到高 按行移除
    for iRow = 1, self.m_iReelRowNum do
        local fallData = {}
        local bombData = {}
        for _index, _reSpinNode in ipairs(rsView.m_respinNodes) do
            if iRow == _reSpinNode.p_rowIndex and self:isRemoveSymbol(_reSpinNode) then
                table.insert(fallDownCol, _reSpinNode.p_colIndex)

                -- 创建爆炸小块
                local lastNode = self.m_respinView:getBombPurrglarSymbolNode(_reSpinNode.p_rowIndex, _reSpinNode.p_colIndex)
                local bombNode = self:createBombPurrglarTempSymbol(lastNode.p_symbolType, _reSpinNode.p_colIndex, _reSpinNode.p_rowIndex)
                self:upDateMultiSymbolScore(bombNode, bombNode.p_cloumnIndex, bombNode.p_rowIndex)
                local pos = util_convertToNodeSpace(lastNode, bombNode:getParent())
                bombNode:setPosition(pos)
                local multi = nil
                if self:isBombPurrglarBonusMuti(lastNode.p_symbolType) then
                    multi = self:getMultiByReelPos(_reSpinNode.p_colIndex, _reSpinNode.p_rowIndex)
                else
                    bHaveBomb = true
                end
                table.insert(
                    bombData,
                    {
                        bombNode = bombNode,
                        bombAnim = "actionframe",
                        iCol = _reSpinNode.p_colIndex,
                        iRow = _reSpinNode.p_rowIndex,
                        moveNum = moveNum,
                        multi = multi,
                        delayTime = 0,
                        flyDelayTime = 0,
                        bCollectAnim = nil ~= multi
                    }
                )

                for _iRow = iRow, self.m_iReelRowNum do
                    local moveNode = self:upDateFallSymbolPos(_reSpinNode.p_colIndex, _iRow, moveNum)

                    table.insert(
                        fallData,
                        {
                            moveNode = moveNode,
                            iCol = _reSpinNode.p_colIndex,
                            iRow = _iRow,
                            moveNum = moveNum,
                            -- 不做延时
                            delayTime = 0,
                            -- 按照列数做延时 列:0.2
                            -- delayTime = (#fallDownCol - 1) * 0.2,

                            -- 按照行列做延时 列:0.2 行:0.5
                            -- delayTime = (#fallDownCol-1) * 0.2 + (_iRow-iRow) * FallDownTime,

                            bLuodiAnim = _iRow == iRow
                        }
                    )
                end

                -- 移除乘倍卷轴的一个格子
                table.remove(self.m_userMultipleReel[_reSpinNode.p_colIndex], _reSpinNode.p_rowIndex)
            end
        end

        if #bombData > 0 then
            if bHaveBomb then
                gLobalSoundManager:playSound(self.m_machineConfig.Sound_Bonus3_bomb)
            end

            self:playBombSymbolAnim(
                bombData,
                function()
                    self:playFallDownAnim(fallData, _fun)
                end
            )
            return #bombData
        end
    end

    return 0
end

-- 创建移动小块
function BombPurrglarMiniMachine:upDateFallSymbolPos(_iCol, _iRow, _moveNum)
    local nextRow = _iRow + _moveNum
    local reSpinNode = self.m_respinView:getRespinNode(_iRow, _iCol)
    local lastNode = self.m_respinView:getBombPurrglarSymbolNode(_iRow, _iCol)
    local upSymbolType = self:getSymbolTypeByReelPos(_iCol, nextRow)

    -- 上方小块信号 和 资源名称
    local upSymbolType = self:getSymbolTypeByReelPos(_iCol, nextRow)
    local ccbName = self:getSymbolCCBNameByType(self, upSymbolType)
    lastNode:changeCCBByName(ccbName, upSymbolType)
    lastNode:changeSymbolImageByName(ccbName)
    self:updateReelGridNode(lastNode)
    lastNode:setVisible(false)

    -- 乘倍信号更新一下倍数
    self:upDateMultiSymbolScore(lastNode, lastNode.p_cloumnIndex, nextRow)

    -- 创建移动小块
    local moveNode = self:createBombPurrglarTempSymbol(upSymbolType, _iCol, _iRow)
    self:upDateMultiSymbolScore(moveNode, moveNode.p_cloumnIndex, nextRow)
    self:upDateBlankSymbolVisible(moveNode, moveNode.p_cloumnIndex, nextRow)

    local pos = util_convertToNodeSpace(lastNode, moveNode:getParent())
    local slotNodeH = self.m_reSpinNodeSize.height
    moveNode:setPosition(pos.x, pos.y + _moveNum * slotNodeH)

    --刷新轮盘格子信号
    local lineIndex = self.m_iReelRowNum + 1 - _iRow
    self.m_spinReels[lineIndex][_iCol] = upSymbolType
    reSpinNode.m_runLastNodeType = upSymbolType
    -- 锁定状态变更
    local bStatus = reSpinNode:getTypeIsEndType(upSymbolType)
    local iStatus = bStatus and RESPIN_NODE_STATUS.LOCK or RESPIN_NODE_STATUS.IDLE
    reSpinNode:setRespinNodeStatus(iStatus)
    if not bStatus then
        reSpinNode:setFirstSlotNode(lastNode)
    end
    self.m_respinView:changeBonus3Order(lastNode)

    return moveNode
end
--[[
    _bombData = { 
        {
            bombNode = bombNode, 
            bombAnim = "actionframe"
            iCol = 1, 
            iRow = 1, 
            moveNum = 1, 
            multi = 0,
            delayTime = 0,  
            flyDelayTime = 0,       --乘倍飞往的延时 
            bCollectAnim = false,   --乘倍的漩涡收集动效
            bCanRemove   = false,   --是否可以放到池子里面去
        } 
    }
]]
function BombPurrglarMiniMachine:playBombSymbolAnim(_bombData, _fun)
    local bombAnim = "actionframe"
    local delayTime = 0
    local flyDelayTime = 0
    local bSound = false
    local soundCol = {}

    for i, _data in ipairs(_bombData) do
        bombAnim = _data.bombAnim or "actionframe"
        delayTime = math.max(delayTime, _data.delayTime)
        flyDelayTime = math.max(flyDelayTime, _data.flyDelayTime)

        local bombNode = _data.bombNode
        self.m_machine:levelPerformWithDelay(
            _data.delayTime,
            function()
                bombNode:runAnim(
                    bombAnim,
                    false,
                    function()
                        if not _data.multi or _data.bCanRemove then
                            -- 乘倍小块需要等待飞行动画播放时再移除
                            bombNode:removeFromParent()
                            self:pushSlotNodeToPoolBySymobolType(bombNode.p_symbolType, bombNode)
                        else
                            _data.bCanRemove = true
                            bombNode:setVisible(false)
                        end
                    end
                )

                if _data.multi then
                    if _data.bCollectAnim then
                        -- 播放乘倍小块的漩涡收集效果
                        self:playMultiSymbolCollectAnim(_data)
                    end

                    --刷新玩家乘倍
                    self.m_machine:levelPerformWithDelay(
                        _data.flyDelayTime,
                        function()
                            -- 同时掉落播一声，延时掉落同列播一声
                            if (flyDelayTime > 0 and not soundCol[_data.iCol]) or not bSound then
                                bSound = true
                                soundCol[_data.iCol] = true

                                self.m_machine:levelPerformWithDelay(
                                    37 / 60,
                                    function()
                                        gLobalSoundManager:playSound(self.m_machineConfig.Sound_Bonus_collectMulti)
                                    end
                                )
                            end

                            self:playBombSymbolLabAnim(_data)

                            if _data.bCanRemove then
                                bombNode:removeFromParent()
                                self:pushSlotNodeToPoolBySymobolType(bombNode.p_symbolType, bombNode)
                            else
                                _data.bCanRemove = true
                            end
                        end
                    )
                end
            end
        )
    end

    self.m_machine:levelPerformWithDelay(
        60 / 60 + delayTime,
        function()
            -- 每次触发消除就更新一下进度条
            self:upDateProgressPlayerPos(true)

            if _fun then
                _fun()
            end
        end
    )
end
-- 漩涡收集效果
function BombPurrglarMiniMachine:playMultiSymbolCollectAnim(_bombData)
    local bombNode = _bombData.bombNode

    local animNameList = {
        [self.m_machine.SYMBOL_BONUSGAME_MULTI_RED] = "Socre_BombPurrglar_red_xiaochu.csb",
        [self.m_machine.SYMBOL_BONUSGAME_MULTI_SILVER] = "Socre_BombPurrglar_silver_xiaochu.csb"
    }

    local symbolType = bombNode.p_symbolType
    local csbName = animNameList[symbolType]

    if csbName then
        local parent = self:findChild("Node_collectAnim")
        local anim = util_createAnimation(csbName)
        parent:addChild(anim)
        local curPos = util_convertToNodeSpace(bombNode, parent)
        anim:setPosition(curPos)
        anim:runCsbAction(
            "actionframe",
            false,
            function()
                anim:removeFromParent()
            end
        )
    end
end
-- 乘倍爆炸文字飞往玩家乘倍区域
function BombPurrglarMiniMachine:playBombSymbolLabAnim(_bombData)
    local labParent = _bombData.bombNode:getCcbProperty("Node_coin")
    if not labParent then
        return
    end
    local labCocosName = "Socre_BombPurrglar_bonus_zi"
    local labCocosNode = labParent:getChildByName(labCocosName)
    if labCocosNode then
        labCocosNode:setVisible(false)
        local text = labCocosNode:findChild("m_lb_coins"):getString()

        local newLab = util_createAnimation("Socre_BombPurrglar_bonus_zi.csb")
        self:addChild(newLab, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        newLab:findChild("m_lb_coins"):setString(text)
        local pos = util_convertToNodeSpace(labCocosNode, self)
        newLab:setPosition(pos)
        newLab:runCsbAction(
            "shouji",
            false,
            function()
                newLab:removeFromParent(false)
                self:upDatePlayerMultiple(_bombData.iCol, _bombData.multi)
            end
        )
        local playItem = self.m_playerItems[_bombData.iCol]

        local multiNode = playItem:findChild("multi")

        local endPos = util_convertToNodeSpace(multiNode, self)
        local actMove = cc.MoveTo:create(37 / 60, endPos)
        newLab:runAction(cc.Sequence:create(actMove))
    end
end
--[[
    -- 对棋盘小块播放下落
    _fallData = { 
        {
            moveNode = moveNode, 
            iCol = 1, 
            iRow = 1, 
            moveNum = 1, 
            delayTime = 0,            --小块掉落的延时
            bLuodiAnim = false,       --播放落地动效 
        } 
    }
]]
function BombPurrglarMiniMachine:playFallDownAnim(_fallData, _fun)
    local moveTime = FallDownTime
    local reelResDis = ResilienceTime

    local delayTime = 0

    for i, _data in ipairs(_fallData) do
        local moveData = _data
        delayTime = math.max(delayTime, _data.delayTime)

        local slotNodeH = self.m_reSpinNodeSize.height
        local resilience = slotNodeH / 8
        local pos1 = cc.p(0, -moveData.moveNum * slotNodeH - resilience)
        local pos2 = cc.p(0, resilience)

        local lastNode = self.m_respinView:getBombPurrglarSymbolNode(moveData.iRow, moveData.iCol)
        local actDelayTime = cc.DelayTime:create(_data.delayTime)
        local actMoveBy = cc.MoveBy:create(moveTime, pos1)
        -- 落地火星
        local actPlayLuodiAnim =
            cc.CallFunc:create(
            function()
                if moveData.bLuodiAnim then
                    self:playFallDownOverAnim(moveData.moveNode)
                end
            end
        )
        local actMoveByUp = cc.MoveBy:create(reelResDis, pos2)

        local actCallFun =
            cc.CallFunc:create(
            function()
                -- 掉落了金色钥匙
                if moveData.moveNode.p_symbolType == self.m_machine.SYMBOL_BONUSGAME_GOLDKEY then
                    -- 修改背景动画
                    if not self.m_bFallGoldKey then
                        self.m_bFallGoldKey = true
                        self.m_machine:changeGameBgAction("bonus3")
                    end
                    -- 播放列光效
                    self:playRunEffectAnim(moveData.iCol)
                end

                moveData.moveNode:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(moveData.moveNode.p_symbolType, moveData.moveNode)
                -- 对下落列的小块 恢复展示
                lastNode:setVisible(true)
                self:upDateBlankSymbolVisible(lastNode)
            end
        )

        moveData.moveNode:setVisible(true)
        self:upDateBlankSymbolVisible(moveData.moveNode)
        lastNode:setVisible(false)
        moveData.moveNode:runAction(cc.Sequence:create(actDelayTime, actMoveBy, actPlayLuodiAnim, actMoveByUp, actCallFun))
    end

    local allTime = moveTime + reelResDis + delayTime
    self.m_machine:levelPerformWithDelay(
        allTime,
        function()
            if _fun then
                _fun()
            end
        end
    )
end

function BombPurrglarMiniMachine:isRemoveSymbol(_reSpinNode)
    local symbolType = _reSpinNode.m_runLastNodeType
    local iRow = _reSpinNode.p_rowIndex

    if symbolType == self.m_machine.SYMBOL_BONUS_3 then
        return true
    elseif self:isBombPurrglarBonusMuti(symbolType) and 1 == iRow then
        return true
    end

    return false
end
-- 落地结束火星动画
function BombPurrglarMiniMachine:playFallDownOverAnim(_symbolNode)
    local curPos = util_convertToNodeSpace(_symbolNode, self)
    local luodiAnim = util_createAnimation("Socre_BombPurrglar_luodi.csb")
    self:addChild(luodiAnim, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    luodiAnim:setPosition(curPos)
    luodiAnim:runCsbAction(
        "luodi",
        false,
        function()
            luodiAnim:removeFromParent()
        end
    )
end
--[[
    开场动画轮盘上滑小块相关
]]
--[[
    _data = {
        startPosY = -70, -- 初始小块的Y轴坐标

        startRow = 1,  -- 初始行索引
        rowDir   = 1,  -- 扩展的方向 1:向上 -1:向下
    }
]]
function BombPurrglarMiniMachine:initSlideSymbol(_data)
    self:clearSlideSymbol()
    -- 创建
    local createCount = 6
    for iCol = 1, self.m_iReelColumnNum do
        self.m_slideSymbol[iCol] = {}
        for iRow = _data.startRow, _data.startRow + _data.rowDir * (createCount - 1), _data.rowDir do
            local slideSymbol = self:createSlideSymbol(iCol, iRow)
        end
    end
    -- 刷初始坐标
    local nodeParent = self.m_bigReelClipNode
    local nodePos = nodeParent:convertToNodeSpace(cc.p(0, _data.startPosY))
    local startPosY = nodePos.y
    local height = self.m_reSpinNodeSize.height
    local dir = _data.rowDir

    for iCol, _list in ipairs(self.m_slideSymbol) do
        local reelWorldPos = self:getReelPos(iCol)
        for iRow, _symbolNode in ipairs(_list) do
            local reelNodePos = nodeParent:convertToNodeSpace(reelWorldPos)
            local posX = reelNodePos.x + self.m_reSpinNodeSize.width / 2
            local posY = startPosY + dir * height / 2 + dir * (iRow - 1) * height
            local pos = cc.p(posX, posY)

            _symbolNode:setPosition(pos)
        end
    end
end

function BombPurrglarMiniMachine:createSlideSymbol(_iCol, _iRow)
    -- 最顶端金钥匙位置在初始时，应为空白，播动效后转换为金钥匙
    local symbolType = self.m_machine.SYMBOL_BONUSGAME_BLANK
    if self.m_multipleReelLength + 1 ~= _iRow then
        local mutil = self:getMultiByReelPos(_iCol, _iRow)
        symbolType = self:getSymbolTypeByMulti(mutil)
    end

    local slideSymbol = self:getSlotNodeWithPosAndType(symbolType, _iRow, _iCol, true)
    local order = self:getBounsScatterDataZorder(symbolType)
    self.m_bigReelClipNode:addChild(slideSymbol, order)

    table.insert(self.m_slideSymbol[_iCol], slideSymbol)

    self:upDateMultiSymbolScore(slideSymbol, _iCol, _iRow)

    return slideSymbol
end
function BombPurrglarMiniMachine:clearSlideSymbol()
    for iCol, _list in ipairs(self.m_slideSymbol) do
        for iRow, _symbolNode in ipairs(_list) do
            _symbolNode:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(_symbolNode.p_symbolType, _symbolNode)
        end
    end
    self.m_slideSymbol = {}
end
-- 金钥匙飞往的8个小块位置
function BombPurrglarMiniMachine:getGoldKeyFlyEndPos()
    local worldPos = {}

    for iCol, _list in ipairs(self.m_slideSymbol) do
        local firstSymbol = _list[1]
        local pos = firstSymbol:getParent():convertToWorldSpace(cc.p(firstSymbol:getPosition()))
        table.insert(worldPos, pos)
    end

    return worldPos
end
-- 首行小块转换为金钥匙,播放三次闪光后开始滑动
function BombPurrglarMiniMachine:changeFirstLineSlideSymbol(_fun, _moveData)
    local symbolType = self.m_machine.SYMBOL_BONUSGAME_GOLDKEY

    local bPlayNextFun = false
    for iCol, _list in ipairs(self.m_slideSymbol) do
        local firstSymbol = _list[1]
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        firstSymbol:changeCCBByName(ccbName, symbolType)
        firstSymbol:changeSymbolImageByName(ccbName)

        firstSymbol:runAnim("actionframe")
        -- 策划说延时 0.7s
        self.m_machine:levelPerformWithDelay(
            0.7,
            function()
                --宝箱闪烁
                local spineDog = self.m_machine.m_bonusJuese_dog
                util_spinePlay(spineDog, "idle2", false)
                util_spineEndCallFunc(
                    spineDog,
                    "idle2",
                    function()
                        util_spinePlay(spineDog, "idle3", true)
                    end
                )

                -- 钥匙闪烁
                firstSymbol:runAnim(
                    "actionframe2",
                    false,
                    function()
                        if not bPlayNextFun then
                            bPlayNextFun = true

                            self:changeBonusBoxParentSize(false)
                            self:startSlideMoveUp(
                                function()
                                    self:playPlayerItemEnterAnim(0)
                                    self:changeSlotParentsVisible(true)
                                    self:changeBigReelVisible(false)
                                    self:clearSlideSymbol()

                                    if _fun then
                                        _fun()
                                    end
                                    if _moveData and _moveData.fun then
                                        _moveData.fun()
                                    end
                                end,
                                _moveData
                            )
                        end
                    end
                )
            end
        )
    end
end
function BombPurrglarMiniMachine:startSlideMoveUp(_fun, _moveData)
    if self.m_moveHandler then
        return
    end
    local bigReelClipNode_size = self.m_bigReelClipNode:getContentSize()
    local bBigReelMove = false
    -- 最后停留在顶部的小块是倒数第三行
    local topLineIndex = #self.m_slideSymbol[1] + 1 - self.m_iReelRowNum
    local lineSymbol = self.m_slideSymbol[1][topLineIndex]
    local lineSymbol_posY = lineSymbol:getPositionY()
    local endPosY = bigReelClipNode_size.height - self.m_reSpinNodeSize.height / 2
    -- 总移动距离,当前移动距离，当前进度
    local totalDistance = endPosY - lineSymbol_posY + self.m_reSpinNodeSize.height * (self.m_multipleReelLength + 1 - #self.m_slideSymbol[1])
    local curDistance = 0
    local curProgress = 0

    local speed = 0
    local topY = bigReelClipNode_size.height + self.m_reSpinNodeSize.height / 2

    gLobalSoundManager:playSound(self.m_machineConfig.Sound_BonusSlide_moveUp)
    self.m_moveHandler =
        scheduler.scheduleUpdateGlobal(
        function(dt)
            curProgress = curDistance / totalDistance

            if curProgress <= 0.2 then
                local startSpeed = self.m_reSpinNodeSize.height
                local targetSpeed = self.m_reSpinNodeSize.height * self.m_multipleReelLength
                speed = startSpeed + (targetSpeed - startSpeed) * curProgress / 0.2
            else
                local reel = self.m_slideSymbol[1]
                local firstSymbol = reel[1]
                local firstPosY = firstSymbol:getPositionY()
                local lastSymbol = reel[#reel]
                local lastPosY = lastSymbol:getPositionY()
                -- 最后一组移动
                if firstSymbol.p_rowIndex <= #reel and lastPosY > 0 and not bBigReelMove then
                    bBigReelMove = true
                    local animMoveTime = 30 / 60

                    self.m_bigReelDikuang:runCsbAction(
                        "actionframe",
                        false,
                        function()
                        end
                    )

                    gLobalSoundManager:playSound(self.m_machineConfig.Sound_BonusPlayerItem_moveUp)
                    self:playPlayerItemEnterAnim(animMoveTime)

                    speed = (totalDistance - curDistance) / animMoveTime
                elseif #reel ~= firstSymbol.p_rowIndex then
                    speed = self.m_reSpinNodeSize.height * self.m_multipleReelLength
                end
            end

            local moveDistance = speed * dt
            -- 最后一次移动
            if curDistance + moveDistance >= totalDistance then
                moveDistance = totalDistance - curDistance
            end
            curDistance = curDistance + moveDistance

            -- 刷新坐标
            for iCol, _list in ipairs(self.m_slideSymbol) do
                for iRow, _symbolNode in ipairs(_list) do
                    local nextPosY = _symbolNode:getPositionY() + moveDistance
                    _symbolNode:setPositionY(nextPosY)
                end
            end
            if _moveData and _moveData.node then
                local nextPosY = _moveData.node:getPositionY() + moveDistance
                _moveData.node:setPositionY(nextPosY)
            end
            -- 刷新信号重制位置
            for iCol, _list in ipairs(self.m_slideSymbol) do
                local firstSymbol = _list[1]
                local lastSymbol = _list[#_list]
                -- 首行信号超过了最大高度，移除添加到尾部
                while firstSymbol:getPositionY() >= topY and lastSymbol.p_rowIndex > 1 do
                    -- 修改行索引
                    firstSymbol.p_rowIndex = lastSymbol.p_rowIndex - 1
                    local mutil = self:getMultiByReelPos(iCol, firstSymbol.p_rowIndex)
                    local nextSymbolType = self:getSymbolTypeByMulti(mutil)
                    local ccbName = self:getSymbolCCBNameByType(self, nextSymbolType)
                    -- 修改信号类型和展示
                    firstSymbol:changeCCBByName(ccbName, nextSymbolType)
                    firstSymbol:changeSymbolImageByName(ccbName)
                    self:updateReelGridNode(firstSymbol)
                    -- 乘倍分值
                    self:upDateMultiSymbolScore(firstSymbol)
                    -- 修改Y坐标
                    local nextPosY = lastSymbol:getPositionY() - self.m_reSpinNodeSize.height
                    firstSymbol:setPositionY(nextPosY)

                    firstSymbol = table.remove(_list, 1)
                    table.insert(_list, firstSymbol)
                    firstSymbol = _list[1]
                    lastSymbol = _list[#_list]
                end
            end

            --结束移动
            if curDistance >= totalDistance then
                self:endSlideSymbolMove(_fun)
            end
        end
    )
end

function BombPurrglarMiniMachine:endSlideSymbolMove(_fun)
    if self.m_moveHandler then
        scheduler.unscheduleGlobal(self.m_moveHandler)
        self.m_moveHandler = nil
    end

    if _fun then
        _fun()
    end
end
--[[
    滑块下移
    _moveData = {
        bonusBox = cc.Node,
        endWorldPos = cc.p(0,0)

    }
]]
function BombPurrglarMiniMachine:startSlideMoveDown(_fun, _moveData)
    if self.m_moveDownHandler then
        return
    end
    local bigReelClipNode_size = self.m_bigReelClipNode:getContentSize()
    local endNodePos = self.m_bigReelClipNode:convertToNodeSpace(_moveData.endWorldPos)

    -- 最后停留在顶部的小块是最后一个
    local topLineIndex = #self.m_slideSymbol[1]
    local lineSymbol = self.m_slideSymbol[1][topLineIndex]
    local lineSymbol_posY = lineSymbol:getPositionY()
    local endPosY = endNodePos.y - self.m_reSpinNodeSize.height / 2
    -- 总移动距离,当前移动距离，当前进度
    local totalDistance = math.abs(endPosY - lineSymbol_posY) + self.m_reSpinNodeSize.height * (self.m_multipleReelLength + 1 - #self.m_slideSymbol[1])
    local curDistance = 0
    local curProgress = 0

    local speed = self.m_reSpinNodeSize.height * (self.m_multipleReelLength + 1) / 2
    local topY = -self.m_reSpinNodeSize.height / 2

    local maxRow = self.m_multipleReelLength + 1

    -- bonusBox
    local box = _moveData.bonusBox
    local boxY = box:getPositionY()
    box:setPositionY(boxY + totalDistance)

    self.m_moveDownHandler =
        scheduler.scheduleUpdateGlobal(
        function(dt)
            curProgress = curDistance / totalDistance

            local moveDistance = -speed * dt
            -- 最后一次移动
            if curDistance + moveDistance >= totalDistance then
                moveDistance = totalDistance - curDistance
            end
            curDistance = curDistance + math.abs(moveDistance)

            -- 刷新坐标
            for iCol, _list in ipairs(self.m_slideSymbol) do
                for iRow, _symbolNode in ipairs(_list) do
                    local nextPosY = _symbolNode:getPositionY() + moveDistance
                    _symbolNode:setPositionY(nextPosY)
                end
            end
            box:setPositionY(box:getPositionY() + moveDistance)

            -- 刷新信号重制位置
            for iCol, _list in ipairs(self.m_slideSymbol) do
                local firstSymbol = _list[1]
                local lastSymbol = _list[#_list]
                -- 首行信号超过了最大高度，移除添加到尾部
                while firstSymbol:getPositionY() <= topY and lastSymbol.p_rowIndex < maxRow do
                    -- 修改行索引
                    firstSymbol.p_rowIndex = lastSymbol.p_rowIndex + 1
                    local mutil = self:getMultiByReelPos(iCol, firstSymbol.p_rowIndex)
                    local nextSymbolType = self:getSymbolTypeByMulti(mutil)
                    local ccbName = self:getSymbolCCBNameByType(self, nextSymbolType)
                    -- 修改信号类型和展示
                    firstSymbol:changeCCBByName(ccbName, nextSymbolType)
                    firstSymbol:changeSymbolImageByName(ccbName)
                    self:updateReelGridNode(firstSymbol)
                    -- 乘倍分值
                    self:upDateMultiSymbolScore(firstSymbol)
                    -- 修改Y坐标
                    local nextPosY = lastSymbol:getPositionY() + self.m_reSpinNodeSize.height
                    firstSymbol:setPositionY(nextPosY)

                    firstSymbol = table.remove(_list, 1)
                    table.insert(_list, firstSymbol)
                    firstSymbol = _list[1]
                    lastSymbol = _list[#_list]
                end
            end

            --结束移动
            if curDistance >= totalDistance then
                if self.m_moveDownHandler then
                    scheduler.unscheduleGlobal(self.m_moveDownHandler)
                    self.m_moveDownHandler = nil
                end
                if _fun then
                    _fun()
                end
            end
        end
    )
end

function BombPurrglarMiniMachine:changeBigReelVisible(_visible)
    self:findChild("reel_kuangBig"):setVisible(_visible)
    self:findChild("reel_kuang"):setVisible(not _visible)
end

function BombPurrglarMiniMachine:changeBonusBoxParentSize(_enlarge)
    local oldSize = self.m_bigReelClipSize
    local size = _enlarge and cc.size(oldSize.width, oldSize.height + 20) or oldSize
    self.m_bigReelClipNode:setContentSize(size)
end

--[[
    红色背景下落

    _data ={
        moveTime = 0,          移动时间
        resilienceTime = 0,    回弹时间
        startPos = cc.p(0, 0), 起始位置 （世界）
        resilienceHeight = 0,  回弹高度
    }
]]
function BombPurrglarMiniMachine:playRedBgDownAnim(_data)
    local redBg = self:findChild("Sprite_redBg")
    local oldPos = cc.p(501, 86)
    local startPos = redBg:getParent():convertToNodeSpace(_data.startPos)
    redBg:setPositionY(startPos.y)

    local actList = {}
    local distance = (oldPos.y - startPos.y) - _data.resilienceHeight
    actList[#actList + 1] = cc.MoveBy:create(_data.moveTime, cc.p(0, distance))
    actList[#actList + 1] = cc.MoveBy:create(_data.resilienceTime, cc.p(0, _data.resilienceHeight))
    -- actList[#actList+1] = cc.CallFunc:create(function(  )
    --     redBg:setVisible(false)
    -- end)

    self:changeRedBgVisible(true)
    redBg:runAction(cc.Sequence:create(actList))
end

function BombPurrglarMiniMachine:changeRedBgVisible(_visible)
    self:findChild("Sprite_redBg"):setVisible(_visible)
end

--[[
    玩家结束提示
]]
function BombPurrglarMiniMachine:playRespinOverTip(_fun)
    local totoalTimes = #(self.m_resultData.data.userMultipleList)

    if totoalTimes - self.m_curSpinTimes <= 2 and not self.m_bPlayOverTip then
        self.m_bPlayOverTip = true

        gLobalSoundManager:playSound(self.m_machineConfig.Sound_Bonus_overTip)
        self.m_overTip:setVisible(true)
        self.m_overTip:runCsbAction(
            "auto",
            false,
            function()
                self.m_overTip:setVisible(false)

                self.m_machine:changeGameBgAction("bonus2")
                if _fun then
                    _fun()
                end
            end
        )

        -- 顶部金色光效
        self:changeTopLightVisible(true)
    else
        if _fun then
            _fun()
        end
    end
end
--[[
    其他工具判断
]]
function BombPurrglarMiniMachine:changeMiniCCBByName()
end
-- 传入卷轴坐标返回一个信号值,
function BombPurrglarMiniMachine:getSymbolTypeByReelPos(_iCol, _iRow)
    local symbolType = self.m_machine.SYMBOL_BONUSGAME_BLANK

    -- 低于轮盘最大行数，优先取spin数据
    local reels = self.m_spinReels
    local lineIndex = self.m_iReelRowNum + 1 - _iRow

    if _iRow <= self.m_iReelRowNum and reels[lineIndex] and reels[lineIndex][_iCol] then
        symbolType = reels[lineIndex][_iCol]
        -- 如果是当前轮盘上的乘倍小块，需要分一下背景颜色
        if self:isBombPurrglarBonusMuti(symbolType) then
            local multipleReel = self.m_userMultipleReel[_iCol]
            if _iRow <= #multipleReel then
                local multi = multipleReel[_iRow]
                symbolType = self:getSymbolTypeByMulti(multi)
            end
        end
    else
        local multipleReel = self.m_userMultipleReel[_iCol]
        if _iRow <= #multipleReel then
            -- 超过乘倍卷轴+1的位置是金钥匙
            local multi = multipleReel[_iRow]
            if multi > 0 then
                symbolType = self:getSymbolTypeByMulti(multi)
            elseif multi < 0 then
                symbolType = self.m_machine.SYMBOL_BONUS_3
            end
        elseif _iRow == #multipleReel + 1 then
            symbolType = self.m_machine.SYMBOL_BONUSGAME_GOLDKEY
        end
    end

    return symbolType
end
-- 传入乘倍值返回一个信号值
function BombPurrglarMiniMachine:getSymbolTypeByMulti(_multi)
    local symbolType = self.m_machine.SYMBOL_BONUSGAME_BLANK

    -- 按照乘倍范围返回信号 金->银->红
    if _multi >= 100 then
        symbolType = self.m_machine.SYMBOL_BONUSGAME_MULTI_SILVER
    elseif _multi > 0 then
        symbolType = self.m_machine.SYMBOL_BONUSGAME_MULTI_RED
    end

    return symbolType
end
-- 传入一个卷轴坐标返回一个乘倍
function BombPurrglarMiniMachine:getMultiByReelPos(_iCol, _iRow)
    local multipleReel = self.m_userMultipleReel[_iCol]
    local multi = multipleReel[_iRow] or 0
    multi = multi > 0 and multi or 0
    return multi
end
-- 刷新一个乘倍小块的数值 , 使用信号本身位置或者传入位置
function BombPurrglarMiniMachine:upDateMultiSymbolScore(_multiSymbol, _iCol, _iRow)
    if self:isBombPurrglarBonusMuti(_multiSymbol.p_symbolType) then
        local iCol = _iCol or _multiSymbol.p_cloumnIndex
        local iRow = _iRow or _multiSymbol.p_rowIndex

        local labCoins = _multiSymbol:getCcbProperty("m_lb_coins")
        local multi = self:getMultiByReelPos(iCol, iRow)
        labCoins:setString(string.format("X%d", multi))
        self:updateLabelSize({label = labCoins, sx = 0.42, sy = 0.42}, 266)
    end
end

function BombPurrglarMiniMachine:addMultiSymbolLab(_symbolNode)
    if self:isBombPurrglarBonusMuti(_symbolNode.p_symbolType) then
        self:removeMultiSymbolLab(_symbolNode)

        local labParent = _symbolNode:getCcbProperty("Node_coin")
        if labParent then
            local labCocosName = "Socre_BombPurrglar_bonus_zi"
            local labCocosNode = labParent:getChildByName(labCocosName)
            if not labCocosNode then
                labCocosNode = util_createAnimation("Socre_BombPurrglar_bonus_zi.csb")
                labParent:addChild(labCocosNode)
                labCocosNode:setName(labCocosName)
            end
            -- 重置一下节点属性
            labCocosNode:setPosition(cc.p(0, 0))
            labCocosNode:setVisible(true)
        end
    end
end
function BombPurrglarMiniMachine:removeMultiSymbolLab(_symbolNode)
    if self:isBombPurrglarBonusMuti(_symbolNode.p_symbolType) then
        local labCocosName = "Socre_BombPurrglar_bonus_zi"
        local labCocosNode = _symbolNode:getCcbProperty(labCocosName)
        if labCocosNode then
            labCocosNode:removeFromParent()
        end
    end
end
--
function BombPurrglarMiniMachine:isBombPurrglarBonusMuti(_symbolType)
    if _symbolType == self.m_machine.SYMBOL_BONUSGAME_MULTI_SILVER or _symbolType == self.m_machine.SYMBOL_BONUSGAME_MULTI_RED then
        return true
    end

    return false
end

-- 创建消除玩法中被消除的临时小块
function BombPurrglarMiniMachine:createBombPurrglarTempSymbol(_symbolType, _iCol, _iRow)
    local symbol = self:getSlotNodeWithPosAndType(_symbolType, _iRow, _iCol, true)
    local order = self:getBounsScatterDataZorder(_symbolType) - 10 * _iCol
    self.m_tempSymbolClip:addChild(symbol, order)

    return symbol
end

--
function BombPurrglarMiniMachine:changeSlotParentsVisible(_visible)
    for iCol, _parentData in ipairs(self.m_slotParents) do
        _parentData.slotParent:setVisible(_visible)
    end
end
--
function BombPurrglarMiniMachine:upDateBlankSymbolVisible(_symbol, _iCol, _iRow)
    if _symbol.p_symbolType == self.m_machine.SYMBOL_BONUSGAME_BLANK then
        local iCol = _iCol or _symbol.p_cloumnIndex
        local iRow = _iRow or _symbol.p_rowIndex
        local multipleReel = self.m_userMultipleReel[iCol]

        if multipleReel and iRow > #multipleReel then
            _symbol:setVisible(false)
        end
    end
end

--[[
    模拟请求滚动数据返回
]]
-- 消息返回
function BombPurrglarMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:updateNetWorkData()
end
------------------------------------------------------------一些特殊操作重写父类接口

--新滚动使用
function BombPurrglarMiniMachine:updateReelGridNode(symblNode)
    self:addMultiSymbolLab(symblNode)
    -- symblNode:setOpacity(255)
end
function BombPurrglarMiniMachine:pushSlotNodeToPoolBySymobolType(symbolType, gridNode)
    self:removeMultiSymbolLab(gridNode)
    BombPurrglarMiniMachine.super.pushSlotNodeToPoolBySymobolType(self, symbolType, gridNode)
end
function BombPurrglarMiniMachine:pushAnimNodeToPool(animNode, symbolType)
    self:removeMultiSymbolLab()
    BombPurrglarMiniMachine.super.pushAnimNodeToPool(self, animNode, symbolType)
end
function BombPurrglarMiniMachine:getAnimNodeFromPool(symbolType, ccbName)
    local node = BombPurrglarMiniMachine.super.getAnimNodeFromPool(self, symbolType, ccbName)
    -- self.m_machine:removeScatterSpineNode(node )
    return node
end

-- 解决落地动画
function BombPurrglarMiniMachine:playCustomSpecialSymbolDownAct(slotNode)
    BombPurrglarMiniMachine.super.playCustomSpecialSymbolDownAct(self, slotNode)
end

function BombPurrglarMiniMachine:MachineRule_SpinBtnCall()
    return false -- 用作延时点击spin调用
end

return BombPurrglarMiniMachine
