---
-- island li
-- 2019年1月26日
-- CodeGameScreenBingoPriatesMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenBingoPriatesMachine = class("CodeGameScreenBingoPriatesMachine", BaseFastMachine)

CodeGameScreenBingoPriatesMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBingoPriatesMachine.SYMBOL_FIX_BONUS = 94  
CodeGameScreenBingoPriatesMachine.SYMBOL_MYSTER = 101
CodeGameScreenBingoPriatesMachine.SYMBOL_LONG_WILD = 93
CodeGameScreenBingoPriatesMachine.SYMBOL_SCORE_10 = 9

CodeGameScreenBingoPriatesMachine.SYMBOL_ACT_WILD = 201
CodeGameScreenBingoPriatesMachine.SYMBOL_SCATRER_CLICK = 202
CodeGameScreenBingoPriatesMachine.SYMBOL_SILVER_BONUES = 203


CodeGameScreenBingoPriatesMachine.FREESPIN_WILD_CHANGE  = GameEffect.EFFECT_SELF_EFFECT - 1

CodeGameScreenBingoPriatesMachine.BASE_TRIGGER_BINGO_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenBingoPriatesMachine.BASE_BONUS_BOOM_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4


CodeGameScreenBingoPriatesMachine.m_aFreeSpinWildArry = {}


-- CodeGameScreenBingoPriatesMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenBingoPriatesMachine.m_BingoNetData = nil -- 本地bingo表

CodeGameScreenBingoPriatesMachine.m_freeSpinScatterList = nil -- scatterNode
CodeGameScreenBingoPriatesMachine.m_freeSpinStartCall = nil --freespinStart回调

-- 船长玩法gameType
CodeGameScreenBingoPriatesMachine.m_AddBaseReelWild = 1 --随机网base轮盘添加wild
CodeGameScreenBingoPriatesMachine.m_AddBingoReelCollectPos = 2 --随机添加轮盘收集位置

CodeGameScreenBingoPriatesMachine.m_goldenBoneBonusType =  "goldenBone"

CodeGameScreenBingoPriatesMachine.m_flyWildList = {}

-- 构造函数
function CodeGameScreenBingoPriatesMachine:ctor()
    BaseFastMachine.ctor(self)
    -- self.m_isOnceClipNode = false --是否只绘制一个矩形裁切 --小矮仙 袋鼠等不规则或者可变高度设置成false
	--init
    self:initGame()

    self.isInBonus = false
    self.m_isFeatureOverBigWinInFree = true

    self.m_aFreeSpinWildArry = {}
    self.m_BingoNetData = nil
    self.m_flyWildList = {}



    self.m_freeSpinScatterList = nil -- scatterNode
    self.m_freeSpinStartCall = nil --freespinStart回调

end


function CodeGameScreenBingoPriatesMachine:initGameStatusData(gameData)
    
    BaseFastMachine.initGameStatusData(self,gameData)



    if gameData.gameConfig and  gameData.gameConfig.init then
        if gameData.gameConfig.init.bingoData then
            self.m_BingoNetData = gameData.gameConfig.init.bingoData 
        end

        if gameData.gameConfig.init.jackpotMultiply then

            self.m_jackpotMultiply = gameData.gameConfig.init.jackpotMultiply 

        end

    end

end

function CodeGameScreenBingoPriatesMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("BingoPriatesConfig.csv", "LevelBingoPriatesConfig.lua")


	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBingoPriatesMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BingoPriates"  
end

function CodeGameScreenBingoPriatesMachine:getNetWorkModuleName( )

    return "BingoPriatesV2"  
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenBingoPriatesMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "BingoPriatesSounds/BingoPriates_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "BingoPriatesSounds/BingoPriates_scatter_down2.mp3"
        else
            soundPath = "BingoPriatesSounds/BingoPriates_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenBingoPriatesMachine:initUI()

    self:runCsbAction("idle1")
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_BonusBingoCollectNdoe = cc.Node:create()
    self:addChild(self.m_BonusBingoCollectNdoe,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1) 
    
    -- 创建view节点方式
    -- self.m_BingoPriatesView = util_createView("CodeBingoPriatesSrc.BingoPriatesView")
    -- self:findChild("xxxx"):addChild(self.m_BingoPriatesView)

    self.m_JackPotBar = util_createView("CodeBingoPriatesSrc.BingoPriatesJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotBar)
    self.m_JackPotBar:initMachine(self)

    self.m_ChestBar = util_createView("CodeBingoPriatesSrc.ChestBar.BingoPriatesChestBarView")
    self:findChild("bingo_baoxiangshouji"):addChild(self.m_ChestBar)

    self.m_GoldBoneBar = util_createView("CodeBingoPriatesSrc.GoldBoneBar.BingoPriatesGoldBoneBarView")
    self:findChild("bingo_jindutiao"):addChild(self.m_GoldBoneBar)

    self.m_BingoReel = util_createView("CodeBingoPriatesSrc.BingoReel.BingoPriatesBingoReelView",self)
    self:findChild("bingoReel"):addChild(self.m_BingoReel)
    
    
    self.m_TipView = util_createAnimation("BingoPriates_tip.csb")
    self:findChild("tip"):addChild(self.m_TipView)
    self:findChild("tip"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1) 
    self.m_TipView:setVisible(false)
 
    self.m_GuoChang = util_spineCreate("BingoPriates_guochang",true,true)
    self:addChild(self.m_GuoChang,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER )
    self.m_GuoChang:setVisible(false)
    -- util_spinePlay(self.m_GuoChang,"actionframe",true)
    self.m_GuoChang:setPosition(display.width - 390,display.height - 390)

    
    self.m_GuoChang_bg = util_createAnimation("BingoPriates_GuoChangBG.csb")
    self:addChild(self.m_GuoChang_bg,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1 )
    self.m_GuoChang_bg:setVisible(false)
    self.m_GuoChang_bg:setPosition(display.width/2,display.height/2)

    self.m_CaptainMan = util_spineCreate("BingoPriates_bonus_juese",true,true)
    self:addChild(self.m_CaptainMan,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1 )
    self.m_CaptainMan:setVisible(false)
    -- util_spinePlay(self.m_CaptainMan,"actionframe",true)
    self.m_CaptainMan:setPosition(display.width  - 200 ,display.height / 2 - (130 /self.m_machineRootScale))

    self.m_m_CaptainMan_bg = util_createAnimation("BingoPriates_GuoChangBG.csb")
    self.m_clipParent:addChild(self.m_m_CaptainMan_bg,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE  )
    self.m_m_CaptainMan_bg:setVisible(false)
    self.m_m_CaptainMan_bg:setPosition(display.width/2,display.height/2)
    
    self.m_WaitNode = cc.Node:create()
    self:addChild(self.m_WaitNode)
    
    
    self:findChild("BingoPriates_Mask"):setVisible(false)
    self:findChild("BingoPriates_Mask"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画


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
            soundIndex = 3
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
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "BingoPriatesSounds/music_BingoPriates_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenBingoPriatesMachine:scaleMainLayer()
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
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + 6)
    end

end

function CodeGameScreenBingoPriatesMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)
    -- gameBg:setPosition(display.width/2,display.height/2)
    gameBg:findChild("root"):setScale(1)
    
    self.m_gameBg = gameBg

    self.m_bgAct_1 = util_spineCreate("BingoPriates_BG_idleframe",true,true)
    gameBg:findChild("Node_Bg_1_spine"):addChild(self.m_bgAct_1)
    util_spinePlay(self.m_bgAct_1,"idleframe",true)
    self.m_bgAct_2 = util_spineCreate("BingoPriates_BG2_idleframe",true,true)
    gameBg:findChild("Node_Bg_2_spine"):addChild(self.m_bgAct_2)
    util_spinePlay(self.m_bgAct_2,"idleframe",true)
end


function CodeGameScreenBingoPriatesMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        if not self.isInBonus then
            gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_enter.mp3")
            scheduler.performWithDelayGlobal(function (  )   
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end,2.5,self:getModuleName())
        end
        

    end,0.4,self:getModuleName())
end

function CodeGameScreenBingoPriatesMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:initJackpotUIInfo()
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setBingoUiDark( true )
    end
    
end

function CodeGameScreenBingoPriatesMachine:addObservers()
    BaseFastMachine.addObservers(self)

end

function CodeGameScreenBingoPriatesMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBingoPriatesMachine:MachineRule_GetSelfCCBName(symbolType)


    if symbolType == self.SYMBOL_FIX_BONUS then
        return "Socre_BingoPriates_Linghting"
    elseif symbolType == self.SYMBOL_LONG_WILD then
        return "Socre_BingoPriates_Wild_0"
    elseif symbolType == self.SYMBOL_MYSTER then
        return "Socre_BingoPriates_9"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BingoPriates_10"
    elseif symbolType == self.SYMBOL_ACT_WILD then
        return "Socre_BingoPriates_Wild_1"
    elseif symbolType == self.SYMBOL_SCATRER_CLICK then
        return "Socre_BingoPriates_Scatter_click"
    elseif symbolType == self.SYMBOL_SILVER_BONUES then
        return "Socre_BingoPriates_jinbi"
    end

    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBingoPriatesMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LONG_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MYSTER,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ACT_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATRER_CLICK,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SILVER_BONUES,count =  2}

    
    
    
    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------


function CodeGameScreenBingoPriatesMachine:checkUpdateJackpotInfo(  jackpotData )

    local isUpdata = false

    for k,v in pairs(jackpotData) do

        local coins = v
        if coins ~= 0 then
            isUpdata = true
        end
        
    end

    return isUpdata
end

-- 断线重连 
function CodeGameScreenBingoPriatesMachine:MachineRule_initGame(  )

    
    if self.m_BingoNetData == nil  then
        -- 更新本地bingo表
        local selfdate = self.m_runSpinResultData.p_selfMakeData or {}
        local bingoData = selfdate.bingoData or {}
        self.m_BingoNetData = bingoData 
    end
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotData = selfdata.jackpotData 
    if jackpotData  then
        self.m_JackPotBar:updateJackpotInfo(jackpotData) 
    end

    self:setMysterTypeFromNet( )


end


function CodeGameScreenBingoPriatesMachine:checkInitSpinWithEnterLevel( )

    local isTriggerEffect = false
    local isPlayGameEffect = false


    if self.m_initSpinData ~= nil then 
        -- 检测上次的feature 信息
        if self.m_initFeatureData and self.m_initFeatureData.p_status and self.m_initFeatureData.p_status =="CLOSED"  then
            self.m_initFeatureData = nil
        end
    end

    isTriggerEffect,isPlayGameEffect = BaseFastMachine.checkInitSpinWithEnterLevel(self)

    return isTriggerEffect,isPlayGameEffect
end


function CodeGameScreenBingoPriatesMachine:enterLevel( )
    BaseFastMachine.enterLevel(self)
    
    self:initBingoUi( )
end

--[[
    @desc: 断线重连时处理 是否有feature 
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenBingoPriatesMachine:checkHasFeature( )

    local hasFeature = BaseFastMachine.checkHasFeature(self)

    if self.isInBonus then -- 处在bonus小游戏
        hasFeature = true
    end

    return hasFeature
end


function CodeGameScreenBingoPriatesMachine:checkBonusTrigger( pos )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local  bingoBalls = selfdata.bingoBalls or {}
    local isTrigger = false
    local actList = {}
    for i=1,#bingoBalls do
        local info = bingoBalls[i]
        if info then
            local reelPosition = info.reelPosition
            local ballNum = info.ballNum
            local cardPosition = info.cardPosition
            if reelPosition == pos then
                
                if cardPosition ~= -1 and reelPosition ~= -1 then
                    return true
                end
            end

        end
        
    end

    return false
end

--
--单列滚动停止回调
--
function CodeGameScreenBingoPriatesMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 
   

    local isHaveFixSymbol = false
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol , iRow, SYMBOL_NODE_TAG) 
        if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FIX_BONUS then
            isHaveFixSymbol = true
            targSp:runAnim("buling",false,function(  )
                local pos = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex) 
                if self:checkBonusTrigger( pos ) then
                    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_onFire.mp3")
                    targSp:runAnim("idleframe2",true)
                end
                
            end)

        end
    end

    if isHaveFixSymbol == true  then
        local soundPath = "BingoPriatesSounds/sound_BingoPriates_Bonus_buling.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            -- respinbonus落地音效
            gLobalSoundManager:playSound(soundPath)
        end
        
    end

    
    for k = 1, self.m_iReelRowNum do
        
        local slotNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
        if slotNode then
            local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]
            if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then

                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
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


function CodeGameScreenBingoPriatesMachine:checkSymbolTypePlayTipAnima( symbolType )

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
        
        return false -- 本关Scatter不走底层播放

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS  then
        return true
    end
end

function CodeGameScreenBingoPriatesMachine:setSpecialSymbolToClipReel(_iCol, _iRow, _type)
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
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = false
        targSp:setLinePos(linePos)
    end
    return targSp
end

function CodeGameScreenBingoPriatesMachine:slotReelDown()

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    BaseFastMachine.slotReelDown(self)
 
end

