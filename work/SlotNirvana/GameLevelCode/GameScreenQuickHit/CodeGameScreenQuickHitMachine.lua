---
-- island li
-- 2019年1月26日
-- CodeGameScreenQuickHitMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenQuickHitMachine = class("CodeGameScreenQuickHitMachine", BaseSlotoManiaMachine)

CodeGameScreenQuickHitMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画 -- 

CodeGameScreenQuickHitMachine.SYMBOL_SCORE_QUICKHIT = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE 
CodeGameScreenQuickHitMachine.SYMBOL_SCORE_CHANGE_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

CodeGameScreenQuickHitMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenQuickHitMachine.Wheel_DOLLAR_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4
CodeGameScreenQuickHitMachine.Wheel_QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5
CodeGameScreenQuickHitMachine.Wheel_FREESPIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6
CodeGameScreenQuickHitMachine.Wheel_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 7

CodeGameScreenQuickHitMachine.Wheel_DOLLAR_WINLINES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 8
CodeGameScreenQuickHitMachine.Wheel_QUICKHIT_JACKPOT_WINLINES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 9

CodeGameScreenQuickHitMachine.m_addSpecialCoins = 0

-- 对应本地从1开始
CodeGameScreenQuickHitMachine.m_WheelType = {"WILD","FREESPIN","DOLLAR","QUICKHIT"}
-- 对应服务器 从零开始
CodeGameScreenQuickHitMachine.m_WILD = 0
CodeGameScreenQuickHitMachine.m_FREESPIN = 1
CodeGameScreenQuickHitMachine.m_DOLLAR = 2
CodeGameScreenQuickHitMachine.m_QUICKHIT = 3

CodeGameScreenQuickHitMachine.m_BigWheelData = {4,3,2,1,4,3,2,1,4,3} -- 大轮盘数据

CodeGameScreenQuickHitMachine.m_WheelData_TRIGGER_WILD     = {20,8,15,10,12,8,12,10,15,8} -- 触发WILD玩法，小轮盘数据（送的FreeSpin次数）
CodeGameScreenQuickHitMachine.m_WheelData_TRIGGER_FREESPIN = {12,8,12,10,15,8,20,8,15,10} -- 触发FREESPIN玩法，小轮盘数据（送的FreeSpin次数）

CodeGameScreenQuickHitMachine.m_WheelData_QUICKHIT = {5,7,6,5,9,6,7,5,6,8} -- 小轮盘数据（送的QUICKHIT次数）
CodeGameScreenQuickHitMachine.m_WheelData_DOLLAR   = {4,15,4,12,5,3,25,3,7,10} -- 小轮盘数据（送的bonus变成wild之后的倍数）
CodeGameScreenQuickHitMachine.m_WheelData_WILD     = {10,5,20,5,15,5,10,5,15,5} -- 小轮盘数据（送的wild个数）
CodeGameScreenQuickHitMachine.m_WheelData_FREESPIN = {5,3,2,3,2,3,2,3,5,2} -- 小轮盘数据（送的倍数数）

CodeGameScreenQuickHitMachine.m_FREESPINWaitTime = 5 -- freespin翻倍的玩法 需要滚轮在轮盘滚动完之后再停止滚动

local FIT_HEIGHT_MAX = 1400
local FIT_HEIGHT_MID = 1300
local FIT_HEIGHT_MIN = 1159
-- 构造函数
function CodeGameScreenQuickHitMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.isInBonus = false

	--init
	self:initGame()
end

function CodeGameScreenQuickHitMachine:initGame()

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
function CodeGameScreenQuickHitMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i <= 1 then
            soundPath = "QuickHitSounds/QuickHit_scatter_1.mp3"
        elseif i > 1 and i <= 2 then
            soundPath = "QuickHitSounds/QuickHit_scatter_2.mp3"
        else
            soundPath = "QuickHitSounds/QuickHit_scatter_3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenQuickHitMachine:initUI()

    self:findChild("sp_reel_3!"):setVisible(false) 



    -- self.m_Wheelbgtexiao = util_spineCreate("Socre_QuickHit_Wheelbgtexiao", true,true) 
    -- self:findChild("Node_Zhuanlun"):addChild(self.m_Wheelbgtexiao)
    -- -- util_spinePlay(self.m_Wheelbgtexiao, "bgidle", true)

    self.m_QuickHitBGAction = util_createView("CodeQuickHitSrc.QuickHitBGAction")
    self:findChild("Node_actBgAction"):addChild(self.m_QuickHitBGAction)
    self.m_QuickHitBGAction:runSelfCsbAction("idle",true)
    self.m_QuickHitBGAction:setVisible(false)


    self.m_bonus_Tip_View = util_createView("CodeQuickHitSrc.QuickHitBonusTip")
    self:findChild("Node_bonus_wheel"):addChild(self.m_bonus_Tip_View)
    -- self:findChild("Node_bonus_wheel"):setVisible(false)
    self.m_jackPotBar = util_createView("CodeQuickHitSrc.QuickHitJackPotLayer",self)
    self:findChild("Node_Jackpot"):addChild(self.m_jackPotBar)
    -- self:findChild("Node_Jackpot"):setVisible(false)
    self.m_wonBonusTimes = util_createView("CodeQuickHitSrc.QuickHitTimsBar")
    self:findChild("Node_freespinbar"):addChild(self.m_wonBonusTimes)
    -- util_setCsbVisible(self.m_wonBonusTimes,false)
    self:initFreeSpinBar()
    self.m_baseFreeSpinBar = self.m_wonBonusTimes
    
    local WheelData = {}
    WheelData.m_BigWheelData = self.m_BigWheelData
    self.m_WheelView = util_createView("CodeQuickHitSrc.QuickHitWheelView",WheelData)
    self.m_WheelView:initMachine(self)
    self:findChild("Node_Zhuanlun"):addChild(self.m_WheelView)
    -- self:findChild("Node_Zhuanlun"):setVisible(false)
    self:SlowWheelRun()

    self:checkWheelMaskShow( )

    self.m_TopView = util_createView("CodeQuickHitSrc.QuickHitTopView")
    self.m_TopView:initMachine(self)
    self:findChild("Node_Top"):addChild(self.m_TopView)
    self:findChild("Node_Top"):setLocalZOrder(-1)
    -- self:findChild("Node_Top"):setVisible(false)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

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
        local soundName = "QuickHitSounds/music_QuickHit_last_win_"..soundIndex..".mp3"

        local startVolume = 0.4
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            startVolume = 1
        else
            startVolume = 0.4
        end
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,4,startVolume,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenQuickHitMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("Node_bg"):setLocalZOrder(-100)
    self:findChild("Node_bg"):addChild(gameBg)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

    local size =  self.m_gameBg:findChild("ChineseStyle_Background_1"):getContentSize()

    local scaleX =  display.width / size.width 
    local scaleY =  display.height / size.height 
    self.m_gameBg:setScaleX(scaleX)
    self.m_gameBg:setScaleY(scaleY)
end

-- 创建正常状态轮盘缓慢滚动
function CodeGameScreenQuickHitMachine:SlowWheelRun( )
    self.m_WheelView:findChild("QuickHit_lunpan_di"):runAction(cc.RepeatForever:create(cc.RotateBy:create(4, 36)))
    self.m_WheelView:findChild("QuickHit_lunpan_panxiao"):runAction(cc.RepeatForever:create(cc.RotateBy:create(4, 36)))
end

-- 停止正常状态轮盘缓慢滚动
function CodeGameScreenQuickHitMachine:StopSlowWheelRun( )
    self.m_WheelView:findChild("QuickHit_lunpan_di"):stopAllActions()
    self.m_WheelView:findChild("QuickHit_lunpan_panxiao"):stopAllActions()
    self.m_WheelView:findChild("QuickHit_lunpan_di"):setRotation(0)
    self.m_WheelView:findChild("QuickHit_lunpan_panxiao"):setRotation(0)

end

