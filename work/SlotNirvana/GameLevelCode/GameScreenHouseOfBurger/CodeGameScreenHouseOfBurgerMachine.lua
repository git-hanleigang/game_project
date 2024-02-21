local HouseOfBurgerSlotsNode = require "CodeHouseOfBurgerSrc.HouseOfBurgerSlotsNode"
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenHouseOfBurgerMachine = class("CodeGameScreenHouseOfBurgerMachine", BaseSlotoManiaMachine)

CodeGameScreenHouseOfBurgerMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenHouseOfBurgerMachine.SYMBOL_Wild_Scatter = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7  -- 自定义的小块类型
CodeGameScreenHouseOfBurgerMachine.SYMBOL_2XWild = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 -- 自定义动画的标识

CodeGameScreenHouseOfBurgerMachine.m_betLevel = 0
--往橱柜掉落
CodeGameScreenHouseOfBurgerMachine.DownType = {Type_SpinStart=1,Type_Spinning=2,Type_SpinEnd_Scatter=3,Type_SpinEnd_Bonus=4,Type_SpinEnd = 5}

--往基础轮盘掉落
CodeGameScreenHouseOfBurgerMachine.DropType = {Type_SpinStart=1,Type_Spinning=2,Type_SpinEnd=3}

-- 构造函数
function CodeGameScreenHouseOfBurgerMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)


	--init
	self:initGame()
end

function CodeGameScreenHouseOfBurgerMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenHouseOfBurgerMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "HouseOfBurger"
end


function CodeGameScreenHouseOfBurgerMachine:initUI()
    self:findChild("topUi"):setScale(self:findChild("root"):getScale())

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_mask = self:findChild("mask")
    self.m_mask:setVisible(false)

    self.m_collectCopyView = util_createView("CodeHouseOfBurgerSrc.HouseOfBurgerCollectCopyView",self)
    self:findChild("shouji"):addChild(self.m_collectCopyView)

    self.m_collectView = util_createView("CodeHouseOfBurgerSrc.HouseOfBurgerCollectView",self)
    self:findChild("shouji1"):addChild(self.m_collectView)

    -- self.m_collectView:setPositionY(200)
    self.m_freeSpinBar = util_createView("CodeHouseOfBurgerSrc.HouseOfBurgerFreeSpinBar",self)
    self:findChild("freespinbar"):addChild(self.m_freeSpinBar)
    self.m_freeSpinBar:setVisible(false)


    self.m_freeSpinMul = util_createView("CodeHouseOfBurgerSrc.HouseOfBurgerFreeSpinMul",self)
    self:findChild("beishu"):addChild(self.m_freeSpinMul)
    self.m_freeSpinMul:setVisible(false)

    local logo = util_createAnimation("HouseOfBurger_logo")
    self:findChild("logo"):addChild(logo)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
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
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 4
        end

        -- local soundName = "HouseOfBurgerSounds/music_HouseOfBurger_last_win_".. soundIndex .. ".mp3"
        -- local winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
        --     -- gLobalSoundManager:setBackgroundMusicVolume(1)
        -- end)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenHouseOfBurgerMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        -- gLobalSoundManager:playSound("HouseOfBurgerSounds/music_HouseOfBurger_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
            end

        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenHouseOfBurgerMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:upateBetLevel()

end

function CodeGameScreenHouseOfBurgerMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
        self:changeFreeSpinByCountOutLine(params,num)
    end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)
end


function CodeGameScreenHouseOfBurgerMachine:initGameStatusData(gameData)
    if gameData.feature and  gameData.feature.action == "BONUS" then
        gameData.spin.action = gameData.feature.action
        gameData.spin.features = gameData.feature.features
        gameData.spin.freespin = gameData.feature.freespin

    end
    -- if gameData.spin and gameData.spin.freespin and gameData.spin.freespin.extra then
    --     local freespin = gameData.spin.freespin
    --     self.m_fsReelDataIndex = freespin.extra.select
    -- end

    BaseSlotoManiaMachine.initGameStatusData(self,gameData)

end

