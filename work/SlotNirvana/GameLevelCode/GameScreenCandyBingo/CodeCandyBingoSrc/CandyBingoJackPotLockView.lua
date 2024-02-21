---
--xcyy
--2018年5月23日
--CandyBingoJackPotLockView.lua

local CandyBingoJackPotLockView = class("CandyBingoJackPotLockView",util_require("base.BaseView"))


function CandyBingoJackPotLockView:initUI()

    self:createCsbNode("CandyBingo_JackPotLock.csb")

end


function CandyBingoJackPotLockView:onEnter()
 

end

function CandyBingoJackPotLockView:showAdd()
    
end
function CandyBingoJackPotLockView:onExit()
 
end

--默认按钮监听回调
function CandyBingoJackPotLockView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return CandyBingoJackPotLockView