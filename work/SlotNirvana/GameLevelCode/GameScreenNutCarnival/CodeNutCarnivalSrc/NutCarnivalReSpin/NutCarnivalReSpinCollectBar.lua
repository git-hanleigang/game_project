--[[
    各种bonus的收集展示
    触发reSpin的次数 | 触发reSpin的全满乘倍
    各种bonus的收集
]]
local NutCarnivalReSpinCollectBar = class("NutCarnivalReSpinCollectBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "NutCarnivalPublicConfig"

function NutCarnivalReSpinCollectBar:initUI(_machine)
    self.m_machine = _machine
    self.m_collectData = {}
    self.m_collectTemplateData = {}

    self:createCsbNode("NutCarnival_respin_shoujig_gualan.csb")
    self:initCollectLab()
    self:initFeedbackAnim()

    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)
end

--[[
    数量文本
]]
function NutCarnivalReSpinCollectBar:initCollectLab()
    self.m_collectLabList = {}
    for _bonusIndex=1,4 do
        local parent = self:findChild(string.format("shuzi%d", _bonusIndex))
        local labCsb = util_createAnimation("NutCarnival_respin_shoujig_gualan_shuzi.csb")
        parent:addChild(labCsb)
        --收集数量
        labCsb.m_collectCount = 0
        self.m_collectLabList[_bonusIndex] = labCsb
    end
end
function NutCarnivalReSpinCollectBar:updateAllCollectCount(_bAnim)
    local list = {
        self.m_machine.SYMBOL_SpecialBonus_1,
        self.m_machine.SYMBOL_SpecialBonus_2,
        self.m_machine.SYMBOL_SpecialBonus_3,
        self.m_machine.SYMBOL_SpecialBonus_4,
    }
    -- 先不播
    if _bAnim then
        -- self:playUpdateBetLevelAnim(list, nil)
        for i,_symbolType in ipairs(list) do
            self:updateCollectCount(_symbolType)
        end
    else
        for i,_symbolType in ipairs(list) do
            self:updateCollectCount(_symbolType)
        end
    end
end
function NutCarnivalReSpinCollectBar:updateCollectCount(_symbolType, _count)
    local count = _count     if not count then
        local betCoin = globalData.slotRunData:getCurTotalBet()
        count = self:getCollectCount(betCoin, _symbolType)
    end
    local index = self.m_machine:getSpecialBonusIndex(_symbolType)
    local labCsb = self.m_collectLabList[index]
    local labNode  = labCsb:findChild("m_lb_coins")
    labNode:setString(count)
    labCsb.m_collectCount = count
    -- local labInfoList = {
    --     [1] = {118, 0.37, 0.37},
    --     [2] = {115, 0.4,  0.4},
    --     [3] = {134, 0.47, 0.47},
    --     [4] = {140, 0.53, 0.53},
    -- }
    -- local labInfo = labInfoList[index]
    self:updateLabelSize({label=labNode, sx=1, sy=1}, 140)
end

--收集反馈
function NutCarnivalReSpinCollectBar:initFeedbackAnim()
    local parent = self:findChild("Node_fankui")
    self.m_feedbackAnimList = {}
    for _index=1,4 do
        local node  = self:findChild(string.format("Sprite_light_%d", _index))
        local feedbackAnim = util_createAnimation("NutCarnival_fankui.csb")
        parent:addChild(feedbackAnim)
        feedbackAnim:setVisible(false)
        feedbackAnim:setPosition(util_convertToNodeSpace(node, parent))
        self.m_feedbackAnimList[_index] = feedbackAnim
    end
end
function NutCarnivalReSpinCollectBar:getCollectFlyEndPos(_symbolType)
    local index = self.m_machine:getSpecialBonusIndex(_symbolType)
    local node  = self:findChild(string.format("Sprite_light_%d", index))
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return worldPos
end


--[[
    时间线
]]
function NutCarnivalReSpinCollectBar:playIdleAnim()
    self:runCsbAction("idle", true)
