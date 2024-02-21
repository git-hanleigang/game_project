
-- FIX IOS 139 1
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenTrainYourDragonMachine = class("CodeGameScreenTrainYourDragonMachine", BaseFastMachine)

CodeGameScreenTrainYourDragonMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenTrainYourDragonMachine.SYMBOL_BIG_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE--93
CodeGameScreenTrainYourDragonMachine.SYMBOL_FIX_SYMBOL1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenTrainYourDragonMachine.SYMBOL_FIX_SYMBOL2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenTrainYourDragonMachine.SYMBOL_FIX_MINI = 101
CodeGameScreenTrainYourDragonMachine.SYMBOL_FIX_MINOR = 102
CodeGameScreenTrainYourDragonMachine.SYMBOL_FIX_MAJOR = 103
CodeGameScreenTrainYourDragonMachine.SYMBOL_FIX_GRAND = 104

CodeGameScreenTrainYourDragonMachine.COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 --金蛋收集
CodeGameScreenTrainYourDragonMachine.COLLECTTOCHANGEXIAOLONG_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 --金蛋收集变小龙

CodeGameScreenTrainYourDragonMachine.DROP_FIRST_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3--respin滚完下落
CodeGameScreenTrainYourDragonMachine.REMOVE_ROWS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2--respin消除
CodeGameScreenTrainYourDragonMachine.DROP_SECOND_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1--respin消除完下落
-- 构造函数
function CodeGameScreenTrainYourDragonMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_isInBonus = false--是不是bonus断线重连
    self.m_randomSymbolSwitch = true
    self.m_spinRestMusicBG = true
    self.m_isrespinInit = false--respin是否初始化完
    self.m_reConnection = false--是否重连
    self.m_scatterClickedNodeTab = {}--scatter点击区域
    self.m_scatterFreespinMoreTab = {}--触发freespinmore的scatter动画对象数组
    self.m_respinEffect = {}--respin下播的动画效果
    self.m_respinJackpotSymbolTab = {}--respin下收集的jackpot图标
    self.m_collectedJackpotIdx = 0--已收集jackpot图标下标
    self.m_respinWinCoin = 0--respin下赢钱的累计值

    self.m_respinCollectWinCoinMutiple = {2,5,"grand"}--满多少格对应的给钱数
    self.m_respinCollectWinCoinNum = {5,9,12}--满多少格给钱
    self.m_isFeatureOverBigWinInFree = true
	--init
	self:initGame()
end

function CodeGameScreenTrainYourDragonMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("TrainYourDragonConfig.csv", "LevelTrainYourDragonConfig.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
end
function CodeGameScreenTrainYourDragonMachine:initUI()
    self.m_reelRunSound = "TrainYourDragonSounds/music_TrainYourDragon_quick_run.mp3"--快滚音效
    --背景适配
    self.m_gameBg:findChild("root"):setScale(self.m_machineRootScale)
    --背景播粒子
    for i = 1,4 do
        if self.m_gameBg:findChild("respin_lizi"..i) then
            self.m_gameBg:findChild("respin_lizi"..i):setPositionType(0)
            self.m_gameBg:findChild("respin_lizi"..i):resetSystem()
        end
        if self.m_gameBg:findChild("freespin_lizi"..i) then
            self.m_gameBg:findChild("freespin_lizi"..i):setPositionType(0)
            self.m_gameBg:findChild("freespin_lizi"..i):resetSystem()
        end
        if  self.m_gameBg:findChild("normal_lizi"..i) then
            self.m_gameBg:findChild("normal_lizi"..i):setPositionType(0)
            self.m_gameBg:findChild("normal_lizi"..i):resetSystem()
        end
    end
    --背景加鸟
    self.m_bgBird = util_spineCreate("TrainYourDragon_bg_niao",true,true)
    self.m_gameBg:findChild("root"):addChild(self.m_bgBird)
    util_spinePlay(self.m_bgBird,"idle",true)

    self:runCsbAction("normal")
    -- self:initFreeSpinBar() -- FreeSpinbar
    --添加freespin计数条
    self.m_freespinBar = util_createView("CodeTrainYourDragonSrc.TrainYourDragonFreespinBarView")
    self:findChild("fs_remaining_top"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)
    --添加jackpot条
    self.m_jackpotBar = util_createView("CodeTrainYourDragonSrc.TrainYourDragonJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)
    --添加提示条
    self.m_tishiBar = util_createAnimation("TrainYourDragon_top.csb")
    self:findChild("fs_remaining_top"):addChild(self.m_tishiBar)
    --添加respin计数条
    self.m_respinBar = util_createAnimation("TrainYourDragon_remaining.csb")
    self:findChild("fs_remaining_top"):addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)
    --添加respin条上计数动画
    self.m_respinBarNumAniTab = {} 
    for i = 1,3 do
        local respinBarNumAni = util_createAnimation("TrainYourDragon_remaining_sr.csb")
        self.m_respinBar:findChild("num_"..i):getParent():addChild(respinBarNumAni)
        respinBarNumAni:setPosition(cc.p(self.m_respinBar:findChild("num_"..i):getPosition()))
        respinBarNumAni:setVisible(false)
        for j = 1,3 do
            if j == i then
                respinBarNumAni:findChild("num_"..j):setVisible(true)
            else
                respinBarNumAni:findChild("num_"..j):setVisible(false)
            end
        end
        table.insert(self.m_respinBarNumAniTab,respinBarNumAni)
    end
    self.m_respinBar.showNum = 0
    --添加进度条
    self.m_collectProgress = util_createAnimation("TrainYourDragon_jindutiao_2.csb")
    self:findChild("jindutiao_2"):addChild(self.m_collectProgress)
    self.m_collectProgress.currCollectCount = 0
    self.m_collectProgress.collectTotalCount = 12--进度条最大收集数
    self.m_collectProgress:setVisible(false)
    self.m_collectProgress:findChild("shuomingtiao"):setVisible(false)
    --添加respin进度条上的赢钱数字
    self.m_respinCollectWinCoinNode = {}
    for i,mutiple in ipairs(self.m_respinCollectWinCoinMutiple) do
        if type(mutiple) == "string" then
            local respinCollectWinCoinNode = util_createAnimation("TrainYourDragon_jindutiao_x5.csb")
            self.m_collectProgress:findChild("winCoinNode"..i):addChild(respinCollectWinCoinNode)
            table.insert(self.m_respinCollectWinCoinNode,respinCollectWinCoinNode)
        else
            local respinCollectWinCoinNode = util_createAnimation("TrainYourDragon_jindutiao_x2.csb")
            self.m_collectProgress:findChild("winCoinNode"..i):addChild(respinCollectWinCoinNode)
            table.insert(self.m_respinCollectWinCoinNode,respinCollectWinCoinNode)
        end
    end
    --添加进度条上的增长特效
    self.m_collectProgressUpEff = util_createAnimation("TrainYourDragon_jindutiao_zengzhangtexiao.csb")
    self.m_collectProgress:findChild("LoadingBar_1"):getParent():addChild(self.m_collectProgressUpEff)
    self.m_collectProgressUpEff:setVisible(false)
    self.m_collectProgressUpEff:findChild("jindutiaoidlelizi"):setPositionType(0)
    self.m_collectProgressUpEff:findChild("jindutiaoidlelizi"):resetSystem()
    self.m_collectProgressUpEff:setPositionX(-9999)
    --添加龙头
    self.m_leftLongtou = util_spineCreate("Socre_TrainYourDragon_longtou",true,true)
    self:findChild("zuolongtou"):addChild(self.m_leftLongtou)
    self.m_leftLongtou:setVisible(false)
    self.m_rightLongtou = util_spineCreate("Socre_TrainYourDragon_longtou",true,true)
    self:findChild("youlongtou"):addChild(self.m_rightLongtou)
    self.m_rightLongtou:setVisible(false)
    --添加过场
    self.m_guochangLong = util_spineCreate("TrainYourDragon_long_da",true,true)
    self.m_guochangEye = util_createAnimation("TrainYourDragon_guochang.csb")
    self:findChild("guochang"):addChild(self.m_guochangLong)
    self:findChild("guochang"):addChild(self.m_guochangEye)
    self:findChild("guochang"):setVisible(false)
    --添加收集加钱特效
    self.m_collectAddCoinEffect = util_createAnimation("TrainYourDragon_jiesuan.csb")
    self.m_bottomUI.coinWinNode:addChild(self.m_collectAddCoinEffect)
    self.m_collectAddCoinEffect:setVisible(false)
    --添加半透明遮罩
    self.m_maskLayer = util_createAnimation("Socre_TrainYourDragon_qipan_yaan.csb")
    self.m_clipParent:addChild(self.m_maskLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE)
    self.m_maskLayer:playAction("idlefame")
    self.m_maskLayer:setVisible(false)
    --添加乘倍特效
    self.m_multipleEff = util_createAnimation("TrainYourDragon_jindutiao_x2.csb")
    self.m_multipleEff:setVisible(false)
    self:addChild(self.m_multipleEff,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    --添加预告中奖烟雾
    self.m_triggerEffect = util_createAnimation("TrainYourDragon_reelyan.csb")
    self.m_triggerEffect:setVisible(false)
    self:findChild("Node_reelyan"):addChild(self.m_triggerEffect)

    --添加收集金蛋进度条
    self.m_collectJindanProgress = util_createAnimation("TrainYourDragon_jindutiao_base.csb")
    self:findChild("jindutiao_2"):addChild(self.m_collectJindanProgress)

    self.m_collectJindanProgress:findChild("bigClick"):setVisible(false)
    self.m_collectJindanProgress:findChild("smallClick"):setVisible(false)

    self.m_collectJindanProgress:findChild("bigClick"):addTouchEventListener(handler(self, self.bigDragonTipClick))
    self.m_collectJindanProgress:findChild("smallClick"):addTouchEventListener(handler(self, self.smallDragonTipClick))

    self.m_bigTipWaitNode = cc.Node:create()
    self:addChild(self.m_bigTipWaitNode)
    
    self.m_smallTipWaitNode = cc.Node:create()
    self:addChild(self.m_smallTipWaitNode)

    -- 添加base收集进度条提示
    self.m_tipBigDragon = util_createAnimation("TrainYourDragon_jindutiao_base_dalongtishi.csb")
    self.m_collectJindanProgress:findChild("dalongtishi"):addChild(self.m_tipBigDragon)

    self.m_tipSmallDragon = util_createAnimation("TrainYourDragon_jindutiao_base_xiaolongtishi.csb")
    self.m_collectJindanProgress:findChild("xiaolongtishi"):addChild(self.m_tipSmallDragon)

    self.m_tipBigDragon:findChild("click"):addTouchEventListener(handler(self, self.closeBigDragonTipClick))
    self.m_tipSmallDragon:findChild("click"):addTouchEventListener(handler(self, self.clsoeSmallDragonTipClick))

    self.m_tipBigDragon:findChild("click"):setVisible(false)
    self.m_tipSmallDragon:findChild("click"):setVisible(false)

    --添加收集金蛋进度条上的图标
    local jindan = util_createAnimation("TrainYourDragon_jindutiao_base_dan.csb")
    self.m_collectJindanProgress:findChild("dan"):addChild(jindan)
    self.m_collectJindanProgress.jindan = jindan
    self.m_collectJindanProgress.jindan:playAction("idle",true)
    local xiaolong = util_createAnimation("TrainYourDragon_jindutiao_base_xiaolong.csb")
    self.m_collectJindanProgress:findChild("xiaolong"):addChild(xiaolong)
    self.m_collectJindanProgress.xiaolong = xiaolong
    local dalong = util_createAnimation("TrainYourDragon_jindutiao_base_dalong.csb")
    self.m_collectJindanProgress:findChild("dalong"):addChild(dalong)
    self.m_collectJindanProgress.dalong = dalong
    --添加收集金蛋进度条上的特效
    self.m_collectJindanProgressUpEff = util_createAnimation("TrainYourDragon_jindutiao_zengzhangtexiao.csb")
    self.m_collectJindanProgress:findChild("effNode"):addChild(self.m_collectJindanProgressUpEff)
    self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setPositionType(0)
    self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):resetSystem()
    self.m_collectJindanProgressUpEff:setPositionX(-9999)

    self:showSmallDragonTip( )
    self:showBigDragonTip( )
end
--初始化收集金蛋进度条上的图标
function CodeGameScreenTrainYourDragonMachine:initCollectJindanProgreeIcon()
    self.m_collectJindanProgress.xiaolong:playAction("idle",true)
    self.m_collectJindanProgress.dalong:playAction("idle",true)
    if self.m_runSpinResultData.p_collectNetData[1] then
        local leftNum = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalNum = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        local phase1Num = self.m_phaseLimit[1]
        if totalNum - leftNum >= phase1Num then
            self.m_collectJindanProgress.xiaolong:playAction("idle2",true)
        end
    end
end
--进关数据初始化
function CodeGameScreenTrainYourDragonMachine:initGameStatusData(gameData)
    CodeGameScreenTrainYourDragonMachine.super.initGameStatusData(self,gameData)
    if gameData.gameConfig and gameData.gameConfig.init then  
        if gameData.gameConfig.init.collectMultiple then
            self.m_respinCollectWinCoinNum = {}
            self.m_respinCollectWinCoinMutiple = {}
            for k,v in pairs(gameData.gameConfig.init.collectMultiple) do
                table.insert(self.m_respinCollectWinCoinNum,tonumber(k))
                table.insert(self.m_respinCollectWinCoinMutiple,v)
            end
            --排个序
            table.sort( self.m_respinCollectWinCoinNum , function(num1 , num2)
                return num1 < num2
            end)
            table.sort( self.m_respinCollectWinCoinMutiple , function(mutiple1 , mutiple2)
                return mutiple1 < mutiple2
            end)
            --最后一个换成grand
            table.remove(self.m_respinCollectWinCoinMutiple,#self.m_respinCollectWinCoinMutiple)
            table.insert(self.m_respinCollectWinCoinMutiple,"grand")
        end
        if gameData.gameConfig.init.phaseLimit then
            self.m_phaseLimit = clone(gameData.gameConfig.init.phaseLimit)--收集金蛋个数配置
        end
    end
    if gameData.collect then
        self.m_runSpinResultData.p_collectNetData = clone(gameData.collect)
    end
end
-- 断线重连
function CodeGameScreenTrainYourDragonMachine:MachineRule_initGame()
    self.m_reConnection = true
end
-- bonus小游戏断线重连
function CodeGameScreenTrainYourDragonMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "OPEN" then
        self.m_isInBonus = true
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end
---
-- 获取关卡名字
function CodeGameScreenTrainYourDragonMachine:getModuleName()
    return "TrainYourDragon"
end
function CodeGameScreenTrainYourDragonMachine:getNetWorkModuleName()
    return "TrainYourDragonV2"
end
-- 继承底层respinView
function CodeGameScreenTrainYourDragonMachine:getRespinView()
    return "CodeTrainYourDragonSrc.TrainYourDragonRespinView"
end
-- 继承底层respinNode
function CodeGameScreenTrainYourDragonMachine:getRespinNode()
    return "CodeTrainYourDragonSrc.TrainYourDragonRespinNode"
end

--小块
function CodeGameScreenTrainYourDragonMachine:getBaseReelGridNode()
    return "CodeTrainYourDragonSrc.TrainYourDragonSlotsNode"
end
function CodeGameScreenTrainYourDragonMachine:getBottomUINode()
    return "CodeTrainYourDragonSrc.TrainYourDragonBoottomUiView"
end

function CodeGameScreenTrainYourDragonMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1
    local disignWidth = 1280--设计轮盘有效宽度
    local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
    local wScale = winSize.width / disignWidth
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end
-- @param symbolType int 信号类型
function CodeGameScreenTrainYourDragonMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_TrainYourDragon_xing"
    end

    if symbolType == self.SYMBOL_BIG_WILD  then
        return "Socre_TrainYourDragon_Wild_0"
    end

    if symbolType == self.SYMBOL_FIX_SYMBOL1 then
        return "Socre_TrainYourDragon_link_1"
    end

    if symbolType == self.SYMBOL_FIX_SYMBOL2 then
        return "Socre_TrainYourDragon_link_2"
    end

    if symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_TrainYourDragon_link_MINI"
    end

    if symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_TrainYourDragon_link_MINOR"
    end

    if symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_TrainYourDragon_link_MAJOR"
    end

    if symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_TrainYourDragon_link_GRAND"
    end

    return nil
end
--随机一个普通信号块
function CodeGameScreenTrainYourDragonMachine:getOneNorSymbol()
    local symbolList = self:getNormalSymbolType()
    return symbolList[math.random(1,#symbolList)]
end
-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenTrainYourDragonMachine:getReSpinSymbolScore(pos)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == pos then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end
    return score
end

function CodeGameScreenTrainYourDragonMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    if symbolType == self.SYMBOL_FIX_SYMBOL2 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end
    return score
end

-- 给respin小块进行赋值
function CodeGameScreenTrainYourDragonMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            symbolNode.showScore = score
            score = util_formatCoins(score, 3,nil,nil,true)
            if symbolNode.getCcbProperty then
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
            else
                symbolNode:findChild("m_lb_score"):setString(score)
            end
            
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3,nil,nil,true)
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
            end
        end
    end
end

--从内存池里取信号块时 设置信号块的数据
function CodeGameScreenTrainYourDragonMachine:updateReelGridNode(symblNode)
    CodeGameScreenTrainYourDragonMachine.super.updateReelGridNode(self,symblNode)
    if symblNode.p_symbolType == self.SYMBOL_FIX_SYMBOL2 then
        self:setSpecialNodeScore(nil,{symblNode})
    end
    if self:getCurrSpinMode() == RESPIN_MODE then
        symblNode:runAnim("dark")
        if symblNode:getCcbProperty("xing_bg") then
            symblNode:getCcbProperty("xing_bg"):setVisible(true)
        end
    else
        if symblNode:getCcbProperty("xing_bg") then
            symblNode:getCcbProperty("xing_bg"):setVisible(false)
        end
    end
    return symblNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是link小块
function CodeGameScreenTrainYourDragonMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL1 or
        symbolType == self.SYMBOL_FIX_SYMBOL2 or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end
--返回本组下落音效和是否触发长滚效果
function CodeGameScreenTrainYourDragonMachine:getRunStatus(col, nodeNum, showCol)
    --设置滚动状态
    local runStatus = 
    {
        DUANG = 1,
        NORUN = 2,
    }
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local showColTemp = {}
        if showCol ~= nil then 
            showColTemp = showCol
        else 
            for i=1,self.m_iReelColumnNum do
                showColTemp[#showColTemp + 1] = i
            end
        end
        
        if col == showColTemp[#showColTemp] then
            if nodeNum >= 2 then
                return runStatus.DUANG, true
            else
                return runStatus.NORUN, false
            end
        else
            if nodeNum >= 2 then
                return runStatus.DUANG, true
            else
                return runStatus.DUANG, false
            end
        end
    else
        return CodeGameScreenTrainYourDragonMachine.super.getRunStatus(self,col, nodeNum, showCol)
    end
    
end
--所有滚轴停止调用
function CodeGameScreenTrainYourDragonMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenTrainYourDragonMachine.super.slotReelDown(self)
end
--
--单列滚动停止回调
--
function CodeGameScreenTrainYourDragonMachine:slotOneReelDown(reelCol)
    BaseFastMachine.slotOneReelDown(self,reelCol)
    local playSound = {bonusSound = 0,scatterSound = 0}
    for k = 1, self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
        if symbolNode and self:isFixSymbol(symbolNode.p_symbolType) then
            playSound.bonusSound = 1
            symbolNode:runAnim("buling",false,function()
                if symbolNode.p_symbolType ~= nil then
                    symbolNode:runAnim("idleframe",true)
                end
            end)
        end
    end
        
    if playSound.bonusSound == 1 then

        local soundPath = "TrainYourDragonSounds/music_TrainYourDragon_bonusBuling2.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
end
function CodeGameScreenTrainYourDragonMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "TrainYourDragonSounds/music_TrainYourDragon_Scatter.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenTrainYourDragonMachine:levelFreeSpinEffectChange()
    --轮盘动画
    self:runCsbAction("freespin",true)
    --背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"free",true})
    util_spinePlay(self.m_bgBird,"idle2",true)
    self.m_bgBird:setVisible(true)
    self.m_collectJindanProgress:setVisible(false)

    self.m_freespinBar:setVisible(true)
    self.m_respinBar:setVisible(false)
    self.m_collectProgress:setVisible(false)
    self.m_collectProgressUpEff:setVisible(false)
    self.m_collectProgressUpEff:setPositionX(-9999)
    self.m_tishiBar:setVisible(false)
end

--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenTrainYourDragonMachine:levelFreeSpinOverChangeEffect()
    
end

function CodeGameScreenTrainYourDragonMachine:freeSpinOverchangeUI()
    --轮盘动画
    self:runCsbAction("normal")
    --背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    util_spinePlay(self.m_bgBird,"idle",true)
    self.m_collectJindanProgress:setVisible(true)
    
    self.m_freespinBar:setVisible(false)
    self.m_respinBar:setVisible(false)
    self.m_collectProgress:setVisible(false)
    self.m_tishiBar:setVisible(true)
end
---------------------------------------------------------------------------

--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenTrainYourDragonMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end
-- 显示free spin
function CodeGameScreenTrainYourDragonMachine:showEffect_FreeSpin(effectData)

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
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_scatterMoreTrigger.mp3")
        
        for row = 1, self.m_iReelRowNum do
            for col = 1, self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    slotNode:setVisible(false)
                    -- self:setSlotNodeEffectParent(slotNode)
                    -- slotNode:runAnim("actionframe2",false,function ()
                         
                    -- end)
                    local freespinMoreScatter = util_spineCreate("Socre_TrainYourDragon_Scatter",true,true)
                    freespinMoreScatter:setScale(self.m_machineRootScale)
                    table.insert(self.m_scatterFreespinMoreTab,freespinMoreScatter)
                    self:addChild(freespinMoreScatter,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)            
                    local worldPos = slotNode:getParent():convertToWorldSpace(cc.p(slotNode:getPosition()))
                    local localpos = self:convertToNodeSpace(worldPos)
                    freespinMoreScatter:setPosition(localpos)
                    freespinMoreScatter:setAnimation(0,"actionframe2",false)
                    util_spineEndCallFunc(freespinMoreScatter,"actionframe2",function ()
                        local movetoPos = self:convertToNodeSpace(display.center)
                        local move = cc.MoveTo:create(15/30,movetoPos)
                        freespinMoreScatter:runAction(move)
                        slotNode:setVisible(true)

                        freespinMoreScatter:setAnimation(0,"yidong",false)
                        util_spineEndCallFunc(freespinMoreScatter,"yidong",function ()
                            if self.m_scatterFreespinMoreTab[1] == freespinMoreScatter then
                                local layer = cc.LayerColor:create(cc.c3b(0, 0, 0),display.width,display.height)
                                layer:setOpacity(0)
                                layer:setScale(10)
                                layer:onTouch( function() 
                                    return true
                                end, false, true)
                                freespinMoreScatter:addChild(layer)

                                gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_custom_freespinMore.mp3")
                                freespinMoreScatter:setAnimation(0,"FreeSpinMoreTB",false)
                                util_spineEndCallFunc(freespinMoreScatter,"FreeSpinMoreTB",function ()
                                    layer:removeFromParent()
                                    self:resetMusicBg(true)
                                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end)

                            else
                                freespinMoreScatter:setVisible(false)
                            end
                        end)
                    end)
                end
            end
        end
        -- performWithDelay(self,function ()
        --     self:showFreeSpinView(effectData)
        -- end,3.5)
    else
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
        for row = 1, self.m_iReelRowNum do
            for col = 1, self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    self:setSlotNodeEffectParent(slotNode)
                    slotNode:runAnim("actionframe",false,function ()
                        
                    end)
                end
            end
        end
        performWithDelay(self,function ()
            self:addScatterClickNode()
        end,46/30)
    end

    if scatterLineValue ~= nil then
        -- self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
        --     if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --         self:showFreeSpinView(effectData)
        --     else
        --         self:addScatterClickNode()
        --     end
        -- end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        -- self:playScatterTipMusicEffect()
    else
        -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --     self:playScatterTipMusicEffect()
        --     for row = 1, self.m_iReelRowNum do
        --         for col = 1, self.m_iReelColumnNum do
        --             local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
        --             if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --                 self:setSlotNodeEffectParent(slotNode)
        --                 slotNode:runAnim("actionframe2",false)
        --             end
        --         end
        --     end
        --     performWithDelay(self,function ()
        --         self:showFreeSpinView(effectData)
        --     end,2.5)
        -- else
        --     self:addScatterClickNode()
        -- end
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
--添加scatter点击区域
function CodeGameScreenTrainYourDragonMachine:addScatterClickNode()
    for col = 1,self.m_iReelColumnNum do
        for row = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local clickedNode = util_createView("CodeTrainYourDragonSrc.TrainYourDragonScatterClickView")
                self.m_clipParent:addChild(clickedNode)
                clickedNode:setPosition(self:getNodePosByColAndRow(row,col))
                clickedNode:initColRow(col,row)
                table.insert(self.m_scatterClickedNodeTab,clickedNode)
                symbolNode:runAnim("idleframe2",true)

                local shuziNode = util_createAnimation("Socre_TrainYourDragon_Scatter_FreeGames.csb")
                symbolNode:addChild(shuziNode,2)
                symbolNode.m_shuziNode = shuziNode
            end
        end
    end
    self.m_maskLayer:setVisible(true)
    self.m_maskLayer:playAction("actionframe",false)
end
--点击scatter调用
function CodeGameScreenTrainYourDragonMachine:scatterClicked(clickCol,clickRow)
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_scatterClicked.mp3")
    --清除scatter点击区域
    for i,clickedNode in ipairs(self.m_scatterClickedNodeTab) do
        clickedNode:removeFromParent()
    end
    self.m_scatterClickedNodeTab = {}
    --播放scatter动画
    local symbolNode = self:getFixSymbol(clickCol, clickRow, SYMBOL_NODE_TAG)
    symbolNode:runAnim("pick",false,function ()
        self:showFreeSpinView()
    end)
    symbolNode.m_shuziNode:findChild("BitmapFontLabel_1"):setString(self.m_runSpinResultData.p_freeSpinsTotalCount)

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.freeSpinCount then
        local freeNumTab = clone(self.m_runSpinResultData.p_selfMakeData.freeSpinCount)
        --去掉一个中的数量
        for i,freeNum in ipairs(freeNumTab) do
            if freeNum == self.m_runSpinResultData.p_freeSpinsTotalCount then
                table.remove(freeNumTab,i)
                break
            end
        end

        local noPickScatterSymbolTab = {}
        for col = 1,self.m_iReelColumnNum do
            for row = 1,self.m_iReelRowNum do
                local symbolNode1 = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
                if symbolNode1 and symbolNode1.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    if col == clickCol and row == clickRow then

                    else
                        table.insert(noPickScatterSymbolTab,symbolNode1)
                        symbolNode1:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 1)
                        local randIdx = math.random(#freeNumTab)
                        symbolNode1.m_shuziNode:findChild("BitmapFontLabel_1"):setString(freeNumTab[randIdx])
                        table.remove(freeNumTab,randIdx)
                    end
                end
            end
        end

        performWithDelay(self,function ()
            symbolNode.m_shuziNode:playAction("pick")
            for i,symbolNode1 in ipairs(noPickScatterSymbolTab) do
                symbolNode1:runAnim("nopick")
                performWithDelay(symbolNode1.m_shuziNode,function ()
                    symbolNode1.m_shuziNode:playAction("nopick")
                end,26/30)
            end
        end,26/30)
    end
end
-- 触发freespin时调用
function CodeGameScreenTrainYourDragonMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_custom_freespinMore.mp3")
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_custom_enter_fs.mp3")
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showGuochang(function ()
                    -- self.m_bottomUI:checkClearWinLabel()
                    self.m_maskLayer:setVisible(false)
                    self:triggerFreeSpinCallFun()
                end,function ()
                    self:notifyGameEffectPlayComplete(GameEffect.EFFECT_FREE_SPIN)
                end)
            end)
        end
    end
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function()
        showFSView()
    end,0.5)
end
function CodeGameScreenTrainYourDragonMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index,self.m_baseDialogViewFps)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function() return false end
    end

    if view:findChild("root") then
        view:findChild("root"):setScale(self.m_machineRootScale)
    end

    gLobalViewManager:showUI(view)
    return view
