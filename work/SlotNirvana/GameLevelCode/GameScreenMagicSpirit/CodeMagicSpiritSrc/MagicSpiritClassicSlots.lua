local BaseMiniMachine = require "Levels.BaseMiniMachine"
local BaseSlots = require "Levels.BaseSlots"
local SlotParentData = require "data.slotsdata.SlotParentData"
local GameEffectData = require "data.slotsdata.GameEffectData"

local MagicSpiritClassicSlots = class("MagicSpiritClassicSlots", BaseMiniMachine)

MagicSpiritClassicSlots.Classic_CHANGE_SYMBOL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10 -- 自定义动画的标识
MagicSpiritClassicSlots.Classic_WIN_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 11 -- 自定义动画的标识

MagicSpiritClassicSlots.m_classicPlayIndex = 94
MagicSpiritClassicSlots.m_ClassicSymbolType = 94

MagicSpiritClassicSlots.m_classicTemReelData = {
    ClassicSlots94 = {{195,195,195},{101,195,103},{195,192,195},{102,195,100},{195,195,195}},
    ClassicSlots95 = {{195,195,195},{200,195,200},{195,292,195},{203,195,201},{195,195,195}},
    ClassicSlots96 = {{195,195,195},{391,303,195},{195,195,390},{303,392,195},{195,195,195}}
}

-- 构造函数    
function MagicSpiritClassicSlots:ctor()
    MagicSpiritClassicSlots.super.ctor(self)
end
 
function MagicSpiritClassicSlots:initData_(data)

    self.m_randomSymbolSwitch = true
    self.m_bCreateResNode = false
    self.m_classicPlayIndex = 94
    self.m_ClassicSymbolType = 94
    
    self.gameResumeFunc = nil
    self.gameRunPause = nil
    self.m_parent = data.parent

   
    --滚动节点缓存列表
    self.cacheNodeMap = {}
    --随机事件 的临时钻石小块
    self.m_rapidsActionNode = {}
    --init
    self:initGame()
  
end

function MagicSpiritClassicSlots:initGame()
   

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MagicSpiritClassicSlots:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MagicSpirit"
end

---
-- 读取配置文件数据
--
function MagicSpiritClassicSlots:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData("MagicSpirit_ClassicConfig.csv", "LevelMagicSpiritConfig.lua")
    end

end

