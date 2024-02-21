---
-- island li
-- 2019年1月26日
-- CodeGameScreenBlazingMotorsMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenBlazingMotorsMachine = class("CodeGameScreenBlazingMotorsMachine", BaseSlotoManiaMachine)

CodeGameScreenBlazingMotorsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBlazingMotorsMachine.SYMBOL_BlazingMotors_NORMAL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  
CodeGameScreenBlazingMotorsMachine.SYMBOL_BlazingMotors_GOLD  = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 
 
CodeGameScreenBlazingMotorsMachine.SYMBOL_RISING = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 
CodeGameScreenBlazingMotorsMachine.SYMBOL_LONG_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3 
CodeGameScreenBlazingMotorsMachine.SYMBOL_BIG_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenBlazingMotorsMachine.SYMBOL_Lock_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9


CodeGameScreenBlazingMotorsMachine.SYMBOL_WHEEL_NODE_Lock = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4 
CodeGameScreenBlazingMotorsMachine.SYMBOL_WHEEL_NODE_Sweep = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5
CodeGameScreenBlazingMotorsMachine.SYMBOL_WHEEL_NODE_WildReels = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6
CodeGameScreenBlazingMotorsMachine.SYMBOL_WHEEL_NODE_Rising = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7



CodeGameScreenBlazingMotorsMachine.SYMBOL_BlazingMotors_NULL  = -1

CodeGameScreenBlazingMotorsMachine.BLAZINGMOTORS_BlazingMotors_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- jackPot
CodeGameScreenBlazingMotorsMachine.BLAZINGMOTORS_LOCK_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- lockWild
CodeGameScreenBlazingMotorsMachine.BLAZINGMOTORS_RISING_BET_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- lockWild



CodeGameScreenBlazingMotorsMachine.FreeGameType_LOCKWILD = 0  
CodeGameScreenBlazingMotorsMachine.FreeGameType_REELSWILD  = 1  
CodeGameScreenBlazingMotorsMachine.FreeGameType_RISINGBET = 2
CodeGameScreenBlazingMotorsMachine.FreeGameType_WILDSWEEP = 3

CodeGameScreenBlazingMotorsMachine.WILDSWEEP_NodeList = {}
CodeGameScreenBlazingMotorsMachine.REELSWILD_NodeList = {}
CodeGameScreenBlazingMotorsMachine.LOCKWILD_NodeList = {}
CodeGameScreenBlazingMotorsMachine.LOCKRESPIN_NodeList = {}

CodeGameScreenBlazingMotorsMachine.m_dontRunCol = nil


CodeGameScreenBlazingMotorsMachine.REELSWILD_DataList = {}
CodeGameScreenBlazingMotorsMachine.WILDSWEEP_DataList = nil

CodeGameScreenBlazingMotorsMachine.m_respinJackPotId = 0

CodeGameScreenBlazingMotorsMachine.m_isLongWildWait = false -- 是否是长条延时
CodeGameScreenBlazingMotorsMachine.m_vecRapids = nil



local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136
-- 构造函数
function CodeGameScreenBlazingMotorsMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.WILDSWEEP_NodeList = {}
    self.REELSWILD_NodeList = {}
    self.LOCKWILD_NodeList = {}
    self.REELSWILD_DataList = {}
    self.WILDSWEEP_DataList = nil

    self.LOCKRESPIN_NodeList = {}
    self.m_dontRunCol = {0,0,0,0,0}

    self.m_lightScore = 0
    self.m_respinJackPotId = 0

    self.m_isLongWildWait = false
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenBlazingMotorsMachine:initGame()
 
    self.m_configData = gLobalResManager:getCSVLevelConfigData("BlazingMotorsConfig.csv", "LevelBlazingMotorsConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {2,3,4}
end  

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenBlazingMotorsMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "BlazingMotorsSounds/BlazingMotors_scatter_down.mp3"
        elseif i == 2 then
            soundPath = "BlazingMotorsSounds/BlazingMotors_scatter_down.mp3"
        else
            soundPath = "BlazingMotorsSounds/BlazingMotors_scatter_down.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBlazingMotorsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BlazingMotors"  
end

function CodeGameScreenBlazingMotorsMachine:getBottomUINode( )
    return "CodeBlazingMotorsSrc.BlazingMotorsGameBottomNode"
end

function CodeGameScreenBlazingMotorsMachine:initUI()

    for i=1,5 do
        local pos = i - 1
        self:findChild("LongRunBg_"..pos):setVisible(false)
    end
   
            

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    
    self.m_LocalTopView = util_createView("CodeBlazingMotorsSrc.BlazingMotorsTopView")
    self:findChild("Jackpot"):addChild(self.m_LocalTopView)
    self.m_LocalTopView:initMachine(self)
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_LocalTopView:findChild("JackpotClip"):setVisible(true)
    self.m_LocalTopView:findChild("totalwon"):setVisible(false)
    self.m_LocalTopView:findChild("totalwon1"):setVisible(false)
    self.m_LocalTopView:findChild("BlazingMotors_Wheel"):setVisible(true)

 


    self:findChild("door1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self:findChild("door2"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self:findChild("risingNodeOne"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    -- 创建view节点方式
    self.m_BlazingMotorsDoorView_1 = util_createView("CodeBlazingMotorsSrc.BlazingMotorsDoorView")
    self:findChild("door1"):addChild(self.m_BlazingMotorsDoorView_1)

    self.m_BlazingMotorsDoorView_2 = util_createView("CodeBlazingMotorsSrc.BlazingMotorsDoorView")
    self:findChild("door2"):addChild(self.m_BlazingMotorsDoorView_2)

    self.m_BlazingMotorsDoorView_1:setVisible(false)
    self.m_BlazingMotorsDoorView_2:setVisible(false)

    
    self.m_BlazingMotorsRisingIdelView = util_createView("CodeBlazingMotorsSrc.BlazingMotorsRisingIdelView")
    self:findChild("risingNodeOne"):addChild(self.m_BlazingMotorsRisingIdelView)
    self.m_BlazingMotorsRisingIdelView:setVisible(false)
    

    -- 创建view节点方式
    -- self.m_BlazingMotorsView = util_createView("CodeBlazingMotorsSrc.BlazingMotorsView")
    -- self:findChild("xxxx"):addChild(self.m_BlazingMotorsView)
   
 
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
        elseif winRate > 3 then
            soundIndex = 3
        end
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "BlazingMotorsSounds/music_BlazingMotors_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenBlazingMotorsMachine:changeViewNodePos( )
   
    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local nodeLunpan = self:findChild("Jackpot")
        nodeLunpan:setPositionY(nodeLunpan:getPositionY() - posY)
        local BlazingMotors_side_1 = self:findChild("BlazingMotors_side_1")
        BlazingMotors_side_1:setPositionY(BlazingMotors_side_1:getPositionY() - posY)
        local BlazingMotors_side_2 = self:findChild("BlazingMotors_side_2")
        BlazingMotors_side_2:setPositionY(BlazingMotors_side_2:getPositionY() - posY)
        self:findChild("wheel"):setPositionY(self:findChild("wheel"):getPositionY() - posY)
        self:findChild("door1"):setPositionY(self:findChild("door1"):getPositionY() - posY)
        self:findChild("door2"):setPositionY(self:findChild("door2"):getPositionY() - posY)

        for i=1,self.m_iReelColumnNum do
            local pos = i -1
            self:findChild("sp_reel_"..pos):setPositionY(self:findChild("sp_reel_"..pos):getPositionY() - posY)
            self:findChild("reel_"..pos):setPositionY(self:findChild("reel_"..pos):getPositionY() - posY)
            self:findChild("LongRunBg_"..pos):setPositionY(self:findChild("LongRunBg_"..pos):getPositionY() - posY)
            
        end

        
        -- local nodeJackpot_0 = self:findChild("Node_1_0")
        -- local nodeJackpot_1 = self:findChild("Node_1_1")
        -- nodeJackpot_0:setPositionY(nodeJackpot_0:getPositionY() + posY -50)
        -- nodeJackpot_1:setPositionY(nodeJackpot_1:getPositionY() + posY -50 )


    elseif display.height < FIT_HEIGHT_MIN then
        

    end

    
end

function CodeGameScreenBlazingMotorsMachine:scaleMainLayer()
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
        if display.height >= FIT_HEIGHT_MAX then
            mainScale = (FIT_HEIGHT_MAX + 80 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale + 0.05
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if (display.height / display.width) >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 46)
            else
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 42 )
            end
            
        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 73 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 40)
        else
            mainScale = (display.height + 78 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 46)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
    
end

function CodeGameScreenBlazingMotorsMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenBlazingMotorsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_LocalTopView:updateJackpotInfo()

end

function CodeGameScreenBlazingMotorsMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

end

function CodeGameScreenBlazingMotorsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBlazingMotorsMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_BlazingMotors_NORMAL then
        return "Socre_BlazingMotors_shot1"
    elseif symbolType == self.SYMBOL_BlazingMotors_GOLD  then
        return "Socre_BlazingMotors_shot2"
    elseif symbolType == self.SYMBOL_BlazingMotors_NULL  then
        return "Socre_BlazingMotors_Null"  
    elseif symbolType == self.SYMBOL_RISING then
        return "Socre_BlazingMotors_Rising"
    elseif symbolType == self.SYMBOL_LONG_WILD then
        return "Socre_BlazingMotors_Wild2"
    elseif symbolType == self.SYMBOL_BIG_WILD then
        return "Socre_BlazingMotors_Wild2"
    elseif symbolType == self.SYMBOL_Lock_WILD then
        return "Socre_BlazingMotors_LockWild"
    elseif symbolType == self.SYMBOL_WHEEL_NODE_Lock then
        return "BlazingMotors_Wheel_lv"
    elseif symbolType == self.SYMBOL_WHEEL_NODE_Sweep then
        return "BlazingMotors_Wheel_hong"
    elseif symbolType == self.SYMBOL_WHEEL_NODE_WildReels then
        return "BlazingMotors_Wheel_zi"
    elseif symbolType == self.SYMBOL_WHEEL_NODE_Rising then
        return "BlazingMotors_Wheel_huang"
    end  

    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBlazingMotorsMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BlazingMotors_NORMAL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BlazingMotors_GOLD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BlazingMotors_NULL,count =  2}
    
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_RISING,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LONG_WILD,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Lock_WILD,count =  2}
    
    
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WHEEL_NODE_Lock,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WHEEL_NODE_Sweep,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WHEEL_NODE_WildReels,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WHEEL_NODE_Rising,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------
---- lighting 断线重连时，随机转盘数据
function CodeGameScreenBlazingMotorsMachine:respinModeChangeSymbolType( )

    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then

        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            

        else

            local storedIcons = self.m_initSpinData.p_storedIcons
            if storedIcons == nil or #storedIcons <= 0 then
                return
            end

            local function isInArry(iRow, iCol)
                for k = 1, #storedIcons do
                    local fix = self:getRowAndColByPos(storedIcons[k][1])
                    if fix.iX == iRow and fix.iY == iCol then
                        return true
                    end
                end
                return false
            end 

            for iRow = 1, #self.m_initSpinData.p_reels do
                local rowInfo = self.m_initSpinData.p_reels[iRow]
                for iCol = 1, #rowInfo do
                    if isInArry(#self.m_initSpinData.p_reels - iRow + 1, iCol) == false then
                        rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % 8
                    end
                end            
            end

        end


        
    end
end
-- 断线重连 
function CodeGameScreenBlazingMotorsMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then 

        for i=1,5 do
            local pos = i - 1
            self:findChild("LongRunBg_"..pos):setVisible(true)
        end

        self.REELSWILD_DataList = {}
        -- 这里作为存储下一次spin时所需要展示的任意一条wild的位置
        if self.m_runSpinResultData.p_selfMakeData then
            local gameType = self.m_runSpinResultData.p_selfMakeData.type
            if gameType and gameType == self.FreeGameType_REELSWILD then
                local wildColumns = self.m_runSpinResultData.p_selfMakeData.wildColumns
                self.REELSWILD_DataList = wildColumns
            end
        end
        
        if self.m_runSpinResultData.p_selfMakeData then
            local gameType = self.m_runSpinResultData.p_selfMakeData.type
            if gameType and gameType == self.FreeGameType_WILDSWEEP then
                local wildColumns = self.m_runSpinResultData.p_selfMakeData.wildColumns
                self.WILDSWEEP_DataList = wildColumns
            end
        end

        if self.m_runSpinResultData.p_selfMakeData then
            local gameType = self.m_runSpinResultData.p_selfMakeData.type
            if gameType and gameType == self.FreeGameType_RISINGBET then
                local risingMultiple = self.m_runSpinResultData.p_selfMakeData.risingMultiple
                if risingMultiple then
                    -- 更新当前的倍数
                    self.m_LocalTopView:findChild("m_lb_num_0"):setString(tostring(risingMultiple).."x")
                end
            end
        end


        self.exhaustSoundId =  gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_penhuo.mp3",true)
    
        util_spinePlay(self.m_LocalTopView.m_exhaust,"idleframe",true)

        self.m_LocalTopView:findChild("JackpotClip"):setVisible(false)
        self.m_LocalTopView:findChild("BlazingMotors_Wheel"):setVisible(false)
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType then 
            if  gameType == self.FreeGameType_RISINGBET then
                self.m_LocalTopView:findChild("totalwon"):setVisible(true)
                self.m_LocalTopView:findChild("totalwon1"):setVisible(false)
                self.m_LocalTopView:runCsbAction("risingidle")
            else
                self.m_LocalTopView:findChild("totalwon"):setVisible(false)
                self.m_LocalTopView:findChild("totalwon1"):setVisible(true)
                self.m_LocalTopView:runCsbAction("normalidle")
            end
        end

    end

    if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self.isInBonus = true
    end

    if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        self.isInBonus = true
    end
    

end

function CodeGameScreenBlazingMotorsMachine:checkIs_InLOCKWILD_NodeList( index)
    local isin = false
    for k,v in pairs(self.LOCKWILD_NodeList) do
        local spr = v
        local sprIndex = self:getPosReelIdx(spr.p_rowIndex, spr.p_cloumnIndex)
        if sprIndex  == index then
            isin = true
            break
        end

    end

    return isin
end

function CodeGameScreenBlazingMotorsMachine:checkRemoveAllLockWild( )

    for k,v in pairs(self.LOCKWILD_NodeList) do
        if v then
            v:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
    end

    self.LOCKWILD_NodeList = {}
end

function CodeGameScreenBlazingMotorsMachine:initSuperWildSlotNodesByNetData( )

    if self.m_runSpinResultData.p_selfMakeData then
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType and gameType == self.FreeGameType_LOCKWILD then
            local lockWilds = self.m_runSpinResultData.p_selfMakeData.lockWilds
            if lockWilds and #lockWilds > 0 then
                for k, v in pairs(lockWilds) do
                    local pos = tonumber(v)
                    local fixPos = self:getRowAndColByPos(pos)
                    local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX) 
    
                    if not self:checkIs_InLOCKWILD_NodeList( pos) then
                        if targSp  then -- and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD

                            targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_Lock_WILD),self.SYMBOL_Lock_WILD)
                            

                            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                            local linePos = {}
                            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                            targSp.m_bInLine = true
                            targSp:setLinePos(linePos)
                            targSp:runAnim("idleframe")
        
                            table.insert( self.LOCKWILD_NodeList,targSp)
                        end
                    end
                   
                end
            end
    
           
        end
    end

   
    
 
end
---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node 
-- 
function CodeGameScreenBlazingMotorsMachine:initCloumnSlotNodesByNetData()
    
    BaseSlotoManiaMachine.initCloumnSlotNodesByNetData(self)

    self:initSuperWildSlotNodesByNetData()

end

function CodeGameScreenBlazingMotorsMachine:checkLockArray( col)
    local notIn = true

    local locks = self.m_dontRunCol --  self.m_runSpinResultData.p_selfMakeData.locks

    if col < 6 then
        local num = self.m_dontRunCol[col]
        if num == 1 then
            notIn = false
        end
    end

    return notIn
end



--
--单列滚动停止回调
--
function CodeGameScreenBlazingMotorsMachine:slotOneReelDown(reelCol)    

    if self.m_vecRapids == nil then
        self.m_vecRapids = {}
    end
    
    for i = 1, self.m_iReelRowNum, 1 do
        local symbol = self:getFixSymbol(reelCol, i, SYMBOL_NODE_TAG)
        if symbol ~= nil and (symbol.p_symbolType == self.SYMBOL_BlazingMotors_NORMAL or symbol.p_symbolType == self.SYMBOL_BlazingMotors_GOLD) then
            if globalData.slotRunData.currSpinMode == RESPIN_MODE and self:checkLockArray(reelCol ) == false then
            
            else
                if reelCol == 5 then 
                    if  #self.m_vecRapids >= 2 then
                        symbol:runAnim("buling")
                    end
                else
                    symbol:runAnim("buling")
                    self.m_vecRapids[#self.m_vecRapids + 1] = symbol
                end
            end
        end
    end

    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol) 


    local isplay= true
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true and isplay then
            isplay = false
            
            if self:checkLockArray(reelCol ) then

                local soundPath = "BlazingMotorsSounds/music_BlazingMotors_respin_showShot.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    -- respinbonus落地音效
                    gLobalSoundManager:playSound(soundPath)
                end

            end  
            
        end
        

    end


 
