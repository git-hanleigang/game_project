---
-- island li
-- 2019年1月26日
-- CodeGameScreenGoldieGrizzliesMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "GoldieGrizzliesPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenGoldieGrizzliesMachine = class("CodeGameScreenGoldieGrizzliesMachine", BaseNewReelMachine)

CodeGameScreenGoldieGrizzliesMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenGoldieGrizzliesMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenGoldieGrizzliesMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenGoldieGrizzliesMachine.SYMBOL_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3   --红
CodeGameScreenGoldieGrizzliesMachine.SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2   --蓝
CodeGameScreenGoldieGrizzliesMachine.SYMBOL_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1   --绿
CodeGameScreenGoldieGrizzliesMachine.SYMBOL_EMPTY = 999

CodeGameScreenGoldieGrizzliesMachine.COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集
CodeGameScreenGoldieGrizzliesMachine.EFFECT_BIG_WIN_LIGHT = GameEffect.EFFECT_SELF_EFFECT - 2 --   大赢光效

CodeGameScreenGoldieGrizzliesMachine.m_chipList = nil
CodeGameScreenGoldieGrizzliesMachine.m_playAnimIndex = 0
CodeGameScreenGoldieGrizzliesMachine.m_lightScore = 0

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenGoldieGrizzliesMachine:ctor()
    CodeGameScreenGoldieGrizzliesMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_publicConfig = PublicConfig
    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_lockScatters = {}
    self.m_scatter_down = {}
    self.m_bonus_down = {}
    self.m_collectBet = {1, 0.3, 0.1}

	--init
	self:initGame()
end

function CodeGameScreenGoldieGrizzliesMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("GoldieGrizzliesConfig.csv", "LevelGoldieGrizzliesConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenGoldieGrizzliesMachine:initRespinBar()
    local node_bar = self:findChild("Node_respinbar")
    self.m_respinBar = util_createView("CodeGoldieGrizzliesSrc.GoldieGrizzliesRespinBar",{machine = self})
    node_bar:addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)
end

function CodeGameScreenGoldieGrizzliesMachine:showRespinBar()
    self.m_respinBar:setVisible(true)
    self.m_respinBar:changeRespinByCount(self.m_runSpinResultData.p_reSpinCurCount)
end

function CodeGameScreenGoldieGrizzliesMachine:hideRespinBar()
    self.m_respinBar:setVisible(false)
end

function CodeGameScreenGoldieGrizzliesMachine:initGameStatusData(gameData)
    CodeGameScreenGoldieGrizzliesMachine.super.initGameStatusData(self, gameData)
    self.m_bonus_level = gameData.gameConfig.extra.bonusLevel
    self.m_start_credit = gameData.gameConfig.extra.start_credit or {}
    --读取额外参数
    local extra = gameData.gameConfig.extra
    if nil ~= extra then
        -- 假滚信号的倍数
        if nil ~= extra.collect_credit then
            self.m_collectBet = extra.collect_credit
        end
    end
    
end
--[[
    修改reel条背景
]]
function CodeGameScreenGoldieGrizzliesMachine:changeReelBg(lockType)
    self:findChild("Node_base_reel"):setVisible(lockType == -1)
    self:findChild("Node_respin_reel_red"):setVisible(lockType == self.SYMBOL_BONUS_1)
    self:findChild("Node_respin_reel_blue"):setVisible(lockType == self.SYMBOL_BONUS_2)
    self:findChild("Node_respin_reel_green"):setVisible(lockType == self.SYMBOL_BONUS_3)
    self:findChild("respin_fengexian_red"):setVisible(lockType == self.SYMBOL_BONUS_1)
    self:findChild("respin_fengexian_blue"):setVisible(lockType == self.SYMBOL_BONUS_2)
    self:findChild("respin_fengexian_green"):setVisible(lockType == self.SYMBOL_BONUS_3)
    self:findChild("respin_reeldi_red"):setVisible(lockType == self.SYMBOL_BONUS_1)
    self:findChild("respin_reeldi_blue"):setVisible(lockType == self.SYMBOL_BONUS_2)
    self:findChild("respin_reeldi_green"):setVisible(lockType == self.SYMBOL_BONUS_3)
end

--[[
    变更背景动画
]]
function CodeGameScreenGoldieGrizzliesMachine:changeBgAni(bgType)
    if bgType == "normal" then
        util_spinePlay(self.m_gameBg,"normal",true)
    else
        util_spinePlay(self.m_gameBg,"free",true)
    end
end

--[[
    初始化背景
]]
function CodeGameScreenGoldieGrizzliesMachine:initMachineBg()
    local gameBg = util_spineCreate("GameScreenGoldieGrizzliesBg",true,true)--util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end

    self.m_gameBg = gameBg

    self:changeBgAni("normal")
end