function MagicSpiritClassicSlots:initMachineCSB()
    self.m_winFrameCCB = "WinFrameMagicSpirit_Classic"
    self:createCsbNode("MagicSpirit/ClassicBonus.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    self.m_node_effect = cc.Node:create()
    self.m_root:addChild(self.m_node_effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
end

function MagicSpiritClassicSlots:initMachine()
    self.m_moduleName = self:getModuleName()

    MagicSpiritClassicSlots.super.initMachine(self)
end

function MagicSpiritClassicSlots:onEnter()
    MagicSpiritClassicSlots.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MagicSpiritClassicSlots:addObservers()
    gLobalNoticManager:addObserver(self, self.quicklyStopReel, ViewEventType.RESPIN_TOUCH_SPIN_BTN)

    MagicSpiritClassicSlots.super.addObservers(self)
end

function MagicSpiritClassicSlots:onExit()
    MagicSpiritClassicSlots.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId_jumpCoin then
        gLobalSoundManager:stopAudio(self.m_soundId_jumpCoin)
        self.m_soundId_jumpCoin = nil
    end
    if self.m_soundId_lineFrame then
        gLobalSoundManager:stopAudio(self.m_soundId_lineFrame)
        self.m_soundId_lineFrame = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function MagicSpiritClassicSlots:removeObservers()
    MagicSpiritClassicSlots.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MagicSpiritClassicSlots:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)
    return ccbName
end

-- 处理特殊关卡 遮罩层级
function MagicSpiritClassicSlots:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    local maxzorder = 0
    local zorder = 0

    for i = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder > maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

function MagicSpiritClassicSlots:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end

        return false
    end

    return true
end

function MagicSpiritClassicSlots:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MagicSpiritClassicSlots:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function MagicSpiritClassicSlots:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MagicSpiritClassicSlots:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function MagicSpiritClassicSlots:clearCurMusicBg()
end

function MagicSpiritClassicSlots:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function MagicSpiritClassicSlots:playEffectNotifyChangeSpinStatus()
  
end

function MagicSpiritClassicSlots:slotReelDown()
    MagicSpiritClassicSlots.super.slotReelDown(self)

    self:spinBtn_updateBtnStatus(false)
end

function MagicSpiritClassicSlots:reelDownNotifyPlayGameEffect()
    MagicSpiritClassicSlots.super.reelDownNotifyPlayGameEffect(self)
end

----------------------------- 玩法处理 -----------------------------------

function MagicSpiritClassicSlots:beginMiniReel()
    for iCol=1,self.m_iReelColumnNum do
        self:setTopResNodeVisible(iCol,true )
    end

    MagicSpiritClassicSlots.super.beginReel(self)
    local classicIndex = self.m_parent.m_classicIndexLis[self.m_ClassicSymbolType]
    local randomMax = 3 - (classicIndex - 1)
    local soundName = string.format("MagicSpiritSounds/music_MagicSpirit_classic_run%d_%d.mp3", classicIndex, math.random(1, randomMax)) 
    gLobalSoundManager:playSound(soundName)
    
    --设置全局的滚动状态和按钮状态
    globalData.slotRunData.gameSpinStage = GAME_MODE_ONE_RUN
    self:spinBtn_normalSpinStart()
    
end

function MagicSpiritClassicSlots:dealSmallReelsSpinStates( )

end


function MagicSpiritClassicSlots:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

-- 消息返回更新数据
function MagicSpiritClassicSlots:netWorkCallFun(spinResult)
    print(cjson.encode(spinResult))
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:updateNetWorkData()
    --开启按钮点击
    globalData.slotRunData.isClickQucikStop = false
    self:spinBtn_normalSpinRecv()
    self:spinBtn_updateBtnStatus(true)
end

function MagicSpiritClassicSlots:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function MagicSpiritClassicSlots:quicklyStopReel(colIndex)

    MagicSpiritClassicSlots.super.quicklyStopReel(self, colIndex)

end

---
-- 清空掉产生的数据
--
function MagicSpiritClassicSlots:clearSlotoData()
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end


function MagicSpiritClassicSlots:addSelfEffect()
     -- 自定义动画创建方式
     local selfDate = self.m_runSpinResultData.p_selfMakeData
     local rapidPositions = selfDate.rapidPositions
     local rapids = selfDate.rapids
     local rapidWinCoins = selfDate.rapidWinCoins

     if rapidPositions and #rapidPositions>1 then
         local selfEffect = GameEffectData.new()
         selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
         selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
         self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
         selfEffect.p_selfEffectType = self.Classic_CHANGE_SYMBOL_EFFECT -- 动画类型
     end
     
     if rapids and rapids >= 5 then -- >= 5个才会弹板
        if  rapidWinCoins then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Classic_WIN_JACKPOT_EFFECT -- 动画类型 !!!
        end
     end
     
end


function MagicSpiritClassicSlots:playChangeToRapids(effectData)


    self.m_parent.m_Anigenie:setVisible(true)
    gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_juese_changeRapids.mp3") 
    util_spinePlay(self.m_parent.m_Anigenie,"actionframe7")
    util_spineEndCallFunc(self.m_parent.m_Anigenie,"actionframe7", function()

        self.m_parent.m_Anigenie:setVisible(false)
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    --第24帧 触发 actionframe2
    performWithDelay(waitNode,function(  )
        --整列出wild时配合角色一起播
        self:runCsbAction("actionframe2",false)

        --第40帧 触发 随机事件切换轮盘展示
        performWithDelay(waitNode,function(  )
            local selfDate = self.m_runSpinResultData.p_selfMakeData
            if selfDate.rapidPositions and #selfDate.rapidPositions>0 then
                self:playRapidAction(selfDate.rapidPositions, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end

            waitNode:removeFromParent()
        end,16/30)

    end,24/30)
    
end

function MagicSpiritClassicSlots:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.Classic_CHANGE_SYMBOL_EFFECT then
        -- gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_bonusRapids_start.mp3")

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            self:playChangeToRapids(effectData)
            
            waitNode:removeFromParent()
        end, 0.5)
    elseif effectData.p_selfEffectType == self.Classic_WIN_JACKPOT_EFFECT then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local num = selfData.rapids or 5 --rapids对应个数 触发jackpot
        local winCoins = selfData.rapidWinCoins or 5 --rapids 触发jackpot 对应的赢钱数
        self.m_parent:showRespinJackpot(
            num,
            winCoins,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end
    return true
end


--[[
    
*******************  重置 classic Ui   *******************
--]]


function MagicSpiritClassicSlots:restClassicSlots(_data )
    
    self.m_classicPlayIndex     = _data.symbolType -- classic 1-3  94 95 96
    self.m_callFunc             = _data.func -- 结束回调
    self.m_iBetLevel            = _data.betlevel -- bet等级
    self.m_ClassicSymbolType    = _data.symbolType -- 对应触发信号
    self.m_spinTimes            = _data.spinTimes -- 点击个数
    self.m_currReelWinCoin      = 0

    self:updateClassicReelBg()
    self:restAllReelsNode()
    --初始化一些节点的默认显示
    self:changeWinCoinLineShow(false)
    self:changeFiveJackpotShow(false)

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function MagicSpiritClassicSlots:restAllReelsNode()
    self:stopAllActions()
    self:clearWinLineEffect()
    self:restSlotNodeByData()
end

function MagicSpiritClassicSlots:getSlotNodeType(_iCol,_iRow)
    
    local reeldata = self.m_classicTemReelData["ClassicSlots"..self.m_classicPlayIndex]

    local rowCount = #reeldata
    local rowDatas = reeldata[rowCount - _iRow + 1]
    if not rowDatas then
       return nil
    end
    local symbolType = rowDatas[_iCol]

    return symbolType
end

-- 小轮盘玩法处理
function MagicSpiritClassicSlots:restSlotNodeByData()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getReelParentChildNode(iCol, iRow)
            local symbolType = self:getSlotNodeType(iCol, iRow)
            if targSp then
                self.m_parent:removeBaseReelMulLab( targSp )
                if symbolType ~= self.m_parent.SYMBOL_CLASSIC_SCORE_Blank then
                    local ccbName = self:getSymbolCCBNameByType(self.m_parent, symbolType)
                    targSp:changeCCBByName(ccbName, symbolType)
                    targSp:changeSymbolImageByName(ccbName)
                    targSp:resetReelStatus()
                else
                    
                    targSp:clear()
                end

                targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) - targSp.p_rowIndex)
            end
        end
    end
end

function MagicSpiritClassicSlots:initRandomSlotNodes()
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()

    for iCol=1,self.m_iReelColumnNum do
        self:setTopResNodeVisible(iCol,false )
    end

end

function MagicSpiritClassicSlots:setTopResNodeVisible(_iCol,_visible )
    
    local node = self:getFixSymbol(_iCol, self.m_iReelRowNum + 1)
    if node then
        node:setVisible(_visible)
    end

end

function MagicSpiritClassicSlots:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end


function MagicSpiritClassicSlots:specialSymbolActionTreatment(node)
    -- if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or node.p_symbolType == self.SYMBOL_SCATTER_GOLD) then
    --     node:runAnim("buling")
    -- end
