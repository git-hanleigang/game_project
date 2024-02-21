

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local CollectData = require "data.slotsdata.CollectData"
local GameEffectData = require "data.slotsdata.GameEffectData"
local GameScreenApolloMachine = class("GameScreenApolloMachine", BaseNewReelMachine)

GameScreenApolloMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
GameScreenApolloMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 99
GameScreenApolloMachine.FREESPINCHANGEMULTIPLE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1--frespin下变倍数事件

GameScreenApolloMachine.SYMBOL_FIX_GRAND_XBEI = 1104
GameScreenApolloMachine.SYMBOL_FIX_MAJOR_XBEI = 1103
GameScreenApolloMachine.SYMBOL_FIX_MINOR_XBEI = 1102
GameScreenApolloMachine.SYMBOL_FIX_MINI_XBEI = 1101
GameScreenApolloMachine.SYMBOL_FIX_SYMBOL_XBEI = 194

GameScreenApolloMachine.SYMBOL_FIX_GRAND = 104
GameScreenApolloMachine.SYMBOL_FIX_MAJOR = 103
GameScreenApolloMachine.SYMBOL_FIX_MINOR = 102
GameScreenApolloMachine.SYMBOL_FIX_MINI = 101
GameScreenApolloMachine.SYMBOL_FIX_SYMBOL = 94
GameScreenApolloMachine.SYMBOL_MIDRUN_SYMBOL = 95
GameScreenApolloMachine.SYMBOL_MIDRUN_SYMBOL_REELMULTIPLE = 110--滚轴里的乘倍图标

GameScreenApolloMachine.MAIN_ADD_POSY = 45
GameScreenApolloMachine.BONUS_VIEW_ADD_POSY = -40

-- 构造函数
function GameScreenApolloMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_iBetLevel = 0
    self.m_BetChooseGear = 0

    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_bonusPosition = 0 -- 地图位置
    self.m_bonusMap = {} -- 地图信息

    self.m_isInit = true--是否是初始化轮

    self.m_respinFinalEffect = nil--respin下差最后一个图标时的特效框
    self.m_clipNode = {}--存储提高层级的图标
    self.m_midrunSymbol = {}--respin结算时存储带滚轴的图标对象

    self.m_isShowMapGuochang = false--打开关闭地图时是否在播过场
    self.m_bSlotRunning = false--轮盘是否在滚动中
    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function GameScreenApolloMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ApolloConfig.csv", "LevelApolloConfig.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
end

function GameScreenApolloMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize() --h 120
    local uiBW, uiBH = self.m_bottomUI:getUISize()  --h 180
    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height/display.width == DESIGN_SIZE.height/DESIGN_SIZE.width then
        --设计尺寸屏

    elseif display.height/display.width > DESIGN_SIZE.height/DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end
    else
        --宽屏
        local topAoH = 0--顶部空间尺寸 在宽屏中会被用的尺寸
        local bottomMoveH = 0--底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH )/(mainHeight + topAoH - bottomMoveH)--有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH ) / (DESIGN_SIZE.height - uiH - uiBH + topAoH )--有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height/2 - uiBH) * mainScale--设计离下条距离
        local dis = (display.height/2 - uiBH)--实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

function GameScreenApolloMachine:initUI()
    --添加大角色
    self.m_dajuese = util_spineCreate("Socre_Apollo_Abo",true,true)
    self:findChild("Apollo_darenwu"):addChild(self.m_dajuese)
    util_spinePlay(self.m_dajuese,"idleframe2",true)

    self.m_respinGuochangHuoquo = util_spineCreate("Socre_Apollo_Abo",true,true)
    self:findChild("root"):addChild(self.m_respinGuochangHuoquo,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 11)
    local worldPos = self:findChild("Apollo_darenwu"):getParent():convertToWorldSpace(cc.p(self:findChild("Apollo_darenwu"):getPosition()))
    local pos = self:findChild("root"):convertToNodeSpace(worldPos)
    self.m_respinGuochangHuoquo:setPosition(pos)
    self.m_respinGuochangHuoquo:setVisible(false)
    --添加freespin计数条
    self.m_baseFreeSpinBar = util_createView("CodeApolloSrc.ApolloFreespinBarView")
    self:findChild("free_tishikuang"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
    --添加jackpot
    self.m_JackPotView = util_createView("CodeApolloSrc.ApolloJackPotBarView")
    self:findChild("Jackpot"):addChild(self.m_JackPotView)
    self.m_JackPotView:initMachine(self)
    self.m_JackPotView:runCsbAction("idleframe",true)
    --添加respin结算条
    self.m_respinWinBar = util_createAnimation("Apollo_rs_winner.csb")
    self:findChild("respin_jiesuan"):addChild(self.m_respinWinBar)
    self.m_respinWinBar:setVisible(false)
    --添加收集进度条
    self.m_baseLoadingBar = util_createView("CodeApolloSrc.ApolloBaseLoadingBarView")
    self:findChild("Jindutiao"):addChild(self.m_baseLoadingBar)
    self.m_baseLoadingBar:setMachine(self)
    --添加tips
    self.m_tipsNode = util_createAnimation("Apollo_tip.csb")
    self.m_baseLoadingBar:findChild("tip"):addChild(self.m_tipsNode)
    self.m_tipsNode:setVisible(false)
    self.m_tipsNode.m_isClosing = false
    local node = cc.Node:create()
    self.m_tipsNode:addChild(node)
    self.m_tipsNode.m_delayNode = node
    --添加大地图
    self.m_MapView = util_createView("CodeApolloSrc.Map.ApolloMapMainView",self)
    self:addChild(self.m_MapView,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 2)
    self.m_MapView:setVisible(false)
    self.m_MapView:findChild("root"):setScale(self.m_machineRootScale)
    --收集满到大关的玩法界面
    self.m_BonusClickView = util_createView("CodeApolloSrc.Map.ApolloBonusClickMainView",self)
    self:addChild(self.m_BonusClickView,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 2)
    self.m_BonusClickView:setVisible(false)
    self.m_BonusClickView:findChild("root"):setScale(self.m_machineRootScale)

    --添加free下的倍数
    self.m_freespinMultiple = util_createAnimation("Apollo_chengbei.csb")
    self:findChild("free_multiple"):addChild(self.m_freespinMultiple)
    self.m_freespinMultiple:setVisible(false)

    --添加respin计数条
    self.m_respinBar = util_createAnimation("Apollo_rs_tishikuang.csb")
    self:findChild("respin_tishikuang"):addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)

    --添加freespin过场动画
    self.m_freespinGuochangzhehao = util_createAnimation("Apollo_guochang_zhezhao.csb")
    self:findChild("guochang"):addChild(self.m_freespinGuochangzhehao)
    self.m_freespinGuochangzhehao:setVisible(false)

    self.m_freespinGuochang = util_spineCreate("Socre_Apollo_guochang",true,true)
    self:findChild("guochang"):addChild(self.m_freespinGuochang)
    self.m_freespinGuochang:setVisible(false)
    --添加map过场动画
    self.m_mapGuochang = util_spineCreate("Socre_Apollo_guochang_yan",true,true)
    self:findChild("guochang"):addChild(self.m_mapGuochang)
    self.m_mapGuochang:setVisible(false)
    local touchLayer = util_createAnimation("ApolloTouchLayer.csb")
    touchLayer:findChild("Panel_1"):setContentSize(cc.size(display.width,display.height))
    self.m_mapGuochang:addChild(touchLayer)

    --添加轮盘特效
    self.m_reelEffect = util_createAnimation("Apollo_rs_jiman.csb")
    self:findChild("Node_respin_jiman"):addChild(self.m_reelEffect)
    self.m_reelEffect:setVisible(false)

    self:findChild("Node_respin_jiman"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 9)

    local node1 = self.m_baseLoadingBar:findChild("tip")
    local worldPos1 = node1:getParent():convertToWorldSpace(cc.p(node1:getPosition()))
    local pos1 = self.m_clipParent:convertToNodeSpace(worldPos1)
    util_changeNodeParent(self.m_clipParent, node1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)
    node1:setPosition(pos1)
    
    local node2 = self:findChild("guochang")
    local worldPos2 = node2:getParent():convertToWorldSpace(cc.p(node2:getPosition()))
    local pos2 = self:convertToNodeSpace(worldPos2)
    util_changeNodeParent(self, node2, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    node2:setPosition(pos2)
    node2:setScale(self.m_machineRootScale)

    --添加半透明遮罩
    self.m_mask = cc.LayerColor:create(cc.c4f(0, 0, 0, 255))
    self.m_clipParent:addChild(self.m_mask,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 1)
    self.m_mask:setContentSize(cc.size(3000,3000))
    self.m_mask:setPosition(cc.p(-1500,-1500))
    self.m_mask:setVisible(false)

    self.m_gameBg:runCsbAction("normal",true)
end

-- 断线重连
function GameScreenApolloMachine:MachineRule_initGame()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"fs",true})
        self.m_freespinMultiple:setVisible(true)
        util_spinePlay(self.m_dajuese,"idleframe3",true)
    end
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenApolloMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Apollo"
end

