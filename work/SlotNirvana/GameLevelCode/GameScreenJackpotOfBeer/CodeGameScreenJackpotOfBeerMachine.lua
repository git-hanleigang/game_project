---
-- island li
-- 2019年1月26日
-- CodeGameScreenJackpotOfBeerMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenJackpotOfBeerMachine = class("CodeGameScreenJackpotOfBeerMachine", BaseSlotoManiaMachine)

CodeGameScreenJackpotOfBeerMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenJackpotOfBeerMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenJackpotOfBeerMachine.SYMBOL_BONUS_LINK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenJackpotOfBeerMachine.SYMBOL_WILD2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10   --长条wild  103
CodeGameScreenJackpotOfBeerMachine.SYMBOL_RS_SCORE_BLANK = 100        --空小块

CodeGameScreenJackpotOfBeerMachine.SMALLWILD_CHANGE = GameEffect.EFFECT_SELF_EFFECT - 10 -- 收集玩法以及free下边大wild玩法

CodeGameScreenJackpotOfBeerMachine.m_chipList = nil
CodeGameScreenJackpotOfBeerMachine.m_playAnimIndex = 0
CodeGameScreenJackpotOfBeerMachine.m_lightScore = 0

CodeGameScreenJackpotOfBeerMachine.m_playedYuGao = false

-- 构造函数
function CodeGameScreenJackpotOfBeerMachine:ctor()
    CodeGameScreenJackpotOfBeerMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_bCreateResNode = false
    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_smallWildist = nil
    self.isNextReSpin = false-- respin玩法 是否出发了多次 即集满15个啤酒 继续下次respin
    self.m_isDuanXianComIn = false -- 是否断线进来
    self.m_playedYuGao = false
	--init
	self:initGame()
end

function CodeGameScreenJackpotOfBeerMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("JackpotOfBeerConfig.csv", "LevelJackpotOfBeerConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenJackpotOfBeerMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "JackpotOfBeerSounds/music_JackpotOfBeer_scatter_Down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenJackpotOfBeerMachine:initUI()

    local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100 ,cc.c3b(0, 0, 0),100 )

    for i=1,5 do
        self["m_colorLayer_waitNode_"..i] = cc.Node:create()
        self:addChild(self["m_colorLayer_waitNode_"..i])
        self["colorLayer_"..i] = colorLayers[i]
    end
    
    self:hideColorLayer( )

    self:initFreeSpinBar() -- FreeSpinbar
    
    self.m_fankui = util_createAnimation("JackpotOfBeer_total_fankui.csb") 
    self.m_bottomUI.coinWinNode:addChild(self.m_fankui)
    self.m_fankui:setVisible(false)
  

    
    

    self.m_jackPotBar = util_createView("CodeJackpotOfBeerSrc.JackpotOfBeerJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self.m_respinBar = util_createView("CodeJackpotOfBeerSrc.JackpotOfBeerRespinBarView")        --Respin次数框
    self:findChild("linkbar"):addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)

    --收集玩法棋盘上层遮罩
    self.m_BubbleMainNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_BubbleMainNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)

    --free的过场
    self.m_changeSceneFree = util_spineCreate("scatter_guochang", true, true)
    self:findChild("guochang"):addChild(self.m_changeSceneFree)
    -- self.m_changeScene:setPosition(cc.p(display.width/2,display.height/2))
    self.m_changeSceneFree:setVisible(false)

    --link的过场
    self.m_changeSceneLink = util_createAnimation("JackpotOfBeer_guochang.csb")
    self:findChild("guochang"):addChild(self.m_changeSceneLink)
    self.m_changeSceneLink:setVisible(false)

    self.m_changeSceneLinkSpine = util_spineCreate("Socre_JackpotOfBeer_Bonus_link", true, true)
    self.m_changeSceneLink:findChild("Node_spine"):addChild(self.m_changeSceneLinkSpine)
    self.m_changeSceneLinkSpine:setVisible(false)

    -- 预告中奖动画
    self.yuGaoView = util_createAnimation("JackpotOfBeer_yugaozhongjiang.csb")
    self:findChild("yugao"):addChild(self.yuGaoView)
    self.yuGaoView:setVisible(false)

    self.yuGaoViewSpine = util_spineCreate("Socre_JackpotOfBeer_Wild_yugao", true, true)
    self.yuGaoView:findChild("spine_yugao"):addChild(self.yuGaoViewSpine)
    self.yuGaoViewSpine:setVisible(false)

    --光效层
    self.m_lightEffectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_lightEffectNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)

    self:initReelBg(1)

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
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "JackpotOfBeerSounds/music_JackpotOfBeer_last_win_".. soundIndex .. ".mp3"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "JackpotOfBeerSounds/music_JackpotOfBeer_FS_last_win_".. soundIndex .. ".mp3"
        else
            if winRate >= 2 then
                gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_niceWin.mp3")
            end
            
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenJackpotOfBeerMachine:initReelBg(status)

    if status == 1 then
        self.m_gameBgLink:setVisible(false)
        self.m_gameBg:setVisible(true)
        self:findChild("base"):setVisible(true)
        self:findChild("link"):setVisible(false)
        self:findChild("reel_free"):setVisible(false)
        self:findChild("reel_base"):setVisible(true)

        util_spinePlay(self.m_gameBg,"base_bg",true)
    elseif status == 2 then
        self.m_gameBgLink:setVisible(false)
        self.m_gameBg:setVisible(true)

        self:findChild("base"):setVisible(true)
        self:findChild("link"):setVisible(false)
        self:findChild("reel_free"):setVisible(true)
        self:findChild("reel_base"):setVisible(false)

        util_spinePlay(self.m_gameBg,"free_bg",true)
    elseif status == 3 then
        self.m_gameBgLink:setVisible(true)
        self.m_gameBg:setVisible(false)

        self:findChild("base"):setVisible(false)
        self:findChild("link"):setVisible(true)
        self:findChild("reel_free"):setVisible(false)
        self:findChild("reel_base"):setVisible(false)
        
        -- link玩法 层级要求 滚动层<棋盘背景<落地
        self.linkReelBg = util_createAnimation("JackpotOfBeer_linkReelBg.csb")
        self.m_respinView:addChild(self.linkReelBg,1000)
        self.link_round = util_createAnimation("JackpotOfBeer_link_round.csb")
        self.linkReelBg:addChild(self.link_round)
        self.link_round:setPosition(0,224)
        local round = self.m_runSpinResultData.p_rsExtraData.round or 1
        self.link_round:findChild("BitmapFontLabel_1"):setString(round)
        
        util_setCsbVisible(self.m_baseFreeSpinBar, false)

        self.m_gameBgLink:runCsbAction("idle",true)
    end