end


function MagicSpiritClassicSlots:slotOneReelDown(reelCol)

    self:setTopResNodeVisible(reelCol,false )

    MagicSpiritClassicSlots.super.slotOneReelDown(self, reelCol)
   
end

-- 给respin小块进行赋值
function MagicSpiritClassicSlots:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then

        --根据网络数据获取停止滚动时小块倍数
        local mul = self:getNormalSymbolMul(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if type(mul) == "number" then
            if mul > self.m_parent.m_NormalSymbolMul then
                self.m_parent:createBaseReelMulLab(symbolNode )
                local mulLab = symbolNode:getChildByName("mulLab")
                mulLab:setPosition(30,-25)
                mulLab:setScale(0.7)
                self.m_parent:setMulLabNum(mul,symbolNode)
            end
        end
        symbolNode:runAnim("idleframe")
    else
        local mul = self.m_parent:randomDownSymbolMul(symbolType) --获取分数（随机假滚数据）
        if symbolNode and symbolNode.p_symbolType then
            if mul ~= nil and type(mul) ~= "string" then
                if type(mul) == "number" then
                    if mul > self.m_parent.m_NormalSymbolMul then
                        if not self.m_parent.m_OutLines then
                            self.m_parent:createBaseReelMulLab(symbolNode )
                            local mulLab = symbolNode:getChildByName("mulLab")
                            mulLab:setPosition(30,-25)
                            mulLab:setScale(0.7)
                            self.m_parent:setMulLabNum(mul,symbolNode)
                        end
                    end
                end
            end
            symbolNode:runAnim("idleframe")
        end
    end

end




-- 根据网络数据获得普通小块的倍数
function MagicSpiritClassicSlots:getNormalSymbolMul(_posId)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local multiplies = selfdata.multiplies or {}
    local mul = self.m_parent.m_NormalSymbolMul
    if _posId then
        local index = _posId + 1
        mul = multiplies[index] or 1
    end
   
    return mul
end

function MagicSpiritClassicSlots:pushSlotNodeToPoolBySymobolType(symbolType, gridNode)
    MagicSpiritClassicSlots.super.pushSlotNodeToPoolBySymobolType(self,symbolType, gridNode)
    self.m_parent:removeBaseReelMulLab(gridNode )
end

--新滚动使用
function MagicSpiritClassicSlots:updateReelGridNode(_symbolNode)
    local symbolType = _symbolNode.p_symbolType
    if symbolType then
        self.m_parent:removeBaseReelMulLab(_symbolNode )
        if self.m_parent:checkAddMuilLab(symbolType )  then
            self:setSpecialNodeScore(nil, {_symbolNode})
        end
        
    end

end



--设置bonus scatter 层级
function MagicSpiritClassicSlots:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
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
--添加金边
function MagicSpiritClassicSlots:creatReelRunAnimation(col)
 
end

function MagicSpiritClassicSlots:setReelRunInfo( )

end


function MagicSpiritClassicSlots:updateClassicReelBg()

    self:findChild("Node_hong"):setVisible(false)
    self:findChild("Node_jin"):setVisible(false)
    self:findChild("Node_lv"):setVisible(false)

    if self.m_ClassicSymbolType == self.m_parent.SYMBOL_CLASSIC1 then -- 绿
        self:findChild("Node_lv"):setVisible(true)
    elseif self.m_ClassicSymbolType == self.m_parent.SYMBOL_CLASSIC2 then -- 红
        self:findChild("Node_hong"):setVisible(true)
    elseif self.m_ClassicSymbolType == self.m_parent.SYMBOL_CLASSIC3 then -- 金
        self:findChild("Node_jin"):setVisible(true)
    end
end

--绘制多个裁切区域
function MagicSpiritClassicSlots:drawReelArea()
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
        local high = reelSize.height / 4
        reelSize.height = reelSize.height + high

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        
        local clipNode
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNode.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode = cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create()     -- cc.LayerColor:create(cc.c4f(r,g,b,200))  --
        
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY - ((slotH /5) * 0.5) )
        clipNode:setTag(CLIP_NODE_TAG + i)

        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()

        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData
    end

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


    end