--绘制多个裁切区域
function CodeGameScreenGoldieGrizzliesMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
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

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(reelSize.width, reelSize.height)
            clipNode:setAnchorPoint(cc.p(0,0))
            --假函数
            clipNode.getClippingRegion = function()
                return {width = reelSize.width, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(reelSize.width, reelSize.height)
            clipNodeBig:setAnchorPoint(cc.p(0,0))
            --假函数
            clipNodeBig.getClippingRegion = function()
                return {width = reelSize.width, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
        end

        local slotParentNode = cc.Layer:create()
        slotParentNode:setContentSize(reelSize.width, reelSize.height)
        clipNode:addChild(slotParentNode)
        slotParentNode:setAnchorPoint(cc.p(0,0))
        clipNode:setPosition(util_convertToNodeSpace(reel,self.m_onceClipNode))
        clipNode:setTag(CLIP_NODE_TAG + i)

        local parentData = SlotParentData:new()
        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = 0--reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            slotParentNodeBig:setAnchorPoint(cc.p(0,0))
            clipNodeBig:setPosition(util_convertToNodeSpace(reel,self.m_onceClipNode))
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    self.m_reelSize = cc.size(slotW, slotH)

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

    -- 测试数据，看点击区域范围
    -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_touchSpinLayer:setBackGroundColorOpacity(0)
    -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    end
end

function CodeGameScreenGoldieGrizzliesMachine:checkOnceClipNode()
    if self.m_isOnceClipNode == false then
        return
    end
    local iColNum = self.m_iReelColumnNum
    local reel = self:findChild("sp_reel_0")
    local startX = reel:getPositionX()
    local startY = reel:getPositionY()
    local reelEnd = self:findChild("sp_reel_" .. (iColNum - 1))
    local endX = reelEnd:getPositionX()
    local endY = reelEnd:getPositionY()
    local reelSize = reelEnd:getContentSize()
    local scaleX = reelEnd:getScaleX()
    local scaleY = reelEnd:getScaleY()
    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY

    self.m_onceClipNode = ccui.Layout:create()
    self.m_onceClipNode:setAnchorPoint(cc.p(0, 0))
    self.m_onceClipNode:setTouchEnabled(false)
    self.m_onceClipNode:setSwallowTouches(false)

    local width = (endX - startX + reelSize.width)
    local size = CCSizeMake(width * 1.2,reelSize.height)
    self.m_onceClipNode:setPosition(cc.p(startX - width * 0.1,startY))
    self.m_onceClipNode:setContentSize(size)
    self.m_onceClipNode:setClippingEnabled(true)

    self.m_clipParent:addChild(self.m_onceClipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
end

--[[
    初始化黑色遮罩层
]]
function CodeGameScreenGoldieGrizzliesMachine:initLayerBlack()
    self.m_blackLayer = util_createAnimation("GoldieGrizzlies_dark.csb")
    self.m_blackLayer:setPosition(util_convertToNodeSpace(self.m_csbOwner["sp_reel_0"],self.m_onceClipNode))
    self.m_onceClipNode:addChild(self.m_blackLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 5000)

    -- self.m_blackLayer:runCsbAction("darkidle")
    self.m_blackLayer:setVisible(false)

    self.m_blackLayer_side = util_createAnimation("GoldieGrizzlies_dark_0.csb")
    self:findChild("spinyaan"):addChild(self.m_blackLayer_side)

    local pos1 = util_convertToNodeSpace(self:findChild("kuang3"),self.m_onceClipNode)
    local pos2 = util_convertToNodeSpace(self:findChild("kuang4"),self.m_onceClipNode)
    util_changeNodeParent(self.m_onceClipNode,self:findChild("kuang3"),SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 5001)
    util_changeNodeParent(self.m_onceClipNode,self:findChild("kuang4"),SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 5002)
    self:findChild("kuang3"):setPosition(pos1)
    self:findChild("kuang4"):setPosition(pos2)
end

--[[
    显示黑色遮罩
]]
function CodeGameScreenGoldieGrizzliesMachine:showLayerBlack()
    self.m_blackLayer:setVisible(true)
    self.m_blackLayer:stopAllActions()
    self.m_blackLayer:runCsbAction("dark")

    self.m_blackLayer_side:setVisible(true)
    self.m_blackLayer_side:stopAllActions()
    self.m_blackLayer_side:runCsbAction("dark")

    self.m_isHideDark = false
end

--[[
    隐藏黑色遮罩
]]
function CodeGameScreenGoldieGrizzliesMachine:hideLayerBlack()
    if self.m_isHideDark then
        return
    end
    self.m_isHideDark = true

    performWithDelay(self.m_blackLayer,function()
        self.m_blackLayer:setVisible(false)
        self.m_blackLayer_side:setVisible(false)
    end,20 / 60)
    self.m_blackLayer:stopAllActions()
    self.m_blackLayer:runCsbAction("darkover",false)

    self.m_blackLayer_side:stopAllActions()
    self.m_blackLayer_side:runCsbAction("darkover",false)
end

function CodeGameScreenGoldieGrizzliesMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initFreeSpinBar() -- FreeSpinbar

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    self.m_effectNode:setScale(self.m_machineRootScale)

    --图标固定层
    self.m_lockNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_lockNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)

    --respinbarore
    self:initRespinBar()

    self.m_respinInfoBar = util_createAnimation("GoldieGrizzlies_respinjiesaolan.csb")
    self:findChild("Node_respinjiansaolan"):addChild(self.m_respinInfoBar)
    self.m_respinInfoBar:setVisible(false)



    --收集条
    self.m_collectBars = {}
    local color = {"red","blue","green"}
    for index = 1,#color do
        local barItem = util_createAnimation("GoldieGrizzlies_collection.csb")
        self:findChild("Node_collection_"..color[index]):addChild(barItem)
        self.m_collectBars[index] = barItem
        for iColor = 1,3 do
            barItem:findChild("wan_"..color[iColor]):setVisible(iColor == index)
            barItem:findChild("m_lb_coins_"..color[iColor]):setVisible(iColor == index)
        end

        local upAni = util_createAnimation("GoldieGrizzlies_collection_jiantou.csb")
        barItem:findChild("ef_jiantou"):addChild(upAni)
        barItem.m_upAni = upAni
        upAni:setVisible(false)

        --触发时播额外光效
        local light = util_createAnimation("GoldieGrizzlies_collection_chufa.csb")
        barItem:findChild("ef_chufa"):addChild(light)
        light:setVisible(false)

        barItem.m_light = light
    end

    --初始化黑色遮罩层
    self:initLayerBlack()
end



-- 断线重连 
function CodeGameScreenGoldieGrizzliesMachine:MachineRule_initGame(  )

    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGoldieGrizzliesMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "GoldieGrizzlies"  
end

-- 继承底层respinView
function CodeGameScreenGoldieGrizzliesMachine:getRespinView()
    return "CodeGoldieGrizzliesSrc.GoldieGrizzliesRespinView"
end
-- 继承底层respinNode
function CodeGameScreenGoldieGrizzliesMachine:getRespinNode()
    return "CodeGoldieGrizzliesSrc.GoldieGrizzliesRespinNode"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGoldieGrizzliesMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_GoldieGrizzlies_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_GoldieGrizzlies_11"
    end

    if  symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
        return "Socre_GoldieGrizzlies_Bonus"
    end

    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_GoldieGrizzlies_Empty"
    end

    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenGoldieGrizzliesMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    -- local storedIcons = self.m_runSpinResultData.p_selfMakeData.bonuspos or {}
    -- if next(self.m_runSpinResultData.p_storedIcons) and (self.m_runSpinResultData.p_reSpinCurCount > 0 or self:getCurrSpinMode() == RESPIN_MODE) then
    --     storedIcons = self.m_runSpinResultData.p_storedIcons
    -- end
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    if score == nil then
       return 0
    end

    return score
end

function CodeGameScreenGoldieGrizzliesMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if self:isFixSymbol(symbolType) then
        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
            local symbolIndex = 1 + (self.SYMBOL_BONUS_1 - symbolType)
            local multip = self.m_collectBet[symbolIndex]
            if multip == nil then
                multip = 1
            end
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = multip * lineBet
        else
            local selfData = self.m_runSpinResultData.p_selfMakeData
            score = selfData.respinCredit
        end
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenGoldieGrizzliesMachine:setSpecialNodeScore(symbolNode)
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


    local score = 0
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        --集满时分数为2倍分数,所以要先减少一半,执行完动效后恢复
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.full then
            score = score / 2
        end
    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    if symbolNode and symbolNode.p_symbolType then
        symbolNode.m_score = score
        if score ~= nil   then
            score = util_formatCoins(score, 3)

            local aniNode = symbolNode:checkLoadCCbNode()
            local spine = aniNode.m_spineNode
            local label = self:getLblOnBonusSymbol(symbolNode)
            if spine then
                self:updateLblCoinsOnBonus(symbolNode,label,score)

                if symbolNode.p_symbolType == self.SYMBOL_BONUS_1 then --红
                    spine:setSkin("hong")
                elseif symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then --蓝
                    spine:setSkin("lan")
                else
                    spine:setSkin("lv")
                end
            end
        end
    end

    if self:getGameSpinStage( ) > IDLE and self:getGameSpinStage() ~= QUICK_RUN and self:getCurrSpinMode() ~= RESPIN_MODE then
        symbolNode:runAnim("idleframe1",true)
    end
    
end

function CodeGameScreenGoldieGrizzliesMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self:getGameSpinStage( ) > IDLE and self:getGameSpinStage() ~= QUICK_RUN then
            node:runAnim("idleframe2",true)
        else
            node:runAnim("idle",true)
        end
    end
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGoldieGrizzliesMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenGoldieGrizzliesMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_3,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenGoldieGrizzliesMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 or 
        symbolType == self.SYMBOL_BONUS_2 or 
        symbolType == self.SYMBOL_BONUS_3 then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenGoldieGrizzliesMachine:slotOneReelDown(reelCol)    
    self:hideLayerBlack()
    CodeGameScreenGoldieGrizzliesMachine.super.slotOneReelDown(self,reelCol) 

    -- local isplay= true
    -- if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
    --     local isHaveFixSymbol = false
    --     for iRow = 1, self.m_iReelRowNum do
    --         if self:isFixSymbol(self.m_stcValidSymbolMatrix[iRow][reelCol]) then
    --             isHaveFixSymbol = true
    --             break
    --         end
    --     end
    --     if isHaveFixSymbol == true and isplay then
    --         isplay = false
    --         -- respinbonus落地音效
    --         -- gLobalSoundManager:playSound("GoldieGrizzliesSounds/music_GoldieGrizzlies_fall_" .. reelCol ..".mp3") 
    --     end
    -- end
   
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenGoldieGrizzliesMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenGoldieGrizzliesMachine:levelFreeSpinOverChangeEffect()

    
    
end
---------------------------------------------------------------------------


-- 触发freespin时调用
function CodeGameScreenGoldieGrizzliesMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("GoldieGrizzliesSounds/music_GoldieGrizzlies_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFreeSpinView()    
    end,0.5)

end


-- 触发freespin结束时调用
function CodeGameScreenGoldieGrizzliesMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("GoldieGrizzliesSounds/music_GoldieGrizzlies_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        -- 调用此函数才是把当前游戏置为freespin结束状态
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end

function CodeGameScreenGoldieGrizzliesMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeGoldieGrizzliesSrc.GoldieGrizzliesJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)
end

function CodeGameScreenGoldieGrizzliesMachine:playChipCollectAnim(curIndex,symbolList,func)
    if curIndex > #symbolList then
        self:delayCallBack(1,function()
            if type(func) == "function" then
                func()
            end
        end)
        
        return
    end
    local symbolNode = symbolList[curIndex]
    if symbolNode then
        self.m_rsWinScore = self.m_rsWinScore + (symbolNode.m_score or 0)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_end_collect)
        symbolNode:runAnim("jiesuan",false,function()
            symbolNode:runAnim("idleframe2",true)
            
        end)

        self:flyRespinScoreParticle(symbolNode,self.m_bottomUI.coinWinNode,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_end_collect_feed_back)
            --底部赢钱光效
            self:playCoinWinEffectUI()
            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_rsWinScore))
            self:playChipCollectAnim(curIndex + 1,symbolList,func)
        end)

        

        -- --收集下个图标
        -- self:delayCallBack(0.5,function()
            
        -- end)
    else
        self:playChipCollectAnim(curIndex + 1,symbolList,func)
    end