end
function NutCarnivalReSpinCollectBar:playCollectFeedbackAnim(_betValue, _collectDataList, _fun)
    --[[
        _collectDataList = {
            [信号] = 新增数量
        }
    ]]
    local fankuiNode = self:findChild("Node_fankui")
    fankuiNode:stopAllActions()
    local symbolTypeList = {}
    for _symbolType,_addCount in pairs(_collectDataList) do
        table.insert(symbolTypeList, _symbolType)
    end
    --爆点
    for i,_symbolType in ipairs(symbolTypeList) do
        local index = self.m_machine:getSpecialBonusIndex(_symbolType)
        local feedbackAnim = self.m_feedbackAnimList[index]
        feedbackAnim:stopAllActions()
        feedbackAnim:setVisible(true)
        local animName = "fankui2"
        local animTime = util_csbGetAnimTimes(feedbackAnim.m_csbAct, animName)
        feedbackAnim:runCsbAction(animName, false)
        performWithDelay(feedbackAnim, function()
            feedbackAnim:setVisible(false)
        end, animTime)
    end
    --刷光
    performWithDelay(fankuiNode, function()
        self:playUpdateBetLevelAnim(symbolTypeList, function()
            local curBet     = globalData.slotRunData:getCurTotalBet()
            local bBetChange = _betValue ~= curBet
            --刷新数量-快停时每次收集只刷新那一次的新增数量
            for _symbolType,_addCount in pairs(_collectDataList) do
                local bonusIndex = self.m_machine:getSpecialBonusIndex(_symbolType)
                local labCsb     = self.m_collectLabList[bonusIndex]
                local curCount   = labCsb.m_collectCount
                local newCount   = nil
                if not bBetChange then
                    newCount   = math.min(self:getCollectCount(curBet, _symbolType), curCount + _addCount)
                end
                self:updateCollectCount(_symbolType, newCount)
            end
        end)
        --下一步
        performWithDelay(fankuiNode, _fun, 63/60)
    end, 9/60)
end
function NutCarnivalReSpinCollectBar:playTriggerAnim(_symbolType, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bonusCollectBar_trigger)
    for _index=1,4 do
        local index    = self.m_machine:getSpecialBonusIndex(_symbolType)
        local bVisible = _index == index
        local nodeName = string.format("light_%d", _index)
        self:findChild(nodeName):setVisible(bVisible)
    end
    self:runCsbAction("actionframe", true)

    self.m_machine:levelPerformWithDelay(self, 120/60, function()
        self:playIdleAnim()
        if _fun then
            _fun()
        end
    end)
end
function NutCarnivalReSpinCollectBar:playUpdateBetLevelAnim(_symbolTypeList, _fun)
    _fun = _fun or function() end
    self.m_delayNode:stopAllActions()
    --打开指定的刷光
    for _bonusIndex=1,4 do
        self:findChild(string.format("shuaxin_%d", _bonusIndex)):setVisible(false)
    end
    for _index,_symbolType in ipairs(_symbolTypeList) do
        local bonusIndex = self.m_machine:getSpecialBonusIndex(_symbolType)
        local nodeName   = string.format("shuaxin_%d", bonusIndex)
        self:findChild(nodeName):setVisible(true)
        --数量文本 提出来单独刷新
        local labCsb = self.m_collectLabList[bonusIndex]
        labCsb:runCsbAction("shuaxin", false)
    end
    self:runCsbAction("shuaxin", false)
    
    performWithDelay(self.m_delayNode, function()
        _fun()
        performWithDelay(self.m_delayNode, function()
            for _bonusIndex=1,4 do
                self:findChild(string.format("shuaxin_%d", _bonusIndex)):setVisible(false)
            end
            self:playIdleAnim()
        end, 39/60)
    end, 21/60)
end

--[[
    数据
]]
function NutCarnivalReSpinCollectBar:setReSpinTemplateCollectData(_templateData)
    self.m_collectTemplateData = {}
    for _sSymbolType,_sCount in pairs(_templateData) do
        local count = tonumber(_sCount)
        self.m_collectTemplateData[_sSymbolType] = count
    end
end
function NutCarnivalReSpinCollectBar:setReSpinCollectCount(_betValue, _data)
    local sKey = tostring(toLongNumber(_betValue))
    if not self.m_collectData[sKey] then
        self.m_collectData[sKey] = {}
    end
    for _sSymbolType,_sCount in pairs(_data) do
        local count = tonumber(_sCount)
        self.m_collectData[sKey][_sSymbolType] = count
    end
end
function NutCarnivalReSpinCollectBar:getCollectDataByBet(_betValue)
    local sKey    = tostring(toLongNumber(_betValue))
    local betData = self.m_collectData[sKey]
    if not betData then
        betData = self.m_collectTemplateData
    end
    return betData
end
function NutCarnivalReSpinCollectBar:getCollectCount(_betValue, _symbolType)
    local betData = self:getCollectDataByBet(_betValue)
    local sSymbolType = tostring(_symbolType)
    local count = betData[sSymbolType] or 0
    return count
end
return NutCarnivalReSpinCollectBar