function CodeGameScreenBingoPriatesMachine:playEffectNotifyNextSpinCall( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    BaseFastMachine.playEffectNotifyNextSpinCall( self )

end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBingoPriatesMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBingoPriatesMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    
end
---------------------------------------------------------------------------

function CodeGameScreenBingoPriatesMachine:createScatterClickView( )
    
    local scatterClickList = {}

    for i=1,#self.m_freeSpinScatterList do
        local scatter = self.m_freeSpinScatterList[i] 
        local index = self:getPosReelIdx(scatter.p_rowIndex, scatter.p_cloumnIndex)
        local clickView = util_createView("CodeBingoPriatesSrc.BingoPriatesScatterClickView")
        clickView:initMachine(self)
        clickView:setScale(self.m_machineRootScale)
        self:addChild(clickView, GAME_LAYER_ORDER.LAYER_ORDER_TOP + 3)
        local pos = cc.p(util_getConvertNodePos(scatter,clickView)) 
        clickView:setPosition(pos)
        clickView.m_index = index
        table.insert(scatterClickList,clickView)
    end


    return scatterClickList

end

function CodeGameScreenBingoPriatesMachine:clickScatterCallFunc( clickIndex )
    
    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Scatter_Click.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freespinNumPool = selfdata.freeSpinCount or {1,2,3}
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    
    for i=#freespinNumPool,1,-1 do
        local num = freespinNumPool[i]
        if num == freeSpinsTotalCount then
            table.remove(freespinNumPool,i)
            break
        end
    end
    
    local clickIndex = clickIndex

    for i=1,#self.m_scatterClickList do
        local clickView = self.m_scatterClickList[i]
        clickView:removeFromParent()
    end
    self.m_scatterClickList = nil

    local currNum = 1
    for i=1,#self.m_freeSpinScatterList do
        local scatter = self.m_freeSpinScatterList[i]
        local index = self:getPosReelIdx(scatter.p_rowIndex, scatter.p_cloumnIndex)
        if index == clickIndex then
            local lab = scatter:findChild("BitmapFontLabel_2")
            if lab then
                lab:setString(freeSpinsTotalCount)
            end
            scatter:runCsbAction("actionframe")
        else
            local lab = scatter:findChild("BitmapFontLabel_2")
            if lab then
                local fsClickNum = freespinNumPool[currNum]
                if  fsClickNum then
                    lab:setString(fsClickNum)
                end
                
            end
            currNum = currNum + 1
            
            scatter:runCsbAction("dark")
        end

        
    end

    performWithDelay(self,function( )
        if self.m_freeSpinStartCall then
            self.m_freeSpinStartCall()
        end
    end,2 + (36/30))
    
end

----------- FreeSpin相关

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenBingoPriatesMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum
    if lineValue.vecValidMatrixSymPos then
        frameNum = #lineValue.vecValidMatrixSymPos
    end

    local animTime = 0

    -- self:operaBigSymbolMask(true)
    local isAct = false

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
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
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
            if i == 1 then
                if slotNode then
                    isAct = true
                end
                slotNode:runAnim("actionframe",false,function(  )

                    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

                end)
                
            end
            

        end
    end


    if not isAct then
        scheduler.performWithDelayGlobal(function (  )   
            self:palyBonusAndScatterLineTipEnd(animTime,callFun)
        end,2.5,self:getModuleName())
    end
    

end

function CodeGameScreenBingoPriatesMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3 -- slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE



    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder + 1000)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runLineAnim()
    end
    return slotNode
end

-- 显示free spin
function CodeGameScreenBingoPriatesMachine:showEffect_FreeSpin(effectData)

    self.isInBonus = true

            
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
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

    scheduler.performWithDelayGlobal(function (  )

        if self.m_winSoundsId ~= nil then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        if scatterLineValue ~= nil then
            --
            self:showBonusAndScatterLineTip(scatterLineValue,function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end)
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        else
            self:showFreeSpinView(effectData)
        end
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
        
    end,0.5,self:getModuleName())

   
    return true
end

function CodeGameScreenBingoPriatesMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)

    -- animTime = 3

    -- -- 延迟回调播放 界面提示 bonus  freespin
    -- performWithDelay(self,function(  )
        self:resetScatterMaskLayerNodes()
        callFun()
    -- end,animTime)

end

function CodeGameScreenBingoPriatesMachine:resetScatterMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                lineNode:removeFromParent()
                -- if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                -- end
                local nZOrder = lineNode.p_showOrder
                -- if preParent == self.m_clipParent then
                --     nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                -- end
                preParent:addChild(lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
                lineNode:setVisible(false)
            end
        end
    end
end


-- FreeSpinstart
function CodeGameScreenBingoPriatesMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            local BingoPriates_Mask = self:findChild("BingoPriates_Mask")
            if BingoPriates_Mask then
                BingoPriates_Mask:setVisible(false)
                util_playFadeOutAction( BingoPriates_Mask , 0.1 ,function (  )
                    BingoPriates_Mask:setVisible(true)
                    util_playFadeInAction( BingoPriates_Mask , 0.2 )
                end)
            end

            self.m_freeSpinScatterList = self:CreateScatterClickCsb()
            self.m_scatterClickList = self:createScatterClickView()
            self.m_freeSpinStartCall = function()

                
                performWithDelay(self,function(  )
                    local BingoPriates_Mask = self:findChild("BingoPriates_Mask")
                    BingoPriates_Mask:setVisible(false)
                    if BingoPriates_Mask then
                        
                        util_playFadeOutAction( BingoPriates_Mask , 0.2 ,function (  )
                            BingoPriates_Mask:setVisible(false)
                            util_playFadeInAction( BingoPriates_Mask , 0.1 )
                        end)
                    end

                    for i=1,#self.m_freeSpinScatterList do
                        local scatter = self.m_freeSpinScatterList[i]
                        if scatter then
                            local reelScatter = scatter.reelScatter
                            if reelScatter then
                                reelScatter:setVisible(true)
                            end
                            scatter:removeFromParent()
                        end
                    end 

                    self.m_freeSpinScatterList = nil
                    self.m_freeSpinStartCall = nil
                end,0.2)
                

                gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Start_fsView.mp3")

                local freeSpinsTotalCount =  self.m_runSpinResultData.p_freeSpinsTotalCount
                local view = self:showFreeSpinStart(freeSpinsTotalCount,function(  )

                    local lastWinCoin = globalData.slotRunData.lastWinCoin
                    globalData.slotRunData.lastWinCoin = 0
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
                    globalData.slotRunData.lastWinCoin = lastWinCoin  

                   


                    self:setBingoUiDark( true )
                    
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
                view.m_btnTouchSound = "BingoPriatesSounds/BingoPriates_Click.mp3"
                
                
                
            end

        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    showFSView()    


    

end

---------------------------------弹版----------------------------------
function CodeGameScreenBingoPriatesMachine:CreateScatterClickCsb()

    local scatterList = {}

    for iCol = 1, self.m_iReelColumnNum do

        for iRow = 1, self.m_iReelRowNum do
            
            local tarSp = self:getFixSymbol(iCol , iRow, SYMBOL_NODE_TAG)
            if tarSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local node = util_createAnimation( self:MachineRule_GetSelfCCBName(self.SYMBOL_SCATRER_CLICK) .. ".csb")
                local index = self:getPosReelIdx(tarSp.p_rowIndex, tarSp.p_cloumnIndex)
                self:addChild(node,GAME_LAYER_ORDER.LAYER_ORDER_TOP + 2 )
                node:setScale(self.m_machineRootScale)
                local pos = cc.p(util_getConvertNodePos(tarSp,node))  
                node:setPosition(pos)
                node.p_rowIndex = tarSp.p_rowIndex
                node.p_cloumnIndex = tarSp.p_cloumnIndex
                node.reelScatter = tarSp
                table.insert(scatterList,node)
                node:runCsbAction("idleframe2",true)
                tarSp:setVisible(false)
            end

        end
    end

    return scatterList
end

function CodeGameScreenBingoPriatesMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin( globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:clearCurMusicBg()


    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_FreespinGameEnd.mp3")

    performWithDelay(self,function(  )

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearFrames_Fun()
        -- 重置连线信息
        -- self:resetMaskLayerNodes()
        self:showFreeSpinOverView()

    end,3)


    
end

function CodeGameScreenBingoPriatesMachine:showFreeSpinOverView()
    
        gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_over_fsView.mp3")

        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            self:setBingoUiDark(  )
            self:checkLocalGameNetDataFeatures() -- 添加feature
            self:triggerFreeSpinOverCallFun()
        end)
        view.m_btnTouchSound = "BingoPriatesSounds/BingoPriates_Click.mp3"

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},674)
   
   

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBingoPriatesMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.isInBonus = false

    self:setMysterTypeFromNet( )

    -- self.m_BonusBingoCollectNdoe:removeAllChildren()
    self:restFlyWild( )

    self.m_TipView:setVisible(false)    
    self:ShowTipChangeReelNodeVisible( )

    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenBingoPriatesMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenBingoPriatesMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBingoPriatesMachine:addSelfEffect()

        
    -- 倒序播放
    -- base玩法 effect
    self:addTriggerBingoEffect() 
    self:addBoomBingoEffect() 

    -- 特殊玩法 effect
    self:addFreeSpinWildChangeEffect( )

end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBingoPriatesMachine:MachineRule_playSelfEffect(effectData)


    if effectData.p_selfEffectType == self.FREESPIN_WILD_CHANGE then
        -- freeSpin wild 列 变化
        self:freeSpinWildChangeFunc(effectData)


    elseif effectData.p_selfEffectType == self.BASE_BONUS_BOOM_EFFECT then

        -- 炸弹飞行
        self:BonusBoomFlyBingoReel(effectData)

    elseif effectData.p_selfEffectType == self.BASE_TRIGGER_BINGO_EFFECT then
        -- 触发了bingo连线玩法
        self:TriggerBingoLines(effectData)

    end



    
	return true
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBingoPriatesMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenBingoPriatesMachine:setMysterTypeFromNet( )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local symbolType = selfData.mysterySignalNext  or 0
    self.m_configData:setMysterSymbol( symbolType)

end

function CodeGameScreenBingoPriatesMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        for rowIndex = 1, rowCount do 
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            --初始化轮盘去掉 长条信号
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end

            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
end

function CodeGameScreenBingoPriatesMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if symbolType == self.SYMBOL_FIX_BONUS then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end



    return node
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenBingoPriatesMachine:getBingoSymbolScore(id)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local  bingoBalls = selfdata.bingoBalls or {}

    local score = nil
    for i=1,#bingoBalls do
        local info = bingoBalls[i]
        if info then
            local reelPosition = info.reelPosition
            local ballNum = info.ballNum

            if id == reelPosition then

                score = ballNum

                break
            end
        end
        
    end

    if score == nil then
       return self:randomDownRespinSymbolScore(self.SYMBOL_FIX_BONUS)
    end

    return score
end

function CodeGameScreenBingoPriatesMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_FIX_BONUS then

        score = math.random(1,76) - 1

    end


    return score
end

-- 给Bonus小块进行赋值
function CodeGameScreenBingoPriatesMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    
    if symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS then
        local rowCount = 0
        if iCol ~= nil then
            local columnData = self.m_reelColDatas[iCol]
            rowCount = columnData.p_showGridCount
        end
    
    
        if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
            
            local score = self:getBingoSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
            local index = 0
            if score ~= nil and type(score) ~= "string" then
                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab then
                    score = util_formatCoins(score, 3)
                    lab:setString(score)
                end
            end
    
        else
            local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
            if score ~= nil  then
                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab then
                    score = util_formatCoins(score, 3)
                    lab:setString(score)
                end
                
            end
            
        end
    end
end


--------------
----------
--------
-----
-- 船长玩法 相关

function CodeGameScreenBingoPriatesMachine:addCaptainGameEffect( curreCaptainType )

    local bingoData = self.m_BingoNetData or {}
    local captainPlay = bingoData.captainPlay

    if captainPlay and captainPlay ~= -1 and curreCaptainType == captainPlay then

        if captainPlay == self.m_AddBaseReelWild then -- 随机网base轮盘添加wild

           return true
        elseif captainPlay == self.m_AddBingoReelCollectPos then -- 随机添加轮盘收集位置
            return true
        end


    end

        
    
    
end

------------
---------
-------
------
--随机网base轮盘添加wild
function CodeGameScreenBingoPriatesMachine:changeFlyWildList( )
    
    for k,node in pairs(self.m_flyWildList) do
        local name = node:getName()
        local oldNode = self.m_clipParent:getChildByName(name)
        if oldNode then
            self.m_flyWildList[k] = oldNode
        end
    end
end

function CodeGameScreenBingoPriatesMachine:restFlyWild( )
    
    self:changeFlyWildList()

    for i=1,#self.m_flyWildList do
        local wild = self.m_flyWildList[i]
        if wild then
            local linePos = {}
            wild.m_bInLine = false
            wild:setLinePos(linePos)
            wild:setName("")
            wild:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            wild.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3 + 1

        end
    end

    self.m_flyWildList = {}
end

function CodeGameScreenBingoPriatesMachine:initFlyWild( wildPositions)

    
    self.m_flyWildList = {}

    for i=1,#wildPositions do
        local endPos = wildPositions[i]
        local v = endPos
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY, false)   

        if targSp  then -- and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD

            targSp:setName("baseFlyWild_"..i)
            targSp:setVisible(false)

            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
            self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - targSp.p_rowIndex + 10 ,targSp.p_cloumnIndex * SYMBOL_NODE_TAG + targSp.p_rowIndex )
            local position =  util_getOneGameReelsTarSpPos(self,pos) 
            targSp:setPosition(cc.p(position))

            table.insert( self.m_flyWildList, targSp )
        end

    end


    return self.m_flyWildList
end

function CodeGameScreenBingoPriatesMachine:runFlyWildAct( flyWildList,func)

    local callFunc = func

    local maxTime = 8/10


    for i=1,#flyWildList do
        local endNode = flyWildList[i]
        endNode:setVisible(false)

        local rodTime = math.random(0,5) / 10

        if i == 1 then
            self:fly_One_Boom_OneTimesAct(endNode,function(  )
                if callFunc then
                    callFunc()
                end
                gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Zha_Wild.mp3")
                endNode:setVisible(true)
                endNode:runAnim("buling")
            end,true,maxTime )

        else

            self:fly_One_Boom_OneTimesAct(endNode,function(  )
                gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Zha_Wild.mp3")
                endNode:setVisible(true)
                endNode:runAnim("buling")
            end ,true,rodTime )
        end


        

        

    end
    
