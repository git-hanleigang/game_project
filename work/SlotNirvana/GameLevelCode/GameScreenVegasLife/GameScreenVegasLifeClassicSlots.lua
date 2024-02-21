---
-- island li
-- 2019年1月26日
-- GameScreenVegasLifeClassicSlots.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = util_require("Levels.BaseMachine")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local GameScreenVegasLifeClassicSlots = class("GameScreenVegasLifeClassicSlots", BaseSlotoManiaMachine)

GameScreenVegasLifeClassicSlots.SYMBOL_CLASSIC_SCORE_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
GameScreenVegasLifeClassicSlots.SYMBOL_CLASSIC_SCORE_7 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2 --10
GameScreenVegasLifeClassicSlots.SYMBOL_CLASSIC_SCORE_7L = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3 --11
GameScreenVegasLifeClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_3 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 4 --12
GameScreenVegasLifeClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_2 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 5 --13
GameScreenVegasLifeClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_1 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 6 --14

GameScreenVegasLifeClassicSlots.SYMBOL_CLASSIC_SCORE_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7

-- 这个wild成倍信号数值是跟普通轮盘start信号是一样的
GameScreenVegasLifeClassicSlots.SYMBOL_WILD_x1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9 --102
GameScreenVegasLifeClassicSlots.SYMBOL_WILD_x2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 --103
GameScreenVegasLifeClassicSlots.SYMBOL_WILD_x3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 --104
GameScreenVegasLifeClassicSlots.SYMBOL_WILD_x5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 --105

GameScreenVegasLifeClassicSlots.Classic_GameStates_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10 -- 自定义动画的标识

GameScreenVegasLifeClassicSlots.m_winSoundTime = 2
-- 构造函数
function GameScreenVegasLifeClassicSlots:ctor()
    --classic滚动之前的盘面 初始化用
    self.m_classicTemReelData = {
        {{11,14,13},{100,100,100},{95,95,95},{100,100,100},{10,12,11}},
        {{11,14,13},{100,100,100},{103,103,103},{100,100,100},{10,12,11}},
        {{11,14,13},{100,100,100},{104,104,104},{100,100,100},{10,12,11}},
        {{11,14,13},{100,100,100},{105,105,105},{100,100,100},{10,12,11}},
        {{11,14,13},{100,100,100},{103,104,105},{100,100,100},{10,12,11}},
    }
    -- 当前应该显示哪种classic初始界面 即哪种bonus base棋盘每列只能出现一种bonus
    self.showCol = 1

    -- 假滚的时候 不同列对应不同的wild
    self.reelAllList = {{self.SYMBOL_WILD_x1},{self.SYMBOL_WILD_x2},{self.SYMBOL_WILD_x3},{self.SYMBOL_WILD_x5},{self.SYMBOL_WILD_x2,self.SYMBOL_WILD_x3,self.SYMBOL_WILD_x5}}

    GameScreenVegasLifeClassicSlots.super.ctor(self)
end

function GameScreenVegasLifeClassicSlots:initData_(data)
    self.m_parent = data.parent
    self.m_callFunc = data.func
    self.m_effectData = data.effectData
    self.m_uiHeight = data.height
    self.m_iBetLevel = data.betlevel
    self.m_parentWinResult = data.parentResultData
    self.m_bonusCol = data.col
    self.showCol = self.m_bonusCol
    self:initGame()
end

function GameScreenVegasLifeClassicSlots:enterGamePlayMusic(  )
end
function GameScreenVegasLifeClassicSlots:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("VegasLife_ClassicConfig.csv", "LevelVegasLifeClassicConfig.lua")

	--初始化基本数据
	self:initMachine()

end

function GameScreenVegasLifeClassicSlots:initMachine( )

    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName

    self:createCsbNode("VegasLife_ClassicBorad" .. self.m_bonusCol .. ".csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
    self:updateBaseConfig()
    
    self:updateMachineData()
    self:initMachineData()
    self:initSymbolCCbNames()

    self:drawReelArea()

    self:updateReelInfoWithMaxColumn()
    self:initReelEffect()
    self:stopOrBeginLiZi(false)

    self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
    ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
    ,self.m_configData.p_bPlayBonusAction)
end

