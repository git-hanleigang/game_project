---
-- island li
-- 2019年1月26日
-- CodeGameScreenSpartaMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require "Levels.BaseDialog"
local BaseMachine = require "Levels.BaseMachine"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local CodeGameScreenSpartaMachine = class("CodeGameScreenSpartaMachine", BaseFastMachine)

local SpartaSlotsNode = require "CodeSpartaSrc.SpartaSlotsNode"
CodeGameScreenSpartaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--背景切换
local BG_TYPE = 
{ 
    NORMAL_TYPE        = 0,
    NORMAL_TO_FREESPIN = 1,
    FREESPIN_TO_NORMAL = 2
}

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


----自定义信号块
CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- bonus 94
CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS_BG = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 100  -- bonusbg

CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS_4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10  -- bonus4
CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS_5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11  -- bonus5
CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS_6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12  -- bonus6
CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS_7 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14  -- bonus7
CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS_8 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15  -- bonus8
CodeGameScreenSpartaMachine.SYMBOL_SCORE_BONUS_9 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 16  -- bonus9 

--自定义效果
CodeGameScreenSpartaMachine.SPARTA_JACKPOT_EFFECT      = GameEffect.EFFECT_SELF_EFFECT - 1 -- Jackpot效果
CodeGameScreenSpartaMachine.SPARTA_BONUS_CHANGE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- bonus变成其它图标效果
CodeGameScreenSpartaMachine.m_isAllReelDown = nil

-- 构造函数
function CodeGameScreenSpartaMachine:ctor()
    BaseFastMachine.ctor(self)
    --init
    self.m_playAddBonus = false
    self.m_bFirstSpin  = false
    self.m_bonusSymbol = {}           --bonus所在位置
    self.m_bHaveScatter = false       --是否有scatter
    self.m_bScatterPlayIdle = false   --scatter是否在播放action
    self.m_JackpotIconList = {}       --jackpot 小图标所在位置
    self.m_BonusColList = {}          --触发Freespin时Bonus所在列数
    self.m_isFeatureOverBigWinInFree = true
	self:initGame()
end

function CodeGameScreenSpartaMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("SpartaConfig.csv", "LevelSpartaConfig.lua")
    self.m_configData:initMachine(self)
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenSpartaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Sparta"  
end

function CodeGameScreenSpartaMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    self.m_jackPotBar = util_createView("CodeSpartaSrc.SpartaJackPotLayer",self)
    self:findChild("jackpot"):addChild(self.m_jackPotBar)

    --jackpot特效 
    self.m_jackpotNode = self:findChild("FileNode_2")
	self.m_jackpotNodeAct = cc.CSLoader:createTimeline("Sparta_shouji.csb")
	self.m_jackpotNode:runAction(self.m_jackpotNodeAct)
	util_csbPlayForKey(self.m_jackpotNodeAct,"animation0",true)
   
    self.m_EffectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_EffectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
 
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        if self:isTriggerFreeSpin( ) then
            return
        end
        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
            soundTime = 4
        end

        local soundName = "SpartaSounds/sound_sparta_last_win_" .. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
    
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
    self:levelBgEffectChange( BG_TYPE.NORMAL_TYPE )
    
end
function CodeGameScreenSpartaMachine:scaleMainLayer()
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
      
    end
    if  display.height/display.width >= 768/1024 then
        mainScale = 0.95
       
    end
    if display.width < 1370 then
        mainScale = mainScale * 0.95
    end
    self.m_machineRootScale = mainScale
    util_csbScale(self.m_machineNode, mainScale)
end
function CodeGameScreenSpartaMachine:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        if self.m_click == true then
            return 
        end
    end
end

function CodeGameScreenSpartaMachine:checkNotifyUpdateWinCoin( )

    -- 这里作为freespin下 连线时通知钱数更新的接口

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
    end
    local bTriggerFreeSpin = true
    if self:isTriggerFreeSpin( ) then
        bTriggerFreeSpin = false
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop,bTriggerFreeSpin})

end

function CodeGameScreenSpartaMachine:isTriggerFreeSpin( )
    if self.m_runSpinResultData.p_features ~= nil and 
    #self.m_runSpinResultData.p_features > 0 then
    
        local featureLen = #self.m_runSpinResultData.p_features
        for i=1,featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            if featureID ~= 0 then
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenSpartaMachine:initFreeSpinBar()
    -- if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("freespin")
        self.m_baseFreeSpinBar = util_createView("CodeSpartaSrc.SpartaFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, true)
        self.m_baseFreeSpinBar:setPosition(0, 0)
    -- end
end

function CodeGameScreenSpartaMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:runCsbAction("start",false) 
end

function CodeGameScreenSpartaMachine:changeViewNodePos( )

    self.m_RunDi = {}
    for i=1,5 do
        local longRunDi =  self:findChild("sp_reel_" ..i.."_0")
        table.insert( self.m_RunDi, longRunDi )
        longRunDi:setVisible(false)
    end
end
--计算结算时间
function CodeGameScreenSpartaMachine:getFreeSpinShowTime()
    local winCoin =  self.m_iOnceSpinLastWin
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 1
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 3
    end
    return showTime
end

function CodeGameScreenSpartaMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:runCsbAction("over",false) 
end

function CodeGameScreenSpartaMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("SpartaSounds/sound_sparta_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenSpartaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    --test
    -- scheduler.performWithDelayGlobal(
      
    --     function()
    --         self.m_playAddBonus = true
    --     --    self:addAddBonusEffect( 2 )
    --     --    self:addAddBonusEffect( 3 )
    --        self:addAddBonusEffect( 5 )
    --     end,
    --     2.5,
    --     self:getModuleName()
    -- )
end

function CodeGameScreenSpartaMachine:addObservers()
    BaseFastMachine.addObservers(self)
end

--中奖线 上是否有信号9
function CodeGameScreenSpartaMachine:checkIsLinesHaveSymbol9( )

    --如果信号块9 变成wild 则直接返回false
    for i,v in ipairs(self.m_bonusSymbol) do
        if v.rollSignal == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            return  false
        end
    end
    --接下来判断连线上是否有信号块9
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines and #winLines > 0 then
        for i=1,#winLines do
            local lineData = winLines[i]
            if lineData.p_iconPos and #lineData.p_iconPos > 0 then
                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                            return true
                        end
                    end
                end
            end 
        end
    end
    return false
end

function CodeGameScreenSpartaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    scheduler.unschedulesByTargetName("playBonusChangeWild")
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenSpartaMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_Sparta_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_4 then
        return "Socre_Sparta_Bonus_4"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_5 then
        return "Socre_Sparta_Bonus_5"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_6 then
        return "Socre_Sparta_Bonus_6"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_7 then
        return "Socre_Sparta_Bonus_7"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_8 then
        return "Socre_Sparta_Bonus_8"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_9 then
        return "Socre_Sparta_Bonus_9"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_BG then
        return "Socre_Sparta_Bonus_tuowei"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenSpartaMachine:getPreLoadSlotNodes()

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 30},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 30},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 30},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 30},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 30},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 30},

        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 30},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 30}
    }


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS_4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS_5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS_6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS_7,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS_8,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS_9,count =  2}

    return loadNode
