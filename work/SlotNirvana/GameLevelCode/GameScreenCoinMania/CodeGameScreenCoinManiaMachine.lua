---
-- island li
-- 2019年1月26日
-- CodeGameScreenCoinManiaMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CoinManiaSlotsNode = require "CodeCoinManiaSrc.CoinManiaSlotsNode"

local CodeGameScreenCoinManiaMachine = class("CodeGameScreenCoinManiaMachine", BaseFastMachine)

CodeGameScreenCoinManiaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenCoinManiaMachine.COINMANIA_PIG_FLY_COINS_DI_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenCoinManiaMachine.COINMANIA_PIG_FLY_COINS_MID_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenCoinManiaMachine.COINMANIA_PIG_ADD_COINS_DI_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识


-- CodeGameScreenCoinManiaMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_Bonus = 96  -- 金猪
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X2 = 101  -- wild 翻倍
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X3 = 102  
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X4 = 103 
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X5 = 104  
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X6 = 105 
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X8 = 106
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X9 = 107
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X15 = 108
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X16 = 109
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X20 = 110
CodeGameScreenCoinManiaMachine.SYMBOL_PIG_WILD_X21 = 112  

CodeGameScreenCoinManiaMachine.m_CoinsFlyTimes = 0 -- 金猪从进币池飞金币循环计数
CodeGameScreenCoinManiaMachine.m_CoinsFlyToWildTimes = 0 -- 金猪底飞金币变成Wild循环计数
CodeGameScreenCoinManiaMachine.m_PigHitCoinsFlyTimes = 0 -- 金猪从轮盘飞金币循环计数
CodeGameScreenCoinManiaMachine.m_roandCutindex = 0 -- 金猪从轮盘飞金币分割位置

CodeGameScreenCoinManiaMachine.m_FiveCoinsDi = {} 

CodeGameScreenCoinManiaMachine.m_flyPigCoins = {} 
CodeGameScreenCoinManiaMachine.m_LockWild = {}
CodeGameScreenCoinManiaMachine.m_actNodeFsAddPig = {}

CodeGameScreenCoinManiaMachine.m_gameTypeJp = 1
CodeGameScreenCoinManiaMachine.m_gameTypeFs = 2

CodeGameScreenCoinManiaMachine.m_WildDi_Nil = -1
CodeGameScreenCoinManiaMachine.m_WildDi_One = 0
CodeGameScreenCoinManiaMachine.m_WildDi_Two = 1
CodeGameScreenCoinManiaMachine.m_WildDi_Three = 2
CodeGameScreenCoinManiaMachine.m_WildDi_Four = 3
CodeGameScreenCoinManiaMachine.m_WildDi_Five = 4
CodeGameScreenCoinManiaMachine.m_WildDi_Six = 5

CodeGameScreenCoinManiaMachine.m_reelRunAnimaBG = nil

CodeGameScreenCoinManiaMachine.nodeBgList = {}
CodeGameScreenCoinManiaMachine.m_initActionFlyNode = {{},{},{},{},{}}

CodeGameScreenCoinManiaMachine.m_isTriggerAddCoins = false
CodeGameScreenCoinManiaMachine.m_ActInfo = {}

CodeGameScreenCoinManiaMachine.m_isOutLine = true

-- 构造函数
function CodeGameScreenCoinManiaMachine:ctor()
    BaseFastMachine.ctor(self)


    self.m_FiveCoinsDi = {} 
    self.m_CoinsFlyTimes = 0
    self.m_CoinsFlyToWildTimes = 0
    self.m_PigHitCoinsFlyTimes = 0 
    self.m_roandCutindex = 0

    self.m_flyPigCoins = {} 
    self.m_LockWild = {}
    self.m_actNodeFsAddPig = {}
    self.m_fsReelDataIndex = 0
    self.m_reelRunAnimaBG = {}
    self.nodeBgList = {}
    self.m_initActionFlyNode = {{},{},{},{},{}}
    self.m_ActInfo = {}

    self.m_isTriggerAddCoins = false

    self.m_isOutLine = true
    self.isInBonus = false
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenCoinManiaMachine:setScatterDownScound( )

    local soundPath = "CoinManiaSounds/CoinMania_scatter_down.mp3"
    local bonusPath = "CoinManiaSounds/CoinMania_Bonus_down.mp3"
   
    self.m_scatterBulingSoundArry["auto"] = soundPath
    self.m_bonusBulingSoundArry["auto"] = bonusPath
end



function CodeGameScreenCoinManiaMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("CoinManiaConfig.csv", "LevelCoinManiaConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCoinManiaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CoinMania"  
end

function CodeGameScreenCoinManiaMachine:getNetWorkModuleName( )
    return "CoinMania"  
end

function CodeGameScreenCoinManiaMachine:initFiveCoinsDi( )
    

    self.m_FiveCoinsDi = {} 
    local csbName = {"CoinMania_wilds_W","CoinMania_wilds_I","CoinMania_wilds_L","CoinMania_wilds_D","CoinMania_wilds_S"}
    local parentName = {"wilds_w","wilds_i","wilds_l","wilds_d","wilds_s"}
    
    for i=1,5 do
        local wildDi = util_createAnimation(csbName[i]..".csb")
        self:findChild(parentName[i]):addChild(wildDi)
        table.insert(self.m_FiveCoinsDi,wildDi)
    end
end

function CodeGameScreenCoinManiaMachine:initUI()


    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")

    self:initFreeSpinBar() -- FreeSpinbar

    self:initFiveCoinsDi( )

    self.m_BigGoldPigBG = util_createAnimation("CoinMania_jinbidui.csb")
    self:findChild("jinbidui"):addChild(self.m_BigGoldPigBG)
    self.m_BigGoldPigBG:runCsbAction("idle1",true)

    self.m_BigGoldPigBG_1 = util_createAnimation("CoinMania_jinbidui_0.csb")
    self:findChild("jinzhu"):addChild(self.m_BigGoldPigBG_1, 100)


    self.m_pigCoinsFlyActBg = util_createAnimation("GameScreenCoinMania_0.csb")
    self:findChild("Node_CoinsAct"):addChild(self.m_pigCoinsFlyActBg)
    self.m_pigCoinsFlyActBg:setVisible(false)
    
    
    self.m_BigGoldPig = util_spineCreate("Socre_CoinMania_Pig",true,true)
    self:findChild("jinzhu"):addChild(self.m_BigGoldPig)
    util_spinePlay(self.m_BigGoldPig,"idleframe",true)
    
    
    self.m_JackPotBar = util_createView("CodeCoinManiaSrc.CoinManiaJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotBar)
    self.m_JackPotBar:initMachine(self)

    self.m_FsBar = util_createView("CodeCoinManiaSrc.CoinManiaFreespinBarView")
    self:findChild("fs_cishu"):addChild(self.m_FsBar)
    self.m_baseFreeSpinBar = self.m_FsBar
    self.m_baseFreeSpinBar:setVisible(false)

    
    self.p_ViewGuoChangLayer = cc.Layer:create()
    self:addChild(self.p_ViewGuoChangLayer,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_GuoChang = util_spineCreate("CoinMania_zhuanchang",true,true)
    self.p_ViewGuoChangLayer:addChild(self.m_GuoChang)
    self.m_GuoChang:setPosition(display.cx,display.height/2)
    self.m_GuoChang:setScale(display.height / 1536)
    self.p_ViewGuoChangLayer:setVisible(false)
    -- self.p_ViewGuoChangLayer:onTouch( function() return true end, false, true)

    -- 创建view节点方式
    -- self.m_CoinManiaView = util_createView("CodeCoinManiaSrc.CoinManiaView")
    -- self:findChild("xxxx"):addChild(self.m_CoinManiaView)

    self.m_JpGameChoose = util_createView("CodeCoinManiaSrc.CoinManiaJpGameChooseView",self)
    self:findChild("GameView"):addChild(self.m_JpGameChoose)
    self.m_JpGameChoose:setVisible(false)

    self:findChild("node_jpShow"):setVisible(false)

    self.m_TipView = util_createAnimation("CoinMania_FS_PayTable.csb")
    self:findChild("Node_tip"):addChild(self.m_TipView)
    self.m_TipView:runCsbAction("idle",true)
    
   
 
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        
        local isAnim = params[5]
        if isAnim then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
            soundTime = 2
        elseif winRate > 6 then
            soundIndex = 3
            soundTime = 2
        end

        if winRate >= self.m_HugeWinLimitRate then
            self.m_BigGoldPigBG:runCsbAction("start")
            self.m_BigGoldPigBG_1:runCsbAction("start")
            util_spinePlay(self.m_BigGoldPig,"idleframe4",true)
            self.m_BigGoldPig.m_BigWinIdle = true
            
        elseif winRate >= self.m_MegaWinLimitRate then
                self.m_BigGoldPigBG:runCsbAction("start")
                self.m_BigGoldPigBG_1:runCsbAction("start")
                util_spinePlay(self.m_BigGoldPig,"idleframe4",true)
                self.m_BigGoldPig.m_BigWinIdle = true
            
        elseif winRate >= self.m_BigWinLimitRate then
                self.m_BigGoldPigBG:runCsbAction("start")
                self.m_BigGoldPigBG_1:runCsbAction("start")
                util_spinePlay(self.m_BigGoldPig,"idleframe4",true)
                self.m_BigGoldPig.m_BigWinIdle = true
        elseif winRate >= 3 then
                self.m_BigGoldPigBG:runCsbAction("start")
                self.m_BigGoldPigBG_1:runCsbAction("start")
                util_spinePlay(self.m_BigGoldPig,"idleframe4",true)
                self.m_BigGoldPig.m_BigWinIdle = true
        end

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}

        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE  then
            print("freespin最后一次 无论是否大赢都播放赢钱音效")
        else
            if winRate >= self.m_HugeWinLimitRate then
                return
            elseif winRate >= self.m_MegaWinLimitRate then
                return
            elseif winRate >= self.m_BigWinLimitRate then
                return
            end
        end

        local soundName = "CoinManiaSounds/music_CoinMania_last_win_".. soundIndex .. ".mp3"        
        globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenCoinManiaMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenCoinManiaMachine:showGuoChang( fuc1 , func2 )
    
    
    gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_GuoChang.mp3")
    

    self.p_ViewGuoChangLayer:setVisible(true)

    util_spinePlay(self.m_GuoChang,"animation",false)

    util_spineFrameCallFunc(self.m_GuoChang, "animation", "Zha", function(  )
        if fuc1 then
            fuc1()
        end
    end,function(  )

        if func2 then
            func2()
        end

        self.p_ViewGuoChangLayer:setVisible(false)
    end)
       

end

function CodeGameScreenCoinManiaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()


    if self.m_BigGoldPig then
        
        util_spinePlay(self.m_BigGoldPig,"buling")

        util_spineFrameCallFunc(self.m_BigGoldPig, "buling", "Down2", function(  )
            self:shakeBaseNode()
        end,function(  )
            util_spinePlay(self.m_BigGoldPig,"idleframe",true)
        end)

    end
    

end

function CodeGameScreenCoinManiaMachine:addObservers()
    BaseFastMachine.addObservers(self)

end

function CodeGameScreenCoinManiaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_fsReelDataIndex = 0

    -- 移除掉nodebg定时器
    for i=1,#self.nodeBgList do
        local actNodeBg = self.nodeBgList[i]
        if actNodeBg.m_updateCoinHandlerID then
            scheduler.unscheduleGlobal(actNodeBg.m_updateCoinHandlerID)
        end
    end

    for i, v in pairs(self.m_reelRunAnimaBG) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnimaBG[i] = v
    end

    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCoinManiaMachine:MachineRule_GetSelfCCBName(symbolType)




    if symbolType == self.SYMBOL_PIG_Bonus then
        return "Socre_CoinMania_Bonus"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        return "Socre_CoinMania_jackpot"
    elseif symbolType == self.SYMBOL_PIG_WILD_X2 then 
        return "Socre_CoinMania_wild_X2"
    elseif symbolType == self.SYMBOL_PIG_WILD_X3 then
        return "Socre_CoinMania_wild_X3"
    elseif symbolType == self.SYMBOL_PIG_WILD_X4 then 
        return "Socre_CoinMania_wild_X4"
    elseif symbolType == self.SYMBOL_PIG_WILD_X5 then 
        return "Socre_CoinMania_wild_X5"
    elseif symbolType == self.SYMBOL_PIG_WILD_X6 then  
        return "Socre_CoinMania_wild_X6"
    elseif symbolType == self.SYMBOL_PIG_WILD_X8 then 
        return "Socre_CoinMania_wild_X8"
    elseif symbolType == self.SYMBOL_PIG_WILD_X9 then 
        return "Socre_CoinMania_wild_X9"
    elseif symbolType == self.SYMBOL_PIG_WILD_X15 then
        return "Socre_CoinMania_wild_X15"
    elseif symbolType == self.SYMBOL_PIG_WILD_X16 then  
        return "Socre_CoinMania_wild_X16"
    elseif symbolType == self.SYMBOL_PIG_WILD_X20 then 
        return "Socre_CoinMania_wild_X20"
    elseif symbolType == self.SYMBOL_PIG_WILD_X21 then 
        return "Socre_CoinMania_wild_X21"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCoinManiaMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_Bonus,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X8,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X9,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X15,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X16,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X20,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_PIG_WILD_X21,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCoinManiaMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        -- 自定义事件修改背景动画
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
    
        self.m_TipView:setVisible(false)

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData then
            if fsExtraData.extraBonus then
                self.m_fsReelDataIndex = 1
            end
            
        end
    end
    
end


---
-- 老虎机滚动结束调用
function CodeGameScreenCoinManiaMachine:slotReelDown()

    

    BaseFastMachine.slotReelDown(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end


function CodeGameScreenCoinManiaMachine:playEffectNotifyNextSpinCall( )

    BaseFastMachine.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)




end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenCoinManiaMachine:specialSymbolActionTreatment( node )
    -- local targSp = self:setSpecialSymbolToClipReel(node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType)
    node:runAnim("buling",false)

end

function CodeGameScreenCoinManiaMachine:playSpecialSymbolDownAct( slotNode )

    if slotNode.p_symbolType and slotNode.p_symbolType == self.SYMBOL_PIG_Bonus then
            
        slotNode.p_reelDownRunAnimaSound = "CoinManiaSounds/music_CoinMania_pigSymbol_Down.mp3"
        slotNode.p_reelDownRunAnima = "buling"
    end

    self:playCustomSpecialSymbolDownAct(slotNode)

    
    for i=1,#self.nodeBgList do
        local actNodeBg = self.nodeBgList[i]
        if actNodeBg.m_isMoveDown == false  then
            util_playFadeOutAction(actNodeBg:getParent(),0.5)
        end
        
    end
end


---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCoinManiaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCoinManiaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"actionframe2")

   
    
end
---------------------------------------------------------------------------

-- -- - - - - - - - - - - - - - 

-- 触发特殊玩法时的处理
function CodeGameScreenCoinManiaMachine:getBonusGameType( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freespinBonus = selfdata.freespinBonus 
    local jackpotBonus = selfdata.jackpotBonus 

    if freespinBonus then
        return self.m_gameTypeFs
    end

    if jackpotBonus then
        return self.m_gameTypeJp  
    end

end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenCoinManiaMachine:showEffect_Bonus(effectData)


    -- 停止播放背景音乐
    self:clearCurMusicBg()
    
    self.isInBonus = true

    local showBonusFunc = function(  )
        

        if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
            self.m_questView:hideQuestView()
        end
    
        if self.m_winSoundsId ~= nil then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
    
        local curType = GameEffect.EFFECT_BONUS
        if self:getBonusGameType( ) == self.m_gameTypeFs  then
            curType = GameEffect.EFFECT_FREE_SPIN
        end
    
        -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
        local lineLen = #self.m_reelResultLines
        local bonusLineValue = nil
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == curType then
                bonusLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end
    
        -- 停止播放背景音乐
        self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        -- 播放bonus 元素不显示连线
        if bonusLineValue ~= nil then
            self:showBonusAndScatterLineTip(bonusLineValue,function()
                self:showBonusGameView(effectData)
            end)
            bonusLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
    
            -- 播放提示时播放音效
            self:playBonusTipMusicEffect()
        else
            self:showBonusGameView(effectData)
        end
    
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    end
    
    local waitTime = 0

    if self.m_isTriggerAddCoins then
        self.m_isTriggerAddCoins = false
        
        local winLines = self.m_reelResultLines

        if winLines and #winLines > 0 then
            waitTime = self.m_changeLineFrameTime or 3  --连线框播放时间

            scheduler.performWithDelayGlobal(function (  )
                showBonusFunc()
            end,waitTime,self:getModuleName())
        else
            showBonusFunc()
        end
    else
        
        showBonusFunc()

    end

    

    

    return true
end

--播放bonus tip music
function CodeGameScreenCoinManiaMachine:playBonusTipMusicEffect()

    self.m_BonusTipMusicPath = "CoinManiaSounds/music_CoinMania_Jptrigger_tip.mp3"
    if self:getBonusGameType( ) == self.m_gameTypeFs  then
        self.m_BonusTipMusicPath = "CoinManiaSounds/music_CoinMania_Fstrigger_tip.mp3"
    end


    if self.m_BonusTipMusicPath ~= nil then
        gLobalSoundManager:playSound(self.m_BonusTipMusicPath)
    end
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenCoinManiaMachine:showBonusAndScatterLineTip(lineValue,callFun)
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
        if slotNode == nil then
            slotNode = self.m_clipParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
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

function CodeGameScreenCoinManiaMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)

    animTime = 120/30
    if self:getBonusGameType( ) == self.m_gameTypeFs  then
        animTime = 160/30

        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
        
    end

    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()

        local nodeLen = #self.m_lineSlotNodes

        for lineNodeIndex = nodeLen, 1, -1 do
            local lineNode = self.m_lineSlotNodes[lineNodeIndex]
            -- node = lineNode
            if lineNode ~= nil then -- TODO 打的补丁， 临时这样
                local preParent = lineNode.p_preParent
                if preParent ~= nil then  
                    lineNode:runIdleAnim()
                end
            end
        end

        local idleTime = 1.5
        if self:getBonusGameType( ) == self.m_gameTypeFs  then
            animTime = 0.5
        end

        scheduler.performWithDelayGlobal(function(  )
            self:resetMaskLayerNodes() 
        end,idleTime,self:getModuleName())
        
        callFun()
    end,util_max(2,animTime),self:getModuleName())
end

function CodeGameScreenCoinManiaMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                lineNode:removeFromParent()
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end


                if (lineNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS ) or (lineNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                preParent:addChild(lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
            end
        end
    end
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenCoinManiaMachine:showBonusGameView(effectData)
    -- effectData.p_isPlay = true
    -- self:playGameEffect() -- 播放下一轮

    

    if self:getBonusGameType( ) == self.m_gameTypeFs  then

        self:showGuoChang( function(  )

            self:createFsGameChooseView( function(  )
            
                self:checkLocalGameNetDataFeatures()
                self:restSelfGameEffects( GameEffect.EFFECT_BONUS  )
                
            end )

        end)

        
    else
        self:createJpGameChooseView( function(  )


            self:checkLocalGameNetDataFeatures()
            self:restSelfGameEffects( GameEffect.EFFECT_BONUS  )
            

        end,true)
    end
    


   

    
    

end

---
-- 自己添加freespin 或bonus事件
--
function CodeGameScreenCoinManiaMachine:checkLocalGameNetDataFeatures()

    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})

            -- self:sortGameEffects( )
            -- self:playGameEffect()
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- self:sortGameEffects( )
            -- self:playGameEffect()


        end
    end

end

----------- FreeSpin相关

-- 更新控制类数据
function CodeGameScreenCoinManiaMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end

---
-- 显示free spin
-- function CodeGameScreenCoinManiaMachine:showEffect_FreeSpin(effectData)
--     self.isInBonus = true
    
--     return BaseFastMachine.showEffect_FreeSpin(self,effectData)
-- end
--重写 去底层震动
function CodeGameScreenCoinManiaMachine:showEffect_FreeSpin(effectData)
    self.isInBonus = true

    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    -- if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
    --     -- freeMore时不播放
    --     self:levelDeviceVibrate(6, "free")
    -- end
    
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

-- FreeSpinstart
function CodeGameScreenCoinManiaMachine:showFreeSpinView(effectData)

    

    gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_fs_StartView.mp3")


    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            self.m_baseFreeSpinBar:setVisible(true)
            self.m_TipView:setVisible(false)
            self.m_baseFreeSpinBar:updateFreespinCount( self.m_iFreeSpinTimes,self.m_iFreeSpinTimes )
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"actionframe1")

            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                    

                    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
                    if fsExtraData then
                        if fsExtraData.extraBonus then
                            self.m_fsReelDataIndex = 1
                        end
                        
                    end
                    
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()  
                    

                         
            end)

            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local totalPigs = selfdata.totalPigs or 0
            view:findChild("m_lb_num2"):setString(totalPigs)
            view:findChild("Particle_1_0"):resetSystem()
            view:findChild("Particle_1"):resetSystem()
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFSView()    
    end,0.5)

    

end

function CodeGameScreenCoinManiaMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Fs_Over.mp3")

    performWithDelay(self,function(  )

        gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_JackPotWinShow.mp3")

        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
    
            self.m_fsReelDataIndex = 0
    
            self:showGuoChang( function(  )

                self.m_TipView:setVisible(true)

                
            end,function(  )
                self:triggerFreeSpinOverCallFun()
            end)
    
            
        end)
    
        view:findChild("Particle_1_0"):resetSystem()
        view:findChild("Particle_1"):resetSystem()
    
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.05,sy=1.05},468)
    end,1.5)
  

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCoinManiaMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    self.isInBonus = false

    self.m_isOutLine = false

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    for i=1,#self.nodeBgList do
        local actNodeBg = self.nodeBgList[i]

        if not actNodeBg.m_isMoveDown  then
            util_playFadeInAction(actNodeBg:getParent(),0.1)
        end
        
    end

    self:restLockWildLayerTag( )

    self:removeAllFlyPigCoins( )

    self:removeAllfsAddPigNode( )

    if self.m_BigGoldPig and self.m_BigGoldPig.m_BigWinIdle  then
        util_spinePlay(self.m_BigGoldPig,"idleframe",true)
        self.m_BigGoldPig.m_BigWinIdle = nil
    end

    self.m_BigGoldPigBG:runCsbAction("idle1",true)
    self.m_BigGoldPigBG_1:runCsbAction("idle1")

    self.m_isTriggerAddCoins = false


    if self.m_pigCoinsFlyActBg:isVisible() then

        self.m_pigCoinsFlyActBg:runCsbAction("over",false,function(  )
            self.m_pigCoinsFlyActBg:setVisible(false)
        end)
    end
    
    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenCoinManiaMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenCoinManiaMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCoinManiaMachine:addSelfEffect()

        
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinCounts = selfdata.coinCounts or {}
    local hitCoinWildPositions = selfdata.hitCoinWildPositions or {}
    local hitBotPositions = selfdata.hitBotPositions or {}

    -- 顺序播放

    if self:CheckIsTriggerPigHitCoinsToWildDiFly( hitBotPositions  ) then
        --自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 3
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COINMANIA_PIG_ADD_COINS_DI_EFFECT -- 猪飞金币填满空的底类型

        -- 在这里单独处理一下 coinCounts 
        -- 因为触发了猪会把 coinCounts 里-1 的位置填上 变成 0
        for i=1,#coinCounts do
            if self.m_runSpinResultData.p_selfMakeData.coinCounts[i] == self.m_WildDi_Nil then
                self.m_runSpinResultData.p_selfMakeData.coinCounts[i] = self.m_WildDi_One
            end
        end

        self.m_isTriggerAddCoins = true

    end

    
    if self:CheckIsTriggerPigCoinsToWildFly( coinCounts ) then
        --自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COINMANIA_PIG_FLY_COINS_DI_EFFECT -- 下板飞金币类型

        self.m_isTriggerAddCoins = true
    end

    if self:CheckIsTriggerPigHitCoinsFly( hitCoinWildPositions  ) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COINMANIA_PIG_FLY_COINS_MID_EFFECT -- 轮盘猪飞金币类型

        self.m_isTriggerAddCoins = true
    end
    

    
        

end




function CodeGameScreenCoinManiaMachine:restSelfGameEffects( restType ,isSelfType  )

    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects , 1 do

            local effectData = self.m_gameEffects[i]
    
            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_effectType
                if isSelfType then
                    effectType = effectData.p_selfEffectType
                end

                if effectType == restType then

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return 
                end
                
            end

        end
    end
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCoinManiaMachine:MachineRule_playSelfEffect(effectData)

    
    if effectData.p_selfEffectType == self.COINMANIA_PIG_ADD_COINS_DI_EFFECT then
        

        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbolTrigger.mp3")
        local pigBonusPos =  self:getGoldPigBonusIndex()
        local fixPos = self:getRowAndColByPos(pigBonusPos)
        self.m_pigBonusSp = self:setSymbolToClipReel(fixPos.iY, fixPos.iX, self.SYMBOL_PIG_Bonus)
        self.m_pigBonusSp:runAnim("actionframe5",false,function(  )

            gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbol_addCoins_toDi.mp3")

            self.m_pigBonusSp:runAnim("actionframe7",false,function(  )
                self.m_pigBonusSp:runAnim("actionframe6",true)
            end)

            scheduler.performWithDelayGlobal(function (  )
                self:beginPigCoinsFlyCoinsToDiAction( )
            end,7/30,self:getModuleName())
        end)

        

    elseif effectData.p_selfEffectType == self.COINMANIA_PIG_FLY_COINS_DI_EFFECT then

        
        if not self.m_addCoinsGameBg then
            self.m_addCoinsGameBg =  gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_addCoinsGameBg.mp3",true)
        end
      
        gLobalSoundManager:setBackgroundMusicVolume(0)

        self.m_CoinsFlyToWildTimes = self:getMaxActTimes()
        self.m_pigCoinsFlyActBg:setVisible(true)
        self.m_pigCoinsFlyActBg:runCsbAction("actionframe",false,function(  )
            self.m_pigCoinsFlyActBg:runCsbAction("actionframe1",true)
            
            self:initDiActNodeList( )

            self:beginPigCoinsFlyToWildAction(  )
        end)
        


    elseif effectData.p_selfEffectType == self.COINMANIA_PIG_FLY_COINS_MID_EFFECT then


        local currFunc = function(  )
            
            self.m_roandCutindex = math.random(2,4)

                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                local coinCounts = selfdata.coinCounts or {}
                local hitCoinWildPositions = selfdata.hitCoinWildPositions or {}
                local hitBotPositions = selfdata.hitBotPositions or {}
        
        
                if self:CheckIsTriggerPigHitCoinsToWildDiFly( hitBotPositions  ) then
        
                    gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbol_Pig_to_reel.mp3")
        
                    self.m_pigBonusSp:runAnim("actionframe7",false,function(  )
                        self.m_pigBonusSp:runAnim("actionframe6",true)
        
        
                    end)
        
                    scheduler.performWithDelayGlobal(function (  )
                        self:beginPigHitCoinsAction(  )
                    end,7/30,self:getModuleName())
                    
                else
                    
                    
                    gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbolTrigger.mp3")
                    local pigBonusPos =  self:getGoldPigBonusIndex()
                    local fixPos = self:getRowAndColByPos(pigBonusPos)
                    self.m_pigBonusSp = self:setSymbolToClipReel(fixPos.iY, fixPos.iX, self.SYMBOL_PIG_Bonus)
                    self.m_pigBonusSp:runAnim("actionframe5",false,function(  )
        
                        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbol_Pig_to_reel.mp3")
        
                        self.m_pigBonusSp:runAnim("actionframe7",false,function(  )
                            self.m_pigBonusSp:runAnim("actionframe6",true)
                            
                        end)
        
                        scheduler.performWithDelayGlobal(function (  )
                            self:beginPigHitCoinsAction(  )
                        end,7/30,self:getModuleName())
                        
                    end)
                end
        end

        if self.m_pigCoinsFlyActBg:isVisible() then
            self.m_pigCoinsFlyActBg:runCsbAction("actionframe1",true)
            self.m_pigCoinsFlyActBg:setVisible(true)
            currFunc()
        else
            
            if not self.m_addCoinsGameBg then
                self.m_addCoinsGameBg =  gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_addCoinsGameBg.mp3",true)
            end
           
            gLobalSoundManager:setBackgroundMusicVolume(0)

            self.m_pigCoinsFlyActBg:setVisible(true)
            self.m_pigCoinsFlyActBg:runCsbAction("actionframe",false,function(  )
                self.m_pigCoinsFlyActBg:runCsbAction("actionframe1",true)
                
                currFunc()
                
            end)

        end

        
      

       

    end
 
	return true
end


function CodeGameScreenCoinManiaMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
 
end

