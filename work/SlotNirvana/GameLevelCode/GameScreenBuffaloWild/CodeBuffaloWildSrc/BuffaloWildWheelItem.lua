---
--xcyy
--2018年5月23日
--BuffaloWildWheelItem.lua

local BuffaloWildWheelItem = class("BuffaloWildWheelItem",util_require("base.BaseView"))


function BuffaloWildWheelItem:initUI(index,data)
    local url = "BuffaloWild_wheel_bar2.csb"
    if index == 1 then
        url = "BuffaloWild_wheel_bar1.csb"
    end
    self:createCsbNode(url)
    if index ~= 1 then -- winall
        self:findChild("lbs_num"):setString("X"..data)
    end
end

return BuffaloWildWheelItem