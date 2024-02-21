---
-- xcyy
-- 2018-12-18 
-- ChicEllaMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local ChicEllaMiniMachine = class("ChicEllaMiniMachine", BaseMiniMachine)


ChicEllaMiniMachine.gameResumeFunc = nil
ChicEllaMiniMachine.gameRunPause = nil



local Main_Reels = 1


-- 构造函数
function ChicEllaMiniMachine:ctor()
    ChicEllaMiniMachine.super.ctor(self)

    self.m_slideSymbol = {
        {},{},{},{},{}
    }
end

function ChicEllaMiniMachine:initData_( machine )
    self.m_randomSymbolSwitch = true
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    -- self.m_parent = data.parent 
    -- self.m_maxReelIndex = data.maxReelIndex 


    self.m_machine = machine
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    self.m_isInitSymbol = false
    self.m_isStopSign = false
    self.m_isStopSignFirst = true
    
    --init
    self:initGame()
    
end

function ChicEllaMiniMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

    
end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function ChicEllaMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ChicElla"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function ChicEllaMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    -- local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return nil
end

---
-- 读取配置文件数据
--
function ChicEllaMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData("ChicEllaMiniConfig.csv")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function ChicEllaMiniMachine:initMachineCSB( )
    -- self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("ChicElla/GameScreenChicEllaColumn.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function ChicEllaMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    ChicEllaMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function ChicEllaMiniMachine:addSelfEffect()


    -- -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 7
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.BONUS_FS_WILD_LOCK_EFFECT -- 动画类型
 
end


function ChicEllaMiniMachine:MachineRule_playSelfEffect(effectData)
    
    -- if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT  then
        
    -- end

    return true
end




function ChicEllaMiniMachine:onEnter()
    ChicEllaMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self:setSwallowTouches(false)
end



function ChicEllaMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function ChicEllaMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function ChicEllaMiniMachine:quicklyStopReel(colIndex)


end

function ChicEllaMiniMachine:onExit()
    -- 清slotnode引用  ccbnode会在clear中清除
    for k, slotNode in ipairs(self.m_slideSymbol[1]) do
        util_resetChildReferenceCount(slotNode)
    end
    


    ChicEllaMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())


    if self.m_moveHandler then
        scheduler.unscheduleGlobal(self.m_moveHandler)
        self.m_moveHandler = nil
    end
end

function ChicEllaMiniMachine:removeObservers()
    ChicEllaMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function ChicEllaMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function ChicEllaMiniMachine:beginMiniReel()
    -- self.m_addSounds = {}
    -- ChicEllaMiniMachine.super.beginReel(self)

end


-- 消息返回更新数据
-- function ChicEllaMiniMachine:netWorkCallFun(spinResult)

--     self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

--     self:updateNetWorkData()
-- end

function ChicEllaMiniMachine:dealSmallReelsSpinStates( )
    
end



-- 处理特殊关卡 遮罩层级
function ChicEllaMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function ChicEllaMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_machine:getBounsScatterDataZorder(symbolType )

end



function ChicEllaMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function ChicEllaMiniMachine:checkGameResumeCallFun( )
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

function ChicEllaMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function ChicEllaMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function ChicEllaMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



---
-- 清空掉产生的数据
--
function ChicEllaMiniMachine:clearSlotoData()
    
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

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function ChicEllaMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function ChicEllaMiniMachine:clearCurMusicBg( )
    
end


function ChicEllaMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()

end

function ChicEllaMiniMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    -- local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    -- local hasFeature = self:checkHasFeature()

    -- if hasFeature == false then
    --     self:initNoneFeature()
    -- else
    --     self:initHasFeature()
    -- end

    -- self:addRewaedFreeSpinStartEffect()
    -- self:addRewaedFreeSpinOverEffect()

    -- if isPlayGameEffect or #self.m_gameEffects > 0 then
    --     self:sortGameEffects()
    --     self:playGameEffect()
    -- end
