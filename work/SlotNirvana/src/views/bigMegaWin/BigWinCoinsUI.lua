--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-01-17 14:05:25
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-01-17 14:05:31
FilePath: /SlotNirvana/src/views/bigMegaWin/BigWinCoinsUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local BigWinCoinsUI = class("BigWinCoinsUI", BaseView)
local COINS_JUMP_ACT_TIME = 6.3 -- 金币增长动画时间

function BigWinCoinsUI:initDatas(_winCoins, _petSpinWinCoins, _mainLayer)
    BigWinCoinsUI.super.initDatas(self)
    
    self.m_totalCoins = toLongNumber(_winCoins or 0)
    self.m_petSpinWinCoins = toLongNumber(_petSpinWinCoins or 0)
    -- self.m_normalSpinWinCoins = self.m_totalCoins - self.m_petSpinWinCoins
    self.m_bUsePetType = self.m_petSpinWinCoins > toLongNumber(0)
    self.m_mainLayer = _mainLayer
end

function BigWinCoinsUI:getCsbName()
    return "CommonWin/csd/BigWinCoinLabel.csb"
end

function BigWinCoinsUI:initCsbNodes()
    BigWinCoinsUI.super.initCsbNodes(self)

    self.m_lbCoins = self:findChild("lb_coins")
    self.m_lbCoins:setString("")

    self.m_alignUIList = {
        {node = self:findChild("sp_coins")},
        {node = self.m_lbCoins, alignX = 5}
    }
end

function BigWinCoinsUI:onEnter()
    BigWinCoinsUI.super.onEnter(self)
    
    self:playCoinsAddJumpAct()
end

-- 金币上涨滚动动画
function BigWinCoinsUI:playCoinsAddJumpAct()
    local addV = self.m_totalCoins / (COINS_JUMP_ACT_TIME * 60)
    util_jumpNumExtra(self.m_lbCoins, 0, self.m_totalCoins, addV, 1/60, util_getFromatMoneyStr, {#tostring(self.m_totalCoins)}, nil, nil, util_node_handler(self, self.coinsAddJumpActOver), util_node_handler(self, self.updateCoinLbSizeScale))
end

-- 宠物加成 金币上涨滚动动画
function BigWinCoinsUI:playPetAddWinCoinsAct()
    self._bOver = true
    local addV = self.m_petSpinWinCoins / (0.5 * 60)
    local totalCoins = self.m_petSpinWinCoins + self.m_totalCoins
    util_jumpNumExtra(self.m_lbCoins, self.m_totalCoins, totalCoins, addV, 1/60, util_getFromatMoneyStr, {#tostring(totalCoins)}, nil, nil, util_node_handler(self, self.coinsAddJumpActOver), util_node_handler(self, self.updateCoinLbSizeScale))
end

-- 金币框缩放动画
function BigWinCoinsUI:playPetCoinScaleAct()
    local delayTime1 = cc.DelayTime:create(33/30)
    local scaleTo1 = cc.EaseQuadraticActionOut:create( cc.ScaleTo:create((41-33)/30, 1.3) )
    local scaleTo2 = cc.EaseQuadraticActionIn:create( cc.ScaleTo:create((50-41)/30, 0.9) )
    local scaleTo3= cc.EaseSineInOut:create( cc.ScaleTo:create((57-50)/30, 1.05) )
    local scaleTo4= cc.EaseSineInOut:create( cc.ScaleTo:create((64-57)/30, 1) )
    local act =  cc.Sequence:create(delayTime1, scaleTo1, scaleTo2, scaleTo3, scaleTo4)
    self.m_csbNode:runAction(act)
end

-- 更新金币size 大小
function BigWinCoinsUI:updateCoinLbSizeScale()
    util_alignCenter(self.m_alignUIList, 0, 1000)
end

-- 金币增长结束 关闭弹板 (音效9秒  0.7金币延迟显示 + 6.3 金币上涨 + 2界面idle)
function BigWinCoinsUI:coinsAddJumpActOver(_time)
    if tolua.isnull(self.m_mainLayer) then
        return
    end
    self:stopAllActions()

    if self._bOver then
        -- 结束待机时间
        _time = self.m_bUsePetType and 1 or 0.5
    end
    if not _time and self.m_bUsePetType then
        -- 普通涨金币 切 宠物加成金币 过渡时间
        _time = 0
    end
    _time = _time or 2
    performWithDelay(self.m_mainLayer, function()
        if self._bOver then
            self.m_mainLayer:closeUI()
        else
            if self.m_bUsePetType then
                self.m_mainLayer:playPetSkillAddAct()
            else
                self._bOver = true
                self.m_mainLayer:closeUI()
            end
        end
    end, _time)
end

-- 中途中断金币上涨动画
function BigWinCoinsUI:interruptCoinAddJumpAct()
    self:stopAllActions()

    self.m_lbCoins:unscheduleUpdate()
    self.m_lbCoins:setString(util_getFromatMoneyStr(self.m_totalCoins))
    self:updateCoinLbSizeScale()

    self:coinsAddJumpActOver(0.5)
end

return BigWinCoinsUI