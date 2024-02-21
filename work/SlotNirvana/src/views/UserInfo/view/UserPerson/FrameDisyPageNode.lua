local FrameDisyPageNode = class("FrameDisyPageNode", BaseView)

function FrameDisyPageNode:initUI(_index,_data)
    self:createCsbNode("Activity/csd/Information_FramePartII/FramePartII_MainUI/FramePartII_PageNode.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self.m_index = _index
    self.m_data = _data
    self:initView()
end

function FrameDisyPageNode:initView()
    for i,v in ipairs(self.m_data) do
        local ic_node = self:findChild("node_icon"..i)
        local node = util_createView("views.UserInfo.view.UserPerson.CashDisyFrameCell")
        if v.teshu ~= nil then
            node:updataCell(v.id,v.teshu)
        else
            node:updataCell(v)
        end
        ic_node:addChild(node)
    end
end

return FrameDisyPageNode