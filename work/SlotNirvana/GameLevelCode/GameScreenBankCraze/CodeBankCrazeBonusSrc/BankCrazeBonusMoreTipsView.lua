---
--xcyy
--2018年5月23日
---
--BankCrazeBonusMoreTipsView.lua

local BankCrazeBonusMoreTipsView = class("BankCrazeBonusMoreTipsView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BankCrazePublicConfig"

BankCrazeBonusMoreTipsView.m_machine = nil
BankCrazeBonusMoreTipsView.m_isClicked = nil

function BankCrazeBonusMoreTipsView:initUI(_machine, _isGold)
    self.m_machine = _machine
    local isGold = _isGold

    if isGold then
        self.m_spineTips = util_spineCreate("Socre_BankCraze_Bonus_lou3",true,true)
        self:addChild(self.m_spineTips)
    else
        self.m_spineTips = util_spineCreate("Socre_BankCraze_Bonus_lou2",true,true)
        self:addChild(self.m_spineTips)
    end
end

function BankCrazeBonusMoreTipsView:showStartMoreType(_onEnter)
    self:setVisible(true)
    local onEnter = _onEnter
    if onEnter then
        util_spinePlay(self.m_spineTips, "idle", true)
    else
        util_spinePlay(self.m_spineTips, "start", false)
        util_spineEndCallFunc(self.m_spineTips, "start", function()
            util_spinePlay(self.m_spineTips, "idle", true)
        end)
    end
end

function BankCrazeBonusMoreTipsView:closeBonusMoreTips()
    util_spinePlay(self.m_spineTips, "over", false)
    util_spineEndCallFunc(self.m_spineTips, "over", function()
        self:setVisible(false)
    end)
end

return BankCrazeBonusMoreTipsView
