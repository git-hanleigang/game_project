--[[
    author:{author}
    time:2019-09-27 22:00:34
]]

local DealTopNode = class("DealTopNode", util_require("base.BaseView"))
function DealTopNode:initUI()
    local csbName = "GameNode/DealChang.csb"
    if globalData.slotRunData.isPortrait then
        csbName = "GameNode/DealChang_Portrait.csb"
    end
    self:createCsbNode(csbName)
    
    self:runCsbAction("idle", true)
end

function DealTopNode:updateCountDown(time)
    local lb_time= self:findChild("shuzi")
    if lb_time then
        lb_time:setString(util_count_down_str(time))
    end
end

return DealTopNode