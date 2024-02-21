---
--xcyy
--2018年5月23日
---
--BankCrazeBonusBtnView.lua

local BankCrazeBonusBtnView = class("BankCrazeBonusBtnView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BankCrazePublicConfig"

BankCrazeBonusBtnView.m_machine = nil
BankCrazeBonusBtnView.m_isClicked = nil

function BankCrazeBonusBtnView:initUI(_machine)
    self:createCsbNode("BankCraze_Button_Bonus.csb")
    
    self.m_machine = _machine
    self:setCilckState(true)
end

function BankCrazeBonusBtnView:playStart()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:playIdle()
    end)
end

function BankCrazeBonusBtnView:playIdle()
    self:setVisible(true)
    self:runCsbAction("idle", true)
end

function BankCrazeBonusBtnView:setBtnState(_state)
    self:findChild("Button_1"):setVisible(_state)
end

function BankCrazeBonusBtnView:playOver(_onEnter)
    if _onEnter then
        self:setVisible(false)
    else
        self:runCsbAction("over", false, function()
            self:setVisible(false)
        end)
    end
end

-- 反馈
function BankCrazeBonusBtnView:playFeedBackAct()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", false, function()
        self:playIdle()
    end)
end

--默认按钮监听回调
function BankCrazeBonusBtnView:clickFunc(sender)
    local name = sender:getName()

    if self:getCilckState() and self.m_machine:bonusBtnIsCanClick() then
        self:showBonusView()
    end
end

function BankCrazeBonusBtnView:showBonusView()
    self:setCilckState(false)
    local endCallFunc = function()
        self.m_machine:playGameEffect() 
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_machine:showChooseView(endCallFunc, true)
end

function BankCrazeBonusBtnView:setCilckState(_state)
    self.m_isClicked = _state
end

function BankCrazeBonusBtnView:getCilckState()
    return self.m_isClicked
end

return BankCrazeBonusBtnView
