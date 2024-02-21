---
-- xcyy
-- 2018-12-18 
-- WestRangerMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"

local WestRangerMiniMachine = class("WestRangerMiniMachine", BaseMiniMachine)

WestRangerMiniMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2--95
WestRangerMiniMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1--94
WestRangerMiniMachine.SYMBOL_SCORE_BLANK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7--100

WestRangerMiniMachine.m_machineIndex = nil -- csv 文件模块名字

WestRangerMiniMachine.gameResumeFunc = nil
WestRangerMiniMachine.gameRunPause = nil


local Main_Reels = 1

-- 构造函数
function WestRangerMiniMachine:ctor()
    WestRangerMiniMachine.super.ctor(self)

end

function WestRangerMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machine = data.machine
    self.m_machineIndex = data.index
    self.m_machineRootScale = data.machine.m_machineRootScale

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function WestRangerMiniMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("WestRangerMiniConfig.csv", "LevelWestRangerMiniConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function WestRangerMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WestRanger"
end

--小块
function WestRangerMiniMachine:getBaseReelGridNode()
    return "CodeWestRangerSrc.WestRangerSlotNode"
end

function WestRangerMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function WestRangerMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
    return ccbName

end

---
-- 读取配置文件数据
--
function WestRangerMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function WestRangerMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("WestRanger/GameScreenWestRangerMini.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    
end
---
--
function WestRangerMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    WestRangerMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function WestRangerMiniMachine:addSelfEffect()


    -- -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 7
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.BONUS_FS_WILD_LOCK_EFFECT -- 动画类型
 
end


function WestRangerMiniMachine:MachineRule_playSelfEffect(effectData)
    
    -- if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT  then
        
    -- end

    return true
end

function WestRangerMiniMachine:onEnter()
    WestRangerMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function WestRangerMiniMachine:addObservers()

    WestRangerMiniMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:MachineRule_respinTouchSpinBntCallBack()
        end,
        ViewEventType.RESPIN_TOUCH_SPIN_BTN
    )
    
end

function WestRangerMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function WestRangerMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function WestRangerMiniMachine:quicklyStopReel(colIndex)


end

function WestRangerMiniMachine:onExit()
    WestRangerMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function WestRangerMiniMachine:removeObservers()
    WestRangerMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function WestRangerMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage( WAITING_DATA )
    if self.m_machineIndex == 1 then
        self.m_machine.m_isGetIndexMini = false
        self.m_machine:requestSpinReusltData()

        self.m_machine.m_isPlayRespinGoldSiverSound = false
    end
end


function WestRangerMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    WestRangerMiniMachine.super.beginReel(self)

end


-- 消息返回更新数据
function WestRangerMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:initMiniReelDataMini(self.m_runSpinResultData.p_rsExtraData["reel"..(self.m_machineIndex-1)])
    self:updateNetWorkData()
end

function WestRangerMiniMachine:enterLevel( )
    WestRangerMiniMachine.super.enterLevel(self)
end

function WestRangerMiniMachine:enterLevelMiniSelf( )

    WestRangerMiniMachine.super.enterLevel(self)
    
end

function WestRangerMiniMachine:dealSmallReelsSpinStates( )
    
end



-- 处理特殊关卡 遮罩层级
function WestRangerMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

---
--设置bonus scatter 层级
function WestRangerMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_machine:getBounsScatterDataZorder(symbolType )

end

function WestRangerMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function WestRangerMiniMachine:checkGameResumeCallFun( )
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

function WestRangerMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function WestRangerMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function WestRangerMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



---
-- 清空掉产生的数据
--
function WestRangerMiniMachine:clearSlotoData()
    
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then

        for i=#self.m_lineDataPool,1,-1 do
            self.m_lineDataPool[i] = nil
        end

    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function WestRangerMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function WestRangerMiniMachine:clearCurMusicBg( )
    
end


function WestRangerMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
end

--[[
    reSpin相关
]]
-- 继承底层respinView
function WestRangerMiniMachine:getRespinView()
    return "CodeWestRangerSrc.WestRangerMini.WestRangerRespinView"
end
-- 继承底层respinNode
function WestRangerMiniMachine:getRespinNode()
    return "CodeWestRangerSrc.WestRangerMini.WestRangerRespinNode"
end

--结束移除小块调用结算特效
function WestRangerMiniMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    -- self:playChipCollectAnim()
end

-- 根据本关卡实际小块数量填写
function WestRangerMiniMachine:getRespinRandomTypes( )
    local symbolList = { self.SYMBOL_BONUS1,
        self.SYMBOL_BONUS2,
        self.SYMBOL_SCORE_BLANK}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function WestRangerMiniMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS1, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BONUS2, runEndAnimaName = "buling", bRandom = true},
    }

    return symbolList
