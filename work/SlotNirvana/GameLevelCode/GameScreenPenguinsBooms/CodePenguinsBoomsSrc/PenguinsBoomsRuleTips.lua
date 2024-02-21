---
--xcyy
--2018年5月23日
--PenguinsBoomsRuleTips.lua

local PenguinsBoomsRuleTips = class("PenguinsBoomsRuleTips",util_require("Levels.BaseLevelDialog"))

PenguinsBoomsRuleTips.TipState = {
    NotShow = 0,            --隐藏
    Start   = 1,            --播start
    Idle    = 2,            --播idle
    Over    = 3,            --播over
}

function PenguinsBoomsRuleTips:initUI(params)
    self.m_machine = params.machine
    self.m_curState = self.TipState.NotShow

    self:createCsbNode("PenguinsBooms_base_wenan.csb")

    self:runCsbAction("idle", true)
end

--[[
    提示按钮
]]
function PenguinsBoomsRuleTips:setTipBtnVisible(_visible)
    self:findChild("Button_1"):setVisible(_visible)
end
function PenguinsBoomsRuleTips:setTipState(_newState)
    self.m_curState = _newState
end
function PenguinsBoomsRuleTips:setTipTouchEnabled(_enable)
    local btn = self:findChild("Button_1")
    btn:setBright(_enable)
    btn:setTouchEnabled(_enable)
end
function PenguinsBoomsRuleTips:clickFunc(sender)
    self:onTipClick()
end
function PenguinsBoomsRuleTips:checkClickStatus()
    if self.m_curState ~= self.TipState.NotShow then
        return false
    end
    -- 滚轮转动
    if self.m_machine:getGameSpinStage( ) ~= IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
        return false
    end
    -- 事件执行
    if self.m_machine.m_isRunningEffect then
        return false
    end
    -- 升行
    if self.m_machine:isPenguinsBoomsUpRow() then
        return false
    end

    return true
end
function PenguinsBoomsRuleTips:onTipClick()
    if not self:checkClickStatus() then
        return
    end

    self:showTipView()
end

function PenguinsBoomsRuleTips:showTipView()
    self:setTipState(self.TipState.Start)

    local curBet   = globalData.slotRunData:getCurTotalBet()
    local betLevel = self.m_machine:getPenguinsBoomsBetLevelByValue(curBet)
    local view = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsChooseBetView",{
        machine  = self.m_machine,
        betLevel = betLevel,
        fnOver   = function()
            self:setTipState(self.TipState.NotShow)
        end
    })
    gLobalViewManager:showUI(view)

    view:setPosition(display.center)
end


return PenguinsBoomsRuleTips