end
--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenSpartaMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end
    if symbolType == self.SYMBOL_SCORE_BONUS then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8
    end
    return symbolType

end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenSpartaMachine:MachineRule_initGame(  )
    -- local data =   self.m_runSpinResultData.p_reelsData
    -- dump(data,"CodeGameScreenSpartaMachine   ==== ")
end

--
--单列滚动停止回调
function CodeGameScreenSpartaMachine:slotOneReelDown(reelCol)    
    -- BaseFastMachine.slotOneReelDown(self,reelCol) 
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1)
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end


    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol ) then
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end



    

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            util_playFadeOutAction(reelEffectNode[1],0.5,function()
                reelEffectNode[1]:setVisible(false)
            end)
            -- reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    -- if isTriggerLongRun == true then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    -- end
    --落地
    for iRow = 1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local targSp =  self:setSymbolToClipReel(reelCol,iRow,TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            -- local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,iRow,SYMBOL_NODE_TAG))
            if targSp then
                self.m_bHaveScatter = true
                
                targSp:runAnim("buling",false,function( )
                    targSp:runAnim("idleframe2",true)
                end)

                local soundPath = "SpartaSounds/sound_sparta_scatter_ground.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

                
            end
        end
        if symbolType == self.SYMBOL_SCORE_BONUS then
            local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,iRow,SYMBOL_NODE_TAG))
            if targSp then
                targSp:removeBonusBg()
            end
            local bonusSp =  self:setSymbolToClipReel(reelCol,iRow,self.SYMBOL_SCORE_BONUS)
            if bonusSp then
                bonusSp:runAnim("buling",false,function( )
                bonusSp:runAnim("idleframe",true)
                    if   self.m_bHaveScatter == true then
                        self:playScatterAction(reelCol)
                    end 
                end)
                
                local soundPath = "SpartaSounds/sound_sparta_bonus_ground" ..reelCol ..  ".mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath,self.SYMBOL_SCORE_BONUS )
                else
                    gLobalSoundManager:playSound(soundPath)
                end


            end 
           
        end
    end 
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage( ) ~= QUICK_RUN or self.m_hasBigSymbol == true )then
        self:creatReelRunAnimation(reelCol + 1)
    end
    if reelCol >= 2 then
        local rundi = self.m_RunDi[reelCol-1]
        if rundi:isVisible() then
            util_playFadeOutAction(rundi,0.5,function()
                rundi:setVisible(false)
            end)
        end
    end
    if reelCol == 6 then
        if self.m_fastRunID  then
            -- print("self.m_fastRunID === " .. self.m_fastRunID .."截断")
            gLobalSoundManager:stopAudio(self.m_fastRunID)
            self.m_fastRunID = nil
        end
    end
end

---
--添加金边
function CodeGameScreenSpartaMachine:creatReelRunAnimation(col)
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

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")
    if col == 2 then
        if  self.m_fastRunID ==nil then
            self.m_fastRunID =  gLobalSoundManager:playSound("SpartaSounds/sound_sparta_fast_run.mp3")
        end
    end
    if col >= 2 then
        local rundi = self.m_RunDi[col-1]
        if rundi then
            rundi:setVisible(true)
            util_setCascadeOpacityEnabledRescursion(rundi,true)
            rundi:setOpacity(0)
            util_playFadeInAction(rundi,0.1) 
        end
    end
    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode,true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode,0.1) 
    util_csbPlayForKey(reelAct, "run", true)
    -- gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    -- self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end
--bonus 落地后切换scatter动画
function CodeGameScreenSpartaMachine:playScatterAction(_reelCol )
    if  self.m_bScatterPlayIdle == false then
        self.m_bScatterPlayIdle = true
        self:clearCurMusicBg()
        for iCol = 1,_reelCol do
            for iRow = 1, self.m_iReelRowNum, 1 do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
                    local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol , iRow, SYMBOL_NODE_TAG))
                    if not targSp then
                        targSp = clipSp
                    end
                    
                    if targSp then
                        targSp:runAnim("actionframe",true)
                    end
                end
            end
        end
    end
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenSpartaMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == 1 and nodeNum >= 1 then
        return runStatus.DUANG, true
    else
        return runStatus.NORUN, false
    end
end

function CodeGameScreenSpartaMachine:showRunReelBg(col)

