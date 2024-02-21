--[[
    活动主界面
    author: 徐袁
    time: 2021-04-05 11:53:27
]]
local BaseRotateLayer = require("base.BaseRotateLayer")
local BaseActivityMainLayer = class("BaseActivityMainLayer", BaseRotateLayer)

function BaseActivityMainLayer:getRefName()
    return ""
end

function BaseActivityMainLayer:onEnter()
    BaseActivityMainLayer.super.onEnter(self)

    local refName = self:getRefName()
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == refName then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

-- function BaseActivityMainLayer:closeUI(callback, ...)
--     local callFunc = function()
--         if callback then
--             callback()
--         end
--     end
--     BaseActivityMainLayer.super.closeUI(self, callFunc, ...)
-- end

return BaseActivityMainLayer
