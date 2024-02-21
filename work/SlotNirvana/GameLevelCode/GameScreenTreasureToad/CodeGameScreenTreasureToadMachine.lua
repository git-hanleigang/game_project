---
-- island li
-- 2019年1月26日
-- CodeGameScreenTreasureToadMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "TreasureToadPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenTreasureToadMachine = class("CodeGameScreenTreasureToadMachine", BaseNewReelMachine)

CodeGameScreenTreasureToadMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenTreasureToadMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenTreasureToadMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenTreasureToadMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenTreasureToadMachine.SYMBOL_FIX_SYMBOL1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenTreasureToadMachine.SYMBOL_FIX_SYMBOL2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3

CodeGameScreenTreasureToadMachine.SYMBOL_RS_SCORE_BLANK = 100   
CodeGameScreenTreasureToadMachine.SYMBOL_RS_SCORE_BLANK1 = 101     

CodeGameScreenTreasureToadMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1          --收集
CodeGameScreenTreasureToadMachine.DROP_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2          --掉落


CodeGameScreenTreasureToadMachine.m_chipList = nil
CodeGameScreenTreasureToadMachine.m_playAnimIndex = 0
CodeGameScreenTreasureToadMachine.m_lightScore = 0

CodeGameScreenTreasureToadMachine.BONUS_RUN_NUM = 4
CodeGameScreenTreasureToadMachine.LONGRUN_COL_ADD_BONUS = 5

local CURRENT_NUM = {
    INDEX_ONE =   1,
    INDEX_TWO =   2,
    INDEX_THREE = 3,
    INDEX_FOUR =  4,
    INDEX_FIVE =  5,
}

local RESPIN_EFFECT = {
    MAX_UP_TIER = 20000,
    UP_TIER = 10000,
    MIDDLE_TIER = 3000,
    DOWN_TIER = 1000,
    MIN_DOWN_TIER = 100
}

local OvalConfig = {
    ellipseA = 310,
    ellipseB = 150,
}

local MATH_PIOVER2 = 1.57079632679489661923
local AVE_ANGLE = 34

-- 构造函数
function CodeGameScreenTreasureToadMachine:ctor()
    CodeGameScreenTreasureToadMachine.super.ctor(self)

    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    --大赢光效
    self.m_isAddBigWinLightEffect = true
    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    --bonus计数
    self.bonusNum1 = 0  --金蝉
    self.bonusNum2 = 0  --聚宝盆
    self.bonusNum3 = 0  --金币

    self.m_isLongRun = false   --是否处于base快滚状态

    self.tempRoleCoins = 0
    self.beforeTempCoins = 0
    self.moveNum = 0

    self.isMoveCollect = false

    self.isRespin = true

    self.aveLong = 40

    self.bonusPause = false

    self.isRespinOver = false

    self.scatterNum = 0
    self.m_jackpot_status = "Normal"
    self.m_isJackpotEnd = false
	--init
	self:initGame()
end

function CodeGameScreenTreasureToadMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("TreasureToadConfig.csv", "LevelTreasureToadConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  



function CodeGameScreenTreasureToadMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --特效节点
    self.m_effect = cc.Node:create()
    self:findChild("Node_zong"):addChild(self.m_effect,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    --respin中特殊bonus收集用
    self.m_effectRespin = cc.Node:create()
    self:findChild("Node_zong"):addChild(self.m_effectRespin,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 21)

    self.scheduleEffectNode = cc.Node:create()
    self:findChild("Node_zong"):addChild(self.scheduleEffectNode)

    self:initFreeSpinBar() -- FreeSpinbar
    self:createBigRole()
    self:addGoldEffect()
   
    --jackpotBar
    self.m_jackPotBar = util_createView("CodeTreasureToadSrc.TreasureToadJackPotBarView")  --jackpot
    self:findChild("jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:setVisible(true)

    --respinBar
    self.m_respinBar = util_createView("CodeTreasureToadSrc.TreasureToadRespinBarView")
    self:findChild("RespinBar"):addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)

    --winner
    self.m_winnerBar = util_createView("CodeTreasureToadSrc.TreasureToadRespinWinnerView")
    self:findChild("Node_Winner"):addChild(self.m_winnerBar)
    self.m_winnerBar:setVisible(false)
 
    self.m_spineGuochang = util_spineCreate("TreasureToad_guochang", true, true)
    self.m_spineGuochang:setScale(self.m_machineRootScale)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang:setVisible(false)

    self.m_spineGuochang2 = util_spineCreate("TreasureToad_guochang2", true, true)
    self.m_spineGuochang2:setScale(self.m_machineRootScale)
    self:addChild(self.m_spineGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_spineGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang2:setVisible(false)

    self.bigWinEffect = util_spineCreate("TreasureToad_bigwin", true, true)
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
    self:findChild("root"):addChild(self.bigWinEffect)
    self.bigWinEffect:setPosition(cc.p(pos.x + 50,pos.y + 15))
    self.bigWinEffect:setVisible(false)

    self:findChild("Node_yugao"):setVisible(false)
    self:showUIForIndex(CURRENT_NUM.INDEX_ONE)

    self:createBlackLayer()

    self.noClickLayer = util_createAnimation("Treasure_NoClick.csb")
    self:addChild(self.noClickLayer, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.noClickLayer:setPosition(display.width * 0.5, display.height * 0.5)
    self.noClickLayer:setVisible(false)

end

--添加黑色遮罩用于滚动
function CodeGameScreenTreasureToadMachine:createBlackLayer()
    self.m_colorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[i]
        local mask = cc.LayerColor:create(cc.c3b(0,0,0), parentData.reelWidth, parentData.reelHeight + 500):hide()
        mask:setOpacity(180)
        mask:setPositionX(parentData.reelWidth / 2)
        mask:setPositionY(-200)
        parentData.slotParent:addChild(mask, REEL_SYMBOL_ORDER.REEL_ORDER_MASK)
        self.m_colorLayers[i] = mask
    end
end

function CodeGameScreenTreasureToadMachine:showColorLayer(bfade)
    for i,v in ipairs(self.m_colorLayers) do
        v:show()
        if bfade then
            v:setOpacity(0)
            v:runAction(cc.FadeTo:create(0.3, 180))
        else   
            v:setOpacity(180)
        end
    end
end

function CodeGameScreenTreasureToadMachine:hideColorLayer(bfade)
    for i,v in ipairs(self.m_colorLayers) do
        if bfade then
            v:runAction(cc.Sequence:create(cc.FadeTo:create(0.3,0),cc.CallFunc:create(function(p)
                p:hide()
            end)))
        else 
            v:setOpacity(0) v:hide()
        end
    end
end

function CodeGameScreenTreasureToadMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    local fadeAct = cc.FadeTo:create(0.3, 0)
    local func = cc.CallFunc:create( function()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

--[[
    @desc: FreeSpinBar
    author:{author}
    time:2023-05-05 12:25:26
    --@index: 
    @return:
]]
function CodeGameScreenTreasureToadMachine:initFreeSpinBar()
    local parent = self:findChild("FreeSpinBar")
    self.m_freeSpinBar = util_createView("CodeTreasureToadSrc.TreasureToadFreespinBarView")
    parent:addChild(self.m_freeSpinBar)
    util_setCsbVisible(self.m_freeSpinBar, false)
    self.m_freeSpinBar:setPosition(0, 0)
end

function CodeGameScreenTreasureToadMachine:showUIForIndex(index)
    self:showBgForIndex(index)
    self:showReelBgForIndex(index)
    self:showGoldEffect(index)
end

--[[
    @desc: 背景
    author:{author}
    time:2023-05-05 11:52:52
    @return:
]]
function CodeGameScreenTreasureToadMachine:showBgForIndex(index)
    if index == 1 then
        util_setCsbVisible(self.m_freeSpinBar, false)
        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("fg"):setVisible(false)
        self.m_gameBg:findChild("respin"):setVisible(false)
    elseif index == 2 then
        util_setCsbVisible(self.m_freeSpinBar, true)
        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("fg"):setVisible(true)
        self.m_gameBg:findChild("respin"):setVisible(false)
    elseif index == 3 then
        util_setCsbVisible(self.m_freeSpinBar, false)
        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("fg"):setVisible(false)
        self.m_gameBg:findChild("respin"):setVisible(true)
    end
end

--[[
    @desc: 金币堆
    author:{author}
    time:2023-05-05 14:03:14
    --@index: 
    @return:
]]

function CodeGameScreenTreasureToadMachine:addGoldEffect()
    self.goldBg = util_spineCreate("TreasureToad_Respin_bg", true, true)
    self:findChild("Node_jinbi"):addChild(self.goldBg)
    self.freeBgLighting = util_createAnimation("Socre_TreasureToad_bg_guang.csb")  
    self:findChild("Node_guang_qipan_fg_0"):addChild(self.freeBgLighting)
    self.freeBgLighting:setVisible(false)
end

function CodeGameScreenTreasureToadMachine:showGoldEffect(index)
    if index == 1 then
        self.bigRole:setVisible(true)
        util_spinePlay(self.goldBg, "idle2",true)
        self.freeBgLighting:setVisible(false)
    elseif index == 2 then
        self.bigRole:setVisible(true)
        util_spinePlay(self.goldBg, "idle2",true)
        self.freeBgLighting:setVisible(true)
        self.freeBgLighting:runCsbAction("idleframe",true)
    elseif index == 3 then
        self.bigRole:setVisible(false)
        util_spinePlay(self.goldBg, "idle1",true)
        self.freeBgLighting:setVisible(false)
    end
end

--[[
    @desc: 棋盘背景
    author:{author}
    time:2023-05-05 12:09:26
    @return:
]]
function CodeGameScreenTreasureToadMachine:showReelBgForIndex(index)
    if index == 1 then
        self:findChild("base"):setVisible(true)
        self:findChild("free"):setVisible(false)
        self:findChild("respin"):setVisible(false)
    elseif index == 2 then
        self:findChild("base"):setVisible(false)
        self:findChild("free"):setVisible(true)
        self:findChild("respin"):setVisible(false)
    elseif index == 3 then
        self:findChild("base"):setVisible(false)
        self:findChild("free"):setVisible(false)
        self:findChild("respin"):setVisible(true)
    end
end

--[[
    @desc: 角色
    author:{author}
    time:2023-05-05 12:01:05
    @return:
]]
function CodeGameScreenTreasureToadMachine:createBigRole()
    self.bigRole = util_spineCreate("Socre_TreasureToad_Bonus2", true, true)
    self:findChild("Node_role"):addChild(self.bigRole)
    util_spinePlay(self.bigRole, "idleframe2",true)
end

-- 断线重连 
function CodeGameScreenTreasureToadMachine:MachineRule_initGame(  )
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_freeSpinBar:changeFreeSpinByCount()
        util_setCsbVisible(self.m_freeSpinBar, true)
        self:showUIForIndex(CURRENT_NUM.INDEX_TWO)
    end
    --判断是否为respin断线
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local dropReels = selfData.dropReels or {}                            --掉落后轮盘数据
    if table_length(dropReels) > 0 then
        self.m_runSpinResultData.p_reels = dropReels
    end
    local reSpinCurCount = self:getCurRespinCount()
    if reSpinCurCount and reSpinCurCount > 0 then
        self.isRespin = false
        -- self:showUIForIndex(CURRENT_NUM.INDEX_THREE)
        self:getRedDi():setVisible(false)
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenTreasureToadMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "TreasureToad"  
end

-- 继承底层respinView
function CodeGameScreenTreasureToadMachine:getRespinView()
    return "CodeTreasureToadSrc.TreasureToadRespinView"
end
-- 继承底层respinNode
function CodeGameScreenTreasureToadMachine:getRespinNode()
    return "CodeTreasureToadSrc.TreasureToadRespinNode"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenTreasureToadMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_TreasureToad_Bonusb"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_TreasureToad_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_TreasureToad_11"
    end

    if symbolType == self.SYMBOL_FIX_SYMBOL1 then
        return "Socre_TreasureToad_Bonus1"
    end

    if symbolType == self.SYMBOL_FIX_SYMBOL2 then
        return "Socre_TreasureToad_Bonus2"
    end

    if symbolType == self.SYMBOL_RS_SCORE_BLANK then
        return "Socre_TreasureToad_blank"
    end
    if symbolType == self.SYMBOL_RS_SCORE_BLANK1 then
        return "Socre_TreasureToad_blank1"
    end

    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenTreasureToadMachine:getReSpinSymbolScore(id)
    local storedIcons = nil
    if self:getCurrSpinMode() == RESPIN_MODE then
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
        storedIcons = rsExtraData.storedIcons or {}      --respin下的bonus信息
        if self:isShowCollectForRespin() then           --若此次触发特殊bonus收集从beforeStoredIcons获取
            storedIcons = rsExtraData.beforeStoredIcons or {}
        end
    else
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        storedIcons = selfData.storedIcons or {}      --base下的bonus信息

        local reSpinCurCount = self:getCurRespinCount()
        if reSpinCurCount > 0 then      --若respin没结束断线或触发respin
            local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
            storedIcons = rsExtraData.storedIcons or {}
            if self:isShowCollectForRespin() then       --触发的时候从beforeStoredIcons获取
                storedIcons = rsExtraData.beforeStoredIcons or {}
            end
        end
    end

    local score = nil
    local idNode = nil
    local nodeType = "Normal"

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = tonumber(values[3])
            idNode = values[1]
            nodeType = values[4]
        end
    end

    if score == nil then
       return 0 ,nodeType
    end

    return score,nodeType
end

function CodeGameScreenTreasureToadMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    local nodeType = "Normal"
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end
    if tonumber(score) == 10 then
        nodeType = "Mini"
    elseif tonumber(score) == 20 then
        nodeType = "Minor"
    elseif tonumber(score) == 100 then
        nodeType = "Major"
    elseif tonumber(score) == 1000 then
        nodeType = "Grand"
    end
    local lineBet = globalData.slotRunData:getCurTotalBet()
    score = score * lineBet
    return score,nodeType
end

-- 给respin小块进行赋值
function CodeGameScreenTreasureToadMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local score = 0
    local nodeType = "Normal"
    
    if not  symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL then
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
        score,nodeType = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）

    else
        score,nodeType =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）

    end
    self:addLevelBonusSpine(symbolNode,score,nodeType)
end


function CodeGameScreenTreasureToadMachine:isJackpotType(type)
    if type == "Grand" or
        type == "Major" or
            type == "Minor" or
                type == "Mini" then
        return true
    end
    return false
end

function CodeGameScreenTreasureToadMachine:changeCoinsShow(coinsView,score,nodeType)
    coinsView:findChild("Grand"):setVisible(false)
    coinsView:findChild("Super"):setVisible(false)
    coinsView:findChild("Mega"):setVisible(false)
    coinsView:findChild("Major"):setVisible(false)
    coinsView:findChild("Minor"):setVisible(false)
    coinsView:findChild("Mini"):setVisible(false)
    coinsView:findChild("m_lb_coins"):setVisible(false)
    if nodeType == "Normal" or nodeType == "Bonus1" or nodeType == "Bonus2" then
        coinsView:findChild("m_lb_coins"):setVisible(true)
        coinsView:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
        self:updateLabelSize({label=coinsView:findChild("m_lb_coins"),sx=0.42,sy=0.42}, 290)
    else
        if self:isJackpotType(nodeType) then
            if nodeType == "Grand" then
                if self.m_jackpot_status == "Super" then
                    coinsView:findChild("Super"):setVisible(true)
                elseif self.m_jackpot_status == "Mega" then
                    coinsView:findChild("Mega"):setVisible(true)
                else
                    coinsView:findChild("Grand"):setVisible(true)
                end
            else
                coinsView:findChild(nodeType):setVisible(true)
            end
            
        end
    end
end


function CodeGameScreenTreasureToadMachine:updateReelGridNode(node)
    CodeGameScreenTreasureToadMachine.super.updateReelGridNode(self, node)
    local symbolType = node.p_symbolType
    local iCol = node.p_cloumnIndex
    local iRow = node.p_rowIndex
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        if not tolua.isnull(node.m_csbNode) then
            node.m_csbNode:removeFromParent()
            node.m_csbNode = nil
        end
        self:setSpecialNodeScore(self,{node})
    end
    if symbolType == self.SYMBOL_FIX_SYMBOL1 or symbolType == self.SYMBOL_FIX_SYMBOL2 then
        if not tolua.isnull(node.m_csbNode) then
            node.m_csbNode:removeFromParent()
            node.m_csbNode = nil
        end
        local score,nodeType = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
        self:addLevelBonusSpineForSpecial(node,score,nodeType)
    end
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenTreasureToadMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenTreasureToadMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL2,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenTreasureToadMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL1 or 
        symbolType == self.SYMBOL_FIX_SYMBOL2  then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenTreasureToadMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenTreasureToadMachine.super.slotOneReelDown(self,reelCol) 
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self:reelStopHideMask(reelCol)
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        if reelCol == self.m_iReelColumnNum then
            if self.m_isLongRun then
                local features = self.m_runSpinResultData.p_features
                if not features or #features <= 1 then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_keep_going)
                end
            end
            
        end
    end

    --期待感动画
    for iCol = 1,reelCol do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(symbolNode) then
                if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and isTriggerLongRun and symbolNode.m_currAnimName ~= "idleframe3" then
                    symbolNode:runAnim("idleframe3",true)
                end
            end
        end
    end

    if not self.m_isLongRun then
        self.m_isLongRun = isTriggerLongRun
    end
    return isTriggerLongRun
end

function CodeGameScreenTreasureToadMachine:beginReel()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self:showColorLayer(true)
    end
    CodeGameScreenTreasureToadMachine.super.beginReel(self)
    self.m_isLongRun = false
    self.isRespinOver = false
    self.scatterNum = 0
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenTreasureToadMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenTreasureToadMachine:levelFreeSpinOverChangeEffect()

    
    
end
---------------------------------------------------------------------------

function CodeGameScreenTreasureToadMachine:getTempScatterForTrigger(node)
    local iCol = node.p_cloumnIndex
    local iRow = node.p_rowIndex
    local nodeIndex = self:getPosReelIdx(iRow, iCol)
    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newStartPos = self.m_effect:convertToNodeSpace(startPos)
    local newBonusSpine = util_spineCreate("Socre_TreasureToad_Scatter",true,true)
    self.m_effect:addChild(newBonusSpine)
    newBonusSpine:setPosition(newStartPos)
    local zOder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    newBonusSpine:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - node.p_rowIndex)
    return newBonusSpine
end

-- 显示free spin
function CodeGameScreenTreasureToadMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    local tempScatter = {}
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

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
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:runCsbAction("start",false,function ()
        -- self:runCsbAction("idle")
    end)
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TreasureToad_trigger_scatter)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(node) and node.p_symbolType then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    node:setVisible(false)
                    local newBonusSpine = self:getTempScatterForTrigger(node)
                    tempScatter[#tempScatter + 1] = newBonusSpine
                    util_spinePlay(newBonusSpine, "actionframe", false)
                end
            end
        end
    end

    self:delayCallBack(2,function ()
        self:runCsbAction("over")
        --压黑结束在显示真正的图标
        self:delayCallBack(0.5,function ()
            for i,v in ipairs(tempScatter) do
                if not tolua.isnull(v) then
                    v:removeFromParent()
                end
            end
            tempScatter = {}
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if not tolua.isnull(node) and node.p_symbolType then
                        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            node:setVisible(true)
                            node:runAnim("idleframe")
                        end
                    end
                end
            end
            self:showFreeSpinView(effectData)
        end)
    end)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenTreasureToadMachine:showFreeSpinStart(num, func, isAuto)
    local params = {
        path = 1,
        isAuto = false,
        endFunc = func,
        num = num,
    }
    local view = util_createView("CodeTreasureToadSrc.TreasureToadView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end


-- 触发freespin时调用
function CodeGameScreenTreasureToadMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showGuochang(1,function ()
                    self:showUIForIndex(CURRENT_NUM.INDEX_TWO)
                    self.m_freeSpinBar:changeFreeSpinByCount()
                end,function ()
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
function CodeGameScreenTreasureToadMachine:showFreeSpinOverView()
    self:clearCurMusicBg()
    if globalData.slotRunData.lastWinCoin == 0 then
        self:showNoWinView(function ()
            self:showGuochang2(3,function ()
                self:showUIForIndex(CURRENT_NUM.INDEX_ONE)
            end,function ()
                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:triggerFreeSpinOverCallFun()
            end)
        end)
    else
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:showGuochang2(3,function ()
                    self:showUIForIndex(CURRENT_NUM.INDEX_ONE)
                end,function ()
                    -- 调用此函数才是把当前游戏置为freespin结束状态
                    self:triggerFreeSpinOverCallFun()
                end)   
            end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},642)
        view:findChild("root"):setScale(self.m_machineRootScale - 0.1)
    end
end

--无赢钱
function CodeGameScreenTreasureToadMachine:showNoWinView(func)
    local view = self:showDialog("FreeSpinOver_NoWin", nil, func)
    local bottonSg = util_spineCreate("TreasureToad_anniu_sg",true,true)
    local ziSg = util_spineCreate("TreasureToad_zi_sg",true,true)
    util_spinePlay(bottonSg, "idle2",true)
    util_spinePlay(ziSg, "idle2",true)
    view:findChild("Node_sg1"):addChild(ziSg)
    view:findChild("Node_sg2"):addChild(bottonSg)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_click)
    end)
    return view
end

function CodeGameScreenTreasureToadMachine:showFreeSpinOver(coins, num, func)
    
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_freeSpin_over_show)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    local jvese = util_spineCreate("Socre_TreasureToad_Bonus2",true,true)
    local bottonSg = util_spineCreate("TreasureToad_anniu_sg",true,true)
    local ziSg = util_spineCreate("TreasureToad_zi_sg",true,true)
    local lighting = util_createAnimation("Socre_TreasureToad_bg_guang.csb")
    util_spinePlay(jvese, "idleframe3",true)
    lighting:runCsbAction("idleframe",true)
    util_spinePlay(bottonSg, "idle2",true)
    util_spinePlay(ziSg, "idle1",true)
    view:findChild("Node_juese"):addChild(jvese)
    view:findChild("Node_guang"):addChild(lighting)
    view:findChild("Node_sg1"):addChild(ziSg)
    view:findChild("Node_sg2"):addChild(bottonSg)
    

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_freeSpin_over_hide)
    end)
    
    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

--1-4分别为mini-grand
function CodeGameScreenTreasureToadMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeTreasureToadSrc.TreasureToadJackPotWinView",{machine = self})
    gLobalViewManager:showUI(jackPotWinView)
    local _data = {
        coins   = coins,
        index   = index,
        func    = func,
        machine = self,
    }
    jackPotWinView:initViewData(_data)
    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)
end

-- 结束respin收集
function CodeGameScreenTreasureToadMachine:playLightEffectEnd()
    self:delayCallBack(0.5,function ()
        -- 通知respin结束
        self:respinOver()
    end)
end

function CodeGameScreenTreasureToadMachine:getGrandCoins()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    local grandCoins = jackpotCoins.Grand
    return tonumber(grandCoins)
end

function CodeGameScreenTreasureToadMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        -- if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)  then
        --     -- 如果全部都固定了，会中JackPot档位中的Grand
        --     local jackpotScore = self:BaseMania_getJackpotScore(1)
        --     self.m_lightScore = self.m_lightScore + jackpotScore
        --     self:showRespinJackpot(
        --         4,
        --         self.m_lightScore,
        --         function()
        --             -- 此处跳出迭代
        --             self:playLightEffectEnd()        
        --         end
        --     )
        -- else
            -- 此处跳出迭代
            self:playLightEffectEnd()
        
        -- end
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_effect:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    -- 根据网络数据获得当前固定小块的分数
    local score,nodeType = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil then
        if nodeType == "Normal" then    --金币
            addScore = score
            self.bonusNum3 = self.bonusNum3 + 1
        elseif nodeType == "Bonus1" then    --聚宝盆
            addScore = score
            self.bonusNum2 = self.bonusNum2 + 1
        elseif nodeType == "Bonus2" then    --金蝉
            addScore = score
            self.bonusNum1 = self.bonusNum1 + 1
        elseif nodeType == "Grand" then
            --self:BaseMania_getJackpotScore(1)
            jackpotScore = score
            addScore = jackpotScore + addScore
            self.bonusNum3 = self.bonusNum3 + 1
            nJackpotType = 4
        elseif nodeType == "Major" then
            --self:BaseMania_getJackpotScore(2)
            jackpotScore = score
            addScore = score + addScore
            self.bonusNum3 = self.bonusNum3 + 1
            nJackpotType = 3
        elseif nodeType == "Minor" then
            --self:BaseMania_getJackpotScore(3)
            jackpotScore =  score
            addScore =score + addScore                  ---self:BaseMania_getJackpotScore(3)
            self.bonusNum3 = self.bonusNum3 + 1
            nJackpotType = 2
        elseif nodeType == "Mini" then
            --self:BaseMania_getJackpotScore(4) 
            jackpotScore =  score
            addScore =  score + addScore                      ---self:BaseMania_getJackpotScore(4)
            self.bonusNum3 = self.bonusNum3 + 1
            nJackpotType = 1
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if nJackpotType == 0 then
            local info = {
                node = chipNode,
                coins = self.m_lightScore,
                num = {self.bonusNum3,self.bonusNum2,self.bonusNum1},
                func1 = function ()
                    self.m_playAnimIndex = self. m_playAnimIndex + 1
                    self:playChipCollectAnim() 
                end,
                func2 = function ()
                    -- chipNode:runAnim("yaan",false,function ()
                    --     chipNode:runAnim("yaan_idleframe")
                    -- end)
                end
            }
            self:flyCollectBonusForReSpin(info)
        else
            local info = {
                node = chipNode,
                coins = self.m_lightScore,
                num = {self.bonusNum3,self.bonusNum2,self.bonusNum1},
                func1 = function ()
                    self.m_jackPotBar:triggerJackpotBar(nJackpotType)
                    self:showRespinJackpot(nJackpotType, jackpotScore, function()
                        self.m_jackPotBar:showLightingNode()
                        self.m_playAnimIndex = self.m_playAnimIndex + 1
                        self:playChipCollectAnim() 
                    end)
                end,
                func2 = function ()
                    -- chipNode:runAnim("yaan")
                end
            }
            self:flyCollectBonusForReSpin(info)
          
        end
    end
    
    runCollect()    

end

function CodeGameScreenTreasureToadMachine:flyCollectBonusForReSpin(info)
    local symbol = info.node
    local coins = info.coins
    local num = info.num or {0,0,0}
    local func1 = info.func1
    local func2 = info.func2

    if not not tolua.isnull(symbol) then
        if func1 then
            func1()
        end
        return
    end
    local bonusSpine = nil
    if symbol.p_symbolType then
        if symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL1 then
            bonusSpine = util_spineCreate("Socre_TreasureToad_Bonus1", true, true)
            util_spinePlay(bonusSpine,"idleframe")
        elseif symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL2 then
            bonusSpine = util_spineCreate("Socre_TreasureToad_Bonus2", true, true)
            util_spinePlay(bonusSpine,"idleframe")
        else
            bonusSpine = util_spineCreate("Socre_TreasureToad_Bonusb", true, true)
            util_spinePlay(bonusSpine,"idleframe2_2")
        end
    else
        bonusSpine = util_spineCreate("Socre_TreasureToad_Bonusb", true, true)
        util_spinePlay(bonusSpine,"idleframe2_2")
    end
    
    local pos = util_convertToNodeSpace(symbol,self.m_effect)
    local endPos = util_convertToNodeSpace(self.m_winnerBar,self.m_effect)
    self.m_effect:addChild(bonusSpine)
    bonusSpine:setPosition(pos)
    bonusSpine:setVisible(false)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local type = self:getRespinOverTypeForIndex(symbol)
        local actName = self:getRespinOverActName(type)
        symbol:runAnim(actName)
    end)
    actList[#actList + 1] = cc.DelayTime:create(5/30)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        bonusSpine:setVisible(true)
        local actName = nil
        if symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            actName = self:getCollectActName()
        else
            actName = "shouji"
        end
        
        util_spinePlay(bonusSpine,actName)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bonusToTotalWin)
    end)
    actList[#actList + 1] = cc.EaseSineIn:create(cc.MoveTo:create(16/30,endPos))
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        self.m_winnerBar:updateCoins(coins)
        self.m_winnerBar:updateCount(num[3],num[2],num[1])
        
    end)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if func1 then
            func1()
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if not tolua.isnull(bonusSpine) then
            bonusSpine:removeFromParent()
        end
    end)
    local sq = cc.Sequence:create(actList)
    bonusSpine:runAction(sq)
end

function CodeGameScreenTreasureToadMachine:isBonusType(type)
    if type == self.SYMBOL_FIX_SYMBOL or 
        type == self.SYMBOL_FIX_SYMBOL1 or 
            type == self.SYMBOL_FIX_SYMBOL2 then
        return true
    end
    return false
end

--结束移除小块调用结算特效
function CodeGameScreenTreasureToadMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1
    self.m_lightScore = 0
    --bonus计数
    self.bonusNum1 = 0  --金蝉
    self.bonusNum2 = 0  --聚宝盆
    self.bonusNum3 = 0  --金币

    -- self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode() 
    self:delayCallBack(0.3,function ()
        self.m_respinBar:runCsbAction("over",false,function ()
            self.m_respinBar:setVisible(false)
        end)
        self.m_winnerBar:initCounts()
        self.m_winnerBar:setVisible(true)
        self.m_winnerBar:showWinner()
    
        self:delayCallBack(0.5,function ()
            self:playChipCollectAnim()
        end)
    end)
    
    
end

function CodeGameScreenTreasureToadMachine:getRespinOverTypeForIndex(lockNode)
    local iCol = lockNode.p_cloumnIndex
    local iRow = lockNode.p_rowIndex  
    local index = self:getPosReelIdx(iRow, iCol)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local storedIcons = rsExtraData.storedIcons or {}
    local nodeType = "Normal"

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == index then
            nodeType = values[4]
        end
    end

    return nodeType
    
end

function CodeGameScreenTreasureToadMachine:getRespinOverActName(type)
    if self:isJackpotType(type) then
        return "actionframe_js2"
    else
        return "actionframe_js"
    end
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenTreasureToadMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_RS_SCORE_BLANK,
        self.SYMBOL_FIX_SYMBOL,
    }


    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenTreasureToadMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_SYMBOL1, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_FIX_SYMBOL2, runEndAnimaName = "buling", bRandom = true},
    }


    return symbolList
end

function CodeGameScreenTreasureToadMachine:getTempBonusForTrigger(node)
    local iCol = node.p_cloumnIndex
    local iRow = node.p_rowIndex
    local nodeIndex = self:getPosReelIdx(iRow, iCol)
    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newStartPos = self.m_effect:convertToNodeSpace(startPos)
    local newBonusSpine = util_spineCreate("Socre_TreasureToad_Bonusb",true,true)
    local goldScore,goldType = self:getReSpinSymbolScore(nodeIndex)
    self:addLevelTempBonusSpine(newBonusSpine,goldScore,goldType,false)
    self.m_effect:addChild(newBonusSpine)
    newBonusSpine:setPosition(newStartPos)
    local zOder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    newBonusSpine:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - node.p_rowIndex)
    return newBonusSpine
end

function CodeGameScreenTreasureToadMachine:triggerRespinAni()
    self:runCsbAction("start",false,function ()
        -- self:runCsbAction("idle")
    end)
    local tempBonus = {}
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_trigger_bonus)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(node) and node.p_symbolType then
                if self:isBonusType(node.p_symbolType) then
                    node:setVisible(false)
                    local newBonusSpine = self:getTempBonusForTrigger(node)
                    tempBonus[#tempBonus + 1] = newBonusSpine
                    util_spinePlay(newBonusSpine, "actionframe", false)
                end
            end
        end
    end

    self:delayCallBack(2,function ()
        self:runCsbAction("over")
        self:delayCallBack(0.5,function ()
            for i,v in ipairs(tempBonus) do
                if not tolua.isnull(v) then
                    v:removeFromParent()
                end
            end
            
            tempBonus = {}
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if not tolua.isnull(node) and self:isBonusType(node.p_symbolType) then
                        node:setVisible(true)
                        node:runAnim("idleframe2",true)
                    end
                end
            end
        end)
        
    end)
end

function CodeGameScreenTreasureToadMachine:initRespinAni()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow)
            if node and node.p_symbolType then
                if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                    node:runAnim("idleframe2_2",true)
                elseif node.p_symbolType == 90 then
                    self:changeBaseParent(node)
                end
            end
        end
    end
end

function CodeGameScreenTreasureToadMachine:showReSpinStart(func)
    local params = {
        endFunc = func,
    }
    local view = util_createView("CodeTreasureToadSrc.TreasureToadRespinStartView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view

end

---
-- 触发respin 玩法
--
function CodeGameScreenTreasureToadMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
    self:levelDeviceVibrate(6, "respin")
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

function CodeGameScreenTreasureToadMachine:showRespinView()
    
        --先播放动画 再进入respin
    self:clearCurMusicBg()

    local waitTime = 0.2
    if self.isRespin then
        waitTime = 2.7
        --触发动画
        self:triggerRespinAni()
    end
    
    self:checkChangeBaseParent()

    self:delayCallBack(waitTime,function ()
        self:showReSpinStart(
                function()
                    self:showGuochang(2,function ()
                        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                        else
                            --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
                            self.m_bottomUI:resetWinLabel()
                            self.m_bottomUI:notifyTopWinCoin()
                            self.m_bottomUI:checkClearWinLabel()
                        end
                        self:changeReSpinStartUI(self:getCurRespinCount())
                        --可随机的普通信息
                        local randomTypes = self:getRespinRandomTypes( )

                        --可随机的特殊信号 
                        local endTypes = self:getRespinLockTypes()
                        
                        --构造盘面数据
                        self:triggerReSpinCallFun(endTypes, randomTypes)
                        self:getRedDi():setVisible(true)
                        self.m_respinView:createRespinLine()
                        self.m_respinView:createMiddleKuang()
                    end,function ()
                        
                    end)
                end
            )
        
    end)
end

function CodeGameScreenTreasureToadMachine:initRespinView(endTypes, randomTypes)
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
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
            if self:isShowCollectForRespin() then
                --respin收集时对应位置的信号块变为底
                local bonusType = self:getSpecialBonusType()
                if bonusType then
                    self:delayCallBack(2,function ()
                        self:collectForRespin(bonusType,function ()
                            self.m_respinBar:updateRespinTotalCount(self.m_runSpinResultData.p_reSpinsTotalCount,true)
                            self:runNextReSpinReel()
                            self:clearAllChild()
                        end)
                    end)
                else
                    self:runNextReSpinReel()
                end
            else
                --继续  
                self:runNextReSpinReel()
            end
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end


---判断结算
function CodeGameScreenTreasureToadMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self:getCurRespinCount() == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()
        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self:getCurRespinCount())
    end
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    if self:isShowCollectForRespin() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        --respin收集时对应位置的信号块变为底
        local bonusType = self:getSpecialBonusType()
        if bonusType then
            self:delayCallBack(0.5,function ()
                self:collectForRespin(bonusType,function ()
                    self.m_respinBar:updateRespinTotalCount(self.m_runSpinResultData.p_reSpinsTotalCount,false)
                    
                    self:runNextReSpinReel()
                    self:clearAllChild()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                end)
            end)
            
        else
            
            self:runNextReSpinReel()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    else
        --继续  
        self:runNextReSpinReel()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end
    

    
