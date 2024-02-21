---
-- xcyy
-- 2018-12-18 
-- BeerHauseMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotsBeerHauseNode = require "CodeBeerHauseSrc.BeerHauseSlotsNode"

local BeerHauseMiniMachine = class("BeerHauseMiniMachine", BaseMiniFastMachine)

BeerHauseMiniMachine.SYMBOL_FSMORE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 -- 101 freespin + 1  暂时加的容错处理，按理说不应该出现这个信号
BeerHauseMiniMachine.SYMBOL_FSMORE_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- 102 freespin + 1
BeerHauseMiniMachine.SYMBOL_FSMORE_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 -- 103 freespin + 2
BeerHauseMiniMachine.SYMBOL_FSMORE_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 -- 104 freespin + 3
BeerHauseMiniMachine.SYMBOL_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94 bonus

BeerHauseMiniMachine.SYMBOL_WILD_GOLD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20 

BeerHauseMiniMachine.m_machineIndex = nil -- csv 文件模块名字
BeerHauseMiniMachine.m_BarrelNodeList = {} -- 酒桶列表
BeerHauseMiniMachine.m_TapNodeList = {} -- 水龙头列表


BeerHauseMiniMachine.m_redBonusTipPos = {21,23} -- 红色提示位置
BeerHauseMiniMachine.m_blueBonusTipPos = {16,18,26,28} -- 蓝色提示位置
BeerHauseMiniMachine.m_redBonusTipNodeList = {} -- 红色
BeerHauseMiniMachine.m_blueBonusTipNodeList = {} -- 蓝色
BeerHauseMiniMachine.m_WildKuangViewList = {} -- Wild变化时亮的框
BeerHauseMiniMachine.m_longWildViewList = {} -- longWild

BeerHauseMiniMachine.WILD_COL_CHANGE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 整列变wild
BeerHauseMiniMachine.ADD_FS_MORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- Add FS MORE times

BeerHauseMiniMachine.gameResumeFunc = nil
BeerHauseMiniMachine.gameRunPause = nil



local normalAuxiliaryReelid = 2
local freespinMainReelid = 3
local freespinAuxiliaryReelid = 4
-- 构造函数
function BeerHauseMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)

    
end

function BeerHauseMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    self.m_BarrelNodeList = {} -- 酒桶列表
    self.m_TapNodeList = {} -- 水龙头列表
    self.m_redBonusTipNodeList = {} -- 红色
    self.m_blueBonusTipNodeList = {} -- 蓝色
    self.m_WildKuangViewList = {}
    self.m_longWildViewList = {} -- longWild

    --init
    self:initGame()
end

function BeerHauseMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

    -- local firstReelLen = 59 -- + (self.m_machineIndex - 1) * 15
    -- self:slotsReelRunData({firstReelLen + 4, firstReelLen + 6, firstReelLen + 8, firstReelLen + 10, firstReelLen + 12})

    self:initWineBarrel( )



    if self.m_machineIndex ~= normalAuxiliaryReelid then
        self:createBonusTipNode()
    end

    self:findChild("Node_tittle"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 2)
    
   
end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function BeerHauseMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BeerHauseMini"
end

function BeerHauseMiniMachine:getMachineConfigName()

    local str = ""

    if self.m_machineIndex ~= freespinMainReelid then 
        str = "_Auxiliary"
    end

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function BeerHauseMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_FSMORE_1 then
        return "Socre_BeerHause_Bonus"
    elseif symbolType == self.SYMBOL_FSMORE_2 then
        return "Socre_BeerHause_Bonus"
    elseif symbolType == self.SYMBOL_FSMORE_3 then
        return "Socre_BeerHause_Bonus"
    elseif symbolType == self.SYMBOL_FIX_BONUS then
        return "Socre_BeerHause_FixBonus"
    elseif symbolType == self.SYMBOL_FSMORE then
        return "Socre_BeerHause_Bonus"
    elseif symbolType == self.SYMBOL_WILD_GOLD then
        return "Socre_BeerHause_Wild_Gold"   
    end  
    return ccbName
