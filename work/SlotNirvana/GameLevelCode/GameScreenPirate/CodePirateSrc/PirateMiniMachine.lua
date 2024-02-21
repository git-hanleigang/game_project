---
-- xcyy
-- 2018-12-18
-- PirateMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local PirateSlotsNode = require "CodePirateSrc.PirateSlotsNode"

local PirateMiniMachine = class("PirateMiniMachine", BaseMiniFastMachine)

PirateMiniMachine.SYMBOL_Blank = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 908 -- 1001
PirateMiniMachine.SYMBOL_JackPot_Mini = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 909 -- 1002
PirateMiniMachine.SYMBOL_JackPot_Minor = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 910 -- 1003
PirateMiniMachine.SYMBOL_JackPot_Major = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 911 -- 1004
PirateMiniMachine.SYMBOL_JackPot_Grand = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 912 -- 1005
PirateMiniMachine.SYMBOL_JackPot_Symbol = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 913 -- 1006

PirateMiniMachine.EFFECT_TYPE_SHOW_JACKPOT = GameEffect.EFFECT_SELF_EFFECT - 4

PirateMiniMachine.m_runCsvData = nil
PirateMiniMachine.m_machineIndex = nil -- csv 文件模块名字

PirateMiniMachine.gameResumeFunc = nil
PirateMiniMachine.gameRunPause = nil
PirateMiniMachine.m_slotReelDown = nil

local Three_Five_Reels = 1
local Four_Five_Reels = 2
-- 构造函数
function PirateMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)
end

function PirateMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent
    --滚动节点缓存列表
    self.cacheNodeMap = {}
    self.m_TypeIndex = 1
    --init
    self:initGame()
end

function PirateMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function PirateMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Pirate"
end

function PirateMiniMachine:getlevelConfigName()
    local levelConfigName = "LevelPirateMiniConfig.lua"

    return levelConfigName
end

function PirateMiniMachine:getMachineConfigName()
    local str = "Mini"

    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function PirateMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_Blank then
        return "Pirate_FastLuck_blank"
    elseif symbolType == self.SYMBOL_JackPot_Grand then
        return "Pirate_FastLuck_grand"
    elseif symbolType == self.SYMBOL_JackPot_Major then
        return "Pirate_FastLuck_major"
    elseif symbolType == self.SYMBOL_JackPot_Minor then
        return "Pirate_FastLuck_minor"
    elseif symbolType == self.SYMBOL_JackPot_Mini then
        return "Pirate_FastLuck_mini"
    elseif symbolType == self.SYMBOL_JackPot_Symbol then
        return "Pirate_FastLuck"
    end
    return ccbName
end

---
-- 读取配置文件数据
--
-- function PirateMiniMachine:readCSVConfigData( )
--     if self.m_configData == nil then
--         self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
--     end
--     globalData.slotRunData.levelConfigData = self.m_configData
-- end

---
-- 读取配置文件数据
--
function PirateMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), self:getlevelConfigName())
    end
    globalData.slotRunData.levelConfigData = self.m_configData
end

function PirateMiniMachine:initMachineCSB( )
    self:createCsbNode("Pirate_FastLuckReel.csb")
    self:runCsbAction("idle",true)
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
end
--
---
--
function PirateMiniMachine:initMachine()
    self.m_moduleName = "Pirate" -- self:getModuleName()

    BaseMiniFastMachine.initMachine(self)
    self:initMiniReelsUi()

    -- self:addClick(self:findChild("click"))
end
function PirateMiniMachine:initUI()  
end
--默认按钮监听回调
function PirateMiniMachine:clickFunc(sender)
    -- local name = sender:getName()
    -- local tag = sender:getTag()
    -- if name == "click" then
    --     if self.m_parent then
    --         self.m_parent:changeBetToUnlock()
    --     end
    -- end
end

