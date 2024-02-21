--[[

    author:{author}
    time:2022-01-24 11:26:27
]]
local BaseMenuItem = require("views.menu.BaseMenuItem")
local MenuItemPayTable = class("MenuItemPayTable", BaseMenuItem)

function MenuItemPayTable:initView(bDeluxe)
    MenuItemPayTable.super.initView(self, bDeluxe)
    if bDeluxe then
        util_changeTexture(self.m_spItemN, "Option/ui/btn_paytable_up1.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_paytable_down1.png")
    else
        util_changeTexture(self.m_spItemN, "Option/ui/btn_paytable_up.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_paytable_down.png")
    end
end

function MenuItemPayTable:clickFunc(sender)
    MenuItemPayTable.super.clickFunc(self, sender)
    self:onClickPayTable(sender)
end

function MenuItemPayTable:onClickPayTable(sender)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAYTABLEVIEW_OPEN)

    --csc 2021年05月19日21:44:06 去掉 2级paytable 引导
    if not globalData.GameConfig:checkUseNewNoviceFeatures() then
        local isCompletePayTable = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.payTable, true)

        if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1) then
            -- 引导打点：进入关卡-4.点击spin
            gLobalSendDataManager:getLogGuide():sendGuideLog(1, 4)
        end
        local isComplete = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskStart1, true)
        if isCompletePayTable and not isComplete then
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_PayTableClick)
            end
        end
    end
end

return MenuItemPayTable
