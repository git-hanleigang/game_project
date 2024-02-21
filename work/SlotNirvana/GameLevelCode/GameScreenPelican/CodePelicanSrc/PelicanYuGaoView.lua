---
--xcyy
--2018年5月23日
--PelicanYuGaoView.lua

local PelicanYuGaoView = class("PelicanYuGaoView",util_require("Levels.BaseLevelDialog"))


function PelicanYuGaoView:initUI()

    self:createCsbNode("Pelican_free_yugao.csb")

end

function PelicanYuGaoView:onEnter()

    PelicanYuGaoView.super.onEnter(self)

end

function PelicanYuGaoView:onExit()
    PelicanYuGaoView.super.onExit(self)
end

function PelicanYuGaoView:showYuGao(func)
    self:runCsbAction("actionframe")
end


return PelicanYuGaoView