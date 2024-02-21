local FlamingPompeiiRespinTopReelNode = class("FlamingPompeiiRespinTopReelNode",util_require("Levels.BaseLevelDialog"))

function FlamingPompeiiRespinTopReelNode:initUI(params)
    self.m_machine   = params.machine
    self.m_initData  = params
    --停轮数据
    self.m_finalData = {}
    --[[
        m_initData = {
            machine       = machine,
            buffReelIndex = 1
        }
    ]]
    -- 上一次停轮索引
    self.m_lastReelIndex = 1

    self:createCsbNode("FlamingPompeii_Wheel.csb")
    --创建横向滚轮
    self.m_reel_horizontal = self:createSpecialReelHorizontal()
    self:findChild("sp_reel"):addChild(self.m_reel_horizontal)
    --棋盘背景光
    self.m_bgLight = util_createAnimation("FlamingPompeii_Wheel_BeiGuang.csb")
    self:findChild("Node_beiGuang"):addChild(self.m_bgLight)
    self.m_bgLight:setVisible(false)
    --棋盘背景光粒子
    self.m_bgLightParticle = util_createAnimation("FlamingPompeii_Wheel_xiaoshi_lizi.csb")
    self:findChild("Node_lizi"):addChild(self.m_bgLightParticle)
    self.m_bgLightParticle:setVisible(false)
end

--[[
    创建特殊轮子-横向
]]
function FlamingPompeiiRespinTopReelNode:createSpecialReelHorizontal()
    local sp_wheel  = self:findChild("sp_reel")
    local wheelSize = sp_wheel:getContentSize()
    local configData = self.m_machine.m_reSpinReel.m_configData 
    local reelData  = configData:getReSpinBuffReelData(self.m_initData.buffReelIndex)
    local iCol = 1
    local iRow = 5
    local reelResTime = 0.5
    local reelNode  =  util_require("CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiRespinTopReelNode"):create({
        --列数据
        parentData  = {
            reelDatas = reelData,
            beginReelIndex = 1,
            slotNodeW = wheelSize.width / iRow,
            slotNodeH = wheelSize.height,
            reelHeight = wheelSize.height,
            reelWidth = wheelSize.width,
            isDone = false
        },     
        --列配置数据 
        configData = {
            p_reelMoveSpeed = 1000,
            p_rowNum = 5,
            p_reelBeginJumpTime = 0.2,
            p_reelBeginJumpHight = 20,
            p_reelResTime = reelResTime,
            p_reelResDis = 15,
            p_reelRunDatas = {19}
        },      
        --创建小块      
        createSymbolFunc = function(symbolType, rowIndex, colIndex, isLastNode, _lastNodeCount)
            local symbolNode = self:createWheelNode(symbolType, rowIndex, colIndex, isLastNode, _lastNodeCount)
            return symbolNode
        end,
        --小块放回缓存池
        pushSlotNodeToPoolFunc = function(symbolType,symbolNode)
            
        end,
        --小块数据刷新回调
        updateGridFunc = function(symbolNode)
            self:upDateReelGrid(symbolNode)
        end,  
        --0纵向 1横向 默认纵向
        direction = 1,      
        colIndex = 1,
        --必传参数
        machine = self.m_machine,    
        --列停止回调
        doneFunc = function()
            local fnNext = self.m_finalData.nextFun
            self.m_finalData.nextFun = nil
            if "function" == type(fnNext) then
                --回弹
                self.m_machine:levelPerformWithDelay(self, reelResTime, fnNext)
            end
        end,
    })
    return reelNode
end

function FlamingPompeiiRespinTopReelNode:createWheelNode(symbolType, rowIndex, colIndex, isLastNode, _lastNodeCount)
    local tempSymbol = self.m_machine:createFlamingPompeiiTempSymbol(symbolType, {
        iCol = colIndex,
        iRow = rowIndex,
    })
    tempSymbol.m_isLastSymbol  = isLastNode
    tempSymbol.m_lastNodeCount = _lastNodeCount or 6

    return tempSymbol
end

function FlamingPompeiiRespinTopReelNode:upDateReelGrid(_symbolNode)
    self:reSetBuff2BonusRewardVisible(_symbolNode)
    self:upDateMultiSymbol(_symbolNode)
    self:upDateUpRowSymbol(_symbolNode)
    self:upDateAddBonusCoinsSymbol(_symbolNode)
    self:upDateBuff2BonusSymbol(_symbolNode)