function CodeGameScreenQuickHitMachine:scaleMainLayer()
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

    local reelslevelPosY = 0

    if globalData.slotRunData.isPortrait == true then
        if display.height >= FIT_HEIGHT_MAX then

            self:findChild("QuickHit_bg_deng_1"):setScale(0.65)
            self:findChild("QuickHit_bg_deng_2"):setScale(0.65)

            if display.height/display.width >= 2 then
                mainScale = FIT_HEIGHT_MAX/ DESIGN_SIZE.height
                reelslevelPosY = 20
            else
                mainScale = FIT_HEIGHT_MAX/ (DESIGN_SIZE.height + 15)
            end

            
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            local addPosY = uiBH / self.m_machineRootScale - reelslevelPosY/self.m_machineRootScale
            if display.height/display.width >= 2 then
                addPosY = addPosY + 80/self.m_machineRootScale
            end
            self:findChild("root_0"):setPositionY(addPosY)
        elseif display.height < FIT_HEIGHT_MAX and display.height >= DESIGN_SIZE.height then

            self:findChild("QuickHit_bg_deng_1"):setScale(0.55)
            self:findChild("QuickHit_bg_deng_2"):setScale(0.55)

            mainScale = FIT_HEIGHT_MAX/ (DESIGN_SIZE.height + 15)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            local addPosY = uiBH / self.m_machineRootScale - reelslevelPosY/self.m_machineRootScale
            self:findChild("root_0"):setPositionY(addPosY)
            
            
        elseif display.height < FIT_HEIGHT_MID and display.height >= FIT_HEIGHT_MIN then


            self:findChild("QuickHit_bg_deng_1"):setScaleY(0.6)
            self:findChild("QuickHit_bg_deng_1"):setScaleX(0.75)
            self:findChild("QuickHit_bg_deng_2"):setScaleY(0.6)
            self:findChild("QuickHit_bg_deng_1"):setScaleX(0.75)

            mainScale = display.height/ (DESIGN_SIZE.height + 15)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            local addPosY =   uiBH / self.m_machineRootScale - reelslevelPosY/self.m_machineRootScale
            self:findChild("root_0"):setPositionY(addPosY)

        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = display.height/ (DESIGN_SIZE.height + 15)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            local addPosY =   uiBH / self.m_machineRootScale - reelslevelPosY/self.m_machineRootScale
            self:findChild("root_0"):setPositionY(addPosY)

            self:findChild("QuickHit_bg_deng_1"):setScaleY(0.5)
            self:findChild("QuickHit_bg_deng_1"):setScaleX(0.65)
            self:findChild("QuickHit_bg_deng_2"):setScaleY(0.5)
            self:findChild("QuickHit_bg_deng_1"):setScaleX(0.65)

        else

            self:findChild("QuickHit_bg_deng_1"):setScaleY(0.4)
            self:findChild("QuickHit_bg_deng_1"):setScaleX(0.6)
            self:findChild("QuickHit_bg_deng_2"):setScaleY(0.4)
            self:findChild("QuickHit_bg_deng_1"):setScaleX(0.6)

            mainScale = (display.height + 130)/ (DESIGN_SIZE.height + 15)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            local addPosY =   uiBH / self.m_machineRootScale - reelslevelPosY/self.m_machineRootScale
            -- self.m_machineNode:setPositionY(addPosY)
            self:findChild("root_0"):setPositionY(addPosY)
            
            
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end


    self:dealUIPos( )
    
end

function CodeGameScreenQuickHitMachine:checkWheelMaskShow( )
    if display.height < FIT_HEIGHT_MIN then
        self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(true)
        self:findChild("Node_Jackpot"):setLocalZOrder(1)
        
    else
        self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(false)
        self:findChild("Node_Jackpot"):setLocalZOrder(1)
    end
    
end

function CodeGameScreenQuickHitMachine:dealUIPos( )
    
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    if display.height >= 1400 then
        local nodeJackpot = self:findChild("Node_Jackpot")
        local nodeJackpotPosY = (display.height - uiH)/self.m_machineRootScale - 130/self.m_machineRootScale

        if display.height/display.width >= 2 then
            nodeJackpotPosY = nodeJackpotPosY - 40/self.m_machineRootScale
        end

        nodeJackpot:setPositionY(nodeJackpotPosY)

        nodeJackpot:setScale(1.1)
    elseif display.height < 1400 and display.height >= 1370 then

        local nodeJackpot = self:findChild("Node_Jackpot")
        local nodeJackpotPosY = (display.height - uiH)/self.m_machineRootScale - 100/self.m_machineRootScale
        nodeJackpot:setPositionY(nodeJackpotPosY)


    elseif display.height < 1370 and display.height >= 1300 then
        local nodeJackpot = self:findChild("Node_Jackpot")
       
        local nodeJackpotPosY = ((display.height ) - uiH)/self.m_machineRootScale - 100/self.m_machineRootScale
        nodeJackpot:setPositionY(nodeJackpotPosY)

    elseif display.height < 1300 and display.height > 1159 then
            
        local nodeJackpot = self:findChild("Node_Jackpot")
        if display.height >=  1280 and display.height <  1300 then--
            local nodeJackpotPosY = ((display.height ) - uiH)/self.m_machineRootScale - 100/self.m_machineRootScale
            nodeJackpot:setPositionY(nodeJackpotPosY)


        elseif display.height < 1280 and display.height >= 1181 then
            local nodeJackpotPosY = ((display.height ) - uiH)/self.m_machineRootScale - 90/self.m_machineRootScale
            nodeJackpot:setPositionY(nodeJackpotPosY)

        elseif display.height < 1181 and display.height > 1159 then
                local nodeJackpotPosY = ((display.height ) - uiH)/self.m_machineRootScale - 50/self.m_machineRootScale
                nodeJackpot:setPositionY(nodeJackpotPosY)

        end
                
    else
        local cutPos = 170
        if display.height > 1052 then
            cutPos = 200 
        end

        local nodeJackpot = self:findChild("Node_Jackpot")
        local nodeJackpotPosY = (display.height + 130 - uiH)/self.m_machineRootScale - cutPos/self.m_machineRootScale
        nodeJackpot:setPositionY(nodeJackpotPosY)
    end
    
    
    if globalData.slotRunData.isPortrait then
        local bangHeight =  util_getBangScreenHeight()
        local nodeJackpot = self:findChild("Node_Jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY()  -bangHeight )
    end
    
end

function CodeGameScreenQuickHitMachine:changeViewNodePos( )

    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
    
    elseif display.height < FIT_HEIGHT_MIN then

    end

end


---
-- 初始化轮盘界面, 已进入游戏时初始化
--
function CodeGameScreenQuickHitMachine:initMachineGame()


end

-- 断线重连 
function CodeGameScreenQuickHitMachine:MachineRule_initGame(  )

    -- 断线重连,重置轮盘
    self:changeWheelForData()

    
    
end

function CodeGameScreenQuickHitMachine:changeWheelForData( )

    if self.m_runSpinResultData.p_selfMakeData and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE  then

        self:StopSlowWheelRun()

        local bigEnd = self:getBigWheelEndIndex(self.m_runSpinResultData.p_selfMakeData.type) - 1
        local rota = 360/#self.m_BigWheelData
        local distance = - (bigEnd * rota )
        self.m_WheelView:findChild("QuickHit_lunpan_di"):setRotation(distance)
        self.m_WheelView:setWheelBgZorder(self.m_runSpinResultData.p_selfMakeData.type)
    
        local index = self.m_runSpinResultData.p_selfMakeData.type 
        self.m_TopView:chooseOneGameTipshow( index )   
        self.m_TopView:setActionState(0)

        -- self.m_TopView:updateFreespinBet()
        -- self.m_TopView:changeWildByCount()
        self.m_TopView:restFreeSpinBet()


        if index == self.m_WILD then
            self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(false)
            self:findChild("Node_Jackpot"):setLocalZOrder(-1)
            self.m_QuickHitBGAction:setVisible(true)
            self.m_QuickHitBGAction:runSelfCsbAction("bgidlebonus_lan",true)
            -- util_spinePlay(self.m_Wheelbgtexiao, "bgidlebonus_lan", true)
        elseif index == self.m_FREESPIN then

            self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(false)
            self:findChild("Node_Jackpot"):setLocalZOrder(-1)
            self.m_QuickHitBGAction:setVisible(true)
            self.m_QuickHitBGAction:runSelfCsbAction("bgidlebonus_zi",true)
            -- util_spinePlay(self.m_Wheelbgtexiao, "bgidlebonus_zi", true)
        end

        -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(true)
        -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(false)

        self.m_WheelView.m_WheelPointAction:runCsbAction("sanfa")
        self.m_WheelView.m_WheelPointAction:showParticle()
        -- self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(true)
        self.m_WheelView:findChild("QuickHit_lunpan_heise_3_0"):setVisible(true) 
        self.m_WheelView:findChild("QuickHit_lunpan_hong1_1"):setVisible(false)

    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_TopView:initWildByCount()
        self.m_TopView:changeFreeSpinByCount()
    end
   

end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenQuickHitMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "QuickHit"  
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenQuickHitMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_QUICKHIT then
        return "Socre_QuickHit"

    elseif symbolType == self.SYMBOL_SCORE_CHANGE_WILD then
        return "Socre_QuickHit_Wild2"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenQuickHitMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_CHANGE_WILD,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

--
--单列滚动停止回调
--
function CodeGameScreenQuickHitMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol) 
    local isPlaySound = true
    local QuickHitNum = 0
    for iRow = 1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if symbolType == self.SYMBOL_SCORE_QUICKHIT then
            QuickHitNum = QuickHitNum + 1
        end
        
    end

    

    for iRow = 1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if symbolType == self.SYMBOL_SCORE_QUICKHIT then
            -- local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,iRow,SYMBOL_NODE_TAG))
            local targSp = self:getReelParentChildNode(reelCol,iRow)
            if targSp then

                if reelCol == self.m_iReelColumnNum then
                    if QuickHitNum >= 5  then
                        targSp:runAnim("buling")
                        if isPlaySound then

                            local soundPath = "QuickHitSounds/music_QuickHit_jackPot_Down.mp3"
                            if self.playBulingSymbolSounds then
                                self:playBulingSymbolSounds( reelCol,soundPath )
                            else
                                gLobalSoundManager:playSound(soundPath)
                            end  
    
                            isPlaySound = false
                        end
                    end 
                else

                    targSp:runAnim("buling")
                    if isPlaySound then

                        local soundPath = "QuickHitSounds/music_QuickHit_jackPot_Down.mp3"
                        if self.playBulingSymbolSounds then
                            self:playBulingSymbolSounds( reelCol,soundPath )
                        else
                            gLobalSoundManager:playSound(soundPath)
                        end 

                        isPlaySound = false
                    end
                end
                
                    
            end
        end
        
    end
    
    
    if reelCol == 3 and self.m_reelRunInfo[3].m_bNextReelLongRun == true then
        self:findChild("sp_reel_3!"):setVisible(true)
    end
    
    if reelCol >= 4 then
        self:findChild("sp_reel_3!"):setVisible(false)
    end
    