end

-- 背景
function CodeGameScreenJackpotOfBeerMachine:initMachineBg()
    local gameBgLink = util_createView("views.gameviews.GameMachineBG")
    local gameBg = util_spineCreate("JackpotOfBeer_bg", true, true) 
    local gameBgNode =  self:findChild("bgBaseFree")
    local gameBgLinkNode =  self:findChild("bg")

    if gameBgLinkNode  then
        gameBgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        gameBgLinkNode:addChild(gameBgLink, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        self:addChild(gameBgLink, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBgLink:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)
    
    self.m_gameBg = gameBg
    self.m_gameBgLink = gameBgLink
    gameBgLink:setAutoScaleEnabled(false)

    self.m_gameBg:setScale( 2 ) 
end

function CodeGameScreenJackpotOfBeerMachine:scaleMainLayer( )
    CodeGameScreenJackpotOfBeerMachine.super.scaleMainLayer(self )
    self.m_gameBg:setScale( self.m_gameBg:getScale()*self.m_machineRootScale)
    util_csbScale(self.m_gameBgLink.m_csbNode, self.m_machineRootScale)  

    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY()+ 7)

end
-- freespinbar
function CodeGameScreenJackpotOfBeerMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:runCsbAction("idle",true)
end

function CodeGameScreenJackpotOfBeerMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenJackpotOfBeerMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("freebar")
        self.m_baseFreeSpinBar = util_createView("CodeJackpotOfBeerSrc.JackpotOfBeerFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_baseFreeSpinBar:setPosition(0, 0)
    end
end

-- 断线重连 
function CodeGameScreenJackpotOfBeerMachine:MachineRule_initGame(  )
    self.m_isDuanXianComIn = true
    self.m_configData:setIsDuanXian(self.m_isDuanXianComIn)
    if self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        for iCol=1,5 do
            for Row=1,3 do
                if self.m_runSpinResultData.p_reels[Row][iCol] == self.SYMBOL_RS_SCORE_BLANK then
                    self.m_runSpinResultData.p_reels[Row][iCol] = math.random(0, 8)
                end
            end
        end
        self.m_initSpinData.p_reels = self.m_runSpinResultData.p_reels
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:initReelBg(2)
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenJackpotOfBeerMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "JackpotOfBeer"  
end

-- 继承底层respinView
function CodeGameScreenJackpotOfBeerMachine:getRespinView()
    return "CodeJackpotOfBeerSrc.JackpotOfBeerRespinView"
end
-- 继承底层respinNode
function CodeGameScreenJackpotOfBeerMachine:getRespinNode()
    return "CodeJackpotOfBeerSrc.JackpotOfBeerRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenJackpotOfBeerMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_BONUS  then 
        return "Socre_JackpotOfBeer_Bonus"
    elseif symbolType == self.SYMBOL_WILD2 then
        return "Socre_JackpotOfBeer_Wild2"
    elseif symbolType == self.SYMBOL_RS_SCORE_BLANK then
        return "Socre_JackpotOfBeer_Bonus_0"
    elseif symbolType == self.SYMBOL_BONUS_LINK then
        return "Socre_JackpotOfBeer_Bonus_link"
    end

    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenJackpotOfBeerMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    if self.isNextReSpin then
        storedIcons = self.m_runSpinResultData.p_rsExtraData.countIcons or {}
    end

    local score = nil
    local idNode = nil
    local jactpot = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
            if values[3] then
                jactpot = values[3]
            end
        end
    end

    if score == nil then
       return 0
    end

    return score, jactpot
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenJackpotOfBeerMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenJackpotOfBeerMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_RS_SCORE_BLANK,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_LINK,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenJackpotOfBeerMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenJackpotOfBeerMachine:slotOneReelDown(reelCol)    
    CodeGameScreenJackpotOfBeerMachine.super.slotOneReelDown(self,reelCol) 
    if reelCol == 1 then
        self:hideColorLayer( )
    end
    
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenJackpotOfBeerMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenJackpotOfBeerMachine:levelFreeSpinOverChangeEffect()

    
    
end
---------------------------------------------------------------------------


-- 触发freespin时调用
function CodeGameScreenJackpotOfBeerMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_showFreeSpinStart.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:playFreeChangeScene(
                    function()
                        self:initReelBg(2)
                    end,
                    function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end


-- 触发freespin结束时调用
function CodeGameScreenJackpotOfBeerMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_showFreeSpinOver.mp3")


   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:playFreeChangeScene(
                function()
                    self.m_baseFreeSpinBar:setVisible(false)
                    self:initReelBg(1)
                end,
                function()
                    -- 调用此函数才是把当前游戏置为freespin结束状态
                    self:triggerFreeSpinOverCallFun()
                end)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},500)

end

function CodeGameScreenJackpotOfBeerMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeJackpotOfBeerSrc.JackpotOfBeerJackPotWinView", self)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)

end