end
-- 触发freespin结束时调用
function CodeGameScreenTrainYourDragonMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_freespinEnd.mp3")
    performWithDelay(self,function ()
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_over_fs.mp3")
        local view = self:showFreeSpinOver( self.m_runSpinResultData.p_fsWinCoins,
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:showGuochang(function ()
                self:freeSpinOverchangeUI()
            end,function ()
                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:triggerFreeSpinOverCallFun()
            end)
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label = node,sx = 1,sy = 1},625)
    end,3)
    
end

function CodeGameScreenTrainYourDragonMachine:showRespinJackpot(index,coins,func)
    local jackPotWinView = util_createView("CodeTrainYourDragonSrc.TrainYourDragonJackPotWinView")
    if jackPotWinView:findChild("root") then
        jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,self,func)
end

-- 获得普通信号块数组
function CodeGameScreenTrainYourDragonMachine:getNormalSymbolType()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    }
    return symbolList
end
-- 根据本关卡实际小块数量填写
function CodeGameScreenTrainYourDragonMachine:getRespinRandomTypes()
    local symbolList = { 
        self.SYMBOL_SCORE_10
    }
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenTrainYourDragonMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL1, runEndAnimaName = "buling", bRandom = true,weight = 37000},
        {type = self.SYMBOL_FIX_SYMBOL2, runEndAnimaName = "buling", bRandom = true,weight = 67600},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true,weight = 2000},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true,weight = 400},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = true,weight = 80},
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "buling", bRandom = true,weight = 10},
    }
    return symbolList
end
--更新金蛋收集进度
function CodeGameScreenTrainYourDragonMachine:updateCollectJindanProgree(isPlayAni)
    local toPogress1 = 0
    local toPogress2 = 0
    local actionTm = 0.5

    if self.m_reConnection and not (self.m_isInBonus == true or self.m_runSpinResultData.p_features[2] == 5 ) then
        if self.m_runSpinResultData.p_collectNetData[1] and self.m_runSpinResultData.p_collectNetData[1].collectLeftCount == 0 then
            self.m_runSpinResultData.p_collectNetData = {}
        end
    end

    if self.m_runSpinResultData.p_collectNetData[1] or self.m_collectData then
        local newAddNum = nil
        local leftNum = nil
        local totalNum = nil
        local phase1Num = self.m_phaseLimit[1]
        if self.m_collectData then
            newAddNum = self.m_collectData.collectChangeCount
            leftNum = self.m_collectData.collectLeftCount
            totalNum = self.m_collectData.collectTotalCount
        else
            newAddNum = self.m_runSpinResultData.p_collectNetData[1].collectChangeCount
            leftNum = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
            totalNum = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        end

        if totalNum - leftNum <= phase1Num then--还在第一阶段
            toPogress1 = (totalNum - leftNum)/phase1Num * 100
            if isPlayAni then
                self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(false)
                self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(true)
                -- self.m_collectJindanProgressUpEff:playAction("yici")
                self.m_collectJindanProgressUpEff:findChild("yici"):setPositionType(0)
                self.m_collectJindanProgressUpEff:findChild("yici"):resetSystem()
                self:progressUpdate(self.m_collectJindanProgress:findChild("LoadingBar_1"),toPogress1,actionTm,function ()
                    local benzhenJindu = self.m_collectJindanProgress:findChild("LoadingBar_1"):getPercent()
                    self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_1"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_1"):getContentSize().width * (benzhenJindu/100))
                end,function ()
                    self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
                    self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(false)
                    self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_1"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_1"):getContentSize().width * (toPogress1/100))
                end)
            else
                self.m_collectJindanProgress:findChild("LoadingBar_1"):setPercent(toPogress1)
                self.m_collectJindanProgress:findChild("LoadingBar_2"):setPercent(toPogress2)

                self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
                self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(false)
                self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_1"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_1"):getContentSize().width * (toPogress1/100))
            end
        else
            toPogress1 = 100
            toPogress2 = (totalNum - leftNum - phase1Num)/(totalNum - phase1Num) * 100
            if totalNum - leftNum - newAddNum >= phase1Num then
                if isPlayAni then
                    self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(false)
                    self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(true)
                    -- self.m_collectJindanProgressUpEff:playAction("yici")
                    self.m_collectJindanProgressUpEff:findChild("yici"):setPositionType(0)
                    self.m_collectJindanProgressUpEff:findChild("yici"):resetSystem()
                    self:progressUpdate(self.m_collectJindanProgress:findChild("LoadingBar_2"),toPogress2,actionTm,function ()
                        local benzhenJindu = self.m_collectJindanProgress:findChild("LoadingBar_2"):getPercent()
                        self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_2"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_2"):getContentSize().width * (benzhenJindu/100))
                    end,function ()
                        if toPogress2 < 100 then
                            self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
                            self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(false)
                            self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_2"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_2"):getContentSize().width * (toPogress2/100))
                        else
                            self.m_collectJindanProgressUpEff:setPositionX(-99999)
                        end
                    end)
                else
                    self.m_collectJindanProgress:findChild("LoadingBar_1"):setPercent(toPogress1)
                    self.m_collectJindanProgress:findChild("LoadingBar_2"):setPercent(toPogress2)
                
                    if toPogress2 < 100 then
                        self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
                        self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(false)
                        self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_2"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_2"):getContentSize().width * (toPogress2/100))
                    else
                        self.m_collectJindanProgressUpEff:setPositionX(-99999)
                    end
                end
            else--要先增长第一阶段
                if isPlayAni then
                    local actionTm1 = actionTm * ((phase1Num - (totalNum - leftNum - newAddNum))/newAddNum)
                    local actionTm2 = actionTm - actionTm1
                    self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(false)
                    self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(true)
                    -- self.m_collectJindanProgressUpEff:playAction("yici")
                    self.m_collectJindanProgressUpEff:findChild("yici"):setPositionType(0)
                    self.m_collectJindanProgressUpEff:findChild("yici"):resetSystem()
                    self:progressUpdate(self.m_collectJindanProgress:findChild("LoadingBar_1"),toPogress1,actionTm1,function ()
                        local benzhenJindu = self.m_collectJindanProgress:findChild("LoadingBar_1"):getPercent()
                        self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_1"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_1"):getContentSize().width * (benzhenJindu/100))
                    end,function ()
                        self:progressUpdate(self.m_collectJindanProgress:findChild("LoadingBar_2"),toPogress2,actionTm2,function ()
                            local benzhenJindu = self.m_collectJindanProgress:findChild("LoadingBar_2"):getPercent()
                            self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_2"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_2"):getContentSize().width * (benzhenJindu/100))
                        end,function ()
                            self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_2"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_2"):getContentSize().width * (toPogress2/100))
                            self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
                            self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(false)
                        end)
                    end)
                else
                    self.m_collectJindanProgress:findChild("LoadingBar_1"):setPercent(toPogress1)
                    self.m_collectJindanProgress:findChild("LoadingBar_2"):setPercent(toPogress2)
                    self.m_collectJindanProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
                    self.m_collectJindanProgressUpEff:findChild("yici"):setVisible(false)
                    self.m_collectJindanProgressUpEff:setPositionX(self.m_collectJindanProgress:findChild("LoadingBar_2"):getPositionX() + self.m_collectJindanProgress:findChild("LoadingBar_2"):getContentSize().width * (toPogress2/100))
                end
            end
        end
    else
        self.m_collectJindanProgress:findChild("LoadingBar_1"):setPercent(toPogress1)
        self.m_collectJindanProgress:findChild("LoadingBar_2"):setPercent(toPogress2)
    end
end
--进度条增长
function CodeGameScreenTrainYourDragonMachine:progressUpdate(pogressNode, toPogress,time,updateFunc,endFunc)
    if self.m_progressUpdateID ~= nil then
        --有更新在走
        scheduler.unscheduleGlobal(self.m_progressUpdateID)
        self.m_progressUpdateID = nil
        -- return
    end
    local startPro = pogressNode:getPercent()
    if toPogress - startPro < 0.001 then
        --已经涨完了，只是数字上有一些小误差搞事
        pogressNode:setPercent(toPogress)
        if endFunc then
            endFunc()
        end
        return
    end
    self.m_progressUpdateID = scheduler.scheduleUpdateGlobal(
            function(dt)
                local zengzhang = (toPogress - startPro)/time * dt--本帧增长
                if pogressNode:getPercent() >= toPogress or zengzhang <= 0.001 then
                    pogressNode:setPercent(toPogress)
                    scheduler.unscheduleGlobal(self.m_progressUpdateID)
                    self.m_progressUpdateID = nil
                    if endFunc then
                        endFunc()
                    end
                    return
                end
                
                local benzhenToPogress = pogressNode:getPercent() + zengzhang
                pogressNode:setPercent(benzhenToPogress)
                if updateFunc then
                    updateFunc()
                end
            end
        )