end

-- 自身逻辑

-- 初始化
function ChicEllaMiniMachine:initSlideSymbol()
    self.m_slideSymbol = {}

    local maxRow = self.m_iReelRowNum + 1
    for iCol=1,5 do
        while true
        do
            if iCol ~= 1 then
                local parentNode = self:findChild( string.format("sp_reel_%d", iCol-1) )
                parentNode:setVisible(false)
                local parentNodeBase = self:findChild( string.format("base_reel_%d", iCol-1) )
                parentNodeBase:setVisible(false)
                break
            else
                self.m_maskAction = {}
                for col = 1,1 do
                    --添加半透明遮罩
                    local parentData = self.m_slotParents[col]
                    local mask = cc.LayerColor:create(cc.c3b(0, 0, 0), parentData.reelWidth - 1 , parentData.reelHeight)
                    mask:setOpacity(100)
                    mask:setPositionX(parentData.reelWidth/2)
                    parentData.slotParent:addChild(mask,REEL_SYMBOL_ORDER.REEL_ORDER_4)
                    table.insert(self.m_maskAction,mask)
                    mask:setVisible(false)
                    self:reelShowMaskAction(0.5)
                end
            end

            self.m_slideSymbol[iCol] = {}
            for iRow=1, maxRow do
                self:createSlideSymbol(iCol, iRow)
            end


            break
        end
        
    end

end
-- 创建
function ChicEllaMiniMachine:createSlideSymbol(_iCol, _iRow)
    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1   -- 初始score1

    local slideSymbol = self.m_machine:getSlotNodeBySymbolType(symbolType)
    local parentNode = self:findChild( string.format("sp_reel_%d", _iCol-1) )
    parentNode:addChild(slideSymbol)
    slideSymbol:setPositionX(self.m_SlotNodeW*0.5)
    table.insert(self.m_slideSymbol[_iCol], slideSymbol)
    
    --存一下自身的数据
    slideSymbol.m_iSlideRow =  _iRow

    return slideSymbol
end

-- clear
function ChicEllaMiniMachine:clearSlideSymbolToPool()
    -- 重置slotnode     push ccbnode to pool
    for k, slotNode in ipairs(self.m_slideSymbol[1]) do
        slotNode:reset()
        slotNode:resetReelStatus()
    end
end

-- 刷新坐标
function ChicEllaMiniMachine:upDateSlidePos()
    for iCol,colData in ipairs(self.m_slideSymbol) do
        for iRow,_slideNode in ipairs(colData) do
            local posY = (iRow-1)*self.m_SlotNodeH + self.m_SlotNodeH*0.5
            _slideNode:setPositionY(posY)
            _slideNode:setVisible(true)
        end
        break
    end
end

function ChicEllaMiniMachine:getSlideRunReelData()
    local reelDataList = {}

    for iCol=1,self.m_iReelColumnNum do
        local reelData = clone(self.m_configData:getNormalReelDatasByColumnIndex(iCol))
        reelDataList[iCol] = reelData

        break
    end

    return reelDataList
end

function ChicEllaMiniMachine:getSlideRunReelDataFinally(_resultReels)
    local reelDataList = {}

    -- 用第二列数据配置最后滚动的数据
    for iCol=2,self.m_iReelColumnNum do
        local reelData = clone(self.m_configData:getNormalReelDatasByColumnIndex(iCol))
        reelDataList[iCol - 1] = reelData

        break
    end
    
    --插入结尾
    for iCol,colData in ipairs(reelDataList) do
        for iLine=#_resultReels,1,-1 do
            table.insert(colData, _resultReels[iLine][iCol])
        end
    end

    return reelDataList
end

function ChicEllaMiniMachine:setColumnReelDataFinally(_resultReels)
    -- 滚动完成的最终盘面
    self.m_resultReels  = clone(_resultReels)

    self.m_reelDataListFinally = self:getSlideRunReelDataFinally(self.m_resultReels)
