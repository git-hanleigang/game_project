---
--xhkj
--2018年6月11日
--MermaidRespinLockReels.lua

local MermaidRespinLockReels = class("MermaidRespinLockReels", util_require("base.BaseView"))

MermaidRespinLockReels.actionType = 0
function MermaidRespinLockReels:initUI(data)

    local resourceFilename="Mermaid_Lock.csb"
    self:createCsbNode(resourceFilename)
    self:IdleAction(false)


end

function MermaidRespinLockReels:onEnter()
      
end

function MermaidRespinLockReels:updateLockLeftNum( times,isfirst)
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


function MermaidRespinLockReels:unLockAction( isloop,func )
    -- performWithDelay(self,
    -- function()   

        gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_respin_unlock.mp3")
        
        self:findChild("Particle_1"):resetSystem()
        self:runCsbAction("actionframe",isloop,func)               
                        
    -- end,
    -- 0.1)
    
end

function MermaidRespinLockReels:lightAction(isloop,func  )
    -- self:runCsbAction("hideNum",isloop,func)
    if func then --  因为没有时间线 暂时这么写
        func()
    end
end

function MermaidRespinLockReels:IdleAction(isloop,func  )
    self:runCsbAction("idleframe",isloop,func)

end

function MermaidRespinLockReels:changeNumAction( isloop,func )
    self:runCsbAction("cishu",isloop,func)

end
function MermaidRespinLockReels:onExit()
     
end

function MermaidRespinLockReels:initMachine(machine)
    self.m_machine = machine
end


return MermaidRespinLockReels