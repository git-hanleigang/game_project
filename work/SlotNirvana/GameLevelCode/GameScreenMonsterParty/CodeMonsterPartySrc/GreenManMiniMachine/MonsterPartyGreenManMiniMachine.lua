---
-- xcyy
-- 2018-12-18 
-- MonsterPartyGreenManMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local MonsterPartySlotFastNode = require "CodeMonsterPartySrc.MonsterPartySlotFastNode"
local SlotParentData = require "data.slotsdata.SlotParentData"

local MonsterPartyGreenManMiniMachine = class("MonsterPartyGreenManMiniMachine", BaseMiniMachine)


MonsterPartyGreenManMiniMachine.m_runCsvData = nil
MonsterPartyGreenManMiniMachine.m_machineIndex = nil -- csv 文件模块名字

MonsterPartyGreenManMiniMachine.gameResumeFunc = nil
MonsterPartyGreenManMiniMachine.gameRunPause = nil

MonsterPartyGreenManMiniMachine.m_reelMoveDownSpeed = {1, 2, 3, 3, 3,3}
MonsterPartyGreenManMiniMachine.m_reelMoveUpSpeed = {1, 1, 2, 2, 2,2}

MonsterPartyGreenManMiniMachine.m_iReelMinRow = nil
MonsterPartyGreenManMiniMachine.m_iReelMaxRow = nil
MonsterPartyGreenManMiniMachine.m_updateReelHeightID = nil
MonsterPartyGreenManMiniMachine.m_reelMoveTime = nil
MonsterPartyGreenManMiniMachine.m_DownWildList = {}

MonsterPartyGreenManMiniMachine.FS_LockWild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
function MonsterPartyGreenManMiniMachine:getBaseReelGridNode()
    return "CodeMonsterPartySrc.MonsterPartySlotFastNode"
end
-- 构造函数
function MonsterPartyGreenManMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    self.m_isOnceClipNode = false --是否只绘制一个矩形裁切 --小矮仙 袋鼠等不规则或者可变高度设置成false

    

end

function MonsterPartyGreenManMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function MonsterPartyGreenManMiniMachine:initGame()

    self.m_iReelMinRow = 3
    self.m_iReelMaxRow = 9
    self.m_reelMoveTime = 0
    self.m_DownWildList = {}
    self.m_monsterPartyClipNodeList = {}

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end

--绘制多个裁切区域-存储clipNode
function MonsterPartyGreenManMiniMachine:drawReelArea()
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

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
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

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)
        self.m_monsterPartyClipNodeList[i] = clipNode
        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()
        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
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

    -- 测试数据，看点击区域范围
    -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_touchSpinLayer:setBackGroundColorOpacity(0)
    -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    end
end

function MonsterPartyGreenManMiniMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(self.m_iReelMaxRow,self.m_iReelColumnNum,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MonsterPartyGreenManMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MonsterParty"
end

function MonsterPartyGreenManMiniMachine:getMachineConfigName()

    local str = "GreenMini"

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MonsterPartyGreenManMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType) 

    

    return ccbName
end

---
-- 读取配置文件数据
--
function MonsterPartyGreenManMiniMachine:readCSVConfigData( )
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelMonsterPartyConfig.lua")
    end
end

function MonsterPartyGreenManMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("MonsterParty_FS_reel3x5.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function MonsterPartyGreenManMiniMachine:initMachine()
    self.m_moduleName =  self:getModuleName()

    BaseMiniMachine.initMachine(self)
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function MonsterPartyGreenManMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()
   
    
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function MonsterPartyGreenManMiniMachine:addSelfEffect()




end


function MonsterPartyGreenManMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end



function MonsterPartyGreenManMiniMachine:reelDownNotifyPlayGameEffect( )
    self:playGameEffect()

    if self.m_parent then
        self.m_parent:FSReelDownNotify( self.m_maxReelIndex  )
    end
end

function MonsterPartyGreenManMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MonsterPartyGreenManMiniMachine:checkNotifyUpdateWinCoin( )

    -- 这里作为freespin下绿巨人 连线时通知钱数更新的接口

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end 

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_parent.m_serverWinCoins,isNotifyUpdateTop})


end


function MonsterPartyGreenManMiniMachine:getVecGetLineInfo( )
    return self.m_runSpinResultData.p_winLines
end


function MonsterPartyGreenManMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent then
        self.m_parent:FSReelShowSpinNotify( self.m_maxReelIndex )
    end

end

function MonsterPartyGreenManMiniMachine:quicklyStopReel(colIndex)

    
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        

        local selfData = self.m_parent.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.m_parent.FS_GAME_TYPE_m_batMan then

            

        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_wolfMan then
            
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_ghostGirl then
            
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_greenMan then
            BaseMiniMachine.quicklyStopReel(self, colIndex) 
        end
    end

    