--关闭 开启粒子
function GameScreenVegasLifeClassicSlots:stopOrBeginLiZi(_isVisible)
    local lizi1 =  self:findChild("Particle_5")
    local lizi2 =  self:findChild("Particle_5_0")
    local lizi3 =  self:findChild("Particle_5_0_0")
    local lizi4 =  self:findChild("Particle_5_0_0_0")
    if _isVisible then
        lizi1:resetSystem()
        lizi2:resetSystem()
        lizi3:resetSystem()
        lizi4:resetSystem()
    else
        lizi1:stopSystem()
        lizi2:stopSystem()
        lizi3:stopSystem()
        lizi4:stopSystem()
    end
    
end
function GameScreenVegasLifeClassicSlots:initMachineData()


    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName.."_Datas"

    globalData.slotRunData.gameModuleName = self.m_moduleName

    -- 设置bet index

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    -- 配置全局信息，供外部使用
    globalData.slotRunData.levelGetAnimNodeCallFun = function(symbolType,ccbName)
                                                      return self:getAnimNodeFromPool(symbolType,ccbName)
                                                   end
    globalData.slotRunData.levelPushAnimNodeCallFun = function(animNode,symbolType)
                                                        self:pushAnimNodeToPool(animNode,symbolType)
                                                    end

    self:checkHasBigSymbol()
end

function GameScreenVegasLifeClassicSlots:startPlay(_index, _isFirst)
    local delayTime = 0
    -- 第一次classic 的spin 加1秒延时
    if _isFirst then
        delayTime = 1
    end
    self:setVisible(true)
    performWithDelay(self,function()
        performWithDelay(self,function()
            self:normalSpinBtnCall(_index)
        end,0.2 + delayTime)
    end,0.3)

    -- 20帧的时候 播放粒子
    performWithDelay(self,function()
        self:stopOrBeginLiZi(true)
    end,20/60)
    
end

function GameScreenVegasLifeClassicSlots:getSlotNodeType(_iCol,_iRow)
    
    local reeldata = self.m_classicTemReelData[self.showCol]

    local rowCount = #reeldata
    local rowDatas = reeldata[rowCount - _iRow + 1]
    if not rowDatas then
       return nil
    end
    local symbolType = rowDatas[_iCol]

    return symbolType
end

-- 小轮盘玩法处理
function GameScreenVegasLifeClassicSlots:restSlotNodeByData()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getReelParentChildNode(iCol, iRow)
            local symbolType = self:getSlotNodeType(iCol, iRow)
            if targSp then
                if symbolType ~= self.SYMBOL_CLASSIC_SCORE_EMPTY then
                    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
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

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenVegasLifeClassicSlots:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "VegasLife_Classic"
end

function GameScreenVegasLifeClassicSlots:getNetWorkModuleName()
    return self.m_parent:getNetWorkModuleName()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenVegasLifeClassicSlots:MachineRule_GetSelfCCBName(symbolType)

    if self.SYMBOL_CLASSIC_SCORE_WILD == symbolType then
        return "Socre_VegasLife_Classical_Wild"
    elseif self.SYMBOL_CLASSIC_SCORE_7 == symbolType then
        return "Socre_VegasLife_Classical_9"
    elseif self.SYMBOL_CLASSIC_SCORE_7L == symbolType then
        return "Socre_VegasLife_Classical_8"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_3 == symbolType then
        return "Socre_VegasLife_Classical_7"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_2 == symbolType then
        return "Socre_VegasLife_Classical_6"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_1 == symbolType then
        return "Socre_VegasLife_Classical_5"
    elseif self.SYMBOL_CLASSIC_SCORE_EMPTY == symbolType then
        return "Socre_VegasLife_Classical_Empty"
    elseif self.SYMBOL_WILD_x1 == symbolType then
        return "Socre_VegasLife_Classical_Wild"
    elseif self.SYMBOL_WILD_x2 == symbolType then
        return "Socre_VegasLife_Classical_2X"
    elseif self.SYMBOL_WILD_x3 == symbolType then
        return "Socre_VegasLife_Classical_3X"
    elseif self.SYMBOL_WILD_x5 == symbolType then
        return "Socre_VegasLife_Classical_5X"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameScreenVegasLifeClassicSlots:getPreLoadSlotNodes()
    local loadNode = GameScreenVegasLifeClassicSlots.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_7,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_7L,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_1,count =  2}

    return loadNode