-- 继承底层respinView
function GameScreenApolloMachine:getRespinView()
    return "CodeApolloSrc.ApolloRespinView"
end
-- 继承底层respinNode
function GameScreenApolloMachine:getRespinNode()
    return "CodeApolloSrc.ApolloRespinNode"
end

--小块
function GameScreenApolloMachine:getBaseReelGridNode()
    return "CodeApolloSrc.ApolloSlotNode"
end

-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenApolloMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return "Score_Apollo_Bonus"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return "Score_Apollo_Bonus_Grand"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Score_Apollo_Bonus_Major"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Score_Apollo_Bonus_Minor"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Score_Apollo_Bonus_Mini"
    elseif symbolType == self.SYMBOL_MIDRUN_SYMBOL then
        return "Score_Apollo_Bonus1"
    elseif symbolType == self.SYMBOL_MIDRUN_SYMBOL_REELMULTIPLE then
        return "Score_Apollo_Bonus1_runreel_zi"
    elseif symbolType == self.SYMBOL_FIX_GRAND_XBEI then
        return "Score_Apollo_Bonus_Xbei_Grand"
    elseif symbolType == self.SYMBOL_FIX_MAJOR_XBEI then
        return "Score_Apollo_Bonus_Xbei_Major"
    elseif symbolType == self.SYMBOL_FIX_MINOR_XBEI then
        return "Score_Apollo_Bonus_Xbei_Minor"
    elseif symbolType == GameScreenApolloMachine.SYMBOL_FIX_MINI_XBEI then
        return "Score_Apollo_Bonus_Xbei_Mini"
    elseif symbolType == GameScreenApolloMachine.SYMBOL_FIX_SYMBOL_XBEI then
        return "Score_Apollo_Bonus_Xbei"
    end
    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function GameScreenApolloMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
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

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "Mini"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        score = "Minor"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        score = "Major"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        score = "Grand"
    end
    return score
end

function GameScreenApolloMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end
    return score
end

-- 给respin小块进行赋值
function GameScreenApolloMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL then
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
        local score = tonumber(self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))) --获取分数（网络数据）
        local index = 0
        if score ~= nil then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            symbolNode:getCcbProperty("m_l_coin"):setString(score)
            self:updateLabelSize({label = symbolNode:getCcbProperty("m_l_coin"),sx = 0.95,sy = 0.95},131)
        end
        symbolNode:runAnim("idleframe",true)
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                symbolNode:getCcbProperty("m_l_coin"):setString(score)
                self:updateLabelSize({label = symbolNode:getCcbProperty("m_l_coin"),sx = 0.95,sy = 0.95},131)
                symbolNode:runAnim("idleframe",true)
            end
        end
    end
end

function GameScreenApolloMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        self:setSpecialNodeScore(self,{node})
    elseif symbolType == self.SYMBOL_MIDRUN_SYMBOL then
        if node and node.m_specialRunUI == nil then
            node.m_specialRunUI = util_createView("CodeApolloSrc.MidRun.ApolloMidRunView",self)
            node:getCcbProperty("Node_runReel"):addChild(node.m_specialRunUI)
            if node.m_isLastSymbol or self.m_isInit then
                node.m_specialRunUI:beginMove()
            end
        end
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        node.p_idleIsLoop = true
        node:runIdleAnim()
    end
end


----------------------------- 玩法处理 -----------------------------------
function GameScreenApolloMachine:getRandomFixSymbol(col)
    if col == 3 then
        return self.SYMBOL_MIDRUN_SYMBOL
    end
    local symbolTab = {
        self.SYMBOL_FIX_SYMBOL,
        self.SYMBOL_FIX_MINI,
        self.SYMBOL_FIX_MINOR,
        self.SYMBOL_FIX_MAJOR,
        self.SYMBOL_FIX_GRAND
    }
    return symbolTab[math.random(1,#symbolTab)]
end
-- 是不是 respinBonus小块
function GameScreenApolloMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_GRAND or
        symbolType == self.SYMBOL_MIDRUN_SYMBOL then
        return true
    end
    return false
end
-- 获取乘倍的信号块类型
function GameScreenApolloMachine:getFixSymbolXBeiSymbolType(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return self.SYMBOL_FIX_SYMBOL_XBEI
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return self.SYMBOL_FIX_MINI_XBEI
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return self.SYMBOL_FIX_MINOR_XBEI
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return self.SYMBOL_FIX_MAJOR_XBEI
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return self.SYMBOL_FIX_GRAND_XBEI
    end
    return symbolType
end
--
--单列滚动停止回调
--
function GameScreenApolloMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self,reelCol)
    local sound = {scatter = 0,bonus = 0}
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        for row = 1, self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
            if symbolNode and self:isFixSymbol(symbolNode.p_symbolType) then
                self:setSymbolToClip(symbolNode)
                if symbolNode.m_specialRunUI then
                    symbolNode.m_specialRunUI:beginMove()
                end
                symbolNode:runAnim("buling",false,function ()
                    if symbolNode.p_symbolType ~= nil then
                        symbolNode:runAnim("idleframe",true)
                    end
                end)
                sound.bonus = 1
            elseif symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if self:isPlayTipAnima(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex,symbolNode) == true then
                    self:setSymbolToClip(symbolNode)
                    symbolNode:runAnim("buling",false)
                    self:playScatterBonusSound(symbolNode)
                    sound.scatter = 1
                end
            end
        end
        if sound.scatter == 0 and sound.bonus == 1 then
            
            local soundPath = "ApolloSounds/music_Apollo_bonusfall.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end
            
            
        end
    end
end
--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
]]
function GameScreenApolloMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        if i >= 3 then
            soundPath = "ApolloSounds/music_Apollo_scatterbuling3.mp3"
        else
            soundPath = "ApolloSounds/music_Apollo_scatterbuling" .. i .. ".mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
