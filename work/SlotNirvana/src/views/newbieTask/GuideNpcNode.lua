--npc
local GuideNpcNode = class("GuideNpcNode", util_require("base.BaseView"))
function GuideNpcNode:initUI()
    self:createCsbNode("GuideNewUser/NewUserNpcNode.csb")

    self.m_nodeNpc = self:findChild("node_spine")
    self.m_spineNpc = util_spineCreate("GuideNewUser/Other/xiaoqiche", false, true, 1)
    self.m_nodeNpc:addChild(self.m_spineNpc)
    -- util_spinePlay(self.m_spineNpc, "idleframe", true)
end

function GuideNpcNode:showIdle(type)
    -- local node_zhang = self:findChild("node_zhang")
    -- local node_quan = self:findChild("node_quan")
    -- if node_zhang then
    --     node_zhang:setVisible(false)
    -- end
    -- if node_quan then
    --     node_quan:setVisible(false)
    -- end
    if type == 1 then
        -- self:runCsbAction("idle2",true)
        -- node_zhang:setVisible(true)
        util_spinePlay(self.m_spineNpc, "idle2", true)
    elseif type == 2 then
        -- self:runCsbAction("idle4",true)
        -- node_quan:setVisible(true)
        util_spinePlay(self.m_spineNpc, "idle", true)
    end
end
return GuideNpcNode