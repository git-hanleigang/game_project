---
-- island li
-- 2019年1月26日
-- CodeGameScreenMrCashMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenMrCashMachine = class("CodeGameScreenMrCashMachine", BaseNewReelMachine)

CodeGameScreenMrCashMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenMrCashMachine.SYMBOL_SCORE_9 =  9  
CodeGameScreenMrCashMachine.SYMBOL_SCORE_10 =  10
CodeGameScreenMrCashMachine.SYMBOL_SCORE_MYSTER =  96


CodeGameScreenMrCashMachine.MysteryType_Drawing = "drawing" -- 开门信号拉满整列的玩法
CodeGameScreenMrCashMachine.TriggerType_Wheel = "wheel" -- 触发了转盘玩法


CodeGameScreenMrCashMachine.OPEN_DOOR_TURN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 开门图标变成其他信号
CodeGameScreenMrCashMachine.OPEN_DOOR_MOVE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 开门图标移动使其他图标变成开门图标

CodeGameScreenMrCashMachine.DEALT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- 等待事件第一个执行
CodeGameScreenMrCashMachine.m_CashManBodyLongRunAct = false 

CodeGameScreenMrCashMachine.m_initNodeCol = 0
CodeGameScreenMrCashMachine.m_initNodeSymbolType = 0
CodeGameScreenMrCashMachine.m_m_initNodeIndex = nil
-- 构造函数
function CodeGameScreenMrCashMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_CashManBodyLongRunAct = false 
    self.m_initNodeCol = 0
    self.m_initNodeSymbolType = 0
    self.m_m_initNodeIndex = nil
	--init
    self:initGame()
    --假滚滚动存储类型
    self.m_mysterList = {}
    for i = 1, self.m_iReelColumnNum do
        self.m_mysterList[i] = -1
    end
end