end

---
-- 获取最高的那一列
--
function MagicSpiritClassicSlots:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0

    local iColNum = self.m_iReelColumnNum
    --    local maxHeightColumnIndex = iColNum
    for iCol = 1, iColNum, 1 do
        -- local colNodeName = "reel_unit"..(iCol - 1)
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))


        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width
            
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / 4

    for iCol = 1, iColNum, 1 do
        -- self.m_reelColDatas[iCol].p_slotColumnPosY = self.m_reelColDatas[iCol].p_slotColumnPosY - 0.5 * self.m_SlotNodeH
        self.m_reelColDatas[iCol].p_slotColumnHeight = self.m_reelColDatas[iCol].p_slotColumnHeight + self.m_SlotNodeH
    end

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = self.m_iReelRowNum -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
    self:initReelControl()
end

--初始化带子（放在drawReelArea()绘制裁切区域之后）
function MagicSpiritClassicSlots:initReelControl()
    local ReelControl = util_require(self:getBaseReelControl())
    self.m_reels = {}
    for i=1,self.m_iReelColumnNum do
        local parentData = self.m_slotParents[i]
        parentData.reelWidth = self.m_fReelWidth
        parentData.reelHeight = self.m_fReelHeigth + self.m_fReelHeigth / 4
        parentData.slotNodeW = self.m_fReelWidth
        parentData.slotNodeH = self.m_fReelHeigth / 4
        local reel = ReelControl:create()
        --设置格子lua类名
        reel:setScheduleName(self:getBaseReelSchedule())
        reel:setGridNodeName(self:getBaseReelGridNode())
        --关卡slotNode重写需要用到
        reel:setMachine(self)
        --初始化
        reel:initData(parentData,self.m_configData,self.m_reelColDatas[i],handler(self,self.createNextGrideData),handler(self,self.reelSchedulerCheckColumnReelDown),handler(self,self.updateReelGridNode))
        self.m_reels[i] = reel
    end
end