--将图标提到clipParent层
function GameScreenApolloMachine:setSymbolToClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX, slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10)
    self.m_clipNode[#self.m_clipNode + 1] = slotNode
    
    local linePos = {}
    linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
    slotNode:setLinePos(linePos)
end
--设置bonus scatter 层级
function GameScreenApolloMachine:getBounsScatterDataZorder(symbolType)
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:isFixSymbol(symbolType) then
        
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
--将图标恢复到轮盘层
function GameScreenApolloMachine:setSymbolToReel()
    for i, slotNode in ipairs(self.m_clipNode) do
        local preParent = slotNode.m_preParent
        if preParent ~= nil then
            slotNode.p_layerTag = slotNode.m_preLayerTag

            local nZOrder = slotNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder

            util_changeNodeParent(preParent, slotNode, nZOrder)
            slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
            slotNode:runIdleAnim()
        end
    end
    self.m_clipNode = {}
end
---
-- 播放freespin动画触发
-- 改变背景动画等
function GameScreenApolloMachine:levelFreeSpinEffectChange()
    self:runCsbAction("fs")
    self.m_baseLoadingBar:setVisible(false)
    -- self.m_freespinMultiple:setVisible(true)
    -- util_spinePlay(self.m_dajuese,"idleframe3",true)
    self:setFreespinMultiple()
    self.m_freespinMultiple:playAction("start")
end

---
--播放freespinover 动画触发
--改变背景动画等
function GameScreenApolloMachine:levelFreeSpinOverChangeEffect()

end
--freespin结束  改变界面动画
function GameScreenApolloMachine:freeSpinOverChangeView()
    self:runCsbAction("normal")
    self.m_baseLoadingBar:setVisible(true)
    self.m_freespinMultiple:setVisible(false)
    self.m_baseFreeSpinBar:setVisible(false)
end

--设置freespin下的倍数
function GameScreenApolloMachine:setFreespinMultiple(isPlayAni)
    if isPlayAni == nil then
        isPlayAni = false
    end
    local multiple = 1
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.freeMultiple then
        multiple = self.m_runSpinResultData.p_selfMakeData.freeMultiple
    else
        multiple = self.m_configData:getFreespinMultiple()
    end
    if isPlayAni then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_freeMultipleChange.mp3")
        self.m_freespinMultiple:playAction("change",false)
        local node = cc.Node:create()
        self:addChild(node)
        performWithDelay(node,function ()
            self.m_freespinMultiple:findChild("BitmapFontLabel_1"):setString(multiple.."X")
            node:removeFromParent()
        end,6/60)
    else
        self.m_freespinMultiple:findChild("BitmapFontLabel_1"):setString(multiple.."X")
    end
end
---
-- 显示bonus freespin 触发小格子连线提示处理
--
function GameScreenApolloMachine:showBonusAndScatterLineTip(lineValue,callFun)
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
            slotNode = self:getFixSymbol(symPosData.iY , symPosData.iX, SYMBOL_NODE_TAG)
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
            animTime = util_max(animTime, 70/30)
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function GameScreenApolloMachine:setSlotNodeEffectParent(slotNode)
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

    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            slotNode:runAnim("actionframe",false)
        else
            slotNode:runLineAnim()
        end
    end
    return slotNode
end

-- 显示free spin
function GameScreenApolloMachine:showEffect_FreeSpin(effectData)

    self.m_beInSpecialGameTrigger = true
    
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
    if scatterLineValue ~= nil and  scatterLineValue.iLineSymbolNum > 0 then
        --
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            performWithDelay(self,function ()
                self.m_mask:setVisible(true)
                util_nodeFadeIn(self.m_mask,5/30,0,180,nil,nil)
            end,5/30)
        end
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
    return true
end
-- 触发freespin时调用
function GameScreenApolloMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("ApolloSounds/music_Apollo_showfreespinview.mp3",false)
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            --scatter飞
            local flyScatterTab = {}
            for row = 1, self.m_iReelRowNum do
                for col = 1, self.m_iReelColumnNum do
                    local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                    if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        slotNode:setVisible(false)
                        local fileName = self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                        local scatter = util_spineCreate(fileName,true,true)
                        self.m_clipParent:addChild(scatter,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 11)
                        table.insert(flyScatterTab,scatter)
                        scatter.m_row = row
                        scatter.m_col = col

                        local worldPos = slotNode:getParent():convertToWorldSpace(cc.p(slotNode:getPosition()))
                        local pos = self.m_clipParent:convertToNodeSpace(worldPos)
                        scatter:setPosition(pos)
                    end
                end
            end
            gLobalSoundManager:playSound("ApolloSounds/music_Apollo_scatterFlyGuochang.mp3",false)
            if self.m_mask:isVisible() == false then
                performWithDelay(self,function ()
                    self.m_mask:setVisible(true)
                    util_nodeFadeIn(self.m_mask,5/30,0,180,nil,nil)
                end,5/30)
            end
            for i,scatter in ipairs(flyScatterTab) do
                util_spinePlay(scatter,"actionframe_feixing",false)
                util_spineFrameEvent(scatter,"actionframe_feixing","feixing",function ()
                    local moveto = cc.MoveTo:create(15/30,cc.p(self:findChild("scatterflyNode"):getPosition()))
                    scatter:runAction(moveto)
      
                end)
                util_spineEndCallFunc(scatter,"actionframe_feixing",function ()
                    scatter:setVisible(false)
                end)
            end


            -- util_spineFrameEvent(flyScatterTab[1],"actionframe_feixing","guochang",function ()
            performWithDelay(self,function ()
                self:showFreespinGuochang(function ()
                    
                    self:clearCurMusicBg()

                    for j,scatterNode in ipairs(flyScatterTab) do
                        local slotNode = self:getFixSymbol(scatterNode.m_col,scatterNode.m_row,SYMBOL_NODE_TAG)
                        if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            slotNode:setVisible(true)
                        end
                        scatterNode:setVisible(false)
                    end
                    
                    self:runCsbAction("fs")
                    self.m_baseLoadingBar:setVisible(false)
                    self.m_baseFreeSpinBar:setVisible(true)
                    self.m_baseFreeSpinBar:changeFreeSpinByCount()
                    self:setFreespinMultiple()
                    self.m_freespinMultiple:playAction("start")

                    self.m_mask:setVisible(false)
                end,function ()
                    self.m_gameBg:runCsbAction("normal_fs",false,function ()
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"fs",true})
                    end)
                    
                end,function ()

                    for j,scatterNode in ipairs(flyScatterTab) do
                        scatterNode:removeFromParent()
                    end

                    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_showfreespinview.mp3",false)
                    local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                    view.m_allowClick = false
                    performWithDelay(view,function ()
                        view.m_allowClick = true
                        self.m_freespinMultiple:setVisible(true)
                    end,45/60)
                end,"idleframe3")
            end,15/30)
            -- end)
        end
    end

    performWithDelay(self,function()
        showFSView()
    end,0.5)
end
--播放 freespin过场   idleActName 大角色接的idle动画
function GameScreenApolloMachine:showFreespinGuochang(func1,func2,func3,idleActName)
    self.m_freespinGuochangzhehao:setVisible(true)
    self.m_freespinGuochang:setVisible(true)
    self.m_freespinGuochangzhehao:playAction("actionframe",false)
    util_spinePlay(self.m_freespinGuochang,"actionframe",false)
    util_spineEndCallFunc(self.m_freespinGuochang,"actionframe",function ()
        self.m_freespinGuochangzhehao:setVisible(false)
        self.m_freespinGuochang:setVisible(false)
    end)

    performWithDelay(self,function ()
        self.m_dajuese:setVisible(false)
        if func1 then
            func1()
        end
    end,10/30)

    -- performWithDelay(self,function ()
        util_spineFrameEvent(self.m_freespinGuochang,"actionframe","guochang",function ()
            self.m_dajuese:setAnimation(0, "actionframe_shang", false)
            self.m_dajuese:addAnimation(0, idleActName, true)
            performWithDelay(self.m_dajuese,function ()--这里做延迟是因为直接显示有问题
                gLobalSoundManager:playSound("ApolloSounds/music_Apollo_dajueseChuxian.mp3")
                self.m_dajuese:setVisible(true)
            end,0.05)

            if func2 then
                func2()
            end

            util_spineEndCallFunc(self.m_dajuese,"actionframe_shang",function ()
                if func3 then
                    func3()
                end
            end)
        end)
    -- end,57/30)
end
-- 触发freespin结束时调用
function GameScreenApolloMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_showfreespinoverview.mp3",false)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            -- gLobalSoundManager:playSound("ApolloSounds/music_Apollo_freespinGuochang.mp3")
            -- self:showFreespinGuochang(function ()
            --     self:freeSpinOverChangeView()
            -- end,function ()
            --     self.m_gameBg:runCsbAction("fs_normal",false,function ()
            --         gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"normal",true})
            --     end)
            -- end,function ()
            --     self:triggerFreeSpinOverCallFun()
            -- end,"idleframe")
            self.m_gameBg:runCsbAction("fs_normal",false,function ()
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"normal",true})
            end)
            self:freeSpinOverChangeView()
            util_spinePlay(self.m_dajuese ,"idleframe2",true)
            self:triggerFreeSpinOverCallFun()
    end)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node,sx = 0.5,sy = 0.5},1252)
end

-- 结束respin收集
function GameScreenApolloMachine:playLightEffectEnd()
    -- 通知respin结束
    self:respinOver()
end

function GameScreenApolloMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        performWithDelay(self,function ()
            -- 此处跳出递归
            self:playLightEffectEnd()
        end,1)
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local startWorldPos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPosition()))
    local startPos = self.m_clipParent:convertToNodeSpace(startWorldPos)
    local endWorldPos = self.m_respinWinBar:findChild("Apollo_rs_total"):getParent():convertToWorldSpace(cc.p(self.m_respinWinBar:findChild("Apollo_rs_total"):getPosition()))
    local endPos = self.m_clipParent:convertToNodeSpace(endWorldPos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local multiple = chipNode.m_multiple

    local nJackpotType = 0
    local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
    if symbolType == self.SYMBOL_FIX_MINI then
        nJackpotType = 4
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        nJackpotType = 3
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        nJackpotType = 2
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        nJackpotType = 1
    end
    -- 根据网络数据获得当前固定小块的分数
    local score = self:getLightingCoins(iCol,iRow)
    self.m_lightScore = self.m_lightScore + score
    
    if nJackpotType == 0 then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinEndcollect.mp3",false)
        chipNode:runAnim("jiesuan",false,function ()
            chipNode:runAnim("idleframe",true)
        end)
        self:runJieSuanTuoWeiAct(startPos,endPos,function ()
            self:setRespinWinBarCoinNum(self.m_lightScore,true)
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            performWithDelay(self,function ()
                self:playChipCollectAnim()
            end,0.2)
        end)
    else
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinEndJackpot.mp3",false)
        self.m_JackPotView:runCsbAction("jackpot"..nJackpotType,true)
        chipNode:runAnim("actionframe",false,function ()
            chipNode:runAnim("idleframe",true)
            self.m_JackPotView:runCsbAction("idleframe",true)
            self:showRespinJackpot(nJackpotType, score, multiple, function()
                gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinEndcollect.mp3",false)
                chipNode:runAnim("jiesuan",false,function ()
                    chipNode:runAnim("idleframe",true)
                end)
                self:runJieSuanTuoWeiAct(startPos,endPos,function ()
                    self:setRespinWinBarCoinNum(self.m_lightScore,true)
                    self.m_playAnimIndex = self.m_playAnimIndex + 1
                    performWithDelay(self,function ()
                        self:playChipCollectAnim()
                    end,0.2)
                end)
            end)
        end)
    end
end
--根据行，列获取lighting图标获得钱数
function GameScreenApolloMachine:getLightingCoins(col,row)
    if col == nil or row == nil then
        for i,v in ipairs(self.m_runSpinResultData.p_winLines) do
            if self.m_runSpinResultData.p_winLines[i].p_iconPos[1] == -1 then
                return self.m_runSpinResultData.p_winLines[i].p_amount
            end
        end
        return 0
    end
    local pos = self:getPosReelIdx(row ,col)
    for i,v in ipairs(self.m_runSpinResultData.p_winLines) do
        if self.m_runSpinResultData.p_winLines[i].p_iconPos[1] == pos then
            return self.m_runSpinResultData.p_winLines[i].p_amount
        end
    end
    return 0
end
--结束移除小块调用结算特效
function GameScreenApolloMachine:reSpinEndAction()
    self.m_respinBar:playAction("over",false)
    if self.m_bProduceSlots_InFreeSpin then
        self.m_baseFreeSpinBar:setVisible(false)
    end
    local allLightingSymbol = self.m_respinView:getAllCleaningNodeNoSort()
    if #allLightingSymbol >= (self.m_iReelRowNum * self.m_iReelColumnNum) then
        -- 如果全部都固定了，会中JackPot档位中的Grand
        self.m_reelEffect:setVisible(true)
        self.m_JackPotView:runCsbAction("jackpot1",true)
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinEndGrand.mp3",false)
        self.m_reelEffect:playAction("actionframe",false,function ()
            self.m_JackPotView:runCsbAction("idleframe",true)
            self.m_reelEffect:setVisible(false)
            local jackpotScore = self:getLightingCoins(-1)
            -- local lastwinCoins = globalData.slotRunData.lastWinCoin
            -- globalData.slotRunData.lastWinCoin = 0
            -- local lastWin = jackpotScore
            -- if self.m_bProduceSlots_InFreeSpin == true then
            --     lastWin = self.m_runSpinResultData.p_fsWinCoins - self.m_runSpinResultData.p_winAmount + jackpotScore
            -- end
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lastWin, false, true})
            -- globalData.slotRunData.lastWinCoin = lastwinCoins
            self:showRespinJackpot(1,jackpotScore,1,function()
                    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonus2Pos then
                        self:respinEndStartPlayMidRunNode()
                    else
                        self:respinEndStartCollect()
                    end
                end)
        end)
    else
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonus2Pos then
            self:respinEndStartPlayMidRunNode()
        else
            self:respinEndStartCollect()
        end
    end