function CodeGameScreenMrCashMachine:initGame()


    self.m_configData = gLobalResManager:getCSVLevelConfigData("MrCashConfig.csv", "LevelMrCashConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMrCashMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MrCash"  
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenMrCashMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "MrCashSounds/MrCash_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "MrCashSounds/MrCash_scatter_down1.mp3"
        else
            soundPath = "MrCashSounds/MrCash_scatter_down1.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenMrCashMachine:initUI()


    self.m_reelRunSound = "MrCashSounds/MrCashSounds_longRun.mp3"

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_JackPotBar = util_createView("CodeMrCashSrc.MrCashJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotBar)
    self.m_JackPotBar:initMachine(self)

    self.m_FsBar = util_createView("CodeMrCashSrc.MrCashFreespinBarView")
    self:findChild("cishu"):addChild(self.m_FsBar)
    self.m_FsBar:runCsbAction("idle",true)
    self.m_baseFreeSpinBar = self.m_FsBar
    self.m_baseFreeSpinBar:setVisible(false)

    self.m_CashManBody = util_spineCreate("MrCash_juese_1",true,true)
    self:findChild("manBody"):addChild(self.m_CashManBody)
    util_spinePlay(self.m_CashManBody,"idleframe",true) 
    self.m_CashManBody:setPositionY(-80)
    self.m_CashManBody:setPositionX(0)
    self.m_CashManBody:setVisible(false)
    
    self.m_CashManHand_Left = util_spineCreate("MrCash_juese_2_Left",true,true)
    self:findChild("manhandLeft"):addChild(self.m_CashManHand_Left)
    self.m_CashManHand_Left:setPositionY(-80)
    self.m_CashManHand_Left:setPositionX(0)
    self.m_CashManHand_Left:setVisible(false)

    self.m_CashManHand_Right = util_spineCreate("MrCash_juese_2_Right_1",true,true)
    self:findChild("manhandRight"):addChild(self.m_CashManHand_Right)
    self.m_CashManHand_Right:setPositionY(-80)
    self.m_CashManHand_Right:setPositionX(0)
    self.m_CashManHand_Right:setVisible(false)

    self.m_CashManHand_Mask = util_spineCreate("MrCash_juese_Mask",true,true)
    self:findChild("manMsk"):addChild(self.m_CashManHand_Mask)
    self.m_CashManHand_Mask:setPositionY(-80)
    self.m_CashManHand_Mask:setPositionX(200)
    self.m_CashManHand_Mask:setVisible(false)




    self.m_JpMiniReel =  self:createrMinIReel(  )
    self.m_JpMiniReel:setVisible(false)

    self.m_JpMarkView = util_createView("CodeMrCashSrc.BaseJPGame.MrCashJpGameMarkView")
    self:findChild("Node_JpGameMark"):addChild(self.m_JpMarkView)
    self.m_JpMarkView:setVisible(false)


    self.m_JpWinBar = util_createView("CodeMrCashSrc.BaseJPGame.MrCashJpGameWinBar")
    self:findChild("jackpotxz"):addChild(self.m_JpWinBar)
    -- self.m_JpWinBar:setPositionY(90)
    self.m_JpWinBar:setVisible(false)
    

    self:findChild("manhandLeft"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    self:findChild("manhandRight"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    self:findChild("manMsk"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 2)
    self:findChild("cishu"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 3)
    
    self:findChild("view_node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)
    self:findChild("WheelView"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)
    self:findChild("Node_ZheZhao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    self:findChild("Node_ZheZhao"):setVisible(false)
    self:findChild("Node_MiniReel"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self:findChild("Panel_JpGameMark"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    self:findChild("jackpotxz"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 11)

    


    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local isBonusGameCoins = params[6]

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
            soundIndex = 3
        end

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}

        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE  then
            print("freespin最后一次 无论是否大赢都播放赢钱音效")
        else

            if not isBonusGameCoins then
                if winRate >= self.m_HugeWinLimitRate then
                    return
                elseif winRate >= self.m_MegaWinLimitRate then
                    return
                elseif winRate >= self.m_BigWinLimitRate then
                    return
                end
            end
            
        end

        
        gLobalSoundManager:setBackgroundMusicVolume(0.4)

        local soundName = "MrCashSounds/music_MrCash_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenMrCashMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then

        mainScale = display.height / (self:getReelHeight() + uiH + uiBH)
        if display.height > DESIGN_SIZE.height then
            mainScale = DESIGN_SIZE.height / (self:getReelHeight() + uiH + uiBH)
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + 40 )
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

function CodeGameScreenMrCashMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_enterGame.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.3,self:getModuleName())
end

function CodeGameScreenMrCashMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    performWithDelay(self,function()
        if not tolua.isnull(self.m_CashManBody) then
            self.m_CashManBody:setVisible(true)
        end
        
        local features = self.m_runSpinResultData.p_features or {}
        if #features >= 2 then
            print("触发玩法啥也不干")
        else
            if self:getCurrSpinMode() == NORMAL_SPIN_MODE or  self:getCurrSpinMode() == AUTO_SPIN_MODE then

                self:CashManEnterLevel( )  
                
            else
                if not tolua.isnull(self.m_CashManBody) then
                    util_spinePlay(self.m_CashManBody,"idleframe",true) 
                end
            end 
        end
    end,0.3)
end


function CodeGameScreenMrCashMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    self:removeChangeReelDataHandler()
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMrCashMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType ==  self.SYMBOL_SCORE_9 then
        return "Socre_MrCash_10"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MrCash_11"
    elseif symbolType == self.SYMBOL_SCORE_MYSTER then
        return "Socre_MrCash_Mystery"   
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMrCashMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_9,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_MYSTER,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMrCashMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        self.m_gameBg:findChild("normal"):setVisible(false)
        self.m_gameBg:findChild("fs"):setVisible(true)
        self.m_gameBg:runCsbAction("freespin",true)
        self:findChild("lan_rell"):setVisible(false)
        
    end
    
end

function CodeGameScreenMrCashMachine:checkIsPlayReelDownSound(reelCol )
   
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerType = selfdata.triggerType or ""
    -- 触发特殊玩法后 不允许点击快停
    if triggerType == self.TriggerType_Wheel then -- 圆盘玩法
        return false
    end
    
    local isPlay =  CodeGameScreenMrCashMachine.super.checkIsPlayReelDownSound( self,reelCol )

    return isPlay

end

--
--单列滚动停止回调
--
function CodeGameScreenMrCashMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun =  BaseNewReelMachine.slotOneReelDown(self,reelCol) 
   
    if isTriggerLongRun then
        if self.m_CashManBodyLongRunAct == false then
            self:CashManStartLongRun( )
        end
        
    end
    

end


---------------------------------------------------------------------------
----------- FreeSpin相关

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenMrCashMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum
    if frameNum == 0 then
        if lineValue.vecValidMatrixSymPos then
            frameNum = #lineValue.vecValidMatrixSymPos
        end
    end

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode==nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end

            end
        end

        if slotNode ~= nil then--这里有空的没有管

            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenMrCashMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)

    -- 延迟回调播放 界面提示 bonus  freespin
    
    local waitTime = 75/30

    performWithDelay(self,function(  )
        self:resetMaskLayerNodes()
        callFun()
    end,waitTime)
    

end

-- 获得锁住的的scatter位置
function CodeGameScreenMrCashMachine:getLockScatterPos()
    local storeIcons = {}
    local fsExtraDat = self.m_runSpinResultData.p_fsExtraData or {}
    local positionTimes = fsExtraDat.positionTimes or {}
    for k, v in pairs(positionTimes) do
        local array = {}
        array[#array + 1] = tonumber(k)
        array[#array + 1] = tonumber(v)
        table.insert(storeIcons, array)
    end
    return storeIcons
end

function CodeGameScreenMrCashMachine:getInitFeatureViewData()
    local storeIcons = self:getLockScatterPos() -- self.m_runSpinResultData.p_storedIcons
    local respinNodeInfo = {}

    for i = 1, #storeIcons do
        local icon = storeIcons[i]
        local posArray = self:getRowAndColByPos(icon[1])

        local columnData = self.m_reelColDatas[posArray.iY]
        local height = columnData.p_showGridH

        --二维坐标
        local arrayPos = {posArray.iX, posArray.iY}
        --世界坐标
        local pos, reelHeight, reelWidth = self:getReelPos(posArray.iY)
        pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
        pos.y = pos.y + (posArray.iX - 0.5) * height  * self.m_machineRootScale

        local nodeInfo = {
            Pos = pos,
            ArrayPos = arrayPos,
            EndValue = icon[2]
        }

        respinNodeInfo[#respinNodeInfo + 1] = nodeInfo
    end
    return respinNodeInfo
end

function CodeGameScreenMrCashMachine:showFreeSpinStart(num,func)

    gLobalSoundManager:playSound("MrCashSounds/music_MrCash_showFsStartView.mp3")
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(false) 
    end
    
    local currFunc = function(  )
        if self.m_touchSpinLayer then
            self.m_touchSpinLayer:setVisible(true)
        end
        
        self:showNodeReelDarkBG( true  )

        if func then
            func()
        end

    end

    local ownerlist={}
    ownerlist["m_lb_num"]=num
     
    local view =  self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,currFunc,nil,nil,true)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)

    view.m_btnTouchSound = "MrCashSounds/music_MrCash_BrnClick.mp3" 

    return view
end

-- FreeSpinstart
function CodeGameScreenMrCashMachine:showFreeSpinView(effectData)

    

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

            util_playFadeOutAction(self.m_FeatureView,0.3)
            
            self:showFreeSpinStart( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self.m_FeatureView:removeFromParent()
                effectData.p_isPlay = true
                self:playGameEffect()
                self:resetMusicBg()

            end,true)
        else

            util_playFadeOutAction(self.m_FeatureView,0.3)

            self.m_FsBar:runCsbAction("buling2")
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self.m_FsBar:runCsbAction("buling1")
                    self.m_FeatureView:removeFromParent()

                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
            end)
        end
    end

    local showFsTimesBar = function( )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

            local startValue = 0
            local endValue = self.m_runSpinResultData.p_freeSpinsTotalCount 
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
               local freeSpinNewCount =  self.m_runSpinResultData.p_freeSpinNewCount or 0
               startValue = self.m_runSpinResultData.p_freeSpinsLeftCount  - freeSpinNewCount
               endValue = self.m_runSpinResultData.p_freeSpinsLeftCount
            end

            self:fsBarJumpNumStart( )

            self:PretreatmentFreeSpinTimesCollect( function(  )
                self:fsBarJumpNumOver()
                performWithDelay(self,function(  )
                    showFSView()
                end,0.5)
            end )

           -- self.m_FsBar:playFsNumAnim(startValue,endValue,function(  )
                -- self:fsBarJumpNumOver()
                -- performWithDelay(self,function(  )
                --     showFSView()
                -- end,0.5)
                
            --end)

        else
           
            self.m_FsBar:setVisible(true)
            self.m_FsBar:updateFreespinCount( "" )
            self.m_FsBar:runCsbAction( "buling1" ,false,function( )

                local startValue = 0
                local endValue = self.m_runSpinResultData.p_freeSpinsTotalCount  

                self:fsBarJumpNumStart( )

                self:PretreatmentFreeSpinTimesCollect( function(  )
                    self:fsBarJumpNumOver()
                    performWithDelay(self,function(  )
                        showFSView()
                    end,0.5)
                end )

                --self.m_FsBar:playFsNumAnim(startValue,endValue,function(  )
                    
                    -- self:fsBarJumpNumOver()
                    -- performWithDelay(self,function(  )
                    --     showFSView()
                    -- end,0.5)
    
                --end)
    
            end)

        end
       
        

    end

    local function showFeatureView()

        self.m_FeatureView = util_createView("CodeMrCashSrc.FreeSpinFeature.MrCashFeatureView")
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local SignalTypeArray = {1, 2 , 3 , 5 , 7 , 10}
            self.m_FeatureView:setSignalTypeArray(SignalTypeArray)
        end
        local featureInitData = self:getInitFeatureViewData()
        self:findChild("reel"):addChild(self.m_FeatureView, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) 

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_FeatureView.getRotateBackScaleFlag = function(  ) return false end
        end


        self.m_FeatureView:initFeatureUI(featureInitData, self)
        self.m_FeatureView:setOverCallBackFun(
            function()
                performWithDelay(
                    self,
                    function()

                        showFsTimesBar()

                        
                    end,
                    0.1
                )
            end
        )
    end

    local showExplosionFlash = function(  )

        self:CashManLieOnTheTable( function(  )
            
            self:CashManGuZhangIdle( )

            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_BianJinKuang.mp3")
    
            local maxCol = self:getMaxContinuityBonusCol( )
            for iCol = 1, self.m_iReelColumnNum  do
                for iRow = 1, self.m_iReelRowNum do
                    if iCol <= maxCol then
                        local tarsp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    
                        if tarsp and tarsp.p_symbolType and tarsp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            local index = self:getPosReelIdx(iRow, iCol)
                            local pos = cc.p(util_getOneGameReelsTarSpPos(self,index))
                            local actNode =  util_createAnimation("Socre_MrCash_zhuanchang.csb")
                            actNode:setPosition(pos) 
                            self:findChild("reel"):addChild(actNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER+ 10)
                            actNode:runCsbAction("actionframe",false,function(  )
                            end)
                        end
                    end
                    
                    
                end
        
            end



            self:showNodeReelDarkBG( false  )

            performWithDelay(self,function(  )
                showFeatureView() 
            end,6/30)

        end )


    end

    local OpenCurtainAct = function( )


        gLobalSoundManager:playSound("MrCashSounds/music_MrCash_GuoChang.mp3")

        self:CashManTheCurtainAct( function(  )

            self.m_gameBg:findChild("fs"):setVisible(true)
            self.m_gameBg:runCsbAction("freespin",true)
            self:findChild("lan_rell"):setVisible(false)
  
        end )

        self:OpenTheCurtain( function(  )

            self.m_gameBg:findChild("normal"):setVisible(false)

            showExplosionFlash()
        end )

    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_FsBar:setVisible(true)
        self.m_FsBar:updateFreespinCount( "" )
        self.m_FsBar:runCsbAction( "idle" ,false,function( )
            local freeSpinNewCount =  self.m_runSpinResultData.p_freeSpinNewCount or 0
            local startValue = globalData.slotRunData.freeSpinCount - freeSpinNewCount
            self.m_FsBar:updateFreespinCount( startValue )
        end)

        showExplosionFlash()
    else

        -- 如果不是freespin状态那就播放拉帘子动画
        OpenCurtainAct()
        
        
    end

end


function CodeGameScreenMrCashMachine:showFreeSpinOver(coins,num,func)

    gLobalSoundManager:playSound("MrCashSounds/music_MrCash_showFsStartView.mp3")

    self:showNodeReelDarkBG( false  )

    local currFunc = function(  )

        self:showNodeReelDarkBG( true  )
        self:findChild("lan_rell"):setVisible(true)

        if func then
            func()
        end

    end

    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,currFunc,nil,nil,true)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenMrCashMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin( globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)

    self:clearCurMusicBg()

    gLobalSoundManager:playSound("MrCashSounds/music_MrCash_End_fs.mp3")

    performWithDelay(self,function(  )
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearFrames_Fun()
        -- 重置连线信息
        -- self:resetMaskLayerNodes()
        self:showFreeSpinOverView()
    
    end,3)
    
end

function CodeGameScreenMrCashMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("MrCashSounds/music_MrCash_over_fs.mp3")

   self.m_baseFreeSpinBar:setVisible(false)

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_GuoChang.mp3")

            self:CashManTheCurtainAct( function(  )

                self.m_gameBg:findChild("normal"):setVisible(true)

            end )

            self:CloseTheCurtain( function(  )

                self:triggerFreeSpinOverCallFun()

                self.m_gameBg:findChild("fs"):setVisible(false)
                self.m_gameBg:runCsbAction("normal")

            end )

        
    end)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMrCashMachine:MachineRule_SpinBtnCall()

    self.m_CashManBodyLongRunAct = false

    self.m_addSounds = {}

    self:setMaxMusicBGVolume( )
   
    if self.m_CashManBody and self.m_CashManBody.m_BigWinIdle  then
        util_spinePlay(self.m_CashManBody,"idleframe5",false)
        util_spineEndCallFunc(self.m_CashManBody,"idleframe5",function ( )
            util_spinePlay(self.m_CashManBody,"idleframe",true) 
        end)
        
        self.m_CashManBody.m_BigWinIdle = nil
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:removeChangeReelDataHandler()
    self:randomMystery()
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMrCashMachine:addSelfEffect()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerType = selfdata.triggerType or ""
    -- 触发特殊玩法后 不允许点击快停
    if triggerType == self.TriggerType_Wheel then -- 圆盘玩法

        -- 加的等待事件
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.DEALT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DEALT_EFFECT -- 动画类型


    end



  
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local changeSignal = selfdata.changeSignal
    local mysteryType = selfdata.mysteryType 

    if changeSignal then
        -- 开门图标变成其他信号
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.OPEN_DOOR_TURN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.OPEN_DOOR_TURN_EFFECT -- 动画类型

    end
    
    if mysteryType and mysteryType == self.MysteryType_Drawing then
        -- 开门图标移动使其他图标变成开门图标
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.OPEN_DOOR_MOVE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.OPEN_DOOR_MOVE_EFFECT -- 动画类型
    end
    

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMrCashMachine:MachineRule_playSelfEffect(effectData)



    if effectData.p_selfEffectType == self.OPEN_DOOR_TURN_EFFECT then

        self:playOpenDoorTurn(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end )
        

    elseif effectData.p_selfEffectType == self.OPEN_DOOR_MOVE_EFFECT then
        self:playOpenDoorMove(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end )

    elseif effectData.p_selfEffectType == self.DEALT_EFFECT then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local triggerType = selfdata.triggerType or ""
        -- 触发特殊玩法后 不允许点击快停
       if triggerType == self.TriggerType_Wheel then -- 圆盘玩法

            if  self.m_WheelView == nil then
                effectData.p_isPlay = true
                self:playGameEffect()
            end


        end

        
        

    end

    
	return true
end

function CodeGameScreenMrCashMachine:changeEffectToPlayed(selfEffectType )
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

function CodeGameScreenMrCashMachine:dealSmallReelsSpinStates( )

end

function CodeGameScreenMrCashMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerType = selfdata.triggerType or ""
    -- 触发特殊玩法后 不允许点击快停
    if triggerType == self.TriggerType_Wheel then -- 圆盘玩法

        self:triggerSpecialBonus( function(  )
            
        end)

        self:showNodeReelDarkBG( false  )
        self:netBackReelsStop()

        self:showWheelView( function(  )
    
            self:showNodeReelDarkBG( true)

            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local jackpot = selfdata.jackpot 
            if jackpot then

                -- 如果有jackpot轮盘数据，进入jackpot玩法轮子
                self:playJackPotCollectAct( function(  )

                    self:CashManReturnIdle( function(  )

                        -- 玩完玩法后完成等待事件
                        self:changeEffectToPlayed(self.DEALT_EFFECT )
      
                      end , true)

                end )
        
            else
                self:CashManReturnIdle( function(  )

                  -- 玩完玩法后完成等待事件
                  self:changeEffectToPlayed(self.DEALT_EFFECT )

                end , true)
                  
            end
            

        end )

    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Stop,true})  
        self:netBackReelsStop()
    end
   

    