end


---
-- 轮盘停下后 改变数据
--
function CodeGameScreenQuickHitMachine:MachineRule_stopReelChangeData()
    
    
end


---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenQuickHitMachine:levelFreeSpinEffectChange()

    -- self:runCsbAction("change_freespin")

end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenQuickHitMachine:levelFreeSpinOverChangeEffect()

    -- self:runCsbAction("change_normal")
    
end
---------------------------------------------------------------------------



function CodeGameScreenQuickHitMachine:showFreeSpinView(effectData)
    -- 停掉背景音乐
    self:clearCurMusicBg()


    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

        
        -- self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
        --     effectData.p_isPlay = true
        --     self:playGameEffect()
        -- end,true)
    else
            -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_enter_fs_view.mp3")

            local func = function(  )
                self:wheelTrigger_Wild_FreeSpin_Act(effectData )
            end
            local  csbname = "Bonusfreespin0"   

            self:showTriggerBonusGameTip(function(  )

                performWithDelay(self,function( )
                    self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(false)
                    self.m_QuickHitBGAction:setVisible(true)
                    self:findChild("Node_Jackpot"):setLocalZOrder(-1)
                end,15/30)

                self:showBonusWin(func,csbname)

            end,TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            

    end

end

function CodeGameScreenQuickHitMachine:wheelTrigger_Wild_FreeSpin_Act(effectData )

    local typeNum = self.m_runSpinResultData.p_selfMakeData.type
    local num = self.m_runSpinResultData.p_freeSpinsTotalCount
    local smallEnd,smallWheelData = self:getSmallTriggerWheelEndIndex(typeNum,num) -- wild和FreeSpin玩法触发那一次
    local bigEnd =self:getBigWheelEndIndex(typeNum)

    if self.m_Bonus_bg_sound_1 then
        gLobalSoundManager:stopAudio(self.m_Bonus_bg_sound_1)
        self.m_Bonus_bg_sound_1 = nil
    end

    self.m_WheelView.playSmallWheelSound = false

    self.m_Bonus_bg_sound = gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_Bonus_bg.mp3",true)
  
    self.m_WheelView:initViewData(function(  )
        -- print("大轮盘停止回调")

        self.m_WheelView.playSmallWheelSound = true

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_big_reward.mp3")

        self.m_WheelView:setWheelBgZorder(typeNum)
        self.m_WheelView:setSmallWheelData(smallWheelData )
        self.m_WheelView:CreateSmallWheelLab(true)
        self.m_WheelView.m_bigWheelNode[bigEnd]:runCsbAction("actionframe",true)

        self.m_WheelView.m_WheelPointAction:runCsbAction("sanfa")
        self.m_WheelView.m_WheelPointAction:showParticle()
        
        self.m_WheelView:findChild("QuickHit_lunpan_heise_3_0"):setVisible(true) 
        self.m_WheelView:findChild("QuickHit_lunpan_hong1_1"):setVisible(false)

    end,function(  )
        -- print("小轮盘停止回调 big: "..bigEnd.."  small: "..smallEnd)

        self.m_WheelView.playSmallWheelSound = false

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_small_reward.mp3")
        self.m_WheelView.m_bigWheelNode[bigEnd]:runCsbAction("idleframe")

        self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(true) 
     
        self.m_WheelView.m_Wheel2WinAction:runCsbAction("actionframe",false,function(  )

            self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 
            

                self.m_WheelView:removeAllSmallWheelLab()
                self:findChild("Node_reel"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                self.m_TriggerGameFlash = util_createView("CodeQuickHitSrc.QuickHitTriggerGameFlashAction")
                self:findChild("Node_reel"):addChild(self.m_TriggerGameFlash)
                gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_flash.mp3")
                

                if typeNum == self.m_FREESPIN then
                    self.m_QuickHitBGAction:runSelfCsbAction("bgidlebonus_zi",true)
                    -- util_spinePlay(self.m_Wheelbgtexiao, "bgidlebonus_zi", true)
                elseif typeNum == self.m_WILD then
                    self.m_QuickHitBGAction:runSelfCsbAction("bgidlebonus_lan",true)
                    -- util_spinePlay(self.m_Wheelbgtexiao, "bgidlebonus_lan", true)
                end 
                
                -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(true)
                -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(false)
 
                local waitTime = self.m_TriggerGameFlash:getWaitTime()
                performWithDelay(self,function() 
        
                    if self.m_TriggerGameFlash then
                        self.m_TriggerGameFlash:removeSelf(function(  )
 
                            if self.m_Bonus_bg_sound then
                                gLobalSoundManager:stopAudio(self.m_Bonus_bg_sound)
                                self.m_Bonus_bg_sound = nil
                            end

                            local fsBgMusicPath = self:getFreeSpinMusicBG()
                            self:resetMusicBg(nil,fsBgMusicPath)

                            --gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_view_show.mp3")

                            self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function()

                                

                                gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_btn_click.mp3")

                                if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                                    -- 只有触发那一次
                                    self.m_TopView:chooseOneGameTipshow(self.m_runSpinResultData.p_selfMakeData.type)
                                    -- 设置滚动状态
                                    self.m_TopView:setActionState(0)
                    
                                    self.m_TopView:updateFreespinBet()
                    
                                    self.m_TopView:changeWildByCount()
                    
                                    self.m_TopView:restWildTimes()
        
                                    self.m_TopView:restFreeSpinBet()
                                end  
                    
                            
                            
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()    
                            end)
                    
                            self.m_TriggerGameFlash = nil
                        end)
                    end
                
                    
                end,waitTime)
        end)
        
       
    end)


    self.m_WheelView:beginBigWheelAction( bigEnd  )
    self.m_WheelView:beginSmallWheelAction( smallEnd )

    self.m_QuickHitBGAction:runSelfCsbAction("bgidlebonus",true)
    -- util_spinePlay(self.m_Wheelbgtexiao, "bgidlebonus", true)

    -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(false)
    -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(true)
    
    
end

function CodeGameScreenQuickHitMachine:showFreeSpinStart(num,func)
    local csbname = "Bonusfreespin0" 
    if self.m_runSpinResultData.p_selfMakeData.type == self.m_WILD then
        csbname = "Bonusfreespin1"
    elseif self.m_runSpinResultData.p_selfMakeData.type == self.m_FREESPIN then
        csbname = "Bonusfreespin2"    
    end
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    self:showDialog(csbname,ownerlist,func)

    performWithDelay(self,function( )
        self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(false)
        self.m_QuickHitBGAction:setVisible(true)
        self:findChild("Node_Jackpot"):setLocalZOrder(-1)
    end,15/30)

end

function CodeGameScreenQuickHitMachine:showFreeSpinOverView()

   local fsOverSpunfId =  gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_view_over.mp3")

    local strCoins= globalData.slotRunData.lastWinCoin -- util_formatCoins(globalData.slotRunData.lastWinCoin,30)

    self:showFreespinOverView_selfMake( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        if fsOverSpunfId then
            gLobalSoundManager:stopAudio(fsOverSpunfId)
        end
        

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_btn_click.mp3")

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_flash.mp3")

        self.m_TransitionView = util_createView("CodeQuickHitSrc.QuickHitTransitionView")
        self:findChild("Node_reel"):addChild(self.m_TransitionView)
        self.m_TransitionView:runSelfAni( "animation0",false,function(  )
            self.m_TransitionView:removeSelf( )
            self.m_TransitionView = nil
            
        end)

        self.m_WheelView:findChild("QuickHit_lunpan_hong1_1"):setVisible(true)

        self.m_WheelView:findChild("QuickHit_lunpan_heise_3_0"):setVisible(false) 

        -- 需要清理小轮盘的lab
        self.m_WheelView:removeAllSmallWheelLab()

        self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 

        self.m_WheelView.m_WheelPointAction:runCsbAction("hide")
        self.m_WheelView.m_Wheel2WinAction:runCsbAction("hide")

        self.m_QuickHitBGAction:runSelfCsbAction("idle",true)
        -- util_spinePlay(self.m_Wheelbgtexiao, "bgidle", true)
        -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(false)
        -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(true)

        
        self.m_TopView:setActionState(1)
        self.m_TopView:chooseOneTipshow()

        self:SlowWheelRun()

        self.m_QuickHitBGAction:setVisible(false)

        self:checkWheelMaskShow( )

        self:triggerFreeSpinOverCallFun()
    end)

end


function CodeGameScreenQuickHitMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()

    performWithDelay(self,function(  )
        self.m_QuickHitBGAction:setVisible(false)
        self:checkWheelMaskShow( )
    end,10/30)
    


    local csbname = "Bonusfreespin3" 

    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showDialog(csbname,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenQuickHitMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    
    self.isInBonus = false

    -- 检测是否需要移除JackPot动画
    self.m_jackPotBar:removeDelayFunc()

     

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 不在FreeSpin中 点spin需要清理小轮盘的lab
        self.m_WheelView:removeAllSmallWheelLab()
    end


    local iswait = false
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_selfMakeData.type == self.m_WILD then
            iswait = true
            -- self:normalSpinBtnCall()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            self:wheelWILDAct()
        end
    end


    return iswait -- 用作延时点击spin调用
end

function CodeGameScreenQuickHitMachine:initJackpotInfo(jackpotPool,lastBetId)
    self:updateJackpot()
end

function CodeGameScreenQuickHitMachine:updateJackpot()
    self.m_jackPotBar:updateJackpotInfo()
end



function CodeGameScreenQuickHitMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenQuickHitMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenQuickHitMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)

end

function CodeGameScreenQuickHitMachine:onExit()

    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    self.m_jackPotBar:removeAllChildren()
    self.m_jackPotBar:removeFromParent()
    self.m_jackPotBar = nil
end



-- ------------玩法处理 -- 

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenQuickHitMachine:MachineRule_network_InterveneSymbolMap()

    self.m_addSpecialCoins = 0
    --特殊玩法增加的数量
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.type then
      
        if self.m_runSpinResultData.p_selfMakeData.type == self.m_DOLLAR  then
            
            local normalLines = self.m_runSpinResultData.p_selfMakeData.normalLines
            if normalLines then
                for k,v in pairs(normalLines) do
                    self.m_addSpecialCoins = self.m_addSpecialCoins + v.amount
                end
            end
        elseif self.m_runSpinResultData.p_selfMakeData.type == self.m_QUICKHIT then
            local normalLines = self.m_runSpinResultData.p_winLines
            if normalLines then
                for k,v in pairs(normalLines) do
                    self.m_addSpecialCoins = self.m_addSpecialCoins + v.p_amount
                end
            end

        end
    end
end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenQuickHitMachine:MachineRule_afterNetWorkLineLogicCalculate()
    
end

---
-- 排序m_gameEffects 列表，根据 effectOrder
--
function CodeGameScreenQuickHitMachine:sortGameEffects( )
    -- 排序effect 队列
    table.sort(
        self.m_gameEffects,
        function(a, b)
            return a.p_effectOrder < b.p_effectOrder
        end
    )

    local a =  self.m_gameEffects
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenQuickHitMachine:addSelfEffect()

    self:updateJackpot()
    self.m_jackPotTipsList={}
    local jackpotNum = 0
    local maxRow=#self.m_runSpinResultData.p_reelsData
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = self.m_iReelRowNum, 1, -1 do
            -- local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
            local targSp = self:getReelParentChildNode(iCol,iRow)
            if targSp then
                if targSp.p_symbolType==self.SYMBOL_SCORE_QUICKHIT then
                    jackpotNum=jackpotNum+1
                    self.m_jackPotTipsList[jackpotNum]=targSp
                end
            end
        end
    end

    local isPlayFsMusic =false
    if self.m_runSpinResultData.p_features ~= nil and 
        #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        for i=1,featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            if featureID~=0 then
                isPlayFsMusic=true
                break
            end
        end
    end

    if isPlayFsMusic then
        -- gLobalSoundManager:playSound("RapidFireSounds/rapidfire_in_freespin_fs.mp3")
    end
    
    if jackpotNum<3 then
        self.m_jackPotTipsList=nil
    else
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT
    end
        
    --添加转盘自定义动画
    self:addWheelChangeEffect()
end

---
-- 添加动画
-- 
function CodeGameScreenQuickHitMachine:addWheelChangeEffect()

    if self.m_runSpinResultData.p_selfMakeData then
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE 
           and self.m_runSpinResultData.p_selfMakeData.type == self.m_WILD then

                -- local selfEffect = GameEffectData.new()
                -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                -- selfEffect.p_selfEffectType = self.Wheel_WILD_EFFECT

        elseif globalData.slotRunData.currSpinMode == FREE_SPIN_MODE 
            and self.m_runSpinResultData.p_selfMakeData.type == self.m_FREESPIN then
                -- local selfEffect = GameEffectData.new()
                -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                -- selfEffect.p_selfEffectType = self.Wheel_FREESPIN_EFFECT

        elseif self.m_runSpinResultData.p_selfMakeData.type == self.m_DOLLAR then

            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.normalLines then
               if #self.m_runSpinResultData.p_selfMakeData.normalLines > 0 then
                    local selfWinLinesEffect = GameEffectData.new()
                    selfWinLinesEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT 
                    selfWinLinesEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT -1
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfWinLinesEffect
                    selfWinLinesEffect.p_selfEffectType = self.Wheel_DOLLAR_WINLINES_EFFECT
               end
                 
            end


            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Wheel_DOLLAR_EFFECT
        elseif self.m_runSpinResultData.p_selfMakeData.type == self.m_QUICKHIT then

            if self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines > 0 then
                local selfWinLinesEffect = GameEffectData.new()
                selfWinLinesEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT 
                selfWinLinesEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT -1
                self.m_gameEffects[#self.m_gameEffects + 1] = selfWinLinesEffect
                selfWinLinesEffect.p_selfEffectType = self.Wheel_QUICKHIT_JACKPOT_WINLINES_EFFECT
            end
            

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Wheel_QUICKHIT_JACKPOT_EFFECT
        end

    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenQuickHitMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then

        self:quickHitJackPotAct(effectData)


    elseif effectData.p_selfEffectType == self.Wheel_DOLLAR_EFFECT then
        
        self:showTriggerBonusGameTip(function(  )
            self:wheelDollerAct(effectData)
        end,TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    elseif effectData.p_selfEffectType == self.Wheel_QUICKHIT_JACKPOT_EFFECT then
        self:showTriggerBonusGameTip(function(  )
            self:wheelQuickHitJackPotAct(effectData)
        end,TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        
    elseif effectData.p_selfEffectType == self.Wheel_FREESPIN_EFFECT then

    elseif effectData.p_selfEffectType == self.Wheel_WILD_EFFECT then

    elseif effectData.p_selfEffectType == self.Wheel_DOLLAR_WINLINES_EFFECT then

        self:showEffect_LineFrame(effectData,true)

    elseif effectData.p_selfEffectType == self.Wheel_QUICKHIT_JACKPOT_WINLINES_EFFECT then

        self:showEffect_LineFrame(effectData,true) 

    end

    
	return true
end


function CodeGameScreenQuickHitMachine:getOneSymbolPos( pos )
    local Row = nil
    local Col = nil
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
    
            local iconpos = self:getPosReelIdx(iRow, iCol)
            
            if pos == iconpos  then
                Row = iRow
                Col = iCol
                return Row,Col
            end 

        end
    end

    return Row,Col
end


function CodeGameScreenQuickHitMachine:wheelDollerAct(effectData )

    local func = function(  )
        local typeNum = self.m_runSpinResultData.p_selfMakeData.type
        local num = self.m_runSpinResultData.p_selfMakeData.mutiple
        local bonusIconsArray = self.m_runSpinResultData.p_selfMakeData.bonusIcons
        local smallEnd,smallWheelData = self:getSmallWheelEndIndex(typeNum,num)
        local bigEnd =self:getBigWheelEndIndex(typeNum)
        local time = 1
        local index = 0

        
        local bonusChange = function(  )
            for k,v in pairs(bonusIconsArray) do
                local reelRow,reelCol =  self:getOneSymbolPos(v)       
                -- local symbolNode =  self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,reelRow,SYMBOL_NODE_TAG))
                local symbolNode = self:getReelParentChildNode(reelCol,reelRow)
                performWithDelay(self,function() 
                    symbolNode:runAnim("bonus_wild",false,function(  )
                        symbolNode:changeCCBByName("Socre_QuickHit_Wild2",self.SYMBOL_SCORE_CHANGE_WILD) 
                    end)   
                end, index * time)
                index = index + 1
            end
            
        end

        if self.m_Bonus_bg_sound_1 then
            gLobalSoundManager:stopAudio(self.m_Bonus_bg_sound_1)
            self.m_Bonus_bg_sound_1 = nil
        end
        
        self.m_WheelView.playSmallWheelSound = false

        self.m_Bonus_bg_sound = gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_Bonus_bg.mp3",true)

        self.m_WheelView:initViewData(function(  )
            -- print("大轮盘停止回调")

            self.m_WheelView.playSmallWheelSound = true

            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_big_reward.mp3")

            self.m_WheelView:setWheelBgZorder(typeNum)
            self.m_WheelView:setSmallWheelData(smallWheelData )
            self.m_WheelView:CreateSmallWheelLab()
            self.m_WheelView.m_bigWheelNode[bigEnd]:runCsbAction("actionframe",true)

            self.m_WheelView.m_WheelPointAction:runCsbAction("sanfa")
            self.m_WheelView.m_WheelPointAction:showParticle()
            self.m_WheelView:findChild("QuickHit_lunpan_heise_3_0"):setVisible(true) 
            self.m_WheelView:findChild("QuickHit_lunpan_hong1_1"):setVisible(false)

        end,function(  )
            -- print("小轮盘停止回调 big: "..bigEnd.."  small: "..smallEnd)

            self.m_WheelView.playSmallWheelSound = false

            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_small_reward.mp3")
            self.m_WheelView.m_bigWheelNode[bigEnd]:runCsbAction("idleframe")

            self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(true) 

            self.m_WheelView.m_Wheel2WinAction:runCsbAction("actionframe",false,function(  )

                gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_bonus_to_wild.mp3")  

                bonusChange()

                self.m_TopView:chooseOneGameTipshow(self.m_runSpinResultData.p_selfMakeData.type)
                -- 设置滚动状态
                self.m_TopView:setActionState(0)

                scheduler.performWithDelayGlobal(function (  )


                    if self.m_Bonus_bg_sound then
                        gLobalSoundManager:stopAudio(self.m_Bonus_bg_sound)
                        self.m_Bonus_bg_sound = nil
                    end

                    gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_flash.mp3")
                    self.m_TransitionView = util_createView("CodeQuickHitSrc.QuickHitTransitionView")
                    self:findChild("Node_reel"):addChild(self.m_TransitionView)
                    self.m_TransitionView:runSelfAni( "animation0",false,function(  )
                        self.m_TransitionView:removeSelf( )
                        self.m_TransitionView = nil
                        
                    end)

                    self.m_WheelView:findChild("QuickHit_lunpan_hong1_1"):setVisible(true)

                    self.m_WheelView:findChild("QuickHit_lunpan_heise_3_0"):setVisible(false) 

                    -- 需要清理小轮盘的lab
                    self.m_WheelView:removeAllSmallWheelLab()

                    self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 

                    self.m_WheelView.m_WheelPointAction:runCsbAction("hide")
                    self.m_WheelView.m_Wheel2WinAction:runCsbAction("hide")

                    self.m_QuickHitBGAction:runSelfCsbAction("idle",true)
                    -- util_spinePlay(self.m_Wheelbgtexiao, "bgidle", true)
                    -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(false)
                    -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(true)

                    self.m_TopView:setActionState(1)
                    self.m_TopView:chooseOneTipshow()

                    self:SlowWheelRun()
                    self.m_QuickHitBGAction:setVisible(false)
                    self:checkWheelMaskShow( )

                    effectData.p_isPlay = true
                    self:playGameEffect()

                    
                end,(time * index  ) + 1,self:getModuleName())
            end)

            
            
        end)

        self.m_WheelView:beginBigWheelAction( bigEnd  )
        self.m_WheelView:beginSmallWheelAction( smallEnd )

        self.m_QuickHitBGAction:runSelfCsbAction("bgidlebonus",true)
        -- util_spinePlay(self.m_Wheelbgtexiao, "bgidlebonus", true)
        -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(false)
        -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(true)
    end
    

    local  csbname = "Bonusfreespin0"   

    performWithDelay(self,function( )
        self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(false)
        self.m_QuickHitBGAction:setVisible(true)
        self:findChild("Node_Jackpot"):setLocalZOrder(-1)
    end,15/30)

    self:showBonusWin(func,csbname)

    
end

function CodeGameScreenQuickHitMachine:wheelQuickHitJackPotAct(effectData )

    local func = function(  )
        local typeNum = self.m_runSpinResultData.p_selfMakeData.type
        local num = self.m_runSpinResultData.p_selfMakeData.quickhits
        local winBet = self.m_runSpinResultData.p_selfMakeData.mutiple
        local smallEnd,smallWheelData = self:getSmallWheelEndIndex(typeNum,num)
        local bigEnd =self:getBigWheelEndIndex(typeNum)

        if self.m_Bonus_bg_sound_1 then
            gLobalSoundManager:stopAudio(self.m_Bonus_bg_sound_1)
            self.m_Bonus_bg_sound_1 = nil
        end
        
        self.m_Bonus_bg_sound = gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_Bonus_bg.mp3",true)

        self.m_WheelView.playSmallWheelSound = false

        self.m_WheelView:initViewData(function(  )
            -- print("大轮盘停止回调")

            self.m_WheelView.playSmallWheelSound = true

            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_big_reward.mp3")
            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_small_change_collor.mp3")
            
            self.m_WheelView:setWheelBgZorder(typeNum)
            self.m_WheelView:setSmallWheelData(smallWheelData )
            self.m_WheelView:CreateSmallWheelLab()
            self.m_WheelView.m_bigWheelNode[bigEnd]:runCsbAction("actionframe",true)
          
            self.m_WheelView.m_WheelPointAction:runCsbAction("sanfa")
            self.m_WheelView.m_WheelPointAction:showParticle()
            self.m_WheelView:findChild("QuickHit_lunpan_heise_3_0"):setVisible(true) 
            self.m_WheelView:findChild("QuickHit_lunpan_hong1_1"):setVisible(false)

        end,function(  )
            -- print("小轮盘停止回调")

            self.m_WheelView.playSmallWheelSound = false

            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_small_reward.mp3")
            self.m_WheelView.m_bigWheelNode[bigEnd]:runCsbAction("idleframe")

            self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(true) 

            -- 设置滚动状态
            self.m_TopView:setActionState(0)

            self.m_TopView:chooseOneGameTipshow(self.m_runSpinResultData.p_selfMakeData.type)

            self.m_WheelView.m_Wheel2WinAction:runCsbAction("actionframe1",false,function(  )
                    self:hideLocalReels()

                    self:clearWinLineEffect()

                    self:findChild("Node_reel"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                    self.m_JackPotReelsAction = util_createView("CodeQuickHitSrc.QuickHitJackPotReelsAction",num)
                    self:findChild("Node_reel"):addChild(self.m_JackPotReelsAction)
                    
                    performWithDelay(self,function() 

                    
                        local index=10-num
                        local Winscore = self.m_serverWinCoins -- self:BaseMania_getLineBet() * winBet
                        self.m_jackPotBar:showJackPotAni(num)

                        -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_view_over.mp3")
                        if self.m_Bonus_bg_sound then
                            gLobalSoundManager:stopAudio(self.m_Bonus_bg_sound)
                            self.m_Bonus_bg_sound = nil
                        end

                        self:showJackPot(Winscore,num,function()

                            --刷新quest进度
                            if self.updateQuestUI then
                                self:updateQuestUI()
                            end
                            -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_btn_click.mp3")

                            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_flash.mp3")
                            self.m_TransitionView = util_createView("CodeQuickHitSrc.QuickHitTransitionView")
                            self:findChild("Node_reel"):addChild(self.m_TransitionView)
                            self.m_TransitionView:runSelfAni( "animation0",false,function(  )
                                
                                self.m_TransitionView:removeSelf( )
                                self.m_TransitionView = nil
                                
                            end)
                            
                            
                            self.m_WheelView:findChild("QuickHit_lunpan_hong1_1"):setVisible(true)
                            self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 

                            self.m_WheelView:findChild("QuickHit_lunpan_heise_3_0"):setVisible(false) 

                            -- 需要清理小轮盘的lab
                            self.m_WheelView:removeAllSmallWheelLab()

                            self.m_WheelView.m_WheelPointAction:runCsbAction("hide")

                            self.m_WheelView.m_Wheel2WinAction:runCsbAction("hide")

                            self.m_QuickHitBGAction:runSelfCsbAction("idle",true)
                            -- util_spinePlay(self.m_Wheelbgtexiao, "bgidle", true)
                            -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(false)
                            -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(true)

                            self:showLocalReels()

                            local score = self.m_serverWinCoins -- self:BaseMania_getLineBet() * winBet
                            if self.m_addSpecialCoins == 0 then
                                
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_serverWinCoins, GameEffect.EFFECT_BONUS})
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                            end
                            
                            self.m_TopView:setActionState(1)
                            self.m_TopView:chooseOneTipshow()

                            if self.m_JackPotReelsAction then
                                self.m_JackPotReelsAction:removeSelf()
                                self.m_JackPotReelsAction = nil
                            end
                            
                            self:SlowWheelRun()

                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end)
            
                    end,self.m_JackPotReelsAction:getWaitTime() )
            end)

        end)

        self.m_WheelView:beginBigWheelAction( bigEnd  )
        self.m_WheelView:beginSmallWheelAction( smallEnd )
        self.m_QuickHitBGAction:runSelfCsbAction("bgidlebonus",true)
        -- util_spinePlay(self.m_Wheelbgtexiao, "bgidlebonus", true)
        -- self.m_QuickHitBGAction:findChild("dongtai"):setVisible(false)
        -- self.m_QuickHitBGAction:findChild("jingtai"):setVisible(true)
    end
    
    local  csbname = "Bonusfreespin0"   


    self:showBonusWin(func,csbname)

    performWithDelay(self,function( )
        self.m_WheelView:findChild("QuickHit_lunpan_an_23"):setVisible(false)
        self.m_QuickHitBGAction:setVisible(true)
        self:findChild("Node_Jackpot"):setLocalZOrder(-1)
    end,15/30)

    
end

function CodeGameScreenQuickHitMachine:wheelFREESPINAct( func )

    local typeNum = self.m_runSpinResultData.p_selfMakeData.type
    local num = self.m_runSpinResultData.p_fsExtraData.mutiple
    local smallEnd,smallWheelData = self:getSmallWheelEndIndex(typeNum,num)
    local bigEnd =self:getBigWheelEndIndex(typeNum)
    local callFunc = func

    self.m_WheelView:setSmallWheelData(smallWheelData )
    self.m_WheelView:CreateSmallWheelLab()
    self.m_TopView:restFreeSpinBet()

    self.m_WheelView.m_WheelPointAction:runCsbAction("show")

    self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 

    self.m_WheelView.playSmallWheelSound = true

    local soundId = gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_Small_run_wildOrBet.mp3")  

    self.m_WheelView:initViewData(function(  )
        -- print("大轮盘停止回调")
      
    end,function(  )
        -- print("小轮盘停止回调 big: "..bigEnd.."  small: "..smallEnd)

        self.m_WheelView.playSmallWheelSound = false

        if soundId then
            gLobalSoundManager:stopAudio(soundId)
        end

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_small_reward.mp3")

        self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(true) 

        self.m_TopView:updateFreespinBet()

        self.m_WheelView.m_Wheel2WinAction:runCsbAction("actionframe",false,function(  )

            --self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 

            

            callFunc()
        end)

        
    end)

    
    self.m_WheelView:beginSmallWheelAction_wildOrFreespin( smallEnd )

    


    
end
function CodeGameScreenQuickHitMachine:wheelWILDAct( )

    local typeNum = self.m_runSpinResultData.p_selfMakeData.type
    local num = self.m_runSpinResultData.p_fsExtraData.wilds
    local smallEnd,smallWheelData = self:getSmallWheelEndIndex(typeNum,num)
    local bigEnd =self:getBigWheelEndIndex(typeNum)

    self.m_WheelView:setSmallWheelData(smallWheelData )
    self.m_WheelView:CreateSmallWheelLab()
    self.m_TopView:restFreeSpinBet()

    self.m_WheelView.m_WheelPointAction:runCsbAction("show")

    self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 

    self.m_WheelView.playSmallWheelSound = true

    local soundId = gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_Small_run_wildOrBet.mp3")  

    self.m_WheelView:initViewData(function(  )
        -- print("大轮盘停止回调")
        
    end,function(  )
        -- print("小轮盘停止回调 big: "..bigEnd.."  small: "..smallEnd)
        if soundId then
            gLobalSoundManager:stopAudio(soundId)
        end
        
        self.m_WheelView.playSmallWheelSound = false

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_small_reward.mp3")

        self.m_WheelView:findChild("QuickHit_lunpan_heise_3"):setVisible(true) 

        self.m_WheelView.m_Wheel2WinAction:runCsbAction("actionframe",false,function(  )




            self.m_TopView:changeWildByCount()
            self:setGameSpinStage( IDLE )

            self:findChild("Node_reel"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
            self.m_AddWildAction = util_createView("CodeQuickHitSrc.QuickHitAddWildReelsAction",num)
            self:findChild("Node_reel"):addChild(self.m_AddWildAction)
            local waitTime = self.m_AddWildAction:getWaitTime()
            performWithDelay(self,function() 

                if self.m_AddWildAction then
                    self.m_AddWildAction:removeSelf(function(  )
                        self.m_AddWildAction = nil
                    end)
                end
            
                
            end,waitTime)
            performWithDelay(self,function() 

                self:addWildToReels(math.floor( num/5 ))
                self:callSpinBtn()
            
            end,waitTime*7/10)
            
        end)


    end)

    self.m_WheelView:beginSmallWheelAction_wildOrFreespin( smallEnd )
    

    
end

function CodeGameScreenQuickHitMachine:quickHitJackPotAct(effectData)
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

        if count >= 5 then
            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_jackPot_Tip.mp3")
            for _,targSp in ipairs(self.m_jackPotTipsList) do
                targSp:runAnim("actionframe",true)
            end
        end
        
        self.m_jackPotTipsList=nil
 
            if count>=5 then
                self.m_jackPotBar:showJackPotAni(count)
                performWithDelay(self,function() 
                    -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_view_over.mp3")

                    self:showJackPot(score,count,function()

                        -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_btn_click.mp3")
                        -- self:updateNotifyWinCoin()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                end, 3)
               
            else
                -- local file="RapidFireSounds/rapidfire_normal_win_3.mp3"
                -- gLobalSoundManager:playSound(file)
                -- self:updateNotifyWinCoin()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        
            
            
    end

end

function CodeGameScreenQuickHitMachine:showJackPot(coins,num,func)

    performWithDelay(self,function(  )
        self.m_QuickHitBGAction:setVisible(false)

        self:checkWheelMaskShow( )
    end,10/30)

    local view=util_createView("CodeQuickHitSrc.QuickHitJackPotWin")
    view:initViewData(coins,num,func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node},628)
end

function CodeGameScreenQuickHitMachine:showFreespinOverView_selfMake(coins,num,func)

    performWithDelay(self,function(  )
        self.m_QuickHitBGAction:setVisible(false)
        self:checkWheelMaskShow( )
    end,10/30)

    local view=util_createView("CodeQuickHitSrc.QuickHitFreespinOverView")
    view:initViewData(coins,num,func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node},627)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenQuickHitMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

--设置长滚信息
function CodeGameScreenQuickHitMachine:setReelRunInfo()
    
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

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 15) 
                self:setLastReelSymbolList()    
            end
        end

        local runLen = reelRunData:getReelRunLen()
  

        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

        local index = self.m_iReelColumnNum - 1
        if col == index and bRunLong then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
            addLens = true

        end

    end --end  for col=1,iColumn do
