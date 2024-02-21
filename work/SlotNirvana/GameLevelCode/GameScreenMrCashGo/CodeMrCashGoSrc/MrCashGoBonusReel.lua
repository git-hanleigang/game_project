local BaseMiniMachine = require "Levels.BaseMiniMachine"
local MrCashGoBonusReel = class("MrCashGoBonusReel", BaseMiniMachine)

-- 构造函数    
function MrCashGoBonusReel:ctor()
    MrCashGoBonusReel.super.ctor(self)
end
 
function MrCashGoBonusReel:initData_(machine)
    self.m_randomSymbolSwitch = true

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machine = machine
    -- 最少截取的数量
    self.m_runRowCount = 26
    --init
    self:initGame()
  
end

function MrCashGoBonusReel:initGame()
    --初始化基本数据
    self.m_moduleName = self:getModuleName()
    self:initMachine(self.m_moduleName)

    self.m_bigScatterList = {}
    self:initSlideSymbol()
end
---
-- 读取配置文件数据
--
function MrCashGoBonusReel:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData("MrCashGoMiniConfig.csv")
    end
end
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MrCashGoBonusReel:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MrCashGo"
end

function MrCashGoBonusReel:initMachineCSB()
    self:createCsbNode("MrCashGo/GameScreenMrCashGo_bonus.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function MrCashGoBonusReel:onEnter()
    MrCashGoBonusReel.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MrCashGoBonusReel:addObservers()
    gLobalNoticManager:addObserver(self, self.quicklyStopReel, ViewEventType.RESPIN_TOUCH_SPIN_BTN)

    MrCashGoBonusReel.super.addObservers(self)
end

function MrCashGoBonusReel:onExit()
    MrCashGoBonusReel.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_moveHandler then
        scheduler.unscheduleGlobal(self.m_moveHandler)
        self.m_moveHandler = nil
    end
end


function MrCashGoBonusReel:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
    return ccbName
end

function MrCashGoBonusReel:checkGameResumeCallFun()
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

function MrCashGoBonusReel:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MrCashGoBonusReel:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function MrCashGoBonusReel:resumeMachine()
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
function MrCashGoBonusReel:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function MrCashGoBonusReel:clearCurMusicBg()
end

function MrCashGoBonusReel:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function MrCashGoBonusReel:playEffectNotifyChangeSpinStatus()
  
end


function MrCashGoBonusReel:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

function MrCashGoBonusReel:addSelfEffect()
end
function MrCashGoBonusReel:MachineRule_playSelfEffect(effectData)
    return true
end



----------------------------- 关卡自身逻辑 -----------------------------------

--[[
    大图标假滚
]]
-- 初始化
function MrCashGoBonusReel:initSlideSymbol()
    self.m_slideSymbol = {}

    local maxRow = self.m_iReelRowNum + 3 + 1
    for iCol=1,5 do
        self.m_slideSymbol[iCol] = {}
        for iRow=1,maxRow do
            self:createSlideSymbol(iCol, iRow)
        end
    end
end
-- 创建
function MrCashGoBonusReel:createSlideSymbol(_iCol, _iRow)
    local symbolType = self.m_machine.SYMBOL_Blank

    local slideSymbol = self.m_machine:createMrCashGoTempSymbol(symbolType)
    local parentNode = self:findChild( string.format("sp_reel_%d", _iCol-1) )
    parentNode:addChild(slideSymbol)
    slideSymbol:setPositionX(self.m_SlotNodeW*0.5)
    table.insert(self.m_slideSymbol[_iCol], slideSymbol)
    
    --存一下自身的数据
    slideSymbol.m_iSlideRow =  _iRow

    return slideSymbol
end
function MrCashGoBonusReel:upDateSlideSymbolOrder(_slideNode, _iCol)
    local specialList = {
        [self.m_machine.SYMBOL_Scatter_2x2] = true,
        [self.m_machine.SYMBOL_Scatter_3x3] = true,
    }

    local isSpecialSymbol = specialList[_slideNode.m_symbolType]
    local newParentName   = isSpecialSymbol and string.format("special_reel_%d", _iCol-1) or string.format("sp_reel_%d", _iCol-1)
    local newParent       = self:findChild(newParentName)
    local slotsOrder      = self.m_machine:getBounsScatterDataZorder(_slideNode.m_symbolType)
    util_changeNodeParent(newParent, _slideNode, slotsOrder)
end
-- 刷新坐标
function MrCashGoBonusReel:upDateSlidePos()
    for iCol,colData in ipairs(self.m_slideSymbol) do
        for iRow,_slideNode in ipairs(colData) do
            local posY = (iRow-1)*self.m_SlotNodeH + self.m_SlotNodeH*0.5
            _slideNode:setPositionY(posY)
            _slideNode:setVisible(true)
        end
    end
end

function MrCashGoBonusReel:resetBonusReelShow(_reels, _resultReels, _levels)
    -- 滚动完成的最终盘面
    self.m_resultReels  = clone(_resultReels)
    -- 生成的等级框(需要创建scatter的位置)
    self.m_levels       = clone(_levels)
    -- 初始化一下假滚列表
    self.m_reelDataList = self:getSlideRunReelData(self.m_resultReels)
    -- 

    --修改当前轮盘
    for _line,_lineData in ipairs(_reels) do
        local iRow = self.m_iReelRowNum - _line + 1
        for iCol,_symbolType in ipairs(_lineData) do
            local slotsNode = self.m_slideSymbol[iCol][iRow]
            slotsNode:changeSymbolCcb(_symbolType)
            self:upDateSlideSymbolOrder(slotsNode, iCol)
            slotsNode:runAnim("idleframe", false)
            local slotsOrder = self.m_machine:getBounsScatterDataZorder(_symbolType)
            slotsNode:setLocalZOrder(slotsOrder)
            slotsNode.m_iSlideRow = iRow
        end
    end
    --修改卷轴未展示的信号
    for iCol,_list in ipairs(self.m_slideSymbol) do
        for iRow=self.m_iReelRowNum+1,#_list do
            
            local slotsNode = self.m_slideSymbol[iCol][iRow]
            local symbolType = self.m_reelDataList[iCol][iRow-self.m_iReelRowNum] or self.m_machine.SYMBOL_Blank
            slotsNode:changeSymbolCcb(symbolType)
            self:upDateSlideSymbolOrder(slotsNode, iCol)
            slotsNode:runAnim("idleframe", false)
            local slotsOrder = self.m_machine:getBounsScatterDataZorder(_symbolType)
            slotsNode:setLocalZOrder(slotsOrder)
            slotsNode.m_iSlideRow = iRow

        end
    end
end
function MrCashGoBonusReel:startSlideMove(_reelDownFun)
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
    local bottomY     = -2.5 * self.m_SlotNodeH 

    self.m_moveHandler = scheduler.scheduleUpdateGlobal(function(dt) 
        curProgress =  curDistance / totalDistance

        if curProgress <= 0.2 then
            local startSpeed  = self.m_SlotNodeH 
            local targetSpeed = self.m_SlotNodeH * reelDataLength/2
            speed = startSpeed + (targetSpeed - startSpeed)*curProgress/0.2 
        end

        local moveDistance = math.floor(speed * dt) 
        -- 最后一次移动
        if curDistance + moveDistance >= totalDistance then
            moveDistance = totalDistance - curDistance
        end
        curDistance = curDistance + moveDistance
        -- 刷新坐标
        for iCol,_list in ipairs(self.m_slideSymbol) do
            for iRow,_symbolNode in ipairs(_list) do
                local nextPosY = _symbolNode:getPositionY() - moveDistance
                _symbolNode:setPositionY(nextPosY)
            end
        end
        -- 刷新信号重制位置
        for iCol,_list in ipairs(self.m_slideSymbol) do
            local firstSymbol = _list[1]
            local lastSymbol = _list[#_list]
            -- 首行信号超过了最大高度，移除添加到尾部
            while firstSymbol:getPositionY() <= bottomY do
                firstSymbol.m_iSlideRow = lastSymbol.m_iSlideRow + 1
                local dataReelIndex = firstSymbol.m_iSlideRow - 3
                local nextSymbolType = reelDataList[iCol][dataReelIndex] --or self.m_machine.SYMBOL_Blank
                if not nextSymbolType then
                    break
                end
                -- 修改信号类型和展示
                firstSymbol:changeSymbolCcb(nextSymbolType)
                self:upDateSlideSymbolOrder(firstSymbol, iCol)
                firstSymbol:runAnim("idleframe", false)
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
        end
        --结束移动
        if curDistance >= totalDistance then
            self:endSlideSymbolMove(_reelDownFun)
        end
    end)
end


function MrCashGoBonusReel:endSlideSymbolMove(_fun)
    if self.m_moveHandler then
        scheduler.unscheduleGlobal(self.m_moveHandler)
        self.m_moveHandler = nil
    end

    self:reelStopHideBigScatter()
    self:playSymbolBuling(function()
        self:playBigScatterNarrow(_fun)
    end)
end

function MrCashGoBonusReel:reelStopHideBigScatter()
    for iCol,_list in ipairs(self.m_slideSymbol) do
        for iRow,_slideNode in ipairs(_list) do
            -- 停轮时 卷轴的最后三行是棋盘区域
            if iRow < #_list-self.m_iReelRowNum then
                _slideNode:setVisible(false)
            end
        end

    end
end
function MrCashGoBonusReel:playSymbolBuling(_fun)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        _fun()
        return
    end

    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bigScatter_buling.mp3")

    local bulingTime = 2
    for iCol,_list in ipairs(self.m_slideSymbol) do
        for iRow,_symbolNode in ipairs(_list) do
            -- 停轮时 卷轴的最后三行是棋盘区域
            if #_list-self.m_iReelRowNum <= iRow then
                 -- 自定义信号 m_symbolType
                local symbolCfg = bulingAnimCfg[_symbolNode.m_symbolType]
                if symbolCfg then
                    _symbolNode:runAnim(symbolCfg[2], false)
                end
            end

            local actList,time = self:getBonusReelDownAction()
            _symbolNode:runAction(cc.Sequence:create(actList))
            bulingTime = time
        end

    end

    
    self.m_machine:levelPerformWithDelay(bulingTime, function()
        _fun()
    end)
end
-- 大scatter缩小
function MrCashGoBonusReel:playBigScatterNarrow(_fun)
    -- 停轮时 卷轴的最后三行是棋盘区域
    local  listCount = #(self.m_slideSymbol[1])

    -- 获得大scatter位置 { [位置] = 信号值 }
    local bigScatterList = {}
    for _line,_lineData in ipairs(self.m_resultReels) do
        --
        local iRow = self.m_iReelRowNum - _line + 1
        for iCol,_symbolType in ipairs(_lineData) do
            if _symbolType == self.m_machine.SYMBOL_Scatter_2x2 or _symbolType == self.m_machine.SYMBOL_Scatter_3x3 then
                local iPos = (_line-1)*self.m_iReelColumnNum + iCol-1
                local slideRow  = listCount - self.m_iReelRowNum + iRow
                local slotsNode = self.m_slideSymbol[iCol][slideRow]

                local tempBigScatter = nil
                if #self.m_bigScatterList > 0 then
                    tempBigScatter = table.remove(self.m_bigScatterList, 1)
                    tempBigScatter:changeSymbolCcb(_symbolType)
                    tempBigScatter:setVisible(true)
                else
                    tempBigScatter = self.m_machine:createMrCashGoTempSymbol(_symbolType)
                    self:addChild(tempBigScatter, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
                end

                local position = util_convertToNodeSpace(slotsNode, self) 
                tempBigScatter:setPosition(position)

                bigScatterList[iPos] = tempBigScatter
            end
        end
        
    end
    
    -- 24 -> 30
    local bianxiaoTime = 30/30 + 3/30
    local actionframeTime = 60/30
    -- 将大scatter覆盖区域切换成小scattr
    for _level,_posList in ipairs(self.m_levels) do
        for _index,_iPos in ipairs(_posList) do
            local fixPos = self.m_machine:getRowAndColByPos(_iPos)
            local iCol   = fixPos.iY
            local slideRow  = listCount - self.m_iReelRowNum + fixPos.iX
            local slotsNode = self.m_slideSymbol[iCol][slideRow]

            slotsNode:changeSymbolCcb(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            self:upDateSlideSymbolOrder(slotsNode, iCol)
            slotsNode:runAnim("idleframe", false)
            local slotsOrder = self.m_machine:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            slotsNode:setLocalZOrder(slotsOrder)

            self.m_machine:levelPerformWithDelay(bianxiaoTime, function()
                local topReel = self:findChild(string.format("top_reel_%d", iCol-1))
                util_changeNodeParent(topReel, slotsNode, slotsOrder)
                slotsNode:runAnim("actionframe", false, function()
                    self:upDateSlideSymbolOrder(slotsNode, iCol)
                end)
            end)
        end
    end
    self.m_machine:levelPerformWithDelay(bianxiaoTime, function()
        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_scatter_actionframe_2.mp3")
    end)
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bigScatter_division.mp3")
    -- 播放大scatter的缩小动画
    for _iPos,_scatter in pairs(bigScatterList) do
        local scatterNode = bigScatterList[_iPos]
        scatterNode:runAnim("bianxiao", false, function()
            scatterNode:setVisible(false)
            table.insert(self.m_bigScatterList, scatterNode)
        end)
    end
    
    self.m_machine:levelPerformWithDelay(bianxiaoTime + actionframeTime, function()
        _fun()
    end)
end
-- 组织一下本次假滚列表
function MrCashGoBonusReel:getSlideRunReelData(_resultReels)
    local reelDataList = {}

    local reelData_1     = self.m_configData:getNormalReelDatasByColumnIndex(1)
    local beginReelIndex = util_random(1, #reelData_1)
    local runRowCount    = self.m_runRowCount
    -- 起始行不能有 999
    while true do
        local bool = false
        for iCol=1,self.m_iReelColumnNum do
            local reelData   = self.m_configData:getNormalReelDatasByColumnIndex(iCol)
            local symbolType = reelData[beginReelIndex]
            if self.m_machine.SYMBOL_Blank ~= symbolType then
                if iCol == self.m_iReelColumnNum then
                    bool = true
                end
            else
                break
            end
        end
        if bool then
            break
        end
        beginReelIndex = beginReelIndex < #reelData_1 and beginReelIndex+1 or 1

        local sMsg = string.format("[MrCashGoBonusReel:getSlideRunReelData] %d", beginReelIndex)
        release_print(sMsg)
    end

    -- 截取
    for iCol=1,self.m_iReelColumnNum do
        local reelData = self.m_configData:getNormalReelDatasByColumnIndex(iCol)
        local newReelData = {}
        for iRow=beginReelIndex,#reelData do
            if #newReelData == runRowCount then
                break
            else
                table.insert(newReelData, reelData[iRow])
            end
        end
        for iRow=1,beginReelIndex do
            if #newReelData == runRowCount then
                break
            else
                table.insert(newReelData, reelData[iRow])
            end
        end
        reelDataList[iCol] = newReelData
    end
    -- 补空
    local addLineData = {}
    for iCol,colData in ipairs(reelDataList) do
        local lastType_1 = colData[#colData]
        local lastType_2 = colData[#colData-1]

        if lastType_1 == self.m_machine.SYMBOL_Scatter_3x3 then
            self:addRandomReelData(addLineData, 2)
            self:setReelDataBlankSymbol(addLineData, iCol, 0, lastType_1)
        elseif lastType_1 == self.m_machine.SYMBOL_Scatter_2x2 then
            self:addRandomReelData(addLineData, 1)
            self:setReelDataBlankSymbol(addLineData, iCol, 0, lastType_1)
        elseif lastType_2 == self.m_machine.SYMBOL_Scatter_3x3 then
            self:addRandomReelData(addLineData, 1)
            self:setReelDataBlankSymbol(addLineData, iCol, -1, lastType_1)
        end
    end
    if #addLineData > 0 then
        for iRow,_rowData in ipairs(addLineData) do
            for iCol,_symbolType in ipairs(_rowData) do
                table.insert(reelDataList[iCol], _symbolType)
            end
        end
    end
    --插入结尾
    for iCol,colData in ipairs(reelDataList) do
        for iLine=#_resultReels,1,-1 do
            table.insert(colData, _resultReels[iLine][iCol])
        end
    end

    return reelDataList
end

function MrCashGoBonusReel:addRandomReelData(_reelData, _lineCount)
    for iLine=1,_lineCount do
        if nil == _reelData[iLine] then
            local baseReelData = {}
            for iCol=1,self.m_iReelColumnNum do
                local symbolType   = self:getReelDataRandomSymbol()
                baseReelData[iCol] = symbolType
            end

            _reelData[iLine] = baseReelData
        end
    end
end
-- 获取补空时的随机信号 0~10
function MrCashGoBonusReel:getReelDataRandomSymbol()
    local symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, self.m_machine.SYMBOL_L6)
    return symbolType
end
-- 将补块的列表指定位置修改为空块
function MrCashGoBonusReel:setReelDataBlankSymbol(_reelData, _iCol, _iRow, _bigSymbolType)
    local symbolData = {
        [self.m_machine.SYMBOL_Scatter_2x2] = {
            iColCount = 2,
            iRowCount = 2,
        },
        [self.m_machine.SYMBOL_Scatter_3x3] = {
            iColCount = 3,
            iRowCount = 3,
        },
    }

    local data = symbolData[_bigSymbolType]
    if data then
        for iRowCount=1,data.iRowCount-1 do
            local iRow = _iRow + iRowCount
            if _reelData[iRow] then
                for iColCount=1,data.iColCount do
                    local iCol = _iCol + iColCount-1
                    _reelData[iRow][iCol] = self.m_machine.SYMBOL_Blank
                end
            end
            
        end
    end
end

function MrCashGoBonusReel:getBonusReelDownAction()
    local speedActionTable = {}

    local allTime = 15/30
    local timeDown = allTime*0.4
    local backTime = allTime*0.6
    -- 下移
    local dis = self.m_configData.p_reelResDis
    speedActionTable[#speedActionTable + 1] = cc.MoveBy:create(timeDown, cc.p(0, -dis))
    --回弹
    speedActionTable[#speedActionTable + 1] = cc.MoveBy:create(backTime, cc.p(0, dis))

    return speedActionTable,allTime
end



return MrCashGoBonusReel
