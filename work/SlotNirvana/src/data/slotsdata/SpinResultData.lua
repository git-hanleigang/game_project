---
--island
--2018年4月3日
--SpinResultData.lua
--
-- spin 结果数据

local SpinResultData = class("SpinResultData")

local SpinWinLineData = require "data.slotsdata.SpinWinLineData"

SpinResultData.p_reels = nil --滚动结果数据 转换后

SpinResultData.p_resTopTypes = nil  -- 上面补充的信号列表
SpinResultData.p_resBottomTypes = nil --  下面补充的信号列表


SpinResultData.p_prevReel = nil  -- 上面补充的信号列表
SpinResultData.p_nextReel = nil --  下面补充的信号列表


SpinResultData.p_reelsData = nil --滚动结果数据 转换前

SpinResultData.p_colCount = nil -- 滚动结果每行数据

SpinResultData.p_winLines = nil -- 赢钱线

SpinResultData.p_winAmount = nil --
SpinResultData.p_winAmountStr = nil --字符串格式
SpinResultData.p_isBonus = nil -- 是否触发 bonus
SpinResultData.p_isScatter = nil -- 是否触发scatter

SpinResultData.p_bet = nil -- bet信息
SpinResultData.p_multiplier = nil --赢钱翻倍

SpinResultData.p_storedIcons = nil -- 当前轮盘锁定icon pos
SpinResultData.p_reSpinsTotalCount = nil -- respin 总次数
SpinResultData.p_reSpinCurCount = nil -- respin 剩余次数
SpinResultData.p_reSpinStoredIcons = nil -- 本轮锁定 icons 的pos 列表
SpinResultData.p_freeSpinsTotalCount = nil -- fs 总数量
SpinResultData.p_freeSpinsLeftCount = nil -- fs 剩余次数
SpinResultData.p_fsMultiplier = nil -- fs 当前轮数的倍数
SpinResultData.p_freeSpinNewCount = nil -- fs 增加次数
SpinResultData.p_fsWinCoins = nil -- fs 累计赢钱数量
SpinResultData.p_jackpotPool = nil -- jack pot 奖池更新信息
SpinResultData.p_features = nil -- 本轮触发的玩法列表  数组格式

SpinResultData.p_fsExtraData = nil --  freespin 下 extra 数据
SpinResultData.p_rsExtraData = nil --  respin下 extra 数据
SpinResultData.p_resWinCoins = nil --  respin下 累计赢钱数量

-- bnous 相关数据
SpinResultData.p_status = nil
SpinResultData.p_chose = nil
SpinResultData.p_pool = nil
SpinResultData.p_content = nil
SpinResultData.p_allpoolindex = nil
SpinResultData.p_bnousGear = nil

-- bonus 数据相关
SpinResultData.p_bonusWinCoins = nil
SpinResultData.p_bonusStatus = nil
SpinResultData.p_bonusExtra = nil

-- 自定义的数据
SpinResultData.p_selfMakeData = nil

SpinResultData.p_avgBet = nil

SpinResultData.p_isAllLine = nil -- 是否是满线

SpinResultData.p_s = nil -- 本轮触发的玩法列表  数组格式

SpinResultData.p_freeSpinAddList = nil
SpinResultData.p_payLineCount = nil -- 赢钱线数量

SpinResultData.p_featuredata = nil -- 小游戏

SpinResultData.p_collectTotalCount = nil
 --收集总数
SpinResultData.p_collectLeftCount = nil
 --当前收集数量
SpinResultData.p_collectCoinsPool = nil
 --收集icons
SpinResultData.p_collectChangeCount = nil
 --本次收集数量
SpinResultData.p_storedBetMuls = nil

 --本次收集的网络数据
 SpinResultData.p_collectNetData = nil

--jackpot倍数
SpinResultData.p_jackpotMultiple = nil
--jackpot奖励
SpinResultData.p_jackpotCoins = nil

-- 构造函数
function SpinResultData:ctor()
    self.p_reels = {}
    self.p_reelsData = {}
    self.p_winLines = {}
    self.p_freeSpinAddList = {}
    self.p_isAllLine = false
    self.p_collect = {}
    self.p_collectNetData = {}
