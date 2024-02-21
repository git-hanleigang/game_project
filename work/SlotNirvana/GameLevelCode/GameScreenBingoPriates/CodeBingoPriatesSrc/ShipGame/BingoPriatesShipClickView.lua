---
--xcyy
--2018年5月23日
--BingoPriatesShipClickView.lua

local BingoPriatesShipClickView = class("BingoPriatesShipClickView",util_require("base.BaseView"))

BingoPriatesShipClickView.m_index = 0
BingoPriatesShipClickView.m_machine = nil

function BingoPriatesShipClickView:initUI(data)

    self:createCsbNode("BingoPriates_shipGame_chuan.csb")
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine

end


function BingoPriatesShipClickView:onEnter()
 

end

function BingoPriatesShipClickView:onExit()
 
end

--默认按钮监听回调
function BingoPriatesShipClickView:clickFunc(sender)
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


return BingoPriatesShipClickView