end
--更新收集进度  addNum增加的进度数 没传默认读服务器数据(respin的)
function CodeGameScreenTrainYourDragonMachine:updateCollectProgree(isPlayAni,addNum)
    local toPogress = 0
    if addNum ~= nil then
        self.m_collectProgress.currCollectCount = self.m_collectProgress.currCollectCount + addNum
        toPogress = self.m_collectProgress.currCollectCount/self.m_collectProgress.collectTotalCount * 100
        -- self.m_collectProgress:findChild("m_lab_num"):setString((collectData.collectTotalCount - collectData.collectLeftCount).."/"..collectData.collectTotalCount)
        if toPogress > 100 then
            toPogress = 100
        end
    elseif self.m_runSpinResultData.p_rsExtraData.collectCount then
        self.m_collectProgress.currCollectCount = self.m_runSpinResultData.p_rsExtraData.collectCount
        toPogress = self.m_runSpinResultData.p_rsExtraData.collectCount/self.m_collectProgress.collectTotalCount * 100
        -- self.m_collectProgress:findChild("m_lab_num"):setString((collectData.collectTotalCount - collectData.collectLeftCount).."/"..collectData.collectTotalCount)
        if toPogress > 100 then
            toPogress = 100
        end
    end
    if toPogress == 0 then
        if self.m_collectProgress:findChild("shuomingtiao"):isVisible() == false then
            self.m_collectProgress:findChild("shuomingtiao"):setVisible(true)
            self.m_collectProgress:playAction("idle",true)
            for i,respinCollectWinCoinNode in ipairs(self.m_respinCollectWinCoinNode) do
                respinCollectWinCoinNode:setVisible(false)
            end
        end
    else
        if self.m_collectProgress:findChild("shuomingtiao"):isVisible() == true then
            self.m_collectProgress:playAction("xiaoshi",false,function ()
                self.m_collectProgress:findChild("shuomingtiao"):setVisible(false)
                if isPlayAni then--表明非初始化调用
                    for i,respinCollectWinCoinNode in ipairs(self.m_respinCollectWinCoinNode) do
                        respinCollectWinCoinNode:setVisible(true)
                    end
                end
            end)
        end
    end
    if isPlayAni then
        if self.m_collectProgress:findChild("LoadingBar_1"):getPercent() >= toPogress then
            return
        end
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_progressUp.mp3")
        self.m_collectProgress:playAction("actionframe",false,function ()
            self.m_collectProgress:playAction("idle2")
        end)
        local startPro = self.m_collectProgress:findChild("LoadingBar_1"):getPercent()
        local dt1 = 15/30--进度条动画时长
        self.m_collectProgressUpEff:setVisible(true)
        self.m_collectProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(false)
        self.m_collectProgressUpEff:findChild("yici"):setVisible(true)
        -- self.m_collectProgressUpEff:playAction("yici")
        self.m_collectProgressUpEff:findChild("yici"):setPositionType(0)
        self.m_collectProgressUpEff:findChild("yici"):resetSystem()
        -- 播放进度条动画
        self.m_progressUpdateID = scheduler.scheduleUpdateGlobal(
            function(dt)
                if self.m_collectProgress:findChild("LoadingBar_1"):getPercent() >= toPogress then
                    self.m_collectProgress:findChild("LoadingBar_1"):setPercent(toPogress)
                    scheduler.unscheduleGlobal(self.m_progressUpdateID)
                    self.m_progressUpdateID = nil
                    if toPogress < 100 then
                        self.m_collectProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
                        self.m_collectProgressUpEff:findChild("yici"):setVisible(false)
                    else
                        self.m_collectProgressUpEff:setVisible(false)
                        self.m_collectProgressUpEff:setPositionX(-9999)
                    end
                    return
                end
                local zengzhang = (toPogress - startPro)/dt1 * dt--本帧增长
                local benzhenToPogress = self.m_collectProgress:findChild("LoadingBar_1"):getPercent() + (toPogress - startPro)/dt1 * dt
                self.m_collectProgress:findChild("LoadingBar_1"):setPercent(benzhenToPogress)

                self.m_collectProgressUpEff:setPositionX(self.m_collectProgress:findChild("LoadingBar_1"):getPositionX() + self.m_collectProgress:findChild("LoadingBar_1"):getContentSize().width * (benzhenToPogress/100))
            end
        )
    else
        self.m_collectProgress:findChild("LoadingBar_1"):setPercent(toPogress)

        --初始化调这里一次，若以后不是只初始化的时候调到这里 就要改了
        local totalbet = globalData.slotRunData:getCurTotalBet()
        for i,respinCollectWinCoinNode in ipairs(self.m_respinCollectWinCoinNode) do
            if self.m_collectProgress.currCollectCount > 0 then
                if self.m_collectProgress.currCollectCount >= self.m_respinCollectWinCoinNum[i] then
                    respinCollectWinCoinNode:setVisible(false)
                else
                    respinCollectWinCoinNode:setVisible(true)
                end
            else
                respinCollectWinCoinNode:setVisible(false)
            end
            respinCollectWinCoinNode:playAction("idle",true)

            if type(self.m_respinCollectWinCoinMutiple[i]) == "string" then

            else
                local aa = respinCollectWinCoinNode:findChild("m_lb_coins_1")
                respinCollectWinCoinNode:findChild("m_lb_coins_1"):setString(util_formatCoins(totalbet*self.m_respinCollectWinCoinMutiple[i], 3,nil,nil,true))
            end
        end
        
        if toPogress > 0 and toPogress < 100 then
            self.m_collectProgressUpEff:setVisible(true)
            self.m_collectProgressUpEff:findChild("jindutiaoidlelizi"):setVisible(true)
            self.m_collectProgressUpEff:findChild("yici"):setVisible(false)
            self.m_collectProgressUpEff:setPositionX(self.m_collectProgress:findChild("LoadingBar_1"):getPositionX() + self.m_collectProgress:findChild("LoadingBar_1"):getContentSize().width * (toPogress/100))
        end
    end
end

--检测是不是respin的触发轮
function CodeGameScreenTrainYourDragonMachine:isRespinInit()
    return self.m_runSpinResultData.p_features[2] == SLOTO_FEATURE.FEATURE_RESPIN
end
function CodeGameScreenTrainYourDragonMachine:showRespinView()
    self:clearCurMusicBg()
    local waitTime = 0
    --如果是触发轮播放触发动画
    if self:isRespinInit() then
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_bonusTrigger.mp3")
        for row = 1, self.m_iReelRowNum do
            for col = 1, self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and self:isFixSymbol(slotNode.p_symbolType) then
                    local showOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType)
                    slotNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - row + showOrder)
                    self:setSlotNodeEffectParent(slotNode)
                    slotNode:runAnim("actionframe",false,function ()
                        slotNode:runAnim("idleframe",true)
                    end)
                end
            end
        end
        waitTime = 2.5
    end

    performWithDelay(self,function()
        self:showGuochang(function ()
            --可随机的普通信号块
            local randomTypes = self:getRespinRandomTypes()
            --可随机的特殊信号
            local endTypes = self:getRespinLockTypes()
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
            --ui切换到respin模式
            self:changeReSpinStartUI()
            --刷新respin次数
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            --播背景音乐
            self:resetMusicBg()
            --就当刚转完一轮
            if self:isRespinInit() == false then
                self:reSpinReelDown()
            else
                --等龙头升完
                performWithDelay(self,function ()
                    self:reSpinReelDown()
                end,30/30)
            end

            self.m_isrespinInit = true
        end,function ()
            if self:isRespinInit() == false then
                self:runNextReSpinReel()
            end
        end)
        
    end,waitTime)
end
function CodeGameScreenTrainYourDragonMachine:initRespinView(endTypes, randomTypes)
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
        nil
    )
    --隐藏 normal盘面
    self:setReelSlotsNodeVisible(false)
end
----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenTrainYourDragonMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if self:isFixSymbol(symbolType) == false then
                symbolType = self.SYMBOL_SCORE_10
            end
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local worldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(iRow,iCol)) 
            -- local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            -- pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            -- local columnData = self.m_reelColDatas[iCol]
            -- local slotNodeH = columnData.p_showGridH
            -- pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = worldPos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end
--ReSpin刷新数量
function CodeGameScreenTrainYourDragonMachine:changeReSpinUpdateUI(curCount,isplaySound)
    if self.m_respinBar.showNum == curCount then
        return
    end
    self.m_respinBar.showNum = curCount
    for i = 1,3 do
        if self.m_respinBarNumAniTab[i]:isVisible() == true then
            self.m_respinBarNumAniTab[i]:playAction("actionframe",false,function ()
                self.m_respinBarNumAniTab[i]:setVisible(false)
            end)
        end
    end
    if curCount > 0 then
        self.m_respinBarNumAniTab[curCount]:setVisible(true)
        
        if curCount == 3 then
            self.m_respinBarNumAniTab[curCount]:playAction("actionframe1")
            self.m_respinBarNumAniTab[curCount]:findChild("baozhatexiao"):setVisible(true)
            if isplaySound == true then
                gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_respinNumReset.mp3")
            end
        else
            self.m_respinBarNumAniTab[curCount]:playAction("actionframe1")
            self.m_respinBarNumAniTab[curCount]:findChild("baozhatexiao"):setVisible(false)
        end
    end
end
--ReSpin开始改变UI状态
function CodeGameScreenTrainYourDragonMachine:changeReSpinStartUI()
    --轮盘动画
    self:runCsbAction("respin")
    --背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"respin",true})
    self.m_bgBird:setVisible(false)
    self.m_collectJindanProgress:setVisible(false)
    -- self:hideFreeSpinBar()
    self.m_freespinBar:setVisible(false)

    self.m_respinBar:setVisible(true)
    self.m_collectProgress:setVisible(true)
    if self:isRespinInit() then
        self:updateCollectProgree(false,0)
    else
        self:updateCollectProgree(false)
    end

    self.m_tishiBar:setVisible(false)

    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_longtouchuxian.mp3")
    self.m_leftLongtou:setVisible(true)
    self.m_rightLongtou:setVisible(true)
    self.m_leftLongtou:setAnimation(0,"star",false)
    self.m_leftLongtou:addAnimation(0,"idleframe2",true)
    self.m_rightLongtou:setAnimation(0,"star",false)
    self.m_rightLongtou:addAnimation(0,"idleframe2",true)
    --如果是freepsin里触发的，要把freespin里的钱算上
    self.m_respinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    local winCoin = 0
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonusWin then
        winCoin = self.m_runSpinResultData.p_selfMakeData.bonusWin
    end
    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.triggeredJackpots then
        for i,jackpotData in ipairs(self.m_runSpinResultData.p_rsExtraData.triggeredJackpots) do
            if jackpotData.flag == "collect" then
                winCoin = winCoin + jackpotData.amount
                break
            end
        end
    end
    self.m_respinWinCoin = self.m_respinWinCoin + winCoin
    --去除这个值的干扰
    if globalData.slotRunData.lastWinCoin > 0 then
        globalData.slotRunData.lastWinCoin = 0
    end
    if self.m_respinWinCoin == 0 then
        self.m_bottomUI:checkClearWinLabel()
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_respinWinCoin,false,false})
    end
    if self.m_reConnection == true and self:isRespinInit() == false then
        if self.m_runSpinResultData.p_rsExtraData.triggeredJackpots then
            local collectedJackpotTab = clone(self.m_runSpinResultData.p_rsExtraData.triggeredJackpots)
            --去掉进度条中的jackpot
            for i,collectedJackpot in ipairs(collectedJackpotTab) do
                if collectedJackpot.flag == "collect" then
                    table.remove(collectedJackpotTab,i)
                    break
                end
            end

            for i,collectedJackpot in ipairs(collectedJackpotTab) do
                local symbolType = self.SYMBOL_FIX_MINI
                if collectedJackpot.type == "Mini" then
                    symbolType = self.SYMBOL_FIX_MINI
                elseif collectedJackpot.type == "Minor" then
                    symbolType = self.SYMBOL_FIX_MINOR
                elseif collectedJackpot.type == "Major" then
                    symbolType = self.SYMBOL_FIX_MAJOR
                elseif collectedJackpot.type == "Grand" then
                    symbolType = self.SYMBOL_FIX_GRAND
                end
                local fileName = self:getSymbolCCBNameByType(self,symbolType)
                local symbolNode = util_createAnimation(fileName..".csb")
                self:findChild("shouji_link"):addChild(symbolNode)
                table.insert(self.m_respinJackpotSymbolTab,symbolNode)
                local rowNum = 2--一行放2个
                local jiange = 70--上下左右间隔70
                local totalNum = #self.m_respinJackpotSymbolTab
                symbolNode:setPosition(cc.p(((totalNum-1)%rowNum)*jiange, -math.floor ((totalNum-1)/rowNum) * jiange))
                -- util_csbPauseForIndex(symbolNode.m_csbAct,455)
                symbolNode:playAction("idle2",true)
                symbolNode.p_symbolType = symbolType
                symbolNode:findChild("xing_bg"):setVisible(false)
            end
        end
    end
end
--ReSpin结算改变UI状态
function CodeGameScreenTrainYourDragonMachine:reSpinOverchangeUI()
    self:setReelSlotsNodeVisible(true)
    self:removeRespinNode()
    if self.m_bProduceSlots_InFreeSpin == true then
        -- self:showFreeSpinBar()
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
        self:levelFreeSpinEffectChange()
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_resWinCoins)
        --轮盘动画
        self:runCsbAction("normal")
        --背景动画
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
        util_spinePlay(self.m_bgBird,"idle",true)
        self.m_bgBird:setVisible(true)
        self.m_collectJindanProgress:setVisible(true)
        self.m_respinBar:setVisible(false)
        self.m_collectProgress:setVisible(false)
        self.m_collectProgressUpEff:setVisible(false)
        self.m_collectProgressUpEff:setPositionX(-9999)
        self.m_tishiBar:setVisible(true)
    end

    self.m_leftLongtou:setAnimation(0,"over",false)
    self.m_rightLongtou:setAnimation(0,"over",false)
    util_spineEndCallFunc(self.m_leftLongtou,"over",function ()
        self.m_leftLongtou:setVisible(false)
        self.m_rightLongtou:setVisible(false)
    end)
    
    for row = 1,self.m_iReelRowNum do
        for col = 1,self.m_iReelColumnNum do
            local symbolNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
            symbolNode:runAnim("idleframe",true)
        end
    end

    --清除respin下的一些变量
    for i,respinJackpotSymbol in ipairs(self.m_respinJackpotSymbolTab) do
        respinJackpotSymbol:removeFromParent()
    end
    self.m_respinJackpotSymbolTab = {}
    self.m_respinWinCoin = 0
    self.m_isrespinInit = false
    self.m_collectProgress.currCollectCount = 0