end

--出现特殊图标，收集
function CodeGameScreenTreasureToadMachine:isShowCollectForRespin()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local beforeStoredIcons = rsExtraData.beforeStoredIcons or {}      --当中间位置有bonus时返回  收集bonus1之前显示的bonus数据

    if table_length(beforeStoredIcons) > 0 then
        return true
    end
    return false
end

--获取列表最后一个  为最新一个特殊bonus
function CodeGameScreenTreasureToadMachine:getSpecialBonusType()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local storedIcons = rsExtraData.storedIcons or {}
    local info = storedIcons[#storedIcons]
    if info and info[4] then
        if info[4] == "Bonus1" then
            return self.SYMBOL_FIX_SYMBOL1
        elseif info[4] == "Bonus2" then
            return self.SYMBOL_FIX_SYMBOL2
        end
    end
    return nil
end

--ReSpin开始改变UI状态
function CodeGameScreenTreasureToadMachine:changeReSpinStartUI(respinCount)
    self:showUIForIndex(CURRENT_NUM.INDEX_THREE)
    self:getRedDi():setVisible(false)
    --修改bonus时间线
    self:initRespinAni()
    self.m_respinBar:updateTotalTimes(self.m_runSpinResultData.p_reSpinsTotalCount)
    self.m_respinBar:setVisible(true)
    self.m_respinBar:runCsbAction("idleframe")
    self:changeReSpinUpdateUI(respinCount)
    
end

function CodeGameScreenTreasureToadMachine:getRedDi()
    return self:findChild("Sprite_red")
end

function CodeGameScreenTreasureToadMachine:getCurRespinCount()
    return self.m_runSpinResultData.p_reSpinCurCount or 0
end

--ReSpin刷新数量
function CodeGameScreenTreasureToadMachine:changeReSpinUpdateUI(curCount)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    curCount = totalCount - curCount
    self.m_respinBar:updateRespinCount(curCount,totalCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenTreasureToadMachine:changeReSpinOverUI()
    
    
end

function CodeGameScreenTreasureToadMachine:changeRespinOverCCbName( )
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow,SYMBOL_NODE_TAG)
            if symbol ~= nil and not self:isBonusType(symbol.p_symbolType) then
                local type = math.random(1,10)
                self:changeSymbolType(symbol,type)
            elseif symbol ~= nil and self:isBonusType(symbol.p_symbolType) then
                if symbol.p_symbolType == self.SYMBOL_FIX_SYMBOL2 then
                    symbol:runAnim("idleframe2_2",true)
                else
                    symbol:runAnim("idleframe2",true)
                end
                
            end
        end
    end
end

function CodeGameScreenTreasureToadMachine:respinOver()
    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    
    self:delayCallBack(0.2,function ()
        self:removeRespinNode()
    end)
    self:showRespinOverView()
end

function CodeGameScreenTreasureToadMachine:showRespinOverView(effectData)
    self:clearCurMusicBg()
    self:hideColorLayer(false)
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_reSpin_over_show)
    local view=self:showReSpinOver(strCoins,function()
        self:showGuochang2(4,function ()
            if self.m_bProduceSlots_InFreeSpin then
                self:showUIForIndex(CURRENT_NUM.INDEX_TWO)
            else
                self:showUIForIndex(CURRENT_NUM.INDEX_ONE)
            end
            self.isRespin = true
            self.isRespinOver = true
            self.m_winnerBar:setVisible(false)
            self:changeRespinOverCCbName()
        end,function ()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self.m_isRespinOver = true
            --bonus计数
            self.bonusNum1 = 0  --金蝉
            self.bonusNum2 = 0  --聚宝盆
            self.bonusNum3 = 0  --金币
            self:resetMusicBg() 
        end)

    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},595)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenTreasureToadMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = self:showDialog("RespinOver", ownerlist, func, nil, index)
    local jvese = util_spineCreate("Socre_TreasureToad_Bonus2",true,true)
    local bottonSg = util_spineCreate("TreasureToad_anniu_sg",true,true)
    local ziSg = util_spineCreate("TreasureToad_zi_sg",true,true)
    local lighting = util_createAnimation("Socre_TreasureToad_bg_guang.csb") 
    util_spinePlay(jvese, "idleframe3",true)
    util_spinePlay(bottonSg, "idle2",true)
    util_spinePlay(ziSg, "idle1",true)
    lighting:runCsbAction("idleframe",true)
    view:findChild("Node_juese"):addChild(jvese)
    view:findChild("Node_sg1"):addChild(ziSg)
    view:findChild("Node_sg2"):addChild(bottonSg)
    view:findChild("Node_guang"):addChild(lighting) 
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_reSpin_over_hide)
    end)
    return view
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end


-- --重写组织respinData信息
function CodeGameScreenTreasureToadMachine:getRespinSpinData()
    local storedIcons = {}
    if self:getCurrSpinMode() == RESPIN_MODE then
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
        storedIcons = rsExtraData.storedIcons or {}      
        if self:isShowCollectForRespin() then
            storedIcons = rsExtraData.beforeStoredIcons or {}
        end
    else
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        storedIcons = selfData.storedIcons or {}      
        if self:isShowCollectForRespin() then
            storedIcons = rsExtraData.beforeStoredIcons or {}
        end
    end
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
function CodeGameScreenTreasureToadMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end


function CodeGameScreenTreasureToadMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.music_TreasureToad_enter)

    end,0.4,self:getModuleName())
end

function CodeGameScreenTreasureToadMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self:checkUpateDefaultBet()
    self:initTopCommonJackpotBar()
    self:updataJackpotStatus()

    CodeGameScreenTreasureToadMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    -- self:upateBetLevel(true)

    local hasFeature = self:checkHasFeature()
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not hasFeature then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_ONENTER)
    end
end

function CodeGameScreenTreasureToadMachine:addObservers()
	CodeGameScreenTreasureToadMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end
        if self.isRespinOver then
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
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = self.m_publicConfig.SoundConfig["sound_TreasureToad_win_line_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = self.m_publicConfig.SoundConfig["sound_TreasureToad_fs_win_line_"..soundIndex] 
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        -- self:upateBetLevel(false)
        self:updataJackpotStatus(params)
    end,ViewEventType.NOTIFY_BET_CHANGE)

    --公共jackpot活动结束
    gLobalNoticManager:addObserver(self,function(target, params)

        if params.name == ACTIVITY_REF.CommonJackpot then
            self.m_isJackpotEnd = true
            -- self:upateBetLevel(false)
            self:updataJackpotStatus()
        end

    end,ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)

    gLobalNoticManager:addObserver(self,function(self,params)
        -- self:unlockHigherBet()
    end,"SHOW_BONUS_MAP")
end

function CodeGameScreenTreasureToadMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTreasureToadMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_respinScheduleId ~= nil then
        scheduler.unscheduleGlobal(self.m_respinScheduleId)
        self.m_respinScheduleId = nil
    end

    if self.m_soundGlobalId ~= nil then
        scheduler.unscheduleGlobal(self.m_soundGlobalId)
        self.m_soundGlobalId = nil
    end

    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearTitleNode()
    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearEntryNode()
end

-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenTreasureToadMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local storedIcons = selfData.storedIcons or {}      --需要收集的bonus
    --{{0, "1", 100000, "Normal"}}
    local dropStoredIcons = selfData.dropStoredIcons or {}      --随机掉落的bonus
    local dropReels = selfData.dropReels or {}          --掉落后棋盘的数据
    if self:checkTreasureToadABTest() then      --AB组
        if storedIcons and table_length(storedIcons) > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
        end

        if dropStoredIcons and table_length(dropStoredIcons) > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.DROP_BONUS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.DROP_BONUS_EFFECT -- 动画类型
        end
    end
end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTreasureToadMachine:MachineRule_playSelfEffect(effectData)

    if self:checkTreasureToadABTest() then    --AB组
        if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
            self:showCollectBonusEffect(function ()
                if effectData then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end)
            
        end
        if effectData.p_selfEffectType == self.DROP_BONUS_EFFECT then
            self:vomitBonusEffect(function ()
                if effectData then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end)
        end
    end
    
    
	return true
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenTreasureToadMachine:operaEffectOver()
    CodeGameScreenTreasureToadMachine.super.operaEffectOver(self)

    if self.m_isRespinOver then
        self.m_isRespinOver = false
        --公共jackpot
        local midReel = self:findChild("sp_reel_2")
        local size = midReel:getContentSize()
        local worldPos = util_convertToNodeSpace(midReel,self)
        worldPos.x = worldPos.x + size.width / 2
        worldPos.y = worldPos.y + size.height / 2
        if G_GetMgr(ACTIVITY_REF.CommonJackpot) then
            G_GetMgr(ACTIVITY_REF.CommonJackpot):playEntryFlyAction(worldPos,function()

            end)
        end
    end
end

function CodeGameScreenTreasureToadMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()

    local isFiveOfKind = self:lineLogicWinLines()

    -- if isFiveOfKind then
    --     self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    -- end

    -- 根据features 添加具体玩法
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end


function CodeGameScreenTreasureToadMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenTreasureToadMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenTreasureToadMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == self.SYMBOL_FIX_SYMBOL and node.m_currAnimName == "idleframe3" then
                    node:runAnim("idleframe2", true)
                elseif node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and node.m_currAnimName == "idleframe3" then--只有播期待动画的图标播idle
                    node:runAnim("idleframe2", true)
                end
            end
        end
    end
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self:hideColorLayer(false)
    end
    
    CodeGameScreenTreasureToadMachine.super.slotReelDown(self)
end

function CodeGameScreenTreasureToadMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenTreasureToadMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenTreasureToadMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if self:checkSymbolBulingAnimPlay(_slotNode) then
                    if symbolCfg[1] then
                        --不能直接使用提层后的坐标不然没法回弹了
                        local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                        util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                        _slotNode:setPositionY(curPos.y)
    
                        --连线坐标
                        local linePos = {}
                        linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                        _slotNode.m_bInLine = true
                        _slotNode:setLinePos(linePos)
    
                        --回弹
                        local newSpeedActionTable = {}
                        for i = 1, #speedActionTable do
                            if i == #speedActionTable then
                                -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                                local resTime = self.m_configData.p_reelResTime
                                local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                                local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                                newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                            else
                                newSpeedActionTable[i] = speedActionTable[i]
                            end
                        end
    
                        local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                        _slotNode:runAction(actSequenceClone)
                    end
                end
                
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --ABtest
                local bulingName = symbolCfg[2]
                if not self:checkTreasureToadABTest() and _slotNode.p_symbolType == 94 then
                    bulingName = "buling1"
                end
                _slotNode:runAnim(
                bulingName,
                false,
                function()
                    self:symbolBulingEndCallBack(_slotNode)
                end
                )
            end
        end
    end
end


function CodeGameScreenTreasureToadMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode then
        if self:isBonusType(_slotNode.p_symbolType) then
            _slotNode:runAnim("idleframe2",true)
        elseif _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self.m_isLongRun and _slotNode.p_cloumnIndex < self.m_iReelColumnNum then
                if _slotNode.m_currAnimName ~= "idleframe3" then
                    _slotNode:runAnim("idleframe3",true)
                end
                
            else
                _slotNode:runAnim("idleframe2",true)
            end
        end
    end
    
end

--播放预告中奖概率
function CodeGameScreenTreasureToadMachine:getFeatureGameTipChance()
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为30%
        local isNotice = (math.random(1, 100) <= 40) 
        return isNotice
    end

    
    return false
end

