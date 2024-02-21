--
-- 泰山水花动画
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local TzrzanFightReelsHide = class("TzrzanFightReelsHide", util_require("base.BaseView"))


function TzrzanFightReelsHide:initUI(  )
    self:createCsbNode("TarzanFight/TarzanFight_reels_hid.csb")
end

function TzrzanFightReelsHide:playAction1(isloop,func )
    self:runCsbAction("tankuangdonghua",isloop,func)
end

function TzrzanFightReelsHide:playAction(isloop,func )
    self:runCsbAction("animation0",isloop,func)
end

return  TzrzanFightReelsHide