end



function GameScreenVegasLifeClassicSlots:slotReelDown()
    GameScreenVegasLifeClassicSlots.super.slotReelDown(self)

    if self.m_spinSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_spinSoundId)
        self.m_spinSoundId = nil
    end
end

function GameScreenVegasLifeClassicSlots:reelDownNotifyChangeSpinStatus( )
end

function GameScreenVegasLifeClassicSlots:checkHasWheel( )
    for i=1,#self.m_gameEffects do
        if self.m_gameEffects[i].p_selfEffectType == self.Classic_Wheel_EFFECT then
            return true
        end
    end
    return false

end

---
-- 添加关卡中触发的玩法
--
function GameScreenVegasLifeClassicSlots:addSelfEffect()
end

function GameScreenVegasLifeClassicSlots:callSpinBtn()

    --播放点击spin音效
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPIN)

    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end


    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    self:spinBtnEnProc()

    self:setGameSpinStage( GAME_MODE_ONE_RUN )

    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function GameScreenVegasLifeClassicSlots:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.Classic_GameStates_EFFECT then
        self:ClassicGameStatesAct(effectData)
    end

	return true
end

function GameScreenVegasLifeClassicSlots:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     local showWinCoins = 0
     if self.m_runSpinResultData then
        if self.m_runSpinResultData.p_resWinCoins then
            showWinCoins = self.m_runSpinResultData.p_resWinCoins
        end
     end
    self:setLastWinCoin(showWinCoins)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,false,true,1})
end

function GameScreenVegasLifeClassicSlots:ClassicGameStatesAct( effectData)
    effectData.p_isPlay = true
    self:playGameEffect()
end
function GameScreenVegasLifeClassicSlots:playGameEffect()
    GameScreenVegasLifeClassicSlots.super.playGameEffect(self)
end
--绘制多个裁切区域
function GameScreenVegasLifeClassicSlots:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self:findChild("sp_reel_0"):getParent()
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
        clipNode:setPosition(posX - reelSize.width * 0.5, posY - high * 0.5)
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
    end
end

---
-- 获取最高的那一列
--
function GameScreenVegasLifeClassicSlots:updateReelInfoWithMaxColumn()
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
end