end

-- 所有滚动列停止
function CodeGameScreenBlazingMotorsMachine:slotReelDown()

    if self.m_vecRapids ~= nil then
        for i = #self.m_vecRapids, 1, -1 do
            table.remove(self.m_vecRapids, i)
        end
        self.m_vecRapids = {}
    end

    BaseSlotoManiaMachine.slotReelDown(self) 

    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
end
function CodeGameScreenBlazingMotorsMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenBlazingMotorsMachine.super.playEffectNotifyNextSpinCall(self)
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBlazingMotorsMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normaltofreespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBlazingMotorsMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关

---
-- 显示free spin
function CodeGameScreenBlazingMotorsMachine:showEffect_FreeSpin(effectData)

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
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if scatterLineValue ~= nil then        
        -- 
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)            
            gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showFreeSpinView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue  

        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end 
        
        -- 播放提示时播放音效        
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    
    -- 播放排气管动画
    util_spinePlay(self.m_LocalTopView.m_exhaust,"actionframe")
     
    util_spineEndCallFunc(self.m_LocalTopView.m_exhaust, "actionframe", function(  )
        
        util_spinePlay(self.m_LocalTopView.m_exhaust,"idleframe",true)
    end)
       

    return true
end

-- FreeSpinstart
function CodeGameScreenBlazingMotorsMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_custom_enter_fs.mp3")
    
    self.m_LocalTopView.m_JackPotBar:runCsbAction("JackPotToWheel",false,function(  )
        self.m_LocalTopView:findChild("JackpotClip"):setVisible(false)
        self.m_LocalTopView:findChild("totalwon"):setVisible(false)
        self.m_LocalTopView:findChild("totalwon1"):setVisible(false)
        self.m_LocalTopView:findChild("BlazingMotors_Wheel"):setVisible(true)

        -- 显示转盘
        self:showBonusWheelView( effectData )
        
    end)
    
    

end

function CodeGameScreenBlazingMotorsMachine:showFreeSpinOverView()

    if self.exhaustSoundId then
        gLobalSoundManager:stopAudio(self.exhaustSoundId)
        self.exhaustSoundId = nil
    end

   

   performWithDelay(self,function(  )
        gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_over_fs.mp3")

        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
              
            local gameType = nil
            if self.m_runSpinResultData.p_selfMakeData then
                if self.m_runSpinResultData.p_selfMakeData.type then
                    gameType = self.m_runSpinResultData.p_selfMakeData.type
                end
            end
            
            if gameType then 
                if  gameType == self.FreeGameType_RISINGBET then
                    self.m_LocalTopView:runCsbAction("over1")
                else
                    self.m_LocalTopView:runCsbAction("over2")
                end
            end


            performWithDelay(self,function(  )
                self.m_LocalTopView:findChild("JackpotClip"):setVisible(true)
                self.m_LocalTopView:findChild("totalwon"):setVisible(false)
                self.m_LocalTopView:findChild("totalwon1"):setVisible(false)
                self.m_LocalTopView:findChild("BlazingMotors_Wheel"):setVisible(false)  

                

                self.m_LocalTopView.m_JackPotBar:runCsbAction("wheelToJackPot",false,function(  )
                    for i=1,5 do
                        local pos = i - 1
                        self:findChild("LongRunBg_"..pos):setVisible(false)
                    end

                    gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_xihuo.mp3")
                    util_spinePlay(self.m_LocalTopView.m_exhaust,"over",false)
                    self:triggerFreeSpinOverCallFun()
                    self:checkRemoveAllLockWild()
                    self:removeAllWILDSWEEPNode( )
                end)
            end,0.3)
            

                
        
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},517)
   end,2)
   

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBlazingMotorsMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.isInBonus = false
 
    self.m_winSoundsId = nil

    self.m_isLongWildWait = false

    self:checkIsWaitSpin() -- 检测是否延时spin

    self:blazingMotorsReelsWild()
    self:blazingMotorsWildSweep()

    local isWait = self.m_isLongWildWait 
    if isWait then

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    return isWait -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenBlazingMotorsMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenBlazingMotorsMachine:MachineRule_afterNetWorkLineLogicCalculate()

    self.REELSWILD_DataList = {}
    -- 这里作为存储下一次spin时所需要展示的任意一条wild的位置
    if self.m_runSpinResultData.p_selfMakeData then
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType and gameType == self.FreeGameType_REELSWILD then
            local wildColumns = self.m_runSpinResultData.p_selfMakeData.wildColumns
            self.REELSWILD_DataList = wildColumns
        end
    end

    self.WILDSWEEP_DataList = nil
    if self.m_runSpinResultData.p_selfMakeData then
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType and gameType == self.FreeGameType_WILDSWEEP then
            local wildColumns = self.m_runSpinResultData.p_selfMakeData.wildColumns
            self.WILDSWEEP_DataList = wildColumns
        end
    end
   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end


function CodeGameScreenBlazingMotorsMachine:checkAddJackPotEffect( )


    self.m_jackPotTipsList={}
    local jackpotNum = 0
    local maxRow=#self.m_runSpinResultData.p_reelsData
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
            if targSp then
                if targSp.p_symbolType ==self.SYMBOL_BlazingMotors_NORMAL 
                    or targSp.p_symbolType ==self.SYMBOL_BlazingMotors_GOLD then
                        jackpotNum=jackpotNum+1
                        self.m_jackPotTipsList[jackpotNum]=targSp
                end
            end
        end
    end

    local isTriggerRespin = false
    if self:checkIsTriggerRespin( ) then
        isTriggerRespin = true
    end

    if jackpotNum<3 or isTriggerRespin  then
        self.m_jackPotTipsList=nil
    else

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BLAZINGMOTORS_BlazingMotors_JACKPOT_EFFECT


    end
end

function CodeGameScreenBlazingMotorsMachine:checkAddLockWild( )


    if self.m_runSpinResultData.p_selfMakeData then
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType and gameType == self.FreeGameType_LOCKWILD then
            local lockWilds = self.m_runSpinResultData.p_selfMakeData.lockWilds
            
            if lockWilds  then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.BLAZINGMOTORS_LOCK_WILD_EFFECT
            end

        end
    end

    

end


function CodeGameScreenBlazingMotorsMachine:checkAddRisingBet( )
    -- body
    
    if self.m_runSpinResultData.p_selfMakeData then
        
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType and gameType == self.FreeGameType_RISINGBET then
            local risingMultiple = self.m_runSpinResultData.p_selfMakeData.risingMultiple
            
            if risingMultiple then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.BLAZINGMOTORS_RISING_BET_EFFECT
            end

        end
    end

    
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBlazingMotorsMachine:addSelfEffect()

    if self:getCurrSpinMode() == RESPIN_MODE then 
        return
    end

    -- 检测是否添加jackPot动画
    self:checkAddJackPotEffect()

    -- 检测是否添加LockWild玩法
    self:checkAddLockWild()

    -- 检测是否添加RisingBet玩法
    self:checkAddRisingBet()


end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBlazingMotorsMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.BLAZINGMOTORS_BlazingMotors_JACKPOT_EFFECT then
        self:blazingMotorsBlazingMotorsJackPotAct(effectData)
    elseif effectData.p_selfEffectType == self.BLAZINGMOTORS_LOCK_WILD_EFFECT then
        self:blazingMotorsLockWild(effectData)

    elseif effectData.p_selfEffectType == self.BLAZINGMOTORS_RISING_BET_EFFECT then 
        self:blazingMotorsRisingBet(effectData)
    end

    
	return true
end

function CodeGameScreenBlazingMotorsMachine:flySymblos(startPos,endPos,func,csbPath,scale,scale2,countNum,onTime)
    local flyNode = cc.Node:create()
    -- flyNode:setOpacity()
    self:findChild("root1"):addChild(flyNode,30000) -- 是否添加在最上层
    local time = 0.02
    if onTime then
        time = 0.05
    end
    local count = countNum or 5
    local flyTime = 0.5

    if onTime then
        flyTime = 0.2
    end

    for i=1,count do
        self:runFlySymblosAction(flyNode,time*i,flyTime,startPos,endPos,i,csbPath,scale,scale2,onTime)
    end
    performWithDelay(flyNode,function()
        if func then
            func()
        end
        flyNode:removeFromParent()
    end,flyTime+time*count)
end


