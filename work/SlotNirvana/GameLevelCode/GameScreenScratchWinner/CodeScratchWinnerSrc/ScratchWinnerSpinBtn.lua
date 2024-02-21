local SpinBtn = util_require("views.gameviews.SpinBtn") 
local ScratchWinnerSpinBtn = class("ScratchWinnerSpinBtn", SpinBtn)

function ScratchWinnerSpinBtn:btnTouchBegan(sender, _touchLayerSpin)
    local name = sender:getName()

    -- 针对spin按钮
    if "touchSpin" == name or "btn_spin" == name then
        local sMsg = "[ScratchWinnerSpinBtn:btnTouchBegan] 触摸开始"
        print(sMsg)
        release_print(sMsg)
        gLobalNoticManager:postNotification("ScratchWinnerMachine_spinBtn_TouchBegan", {})
        return
    else
        ScratchWinnerSpinBtn.super.btnTouchBegan(self, sender, _touchLayerSpin)
    end
end
function ScratchWinnerSpinBtn:btnTouchEnd(sender)
    local name = sender:getName()

    -- 针对spin按钮
    if "touchSpin" == name or "btn_spin" == name then
        local sMsg = "[ScratchWinnerSpinBtn:btnTouchEnd] 触摸结束"
        print(sMsg)
        release_print(sMsg)
        gLobalNoticManager:postNotification("ScratchWinnerMachine_spinBtn_TouchEnd", {})
        return
    else
        ScratchWinnerSpinBtn.super.btnTouchEnd(self, sender)
    end

end

function ScratchWinnerSpinBtn:btnStopTouchBegan(sender)
    local name = sender:getName()
    -- 针对stop按钮
    if "btn_stop" == name then
        local sMsg = "[ScratchWinnerSpinBtn:btnStopTouchBegan] 触摸开始"
        print(sMsg)
        release_print(sMsg)
        return
    else
        ScratchWinnerSpinBtn.super.btnStopTouchBegan(self, sender)
    end
end

function ScratchWinnerSpinBtn:btnStopTouchEnd(sender)
    local name = sender:getName()
    -- 针对stop按钮
    if "btn_stop" == name then
        local sMsg = "[ScratchWinnerSpinBtn:btnStopTouchEnd] 触摸结束"
        print(sMsg)
        release_print(sMsg)
        gLobalNoticManager:postNotification("ScratchWinnerMachine_stopBtn_TouchEnd", {})
        return
    else
        ScratchWinnerSpinBtn.super.btnStopTouchEnd(self, sender)
    end
    
end

return ScratchWinnerSpinBtn