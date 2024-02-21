--[[
    author:{author}
    time:2019-09-26 17:24:55
]]

local WheelTopStrip = class("WheelTopStrip", util_require("base.BaseView"))

function WheelTopStrip:initUI()
    self:createCsbNode("GameNode/GameTopNode_ZBQ_tiao.csb")
end

function WheelTopStrip:stopFrameAt(percent)
    self:pauseForIndex(math.floor(percent*100))
end

return WheelTopStrip