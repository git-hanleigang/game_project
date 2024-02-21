--
-- 继承自 GameBottomNode
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MermaidGameBottomNode = class("MermaidGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function MermaidGameBottomNode:setMachine( machine )
    self.m_machine = machine
end


return  MermaidGameBottomNode