end

function MonsterPartyGreenManMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    if self.m_updateReelHeightID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())

end



function MonsterPartyGreenManMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function MonsterPartyGreenManMiniMachine:beginMiniReel()
    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function MonsterPartyGreenManMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function MonsterPartyGreenManMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end

function MonsterPartyGreenManMiniMachine:enterLevelMiniSelf( )

    BaseMiniMachine.enterLevel(self)
    
end



function MonsterPartyGreenManMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end



-- 处理特殊关卡 遮罩层级
function MonsterPartyGreenManMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function MonsterPartyGreenManMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType ) 

end


function MonsterPartyGreenManMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function MonsterPartyGreenManMiniMachine:checkGameResumeCallFun( )
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


function MonsterPartyGreenManMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MonsterPartyGreenManMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function MonsterPartyGreenManMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 根据类型获取对应节点
--
function MonsterPartyGreenManMiniMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
        
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    reelNode:setMachine(self )
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

---
-- 清空掉产生的数据
--
function MonsterPartyGreenManMiniMachine:clearSlotoData()
    
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then

        for i=#self.m_lineDataPool,1,-1 do
            self.m_lineDataPool[i] = nil
        end

    end
end

function MonsterPartyGreenManMiniMachine:restSelfGameEffects( restType  )

    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects , 1 do

            local effectData = self.m_gameEffects[i]
    
            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return 
                end
                
            end

        end
    end
    
end

function MonsterPartyGreenManMiniMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            -- self:clearFrames_Fun()
            if frameIndex > #winLines  then
                frameIndex = 1
                if self.m_showLineHandlerID ~= nil then

                    scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                    self.m_showLineHandlerID = nil
                    self:showAllFrame(winLines)
                    self:playInLineNodes()
                    showLienFrameByIndex()
                end
                return
            end
            self:playInLineNodesIdle()
            -- 跳过scatter bonus 触发的连线
            while true do
                if frameIndex > #winLines then
                    break
                end
                -- print("showLine ... ")
                local lineData = winLines[frameIndex]

                if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                    end
                else
                    break
                end
            end
            -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
            -- 所以打上一个判断
            if frameIndex > #winLines  then
                frameIndex = 1
            end

            self:showLineFrameByIndex(winLines,frameIndex)

            frameIndex = frameIndex + 1
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    self:showAllFrame(winLines)
    if #winLines > 1 then
        showLienFrameByIndex()
    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MonsterPartyGreenManMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function MonsterPartyGreenManMiniMachine:clearCurMusicBg( )
    
end

function MonsterPartyGreenManMiniMachine:removeAllReelsNode()
    local direction = self.m_iReelMinRow - self.m_iReelRowNum
    self.m_iReelRowNum = self.m_iReelMinRow

    if direction ~= 0 then
        self:setMinReelLength()
    end
    
    self:stopAllActions()
    self:clearWinLineEffect()

    self:removeAllDownWild( )

    -- local childs = self.m_clipParent:getChildren()
    -- for iCol = 1, self.m_iReelColumnNum do
    --     for iRow = 1, self.m_iReelRowNum do
    --         local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
    --         if targSp and targSp:getParent() then
    --             targSp:removeFromParent()
    --             targSp:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    --             self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType,targSp)
    --         end
    --     end
    -- end
    
    -- self:randomSlotNodes( )
    
end


function MonsterPartyGreenManMiniMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end


    -- 网络消息已经赋值成功开始进行飞蝙蝠变信号 , 等动画的判断逻辑

    self.m_parent:greenManNetBackCheckAddAction( )
end


function MonsterPartyGreenManMiniMachine:netBackReelsStop( )

    

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end


function MonsterPartyGreenManMiniMachine:produceSlots()
    --延长滚动长度
    local reelCurrRow = #self.m_runSpinResultData.p_reels

    if reelCurrRow > self.m_iReelRowNum then
        
        for i=1,#self.m_reelRunInfo, 1 do
            local addition = 0
            local runInfo = self.m_reelRunInfo[i]
           
            --得到初始长度
            local len = runInfo:getInitReelRunLen()
            -- addition = addition + 6
            runInfo:setReelRunLen(len  + addition)
        end

    end
    if reelCurrRow ~= self.m_iReelRowNum then
        local direction = reelCurrRow - self.m_iReelRowNum
        self.m_iReelRowNum = reelCurrRow
        self:changeReelData()
    end

    BaseSlots.produceSlots(self)
end


function MonsterPartyGreenManMiniMachine:changeReelData()
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    end
end