function CodeGameScreenBlazingMotorsMachine:runFlySymblosAction(flyNode,time,flyTime,startPos,endPos,index,csbPath,scale,scale2,onTime)
    local actionList = {}
    local opacityList = {185,145,105,65,25,1,1,1,1,1}

    if onTime then
        opacityList = {255,145,105,65,25,1,1,1,1,1}
    else
        opacityList = {185,145,105,65,25,1,1,1,1,1} -- {1,25,65,105,145,185} -- {185,165,145,125,105,85,65,45,25,15,10,5,1,1,1}
    end
    actionList[#actionList + 1] = cc.DelayTime:create(time)


    local node,csbAct=util_csbCreate(csbPath)
    util_csbPlayForKey(csbAct,"idlefly")
    node:setScale(scale)
    -- node:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(node,true)
    node:setOpacity(opacityList[index])
    actionList[#actionList + 1] = cc.CallFunc:create(function()
    --     node:setVisible(true)
          node:runAction(cc.ScaleTo:create(flyTime,scale2))
    end)
    flyNode:addChild(node,6-index)
    node:setLocalZOrder(100 - index)
    
    node:setPosition(startPos)
    local k =0
    if startPos.x <= display.width/2 then
        k = 1
    else
        k = -1
    end

    if onTime then
        local onePos = cc.p(startPos.x + (50 * k) ,startPos.y - 100)
         actionList[#actionList + 1] = cc.MoveTo:create(flyTime * 1/4, cc.p(onePos))
         actionList[#actionList + 1] = cc.MoveTo:create(flyTime* 3/4, cc.p(endPos))
    else
        local bezier1 = {        
            cc.p(startPos.x + 200 , (startPos.y + endPos.y)*1/4),
            cc.p(startPos.x + 100 , (startPos.y + endPos.y )*3/4),            
            cc.p( endPos.x ,endPos.y)
        }

        actionList[#actionList + 1] = cc.BezierTo:create(flyTime,bezier1)
        
    end

    
    --actionList[#actionList + 1] = cc.DelayTime:create(flyTime)
    
    actionList[#actionList + 1] = cc.CallFunc:create(function()
          node:setLocalZOrder(100 - index)
    end)
    
    node:runAction(cc.Sequence:create(actionList))
end

-- RisingBet 玩法
function CodeGameScreenBlazingMotorsMachine:risingAction(startPos,oneEndPos,endPos,callfunc,maxDealyTime)


    local risingName = "Socre_BlazingMotors_Rising" -- self:MachineRule_GetSelfCCBName(self.SYMBOL_RISING)

    
    local oneCallFunc = function(  )
        self.m_BlazingMotorsRisingIdelView:setVisible(true)
        self.m_BlazingMotorsRisingIdelView:showAnction()
        -- 播放中间动画
        performWithDelay(self,function(  )

            self.m_BlazingMotorsRisingIdelView:setVisible(false)

            local twofunc = function(  )

                self.m_LocalTopView.m_TopViewRisingIdel:setVisible(true)
                self.m_LocalTopView.m_TopViewRisingIdel:showOverAnction()
                
                -- 播放中间动画
                performWithDelay(self,function(  )
                    self.m_LocalTopView.m_TopViewRisingIdel:setVisible(false)
                    if  callfunc then
                        callfunc()
                    end

                end,self.m_LocalTopView.m_TopViewRisingIdel:getOverActTime())
                
            end
            
            
            self:flySymblos(oneEndPos,endPos,twofunc,risingName..".csb",1,0.2,5)
        
        end,self.m_BlazingMotorsRisingIdelView:getActTime())
    end


    self:flySymblos(startPos,oneEndPos,oneCallFunc,risingName..".csb",0.1,1,5,true)
  

end

-- RisingBet 玩法
function CodeGameScreenBlazingMotorsMachine:blazingMotorsRisingBet(effectData)

    if self.m_runSpinResultData.p_selfMakeData then
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType and gameType == self.FreeGameType_RISINGBET then
            local risingMultiple = self.m_runSpinResultData.p_selfMakeData.risingMultiple
            
            local risingCount =  self.m_runSpinResultData.p_selfMakeData.risings
            if risingCount and #risingCount > 0 then
                 --  播放飞翔 rising 

                 local risingNodePos = cc.p(self.m_LocalTopView:findChild("risingNode"):getPosition())

                 local endPos = self.m_LocalTopView:findChild("risingNode"):getParent():convertToWorldSpace(risingNodePos)
                 endPos = self:findChild("root1"):convertToNodeSpace(endPos)
                 local oneEndPos = cc.p(self:findChild("risingNodeOne"):getPosition())

                 local showIdleTime = self.m_BlazingMotorsRisingIdelView:getActTime()
                 local delayTime = 1 + 0.45+ 0.65 + showIdleTime --  等待时间 飞行时间 播放中间动画时间
                 local maxNum = #risingCount
                 local nowNum = 1
                 for k,v in pairs(risingCount) do
                    local index = v
                    local startPos = self:getThreeReelsTarSpPos(index)
                    
                    local courNum = nowNum
                     performWithDelay(self,function(  )

                        gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_rising.mp3")

                        local callfunc = function(  )
                            if risingMultiple then
                                local betNum = risingMultiple - maxNum  + courNum
                                -- 更新当前的倍数
                                self.m_LocalTopView:findChild("m_lb_num_0"):setString(tostring(betNum).."x")
                
                    
                            end
                        end

                        if courNum >= maxNum then
                            callfunc = function(  )
                                if risingMultiple then
                                    -- 更新当前的倍数
                                    self.m_LocalTopView:findChild("m_lb_num_0"):setString(tostring(risingMultiple) .."x")
                                end
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        end

                        self:risingAction(startPos,oneEndPos,endPos,callfunc,delayTime)

                     end,delayTime* (k -1 ))

                     nowNum = nowNum +1
                 end

                 -- 第二轮动画

            else

                effectData.p_isPlay = true
                self:playGameEffect()
            end
            
    
        end
    
        
    end

   

end
-- 锁定wild玩法
function CodeGameScreenBlazingMotorsMachine:blazingMotorsLockWild(effectData)

    local isChange = false
    if self.m_runSpinResultData.p_selfMakeData then
        local gameType = self.m_runSpinResultData.p_selfMakeData.type
        if gameType and gameType == self.FreeGameType_LOCKWILD then
        
            local lockWilds = self.m_runSpinResultData.p_selfMakeData.lockWilds

            if lockWilds and #lockWilds > 0 then

                for k, v in pairs(lockWilds) do
                    local pos = tonumber(v)
                    local fixPos = self:getRowAndColByPos(pos)
                    local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX) 

                    if not self:checkIs_InLOCKWILD_NodeList( pos) then
                        if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then

                            targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_Lock_WILD),self.SYMBOL_Lock_WILD)
                            
                            gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_LockWild.mp3")
                            
                            isChange = true
                            targSp:runAnim("buling",false,function(  )
                                targSp:runAnim("idleframe")
                            end)
        
                            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                            local linePos = {}
                            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                            targSp.m_bInLine = true
                            targSp:setLinePos(linePos)
                            table.insert( self.LOCKWILD_NodeList,targSp)
                        end
                    end
                    
                end
            end

        
        end
    end

    

    if isChange then
        performWithDelay(self,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end,1)

    else

        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

-- BlazingMotorsJackPot玩法 
function CodeGameScreenBlazingMotorsMachine:blazingMotorsBlazingMotorsJackPotAct(effectData)
    local function clearLine()
        self:clearWinLineEffect()

        if self.m_isShowMaskLayer == true then
            self:resetMaskLayerNodes()
            -- 隐藏所有的遮罩 layer
            
        end
    end

    if self.m_jackPotTipsList and #self.m_jackPotTipsList>0 then
        local count=#self.m_jackPotTipsList
        if count>9 then
            count=9
        end

        --jackpot加钱逻辑
        local index=10-count
        local score = self:BaseMania_getJackpotScore(index)
        clearLine()

        if count >= 3 then
            -- gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_jackPot_Tip.mp3")
            for _,targSp in ipairs(self.m_jackPotTipsList) do
                targSp:runAnim("actionframe",true)
            end
        end
        
        self.m_jackPotTipsList=nil
 
            if count>=5 then
                local jpScore = util_formatCoins(score,50)

                self.m_LocalTopView.m_JackPotBar:showjackPotAction(count,true )

                gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_Bonusrapid_win.mp3")
        

                performWithDelay(self,function(  )
                    self:showJackPot(jpScore,index,function()

                        -- 通知UI钱更新
                        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                            -- freeSpin下特殊玩法的算钱逻辑
                            if #self.m_vecGetLineInfo == 0  then
                                print("没有赢钱线，得手动加钱")
                                
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})  
                            else
                                print("在算线钱的时候就已经把特殊玩法赢的钱加到总钱了，所以不用更新钱")
                                
                            end
            
                        else
                            if #self.m_vecGetLineInfo == 0 then
    
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})
            
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                            end
    
                        end
    
                        self.m_LocalTopView.m_JackPotBar:showjackPotAction(count,false )
    
                        effectData.p_isPlay = true
                        self:playGameEffect()
    
                    end)
                end,4)

                

               
            else

                effectData.p_isPlay = true
                self:playGameEffect()
            end
        
            
            
    end

