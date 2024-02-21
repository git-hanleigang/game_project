---
--xcyy
--2018年5月23日
--ZeusSpinBtn.lua

local ZeusSpinBtn = class("ZeusSpinBtn",util_require("views.gameviews.SpinBtn"))

function ZeusSpinBtn:playSpinBtnClick( )
    gLobalSoundManager:playSound("ZeusSounds/Zeus_spin.mp3")
end

return ZeusSpinBtn