function CodeGameScreenCoinManiaMachine:showJackpotWinView(index,coins,func)
    
    
    local jackPotWinView = util_createView("CodeCoinManiaSrc.CoinManiaJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)

    local curCallFunc = function(  )

        if func then
            func()
        end
    end

    jackPotWinView:initViewData(index,coins,curCallFunc)

    jackPotWinView:findChild("Particle_1_0"):resetSystem()
    jackPotWinView:findChild("Particle_1"):resetSystem()

end


---
--设置bonus scatter 层级
function CodeGameScreenCoinManiaMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_PIG_Bonus then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 
    elseif symbolType == self.SYMBOL_PIG_WILD_X2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X4 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X5 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X6 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X8 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X9 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X15 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X16 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X20 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_PIG_WILD_X21 then
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

function CodeGameScreenCoinManiaMachine:shakeBaseNode( playType )


    local changePosY = 4
    local actionList2={}
    local oldPos = cc.p(self:findChild("BaseReel"):getPosition())
    
    actionList2[#actionList2+1]=cc.MoveTo:create(3/30,cc.p(oldPos.x  ,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(3/30,cc.p(oldPos.x,oldPos.y))
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("BaseReel"):runAction(seq2)

end

function CodeGameScreenCoinManiaMachine:updateNetWorkData()

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

    self:PigCoinsCollect( )

end



function CodeGameScreenCoinManiaMachine:CheckIsTriggerPigFly( coinCounts  )
    
    
    for k,v in pairs(coinCounts) do
        if v ~= self.m_WildDi_Nil then
            return true
        end
    end

    return false

end

function CodeGameScreenCoinManiaMachine:getWildBetAndReelPosNotTrigger( icol,index )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinWildPositions = selfdata.coinMultiplies or {}
    local colInfo  = coinWildPositions[icol]
    if colInfo then
        local pairNum = 0
        for k,v in pairs(colInfo) do
            pairNum = pairNum + 1
            local posIndex = tonumber(k)
            local betNum = v
            if index == pairNum then
                return posIndex,betNum
            end
        end
    end
end

function CodeGameScreenCoinManiaMachine:getWildBetAndReelPos( icol,index )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinWildPositions = selfdata.coinWildPositions or {}
    local colInfo  = coinWildPositions[icol]
    if colInfo then
        local pairNum = 0
        for k,v in pairs(colInfo) do
            pairNum = pairNum + 1
            local posIndex = tonumber(k)
            local betNum = v
            if index == pairNum then
                return posIndex,betNum
            end
        end
    end



end

function CodeGameScreenCoinManiaMachine:removeAllFlyPigCoinsAct( node,deTime,callback,addpos )

    local currNode = node

    local actionList={}
    
    if addpos and addpos > 0 then
        actionList[#actionList+1]=cc.DelayTime:create(deTime )
        actionList[#actionList+1]=cc.CallFunc:create(function(  )
            local pos = cc.p(currNode:getPosition())
            local actionList_1={}
            actionList_1[#actionList_1+1]=cc.MoveTo:create(0.05,cc.p(pos.x,pos.y - addpos))
            local seq_1=cc.Sequence:create(actionList_1)
            currNode:runAction(seq_1)
        end)
        actionList[#actionList+1]=cc.DelayTime:create(0.05 )
    else
        actionList[#actionList+1]=cc.DelayTime:create(deTime)
    end
    
    actionList[#actionList+1]=cc.ScaleTo:create(0.1,0.01)
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
       if callback then
            callback()
       end
    end)
    local seq=cc.Sequence:create(actionList)
    currNode:runAction(seq)
end

function CodeGameScreenCoinManiaMachine:removeAllFlyPigCoins( )
    
    for i = #self.m_flyPigCoins,1,-1 do
        local coins = self.m_flyPigCoins[i]
        if coins then
            local coinsNode = coins
            if coinsNode:isVisible() then
                local timeBet = coinsNode.runtimes or 1
                local addPos = coinsNode.addPos
                local deTimes = timeBet * 0.05 -- 这个时间不能小于0.02
                self:removeAllFlyPigCoinsAct( coinsNode,deTimes,function(  )
                    coinsNode:getParent():removeFromParent()
                end ,addPos)

            else
                coinsNode:getParent():removeFromParent()
            end
            
        end
        table.remove(self.m_flyPigCoins,i)
    end
end

function CodeGameScreenCoinManiaMachine:playMoveToAction(node,time,pos,callback,type,isHide,isToDi,isplaysound)
    local actionList={}
    local flyTime = 1
    local waitTimes = time - flyTime

    local soundPlay = isplaysound
    type = "easyInOut"

    local todi = isToDi

    if isHide then
        node:setVisible(false)
    end
    

    actionList[#actionList + 1] = cc.DelayTime:create(waitTimes)
    actionList[#actionList+1]=cc.CallFunc:create(function(  )

        if soundPlay then
            gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbol_Di_to_reel.mp3")
        end
        

         local curNode = node
         node:setVisible(true)
        local seq_1 =cc.Sequence:create(cc.CallFunc:create(function(  )
            if curNode:getParent() then
                curNode:runCsbAction("actionframe1")
            end
            
        end))
        curNode:runAction(seq_1)
        
     end)

    if type == "easyInOut" then
        -- actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveTo:create(flyTime,pos),1)
        actionList[#actionList + 1] = cc.EaseOut:create(cc.JumpTo:create(flyTime,pos,200,1),1)
    else
        actionList[#actionList+1]=cc.MoveTo:create(flyTime,pos)
    end
    if todi then
        actionList[#actionList+1]=cc.CallFunc:create(function(  )
            local curNode = node
           local seq_1 =cc.Sequence:create(cc.CallFunc:create(function(  )
               if curNode:getParent() then
                local curNode_1 = curNode
                   curNode:runCsbAction("buling",false,function(  )
                        curNode_1:runCsbAction("idleframe",true)
                   end)
               end
               
           end))
           curNode:runAction(seq_1)
           
        end)
    end
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
       if callback then
            callback()
       end
    end)
    local seq=cc.Sequence:create(actionList)
    node:runAction(seq)
end

function CodeGameScreenCoinManiaMachine:playMoveToAction_One(node,time,pos,callback,type)
    local actionList={}
    local flyTime = 23/30
    local waitTimes = time - flyTime
    local downTimes = 22/30

    type = "easyInOut"

    node:setVisible(false)
    actionList[#actionList + 1] = cc.DelayTime:create(waitTimes)
    actionList[#actionList+1]=cc.CallFunc:create(function(  )

        

         local curNode = node
         node:setVisible(true)
        local seq_1 =cc.Sequence:create(cc.CallFunc:create(function(  )
            if curNode:getParent() then
                local curNode_1 = curNode
                
                curNode:runCsbAction("actionframe",false,function(  )

                    if self.m_flyPigCoins and #self.m_flyPigCoins > 0 then
                        if self.m_flyPigCoins[curNode_1.arrayIndex] then
                            if not self.m_flyPigCoins[curNode_1.arrayIndex].quickStop then
                                curNode_1:runCsbAction("idleframe",true)
                            end
                        end
                       
                    end
                end)

            end
            
        end))
        curNode:runAction(seq_1)
        
    end)

    if type == "easyInOut" then
        -- actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveTo:create(flyTime,pos),1)
        actionList[#actionList + 1] = cc.EaseOut:create(cc.JumpTo:create(flyTime,pos,100,1),1)
    else
        actionList[#actionList+1]=cc.MoveTo:create(flyTime,pos);
    end
    actionList[#actionList+1]=cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Coins_pool_luoDi.mp3")

       if callback then
            callback()
       end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(downTimes)
    local seq=cc.Sequence:create(actionList)
    node:runAction(seq)
end

function CodeGameScreenCoinManiaMachine:getMaxActTimes( )

    local maxTimes = 0

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinCounts = selfdata.coinCounts or {}

    while true do
        maxTimes = maxTimes + 1
        local stopWhile = true
        for k,v in pairs(coinCounts) do
            local coinsNum = v
            local col = k
            if (coinsNum - maxTimes) > self.m_WildDi_Nil then
                stopWhile = false
                break
            end
        end

        if stopWhile  then
            break  
        end
    end
    

    return maxTimes
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- 猪从金币池落下 相关

function CodeGameScreenCoinManiaMachine:stopflyPigCoinsAndRestPos( )
    
    if self.m_flyPigCoins then
        local isLuoDi = false
        for i=1,#self.m_flyPigCoins do
            local coinsNode = self.m_flyPigCoins[i]
            local pos = cc.p(coinsNode:getPosition())
            if not (coinsNode.endPos.x == pos.x and coinsNode.endPos.y == pos.y)   then
                coinsNode:setVisible(true)
                coinsNode:stopAllActions()
                coinsNode:setPosition(coinsNode.endPos.x,coinsNode.endPos.y)
                coinsNode:runCsbAction("idleframe",true)  
                self.m_flyPigCoins[i].quickStop = true

                isLuoDi = true
            end
        end

        if isLuoDi then
            gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Coins_pool_luoDi.mp3")
        end
    end
    
end

function CodeGameScreenCoinManiaMachine:beginPigCoinsFlyAction(  )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinCounts = selfdata.coinCounts or {}

    local actionCol = {}
    for k,v in pairs(coinCounts) do
        local coinsNum = v
        local col = k
        if (coinsNum - self.m_CoinsFlyTimes) > self.m_WildDi_Nil then
            table.insert(actionCol,col)
        end
    end

    self.m_CoinsFlyTimes = self.m_CoinsFlyTimes + 1
    if #actionCol == 0  then
        
        self.m_CoinsFlyTimes = 0
        local colAddNum = math.random(2,4)
        local colList = {1,2,3,4,5}
        local colAddList = {}
        for i=1,colAddNum do
            local addindex = math.random(1,#colList)
            table.insert(colAddList,colList[addindex])
            table.remove(colList,addindex)
        end

        for i=1,#self.m_ActInfo do
            local info = self.m_ActInfo[i]
            for k = 1,#colAddList do
                if info.col == colAddList[k] then
                    self.m_ActInfo[i].time = self.m_ActInfo[i].time + math.random(30,50) / 100  -- math.random(30,50) / 100
                    break
                end
            end
        end
        
        self:beginActCoinsPoolToDi(self.m_ActInfo )

        return
    end
    
    local deTimes = 0.4 
    local flyTimesPool = {78,83} --{78,83}
    for i=1,#actionCol do
        local acttionTime = math.random(flyTimesPool[1],flyTimesPool[2]) / 100
        local info = {}
        info.col = actionCol[i]
        info.time = acttionTime + self.m_CoinsFlyTimes * deTimes
        info.m_CoinsFlyTimes = self.m_CoinsFlyTimes
        table.insert(self.m_ActInfo,info)
    end

    self:beginPigCoinsFlyAction(  )
    

   
end

function CodeGameScreenCoinManiaMachine:beginActCoinsPoolToDi(ActInfo )

    if #ActInfo == 0  then
        
        self:netBackReelsStop( )
        return 
    end

    table.sort(ActInfo,function( a,b )
        return a.time < b.time
    end)

    for i=1,#ActInfo do
        local info = ActInfo[i]
        local m_CoinsFlyTimes = info.m_CoinsFlyTimes

        local coinsPos , coinsBet = self:getWildBetAndReelPos( info.col,m_CoinsFlyTimes - 1 )

        if self.m_notTrigger then
            coinsPos , coinsBet = self:getWildBetAndReelPosNotTrigger( info.col,m_CoinsFlyTimes - 1 )
        end

        local nodeFirstName = {"CoinMania_jinbi_W","CoinMania_jinbi_I","CoinMania_jinbi_L","CoinMania_jinbi_D","CoinMania_jinbi_S"} 
        local CsbName = "CoinMania_jinbi_duocaiduofu" 
        local coinsZOrder = -1
        if m_CoinsFlyTimes == 1 then
            CsbName = nodeFirstName[info.col]
        end
        if coinsBet then
            coinsZOrder = m_CoinsFlyTimes
            if coinsBet == 1 then
                CsbName = "CoinMania_jinbi_duocaiduofu" 
            else
                CsbName = "CoinMania_jinbi_X2"
            end
            
        end

        local node = util_createAnimation(CsbName .. ".csb")

        local lab = node:findChild("BitmapFontLabel_1")
        if lab then
            lab:setString("*"..coinsBet)
        end
        local nodePar = cc.Node:create()
        nodePar:addChild(node,coinsZOrder)
        self:findChild("BaseReel"):addChild(nodePar,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + coinsZOrder )
        local parentName = {"wilds_w","wilds_i","wilds_l","wilds_d","wilds_s"}
        local ReferencePosA = cc.p(self:findChild(parentName[info.col]):getPosition()) 
        local ReferencePosB = cc.p(self:findChild("jinbidui"):getPosition()) 
        local addYPos = 12
        local addPos = ((m_CoinsFlyTimes - 1) * addYPos )
        local endPos = cc.p(ReferencePosA.x,ReferencePosA.y + addPos )
        local endCallIndex = #ActInfo

        node:setPosition(cc.p(ReferencePosA.x,ReferencePosB.y - 20))
        node.pos = coinsPos
        node.bet = coinsBet
        node.icol = info.col
        node.runtimes =  m_CoinsFlyTimes
        node.addPos =  addPos
        node.endPos = cc.p(ReferencePosA.x,ReferencePosA.y + node.addPos )
        node.arrayIndex =i
        table.insert(self.m_flyPigCoins,node)
        
        if i == endCallIndex then
            

  
            self:playMoveToAction_One(node,info.time,endPos,function(  )
                
            end,true)     
        else
            self:playMoveToAction_One(node,info.time,endPos,nil,true)
        end

    end


    self:netBackReelsStop( )

end

-- 判断是否有金币飞行动画
function CodeGameScreenCoinManiaMachine:PigCoinsCollect( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinCounts = selfdata.coinCounts or {}
    local hitCoinWildPositions = selfdata.hitCoinWildPositions or {}
    local hitBotPositions = selfdata.hitBotPositions or {}
    local pigDown = selfdata.pigDown 
    
    self.m_notTrigger = nil
    self.m_triggerCoinsMainai = nil
    if self:CheckIsTriggerPigFly( coinCounts ) then

        if not (self:CheckIsTriggerPigHitCoinsToWildDiFly( hitBotPositions  ) or self:CheckIsTriggerPigCoinsToWildFly( coinCounts ))  then
            self.m_notTrigger = true
        else
            self.m_triggerCoinsMainai = true
        end
        
        if pigDown then

            gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_logoPig_yuGao.mp3")
            -- 开始猪飞动画
            util_spinePlay(self.m_BigGoldPig,"actionframe4",false)
            util_spineFrameCallFunc(self.m_BigGoldPig, "actionframe4", "Down", function(  )
                self:shakeBaseNode()
                performWithDelay(self,function(  )
                    self.m_ActInfo = {}
                    self:beginPigCoinsFlyAction(  )
                end,0.1)
                
            end,function(  )
                util_spinePlay(self.m_BigGoldPig,"idleframe",true)
                
            end)
        else
            self.m_ActInfo = {}
            self:beginPigCoinsFlyAction(  )
        end

    else
        self:netBackReelsStop( )

    end

end


function CodeGameScreenCoinManiaMachine:netBackReelsStop( )

    

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

--  ----  ----  ----  ----  ----  ----  ----  ----  ----  --
-- 猪 喷金币到下wild底相关
function CodeGameScreenCoinManiaMachine:CheckIsTriggerPigHitCoinsToWildDiFly( hitBotPositions  )
    
    if hitBotPositions and #hitBotPositions > 0 then
        return true
    end

    return false

end

function CodeGameScreenCoinManiaMachine:beginPigCoinsFlyCoinsToDiAction( )
    

    

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinCounts = selfdata.coinCounts or {}
    local hitCoinWildPositions = selfdata.hitCoinWildPositions or {}
    local hitBotPositions = selfdata.hitBotPositions or {}

    

    local actionCol = {}
    for k,v in pairs(hitBotPositions) do
        local col = v + 1
        table.insert(actionCol,col)
    end


    local flyTimesPool = {100,150}
    local ActInfo = {}
    for i=1,#actionCol do
        local acttionTime = math.random(flyTimesPool[1],flyTimesPool[2]) / 100

        if i == 1 then
            acttionTime = flyTimesPool[1] / 100
        end

        local info = {}
        info.col = actionCol[i]
        info.time = acttionTime
        table.insert(ActInfo,info)
    end


    table.sort(ActInfo,function( a,b )
        return a.time < b.time
    end)

    for i=1,#ActInfo do
        local info = ActInfo[i]

        local coinsPos , coinsBet = self:getWildBetAndReelPos( info.col,- 1 )
        local nodeFirstName = {"CoinMania_jinbi_W","CoinMania_jinbi_I","CoinMania_jinbi_L","CoinMania_jinbi_D","CoinMania_jinbi_S"} 
        local CsbName = nodeFirstName[info.col]
        if coinsBet then
            if coinsBet == 1 then
                CsbName = "CoinMania_jinbi_duocaiduofu" 
            else
                CsbName = "CoinMania_jinbi_X2"
            end
            
        end

        local node = util_createAnimation(CsbName .. ".csb")
        local lab = node:findChild("BitmapFontLabel_1")
        if lab then
            lab:setString("*"..coinsBet)
        end
        local nodePar = cc.Node:create()
        nodePar:addChild(node)
        self:findChild("BaseReel"):addChild(nodePar,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER )
        local parentName = {"wilds_w","wilds_i","wilds_l","wilds_d","wilds_s"}
        local ReferencePosA = cc.p(self:findChild(parentName[info.col]):getPosition()) 
        local ReferencePosB = cc.p(util_getOneGameReelsTarSpPos(self,self:getGoldPigBonusIndex( ) )) 
        node:setPosition(cc.p(ReferencePosB.x - 25,ReferencePosB.y + 120))
        node.pos = coinsPos
        node.bet = coinsBet
        node.icol = info.col
        node.runtimes =  1
        table.insert(self.m_flyPigCoins,node)
        local addYPos = 6
        local endPos = cc.p(ReferencePosA.x,ReferencePosA.y  )

        local endCallIndex = #ActInfo

        local angle = util_getAngleByPos(cc.p(ReferencePosB.x - 25,ReferencePosB.y + 120),endPos) + 270
        node:findChild("root"):setRotation( -angle)

        if i == endCallIndex then
        
            self:playMoveToAction(node,info.time,endPos,function(  )
                node:findChild("root"):setRotation(0)
                self:restSelfGameEffects( self.COINMANIA_PIG_ADD_COINS_DI_EFFECT ,true )

            end,true,true,true)
        else
            self:playMoveToAction(node,info.time,endPos,function(  )
                node:findChild("root"):setRotation(0)
            end,true,true,true)
        end

    end


    
end


--  ----  ----  ----  ----  ----  ----  ----  ----  ----  --
-- 由 金币变成wildx相关
function CodeGameScreenCoinManiaMachine:CheckIsTriggerPigCoinsToWildFly( coinCounts  )
    
    local isFiveFull = true
    for k,v in pairs(coinCounts) do
        if v == self.m_WildDi_Nil then
            isFiveFull = false
            break
        end
    end


    if isFiveFull then
        for k,v in pairs(coinCounts) do
            if v > self.m_WildDi_One then
                return true
            end
        end
    end
    

    return false

end
function CodeGameScreenCoinManiaMachine:restLockWildLayerTag( )


    for k,v in pairs(self.m_LockWild) do
        if v then
            v:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
    end

    self.m_LockWild = {}
end

function CodeGameScreenCoinManiaMachine:initDiActNodeList( )
    self.m_initActionFlyNode = {{},{},{},{},{}}
    for k,v in pairs(self.m_flyPigCoins) do
        local flyNode = v

        if flyNode.runtimes and flyNode.runtimes ~= 1 then -- 这里减一，是因为第一波飞的是不参与飞到轮盘的动作
            self.m_initActionFlyNode[flyNode.icol][flyNode.runtimes - 1] = flyNode
        end
        

    end

end

function CodeGameScreenCoinManiaMachine:getDiActNodeList(  )

    local actionFlyNode = {}

    for iCol =1,#self.m_initActionFlyNode do
        local colNodeList = self.m_initActionFlyNode[iCol]
        if #colNodeList > 0 then
            
            for runtimes = #colNodeList,1,-1 do
                local node = colNodeList[runtimes]
                if node then
                    table.insert(actionFlyNode,node)
                    table.remove(colNodeList,runtimes)
                    break
                end

            end
        end
    end

    return actionFlyNode


end

function CodeGameScreenCoinManiaMachine:pigCoinsFlyActBgShowStates( )
    
    local winlines = self.m_runSpinResultData.p_winLines

    if winlines and #winlines > 0 then

        if #winlines == 1 and winlines[1].type and (winlines[1].type == 90 or winlines[1].type == 91) then

            self.m_pigCoinsFlyActBg:runCsbAction("over",false,function(  )
                self.m_pigCoinsFlyActBg:setVisible(false)
            end)
        else
            
           
        
            -- self.m_pigCoinsFlyActBg:runCsbAction("actionframe1",true)
        end
        
    else
        self.m_pigCoinsFlyActBg:runCsbAction("over",false,function(  )
            self.m_pigCoinsFlyActBg:setVisible(false)
        end)
    end
        
        

end

function CodeGameScreenCoinManiaMachine:beginPigCoinsFlyToWildAction(  )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinCounts = selfdata.coinCounts or {}
    local hitBotPositions = selfdata.hitBotPositions or {}
    local hitCoinWildPositions = selfdata.hitCoinWildPositions or {}

    
    local actionFlyNode = self:getDiActNodeList(  )
    -- for k,v in pairs(self.m_flyPigCoins) do
    --     local flyNode = v

    --     if flyNode.runtimes == self.m_CoinsFlyToWildTimes then
    --         table.insert(actionFlyNode,flyNode)
    --     end
    -- end

    self.m_CoinsFlyToWildTimes = self.m_CoinsFlyToWildTimes - 1
    if self.m_CoinsFlyToWildTimes == 0  then
        
        self.m_CoinsFlyToWildTimes = 0
        
        if not self:CheckIsTriggerPigHitCoinsFly( hitCoinWildPositions  )  then

            self:pigCoinsFlyActBgShowStates( )

            if self.m_addCoinsGameBg then
                gLobalSoundManager:stopAudio(self.m_addCoinsGameBg)
                self.m_addCoinsGameBg= nil
            end
            -- gLobalSoundManager:setBackgroundMusicVolume(1)
            gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_addCoinsGameEnd.mp3")  
        end
        

        self:restSelfGameEffects( self.COINMANIA_PIG_FLY_COINS_DI_EFFECT ,true )

        

        

        return
    end

    local flyTimesPool = {100,130}

    for i=1,#actionFlyNode do
        local acttionTime = math.random(flyTimesPool[1],flyTimesPool[2]) / 100
        if i == 1 then
            acttionTime = flyTimesPool[1] / 100
        end

        actionFlyNode[i].time = acttionTime
    end

    table.sort(actionFlyNode,function( a,b )
        return a.time < b.time
    end)

    for i=1,#actionFlyNode do
        local flyNode = actionFlyNode[i]
        local fixPos = self:getRowAndColByPos(flyNode.pos)

        local endCallIndex = #actionFlyNode
        
        
        local WildType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        if flyNode.bet ~= 1 then
            WildType = self["SYMBOL_PIG_WILD_X".. flyNode.bet ]
        end
        
        local endPos = cc.p(util_getOneGameReelsTarSpPos(self,flyNode.pos ))

        local targSp =  nil 
        local isOld = false
        local lockwild = self:checkWildIsLocked( flyNode.pos  )
        if lockwild then
            targSp = lockwild
            isOld = true
        else
            targSp =  self:getSlotNodeWithPosAndType( WildType , fixPos.iX, fixPos.iY, false)  
            targSp:setVisible(false)
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1 --REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            

            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
            self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 100  , SYMBOL_NODE_TAG)
            -- targSp:setLocalZOrder(self:getBounsScatterDataZorder(targSp.p_symbolType) )
            targSp:setPosition(endPos)

            table.insert(self.m_LockWild,targSp)
            
        end
            
        local angle = util_getAngleByPos(cc.p(flyNode:getPosition()),endPos) + 270
        flyNode:findChild("root"):setRotation( -angle)

        
        if i == endCallIndex then
            

            if self.m_CoinsFlyToWildTimes == 1 then

                self:playMoveToAction(flyNode,flyNode.time,endPos,function(  )

                    local pigBonusPos =  self:getGoldPigBonusIndex()
                    if pigBonusPos == flyNode.pos then
                        targSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE) 
                    end

                    
                    targSp:setVisible(true)
                    flyNode:setVisible(false)
                    if isOld then
                        if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                            targSp.p_symbolImage:removeFromParent()
                        end
                        targSp.p_symbolImage = nil
                        targSp:changeCCBByName(self:getSymbolCCBNameByType(self,WildType),WildType)
                    end
                    local currtargSp = targSp
                    targSp:runAnim("animation0",false,function(  )
                        self:beginPigCoinsFlyToWildAction( ) 
                        currtargSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 100) 
                    end)      
                    
                end,true,nil,nil,true)
                   
            else
                self:playMoveToAction(flyNode,flyNode.time,endPos,function(  )
                    local pigBonusPos =  self:getGoldPigBonusIndex()
                    if pigBonusPos == flyNode.pos then
                        targSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE) 
                    end
                    targSp:setVisible(true)
                    flyNode:setVisible(false)
                    if isOld then
                        if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                            targSp.p_symbolImage:removeFromParent()
                        end
                        targSp.p_symbolImage = nil
                        targSp:changeCCBByName(self:getSymbolCCBNameByType(self,WildType),WildType)
                    end
                    local currtargSp = targSp
                    targSp:runAnim("animation0",false,function(  )
                        currtargSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 100) 
                    end)      
                    
                end,true,nil,nil,true)

                scheduler.performWithDelayGlobal(function (  )

                    self:beginPigCoinsFlyToWildAction( ) 
                    
                end,flyNode.time / 2,self:getModuleName())
                
            end

            

            
        else
            self:playMoveToAction(flyNode,flyNode.time,endPos,function( )
                local pigBonusPos =  self:getGoldPigBonusIndex()
                if pigBonusPos == flyNode.pos then
                    targSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE) 
                end
                targSp:setVisible(true)
                flyNode:setVisible(false)
                if isOld then
                    if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                        targSp.p_symbolImage:removeFromParent()
                    end
                    targSp.p_symbolImage = nil
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self,WildType),WildType)
                end

                local currtargSp = targSp
                targSp:runAnim("animation0",false,function(  )
                    currtargSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 100) 
                end) 

            end,true)
        end

    end

end
--  ----  ----  ----  ----  ----  ----  ----  ----  ----  --
-- 猪喷出金币
function CodeGameScreenCoinManiaMachine:CheckIsTriggerPigHitCoinsFly( hitCoinWildPositions  )
    

    if hitCoinWildPositions and #hitCoinWildPositions > 0 then
        return true
    end

    return false

end

function CodeGameScreenCoinManiaMachine:getGoldPigBonusIndex( )
    
    for iCol = 1, self.m_iReelColumnNum  do


        for iRow = 1, self.m_iReelRowNum do

            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            
            if symbolType ==  self.SYMBOL_PIG_Bonus then
                
                return self:getPosReelIdx(iRow, iCol)
            end
        end

    end
end

function CodeGameScreenCoinManiaMachine:getGoldPigBonusBet( index )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinWildPositions = selfdata.coinWildPositions or {}
    local backBet = 1
    for i=1,#coinWildPositions do
        local colCoinData = coinWildPositions[i]
        for k,v in pairs(colCoinData) do
            local posIndex = tonumber(k)
            local bet = v
            if index == posIndex then
                
                return bet + backBet
            end
        end
    end
    

    return backBet

end

function CodeGameScreenCoinManiaMachine:beginPigHitCoinsAction(  )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local coinCounts = selfdata.coinCounts or {}
    local hitCoinWildPositions = selfdata.hitCoinWildPositions or {}

    local actionCol = {}

    if self.m_PigHitCoinsFlyTimes == 0 then

        for i=1,#hitCoinWildPositions do
            local endPos = hitCoinWildPositions[i]
            if i <= self.m_roandCutindex then
                table.insert(actionCol,endPos)
            end
        end

    else

        for i=1,#hitCoinWildPositions do
            local endPos = hitCoinWildPositions[i]
            if i > self.m_roandCutindex then
                table.insert(actionCol,endPos)
            end
        end 
    end

    

    self.m_PigHitCoinsFlyTimes = self.m_PigHitCoinsFlyTimes + 1

    if self.m_PigHitCoinsFlyTimes > 2  then

        
        self.m_pigBonusSp:runAnim("actionframe12")
        if self.m_pigBonusSp then
            self.m_pigBonusSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 200)
        end
        
        self.m_PigHitCoinsFlyTimes = 0

        self:pigCoinsFlyActBgShowStates( )

        if self.m_addCoinsGameBg then
            gLobalSoundManager:stopAudio(self.m_addCoinsGameBg)
            self.m_addCoinsGameBg= nil
        end
        -- gLobalSoundManager:setBackgroundMusicVolume(1)
        gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_addCoinsGameEnd.mp3")


        self:restSelfGameEffects( self.COINMANIA_PIG_FLY_COINS_MID_EFFECT,true )

        return
    end

    local flyTimesPool = {100,150}
    local ActInfo = {}
    for i=1,#actionCol do
        local acttionTime = math.random(flyTimesPool[1],flyTimesPool[2]) / 100
        if i == 1 then
            acttionTime = flyTimesPool[1] / 100
        end
        
        local info = {}
        info.pos = actionCol[i]
        info.time = acttionTime
        table.insert(ActInfo,info)
    end


    table.sort(ActInfo,function( a,b )
        return a.time < b.time
    end)

    for i=1,#ActInfo do
        local info = ActInfo[i]
        local CsbName = "CoinMania_jinbi_duocaiduofu"

        local node = util_createAnimation(CsbName .. ".csb")

        local nodePar = cc.Node:create()
        nodePar:addChild(node)

        self:findChild("BaseReel"):addChild(nodePar,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER   )
        local currPos = cc.p(util_getOneGameReelsTarSpPos(self,self:getGoldPigBonusIndex( )))
        node:setPosition(cc.p(currPos.x- 25,currPos.y + 120))

        table.insert(self.m_flyPigCoins,node)

        local endPos = cc.p(util_getOneGameReelsTarSpPos(self,info.pos )  )

        

        local fixPos = self:getRowAndColByPos(info.pos )        
        local WildType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        local HitPigBet =  self:getGoldPigBonusBet( info.pos )
        if HitPigBet ~= 1 then
            WildType = self["SYMBOL_PIG_WILD_X".. HitPigBet]
        end

        local targSp =  nil 
        local isOld = false
        local lockwild = self:checkWildIsLocked( info.pos  )
        if lockwild then
            targSp =  lockwild
            isOld = true
        else

            targSp = self:getSlotNodeWithPosAndType( WildType , fixPos.iX, fixPos.iY, false)  
            targSp:setVisible(false)
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1 -- REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
            self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 100, SYMBOL_NODE_TAG)
            -- targSp:setLocalZOrder(self:getBounsScatterDataZorder(targSp.p_symbolType) )
            targSp:setPosition(endPos)

            table.insert(self.m_LockWild,targSp)
            
        end
        
        

        local angle = util_getAngleByPos(cc.p(node:getPosition()),endPos) + 270
        node:findChild("root"):setRotation( -angle)


        local endCallIndex = #ActInfo

        if i == endCallIndex then
            
            self:playMoveToAction(node,info.time,endPos,function(  )

                node:setVisible(false)
                targSp:setVisible(true)
                local pigBonusPos =  self:getGoldPigBonusIndex()
                if pigBonusPos == info.pos then
                    targSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE) 
                end

                if isOld then
                    if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                        targSp.p_symbolImage:removeFromParent()
                    end
                    targSp.p_symbolImage = nil
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self,WildType),WildType)
                end
                local currtargSp = targSp
                targSp:runAnim("animation0",false,function(  )
                    currtargSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 100)
                    
                    
                    if self.m_PigHitCoinsFlyTimes == 1 then

                        
                        
                        if self.m_pigBonusSp then
                            self.m_pigBonusSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 1)
                        end

                        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbol_Pig_to_reel.mp3")

                        self.m_pigBonusSp:runAnim("actionframe7",false,function(  )
                            self.m_pigBonusSp:runAnim("actionframe6",true)

                        end)
    
                        scheduler.performWithDelayGlobal(function (  )
                            self:beginPigHitCoinsAction(  )
                        end,7/30,self:getModuleName())
                    else
                        self:beginPigHitCoinsAction( )
                    end
                end)

                
                

            end,true,true)
        else
            self:playMoveToAction(node,info.time,endPos,function(  )
                node:setVisible(false)
                targSp:setVisible(true)
                local pigBonusPos =  self:getGoldPigBonusIndex()
                if pigBonusPos == info.pos then
                    targSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE) 
                end

                if isOld then
                    if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                        targSp.p_symbolImage:removeFromParent()
                    end
                    targSp.p_symbolImage = nil
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self,WildType),WildType)
                end
                local currtargSp = targSp
                targSp:runAnim("animation0",false,function(  )
                    currtargSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 100)
                end)

            end,true,true)
        end

    end