end

---
-- 读取配置文件数据
--
function BeerHauseMiniMachine:readCSVConfigData( )
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    globalData.slotRunData.levelConfigData = self.m_configData

    self.m_configData.p_lineCount = 80
    self.m_configData.p_rowNum = 6
    self.m_configData.p_validLineSymNum = 6

end

function BeerHauseMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("BeerHause/GameScreenBeerHauseMini.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function BeerHauseMiniMachine:initMachine()
    self.m_moduleName = "BeerHause" -- self:getModuleName()

    BaseMiniFastMachine.initMachine(self)
end

-- function BeerHauseMiniMachine:operaQuicklyStopReel( )
--     if self.m_bIsUnlock ~= true then
--         return
--     end
--     BaseMiniFastMachine.operaQuicklyStopReel(self)
-- end

function BeerHauseMiniMachine:setWheelStates(state)
    self.m_bIsUnlock = state
end

function BeerHauseMiniMachine:addLastWinSomeEffect() -- add big win or mega win
    if self.m_machineIndex == normalAuxiliaryReelid then
        
        if #self.m_parent.m_vecGetLineInfo == 0 then
            return
        end


        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        if self.getNewBingWinTotalBet then
            lTatolBetNum = self:getNewBingWinTotalBet()
        end
        local WinBetNumRatio = self.m_parent.m_serverWinCoins / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值


        local iBigWinLimit = self.m_parent.m_BigWinLimitRate
        local iMegaWinLimit = self.m_parent.m_MegaWinLimitRate
        local iEpicWinLimit = self.m_parent.m_HugeWinLimitRate
        local iLegendaryLimit = self.m_LegendaryWinLimitRate

        local isHaveBigWin = false
        if WinBetNumRatio >= iLegendaryLimit then
            isHaveBigWin = true
        elseif WinBetNumRatio >= iEpicWinLimit then
            isHaveBigWin = true
        elseif WinBetNumRatio >= iMegaWinLimit then
            isHaveBigWin = true
        elseif WinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
            isHaveBigWin = true
        end

        --判断当前是否有big win或者 mega win  将five of kind 挪掉
        if isHaveBigWin or
            WinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
            self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
        end

        if self:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND)  and self.m_parent:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND) then
                self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
        end

    else
        local lines = self.m_parent.m_vecMiniWheel[freespinMainReelid]:getVecGetLineInfo( )
        if #lines == 0 then
            return
        end

        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        if self.getNewBingWinTotalBet then
            lTatolBetNum = self:getNewBingWinTotalBet()
        end
        local WinBetNumRatio = self.m_parent.m_serverWinCoins / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值


        local iBigWinLimit = self.m_parent.m_BigWinLimitRate
        local iMegaWinLimit = self.m_parent.m_MegaWinLimitRate
        local iEpicWinLimit = self.m_parent.m_HugeWinLimitRate
        local iLegendaryLimit = self.m_LegendaryWinLimitRate

        local isHaveBigWin = false

        if WinBetNumRatio >= iLegendaryLimit then
            isHaveBigWin = true
        elseif WinBetNumRatio >= iEpicWinLimit then
            isHaveBigWin = true
        elseif WinBetNumRatio >= iMegaWinLimit then
            isHaveBigWin = true
        elseif WinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
            isHaveBigWin = true
        end

        --判断当前是否有big win或者 mega win  将five of kind 挪掉
        if isHaveBigWin or
            WinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
            self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
        end

        if self.m_machineIndex == freespinMainReelid then
            if self:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND)  
                and self.m_parent.m_vecMiniWheel[freespinAuxiliaryReelid]:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND) then
                self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
            end

            if self:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND)  
                and  self.m_parent:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND) then
                self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
            end

        else
            if self:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND)  
                and self.m_parent.m_vecMiniWheel[freespinMainReelid]:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND) then
                self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
            end

            if self:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND)  
                and  self.m_parent:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND) then
                self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
            end
        end 

        
         
    end