end

function CodeGameScreenBlazingMotorsMachine:showJackPot(coins,num,func)
    
    gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_wonJackPot.mp3")
            
    local view=util_createView("CodeBlazingMotorsSrc.BlazingMotorsJackPotWinView")
    view:initViewData(coins,num,func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
end

function CodeGameScreenBlazingMotorsMachine:changeAllReelsWildTag( )
    for k,v in pairs(self.REELSWILD_NodeList) do
        if v then
            local sp = v

            sp:runAnim("over",false,function(  )
                sp:setVisible(false)

            end)

            sp:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)


        end
    end


    self.REELSWILD_NodeList = {}

end

-- 随机几列出现wild 玩法
function CodeGameScreenBlazingMotorsMachine:blazingMotorsReelsWild()
    
    self:changeAllReelsWildTag( )

    if self.m_bProduceSlots_InFreeSpin then -- freespin下才生效
        local indexList = {10,11,12,13,14}
        if self.m_runSpinResultData.p_selfMakeData then
            local gameType = self.m_runSpinResultData.p_selfMakeData.type
            if gameType and gameType == self.FreeGameType_REELSWILD then
                local wildColumns = self.REELSWILD_DataList -- 这里使用的是上一轮数据的缓存，因为点击了spin后网络数据还没返回
                
                if wildColumns and #wildColumns > 0 then

                    -- self.m_isLongWildWait = true

                    for k,v in pairs(wildColumns) do  
                        local Colindex = v + 1 
                        local posIndex = indexList[Colindex]
                        local fixPos = self:getRowAndColByPos(posIndex)
                        local bigWild = self:getSlotNodeWithPosAndType(self.SYMBOL_LONG_WILD,fixPos.iX,fixPos.iY)
                        bigWild.m_bInLine = false

                        -- 先去掉下方小块的连线动画
                        local linePos = {}
                        
                        -- 给大块填上连线动画
                        for lineRowIndex = 3, 1,-1 do
                            linePos[#linePos + 1] = {
                                iX = lineRowIndex,
                                iY = fixPos.iY
                            }
                        end
                        bigWild.p_slotNodeH = self.m_SlotNodeH 

                        bigWild.m_symbolTag = SYMBOL_FIX_NODE_TAG
                        bigWild.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                        bigWild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        
                        bigWild:setLinePos(linePos)
        
                        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                        
                        local targSpPos = cc.p(self:getThreeReelsTarSpPos(posIndex))

                        local reelParent = self:getReelParent(fixPos.iY)
                        
                        -- local nodePos = self.m_root:convertToWorldSpace(targSpPos)
                        -- nodePos = reelParent:convertToNodeSpace(nodePos)

                        self.m_clipParent:addChild(bigWild,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_NODE_TAG)
                        bigWild:setPosition(targSpPos)
                        

                        bigWild:setVisible(false)
                        scheduler.performWithDelayGlobal(function()
                            table.insert( self.REELSWILD_NodeList, bigWild )
                            bigWild:setVisible(true)
                            bigWild:runAnim("chuxian",false,function(  )
                                bigWild:runAnim("idle",true)
                            end)
                        end,1.1, self:getModuleName()) 
                        

                    end
                

                end

            end

        end
    end

    
    

end

function CodeGameScreenBlazingMotorsMachine:checkIsWaitSpin( )
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_runSpinResultData.p_selfMakeData then
            local gameType = self.m_runSpinResultData.p_selfMakeData.type
            if gameType and gameType == self.FreeGameType_WILDSWEEP then
                local wildColumns = self.WILDSWEEP_DataList -- self.m_runSpinResultData.p_selfMakeData.wildColumns
                if wildColumns == nil  then
                    wildColumns = {4} -- 因为触发freespin时服务器未推送数据，第一次肯定是 4」
                end
    
                if wildColumns then
 
                    self.m_isLongWildWait = true


                end
    
            end
    
        end
    end

    if self.m_bProduceSlots_InFreeSpin then -- freespin下才生效
        local indexList = {10,11,12,13,14}
        if self.m_runSpinResultData.p_selfMakeData then
            local gameType = self.m_runSpinResultData.p_selfMakeData.type
            if gameType and gameType == self.FreeGameType_REELSWILD then
                local wildColumns = self.REELSWILD_DataList -- 这里使用的是上一轮数据的缓存，因为点击了spin后网络数据还没返回
                
                if wildColumns and #wildColumns > 0 then

                    self.m_isLongWildWait = true

                end

            end

        end
    end



    if self.m_isLongWildWait == true then
        local waitTime = 0
        if #self.WILDSWEEP_NodeList > 0 or #self.REELSWILD_NodeList > 0  then
            waitTime = 0.9
        end 
        performWithDelay(self,function(  )
            self:setGameSpinStage( IDLE )
            self:callSpinBtn()
        end,waitTime)
    end
    
    
end

function CodeGameScreenBlazingMotorsMachine:removeAllWILDSWEEPNode(isremove )

    for k,v in pairs(self.WILDSWEEP_NodeList) do
        if v then
            local sp = v

            if isremove then
                sp:runAnim("over",false,function(  )
                    sp:setVisible(false)
 
                end)
            end
            sp:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)


        end
    end

    if isremove then
        self.WILDSWEEP_NodeList = {}
    end
      
end

-- 两列 wild 移动 玩法
function CodeGameScreenBlazingMotorsMachine:blazingMotorsWildSweep()

        self:removeAllWILDSWEEPNode( true )

    
        local indexList = {10,11,12,13,14}
    
        if self.m_bProduceSlots_InFreeSpin then
            if self.m_runSpinResultData.p_selfMakeData then
                local gameType = self.m_runSpinResultData.p_selfMakeData.type
                if gameType and gameType == self.FreeGameType_WILDSWEEP then
                    local wildColumns = self.WILDSWEEP_DataList -- self.m_runSpinResultData.p_selfMakeData.wildColumns
                    if wildColumns == nil  then
                        wildColumns = {4} -- 因为触发freespin时服务器未推送数据，第一次肯定是 4」
                    end
        
                    if wildColumns then
                        for k,v in pairs(wildColumns) do  
                            local colIndex = v + 1
                            if colIndex then


                                local Colindex = v + 1 
                                local posIndex = indexList[Colindex]
                                local fixPos = self:getRowAndColByPos(posIndex)
                                local bigWild = self:getSlotNodeWithPosAndType(self.SYMBOL_LONG_WILD,fixPos.iX,fixPos.iY)
                                bigWild.m_bInLine = true


                                -- 先去掉下方小块的连线动画
                                local linePos = {}
                                
                                -- 给大块填上连线动画
                                for lineRowIndex = 3, 1,-1 do
                                    linePos[#linePos + 1] = {
                                        iX = lineRowIndex,
                                        iY = fixPos.iY
                                    }
                                end
                                bigWild.p_slotNodeH = self.m_SlotNodeH 

                                bigWild.m_symbolTag = SYMBOL_FIX_NODE_TAG
                                bigWild.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                                bigWild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                
                                bigWild:setLinePos(linePos)
                
                                local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                                
                                local targSpPos = cc.p(self:getThreeReelsTarSpPos(posIndex)) 

                                local reelParent = self:getReelParent(fixPos.iY)
                                
                                local nodePos = targSpPos -- self.m_root:convertToWorldSpace(targSpPos)
                                -- nodePos = reelParent:convertToNodeSpace(nodePos)
                                self.m_clipParent:addChild(bigWild,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_NODE_TAG)
                                bigWild:setPosition(nodePos)

                                
                                
                                bigWild:setVisible(false)
                                scheduler.performWithDelayGlobal(function()
                                    table.insert( self.WILDSWEEP_NodeList, bigWild )
                                    bigWild:setVisible(true)
                                    bigWild:runAnim("chuxian",false,function(  )
                                        bigWild:runAnim("idle",true)
                                    end)
                                end,1.1, self:getModuleName()) 
                            end 
                            
        
                        end
        
                    end
        
                end
        
            end
        end
        
       

end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBlazingMotorsMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