end

function CodeGameScreenTrainYourDragonMachine:showRespinOverView(effectData)
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        end
    end

    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_respinOver.mp3")
    self:playCoinWinEffectUI()


    self.m_collectAddCoinEffect:setVisible(false)
    self.m_collectAddCoinEffect:playAction("actionframe2",false,function ()
        self.m_collectAddCoinEffect:setVisible(false)
        local strCoins = util_formatCoins(self.m_runSpinResultData.p_fsWinCoins,11)
        -- local view = self:showReSpinOver(strCoins,function()
            self:showGuochang(function ()
                self:reSpinOverchangeUI()
            end,function ()
                self:triggerReSpinOverCallFun(self.m_serverWinCoins)
            end)
        -- end)
        -- gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_linghtning_over_win.mp3")
        -- local node=view:findChild("m_lb_coins")
        -- view:updateLabelSize({label = node,sx = 0.8,sy = 0.8},1010)
    end)
end

--重写组织respinData信息
function CodeGameScreenTrainYourDragonMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenTrainYourDragonMachine:MachineRule_SpinBtnCall()

    self:showSmallDragonTip(true )
    self:showBigDragonTip(true )

    gLobalSoundManager:setBackgroundMusicVolume(1)
    return false -- 用作延时点击spin调用
end
--轮盘开始滚动
function CodeGameScreenTrainYourDragonMachine:beginReel()
    CodeGameScreenTrainYourDragonMachine.super.beginReel(self)
    self.m_reConnection = false
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    for i,scatterFreespinMore in ipairs(self.m_scatterFreespinMoreTab) do
        scatterFreespinMore:removeFromParent()
    end
    self.m_scatterFreespinMoreTab = {}
end

function CodeGameScreenTrainYourDragonMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        self:playEnterGameSound("TrainYourDragonSounds/music_TrainYourDragon_enter.mp3")
        -- gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_enter.mp3")
        -- scheduler.performWithDelayGlobal(function ()
        --     self.m_enterGameMusicIsComplete = true
        --     self:resetMusicBg()
        --     if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
        --         self:setMinMusicBGVolume()
        --     end
        -- end,2.5,self:getModuleName())
    end,0.4,self:getModuleName())
end

function CodeGameScreenTrainYourDragonMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)
    self:addObservers()

    self:updateCollectJindanProgree(false)
    self:initCollectJindanProgreeIcon()
end
function CodeGameScreenTrainYourDragonMachine:addObservers()
	BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        if self:getCurrSpinMode() == RESPIN_MODE then
            return
        end
 
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 3
        else
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "TrainYourDragonSounds/music_TrainYourDragon_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:scatterClicked(params[1],params[2])
    end,"CodeGameScreenTrainYourDragonMachine_scatterClicked")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:showTrainYourDragonDragonGrowWinCoinView(params[1])
    end,"CodeGameScreenTrainYourDragonMachine_showTrainYourDragonDragonGrowWinCoinView")
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:showTrainYourDragonChooseGameView()
    end,"CodeGameScreenTrainYourDragonMachine_showTrainYourDragonChooseGameView")


    gLobalNoticManager:addObserver(self,function(self,params)
        self:dragonGrowXiaoLongEnd()
    end,"CodeGameScreenTrainYourDragonMachine_dragonGrowXiaoLongEnd")
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:bonusGameOver()
    end,"CodeGameScreenTrainYourDragonMachine_bonusGameOver")
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:SpinResultParseResultData(params[1])
    end,"CodeGameScreenTrainYourDragonMachine_SpinResultParseResultData")
    
end

function CodeGameScreenTrainYourDragonMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)
    self:removeObservers()
    
    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_progressUpdateID then
        scheduler.unscheduleGlobal(self.m_progressUpdateID)
        self.m_progressUpdateID = nil
    end
end
-- ------------玩法处理 --

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenTrainYourDragonMachine:addSelfEffect()
    -- 金蛋收集
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        if self.m_runSpinResultData.p_collectNetData[1] and self.m_runSpinResultData.p_collectNetData[1].collectChangeCount > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COLLECT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_EFFECT
        end
        -- 金蛋孵化成小龙
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.collectWin and self.m_runSpinResultData.p_collectNetData[1].collectLeftCount > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COLLECTTOCHANGEXIAOLONG_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECTTOCHANGEXIAOLONG_EFFECT
        end
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTrainYourDragonMachine:MachineRule_playSelfEffect(effectData)
    -- 金蛋收集
    if effectData.p_selfEffectType == self.COLLECT_EFFECT then
        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) or self:checkHasGameEffectType(GameEffect.EFFECT_SELF_EFFECT,self.COLLECTTOCHANGEXIAOLONG_EFFECT) then
            self:collectJindan(true)
        else
            self:collectJindan(false)
        end
    end
    -- 金蛋孵化成小龙
    if effectData.p_selfEffectType == self.COLLECTTOCHANGEXIAOLONG_EFFECT then
        self:clearCurMusicBg()
        self:showDragonGrowView(1)
    end
	return true