function PirateMiniMachine:initMiniReelsUi()
    -- self.m_fastLucyLogo = util_createView("CodePirateSrc.PirateMiniReelsLogoView")
    -- self:findChild("logo"):addChild(self.m_fastLucyLogo)
    -- self:findChild("Panel_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    -- self:findChild("Pirate_right_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    -- self:findChild("logo"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 3)
    -- self:findChild("Sprite_28"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 4)
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function PirateMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Blank, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Grand, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Major, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Minor, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Mini, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Symbol, count = 1}
    
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------
function PirateMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function PirateMiniMachine:checkNotifyUpdateWinCoin()
    -- 这里作为freespin下 连线时通知钱数更新的接口

    if self.m_parent.m_runSpinResultData.p_winLines and #self.m_parent.m_runSpinResultData.p_winLines > 0 then
    else
        local winLines = self.m_reelResultLines

        if #winLines <= 0 then
            return
        end
        -- 如果freespin 未结束，不通知左上角玩家钱数量变化
        local isNotifyUpdateTop = true
        if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
            isNotifyUpdateTop = false
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_parent.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

-- function PirateMiniMachine:slotReelDown()
--     -- BaseMiniFastMachine.slotReelDown(self)
--     print("------------------------------------------------------------")
--     print("--------------------PirateMiniMachine-----------------------")
--     print("------------------------------------------------------------")
--     if self.m_slotReelDown == true then
--         return
--     end
--     self.m_slotReelDown = true
--     self:setGameSpinStage( STOP_RUN )
--     self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

--     -- 清理之前数据
--     local slotsList = self.m_reelSlotsList
--     local listLen = #slotsList
--     for i = 1, listLen do
--         local columnDatas = slotsList[i]

--         for dataIndex = #columnDatas, 1, -1 do
--             local reelData = columnDatas[dataIndex]

--             if reelData == nil or tolua.type(reelData) == "number" then
--                 -- do nothing
--             else
--                 reelData:clear()
--                 self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
--             end

--             columnDatas[dataIndex] = nil
--         end
--     end -- end for i = 1,listLen

--     if self.m_reelResultLines and #self.m_reelResultLines > 0 then
--         for i = #self.m_reelResultLines, 1, -1 do
--             local value = self.m_reelResultLines[i]

--             value:clean()
--             self.m_reelResultLines[i] = nil

--             self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
--         end
--     elseif self.m_reelResultLines == nil then
--         self.m_reelResultLines = {}
--     end


--     self:checkRestSlotNodePos( )

--     print("滚动结束了....")
--     -- self:reelDownNotifyChangeSpinStatus()

--     self:delaySlotReelDown()
--     self:stopAllActions()
--     if self.m_parent then
--         self.m_parent:fastReelsWinslotReelDown()
--     end
-- end
function PirateMiniMachine:slotReelDown()
    self.m_slotReelDown = true
    BaseMiniFastMachine.slotReelDown(self) 

    if self.m_parent  then
        self.m_parent:fastReelsWinslotReelDown()
    end

    
end
---
-- 每个reel条滚动到底
function PirateMiniMachine:slotOneReelDown(reelCol)
    BaseMiniFastMachine.slotOneReelDown(self, reelCol)
   
    local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, 3, SYMBOL_NODE_TAG))
    if targSp and targSp.p_symbolType ~= self.SYMBOL_Blank then
        -- gLobalSoundManager:playSound("PirateSounds/Pirate_JackPotDown.mp3")
        local index= targSp.p_symbolType - self.SYMBOL_Blank 
        self.m_TypeIndex = index
        local targSp = self:setSymbolToClipReel(reelCol,3,targSp.p_symbolType)
        targSp:runAnim("buling" .. self.m_TypeIndex,false,function(  )
            -- symbolEffect:runAnim("actionframe",false)
        end)

        local soundPath = "PirateSounds/sound_pirate_scatter2.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end


    end
 
end