end

function BeerHauseMiniMachine:calculateLastWinCoin()
--     if self.m_machineIndex == freespinMainReelid then
--         self.m_iOnceSpinLastWin = 0 -- 每次spin 赢得数据清0

--         local clientWinCoins = self:getClientWinCoins()
    
--         self.m_iOnceSpinLastWin = self.m_serverWinCoins
--    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function BeerHauseMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()
    -- loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 3}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE_3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_GOLD,count =  2}
    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function BeerHauseMiniMachine:addSelfEffect()

    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        local triggerFSMore = false
        for iCol = 1, self.m_parent.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelColumnNum  do
            for iRow = self.m_parent.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelRowNum , 1, -1 do
                local targSp = self.m_parent.m_vecMiniWheel[freespinAuxiliaryReelid]:getReelParentChildNode(iCol,iRow)--:getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
               if targSp then
                    if  targSp.p_symbolType == self.SYMBOL_FSMORE
                        or targSp.p_symbolType == self.SYMBOL_FSMORE_1 
                            or targSp.p_symbolType == self.SYMBOL_FSMORE_2 
                                or targSp.p_symbolType == self.SYMBOL_FSMORE_3 then
                            
                                    triggerFSMore = true

                                    break
                    end 
               end
                
            end
        end

        for iCol = 1, self.m_parent.m_vecMiniWheel[freespinMainReelid].m_iReelColumnNum  do
            for iRow = self.m_parent.m_vecMiniWheel[freespinMainReelid].m_iReelRowNum , 1, -1 do
                local targSp = self.m_parent.m_vecMiniWheel[freespinMainReelid]:getReelParentChildNode(iCol,iRow) --:getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
                if targSp then
                    if targSp.p_symbolType == self.SYMBOL_FSMORE
                        or targSp.p_symbolType == self.SYMBOL_FSMORE_1 
                            or targSp.p_symbolType == self.SYMBOL_FSMORE_2 
                                or targSp.p_symbolType == self.SYMBOL_FSMORE_3 then
                            
                                    triggerFSMore = true

                                    break
                    end
                end
                
            end
        end

        if triggerFSMore then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ADD_FS_MORE_EFFECT -- 动画类型
        end



        if self.m_parent.m_runSpinResultData.p_fsExtraData then
            local wildCol = self.m_parent.m_runSpinResultData.p_fsExtraData.wildColumns
            if wildCol and #wildCol > 0 then
                -- 整列变wild
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.WILD_COL_CHANGE_EFFECT -- 动画类型
            end
    
        end

    else

        if self.m_parent.m_runSpinResultData.p_selfMakeData then
            local wildCol = self.m_parent.m_runSpinResultData.p_selfMakeData.wildColumns
            if wildCol and #wildCol > 0 then
                -- 整列变wild
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.WILD_COL_CHANGE_EFFECT -- 动画类型
            end
    
        end
    end

end

function BeerHauseMiniMachine:changeEffectToPlayed(selfEffectType )
    for i=1,#self.m_gameEffects do
        local  effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType == selfEffectType then
            if effectData.p_isPlay == false then
                effectData.p_isPlay = true
                self:playGameEffect()
                break
            end
            
            
        end
    end
end

function BeerHauseMiniMachine:MachineRule_playSelfEffect(effectData)
    
    -- 自定义事件什么也不做，在minireels里只做延时的作用
    if effectData.p_selfEffectType == self.WILD_COL_CHANGE_EFFECT then
    
    elseif effectData.p_selfEffectType ==  self.ADD_FS_MORE_EFFECT then
        
    end

    return true
end

function BeerHauseMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function BeerHauseMiniMachine:checkNotifyUpdateWinCoin( )
    --  mini 轮子不在通知赢钱线的变化了 只有轮子三通知 因为轮子三是Freespin下的主轮子
    -- 这里作为freespin下 连线时通知钱数更新的接口
    if self.m_machineIndex == freespinMainReelid then

        local winLines = self.m_reelResultLines

        if #winLines <= 0  then
            return
        end
         -- 如果freespin 未结束，不通知左上角玩家钱数量变化
         local isNotifyUpdateTop = true
         if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
             isNotifyUpdateTop = false
         end 
    
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_parent.m_iOnceSpinLastWin,isNotifyUpdateTop})

    end