-- 结束respin收集
function CodeGameScreenJackpotOfBeerMachine:playLightEffectEnd()
    self.m_chipList = {}
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    -- 当集满15个啤酒 这一轮结束 开始结算 然后进行下一轮
    performWithDelay(self,function()
        if #self.m_chipList >= 15 then
            gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_ShowRespinReStart.mp3")
            self:showDialog("Respin_restart", nil, function(  )

                gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_RespinReStartGuoChang.mp3") 

                self:runCsbAction("start",false,function(  )

                    self.m_respinBar:updateTimes(self.m_runSpinResultData.p_reSpinCurCount) 
                    
                    self.isNextReSpin = false
                    self.m_BubbleMainNode:removeAllChildren()
                    for i, _node in ipairs(self.m_chipList) do
                        _node:removeFromParent()
                    end
    
                    for i=1,#self.m_respinView.m_respinNodes do
                        local respinNode = self.m_respinView.m_respinNodes[i]
                        respinNode.m_runLastNodeType = 100
                        respinNode:setRespinNodeStatus(1)
                    end
                    
                    self.m_respinView.m_spinEndNode = {}
    
                    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
                    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
                    end

                    self:runCsbAction("start2")
                end)
                self.m_gameBgLink:runCsbAction("start",false, function( )

                    self.m_gameBgLink:runCsbAction("idle2",true)

                    self.link_round:runCsbAction("actionframe") 
                    local round = self.m_runSpinResultData.p_rsExtraData.round or 1
                    self.link_round:findChild("BitmapFontLabel_1"):setString(round)

                    self:runNextReSpinReel()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})

                end)
    
                
            end, BaseDialog.AUTO_TYPE_ONLY)
        else
            -- 通知respin结束
            self:respinOver()
        end
    end,2)
    
end

function CodeGameScreenJackpotOfBeerMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        -- 此处跳出迭代
        self:playLightEffectEnd()
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = self:getPosReelIdx(iRow, iCol)  

    local score, jackpot = self:getReSpinSymbolScore(nFixIdx) 

    -- 根据网络数据获得当前固定小块的分数
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if jackpot then
        if jackpot == "grand" then
            jackpotScore = self:getCoinsFromStoredCreditData(nFixIdx )
            addScore = jackpotScore + addScore
            nJackpotType = 4
        elseif jackpot == "major" then
            jackpotScore = self:getCoinsFromStoredCreditData(nFixIdx )
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif jackpot == "minor" then
            jackpotScore =  self:getCoinsFromStoredCreditData(nFixIdx )
            addScore =jackpotScore + addScore                 
            nJackpotType = 2
        elseif jackpot == "mini" then
            jackpotScore = self:getCoinsFromStoredCreditData(nFixIdx ) 
            addScore =  jackpotScore + addScore                     
            nJackpotType = 1
        end
    else
        addScore = score * lineBet
    end
    local beginCoins = self.m_lightScore
    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if nJackpotType == 0 then
            local resWinCoins = self.m_runSpinResultData.p_resWinCoins
            local params = {self.m_lightScore, false, true,beginCoins}
            params[self.m_stopUpdateCoinsSoundIndex] = true

            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
            globalData.slotRunData.lastWinCoin = lastWinCoin

            self.m_playAnimIndex = self. m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else
            self:showRespinJackpot(nJackpotType, jackpotScore, function()
                local params = {self.m_lightScore, false, true,beginCoins}
                params[self.m_stopUpdateCoinsSoundIndex] = true

                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                globalData.slotRunData.lastWinCoin = lastWinCoin

                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end)
          
        end
    end
    
    chipNode:runAnim("shouji_link",false)

    local scoreLabNode =  self.m_BubbleMainNode:getChildByTag(nFixIdx)  
    if scoreLabNode then
        scoreLabNode:runCsbAction("shouji")
    end
    
    self:flyCollectCoin(chipNode, function ()
        runCollect()    
    end)
    
end

-- 收集金币
function CodeGameScreenJackpotOfBeerMachine:flyCollectCoin(startNode, func)

    self:playCoinWinEffectUI()
    self.m_fankui:runCsbAction("actionframe")

    gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_JieSuan.mp3")

    local fly = util_createAnimation("JackpotOfBeer_linktuowei.csb")
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local pos = cc.p(self.m_bottomUI:findChild("node_bar"):getPosition()) 
    local endworldPos = self.m_bottomUI:findChild("node_bar"):getParent():convertToWorldSpace(cc.p(pos.x,pos.y - 40 ))
    local endPos = self:convertToNodeSpace(cc.p(endworldPos))

    local startWorldPos = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local startPos =  self:convertToNodeSpace(cc.p(startWorldPos))



    local angle = util_getAngleByPos(startPos,endPos)
    fly:findChild("Node_1"):setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
    fly:findChild("Node_1"):setScaleX(scaleSize / 580 )

    fly:setPosition(startPos)

    fly:runCsbAction("actionframe")
    
    performWithDelay(fly,function ()
        if func then
            func()
        end

        fly:stopAllActions()
        fly:removeFromParent()
    end,24/60)
end

function CodeGameScreenJackpotOfBeerMachine:getCoinsFromStoredCreditData(_nFixIdx )
    local coins = 0
    local storedCreditData = self.m_runSpinResultData.p_rsExtraData.preStoredCredit  or self.m_runSpinResultData.p_rsExtraData.storedCredit  --服务器返回的分数

    for k,_data in pairs(storedCreditData) do
        local posIndex = _data[1]
        local coins = _data[2]
        if posIndex == _nFixIdx then
            return coins
        end
    end

    return 0
end

function CodeGameScreenJackpotOfBeerMachine:getRsSpinCurrCoins( )
    local currCoins = 0
    for i=1,#self.m_chipList do
        local chipNode = self.m_chipList[i]
        local iCol = chipNode.p_cloumnIndex
        local iRow = chipNode.p_rowIndex            
        local nFixIdx = self:getPosReelIdx(iRow, iCol) 

        currCoins = currCoins + self:getCoinsFromStoredCreditData(nFixIdx )
 
    end
    
    return currCoins