function MonsterPartyGreenManMiniMachine:changeReelLength(direction,callfunc)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelMaxRow,true)
    end

    local oldPos = cc.p(self:getPosition())
    local actid =   self:beginShake( )

    local func = function(  )
        
        self:stopAction(actid)
        self:setPosition(oldPos)

        if callfunc then
            callfunc()
        end
    end
 
    local minPercent = math.ceil(self.m_iReelMinRow * 100 / self.m_iReelMaxRow)
    local endPercent = math.ceil((self.m_iReelMinRow + direction) * 100 / self.m_iReelMaxRow )
    local movePercent = 0
    local maxHeight = self.m_SlotNodeH * self.m_iReelMaxRow

    local scheduleDelayTime = 0.076
    local percent = 0
    if direction > 0 then

        gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_GreenMan_ReelUp.mp3")

        self.m_bIsReelStartMove = true
        movePercent = self.m_reelMoveUpSpeed[direction]
        percent = minPercent
        direction = 1
        
    else
        self.m_bIsReelStartMove = false
        percent = math.ceil((self.m_iReelMinRow - direction) * 100 / self.m_iReelMaxRow )
        endPercent = minPercent
        movePercent = self.m_reelMoveDownSpeed[-direction]
        direction = -1
        scheduleDelayTime = 0.5 * movePercent / (percent - endPercent)

    end

    local reelBGSizeY = {}
    for i=1,self.m_iReelColumnNum do
        local reelBG =  self:findChild("reel_"..i-1)
        table.insert(reelBGSizeY,reelBG:getContentSize().height)
    end
    local kuangBGSizeY = self:findChild("MonsterParty_kuang"):getContentSize().height 

    self.m_updateReelHeightID = scheduler.scheduleGlobal( function(delayTime)
        self.m_reelMoveTime = self.m_reelMoveTime + delayTime
        local distance = 0
        if direction > 0 then

            if percent + movePercent * direction > endPercent then
                distance = (endPercent - percent) * maxHeight / 100
                percent = endPercent

                if func then
                    func()
                end
                scheduler.unscheduleGlobal(self.m_updateReelHeightID)

            else
                percent = percent + movePercent * direction
                distance = movePercent * maxHeight * direction / 100
            end
        else
            if percent + movePercent * direction < minPercent then
                distance = (percent - endPercent) * maxHeight * direction / 100
                percent = minPercent
                scheduler.unscheduleGlobal(self.m_updateReelHeightID)

                if func then
                    func()
                end
            else
                percent = percent + movePercent * direction
                distance = movePercent * maxHeight * direction / 100
            end
        end
        for i = 1, self.m_iReelColumnNum, 1 do
            if not tolua.isnull(self.m_clipParent) then
                --获取裁切节点的方式修改 有崩溃出现在通过tag值获取节点的方法附近
                local clipNode = self.m_monsterPartyClipNodeList[i]
                -- local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
                local rect = clipNode:getClippingRegion()
                clipNode:setClippingRegion(
                    {
                        x = rect.x,
                        y = rect.y,
                        width = rect.width,
                        height = rect.height + distance
                    }
                )
            else
                assert(false, "MonsterPartyGreenManMiniMachine:changeReelLength|reelCol:" .. i .. "|"  .. debug.traceback())
            end
            -- self.m_reelBar[i]:setPercent(percent)

            -- self.m_reelLine[i]:setPercent(percent)
            self:findChild("reel_"..i-1):setContentSize({width= 130,height= reelBGSizeY[i] + distance })
            reelBGSizeY[i] = reelBGSizeY[i] + distance
        end

        self:findChild("MonsterParty_kuang"):setContentSize({width= 345,height= kuangBGSizeY + distance / 2 })
        kuangBGSizeY = kuangBGSizeY + distance / 2

        -- self.m_parent.m_greenMan:setPosition(self.m_parent.m_greenMan:getPositionX(), self.m_parent.m_greenMan:getPositionY() + distance)
    end, scheduleDelayTime)
end

--[[
    将裁切层设置为最小(free结束用)
]]
function MonsterPartyGreenManMiniMachine:setMinReelLength()
    local minPercent = math.ceil(self.m_iReelMinRow * 100 / self.m_iReelMaxRow)
    for i = 1, self.m_iReelColumnNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2
            
        if not tolua.isnull(self.m_clipParent) then
            --获取裁切节点的方式修改 有崩溃出现在通过tag值获取节点的方法附近
            local clipNode = self.m_monsterPartyClipNodeList[i]
            -- local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
            local sMsg = string.format("[MonsterPartyGreenManMiniMachine:setMinReelLength] 获取裁切小块 %d", i)
            util_printLog(sMsg, true)
            clipNode:setClippingRegion(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            sMsg = string.format("[MonsterPartyGreenManMiniMachine:changeReelLength] 设置裁切区域完毕 %d", i)
            util_printLog(sMsg, true)
        else
            assert(false, "MonsterPartyGreenManMiniMachine:setMinReelLength|reelCol:" .. i .. "|" .. debug.traceback())
        end
        self:findChild("reel_"..i-1):setContentSize({width= 130,height= 300})
    end
    self:findChild("MonsterParty_kuang"):setContentSize({width= 345,height= 168})
end

function MonsterPartyGreenManMiniMachine:runDownWildAct( node, func )
    
    local endPos = cc.p(node:getPosition()) 
    local addPosY = math.random(1,1200) 
    local beiginPos = cc.p(endPos.x, display.height   / self.m_parent.m_machineRootScale + addPosY)   

    node:setPosition(beiginPos)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
    end)
    actList[#actList + 1] = cc.MoveTo:create(1,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
        if func then
            func()
        end
    end)

    local sq = cc.Sequence:create(actList)
    node:runAction(sq)

