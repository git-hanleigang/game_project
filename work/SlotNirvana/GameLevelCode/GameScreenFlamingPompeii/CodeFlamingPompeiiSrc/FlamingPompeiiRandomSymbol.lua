local FlamingPompeiiRandomSymbol = class("FlamingPompeiiRandomSymbol", util_require("base.BaseView"))
local FlamingPompeiiPublicConfig = require "FlamingPompeiiPublicConfig"

FlamingPompeiiRandomSymbol.Order = {
    RandomSymbol_Wild = 10,
    RandomSymbol_Bonus = 50,
    RandomSymbol_Scatter = 100,
    MaskSymbol   = 200,
}
function FlamingPompeiiRandomSymbol:initDatas(_machine)
    self.m_machine  = _machine

    self.m_reelMask = self.m_machine:findChild("Panel_randomSymbol")
    self.m_reelMask:setVisible(false)
end

--添加随机图标
function FlamingPompeiiRandomSymbol:addRandomSymbolWild(_posList)
    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for i,_iPos in ipairs(_posList) do
        local fixPos     = self.m_machine:getRowAndColByPos(_iPos) 
        local tempSymbol = self.m_machine:createFlamingPompeiiTempSymbol(symbolType, {})
        local order      = self.Order.RandomSymbol_Wild
        order = order + 10 * fixPos.iY - fixPos.iX
        self:addChild(tempSymbol, order)
        tempSymbol:setVisible(false)
        self:upDateRandomSymbol(tempSymbol, fixPos.iY, fixPos.iX)

        self:playMaskSymbolAnim(fixPos.iY, fixPos.iX, function()
            tempSymbol:setVisible(true)
        end)
    end
end
--添加随机图标
function FlamingPompeiiRandomSymbol:addRandomSymbolScatter(_posList)
    if #_posList > 0 then
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_scatter_buling)
    end

    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    for i,_iPos in ipairs(_posList) do
        local fixPos     = self.m_machine:getRowAndColByPos(_iPos) 
        local tempSymbol = self.m_machine:createFlamingPompeiiTempSymbol(symbolType, {
            iCol = fixPos.iY,
            iRow = fixPos.iX,
        })
        local order      = self.Order.RandomSymbol_Scatter
        order = order + 10 * fixPos.iY - fixPos.iX
        self:addChild(tempSymbol, order)
        tempSymbol:setVisible(false)
        self:upDateRandomSymbol(tempSymbol, fixPos.iY, fixPos.iX)

        self:playMaskSymbolAnim(fixPos.iY, fixPos.iX, function()
            tempSymbol:setVisible(true)
            tempSymbol:runAnim("buling", false)
        end)
    end
end
--添加随机图标
function FlamingPompeiiRandomSymbol:addRandomSymbolBonus(_posList)
    if #_posList > 0 then
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bonus_buling)
    end

    for i,_iPos in ipairs(_posList) do
        local fixPos     = self.m_machine:getRowAndColByPos(_iPos) 
        local symbolType = self.m_machine:getBonusRandomSymbolType(fixPos.iY, fixPos.iX)
        local tempSymbol = self.m_machine:createFlamingPompeiiTempSymbol(symbolType, {
            iCol = fixPos.iY,
            iRow = fixPos.iX,
        })
        local order      = self.Order.RandomSymbol_Bonus
        order = order + 10 * fixPos.iY - fixPos.iX
        self:addChild(tempSymbol, order)
        tempSymbol:setVisible(false)
        self:upDateRandomSymbol(tempSymbol, fixPos.iY, fixPos.iX)
        self.m_machine:upDateBonusReward(tempSymbol)

        self:playMaskSymbolAnim(fixPos.iY, fixPos.iX, function()
            tempSymbol:setVisible(true)
            tempSymbol:runAnim("buling", false, function()
                self.m_machine:playBonusSymbolBreathingAnim(tempSymbol)
            end)
        end)
    end
end

-- 添加遮挡
function FlamingPompeiiRandomSymbol:playMaskSymbolAnim(_iCol, _iRow, _fun)
    local flameSpine = util_spineCreate("FlamingPompeii_huoyan",true,true)
    local order      = self.Order.MaskSymbol
    order = order + 10 * _iCol - _iRow
    self:addChild(flameSpine, order)
    self:upDateRandomSymbol(flameSpine, _iCol, _iRow)

    local animName = "actionframe"
    util_spinePlay(flameSpine, animName, true)
    util_spineEndCallFunc(flameSpine, animName, function()
        flameSpine:setVisible(false)
        performWithDelay(flameSpine,function()
            flameSpine:removeFromParent()
        end,0)
    end)
    -- 第18帧出buff格子
    self.m_machine:levelPerformWithDelay(self, 18/30, _fun)
end

-- 刷新坐标
function FlamingPompeiiRandomSymbol:upDateRandomSymbol(_symbol, _iCol, _iRow)
    local reelName      = string.format("sp_reel_%d", (_iCol - 1))
    local reelNode      = self.m_machine:findChild(reelName)
    local symbolNodePos = cc.p(0, 0) 
    symbolNodePos.x     = self.m_machine.m_SlotNodeW * 0.5
    symbolNodePos.y     = (_iRow - 0.5) * self.m_machine.m_SlotNodeH
    local worldPos      = reelNode:convertToWorldSpace(symbolNodePos)
    local nodePos       = self:convertToNodeSpace(worldPos)
    _symbol:setPosition(nodePos)
end

-- 移除所有随机图标相关节点
function FlamingPompeiiRandomSymbol:removeRandomSymbol()
    self:removeAllChildren(true)
end

--[[
    随机图标的棋盘遮罩
]]
function FlamingPompeiiRandomSymbol:playReelMaskStartAnim(_fun)
    self.m_reelMask:setOpacity(0)
    self.m_reelMask:setVisible(true)
    self.m_reelMask:runAction(cc.Sequence:create(
        cc.FadeIn:create(0.2),
        cc.CallFunc:create(function()
            _fun()
        end)
    ))
end
function FlamingPompeiiRandomSymbol:playReelMaskOverAnim(_fun)
    self.m_reelMask:runAction(cc.Sequence:create(
        cc.FadeOut:create(0.2),
        cc.CallFunc:create(function()
            self.m_reelMask:setVisible(false)
            _fun()
        end)
    ))
end

return FlamingPompeiiRandomSymbol