end

--[[
    收集分数动画
]]
function CodeGameScreenGoldieGrizzliesMachine:flyRespinScoreParticle(startNode,endNode,func)
    
    local flyNode = util_createAnimation("GoldieGrizzlies_bouns_shoujilizi_0.csb")
    
    local Particle = flyNode:findChild("Particle_1")
    Particle:setPositionType(0)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(15 / 30,endPos),
        cc.CallFunc:create(function()
            Particle:stopSystem()
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

function CodeGameScreenGoldieGrizzliesMachine:respinFullAni(symbolList,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_collect_full)
    --出现一个X2砸向棋盘
    local multiAni = util_createAnimation("GoldieGrizzlies_bonus_xbei.csb")
    self:findChild("Node_tx"):addChild(multiAni)
    multiAni:runCsbAction("actionframe",false,function()
        multiAni:removeFromParent()
    end)
    self:delayCallBack(30 / 60,function()
        local spine = util_spineCreate("GoldieGrizzlies_respin_yugao",true,true)
        self:findChild("Node_tx1"):addChild(spine)

        --棋盘出现光圈
        local lightAni = util_createAnimation("GoldieGrizzlies_respin_yugao.csb")
        for index = 1,3 do
            lightAni:findChild("Particle_"..(3 + index)):setVisible(false)
        end
        self:findChild("Node_tx1"):addChild(lightAni)
        self:runCsbAction("shake",true)

        util_spinePlay(spine,"actionframe")
        util_spineEndCallFunc(spine,"actionframe",function()
            self:runCsbAction("idleframe",true)
            spine:setVisible(false)
            lightAni:removeFromParent()
            self:delayCallBack(0.5,function()
                spine:removeFromParent()
            end)

            if type(func) == "function" then
                func()
            end
        end)

        --数字变为2倍
        for k,symbolNode in pairs(symbolList) do
            symbolNode:runAnim("actionframe")
            local lbl_coins = self:getLblOnBonusSymbol(symbolNode)
            lbl_coins:runCsbAction("xbei")
            symbolNode.m_score = symbolNode.m_score * 2
            self:delayCallBack(5 / 60,function()
                for index = self.SYMBOL_BONUS_3,self.SYMBOL_BONUS_1 do
                    lbl_coins:findChild("m_lb_coins_"..index):setVisible(index == symbolNode.p_symbolType)
                    lbl_coins:findChild("m_lb_coins_"..index):setString(util_formatCoins(symbolNode.m_score,3))
                    self:updateLabelSize({label=lbl_coins:findChild("m_lb_coins_"..index),sx=1,sy=1},120)
                end
            end)
        end
    end)
end

--结束移除小块调用结算特效
function CodeGameScreenGoldieGrizzliesMachine:reSpinEndAction()    
    
    -- 播放收集动画效

    self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    local chipList = self.m_respinView:getAllCleaningNode()    
    self.m_rsWinScore = 0

    local func = function()
        
        --播放触发动画
        for i,symbol in ipairs(chipList) do
            symbol:runAnim("actionframe",false,function()
                symbol:runAnim("idleframe",true)
            end)
        end

        self:delayCallBack(60 / 30,function()
            self:playChipCollectAnim(1,chipList,function()
                -- 通知respin结束
                self:respinOver()
            end)
        end)
    end

    --等落地播完
    self:delayCallBack(0.5,function()
        --判断轮盘是否集满
        if self.m_runSpinResultData.p_selfMakeData.full then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_end_trigger)
            self:respinFullAni(chipList,function()
                func()
            end)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_collect_without_full)
            func()
        end
    end)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenGoldieGrizzliesMachine:getRespinRandomTypes( )
    local symbolList = {}

    local bonusType = self.m_runSpinResultData.p_selfMakeData.respinType or self.SYMBOL_BONUS_1
    --bonus出现概率为25%
    for index = 1,3 do
        symbolList[#symbolList + 1] = self.SYMBOL_EMPTY
    end
    symbolList[#symbolList + 1] = bonusType

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenGoldieGrizzliesMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_BONUS_1, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_BONUS_2, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_BONUS_3, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

function CodeGameScreenGoldieGrizzliesMachine:showRespinView()
    self.m_triggerRespin = false

    --先播放动画 再进入respin
    self:clearCurMusicBg()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    
    --隐藏固定小块
    self.m_lockNode:setVisible(false)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_bonus_trigger_short_music)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    local delayTime = 0
    if self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount then
        --触发动画
        local children = self.m_clipParent:getChildren()
        for index = 1, #children do
            local slotsNode = children[index]
            if slotsNode.p_symbolType and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                slotsNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                local order = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER) - slotsNode.p_rowIndex
                slotsNode:changeParentToOtherNode(self.m_effectNode,order)
                slotsNode:runAnim("actionframe2",false,function()
                    slotsNode.m_isInTop = true
                    slotsNode:putBackToPreParent()
                end)
            end
        end
        for iCol = 1,self.m_iReelColumnNum do
            --scatter只出现在1 3列
            if iCol ~= 2 and iCol ~= 4 then
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType then
                        if self:isFixSymbol(symbolNode.p_symbolType) then
                            symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                            symbolNode:changeParentToOtherNode(self.m_effectNode)
                            symbolNode:runAnim("actionframe",false,function()
                                    
                            end)
                            self:delayCallBack(60 / 30,function()
                                symbolNode:runAnim("idleframe",true)
                                symbolNode:putBackToPreParent()
                            end)
                        end
                    end
                end
            end
        end
        delayTime = 60 / 30
    end
    

    self:delayCallBack(delayTime,function()
        self:showReSpinStart(function()
            self:changeSceneToRespin(function()
                
            end)

            self:delayCallBack(235 / 30,function()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )

                --可随机的特殊信号 
                local endTypes = self:getRespinLockTypes()
                
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)

                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            end)
            
        end)
    end)
end

function CodeGameScreenGoldieGrizzliesMachine:initRespinView(endTypes, randomTypes)
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

            local func = function()
                
                
                self:runNextReSpinReel()
            end

            if self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount then
                local fixSymbol
                --刷新小块数字
                for index = 1,#self.m_respinView.m_respinNodes do
                    local respinNode = self.m_respinView.m_respinNodes[index]
                    if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType and self:isFixSymbol(respinNode.m_baseFirstNode.p_symbolType) then
                        local symbolNode = respinNode.m_baseFirstNode
                        symbolNode.m_score = self.m_runSpinResultData.p_selfMakeData.respinCredit
                        local score = util_formatCoins(symbolNode.m_score, 3)
                        fixSymbol = symbolNode
                        local label = self:getLblOnBonusSymbol(symbolNode)
                        if label then
                            self:updateLblCoinsOnBonus(symbolNode,label,score)
                        end

                        --图标先隐藏,等待转场动画播完
                        symbolNode:setVisible(false)
                    end
                end
                self.m_respinInfoBar:findChild("m_lb_coins"):setVisible(false)
                self:delayCallBack(0.5,function()
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:changeSceneToRespin2(fixSymbol,function()
                        func()
                    end)
                end)
                
                
            else
                func()
            end
            
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--[[
    respin过场
]]
function CodeGameScreenGoldieGrizzliesMachine:changeSceneToRespin(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_changeScene_to_respin)

    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(display.width, display.height))
    layout:setAnchorPoint(cc.p(0.5, 0.5))
    layout:setTouchEnabled(true)
    layout:setSwallowTouches(true)
    layout:setPosition(display.center)
    layout:setScale(self.m_machineRootScale)
    self:addChild(layout,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)

    local spine = util_spineCreate("GoldieGrizzlies_guochang",true,true)
    layout:addChild(spine)
    spine:setPosition(display.center)
    util_spinePlay(spine,"actionframe1")
    util_spineEndCallFunc(spine,"actionframe1",function()
        spine:setVisible(false)
        if type(func) == "function" then
            func()
        end
        self:delayCallBack(0.5,function()
            layout:removeFromParent()
        end)
    end)
