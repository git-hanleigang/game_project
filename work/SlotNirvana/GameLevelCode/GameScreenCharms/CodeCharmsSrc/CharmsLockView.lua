---
--xcyy
--2018年5月23日
--CharmsLockView.lua

local CharmsLockView = class("CharmsLockView",util_require("base.BaseView"))


function CharmsLockView:initUI()

    self:createCsbNode("Charms_lock.csb")

    

    -- self.m_lock = util_spineCreate("Charms_Oldgoldcar", true, true)
    -- self:addChild(self.m_lock)


    self.m_lock = util_createView("CodeCharmsSrc.CharmsLockSymbolView")
    self:addChild(self.m_lock)
      
end


function CharmsLockView:onEnter()
 

end

function CharmsLockView:showAdd()
    
end
function CharmsLockView:onExit()
 
end



return CharmsLockView