end



function CodeGameScreenCoinManiaMachine:checkWildIsLocked( index )

    for i=1,#self.m_LockWild do
        local wild = self.m_LockWild[i]

        if wild then
            local iconsPos = self:getPosReelIdx(wild.p_rowIndex, wild.p_cloumnIndex)

            if index == iconsPos then
                return wild
            end
            
        end

    end

    return false
    
end

------------------------------------------
-- 收集小游戏 断线处理
function CodeGameScreenCoinManiaMachine:initFeatureInfo(spinData,featureData)
    if spinData.p_bonusStatus and spinData.p_bonusStatus ~= "CLOSED"  then

        self.isInBonus = true
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})

        if self:getBonusGameType( ) == self.m_gameTypeFs  then
            self:createFsGameChooseView( function(  )
                self:checkLocalGameNetDataFeatures()
                self:playGameEffect()
            end )
        else
            self:createJpGameChooseView(function(  )


                self:checkLocalGameNetDataFeatures()
                self:playGameEffect()
            end )
        end
    end
    
end

-- freespin选择玩法
function CodeGameScreenCoinManiaMachine:createFsGameChooseView( func,isShow)

    local FsGameChoose = util_createView("CodeCoinManiaSrc.CoinManiaFsGameChooseView",self)
    self:findChild("GameView"):addChild(FsGameChoose)
    if globalData.slotRunData.machineData.p_portraitFlag then
        FsGameChoose.getRotateBackScaleFlag = function(  ) return false end
    end

    

    FsGameChoose:setEndCall( function(  )
        
        util_playFadeOutAction(FsGameChoose,0.3,function(  )

            if func then
                func()
            end

            if FsGameChoose:getParent() then
                FsGameChoose:removeFromParent()
                FsGameChoose = nil
            end
        end)

        
        
    end)
    self:resetMusicBg(nil,"CoinManiaSounds/music_CoinMania_FsChooseGameBG.mp3")

    performWithDelay(self,function(  )

        FsGameChoose:runChestTiShiAct( )
        performWithDelay(self,function(  )
            
            FsGameChoose:startGameCallFunc()
            FsGameChoose:beginBulingAct( )
        end,1.5)

    end,1)
    

    
    
    
   