-- 创建滚动轮盘
function CodeGameScreenBlazingMotorsMachine:showBonusWheelView( effectData )

    self:resetMusicBg(nil,"BlazingMotorsSounds/music_BlazingMotors_wheel_bg.mp3")

    self.exhaustSoundId =  gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_penhuo.mp3",true)

    local wheel = {{0,0},{1,0},{2,0},{3,0}}
    local bonusView = util_createView("CodeBlazingMotorsSrc.BlazingMotorsWheelView", wheel)
    --传入信号池
    bonusView:setNodePoolFunc(
        function(symbolType)
            return self:getSlotNodeBySymbolType(symbolType)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end)

    bonusView:initFeatureUI()
    bonusView:setOverCallBackFun(function()
        
        gLobalSoundManager:setBackgroundMusicVolume(1)

        local childs = nil
        if bonusView.m_FeatureNode and bonusView.m_FeatureNode.m_symbolNodeList then
            childs = bonusView.m_FeatureNode.m_symbolNodeList
            for k,v in pairs(childs) do
                if v.isEndNode then
                    v:runAnim("idleframe")
                end
            end
        end

        
        performWithDelay(self,function(  )
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                bonusView:runCsbAction("over",false,function(  )
                    bonusView:removeFromParent()
                    self.m_bonusWheelView = nil
    
                    for i=1,5 do
                        local pos = i - 1
                        self:findChild("LongRunBg_"..pos):setVisible(true)
                    end
    
                    self.m_LocalTopView:findChild("JackpotClip"):setVisible(false)
                    self.m_LocalTopView:findChild("BlazingMotors_Wheel"):setVisible(false)
                    local gameType = self.m_runSpinResultData.p_selfMakeData.type
                    if gameType then 
                        if  gameType == self.FreeGameType_RISINGBET then
                            self.m_LocalTopView:findChild("totalwon"):setVisible(true)
                            self.m_LocalTopView:findChild("totalwon1"):setVisible(false)
    
                            -- 更新当前的倍数
                            self.m_LocalTopView:findChild("m_lb_num_0"):setString("1x")
    
    
                        else
                            self.m_LocalTopView:findChild("totalwon"):setVisible(false)
                            self.m_LocalTopView:findChild("totalwon1"):setVisible(true)
                        end
                    end
    
                    
    
                    local gameType = self.m_runSpinResultData.p_selfMakeData.type
                    if gameType then 
                        if  gameType == self.FreeGameType_RISINGBET then
                            self.m_LocalTopView:runCsbAction("chuxian1")
                    
                        else
                            self.m_LocalTopView:runCsbAction("chuxian2")
                        end
                    end
    
                    performWithDelay(self,function(  )
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end,0.3)
    
                end)
    
                
    
            end,true)
        end,0.5)
        
            
    end)
    self.m_LocalTopView:findChild("BlazingMotors_Wheel"):addChild(bonusView)
    self.m_bonusWheelView = bonusView

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_bonusWheelView.getRotateBackScaleFlag = function(  ) return false end
    end


    
    -- self.m_bonusWheelView:setVisible(false)

    local press =  util_createView("CodeBlazingMotorsSrc.BlazingMotorsPreesSpin")
    self.m_LocalTopView:findChild("press_node"):setLocalZOrder(1000)
    self.m_LocalTopView:findChild("press_node"):addChild(press,1000)

    if globalData.slotRunData.machineData.p_portraitFlag then
        press.getRotateBackScaleFlag = function(  ) return false end
    end

    press:setVisible(false)
    press:findChild("BlazingMotors_Press"):setVisible(false) 
    performWithDelay(self,function(  )
        press:setVisible(true)
        press:runCsbAction("buing",false,function(  )
            press:findChild("BlazingMotors_Press"):setVisible(true) 
            press:runCsbAction("actionframe",true)
        end)
        
    end,1)
    
    

    press:initCallFunc(function(  )

        -- self.m_bonusWheelView:setVisible(true)
         -- 结束类型
        local endData = {}
        local endType = 0
        if self.m_runSpinResultData.p_selfMakeData then
            if self.m_runSpinResultData.p_selfMakeData.type then
                endType = self.m_runSpinResultData.p_selfMakeData.type
            end
        end
        endData.type = endType
        endData.score = 3
        if self.m_bonusWheelView then

            gLobalSoundManager:setBackgroundMusicVolume(0.1)

            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            self.m_bonusWheelView:setEndValue(endData)
            self.m_bonusWheelView:beginMove()
        end
        
    end)

   
end

function CodeGameScreenBlazingMotorsMachine:showFreeSpinStart(num,func,isAuto)

    local function newFunc()
        self:resetMusicBg(true)  
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local view= util_createView("CodeBlazingMotorsSrc.BlazingMotorsFreespinStartView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
    
    local gameType = self.m_runSpinResultData.p_selfMakeData.type
    if gameType then 
        if  gameType == self.FreeGameType_LOCKWILD then
            view:findChild("lockWILD"):setVisible(true)
            view:findChild("WildSweep"):setVisible(false)
            view:findChild("WildColumn"):setVisible(false)
            view:findChild("rising"):setVisible(false)

            gLobalSoundManager:playSound("BlazingMotorsSounds/BlazingMotors_scatter_Lock.mp3")

            view:runCsbAction("auto",false,function(  )
                newFunc()
                view:removeFromParent()
            end)
        elseif gameType == self.FreeGameType_REELSWILD then  
            view:findChild("lockWILD"):setVisible(false)
            view:findChild("WildSweep"):setVisible(false)
            view:findChild("WildColumn"):setVisible(true)
            view:findChild("rising"):setVisible(false)
            gLobalSoundManager:playSound("BlazingMotorsSounds/BlazingMotors_scatter_col.mp3")

            view:runCsbAction("auto3",false,function(  )
                newFunc()
                view:removeFromParent()
            end)
        elseif gameType == self.FreeGameType_RISINGBET then 
            view:findChild("lockWILD"):setVisible(false)
            view:findChild("WildSweep"):setVisible(false)
            view:findChild("WildColumn"):setVisible(false)
            view:findChild("rising"):setVisible(true)
            gLobalSoundManager:playSound("BlazingMotorsSounds/BlazingMotors_scatter_rising.mp3")

            view:runCsbAction("auto4",false,function(  )
                newFunc()
                view:removeFromParent()
            end)
        elseif gameType == self.FreeGameType_WILDSWEEP then  
            view:findChild("lockWILD"):setVisible(false)
            view:findChild("WildSweep"):setVisible(true)
            view:findChild("WildColumn"):setVisible(false)
            view:findChild("rising"):setVisible(false)
            gLobalSoundManager:playSound("BlazingMotorsSounds/BlazingMotors_scatter_sweep.mp3")

            view:runCsbAction("auto2",false,function(  )
                newFunc()
                view:removeFromParent()
            end)
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
function CodeGameScreenBlazingMotorsMachine:getThreeReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenBlazingMotorsMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end


---
-- 获取随机信号，  
-- @param col 列索引
function CodeGameScreenBlazingMotorsMachine:MachineRule_getRandomSymbol(col)

    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local FsReelDatasIndex = 0
        if self.m_runSpinResultData.p_selfMakeData then -- 添加这段代码是为了加上两个假滚滚轮
            local typeNum = self.m_runSpinResultData.p_selfMakeData.type
            if typeNum  then
                if typeNum == self.FreeGameType_LOCKWILD then
                    FsReelDatasIndex = typeNum 
                elseif  typeNum == self.FreeGameType_REELSWILD then
                    FsReelDatasIndex = typeNum 
                elseif  typeNum == self.FreeGameType_RISINGBET then
                    FsReelDatasIndex = typeNum 
                elseif  typeNum == self.FreeGameType_WILDSWEEP then

                    FsReelDatasIndex = typeNum 
                end
                
            end
        end

        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(FsReelDatasIndex,col)
        if reelDatas == nil then
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
        end
    
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        reelDatas = self:getRespinRunningData(col)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
    end

    local totalCount = #reelDatas
    local randomType = reelDatas[xcyy.SlotsUtil:getArc4Random() % totalCount + 1]
    
    return randomType
end

-- 转轮开始滚动函数
function CodeGameScreenBlazingMotorsMachine:beginReel()

     -- 固定某个小块
     if self:getCurrSpinMode() == RESPIN_MODE  then
        if self.m_runSpinResultData.p_selfMakeData then
            local locks = self.m_runSpinResultData.p_selfMakeData.locks
            if locks then
                for k,v in pairs(locks) do
                    local iCol = v + 1
                    self:findHitLockSymbol(iCol)                 
                end
            end
            
        end
    else
        -- 重置小块为不固定状态
        self:restHitLockSymbolTag( )
    end


    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local FsReelDatasIndex = 0
        if self.m_runSpinResultData.p_selfMakeData then -- 添加这段代码是为了加上两个假滚滚轮
            local typeNum = self.m_runSpinResultData.p_selfMakeData.type
            if typeNum  then
                if typeNum == self.FreeGameType_LOCKWILD then
                    FsReelDatasIndex = 1 
                elseif  typeNum == self.FreeGameType_RISINGBET then
                    FsReelDatasIndex = 2 
                elseif  typeNum == self.FreeGameType_WILDSWEEP then
                    FsReelDatasIndex = 3 
                end
                
            end
        end
        self.m_fsReelDataIndex = FsReelDatasIndex
    end
    
    BaseSlotoManiaMachine.beginReel(self)

    -- 判断是否有某列不应该滚动
    
    if self:getCurrSpinMode() == RESPIN_MODE  then

        if self.m_runSpinResultData.p_selfMakeData then
            local locks = self.m_runSpinResultData.p_selfMakeData.locks
            if locks then
                for k,v in pairs(locks) do
                    local iCol = v + 1

                    self:setOneReelsRunStates(iCol,false )
                    
                end
            end
            
        end
    else

        -- 如果不是respin就重置
        for iCol=1,self.m_iReelColumnNum do
            self:setOneReelsRunStates(iCol,true )
        end
        
    end


    -- FreeSpin玩法 第一次多滚
    if self.m_isLongWildWait then
          
        --添加滚轴停止等待时间,此处的时间只是为了，确定延时逻辑，并不是就停1秒
        self:setWaitChangeReelTime(5)
            
    end

end

function CodeGameScreenBlazingMotorsMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        reelDatas = self:getRespinRunningData(parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end

function CodeGameScreenBlazingMotorsMachine:checkIsTriggerRespin( )
   local isTrigger  = false
   local features  = self.m_runSpinResultData.p_features
   if features and type(features) == "table" then
        for k,v in pairs(features) do
            if v == RESPIN_MODE then
                isTrigger  = true

                break
            end
        end
   end

   return isTrigger
   
end

function CodeGameScreenBlazingMotorsMachine:checkNetLockArray(col )

    local notIn = true

    local locks = self.m_runSpinResultData.p_selfMakeData.locks

    for k,v in pairs(locks) do
        local iCol = v +1
        if col == iCol then
            notIn = false
            break
        end
    end

    return notIn

end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function CodeGameScreenBlazingMotorsMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_resTopTypes
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
     
        elseif self:getCurrSpinMode() == RESPIN_MODE and self.m_runSpinResultData.p_reSpinCurCount > 0 then
            --此时取信号 noral
            reelDatas = self:getRespinRunningData(parentData.cloumnIndex)
            if not self:checkNetLockArray(parentData.cloumnIndex ) then
                symbolType = self.SYMBOL_BlazingMotors_NULL 
                return symbolType
            end
            
            
        elseif self:getCurrSpinMode() == RESPIN_MODE and self.m_runSpinResultData.p_reSpinCurCount == 0 then
             --此时取普通信号
            parentData.reelDatas = self:getRespinRunningData(parentData.cloumnIndex) -- self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
            
            if not self:checkNetLockArray(parentData.cloumnIndex ) then
                symbolType = self.SYMBOL_BlazingMotors_NULL 
                return symbolType
            end
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        -- local reelIndex = parentData.beginReelIndex
        -- symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)

        if self:checkIsTriggerRespin( ) then
            if not self:checkNetLockArray(parentData.cloumnIndex ) then
                symbolType = self.SYMBOL_BlazingMotors_NULL 
            end
        end
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end

-- 给respin小块进行赋值
function CodeGameScreenBlazingMotorsMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    if symbolNode.p_symbolType == nil then
        print("ppkiohijlp")
    end
    if symbolNode and symbolNode.p_symbolType then
        if not self:isFixSymbol(symbolNode.p_symbolType) then
            symbolNode:runAnim("animation0")
        end
        
    end
    


end

function CodeGameScreenBlazingMotorsMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if self:getCurrSpinMode() == RESPIN_MODE then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
        
    end
    

    return reelNode
end

-- 是不是 BlazingMotors 小块
function CodeGameScreenBlazingMotorsMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BlazingMotors_NORMAL
        or symbolType == self.SYMBOL_BlazingMotors_GOLD    then   
        return true
    end
    return false
end

---
-- 触发respin 玩法
--
function CodeGameScreenBlazingMotorsMachine:showEffect_Respin(effectData)

    performWithDelay(self,function(  )
        -- 停掉背景音乐
        self:clearCurMusicBg()
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "respin")
        end
        local removeMaskAndLine = function()
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            self:resetMaskLayerNodes()
            
            -- 处理特殊信号
            local childs = self.m_lineSlotNodes
            for i = 1, #childs do
                -- if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE then
                --将该节点放在 .m_clipParent
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(),childs[i]:getPositionY()))
                local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                childs[i]:removeFromParent()
                childs[i]:setPosition(cc.p(pos.x, pos.y))
                self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
                -- end
            end
        end

        if  self:getLastWinCoin() > 0 then  -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝

            --scheduler.performWithDelayGlobal(function()
                removeMaskAndLine()
                self:showRespinView(effectData) 
            --end,1,self:getModuleName())

        else 
            self:showRespinView(effectData)
        end
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin,self.m_iOnceSpinLastWin)
    end,2)
    
    return true