end

function CodeGameScreenBingoPriatesMachine:TriggerCaptainGame_AddBaseReelWild()

    self:CaptainGameActThreeTimes( function(  )
            local selfdata = self.m_runSpinResultData.p_selfMakeData
            -- 飞wild
            -- 初始化wild信号
            local wildPositions =  selfdata.dropWilds or  {} 
            local flyWildList =  self:initFlyWild( wildPositions)
            self:runFlyWildAct( flyWildList,function(  )
    
                self.m_m_CaptainMan_bg:runCsbAction("actionframe3_over",false,function(  )
                    self.m_m_CaptainMan_bg:setVisible(false)
                end)

                self:netBackReelsStop( )
                
            end)
    
    end )


end

--------------
----------
--------
-----
-- bingoReel 船长玩法 添加bingo收集位置 相关

function CodeGameScreenBingoPriatesMachine:TriggerCaptainGame_BoomFlyToBingoReel(  )


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local  bingoBalls = selfdata.bingoBalls or {}
    local isTrigger = false
    local actList = {}
    for i=1,#bingoBalls do
        local info = bingoBalls[i]
        if info then
            local reelPosition = info.reelPosition
            local ballNum = info.ballNum
            local cardPosition = info.cardPosition
            if cardPosition then

                -- reelPosition == -1 说明是船长玩法触发的
                if cardPosition ~= -1 and reelPosition == -1 then
                    table.insert(actList,info)

                end
            end

        end
        
    end

        
    local BoomFlyToBingoReel = function( )
        self.m_m_CaptainMan_bg:runCsbAction("actionframe3_over",false,function(  )
            self.m_m_CaptainMan_bg:setVisible(false)
        end)

       
        self:Captain_playBonusBingoCollectAni( actList , function(  )

            self:netBackReelsStop( )

        end )



    end

    if #actList > 0 then

        if #actList == 1 then
            self:CaptainGameActOneTimes( function(  )
                BoomFlyToBingoReel()
            end )
        
        elseif #actList == 2 then
            self:CaptainGameActTwoTimes( function(  )
                BoomFlyToBingoReel()
            end )
        else
            self:CaptainGameActThreeTimes( function(  )
       
                BoomFlyToBingoReel()
            end )
        end
        
    end


    
    

   



end

--------------
----------
--------
-----
-- bingoReel 连成线 相关

function CodeGameScreenBingoPriatesMachine:addTriggerBingoEffect( )

    local bingoData = self.m_BingoNetData or {}
    local bingo = bingoData.bingo

    if bingo then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BASE_TRIGGER_BINGO_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BASE_TRIGGER_BINGO_EFFECT -- 动画类型
    end
    
end

function CodeGameScreenBingoPriatesMachine:winBingoRestBingoUI( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local bingoData = selfdata.newBingoData or self.m_BingoNetData or {}

    -- 初始化bingo轮盘
    local bingoCards = bingoData.bingoCards
    if bingoCards then
        self.m_BingoReel:updateBingoTextNum( bingoCards )
    end

    -- 初始化平均betUI
    local avgBet = bingoData.avgBet 
    if avgBet then
        self.m_ChestBar:updateBingoAvgBetNum( avgBet )
    end

    -- 初始化倍数
    local bingoMul = bingoData.bingoMul
    if bingoMul then
        self.m_BingoReel:updateBingoMulNum( bingoMul )
        
    end

    -- 初始化金色骷髅位置
    local goldenBoneHit = bingoData.goldenBoneHit
    if goldenBoneHit then
        self.m_BingoReel:updateBingoGoldBonePos( goldenBoneHit )
        
    end

    -- 初始化金币池位置
    local coinsHeap = bingoData.coinsHeap
    if coinsHeap then
        self.m_BingoReel:updateBingoCoinsPoolPos( coinsHeap )
        
    end

    
    -- 初始化紫色骷髅位置
    local bingoHit = bingoData.bingoHit
    if bingoHit then
        self.m_BingoReel:updateBingoPurpleBonePos( bingoHit )
        
    end

    -- 初始化 标记一个数字，若这个数字被bonus覆盖后会马上赢得bingo奖励
    local markSignal = bingoData.markSignal
    if markSignal then
        for i=1,#markSignal do
            local netPos = markSignal[i] + 1
            self.m_BingoReel:setBingoWinAllLab( netPos )
        end
    end

end

function CodeGameScreenBingoPriatesMachine:showBingoLinesAct( bingoLines ,func )
    
    self.m_PurpleBoneActNodeList = {}
    self.m_PurpleBoneActIndex = 1
    self.m_m_PurpleBoneActCallFunc = function(  )
        if func then
            func()
        end
    end
    for i=1,#bingoLines do
        local lineInfo = bingoLines[i]
        for k = 1,#lineInfo do
            local pos = lineInfo[k] + 1
            local PurpleBone = self.m_BingoReel["PurpleBone_" .. pos]
            table.insert(self.m_PurpleBoneActNodeList,PurpleBone)
        end
    end

    self:PurpleBoneRunBingoLinesAct()

end

function CodeGameScreenBingoPriatesMachine:PurpleBoneRunBingoLinesAct( )

    if self.m_PurpleBoneActIndex > #self.m_PurpleBoneActNodeList then
        
        local aniNode = cc.Node:create()
        self:addChild(aniNode)
        performWithDelay(self,function(  )
            if self.m_m_PurpleBoneActCallFunc then
                self.m_m_PurpleBoneActCallFunc()
            end 
            aniNode:removeFromParent()
        end,126/30)
        

        return
    end

    
    local actNdoe = self.m_PurpleBoneActNodeList[self.m_PurpleBoneActIndex]
    actNdoe:runCsbAction("actionframe",false,function(  )
        actNdoe:runCsbAction("actionframe")
    end)

    self.m_PurpleBoneActIndex = self.m_PurpleBoneActIndex + 1
    self:PurpleBoneRunBingoLinesAct()
        


end

function CodeGameScreenBingoPriatesMachine:collectShipProcessAni( time , func )
    local AniNode = util_createAnimation("BingoPriates_bingolianxian.csb")
    self:addChild(AniNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startWorldPos = self.m_BingoReel:findChild("Node_13"):getParent():convertToWorldSpace(cc.p(self.m_BingoReel:findChild("Node_13"):getPosition())) 
    local startPos = self:convertToNodeSpace(cc.p(startWorldPos))
    
    local endWorldPos = self.m_GoldBoneBar:findChild("Node_Act"):getParent():convertToWorldSpace(cc.p(self.m_GoldBoneBar:findChild("Node_Act"):getPosition())) 
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))

    local Particle =  AniNode:findChild("Particle_1")
    if Particle then
        Particle:setPositionType(0)
        Particle:setDuration(time + 1.1)
    end

    AniNode:setPosition(startPos)
    AniNode:runCsbAction("actionframe",false,function(  )
        
        

        local actionList = {}
        actionList[#actionList + 1] = cc.CallFunc:create(function( )
            AniNode:runCsbAction("shouji")
            
        end)
        actionList[#actionList + 1] = cc.MoveTo:create(time, cc.p(endPos.x, endPos.y))
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            if func then
                func()
            end
        end)
        local sq = cc.Sequence:create(actionList)
        AniNode:runAction(sq)
        
    end)

end

function CodeGameScreenBingoPriatesMachine:TriggerBingoLines( effectData )

   
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local newBingoData = selfdata.newBingoData or {} 
    local bingoLines  = selfdata.bingoLines or {}
    local coins = selfdata.bingoWin or 0
    local bingoData = self.m_BingoNetData or {}
    local markGoldenBoneHit =  bingoData.markGoldenBoneHit or {}

    -- 金币池 这个字段是不对
    local markCoinsHit = bingoData.markCoinsHit or {}

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bingoLines")
    end

    local showBingoWinView = function(  )

        
        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_BingoWinCoinsAct.mp3")

        self:showBingoLinesAct( bingoLines ,function(  )

            gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_bingoLines_collect.mp3")

            self:collectShipProcessAni( 0.5 , function(  )
                
                local bingoData =  self.m_BingoNetData or {}
                -- 初始化金骷髅进度
                local goldenBoneProcess = bingoData.goldenBoneProcess

                if goldenBoneProcess then
                    if goldenBoneProcess > self.m_GoldBoneBar.BarMaxNum then
                        goldenBoneProcess = self.m_GoldBoneBar.BarMaxNum 
                    end
                    self.m_GoldBoneBar:beginProcessAct( goldenBoneProcess , function(  )
                        
                        performWithDelay(self,function(  )
                            self:winBingoRestBingoUI( )
                        end,0.5)
        
                        self:showBonusOverView( coins, function(  )
                
                            self:resetMusicBg()
                            
                            if self.m_serverWinCoins and coins and coins ~= 0 and self.m_serverWinCoins == coins then
        
                                -- 通知bonus 结束， 以及赢钱多少
                                self:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_SELF_EFFECT,self.BASE_TRIGGER_BINGO_EFFECT)
                                self:updateQuestBonusRespinEffectData()
                
                            end
        
                            if effectData then
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
        
                            if self.m_serverWinCoins and coins and coins ~= 0 and self.m_serverWinCoins == coins then
                                -- 更新游戏内每日任务进度条
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,true})
        
                            end
                
                        end )

                    end  )
                    
                end
                
                
            end )

            
    
        end )
    end

    local currCallFunc = function(  )
        if #markGoldenBoneHit > 0 then
            -- 播放金骷髅收集
            for i=1,#markGoldenBoneHit do
                local cardPosition = markGoldenBoneHit[i]
                if i == #markGoldenBoneHit then
                    self:GoldBoneBingoCollectAction(cardPosition,function(  )
                        showBingoWinView()
                    end )
                else
                    self:GoldBoneBingoCollectAction(cardPosition,nil,true)
                end
                
            end
    
        else
            showBingoWinView()
        end
    end

    if table_length(markCoinsHit) ~= 0  then
        
        local index = 0
        
        for k,v in pairs(markCoinsHit) do
            index = index + 1
            local bingoReelPos = tonumber(k) 
            local coins = v
            local flyEndFunc = nil
            if index == table_length(markCoinsHit) then
                flyEndFunc = function(  )
                    currCallFunc()
                end
            end
            local actNdoe = cc.Node:create()
            self:addChild(actNdoe)
            performWithDelay(self,function(  )
                self:CoinsHeapBingoCollectAction(bingoReelPos,function(  )

                    if flyEndFunc then
                        flyEndFunc()
                    end
                   
                
                end,nil,coins)

                actNdoe:removeFromParent()

            end,0.5 * (index - 1))
            
        end

    else
        currCallFunc()
    end

   
    

 

end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenBingoPriatesMachine:checkFeatureOverTriggerBigWin( winAmonut , feature,selfEffectType)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i=1,#self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if selfEffectType then
                if effectData.p_effectType == feature and effectData.p_selfEffectType == selfEffectType then
                    isAddEffect = true
                    self.m_llBigOrMegaNum = winAmonut
    
    
                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert( self.m_gameEffects, i + 1, delayEffect )
    
                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert( self.m_gameEffects, i + 2, effectData )
                    break
                end
            else
                if effectData.p_effectType == feature then
                    isAddEffect = true
                    self.m_llBigOrMegaNum = winAmonut
    
    
                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert( self.m_gameEffects, i + 1, delayEffect )
    
                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert( self.m_gameEffects, i + 2, effectData )
                    break
                end
            end
            
        end
        if isAddEffect == false then
            for i=1,#self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut


                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert( self.m_gameEffects, i + 1, delayEffect )

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert( self.m_gameEffects, i + 2, effectData )
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert( self.m_gameEffects, 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, 2, effectData )
            end
        end

    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end

