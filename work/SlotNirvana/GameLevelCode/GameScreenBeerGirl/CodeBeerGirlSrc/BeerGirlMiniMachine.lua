---
-- xcyy
-- 2018-12-18 
-- BeerGirlMiniMachine.lua
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


local BeerGirlMiniMachine = class("BeerGirlMiniMachine", BaseMiniFastMachine)

BeerGirlMiniMachine.SYMBOL_Blank = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7  -- 100 
BeerGirlMiniMachine.SYMBOL_JackPot_Grand = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8  -- 101 
BeerGirlMiniMachine.SYMBOL_JackPot_Major = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- 102 
BeerGirlMiniMachine.SYMBOL_JackPot_Minor = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10  -- 103 
BeerGirlMiniMachine.SYMBOL_JackPot_Mini = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11  -- 104 


BeerGirlMiniMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 
BeerGirlMiniMachine.EFFECT_TYPE_TEN_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 2 
BeerGirlMiniMachine.EFFECT_TYPE_FAST_WIN = GameEffect.EFFECT_SELF_EFFECT - 3 


BeerGirlMiniMachine.m_machineIndex = nil -- csv 文件模块名字

BeerGirlMiniMachine.gameResumeFunc = nil
BeerGirlMiniMachine.gameRunPause = nil



local Three_Five_Reels = 1
local Four_Five_Reels = 2
-- 构造函数
function BeerGirlMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)


    
end

function BeerGirlMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function BeerGirlMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function BeerGirlMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BeerGirl"
end

function BeerGirlMiniMachine:getlevelConfigName( )
    local levelConfigName = "LevelBeerGirlMiniConfig.lua"

    return levelConfigName

end

function BeerGirlMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function BeerGirlMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil


    if symbolType == self.SYMBOL_Blank then
        return "BeerGirl_blank"  
        
    elseif symbolType == self.SYMBOL_JackPot_Grand then
        return "BeerGirl_grand"  
    elseif symbolType == self.SYMBOL_JackPot_Major then
        return "BeerGirl_major"  
    elseif symbolType == self.SYMBOL_JackPot_Minor then
        return "BeerGirl_minor"  
    elseif symbolType == self.SYMBOL_JackPot_Mini then
        return "BeerGirl_mini"  

    end  
    return ccbName
end


--[[
    @desc: 读取轮盘配置信息
    time:2020-07-11 18:55:11
]]
function BeerGirlMiniMachine:readReelConfigData()
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter 
    self.m_validLineSymNum = self.m_configData.p_validLineSymNum --触发sf，bonus需要的数量
    self:setReelEffect(self.m_configData.p_reelEffectRes)--配置快滚效果资源名称
    -- self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() or 3  --连线框播放时间
end

---
-- 读取配置文件数据
--
function BeerGirlMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(),self:getlevelConfigName())
    end
    globalData.slotRunData.levelConfigData = self.m_configData
end

function BeerGirlMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrameMinIReels" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("BeerGirl_right.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function BeerGirlMiniMachine:initMachine()
    self.m_moduleName = "BeerGirl" -- self:getModuleName()

    BaseMiniFastMachine.initMachine(self)

    self:initMiniReelsUi()

    self:addClick(self:findChild("click")) 

end

--默认按钮监听回调
function BeerGirlMiniMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        if self.m_parent then
            self.m_parent:changeBetToUnlock()
        end
        
    end


end