end

function CodeGameScreenMrCashMachine:netBackReelsStop()

    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()  -- end

end


function CodeGameScreenMrCashMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    gameBg:setScale(0.9)
    gameBg:setPositionY(gameBg:getPositionY() - 100)

    self.m_gameBg = gameBg
    gameBg:findChild("fs"):setVisible(false)
    gameBg:findChild("normal"):setVisible(true)

    self.m_normalBgSpine = util_spineCreate("MrCash_bj",true,true)
    gameBg:findChild("normal"):addChild(self.m_normalBgSpine)
    util_spinePlay(self.m_normalBgSpine,"idleframe")
    self.m_normalBgSpine:setPositionX(200)
    self.m_normalBgSpine:setPositionY(170)
end

---
--设置bonus scatter 层级
function CodeGameScreenMrCashMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
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

--------------
----------
-------
----
-- 自定义动画

function CodeGameScreenMrCashMachine:createOneSymbolActNode( symbolType,  rowIndex , cloumnIndex ,pos,currParent )
    
    local targSp = util_createAnimation("Socre_MrCash_Mystery.csb") 

    currParent:addChild(targSp,REEL_SYMBOL_ORDER.REEL_ORDER_4)
    targSp:setPosition(cc.p(pos))

    return targSp

end

-- 开门图标变成其他信号
function CodeGameScreenMrCashMachine:playOpenDoorTurn( func )
    

    

    -- 找到所有开门图标
    local OpenDoorSymbolList = {}
    for iCol = 1, self.m_iReelColumnNum  do
       
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_MYSTER then
                table.insert(OpenDoorSymbolList,slotNode)
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


    gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_openDoor.mp3")
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local symbolType = selfdata.changeSignal

    for i=1,#OpenDoorSymbolList do
        local symbolNode = OpenDoorSymbolList[i]
        local currParent = symbolNode:getParent()
        local pos = cc.p(symbolNode:getPosition())
        local actNode = self:createOneSymbolActNode(  symbolType,  symbolNode.p_rowIndex , symbolNode.p_cloumnIndex ,pos,currParent  )

        if self:getSymbolCCBNameByType(self,symbolType ) == symbolNode.m_ccbName then 
            symbolNode.m_ccbName = "" 
        end
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType ), symbolType)
        if symbolNode.p_symbolImage ~= nil then
            symbolNode.p_symbolImage:setVisible(false)
        end

        if i == 1 then
            actNode:runCsbAction("actionframe",false,function(  )
                actNode:removeFromParent()
                if func then
                    func()
                end

            end)
        else
            actNode:runCsbAction("actionframe",false,function(  )
                actNode:removeFromParent()
            end)
        end
        
    end


    
end

-- 开门图标移动使其他图标变成开门图标
function CodeGameScreenMrCashMachine:OpenDoorMoveToAction(node,time,pos,callback,type)
    local actionList={}
    if type == "easyInOut" then
        actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveTo:create(time,pos),1)
    else
        actionList[#actionList+1]=cc.MoveTo:create(time,pos);
    end

    actionList[#actionList+1]=cc.CallFunc:create(function(  )
       if callback then
            callback()
       end
    end)
    local seq=cc.Sequence:create(actionList)
    node:runAction(seq)
end

function CodeGameScreenMrCashMachine:playOpenDoorMove( func )

    

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local symbolType = selfdata.changeSignal
    local column = selfdata.column + 1

    local beginRow = nil
    local endRow = self.m_iReelRowNum 
    local currParent = nil
    for iRow = self.m_iReelRowNum, 1 , -1 do
        local slotNode = self:getFixSymbol(column, iRow, SYMBOL_NODE_TAG)
        if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_MYSTER then
            beginRow = iRow 
            currParent = slotNode:getParent()
            break
        end
    end


    if beginRow == nil then

        if func then
            func()
        end

        return 
    end

    self:CashManLieOnTheTable( function(  )
        local index = self:getPosReelIdx(beginRow, column)
        local movePos = cc.p(util_getOneGameReelsTarSpPos(self,index))

        

        self:CashManPushOpenDoorSymbolUp( function(  )
        
            -- 因为只会从下网上移动创建需要补齐的小块
            local time = 0.5
            for iRow = 1, self.m_iReelRowNum do
                local pos = cc.p(util_getPosByColAndRow(self,column, iRow - (self.m_iReelRowNum - beginRow )))
                local actNode = self:createOneSymbolActNode( symbolType,  iRow , column ,pos ,currParent )  
    
                local actPos = cc.p(util_getPosByColAndRow(self,column, iRow))
                if iRow == 1 then
                    self:OpenDoorMoveToAction(actNode,time,actPos,function(  )
                        actNode:removeFromParent()
                        for iRowNum = 1, self.m_iReelRowNum do
                            local slotNode = self:getFixSymbol(column, iRowNum, SYMBOL_NODE_TAG)
                            if slotNode and slotNode.p_symbolType ~= self.SYMBOL_SCORE_MYSTER then
    
                                if self:getSymbolCCBNameByType(self,self.SYMBOL_SCORE_MYSTER ) == slotNode.m_ccbName then 
                                    slotNode.m_ccbName = "" 
                                end
                                slotNode:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_SCORE_MYSTER ), self.SYMBOL_SCORE_MYSTER)
                                if slotNode.p_symbolImage ~= nil then
                                    slotNode.p_symbolImage:setVisible(false)
                                end
    
                            end
                        end
    

                    end)
                else
                    self:OpenDoorMoveToAction(actNode,time,actPos,function(  )
                        actNode:removeFromParent()
                    
                    end)
                end
                
            end
    
        end ,column,function(  )

            
            self:CashManReturnIdle( )

            if func then
                func()
            end

        end,movePos)
    end )

    

    
 
end

function CodeGameScreenMrCashMachine:getMachineReelStr( machineReel)
   
    local endLabData = {"","",""} 

    local coinsList = {}
    local isInster = false
    for i=1,#machineReel do
        local num =  machineReel[i]
        if isInster == false and num ~= "0" then
            isInster = true
        end

        if isInster then
            table.insert(coinsList,num)
        end
    end

    if #coinsList == 1 then
        endLabData = {"","",coinsList[1]} 
    elseif #coinsList == 2 then
        endLabData = {"",coinsList[1],coinsList[2]} 
    elseif #coinsList == 3 then
        endLabData = {coinsList[1],coinsList[2],coinsList[3]} 
    elseif #coinsList == 4 then
        endLabData = {coinsList[1],coinsList[2] .. coinsList[3],coinsList[4]} 
    elseif #coinsList == 5 then
        endLabData = {coinsList[1] .. coinsList[2],coinsList[3] .. coinsList[4],coinsList[5]} 
    elseif #coinsList == 6 then
        endLabData = {coinsList[1] .. coinsList[2],coinsList[3] .. coinsList[4],coinsList[5]..coinsList[6]} 
    end


    return endLabData
end