--------------
----------
--------
-----
-- 炸弹飞到bingoReel 相关
function CodeGameScreenBingoPriatesMachine:addBoomBingoEffect( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local  bingoBalls = selfdata.bingoBalls or {}
    local isTrigger = false
    for i=1,#bingoBalls do
        local info = bingoBalls[i]
        if info then
            local reelPosition = info.reelPosition
            local ballNum = info.ballNum
            local cardPosition = info.cardPosition
            if cardPosition then
                
                if cardPosition ~= -1 and reelPosition ~= -1 then
                    isTrigger = true
                end
            end

        end
        
    end

    if isTrigger then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BASE_BONUS_BOOM_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BASE_BONUS_BOOM_EFFECT -- 动画类型
        
        
    end
end


function CodeGameScreenBingoPriatesMachine:BonusBingoCollectAction(beginIndex,endIndex,Score,moveTime,delayTimes,func )
    

    local fixPos = self:getRowAndColByPos(beginIndex)
    local beginNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    local bingoReelNode = self.m_BingoReel:findChild("Node_" .. endIndex + 1)


    if beginNode and bingoReelNode then
        local actNode = cc.Node:create()
        self.m_BonusBingoCollectNdoe:addChild(actNode)

        actNode:setScale(self.m_machineRootScale)

        local node = util_createAnimation("Socre_BingoPriates_Linghting.csb")
        actNode:addChild(node)

        local BoomAct = util_createAnimation("Socre_BingoPriates_Boom.csb")
        actNode:addChild(BoomAct)
        BoomAct:setVisible(false)
    

        local startWorldPos = beginNode:convertToWorldSpace(cc.p(beginNode:getCcbProperty("Node_actMove"):getPosition())) 
        local startPos = self:convertToNodeSpace(cc.p(startWorldPos))
        actNode:setPosition(startPos)

        local lab = node:findChild("m_lb_score")
        if lab then
            lab:setString(Score)
        end
        
        beginNode:changeCCBByName(self:MachineRule_GetSelfCCBName(self.SYMBOL_SILVER_BONUES),self.SYMBOL_SILVER_BONUES)
        
        local endWorldPos =  self.m_BingoReel:convertToWorldSpace(cc.p( bingoReelNode:getPosition())) 
        local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
        local actionList = {}
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            node:runCsbAction("idleframe2")
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(delayTimes)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            node:runCsbAction("actionframe")
        end)
        actionList[#actionList + 1] = cc.JumpTo:create(moveTime, cc.p(endPos),200, 1) 
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_EndFly.mp3")
            BoomAct:setVisible(true) 
            node:setVisible(false)
            local BoomAct_1 = BoomAct
            BoomAct:runCsbAction("actionframe",false,function(  )
                BoomAct_1:setVisible(false)
            end)
            
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(9/30) -- BoomAct 炸到最大时
        actionList[#actionList + 1] = cc.CallFunc:create(function()
  
            if func then
                func()
            end
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(1)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
  
            actNode:removeFromParent()
        end)



        actNode:runAction(cc.Sequence:create(actionList))
    end

    

    

end

function CodeGameScreenBingoPriatesMachine:BonusBoomFlyBingoReel(effectData )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local  bingoBalls = selfdata.bingoBalls or {}
    local isTrigger = false
    local actList = {}
    for i=1,#bingoBalls do
        local info = bingoBalls[i]
        if info then
            local reelPosition = info.reelPosition
            local ballNum = info.ballNum
            local cardPosition = info.cardPosition
            if cardPosition then
                
                if cardPosition ~= -1 and reelPosition ~= -1 then
                    table.insert(actList,info)

                end
            end

        end
        
    end

    self:playBonusBingoCollectAni( actList , function(  )

        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end

    end )

end

--------------
----------
--------
-----
-- freespin_wild移动相关

function CodeGameScreenBingoPriatesMachine:addFreeSpinWildChangeEffect( )
    
    self.m_aFreeSpinWildArry = {}


    if self:getCurrSpinMode() == FREE_SPIN_MODE then    

            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local freeLockWilds = selfData.freeLockWilds or {}

            local tableNum = self:checkTableNum( freeLockWilds )
            

            if tableNum and  tableNum > 0 then
                for iCol = 1, self.m_iReelColumnNum  do         --列
                    local tempRow = nil
                    for iRow = self.m_iReelRowNum , 1, -1 do     --行
                        if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                            tempRow = iRow
                        else
                            break
                        end
                    end
                    if tempRow ~= nil  then
                        self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "down"}
                    end
        
                    tempRow = nil
                    for iRow = 1, self.m_iReelRowNum, 1 do     --行
                        if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                            tempRow = iRow
                        else
                            break
                        end
                    end
        
                    if tempRow ~= nil and tempRow ~= self.m_iReelRowNum then
                        self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "up"}
                    end
        
                end
            end
            
    end
   if self:getCurrSpinMode() == FREE_SPIN_MODE and #self.m_aFreeSpinWildArry > 0 then
       local wildChangeEffect = GameEffectData.new()
       wildChangeEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
       wildChangeEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
       wildChangeEffect.p_selfEffectType = self.FREESPIN_WILD_CHANGE
       self.m_gameEffects[#self.m_gameEffects + 1] = wildChangeEffect
   end


end

function CodeGameScreenBingoPriatesMachine:freeSpinWildChangeFunc(effectData)
        local delayTime = 0.5
        local runTime = 0.5 
        for i = 1, #self.m_aFreeSpinWildArry, 1 do
            local temp = self.m_aFreeSpinWildArry[i]
            local iRow = temp.row
            local iCol = temp.col
            local currRow = iRow
            
            local iTempRow = {} --隐藏小块避免穿帮

            if temp.direction == "up" then --    4,3,2 
                
                currRow =  temp.row + 1 - 4
            else   -- 1,2,3


            end

            local maxZOrder = 0
            local nodeList = {}
            for j = 1, self.m_iReelRowNum , 1 do
                local node =  self:getFixSymbol(iCol , j, SYMBOL_NODE_TAG)
                if node ~= nil and node.p_symbolType ~= self.SYMBOL_LONG_WILD then -- 移除被覆盖度额小块
                    table.insert(nodeList,node)
                    if maxZOrder <  node:getLocalZOrder() then
                        maxZOrder = node:getLocalZOrder()
                    end
                    
                end
            end

            -- 把这一列的长条信息添加到存储数据中
            self:addBigSymbolInfo( iCol )


            local posIndex = self:getPosReelIdx(currRow, iCol)
            local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_ACT_WILD, currRow, iCol, false)   
            targSp:getCcbProperty("Particle_1"):setVisible(false)

            if targSp  then 
    
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                local linePos = {}
                for row = 1,self.m_iReelRowNum do
                    linePos[#linePos + 1] = {iX = row, iY = iCol}
                end
                
                
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)
                self:getReelBigParent(iCol):addChild(targSp,maxZOrder * 1000, targSp.p_cloumnIndex * SYMBOL_NODE_TAG + targSp.p_rowIndex)
                targSp.p_rowIndex = 1
                

                local pos =  cc.p(self:getPosByColAndRow(iCol, currRow))
                local posEnd =  cc.p(self:getPosByColAndRow(iCol,1))
                if temp.direction == "up" then 
                    posEnd =  cc.p(self:getPosByColAndRow(iCol, 1))
                end

                targSp:setPosition(pos)
                
                local distance = posEnd.y
                
                local actionList = {}
                actionList[#actionList + 1] = cc.CallFunc:create(function ()
                    targSp:getCcbProperty("Particle_1"):setVisible(true)
                    targSp:getCcbProperty("Particle_1"):resetSystem()
                    targSp:runAnim("actionframe")

                end)
                actionList[#actionList + 1] = cc.MoveTo:create(runTime, cc.p(posEnd.x, posEnd.y))
                actionList[#actionList + 1] = cc.DelayTime:create(delayTime)
                actionList[#actionList + 1] = cc.CallFunc:create(function ()

                    targSp:changeCCBByName(self:MachineRule_GetSelfCCBName(self.SYMBOL_LONG_WILD),self.SYMBOL_LONG_WILD)
                    targSp:setLocalZOrder( REEL_SYMBOL_ORDER.REEL_ORDER_1 - targSp.p_rowIndex + self:getBounsScatterDataZorder(targSp.p_symbolType ))
                   

                    for i=1,#nodeList do
                        local node = nodeList[i]
                        if node then
                            self:moveDownCallFun(node, node.p_cloumnIndex) 
                        end
                        
                    end

                end)

                
                local seq = cc.Sequence:create(actionList)
                targSp:runAction(seq)

            end
            

        end


        gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_FS_Wild_Act.mp3")

        scheduler.performWithDelayGlobal(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,  delayTime + runTime + 0.2, self:getModuleName())
end

function CodeGameScreenBingoPriatesMachine:oneLabJump( lab,coins,oldCoins ,sxNum ,syNum ,length,jumTime)

    if oldCoins < coins then
        local startValue = oldCoins
        local addValue = (coins - startValue) /jumTime
        local sxNum_1 ,syNum_1 ,length_1 = sxNum ,syNum ,length
        local lab_1 = lab
        util_jumpNum(lab_1,startValue,coins,addValue,0.02,{50},nil,nil,function(  )
    
        end,function(  )
    
            self:updateLabelSize({label=lab_1,sx = sxNum_1,sy=syNum_1},length_1)
    
        end) 
    end
    
end

function CodeGameScreenBingoPriatesMachine:netBackUpdataLocalUI( )
    
        
        
        -- 更新本地bingo表
        local selfdate = self.m_runSpinResultData.p_selfMakeData or {}
        local bingoData = selfdate.bingoData or {}
        self.m_BingoNetData = bingoData 


        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local jackpotData = selfdata.jackpotData 
        if jackpotData  then

            

            if self:checkUpdateJackpotInfo(  jackpotData ) then

                self:oneLabJump( self.m_JackPotBar:findChild("grand_shuzi"),jackpotData.Grand,self.m_JackPotBar.m_GrandOldCoins,1 ,1 ,226,20 )
                self:oneLabJump( self.m_JackPotBar:findChild("major_shuzi"),jackpotData.Major,self.m_JackPotBar.m_MajorOldCoins,1 ,1 ,154,20 )
                self:oneLabJump( self.m_JackPotBar:findChild("minor_shuzi"),jackpotData.Minor,self.m_JackPotBar.m_MiniOldCoins,1 ,1 ,134,20 )
            

                self.m_JackPotBar:updateJackpotInfo(jackpotData)
            end
            
 
        end
        
        local bingoData =  self.m_BingoNetData or {}
        -- 初始化平均betUI
        local avgBet = bingoData.avgBet 
        if avgBet then

            self:oneLabJump( self.m_ChestBar:findChild("BitmapFontLabel_1"),avgBet,self.m_ChestBar.m_OldAvgBet,0.65 ,0.65 ,267 ,20)
            
            self.m_ChestBar:updateBingoAvgBetNum( avgBet )
        end

end

function CodeGameScreenBingoPriatesMachine:beginOperaNetData( )
    
end

function CodeGameScreenBingoPriatesMachine:updateNetWorkData()

    self:netBackUpdataLocalUI()

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


    -- 船长玩法gameType
    local AddBaseReelWild =  self:addCaptainGameEffect( self.m_AddBaseReelWild ) --随机网base轮盘添加wild  
    local AddBingoReelCollectPos =  self:addCaptainGameEffect( self.m_AddBingoReelCollectPos ) --随机添加轮盘收集位置

    if AddBaseReelWild then
        -- 随机网base轮盘添加wild
        self:TriggerCaptainGame_AddBaseReelWild()
    elseif AddBingoReelCollectPos then
        --随机添加轮盘收集位置
        self:TriggerCaptainGame_BoomFlyToBingoReel(  )
    else
        self:netBackReelsStop( )
    end

end

function CodeGameScreenBingoPriatesMachine:netBackReelsStop( )

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()

end

function CodeGameScreenBingoPriatesMachine:initBingoUi( )
    
    local bingoData =  self.m_BingoNetData or {}

    -- 初始化bingo轮盘
    local bingoCards = bingoData.bingoCards
    if bingoCards then
        self.m_BingoReel:updateBingoTextNum( bingoCards )
    end

    -- 初始化平均betUI
    local avgBet = bingoData.avgBet 
    if avgBet then
        self.m_ChestBar:updateBingoAvgBetNum( avgBet )
    end

    -- 初始化倍数
    local bingoMul = bingoData.bingoMul
    if bingoMul then
        self.m_BingoReel:updateBingoMulNum( bingoMul )
        
    end

    -- 初始化金骷髅进度
    local goldenBoneProcess = bingoData.goldenBoneProcess
    if goldenBoneProcess then
        if goldenBoneProcess > self.m_GoldBoneBar.BarMaxNum then
            goldenBoneProcess = self.m_GoldBoneBar.BarMaxNum -- goldenBoneProcess - self.m_GoldBoneBar.BarMaxNum
        end

        self.m_GoldBoneBar:updateBingoGoldenBoneProcess( goldenBoneProcess )
    end

    -- 初始化宝箱进度
    local boxProcess = bingoData.boxProcess
    if boxProcess then
        if boxProcess > self.m_ChestBar.ChestMaxNum then
            boxProcess = self.m_ChestBar.ChestMaxNum -- boxProcess - self.m_ChestBar.ChestMaxNum
        end

        self.m_ChestBar:updateBingoChestBoxProcess( boxProcess )
    end

    -- 初始化金色骷髅位置
    local goldenBoneHit = bingoData.goldenBoneHit
    if goldenBoneHit then
        self.m_BingoReel:updateBingoGoldBonePos( goldenBoneHit )
        
    end

     -- 初始化金币池位置
     local coinsHeap = bingoData.coinsHeap
     if coinsHeap then
         self.m_BingoReel:updateBingoCoinsPoolPos( coinsHeap )
         
     end
     
    -- 初始化紫色骷髅位置
    local bingoHit = bingoData.bingoHit
    if bingoHit then
        self.m_BingoReel:updateBingoPurpleBonePos( bingoHit )
        
    end

    -- 初始化 标记一个数字，若这个数字被bonus覆盖后会马上赢得bingo奖励
    local markSignal = bingoData.markSignal
    if markSignal then
        for i=1,#markSignal do
            local netPos = markSignal[i] + 1
            self.m_BingoReel:setBingoWinAllLab( netPos )
        end
    end
    
    

end

function CodeGameScreenBingoPriatesMachine:checkTableNum( table_name , value)
    
    local num = 0
    local isHave = false

    if table_name then
        for k,v in pairs(table_name) do
            num = num + 1
            if value then
                if tonumber(k) == value then
                    isHave = true
                end
            end
            
        end
    end

    
    return num ,isHave
end

function CodeGameScreenBingoPriatesMachine:getTableValue( table_name,kNum )
    local value = nil

    if table_name then
        for k,v in pairs(table_name) do
            if kNum == tonumber(k)  then
                value = v
                return value
            end
        end
    end

    return value
end

function CodeGameScreenBingoPriatesMachine:getPosByColAndRow(col, row)
    local posX = self.m_SlotNodeW
    local posY = (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

function CodeGameScreenBingoPriatesMachine:addBigSymbolInfo( icol )
        -- 处理大信号信息
        if self.m_hasBigSymbol == true then
            self.m_bigSymbolColumnInfo = {}
        else
            self.m_bigSymbolColumnInfo = nil
        end
    
        local iColumn = self.m_iReelColumnNum
        local iRow = self.m_iReelRowNum
    
        for colIndex=1,iColumn do
            
            local isBigSymbolCol = false
            if colIndex == icol then
                isBigSymbolCol = true
            end

            local rowIndex=1
            if isBigSymbolCol then
                while true do
                    if rowIndex > iRow then
                        break
                    end
                    local symbolType = 0
                    if isBigSymbolCol then
                        symbolType = self.SYMBOL_LONG_WILD
                    end
                    -- 判断是否有大信号内容
                    if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil  then
        
                        local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG,changeRows = {}}
                        
                        
                        local colDatas = self.m_bigSymbolColumnInfo[colIndex]
                        if colDatas == nil then
                            colDatas = {}
                            self.m_bigSymbolColumnInfo[colIndex] = colDatas
                        end           
        
                        colDatas[#colDatas + 1] = bigInfo     
        
                        local symbolCount = self.m_bigSymbolInfos[symbolType]
        
                        local hasCount = symbolCount
        
                        bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex
        
        
                        if symbolCount == hasCount or rowIndex > 1 then  -- 表明从对应索引开始的
                            bigInfo.startRowIndex = rowIndex
                        else
        
                            bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
                        end
        
                        rowIndex = rowIndex + hasCount - 1  -- 跳过上面有的
        
                    end -- end if ~= nil 
        
                    rowIndex = rowIndex + 1
                end
        
            end
    
            
        end
    
end

--
--设置bonus scatter 层级
function CodeGameScreenBingoPriatesMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.SYMBOL_FIX_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif  symbolType == self.SYMBOL_LONG_WILD or symbolType == self.SYMBOL_ACT_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD  then
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


function CodeGameScreenBingoPriatesMachine:getBottomUINode( )
    return "CodeBingoPriatesSrc.BingoPriatesBottomUiView"
end


-- ----- ----- ---
-- ----- ---
-- ---
-- bingo炸弹收集
function CodeGameScreenBingoPriatesMachine:playBonusBingoCollectAni( actList , func  )
    

    self.m_BingoCollectBoomCallFunc = function(  )
        if func then
            func()
        end

    end
    self.m_BingoCollectPlayAnimIndex = 1
    self.m_BingoCollectBoomList = actList or {}

    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local markBingo = selfdata.markBingo or {}

    if #self.m_BingoCollectBoomList > 0 then
        -- gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_onFire.mp3")
    end
    

    local markBingoInfoList = {}
    for i=#self.m_BingoCollectBoomList, 1 , -1 do
        local info = self.m_BingoCollectBoomList[i]
        local reelPosition = info.reelPosition
        local cardPosition = info.cardPosition

        local fixPos = self:getRowAndColByPos(reelPosition)
        local beginNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if beginNode then
            -- beginNode:runAnim("idleframe2",true)
        end

        local isBingoWin = false
        for i=1,#markBingo do
            local markBingoPos = markBingo[i]
            if markBingoPos == cardPosition then
                isBingoWin = true
                break
            end
        end

        if isBingoWin then
            table.insert(markBingoInfoList,info)
            table.remove(self.m_BingoCollectBoomList,i)
        end
    end

    -- 这一步的操作是因为需要把 allWinBingo 的特殊位置最后播放
    for i=1,#markBingoInfoList do
        local info = markBingoInfoList[i]
        table.insert(self.m_BingoCollectBoomList,info)
    end
    

    performWithDelay(self,function(  )
        self:playBingoCollectBoomCollectAnim( )
    end,0.5)
    

end


function CodeGameScreenBingoPriatesMachine:playBingoCollectBoomCollectAnim()

   

    if self.m_BingoCollectPlayAnimIndex > #self.m_BingoCollectBoomList then
     
        
        if self.m_BingoCollectBoomCallFunc then
            self.m_BingoCollectBoomCallFunc()
        end
        
        return 
    end



    local info = self.m_BingoCollectBoomList[self.m_BingoCollectPlayAnimIndex]



    local function fishFlyEndJiesuan()

            -- 这里需要验一下
            local bingoData =  self.m_BingoNetData or {}
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local cardPosition = info.cardPosition

            -- 金币池
            local removeCoins = bingoData.removeCoins or {}
            local isRemoveCoins = false
            local coins = 0
            for k,v in pairs(removeCoins) do
                local bingoReelPos = tonumber(k) 
                if bingoReelPos == cardPosition then
                    isRemoveCoins = true
                    coins = v
                    break
                end
            end

            -- 初始化金色骷髅位置
            
            local goldenBoneHitNewRemove = bingoData.goldenBoneHitNewRemove or {}
            
            local isGoldBone  = false
            for i=1,#goldenBoneHitNewRemove do
                local bingoReelPos = goldenBoneHitNewRemove[i]
                if bingoReelPos == cardPosition then
                    isGoldBone = true
                    break
                end
            end

            
            local markBingo = selfdata.markBingo or {}
            local isBingoWin = false
            for i=1,#markBingo do
                local markBingoPos = markBingo[i]
                if markBingoPos == cardPosition then
                    isBingoWin = true
                    break
                end
            end
            
            if isGoldBone then -- 更新宝箱收集

                self:GoldBoneBingoCollectAction(cardPosition,function(  )
                    self.m_BingoCollectPlayAnimIndex = self.m_BingoCollectPlayAnimIndex + 1
                    self:playBingoCollectBoomCollectAnim() 
                end )
                
            elseif isRemoveCoins then -- 收集金币池的钱
                self:CoinsHeapBingoCollectAction(cardPosition,function(  )
                    self.m_BingoCollectPlayAnimIndex = self.m_BingoCollectPlayAnimIndex + 1
                    self:playBingoCollectBoomCollectAnim() 

                end,nil,coins)

            elseif isBingoWin then -- bingoWinAll位置
                self:AllWinBingoPosCollectAction(cardPosition,function(  )
                    self.m_BingoCollectPlayAnimIndex = self.m_BingoCollectPlayAnimIndex + 1
                    self:playBingoCollectBoomCollectAnim() 
                end )
            else
                -- 普通收集
                self.m_BingoCollectPlayAnimIndex = self.m_BingoCollectPlayAnimIndex + 1
                self:playBingoCollectBoomCollectAnim() 
            end

            
        
    end


    if info then
        local reelPosition = info.reelPosition
        local ballNum = info.ballNum
        local cardPosition = info.cardPosition
        if cardPosition then
            
            if cardPosition ~= -1 and reelPosition ~= -1 then
                local Score = ballNum
                local delayTime = 9/30
                local actMoveTime = 1 
                local bingoData = self.m_BingoNetData or {}
                local bingo = bingoData.bingo

                gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_BeginFly.mp3")
                
                

                local feature = self.m_runSpinResultData.p_features or {}
                local isBigWin = self:checkIsBigWin( ) -- 大赢要播放完
                if not isBigWin and not bingo and #feature < 2 and self.m_BingoCollectPlayAnimIndex == #self.m_BingoCollectBoomList then
                    
                    -- 这里需要验一下
                    -- 初始化金色骷髅位置
                    local bingoData =  self.m_BingoNetData or {}
                    
                    local cardPosition = info.cardPosition

                     -- 金币池
                    local removeCoins = bingoData.removeCoins or {}
                    local isRemoveCoins = false
                    local coins = 0
                    for k,v in pairs(removeCoins) do
                        local bingoReelPos = tonumber(k) 
                        if bingoReelPos == cardPosition then
                            isRemoveCoins = true
                            coins = v
                            break
                        end
                    end

                    local goldenBoneHitNewRemove = bingoData.goldenBoneHitNewRemove or {}
                    local isGoldBone  = false
                    for i=1,#goldenBoneHitNewRemove do
                        local bingoReelPos = goldenBoneHitNewRemove[i]
                        if bingoReelPos == cardPosition then
                            isGoldBone = true
                            break
                        end
                    end

                    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                    local markBingo = selfdata.markBingo or {}
                    local isBingoWin = false
                    for i=1,#markBingo do
                        local markBingoPos = markBingo[i]
                        if markBingoPos == cardPosition then
                            isBingoWin = true
                            break
                        end
                    end
                    

                    if isGoldBone or isBingoWin or isRemoveCoins  then -- 更新宝箱收集 -- bingoWinAll位置
                        self:BonusBingoCollectAction(reelPosition,cardPosition,Score,actMoveTime,delayTime,function(  )

                            self.m_BingoReel:collectOneBingoReel( cardPosition )
        
                            fishFlyEndJiesuan() 
        
                        end)   
                    else
                        self:BonusBingoCollectAction(reelPosition,cardPosition,Score,actMoveTime,delayTime,function(  )

                            self.m_BingoReel:collectOneBingoReel( cardPosition )
                        end) 
                        fishFlyEndJiesuan() 
                    end

                else
                    self:BonusBingoCollectAction(reelPosition,cardPosition,Score,actMoveTime,delayTime,function(  )

                        self.m_BingoReel:collectOneBingoReel( cardPosition )
    
                        fishFlyEndJiesuan() 
    
                    end)
                end
                

            end
        end

    end
        

end

function CodeGameScreenBingoPriatesMachine:AllWinBingoPosCollectAction( endIndex,func )
    
    local actNode = util_createAnimation("BingoPriates_bingoReel_OnePosWinAll.csb")
    self.m_BingoReel:findChild("OnePosWinAll"):addChild(actNode)
    self.m_BingoReel:findChild("OnePosWinAll"):setVisible(true)
    local beginNode = self.m_BingoReel:findChild("Node_" .. endIndex + 1)
    local startWorldPos = beginNode:getParent():convertToWorldSpace(cc.p(beginNode:getPosition())) 
    local startPos = self.m_BingoReel:findChild("OnePosWinAll"):convertToNodeSpace(cc.p(startWorldPos))
    actNode:setPosition(startPos)

    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_AllWinBingoAct.mp3")

    performWithDelay(self,function(  )
        local bingoFixPos =  self.m_BingoReel:getBingoReelRowAndColByPos(endIndex)
        local iCol = bingoFixPos.iY
        local iRow = bingoFixPos.iX
        self.m_BingoReel:changeColRowToPurpleBone( iCol,iRow )
    end,9/30)
    

    actNode:runCsbAction("actionframe",false,function(  )
        
        

        performWithDelay(self,function(  )
            self.m_BingoReel:findChild("OnePosWinAll"):setVisible(false)
            actNode:removeFromParent()
            if func then
                func()
            end
        end,0.5)
        

    end)

end

function CodeGameScreenBingoPriatesMachine:flyChestNode(beginNode , endNode,func )
    
    local actNode = util_createAnimation("BingoPriates_baoxiang.csb")
    self:addChild(actNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    actNode:setScale(0.26 * self.m_machineRootScale)
    local beginPos = cc.p(util_getConvertNodePos(beginNode,actNode))
    actNode:setPosition(beginPos)
    local endPos = cc.p(util_getConvertNodePos(endNode,actNode))
    local time = 28/30
    local Particle =  actNode:findChild("Particle_1")
    if Particle then
        Particle:setPositionType(0)
        Particle:setDuration(time)
    end
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        actNode:runCsbAction("shouji")
    end)
    actList[#actList + 1] = cc.DelayTime:create(27/30)
    actList[#actList + 1] = cc.MoveTo:create(time,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        actNode:setVisible(false)
        if func then
            func()
        end

    end)
    actList[#actList + 1] = cc.DelayTime:create(21/30)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        actNode:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    actNode:runAction(sq)

end



function CodeGameScreenBingoPriatesMachine:GoldBoneBingoCollectAction(endIndex,func,showIdle )
    
    local showIdleUi = showIdle

    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_ShipGame_getChest.mp3")

    local chestProcess =  self.m_ChestBar.ChestProcess + 1
    if chestProcess > self.m_ChestBar.ChestMaxNum then
        chestProcess = self.m_ChestBar.ChestMaxNum -- chestProcess - self.m_ChestBox.ChestMaxNum
    end
    local beginNode = self.m_BingoReel:findChild("Node_" .. endIndex + 1)
    local endNode = self.m_ChestBar["Chest_" .. chestProcess]

    if beginNode and endNode then

        self:flyChestNode(beginNode , endNode,function(  )
            -- 更新宝箱
            self.m_ChestBar:runOneProcessAct( chestProcess , function(  )
    
                    if func then
                        func()
                    end
                    
                end ,showIdleUi ) 
        end )
    
    end
 
end


function CodeGameScreenBingoPriatesMachine:CoinsHeapBingoCollectAction(endIndex,func,showIdle,coins )
    

    local CurrCoins = coins

    local showIdleUi = showIdle

    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_ShipGame_getChest.mp3")

    local beginNode = self.m_BingoReel:findChild("Node_" .. endIndex + 1)
    local endNode = self.m_bottomUI:findChild("win_guang_0")
    if beginNode and endNode then

        local time = 0.5
        local csbName = "BingoPriates_bingoReel_jinbi"
        self:runFlyCoinsPoolAct(beginNode,endNode,csbName,function(  )

            local isUpdate = true
            if self.m_serverWinCoins - coins > 0 then
                isUpdate = false
            end
            if isUpdate then
                -- 通知bonus 结束， 以及赢钱多少
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{coins, GameEffect.EFFECT_SELF_EFFECT})
            end
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isUpdate,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin 


            if func then
                func()
            end
        end,time,1,coins)

        
                    
    end
 
end

--------
-----
---
--- 船长玩法动画炸弹过场
function CodeGameScreenBingoPriatesMachine:CaptainGameActOneTimes( func )

    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Captain_openFire_One.mp3")

    local actNode = cc.Node:create()
    self:addChild(actNode)
    self.m_CaptainMan:setVisible(true)
    util_spinePlay( self.m_CaptainMan , "actionframe3")
    self.m_m_CaptainMan_bg:setVisible(true)
    self.m_m_CaptainMan_bg:runCsbAction("actionframe3",false,function(  )
        self.m_m_CaptainMan_bg:setVisible(false)
    end)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(17/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()
        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_captainMan_show.mp3")
    end)
    actionList[#actionList + 1] = cc.DelayTime:create((60 - 17) /30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()

        
        self.m_CaptainMan:setVisible(false)
        if func then
            func()
        end
        actNode:removeFromParent()
    end)

    local seq = cc.Sequence:create(actionList)
    actNode:runAction(seq)

    
end

--------
-----
---
--- 船长玩法动画炸弹过场
function CodeGameScreenBingoPriatesMachine:CaptainGameActTwoTimes( func )

    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Captain_openFire_Two.mp3")

    local actNode = cc.Node:create()
    self:addChild(actNode)
    self.m_CaptainMan:setVisible(true)
    util_spinePlay( self.m_CaptainMan , "actionframe")
    self.m_m_CaptainMan_bg:setVisible(true)
    self.m_m_CaptainMan_bg:runCsbAction("actionframe",false,function(  )
        self.m_m_CaptainMan_bg:setVisible(false)
    end)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(17/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()
        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_captainMan_show.mp3")
    end)
    actionList[#actionList + 1] = cc.DelayTime:create((60 - 17) /30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()

        
        self.m_CaptainMan:setVisible(false)
        if func then
            func()
        end
        actNode:removeFromParent()
    end)

    local seq = cc.Sequence:create(actionList)
    actNode:runAction(seq)

    
end

-- 只在随机添加wild时使用
function CodeGameScreenBingoPriatesMachine:CaptainGameActThreeTimes( func )

    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Captain_openFire_Three.mp3")

    local actNode = cc.Node:create()
    self:addChild(actNode)
    self.m_CaptainMan:setVisible(true)
    util_spinePlay( self.m_CaptainMan , "actionframe2")

    self.m_m_CaptainMan_bg:setVisible(true)
    self.m_m_CaptainMan_bg:runCsbAction("actionframe3_start",false,function(  )
        -- self.m_m_CaptainMan_bg:setVisible(false)
    end)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(17/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()
        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_captainMan_show.mp3")
    end)
    actionList[#actionList + 1] = cc.DelayTime:create((72 - 17) /30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()
        self.m_CaptainMan:setVisible(false)
        
        
        if func then
            func()
        end

        actNode:removeFromParent()
    end)

    local seq = cc.Sequence:create(actionList)
    actNode:runAction(seq)

    
end


--------------
----------
-----
-- 根据Bonus Game 每关做的处理
--

-- 收集小游戏 断线处理
function CodeGameScreenBingoPriatesMachine:initFeatureInfo(spinData,featureData)
    if featureData.p_status and featureData.p_status ~= "CLOSED"  then

        self.isInBonus = true

        local bonusdata = featureData.p_bonus or {}
        performWithDelay(self,function(  )
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end,0)
       

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusType = selfdata.bonusType
    
        if bonusType then
            if bonusType == self.m_goldenBoneBonusType then
    
                self:createShipGameView( function(  )
                    performWithDelay(self,function(  )
                        self:checkLocalGameNetDataFeatures() -- 添加feature
                        self:playGameEffect() -- 播放下一轮 
                    end,0.5)
                    
                end,bonusdata)
    
            else
    
                self:createChestGameView( function(  )
                    performWithDelay(self,function(  )
                        self:checkLocalGameNetDataFeatures() -- 添加feature
                        self:playGameEffect() -- 播放下一轮
                    end,0.5)
                    
                end,bonusdata)
    
            end
            
        end

    end
    
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenBingoPriatesMachine:showEffect_Bonus(effectData)

    self.isInBonus = true

    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    local waitTime = 0
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if #winLines > 0 then
        waitTime = self.m_changeLineFrameTime
    end

    scheduler.performWithDelayGlobal(function (  )

        if self.m_winSoundsId ~= nil then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
    
        -- 这里只删除freespin的线 ，因为bonus没有线，这里删除是为了处理bonusfreespin同时触发的问题
        local lineLen = #self.m_reelResultLines
        local bonusLineValue = nil
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                -- bonusLineValue = lineValue
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
        
    end,waitTime,self:getModuleName())
   

    return true
end


function CodeGameScreenBingoPriatesMachine:showBonusGameView(effectData)


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusType = selfdata.bonusType

    if bonusType then
        if bonusType == self.m_goldenBoneBonusType then

            self:createShipGameView( function(  )
                performWithDelay(self,function(  )
                    self:checkLocalGameNetDataFeatures() -- 添加feature
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 播放下一轮
                end,0.5)
                
            end)

        else

            self:createChestGameView( function(  )
                performWithDelay(self,function(  )
                    self:checkLocalGameNetDataFeatures() -- 添加feature
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 播放下一轮
                end,0.5)
                
            end)

        end
        
    end
   


end

-- Ship玩法
function CodeGameScreenBingoPriatesMachine:createShipGameView( func,bonusData)

    local data = {}
    data.machine = self

    if bonusData == nil then
        bonusData = {}
    end

    data.bonusExtr = bonusData.extra or {}
    data.choose = bonusData.choose or {}

    local ShipGameMain = util_createView("CodeBingoPriatesSrc.ShipGame.BingoPriatesShipGameMainView",data)
    self:addChild(ShipGameMain,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_ShipGameMain = ShipGameMain
    ShipGameMain:setPosition(display.width/2 ,display.height/ 2)
    ShipGameMain:setEndCall( function(  )

        self:showGuoChang( function(  )

            util_playFadeOutAction(ShipGameMain,0.3,function(  )
                if ShipGameMain then
                    ShipGameMain:removeFromParent()
                    ShipGameMain = nil
                    self.m_ShipGameMain = nil
                end
            end)

            self:restGoldBoneProgress( )

            self.m_bottomUI:setVisible(true)
            self:findChild("root"):setVisible(true)

            if func then
                func()
            end
            self:resetMusicBg()
        end,nil,true)
            
        
    end)

    ShipGameMain:setScale(self.m_machineRootScale)

    ShipGameMain:setVisible(false)
    util_playFadeOutAction(ShipGameMain, 0.1)

    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_Trigger_Ship.mp3")

    self.m_GoldBoneBar:runCsbAction("win",false,function(  )
        self.m_GoldBoneBar:runCsbAction("win",false,function(  )

            performWithDelay(self,function(  )
                self:showGuoChang( function(  )
                    self.m_bottomUI:setVisible(false)
                    ShipGameMain:setVisible(true)
                    util_playFadeInAction(ShipGameMain, 0.5,function(  )
                        
                        self:findChild("root"):setVisible(false)
                    end)
            
                end,function(  )
    
                    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Ship_Enter.mp3")
    
                    self:resetMusicBg(nil,"BingoPriatesSounds/BingoPriatesSounds_ShipgameBG.mp3")
    
                    ShipGameMain:runCsbAction("open",false,function(  )
    
                        scheduler.performWithDelayGlobal(function (  )   
                            ShipGameMain.m_shipTipView:runCsbAction("over")
                        end,5,self:getModuleName())
                        
                        
                        ShipGameMain:initShipStates( )
                        ShipGameMain:startGameCallFunc()
                    end)
    
                    scheduler.performWithDelayGlobal(function (  )   
                        ShipGameMain.m_shipTipView:runCsbAction("show")
                    end,1,self:getModuleName())
                end)
            end,0.5)
            
        end)
    end)
    

    


end

-- Chest玩法
function CodeGameScreenBingoPriatesMachine:createChestGameView( func,bonusData)

    local data = {}
    data.machine = self

    if bonusData == nil then
        bonusData = {}
    end

    data.choose = bonusData.choose or {}
    data.content = bonusData.content or {}

    local ChestGameMain = util_createView("CodeBingoPriatesSrc.ChestGame.BingoPriatesChestGameMainView",data)
    self:addChild(ChestGameMain,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_ChestGameMain = ChestGameMain
    ChestGameMain:setPosition(display.width/2 ,display.height/ 2)
    ChestGameMain:setEndCall( function(  )
        
        self:showGuoChang( function(  )

            util_playFadeOutAction(ChestGameMain,0.3,function(  )
                if ChestGameMain then
                    ChestGameMain:removeFromParent()
                    ChestGameMain = nil
                    self.m_ChestGameMain = nil
                end
            end)

            self:restGoldBoneProgress( )
            self:restChestBarProgress( )
        
            -- 重置bingo轮盘
            self:winBingoRestBingoUI( )

            self:findChild("root"):setVisible(true)
            self.m_bottomUI:setVisible(true)

            if func then
                func()
            end
            self:resetMusicBg()
        end,nil,true)

    end)
    ChestGameMain:setVisible(false)
    ChestGameMain:setScale(self.m_machineRootScale)


    util_playFadeOutAction(ChestGameMain, 0.1)

    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_Trigger_Chest.mp3")
    
    for i=1,self.m_ChestBar.ChestMaxNum do
        local bar = self.m_ChestBar["Chest_" .. i]
        if bar then
            bar:runCsbAction("win")
        end
    end
    
    performWithDelay(self,function(  )
        self:showGuoChang( function(  )
            self.m_bottomUI:setVisible(false)
            ChestGameMain:setVisible(true)
            util_playFadeInAction(ChestGameMain, 0.5,function(  )
                
                self:findChild("root"):setVisible(false)
            end)
    
        end,function(  )

            gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Chest_Sound_1.mp3")

            self:resetMusicBg(nil,"BingoPriatesSounds/BingoPriatesSounds_ChestgameBG.mp3")

            ChestGameMain:startGameCallFunc()
    
        end)
    end,2.5)

    
    
end

function CodeGameScreenBingoPriatesMachine:showGuoChang( func,funcEnd ,isBonusOver)

    if isBonusOver then
        gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_GuoChang_2.mp3")
    else
        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_GuoChang.mp3")
    end
    

    local actNode = cc.Node:create()
    self:addChild(actNode)
    self.m_GuoChang:setVisible(true)
    util_spinePlay( self.m_GuoChang , "actionframe")

    self.m_GuoChang_bg:setVisible(true)
    self.m_GuoChang_bg:runCsbAction("actionframe3",false,function(  )
        self.m_GuoChang_bg:setVisible(false)
    end)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(90/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()

        if func then
            func()
        end


    end)
    actionList[#actionList + 1] = cc.DelayTime:create(42/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()
        self.m_GuoChang:setVisible(false)
        if funcEnd then
            funcEnd()
        end

        actNode:removeFromParent()
    end)

    local seq = cc.Sequence:create(actionList)
    actNode:runAction(seq)
end

-- 更新控制类数据
function CodeGameScreenBingoPriatesMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end


function CodeGameScreenBingoPriatesMachine:showJackpotWinView(index,coins,func)
    
    
    local jackPotWinView = util_createView("CodeBingoPriatesSrc.BingoPriatesJackPotWinView")
    
    gLobalViewManager:showUI(jackPotWinView)

    local curCallFunc = function(  )

        if func then
            func()
        end
    end

    jackPotWinView:initViewData(index,coins,curCallFunc)


end

function CodeGameScreenBingoPriatesMachine:showBonusOverView( coins, func )
    
    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_BingoOverView.mp3")

    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)

    local view = self:showDialog("BonusOver",ownerlist,function(  )
        if func then
            func()
        end
    end)
    view.m_btnTouchSound = "BingoPriatesSounds/BingoPriates_Click.mp3"
    
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx= 1 ,sy = 1},674)
end

function CodeGameScreenBingoPriatesMachine:showChestBonusOverView( coins, jpIndex , jpCoins ,func  )
    
    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_ChestBonusBingoOverView.mp3")
    
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)

    local view = self:showDialog("JackpotOver",ownerlist,function(  )
        if func then
            func()
        end
    end)
    view.m_btnTouchSound = "BingoPriatesSounds/BingoPriates_Click.mp3"

    local imgName = {"tb_grand","tb_major","tb_mini"}
    for k,v in pairs(imgName) do
        local img =  view:findChild(v)
        if img then
            if k == jpIndex then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},685)