end
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenTrainYourDragonMachine:checkHasGameEffectType(effectType,selfEffectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i=1 ,effectLen , 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType then
            if effectType == GameEffect.EFFECT_SELF_EFFECT then
                if selfEffectType == self.m_gameEffects[i].p_selfEffectType then
                    return true
                end
            else
                return true
            end
        end
    end

    return false
end
--respin滚完下落(第一次下落)
function CodeGameScreenTrainYourDragonMachine:firstDroped()
    self:respinSymbolDrop(self.m_runSpinResultData.p_selfMakeData.dropDataFirst)
    if self:isRespinInit() == false and self.m_reConnection == true then
        self:respinPlayNextEffect()
    else
        performWithDelay(self,function ()
            self:respinPlayNextEffect()
        end,12/30)
    end
end
--消除行(一次性消除多行用的，现在玩法是一行一行消除，就只重连用一下了)
function CodeGameScreenTrainYourDragonMachine:removeRows()
    local removeRowsNumTab = self.m_runSpinResultData.p_selfMakeData.removeRows
    if self:isRespinInit() == false and self.m_reConnection == true then
        for i,rowId in ipairs(removeRowsNumTab) do
            local row = self.m_iReelRowNum - rowId
            local symbolNodeTab = self.m_respinView:getOneRowRespinNode(row)
            for i,symbolNode in ipairs(symbolNodeTab) do
                local respinSlot = self.m_respinView:getRespinNode(symbolNode.p_rowIndex,symbolNode.p_cloumnIndex)
                respinSlot:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
                symbolNode:removeFromParent()
            end
        end
        --更新进度条
        self:updateCollectProgree(false)

        self:respinPlayNextEffect()
    else
        self.m_flySymbolTab = {}
        --播放消除特效
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_xiaochu.mp3")
        for i,rowId in ipairs(removeRowsNumTab) do
            local row = self.m_iReelRowNum - rowId
            -- local removeAni = util_createAnimation("TrainYourDragon_longtou_xiaochu.csb")
            -- self.m_clipParent:addChild(removeAni,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
            local pos = self:getNodePosByColAndRow(row,3)
            -- removeAni:setPosition(pos)
            -- removeAni:playAction("xiaochu",false,function ()
            --     removeAni:removeFromParent()
            -- end)

            local removeAni1 = util_createAnimation("TrainYourDragon_longtou_xiaochu_jindu.csb")
            self:findChild("jindutiao_2"):addChild(removeAni1,1)
            -- self.m_clipParent:addChild(removeAni1,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
            -- removeAni1:setPosition(pos)
            local worldPos = self.m_clipParent:convertToWorldSpace(pos)
            local localpos = self:findChild("jindutiao_2"):convertToNodeSpace(worldPos)
            removeAni1:setPosition(localpos)
            removeAni1:playAction("xiaochu",false,function ()
                removeAni1:removeFromParent()
            end)

        end
        self.m_leftLongtou:setAnimation(0,"actionframe",false)
        self.m_leftLongtou:addAnimation(0,"idleframe2",true)
        self.m_rightLongtou:setAnimation(0,"actionframe",false)
        self.m_rightLongtou:addAnimation(0,"idleframe2",true)
        --删除图标
        performWithDelay(self,function ()
            for i,rowId in ipairs(removeRowsNumTab) do
                local row = self.m_iReelRowNum - rowId
                local symbolNodeTab = self.m_respinView:getOneRowRespinNode(row)
                for i,symbolNode in ipairs(symbolNodeTab) do
                    local respinSlot = self.m_respinView:getRespinNode(symbolNode.p_rowIndex,symbolNode.p_cloumnIndex)
                    respinSlot:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)

                    respinSlot.m_lastNode:setVisible(true)
                    -- if respinSlot.m_lastNode.p_symbolType >= 95 then
                    --     local symbolType = self.SYMBOL_SCORE_10
                    --     respinSlot.m_lastNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                    --     -- respinSlot.m_lastNode:runAnim("dark")
                    -- end

                    if symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL1 then
                        symbolNode:playAction("actionframe1",false,function ()
                            symbolNode:removeFromParent()
                        end)
                    else
                        symbolNode:playAction("actionframe1",false,function ()
                            symbolNode:playAction("idle1",true)
                        end)
                        table.insert(self.m_flySymbolTab,symbolNode)
                    end
                end
            end
            --更新进度条
            self:updateCollectProgree(true)
            --开始收集消除的图标
            if #self.m_flySymbolTab > 0 then
                performWithDelay(self,function ()
                    --先排个序
                    table.sort(self.m_flySymbolTab,function (symbol1,symbol2)
                        return symbol1.p_cloumnIndex < symbol2.p_cloumnIndex
                    end)
                    --再开始收集
                    self:collectRemoveSymbol()
                end,30/30)
            else
                self:respinPlayNextEffect()
            end
        end,15/30)
    end
end
--消除一行
function CodeGameScreenTrainYourDragonMachine:removeOneRow()
    local symbolNodeTab = self.m_respinView:getOneRowRespinNode(1)
    --第一行没满，不用消除了
    if #symbolNodeTab < self.m_iReelColumnNum then
        self:respinPlayNextEffect()
        return
    end
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_xiaochu.mp3")
    -- local removeAni = util_createAnimation("TrainYourDragon_longtou_xiaochu.csb")
    -- self.m_clipParent:addChild(removeAni,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    local pos = self:getNodePosByColAndRow(1,3)
    -- removeAni:setPosition(pos)
    -- removeAni:playAction("xiaochu",false,function ()
    --     removeAni:removeFromParent()
    -- end)

    if self.m_collectProgress.currCollectCount < self.m_collectProgress.collectTotalCount then
        local removeAni1 = util_createAnimation("TrainYourDragon_longtou_xiaochu_jindu.csb")
        self:findChild("jindutiao_2"):addChild(removeAni1,1)
        -- self.m_clipParent:addChild(removeAni1,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
        -- removeAni1:setPosition(pos)
        local worldPos = self.m_clipParent:convertToWorldSpace(pos)
        local localpos = self:findChild("jindutiao_2"):convertToNodeSpace(worldPos)
        removeAni1:setPosition(localpos)
        removeAni1:playAction("xiaochu",false,function ()
            --更新进度条
            self:updateCollectProgree(true,1)

            removeAni1:removeFromParent()
        end)
        if self.m_collectProgress.currCollectCount + 1 <= self.m_collectProgress.collectTotalCount/2 then
            removeAni1:findChild("huoqiu_"..(self.m_collectProgress.currCollectCount+1)):setVisible(true)
        else
            removeAni1:setScaleX(-1)
            removeAni1:findChild("huoqiu_"..(self.m_collectProgress.collectTotalCount - self.m_collectProgress.currCollectCount)):setVisible(true)
        end
    else
        self.m_collectProgress.currCollectCount = self.m_collectProgress.currCollectCount + 1
    end

    self.m_leftLongtou:setAnimation(0,"actionframe",false)
    self.m_leftLongtou:addAnimation(0,"idleframe2",true)
    self.m_rightLongtou:setAnimation(0,"actionframe",false)
    self.m_rightLongtou:addAnimation(0,"idleframe2",true)

    self.m_flySymbolTab = {}
    --删除图标
    performWithDelay(self,function ()
        self.m_isYindanxiaoshi = false--银蛋是否消失了
        self.m_jindanCollectEnd = false--金蛋是否收集完了
        local yindanRemoveTime = 0
        for i,symbolNode in ipairs(symbolNodeTab) do
            local respinSlot = self.m_respinView:getRespinNode(symbolNode.p_rowIndex,symbolNode.p_cloumnIndex)
            respinSlot:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)

            respinSlot.m_lastNode:setVisible(true)
            -- if respinSlot.m_lastNode.p_symbolType >= 95 then
            --     local symbolType = self.SYMBOL_SCORE_10
            --     respinSlot.m_lastNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
            --     -- respinSlot.m_lastNode:runAnim("dark")
            -- end

            if symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL1 then
                symbolNode:playAction("actionframe1",false,function ()
                    symbolNode:removeFromParent()
                end)
                if yindanRemoveTime == 0 then
                    yindanRemoveTime = util_csbGetAnimTimes(symbolNode.m_csbAct,"actionframe1")
                end
            else
                symbolNode:playAction("actionframe1",false,function ()
                    symbolNode:playAction("idle1",true)
                end)
                table.insert(self.m_flySymbolTab,symbolNode)
            end
        end
        
        -- --更新进度条
        -- self:updateCollectProgree(true,1)
        --开始收集消除的图标
        if #self.m_flySymbolTab > 0 then
            performWithDelay(self,function ()
                --先排个序
                table.sort(self.m_flySymbolTab,function (symbol1,symbol2)
                    return symbol1.p_cloumnIndex < symbol2.p_cloumnIndex
                end)
                --再开始收集
                self:collectRemoveSymbol()
            end,30/30)
        else
            self.m_jindanCollectEnd = true
        end
        if yindanRemoveTime == 0 then
            self.m_isYindanxiaoshi = true
        else
            performWithDelay(self,function ()
                --银蛋消失
                self.m_isYindanxiaoshi = true
                --检测收集奖励
                self:respinCollectGiveCoin()
            end,yindanRemoveTime + 0.3)
        end
    end,15/30)
end
--开始收集消除的图标
function CodeGameScreenTrainYourDragonMachine:collectRemoveSymbol()
    if #self.m_flySymbolTab == 0 then
        self.m_jindanCollectEnd = true
        self:respinCollectGiveCoin()
        return
    end
    local symbolNode = self.m_flySymbolTab[1]
    table.remove(self.m_flySymbolTab,1)
    --一般赢钱图标飞到lastwin处
    if symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL2 then
        local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        local startPos = self:convertToNodeSpace(worldPos)
        symbolNode:retain()
        symbolNode.m_csbAct:retain()
        symbolNode:removeFromParent()
        self:addChild(symbolNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        symbolNode:release()
        symbolNode:runAction(symbolNode.m_csbAct)
        symbolNode.m_csbAct:release()
        symbolNode:setPosition(startPos)
        symbolNode:setScale(self.m_machineRootScale)

        local coinLab = self.m_bottomUI:getNormalWinLabel()
        local winCoinPos = coinLab:getParent():convertToWorldSpace(cc.p(coinLab:getPosition()))
        local endPos = self:convertToNodeSpace(winCoinPos)

        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_dancollect.mp3")
        local moveTime = util_csbGetAnimTimes(symbolNode.m_csbAct,"fly")
        local move = cc.MoveTo:create(moveTime,endPos)
        local func = cc.CallFunc:create(function ()
            local winCoin = symbolNode.showScore
            self.m_respinWinCoin = self.m_respinWinCoin + winCoin
            --去除这个值的干扰
            if globalData.slotRunData.lastWinCoin > 0 then
                globalData.slotRunData.lastWinCoin = 0
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_respinWinCoin,false,false})
            
            symbolNode:playAction("over",false,function ()
                symbolNode:removeFromParent()
            end)
            gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danCollectOver.mp3")
            self:playCoinWinEffectUI()

            self.m_collectAddCoinEffect:setVisible(false)
            self.m_collectAddCoinEffect:playAction("actionframe",false)
            self:collectRemoveSymbol()
        end)
        local seq = cc.Sequence:create(move,func)
        symbolNode:playAction("fly",false)
        symbolNode:runAction(seq)
    else
        --jackpot图标收集起来
        local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        local startPos = self:findChild("shouji_link"):convertToNodeSpace(worldPos)
        symbolNode:retain()
        symbolNode.m_csbAct:retain()
        symbolNode:removeFromParent()
        self:findChild("shouji_link"):addChild(symbolNode)
        symbolNode:release()
        symbolNode:runAction(symbolNode.m_csbAct)
        symbolNode.m_csbAct:release()
        symbolNode:setPosition(startPos)
        table.insert(self.m_respinJackpotSymbolTab,symbolNode)

        local rowNum = 2--一行放2个
        local jiange = 70--上下左右间隔70
        local totalNum = #self.m_respinJackpotSymbolTab
        local endPos = cc.p(((totalNum-1)%rowNum)*jiange, -math.floor ((totalNum-1)/rowNum) * jiange)

        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_jackpotdanMove.mp3")
        local moveTime = util_csbGetAnimTimes(symbolNode.m_csbAct,"fly_jackpot")
        local move = cc.MoveTo:create(moveTime,endPos)
        local func = cc.CallFunc:create(function ()
            -- symbolNode:removeFromParent()
            self:collectRemoveSymbol()
        end)
        local seq = cc.Sequence:create(move,func)
        symbolNode:playAction("fly_jackpot",false,function ()
            symbolNode:playAction("idle2",true)
        end)
        symbolNode:runAction(seq)
    end
end
--消除完检测是否达到收集给金币的条件
function CodeGameScreenTrainYourDragonMachine:respinCollectGiveCoin()
    if self.m_isYindanxiaoshi == true and self.m_jindanCollectEnd == true then
        local rewardIndex = nil
        for i,v in ipairs(self.m_respinCollectWinCoinNum) do
            if self.m_collectProgress.currCollectCount == v then
                rewardIndex = i
                break
            end
        end
        if rewardIndex then
            if self.m_respinCollectWinCoinNode[rewardIndex]:findChild("Particle_5") then
                self.m_respinCollectWinCoinNode[rewardIndex]:findChild("Particle_5"):setPositionType(0)
                self.m_respinCollectWinCoinNode[rewardIndex]:findChild("Particle_5"):resetSystem()
            end
            self.m_respinCollectWinCoinNode[rewardIndex]:playAction("zhongjiang",false,function ()
                self.m_respinCollectWinCoinNode[rewardIndex]:setVisible(false)
                local multipNum = self.m_respinCollectWinCoinMutiple[rewardIndex]
                local rewardCoin = self.m_runSpinResultData.p_selfMakeData.collectMulWin or 0
                if type(multipNum) == "string" then
                    local jackpotWinDataTab = self.m_runSpinResultData.p_rsExtraData.triggeredJackpots
                    for i,jackpotWinData in ipairs(jackpotWinDataTab) do
                        if jackpotWinData.flag == "collect" then
                            rewardCoin = jackpotWinData.amount
                            break
                        end
                    end
                    --grand
                    self:showRespinJackpot(4,rewardCoin,function ()
                        self:playCoinWinEffectUI()
                        self.m_collectAddCoinEffect:setVisible(false)
                        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danCollectOver.mp3")
                        self.m_collectAddCoinEffect:playAction("actionframe",false)
                        self.m_respinWinCoin = self.m_respinWinCoin + rewardCoin
                        --去除这个值的干扰
                        if globalData.slotRunData.lastWinCoin > 0 then
                            globalData.slotRunData.lastWinCoin = 0
                        end
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_respinWinCoin,false,false})

                        self:allSymbolDropedOneRow()
                    end)
                else
                    local totalbet = globalData.slotRunData:getCurTotalBet()
                    self.m_multipleEff:findChild("m_lb_coins_1"):setString(util_formatCoins(totalbet*multipNum, 3,nil,nil,true))
                    self.m_multipleEff:playAction("feizi",false,function ()
                        self.m_multipleEff:setVisible(false)
                        self:allSymbolDropedOneRow()
                    end)
                    local startPosNode = self.m_collectProgress:findChild("winCoinNode"..rewardIndex)
                    local startWorldPos = startPosNode:getParent():convertToWorldSpace(cc.p(startPosNode:getPosition()))
                    local startPos = self:convertToNodeSpace(startWorldPos)
            
                    local coinLab = self.m_bottomUI:getNormalWinLabel()
                    local winCoinPos = coinLab:getParent():convertToWorldSpace(cc.p(coinLab:getPosition()))
                    local endPos = self:convertToNodeSpace(winCoinPos)
            
                    self.m_multipleEff:setVisible(true)
                    self.m_multipleEff:setPosition(startPos)
                    -- local delayTm = cc.DelayTime:create(9/30)
                    local move = cc.EaseIn:create(cc.MoveTo:create(10/30,endPos),1.5)
                    local func = cc.CallFunc:create(function ()
                        self.m_collectAddCoinEffect:setVisible(false)
                        self:playCoinWinEffectUI()
                        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danCollectOver.mp3")
                        self.m_collectAddCoinEffect:playAction("actionframe",false)
                        self.m_respinWinCoin = self.m_respinWinCoin + rewardCoin
                        --去除这个值的干扰
                        if globalData.slotRunData.lastWinCoin > 0 then
                            globalData.slotRunData.lastWinCoin = 0
                        end
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_respinWinCoin,false,false})
                    end)
                    local seq = cc.Sequence:create(move,func)
                    self.m_multipleEff:runAction(seq)
                
                end
            end)
        else
            self:allSymbolDropedOneRow()
        end
    end
end
--消除完所有图标下落一行
function CodeGameScreenTrainYourDragonMachine:allSymbolDropedOneRow()
    -- if self.m_isYindanxiaoshi == true and self.m_jindanCollectEnd == true then
        local symbolNodeTab = self.m_respinView:getAllRespinNode()
        if #symbolNodeTab > 0 then
            --排序，从下到上，从左到右
            table.sort(symbolNodeTab,function (symbolNode1,symbolNode2)
                if symbolNode1.p_rowIndex == symbolNode2.p_rowIndex then
                    return symbolNode1.p_cloumnIndex < symbolNode2.p_cloumnIndex
                end
                return symbolNode1.p_rowIndex < symbolNode2.p_rowIndex
            end)

            gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danMove.mp3")
            for i,symbolNode in ipairs(symbolNodeTab) do
                if symbolNode.p_rowIndex > 0 and symbolNode.p_rowIndex <= self.m_iReelRowNum then
                    self:respinOneSymbolDrop(self:getPosReelIdx(symbolNode.p_rowIndex,symbolNode.p_cloumnIndex),self:getPosReelIdx(symbolNode.p_rowIndex,symbolNode.p_cloumnIndex) + self.m_iReelColumnNum)
                end
            end
            performWithDelay(self,function ()
                self:removeOneRow()
            end,12/30)
        else
            --没有图标了
            self:respinPlayNextEffect()
        end
    -- end
end
--消除完下落(第二次下落)
function CodeGameScreenTrainYourDragonMachine:secondDroped()
    self:respinSymbolDrop(self.m_runSpinResultData.p_selfMakeData.dropDataSecond)
    if self:isRespinInit() == false and self.m_reConnection == true then
        self:respinPlayNextEffect()
    else
        performWithDelay(self,function ()
            self:respinPlayNextEffect()
        end,0.25)
    end
end
--图标下落
function CodeGameScreenTrainYourDragonMachine:respinSymbolDrop(dropData)
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danMove.mp3")
    for i,data in ipairs(dropData) do
        self:respinOneSymbolDrop(data[1],data[2])
    end
end
--一个图标下落
function CodeGameScreenTrainYourDragonMachine:respinOneSymbolDrop(startPos,endPos)
    local startRowCol = self:getRowAndColByPos(startPos)
    local symbolNode = self.m_respinView:getRespinEndNode(startRowCol.iX,startRowCol.iY)
    
    local endRowCol = self:getRowAndColByPos(endPos)
    local endPosition = self:getNodePosByColAndRow(endRowCol.iX,endRowCol.iY)

    symbolNode.p_rowIndex = endRowCol.iX
    symbolNode.p_cloumnIndex = endRowCol.iY
    symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - symbolNode.p_rowIndex)

    if self:isRespinInit() == false and self.m_reConnection == true then
        symbolNode:setPosition(endPosition)
    else
        symbolNode.m_csbAct:retain()
        symbolNode.m_csbNode:stopAllActions()
        symbolNode.m_csbNode:runAction(symbolNode.m_csbAct)
        symbolNode.m_csbAct:release()
        symbolNode:playAction("diaoluo",false,function ()
            symbolNode:playAction("idleframe",true)
        end)
        local move = cc.MoveTo:create(12/30,endPosition)
        local func = cc.CallFunc:create(function ()
            
        end)
        local seq = cc.Sequence:create(move,func)
        symbolNode:runAction(seq)
        
    end

    local startRespinSlot = self.m_respinView:getRespinNode(startRowCol.iX,startRowCol.iY)
    local endRespinSlot = self.m_respinView:getRespinNode(endRowCol.iX,endRowCol.iY)
    startRespinSlot:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    endRespinSlot:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    -- endRespinSlot.m_lastNode:setVisible(false)

    -- startRespinSlot.m_lastNode:setVisible(true)
    -- if startRespinSlot.m_lastNode.p_symbolType >= 95 then
    --     local symbolType = self.SYMBOL_SCORE_10
    --     startRespinSlot.m_lastNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
    --     -- startRespinSlot.m_lastNode:runAnim("dark")
    -- end