end
--respin结束后带滚轴的lighting图标开始播动画
function GameScreenApolloMachine:respinEndStartPlayMidRunNode()
    --取出所有的lighting图标
    local allLightingSymbol = self.m_respinView:getAllCleaningNodeNoSort()
    --筛选出带滚轴的图标
    self.m_midrunSymbol = {}
    self.m_playMidrunIdx = 1
    for i,symbolNode in ipairs(allLightingSymbol) do
        if symbolNode.p_symbolType == self.SYMBOL_MIDRUN_SYMBOL then
            table.insert(self.m_midrunSymbol,symbolNode)
        else
            symbolNode.m_stage = 0--记录这个图标被翻倍的次数
            symbolNode.m_multiple = 1--记录这个图标已经翻的倍数
        end
    end
    table.sort( self.m_midrunSymbol, function(a, b)
        return b.p_rowIndex < a.p_rowIndex
    end)
    self:playMidRunNode()
end
function GameScreenApolloMachine:playMidRunNode()
    if self.m_playMidrunIdx > #self.m_midrunSymbol then
        self:respinEndStartCollect()
        return
    end

    --添加半透明遮罩
    local reelWorldPos = self:findChild("Apollo_reel_kuang"):getParent():convertToWorldSpace(cc.p(self:findChild("Apollo_reel_kuang"):getPosition()))
    local colorPos = self.m_respinView:convertToNodeSpace(reelWorldPos)
    local colorNode = cc.LayerColor:create(cc.c4f(0, 0, 0, 255))
    colorNode:setContentSize(cc.size(662,400))
    self.m_respinView:addChild(colorNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - 1)
    colorNode:setPosition(cc.p(colorPos.x - 331,colorPos.y - 200))
    util_nodeFadeIn(colorNode,30/60,0,180,nil,nil)

    local zorder = self.m_midrunSymbol[self.m_playMidrunIdx]:getLocalZOrder()
    self.m_midrunSymbol[self.m_playMidrunIdx]:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_bonus1Fangda.mp3",false)
    self.m_midrunSymbol[self.m_playMidrunIdx]:runAnim("actionframe1",false,function ()
        self.m_midrunSymbol[self.m_playMidrunIdx]:runAnim("idleframe1",true)
    end)
    local score = 2--扫光图标的倍数
    local bonusPos = 0--扫光图标的位置
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreDataTab = selfData.bonus2Pos or {}
    for i,data in ipairs(scoreDataTab) do
        local rowColData = self:getRowAndColByPos(data[1])
        if rowColData.iX == self.m_midrunSymbol[self.m_playMidrunIdx].p_rowIndex and rowColData.iY == self.m_midrunSymbol[self.m_playMidrunIdx].p_cloumnIndex then
            score = data[2]
            bonusPos = data[1]
            break
        end
    end
    local endData = {}
    endData.type = self.SYMBOL_MIDRUN_SYMBOL_REELMULTIPLE
    endData.score = score
    self.m_midrunSymbol[self.m_playMidrunIdx].m_specialRunUI:setEndValue(endData)

    self.m_midrunSymbol[self.m_playMidrunIdx].m_specialRunUI:setOverCallBackFun(function ()
        --添加箭头
        local jiantou = util_createAnimation("Score_Apollo_Bonus1_jiantou.csb")
        self.m_midrunSymbol[self.m_playMidrunIdx]:getCcbProperty("Node_jiantou"):addChild(jiantou)
        --添加裁切轮盘
            --创建切割区域
        local respinClipView = util_createView("CodeApolloSrc.ClipView.StencilClipView")
        self.m_midrunSymbol[self.m_playMidrunIdx]:getCcbProperty("Node_shexian"):addChild(respinClipView)
        --创建要放进切割区域的对象
        local symbolNodeTab = {}--存储放进裁切区域的信号块对象
        local allLightingSymbol = self.m_respinView:getAllCleaningNodeNoSort()
        for i,lightingNode in ipairs(allLightingSymbol) do
            if lightingNode.p_symbolType ~= self.SYMBOL_MIDRUN_SYMBOL then
                if self:testPosIsInLine(self.m_midrunSymbol[self.m_playMidrunIdx].p_rowIndex,self.m_midrunSymbol[self.m_playMidrunIdx].p_cloumnIndex,lightingNode.p_rowIndex,lightingNode.p_cloumnIndex) then
                    local symbolType = self:getFixSymbolXBeiSymbolType(lightingNode.p_symbolType)
                    local fileName = self:MachineRule_GetSelfCCBName(symbolType)
                    local symbolNode = util_createAnimation(fileName..".csb")
                    symbolNode.m_worldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(lightingNode.p_rowIndex,lightingNode.p_cloumnIndex))
                    symbolNode:setScale(1.1)
                    table.insert(symbolNodeTab,symbolNode)
                    if symbolType == self.SYMBOL_FIX_SYMBOL_XBEI then
                        local lineBet = globalData.slotRunData:getCurTotalBet()
                        local repsinCoinNum = tonumber(self:getReSpinSymbolScore(self:getPosReelIdx(lightingNode.p_rowIndex, lightingNode.p_cloumnIndex))) * lineBet
                        symbolNode:findChild("m_l_coin"):setString(util_formatCoins(lightingNode.m_multiple * score * repsinCoinNum,3))
                        self:updateLabelSize({label = symbolNode:findChild("m_l_coin"),sx = 0.95,sy = 0.95},131)
                        symbolNode:findChild("Apollo_di_"..(lightingNode.m_stage + 1)):setVisible(true)
                    else
                        symbolNode:findChild("m_l_coin_Xbei"):setString(""..lightingNode.m_multiple * score.."X")
                        symbolNode:findChild("Apollo_di_"..(lightingNode.m_stage + 1)):setVisible(true)
                    end
                    local shine = util_createAnimation("Score_Apollo_Bonus_Xbei_shine"..(lightingNode.m_stage + 1)..".csb")
                    symbolNode:findChild("Node_shine"):addChild(shine)
                    shine:playAction("actionframe",true)
                end
            end
        end
        --设置切割区域形状
        respinClipView:stencilDrawPolygon({cc.p(48.2,47),cc.p(-46,47),cc.p(-128.6,488.5),cc.p(113,488.5)})
        respinClipView:addContentTabToClip(symbolNodeTab)
        util_nodeFadeIn(respinClipView,0.5,0,255)
        --添加射线
        --创建切割区域
        local shexianClipView = util_createView("CodeApolloSrc.ClipView.StencilClipView")
        self.m_midrunSymbol[self.m_playMidrunIdx]:getCcbProperty("Node_shexian"):addChild(shexianClipView)
        --设置切割区域形状
        local leftX = -330
        local rightX = 330
        local topY = (self.m_iReelRowNum - self.m_midrunSymbol[self.m_playMidrunIdx].p_rowIndex) * self.m_SlotNodeH + self.m_SlotNodeH/2
        local bottomY = -(self.m_midrunSymbol[self.m_playMidrunIdx].p_rowIndex - 1) * self.m_SlotNodeH - self.m_SlotNodeH/2
        shexianClipView:stencilDrawPolygon({cc.p(leftX,bottomY),cc.p(leftX,topY),cc.p(rightX,topY),cc.p(rightX,bottomY)})
        local shexian = util_createAnimation("Score_Apollo_Bonus1_shexian.csb")
        shexianClipView:addContentToClip(shexian)
        shexian:playAction("actionframe2",false,function ()
            shexian:playAction("idleframe",true)
        end)

        local mulNode = util_createAnimation("Score_Apollo_Bonus1_runreel_zi.csb")
        mulNode:findChild("Apollo_Bonus1_"..score.."X"):setVisible(true)
        self.m_midrunSymbol[self.m_playMidrunIdx]:getCcbProperty("Node_Xbei_0"):addChild(mulNode)
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_bonus1gunwan.mp3",false)
        self.m_midrunSymbol[self.m_playMidrunIdx]:runAnim("actionframe2",false,function ()
            -- performWithDelay(self,function ()
                --箭头、射线、切割区域开始转动
                local startPos = cc.p(self.m_midrunSymbol[self.m_playMidrunIdx].p_rowIndex, self.m_midrunSymbol[self.m_playMidrunIdx].p_cloumnIndex)
                local resultDataTab = self.m_runSpinResultData.p_selfMakeData.scanResult
                local rowcol = self:getRowAndColByPos(resultDataTab[""..bonusPos][1])
                local endPos = cc.p(rowcol.iX,rowcol.iY)
                local rotate = self:calculationAngle(startPos,endPos)
                local action1 = cc.EaseSineOut:create(cc.RotateBy:create(5,360 + rotate))
                local action2 = cc.EaseSineOut:create(cc.RotateBy:create(5,360 + rotate))
                local action3 = cc.EaseSineOut:create(cc.RotateBy:create(5,360 + rotate))
                local func = cc.CallFunc:create(function ()
                    local soundFileName = "ApolloSounds/music_Apollo_respinEndshexianPenhuo.mp3"
                    for i,posIdx in ipairs(resultDataTab[""..bonusPos]) do
                        local respinMulSymboRowColData = self:getRowAndColByPos(posIdx)
                        local respinSymbolNode = self.m_respinView:getRespinEndNode(respinMulSymboRowColData.iX,respinMulSymboRowColData.iY)
                        if respinSymbolNode and respinSymbolNode.m_stage then
                            if respinSymbolNode.m_stage > 0 then
                                soundFileName = "ApolloSounds/music_Apollo_respinEndshexianPenhuoPlus.mp3"
                                break
                            end
                        end
                    end
                    gLobalSoundManager:playSound(soundFileName,false)
                    shexian:playAction("over",false,function ()
                        respinClipView:setVisible(false)
                        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinEndbonusFanbei.mp3",false)
                        for i,posIdx in ipairs(resultDataTab[""..bonusPos]) do
                            local respinMulSymboRowColData = self:getRowAndColByPos(posIdx)
                            local respinSymbolNode = self.m_respinView:getRespinEndNode(respinMulSymboRowColData.iX,respinMulSymboRowColData.iY)
                            if respinSymbolNode and respinSymbolNode.m_stage then
                                local symbolType = self:getFixSymbolXBeiSymbolType(respinSymbolNode.p_symbolType)
                                local fileName = self:MachineRule_GetSelfCCBName(symbolType)
                                respinSymbolNode:changeCCBByName(fileName,symbolType)
                                for i = 1,3 do
                                    respinSymbolNode:getCcbProperty("Apollo_di_"..i):setVisible(false)
                                end
                                respinSymbolNode.m_stage = respinSymbolNode.m_stage + 1--记录这个图标被翻倍的次数
                                respinSymbolNode.m_multiple = respinSymbolNode.m_multiple * score--记录这个图标已经翻的倍数

                                if symbolType == self.SYMBOL_FIX_SYMBOL_XBEI then
                                    local lineBet = globalData.slotRunData:getCurTotalBet()
                                    local repsinCoinNum = tonumber(self:getReSpinSymbolScore(self:getPosReelIdx(respinMulSymboRowColData.iX, respinMulSymboRowColData.iY))) * lineBet
                                    respinSymbolNode:getCcbProperty("m_l_coin"):setString(util_formatCoins(respinSymbolNode.m_multiple * repsinCoinNum,3))
                                    self:updateLabelSize({label = respinSymbolNode:getCcbProperty("m_l_coin"),sx = 0.95,sy = 0.95},131)
                                    respinSymbolNode:getCcbProperty("Apollo_di_"..respinSymbolNode.m_stage):setVisible(true)
                                else
                                    respinSymbolNode:getCcbProperty("m_l_coin_Xbei"):setString(""..respinSymbolNode.m_multiple.."X")
                                    respinSymbolNode:getCcbProperty("Apollo_di_"..respinSymbolNode.m_stage):setVisible(true)
                                end
                                local oldZOrder = respinSymbolNode:getLocalZOrder()
                                respinSymbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + respinMulSymboRowColData.iY * 10 - respinMulSymboRowColData.iX)
                                respinSymbolNode:runAnim("actionframe1",false,function ()
                                    respinSymbolNode:setLocalZOrder(oldZOrder)
                                end)

                                local shine = util_createAnimation("Score_Apollo_Bonus_Xbei_shine"..respinSymbolNode.m_stage..".csb")
                                respinSymbolNode:getCcbProperty("Node_shine"):addChild(shine)
                                shine:playAction("actionframe",true)
                            end
                        end
                        self.m_midrunSymbol[self.m_playMidrunIdx]:runAnim("over",false)
                        util_nodeFadeIn(colorNode,30/60,180,0,nil,nil)
                        util_nodeFadeIn(shexian,60/60,255,0,nil,function ()
                        -- shexian:playAction("over",false,function ()
                        -- performWithDelay(self,function ()
                            --转完之后删除箭头、射线、裁切区域、放大倍数
                            jiantou:removeFromParent()
                            self.m_midrunSymbol[self.m_playMidrunIdx]:getCcbProperty("Node_shexian"):removeAllChildren()
                            self.m_midrunSymbol[self.m_playMidrunIdx]:getCcbProperty("Node_Xbei_0"):removeAllChildren()
                            -- 恢复层级
                            self.m_midrunSymbol[self.m_playMidrunIdx]:setLocalZOrder(zorder)
                            colorNode:removeFromParent()
                            --去转下一个
                            performWithDelay(self,function ()
                                self.m_playMidrunIdx = self.m_playMidrunIdx + 1
                                self:playMidRunNode()
                            end,0.5)
                        -- end,2.0)
                        end)
                    end)
                end)
                gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinEndshexianrotate.mp3",false)
                jiantou:runAction(action1)
                shexian:runAction(action2)
                respinClipView:getStencil():runAction(cc.Sequence:create(action3,func))
            -- end,1)
        end)
    end)