-- 随机出现大圆盘玩法
function CodeGameScreenMrCashMachine:showWheelView( func )
    
    self:resetMusicBg(nil,"MrCashSounds/music_MrCash_WheelGameBG.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local wheel = selfdata.wheel or {"jackpot","1","2","3","4","5","6","7"}
    local select = selfdata.select  or 1
    local wheelCoins = selfdata.wheelCoins or 0

    local jackpot = selfdata.jackpot
    

    local data = {}
    data.wheel = wheel
    data.select = select + 1
    data.parent = self

    self.m_WheelView = util_createView("CodeMrCashSrc.BaseWheel.MrCashWheelView",data)
    self:findChild("wheel_Clicp"):addChild(self.m_WheelView )

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_WheelView.getRotateBackScaleFlag = function(  ) return false end
    end


    self.m_WheelView:initCallBack(function(  )
        
        if jackpot then
            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_JackPotGame_Trigger.mp3")
        else
            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_Wheel_XuanZhong.mp3")
        end

        self.m_WheelView:runCsbAction("zhongjiang",true)

        performWithDelay(self,function(  )
            
            -- 本次没有赢钱线的时候
            local winCoin = self.m_serverWinCoins
            local winLines = self.m_runSpinResultData.p_winLines or {}
    
    
            local wheelEndCallFunc = function(  )
                gLobalSoundManager:playSound("MrCashSounds/music_MrCash_Wheel_ShouHui.mp3")
                self:findChild("Panel_Wheel"):setClippingEnabled(true)

                self.m_WheelView:runCsbAction("over",false,function(  )
    
                    self.m_WheelView:removeFromParent()
                    self.m_WheelView = nil
                      
                    self:resetMusicBg(true)
                    
                    if func then
                        func()
                    end
    
                    
                end)
            end

            local wheelJpEndCallFunc = function(  )
 
                self:findChild("Panel_Wheel"):setClippingEnabled(true)

                self.m_WheelView:removeFromParent()
                self.m_WheelView = nil
                
                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                local jackpot = selfdata.jackpot 
                if jackpot then

                    self:resetMusicBg(nil,"MrCashSounds/music_MrCash_JpGameBG.mp3")
            
                else
                    self:resetMusicBg(true)
                end
                
                
                if func then
                    func()
                end
    
                    

            end
    
            local waitTime = 0
            -- 没有中jackpot玩法才执行这块逻辑
            if not jackpot then
                waitTime = self:getWinLabJumpTime( winCoin )
                self:updateLittleCoins( wheelCoins )
            end
    
            
    
            if waitTime > 0 then
    
                performWithDelay(self,function(  )
                    wheelEndCallFunc()
                end,waitTime)
                
            else

                -- util_playScaleToAction(self.m_WheelView,0.3,0.9)
                self.m_WheelView:runCsbAction("clicked")
                
                

                gLobalSoundManager:playSound("MrCashSounds/music_MrCash_JackPotGame_TwoView_Tip.mp3")
                local showJpTip = util_createView("CodeMrCashSrc.MrCashShowWheelTip_TwoView") 
                self:findChild("WheelView"):addChild(showJpTip,1)

                if globalData.slotRunData.machineData.p_portraitFlag then
                    showJpTip.getRotateBackScaleFlag = function(  ) return false end
                end


                showJpTip:setPositionY(-28)
                showJpTip:setClickCallFunc(function(  )

                    wheelJpEndCallFunc() 

                end , function(  )
                    self.m_WheelView:runCsbAction("over2")
                    gLobalSoundManager:playSound("MrCashSounds/music_MrCash_Wheel_ShouHui.mp3")
                end)
                showJpTip:findChild("click"):setVisible(false)
                showJpTip:runCsbAction("start",false,function(  )

                    showJpTip:runCsbAction("idle",true)
                    showJpTip:findChild("click"):setVisible(true)

                end)

                -- 如果四秒没点自动继续
                performWithDelay(showJpTip.m_actNode,function(  )
                    
                    showJpTip:findChild("click"):setVisible(false)

                    
                    if showJpTip.m_callFunc then
                        showJpTip.m_callFunc()
                    end

                end,4)
                
            end
                
        end,0)
   
    end)
    
   
    local column = 3
    local beginRow = 1 
    local index = self:getPosReelIdx(beginRow, column)
    local movePos = cc.p(util_getOneGameReelsTarSpPos(self,index))

    local oldPos =  cc.p(self:findChild("WheelView"):getPosition())
    local newPos = cc.p(oldPos.x,oldPos.y)
    self:findChild("WheelView"):setPosition(newPos)

    self:findChild("Panel_Wheel"):setClippingEnabled(true)


                
    self:createWheelTipVIew( function(  )
                
        self:CashManShowWheelUp( nil ,column,function(  )

            self:findChild("manhandLeft"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
            util_spinePlay(self.m_CashManBody,"idleframe2",true)
            util_spinePlay(self.m_CashManHand_Left,"idleframe2",true)
            util_spinePlay(self.m_CashManHand_Right,"idleframe2",true)
    
            self.m_WheelView:changeBtnEnabled( true )
    
        end,movePos,function(  )
    
            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_Wheel_tanChu.mp3")
    
            self:findChild("manhandLeft"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 11)
    
            self.m_WheelView:runCsbAction("start",false,function(  )

                performWithDelay(self.m_WheelView.m_actNode,function(  )

                    if self.m_WheelView.m_bIsTouch == false then
                        
                        return
                    end
                    
                    self.m_WheelView.m_bIsTouch = false
                    
                    self.m_WheelView:WheelSpinFunc( )
            
                end,4)

                self:findChild("Panel_Wheel"):setClippingEnabled(false)
                self.m_WheelView:runCsbAction("idle",true)

                

            end)
    
            
        end)    
                
    end )

    

end

function CodeGameScreenMrCashMachine:getWinLabJumpTime( winCoin )
    
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 4
    end

    return showTime
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenMrCashMachine:showDialog(ccbName,ownerlist,func,isAuto,index,isAddRoot)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    if isAddRoot then
        self:findChild("view_node"):addChild(view)
        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function(  ) return false end
        end

    else
        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalViewManager:showUI(view)
    end

    return view
end

function CodeGameScreenMrCashMachine:showNodeReelDarkBG( isHide , func )
    
    local nodeDarkBG = self:findChild("Node_ZheZhao")
    if nodeDarkBG then

        if isHide then
            nodeDarkBG:setVisible(true)
            util_playFadeOutAction(nodeDarkBG,0.3,function(  )
                nodeDarkBG:setVisible(false)
                if func then
                    func()
                end
            end)
        else
            nodeDarkBG:setVisible(false)
            util_playFadeOutAction(nodeDarkBG,0.01,function(  )
                nodeDarkBG:setVisible(true)
                util_playFadeInAction(nodeDarkBG,0.29,function(  )
                    
                    if func then
                        func()
                    end
                end)
            end)
        end

    else
        if func then
            func()
        end
        
    end
    
    
end
-- ------ ------ ------ ------ ------ ------ ------ ------ ------ ----

function CodeGameScreenMrCashMachine:specialSymbolActionTreatment( node )
    if node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        node:runAnim("buling",false,function(  )
            -- node:runAnim("idleframe",true)
        end)
    end
end

-- ---- 快滚相关 修改
function CodeGameScreenMrCashMachine:getMaxContinuityBonusCol( )
    local maxColIndex = 0

    local isContinuity = true

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0

        for iRow = 1, self.m_iReelRowNum do

            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]


            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
                bonusNum = bonusNum + 1
                if isContinuity then
                    maxColIndex = iCol
                end
            end


        end
        if bonusNum == 0 then
            isContinuity = false
            break
        end
    end

    return maxColIndex
end
--改变下落音效
function CodeGameScreenMrCashMachine:changeReelDownAnima(parentData)
    if parentData.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
        if not self.m_addSounds then
            self.m_addSounds = {}
        end
        if self:getMaxContinuityBonusCol() >= parentData.cloumnIndex  then
            local soundIndex = 1
            if parentData.cloumnIndex == 1 then
                soundIndex = 1
            elseif parentData.cloumnIndex > 1 and parentData.cloumnIndex < self:getMaxContinuityBonusCol() then
                soundIndex = 2
            else
                soundIndex = 3
            end
            parentData.reelDownAnima = "buling"
            if not self.m_addSounds[parentData.cloumnIndex] then
                self.m_addSounds[parentData.cloumnIndex] = true
                parentData.reelDownAnimaSound = self.m_scatterBulingSoundArry[soundIndex] 
            end
        end
        parentData.order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + (( self.m_iReelRowNum - parentData.rowIndex )*10 + parentData.cloumnIndex)
    end
end

-- --设置滚动状态
local runStatus =
{
    DUANG = 1,
    NORUN = 2,
}

function CodeGameScreenMrCashMachine:getCol_1_ScatterNum( )

    local iCol_1_ScatterNum = 0

 
    for iCol = 1, self.m_iReelColumnNum do


        for iRow = 1, self.m_iReelRowNum do

            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]


            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
                
                if iCol == 1  then
                    iCol_1_ScatterNum = iCol_1_ScatterNum  + 1
                end
            end


        end
     
    end

    if iCol_1_ScatterNum == 0 then
        iCol_1_ScatterNum = 2
    end

    return iCol_1_ScatterNum + 1
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenMrCashMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum >= self:getCol_1_ScatterNum( ) then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= self:getCol_1_ScatterNum( )  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[1] then
        if nodeNum >= self:getCol_1_ScatterNum( ) then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum >= self:getCol_1_ScatterNum( ) then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end


--设置bonus scatter 信息
function CodeGameScreenMrCashMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column] -- 快滚信息
    local runLen = reelRunData:getReelRunLen() -- 本列滚动长度
    local allSpecicalSymbolNum = specialSymbolNum -- bonus或者scatter的数量（上一轮，判断后得到的）
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType) -- 获得是否进行长滚逻辑和播放长滚动画（true为进行或播放）

    local soundType = runStatus.DUANG
    local nextReelLong = false

    -- scatter 列数限制 self.m_ScatterShowCol 为空则默认为 五列全参与长滚 在：getRunStatus判断
    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then

    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    -- for 这里的代码块只是为了添加scatter或者bonus快滚停止时 的音效和动画
    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        if targetSymbolType == symbolType  then

            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then

                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效

                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end

    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--设置长滚信息
function CodeGameScreenMrCashMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0

    local addLens = false

    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        if bRunLong == true then --如果上一列长滚
            longRunIndex = longRunIndex + 1 -- 长滚统计加1

            local runLen = self:getLongRunLen(col, longRunIndex) -- 获得本列的长滚动长度
            local preRunLen = reelRunData:getReelRunLen() -- 获得本列普通滚动长度
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen) -- 设置本列滚动长度为快滚长度

        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 10)
                self:setLastReelSymbolList()
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        -- bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
        local maxCol =  self:getMaxContinuityBonusCol()
        if  col > maxCol then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
        elseif maxCol == col  then
            if bRunLong then
                addLens = true
            end
        end

    end 
end

-------------------
---------------
-------------
-- jackpot game

