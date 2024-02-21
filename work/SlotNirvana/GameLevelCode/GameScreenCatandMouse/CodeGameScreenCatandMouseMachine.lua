---
-- island li
-- 2019年1月26日
-- CodeGameScreenCatandMouseMachine.lua
-- 
-- 玩法：
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local SlotParentData = require "data.slotsdata.SlotParentData"
local CodeGameScreenCatandMouseMachine = class("CodeGameScreenCatandMouseMachine", BaseNewReelMachine)

CodeGameScreenCatandMouseMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenCatandMouseMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenCatandMouseMachine.SYMBOL_CAT_CLOTH = 102
CodeGameScreenCatandMouseMachine.SYMBOL_CAT_STONE = 101
CodeGameScreenCatandMouseMachine.SYMBOL_CAT_SCISSORS = 100
CodeGameScreenCatandMouseMachine.SYMBOL_MOUSE_CLOTH = 202
CodeGameScreenCatandMouseMachine.SYMBOL_MOUSE_STONE = 201
CodeGameScreenCatandMouseMachine.SYMBOL_MOUSE_SCISSORS = 200

--自定义玩法
CodeGameScreenCatandMouseMachine.COLLECT_BETTLE_EFFECT =  GameEffect.EFFECT_SELF_EFFECT - 3 -- 收集玩法（收集玩法包括猜拳玩法）
CodeGameScreenCatandMouseMachine.CAT_WIN_EFFECT =  GameEffect.EFFECT_SELF_EFFECT - 2 -- 猫赢
CodeGameScreenCatandMouseMachine.MOUSE_WIN_EFFECT =  GameEffect.EFFECT_SELF_EFFECT - 1 -- 老鼠赢

--定义上方人物显示的index
local UPPEOPLE_INDEX = {
    INDEX_ONE = 1,
    INDEX_TWO = 2,
    INDEX_THREE = 3,
    INDEX_FOUR = 4,
    INDEX_FIVE = 5,
    INDEX_SIX = 6,
    INDEX_SEVEN = 7,
    INDEX_EIGHT = 8,
    INDEX_NICE = 9,
    INDEX_TEN = 10,
    INDEX_ELEVEN = 11,
    INDEX_TWELVE = 12,
    INDEX_THIRTEEN = 13,
    INDEX_FOURTEEN = 14,
    INDEX_FIFTEEN = 15,
    INDEX_SIXTEEN = 16,
    INDEX_SEVENTEEN = 17
}

--定义free弹板显示的index
local FREESHOWUPNUM = {
    CAT = 1,
    MOUSE = 2,
    BIG_CAT = 3,
    BIG_MOUSE = 4,
    BALANCE = 5
}

--定义收集区间

local PROGRESS = {
    CAT_FREE = 0,
    BIGCAT_lEFT = 1,
    BIGCAT_RIGHT = 8,
    CAT_LEFT = 9,
    CAT_RIGHT = 15,
    BOTH_LEFT = 16,
    BOTH_RIGHT = 20,
    MOUSE_LEFT = 21,
    MOUSE_RIGHT = 27,
    BIGMOUSE_LEFT = 28,
    BIGMOUSE_RIGHT = 35,
    MOUSE_FREE = 36
}

-- 构造函数
function CodeGameScreenCatandMouseMachine:ctor()
    CodeGameScreenCatandMouseMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_storageMark = {}         --储存标记的列表
    self.m_betTotalCoins = 0        --当前bet

    self.curCollectNum = 18

    self.upRenWuList = {}           --存储上方人物spine

    self.m_tempLightSymbol = {}     --储存free中临时的高亮图标

    self.m_tempWildSymbol = {}     --储存free中临时的高亮wild图标

    self.bonusRenWu = nil     
    self.collectWaitTime = 0
    self.freeRenWuCollrctNum = 0

    self.lockIsWild = false

    self.m_scatterBulingSoundArry2 = {}     --h2落地音效

    self.soundIdForIdle = nil
    self.soundIndexForIdle = 1
    self.isResetSoundId = false


    self:initGame()
end

function CodeGameScreenCatandMouseMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("CatandMouseConfig.csv", "LevelCatandMouseConfig.lua")
    -- self.m_configData.m_machine = self
    self.m_configData:changeSpecialSymbolList(0)
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCatandMouseMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CatandMouse"  
end

function CodeGameScreenCatandMouseMachine:initUI()


    self.wenZi = util_createView("CodeCatandMouseSrc.CatandMouseTipsView")
    self:findChild("Node_wenzikuang"):addChild(self.wenZi)    --上方文字框


   --进度条
    self.collectBar = util_createView("CodeCatandMouseSrc.CatandMouseCollectBar")
    self:findChild("Node_shoujitiao"):addChild(self.collectBar)

    --进度条猫、老鼠以及反馈特效
    
    self.collectUpCat = util_createAnimation("CatandMouse_shoujimao_bd.csb")
    self:findChild("Node_shoujimao_1"):addChild(self.collectUpCat,100)

    self.collectCat = util_createAnimation("CatandMouse_shoujimao.csb")
    self:findChild("Node_shoujimao"):addChild(self.collectCat)
    self.collectCat:runCsbAction("idleframe",true)

    self.cat = util_spineCreate("CatandMouse_zhujiemian_maotou",true,true)
    self.collectCat:findChild("CatandMouse_zhujiemian_maotou"):addChild(self.cat)
    util_spinePlay(self.cat,"idleframe",true)


    
    self.collectUpMouse = util_createAnimation("CatandMouse_shoujimao_bd.csb")
    self:findChild("Node_shoujishu_1"):addChild(self.collectUpMouse,100)
    self.collectMouse = util_createAnimation("CatandMouse_shoujishu.csb")
    self:findChild("Node_shoujishu"):addChild(self.collectMouse)
    self.collectMouse:runCsbAction("idleframe",true)

    self.mouse = util_spineCreate("CatandMouse_zhujiemian_shutou",true,true)
    self.collectMouse:findChild("CatandMouse_zhujiemian_shutou"):addChild(self.mouse)
    util_spinePlay(self.mouse,"idleframe",true)

    local node_bar = self:findChild("Node_freejishukuang")
    self.m_baseFreeSpinBar = util_createView("CodeCatandMouseSrc.CatandMouseFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)

    self.bgFire = util_createAnimation("CatandMouse_bg_fire.csb")
    self:findChild("Node_bg_fire"):addChild(self.bgFire)
    self.bgFire:setVisible(false)

    self.mask = util_createAnimation("CatandMouse_bonus_mask.csb") --压黑
    self:findChild("mask"):addChild(self.mask)
    self.mask:setVisible(false)


    -- local BottomNode_bar = self.m_bottomUI:findChild("font_last_win_value")
    -- self.m_jiesuanAct = util_createAnimation("CatandMouse_totalwin.csb")
    -- local bottomNodePos = util_convertToNodeSpace(BottomNode_bar,self)
    -- self:addChild(self.m_jiesuanAct,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    -- self.m_jiesuanAct:setPosition(bottomNodePos)
    -- self.m_jiesuanAct:setVisible(false)

    --创建四个node，用来做动画切换的延迟
    self.node1 = cc.Node:create()
    self:addChild(self.node1)
    self.node2 = cc.Node:create()
    self:addChild(self.node2)
    self.node3 = cc.Node:create()
    self:addChild(self.node3)
    self.node4 = cc.Node:create()
    self:addChild(self.node4)
    self.node5 = cc.Node:create()
    self:addChild(self.node5)

    self.colorLayerNode = cc.Node:create()
    self:addChild(self.colorLayerNode)

    self.soundNode = cc.Node:create()
    self:addChild(self.soundNode)

    self:hideColorLayer( )

    self:createAllUpRenwu()
    self:createAllUpBg()
    self:setMouseDownSound()
    self:updateCollectEffect(false)

    
    self.collectBar:setCatPercent()
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "CatandMouseSounds/music_CatandMouse_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "CatandMouseSounds/music_CatandMouse_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            self.m_winSoundsId = nil
        end)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenCatandMouseMachine:showColorLayer( )
    self.colorLayerNode:stopAllActions()
    self.slotParentNode_1:setOpacity(200)   --由于FadeOut将透明度设置为0，所以在显示的时候设置一下透明度
    self.slotParentNode_1:setVisible(true)
end

function CodeGameScreenCatandMouseMachine:hideColorLayer( )
    self.colorLayerNode:stopAllActions()
    local act = cc.FadeOut:create(0.3)
    self.slotParentNode_1:runAction(act)
    performWithDelay(self.colorLayerNode,function (  )
        self.slotParentNode_1:setVisible(false)
    end,0.1)

end

function CodeGameScreenCatandMouseMachine:initMachineUI( )
    
    CodeGameScreenCatandMouseMachine.super.initMachineUI( self )

    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for i =1 ,#self.m_slotParents do
        local parentData = self.m_slotParents[i]
        
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

    end
    --创建压黑层
    local node = cc.Node:create()
    local reel1 = self:findChild("sp_reel_1")
    local reelSize1 = reel1:getContentSize()
    self.m_slotParents[5].slotParent:getParent():addChild(node,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)
    self.slotParentNode_1 = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
    self.slotParentNode_1:setOpacity(200)
    self.slotParentNode_1:setContentSize(cc.size(slotW, slotH))
    self.slotParentNode_1:setAnchorPoint(cc.p(0, 0))
    self.slotParentNode_1:setTouchEnabled(false)
    node:addChild(self.slotParentNode_1,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)
    self.slotParentNode_1:setPosition(cc.p(-slotW + reelSize1.width + reelSize1.width/2 ,0))
    self.slotParentNode_1:setVisible(false)
end

--创建上方人物
function CodeGameScreenCatandMouseMachine:createAllUpRenwu( )
    self.renWu1 = util_spineCreate("CatandMouse_juese_1",true,true)   --均势
    self:findChild("Node_shangfangrenwu"):addChild(self.renWu1,1)
    -- self.renWu1:setVisible(false)
    util_spinePlay(self.renWu1,"idleframe",true)
    table.insert(self.upRenWuList,self.renWu1)

    self.renWu2 = util_spineCreate("CatandMouse_juese_2",true,true)   --猫优势
    self:findChild("Node_shangfangrenwu"):addChild(self.renWu2,2)
    self.renWu2:setVisible(false)
    table.insert(self.upRenWuList,self.renWu2)

    self.renWu3 = util_spineCreate("CatandMouse_juese_4",true,true)   --猫大优势
    self:findChild("Node_shangfangrenwu"):addChild(self.renWu3,3)
    self.renWu3:setVisible(false)
    table.insert(self.upRenWuList,self.renWu3)

    self.renWu4 = util_spineCreate("CatandMouse_juese_3",true,true)   --鼠优势
    self:findChild("Node_shangfangrenwu"):addChild(self.renWu4,4)
    self.renWu4:setVisible(false)
    table.insert(self.upRenWuList,self.renWu4)

    self.renWu5 = util_spineCreate("CatandMouse_juese_5",true,true)   --鼠大优势
    self:findChild("Node_shangfangrenwu"):addChild(self.renWu5,5)
    self.renWu5:setVisible(false)
    table.insert(self.upRenWuList,self.renWu5)

    self.renWu6 = util_spineCreate("CatandMouse_juese_laoshu",true,true)   --鼠玩法
    self:findChild("Node_shangfangrenwu"):addChild(self.renWu6,6)
    self.renWu6:setVisible(false)
    table.insert(self.upRenWuList,self.renWu6)

    self.renWu7 = util_spineCreate("CatandMouse_juese_mao",true,true)   --猫玩法
    self:findChild("Node_shangfangrenwu"):addChild(self.renWu7,7)
    self.renWu7:setVisible(false)
    table.insert(self.upRenWuList,self.renWu7)
end

--上方人物背景
function CodeGameScreenCatandMouseMachine:createAllUpBg( )
    self.upBg = util_spineCreate("GameScreenCatandMouseBg",true,true)
    -- self.balance = util_spineCreate("CatandMouse_juese_1_2",true,true)   --背景
    self:findChild("Node_shangfangrenwuBg"):addChild(self.upBg)
    util_spinePlay(self.upBg,"idleframe1",true)

    self.lightning = util_spineCreate("GameScreenCatandMouseBg2",true,true)     --闪电
    self:findChild("Node_shandian"):addChild(self.lightning)
    util_spinePlay(self.lightning,"idleframe1",true)

    self.lightningUp = util_spineCreate("GameScreenCatandMouseBg2",true,true)       --大优势特殊闪电
    self:findChild("Node_shandian_0"):addChild(self.lightningUp)
    self.lightningUp:setVisible(false)
end

function CodeGameScreenCatandMouseMachine:clearAllUp( )

    for i,v in ipairs(self.upRenWuList) do
        v:removeFromParent()
    end
    self.upRenWuList = {}

end

--根据index获取显示不同的上方人物
function CodeGameScreenCatandMouseMachine:getShowUpRenWu(index,isIdle)
    for i,v in ipairs(self.upRenWuList) do
        if index == i then
            v:setVisible(true)
            if index == 6 or index == 7 then
                if isIdle then
                    util_spinePlay(v,"idleframe1",true)
                end
            else
                if isIdle then
                    util_spinePlay(v,"idleframe",true)
                end
            end
            
        else
            v:setVisible(false)
        end
    end
end

function CodeGameScreenCatandMouseMachine:setUpRenWuVisible(index1,index2)
    for i,v in ipairs(self.upRenWuList) do
        if index1 == i or index2 == i then
            v:setVisible(true)
        else
            v:setVisible(false)
        end
    end
end

function CodeGameScreenCatandMouseMachine:setShowUpBg(index)
    if index then
        self.upBg:setVisible(true)
        self.lightning:setVisible(true)
        if index == UPPEOPLE_INDEX.INDEX_ONE then
            util_spinePlay(self.upBg,"idleframe1",true)
            util_spinePlay(self.lightning,"idleframe1",true)
        elseif index == UPPEOPLE_INDEX.INDEX_TWO then
            util_spinePlay(self.upBg,"idleframe2",true)
            util_spinePlay(self.lightning,"idleframe2",true)
        elseif index == UPPEOPLE_INDEX.INDEX_THREE then
            util_spinePlay(self.upBg,"idleframe3",true)
            util_spinePlay(self.lightning,"idleframe3",true)
        elseif index == UPPEOPLE_INDEX.INDEX_FOUR then
            self.lightning:setVisible(false)
            self.lightningUp:setVisible(true)
            util_spinePlay(self.upBg,"idleframe4",true)
            util_spinePlay(self.lightningUp,"idleframe4",true)
        elseif index == UPPEOPLE_INDEX.INDEX_FIVE then
            self.lightning:setVisible(false)
            self.lightningUp:setVisible(true)
            util_spinePlay(self.upBg,"idleframe5",true)
            util_spinePlay(self.lightningUp,"idleframe5",true)
        end
    else
        self.upBg:setVisible(false)
        self.lightning:setVisible(false)
        self.lightningUp:setVisible(false)
    end
    
end

function CodeGameScreenCatandMouseMachine:enterGamePlayMusic(  )
    
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        scheduler.performWithDelayGlobal(function(  )
        
            self:playEnterGameSound( "CatandMouseSounds/music_CatandMouse_enter.mp3" )
      
          end,0.4,self:getModuleName())
    end  
end

function CodeGameScreenCatandMouseMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCatandMouseMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    self.m_betTotalCoins = totalBet
end

function CodeGameScreenCatandMouseMachine:addObservers()
    CodeGameScreenCatandMouseMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)

        local totalBet = globalData.slotRunData:getCurTotalBet( )

        -- 不同的bet切换才刷新框
        if self.m_betTotalCoins ~=  totalBet  then
            self.m_betTotalCoins = totalBet
            self:changeBetUpdataCollect(totalBet)
            
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenCatandMouseMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCatandMouseMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    self:clearAllUp()       --退出游戏清空所有上方人物以及背景
    self.node1:removeFromParent()
    self.node2:removeFromParent()
    self.node3:removeFromParent()
    self.node4:removeFromParent()
    self.node5:removeFromParent()
    self.soundNode:removeFromParent()
    self.colorLayerNode:removeFromParent()
    self.m_scatterBulingSoundArry2 = {}
    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCatandMouseMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_CAT_CLOTH then
        return "Socre_CatandMouse_bu1"
    elseif symbolType == self.SYMBOL_CAT_STONE then
        return "Socre_CatandMouse_shitou1"
    elseif symbolType == self.SYMBOL_CAT_SCISSORS then
        return "Socre_CatandMouse_jiandao1"
    elseif symbolType == self.SYMBOL_MOUSE_CLOTH then
        return "Socre_CatandMouse_bu2"
    elseif symbolType == self.SYMBOL_MOUSE_STONE then
        return "Socre_CatandMouse_shitou2"
    elseif symbolType == self.SYMBOL_MOUSE_SCISSORS then
        return "Socre_CatandMouse_jiandao2"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_CatandMouse_10"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCatandMouseMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCatandMouseMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CAT_CLOTH,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CAT_STONE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CAT_SCISSORS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MOUSE_CLOTH,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MOUSE_STONE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MOUSE_SCISSORS,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCatandMouseMachine:MachineRule_initGame(  )
    --刷新进度条
    self:updateCollectEffect(false)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeKind or nil   
        if freeSpinType == "CAT" then
            self.m_configData:changeSpecialSymbolList(1)
            self.wenZi:setShowTips(3)
        elseif freeSpinType == "MOUSE" then
            self.m_configData:changeSpecialSymbolList(2)
            self.wenZi:setShowTips(2)
        end
        self:freeSpinStartShow()
        self:levelFreeSpinEffectChange()
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenCatandMouseMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCatandMouseMachine.super.slotOneReelDown(self,reelCol) 

    if reelCol == 2 then
        self:hideColorLayer( )
    end

    for row = 1, self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
        if symbolNode and self:isScatterSymbol(symbolNode.p_symbolType) then
            self:specialSymbolActionTreatment( symbolNode)
        end
    end
