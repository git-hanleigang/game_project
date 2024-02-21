---
-- xcyy
-- 2018-12-18 
-- MrCashMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"


local MrCashMiniMachine = class("MrCashMiniMachine", BaseMiniFastMachine)


MrCashMiniMachine.SYMBOL_JP_101 = 101
MrCashMiniMachine.SYMBOL_JP_102 = 102
MrCashMiniMachine.SYMBOL_JP_103 = 103
MrCashMiniMachine.SYMBOL_JP_104 = 104
MrCashMiniMachine.SYMBOL_JP_105 = 105
MrCashMiniMachine.SYMBOL_JP_106 = 106
MrCashMiniMachine.SYMBOL_JP_107 = 107
MrCashMiniMachine.SYMBOL_JP_108 = 108 -- 有大于 108 的情况 

MrCashMiniMachine.SYMBOL_SCORE_9 =  9  
MrCashMiniMachine.SYMBOL_SCORE_10 =  10
MrCashMiniMachine.SYMBOL_SCORE_MYSTER =  96

MrCashMiniMachine.m_runCsvData = nil

MrCashMiniMachine.gameResumeFunc = nil
MrCashMiniMachine.gameRunPause = nil

MrCashMiniMachine.m_ActEndCall = nil

-- 构造函数
function MrCashMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)

    
end

function MrCashMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_parent = data.parent 
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function MrCashMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MrCashMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MrCash"
end


function MrCashMiniMachine:getMachineConfigName()

    local str = "Mini"
    
    return self.m_moduleName.. str .. "Config"..".csv"
    
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MrCashMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_JP_101 then
        return "Socre_MrCash_jackpot_Num_1"   
    elseif symbolType == self.SYMBOL_JP_102 then
        return "Socre_MrCash_jackpot_Num_2" 
    elseif symbolType == self.SYMBOL_JP_103 then
        return "Socre_MrCash_jackpot_Num_3" 
    elseif symbolType == self.SYMBOL_JP_104 then
        return "Socre_MrCash_jackpot_Num_4" 
    elseif symbolType == self.SYMBOL_JP_105 then
        return "Socre_MrCash_jackpot_Num_5" 
    elseif symbolType == self.SYMBOL_JP_106 then
        return "Socre_MrCash_jackpot_Num_6" 
    elseif symbolType == self.SYMBOL_JP_107 then
        return "Socre_MrCash_jackpot_Num_7" 
    elseif symbolType >= self.SYMBOL_JP_108 then
        return "Socre_MrCash_jackpot_Num_8" 
    elseif symbolType ==  self.SYMBOL_SCORE_9 then
        return "Socre_MrCash_10"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MrCash_11"
    elseif symbolType == self.SYMBOL_SCORE_MYSTER then
        return "Socre_MrCash_Mystery"   

    end  

    return ccbName
end


---
-- 读取配置文件数据
--
function MrCashMiniMachine:readCSVConfigData( )
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(),"LevelMrCashMiniConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData

end

function MrCashMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("GameScreenMrCashMini.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function MrCashMiniMachine:initMachine()
    self.m_moduleName =  self:getModuleName()


    BaseMiniFastMachine.initMachine(self)

end


function MrCashMiniMachine:addLastWinSomeEffect() -- add big win or mega win
    --小轮子不播五连
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

function MrCashMiniMachine:normalSpinBtnCall()

end

function MrCashMiniMachine:spinResultCallFun(param)
end

function MrCashMiniMachine:calculateLastWinCoin()

end

function MrCashMiniMachine:setCurrSpinMode( spinMode )
    self.m_currSpinMode = spinMode
end
function MrCashMiniMachine:getCurrSpinMode( )
    return self.m_currSpinMode
end

function MrCashMiniMachine:setGameSpinStage( spinStage )
    self.m_currSpinStage = spinStage
end
function MrCashMiniMachine:getGameSpinStage( )
    return self.m_currSpinStage
end

function MrCashMiniMachine:setLastWinCoin( winCoin )
    self.m_lastWinCoin = winCoin
end
function MrCashMiniMachine:getLastWinCoin(  )
    return self.m_lastWinCoin
end


function MrCashMiniMachine:setRunCsvData( csvData )
    self.m_runCsvData = csvData
end
function MrCashMiniMachine:getRunCsvData( )
    return self.m_runCsvData
end


----------------------------- 玩法处理 -----------------------------------

function MrCashMiniMachine:addSelfEffect()

end


function MrCashMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end




function MrCashMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MrCashMiniMachine:enterGamePlayMusic()
    -- do nothing
end


function MrCashMiniMachine:checkNotifyUpdateWinCoin( )



end

function MrCashMiniMachine:slotReelDown()
    BaseMiniFastMachine.slotReelDown(self) 
end


---
-- 每个reel条滚动到底
function MrCashMiniMachine:slotOneReelDown(reelCol)
    BaseMiniFastMachine.slotOneReelDown(self,reelCol)

end

function MrCashMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function MrCashMiniMachine:reelDownNotifyChangeSpinStatus()
  
end



function MrCashMiniMachine:playEffectNotifyNextSpinCall( )

end


function MrCashMiniMachine:quicklyStopReel()

    -- BaseMiniFastMachine.quicklyStopReel(self)
end

function MrCashMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function MrCashMiniMachine:removeObservers()
    BaseMiniFastMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function MrCashMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function MrCashMiniMachine:beginMiniReel()

    BaseMiniFastMachine.beginReel(self)

end


-- 消息返回更新数据
function MrCashMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end


function MrCashMiniMachine:dealSmallReelsSpinStates( )
   
end



-- 处理特殊关卡 遮罩层级
function MrCashMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function MrCashMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
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



function MrCashMiniMachine:MachineRule_network_InterveneSymbolMap( )
   
    
end


function MrCashMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end



---
--判断改变freespin的状态
function MrCashMiniMachine:changeFreeSpinModeStatus()

    
end


function MrCashMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MrCashMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function MrCashMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

--检测是否可以增加quest 完成事件
function MrCashMiniMachine:checkAddQuestDoneEffectType( )
    
end


---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MrCashMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function MrCashMiniMachine:clearCurMusicBg( )
    
end

function MrCashMiniMachine:initRandomSlotNodes()
    
    self:randomSlotNodes()
 
end


function MrCashMiniMachine:setActEndCall( func )
    
    self.m_ActEndCall = function(  )
        if func then
            func()
        end

        self.m_ActEndCall = nil
    end

end

-- 这个函数在这个类用作小轮子所有动画播放完毕后的调用函数
function MrCashMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_ActEndCall then

        self.m_ActEndCall()

    end
    
end

-- 这一关小轮子的玩法就不播放连线动画了
function MrCashMiniMachine:showEffect_LineFrame(effectData)


    effectData.p_isPlay = true
    self:playGameEffect()
    

    return true

end

function MrCashMiniMachine:changeBaseReelNode( reelData )
    

    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local symbolType = reelData[iRow][iCol]

            if targSp and targSp.p_symbolType and targSp.p_symbolType ~= symbolType then
                if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                    targSp.p_symbolImage:removeFromParent()
                end
                targSp.p_symbolImage = nil
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType),symbolType)
            end
            
        end

    end

end



return MrCashMiniMachine
