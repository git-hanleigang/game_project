---
--xcyy
--2018年5月23日
--FrozenJewelryModeItem.lua

local FrozenJewelryModeItem = class("FrozenJewelryModeItem",util_require("Levels.BaseLevelDialog"))


function FrozenJewelryModeItem:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("FrozenJewelry_Mode.csb")
    self.m_isWaitting = false
end


--默认按钮监听回调
function FrozenJewelryModeItem:clickFunc(sender)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if self.m_isWaitting or 
        self.m_machine:getGameSpinStage( ) > IDLE or 
        self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or 
        (selfData and selfData.jackpot) then
            return
    end
    self.m_isWaitting = true

    self.m_machine:showModeView()
end

function FrozenJewelryModeItem:resetStatus()
    self.m_isWaitting = false
end

return FrozenJewelryModeItem