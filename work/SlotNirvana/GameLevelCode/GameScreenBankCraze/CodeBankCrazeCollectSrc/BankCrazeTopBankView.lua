---
--xcyy
--2018年5月23日
--BankCrazeTopBankView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeTopBankView = class("BankCrazeTopBankView",util_require("Levels.BaseLevelDialog"))


function BankCrazeTopBankView:initUI()
    self:createCsbNode("BankCraze_Jindutiao_Bank.csb")
    self.m_collectText = self:findChild("m_lb_num")
    self:playBankStateIdle(1)
end

function BankCrazeTopBankView:refreshCollectBank(_curCount, _totalCount, _curLevel, _onEnter)
    -- local curCount = (_curLevel-1)*10 + _curCount
    -- local totalCount = (_curLevel-1)*10 + _totalCount
    local curCount = _curCount
    local totalCount = _totalCount
    local str = curCount .. "/" .. totalCount
    if _curLevel < 3 then
        self.m_collectText:setString(str)
    end

    if _onEnter then
        self:playBankStateIdle(_curLevel)
    end
end

function BankCrazeTopBankView:playBankStateIdle(_curLevel)
    local idleNameTbl = {"idle1", "idle2"}
    if _curLevel < 3 then
        self:runCsbAction(idleNameTbl[_curLevel], true)
    end
end

function BankCrazeTopBankView:playTriggerAct(_curLevel)
    local curLevel = _curLevel
    local actName = "actionframe"
    if curLevel == 3 then
        return
    end
    self:runCsbAction(actName, false, function()
        self:playBankStateIdle(curLevel)
    end)
end

return BankCrazeTopBankView