function PirateMiniMachine:playWinJackpotEffect( )
    local targSp = self:getReelParent(1):getChildByTag(self:getNodeTag(1, 3, SYMBOL_NODE_TAG))
    local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(1 , 3, SYMBOL_NODE_TAG))
    if not targSp then
        targSp = clipSp
    end
    if targSp ~= nil then
        local index= targSp.p_symbolType - self.SYMBOL_Blank 
        targSp:runAnim("actionframe" .. index ,false,function()
        end )  
        performWithDelay(
            self,
            function()
                self:runCsbAction("idle",true)
            end,
            2
        )
        gLobalSoundManager:playSound("PirateSounds/sound_pirate_jackpot_win.mp3") 
    end
end


function PirateMiniMachine:playWinEffect( )
    self:runCsbAction("win",true)
end

function PirateMiniMachine:setSymbolToClipReel(_iCol,_iRow,_type)
    local targSp = self:getReelParent(_iCol):getChildByTag(self:getNodeTag(_iCol, _iRow, SYMBOL_NODE_TAG))
    local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(_iCol , _iRow, SYMBOL_NODE_TAG))
    if not targSp then
        targSp = clipSp
    end
    if targSp ~= nil then
        targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_JackPot_Symbol), self.SYMBOL_JackPot_Symbol)
        targSp.p_symbolType = _type
    end
    return targSp
end

function PirateMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function PirateMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:setNormalAllRunDown(1 )
end


function PirateMiniMachine:addObservers()
    BaseMiniFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            local flag = params
            if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
                flag = false
            end

            -- self:findChild("click"):setVisible(flag)
        end,
        "BET_ENABLE"
    )
end

function PirateMiniMachine:quicklyStopReel(colIndex)
    if self.m_runSpinResultData.p_winLines ~= nil and #self.m_runSpinResultData.p_winLines > 0 then
        return
    end
    if self:isVisible() and self.m_slotReelDown ~= true then 
        BaseMiniFastMachine.quicklyStopReel(self, colIndex)
        -- if self.m_parent:getBetLevel() ~= 0 then
        --     BaseMiniFastMachine.quicklyStopReel(self)
        -- end
    end
end

function PirateMiniMachine:onExit()
    PirateMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


function PirateMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

function PirateMiniMachine:beginMiniReel()
    BaseMiniFastMachine.beginReel(self)
    self.m_slotReelDown = false
end

-- 消息返回更新数据
function PirateMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:updateNetWorkData()
end

function PirateMiniMachine:enterLevel()
    BaseMiniFastMachine.enterLevel(self)
end

function PirateMiniMachine:enterLevelMiniSelf()
end

function PirateMiniMachine:dealSmallReelsSpinStates( )
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
end

-- 轮盘停止回调(自己实现)
function PirateMiniMachine:setDownCallFunc(func)
    self.m_reelDownCallback = func
end

function PirateMiniMachine:playEffectNotifyNextSpinCall()
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

-- 处理特殊关卡 遮罩层级
function PirateMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
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

---
--设置bonus scatter 层级
function PirateMiniMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
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

function PirateMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function PirateMiniMachine:checkGameResumeCallFun( )
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


function PirateMiniMachine:showEffect_LineFrame(effectData)


    effectData.p_isPlay = true
    self:playGameEffect()

    return true

end

function PirateMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function PirateMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function PirateMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- -------clasicc 轮盘处理
--绘制多个裁切区域
function PirateMiniMachine:drawReelArea()
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
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() -- cc.LayerColor:create(cc.c4f(r,g,b,200))  --

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
function PirateMiniMachine:updateReelInfoWithMaxColumn()
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

function PirateMiniMachine:checkRestSlotNodePos()
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
                    local posWorld = slotParent:convertToWorldSpace(cc.p(childNode:getPositionX(), childNode:getPositionY()))
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



--小块
function PirateMiniMachine:getBaseReelGridNode()
    return "CodePirateSrc.PirateSlotsNode"
end

return PirateMiniMachine
