--[[
    固定图标
]]
local CherryBountyLockWild = class("CherryBountyLockWild")
local PublicConfig = require "CherryBountyPublicConfig"

function CherryBountyLockWild:initData_(_data)
    --[[
        _data = {
            machine = machine
            parent  = cc.Node
        }
    ]]
    self.m_machine   = _data.machine
    self.m_parent    = _data.parent
    self.m_showTimes = 3          --展示次数比实际次数大1
    self.m_betList   = {}
    self.m_bulingCol = 0          --首个调用buling的列

    self:initUI()
end
function CherryBountyLockWild:initUI(_machine)
    self.m_wildList = {}
    self.m_wildPool = {}
    self:resetLockWild()
end
function CherryBountyLockWild:resetLockWild()
    self.m_showTimes = 0
    if #self.m_wildList <= 0 then
        return
    end
    self.m_wildList  = {}
    self.m_wildPool  = {}
    for i,_wild in ipairs(self.m_parent:getChildren()) do
        _wild.m_reelPos = -1
        _wild:setVisible(false)
        _wild:runAnim("idleframe", false)
        table.insert(self.m_wildPool, _wild)
    end
end
--固定wild-创建
function CherryBountyLockWild:craeteLockWild(_reelPos, _showTimes)
    local wild = nil
    if #self.m_wildPool > 0 then
        wild = table.remove(self.m_wildPool, 1)
        wild:setVisible(true)
    end
    if nil == wild then
        wild = util_createView("CherryBountySrc.CherryBountyTempSymbol", {machine=self.m_machine})
        self.m_parent:addChild(wild)
        wild:changeSymbolCcb(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    end
    wild.m_reelPos = _reelPos
    self:upDateLockWildPos(wild)
    self.m_machine:upDateWildTimes(wild, _showTimes-1)
    local fixPos = self.m_machine:getCherryBountyRowAndColByPos(_reelPos)
    local order = fixPos.iY*10 - fixPos.iX
    wild:setLocalZOrder(order)
    table.insert(self.m_wildList, wild)
    return wild
end
--固定wild-spin重置数据状态
function CherryBountyLockWild:MachineSpinBtnCall()
    self.m_bulingCol = 0
end

--固定wild-落地
function CherryBountyLockWild:playLockWildBulingAnim(_symbol, _speedActionTable)
    local iCol    = _symbol.p_cloumnIndex
    local iRow    = _symbol.p_rowIndex
    local reelPos = self.m_machine:getCherryBountyPosReelIdx(iRow, iCol)
    local wild = self:getLockWildByReelPos(reelPos)
    local bHas = nil~=wild
    local showTimes = 3
    --重置wild次数
    self:playLockWildResetTimesAnim(iCol)
    --当前位置补充wild
    if not bHas then
        wild = self:craeteLockWild(reelPos, showTimes)
    end
    --回弹
    local machine = self.m_machine
    local newSpeedActionTable = {}
    local tabLen = #_speedActionTable
    for i = 1,tabLen do
        if i == tabLen then
            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
            local resTime = machine.m_configData.p_reelResTime
            local index = machine:getCherryBountyPosReelIdx(iRow, iCol)
            local tarSpPos = util_getOneGameReelsTarSpPos(machine, index)
            -- 父节点在棋盘中心时不需要在进行下面的转换
            -- local reelNode = machine:findChild("sp_reel_" .. (iCol - 1))
            -- local tarSpWorldPos = reelNode:getParent():convertToWorldSpace(tarSpPos)
            -- local pos = wild:getParent():convertToNodeSpace(tarSpWorldPos) 
            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
        else
            newSpeedActionTable[i] = _speedActionTable[i]
        end
    end
    wild:setPosition( util_convertToNodeSpace(_symbol, wild:getParent()))
    wild:runAnim("buling", false, function()
        self.m_machine.m_symbolExpectCtr:playSymbolIdleAnim(wild)
    end)
    wild:runAction( cc.Sequence:create(newSpeedActionTable):clone() )
    if bHas then
        self.m_machine:levelPerformWithDelay(self.m_machine, 1/30, function()
            --将次数重置为3
            self.m_machine:upDateWildSymbolSkin(wild, showTimes)
        end)
    end
end
--固定wild-落地时有老的wild需要重置次数
function CherryBountyLockWild:playLockWildResetTimesAnim(_iCol)
    if 0 ~= self.m_bulingCol then
        return
    end
    self.m_bulingCol = _iCol
    self.m_machine:playEFFECT_WildTimes(function() end)
end


--固定wild-次数刷新
function CherryBountyLockWild:playAllWildTimesAnim(_times, _allPos, _newPos)
    self.m_showTimes = _times+1
    local animTime = 0
    local posList = self:getLastLockPosList(_allPos, _newPos)
    for i,_reelPos in ipairs(posList) do
        local wild = self:getLockWildByReelPos(_reelPos)
        if not wild then
            wild = self:craeteLockWild(_reelPos, self.m_showTimes)
            self.m_machine.m_symbolExpectCtr:playSymbolIdleAnim(wild)
        else
            animTime = self:playLockWildTimesAnim(wild, self.m_showTimes)
        end
    end
    return animTime
end
--固定wild-次数重置
function CherryBountyLockWild:playAllWildReSetTimesAnim(_times, _allPos, _newPos)
    self.m_showTimes = _times+1
    local animTime = 0
    local posList = self:getLastLockPosList(_allPos, _newPos)
    for i,_reelPos in ipairs(posList) do
        local wild = self:getLockWildByReelPos(_reelPos)
        if not wild then
            wild = self:craeteLockWild(_reelPos, self.m_showTimes)
        end
        animTime = self:playLockWildTimesAnim(wild, self.m_showTimes)
    end
    return animTime
end
function CherryBountyLockWild:playLockWildTimesAnim(_wild, _showTimes)
    local animName = "switch2"
    _wild:runAnim(animName, false, function()
        self.m_machine.m_symbolExpectCtr:playSymbolIdleAnim(_wild)
    end)
    self.m_machine:levelPerformWithDelay(self.m_machine, 9/30, function()
        self.m_machine:upDateWildSymbolSkin(_wild, _showTimes)
    end)
    return _wild:getAniamDurationByName(animName)
end
--固定wild-连线隐藏
function CherryBountyLockWild:hideLockWildByLineFrame()
    for i,_wild in ipairs(self.m_wildList) do
        _wild:setVisible(false)
    end
    self:supplementWildReelSymbol()
end
--固定wild-替换棋盘图标为wild
function CherryBountyLockWild:supplementWildReelSymbol()
    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for i,_wild in ipairs(self.m_wildList) do
        local reelPos = _wild.m_reelPos
        local fixPos = self.m_machine:getCherryBountyRowAndColByPos(reelPos) 
        local symbol = self.m_machine:getFixSymbol(fixPos.iY, fixPos.iX)
        if symbol.p_symbolType ~= symbolType then
            --^^^测试代码
            local sMsg = string.format("[CodeGameScreenCherryBountyMachine:supplementWildReelSymbol] wild替换 %d", reelPos) 
            print(sMsg)
            release_print(sMsg)
            --^^^测试代码 end
            self.m_machine:changeReelSymbolType(symbol, symbolType)
            self.m_machine:upDateWildTimes(symbol, self.m_showTimes-1)
        end
        self.m_machine:changeReelSymbolOrder(symbol, true)
        self.m_machine.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
    end
end
--固定wild-连线结束展示
function CherryBountyLockWild:showLockWildByLineFrameOver()
    for i,_wild in ipairs(self.m_wildList) do
        _wild:setVisible(true)
    end
end
--固定wild-spin时如果当前次数为1则滚走
function CherryBountyLockWild:spinResetLockWild()
    self:supplementWildReelSymbol()
    self:resetLockWild()
end
--固定wild-获取不包含本次新增的坐标列表
function CherryBountyLockWild:getLastLockPosList(_allPos, _newPos)
    local posList = {}
    for i,_reelPos in ipairs(_allPos) do
        local bHas = false
        for i,_newReelPos in ipairs(_newPos) do
            bHas = _reelPos==_newReelPos
            if bHas then
                break
            end
        end
        if not bHas then
            table.insert(posList, _reelPos)
        end
    end
    return posList
end


--设置固定wild-坐标
function CherryBountyLockWild:upDateLockWildPos(_wild)
    local reelPos = _wild.m_reelPos
    local pos = self:getLockPosByReelPos(reelPos, self.m_parent)
    _wild:setPosition(pos)
end
--获取固定wild-节点
function CherryBountyLockWild:getLockWildByReelPos(_reelPos)
    for i,_wild in ipairs(self.m_wildList) do
        if _wild.m_reelPos == _reelPos then
            return _wild
        end
    end
    return nil
end
--获取固定wild-坐标
function CherryBountyLockWild:getLockPosByReelPos(_reelPos, _parent)
    local fixPos        = self.m_machine:getCherryBountyRowAndColByPos(_reelPos)
    local reelName      = string.format("sp_reel_%d", (fixPos.iY - 1))
    local reelNode      = self.m_machine:findChild(reelName)
    local symbolNodePos = cc.p(0, 0) 
    symbolNodePos.x     = self.m_machine.m_SlotNodeW * 0.5
    symbolNodePos.y     = (fixPos.iX - 0.5) * self.m_machine.m_SlotNodeH
    local worldPos      = reelNode:convertToWorldSpace(symbolNodePos)
    local pos = _parent:convertToNodeSpace(worldPos)
    return pos
end


--固定wild数据-进入关卡刷新
function CherryBountyLockWild:initLockWildBetList(_betList)
    self.m_betList = _betList
    --[[
        m_betList = {
            "100" = {
                leftTimes = 1,
                wild_position = {0, 1}
            }
        }
    ]]
end
--固定wild数据-spin刷新
function CherryBountyLockWild:spinUpDateLockWildBetList(_result)
    if not _result.selfData.leftTimes or not _result.selfData.wild_position then
        return
    end
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local betKey   = self.m_machine:getCherryBountyLongNumString(totalBet)
    local betData  = {}
    betData.leftTimes     = _result.selfData.leftTimes or 0
    betData.wild_position = _result.selfData.wild_position or {}
    self.m_betList[betKey] = betData
end
--固定wild数据-获取一个bet下的数据
function CherryBountyLockWild:geLockWildDataByBet(_betValue)
    local betKey  = self.m_machine:getCherryBountyLongNumString(_betValue)
    local betData = self.m_betList[betKey]
    if not betData then
        betData = {}
        betData.leftTimes     = 0
        betData.wild_position = {}
    end
    return betData
end

return CherryBountyLockWild