end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenSpartaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self:levelBgEffectChange( BG_TYPE.NORMAL_TO_FREESPIN )
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenSpartaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self:levelBgEffectChange( BG_TYPE.FREESPIN_TO_NORMAL )
end
---------------------------------------------------------------------------
function CodeGameScreenSpartaMachine:initJackpotInfo(jackpotPool,lastBetId)
    self:updateJackpot()
end

function CodeGameScreenSpartaMachine:updateJackpot()
    self.m_jackPotBar:updateJackpotInfo()
end
----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenSpartaMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("SpartaSounds/music_Sparta_custom_enter_fs.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData
    self.m_BonusColList = {}  --获取bonus 出现列数
    if selfdata and selfdata.change ~= nil then
        for k,v in pairs(selfdata.change) do
            local pos = tonumber(k)
            local fixPos = self:getRowAndColByPos(pos)
            table.insert(self.m_BonusColList,  fixPos.iY ) 
        end
    end
    -- local bonusColumns
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            --     effectData.p_isPlay = true
            --     self:playGameEffect()
            -- end,true)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                            self:triggerFreeSpinCallFun()
                            --播放
                            self.m_effectData = effectData
                            self.m_playAddBonus = true
                            for k,v in pairs(self.m_BonusColList) do
                                self:addAddBonusEffect(v)
                            end   
                         end)
           
        end
    end
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("SpartaSounds/sound_sparta_scatter_start.mp3")
    performWithDelay(self,function(  )
        gLobalSoundManager:playSound("SpartaSounds/sound_sparta_freespin_start.mp3")
        showFSView()    
    end,4.0)

end

--重写FreeSpinStart
function CodeGameScreenSpartaMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    return self:showSpartaDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
end

--重写FreeSpinOver
function CodeGameScreenSpartaMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showSpartaDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
end

--添加到 轮盘节点上 适配 
function CodeGameScreenSpartaMachine:showSpartaDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    self:findChild("veiwNode"):addChild(view)
    return view
end

--获取freespin触发时Bonus所在列 滚动变轴假滚
function CodeGameScreenSpartaMachine:getBonusColList( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    self.m_BonusColList = {}  --获取bonus 出现列数
    if selfdata and selfdata.bonusColumns ~= nil then
        for k,v in pairs(selfdata.bonusColumns) do
            local Columns = v
            table.insert(self.m_BonusColList,  (Columns+1)) --服务器从0开始
        end
    end
    return self.m_BonusColList
end

function CodeGameScreenSpartaMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("SpartaSounds/music_Sparta_over_fs.mp3")
    local showFSView = function ( ... )
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:triggerFreeSpinOverCallFun()
            self.m_BonusColList = {}
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.8,sy=0.8},746)
        gLobalSoundManager:playSound("SpartaSounds/sound_sparta_freespin_over.mp3")
    end
    gLobalSoundManager:playSound("SpartaSounds/sound_sparta_freespin_over_start.mp3")
    performWithDelay(self,function(  )
        showFSView()    
    end,3.0)
end



--  检测轮盘第一列是否有Scatter
function CodeGameScreenSpartaMachine:CheckHaveScatter( )
  
    for iRow = 1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][1]
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            return true
        end
    end
    return false
end

function CodeGameScreenSpartaMachine:dealSmallReelsSpinStates( )
    if self:CheckHaveScatter() == false then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
end


--移除bonus拖尾
function CodeGameScreenSpartaMachine:removeBonusBgPanel( )
    for i=1,6 do
        local panel = self:findChild("Panel_" .. i)
        panel:removeAllChildren()
    end
end
-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenSpartaMachine:MachineRule_network_InterveneSymbolMap()

end

function CodeGameScreenSpartaMachine:slotReelDown( )
    BaseMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    self.m_isAllReelDown = true
    
end

function CodeGameScreenSpartaMachine:playEffectNotifyNextSpinCall( )
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
     self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()
        if self.m_bFirstInFreeSpin == true then
            delayTime = 1.0
        end
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenSpartaMachine:MachineRule_afterNetWorkLineLogicCalculate()

    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    
end
function CodeGameScreenSpartaMachine:addLastWinSomeEffect() -- add big win or mega win
    BaseMachine.addLastWinSomeEffect(self)
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end
--设置bonus scatter 层级
function CodeGameScreenSpartaMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_SCORE_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
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

function CodeGameScreenSpartaMachine:getTableNum( array)
    local num = 0
    for k,v in pairs(array) do
        num = num + 1
    end

    return num
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenSpartaMachine:addSelfEffect()

    self.m_bClickSpin = false
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        --jackpot 效果
        if selfdata.jackpot ~= nil  then
            if selfdata.jackpot.position ~= nil and self:getTableNum(selfdata.jackpot.position) > 0 then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.SPARTA_JACKPOT_EFFECT -- 动画类型
            end 
        end
        --bonus 效果
        if selfdata.change ~= nil then
            local len = self:getPlayBonusData( )
            if len > 0 then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.SPARTA_BONUS_CHANGE_EFFECT -- 动画类型
            end
        end
    end
end