end

--[[
    respin过场2
]]
function CodeGameScreenGoldieGrizzliesMachine:changeSceneToRespin2(symbolNode,func)
    if not symbolNode then
        if type(func) == "function" then
            func()
        end
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_changeScene_to_respin_2)
    local spine = util_spineCreate("GoldieGrizzlies_Bonus_guochang",true,true)
    self.m_effectNode:addChild(spine)
    spine:setPosition(util_convertToNodeSpace(self:findChild("root"),self.m_effectNode))

    local respinType = self.m_runSpinResultData.p_selfMakeData.respinType or self.SYMBOL_BONUS_3
    if respinType == self.SYMBOL_BONUS_1 then
        spine:setSkin("hong")
    elseif respinType == self.SYMBOL_BONUS_2 then
        spine:setSkin("lan")
    else
        spine:setSkin("lv")
    end

    --数字
    local score = util_formatCoins(self.m_runSpinResultData.p_selfMakeData.respinCredit, 3)
    local label = util_createAnimation("Socre_GoldieGrizzlies_Bonus_shuzi.csb")
    util_spinePushBindNode(spine,"shizi",label)
    spine.m_label = label
    label:runCsbAction("idle")
    for index = self.SYMBOL_BONUS_3,self.SYMBOL_BONUS_1 do
        label:findChild("m_lb_coins_"..index):setVisible(index == symbolNode.p_symbolType)
        label:findChild("m_lb_coins_"..index):setString(score)
        self:updateLabelSize({label=label:findChild("m_lb_coins_"..index),sx=1,sy=1},110)
    end
    symbolNode:runAnim("idleframe2",true)

    --碗落下砸到轮盘上
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function()
        util_spinePlay(spine,"idleframe",true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_collect_score_on_change_ani)
        --数字飞到信息区
        self:flyScoreAniForChangeScene(spine.m_label,self.m_respinInfoBar:findChild("m_lb_coins"),score,symbolNode.p_symbolType,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_collect_score_on_change_ani_feed_back)
            self.m_respinInfoBar:findChild("m_lb_coins"):setVisible(true)
            self.m_respinInfoBar:runCsbAction("actionframe")
            local selfData = self.m_runSpinResultData.p_selfMakeData
            local coins = util_formatCoins(selfData.respinCredit or 0,3)
            local label = self.m_respinInfoBar:findChild("m_lb_coins"):setString(coins)
            self:updateLabelSize({label=self.m_respinInfoBar:findChild("m_lb_coins"),sx=1.2,sy=1.2},95)

            --spine变小飞到图标处
            local endPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
            util_spinePlay(spine,"actionframe1")
            util_spineEndCallFunc(spine,"actionframe1",function ()
                spine:setVisible(false)
                self:delayCallBack(0.5,function()
                    spine:removeFromParent()
                end)

                symbolNode:setVisible(true)
                symbolNode:runAnim("idleframe",true)
                

                if type(func) == "function" then
                    func()
                end
                -- local lbl_coins = self:getLblOnBonusSymbol(symbolNode)
                -- if lbl_coins then
                --     lbl_coins:runCsbAction("actionframe",false,function()
                --         if type(func) == "function" then
                --             func()
                --         end
                --     end)
                -- end
            end)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_move_to_bonus)
            spine:runAction(cc.Sequence:create({
                cc.EaseSineIn:create(cc.MoveTo:create(15 / 30,endPos))
            }))
        end)
    end)

    self:delayCallBack(12 / 30,function()
        --轮盘震动
        self:runCsbAction("shake",false,function()
            self:runCsbAction("idleframe",true)
        end)
    end)
end



function CodeGameScreenGoldieGrizzliesMachine:showReSpinStart(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_show_respin_start)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = self.m_runSpinResultData.p_reSpinsTotalCount
    ownerlist["m_lb_coins"] = util_formatCoins(self.m_runSpinResultData.p_selfMakeData.respinCredit, 3)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, ownerlist, func)
    view.m_btnTouchSound = PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_start_clicked
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_start_over)
    end)
    local respinType = self.m_runSpinResultData.p_selfMakeData.respinType or self.SYMBOL_BONUS_1
    view:findChild("respin1"):setVisible(respinType == self.SYMBOL_BONUS_1)
    view:findChild("respin2"):setVisible(respinType == self.SYMBOL_BONUS_2)
    view:findChild("respin3"):setVisible(respinType == self.SYMBOL_BONUS_3)

    self:updateLabelSize({label=view:findChild("m_lb_coins"),sx=1.25,sy=1.25},95)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

--ReSpin开始改变UI状态
function CodeGameScreenGoldieGrizzliesMachine:changeReSpinStartUI(respinCount)
    self:showRespinBar()

    for index = 1,#self.m_collectBars do
        self.m_collectBars[index]:setVisible(false)
        self.m_collectBars[index].m_light:setVisible(false)
    end
    self.m_respinInfoBar:setVisible(true)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        self.m_respinInfoBar:findChild("Node_red"):setVisible(selfData.respinType == self.SYMBOL_BONUS_1)
        self.m_respinInfoBar:findChild("Node_blue"):setVisible(selfData.respinType == self.SYMBOL_BONUS_2)
        self.m_respinInfoBar:findChild("Node_green"):setVisible(selfData.respinType == self.SYMBOL_BONUS_3)

        self:changeReelBg(selfData.respinType)

        local coins = util_formatCoins(selfData.respinCredit or 0,3)
        if self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount then
            coins = 0
        end
        local label = self.m_respinInfoBar:findChild("m_lb_coins"):setString(coins)
        self:updateLabelSize({label=self.m_respinInfoBar:findChild("m_lb_coins"),sx=1.2,sy=1.2},95)
    end
    

end

--ReSpin刷新数量
function CodeGameScreenGoldieGrizzliesMachine:changeReSpinUpdateUI(curCount)
    self.m_respinBar:changeRespinByCount(curCount)

    
end

--ReSpin结算改变UI状态
function CodeGameScreenGoldieGrizzliesMachine:changeReSpinOverUI()
    self:hideRespinBar()

    for index = 1,#self.m_collectBars do
        self.m_collectBars[index]:setVisible(true)
    end

    --刷新收集进度
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self:refreshCollectBar(selfData)

    self.m_respinInfoBar:setVisible(false)
end

---判断结算
function CodeGameScreenGoldieGrizzliesMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

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
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

    local func = function()
        if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        end

        --继续
        self:runNextReSpinReel()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end

    
    if self.m_runSpinResultData.p_selfMakeData.extraTimes then
        
        self:delayCallBack(0.5,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_show_extra_time_tip)
            local spine = util_spineCreate("GoldieGrizzlies_respinadditional",true,true)
            self:findChild("Node_respinadditional"):addChild(spine)
            util_spinePlay(spine,"actionframe")
            util_spineEndCallFunc(spine,"actionframe",function()
                spine:setVisible(false)
                self:showRsExtraTimesView(func)
                self:delayCallBack(0.2,function()
                    spine:removeFromParent()
                end)
                
            end)
        end)
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    else
        func()
    end
end

function CodeGameScreenGoldieGrizzliesMachine:showExplainView()
    local view = util_createView("CodeGoldieGrizzliesSrc.GoldieGrizzliesExplainView")

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
end

function CodeGameScreenGoldieGrizzliesMachine:showRsExtraTimesView(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_show_extra_time_view)
    local view = util_createView("CodeGoldieGrizzliesSrc.GoldieGrizzliesExtraTimesView",{machine = self,callBack = func})

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
end