end
--结束移除小块调用结算特效
function CodeGameScreenJackpotOfBeerMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    
    for i, _node in ipairs(self.m_chipList) do
        _node:runAnim("actionframe_link3",false,function( )
        end)
    end
    self.m_lightScore = 0
    local respinCountCoins = self.m_runSpinResultData.p_resWinCoins or 0
    local round = self.m_runSpinResultData.p_rsExtraData.round
    if round > 1 then
        self.m_lightScore = respinCountCoins - self:getRsSpinCurrCoins( )
    end
    
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            self.m_lightScore = self.m_lightScore +  self.m_runSpinResultData.p_fsWinCoins - respinCountCoins
        else
            self.m_lightScore = self.m_lightScore +  self.m_runSpinResultData.p_fsWinCoins
        end
        
    end

    performWithDelay(self,function(  )
        self:playChipCollectAnim()
    end,30/30)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenJackpotOfBeerMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_BONUS_LINK,
        self.SYMBOL_RS_SCORE_BLANK}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenJackpotOfBeerMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS_LINK, runEndAnimaName = "buling_link", bRandom = true}
    }

    return symbolList
end

function CodeGameScreenJackpotOfBeerMachine:showRespinView()


    gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_triggerRsBonus.mp3")

    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS then
                    local symbolNode = util_setSymbolToClipReel(self,iCol, iRow, self.SYMBOL_BONUS,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                    curBonusList[#curBonusList + 1] = node
                end
            end
        end
    end
    for i,v in ipairs(curBonusList) do
        v:runAnim("actionframe",false,function (  )
            v:runAnim("idleframe",true)
        end)
    end
    performWithDelay(self,function (  )
        --将self.m_clipParent层小块放回滚轴层
        self:checkChangeBaseParent()
        -- self:showRespinStartView(function (  )
            self:clearCurMusicBg()
            self.m_respinBar:resetLastNum()
    
            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes( )
    
            --可随机的特殊信号 
            local endTypes = self:getRespinLockTypes()
            
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
            
        -- end)
    end,2)
end

function CodeGameScreenJackpotOfBeerMachine:initRespinView(endTypes, randomTypes)

    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                    self:playLinkChangeScene(function()
                        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                        -- 更改respin 状态下的背景音乐
                        self:changeReSpinBgMusic()
                        self:runNextReSpinReel()
                    end)
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)

    for i, _respinNodeInfo in ipairs(respinNodeInfo) do
        if _respinNodeInfo.Type == self.SYMBOL_BONUS_LINK then
            self:showRespinDuanXianScore(_respinNodeInfo.ArrayPos.iX, _respinNodeInfo.ArrayPos.iY, "idle2")
        end
    end
    self.m_isDuanXianComIn = false
    self.m_configData:setIsDuanXian(self.m_isDuanXianComIn)
end

-- 断线重连的时候 需要先显示 95对应位置的分值
function CodeGameScreenJackpotOfBeerMachine:showRespinDuanXianScore(iRow, iCol, idle)
    local storedCreditData =  self.m_runSpinResultData.p_rsExtraData.storedCredit or nil --服务器返回的分数

    local score = util_createAnimation("JackpotOfBeer_coins.csb")
    local index = self:getPosReelIdx(iRow ,iCol)
    self.m_BubbleMainNode:addChild(score,index,index)    
    local pos = cc.p(util_getOneGameReelsTarSpPos(self,index ) )  
    score:setScale(0.8)
    score:setPosition(cc.p(pos.x-5, pos.y-10))
    score:setTag(index)
    score:setName("coins")
    score:findChild("m_lb_coins_0"):setString(util_formatCoins(storedCreditData[index+1][2], 3))
    score:findChild("m_lb_coins"):setString(util_formatCoins(storedCreditData[index+1][2], 3))
    
    
    if storedCreditData[index+1][3] then
        score:findChild("m_lb_coins_0"):setVisible(false)
        score:findChild("m_lb_coins"):setVisible(false)
        local temporaryTable = {"link_grand0", "link_major0", "link_minor0", "link_mini0",
            "link_grand", "link_major", "link_minor", "link_mini"}
        for i,v in ipairs(temporaryTable) do
            score:findChild(v):setVisible(false)
        end
        if storedCreditData[index+1][3] == "grand" then
            score:findChild("link_grand0"):setVisible(true)
            score:findChild("link_grand"):setVisible(true)
            score:setName("grand")
            
            local jpLight = util_createAnimation("JackpotOfBeer_coins_0.csb")
            score:addChild(jpLight,-1)
            jpLight:runCsbAction("actionframe",false,function(  )
                jpLight:removeFromParent()
            end)
        elseif storedCreditData[index+1][3] == "major" then 
            score:findChild("link_major0"):setVisible(true)
            score:findChild("link_major"):setVisible(true)
            score:setName("major")
            local jpLight = util_createAnimation("JackpotOfBeer_coins_0.csb")
            score:addChild(jpLight,-1)
            jpLight:runCsbAction("actionframe",false,function(  )
                jpLight:removeFromParent()
            end)
        elseif storedCreditData[index+1][3] == "minor" then
            score:findChild("link_minor0"):setVisible(true)
            score:findChild("link_minor"):setVisible(true)
            score:setName("minor")
            local jpLight = util_createAnimation("JackpotOfBeer_coins_0.csb")
            score:addChild(jpLight,-1)
            jpLight:runCsbAction("actionframe",false,function(  )
                jpLight:removeFromParent()
            end)
        elseif storedCreditData[index+1][3] == "mini" then
            score:findChild("link_mini0"):setVisible(true)
            score:findChild("link_mini"):setVisible(true)
            score:setName("mini")
            local jpLight = util_createAnimation("JackpotOfBeer_coins_0.csb")
            score:addChild(jpLight,-1)
            jpLight:runCsbAction("actionframe",false,function(  )
                jpLight:removeFromParent()
            end)
        end
    else
        score:findChild("Node_jackpot"):setVisible(false)
        score:findChild("Node_jackpot1"):setVisible(false)
    end
    score:runCsbAction(idle)
end

-- 用于判断 进去respin的时候 是否清空棋盘
function CodeGameScreenJackpotOfBeerMachine:isClearQiPan( )
    local reelTable = self.m_runSpinResultData.p_reels
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            if reelTable[iRow][iCol] then
                if reelTable[iRow][iCol] == self.SYMBOL_BONUS_LINK or reelTable[iRow][iCol] == self.SYMBOL_RS_SCORE_BLANK then
                    return false
                end
            end
        end
    end
    return true
end
----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenJackpotOfBeerMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if self:isClearQiPan() or self:getIsNextLink( ) then
                symbolType = self.SYMBOL_RS_SCORE_BLANK
            end
            --层级
            -- local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            local zorder = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end

function CodeGameScreenJackpotOfBeerMachine:showReSpinStart(func)

    gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_showReSpinStart.mp3")
    
    --清空底部金币
    if self.m_bottomUI.m_isUpdateTopUI == true then
        self.m_bottomUI:notifyTopWinCoin()
    end
    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:checkClearWinLabel()

    local respinCountCoins = self.m_runSpinResultData.p_resWinCoins or 0
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    local totalCoins = respinCountCoins + fsWinCoins
    if self.m_bProduceSlots_InFreeSpin then
        if totalCoins > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalCoins))
        end
    else
        if respinCountCoins > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(respinCountCoins))
        end
        
    end
    
    self:clearCurMusicBg()
    self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