---
-- 重连更新freespin 剩余次数
--
function CodeGameScreenHouseOfBurgerMachine:changeFreeSpinByCountOutLine(params,changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.freeSpinCount - changeNum
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self.m_freeSpinbar:updateView(leftFsCount,totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function CodeGameScreenHouseOfBurgerMachine:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    if self.m_freeSpinbar then
        self.m_freeSpinbar:updateView(leftFsCount,totalFsCount)
    end
end
function CodeGameScreenHouseOfBurgerMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end
function CodeGameScreenHouseOfBurgerMachine:checkNeedDrop()

end

function CodeGameScreenHouseOfBurgerMachine:requestSpinResult(spinType,selectIndex)
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        self.m_collectView:updateData(self.DownType.Type_SpinStart,self.m_runSpinResultData.p_selfMakeData.burgerData)
        self.m_collectView:dropNodeToBaseWheel(self.DropType.Type_SpinStart,function(dropList)
            self:realRequest(spinType,selectIndex)
        end)
    else
        self:realRequest(spinType,selectIndex)
    end

end
function CodeGameScreenHouseOfBurgerMachine:realRequest(spinType,selectIndex)
    local betCoin = globalData.slotRunData:getCurTotalBet()

        local totalCoin = globalData.userRunData.coinNum

        local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

        -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
        if self.m_spinIsUpgrade == nil then
            self.m_spinIsUpgrade = false
        end
        if self.m_spinNextLevel == nil then
            self.m_spinNextLevel = globalData.userRunData.levelNum
        end
        if self.m_spinNextProVal == nil then
            self.m_spinNextProVal = globalData.userRunData.currLevelExper
        end
        -- 发送spin action
        local moduleName = self:getNetWorkModuleName()

        local isFreeSpin = true
        --小猪银行
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
            self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
            self:getCurrSpinMode() ~= RESPIN_MODE
        then

            self.m_topUI:updataPiggy(betCoin)
            isFreeSpin = false
        end

        if self:getCurrSpinMode() == RESPIN_MODE then
            self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount-1,self.m_runSpinResultData.p_reSpinsTotalCount)
        end

        self:updateJackpotList()
        local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,data=self.m_collectDataList,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( )}
        if spinType then
            messageData={msg=spinType,data=selectIndex,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( )}
        end
       -- 拼接 collect 数据， jackpot 数据

        -- local operaId =
        httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
            self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end
function CodeGameScreenHouseOfBurgerMachine:spinResultCallFun(param)
    local isSucc = param[1]
    local spinData = param[2]
    -- "selfData":{"burgerData":{"drops":[false,false,false,false,true],
    -- "oldReels":[[8,4,3,8,90],[2,6,4,5,5],[4,8,8,2,2],[7,3,7,4,8]],"oldWilds":[0,3,0,0,8],"wilds":[0,3,0,0,4]}}
    -- spinAddWilds，scAddWilds，chickenAddWilds
    if isSucc then
        if self.m_bProduceSlots_InFreeSpin then
            self.m_freeSpinMul:setVisible(true)
            self.m_freeSpinMul:updateView(spinData.result.freespin.fsMultiplier)
        end

        if spinData.result.selfData and spinData.result.selfData.burgerData then
            local burgeData = spinData.result.selfData.burgerData
            -- spinData.spinAddWilds
            self.m_collectView:updateData(self.DownType.Type_Spinning,burgeData)

            self.m_collectView:downNodeToCupboard(function()
                self.m_collectView:dropNodeToBaseWheel(self.DropType.Type_Spinning,function(isDrop,dropList)
                    if isDrop then
                        self:dropReplaceReelsData(dropList,spinData.result)
                    end
                    if self:checkDrop(burgeData.startDrops) then--开始时候的替换
                        self:dropReplaceReelsData(burgeData.startDrops,spinData.result)
                    end
                    BaseSlotoManiaMachine.spinResultCallFun(self,param)
                    if self.m_bIsSelectCall then
                        self.m_bIsSelectCall = false
                        globalData.slotRunData.freeSpinCount = spinData.result.freespin.freeSpinsLeftCount
                        globalData.slotRunData.totalFreeSpinCount = spinData.result.freespin.freeSpinsTotalCount
                        -- freeSpinNewCount
                        performWithDelay(self,function()
                            self:triggerFreeSpinCallFun()
                            self.m_effectData.p_isPlay = true
                            self:playGameEffect()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Stop, false})
                        end,0.1)

                    end
                end)
            end)
        else
            BaseSlotoManiaMachine.spinResultCallFun(self,param)
        end
    end
end
--转动过程中替换数据
function CodeGameScreenHouseOfBurgerMachine:checkDrop(dropList)
    local need = false
    for i=1,#dropList do
        if dropList[i] then
            need = true
            break
        end
    end
    return need
end