end

function CodeGameScreenCatandMouseMachine:isScatterSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        return true
    end
    return false
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCatandMouseMachine:levelFreeSpinEffectChange()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeKind or nil   
    if freeSpinType == "CAT" then
        self.m_gameBg:findChild("CatandMouse_zhujiemian_BJ_7_7"):setVisible(false)
        self.m_gameBg:findChild("CatandMouse_zhujiemian_BJ_6_6"):setVisible(true)
    elseif freeSpinType == "MOUSE" then
        self.m_gameBg:findChild("CatandMouse_zhujiemian_BJ_7_7"):setVisible(true)
        self.m_gameBg:findChild("CatandMouse_zhujiemian_BJ_6_6"):setVisible(false)
    end
    -- 自定义事件修改背景动画
    self.m_gameBg:runCsbAction("bonus",true)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCatandMouseMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    self.m_gameBg:runCsbAction("base",true)
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关

--根据类型的不同展示不同的开始弹板
function CodeGameScreenCatandMouseMachine:showFreeSpinStart(num, func, isAuto)
    local freeSpinStartview = util_spineCreate("CatandMouse_guochang_2",true,true)   --猫玩法开始弹板
    local soundName = "CatandMouseSounds/music_CatandMouse_cat_enter_fs.mp3"
    local tipsIndex = 3
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeKind or nil   
    if freeSpinType == "MOUSE" then
        tipsIndex = 2
        soundName = "CatandMouseSounds/music_CatandMouse_mouse_enter_fs.mp3"
        freeSpinStartview = util_spineCreate("CatandMouse_guochang_1",true,true)
    end
    gLobalSoundManager:playSound(soundName)
    gLobalViewManager:showUI(freeSpinStartview)
    freeSpinStartview:setPosition(display.center)
    freeSpinStartview:setScale(self.m_machineRootScale)
    util_spinePlay(freeSpinStartview,"actionframe",false)
    performWithDelay(self,function (  )
        self.wenZi:setShowTips(tipsIndex)
        if func then
            func()
        end
    end,105/30)
    performWithDelay(self,function (  )
        
        freeSpinStartview:removeFromParent()
    end,115/30)
end

