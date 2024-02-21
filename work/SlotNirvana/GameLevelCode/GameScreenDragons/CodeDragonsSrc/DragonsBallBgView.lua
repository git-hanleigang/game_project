---
--xcyy
--2018年5月23日
--DragonsBallBgView.lua

local DragonsBallBgView = class("DragonsBallBgView",util_require("base.BaseView"))


function DragonsBallBgView:initUI()

    self:createCsbNode("Dragons_longzhu_guang.csb")

    self:runCsbAction("idle",true) -- 播放时间线

end


function DragonsBallBgView:onEnter()
 

end

function DragonsBallBgView:onExit()
 
end


return DragonsBallBgView