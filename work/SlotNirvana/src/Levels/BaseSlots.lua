---
-- island
-- 2017年8月22日
-- BaseSlots.lua
-- 老虎机核心算法流程，这里只做数值的计算


local BaseView = util_require("base.BaseView")
local BaseSlots = class("BaseSlots",BaseView )
local ReelLineInfo = require "data.levelcsv.ReelLineInfo"
local SlotsReelData = require "data.slotsdata.SlotsReelData"
 
BaseSlots.m_currentReelStripData = nil -- 当前滚轮数据
BaseSlots.m_reelColDatas = nil -- 存储每列的数据信息 , 计算数据信息， 显示信息
BaseSlots.m_vecSymbolType = nil --

-- wild 类型信息
BaseSlots.m_iRandomSmallSymbolTypeNum = nil -- 随机小信号个数

BaseSlots.m_iReelColumnNum = nil --
BaseSlots.m_iReelRowNum = nil --
BaseSlots.m_reelWidth = nil --轮盘宽度
BaseSlots.m_reelHeight = nil --轮盘高度

BaseSlots.m_stcValidSymbolMatrix = nil -- 存放每次spin的矩阵(坐标系左下),symbol锚点为（0.5 0.5）

-- 网格相关
BaseSlots.m_fReelWidth = nil
BaseSlots.m_fReelHeigth = nil  -- 滚动网格中， 最高的那一列

BaseSlots.m_SlotNodeW = nil -- 小格子的宽度
BaseSlots.m_SlotNodeH = nil -- 小格子的高度

-- 大信号相关
BaseSlots.m_bigSymbolInfos = nil -- 大wild 类型
BaseSlots.m_bigSymbolColumnInfo = nil -- 大信号起始位置


BaseSlots.m_vecGetLineInfo = nil  --创建属性
BaseSlots.m_iFreeSpinTimes = nil --
BaseSlots.m_reelSlotsList = nil -- 最终生成的滚动列表
BaseSlots.m_reelLineInfoPool = nil -- ReelLineInfo 内存池
BaseSlots.m_validLineSymNum = nil -- 触发feature 的数量 (scatter 、 bonus)
---- 滚动效果等配置内容
BaseSlots.m_REEL_ResType = nil --  回弹类型


--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


function BaseSlots:ctor()
    BaseView.ctor(self)
    self:init()

    self.m_iFreeSpinTimes = 0

    -- 初始化reel 列的滚动信息
    self.m_validLineSymNum = VALID_LINE_SYM_NUM
    
    self.m_vecGetLineInfo = {}
end
function BaseSlots:initUI(data)
    
end
-- 构造函数
function BaseSlots:init()

    self.m_fReelWidth = 0
    self.m_fReelHeigth = 0
                                                                                            
    self:initSymbolMatrix()

    self.m_fSymbolSize = 0 --
end