-- 创建小轮子 
function CodeGameScreenMrCashMachine:createrMinIReel(  )
    
    local className = "CodeMrCashSrc.BaseJPGame.MrCashMiniMachine"

    local reelData= {}
    reelData.parent = self

    local miniReel = util_createView(className,reelData)
    self:findChild("Node_MiniReel"):addChild(miniReel) 

    return miniReel
end


function CodeGameScreenMrCashMachine:showJackpotWinView(index,coins,func)

    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(false)
    end
    
    self:showNodeReelDarkBG( false  )

    local currFunc = function(  )
        if self.m_touchSpinLayer then
            self.m_touchSpinLayer:setVisible(true)
        end
        
        self:showNodeReelDarkBG( true  )

        if func then
            func()
        end

    end


    
    local jackPotWinView = util_createView("CodeMrCashSrc.BaseJPGame.MrCashJackPotWinView")
    self:findChild("view_node"):addChild(jackPotWinView)
    jackPotWinView:initViewData(index,coins,self,currFunc)

    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end


end


function CodeGameScreenMrCashMachine:runFlyWildAct(startNode,endNode,csbName,func)

    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self:findChild("reel"):addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 501)

    local startPos = cc.p(util_getConvertNodePos(startNode,flyNode))
    startPos = cc.p(startPos.x  ,startPos.y )
    flyNode:setPosition(cc.p(startPos))

    
    for i=1,5 do
        local sprNode = flyNode:findChild("Node_"..i)
        if startNode.p_cloumnIndex == i then
            sprNode:setVisible(true)
        else
            sprNode:setVisible(false)
        end
    end

    performWithDelay(self,function()

        self.m_JpWinBar.m_WinBarShouJi:setVisible(true)
        self.m_JpWinBar.m_WinBarShouJi:runCsbAction("actionframe",false,function()
            self.m_JpWinBar.m_WinBarShouJi:setVisible(false)
        end)

        -- performWithDelay(self,function()
            if func then
                func()
            end
        -- end,6/30)
        

    end,9/30)

    flyNode:runCsbAction("shouji",false,function(  )

            flyNode:stopAllActions()
            flyNode:removeFromParent()
    end)

    return flyNode

end

function CodeGameScreenMrCashMachine:sortOutJackpPotCollectData( func )
    
    self.m_JPReelJpType = - 1
    self.m_JPReelIndex = 1
    self.m_JPReelCollectNum = 0
    self.m_JPReelActCallFunc = function(  )
        if func then
            func()
        end
    end
    self.m_JPReelNode = {}

    for iCol = 1, self.m_iReelColumnNum  do

        local slotNode = self.m_JpMiniReel:getFixSymbol(iCol, 2, SYMBOL_NODE_TAG)
        if slotNode and slotNode.p_symbolType  then

            if slotNode.p_symbolType >= self.m_JpMiniReel.SYMBOL_JP_108 then

            else

                table.insert(self.m_JPReelNode,slotNode)

            end
        end
    end

    for iCol = 1, self.m_iReelColumnNum  do

        local slotNode = self.m_JpMiniReel:getFixSymbol(iCol, 2, SYMBOL_NODE_TAG)
        if slotNode and slotNode.p_symbolType  then

            if slotNode.p_symbolType >= self.m_JpMiniReel.SYMBOL_JP_108 then

                table.insert(self.m_JPReelNode,slotNode)

            else

            end
        end
    end

end
-- 开始收集
function CodeGameScreenMrCashMachine:beginJackpPotCollectAct(  )
    
    

   if self.m_JPReelIndex > #self.m_JPReelNode then
       
        self.m_JpWinBar.m_WinBarLight:setVisible(false)
        
        if self.m_JPReelActCallFunc then
            self.m_JPReelActCallFunc()
        end
        
        return 
   end

   local actNode = self.m_JPReelNode[self.m_JPReelIndex]

   self.m_JPReelCollectNum = self.m_JPReelCollectNum + (actNode.p_symbolType - 100)

   local aniName = "actionframe1"
   local aniName_2 = "actionframe"
   if actNode.p_symbolType >= self.m_JpMiniReel.SYMBOL_JP_108 then
        
        gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCash_JP_OpenDoor.mp3")

        local csbAct = util_createAnimation("Socre_MrCash_jackpot_Num_8_2.csb")
        actNode:getParent():addChild(csbAct,actNode:getLocalZOrder() + 1)
        csbAct:setPosition(cc.p(actNode:getPosition()))

        local spineMan = util_spineCreate("Socre_MrCash_Jackpot",true,true)
        csbAct:findChild("juese"):addChild(spineMan)

        local csbActLab = util_createAnimation("Socre_MrCash_jackpot_Num_8_1.csb")
        csbAct:findChild("Node_3"):addChild(csbActLab)


        local lab_act =  csbActLab:findChild("m_lb_num")
        if lab_act then
            lab_act:setString(actNode.p_symbolType - 100) 
        end

        local lab =  actNode:getCcbProperty("m_lb_num")
        if lab then
            lab:setString(actNode.p_symbolType - 100) 
        end
        
        actNode:runAnim("idle1")

        util_spinePlay(spineMan,"actionframe")

        csbAct:runCsbAction(aniName_2,false,function(  )

            local csbAct_1 = csbAct
            csbAct_1:runCsbAction(aniName,false,function(  )
                csbAct_1:removeFromParent()
            end)


            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_MrCash_JpGame_BianShuzi.mp3")
            self.m_JpWinBar.m_WinBarLight:setVisible(false)

            local startNode = actNode
            local endNode = self.m_JpWinBar:findChild("guangmang")
            local csbName = "Socre_MrCash_jackpot_shouji"
            local func = function(  )

                self.m_JpWinBar:runCsbAction("shouji")

                self:playJpBarAct( )
                
                self.m_JpWinBar:findChild("m_lb_num"):setString(self.m_JPReelCollectNum)
                
                performWithDelay(self,function()
                    self:beginJackpPotCollectAct(  )
                end,15/30)

                

            end
            self:runFlyWildAct(startNode,endNode,csbName,func)
        end)
        
   else
        

        actNode:runAnim(aniName,false,function(  )
        end)

        gLobalSoundManager:playSound("MrCashSounds/music_MrCash_MrCash_JpGame_Shuzi.mp3")

        self.m_JpWinBar.m_WinBarLight:setVisible(false)

        local startNode = actNode
        local endNode = self.m_JpWinBar:findChild("guangmang")
        local csbName = "Socre_MrCash_jackpot_shouji"
        local func = function(  )


            self.m_JpWinBar:runCsbAction("shouji")

            self:playJpBarAct( )

            self.m_JpWinBar:findChild("m_lb_num"):setString(self.m_JPReelCollectNum)
                
            performWithDelay(self,function()
                self:beginJackpPotCollectAct(  )
            end,15/30)

        end

        self:runFlyWildAct(startNode,endNode,csbName,func)    
        
   end


   self.m_JPReelIndex = self.m_JPReelIndex + 1

  

end

function CodeGameScreenMrCashMachine:playJpBarAct( )
    
     -- 收集JackPotbar动画
     local jackpotType = nil
     local CollectNum = self.m_JPReelCollectNum
     local WinList = {37,46,50}
     if CollectNum < WinList[1]  then  -- < 36
         jackpotType = 4
     elseif CollectNum >= WinList[1] and CollectNum < WinList[2] then -- 37 -45
         jackpotType = 3
     elseif CollectNum >= WinList[2] and CollectNum < WinList[3] then -- 46 - 49
         jackpotType = 2
     elseif CollectNum >= WinList[3] then -- >= 50
         jackpotType = 1
     end
     
    if self.m_JPReelJpType ~= jackpotType then
            self.m_JPReelJpType = jackpotType

            gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCash_JP_LevelUp_" .. (jackpotType + 1) .. ".mp3")

            self.m_JpWinBar:findChild("grand"):setVisible(false)
            self.m_JpWinBar:findChild("major"):setVisible(false)
            self.m_JpWinBar:findChild("minor"):setVisible(false)
            self.m_JpWinBar:findChild("mini"):setVisible(false)
            if CollectNum < WinList[1]  then  -- < 36
                -- mini
                self.m_JpWinBar:findChild("mini"):setVisible(true)
            elseif CollectNum >= WinList[1] and CollectNum < WinList[2] then -- 37 -45
                --minior    
                self.m_JpWinBar:findChild("minor"):setVisible(true)
            elseif CollectNum >= WinList[2] and CollectNum < WinList[3] then -- 46 - 49
                -- major
                self.m_JpWinBar:findChild("major"):setVisible(true)
            elseif CollectNum >= WinList[3] then -- >= 50
                -- Grand
                self.m_JpWinBar:findChild("grand"):setVisible(true)
            end

            self.m_JpWinBar:runCsbAction("showJpWin")

    else

        gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCash_JP_LevelUp_" .. 1 .. ".mp3")

    end


end

function CodeGameScreenMrCashMachine:hideAllSymbolNode( )
    
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do

            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                slotNode:setVisible(false)
            end
        end

    end

end

function CodeGameScreenMrCashMachine:showAllSymbolNode( )
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do

            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                slotNode:setVisible(true)
            end
        end

    end
end

function CodeGameScreenMrCashMachine:copyAndCreateMiniReelNetData( )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotResult = selfdata.jackpot or {}

    jackpotResult.bet = globalData.slotRunData:getCurTotalBet() / 50
    jackpotResult.payLineCount = 50
    jackpotResult.action = "NORMAL"
    jackpotResult.features = {0}
    jackpotResult.freespin = {}
    jackpotResult.freespin.freeSpinsTotalCount = 0
    jackpotResult.freespin.fsMultiplier = 0 
    jackpotResult.freespin.freeSpinsLeftCount = 0
    jackpotResult.freespin.fsWinCoins = 0
    jackpotResult.freespin.freeSpinNewCount = 0
    jackpotResult.freespin.newTrigger = false
    jackpotResult.freespin.fsModeId = 0
    jackpotResult.respin = {}
    jackpotResult.respin.reSpinsTotalCount = 0 
    jackpotResult.respin.reSpinCurCount = 0
    jackpotResult.respin.resWinCoins = 0

    return jackpotResult