end
--检测目标点是否与参考点在一条线上
function GameScreenApolloMachine:testPosIsInLine(referenceRow,referenceCol,targetRow,targetCol)
    if referenceRow == targetRow then
        return true
    end
    if math.abs(referenceRow - targetRow) == math.abs(referenceCol - targetCol) then
        return true
    end
end
--根据两个位置计算角度
function GameScreenApolloMachine:calculationAngle(startPos,endPos)
    local angle = util_getAngleByPos(startPos,endPos)
    if angle < 0 then
        angle = 360 + angle
    end
    return angle
end
--respin结束后开始收集
function GameScreenApolloMachine:respinEndStartCollect()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    local idx = 1
    while true do
        if idx > #self.m_chipList then
            break
        end
        if self.m_chipList[idx].p_symbolType == self.SYMBOL_MIDRUN_SYMBOL then
            table.remove(self.m_chipList,idx)
        else
            idx = idx + 1
        end
    end

    self.m_respinWinBar:setVisible(true)
    self:setRespinWinBarCoinNum(0)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinEndwinbarshow.mp3",false)
    self.m_respinWinBar:playAction("show",false,function ()
        self:playChipCollectAnim()
    end)
    util_nodeFadeIn(self.m_dajuese,30/60,255,0,nil,nil)
end
--设置respin赢钱框上的赢钱数
function GameScreenApolloMachine:setRespinWinBarCoinNum(coinNum,isPlayAction)
    if isPlayAction then
        self.m_respinWinBar:playAction("actionframe",false)
    end
    self.m_respinWinBar:findChild("Apollo_rs_total"):setString(util_formatCoins(coinNum,30))
    if coinNum == 0 then
        self.m_respinWinBar:findChild("Apollo_rs_total"):setVisible(false)
    else
        self.m_respinWinBar:findChild("Apollo_rs_total"):setVisible(true)
    end
    self.m_respinWinBar:updateLabelSize({label = self.m_respinWinBar:findChild("Apollo_rs_total"),sx = 0.5,sy = 0.5},1252)
