---
--xcyy
--2018年5月23日
--CoinManiaBaoZhuView.lua

local CoinManiaBaoZhuView = class("CoinManiaBaoZhuView",util_require("base.BaseView"))

CoinManiaBaoZhuView.m_index = 0
CoinManiaBaoZhuView.m_machine = nil

function CoinManiaBaoZhuView:initUI(data)

    self:createCsbNode("CoinMania_FS_baozhu.csb")

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine


end


function CoinManiaBaoZhuView:onEnter()
 

end

function CoinManiaBaoZhuView:onExit()
 
end

--默认按钮监听回调
function CoinManiaBaoZhuView:clickFunc(sender)
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


return CoinManiaBaoZhuView