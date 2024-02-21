---
--xcyy
--2018年5月23日
--ZooManiaAnimalView.lua

local ZooManiaAnimalView = class("ZooManiaAnimalView",util_require("base.BaseView"))

ZooManiaAnimalView.m_index = 0
ZooManiaAnimalView.m_machine = nil

function ZooManiaAnimalView:initUI(data)

    self:createCsbNode("ZooMania_dongwu.csb")
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine

end


function ZooManiaAnimalView:onEnter()
 
end

function ZooManiaAnimalView:onExit()
 
end

--默认按钮监听回调
function ZooManiaAnimalView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "click" then
        if self.m_machine:isCanTouch( ) then
            self.m_machine:setClickData( self.m_index )
            -- self:findChild("click"):setVisible(false)
            print(" 第几个 @@@@ ".. self.m_index)
        end
        
    end

end


return ZooManiaAnimalView