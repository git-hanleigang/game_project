---
--xcyy
--2018年5月23日
--PelicanLoadingIconView.lua

local PelicanLoadingIconView = class("PelicanLoadingIconView",util_require("Levels.BaseLevelDialog"))


function PelicanLoadingIconView:initUI()

    self:createCsbNode("Pelican_loadingbar_icon.csb")
    self:runCsbAction("idle",true)
end

function PelicanLoadingIconView:showActionFrame( )
    self:runCsbAction("actionframe",false,function (  )
        self:runCsbAction("idle",true)
    end)
end

function PelicanLoadingIconView:jiman( )
    self:stopAllActions()
    self:runCsbAction("actionframe2",false,function (  )
        self:runCsbAction("idle",true)
    end)
end

function PelicanLoadingIconView:Lock( )
    self:runCsbAction("lock",true)
end

function PelicanLoadingIconView:unLock( )
    self:runCsbAction("unlock",false,function (  )
        self:runCsbAction("idle",true)
    end)
end
return PelicanLoadingIconView