-- 播放预告中奖统一接口
function CodeGameScreenTreasureToadMachine:showFeatureGameTip(_func)
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then

        -- 出现预告动画
        local isNotice = self:getFeatureGameTipChance()
       
        if isNotice then
            --播放预告中奖动画
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TreasureToad_yugao)
            self:playFeatureNoticeAni(function()
                if type(_func) == "function" then
                    _func()
                end
            end)
        else
            if type(_func) == "function" then
                _func()
            end
        end
    else
        if type(_func) == "function" then
            _func()
        end
    end
end

function CodeGameScreenTreasureToadMachine:showParticle(isShow)
    local particle1 = self:findChild("Particle_you1")
    local particle2 = self:findChild("Particle_you2")
    local particle3 = self:findChild("Particle_zuo1")
    local particle4 = self:findChild("Particle_zuo2")
    local particle5 = self:findChild("Particle_shang1")
    local particle6 = self:findChild("Particle_shang2")
    local particle7 = self:findChild("Particle_xia1")
    local particle8 = self:findChild("Particle_xia2")
    if isShow then
        particle1:resetSystem()
        particle2:resetSystem()
        particle3:resetSystem()
        particle4:resetSystem()
        particle5:resetSystem()
        particle6:resetSystem()
        particle7:resetSystem()
        particle8:resetSystem()
    else
        particle1:stopSystem()
        particle2:stopSystem()
        particle3:stopSystem()
        particle4:stopSystem()
        particle5:stopSystem()
        particle6:stopSystem()
        particle7:stopSystem()
        particle8:stopSystem()
    end
    
end

--[[
    播放预告中奖动画
    预告中奖通用规范
    命名:关卡名+_yugao
    时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
    挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
]]
function CodeGameScreenTreasureToadMachine:playFeatureNoticeAni(func)
    --动效执行时间
    local aniTime = 0
    --获取父节点
    self:findChild("Node_yugao"):setVisible(true)
    self:showParticle(true)
    local parentNode = self:findChild("jinbi")
    if not parentNode then
        parentNode = self:findChild("root")
    end

    --检测是否存在预告中奖资源
    local aniName = "TreasureToad_yugao"

    self.b_gameTipFlag = true
    --创建对应格式的spine
    local spineAni = util_spineCreate(aniName,true,true)
    if parentNode then
        parentNode:addChild(spineAni)
        util_spinePlay(spineAni,"actionframe")
        self:runCsbAction("actionframe")
        util_shakeNode(self:findChild("QiPan"),7,7,2)
        util_shakeNode(self:findChild("Node_reel"),7,7,2)
        util_shakeNode(self:findChild("Node_yugao"),7,7,2)
        util_spineEndCallFunc(spineAni,"actionframe",function()
            self:showParticle(false)
            self:delayCallBack(0.5,function ()
                self:findChild("Node_yugao"):setVisible(false)
            end)
            spineAni:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            self:delayCallBack(0.1,function()
                spineAni:removeFromParent()
            end)
            
        end)
        aniTime = spineAni:getAnimationDurationTime("actionframe")
    end
    
    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenTreasureToadMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = 15
        local posX = 27
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
        self.m_bottomUI.m_bigWinLabCsb:setPositionX(posX)
    end
    
    local a = self.m_bottomUI.m_bigWinLabCsb:getPositionX()
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1,
        animName   = "actionframe3",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenTreasureToadMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bigWin_yugao)
    self.bigWinEffect:setVisible(true)
    util_spinePlay(self.bigWinEffect, "actionframe")
    local aniTime = 100/30
    util_shakeNode(self:findChild("QiPan"),7,7,aniTime)
    util_shakeNode(self:findChild("Node_reel"),7,7,aniTime)
    util_shakeNode(self:findChild("Node_yugao"),7,7,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenTreasureToadMachine:showGuoChangSound(index)
    if index == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bgToFg_guochang)
    elseif index == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bgToRg_guochang)
    elseif index == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_fgToBg_guochang)
    elseif index == 4 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_rgToBg_guochang)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_rgToBg_guochang)
    end
end

--[[
    过场动画
]]
function CodeGameScreenTreasureToadMachine:showGuochang(index,func1,func2)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    
    self:delayCallBack(0.5,function ()
        self.noClickLayer:setVisible(true)
        self.m_spineGuochang:setVisible(true)
        self:showGuoChangSound(index)
        util_spinePlay(self.m_spineGuochang, "actionframe_guochang")
        util_spineEndCallFunc(self.m_spineGuochang, "actionframe_guochang", function ()
            self.noClickLayer:setVisible(false)
            self.m_spineGuochang:setVisible(false)
        end)
        self:delayCallBack(60/30,function ()
            if type(func1) == "function" then
                func1()
            end
        end)
        self:delayCallBack(95 / 30, function ()
            if type(func2) == "function" then
                func2()
            end
        end)
            
    end)
    
end

--[[
    过场动画
]]
function CodeGameScreenTreasureToadMachine:showGuochang2(index,func1,func2)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:showGuoChangSound(index)
    self.noClickLayer:setVisible(true)
    self.m_spineGuochang2:setVisible(true)
    util_spinePlay(self.m_spineGuochang2, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang2, "actionframe_guochang", function ()
        self.noClickLayer:setVisible(false)
        self.m_spineGuochang2:setVisible(false)
        if type(func2) == "function" then
            func2()
        end
    end)
    util_spineFrameCallFunc(self.m_spineGuochang2,"actionframe_guochang","qp", function()
        if type(func1) == "function" then
            func1()
        end
    end)
    
end

--初始化收集的数据（gameConf+ig里存对应bet的收集列表）
function CodeGameScreenTreasureToadMachine:initGameStatusData( gameData )
    CodeGameScreenTreasureToadMachine.super.initGameStatusData(self,gameData)
    self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    
end

function CodeGameScreenTreasureToadMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenTreasureToadMachine:upateBetLevel(isInit)
    local minBet = self:getMinBet( )
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarLock( isInit,minBet ) 
    else
        self.m_betLevel = 1
    end
    
end

function CodeGameScreenTreasureToadMachine:unlockHigherBet()
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
    if betCoin >= self:getMinBet() then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
        if bets.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = bets.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenTreasureToadMachine:updateJackpotBarLock( isInit,minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
            -- 解锁jackpot
            self.m_jackPotBar:showLockAct(isInit,false)
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            -- 锁定jackpot
            self.m_jackPotBar:showLockAct(isInit,true)
        end
        
    end 
end

function CodeGameScreenTreasureToadMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()

    self.m_iBetLevel = 1
    
    self:setSpecialSpinStates(false )

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenTreasureToadMachine:MachineRule_ResetReelRunData()
    CodeGameScreenTreasureToadMachine.super.MachineRule_ResetReelRunData(self)
end

-- 显示paytableview 界面
function CodeGameScreenTreasureToadMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    view:findChild("Node_3"):setScale(self.m_machineRootScale)
    if view then
        view:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                gLobalViewManager:viewResume(
                    function()
                        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
                    end
                )
            end
        )
    end
end