--转动过程中替换数据
function CodeGameScreenHouseOfBurgerMachine:dropReplaceReelsData(dropList,result)
    for i=1,#dropList do
        if dropList[i] then
            for j=1,#result.reels do--p_reels
                result.reels[j][i] = result.selfData.burgerData.oldReels[j][i]
            end
        end
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenHouseOfBurgerMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_Wild_Scatter then
        return "Socre_HouseOfBurger_100"
    end
    if symbolType == self.SYMBOL_2XWild then
        return "Socre_HouseOfBurger_WildX2"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenHouseOfBurgerMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenHouseOfBurgerMachine:MachineRule_initGame(  )
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.burgerData then
        local burgeData = self.m_runSpinResultData.p_selfMakeData.burgerData
        self.m_collectView:initData(burgeData)

        -- if self:checkDrop(burgeData.middleDrops) then--开始时候的替换
        --     self:dropReplaceReelsData(burgeData.middleDrops,self.m_runSpinResultData)
        -- end
        -- if self:checkDrop(burgeData.startDrops) then--开始时候的替换
        --     self:dropReplaceReelsData(burgeData.startDrops,self.m_runSpinResultData)
        -- end
        -- if self:checkDrop(burgeData.endDrops) then--开始时候的替换
        --     self:dropReplaceReelsData(burgeData.endDrops,self.m_runSpinResultData)
        -- end
        self.m_runSpinResultData.p_reels = burgeData.oldReels
    end
    -- self:showMask()
end

--
--单列滚动停止回调
--
function CodeGameScreenHouseOfBurgerMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)
    -- local isplay= true
    -- if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
    --     for i = 1, self.m_iReelRowNum, 1 do
    --         if self:isBulingSymbol(self.m_stcValidSymbolMatrix[i][reelCol]) then
    --             local symbolNode = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,i,SYMBOL_NODE_TAG))
    --             symbolNode:runAnim("buling",false,function()
    --                 -- if
    --             end)
    --             symbolNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
    --         end
    --     end
    --     local isHaveFixSymbol = false
    --     for k = 1, self.m_iReelRowNum do
    --         if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
    --             isHaveFixSymbol = true
    --             break
    --         end
    --     end
    --     if isHaveFixSymbol == true and isplay then
    --         isplay = false
    --         -- respinbonus落地音效
    --         -- gLobalSoundManager:playSound("HouseOfBurgerSounds/music_HouseOfBurger_fall_" .. reelCol ..".mp3")
    --     end
    -- else


    -- end
end

--滚轮彻底停止
function CodeGameScreenHouseOfBurgerMachine:slotReelDown()
    self:hideMask()

    performWithDelay(self,function()
        --先处理scatter
        self.m_collectView:updateData(self.DownType.Type_SpinEnd_Scatter,self.m_runSpinResultData.p_selfMakeData.burgerData)
        self.m_collectView:downNodeToCupboard(function()
            --再处理bonus
            self.m_collectView:updateData(self.DownType.Type_SpinEnd_Bonus,self.m_runSpinResultData.p_selfMakeData.burgerData)
            self.m_collectView:downNodeToCupboard(function()
                --最后开始处理spin结束的  掉落
                -- self.m_collectView:updateData(self.DownType.Type_SpinEnd,self.m_runSpinResultData.p_selfMakeData.burgerData)
                self.m_collectView:dropNodeToBaseWheel(self.DropType.Type_SpinEnd,function(isDrop,dropList)
                    if isDrop then
                        self:dropReplaceReels(dropList,self.m_runSpinResultData.p_selfMakeData.burgerData.oldReels)
                        self.m_collectView:clearDropedNode()
                        BaseSlotoManiaMachine.slotReelDown(self)
                    else
                        BaseSlotoManiaMachine.slotReelDown(self)
                        self.m_collectView:clearDropedNode()
                    end
                end)
            end)
        end)
    end,2)



end
--转动停止后替换滚轮
function CodeGameScreenHouseOfBurgerMachine:dropReplaceReels(dropList,reels)
    for iCol = 1, self.m_iReelColumnNum  do
        if dropList[iCol] then

            for iRow = 1, self.m_iReelRowNum do
                local symbolType = reels[iRow][iCol]
                -- local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
                if targSp then
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType),symbolType)
                    targSp:runAnim("idleframe")
                    local order = self:getBounsScatterDataZorder(symbolType) - targSp.p_rowIndex
                    targSp.p_showOrder = order
                    targSp:setLocalZOrder(order)
                end
            end

        end

    end

end



function CodeGameScreenHouseOfBurgerMachine:delaySlotReelDown()
    BaseSlotoManiaMachine.delaySlotReelDown(self)

end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenHouseOfBurgerMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenHouseOfBurgerMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")

end
---------------------------------------------------------------------------