function CodeGameScreenSpartaMachine:sortBonusData(_StartPos,_data)
    local wildData = {}
   
    local function isHave( _lsit,_valve)
        for ki,vi in pairs(_lsit) do
            for kj,vj in pairs(vi) do
                if vj == _valve then
                    return true
                end
            end
        end
        return false
    end

    local function findNearRowAndColPos( _col,_row,_index)
        local dataList = {}
        for k,v in pairs(_data) do
            local  otherFixPos = self:getRowAndColByPos(v)
            if (otherFixPos.iY == (_col +_index) and (otherFixPos.iX >= (_row -_index) and otherFixPos.iX <= (_row +_index)))
                or (otherFixPos.iY == (_col -_index) and (otherFixPos.iX >= (_row -_index) and otherFixPos.iX <= (_row +_index))) 
                or (otherFixPos.iX == (_row -_index) and (otherFixPos.iY <= (_col + _index) and otherFixPos.iY >= (_col-_index)))
                or (otherFixPos.iX == (_row +_index) and (otherFixPos.iY <= (_col + _index)and otherFixPos.iY >= (_col-_index)))then
                    if not isHave(wildData,v) then
                    -- print("sortBonusData 第" .._index .."层" .. "==" ..otherFixPos.iY .."==" ..otherFixPos.iX)
                    table.insert( dataList,v)
                end
            end
        end
        return dataList
    end
    local index = 1
    while true do
        local  list = findNearRowAndColPos(_StartPos.iY,_StartPos.iX,index)
        -- print("findNearRowAndColPos 第" ..index .."层" .. "==" .._StartPos.iY .."==" .._StartPos.iX)
        if table.getn(list) > 0 then
            wildData[#wildData+1] = list
        end
        if index > 5 then
            break
        end
        index =  index + 1
    end
    return wildData
end

function CodeGameScreenSpartaMachine:getPlayBonusData( )
    local len = 0
    self.m_bonusSymbol = {}
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    for k,v in pairs(selfdata.change) do
        local changeInfo =  {}
        local pos = tonumber(k)
        changeInfo.bonusPos = pos
        local fixPos = self:getRowAndColByPos(changeInfo.bonusPos)
        changeInfo.iCol = fixPos.iY 
        changeInfo.iRow = fixPos.iX
        changeInfo.rollSignal = v.rollSignal
        changeInfo.posList = self:sortBonusData(fixPos,v.wild)--v.wild
        table.insert( self.m_bonusSymbol,changeInfo)
        len = len + 1
    end
    if len > 0 then
        --从左到右排序 从上到下
        table.sort(self.m_bonusSymbol, function (a, b)
            if tonumber(a.iCol) == tonumber(b.iCol) then
                return a.iRow > b.iRow
            else
                return tonumber(a.iCol) < tonumber(b.iCol)
            end
        end)
    end
    return len
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenSpartaMachine:MachineRule_playSelfEffect(effectData)
    -- 记得完成所有动画后调用这两行
    -- 作用：标识这个动画播放完结，继续播放下一个动画
    -- effectData.p_isPlay = true
    -- self:playGameEffect()
    if effectData.p_selfEffectType == self.SPARTA_BONUS_CHANGE_EFFECT then
        self.m_playBonusNum =  1
        self.m_effectData = effectData
        local  delayTimes = 0
        performWithDelay(self,function(  )
            self:playBonusChangeWildSymbol()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop,true})
            self:setGameSpinStage(GAME_MODE_ONE_RUN)
            self:setSpinBtnStopTouch(false)  
        end, delayTimes)
    elseif effectData.p_selfEffectType == self.SPARTA_JACKPOT_EFFECT then
        self:collectJackpotFly(effectData)
    end

    
	return true
end