--ReSpin开始改变UI状态
function CodeGameScreenJackpotOfBeerMachine:changeReSpinStartUI(respinCount)
    self.m_respinBar:updateTimes(respinCount)
    self:initReelBg(3)
    self.m_respinBar:setVisible(true)
    self.m_respinBar:runCsbAction("idle")
end

--ReSpin刷新数量
function CodeGameScreenJackpotOfBeerMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_respinBar:updateTimes(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenJackpotOfBeerMachine:changeReSpinOverUI()
    self.m_BubbleMainNode:removeAllChildren()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:initReelBg(2)
    else
        self:initReelBg(1)
    end
    self.m_respinBar:setVisible(false)
end

function CodeGameScreenJackpotOfBeerMachine:showRespinOverView(effectData)
    
    self:changeReSpinOverUI()
    self:reSpinOverChangeReel()
    
    gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_showReSpinOver.mp3")

    local strCoins=util_formatCoins(self.m_serverWinCoins,30)
    local view=self:showReSpinOver(strCoins,function()
        
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
        self:resetMusicBg() 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            util_setCsbVisible(self.m_baseFreeSpinBar, true)
        end
        
        
    end)
   
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},500)
end


-- --重写组织respinData信息
function CodeGameScreenJackpotOfBeerMachine:getRespinSpinData()
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


---
-- 处理点击逻辑
--
function CodeGameScreenJackpotOfBeerMachine:spinBtnEnProc()

    CodeGameScreenJackpotOfBeerMachine.super.spinBtnEnProc(self)
    
    self:showColorLayer( )

end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenJackpotOfBeerMachine:MachineRule_SpinBtnCall()

    self.m_playedYuGao = false
    self.m_playedYuGao = false
    self.m_isDuanXianComIn = false
    self.m_configData:setIsDuanXian(self.m_isDuanXianComIn)

    self:setMaxMusicBGVolume()

    -- 恢复一下大信号的层级 防止滚动的时候 层级不对
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if targSp.p_symbolType == self.SYMBOL_WILD2 then
                    targSp:hideBigSymbolClip()
                end
            end
        end
    end

    return false -- 用作延时点击spin调用
end




function CodeGameScreenJackpotOfBeerMachine:enterGamePlayMusic(  )
 
    self:playEnterGameSound( "JackpotOfBeerSounds/music_JackpotOfBeer_enter.mp3" )

end

function CodeGameScreenJackpotOfBeerMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenJackpotOfBeerMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenJackpotOfBeerMachine:addObservers()
	CodeGameScreenJackpotOfBeerMachine.super.addObservers(self)

end

function CodeGameScreenJackpotOfBeerMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenJackpotOfBeerMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end



-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenJackpotOfBeerMachine:addSelfEffect()
    -- 去掉变长图玩法
    -- local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    -- self.m_smallWildist = nil
    -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
    --     for iCol = 1, self.m_iReelColumnNum do
    --         for iRow = self.m_iReelRowNum, 1, -1 do
    --             local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    --             if node then
    --                 if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
    --                     if not self.m_smallWildist then
    --                         self.m_smallWildist = {}
    --                     end
    --                     self.m_smallWildist[#self.m_smallWildist + 1] = node
    --                 end
    --             end
    --         end
    --     end
    -- else
    --     if selfData.expandCol and #selfData.expandCol > 0 then
    --         for i,iCol in ipairs(selfData.expandCol) do
    --             for iRow = self.m_iReelRowNum, 1, -1 do
    --                 -- 服务器返过来的 列 是从0开始的
    --                 local node = self:getFixSymbol(iCol+1, iRow, SYMBOL_NODE_TAG)
    --                 if node then
    --                     if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
    --                         if not self.m_smallWildist then
    --                             self.m_smallWildist = {}
    --                         end
    --                         self.m_smallWildist[#self.m_smallWildist + 1] = node
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end
        
    -- if self.m_smallWildist and #self.m_smallWildist > 0 then
    --     local selfEffect = GameEffectData.new()
    --     selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --     selfEffect.p_effectOrder = self.SMALLWILD_CHANGE
    --     self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --     selfEffect.p_selfEffectType = self.SMALLWILD_CHANGE -- 动画类型 
    -- end

end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenJackpotOfBeerMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.SMALLWILD_CHANGE then
        self:wildSmallChangeBig()
        performWithDelay(self,function (  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end,1.5)
    end

    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenJackpotOfBeerMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


function CodeGameScreenJackpotOfBeerMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenJackpotOfBeerMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenJackpotOfBeerMachine:slotReelDown( )


    

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenJackpotOfBeerMachine.super.slotReelDown(self)
end

--将小wild一整列变成一个大wild
function CodeGameScreenJackpotOfBeerMachine:wildSmallChangeBig()
    for _, node in pairs(self.m_smallWildist) do
        local iCol = node.p_cloumnIndex
        local maxZOrder = 0
        local nodeList = {}     --储存出现wild列的小块，进行移除
        local wildNodeList = {} 
        for j = 1, self.m_iReelRowNum , 1 do
            local otherNode =  self:getFixSymbol(iCol , j, SYMBOL_NODE_TAG)
            if otherNode ~= nil and otherNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                table.insert(nodeList,otherNode)
                if maxZOrder <  otherNode:getLocalZOrder() then
                    maxZOrder = otherNode:getLocalZOrder()
                end
            elseif otherNode ~= nil and otherNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                table.insert( wildNodeList, node)
            end
        end
        self:addBigWildInfo(node)

        -- performWithDelay(self,function (  )
            for i=1,#nodeList do
                local node = nodeList[i]
                if node then
                    self:moveDownCallFun(node, node.p_cloumnIndex)      --删除小块（调用这个函数为了回收小块到池中去）
                end 
            end
        -- end,0.5)
        --根据wild不同行数播放不同的时间线
        if node.p_rowIndex == 1 then
            node:runAnim("switch4")
        elseif node.p_rowIndex == 2 then
            node:runAnim("switch3")
        elseif node.p_rowIndex == 3 then
            node:runAnim("switch2")
        end
        
        performWithDelay(self,function (  )
            local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_WILD2, 1, iCol, false)   --创建长条小块
            
            if targSp then 
                targSp:runAnim("idleframe")
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
                
                local pos =  cc.p(self:getPosByColAndRow(iCol, 1))

                targSp:setPosition(pos)

                
                targSp:setLocalZOrder( REEL_SYMBOL_ORDER.REEL_ORDER_2 - targSp.p_rowIndex + self:getBounsScatterDataZorder(targSp.p_symbolType ))
                
                for i=1,#wildNodeList do
                    local node = wildNodeList[i]
                    if node then
                        self:moveDownCallFun(node, node.p_cloumnIndex)      --删除小块（调用这个函数为了回收小块到池中去）
                    end 
                end
                
            end
        end,1)
        
    end
    
end

function CodeGameScreenJackpotOfBeerMachine:getPosByColAndRow(col, row)
    local posX = self.m_SlotNodeW
    local posY = (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

function CodeGameScreenJackpotOfBeerMachine:addBigWildInfo(node)
    local stepCount = 1
    local icol = node.p_cloumnIndex
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
                    symbolType = self.SYMBOL_WILD2
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

---
--设置bonus scatter 层级
function CodeGameScreenJackpotOfBeerMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD2 then
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

-- 使用服务器返回的数据 判断，不这样的话 断线重连不好判断
function CodeGameScreenJackpotOfBeerMachine:getSymbolBySpinResult(iRow, iCol)
    local reelsData = self.m_runSpinResultData.p_reels or {}
    if iRow == 1 then
        iRow = 3
    elseif iRow == 3 then
        iRow = 1
    end
    return reelsData[iRow][iCol]
end

--判断服务器返回的 是否全部是 95 如果是 则在此触发了 link玩法
function CodeGameScreenJackpotOfBeerMachine:getIsNextLink( )
    local reelTable = self.m_runSpinResultData.p_reels
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            if reelTable[iRow][iCol] then
                if reelTable[iRow][iCol] ~= self.SYMBOL_BONUS_LINK then
                    return false
                end
            end
        end
    end
    return true
end

-- respin玩法 每次spin之前 刷新分数
function CodeGameScreenJackpotOfBeerMachine:showReSpinScore( )
    local storedCreditData =  self.m_runSpinResultData.p_rsExtraData.storedCredit or nil --服务器返回的分数

    local delayTimeIndex = 1
    if storedCreditData then
        for iCol=1,self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                if self:getSymbolBySpinResult(iRow, iCol) ~= self.SYMBOL_BONUS_LINK or self:getIsNextLink() then
                    local index = self:getPosReelIdx(iRow ,iCol)
                    if self.m_BubbleMainNode:getChildByTag(index) then
                        self.m_BubbleMainNode:getChildByTag(index):runCsbAction("reload1",false,function (  )
                            self.m_BubbleMainNode:removeChildByTag(index)
                        end)
                        
                    end
                end
            end
        end

        for iCol=1,self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                if self:getSymbolBySpinResult(iRow, iCol) ~= self.SYMBOL_BONUS_LINK or self:getIsNextLink() then
                    delayTimeIndex = delayTimeIndex + 1
                    performWithDelay(self,function()

                        gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_shuzi_shuaxin.mp3")

                        self:showRespinDuanXianScore(iRow, iCol, "idle1")
                    end,0.1 * delayTimeIndex)
                end
            end
        end

    end

    return 0.1 * delayTimeIndex + 0.2
end

-- free过场
function CodeGameScreenJackpotOfBeerMachine:playFreeChangeScene(func1, func2)

    gLobalSoundManager:playSound("JackpotOfBeerSounds/JackpotOfBeer_Free_GuoChang.mp3")

    self.m_changeSceneFree:setVisible(true)
    -- 过场动画
    util_spinePlay(self.m_changeSceneFree,"actionframe")

    util_spineEndCallFunc(self.m_changeSceneFree,"actionframe",function ()
        --构造盘面数据0
        self.m_changeSceneFree:setVisible(false)
        if func2 then
            func2()
        end
    end)
    util_spineFrameEvent(self.m_changeSceneFree,"actionframe","1",function ()
        if func1 then
            func1()
        end
    end)
end

--link过场
function CodeGameScreenJackpotOfBeerMachine:playLinkChangeScene(func1)

    gLobalSoundManager:playSound("JackpotOfBeerSounds/JackpotOfBeer_RS_GuoChang.mp3")

    self.m_changeSceneLink:setVisible(true)
    self.m_changeSceneLinkSpine:setVisible(true)

    self.m_changeSceneLink:runCsbAction("actionframe") 
    util_spinePlay(self.m_changeSceneLinkSpine,"guochang_link")

    util_spineEndCallFunc(self.m_changeSceneLinkSpine,"guochang_link",function ()
        self.m_changeSceneLink:setVisible(false)
        self.m_changeSceneLinkSpine:setVisible(false)
        if func1 then
            func1()
        end
    end)
end

function CodeGameScreenJackpotOfBeerMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    

    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then
        -- c出现预告动画概率40%
        local yuGaoId = math.random(1, 10)
        if yuGaoId <= 4  then
            self.m_playedYuGao = true
            self:playYuGaoAct(function()
                self:produceSlots()
    
                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end)
        else
            self:produceSlots()

            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end
        
    else
        self:produceSlots()

        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end
    
end

--播放中奖预告
function CodeGameScreenJackpotOfBeerMachine:playYuGaoAct(func)

     gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_playYuGaoAct.mp3") 
    self.yuGaoView:setVisible(true)

    self.yuGaoView:runCsbAction("actionframe_yugao") 
    performWithDelay(self,function ()
        self.yuGaoViewSpine:setVisible(true)

        util_spinePlay(self.yuGaoViewSpine,"actionframe_yugao")

        util_spineEndCallFunc(self.yuGaoViewSpine,"actionframe_yugao",function ()
            self.yuGaoView:setVisible(false)
            self.yuGaoViewSpine:setVisible(false)
            if func then
                func()
            end
        end)
        
    end,45/60)
    
end

--开始滚动
function CodeGameScreenJackpotOfBeerMachine:startReSpinRun()
    local delayTime = self:showReSpinScore()
    
    performWithDelay(self,function (  )
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})

        if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
            return
        end
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end
        --一次新的spin发个通知
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

        self:requestSpinReusltData()
        if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1,
            self.m_runSpinResultData.p_reSpinsTotalCount)
        end
    
        self.m_respinView:startMove()
    end,delayTime)
    

end

---判断结算
function CodeGameScreenJackpotOfBeerMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self.m_chipList = {}
    self.m_chipList = self.m_respinView:getAllCleaningNode()

     -- 每次respin 之后 播放的动画
    local delayTime = 0
    local isHaveJackpot = false
    local newIconData =  self.m_runSpinResultData.p_rsExtraData.newIcon or nil --服务器返回的本次spin 中酒杯的位置
    if newIconData and #newIconData > 0 then

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
 
        if #self.m_chipList < 15 then
            self.m_respinBar:runCsbAction("actionframe",false,function( )
                gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_AddTimes.mp3")
                self.m_respinBar:updateTimes(self.m_runSpinResultData.p_reSpinCurCount) 
                self.m_respinBar:runCsbAction("idle")
             end) 
        end
         
 
        for i, _node in ipairs(self.m_respinView.m_spinEndNode) do
            for j, _id in ipairs(newIconData) do
                local pos = self:getRowAndColByPos(_id)
                if pos.iX == _node.p_rowIndex and pos.iY == _node.p_cloumnIndex then
                    -- local node = self.m_respinView:getRespinNode(pos.iX, pos.iY)
                    if _node.m_ccbName == "Socre_JackpotOfBeer_Bonus_link" then
                        _node:runAnim("actionframe_link2",false,function( )
                            _node:runAnim("actionframe_link",false,function( )
                                _node:runAnim("idleframe",true)
                            end)
                        end)
                        
                    end
                    local actNode = self.m_BubbleMainNode:getChildByTag(_id)
                    

                    if actNode then
                        local actNodeName = actNode:getName()
                        if actNodeName == "grand" then
                            isHaveJackpot = true
                        elseif actNodeName == "major" then 
                            isHaveJackpot = true
                        elseif actNodeName == "minor" then
                            isHaveJackpot = true
                        elseif actNodeName == "mini" then
                            isHaveJackpot = true
                        end
                        
                    end
                    performWithDelay(self,function(  )
                        if actNode then
                            local actNode_1 = actNode
                            actNode_1:runCsbAction("actionframe",false,function()
                                actNode_1:findChild("Node_2"):setVisible(false)
                            end)
                        end
                    end,0.5)
                    
                end
            end
        end
        delayTime = 2 + 0.5

        if isHaveJackpot then
            gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_JackPot_RenSheng.mp3")
            gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_JpEmptyCupToFull.mp3")
        else
            gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_emptyCupToFull.mp3") 
        end
        


    end

    local function beginNextSpin(  )
        self:setGameSpinStage(STOP_RUN)

        -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        self:updateQuestUI()

        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
    
            --quest
            self:updateQuestBonusRespinEffectData()
            
            performWithDelay(self,function()
                   --结束
                self:reSpinEndAction()

                self:removeSoundHandler( )
                self:reelsDownDelaySetMusicBGVolume( )
            end, 2)
            
    
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    
            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false
    
            return
        end
    
        
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        --    dump(self.m_runSpinResultData,"m_runSpinResultData")

        if #self.m_chipList < 15 then
            if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            end
        end
        
        --    --下轮数据
        --    self:operaSpinResult()
        --    self:getRandomList()
        --继续
        
        performWithDelay(self,function()
            self:runNextReSpinReel()
            
        end, delayTime)
    end

 
    -- 当集满15个啤酒 这一轮结束 开始结算 然后进行下一轮
    -- 多次触发的时候 服务器才会给这个 countIcons
    if #self.m_chipList >= 15 then
        performWithDelay(self,function()
            self.isNextReSpin = true
            self:reSpinEndAction(true)
        end, 1.5)
        
    else
        beginNextSpin()
    end
end

function CodeGameScreenJackpotOfBeerMachine:respinOver()
    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:removeRespinNode()
    self:showRespinOverView()
end

--隐藏盘面信息
function CodeGameScreenJackpotOfBeerMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        local childs = self:getReelParent(iCol):getChildren()
        for j = 1, #childs do
            local node = childs[j]
            node:setVisible(status)
        end
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then
            local childs = slotParentBig:getChildren()
            for j = 1, #childs do
                local node = childs[j]
                node:setVisible(status)
            end
        end
    end

    --如果为空则从 clipnode获取
    -- local childs = self.m_clipParent:getChildren()
    -- local childCount = #childs

    -- for i = 1, childCount, 1 do
    --     local slotsNode = childs[i]
    --     if slotsNode:getTag() > SYMBOL_FIX_NODE_TAG and slotsNode:getTag() < SYMBOL_NODE_TAG then
    --         slotsNode:setVisible(status)
    --     end
    -- end
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenJackpotOfBeerMachine:initCloumnSlotNodesByNetData()
    -- self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount, rowNum, rowIndex = self:getinitSlotRowDatatByNetData(columnData)

        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType)

            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
end

-- respin结束之后 重置一下棋盘 ，策划说 空小块显示上面不好看
function CodeGameScreenJackpotOfBeerMachine:reSpinOverChangeReel()
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node then
            local cloumnIndex = _node.p_cloumnIndex
            -- local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex( cloumnIndex )
            -- local symbolType = self:getRandomReelType(cloumnIndex, reelDatas)
            local symbolType = math.random(0, 8)
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            _node:changeCCBByName(ccbName, symbolType)
            _node:changeSymbolImageByName(ccbName)
            _node:resetReelStatus()
        end
    end)
end

function CodeGameScreenJackpotOfBeerMachine:baseReelForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node.p_symbolType == self.SYMBOL_RS_SCORE_BLANK then
                local isJumpFun = fun(node, iCol, iRow)
                if (isJumpFun) then
                    return
                end
            end
        end
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenJackpotOfBeerMachine:specialSymbolActionTreatment( node)
    -- print("dada")

    if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --修改小块层级
        local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType,0)
        symbolNode:runAnim("buling")
    end

end

function CodeGameScreenJackpotOfBeerMachine:playCustomSpecialSymbolDownAct( slotNode )

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        if slotNode and  self:isFixSymbol(slotNode.p_symbolType) then
            local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
            self:playScatterBonusSound(slotNode)
            symbolNode:runAnim("buling")
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,"JackpotOfBeerSounds/music_JackpotOfBeer_fixSymoblDown.mp3" )
        end
        
    end


end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenJackpotOfBeerMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

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
        if slotNode==nil then
            slotNode = self:getFixSymbol(symPosData.iY , symPosData.iX)
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

function CodeGameScreenJackpotOfBeerMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = 1, nodeLen do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent,lineNode,nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
            end
        end
    end

    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_BONUS then
                    targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
 
                end
            end

        end

    end

    
end

function CodeGameScreenJackpotOfBeerMachine:checkIsInLongRun(col, symbolType)
    
    if self.m_playedYuGao then
        return false
    else
        return CodeGameScreenJackpotOfBeerMachine.super.checkIsInLongRun(self,col, symbolType)
    end
    
end

function CodeGameScreenJackpotOfBeerMachine:getReelWidth( )
    if display.width < 1228 then
        return 1150
    else
        return 950
    end
end

function CodeGameScreenJackpotOfBeerMachine:showColorLayer( )
    for i=1,5 do

        self["m_colorLayer_waitNode_"..i]:stopAllActions()

        local layerNode = self["colorLayer_"..i]

        util_playFadeInAction(layerNode,0.1)
        layerNode:setVisible(true)
    end
end

function CodeGameScreenJackpotOfBeerMachine:hideColorLayer( )
    for i=1,5 do
        self["m_colorLayer_waitNode_"..i]:stopAllActions()

        local layerNode = self["colorLayer_"..i]
        util_playFadeOutAction(layerNode,0.1)
        layerNode:setVisible(true)
        performWithDelay(self["m_colorLayer_waitNode_"..i] ,function(  )
            layerNode:setVisible(false)
        end,0.1)
    end
end
--respin下获得特殊块类型
function CodeGameScreenJackpotOfBeerMachine:getSpecialSymbolType()
    if xcyy.SlotsUtil:getArc4Random() % 2 == 0 then
        return self.SYMBOL_RS_SCORE_BLANK
    else
        return self.SYMBOL_BONUS_LINK
    end
end

function CodeGameScreenJackpotOfBeerMachine:showLineFrame()

    if self:isTriggerFreeSpinOrBonus() then
        self:removeScatterAndBonusLines()
    end
    local lineLen = #self.m_reelResultLines
    if lineLen == 0 then
        
        if self.m_iOnceSpinLastWin > 0 then
            -- 如果freespin 未结束，不通知左上角玩家钱数量变化
            local isNotifyUpdateTop = true
            if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
                isNotifyUpdateTop = false
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
        end
        
    
    else
        CodeGameScreenJackpotOfBeerMachine.super.showLineFrame(self)
    end
    
end

function CodeGameScreenJackpotOfBeerMachine:isTriggerFreeSpinOrBonus()
    local isIn = false
    local features = self.m_runSpinResultData.p_features
    if features then
        for k, v in pairs(features) do
            if v == SLOTO_FEATURE.FEATURE_FREESPIN or v == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                isIn = true
            end
        end
    end

    return isIn
end

function CodeGameScreenJackpotOfBeerMachine:removeScatterAndBonusLines()
    local lineLen = #self.m_reelResultLines
    self.m_scatterLineValue = nil
    self.m_bonusLineValue = nil
    for i = lineLen, 1, -1 do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            self.m_scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
        elseif lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            self.m_bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
        end
    end
end

---
-- 显示free spin
function CodeGameScreenJackpotOfBeerMachine:showEffect_FreeSpin(effectData)
    if self.m_scatterLineValue then
        self.m_reelResultLines[#self.m_reelResultLines+1] = self.m_scatterLineValue
        self.m_scatterLineValue = nil
    end
    
    return CodeGameScreenJackpotOfBeerMachine.super.showEffect_FreeSpin(self,effectData)
end

return CodeGameScreenJackpotOfBeerMachine