end

-- 显示或者消失 锁链
function WestRangerMiniMachine:showOrCloseSuoLian(isShow,num)
    if isShow == "closed" then
        self.m_suolian:setVisible(true)
        self.m_suolian:runCsbAction("idle",true)
        if num < 0 then
            self.m_suolian:findChild("m_lb_num"):setString(0)
        else
            self.m_suolian:findChild("m_lb_num"):setString(num)
        end
        return false
    else
        if self.m_suolian:isVisible() then
            self.m_suolian:findChild("m_lb_num"):setString(0)
            self:waitWithDelay(nil,function()
                self.m_suolian:runCsbAction("actionframe",false,function()
                    self.m_suolian:setVisible(false)
                end)

                gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinChainUnlock.mp3")
            end,0.1) 
            
            return true
        end
    end
end

function WestRangerMiniMachine:showRespinView()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()

    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)

end

function WestRangerMiniMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()
    local isJinSeBonus = false --判断是否是 金色的
    for i,v in ipairs(respinNodeInfo) do
        if v.Type == self.SYMBOL_BONUS2 then
            isJinSeBonus = true
            break
        end
    end
    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            if self.m_machineIndex == 1 then 
                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                -- 更改respin 状态下的背景音乐
                self:changeReSpinBgMusic()
            end
            
            if isJinSeBonus and not self.m_machine.m_isDuanXian then
                if self.m_machineIndex == 4 then 
                    self.m_machine:getRespinChipList()
                    self:waitWithDelay(nil,function()
                        self.m_machine:flyDarkIcon()
                    end,1) 
                    
                end
            else
                self:waitWithDelay(nil,function()
                    self:runNextReSpinReel()
                end,2) 
                
            end
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function WestRangerMiniMachine:changeReSpinStartUI(respinCount)
    self.m_machine:changeReSpinStartUI(respinCount)
end

--ReSpin刷新数量
function WestRangerMiniMachine:changeReSpinUpdateUI(curCount)
    if self.m_machineIndex == 1 then 
        print("当前展示位置信息  %d ", curCount)
        self.m_machine:changeReSpinUpdateUI(curCount,false)
    end
end

--ReSpin结算改变UI状态
function WestRangerMiniMachine:changeReSpinOverUI()

end

-- --重写组织respinData信息
function WestRangerMiniMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

function WestRangerMiniMachine:initMiniReelData(data)
    -- self.m_runSpinResultData:parseResultData(data,self.m_lineDataPool)
    self.m_runSpinResultData.p_reels = data.reels
    self.m_runSpinResultData.p_storedIcons = data.storedIcons
    self.m_runSpinResultData.p_jackpotLoc = data.jackpotLoc
    self.m_runSpinResultData.p_reSpinCurCount = 3
end

function WestRangerMiniMachine:initMiniReelDataMini(data)
    self.m_runSpinResultData.p_reels = data.reels
    self.m_runSpinResultData.p_storedIcons = data.storedIcons
    self.m_runSpinResultData.p_jackpotLoc = data.jackpotLoc