function CodeGameScreenGoldieGrizzliesMachine:showRespinOverView(effectData)

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.start_credit then
        self.m_start_credit = self.m_runSpinResultData.p_selfMakeData.start_credit
    end

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_end_short_music)
    local view=self:showReSpinOver(strCoins,function()
        self:changeSceneToBase(function()
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg() 
        end)
        
        self:delayCallBack(0.5,function()
            self:changeReelBg(-1)

            --变更轮盘小块
            self:changeRespinReelByStart()

            --显示固定小块
            self.m_lockNode:setVisible(true)
            --刷新固定小块
            self:refreshLockScatter()

            for iCol = 1,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_EMPTY then
                        local randSymbolType = math.random(0,10)
                        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,randSymbolType), randSymbolType)
                        symbolNode.p_symbolType = randSymbolType
                    end
                end
            end
        end)
    end)
    -- gLobalSoundManager:playSound("GoldieGrizzliesSounds/music_GoldieGrizzlies_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},793)

    view.m_btnTouchSound = PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_end_clicked
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_respin_end_over)
    end)
end

function CodeGameScreenGoldieGrizzliesMachine:changeRespinReelByStart()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local startReel = self.m_runSpinResultData.p_selfMakeData.start_reel
    if not startReel then
        return
    end

    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local betData = {}
    if selfData.bet then
        betData = selfData.bet[tostring(curTotalBet)] or {}
    end
    local wildPos = betData.wild_pos

    if wildPos then
        for index = 1,#wildPos do
            local posIndex = wildPos[index]
            local posData = self:getRowAndColByPos(posIndex)
            local iCol,iRow = posData.iY,posData.iX
            startReel[self.m_iReelRowNum - iRow + 1][iCol] = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
        end
    end

    for iCol = 1,self.m_iReelColumnNum do
        local parentData = self.m_slotParents[iCol]
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            local symbolType = startReel[self.m_iReelRowNum - iRow + 1][iCol]

            if not symbolNode.m_baseNode then
                symbolNode.m_baseNode = parentData.slotParent
            end

            if not symbolNode.m_topNode then
                symbolNode.m_topNode = parentData.slotParentBig
            end

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self:changeSymbolToScatter(symbolNode)
            else
                self:changeSymbolType(symbolNode,symbolType,self:isSpecialSymbol(symbolType))
            end

            
        end
    end
end

function CodeGameScreenGoldieGrizzliesMachine:isSpecialSymbol(symbolType)
    for i,v in ipairs(self.m_configData.p_specialSymbolList) do
        if v == symbolType then
            return true
        end
    end
    
    return false
end

function CodeGameScreenGoldieGrizzliesMachine:changeSceneToBase(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_change_scene_to_base)

    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(display.width, display.height))
    layout:setAnchorPoint(cc.p(0.5, 0.5))
    layout:setTouchEnabled(true)
    layout:setSwallowTouches(true)
    layout:setPosition(display.center)
    layout:setScale(self.m_machineRootScale)
    self:addChild(layout,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)


    local spine = util_spineCreate("GoldieGrizzlies_guochang",true,true)
    layout:addChild(spine)
    spine:setPosition(display.center)
    util_spinePlay(spine,"actionframe2")
    util_spineEndCallFunc(spine,"actionframe2",function()
        spine:setVisible(false)
        if type(func) == "function" then
            func()
        end
        self:delayCallBack(0.5,function()
            layout:removeFromParent()
        end)
    end)
end


-- --重写组织respinData信息
function CodeGameScreenGoldieGrizzliesMachine:getRespinSpinData()
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
function CodeGameScreenGoldieGrizzliesMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume()

    self.m_scatter_down = {}
    self.m_bonus_down = {}

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end




function CodeGameScreenGoldieGrizzliesMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_enter_game)

    end,0.4,self:getModuleName())
end

function CodeGameScreenGoldieGrizzliesMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    
    CodeGameScreenGoldieGrizzliesMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    --刷新界面上固定的scatter图标
    self:refreshLockScatter(true)

    --刷新收集进度
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self:refreshCollectBar(selfData)

    self:runCsbAction("idleframe",true)

    self:changeReelBg(-1)

    if self.m_isNeedPlayEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end

    local hasFeature = self:checkHasFeature()
    if not hasFeature then
        self:showExplainView()
    end

    

    -- if self:getCurrSpinMode() == RESPIN_MODE then
        
    -- end
end

---
-- 进入关卡
--
function CodeGameScreenGoldieGrizzliesMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()
    self.m_isNeedPlayEffect = isPlayGameEffect

    -- if isPlayGameEffect or #self.m_gameEffects > 0 then
    --     self:sortGameEffects()
    --     self:playGameEffect()
    -- end
end

function CodeGameScreenGoldieGrizzliesMachine:addObservers()
	CodeGameScreenGoldieGrizzliesMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:clearWinLineEffect()
            local selfData = self.m_runSpinResultData.p_selfMakeData
            self:refreshCollectBar(selfData)
            self:refreshLockScatter()
        end
        
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --freespin最后一次spin不会播大赢,需单独处理
            local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            if fsLeftCount <= 0 then
                self.m_bIsBigWin = false
            end
        end
        
        if self.m_bIsBigWin then
            return
        end

        if self.m_triggerRespin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winCoin / lTatolBetNum
        local soundIndex = 1
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundIndex = 1
            elseif winRatio > 1 and winRatio <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig.SoundConfig["sound_GoldieGrizzlies_winline_"..soundIndex] 
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenGoldieGrizzliesMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenGoldieGrizzliesMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    收集条反馈动画
]]
function CodeGameScreenGoldieGrizzliesMachine:collectBarFeedBackAni(index,func,selfData)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_base_bonus_collect_feed_back)

    if not selfData then
        selfData = {}
    end

    local credit = selfData.credit
    if not credit then
        credit = {}
    end

    local idleAnis = {"idleframe","idleframe1","idleframe2"}
    local barItem = self.m_collectBars[index]
    local curLevel = barItem.m_curLevel
    local level = self:getCollectLevel(index)

    local isRespin = self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    --触发时播额外光效
    if isRespin then
        local light = barItem.m_light
        light:setVisible(true)
        light:runCsbAction("chufa",true)
    end

    --进度升级
    if level > curLevel then
        local swithAniName = "switch"
        if isRespin and curLevel == 1 then
            --触发respin时直接播第三阶段动画
            swithAniName = "switch2"
        elseif level == 3 then
            swithAniName = "switch1"
        end
        barItem.m_curLevel = level
        barItem:runCsbAction(swithAniName,false,function()
            barItem:runCsbAction(idleAnis[level],true)
            if type(func) == "function" then
                func()
            end
        end)
    else
        
        barItem.m_curLevel = curLevel
        local aniName = "actionframe"..curLevel
        
        barItem:runCsbAction(aniName,false,function()
            barItem:runCsbAction(idleAnis[curLevel],true)
            if type(func) == "function" then
                func()
            end
        end)
    end

    
    

    local score = credit[index] or 0
    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local initMultiple = self.m_start_credit[index] or 0
    score = score + initMultiple * curTotalBet

    local color = {"red","blue","green"}
    for index = 1,#color do
        for iColor = 1,3 do
            local m_lb_coins = barItem:findChild("m_lb_coins_"..color[iColor])
            m_lb_coins:setString(util_formatCoins(score,3,nil,nil,nil,true))
            self:updateLabelSize({label=m_lb_coins,sx=0.78,sy=0.78},129)
        end
    end
end

--[[
    刷新收集进度
]]
function CodeGameScreenGoldieGrizzliesMachine:refreshCollectBar(selfData)

    if not selfData then
        selfData = {}
    end

    local credit = selfData.credit
    if not credit then
        credit = {}
    end

    local idleAnis = {"idleframe","idleframe1","idleframe2"}
    local color = {"red","blue","green"}
    for index = 1,#self.m_collectBars do
        local barItem = self.m_collectBars[index]
        local score = credit[index] or 0

        local curTotalBet = globalData.slotRunData:getCurTotalBet()
        local initMultiple = self.m_start_credit[index] or 0
        score = score + initMultiple * curTotalBet

       
        for iColor = 1,3 do
            local m_lb_coins = barItem:findChild("m_lb_coins_"..color[iColor])
            m_lb_coins:setString(util_formatCoins(score,3,nil,nil,nil,true))
            self:updateLabelSize({label=m_lb_coins,sx=0.78,sy=0.78},129)
        end

        --刷新进度表现
        local level = self:getCollectLevel(index)
        barItem:runCsbAction(idleAnis[level],true)
        barItem.m_curLevel = level
    end
