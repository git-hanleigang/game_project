---
--xcyy
--2018年5月23日
--CleosCoffersChooseBetView.lua

local CleosCoffersChooseBetView = class("CleosCoffersChooseBetView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CleosCoffersPublicConfig"

function CleosCoffersChooseBetView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("CleosCoffers/BetChoose.csb")
    self.m_col = 5
    self.m_coinLabel = {}
    self.m_itemTbl = {}
    self.m_itemEffectTbl = {}
    self:addClick(self:findChild("Panel_click_over"))
    for index = 1, self.m_col do
        local item = util_createAnimation("CleosCoffers_bet_choose.csb")
        self:findChild("choose_"..index):addChild(item)
        self:addClick(item:findChild("click_Btn"))
        self:addClick(item:findChild("Button"))
        item:findChild("click_Btn"):setTag(index)
        item:findChild("Button"):setTag(index)
        self:initItemCol(item, index)

        -- 点击特效
        local itemEffect = util_createAnimation("CleosCoffers_bet_choose_tx.csb")
        item:findChild("Node_tx"):addChild(itemEffect)
        itemEffect:setVisible(false)
        table.insert(self.m_coinLabel, item:findChild("m_lb_coins"))
        table.insert(self.m_itemTbl, item)
        table.insert(self.m_itemEffectTbl, itemEffect)
    end

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CleosCoffersChooseBetView:onEnter()
    CleosCoffersChooseBetView.super.onEnter(self)
end

function CleosCoffersChooseBetView:onExit()
    CleosCoffersChooseBetView.super.onExit(self)
end

function CleosCoffersChooseBetView:initItemCol(item, curIndex)
    for index = 1,self.m_col do
        item:findChild("Node_choose_"..index):setVisible(index == curIndex)
    end
    if curIndex == 5 then
        item:runCsbAction("idle2", true)
    else
        -- item:runCsbAction("idle1", true)
    end
end

--默认按钮监听回调
function CleosCoffersChooseBetView:clickFunc(sender)
    if not self.m_canClick then
        return
    end
    self.m_canClick = false
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_click_over" then
        self:hideView()
    else
        self:setUI(tag)
    end
end

function CleosCoffersChooseBetView:setUI(_tag)
    for i=1,#self.m_itemTbl do
        if i == _tag then
            if _tag == 5 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Choose_MaxColBet)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Choose_Bet)
            end
            self.m_itemEffectTbl[i]:setVisible(true)
            self.m_itemEffectTbl[i]:runCsbAction("actionframe", false, function()
                self.m_itemEffectTbl[i]:setVisible(false)
                if not self.m_machine:judgeCurSameLastChoose(_tag) then
                    self.m_machine:changeKuangEffect(false, 0)
                end
                self:hideView(function()
                    self.m_machine:chooseBetLevel(_tag)
                    self.m_machine.m_betBtnView:playIdle()
                end)
            end)
            self.m_itemTbl[i]:runCsbAction("idle3", false)
        else
            if self.m_isEnter then
                self.m_itemTbl[i]:runCsbAction("darkstart", false, function()
                    self.m_itemTbl[i]:runCsbAction("darkidle", true)
                end)
            else
                if self.m_curSelectIndex and self.m_curSelectIndex == i then
                    self.m_itemTbl[i]:runCsbAction("darkstart", false, function()
                        self.m_itemTbl[i]:runCsbAction("darkidle", true)
                    end)
                end
            end
        end
    end
end

function CleosCoffersChooseBetView:hideView(callBack)
    self:runCsbAction("over", false, function()
        if callBack then
            callBack()
        else
            self.m_machine:setSpinTounchType(true)
        end
        self.m_machine.m_betBtnView:playIdle()
        self:setVisible(false)
    end)
end
 
function CleosCoffersChooseBetView:showView(_iBetLevel)
    self:setVisible(true)
    self:initCoins()
    if _iBetLevel and _iBetLevel >= 0 then
        self.m_isEnter = false
        self:playItemDarkEffect(_iBetLevel)
    else
        self.m_isEnter = true
    end
    self.m_machine.m_betBtnView:playIdle()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Show_ChooseBet)
    self:runCsbAction("start", false, function()
        self.m_canClick = true
        self:playIdle()
    end)
end

function CleosCoffersChooseBetView:initCoins()
    for index = 1, self.m_col do
        local lable = self.m_coinLabel[index]
        local strCoins = self.m_machine:getBetLevelCoins(index)
        local strCoins = util_formatCoinsLN(strCoins, 3)
        lable:setString(strCoins)
    end
end

function CleosCoffersChooseBetView:playIdle()
    self:runCsbAction("idle", true)
end

function CleosCoffersChooseBetView:playItemDarkEffect(_iBetLevel)
    for index = 1, #self.m_itemTbl do
        if index ~= (_iBetLevel+1) then
            self.m_itemTbl[index]:runCsbAction("darkidle", true)
        else
            if index == 5 then
                self.m_itemTbl[index]:runCsbAction("idle2", true)
            else
                self.m_itemTbl[index]:runCsbAction("idle1", true)
            end
            self.m_curSelectIndex = index
        end
    end
end

return CleosCoffersChooseBetView
