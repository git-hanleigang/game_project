---
--xcyy
--2018年5月23日
--PomiRespinBarView.lua

local PomiRespinBarView = class("PomiRespinBarView",util_require("base.BaseView"))
PomiRespinBarView.m_times = 10000
function PomiRespinBarView:initUI()

    self:createCsbNode("LinkReels/PomiLink/4in1_Pomi_respin_bar.csb")


    self.m_PomiRespinAction = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiRespinAction")
    self:findChild("action"):addChild(self.m_PomiRespinAction)
    self.m_PomiRespinAction:setVisible(false)
    self.m_times = 10000
 
end


function PomiRespinBarView:onEnter()
 

end

function PomiRespinBarView:onExit()
 
end

function PomiRespinBarView:updateRespinLeftTimnes(times,isplay )
    local name = "actionframe0"
    if times == 0 then
        name = "actionframe0"
    elseif times == 1 then
        name = "actionframe1"
    elseif times == 2 then
        name = "actionframe2"
    elseif times == 3 then
        if isplay then
            gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/Pomi_respinTime_rest.mp3")
        end
        
        name = "actionframe3"
        self.m_PomiRespinAction:setVisible(true)
        self.m_PomiRespinAction:runCsbAction("actionframe",false,function(  )
            self.m_PomiRespinAction:setVisible(false)
        end)

    end

    if  self.m_times ~= times then
        self.m_times = times
        self:runCsbAction(name)

    end
    

end

function PomiRespinBarView:initMachine(machine)
    self.m_machine = machine
end

return PomiRespinBarView