end

--
-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenQuickHitMachine:specialSymbolActionTreatment( node)
   
    
end

-- 根据服务器传来的值确定小转盘停止位置
-- type：服务器游戏类型 num：对应送的次数 
function CodeGameScreenQuickHitMachine:getSmallTriggerWheelEndIndex(type,num)
   
    local randBigWheelIndex , randSmallWheelIndex =   self.m_WheelView:getLastEndIndex()
    local lastIndex = randSmallWheelIndex
    local endIndex = nil
    local data = self["m_WheelData_TRIGGER_"..self.m_WheelType[type + 1]]

    for k,v in pairs(self["m_WheelData_TRIGGER_"..self.m_WheelType[type + 1]]) do
            if v == num then

                endIndex = k

                if lastIndex and k ~= lastIndex  then
                    return endIndex,data
                end
            end 
    end 

    return endIndex,data
end

-- 根据服务器传来的值确定小转盘停止位置
-- type：服务器游戏类型 num：对应送的次数 
function CodeGameScreenQuickHitMachine:getSmallWheelEndIndex(type,num)
   
    local randBigWheelIndex , randSmallWheelIndex =   self.m_WheelView:getLastEndIndex()
    local lastIndex = randSmallWheelIndex
    local endIndex = nil
    local data = self["m_WheelData_"..self.m_WheelType[type + 1]]

    for k,v in pairs(self["m_WheelData_"..self.m_WheelType[type + 1]]) do
            if v == num then
                endIndex = k

                if lastIndex and k ~= lastIndex  then
                    
                    return endIndex,data
                end
            end 
    end 

    return endIndex,data