--播放free开始弹板之前先播放上方人物效果
function CodeGameScreenCatandMouseMachine:FreeUpRenWuWinAct(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --猫图标的位置
    local collect = selfData.CatandMouseCollect or {}
    local catProgress = collect.CatCollectProgress or 18
    local mouseProgress = collect.MouseCollectProgress or 18
    if self.freeRenWuCollrctNum == FREESHOWUPNUM.BIG_MOUSE then  --老鼠大优势 
        util_spinePlay(self.renWu5,"switch7",false)
        util_spinePlay(self.upBg,"5to7",false)
        self:isShowLightingUp(true)
        util_spinePlay(self.lightningUp,"5to7",false)
        performWithDelay(self,function (  )
            if func then
                func()
            end
        end,1/3)
    elseif self.freeRenWuCollrctNum == FREESHOWUPNUM.MOUSE then     --老鼠优势 
        self:lastUpCatAndMouse(15)
        self:changeUpCatAndMouse(14)
        util_spinePlay(self.upBg,"3to7",false)
        self:isShowLightingUp()
        util_spinePlay(self.lightning,"3to7",false)
        util_spinePlay(self.lightningUp,"3to7",false)
        performWithDelay(self,function (  )
            if func then
                func()
            end
        end,0.5)
        performWithDelay(self,function (  )
            self:isShowLightingUp(true)
        end,16/30)
    elseif self.freeRenWuCollrctNum == FREESHOWUPNUM.BIG_CAT then     --猫大优势
        util_spinePlay(self.renWu3,"switch6",false)
        util_spinePlay(self.upBg,"4to6",false)
        self:isShowLightingUp(true)
        util_spinePlay(self.lightningUp,"4to6",false)
        performWithDelay(self,function (  )
            if func then
                func()
            end
        end,1/3)
    elseif self.freeRenWuCollrctNum == FREESHOWUPNUM.CAT then     --猫优势
        self:lastUpCatAndMouse(16)
        self:changeUpCatAndMouse(15)
        util_spinePlay(self.upBg,"2to6",false)
        self:isShowLightingUp()
        util_spinePlay(self.lightning,"2to6",false)
        util_spinePlay(self.lightningUp,"2to6",false)
        performWithDelay(self,function (  )
            if func then
                func()
            end
        end,0.5)
        performWithDelay(self,function (  )
            self:isShowLightingUp(true)
        end,16/30)
    else
        if self.freeRenWuCollrctNum == 0 then
            if mouseProgress >= PROGRESS.MOUSE_FREE then
                self:getShowUpRenWu(5)
                util_spinePlay(self.renWu5,"switch7",false)
                util_spinePlay(self.upBg,"5to7",false)
                self:isShowLightingUp(true)
                util_spinePlay(self.lightningUp,"5to7",false)
                performWithDelay(self,function (  )
                    if func then
                        func()
                    end
                end,1/3)
            elseif mouseProgress <= PROGRESS.CAT_FREE then
                self:getShowUpRenWu(3)
                util_spinePlay(self.renWu3,"switch6",false)
                util_spinePlay(self.upBg,"4to6",false)
                self:isShowLightingUp(true)
                util_spinePlay(self.lightningUp,"4to6",false)
                performWithDelay(self,function (  )
                    if func then
                        func()
                    end
                end,1/3)
            end
        else
            performWithDelay(self,function (  )
                if func then
                    func()
                end
            end,0.5)
        end
        
    end
    
end

function CodeGameScreenCatandMouseMachine:showFreeSpinStartRenWu(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeKind or nil   
    if freeSpinType == "MOUSE" then
        self.m_configData:changeSpecialSymbolList(2)
        self:getShowUpRenWu(6,true)
    elseif freeSpinType == "CAT" then
        self.m_configData:changeSpecialSymbolList(1)
        self:getShowUpRenWu(7,true)
    end
end

-- FreeSpinstart
function CodeGameScreenCatandMouseMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_enter_fs.mp3")
    
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            --上方人物触发动画
            self:FreeUpRenWuWinAct(function (  )
                self:clearCurMusicBg()
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                    local freeKind = selfData.freeKind
                    local GuoChang = util_createView("CodeCatandMouseSrc.CatandMouseGuoChangView",freeKind)
                    self:addChild(GuoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
                    GuoChang:setPosition(display.center)
                    GuoChang:showGuochang(function (  )
                        
                        effectData.p_isPlay = true
                        self:playGameEffect() 
                    end)   
                    performWithDelay(self,function (  )
                        self:triggerFreeSpinCallFun()
                        self:freeSpinStartShow()
                    end,2)  
                end)
            end)
        end
    end

    self.collectMouse:runCsbAction("jiman")
    self.collectCat:runCsbAction("jiman")
    self.collectBar:showFreeJiMan()
    self:showSoundForIdle(false,nil,true)
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()  
    end,3/2)

    
end

function CodeGameScreenCatandMouseMachine:freeSpinStartShow( )
    self:setShowUpBg()
    self:showFreeSpinStartRenWu()
    self.bgFire:setVisible(false)
    util_setCsbVisible(self.m_baseFreeSpinBar, true)
    self.collectBar:setVisible(false)
    self.cat:setVisible(false)
    self.mouse:setVisible(false)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeKind = selfData.freeKind
end

function CodeGameScreenCatandMouseMachine:freeSpinOverShow( )
    self.wenZi:setShowTips(1)
    self:getShowUpRenWu(1,true)
    self:setShowUpBg(1)
    self.collectBar:setVisible(true)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.collectBar:updataProgress(18,18,false)
    self.cat:setVisible(true)
    util_spinePlay(self.cat,"idleframe",true)
    self.mouse:setVisible(true)
    util_spinePlay(self.mouse,"idleframe",true)
    self.freeRenWuCollrctNum = 0
    self:showSoundForIdle(false,FREESHOWUPNUM.BALANCE,false)
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    local data = self.m_betNetCollectData[tostring(totalBet)]
    local occupyNum = data.occupyNum or {}
    if data ~= nil then
        local occupyNum = data.occupyNum or {}
        if table_length(occupyNum) then
            occupyNum[1] = 18
            occupyNum[2] = 18
        end

    end
end

function CodeGameScreenCatandMouseMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local path = "BonusOverCat"
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeKind or nil   
    if freeSpinType == "MOUSE" then
        path = "BonusOverMouse"
    end
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    return self:showDialog(path, ownerlist, func)
end

function CodeGameScreenCatandMouseMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_over_fs.mp3")
    local soundName = "CatandMouseSounds/music_CatandMouse_cat_over_fs.mp3"
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeKind or nil   
    if freeSpinType == "MOUSE" then
        soundName = "CatandMouseSounds/music_CatandMouse_mouse_over_fs.mp3"
    end
    gLobalSoundManager:playSound(soundName)
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
   
    local view = self:showFreeSpinOver( strCoins, 
        
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:freeSpinOverShow()
        self:triggerFreeSpinOverCallFun()
    end)
    view:findChild("Node_1"):setScale(self.m_machineRootScale)
    self:updateLabelSize({label = view:findChild("m_lb_coins"),sx = 0.94,sy = 0.94},680)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeKind or nil   
    local OverRenWu = util_spineCreate("CatandMouse_juese_mao",true,true)
    if freeSpinType == "MOUSE" then
        OverRenWu = util_spineCreate("CatandMouse_juese_laoshu",true,true)
    end
    view:findChild("juese"):addChild(OverRenWu)
    util_spinePlay(OverRenWu,"actionframe_tanban")
    util_spineEndCallFunc(OverRenWu,"actionframe_tanban",function (  )
        util_spinePlay(OverRenWu,"idleframe_tanban",true)
    end)
    self.m_configData:changeSpecialSymbolList(0)
    self.curCollectNum = 18
end

-- ---------------------------收集玩法start------------------

--收集反馈动画
function CodeGameScreenCatandMouseMachine:collectFeedback(type)
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --猫图标的位置
    local collect = selfData.CatandMouseCollect or {}
    local catProgress = collect.CatCollectProgress or 0
    local mouseProgress = collect.MouseCollectProgress or 0
    if type then
        if type == 1 then
            
            if catProgress >= PROGRESS.MOUSE_FREE then
                util_spinePlay(self.cat,"jiman",false)
                util_spineEndCallFunc(self.cat,"jiman",function (  )
                    util_spinePlay(self.cat,"idleframe_jiman",true)
                end)
            else
                util_spinePlay(self.cat,"shouji2",false)
                util_spineEndCallFunc(self.cat,"shouji2",function (  )
                    util_spinePlay(self.cat,"idleframe",true)
                end)
            end
            self.collectUpCat:runCsbAction("actionframe")
            self.collectCat:runCsbAction("actionframe",false,function (  )
                self.collectCat:runCsbAction("idleframe",true)
            end)
        elseif type == 2 then
            if mouseProgress >= PROGRESS.MOUSE_FREE then
                util_spinePlay(self.mouse,"jiman",false)
                util_spineEndCallFunc(self.mouse,"jiman",function (  )
                    util_spinePlay(self.mouse,"idleframe_jiman",true)
                end)
            else
                util_spinePlay(self.mouse,"shouji2",false)
                util_spineEndCallFunc(self.mouse,"shouji2",function (  )
                    util_spinePlay(self.mouse,"idleframe",true)
                end)
            end
            self.collectUpMouse:runCsbAction("actionframe")
            self.collectMouse:runCsbAction("actionframe",false,function (  )
                self.collectMouse:runCsbAction("idleframe",true)
            end)
        end
    end
end

--判断收集的小块是否在连线中
function CodeGameScreenCatandMouseMachine:isShowLineAnim(symbol)
    local a = self.m_reelResultLines
    local b = a.vecValidMatrixSymPos
    if self.m_reelResultLines ~= nil then
        for i,v in ipairs(self.m_reelResultLines) do
            for j,v in ipairs(self.m_reelResultLines[i].vecValidMatrixSymPos) do
                if v.iY == symbol.p_cloumnIndex and v.iX == symbol.p_rowIndex then
                    local slotNode = self:getFixSymbol(v.iY, v.iX, SYMBOL_NODE_TAG)
                    if slotNode ~= nil then
                        if slotNode.p_symbolType == symbol.p_symbolType then
                            return true
                        end
                    end
                end
                
            end
        end
    end
    return false
end

-- function CodeGameScreenCatandMouseMachine:showWinJieSunaAct( )
--     self.m_jiesuanAct:setVisible(true)
--     self.m_jiesuanAct:findChild("Particle_2"):resetSystem()
--     self.m_jiesuanAct:findChild("Particle_1"):resetSystem()
--     self.m_jiesuanAct:runCsbAction("actionframe")
-- end

--播放猜拳动画
function CodeGameScreenCatandMouseMachine:showSymbolEffect(func)
    --参数解释：symbol为在棋盘上的小块，node为飞行的小块，node1为飞行小块下层（为达到飞行效果，创建两个临时小块node,node1）
    local function flyToCollect(symbol,node,node1,startPos,endPos,type)
        
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        --猫图标的位置
        local collect = selfData.CatandMouseCollect or {}
        local catProgress = collect.CatCollectProgress or 0
        local mouseProgress = collect.MouseCollectProgress or 0
        local actList = {}
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            symbol:runAnim("actionframe2",false,function (  )
                if self:isShowLineAnim(symbol) then
                    if mouseProgress < PROGRESS.MOUSE_FREE and mouseProgress > PROGRESS.CAT_FREE then
                        symbol:runLineAnim()
                    end
                end
            end)
            util_spinePlay(node,"shouji",false)
            util_spinePlay(node1,"shouji_di",false)
        end)
        actList[#actList + 1] = cc.DelayTime:create(5/30)
        actList[#actList + 1 ] = cc.BezierTo:create(0.3,{cc.p(startPos.x , startPos.y), cc.p(endPos.x, startPos.y), endPos})
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            self:collectFeedback(type)
        end)
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            node1:removeFromParent()
            node:removeFromParent()
        end)
        local sq = cc.Sequence:create(actList)
        node:runAction(sq)
    end
    self.collectWaitTime = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --大图标收集
    --猫图标的位置
    local collect = selfData.CatandMouseCollect or {}
    local catPos = collect.CatCollectlocs or {}
    --老鼠图标的位置
    local mousePos = collect.MouseCollectlocs or {}
    --剪刀石头布收集
    local winType = collect.WinType or nil    --0，1，2分别表示平局，猫赢，老鼠赢
    local catStoredIcons = collect.CatStoredIcons or {}
    local mouseStoredIcons = collect.MouseStoredIcons or {}
    --猫和鼠的飞行最终位置
    local endPos1 = cc.p(self:findChild("Node_shoujimao"):getPositionX(),self:findChild("Node_shoujimao"):getPositionY())
    local endPos2 = cc.p(self:findChild("Node_shoujishu"):getPositionX(),self:findChild("Node_shoujishu"):getPositionY())
    --先播放猜拳
    if winType ~= nil and winType == 1 then
        self.collectWaitTime = 2
        --播放bonus小块动画
        self:showBonusAction(catStoredIcons,mouseStoredIcons,function (  )
            
            local winCoins = collect.BattleWin
            local endNode = self.m_bottomUI:findChild("font_last_win_value")
            local fixPos = self:getRowAndColByPos(catStoredIcons[1])
            local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX,SYMBOL_NODE_TAG)
            symbol:runAnim("actionframe",false,function (  )
                symbol:getCcbProperty("m_lb_num"):setString("")
                local endPos = util_convertToNodeSpace(endNode,self)
                self:runFlyCoins(1,symbol,endPos,winCoins,function (  )
                    gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_caiquan_changeCoins.mp3")
                    if #self.m_runSpinResultData.p_winLines == 0 then
                        local params = {winCoins,true,nil,0}
                        --检测大赢
                        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount , self.COLLECT_BETTLE_EFFECT)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true})
                    end
                end)
            end)
            performWithDelay(self,function (  )
                local startPos = util_convertToNodeSpace(symbol,self:findChild("root"))
                local tempSymbol = self:createTempSymbolForType(symbol.p_symbolType)
                self:findChild("root"):addChild(tempSymbol,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                tempSymbol:setPosition(startPos)
                self:showFlySymbolMora(symbol,tempSymbol,startPos,endPos1,1)
            end,self.collectWaitTime-0.8)
            
        end)
    elseif winType ~= nil and winType == 2 then
        self.collectWaitTime = 2
        self:showBonusAction(catStoredIcons,mouseStoredIcons,function (  )
            local winCoins = collect.BattleWin
            local endNode = self.m_bottomUI:findChild("font_last_win_value")

            local fixPos = self:getRowAndColByPos(mouseStoredIcons[1])
            local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX,SYMBOL_NODE_TAG)
            symbol:runAnim("actionframe",false,function (  )
                local endPos = util_convertToNodeSpace(endNode,self)
                symbol:getCcbProperty("m_lb_num"):setString("")
                self:runFlyCoins(2,symbol,endPos,winCoins,function (  )
                    if #self.m_runSpinResultData.p_winLines == 0 then
                        local params = {winCoins,true,nil,0}
                        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount , self.COLLECT_BETTLE_EFFECT)
                        
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true})
                    end
                end)
            end)
            
            performWithDelay(self,function (  )
                local startPos = util_convertToNodeSpace(symbol,self:findChild("root"))
                local tempSymbol = self:createTempSymbolForType(symbol.p_symbolType)
                self:findChild("root"):addChild(tempSymbol,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                tempSymbol:setPosition(startPos)
                self:showFlySymbolMora(symbol,tempSymbol,startPos,endPos2,2)
            end,self.collectWaitTime-0.8)
            
        end)
    elseif winType ~= nil and winType == 0 then
        self.collectWaitTime = 1.2
        self:showBonusAction(catStoredIcons,mouseStoredIcons)
    end
    performWithDelay(self,function (  )
        --收集大图标
        if #catPos > 0 or #mousePos > 0 then
            gLobalSoundManager:playSound("CatandMouseSounds/CatandMouse_CatFly.mp3")
        end
        for i,v in ipairs(catPos) do
            local fixPos = self:getRowAndColByPos(v)
            local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX,SYMBOL_NODE_TAG)
            local startPos = util_convertToNodeSpace(symbol,self:findChild("root"))
            local tempSymbol = util_spineCreate("Socre_CatandMouse_9",true,true)
            local tempSymbol1 = util_spineCreate("Socre_CatandMouse_9",true,true)
            self:findChild("root"):addChild(tempSymbol1,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER-10)
            tempSymbol1:setPosition(startPos)
            self:findChild("root"):addChild(tempSymbol,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
            tempSymbol:setPosition(startPos)
            flyToCollect(symbol,tempSymbol,tempSymbol1,startPos,endPos1,1)
        end

        for i,v in ipairs(mousePos) do
            local fixPos = self:getRowAndColByPos(v)
            local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX,SYMBOL_NODE_TAG)
            local startPos = util_convertToNodeSpace(symbol,self:findChild("root"))
            local tempSymbol = util_spineCreate("Socre_CatandMouse_8",true,true)
            self:findChild("root"):addChild(tempSymbol,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
            tempSymbol:setPosition(startPos)
            local tempSymbol1 = util_spineCreate("Socre_CatandMouse_8",true,true)
            self:findChild("root"):addChild(tempSymbol1,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 10)
            tempSymbol1:setPosition(startPos)
            flyToCollect(symbol,tempSymbol,tempSymbol1,startPos,endPos2,2)
        end
        performWithDelay(self,function (  )
            gLobalSoundManager:playSound("CatandMouseSounds/CatandMouse_collect_end.mp3")
        end,0.3 + 5/30)
    end,self.collectWaitTime)
    --如果没有连线，猜拳玩法获得大赢，等收集完再大赢
    if #self.m_runSpinResultData.p_winLines == 0 and self:isHaveBigWinEffect(self.m_runSpinResultData.p_winAmount) then
        self.collectWaitTime = 3
    end
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,self.collectWaitTime)
end