function CodeGameScreenTreasureToadMachine:scaleMainLayer()
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
    local ratio = display.height / display.width
    if ratio <= 2176 / 1800 then
        self:findChild("bg"):setScale(1.2)
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            local changeY = 33
            if ratio < 1152/768 and ratio > 920/768 then
                mainScale = mainScale + 0.09 * (ratio - 920/768)
                self:findChild("bg"):setScale(1.2)
            elseif ratio <= 920/768 then    --兼顾公共jackpot，920下的缩放在initTopCommonJackpotBar下重新做了调整
                mainScale = mainScale + 0.06
                changeY = 45
            end
            -- mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(mainPosY + changeY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

-- function CodeGameScreenTreasureToadMachine:scaleMainLayer()
--     CodeGameScreenTreasureToadMachine.super.scaleMainLayer(self)
--     local ratio = display.height / display.width
--     local mainScale = self.m_machineRootScale
--     local mainPosY = 0
--     if  ratio >= 1370/768 or (ratio < 1370/768 and ratio > 1228/768) then
--         mainScale = mainScale
--     elseif ratio <= 1228/768 and ratio > 1152/768 then
--         mainPosY = 5
--         mainScale = mainScale + 0.3*(ratio - 1152/768)
--     elseif ratio <= 1152/768 and ratio > 920/768 then       --0.81
--         mainPosY = 10
--         mainScale = mainScale + 0.15 * (ratio - 920/768)

--     elseif ratio <= 920/768 then        --0.61
--         mainPosY = 20
--         mainScale = mainScale + 0.09
--         self:findChild("bg"):setScale(1.2)
--     end
--     if ratio <= 2176 / 1800 then
--         self:findChild("bg"):setScale(1.2)
--     end
--     self.m_machineRootScale = mainScale
--     util_csbScale(self.m_machineNode, mainScale)
--     self.m_machineNode:setPositionY(mainPosY)
--     self:findChild("root"):setPosition(display.center)
-- end

function CodeGameScreenTreasureToadMachine:getSoundPathForScatterNum()
    local path = nil
    if self.scatterNum == 1 then
        path = PublicConfig.SoundConfig.sound_TreasureToad_scatter_buling_1
    elseif self.scatterNum == 2 then
        path = PublicConfig.SoundConfig.sound_TreasureToad_scatter_buling_2
    else
        path = PublicConfig.SoundConfig.sound_TreasureToad_scatter_buling_3
    end
    return path
end

function CodeGameScreenTreasureToadMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            local iCol = _slotNode.p_cloumnIndex
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.scatterNum = self.scatterNum + 1
                local soundPath = self:getSoundPathForScatterNum()
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                end
            else
                if symbolCfg then
                    
                    local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                    if soundPath then
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
            
        end
    end
end

--[[
    延迟回调
]]
function CodeGameScreenTreasureToadMachine:delayCallBack(time, func)
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

-------------------------------------收集
--[[
    @desc: 轮盘转出来的 金币bonus列表  位置0-14, 倍数, 金币数, 类型(对应jackpot或普通倍数)
    author:{author}
    time:2023-05-05 18:10:14
    --@func: 
    @return:
]]
function CodeGameScreenTreasureToadMachine:showCollectBonusEffect(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local storedIcons = selfData.storedIcons or {}      --需要收集的bonus
    local dropStoredIcons = selfData.dropStoredIcons or {}
    local features = self.m_runSpinResultData.p_features or {}
    local waitTime = 0
    if table_length(dropStoredIcons) > 0 or (#features >= 2 and features[2] > 0) then
        waitTime = 1
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bonus_collect)
    self:delayCallBack(12/30,function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bonus_collectFankui)
    end)
    for i,info in ipairs(storedIcons) do
        self:flyCollectBonusAct(info)
    end
    self:delayCallBack(waitTime,function ()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenTreasureToadMachine:flyCollectBonusAct(info)
    local bonusSpine = util_spineCreate("Socre_TreasureToad_Bonusb", true, true)
    local index = info[1]
    local symbol = self:getSymbolByPosIndex(index)
    local startPos = util_convertToNodeSpace(symbol,self.m_effect)
    local endPos = util_convertToNodeSpace(self:findChild("Node_role"),self.m_effect)
    local newPos = cc.p(endPos.x,endPos.y + 110)
    self.m_effect:addChild(bonusSpine)
    bonusSpine:setPosition(startPos)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local actName = self:getCollectActName()
        util_spinePlay(bonusSpine,actName)
        self:delayCallBack(12/30,function ()
            util_spinePlay(self.bigRole, "actionframe")
            util_spineEndCallFunc(self.bigRole, "actionframe",function ()
                util_spinePlay(self.bigRole, "idleframe2",true)
            end)
            
        end)
    end)
    actList[#actList + 1] = cc.EaseSineIn:create(cc.MoveTo:create(16/30,newPos))
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        bonusSpine:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    bonusSpine:runAction(sq)
end

function CodeGameScreenTreasureToadMachine:getCollectActName()
    local actName = {
        "shouji",
        "shouji2",
        "shouji3"
    }
    local randNum = math.random(1,3)
    local name = actName[randNum]
    if name then
        return name
    else
        return "shouji"
    end
end

-------------------------------------随机添加
--[[
    @desc: 轮盘转出来的 金币bonus列表  位置0-14, 倍数, 金币数, 类型(对应jackpot或普通倍数)
    author:{author}
    time:2023-05-05 18:10:14
    --@func: 
    @return:
]]
function CodeGameScreenTreasureToadMachine:vomitBonusEffect(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --{{4, "1", 100000, "Normal"}}      --测试
    local dropStoredIcons = selfData.dropStoredIcons or {}      --添加bonus的列表
    local dropReels = selfData.dropReels or {}                            --掉落后轮盘数据
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_vomit_gold)
    for i,info in ipairs(dropStoredIcons) do
        self:flyVomitBonusAct(info)
    end
    --p_reels 变为 dropReels,否则在触发的时候会构建不出小块
    if table_length(dropReels) > 0 then
        self.m_runSpinResultData.p_reels = dropReels
    end
    self:delayCallBack(2,function ()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenTreasureToadMachine:flyVomitBonusAct(info)
    local bonusSpine = util_spineCreate("Socre_TreasureToad_Bonusb", true, true)
    local index = info[1]
    local symbol = self:getSymbolByPosIndex(index)
    local endPos = util_convertToNodeSpace(symbol,self.m_effect)
    
    local pos = util_convertToNodeSpace(self:findChild("Node_role"),self.m_effect)
    local startPos = cc.p(pos.x,pos.y + 160)
    local middlePosX = math.abs((pos.x - endPos.x)/2)
    local endPos1 = cc.p(endPos.x + middlePosX,pos.y + 300)
    if startPos.x < endPos.x then
        endPos1 = cc.p(endPos.x - middlePosX,pos.y + 300)
    end
    
    local symbolZorder = symbol:getLocalZOrder()
    self.m_effect:addChild(bonusSpine,symbolZorder)
    bonusSpine:setPosition(startPos)
    bonusSpine:setVisible(false)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        util_spinePlay(self.bigRole, "actionframe3")
        util_spineEndCallFunc(self.bigRole, "actionframe3",function ()
            util_spinePlay(self.bigRole, "idleframe2",true)
        end)
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(8/30)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        bonusSpine:setVisible(true)
        util_spinePlay(bonusSpine, "fly")
        
    end)
    local move1 = cc.EaseSineOut:create(cc.BezierTo:create(6/30,{cc.p(startPos.x-10 , startPos.y), cc.p(startPos.x - 10, endPos1.y), endPos1}))
    local move2 = cc.EaseSineIn:create(cc.MoveTo:create(10/30,endPos))
    if startPos.x < endPos.x then
        move1 = cc.EaseSineOut:create(cc.BezierTo:create(6/30,{cc.p(startPos.x+10 , startPos.y), cc.p(startPos.x + 10, endPos1.y), endPos1}))
    end
    --两段飞行
    actList[#actList + 1] = move1
    
    actList[#actList + 1] = move2
    
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        self:changeSymbolType(symbol, 94)
        local curPos = util_convertToNodeSpace(symbol, self.m_clipParent)
        util_setSymbolToClipReel(self, symbol.p_cloumnIndex, symbol.p_rowIndex, symbol.p_symbolType, 0)
        symbol:setPositionY(curPos.y)
        self:addLevelBonusSpine(symbol,tonumber(info[3]),info[4])
        symbol:runAnim("actionframe2")
        bonusSpine:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    bonusSpine:runAction(sq)
end

-----------------------respin收集
function CodeGameScreenTreasureToadMachine:collectForRespin(type,func)
    self.moveNum = self:getGoldNum(type)
    self.moveTotalNum = self:getGoldNum(type)
    self.tempRoleCoins = 0
    self.beforeTempCoins = 0
    local tempList = self:setSymbolIndex(type)
    self:createDarkBgForReSpin(type)
    self:createMiddleRoleForReSpin(type)
    self:createMiddleRoleStr()
    self:createGoldsForRespin(type,tempList)
    self:hideAllCleaningNode(type)
    self:initRespinSymbolPos(type)
    self:delayCallBack(31/60,function ()
        self:updateBonusPos(type,func)
    end)
end

function CodeGameScreenTreasureToadMachine:setSymbolIndex(type)
    local tempList = {}
    --获取respin固定金币
    local lockReSpinNodes = self.m_respinView:getAllCleaningNode()
    for i,lockNode in ipairs(lockReSpinNodes) do
        local iCol = lockNode.p_cloumnIndex
        local iRow = lockNode.p_rowIndex  
        if type == self.SYMBOL_FIX_SYMBOL1 then     --特殊1时，1和2除外的参加收集
            if lockNode.p_symbolType and (lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL1) then
                tempList[#tempList + 1] = {iCol = iCol,iRow = iRow}
            end
        else --特殊2时，2除外的参加收集
            if lockNode.p_symbolType and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 then
                tempList[#tempList + 1] = {iCol = iCol,iRow = iRow}
            end
        end
    end 
    return tempList
end

function CodeGameScreenTreasureToadMachine:createDarkBgForReSpin(type)
    local path = "TreasureToad/Respin11.csb"
    if type == self.SYMBOL_FIX_SYMBOL2 then
        path = "TreasureToad/Respin21.csb"
    end
    self.darkBg = util_createAnimation(path) 
    local lighting = util_createAnimation("Socre_TreasureToad_bg_guang.csb") 
    self.darkBg:findChild("Node_guang"):addChild(lighting) 
    self.darkBg.lighting = lighting
    lighting:runCsbAction("idleframe",true)
    self.m_effectRespin:addChild(self.darkBg,RESPIN_EFFECT.MIN_DOWN_TIER)
    self.darkBg:runCsbAction("start",false,function ()
        self.darkBg:runCsbAction("idle",true)
    end)
end

function CodeGameScreenTreasureToadMachine:createMiddleRoleStr()
    local cocosName = "Socre_TreasureToad_Respin_zi.csb"
    self.middleRoleStr = util_createAnimation(cocosName)
    self.middleRoleStr:findChild("m_lb_coins"):setString("")
    self:updateLabelSize({label=self.middleRoleStr:findChild("m_lb_coins"),sx=1,sy=1}, 290)
    local endPos = util_convertToNodeSpace(self:findChild("RespinBg"),self.m_effectRespin)
    self.m_effectRespin:addChild(self.middleRoleStr,RESPIN_EFFECT.MAX_UP_TIER)
    self.middleRoleStr:setPosition(cc.p(endPos.x,endPos.y - 127))
end

function CodeGameScreenTreasureToadMachine:createMiddleRoleForReSpin(type)
    --创建一个特殊bonus，播fly，,放大-移动到固定位置
    self.tempRole = util_spineCreate("Socre_TreasureToad_Bonus1", true, true)
    local nodeType = "Bonus1"
    local actName = "idleframe2_2"
    if type == self.SYMBOL_FIX_SYMBOL2 then
        self.tempRole = util_spineCreate("Socre_TreasureToad_Bonus2", true, true)
        nodeType = "Bonus2"
        actName = "idleframe4"
    end
    self:addLevelTempBonusRole(self.tempRole,"",nodeType,true)
    local respinNode = self.m_respinView:getRespinNode(2,3)
    
    local pos = util_convertToNodeSpace(respinNode,self.m_effectRespin)
    self.m_effectRespin:addChild(self.tempRole,RESPIN_EFFECT.MIDDLE_TIER)
    self.tempRole:setPosition(pos)
    
    self.tempRole.isRole = true
    local endPos = util_convertToNodeSpace(self:findChild("RespinBg"),self.m_effectRespin)
    if type == self.SYMBOL_FIX_SYMBOL2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_scale_bonus2)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_scale_bonus1)
    end
    
    util_spinePlay(self.tempRole, "fly")
    util_spineEndCallFunc(self.tempRole, "fly",function ()
        util_spinePlay(self.tempRole, actName,true)
    end)
    --移动
    local move = cc.EaseOut:create(cc.MoveTo:create(15/30,endPos),1)
    local func = cc.CallFunc:create(function(  )
        
    end)
    local sq = cc.Sequence:create(move,func)
    self.tempRole:runAction(sq)
end

function CodeGameScreenTreasureToadMachine:getSymbolIndex(tempList,iRow,iCol)
    if table_length(tempList) <= 0 then
        return nil
    end
    for i,v in ipairs(tempList) do
        if iRow == v.iRow and iCol == v.iCol then
            return i
        end
    end
    return nil
end

function CodeGameScreenTreasureToadMachine:createGoldsForRespin(type,tempList)
    --获取respin固定金币
    local lockReSpinNodes = self.m_respinView:getAllCleaningNode()
    local lineBet = globalData.slotRunData:getCurTotalBet()
    for i,lockNode in ipairs(lockReSpinNodes) do
        local iCol = lockNode.p_cloumnIndex
        local iRow = lockNode.p_rowIndex  
        local index = self:getSymbolIndex(tempList,iRow,iCol)
        if type == self.SYMBOL_FIX_SYMBOL1 then     --特殊1时，1和2除外的参加收集
            if lockNode.p_symbolType and (lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL1) then
                local iCol = lockNode.p_cloumnIndex
                local iRow = lockNode.p_rowIndex  
                local pos = self:getPosReelIdx(iRow, iCol)
                local goldNode = util_spineCreate("Socre_TreasureToad_Bonusb", true, true)
                local goldScore,goldType = self:getGoldInfo(pos)
                self:addLevelTempBonusSpine(goldNode,goldScore,goldType,false)
                local goldPos = util_convertToNodeSpace(lockNode,self.m_effectRespin)
                self.m_effectRespin:addChild(goldNode,RESPIN_EFFECT.UP_TIER)
                goldNode:setPosition(goldPos)
                goldNode.isMove = true
                if index then
                    goldNode.index = index
                else
                    goldNode.index = i
                end
                goldNode.isStrong = false
                if tonumber(goldScore) >= lineBet * 5 or self:isJackpotType(goldType) then
                    goldNode.isStrong = true
                end
                goldNode.pos = pos
                goldNode.zoder = RESPIN_EFFECT.UP_TIER
                goldNode.p_type = lockNode.p_symbolType
                goldNode.isRole = false
            end
        else --特殊2时，2除外的参加收集
            if lockNode.p_symbolType and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 then
                local iCol = lockNode.p_cloumnIndex
                local iRow = lockNode.p_rowIndex  
                local pos = self:getPosReelIdx(iRow, iCol)
                local goldScore,goldType = self:getGoldInfo(pos)
                local goldNode = util_spineCreate("Socre_TreasureToad_Bonusb", true, true)
                if lockNode.p_symbolType == self.SYMBOL_FIX_SYMBOL1 then
                    goldNode = util_spineCreate("Socre_TreasureToad_Bonus1", true, true)
                    self:addLevelTempBonusSpine(goldNode,goldScore,goldType,true)
                else
                    self:addLevelTempBonusSpine(goldNode,goldScore,goldType,false)
                end
                local goldPos = util_convertToNodeSpace(lockNode,self.m_effectRespin)
                self.m_effectRespin:addChild(goldNode,RESPIN_EFFECT.UP_TIER)
                goldNode:setPosition(goldPos)
                goldNode.isMove = true
                if index then
                    goldNode.index = index
                else
                    goldNode.index = i
                end
                goldNode.isStrong = false
                if tonumber(goldScore) >= lineBet * 5 or self:isJackpotType(goldType) then
                    goldNode.isStrong = true
                end
                goldNode.pos = pos
                goldNode.zoder = RESPIN_EFFECT.UP_TIER
                goldNode.p_type = lockNode.p_symbolType
                goldNode.isRole = false
            end
        end
        
    end 
end

function CodeGameScreenTreasureToadMachine:initRespinSymbolPos(type)
    local children = self.m_effectRespin:getChildren()
    for k,_node in pairs(children) do
        --环绕的金币或宝箱
        if not tolua.isnull(_node) and _node.index then
            local endPos,endTier,angle = self:getGoldPosAndTier(type,_node.index)
            --设置层级
            if endTier == RESPIN_EFFECT.DOWN_TIER then
                if angle <= 90 then

                    endTier = endTier - (180 + angle)
                else
                    endTier = endTier + (180 + angle)

                end
            else
                endTier = endTier - (360 - angle)
            end
            _node:setLocalZOrder(endTier)
            _node.angle = angle
            if _node.p_type and _node.p_type == self.SYMBOL_FIX_SYMBOL1 then
                
            else
                util_spinePlay(_node, "fly2")
            end
            
            --移动
            _node:runAction(cc.EaseOut:create(cc.MoveTo:create(15/30,endPos),1))
        end
    end
end

function CodeGameScreenTreasureToadMachine:clearAllChild()
    local children = self.m_effectRespin:getChildren()
    for k,_node in pairs(children) do
        if not tolua.isnull(_node) then
            _node:removeFromParent()
        end
    end
end

--根据个数获取需要平均除的值
function CodeGameScreenTreasureToadMachine:setAveLongForNum()
    if self.moveTotalNum >= 6 then
        self.aveLong = 25
    else
        self.aveLong = 20 + (6 - self.moveTotalNum)*10
    end

end

--移动bonus
function CodeGameScreenTreasureToadMachine:updateBonusPos(type,func)
    if self.m_respinScheduleId ~= nil then
        scheduler.unscheduleGlobal(self.m_respinScheduleId)
        self.m_respinScheduleId = nil
    end
    if self.rotateSound then
        gLobalSoundManager:stopAudio(self.rotateSound)
        self.rotateSound = nil
    end
    self:setAveLongForNum()
    self.rotateSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_rotate_bonus2,true)
	self.m_respinScheduleId = scheduler.scheduleUpdateGlobal(function(  )
		if self.moveNum > 0 then
            self:setMoveBonusPos(type)
		else
            
            if self.m_respinScheduleId ~= nil then
                scheduler.unscheduleGlobal(self.m_respinScheduleId)
                self.m_respinScheduleId = nil
            end
            self:delayCallBack(1,function ()
                self:fadeOutRotateSound()
                self:collectOverEffect(func)
            end)

		end
	end)
end

function CodeGameScreenTreasureToadMachine:fadeOutRotateSound()
    if self.m_soundGlobalId ~= nil then
        scheduler.unscheduleGlobal(self.m_soundGlobalId)
        self.m_soundGlobalId = nil
    end
    local volume = gLobalSoundManager:getSoundVolume(self.rotateSound)
    self.m_soundGlobalId =
        scheduler.scheduleGlobal(
        function()
            

            if volume <= 0 then
                volume = 0
            end

            if volume <= 0 then
                if self.m_soundGlobalId ~= nil then
                    scheduler.unscheduleGlobal(self.m_soundGlobalId)
                    self.m_soundGlobalId = nil
                end
                if self.rotateSound then
                    gLobalSoundManager:stopAudio(self.rotateSound)
                    self.rotateSound = nil
                end
            else
                volume = volume - 0.1
                if self.rotateSound ~= nil then
                    gLobalSoundManager:setSoundVolumeByID(self.rotateSound, volume)
                end
            end
            
        end,
        0.1
    )
end

function CodeGameScreenTreasureToadMachine:setRoleStr()
    if not tolua.isnull(self.middleRoleStr)and self.middleRoleStr:findChild("m_lb_coins") then
        local waitTime = 10/60
        if self.bonusPause then
            self.middleRoleStr:runCsbAction("actionframe2")
        else
            self.middleRoleStr:runCsbAction("actionframe3")
        end
        
        self:delayCallBack(waitTime,function ()
            local addValue = self.tempRoleCoins - self.beforeTempCoins
            util_jumpNum(self.middleRoleStr:findChild("m_lb_coins"),self.beforeTempCoins,self.tempRoleCoins,addValue,0.1,{3},nil,nil,function ()
                self.beforeTempCoins = self.tempRoleCoins
            end,function ()
                self:updateLabelSize({label = self.middleRoleStr:findChild("m_lb_coins"),sx = 1,sy = 1},290)
            end)
        end)
        
    end
end

function CodeGameScreenTreasureToadMachine:collectOverEffect(func)
    self.isMoveCollect = false
    self:delayCallBack(0.5,function ()
        util_setCascadeOpacityEnabledRescursion(self.darkBg, true)
        util_setCascadeColorEnabledRescursion(self.darkBg, true)
        self.darkBg:runCsbAction("over",false,function ()
            self.darkBg:removeFromParent()
            self.darkBg = nil
        end)
        self:delayCallBack(20/60,function ()
            --获取特殊小块的信息
            local info = self:getSpecialBonusInfo()
            if table_length(info) <= 0 then
                if func then
                    func()
                end
                return
            end
            local index = info[1]
            local coins = info[3]
            local nodeType = info[4]
            local type = self.SYMBOL_FIX_SYMBOL1
            if nodeType == "Bonus2" then
                type = self.SYMBOL_FIX_SYMBOL2
            end
            local fixPos = self:getRowAndColByPos(index)
            local respinNode = self.m_respinView:getRespinNode(fixPos.iX,fixPos.iY)
            local endPos = util_convertToNodeSpace(respinNode,self.m_effectRespin)
            if not tolua.isnull(self.middleRoleStr) then
                self.middleRoleStr:setVisible(false)
            end
            if not tolua.isnull(self.tempRole) then
                local str = self.tempRole.m_csbNode
                if str and str:findChild("m_lb_coins") then
                    if self.tempRoleCoins == 0 then
                        str:findChild("m_lb_coins"):setString(util_formatCoins("", 3))
                        self:updateLabelSize({label = str:findChild("m_lb_coins"),sx = 1,sy = 1},290)
                    else
                        str:findChild("m_lb_coins"):setString(util_formatCoins(self.tempRoleCoins, 3))
                        self:updateLabelSize({label = str:findChild("m_lb_coins"),sx = 1,sy = 1},290)
                    end
                    
                end
                
            end
            local callFun1 = cc.CallFunc:create(function ()
                self:createAndShowEndLighting(endPos)
                if type == self.SYMBOL_FIX_SYMBOL2 then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_scaleS_bonus2)
                else
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_scaleS_bonus1)
                end
                
                util_spinePlay(self.tempRole, "fly2")
            end)
            local move = cc.MoveTo:create(10/30,endPos)
            local act_move = cc.Spawn:create(callFun1, move)
            local deyTime = cc.DelayTime:create(15/30)
            local callFun2 = cc.CallFunc:create(function ()
                if type == self.SYMBOL_FIX_SYMBOL2 then
                    --棋盘震动
                    util_shakeNode(self:findChild("root"),7,7,40/60)
                end
                self:changeRespinSymbolForType(type,index,coins,nodeType)
                self.tempRole:setVisible(false)
            end)
            local delayTime = cc.DelayTime:create(56/60)
            local callFun3 = cc.CallFunc:create(function ()
                self:delayCallBack(0.5,function ()
                    if func then
                        func()
                    end
                end)
          
            end)
            self.tempRole:runAction(cc.Sequence:create(act_move, callFun2,delayTime,callFun3))
        end)
    end)
    
    
end

function CodeGameScreenTreasureToadMachine:createAndShowEndLighting(endPos)
    local lighting = util_createAnimation("TreasureToad_Respin_sc.csb")
    self.m_effectRespin:addChild(lighting,RESPIN_EFFECT.MIN_DOWN_TIER - 1)
    lighting:setPosition(endPos)
    lighting:runCsbAction("actionframe",false,function ()
        if not tolua.isnull(lighting) then
            lighting:removeFromParent()
        end
    end)
    
end

function CodeGameScreenTreasureToadMachine:getBigRoleAct(index,type)
    if type == self.SYMBOL_FIX_SYMBOL2 then
        if index == 1 then
            return "actionframe2"
        else
            return "actionframe2_2"
        end
    else
        return "actionframe2"
    end
end

function CodeGameScreenTreasureToadMachine:setMoveBonusPos(type)
    local children = self.m_effectRespin:getChildren()
    --
    local  aveAngle = 360 / self.moveTotalNum
    if self.bonusPause then
        aveAngle = 0
    else
        if self.isMoveCollect then
            if self.moveTotalNum >= 6 then
                self.aveLong = 30
            else
                self.aveLong = 20 + (6 - self.moveTotalNum) * 10
            end
        end
        aveAngle = aveAngle / self.aveLong
    end
    
    for k,_node in pairs(children) do
        if not tolua.isnull(_node) and _node.index then
            local angle = _node.angle
            if _node.isMove then
                angle = angle - aveAngle
                angle = (angle + 360) % 360
                local posX = self:getPosXAtOval(angle)
                local posY = self:getPosYAtOval(angle)
                local tier = RESPIN_EFFECT.DOWN_TIER
                if angle >= 180 then
                    tier = RESPIN_EFFECT.UP_TIER
                end
                
                if posX >= OvalConfig.ellipseA then
                    if _node.index == 1 then        --当第一个金币再一次移动到右边位置时，开始收集
                        self.isMoveCollect = true
                    end
                end
                
                if self.isMoveCollect then
                    
                    if posX >= OvalConfig.ellipseA  then
                        _node:setLocalZOrder(RESPIN_EFFECT.UP_TIER)
                        _node.isMove = false
                        local waitTime = 6/30

                        if _node.isStrong then
                            self.bonusPause = true
                            waitTime = 40/30

                            if _node.p_type then
                                _node.isMove = false
                                local actName = self:getActName(_node.p_type,true)
                                util_setCascadeOpacityEnabledRescursion(_node, true)
                                util_setCascadeColorEnabledRescursion(_node, true)
                                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_special_bonus_collect)
                                self:scaleBigForRoot()
                                util_spinePlay(_node, actName)
                            end
                        else
                            if _node.p_type then
                                _node.isMove = false
                                local actName = self:getActName(_node.p_type,false)
                                util_setCascadeOpacityEnabledRescursion(_node, true)
                                util_setCascadeColorEnabledRescursion(_node, true)
                                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_collect_bonus1_to_bonus2)
                                util_spinePlay(_node, actName)
                            end
                        end
                        
                        self:delayCallBack(waitTime,function ()
                            if not tolua.isnull(_node) then
                                local coins = 0
                                local nodeType = "Normal"
                                if _node.pos then
                                    local coins,nodeType = self:getGoldInfo(_node.pos)
                                    self.tempRoleCoins = self.tempRoleCoins + coins
                                end
                                local actName = self:getBigRoleAct(_node.index,type)
                                util_spinePlay(self.tempRole, actName)
                                self:setRoleStr()
                            end
                            
                        end)
                        self:delayCallBack(waitTime + 5/30,function ()
                            if not tolua.isnull(_node) then
                                
                                _node:removeFromParent()
                                
                            end
                            
                        end)

                        if self.moveNum == 1 then
                            self:delayCallBack(waitTime,function ()
                                self.moveNum = self.moveNum - 1
                            end)
                        else
                            self.moveNum = self.moveNum - 1
                        end
                        
                    else
                        if tier == RESPIN_EFFECT.DOWN_TIER then
                            if angle <= 90 then
                                tier = tier - (180 + angle)
                            else
                                tier = tier + (180 + angle)
                            end
                        else
                            tier = tier - (360 - angle)
                        end
                        _node:setLocalZOrder(tier)
                        _node:setPosition(cc.p(posX,posY))
                        _node.angle = angle
                    end
                else
                    if tier == RESPIN_EFFECT.DOWN_TIER then
                        if angle <= 90 then
                            tier = tier - (180 + angle)
                        else
                            tier = tier + (180 + angle)
                        end
                    else
                        tier = tier - (360 - angle)
                    end
                    _node:setLocalZOrder(tier)
                    _node:setPosition(cc.p(posX,posY))
                    _node.angle = angle
                end
                
                
            end
        end   
    end