end

function CodeGameScreenMrCashMachine:playJackPotCollectAct( func  )
    

    self.m_JpMiniReel:setVisible(true)
    self:hideAllSymbolNode( )

    self.m_JpMiniReel:changeBaseReelNode( self.m_stcValidSymbolMatrix )

    -- 无奈之举，客户端模拟服务器数据
    local jackpotResult = self:copyAndCreateMiniReelNetData( )
    
    self.m_JpMiniReel:setActEndCall( function(  )

        gLobalSoundManager:playSound("MrCashSounds/music_MrCash_MrCash_JpGame_XuanZhong.mp3")
        
            self:sortOutJackpPotCollectData( function(  )
    
                local jackpotType = nil
                local coins = jackpotResult.winAmount or 0
                local CollectNum = self.m_JPReelCollectNum
                local WinList = {37,46,50}
                if CollectNum < WinList[1]  then  -- < 36
                    -- mini
                    self.m_JpWinBar:findChild("mini"):setVisible(true)
                    jackpotType = 4
                elseif CollectNum >= WinList[1] and CollectNum < WinList[2] then -- 37 -45
                    jackpotType = 3
                elseif CollectNum >= WinList[2] and CollectNum < WinList[3] then -- 46 - 49
                    jackpotType = 2
                elseif CollectNum >= WinList[3] then -- >= 50
                    jackpotType = 1
                end

                -- 更新钱
                self:updateLittleCoins( coins )

                gLobalSoundManager:playSound("MrCashSounds/music_MrCash_JackpotOver.mp3")
                self:showJackpotWinView(jackpotType,coins,function(  )


                    self:resetMusicBg(true)

                
                    if func then
                        func()
                    end

                end)


                

                self.m_JpWinBar:setVisible(false)
                self.m_JpMarkView:setVisible(false)
                self.m_JpMiniReel:setVisible(false) 
                self:showAllSymbolNode( )

                

                

        end )
        self:beginJackpPotCollectAct(  )
        

        self.m_JpWinBar:findChild("m_lb_num"):setString("")
        

    end )


    performWithDelay(self,function(  )

        -- 显示中奖ui
        self.m_JpWinBar:setVisible(true)
        self.m_JpWinBar:runCsbAction("idle")
        self.m_JpWinBar:findChild("m_lb_num"):setString("")
        
        self.m_JpMarkView:setVisible(true)
        self.m_JpMarkView:runCsbAction("star",false,function(  )
            self.m_JpMarkView:runCsbAction("start2")
        end)
        
        self.m_JpMiniReel:beginReel()  

        -- 0.5秒后停止滚动
        performWithDelay(self,function(  )

            self.m_JpMiniReel:netWorkCallFun(jackpotResult)
        end,0.5)

    end,0.1)
   

    


end



-- -----------------
--------------
--------
-- 钞票人的小动画
-- 鼓掌动画
function CodeGameScreenMrCashMachine:CashManGuZhangIdle(  )
    
    

    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    util_spinePlay(self.m_CashManBody,"idleframe6",true)
    util_spinePlay(self.m_CashManHand_Left,"idleframe6",true)
    util_spinePlay(self.m_CashManHand_Right,"idleframe6",true)
  


end

function CodeGameScreenMrCashMachine:showCashManMask(func )
    self.m_CashManHand_Mask:setVisible(true)
    util_spinePlay(self.m_CashManHand_Mask,"actionframe25")
    util_spineEndCallFunc(self.m_CashManHand_Mask,"actionframe25",function(  )
        if func then
            func()
        end
    end)
end

function CodeGameScreenMrCashMachine:hideCashManMask( func )

    util_spinePlay(self.m_CashManHand_Mask,"actionframe4")
    util_spineEndCallFunc(self.m_CashManHand_Mask,"actionframe4",function(  )
        self.m_CashManHand_Mask:setVisible(false)
        if func then
            func()
        end
    end)
end

-- 用于s随机触发触发棋盘随机玩法时角色
function CodeGameScreenMrCashMachine:triggerSpecialBonus( func )
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    self.m_CashManHand_Left:setVisible(false)
    self.m_CashManHand_Right:setVisible(false)

    gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_specialGameTrigger.mp3")

    self.m_CashManHand_Mask:setVisible(true)
    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    util_spinePlay(self.m_CashManHand_Mask,"actionframe25")
    util_spinePlay(self.m_CashManBody,"actionframe25")
    util_spinePlay(self.m_CashManHand_Left,"actionframe25")
    util_spinePlay(self.m_CashManHand_Right,"actionframe25")
    util_spineEndCallFunc(self.m_CashManBody,"actionframe25",function(  )

        

        util_spinePlay(self.m_CashManBody,"idleframe2",true)
        util_spinePlay(self.m_CashManHand_Left,"idleframe2",true)
        util_spinePlay(self.m_CashManHand_Right,"idleframe2",true)

        if func then
            func()
        end
        
    end)

   

end

-- 用于freespin计数滚动时角色
function CodeGameScreenMrCashMachine:fsBarJumpNumStart( )
    
    gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_LongRunBegin.mp3")
    
    self.m_CashManHand_Left:setVisible(false)
    self.m_CashManHand_Right:setVisible(false)

    util_spinePlay(self.m_CashManBody,"actionframe26")
    util_spineEndCallFunc(self.m_CashManBody,"actionframe26",function(  )

        util_spinePlay(self.m_CashManBody,"actionframe27",true)

    end) 

end

function CodeGameScreenMrCashMachine:fsBarJumpNumOver( )

    util_spinePlay(self.m_CashManBody,"actionframe28")
    util_spineEndCallFunc(self.m_CashManBody,"actionframe28",function(  )

        util_spinePlay(self.m_CashManBody,"idleframe",true)

    end) 
end

--进入关卡动画
function CodeGameScreenMrCashMachine:CashManEnterLevel( )

    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    util_spinePlay(self.m_CashManBody,"actionframe")
    util_spinePlay(self.m_CashManHand_Left,"actionframe")
    util_spinePlay(self.m_CashManHand_Right,"actionframe")

    util_spineEndCallFunc(self.m_CashManBody,"actionframe",function ( )
        self.m_CashManHand_Left:setVisible(false)
        self.m_CashManHand_Right:setVisible(false)

        util_spinePlay(self.m_CashManBody,"idleframe",true) 
    end)
end

-- 播放快滚动画
function CodeGameScreenMrCashMachine:CashManStartLongRun( )
    
    self.m_CashManHand_Right:setVisible(false)
    self.m_CashManHand_Left:setVisible(false)

    
    

    self.m_CashManBodyLongRunAct = true
    util_spinePlay(self.m_CashManBody,"actionframe21")
    util_spineEndCallFunc(self.m_CashManBody,"actionframe21",function(  )

        util_spinePlay(self.m_CashManBody,"actionframe22",true)

    end)  
end
-- 快滚停止动画
function CodeGameScreenMrCashMachine:CashManStopLongRun(  )
    
    if self.m_CashManBodyLongRunAct then
        self.m_CashManBodyLongRunAct = false

        local feature = self.m_runSpinResultData.p_features or {}
        if #feature == 2 and feature[2] == 1 then

            gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCashYes.mp3")

            --用于播放快滚时  中  SCATTER角色动画
            util_spinePlay(self.m_CashManBody,"actionframe23")
            util_spineEndCallFunc(self.m_CashManBody,"actionframe23",function(  )
        
                util_spinePlay(self.m_CashManBody,"idleframe",true)
        
            end) 
        
        else
            -- gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCashOh.mp3")
            --用于播放快滚时  没中  SCATTER角色动画
            util_spinePlay(self.m_CashManBody,"actionframe24")
            util_spineEndCallFunc(self.m_CashManBody,"actionframe24",function(  )
        
                util_spinePlay(self.m_CashManBody,"idleframe",true)
        
            end) 
        end


    end
    

    
end

-- 趴在桌子上
function CodeGameScreenMrCashMachine:CashManLieOnTheTable( func )
    
    gLobalSoundManager:playSound("MrCashSounds/music_MrCash_PaZaiLunZi.mp3")

    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    util_spinePlay(self.m_CashManBody,"actionframe2")
    util_spinePlay(self.m_CashManHand_Left,"actionframe2")
    util_spinePlay(self.m_CashManHand_Right,"actionframe2")
    util_spineEndCallFunc(self.m_CashManBody,"actionframe2",function(  )

        util_spinePlay(self.m_CashManBody,"idleframe2",true)
        util_spinePlay(self.m_CashManHand_Left,"idleframe2",true)
        util_spinePlay(self.m_CashManHand_Right,"idleframe2",true)


        if func then
            func()
        end
    end)

    
    
end

-- 返回idle状态
function CodeGameScreenMrCashMachine:CashManReturnIdle( func , isShowMask )
    
    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    if isShowMask then
        self.m_CashManHand_Mask:setVisible(true) 
    end
    
    
    util_spinePlay(self.m_CashManBody,"actionframe4")
    util_spinePlay(self.m_CashManHand_Mask,"actionframe4")
    util_spinePlay(self.m_CashManHand_Left,"actionframe4")
    util_spinePlay(self.m_CashManHand_Right,"actionframe4")
    util_spineEndCallFunc(self.m_CashManBody,"actionframe4",function(  )

        self.m_CashManHand_Left:setVisible(false)
        self.m_CashManHand_Right:setVisible(false)
        self.m_CashManHand_Mask:setVisible(false)

        util_spinePlay(self.m_CashManBody,"idleframe",true)
        util_spinePlay(self.m_CashManHand_Left,"idleframe",true)
        util_spinePlay(self.m_CashManHand_Right,"idleframe",true)

        if func then
            func()
        end
    end)

    
    