end

function CodeGameScreenBingoPriatesMachine:restChestBarProgress( )

    local selfdate = self.m_runSpinResultData.p_selfMakeData or {}
    local bingoData = selfdate.bingoData or {}
     -- 初始化宝箱进度
    self.m_ChestBar:updateBingoChestBoxProcess( 0 )

end

function CodeGameScreenBingoPriatesMachine:restGoldBoneProgress( )
    local selfdate = self.m_runSpinResultData.p_selfMakeData or {}
    local bingoData = selfdate.bingoData or {}
     -- 初始化金骷髅进度
    self.m_GoldBoneBar:updateBingoGoldenBoneProcess( 0 )
     
end



function CodeGameScreenBingoPriatesMachine:fly_One_Boom_OneTimesAct(endNode,func ,isBig,waitTime)
    

  

    local actNode = cc.Node:create()
    self.m_BonusBingoCollectNdoe:addChild(actNode)

    actNode:setScale(self.m_machineRootScale)

    local node = util_createAnimation("Socre_BingoPriates_Linghting.csb")
    node:findChild("m_lb_score"):setString("")
    actNode:addChild(node)

    local BoomAct = util_createAnimation("Socre_BingoPriates_Boom.csb")
    actNode:addChild(BoomAct)
    BoomAct:setVisible(false)

    local bigAct = isBig


    local time = 1
    local endPos = cc.p(util_getConvertNodePos(endNode,actNode))
    local beginPos =  cc.p(endPos.x,endPos.y + 1000)
    actNode:setPosition(beginPos)
    
    local actionList={}
    if waitTime then
        actionList[#actionList+1] = cc.DelayTime:create(waitTime)  
    end
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
        -- gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Captain_Boom_Zha.mp3")
        if bigAct then
            node:runCsbAction("big")
        else   
            node:runCsbAction("small")
        end
        
    end)
    actionList[#actionList+1]=cc.MoveTo:create(time,endPos);
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_EndFly.mp3")

        BoomAct:setVisible(true) 
        node:setVisible(false)
        local BoomAct_1 = BoomAct
        if bigAct then
            BoomAct:runCsbAction("actionframe2",false,function(  )
                BoomAct_1:setVisible(false)
            end)
        else   
            BoomAct:runCsbAction("actionframe",false,function(  )
                BoomAct_1:setVisible(false)
            end)
        end

        
        
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(9/30) -- BoomAct 炸到最大时
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        if func then
            func()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(1)
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        actNode:removeFromParent()
    end)
    local seq=cc.Sequence:create(actionList)
    actNode:runAction(seq)