function CodeGameScreenSpartaMachine:playBonusChangeWildSymbol()

    if self.m_playBonusNum > #self.m_bonusSymbol then
        self:setGameSpinStage( STOP_RUN )
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_effectData.p_isPlay = true
        self:playGameEffect()
		return
    end

    if #self.m_bonusSymbol > 0 then
        --bonus变wild
        local changeInfo = self.m_bonusSymbol[self.m_playBonusNum]
        local fixPos = self:getRowAndColByPos(changeInfo.bonusPos)
        local targSp = self:getReelParent(fixPos.iY):getChildByTag(self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG))
        local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(fixPos.iY , fixPos.iX, SYMBOL_NODE_TAG))
        if not targSp then
            targSp = clipSp
        end
        if targSp == nil then
            return 
        end
        local bonusType = self:getChangeBonusType(changeInfo.rollSignal)
        -- Bonus变成对应的 bonus 4，5，6，7，8，9
        targSp:changeCCBByName(self:getSymbolCCBNameByType(self,bonusType),bonusType)
        if targSp then

            local changeWild = function()
                local len = 0
                for ki,vi in pairs(changeInfo.posList) do
                    for kj,vj in pairs(vi) do
                        local otherFixPos = self:getRowAndColByPos(vj)
                        local otherTargSp = self:setSymbolToClipReel(otherFixPos.iY,otherFixPos.iX,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                        if otherTargSp then
                            scheduler.performWithDelayGlobal(function()
                                otherTargSp:runAnim("wild",false,function()
                                    if self.m_stopBonusChangeWild == true then
                                        return
                                    end
                                    otherTargSp:changeSymbolToWild(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                    self:BonusChangeWildSetZorder(otherTargSp,otherFixPos.iY,otherFixPos.iX)
                                    otherTargSp:runAnim("idleframe2",true) 
                                end)
                            end,
                            len*0.2,
                            "playBonusChangeWild")
                        end
                    end
                    len = len+1
                end  
                targSp:runAnim("actionframe",false,function()
                    if self.m_stopBonusChangeWild == true then
                        return
                    end
                    targSp:changeSymbolToWild(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    -- targSp:runAnim("idleframe2",true)
                    self:BonusChangeWildSetZorder(targSp,fixPos.iY, fixPos.iX)
                    local  delayTimes = len*0.2
                    if  self.m_playBonusNum == #self.m_bonusSymbol then
                        delayTimes = len*0.2
                    end
                    -- scheduler.performWithDelayGlobal(
                    --     function()
                    --         self.m_playBonusNum = self.m_playBonusNum + 1
                    --         self:playBonusChangeWildSymbol()
                    --     end,
                    --     delayTimes,
                    --     "playBonusChangeWild"
                    -- )
                end)
                scheduler.performWithDelayGlobal(
                        function()
                            self.m_playBonusNum = self.m_playBonusNum + 1
                            self:playBonusChangeWildSymbol()
                        end,
                        2,
                        "playBonusChangeWild"
                    )
            end

            
            -- targSp:runAnim("lizisankai",false,function()
            
                -- self:playFanZhuanParticleEffect(targSp)
                -- gLobalSoundManager:playSound("SpartaSounds/sound_sparta_bonus_small_bomb.mp3")
                targSp:runAnim("fanzhuan",false,function()
                    if self.m_stopBonusChangeWild == true then
                        return
                    end
                    --随机变wild小块
                    scheduler.performWithDelayGlobal(function()
                        gLobalSoundManager:playSound("SpartaSounds/sound_sparta_change_golden.mp3")
                    end,
                    0.42,
                    "playBonusChangeWild"
                    )
                    
                    for ki,vi in pairs(changeInfo.posList) do
                        for kj,vj in pairs(vi) do
                            local otherFixPos = self:getRowAndColByPos(vj)
                            local otherTargSp = self:getReelParent(otherFixPos.iY):getChildByTag(self:getNodeTag(otherFixPos.iY, otherFixPos.iX, SYMBOL_NODE_TAG))
                            if otherTargSp then
                                local zorder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                otherTargSp:setLocalZOrder(zorder + otherFixPos.iX*10)
                                otherTargSp:runAnim("bianjinse",false)
                            end
                        end
                    end  
                    targSp:runAnim("bianjinse",false,function()
                        if self.m_stopBonusChangeWild == true then
                            return
                        end
                        gLobalSoundManager:playSound("SpartaSounds/sound_sparta_bonus_big_bomb.mp3")
                        --次序播放
                        changeWild()
                    end)
                end)
            -- end)
        end
    end
end

--提高层级
function CodeGameScreenSpartaMachine:setSymbolToClipReel(_iCol,_iRow,_type)
    local targSp = self:getReelParent(_iCol):getChildByTag(self:getNodeTag(_iCol, _iRow, SYMBOL_NODE_TAG))
    local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(_iCol , _iRow, SYMBOL_NODE_TAG))
    if not targSp then
        targSp = clipSp
    end
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        if _type == self.SYMBOL_SCORE_BONUS then
             targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_4 + _iCol*10 +_iRow
        elseif  _type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_4 -100 + _iCol*10 +_iRow
        elseif  _type == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3 + _iCol*10 +_iRow
        end
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(
            targSp,
            SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE  + targSp.m_showOrder,
            targSp:getTag()
        )
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end
--重新设置变完bonus后wild层级
function CodeGameScreenSpartaMachine:BonusChangeWildSetZorder(_target,_iCol,_iRow)
    
    if _target ~= nil then
        if _target.__cname ~= nil and _target.__cname == "SlotsNode" then
            _target:resetReelStatus()
        end
        if _target.p_layerTag ~= nil and _target.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            local posWorld =
                self.m_clipParent:convertToWorldSpace(cc.p(_target:getPositionX(), _target:getPositionY()))
            local pos =
                self.m_slotParents[_iCol].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                _target:removeFromParent()
                _target:resetReelStatus()
                local zorder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                _target:setLocalZOrder(zorder + _iCol)
                _target:setPosition(cc.p(pos.x, pos.y))
            self.m_slotParents[_iCol].slotParent:addChild(_target)
        end
    end
end

--重写 上压下
function CodeGameScreenSpartaMachine:createSlotNextNode(parentData)
    if self.m_isWaitingNetworkData == true then
        -- 等待网络数据返回时， 还没开始滚动真信号，所以肯定为false 2018-12-15 18:15:51
        parentData.m_isLastSymbol = false
        self:getReelDataWithWaitingNetWork(parentData)
        return
    end

    parentData.lastReelIndex = parentData.lastReelIndex + 1

    local cloumnIndex = parentData.cloumnIndex
    local columnDatas = self.m_reelSlotsList[cloumnIndex]
    local data = columnDatas[parentData.lastReelIndex]
    if data == nil then -- 在最后滚动过程中由于未滚动停止 ， 所以会继续触发创建
        return
    end
    local columnData = self.m_reelColDatas[cloumnIndex]
    local columnRowNum = columnData.p_showGridCount

    local symbolType = nil
    if tolua.type(data) == "number" then
        symbolType = data

        local rowIndex = parentData.lastReelIndex % columnRowNum --self.m_iReelRowNum
        if rowIndex == 0 then
            rowIndex = columnRowNum--self.m_iReelRowNum
        end

        --上压下
        parentData.order =  self:getBounsScatterDataZorder(symbolType) + rowIndex

        parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        parentData.tag = cloumnIndex * SYMBOL_NODE_TAG + rowIndex
        parentData.reelDownAnima = nil
        parentData.reelDownAnimaSound = nil
        parentData.m_isLastSymbol = false

        parentData.rowIndex = rowIndex
    else
        parentData.isLastNode = false
        symbolType = data.p_symbolType
        --上压下
        parentData.order = data.m_showOrder + data.m_rowIndex
        parentData.tag = data.m_columnIndex * data.m_symbolTag + data.m_rowIndex

        parentData.reelDownAnima = data.m_reelDownAnima
        parentData.reelDownAnimaSound = data.m_reelDownAnimaSound
        parentData.layerTag = data.p_layerTag

        parentData.rowIndex = data.m_rowIndex
        if data.m_rowIndex == columnRowNum then --self.m_iReelRowNum then
            parentData.isLastNode = true
        elseif self.m_bigSymbolInfos[symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[symbolType]
            parentData.order = self:getBounsScatterDataZorder(symbolType)
            if parentData.rowIndex + (addCount - 1) >= columnRowNum then --self.m_iReelRowNum then
                parentData.isLastNode = true
            end
        end

        parentData.m_isLastSymbol = data.m_isLastSymbol
    end

    parentData.symbolType = symbolType

    if self.m_bigSymbolInfos[symbolType] ~= nil then
        local addCount = self.m_bigSymbolInfos[symbolType]
        parentData.lastReelIndex = parentData.lastReelIndex + addCount - 1
    end
end
-- 处理特殊关卡 遮罩层级
function CodeGameScreenSpartaMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    slotParent:getParent():setLocalZOrder(parentData.cloumnIndex*10)
end

function CodeGameScreenSpartaMachine:playFanZhuanParticleEffect(_node )

    local sanParticle1 = cc.ParticleSystemQuad:create("effect/Bouns_sankai_1.plist")
    local sanParticle2 = cc.ParticleSystemQuad:create("effect/Bouns_sankai_2.plist")
    _node:addChild(sanParticle1)
    _node:addChild(sanParticle2)

    sanParticle1:setPosition(0,0)
    sanParticle2:setPosition(0,0)
    scheduler.performWithDelayGlobal(function()
        sanParticle1:removeFromParent()
        sanParticle2:removeFromParent()
    end,
    1.0,
    self:getModuleName())
end

---
-- 根据类型获取对应节点
--
function CodeGameScreenSpartaMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
        
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initMachine(self )
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end
--小块
function CodeGameScreenSpartaMachine:getBaseReelGridNode()
    return "CodeSpartaSrc.SpartaSlotsNode"
end
function CodeGameScreenSpartaMachine:getChangeBonusType(_type)

    if _type == 0 then
        return self.SYMBOL_SCORE_BONUS_9
    elseif _type == 1 then
        return self.SYMBOL_SCORE_BONUS_8
    elseif _type == 2 then
        return self.SYMBOL_SCORE_BONUS_7
    elseif _type == 3 then
        return self.SYMBOL_SCORE_BONUS_6
    elseif _type == 4 then
        return self.SYMBOL_SCORE_BONUS_5
    elseif _type == 5 then
        return self.SYMBOL_SCORE_BONUS_4
    end
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenSpartaMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenSpartaMachine:normalSpinBtnCall( )
    BaseSlotoManiaMachine.normalSpinBtnCall(self) 

    self.m_bHaveScatter = false
    self.m_bScatterPlayIdle = false
    self.m_bFirstSpin =  true
    self.m_bClickSpin = true
    self:removeBonusBgPanel() 

    self:RemoveJackpotIcon()
    self:setMaxMusicBGVolume( )
    self:removeSoundHandler( )
    self.m_bFirstInFreeSpin =  false
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenSpartaMachine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_isAllReelDown = false
    self.m_stopBonusChangeWild = false
    return false -- 用作延时点击spin调用
end

function CodeGameScreenSpartaMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if symbolType ==self.SYMBOL_SCORE_BONUS  then
         if  self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            gLobalSoundManager:playSound("SpartaSounds/sound_sparta_bonus_wei.mp3")
         end
         if  isLastSymbol == false then
            local bonusBg =  self:createBonusBg()
            local pos = self:getNodePosByColAndRow(row, col)
            self:findChild("Panel_" .. col):addChild(bonusBg)
            bonusBg:setPosition(pos)

            local actionList = {}
            actionList[#actionList + 1] = cc.MoveTo:create(2, cc.p(pos.x,-2000))
            actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                bonusBg:removeFromParent()
            end)
            local sq = cc.Sequence:create(actionList)
            bonusBg:runAction(sq)
        end
    end


    if node:isLastSymbol() then

        local reelsIndex = self:getPosReelIdx(row, col)
        local isHave = self:getJackpotIcon(reelsIndex)
        if isHave  then 
            if node.m_Corn == nil then
                node.m_Corn =  self:creatJackPotMarker()
                node.m_Corn:setPosition(cc.p(40, -30))
                node.m_Corn:playAction("idle2",false)
                node:addChild(node.m_Corn,2)
            end
            
        end
        
    end
end
--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenSpartaMachine:getReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)

    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenSpartaMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("Panel_" .. (col))
    local size = reelNode:getContentSize()
    local posX  = size.width * 0.5
    local posY  = size.height - 0.5* self.m_SlotNodeH
    return cc.p(posX, posY)
end
--[[
    @return: bonus 拖尾
]]
function CodeGameScreenSpartaMachine:createBonusBg()
    local name = self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_BONUS_BG)
    local BonusBg = util_createAnimation(name..".csb") 
    return BonusBg
end

function CodeGameScreenSpartaMachine:getJackpotIcon(reelsIndex)

    local isHave = false
    local jackpot = self.m_runSpinResultData.p_selfMakeData.jackpot
    if jackpot and type(jackpot) == "table"   then
        local jackPos = jackpot.position
        if jackPos then
            for k,v in pairs(jackPos) do
                local index = tonumber(v)
                if reelsIndex == index then
                    isHave = true
                end
            end
        end
    end

    return isHave
end
-- 掉落收集动画 start -------------------------------------------------------
function CodeGameScreenSpartaMachine:creatJackPotMarker()
    local csb = util_createAnimation("Sparta_shouji_jiantou.csb")
    return csb
end
function CodeGameScreenSpartaMachine:createMoveJackpotMarker()
    local addNode = cc.Node:create()
    local csb = util_createAnimation("Sparta_shouji_tuowwei.csb")
    csb:playAction("idle2",false)
    addNode:addChild(csb)
    return addNode
end

-- 收集飞jackpot动画
function CodeGameScreenSpartaMachine:collectJackpotFly( effectData)

    local flyTime = 0.5
    local actionframeTimes = 0.5
    local FlyNum = 1
    self.m_JackpotIconList = {}

    scheduler.performWithDelayGlobal(function (  )
        gLobalSoundManager:playSound("SpartaSounds/sound_sparta_collect_jackpot.mp3")
    end,0.5,self:getModuleName())
   
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local reelsIndex = self:getPosReelIdx(iRow, iCol)
            local isHave = self:getJackpotIcon(reelsIndex)

            if isHave then
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if node  then
                    -- 对应位置创建 jackpot 图标
                    local newCorn  = self:createMoveJackpotMarker() 
                    self.m_EffectNode:addChild(newCorn)
                    local pos = cc.p(util_getConvertNodePos(node.m_Corn,newCorn)) 
                    newCorn:setPosition(pos)
                    --移除小块内的jackpot 图标
                    if node.m_Corn then
                        node.m_Corn:stopAllActions()
                        node.m_Corn:removeFromParent()
                        node.m_Corn = nil
                    end 
                   
                    local str = "jiantou" .. FlyNum
                    local jiantouPos = self:findChild(str):getParent():convertToWorldSpace(cc.p(self:findChild(str):getPosition()))
                    local endPos =  self.m_EffectNode:getParent():convertToNodeSpace(cc.p(jiantouPos.x,jiantouPos.y))
                    local actionList = {}
                    actionList[#actionList + 1] = cc.DelayTime:create(actionframeTimes)
                    actionList[#actionList + 1] = cc.ScaleTo:create(0.1,2)
                    actionList[#actionList + 1]  = cc.Spawn:create( cc.ScaleTo:create(flyTime,1), cc.MoveTo:create(flyTime,cc.p(endPos.x ,endPos.y )))
                    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                        newCorn:removeFromParent()
                        local jackIcon =  self:creatJackPotMarker()
                        jackIcon:setPosition(cc.p(endPos.x ,endPos.y ))
                        jackIcon:playAction("fankui",false)
                        self.m_EffectNode:addChild(jackIcon)
                        if self.m_bClickSpin == true then
                            jackIcon:playAction("over",false,function()
                                jackIcon:removeFromParent()
                            end)
                        else
                             table.insert(self.m_JackpotIconList,jackIcon)
                        end
                    end)
                    local sq = cc.Sequence:create(actionList)
                    newCorn:runAction(sq)


                    FlyNum = FlyNum + 1

                end 
            end
        end

    end

    local delayTime = 0.8
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.jackpot ~= nil  then
            if selfdata.jackpot.type ~= -1 then
                delayTime = 2
            end
        end
    end
    scheduler.performWithDelayGlobal(function (  )
        -- 飞行完毕刷新等其他操作
        if self.m_runSpinResultData ==  nil then
            return
        end
        local selfdata = self.m_runSpinResultData.p_selfMakeData
        if selfdata ~= nil then
            if selfdata.jackpot ~= nil  then
                if selfdata.jackpot.type ~= -1 then
                    local jackpotType  =  selfdata.jackpot.type
                    local winLines = self.m_runSpinResultData.p_winLines
                    local jackpotScore = 0
                    if #winLines > 0 then
                        for i,v in ipairs(winLines) do
                            if  v.p_id == -2 then --jackpot 中奖类型-2
                                jackpotScore =   v.p_amount
                            end
                        end
                    end
                    self:clearCurMusicBg()
                    performWithDelay(self,function(  )
                        self:showJackpotWin(jackpotType, jackpotScore, function()
                            local lastWinCoin = globalData.slotRunData.lastWinCoin
                            globalData.slotRunData.lastWinCoin = 0
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{jackpotScore,false,false})
                            globalData.slotRunData.lastWinCoin = lastWinCoin 
                            effectData.p_isPlay = true
                            self:playGameEffect()
                            self:resetMusicBg(true)
                        end)
                    end,0.2)

                else
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end
        end  
    end,delayTime,self:getModuleName())
end

--移除jackpot显示框 上的标志
function CodeGameScreenSpartaMachine:RemoveJackpotIcon()
    for k,v in pairs(self.m_JackpotIconList) do 
        v:playAction("over",false,function()
            v:setVisible(false)
            v:removeFromParent()
        end)
    end
    self.m_JackpotIconList = {}
end

function CodeGameScreenSpartaMachine:showJackpotWin(index,coins,func)
    
    local jackPotWinView = util_createView("CodeSpartaSrc.SpartaJackPotWinView", self)
    jackPotWinView:initViewData(index,coins,func)
    self:findChild("veiwNode"):addChild(jackPotWinView)
end

function CodeGameScreenSpartaMachine:levelBgEffectChange( _type )
    if _type == BG_TYPE.NORMAL_TYPE  then 
        self.m_gameBg:runCsbAction("normal_idle",true)
    elseif _type ==  BG_TYPE.FREESPIN_TO_NORMAL then
        self.m_gameBg:runCsbAction("freespin_change_normal",false,function(  )
            self.m_gameBg:runCsbAction("normal_idle",true)
        end)
    elseif _type == BG_TYPE.NORMAL_TO_FREESPIN then 
        self.m_gameBg:runCsbAction("normal_change_freespin",false,function(  )
            self.m_gameBg:runCsbAction("freespin",true)
        end)
    end
end

function CodeGameScreenSpartaMachine:addAddBonusEffect( _iCol )
    local addBonusSymbol = {}
    for iRow = 1,self.m_iReelRowNum, 1 do
        local node = self:getReelParent(_iCol):getChildByTag(self:getNodeTag(_iCol, iRow, SYMBOL_NODE_TAG))
        local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(_iCol , iRow, SYMBOL_NODE_TAG))
        if not node then
            node = clipSp
        end
        if node then
            node:setVisible(false)
            addBonusSymbol[iRow] = node.p_symbolType 
        end
    end

    local str = "addBonusNode" ..  _iCol
    local SpartaAddBonusView = util_createView("CodeSpartaSrc.SpartaAddBonusView")
  
    self:findChild(str):addChild(SpartaAddBonusView)
    SpartaAddBonusView:initFirstSymbol(addBonusSymbol)
    --传入信号池
    SpartaAddBonusView:setNodePoolFunc(
        function(symbolType)
            return self:getSlotNodeBySymbolType(symbolType)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
    end)

    SpartaAddBonusView:initFeatureUI()

    SpartaAddBonusView:setOverCallBackFun(function()

        util_playFadeOutAction(SpartaAddBonusView,0.5,function()
            SpartaAddBonusView:removeFromParent()
            self.m_playAddBonus = false
        end)

        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(_iCol):getChildByTag(self:getNodeTag(_iCol, iRow, SYMBOL_NODE_TAG))
            local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(_iCol , iRow, SYMBOL_NODE_TAG))
            if not node then
                node = clipSp
            end
            if node then
                node:setVisible(true)
                util_setCascadeOpacityEnabledRescursion(node,true)
                node:setOpacity(0)
                util_playFadeInAction(node,0.1)   
            end
        end
        --开始spin
        if self.m_effectData.p_isPlay == false then
            self.m_bFirstInFreeSpin = true
            self.m_effectData.p_isPlay = true
            self:playGameEffect()    
        end 
        --test
        -- scheduler.performWithDelayGlobal(
        --     function()
        --         self.m_playAddBonus = true
        --         self:addAddBonusEffect( _iCol )
        --     end,
        --     1.5,
        --     self:getModuleName()
        -- )

    end)
    SpartaAddBonusView:setAddBonusFlyEffectCallBackFun(function()
         self:playAddBonusFlyEffect(_iCol)
    end)
    SpartaAddBonusView:beginMove()
   