end

-- 根据服务器传来的值确定大转盘停止位置
-- type：服务器游戏类型 
function CodeGameScreenQuickHitMachine:getBigWheelEndIndex(type)
   
    local randBigWheelIndex , randSmallWheelIndex =   self.m_WheelView:getLastEndIndex()
    local lastIndex = randBigWheelIndex
    local endIndex = nil
    local pos = type + 1

    for k,v in pairs(self.m_BigWheelData) do
            
            if v == pos then
                endIndex = k

                if lastIndex and k ~= lastIndex  then
                    return endIndex
                end
            end 
    end 

    return endIndex
end

function CodeGameScreenQuickHitMachine:showBonusWin(func,csbname,num)

    gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_enter_bonus_view.mp3")

    performWithDelay(self,function() 
        if not self.m_Bonus_bg_sound then
            self.m_Bonus_bg_sound_1 = gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_Bonus_bg_1.mp3",true)
        end
        
    end,3.3)

    local function newFunc()

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_btn_click.mp3")

        

        if csbname == "Bonusfreespin0" then
            
            local Particle_2 = self.m_view:findChild("Particle_1_ui_binkuang")
            Particle_2:stopSystem()
        end

        self:StopSlowWheelRun()

        if func then
            func()
        end
    end
    local ownerlist={}
    if num then
        ownerlist["m_lb_num"]=num
    end

    

    self.m_view = self:showDialog(csbname,ownerlist,newFunc)