function CodeGameScreenCatandMouseMachine:showFlyShou(tempSymbol,index)
    for i=1,6 do
        if index == i then
            tempSymbol:findChild("shou_"..i):setVisible(true)
        else
            tempSymbol:findChild("shou_"..i):setVisible(false)
        end
    end
end

function CodeGameScreenCatandMouseMachine:createTempSymbolForType(type)
    local tempSymbol = util_createAnimation("Socre_CatandMouse_shouji_shou.csb")
    if type == self.SYMBOL_CAT_CLOTH then
        self:showFlyShou(tempSymbol,1)
    elseif type == self.SYMBOL_CAT_STONE then
        self:showFlyShou(tempSymbol,3)
    elseif type == self.SYMBOL_CAT_SCISSORS then
        self:showFlyShou(tempSymbol,2)
    elseif type == self.SYMBOL_MOUSE_CLOTH then
        self:showFlyShou(tempSymbol,4)
    elseif type == self.SYMBOL_MOUSE_STONE then
        self:showFlyShou(tempSymbol,6)
    elseif type == self.SYMBOL_MOUSE_SCISSORS then
        self:showFlyShou(tempSymbol,5)
    end
    return tempSymbol
end

--猜拳结束后进行飞钱
function CodeGameScreenCatandMouseMachine:runFlyCoins(type,curNode,endPos,coins,func)
    local nodeCoins = nil
    local startPos = util_convertToNodeSpace(curNode,self)
    nodeCoins = util_createAnimation("Socre_CatandMouse_shouji_qian.csb")
    nodeCoins:findChild("m_lb_num_1"):setVisible(false)
    nodeCoins:findChild("m_lb_num_2"):setVisible(false)
    self:addChild(nodeCoins,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    nodeCoins:setPosition(startPos)
    local score = util_formatCoins(coins, 3)
    self:updateLabelSize({label = nodeCoins:findChild("m_lb_num_"..type),sx = 1,sy = 1},111)
    if type then
        nodeCoins:findChild("m_lb_num_"..type):setString(score)
        nodeCoins:findChild("m_lb_num_"..type):setVisible(true)
    end
    gLobalSoundManager:playSound("CatandMouseSounds/CatandMouse_bonus_CoinsFly.mp3")
    local actList = {}
    actList[#actList + 1]  = cc.MoveTo:create(0.3,endPos)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        -- self:showWinJieSunaAct()
        self:playCoinWinEffectUI()
        nodeCoins:removeFromParent()
    end)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    nodeCoins:runAction(sq)
end

--猜拳结束后飞猜拳小块
--参数解释：symbol为在棋盘上的小块，node为飞行的小块，type分别为猫和鼠
function CodeGameScreenCatandMouseMachine:showFlySymbolMora(symbol,node,startPos,endPos,type)
    gLobalSoundManager:playSound("CatandMouseSounds/CatandMouse_bonus_BonusFly.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --猫图标的位置
    local collect = selfData.CatandMouseCollect or {}
    local catPos = collect.CatCollectlocs or {}
    --老鼠图标的位置
    local mousePos = collect.MouseCollectlocs or {}
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        symbol:runAnim("actionframe2")
        node:runCsbAction("actionframe")
    end)
    actList[#actList + 1 ] = cc.BezierTo:create(0.3,{cc.p(startPos.x , startPos.y), cc.p(endPos.x, startPos.y), endPos})
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        --如果有对应图标
        if type == 1 then
            if #catPos == 0 then
                gLobalSoundManager:playSound("CatandMouseSounds/CatandMouse_bonus_FlyEnd.mp3")
                self:collectFeedback(type)
            end
        elseif type == 2 then
            if #mousePos == 0 then
                gLobalSoundManager:playSound("CatandMouseSounds/CatandMouse_bonus_FlyEnd.mp3")
                self:collectFeedback(type)
            end
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

--node1,node2分别为猜拳的两个小块
function CodeGameScreenCatandMouseMachine:showSymbolBonusAction(node1,node2)
    if node1.p_rowIndex == node2.p_rowIndex then
        node1:runAnim("shouji2")
        node2:runAnim("shouji2")
    elseif node1.p_rowIndex > node2.p_rowIndex then
        node1:runAnim("shouji1")
        node2:runAnim("shouji3")
    elseif node1.p_rowIndex < node2.p_rowIndex then
        node1:runAnim("shouji3")
        node2:runAnim("shouji1")
    end
end

function CodeGameScreenCatandMouseMachine:showSymbolOverAction(node1,node2)
    if node1.p_rowIndex == node2.p_rowIndex then
        node1:runAnim("over2")
        node2:runAnim("over2")
    elseif node1.p_rowIndex > node2.p_rowIndex then
        node1:runAnim("over1")
        node2:runAnim("over3")
    elseif node1.p_rowIndex < node2.p_rowIndex then
        node1:runAnim("over3")
        node2:runAnim("over1")
    end
end

function CodeGameScreenCatandMouseMachine:showBonusAction(catStoredIcons,mouseStoredIcons,func)
    local fixPos1 = self:getRowAndColByPos(catStoredIcons[1])
    local fixPos2 = self:getRowAndColByPos(mouseStoredIcons[1])
    local catSymbol = self:getFixSymbol(fixPos1.iY, fixPos1.iX,SYMBOL_NODE_TAG)
    catSymbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10000)
    local mouseSymbol = self:getFixSymbol(fixPos2.iY, fixPos2.iX,SYMBOL_NODE_TAG)
    mouseSymbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10000)
    
    self:showSymbolBonusAction(catSymbol,mouseSymbol)
    performWithDelay(self,function (  )
        local catStartPos = util_convertToNodeSpace(catSymbol,self.m_clipParent)
        local mouseStartPos = util_convertToNodeSpace(mouseSymbol,self.m_clipParent)
        local endPos = cc.p((mouseStartPos.x + catStartPos.x)/2 - 30,(mouseStartPos.y + catStartPos.y)/2)
        local endPos1 = cc.p((mouseStartPos.x + catStartPos.x)/2 + 30,(mouseStartPos.y + catStartPos.y)/2)
        local moveToEnd1 = cc.MoveTo:create(0.14, endPos)
        local moveToEnd2 = cc.MoveTo:create(0.14, endPos1)
        local moveToCat = cc.MoveTo:create(0.14, catStartPos)
        local moveToMouse = cc.MoveTo:create(0.14, mouseStartPos)
        local collision = util_createAnimation("CatandMouse_BattleBd.csb")
        self.m_clipParent:addChild(collision,100000)
        collision:setPosition(endPos.x,endPos.y)
        if catSymbol and mouseSymbol then
            local catMove = cc.Sequence:create(moveToEnd1,moveToCat)
            local mouseMove = cc.Sequence:create(moveToEnd2,moveToMouse)
            catSymbol:runAction(catMove)
            mouseSymbol:runAction(mouseMove)
            performWithDelay(self,function (  )
                gLobalSoundManager:playSound("CatandMouseSounds/CatandMouse_caiquan_boom.mp3")
                collision:runCsbAction("actionframe")
            end,0.14)
        end
        performWithDelay(self,function (  )
            self:showSymbolOverAction(catSymbol,mouseSymbol)
        end,0.5)
        performWithDelay(self,function (  )
            collision:removeFromParent()
            local zOder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_BONUS)
            catSymbol:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - catSymbol.p_rowIndex)
            mouseSymbol:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - catSymbol.p_rowIndex)
            if func then
                func()
            end
        end,0.75)
    end,1/6)
    
end

function CodeGameScreenCatandMouseMachine:randomShowSound( )
    return math.random(1,2)
end

-- 7 5 3 1 2 4 6 播startzuo或者startyou是根据从哪个方向来的。例：1->2  1播switch2，2播startzuo
function CodeGameScreenCatandMouseMachine:changeCollectState(mouseProgress)
    if self.curCollectNum >= PROGRESS.BOTH_LEFT and self.curCollectNum <= PROGRESS.BOTH_RIGHT then      --均势
        if mouseProgress >= PROGRESS.MOUSE_LEFT and mouseProgress <= PROGRESS.MOUSE_RIGHT then --变为鼠的优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouseChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_ONE,UPPEOPLE_INDEX.INDEX_FOUR)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_TWO)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_TWO)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_TWO)
        elseif mouseProgress >= PROGRESS.CAT_LEFT and mouseProgress <= PROGRESS.CAT_RIGHT then   --变为猫的优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_catChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_ONE,UPPEOPLE_INDEX.INDEX_TWO)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_ONE)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_ONE)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_ONE)
        elseif mouseProgress >= PROGRESS.BIGCAT_lEFT and mouseProgress <= PROGRESS.BIGCAT_RIGHT then       --猫的大优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_catChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_ONE,UPPEOPLE_INDEX.INDEX_THREE)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_NICE)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_THREE)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_THREE)
        elseif mouseProgress >= PROGRESS.BIGMOUSE_LEFT and mouseProgress <= PROGRESS.BIGMOUSE_RIGHT then     --老鼠的大优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouseChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_ONE,UPPEOPLE_INDEX.INDEX_FIVE)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_TEN)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_FOUR)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_FOUR)
        end
    elseif self.curCollectNum >= PROGRESS.MOUSE_LEFT and self.curCollectNum <= PROGRESS.MOUSE_RIGHT then     --老鼠优势
        if mouseProgress >= PROGRESS.BOTH_LEFT and mouseProgress <= PROGRESS.BOTH_RIGHT then  --均势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_catChangeGood.mp3")
            
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_FOUR,UPPEOPLE_INDEX.INDEX_ONE)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_FIVE)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_FIVE)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_FIVE)
        elseif mouseProgress >= PROGRESS.BIGMOUSE_LEFT and mouseProgress <= PROGRESS.BIGMOUSE_RIGHT then     --老鼠的大优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouseChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_FOUR,UPPEOPLE_INDEX.INDEX_FIVE)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_SIX)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_FOUR)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_SIX)
        elseif mouseProgress >= PROGRESS.CAT_LEFT and mouseProgress <= PROGRESS.CAT_RIGHT then       --猫的优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_catChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_FOUR,UPPEOPLE_INDEX.INDEX_TWO)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_FOURTEEN)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_THIRTEEN)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_SEVEN)
        elseif mouseProgress >= PROGRESS.MOUSE_FREE then --触发
            self.freeRenWuCollrctNum = FREESHOWUPNUM.MOUSE
        end
    elseif self.curCollectNum >= PROGRESS.BIGMOUSE_LEFT and self.curCollectNum <= PROGRESS.BIGMOUSE_RIGHT then     --老鼠大优势
        if mouseProgress >= PROGRESS.MOUSE_LEFT and mouseProgress <= PROGRESS.MOUSE_RIGHT then     --老鼠的优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_catChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_FIVE,UPPEOPLE_INDEX.INDEX_FOUR)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_EIGHT)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_EIGHT)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_EIGHT)
        elseif mouseProgress >= PROGRESS.BOTH_LEFT and mouseProgress <= PROGRESS.BOTH_RIGHT then  --均势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_catChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_FIVE,UPPEOPLE_INDEX.INDEX_ONE)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_TWELVE)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_ELEVEN)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_NICE)
        elseif mouseProgress >= PROGRESS.MOUSE_FREE then --触发
            self.freeRenWuCollrctNum = FREESHOWUPNUM.BIG_MOUSE
        end
    elseif self.curCollectNum >= PROGRESS.CAT_LEFT and self.curCollectNum <= PROGRESS.CAT_RIGHT then     --猫优势
        if mouseProgress >= PROGRESS.BOTH_LEFT and mouseProgress <= PROGRESS.BOTH_RIGHT then      --均势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouseChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_TWO,UPPEOPLE_INDEX.INDEX_ONE)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_THREE)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_SIX)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_TEN)
        elseif mouseProgress >= PROGRESS.BIGCAT_lEFT and mouseProgress <= PROGRESS.BIGCAT_RIGHT then   --猫的大优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_catChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_TWO,UPPEOPLE_INDEX.INDEX_THREE)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_FOUR)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_THREE)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_ELEVEN)
        elseif mouseProgress >= PROGRESS.MOUSE_LEFT and mouseProgress <= PROGRESS.MOUSE_RIGHT then --老鼠的优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouseChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_TWO,UPPEOPLE_INDEX.INDEX_FOUR)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_THIRTEEN)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_TWELVE)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_TWELVE)
        elseif mouseProgress <= PROGRESS.CAT_FREE then  --触发
            self.freeRenWuCollrctNum = FREESHOWUPNUM.CAT
        end
    elseif self.curCollectNum >= PROGRESS.BIGCAT_lEFT and self.curCollectNum <= PROGRESS.BIGCAT_RIGHT then     --猫大优势
        if mouseProgress >= PROGRESS.CAT_LEFT and mouseProgress <= PROGRESS.CAT_RIGHT then   --猫的优势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouseChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_THREE,UPPEOPLE_INDEX.INDEX_TWO)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_SEVEN)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_SEVEN)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_THIRTEEN)
        elseif mouseProgress >= PROGRESS.BOTH_LEFT and mouseProgress <= PROGRESS.BOTH_RIGHT then  --均势
            gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouseChangeGood.mp3")
            self:setUpRenWuVisible(UPPEOPLE_INDEX.INDEX_ONE,UPPEOPLE_INDEX.INDEX_TWO)
            self:lastUpCatAndMouse(UPPEOPLE_INDEX.INDEX_ELEVEN)
            self:changeUpCatAndMouse(UPPEOPLE_INDEX.INDEX_TEN)
            self:changeUpBg(UPPEOPLE_INDEX.INDEX_FOURTEEN)
        elseif mouseProgress <= PROGRESS.CAT_FREE then  --触发
            self.freeRenWuCollrctNum = FREESHOWUPNUM.BIG_CAT
        end
    
    end
    
    self.curCollectNum = mouseProgress
