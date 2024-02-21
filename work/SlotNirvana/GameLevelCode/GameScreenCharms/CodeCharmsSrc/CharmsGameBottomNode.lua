--
-- 气泡下UI
-- Author:{author}
-- Date: 2018-12-22 16:34:48

local GameBottomNode = require "views.gameviews.GameBottomNode"

local CharmsGameBottomNode = class("CharmsGameBottomNode", util_require("views.gameviews.GameBottomNode"))


function CharmsGameBottomNode:setMachine(machine )
    self.m_machine = machine
end

function CharmsGameBottomNode:createLocalAnimation( )
    local pos = cc.p(self.m_normalWinLabel:getPosition()) 
    
    self.m_respinEndActiom =  util_createView("CodeCharmsSrc.CharmsViewWinCoinsAction")
    self.m_normalWinLabel:getParent():addChild(self.m_respinEndActiom,99999)
    self.m_respinEndActiom:setPosition(cc.p(pos.x ,pos.y - 8))

    self.m_respinEndActiom:setVisible(false)
end



return  CharmsGameBottomNode