end

---
-- 每个reel条滚动到底
function BeerHauseMiniMachine:slotOneReelDown(reelCol)
    BaseMiniFastMachine.slotOneReelDown(self,reelCol)

    local triggerFSMore = false
    for iCol = 1, self.m_iReelColumnNum  do

        if iCol ==  reelCol then
            for iRow = self.m_iReelRowNum , 1, -1 do
                local targSp = self:getReelParentChildNode(iCol,iRow) 
                if targSp and targSp.p_symbolType then
                    if targSp.p_symbolType == self.SYMBOL_FSMORE_1 
                        or targSp.p_symbolType == self.SYMBOL_FSMORE_2 
                            or targSp.p_symbolType == self.SYMBOL_FSMORE_3 then
                            
                                triggerFSMore = true
                                targSp:runAnim("buling",false,function(  )
                                    targSp:runIdleAnim()
                                end)
                    end
                end
                
            end
        end
        
    end

    if triggerFSMore then
        
    end
end

function BeerHauseMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function BeerHauseMiniMachine:reelDownNotifyChangeSpinStatus()
    -- do nothing 滚动停止不通知
    if self.m_machineIndex == freespinMainReelid then
        gLobalNoticManager:postNotification("ReelDownInFS")
    end
    
end

function BeerHauseMiniMachine:checkGameResumeCallFun( )
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


function BeerHauseMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function BeerHauseMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function BeerHauseMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end


function BeerHauseMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_machineIndex == normalAuxiliaryReelid then
        self.m_parent:setNormalAllRunDown( 1)
    else
        self.m_parent:setFsAllRunDown( 1)
    end

end

function BeerHauseMiniMachine:quicklyStopReel(colIndex)
    if self.m_bIsUnlock ~= true then
        return
    end
    BaseMiniFastMachine.quicklyStopReel(self, colIndex)
end

function BeerHauseMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function BeerHauseMiniMachine:requestSpinReusltData()

        self.m_isWaitingNetworkData = true
    
        self:setGameSpinStage( WAITING_DATA )


end


function BeerHauseMiniMachine:beginMiniReel()


    BaseMiniFastMachine.beginReel(self)

end




function BeerHauseMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function BeerHauseMiniMachine:enterLevel( )
    
end

function BeerHauseMiniMachine:enterLevelMiniSelf( )

    BaseMiniFastMachine.enterLevel(self)
    
end

-- 初始化上次游戏状态数据
--
function BeerHauseMiniMachine:initMiniGameStatusData(gameData)
    
    local spin = gameData.spin

    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end
 

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin,self.m_lineDataPool,self.m_symbolCompares,feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    




end

function BeerHauseMiniMachine:dealSmallReelsSpinStates( )
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    -- do nothing
end


-- 初始化酒桶UI
function BeerHauseMiniMachine:initWineBarrel( )

    self.m_BarrelNodeList = {}
    self.m_TapNodeList = {}
    for i=1,5 do
        local nodeBarrel = self:findChild("tong"..i)
        local barrelView = util_createView("CodeBeerHauseSrc.BeerHauseBarrelView")
        nodeBarrel:addChild(barrelView)
        table.insert( self.m_BarrelNodeList, barrelView )

        local nodetap =  self:findChild("longtou"..i) 
        nodetap:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 150)
        local tapView = util_createView("CodeBeerHauseSrc.BeerHauseWaterTapView")
        nodetap:addChild(tapView)
        
        table.insert( self.m_TapNodeList, tapView )
    end

end

function BeerHauseMiniMachine:setDownCallFunc(func )
    self.m_reelDownCallback = func
end

function BeerHauseMiniMachine:playEffectNotifyNextSpinCall( )
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