end

function CodeGameScreenSpartaMachine:playAddBonusFlyEffect(_iCol)

    local _index = xcyy.SlotsUtil:getArc4Random() % 2 + 1
    local addEffect = self:createAddBonusTuoWei(_index)
    self.m_EffectNode:addChild(addEffect,1000)
    local str = "addBonusNode" ..  _iCol
    local addPos = self:findChild(str):getParent():convertToWorldSpace(cc.p(self:findChild(str):getPosition()))
    local endPos =  self.m_EffectNode:getParent():convertToNodeSpace(cc.p(addPos.x,addPos.y))
    addEffect:setPosition(endPos)
    gLobalSoundManager:playSound("SpartaSounds/sound_sparta_add_bonus.mp3")
end

function CodeGameScreenSpartaMachine:createAddBonusTuoWei(_iCol )
    local addNode = cc.Node:create()
    local csb = util_createAnimation("Socre_Sparta_AddBonus_tuowei.csb")
    csb:playAction("buling",false,function ()
        scheduler.performWithDelayGlobal(
            function()
                addNode:removeFromParent()
            end,
            0.5,
            self:getModuleName()
        )  
    end)
    local sprite = csb:findChild("fanzhuanyong")
    if _iCol == 2 then
        sprite:setFlippedX(true)
        -- sprite:setFlippedY(true)
    end
    addNode:addChild(csb)
    return addNode