function GameScreenVegasLifeClassicSlots:checkRestSlotNodePos( )
    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息

        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)

        local lastType = nil
        local preRow = 0
        local maxLastNodePosY = nil
        local minLastNodePosY = nil

        local moveDis = nil
        for nodeIndex = 1, #childs do
            local childNode = childs[nodeIndex]
            if childNode.m_isLastSymbol == true then
                local childPosY = childNode:getPositionY()
                if maxLastNodePosY == nil then
                    maxLastNodePosY = childPosY
                elseif maxLastNodePosY < childPosY then
                    maxLastNodePosY = childPosY
                end

                if minLastNodePosY == nil then
                    minLastNodePosY = childPosY
                elseif minLastNodePosY > childPosY then
                    minLastNodePosY = childPosY
                end
                local columnData = self.m_reelColDatas[childNode.p_cloumnIndex]
                local nodeH = columnData.p_showGridH

                childNode:setPositionY((nodeH * childNode.p_rowIndex - nodeH * 0.5))

                if moveDis == nil then
                    moveDis = childPosY - childNode:getPositionY()
                end
            else
                --do nothing
            end

            childNode.m_isLastSymbol = false
        end

        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        local childs = slotParent:getChildren()
        for i = 1, #childs do
            local childNode = childs[i]
            if childNode.m_isLastSymbol == true then
                if childNode:getTag() < SYMBOL_NODE_TAG + BIG_SYMBOL_NODE_DIFF_TAG then
                    --将该节点放在 .m_clipParent
                    childNode:removeFromParent()
                    local posWorld =
                        slotParent:convertToWorldSpace(cc.p(childNode:getPositionX(), childNode:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    childNode:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(childNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                end
            end
        end

        -- printInfo(" xcyy %d  %d  ", parentData.cloumnIndex,parentData.symbolType)
        parentData:reset()
    end
end


---
-- 处理spin 返回结果
function GameScreenVegasLifeClassicSlots:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    
    self:checkTestConfigType(param)

    if param[1] == true then                -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else                                    -- 处理spin失败
        self:checkOpearSpinFaild(param)                            
    end
end


function GameScreenVegasLifeClassicSlots:checkOperaSpinSuccess( param )
    local spinData = param[2]
    if spinData.action == "SPIN" then
        globalData.seqId = spinData.sequenceId
        release_print("消息返回胡来了")
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        --发送测试赢钱数
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN,self.m_serverWinCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)

        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

        local preLevel =  globalData.userRunData.levelNum
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if self.m_spinIsUpgrade == true then

            local sendData = {}

            local betCoin = globalData.slotRunData:getCurTotalBet()

            sendData.exp = betCoin  * self.m_expMultiNum

            -- 存储一下VIP的原始等级
            self.m_preVipLevel = globalData.userRunData.vipLevel
            self.m_preVipPoints = globalData.userRunData.vipPoints
        end

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function GameScreenVegasLifeClassicSlots:requestSpinResult()

    local showWinCoins = self.m_parentWinResult.p_winAmount
    if self.m_runSpinResultData then
       if self.m_runSpinResultData.p_resWinCoins then
           showWinCoins = self.m_runSpinResultData.p_resWinCoins
       end
    end
    self:setLastWinCoin(showWinCoins)

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

    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, false, moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

--
-- 点击spin 按钮开始执行老虎机逻辑
--
function GameScreenVegasLifeClassicSlots:normalSpinBtnCall(_index)

    performWithDelay(self,function(  )
        BaseMachine.normalSpinBtnCall(self)
        self.m_spinSoundId = gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_classic_spin.mp3")
        if not _index then
            _index = 1
        end
        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_classic_spin_" .. _index .. ".mp3")
    end,0.5)
end


function GameScreenVegasLifeClassicSlots:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex,self.m_nowPlayCol)

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end

function GameScreenVegasLifeClassicSlots:reelSchedulerHanlder(delayTime)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or
    self:checkGameRunPause()
    then
        return
    end

    if self.m_reelDownAddTime > 0 then
        self.m_reelDownAddTime = self.m_reelDownAddTime - delayTime
    else
        self.m_reelDownAddTime = 0
    end
    local timeDown = 0
    local slotParentDatas = self.m_slotParents

    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        -- if parentData.cloumnIndex == 1 then
        -- 	printInfo(" %d ", parentData.tag)
        -- end
        local columnData = self.m_reelColDatas[index]
        local halfH = columnData.p_showGridH * 0.5

        local parentY = slotParent:getPositionY()
        if parentData.isDone == false then


            local cloumnMoveStep = self:getColumnMoveDis(parentData, delayTime)
            local newParentY = slotParent:getPositionY() - cloumnMoveStep
            if self.m_isWaitingNetworkData == false then
                if newParentY < parentData.moveDistance then
                    newParentY = parentData.moveDistance
                end
            end
            parentData.symbolType = self:filterSymbolType(parentData.symbolType)

            slotParent:setPositionY(newParentY)
            parentY = newParentY
            local childs = slotParent:getChildren()
            local zOrder, preY = self:reelSchedulerCheckRemoveNodes(childs, halfH, parentY , index)
            self:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
        end

        if self.m_isWaitingNetworkData == false then
            timeDown = self:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
        end
    end -- end for

    local isAllReelDone = function()
        for index = 1, #slotParentDatas do
            if slotParentDatas[index].isResActionDone == false then
            -- if slotParentDatas[index].isDone == false then

                return false
            end
        end
        return true
    end

    if isAllReelDone() == true then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        self:slotReelDown()

        self.m_reelDownAddTime = 0
    end
end

function GameScreenVegasLifeClassicSlots:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    self:requestSpinResult()

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage( WAITING_DATA )

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function GameScreenVegasLifeClassicSlots:dealSmallReelsSpinStates( )
    -- do nothing
end


function GameScreenVegasLifeClassicSlots:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    GameScreenVegasLifeClassicSlots.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    self:restSlotNodeByData()
end

function GameScreenVegasLifeClassicSlots:addObservers()
    GameScreenVegasLifeClassicSlots.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 1
        self.m_winSoundTime = 2

        -- 中jackpot的连线音效
        if self:cheackInTriggerJackPot() > 0 then
            soundIndex = 2
            self.m_winSoundTime = 4
        else
            if self:checkTriggerBigWin() then
                soundIndex = 3
                self.m_winSoundTime = 3

                 -- 和赢钱线一起播 ：base或free中赢钱大于3倍小于big win时；classic中赢钱大于10倍时
                local soundId1 = gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_winSound4.mp3")
                self.m_winSoundsId1 = soundId1
            else
                soundIndex = 1
                self.m_winSoundTime = 2
            end
        end

        local soundName = "VegasLifeSounds/VegasLife_classic_lastwin_".. soundIndex .. ".mp3"
        -- local soundId = globalMachineController:playBgmAndResume(soundName,self.m_winSoundTime,0.4,1)
        local soundId = gLobalSoundManager:playSound(soundName)

        performWithDelay(self,function()
            -- gLobalSoundManager:stopAudio(soundId)
            soundId = nil
        end,self.m_winSoundTime)
        self.m_winSoundsId = soundId

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function GameScreenVegasLifeClassicSlots:MachineRule_SpinBtnCall()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    if self.m_winSoundsId1 then
        gLobalSoundManager:stopAudio(self.m_winSoundsId1)
        self.m_winSoundsId1 = nil
    end

    return false
end

function GameScreenVegasLifeClassicSlots:symbolNodeAnimation(animation)
    for reelCol = 1, self.m_iReelColumnNum, 1 do
        local parent = self:getReelParent(reelCol)
        local children = parent:getChildren()
        for i = 1, #children, 1 do
            local child = children[i]
            child:runAnim(animation)
        end
        -- local symbolNode =  self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, 1, SYMBOL_NODE_TAG))

    end