end


function CodeGameScreenBlazingMotorsMachine:showRespinView(effectData)
    
        --触发respin
        --先播放动画 再进入respin

        gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_trigger_respin.mp3")
            

        self:clearCurMusicBg()
         
        self:setCurrSpinMode( RESPIN_MODE )
        self.m_specialReels = false

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})


        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum , 1, -1 do
                local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp  then
                    if self:isFixSymbol(targSp.p_symbolType) then
                       
                        targSp:runAnim("idleframe")
                    end
    
                end
            end
        end

        self:clearWinLineEffect()

        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)


        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_guochang_respinstart.mp3")
            
            self.m_BlazingMotorsDoorView_1:setVisible(true)
            self.m_BlazingMotorsDoorView_2:setVisible(true)
            self.m_BlazingMotorsDoorView_1:runCsbAction("auto")
            self.m_BlazingMotorsDoorView_2:runCsbAction("auto")
            local time = util_csbGetAnimTimes(self.m_BlazingMotorsDoorView_2.m_csbAct,"appear")
            local time2 = util_csbGetAnimTimes(self.m_BlazingMotorsDoorView_2.m_csbAct,"auto")

            

            performWithDelay(self,function(  )

                self:changeSprToNullSymboll()

            end,time)
            
            performWithDelay(self,function(  )

                self.m_BlazingMotorsDoorView_1:setVisible(false)
                self.m_BlazingMotorsDoorView_2:setVisible(false)

                effectData.p_isPlay = true
                self:playGameEffect()

                self:resetMusicBg()

            end,time2)
        end,2)

        
        


end



--接收到数据开始停止滚动
function CodeGameScreenBlazingMotorsMachine:stopRespinRun()
    print("已经得到了数据")
end

--ReSpin开始改变UI状态
function CodeGameScreenBlazingMotorsMachine:changeReSpinStartUI(respinCount)
   
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"mormaltolink")
end

--ReSpin刷新数量
function CodeGameScreenBlazingMotorsMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
   
    print("dadadad")
end

--ReSpin结算改变UI状态
function CodeGameScreenBlazingMotorsMachine:changeReSpinOverUI()

end

function CodeGameScreenBlazingMotorsMachine:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    self:removeRespinNode()  
    self:clearCurMusicBg()

    self.m_respinJackPotId = 0

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                if self:isFixSymbol(targSp.p_symbolType) then
                    self.m_respinJackPotId = self.m_respinJackPotId + 1
                    targSp:runAnim("actionframe",true)
                end

            end
        end
    end

    self.m_LocalTopView.m_JackPotBar:showjackPotAction(self.m_respinJackPotId,true )

    gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_Bonusrapid_win.mp3")
        
    performWithDelay(self,function(  )
        self:showRespinOverView(effectData)
    end,2)
    

    return true 
end