function CodeGameScreenHouseOfBurgerMachine:showEffect_Bonus(effectData)
    -- if self.m_runSpinResultData.p_selfMakeData then
    --     self.m_iFreeSpinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_FREESPIN.times
    --     if self.m_bProduceSlots_InFreeSpin == false then
    --         self.m_iRespinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_RESPIN.times
    --     end
    -- end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    if scatterLineValue ~= nil then
        --
        -- util_spinePlay(self.m_chilliPlayer,"actionframe",false)
        -- performWithDelay(self,function()
        --     util_spinePlay(self.m_chilliPlayer,"idleframe",true)
        --     self:showFreeSpinView(effectData)
        -- end,4.05)

        gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move

        -- gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_scatterTrigger.mp3")

        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)

        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenHouseOfBurgerMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("HouseOfBurgerSounds/music_HouseOfBurger_custom_enter_fs.mp3")

    -- local showFSView = function ( ... )
    --     if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    --         self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
    --             effectData.p_isPlay = true
    --             self:playGameEffect()
    --         end,true)
    --     else
    --             self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
    --             self:triggerFreeSpinCallFun()
    --             effectData.p_isPlay = true
    --             self:playGameEffect()
    --         end)
    --     end
    -- end

    -- --  延迟0.5 不做特殊要求都这么延迟
    -- performWithDelay(self,function(  )
    --         showFreeSpinView()
    -- end,0.5)

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then

        local m_freeSpinChose=util_createView("CodeHouseOfBurgerSrc.HouseOfBurgerFreeSpinChoose",self.m_runSpinResultData.p_selfMakeData,function(spinType)
            self.m_bIsSelectCall = true
            self.m_effectData = effectData
            local sumNum = self.m_runSpinResultData.p_selfMakeData["triggerTimes_"..spinType].times

            -- if self.m_freeSpinChose then
            --     self.m_freeSpinChose:removeFromParent()
            -- end
            self.m_freeSpinBar:setVisible(true)
            self.m_freeSpinBar:updateView(sumNum,sumNum)

            self.m_freeSpinMul:setVisible(true)
            self.m_freeSpinMul:updateView(0)

            performWithDelay(self,function()
                self:requestSpinResult(MessageDataType.MSG_BONUS_SELECT,spinType)
            end,2)
        end,self)
        gLobalViewManager:showUI(m_freeSpinChose)


    else

        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:showFreeSpinMore(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            true
        )
        -- gLobalSoundManager:setBackgroundMusicVolume(0.4)
        -- gLobalSoundManager:playSound("LightCherrySounds/music_lightcherry_custom_enter_fs_2.mp3",false, function(  )
        --     gLobalSoundManager:setBackgroundMusicVolume(1)
        -- end)
    end

end

function CodeGameScreenHouseOfBurgerMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("HouseOfBurgerSounds/music_HouseOfBurger_over_fs.mp3")

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
function CodeGameScreenHouseOfBurgerMachine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)




    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenHouseOfBurgerMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenHouseOfBurgerMachine:MachineRule_afterNetWorkLineLogicCalculate()


    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenHouseOfBurgerMachine:addSelfEffect()


        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenHouseOfBurgerMachine:MachineRule_playSelfEffect(effectData)

    -- if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then

        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        effectData.p_isPlay = true
        self:playGameEffect()

    -- end


	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenHouseOfBurgerMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end


function CodeGameScreenHouseOfBurgerMachine:getBetLevel( )
    return self.m_betLevel
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenHouseOfBurgerMachine:upateBetLevel()

    local minBet = self:getMinBet( )

    self:updateHighLowBetLock( minBet )
end

function CodeGameScreenHouseOfBurgerMachine:getMinBet( )
    local minBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenHouseOfBurgerMachine:updateHighLowBetLock( minBet )
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_clickBet = true
            self.m_betLevel = 1
            -- self.m_betChoiceIcon:setVisible(false)
        else

        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_clickBet = false
            self.m_betLevel = 0
            -- self.m_betChoiceIcon:setVisible(true)
        end
    end
end

function CodeGameScreenHouseOfBurgerMachine:showChoiceBetView( )
    self.highLowBetView = util_createView("CodeHouseOfBurgerSrc.HouseOfBurgeHighLowBetView",self)
    gLobalViewManager:showUI(self.highLowBetView)
end

function CodeGameScreenHouseOfBurgerMachine:unlockHigherBet()
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end


function CodeGameScreenHouseOfBurgerMachine:showMask()
    self.m_mask:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self.m_mask:setVisible(true)
end

function CodeGameScreenHouseOfBurgerMachine:hideMask()
    self.m_mask:setVisible(false)
end

--小块
function CodeGameScreenHouseOfBurgerMachine:getBaseReelGridNode()
    return "CodeHouseOfBurgerSrc.HouseOfBurgerSlotsNode"
end


return CodeGameScreenHouseOfBurgerMachine