end

function ChicEllaMiniMachine:setColumnReelData(_reels)
    if not self.m_isInitSymbol then
        self:initSlideSymbol()
        self.m_isInitSymbol = true
    end

    -- 初始化一下假滚列表
    self.m_reelDataList = self:getSlideRunReelData()

    --修改当前轮盘
    for _line,_lineData in ipairs(_reels) do
        local iRow = self.m_iReelRowNum - _line + 1
        for iCol,_symbolType in ipairs(_lineData) do
            local slotsNode = self.m_slideSymbol[iCol][iRow]
            -- slotsNode:changeSymbolCcb(_symbolType)

            local ccbName = self.m_machine:getSymbolCCBNameByType(self, _symbolType)
            slotsNode:changeCCBByName(ccbName, _symbolType)
            slotsNode:changeSymbolImageByName(ccbName)

            if _symbolType == 90 then
                slotsNode:runAnim("idle", true)
            end
            
            local slotsOrder = self.m_machine:getBounsScatterDataZorder(_symbolType)
            slotsNode:setLocalZOrder(slotsOrder)
            slotsNode.m_iSlideRow = iRow

            break
        end
    end
    --修改卷轴未展示的信号
    for iCol,_list in ipairs(self.m_slideSymbol) do
        for iRow=self.m_iReelRowNum+1,#_list do
            
            local slotsNode = self.m_slideSymbol[iCol][iRow]
            local symbolType = self.m_reelDataList[iCol][iRow-self.m_iReelRowNum]
            -- slotsNode:changeSymbolCcb(symbolType)

            local ccbName = self.m_machine:getSymbolCCBNameByType(self, symbolType)
            slotsNode:changeCCBByName(ccbName, symbolType)
            slotsNode:changeSymbolImageByName(ccbName)

            if symbolType == 90 then
                slotsNode:runAnim("idle", true)
            end
            local slotsOrder = self.m_machine:getBounsScatterDataZorder(symbolType)
            slotsNode:setLocalZOrder(slotsOrder)
            slotsNode.m_iSlideRow = iRow

        end
        break
    end

    self:upDateSlidePos()
end

function ChicEllaMiniMachine:setStop(func)
    self.m_isStopSign = true
    self.m_isStopSignFirst = true

    self.func = func
end

function ChicEllaMiniMachine:resetStop()
    self.m_isStopSign = false
    self.m_isStopSignFirst = true
end

