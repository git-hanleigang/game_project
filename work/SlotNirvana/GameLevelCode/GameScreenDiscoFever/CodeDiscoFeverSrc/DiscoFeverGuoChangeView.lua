---
--xcyy
--2018年5月23日
--DiscoFeverGuoChangeView.lua

local DiscoFeverGuoChangeView = class("DiscoFeverGuoChangeView",util_require("base.BaseView"))


function DiscoFeverGuoChangeView:initUI()

    self:createCsbNode("DiscoFever_guochangdonghua.csb")


    self.m_spine = util_spineCreate("DiscoFever_guochangdonghua", true, true) 
    self:findChild("Node_1"):addChild(self.m_spine)

end

function DiscoFeverGuoChangeView:runCsbAction( name,isloop,func)
    util_spinePlay(self.m_spine,name,isloop)
    if func then
        util_spineEndCallFunc(self.m_spine, name, function() 
            func()
      end)
    end
end

function DiscoFeverGuoChangeView:onEnter()
 

end

function DiscoFeverGuoChangeView:onExit()
 
end

return DiscoFeverGuoChangeView