---
--xcyy
--2018年5月23日
--PomiBgChangeActView.lua

local PomiBgChangeActView = class("PomiBgChangeActView",util_require("base.BaseView"))


function PomiBgChangeActView:initUI()

    self:createCsbNode("LinkReels/PomiLink/4in1_pami_Fire.csb")

end


function PomiBgChangeActView:onEnter()
 

end

function PomiBgChangeActView:showOneActImg(index)
    
      for i=4,6 do
            local name = i.."c"
            local node = self:findChild(name)
            if node then
                  if index == i then
                        node:setVisible(true)
                  else
                        node:setVisible(false)
                  end    
            end
            
            
      end

end

function PomiBgChangeActView:onExit()
 
end




return PomiBgChangeActView