-- Created by jfwang on 2019-05-21.
-- BetTipsNode
--
local BetTipsNode = class("BetTipsNode", util_require("base.BaseView"))

function BetTipsNode:initUI(data)
    self:createCsbNode("BetTipsUI/BetTipsNode.csb",true)

end

function BetTipsNode:showBetTips(callback)
    self:runCsbAction("show",false,function(  )
        self:runCsbAction("idle",false)
        if callback ~= nil then
            callback()
        end
    end)
end

function BetTipsNode:hideBetTips(callback)
    self:runCsbAction("over",false,function(  )
        if callback ~= nil then
            callback()
        end
    end)
end

return BetTipsNode