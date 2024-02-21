---
--xhkj
--2018年6月11日
--HowlingMoonRespinLockReels.lua

local HowlingMoonRespinLockReels = class("HowlingMoonRespinLockReels", util_require("base.BaseView"))

HowlingMoonRespinLockReels.actionType = 0
function HowlingMoonRespinLockReels:initUI(data)

    local resourceFilename="Socre_HowlingMoon_Lock.csb"
    self:createCsbNode(resourceFilename)
    self:IdleAction(false)

    local zhezhao = self:findChild("zhezhao")
    if zhezhao then
        local size = zhezhao:getContentSize()
        zhezhao:setContentSize(size.width,size.height+2)
    end
end

function HowlingMoonRespinLockReels:onEnter()
      
end

function HowlingMoonRespinLockReels:updateLockLeftNum( times,isfirst)
    if times ~= "" and  times <= 0  then
        times = 0
    end
    local str = self:findChild("fnt_shuzi"):getString()
    if times ~= "" and times ~= 0 and tonumber(str) ~= times then
        if not isfirst then
            self:changeNumAction(false)
        end
    end
    self:findChild("fnt_shuzi"):setString(times)
    
end


function HowlingMoonRespinLockReels:unLockAction( isloop,func )
    performWithDelay(self,
    function()   
        gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_spin_respin_to3.mp3")
        self:runCsbAction("actionframe",isloop,func)               
                        
    end,
    0.2)
    
end

function HowlingMoonRespinLockReels:lightAction(isloop,func  )
    self:runCsbAction("hideNum",isloop,func)
end

function HowlingMoonRespinLockReels:IdleAction(isloop,func  )
    self:runCsbAction("idleframe",isloop,func)
end

function HowlingMoonRespinLockReels:changeNumAction( isloop,func )
    self:runCsbAction("actionframe1",isloop,func)
end
function HowlingMoonRespinLockReels:onExit()
     
end

function HowlingMoonRespinLockReels:initMachine(machine)
    self.m_machine = machine
end


return HowlingMoonRespinLockReels