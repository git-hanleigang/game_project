---
--xcyy
--2018年5月23日
--DiscoFeverBgActionView.lua

local DiscoFeverBgActionView = class("DiscoFeverBgActionView",util_require("base.BaseView"))
DiscoFeverBgActionView.nameList = {"blue","orange","purple","green","red"} 

function DiscoFeverBgActionView:initUI()

    self:createCsbNode("DiscoFever_bg_Action.csb")

   

end

function DiscoFeverBgActionView:showOneAction( index)

    if index == nil then
        return
    end

    for k,v in pairs(self.nameList) do
        
            local node = self:findChild("bg_"..v)
            if node then
                if k == (index + 1) then
                    node:setVisible(true)
                else
                    node:setVisible(false)
                end
                
            end   
    end
end

function DiscoFeverBgActionView:onEnter()
 

end


function DiscoFeverBgActionView:onExit()
 
end


return DiscoFeverBgActionView