end

-- 转动大圆盘
function CodeGameScreenMrCashMachine:CashManRotatingDisc( func )

    self:findChild("manhandLeft"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 11)

    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    
    util_spinePlay(self.m_CashManBody,"actionframe3")
    util_spinePlay(self.m_CashManHand_Left,"actionframe3")
    util_spinePlay(self.m_CashManHand_Right,"actionframe3")
    util_spineFrameCallFunc(self.m_CashManBody, "actionframe3", "show7", 
        function()

            if func then
                func()
            end

        end,
        function()
            self:findChild("manhandLeft"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
            util_spinePlay(self.m_CashManBody,"idleframe2",true)
            util_spinePlay(self.m_CashManHand_Left,"idleframe2",true)
            util_spinePlay(self.m_CashManHand_Right,"idleframe2",true)
        end 
    )
end

-- 用于圆盘手勾一下移动
function CodeGameScreenMrCashMachine:CashManShowWheelUp( func ,reelIndex ,funEnd,movePos,func2)

    local actIndex = reelIndex + 5
    local movePosY = {121,65,7,86,36}


    if reelIndex <= 3 then
        self:findChild("manhandLeft"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

        
        local manhandLeftPos = cc.p(self:findChild("manhandLeft"):getPosition())
        util_playMoveToAction(self:findChild("manhandLeft"),7/30,cc.p(manhandLeftPos.x,manhandLeftPos.y + movePosY[reelIndex]),function(  )
            util_playMoveToAction(self:findChild("manhandLeft"),18/30,cc.p(manhandLeftPos.x,movePos.y  + 70 +  109.2),function(  )
                if func2 then
                    func2()
                end
                util_playMoveToAction(self:findChild("manhandLeft"),15/30,cc.p(manhandLeftPos.x,manhandLeftPos.y),function(  )

                end)
            end)
        end)

    else

        self:findChild("manhandRight"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

        local manhandLeftPos = cc.p(self:findChild("manhandRight"):getPosition())
        util_playMoveToAction(self:findChild("manhandRight"),7/30,cc.p(manhandLeftPos.x,manhandLeftPos.y + movePosY[reelIndex]),function(  )
            util_playMoveToAction(self:findChild("manhandRight"),17/30,cc.p(manhandLeftPos.x,movePos.y + self.m_SlotNodeH / 2 + 70 + 109.2),function(  )
                util_playMoveToAction(self:findChild("manhandRight"),15/30,cc.p(manhandLeftPos.x,manhandLeftPos.y),function(  )

                end)
            end)
        end)
    end
    
    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    
    util_spinePlay(self.m_CashManBody,"actionframe".. actIndex)
    util_spinePlay(self.m_CashManHand_Left,"actionframe".. actIndex)
    util_spinePlay(self.m_CashManHand_Right,"actionframe".. actIndex)
    util_spineFrameCallFunc(self.m_CashManBody, "actionframe".. actIndex, "show" .. reelIndex + 1, 
        function()

            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_OpenDoor_Move.mp3")

            if func then
                func()
            end

        end,
        function()
            if funEnd then
                funEnd()
            end
            
        end 
    )
end

-- 用于开门图标移动
function CodeGameScreenMrCashMachine:CashManPushOpenDoorSymbolUp( func ,reelIndex ,funEnd,movePos,func2)

    local actIndex = reelIndex + 5
    local movePosY = {121,65,7,86,36}


    if reelIndex <= 3 then
        self:findChild("manhandLeft"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

        
        local manhandLeftPos = cc.p(self:findChild("manhandLeft"):getPosition())
        util_playMoveToAction(self:findChild("manhandLeft"),7/30,cc.p(manhandLeftPos.x,manhandLeftPos.y + movePosY[reelIndex]),function(  )
            util_playMoveToAction(self:findChild("manhandLeft"),17/30,cc.p(manhandLeftPos.x,movePos.y + self.m_SlotNodeH / 2 + 70 +  109.2),function(  )
                if func2 then
                    func2()
                end
                util_playMoveToAction(self:findChild("manhandLeft"),15/30,cc.p(manhandLeftPos.x,manhandLeftPos.y),function(  )

                end)
            end)
        end)

    else

        self:findChild("manhandRight"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

        local manhandLeftPos = cc.p(self:findChild("manhandRight"):getPosition())
        util_playMoveToAction(self:findChild("manhandRight"),7/30,cc.p(manhandLeftPos.x,manhandLeftPos.y + movePosY[reelIndex]),function(  )
            util_playMoveToAction(self:findChild("manhandRight"),17/30,cc.p(manhandLeftPos.x,movePos.y + self.m_SlotNodeH / 2 + 70 + 109.2),function(  )
                util_playMoveToAction(self:findChild("manhandRight"),15/30,cc.p(manhandLeftPos.x,manhandLeftPos.y),function(  )

                end)
            end)
        end)
    end
    
    self.m_CashManHand_Left:setVisible(true)
    self.m_CashManHand_Right:setVisible(true)
    
    util_spinePlay(self.m_CashManBody,"actionframe".. actIndex)
    util_spinePlay(self.m_CashManHand_Left,"actionframe".. actIndex)
    util_spinePlay(self.m_CashManHand_Right,"actionframe".. actIndex)
    util_spineFrameCallFunc(self.m_CashManBody, "actionframe".. actIndex, "show" .. reelIndex + 1, 
        function()

            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_OpenDoor_Move.mp3")

            if func then
                func()
            end

        end,
        function()
            if funEnd then
                funEnd()
            end
            
        end 
    )
end

-- 用于freespin触拉开窗帘

function CodeGameScreenMrCashMachine:OpenTheCurtain( func  )
    
    util_spinePlay(self.m_normalBgSpine,"guochang")
    util_spineEndCallFunc(self.m_normalBgSpine, "guochang",function(  )
        if func then
            func()
        end
    end)
  
end

function CodeGameScreenMrCashMachine:CloseTheCurtain( func )
    util_spinePlay(self.m_normalBgSpine,"guochang2")
    util_spineEndCallFunc(self.m_normalBgSpine, "guochang2",function(  )
        if func then
            func()
        end
    end)
end

function CodeGameScreenMrCashMachine:CashManTheCurtainAct( func ,funcEnd  )


    self.m_CashManHand_Left:setVisible(false)
    self.m_CashManHand_Right:setVisible(false)

    util_spinePlay(self.m_CashManBody,"guochang")
    util_spineFrameCallFunc(self.m_CashManBody, "guochang", "show9", 
        function()

            if func then
                func()
            end

        end,
        function()
            
            util_spinePlay(self.m_CashManBody,"idleframe",true)

            if funcEnd then
                funcEnd()
            end
            
        end 
    )
end

local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenMrCashMachine:addLastWinSomeEffect() -- add big win or mega win

    -- 触发特殊玩法后 判断是否大赢
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerType = selfdata.triggerType or ""
    if #self.m_vecGetLineInfo == 0 then
        if triggerType == self.TriggerType_Wheel then -- 圆盘玩法
    
        else
            
            return
        end
    end
   
    

   

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值


    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢

        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)

    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or
            self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or
            self.m_fLastWinBetNumRatio < 1
    then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

end

function CodeGameScreenMrCashMachine:showEffect_NewWin(effectData,winType)

    self:changeCashManBodyToBigWinAct( )

    BaseNewReelMachine.showEffect_NewWin(self,effectData,winType)
end

function CodeGameScreenMrCashMachine:changeCashManBodyToBigWinAct( )
    
    self.m_CashManHand_Left:setVisible(false)
    self.m_CashManHand_Right:setVisible(false)

    util_spinePlay(self.m_CashManBody,"idleframe4",true)
    util_spineEndCallFunc(self.m_CashManBody,"idleframe4",function ( )
        util_spinePlay(self.m_CashManBody,"idleframe3",true) 
    end)

    self.m_CashManBody.m_BigWinIdle = true
end

function CodeGameScreenMrCashMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self:CashManStopLongRun(  )

    BaseNewReelMachine.slotReelDown(self)
  
end

function CodeGameScreenMrCashMachine:playEffectNotifyNextSpinCall( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )

end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenMrCashMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()

    end

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end

function CodeGameScreenMrCashMachine:checkWinLinesIsUpdate( )
    
    local winLines = self.m_runSpinResultData.p_winLines or {}
    local isUpdate = false

    for i=1,#winLines do
        local lines = winLines[i]
        if lines.p_iconPos and #lines.p_iconPos > 0 then
            isUpdate = true
            break
        end
    end

    return isUpdate

end

function CodeGameScreenMrCashMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end

    if self:checkWinLinesIsUpdate( ) then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local littleGameWinCoins = self:getLittleCoins( )

        if isNotifyUpdateTop == false then

            
            if littleGameWinCoins then

                local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
                local beiginCoins = fsWinCoin - (self.m_serverWinCoins - littleGameWinCoins)

                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{fsWinCoin,isNotifyUpdateTop,nil,beiginCoins})
                globalData.slotRunData.lastWinCoin = lastWinCoin
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop}) 
            end

        else
            if littleGameWinCoins then

                local beiginCoins = littleGameWinCoins
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop,nil,beiginCoins})

            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop}) 
            end

        end

        

       
    end
    
end

function CodeGameScreenMrCashMachine:getLittleCoins( )
    
    local coins = nil

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local wheelCoins = selfdata.wheelCoins 
    if wheelCoins and wheelCoins > 0 then
        coins = wheelCoins
    end

    local jackpotResult = selfdata.jackpot or {}
    local jackpotCoins = jackpotResult.winAmount 
    if jackpotCoins and jackpotCoins > 0 then
        coins = jackpotCoins
    end

    return coins
end