end
-- 根据本关卡实际小块数量填写
function GameScreenApolloMachine:getRespinRandomTypes()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2
    }
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function GameScreenApolloMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_MIDRUN_SYMBOL, runEndAnimaName = "buling", bRandom = true},
    }

    return symbolList
end
--检测是不是respin的触发轮
function GameScreenApolloMachine:isRespinInit()
    -- return self.m_runSpinResultData.p_features[2] == SLOTO_FEATURE.FEATURE_RESPIN
    return self.m_runSpinResultData.p_reSpinsTotalCount > 0
end
function GameScreenApolloMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    local waitTime = 0
    --如果是触发轮播放触发动画
    if self:isRespinInit() then
        for row = 1, self.m_iReelRowNum do
            for col = 1, self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and self:isFixSymbol(slotNode.p_symbolType) then
                    slotNode:runAnim("actionframe",false,function ()
                        slotNode:runAnim("idleframe",true)
                    end)
                end
            end
        end
        waitTime = 2.5
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinChufa.mp3")
    end

    performWithDelay(self,function()
        if self:isRespinInit() then
            if self.m_bProduceSlots_InFreeSpin then
                self.m_freespinMultiple:setVisible(false)
            end
            self:showRespinGuochang(function ()
                if self.m_bProduceSlots_InFreeSpin == false then
                    self.m_bottomUI:checkClearWinLabel()
                end
                self:setSymbolToReel()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes()
                --可随机的特殊信号
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)

                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                -- 更改respin 状态下的背景音乐
                self:changeReSpinBgMusic()
            end,function ()
                self:runNextReSpinReel()
            end)
        else
            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes()
            --可随机的特殊信号
            local endTypes = self:getRespinLockTypes()
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)

            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()

            self:runNextReSpinReel()
        end

    end,waitTime)
end
--播进入respin过场
function GameScreenApolloMachine:showRespinGuochang(func1,func2)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinguochang.mp3",false)
    util_spinePlay(self.m_dajuese,"guochang",false)
    self.m_respinGuochangHuoquo:setVisible(true)
    util_spinePlay(self.m_respinGuochangHuoquo,"guochang_qiu",false)
    util_spineEndCallFunc(self.m_respinGuochangHuoquo,"guochang_qiu",function ()
        self.m_respinGuochangHuoquo:setVisible(false)
        if func2 then
            func2()
        end
    end)
    util_spineFrameEvent(self.m_respinGuochangHuoquo,"guochang_qiu","guochang",function ()
        util_spinePlay(self.m_dajuese,"idleframe2",true)
        if func1 then
            func1()
        end
    end)
end
function GameScreenApolloMachine:initRespinView(endTypes, randomTypes)
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
        end
    )
    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

---判断结算
function GameScreenApolloMachine:reSpinReelDown(addNode)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        if self.m_respinFinalEffect ~= nil then
            self.m_respinFinalEffect:removeFromParent()
            self.m_respinFinalEffect = nil
        end
        -- self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end

    if self.m_runSpinResultData.p_reSpinCurCount == 1 then
        self.m_respinView:setIsBigres(true)
    else
        self.m_respinView:setIsBigres(false)
    end

    if #self.m_respinView:getAllCleaningNodeNoSort() == 14 then
        if self.m_respinFinalEffect == nil then
            self.m_respinFinalEffect = util_createAnimation("Apollo_respin_tishi.csb")
            self.m_respinView:addChild(self.m_respinFinalEffect,2)
            self.m_respinFinalEffect:playAction("actionframe",true)
            self.m_respinView:setIsQuickRun(true)

            for row = 1, self.m_iReelRowNum do
                for col = 1, self.m_iReelColumnNum do
                    local respinSymbolNode = self.m_respinView:getRespinEndNode(row,col)
                    if respinSymbolNode == nil then
                        local worldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(row,col))
                        local pos = self.m_respinFinalEffect:getParent():convertToNodeSpace(worldPos)
                        self.m_respinFinalEffect:setPosition(pos)
                        break
                    end
                end
            end
        end
    end

    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续
    self:runNextReSpinReel()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

--开始下次ReSpin
function GameScreenApolloMachine:runNextReSpinReel()
    GameScreenApolloMachine.super.runNextReSpinReel(self)
    self.m_isInit = false
end

--respin开始滚动
function GameScreenApolloMachine:startReSpinRun()
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
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinView:startMove()
    if self.m_respinView.m_isQuickRun == true then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respinquickrun.mp3")
    end
end

--ReSpin开始改变UI状态
function GameScreenApolloMachine:changeReSpinStartUI(respinCount)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"rs",true})
    self.m_respinBar:setVisible(true)
    self.m_respinBar:playAction("idleframe")
    self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,false)
    self.m_baseLoadingBar:setVisible(false)
end

--ReSpin刷新数量
function GameScreenApolloMachine:changeReSpinUpdateUI(curCount,isPlayAni)
    print("当前展示位置信息  %d ", curCount)
    for i = 1,3 do
        if i == curCount then
            self.m_respinBar:findChild("Apollo_respin_dian"..i.."_liang"):setVisible(true)
        else
            self.m_respinBar:findChild("Apollo_respin_dian"..i.."_liang"):setVisible(false)
        end
    end
    if curCount == 3 then
        if isPlayAni ~= false then
            self.m_respinBar:playAction("actionframe")
            gLobalSoundManager:playSound("ApolloSounds/music_Apollo_respin3.mp3")
        end
    end
end

--ReSpin结算改变UI状态
function GameScreenApolloMachine:reSpinOverchangeUI()
    self.m_respinBar:setVisible(false)
    if self.m_bProduceSlots_InFreeSpin then
        self.m_gameBg:runCsbAction("rs_fs",false,function ()
            self.m_gameBg:runCsbAction("fs",true)
        end)

        self.m_baseFreeSpinBar:setVisible(true)
        self.m_freespinMultiple:setVisible(true)
        util_spinePlay(self.m_dajuese,"idleframe3",true)
    else
        self.m_gameBg:runCsbAction("rs_normal",false,function ()
            self.m_gameBg:runCsbAction("normal",true)
        end)
        self.m_baseLoadingBar:setVisible(true)
        util_spinePlay(self.m_dajuese,"idleframe2",true)
    end
end

function GameScreenApolloMachine:showRespinOverView(effectData)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_showrespinoverview.mp3",false)
    local strCoins = util_formatCoins(self.m_serverWinCoins,30)
    local view = self:showReSpinOver(strCoins,function()
        self:reSpinOverchangeUI()
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
    end)
    self.m_respinWinBar:playAction("over",false,function ()
        self.m_respinWinBar:setVisible(false)
    end)
    util_nodeFadeIn(self.m_dajuese,30/60,0,255,nil,nil)
    performWithDelay(self,function ()
        -- self:reSpinOverchangeUI()
        for i,v in ipairs(self.m_midrunSymbol) do
            v.m_specialRunUI:restartMove()
        end
        self.m_midrunSymbol = {}
    end,45/60)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node,sx = 0.5,sy = 0.5},1252)
end

--重写组织respinData信息
function GameScreenApolloMachine:getRespinSpinData()
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
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function GameScreenApolloMachine:MachineRule_SpinBtnCall()
    if self.m_MapView:isVisible() then
        self:showMapGuoChang(function ()
            self:clearCurMusicBg()
            self:resetMusicBg(true)
            self.m_MapView:closeUi()
        end,function ()
            self.m_bSlotRunning = true
            self:MachineRule_SpinBtnCall_call()
            self:setGameSpinStage( IDLE )
            self:callSpinBtn()
        end)
        return true
    else
        self.m_bSlotRunning = true
        self:MachineRule_SpinBtnCall_call()
        return false -- 用作延时点击spin调用
    end
end

function GameScreenApolloMachine:MachineRule_SpinBtnCall_call()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio( self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_isInit = false
    self:removeSoundHandler() -- 移除监听
    self:setMaxMusicBGVolume()

    self:setSymbolToReel()

    self:hideTip()
end

function GameScreenApolloMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        self:playEnterGameSound("ApolloSounds/music_Apollo_enter.mp3")
        scheduler.performWithDelayGlobal(function ()
            self.m_enterGameMusicIsComplete = true
            self:resetMusicBg()
            if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
                self:setMinMusicBGVolume()
            end
        end,2.5,self:getModuleName())
    end,0.4,self:getModuleName())
end

function GameScreenApolloMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    local percent = self:getBaseBarPercent()
    self.m_baseLoadingBar:setBarPercent(percent)

    local perBetLevel = self.m_iBetLevel
    self:updateBetLevel()
    self:updateLockUi(perBetLevel,false)

    if self:checkShopShouldClick() == false then
        self:showTip()
    end
    