end

--[[
    获取收集进度等级
]]
function CodeGameScreenGoldieGrizzliesMachine:getCollectLevel(index)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return 1
    end
    local symbolType = self.SYMBOL_BONUS_1
    if index == 2 then
        symbolType = self.SYMBOL_BONUS_2
    elseif index == 3 then
        symbolType = self.SYMBOL_BONUS_3
    end

    local isRespin = self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    if isRespin and symbolType == selfData.respinType then
        return 3
    end

    local bonusNum = selfData.bonus_num or {}
    local curNum = bonusNum[index] or 0
    local bonusLevel = self.m_bonus_level[tostring(symbolType)] or {5,10}
    
    for iLevel = 1,#bonusLevel do
        if curNum <= bonusLevel[iLevel] then
            return iLevel
        end
    end
    return 3
end


--[[
    变更小块信号值
]]
function CodeGameScreenGoldieGrizzliesMachine:changeSymbolType(symbolNode,symbolType,isInTop)

    if not isInTop then
        isInTop = false
    end

    if symbolNode then
        if symbolNode.p_symbolImage then
            symbolNode.p_symbolImage:removeFromParent()
            symbolNode.p_symbolImage = nil
        end
        local symbolName = self:getSymbolCCBNameByType(self,symbolType)
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType), symbolType)
        symbolNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self,symbolType))

        local zOrder = self:getBounsScatterDataZorder(symbolType)
        symbolNode.p_symbolType = symbolType
        symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
        symbolNode.m_isInTop = isInTop
        symbolNode:putBackToPreParent()
        symbolNode:setLocalZOrder(symbolNode.p_showOrder)
    end
end

--[[
    切换bet是切换scatter图标
]]
function CodeGameScreenGoldieGrizzliesMachine:changeScatterOnChangeBet()
    --切bet时固定的wild先变为其他图标
    for index = 1,#self.m_lockScatters do
        local lockNode = self.m_lockScatters[index]
        local posIndex = lockNode.m_posIndex
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX

        local symbolNode = self:getFixSymbol(iCol,iRow)
        if symbolNode then
            local randType = math.random(0,self.SYMBOL_SCORE_11)
            self:changeSymbolType(symbolNode,randType,false)
        end
    end
end

--[[
    把小块变为scatter图标
]]
function CodeGameScreenGoldieGrizzliesMachine:changeSymbolToScatter(symbolNode,isInit)
    if not symbolNode then
        return
    end
    if symbolNode.p_symbolImage then
        symbolNode.p_symbolImage:removeFromParent()
        symbolNode.p_symbolImage = nil
    end
    symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_SCATTER), TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    if isInit then
        symbolNode:runAnim("idle",true)
    else
        symbolNode:runAnim("idleframe",true)
    end
    
    symbolNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_SCATTER))
    local zOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    symbolNode.p_symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
    symbolNode.m_isInTop = true

    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
    util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
    -- symbolNode:setPositionY(curPos.y)
    symbolNode:setLocalZOrder(symbolNode.p_showOrder)
end

--[[
    刷新固定的scatter图标
]]
function CodeGameScreenGoldieGrizzliesMachine:refreshLockScatter(isInit)
    --滚动过程中不刷新
    if self.m_isReelRun then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData

    local curTotalBet = globalData.slotRunData:getCurTotalBet()

    if curTotalBet ~= self.m_curTotalBet then
        self:changeScatterOnChangeBet()
    elseif #self.m_lockScatters > 0 then
        --把固定的spine替换到symbol上,防止跳帧
        for index = #self.m_lockScatters,1,-1 do
            local lockNode = self.m_lockScatters[index]
            if lockNode and lockNode.m_posIndex ~= -1 then
                local posIndex = lockNode.m_posIndex
                lockNode:setVisible(true)
                lockNode:stopAllActions()
                local posData = self:getRowAndColByPos(posIndex)
                local iCol,iRow = posData.iY,posData.iX
                local symbolNode = self:getFixSymbol(iCol,iRow)
                if symbolNode and symbolNode.p_symbolType then
                    --不是scatter的小块变为scatter
                    if symbolNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self:changeSymbolToScatter(symbolNode)
                    end
                    --替换spine
                    local ccbNode = symbolNode:getCCBNode()
                    if ccbNode.m_spineNode then
                        ccbNode.m_spineNode:removeFromParent()
                    end
                    util_changeNodeParent(ccbNode,lockNode)
                    ccbNode.m_spineNode = lockNode
                    lockNode:setPosition(cc.p(0,0))
                    table.remove(self.m_lockScatters,index)
                else
                    table.remove(self.m_lockScatters,index)
                end
            else
                table.remove(self.m_lockScatters,index)
            end
            
        end
        -- self:changeSymbolType(symbolNode,randType,false)
    end

    self.m_lockNode:removeAllChildren()
    self.m_lockScatters = {}

    self.m_curTotalBet = curTotalBet
    if not selfData then
        return
    end

    if not selfData.bet then
        return
    end

    local betData = selfData.bet[tostring(curTotalBet)]
    if not betData then
        return
    end
    local wildPos = betData.wild_pos

    for index = 1,#wildPos do
        local lockNode = util_spineCreate("Socre_GoldieGrizzlies_Scatter",true,true) --util_createAnimation("Socre_GoldieGrizzlies_Scatter.csb")
        self.m_lockScatters[#self.m_lockScatters + 1] = lockNode
        self.m_lockNode:addChild(lockNode)
        util_spinePlay(lockNode,"idleframe",true)

        local posIndex = wildPos[index]
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX

        --将轮盘上的小块变为scatter
        local symbolNode = self:getFixSymbol(iCol,iRow)
        if symbolNode and symbolNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self:changeSymbolToScatter(symbolNode,isInit)
        elseif symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if isInit then
                symbolNode:runAnim("idle",true)
            else
                -- symbolNode:runAnim("idleframe",true)
            end
        end

        local clipTarPos = util_getOneGameReelsTarSpPos(self, posIndex)
        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
        local nodePos = self.m_lockNode:convertToNodeSpace(worldPos)
        
        lockNode:setVisible(false)
        lockNode:setPosition(nodePos)
        lockNode.m_posIndex = posIndex
        lockNode:setLocalZOrder(posIndex)
        lockNode.isUnlock = posIndex > 9
    end
end

--[[
    移动固定图标
]]
function CodeGameScreenGoldieGrizzliesMachine:moveLockScatter(func)
    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.bet then
        if type(func) == "function" then
            func(false)
        end
        return
    end

    local betData = selfData.bet[tostring(curTotalBet)]
    if not betData then
        if type(func) == "function" then
            func(false)
        end
        return
    end
    local delayTime = 0

    for index = 1,#self.m_lockScatters do
        local lockNode = self.m_lockScatters[index]
        local posIndex = lockNode.m_posIndex
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX
        --在最下层的图标不固定
        if not lockNode.isUnlock then
            delayTime = 60 / 30
            lockNode:setVisible(true)

            local nodePos = cc.p(lockNode:getPosition())
            local isHide = false
            if iRow - 1 > 0 then
                --图标向下移动一格
                local tarIndex = self:getPosReelIdx(iRow - 1,iCol)
                local clipTarPos = util_getOneGameReelsTarSpPos(self, tarIndex)
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                nodePos = self.m_lockNode:convertToNodeSpace(worldPos)
                lockNode.m_posIndex = tarIndex
            else
                isHide = true
                nodePos.y = nodePos.y - self.m_SlotNodeH 
            end
            util_spinePlay(lockNode,"actionframe3")
            util_spineEndCallFunc(lockNode,"actionframe3",function()
                if not tolua.isnull(lockNode) then
                    --延迟一帧避免闪烁
                    performWithDelay(lockNode,function()
                        if not tolua.isnull(lockNode) then
                            util_spinePlay(lockNode,"idleframe",true)
                            lockNode:setPosition(nodePos)
                        end
                    end,1 / 30)

                    if isHide then
                        lockNode:setVisible(false)
                    end
                end
                
            end)
        else
            lockNode:setVisible(false)
            lockNode.m_posIndex = -1
        end
        
    end

    if delayTime > 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_scatter_move)
        if math.random(1,10) <= 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_Haiiii)
        end
    end
    
    self:delayCallBack(delayTime,function()
        if type(func) == "function" then
            func(delayTime > 0)
        end
        
    end)