end

function CodeGameScreenQuickHitMachine:showBonusWinOver(coins,func,csbname)

    local strCoins=util_formatCoins(coins,30)

    local function newFunc()
        if func then
            func()
        end
    end
    local ownerlist={}
    ownerlist["m_lb_coins"]=strCoins
    -- gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_freespin_over_view.mp3")
    
    local view = self:showDialog(csbname,ownerlist,newFunc)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},480)
end


function CodeGameScreenQuickHitMachine:checkWaitOperaNetWorkData( )
        --存在等待时间延后调用下面代码
    if self.m_waitChangeReelTime and self.m_waitChangeReelTime>0 then

        -- 关卡FreeSpin翻倍玩法（在已经接受完网络数据，本地数据赋值之后）
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.type == self.m_FREESPIN then
                -- freespin翻倍的玩法 需要滚轮在轮盘滚动完之后再停止滚动

                -- 开始滚动 freespin翻倍的玩法转盘
                self:wheelFREESPINAct( function(  )
                    -- 继续老虎机逻辑
                    self.m_waitChangeReelTime=nil
                    self:updateNetWorkData()
                end )
                

                return true
            end
        end

        scheduler.performWithDelayGlobal(function()
            self.m_waitChangeReelTime=nil
            self:updateNetWorkData()
        end, self.m_waitChangeReelTime,self:getModuleName())
        return true
    end
    return false