end


function GameScreenVegasLifeClassicSlots:playEffectNotifyNextSpinCall( )
    -- 播两遍连线动画在结束 48/30
    local delayTime = 48/30
    if self:cheackInTriggerJackPot() > 0 then
        delayTime = 48/30
    else
        if self:checkTriggerBigWin() then
            delayTime = 46/30 * 2
        else
            delayTime = 48/30
        end
    end

    performWithDelay(self,function()
        
        local classicEndFun = function()
            self:runCsbAction("over",false,function()
            end)
            --停止连线动画     
            self:resetReelShowState()
            local winCount = 0
            if self.m_runSpinResultData then
                if self.m_runSpinResultData.p_resWinCoins then
                    winCount = self.m_runSpinResultData.p_resWinCoins
                end
            end
            if self.m_callFunc then
                self.m_callFunc(winCount, self.m_bonusCol)
                self.m_callFunc = nil
            end
        end

        -- 显示jackpot
        self:showJackPot(classicEndFun)
        
    end,delayTime)
end

--重置小轮盘所有小块的展示状态
function GameScreenVegasLifeClassicSlots:resetReelShowState()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            
            if node then
                node:resetReelStatus()
            end
        end
    end

end
-- 根据类型获取对应节点
--
function GameScreenVegasLifeClassicSlots:getSlotNodeBySymbolType(symbolType)
    local reelNode =  SlotsNode:create()
    reelNode:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
    symbolType = self:filterSymbolType(symbolType)

    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    -- print("hhhhh~ "..ccbName)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)

    return reelNode
end


function GameScreenVegasLifeClassicSlots:playEffectNotifyChangeSpinStatus( )

end