end

-- 给respin小块进行赋值
function WestRangerMiniMachine:setSpecialNodeScore(node)
    local bonusName = {"m_lb_score_yin","m_lb_score_jin","m_lb_mini","m_lb_minor","m_lb_mijor"}
    local symbolNode = node
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end
    
    local coinsView
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        -- local storedIcons = self.m_runSpinResultData.p_rsExtraData["reel"..(self.m_machineIndex-1)].jackpotLoc -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil then
            local symbol_node = symbolNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            if not spineNode.m_csbNode then
                coinsView = util_createAnimation("Socre_WestRanger_Bonus_coin.csb")
                util_spinePushBindNode(spineNode,"text",coinsView)
                spineNode.m_csbNode = coinsView
            else
                coinsView = spineNode.m_csbNode
            end

            if spineNode.m_csbNodeSaoGuang then
                spineNode.m_csbNodeSaoGuang:setVisible(false)
                spineNode.m_csbNodeSaoGuang:removeFromParent()
                spineNode.m_csbNodeSaoGuang = nil
            end
            symbolNode:createBonusAddNode(score, symbolNode.p_symbolType == self.SYMBOL_BONUS2)

            local lineBet = globalData.slotRunData:getCurTotalBet()

            for i,vName in ipairs(bonusName) do
                coinsView:findChild(vName):setVisible(false)
            end
            if score == "mini" then--mini
                coinsView:findChild("m_lb_mini"):setVisible(true)
            elseif score == "minor" then--minor
                coinsView:findChild("m_lb_minor"):setVisible(true)
            elseif score == "major" then--major
                coinsView:findChild("m_lb_mijor"):setVisible(true)
            else
                score = score * lineBet
                score = util_formatCoins(score, 3)
                if symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
                    coinsView:findChild("m_lb_score_yin"):setVisible(true)
                    coinsView:findChild("m_lb_score_yin"):setString(score)
                elseif symbolNode.p_symbolType == self.SYMBOL_BONUS2 then
                    coinsView:findChild("m_lb_score_jin"):setVisible(true)
                    coinsView:findChild("m_lb_score_jin"):setString(score)
                end
                
            end
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                symbolNode:createBonusAddNode(score, symbolNode.p_symbolType == self.SYMBOL_BONUS2)
            end
        end
    end
end

-- 根据网络数据获得respinBonus小块的分数
function WestRangerMiniMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local jackpotLoc = self.m_runSpinResultData.p_jackpotLoc
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    for _, _jackpotInfo in ipairs(jackpotLoc) do
        if _jackpotInfo[1] == idNode then
            score = _jackpotInfo[2]
        end
    end

    return score
end


function WestRangerMiniMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS1 or symbolType == self.SYMBOL_BONUS2 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_machine.m_configData:getFixSymbolPro()
    end

    return score
end

--新滚动使用
function WestRangerMiniMachine:updateReelGridNode(symblNode)
    
    if symblNode.p_symbolType == self.SYMBOL_BONUS1 or symblNode.p_symbolType == self.SYMBOL_BONUS2 then
        self:setSpecialNodeScore(symblNode)
        symblNode:setScale(0.5)
    end
    
end

-- 延时函数
function WestRangerMiniMachine:waitWithDelay(parent, endFunc, time)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

---判断结算
function WestRangerMiniMachine:reSpinReelDown(addNode)
    self:waitWithDelay(nil,function()
        if self.m_machine.m_isGetIndexMini == false then
            self.m_machine:getIndexReelMiniNoJiMan()
        end
        self.m_machine.m_isGetIndexMini = true
        if self.m_machineIndex == self.m_machine.m_IndexReelMini then
            self.m_machine:reSpinSelfReelDown(addNode)
        end
    end,1) 
    
end

--开始下次ReSpin
function WestRangerMiniMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        self.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end

return WestRangerMiniMachine
