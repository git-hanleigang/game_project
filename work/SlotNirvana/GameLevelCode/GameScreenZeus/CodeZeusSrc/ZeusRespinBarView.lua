---
--xcyy
--2018年5月23日
--ZeusRespinBarView.lua

local ZeusRespinBarView = class("ZeusRespinBarView",util_require("base.BaseView"))


function ZeusRespinBarView:initUI()

    self:createCsbNode("Zeus_RespinSpinsRemaining.csb")

    
end


function ZeusRespinBarView:onEnter()
 

end

function ZeusRespinBarView:changeRespinTimes(times,isinit)

    local lab1 =  self:findChild("zeus_spin_1")
    local lab2 =  self:findChild("zeus_spin_2")
    local lab3 =  self:findChild("zeus_spin_3")

    lab1:setVisible(true)
    lab2:setVisible(true)
    lab3:setVisible(true)

    if times == 0 then

    elseif times == 1 then
        lab1:setVisible(false)

    elseif times == 2 then

        lab2:setVisible(false)

    elseif times == 3 then
        if not isinit then
            gLobalSoundManager:playSound("ZeusSounds/music_Zeus_RsBar_rest.mp3")
            self:runCsbAction("animation0")
        end
        
        lab3:setVisible(false)
    end
    
end

function ZeusRespinBarView:onExit()
 
end

--默认按钮监听回调
function ZeusRespinBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ZeusRespinBarView