function BeerHauseMiniMachine:playWildColumnAct(cols )
    local wildCols = cols
    for i=1,#wildCols do
        local iCol = wildCols[i] + 1
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if targSp.p_symbolType then
                -- if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                --     targSp:changeCCBByName(
                --             self:getSymbolCCBNameByType(self, self.SYMBOL_WILD_GOLD),
                --             self.SYMBOL_WILD_GOLD
                --         )
                -- else
                    targSp:changeCCBByName(
                        self:getSymbolCCBNameByType(self, self.SYMBOL_WILD_GOLD),
                        self.SYMBOL_WILD_GOLD
                    )
                -- end
            end

        end

    end
end


--小块
function BeerHauseMiniMachine:getBaseReelGridNode()
    return "CodeBeerHauseSrc.BeerHauseSlotsNode"
end


-- 处理特殊关卡 遮罩层级
function BeerHauseMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function BeerHauseMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE_1 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE_3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FIX_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
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

function BeerHauseMiniMachine:createBonusTipNode( )


    for i=1,#self.m_redBonusTipPos do
        local tipView = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView","BeerHause_kuang_red" )
        self:findChild("wheel"):addChild(tipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1 )
        tipView.pos = self.m_redBonusTipPos[i]
        table.insert( self.m_redBonusTipNodeList, tipView )

        local pos = cc.p(self:getSixReelsTarSpPos(tipView.pos  )) 
        tipView:setPosition(pos)

    end

    for i=1,#self.m_blueBonusTipPos do
        local tipView = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView","BeerHause_kuang_blue" )
        self:findChild("wheel"):addChild(tipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
        tipView.pos = self.m_blueBonusTipPos[i]
        table.insert( self.m_blueBonusTipNodeList, tipView )

        local pos = cc.p(self:getSixReelsTarSpPos(tipView.pos  )) 
        tipView:setPosition(pos)
    end

end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function BeerHauseMiniMachine:getSixReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPosForSixRow(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--- 6行的情况
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function BeerHauseMiniMachine:getRowAndColByPosForSixRow(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = 6 - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function BeerHauseMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end


function BeerHauseMiniMachine:MachineRule_network_InterveneSymbolMap( )
    if self.m_machineIndex == freespinMainReelid  then
        if self.m_runSpinResultData.p_fsExtraData ~= nil and self.m_runSpinResultData.p_fsExtraData.extraReelsResult ~= nil then
            local resultDatas = self.m_runSpinResultData.p_fsExtraData.extraReelsResult
            self:insetMiniReelsLines(resultDatas)
        end
    end
    
end

function BeerHauseMiniMachine:insetMiniReelsLines(data )
    if data  and type(data.lines) == "table" then

        if #data.lines > 0 then
           if type(self.m_runSpinResultData.p_winLines) ~=  "table" then
                self.m_runSpinResultData.p_winLines= {}
           end     
        end

        for i = 1, #data.lines do
            local lineData = data.lines[i]
            local winLineData = SpinWinLineData.new()
            winLineData.p_id = lineData.id
            winLineData.p_amount = lineData.amount
            winLineData.p_iconPos = {}
            winLineData.p_type = lineData.type
            winLineData.p_multiple = lineData.multiple
            
            self.m_runSpinResultData.p_winLines[#self.m_runSpinResultData.p_winLines + 1] = winLineData
        end
    end
    
end

-- 创建一个reels上层的特殊显示Spine信号信号
function BeerHauseMiniMachine:createOneActionSymbol(endNode,actionName,callBackFunc,_loopname)
    if not endNode or not endNode.m_ccbName  then
          return
    end
    
    local fatherNode = endNode

    local LoopName = _loopname
    local node= nil
    local callFunc = callBackFunc

    node = util_spineCreate(endNode.m_ccbName, true, true)

    local func = function(  )

            if LoopName then
                if isSpine then
                    util_spinePlay(node,LoopName,true)
                else
                    node:playAction(LoopName,true)  
                end
            end

            if callFunc then
                callFunc()
            end
          
    end


    util_spinePlay(node,actionName,false)
    util_spineEndCallFunc(node, actionName,function(  )

            if node then
                node:setVisible(false)
            end
            performWithDelay(self,function(  )
                node:removeFromParent()
            end,0)

            if func then
                func()
            end
    end )

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("wheel"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("wheel"):addChild(node , SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE  + endNode.p_rowIndex + 200)
    node:setPosition(pos)


    return node
end

function BeerHauseMiniMachine:hideAllKuang( )
    for i=1,#self.m_WildKuangViewList do
        local kuang = self.m_WildKuangViewList[i]
        if kuang then
            kuang:setVisible(false) 
            kuang:runCsbAction("idle",false) 
            kuang:removeFromParent()
        end
    end

    self.m_WildKuangViewList = {}
    
end

function BeerHauseMiniMachine:showOneKuang(col )

    local name =  "Socre_BeerHause_kuang2"
    local pos = col -1
    local WildKuangView =  util_createView("CodeBeerHauseSrc.BeerHauseWildKuangView" , name)
    self:findChild("wheel"):addChild(WildKuangView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 4)
    WildKuangView:setPosition(cc.p(self:findChild("sp_reel_"..pos):getPosition()))
    table.insert( self.m_WildKuangViewList, WildKuangView )

    WildKuangView:setVisible(true) 
    WildKuangView:runCsbAction("actionframe",true) 
end

function BeerHauseMiniMachine:hideAllLongWild( )
    for i=1,#self.m_longWildViewList do
        local kuang = self.m_longWildViewList[i]
        if kuang then
            kuang:setVisible(false) 
            kuang:runCsbAction("idle") 
            kuang:removeFromParent()
        end
    end
    self.m_longWildViewList = {}
end

function BeerHauseMiniMachine:showOneLongWild(col )


    local pos = col -1
    local name =  "Socre_BeerHause_CopyWild"
    local longWildView =  util_createView("CodeBeerHauseSrc.BeerHauseLongWildView" , name)
    self:findChild("wheel"):addChild(longWildView,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 100)
    longWildView:setPosition(cc.p(self:findChild("sp_reel_"..pos):getPosition()))
    table.insert( self.m_longWildViewList, longWildView )
    longWildView:setVisible(true) 
    longWildView:playAddWild("actionframe") 

end

function BeerHauseMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function BeerHauseMiniMachine:createOneCSbActionSymbol(endNode,actionName,isSpine)
    if not endNode or not endNode.m_ccbName  then
          return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    
    local node = self:getSlotNodeBySymbolType(endNode.p_symbolType)
    local func = function(  )
          if fatherNode then
                fatherNode:setVisible(true)
          end
          if node then
                node:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
          end
          
    end
    node:runAnim(actionName,false,func)

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("wheel"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("wheel"):addChild(node , SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE  + endNode.p_rowIndex + 200)
    node:setPosition(pos)

    return node
end


function BeerHauseMiniMachine:updateTipNode( level)

    if self.m_machineIndex == normalAuxiliaryReelid then
        return
    end

    for i=1,#self.m_redBonusTipNodeList do
        self.m_redBonusTipNodeList[i]:removeFromParent()
    end

    self.m_redBonusTipNodeList = {}


    for i=1,#self.m_redBonusTipPos do

        local fileName = "BeerHause_kuang_red"

        if level == 0 then  
            fileName = "BeerHause_kuang_blue"
        end

        local tipView = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView",fileName )
        self:findChild("wheel"):addChild(tipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1 )
        tipView.pos = self.m_redBonusTipPos[i]
        table.insert( self.m_redBonusTipNodeList, tipView )
        local pos = cc.p(self:getSixReelsTarSpPos(tipView.pos  )) 
        tipView:setPosition(pos)

    end
 
end



---
--判断改变freespin的状态
function BeerHauseMiniMachine:changeFreeSpinModeStatus()

    
end


return BeerHauseMiniMachine
