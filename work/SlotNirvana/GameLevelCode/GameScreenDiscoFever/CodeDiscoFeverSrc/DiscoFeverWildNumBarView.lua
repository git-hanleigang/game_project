---
--xcyy
--2018年5月23日
--DiscoFeverWildNumBarView.lua

local DiscoFeverWildNumBarView = class("DiscoFeverWildNumBarView",util_require("base.BaseView"))

DiscoFeverWildNumBarView.m_sumNum = 0
DiscoFeverWildNumBarView.imageName = {"DiscoFever_left2_2","DiscoFever_left1_1","DiscoFever_left4_4","DiscoFever_left3_3"}

function DiscoFeverWildNumBarView:initUI()

    self:createCsbNode("DiscoFever_left.csb")
    self.m_sumNum = 0

end


function DiscoFeverWildNumBarView:onEnter()
 

end

function DiscoFeverWildNumBarView:changeImg( index)
    for k,v in pairs(self.imageName) do
        local node = self:findChild(v)
        if index == k then
            if node then
                node:setVisible(true)
            end
        else
            if node then
                node:setVisible(false)
            end
        end
    end
end

function DiscoFeverWildNumBarView:onExit()
 
end


return DiscoFeverWildNumBarView