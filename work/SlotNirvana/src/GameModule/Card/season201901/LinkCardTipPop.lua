--[[
    author:{author}
    time:2019-07-10 11:12:56
]]
local BaseView = util_require("base.BaseView")
local LinkCardTipPop = class("LinkCardTipPop", BaseView)

function LinkCardTipPop:initUI()
    self:createCsbNode(CardResConfig.LinkCardTipRes)
    local touch = self:findChild("touch")
    self:addClick(touch)

end

function LinkCardTipPop:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch" then
        self:closeUI()
    end
end

function LinkCardTipPop:closeUI()
    if self.isClose then
        return 
    end
    self.isClose = true
    self:removeFromParent()
end

return LinkCardTipPop