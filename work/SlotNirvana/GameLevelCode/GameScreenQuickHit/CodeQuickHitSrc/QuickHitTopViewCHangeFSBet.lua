---
--xhkj
--2018年6月11日
--QuickHitTopViewCHangeFSBet.lua

local QuickHitTopViewCHangeFSBet = class("QuickHitTopViewCHangeFSBet", util_require("base.BaseView"))
QuickHitTopViewCHangeFSBet.waitTime = 0

function QuickHitTopViewCHangeFSBet:initUI()

    local resourceFilename="QuickHit_numberBoom.csb"
    self:createCsbNode(resourceFilename)

    self:runSelfCsbAction("hide")
    
    -- self:runSelfCsbAction("show")
 
end

function QuickHitTopViewCHangeFSBet:updatelab(isAction , times)
   if isAction then
        self:runCsbAction("animation0")
   end

   self:findChild("BitmapFontLabel_1"):setString("X"..times)
end

function QuickHitTopViewCHangeFSBet:runSelfCsbAction(_name ,_loop,_func)
    
    self:runCsbAction(_name,_loop,_func)

 end

function QuickHitTopViewCHangeFSBet:getWaitTime( )
    return self.waitTime
end

function QuickHitTopViewCHangeFSBet:onEnter()
   

end


function QuickHitTopViewCHangeFSBet:onExit()
    
end

function QuickHitTopViewCHangeFSBet:removeSelf(func)
    if func then
        func()
    end
    self:removeFromParent()
end

function QuickHitTopViewCHangeFSBet:initMachine(machine)
    self.m_machine = machine
end

return QuickHitTopViewCHangeFSBet