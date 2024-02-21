---
--xcyy
--2018年5月23日
--JackpotOfBeerRespinBarView.lua

local JackpotOfBeerRespinBarView = class("JackpotOfBeerRespinBarView",util_require("Levels.BaseLevelDialog"))


function JackpotOfBeerRespinBarView:initUI()

    self:createCsbNode("JackpotOfBeer_linkbar.csb")
    self.lastNum = 0
end


function JackpotOfBeerRespinBarView:onEnter()

    JackpotOfBeerRespinBarView.super.onEnter(self)

end

function JackpotOfBeerRespinBarView:onExit()
    JackpotOfBeerRespinBarView.super.onExit(self)
end

function JackpotOfBeerRespinBarView:resetLastNum( )
    self.lastNum = 0
end

function JackpotOfBeerRespinBarView:updateTimes(curtimes)
    self:findChild("m_lb_num"):setString(curtimes)
    
end


return JackpotOfBeerRespinBarView