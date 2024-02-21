local CashBonus_tishi = class("CashBonus_tishi", util_require("base.BaseView"))

function CashBonus_tishi:initUI(tipType)
    self.m_id = tipType

    CashBonus_tishi.super.initUI(self)
    -- 添加mask
    self:addMask()

    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    )
end

function CashBonus_tishi:getCsbName()
    return "NewCashBonus/CashBonusNew/CashBonus_tishi.csb"
end

function CashBonus_tishi:initCsbNodes()
    self.sp_tip1 = self:findChild("cashbonus_tishi1")
    self.sp_tip2 = self:findChild("cashbonus_tishi2")
    if self.m_id then
        -- 1. congrats  2.dont forget
        self.sp_tip1:setVisible(self.m_id == 1)
        self.sp_tip2:setVisible(self.m_id == 2)
    end
end

function CashBonus_tishi:addMask()
    local isTouch = false
    local mask = util_newMaskLayer()
    if mask then
        mask:setOpacity(185)
        mask:onTouch(
            function(event)
                if not isTouch then
                    return true
                end
                if event.name == "ended" then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_CASHWHEEL_GUIDE_ZORDER, {removeGuide = true})
                end
                return true
            end,
            false,
            true
        )
        gLobalViewManager:getViewLayer():addChild(mask, ViewZorder.ZORDER_GUIDE)

        self.m_mask = mask

        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.5),
                cc.CallFunc:create(
                    function()
                        isTouch = true
                    end
                )
            )
        )
    end
end

function CashBonus_tishi:onExit()
    if self.m_mask then
        self.m_mask:removeFromParent()
        self.m_mask = nil
    end
    CashBonus_tishi.super.onExit(self)
end
return CashBonus_tishi