end

function CodeGameScreenSpartaMachine:setSpinBtnStopTouch(flag)
    self.m_bottomUI.m_spinBtn.m_btnStopTouch = flag
    globalData.slotRunData.isClickQucikStop = false
end

function CodeGameScreenSpartaMachine:quicklyStopReel(colIndex)
    if self.m_isAllReelDown == true  then
        self.m_stopBonusChangeWild = true
        self:stopBonusChangeWild()
    else
        BaseFastMachine.quicklyStopReel(self, colIndex) 
    end
    
end

function CodeGameScreenSpartaMachine:stopBonusChangeWild()
    scheduler.unschedulesByTargetName("playBonusChangeWild")
    
    if #self.m_bonusSymbol > 0 then
        self.m_playBonusNum = #self.m_bonusSymbol
        --bonus变wild
        for i = 1, #self.m_bonusSymbol, 1 do
            local changeInfo = self.m_bonusSymbol[i]
            local fixPos = self:getRowAndColByPos(changeInfo.bonusPos)
            local targSp = self:getReelParent(fixPos.iY):getChildByTag(self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG))
            local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(fixPos.iY , fixPos.iX, SYMBOL_NODE_TAG))
            if not targSp then
                targSp = clipSp
            end
            if targSp == nil then
                return 
            end

            local bonusType = self:getChangeBonusType(changeInfo.rollSignal)
            if targSp and targSp.p_symbolType ~= bonusType and targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,bonusType),bonusType)
            end
            
            if targSp and targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD  then
                for ki,vi in pairs(changeInfo.posList) do
                    for kj,vj in pairs(vi) do
                        local otherFixPos = self:getRowAndColByPos(vj)
                        local otherTargSp = self:setSymbolToClipReel(otherFixPos.iY,otherFixPos.iX,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                        if otherTargSp then
                            -- otherTargSp:runAnim("wild",false,function()
                                otherTargSp:changeSymbolToWild(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                self:BonusChangeWildSetZorder(otherTargSp,otherFixPos.iY,otherFixPos.iX)
                                otherTargSp:runAnim("idleframe2",true) 
                            -- end)
                            
                        end
                    end
                end  
                targSp:runAnim("wild")
                targSp:changeSymbolToWild(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                -- targSp:runAnim("idleframe2",true)
                self:BonusChangeWildSetZorder(targSp,fixPos.iY, fixPos.iX)
                local  delayTimes = 0
                if  i == #self.m_bonusSymbol then
                    scheduler.performWithDelayGlobal(
                        function()
                            self:setGameSpinStage( STOP_RUN )
                            self.m_effectData.p_isPlay = true
                            self:playGameEffect()
                        end,
                        0,
                        self:getModuleName()
                        )
                end
                
            end
        end
    end
end

return CodeGameScreenSpartaMachine






