---
--xcyy
--2018年5月23日
--OZCollectGirl.lua

local OZCollectGirl = class("OZCollectGirl",util_require("base.BaseView"))


function OZCollectGirl:initUI()

    self:createCsbNode("OZ_jindutiao_girl.csb")

    self.m_girl =  util_spineCreate("OZ_jindutiao_girl_spine",true,true)
    self:addChild(self.m_girl)

    util_spinePlay(self.m_girl,"idleframe",true)

    self.m_FanKuiView = util_createView("CodeOZSrc.CollectGame.OZCollectGirlFanKui")
    self:addChild(self.m_FanKuiView ,10)
    
end


function OZCollectGirl:onEnter()
 

end

function OZCollectGirl:showAdd()
    
end
function OZCollectGirl:onExit()
 
end

--默认按钮监听回调
function OZCollectGirl:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return OZCollectGirl