end

function CodeGameScreenBingoPriatesMachine:fly_Two_Boom_OneTimesAct(endNode, func,isBig )
    
    local callfunc = func
    local endNode_1 = endNode
    local dealyTimes = 0.3

    self:fly_One_Boom_OneTimesAct(endNode )
    
    scheduler.performWithDelayGlobal(function (  )
        local callfunc_1 = callfunc
        self:fly_One_Boom_OneTimesAct(endNode_1,function(  )
            if callfunc_1 then
                callfunc_1()
            end
        end)
    end,dealyTimes,self:getModuleName())


end

function CodeGameScreenBingoPriatesMachine:fly_Three_Boom_OneTimesAct(endNode,func ,isBig)

    local dealyTimes = 0.3
    local callfunc = func
    local endNode_1 = endNode

    self:fly_One_Boom_OneTimesAct(endNode_1 )

    scheduler.performWithDelayGlobal(function (  )
        local callfunc_1 = callfunc
        local endNode_2 = endNode_1

        self:fly_One_Boom_OneTimesAct(endNode_2 )

        scheduler.performWithDelayGlobal(function (  )


            local callfunc_2 = callfunc_1
            local endNode_3 = endNode_2
            self:fly_One_Boom_OneTimesAct(endNode_3,function(  )
                if callfunc_2 then
                    callfunc_2()
                end
            end)
        end,dealyTimes,self:getModuleName())

    end,dealyTimes,self:getModuleName())
    
    