end


function CodeGameScreenCoinManiaMachine:playStartJpGame(JpGameChoose,posList , func ,waitTimes)
    
    for i=1,6 do
        local index = math.random(1,#posList)
        local posindex = posList[index]
        local node = util_createAnimation("CoinMania_JackPot_wanfa_cai_0.csb")
        JpGameChoose:findChild("Node_Effect"):addChild(node,100)
        local startPos = cc.p(util_getConvertNodePos(self:findChild("jinzhu"),node))
        node:setPosition(cc.p(startPos.x - 50,startPos.y + 240))
        local pos = cc.p(util_getConvertNodePos(JpGameChoose["Chest"..posindex],node))  
        local callback = nil
        if i== 6 then
            callback = function(  )
            
                if func then
                    func()
                end
            end
        end
        local type = "easyInOut"
        local waitTime = waitTimes
        table.remove(posList,index)
        scheduler.performWithDelayGlobal(function (  )
            
            JpGameChoose:playStartMoveToAction(node,pos,callback,type,waitTime)
            
        end,(i - 1 )*0.05,self:getModuleName())

        

    end

end

------------------------------------------
-- jackpot选择玩法
function CodeGameScreenCoinManiaMachine:createJpGameChooseView( func , isShow )

    local JpGameChoose = self.m_JpGameChoose 
    JpGameChoose:setVisible(true)
    JpGameChoose:updateUI(self ,isShow )
    JpGameChoose:setEndCall( function(  )
        
        if func then
            func()
        end

        self:findChild("gameBg"):setVisible(true)
        self:findChild("BaseReel"):setVisible(true)
        self:findChild("jackpot"):setVisible(true)
        self.m_clipParent:setVisible(true)

        JpGameChoose.m_actNode:stopAllActions()
        JpGameChoose.m_bulingPos = 1000

        JpGameChoose:setVisible(false)

        JpGameChoose:removeAllChest( ) 


        
    end)

    if isShow then

        
        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Start_GuoChang.mp3")

        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:checkClearWinLabel()

        local posList = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18}

        self:findChild("node_jpShow"):setVisible(false)
        util_playFadeOutAction(self:findChild("node_jpShow"),0.1,function(  )
            self:findChild("node_jpShow"):setVisible(true)
            util_playFadeInAction(self:findChild("node_jpShow"),1.3,function(  )
                
            end)
        end)


        JpGameChoose:findChild("Node_littledi"):setVisible(false)
        JpGameChoose:findChild("shouji"):setVisible(false)
        JpGameChoose:findChild("zi"):setVisible(false)
        JpGameChoose:findChild("jackpot"):setVisible(false)
        JpGameChoose:findChild("tubiao_fanzhuan"):setVisible(false)
 
        self.m_BigGoldPigBG:runCsbAction("start")
        self.m_BigGoldPigBG_1:runCsbAction("start")
        util_spinePlay(self.m_BigGoldPig,"actionframe",false)
        util_spineFrameCallFunc(self.m_BigGoldPig, "actionframe", "Gush1", function(  )
            
            
            
            self:playStartJpGame(JpGameChoose,posList , function(  )

            end ,0 )


            scheduler.performWithDelayGlobal(function (  )
            
                self:playStartJpGame(JpGameChoose,posList , function(  )

                end , 0 )
                
            end,0.6,self:getModuleName())

            
            scheduler.performWithDelayGlobal(function (  )
            
                self:playStartJpGame(JpGameChoose,posList , function(  )


                    util_playFadeOutAction(JpGameChoose:findChild("Node_littledi"),0.1,function(  )
                        JpGameChoose:findChild("Node_littledi"):setVisible(true)
                        util_playFadeInAction(JpGameChoose:findChild("Node_littledi"),0.5,function(  )
                            
                        end)
                    end)
                    util_playFadeOutAction(JpGameChoose:findChild("shouji"),0.01,function(  )
                        JpGameChoose:findChild("shouji"):setVisible(true)
                        util_playFadeInAction(JpGameChoose:findChild("shouji"),0.5,function(  )
                            
                        end)
                    end)
                    util_playFadeOutAction(JpGameChoose:findChild("zi"),0.01,function(  )
                        JpGameChoose:findChild("zi"):setVisible(true)
                        util_playFadeInAction(JpGameChoose:findChild("zi"),0.5,function(  )
                            
                        end)
                    end)
                    util_playFadeOutAction(JpGameChoose:findChild("jackpot"),0.01,function(  )
                        JpGameChoose:findChild("jackpot"):setVisible(true)
                        util_playFadeInAction(JpGameChoose:findChild("jackpot"),0.5,function(  )
    
                            JpGameChoose:findChild("tubiao_fanzhuan"):setVisible(true)
    
                            self:findChild("gameBg"):setVisible(false)
                            self:findChild("BaseReel"):setVisible(false)
                            self:findChild("jackpot"):setVisible(false)
                            self.m_clipParent:setVisible(false)
    
                            JpGameChoose:findChild("Node_Effect"):removeAllChildren()
    
                            self:resetMusicBg(nil,"CoinManiaSounds/music_CoinMania_JpGameBG.mp3")

                            JpGameChoose:startGameCallFunc()

                            self:findChild("node_jpShow"):setVisible(false)
    
                        end)
                    end)
    
    
                end , 0.64 )
                
            end,1.2,self:getModuleName())


            

        end)

  

    else

        self:findChild("gameBg"):setVisible(false)
        self:findChild("BaseReel"):setVisible(false)
        self:findChild("jackpot"):setVisible(false)
        self.m_clipParent:setVisible(false)

        self:resetMusicBg(nil,"CoinManiaSounds/music_CoinMania_JpGameBG.mp3")

        JpGameChoose:startGameCallFunc()
    
    end

   
