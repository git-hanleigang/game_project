---
--xcyy
--2018年5月23日
--BingoPriatesChestClickView.lua

local BingoPriatesChestClickView = class("BingoPriatesChestClickView",util_require("base.BaseView"))

BingoPriatesChestClickView.m_index = 0
BingoPriatesChestClickView.m_machine = nil

function BingoPriatesChestClickView:initUI(data)

    self:createCsbNode("BingoPriates_baoxiang.csb")
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine

end


function BingoPriatesChestClickView:onEnter()
 

end

function BingoPriatesChestClickView:onExit()
 
end

--默认按钮监听回调
function BingoPriatesChestClickView:clickFunc(sender)
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


return BingoPriatesChestClickView