end
function FlamingPompeiiRespinTopReelNode:reSetBuff2BonusRewardVisible(_symbolNode)
    if _symbolNode.m_symbolType ~= self.m_machine.SYMBOL_Buff2_bonus then
        return
    end

    _symbolNode:getCcbProperty("grand"):setVisible(false)
    _symbolNode:getCcbProperty("mega"):setVisible(false)
    _symbolNode:getCcbProperty("major"):setVisible(false)
    _symbolNode:getCcbProperty("minor"):setVisible(false)
    _symbolNode:getCcbProperty("mini"):setVisible(false)
    _symbolNode:getCcbProperty("m_lb_coins"):setVisible(false)
    _symbolNode:getCcbProperty("sp_multip_2"):setVisible(false)
    _symbolNode:getCcbProperty("sp_multip_3"):setVisible(false)
    _symbolNode:getCcbProperty("sp_multip_4"):setVisible(false)
end
function FlamingPompeiiRespinTopReelNode:upDateMultiSymbol(_symbolNode)
    if _symbolNode.m_symbolType ~= self.m_machine.SYMBOL_Buff1_multi then
        return
    end

    local value = nil
    --最终数据
    if _symbolNode.m_isLastSymbol and _symbolNode.m_symbolType == self.m_finalData.symbolType and _symbolNode.m_lastNodeCount == 2 then
        value = self.m_finalData.serverData[3]
    end
    --随机数据
    if not value then
        local configData = self.m_machine.m_reSpinReel.m_configData 
        value  = configData:getBuffReel1MultiPro()
    end
    local label   = _symbolNode:getCcbProperty("m_lb_num")
    local sReward = string.format("X%d", value)
    label:setString(sReward)
    self.m_machine:updateLabelSize({label=label, sx=0.7, sy=0.7}, 90)
end
function FlamingPompeiiRespinTopReelNode:upDateUpRowSymbol(_symbolNode)
    if _symbolNode.m_symbolType ~= self.m_machine.SYMBOL_Buff1_upRow then
        return
    end
    
    local value = nil
    --最终数据
    if _symbolNode.m_isLastSymbol and _symbolNode.m_symbolType == self.m_finalData.symbolType and _symbolNode.m_lastNodeCount == 2 then
        value = self.m_finalData.serverData[3]
    end
    --随机数据
    if not value then
        local configData = self.m_machine.m_reSpinReel.m_configData 
        value  = configData:getBuffReel1UpRowPro()
    end
    local label   = _symbolNode:getCcbProperty("m_lb_num")
    local sReward = string.format("+%d", value)
    label:setString(sReward)
    self.m_machine:updateLabelSize({label=label, sx=0.7, sy=0.7}, 90)
end
function FlamingPompeiiRespinTopReelNode:upDateAddBonusCoinsSymbol(_symbolNode)
    if _symbolNode.m_symbolType ~= self.m_machine.SYMBOL_Buff1_addBonusCoins then
        return
    end
    
    local value = nil
    --最终数据
    if _symbolNode.m_isLastSymbol and _symbolNode.m_symbolType == self.m_finalData.symbolType and _symbolNode.m_lastNodeCount == 2 then
        value = self.m_finalData.serverData[3]
    end
    --随机数据
    if not value then
        local configData = self.m_machine.m_reSpinReel.m_configData 
        value  = configData:getBuffReel1AddBonusCoins()
    end
    local label       = _symbolNode:getCcbProperty("m_lb_num")
    local rewardValue = value * globalData.slotRunData:getCurTotalBet()
    local sReward     = string.format("+%s", util_formatCoins(rewardValue, 3))
    label:setString(sReward)
    self.m_machine:updateLabelSize({label=label, sx=0.47, sy=0.55}, 273)
end
function FlamingPompeiiRespinTopReelNode:upDateBuff2BonusSymbol(_symbolNode)
    if _symbolNode.m_symbolType ~= self.m_machine.SYMBOL_Buff2_bonus then
        return
    end
    
    local value = nil
    local jpName = ""
    --最终数据
    if _symbolNode.m_isLastSymbol and _symbolNode.m_symbolType == self.m_finalData.symbolType and _symbolNode.m_lastNodeCount == 2 then
        value  = self.m_finalData.serverData[3]
        jpName = self.m_finalData.serverData[4]
    end
    --随机数据
    if not value then
        local configData = self.m_machine.m_reSpinReel.m_configData 
        local bLockGrand = self.m_machine:getGrandLockState()
        if bLockGrand then
            value  = configData:getBuffReel2WinCoinsNotGrand()
        else
            value  = configData:getBuffReel2WinCoins()
        end
        jpName = value
    end

    local jpIndex = self.m_machine.JackpotNameToIndex[jpName]
    if nil ~= jpIndex then
        local jackpotNode = _symbolNode:getCcbProperty(jpName)
        jackpotNode:setVisible(true) 
    else
        local bonusMulti = tonumber(value)
        local curMultip  = self.m_finalData.curMultip or 1
        local newMulti   = curMultip * bonusMulti
        local coins      = newMulti * globalData.slotRunData:getCurTotalBet()
        local sCoins     = util_formatCoins(coins, 3)
        local label      = _symbolNode:getCcbProperty("m_lb_coins")
        label:setString(sCoins)
        self:updateLabelSize({label=label, sx=1.25, sy=1.25}, 75)
        label:setVisible(true) 

        local multiNodeName = string.format("sp_multip_%d", bonusMulti)
        local multiNode     = _symbolNode:getCcbProperty(multiNodeName)
        if multiNode then
            multiNode:setVisible(true)
        end
    end