end

--更新进度条数量
function CodeGameScreenCatandMouseMachine:updateCollectEffect(isUpdate,func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --猫图标的位置
    local collect = selfData.CatandMouseCollect or {}
    local catProgress = collect.CatCollectProgress or 18

    local mouseProgress = collect.MouseCollectProgress or 18
    
    if isUpdate then
        self:showSymbolEffect(function (  )
                self.node5:stopAllActions()
                performWithDelay(self.node5,function (  )
                    self.collectBar:updataProgress(catProgress,mouseProgress,isUpdate)
                end,self.collectWaitTime + 0.5)
            
            local changeNum = math.abs(mouseProgress - self.curCollectNum)
            performWithDelay(self.node5,function (  )
                -- --根据收集数量的不同改变上方人物
                self:changeCollectState(mouseProgress)
            end,self.collectWaitTime + 0.5 + changeNum * 0.05)
            if mouseProgress >= PROGRESS.MOUSE_FREE or mouseProgress <= PROGRESS.CAT_FREE then
                performWithDelay(self,function (  )
                    if func then
                        func()
                    end
                end,2)
            else
                if func then
                    func()
                end
            end
            
        end)
    else
        self:changeCollectUpBgAndRemWu(mouseProgress)
        
        self.collectBar:updataProgress(catProgress,mouseProgress,isUpdate)
        self.curCollectNum = mouseProgress
        if func then
            func()
        end
    end
    --背景火
    if mouseProgress > PROGRESS.BIGMOUSE_LEFT then
        self.bgFire:setVisible(true)
        self.bgFire:runCsbAction("actionframe2",true)
    elseif mouseProgress <  PROGRESS.BIGCAT_RIGHT then
        self.bgFire:setVisible(true)
        self.bgFire:runCsbAction("actionframe1",true)
    else
        self.bgFire:setVisible(false)
    end
end

--立即改变上方人物和背景（用于进入游戏和切换bet）
function CodeGameScreenCatandMouseMachine:changeCollectUpBgAndRemWu(mouseProgress)
    self.isResetSoundId = true
    --根据收集数量的不同改变上方人物
    if mouseProgress >= PROGRESS.BOTH_LEFT and mouseProgress <= PROGRESS.BOTH_RIGHT then      --均势
        self:showSoundForIdle(true,FREESHOWUPNUM.BALANCE,false)
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_ONE,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_ONE)
    elseif mouseProgress >= PROGRESS.MOUSE_LEFT and mouseProgress <= PROGRESS.MOUSE_RIGHT then     --老鼠优势
        self:showSoundForIdle(true,FREESHOWUPNUM.MOUSE,false)
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_FOUR,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_THREE)
        self.freeRenWuCollrctNum = FREESHOWUPNUM.MOUSE
    elseif mouseProgress >= PROGRESS.BIGMOUSE_LEFT and mouseProgress <= PROGRESS.BIGMOUSE_RIGHT then     --老鼠大优势
        self:showSoundForIdle(true,FREESHOWUPNUM.BIG_MOUSE,false)
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_FIVE,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_FIVE)
    elseif mouseProgress >= PROGRESS.CAT_LEFT and mouseProgress <= PROGRESS.CAT_RIGHT then     --猫优势
        self:showSoundForIdle(true,FREESHOWUPNUM.CAT,false)
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_TWO,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_TWO)
    elseif mouseProgress >= PROGRESS.BIGCAT_lEFT and mouseProgress <= PROGRESS.BIGCAT_RIGHT then     --猫大优势
        self:showSoundForIdle(true,FREESHOWUPNUM.BIG_CAT,false)
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_THREE,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_FOUR)
        self.freeRenWuCollrctNum = FREESHOWUPNUM.BIG_CAT
    elseif mouseProgress <= PROGRESS.CAT_FREE then
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_THREE,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_FOUR)
        self.freeRenWuCollrctNum = FREESHOWUPNUM.BIG_CAT
    elseif mouseProgress >= PROGRESS.MOUSE_FREE then
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_FIVE,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_FIVE)
        self.freeRenWuCollrctNum = FREESHOWUPNUM.BIG_MOUSE
    else
        self:getShowUpRenWu(UPPEOPLE_INDEX.INDEX_ONE,true)
        self:setShowUpBg(UPPEOPLE_INDEX.INDEX_ONE)
    end
end

