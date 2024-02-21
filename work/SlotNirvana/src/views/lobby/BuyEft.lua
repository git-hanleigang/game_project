--
--大厅关卡节点
--
local BuyEft = class("BuyEft", util_require("base.BaseView"))

BuyEft.m_contentLen = nil
BuyEft.activityNodes = nil
BuyEft.m_actionName = {"two_idle","one_idle","one_saoguang"}
BuyEft.m_state = nil
function BuyEft:initUI()
    self:createCsbNode("GameNode/two_buttom_eft.csb")

end

function BuyEft:setActionState(state,_loop)
    if  state < 0 or state > 3 or self.m_state == state  then
        return 
    end
    self.m_state = state
    local isLoop = _loop

    self:runCsbAction(self.m_actionName[2],false,function(  )
        self:runCsbAction(self.m_actionName[self.m_state],isLoop,nil)
    end)
    
end


return BuyEft