end

-- 转轮开始滚动函数
function CodeGameScreenQuickHitMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local FsReelDatasIndex = 0
        if self.m_runSpinResultData.p_selfMakeData then -- 添加这段代码是为了加上两个假滚滚轮
            local typeNum = self.m_runSpinResultData.p_selfMakeData.type
            if typeNum  then
                if typeNum == self.m_WILD or  typeNum == self.m_FREESPIN then
                    FsReelDatasIndex = typeNum 
                end
                
            end
        end
        self.m_fsReelDataIndex = FsReelDatasIndex
    end
    BaseSlotoManiaMachine.beginReel(self)

    -- 关卡FreeSpin翻倍玩法（在已经接受完网络数据，本地数据赋值之后）
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_selfMakeData.type == self.m_FREESPIN then
           
            --添加滚轴停止等待时间,此处的时间只是为了，确定延时逻辑，并不是就停五秒
            self:setWaitChangeReelTime(5)

        end
    end


end

---
-- 获取随机信号，  
-- @param col 列索引
function CodeGameScreenQuickHitMachine:MachineRule_getRandomSymbol(col)

    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local FsReelDatasIndex = 0
        if self.m_runSpinResultData.p_selfMakeData then -- 添加这段代码是为了加上两个假滚滚轮
            local typeNum = self.m_runSpinResultData.p_selfMakeData.type
            if typeNum  then
                if typeNum == self.m_WILD or  typeNum == self.m_FREESPIN then
                    FsReelDatasIndex = typeNum 
                end
                
            end
        end

        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(FsReelDatasIndex,col)
        if reelDatas == nil then
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
        end
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
    end

    local totalCount = #reelDatas
    local randomType = reelDatas[xcyy.SlotsUtil:getArc4Random() % totalCount + 1]
    
    return randomType
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenQuickHitMachine:showTriggerBonusGameTip(callFun,symbolType)
    gLobalSoundManager:setBackgroundMusicVolume(1)
    
    local animTime = 0
    
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = self.m_iReelRowNum, 1, -1 do
            -- local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
            local targSp =  self:getReelParentChildNode(iCol,iRow)
            if targSp then
                if targSp.p_symbolType == symbolType  then -- 
                    -- animTime = util_max(animTime, targSp:getAniamDurationByName(targSp:getLineAnimName()) ) 
                    targSp:runAnim(targSp:getLineAnimName(),true)
                end
            end

           
        end
    end


    -- 播放提示时播放音效        
    --self:playScatterTipMusicEffect()

    gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_jackPot_Tip.mp3")

    scheduler.performWithDelayGlobal(function()
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = self.m_iReelRowNum, 1, -1 do
                -- local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
                local targSp = self:getReelParentChildNode(iCol,iRow)
                if targSp then
                    if targSp.p_symbolType == symbolType then
                       
                        targSp:runAnim("idleframe")
                    end
                end
    
               
            end
        end
        callFun()
    end,3.5,self:getModuleName())

