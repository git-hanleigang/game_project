--[[
    处理各个bet档位的固定图标数据
    固定图标的展示
]]
local PenguinsBoomsCollectBar = class("PenguinsBoomsCollectBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "PenguinsBoomsPublicConfig"

--最大收集列数
PenguinsBoomsCollectBar.MaxCollectCount = 5
--渐变时长
PenguinsBoomsCollectBar.BgFadeTime    = 21/60
PenguinsBoomsCollectBar.KuLouFadeTime = 21/60


function PenguinsBoomsCollectBar:initUI(params)
    self.m_machine = params.machine
    --服务器的固定数据列表
    self.m_severBetDataList = {}
    --前端随机的固定数据(只保存当前bet数据,每次切换bet清空列表)
    self.m_randomBetDataList = {}

    self:createCsbNode("PenguinsBooms_collect_bar.csb")
    self:initCollectList()
    self:initKulouList()
end

--根据模式切换底栏
function PenguinsBoomsCollectBar:changeBgSpriteVisible(_bFree)
    self:findChild("basedi"):setVisible(not _bFree)
    self:findChild("freedi"):setVisible(_bFree)
    --骷髅透完全消失
    self:changeKuLouFreeSpriteVisible(_bFree)
end
--根据滚动状态修改透明度
function PenguinsBoomsCollectBar:changeBgSpriteOpacity(_bRun)
    local multiple = _bRun and 0.6 or 1
    local opacity  = 255 * multiple
    local spBase = self:findChild("basedi")
    local spFree = self:findChild("freedi")
    spBase:stopAllActions()
    spFree:stopAllActions()
    spBase:runAction(cc.FadeTo:create(self.BgFadeTime, opacity))
    spFree:runAction(cc.FadeTo:create(self.BgFadeTime, opacity))
    --骷髅透完全消失
    self:changeKuLouOpacity(_bRun)
end

--[[
    固定bonus
]]
function PenguinsBoomsCollectBar:initCollectList()
    local parent = self:findChild("Node_bomb")
    self.m_collectItems = {}
    for iCol = 1,self.MaxCollectCount do
        local item = self.m_machine:createPenguinsBoomsTempSymbol({
            symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
            machine    = self.m_machine,
        })
        parent:addChild(item)
        item:setVisible(false)
        local posNode = self:findChild(string.format("Node_%d", iCol))
        item:setPosition(util_getConvertNodePos(posNode, parent))
        --挂文本
        self:abbBonusSymbolLab(item)

        self.m_collectItems[iCol] = item
        --默认隐藏次数框
        self:updateBonusLabVisible(iCol, 0)
    end
end
function PenguinsBoomsCollectBar:abbBonusSymbolLab(_bonusNode)
    if _bonusNode.p_symbolImage then
        _bonusNode.p_symbolImage:removeFromParent()
        _bonusNode.p_symbolImage = nil
    end
    -- 默认一个spine上面最多有一个插槽可以挂cocos工程,存放的变量名称保持一致
    local animNode = _bonusNode:checkLoadCCbNode()
    if not animNode.m_slotCsb then
        -- 标准小块用的spine是 animNode.m_spineNode, 临时小块的spine直接是 animNode
        local spineNode = animNode.m_spineNode or (_bonusNode.m_symbolType and animNode) 
        animNode.m_slotCsb = util_createAnimation("PenguinsBooms_BonusLab.csb")
        util_spinePushBindNode(spineNode, "jiaobiao", animNode.m_slotCsb)
    end
end
function PenguinsBoomsCollectBar:updateBonusLabVisible(_iCol, _count)
    local bonusSymbol = self:getItemByColIndex(_iCol)
    local ccbNode     = bonusSymbol:getCCBNode()
    local slotCsb     = ccbNode.m_slotCsb
    local bVisible    = _count > 1
    slotCsb:setVisible(bVisible)
end
--获取固定bonus
function PenguinsBoomsCollectBar:getItemByColIndex(colIndex)
    local item = self.m_collectItems[colIndex]
    return item
end

-- 刷新收集道具
function PenguinsBoomsCollectBar:refreshCollectItems(data)
    if not data then
        data = {}
    end
    for iCol = 1,self.MaxCollectCount do
        self:refreshCollectItemsByCol(data,iCol)
    end
end
function PenguinsBoomsCollectBar:changeBetUpdateCollectItem(_collectData)
    for iCol = 1,self.MaxCollectCount do
        local item  = self:getItemByColIndex(iCol)
        local count = _collectData[tostring(iCol - 1)] or 0
        local bVisible = count > 0
        item:setVisible(bVisible)
        if bVisible then
            self:playChangeBetAnim(iCol, function()
                self:playIdleAnim(iCol)
            end)
        else
            self:playKuLouIdleAnim(iCol)
        end
    end
end
--按列刷新道具数量
function PenguinsBoomsCollectBar:refreshCollectItemsByCol(data, colIndex)
    if not data then
        data = {}
    end
    local item  = self:getItemByColIndex(colIndex)
    local count = data[tostring(colIndex - 1)] or 0
    local bVisible = count > 0

    item:setVisible(bVisible)
    if bVisible then
        self:updateBonusLabVisible(colIndex, count)
        self:playIdleAnim(colIndex)
    else
        self:playKuLouIdleAnim(colIndex)
    end
end
--清空收集进度 (free触发时 free和base是两套)
function PenguinsBoomsCollectBar:clearCollectBar( )
    for iCol = 1,self.MaxCollectCount do
        self:hideBomb(iCol)
    end
    for iCol=1,self.MaxCollectCount do
        self:playKuLouIdleAnim(iCol)
    end
end

--隐藏固定bonus
function PenguinsBoomsCollectBar:hideBomb(_iCol)
    local item = self:getItemByColIndex(_iCol)
    item:setVisible(false)
end
--切换bet时间线
function PenguinsBoomsCollectBar:playChangeBetAnim(_iCol, _fun)
    local animName = "bet"
    local item = self:getItemByColIndex(_iCol)
    item:runAnim(animName, false, _fun)
end
--循环idle
function PenguinsBoomsCollectBar:playIdleAnim(_colIndex)
    local animName = "idleframe2"
    local item = self:getItemByColIndex(_colIndex)
    item:runAnim(animName, true)
end
-- 滚动落地
function PenguinsBoomsCollectBar:playBulingAnim(_colIndex, _count)
    local animName = "buling1"
    local item = self:getItemByColIndex(_colIndex)
    item:setVisible(true)
    item:runAnim(animName, false, function()
        self:updateBonusLabVisible(_colIndex, _count)
        self:playIdleAnim(_colIndex)
    end)
end
--收集满的触发动画
function PenguinsBoomsCollectBar:playCollectTriggerAnim()
    for iCol=1,self.MaxCollectCount do
        local item = self:getItemByColIndex(iCol) 
        item:runAnim("actionframe2", false, function()
            self:playBombIdle1Anim(iCol)
        end)
    end
end
--全体待触发时间线
function PenguinsBoomsCollectBar:playBombWaitTriggerAnim()
    for iCol=1,self.MaxCollectCount do
        local item = self:getItemByColIndex(iCol) 
        item:runAnim("actionframe3", false, function()
            self:playBombIdle1Anim(iCol)
        end)
    end
end
--待触发
function PenguinsBoomsCollectBar:playBombIdle1Anim(_iCol)
    local item = self:getItemByColIndex(_iCol) 
    item:runAnim("idleframe1", true)
end
--随机增加固定bonus玩法
function PenguinsBoomsCollectBar:playBombAddBonusAnim(_colIndex, _playIdle)
    local animName = "add"
    local item = self:getItemByColIndex(_colIndex)
    item:setVisible(true)
    item:runAnim(animName, false, function()
        if _playIdle then
            self:playIdleAnim(_colIndex)
        end
    end)
end
--[[
    收集栏时间线相关
]]
function PenguinsBoomsCollectBar:playBarIdleAnim()
    self:runCsbAction("idle", true)
end


--[[
    骷髅头
]]
function PenguinsBoomsCollectBar:initKulouList()
    self.m_kulouList = {}
    for i=1,self.MaxCollectCount do
        local parent = self:findChild(string.format("Node_%d", i))
        local csb = util_createAnimation("PenguinsBooms_collect_kulou.csb")
        parent:addChild(csb)
        self.m_kulouList[i] = csb
    end
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_kulou"), true)
end
--普通idle
function PenguinsBoomsCollectBar:playKuLouIdleAnim(_iCol)
    local kulouCsb = self.m_kulouList[_iCol]
    kulouCsb:setVisible(true)
    kulouCsb:runCsbAction("idle", false)
end
--根据收集列数刷新所有骷髅的idle状态
function PenguinsBoomsCollectBar:upDateKuLouIdleAnim(_betValue)
    local collectData = self:getCollectDataByBetValue(_betValue)
    for _sIndex,_count in pairs(collectData) do
        if _count <= 0 then
            local iCol = tonumber(_sIndex) + 1
            self:playKuLouIdleAnim(iCol)
        end
    end
end
--根据模式修改资源
function PenguinsBoomsCollectBar:changeKuLouFreeSpriteVisible(_bFree)
    for i,_kulouCsb in ipairs(self.m_kulouList) do
        _kulouCsb:findChild("base"):setVisible(not _bFree) 
        _kulouCsb:findChild("free"):setVisible(_bFree) 
    end
end
--骷髅头滚动时透明度为0
function PenguinsBoomsCollectBar:changeKuLouOpacity(_bRun)
    local multiple = _bRun and 0 or 1
    local opacity  = 255 * multiple
    for i,_kulouCsb in ipairs(self.m_kulouList) do
        _kulouCsb:stopAllActions()
        _kulouCsb:runAction(cc.FadeTo:create(self.KuLouFadeTime, opacity))
    end
end
--[[
    各个档位bet的固定数据处理
]]
--服务器数据 初始化 修改 获取
function PenguinsBoomsCollectBar:setBetDataList(_betDataList)
    self.m_severBetDataList = _betDataList
end
function PenguinsBoomsCollectBar:setBetDataByBetValue(_betValue, _collectData)
    local sKey = tostring(_betValue)
    if not self.m_severBetDataList[sKey] then
        self.m_severBetDataList[sKey] = {}
    end
    self.m_severBetDataList[sKey].bonusPosition = _collectData
end
function PenguinsBoomsCollectBar:getServerCollectData(_betValue)
    local sKey = tostring(_betValue)
    local betData = self.m_severBetDataList[sKey]
    if betData and betData.bonusPosition then
        return betData.bonusPosition
    end
    return nil
end
-- 本地随机数据 获取 清理
function PenguinsBoomsCollectBar:getRandomCollectData(_betValue)
    local sKey = tostring(_betValue)
    local collectData = self.m_randomBetDataList[sKey]
    if self.m_randomBetDataList[sKey] and self.m_randomBetDataList[sKey].bonusPosition then
        return self.m_randomBetDataList[sKey].bonusPosition
    end
    local betLevel    = self.m_machine:getPenguinsBoomsBetLevelByValue(_betValue)
    local randomCount = betLevel
    collectData = {}
    local indexList   = {}
    --初始化数量列表和随机列表
    for _iCol=1,self.m_machine.m_iReelColumnNum do
        collectData[tostring(_iCol-1)] = 0
        table.insert(indexList, _iCol)
    end
    --随机排除
    while #indexList > randomCount do
        table.remove(indexList, math.random(1, #indexList))
    end
    --剩下的列数量修改为1
    for i,_iCol in ipairs(indexList) do
        collectData[tostring(_iCol-1)] = 1
    end


    self.m_randomBetDataList[sKey] = {}
    self.m_randomBetDataList[sKey].bonusPosition = collectData
    return collectData
end
function PenguinsBoomsCollectBar:clearRandomCollectData()
    self.m_randomBetDataList = {}
end


function PenguinsBoomsCollectBar:getCollectDataByBetValue(_betValue)
    local collectData = self:getServerCollectData(_betValue)
    -- collectData = { ["0"] = 0, ["1"] = 0, ["2"] = 0, ["3"] = 0, ["4"] = 0, }
    if not collectData then
        collectData = self:getRandomCollectData(_betValue)
        --日志
        local sMsg = string.format("[PenguinsBoomsCollectBar:getCollectDataByBetValue] 前端随机bonus位置 %d", _betValue)
        sMsg = string.format("%s %s", sMsg, cjson.encode(collectData) )
        util_printLog(sMsg, true)
    end

    return collectData
end

function PenguinsBoomsCollectBar:getCurShowCollectData()
    local betCoin     = globalData.slotRunData:getCurTotalBet() or 0
    local collectData = self:getServerCollectData(betCoin)

    local betLevel = self.m_machine:getPenguinsBoomsBetLevelByValue(betCoin)
end
--获取那些列有固定图标
function PenguinsBoomsCollectBar:getLockColData(_betValue, _collectData)
    local colData = {}
    if not _collectData then
        _collectData = self:getCollectDataByBetValue(_betValue)
    end

    for _sIndex,_count in pairs(_collectData) do
        if _count > 0 then
            local iCol = tonumber(_sIndex) + 1
            table.insert(colData, iCol)
        end
    end
    return colData
end

return PenguinsBoomsCollectBar