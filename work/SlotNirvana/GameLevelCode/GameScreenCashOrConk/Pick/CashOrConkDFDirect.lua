local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CashOrConkDFDirect = class("CashOrConkDFDirect",CashOrConkDFBase)

function CashOrConkDFDirect:initUI(data)
    self:setDelegate(data.machine)
    -- self:createCsbNode("CashOrConk/GameScreenCashOrConk_sanxuanyi.csb")
end

function CashOrConkDFDirect:goDirectNext(func_callback)
    self._func_callback = func_callback
    self:sendData(1)
end

function CashOrConkDFDirect:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        self._machine.m_runSpinResultData.p_selfMakeData.bonus = spinData.result.selfData.bonus
    else
        gLobalViewManager:showReConnect(true)
    end
    if self._func_callback then
        self._func_callback()
    end
end

return CashOrConkDFDirect