--1和2位均势的下一阶段，3和4位猫优势的下一次，5和6为鼠优势的下一阶段，7和8为猫和老鼠大优势的下一次
function CodeGameScreenCatandMouseMachine:lastUpCatAndMouse(index)
    self.node2:stopAllActions()
    if index == UPPEOPLE_INDEX.INDEX_ONE then
        -- self:getShowUpRenWu(1)
        self.renWu1:setLocalZOrder(10)
        util_spinePlay(self.renWu1,"switch2",false)
        performWithDelay(self.node2,function (  )
            self.renWu1:setLocalZOrder(1)
            self.renWu1:setVisible(false)
        end,1.5)
        -- util_spineEndCallFunc(self.renWu1,"switch2",function (  )
            
        -- end)
    elseif index == UPPEOPLE_INDEX.INDEX_TWO then
        self.renWu1:setLocalZOrder(10)
        util_spinePlay(self.renWu1,"switch3",false)
        performWithDelay(self.node2,function (  )
            self.renWu1:setLocalZOrder(1)
            self.renWu1:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_THREE then
        self.renWu2:setLocalZOrder(10)
        util_spinePlay(self.renWu2,"switch1",false)
        performWithDelay(self.node2,function (  )
            self.renWu2:setLocalZOrder(2)
            self.renWu2:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FOUR then
        self.renWu2:setLocalZOrder(10)
        util_spinePlay(self.renWu2,"switch4",false)
        performWithDelay(self.node2,function (  )
            self.renWu2:setLocalZOrder(2)
            self.renWu2:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FIVE then
        self.renWu4:setLocalZOrder(10)
        util_spinePlay(self.renWu4,"switch1",false)
        performWithDelay(self.node2,function (  )
            self.renWu4:setLocalZOrder(4)
            self.renWu4:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_SIX then
        self.renWu4:setLocalZOrder(10)
        util_spinePlay(self.renWu4,"switch5",false)
        performWithDelay(self.node2,function (  )
            self.renWu4:setLocalZOrder(4)
            self.renWu4:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_SEVEN then
        self.renWu3:setLocalZOrder(10)
        util_spinePlay(self.renWu3,"switch2",false)
        performWithDelay(self.node2,function (  )
            self.renWu3:setLocalZOrder(3)
            self.renWu3:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_EIGHT then
        self.renWu5:setLocalZOrder(10)
        util_spinePlay(self.renWu5,"switch3",false)
        performWithDelay(self.node2,function (  )
            self.renWu5:setLocalZOrder(5)
            self.renWu5:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_NICE then
        self.renWu1:setLocalZOrder(10)
        util_spinePlay(self.renWu1,"switch4",false)
        performWithDelay(self.node2,function (  )
            self.renWu1:setLocalZOrder(1)
            self.renWu1:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TEN then
        self.renWu1:setLocalZOrder(10)
        util_spinePlay(self.renWu1,"switch5",false)
        performWithDelay(self.node2,function (  )
            self.renWu1:setLocalZOrder(1)
            self.renWu1:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_ELEVEN then
        self.renWu3:setLocalZOrder(10)
        util_spinePlay(self.renWu3,"switch1",false)
        performWithDelay(self.node2,function (  )
            self.renWu3:setLocalZOrder(1)
            self.renWu3:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TWELVE then
        self.renWu5:setLocalZOrder(10)
        util_spinePlay(self.renWu5,"switch1",false)
        performWithDelay(self.node2,function (  )
            self.renWu5:setLocalZOrder(5)
            self.renWu5:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_THIRTEEN then
        self.renWu2:setLocalZOrder(10)
        util_spinePlay(self.renWu2,"switch3",false)
        performWithDelay(self.node2,function (  )
            self.renWu2:setLocalZOrder(2)
            self.renWu2:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FOURTEEN then
        self.renWu4:setLocalZOrder(10)
        util_spinePlay(self.renWu4,"switch2",false)
        performWithDelay(self.node2,function (  )
            self.renWu4:setLocalZOrder(4)
            self.renWu4:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FIFTEEN then
        self.renWu4:setLocalZOrder(10)
        util_spinePlay(self.renWu4,"switch7",false)
        performWithDelay(self.node2,function (  )
            self.renWu4:setLocalZOrder(4)
            self.renWu4:setVisible(false)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_SIXTEEN then
        self.renWu2:setLocalZOrder(10)
        util_spinePlay(self.renWu2,"switch6",false)
        performWithDelay(self.node2,function (  )
            self.renWu2:setLocalZOrder(2)
            self.renWu2:setVisible(false)
        end,1.5)
    end
end

function CodeGameScreenCatandMouseMachine:getSoundPath(index)
    if index == FREESHOWUPNUM.CAT then
        return "CatandMouseSounds/music_CatandMouse_custom_cat_small.mp3"
    elseif index == FREESHOWUPNUM.MOUSE then
        return "CatandMouseSounds/music_CatandMouse_custom_mouse_small.mp3"
    elseif index == FREESHOWUPNUM.BIG_CAT then
        return "CatandMouseSounds/music_CatandMouse_custom_cat_big.mp3"
    elseif index == FREESHOWUPNUM.BIG_MOUSE then
        return "CatandMouseSounds/music_CatandMouse_custom_mouse_big.mp3"
    elseif index == FREESHOWUPNUM.BALANCE then
        if self:randomShowSound() == 1 then
            return "CatandMouseSounds/music_CatandMouse_custom_balance1.mp3"
        else
            return "CatandMouseSounds/music_CatandMouse_custom_balance2.mp3"
        end
    end
    return "CatandMouseSounds/music_CatandMouse_custom_balance1.mp3"
end

function CodeGameScreenCatandMouseMachine:showSoundForIdle(isEnter,index,isStop)
    if isStop then
        self.soundNode:stopAllActions()
        if self.soundIdForIdle ~= nil then
            gLobalSoundManager:stopAudio(self.soundIdForIdle)
            self.soundIdForIdle = nil
        end
    else
        if isEnter then
            self.soundIndexForIdle = index
        else
            if index and index ~= nil then
                self.soundIndexForIdle = index
                self.soundNode:stopAllActions()
                if self.soundIdForIdle ~= nil then
                    gLobalSoundManager:stopAudio(self.soundIdForIdle)
                    self.soundIdForIdle = nil
                end
                self.soundIdForIdle = gLobalSoundManager:playSound(self:getSoundPath(index))
            else
                self.soundIdForIdle = gLobalSoundManager:playSound(self:getSoundPath(self.soundIndexForIdle))
            end
            performWithDelay(self.soundNode,function(  )
                self:showSoundForIdle()
            end,10)
        end
    end
    
end
--1为均势变成猫优势，2为均势变为老鼠优势，3为猫优势变为大优势，4为老鼠优势变为大优势，5为猫的优势变为均势，
--6为老鼠的优势变为均势，7为猫的大优势变为优势，8为老鼠的大优势变为优势，9为老鼠的优势变为猫的优势，10为猫的优势变为老鼠的优势
--11为均势变为老鼠的大优势，12为均势变为猫的大优势
function CodeGameScreenCatandMouseMachine:changeUpCatAndMouse(index)
    self.node1:stopAllActions()
    if index == UPPEOPLE_INDEX.INDEX_ONE then
        self.renWu2:setVisible(true)
        util_spinePlay(self.renWu2,"startzuo",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.CAT)
            util_spinePlay(self.renWu2,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TWO then
        self.renWu4:setVisible(true)
        util_spinePlay(self.renWu4,"startyou",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.MOUSE)
            util_spinePlay(self.renWu4,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_THREE then
        self.renWu3:setVisible(true)
        util_spinePlay(self.renWu3,"start",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.BIG_CAT)
            util_spinePlay(self.renWu3,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FOUR then
        self.renWu5:setVisible(true)
        util_spinePlay(self.renWu5,"start",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.BIG_MOUSE)
            util_spinePlay(self.renWu5,"idleframe",true)
        end,1.5)

    elseif index == UPPEOPLE_INDEX.INDEX_FIVE then
        self.renWu1:setVisible(true)
        util_spinePlay(self.renWu1,"startzuo",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.BALANCE)
            util_spinePlay(self.renWu1,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_SIX then
        self.renWu1:setVisible(true)
        util_spinePlay(self.renWu1,"startyou",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.BALANCE)
            util_spinePlay(self.renWu1,"idleframe",true)
        end,1.5)

    elseif index == UPPEOPLE_INDEX.INDEX_SEVEN then
        self.renWu2:setVisible(true)
        util_spinePlay(self.renWu2,"startyou",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.CAT)
            util_spinePlay(self.renWu2,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_EIGHT then
        self.renWu4:setVisible(true)
        util_spinePlay(self.renWu4,"startzuo",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.MOUSE)
            util_spinePlay(self.renWu4,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_NICE then
        self.renWu3:setVisible(true)
        util_spinePlay(self.renWu3,"start",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.MOUSE)
            util_spinePlay(self.renWu3,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TEN then
        self.renWu1:setVisible(true)
        util_spinePlay(self.renWu1,"startyou4",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.BALANCE)
            util_spinePlay(self.renWu1,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_ELEVEN then
        self.renWu1:setVisible(true)
        util_spinePlay(self.renWu1,"startzuo5",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.BALANCE)
            util_spinePlay(self.renWu1,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TWELVE then
        self.renWu4:setVisible(true)
        util_spinePlay(self.renWu4,"startyou2",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.MOUSE)
            util_spinePlay(self.renWu4,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_THIRTEEN then
        self.renWu2:setVisible(true)
        util_spinePlay(self.renWu2,"startzuo3",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.CAT)
            util_spinePlay(self.renWu2,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FOURTEEN then
        self.renWu5:setVisible(true)
        util_spinePlay(self.renWu5,"switch7_2",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.BIG_MOUSE)
            util_spinePlay(self.renWu5,"idleframe",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FIFTEEN then
        self.renWu3:setVisible(true)
        util_spinePlay(self.renWu3,"switch6_2",false)
        performWithDelay(self.node1,function (  )
            self:showSoundForIdle(false,FREESHOWUPNUM.MOUSE)
            util_spinePlay(self.renWu3,"idleframe",true)
        end,1.5)
    end
end

function CodeGameScreenCatandMouseMachine:isShowLightingUp(isShow)
    if isShow then
        self.lightning:setVisible(false)
        self.lightningUp:setVisible(true)
    else
        self.lightning:setVisible(true)
        self.lightningUp:setVisible(false)
    end
end

function CodeGameScreenCatandMouseMachine:changeUpBg(index)
    gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_shandian_change.mp3")
    self.node4:stopAllActions()
    if index == UPPEOPLE_INDEX.INDEX_ONE then   --均势变猫优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"1to2",false)
        util_spinePlay(self.lightning,"1to2",false)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe2",true)
            util_spinePlay(self.lightning,"idleframe2",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TWO then   --均势变老鼠优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"1to3",false)
        util_spinePlay(self.lightning,"1to3",false)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe3",true)
            util_spinePlay(self.lightning,"idleframe3",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_THREE then --均势变猫大优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"1to4",false)
        util_spinePlay(self.lightning,"1to4",false)
        util_spinePlay(self.lightningUp,"1to4",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp(true)
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe4",true)
            util_spinePlay(self.lightningUp,"idleframe4",true)
        end,1.5)

    elseif index == UPPEOPLE_INDEX.INDEX_FOUR then  --均势变老鼠大优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"1to5",false)
        util_spinePlay(self.lightning,"1to5",false)
        util_spinePlay(self.lightningUp,"1to5",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp(true)
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe5",true)
            util_spinePlay(self.lightningUp,"idleframe5",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FIVE then  --老鼠优势变均势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"3to1",false)
        util_spinePlay(self.lightning,"3to1",false)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe1",true)
            util_spinePlay(self.lightning,"idleframe1",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_SIX then   --老鼠优势变老鼠大优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"3to5",false)
        util_spinePlay(self.lightning,"3to5",false)
        util_spinePlay(self.lightningUp,"3to5",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp(true)
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe5",true)
            util_spinePlay(self.lightningUp,"idleframe5",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_SEVEN then --老鼠优势变猫优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"3to2",false)
        util_spinePlay(self.lightning,"3to2",false)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe2",true)
            util_spinePlay(self.lightning,"idleframe2",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_EIGHT then --老鼠大优势变老鼠优势
        self:isShowLightingUp(true)
        util_spinePlay(self.upBg,"5to3",false)
        util_spinePlay(self.lightning,"5to3",false)
        util_spinePlay(self.lightningUp,"5to3",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp()
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe3",true)
            util_spinePlay(self.lightning,"idleframe3",true)
        end,1.5)

    elseif index == UPPEOPLE_INDEX.INDEX_NICE then  --老鼠大优势变均势
        self:isShowLightingUp(true)
        util_spinePlay(self.upBg,"5to1",false)
        util_spinePlay(self.lightning,"5to1",false)
        util_spinePlay(self.lightningUp,"5to1",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp()
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe1",true)
            util_spinePlay(self.lightning,"idleframe1",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TEN then   --猫优势变均势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"2to1",false)
        util_spinePlay(self.lightning,"2to1",false)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe1",true)
            util_spinePlay(self.lightning,"idleframe1",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_ELEVEN then    --猫优势变猫大优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"2to4",false)
        util_spinePlay(self.lightning,"2to4",false)
        util_spinePlay(self.lightningUp,"2to4",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp(true)
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe4",true)
            util_spinePlay(self.lightningUp,"idleframe4",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_TWELVE then    --猫优势变老鼠优势
        self:isShowLightingUp()
        util_spinePlay(self.upBg,"2to3",false)
        util_spinePlay(self.lightning,"2to3",false)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe3",true)
            util_spinePlay(self.lightning,"idleframe3",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_THIRTEEN then  --猫大优势变猫优势
        self:isShowLightingUp(true)
        util_spinePlay(self.upBg,"4to2",false)
        util_spinePlay(self.lightning,"4to2",false)
        util_spinePlay(self.lightningUp,"4to2",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp()
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe2",true)
            util_spinePlay(self.lightning,"idleframe2",true)
        end,1.5)
    elseif index == UPPEOPLE_INDEX.INDEX_FOURTEEN then  --猫大优势变均势
        self:isShowLightingUp(true)
        util_spinePlay(self.upBg,"4to1",false)
        util_spinePlay(self.lightning,"4to1",false)
        util_spinePlay(self.lightningUp,"4to1",false)
        performWithDelay(self.node4,function (  )
            self:isShowLightingUp()
        end,16/30)
        performWithDelay(self.node4,function (  )
            util_spinePlay(self.upBg,"idleframe1",true)
            util_spinePlay(self.lightning,"idleframe1",true)
        end,1.5)
    end
end

-- ---------------------------收集玩法end------------------

-- ---------------------------猫、老鼠玩法start------------------
--每次spin会标记一个格子，若停轮后该格子中出现对方的图标或wild，则轮盘中增加一定数量的wild
function CodeGameScreenCatandMouseMachine:catWinEffect(func)
    self:changeSymbolToWild(function (  )
        if func then
            func()
        end
    end)
end

--每次spin标记5个格子，若停轮后格子中出现对方图标，则每个出现对方图标的格子都变成wild
function CodeGameScreenCatandMouseMachine:mouseWinEffect(func)
    self:changeSymbolToWild(function (  )
        if func then
            func()
        end
    end)
end

function CodeGameScreenCatandMouseMachine:mouseIsLock()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeKind = selfData.freeKind
    local wildPosition = {}
    if freeKind and freeKind == "MOUSE" then
        local mouseFreespin = selfData.MouseFreespin
        wildPosition = mouseFreespin.MouseWildPosition
    end
    for i,v in ipairs(wildPosition) do
        for j,node in ipairs(self.m_storageMark) do
            local fixPos = self:getRowAndColByPos(v)
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if node.pos == v then
                if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 
                    or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 
                        or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
                    return true
                end
            end
        end
    end
    return false
end

--猫和鼠玩法中是否有锁定标记（变wild位置是否有对方图标）
function CodeGameScreenCatandMouseMachine:ishaveCatLock(posIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeKind = selfData.freeKind
    local wildPosition = {}
    if freeKind and freeKind == "CAT" then
        local catFreespin = selfData.CatFreespin
        wildPosition = catFreespin.CatWildPosition
    end
    for i,v in ipairs(wildPosition) do
        local fixPos = self:getRowAndColByPos(v)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if posIndex == v then
            if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 
                or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 
                    or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 
                        or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                return true
            end
        end
    end
    return false
end

--猫和鼠玩法中是否有锁定标记（变wild位置是否有对方图标）
function CodeGameScreenCatandMouseMachine:ishaveMouseLock(posIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeKind = selfData.freeKind
    local wildPosition = {}
    if freeKind and freeKind == "MOUSE" then
        local mouseFreespin = selfData.MouseFreespin
        wildPosition = mouseFreespin.MouseWildPosition
    end
    for i,v in ipairs(wildPosition) do
        local fixPos = self:getRowAndColByPos(v)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if tonumber(posIndex) == v then
            if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 
                or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 
                    or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenCatandMouseMachine:showLightSymbol(posIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeKind = selfData.freeKind
    local wildPosition = {}
    if freeKind and freeKind == "CAT" then
        local catFreespin = selfData.CatFreespin
        wildPosition = catFreespin.CatWildPosition
    elseif freeKind and freeKind == "MOUSE" then
        local mouseFreespin = selfData.MouseFreespin
        wildPosition = mouseFreespin.MouseWildPosition
    end
    for i,v in ipairs(wildPosition) do
        local fixPos = self:getRowAndColByPos(v)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local pos = util_convertToNodeSpace(targSp,self:findChild("mask"))
        if posIndex == v then
            local tempSymbol = self:createLightSymbol(targSp.p_symbolType)
            if tempSymbol ~= nil then
                if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    self.lockIsWild = true
                    self:findChild("mask"):addChild(tempSymbol,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
                    tempSymbol:setPosition(pos)
                    table.insert( self.m_tempLightSymbol, tempSymbol )
                else
                    self:findChild("mask"):addChild(tempSymbol,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
                    local tempWild = util_spineCreate("Socre_CatandMouse_Wild",true,true)
                    self:findChild("mask"):addChild(tempWild,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 6)
                    tempWild:setPosition(pos)
                    tempSymbol:setPosition(pos)
                    tempWild:setVisible(false)
                    table.insert( self.m_tempLightSymbol, tempSymbol )
                    table.insert( self.m_tempWildSymbol, tempWild )
                end
                
            end
        end
    end
end

function CodeGameScreenCatandMouseMachine:createLightSymbol(symbolType)

    local tempSymbol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        tempSymbol = util_spineCreate("Socre_CatandMouse_9",true,true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        tempSymbol = util_spineCreate("Socre_CatandMouse_7",true,true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        tempSymbol = util_spineCreate("Socre_CatandMouse_5",true,true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        tempSymbol = util_spineCreate("Socre_CatandMouse_8",true,true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        tempSymbol = util_spineCreate("Socre_CatandMouse_6",true,true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
        tempSymbol = util_spineCreate("Socre_CatandMouse_4",true,true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        tempSymbol = util_spineCreate("Socre_CatandMouse_Wild",true,true)
    end
    return tempSymbol
end

function CodeGameScreenCatandMouseMachine:lightSymbolChangeWild()
    if self.lockIsWild then

    else
        for i,v in ipairs(self.m_tempLightSymbol) do
            util_spinePlay(v,"actionframe3",false)
            self.m_tempWildSymbol[i]:setVisible(true)
            util_spinePlay(self.m_tempWildSymbol[i],"actionframe3",false)
        end
    end
    
end

function CodeGameScreenCatandMouseMachine:addWildPosSort(list,pos)
    local tempList = {}
    for i,v in ipairs(list) do
        if v == pos then
            
        else
            table.insert( tempList, v )
        end
    end
    --从左到右排序 从上到下
    table.sort(
        tempList,
        function(a, b)
            local pos1 = self:getRowAndColByPos(a)
            local pos2 = self:getRowAndColByPos(b)

            if pos1.iY ~= pos2.iY then
                return pos1.iY < pos2.iY
            else
                return pos1.iX < pos2.iX
            end
        end
    )
    return tempList
end

function CodeGameScreenCatandMouseMachine:createCatWild(pos)
    local wildBd = util_createAnimation("CatandMouse_addwild_bd.csb")
    local tempSymbol = self:createLightSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    self:findChild("mask"):addChild(wildBd,10)
    self:findChild("mask"):addChild(tempSymbol,5)
    wildBd:setPosition(pos)
    tempSymbol:setPosition(pos)
    table.insert(self.m_tempWildSymbol,tempSymbol)
    gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_cat_changeWild.mp3")
    wildBd:runCsbAction("actionframe",false,function (  )
        wildBd:removeFromParent()
    end)
    util_spinePlay(tempSymbol,"actionframe3",false)
end

function CodeGameScreenCatandMouseMachine:addWildToMark(pos)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildPosition = {}
    local catFreespin = selfData.CatFreespin
    wildPosition = catFreespin.CatWildPosition
    local fixPos1 = self:getRowAndColByPos(pos)
    local targSp1 = self:getFixSymbol(fixPos1.iY, fixPos1.iX, SYMBOL_NODE_TAG)
    local startPos = util_convertToNodeSpace(targSp1,self:findChild("mask"))
    local wildPosList = self:addWildPosSort(wildPosition,pos)
    if targSp1.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
        targSp1:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
    end 
    for k, v in pairs(wildPosList) do
        local posIndex = v
        local fixPos = self:getRowAndColByPos(posIndex)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local endPos = util_convertToNodeSpace(targSp,self:findChild("mask"))
        performWithDelay(
            self,
            function()
                --播放闪电粒子
                self:flyAddWildShow(
                    startPos,
                    endPos,
                    function()
                        --在mark上创建爆点和wild出现
                        self:createCatWild(endPos)
                        performWithDelay(self,function (  )
                            if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                            end 
                        end,0.3)
                    end
                )
            end,
            0.1 * (k - 1)
        )
    end
end

function CodeGameScreenCatandMouseMachine:clearAllLightSymbol( )
    for i,v in ipairs(self.m_tempLightSymbol) do
        v:removeFromParent()
        
    end
    for i,v in ipairs(self.m_tempWildSymbol) do
        v:removeFromParent()
    end
    -- self:findChild("mask"):removeAllChildren()
    self.m_tempWildSymbol = {}
    self.m_tempLightSymbol = {}
end

--将服务器下发位置的小块变成wild
function CodeGameScreenCatandMouseMachine:changeSymbolToWild(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeKind = selfData.freeKind
    local wildPosition = {}
    if freeKind and freeKind == "CAT" then
        
        local catFreespin = selfData.CatFreespin
        wildPosition = catFreespin.CatWildPosition
        if self.m_storageMark[1] ~= nil then
            local node = self.m_storageMark[1]
            if self:ishaveCatLock(node.pos) then
                --压黑
                self.mask:setVisible(true)
                --创建高亮图标
                self:showLightSymbol(node.pos)
                self.mask:runCsbAction("actionframe",false,function (  )
                    self.mask:runCsbAction("idleframe")
                end)
                gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_cat_lock.mp3")
                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                local actList = {}
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    node:runCsbAction("actionframe1",false)
                end)
                actList[#actList + 1] = cc.DelayTime:create(45/60)
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    node:runCsbAction("idleframe1",true)
                    if self.bonusRenWu then
                        gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_cat_changewild_showRenwu.mp3")
                        self.bonusRenWu:showChangeWildSpine()
                    end
                end)
                actList[#actList + 1] = cc.DelayTime:create(0.7)
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    node:runCsbAction("over1",false)
                end)
                actList[#actList + 1] = cc.DelayTime:create(15/60)
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    
                    self:lightSymbolChangeWild()
                end)
                actList[#actList + 1] = cc.DelayTime:create(0.1)
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    self:addWildToMark(node.pos)
                end)
                actList[#actList + 1] = cc.DelayTime:create(#wildPosition * 0.3)
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    self.bonusRenWu:showOverSpin()
                    
                    self.lockIsWild = false
                    self.mask:setVisible(false)
                    self:clearAllLightSymbol()
                    
                    self:runCsbAction("actionframe1")
                end)
                actList[#actList + 1] = cc.DelayTime:create(0.5)
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    if func then
                        func()
                    end
                    waitNode:removeFromParent()
                end)
                local sq = cc.Sequence:create(actList)
                waitNode:runAction(sq)
            else
                node:runCsbAction("actionframe2",false,function (  )
                    node:runCsbAction("over2")
                end)
                performWithDelay(self,function (  )
                    self.bonusRenWu:showOverSpin()
                    self:runCsbAction("actionframe1")
                    performWithDelay(self,function (  )
                        if func then
                            func()
                        end
                    end,0.5)
                end,1.5)
            end
        end
    elseif freeKind and freeKind == "MOUSE" then
        local mouseFreespin = selfData.MouseFreespin
        wildPosition = mouseFreespin.MouseWildPosition
        --如果标记列表中有对方图标
        if self:mouseIsLock() then
            self.mask:setVisible(true)
            self.mask:runCsbAction("actionframe",false,function (  )
                self.mask:runCsbAction("idleframe")
            end)
            for j,node in ipairs(self.m_storageMark) do
                if self:ishaveMouseLock(node.pos)then
                    --创建高亮图标
                    self:showLightSymbol(node.pos)
                    gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouse_lock.mp3")
                    node:runCsbAction("actionframe1",false,function (  )
                        node:runCsbAction("idleframe1")
                    end)
                else
                    node:runCsbAction("actionframe2",false,function (  )
                        node:runCsbAction("idleframe2")
                    end)
                    
                end
            end
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            local actList = {}
            actList[#actList + 1] = cc.DelayTime:create(45/60)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                if self.bonusRenWu then
                    gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouse_changewild_showRenwu.mp3")
                    self.bonusRenWu:showChangeWildSpine()
                end
            end)
            actList[#actList + 1] = cc.DelayTime:create(1)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                for j,node in ipairs(self.m_storageMark) do
                    if self:ishaveMouseLock(node.pos)then
                        node:runCsbAction("over1")
                    else
                        node:runCsbAction("over2")
                    end
                end
            end)
            actList[#actList + 1] = cc.DelayTime:create(15/60)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouse_changeWild.mp3")
                self:lightSymbolChangeWild()
            end)
            actList[#actList + 1] = cc.DelayTime:create(0.5)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                for i,v in ipairs(wildPosition) do
                    local fixPos = self:getRowAndColByPos(v)
                    local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    end  
                end
                self:clearAllLightSymbol()
                self.mask:setVisible(false)
            end)
            actList[#actList + 1] = cc.DelayTime:create(0.1)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                
                self.bonusRenWu:showOverSpin()
                self:runCsbAction("actionframe1")
            end)
            actList[#actList + 1] = cc.DelayTime:create(0.5)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                if func then
                    func()
                end
                waitNode:removeFromParent()
            end)
            local sq = cc.Sequence:create(actList)
            waitNode:runAction(sq)
        else
            --如果没有固定的标记，则消失
            for i,v in ipairs(self.m_storageMark) do
                v:runCsbAction("actionframe2",false,function (  )
                    v:runCsbAction("over2")
                end)
            end
            performWithDelay(self,function (  )
                self.bonusRenWu:showOverSpin()
                self:runCsbAction("actionframe1")
                performWithDelay(self,function (  )
                    if func then
                        func()
                    end
                end,0.5)
            end,1.5)
        end
        
    end

    
end

--在停轮前设置一个标志
function CodeGameScreenCatandMouseMachine:setMarkToReel(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local choosePosition = {}
    local freeKind = selfData.freeKind
    self.bonusRenWu = nil
    if freeKind and freeKind == "CAT" then

        self.bonusRenWu = util_createView("CodeCatandMouseSrc.CatandMouseFreeCatAndMouseView",freeKind)

        self:findChild("Node_bonusrenwu"):addChild(self.bonusRenWu)
        local catFreespin = selfData.CatFreespin
        choosePosition = catFreespin.CatChoosePosition
        local pos = self:getRowAndColByPos(choosePosition[1])
        local col = pos.iY
        self.bonusRenWu:getSpinePosition(col)       --根据标记的位置修改猫出来的方向
    elseif freeKind and freeKind == "MOUSE" then
        self.bonusRenWu = util_createView("CodeCatandMouseSrc.CatandMouseFreeCatAndMouseView",freeKind)

        self:findChild("Node_bonusrenwu"):addChild(self.bonusRenWu)
        
        local mouseFreespin = selfData.MouseFreespin
        choosePosition = mouseFreespin.MouseChoosePosition
    end
    --人物出现动画
    self:runCsbAction("actionframe")
    if self.bonusRenWu ~= nil then
        if freeKind and freeKind == "CAT" then
            if self:randomShowSound() == 1 then
                gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_cat_addMark.mp3")
            else
                gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_cat_addMark2.mp3")
            end
        elseif freeKind and freeKind == "MOUSE" then
            if self:randomShowSound() == 1 then
                gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouse_addMark.mp3")
            else
                gLobalSoundManager:playSound("CatandMouseSounds/music_CatandMouse_custom_mouse_addMark2.mp3")
            end
            
        end
        
        self.bonusRenWu:showSpineAct(function (  )
            for i,v in ipairs(choosePosition) do
                --获得节点的轮盘对应位置
                local pos = util_getOneGameReelsTarSpPos(self,v)
                local mark = util_createAnimation("CatandMouse_bonus_biaoji_1.csb")
                if freeKind and freeKind == "MOUSE" then
                    mark = util_createAnimation("CatandMouse_bonus_biaoji.csb")
                end
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                local newPos = self:findChild("mask"):convertToNodeSpace(worldPos)
                self:findChild("mask"):addChild(mark,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
                mark:setPosition(newPos)
                mark.pos = v
                table.insert(self.m_storageMark,mark)
                mark:runCsbAction("start",false,function (  )
                    mark:runCsbAction("actionframe")
                end)
            end
            performWithDelay(self,function (  )
                if func then
                    func()
                end
            end,85/60)
        end)
    end
end

function CodeGameScreenCatandMouseMachine:resetStorageMark( )
    for i,v in ipairs(self.m_storageMark) do
        v:removeFromParent()
    end
    self.m_storageMark = {}
end
-- ---------------------------猫、老鼠玩法结束-----------------------------------

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCatandMouseMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        if self.isResetSoundId then
            self:showSoundForIdle()
            self.isResetSoundId = false
        end
    end
    
    self:showColorLayer( )

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:resetStorageMark()
    end
   
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCatandMouseMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collect = selfData.CatandMouseCollect
    local isUpdataCollect = 0
    if collect then
        isUpdataCollect = collect.OccurSignal or 0       --0和1为是否有收集
    end
    local catFree = selfData.CatFreespin or {}
    local catOccurSignal = catFree.CatOccurSignal or 0    --是否触发猫的玩法
    local mouseFree = selfData.MouseFreespin or {}
    local mouseOccurSignal = mouseFree.MouseOccurSignal or 0  --是否触发老鼠的玩法
    local battleWin = selfData.battleWin or 0       --pk的赢钱

    --在free情况下没有触发玩法，则将标记拿掉
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if catOccurSignal == 0 and mouseOccurSignal == 0 then
            self.bonusRenWu:showOverSpin()
            self:runCsbAction("actionframe1")
            for i,v in ipairs(self.m_storageMark) do
                v:runCsbAction("over2")
            end
        end
    end

    if catOccurSignal and catOccurSignal == 1 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.CAT_WIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CAT_WIN_EFFECT -- 动画类型
    elseif mouseOccurSignal and mouseOccurSignal == 1 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.MOUSE_WIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.MOUSE_WIN_EFFECT -- 动画类型
    elseif isUpdataCollect > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BETTLE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BETTLE_EFFECT -- 动画类型
    end
        

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCatandMouseMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.CAT_WIN_EFFECT then

        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:mouseWinEffect(function (  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.MOUSE_WIN_EFFECT then
        self:catWinEffect(function (  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_BETTLE_EFFECT then
        --触发收集时，先播石头剪刀布的效果
        self:updateCollectEffect(true,function (  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    end

    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCatandMouseMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenCatandMouseMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenCatandMouseMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenCatandMouseMachine:slotReelDown( )


    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenCatandMouseMachine.super.slotReelDown(self)
end

function CodeGameScreenCatandMouseMachine:beginReel()
    self.m_fsReelDataIndex = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeKind = selfData.freeKind or ""
    if freeKind == "CAT" then
        self.m_fsReelDataIndex = 0
    elseif freeKind == "MOUSE" then
        self.m_fsReelDataIndex = 1
    end

    CodeGameScreenCatandMouseMachine.super.beginReel(self)
end


function CodeGameScreenCatandMouseMachine:isSpecialNode(symbolType)

    if symbolType == self.SYMBOL_CAT_CLOTH 
        or symbolType == self.SYMBOL_CAT_STONE 
         or symbolType == self.SYMBOL_CAT_SCISSORS 
          or symbolType == self.SYMBOL_MOUSE_CLOTH 
           or symbolType == self.SYMBOL_MOUSE_STONE 
            or symbolType == self.SYMBOL_MOUSE_SCISSORS then
        
        return true
    end

    return false
end

function CodeGameScreenCatandMouseMachine:updateReelGridNode(symblNode)
    --如果是带钱的小块，更新钱数
    if self:isSpecialNode(symblNode.p_symbolType) then
        self:setSpecialNodeScore(self,{symblNode})
    end
end

function CodeGameScreenCatandMouseMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType or self:isSpecialNode(symbolNode.p_symbolType) == false then
        return
    end
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        if score ~= nil and type(score) ~= "string" then
            
            score = score * lineBet
            score = util_formatCoins(score, 3)
            symbolNode:getCcbProperty("m_lb_num"):setString(score)
            self:updateLabelSize({label = symbolNode:getCcbProperty("m_lb_num"),sx = 1,sy = 1},111)
        end

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                symbolNode:getCcbProperty("m_lb_num"):setString(score)
                self:updateLabelSize({label = symbolNode:getCcbProperty("m_lb_num"),sx = 1,sy = 1},111)
            end
        end
    end
end

--[[
    获取小块真实分数
]]
function CodeGameScreenCatandMouseMachine:getSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = 0
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end
    return score
end

function CodeGameScreenCatandMouseMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0

    if self:isSpecialNode(symbolType) then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end
    return score
end


--消息返回时判断是否播放锁定小块
function CodeGameScreenCatandMouseMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
       
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:setMarkToReel(function (  )    --free情况下在停轮之前增加标记
            self:produceSlots()         
            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData()  -- end
        end)
    else
        self:produceSlots()
        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()  -- end
    end
    
end


function CodeGameScreenCatandMouseMachine:MachineRule_afterNetWorkLineLogicCalculate()

    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

    self:updateBetNetCollectData()

    
end

function CodeGameScreenCatandMouseMachine:initGameStatusData(gameData)
    
    CodeGameScreenCatandMouseMachine.super.initGameStatusData(self,gameData)
    if gameData.gameConfig ~= nil and  gameData.gameConfig.bets ~= nil then
        self:initBetNetCollectData(gameData.gameConfig.bets)
    else
        self.m_betNetCollectData = {}
    end
     
end
function CodeGameScreenCatandMouseMachine:initBetNetCollectData(bets )
    if bets then
        self.m_betNetCollectData = bets
    end
end

function CodeGameScreenCatandMouseMachine:updateBetNetCollectData( )
    local selfdata =  self.m_runSpinResultData.p_selfMakeData
    if selfdata then
        local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
        local data =  self.m_betNetCollectData[tostring(totalBet)] 
        if data == nil then
            self.m_betNetCollectData[tostring(totalBet)] = {}
            data =  self.m_betNetCollectData[tostring(totalBet)]
        end
        if selfdata.CatandMouseCollect then
            data.occupyNum = {selfdata.CatandMouseCollect.CatCollectProgress,selfdata.CatandMouseCollect.MouseCollectProgress}
        end

    end
end

--切换bet刷新进度条
function CodeGameScreenCatandMouseMachine:changeBetUpdataCollect(totalBet)
    local curTotalBet = toLongNumber(totalBet)
    local data = self.m_betNetCollectData[tostring(curTotalBet)] 
    if data ~= nil then
        local catProgress = data.occupyNum[1] or 18

        local mouseProgress = data.occupyNum[2] or 18
        
        self:changeCollectUpBgAndRemWu(mouseProgress)
        self.collectBar:updataProgress(catProgress,mouseProgress,false)
        --背景火
        if mouseProgress >PROGRESS.BIGMOUSE_LEFT then
            self.bgFire:setVisible(true)
            self.bgFire:runCsbAction("actionframe2",true)
        elseif mouseProgress < PROGRESS.BIGCAT_RIGHT then
            self.bgFire:setVisible(true)
            self.bgFire:runCsbAction("actionframe1",true)
        else
            self.bgFire:setVisible(false)
        end
    else
        self:getShowUpRenWu(1,true)
        self:setShowUpBg(1)
        self.collectBar:updataProgress(18,18,false)
        self.bgFire:setVisible(false)
    end
    
end

function CodeGameScreenCatandMouseMachine:checkTowHaveBonus( )
    --获取停轮信号值
    local reels = self.m_runSpinResultData.p_reels or {}
    for i,v in ipairs(reels) do
        if v then
            for j,symbolType in ipairs(v) do
                if self:isSpecialNode(v[2]) then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenCatandMouseMachine:playCustomSpecialSymbolDownAct( slotNode )
    if self:checkTowHaveBonus() then
        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
            if slotNode and  self:isSpecialNode(slotNode.p_symbolType) then
                local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_BONUS,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    
                self:playScatterBonusSound(slotNode)
                symbolNode:runAnim("buling")
            end
        end
    end
end

function CodeGameScreenCatandMouseMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--设置bonus scatter 层级
function CodeGameScreenCatandMouseMachine:getBounsScatterDataZorder(symbolType )
    local order =  CodeGameScreenCatandMouseMachine.super.getBounsScatterDataZorder(self,symbolType )
    --将H1,H2层级设置为scatter层级
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif self:isSpecialNode(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end

    return order

end

-- 重置当前背景音乐名称
function CodeGameScreenCatandMouseMachine:resetCurBgMusicName(musicName)

    CodeGameScreenCatandMouseMachine.super.resetCurBgMusicName(self,musicName)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeKind or nil   
        if freeSpinType == "CAT" then
            self.m_currentMusicBgName = "CatandMouseSounds/music_CatandMouse_FreeBg1.mp3"
        elseif freeSpinType == "MOUSE" then
            self.m_currentMusicBgName = "CatandMouseSounds/music_CatandMouse_FreeBg2.mp3"
        end

    end
    
end

function CodeGameScreenCatandMouseMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
        bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex = 1, #self.m_lineSlotNodes do
                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end
            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode == nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode == nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end
                checkAddLineSlotNode(slotNode)
                --特殊处理，上面获取不到猫和鼠的小块，导致小块加进不self.m_lineSlotNodes，一直播连线动画
                if slotNode == nil and slotParentBig then
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        checkAddLineSlotNode(slotNode)
                    end
                end

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    local specialChilds = self:getAllSpecialNode()
    for specialIndex = 1, #specialChilds do
        local specialNode = specialChilds[specialIndex]
        checkAddLineSlotNode(specialNode)
    end
end

function CodeGameScreenCatandMouseMachine:flyAddWildShow(startPos, endPos, func)
    --计算旋转角度
    local rotation = util_getAngleByPos(startPos, endPos)
    --计算两点之间距离
    local distance = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    -- -- 创建粒子
    local flyNode = util_createAnimation("CatandMouse_addwild_trail.csb")
    self:findChild("mask"):addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 15)
    flyNode:setPosition(startPos)
    flyNode:setRotation(-rotation)
    flyNode:setScaleX(distance / 532)

    flyNode:runCsbAction(
        "actionframe",
        false,
        function()
            flyNode:removeFromParent()
        end
    )
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,0.1)
end

function CodeGameScreenCatandMouseMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath1 = "CatandMouseSounds/CatandMouse_h1_down.mp3"
        -- 
        local soundPathBonus = "CatandMouseSounds/CatandMouse_bonus_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath1  --猫落地
        self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = soundPathBonus
        -- 
    end
end

function CodeGameScreenCatandMouseMachine:setMouseDownSound( )
    for i=1,5 do
        local soundPath2 = "CatandMouseSounds/CatandMouse_h2_down.mp3"
        self.m_scatterBulingSoundArry2[#self.m_scatterBulingSoundArry2 + 1] = soundPath2    --老鼠落地
    end
end

-- 特殊信号下落时播放的音效
function CodeGameScreenCatandMouseMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        local soundType = slotNode.p_symbolType
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end

            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end

            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
            if self.m_scatterBulingSoundArry2 == nil or not tolua.isnull(self.m_scatterBulingSoundArry2) then
                return
            end

            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry2[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry2[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry2["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry2["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        elseif  self:isSpecialNode(slotNode.p_symbolType) then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        end

        if soundPath then
            self:playBulingSymbolSounds(iCol, soundPath, soundType)
        end
    end
end

function CodeGameScreenCatandMouseMachine:specialSymbolActionTreatment( node)
    --修改小块层级
    local scatterOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
    local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,scatterOrder)
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
        self:playScatterBonusSound(symbolNode)
        symbolNode:runAnim("buling")
        
    end

end

function CodeGameScreenCatandMouseMachine:isHaveBigWinEffect(winAmonut)
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = winAmonut / lTatolBetNum
    if winRatio >= self.m_HugeWinLimitRate then
        return true
    elseif winRatio >= self.m_MegaWinLimitRate then
        return true
    elseif winRatio >= self.m_BigWinLimitRate then
        return true
    end
    return false
end

--[[
    延迟回调
]]
function CodeGameScreenCatandMouseMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

--在背景音乐停止时关闭idle音效
function CodeGameScreenCatandMouseMachine:reelsDownDelaySetMusicBGVolume()
    self:removeSoundHandler()

    self.m_soundHandlerId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_soundHandlerId = nil
            local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0

            self.m_soundGlobalId =
                scheduler.scheduleGlobal(
                function()
                    --播放广告过程中暂停逻辑
                    if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                        return
                    end

                    if volume <= 0 then
                        volume = 0
                    end

                    print("缩小音量 = " .. tostring(volume))
                    gLobalSoundManager:setBackgroundMusicVolume(volume)

                    if volume <= 0 then
                        if self.m_soundGlobalId ~= nil then
                            scheduler.unscheduleGlobal(self.m_soundGlobalId)
                            self.m_soundGlobalId = nil

                            self:showSoundForIdle(false,nil,true)
                            self.isResetSoundId = true
                        end
                    end

                    volume = volume - 0.04
                end,
                0.1
            )
        end,
        self.m_bgmReelsDownDelayTime,
        "SoundHandlerId"
    )

    self:setReelDownSoundFlag(true)
end

function CodeGameScreenCatandMouseMachine:scaleMainLayer()
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
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            local offsetScale = 1.08
            offsetScale = offsetScale - (DESIGN_SIZE.height - display.height) / 100 * 0.0751
            
            local offsetY = 0
            if display.height >= 1024 and display.height < 1152 then
                offsetY = offsetY + (DESIGN_SIZE.height - display.height) / 100 * 24
                mainScale = offsetScale
            elseif display.height >= 1152 and display.height < 1228 then
                offsetY = offsetY + (DESIGN_SIZE.height - display.height) / 100 * 30
                mainScale = offsetScale
            elseif display.height >= 1228 and display.height < 1370 then
                offsetY = offsetY + (DESIGN_SIZE.height - display.height) / 100 * 40
                mainScale = offsetScale
            end
            if display.height >1259 and display.height <=1369 then
                mainScale = 0.97
            end
            self.m_machineNode:setPositionY(offsetY)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        else

        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
    if display.height < DESIGN_SIZE.height then
        self:findChild("Node_bonusrenwu"):setScale(1.04 + (1- self.m_machineRootScale))
    end
end

function CodeGameScreenCatandMouseMachine:showEffect_NewWin(effectData, winType)
    CodeGameScreenCatandMouseMachine.super.showEffect_NewWin(self,effectData, winType)
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
        self:showSoundForIdle(false,nil,true)
        self.isResetSoundId = true
    end
end

return CodeGameScreenCatandMouseMachine