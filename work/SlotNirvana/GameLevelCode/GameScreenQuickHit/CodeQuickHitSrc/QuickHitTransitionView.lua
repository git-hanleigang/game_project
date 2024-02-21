---
--xhkj
--2018年6月11日
--QuickHitTransitionView.lua

local QuickHitTransitionView = class("QuickHitTransitionView", util_require("base.BaseView"))

function QuickHitTransitionView:initUI()

    local resourceFilename = "Socre_QuickHit_guodudonghua.csb"
    self:createCsbNode(resourceFilename)
    
    
end

function QuickHitTransitionView:runSelfAni( _name,_loop,_func)
    self:runCsbAction(_name,_loop,_func)
end

function QuickHitTransitionView:removeSelf( )
    self:removeFromParent()
end
function QuickHitTransitionView:onEnter()
 

end


function QuickHitTransitionView:onExit()
    
end

return QuickHitTransitionView