end



-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGoldieGrizzliesMachine:addSelfEffect()
    --收集分数
    if self.m_runSpinResultData.p_storedIcons and #self.m_runSpinResultData.p_storedIcons > 0  then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_EFFECT -- 动画类型
    end
    local features = self.m_runSpinResultData.p_features or {}
    self.m_triggerRespin = #features > 1 and 3 == features[2]
end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGoldieGrizzliesMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_EFFECT then
        self:collectScoreAni(function()
            
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BIG_WIN_LIGHT then
        self:showEffect_BigWinLight(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
	return true
end

function CodeGameScreenGoldieGrizzliesMachine:collectScoreAni(func)
    if self.m_runSpinResultData.p_storedIcons and #self.m_runSpinResultData.p_storedIcons > 0  then
        for index = 1,#self.m_runSpinResultData.p_storedIcons do
            local data = self.m_runSpinResultData.p_storedIcons[index]
            local posIndex = data[1]
            local pos = self:getRowAndColByPos(posIndex)
            local iCol,iRow = pos.iY,pos.iX
            local symbolNode =  self:getFixSymbol(iCol, iRow)

            if symbolNode then
                local collectIndex = self:getCollectIndex(symbolNode.p_symbolType)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_base_bonus_collect)
                symbolNode:runAnim("shouji_yaochu",false,function()
                    symbolNode:runAnim("shouji_wan",true)
                    --收集过程中数字消失
                    local label = self:getLblOnBonusSymbol(symbolNode)
                    if label then
                        label:runCsbAction("shouji")
                    end
                    if type(func) == "function" then
                        func()
                    end
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    local collectBar = self.m_collectBars[collectIndex]
                    self:flyCollectScoreAni(symbolNode,collectBar,function()
                        symbolNode:runAnim("shouji_wan_over",false,function()
                            symbolNode:runAnim("idleframe",true)
                        end)

                        collectBar.m_upAni:setVisible(true)
                        collectBar.m_upAni:runCsbAction("actionframe")
                        self:collectBarFeedBackAni(
                            collectIndex,
                            function()
                                self:refreshCollectBar(selfData)
                            end,
                            selfData
                        )
                    end)
                end)
                --每次spin只会出一个bonus图标
                return
            end
        end
    else
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self:refreshCollectBar(selfData)
        if type(func) == "function" then
            func()
        end
    end

    
end

--[[
    获取收集索引
]]
function CodeGameScreenGoldieGrizzliesMachine:getCollectIndex(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 then
        return 1
    elseif symbolType == self.SYMBOL_BONUS_2 then
        return 2
    else
        return 3
    end
end

--[[
    收集分数动画
]]
function CodeGameScreenGoldieGrizzliesMachine:flyCollectScoreAni(startNode,endNode,func)
    
    local spine = util_spineCreate("Socre_GoldieGrizzlies_Bonus",true,true)
    util_spinePlay(spine,"shouji_shaozifeixing")

    local symbolType = startNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS_1 then --红
        spine:setSkin("hong")
    elseif symbolType == self.SYMBOL_BONUS_2 then --蓝
        spine:setSkin("lan")
    else
        spine:setSkin("lv")
    end

    local flyNode = cc.Node:create()
    flyNode:addChild(spine,10)

    -- local tempNode = cc.Node:create()
    -- util_spinePushBindNode(spine,"lizituowei",tempNode)

    --粒子拖尾
    local tail = util_createAnimation("GoldieGrizzlies_bouns_shoujilizi_0.csb")
    util_spinePushBindNode(spine,"lizituowei",tail)
    -- flyNode:addChild(tail,5)
    -- tail:setPosition(util_convertToNodeSpace(tempNode,flyNode))
    
    local Particle = tail:findChild("Particle_1")
    Particle:setPositionType(0)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.EaseSineIn:create(cc.BezierTo:create(18 / 30,{startPos, cc.p(endPos.x - 100, startPos.y - 100), endPos})),
        -- cc.MoveTo:create(12 / 30,endPos),
        cc.CallFunc:create(function()
            -- spine:setVisible(false)
            Particle:stopSystem()
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

--[[
    respin过场飞分数
]]
function CodeGameScreenGoldieGrizzliesMachine:flyScoreAniForChangeScene(startNode,endNode,score,symbolType,func)
    
    local flyNode = util_createAnimation("Socre_GoldieGrizzlies_Bonus_shuzi.csb")
    startNode:setVisible(true)
    
    for index = self.SYMBOL_BONUS_3,self.SYMBOL_BONUS_1 do
        flyNode:findChild("m_lb_coins_"..index):setVisible(index == symbolType)
        flyNode:findChild("m_lb_coins_"..index):setString(score)
        self:updateLabelSize({label=flyNode:findChild("m_lb_coins_"..index),sx=1,sy=1},120)
    end

    flyNode:runCsbAction("fly")

    --粒子拖尾
    local Particle = flyNode:findChild("Particle_1")
    Particle:setPositionType(0)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(24 / 60,endPos),
        cc.CallFunc:create(function()
            flyNode:findChild("Node_2"):setVisible(false)
            Particle:stopSystem()
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenGoldieGrizzliesMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


function CodeGameScreenGoldieGrizzliesMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenGoldieGrizzliesMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenGoldieGrizzliesMachine:slotReelDown( )
    if self.m_reelRunSoundTag then
        gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    self.m_isReelRun = false
    local delayTime = 0

    local isHaveFixSymbol = false
    local scatterShowCol = self.m_configData.p_scatterShowCol
    for iRow = 1, self.m_iReelRowNum do
        if self:isFixSymbol(self.m_stcValidSymbolMatrix[iRow][self.m_iReelColumnNum]) then
            isHaveFixSymbol = true
        end
        if not isHaveFixSymbol and self:getGameSpinStage() == QUICK_RUN then
            for index = 1,#scatterShowCol do
                local iCol = scatterShowCol[index]
                if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isHaveFixSymbol = true
                    break
                end
            end
        end

        if isHaveFixSymbol then
            break
        end
    end

    --检测轮盘上是否有落地图标
    if isHaveFixSymbol == true then
        delayTime = 0.5
        self:reelDownNotifyChangeSpinStatus()
    end

    --等待落地动画播完
    self:delayCallBack(delayTime,function()
        self:refreshLockScatter()
        CodeGameScreenGoldieGrizzliesMachine.super.slotReelDown(self)

        for index = 1,#self.m_lockScatters do
            local lockNode = self.m_lockScatters[index]
            lockNode:setVisible(false)
        end
    end)

    
end

function CodeGameScreenGoldieGrizzliesMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    延迟回调
]]
function CodeGameScreenGoldieGrizzliesMachine:delayCallBack(time, func)
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

function CodeGameScreenGoldieGrizzliesMachine:beginReel()
    self.m_isReelRun = true
    CodeGameScreenGoldieGrizzliesMachine.super.beginReel(self)
    self:showLayerBlack()
    self:moveLockScatter(function(isNeedMove)
        if isNeedMove then
            self.m_configData.p_reelRunDatas = {3,6,9,12,15}--{8,11,14,17,20}
        else
            self.m_configData.p_reelRunDatas = {16,19,22,25,28}
        end
        for iCol =1,self.m_iReelColumnNum do
            self.m_reelRunInfo[iCol].m_reelRunLen = self.m_configData.p_reelRunDatas[iCol]
            self.m_reelRunInfo[iCol].initInfo.autoSpinreelRunLen = self.m_configData.p_reelRunDatas[iCol]
        end

        --等移动完再请求数据
        self:requestSpinResult()
    end)
end

function CodeGameScreenGoldieGrizzliesMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == RESPIN_MODE then
        self:requestSpinResult()
    end

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage(WAITING_DATA)
    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

---
--设置bonus scatter 层级
function CodeGameScreenGoldieGrizzliesMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
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

--[[
    获取bonus小块上的label
]]
function CodeGameScreenGoldieGrizzliesMachine:getLblOnBonusSymbol(symbolNode)
    local aniNode = symbolNode:checkLoadCCbNode()
    local spine = aniNode.m_spineNode
    if spine and not spine.m_lbl_score then
        local label = util_createAnimation("Socre_GoldieGrizzlies_Bonus_shuzi.csb")
        util_spinePushBindNode(spine,"shuzi",label)
        spine.m_lbl_score = label
    end

    return spine.m_lbl_score
end

--[[
    刷新bonus上小块分数
]]
function CodeGameScreenGoldieGrizzliesMachine:updateLblCoinsOnBonus(symbolNode,lbl_coins,coins)
    for index = self.SYMBOL_BONUS_3,self.SYMBOL_BONUS_1 do
        lbl_coins:findChild("m_lb_coins_"..index):setVisible(index == symbolNode.p_symbolType)
        lbl_coins:findChild("m_lb_coins_"..index):setString(coins)
        self:updateLabelSize({label=lbl_coins:findChild("m_lb_coins_"..index),sx=1,sy=1},110)
        lbl_coins:runCsbAction("idle")
    end
end

function CodeGameScreenGoldieGrizzliesMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenGoldieGrizzliesMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    local resultReel = self.m_runSpinResultData.p_selfMakeData.result_reels
    for row = 1, iRow do
        if resultReel and resultReel[row] and resultReel[row][column] and resultReel[row][column] == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end

            break
        end
        
    end

    if not self.m_isNotice and bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenGoldieGrizzliesMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()
    
    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    self.m_isWaitingNetworkData = false

    -- 出现预告动画概率30%
    self.m_isNotice = (math.random(1, 100) <= 30) 

    
    
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then
        self:produceSlots()
        if self.m_isNotice then
            self:playNoticeAct(function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            end)
            self:delayCallBack(2,function()
                self:operaNetWorkData() -- end
            end)
        else
            self:operaNetWorkData() -- end
        end
        
    else
        self.m_isNotice = false
        self:produceSlots()
        self:operaNetWorkData() -- end
    end
    
end

function CodeGameScreenGoldieGrizzliesMachine:dealSmallReelsSpinStates( )
    if not self.m_isNotice then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
end

--[[
    预告中奖动画
]]
function CodeGameScreenGoldieGrizzliesMachine:playNoticeAct(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_notcie_win)
    local ani = util_createAnimation("GoldieGrizzlies_free_yugao.csb")
    self:findChild("root"):addChild(ani,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    ani:runCsbAction("actionframe",true)

    local spine = util_spineCreate("GoldieGrizzlies_yugao_juese",true,true)
    ani:findChild("Node_juese"):addChild(spine)
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function()
        ani:setVisible(false)
        if type(func) == "function" then
            func()
        end
        self:delayCallBack(0.5,function()
            ani:removeFromParent()
        end)
        
    end)
end

function CodeGameScreenGoldieGrizzliesMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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

                if not slotNode then
                    slotNode = self.m_clipParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                end

                checkAddLineSlotNode(slotNode)

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

function CodeGameScreenGoldieGrizzliesMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

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
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    local winSize = cc.Director:getInstance():getWinSize()
    if ratio >= 768 / 1024 then
        mainScale = 0.8
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        mainScale = 0.88
        mainPosY = mainPosY
    elseif ratio < 640 / 960 and ratio >= 768 / 1230 then
        mainScale = 0.98
        mainPosY = mainPosY - 10
    elseif ratio < 768 / 1230 and ratio > 768 / 1370 then
        mainScale = 1
        mainPosY = mainPosY - 5
    else
        mainScale = 1
        mainPosY = mainPosY - 5
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenGoldieGrizzliesMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    -- _slotNode:setPositionY(curPos.y)

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
                            newSpeedActionTable[i] = speedActionTable[i]:clone()
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable)
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and not self.m_scatter_down[_slotNode.p_cloumnIndex] then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_scatter_down)
                end
                
                if self:isFixSymbol(_slotNode.p_symbolType) and not self.m_bonus_down[_slotNode.p_cloumnIndex] then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_bonus_down)
                end
                self.m_bonus_down[_slotNode.p_cloumnIndex] = true
                self.m_scatter_down[_slotNode.p_cloumnIndex] = true
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            end
        end
    end
    if self.m_bClickQuickStop then
        for index = 1,self.m_iReelColumnNum do
            self.m_scatter_down[index] = true
            self.m_bonus_down[index] = true
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenGoldieGrizzliesMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:isFixSymbol(_slotNode.p_symbolType) then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                -- if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                --     return true
                -- end
                return true
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenGoldieGrizzliesMachine:symbolBulingEndCallBack(_slotNode)
    -- if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --     _slotNode:runAnim("idle",true)
    -- else
    --     _slotNode:runAnim("idleframe",true)
    -- end

    _slotNode:runAnim("idleframe",true)
    