--[[
    @desc: 初始化结果轮盘， 默认使用最大的7行6列进行排布，如果本关卡存在不同的行列或者更大要求的可以自行定义
    time:2019-02-12 18:41:10
    @return:
]]
function BaseSlots:initSymbolMatrix( )
    self.m_stcValidSymbolMatrix = table_createTwoArr(REEL_MAX_ROW_NUMBER,REEL_COLUMN_NUMBER,TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function BaseSlots:onEnter()
    -- body
end

function BaseSlots:onExit()
    BaseSlots.super.onExit(self)
    self.m_vecSymbolType = nil

end


--[[
    @desc: 网络消息返回后， 做的处理
    time:2018-11-29 17:24:15
    @return:
]]
function BaseSlots:produceSlots()

    self:MachineRule_RestartProbabilityCtrl()

    self:setLastReelSymbolList() 
    
    self:setReelRunInfo()

    self:MachineRule_ResetReelRunData()
    
    self:produceReelSymbolList()

    self:MachineRule_InterveneReelList()

end

---
-- 干预最终生成的信号
--
function BaseSlots:MachineRule_InterveneReelList()

end

function BaseSlots:MachineRule_RestartProbabilityCtrl()
    
end

---
--设置bonus scatter 层级
function BaseSlots:getBounsScatterDataZorder(symbolType )
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


--返回本组下落音效和是否触发长滚效果
function BaseSlots:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum == 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum == 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

---
-- 将最终轮盘放入m_reelSlotsList
--
function BaseSlots:setLastReelSymbolList()

    --- 将最终生成的盘面加入进去


    local iColumn = self.m_iReelColumnNum
    -- local iRow = self.m_iReelRowNum


    for cloumIndex=1,iColumn do
        local nodeCount = self.m_reelRunInfo[cloumIndex]:getReelRunLen()
        local columnData = self.m_reelColDatas[cloumIndex]
        local iRow = columnData.p_showGridCount
        
        if iRow == nil then  -- fix bug 可能是因为轮盘丢块导致的 2018-12-20 11:10:27
            iRow = self.m_iReelRowNum
        end

        local cloumnDatas = {}
        self.m_reelSlotsList[cloumIndex] = cloumnDatas

        local startIndex = nodeCount  -- 从假数据后面开始赋值
        
        for i=1,iRow  do
            local symbolValue = self.m_stcValidSymbolMatrix[i][cloumIndex] -- 循环提取每行中的某列¸
            local slotData = self:getSlotsReelData()

            slotData.m_isLastSymbol = true
            slotData.m_rowIndex = i
            slotData.m_columnIndex = cloumIndex
            slotData.p_symbolType = symbolValue--symbolValue.enumSymbolType
            
            if self.m_bigSymbolInfos[slotData.p_symbolType] ~= nil then
                slotData.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
                
                local symbolCount = self.m_bigSymbolInfos[slotData.p_symbolType]

                symbolCount = symbolCount - 1
                -- 将前面的也进行赋值
                if i == 1 then  -- 检测后面是否足够数量展示 symbol count
                    for checkIndex=2,iRow do
                        local checkType = self.m_stcValidSymbolMatrix[checkIndex][cloumIndex]
                        if symbolValue == checkType then
                            symbolCount = symbolCount - 1
                        else
                            break
                        end
                    end
                    -- 将前面需要变为大信号的地方全部设置为大信号，这样滚动时如果最终信号组跨列 那么现实也是正常的
                    if symbolCount > 0 then
                        for addIndex=1,symbolCount do
                            local addSlotData = self:getSlotsReelData()
                            addSlotData.m_isLastSymbol = true
                            addSlotData.m_rowIndex = 1 - addIndex  -- 这里会是负数，因为创建长条的起始位置是从这里开始的， 所以针对于第一行是负数
                            addSlotData.m_columnIndex = cloumIndex
                            addSlotData.p_symbolType = symbolValue

                            slotData.m_showOrder = self:getBounsScatterDataZorder(slotData.p_symbolType )

                            cloumnDatas[startIndex + i - addIndex] = addSlotData
                        end
                    end
                end


            else
                slotData.m_showOrder = self:getBounsScatterDataZorder(slotData.p_symbolType )
            end

            cloumnDatas[startIndex + i] = slotData
        end

    end
    print("...")
end

function BaseSlots:getLongRunLen(col, index)
    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        if self:getInScatterShowCol(col) then 
            local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

        elseif col > scatterShowCol[#scatterShowCol] then
            local reelRunData = self.m_reelRunInfo[col - 1]
            local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
            local lastRunLen = reelRunData:getReelRunLen()
            len = lastRunLen + diffLen
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    end
    return len
end

function BaseSlots:getInScatterShowCol(col)
    for i=1,#self.m_ScatterShowCol do
        if self.m_ScatterShowCol[i] == col then
            return true
        end
    end
    return false
end


function BaseSlots:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else 
                return false
            end
        end
    end

    return true
end

function BaseSlots:checkAndClearVecLines()

    if self.m_vecGetLineInfo == nil then
        self.m_vecGetLineInfo = {}
    end

    for lineIndex = #self.m_vecGetLineInfo , 1, -1 do
        local value = self.m_vecGetLineInfo[lineIndex]
        value:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value

        self.m_vecGetLineInfo[lineIndex] = nil
    end

end


function BaseSlots:getSymbolTypeForNetData(iCol, iRow, iLen)
    local data = self.m_reelSlotsList[iCol][iRow+iLen]
    return data.p_symbolType
end

--设置bonus scatter 信息
function BaseSlots:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
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
        end
        
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

----
--
-- 获取ReelLineInfo
--
function BaseSlots:getReelLineInfo()

    if #self.m_reelLineInfoPool > 0 then
        local value = self.m_reelLineInfoPool[1]
        table.remove(self.m_reelLineInfoPool,1)

        if value.enumSymbolType ~= nil or  #value.vecValidMatrixSymPos > 0  then
            value:clean()
        end

        return value
    else
        local value = ReelLineInfo.new()
        return value
    end
end

--[[
    @desc: 获取滚动轮盘结果里面， 某些类型元素的数量
    time:2018-12-12 21:25:26
    --@args: 
    @return:
]]
function BaseSlots:getSymbolCountWithReelResult( ... )

    local args = {...}
    local hasCount = 0
    for iCol = 1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local lineRowPos = columnData.p_lineCalculatePos


        for k,iRow in pairs(lineRowPos) do
            -- 检测拥有的信号类型
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            for i=1,#args do
                if symbolType == args[i] then
                    hasCount = hasCount + 1
                end
            end
        end
    end

    return hasCount

end


--TODO 开始生成概率前，干预，各个关卡继承

---
-- 2020-07-02 重构， 更新machine 数据
--@param csvFileName string csv文件名字
--@param luaFileName string lua文件名字
function BaseSlots:updateMachineData()

    if self.m_currentReelStripData == nil then
        self.m_currentReelStripData = self.m_configData.reelDataNormal -- 默认是normal模式下的reel strip data
    end

    self:checkUpdateColumnData()
end
--[[
    @desc: 检测是否处理 每列的数据信息
    time:2019-01-02 15:57:22
]]
function BaseSlots:checkUpdateColumnData( )

    if self.m_reelColDatas == nil or #self.m_reelColDatas == 0 then
        self.m_reelColDatas = {}
        for i=1,self.m_iReelColumnNum do
            if self.m_reelColDatas[i] == nil then
                self.m_reelColDatas[i] = util_require("data.slotsdata.ReelColumnData"):create()
            end
            self.m_reelColDatas[i]:updateColInfo(i , self.m_iReelRowNum)
        end
    end

end

--设置长滚信息
function BaseSlots:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

    end --end  for col=1,iColumn do

end


---
--根据关卡玩法重新设置滚动信息
function BaseSlots:MachineRule_ResetReelRunData()

end

---
-- 获取每列滚动信号中的 symboltype
--
function BaseSlots:getReelSymbolType(parentData)


    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end

    -- dump(parentData.reelDatas,"parentData.reelDatas",3)
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]

    -- while true do
        local addCount = 1
        if self.m_bigSymbolInfos[symbolType] ~= nil then
            addCount = self.m_bigSymbolInfos[symbolType]
        end
        parentData.beginReelIndex = parentData.beginReelIndex + addCount
        if parentData.beginReelIndex > #parentData.reelDatas then
            parentData.beginReelIndex = 1
            symbolType = parentData.reelDatas[parentData.beginReelIndex]
        end
        
    -- end

    return symbolType
end

--补丁找不到数据随机普通信号
function BaseSlots:getRandomSymbolType()
    return math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
end

---
-- 获取slot node data
--
function BaseSlots:getSlotsReelData()

    local slotData = nil

    if #self.m_reelSlotDataPool > 0 then  -- 先从缓存中提取
        slotData = self.m_reelSlotDataPool[1]
        table.remove(self.m_reelSlotDataPool,1)
    else
        slotData = SlotsReelData.new()
    end
    return slotData
end

---
-- 生成滚动序列
-- @param cloumGroupNums array 生成列对应组的数量 , 这个数量必须对应列的数量否则不执行
--
function BaseSlots:produceReelSymbolList()

    if self.m_reelRunInfo == nil then
        return
    end

    local reelCount = #self.m_reelRunInfo  -- 共有多少列信息

    if reelCount ~= self.m_iReelColumnNum then
        assert(false,"reelCount  ！= self.m_iReelColumnNum")
        return
    end
    local bottomResList = self.m_runSpinResultData.p_resBottomTypes

    for cloumIndex = 1 , reelCount ,1  do
        local columnDatas = self.m_reelSlotsList[cloumIndex]
        local parentData = self.m_slotParents[cloumIndex]
        local columnData = self.m_reelColDatas[cloumIndex]
        parentData.lastReelIndex = columnData.p_showGridCount -- 从最初起始开始滚动
        
        local nodeCount = self.m_reelRunInfo[cloumIndex]:getReelRunLen()
        -- local nodeList = {}
        for nodeIndex=1,nodeCount do
            
            -- 由于初始创建了一组数据， 所以跨过第一组从后面开始
            if nodeIndex >= 1 and nodeIndex <= columnData.p_showGridCount then
                columnDatas[nodeIndex] = 0
            else
                local symbolType = self:getReelSymbolType(parentData)  -- 根据规则随机产生信号
                -- 根据服务器传回来的数据获取 type ，检测是否是长条如果是长条不做处理 太麻烦了
                local bottomResType = nil
                if nodeIndex == nodeCount and bottomResList ~= nil and bottomResList[cloumIndex] ~= nil then
                    bottomResType = bottomResList[cloumIndex]
                    if self.m_bigSymbolInfos[bottomResType] ~= nil then
                        bottomResType = nil
                    end
                end
                if bottomResType ~= nil then
                    symbolType = bottomResType
                end

                if self.m_bigSymbolInfos[symbolType] ~= nil then
                    -- 大信号后面几个全部赋值为 symbolType  ******

                    if columnDatas[nodeIndex] == nil then

                        local addCount = self.m_bigSymbolInfos[symbolType]
                        local hasBigSymbol = false
                        for checkIndex=1,addCount do  -- 主要是判断后面是否有元素，如果有元素并且长度不足以放下长条元素则不再放置长条元素类型
                            local addedType= columnDatas[nodeIndex + checkIndex - 1]
                            if addedType ~= nil then
                                hasBigSymbol = true
                            end
                        end

                        if hasBigSymbol == false then -- 可以放置下长条元素，则直接将symbolType 赋值
                            for i=1,addCount do
                                columnDatas[nodeIndex + i - 1] = symbolType
                            end
                        else
                            for i=1,addCount do  -- 这里是在补充非长条小块
                                local checkType = columnDatas[nodeIndex + i - 1]
                                if checkType == nil then

                                    local addType = self:getReelSymbolType(parentData)
                                    local index = 1
                                    if DEBUG == 2 then
                                        -- release_print("657 begin  %d" , addType)
                                    end
                                    while true do
                                        if self.m_bigSymbolInfos[addType]== nil then
                                            break
                                        end
                                        index = index + 1
                                        
                                        addType = self:getReelSymbolType(parentData)
                                    end
                                    if DEBUG == 2 then
                                        -- release_print("668 begin")
                                    end
                                    columnDatas[nodeIndex + i - 1] = addType
                                end
                            end -- end for i=1,addCount do
                        end


                    end  -- end if columnDatas[nodeIndex] == nil then

                else
                    if columnDatas[nodeIndex] == nil then
                        columnDatas[nodeIndex] = symbolType
                    end
                end
                
            end
            
        end
        
        -- columnDatas[#columnDatas + 1] = nodeList

    end

end

--[[
    @desc: 处于freespin 模式时切换到对应的分数 和 滚轮
    time:2018-11-30 16:08:50
    @return:
]]
function BaseSlots:changeFreeSpinReelData( )
    if self.m_configData.reelDataFs ~= nil then
        self.m_currentReelStripData = self.m_configData.reelDataFs
    end

end
--[[
    @desc: 切换到Normal 模式对应的分数 和 滚轮
    time:2018-11-30 16:09:09
    @return:
]]
function BaseSlots:changeNormalReelData( )
    self.m_currentReelStripData = self.m_configData.reelDataNormal

end


---
-- 获取随机信号，  
-- @param col 列索引
function BaseSlots:MachineRule_getRandomSymbol(col)

    local reelDatas = nil
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex,col)
        if reelDatas == nil then
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
        end
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
    end

    local totalCount = #reelDatas
    local randomType = reelDatas[xcyy.SlotsUtil:getArc4Random() % totalCount + 1]
    
    return randomType
end

function BaseSlots:setCurrSpinMode( spinMode )
    globalData.slotRunData.currSpinMode = spinMode
end
function BaseSlots:getCurrSpinMode( )
    return globalData.slotRunData.currSpinMode
end

function BaseSlots:setGameSpinStage( spinStage)
    globalData.slotRunData.gameSpinStage = spinStage
end
function BaseSlots:getGameSpinStage( )
    return globalData.slotRunData.gameSpinStage
end
function BaseSlots:setPlayGameEffectStage( stage)
    globalData.slotRunData.gameEffStage = stage -- 这个状态标识
end


---
-- 随机获取普通信号
--
function BaseSlots:getNormalSymbol(col)
    local symbolType = self:MachineRule_getRandomSymbol(col)
    local index = 1
    if DEBUG == 2 then
        release_print("getNormalSymbol  begin")
    end
    while true do
        if DEBUG == 2 then
            index = index + 1
            if index == 120 then
                release_print("估计卡主了， 一直在while 循环")
            end
        end
        
        if self.m_bigSymbolInfos[symbolType] ~= nil or 
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then

            symbolType = self:MachineRule_getRandomSymbol(col)
        else
            break
        end
    end
    if DEBUG == 2 then
        release_print("getNormalSymbol  end")
    end
    return symbolType

end

------------------------ 根据csv 信息生成小块算法 END----------------------------

---
--触摸事件
function BaseSlots:onTouchBegan(touch, event)
end

function BaseSlots:onTouchMoved(touch, event)
end

function BaseSlots:onTouchEnded(touch, event)
end


return BaseSlots
