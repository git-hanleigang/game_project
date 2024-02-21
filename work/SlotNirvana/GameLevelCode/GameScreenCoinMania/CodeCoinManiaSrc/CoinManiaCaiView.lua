---
--xcyy
--2018年5月23日
--CoinManiaCaiView.lua

local CoinManiaCaiView = class("CoinManiaCaiView",util_require("base.BaseView"))

CoinManiaCaiView.m_index = 0
CoinManiaCaiView.m_machine = nil

function CoinManiaCaiView:initUI(data)

    self:createCsbNode(data.csbname)
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine

end


function CoinManiaCaiView:onEnter()
 

end

function CoinManiaCaiView:onExit()
 
end

--默认按钮监听回调
function CoinManiaCaiView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        

        if self.m_machine:isCanTouch( ) then
            self.m_machine:setClickData( self.m_index )
            self:findChild("click"):setVisible(false)
            print(" 第几个 @@@@ ".. self.m_index)
        end
        
    end

end


return CoinManiaCaiView