----构造respin所需要的数据
function GameScreenVegasLifeClassicSlots:reateReelNodeInfo()
    local reelNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)

            local addScale = 0

            if display.height > 1500 then
                addScale = (display.height - 1500) * 0.001

            end

            pos.x = pos.x + reelWidth / 2 * (self.m_machineRootScale + addScale)

            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH

            pos.y = pos.y + (iRow - 0.5) * slotNodeH * (self.m_machineRootScale + addScale)

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
            reelNodeInfo[#reelNodeInfo + 1] = symbolNodeInfo
        end
    end
    return reelNodeInfo
end

function GameScreenVegasLifeClassicSlots:showLineFrameByIndex(winLines,frameIndex)
    if winLines[1].iLineIdx then
        if winLines[1].iLineIdx > 0 and winLines[1].iLineIdx < 9 then
            
            -- 连线ID为1 表示三个wild 会触发jackpot
            if winLines[1].iLineIdx == 1 then
                self.m_parent:showClassicLineAction(winLines[1].iLineIdx)
                self.m_parent:showClassicJackPotAction(self.m_bonusCol)
                self:runCsbAction("actionframe",true)
            else
                if self:checkTriggerBigWin() then
                    self:runCsbAction("actionframe",false)
                    self.m_parent:showClassicLineAction(winLines[1].iLineIdx, true)
                else
                    self.m_parent:showClassicLineAction(winLines[1].iLineIdx)
                end
            end
        end
    end
end

function GameScreenVegasLifeClassicSlots:checkFeatureOverTriggerBigWin( winAmonut , feature)
    if winAmonut == nil then
        return
    end
end

function GameScreenVegasLifeClassicSlots:addLastWinSomeEffect() -- add big win or mega win
    if #self.m_vecGetLineInfo == 0 then
        return
    end
end

function GameScreenVegasLifeClassicSlots:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    GameScreenVegasLifeClassicSlots.super.onExit(self) -- 必须调用不予许删除

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function GameScreenVegasLifeClassicSlots:checkAddQuestDoneEffectType( )
end

function GameScreenVegasLifeClassicSlots:checkControlerReelType( )
    return false
end

function GameScreenVegasLifeClassicSlots:initHasFeature( )
    self:checkUpateDefaultBet()
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    
    self:initCloumnSlotNodesByNetData()
end

function GameScreenVegasLifeClassicSlots:initNoneFeature( )
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetActivityDataByRef(ACTIVITY_REF.Quest)
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end

    self:checkUpateDefaultBet()

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:initRandomSlotNodes()
end

-- 每一列都是不同的滚轮 对应不同倍数的wild 假滚的时候要特殊处理成对应列的 wild
function GameScreenVegasLifeClassicSlots:filterSymbolType(symbolType)
    if symbolType ==  self.SYMBOL_CLASSIC_SCORE_WILD or symbolType == self.SYMBOL_WILD_x1 or symbolType == self.SYMBOL_WILD_x2 or symbolType == self.SYMBOL_WILD_x3 or symbolType == self.SYMBOL_WILD_x5 then
        local temp = self.reelAllList[self.showCol]
        local has = false
        for i=1,#temp do
            if symbolType == temp[i] then
                has = true
                break
            end
        end
        if not has then
            symbolType = temp[math.random(1, #temp)]
        end
    end
    return symbolType
end

-- 是否触发jackpot
function GameScreenVegasLifeClassicSlots:cheackInTriggerJackPot( )
    local jpScore = 0
    local result = self.m_runSpinResultData.p_winLines
    for i, _line in ipairs(result) do
        if _line.p_id == 1 then
            jpScore = _line.p_amount
            break
        end
    end
    return jpScore
end
-- 显示classic的jackpot弹板
function GameScreenVegasLifeClassicSlots:showJackPot(_fun)
    -- 赢钱线ID为1 表示jackpot
    local jpScore = self:cheackInTriggerJackPot()

    if jpScore > 0 then
        -- 3秒之后显示 弹板， 上面播两遍连线 时间为48/30，所有在这在延时42/30
        performWithDelay(self,function()
            self:runCsbAction("idle2")
            self.m_parent:showClassicJackPot(jpScore, self.m_bonusCol, _fun)
        end,42/30)
        
    else
        if _fun then
            _fun()
        end
    end
end

function GameScreenVegasLifeClassicSlots:showViewFadeOut(time)
    util_setCascadeOpacityEnabledRescursion(self, true)
    util_setCascadeColorEnabledRescursion(self, true)
    self:runAction(cc.FadeOut:create(time))
end

-- 播放在线上的SlotsNode 动画
--
function GameScreenVegasLifeClassicSlots:playInLineNodes()

    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            -- 大于0表示触发jackpot
            if self:cheackInTriggerJackPot() > 0 then
                slotsNode:runLineAnim()
            else
                if self:checkTriggerBigWin() then
                    slotsNode:runAnim("actionframe2",true)
                else
                    slotsNode:runLineAnim()
                end
            end

            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()) )
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function GameScreenVegasLifeClassicSlots:checkTriggerBigWin()
    if self.m_runSpinResultData.p_winAmount == nil then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = self.m_runSpinResultData.p_winAmount / lTatolBetNum
    local winEffect = nil
    -- 策划定的10倍 算大赢
    if winRatio >= 10 then
        return true
    else
        return false
    end

end

return GameScreenVegasLifeClassicSlots