end

function CodeGameScreenTreasureToadMachine:getActName(type,isStrong)
    if type == self.SYMBOL_FIX_SYMBOL then
        if isStrong then
            return "actionframe_js4"
        else
            return "actionframe_js3"
        end
    elseif type == self.SYMBOL_FIX_SYMBOL1 then
        if isStrong then
            return "actionframe_js1"
        else
            return "actionframe_js2"
        end
    end
end

--将固定小块变为底
function CodeGameScreenTreasureToadMachine:hideAllCleaningNode(type)
    self.m_respinView:changeLockSymbolForSpecial()

    local lockReSpinNodes = self.m_respinView:getAllCleaningNode()
    for i,lockNode in ipairs(lockReSpinNodes) do
        if type == self.SYMBOL_FIX_SYMBOL1 then     --特殊1时，1和2除外的参加收集
            if lockNode.p_symbolType and (lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL1) then
                
                local iCol = lockNode.p_cloumnIndex
                local iRow = lockNode.p_rowIndex  
                local fixPos = {iX = iRow, iY = iCol}
                self.m_respinView:changeLockSymbol(fixPos)
            end
        else --特殊2时，2除外的参加收集
            if lockNode.p_symbolType and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 then
                local iCol = lockNode.p_cloumnIndex
                local iRow = lockNode.p_rowIndex  
                local fixPos = {iX = iRow, iY = iCol}
                self.m_respinView:changeLockSymbol(fixPos)
            end
        end
    end