function MagicSpiritClassicSlots:playEffectNotifyNextSpinCall()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local classicJackpot = selfdata.classicJackpot
    local wincoins = self.m_runSpinResultData.p_winAmount
    --下一步
    local nextFun = function()
        --停止连线动画     
        self:resetReelShowState()
        
        performWithDelay(self,function()
            --停止主棋盘jackpot高亮
            self:hideJacjpotLight()

            if self.m_callFunc then
                self.m_callFunc()
                self.m_callFunc = nil
            end
        end,0.5)
    end
    --是否中了jackPot
    if classicJackpot then
        performWithDelay(self,function()
                self.m_parent:showJackpotView(classicJackpot,wincoins,function()
                    nextFun()
                end)
        end,1)
    else
        nextFun()
    end
end

function MagicSpiritClassicSlots:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex, self.m_classicPlayIndex)

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--顶部补块
function MagicSpiritClassicSlots:createResNode(parentData)

    if self.m_bCreateResNode == false then
        return 
    end

    MagicSpiritClassicSlots.super.createResNode(self,parentData)
end

function MagicSpiritClassicSlots:checkNotifyUpdateWinCoin()
   
end

function MagicSpiritClassicSlots:playGameEffect()
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == true then
        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    end
    MagicSpiritClassicSlots.super.playGameEffect(self)
end

function MagicSpiritClassicSlots:updateCoinsLab(_coins)
    _coins = _coins or 0

    for i=1,3 do
        local lab = self:findChild("m_lb_coin"..i)
        if lab then
            lab:setString(util_formatCoins(_coins,3))
            self:updateLabelSize({label = lab, sx = 1, sy = 1}, 166)
        end
    end
end

function MagicSpiritClassicSlots:jumpCoinsLab(_coins)
    self.m_winCoin = _coins
    if self.m_updateCoinHandlerID then
        return
    end
    local curCoins = 0
    self:updateCoinsLab( curCoins )

    local coinRiseNum =  _coins / (1 * 60)
    coinRiseNum = math.ceil(coinRiseNum) 

    self.m_soundId_jumpCoin = gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_classic_jumpCoin.mp3")
    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()
        curCoins = curCoins + coinRiseNum

        if curCoins >= self.m_winCoin then
            curCoins = self.m_winCoin

            if self.m_soundId_jumpCoin then
                gLobalSoundManager:stopAudio(self.m_soundId_jumpCoin)
                self.m_soundId_jumpCoin = nil
            end
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
        else
        end
        
        self:updateCoinsLab(curCoins)
    end)
end

