--[[
    集卡 Magic卡 wild关闭 二次确认界面
--]]
local CardMagicWildExcCloseLayer = class("CardMagicWildExcCloseLayer", BaseLayer)

function CardMagicWildExcCloseLayer:initDatas(_expire, _confirmCB)
    self.m_expire = _expire
    self.m_confirmCB = _confirmCB

    self:setExtendData("CardMagicWildExcCloseLayer")
    self:setName("CardMagicWildExcCloseLayer")
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/wild/cash_wild_exchange_quit.csb")
    self:addClickSound({"btn_yes", "btn_no"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

-- 初始化UI --
function CardMagicWildExcCloseLayer:initView()
    CardMagicWildExcCloseLayer.super.initView(self)

    -- 过期时间
    self.m_scheduler =
        schedule(
        self,
        function()
            self:updateCountdonwUI(self.m_expire)
        end,
        1
    )
    self:updateCountdonwUI(self.m_expire)
    self:initButtonLabel()
end

function CardMagicWildExcCloseLayer:initButtonLabel()
    self:setButtonLabelContent("btn_yes", "STAY")
    self:setButtonLabelContent("btn_no", "CLOSE")
end

function CardMagicWildExcCloseLayer:updateCountdonwUI(_expireSec)
    local lbExpireTime = self:findChild("lb_expireTime")
    local timeStr, bOver = util_daysdemaining(_expireSec, true)
    if bOver then
        self:clearScheduler()
        self:closeUI()
    end
    lbExpireTime:setString(timeStr)
end

-- function CardMagicWildExcCloseLayer:playShowAction()
--     gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
--     CardMagicWildExcCloseLayer.super.playShowAction(self, "show", false)
-- end

function CardMagicWildExcCloseLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

-- function CardMagicWildExcCloseLayer:playHideAction()
--     CardMagicWildExcCloseLayer.super.playHideAction(self, "over", false)
-- end

-- 点击事件 --
function CardMagicWildExcCloseLayer:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_yes" then
        -- stay 留下来直接关闭界面
        self:closeUI()
    elseif name == "btn_no" then
        -- close 要关闭所有界面
        self:closeUI(self.m_confirmCB)
    end
end

function CardMagicWildExcCloseLayer:closeUI(_cb)
    if self.m_closing then
        return
    end
    self.m_closing = true

    CardMagicWildExcCloseLayer.super.closeUI(self, _cb)
end

-- 清楚定时器
function CardMagicWildExcCloseLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

return CardMagicWildExcCloseLayer
