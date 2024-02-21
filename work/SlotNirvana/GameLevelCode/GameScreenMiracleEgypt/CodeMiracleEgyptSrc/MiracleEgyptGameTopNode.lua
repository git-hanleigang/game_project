--
-- 气泡下UI
-- Author:{author}
-- Date: 2018-12-22 16:34:48

local GameTopNode = require "views.gameviews.GameTopNode"

local MiracleEgyptGameTopNode = class("MiracleEgyptGameTopNode", GameTopNode)


function MiracleEgyptGameTopNode:initUI(machine)

    self:setMachine(machine )
    GameTopNode.initUI(self)
end

function MiracleEgyptGameTopNode:setMachine(machine )
    self.m_machine = machine
end


function MiracleEgyptGameTopNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_layout_home" then
        -- if self.m_machine and self.m_machine:getIsHaveBubble() and self.m_machine.m_bProduceSlots_InFreeSpin ~= true then
        --     if self.m_machine and self.m_machine.m_LeaveGameTip then
        --         self.m_machine.m_LeaveGameTip:setVisible(true)
        --         self.m_machine.m_LeaveGameTip:showAction()
        --         self.m_machine.m_LeaveGameTip:setCallFunc(function(  )
        --             gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        --         end)
                
        --     else
        --         gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        --     end
        -- else
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        -- end
    else
        GameTopNode.clickFunc(self,sender)
    end
end


return  MiracleEgyptGameTopNode