end
--显示tip框
function GameScreenApolloMachine:showTip(isPlaySound)
    if isPlaySound == nil then
        isPlaySound = false
    end
    if self.m_tipsNode:isVisible() == false then
        if self:checkShopShouldClick() then
            return
        end
        self.m_tipsNode:setVisible(true)
        self.m_tipsNode:playAction("start",false)
        performWithDelay(self.m_tipsNode.m_delayNode,function ()
            self:hideTip(false)
        end,3)
        if isPlaySound then
            gLobalSoundManager:playSound("ApolloSounds/music_Apollo_tipOpenClick.mp3")
        end
    else
        self:hideTip(isPlaySound)
    end
end
--隐藏tip框
function GameScreenApolloMachine:hideTip(isPlaySound)
    if isPlaySound == nil then
        isPlaySound = false
    end
    self.m_tipsNode.m_delayNode:stopAllActions()
    if self.m_tipsNode.m_isClosing == false then
        if isPlaySound then
            gLobalSoundManager:playSound("ApolloSounds/music_Apollo_tipCloseClick.mp3")
        end
        self.m_tipsNode.m_isClosing = true
        self.m_tipsNode:playAction("over",false,function ()
            self.m_tipsNode.m_isClosing = false
            self.m_tipsNode:setVisible(false)
        end)
    end
end
--[[
    @desc: 获得轮盘的位置
]]
function GameScreenApolloMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

function GameScreenApolloMachine:addObservers()
	BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        local winLines = self.m_reelResultLines
        if #winLines == 1 and  winLines[1].enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            return
        end

        if self.m_bIsBigWin then
            if not (self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0) then
                return
            end
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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "ApolloSounds/music_Apollo_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)

    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        self:updateLockUi(perBetLevel)
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:showChooseOneView()
    end,"GameScreenApolloMachine_showChooseOneView")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:chooseOneViewCollectCoin(params[1])
    end,"GameScreenApolloMachine_chooseOneViewCollectCoin")
end
function GameScreenApolloMachine:updateLockUi( perBetLevel ,isPlayAni)
    if perBetLevel > self.m_iBetLevel then
        -- 锁住
        local btnUnLock = self.m_baseLoadingBar:findChild("unlock")
        btnUnLock:stopAllActions()
        if btnUnLock then
            btnUnLock:setVisible(true)
        end
        self.m_baseLoadingBar.m_unLock:playAction("idle")
        self.m_baseLoadingBar.m_unLock.m_isJiesuoIng = false
    elseif perBetLevel < self.m_iBetLevel then
        -- 解锁
        local btnUnLock = self.m_baseLoadingBar:findChild("unlock")
        if isPlayAni == nil then
            isPlayAni = true
        end
        if isPlayAni == true then
            self.m_baseLoadingBar.m_unLock.m_isJiesuoIng = true
            self.m_baseLoadingBar.m_unLock:playAction("jiesuo",false,function ()
                if self.m_baseLoadingBar.m_unLock.m_isJiesuoIng == true then
                    self.m_baseLoadingBar.m_unLock.m_isJiesuoIng = false
                    if btnUnLock then
                        btnUnLock:setVisible(false)
                    end
                end
            end)
        else
            if btnUnLock then
                btnUnLock:setVisible(false)
            end
        end
    end
end
function GameScreenApolloMachine:unlockHigherBet()
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

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end
-- 高低bet玩法
function GameScreenApolloMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if  betCoin == nil or betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end

    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 1
    end
end
function GameScreenApolloMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

-- ------------玩法处理 --

---
-- 添加关卡中触发的玩法
--
function GameScreenApolloMachine:addSelfEffect()
    self.m_collectList = {}

    self:updateCollectList()

    if self.m_collectList and #self.m_collectList > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT

        --是否触发收集小游戏
        if self:BaseMania_isTriggerCollectBonus() then
            self.m_triggerBonus = true
        end
    end

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.freeMultiple then
        local lines = self.m_runSpinResultData.p_winLines
        local isMultiple = true
        if #lines == 0 then
            isMultiple = false
        end
        if #lines == 1 then
            if lines[1].p_type == 90 then
                isMultiple = false
            end
        end
        if isMultiple then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREESPINCHANGEMULTIPLE_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREESPINCHANGEMULTIPLE_EFFECT
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function GameScreenApolloMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        self:playCollectEffect(effectData)
    elseif effectData.p_selfEffectType == self.FREESPINCHANGEMULTIPLE_EFFECT then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_freespinmultiple.mp3",false)
        self.m_freespinMultiple:playAction("actionframe")
        self.m_dajuese:setAnimation(0, "actionframe3_chufa", false)
        self.m_dajuese:addAnimation(0, "idleframe3", true)
        util_spineFrameEvent(self.m_dajuese,"actionframe3_chufa","chufa",function ()
            local startWorldPos = self.m_freespinMultiple:getParent():convertToWorldSpace(cc.p(self.m_freespinMultiple:getPosition()))
            local startPos = self.m_clipParent:convertToNodeSpace(startWorldPos)
            local endPos = cc.p(self:findChild("Apollo_reel_kuang"):getPosition())
            self:runFreespinTuoWeiAct(startPos,endPos,function ()
                self.m_freespinMultiple:playAction("over")
                self.m_reelEffect:setVisible(true)
                self.m_reelEffect:playAction("shouji",false,function ()
                    self.m_reelEffect:setVisible(false)
                end)
                performWithDelay(self,function ()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,11/60)
            end)
        end)
        -- performWithDelay(self,function ()
            
        -- end,20/30)
    end
	return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function GameScreenApolloMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end

function GameScreenApolloMachine:playEffectNotifyNextSpinCall()
    self.m_bSlotRunning = false
    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
end

function GameScreenApolloMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    BaseNewReelMachine.slotReelDown(self)
end