end

function CodeGameScreenBingoPriatesMachine:setBingoUiDark( istrue )
    
    if istrue then 
        self:runCsbAction("idle2")
        self.m_BingoReel:runCsbAction("idle2")
        self.m_JackPotBar:runCsbAction("idle2")
        self.m_ChestBar:runCsbAction("idle2")
    else
        self:runCsbAction("idle1")
        self.m_ChestBar:runCsbAction("idle1")
        self.m_BingoReel:runCsbAction("idle1")
        self.m_JackPotBar:runCsbAction("idle1")
        self.m_ChestBar:runCsbAction("idle1")
    end

    
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenBingoPriatesMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
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

---
-- 自己添加freespin 或 respin 或 bonus事件
--
function CodeGameScreenBingoPriatesMachine:checkLocalGameNetDataFeatures()

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
           
            if self.m_runSpinResultData.p_winLines then
                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                    if checkEnd == true then
                        break
                    end
    
                end
            end
            

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

function CodeGameScreenBingoPriatesMachine:checkShowTipView( )
    
    if self.m_bProduceSlots_InFreeSpin == true or 
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and 
    self:getGameSpinStage() ~= IDLE ) or 
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or 
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        self.m_TipView:setVisible(false)

        return
    end


    if self.m_TipView:isVisible() then
        gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_Click.mp3")
        self.m_TipView:setVisible(false)
    else
        gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_Click.mp3")
        self.m_TipView:setVisible(true)
    end

    self:ShowTipChangeReelNodeVisible( )

end

function CodeGameScreenBingoPriatesMachine:ShowTipChangeReelNodeVisible( )

    
    if self.m_TipView:isVisible() then
        if self.m_lineSlotNodes then
            for i=1,#self.m_lineSlotNodes do
                local node = self.m_lineSlotNodes[i]
                node:setVisible(false)
            end
        end
        self.m_slotEffectLayer:setVisible(false)
        self.m_slotFrameLayer:setVisible(false)
    else
        if self.m_lineSlotNodes then
            for i=1,#self.m_lineSlotNodes do
                local node = self.m_lineSlotNodes[i]
                node:setVisible(true)
            end
        end
        self.m_slotEffectLayer:setVisible(true)
        self.m_slotFrameLayer:setVisible(true)
    end
     -- 隐藏scatter信号以防穿帮
     local scatterList
     for iCol = 1, self.m_iReelColumnNum do
 
         for iRow = 1, self.m_iReelRowNum do
             
             local tarSp = self:getFixSymbol(iCol , iRow, SYMBOL_NODE_TAG)
             if tarSp and tarSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                 if self.m_TipView:isVisible() then
                     tarSp:setVisible(false)
                 else
                     tarSp:setVisible(true)
                 end
                 
             end
 
         end
     end
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenBingoPriatesMachine:changeToMaskLayerSlotNode(slotNode)

    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3 - slotNode.p_rowIndex
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

   -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)

    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then

        printInfo("xcyy : %s","slotNode p_rowIndex  p_cloumnIndex isnil")

    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end


--    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenBingoPriatesMachine:initJackpotUIInfo( )

    local setInitJpLabData = function(  )
        if self.m_jackpotMultiply  then
        
            local totalBet =  globalData.slotRunData:getCurTotalBet()
            local jackpotData = {}
            jackpotData.Grand = totalBet * self.m_jackpotMultiply[3]
            jackpotData.Major = totalBet * self.m_jackpotMultiply[2]
            jackpotData.Minor = totalBet * self.m_jackpotMultiply[1]
            self.m_JackPotBar:updateJackpotInfo(jackpotData)
        end
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotData = selfdata.jackpotData 
    if jackpotData == nil then
        setInitJpLabData()
    else
        if not self:checkUpdateJackpotInfo(jackpotData) then
            setInitJpLabData()
        end
        
    end

    
end

function CodeGameScreenBingoPriatesMachine:checkIsBigWin( )
    local coins = self.m_serverWinCoins or 0
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = coins / totalBet

    if winRate >= self.m_HugeWinLimitRate then
        return true
    elseif winRate >= self.m_MegaWinLimitRate then
        return true
    elseif winRate >= self.m_BigWinLimitRate then
        return true
    end

    return false
end



-- ----- ----- ---
-- ----- ---
-- ---
-- 船长 bingoReel 炸弹收集
function CodeGameScreenBingoPriatesMachine:Captain_playBonusBingoCollectAni( actList , func  )
    

    self.m_Captain_BingoCollectBoomCallFunc = function(  )
        if func then
            func()
        end

    end
    self.m_Captain_BingoCollectPlayAnimIndex = 1
    self.m_Captain_BingoCollectBoomList = actList or {}

    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local markBingo = selfdata.markBingo or {}


    local markBingoInfoList = {}
    for i=#self.m_Captain_BingoCollectBoomList, 1 , -1 do
        local info = self.m_Captain_BingoCollectBoomList[i]
        local reelPosition = info.reelPosition
        local cardPosition = info.cardPosition

        local isBingoWin = false
        for i=1,#markBingo do
            local markBingoPos = markBingo[i]
            if markBingoPos == cardPosition then
                isBingoWin = true
                break
            end
        end

        if isBingoWin then
            table.insert(markBingoInfoList,info)
            table.remove(self.m_Captain_BingoCollectBoomList,i)
        end
    end

    -- 这一步的操作是因为需要把 allWinBingo 的特殊位置最后播放
    for i=1,#markBingoInfoList do
        local info = markBingoInfoList[i]
        table.insert(self.m_Captain_BingoCollectBoomList,info)
    end
    

    performWithDelay(self,function(  )
        self:Captain_playBingoCollectBoomCollectAnim( )
    end,0.5)
    

end


function CodeGameScreenBingoPriatesMachine:Captain_playBingoCollectBoomCollectAnim()

   

    if self.m_Captain_BingoCollectPlayAnimIndex > #self.m_Captain_BingoCollectBoomList then
     
        
        if self.m_Captain_BingoCollectBoomCallFunc then
            self.m_Captain_BingoCollectBoomCallFunc()
        end
        
        return 
    end



    local info = self.m_Captain_BingoCollectBoomList[self.m_Captain_BingoCollectPlayAnimIndex]



    local function fishFlyEndJiesuan()

            local bingoData =  self.m_BingoNetData or {}
            local cardPosition = info.cardPosition
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            -- 这里需要验一下
            -- 金币池
            local removeCoins = bingoData.removeCoins or {}
            local isRemoveCoins = false
            local coins = 0
            for k,v in pairs(removeCoins) do
                local bingoReelPos = tonumber(k) 
                if bingoReelPos == cardPosition then
                    isRemoveCoins = true
                    coins = v
                    break
                end
            end


            -- 初始化金色骷髅位置
            
            local goldenBoneHitNewRemove = bingoData.goldenBoneHitNewRemove or {}
            local isGoldBone  = false
            for i=1,#goldenBoneHitNewRemove do
                local bingoReelPos = goldenBoneHitNewRemove[i]
                if bingoReelPos == cardPosition then
                    isGoldBone = true
                    break
                end
            end

            
            local markBingo = selfdata.markBingo or {}
            local isBingoWin = false
            for i=1,#markBingo do
                local markBingoPos = markBingo[i]
                if markBingoPos == cardPosition then
                    isBingoWin = true
                    break
                end
            end
            
            if isGoldBone then -- 更新宝箱收集

                self:GoldBoneBingoCollectAction(cardPosition,function(  )
                    self.m_Captain_BingoCollectPlayAnimIndex = self.m_Captain_BingoCollectPlayAnimIndex + 1
                    self:Captain_playBingoCollectBoomCollectAnim() 
                end )

            elseif isRemoveCoins then -- 收集金币池的钱
                self:CoinsHeapBingoCollectAction(cardPosition,function(  )

                    self.m_Captain_BingoCollectPlayAnimIndex = self.m_Captain_BingoCollectPlayAnimIndex + 1
                    self:Captain_playBingoCollectBoomCollectAnim() 

                end,nil,coins)
            elseif isBingoWin then -- bingoWinAll位置
                self:AllWinBingoPosCollectAction(cardPosition,function(  )
                    self.m_Captain_BingoCollectPlayAnimIndex = self.m_Captain_BingoCollectPlayAnimIndex + 1
                    self:Captain_playBingoCollectBoomCollectAnim() 
                end )
            else
                -- 普通收集
                self.m_Captain_BingoCollectPlayAnimIndex = self.m_Captain_BingoCollectPlayAnimIndex + 1
                self:Captain_playBingoCollectBoomCollectAnim() 
            end

 
        
    end


    if info then
        local reelPosition = info.reelPosition
        local ballNum = info.ballNum
        local cardPosition = info.cardPosition
        if cardPosition then
            
            if cardPosition ~= -1 and reelPosition == -1 then
                local Score = ballNum
                local actMoveTime = 0.5
                local bingoData = self.m_BingoNetData or {}
                local bingo = bingoData.bingo

                gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_BeginFly.mp3")
                
                 -- 这里需要验一下
                 local bingoData =  self.m_BingoNetData or {}
                 local cardPosition = info.cardPosition

                 -- 金币池
                 local removeCoins = bingoData.removeCoins or {}
                 local isRemoveCoins = false
                 local coins = 0
                 for k,v in pairs(removeCoins) do
                     local bingoReelPos = tonumber(k) 
                     if bingoReelPos == cardPosition then
                         isRemoveCoins = true
                         coins = v
                         break
                     end
                 end

                 -- 初始化金色骷髅位置
                
                 local goldenBoneHitNewRemove = bingoData.goldenBoneHitNewRemove or {}
                 
                 local isGoldBone  = false 
                 for i=1,#goldenBoneHitNewRemove do
                     local bingoReelPos = goldenBoneHitNewRemove[i]
                     if bingoReelPos == cardPosition then
                         isGoldBone = true
                         break
                     end
                 end

                 local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                 local markBingo = selfdata.markBingo or {}
                 local isBingoWin = false
                 for i=1,#markBingo do
                     local markBingoPos = markBingo[i]
                     if markBingoPos == cardPosition then
                         isBingoWin = true
                         break
                     end
                 end
                 
                 if isGoldBone or isBingoWin or isRemoveCoins then -- 更新宝箱收集 -- bingoWinAll位置
                     self:Captain_BonusBingoCollectAction(cardPosition,Score,actMoveTime,function(  )

                         self.m_BingoReel:collectOneBingoReel( cardPosition )
     
                         fishFlyEndJiesuan() 
     
                     end)   
                 else
                     
                    local feature = self.m_runSpinResultData.p_features or {}
                    local isBigWin = self:checkIsBigWin( ) -- 大赢要播放完
                    if self.m_Captain_BingoCollectPlayAnimIndex == #self.m_Captain_BingoCollectBoomList then

                        self:Captain_BonusBingoCollectAction(cardPosition,Score,actMoveTime,function(  )

                            self.m_BingoReel:collectOneBingoReel( cardPosition )
                            fishFlyEndJiesuan() 
                        end)

                    else
    
                        self:Captain_BonusBingoCollectAction(cardPosition,Score,actMoveTime,function(  )

                            self.m_BingoReel:collectOneBingoReel( cardPosition )
                        end) 
                        performWithDelay(self,function(  )
                            fishFlyEndJiesuan() 
                        end,0.2)
                        
                    end

                    
                 end
                 
                
                

            end
        end

    end
        

end