end

--将收集完的特殊小块固定
function CodeGameScreenTreasureToadMachine:changeRespinSymbolForType(type,pos,store,nodeType)
    self.m_respinView:changeBlankSymbol(type,pos,store,nodeType)
end


--获取需要移动的个数
function CodeGameScreenTreasureToadMachine:getGoldNum(type)
    local num = 0
    --获取respin固定金币
    local lockReSpinNodes = self.m_respinView:getAllCleaningNode()
    for i,lockNode in ipairs(lockReSpinNodes) do
        if type == self.SYMBOL_FIX_SYMBOL1 then     --特殊1时，1和2除外的参加收集
            if lockNode.p_symbolType and (lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL1) then
                num = num + 1
            end
        else --特殊2时，2除外的参加收集
            if lockNode.p_symbolType and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 then
                num = num + 1
            end
        end
    end 
    return num
end

--获取初始化旋转金币的位置和层级
function CodeGameScreenTreasureToadMachine:getGoldPosAndTier(type,index)
    local  aveAngle = 360 / self.moveTotalNum
    local angle = ((index - 1) * aveAngle) - (aveAngle * (self.moveTotalNum - 4))
    if self.moveTotalNum <= 4 then
        local angle = ((index - 1) * aveAngle)
    end
    
    angle = (angle + 360) % 360
    local posX = self:getPosXAtOval(angle)
    local posY = self:getPosYAtOval(angle)

    local tier = RESPIN_EFFECT.DOWN_TIER


    if angle >= 180 then
        tier = RESPIN_EFFECT.UP_TIER
    end
    

    return cc.p(posX,posY),tier,angle
end



function CodeGameScreenTreasureToadMachine:getPosYAtOval(angle)
    return OvalConfig.ellipseB * math.sin(MATH_PIOVER2 * angle / 90);
end

function CodeGameScreenTreasureToadMachine:getPosXAtOval(angle)
    return OvalConfig.ellipseA * math.cos(MATH_PIOVER2 * angle / 90);
end

--获取金币信息
function CodeGameScreenTreasureToadMachine:getGoldInfo(index)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local beforeStoredIcons = rsExtraData.beforeStoredIcons or {}
    local score = nil
    local idNode = nil
    local nodeType = "Normal"

    for i=1, #beforeStoredIcons do
        local values = beforeStoredIcons[i]
        if values[1] == index then
            score = tonumber(values[3])
            idNode = values[1]
            nodeType = values[4]
        end
    end

    if score == nil then
       return 0 ,nodeType
    end

    return score,nodeType
end

function CodeGameScreenTreasureToadMachine:getSpecialBonusInfo()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local storedIcons = rsExtraData.storedIcons or {}
    if table_length(storedIcons) <= 0 then
        return {}
    end
    local info = storedIcons[#storedIcons]
    return info
end

--强结算界面放大
--分为三段
function CodeGameScreenTreasureToadMachine:scaleBigForRoot()
    self:findChild("Node_zong"):stopAllActions()
    local function actFunc()
        local scaleAct = cc.ScaleTo:create(25/30, 1.3)
        local moveAct = cc.EaseInOut:create(cc.MoveTo:create(25/30,cc.p(0,-150)),1)

        local scaleAct1 = cc.ScaleTo:create(15/30, 1.45)
        local moveAct1 = cc.MoveTo:create(15/30,cc.p(0,-200))

        local scaleAct2 = cc.ScaleTo:create(10/30, 1)
        local moveAct2 = cc.EaseInOut:create(cc.MoveTo:create(10/30,cc.p(0,0)),1)

        local act_move = cc.Spawn:create(scaleAct, moveAct)
        local act_move1 = cc.Spawn:create(scaleAct1, moveAct1)
        local act_move2 = cc.Spawn:create(scaleAct2, moveAct2)
        local func = cc.CallFunc:create(function ()
            self.bonusPause = false
        end)
        return cc.Sequence:create(act_move,act_move1,act_move2,func)
    end
    self:findChild("Node_zong"):runAction(actFunc())
end


--[[
    @desc: bonus小块和临时创建spine挂钱
    author:{author}
    time:2023-05-15 14:41:06
    --@_symbol:
	--@score:
	--@nodeType: 
    @return:
]]

--spine小块挂钱
function CodeGameScreenTreasureToadMachine:addLevelBonusSpine(_symbol,score,nodeType)
    local cocosName = "Socre_TreasureToad_Bonus_zi.csb"
    
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local hangingName = "kb"
    local lab = self:getLblCsbOnSymbol(_symbol,"Socre_TreasureToad_Bonus_zi.csb",hangingName)
    self:changeCoinsShow(lab,score,nodeType)
end

--特殊bonus小块
function CodeGameScreenTreasureToadMachine:addLevelBonusSpineForSpecial(_symbol,score,nodeType)
    local cocosName = "Socre_TreasureToad_Respin_zi.csb"
    
    local symbol_node = _symbol:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local hangingName = "shuzi"
    local lab = self:getLblCsbOnSymbol(_symbol,cocosName,hangingName)
    if score == 0 then
        score = ""
    end
    lab:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
    self:updateLabelSize({label=lab:findChild("m_lb_coins"),sx=1,sy=1}, 290)
    if self:checkTreasureToadABTest() then
        lab:runCsbAction("idleframe")
    else
        lab:runCsbAction("idleframe1")
    end
end

--临时创建spine挂钱
function CodeGameScreenTreasureToadMachine:addLevelTempBonusSpine(spineNode,score,nodeType,isBonusS)
    local cocosName = "Socre_TreasureToad_Bonus_zi.csb"
    local hangingName = "kb"
    local actName = "idleframe2_2"
    if isBonusS then
        cocosName = "Socre_TreasureToad_Respin_zi.csb"
        hangingName = "shuzi"
        actName = "idleframe2"
    end
    if spineNode.m_csbNode then
        util_spineRemoveSlotBindNode(spineNode,hangingName)
    end
    local coinsView = util_createAnimation(cocosName)
    
    if isBonusS then
        coinsView:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
        self:updateLabelSize({label=coinsView:findChild("m_lb_coins"),sx=1,sy=1}, 290)
        if self:checkTreasureToadABTest() then
        
            coinsView:runCsbAction("idleframe")
        else
            coinsView:runCsbAction("idleframe1")  
        end
    else
        self:changeCoinsShow(coinsView,score,nodeType)
        coinsView:runCsbAction("idleframe")
    end
    
    util_spinePushBindNode(spineNode,hangingName,coinsView)
    
    spineNode.m_csbNode = coinsView
    util_spinePlay(spineNode,actName,true)
end

--临时创建特殊spine挂钱
function CodeGameScreenTreasureToadMachine:addLevelTempBonusRole(spineNode,score,nodeType,isBonusS)
    local cocosName = "Socre_TreasureToad_Respin_zi.csb"
    local name = "shuzi"
    if spineNode.m_csbNode then
        util_spineRemoveSlotBindNode(spineNode,name)
    end
    local coinsView = util_createAnimation(cocosName)
    coinsView:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
    self:updateLabelSize({label=coinsView:findChild("m_lb_coins"),sx=1,sy=1}, 290)
    util_spinePushBindNode(spineNode,name,coinsView)
    spineNode.m_csbNode = coinsView
end

-------------------------------------------------公共jackpot-----------------------------------------------------------------------
---
-- 处理spin 返回结果
function CodeGameScreenTreasureToadMachine:spinResultCallFun(param)
    CodeGameScreenTreasureToadMachine.super.spinResultCallFun(self,param)
    self.m_jackPotBar:resetCurRefreshTime()
end
--[[
    更新公共jackpot状态
]]
function CodeGameScreenTreasureToadMachine:updataJackpotStatus(params)
    local totalBetID = globalData.slotRunData:getCurTotalBet()

    self.m_jackpot_status = "Normal" -- "Mega" "Super"
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarMegaShow()
        return
    end

    if self.m_isJackpotEnd then
        self:updateJackpotBarMegaShow()
        return
    end

    if not mgr:isDownloadRes() then
        self:updateJackpotBarMegaShow()
        return
    end
    
    local data = mgr:getRunningData()
    if not data or not next(data) then
        self:updateJackpotBarMegaShow()
        return
    end

    local levelData = data:getLevelDataByBet(totalBetID)
    local levelName = levelData.p_name
    self.m_jackpot_status = levelName
    self:updateJackpotBarMegaShow()
end

function CodeGameScreenTreasureToadMachine:updateJackpotBarMegaShow()
    self.m_jackPotBar:updateMegaShow()
end

function CodeGameScreenTreasureToadMachine:getCommonJackpotValue(_status, _addTimes)
    _addTimes = math.floor(_addTimes)
    local value     = 0
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if _status == "Mega" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Mega)
        end
    elseif _status == "Super" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Super)
        end
    end

    return value
end

--[[
    新增顶栏和按钮
]]
function CodeGameScreenTreasureToadMachine:initTopCommonJackpotBar()
    if not ACTIVITY_REF.CommonJackpot then
        return 
    end

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarMegaShow()
        return
    end

    local commonJackpotTitle = mgr:createTitleNode()

    if not commonJackpotTitle then
        return
    end
    self.m_commonJackpotTitle = commonJackpotTitle
    self:addChild(self.m_commonJackpotTitle, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local titlePos = util_getConvertNodePos(self.m_topUI:findChild("TopUI_down"), self)
    local topSpSize = self.m_commonJackpotTitle:findChild("sp_Jackpot1"):getContentSize()
    titlePos.y = titlePos.y - topSpSize.height*0.25
    self.m_commonJackpotTitle:setPosition(titlePos)
    self.m_commonJackpotTitle:setScale(globalData.topUIScale)

    --若走到這裡，說明創建成功了，那麼改變jackpot的父節點，将jackpot下移动
    if display.height <=  DESIGN_SIZE.height then
        if self.m_jackPotBar then
            util_changeNodeParent(self:findChild("jackpot_grand"),self.m_jackPotBar)
            if display.height < DESIGN_SIZE.height then
                local ratio = display.height / display.width
                local posY = self.m_machineNode:getPositionY()
                local mainScale = self.m_machineRootScale
                local changeY = 0
                if ratio <= 920/768 then
                    mainScale = mainScale - 0.03
                    changeY = 10
                    util_csbScale(self.m_machineNode, mainScale)
                    self.m_machineRootScale = mainScale
                    self.m_machineNode:setPositionY(posY - changeY)
                end
            end
            
        end
    end
    
    
end

-- ABTest 
function CodeGameScreenTreasureToadMachine:checkTreasureToadABTest()
    --
    return globalData.GameConfig:checkABtestGroupA("TreasureToad")
end

return CodeGameScreenTreasureToadMachine