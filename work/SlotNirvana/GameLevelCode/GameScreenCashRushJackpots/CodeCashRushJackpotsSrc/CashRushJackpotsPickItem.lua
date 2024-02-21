---
--xcyy
--2018年5月23日
--CashRushJackpotsPickItem.lua

local CashRushJackpotsPickItem = class("CashRushJackpotsPickItem",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CashRushJackpotsPublicConfig"

CashRushJackpotsPickItem.m_curIndex = 0
CashRushJackpotsPickItem.m_isClick = false
CashRushJackpotsPickItem.m_superState = false

function CashRushJackpotsPickItem:initUI(_bonusView, _index)

    self:createCsbNode("CashRushJackpots_pick.csb")

    self.m_curIndex = _index
    self.m_parent = _bonusView

    self.m_freeTimes = self:findChild("m_lb_num1")
    self.m_wildCount = self:findChild("m_lb_num2")

    self:setItemIdle()

    self:addClick(self:findChild("click_Panel"))
end

function CashRushJackpotsPickItem:setItemIdle()
    self:runCsbAction("idle", true)
end

function CashRushJackpotsPickItem:runRandomAction()
    self:runCsbAction("tishi", false)
end

function CashRushJackpotsPickItem:setActionframe()
    self:runCsbAction("actionframe2", true)
end

function CashRushJackpotsPickItem:setSuperActionframe()
    self:runCsbAction("actionframe", true)
end

function CashRushJackpotsPickItem:setDarkAction()
    if self:getSuperState() then
        -- self:runCsbAction("yaan2", false, function()
            self:runCsbAction("anidle2", true)
        -- end)
    else
        -- self:runCsbAction("yaan", false, function()
            self:runCsbAction("anidle", true)
        -- end)
    end
end

function CashRushJackpotsPickItem:setFlipAction()
    self:runCsbAction("transform", false, function()
        self:setDarkAction()
    end)
end

-- super，万能牌
function CashRushJackpotsPickItem:refreshItemView(_itemConfig, _isSuper, _onEnter, _isOver)
    local itemConfig = _itemConfig
    local isSuper = _isSuper
    local onEnter = _onEnter
    local isOver = _isOver
    self:setSuperState(isSuper)
    if not isSuper then
        local freeTimes = itemConfig.free or 0
        local wildCount = itemConfig.wildCount or 0
        local wildMul = itemConfig.mul or 0
        self:setFreeTimess(freeTimes)
        self:setWildCount(wildCount)
        self:setWildMul(wildMul)
    end
    if onEnter then
        if isSuper then
            self:runCsbAction("idle3", true)
        else
            self:runCsbAction("idle2", true)
        end
    else
        if isSuper then
            gLobalSoundManager:playSound(PublicConfig.Music_Pick_Select_Wild)
            self:runCsbAction("fankui2", false, function()
                if not isOver then
                    self:runCsbAction("idle3", true)
                end
            end)
        else
            gLobalSoundManager:playSound(PublicConfig.Music_Pick_Select_Normal)
            self:runCsbAction("fankui1", false, function()
                if not isOver then
                    self:runCsbAction("idle2", true)
                end
            end)
        end
    end
end

-- 结束时把压暗的数据填充下
function CashRushJackpotsPickItem:gameOverRefreshItemView(_itemConfig, _isSuper)
    local itemConfig = _itemConfig
    local isSuper = _isSuper
    if not isSuper then
        local freeTimes = itemConfig.free or 0
        local wildCount = itemConfig.wildCount or 0
        local wildMul = itemConfig.mul or 0
        self:setFreeTimess(freeTimes)
        self:setWildCount(wildCount)
        self:setWildMul(wildMul)
    end
    if isSuper then
        self:runCsbAction("anidle2", true)
    else
        self:runCsbAction("anidle", true)
    end
end

function CashRushJackpotsPickItem:setFreeTimess(_times)
    self.m_freeTimes:setString(_times)
end

function CashRushJackpotsPickItem:setWildCount(_count)
    self.m_wildCount:setString(_count)
end

function CashRushJackpotsPickItem:setWildMul(_mul)
    self:findChild("Node_wild"):setVisible(true)
    if _mul == 0 then
        self:findChild("Node_wild"):setVisible(false)
        return
    elseif _mul == 2 then
        self:findChild("2xwild"):setVisible(true)
        self:findChild("3xwild"):setVisible(false)
    elseif _mul == 3 then
        self:findChild("2xwild"):setVisible(false)
        self:findChild("3xwild"):setVisible(true)
    end
end

--默认按钮监听回调
function CashRushJackpotsPickItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_Panel" and self:isCanTouch() and self.m_parent:isCanTouch() then
        self:setClickData(self.m_curIndex)
    end
end

function CashRushJackpotsPickItem:setClickData(_index)
    self:setClickState(false)
    self.m_parent:sendData(_index)
end

function CashRushJackpotsPickItem:setClickState(_state)
    self.m_isClick = _state
end

function CashRushJackpotsPickItem:isCanTouch()
    return self.m_isClick
end

function CashRushJackpotsPickItem:setSuperState(_superState)
    self.m_superState = _superState
end

function CashRushJackpotsPickItem:getSuperState()
    return self.m_superState
end

return CashRushJackpotsPickItem