function BeerGirlMiniMachine:initMiniReelsUi( )
    
    self.m_fastLucyLogo = util_createView("CodeBeerGirlSrc.BeerGirlMiniReelsLogoView")
    self:findChild("logo"):addChild(self.m_fastLucyLogo)

    self:findChild("Panel_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    self:findChild("BeerGirl_right_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    self:findChild("logo"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 3)
    self:findChild("Sprite_28"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 4)
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function BeerGirlMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Blank,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JackPot_Grand,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JackPot_Major,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JackPot_Minor,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JackPot_Mini,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function BeerGirlMiniMachine:addSelfEffect()
    self.m_collectList = nil
    
    for iCol = 1, self.m_parent.m_iReelColumnNum do
        for iRow = self.m_parent.m_iReelRowNum, 1, -1 do
            local node = self.m_parent:getReelParent(iCol):getChildByTag(self.m_parent:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == self.SYMBOL_FIX_BONUS then
                    if not self.m_collectList then
                        self.m_collectList = {}
                    end
                    self.m_collectList[#self.m_collectList + 1] = node
                end
            end
        end
    end
    if self.m_collectList and #self.m_collectList > 0 then

        --收集金币
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT

    end

    self.m_collectList = {}

    local spinTimes = self.m_parent.m_runSpinResultData.p_selfMakeData.spinTimes
    if spinTimes == 10 and self.m_parent.m_FixBonusKuang and #self.m_parent.m_FixBonusKuang > 0 then
        --第十次所有框都变成wild
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_TEN_COLLECT
    end

    local lines = self.m_parent.m_runSpinResultData.p_selfMakeData.cash.lines
    if lines and #lines > 0 then
        -- 添加 fast赢钱弹板
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_FAST_WIN
    end
end


function BeerGirlMiniMachine:MachineRule_playSelfEffect(effectData)
    

    return true
end

-- 设置自定义游戏事件
function BeerGirlMiniMachine:restSelfEffect( selfEffect )
    for i = 1, #self.m_gameEffects , 1 do

        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and effectData.p_selfEffectType == selfEffect then
            
            effectData.p_isPlay = true
            self:playGameEffect()

            break
        end
        
    end
    
end



function BeerGirlMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function BeerGirlMiniMachine:checkNotifyUpdateWinCoin( )

    -- 这里作为freespin下 连线时通知钱数更新的接口

    if self.m_parent.m_runSpinResultData.p_winLines and #self.m_parent.m_runSpinResultData.p_winLines > 0 then
        
    else
        local winLines = self.m_reelResultLines

        if #winLines <= 0  then
            return
        end
        -- 如果freespin 未结束，不通知左上角玩家钱数量变化
        local isNotifyUpdateTop = true
        if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
            isNotifyUpdateTop = false
        end 
    
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_parent.m_iOnceSpinLastWin,isNotifyUpdateTop})
    end
    


end

function BeerGirlMiniMachine:slotReelDown()
    self.m_slotReelDown = true

    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        BaseMiniFastMachine.slotReelDown(self) 
        if self.m_parent  then
            self.m_parent:fastReelsWinslotReelDown()
        end
        node:removeFromParent()
    end,self.m_configData.p_reelResTime or 0)
   

    
end



---
-- 每个reel条滚动到底
function BeerGirlMiniMachine:slotOneReelDown(reelCol)
    BaseMiniFastMachine.slotOneReelDown(self,reelCol)

    -- for iRow = 2, self.m_iReelRowNum do
        local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,3,SYMBOL_NODE_TAG))
        if targSp and targSp.p_symbolType ~= self.SYMBOL_Blank  then

            gLobalSoundManager:setBackgroundMusicVolume(0)
            gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_JackPotDown.mp3")

            targSp:runAnim("buling",false,function(  )
                targSp:runAnim("idleframe",true)
            end)

        end
    -- end

end

function BeerGirlMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function BeerGirlMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent:getBetLevel() == 1 then
        self.m_parent:setNormalAllRunDown(1 )
    end



end

function BeerGirlMiniMachine:addObservers()

    BaseMiniFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
       
        local flag = params
        if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
            flag=false
        end

        self:findChild("click"):setVisible(flag)

    end,"BET_ENABLE")

end

function BeerGirlMiniMachine:quicklyStopReel(colIndex)

    if self.m_parent:getBetLevel() ~= 0 and self.m_slotReelDown ~= true then
        BaseMiniFastMachine.quicklyStopReel(self, colIndex) 
    end
    
end

function BeerGirlMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function BeerGirlMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function BeerGirlMiniMachine:beginMiniReel()
    self.m_slotReelDown = false
    BaseMiniFastMachine.beginReel(self)

end


-- 消息返回更新数据
function BeerGirlMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end


function BeerGirlMiniMachine:enterLevelMiniSelf( )

end


function BeerGirlMiniMachine:dealSmallReelsSpinStates( )
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    -- do nothing
end


-- 轮盘停止回调(自己实现)
function BeerGirlMiniMachine:setDownCallFunc(func )
    self.m_reelDownCallback = func
end

function BeerGirlMiniMachine:playEffectNotifyNextSpinCall( )
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end



-- 处理特殊关卡 遮罩层级
function BeerGirlMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

---
--设置bonus scatter 层级
function BeerGirlMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
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

function BeerGirlMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function BeerGirlMiniMachine:checkGameResumeCallFun( )
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

function BeerGirlMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function BeerGirlMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function BeerGirlMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



-- -------clasicc 轮盘处理
--绘制多个裁切区域
function BeerGirlMiniMachine:drawReelArea()
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
function BeerGirlMiniMachine:updateReelInfoWithMaxColumn()
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

function BeerGirlMiniMachine:checkRestSlotNodePos( )
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

--小块
function BeerGirlMiniMachine:getBaseReelGridNode()
    return "CodeBeerGirlSrc.BeerGirlSlotsNode"
end


return BeerGirlMiniMachine
