---
--smy
--2018年4月26日
--BaseLevelDialog.lua
--fix ios 0312
local BaseLevelDialog = class("BaseLevelDialog", util_require("base.BaseView"))

function BaseLevelDialog:onEnter()
    BaseLevelDialog.super.onEnter(self)
    if not self.m_csbNode then
        return
    end
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                assert(self.m_csbNode, "csbNode is nill !!! cname is " .. self.__cname)
                
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end

return BaseLevelDialog