function CodeGameScreenMrCashMachine:updateLittleCoins( coins )
    local winCoin = self.m_serverWinCoins
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if not self:checkWinLinesIsUpdate( ) then
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        if self:getCurrSpinMode() == FREE_SPIN_MODE then

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,nil,nil,nil,true})

        else
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,nil,nil,nil,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end
    else

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then 
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,nil,nil,nil,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin

        else
            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            local updateCoins = fsWinCoin - self.m_serverWinCoins +  coins
            local beiginCoins = fsWinCoin - self.m_serverWinCoins
            if updateCoins > 0 then
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{updateCoins,false,nil,beiginCoins,nil,true})
                globalData.slotRunData.lastWinCoin = lastWinCoin
            end
            
        end

    end
end

function CodeGameScreenMrCashMachine:setNormalSymbolType( )
    
    self.m_initNodeSymbolType = math.random(0 , 9 )

end

function CodeGameScreenMrCashMachine:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex,reelDatas  )
    
    

    local changedSymbolType = 0

    if colIndex and reelDatas  then

        if self.m_m_initNodeIndex == nil then
            self.m_m_initNodeIndex = math.random(1,#reelDatas) 
        end

        self.m_m_initNodeIndex = self.m_m_initNodeIndex + 1
        if self.m_m_initNodeIndex > #reelDatas then
            self.m_m_initNodeIndex = 1
        end

        changedSymbolType = reelDatas[self.m_m_initNodeIndex]

        if changedSymbolType == self.SYMBOL_SCORE_MYSTER then
             
            if self.m_initNodeCol ~= colIndex then
                self.m_initNodeCol = colIndex
                self:setNormalSymbolType( )

                changedSymbolType = self.m_initNodeSymbolType

            else

                changedSymbolType = self.m_initNodeSymbolType

            end   
        end
    else
        changedSymbolType = symbolType
    end
    

    return changedSymbolType
end

function CodeGameScreenMrCashMachine:createWheelTipVIew( func )
    
    
    gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCashWheelTip.mp3")

    local WheelTipView = util_createView("CodeMrCashSrc.MrCashShowWheelTipView")
    self:findChild("WheelView"):addChild(WheelTipView,1)

    if globalData.slotRunData.machineData.p_portraitFlag then
        WheelTipView.getRotateBackScaleFlag = function(  ) return false end
    end


    WheelTipView:findChild("click"):setVisible(false)
    WheelTipView:setClickCallFunc(function(  )
        if func then
            func()
        end
    end)
    WheelTipView:runCsbAction("start",false,function(  )
        WheelTipView:runCsbAction("idle",true)
        local node = cc.Node:create()
        self:addChild(node)
        performWithDelay(node,function(  )
            node:removeFromParent()
            if WheelTipView.m_callFunc then
                WheelTipView.m_callFunc()
            end

        end,1)
        
    end)

end

---
-- 显示五个元素在同一条线效果
function CodeGameScreenMrCashMachine:showEffect_FiveOfKind(effectData)

    local feature = self.m_runSpinResultData.p_features or {}

    if feature and #feature == 2 and feature[2] == 1 then
        -- 触发freespin的时候不播放5连
        effectData.p_isPlay = true
        self:playGameEffect()

    else
        BaseNewReelMachine.showEffect_FiveOfKind(self,effectData)
    end

    return true
end

function CodeGameScreenMrCashMachine:PretreatmentFreeSpinTimesCollect( func )
    
    self.m_actScatterNodeList = {}
    local maxCol = self:getMaxContinuityBonusCol( )
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = self.m_iReelRowNum, 1 , -1 do
            if iCol <= maxCol then
                local tarsp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            
                if tarsp and tarsp.p_symbolType and tarsp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    
                    table.insert(self.m_actScatterNodeList,tarsp)
                end
            end
            
            
        end

    end

    self.m_actScatterIndex = 0
    self.m_scatterCollectTimes = 0
    self.m_actScatterCallFunc = function(  )

        if func then
            func()
        end

    end


    self:BeginFreeSpinTimesCollect( )
end

function CodeGameScreenMrCashMachine:BeginFreeSpinTimesCollect( )
    
    self.m_actScatterIndex = self.m_actScatterIndex + 1

    if self.m_actScatterIndex > #self.m_actScatterNodeList then
        

        gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCashNice.mp3")

        if self.m_actScatterCallFunc then
            self.m_actScatterCallFunc()
        end

        return 
    end


    local time = 0.3

    local actScatter = self.m_actScatterNodeList[self.m_actScatterIndex]
    local index = self:getPosReelIdx(actScatter.p_rowIndex , actScatter.p_cloumnIndex)
    local pos = cc.p(util_getOneGameReelsTarSpPos(self,index))
    local actParticle = util_createAnimation("MrCash_FS_shouji.csb")

    self:findChild("reel"):addChild(actParticle, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 4) 
    actParticle:setPosition(pos)
    actParticle:findChild("Particle_1"):setPositionType(0)
    actParticle:findChild("Particle_1"):setDuration(time)

    local endWoldPos = self.m_FsBar:findChild("Node"):convertToWorldSpace(cc.p(0,0))
    local endPos =  self.m_clipParent:convertToNodeSpace(cc.p(endWoldPos.x,endWoldPos.y))


    local storeIcons = self:getLockScatterPos() 

    for i = 1, #storeIcons do
        local icon = storeIcons[i]
        local iconPos = icon[1]
        local iconValue = icon[2]
        if index == iconPos then
            self.m_scatterCollectTimes = self.m_scatterCollectTimes + iconValue
            break
        end
    end

    gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCashFly.mp3")

    local actionList={}
    actionList[#actionList+1]=cc.MoveTo:create(time,endPos);
    actionList[#actionList+1]=cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("MrCashSounds/MrCashSounds_MrCashFlyEnd.mp3")
        self.m_FsBar:runCsbAction("shouji")

        self.m_FsBar:updateFreespinCount( self.m_scatterCollectTimes )

        performWithDelay(self,function(  )
            self:BeginFreeSpinTimesCollect( )
        end,0.1)

    end)
    actionList[#actionList+1]=cc.DelayTime:create(time)
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
       
        actParticle:removeFromParent()

    end)
    local seq=cc.Sequence:create(actionList)
    actParticle:runAction(seq)

 
end

--消息返回
function CodeGameScreenMrCashMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" then
        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        self:setNetMysteryType()
        
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end
--切换假滚类型
function CodeGameScreenMrCashMachine:randomMystery()
    self.m_bNetSymbolType = false
    for i = 1, #self.m_mysterList do
        local symbolInfo = self:getColIsSameSymbol(i,false)
        local symbolType = symbolInfo.symbolType
        self.m_mysterList[i] =symbolType
        if  symbolInfo.symbolType ~= -1 then
            local symbolNodeList,start,over = self.m_reels[i].m_gridList:getList()
            local gridNode = symbolNodeList[over]
            --由于最上面未显示的类型不确定 在假滚的过程中导致突然插入不同类型 在这里切换一下类型
            if gridNode  then
                gridNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType ), symbolType)
                if gridNode.p_symbolImage ~= nil then
                    gridNode:runIdleAnim()
                end
            end
        end
    end

    self.m_configData:setMysterSymbol(self.m_mysterList)
end



--使用现在获取的数据 来表现假滚 如果一列全相同 则滚动相同信号 一列不同及有快滚则播放配置的假滚数据
function CodeGameScreenMrCashMachine:setNetMysteryType()
    self.m_changeReelDataId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_bNetSymbolType = true
            local bRunLong = false
            for i = 1, #self.m_mysterList do
                local symbolInfo = self:getColIsSameSymbol(i,true)
                self.m_mysterList[i] = symbolInfo.symbolType
                local reelRunData = self.m_reelRunInfo[i]
                if bRunLong then
                    self.m_mysterList[i] = -1
                end
                if self.m_mysterList[i] == -1 then
                    self:changeSlotReelDatas(i, bRunLong)
                end
                if reelRunData:getNextReelLongRun() == true then
                    bRunLong = true
                end
            end
        end,
        0.3,
        "changeReelData"
    )
end
--移除定时器
function CodeGameScreenMrCashMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end

--使用配置的假滚数据
function CodeGameScreenMrCashMachine:changeSlotReelDatas(_col, _bRunLong)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData, _bRunLong)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end
--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenMrCashMachine:checkUpdateReelDatas(parentData, _bRunLong)
    local reelDatas = nil

 
    if _bRunLong == true then
        reelDatas = self.m_configData:getRunLongDatasByColumnIndex(parentData.cloumnIndex)
    else
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        else
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        end
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--随机信号
function CodeGameScreenMrCashMachine:getReelSymbolType(parentData)
    local cloumnIndex = parentData.cloumnIndex
    if self.m_bNetSymbolType == true then
        if self.m_mysterList[cloumnIndex] ~= -1 then
            return self.m_mysterList[cloumnIndex]
        end
    end
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end

--判断一列是否是相同的信号块 _iCol 列数， _bNetdata 使用服务器的数据 为true，由于信号块切换过类型使用当前显示的信号块类型为false 
function CodeGameScreenMrCashMachine:getColIsSameSymbol(_iCol,_bNetdata)
    local reelsData = self.m_runSpinResultData.p_reels
    if reelsData and next(reelsData) then
        local symbolInfo = {}
        local tempType
        local symbolType = nil
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
            if _bNetdata then
                tempType = reelsData[iRow][_iCol]
            else
                if slotNode and slotNode.p_symbolType  then
                    tempType = slotNode.p_symbolType
                end
            end
   
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType ~= tempType then
                symbolInfo.symbolType = -1
                symbolInfo.bSame = false
                return symbolInfo
            end
        end
        symbolInfo.symbolType = tempType
        symbolInfo.bSame = true
        return symbolInfo
    else
        local symbolInfo = {}
        symbolInfo.symbolType = -1
        symbolInfo.bSame = false
        return symbolInfo
    end
end

return CodeGameScreenMrCashMachine