end

--[[
    @desc: 设置allLine
    time:2019-01-02 21:01:27
    @return:
]]
function SpinResultData:setAllLine( isAllLine )
    self.p_isAllLine = isAllLine
end

---
--
function SpinResultData:clear(lineDataPool)
    if self.p_reels ~= nil then
        for i = #self.p_reels, 1, -1 do
            self.p_reels[i] = nil
        end
    end

    if self.p_reelsData ~= nil then
        for i = #self.p_reelsData, 1, -1 do
            self.p_reelsData[i] = nil
        end
    end

    if self.p_winLines ~= nil then
        for i = #self.p_winLines, 1, -1 do
            local lineData = self.p_winLines[i]

            if lineDataPool ~= nil then
                lineDataPool[#lineDataPool + 1] = lineData
            end

            self.p_winLines[i] = nil
        end
    end
    if self.p_bonus ~= nil then
        self.p_bonus = nil
    end
    if self.p_freeSpinAddList ~= nil then
        self.p_freeSpinAddList = nil
    end
end

---
-- 赢钱数据解析
--
-- data json格式数据
-- lineDataPool lineData 的数据池
function SpinResultData:parseResultData(data, lineDataPool,featureData,symbolCompares)
    assert(lineDataPool ~= nil, "赢钱线数据池 不能为空")

    self:clear(lineDataPool)

    self:parseReelData(data)

    -- 计算赢钱线
    self:parseWinLines(data,lineDataPool)

    self.p_winAmount = data.winAmount
    self.p_winAmountStr = data.winAmountValue

    -- 解析玩法相关

    self.p_storedIcons = data.storedIcons -- 当前轮盘锁定icon pos
    self.p_storedBetMuls = data.storedmuls -- 当前 bet 随机倍数  樱桃专用

    if data.respin ~= nil then
        self.p_reSpinsTotalCount = data.respin.reSpinsTotalCount -- respin 总次数
        self.p_reSpinCurCount = data.respin.reSpinCurCount -- respin 剩余次数
        self.p_rsExtraData = data.respin.extra
        if data.respin.resWinCoins then
            self.p_resWinCoins = data.respin.resWinCoins
        end

        self.p_reSpinStoredIcons = data.respin.reSpinStoredIcons -- 本轮锁定 icons 的pos 列表
    end
    if data.freespin ~= nil then
        self.p_freeSpinsTotalCount = data.freespin.freeSpinsTotalCount -- fs 总数量
        self.p_freeSpinsLeftCount = data.freespin.freeSpinsLeftCount -- fs 剩余次数
        self.p_fsMultiplier = data.freespin.fsMultiplier -- fs 当前轮数的倍数
        self.p_freeSpinNewCount = data.freespin.freeSpinNewCount -- fs 增加次数
        self.p_fsWinCoins = data.freespin.fsWinCoins -- fs 累计赢钱数量
        self.p_freeSpinAddList = data.freespin.freeSpinAddList
        self.p_newTrigger = data.freespin.newTrigger
        self.p_fsExtraData = data.freespin.extra
    end

    if data.bonus ~= nil then
        self.p_bonusWinCoins = data.bonus.bsWinCoins
        self.p_bonusStatus = data.bonus.status
        self.p_bonusExtra = data.bonus.extra
    end

    self.p_jackpotPool = data.jackpotPool -- jack pot 奖池更新信息
    self.p_features = data.features -- 本轮触发的玩法列表  数组格式
    self.p_featuredata = data.featuredata -- 本轮触发小游戏具体数值玩法列表  数组格式
    self.p_jackpotMultiple = data.jackpotMultiple
    self.p_jackpotCoins = data.jackpotCoins

    if featureData == nil then featureData = {} end
    self.p_status = featureData.status
    self.p_chose = featureData.chose or featureData.choose
    self.p_pool = featureData.pool
    self.p_content = featureData.content
    self.p_allpoolindex = featureData.allpoolindex
    self.p_bnousGear = featureData.bnousGear

    self.p_prevReel = data.prevReel  -- 上面补充的信号列表
    self.p_nextReel = data.nextReel --  下面补充的信号列表

    self.p_selfMakeData = data.selfData

    self.p_avgBet = data.avgBet or 0 -- 平均bet

    self.p_payLineCount = data.payLineCount -- 赢钱线数量

    --满线关卡 按50条线计算
    if not self.p_payLineCount or self.p_payLineCount == 1 then
        self.p_payLineCount = 50
    end

    --兼容旧数据普通关卡
    if type(data.bet) == "table" then
        --最终使用的数据
        self.p_bet = data.bet.value
        --满线关卡默认bet为50
        if self.p_bet == 50 and type(data.betMultiplier) == "table" then
            self.p_bet = data.betMultiplier.value
        end
    elseif type(data.bet) == "number" then
        self.p_bet = data.bet
    end

    if data.collect ~= nil then
        self.p_collectTotalCount = data.collect.collectTotalCount
         --收集总数
        self.p_collectLeftCount = data.collect.collectLeftCount
         --当前收集数量
        self.p_collectCoinsPool = data.collect.collectCoinsPool
         --收集icons
        self.p_collectChangeCount = data.collect.collectChangeCount
        --本次收集的网络数据
        self.p_collectNetData = data.collect

    end

end

--[[
    @desc: 解析reel 信息
    time:2019-05-15 15:53:06
    --@data:
    @return:
]]
function SpinResultData:parseReelData( data )

    -- 计算轮盘结果数组
    self.p_reels = clone(data.reels) -- 多维数组， 根据轮盘的行列决定
    self.p_reelsData = {}
    self.p_colCount = 0
    if self.p_reels  and #self.p_reels > 0 then
        local firstRowDatas = self.p_reels[1]
        self.p_colCount = #firstRowDatas
        for i = 1, #self.p_reels do
            local rowDatas = self.p_reels[i]
            if rowDatas ~= nil then
                local copyReelData = {}
                for colIndex = 1, #rowDatas do
                    local symbolType = rowDatas[colIndex]
                    if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_NIL_TYPE then  -- 表明没有信号
                        copyReelData[colIndex] = symbolType
                    end
                end
                self.p_reelsData[#self.p_reelsData + 1] = copyReelData
            end
        end
    end

end

function SpinResultData:getWinLineDataWithPool( lineDataPool)
    local winLineData = nil
    if #lineDataPool > 0 then
        winLineData = lineDataPool[#lineDataPool]
        lineDataPool[#lineDataPool] = nil
    else
        winLineData = SpinWinLineData.new()
    end

    return winLineData
end

function SpinResultData:parseWinLines( data , lineDataPool)
    if data.lines ~= nil then
        for i = 1, #data.lines do
            local lineData = data.lines[i]

            -- if self.p_isAllLine == true and lineData.nums ~= nil and  #lineData.nums ~= 0 then
            --     self:parseAllLines(lineData , lineDataPool)
            -- else
                local winLineData = self:getWinLineDataWithPool(lineDataPool)
                winLineData.p_id = lineData.id
                winLineData.p_amount = lineData.amount
                winLineData.p_iconPos = lineData.icons
                winLineData.p_type = lineData.type
                winLineData.p_multiple = lineData.multiple
                self.p_winLines[#self.p_winLines + 1] = winLineData
            -- end

        end
    end
end
--[[
    @desc: 解析满线情况下所有连线的组合
    time:2019-01-02 21:34:32
]]
function SpinResultData:parseAllLines( lineData , lineDataPool)

    local allLineSymbolNums = lineData.nums
    local symbolPos = lineData.icons
    local preCount = 0
    local linesPos = {}
    -- 将对应每列的pos 信息组织起来
    for i=1,#allLineSymbolNums do
        local num = allLineSymbolNums[i]
        if num ~= 0 then
            local colPos = {}
            linesPos[#linesPos + 1] = colPos
            local idx = preCount + 1
            for j=idx,preCount + num do
                colPos[#colPos + 1] = symbolPos[j]
            end
            preCount = preCount + num
        end
    end

    -- 解析成 line 数据
    local allLines = {}
    self:parseLines(linesPos , 1, {} , allLines)

    for i=1,#allLines do
        local linePos = allLines[i]
        local winLineData = self:getWinLineDataWithPool(lineDataPool)
        winLineData.p_id = lineData.id
        winLineData.p_amount = lineData.lineAmount
        winLineData.p_iconPos = linePos
        winLineData.p_type = lineData.type
        winLineData.p_multiple = lineData.multiple
        self.p_winLines[#self.p_winLines + 1] = winLineData
    end

end

function SpinResultData:parseLines( datas, index , lines , allLines)
    if index > #datas then
        allLines[#allLines + 1] = lines
        return
    end
    local numData = datas[index]
    for idx=1,#numData do
        local num = numData[idx]
        local newLines = clone(lines)
        newLines[#newLines + 1] = num
        self:parseLines(datas,index + 1 , newLines,allLines)
    end
end

---
-- copy 目标数据
--
function SpinResultData:copyData(targetData, lineDataPool)
    assert(lineDataPool ~= nil, "赢钱线数据池 不能为空")

    self:clear(lineDataPool)

    if targetData.p_reels ~= nil then
        for i = 1, #targetData.p_reels do
            local rowDatas = targetData.p_reels[i]
            self.p_reels[#self.p_reels + 1] = rowDatas
        end

        for i = 1, #targetData.p_reelsData do
            local rowDatas = targetData.p_reelsData[i]
            self.p_reelsData[#self.p_reelsData + 1] = rowDatas
        end
    end

    if targetData.p_winLines ~= nil then
        for i = 1, #targetData.p_winLines do
            local targetLineData = targetData.p_winLines[i]

            local winLineData = nil
            if #lineDataPool > 0 then
                winLineData = lineDataPool[#lineDataPool]
                lineDataPool[#lineDataPool] = nil
            else
                winLineData = SpinWinLineData.new()
            end

            winLineData.p_id = targetLineData.p_id
            winLineData.p_amount = targetLineData.p_amount
            winLineData.p_iconPos = targetLineData.p_iconPos
            winLineData.p_type = targetLineData.type
            winLineData.p_multiple = targetLineData.p_multiple
            self.p_winLines[#self.p_winLines + 1] = winLineData
        end
    end

    self.p_winAmount = targetData.p_winAmount
    self.p_winAmountStr = targetData.p_winAmountStr

    -- bet 值信息
    self.p_bet = targetData.p_bet

    -- 解析玩法相关
    self.p_storedIcons = targetData.p_storedIcons -- 当前轮盘锁定icon pos
    self.p_reSpinsTotalCount = targetData.p_reSpinsTotalCount -- respin 总次数
    self.p_reSpinCurCount = targetData.p_reSpinCurCount -- respin 剩余次数
    self.p_reSpinStoredIcons = targetData.p_reSpinStoredIcons -- 本轮锁定 icons 的pos 列表
    self.p_freeSpinsTotalCount = targetData.p_freeSpinsTotalCount -- fs 总数量
    self.p_freeSpinsLeftCount = targetData.p_freeSpinsLeftCount -- fs 剩余次数
    self.p_fsMultiplier = targetData.p_fsMultiplier -- fs 当前轮数的倍数
    self.p_freeSpinNewCount = targetData.p_freeSpinNewCount -- fs 增加次数
    self.p_fsWinCoins = targetData.p_fsWinCoins -- fs 累计赢钱数量
    self.p_jackpotPool = targetData.p_jackpotPool -- jack pot 奖池更新信息
    self.p_features = targetData.p_features -- 本轮触发的玩法列表  数组格式
    self.p_featuredata = targetData.p_featuredata -- 本轮触发的小游戏玩法列表  数组格式

    self.p_collectTotalCount = targetData.p_collectTotalCount --收集总数
    self.p_collectLeftCount = targetData.p_collectLeftCount --当前收集数量
    self.p_collectCoinsPool = targetData.p_collectCoinsPool --收集icons
    self.p_collectChangeCount = targetData.p_collectChangeCount --本次收集数量
end
---
-- 当前freespin 次数下，赢钱总数
--
function SpinResultData:getCurFreeSpinWinRate()
    local rate = self.p_fsWinCoins / self.p_bet

    return rate
end

function SpinResultData:getBetValue()
    return self.p_bet*self.p_payLineCount
end

return SpinResultData