function GameScreenApolloMachine:runJieSuanTuoWeiAct(startPos,endPos,func)
    -- 创建粒子
    local flyNode = util_createAnimation( "Apollo_jiesuan_tuowei.csb" )
    self.m_clipParent:addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    flyNode:setPosition(cc.p(startPos))

    local angle = util_getAngleByPos(startPos,endPos)
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
    flyNode:setScaleX(scaleSize / 518 )

    flyNode:runCsbAction("actionframe",false,function()
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    performWithDelay(flyNode,function ()
        if func then
            func()
        end
    end,20/60)

    return flyNode
end

function GameScreenApolloMachine:runFreespinTuoWeiAct(startPos,endPos,func)
    -- 创建粒子
    local flyNode = util_createAnimation( "Apollo_jiesuan_tuowei_0.csb" )
    self.m_clipParent:addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    flyNode:setPosition(cc.p(startPos))

    local shuzi = util_createAnimation("Apollo_chengbei.csb")
    flyNode:findChild("chengbei"):addChild(shuzi)
    local multiple = 1
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.freeMultiple then
        multiple = self.m_runSpinResultData.p_selfMakeData.freeMultiple
    end
    shuzi:findChild("BitmapFontLabel_1"):setString(multiple.."X")
    shuzi:playAction("shouji",false)

    local angle = util_getAngleByPos(startPos,endPos)
    flyNode:setRotation( - angle)
    shuzi:setRotation(angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
    flyNode:findChild("tuoweiNode"):setScaleX(scaleSize / 518 )

    flyNode:runCsbAction("actionframe",false,function()
        flyNode:stopAllActions()
        flyNode:removeFromParent()
        shuzi:removeFromParent()
    end)

    performWithDelay(flyNode,function ()
        if func then
            func()
        end
    end,20/60)

    return flyNode
end

function GameScreenApolloMachine:showRespinJackpot(index,coins,multiple,func)
    local jackPotWinView = util_createView("CodeApolloSrc.ApolloJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self,index,coins,multiple,func)
end

function GameScreenApolloMachine:showBonusOverView(_coins,_func)

    if _func then
        _func()
    end

    -- local ownerlist={}
    -- ownerlist["m_lb_coins"] = _coins
    -- local view = self:showDialog("BonusOverView",ownerlist,_func)

    -- util_setCascadeOpacityEnabledRescursion(view,true)
end

--[[
    +++++++++++++
    地图 玩法
]]

function GameScreenApolloMachine:showMapGuoChang(_func,_func1)
    self.m_isShowMapGuochang = true
    self.m_mapGuochang:setVisible(true)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_mapGuochang.mp3",false)
    util_spinePlay(self.m_mapGuochang,"actionframe",false)
    util_spineEndCallFunc(self.m_mapGuochang,"actionframe",function ()
        self.m_mapGuochang:setVisible(false)
        self.m_isShowMapGuochang = false
        if _func1 then
            _func1()
        end
    end)
    util_spineFrameEvent(self.m_mapGuochang,"actionframe","guochang",function ()
        if _func then
            _func()
        end
    end)
end

function GameScreenApolloMachine:checkShopShouldClick()

    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    -- 返回true 不允许点击

    if self.m_isWaitingNetworkData  then
        return true

    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return true

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return true

    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return true

    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then

        return true

    elseif #featureDatas > 1 and self.m_isInit == false then
        return true

    elseif self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return true

    elseif self.m_MapView:isVisible() then
        return true

    elseif self.m_BonusClickView:isVisible() then
        return true

    elseif self.m_bSlotRunning == true then
        return true
    end
    return false
end

function GameScreenApolloMachine:showMapFromBarClick()
    if self.m_bonusPosition then
        if self.m_isShowMapGuochang == false then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self:showMapGuoChang(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                self.m_MapView:updateLittleUINodeAct( self.m_bonusPosition)
                self:clearCurMusicBg()
                self:resetMusicBg(nil,"ApolloSounds/music_Apollo_MapBg.mp3")
                self.m_MapView:showMap()
            end)
        end
    end
end

function GameScreenApolloMachine:initGameStatusData(gameData)
    if gameData and gameData.gameConfig and  gameData.gameConfig.extra ~= nil then
        self:updateMapDataInfo(gameData.gameConfig.extra.bonusPosition,gameData.gameConfig.extra.bonusMap )
    end
    BaseNewReelMachine.initGameStatusData(self, gameData)
end
----
--- 处理spin 成功消息
--
function GameScreenApolloMachine:checkOperaSpinSuccess(param)
    GameScreenApolloMachine.super.checkOperaSpinSuccess(self,param)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setFreespinMultiple(true)
    end
end
-- 更新控制类数据
function GameScreenApolloMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
    self.m_serverWinCoins = spinData.result.winAmount
    self:setLastWinCoin(self.m_serverWinCoins)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusPosition = selfdata.bonusPosition
    self:updateMapDataInfo(bonusPosition)
end

function GameScreenApolloMachine:updateMapDataInfo(_mappos,_mapdata )
    if _mappos then
        self.m_bonusPosition = _mappos
    end
    if _mapdata then
        self.m_bonusMap = _mapdata
    end

end
---
-- 显示bonus 触发的小游戏
function GameScreenApolloMachine:showEffect_Bonus(effectData)
    local time = self:getWinCoinTime()
    performWithDelay(self,function()
        BaseNewReelMachine.showEffect_Bonus(self,effectData)
    end,time)

    return true
end

function GameScreenApolloMachine:showBonusGameView(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_TriggerBonus.mp3",false)
    self.m_baseLoadingBar:playGongdianAni(function ()
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            self:showMapGuoChang(function()
                self.m_bottomUI:showAverageBet()

                self.m_MapView:updateLittleUINodeAct(self.m_bonusPosition)

                self:clearCurMusicBg()
                
                self.m_MapView:showMap(true)
            end )

            self.m_BonusGameOverCall = function()
                self.m_baseLoadingBar:resetProgress()
                self:showBonusOverView(util_formatCoins( self.m_serverWinCoins , 50),function()
                    self.m_bottomUI:hideAverageBet()
                    -- 更新游戏内每日任务进度条
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

                    if self.m_runSpinResultData.p_selfMakeData.cellTable then
                        local lastWinCoin = globalData.slotRunData.lastWinCoin
                        globalData.slotRunData.lastWinCoin = 0
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins ,true,true})
                        globalData.slotRunData.lastWinCoin = lastWinCoin
                    end

                    -- 通知bonus 结束， 以及赢钱多少
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_serverWinCoins, GameEffect.EFFECT_BONUS})

                    performWithDelay(self,function ()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,25/30)--延迟过场事件到过场结束的时间，就是要等过场结束后走下一步
                    

                    self.m_BonusGameOverCall = nil
                end)
            end
            waitNode:removeFromParent()
        end,0.5)
    end)
    
end

--[[
    ***************
    收集 宫殿点击玩法
--]]
function GameScreenApolloMachine:triggerBonusClickGame()
    self:resetMusicBg(nil,"ApolloSounds/music_Apollo_MapBg.mp3")
    self.m_BonusClickView:showBonusClickMainView(function()
        if self.m_BonusGameOverCall then
            self.m_BonusGameOverCall()
        end
    end )
end

function GameScreenApolloMachine:showBonusClickGameGuoChang(_func,_funcEnd)
    self:showMapGuoChang(_func,_funcEnd)
end

--[[
    +++++++++++++
    收集玩法
]]

--更新收集数据 addCount增加的数量  addCoins增加的奖金
function GameScreenApolloMachine:BaseMania_updateCollect(addCount,index,totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index])=="table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

function GameScreenApolloMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount,1,totalCount)
    end
end
--第一次进入本关卡初始化本关收集数据 如果数据格式不同子类重写这个方法
function GameScreenApolloMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList = {}
    --默认总数
    self.m_collectDataList[1] = CollectData.new()
    self.m_collectDataList[1].p_collectTotalCount = 100
    self.m_collectDataList[1].p_collectLeftCount = 100
    self.m_collectDataList[1].p_collectCoinsPool = 0
    self.m_collectDataList[1].p_collectChangeCount = 0
end

function GameScreenApolloMachine:getBaseBarPercent()
    local collectData = self:BaseMania_getCollectData()

    local collectTotalCount = collectData.p_collectTotalCount
    local collectCount = nil

    if collectTotalCount ~= nil then
        collectCount = collectData.p_collectTotalCount - collectData.p_collectLeftCount
    else
        collectTotalCount = collectData.p_collectTotalCount
        collectCount = collectData.p_collectTotalCount - collectData.p_collectLeftCount
    end

    local percent = (collectCount / collectTotalCount) * 100

    return percent
end
function GameScreenApolloMachine:playCollectEffect(effectData)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_collect.mp3",false)
    local endNode = self.m_baseLoadingBar:findChild("Node_actPos")
    local endPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))

    local pecent = self:getBaseBarPercent()

    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self.m_clipParent:convertToNodeSpace(startPos)
        local newEndPos = self.m_clipParent:convertToNodeSpace(endPos)
        local func = nil

        if i == 1 then
            func = function()
                self.m_baseLoadingBar:updatePercent(pecent)
            end
        end

        self:runJieSuanTuoWeiAct(newStartPos,newEndPos,func)

        table.remove(self.m_collectList, i)
    end

    local delayTime = 0
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true or
        self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true or
            self.m_collectGameWait == true then

        delayTime = 0.5 + 0.7
    end

    if self.m_triggerBonus == true  then
        delayTime = 0.5 + 0.7
    end

    performWithDelay(self, function()
        effectData.p_isPlay = true
        self:playGameEffect()
        self.m_collectGameWait = false
        self.m_triggerBonus = false
    end, delayTime )
end

function GameScreenApolloMachine:updateCollectList()
    if self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self.m_iBetLevel == 1 then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
                if node then
                    if self:isFixSymbol(node.p_symbolType) then
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end
    end
end

function GameScreenApolloMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index=1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end

-- lighting 断线重连时，随机转盘数据
function GameScreenApolloMachine:respinModeChangeSymbolType()
    --这里啥也别干就是了
end

function GameScreenApolloMachine:showChooseOneView()
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_showChooseOneView.mp3")
    local chooseOneView = util_createView("CodeApolloSrc.Map.ApplloThreeChooseOneView",{coinNum = self.m_runSpinResultData.p_winAmount})
    self:addChild(chooseOneView,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 2)
    chooseOneView:findChild("root"):setScale(self.m_machineRootScale)

    if globalData.slotRunData.machineData.p_portraitFlag then
        chooseOneView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = chooseOneView})
end

function GameScreenApolloMachine:chooseOneViewCollectCoin(startWorldPos)
    local fly = util_createAnimation("Apollo_jiesuan_tuowei.csb")
    self:addChild(fly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = self:convertToNodeSpace(startWorldPos)
    local endWorldPos = self.m_bottomUI:getCoinWinNode():getParent():convertToWorldSpace(cc.p(self.m_bottomUI:getCoinWinNode():getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))

    local angle = util_getAngleByPos(startPos,endPos)
    fly:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
    fly:setScaleX(scaleSize / 535 )

    fly:setPosition(startPos)

    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_chooseOneCollect.mp3")
    fly:runCsbAction("actionframe",false,function()
        fly:stopAllActions()
        fly:removeFromParent()
    end)

    performWithDelay(fly,function ()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, true, true})
        self:playCoinWinEffectUI(function ()
            performWithDelay(self,function ()
                self:showMapGuoChang(function ()
                    gLobalNoticManager:postNotification("ApplloThreeChooseOneView_closeSelf")
                end)
            end,2.5)
        end)
    end,30/60)
end

function GameScreenApolloMachine:getNormalType()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2
    }
    return symbolList[math.random(1, #symbolList)]
end
--初始化的 wild图标变为普通图标
function GameScreenApolloMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex=1,rowCount do
            local symbolType = self:getRandomReelType(colIndex,reelDatas)
            if self:isFixSymbol(symbolType) or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolType = self:getNormalType()
            end
            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex , reelDatas   )

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex
           

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end
            
--            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )

           
        end
    end
    self:initGridList()
end
return GameScreenApolloMachine