end
--respin轮盘滚动全部停止调用
function CodeGameScreenTrainYourDragonMachine:reSpinReelDown(addNode)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    --respin滚完下落
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.dropDataFirst then
        table.insert(self.m_respinEffect,self.DROP_FIRST_EFFECT)
    end

    --respin消除
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.removeRows then
        table.insert(self.m_respinEffect,self.REMOVE_ROWS_EFFECT)
    end

    --respin消除完下落
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.dropDataSecond then
        if self.m_reConnection == true and self:isRespinInit() == false then
            table.insert(self.m_respinEffect,self.DROP_SECOND_EFFECT)
        end
    end

    if #self.m_respinEffect > 0 and not (self:isRespinInit() == false and self.m_reConnection == true) then
        performWithDelay(self,function ()
            self:respinPlayNextEffect()
        end,0.5)
    else
        self:respinPlayNextEffect()
    end
end
--respin下播放下一个动画效果
function CodeGameScreenTrainYourDragonMachine:respinPlayNextEffect()
    if #self.m_respinEffect > 0 then
        local effect = self.m_respinEffect[1]
        table.remove(self.m_respinEffect,1)
        self:respinPlayEffect(effect)
    else
        self:respinEffectEnd()
    end
end
--respin下播放一个动画效果
function CodeGameScreenTrainYourDragonMachine:respinPlayEffect(effect)
    if effect == self.DROP_FIRST_EFFECT then--respin滚完下落
        self:firstDroped()
    end
    if effect == self.REMOVE_ROWS_EFFECT then--respin消除
        if self.m_reConnection == true and self:isRespinInit() == false then
            self:removeRows()
        else
            self:removeOneRow()
        end
    end
    if effect == self.DROP_SECOND_EFFECT then--respin消除完下落
        self:secondDroped()
    end
end
--respin下全部效果播放完
function CodeGameScreenTrainYourDragonMachine:respinEffectEnd()

    self:setGameSpinStage(STOP_RUN)

    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN)
        self.m_isWaitingNetworkData = false

        return
    end
  
    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    -- if self.m_runSpinResultData.p_reSpinCurCount == 3 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
    -- end
    --开始下轮的滚动
    self.m_reConnection = false
    if self:findChild("guochang"):isVisible() == false then
        self:runNextReSpinReel()
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end
--开始滚动
function CodeGameScreenTrainYourDragonMachine:startReSpinRun()

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end
    end

    

    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)
    
    self:requestSpinReusltData()
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    -- if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
    --     self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    -- end

    self.m_respinView:startMove()


end
function CodeGameScreenTrainYourDragonMachine:getBigSymbolNode(iX, iY)
    local slotNode = nil
    if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[iY] ~= nil then
        local parentData = self.m_slotParents[iY]
        local slotParent = parentData.slotParent
        local bigSymbolInfos = self.m_bigSymbolColumnInfo[iY]
        for k = 1, #bigSymbolInfos do
            local bigSymbolInfo = bigSymbolInfos[k]
            for changeIndex=1,#bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == iX then
                    slotNode = slotParent:getChildByTag(iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                    return slotNode, bigSymbolInfo.changeRows
                end
            end
        end
    end
    return slotNode
end
--respin转动结束
function CodeGameScreenTrainYourDragonMachine:reSpinEndAction()
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_respinEnd.mp3")
    performWithDelay(self,function ()
        --如果有jackpot，开始结算jackpot
        if #self.m_respinJackpotSymbolTab > 0 then
            self.m_collectedJackpotIdx = 1
            self:startShowRespinJackpot()
        else
            self:playMultipEff()
        end
    end,0.3)
end
function CodeGameScreenTrainYourDragonMachine:startShowRespinJackpot()
    if self.m_collectedJackpotIdx > #self.m_respinJackpotSymbolTab then
        self:playMultipEff()
        return
    end
    local respinJackpotSymbol = self.m_respinJackpotSymbolTab[self.m_collectedJackpotIdx]
    -- gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_jackpotdanOver.mp3")
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danMove.mp3")
    local worldPos = self:getParent():convertToWorldSpace(cc.p(display.center.x,display.center.y + 34 ) )
    local pos = respinJackpotSymbol:getParent():convertToNodeSpace(worldPos)
    local move = cc.MoveTo:create(20/30,pos)
    respinJackpotSymbol:runAction(move)

    local jackpotWinDataTab = self.m_runSpinResultData.p_rsExtraData.triggeredJackpots
    for i,jackpotWinData in ipairs(jackpotWinDataTab) do
        if jackpotWinData.flag == "collect" then
            table.remove(jackpotWinDataTab,i)
            break
        end
    end

    respinJackpotSymbol:playAction("jiesuan_fly",false,function ()
        performWithDelay(self,function ()
            respinJackpotSymbol:setVisible(false)
        end,0.1)
        -- local winCoin = self.m_runSpinResultData.p_rsExtraData.triggeredJackpots[self.m_collectedJackpotIdx].amount
        local winCoin = jackpotWinDataTab[self.m_collectedJackpotIdx].amount
        self:showRespinJackpot(respinJackpotSymbol.p_symbolType - 100 ,winCoin,function ()
            self.m_respinWinCoin = self.m_respinWinCoin + winCoin
            --去除这个值的干扰
            if globalData.slotRunData.lastWinCoin > 0 then
                globalData.slotRunData.lastWinCoin = 0
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_respinWinCoin,false,false})
            gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danCollectOver.mp3")
            self:playCoinWinEffectUI()
            self.m_collectAddCoinEffect:setVisible(false)
            self.m_collectAddCoinEffect:playAction("actionframe",false)

            self:startShowRespinJackpot()
        end)
        self.m_collectedJackpotIdx = self.m_collectedJackpotIdx + 1
    end)
end
--播放乘倍特效
function CodeGameScreenTrainYourDragonMachine:playMultipEff()
    --收集结束  如果触发乘倍 则收集的钱数加倍
    -- local multip = {
    --     [7] = 2,
    --     [12] = 5
    -- }
    -- if self.m_collectProgress.currCollectCount >= 7 then
    --     local multipNum = 2
    --     if self.m_collectProgress.currCollectCount >= 12 then
    --         self.m_collectProgress.x5:setVisible(false)
    --         multipNum = multip[12]
    --     elseif self.m_collectProgress.currCollectCount >= 7 then
    --         self.m_collectProgress.x2:setVisible(false)
    --         multipNum = multip[7]
    --     end
    --     self.m_multipleEff:playAction("actionframe",false,function ()
    --         self.m_multipleEff:findChild("x"..multipNum):setVisible(false)
    --         self.m_multipleEff:setVisible(false)
    --         self:respinOver()
    --     end)
    --     local startPosNode = self.m_collectProgress:findChild("x"..multipNum)
    --     local startWorldPos = startPosNode:getParent():convertToWorldSpace(cc.p(startPosNode:getPosition()))
    --     local startPos = self:convertToNodeSpace(startWorldPos)

    --     local coinLab = self.m_bottomUI:getNormalWinLabel()
    --     local winCoinPos = coinLab:getParent():convertToWorldSpace(cc.p(coinLab:getPosition()))
    --     local endPos = self:convertToNodeSpace(winCoinPos)

    --     self.m_multipleEff:setVisible(true)
    --     self.m_multipleEff:findChild("x"..multipNum):setVisible(true)
    --     self.m_multipleEff:setPosition(startPos)
    --     local delayTm = cc.DelayTime:create(9/30)
    --     local move = cc.EaseIn:create(cc.MoveTo:create(10/30,endPos),1.5)
    --     local func = cc.CallFunc:create(function ()
    --         self.m_collectAddCoinEffect:setVisible(true)
    --         gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_danCollectOver.mp3")
    --         self.m_collectAddCoinEffect:playAction("actionframe",false)
    --         if self.m_bProduceSlots_InFreeSpin == true then
    --             self.m_respinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    --         else
    --             self.m_respinWinCoin = self.m_runSpinResultData.p_resWinCoins
    --         end
    --         --去除这个值的干扰
    --         if globalData.slotRunData.lastWinCoin > 0 then
    --             globalData.slotRunData.lastWinCoin = 0
    --         end
    --         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_respinWinCoin,false,false})
    --     end)
    --     local seq = cc.Sequence:create(delayTm,move,func)
    --     self.m_multipleEff:runAction(seq)
    -- else
        self:respinOver()
    -- end
end
--respin下收集够次数了额外加钱
function CodeGameScreenTrainYourDragonMachine:respinCollectWinCoin()
    -- 
end
--
function CodeGameScreenTrainYourDragonMachine:respinOver()
    -- self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    -- self:removeRespinNode()
    self:showRespinOverView()
end
--respin结束 移除respin小块对应位置滚轴中的小块
function CodeGameScreenTrainYourDragonMachine:checkRemoveReelNode(node)
    local targSp = self:getReelParent(node.p_cloumnIndex):getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    local slotParentBig = self:getReelBigParent(node.p_cloumnIndex)
    if targSp == nil and slotParentBig then
        targSp = slotParentBig:getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    end
    if targSp == nil then
        targSp = self:getBigSymbolNode(node.p_rowIndex,node.p_cloumnIndex)
    end
    if targSp then
        targSp:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
    end
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenTrainYourDragonMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    local linkSymbol = self.m_respinView:getRespinEndNode(node.p_rowIndex,node.p_cloumnIndex)
    if linkSymbol then
        node:setVisible(true)
        node:changeCCBByName(self:getSymbolCCBNameByType(self, linkSymbol.p_symbolType ), linkSymbol.p_symbolType)
        if linkSymbol.p_symbolType == self.SYMBOL_FIX_SYMBOL2 then
            local score = util_formatCoins(linkSymbol.showScore, 3)
            node:getCcbProperty("m_lb_score"):setString(score)
        end
        if node.p_symbolImage ~= nil and node.p_symbolImage:getParent() ~= nil then
            node.p_symbolImage:removeFromParent()
        end
        node.p_symbolImage = nil
        if node:getCcbProperty("xing_bg") then
            node:getCcbProperty("xing_bg"):setVisible(false)
        end
    else--if node:isVisible() == false then
        node:setVisible(true)
        local symbolType = self:getOneNorSymbol()
        -- if self.m_bProduceSlots_InFreeSpin == true then
        --     if node.p_cloumnIndex == 3 then
        --         symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        --     end
        -- end
        node:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
        node:runAnim("dark")
    end
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex--REEL_SYMBOL_ORDER.REEL_ORDER_1
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
end
--添加过场
function CodeGameScreenTrainYourDragonMachine:showGuochang(func1,func2)
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_guochang.mp3")
    self:findChild("guochang"):setVisible(true)
    self.m_guochangLong:setVisible(true)
    self.m_guochangLong:setAnimation(0,"actionframe",false)
    self.m_guochangEye:playAction("actionframe",false,function ()
        self:findChild("guochang"):setVisible(false)
        if func2 then
            func2()
        end
    end)
    performWithDelay(self,function ()
        self.m_guochangLong:setVisible(false)
        if func1 then
            func1()
        end
    end,60/30)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenTrainYourDragonMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end

--所有effect播放完之后调用
function CodeGameScreenTrainYourDragonMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenTrainYourDragonMachine.super.playEffectNotifyNextSpinCall(self)
end

--获得信号块层级
function CodeGameScreenTrainYourDragonMachine:getBounsScatterDataZorder(symbolType)
    local order = CodeGameScreenTrainYourDragonMachine.super.getBounsScatterDataZorder(self,symbolType)
    if symbolType == self.SYMBOL_BIG_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    return order
end

----
--- 处理spin 成功消息
--
function CodeGameScreenTrainYourDragonMachine:checkOperaSpinSuccess( param )
    -- 触发了玩法 一定概率播特效
    if (param[2].result.features[2] == 1 or param[2].result.features[2] == 3) and not (param[2].result.features[2] == 1 and self:getCurrSpinMode() == FREE_SPIN_MODE) then
        local rand = math.random(1,10)
        if rand <= 4 then
            self:showTriggerEffect(function ()
                CodeGameScreenTrainYourDragonMachine.super.checkOperaSpinSuccess(self,param)
            end)
        else
            CodeGameScreenTrainYourDragonMachine.super.checkOperaSpinSuccess(self,param)
        end
    else
        CodeGameScreenTrainYourDragonMachine.super.checkOperaSpinSuccess(self,param)
    end
end
--显示玩法触发特效
function CodeGameScreenTrainYourDragonMachine:showTriggerEffect(func)
    self:shakeRootNode()
    self.m_triggerEffect:setVisible(true)
    self.m_triggerEffect:playAction("actionframe")
    self.m_triggerEffect:findChild("LIzi"):setPositionType(0)
    self.m_triggerEffect:findChild("LIzi"):resetSystem()
    self.m_triggerEffect:findChild("Wu"):setPositionType(0)
    self.m_triggerEffect:findChild("Wu"):resetSystem()
    self.m_maskLayer:setVisible(true)
    self.m_maskLayer:playAction("actionframe1")
    performWithDelay(self,function ()
        self:hideTriggerEffect(func)
    end,3)