function CodeGameScreenBingoPriatesMachine:Captain_BonusBingoCollectAction(endIndex,Score,moveTime,func )
    
    

    local beginNode = self.m_BingoReel:findChild("Node_" .. endIndex + 1)
    local bingoReelNode = self.m_BingoReel:findChild("Node_" .. endIndex + 1)


    if beginNode and bingoReelNode then
        local actNode = cc.Node:create()
        self.m_BonusBingoCollectNdoe:addChild(actNode)

        actNode:setScale(self.m_machineRootScale)

        local node = util_createAnimation("Socre_BingoPriates_Linghting.csb")
        actNode:addChild(node)

        local BoomAct = util_createAnimation("Socre_BingoPriates_Boom.csb")
        actNode:addChild(BoomAct)
        BoomAct:setVisible(false)
    

        local startWorldPos = beginNode:convertToWorldSpace(cc.p(beginNode:getPosition())) 
        local startPos = self:convertToNodeSpace(cc.p(startWorldPos))
        actNode:setPosition(cc.p(startPos.x,startPos.y + 1000))

        local lab = node:findChild("m_lb_score")
        if lab then
            lab:setString(Score)
        end

        local endWorldPos =  self.m_BingoReel:convertToWorldSpace(cc.p( bingoReelNode:getPosition())) 
        local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
        local actionList = {}
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            node:runCsbAction("small",true)
        end)
        actionList[#actionList + 1] = cc.MoveTo:create(moveTime, cc.p(endPos)) 
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_Bonus_EndFly.mp3")
            BoomAct:setVisible(true) 
            node:setVisible(false)
            local BoomAct_1 = BoomAct
            BoomAct:runCsbAction("actionframe",false,function(  )
                BoomAct_1:setVisible(false)
            end)
            
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(9/30) -- BoomAct 炸到最大时
        actionList[#actionList + 1] = cc.CallFunc:create(function()
  
            if func then
                func()
            end
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(1)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
  
            actNode:removeFromParent()
        end)



        actNode:runAction(cc.Sequence:create(actionList))
    end

    

    

end


function CodeGameScreenBingoPriatesMachine:runFlyCoinsPoolAct(startNode,endNode,csbName,func,times,scale,coins)


    

    local flytime = times or 0.5
    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    flyNode:findChild("Particle_3"):setPositionType(0)
    flyNode:findChild("Particle_3"):setDuration(flytime + 1)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = util_getConvertNodePos(endNode,flyNode)
    endPos = cc.p(endPos.x,endPos.y + 30)
    local flyNodeFk =  util_createAnimation( "BingoPriates_TotalWin.csb")
    self:addChild(flyNodeFk,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    flyNodeFk:setPosition(endPos)
    flyNodeFk:setVisible(false)
    
    
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:findChild("BitmapFontLabel_1"):setString(util_formatCoins(coins, 3))
        flyNode:runCsbAction("actionframe")
    end)
    actList[#actList + 1] = cc.DelayTime:create(1)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        
        flyNode:runCsbAction("shouji")
        local actList_1 = {}
        actList_1[#actList_1 + 1] = cc.ScaleTo:create(flytime,scale or 1)
        local sq_1 = cc.Sequence:create(actList_1)
        flyNode:runAction(sq_1)
    end)
    actList[#actList + 1] = cc.MoveTo:create(flytime,cc.p(endPos.x,endPos.y + 30))
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:setVisible(false)
        flyNodeFk:runCsbAction("actionframe")
        
        self:playCoinWinEffectUI()

        if func then
            func()
        end
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(flytime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
        flyNodeFk:stopAllActions()
        flyNodeFk:removeFromParent()
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)


end

function CodeGameScreenBingoPriatesMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)

    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for i=1,#newChilds do
            childs[#childs+1]=newChilds[i]
        end
    end

    for childIndex = 1, #childs do

        local child = childs[childIndex]
        self:moveDownCallFun(child, parentData.cloumnIndex)
    end

    local index = 1

    while index <= columnData.p_showGridCount do -- 只改了这 为了适应freespin
        self:createSlotNextNode(parentData)
        local symbolType = parentData.symbolType
        local node = self:getCacheNode(parentData.cloumnIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
            local slotParentBig = parentData.slotParentBig
            -- 添加到显示列表
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, parentData.order, parentData.tag)
            else
                slotParent:addChild(node, parentData.order, parentData.tag)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(parentData.order)
            node:setTag(parentData.tag)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
        end
        
        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

        node.p_cloumnIndex = parentData.cloumnIndex
        node.p_rowIndex = parentData.rowIndex
        node.m_isLastSymbol = parentData.m_isLastSymbol

        node.p_slotNodeH = columnData.p_showGridH
        node.p_symbolType = parentData.symbolType
        node.p_preSymbolType = parentData.preSymbolType
        node.p_showOrder = parentData.order

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
        node.p_layerTag = parentData.layerTag
        node:setTag(parentData.tag)
        node:setLocalZOrder(parentData.order)

        node:runIdleAnim()
        -- node:setVisible(false)
        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            -- 执行回弹, 如果不执行回弹判断是否执行
            parentData.isReeling = false
            -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
            -- 创建一个假的小块 在回滚停止后移除

            self:createResNode(parentData, node)
        end

        if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[parentData.symbolType]
            index = addCount + node.p_rowIndex
        else
            index = index + 1
        end
    end


end



----------------------------------------------对比数据相关
--数据化bingo盘面
function CodeGameScreenBingoPriatesMachine:getDataForUi()
    local tempList = {}
    --bingo轮盘（list）
    local bingoCards = self.m_BingoReel:getTextNumForContrast()
    tempList.bingoCards = bingoCards
    --平均betUI（number）
    local avgBet = self.m_ChestBar:getAvgBetNumForContrast()
    tempList.avgBet = avgBet
    --倍数
    local bingoMul = self.m_BingoReel:getBingoMulForContrast()
    tempList.bingoMul = bingoMul
    --下方收集
    local goldenBoneProcess = self.m_GoldBoneBar:getGoldenBoneProcessForContrast()
    tempList.goldenBoneProcess = goldenBoneProcess
    --宝箱收集
    local boxProcess = self.m_ChestBar:getChestBoxProcessForContrast()
    tempList.boxProcess = boxProcess
    -- 初始化金色骷髅位置(宝箱list)
    local goldenBoneHit = self.m_BingoReel:getPosForContrast(1)
    tempList.goldenBoneHit = goldenBoneHit
    --金币池位置
    local coinsHeap = self.m_BingoReel:getPosForContrast(2)
    tempList.coinsHeap = coinsHeap
    --五角星位置
    local bingoHit = self.m_BingoReel:getPosForContrast(3)
    tempList.bingoHit = bingoHit
    -- 初始化 标记一个数字，若这个数字被bonus覆盖后会马上赢得bingo奖励(list)
    local markSignal = self.m_BingoReel:getBingoWinAllLabForContrast()
    tempList.markSignal = markSignal
    return tempList
end

--对比bingo表，若不同  赋值、打印
function CodeGameScreenBingoPriatesMachine:contrastBingoNetData()
    local differentList = {}
    local selfdate = self.m_runSpinResultData.p_selfMakeData or {}
    local bingoData = selfdate.bingoData or {}
    local curBingoData = self:getDataForUi()
    local bingoData = clone(selfdate.newBingoData or {})
    -- if selfdate.newBingoData then
    --     print("111111")
    -- else
    --     print("111111")
    -- end
    if table_length(bingoData) ~= 0 and table_length(curBingoData) ~= 0 then
        -- 初始化bingo轮盘（list）
        local bingoCards = bingoData.bingoCards
        local contrastBingoCards = self:contrastTwoArrayList(bingoCards,curBingoData.bingoCards)
        if not contrastBingoCards then
            differentList.bingoCards = bingoCards
        end

        -- 初始化平均betUI（number）
        local avgBet = bingoData.avgBet 
        local contrastavgBet = self:contrastTwoNum(avgBet,curBingoData.avgBet)
        if not contrastavgBet then
            differentList.avgBet = avgBet
        end

        -- 初始化倍数(number)
        local bingoMul = bingoData.bingoMul
        local contrastBingoMul = self:contrastTwoNum(bingoMul,curBingoData.bingoMul)
        if not contrastBingoMul then
            differentList.bingoMul = bingoMul
        end

        -- 初始化金骷髅进度(下方收集 number)
        local goldenBoneProcess = bingoData.goldenBoneProcess
        local contrastGoldenBoneProcess = self:contrastTwoNum(goldenBoneProcess,curBingoData.goldenBoneProcess)
        if not contrastGoldenBoneProcess then
            differentList.goldenBoneProcess = goldenBoneProcess
        end

        -- 初始化宝箱进度(number)
        local boxProcess = bingoData.boxProcess
        local contrastBoxProcess = self:contrastTwoNum(boxProcess,curBingoData.boxProcess)
        if not contrastBoxProcess then
            differentList.boxProcess = boxProcess
        end

        -- 初始化金币池位置(list)
        local coinsHeap = bingoData.coinsHeap
        local contrastCoinsHeap = self:contrastTwoList(coinsHeap,curBingoData.coinsHeap)
        if table_length(coinsHeap) == 0 and table_length(curBingoData.coinsHeap) == 0 then
            contrastCoinsHeap = true
        end
        if not contrastCoinsHeap then
            differentList.coinsHeap = coinsHeap
        end

        -- 初始化紫色骷髅位置(list,五角星位置)
        local bingoHit = bingoData.bingoHit
        local contrastBingoHit = self:contrastTwoList(bingoHit,curBingoData.bingoHit)
        if table_length(bingoHit) == 0 and table_length(curBingoData.bingoHit) == 0 then
            contrastBingoHit = true
        end
        if not contrastBingoHit then
            differentList.bingoHit = bingoHit
        end

        -- 初始化 标记一个数字，若这个数字被bonus覆盖后会马上赢得bingo奖励(list)
        local markSignal = bingoData.markSignal
        local contrastMarkSignal = self:contrastTwoList(markSignal,curBingoData.markSignal)
        if table_length(markSignal) == 0 and table_length(curBingoData.markSignal) == 0 then
            contrastMarkSignal = true
        end
        if not contrastMarkSignal then
            differentList.markSignal = markSignal
        end

        -- 初始化金色骷髅位置(宝箱list)
        local goldenBoneHit = bingoData.goldenBoneHit
        local contrastGoldenBoneHit = self:contrastTwoList(goldenBoneHit,curBingoData.goldenBoneHit)
        if table_length(goldenBoneHit) == 0 and table_length(curBingoData.goldenBoneHit) == 0 then
            contrastGoldenBoneHit = true
        end
        if not contrastGoldenBoneHit then
            differentList.goldenBoneHit = goldenBoneHit
        end

    end
    return differentList
end

--针对bingoCards
function CodeGameScreenBingoPriatesMachine:contrastTwoArrayList(list1,list2)
    local contrast = false
    --判断长度是否一致
    if table_length(list1) ~= table_length(list2) then
        return false
    end
    --长度一致判断val
    local listNum = table_length(list1)
    for i=1,listNum do
        contrast = self:contrastTwoList(list1[i],list2[i])
    end

    return contrast
end

function CodeGameScreenBingoPriatesMachine:contrastTwoList(tab1,tab2)
    --判断长度是否一致
    if table_length(tab1) ~= table_length(tab2) then
        return false
    end
    -- if table_length(tab1) == 0 and table_length(tab2) == 0 then
    --     return true
    -- end
    local iTab1 = clone(tab1)
    local iTab2 = clone(tab2)
    for i1,v1 in ipairs(iTab1) do
        for i2,v2 in ipairs(iTab2) do
            if v1 == v2 then
                table.remove(iTab1,i1)
                table.remove(iTab2,i2)
                if #iTab1 == 0 and #iTab2 == 0 then
                    return true
                else
                    return self:contrastTwoList(iTab1,iTab2)
                end
            end
        end
    end
    return false
end
-- function CodeGameScreenBingoPriatesMachine:contrastTwoList(list1,list2)
--     --判断长度是否一致
--     if table_length(list1) ~= table_length(list2) then
--         return false
--     end
--     --长度一致判断val
--     local listNum = table_length(list1)
--     for i,v in ipairs(list1) do
--         for i,v in ipairs(list2) do
            
--         end
--     end
--     for i=1,listNum do
--         if list1[i] ~= list2[i] then
--             return false
--         end
--     end

--     return true
-- end

--判断数字是否一致
function CodeGameScreenBingoPriatesMachine:contrastTwoNum(num1,num2)
    if num1 == num2 then
        return true
    end
    return false
end

--增加对比打印
--放在玩法结束后以及不触发玩法时飞行结束
function CodeGameScreenBingoPriatesMachine:sendErrorBingoDate()
    local differentList = self:contrastBingoNetData()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bingoData = selfdata.bingoData or {}
    local newBingoData = selfdata.newBingoData
    if table_length(differentList) > 0 then
        -- print("differentList:"..cjson.encode(differentList))
        --刷新bingoUi
        self:winBingoRestBingoUI()
        local curBingoUiData = self:getDataForUi()
        if 2 ~= DEBUG then
            local sTitel = "[CodeGameScreenBingoPriatesMachine:sendErrorBingoDate] "
            local sUser = " error_userInfo_ udid=" .. (globalData.userRunData.userUdid or "isnil") .. " machineName="..(globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. " gameSeqID = " .. (globalData.seqId or "")
            local requestId = "Headers requestId =" .. (globalData.requestId or "isnil")
            local sBingoData = " 本次spin的bingoData = " .. cjson.encode(bingoData)
            local sNewBingoData = "本次有bingo连线newBingoData = " .. cjson.encode(newBingoData)
            local curBingoUiData = "当前ui显示的bingoData = " .. cjson.encode(curBingoUiData)

            local msg = sTitel .. sUser .. requestId .. sBingoData .. sNewBingoData .. curBingoUiData
            if util_sendToSplunkMsg then
                util_sendToSplunkMsg("BingoPriates_luaError",msg)
            end
        end
    end
end

function CodeGameScreenBingoPriatesMachine:beginReel()
    CodeGameScreenBingoPriatesMachine.super.beginReel(self)
    local bingoData = self.m_BingoNetData or {}
    local bingo = bingoData.bingo
    if bingo then
        self:sendErrorBingoDate()
    end
end

return CodeGameScreenBingoPriatesMachine