function ChicEllaMiniMachine:startSlideMove(_reelDownFun)
    if self.m_moveHandler then
        return
    end

    self:upDateSlidePos()

    local reelDataList = self.m_reelDataList
    local reelDataLength = #reelDataList[1]
    
    local totalDistance = self.m_SlotNodeH * reelDataLength
    local curDistance = 0 
    local curProgress = 0
    local speed       = 0
    local bottomY     = -0.5 * self.m_SlotNodeH 

    local acceleration = 60
    speed       = 1950

    

    self.m_moveHandler = scheduler.scheduleUpdateGlobal(function(dt) 
        -- curProgress =  curDistance / totalDistance

        -- if curProgress <= 0.2 then
        --     local startSpeed  = self.m_SlotNodeH 
        --     local targetSpeed = self.m_SlotNodeH * reelDataLength/2
        --     speed = startSpeed + (targetSpeed - startSpeed)*curProgress/0.2 
        -- end

        local moveDistance = math.floor(speed * dt) 
        -- 最后一次移动
        if self.m_isStopSign then
            if self.m_isStopSignFirst then
                self.m_isStopSignFirst = false
                curDistance = curDistance % self.m_SlotNodeH
                totalDistance = self.m_SlotNodeH * #self.m_reelDataListFinally[1]
                --更新row
                for iCol,_list in ipairs(self.m_slideSymbol) do
                    local idx = 1
                    for j, node in ipairs(_list) do
                        node.m_iSlideRow = idx
                        idx = idx + 1
                    end
                    break
                end
            end
            
            if curDistance + moveDistance >= totalDistance then
                moveDistance = totalDistance - curDistance
            end
        end
        
        curDistance = curDistance + moveDistance
        -- 刷新坐标
        for iCol,_list in ipairs(self.m_slideSymbol) do
            for iRow,_symbolNode in ipairs(_list) do
                local nextPosY = _symbolNode:getPositionY() - moveDistance
                _symbolNode:setPositionY(nextPosY)
            end
            break
        end
        -- 刷新信号重制位置
        for iCol,_list in ipairs(self.m_slideSymbol) do
            local firstSymbol = _list[1]
            local lastSymbol = _list[#_list]
            -- 首行信号超过了最大高度，移除添加到尾部
            while firstSymbol:getPositionY() <= bottomY do
                firstSymbol.m_iSlideRow = lastSymbol.m_iSlideRow + 1
                local dataReelIndex = firstSymbol.m_iSlideRow - 3

                local nextSymbolType = nil
                if self.m_isStopSign then   --用真实数据
                    
                    nextSymbolType = self.m_reelDataListFinally[iCol][dataReelIndex]
                    if not nextSymbolType then
                        break
                    end
                else                        --用循环数据
                    nextSymbolType = reelDataList[iCol][dataReelIndex]
                    if not nextSymbolType then
                        dataReelIndex = 1
                        firstSymbol.m_iSlideRow = 4
                        nextSymbolType = reelDataList[iCol][dataReelIndex]
                    end
                end
                
                -- 修改信号类型和展示
                -- firstSymbol:changeSymbolCcb(nextSymbolType)
                local ccbName = self.m_machine:getSymbolCCBNameByType(self, nextSymbolType)
                firstSymbol:changeCCBByName(ccbName, nextSymbolType)
                firstSymbol:changeSymbolImageByName(ccbName)

                -- self:upDateSlideSymbolOrder(firstSymbol, iCol)
                firstSymbol:runAnim("idleframe", false)

                -- if nextSymbolType == 90 then
                    -- nextSymbolType:runAnim("idle", true)
                -- end
                local slotsOrder = self.m_machine:getBounsScatterDataZorder(nextSymbolType)
                firstSymbol:setLocalZOrder(slotsOrder)
                -- 修改Y坐标
                local nextPosY = lastSymbol:getPositionY() + self.m_SlotNodeH 
                firstSymbol:setPositionY(nextPosY)
                -- 指针指向下一个滑块
                firstSymbol = table.remove(_list, 1)
                table.insert(_list, firstSymbol)
                firstSymbol = _list[1]
                lastSymbol = _list[#_list]
            end

            break
        end
        if self.m_isStopSign then
            --结束移动
            if curDistance >= totalDistance then
                self:endSlideSymbolMove()
            end
        end
        
    end)
end


function ChicEllaMiniMachine:endSlideSymbolMove()
    if self.m_moveHandler then
        scheduler.unscheduleGlobal(self.m_moveHandler)
        self.m_moveHandler = nil
    end

    self:resetStop()

    self:reelHideMaskAction(0.5)

    if self.func then
        self.func()
    end
end

-- 显示黑遮
function ChicEllaMiniMachine:reelShowMaskAction(time)
    for i,maskNode in ipairs(self.m_maskAction) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            util_nodeFadeIn(maskNode,time,0,100,nil,nil)
        end
    end
end

-- 隐藏黑遮
function ChicEllaMiniMachine:reelHideMaskAction(time)
    for i=1, #self.m_maskAction do
        local maskNode = self.m_maskAction[i]
        local act = cc.FadeOut:create(time)
        maskNode:runAction(act)

        self:waitWithDelay(nil,function()
            maskNode:setVisible(false)
        end,time)
    end
    
end

function ChicEllaMiniMachine:waitWithDelay(parent, endFunc, time)
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


return ChicEllaMiniMachine