end

function CodeGameScreenGoldieGrizzliesMachine:getBottomUINode()
    return "CodeGoldieGrizzliesSrc.GoldieGrizzliesBottomNode"
end

function CodeGameScreenGoldieGrizzliesMachine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

    -- if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
    --     if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --         lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
    --     elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    --         lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
    --     end
    -- end

    return enumSymbolType
end

function CodeGameScreenGoldieGrizzliesMachine:delaySlotReelDown()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:resetSlotsRunChangeData()

    -- 开始执行后续的逻辑 ， 暂时不考虑准备下一阶段的滚动内容
    self:heldOnAllScore()

    self:MachineRule_stopReelChangeData()

    --改变freespin状态
    self:changeFreeSpinModeStatus()

    -- 改变respin状态
    self:changeReSpinModeStatus()

    -- 添加自定义的effects
    self:addSelfEffect()

    self:calculateLastWinCoin()

    self:addLastWinSomeEffect()

    -- 保留本轮结果
    self:keepCurrentSpinData()

    self:checkRemoveBigMegaEffect()

    --添加连线动画
    self:addLineEffect()

    --刷新quest 并且尝试添加quest完成
    self:addQuestCompleteTipEffect()

    -- 添加活动赠送免费spin次数游戏事件
    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    --添加收集角标Effct
    self:addCollectSignEffect()

    --检测添加大赢光效
    self:checkAddBigWinLight()

    --动画层级赋值
    self:setGameEffectOrder()

    self:sortGameEffects()

    if #self.m_gameEffects > 0 then
        -- 通知动画开始运行。
        self.m_isRunningEffect = true
    end

    for i = #self.m_vecSymbolEffectType, 1, -1 do
        table.remove(self.m_vecSymbolEffectType, i)
    end

    self:removeGameEffectType(GameEffect.EFFECT_FIVE_OF_KIND)    
end


--[[
    检测添加大赢光效
]]
function CodeGameScreenGoldieGrizzliesMachine:checkAddBigWinLight()
    --检测是否有大赢
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasEffectType(GameEffect.EFFECT_EPICWIN) then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        effectData.p_selfEffectType = self.EFFECT_BIG_WIN_LIGHT -- 动画类型
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end


--[[
    连线播大赢前光效
]]
function CodeGameScreenGoldieGrizzliesMachine:showEffect_BigWinLight(func)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_big_win)
    local spine = util_spineCreate("GoldieGrizzlies_respin_yugao",true,true)
    self:findChild("Node_tx1"):addChild(spine)

    --棋盘出现光圈
    local lightAni = util_createAnimation("GoldieGrizzlies_respin_yugao.csb")
    for index = 1,3 do
        lightAni:findChild("Particle_"..index):setVisible(false)
    end
    self:findChild("Node_tx1"):addChild(lightAni)

    local time = spine:getAnimationDurationTime("actionframe2")
    util_spinePlay(spine,"actionframe2")
    util_spineEndCallFunc(spine,"actionframe2",function()
        spine:setVisible(false)
        lightAni:removeFromParent()
        self:delayCallBack(0.5,function()
            spine:removeFromParent()
        end)

        if type(func) == "function" then
            func()
        end
    end)
    
end

function CodeGameScreenGoldieGrizzliesMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

function CodeGameScreenGoldieGrizzliesMachine:playBulingSymbolSounds(_iCol, _soundName, _soundType)
    
end

return CodeGameScreenGoldieGrizzliesMachine






