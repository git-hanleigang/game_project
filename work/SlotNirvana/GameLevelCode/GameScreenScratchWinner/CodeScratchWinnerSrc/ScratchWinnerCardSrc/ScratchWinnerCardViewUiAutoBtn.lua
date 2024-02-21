local ScratchWinnerCardViewUiAutoBtn = class("ScratchWinnerCardViewUiAutoBtn",util_require("Levels.BaseLevelDialog"))
function ScratchWinnerCardViewUiAutoBtn:initUI()
    self:createCsbNode("ScratchWinner_btnAuto.csb")

    self:resetBtnState()
end

function ScratchWinnerCardViewUiAutoBtn:upDateTimes(_cur, _max)
    local sCount = string.format("%d/%d", _cur, _max)

    local labNum1 = self:findChild("m_lb_num_0")
    labNum1:setString(sCount)
    self:updateLabelSize({label=labNum1,sx=1,sy=1}, 130)

    local labNum2 = self:findChild("m_lb_num_1")
    labNum2:setString(sCount)
    self:updateLabelSize({label=labNum2,sx=1,sy=1}, 130)
end

--[[
    按钮状态
]]
function ScratchWinnerCardViewUiAutoBtn:resetBtnState()
    self.m_bAutoState = false
    self.m_bOneCard   = false
    self:upDateBtnState()
end
function ScratchWinnerCardViewUiAutoBtn:changeAutoBtnEnable(_bEnable)
    self:findChild("btn_scratch_one"):setEnabled(_bEnable)
    self:findChild("btn_scratch"):setEnabled(_bEnable)
    self:findChild("btn_auto_one"):setEnabled(_bEnable)
    self:findChild("btn_auto"):setEnabled(_bEnable)
end

function ScratchWinnerCardViewUiAutoBtn:setAutoState(_bAutoState)
    self.m_bAutoState = _bAutoState
end
function ScratchWinnerCardViewUiAutoBtn:setOneCardState(_bOneCard)
    self.m_bOneCard = _bOneCard
end

function ScratchWinnerCardViewUiAutoBtn:upDateBtnState()
    local btnScratchOne = self:findChild("btn_scratch_one")
    local btnScratch = self:findChild("btn_scratch")
    local btnAutoOne = self:findChild("btn_auto_one")
    local btnAuto = self:findChild("btn_auto")

    btnScratchOne:setVisible(self.m_bOneCard and not self.m_bAutoState)
    btnScratch:setVisible(not self.m_bOneCard and not self.m_bAutoState)
    btnAutoOne:setVisible(self.m_bOneCard and self.m_bAutoState)
    btnAuto:setVisible(not self.m_bOneCard and self.m_bAutoState)


end

--[[
    开始刮卡 和 结束刮卡
]]
function ScratchWinnerCardViewUiAutoBtn:plauAutoBtnStartAnim()
    self:runCsbAction("start", false, function()
        self:plauAutoBtnIdleAnim()
    end)
end
function ScratchWinnerCardViewUiAutoBtn:plauAutoBtnIdleAnim()
    self:runCsbAction("idle", true)
end
function ScratchWinnerCardViewUiAutoBtn:plauAutoBtnOverAnim()
    self:runCsbAction("over2", false)
end


return ScratchWinnerCardViewUiAutoBtn