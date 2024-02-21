---
--xcyy
--2018年5月23日
--CleosCoffersBtnBetView.lua

local CleosCoffersBtnBetView = class("CleosCoffersBtnBetView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CleosCoffersPublicConfig"

function CleosCoffersBtnBetView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("CleosCoffers_bet.csb")
    self:addClick(self:findChild("Panel_click"))
    self.m_itemTab = {}
    for index = 1, 5 do
        self.m_itemTab[index] = self:findChild("bet_"..index)
    end
end

function CleosCoffersBtnBetView:onEnter()
    CleosCoffersBtnBetView.super.onEnter(self)
end

function CleosCoffersBtnBetView:onExit()
    CleosCoffersBtnBetView.super.onExit(self)
end

function CleosCoffersBtnBetView:updateColItem(_col)
    for index = 1, #self.m_itemTab do
        self.m_itemTab[index]:setVisible(index <= (_col+1))
    end
end

--[[
    更新金币显示
]]
function CleosCoffersBtnBetView:updateCoins(_index)
    local strCoins = self.m_machine:getBetLevelCoins(_index+1)
    local strCoins = util_formatCoinsLN(strCoins, 3)
    self:findChild("m_lb_coins"):setString(strCoins)
end

--默认按钮监听回调
function CleosCoffersBtnBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if (name == "Panel_click" or name == "Button") and self.m_machine:betBtnIsCanClick() then
        self:openBetChooseView()
    end
end

function CleosCoffersBtnBetView:openBetChooseView()
    self.m_machine:openBetChooseView()
end

function CleosCoffersBtnBetView:playIdle()
    self:runCsbAction("idle", true)
end

--[[
    压暗
]]
function CleosCoffersBtnBetView:playDarkEffect( )
    self:runCsbAction("darkidle", true)
end

return CleosCoffersBtnBetView
