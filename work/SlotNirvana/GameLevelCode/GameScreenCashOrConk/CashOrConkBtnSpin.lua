local CashOrConkBtnSpin = class("CashOrConkBtnSpin",util_require("views.gameviews.SpinBtn"))

function CashOrConkBtnSpin:baseTouchEvent(sender, eventType)
    local name = sender:getName()
    if name == "stop_cpy" then
        if eventType == ccui.TouchEventType.began then
            gLobalNoticManager:postNotification("on_coc_btnstopcpy_begin")
        end
    else
        CashOrConkBtnSpin.super.baseTouchEvent(self,sender,eventType)
    end
end

return CashOrConkBtnSpin