--随机事件钻石移动效果 从上边下滑一整行 移动时间 1s
--检查移动列的第1，5行判断移动方向 每列
function MagicSpiritClassicSlots:playRapidAction(rapidPositions, endFun)
    --需要移动的列
    local iCol = rapidPositions[1]%self.m_iReelColumnNum + 1
     

    --补充不可见的小块
    local symbolList,moveNum,offset = self:getRapidActionNode(iCol, rapidPositions)
    --存一下类型
    local reelData = self:getFinalReelData()

    --移动的方向是创建方向的相反方向
    local distance = cc.p(0, -offset * moveNum * self.m_SlotNodeH)

    local moveTime = 1

    --移除并替换新增的小块
    local createCount = #symbolList-self.m_iReelRowNum
    local act_callFun_replace = cc.CallFunc:create(function()
        for _index=1,#symbolList do
            local symbolNode = symbolList[_index]
            
            --原有的小块刷新展示的位置
            if(_index <= self.m_iReelRowNum)then
                local symbolType = reelData[_index][iCol]
                local ccbName = self:getSymbolCCBNameByType(self.m_parent, symbolType)
                if symbolType == self.m_parent.SYMBOL_CLASSIC_SCORE_Rapid then
                    symbolNode:changeCCBByName(ccbName, symbolType)
                    symbolNode:changeSymbolImageByName(ccbName)
                    symbolNode:resetReelStatus()
                else
                    self.m_parent:removeBaseReelMulLab( symbolNode )
                    symbolNode:clear()
                end
                
                --还原坐标
                local pos = cc.p(symbolNode:getPositionX() - distance.x, symbolNode:getPositionY() - distance.y)
                symbolNode:setPosition(pos)
            --新增的临时小块全部移除
            else
                 --丢进池子
                symbolNode:removeFromParent()
                self.m_parent:pushSlotNodeToPoolBySymobolType(symbolNode.p_symbolType, symbolNode)
            end
        end
    end)
    local act_callFun_next = cc.CallFunc:create(function()
        if endFun then
            endFun()
        end
    end)

    gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_bonusRapids_move.mp3")

    for _index,_symbolNode in ipairs(symbolList) do
        local symbolNode = _symbolNode
        local action = nil

        local act_move = cc.MoveTo:create(moveTime, cc.p(symbolNode:getPositionX()+distance.x, symbolNode:getPositionY()+distance.y))
        if(#symbolList == _index)then
            symbolNode:runAction(cc.Sequence:create(act_move, act_callFun_replace, act_callFun_next))
        else
            symbolNode:runAction(cc.Sequence:create(act_move))
        end
    end
end
--获取随机事件的移动方向，距离，起始/终点索引    
function MagicSpiritClassicSlots:getRapidActionParams(rapidPositions)
    --以棋盘上的行数方向为标准
    local params = {
        --最内侧 rapid 行数索引
        startIndex = 1,
        endIndex   = self.m_iReelRowNum,
        --偏移方向(补充额外小块的方向) ,和 移动方向相反
        offset = 1,  
        --移动距离
        moveNum = 0,
    }

    --需要移动的列
    local iCol = rapidPositions[1]%self.m_iReelColumnNum + 1
    --首次展示棋盘的数据
    local reels = self.m_runSpinResultData.p_reels
    --哪一行是钻石
    local rapid_lineData = {}
    for _index,_pos in ipairs(rapidPositions) do
       rapid_lineData[math.floor(_pos/self.m_iReelColumnNum)+1] = 1
    end

    local rapidCount = #rapidPositions
    --上拉、掉落 检测对应的行数
    local up_list = {4,5}
    local down_list = {2,1}
    
    for _index=1,#up_list do
        local isBreak = false
        local rowIndex = up_list[_index]
        local rowSymbol = reels[rowIndex][iCol]
        --起始的行索引需要移动到的终点
        local moveEnd_rowIndex = 0  --棋盘行数

        if(rowSymbol == self.m_parent.SYMBOL_CLASSIC_SCORE_Rapid)then
            isBreak = true
            --需要向上拉 那起始行向下偏移
            params.offset = -1 

            --找到最高点行数
            moveEnd_rowIndex = 1
            for _rapid_rowIndex,v in pairs(rapid_lineData) do
                --服务器行数 -> 棋盘行数
                local reel_rowIndex = 1 + (self.m_iReelRowNum - _rapid_rowIndex)
                if reel_rowIndex > moveEnd_rowIndex then
                    moveEnd_rowIndex = reel_rowIndex
                end
            end
        end
        
        
        if(not isBreak)then
            rowIndex = down_list[_index]
            rowSymbol = reels[rowIndex][iCol]

            if(rowSymbol == self.m_parent.SYMBOL_CLASSIC_SCORE_Rapid)then
                isBreak = true
                --需要向下落 那起始行向上偏移
                params.offset = 1

                --找到最低点行数
                moveEnd_rowIndex = 5
                for _rapid_rowIndex,v in pairs(rapid_lineData) do
                    --服务器行数 -> 棋盘行数
                    local reel_rowIndex = 1 + (self.m_iReelRowNum - _rapid_rowIndex)
                    if reel_rowIndex < moveEnd_rowIndex then
                        moveEnd_rowIndex = reel_rowIndex
                    end
                end
            end
        end

        if(isBreak)then
            --最多向原方向查一个小块(中心点) 取服务器数据需要用 棋盘偏移的相反数
            local lastSymbol = reels[rowIndex - (-params.offset)][iCol]
            if(lastSymbol == self.m_parent.SYMBOL_CLASSIC_SCORE_Rapid)then
                params.startIndex = 1 + (self.m_iReelRowNum - rowIndex) - params.offset
            else
                params.startIndex = 1 + (self.m_iReelRowNum - rowIndex)
            end
            
            params.moveNum = math.abs(moveEnd_rowIndex-params.startIndex)

            if params.offset > 0 then
                params.endIndex = self.m_iReelRowNum + params.moveNum
            else
                params.endIndex = 1 - params.moveNum
            end

            break
        end
    end


    return params
end
--棋盘行数 上->下 5~1 行,服务器行数 上->下 1~5
--
function MagicSpiritClassicSlots:getRapidActionNode(_iCol, rapidPositions)
    local nodes = {}

    local params = self:getRapidActionParams(rapidPositions)

    --最内侧 rapid 行数索引
    local startIndex = params.startIndex       
    local endIndex   = params.endIndex
    --(补充额外小块的方向) 
    local offset = params.offset
    --移动距离
    local moveNum = params.moveNum

    local rapidCount = #rapidPositions

    --当前棋盘上的小块
    for iRow = 1,self.m_iReelRowNum,1 do
        local node = self:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
        table.insert(nodes, node)
    end

    --棋盘上 补充的小块
    local rapidType = self.m_parent.SYMBOL_CLASSIC_SCORE_Rapid
    local blankType = self.m_parent.SYMBOL_CLASSIC_SCORE_Blank
    for iRow=startIndex,endIndex,offset do
        local symbolNode = nil

        --替换列内小块或者新增小块
        if(1<=iRow and iRow<=self.m_iReelRowNum)then
            symbolNode = nodes[iRow]

            if symbolNode.p_symbolType ~= rapidType then
                --替换的话改一下信号值
                local ccbName = self:getSymbolCCBNameByType(self.m_parent, rapidType)
                symbolNode:changeCCBByName(ccbName, rapidType)
                symbolNode:changeSymbolImageByName(ccbName)
                symbolNode:resetReelStatus()

                self.m_parent:removeBaseReelMulLab(symbolNode )
            end
        else
            local symbolType = math.abs(iRow-startIndex)<rapidCount and rapidType or blankType
            symbolNode = self:getSlotNodeBySymbolType(symbolType)

            symbolNode.p_rowIndex = iRow

            local showOrder = self.m_parent:getBounsScatterDataZorder(symbolType, _iCol, iRow)
            symbolNode.m_showOrder = showOrder
            self:getReelParent(_iCol):addChild(symbolNode, showOrder)
            local startpos = cc.p(self.m_SlotNodeW, (symbolNode.p_rowIndex - 0.5) * self.m_SlotNodeH)
            symbolNode:setPosition(startpos)

            --补充的小块
            table.insert(nodes, symbolNode)
        end
    end

    return nodes,moveNum,offset
end

--棋盘最终结果，包含 随机事件滚动后数据
function MagicSpiritClassicSlots:getFinalReelData()
    local reel_data = clone(self.m_runSpinResultData.p_reels)

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local rapidPositions = selfData.rapidPositions
    if(rapidPositions and #rapidPositions>0)then
        local rapidType = self.m_parent.SYMBOL_CLASSIC_SCORE_Rapid
        local blankType = self.m_parent.SYMBOL_CLASSIC_SCORE_Blank
        --需要移动的列
        local iCol = rapidPositions[1]%self.m_iReelColumnNum + 1
        --获取以棋盘为标准的随机事件数据
        local params = self:getRapidActionParams(rapidPositions)
        -- 转换为服务器数据的标准
        -- 服务器数据的方向 = -棋盘行数方向  ,  移动方向 = -补充小块方向 
        local moveOffset = - (-params.offset)
        local moveNum = params.moveNum * moveOffset


        --取将要移动到该行的信号，不存在的话先补空
        for _row=1,self.m_iReelRowNum do
            reel_data[_row][iCol] = reel_data[_row-moveNum] and reel_data[_row-moveNum][iCol] or blankType
        end
        --将滚动后的钻石覆盖进来
        for _index,_pos in ipairs(rapidPositions) do
            local rowColData = self:getRowAndColByPos(_pos)
            reel_data[rowColData.iX][rowColData.iY] = self.m_parent.SYMBOL_CLASSIC_SCORE_Rapid
        end
    end
    return reel_data
end
--播放赢钱线动画
function MagicSpiritClassicSlots:playWinCoinLineAction()
    if(not self.m_winCoinLine)then
        self.m_winCoinLine = util_createAnimation("MagicSpirit_classic_zhongjiangxian.csb")
        self:findChild("Node_zhongjiangxian"):addChild(self.m_winCoinLine)
    end
    self:changeWinCoinLineShow(true)
end
function MagicSpiritClassicSlots:changeWinCoinLineShow(isShow)
    if(self.m_winCoinLine)then
        self.m_winCoinLine:setVisible(isShow)
    end
end

--重置小轮盘所有小块的展示状态
function MagicSpiritClassicSlots:resetReelShowState()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            
            if node then
                node:resetReelStatus()
            end
        end
    end

end

--播放jackpot动作
function MagicSpiritClassicSlots:playFiveJackpotFadeIn()
    for _index=0,2 do
        local reel_node = self:findChild(string.format("reel_0_%d", _index))
        if(reel_node)then
            reel_node:setOpacity(0)
            reel_node:setVisible(true)
            reel_node:runAction(cc.FadeIn:create(0.5))
        end
    end
end
function MagicSpiritClassicSlots:changeFiveJackpotShow(isShow)
    for _index=0,2 do
        local reel_node = self:findChild(string.format("reel_0_%d", _index))
        if(reel_node)then
            reel_node:setVisible(isShow)
        end
    end
end
--调用主棋盘jackpot闪烁
function MagicSpiritClassicSlots:playJacjpotLight(rapids)
    --标记
    self.m_isPlayJackpotLight = true

    local curMode = self.m_parent:getCurrSpinMode()
    local isRs = curMode == RESPIN_MODE

    if isRs then
        self.m_parent:changeRespinJacjpotLight(true, rapids)
    else
        self.m_parent:changeBaseJacjpotLight(true, rapids)
    end
end
function MagicSpiritClassicSlots:hideJacjpotLight()
    if not self.m_isPlayJackpotLight then
        return
    end
    self.m_isPlayJackpotLight = false
    
    local curMode = self.m_parent:getCurrSpinMode()
    local isRs = curMode == RESPIN_MODE

    if isRs then
        self.m_parent:changeRespinJacjpotLight(false, 0)
    else
        self.m_parent:changeBaseJacjpotLight(false, 0)
    end

    
end
--
function MagicSpiritClassicSlots:playJackpotWinCoinSound()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
    local winCoin = selfData.rapidWinCoins or 5
        
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
    local bottomUi = self.m_parent.m_bottomUI

    if bottomUi  then
        soundTime = bottomUi:getCoinsShowTimes( winCoin )
    end

    local soundName = "MagicSpiritSounds/music_MagicSpirit_last_win_".. soundIndex .. ".mp3"
    self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

end
--=====一些特殊操作需要重写的父类接口
-- 解决播放两次连线后 再进行下一步展示
function MagicSpiritClassicSlots:showEffect_LineFrame(effectData)

    self:showLineFrame()
    self:reworldClassicPayTableAni()

    -- if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
    --  or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
    --     performWithDelay(self, function()
    --         effectData.p_isPlay = true
    --         self:playGameEffect()
    --     end, 0.5)
    -- else
    --     effectData.p_isPlay = true
    --     self:playGameEffect()
    -- end

    --两次连线的时间
    local twiceTime = 1* (60/60)

    performWithDelay(self, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end, twiceTime)
    --五个jackpot
    local selfDate = self.m_runSpinResultData.p_selfMakeData or {}
    local rapids = selfDate.rapids
    if rapids and rapids>=5 then
        self:playFiveJackpotFadeIn()
        self:playJacjpotLight(rapids)
        self:playJackpotWinCoinSound()
    end
    
    return true
end

--调用主棋盘paytable闪烁
function MagicSpiritClassicSlots:reworldClassicPayTableAni()
    local curMode = self.m_parent:getCurrSpinMode()
    local isRs = curMode == RESPIN_MODE
    local classicType = self.m_ClassicSymbolType
    
    local winIndex = self.m_parent:getClassicWinIndex(isRs, classicType)
    self.m_parent:reworldClassicPayTableAni(isRs, classicType, winIndex)

    --小轮盘播放赢钱线 赢钱类型不在第三行的不处理
    if( (0 < winIndex and winIndex < 8) or winIndex == 13)then
        self:playWinCoinLineAction()
    end

    --只要paytable闪烁就播连线音效
    if 0 < winIndex then
        self.m_soundId_lineFrame = gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_classic_lineFrame.mp3")
    end
end


-----底部Spin按钮相关
function MagicSpiritClassicSlots:spinBtn_normalSpinStart()
    local spinBtn = self.m_parent.m_bottomUI:getSpinBtn()
    spinBtn:normalSpinStart()
end
function MagicSpiritClassicSlots:spinBtn_normalSpinRecv()
    local spinBtn = self.m_parent.m_bottomUI:getSpinBtn()
    spinBtn:normalSpinRecv()
end
--数据返回开启点击
function MagicSpiritClassicSlots:spinBtn_updateBtnStatus(touchEnable)
    local spinBtn = self.m_parent.m_bottomUI:getSpinBtn()
    spinBtn:updateBtnStatus({SpinBtn_Type.BtnType_Stop, touchEnable})
end

return MagicSpiritClassicSlots
