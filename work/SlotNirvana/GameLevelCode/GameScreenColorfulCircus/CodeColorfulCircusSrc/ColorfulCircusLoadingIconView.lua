---
--xcyy
--2018年5月23日
--ColorfulCircusLoadingIconView.lua

local ColorfulCircusLoadingIconView = class("ColorfulCircusLoadingIconView",util_require("Levels.BaseLevelDialog"))


function ColorfulCircusLoadingIconView:initUI()

    self:createCsbNode("ColorfulCircus_loadingbar_icon.csb")
    self:runCsbAction("idle",true)
end

function ColorfulCircusLoadingIconView:showActionFrame( )
    self:runCsbAction("actionframe",false,function (  )
        self:runCsbAction("idle",true)
    end)
end

function ColorfulCircusLoadingIconView:jiman( )
    self:stopAllActions()
    self:runCsbAction("actionframe2",false,function (  )
        self:runCsbAction("idle",true)
    end)
end

function ColorfulCircusLoadingIconView:Lock( )
    self:runCsbAction("lock",true)
end

function ColorfulCircusLoadingIconView:unLock( )
    self:runCsbAction("unlock",false,function (  )
        self:runCsbAction("idle",true)
    end)
end
return ColorfulCircusLoadingIconView