end

-- 提高小块层级到self.m_clipParen
function CodeGameScreenCoinManiaMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 1, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        -- linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = false
        targSp:setLinePos(linePos)
    end
    return targSp
end


-- -- -- -- -- - ------ -- - - - - - - - - -

function CodeGameScreenCoinManiaMachine:checkLongRunStates( )

    local scatterNum = 0
    local bonusNum = 0
    local totalscatte = 0
    local totalbonus = 0
    local scatterContinuity = false
    local bonusContinuity = false



    for iCol = 1, self.m_iReelColumnNum  do


        local isHaveScatter = 0
        local isHaveBonus = 0

        for iRow = 1, self.m_iReelRowNum do

            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            

            if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if iCol == 2  then
                    scatterContinuity = true
                    scatterNum = scatterNum + 1
                elseif iCol == 3 then
                    if scatterContinuity then
                        scatterNum = scatterNum + 1
                    end
                end
                

                totalscatte = totalscatte + 1
            end
                
            if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                
                if iCol == 1 then
                    bonusNum =  bonusNum + 1
                    bonusContinuity = true
                elseif iCol == 3 then
                    if bonusContinuity then
                        bonusNum =  bonusNum + 1
                    end
                end
                totalbonus = totalbonus + 1
                
            end

            if iCol == 3 then

                if symbolType ~=  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isHaveScatter = isHaveScatter + 1
                end
    
                if symbolType ~=  TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    isHaveBonus = isHaveBonus + 1
                end

                if isHaveScatter == self.m_iReelRowNum then
                    scatterContinuity = false
                end

                if isHaveBonus == self.m_iReelRowNum then
                    bonusContinuity = false
                end
    
            end


        end

        

    end


    return scatterNum , bonusNum , totalscatte,totalbonus,scatterContinuity,bonusContinuity

end

--设置长滚信息
function CodeGameScreenCoinManiaMachine:setReelRunInfo()
    
    self.m_ScatterShowCol = nil

    local scatterNum , bonusNum , totalscatte,totalbonus =  self:checkLongRunStates( )
    if (scatterNum >= 2) and (bonusNum >= 2) then
            self.m_ScatterShowCol = nil
    else
            if scatterNum >= 2 then
                self.m_ScatterShowCol = {2,3,4}
            elseif bonusNum >= 2 then
                self.m_ScatterShowCol = {1,3,5}
            else

                if (totalscatte >= 2 ) and (totalbonus >= 2 ) then
                    self.m_ScatterShowCol = {2,3,4}
                else 
                    if totalscatte >= 2 then
                        self.m_ScatterShowCol = {2,3,4}
                    elseif totalbonus >= 2 then
                        self.m_ScatterShowCol = {1,3,5}

                    end
                    
                end
                
        end
    end

    BaseFastMachine.setReelRunInfo(self)
end

function CodeGameScreenCoinManiaMachine:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    -- if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else 
                return false
            end
        end
    -- end

    return true
end

function CodeGameScreenCoinManiaMachine:changeSlotsNodeInfo(pos,symbolType)
    if self.m_reelRunInfo[pos].m_slotsNodeInfo then
        for i=#self.m_reelRunInfo[pos].m_slotsNodeInfo,1,-1 do
            local data = self.m_reelRunInfo[pos].m_slotsNodeInfo[i]
            local CurrSymbolType = self.m_stcValidSymbolMatrix[data.x][data.y]
            if symbolType == CurrSymbolType then
                table.remove(self.m_reelRunInfo[pos].m_slotsNodeInfo,i)
                if self.m_reelRunInfo[pos].m_slotsNodeInfo and #self.m_reelRunInfo[pos].m_slotsNodeInfo == 0 then
                    self.m_reelRunInfo[pos].m_slotsNodeInfo = nil
                end
            end
        end
    end