function CodeGameScreenBlazingMotorsMachine:showRespinOverView(effectData)

    
    gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_tanban_respinover.mp3")
    
    
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()

        gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_guochang_respinover.mp3")

        if self.m_respinJackPotId >= 5 then
            --通知jackpot
            local jpIndex = 10 -  self.m_respinJackPotId
            globalData.jackpotRunData:notifySelfJackpot(self.m_serverWinCoins,jpIndex)
        
        end
        
        self.m_LocalTopView.m_JackPotBar:showjackPotAction(self.m_respinJackPotId,false )

        self.m_BlazingMotorsDoorView_1:setVisible(true)
        self.m_BlazingMotorsDoorView_2:setVisible(true)
        self.m_BlazingMotorsDoorView_1:runCsbAction("auto")
        self.m_BlazingMotorsDoorView_2:runCsbAction("auto")
        local time = util_csbGetAnimTimes(self.m_BlazingMotorsDoorView_2.m_csbAct,"appear")
        local time2 = util_csbGetAnimTimes(self.m_BlazingMotorsDoorView_2.m_csbAct,"auto")

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum , 1, -1 do
                local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp  then
                    if self:isFixSymbol(targSp.p_symbolType) then
                        self.m_respinJackPotId = self.m_respinJackPotId + 1
                        targSp:runAnim("idleframe")
                    end
    
                end
            end
        end
        

        performWithDelay(self,function(  )

            self:changeNullSprToNormalSymboll()

        end,time)

        performWithDelay(self,function(  )

            self.m_BlazingMotorsDoorView_1:setVisible(false)
            self.m_BlazingMotorsDoorView_2:setVisible(false)

            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")

            effectData.p_isPlay = true
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg() 

        end,time2)
        
    end,self.m_respinJackPotId)
    -- gLobalSoundManager:playSound("BlazingMotorsSounds/music_BlazingMotors_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},517)
end

function CodeGameScreenBlazingMotorsMachine:showReSpinOver(coins,func,num)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    ownerlist["m_lb_num"]= num
    return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER,ownerlist,func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end


function CodeGameScreenBlazingMotorsMachine:getRespinRunningData(col,isAllNull)
    local data = nil

    if not isAllNull then
        data = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(col)
    else
        data = globalData.slotRunData.levelConfigData:getNormalFreeSpinRespinCloumnByColumnIndex(col)
    end


    return data
end

-- 设置某列不参与滚动
function CodeGameScreenBlazingMotorsMachine:setOneReelsRunStates(col,isrun )
    if isrun then
        self.m_slotParents[col].isReeling = true
        self.m_slotParents[col].isResActionDone = false

        self.m_dontRunCol = {0,0,0,0,0}
    else
        self.m_dontRunCol[col] = 1

        self.m_slotParents[col].isReeling = false
        self.m_slotParents[col].isResActionDone = true

    end
    

    
end

function CodeGameScreenBlazingMotorsMachine:MachineRule_respinTouchSpinBntCallBack()
    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == RESPIN_MODE then 
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        release_print("STR_TOUCH_SPIN_BTN 触发了 free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        release_print("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            release_print("STR_TOUCH_SPIN_BTN 触发了 normal")
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            release_print("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end 

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN and self.m_isWaitingNetworkData == false then  -- 表明滚动了起来。。
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end

function CodeGameScreenBlazingMotorsMachine:findHitLockSymbol(iCol)

    for iRow = self.m_iReelRowNum , 1, -1 do
        local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if targSp  then -- and self:isFixSymbol(targSp.p_symbolType)
            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

            table.insert( self.LOCKRESPIN_NodeList, targSp ) 
        end
    end

end

function CodeGameScreenBlazingMotorsMachine:restHitLockSymbolTag( )
    for k,v in pairs(self.LOCKRESPIN_NodeList) do
        v:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    end
    self.LOCKRESPIN_NodeList = {}
end


function CodeGameScreenBlazingMotorsMachine:changeNullSprToNormalSymboll( )

    for k,v in pairs(self.LOCKRESPIN_NodeList) do
        local targSp =  v
        if targSp   then
            targSp:runAnim("idleframe")
            -- if not self:isFixSymbol(targSp.p_symbolType) then
            --     local symbolType = math.random( 0, 8 )
            --     targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType),symbolType)
            -- end

        end
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                targSp:runAnim("idleframe")
                -- if not self:isFixSymbol(targSp.p_symbolType) then
                --     local symbolType = math.random( 0, 8 )
                --     targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType),symbolType)
                -- end

            end
        end
    end

    local slotParentDatas = self.m_slotParents
    
    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        local childs = slotParent:getChildren()
        for k,v in pairs(childs) do
            v:runAnim("idleframe")
            -- if v.p_symbolType and  v.p_symbolType == self.SYMBOL_BlazingMotors_NULL then
            --     local symbolType = math.random( 0, 8 )
            --     v:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType),symbolType)
            -- end
        end
    end

end

function CodeGameScreenBlazingMotorsMachine:changeSprToNullSymboll( )
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                if not self:isFixSymbol(targSp.p_symbolType) then
                    -- targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_BlazingMotors_NULL),self.SYMBOL_BlazingMotors_NULL)
                    targSp:runAnim("animation0")
                end

            end
        end
    end

    for iCol = 1, self.m_iReelColumnNum do
        -- 找到长条 隐藏掉
        local childs =  self.m_clipParent:getChildren()
        for k,v in pairs(childs) do
            local sp = v
            if sp.p_symbolType then
                if sp.p_symbolType == self.SYMBOL_BIG_WILD then
                    sp:runAnim("animation0")
                    -- sp:setVisible(false)
                end
            end
        end
        local childs1 = self.m_slotParents[iCol].slotParent:getChildren()
        for k,v in pairs(childs1) do
        local sp1 = v
            if sp1.p_symbolType then
                if sp1.p_symbolType == self.SYMBOL_BIG_WILD then
                    -- sp1:setVisible(false)
                    sp1:runAnim("animation0")
                else
                    if not self:isFixSymbol(sp1.p_symbolType) then
                        sp1:runAnim("animation0")
                    end
                end
            end
        end



    end


    
    
end

-- 去除 jackPot 显示 fiveofkind

function CodeGameScreenBlazingMotorsMachine:lineLogicWinLines( )
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        
        self:compareScatterWinLines(winLines)

        for i=1,#winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo,iconsPos)
            
            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())
            
            if lineInfo.iLineSymbolNum >=5 then
                if not self:isFixSymbol(lineInfo.enumSymbolType) then
                    isFiveOfKind=true
                end
                
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end
local curWinType = 0
---
-- 增加赢钱后的 效果 (respin 不添加)
function CodeGameScreenBlazingMotorsMachine:addLastWinSomeEffect() -- add big win or mega win

    if self:getCurrSpinMode() == RESPIN_MODE then
        return
    end

    if #self.m_vecGetLineInfo == 0 then
        return
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


function CodeGameScreenBlazingMotorsMachine:checkWaitOperaNetWorkData( )
    --存在等待时间延后调用下面代码
    if self.m_waitChangeReelTime and self.m_waitChangeReelTime>0 then
        -- 长wild多滚一会儿
        if self.m_isLongWildWait then

            scheduler.performWithDelayGlobal(function()
                self.m_isLongWildWait = false
                -- 开始继续轮盘滚动停止逻辑
                self.m_waitChangeReelTime=nil
                self:updateNetWorkData()
            
    
            end,2.5, self:getModuleName()) 

            return true
        end

        scheduler.performWithDelayGlobal(function()
            self.m_waitChangeReelTime=nil
            self:updateNetWorkData()
        end, self.m_waitChangeReelTime,self:getModuleName())
        return true
    end
    return false
end

---
-- 根据类型将节点放回到pool里面去
-- @param node 需要放回去的node ，在放回去时该清理的要清理完毕， 以免出现node 已经添加到了parent ，但是去除来后再addChild进去
-- 这里停止的
function CodeGameScreenBlazingMotorsMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)
    self.m_reelNodePool[#self.m_reelNodePool + 1] = node
    node:reset()
    node:stopAllActions()
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenBlazingMotorsMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
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


---
--
function CodeGameScreenBlazingMotorsMachine:callSpinBtn()
    if globalData.GameConfig.checkNormalReel  then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end 
    end
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToAutospinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
            end
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE  then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToFreespinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToFreespinReelRunLen()
            end
        end
    end


    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    self:notifyClearBottomWinCoin()
   
    local betCoin = self:getSpinCostCoins()
    local totalCoin = globalData.userRunData.coinNum
    
    -- freespin时不做钱的计算
    if self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
        --金币不足
        -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
        gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
        -- cxc 2023-12-05 15:57:06 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
        local checkOperaGuidePop = function()
            if tolua.isnull(self) then
                return
            end
            
            local betCoin = self:getSpinCostCoins() or toLongNumber(0)
            local totalCoin = globalData.userRunData.coinNum or 1
            if betCoin <= totalCoin then
                globalData.rateUsData:resetBankruptcyNoPayCount()
                self:showLuckyVedio()
                return
            end

            -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
            globalData.rateUsData:addBankruptcyNoPayCount()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
            if view then
                view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
            else
                self:showLuckyVedio()
            end
        end
        gLobalPushViewControl:setEndCallBack(checkOperaGuidePop)
    
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        end

    else
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
            self:getCurrSpinMode() ~= RESPIN_MODE
         then
            self:callSpinTakeOffBetCoin(betCoin)
            print("callSpinBtn  点击了spin14")
        else
            self.m_spinNextLevel = globalData.userRunData.levelNum
            self.m_spinNextProVal = globalData.userRunData.currLevelExper
            self.m_spinIsUpgrade = false
        end
       
        --统计quest spin次数
        self:staticsQuestSpinData()

        self:spinBtnEnProc()

        self:setGameSpinStage( GAME_MODE_ONE_RUN )

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)

    end
    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end

return CodeGameScreenBlazingMotorsMachine






