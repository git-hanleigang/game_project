--
-- 泰山水花动画
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local TzrzanFightWater = class("TzrzanFightWater", util_require("base.BaseView"))


function TzrzanFightWater:initUI(  )
    self:createCsbNode("TarzanFight/shuihua.csb")
end

function TzrzanFightWater:playAction(isloop,func )
    self:runCsbAction("animation0",isloop,func)
end


return  TzrzanFightWater