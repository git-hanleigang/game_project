local NoobBubble=class("NoobBubble",util_require("base.BaseView"))
NoobBubble.info = nil
function NoobBubble:initUI(name)
    self:createCsbNode("NoviceGuide/tishi_qipao.csb")
    self.m_id =  self:findChild(name)
    self:initActive()
end

function NoobBubble:initActive(  )
    local children = self.m_csbNode:getChildren()
    if self.m_id == nil then
        self.m_id = 1
    end
    for j = 1, #children, 1 do
        local child = children[j]
       
        if child ~= self.m_id then
            child:setVisible(false)
        end
    end
end
return NoobBubble