end
---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenCoinManiaMachine:MachineRule_ResetReelRunData()

    local scatterNum , bonusNum , totalscatte,totalbonus,scatterContinuity,bonusContinuity =  self:checkLongRunStates( )

    if self.m_ScatterShowCol then

    else

        if (scatterNum == 0 and totalscatte > 0) or (bonusNum == 0 and totalbonus > 0) then

            if self.m_reelRunInfo[3].m_slotsNodeInfo then
                self.m_reelRunInfo[3].m_slotsNodeInfo = nil
            end

            if self.m_reelRunInfo[5].m_slotsNodeInfo then
                self.m_reelRunInfo[5].m_slotsNodeInfo = nil
            end
    
            if self.m_reelRunInfo[4].m_slotsNodeInfo then
                self.m_reelRunInfo[4].m_slotsNodeInfo = nil
            end
        end
 
    end

    if not scatterContinuity then
            
        self:changeSlotsNodeInfo(3,TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        self:changeSlotsNodeInfo(4,TAG_SYMBOL_TYPE.SYMBOL_SCATTER)

    end

    if not bonusContinuity then

        self:changeSlotsNodeInfo(3,TAG_SYMBOL_TYPE.SYMBOL_BONUS)
        self:changeSlotsNodeInfo(5,TAG_SYMBOL_TYPE.SYMBOL_BONUS)

    end

    
end

--- -- -- - - - - - - - - -- - - - -  - -
function CodeGameScreenCoinManiaMachine:removeAllfsAddPigNode( )
    
    for i=1,#self.m_actNodeFsAddPig do
        local node = self.m_actNodeFsAddPig[i]
        node:removeFromParent()
        
    end
    
    self.m_actNodeFsAddPig = {}
end


function CodeGameScreenCoinManiaMachine:requestSpinResult()
    
    self:checkAddPigInFsFirst( function(  )
        BaseFastMachine.requestSpinResult(self)
    end )

end
-- 检测是否freespin第一次播放添加猪的动画
function CodeGameScreenCoinManiaMachine:checkAddPigInFsFirst( func )
    
    local fsLeftTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
    local fsTotalTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
    if (self:getCurrSpinMode() == FREE_SPIN_MODE) and (fsTotalTimes ~= 0) and (fsLeftTimes == fsTotalTimes) then
       local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
       local clientPositions = selfdata.clientPositions or {}
       local rewards = selfdata.rewards or {}
       local totalPigs = selfdata.totalPigs or 0
       local isAddPig = false
       for i=1,#clientPositions do
           local clickPos = clientPositions[i] + 1
           if rewards[clickPos] and (rewards[clickPos] == 0) then
                isAddPig = true
                break
           end
       end

       if totalPigs > 0 then
            isAddPig = true
       end

       if isAddPig then
            

           -- 如果是freespin的第一次 播放添加猪的动画
            self:fsAddPigCoinsToReel( function(  )
                if func then
                    func()
                end
            end )
        else
            if func then
                func()
            end
        end
        
    else
        if func then
            func()
        end
    end
end

function CodeGameScreenCoinManiaMachine:fsAddPigCoinsToReel( func )
    
    gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Fs_start_addPigAct.mp3")

    local endPos = cc.p(util_getOneGameReelsTarSpPos(self,12 )) 
    local startPosY = - 420
    local startPosX = {-263 ,-87, -160 ,0 , 142, 285}

    local m_actBg_1 = util_createAnimation("Socre_zengjia_3.csb")
    self.m_clipParent:addChild( m_actBg_1,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 10)
    m_actBg_1:setPosition(cc.p(endPos.x,endPos.y + 50))


    local waitTimes = 9/30
    for i=1,6 do
        
        local index = i
        local delayTime = (i-1) * waitTimes

        local m_actBg_2  = util_createAnimation("Socre_zengjia_2.csb")
        self.m_clipParent:addChild(  m_actBg_2,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
        local m_actBg_3 = util_createAnimation("Socre_zengjia_1.csb")
        self.m_clipParent:addChild( m_actBg_3,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        
        
        m_actBg_2:setPosition(cc.p(endPos.x,endPos.y + 50))
        m_actBg_3:setPosition(cc.p(endPos.x,endPos.y + 50))

        scheduler.performWithDelayGlobal(function (  )
            
            self.m_actNodeFsAddPig[index] = cc.Node:create()
            self.m_clipParent:addChild(self.m_actNodeFsAddPig[index],SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 10)
            local pigSpine = util_spineCreate("Socre_CoinMania_Pig",true,true)
            self.m_actNodeFsAddPig[index]:addChild(pigSpine)
            util_spinePlay(pigSpine,"actionframe9",false)
            self.m_actNodeFsAddPig[index]:setPosition(cc.p(startPosX[index],startPosY))
            self.m_actNodeFsAddPig[index]:setScale(0.6)
            if index > 3 then
                pigSpine:setScaleX(-1)
            end
            util_spineFrameCallFunc(pigSpine, "actionframe9", "Up", function(  )

                local actBg_1 = m_actBg_1
                local actBg_2 = m_actBg_2
                local actBg_3 = m_actBg_3

                local index_1 = index
                local actList = {}
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    local index_2 = index_1
                    local actList_1 = {}
                    actList_1[#actList_1 + 1] = cc.EaseOut:create(cc.ScaleTo:create(14/30,0.4),1) 
                    
                    self.m_actNodeFsAddPig[index_2]:runAction(cc.Sequence:create(actList_1))

                end)
                -- actList[#actList + 1] = cc.EaseInOut:create(cc.MoveTo:create(14/30,cc.p(endPos.x,endPos.y + 50)),1)  
                actList[#actList + 1] = cc.EaseOut:create(cc.JumpTo:create(14/30,cc.p(endPos.x,endPos.y + 50),100,1),1)
                actList[#actList + 1] = cc.CallFunc:create(function(  )

                    actBg_1:setPosition(cc.p(endPos.x,endPos.y + 50))
                    actBg_2:setPosition(cc.p(endPos.x,endPos.y + 50))
                    actBg_3:setPosition(cc.p(endPos.x,endPos.y + 50))

                    actBg_3:runCsbAction("animation0",false,function(  )
                        actBg_3:removeFromParent()
                    end)
                    actBg_2:runCsbAction("animation0",false,function(  )
                        actBg_2:removeFromParent()
                    end)
                    if index_1 == 1 then
                        actBg_1:runCsbAction("start")
                    end
                    self.m_actNodeFsAddPig[index_1]:setVisible(false)

                end)
                self.m_actNodeFsAddPig[index_1]:runAction(cc.Sequence:create(actList))

            end,function(  )
               
                if index == 6 then
                    m_actBg_1:runCsbAction("over",false,function(  )
                        
                        if func then
                            func()
                        end

                        m_actBg_1:removeFromParent()
                    end)
                    
                end

                self.m_actNodeFsAddPig[index]:setVisible(false)
            end)
            
        end,delayTime,self:getModuleName())
            
    end

end

function CodeGameScreenCoinManiaMachine:createReelEffectBG(col)
    local reelEffectNode, effectAct = util_csbCreate("WinCoinMania_run_0.csb")

    reelEffectNode:retain()
    effectAct:retain()

    self:findChild("BaseReel"):addChild(reelEffectNode, 1)
    reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
    self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function CodeGameScreenCoinManiaMachine:creatReelRunAnimation(col)
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

    self:setLongAnimaInfo(reelEffectNode, col)

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)


    local reelEffectNodeBG = nil
    local reelActBG = nil
    if self.m_reelRunAnimaBG[col] == nil then
        reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
    else
        local reelBGObj = self.m_reelRunAnimaBG[col]

        reelEffectNodeBG = reelBGObj[1]
        reelActBG = reelBGObj[2]
    end

    reelEffectNodeBG:setScaleX(1)
    reelEffectNodeBG:setScaleY(1)

    reelEffectNodeBG:setVisible(true)
    util_csbPlayForKey(reelActBG, "run", true)


    if col == 4 then

        reelEffectNode:getChildByName("Node_1"):setVisible(false)
        reelEffectNodeBG:getChildByName("Node_1"):setVisible(false)
        reelEffectNode:getChildByName("Node_2"):setVisible(true)
        reelEffectNodeBG:getChildByName("Node_2"):setVisible(true)
        self:setReelRunSound("CoinManiaSounds/music_CoinMania_LongRunFs.mp3")
    elseif col == 5 then
        self:setReelRunSound("CoinManiaSounds/music_CoinMania_LongRunJp.mp3")
        reelEffectNode:getChildByName("Node_1"):setVisible(true)
        reelEffectNodeBG:getChildByName("Node_1"):setVisible(true)
        reelEffectNode:getChildByName("Node_2"):setVisible(false)
        reelEffectNodeBG:getChildByName("Node_2"):setVisible(false)
    end


    

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--
--单列滚动停止回调
--
function CodeGameScreenCoinManiaMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 
    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end


    for k = 1, self.m_iReelRowNum do
        
        local slotNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
        if slotNode then
            local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]
            if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                --播放关卡中设置的小块效果
                self:playSpecialSymbolDownAct(slotNode)
        
                if
                    slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
                        slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS
                 then
                    if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex,slotNode) == true then
                        local tarsp =  self:setSpecialSymbolToClipReel(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType)
                        tarsp:runAnim("buling",false)
                        self:playScatterBonusSound(tarsp)
                    end
        
        
                end
        
            end
        end

         

    end

   
end



---
-- 根据类型获取对应节点
--
function CodeGameScreenCoinManiaMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeBySymbolType(self,symbolType)
    reelNode:initMachine(self )
    return reelNode
end
function CodeGameScreenCoinManiaMachine:perLoadSLotNodes()
    for i = 1, 10 do
        local node = CoinManiaSlotsNode:create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        node:initMachine(self )
        self.m_reelNodePool[#self.m_reelNodePool + 1] = node
    end
end

function CodeGameScreenCoinManiaMachine:getBaseReelGridNode()
    return "CodeCoinManiaSrc.CoinManiaSlotsNode"
end

---
-- 进入关卡
--
function CodeGameScreenCoinManiaMachine:enterLevel()
    BaseFastMachine.enterLevel(self)

    for i=1,#self.nodeBgList do
        local actNodeBg = self.nodeBgList[i]
        actNodeBg:setVisible(false)
    end
end


--[[
    @desc: 计算单线
    time:2018-08-16 19:35:49
    --@lineData: 
    @return:
]]
function CodeGameScreenCoinManiaMachine:getWinLineSymboltType(winLineData,lineInfo )
    local iconsPos = winLineData.p_iconPos
    local enumSymbolType = winLineData.p_type
    for posIndex=1,#iconsPos do
        local posData = iconsPos[posIndex]
        
        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData  -- 连线元素的 pos信息
            
        -- local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        -- if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
        --     enumSymbolType = symbolType
        -- end
    end
    return enumSymbolType
end

function CodeGameScreenCoinManiaMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE



    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder + SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3 )
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runLineAnim()
    end
    return slotNode
end


function CodeGameScreenCoinManiaMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    node.p_rowIndex = row
    node.p_cloumnIndex = col
    node.p_symbolType = symbolType
    node.m_isLastSymbol = isLastSymbol or false

    node:createTrailingNode( symbolType,col,row,isLastSymbol )

    --检测添加角标
    self:checkAddSignOnSymbol(node)

end

function CodeGameScreenCoinManiaMachine:setSpecialSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        -- local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        -- targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE , targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        -- linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = false
        targSp:setLinePos(linePos)
    end
    return targSp
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenCoinManiaMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
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

function CodeGameScreenCoinManiaMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel  then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    self:showLineFrame()
    
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        if self.m_triggerCoinsMainai then
            self:shakeMachineNode(  )
        end
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


function CodeGameScreenCoinManiaMachine:showEffect_NewWin(effectData,winType)

    if self.m_triggerCoinsMainai then

        -- performWithDelay(self,function(  )
            BaseFastMachine.showEffect_NewWin(self,effectData,winType)
        -- end,1.5)
        
    else
        BaseFastMachine.showEffect_NewWin(self,effectData,winType)
    end

end

function CodeGameScreenCoinManiaMachine:shakeMachineNode( func )

    
    -- gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_Shank_Node.mp3")

    local changePosY = 4
    local changePosX = 2
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    
    for i=1,7 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    for i=1,7 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    for i=1,7 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)
    
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)

end

--[[
    @desc: 处理轮盘滚动中的快停，
    在快停前先检测各列需要补偿的nodecount 数量，一次来补齐各个高度同时需要考虑向下补偿的数量，这种处理
    主要是为了兼容长条模式
    time:2019-03-14 14:54:47
    @return:
]]
function CodeGameScreenCoinManiaMachine:operaQuicklyStopReel( )

    BaseFastMachine.operaQuicklyStopReel(self )

    self:stopflyPigCoinsAndRestPos( )
end

function CodeGameScreenCoinManiaMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "bonus" == _sFeature then
        return
    end
    if CodeGameScreenCoinManiaMachine.super.levelDeviceVibrate then
        CodeGameScreenCoinManiaMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenCoinManiaMachine






