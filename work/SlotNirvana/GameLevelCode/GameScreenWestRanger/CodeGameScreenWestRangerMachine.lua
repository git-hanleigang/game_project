---
-- island li
-- 2019年1月26日
-- CodeGameScreenWestRangerMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = util_require("Levels.BaseDialog") 
local CodeGameScreenWestRangerMachine = class("CodeGameScreenWestRangerMachine", BaseSlotoManiaMachine)

CodeGameScreenWestRangerMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWestRangerMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2--95
CodeGameScreenWestRangerMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1--94
CodeGameScreenWestRangerMachine.SYMBOL_WILDBIG = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE--93
CodeGameScreenWestRangerMachine.SYMBOL_SCORE_BLANK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7--100

CodeGameScreenWestRangerMachine.m_changeBigSymbolEffect = GameEffect.EFFECT_SELF_EFFECT - 1 --base下自定义动画 
CodeGameScreenWestRangerMachine.m_freeSpinWildChange = GameEffect.EFFECT_SELF_EFFECT - 2 --free下自定义动画

CodeGameScreenWestRangerMachine.m_lightScore = 0


-- 构造函数
function CodeGameScreenWestRangerMachine:ctor()
    CodeGameScreenWestRangerMachine.super.ctor(self)

    self.m_videoPokeMgr = util_require("LevelVideoPokerCode.VideoPokeManager"):getInstance()
    if self:checkControlerReelType() then
        self.m_videoPokeMgr:initData( self )
    end

    self.m_isFeatureOverBigWinInFree = true

    self.m_wildContinusPos = {}-- 存放base下需要变化的wild
    self.m_aFreeSpinWildArry = {} -- FreeSpin 过程中wild 个数
    self.m_miniMachine = {} -- mini轮盘
    self.m_miniMachineBianKaung = {} -- mini盘集满 效果 挂点
    self.m_spinRestMusicBG = true
    self.m_lightScore = 0
    self.m_clipNode = {}--存储提高层级的图标
    self.m_isGetIndexMini = false
    self.m_curIsJackpotMiniIndex = false --当前结算是否弹jackpot的
    self.m_flyIndex = 1
    self.m_isDuanXian = true
    self.m_isTriggerLongRun = false

    self.m_isPlayRespinGoldSiverSound = false

	--init
	self:initGame()
end

function CodeGameScreenWestRangerMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("WestRangerConfig.csv", "LevelWestRangerConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenWestRangerMachine:initUI()

    -- util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_jackPotBar = util_createView("CodeWestRangerSrc.WestRangerJackPotBarView", self)
    self:findChild("jackpot"):addChild(self.m_jackPotBar)

    self.m_jackPotBarRespin = util_createView("CodeWestRangerSrc.WestRangerJackPotBarView", self)
    self:findChild("jackpot_RESPIN"):addChild(self.m_jackPotBarRespin)

    self:initFreeSpinBar() -- FreeSpinbar

    -- 隐藏respin相关节点
    self:findChild("Node_2"):setVisible(false)
    
    for miniIndex = 1, 4 do
        self.m_miniMachine[miniIndex] = util_createView("CodeWestRangerSrc.WestRangerMini.WestRangerMiniMachine",{machine = self,index = miniIndex})
        self:findChild("mini_wheel_"..miniIndex):addChild(self.m_miniMachine[miniIndex])

        if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
            self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniMachine[miniIndex].m_touchSpinLayer)
        end
        self.m_miniMachineBianKaung[miniIndex] = util_createAnimation("Socre_WestRanger_jiman_biankuang.csb")
        self:findChild("respin_jiman"..miniIndex):addChild(self.m_miniMachineBianKaung[miniIndex])
        self.m_miniMachineBianKaung[miniIndex]:setVisible(false)

        self.m_miniMachine[miniIndex].m_suolian = util_createAnimation("WestRanger_Suolian.csb")
        self:findChild("respin_suolian_"..miniIndex):addChild(self.m_miniMachine[miniIndex].m_suolian)
        if miniIndex == 1 then
            self.m_miniMachine[miniIndex].m_suolian:setVisible(false)
        end
    end

    --base下可能触发respin的时候的 预告
    self.m_baseYugaoSpine1 = util_createAnimation("Socre_WestRanger_yugao.csb")
    self.m_baseYugaoSpine2 = util_spineCreate("Socre_WestRanger_Wild", true, true)
    self:findChild("yugaobg"):addChild(self.m_baseYugaoSpine1,1)
    self:findChild("yugaobg"):addChild(self.m_baseYugaoSpine2,2)
    self.m_baseYugaoSpine1:setVisible(false)
    self.m_baseYugaoSpine2:setVisible(false)

    -- free过场
    self.m_GuoChangBg = util_createAnimation("Socre_WestRanger_freeGC.csb")
    self:findChild("guochang"):addChild(self.m_GuoChangBg)
    self.m_GuoChangBg:setVisible(false)

    -- respin过场
    self.m_reSpinGuoChangBg = util_spineCreate("Socre_WestRanger_respineGC", true, true)
    self:findChild("respinGuoChang"):addChild(self.m_reSpinGuoChangBg)
    self.m_reSpinGuoChangBg:setVisible(false)

    -- respin结算框
    self.m_respin_jiesuan = util_createAnimation("Socre_WestRanger_Respin_Jiesuan.csb")
    self:findChild("respin_jiesuan"):addChild(self.m_respin_jiesuan)
    self.m_respin_jiesuan:setVisible(false)

    self.m_respin_jiesuan_qingzhu = util_createAnimation("Socre_WestRanger_Respin_Jiesuan_qingzhu.csb")
    self.m_respin_jiesuan:findChild("ef_jiantou"):addChild(self.m_respin_jiesuan_qingzhu)
    self.m_respin_jiesuan_qingzhu:setVisible(false)

    self:setReelBg(1)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if not (freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE) then
            if self.m_bIsBigWin then
                return 
            end
        end 
        if #self.m_runSpinResultData.p_features > 1 then
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

        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "WestRangerSounds/sound_WestRanger_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "WestRangerSounds/sound_WestRanger_last_win_".. soundIndex .. ".mp3"
        end

        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

-- 次数条
function CodeGameScreenWestRangerMachine:initFreeSpinBar( )
    -- FreeSpinbar
    self.m_FreespinBarView = util_createView("CodeWestRangerSrc.WestRangerFreespinBarView")
    self:findChild("freegamebar"):addChild(self.m_FreespinBarView)
    self.m_FreespinBarView:setVisible(false)

    -- respinber
    self.m_RespinBarView =  util_createView("CodeWestRangerSrc.WestRangerRespinBerView")
    self:findChild("respinbar"):addChild(self.m_RespinBarView)
    self.m_RespinBarView:setVisible(false)
end

-- 断线重连 
function CodeGameScreenWestRangerMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_FreespinBarView:setVisible(true)
        self.m_FreespinBarView:runCsbAction("start",false,function()
            self.m_FreespinBarView:runCsbAction("idleframe",true)
        end)
        self:setReelBg(2)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end

end

-- 背景
function CodeGameScreenWestRangerMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local gameBgRespin = util_createView("views.gameviews.GameMachineBG") 

    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    local bgNodeRespin = self:findChild("bg_respin")

    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    bgNodeRespin:addChild(gameBgRespin, GAME_LAYER_ORDER.LAYER_ORDER_BG)

    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    gameBgRespin:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBgBaceSpine = util_spineCreate("WestRanger_BG_bace", true, true) 
    self.m_gameBgFreeSpine = util_spineCreate("WestRanger_BG_free", true, true)
    self.m_gameBgRespinSpine = util_spineCreate("WestRanger_BG_respin", true, true)
    gameBg:findChild("Node_40"):addChild(self.m_gameBgBaceSpine)
    gameBg:findChild("free_zhutai"):addChild(self.m_gameBgFreeSpine)
    gameBgRespin:findChild("respin_zhutai"):addChild(self.m_gameBgRespinSpine)

    self.m_gameBg = gameBg
    self.m_gameBgRespin = gameBgRespin
end

--设置棋盘的背景
-- _BgIndex 1bace 2free 3respin
function CodeGameScreenWestRangerMachine:setReelBg(_BgIndex)
    
    if _BgIndex == 1 then
        self.m_gameBg:setVisible(true)
        self.m_gameBgRespin:setVisible(false)

        self.m_jackPotBar:setVisible(true)
        self.m_jackPotBarRespin:setVisible(false)

        self:findChild("bace_guang"):setVisible(true)
        self:findChild("free_guang"):setVisible(false)
        self:findChild("xian_base"):setVisible(true)
        self:findChild("xian_free"):setVisible(false)
        self:findChild("reel_bg_base"):setVisible(true)
        self:findChild("reel_bg_free"):setVisible(false)

        self:runCsbAction("bace",true)
        self.m_gameBg:runCsbAction("bace",true)
        util_spinePlay(self.m_gameBgBaceSpine, "bace_idle", true)
    elseif _BgIndex == 2 then
        self.m_gameBg:setVisible(true)
        self.m_gameBgRespin:setVisible(false)

        self.m_jackPotBar:setVisible(true)
        self.m_jackPotBarRespin:setVisible(false)

        self:findChild("bace_guang"):setVisible(false)
        self:findChild("free_guang"):setVisible(true)
        self:findChild("xian_base"):setVisible(false)
        self:findChild("xian_free"):setVisible(true)
        self:findChild("reel_bg_base"):setVisible(false)
        self:findChild("reel_bg_free"):setVisible(true)

        self:runCsbAction("free",true)
        self.m_gameBg:runCsbAction("free",true)
        util_spinePlay(self.m_gameBgFreeSpine, "free_zhutai", true)
    elseif _BgIndex == 3 then
        
        self.m_gameBgRespin:setVisible(true)
        self.m_gameBg:setVisible(false)

        self.m_jackPotBarRespin:setVisible(true)
        self.m_jackPotBar:setVisible(false)

        self:findChild("respin_guang"):setVisible(true)

        self:runCsbAction("respin",true)
        self.m_gameBgRespin:runCsbAction("respin",true)
        util_spinePlay(self.m_gameBgRespinSpine, "respin_zhutai", true)
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWestRangerMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "WestRanger"  
end

--小块
function CodeGameScreenWestRangerMachine:getBaseReelGridNode()
    return "CodeWestRangerSrc.WestRangerSlotNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWestRangerMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_BONUS1 then
        return "Socre_WestRanger_Bonus"
    end

    if symbolType == self.SYMBOL_BONUS2 then
        return "Socre_WestRanger_Bonus2"
    end

    if symbolType == self.SYMBOL_WILDBIG then
        return "Socre_WestRanger_Wild_0"
    end

    if symbolType == self.SYMBOL_SCORE_BLANK then
        return "Socre_WestRanger_Respin_Genzi"
    end 

    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenWestRangerMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local jackpotLoc = self.m_runSpinResultData.p_selfMakeData.jackpotLoc or {}
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    for _, _jackpotInfo in ipairs(jackpotLoc) do
        if _jackpotInfo[1] == idNode then
            score = _jackpotInfo[2]
        end
    end

    return score
end

function CodeGameScreenWestRangerMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS1 or symbolType == self.SYMBOL_BONUS2 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenWestRangerMachine:setSpecialNodeScore(sender,param)
    local bonusName = {"m_lb_score_yin","m_lb_score_jin","m_lb_mini","m_lb_minor","m_lb_mijor"}
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local coinsView
    local saoguang

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil then
            local symbol_node = symbolNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            if not spineNode.m_csbNode then
                coinsView = util_createAnimation("Socre_WestRanger_Bonus_coin.csb")
                util_spinePushBindNode(spineNode,"text",coinsView)
                spineNode.m_csbNode = coinsView
            else
                coinsView = spineNode.m_csbNode
            end

            if not spineNode.m_csbNodeSaoGuang then
                saoguang = util_createAnimation("Socre_WestRanger_Bonus_saoguang.csb")
                util_spinePushBindNode(spineNode,"text",saoguang)
                spineNode.m_csbNodeSaoGuang = saoguang
            else
                saoguang = spineNode.m_csbNodeSaoGuang
            end
            symbolNode:createBonusAddNode(score, symbolNode.p_symbolType == self.SYMBOL_BONUS2)
            
            local lineBet = globalData.slotRunData:getCurTotalBet()

            for i,vName in ipairs(bonusName) do
                coinsView:findChild(vName):setVisible(false)
            end
            if score == "mini" then--mini
                coinsView:findChild("m_lb_mini"):setVisible(true)
            elseif score == "minor" then--minor
                coinsView:findChild("m_lb_minor"):setVisible(true)
            elseif score == "major" then--major
                coinsView:findChild("m_lb_mijor"):setVisible(true)
            else
                score = score * lineBet
                score = util_formatCoins(score, 3)
                if symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
                    coinsView:findChild("m_lb_score_yin"):setVisible(true)
                    coinsView:findChild("m_lb_score_yin"):setString(score)
                elseif symbolNode.p_symbolType == self.SYMBOL_BONUS2 then
                    coinsView:findChild("m_lb_score_jin"):setVisible(true)
                    coinsView:findChild("m_lb_score_jin"):setString(score)
                end
            end
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                symbolNode:createBonusAddNode(score, symbolNode.p_symbolType == self.SYMBOL_BONUS2)
            end
        end
    end
end

-- 给金色 飞的 respin小块进行赋值
function CodeGameScreenWestRangerMachine:setJinSeBonusSpecialNodeScore(node)
    local bonusName = {"m_lb_score_yin","m_lb_score_jin","m_lb_mini","m_lb_minor","m_lb_mijor"}
    local symbolNode = node
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    local coinsView
    coinsView = util_createAnimation("Socre_WestRanger_Bonus_coin.csb")
    util_spinePushBindNode(symbolNode,"text",coinsView)

    --根据网络数据获取停止滚动时respin小块的分数
    local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    local index = 0
    if score ~= nil then
        local lineBet = globalData.slotRunData:getCurTotalBet()

        for i,vName in ipairs(bonusName) do
            coinsView:findChild(vName):setVisible(false)
        end
        if score == "mini" then--mini
            coinsView:findChild("m_lb_mini"):setVisible(true)
        elseif score == "minor" then--minor
            coinsView:findChild("m_lb_minor"):setVisible(true)
        elseif score == "major" then--major
            coinsView:findChild("m_lb_mijor"):setVisible(true)
        else
            score = score * lineBet
            score = util_formatCoins(score, 3)
            coinsView:findChild("m_lb_score_jin"):setVisible(true)
            coinsView:findChild("m_lb_score_jin"):setString(score)
        end
    end
end

function CodeGameScreenWestRangerMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_BONUS1 or symbolType == self.SYMBOL_BONUS2 then
        self:setSpecialNodeScore(self,{node})
    end

    -- videoPoker收集添加角标
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local iconLocs = selfdata.iconLocs or {}
    self.m_videoPokeMgr:createVideoPokerIcon(node,self,iconLocs )
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWestRangerMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWestRangerMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILDBIG,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BLANK,count =  2} 

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenWestRangerMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS1 or 
        symbolType == self.SYMBOL_BONUS2 then
        return true
    end
    return false
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenWestRangerMachine:levelFreeSpinEffectChange()
    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenWestRangerMachine:levelFreeSpinOverChangeEffect()
    
end
---------------------------------------------------------------------------

-- 触发freespin时调用
function CodeGameScreenWestRangerMachine:showFreeSpinView(effectData)
    if effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:triggerFreeSpinCallFun()
                self.m_FreespinBarView:setVisible(true)
                self.m_FreespinBarView:runCsbAction("start",false,function()
                    self.m_FreespinBarView:runCsbAction("idleframe",true)
                end)
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        else
            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_freeSpinMorePopup.mp3")
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        end
    else
        -- 界面选择回调
        local function chooseCallBack(index)
            self:sendData(index)
            self.m_bIsSelectCall = true
            self.m_iSelectID = index
            self.m_gameEffect = effectData
        end

        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            scheduler.performWithDelayGlobal(function()
                self:showFreatureChooseView( chooseCallBack)
            end, 0.7, self:getModuleName())
        else
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            scheduler.performWithDelayGlobal(function()
                gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_freeSpinMorePopup.mp3")
                self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,true)
            end, 0.8, self:getModuleName())
        end
    end
end

-- 点击界面 发送消息
function CodeGameScreenWestRangerMachine:sendData(index)
    if self.m_isLocalData then
    else
        local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = {select = index}}
        local httpSendMgr = SendDataManager:getInstance()
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end

--spin结果
function CodeGameScreenWestRangerMachine:spinResultCallFun(param)
    CodeGameScreenWestRangerMachine.super.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        if param[1] == true then
            if param[2] and param[2].result then
                globalData.slotRunData.freeSpinCount = param[2].result.freespin.freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = param[2].result.freespin.freeSpinsTotalCount

                self:showFreeSpinStart(globalData.slotRunData.totalFreeSpinCount,function()
                    self:playChangeGuoChang(function()
                        self.m_gameBg:runCsbAction("bace_free",false,function()
                            self:setReelBg(2)
                        end)
                    end,function()
                        self.m_iOnceSpinLastWin = 0
                        self:triggerFreeSpinCallFun()
                        self.m_FreespinBarView:setVisible(true)
                        self.m_FreespinBarView:runCsbAction("start",false,function()
                            self.m_FreespinBarView:runCsbAction("idleframe",true)
                        end)

                        self.m_gameEffect.p_isPlay = true
                        self:playGameEffect() 
                    end)
                end)

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Stop,false})
            end
        end
    end
    self.m_bIsSelectCall = false
    if param[1] == true then
        if param[2] and param[2].result then
            local spinData = param[2]
            if spinData.action == "SPIN" then
                if self:getCurrSpinMode() == RESPIN_MODE then
                    if spinData.result.respin and spinData.result.respin.extra and spinData.result.respin.extra.reel0 then
                        local resultDatas = spinData.result.respin.extra
                        for miniIndex = 1, 4 do
                            local mninReel = self.m_miniMachine[miniIndex]
                            local dataName = "reel".. (miniIndex -1)

                            local miniReelsResultDatas = resultDatas[dataName]
                            spinData.result.reels = miniReelsResultDatas.reels
                            spinData.result.storedIcons = miniReelsResultDatas.storedIcons
                            spinData.result.jackpotLoc = miniReelsResultDatas.jackpotLoc

                            mninReel:netWorkCallFun(spinData.result)
                        end
                    end
                end
            end
        end
    end

    -- 处理bonus消息返回
    self:videoPokerResultCallFun(param)
end

--增加新手任务进度
function CodeGameScreenWestRangerMachine:checkIncreaseNewbieTask()
    local sysNoviceTaskMgr = G_GetMgr(G_REF.SysNoviceTask)
    if sysNoviceTaskMgr and sysNoviceTaskMgr:checkEnabled() then
        -- 新版 服务器会同步增加， 不需要客户端自己记录计算
        return
    end

    globalNewbieTaskManager:increasePool(NewbieTaskType.spin_count, 1, self.m_moduleName)
    if self.m_spinIsUpgrade and self.m_upgradePreLevel then
        globalNewbieTaskManager:increasePool(NewbieTaskType.reach_level, self.m_spinNextLevel - self.m_upgradePreLevel, self.m_moduleName)
    end
    local taskData = globalNewbieTaskManager:getCurrentTaskData()
    if taskData and taskData:checkUnclaimed() then
        if self.m_spinIsUpgrade then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPLEVEL_STATUS, {level = self.m_spinNextLevel, type = 1})
        end
        self:addAnimationOrEffectType(GameEffect.EFFECT_NEWBIETASK_COMPLETE)
    end
end

-- 显示bonus 触发的小游戏
function CodeGameScreenWestRangerMachine:showEffect_Bonus(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- gLobalSoundManager:setLockBgMusic(false)
    -- 停掉背景音乐
    self:clearCurMusicBg()
    if scatterLineValue ~= nil then
        -- 播放震动
        if self.levelDeviceVibrate then
            -- freeMore时不播放
            self:levelDeviceVibrate(6, "bonus")
        end
        performWithDelay(self, function()
            self:showBonusAndScatterLineTip(scatterLineValue,function()

                self:showFreeSpinView(effectData)
            end)
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        end, 0.2)
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

-- 二选一界面
function CodeGameScreenWestRangerMachine:showFreatureChooseView(func)
	local view = util_createView("CodeWestRangerSrc.WestRangerFeatureChooseView")

    view:initViewData(self, func, function()
        self:levelFreeSpinEffectChange()
    end)
    self:addChild(view, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
end

-- 触发freespin结束时调用
function CodeGameScreenWestRangerMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:playChangeGuoChang(function()
                self.m_FreespinBarView:setVisible(false)
                self.m_gameBg:runCsbAction("free_bace",false,function()
                    self:setReelBg(1)
                end)
            end,function()
                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:triggerFreeSpinOverCallFun()
            end)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},794)

end

function CodeGameScreenWestRangerMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeWestRangerSrc.WestRangerJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self,index,coins,func)
end

-- respin 相关
function CodeGameScreenWestRangerMachine:showRespinView()
    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if self:isFixSymbol(node.p_symbolType) then
                    local symbolNode = util_setSymbolToClipReel(self,iCol, iRow, node.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                    curBonusList[#curBonusList + 1] = node
                end
            end
        end
    end
    for _, _bonusNode in ipairs(curBonusList) do
        _bonusNode:runAnim("actionframe",false,function (  )
            _bonusNode:runAnim("idleframe",true)
            local symbol_node = _bonusNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            if spineNode.m_csbNodeSaoGuang then
                spineNode.m_csbNodeSaoGuang:runCsbAction("saoguang",true)
            end
        end)
    end
    gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinProcessAni.mp3")
    self:waitWithDelay(nil,function()
        self:showReSpinStart(function()
            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinTrans.mp3")
            self:playReSpinChangeGuoChang(function()
                if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                    self:findChild("Node_0"):setVisible(false)
                    -- 显示respin相关节点
                    self:findChild("Node_2"):setVisible(true)
                    self:setReelBg(3)
                else
                    self:findChild("Node_0"):setVisible(false)
                    -- 显示respin相关节点
                    self:findChild("Node_2"):setVisible(true)
                    self:setReelBg(3)
                end
                
                self:setCurrSpinMode(RESPIN_MODE)

                --清空赢钱
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN) 
                
                for miniIndex = 1, 4 do
                    self.m_miniMachine[miniIndex]:initMiniReelData(self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)])
                    local suolianType = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)].status
                    
                    if self.m_runSpinResultData.p_rsExtraData.kind == "special" then
                        self.m_miniMachine[miniIndex].m_suolian:setVisible(false)
                    else
                        if miniIndex ~= 1 then
                            self.m_miniMachine[miniIndex].m_suolian:setVisible(true)
                            self.m_miniMachine[miniIndex].m_suolian:runCsbAction("idle",true)
                            local num = self.m_runSpinResultData.p_rsExtraData.collectRequest[miniIndex]-self.m_runSpinResultData.p_rsExtraData.curCollect
                            if num < 0 then
                                num = 0
                            end
                            self.m_miniMachine[miniIndex].m_suolian:findChild("m_lb_num"):setString(num)
                        end
                    end

                    self:waitWithDelay(nil,function()
                        self.m_miniMachine[miniIndex]:showOrCloseSuoLian(suolianType,self.m_runSpinResultData.p_rsExtraData.collectRequest[miniIndex]-self.m_runSpinResultData.p_rsExtraData.curCollect)
                    end,1)

                    self.m_miniMachine[miniIndex]:showRespinView()
                end
            end,function()
            end)
        end)
    end,2)
end

function CodeGameScreenWestRangerMachine:showReSpinStart(func)
    local respinType = self.m_runSpinResultData.p_rsExtraData.kind
    if respinType == "special" then
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_showRespinStartSpecial.mp3")
        local view = self:showDialog("SuperRespinStart",nil,func,true)
        local smallSuoLian = {}
        for smallSuoLianIndex = 1, 3 do
            smallSuoLian[smallSuoLianIndex] = util_createAnimation("WestRanger_tanban_Suolian.csb")
            view:findChild("suolian_"..smallSuoLianIndex):addChild(smallSuoLian[smallSuoLianIndex])
            smallSuoLian[smallSuoLianIndex]:runCsbAction("idle",false)
        end
        view:findChild("Button"):setTouchEnabled(false)
        view:findChild("Button"):setBright(false)

        self:waitWithDelay(nil,function()
            for smallSuoLianIndex = 1, 3 do
                smallSuoLian[smallSuoLianIndex]:runCsbAction("actionframe",false,function()
                    view:findChild("Button"):setTouchEnabled(true)
                    view:findChild("Button"):setBright(true)
                end)
            end
        end, 40/60)
    else
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_showRespinStartDialog.mp3")
        self:showDialog("RespinStart",nil,func,true)
    end
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWestRangerMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume()

    return false -- 用作延时点击spin调用
end

function CodeGameScreenWestRangerMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
       self:playEnterGameSound( "WestRangerSounds/sound_WestRanger_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenWestRangerMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWestRangerMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    -- videoPoker添加ui
    self:addVideoPokerUI( )

    self:videoPoker_initGame()
end

function CodeGameScreenWestRangerMachine:addObservers()
	CodeGameScreenWestRangerMachine.super.addObservers(self)

end

function CodeGameScreenWestRangerMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWestRangerMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function CodeGameScreenWestRangerMachine:playCustomSpecialSymbolDownAct( slotNode )
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        if slotNode and  self:isFixSymbol(slotNode.p_symbolType) then
            slotNode:runAnim("buling",false,function()
                slotNode:runAnim("idleframe",true)
                local symbol_node = slotNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                if spineNode.m_csbNodeSaoGuang then
                    spineNode.m_csbNodeSaoGuang:runCsbAction("saoguang",true)
                end
            end)
        end
    end
end

--将图标提到clipParent层
function CodeGameScreenWestRangerMachine:setSymbolToClip(_MainClass, _iCol, _iRow, _type, _zorder)
    local targSp = _MainClass:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = _MainClass:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(_MainClass, index)
        local showOrder = _MainClass:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        targSp:removeFromParent()
        _MainClass.m_clipParent:addChild(targSp, _zorder + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))

    end
    return targSp
end

function CodeGameScreenWestRangerMachine:beginReel()
    CodeGameScreenWestRangerMachine.super.beginReel(self)
    self.m_configData.m_isFirstComeIn = false
    self.m_isDuanXian = false
    self.m_isTriggerLongRun = false
    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end
end

-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWestRangerMachine:addSelfEffect()

    -- base下 3个连续的wild 并且参与连线
    if #self.m_wildContinusPos > 0 then -- 触发了小格子变化大格子effect
        self.m_preWildContinusPos = self.m_wildContinusPos
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_selfEffectType = self.m_changeBigSymbolEffect
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    end

    -- free下 wild上下移动
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and #self.m_aFreeSpinWildArry > 0 then
        local wildChangeEffect = GameEffectData.new()
        wildChangeEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        wildChangeEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        wildChangeEffect.p_selfEffectType = self.m_freeSpinWildChange
        self.m_gameEffects[#self.m_gameEffects + 1] = wildChangeEffect
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWestRangerMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.m_changeBigSymbolEffect then
        self:baseChangeBigWild(function()
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end)
    end

    if effectData.p_selfEffectType == self.m_freeSpinWildChange then
        self:freeSpinWildChange(function()
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end)
    end
    
	return true
end

-- base下变大wild
function CodeGameScreenWestRangerMachine:baseChangeBigWild(_func)
    local isPlaySound = false
    for wildMoveIndex = 1, #self.m_preWildContinusPos do
        local wildChangeData = self.m_preWildContinusPos[wildMoveIndex]
        local bigWild = nil

        local maxZOrder = 0
        local nodeList = {}
        for rowIndex = 1, self.m_iReelRowNum , 1 do
            local node =  self:getFixSymbol(wildChangeData.iY , rowIndex, SYMBOL_NODE_TAG)
            if node ~= nil then -- 移除被覆盖度额小块
                table.insert(nodeList,node)
                if maxZOrder <  node:getLocalZOrder() then
                    maxZOrder = node:getLocalZOrder()
                end
            end
        end

        -- 把这一列的长条信息添加到存储数据中
        self:addBigSymbolInfo( wildChangeData.iY )

        if wildChangeData.len == 3 then
            bigWild = self:getSlotNodeWithPosAndType(self.SYMBOL_WILDBIG,wildChangeData.iX,wildChangeData.iY)
        end

        bigWild.m_bInLine = true

        local linePos = {}
        for lineRowIndex = 1, wildChangeData.len do
            linePos[#linePos + 1] = {
                iX = wildChangeData.iX + (lineRowIndex - 1),
                iY = wildChangeData.iY
            }
        end

        bigWild:setLinePos(linePos)

        local targSp = self:getFixSymbol(wildChangeData.iY, wildChangeData.iX, SYMBOL_NODE_TAG)

        local reelParent = self:getReelParent(wildChangeData.iY)

        reelParent:addChild(bigWild, wildChangeData.len + targSp:getLocalZOrder(), targSp:getTag())
        bigWild:setPosition(targSp:getPositionX(), targSp:getPositionY())

        for index=1,#nodeList do
            local node = nodeList[index]
            if node then
                self:moveDownCallFun(node, node.p_cloumnIndex) 
            end
            
        end

        if not isPlaySound then
            isPlaySound = true
            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_baseWildSwitch.mp3")
        end

        bigWild:runAnim("switch1",false,function()
            if wildMoveIndex == #self.m_preWildContinusPos then
                self:waitWithDelay(nil,function()
                    if _func then
                        _func()
                    end
                end, 0.5)
            end
        end)
    end
end

-- freeSpin wild change
function CodeGameScreenWestRangerMachine:freeSpinWildChange(_func)
    local delayTime = 0.5
    local runTime = 0.5 
    local isPlaySound = false
    for freeWildMoveIndex = 1, #self.m_aFreeSpinWildArry, 1 do
        local temp = self.m_aFreeSpinWildArry[freeWildMoveIndex]
        local iRow = temp.row
        local iCol = temp.col
        local currRow = iRow
        
        local iTempRow = {} --隐藏小块避免穿帮
        if temp.direction == "up" then --    4,3,2 
            currRow =  temp.row + 1 - 3
        end

        local maxZOrder = 0
        local nodeList = {}
        for rowIndex = 1, self.m_iReelRowNum , 1 do
            local node =  self:getFixSymbol(iCol , rowIndex, SYMBOL_NODE_TAG)
            if node ~= nil and node.p_symbolType ~= 92 then -- 移除被覆盖度额小块
                table.insert(nodeList,node)
                if maxZOrder <  node:getLocalZOrder() then
                    maxZOrder = node:getLocalZOrder()
                end
            end
            if node ~= nil and node.p_symbolType == 92 then
                self:moveDownCallFun(node, node.p_cloumnIndex) 
            end
        end

        -- 把这一列的长条信息添加到存储数据中
        self:addBigSymbolInfo( iCol )

        local posIndex = self:getPosReelIdx(currRow, iCol)
        local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_WILDBIG, currRow, iCol, false)   
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
            self:getReelParent(iCol):addChild(targSp,maxZOrder, targSp.p_cloumnIndex * SYMBOL_NODE_TAG + targSp.p_rowIndex)
            targSp.p_rowIndex = 1
            
            local pos =  cc.p(self:getPosByColAndRow(iCol, currRow))
            local posEnd =  cc.p(self:getPosByColAndRow(iCol,1))
            if temp.direction == "up" then 
                posEnd =  cc.p(self:getPosByColAndRow(iCol, 1))
            end

            targSp:setPosition(pos)
            local distance = posEnd.y
            local actionList = {}
            actionList[#actionList + 1] = cc.MoveTo:create(runTime, cc.p(posEnd.x, posEnd.y))
            actionList[#actionList + 1] = cc.CallFunc:create(function ()
                for index = 1, #nodeList do
                    local node = nodeList[index]
                    if node then
                        self:moveDownCallFun(node, node.p_cloumnIndex) 
                    end
                end

                if freeWildMoveIndex == #self.m_aFreeSpinWildArry then
                    self:waitWithDelay(nil,function()
                        if _func then
                            _func()
                        end
                    end, 0.5)
                end
            end)

            targSp:runAnim("switch2")
            local seq = cc.Sequence:create(actionList)
            targSp:runAction(seq)

            if not isPlaySound then
                isPlaySound = true
                gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_baseWildSwitch.mp3")
            end
        end
    end
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWestRangerMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
    local bonusType = self.m_runSpinResultData.p_selfMakeData.bonusKind or nil
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            -- 假滚数据
            local parentData = self.m_slotParents[iCol]
            if parentData and parentData.reelDatas then
                -- 替换为配置假滚 或者 相同信号假滚
                for index = 1, #parentData.reelDatas do
                    if bonusType == "normal" then
                        if parentData.reelDatas[index] == self.SYMBOL_BONUS2 then
                            parentData.reelDatas[index] = self.SYMBOL_BONUS1
                        end
                    elseif bonusType == "special" then
                        if parentData.reelDatas[index] == self.SYMBOL_BONUS1 then
                            parentData.reelDatas[index] = self.SYMBOL_BONUS2
                        end
                    end
                end
            end
        end
    end
end


function CodeGameScreenWestRangerMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenWestRangerMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenWestRangerMachine:slotReelDown( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName == "idleframe2" then
                local ccbNode = symbolNode:getCCBNode()
                if ccbNode then
                    util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idleframe", 0.5)
                end
                symbolNode:runAnim("idleframe", true)
            end
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenWestRangerMachine.super.slotReelDown(self)
end

function CodeGameScreenWestRangerMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenWestRangerMachine:checkPosInLine(pos)
    for linesIndex = 1, #self.m_runSpinResultData.p_winLines do
        local winLine = self.m_runSpinResultData.p_winLines[linesIndex]
        for index = 1, #winLine.p_iconPos do
            local posInLine = self:getRowAndColByPos(winLine.p_iconPos[index])
            if posInLine.iX == pos.iX and posInLine.iY == pos.iY then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenWestRangerMachine:MachineRule_network_InterveneSymbolMap()
    self.m_wildContinusPos = {}
    --获取所有相邻的wild 坐标合集
    -- base查找连续3个wild 并且参与连线
    for iCol = 1, self.m_iReelColumnNum do
        local seriesPos = {}
        for iRow = 1, self.m_iReelRowNum do
            if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local checkPos = {iX = iRow, iY = iCol}
                local inLine = self:checkPosInLine(checkPos)
                if inLine == true then
                    -- 第一个添加进来的或者与上一个相邻则添加到被检索列表
                    if #seriesPos == 0 or seriesPos[#seriesPos].iX + 1 == iRow then
                        seriesPos[#seriesPos + 1] = checkPos
                    end
                end
            end
        end -- end for row

        if #seriesPos == 1 then
            seriesPos[1] = 0
        elseif #seriesPos >= 3 then
            self.m_wildContinusPos[#self.m_wildContinusPos + 1] = {
                iX = seriesPos[1].iX,
                iY = seriesPos[#seriesPos].iY,
                len = #seriesPos
            }
        end
    end -- end for column

    -- free wild上下移动
    for i = #self.m_aFreeSpinWildArry, 1, -1 do
        table.remove(self.m_aFreeSpinWildArry, i)
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        for iCol = 1, self.m_iReelColumnNum do --列
            local tempRow = nil
            for iRow = self.m_iReelRowNum, 1, -1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    tempRow = iRow
                else
                    break
                end
            end
            if tempRow ~= nil and tempRow ~= 1 then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "down"}
            end

            tempRow = nil
            for iRow = 1, self.m_iReelRowNum, 1 do --行
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


function CodeGameScreenWestRangerMachine:addBigSymbolInfo( icol )
    local iColumn = self.m_iReelColumnNum
    local iRow = self.m_iReelRowNum

    if not self.m_bigSymbolColumnInfo then
        self.m_bigSymbolColumnInfo = {}
    end

    local rowIndex=1
    while true do
        if rowIndex > iRow then
            break
        end
        local symbolType = self.SYMBOL_WILDBIG
        -- 判断是否有大信号内容
        if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil  then

            local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG,changeRows = {}}
            
            local colDatas = self.m_bigSymbolColumnInfo[icol]
            if colDatas == nil then
                colDatas = {}
                self.m_bigSymbolColumnInfo[icol] = colDatas
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

function CodeGameScreenWestRangerMachine:getPosByColAndRow(col, row)
    local posX = self.m_SlotNodeW
    local posY = (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

--设置bonus scatter 层级
function CodeGameScreenWestRangerMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.SYMBOL_BONUS1 or symbolType == self.SYMBOL_BONUS2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif  symbolType == self.SYMBOL_WILDBIG then
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


---------------------------------弹版----------------------------------
function CodeGameScreenWestRangerMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if num == 9 then
        ownerlist["m_lb_num_1"] = 6
    elseif num == 6 then
        ownerlist["m_lb_num_1"] = 5
    elseif num == 3 then
        ownerlist["m_lb_num_1"] = 4
    end

    gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_freeSpinStartPopup.mp3")
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end


-- 延时函数
function CodeGameScreenWestRangerMachine:waitWithDelay(parent, endFunc, time)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

---判断结算
function CodeGameScreenWestRangerMachine:reSpinSelfReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    self:setGameSpinStage(STOP_RUN)
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        for miniIndex = 1, 4 do
            self.m_miniMachine[miniIndex].m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        end
        --quest
        self:updateQuestBonusRespinEffectData()

        for miniIndex = 1, 4 do
            --结束
            self.m_miniMachine[miniIndex]:reSpinEndAction()
        end
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false
        return
    end

    local waitTime = 0.1
    local waitTimeDelay = 0
    local jiesuoMiniIndex = {}
    local isTeshuIsle = false

    for miniIndex = 1, 4 do
        self.m_miniMachine[miniIndex].m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        local suolianType = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)].status
        local isWaitTime = self.m_miniMachine[miniIndex]:showOrCloseSuoLian(suolianType,self.m_runSpinResultData.p_rsExtraData.collectRequest[miniIndex]-self.m_runSpinResultData.p_rsExtraData.curCollect)
        
        if isWaitTime then
            table.insert(jiesuoMiniIndex, miniIndex)
            waitTime = 60/60 
            waitTimeDelay = 70/60+0.1
        end 
        if suolianType == "open" then
            if #self.m_miniMachine[miniIndex].cacheNodeMap > 0 then
                isTeshuIsle = true
            end
        end
    end

    if isTeshuIsle then
        waitTime = waitTime + 20/30
    end

    for miniIndex = 1, 4 do
        self:waitWithDelay(nil,function(  )
            local isShowJiesuo = false
            local chipList = self.m_miniMachine[miniIndex].m_respinView:getAllCleaningNode()  
            local suolianType = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)].status 
            if #jiesuoMiniIndex > 0 then
                for _, _jiesuoIndex in ipairs(jiesuoMiniIndex) do
                    if _jiesuoIndex == miniIndex then
                        isShowJiesuo = true
                        for _, vNode in ipairs(chipList) do
                            self:setRespinNodeZOrder(miniIndex, vNode, true)
                            vNode:runAnim("teshubuling",false,function()
                                self:setRespinNodeZOrder(miniIndex, vNode, false)
                            end)
                        end
                    end
                end
            end

            if not isShowJiesuo then
                for _, _mapInfo in ipairs(self.m_miniMachine[miniIndex].cacheNodeMap) do
                    for _, vNode in ipairs(chipList) do
                        if _mapInfo.row == vNode.p_rowIndex and _mapInfo.clo == vNode.p_cloumnIndex then
                            if suolianType == "open" then
                                self:setRespinNodeZOrder(miniIndex, vNode, true)
                                vNode:runAnim("teshubuling",false,function()
                                    self:setRespinNodeZOrder(miniIndex, vNode, false)
                                end)
                            end
                        end
                    end
                end
                self.m_miniMachine[miniIndex].cacheNodeMap = {}
            end
        end,waitTimeDelay)
    end

    self:waitWithDelay(nil,function(  )
        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            if self.m_runSpinResultData.p_reSpinCurCount >= 3 then
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
            else
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,false)
            end
        end
    end,waitTimeDelay)

    self:waitWithDelay(nil,function(  )
        --继续
        for miniIndex = 1, 4 do
            self.m_miniMachine[miniIndex]:runNextReSpinReel()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end, waitTime)
end

--结束移除小块调用结算特效
function CodeGameScreenWestRangerMachine:reSpinEndAction()    
    
    self:clearCurMusicBg() 
    self.m_maxIndexMini = 1--固定小块最多的mini盘
    local maxNodeNumMini = 0--固定小块的个数

    self.m_respin_jiesuan:setVisible(true)
    self.m_respin_jiesuan:findChild("BitmapFontLabel_1"):setString("")
    self.m_respin_jiesuan:runCsbAction("start",false,function()
        for miniIndex = 1, 4 do
            local suolianType = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)].status
            if suolianType == "open" then
                if maxNodeNumMini < #self.m_miniMachine[miniIndex].m_chipList then
                    maxNodeNumMini = #self.m_miniMachine[miniIndex].m_chipList
                    self.m_maxIndexMini = miniIndex
                end
                
            end
        end
        for miniIndex = 1, 4 do
            local suolianType = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)].status
            if suolianType == "open" then
                self:waitWithDelay(nil,function(  )
                    self:playChipCollectAnim(miniIndex, true)
                end,1/60)
            end
        end
    end)
end

function CodeGameScreenWestRangerMachine:playChipCollectAnim(indexMini, isPlay)
    if self.m_curIsJackpotMiniIndex or self.m_isJieSuanOver then
        return
    end
    local jiesuoIndex = 1
    local isJiesuan = {}
    for miniIndex = 1, 4 do
        local suolianType = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)].status
        if suolianType == "open" then
            jiesuoIndex = miniIndex
        end
    end
    for index = 1, jiesuoIndex do
        isJiesuan[index] = false
        if self.m_miniMachine[index].m_playAnimIndex > #self.m_miniMachine[index].m_chipList then
            isJiesuan[index] = true
        end
    end
    local isJiesuanOver = true
    for index = 1, jiesuoIndex do
        if not isJiesuan[index] then
            isJiesuanOver = false
        end
    end
    if isJiesuanOver then
        self.m_isJieSuanOver = true
        -- 此处跳出迭代
        self:playLightEffectEnd(indexMini)
        return 
    end

    if self.m_miniMachine[indexMini].m_playAnimIndex > #self.m_miniMachine[indexMini].m_chipList then
        return
    end

    local chipNode = self.m_miniMachine[indexMini].m_chipList[self.m_miniMachine[indexMini].m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self:findChild("bonusNewNode"):convertToNodeSpace(nodePos)
    local oldParent = chipNode:getParent()
    local oldPosition = cc.p(chipNode:getPosition())
    local oldZOrder = chipNode:getZOrder()
    util_changeNodeParent(self:findChild("bonusNewNode"),chipNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - chipNode.p_rowIndex)
    -- chipNode:setTag(self.REPIN_NODE_TAG)
    chipNode:setPosition(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    -- 根据网络数据获得当前固定小块的分数
    local score = self.m_miniMachine[indexMini]:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "grand" then
            jackpotScore = self:BaseMania_getJackpotScore(1)
            addScore = jackpotScore + addScore
            nJackpotType = 4
            self.m_curIsJackpotMiniIndex = true
        elseif score == "major" then
            jackpotScore = self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 3
            self.m_curIsJackpotMiniIndex = true
        elseif score == "minor" then
            jackpotScore =  self:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                  ---self:BaseMania_getJackpotScore(3)
            nJackpotType = 2
            self.m_curIsJackpotMiniIndex = true
        elseif score == "mini" then
            jackpotScore = self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                      ---self:BaseMania_getJackpotScore(4)
            nJackpotType = 1
            self.m_curIsJackpotMiniIndex = true
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if nJackpotType == 0 then
            self.m_miniMachine[indexMini].m_playAnimIndex = self.m_miniMachine[indexMini].m_playAnimIndex + 1
            self:playChipCollectAnim(indexMini,isPlay) 
        else
            self:showRespinJackpot(nJackpotType, jackpotScore, function()
                self.m_curIsJackpotMiniIndex = false
                self.m_miniMachine[indexMini].m_playAnimIndex = self.m_miniMachine[indexMini].m_playAnimIndex + 1

                self.m_jackPotBarRespin:runCsbAction("idle",false)

                for miniIndex = 1, 4 do
                    local suolianType = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)].status
                    if suolianType == "open" then
                        self:waitWithDelay(nil,function(  )
                            self:playChipCollectAnim(miniIndex, true)
                        end,1/60)
                    end
                end
            end)
        end
    end  
    
    local symbol_node = chipNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()

    if type(score) ~= "string" then
        if spineNode.m_csbNodeSaoGuang then
            spineNode.m_csbNodeSaoGuang:setVisible(false)
            spineNode.m_csbNodeSaoGuang:removeFromParent()
            spineNode.m_csbNodeSaoGuang = nil
        end
        chipNode:runAnim("shouji",false,function()
            util_changeNodeParent(oldParent,chipNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - chipNode.p_rowIndex)
            chipNode:setPosition(oldPosition)
        end)
        self:waitWithDelay(nil,function(  )
            self:flyCollectCoin(chipNode, function ()
                runCollect()    
            end,isPlay,addScore)
        end,4/30)
    else
        if spineNode.m_csbNodeSaoGuang then
            spineNode.m_csbNodeSaoGuang:setVisible(false)
            spineNode.m_csbNodeSaoGuang:removeFromParent()
            spineNode.m_csbNodeSaoGuang = nil
        end

        self.m_jackPotBarRespin:runCsbAction("actionframe"..nJackpotType,true)

        chipNode:runAnim("teshushouji",false,function()
            util_changeNodeParent(oldParent,chipNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - chipNode.p_rowIndex)
            chipNode:setPosition(oldPosition)
        end)
        self:waitWithDelay(nil,function(  )
            self:flyCollectCoin(chipNode, function ()
                runCollect()    
            end,isPlay,addScore)
        end,10/30)
    end
end

function CodeGameScreenWestRangerMachine:setRespinNodeZOrder(machineIndex, chipNode, isUp)--isup表示 提层
    local isUpNode = "bonusNewNode" --提层的节点
    if self.m_miniMachine[machineIndex].m_suolian:isVisible() then
        isUpNode = "bonusNewNode1"
    end
    if isUp then
        local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
        nodePos = self:findChild(isUpNode):convertToNodeSpace(nodePos)
        chipNode.oldParent = chipNode:getParent()
        chipNode.oldPosition = cc.p(chipNode:getPosition())
        chipNode.oldZOrder = chipNode:getZOrder()
        util_changeNodeParent(self:findChild(isUpNode),chipNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - chipNode.p_rowIndex)
        chipNode:setPosition(nodePos)
    else
        util_changeNodeParent(chipNode.oldParent,chipNode,chipNode.oldZOrder)
        chipNode:setPosition(chipNode.oldPosition)
    end
end

-- 收集金币
function CodeGameScreenWestRangerMachine:flyCollectCoin(startNode, func, isPlay, addScore)

    -- gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_JieSuan.mp3")

    local fly = util_createAnimation("Socre_WestRanger_Respin_shoujixian.csb")
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local endworldPos = self.m_respin_jiesuan:getParent():convertToWorldSpace(cc.p(self.m_respin_jiesuan:getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endworldPos))

    local startWorldPos = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local startPos =  self:convertToNodeSpace(cc.p(startWorldPos))


    local angle = util_getAngleByPos(startPos,endPos)
    fly:findChild("Node_1"):setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
    fly:findChild("Node_1"):setScaleX(scaleSize / 350 )

    fly:setPosition(startPos)

    fly:runCsbAction("shouji")
    
    if isPlay then
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinCollectLineBegin.mp3")
    end
    performWithDelay(fly,function ()
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
        end

        if isPlay then
            self:jumpCoins(self.m_lightScore, addScore)
            self.m_respin_jiesuan:runCsbAction("shouji")

            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinCollectLineEnd.mp3")
        end

        if func then
            func()
        end

        fly:stopAllActions()
        fly:removeFromParent()
    end,22/60)
end

-- 结算的时候 金币滚动
function CodeGameScreenWestRangerMachine:jumpCoins(coins, addScore)
    if coins == addScore then
        addScore = 0
    end
    local node = self.m_respin_jiesuan:findChild("BitmapFontLabel_1")
    node:setString(util_formatCoins(coins - addScore,30))
    self.m_respin_jiesuan:updateLabelSize({label=node,sx=0.54,sy=0.54},794)

    local coinRiseNum =  (coins - addScore) / (0.3 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = coins - addScore


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self.m_respin_jiesuan:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(curCoins,30))
            self.m_respin_jiesuan:updateLabelSize({label=node,sx=0.54,sy=0.54},794)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self.m_respin_jiesuan:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(curCoins,30))
            self.m_respin_jiesuan:updateLabelSize({label=node,sx=0.54,sy=0.54},794)
        end
    end)
end

-- mini轮盘集满15个效果
function CodeGameScreenWestRangerMachine:playMiniCollectJiMan(_fun,_index)
    local jimanData = self.m_runSpinResultData.p_rsExtraData.fullReel
    if jimanData then
        if jimanData[_index] then

            local miniReelIndex = string.sub(jimanData[_index].type,5,string.len(jimanData[_index].type)) + 1
            self.m_miniMachineBianKaung[miniReelIndex]:setVisible(true)--集满边框

            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinSpecialFull.mp3")

            for index, chipNode in ipairs(self.m_miniMachine[miniReelIndex].m_chipList) do
                local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
                nodePos = self:findChild("bonusNewNode"):convertToNodeSpace(nodePos)
                local oldParent = chipNode:getParent()
                local oldPosition = cc.p(chipNode:getPosition())
                local oldZOrder = chipNode:getZOrder()
                util_changeNodeParent(self:findChild("bonusNewNode"),chipNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - chipNode.p_rowIndex)
                chipNode:setPosition(nodePos)

                chipNode:runAnim("jiman",false,function()
                    util_changeNodeParent(oldParent,chipNode,oldZOrder)
                    chipNode:setPosition(oldPosition)
                    if index == #self.m_miniMachine[miniReelIndex].m_chipList then
                        self.m_miniMachineBianKaung[miniReelIndex]:setVisible(false)--集满边框
                    end
                end)
            end

            self.m_jackPotBarRespin:runCsbAction("actionframe4",true)

            self:waitWithDelay(nil,function(  )
                local jackpotScore = self:BaseMania_getJackpotScore(1)
                self.m_lightScore = self.m_lightScore + jackpotScore
                self.m_respin_jiesuan:findChild("BitmapFontLabel_1"):setString(util_formatCoins(self.m_lightScore,30))
                local node=self.m_respin_jiesuan:findChild("BitmapFontLabel_1")
                self.m_respin_jiesuan:updateLabelSize({label=node,sx=0.54,sy=0.54},794)
                
                self:showRespinJackpot(
                    4,
                    jackpotScore,
                    function()
                        self.m_jackPotBarRespin:runCsbAction("idle",false)
                        self:playMiniCollectJiMan(_fun, _index+1) 
                    end
                )
            end,80/60)
            
        else
            if _fun then
                _fun()
            end
        end
    else
        if _fun then
            _fun()
        end
    end
end

-- 结束respin收集
function CodeGameScreenWestRangerMachine:playLightEffectEnd(indexMini)
    self:waitWithDelay(nil,function(  )
        self:playMiniCollectJiMan(function()
            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinOverCelebrate.mp3")
            self.m_respin_jiesuan_qingzhu:setVisible(true)
            self.m_respin_jiesuan:runCsbAction("idle",false)
            self.m_respin_jiesuan_qingzhu:runCsbAction("actionframe",false,function()
                self:waitWithDelay(nil,function(  )
                    -- 通知respin结束
                    self:respinOver()
                end,0.5)
                
            end)
            self:waitWithDelay(nil,function(  )
                local littleEf_1 = self.m_respin_jiesuan_qingzhu:findChild("Particle_1")
                local littleEf_2 = self.m_respin_jiesuan_qingzhu:findChild("Particle_1_0")
                littleEf_1:resetSystem()
                littleEf_2:resetSystem()
            end,28/60)
        end,1)
    end,30/60)
end

function CodeGameScreenWestRangerMachine:respinOver()
    
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:showRespinOverView()
end

function CodeGameScreenWestRangerMachine:showRespinOverView(effectData)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    local node=self.m_respin_jiesuan:findChild("BitmapFontLabel_1")
    node:setString(util_formatCoins(self.m_lightScore,30))
    self.m_respin_jiesuan:updateLabelSize({label=node,sx=0.54,sy=0.54},794)

    local strCoins=util_formatCoins(self.m_serverWinCoins,30)
    local view=self:showReSpinOver(strCoins,function()
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinTransOver.mp3")
        self:playReSpinChangeGuoChang(function()
            
            if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                self:findChild("Node_0"):setVisible(true)
                -- 显示respin相关节点
                self:findChild("Node_2"):setVisible(false)
                self:setReelBg(1)
            else
                self:findChild("Node_0"):setVisible(true)
                -- 显示respin相关节点
                self:findChild("Node_2"):setVisible(false)
                self:setReelBg(2)
            end

            for miniIndex = 1, 4 do
                self.m_miniMachine[miniIndex]:setReelSlotsNodeVisible(true)
                self.m_miniMachine[miniIndex]:removeRespinNode()
                if miniIndex ~= 1 then
                    self.m_miniMachine[miniIndex].m_suolian:setVisible(true)
                end
            end
    
            self.m_respin_jiesuan:setVisible(false)
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
    
            if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                self:findChild("free_guang"):setVisible(false)
            else
                self:findChild("free_guang"):setVisible(true)
            end
            self.m_isJieSuanOver = false
    
        end,function()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg() 
        end)
        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},794)
end

function CodeGameScreenWestRangerMachine:showReSpinOver(coins, func, index)
    local respinType = self.m_runSpinResultData.p_rsExtraData.kind
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinOverPopup.mp3")
    if respinType == "special" then
        return self:showDialog("SuperRespinOver", ownerlist, func, nil, index)
    else
        return self:showDialog("RespinOver", ownerlist, func, nil, index)
    end
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

-- 判断哪个小轮盘 没有集满
function CodeGameScreenWestRangerMachine:getIndexReelMiniNoJiMan( )
    for miniIndex = 1, 4 do
        local reelData = self.m_runSpinResultData.p_rsExtraData["reel"..(miniIndex-1)]
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = 1, self.m_iReelRowNum do
                if reelData.reels[iRow][iCol] == 100 then
                    self.m_IndexReelMini = miniIndex
                    return
                end
            end
        end
    end
end

function CodeGameScreenWestRangerMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    

    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == 3 then
        -- c出现预告动画概率40%
        local yuGaoId = math.random(1, 10)
        if yuGaoId <= 4 then
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
function CodeGameScreenWestRangerMachine:playYuGaoAct(func)

    -- gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_playYuGaoAct.mp3") 
    gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_promptWin.mp3")
    self.m_baseYugaoSpine1:setVisible(true)
    self.m_baseYugaoSpine2:setVisible(true)

    self.m_baseYugaoSpine1:runCsbAction("yugao",false)
    util_spinePlay(self.m_baseYugaoSpine2,"yugao")

    util_spineEndCallFunc(self.m_baseYugaoSpine2,"yugao",function ()
        self.m_baseYugaoSpine1:setVisible(false)
        self.m_baseYugaoSpine2:setVisible(false)
        if func then
            func()
        end
    end)
end

-- free过场
function CodeGameScreenWestRangerMachine:playChangeGuoChang(func1,func2)
    self.m_GuoChangBg:setVisible(true)

    self.m_GuoChangBg:findChild("Particle_1"):resetSystem()
    -- self.m_GuoChangBg:findChild("Particle_1_0"):resetSystem()
    self.m_GuoChangBg:findChild("Particle_1_1"):resetSystem()

    -- gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_guochang.mp3")
    self.m_GuoChangBg:runCsbAction("actionframe",false,function()
        self.m_GuoChangBg:setVisible(false)
        if func2 then
            func2()
        end
    end)

    self:waitWithDelay(nil,function(  )
        if func1 then
            func1()
        end
    end,80/60)

    gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_base_freeSpinTrans.mp3")
end

-- respin过场
function CodeGameScreenWestRangerMachine:playReSpinChangeGuoChang(func1,func2)
    self.m_reSpinGuoChangBg:setVisible(true)
    util_spinePlay(self.m_reSpinGuoChangBg,"actionframe")

    util_spineEndCallFunc(self.m_reSpinGuoChangBg,"actionframe",function ()
        self.m_reSpinGuoChangBg:setVisible(false)

        if func2 then
            func2()
        end
    end)

    self:waitWithDelay(nil,function(  )
        if func1 then
            func1()
        end
    end,37/30)
end

-- 每个reel条滚动到底
function CodeGameScreenWestRangerMachine:slotOneReelDown(reelCol)
    local isTriggerLongRun = CodeGameScreenWestRangerMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isTriggerLongRun then
        self.m_isTriggerLongRun = isTriggerLongRun
    end

    return isTriggerLongRun
end

function CodeGameScreenWestRangerMachine:symbolBulingEndCallBack(_symbolNode)
    if _symbolNode and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isTriggerLongRun and _symbolNode.p_cloumnIndex ~= self.m_iReelColumnNum then
            local Col = _symbolNode.p_cloumnIndex
            for iCol = 1, Col do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName ~= "idleframe2" then
                        symbolNode:runAnim("idleframe2", true)
                    end
                end
            end
        else
            _symbolNode:runAnim("idleframe", true)
        end
    end
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenWestRangerMachine:showBonusAndScatterLineTip(lineValue,callFun)

    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

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

            -- slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            slotNode:runAnim("actionframe")
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

--ReSpin开始改变UI状态
function CodeGameScreenWestRangerMachine:changeReSpinStartUI(curCount)
    self.m_RespinBarView:updateLeftCount(curCount,false)
    self.m_RespinBarView:setVisible(true)
    self.m_RespinBarView:runCsbAction("start",false,function()
        self.m_RespinBarView:runCsbAction("idle",false)
    end)
end

--ReSpin刷新数量
function CodeGameScreenWestRangerMachine:changeReSpinUpdateUI(curCount,isLiang)
    print("当前展示位置信息  %d ", curCount)
    self.m_RespinBarView:updateLeftCount(curCount,isLiang)
end

function CodeGameScreenWestRangerMachine:getReelHeight()
    if display.width <= 1370 then
        return self.m_reelHeight
    else
        return 545
    end
end

-- 适配
function CodeGameScreenWestRangerMachine:scaleMainLayer()
    CodeGameScreenWestRangerMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.72
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        -- 
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.78 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.85 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.90 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    if display.width <= 1370 then
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 12)
    end
end

-- 金色bonus飞之前 先获取下 固定的小块
function CodeGameScreenWestRangerMachine:getRespinChipList( )
    for miniIndex = 1, 4 do
        self.m_miniMachine[miniIndex]:reSpinEndAction()
        if miniIndex ~= 1 then
            for j,vNode in ipairs(self.m_miniMachine[miniIndex].m_chipList) do
                vNode:setVisible(false)
                local endPos = vNode:getParent():convertToWorldSpace(cc.p(vNode:getPosition()))
                local respinKong = util_createAnimation("Socre_WestRanger_Respin_Genzi.csb")
                endPos = self:findChild("bonusNewNode2"):convertToNodeSpace(endPos)
                self:findChild("bonusNewNode2"):addChild(respinKong,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
                respinKong:setPosition(endPos)
                respinKong:setName("respinKong"..miniIndex*100+self:getPosReelIdx(vNode.p_rowIndex, vNode.p_cloumnIndex))
            end
        end
    end
end
--金色bonus往其他三个mini盘飞
function CodeGameScreenWestRangerMachine:flyDarkIcon()

    if self.m_flyIndex > #self.m_miniMachine[1].m_chipList then
        return
    end
    for miniIndex = 2, 4 do
        local symbolStartNode =  self.m_miniMachine[1].m_chipList[self.m_flyIndex]
        local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))

        local nodeEndSymbol =  self.m_miniMachine[miniIndex].m_chipList[self.m_flyIndex]
        local endPos = nodeEndSymbol:getParent():convertToWorldSpace(cc.p(nodeEndSymbol:getPosition()))
        if miniIndex == 4 then
            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinGoldFlyStart.mp3")
        end
        self:runFlySymbolAction(miniIndex, nodeEndSymbol,0.01,12/30,startPos,endPos,function()
            if miniIndex == 4 then
                self.m_flyIndex = self.m_flyIndex + 1
                if self.m_flyIndex == #self.m_miniMachine[1].m_chipList + 1 then
                    self.m_flyIndex = 1
                    for j=1,4 do
                        self.m_miniMachine[j]:runNextReSpinReel()
                    end
                else
                    self:flyDarkIcon()
                end
                gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinGoldFlyEnd.mp3")
            end
            
        end)
    end
    
end

function CodeGameScreenWestRangerMachine:runFlySymbolAction(miniIndex,endNode,time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node = util_spineCreate("Socre_WestRanger_Bonus2",true,true)
    node.p_cloumnIndex = endNode.p_cloumnIndex
    node.p_rowIndex = endNode.p_rowIndex
    self:setJinSeBonusSpecialNodeScore(node)
    node:setScale(0.5)
    node:setVisible(false)

    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        util_spinePlay(node,"fuzhi_over",false)
        
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        -- gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_flyUp.mp3")
    end)
    local bez=cc.BezierTo:create(flyTime,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
    cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
    local ease = cc.EaseQuadraticActionOut:create(bez)
    actionList[#actionList + 1] = ease
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        -- gLobalSoundManager:playSound("PelicanSounds/Pelican_bonus_flyUp_fanKui.mp3")
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(1/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        node:setVisible(false)
        node:removeFromParent()
        
        local kongNode = self:findChild("bonusNewNode2"):getChildByName("respinKong"..miniIndex*100+self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex))
        kongNode:setVisible(false)
        kongNode:removeFromParent()

        local symbol_node = endNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()

        if spineNode.m_csbNode then
            spineNode.m_csbNode:runCsbAction("start",false)
        end

        endNode:setVisible(true)
        endNode:runAnim("fuzhi_start", false,function()
        end)

    end)
    node:runAction(cc.Sequence:create(actionList))
end

-- 获取第一个棋盘已经固定的某个小块
function CodeGameScreenWestRangerMachine:getCurRespinNode( )
    local chipList = self.m_miniMachine[1].m_respinView:getAllCleaningNode()
    for i,vNode in ipairs(chipList) do
        if vNode.p_symbolType == self.SYMBOL_BONUS1 or vNode.p_symbolType == self.SYMBOL_BONUS2 then
            return vNode
        end
    end
end

------------------------------------------------------------
-- videoPoker 相关
------------------------------------------------------

function CodeGameScreenWestRangerMachine:videoPokerResultCallFun(param)

    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]

        if spinData.action == "SPECIAL" then
            gLobalViewManager:removeLoadingAnima()
            local serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_BonusWinCoins = serverWinCoins
            globalData.userRate:pushCoins(serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            -- 更新本地数据
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
            -- 更新VideoPoker数据
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            self.m_videoPokeMgr.m_runData:parseData( selfdata )
            local bonus = spinData.result.bonus or {}
            self.m_videoPokeMgr.m_runData:parseData( bonus )
            local extra = bonus.extra or {}
            self.m_videoPokeMgr.m_runData:parseData( extra )

            self.m_videoPokeMgr:handleVideoPokerResult( )
        end

       
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end

function CodeGameScreenWestRangerMachine:addVideoPokerUI( )

    self.m_videoPokerGuoChang =  self.m_videoPokeMgr:createVideoPokerGuoChang()
    self:addChild(self.m_videoPokerGuoChang ,self.m_videoPokeMgr.p_Config.UIZORDER.GUOCAHNG)
    self.m_videoPokerGuoChang:setVisible(false)
    self.m_videoPokerGuoChang:setPosition(display.center)
    
    self.m_videoPokerMain =  self.m_videoPokeMgr:createVideoPokerBaseMain()
    self:addChild(self.m_videoPokerMain ,self.m_videoPokeMgr.p_Config.UIZORDER.MAINUI)
    self.m_videoPokerMain:setVisible(false)

    self.m_videoPokerBetChoose =  self.m_videoPokeMgr:createVideoPokerBetChooseView()
    self:addChild(self.m_videoPokerBetChoose ,self.m_videoPokeMgr.p_Config.UIZORDER.BETCHOSEUI)
    self.m_videoPokerBetChoose:setVisible(false)
    if not self.m_videoPokeMgr:checkEntranceCanClick( ) then
        self.m_videoPokeMgr:showVideoPokeChooseBetViewView()
    end

    self.m_entrance = self.m_videoPokeMgr:ceateVideoPokerEntrance( )
    self:findChild("Node_CasinoEntrance"):addChild(self.m_entrance)
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenWestRangerMachine:initGameStatusData(gameData)
    -- 数据合并
    local spin = gameData.spin
    local special = gameData.special
    if spin ~= nil then
        if special ~= nil then
            local bonus = special.bonus
            if bonus then
                if bonus.status then
                    gameData.spin.selfData = clone(gameData.special.selfData)
                    gameData.spin.bonus    = clone(gameData.special.bonus)
                end
                self.m_videoPokeMgr.m_runData:parseData( bonus )
                local extra = bonus.extra or {}
                self.m_videoPokeMgr.m_runData:parseData( extra )
            end
            
        end
    else
        gameData.spin = clone(special)
        spin = gameData.spin
    end
    
    CodeGameScreenWestRangerMachine.super.initGameStatusData(self,gameData)

    if spin ~= nil then
        local bonus = spin.bonus or {}
        self.m_videoPokeMgr.m_runData:parseData( bonus )
        local extra = bonus.extra or {}
        self.m_videoPokeMgr.m_runData:parseData( extra )
    end

    if gameData.feature ~= nil then
        self.m_runSpinResultData:parseResultData(gameData.feature, self.m_lineDataPool, self.m_symbolCompares)
        self.m_initSpinData = self.m_runSpinResultData
    end
    
end

--[[
   videoPoke断线重连
]]
function CodeGameScreenWestRangerMachine:videoPoker_initGame()
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "OPEN" then
        local requestType = self.m_videoPokeMgr.m_runData:getRequestType( )
        if requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP then
            -- 消耗筹码开始
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP ) 
            self.m_videoPokerMain:postChipRequestCallFun()
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.HOLDPOKER then
            -- 选择牌型
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP ) 
            self.m_videoPokerMain:holdPokeRequestCallFun( )
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.COLLECTDOUBLE_START then
            -- double直接结束选择赢钱
            print("直接结束不处理任何逻辑,实际上这块逻辑就不会走进来")
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.COLLECTDOUBLE_MAIN then
            -- double直接结束选择赢钱
            print("直接结束不处理任何逻辑,实际上这块逻辑就不会走进来")
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_MAIN then
            -- doubleMain选择继续翻倍
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_MAIN ) 
            gLobalNoticManager:postNotification(self.m_videoPokeMgr.p_Config.EventType.NOTIFY_REC_SHOW_DOUBLEGAME_MAINVIEW)
            self.m_videoPokerMain:doubleUpMainRequestCallFun( )
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_START then
            -- doubeStart选择继续翻倍
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_START ) 
            gLobalNoticManager:postNotification(self.m_videoPokeMgr.p_Config.EventType.NOTIFY_SHOW_DOUBLEGAME_MAINVIEW)
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLECLICKPOS then
            -- 发送在double里选择选择牌的位置
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLECLICKPOS )
            self.m_videoPokerMain:recDoubleClickPosRequestCallFun( )
        end
        
    end
    
   
end

function CodeGameScreenWestRangerMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "WestRangerSounds/sound_WestRanger_soundScatterTip.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenWestRangerMachine:playScatterTipMusicEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_soundScatterFreeSpinTip.mp3")
    else
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_scatterTrigger.mp3")
    end
end

--重写
function CodeGameScreenWestRangerMachine:showEffect_FreeSpin(effectData)
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

    --重写改动
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- gLobalSoundManager:setLockBgMusic(false)
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end
    
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
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenWestRangerMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        -- self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end


---
-- 触发respin 玩法
--
function CodeGameScreenWestRangerMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- gLobalSoundManager:setLockBgMusic(false)
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
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
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

return CodeGameScreenWestRangerMachine