end
--隐藏玩法触发特效
function CodeGameScreenTrainYourDragonMachine:hideTriggerEffect(func)
    self.m_triggerEffect:setVisible(false)
    self.m_maskLayer:setVisible(false)
    self.m_maskLayer:playAction("idlefame")
    if func then
        func()
    end
end
function CodeGameScreenTrainYourDragonMachine:shakeRootNode()
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_shake.mp3")
    local changePosY = 5
    local changePosX = 2
    local actionList2 = {}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,15 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    actionList2[#actionList2+1] = cc.CallFunc:create(function()
        
    end)
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end
--收集金蛋
function CodeGameScreenTrainYourDragonMachine:collectJindan(isNext)
    local moveTm = 0.5
    if isNext == false then
        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECT_EFFECT})
    end
    for row = 1, self.m_iReelRowNum do
        for col = 1,self.m_iReelColumnNum do
            if self.m_stcValidSymbolMatrix[row][col] >= self.SYMBOL_FIX_SYMBOL2 then
                local colrowPos = self:getNodePosByColAndRow(row,col)
                local worldPos = self.m_clipParent:convertToWorldSpace(colrowPos)
                local startPos = self:findChild("jindutiao_2"):convertToNodeSpace(worldPos)
                local lizi = util_createAnimation("TrainYourDragon_jindanshouji.csb")
                lizi:findChild("Particle_1"):setPositionType(0)
                lizi:findChild("Particle_1"):resetSystem()
                lizi:findChild("Particle_2"):setPositionType(0)
                lizi:findChild("Particle_2"):resetSystem()
                lizi:setPosition(startPos)
                self:findChild("jindutiao_2"):addChild(lizi)

                local endWorldPos = self.m_collectJindanProgress:findChild("dan"):getParent():convertToWorldSpace(cc.p(self.m_collectJindanProgress:findChild("dan"):getPosition()))
                local endPos = self:findChild("jindutiao_2"):convertToNodeSpace(endWorldPos)
            
                local move = cc.MoveTo:create(moveTm,endPos)
                local callFun = cc.CallFunc:create(function ()
                    lizi:findChild("Particle_1"):stop()
                    lizi:findChild("Particle_2"):stop()
                    performWithDelay(lizi,function ()
                        lizi:removeFromParent()
                    end,1)
                end)
                lizi:runAction(cc.Sequence:create(move,callFun))
            end
        end
    end
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_jindanshouji.mp3")
    --存储收集数据  这里数据必定有
    self.m_collectData = clone(self.m_runSpinResultData.p_collectNetData[1])
    performWithDelay(self:findChild("jindutiao_2"),function ()
        self:updateCollectJindanProgree(true)
        self.m_collectData = nil
        self.m_collectJindanProgress.jindan:playAction("fankui",false,function ()
            self.m_collectJindanProgress.jindan:playAction("idle",true)
        end)
        if isNext == true then
            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECT_EFFECT})
        end
    end,moveTm)
end
--bonus小游戏
function CodeGameScreenTrainYourDragonMachine:showBonusGameView(effectData)
    if self.m_isInBonus then
        self:showTrainYourDragonChooseGameView()
    else
        performWithDelay(self,function ()
            self:clearCurMusicBg()
            self:setCurrSpinMode(REWAED_SPIN_MODE)
            self.m_bottomUI:checkClearWinLabel()
            self:showDragonGrowView(2)
        end,0.5)
    end
end

-- 通知某种类型动画播放完毕
function CodeGameScreenTrainYourDragonMachine:notifyGameEffectPlayComplete(param)
    local effectType
    if type(param) == "table" then
        effectType = param[1]
    else
        effectType = param
    end
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    for i=1,effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 继续播放动画
                    break
                end
            else
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
                break
            end
        end
    end
end
--显示龙成长界面  growState成长阶段，1为变小龙，2为变大龙
function CodeGameScreenTrainYourDragonMachine:showDragonGrowView(growState)
    if growState == 1 then
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_jindanshoujizhongjiang1.mp3")
        self.m_collectJindanProgress.xiaolong:playAction("zhongjiang")
        performWithDelay(self,function ()
            self.m_collectJindanProgress.xiaolong:playAction("idle2",true)
            local dragonGrowView = util_createView("CodeTrainYourDragonSrc.TrainYourDragonDragonGrowView")
            if dragonGrowView:findChild("root") then
                dragonGrowView:findChild("root"):setScale(self.m_machineRootScale)
            end
            gLobalViewManager:showUI(dragonGrowView)
            dragonGrowView:initViewData(growState)
        end,2)
    else
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_jindanshoujizhongjiang2.mp3")
        self.m_collectJindanProgress.dalong:playAction("zhongjiang")
        performWithDelay(self,function ()
            self.m_collectJindanProgress.dalong:playAction("idle2",true)
            local dragonGrowView = util_createView("CodeTrainYourDragonSrc.TrainYourDragonDragonGrowView")
            if dragonGrowView:findChild("root") then
                dragonGrowView:findChild("root"):setScale(self.m_machineRootScale)
            end
            gLobalViewManager:showUI(dragonGrowView)
            dragonGrowView:initViewData(growState)
        end,2)
    end
end
--显示孵化小龙后的给钱结算界面  showType 1 小龙结算，2大龙结算
function CodeGameScreenTrainYourDragonMachine:showTrainYourDragonDragonGrowWinCoinView(showType)
    local DragonGrowWinCoinView = util_createView("CodeTrainYourDragonSrc.TrainYourDragonDragonGrowWinCoinView")
    if DragonGrowWinCoinView:findChild("root") then
        DragonGrowWinCoinView:findChild("root"):setScale(self.m_machineRootScale)
    end
    gLobalViewManager:showUI(DragonGrowWinCoinView)
    if showType == 1 then
        DragonGrowWinCoinView:initViewData(self.m_runSpinResultData.p_selfMakeData.collectWin,showType)
    else
        DragonGrowWinCoinView:initViewData(self.m_runSpinResultData.p_winAmount,showType)
    end
end
--关闭孵化出小龙后的界面回调
function CodeGameScreenTrainYourDragonMachine:dragonGrowXiaoLongEnd()
    self:resetMusicBg(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{0,true,true})
    local winAmonut = self.m_runSpinResultData.p_winAmount
    --如果没有连线
    if #self.m_reelResultLines <= 0 then
        self:checkFeatureOverTriggerBigWin(winAmonut,GameEffect.EFFECT_BONUS)
    end
    self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECTTOCHANGEXIAOLONG_EFFECT})
end
--显示bonus小游戏界面
function CodeGameScreenTrainYourDragonMachine:showTrainYourDragonChooseGameView()
    local chooseGameView = util_createView("CodeTrainYourDragonSrc.TrainYourDragonChooseGameView")
    if chooseGameView:findChild("root") then
        chooseGameView:findChild("root"):setScale(self.m_machineRootScale)
    end
    gLobalViewManager:showUI(chooseGameView)
    if self.m_isInBonus then
        chooseGameView:initViewData(clone(self.m_initFeatureData.p_data))
        self.m_isInBonus = false
    else
        chooseGameView:initViewData()
    end
end
--bonus小游戏结束回调
function CodeGameScreenTrainYourDragonMachine:bonusGameOver()
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true,true})
    local winAmonut = self.m_runSpinResultData.p_winAmount
    self:checkFeatureOverTriggerBigWin(winAmonut,GameEffect.EFFECT_BONUS)
    self:notifyGameEffectPlayComplete(GameEffect.EFFECT_BONUS)
    self:updateCollectJindanProgree(false)
    self:initCollectJindanProgreeIcon()
end

function CodeGameScreenTrainYourDragonMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData.p_collectNetData = {}
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
    self:setLastWinCoin( spinData.result.winAmount )
end

function CodeGameScreenTrainYourDragonMachine:showSmallDragonTip(_isOver )
    
    if _isOver then
        if self.m_tipSmallDragon.states and self.m_tipSmallDragon.states ~= "over" then
            self.m_collectJindanProgress:findChild("smallClick"):setVisible(false)
            self.m_tipSmallDragon:findChild("click"):setVisible(false)
            self.m_smallTipWaitNode:stopAllActions()
            self.m_tipSmallDragon.states = "over"
            self.m_tipSmallDragon:runCsbAction("over",false,function(  )
                self.m_collectJindanProgress:findChild("smallClick"):setVisible(true)
                self.m_tipSmallDragon.states = "idle"
                self.m_tipSmallDragon:setVisible(false)
            end)
        end
    else
        if not self.m_tipSmallDragon.states or self.m_tipSmallDragon.states == "idle"  then
            self.m_collectJindanProgress:findChild("smallClick"):setVisible(false)
            self.m_tipSmallDragon:findChild("click"):setVisible(true)
            self.m_tipSmallDragon.states = "start"
            self.m_tipSmallDragon:runCsbAction("start",false,function(  )
                self.m_tipSmallDragon.states = "idle"
            end)
            self.m_tipSmallDragon:setVisible(true)
            self.m_smallTipWaitNode:stopAllActions()
            performWithDelay(self.m_smallTipWaitNode,function(  )
                self.m_tipSmallDragon.states = "over"
                self.m_tipSmallDragon:runCsbAction("over",false,function(  )
                    self.m_collectJindanProgress:findChild("smallClick"):setVisible(true)
                    self.m_tipSmallDragon:setVisible(false)
                    self.m_tipSmallDragon.states = "idle"
                end)
            end,3)
        end 
    end
    
    

end

function CodeGameScreenTrainYourDragonMachine:showBigDragonTip(_isOver )
    
    if _isOver then
        if self.m_tipBigDragon.states and self.m_tipBigDragon.states ~= "over" then
            self.m_collectJindanProgress:findChild("bigClick"):setVisible(false)
            self.m_tipBigDragon:findChild("click"):setVisible(false)
            self.m_bigTipWaitNode:stopAllActions()
            self.m_tipBigDragon.states = "over"
            self.m_tipBigDragon:runCsbAction("over",false,function(  )
                self.m_collectJindanProgress:findChild("bigClick"):setVisible(true)
                
                self.m_tipBigDragon:setVisible(false)
                self.m_tipBigDragon.states = "idle"
            end)
        end
    else
        if not self.m_tipBigDragon.states or self.m_tipBigDragon.states == "idle"  then
            self.m_collectJindanProgress:findChild("bigClick"):setVisible(false)
            self.m_tipBigDragon:findChild("click"):setVisible(true)
            self.m_tipBigDragon:setVisible(true)
            self.m_tipBigDragon.states = "start"
            self.m_tipBigDragon:runCsbAction("start",false,function(  )

                self.m_tipBigDragon.states = "idle"
            end)
            self.m_bigTipWaitNode:stopAllActions()
            performWithDelay(self.m_bigTipWaitNode,function(  )
                self.m_tipBigDragon.states = "over"
                self.m_tipBigDragon:runCsbAction("over",false,function(  )
                    self.m_collectJindanProgress:findChild("bigClick"):setVisible(true)
                    self.m_tipBigDragon:setVisible(false)
                    self.m_tipBigDragon.states = "idle"
                end)
            end,3)
        end  
    end
    
    
end

function CodeGameScreenTrainYourDragonMachine:bigDragonTipClick(_sender,_eventType )
    if _eventType == ccui.TouchEventType.ended then

        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then

            if self.m_bProduceSlots_InFreeSpin == true or 
            (self:getCurrSpinMode() == NORMAL_SPIN_MODE and 
            self:getGameSpinStage() ~= IDLE ) or 
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
            and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or 
            self:getCurrSpinMode() == AUTO_SPIN_MODE
            then
                return
            end

            self:showBigDragonTip( )
        end
   
    end
end

function CodeGameScreenTrainYourDragonMachine:smallDragonTipClick(_sender,_eventType )
    if _eventType == ccui.TouchEventType.ended then

        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then

            if self.m_bProduceSlots_InFreeSpin == true or 
            (self:getCurrSpinMode() == NORMAL_SPIN_MODE and 
            self:getGameSpinStage() ~= IDLE ) or 
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
            and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or 
            self:getCurrSpinMode() == AUTO_SPIN_MODE
            then
                return
            end
            
            self:showSmallDragonTip( )
        end
   
    end
end

function CodeGameScreenTrainYourDragonMachine:clsoeSmallDragonTipClick(_sender,_eventType )
    if _eventType == ccui.TouchEventType.ended then

        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then
            self:showBigDragonTip( true ) 
            self:showSmallDragonTip(true )
        end
   
    end
end

function CodeGameScreenTrainYourDragonMachine:closeBigDragonTipClick(_sender,_eventType )
    if _eventType == ccui.TouchEventType.ended then

        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then
            self:showBigDragonTip( true ) 
            self:showSmallDragonTip(true )
        end
   
    end
end




return CodeGameScreenTrainYourDragonMachine