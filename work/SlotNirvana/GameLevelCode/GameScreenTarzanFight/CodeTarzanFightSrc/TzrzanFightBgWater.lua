--
-- 泰山BG水花动画
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local TzrzanFightBgWater = class("TzrzanFightBgWater", util_require("base.BaseView"))


function TzrzanFightBgWater:initUI(  )
    self:createCsbNode("TarzanFight/pubu.csb")
end

function TzrzanFightBgWater:playAction(isloop,func )
    self:runCsbAction("animation0",isloop,func)
end


return  TzrzanFightBgWater