end

function CodeGameScreenQuickHitMachine:hideLocalReels( )
    -- self.m_root:setOpacity(0)
    local speed = 0.5

    scheduler.performWithDelayGlobal(
    function()

        for iCol = 1, self.m_iReelColumnNum  do
            self.m_slotParents[iCol].slotParent:setVisible(false)
        end
      
    end,
    speed,
    self:getModuleName())
  
end


function CodeGameScreenQuickHitMachine:showLocalReels( )
    
    for iCol = 1, self.m_iReelColumnNum  do
        self.m_slotParents[iCol].slotParent:setVisible(true)
    end
end

function CodeGameScreenQuickHitMachine:addWildToReels( num)
    
    for i = 1, self.m_iReelColumnNum do
        local addSymbols = {}
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local childs = self:getReelParent(i):getChildren()
        local pos = {}
        local addSymbolMaxPos = {}
        for j = 1, #childs do
            local nodeSymbol = childs[j]
            if nodeSymbol.p_rowIndex ~= nil then
                local nodePosY = nodeSymbol:getPositionY()
                if #addSymbolMaxPos == 0 then
                    addSymbolMaxPos.x = nodeSymbol:getPositionX()
                    addSymbolMaxPos.y = nodePosY
                else
                    if addSymbolMaxPos.y < nodePosY then
                        addSymbolMaxPos.x = nodeSymbol:getPositionX()
                        addSymbolMaxPos.y = nodePosY
                    end
                end
            end

            for z = 1, 5 do
                local addSymbol = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                addSymbol:setPosition(cc.p(addSymbolMaxPos.x, addSymbolMaxPos.y + halfH * 2 * z))
                self:getReelParent(i):addChild(addSymbol)
                addSymbol:setVisible(true)
                addSymbol.p_slotNodeH = halfH
                addSymbols[#addSymbols + 1] = addSymbol
            end
        end

    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenQuickHitMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
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


--[[
    @desc: 计算单线
    time:2018-08-16 19:35:49
    --@lineData: 
    @return:
]]
function CodeGameScreenQuickHitMachine:getWinLineSymboltType(winLineData,lineInfo )
    local enumSymbolType = winLineData.p_type
    local iconsPos = winLineData.p_iconPos
    for posIndex=1,#iconsPos do
        local posData = iconsPos[posIndex]
        
        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData  -- 连线元素的 pos信息
            
        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]

    end

    return enumSymbolType
end

function CodeGameScreenQuickHitMachine:lineLogicWinLines( )
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
            
            if lineInfo.iLineSymbolNum >=5 and lineInfo.enumSymbolType < TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE then
                isFiveOfKind=true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end


function CodeGameScreenQuickHitMachine:checkNotifyUpdateWinCoin(ischangeLines )

    local winLines = self.m_reelResultLines
    local coins = self.m_iOnceSpinLastWin
    if ischangeLines then
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.normalLines then
            winLines = self:netWorklineLogicNormalCalculate(self.m_runSpinResultData.p_selfMakeData.normalLines) 
        end
        coins =  self.m_addSpecialCoins
        if winLines == nil or #winLines == 0 then
            return
        end
    end

    
    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end 

    local lastWinCoin = globalData.slotRunData.lastWinCoin
    if ischangeLines then
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
        local curTotalCoin = toLongNumber(globalData.userRunData.coinNum - self.m_iOnceSpinLastWin + self.m_addSpecialCoins)
        globalData.coinsSoundType = 1
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,curTotalCoin)
        globalData.slotRunData.lastWinCoin = self.m_iOnceSpinLastWin  

    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isNotifyUpdateTop}) 
    end 
    
    
end

function CodeGameScreenQuickHitMachine:showLineFrame(ischangeLines)
    local winLines = self.m_reelResultLines

    

    self:clearWinLineEffect()

    if ischangeLines then
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.normalLines then
            winLines = self:netWorklineLogicNormalCalculate(self.m_runSpinResultData.p_selfMakeData.normalLines) 
        end
        
        if winLines == nil or #winLines == 0 then
            return
        end
    end

    
    if self.m_bGetSymbolTime == nil then
        self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期
    end
    
    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin(ischangeLines)

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)
    
    self:clearFrames_Fun()

    
    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            -- self:clearFrames_Fun()
            if frameIndex > #winLines  then
                frameIndex = 1
                if self.m_showLineHandlerID ~= nil then

                    scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                    self.m_showLineHandlerID = nil
                    self:showAllFrame(winLines)
                    self:playInLineNodes()
                    showLienFrameByIndex()
                end
                return
            end
            self:playInLineNodesIdle()
            -- 跳过scatter bonus 触发的连线
            while true do
                if frameIndex > #winLines then
                    break
                end
                -- print("showLine ... ")
                local lineData = winLines[frameIndex]
                
                if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or 
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                    end
                else
                    break
                end
            end
            -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
            -- 所以打上一个判断
            if frameIndex > #winLines  then
                frameIndex = 1
            end

            self:showLineFrameByIndex(winLines,frameIndex)

            frameIndex = frameIndex + 1
    
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
        self:getCurrSpinMode() == FREE_SPIN_MODE then

        self:showAllFrame(winLines)
        if #winLines > 1 then
            showLienFrameByIndex()
        end
    else
         if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines,1)
        end
    end
end

function CodeGameScreenQuickHitMachine:showEffect_LineFrame(effectData,ischangeLines)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    self:showLineFrame(ischangeLines)

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true

end

function CodeGameScreenQuickHitMachine:netWorklineLogicNormalCalculate( winLines)
    local Lines = {}
    local winLines = winLines
    if #winLines > 0 then
        
        for i=1,#winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.icons

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            
            local enumSymbolType = self:getNormalWinLineSymboltType(winLineData,lineInfo)
            
            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.amount / (self.m_runSpinResultData:getBetValue())
            

            Lines[#Lines + 1] = lineInfo
        end

    end

    return Lines
end

--[[
    @desc: 计算单线
    time:2018-08-16 19:35:49
    --@lineData: 
    @return:
]]
function CodeGameScreenQuickHitMachine:getNormalWinLineSymboltType(winLineData,lineInfo )
    local iconsPos = winLineData.icons
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex=1,#iconsPos do
        local posData = iconsPos[posIndex]
        
        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData  -- 连线元素的 pos信息
            
        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            enumSymbolType = symbolType
        end
    end
    return enumSymbolType
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenQuickHitMachine:normalSpinBtnCall()
    --暂停中点击了spin不自动开始下一次
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.normalSpinBtnCall then
                self:normalSpinBtnCall()
            end
        end
        return
    end

    print("触发了 normalspin")

    local time1 = xcyy.SlotsUtil:getMilliSeconds()

    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    if self.m_showLineFrameTime ~= nil then
        if (time1 - self.m_showLineFrameTime) < (self.m_lineWaitTime * 1000) then
            return --时间不到，spin无效
        end
    end

    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    -- 引导打点：进入关卡-4.点击spin
    if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1) then
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 4)
    end
    --新手引导相关
    local isComplete = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskStart1,true)
    if isComplete then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS,{1,false})
    end
    if self.m_isWaitingNetworkData == true then -- 真实数据未返回，所以不处理点击
        return
    end

    local iswait = false
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_selfMakeData.type == self.m_WILD then
            iswait = true
        end
    end

    if iswait == false then
        if self.m_showLineHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_showLineHandlerID)
    
            self.m_showLineHandlerID = nil
        end 
    end
    

    local time2 = xcyy.SlotsUtil:getMilliSeconds()
    release_print("normalSpinBtnCall 消耗时间1 .. " .. (time2 - time1))

    if self:getGameSpinStage() == WAIT_RUN then
        return
    end

    local isWaitCall = self:MachineRule_SpinBtnCall()
    if isWaitCall == false then
        self:callSpinBtn()
    else
        self:setGameSpinStage( WAIT_RUN )
    end

    local timeend = xcyy.SlotsUtil:getMilliSeconds()

    release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")

end

function CodeGameScreenQuickHitMachine:slotReelDown()
    CodeGameScreenQuickHitMachine.super.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
 end
function CodeGameScreenQuickHitMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenQuickHitMachine.super.playEffectNotifyNextSpinCall(self)
end

return CodeGameScreenQuickHitMachine