end

--[[
    滚动流程
]]
function FlamingPompeiiRespinTopReelNode:startMove()
    self.m_reel_horizontal:startMove()
end

function FlamingPompeiiRespinTopReelNode:stopMove(_finalData)
    self.m_finalData = _finalData
    --[[
        _finalData = {
            symbolType = 0,
            serverData = {触发格子，触发类型(1~5)，具体效果，效果位置},
            nextFun    = fn,
            curMultip  = 1,         --修改位置bonus的当前乘倍
            curMultiType "",        --修改位置bonus的当前乘倍类型
        }
    ]]
    local lastReelData = self:getLastReelData(_finalData.symbolType)

    self.m_reel_horizontal:setSymbolList(lastReelData)
    self.m_reel_horizontal.m_needDeceler = true
    self.m_reel_horizontal.m_runTime = 0
end
function FlamingPompeiiRespinTopReelNode:getLastReelData(_finalSymbol)
    local configData = self.m_machine.m_reSpinReel.m_configData 
    local reelList   = configData:getReSpinBuffReelData(self.m_initData.buffReelIndex)

    --最终信号放在第三位
    local fnGetLastReelData = function(_startIndex)
        local data,reelIndex = {},1
        for _reelIndex=_startIndex,#reelList do
            local symbolType = reelList[_reelIndex]
            if symbolType == _finalSymbol then
                reelIndex = _reelIndex
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, _reelIndex-2))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, _reelIndex-1))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, _reelIndex))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, _reelIndex+1))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, _reelIndex+2))
                break
            end
            _reelIndex = _reelIndex + 1
        end
        return data,reelIndex
    end
    
    local data,reelIndex = fnGetLastReelData(self.m_lastReelIndex)
    if #data < 1 then
        data,reelIndex = fnGetLastReelData(1)
    end
    self.m_lastReelIndex = reelIndex

    return data
end

function FlamingPompeiiRespinTopReelNode:getSymbolTypeByReelIndex(_reelList, _reelIndex)
    if #_reelList < 1 then
        return self.m_machine.SYMBOL_Blank
    end
    local reelIndex = 1
    if nil ~= _reelList[_reelIndex] then
        reelIndex = _reelIndex
    elseif 0 < _reelIndex then
        reelIndex = math.mod(#_reelList, _reelIndex)
        if 0 == reelIndex then
            reelIndex = #_reelList
        end
    elseif 0 == _reelIndex then
        reelIndex = #_reelList
    elseif 0 > _reelIndex then
        reelIndex = math.mod(#_reelList, math.abs(_reelIndex))
        if 0 == reelIndex then
            reelIndex = #_reelList
        else
            reelIndex = #_reelList - reelIndex
        end
    end

    return _reelList[reelIndex]
end

--[[
    动画执行
]]
function FlamingPompeiiRespinTopReelNode:playReelAnim_start(_fun)
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:runCsbAction("start", false, _fun)
end
function FlamingPompeiiRespinTopReelNode:playReelAnim_over(_fun)
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:runCsbAction("over", false, _fun)
end
--[[
    背景光动画
]]
function FlamingPompeiiRespinTopReelNode:playBgLightAnim_start()
    self.m_bgLight:setVisible(true)
    self.m_bgLight:runCsbAction("start", false, function()
        self.m_bgLight:runCsbAction("idle", true)
    end)
end

function FlamingPompeiiRespinTopReelNode:playBgLightLiZiOverAnim(_fun)
    self.m_bgLightParticle:setVisible(true)
    self.m_bgLightParticle:runCsbAction("over", false, function()
        self.m_bgLightParticle:setVisible(false)
        _fun()
    end)
end

function FlamingPompeiiRespinTopReelNode:playReelAnim_animation(_fun)
    self:runCsbAction("animation0", false, _fun)
end

function FlamingPompeiiRespinTopReelNode:playBgLightAnim_over(_fun)
    self.m_bgLight:runCsbAction("over", false, function()
        self.m_bgLight:setVisible(false)
        _fun()
    end)
end

return FlamingPompeiiRespinTopReelNode