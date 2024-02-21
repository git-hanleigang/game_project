local CashOrConkBottomUI = class("CashOrConkBottomUI",util_require("views.gameviews.GameBottomNode"))


function CashOrConkBottomUI:initUI(...)
    CashOrConkBottomUI.super.initUI(self,...)
    local btn_stop = self.m_spinBtn.m_stopBtn:clone()
    btn_stop:setName("stop_cpy")
    self.m_spinBtn.m_stopBtn:getParent():addChild(btn_stop)
    self._btn_stop = btn_stop
    self:hideBtnStopCpy()
end

function CashOrConkBottomUI:onEnter(...)
    CashOrConkBottomUI.super.onEnter(self,...)
    gLobalNoticManager:addObserver(self,function(self,params)
        self.m_machine:quickOpen()
    end,"on_coc_btnstopcpy_begin")
end

function CashOrConkBottomUI:getSpinUINode( )
    return "CashOrConkBtnSpin"
end

function CashOrConkBottomUI:showBtnStopCpy()
    self._btn_stop:show()
end

function CashOrConkBottomUI:hideBtnStopCpy()
    self._btn_stop:hide()
end

-- function CashOrConkBottomUI:getSpinUINode( )
--     return "COCSpinBtn"
-- end

return CashOrConkBottomUI