end

function MonsterPartyGreenManMiniMachine:beiginAllWildDown( callfunc )

    local waittime  = 0.5
    for i=1,#self.m_DownWildList do

        local node = self.m_DownWildList[i]
        local func = nil

        if i == #self.m_DownWildList then
            func = function(  )
                if callfunc then
                    callfunc()
                end
            end
        end
        self:runDownWildAct( node, func )
    end
    
end

function MonsterPartyGreenManMiniMachine:CreateDownWild( wildList )

    for i=1,#wildList do
        local v = wildList[i]
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSpIcons = self:getPosReelIdx(fixPos.iX, fixPos.iY)

        local symbolName = self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD)
        local targSp = util_spineCreate(symbolName,true,true)

        if targSp  then 
            self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
            util_spinePlay(targSp,"idleframe")

            local position =  util_getOneGameReelsTarSpPos(self,pos )
            targSp:setPosition(cc.p(position))
            table.insert( self.m_DownWildList,targSp)
            
        end
    end
        
end

function MonsterPartyGreenManMiniMachine:restAllDownWildLayerTag( )
    self:removeAllDownWild()
end

function MonsterPartyGreenManMiniMachine:removeAllDownWild( )
    for k,wildSymbol in pairs(self.m_DownWildList) do
        wildSymbol:removeFromParent()
    end
    self.m_DownWildList = {}

end

function MonsterPartyGreenManMiniMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end


function MonsterPartyGreenManMiniMachine:beginShake( )
    local oldPos = cc.p(0,0)
  
   local action = self:shakeOneNodeForever( oldPos ,self,function(  ) 
    end)

    return action
end

function MonsterPartyGreenManMiniMachine:shakeOneNodeForever( oldPos ,node,func)

    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )

        if func then
            func()
        end
        -- changePosY = math.random( 130,300 )
    end)
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX ,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    node:runAction(action)
    return action
end

function MonsterPartyGreenManMiniMachine:shakeMachineNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(0,0)
    
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    local seq2=cc.Sequence:create(actionList2)
    self:runAction(seq2)

end

---
-- 每个reel条滚动到底
function MonsterPartyGreenManMiniMachine:slotOneReelDown(reelCol)
    return MonsterPartyGreenManMiniMachine.super.slotOneReelDown(self,reelCol)
end

function MonsterPartyGreenManMiniMachine:slotReelDown( )
    local selfdata = self.m_parent.m_runSpinResultData.p_selfMakeData or {}
    local wildShape = selfdata.wildShape or {}
    for i=1,#wildShape do
        local v = wildShape[i]
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(fixPos.iY,fixPos.iX)
        if symbolNode and symbolNode.p_symbolType then
            self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD)
        end
    end
    for k,wildSymbol in pairs(self.m_DownWildList) do
        wildSymbol:setVisible(false)
    end
    MonsterPartyGreenManMiniMachine.super.slotReelDown(self)
end

--[[
    变更小块信号值
]]
function MonsterPartyGreenManMiniMachine:changeSymbolType(symbolNode,symbolType)
    if symbolNode then
        if symbolNode.p_symbolImage then
            symbolNode.p_symbolImage:removeFromParent()
            symbolNode.p_symbolImage = nil
        end

        local parentData = self.m_slotParents[symbolNode.p_cloumnIndex]
        if not symbolNode.m_baseNode then
            symbolNode.m_baseNode = parentData.slotParent
        end

        if not symbolNode.m_topNode then
            symbolNode.m_topNode = parentData.slotParentBig
        end

        local symbolName = self:getSymbolCCBNameByType(self,symbolType)
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType), symbolType)
        symbolNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self,symbolType))

        local zOrder = self:getBounsScatterDataZorder(symbolType)
        symbolNode.p_symbolType = symbolType
        symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
        symbolNode.m_isInTop = false
        symbolNode:putBackToPreParent()
        symbolNode:setLocalZOrder(symbolNode.p_showOrder)
    end
end

return MonsterPartyGreenManMiniMachine
